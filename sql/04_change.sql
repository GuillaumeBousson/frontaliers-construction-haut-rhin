-- Francs suisses pour un euro, moyenne annuelle des cours quotidiens de la BCE.
-- Quand ce nombre baisse, le franc suisse s'apprécie.
CREATE TABLE change AS
SELECT
    CAST(substr(jour, 1, 4) AS INTEGER) AS annee,
    AVG(chf)                            AS chf_par_euro,
    COUNT(*)                            AS jours_cotes
FROM change_quotidien
WHERE chf IS NOT NULL
GROUP BY 1;
