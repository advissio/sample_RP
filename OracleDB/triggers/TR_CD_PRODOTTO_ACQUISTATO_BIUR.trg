CREATE OR REPLACE TRIGGER VENCD.TR_CD_PRODOTTO_ACQUISTATO_BIUR
BEFORE INSERT OR UPDATE ON VENCD.CD_PRODOTTO_ACQUISTATO  REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
declare v_data_prenotazione cd_pianificazione.data_prenotazione%type;
        v_progressivo       cd_prd_acq_stato_vendita.PROGRESSIVO%type;
BEGIN
-----------------------
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel , Altran, Settembre 2009
   -- ----------------------------------------------------------------------------------------
   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
    PA_TRIGGER.INIZIA('PRODOTTO_ACQUISTATO_BIUR');
   -- 2) Business Rule 1): imposta la data_prenotazione, se non e gia impostata,
   ---sulla tavola cd_pianificazione quando
   ---il primo prodotto_acquistato passa allo stato prenotato (valore 3).
   select data_prenotazione into v_data_prenotazione
   from cd_pianificazione
   where id_piano =:new.id_piano
   and   id_ver_piano =:new.id_ver_piano;
   if :new.stato_di_vendita <> :old.stato_di_vendita  then

     select nvl(max(progressivo),0) into v_progressivo
     from  cd_prd_acq_stato_vendita
     where id_prodotto_acquistato = :new.id_prodotto_acquistato;

     insert into cd_prd_acq_stato_vendita (PROGRESSIVO,STATO_DI_VENDITA,ID_PRODOTTO_ACQUISTATO)
     values (v_progressivo+1,:new.stato_di_vendita,:new.id_prodotto_acquistato);

     if :old.stato_di_vendita='PRE' and :new.stato_di_vendita !='PRE'then
        update cd_comunicato set posizione = null where id_prodotto_acquistato=:new.id_prodotto_acquistato;
     end if;

   end if;
   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('PRODOTTO_ACQUISTATO_BIUR');
EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('PRODOTTO_ACQUISTATO_BIUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
-----------------------
END TR_CD_PRODOTTO_ACQUISTATO_BIUR;
/




