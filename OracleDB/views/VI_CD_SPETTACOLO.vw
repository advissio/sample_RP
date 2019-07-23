CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SPETTACOLO
(ID, NOME, DATA_INIZIO, DATA_FINE)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_SPETTACOLO
--
-- Estrae la lista degli spettacoli disponibili
--
-- REALIZZATORE: Luigi Cipolla, 15/01/2010
--
-- MODIFICHE:
--
-----------------------------------------------------------------------------------------------------
  ID_SPETTACOLO    ID
 ,NOME_SPETTACOLO  NOME
 ,DATA_INIZIO
 ,DATA_FINE
FROM CD_SPETTACOLO
/



