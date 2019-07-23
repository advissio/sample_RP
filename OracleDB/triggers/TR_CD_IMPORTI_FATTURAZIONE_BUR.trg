CREATE OR REPLACE TRIGGER VENCD.TR_CD_IMPORTI_FATTURAZIONE_BUR BEFORE UPDATE ON VENCD.CD_IMPORTI_FATTURAZIONE FOR EACH ROW
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran , Giugno 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('IMPORTI_FATTURAZIONE_BUR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
   PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                           :NEW.UTEMOD,
                           :NEW.DATAMOD,
                            PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                           );
                           
   IF :NEW.STATO_FATTURAZIONE != :OLD.STATO_FATTURAZIONE THEN  
   
       :NEW.DATAMOD_FATTURAZIONE  := SYSDATE;                     
       
       IF :NEW.STATO_FATTURAZIONE = 'TRA' THEN
         :NEW.DATA_FATTURAZIONE := SYSDATE;
       ELSE
         :NEW.DATA_FATTURAZIONE := NULL;
       END IF;
   END IF;
   
   IF (:NEW.IMPORTO_NETTO != :OLD.IMPORTO_NETTO)  OR (:NEW.FLG_INCLUSO_IN_ORDINE != :OLD.FLG_INCLUSO_IN_ORDINE) THEN
      PA_CD_ORDINE.PR_IMPOSTA_FLG_MODIFICA_ORDINE(:NEW.ID_ORDINE, 'S');
   END IF;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('IMPORTI_FATTURAZIONE_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('IMPORTI_FATTURAZIONE_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




