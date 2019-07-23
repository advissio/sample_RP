CREATE OR REPLACE TRIGGER VENCD.TR_CD_CLIENTI_SPECIALI_BIR BEFORE INSERT ON VENCD.CD_CLIENTI_SPECIALI FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran Italia, Giugno 2010
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('CD_CLIENTI_SPECIALI_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_CLIENTI_SPECIALI_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_CLIENTI_SPECIALI := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('CD_CLIENTI_SPECIALI_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('CD_CLIENTI_SPECIALI_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




