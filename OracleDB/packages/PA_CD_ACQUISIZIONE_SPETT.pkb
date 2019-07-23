CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_ACQUISIZIONE_SPETT IS
--
---------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ALLINEA_DATI_ACQUISITI
--
-- DESCRIZIONE:  Procedura che si occupa di allineare i dati ricevuti da Cinetel e presenti nella
--               tabella CD_DATI_CINETEL_SIPRA
--
-- OPERAZIONI:
--   1) Recupera l'elenco dei dati presenti nella tabella CD_DATI_CINETEL_SIPRA
--   2) Se vengono rilevati spettacoli non presenti nella tabella CD_SPETTACOLO questi vengono censiti
--   3) Aggiornamento (insert/update) tabella CD_SPETTATORI_EFF con i dati appena recuperati
--   4) Instaurazione del legame CD_SPETTATORI_EFF / SPETTACOLO attraverso la valorizzazione
--      della FK ID_SPETTACOLO nella tabella CD_SPETTATORI_EFF
--   5) Cancellazione dei dati dalla tabella CD_DATI_CINETEL_SIPRA in caso di esito positivo delle operazioni
--      sopra citate
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione
--         -1 Presenza di circuiti non presenti in anagrafica Sipra
--         -2 Presenza di associazioni sala-circuiti non presenti nella base dati Sipra
--         -3 Errore non previsto durante le operazioni di aggiornamento tabella
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 5 Marzo 2010
--
--  MODIFICHE: Antonio Colucci, Teoresigroup srl, 13 Luglio 2010 
--                  Gestione causali Cinetel in caso di zero spettatori
--             Antonio Colucci, Teoresigroup srl, 22 Luglio 2010
--                  Cancellazione delle righe da CD_SPETTATORI_EFF in base a quelle che 
--                  verranno trattate attraverso la tavola CD_DATI_CINETEL_SIPRA 
--              Antonio Colucci, Teoresigroup srl, 01 Febbraio 2011
--                  Inserita chiamata alla procedura PR_ALLINEA_FATTO_SPETTATORI
--              Antonio Colucci, Teoresigroup srl, 05/07/2011
--                  Affinata query di estrazione delle sale sulle quali eseguire un controllo di integrita
--              Antonio Colucci, Teoresigroup srl, 18/07/2011
--                  Sostituzione uso con flg_attivo con data_inizio_validita
-------------------------------------------------------------------------------------------------

PROCEDURE PR_ALLINEA_DATI_ACQUISITI(p_esito OUT NUMBER)
IS 
V_NUM_CIRCUITI_INESISTENTI NUMBER;
V_NUM_COPPIE NUMBER;
num_rec NUMBER;
v_data_inizio   DATE;
v_data_fine     DATE;
--
BEGIN -- PR_PROVA
--
    SAVEPOINT SP_ALLINEA_DATI_ACQUISITI;
    P_ESITO     := 1;
    /*Prima di procedere con i calcoli provvedo a pulire la tavola 
      CD_SPETTATORI_EFF con i dati che sto per caricare dalla tavola CD_DATI_CINETEL_SIPRA
      perche potrebbero esserci rilevazioni sulla stessa sala/giorno ma
      con film (e non solo spettatori) diversi. Se non venisse eseguita la delete
      verrebe trattato come dato diverso dove non viene fatto l'update e 
      quindi rimarrebbe un dato sporco
    */
    select min(data_rif),max(data_rif)
    into v_data_inizio,v_data_fine
    from CD_DATI_CINETEL_SIPRA;
    
    FOR DATI_DA_PULIRE IN 
        (SELECT DISTINCT ID_SALA,DATA_RIF FROM CD_DATI_CINETEL_SIPRA)
    LOOP
        DELETE CD_SPETTATORI_EFF
        WHERE
            CD_SPETTATORI_EFF.ID_SALA = DATI_DA_PULIRE.ID_SALA
        AND CD_SPETTATORI_EFF.DATA_RIFERIMENTO = DATI_DA_PULIRE.DATA_RIF;
    END LOOP;
    /*CONTROLLO ESISTENZA CIRCUITI IN ANAGRAFICA*/
    SELECT COUNT(DISTINCT ID_CIRCUITO) INTO V_NUM_CIRCUITI_INESISTENTI 
    FROM CD_DATI_CINETEL_SIPRA 
    WHERE ID_CIRCUITO NOT IN 
        (SELECT ID_CIRCUITO 
            FROM CD_CIRCUITO WHERE 
                (DATA_FINE_VALID IS NULL OR DATA_FINE_VALID >= TRUNC(SYSDATE))
        );
    IF(V_NUM_CIRCUITI_INESISTENTI > 0)THEN
        P_ESITO     := -1;
    ELSE
        /*CONTROLLO COERENZA ASSOCIAZIONI SALA-CIRCUITO 
            IN BASE ALLA DATA DI RIFERIMENTO
            e alle sale presenti nel file sotto osservazione
            che sono VALIDE
            e 
            associate a cinema ATTIVI*/
            /*#05/07/2011#*/
        FOR COPPIE IN (
            SELECT  CD_DATI_CINETEL_SIPRA.ID_SALA,ID_CIRCUITO,DATA_RIF 
            FROM    CD_DATI_CINETEL_SIPRA,cd_sala,cd_cinema
            where   CD_DATI_CINETEL_SIPRA.id_sala = cd_sala.id_sala
            and     cd_sala.id_cinema = cd_cinema.id_cinema
            and     cd_cinema.data_inizio_validita <= CD_DATI_CINETEL_SIPRA.data_rif
            and     (cd_sala.data_fine_validita is null or cd_sala.data_fine_validita>= DATA_RIF) 
            ORDER BY CD_DATI_CINETEL_SIPRA.ID_SALA,DATA_RIF)
        LOOP
            SELECT  COUNT(DISTINCT ID_CIRCUITO_SCHERMO) INTO V_NUM_COPPIE
            FROM    CD_CIRCUITO_SCHERMO,
                    CD_LISTINO,
                    cd_schermo
            WHERE   ID_CIRCUITO = COPPIE.ID_CIRCUITO
            AND     CD_CIRCUITO_SCHERMO.ID_LISTINO = cd_listino.id_listino
            and     COPPIE.DATA_RIF BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE
            AND     CD_CIRCUITO_SCHERMO.ID_SCHERMO = cd_schermo.id_schermo
            and     cd_schermo.id_sala = COPPIE.ID_SALA
            AND     CD_CIRCUITO_SCHERMO.FLG_ANNULLATO = 'N';
            /*#05/07/2011#*/
            IF(V_NUM_COPPIE = 0)THEN
                /*TROVATA ANOMALIA: COPPIA CIRCUITO-SCHERMO NON VALIDA*/
                P_ESITO     := -2;
                EXIT;
            END IF;
        END LOOP;
        
        IF(p_esito>0)THEN
            /*Elimino eventuali occorrenze riferite
              a sale di cinema non validi*/
            /*#05/07/2011#*/
            delete from cd_dati_cinetel_sipra
            where id_sala in 
            (
                select distinct id_sala
                from cd_cinema,cd_sala
                where cd_sala.id_cinema = cd_cinema.id_cinema
                and   cd_cinema.data_inizio_validita > cd_dati_cinetel_sipra.data_rif
            );
            /*#05/07/2011#*/
            /*Procedo con gli aggiornamenti su DB*/
            /*
            AGGIORNO TAVOLe 
                SPETTACOLI
                CASE DI DISTRIBUZIONE 
                CAUSALI CINETEL
            CON EVENTUALI DATI NUOVI
            */
            INSERT INTO CD_DISTRIBUTORE
            (
            CASA_DISTRIBUZIONE 
            )
            SELECT DISTINCT DISTRIBUTORE FROM CD_DATI_CINETEL_SIPRA WHERE
            NUMERO_SPETTATORI>0 AND DISTRIBUTORE 
            NOT IN
            (
                SELECT DISTINCT CASA_DISTRIBUZIONE FROM CD_DISTRIBUTORE
            )
            AND DISTRIBUTORE IS NOT NULL; 
            /*
                AGGIORNO LA TABELLA CD_SPETTACOLO
                EVENTUALMENTE CON L'ASSOCIAZIONE ANCHE DELLA CASA DI DISTRIBUZIONE
            */
            INSERT INTO CD_SPETTACOLO
            (
                NOME_SPETTACOLO,
                DATA_INIZIO,
                PROVENIENZA,
                ID_DISTRIBUTORE
            )
            SELECT DISTINCT TITOLO_FILM,TRUNC(SYSDATE),
                   'CINETEL' PROVENIENZA, ID_DISTRIBUTORE 
            FROM CD_DATI_CINETEL_SIPRA,CD_DISTRIBUTORE
            WHERE 
                    NUMERO_SPETTATORI >0
                AND UPPER(TITOLO_FILM) NOT IN
                (
                    SELECT DISTINCT UPPER(NOME_SPETTACOLO) FROM CD_SPETTACOLO
                )
                AND CASA_DISTRIBUZIONE IS NOT NULL
                AND CASA_DISTRIBUZIONE = DISTRIBUTORE;
            
            /*CENSIMENTO EVENTUALI NUOVE CAUSALI CINETEL*/
            INSERT INTO CD_CAUSALE_CINETEL
            (
            DESC_CINETEL
            )
            SELECT DISTINCT UPPER(TITOLO_FILM) FROM CD_DATI_CINETEL_SIPRA
            WHERE NUMERO_SPETTATORI = 0
            AND   UPPER(TITOLO_FILM) 
            NOT IN 
                (SELECT DISTINCT UPPER(DESC_CINETEL) FROM CD_CAUSALE_CINETEL);
            /*
                AGGIORNO LA TABELLA CD_SPETTATORI_EFF
                PER OGNI RECORD CHE ANALIZZO, SE ESISTE GIA UN'OCCORRENZA 
                IN TABELLA PROCEDO CON L'UPDATE
            */
            FOR DATI_ACQUISITI IN 
               (SELECT DATA_RIF,ID_SALA
                      ,spettacoli.ID_SPETTACOLO
                      ,SUM(NUMERO_SPETTATORI) NUMERO_SPETTATORI
                    FROM  CD_DATI_CINETEL_SIPRA,
                        (
                    	select min(id_spettacolo) id_spettacolo,upper(nome_spettacolo) nome_spettacolo
                    	from cd_spettacolo group by upper(nome_spettacolo)
                        )spettacoli
                    WHERE UPPER(CD_DATI_CINETEL_SIPRA.TITOLO_FILM) = UPPER(spettacoli.NOME_SPETTACOLO)
                    AND NUMERO_SPETTATORI > 0
                    GROUP BY DATA_RIF,ID_SALA,spettacoli.ID_SPETTACOLO
                UNION
                SELECT DATA_RIF,ID_SALA,NULL ID_SPETTACOLO
                       ,SUM(NUMERO_SPETTATORI) NUMERO_SPETTATORI
                 FROM CD_DATI_CINETEL_SIPRA
                 WHERE ( ( CD_DATI_CINETEL_SIPRA.DISTRIBUTORE IS NULL ) 
                        OR
                         (UPPER(CD_DATI_CINETEL_SIPRA.TITOLO_FILM) NOT IN (SELECT DISTINCT UPPER(CD_SPETTACOLO.NOME_SPETTACOLO) FROM CD_SPETTACOLO)
                            AND DISTRIBUTORE IS NOT NULL)
                       )
                 AND NUMERO_SPETTATORI > 0
                GROUP BY DATA_RIF,ID_SALA)
               LOOP
               /*
                Verifico esistenza dato in tabella. In caso affermativo
                procedo con update e non con insert
                */
               select count(1) into num_rec from cd_spettatori_eff
                   where cd_spettatori_eff.DATA_RIFERIMENTO = dati_acquisiti.data_rif
                   and   cd_spettatori_eff.ID_SALA = dati_acquisiti.id_sala
                   and   (
                           (cd_spettatori_eff.id_spettacolo is null and dati_acquisiti.id_spettacolo is null )
                          or 
                           (cd_spettatori_eff.id_spettacolo = dati_acquisiti.id_spettacolo)
                          );
               if(num_rec > 0)then
               /*DENTRO QUESTO IF NON DOVREBBE PIu ENTRARE IN QUANTO I DATI VENGONO CANCELLATI
               SUBITO DOPO L'INIZIO DELLA PROCEDURA*/
               /*Procedo con update*/
               update cd_spettatori_eff
                set
                    NUM_SPETTATORI = dati_acquisiti.numero_spettatori
                where
                    cd_spettatori_eff.DATA_RIFERIMENTO = dati_acquisiti.data_rif
                   and   cd_spettatori_eff.ID_SALA = dati_acquisiti.id_sala
                   and   cd_spettatori_eff.id_spettacolo = dati_acquisiti.id_spettacolo;
               else
               /*Procedo con insert*/
               insert into cd_spettatori_eff
                   (
                   ID_SALA,
                   NUM_SPETTATORI,
                   DATA_RIFERIMENTO,
                   id_spettacolo 
                   )
               values
                    (
                    dati_acquisiti.id_sala,
                    dati_acquisiti.numero_spettatori,
                    dati_acquisiti.data_rif,
                    dati_acquisiti.id_spettacolo
                    );
               end if;
           end loop;
           /*
                AGGIORNO LA TABELLA CD_SPETTATORI_EFF PER INSERIMENTO NUM_SPETTATORI = 0
                PER OGNI RECORD CHE ANALIZZO, 
                PRIMA DI PROCEDERE ELIMINO EVENTUALI OCCRRENZE GIa PRESENTI
            */
            FOR DATI_ELIMINA IN
            (SELECT ID_SALA, DATA_RIF FROM CD_DATI_CINETEL_SIPRA)
            LOOP
                DELETE FROM CD_SPETTATORI_EFF WHERE 
                    ID_SALA = DATI_ELIMINA.ID_SALA
                AND DATA_RIFERIMENTO = DATI_ELIMINA.DATA_RIF
                AND NUM_SPETTATORI = 0;
            END LOOP;
            FOR DATI_NON_ACQUISITI IN 
               (SELECT DATA_RIF,ID_SALA, TITOLO_FILM, causali.id_cinetel
                      FROM  CD_DATI_CINETEL_SIPRA,
                        (
                    	select distinct id_cinetel,desc_cinetel from cd_causale_cinetel
                        )causali
                    WHERE UPPER(CD_DATI_CINETEL_SIPRA.TITOLO_FILM) = UPPER(causali.desc_cinetel)
                    AND NUMERO_SPETTATORI = 0
                    GROUP BY DATA_RIF,ID_SALA,TITOLO_FILM,causali.id_cinetel
               )
               LOOP
               /*Procedo con insert*/
               insert into cd_spettatori_eff
                   (
                   ID_SALA,
                   NUM_SPETTATORI,
                   DATA_RIFERIMENTO,
                   ID_CINETEL 
                   )
               values
                    (
                    DATI_NON_ACQUISITI.id_sala,
                    0,
                    DATI_NON_ACQUISITI.data_rif,
                    DATI_NON_ACQUISITI.ID_CINETEL
                    );
           end loop;
        /*dopo tutte le operazioni di aggiornamento
        prima di cancellare la tavola recuper data_min e data_max 
        e con queste date aggiorno tavola CD_FATTO_SPETTATORI*/
        PR_ALLINEA_FATTO_SPETTATORI(v_data_inizio,v_data_fine);
        END IF;
    END IF;
    /*Pulisco Tabella di appoggio CD_DATI_CINETEL_SIPRA*/
    delete from cd_dati_cinetel_sipra;
  EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -3;
        delete from cd_dati_cinetel_sipra;
        RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_ALLINEA_DATI_ACQUISITI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:'||SQLERRM);
        ROLLBACK TO SP_ALLINEA_DATI_ACQUISITI;
