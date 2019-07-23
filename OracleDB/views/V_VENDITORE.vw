CREATE OR REPLACE FORCE VIEW VENCD.V_VENDITORE
OF VENCD.VENDITORE
WITH OBJECT IDENTIFIER (ID_VENDITORE)
AS 
SELECT cod_interl as id_venditore,
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



