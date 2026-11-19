# ---------------------------------------------------------------------------
# 03 - Estimer, puis chercher à casser le résultat
# Question : quand le franc suisse s'apprécie, construit-on davantage dans les
# communes où vivent beaucoup de frontaliers ?
# Modèle : régression de Poisson sur le nombre de logements autorisés, avec
# effets fixes par commune et par année, écarts-types regroupés par commune.
# ---------------------------------------------------------------------------
library(fixest)
library(ggplot2)
setFixest_notes(FALSE)

base <- read.csv2(file.path("base", "base_communes_annees_68.csv"), colClasses = c(com = "character"))
epci <- read.csv2(file.path("data_raw", "epci_communes_68.csv"), colClasses = "character", fileEncoding = "UTF-8")
base <- merge(base, epci, by = "com")

base$part      <- base$part_suisse_2011 / 100            # part de frontaliers vers la Suisse en 2011
base$part_al   <- base$part_allemagne_2011 / 100         # idem vers l'Allemagne (groupe de contrôle)
base$traite    <- as.integer(base$part_suisse_2011 >= 20)
base$franc     <- log(1.643 / base$chf_par_euro)         # appréciation du franc depuis 2007, en log
base$periode   <- cut(base$annee, c(2001, 2007, 2014, 2021, 2025),
                      labels = c("2002-2007", "2008-2014", "2015-2021", "2022-2025"))
base$saint_louis <- as.integer(base$epci_nom == "CA Saint-Louis Agglomération")

ligne <- function(nom, m, terme) {
  i <- grep(terme, names(coef(m)), fixed = TRUE)[1]
  data.frame(test = nom, coefficient = round(coef(m)[i], 2), ecart_type = round(se(m)[i], 2),
             p_valeur = round(pvalue(m)[i], 3), communes = length(unique(m$fixef_id$com)), row.names = NULL)
}

# --- 1. Résultat de départ ----------------------------------------------------
m_base <- fepois(aut_tous ~ part:franc | com + annee, base, cluster = ~com)
m_per  <- fepois(aut_tous ~ i(periode, traite, ref = "2002-2007") | com + annee, base, cluster = ~com)
cat("\nÉcart de construction entre communes de frontaliers (20 % et plus) et les autres,\npar rapport à 2002-2007, en % :\n")
print(round(100 * (exp(coef(m_per)) - 1)))

# --- 2. Tendances avant le choc : étude d'événement --------------------------
m_evt <- fepois(aut_tous ~ i(annee, traite, ref = 2007) | com + annee, base, cluster = ~com)
evt <- data.frame(annee = as.integer(gsub("\\D", "", names(coef(m_evt)))), b = coef(m_evt), s = se(m_evt))
evt <- rbind(evt, data.frame(annee = 2007, b = 0, s = 0))
avant <- wald(m_evt, "annee::200[2-6]", print = FALSE)
cat("\nTest conjoint des écarts de 2002 à 2006 : p =", round(avant$p, 3), "\n")

g4 <- ggplot(evt, aes(annee, b)) +
  geom_hline(yintercept = 0, colour = "#52514e", linewidth = 0.3) +
  geom_vline(xintercept = 2007, colour = "#52514e", linewidth = 0.3, linetype = "dashed") +
  geom_ribbon(aes(ymin = b - 1.96 * s, ymax = b + 1.96 * s), fill = "#2a78d6", alpha = 0.18) +
  geom_line(colour = "#2a78d6", linewidth = 0.9) + geom_point(colour = "#2a78d6", size = 1.8) +
  scale_x_continuous(breaks = seq(2002, 2025, 3)) +
  labs(title = "L'écart entre les deux groupes de communes se creuse à partir de 2015",
       subtitle = "Écart de construction entre les communes de frontaliers (20 % et plus) et les autres, en log, base 2007",
       x = NULL, y = "Écart (log)",
       caption = "Régression de Poisson, effets fixes par commune et par année. Bande : intervalle de confiance à 95 %.") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14), plot.subtitle = element_text(colour = "#52514e"),
        plot.caption = element_text(colour = "#52514e", hjust = 0, size = 9), plot.title.position = "plot",
        plot.caption.position = "plot", panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.background = element_rect(fill = "#fcfcfb", colour = NA))
ggsave(file.path("figures", "fig4_etude_evenement.png"), g4, width = 8, height = 4.6, dpi = 200)