--
END PR_ALLINEA_DATI_ACQUISITI;
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_CINEMA_SETTIMANA
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               degli spettatori complessivi per cinema all'interno di una settimana
--
-- OPERAZIONI:
--   1) Recupera la lista degli spettatori complessivi per cinema
--
-- INPUT:
--      p_data_inizio          data inizio di riferimento
--      p_data_fine            data fine di riferimento,
--      p_id_cinema            indicativo del cinema,
--
-- OUTPUT: lista degli spettatori effettvi spaccati per settimana e per cinema
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Febbraio 2010
--
--  MODIFICHE: Mauro Viel, Altran Dicembre 2010 inserita gestione del nome cinema.
--             
-------------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_CINEMA_SETTIMANA( p_data_inizio         DATE,
                                    p_data_fine           DATE,
                                    p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                    p_id_sala             CD_SALA.ID_SALA%TYPE,
                                    p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                    p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                    p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                                    p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                    p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                    p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                     ) RETURN C_SPETT_CINEMA
IS
C_SPETTATORI C_SPETT_CINEMA;
BEGIN
    OPEN C_SPETTATORI
    FOR
        select cd_cinema.id_cinema,
               --cd_cinema.NOME_CINEMA,
               pa_cd_cinema.FU_GET_NOME_CINEMA(cd_cinema.id_cinema,p_data_fine) AS NOME_CINEMA,  
               cd_comune.comune,cd_provincia.PROVINCIA,cd_regione.NOME_REGIONE regione,
              'NON SPECIFICATO' RAGIONE_SOCIALE,
              'NON SPECIFICATO' tipo_cinema,
               sum(cd_spettatori_eff.num_spettatori)tot_spettatori,
               NULL DATA_INIZIO,NULL DATA_FINE, 
               NULL DATA_RIF  
        from 
               cd_spettatori_eff--, periodi
               ,cd_sala,
               cd_cinema,cd_comune, cd_provincia, 
               cd_regione, cd_area_nielsen, 
               cd_nielsen_regione,
               cd_spettacolo,cd_liquidazione_sala
        where
                 /*Filtri di Ricerca*/
               trunc(cd_spettatori_eff.data_riferimento) between p_data_inizio and p_data_fine
               and (p_id_comune is null or cd_comune.id_comune = p_id_comune)
               and (p_id_sala is null or cd_sala.id_sala = p_id_sala)
               and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
               and (p_id_regione is null or cd_regione.id_regione = p_id_regione)
               and (p_id_area_nielsen is null or cd_area_nielsen.id_area_nielsen = p_id_area_nielsen)
               and (p_id_tipo_cinema is null or cd_cinema.id_tipo_cinema = p_id_tipo_cinema)
               and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo)
               and (p_flg_venduta is null or cd_liquidazione_sala.flg_programmazione = p_flg_venduta)
                /*Fine Filtri di Ricerca*/
               and cd_sala.id_sala = cd_spettatori_eff.id_sala
               and cd_sala.id_cinema = cd_cinema.id_cinema
               and cd_cinema.id_comune = cd_comune.id_comune
               and cd_comune.id_provincia = cd_provincia.id_provincia
               and cd_provincia.id_regione = cd_regione.id_regione
               and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
               and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
               and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
               and cd_spettatori_eff.id_sala = cd_liquidazione_sala.id_sala (+) 
               and cd_spettatori_eff.data_riferimento = cd_liquidazione_sala.data_rif(+)
            group by
               --periodi.data_iniz,periodi.data_fine,
               cd_cinema.id_cinema,
               --cd_cinema.NOME_CINEMA,
               pa_cd_cinema.FU_GET_NOME_CINEMA(cd_cinema.id_cinema,p_data_fine), 
               cd_comune.comune,cd_provincia.PROVINCIA, cd_regione.NOME_REGIONE--,esercente
            order by NOME_CINEMA; 
    RETURN C_SPETTATORI;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'FUNZIONE FU_SPETT_CINEMA_SETTIMANA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_SPETT_CINEMA_SETTIMANA;

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_CINEMA_GIORNO
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               degli spettatori complessivi per cinema all'interno di un GIORNO
--
-- OPERAZIONI:
--   1) Recupera la lista degli spettatori complessivi per cinema
--
-- INPUT:
--      p_data_inizio          data inizio di riferimento
--      p_data_fine            data fine di riferimento,
--      p_id_cinema            indicativo del cinema,
--
-- OUTPUT: lista degli spettatori effettvi spaccati per giorno e per cinema
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Febbraio 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
/*
FUNCTION FU_SPETT_CINEMA_GIORNO(  p_data_inizio         DATE,
                                  p_data_fine           DATE,
                                  p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE
                               )  RETURN VARCHAR2
IS
RETURN_VAR VARCHAR2(240);
BEGIN
    
RETURN_VAR := 'P';
RETURN RETURN_VAR;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_CINEMA_GIORNO: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_SPETT_CINEMA_GIORNO;
*/
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_SALA_SETTIMANA
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               degli spettatori complessivi per sala - cinema 
--               all'interno di una
--               SETIMANA SIPRA
--
-- OPERAZIONI:
--   1) Recupera la lista degli spettatori complessivi per cinema
--
-- INPUT:
--      p_data_inizio          data inizio di riferimento
--      p_data_fine            data fine di riferimento,
--      p_id_cinema            indicativo del cinema,
--      p_id_sala              indicativo del sala,
--
-- OUTPUT: lista degli spettatori effettivi spaccati per settimana e per sala-cinema
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Febbraio 2010
--
--  MODIFICHE: 
--  Mauro Viel, Altran Dicembre 2010 inserita gestione del nome cinema.
-------------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_SALA_SETTIMANA(
                                p_data_inizio         DATE,
                                p_data_fine           DATE,
                                p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala             CD_SALA.ID_SALA%TYPE,
                                p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,  
                                p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                )  RETURN C_SPETT_SALA
