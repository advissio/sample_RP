CREATE OR REPLACE TRIGGER VENCD.TR_CAUSALE_CINETEL_SEQ_BIR BEFORE INSERT ON VENCD.CD_CAUSALE_CINETEL FOR EACH ROW
DECLARE
v_nextval NATURAL;
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Luglio 2010
   -- ----------------------------------------------------------------------------------------
   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CAUSALE_CINETEL_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
      SELECT CD_CAUSALE_CINETEL_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;
     :NEW.ID_CINETEL := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CAUSALE_CINETEL_BIR');
EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CAUSALE_CINETEL_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




