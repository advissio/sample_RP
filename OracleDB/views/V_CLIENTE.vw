CREATE OR REPLACE FORCE VIEW VENCD.V_CLIENTE
OF VENCD.CLIENTE
WITH OBJECT IDENTIFIER (ID_CLIENTE)
AS 
SELECT cod_interl as id_cliente,
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
from interl_u  where cod_interl_tipo ='CC'
and sysdate  between  DT_INIZ_VAL and DT_FINE_VAL
/



