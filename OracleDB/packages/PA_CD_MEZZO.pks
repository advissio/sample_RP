CREATE OR REPLACE PACKAGE VENCD.PA_CD_MEZZO IS
--
-- ------------------------------------------------------------------------------------------
-- DESCRIZIONE: CONTENITORE PER COSTANTI DIPENDENTI DAL MEZZO
--
-- REALIZZATORE: Luigi Cipolla, Settembre 2009
--
-- MODIFICHE
-- 21/12/2009  Autore Mauro Viel Altran  aggiunte funzioni FU_TESTATA_NAZIONALE e FU_TESTATA_LOCALE. Le funzioni restituiscono le costanti omonime.
-- La modifica e necessarie per la gestione della testata editoriale a livello di piano.
--01/07/2010 Mauro Viel agginta la testata Cinema eventi e su agestione.
-- ------------------------------------------------------------------------------------------
--
--
-- ------------------------------------------------------------------------------------------
-- COSTANTI
--
GEST_COMM CHAR(2) := 'CI'; -- Identifica la gestione commerciale
--
SOTTOSISTEMA CHAR(2) := 'CD'; -- Identifica il sottosistema per la sicurezza funzionale
--
MEZZO CHAR(1) := 'C';    -- Identifica il mezzo
--
ARROTONDAMENTO NUMBER := 0.01; -- Valore di arrotondamento dipendente dal mezzo.
--
TESTATA_NAZIONALE VARCHAR(2) := '00'; --
TESTATA_LOCALE VARCHAR(2) := '01'; --
TESTATA_CINEMA_EVENTI VARCHAR(2) := '02';
--
-- ------------------------------------------------------------------------------------------
--
-- ------------------------------------------------------------------------------------------
-- FUNZIONI
--
-- Restituisce il valore di gestione commerciale.
FUNCTION FU_GEST_COMM RETURN CHAR;
   PRAGMA RESTRICT_REFERENCES (FU_GEST_COMM,WNDS,RNDS,WNPS);
--
-- Restituisce il valore di sottosistema.
FUNCTION FU_SOTTOSISTEMA RETURN CHAR;
   PRAGMA RESTRICT_REFERENCES (FU_SOTTOSISTEMA,WNDS,RNDS,WNPS);
--
--  Restituisce il valore di mezzo.
FUNCTION FU_MEZZO RETURN CHAR;
   PRAGMA RESTRICT_REFERENCES (FU_MEZZO,WNDS,RNDS,WNPS);
--
-- Restituisce il valore di arrotondamento, usato nel calcolo della tariffa.
FUNCTION FU_ARROTONDAMENTO RETURN NUMBER;
   PRAGMA RESTRICT_REFERENCES (FU_ARROTONDAMENTO,WNDS,RNDS,WNPS);
--
-- Restituisce il valore di testata
FUNCTION  FU_TESTATA(P_ID_PRODOTTO_VENDITA CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE)  RETURN VARCHAR;
   --PRAGMA RESTRICT_REFERENCES (FU_TESTATA,WNDS,RNDS,WNPS);
--
FUNCTION FU_TESTATA_NAZIONALE RETURN VARCHAR;
FUNCTION FU_TESTATA_LOCALE RETURN VARCHAR;
FUNCTION FU_TESTATA_CINEMA_EVENTI RETURN VARCHAR;
-- ------------------------------------------------------------------------------------------
--
END; 
/

