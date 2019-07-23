CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_VENDITORE
OF VENCD.VENDITORE
WITH OBJECT IDENTIFIER (ID_VENDITORE)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_CENTRO_MEDIA
--
-- Estrae i venditori validi
--
-- REALIZZATORE: Mauro  Viel, 06/07/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
cod_interl as id_venditore,
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
from interl_u  where cod_interl_tipo in ('AG','PG')
and sysdate  between  DT_INIZ_VAL and DT_FINE_VAL
/



