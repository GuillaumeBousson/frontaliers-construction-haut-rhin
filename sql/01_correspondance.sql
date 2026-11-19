-- Géographie de référence : les 366 communes du Haut-Rhin au 1er janvier 2025.
-- Chaque ancien code de commune est rattaché à la commune actuelle.
CREATE TABLE correspondance AS
SELECT CODGEO AS code, CODGEO AS com, LIBGEO AS nom
FROM population_brute
WHERE DEP = '68'
UNION ALL
SELECT p.ancien AS code, p.actuel AS com, r.LIBGEO AS nom
FROM passage AS p
JOIN population_brute AS r ON r.CODGEO = p.actuel;
