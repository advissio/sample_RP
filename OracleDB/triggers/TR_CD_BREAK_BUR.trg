CREATE OR REPLACE TRIGGER VENCD.TR_CD_BREAK_BUR BEFORE UPDATE ON VENCD.CD_BREAK FOR EACH ROW
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('BREAK_BUR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
   PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                           :NEW.UTEMOD,
                           :NEW.DATAMOD,
                           PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                           );
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('BREAK_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('BREAK_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




