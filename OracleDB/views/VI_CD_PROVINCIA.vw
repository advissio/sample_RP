CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_PROVINCIA
(ID, ID_REGIONE, NOME, SIGLA)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_PROVINCIA
--
-- Estrae la lista delle provincie disponibili a sistema
--
-- REALIZZATORE: Antonio Colucci, Teoresi s.r.l. 26/10/2009
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
ID_PROVINCIA as ID,ID_REGIONE,PROVINCIA AS NOME, ABBR AS SIGLA
FROM CD_PROVINCIA
/



