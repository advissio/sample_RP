CREATE OR REPLACE TRIGGER VENCD.TR_CD_SCH_VIRTUALE_PROD_BIR BEFORE INSERT ON VENCD.CD_SCHERMO_VIRTUALE_PRODOTTO FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran , Luglio  2010
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('SCHERMO_VIRTUALE_PRODOTTO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_SCH_VIRTUALE_PRODOTTO_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_SCHERMO_VIRTUALE_PRODOTTO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('SCHERMO_VIRTUALE_PRODOTTOE_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('SCHERMO_VIRTUALE_PRODOTTOE_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




