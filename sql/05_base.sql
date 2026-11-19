-- Base finale : une ligne par commune et par année, de 2002 à 2025.
CREATE TABLE base AS
SELECT
    g.com,
    g.nom,
    a.annee,
    k.aut_tous, k.aut_individuel, k.aut_collectif, k.com_tous,
    p.population,
    p11.population                         AS population_2011,
    x.chf_par_euro,
    f11.actifs                             AS actifs_2011,
    f11.suisse                             AS suisse_2011,
    f11.allemagne                          AS allemagne_2011,
    100.0 * f11.suisse / f11.actifs        AS part_suisse_2011,
    100.0 * f11.allemagne / f11.actifs     AS part_allemagne_2011,
    f18.suisse                             AS suisse_2018,
    f22.suisse                             AS suisse_2022,
    f22.actifs                             AS actifs_2022
FROM (SELECT DISTINCT com, nom FROM correspondance) AS g
CROSS JOIN (SELECT DISTINCT annee FROM construction) AS a
LEFT JOIN construction AS k   ON k.com = g.com AND k.annee = a.annee
LEFT JOIN population   AS p   ON p.com = g.com AND p.annee = a.annee
LEFT JOIN population   AS p11 ON p11.com = g.com AND p11.annee = 2011
LEFT JOIN change       AS x   ON x.annee = a.annee
LEFT JOIN frontaliers  AS f11 ON f11.com = g.com AND f11.annee = 2011
LEFT JOIN frontaliers  AS f18 ON f18.com = g.com AND f18.annee = 2018
LEFT JOIN frontaliers  AS f22 ON f22.com = g.com AND f22.annee = 2022
ORDER BY g.com, a.annee;