IS
C_SPETTATORI C_SPETT_SALA;
BEGIN
    OPEN C_SPETTATORI
    FOR
        with elenco_circuiti as
        (
        select distinct 
          id_sala,
          id_cinema,
          nome_cinema,
          comune,
          nome_sala,
          REPLACE(VENCD.fu_cd_string_agg( NOME_CIRCUITO) over (partition by id_sala),';',', ') NOME_CIRCUITO
          from
            (
                select distinct
                      cd_sala.id_sala,
                      cd_cinema.id_cinema,
                      cd_cinema.nome_cinema,
                      cd_comune.comune,
                      cd_sala.nome_sala,
                      cd_circuito.nome_circuito
                      --REPLACE(VENCD.fu_cd_string_agg( cd_circuito.NOME_CIRCUITO) over (partition by cd_sala.id_sala),';',', ') NOME_CIRCUITO
                from    
                        cd_cinema,
                        cd_comune,
                        cd_sala,
                        cd_schermo,
                        cd_circuito,
                        cd_circuito_schermo
                where
                        cd_schermo.id_schermo = cd_circuito_schermo.id_schermo    
                and     cd_circuito_schermo.id_circuito = cd_circuito.ID_CIRCUITO
                and     cd_circuito_schermo.flg_annullato = 'N'
                and     cd_circuito.FLG_DEFINITO_A_LISTINO = 'S'
                and     cd_schermo.id_sala = cd_sala.id_sala
                and     cd_sala.flg_visibile = 'S'
                and     cd_sala.flg_arena = 'N'
                and     cd_sala.id_cinema = cd_cinema.id_cinema
                and     cd_cinema.flg_virtuale = 'N'
                and     cd_comune.id_comune = cd_cinema.id_comune
                and     cd_sala.id_sala = nvl(p_id_sala,cd_sala.id_sala)
                and     cd_cinema.id_cinema = nvl(p_id_cinema,cd_cinema.id_cinema))
            )
        select distinct 
           cd_spettatori_eff.id_sala,
           cd_cinema.id_cinema,
           pa_cd_cinema.FU_GET_NOME_CINEMA(cd_cinema.id_cinema,p_data_fine) AS NOME_CINEMA, 
           cd_sala.nome_sala, cd_comune.comune,
           sum(cd_spettatori_eff.num_spettatori) over (partition by cd_spettatori_eff.id_sala) tot_spettatori,
           elenco_circuiti.nome_circuito,
           NULL DATA_INIZIO, NULL DATA_FINE, 
           NULL DATA_RIF
        from 
               cd_spettatori_eff,
               cd_cinema, cd_sala, cd_comune,
               cd_regione, cd_area_nielsen, 
               cd_nielsen_regione, cd_provincia,
               cd_spettacolo,cd_liquidazione_sala
               ,elenco_circuiti 
        where
               /*Filtri di Ricerca*/
               trunc(cd_spettatori_eff.data_riferimento) between p_data_inizio and p_data_fine
               and (p_id_comune is null or cd_comune.id_comune = p_id_comune)
               and (p_id_sala is null or cd_sala.id_sala = p_id_sala)
               and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
               and (p_id_regione is null or cd_regione.id_regione = p_id_regione)
               and (p_id_area_nielsen is null or cd_area_nielsen.id_area_nielsen = p_id_area_nielsen)
               and (p_id_tipo_cinema is null or cd_cinema.id_tipo_cinema = p_id_tipo_cinema)
               and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo)
               and (p_flg_venduta is null or cd_liquidazione_sala.flg_programmazione = p_flg_venduta)
               /*Fine Filtri di Ricerca*/
               and cd_sala.id_sala = cd_spettatori_eff.id_sala
               and cd_sala.id_cinema = cd_cinema.id_cinema
               and cd_cinema.id_comune = cd_comune.id_comune
               and cd_comune.id_provincia = cd_provincia.id_provincia
               and cd_provincia.id_regione = cd_regione.id_regione
               and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
               and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
               and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
               and cd_spettatori_eff.id_sala = cd_liquidazione_sala.id_sala (+) 
               and cd_spettatori_eff.data_riferimento = cd_liquidazione_sala.data_rif(+)
               and cd_sala.id_sala = elenco_circuiti.id_sala
        order by pa_cd_cinema.FU_GET_NOME_CINEMA(cd_cinema.id_cinema,p_data_fine),
                 nome_sala;
                 --,data_inizio;
                 
    RETURN C_SPETTATORI;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_SALA_SETTIMANA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_SPETT_SALA_SETTIMANA;

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_CIRCUITO_SETTIMANA
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               degli spettatori complessivi per circuito
--               all'interno di un intervallo di tempo specificato da parametri
--
-- OPERAZIONI:
--   1) Recupera la lista degli spettatori complessivi per circuito
--
-- INPUT:
--       p_data_inizio        data inizio,
--       p_data_fine          data fine,
--       p_id_cinema          identificativo del cinema,
--       p_id_sala             identificativo della sala,
--       p_id_comune           identificativo del comune,
--       p_id_regione          identificativo della regione ,
--       p_id_area_nielsen     identificativo dell'area nielsen
--
-- OUTPUT: lista degli spettatori effettivi spaccati per intervallo di tempo definito in input e circuito
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Aprile 2010
--
--  MODIFICHE: 
--         11/5/2010: Aggiunto conteggio sale, Angelo Marletta
--         20/05/2011: Antonio Colucci, Teoresi srl 
--                      Cambiata query di estrazione; la tabella di riferimento
--                      e diventata CD_FATTO_SPETTATORI (tavola denormalizzata)
--                      TEMPORANEAMENTE ALCUNI FILTRI DI RICERCA NON HANNO EFFETTO
-------------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_CIRCUITO_SETTIMANA(
                                p_data_inizio         DATE,
                                p_data_fine           DATE,
                                p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala             CD_SALA.ID_SALA%TYPE,
                                p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,  
                                p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                )RETURN C_SPETT_CIRCUITO
IS
C_SPETTATORI C_SPETT_CIRCUITO;
BEGIN
    OPEN C_SPETTATORI
    FOR
        select  distinct
                cd_circuito.nome_circuito,
                count(distinct id_cinema) over (partition by cd_fatto_spettatori.id_circuito) tot_cinema,
                count(distinct id_sala) over (partition by cd_fatto_spettatori.id_circuito) tot_sale,
                sum(spettatori_giorno) over (partition by cd_fatto_spettatori.id_circuito) tot_spettatori,
                NULL DATA_INIZIO, NULL DATA_FINE, 
                NULL DATA_RIF 
        from    
                cd_fatto_spettatori,
                cd_circuito
        where   data_riferimento between p_data_inizio and p_data_fine
        and     cd_fatto_spettatori.id_circuito = cd_circuito.id_circuito
        and     cd_fatto_spettatori.id_sala = nvl(p_id_sala,cd_fatto_spettatori.id_sala)
        and     cd_fatto_spettatori.id_cinema = nvl(p_id_cinema,cd_fatto_spettatori.id_cinema)
        order by nome_circuito;
        /*with sale_circuiti as
        (
        select distinct
                  cd_sala.id_sala,
                  cd_cinema.id_cinema,
                  cd_circuito.id_circuito
            from    
                    cd_cinema,
                    cd_sala,
                    cd_schermo,
                    cd_circuito,
                    cd_circuito_schermo
            where
                    cd_schermo.id_schermo = cd_circuito_schermo.id_schermo    
            and     cd_circuito_schermo.id_circuito = cd_circuito.ID_CIRCUITO
            and     cd_circuito_schermo.flg_annullato = 'N'
            and     cd_circuito.FLG_DEFINITO_A_LISTINO = 'S'
            and     cd_schermo.id_sala = cd_sala.id_sala
            and     cd_sala.flg_visibile = 'S'
            and     cd_sala.flg_arena = 'N'
            and     cd_sala.id_cinema = cd_cinema.id_cinema
            and     cd_cinema.flg_virtuale = 'N'
           )
        select distinct
               cd_circuito.NOME_CIRCUITO,
               count(distinct cd_sala.id_cinema) over (partition by cd_circuito.id_circuito) tot_cinema,
               count(distinct cd_sala.id_sala) over (partition by cd_circuito.id_circuito) tot_sale,
               sum(cd_spettatori_eff.num_spettatori) over (partition by cd_circuito.id_circuito)tot_spettatori ,
               NULL DATA_INIZIO, NULL DATA_FINE, 
               NULL DATA_RIF  
        from 
               cd_spettacolo,cd_cinema, 
               cd_sala, cd_comune,
               cd_regione, cd_area_nielsen, 
               cd_nielsen_regione, cd_provincia,
               cd_circuito, 
               cd_liquidazione_sala,
               sale_circuiti,
               cd_spettatori_eff
        where*/
               /*Filtri di Ricerca*/
               /*
                   cd_spettatori_eff.data_riferimento between p_data_inizio and p_data_fine
               and cd_comune.id_comune = nvl(p_id_comune,cd_comune.id_comune) 
               and cd_sala.id_sala = nvl(p_id_sala,cd_sala.id_sala)
               and cd_cinema.id_cinema = nvl(p_id_cinema,cd_cinema.id_cinema)
               and cd_regione.id_regione = nvl(p_id_regione,cd_regione.id_regione)
               and cd_area_nielsen.id_area_nielsen = nvl(p_id_area_nielsen,cd_area_nielsen.id_area_nielsen)
               and cd_cinema.id_tipo_cinema = nvl(p_id_tipo_cinema,cd_cinema.id_tipo_cinema)
               and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo)
               and cd_liquidazione_sala.flg_programmazione = nvl(p_flg_venduta,cd_liquidazione_sala.flg_programmazione)
               */
               /*Fine Filtri di Ricerca*/
               /*
               and cd_spettatori_eff.id_sala = sale_circuiti.id_sala
               and sale_circuiti.id_circuito = cd_circuito.id_circuito
               and sale_circuiti.id_sala = cd_sala.id_sala
               and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
               and cd_spettatori_eff.id_sala = cd_liquidazione_sala.id_sala (+) 
               and cd_spettatori_eff.data_riferimento = cd_liquidazione_sala.data_rif(+)
               and cd_sala.id_cinema = cd_cinema.id_cinema
               and cd_cinema.id_comune = cd_comune.id_comune
               and cd_comune.id_provincia = cd_provincia.id_provincia
               and cd_provincia.id_regione = cd_regione.id_regione
               and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
               and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
        order by cd_circuito.NOME_CIRCUITO;
        */
    RETURN C_SPETTATORI;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_CIRCUITO_SETTIMANA:'||sqlerrm);
END FU_SPETT_CIRCUITO_SETTIMANA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_ESERCENTE_SETTIMANA
--  Realizzatore Antonio Colucci Teoresi srl, Aprile 2010
--  
--  MODIFICHE:  Antonio Colucci, teoresi srl, 14/03/2011
--              Aggiunto filtro di data su ESER_CONTRATTO per ottenere un numero
--              corretto di spettatori spaccato anche per esercente in funzione 
--              del periodo di validita del contratto
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_ESERCENTE_SETTIMANA(
                                p_data_inizio         DATE,
                                p_data_fine           DATE,
                                p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala             CD_SALA.ID_SALA%TYPE,
                                p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,  
                                p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                )RETURN C_SPETT_ESERCENTE
