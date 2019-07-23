CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_MATERIALI_SOGGETTI
(ID_MATERIALE, TITOLO, TRADUZIONE_TITOLO, DESCRIZIONE, DURATA, 
 NAZIONALITA, AGENZIA_PRODUZ, DATA_INSERIMENTO, DES_SOGG, RAGSOC)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_MATERIALI_SOGGETTI
--
-- DESCRIZIONE:
--   Estrae i Materiali validi per la messa in onda.
--   Usata dal vecchio cinema.
--
-- REALIZZATORE: Luigi Cipolla, 17/12/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
  MAT.ID_MATERIALE
 ,MAT.TITOLO
 ,MAT.TRADUZIONE_TITOLO
 ,MAT.DESCRIZIONE
 ,MAT.DURATA
 ,MAT.NAZIONALITA
 ,MAT.AGENZIA_PRODUZ
 ,MAT.DATA_INSERIMENTO
 ,SO.DES_SOGG
 ,CLI.ragsoc
from
  clicomm CLI,
  soggetti SO,
  cd_materiale_soggetti MAT_SO,
  cd_materiale MAT
where
      nvl(MAT.DATA_FINE_VALIDITA, sysdate) <= sysdate
  and MAT_SO.ID_MATERIALE = MAT.ID_MATERIALE
  and SO.cod_sogg = MAT_SO.cod_sogg
  and CLI.cod_interl = MAT.ID_CLIENTE
/



