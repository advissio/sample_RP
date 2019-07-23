CREATE OR REPLACE TRIGGER VENCD.TR_CD_RICERCA_COMP_SCHERMI_BIR BEFORE INSERT ON VENCD.CD_RICERCA_COMP_SCHERMI FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Dicembre 2010
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('RICERCA_COMP_SCHERMI_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_RICERCA_COMP_SCHERMI_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_RICERCA := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('RICERCA_COMP_SCHERMI_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('RICERCA_COMP_SCHERMI_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