IS
C_SPETTATORI C_SPETT_ESERCENTE;
BEGIN
    OPEN C_SPETTATORI
    FOR
        select distinct 
            vi_cd_societa_esercente.ragione_sociale,
            count(distinct cd_cinema.id_cinema) over (partition by vi_cd_societa_esercente.ragione_sociale) tot_cinema, 
            count(distinct cd_sala.id_sala) over (partition by vi_cd_societa_esercente.ragione_sociale) tot_sale,
            sum(cd_spettatori_eff.num_spettatori) over (partition by vi_cd_societa_esercente.ragione_sociale) tot_spettatori,
            NULL DATA_INIZIO, NULL DATA_FINE, 
            NULL DATA_RIF  
        from 
           cd_sala,cd_cinema,cd_cinema_contratto,
           cd_contratto,cd_eser_contratto,vi_cd_societa_esercente,
           cd_spettatori_eff,
           cd_comune,
           cd_regione, cd_area_nielsen, 
           cd_nielsen_regione, cd_provincia,
           cd_spettacolo,cd_liquidazione_sala
        where
           /*Filtri di Ricerca*/
           trunc(cd_spettatori_eff.data_riferimento) between p_data_inizio and p_data_fine
           and (p_id_comune is null or cd_comune.id_comune = p_id_comune)
           and (p_id_sala is null or cd_sala.id_sala = p_id_sala)
           and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
           and (p_id_regione is null or cd_regione.id_regione = p_id_regione)
           and (p_id_area_nielsen is null or cd_area_nielsen.id_area_nielsen = p_id_area_nielsen)
           and (p_id_tipo_cinema is null or cd_cinema.id_tipo_cinema = p_id_tipo_cinema)
           and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo)
           and (p_flg_venduta is null or cd_liquidazione_sala.flg_programmazione = p_flg_venduta)
           /*Fine Filtri di Ricerca*/
           and cd_cinema.id_cinema=cd_cinema_contratto.id_cinema
           and cd_sala.id_cinema=cd_cinema.id_cinema
           and cd_cinema_contratto.id_contratto=cd_contratto.id_contratto
           and cd_contratto.id_contratto=cd_eser_contratto.id_contratto
           and cd_eser_contratto.COD_ESERCENTE=vi_cd_societa_esercente.COD_ESERCENTE
           and cd_spettatori_eff.data_riferimento between cd_eser_contratto.DATA_INIZIO and cd_eser_contratto.DATA_FINE
           and cd_sala.id_sala=cd_spettatori_eff.id_sala
           and cd_cinema.id_comune = cd_comune.id_comune
           and cd_comune.id_provincia = cd_provincia.id_provincia
           and cd_provincia.id_regione = cd_regione.id_regione
           and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
           and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
           and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
           and cd_spettatori_eff.id_sala = cd_liquidazione_sala.id_sala (+) 
               and cd_spettatori_eff.data_riferimento = cd_liquidazione_sala.data_rif(+)
        order by
            vi_cd_societa_esercente.ragione_sociale;
    RETURN C_SPETTATORI;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_ESERCENTE_SETTIMANA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_SPETT_ESERCENTE_SETTIMANA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_NIELSEN_SETTIMANA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_NIELSEN_SETTIMANA(
                                p_data_inizio         DATE,
                                p_data_fine           DATE,
                                p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala             CD_SALA.ID_SALA%TYPE,
                                p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,  
                                p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                )RETURN C_SPETT_NIELSEN
IS
C_SPETTATORI C_SPETT_NIELSEN;
BEGIN
    OPEN C_SPETTATORI
    FOR
        select 
           cd_area_nielsen.DESC_AREA area_nielsen,
           count(distinct cd_sala.id_cinema) tot_cinema,
           count(distinct cd_sala.id_sala) tot_sale,
           sum(cd_spettatori_eff.num_spettatori)tot_spettatori,
           NULL DATA_INIZIO, NULL DATA_FINE, 
           NULL DATA_RIF  
        from 
           cd_spettatori_eff, --periodi,
           cd_cinema, cd_sala, cd_comune,
           cd_regione, cd_area_nielsen, 
           cd_nielsen_regione, cd_provincia,
           cd_spettacolo,cd_liquidazione_sala
        where
           /*Filtri di Ricerca*/
           trunc(cd_spettatori_eff.data_riferimento) between p_data_inizio and p_data_fine
           and (p_id_comune is null or cd_comune.id_comune = p_id_comune)
           and (p_id_sala is null or cd_sala.id_sala = p_id_sala)
           and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
           and (p_id_regione is null or cd_regione.id_regione = p_id_regione)
           and (p_id_area_nielsen is null or cd_area_nielsen.id_area_nielsen = p_id_area_nielsen)
           and (p_id_tipo_cinema is null or cd_cinema.id_tipo_cinema = p_id_tipo_cinema)
           and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo)
           and (p_flg_venduta is null or cd_liquidazione_sala.flg_programmazione = p_flg_venduta)
           /*Fine Filtri di Ricerca*/
           and cd_sala.id_sala = cd_spettatori_eff.id_sala
           and cd_sala.id_cinema = cd_cinema.id_cinema
           and cd_cinema.id_comune = cd_comune.id_comune
           and cd_comune.id_provincia = cd_provincia.id_provincia
           and cd_provincia.id_regione = cd_regione.id_regione
           and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
           and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
           and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
           and cd_spettatori_eff.id_sala = cd_liquidazione_sala.id_sala (+) 
               and cd_spettatori_eff.data_riferimento = cd_liquidazione_sala.data_rif(+)
        group by
           cd_area_nielsen.DESC_AREA
        order by cd_area_nielsen.DESC_AREA;
    RETURN C_SPETTATORI;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_NIELSEN_SETTIMANA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_SPETT_NIELSEN_SETTIMANA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_FILM_SETTIMANA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_FILM_SETTIMANA(
                                p_data_inizio         DATE,
                                p_data_fine           DATE,
                                p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala             CD_SALA.ID_SALA%TYPE,
                                p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,  
                                p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                )RETURN C_SPETT_FILM
IS
C_SPETTATORI C_SPETT_FILM;
BEGIN
    OPEN C_SPETTATORI
    FOR
        select distinct
            nome_spettacolo,
            DESC_GENERE,
            vencd.FU_CD_STRING_AGG(nome_target) over (partition by elenco.id_spettacolo) target,
            tot_cinema,
            tot_sale,
            tot_spettatori,
            data_inizio,
            data_fine
        from    
        (
        select distinct
           cd_spettatori_eff.id_spettacolo,
           cd_spettacolo.nome_spettacolo,
           cd_genere.DESC_GENERE,
           --vencd.FU_CD_STRING_AGG(distinct cd_target.descr_target) over (partition by cd_spett_target.id_spettacolo) target,
           count(distinct cd_sala.id_cinema) over (partition by cd_spettatori_eff.id_spettacolo)tot_cinema,
           count(distinct cd_sala.id_sala)over (partition by cd_spettatori_eff.id_spettacolo) tot_sale,
           sum(cd_spettatori_eff.num_spettatori)over (partition by cd_spettatori_eff.id_spettacolo)tot_spettatori,
           min(data_riferimento) over (partition by cd_spettatori_eff.id_spettacolo) data_inizio,   
           max(data_riferimento) over (partition by cd_spettatori_eff.id_spettacolo)data_fine
        from 
           cd_spettatori_eff,
           cd_cinema, cd_sala, cd_comune,
           cd_regione, cd_area_nielsen, 
           cd_nielsen_regione, cd_provincia,
           cd_spettacolo,cd_liquidazione_sala,
           cd_genere
        where
           /*Filtri di Ricerca*/
           trunc(cd_spettatori_eff.data_riferimento) between p_data_inizio and p_data_fine
           and (p_id_comune is null or cd_comune.id_comune = p_id_comune)
           and (p_id_sala is null or cd_sala.id_sala = p_id_sala)
           and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
           and (p_id_regione is null or cd_regione.id_regione = p_id_regione)
           and (p_id_area_nielsen is null or cd_area_nielsen.id_area_nielsen = p_id_area_nielsen)
           and (p_id_tipo_cinema is null or cd_cinema.id_tipo_cinema = p_id_tipo_cinema)
           and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo )
           and (p_flg_venduta is null or cd_liquidazione_sala.flg_programmazione = p_flg_venduta)
           /*Fine Filtri di Ricerca*/
           and cd_sala.id_sala = cd_spettatori_eff.id_sala
           and cd_sala.id_cinema = cd_cinema.id_cinema
           and cd_cinema.id_comune = cd_comune.id_comune
           and cd_comune.id_provincia = cd_provincia.id_provincia
           and cd_provincia.id_regione = cd_regione.id_regione
           and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
           and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
           and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
           and cd_spettatori_eff.id_sala = cd_liquidazione_sala.id_sala (+) 
           and cd_spettatori_eff.data_riferimento = cd_liquidazione_sala.data_rif(+)
           and cd_spettacolo.id_genere = cd_genere.id_genere(+)
        )elenco,cd_target,cd_spett_target
        where   elenco.id_spettacolo = cd_spett_target.id_spettacolo(+)
        and     cd_spett_target.id_target = cd_target.id_target(+) 
        order by nome_spettacolo;
    RETURN C_SPETTATORI;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_FILM_SETTIMANA: SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_SPETT_FILM_SETTIMANA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_GENERE_SETTIMANA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_GENERE_SETTIMANA(
                                p_data_inizio         DATE,
                                p_data_fine           DATE,
                                p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala             CD_SALA.ID_SALA%TYPE,
                                p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,  
                                p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                )RETURN C_SPETT_GENERE
IS
C_SPETTATORI C_SPETT_GENERE;
BEGIN
    OPEN C_SPETTATORI
    FOR
        select distinct
           cd_genere.DESC_GENERE,
           count(distinct cd_sala.id_cinema) over (partition by cd_spettacolo.id_genere)tot_cinema,
           count(distinct cd_sala.id_sala)over (partition by cd_spettacolo.id_genere) tot_sale,
           sum(cd_spettatori_eff.num_spettatori)over (partition by cd_spettacolo.id_genere)tot_spettatori,
           min(data_riferimento) over (partition by cd_spettacolo.id_genere) data_inizio,   
           max(data_riferimento) over (partition by cd_spettacolo.id_genere)data_fine
        from 
           cd_spettatori_eff,
           cd_cinema, cd_sala, cd_comune,
           cd_regione, cd_area_nielsen, 
           cd_nielsen_regione, cd_provincia,
           cd_spettacolo,cd_liquidazione_sala,
           cd_genere
           ,cd_target,cd_spett_target
        where
           /*Filtri di Ricerca*/
           trunc(cd_spettatori_eff.data_riferimento) between p_data_inizio and p_data_fine
           and (p_id_comune is null or cd_comune.id_comune = p_id_comune)
           and (p_id_sala is null or cd_sala.id_sala = p_id_sala)
           and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
           and (p_id_regione is null or cd_regione.id_regione = p_id_regione)
           and (p_id_area_nielsen is null or cd_area_nielsen.id_area_nielsen = p_id_area_nielsen)
           and (p_id_tipo_cinema is null or cd_cinema.id_tipo_cinema = p_id_tipo_cinema)
           and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo )
           and (p_flg_venduta is null or cd_liquidazione_sala.flg_programmazione = p_flg_venduta)
           /*Fine Filtri di Ricerca*/
           and cd_sala.id_sala = cd_spettatori_eff.id_sala
           and cd_sala.id_cinema = cd_cinema.id_cinema
           and cd_cinema.id_comune = cd_comune.id_comune
           and cd_comune.id_provincia = cd_provincia.id_provincia
           and cd_provincia.id_regione = cd_regione.id_regione
           and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
           and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
           and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
           and cd_spettatori_eff.id_sala = cd_liquidazione_sala.id_sala (+) 
           and cd_spettatori_eff.data_riferimento = cd_liquidazione_sala.data_rif(+)
           and cd_spettacolo.id_genere = cd_genere.id_genere(+)
           and cd_spettacolo.id_spettacolo = cd_spett_target.id_spettacolo(+)
           and cd_spett_target.id_target = cd_target.id_target(+) 
           order by DESC_GENERE;
    RETURN C_SPETTATORI;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_GENERE_SETTIMANA: SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_SPETT_GENERE_SETTIMANA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_TIPOCINEMA_SETTIMANA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_TIPOCINEMA_SETTIMANA(
                                p_data_inizio         DATE,
                                p_data_fine           DATE,
                                p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala             CD_SALA.ID_SALA%TYPE,
                                p_id_comune           CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,  
                                p_id_tipo_cinema      CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_spettacolo       CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_flg_venduta         CD_LIQUIDAZIONE_SALA.FLG_PROGRAMMAZIONE%TYPE
                                )RETURN C_SPETT_TIPOCINEMA
