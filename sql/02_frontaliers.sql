-- Actifs occupés par commune de résidence, dont ceux qui travaillent en Suisse (code SU...)
-- ou en Allemagne (code AL...). Source : recensements 2011, 2018 et 2022.
CREATE TABLE frontaliers AS
SELECT
    c.com,
    f.annee,
    SUM(f.flux)                                                   AS actifs,
    SUM(CASE WHEN substr(f.dclt, 1, 2) = 'SU' THEN f.flux ELSE 0 END) AS suisse,
    SUM(CASE WHEN substr(f.dclt, 1, 2) = 'AL' THEN f.flux ELSE 0 END) AS allemagne
FROM flux AS f
JOIN correspondance AS c ON c.code = f.codgeo
GROUP BY c.com, f.annee;
