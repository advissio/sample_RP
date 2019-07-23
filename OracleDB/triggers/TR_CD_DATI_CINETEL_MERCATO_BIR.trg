CREATE OR REPLACE TRIGGER VENCD.TR_CD_DATI_CINETEL_MERCATO_BIR BEFORE INSERT ON VENCD.CD_DATI_CINETEL_MERCATO FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Febbraio 2010
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('DATI_CINETEL_MERCATO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_DATI_CINETEL_MERCATO_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_DATI_CINETEL_MERCATO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('DATI_CINETEL_MERCATO_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('DATI_CINETEL_MERCATO_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




