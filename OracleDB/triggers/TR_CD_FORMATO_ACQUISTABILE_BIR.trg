CREATE OR REPLACE TRIGGER VENCD.TR_CD_FORMATO_ACQUISTABILE_BIR
BEFORE INSERT
ON VENCD.CD_FORMATO_ACQUISTABILE REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE

v_nextval NATURAL;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Roberto Barbaro, Teoresi, Giugno 2009
   -- ----------------------------------------------------------------------------------------


   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('FORMATO_ACQUISTABILE_BIR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)

      SELECT CD_FORMATO_ACQUISTABILE_SEQ.NEXTVAL
      INTO v_nextval
     FROM DUAL;

      --if :new.id_tipo_formato =1 then
       -- :new.descrizione :='Filmato';
      --end if;


     :NEW.ID_FORMATO := v_nextval;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('FORMATO_ACQUISTABILE_BIR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('FORMATO_ACQUISTABILE_BIR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




