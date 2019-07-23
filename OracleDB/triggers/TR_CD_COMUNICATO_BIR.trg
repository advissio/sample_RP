CREATE OR REPLACE TRIGGER VENCD.TR_CD_COMUNICATO_BIR BEFORE INSERT ON VENCD.CD_COMUNICATO FOR EACH ROW
DECLARE

v_nextval NATURAL;


BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Simone Bottani, Altran, Luglio 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('COMUNICATO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_COMUNICATO_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_COMUNICATO := v_nextval;


   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('COMUNICATO_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('COMUNICATO_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




