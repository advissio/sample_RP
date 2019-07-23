CREATE OR REPLACE TRIGGER VENCD.TR_CD_PRODOTTI_RICH_SEQ_BIR BEFORE INSERT ON CD_prodotti_richiesti FOR EACH ROW
DECLARE
       
v_nextval NATURAL; 

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Viel Mauro, Altran, Novembre 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CD_PRODOTTI_RICHIESTI_SEQ');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
  
      SELECT CD_AREE_PRODOTTO_ACQ_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;

  
     :NEW.ID_PRODOTTI_RICHIESTI := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CD_PRODOTTI_RICHIESTI_SEQ');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CD_PRODOTTI_RICHIESTI_SEQ');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




