CREATE OR REPLACE TRIGGER VENCD.TR_CD_SALA_TARGET_BUR BEFORE UPDATE ON VENCD.CD_SALA_TARGET FOR EACH ROW
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Novembre 2011
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('SALA_TARGET_BUR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
   PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                           :NEW.UTEMOD,
                           :NEW.DATAMOD,
                           PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                           );
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('SALA_TARGET_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('SALA_TARGET_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




