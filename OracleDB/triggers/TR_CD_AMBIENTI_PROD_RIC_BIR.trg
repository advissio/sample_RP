CREATE OR REPLACE TRIGGER VENCD.TR_CD_AMBIENTI_PROD_RIC_BIR BEFORE INSERT ON VENCD.CD_AMBIENTI_PRODOTTI_RICHIESTI FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Viel Mauro, Altran, Novembre 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CD_AMBIENTI_PRODOTTI_RICHIESTI');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_AMBIENTI_PRODOTTI_RIC_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_AMBIENTI_PRODOTTI_RICHIESTI := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CD_AMBIENTI_PRODOTTI_RICHIESTI');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CD_AMBIENTI_PRODOTTI_RICHIESTI');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