IS
C_SPETTATORI C_SPETT_TIPOCINEMA;
BEGIN
    OPEN C_SPETTATORI
    FOR
        select 
           cd_tipo_cinema.DESC_TIPO_CINEMA tipo_cinema,
           count(distinct cd_sala.id_cinema) tot_cinema,
           count(distinct cd_sala.id_sala) tot_sale,
           sum(cd_spettatori_eff.num_spettatori)tot_spettatori,
           NULL DATA_INIZIO, NULL DATA_FINE, 
           NULL DATA_RIF  
        from 
           cd_spettatori_eff, --periodi,
           cd_cinema, cd_sala, cd_comune,
           cd_regione, cd_area_nielsen, 
           cd_nielsen_regione, cd_provincia,
           cd_tipo_cinema, cd_spettacolo
        where
           /*Filtri di Ricerca*/
           trunc(cd_spettatori_eff.data_riferimento) between p_data_inizio and p_data_fine
           and (p_id_comune is null or cd_comune.id_comune = p_id_comune)
           and (p_id_sala is null or cd_sala.id_sala = p_id_sala)
           and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
           and (p_id_regione is null or cd_regione.id_regione = p_id_regione)
           and (p_id_area_nielsen is null or cd_area_nielsen.id_area_nielsen = p_id_area_nielsen)
           and (p_id_tipo_cinema is null or cd_cinema.id_tipo_cinema = p_id_tipo_cinema)
           and (p_id_spettacolo is null or cd_spettacolo.id_spettacolo = p_id_spettacolo)
           /*Fine Filtri di Ricerca*/
           and cd_sala.id_sala = cd_spettatori_eff.id_sala
           and cd_sala.id_cinema = cd_cinema.id_cinema
           and cd_cinema.id_comune = cd_comune.id_comune
           and cd_comune.id_provincia = cd_provincia.id_provincia
           and cd_provincia.id_regione = cd_regione.id_regione
           and cd_nielsen_regione.ID_REGIONE = cd_regione.id_regione
           and cd_nielsen_regione.ID_AREA_NIELSEN = cd_area_nielsen.ID_AREA_NIELSEN
           and cd_cinema.id_tipo_cinema = cd_tipo_cinema.id_tipo_cinema
           and cd_spettatori_eff.ID_SPETTACOLO = cd_spettacolo.ID_SPETTACOLO(+)
        group by
            cd_tipo_cinema.DESC_TIPO_CINEMA
        order by cd_tipo_cinema.DESC_TIPO_CINEMA;
    RETURN C_SPETTATORI;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SPETT_TIPOCINEMA_SETTIMANA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_SPETT_TIPOCINEMA_SETTIMANA;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_PRO_SALA_LIQUIDAZIONE
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               delle sale-giorno con l'indicazione
--               sulla effettiva trasmissione dei comunicati
--
-- OPERAZIONI:
--   1) Recupera la lista delle sale per ogni giorno di programmazione
--
-- INPUT:
--      p_data_inizio          data inizio di riferimento
--      p_data_fine            data fine di riferimento,
--      p_id_cinema            indicativo del cinema,
--      p_id_sala              indicativo del sala,
--      p_flg_proiezione       indicazione sulla messa in onda del comunicato,
--      p_responsabilita       indicazione sul tipo di responsabilita da ricercare
--
-- OUTPUT: lista richiesta
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Marzo 2010
--
--  MODIFICHE:
--  Mauro Viel Altran Italia Ottobre 2010 sostuita la vista cd_spettatori_eff perche restituiva righe duplicate.
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_PRO_SALA_LIQUIDAZIONE(  p_data_inizio         DATE,
                                        p_data_fine           DATE,
                                        p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                        p_id_sala             CD_SALA.ID_SALA%TYPE,
                                        p_flg_proiezione      VARCHAR2,
                                        p_responsabilita      NUMBER,
                                        p_id_codice_resp      cd_codice_resp.ID_CODICE_RESP%TYPE,
                                        p_decurtazione        VARCHAR2,
                                        p_num_spettatori      number,
                                        p_id_cinetel          cd_causale_cinetel.id_cinetel%TYPE
                                      )  RETURN C_PRO_SALA_LIQUIDAZ
IS
C_ELENCO C_PRO_SALA_LIQUIDAZ;
BEGIN
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data_inizio, p_data_fine);
    OPEN C_ELENCO
    FOR
       select distinct cd_liquidazione_sala.id_sala,cd_cinema.id_cinema,
               cd_cinema.nome_cinema,  
               cd_sala.nome_sala,cd_comune.comune,
               --sum(num_spettatori) over (partition by cd_spettatori_eff.id_sala,cd_spettatori_eff.data_riferimento) tot_spettatori ,
               vi_cd_spettatori_eff.num_spettatori tot_spettatori,
               cd_liquidazione_sala.DATA_RIF,
               cd_liquidazione_sala.FLG_PROIEZIONE_PUBB,cd_liquidazione_sala.id_codice_resp,
               cd_codice_resp.DESC_CODICE cod_resp,cd_liquidazione_sala.MOTIVAZIONE,
               cd_liquidazione_sala.FLG_PROGRAMMAZIONE,
               decode(cd_codice_resp.AGGREGAZIONE,'RS','NO','SI') decurtazione
               ,desc_cinetel,VI_CD_SALE_CAUSALI_PREV.id_codice_resp id_causale_prev
        from   cd_cinema,cd_sala,
               cd_comune,cd_liquidazione_sala,
               cd_codice_resp,
                   (select cd_spettatori_eff.id_sala id_sala,cd_spettatori_eff.data_riferimento data_riferimento, sum(num_spettatori) num_spettatori,
                    max(id_cinetel) id_cinetel
                    from  cd_spettatori_eff, cd_liquidazione_sala sa
                    where cd_spettatori_eff.id_sala=sa.id_sala
                    and   cd_spettatori_eff.data_riferimento = sa.DATA_RIF
                    and   cd_spettatori_eff.data_riferimento between p_data_inizio and p_data_fine
                    and   cd_spettatori_eff.id_sala = nvl (p_id_sala, cd_spettatori_eff.id_sala)
                    group by cd_spettatori_eff.id_sala,cd_spettatori_eff.data_riferimento
                    ) vi_cd_spettatori_eff,
                cd_causale_cinetel,VI_CD_SALE_CAUSALI_PREV
        /*Filtri*/
        where  (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
          and  (p_id_sala is null or cd_sala.id_sala = p_id_sala)
          and  cd_liquidazione_sala.DATA_RIF between p_data_inizio and p_data_fine
          and  (p_flg_proiezione = 'Tutti' or  cd_liquidazione_sala.flg_proiezione_pubb = p_flg_proiezione)
          and  (p_responsabilita = -1 or (decode(cd_liquidazione_sala.id_codice_resp,5,5,0) = decode(p_responsabilita,5,5,0)))
          and  (p_id_codice_resp = -100 or cd_liquidazione_sala.id_codice_resp = p_id_codice_resp) 
          and  (p_decurtazione is null or cd_codice_resp.AGGREGAZIONE = p_decurtazione)
          and  (p_id_cinetel is null or vi_cd_spettatori_eff.id_cinetel = p_id_cinetel)
          /*
            num_spettatori = null
            num_spettatori = 0 ==> p_num_spettatori = 1
            num_spettatori > 0 ==> p_num_spettatori = 2
           */
          and  (p_num_spettatori = -100 or p_num_spettatori = decode(nvl(vi_cd_spettatori_eff.num_spettatori,0),0,1,2)  )
          /*Join*/
          and  cd_liquidazione_sala.id_sala = cd_sala.id_sala
          and  cd_sala.id_cinema = cd_cinema.id_cinema
          and  cd_cinema.id_comune = cd_comune.id_comune 
          and  cd_liquidazione_sala.id_codice_resp = cd_codice_resp.id_codice_resp(+)
          and  cd_liquidazione_sala.id_sala = vi_cd_spettatori_eff.id_sala(+)
          and  cd_liquidazione_sala.data_rif = vi_cd_spettatori_eff.data_riferimento(+)
          and  vi_cd_spettatori_eff.id_cinetel = cd_causale_cinetel.id_cinetel(+)
          and  VI_CD_SALE_CAUSALI_PREV.id_sala = cd_liquidazione_sala.id_sala
          and  VI_CD_SALE_CAUSALI_PREV.data_RIF = cd_liquidazione_sala.data_rif
          order by nome_cinema,comune,nome_sala,DATA_RIF;
    RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_GET_PRO_SALA_LIQUIDAZIONE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_GET_PRO_SALA_LIQUIDAZIONE;



--
---------------------------------------------------------------------------------------------------
-- PROCEDURE PR_MODIFICA_PRO_SALA_LIQUID
--
-- DESCRIZIONE:  Procedura che si occupa di aggiornare i dati della tabella CD_LIQUIDAZIONE_SALA
--
-- OPERAZIONI:
--   1) Esegue l'update del record individuato dalla chiave DataRif-IdSala 
--
-- INPUT:   p_id_sala               identificativo della sala (PK)
--          p_data_rif              data di riferimento (PK)
--          p_id_codice_resp        identificativo della reposnsabilita dello stato della proiezione di sala
--          p_motivazione           motivzione inserita dall'utente
--          p_esito
--
-- OUTPUT: esito dell'operazione
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 17 Marzo 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------

PROCEDURE PR_IMPOSTA_CAUSALE_DEF(  p_id_sala               cd_liquidazione_sala.ID_SALA%TYPE,
                                   p_data_rif              cd_liquidazione_sala.DATA_RIF%TYPE,
                                   p_id_codice_resp        cd_liquidazione_sala.id_codice_resp%type,
                                   p_motivazione           cd_liquidazione_sala.motivazione%type,
                                   p_esito OUT NUMBER)
IS
v_disponibilita     number;
--
BEGIN 
--
    SAVEPOINT SP_IMPOSTA_CAUSALE_DEF;
    P_ESITO     := 1;
    /*
      Eseguo update secco sulla tavola cd_liquidazione_sala
      solo per quelle proiezioni non andate in onda
    */
    v_disponibilita := pa_cd_esercente.FU_DISP_FERIE_CONSUNTIVO(p_id_sala,p_id_codice_resp);
    if(v_disponibilita>0)then
        UPDATE CD_LIQUIDAZIONE_SALA
        SET 
        ID_CODICE_RESP = P_ID_CODICE_RESP,
        MOTIVAZIONE = P_MOTIVAZIONE
        WHERE ID_SALA = P_ID_SALA
        AND   DATA_RIF = P_DATA_RIF;
    else
        p_esito := -4;
    end if;
    --
  EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -3;
        RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_IMPOSTA_CAUSALE_DEF: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:'||SQLERRM);
        ROLLBACK TO SP_IMPOSTA_CAUSALE_DEF;
