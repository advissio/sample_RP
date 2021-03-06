CREATE OR REPLACE TRIGGER VENCD.TR_CD_PRD_STATO_VENDITA_BIR BEFORE INSERT ON VENCD.CD_PRD_ACQ_STATO_VENDITA FOR EACH ROW
DECLARE

v_nextval natural;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('PRD_ACQ_STATO_VENDITA_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_PRD_ACQ_STATO_VENDITA_seq.NEXTVAL
      INTO v_nextval
     FROM dual;


     :NEW.ID_PRODOTTO_STATO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('PRD_ACQ_STATO_VENDITA_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('PRD_ACQ_STATO_VENDITA_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




