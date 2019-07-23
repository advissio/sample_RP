CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SOCIETA_GRUPPO
(ID_SOCIETA_GRUPPO, ID_GRUPPO_ESERCENTE, COD_ESERCENTE, DATA_INIZIO_VAL, DATA_FINE_VAL)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_SOCIETA_GRUPPO
--
-- La vista e in sostituzione temporanea della tavola CD_SOCIETA_GRUPPO. La vista verra rimpiazzata dalla 
-- Vista contenente l'associazione esercente con un gruppo  cd_societa_gruppo dedotte dall'anagrafica Sipra. 
-- tavola qundo i dati degli esercenti non 
-- verranno piu gestiti da smartstream 
--
-- REALIZZATORE: MAURO VIEL, Altran 12/04/2010
--
-- MODIFICHE:
--   Luigi Cipolla, 14/04/2010
--     Revisione
-----------------------------------------------------------------------------------------------------
distinct
  COD_INTERL_P||COD_INTERL_F as id_societa_gruppo,
  COD_INTERL_P id_gruppo_esercente,
  COD_INTERL_F COD_ESERCENTE,
  dt_iniz_val data_inizio_val,
  dt_fine_val data_fine_val
from raggruppamento_u
where TIPO_RAGGRUPP ='GLLC'
/



