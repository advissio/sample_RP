CREATE OR REPLACE TRIGGER VENCD.TR_CD_QUOTA_ESER_BIR BEFORE INSERT ON VENCD.CD_QUOTA_ESERCENTE FOR EACH ROW
DECLARE
v_nextval NATURAL;
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Aprile 2010
   -- ----------------------------------------------------------------------------------------
   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('QUOTA_ESER_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_QUOTA_ESER_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;
     :NEW.ID_QUOTA_ESERCENTE := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('QUOTA_ESER_BIR');
EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('QUOTA_ESER_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




