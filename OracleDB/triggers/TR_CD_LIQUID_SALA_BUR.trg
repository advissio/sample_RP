CREATE OR REPLACE TRIGGER VENCD.TR_CD_LIQUID_SALA_BUR BEFORE UPDATE ON VENCD.CD_LIQUIDAZIONE_SALA FOR EACH ROW
DECLARE
V_STATO_LAVORAZIONE CD_LIQUIDAZIONE.STATO_LAVORAZIONE%TYPE;
V_PROGRESSIVO       CD_LIQUIDAZIONE_SALA_STO.PROGRESSIVO%TYPE;
v_id_liquidazione   CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%type;
v_update_verifica_trasm    number := 0;
BEGIN
   
   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('LIQUID_SALA_BUR');
   --DBMS_OUTPUT.put_line(:OLD.id_sala = :NEW.id_sala);
   IF  PA_CD_UTILITY.FU_TRIGGER_ON ='S' THEN
        /*Controllo che la modifica riguardi solo la verifica del trasmesso*/
        if(     :OLD.id_sala = :NEW.id_sala
           and  :OLD.data_rif = :NEW.data_rif
           and  ((:OLD.FLG_PROIEZIONE_PUBB is null and :new.FLG_PROIEZIONE_PUBB is null ) or (:OLD.FLG_PROIEZIONE_PUBB = :new.FLG_PROIEZIONE_PUBB))
           and  ((:OLD.NUM_SPETTATORI_EFF is null and :new.NUM_SPETTATORI_EFF is null )or (:OLD.NUM_SPETTATORI_EFF = :new.NUM_SPETTATORI_EFF))
           and  ((:OLD.MOTIVAZIONE is null and :new.MOTIVAZIONE is null ) or (:OLD.MOTIVAZIONE = :new.MOTIVAZIONE))
           and  ((:OLD.ID_CODICE_RESP is null and :new.ID_CODICE_RESP is null ) or (:OLD.ID_CODICE_RESP = :new.ID_CODICE_RESP))
           and  ((:OLD.FLG_PROGRAMMAZIONE is null and :new.FLG_PROGRAMMAZIONE is null ) or (:OLD.FLG_PROGRAMMAZIONE = :new.FLG_PROGRAMMAZIONE ))
           /*and  (   (:new.PROIEZIONI_ERR IS NULL OR :OLD.PROIEZIONI_ERR <> :new.PROIEZIONI_ERR ) 
                 OR (:new.PROIEZIONI_OK IS NULL OR :OLD.PROIEZIONI_OK <> :new.PROIEZIONI_OK ) 
                 OR (:new.STATO IS NULL OR :OLD.STATO <> :new.STATO )
                )*/
           )then
             v_update_verifica_trasm := 1;
             --DBMS_OUTPUT.PUT_LINE('Richiesta modifica su dati della verifica del trasmesso');
            --RAISE_APPLICATION_ERROR(-20008, 'Nessuna modifica sulla liquidazione, ma solo eventualmente sulla verifica del trasmesso');  
        else
            --RAISE_APPLICATION_ERROR(-20009, 'Rilevata modifica anche su liquidazione');
            v_update_verifica_trasm := 0;
            --DBMS_OUTPUT.PUT_LINE('Richiesta modifica su dati inerenti la liquidazione');
            --DBMS_OUTPUT.PUT_LINE('v_update_verifica_trasm:'||v_update_verifica_trasm);
        end if;
        begin 
            SELECT STATO_LAVORAZIONE,id_liquidazione
            INTO   V_STATO_LAVORAZIONE,v_id_liquidazione
            FROM   CD_LIQUIDAZIONE
            WHERE  :OLD.DATA_RIF BETWEEN DATA_INIZIO AND DATA_FINE;
        exception 
        when no_data_found then
            V_STATO_LAVORAZIONE := 'ANT'; --non e stata ancora eseguita la liquidazione (non esiste il record sulla tavola cd_liquidazione) ma siamo gia nel trimestre di liquidazione
        end;
        /*Controllo temporaneo per evitare modifiche dei dai consolidati a meno che non si tratti 
          di una modifica fatta sulla verifica del trasmesso*/
       IF ( (V_STATO_LAVORAZIONE != 'ANT' 
                or 
            (v_id_liquidazione = 12 and upper(user) not in ('GESTCD','SA01860'))
           ) 
            and v_update_verifica_trasm=0) 
       THEN
            --RAISE_APPLICATION_ERROR(-20002, 'TR_CD_LIQUID_SALA_BUR, impossibile modificare i dati gia  liquidati.');
            RAISE_APPLICATION_ERROR(-20002, 'Impossibile modificare. periodo gia'' consolidato');
       else
            select nvl(max(progressivo),0 )into v_progressivo
            from   cd_liquidazione_sala_sto
            where  id_sala  = :OLD.id_sala
            and    data_rif = :OLD.data_rif;
            insert into cd_liquidazione_sala_sto(ID_SALA,      DATA_RIF,    PROGRESSIVO,   FLG_PROIEZIONE_PUBB,       NUM_SPETTATORI_EFF,      MOTIVAZIONE,      ID_CODICE_RESP,      FLG_PROGRAMMAZIONE)
                                         values (:OLD.id_sala,:OLD.data_rif,v_progressivo+1, :OLD.FLG_PROIEZIONE_PUBB,  :OLD.NUM_SPETTATORI_EFF, :OLD.MOTIVAZIONE, :OLD.ID_CODICE_RESP, :OLD.FLG_PROGRAMMAZIONE );
             -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
       
       END IF;
       -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
       -- CREAZIONE: Antonio Colucci, Teoresi, Aprile 2010
       -- ----------------------------------------------------------------------------------------

    END IF;
    PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                               :NEW.UTEMOD,
                               :NEW.DATAMOD,
                                PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                               );
       -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
       PA_TRIGGER.CONCLUDI('LIQUID_SALA_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('LIQUID_SALA_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE
      RAISE;
END;
/




