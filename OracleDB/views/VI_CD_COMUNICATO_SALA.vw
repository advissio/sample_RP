CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_COMUNICATO_SALA
(ID_COMUNICATO, POSIZIONE, POSIZIONE_DI_RIGORE, VERIFICATO, DATA_EROGAZIONE_PREV, 
 ID_BREAK_VENDITA, ID_SOGGETTO_DI_PIANO, ID_PRODOTTO_ACQUISTATO, ID_MATERIALE_DI_PIANO, IMPORTO_SIAE, 
 ID_BREAK, ID_PROIEZIONE, ID_SCHERMO, ID_SALA, DATA_CONFERMA_SIAE)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_COMUNICATO_SALA
--
-- DESCRIZIONE:
-- Estrae i comunicati validi, corredati con l'ID_SALA
--
--  REALIZZATORE: Mauro Viel Altran - 01/02/2010
--
-- MODIFICHE:   Lugi Cipolla -02/02/2010
-- Modificata eliminata la colonna hh_prev mm_prev di comunicato.
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
com.ID_COMUNICATO,
com.POSIZIONE,
com.POSIZIONE_DI_RIGORE,
com.VERIFICATO,
com.DATA_EROGAZIONE_PREV,
com.ID_BREAK_VENDITA,
com.ID_SOGGETTO_DI_PIANO,
com.ID_PRODOTTO_ACQUISTATO,
com.ID_MATERIALE_DI_PIANO,
com.importo_siae,
brk.ID_BREAK,
pr.ID_PROIEZIONE,
sc.ID_SCHERMO,
sc.ID_SALA,
com.DATA_CONFERMA_SIAE
FROM
  CD_SCHERMO SC,
  CD_PROIEZIONE PR,
  CD_BREAK BRK,
  CD_CIRCUITO_BREAK C_BRK,
  CD_BREAK_VENDITA BRK_V,
  CD_COMUNICATO COM
WHERE COM.FLG_ANNULLATO = 'N'
  AND COM.FLG_SOSPESO = 'N'
  AND COM.COD_DISATTIVAZIONE IS NULL
  AND BRK_V.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
  AND BRK_V.FLG_ANNULLATO = 'N'
  AND C_BRK.ID_CIRCUITO_BREAK = BRK_V.ID_CIRCUITO_BREAK
  AND C_BRK.FLG_ANNULLATO = 'N'
  AND BRK.ID_BREAK = C_BRK.ID_BREAK
  AND BRK.FLG_ANNULLATO='N'
  AND PR.ID_PROIEZIONE = BRK.ID_PROIEZIONE
  AND PR.FLG_ANNULLATO='N'
  AND SC.ID_SCHERMO = PR.ID_SCHERMO
  AND SC.FLG_ANNULLATO = 'N'
/



