CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_MATERIALE IS

PLAYED_EXCEPTION EXCEPTION;
FK_VIOLATED_EXCEPTION EXCEPTION;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_MATERIALE
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo materiale nel sistema
--
-- OPERAZIONI:
--   1) Memorizza il materiale (CD_MATERIALE)
--
-- INPUT: parametri per l'inserimento di un nuovo materiale
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_MATERIALE(p_descrizione              CD_MATERIALE.DESCRIZIONE%TYPE,
							     p_id_codifica              CD_MATERIALE.ID_CODIFICA%TYPE,
                                 p_id_colonna_sonora        CD_MATERIALE.ID_COLONNA_SONORA%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_url_bassa_risoluzione    CD_MATERIALE.URL_BASSA_RISOLUZIONE%TYPE,
                                 p_durata                   CD_MATERIALE.DURATA%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
							     p_agenzia_prod             CD_MATERIALE.AGENZIA_PRODUZ%TYPE,
                                 p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_flg_siae                 CD_MATERIALE.FLG_SIAE%TYPE,
                                 p_data_inizio_validita     CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine_validita       CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_traduzione_titolo        CD_MATERIALE.TRADUZIONE_TITOLO%TYPE,
                                 p_cod_soggetto             SOGGETTI.COD_SOGG%TYPE,
                                 p_nazionalita              CD_MATERIALE.NAZIONALITA%TYPE,
                                 p_causale                  CD_MATERIALE.CAUSALE%TYPE,
                                 p_flg_approvazione         CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
                                 p_flg_protetto             CD_MATERIALE.FLG_PROTETTO%TYPE,
                                 p_esito					OUT NUMBER)
IS

v_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE;

BEGIN -- PR_INSERISCI_MATERIALE
--

p_esito 	:= 1;
--P_ID_MATERIALE := MATERIALE_SEQ.NEXTVAL;

	 --
  		SAVEPOINT SP_PR_INSERISCI_MATERIALE;
  	--
	   -- EFFETTUO L'INSERIMENTO
	   INSERT INTO CD_MATERIALE
       (DESCRIZIONE,
        ID_CODIFICA,
        ID_COLONNA_SONORA,
        NOME_FILE,
        URL_BASSA_RISOLUZIONE,
        DURATA,
        FLG_MULTIPRODOTTO,
        ID_CLIENTE,
        AGENZIA_PRODUZ,
        TITOLO,
        FLG_SIAE,
        DATA_INIZIO_VALIDITA,
        DATA_FINE_VALIDITA,
        DATA_INSERIMENTO,
        TRADUZIONE_TITOLO,
        NAZIONALITA,
        CAUSALE,
        FLG_APPROVAZIONE,
        FLG_PROTETTO,
        UTEMOD,
        DATAMOD
	   )
	   VALUES
	     (p_descrizione,
          p_id_codifica,
          p_id_colonna_sonora,
          p_nome_file,
          p_url_bassa_risoluzione,
          p_durata,
          p_flg_multiprodotto,
          p_id_cliente,
          p_agenzia_prod,
          p_titolo,
          p_flg_siae,
          p_data_inizio_validita,
          p_data_fine_validita,
          FU_DATA_ORA,
          p_traduzione_titolo,
          p_nazionalita,
          p_causale,
          p_flg_approvazione,
          p_flg_protetto,
		  user,
		  FU_DATA_ORA
		  );
    --Definisco associazione Materiale Soggetto
    select max(id_materiale) into v_id_materiale from cd_materiale ;
    INSERT INTO CD_MATERIALE_SOGGETTI
    (
        ID_MATERIALE,
        COD_SOGG,
        DATA_INIZIO_VALIDITA,
        DATA_FINE_VALIDITA,
        DATAMOD,
        UTEMOD
    )
    VALUES
    (
        v_id_materiale,
        p_cod_soggetto,
        p_data_inizio_validita,
        NULL,
        SYSDATE,
        USER
    );
    p_esito := v_id_materiale;
--
--

	EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
		WHEN OTHERS THEN

		p_esito := -11;
        --raise;
		RAISE_APPLICATION_ERROR(-20020, 'Procedura PR_INSERISCI_MATERIALE: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_MATERIALE(p_titolo,
                                                                                                                                                            p_nome_file,
                                                                                                                                                            p_data_inizio_validita,
                                                                                                                                                            p_data_fine_validita,
                                                                                                                                                            p_id_cliente,
                                                                                                                                                            p_flg_multiprodotto)||' - '||sqlerrm);
		ROLLBACK TO SP_PR_INSERISCI_MATERIALE;

END PR_INSERISCI_MATERIALE;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_MATERIALE
--
-- DESCRIZIONE:  Esegue la modifica di un materiale nel sistema
--
-- OPERAZIONI:
--   - Verifica che non ci siano comunicati gia' andati in onda
--   - Nel caso non trovi dei comunicati gia andati in onda provvedo alla modifica,
--      altrimenti segnalo l'errore
--
-- INPUT: parametri per l'inserimento di un nuovo materiale
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Dicembre 2009
--
--  MODIFICHE:
--               Tommaso D'Anna, Teoresi srl, 24 Novembre 2010
--               Aggiunta modifica TRADUZIONE_TITOLO mancante.
--               Mauro Viel, Novembre 2011 Altran Italia inserita la gestione del flg_tutela sul comunicato.
--               Con questa modifica non sara piu necessario associare nuovemente un materiale al/ai prodotti se 
--               varia lo stato di protezione del materiale --#MV01
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_MATERIALE( p_id_materiale             CD_MATERIALE.ID_MATERIALE%TYPE,
                                 p_descrizione              CD_MATERIALE.DESCRIZIONE%TYPE,
							     p_id_codifica              CD_MATERIALE.ID_CODIFICA%TYPE,
                                 p_id_colonna_sonora        CD_MATERIALE.ID_COLONNA_SONORA%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_url_bassa_risoluzione    CD_MATERIALE.URL_BASSA_RISOLUZIONE%TYPE,
                                 p_durata                   CD_MATERIALE.DURATA%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
							     p_agenzia_prod             CD_MATERIALE.AGENZIA_PRODUZ%TYPE,
                                 p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_flg_siae                 CD_MATERIALE.FLG_SIAE%TYPE,
                                 p_data_inizio_validita     CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine_validita       CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_traduzione_titolo        CD_MATERIALE.TRADUZIONE_TITOLO%TYPE,
                                 p_nazionalita              CD_MATERIALE.NAZIONALITA%TYPE,
                                 p_cod_sogg                 CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE,
                                 p_causale                  CD_MATERIALE.CAUSALE%TYPE,
                                 p_flg_approvazione         CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
                                 p_flg_protetto             CD_MATERIALE.FLG_PROTETTO%TYPE,
                                 p_esito					OUT NUMBER)
IS
--
num_comunicati_trasmessi NUMBER;
num_materiali            NUMBER;
--#MV01
v_flg_protetto cd_materiale.flg_protetto%type;
--
BEGIN
--
--
p_esito 	:= 1;
num_comunicati_trasmessi := 0;
--
  		SAVEPOINT ann_update;
/*
        SELECT count(id_comunicato) into num_comunicati_trasmessi FROM CD_MATERIALE_DI_PIANO,CD_COMUNICATO
            WHERE CD_MATERIALE_DI_PIANO.ID_MATERIALE = p_id_materiale
            AND   CD_COMUNICATO.ID_MATERIALE_DI_PIANO = CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO
            AND   CD_COMUNICATO.DATA_EROGAZIONE_PREV < SYSDATE;
*/
    --#MV01
    select flg_protetto
    into   v_flg_protetto
    from   cd_materiale 
    where  id_materiale = p_id_materiale; 
    --#MV01