# --- 3. Les tests qui cherchent à casser le résultat --------------------------
tests <- rbind(
  ligne("Résultat de départ", m_base, "part:franc"),
  ligne("Contrôle : frontaliers vers l'Allemagne",
        fepois(aut_tous ~ part:franc + part_al:franc | com + annee, base, cluster = ~com), "part_al"),
  ligne("Seuil 10 % de frontaliers", { base$s <- as.integer(base$part_suisse_2011 >= 10)
        fepois(aut_tous ~ s:franc | com + annee, base, cluster = ~com) }, "s:franc"),
  ligne("Seuil 30 % de frontaliers", { base$s <- as.integer(base$part_suisse_2011 >= 30)
        fepois(aut_tous ~ s:franc | com + annee, base, cluster = ~com) }, "s:franc"),
  ligne("Maisons individuelles", fepois(aut_individuel ~ part:franc | com + annee, base, cluster = ~com), "part:franc"),
  ligne("Immeubles collectifs", fepois(aut_collectif ~ part:franc | com + annee, base, cluster = ~com), "part:franc"),
  ligne("Comparaison à l'intérieur de chaque intercommunalité",
        fepois(aut_tous ~ part:franc | com + epci^annee, base, cluster = ~com), "part:franc"),
  ligne("Sans Saint-Louis Agglomération",
        fepois(aut_tous ~ part:franc | com + annee, base[base$saint_louis == 0, ], cluster = ~com), "part:franc"))
cat("\nEffet de la part de frontaliers quand le franc s'apprécie (coefficient positif = plus de construction)\n")
print(tests, row.names = FALSE)
write.csv2(tests, file.path("base", "resultats_tests.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# --- 4. Où se trouve vraiment la hausse ? -------------------------------------
base$zone <- ifelse(base$saint_louis == 1, "Saint-Louis Agglomération",
             ifelse(base$epci_nom %in% c("CC Sundgau", "CC Sud Alsace Largue"), "Sundgau et Largue",
             ifelse(base$epci_nom == "CA Mulhouse Alsace Agglomération", "Agglomération de Mulhouse", "Reste du Haut-Rhin")))
z <- aggregate(cbind(aut_tous, aut_collectif, population_2011) ~ zone + periode, base, sum)
z$tous <- round(1000 * z$aut_tous / z$population_2011, 1)
z$collectif <- round(1000 * z$aut_collectif / z$population_2011, 1)
c11 <- base[base$annee == 2011, ]
profil <- aggregate(cbind(suisse_2011, actifs_2011, suisse_2022) ~ zone, c11, sum)
profil$part_frontaliers_2011 <- round(100 * profil$suisse_2011 / profil$actifs_2011, 1)
profil$evolution_frontaliers <- round(100 * (profil$suisse_2022 / profil$suisse_2011 - 1))
cat("\nLogements autorisés par an pour 1 000 habitants, par zone\n")
tz <- reshape(z[, c("zone", "periode", "tous")], idvar = "zone", timevar = "periode", direction = "wide")
names(tz) <- sub("tous.", "", names(tz), fixed = TRUE)
tz <- merge(profil[, c("zone", "part_frontaliers_2011", "evolution_frontaliers")], tz, by = "zone")
print(tz, row.names = FALSE)
write.csv2(tz, file.path("base", "tableau_par_zone.csv"), row.names = FALSE, fileEncoding = "UTF-8")

za <- aggregate(cbind(aut_tous, population_2011) ~ zone + annee, base, sum)
za$taux <- 1000 * za$aut_tous / za$population_2011
coul <- c("Saint-Louis Agglomération" = "#2a78d6", "Sundgau et Largue" = "#eb6834",
          "Agglomération de Mulhouse" = "#1baf7a", "Reste du Haut-Rhin" = "#eda100")
fin <- za[za$annee == 2025, ]; fin <- fin[order(fin$taux), ]; fin$y <- fin$taux
for (i in 2:nrow(fin)) fin$y[i] <- max(fin$y[i], fin$y[i - 1] + 1.1)
g5 <- ggplot(za, aes(annee, taux, colour = zone)) +
  geom_line(linewidth = 0.9) +
  geom_text(data = fin, aes(y = y, label = zone), hjust = 0, nudge_x = 0.3, size = 3.5, colour = "#0b0b0b") +
  scale_colour_manual(values = coul) +
  scale_x_continuous(breaks = seq(2002, 2025, 3), limits = c(2002, 2032)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "La hausse vient de l'agglomération de Saint-Louis, pas du Sundgau",
       subtitle = "Logements autorisés par an pour 1 000 habitants, par zone",
       x = NULL, y = "Logements autorisés pour 1 000 habitants",
       caption = "Sources : SDES, Sitadel ; Insee. Population de 2011 au dénominateur.") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14), plot.subtitle = element_text(colour = "#52514e"),
        plot.caption = element_text(colour = "#52514e", hjust = 0, size = 9), plot.title.position = "plot",
        plot.caption.position = "plot", panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        legend.position = "none", plot.background = element_rect(fill = "#fcfcfb", colour = NA))
ggsave(file.path("figures", "fig5_construction_par_zone.png"), g5, width = 8, height = 4.6, dpi = 200)
