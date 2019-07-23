CREATE OR REPLACE TRIGGER VENCD.TR_CD_DATI_CINETEL_SIPRA_BIR BEFORE INSERT ON VENCD.CD_DATI_CINETEL_SIPRA FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Antonio Colucci, Teoresi, Marzo 2010
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('DATI_CINETEL_SIPRA_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_DATI_CINETEL_SIPRA_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;


     :NEW.ID_DATI_CINETEL_SIPRA := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('DATI_CINETEL_SIPRA_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('DATI_CINETEL_SIPRA_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




