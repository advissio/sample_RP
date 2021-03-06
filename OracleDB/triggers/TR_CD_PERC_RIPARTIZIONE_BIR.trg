CREATE OR REPLACE TRIGGER VENCD.TR_CD_PERC_RIPARTIZIONE_BIR BEFORE INSERT ON VENCD.CD_PERCENTUALE_RIPARTIZIONE FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Febbraio 2010
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('PERC_RIPARTIZIONE_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_PERC_RIPARTIZIONE_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_PERC_RIPARTIZIONE := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('PERC_RIPARTIZIONE_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('PERC_RIPARTIZIONE_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




