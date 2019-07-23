CREATE OR REPLACE TRIGGER VENCD.TR_CD_PIANIFICAZIONE_BUR BEFORE UPDATE ON VENCD.CD_PIANIFICAZIONE FOR EACH ROW
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- Modifica: Mauro Viel Altran inserita gestione sullo stato di lavorazione della pianificazione.
   -- Modifica: Mauro Viel Altran eliminata la messa in lavorazione del piano nel caso di modifica cliente o resp contatto
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('PIANIFICAZIONE_BUR');

   /*if (:old.ID_CLIENTE !=  :new.ID_CLIENTE ) or (:old.ID_RESPONSABILE_CONTATTO !=  :new.ID_RESPONSABILE_CONTATTO) then

       :new.ID_STATO_LAV := 1;

   end if;  */

   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
   PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                           :NEW.UTEMOD,
                           :NEW.DATAMOD,
                            PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                           );
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('PIANIFICAZIONE_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('PIANIFICAZIONE_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




