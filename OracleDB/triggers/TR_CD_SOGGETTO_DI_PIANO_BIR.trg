CREATE OR REPLACE TRIGGER VENCD.TR_CD_SOGGETTO_DI_PIANO_BIR BEFORE INSERT ON VENCD.CD_SOGGETTO_DI_PIANO FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('SOGGETTO_DI_PIANO_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_SOGGETTO_DI_PIANO_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_SOGGETTO_DI_PIANO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('SOGGETTO_DI_PIANO_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('SOGGETTO_DI_PIANO_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