--
  	IF(num_comunicati_trasmessi>0)THEN
--
        RAISE PLAYED_EXCEPTION;--
        --Esistono dei comunicati gia andati in onda associati al materiale specificato
        --Non e possibile modificare il materiale specificato
    ELSE
        -- EFFETTUO L'UPDATE
       UPDATE CD_MATERIALE
        SET
              DESCRIZIONE = (nvl(p_descrizione,DESCRIZIONE)),
              ID_CODIFICA = (nvl(p_id_codifica,ID_CODIFICA)),
              ID_COLONNA_SONORA = (nvl(p_id_colonna_sonora,ID_COLONNA_SONORA)),
              NOME_FILE = p_nome_file,
              URL_BASSA_RISOLUZIONE = (nvl(p_url_bassa_risoluzione,URL_BASSA_RISOLUZIONE)),
              DURATA = (nvl(p_durata,DURATA)),
              FLG_MULTIPRODOTTO = (nvl(p_flg_multiprodotto,FLG_MULTIPRODOTTO)),
              ID_CLIENTE = (nvl(p_id_cliente,ID_CLIENTE)),
              AGENZIA_PRODUZ = (nvl(p_agenzia_prod,AGENZIA_PRODUZ)),
              TITOLO = (nvl(p_titolo,TITOLO)),
              FLG_SIAE = (nvl(p_flg_siae,FLG_SIAE)),
              DATA_INIZIO_VALIDITA = (nvl(p_data_inizio_validita,DATA_INIZIO_VALIDITA)),
              DATA_FINE_VALIDITA = (nvl(p_data_fine_validita,DATA_FINE_VALIDITA)),
              TRADUZIONE_TITOLO = ( nvl(p_traduzione_titolo,TRADUZIONE_TITOLO)),
              NAZIONALITA = (nvl(p_nazionalita,NAZIONALITA)),
              CAUSALE = (nvl(p_causale,' ')),
              FLG_APPROVAZIONE = p_flg_approvazione,
              FLG_PROTETTO = p_flg_protetto
          WHERE ID_MATERIALE = p_id_materiale;
--
          p_esito := SQL%ROWCOUNT;
          -- AGGIORNAMANETO SOLO APPROSSIMATIVO AL MOMENTO DEL PRIMO RILASCIO
          -- A TENDERE AD UN MATERIALE POTRANNO ESSERE ASSOCIATI  DIVERSI SOGGETTI
          select count(ID_MATERIALE_SOGGETTI) INTO num_materiali FROM CD_MATERIALE_SOGGETTI
          WHERE ID_MATERIALE = p_id_materiale;
          if(num_materiali>0)then
            UPDATE CD_MATERIALE_SOGGETTI
              SET COD_SOGG = p_cod_sogg
              WHERE ID_MATERIALE = p_id_materiale;
          else
            insert into CD_MATERIALE_SOGGETTI
            (
            id_materiale,
            cod_sogg,
            data_inizio_validita,
            data_fine_validita
            )
            values
            (
            p_id_materiale,
            p_cod_sogg,
            sysdate,
            null
            );
          end if;
          
          
          --#MV01-----------------------------
          if v_flg_protetto != p_flg_protetto then
              FOR C IN (
                        SELECT id_piano,id_ver_piano,id_materiale_di_piano 
                        FROM CD_MATERIALE_DI_PIANO
                        WHERE id_materiale = p_id_materiale 
                        )
              LOOP
                    UPDATE CD_COMUNICATO COM
                    SET FLG_TUTELA = p_flg_protetto
                    WHERE FLG_ANNULLATO = 'N'
                    AND FLG_SOSPESO = 'N'
                    AND COD_DISATTIVAZIONE IS NULL
                    AND FLG_TUTELA !=p_flg_protetto
                    AND DATA_EROGAZIONE_PREV >= TRUNC(SYSDATE)
                    AND ID_MATERIALE_DI_PIANO = c.id_materiale_di_piano
                    AND ID_PRODOTTO_ACQUISTATO IN
                    (
                        SELECT ID_PRODOTTO_ACQUISTATO
                        FROM CD_PRODOTTO_ACQUISTATO
                        WHERE FLG_ANNULLATO = 'N'
                        AND FLG_SOSPESO = 'N'
                        AND COD_DISATTIVAZIONE IS NULL
                        AND ID_PIANO = c.id_piano
                        AND ID_VER_PIANO = c.id_ver_piano
                    )
                    AND ID_COMUNICATO IN
                    (
                        SELECT C.ID_COMUNICATO
                        FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO C
                        WHERE C.ID_COMUNICATO = COM.ID_COMUNICATO
                        AND BR.ID_BREAK = C.ID_BREAK
                        AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
                        AND F.ID_FASCIA = P.ID_FASCIA
                        AND F.FLG_PROTETTA = 'S'
                    );
                END LOOP;
          end if;      
          --#MV01-----------------------------


          p_esito := SQL%ROWCOUNT;
    END IF;
--

	EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
		WHEN PLAYED_EXCEPTION THEN
        p_esito := -20;
        RAISE_APPLICATION_ERROR(-20030, 'Procedura di modifica non eseguita. Sono stati trovati dei comunicati andati in onda associati');
        WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20020, 'Procedura PR_MODIFICA_MATERIALE: Update non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_MATERIALE(p_titolo,
                                                                                                                                                            p_nome_file,
                                                                                                                                                            p_data_inizio_validita,
                                                                                                                                                            p_data_fine_validita,
                                                                                                                                                            p_id_cliente,
                                                                                                                                                            p_flg_multiprodotto)||' - '||sqlerrm);
		ROLLBACK TO ann_update;

END PR_MODIFICA_MATERIALE;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_MATERIALE
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               di materiali che soddisfa
--               i criteri di ricerca inseriti dall'utente
--
-- OPERAZIONI:
--   1) Recupera le informazioni relative ad un insieme di materiali
--
-- INPUT:
--      p_id_materiale          id del materiale
--      p_titolo                titolo del materiale,
--      p_nome_file             nome del file,
--      p_data_inizio           data inizio validita del materiale,
--      p_data_fine             data fine validita del materiale,
--      p_id_cliente            identificativo del cliente,
--      p_flg_multiprodotto     indicazione di un materiale multiprodotto
--
-- OUTPUT: lista dei materiali che soddisfano i criteri di ricerca
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Dicembre 2009
--
--  MODIFICHE: Antonio Colucci, Teoresi srl, Febbraio 2010
--              Modificata la gestione del parametro p_nome_file
--              in modo da filtrare i materiali ottenuti oltre che
--              in base agli altri parametri, anche per
--                  - Materiali con filmato presente --> p_nome_file = 'S'
--                  - Materiali senza filmato presente --> p_nome_file = 'N'
--                  - Tutti i Materiali indipendentemente dalla presenza del filmato --> p_nome_file = 'Tutti'
--             Antonio Colucci, Teoresi srl, Agosto 2010
--             Inseriti nuovi campi da recuperare in fase di ricerca:
--                  -avanzamento
--                  -num_cinema_sincronizzati
--                  -num_cinema_non_sincronizzati
--                  -cinema_non_sincronizzati
--              Tommaso D'Anna, Teoresi srl, 18 Novembre 2010
--              Inseriti nuovi campi di ricerca:
--                  -presenza visto censura
--                  -id protocollo
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_MATERIALE(   p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_data_inizio              CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine                CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
                                 p_id_materiale             CD_MATERIALE.ID_MATERIALE%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE,
                                 p_flg_approvazione         CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
                                 p_flg_protetto             CD_MATERIALE.FLG_PROTETTO%TYPE,
                                 p_num_protocollo           CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO%TYPE,
                                 p_visto_cerca              VARCHAR2)
                                 RETURN C_MATERIALE
