# ---------------------------------------------------------------------------
# 04 - Comparer les quatre zones
# Le script 03 montre que la hausse vient de l'agglomération de Saint-Louis.
# Ici, on met côte à côte ce qui distingue cette zone du Sundgau : population,
# type de logements construits, poids dans la construction, loyers.
# ---------------------------------------------------------------------------
base <- read.csv2(file.path("base", "base_communes_annees_68.csv"), colClasses = c(com = "character"))
epci <- read.csv2(file.path("data_raw", "epci_communes_68.csv"), colClasses = "character", fileEncoding = "UTF-8")
base <- merge(base, epci, by = "com")

base$zone <- ifelse(base$epci_nom == "CA Saint-Louis Agglomération", "Saint-Louis Agglomération",
             ifelse(base$epci_nom %in% c("CC Sundgau", "CC Sud Alsace Largue"), "Sundgau et Largue",
             ifelse(base$epci_nom == "CA Mulhouse Alsace Agglomération", "Agglomération de Mulhouse", "Reste du Haut-Rhin")))
c11 <- base[base$annee == 2011, ]
somme <- function(x, par) tapply(x, par, sum)

# --- Communes, habitants, frontaliers -----------------------------------------
tab <- data.frame(communes = as.vector(table(c11$zone)), row.names = names(table(c11$zone)))
tab$part_population_2011 <- round(100 * somme(c11$population_2011, c11$zone) / sum(c11$population_2011), 1)
tab$part_frontaliers_2011 <- round(100 * somme(c11$suisse_2011, c11$zone) / somme(c11$actifs_2011, c11$zone), 1)
tab$evol_frontaliers_2011_2022 <- round(100 * (somme(c11$suisse_2022, c11$zone) / somme(c11$suisse_2011, c11$zone) - 1))

# --- Population : 2011 à 2023 -------------------------------------------------
p23 <- base[base$annee == 2023, ]
tab$evol_population_2011_2023 <- round(100 * (somme(p23$population, p23$zone) / somme(c11$population, c11$zone) - 1), 1)

# --- Part des immeubles collectifs dans les logements autorisés ---------------
avant <- base[base$annee %in% 2002:2007, ]
apres <- base[base$annee %in% 2015:2021, ]
tab$part_collectif_2002_2007 <- round(100 * somme(avant$aut_collectif, avant$zone) / somme(avant$aut_tous, avant$zone))
tab$part_collectif_2015_2021 <- round(100 * somme(apres$aut_collectif, apres$zone) / somme(apres$aut_tous, apres$zone))

# --- Poids de chaque zone dans les logements autorisés depuis 2015 ------------
recent <- base[base$annee >= 2015, ]
tab$part_construction_2015_2025 <- round(100 * somme(recent$aut_tous, recent$zone) / sum(recent$aut_tous), 1)

# --- Loyers d'annonce 2025 (carte des loyers) ---------------------------------
# Moyenne des estimations communales, pondérée par la population. Pour les petites communes,
# l'estimation est celle d'un groupe de communes voisines ("maille") : c'est un ordre de grandeur.
lire_loyers <- function(fichier) {
  l <- read.csv2(file.path("data_raw", fichier), colClasses = "character", fileEncoding = "latin1")
  l <- l[l$DEP == "68", ]
  data.frame(com = l$INSEE_C, loyer = as.numeric(sub(",", ".", l$loypredm2, fixed = TRUE)), niveau = l$TYPPRED)
}
loyer_zone <- function(fichier) {
  l <- merge(c11[, c("com", "zone", "population_2011")], lire_loyers(fichier), by = "com")
  stopifnot(nrow(l) == nrow(c11))
  round(somme(l$loyer * l$population_2011, l$zone) / somme(l$population_2011, l$zone), 1)
}
tab$loyer_appartement_2025 <- loyer_zone("pred-app-mef-dhup.csv")
tab$loyer_maison_2025      <- loyer_zone("pred-mai-mef-dhup.csv")

tab <- tab[c("Saint-Louis Agglomération", "Sundgau et Largue", "Agglomération de Mulhouse", "Reste du Haut-Rhin"), ]
print(t(tab))
write.csv2(cbind(zone = rownames(tab), tab), file.path("base", "tableau_comparaison_zones.csv"),
           row.names = FALSE, fileEncoding = "UTF-8")

# --- Où construit-on dans l'agglomération de Saint-Louis ? --------------------
sl <- recent[recent$zone == "Saint-Louis Agglomération", ]
top <- sort(somme(sl$aut_tous, sl$nom), decreasing = TRUE)[1:5]
cat("\nLes cinq communes de Saint-Louis Agglomération qui autorisent le plus de logements, 2015-2025 :\n")
print(top)
