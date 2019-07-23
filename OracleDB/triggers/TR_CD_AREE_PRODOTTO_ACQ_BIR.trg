CREATE OR REPLACE TRIGGER VENCD.TR_CD_AREE_PRODOTTO_ACQ_BIR BEFORE INSERT ON VENCD.CD_AREE_PRODOTTO_ACQUISTATO FOR EACH ROW
DECLARE
       
v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Viel Mauro, Altran, Novembre 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CD_AREE_PRODOTTO_ACQ');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
  
      SELECT CD_AREE_PRODOTTO_ACQ_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;

  
     :NEW.ID_AREE_PRODOTTO_ACQUISTATO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CD_AREE_PRODOTTO_ACQ');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CD_AREE_PRODOTTO_ACQ');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