IS
c_materiale_return  C_MATERIALE;
--
BEGIN
    open c_materiale_return
    for
        select /*+ ALL_ROWS*/ materiale.id_materiale,materiale.titolo,
                materiale.nome_file,materiale.durata,
                anagrafiche.rag_soc_cogn desc_cliente,materiale.data_inizio_validita,
                materiale.DATA_FINE_VALIDITA,PA_CD_PIANIFICAZIONE.FU_GET_DESC_SOGGETTO(cod_sogg) desc_sogg,
                nvl(avanzamento,0) avanzamento,num_cinema_sincronizzati num_cinema_sinc, 
                num_cinema_non_sincronizzati num_cinema_non_sinc,cinema_non_sincronizzati cinema_non_sinc,
                visti_materiali.VISTO_CENSURA_PRESENTE
                from cd_materiale materiale, vi_cd_cliente anagrafiche, 
                     cd_materiale_soggetti, vi_cd_stato_materiale, 
                        (select
                            cd_materiale.id_materiale ID_MATERIALE,
                            decode(nvl(cd_visto_censura.id_materiale,0),0,'No','Si') VISTO_CENSURA_PRESENTE
                         from 
                            cd_materiale, cd_visto_censura
                         where
                            cd_materiale.id_materiale = cd_visto_censura.id_materiale(+)
                            and (( cd_visto_censura.FLG_ANNULLATO is null) or cd_visto_censura.FLG_ANNULLATO='N')
                        ) visti_materiali
         where
                ((p_id_materiale is null)or materiale.id_materiale = p_id_materiale)
                and ((p_titolo is null) or (upper(materiale.titolo) like '%'||upper(p_titolo)||'%'))
                and (p_nome_file = 'Tutti' or
                    (nvl(nome_file,2) =  decode(p_nome_file,'Si',nome_file,'No', 2)))
                and ((p_data_inizio IS NULL) OR (materiale.DATA_inizio_VALIDITA IS NULL) OR (materiale.DATA_inizio_VALIDITA >= p_data_inizio))
                and ((p_data_fine IS NULL) OR (materiale.DATA_FINE_VALIDITA IS NULL) OR (materiale.DATA_FINE_VALIDITA <= p_data_fine))
                and materiale.ID_CLIENTE = nvl(p_id_cliente,materiale.id_cliente)
                and materiale.FLG_MULTIPRODOTTO = nvl(p_flg_multiprodotto,materiale.flg_multiprodotto)
                and ((p_flg_approvazione IS NULL ) or (materiale.FLG_APPROVAZIONE = p_flg_approvazione))
                and materiale.FLG_PROTETTO=nvl(p_flg_protetto,materiale.FLG_PROTETTO)
                and ((p_visto_cerca = 'Tutti') or (visti_materiali.VISTO_CENSURA_PRESENTE = p_visto_cerca))
                and ((p_num_protocollo is null) or materiale.NUMERO_PROTOCOLLO_MINISTERO=p_num_protocollo)
                and anagrafiche.ID_CLIENTE = materiale.id_cliente
                and materiale.id_materiale = cd_materiale_soggetti.id_materiale(+)
                and materiale.id_materiale = vi_cd_stato_materiale.id_materiale(+)
                and materiale.id_materiale = visti_materiali.id_materiale;
    RETURN c_materiale_return;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_MATERIALE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:'||FU_STAMPA_MATERIALE(p_titolo,
                                                                                                                                                                p_nome_file,
                                                                                                                                                                p_data_inizio,
                                                                                                                                                                p_data_fine,
                                                                                                                                                                p_id_cliente,
                                                                                                                                                                p_flg_multiprodotto));
--
END FU_RICERCA_MATERIALE;

--
-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_MATERIALE
--
-- DESCRIZIONE:  Funzione che permette di recuperare il dettaglio di uno
--               specifico materiale avendo come input id_materiale
--
-- OPERAZIONI:
--   1) Recupera le informazioni di dettaglio di un materiale
--
-- INPUT:
--      p_id_materiale      id del materiale
--
-- OUTPUT: informazioni di dettaglio di un materiale
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Dicembre 2009
--
--  MODIFICHE:
--              Tommaso D'Anna, Teoresi srl, 12 Novembre 2010
--              Inserimento recupero informazioni sui visti censura
--              Tommaso D'Anna, Teoresi srl, 19 Novembre 2010
--              Inserimento recupero informazioni sul protocollo
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_MATERIALE(p_id_materiale  CD_MATERIALE.ID_MATERIALE%TYPE)
                               RETURN C_DETTAGLIO_MATERIALE
IS
c_dettaglio_return  C_DETTAGLIO_MATERIALE;

BEGIN
    OPEN c_dettaglio_return
    FOR
    select materiale.id_materiale,materiale.DESCRIZIONE,materiale.NOME_FILE,
       materiale.URL_BASSA_RISOLUZIONE URL_BASSA_RIS,materiale.TITOLO,
       materiale.DURATA,materiale.FLG_MULTIPRODOTTO,
       materiale.ID_CLIENTE,materiale.AGENZIA_PRODUZ,
       materiale.FLG_SIAE,materiale.ID_COLONNA_SONORA,materiale.DATA_INIZIO_VALIDITA,
       materiale.DATA_FINE_VALIDITA,materiale.DATA_INSERIMENTO,
       materiale.TRADUZIONE_TITOLO,materiale.ID_CODIFICA,
       anagrafiche.rag_soc_cogn desc_cliente,codifiche.descrizione desc_codifica,
       colonna_sonora.titolo desc_colonna, materiale.NAZIONALITA, materiale.CAUSALE,
       materiale.FLG_APPROVAZIONE, materiale.FLG_PROTETTO, visti_validi.id_visto_censura,
       materiale.NUMERO_PROTOCOLLO_MINISTERO, materiale.DATA_RIL_NULLAOSTA_MINISTERO
        from cd_materiale materiale,vi_cd_cliente anagrafiche,
             cd_colonna_sonora colonna_sonora, cd_anag_codifiche codifiche,
             (
                select id_visto_censura,id_materiale 
                from cd_visto_censura 
                where flg_annullato = 'N'
             ) 
             visti_validi
        where materiale.id_materiale = p_id_materiale
              and materiale.id_cliente = anagrafiche.id_cliente
              and materiale.id_materiale = visti_validi.id_materiale (+)
              and materiale.id_colonna_sonora = colonna_sonora.id_colonna_sonora (+)
              and materiale.id_codifica = codifiche.id_codifica (+);
--
   RETURN c_dettaglio_return;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_DETTAGLIO_MATERIALE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI - ID_MATERIALE:'||p_id_materiale);
