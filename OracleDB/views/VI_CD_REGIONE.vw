CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_REGIONE
(ID, NOME)
AS 
SELECT 
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_REGIONE
--
-- Estrae la lista delle regioni disponibili a sistema
--
-- REALIZZATORE: Antonio Colucci, Teoresi s.r.l. 26/10/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
ID_REGIONE as ID,NOME_REGIONE AS NOME FROM CD_REGIONE
/



