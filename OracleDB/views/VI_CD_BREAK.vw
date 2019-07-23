CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_BREAK
(ID, ID_PROIEZIONE, ID_SALA, DATA_COMMERCIALE, TIPO_BREAK)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_BREAK
--
-- DESCRIZIONE:
--   Estrae i Break validi per la messa in onda.
--   Gestire break Top Spot,Frame Screen e Locale
--
-- REALIZZATORE: Antonio Colucci, Teoresi s.r.l. - 26/10/2009
--
-- MODIFICHE:
--     06/07/2010, Angelo Marletta
--           Eliminate colonne DATA_PREV, e fascia oraria
--     08/07/2010, Angelo Marletta
--           Eliminati break relativi alle arene
--     01/09/2010, Angelo Marletta
--           Eliminati break relativi alle sale virtuali
-----------------------------------------------------------------------------------------------------
ID_BREAK as ID, CD_PROIEZIONE.ID_PROIEZIONE,CD_SALA.ID_SALA,
DATA_PROIEZIONE AS DATA_COMMERCIALE,
CD_TIPO_BREAK.DESC_TIPO_BREAK AS TIPO_BREAK
FROM CD_BREAK, CD_PROIEZIONE, CD_SCHERMO, CD_TIPO_BREAK, CD_SALA, CD_CINEMA
WHERE CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
AND   CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN PA_CD_ADV_CINEMA.FU_DATA_INIZIO AND PA_CD_ADV_CINEMA.FU_DATA_FINE
AND   CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
AND   CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
AND   CD_BREAK.FLG_ANNULLATO = 'N'
AND   CD_SALA.FLG_ARENA = 'N'
AND   CD_TIPO_BREAK.ID_TIPO_BREAK = CD_BREAK.ID_TIPO_BREAK
AND   (CD_TIPO_BREAK.DESC_TIPO_BREAK = 'Trailer' or CD_TIPO_BREAK.DESC_TIPO_BREAK = 'Inizio Film')
AND   CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
AND   CD_CINEMA.FLG_ANNULLATO = 'N'
AND   CD_CINEMA.FLG_VIRTUALE = 'N'
/



