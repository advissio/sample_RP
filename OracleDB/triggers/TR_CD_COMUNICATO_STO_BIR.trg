CREATE OR REPLACE TRIGGER VENCD.TR_CD_COMUNICATO_STO_BIR BEFORE INSERT ON VENCD.CD_COMUNICATO_STO FOR EACH ROW
DECLARE

v_nextval NATURAL;


BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel , Altran, Agosto 2010
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('COMUNICATO_STO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_COMUNICATO_STO_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_COMUNICATO_STO := v_nextval;


   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('COMUNICATO_STO_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('COMUNICATO_STO_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




