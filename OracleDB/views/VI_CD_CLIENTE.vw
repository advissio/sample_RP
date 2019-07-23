CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_CLIENTE
OF VENCD.CLIENTE
WITH OBJECT IDENTIFIER (ID_CLIENTE)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_CLIENTE
--
-- Estrae i clienti commerciali validi
-- condizionati  alla limitazione sull'interlocutore dell'utente di sessione.
--
-- REALIZZATORE: Mauro  Viel, 06/07/2009
--
-- MODIFICHE: Mauro Viel Altran, 01/12/2012 Modificata regola di estrazione. #MV01
--
-----------------------------------------------------------------------------------------------------
id_cliente,
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
from VI_CD_CLICOMM
where decode( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(id_cliente),'S')  = 'S'
--and sysdate  between  data_inizio_validita  and data_fine_validita #MV01
and sysdate <= data_fine_validita
/