END FU_DETTAGLIO_MATERIALE;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_MATERIALE
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un materiale dal sistema
--
-- OPERAZIONI:
--   1) Elimina il materiale
--
-- INPUT:
--      p_id_materiale      id del materiale
--
-- OUTPUT: esito:
--    1  Mateeriale eliminato con successo
--   -2  Eliminazione non eseguita: i parametri per la Delete non sono coerenti - possibile problema di FK
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_MATERIALE( p_id_materiale		IN CD_MATERIALE.ID_MATERIALE%TYPE,
							    p_esito		        OUT NUMBER)
IS

count_comunicati NUMBER;
--
BEGIN -- PR_ELIMINA_MATERIALE
--

    p_esito 	:= 1;
       SELECT count(id_comunicato) into count_comunicati FROM CD_MATERIALE_DI_PIANO,CD_COMUNICATO
            WHERE CD_MATERIALE_DI_PIANO.ID_MATERIALE = p_id_materiale
            AND   CD_COMUNICATO.ID_MATERIALE_DI_PIANO = CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO;
      --
  		SAVEPOINT ann_del;
  	    IF(count_comunicati>0)THEN
            RAISE FK_VIOLATED_EXCEPTION;
        ELSE
	   -- EFFETTUA L'ELIMINAZIONE DA MATERIALE_SOGGETTI
            DELETE FROM CD_MATERIALE_SOGGETTI
            WHERE ID_MATERIALE =  p_id_materiale;
       -- ESEGUE ELIMINAZIONE DA TABELLA MATERIALE
    	   DELETE FROM CD_MATERIALE
    	   WHERE ID_MATERIALE = p_id_materiale;
       END IF;
	   --
	p_esito := SQL%ROWCOUNT;

  EXCEPTION
  		WHEN  FK_VIOLATED_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20030, 'Impossibile eliminare il materiale. Sono stati trovati dei comunicati associati');
        p_esito:=-3;
        WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20020, 'Procedura PR_ELIMINA_MATERIALE: Delete non eseguita, verificare la coerenza dei parametri');
		p_esito := -2;
        ROLLBACK TO ann_del;


END;


-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_COLONNA
-----------------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Esegue l'inserimento di una nuova colonna sonora
--
-- OPERAZIONI:
--   1) Inserimento di una colonna sonora
--
-- INPUT:
--      p_titolo      titolo della colonna sonora
--      p_autore      autore della colonna sonora
--      p_nota        nota della colonna sonora
--
-- OUTPUT: esito:
--    1  Colonna inserita correttamente
--   -2  Inserimento non eseguito. Si sono verificati dei problemi
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_COLONNA(  p_titolo                   CD_COLONNA_SONORA.TITOLO%TYPE,
                                 p_autore                   CD_COLONNA_SONORA.AUTORE%TYPE,
                                 p_nota                     CD_COLONNA_SONORA.NOTA%TYPE,
                                 p_esito					OUT NUMBER)
IS
BEGIN
p_esito 	:= 1;
	--
  		SAVEPOINT SP_PR_INSERISCI_COLONNA;
  	--
	   -- EFFETTUO L'INSERIMENTO
	   INSERT INTO CD_COLONNA_SONORA
       (
        TITOLO,
        AUTORE,
        NOTA,
        UTEMOD,
        DATAMOD
	   )
	   VALUES
	     (
          p_titolo,
          p_autore,
          p_nota,
		  user,
		  FU_DATA_ORA
		  );
--
--

	EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
		WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20020, 'Procedura PR_INSERISCI_COLONNA: Insert non eseguita, verificare la coerenza dei parametri ==> titolo:'||p_titolo||' - autore:'||p_autore||' - nota:'||p_nota);
END PR_INSERISCI_COLONNA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_COLONNA_SONORA
-- DESCRIZIONE:  LA FUNZIONE RESTITUISCE LA LISTA DELLE COLONNE SONORE DISPONIBILI
--
-- INPUT: NESSUN PARAMETRO DI INPUT PREVISTO
--
-- OUTPUT: REF CURSOR CON LE COLONNE SONORE
--
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Dicembre 2009
--
-- MODIFICHE     Barbaro Roberto, Teoresi srl, Febbraio 2010
--               Aggiunti i parameri titolo e autore
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_COLONNA_SONORA(p_titolo              CD_COLONNA_SONORA.TITOLO%TYPE,
                                   p_autore              CD_COLONNA_SONORA.AUTORE%TYPE)
                                   RETURN C_COLONNA_SONORA
IS
c_colonne_return C_COLONNA_SONORA;
BEGIN
    OPEN c_colonne_return
        FOR
            SELECT  ID_COLONNA_SONORA,TITOLO,AUTORE,NOTA
            FROM    CD_COLONNA_SONORA
            WHERE   (p_titolo is null OR UPPER(TITOLO) LIKE '%'||UPPER(p_titolo)||'%')
            AND     (p_autore is null OR UPPER(AUTORE) LIKE '%'||UPPER(p_autore)||'%')
            order by titolo;
--
    RETURN c_colonne_return;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FU_RICERCA_COLONNA_SONORA: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI');
END FU_RICERCA_COLONNA_SONORA;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_COLONNA_SONORA
--
-- DESCRIZIONE:  Esegue la modifica di una colonna sonora
--
-- OPERAZIONI:
--              Modifica la colonna sonora identificata dall'id
--
-- INPUT: parametri per la modifica di una colonna sonora
--
--
-- REALIZZATORE: Barbaro Roberto, Teoresi srl, Febbraio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_COLONNA_SONORA(p_id_colonna_sonora   CD_COLONNA_SONORA.ID_COLONNA_SONORA%TYPE,
                                     p_titolo              CD_COLONNA_SONORA.TITOLO%TYPE,
                                     p_autore              CD_COLONNA_SONORA.AUTORE%TYPE,
                                     p_nota                CD_COLONNA_SONORA.NOTA%TYPE,
							         p_esito		        OUT NUMBER)
IS

BEGIN

    UPDATE CD_COLONNA_SONORA
    SET    TITOLO = NVL(p_titolo,TITOLO),
           AUTORE = NVL(p_autore,AUTORE),
           NOTA   = NVL(p_nota,NOTA)
    WHERE  ID_COLONNA_SONORA = p_id_colonna_sonora;

    p_esito := SQL%ROWCOUNT;

EXCEPTION
		WHEN OTHERS THEN
        p_esito := -1;
		RAISE_APPLICATION_ERROR(-20020, 'Procedura PR_MODIFICA_COLONNA_SONORA: Update non eseguita, verificare la coerenza dei parametri '||SQLERRM);

END PR_MODIFICA_COLONNA_SONORA;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_COLONNA_SONORA
--
-- DESCRIZIONE:  Esegue l'eliminazione di una colonna sonora
--
-- OPERAZIONI:
--              Elimina la colonna sonora identificata dall'id
--
-- INPUT: id della colonna sonora
--
--
-- REALIZZATORE: Barbaro Roberto, Teoresi srl, Febbraio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_COLONNA_SONORA(p_id_colonna_sonora   CD_COLONNA_SONORA.ID_COLONNA_SONORA%TYPE,
							        p_esito		          OUT NUMBER)
IS

BEGIN

    DELETE FROM CD_COLONNA_SONORA
    WHERE ID_COLONNA_SONORA = p_id_colonna_sonora;

    p_esito := SQL%ROWCOUNT;

    EXCEPTION
		WHEN OTHERS THEN
        p_esito := -1;

