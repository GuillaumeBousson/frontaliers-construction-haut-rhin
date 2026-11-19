# Fichiers à télécharger

Ces fichiers sont trop lourds pour le dépôt. Il faut les télécharger et les placer dans ce dossier, sans les renommer ni les décompresser. Je les ai récupérés le 19 novembre 2026.

| Fichier attendu | Contenu | Où le trouver |
|---|---|---|
| `Donnees-annuelles-communales-Logements.2026-10.csv` | Logements autorisés et commencés par commune et par type (Sitadel) | SDES : https://data.statistiques.developpement-durable.gouv.fr/dido/api/v1/datafiles/9c90a880-4ba0-49b4-b99d-d7dd6c810dd0/csv |
| `base-texte-flux-mobilite-domicile-lieu-travail-2011.zip` | Trajets domicile-travail de commune à commune, recensement 2011 | Insee : https://www.insee.fr/fr/statistiques/2022113 |
| `base-csv-flux-mobilite-domicile-lieu-travail-2018.zip` | Idem, recensement 2018 | Insee : https://www.insee.fr/fr/statistiques/5393835 |
| `base-flux-mobilite-domicile-lieu-travail-2022_csv.zip` | Idem, recensement 2022 | Insee : https://www.insee.fr/fr/statistiques/8582949 |
| `base-pop-historiques-1876-2023.xlsx` | Population municipale par commune | Insee : https://www.insee.fr/fr/statistiques/3698339 |
| `pred-app-mef-dhup.csv` et `pred-mai-mef-dhup.csv` | Loyers d'annonce au m², appartements et maisons, 2025 | Carte des loyers : https://www.data.gouv.fr/datasets/693aa2feed1bf4da603faa49/ |
| `eurofxref-hist.zip` | Taux de change quotidiens de l'euro | BCE : https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip |

Le nom du fichier Sitadel contient la date de sa mise à jour. S'il a changé, il suffit de le corriger en haut du script `01_preparer_donnees.R`.

# Fichiers déjà présents

Deux petites tables que j'ai préparées pour l'étude :

- `passage_communes_fusionnees_68.csv` : les onze anciennes communes du Haut-Rhin qui ont fusionné depuis 2002, avec le code de leur commune actuelle. Sans elle, leurs permis d'avant la fusion seraient perdus.
- `epci_communes_68.csv` : l'intercommunalité de chaque commune.
