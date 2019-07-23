CREATE OR REPLACE TRIGGER VENCD.TR_CD_CIRCUITO_RECUPERO_BIR BEFORE INSERT ON VENCD.CD_CIRCUITO_RECUPERO FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran, Luglio 2010
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CIRCUITO_RECUPERO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_CIRCUITO_RECUPERO_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_CIRCUITO_RECUPERO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CIRCUITO_RECUPERO');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CIRCUITO_RECUPERO');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




