CREATE OR REPLACE TRIGGER VENCD.TR_CD_PRODOTTO_ACQUISTATO_BUR
BEFORE UPDATE
ON VENCD.CD_PRODOTTO_ACQUISTATO REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('PRODOTTO_ACQUISTATO_BUR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
   PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                           :NEW.UTEMOD,
                           :NEW.DATAMOD,
                            PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                           );

       if   (:new.IMP_NETTO <> :old.IMP_NETTO) or
            --(:new.IMP_NETTO_DIR <> :old.IMP_NETTO_DIR) or
            (:new.IMP_RECUPERO <> :old.IMP_RECUPERO) or
            (:new.IMP_LORDO <> :old.IMP_LORDO) or
            (:new.IMP_MAGGIORAZIONE <> :old.IMP_MAGGIORAZIONE) or
            (:new.IMP_SANATORIA <> :old.IMP_SANATORIA) or
           -- (:new.IMP_SCO_COMM <> :old.IMP_SCO_COMM) or
            (:new.IMP_TARIFFA <> :old.IMP_TARIFFA) or
            (:new.STATO_DI_VENDITA <> :old.STATO_DI_VENDITA) or
            (:new.FLG_ANNULLATO <> :old.FLG_ANNULLATO) or
            (:new.FLG_SOSPESO <> :old.FLG_SOSPESO) then
               PA_CD_PIANIFICAZIONE.PR_MODIFICA_STATO_LAVORAZIONE(:NEW.ID_PIANO,:NEW.ID_VER_PIANO,1);
       end if;
       if   (:new.id_piano <> :old.id_piano)  or  (:new.id_ver_piano <> :old.id_ver_piano)  then
            PA_CD_PIANIFICAZIONE.PR_MODIFICA_STATO_LAVORAZIONE(:NEW.ID_PIANO,:NEW.ID_VER_PIANO,1);
            PA_CD_PIANIFICAZIONE.PR_MODIFICA_STATO_LAVORAZIONE(:OLD.ID_PIANO,:OLD.ID_VER_PIANO,1);
       end if;

   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('PRODOTTO_ACQUISTATO_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('PRODOTTO_ACQUISTATO_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




