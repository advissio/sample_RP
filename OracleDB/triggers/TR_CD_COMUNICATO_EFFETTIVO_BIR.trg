CREATE OR REPLACE TRIGGER VENCD.TR_CD_comunicato_effettivo_BIR BEFORE INSERT ON VENCD.CD_COMUNICATO_EFFETTIVO FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran, Novembre 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('TR_CD_comunicato_effettivo_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_comunicato_effettivo_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_comunicato_effettivo := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('TR_CD_comunicato_effettivo_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('TR_CD_comunicato_effettivo_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