--
END PR_IMPOSTA_CAUSALE_DEF;

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CODICI_RESP
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               dei codici di reponsabilita disponibili
--
-- OPERAZIONI:
--   1) recupera la lista dei codici di reponsabilita disponibili
--
-- INPUT:
--
-- OUTPUT: lista dei codici di reponsabilita disponibili
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Marzo 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_CODICI_RESP RETURN C_CODICE_RESP
IS
C_ELENCO C_CODICE_RESP;
BEGIN
    OPEN C_ELENCO FOR
        SELECT ID_CODICE_RESP, DESC_CODICE, PROBLEMATICA, AGGREGAZIONE FROM CD_CODICE_RESP where flg_annullato ='N'
        order by desc_codice;        
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_GET_CODICI_RESP: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_GET_CODICI_RESP;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALI_AMMINISTRATIVE
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               dei codici di causali amministrative valide
--
-- OPERAZIONI:
--   1) recupera la lista dei codici di reponsabilita disponibili
--
-- INPUT:
--
-- OUTPUT: lista dei codici di reponsabilita disponibili
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Settembre 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------FUNCTION FU_GET_CAUSALI_TECNICHE RETURN C_CODICE_RESP;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALI_AMMINISTRATIVE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALI_AMMINISTRATIVE RETURN C_CODICE_RESP
IS
C_ELENCO C_CODICE_RESP;
BEGIN
    OPEN C_ELENCO FOR
        SELECT ID_CODICE_RESP, DESC_CODICE, PROBLEMATICA, AGGREGAZIONE 
        FROM CD_CODICE_RESP 
        where flg_annullato ='N'
        and upper(problematica) like '%INDISPONIBILE%'
        order by desc_codice;        
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_GET_CAUSALI_AMMINISTRATIVE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_GET_CAUSALI_AMMINISTRATIVE;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALI_TECNICHE
--
-- DESCRIZIONE:  Funzione che permette di recuperare la lista
--               dei codici di causali TECNICHE valide
--
-- OPERAZIONI:
--   1) recupera la lista dei codici di reponsabilita disponibili
--
-- INPUT:
--
-- OUTPUT: lista dei codici di reponsabilita disponibili
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Settembre 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------FUNCTION FU_GET_CAUSALI_TECNICHE RETURN C_CODICE_RESP;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALI_TECNICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALI_TECNICHE RETURN C_CODICE_RESP
IS
C_ELENCO C_CODICE_RESP;
BEGIN
    OPEN C_ELENCO FOR
        SELECT ID_CODICE_RESP, DESC_CODICE, PROBLEMATICA, AGGREGAZIONE 
        FROM CD_CODICE_RESP 
        where flg_annullato ='N'
        and upper(problematica) like '%PROBLEMA TECNICO%'
        order by desc_codice;        
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_GET_CAUSALI_TECNICHE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:');
END FU_GET_CAUSALI_TECNICHE;
-----------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALI_CINETEL
-- --------------------------------------------------------------------------------------------
--
-- DESCRIZIONE:  Restituisce l'elenco delle causali cinetel disponibili a sistema
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, 14/07/2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALI_CINETEL RETURN C_CAUSALE_CINETEL
IS
C_ELENCO C_CAUSALE_CINETEL;
BEGIN
    OPEN C_ELENCO
    FOR
        select distinct id_cinetel, desc_cinetel
        from cd_causale_cinetel;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_GET_CAUSALI_CINETEL: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:'||sqlerrm);
END FU_GET_CAUSALI_CINETEL;    
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_CONFRONTO_SPETT_SALA
--
-- DESCRIZIONE:  Funzione che permette di recuperare il confronto annuo degli spettatori
--               spaccato per sala
--               E' FONDAMENTALE MANTENERE L'ORDINAMENTO IMPOSTATO
--               IN MODO DA POTER COSTRUIRE IN MANIERA OPPORTUNA 
--               LA STRUTTURA DA VISUALIZZARE
--
--
-- INPUT:
--  p_id_cinema     identificativo del cinema
--  p_id_sala       identificativo della sala
--  p_data_inizio   data inizio della ricerca
--  p_data_fine     data fine ricerca
--
-- OUTPUT: lista delle sale con indicazione degli spettatori
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Gennaio 2011
--
--  MODIFICHE: 
FUNCTION FU_CONFRONTO_SPETT_SALA(  p_id_circuito        CD_CIRCUITO.id_CIRCUITO%TYPE,
                                   p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                   p_id_sala            CD_SALA.ID_SALA%TYPE,
                                   p_data_inizio        DATE,
                                   p_data_fine          DATE
                                ) return C_CONFRONTO_SALA
IS
C_ELENCO C_CONFRONTO_SALA;
BEGIN
    OPEN C_ELENCO
    FOR
        select distinct
            id_cinema,
            id_sala,
            nome_cinema||'-'||comune cinema,
            nome_sala,
            mese,
            --VENCD.fu_cd_string_agg(anno) over (partition by id_sala,mese) periodo,
            VENCD.fu_cd_string_agg(spettatori_anno)over (partition by id_sala,mese) spettatori
        from
        (
        with sale_spett as
            (
            select distinct id_sala,id_cinema,data_riferimento,spettatori_giorno
            from cd_fatto_spettatori
            where data_riferimento between p_data_inizio and p_data_fine
            and (p_id_circuito is null or cd_fatto_spettatori.id_circuito = p_id_circuito)
            )
        select 
                distinct
                sale_spett.id_cinema,
                sale_spett.id_sala,
                cd_cinema.nome_cinema,
                comune,
                cd_sala.nome_sala,
                to_char(data_riferimento,'MM') mese,
                --VENCD.fu_cd_string_agg( distinct to_char(data_riferimento,'MM-YYYY')) over (partition by sale_spett.id_sala) mese_anno,
                /*
                to_char(data_riferimento,'YYYY') anno,
                sum(spettatori_giorno) over (partition by sale_spett.id_sala,to_char(data_riferimento,'MM-YYYY')) spettatori
                */
                to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by sale_spett.id_sala,to_char(data_riferimento,'MM-YYYY')) spettatori_anno
        from
                sale_spett,
                cd_sala,
                cd_cinema,
                cd_comune
        where
                sale_spett.id_sala = cd_sala.id_sala
        and     cd_sala.id_cinema = cd_cinema.id_cinema
        and     sale_spett.data_riferimento between p_data_inizio and p_data_fine
        and     cd_cinema.id_comune = cd_comune.id_comune
        and     (p_id_sala is null or sale_spett.id_sala = p_id_sala)
        and     (p_id_cinema is null or sale_spett.id_cinema = p_id_cinema)
        order by sale_spett.id_sala,mese,spettatori_anno
        )
        order by cinema,id_sala,mese;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CONFRONTO_SPETT_SALA - SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_CONFRONTO_SPETT_SALA;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_CONFRONTO_SPETT_CINEMA
--
-- DESCRIZIONE:  Funzione che permette di recuperare il confronto annuo degli spettatori
--               spaccato per cinema
--               E' FONDAMENTALE MANTENERE L'ORDINAMENTO IMPOSTATO
--               IN MODO DA POTER COSTRUIRE IN MANIERA OPPORTUNA 
--               LA STRUTTURA DA VISUALIZZARE
--
--
-- INPUT:
--  p_id_cinema     identificativo del cinema
--  p_data_inizio   data inizio della ricerca
--  p_data_fine     data fine ricerca
--
-- OUTPUT: lista dei cinema con indicazione degli spettatori
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Febbraio 2011
--
--  MODIFICHE: 
FUNCTION FU_CONFRONTO_SPETT_CINEMA(    p_id_circuito        CD_CIRCUITO.id_CIRCUITO%TYPE,
                                       p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                       p_data_inizio        DATE,
                                       p_data_fine          DATE
                                    )return C_CONFRONTO_CINEMA
IS
C_ELENCO C_CONFRONTO_CINEMA;
BEGIN
    OPEN C_ELENCO
    FOR
        select distinct
            id_cinema,
            nome_cinema||'-'||comune cinema,
            mese,
            VENCD.fu_cd_string_agg(spettatori_anno) over (partition by id_cinema,mese) SPETTATORI
        from
        (
        with sale_spett as
            (
            select distinct id_cinema,data_riferimento,
                sum(spettatori_giorno) over (partition by id_cinema,data_riferimento) spettatori_giorno
                from
                (
                    select distinct id_sala,id_cinema,spettatori_giorno,data_riferimento
                    from cd_fatto_spettatori
                    where data_riferimento between p_data_inizio and p_data_fine
                    and (p_id_circuito is null or cd_fatto_spettatori.id_circuito = p_id_circuito)
                )
            )
        select 
                distinct
                sale_spett.id_cinema,
                cd_cinema.nome_cinema,
                comune,
                to_char(data_riferimento,'MM') mese,
                --VENCD.fu_cd_string_agg( distinct to_char(data_riferimento,'MM-YYYY')) over (partition by sale_spett.id_sala) mese_anno,
                to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by sale_spett.id_cinema,to_char(data_riferimento,'MM-YYYY')) spettatori_anno
        from
                sale_spett,
                cd_cinema,
                cd_comune
        where
                sale_spett.id_cinema = cd_cinema.id_cinema
        and     sale_spett.data_riferimento between p_data_inizio and p_data_fine
        and     cd_cinema.id_comune = cd_comune.id_comune
        and     (p_id_cinema is null or sale_spett.id_cinema = p_id_cinema)
        order by sale_spett.id_cinema,mese,spettatori_anno
        )order by cinema,mese;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CONFRONTO_SPETT_CINEMA - SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_CONFRONTO_SPETT_CINEMA;                           
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_CONFRONTO_SPETT_CIRCUITO
--
-- DESCRIZIONE:  Funzione che permette di recuperare il confronto annuo degli spettatori
--               spaccato per circuito
--               E' FONDAMENTALE MANTENERE L'ORDINAMENTO IMPOSTATO
--               IN MODO DA POTER COSTRUIRE IN MANIERA OPPORTUNA 
--               LA STRUTTURA DA VISUALIZZARE
--
--
-- INPUT:
--  p_id_circuito   identificativo del cinema
--  p_data_inizio   data inizio della ricerca
--  p_data_fine     data fine ricerca
--
-- OUTPUT: lista dei cinema con indicazione degli spettatori
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Febbraio 2011
--
--  MODIFICHE: 
FUNCTION FU_CONFRONTO_SPETT_CIRCUITO(  p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_data_inizio        DATE,
                                       p_data_fine          DATE
                                    ) return C_CONFRONTO_CIRCUITO
