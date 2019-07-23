CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_TIPO_COMMITTENTE
OF VENCD.TIPO_COMMITTENTE
WITH OBJECT IDENTIFIER (ID_TIPO_COMMITTENTE)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_TIPO_COMMITTENTE
--
-- Estrae i committenti validi
--
-- REALIZZATORE: Mauro  Viel, 06/07/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
cod_interl as id_tipo_commitente,
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
from interl_u   where cod_interl_tipo ='CC'
and sysdate  between  DT_INIZ_VAL and DT_FINE_VAL
/



