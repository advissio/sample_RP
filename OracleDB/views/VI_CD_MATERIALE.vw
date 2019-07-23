CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_MATERIALE
(ID, NOME_FILE, DURATA, DESCRIZIONE, ID_CLIENTE, 
 DATA_INSERIMENTO, DATA_INIZIO_VALIDITA, DATA_FINE_VALIDITA, TITOLO, DESC_SCENEGGIATURA, 
 AGENZIA_PRODUZ, TRADUZIONE_TITOLO, NAZIONALITA)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_MATERIALE
--
-- Estrae la lista dei comuni disponibili a sistema
--
-- REALIZZATORE: Antonio Colucci, Teoresi s.r.l. 26/10/2009
--
-- MODIFICHE:
--   Luigi Cipolla, 22/02/2010  [LC #1]
--     Inserimento colonne
--
-----------------------------------------------------------------------------------------------------
  ID_MATERIALE ID
 ,NOME_FILE
 ,DURATA
 ,TITOLO DESCRIZIONE
 ,ID_CLIENTE
 ,DATA_INSERIMENTO
 ,DATA_INIZIO_VALIDITA
 ,DATA_FINE_VALIDITA
 /* inizio [LC #1] */
 ,TITOLO
 ,DESCRIZIONE DESC_SCENEGGIATURA
 ,AGENZIA_PRODUZ
 ,TRADUZIONE_TITOLO
 ,NAZIONALITA
 /* fine [LC #1] */
FROM CD_MATERIALE
/



