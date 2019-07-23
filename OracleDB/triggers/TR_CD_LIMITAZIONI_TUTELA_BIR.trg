CREATE OR REPLACE TRIGGER VENCD.TR_CD_LIMITAZIONI_TUTELA_BIR BEFORE INSERT ON VENCD.CD_LIMITAZIONI_TUTELA FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran Italia, Giugno 2010
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CD_LIMITAZIONI_TUTELA_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_LIMITAZIONI_TUTELA_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_LIMITAZIONI_TUTELA := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CD_LIMITAZIONI_TUTELA_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CD_LIMITAZIONI_TUTELA_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




