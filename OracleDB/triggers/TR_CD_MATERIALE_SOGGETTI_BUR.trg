CREATE OR REPLACE TRIGGER VENCD.TR_CD_MATERIALE_SOGGETTI_BUR BEFORE UPDATE ON VENCD.CD_MATERIALE_SOGGETTI FOR EACH ROW
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio colucci, Teoresi, Dicembre 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('MATERIALE_SOGGETTI_BUR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
   PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                           :NEW.UTEMOD,
                           :NEW.DATAMOD,
                            PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                           );
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('MATERIALE_SOGGETTI_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('MATERIALE_SOGGETTI_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