IS
C_ELENCO C_CONFRONTO_CIRCUITO;
BEGIN
    OPEN C_ELENCO
    FOR
         select distinct
        circuito_spett.id_circuito,
        cd_circuito.nome_circuito,
        mese,
        VENCD.fu_cd_string_agg(spettatori_anno) over (partition by circuito_spett.id_circuito,mese) SPETTATORI
    from
    (
        select distinct id_circuito,--data_riferimento,
            to_char(data_riferimento,'MM') mese,
            to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by id_circuito,to_char(data_riferimento,'MM-YYYY')) spettatori_anno 
        from cd_fatto_spettatori
        where data_riferimento between p_data_inizio and p_data_fine
    )circuito_spett,
    cd_circuito
    where 
        cd_circuito.id_circuito = circuito_spett.id_circuito
        and (p_id_circuito is null or circuito_spett.id_circuito = p_id_circuito)
    order by nome_circuito,mese;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CONFRONTO_SPETT_CIRCUITO - SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_CONFRONTO_SPETT_CIRCUITO;
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_CONFRONTO_SPETT_ESERCENTE
--
-- DESCRIZIONE:  Funzione che permette di recuperare il confronto annuo degli spettatori
--               spaccato per esercente
--               E' FONDAMENTALE MANTENERE L'ORDINAMENTO IMPOSTATO
--               IN MODO DA POTER COSTRUIRE IN MANIERA OPPORTUNA 
--               LA STRUTTURA DA VISUALIZZARE
--
--
-- INPUT:
--  p_id_cinema     identificativo del cinema
--  p_id_sala       identificativo della sala
--  p_id_circuito   identificativo del circuito
--  p_data_inizio   data inizio della ricerca
--  p_data_fine     data fine ricerca
--
-- OUTPUT: lista dei cinema con indicazione degli spettatori
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Aprile 2011
--
--  MODIFICHE: 
FUNCTION FU_CONFRONTO_SPETT_ESERCENTE(  p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                        p_id_sala            CD_SALA.ID_SALA%TYPE,
                                        p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_data_inizio        DATE,
                                        p_data_fine          DATE
                                      ) return C_CONFRONTO_ESERCENTE
IS
C_ELENCO C_CONFRONTO_ESERCENTE;
BEGIN
    OPEN C_ELENCO
    FOR
         select distinct
            COD_ESERCENTE,
            RAGIONE_SOCIALE,
            mese,
            VENCD.fu_cd_string_agg(spettatori_anno)over (partition by COD_ESERCENTE,mese) spettatori
        from
        (with cinema_spett as
            (
            select distinct id_cinema,data_riferimento,
                sum(spettatori_giorno) over (partition by id_cinema,data_riferimento) spettatori_giorno
                from
                (
                    select distinct id_sala,id_cinema,spettatori_giorno,data_riferimento
                    from    cd_fatto_spettatori
                    where   data_riferimento between p_data_inizio and p_data_fine
                    and     cd_fatto_spettatori.id_circuito = nvl(p_id_circuito,cd_fatto_spettatori.id_circuito)
                    and     cd_fatto_spettatori.id_sala = nvl(p_id_sala,cd_fatto_spettatori.id_sala)
                    and     cd_fatto_spettatori.id_cinema = nvl(p_id_cinema,cd_fatto_spettatori.id_cinema)
                )
            )
        select  distinct
                vi_cd_societa_esercente.RAGIONE_SOCIALE,
                cd_eser_contratto.COD_ESERCENTE,
                to_char(cinema_spett.data_riferimento,'MM') mese, 
                to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by cd_eser_contratto.COD_ESERCENTE,to_char(data_riferimento,'MM-YYYY')) spettatori_anno
        from    vi_cd_societa_esercente,
                cd_eser_contratto,
                cd_contratto,
                cd_cinema_contratto,
                cinema_spett
        where   
                cinema_spett.id_cinema = cd_cinema_contratto.id_cinema
        and     cd_cinema_contratto.id_contratto = cd_contratto.id_contratto
        and     cd_eser_contratto.ID_CONTRATTO = cd_contratto.id_contratto
        and     cd_eser_contratto.DATA_INIZIO <= cinema_spett.data_riferimento
        and     (cd_eser_contratto.DATA_FINE is null or cd_eser_contratto.DATA_FINE>=cinema_spett.data_riferimento)
        and     cd_eser_contratto.cod_esercente = vi_cd_societa_esercente.COD_ESERCENTE
        order by cd_eser_contratto.COD_ESERCENTE,mese,spettatori_anno
        )
        order by ragione_sociale,COD_ESERCENTE,mese;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CONFRONTO_SPETT_ESERCENTE - SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_CONFRONTO_SPETT_ESERCENTE;
/*Funzione temporanea per eseguire 
test con i dati in produzione*/
FUNCTION FU_CONFRONTO_SPETT_ESERCENTE_T(  p_id_cinema            CD_CINEMA.ID_CINEMA%TYPE,
                                        p_id_sala                   CD_SALA.ID_SALA%TYPE,
                                        p_id_circuito               CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_data_inizio_rif           DATE,
                                        p_data_fine_rif             DATE,
                                        p_data_inizio_conf          DATE,
                                        p_data_fine_conf            DATE
                                      ) return C_CONFRONTO_ESERCENTE
IS
C_ELENCO C_CONFRONTO_ESERCENTE;
BEGIN
    OPEN C_ELENCO
    FOR
         select distinct
            COD_ESERCENTE,
            RAGIONE_SOCIALE,
            mese,
            VENCD.fu_cd_string_agg(spettatori_anno)over (partition by COD_ESERCENTE,mese) spettatori
        from
        (
        with cinema_spett_rif as
            (
            select distinct id_cinema,data_riferimento,
                sum(spettatori_giorno) over (partition by id_cinema,data_riferimento) spettatori_giorno
                from
                (
                    select distinct id_sala,id_cinema,spettatori_giorno,data_riferimento
                    from    cd_fatto_spettatori
                    where   data_riferimento between p_data_inizio_rif and p_data_fine_rif
                    and     cd_fatto_spettatori.id_circuito = nvl(p_id_circuito,cd_fatto_spettatori.id_circuito)
                    and     cd_fatto_spettatori.id_sala = nvl(p_id_sala,cd_fatto_spettatori.id_sala)
                    and     cd_fatto_spettatori.id_cinema = nvl(p_id_cinema,cd_fatto_spettatori.id_cinema)
                )
            )
        select  distinct
                vi_cd_societa_esercente.RAGIONE_SOCIALE,
                cd_eser_contratto.COD_ESERCENTE,
                to_char(cinema_spett_rif.data_riferimento,'MM') mese, 
                to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by cd_eser_contratto.COD_ESERCENTE,to_char(data_riferimento,'MM-YYYY')) spettatori_anno
        from    vi_cd_societa_esercente,
                cd_eser_contratto,
                cd_contratto,
                cd_cinema_contratto,
                cinema_spett_rif
        where   
                cinema_spett_rif.id_cinema = cd_cinema_contratto.id_cinema
        and     cd_cinema_contratto.id_contratto = cd_contratto.id_contratto
        and     cd_eser_contratto.ID_CONTRATTO = cd_contratto.id_contratto
        and     cd_eser_contratto.DATA_INIZIO <= cinema_spett_rif.data_riferimento
        and     (cd_eser_contratto.DATA_FINE is null or cd_eser_contratto.DATA_FINE>=cinema_spett_rif.data_riferimento)
        and     cd_eser_contratto.cod_esercente = vi_cd_societa_esercente.COD_ESERCENTE
        union
        select  distinct
                vi_cd_societa_esercente.RAGIONE_SOCIALE,
                cd_eser_contratto.COD_ESERCENTE,
                to_char(cinema_spett_conf.data_riferimento,'MM') mese, 
                to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by cd_eser_contratto.COD_ESERCENTE,to_char(data_riferimento,'MM-YYYY')) spettatori_anno
        from    vi_cd_societa_esercente,
                cd_eser_contratto,
                cd_contratto,
                cd_cinema_contratto,
                (
                select distinct id_cinema,data_riferimento,
                    sum(spettatori_giorno) over (partition by id_cinema,data_riferimento) spettatori_giorno
                    from
                    (
                        select distinct id_sala,id_cinema,spettatori_giorno,data_riferimento
                        from    cd_fatto_spettatori
                        where   data_riferimento between p_data_inizio_conf and p_data_fine_conf
                        and     cd_fatto_spettatori.id_circuito = nvl(p_id_circuito,cd_fatto_spettatori.id_circuito)
                        and     cd_fatto_spettatori.id_sala = nvl(p_id_sala,cd_fatto_spettatori.id_sala)
                        and     cd_fatto_spettatori.id_cinema = nvl(p_id_cinema,cd_fatto_spettatori.id_cinema)
                    )
                )cinema_spett_conf
        where   
                cinema_spett_conf.id_cinema = cd_cinema_contratto.id_cinema
        and     cd_cinema_contratto.id_contratto = cd_contratto.id_contratto
        and     cd_eser_contratto.ID_CONTRATTO = cd_contratto.id_contratto
        and     cd_eser_contratto.DATA_INIZIO <= cinema_spett_conf.data_riferimento
        and     (cd_eser_contratto.DATA_FINE is null or cd_eser_contratto.DATA_FINE>=cinema_spett_conf.data_riferimento)
        and     cd_eser_contratto.cod_esercente = vi_cd_societa_esercente.COD_ESERCENTE
        order by COD_ESERCENTE,mese,spettatori_anno
        )
        order by ragione_sociale,COD_ESERCENTE,mese;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CONFRONTO_SPETT_ESERCENTE_T - SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_CONFRONTO_SPETT_ESERCENTE_T;
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_CONFRONTO_SPETT_GRUPPO
--
-- DESCRIZIONE:  Funzione che permette di recuperare il confronto annuo degli spettatori
--               spaccato per gruppo esercenti
--               E' FONDAMENTALE MANTENERE L'ORDINAMENTO IMPOSTATO
--               IN MODO DA POTER COSTRUIRE IN MANIERA OPPORTUNA 
--               LA STRUTTURA DA VISUALIZZARE
--
--
-- INPUT:
--  p_id_cinema     identificativo del cinema
--  p_id_sala       identificativo della sala
--  p_id_circuito   identificativo del circuito
--  p_data_inizio   data inizio della ricerca
--  p_data_fine     data fine ricerca
--
-- OUTPUT: lista dei gruppi con indicazione degli spettatori
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, 26 Maggio 2011
--
--  MODIFICHE: 
FUNCTION FU_CONFRONTO_SPETT_GRUPPO(  p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                     p_id_sala            CD_SALA.ID_SALA%TYPE,
                                     p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                     p_data_inizio        DATE,
                                     p_data_fine          DATE
                                   ) return C_CONFRONTO_GRUPPO
