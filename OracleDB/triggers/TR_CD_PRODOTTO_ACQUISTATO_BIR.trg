CREATE OR REPLACE TRIGGER VENCD.TR_CD_PRODOTTO_ACQUISTATO_BIR BEFORE INSERT ON VENCD.CD_PRODOTTO_ACQUISTATO FOR EACH ROW
DECLARE

v_nextval natural;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('PRODOTTO_ACQUISTATO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_PRODOTTO_ACQUISTATO_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_PRODOTTO_ACQUISTATO := v_nextval;

     PA_CD_PIANIFICAZIONE.PR_MODIFICA_STATO_LAVORAZIONE(:NEW.ID_PIANO,:NEW.ID_VER_PIANO,1);


     insert into cd_prd_acq_stato_vendita (PROGRESSIVO,STATO_DI_VENDITA,ID_PRODOTTO_ACQUISTATO)
     values (0,:new.stato_di_vendita,:new.id_prodotto_acquistato);
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('PRODOTTO_ACQUISTATO_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('PRODOTTO_ACQUISTATO_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




