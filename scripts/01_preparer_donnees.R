# ---------------------------------------------------------------------------
# 01 - Préparer les données
# Charge les fichiers bruts dans une base SQLite, puis construit la base
# communes x années avec les requêtes du dossier sql/.
# À lancer depuis le projet RStudio (dossier etude-franc-suisse).
# ---------------------------------------------------------------------------
library(DBI)
library(RSQLite)
library(readxl)

brut <- "data_raw"
dir.create("base", showWarnings = FALSE)
fichier_db <- file.path("base", "etude.sqlite")
# Si une exécution précédente s'est arrêtée en cours de route, sa connexion est encore ouverte :
# on la ferme, sinon Windows interdit de remplacer le fichier.
if (exists("con")) try(dbDisconnect(con), silent = TRUE)
if (file.exists(fichier_db)) file.remove(fichier_db)
con <- dbConnect(SQLite(), fichier_db)

# --- 1. Permis de construire (Sitadel) : 4,3 millions de lignes -------------
message("Lecture de Sitadel (une à deux minutes)...")
sitadel <- read.csv(file.path(brut, "Donnees-annuelles-communales-Logements.2026-10.csv"),
                    sep = ";", encoding = "UTF-8",
                    colClasses = c("character", "character", "character", rep("numeric", 4)))
sitadel$ANNEE <- as.integer(sitadel$ANNEE)
dbWriteTable(con, "sitadel", sitadel)
message("  ", format(nrow(sitadel), big.mark = " "), " lignes")
rm(sitadel)

# --- 2. Trajets domicile-travail (recensements 2011, 2018, 2022) ------------
lire_flux <- function(zip, annee) {
  # Les fichiers n'ont pas tous le même encodage. On ne garde donc que les lignes du Haut-Rhin
  # (elles commencent par 68) et trois champs sans accent : commune, lieu de travail, effectif.
  fichier <- unzip(file.path(brut, zip), exdir = tempdir())[1]
  lignes <- readLines(fichier, warn = FALSE)
  file.remove(fichier)
  lignes <- lignes[startsWith(lignes, "68")]
  champs <- strsplit(lignes, ";", fixed = TRUE, useBytes = TRUE)
  data.frame(annee = annee,
             codgeo = vapply(champs, `[`, "", 1),
             dclt   = vapply(champs, `[`, "", 3),
             flux   = as.numeric(sub(",", ".", vapply(champs, `[`, "", 5), fixed = TRUE)))
}
flux <- rbind(
  lire_flux("base-texte-flux-mobilite-domicile-lieu-travail-2011.zip", 2011L),
  lire_flux("base-csv-flux-mobilite-domicile-lieu-travail-2018.zip",   2018L),
  lire_flux("base-flux-mobilite-domicile-lieu-travail-2022_csv.zip",   2022L))
stopifnot(!anyNA(flux$flux))
dbWriteTable(con, "flux", flux)

# --- 3. Population par commune (géographie au 1er janvier 2025) -------------
pop <- read_excel(file.path(brut, "base-pop-historiques-1876-2023.xlsx"),
                  sheet = 1, skip = 5, col_types = "text")
dbWriteTable(con, "population_brute", as.data.frame(pop[, c("CODGEO", "DEP", "LIBGEO")]))
pop68 <- pop[pop$DEP == "68", ]
annees <- 2006:2023
population <- do.call(rbind, lapply(annees, function(a)
  data.frame(com = pop68$CODGEO, annee = a,
             population = as.numeric(pop68[[paste0("PMUN", a)]]))))
dbWriteTable(con, "population", population)

# --- 4. Communes fusionnées et taux de change -------------------------------
passage <- read.csv(file.path(brut, "passage_communes_fusionnees_68.csv"), sep = ";",
                    colClasses = "character", encoding = "UTF-8")
dbWriteTable(con, "passage", passage)

bce <- read.csv(unz(file.path(brut, "eurofxref-hist.zip"), "eurofxref-hist.csv"),
                na.strings = c("N/A", ""), check.names = FALSE)
dbWriteTable(con, "change_quotidien",
             data.frame(jour = as.character(bce$Date), chf = as.numeric(bce$CHF)))

# --- 5. Requêtes SQL ---------------------------------------------------------
for (f in sort(list.files("sql", pattern = "\\.sql$", full.names = TRUE))) {
  message("SQL : ", basename(f))
  dbExecute(con, paste(readLines(f, encoding = "UTF-8"), collapse = "\n"))
}

# --- 6. Export et contrôles --------------------------------------------------
base <- dbReadTable(con, "base")
write.csv2(base, file.path("base", "base_communes_annees_68.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("\nContrôles\n")
cat("Communes :", length(unique(base$com)), "| années :", min(base$annee), "à", max(base$annee),
    "| lignes :", nrow(base), "\n")
cat("Valeurs manquantes, logements autorisés :", sum(is.na(base$aut_tous)),
    "| part de frontaliers :", sum(is.na(base$part_suisse_2011)), "\n")
print(dbGetQuery(con, "SELECT annee, ROUND(SUM(actifs)) AS actifs, ROUND(SUM(suisse)) AS suisse,
                              ROUND(SUM(allemagne)) AS allemagne FROM frontaliers GROUP BY annee"))
print(dbGetQuery(con, "SELECT annee, SUM(aut_tous) AS logements_autorises, ROUND(chf_par_euro, 3) AS chf_par_euro
                       FROM base GROUP BY annee"))
dbDisconnect(con)