END PR_ELIMINA_COLONNA_SONORA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_CODIFICHE
-- DESCRIZIONE:  LA FUNZIONE RESTITUISCE LA LISTA DELLE CODIFICHE DISPONIBILI
--
-- INPUT: NESSUN PARAMETRO DI INPUT PREVISTO
--
-- OUTPUT: REF CURSOR CON LE CODIFICHE DISPONIBILI A SISTEMA
--
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Dicembre 2009
--
-- MODIFICHE
-- -------------------------------------------------
FUNCTION FU_RICERCA_CODIFICHE RETURN C_CODIFICHE
--
IS
c_codifiche_return C_CODIFICHE;
BEGIN
    OPEN c_codifiche_return
        FOR
        SELECT ID_CODIFICA,DESCRIZIONE,NOME FROM CD_ANAG_CODIFICHE;
--
    RETURN c_codifiche_return;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FU_RICERCA_CODIFICHE: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI');
END FU_RICERCA_CODIFICHE;
 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_MATERIALE
-- DESCRIZIONE:  LA FUNZIONE SI OCCUPA DI STAMPARE LE VARIABILI DI PACKAGE
--
-- INPUT: parametri del materiale
--
-- OUTPUT: VARCHAR CHE CONTIENE I PARAMTETRI
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_STAMPA_MATERIALE(    p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_data_inizio              CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine                CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE)  RETURN VARCHAR2
IS

BEGIN

IF v_stampa_materiale = 'ON'

    THEN

     RETURN 'TITOLO: '                    ||  p_titolo                || ', ' ||
            'NOME_FILE: '                 ||  p_nome_file             || ', ' ||
            'DATA_INIZIO: '               ||  p_data_inizio           || ', ' ||
            'DATA_FINE: '                 ||  p_data_fine             || ', ' ||
            'ID_CLIENTE: '                ||  p_id_cliente            || ', ' ||
            'FLG_MULTIPRODOTTO: '         ||  p_flg_multiprodotto    ;

END IF;

END  FU_STAMPA_MATERIALE;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_MATERIALI_PIANO
--
-- DESCRIZIONE:  Restituisce la lista dei materiali legati ad un piano
--
-- OPERAZIONI:
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT: Restitusice la lista di materiali legati al piano
--
-- REALIZZATORE  Michele Borgogno, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_MATERIALI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_MATERIALE_ASS IS

v_materiale C_MATERIALE_ASS;
BEGIN
    OPEN v_materiale FOR
    SELECT MAT_PIA.ID_MATERIALE_DI_PIANO, MAT_PIA.ID_MATERIALE, MAT_PIA.PERC_DISTRIBUZIONE, MAT.TITOLO, SOGG.INT_U_COD_INTERL,
           SOGG.DES_SOGG, MAT_SOGG.COD_SOGG, null,MAT.DURATA,MAT.NOME_FILE
        FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT, CD_MATERIALE_SOGGETTI MAT_SOGG, SOGGETTI SOGG
        WHERE MAT_PIA.ID_PIANO = p_id_piano
        AND   MAT_PIA.ID_VER_PIANO = p_id_ver_piano
        AND   MAT_PIA.ID_MATERIALE = MAT.ID_MATERIALE
        AND   MAT.ID_MATERIALE = MAT_SOGG.ID_MATERIALE
        AND   MAT_SOGG.COD_SOGG = SOGG.COD_SOGG;
    RETURN v_materiale;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_MATERIALI_PIANO;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_MATERIALI
