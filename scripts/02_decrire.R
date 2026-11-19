# ---------------------------------------------------------------------------
# 02 - Décrire
# Trois graphiques : où vivent les frontaliers, comment a évolué le franc suisse,
# et combien on construit selon le poids des frontaliers dans la commune.
# ---------------------------------------------------------------------------
library(ggplot2)

base <- read.csv2(file.path("base", "base_communes_annees_68.csv"), colClasses = c(com = "character"))
dir.create("figures", showWarnings = FALSE)

bleu_clair <- "#86b6ef"; bleu <- "#2a78d6"; bleu_fonce <- "#0d366b"
encre <- "#0b0b0b"; gris <- "#52514e"
theme_etude <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", colour = encre, size = 14),
        plot.subtitle = element_text(colour = gris, margin = margin(b = 10)),
        plot.caption = element_text(colour = gris, hjust = 0, size = 9),
        plot.title.position = "plot", plot.caption.position = "plot",
        panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = "#e6e5e1", linewidth = 0.3),
        axis.title = element_text(colour = gris, size = 10), axis.text = element_text(colour = gris),
        legend.position = "none", plot.background = element_rect(fill = "#fcfcfb", colour = NA))

# Trois groupes de communes selon la part d'actifs travaillant en Suisse en 2011
groupes <- c("Moins de 5 % de frontaliers", "De 5 à 20 %", "Plus de 20 %")
base$groupe <- cut(base$part_suisse_2011, c(-Inf, 5, 20, Inf), labels = groupes, right = FALSE)
communes <- base[base$annee == 2011, ]

# --- Figure 1 : répartition des communes ------------------------------------
classes <- c("0 à 5 %", "5 à 10 %", "10 à 20 %", "20 à 30 %", "30 à 50 %", "50 % et plus")
communes$classe <- cut(communes$part_suisse_2011, c(-Inf, 5, 10, 20, 30, 50, Inf), labels = classes, right = FALSE)
f1 <- as.data.frame(table(classe = communes$classe))
g1 <- ggplot(f1, aes(classe, Freq)) +
  geom_col(fill = bleu, width = 0.62) +
  geom_text(aes(label = Freq), vjust = -0.5, colour = encre, size = 3.8) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(title = "Une commune du Haut-Rhin sur trois compte plus de 20 % de frontaliers",
       subtitle = "Nombre de communes selon la part des actifs occupés qui travaillent en Suisse, en 2011",
       x = NULL, y = "Nombre de communes",
       caption = "Source : Insee, recensement de la population 2011. Champ : 366 communes du Haut-Rhin.") +
  theme_etude
ggsave(file.path("figures", "fig1_frontaliers_par_commune.png"), g1, width = 8, height = 4.6, dpi = 200)

# --- Figure 2 : le franc suisse ---------------------------------------------
f2 <- unique(base[, c("annee", "chf_par_euro")])
g2 <- ggplot(f2, aes(annee, chf_par_euro)) +
  geom_line(colour = bleu, linewidth = 0.9) +
  geom_point(data = f2[f2$annee %in% c(2007, 2011, 2015, 2025), ], colour = bleu, size = 2.6) +
  geom_text(data = f2[f2$annee %in% c(2007, 2011, 2015, 2025), ],
            aes(label = formatC(chf_par_euro, format = "f", digits = 2, decimal.mark = ",")),
            vjust = -1, hjust = -0.15, colour = encre, size = 3.6) +
  scale_x_continuous(breaks = seq(2002, 2025, 3)) +
  scale_y_continuous(limits = c(0.85, 1.75), labels = function(x) formatC(x, format = "f", digits = 2, decimal.mark = ",")) +
  labs(title = "En dix-huit ans, le franc suisse a gagné 75 % face à l'euro",
       subtitle = "Francs suisses pour un euro, moyenne annuelle. Quand la courbe baisse, le franc s'apprécie.",
       x = NULL, y = "Francs suisses pour un euro",
       caption = "Source : Banque centrale européenne, cours de référence quotidiens.") +
  theme_etude
ggsave(file.path("figures", "fig2_franc_suisse.png"), g2, width = 8, height = 4.6, dpi = 200)

# --- Figure 3 : la construction par groupe de communes ----------------------
f3 <- aggregate(cbind(aut_tous, population_2011) ~ groupe + annee, data = base, FUN = sum)
f3$taux <- 1000 * f3$aut_tous / f3$population_2011
couleurs <- setNames(c(bleu_clair, bleu, bleu_fonce), groupes)
fin <- f3[f3$annee == max(f3$annee), ]
fin <- fin[order(fin$taux), ]
fin$y <- fin$taux
for (i in 2:nrow(fin)) fin$y[i] <- max(fin$y[i], fin$y[i - 1] + 0.9)   # écarte les étiquettes trop proches
g3 <- ggplot(f3, aes(annee, taux, colour = groupe)) +
  geom_line(linewidth = 0.9) +
  geom_text(data = fin, aes(y = y, label = groupe), hjust = 0, nudge_x = 0.3, size = 3.5, colour = encre) +
  scale_colour_manual(values = couleurs) +
  scale_x_continuous(breaks = seq(2002, 2025, 3), limits = c(2002, 2031.5)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Depuis 2015, on construit deux fois plus dans les communes de frontaliers",
       subtitle = "Logements autorisés par an pour 1 000 habitants, selon la part de frontaliers vers la Suisse en 2011",
       x = NULL, y = "Logements autorisés pour 1 000 habitants",
       caption = "Sources : SDES, Sitadel ; Insee, recensement 2011. Population de 2011 au dénominateur.") +
  theme_etude
ggsave(file.path("figures", "fig3_construction_par_groupe.png"), g3, width = 8, height = 4.6, dpi = 200)

# --- Tableau de synthèse ------------------------------------------------------
base$periode <- cut(base$annee, c(2001, 2007, 2014, 2021, 2025), labels = c("2002-2007", "2008-2014", "2015-2021", "2022-2025"))
t3 <- aggregate(cbind(aut_tous, population_2011) ~ groupe + periode, data = base, FUN = sum)
t3$taux <- round(1000 * t3$aut_tous / t3$population_2011, 1)
tab <- reshape(t3[, c("groupe", "periode", "taux")], idvar = "groupe", timevar = "periode", direction = "wide")
names(tab) <- sub("taux.", "", names(tab), fixed = TRUE)
tab$communes <- as.vector(table(communes$groupe)[as.character(tab$groupe)])
print(tab, row.names = FALSE)
write.csv2(tab, file.path("base", "tableau_construction_par_groupe.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("Variation du franc 2007-2025 :", round(100 * (f2$chf_par_euro[f2$annee == 2007] / f2$chf_par_euro[f2$annee == 2025] - 1)), "%\n")
