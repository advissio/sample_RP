CREATE OR REPLACE TRIGGER VENCD.CD_ADV_COMUNICATO_TEST_BIR BEFORE INSERT ON VENCD.CD_ADV_COMUNICATO_TEST FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Marzo 2010
   -- ----------------------------------------------------------------------------------------

 -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('ADV_COMUNICATO_TEST_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_ADV_COMUNICATO_TEST_0.NEXTVAL
      INTO v_nextval
     FROM DUAL;

     :NEW.ID := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('ADV_COMUNICATO_TEST_BIR');


EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('ADV_COMUNICATO_TEST_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