--
-- DESCRIZIONE:  Restituisce la lista dei materiali legati ad un cliente
--
-- OPERAZIONI:
-- INPUT:  Id cliente
-- OUTPUT: Restitusice la lista di materiali legati al cliente
--
-- REALIZZATORE  Michele Borgogno, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_MATERIALI(p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE,
                          p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                          p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN C_MATERIALE_ASS IS

v_materiale C_MATERIALE_ASS;
v_min_data DATE;
v_max_data DATE;
BEGIN

    SELECT MIN(COM.DATA_EROGAZIONE_PREV) ,MAX(COM.DATA_EROGAZIONE_PREV) INTO v_min_data, v_max_data FROM CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO PR
        WHERE PR.ID_PIANO = p_id_piano
        AND PR.ID_VER_PIANO = p_id_ver_piano
        AND COM.ID_PRODOTTO_ACQUISTATO = PR.ID_PRODOTTO_ACQUISTATO
        AND PR.FLG_ANNULLATO = 'N'
        AND PR.FLG_SOSPESO = 'N'
        AND PR.COD_DISATTIVAZIONE IS NULL
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL;



    OPEN v_materiale FOR

    SELECT null, MAT.ID_MATERIALE, null, MAT.TITOLO, SOGG.INT_U_COD_INTERL,
           SOGG.DES_SOGG, MAT_SOGG.COD_SOGG, MAT.FLG_APPROVAZIONE,MAT.DURATA,MAT.NOME_FILE
        FROM CD_MATERIALE MAT, CD_MATERIALE_SOGGETTI MAT_SOGG, SOGGETTI SOGG
        WHERE MAT.ID_CLIENTE = p_id_cliente
        AND   MAT_SOGG.ID_MATERIALE = MAT.ID_MATERIALE
        AND   MAT_SOGG.COD_SOGG = SOGG.COD_SOGG
        AND   (v_min_data BETWEEN MAT.DATA_INIZIO_VALIDITA AND NVL(MAT.DATA_FINE_VALIDITA, TO_DATE('01/01/2099', 'DD/MM/YYYY'))
               OR  v_max_data BETWEEN MAT.DATA_INIZIO_VALIDITA AND NVL(MAT.DATA_FINE_VALIDITA, TO_DATE('01/01/2099', 'DD/MM/YYYY')));
    RETURN v_materiale;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_MATERIALI;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_SALVA_MAT_PIANO
--
-- DESCRIZIONE:  Salva un materiale legato ad un cliente sulla tabella materiali di piano
--
-- OPERAZIONI:
-- INPUT:  Id materiale, Id piano, Id ver piano
-- OUTPUT: Restitusice l'id materiale di piano
--
-- REALIZZATORE  Michele Borgogno, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_SALVA_MAT_PIANO(p_id_materiale CD_MATERIALE_DI_PIANO.ID_MATERIALE%TYPE,
                             p_id_piano CD_MATERIALE_DI_PIANO.ID_PIANO%TYPE,
                             p_id_ver_piano CD_MATERIALE_DI_PIANO.ID_VER_PIANO%TYPE,
                             p_id_mat_piano OUT CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE)is
v_exist number;

begin

SELECT COUNT(1)
INTO v_exist
FROM   CD_MATERIALE_DI_PIANO
WHERE  ID_PIANO         = p_id_piano
AND    ID_VER_PIANO     = p_id_ver_piano
AND    ID_MATERIALE     = p_id_materiale;

IF v_exist =0 THEN
INSERT INTO CD_MATERIALE_DI_PIANO (ID_MATERIALE,ID_PIANO,ID_VER_PIANO)
      VALUES (p_id_materiale,p_id_piano,p_id_ver_piano);

      SELECT CD_MATERIALE_PIANO_SEQ.CURRVAL INTO p_id_mat_piano FROM DUAL;
END IF;
EXCEPTION
WHEN OTHERS THEN
RAISE;
end PR_SALVA_MAT_PIANO;
--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_SOGGETTO_MATERIALE
--
-- DESCRIZIONE:  Restituisce la lista dei soggetti legati ad un determinato materiale
--
-- OPERAZIONI:
-- INPUT:  id del materiale
-- OUTPUT: Restitusice la lista di soggetti legati al materiale. In fase di primo rilascio viene restituito tutto l'elendo
--
-- REALIZZATORE  Antonio colucci, Teoresi, Dicembre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SOGGETTO_MATERIALE(p_id_materiale CD_MATERIALE_SOGGETTI.ID_MATERIALE%TYPE) RETURN C_SOGGETTO_MATERIALE
IS
c_soggetto_materiale_return C_SOGGETTO_MATERIALE;
BEGIN
    OPEN c_soggetto_materiale_return
        FOR
        select id_materiale_soggetti, id_materiale, data_inizio_validita
                      ,data_fine_validita, soggetti.cod_sogg, soggetti.des_sogg from cd_materiale_soggetti,soggetti
                      where id_materiale = p_id_materiale
                      and soggetti.cod_sogg = cd_materiale_soggetti.cod_sogg;
--
    RETURN c_soggetto_materiale_return;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FU_GET_SOGGETTO_MATERIALE: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI:'||sqlerrm);
END FU_GET_SOGGETTO_MATERIALE;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_MATERIALI_SOGGETTO
--
-- DESCRIZIONE:  Restituisce la lista dei materiali per un soggetto
--
-- OPERAZIONI:
-- INPUT:  id del soggetto
-- OUTPUT: Lista di materiali legati ad un soggetto.
--
-- REALIZZATORE  Simone Bottani, Altran, Febbraio 2010
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, 24 Agosto 2010
--              Modificato ref cursor R_MATERIALE, sono stati aggiunti 4 campi
--              che in questa funzione sono stati messi a null
--              Tommaso D'Anna, Teoresi srl, 18 Novembre 2010
--              Modificato ref cursor R_MATERIALE, e stato aggiunto 1 campo
--              che in questa funzione e stato messo a null
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_MATERIALI_SOGGETTO(p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE) RETURN C_MATERIALE IS
v_materiale C_MATERIALE;
BEGIN
    OPEN v_materiale FOR
    SELECT MAT.ID_MATERIALE, MAT.TITOLO, '', 0,'',MAT.DATA_INIZIO_VALIDITA, MAT.DATA_FINE_VALIDITA,'',
        null,null,null,null,null
        FROM CD_MATERIALE MAT, CD_MATERIALE_SOGGETTI MAT_SOGG
        WHERE   MAT.ID_MATERIALE = MAT_SOGG.ID_MATERIALE
        AND   MAT_SOGG.COD_SOGG = p_id_soggetto;
    RETURN v_materiale;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END  FU_GET_MATERIALI_SOGGETTO;

FUNCTION FU_ELENCO_PRODOTTI_SENZA_MATER(P_DATA_INIZIO            CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                        P_DATA_FINE              CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                        P_STATO_DI_VENDITA       CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE
                                        ) 
                                        RETURN C_MAT_DA_ASSOCIARE 
IS
V_MAT_DA_ASSOCIARE C_MAT_DA_ASSOCIARE; 
BEGIN

OPEN V_MAT_DA_ASSOCIARE 
FOR select distinct 
       pa.ID_PRODOTTO_ACQUISTATO,
       pa.DATA_INIZIO,
       pa.DATA_FINE,
       pa.ID_PIANO,
       pa.ID_VER_PIANO,
       cir.NOME_CIRCUITO,
       mod_ven.DESC_MOD_VENDITA as modalita_vendita,
       coeff.DURATA as formato, 
       pa.STATO_DI_VENDITA,
       tb.DESC_TIPO_BREAK as tipo_break,
       iu.RAG_SOC_COGN as cliente
from             cd_comunicato com,
                 cd_prodotto_acquistato pa,
                 cd_pianificazione pi,
                 interl_u iu,
                 cd_formato_acquistabile fa, 
                 cd_coeff_cinema coeff,
                 cd_prodotto_vendita pv,
                 cd_tipo_break tb,
                 cd_modalita_vendita mod_ven,
                 cd_circuito cir
where id_materiale_di_piano is null
and   pa.ID_PRODOTTO_ACQUISTATO = com.ID_PRODOTTO_ACQUISTATO
and   pa.ID_FORMATO = fa.ID_FORMATO
and   fa.ID_COEFF = coeff.ID_COEFF
and   pv.ID_PRODOTTO_VENDITA = pa.ID_PRODOTTO_VENDITA
and   pv.ID_MOD_VENDITA = mod_ven.ID_MOD_VENDITA
and   pv.ID_CIRCUITO = cir.ID_CIRCUITO
and   pv.ID_TIPO_BREAK =  tb.ID_TIPO_BREAK
and   pa.STATO_DI_VENDITA = P_STATO_DI_VENDITA
and   pa.ID_PIANO = pi.ID_PIANO
and   pi.ID_CLIENTE = iu.COD_INTERL
and   pa.DATA_INIZIO >=P_DATA_INIZIO
and   pa.DATA_FINE <= P_DATA_FINE
and   com.ID_MATERIALE_DI_PIANO is null
and   pa.FLG_ANNULLATO = 'N'
and   pa.FLG_SOSPESO = 'N'
and   pa.COD_DISATTIVAZIONE is null
and   com.FLG_ANNULLATO = 'N'
and   com.FLG_SOSPESO = 'N'
and   com.COD_DISATTIVAZIONE is null
order by pa.DATA_INIZIO,
       pa.DATA_FINE,
       pa.ID_PIANO,
       pa.ID_VER_PIANO,
       cir.NOME_CIRCUITO,
       mod_ven.DESC_MOD_VENDITA, 
       coeff.DURATA; 
RETURN V_MAT_DA_ASSOCIARE;
EXCEPTION
WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FU_ELENCO_PRODOTTI_SENZA_MATER: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI:'||sqlerrm);
END FU_ELENCO_PRODOTTI_SENZA_MATER;
--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_PROCURE_VALIDE
--
-- DESCRIZIONE: Funzione che restituisce l'elenco delle procure dove il flag annullato e uguale a 'N'
--
-- OPERAZIONI:
-- OUTPUT: Lista delle procure valide.
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 16 Novembre 2010
--
--  MODIFICHE:  
--               Tommaso D'Anna, Teoresi srl, 22 Novembre 2010
--              Inseriti nuovi campi di ricerca posti a null con le informazioni necessarie solamente
--              per la stampa dei pdf con jasper report   
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROCURE_VALIDE RETURN C_PROCURA
IS
V_PROCURE_VALIDE C_PROCURA; 
BEGIN
    OPEN V_PROCURE_VALIDE
        FOR
            SELECT  ID_PROCURA,
                    NOME,
                    COGNOME,
                    DATA_INIZIO_VAL,
                    DATA_FINE_VAL,
                    NUM_CI,
                    COMUNE_CI,
                    DATA_RILASCIO_CI,
                    null,
                    null,
                    null
            FROM    CD_PROCURA
            WHERE   FLG_ANNULLATO = 'N'
            ORDER BY DATA_INIZIO_VAL DESC;
    RETURN V_PROCURE_VALIDE;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20022, 'FU_GET_PROCURE_VALIDE: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI');
