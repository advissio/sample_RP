CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_AREE_SEDI_COMPET
(COD_AREA, COD_SEDE, DES_AREA, DES_ABBR_AREA, DES_SEDE, 
 DES_ABBR_SEDE, DES_SEDE_ESTESA)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_AREE_SEDI_COMPET
--
-- Estrae Aree e Sedi di interesse della Gestione commerciale corrente,
-- condizionate alla limitazione territoriale dell'utente di sessione.
--
-- REALIZZATORE: Luigi Cipolla, 06/10/2009
--
-- MODIFICHE: Mauro Viel Altran 11/01/2010 aggiunta descrizione estesa della sede.
--
-----------------------------------------------------------------------------------------------------
   CMD.cod_area,
   CMD.cod_sede,
   AR.descriz des_area,
   AR.des_abbr des_abbr_area,
   SE.des_sede,
   SE.des_abbr des_abbr_sede,
   SE.descrizione_estesa
from sedi SE,
     aree AR,
     gest_comm_aree GCA,
     cmdareesedi_compet CMD
where CMD.idn_rich = PA_SESSIONE.FU_LEGGI_IR_AREESEDI
  and GCA.cod_area = CMD.cod_area
  and GCA.cod_comm = PA_CD_MEZZO.FU_GEST_COMM
  and AR.cod_area  = CMD.cod_area
  and SE.cod_sede  = CMD.cod_sede
/



