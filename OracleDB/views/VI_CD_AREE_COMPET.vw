CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_AREE_COMPET
(COD_AREA, DESCRIZ, DES_ABBR, DATA_DA_VALID, DATA_A_VALID, 
 DESCRIZIONE_ESTESA, ORDINAMENTO)
AS 
SELECT distinct
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_AREE_COMPET
--
-- Estrae le Aree di interesse della Gestione commerciale corrente,
-- condizionate alla limitazione territoriale dell'utente di sessione.
--
-- REALIZZATORE: Luigi Cipolla, 06/10/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
  AR.COD_AREA,
  AR.DESCRIZ,
  AR.DES_ABBR,
  AR.DATA_DA_VALID,
  AR.DATA_A_VALID,
  AR.DESCRIZIONE_ESTESA,
  GCA.ORDINAMENTO
from aree AR,
     gest_comm_aree GCA,
     cmdareesedi_compet CMD
where CMD.idn_rich = PA_SESSIONE.FU_LEGGI_IR_AREESEDI
  and GCA. cod_area = CMD.cod_area
  and GCA.cod_comm = PA_CD_MEZZO.FU_GEST_COMM
  and AR. cod_area = GCA. cod_area
/