END FU_GET_PROCURE_VALIDE;
--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_PROCURA
--
-- DESCRIZIONE: Funzione che permette di ottenere le informazioni di anagrafica della procura
--              legata al visto censura in osservazione e identificato dall' id
--
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Novembre 2010
--
--  MODIFICHE:  
--               Tommaso D'Anna, Teoresi srl, 22 Novembre 2010
--              Inseriti nuovi campi in uscita:
--              - Data del rilascio nulla osta dal Ministero
--              - Numero del protocollo ministero
--              - Titolo del materiale
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_PROCURA(P_ID_VISTO_CENSURA       CD_VISTO_CENSURA.ID_VISTO_CENSURA%TYPE) 
                             RETURN C_PROCURA
IS
C_RECORD C_PROCURA; 
BEGIN
    OPEN C_RECORD
        FOR
            select
                CD_PROCURA.ID_PROCURA,
                CD_PROCURA.NOME,
                CD_PROCURA.COGNOME,
                CD_PROCURA.DATA_INIZIO_VAL,
                CD_PROCURA.DATA_FINE_VAL,
                CD_PROCURA.NUM_CI,
                CD_PROCURA.COMUNE_CI,
                CD_PROCURA.DATA_RILASCIO_CI,
                CD_MATERIALE.DATA_RIL_NULLAOSTA_MINISTERO,
                CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO,
                CD_MATERIALE.TITOLO
            from 
                cd_visto_censura,
                cd_procura,
                cd_materiale
            where 
                cd_visto_censura.id_visto_censura   = p_id_visto_censura
            and cd_visto_censura.id_procura         = cd_procura.id_procura
            and cd_visto_censura.id_materiale       = cd_materiale.id_materiale;
    RETURN C_RECORD;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20025, 'FU_DETTAGLIO_PROCURA: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI:'||sqlerrm);
END FU_DETTAGLIO_PROCURA;   
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_VISTO_CENSURA
--
-- DESCRIZIONE: Procedura che inserisce un nuovo visto censura. Il blob che conterra il pdf del visto
--              sara un a EMPTY_BLOB() che verra aggiornato dal sistema tramite la classe BLOBManager 
--
-- OPERAZIONI:
-- INPUT: L'id del materiale e della procura di riferimento
-- OUTPUT: esito
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 17 Novembre 2010
--
--  MODIFICHE:  
--              
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_VISTO_CENSURA(   p_id_materiale      CD_MATERIALE.ID_MATERIALE%TYPE,
							            p_id_procura        CD_PROCURA.ID_PROCURA%TYPE,
                                        p_esito             OUT NUMBER)
IS
BEGIN
--
        p_esito:= 1;
    --
  	    SAVEPOINT SP_PR_INSERISCI_VISTO_CENSURA;
  	--
	   -- EFFETTUO L'INSERIMENTO
	    INSERT INTO CD_VISTO_CENSURA
        (   
            ID_MATERIALE,
            ID_PROCURA,
            FILE_VISTO,
            FLG_ANNULLATO,
            UTEMOD,
            DATAMOD
    	    )
	    VALUES
        (   p_id_materiale,
            p_id_procura,
            EMPTY_BLOB(),
            'N',
		    user,
		    FU_DATA_ORA
		);
        SELECT MAX(ID_VISTO_CENSURA) INTO p_esito FROM CD_VISTO_CENSURA;
--
	    EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
		    WHEN OTHERS THEN
		    p_esito := -1;
		    RAISE_APPLICATION_ERROR(-20023, 'Procedura PR_INSERISCI_VISTO_CENSURA: Insert non eseguita, verificare la coerenza dei parametri ID_MATERIALE='||p_id_materiale||' - ID_PROCURA='||p_id_procura);
		    ROLLBACK TO SP_PR_INSERISCI_VISTO_CENSURA;

END PR_INSERISCI_VISTO_CENSURA;
--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_PROCURA
--
-- DESCRIZIONE: Funzione che permette di ottenere una firma RANDOM della procura valida a sysdate
--
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Novembre 2010
--
--  MODIFICHE:  
--               
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_FIRMA_VALIDA RETURN BLOB
IS
V_FIRMA BLOB; 
BEGIN
    /*
    select file_procura as firma 
    into v_firma
    from cd_procura where id_procura = 3;
    */
    select firma into v_firma 
    from
    (
    select id_firma_procura,firma 
        from cd_firma_procura
        where id_procura = 
            --Recupero Procura Valida
            (select id_procura 
            from cd_procura 
            where 
                data_inizio_val <= trunc(sysdate) 
            and (data_fine_val is null or data_fine_val>=trunc(sysdate)) )
        order by dbms_random.value)
    where rownum =1;
    
    RETURN v_firma ;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20025, 'FU_GET_FIRMA_PROCURA_VALIDA: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI:'||sqlerrm);
END FU_GET_FIRMA_VALIDA;   
--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_FIRMA_DICH_SOST
--
-- DESCRIZIONE: Funzione che permette di ottenere una firma RANDOM della procura 
--              identificata dal parametro passato in input
--
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Novembre 2010
--
--  MODIFICHE:  
--               
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_FIRMA_DICH_SOST(p_id_procura CD_PROCURA.ID_PROCURA%TYPE)
                                 RETURN BLOB
IS
V_FIRMA BLOB; 
BEGIN
    /*
    select file_procura as firma 
    into v_firma
    from cd_procura where id_procura = 3;
    */
    
    select firma into v_firma 
    from
    (
        select id_firma_procura,firma 
        from cd_firma_procura
        where id_procura = p_id_procura
        order by dbms_random.value
    )
    where rownum =1;
    
    RETURN v_firma ;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20025, 'FU_GET_FIRMA_DICH_SOST: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI:'||sqlerrm);
END FU_GET_FIRMA_DICH_SOST;   
-----------------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_VISTO_CENSURA
--
-- DESCRIZIONE:  Esegue la modifica di un visto censura
--
-- OPERAZIONI:
--              Modifica l'identificativo della procura, in quanto e l'unica cosa modificabile dato l'id
--              del materiale (il blob viene modificato tramite BLOBManager via Java)
--
-- INPUT: parametri per la modifica di una colonna sonora
--
--
-- REALIZZATORE: Tommaso D'Anna, Teoresi srl, 17 Novembre 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_VISTO_CENSURA(    p_id_materiale      CD_VISTO_CENSURA.ID_MATERIALE%TYPE,
							            p_id_procura        CD_VISTO_CENSURA.ID_PROCURA%TYPE,
                                        p_esito             OUT NUMBER)
IS

BEGIN

  	SAVEPOINT SP_PR_MODIFICA_VISTO_CENSURA;

    UPDATE CD_VISTO_CENSURA
    SET    ID_PROCURA = NVL(p_id_procura,ID_PROCURA)
    WHERE  ID_MATERIALE = p_id_materiale;

    p_esito := SQL%ROWCOUNT;

EXCEPTION
		WHEN OTHERS THEN
        p_esito := -1;
		RAISE_APPLICATION_ERROR(-20026, 'Procedura PR_MODIFICA_VISTO_CENSURA: Update non eseguita, verificare la coerenza dei parametri '||SQLERRM);
        ROLLBACK TO SP_PR_MODIFICA_VISTO_CENSURA;

END PR_MODIFICA_VISTO_CENSURA;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_AUTORIZZA_MATERIALE
--
-- DESCRIZIONE:  Autorizza un materiale per il visto censura
--
-- OPERAZIONI:
--   1) Imposta la data autorizzazione del materiale
--
-- INPUT:
--      p_id_materiale         id del materiale
--      p_data_autorizzazione  data
--- 
-- OUTPUT: esito:
--
-- REALIZZATORE: Michele Borgogno, Altran, Agosto 2010
--
--  MODIFICHE: Mauro Viel Altran, Novembre 2010 aggiunto il parametro p_data_autorizzazione.
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_AUTORIZZA_MATERIALE( p_id_materiale IN CD_MATERIALE.ID_MATERIALE%TYPE,p_data_autorizzazione date,
							    p_esito OUT NUMBER) IS
                                
