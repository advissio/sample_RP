CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_CENTRO_MEDIA
OF VENCD.CENTRO_MEDIA
WITH OBJECT IDENTIFIER (ID_CENTRO_MEDIA)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_CENTRO_MEDIA
--
-- Estrae i centri media  validi
--
-- REALIZZATORE: Mauro  Viel, 06/07/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------

cod_interl as id_centro_media,
rag_soc_br_nome,
rag_soc_cogn,
indirizzo,
localita,
cap,
nazione,
cod_fisc,
num_civico,
provincia,
sesso,
area,
sede,
nome,
cognome
from interl_u  where cod_interl_tipo ='CM'
and sysdate  between  DT_INIZ_VAL and DT_FINE_VAL
/