IS
C_ELENCO C_CONFRONTO_GRUPPO;
BEGIN
    OPEN C_ELENCO
    FOR
        select distinct
            id_gruppo_esercente,
            nome_gruppo,
            mese,
            max(spettatori )over (partition by id_gruppo_esercente,mese) spettatori
        from
        (
        select
            id_gruppo_esercente,
            rag_soc_cogn nome_gruppo,
            mese,
            VENCD.fu_cd_string_agg(spettatori_anno)over (partition by id_gruppo_esercente,mese order by spettatori_anno) spettatori
        from
            (with cinema_spett as
                (
                select distinct id_cinema,data_riferimento,
                    sum(spettatori_giorno) over (partition by id_cinema,data_riferimento) spettatori_giorno
                    from
                    (
                        select distinct id_sala,id_cinema,spettatori_giorno,data_riferimento
                        from    cd_fatto_spettatori
                        where   data_riferimento between p_data_inizio and p_data_fine
                        and     cd_fatto_spettatori.id_circuito = nvl(p_id_circuito,cd_fatto_spettatori.id_circuito)
                        and     cd_fatto_spettatori.id_sala = nvl(p_id_sala,cd_fatto_spettatori.id_sala)
                        and     cd_fatto_spettatori.id_cinema = nvl(p_id_cinema,cd_fatto_spettatori.id_cinema)
                    )
                )
            select  distinct
                    vi_cd_societa_gruppo.id_gruppo_esercente,
                    to_char(cinema_spett.data_riferimento,'MM') mese, 
                    to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by vi_cd_societa_gruppo.id_gruppo_esercente,to_char(data_riferimento,'MM-YYYY')) spettatori_anno
            from    vi_cd_societa_gruppo,
                    vi_cd_societa_esercente,
                    cd_eser_contratto,
                    cd_contratto,
                    cd_cinema_contratto,
                    cinema_spett
            where   
                    cinema_spett.id_cinema = cd_cinema_contratto.id_cinema
            and     cd_cinema_contratto.id_contratto = cd_contratto.id_contratto
            and     cd_eser_contratto.ID_CONTRATTO = cd_contratto.id_contratto
            and     cd_eser_contratto.DATA_INIZIO <= cinema_spett.data_riferimento
            and     (cd_eser_contratto.DATA_FINE is null or cd_eser_contratto.DATA_FINE>=cinema_spett.data_riferimento)
            and     cd_eser_contratto.cod_esercente = vi_cd_societa_esercente.COD_ESERCENTE
            and     vi_cd_societa_esercente.COD_ESERCENTE = vi_cd_societa_gruppo.COD_ESERCENTE
            and     (vi_cd_societa_gruppo.DATA_FINE_val is null or vi_cd_societa_gruppo.DATA_FINE_val>=cinema_spett.data_riferimento)
            and     vi_cd_societa_gruppo.data_inizio_val <= cinema_spett.data_riferimento
            order by id_gruppo_esercente,mese,spettatori_anno
            ),interl_u
        where id_gruppo_esercente = interl_u.cod_interl
        order by rag_soc_cogn,mese
        )
        order by nome_gruppo,mese;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CONFRONTO_SPETT_GRUPPO - SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_CONFRONTO_SPETT_GRUPPO;
--
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_CONFRONTO_TIPO_CINEMA
--
-- DESCRIZIONE:  Funzione che permette di recuperare il confronto annuo degli spettatori
--               spaccato per tipo cinema
--               E' FONDAMENTALE MANTENERE L'ORDINAMENTO IMPOSTATO
--               IN MODO DA POTER COSTRUIRE IN MANIERA OPPORTUNA 
--               LA STRUTTURA DA VISUALIZZARE
--
--
-- INPUT:
--  p_id_cinema     identificativo del cinema
--  p_id_sala       identificativo della sala
--  p_id_circuito   identificativo del circuito
--  p_data_inizio   data inizio della ricerca
--  p_data_fine     data fine ricerca
--
-- OUTPUT: lista dei cinema con indicazione degli spettatori
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Aprile 2011
--
--  MODIFICHE: 
FUNCTION FU_CONFRONTO_SPETT_TIPO_CINEMA(  p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                          p_id_sala            CD_SALA.ID_SALA%TYPE,
                                          p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                          p_data_inizio        DATE,
                                          p_data_fine          DATE
                                      ) return C_CONFRONTO_TIPO_CINEMA
IS
C_ELENCO C_CONFRONTO_TIPO_CINEMA;
BEGIN
    OPEN C_ELENCO
    FOR
         select distinct
            ID_TIPO_CINEMA,
            DESC_TIPO_CINEMA,
            mese,
            VENCD.fu_cd_string_agg(spettatori_anno)over (partition by ID_TIPO_CINEMA,mese) spettatori
        from
        (with cinema_spett as
            (
                select distinct id_cinema,data_riferimento,
                sum(spettatori_giorno) over (partition by id_cinema,data_riferimento) spettatori_giorno
                from
                (
                    select distinct id_sala,id_cinema,spettatori_giorno,data_riferimento
                    from    cd_fatto_spettatori
                    where   data_riferimento between p_data_inizio and p_data_fine
                    and     cd_fatto_spettatori.id_circuito = nvl(p_id_circuito,cd_fatto_spettatori.id_circuito)
                    and     cd_fatto_spettatori.id_sala = nvl(p_id_sala,cd_fatto_spettatori.id_sala)
                    and     cd_fatto_spettatori.id_cinema = nvl(p_id_cinema,cd_fatto_spettatori.id_cinema)
                )
            )
        select  distinct
                cd_tipo_cinema.id_tipo_cinema,
                cd_tipo_cinema.DESC_TIPO_CINEMA,
                to_char(cinema_spett.data_riferimento,'MM') mese, 
                to_char(data_riferimento,'YYYY')||':'|| sum(spettatori_giorno) over (partition by cd_tipo_cinema.id_tipo_cinema,to_char(data_riferimento,'MM-YYYY')) spettatori_anno
        from    cd_tipo_cinema,
                cd_cinema,
                cinema_spett
        where   
                cinema_spett.id_cinema = cd_cinema.id_cinema
        and     cd_cinema.ID_TIPO_CINEMA = cd_tipo_cinema.ID_TIPO_CINEMA
        order by cinema_spett.id_cinema,mese,spettatori_anno
        )
        order by DESC_TIPO_CINEMA,ID_TIPO_CINEMA,mese;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CONFRONTO_TIPO_CINEMA - SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_CONFRONTO_SPETT_TIPO_CINEMA;                                                       
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_PARAMETRI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_PARAMETRI(    p_data_riferimento         CD_SPETTATORI_EFF.DATA_RIFERIMENTO%TYPE,
                                 p_num_spettatori           CD_SPETTATORI_EFF.NUM_SPETTATORI%TYPE,
                                 p_id_sala                  CD_SPETTATORI_EFF.ID_SALA%TYPE
                                 )  RETURN VARCHAR2
IS
RETURN_VAR VARCHAR(240);
BEGIN
IF(v_stampa_acquisizione = 'ON')THEN
    RETURN_VAR := 'PROVA';
END IF;

RETURN RETURN_VAR;
END FU_STAMPA_PARAMETRI;

--
--PROCEDURE PR_ALLINEA_NUMERO_SPETTATORI
--AUTORE Mauro Viel Altran Luglio 2010
--La procedura aggiorna il numero di spettatori presenti sulla tavola cd_liquidazione_sala .
--Il numero di spettatori puo variare se Cinetel effettua una variazione.

PROCEDURE PR_ALLINEA_NUMERO_SPETTATORI(p_id_sala cd_spettatori_eff.ID_SALA%type, p_data_riferimento cd_spettatori_eff.DATA_RIFERIMENTO%type, p_num_spettatori cd_spettatori_eff.NUM_SPETTATORI%type) is
BEGIN 

update cd_liquidazione_sala 
set    num_spettatori_eff = p_num_spettatori
where  id_sala            = p_id_sala
and    data_rif           = p_data_riferimento;

exception 
when others then
   raise;
END PR_ALLINEA_NUMERO_SPETTATORI;
--
---------------------------------------------------------------------------------------------------
-- FUNCTION PR_ALLINEA_FATTO_SPETTATORI
--
-- DESCRIZIONE:  Procedura che si occupa dell'aggiornamento della
--              tavola denormalizzata CD_FATTO_SPETTAOTIR contenente le informazioni
--              relative al numero di spettatori legati alle sale-cinema-circuito
--
--
-- INPUT:
--  p_data_inizio   data inizio aggiornamento
--  p_data_fine     data fine aggiornamento
--
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Febbrario 2011
--
--  MODIFICHE:    Antonio Colucci, Teoresi srl, Aprile 2011
--                  Aggiunta gestione dei nuovi circuiti Sipra inseriti in anagrafica 
--                      -Blu Digitale
--                      -Rosso digitale
--                Antonio Colucci, Teoresi srl, 20/05/2011
--                  Inserita gestione temporale della associzione sala-circuito
--
PROCEDURE PR_ALLINEA_FATTO_SPETTATORI(p_data_inizio  DATE, p_data_fine DATE) 
IS
BEGIN
for elenco in (
     with sala_circuito as
     (
        select distinct
              cd_sala.id_sala,
              cd_cinema.id_cinema,
              cd_cinema.nome_cinema,
              cd_comune.comune,
              cd_sala.nome_sala,
              cd_circuito.nome_circuito,
              cd_circuito.id_circuito,
              cd_circuito_schermo.id_listino
        from    
                cd_cinema,
                cd_comune,
                cd_sala,
                cd_schermo,
                cd_circuito,
                cd_circuito_schermo
        where
                cd_schermo.id_schermo = cd_circuito_schermo.id_schermo    
        and     cd_circuito_schermo.id_circuito = cd_circuito.ID_CIRCUITO
        and     cd_circuito_schermo.flg_annullato = 'N'
        and     cd_circuito.FLG_DEFINITO_A_LISTINO = 'S'
        and     cd_schermo.id_sala = cd_sala.id_sala
        and     cd_sala.flg_visibile = 'S'
        and     cd_sala.flg_arena = 'N'
        and     cd_sala.id_cinema = cd_cinema.id_cinema
        and     cd_cinema.flg_virtuale = 'N'
        and     cd_comune.id_comune = cd_cinema.id_comune
        /*Prendo in esame solo i circuiti NAZIONALI*/
        --and     cd_circuito.id_circuito in (68,69,70,71,72,73,74,103,104)
        /*
        and     cd_sala.id_sala = nvl(p_id_sala,cd_sala.id_sala)
        and     cd_cinema.id_cinema = nvl(p_id_cinema,cd_cinema.id_cinema)*/
     )
     select 
            distinct
            sala_circuito.id_sala,
            sala_circuito.id_cinema,
            sala_circuito.id_circuito,
            sum(cd_spettatori_eff.num_spettatori) over (partition by cd_spettatori_eff.id_sala,cd_spettatori_eff.data_riferimento,sala_circuito.id_circuito) spettatori_giorno,
            cd_spettatori_eff.data_riferimento,
            sala_circuito.nome_cinema||'-'||sala_circuito.comune as cinema,
            sala_circuito.nome_sala,
            sala_circuito.nome_circuito
     from 
            cd_spettatori_eff,
            sala_circuito,
            cd_listino
     where
            sala_circuito.id_sala = cd_spettatori_eff.id_sala
     and    cd_spettatori_eff.data_riferimento between p_data_inizio and p_data_fine
     and    cd_spettatori_eff.data_riferimento between cd_listino.data_inizio and cd_listino.data_fine
     and    sala_circuito.id_listino = cd_listino.id_listino
     order by id_sala,data_riferimento
     )loop
         delete from cd_fatto_spettatori
         where 
                id_sala = elenco.id_sala
         and    id_cinema = elenco.id_cinema
         and    id_circuito = elenco.id_circuito
         and    data_riferimento = elenco.data_riferimento;
         --DBMS_OUTPUT.PUT_LINE('PRIMA:'||elenco.id_sala||'-'||elenco.id_cinema||'-'||elenco.id_circuito||'-'||elenco.data_riferimento||'-'||elenco.spettatori_giorno);
         insert into cd_fatto_spettatori
         (id_sala,id_cinema,id_circuito,data_riferimento,spettatori_giorno)
         values
         (elenco.id_sala,elenco.id_cinema,elenco.id_circuito,elenco.data_riferimento,elenco.spettatori_giorno);
         commit;
         --DBMS_OUTPUT.PUT_LINE('DOPO:'||elenco.id_sala||'-'||elenco.id_cinema||'-'||elenco.id_circuito||'-'||elenco.data_riferimento||'-'||elenco.spettatori_giorno);
     end loop;
     COMMIT;
END PR_ALLINEA_FATTO_SPETTATORI;

END PA_CD_ACQUISIZIONE_SPETT; 
/

