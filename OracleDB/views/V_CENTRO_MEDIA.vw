CREATE OR REPLACE FORCE VIEW VENCD.V_CENTRO_MEDIA
OF VENCD.CENTRO_MEDIA
WITH OBJECT IDENTIFIER (ID_CENTRO_MEDIA)
AS 
SELECT cod_interl as id_centro_media,
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