v_num_materiali NUMBER;
--
BEGIN 
    p_esito := 0;

    SELECT COUNT(1) 
    INTO v_num_materiali
    FROM CD_MATERIALE
    WHERE ID_MATERIALE = p_id_materiale
    AND DATA_AUT_INVIO_MINISTERO is not null;
      --
    IF v_num_materiali = 0 THEN
        UPDATE CD_MATERIALE SET DATA_AUT_INVIO_MINISTERO = p_data_autorizzazione --trunc(SYSDATE)
        WHERE ID_MATERIALE =  p_id_materiale;
    ELSE
        p_esito := -1;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FU_AUTORIZZA_MATERIALE: SI E VERIFICATO UN ERRORE DURANTE L''AUTORIZZAZIONE DEL MATERIALE:'||sqlerrm);
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_CONSEGNA_MAT_MINISTERO
--
-- DESCRIZIONE:  Valorizza la data di consegna al Ministero di un materiale
--
-- OPERAZIONI:
--   1) Imposta la data di consegna del materiale
--
-- INPUT:
--      p_id_materiale      id del materiale
--
-- OUTPUT: esito:
--
-- REALIZZATORE: Michele Borgogno, Altran, Agosto 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CONSEGNA_MAT_MINISTERO(p_id_materiale IN CD_MATERIALE.ID_MATERIALE%TYPE,
                                    p_data_consegna CD_MATERIALE.DATA_CONSEGNA_MINISTERO%TYPE,
							        p_esito OUT NUMBER) IS
v_data_autorizzazione DATE;
--
BEGIN 
    p_esito := 0;
--
    SELECT mat.DATA_AUT_INVIO_MINISTERO
    INTO v_data_autorizzazione
    FROM CD_MATERIALE mat
    WHERE mat.ID_MATERIALE = p_id_materiale;

    IF (v_data_autorizzazione is not null AND p_data_consegna >= v_data_autorizzazione) THEN
        --
        UPDATE CD_MATERIALE SET DATA_CONSEGNA_MINISTERO = trunc(p_data_consegna)
        WHERE ID_MATERIALE =  p_id_materiale; 
    ELSE
        IF (v_data_autorizzazione is null) THEN
            p_esito := -1;
        ELSIF (p_data_consegna < v_data_autorizzazione) THEN
            p_esito := -2;
        ELSE
            p_esito := -10;
        END IF;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'PR_CONSEGNA_MAT_MINISTERO: SI E VERIFICATO UN ERRORE DURANTE IL SALVATAGGIO DELLA DATA DI CONSEGNA AL MINISTERO:'||sqlerrm);
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_RILASCIO_NULLA_OSTA
--
-- DESCRIZIONE:  Valorizza la data di rilascio e il numero protocollo del nulla osta
--
-- INPUT:
--      p_id_materiale      id del materiale
--
-- OUTPUT: esito:
--
-- REALIZZATORE: Michele Borgogno, Altran, Agosto 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RILASCIO_NULLA_OSTA(p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE,
                                 p_data_ril_nulla_osta CD_MATERIALE.DATA_RIL_NULLAOSTA_MINISTERO%TYPE,
                                 p_protocollo CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO%TYPE,
							     p_esito OUT NUMBER) IS
v_data_consegna DATE;
--
BEGIN 
    p_esito := 0;
--
    SELECT mat.DATA_CONSEGNA_MINISTERO
    INTO v_data_consegna
    FROM CD_MATERIALE mat
    WHERE mat.ID_MATERIALE = p_id_materiale;
    
    IF (v_data_consegna is not null AND p_data_ril_nulla_osta >= v_data_consegna) THEN
        --
        UPDATE CD_MATERIALE SET 
            DATA_RIL_NULLAOSTA_MINISTERO = trunc(p_data_ril_nulla_osta),
            NUMERO_PROTOCOLLO_MINISTERO = p_protocollo
        WHERE ID_MATERIALE =  p_id_materiale
        AND DATA_AUT_INVIO_MINISTERO is not null;
    ELSE
        IF (v_data_consegna is null) THEN
            p_esito := -1;
        ELSIF (p_data_ril_nulla_osta < v_data_consegna) THEN
            p_esito := -2;
        ELSE
            p_esito := -10;
        END IF;
    END IF;

--
  EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'PR_RILASCIO_NULLA_OSTA: SI E VERIFICATO UN ERRORE DURANTE il rilascio del nulla osta:'||sqlerrm);
END;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_MATERIALE_SOTTO_TUTELA
--
-- DESCRIZIONE: 
--      Funzione che recupera un flag 'S' o 'N' indicante se il materiale e' sotto tutela o no
--
--
-- REALIZZATORE:
--      Tommaso D'Anna, Teoresi s.r.l., 23 Maggio 2011              
--              
-- --------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALE_SOTTO_TUTELA(p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE)
                                 RETURN VARCHAR
IS
v_tutela VARCHAR(1);
BEGIN  
    SELECT
        FU_CD_VERIFICA_TUTELA(CD_MATERIALE.ID_CLIENTE, CD_MATERIALE_SOGGETTI.COD_SOGG, CD_MATERIALE.ID_MATERIALE)
    INTO v_tutela
    FROM
        CD_MATERIALE,
        CD_MATERIALE_SOGGETTI
    WHERE   CD_MATERIALE.ID_MATERIALE = p_id_materiale
    AND     CD_MATERIALE_SOGGETTI.ID_MATERIALE = CD_MATERIALE.ID_MATERIALE;
    
    RETURN v_tutela ;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20047, 'FU_MATERIALE_SOTTO_TUTELA: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI:'||sqlerrm);
END FU_MATERIALE_SOTTO_TUTELA;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_MATERIALI_SOTTO_TUTELA
--
-- DESCRIZIONE: 
--      Funzione che recupera un flag 'S' o 'N' indicante se almeno un materiale di quelli 
--      inseriti e' sotto tutela
--
--      Accetta una stringa del tipo MMATERIALE_1MMMATERIALE_2MMMATERIALE_3M
--
--
-- REALIZZATORE:
--      Tommaso D'Anna, Teoresi s.r.l., 23 Maggio 2011              
--              
-- --------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALI_SOTTO_TUTELA(p_stringa_materiali VARCHAR)
                                 RETURN VARCHAR
IS
v_tutela VARCHAR(1);
BEGIN  
    SELECT 
        decode( COUNT(1),0,'N','S')
    INTO 
        v_tutela
    FROM 
        CD_MATERIALE
    WHERE instr( p_stringa_materiali, 'M' || ID_MATERIALE || 'M') > 0
    AND   PA_CD_MATERIALE.FU_MATERIALE_SOTTO_TUTELA(ID_MATERIALE) = 'S';
    
    RETURN v_tutela ;
    EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20047, 'FU_MATERIALI_SOTTO_TUTELA: SI E VERIFICATO UN ERRORE DURANTE IL REPERIMENTO DELLE INFORMAZIONI:'||sqlerrm);
END FU_MATERIALI_SOTTO_TUTELA; 

END PA_CD_MATERIALE; 
/

