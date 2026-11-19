-- Logements autorisés et commencés par commune actuelle et par année (Sitadel).
-- Le fichier national compte 4,3 millions de lignes : on ne garde que le Haut-Rhin.
CREATE TABLE construction AS
SELECT
    c.com,
    s.ANNEE AS annee,
    SUM(CASE WHEN s.TYPE_LGT = 'Tous Logements' THEN s.LOG_AUT END)                          AS aut_tous,
    SUM(CASE WHEN s.TYPE_LGT IN ('Individuel pur', 'Individuel groupe') THEN s.LOG_AUT END)  AS aut_individuel,
    SUM(CASE WHEN s.TYPE_LGT IN ('Collectif', 'Residence') THEN s.LOG_AUT END)               AS aut_collectif,
    SUM(CASE WHEN s.TYPE_LGT = 'Tous Logements' THEN s.LOG_COM END)                          AS com_tous
FROM sitadel AS s
JOIN correspondance AS c ON c.code = s.COMM
WHERE substr(s.COMM, 1, 2) = '68'
GROUP BY c.com, s.ANNEE;
