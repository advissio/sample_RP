CREATE OR REPLACE TRIGGER VENCD.TR_CD_CIRC_TIPO_BREAK_BIR BEFORE INSERT ON VENCD.CD_CIRCUITO_TIPO_BREAK FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Luglio 2011
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CIRC_TIPO_BREAK_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_CIRC_TIPO_BREAK_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_CIRCUITO_TIPO_BREAK := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CIRC_TIPO_BREAK_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CIRC_TIPO_BREAK_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




