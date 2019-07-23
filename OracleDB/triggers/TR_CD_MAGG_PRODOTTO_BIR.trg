CREATE OR REPLACE TRIGGER VENCD.TR_CD_MAGG_PRODOTTO_BIR BEFORE INSERT ON VENCD.CD_MAGG_PRODOTTO FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Simone Bottani, Altran, Settembre 2009
   -- ----------------------------------------------------------------------------------------

  -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('MAGGIORAZIONE_PRODOTTO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_MAGG_PRODOTTO_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_MAGG_PRODOTTO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('MAGGIORAZIONE_PRODOTTO_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('MAGGIORAZIONE_PRODOTTO_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




