CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_CLI_FATTURAZIONE
(COD_MEZZO, COD_GC, COD_SOTTOSISTEMA, COD_PIANO, VERSIONE_PIANO, 
 COD_CLI_FRUITORE, DES_CLI_FRUITORE, COD_CLI_COMMITTENTE, DES_CLI_COMMITTENTE)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA  VI_CD_CLI_FATTURAZIONE
--
-- DESCRIZIONE:
--   Estrae i clienti del Mezzo Cinema per la Fatturazione
--
-- REALIZZATORE: Luigi Cipolla - 20/12/2010
--
-- MODIFICHE:
-----------------------------------------------------------------------------------------------------
distinct
  PA_CD_MEZZO.fu_mezzo              COD_MEZZO
 ,PA_CD_MEZZO.fu_gest_comm          COD_GC
 ,PA_CD_MEZZO.fu_sottosistema       COD_SOTTOSISTEMA
 ,PIA.id_piano                      COD_PIANO
 ,PIA.id_ver_piano                  VERSIONE_PIANO
 ,C_F.cod_interl 	                cod_cli_fruitore
 ,C_F.rag_soc_cogn                  des_cli_fruitore
 ,C_FC.cod_interl                   cod_cli_committente
 ,C_FC.rag_soc_cogn                 des_cli_committente
from
  interl_u C_FC,
  interl_u C_F,
  cd_fruitori_di_piano CLI_AMM,
  cd_ordine ORD,
  cd_pianificazione PIA
where ORD.id_piano = PIA.id_piano
  and ORD.id_ver_piano = PIA.id_ver_piano
  and CLI_AMM.ID_FRUITORI_DI_PIANO = ORD.ID_FRUITORI_DI_PIANO
  and C_F.cod_interl	= CLI_AMM.ID_CLIENTE_FRUITORE
  and C_FC.cod_interl   = ORD.ID_CLIENTE_COMMITTENTE
/



