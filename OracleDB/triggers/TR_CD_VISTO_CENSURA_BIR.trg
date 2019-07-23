CREATE OR REPLACE TRIGGER VENCD.TR_CD_VISTO_CENSURA_BIR BEFORE INSERT ON VENCD.CD_VISTO_CENSURA FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Novembre 2010
   -- ----------------------------------------------------------------------------------------

 -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('VISTO_CENSURA_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_VISTO_CENSURA_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;

     :NEW.ID_VISTO_CENSURA := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('VISTO_CENSURA_BIR');


EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('VISTO_CENSURA_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




