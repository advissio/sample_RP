CREATE OR REPLACE TRIGGER VENCD.TR_CD_SALA_TARGET_BIR BEFORE INSERT ON VENCD.CD_SALA_TARGET FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Novembre 2011
   -- ----------------------------------------------------------------------------------------

 -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CD_SALA_TARGET_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_SALA_TARGET_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;

     :NEW.ID_SALA_TARGET := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CD_SALA_TARGET_BIR');


EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CD_SALA_TARGET_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




