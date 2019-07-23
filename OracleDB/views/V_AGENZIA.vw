CREATE OR REPLACE FORCE VIEW VENCD.V_AGENZIA
OF VENCD.AGENZIA
WITH OBJECT IDENTIFIER (ID_AGENZIA)
AS 
SELECT cod_interl as id_agenzia,
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
from interl_u  where cod_interl_tipo ='AZ'
and sysdate  between  DT_INIZ_VAL and DT_FINE_VAL
/



