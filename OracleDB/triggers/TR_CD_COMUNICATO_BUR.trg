CREATE OR REPLACE TRIGGER VENCD.TR_CD_COMUNICATO_BUR BEFORE UPDATE ON VENCD.CD_COMUNICATO FOR EACH ROW
declare
v_id_piano      cd_pianificazione.id_piano%type;
v_id_ver_piano   cd_pianificazione.id_ver_piano%type;
V_PROGRESSIVO   CD_COMUNICATO_STO.PROGRESSIVO%TYPE;

BEGIN
   -- TRIGGER DI IMPLEMENTAZIONE DI BUSINESS RULES
   -- CREAZIONE: Mauro Viel, Altran, Giugno 2009
   -- Modifiche: 05/02/2010 Mauro Viel commentata la gestione dello stato di lavorazione del piano
   -- per ch? le modifiche del comunicato non impattano sllo stato del comunicato.
   -- ----------------------------------------------------------------------------------------

   -- 1) MESSA IN SICUREZZA DEL TRIGGER: Registro attivazione
   PA_TRIGGER.INIZIA('TR_CD_COMUNICATO_BUR');
   -- 2) Business Rule 1): gestione Timestamp su operazioni di modifica (SEMPRE ESEGUITA!)
   PA_CD_UTILITY.PR_TIMESTAMP_MODIFICA(
                           :NEW.UTEMOD,
                           :NEW.DATAMOD, 
                           PA_CD_TRIGGER.FU_GET_STATO_TRIGGER
                           );
                           
    IF :OLD.ID_BREAK_VENDITA != :NEW.ID_BREAK_VENDITA THEN
    
        SELECT  NVL(MAX(PROGRESSIVO),0)
        INTO  V_PROGRESSIVO
        FROM CD_COMUNICATO_STO
        WHERE ID_COMUNICATO = :OLD.ID_COMUNICATO;
        
        INSERT INTO CD_COMUNICATO_STO 
        ( 
            ID_COMUNICATO, 
            PROGRESSIVO,
            POSIZIONE,
            POSIZIONE_DI_RIGORE, 
            COD_DISATTIVAZIONE, 
            FLG_ANNULLATO, 
            FLG_SOSPESO, 
            DATA_EROGAZIONE_PREV, 
            UTEMOD,
            DATAMOD, 
            ID_CINEMA_VENDITA, 
            ID_BREAK_VENDITA, 
            ID_ATRIO_VENDITA, 
            ID_SOGGETTO_DI_PIANO,
            ID_SALA_VENDITA, 
            ID_PRODOTTO_ACQUISTATO, 
            ID_MATERIALE_DI_PIANO, 
            IMPORTO_SIAE, 
            DATA_CONFERMA_SIAE,
            ID_SALA, 
            FLG_TUTELA
        ) 
        VALUES 
        (
            :OLD.ID_COMUNICATO, 
            V_PROGRESSIVO+1, 
            :OLD.POSIZIONE,
            :OLD.POSIZIONE_DI_RIGORE, 
            :OLD.COD_DISATTIVAZIONE, 
            :OLD.FLG_ANNULLATO, 
            :OLD.FLG_SOSPESO, 
            :OLD.DATA_EROGAZIONE_PREV, 
            :OLD.UTEMOD,
            :OLD.DATAMOD, 
            :OLD.ID_CINEMA_VENDITA, 
            :OLD.ID_BREAK_VENDITA, 
            :OLD.ID_ATRIO_VENDITA, 
            :OLD.ID_SOGGETTO_DI_PIANO,
            :OLD.ID_SALA_VENDITA, 
            :OLD.ID_PRODOTTO_ACQUISTATO, 
            :OLD.ID_MATERIALE_DI_PIANO, 
            :OLD.IMPORTO_SIAE, 
            :OLD.DATA_CONFERMA_SIAE,
            :OLD.ID_SALA, 
            :OLD.FLG_TUTELA 
        );  
    
    END IF;
    

                       

     /*if  (:OLD.cod_disattivazione <> :NEW.cod_disattivazione) then

        select id_piano,id_ver_piano into v_id_piano,v_id_ver_piano
        from   cd_prodotto_acquistato
        where  id_prodotto_acquistato = :new.id_prodotto_acquistato;

        --PA_CD_PIANIFICAZIONE.PR_MODIFICA_STATO_LAVORAZIONE(V_ID_PIANO,V_ID_VER_PIANO,1);

     end if;*/

   -- 3) MESSA IN SICUREZZA DEL TRIGGER: Registro corretta terminazione
   PA_TRIGGER.CONCLUDI('TR_CD_COMUNICATO_BUR');

EXCEPTION
   WHEN OTHERS THEN
      -- MESSA IN SICUREZZA DEL TRIGGER: Registro terminazione
      PA_TRIGGER.CONCLUDI('TR_CD_COMUNICATO_BUR');
      -- TRASMETTO ECCEZIONE AL PROCESSO SCATENANTE

      raise;
      
END;
/




