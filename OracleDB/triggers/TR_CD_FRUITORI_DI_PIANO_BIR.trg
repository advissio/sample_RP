CREATE OR REPLACE TRIGGER VENCD.TR_CD_FRUITORI_DI_PIANO_BIR BEFORE INSERT ON VENCD.CD_FRUITORI_DI_PIANO FOR EACH ROW
DECLARE

v_nextval NATURAL;

v_progressivo CD_FRUITORI_DI_PIANO.PROGRESSIVO%type;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran, novembre 2009
   ---22/02/2010 Mauro Viel  inserita gestione del nuovo atributo progressivo.
   ---necessario per mantenere legati, lato applicazione,  il fruitore con il prodotto_acquistato.
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('FRUITORI_DI_PIANO');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_FRUITORI_DI_PIANO_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_FRUITORI_DI_PIANO := v_nextval;


     --Gestione del progressivo

     select nvl(max(progressivo),0) + 1
     into v_progressivo
     from CD_FRUITORI_DI_PIANO
     where id_piano = :NEW.id_piano;

     :NEW.progressivo := v_progressivo;

   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('FRUITORI_DI_PIANO');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('FRUITORI_DI_PIANO');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




