CREATE OR REPLACE TRIGGER VENCD.TR_CD_RAGGR_INTERMED_BIR BEFORE INSERT ON VENCD.CD_RAGGRUPPAMENTO_INTERMEDIARI FOR EACH ROW
DECLARE

v_nextval NATURAL;

v_progressivo CD_RAGGRUPPAMENTO_INTERMEDIARI.PROGRESSIVO%type;

---22/02/2010 Mauro Viel  inserita gestione del nuovo atributo progressivo.
---necessario per mantenere legati, lato applicazione,  il raggruppamento con il prodotto_acquistato.


BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('RAGGR_INTERMED_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_RAGGR_INTERMED_SEQ.NEXTVAL
      INTO v_nextval
      FROM DUAL;


     :NEW.ID_RAGGRUPPAMENTO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione

   --Gestione del progressivo

    select nvl(max(progressivo),0) + 1
    into v_progressivo
    from cd_raggruppamento_intermediari
    where id_piano = :NEW.id_piano;

    :NEW.progressivo := v_progressivo;

   PA_TRIGGER.CONCLUDI('RAGGR_INTERMED_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('RAGGR_INTERMED_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




