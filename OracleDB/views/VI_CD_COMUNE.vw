CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_COMUNE
(ID, ID_PROVINCIA, NOME)
AS 
SELECT  
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_COMUNE
--
-- Estrae la lista dei comuni disponibili a sistema
--
-- REALIZZATORE: Antonio Colucci, Teoresi s.r.l. 26/10/2009
--
-- MODIFICHE:
--    Viene mostrato il nome del comune anziche il nome della provincia, Angelo Marletta, 6/10/2010
--
-----------------------------------------------------------------------------------------------------
ID_COMUNE as ID, CD_COMUNE.ID_PROVINCIA, CD_COMUNE.COMUNE AS NOME
FROM CD_COMUNE, CD_PROVINCIA
WHERE CD_COMUNE.ID_PROVINCIA = CD_PROVINCIA.ID_PROVINCIA
/



