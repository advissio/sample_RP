CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_GRUPPO_ESERCENTE
(ID_GRUPPO_ESERCENTE, NOME_GRUPPO, DATA_INIZIO, DATA_FINE, FLG_ANNULLATO)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_GRUPPO_ESERCENTE
--
-- Vista contenente i gruppi esercenti estratti dall'anagrafica Sipra. La vista e in sostituzione temporanea
-- della tavola cd_gruppo_esercente. La vista verra rimpiazzata dalla tavola qundo i dati degli esercenti non
-- verranno piu gestiti da smartstream
--
-- REALIZZATORE: MAURO VIEL, Altran 12/04/2010
--
-- MODIFICHE:
--   Luigi Cipolla, 14/04/2010
--     Revisione
-----------------------------------------------------------------------------------------------------
  COD_INTERL AS ID_GRUPPO_ESERCENTE,
  RAG_SOC_COGN AS NOME_GRUPPO,
  DT_INIZ_VAL AS  DATA_INIZIO,
  DT_FINE_VAL AS  DATA_FINE,
  'N' as FLG_ANNULLATO
FROM  INTERL_U
WHERE COD_INTERL_TIPO ='GL'
/



