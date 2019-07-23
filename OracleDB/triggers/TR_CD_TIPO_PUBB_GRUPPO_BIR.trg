CREATE OR REPLACE TRIGGER VENCD.TR_CD_TIPO_PUBB_GRUPPO_BIR BEFORE INSERT ON VENCD.CD_TIPO_PUBB_GRUPPO FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('TIPO_PUBB_GRUPPO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_TIPO_PUBB_GRUPPO_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_TIPO_PUBB_GRUPPO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('TIPO_PUBB_GRUPPO_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('TIPO_PUBB_GRUPPO_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




