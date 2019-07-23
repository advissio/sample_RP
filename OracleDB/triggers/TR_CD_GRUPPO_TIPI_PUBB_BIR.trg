CREATE OR REPLACE TRIGGER VENCD.TR_CD_GRUPPO_TIPI_PUBB_BIR BEFORE INSERT ON VENCD.CD_GRUPPO_TIPI_PUBB FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('GRUPPO_TIPI_PUBB_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_GRUPPO_TIPI_PUBB_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_GRUPPO_TIPI_PUBB := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('GRUPPO_TIPI_PUBB_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('GRUPPO_TIPI_PUBB_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




