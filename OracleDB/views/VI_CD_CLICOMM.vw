CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_CLICOMM
OF VENCD.CLIENTE_COMM
WITH OBJECT IDENTIFIER (ID_CLIENTE)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_CLIENTE_COMM
--
-- Estrae i  tutti i clienti  comerciali
--
-- REALIZZATORE: Mauro  Viel, 06/07/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
cod_interl as id_cliente_comm,
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
cognome,
DT_INIZ_VAL as DATA_INIZIO_VALIDITA,
DT_FINE_VAL as DATA_FINE_VALIDITA
from interl_u
where cod_interl_tipo ='CC'
/



