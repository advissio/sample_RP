CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PLAYLIST IS
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STATO_PLAYLIST_PERIODO
-- --------------------------------------------------------------------------------------------
-- INPUT:  p_data_inizio        data di inizio ricerca
--         p_data_fine          data di fine ricerca
-- OUTPUT: Restituisce un record per ogni data con le seguenti informazioni
--         a_data_commerciale    data commerciale a cui si riferisce il record
--         a_sale_vendute        numero di sale vendute
--         a_sale_allineate      numero di sale per cui la playlist e allineata alla pianificazione
--         a_vp_ok               numero di sale che hanno gia ricevuto l'ultima playlist generate
--         a_vs_ok               numero di sale i cui video server hanno gia ricevuto l'ultima playlist generata
--         a_sale_disp           numero di sale disponibili a magazzino
--         a_sale_senza_playlist numero di sale per cui non e ancora stata generata la playlist
--
-- REALIZZATORE  Angelo Marletta, Teoresi srl, 3/8/2010
--
-- MODIFICHE
--              Tommaso D'Anna, Teoresi srl, 16 Settembre 2011
--                  Aggiunto il cappello per reperire correttamente il numero di VS allineati completamente.
--                  La funzione in precedenza considerava allineato un VS che aveva anche una sola playlist
--                  allineata.
--          
FUNCTION FU_STATO_PLAYLIST_PERIODO(p_data_inizio DATE, p_data_fine DATE) RETURN C_STATO_PLAYLIST_PERIODO
IS
   cur C_STATO_PLAYLIST_PERIODO;
BEGIN
   PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data_inizio, p_data_fine);
   PA_CD_ADV_CINEMA.IMPOSTA_SALA(null);
OPEN cur FOR
    SELECT
        DATA_COMMERCIALE,
        SUM(SALE_VENDUTE) SALE_VENDUTE,
        SUM(SALE_ALLINEATE) SALE_ALLINEATE,
        SUM(VP_OK) VP_OK,
        SUM(VS_OK) VS_OK,
        SUM(VS_TOT) VS_TOT,
        SALE_DISP,
        SUM(SALE_SENZA_PLAYLIST) SALE_SENZA_PLAYLIST
    FROM (    
        select /*+ RULE */
            ID_CINEMA,
            data_commerciale,
            count(vi_cd_stato_playlist.id_sala) sale_vendute,
            sum(comunicati_sync) sale_allineate,
            sum(vp_sync) vp_ok,
            --count(distinct case when vs_sync = 1 then id_cinema else null end) vs_ok,
            SUM(VS_SYNC),
            COUNT(ID_SALA),
            FLOOR(SUM(VS_SYNC)/COUNT(ID_SALA)) AS VS_OK,
            count(distinct vi_cd_stato_playlist.id_cinema) vs_tot,
            tab_sale_disp.sale_disp,
            count(case when id_playlist is null then 1 else null end ) sale_senza_playlist
        from
            vi_cd_stato_playlist,
            (select /*+ RULE */ distinct
                data_proiezione,
                count(distinct cd_proiezione.id_schermo) over (partition by data_proiezione) sale_disp
            from
                cd_proiezione,
                cd_schermo,
                vi_cd_sala
            where
                data_proiezione between PA_CD_ADV_CINEMA.FU_DATA_INIZIO
                and PA_CD_ADV_CINEMA.FU_DATA_FINE
                and cd_proiezione.id_schermo = cd_schermo.id_schermo
                and cd_schermo.id_sala = vi_cd_sala.id and cd_proiezione.flg_annullato = 'N') tab_sale_disp
        where
            tab_sale_disp.data_proiezione = vi_cd_stato_playlist.data_commerciale
        group by
            ID_CINEMA,
            data_commerciale,
            sale_disp
        )
    group by
        data_commerciale,
        sale_disp;
RETURN cur;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_STATO_PLAYLIST_PERIODO: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_STATO_PLAYLIST_PERIODO;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_LAST_PLAYLIST
-- Restituisce la composizione dell'ultima playlist inviata per una sala in un dato giorno
-- --------------------------------------------------------------------------------------------
-- INPUT:  p_data_commerciale    data commerciale di riferimento
--         p_id_sala             sala di riferimento
-- OUTPUT: Restituisce un record per ogni data con le seguenti informazioni
--         a_data_commerciale    data commerciale 
--         a_id_sala             sala
--         a_data_modifica       data di generazione dell'ultima playlist
--         a_id_playlist         id dell'ultima playlist
--         a_id_proiezione       id proiezione (cd_proiezione)
--         a_id_break            id break (cd_break)
--         a_tipo                tipo break
--         a_id_comunicato       id comunicato (cd_comunicato)
--         a_id_materiale        id materiale (cd_materiale)
--         a_desc_sogg           descrizione soggetto
--         a_posizione           posizione del comunicato (da cd_comunicato)
--         a_posizione_relativa  posizione progressiva (da 1 in poi)
--         a_durata              durata del materiale in secondi
--         a_fasce               lista fasce orarie associate alla proiezione
--
-- REALIZZATORE  Angelo Marletta, Teoresi srl, 3/8/2010
--
-- MODIFICHE:    Antonio Colucci, Teoresi srl, 14/03/2011
--                  Aggiunta gestione del gingle del segui il film
FUNCTION FU_LAST_PLAYLIST(p_data_commerciale DATE, p_id_sala NUMBER) RETURN C_LAST_PLAYLIST
IS
   cur C_LAST_PLAYLIST;
BEGIN
OPEN cur FOR
    select distinct
        pl.data_commerciale,
        pl.id_sala,
        pl.data_modifica,
        pl.id id_playlist,
        br.id_proiezione,
        br.id_break,
        br.TIPO,
        co.ID_COMUNICATO,
        mat.id_materiale,
        co.DESC_SOGG,
        co.posizione,
        dense_rank() over (partition by pl.data_commerciale,pl.id_sala,co.id_break order by posizione) posizione_relativa,
        mat.durata,
        cl.rag_soc_cogn cliente,
        null fasce
        --fu_cd_string_agg(distinct fa.hh_inizio||':'||fa.mm_inizio||'-'||fa.hh_fine||':'||fa.mm_fine) over(partition by pl.data_commerciale,pl.id_sala,br.id_proiezione) fasce
    from
        (select distinct
            first_value(pl.id) over(partition by pl.data_commerciale,pl.id_sala order by pl.data_modifica desc) id,
            first_value(pl.data_modifica) over(partition by pl.data_commerciale,pl.id_sala order by pl.data_modifica desc) data_modifica,
            pl.data_commerciale,
            id_sala
         from cd_adv_snapshot_playlist pl
            where data_commerciale=p_data_commerciale
            and id_sala = nvl(p_id_sala,id_sala)
        ) pl,
        cd_adv_snapshot_break br,cd_adv_snapshot_comunicato co,
        cd_adv_snapshot_materiale mat,cd_adv_snapshot_fascia fa,
        vi_cd_cliente cl
    where
        pl.id=br.id_playlist
        and br.id=co.id_break
        and co.id_materiale=mat.id
        and pl.id=fa.id_playlist
        and br.id_proiezione=fa.id_proiezione
        --gestione del gingle Segui il Film
        and co.posizione not in (-2,91,71)
        and cl.id_cliente = mat.id_cliente
        and id_sala=nvl(p_id_sala,id_sala)
    order by data_commerciale,id_sala,id_proiezione,br.tipo desc,posizione;
RETURN cur;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_LAST_PLAYLIST: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_LAST_PLAYLIST;
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_PLAYLIST
-- Restituisce la composizione di una particolare playlist, individuata dalla tripla:
--     data_commerciale, id_sala, data_modifica
--  
-- --------------------------------------------------------------------------------------------
-- INPUT:  p_data_commerciale    data commerciale di riferimento
--         p_id_sala             sala di riferimento
--         p_data_modifica       data di modifica della playlist cercata
-- OUTPUT: Restituisce un record per ogni data con le seguenti informazioni
--         a_data_commerciale    data commerciale 
--         a_id_sala             sala
--         a_data_modifica       data di generazione dell'ultima playlist
--         a_id_playlist         id dell'ultima playlist
--         a_id_proiezione       id proiezione (cd_proiezione)
--         a_id_break            id break (cd_break)
--         a_tipo                tipo break
--         a_id_comunicato       id comunicato (cd_comunicato)
--         a_id_materiale        id materiale (cd_materiale)
--         a_desc_sogg           descrizione soggetto
--         a_posizione           posizione del comunicato (da cd_comunicato)
--         a_posizione_relativa  posizione progressiva (da 1 in poi)
--         a_durata              durata del materiale in secondi
--         a_fasce               lista fasce orarie associate alla proiezione
--
-- REALIZZATORE  Angelo Marletta, Teoresi srl, 22/09/2010
--
-- MODIFICHE:    Antonio Colucci, Teoresi srl, 14/03/2011
--                  Aggointa gestione del gingle del segui il film
FUNCTION FU_GET_PLAYLIST(p_data_commerciale DATE, p_id_sala NUMBER, p_data_modifica DATE) RETURN C_GET_PLAYLIST
IS
   cur C_GET_PLAYLIST;
BEGIN
OPEN cur FOR
    select distinct
        pl.data_commerciale,
        pl.id_sala,
        pl.data_modifica,
        pl.id id_playlist,
        br.id_proiezione,
        br.id_break,
        br.TIPO,
        co.ID_COMUNICATO,
        mat.id_materiale,
        co.DESC_SOGG,
        co.posizione,
        dense_rank() over (partition by pl.data_commerciale,pl.id_sala,co.id_break order by posizione) posizione_relativa,
        mat.durata,
        cl.rag_soc_cogn cliente,
        null fasce
        --fu_cd_string_agg(distinct fa.hh_inizio||':'||fa.mm_inizio||'-'||fa.hh_fine||':'||fa.mm_fine) over(partition by pl.data_commerciale,pl.id_sala,br.id_proiezione) fasce
    from
        (select distinct
            pl.id,
            pl.data_modifica,
            pl.data_commerciale,
            id_sala
         from cd_adv_snapshot_playlist pl
            where data_commerciale = p_data_commerciale
            and id_sala = nvl(p_id_sala,id_sala)
            and data_modifica = p_data_modifica
        ) pl,
        cd_adv_snapshot_break br,cd_adv_snapshot_comunicato co,
        cd_adv_snapshot_materiale mat,cd_adv_snapshot_fascia fa,
        vi_cd_cliente cl
    where
        pl.id=br.id_playlist
        and br.id=co.id_break
        and co.id_materiale=mat.id
        and pl.id=fa.id_playlist
        and br.id_proiezione=fa.id_proiezione
        --gestione del gingle Segui il Film
        and co.posizione not in (-2,91,71)
        and cl.id_cliente = mat.id_cliente
        and id_sala=nvl(p_id_sala,id_sala)
    order by data_commerciale,id_sala,id_proiezione,br.tipo desc,posizione;
RETURN cur;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_LAST_PLAYLIST: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_GET_PLAYLIST;
-----------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_PROIEZIONI
-- --------------------------------------------------------------------------------------------
--
-- DESCRIZIONE:  Funzione che permette di calcolare lo stato di trasmissione
--               per tutte le sale in un determinato intervallo di tempo.
--               Ogni stato e identificato da un numero intero ed e relativo alla coppia sala-data. 
--               Sono definiti i seguenti stati:
--               1: La sala e in produzione, ha trasmesso correttamente almeno 2 proiezioni e non si e verificato nessun errore
--               2: La sala e in produzione e ha trasmesso qualcosa ma il numero di proiezioni corrette e minore di 2
--               4: La sala e in produzione e ha trasmesso correttamente almeno 2 proiezioni, ma almeno in una si e verificato un errore
--               8: La sala non e in produzione e non ha trasmesso nulla
--               16: La sala non e in produzione e ha trasmesso dei comunicati di test
--               32: La sala e in produzione e non ha trasmesso nulla
--
-- OPERAZIONI:
--   1) Recupera la lista delle sale per ogni giorno di programmazione
--   2) Calcola lo stato di effettiva trasmissione definito sopra
--
-- NOTE: RECUPERA LE IONFORMAZIONI SUDDETTE ACCEDENDO ALLA TAVOLA 
--       CD_LIQUIDAZIONE_SALA CONTENENTE UNA DENORMALIZZAZIONE DELLE
--       INFO SULLA VERIFICA DEL TRASMESSO 
--
-- INPUT:
--      p_data_inizio          data commerciale iniziale di riferimento
--      p_data_fine            data commerciale finale di riferimento
--      p_id_cinema            indicativo del cinema (se e null viene ignorato)
--      p_id_sala              indicativo del sala (se e null viene ignorato)
--      p_flg_stato            somma degli stati che si vogliono ottenere
--
-- OUTPUT: lista richiesta
--
-- REALIZZATORE: Angelo Marletta, Teoresi srl, 15/04/2010
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, 13/09/2010
--                  Inserite informazioni sulle causali a preventivo e a consuntivo 
--                  nelle sale recuperate
--              Antonio Colucci, Teoresi srl, 21/12/2010
--                  Inserito calcolo al volo della causale preventiva in base al giorno di chiusura
--              Mauro Viel, Altran Dicembre 2010 
--                  Inserita gestione del nome cinema.
--              Tommaso D'Anna, Teoresi srl, 13/01/2011
--                  Inserito il reperimento dello stato della sala in tempo reale.
--              Tommaso D'Anna, Teoresi srl, 03/05/2011
--                  Inserita la gestione della data fine validita' della sala.
-------------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_PROIEZIONI( p_data_inizio         DATE,
                                 p_data_fine           DATE,
                                 p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                 p_id_sala             CD_SALA.ID_SALA%TYPE,
                                 p_flg_stato           INTEGER
                              ) RETURN C_VERIFICA_PROIEZIONI
IS
C_ELENCO C_VERIFICA_PROIEZIONI;
BEGIN
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data_inizio, p_data_fine);
    PA_CD_ADV_CINEMA.IMPOSTA_SALA(p_id_sala);
    OPEN C_ELENCO
    FOR
       select distinct
            cd_liquidazione_sala.data_rif data_commerciale,
            cd_cinema.id_cinema,
            cd_sala.id_sala,
            --cd_cinema.nome_cinema ,
            pa_cd_cinema.FU_GET_NOME_CINEMA( cd_cinema.id_cinema,cd_liquidazione_sala.DATA_RIF) as nome_cinema,
            cd_sala.nome_sala,
            cd_comune.comune,
            decode(cd_liquidazione_sala.flg_programmazione,'S',1,0) programmata,
            cd_liquidazione_sala.proiezioni_ok,
            cd_liquidazione_sala.PROIEZIONI_ERR,
            0 proiezioni_test,
            cd_liquidazione_sala.stato,
            /*Ricavo la causale preventiva controllando anche il giorno di chiusura settimanale*/
            substr(
                    PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(cd_liquidazione_sala.data_rif,cd_cinema.id_cinema,vi_cd_sale_causali_prev.id_codice_resp),
                    1,
                    instr(PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(cd_liquidazione_sala.data_rif,cd_cinema.id_cinema,vi_cd_sale_causali_prev.id_codice_resp),'-')-1
                  ) id_causale_prev,
            substr(
                    PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(cd_liquidazione_sala.data_rif,cd_cinema.id_cinema,vi_cd_sale_causali_prev.id_codice_resp),
                    instr(PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(cd_liquidazione_sala.data_rif,cd_cinema.id_cinema,vi_cd_sale_causali_prev.id_codice_resp),'-')+1,
                    length(PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(cd_liquidazione_sala.data_rif,cd_cinema.id_cinema,vi_cd_sale_causali_prev.id_codice_resp))
                  ) causale_prev,
            --vi_cd_sale_causali_prev.id_codice_resp id_causale_prev,
            --vi_cd_sale_causali_prev.desc_codice_prev causale_prev,
            cd_liquidazione_sala.id_codice_resp id_causale_def,
            cd_codice_resp.desc_codice causale_def,
            sum(num_spettatori) over (partition by cd_spettatori_eff.id_sala,cd_spettatori_eff.data_riferimento)tot_spettatori,
            cd_liquidazione_sala.motivazione nota,
            cd_adv_sala.STATO AS STATO_SALA
        from
            vi_cd_sale_causali_prev, 
            cd_spettatori_eff,
            cd_liquidazione_sala,
            cd_cinema,
            cd_sala,
            cd_comune,
            cd_codice_resp,
            cd_adv_sala
        where
            cd_liquidazione_sala.DATA_RIF between p_data_inizio and p_data_fine
        and (p_id_sala is null or cd_liquidazione_sala.id_sala = p_id_sala)
        and (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
        and cd_liquidazione_sala.id_sala = cd_sala.id_sala
        and cd_spettatori_eff.id_sala(+) = cd_liquidazione_sala.id_sala 
        and cd_spettatori_eff.data_riferimento(+) = cd_liquidazione_sala.data_rif
        and cd_liquidazione_sala.ID_SALA = vi_cd_sale_causali_prev.ID_SALA
        and cd_liquidazione_sala.DATA_RIF = vi_cd_sale_causali_prev.DATA_RIF
        and cd_liquidazione_sala.id_codice_resp = cd_codice_resp.id_codice_resp(+)
        and cd_sala.id_cinema = cd_cinema.id_cinema
        and cd_cinema.id_comune = cd_comune.id_comune
        and (p_flg_stato is null or bitand(cast(cd_liquidazione_sala.stato as INTEGER), p_flg_stato)>0)
        and cd_adv_sala.ID_SALA = cd_sala.ID_SALA
        AND ( CD_SALA.DATA_FINE_VALIDITA IS NULL OR ( p_data_fine <= CD_SALA.DATA_FINE_VALIDITA ) )
        order by
            cd_liquidazione_sala.data_rif,
            pa_cd_cinema.FU_GET_NOME_CINEMA( cd_cinema.id_cinema,cd_liquidazione_sala.DATA_RIF),
            --cd_cinema.nome_cinema,
            cd_comune.comune,
            cd_cinema.id_cinema,
            cd_sala.id_sala
        ;
    RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_VERIFICA_PROIEZIONI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:'||sqlerrm);
END FU_VERIFICA_PROIEZIONI;
--
-----------------------------------------------------------------------------------------------
-- FUNCTION FU_VER_PRO_TEMPO_REALE
-- --------------------------------------------------------------------------------------------
--
-- DESCRIZIONE:  Funzione che permette di calcolare lo stato di trasmissione
--               per tutte le sale in un determinato intervallo di tempo.
--               Ogni stato e identificato da un numero intero ed e relativo alla coppia sala-data. 
--               Sono definiti i seguenti stati:
--               1: La sala e in produzione, ha trasmesso correttamente almeno 2 proiezioni e non si e verificato nessun errore
--               2: La sala e in produzione e ha trasmesso qualcosa ma il numero di proiezioni corrette e minore di 2
--               4: La sala e in produzione e ha trasmesso correttamente almeno 2 proiezioni, ma almeno in una si e verificato un errore
--               8: La sala non e in produzione e non ha trasmesso nulla
--               16: La sala non e in produzione e ha trasmesso dei comunicati di test
--               32: La sala e in produzione e non ha trasmesso nulla
--
-- OPERAZIONI:
--   1) Recupera la lista delle sale per ogni giorno di programmazione
--   2) Calcola lo stato di effettiva trasmissione definito sopra
--
-- NOTE: Usa la vista vi_cd_comunicati_trasmessi
--      PER OTTENERE QUESTE INFORMAZIONE SI ACCEDE DIRETTAMENTE ALLE TAVOLE
--      CONTENENTI I LOG REALI DEI COMUNICATI ANDATI IN ONDA
--
-- INPUT:
--      p_data_inizio          data commerciale iniziale di riferimento
--      p_data_fine            data commerciale finale di riferimento
--      p_id_cinema            indicativo del cinema (se e null viene ignorato)
--      p_id_sala              indicativo del sala (se e null viene ignorato)
--      p_flg_stato            somma degli stati che si vogliono ottenere
--
-- OUTPUT: lista richiesta
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, 03/12/2010 FATTA COPIA DELLA VECCHIA VERIFICA DEL TRASMESSO 
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, 21/12/2010
--                  Inserito calcolo al volo della causale preventiva in base al giorno di chiusura
--              Mauro Viel, Altran Dicembre 2010 
--                  Inserita gestione del nome cinema.
--              Tommaso D'Anna, Teoresi srl, 13/01/2011
--                  Inserito il reperimento dello stato della sala in tempo reale.
--              Tommaso D'Anna, Teoresi srl, 03/05/2011
--                  Inserita la gestione della data fine validita' della sala.
-------------------------------------------------------------------------------------------------
FUNCTION FU_VER_PRO_TEMPO_REALE( p_data_inizio         DATE,
                                 p_data_fine           DATE,
                                 p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                 p_id_sala             CD_SALA.ID_SALA%TYPE,
                                 p_flg_stato           INTEGER
                              ) RETURN C_VERIFICA_PROIEZIONI
IS
C_ELENCO C_VERIFICA_PROIEZIONI;
BEGIN
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data_inizio, p_data_fine);
    PA_CD_ADV_CINEMA.IMPOSTA_SALA(p_id_sala);
    OPEN C_ELENCO
    FOR
       select 
            elenco_sale.data_commerciale,
            elenco_sale.id_cinema,
            elenco_sale.id_sala,
            --elenco_sale.nome_cinema,
            pa_cd_cinema.FU_GET_NOME_CINEMA(elenco_sale.id_cinema,elenco_sale.data_commerciale) as nome_cinema,
            elenco_sale.nome_sala,
            elenco_sale.comune,
            elenco_sale.programmata,
            elenco_sale.proiezioni_ok,
            elenco_sale.proiezioni_err,
            elenco_sale.proiezioni_test,
            elenco_sale.stato,
            /*##13/09/2010## start*/
            /*Ricavo la causale preventiva controllando anche il giorno di chiusura settimanale*/
            substr(
                    PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(elenco_sale.data_commerciale,elenco_sale.id_cinema,elenco_sale.id_causale_prev),
                    1,
                    instr(PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(elenco_sale.data_commerciale,elenco_sale.id_cinema,elenco_sale.id_causale_prev),'-')-1
                  ) id_causale_prev,
            substr(
                    PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(elenco_sale.data_commerciale,elenco_sale.id_cinema,elenco_sale.id_causale_prev),
                    instr(PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(elenco_sale.data_commerciale,elenco_sale.id_cinema,elenco_sale.id_causale_prev),'-')+1,
                    length(PA_CD_PLAYLIST.FU_GET_CAUSALE_FROM_CHIUS_SETT(elenco_sale.data_commerciale,elenco_sale.id_cinema,elenco_sale.id_causale_prev))
                  ) causale_prev,
            /*
            elenco_sale.id_causale_prev,
            elenco_sale.CAUSALE_PREV,
            */
            elenco_sale.id_causale_def,
            elenco_sale.CAUSALE_DEF,
            /*##13/09/2010## end*/ 
            elenco_sale.tot_spettatori,
            elenco_sale.nota,
            cd_adv_sala.STATO AS STATO_SALA
        from (
            select distinct
                h.data_commerciale,
                vi_cd_cinema.id id_cinema,
                h.id_sala,
                vi_cd_cinema.nome nome_cinema,
                vi_cd_sala.nome nome_sala,
                vi_cd_comune.nome comune,
                h.programmata,
                h.proiezioni_ok,
                (h.proiezioni_tot - h.proiezioni_ok) proiezioni_err,
                case
                    when com_test>0 then 1
                    else 0
                end proiezioni_test,
                case
                    when programmata=0 and com_test>0 then 16 --grigio
                    when programmata=0 then 8                 --bianco
                    when proiezioni_tot=0 then 32             --nero
                    --when proiezioni_ok<2 then 2             --rosso
                    when proiezioni_tot>proiezioni_ok then 4  --giallo
                    else 1                                    --verde
                end stato,
               /*##13/09/2010## start*/
                VI_CD_SALE_CAUSALI_PREV.ID_CODICE_RESP id_causale_prev,
                cd_codice_resp.DESC_CODICE CAUSALE_PREV,
                causali_def.ID_CODICE_RESP id_causale_def,
                causali_def.DESC_CODICE CAUSALE_DEF,
                /*##13/09/2010## end*/ 
                 sum(num_spettatori) over (partition by cd_spettatori_eff.id_sala,cd_spettatori_eff.data_riferimento) tot_spettatori,
                causali_def.nota
            from
            (
                select distinct
                    data_commerciale,
                    id_sala,
                    programmata,
                    sum(min(decode(durata_ok + fascia_ok + proiezione_ok + break_ok, 4, 1, 0))) over (partition by id_sala, data_commerciale) proiezioni_ok,
                    count(distinct data_inizio_proiezione) over (partition by id_sala, data_commerciale) proiezioni_tot,
                    max(com_test) com_test
                from
                vi_cd_comunicati_trasmessi t
                group by t.id_sala, data_inizio_proiezione, data_commerciale, programmata
            ) h,
            vi_cd_sala,
            vi_cd_cinema,
            vi_cd_comune,
            cd_spettatori_eff,
            VI_CD_SALE_CAUSALI_PREV,
            cd_codice_resp,
            CD_SALA
            /*##13/09/2010## start*/
            ,(select 
                id_sala,data_rif,desc_codice,
                cd_codice_resp.id_codice_resp,
                cd_liquidazione_sala.motivazione nota 
              from cd_liquidazione_sala, cd_codice_resp 
              where cd_liquidazione_sala.id_codice_resp = cd_codice_resp.id_codice_resp(+)
              and data_rif between p_data_inizio and p_data_fine
             )causali_def
            where
                VI_CD_SALE_CAUSALI_PREV.id_sala = h.id_sala
            and VI_CD_SALE_CAUSALI_PREV.data_RIF = h.DATA_COMMERCIALE
            and VI_CD_SALE_CAUSALI_PREV.id_codice_resp = cd_codice_resp.id_codice_resp (+)
            and causali_def.id_sala(+) = h.id_sala
            and causali_def.DATA_RIF(+) = h.DATA_COMMERCIALE
            and h.id_sala = vi_cd_sala.id
            and vi_cd_sala.id_cinema = vi_cd_cinema.id
            and vi_cd_comune.id = vi_cd_cinema.id_comune
            and data_commerciale between p_data_inizio and p_data_fine
            and (p_id_cinema is null or (vi_cd_cinema.id = p_id_cinema))
            and (p_id_sala is null or (vi_cd_sala.id = p_id_sala))
            and cd_spettatori_eff.id_sala(+) = h.id_sala
            and cd_spettatori_eff.data_riferimento(+) = h.data_commerciale
            AND vi_cd_sala.ID = CD_SALA.ID_SALA
            AND ( CD_SALA.DATA_FINE_VALIDITA IS NULL OR ( p_data_fine <= CD_SALA.DATA_FINE_VALIDITA ) )
        ) elenco_sale,
        cd_adv_sala
        where p_flg_stato is null or bitand(cast(elenco_sale.stato as INTEGER), p_flg_stato)>0
        and cd_adv_sala.ID_SALA = elenco_sale.id_sala
        order by
            elenco_sale.data_commerciale,
            --elenco_sale.nome_cinema,
            pa_cd_cinema.FU_GET_NOME_CINEMA(elenco_sale.id_cinema,elenco_sale.data_commerciale),
            elenco_sale.comune,
            elenco_sale.id_cinema,
            elenco_sale.id_sala
        ;
    RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_VERIFICA_PROIEZIONI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:'||sqlerrm);
END FU_VER_PRO_TEMPO_REALE;
--
FUNCTION FU_VERIFICA_PROIEZIONI_DETT( p_data           DATE,
                                 p_id_sala             CD_SALA.ID_SALA%TYPE,
                                 p_id_fascia           CD_FASCIA.ID_FASCIA%TYPE
                              ) RETURN C_VERIFICA_PROIEZIONI_DETT
IS
C_ELENCO C_VERIFICA_PROIEZIONI_DETT;
BEGIN
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data, p_data);
    PA_CD_ADV_CINEMA.IMPOSTA_SALA(p_id_sala);
    OPEN C_ELENCO
    FOR
    select
        eff.id_sala,
        eff.id_proiezione,
        eff.id_comunicato,
        eff.id_tipo_break,
        prev.durata_break durata_break_prev,
        progressivo,
        data_inizio_proiezione,
        data_inizio_break,
        data_erogazione_eff,
        eff.durata_break durata_break_eff,
        mat.id_materiale,
        durata_prev,
        durata_eff,
        CASE
           WHEN durata_eff IS NULL
              THEN NULL
           WHEN durata_eff > durata_prev
              THEN 1
           ELSE 0
        END durata_ok,
        (select decode(count(*), 0, 0, 1) from
             cd_adv_snapshot_fascia sfa, cd_adv_snapshot_playlist play
         where play.id=sfa.id_playlist and sfa.id_proiezione=prev.id_proiezione
             and (data_inizio_break-data_commerciale)*1440 between hh_inizio*60+mm_inizio and hh_fine*60+mm_fine
             and play.data_modifica<eff.data_erogazione_eff) fascia_ok,
        CASE
           WHEN prev.hash_proiezione IS NULL
              THEN NULL
           WHEN prev.hash_proiezione = eff.hash_proiezione
              THEN 1
           ELSE 0
        END proiezione_ok,
        CASE
           WHEN prev.hash_break IS NULL
              THEN NULL
           WHEN prev.hash_break = eff.hash_break
              THEN 1
           ELSE 0
        END break_ok,
        null com_test, --RIMUOVERE, CAMPO OBSOLETO
        cl.rag_soc_cogn cliente,
        mat.titolo,
        so.des_sogg soggetto,
        null id_fascia --RIMUOVERE, CAMPO OBSOLETO
    from 
        -- Comunicati effettivi
        vi_cd_comunicato_effettivo eff,
        -- Comunicati previsti
        vi_cd_comunicato_previsto prev,
        vi_cd_cliente cl,
        cd_materiale mat,
        cd_materiale_soggetti ms,
        soggetti so
    where
        eff.id_comunicato = prev.id_comunicato(+)
        and mat.id_materiale(+) = eff.id_materiale
        and cl.id_cliente(+) = mat.id_cliente
        and ms.id_materiale = mat.id_materiale
        and ms.cod_sogg = so.cod_sogg
        and (p_id_sala is null or p_id_sala = eff.id_sala)
    order by id_sala,data_erogazione_eff;
RETURN C_ELENCO;
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_VERIFICA_PROIEZIONI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI:'||sqlerrm);
END FU_VERIFICA_PROIEZIONI_DETT;
--
--
---------------------------------------------------------------------------------------------------
-- PROCEDURE PR_IMPOSTA_CAUSALE_PREV
--
-- DESCRIZIONE:  Procedura che si occupa di impostare la causale preventiva 
--               in una specifica sala per un periodo ben definito
--
-- OPERAZIONI:
--   1) Esegue l'update del record individuato dalla chiave IdSchermo-Data_proieizione nella tavola CD_PROIEZIONE 
--
-- INPUT:   p_id_sala               identificativo della sala 
--          p_id_codice_resp        causale da impostare a preventivo
--          p_data_inizio           data inizio periodo di intervento
--          p_data_fine             data fine periodo di intervento
--          p_esito
--
-- OUTPUT: esito dell'operazione
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 14 Settembre 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------

PROCEDURE PR_IMPOSTA_CAUSALE_PREV(  p_id_sala               cd_sala.ID_SALA%TYPE,
                                    p_id_codice_resp        cd_codice_resp.id_codice_resp%type,
                                    p_data_inizio           DATE,
                                    p_data_fine             DATE,
                                    p_esito OUT NUMBER)
IS
num_rec number :=0;
v_num_giorni number := 0;
v_data_proiezione date;
--
BEGIN 
--
    SAVEPOINT SP_IMPOSTA_CAUSALE_PREV;
    P_ESITO     := 1;
    select count(1) into num_rec
    from cd_sala_indisp
    where id_sala = p_id_sala
    and   data_rif between p_data_inizio and p_data_fine;
    if(num_rec> 0 and p_id_codice_resp is null)then
    /*E' stato richiesto di impostare id_codice_resp a null, quindi elimino record*/
        delete cd_sala_indisp 
        where id_sala = p_id_sala
        and   data_rif between p_data_inizio and p_data_fine;
    end if;
    if(num_rec> 0 and p_id_codice_resp is not null)then
    /*
      Eseguo update secco sulla tavola CD_SALA_INDISP
    */
        UPDATE CD_SALA_INDISP
        SET 
        ID_CODICE_RESP = P_ID_CODICE_RESP
        WHERE ID_SALA = P_ID_SALA 
        AND   DATA_RIF BETWEEN P_DATA_INIZIO AND P_DATA_FINE;
    end if;
    if(num_rec = 0 and p_id_codice_resp is not null)then
    /*
      Eseguo insert sulla tavola CD_SALA_INDISP
    */
        v_num_giorni := p_data_fine - p_data_inizio;
        FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni
            v_data_proiezione   :=   p_data_inizio + k ;
            insert into CD_SALA_INDISP
            (ID_SALA,DATA_RIF,id_codice_resp)
            values
            (P_ID_SALA,v_data_proiezione,p_id_codice_resp);
        end loop k;
    end if;
    
    --
  EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -3;
        RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_IMPOSTA_CAUSALE_PREV: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_IMPOSTA_CAUSALE_PREV;
--
END PR_IMPOSTA_CAUSALE_PREV;
---------------------------------------------------------------------------------------------------
-- PROCEDURE PR_IMPOSTA_CAUSALE_DEF
--
-- DESCRIZIONE:  Procedura che si occupa di impostare la causale definitiva 
--               in una specifica sala per un periodo ben definito
--
-- OPERAZIONI:
--   1) Esegue l'update del record individuato dalla chiave IdSala-Data_Rif nella tavola CD_LIQUIDAZIONE_SALA 
--
-- INPUT:   p_id_sala               identificativo della sala 
--          p_id_codice_resp        causale da impostare a preventivo
--          p_data                  data inizio periodo di intervento
--          p_esito
--
-- OUTPUT: esito dell'operazione
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 14 Settembre 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
/*
PROCEDURE PR_IMPOSTA_CAUSALE_DEF(  p_id_sala              cd_sala.ID_SALA%TYPE,
                                   p_id_codice_resp       cd_liquidazione_sala.id_codice_resp%type,
                                   p_data                 DATE,
                                   p_esito OUT NUMBER)
IS 
--
BEGIN 
--
    SAVEPOINT SP_IMPOSTA_CAUSALE_DEF;
    P_ESITO     := 1;*/
    /*
      Eseguo update secco sulla tavola cd_liquidazione_sala
    */
/*    UPDATE CD_LIQUIDAZIONE_SALA
    SET 
    ID_CODICE_RESP = P_ID_CODICE_RESP
    WHERE ID_SALA = P_ID_SALA 
    AND   DATA_RIF = P_DATA;
    --
  EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -3;
        RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_IMPOSTA_CAUSALE_DEF: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_IMPOSTA_CAUSALE_DEF;*/
--
/*END PR_IMPOSTA_CAUSALE_DEF;*/
---------------------------------------------------------------------------------------------------
-- PROCEDURE PR_CONFERMA_CAUSALE_PREV
--
-- DESCRIZIONE:  Procedura che si occupa di impostare la causale definitva 
--               in una specifica sala per un periodo ben definito copiandola da quella prreventiva
--
-- OPERAZIONI:
--   1) Esegue l'update del record individuato dalla chiave IdSchermo-Data_proieizione nella tavola CD_PROIEZIONE 
--
-- INPUT:   p_id_sala               identificativo della sala 
--          p_id_codice_resp        causale da impostare a preventivo
--          p_data_inizio           data inizio periodo di intervento
--          p_data_fine             data fine periodo di intervento
--          p_esito
--
-- OUTPUT: esito dell'operazione
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 14 Settembre 2010
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
/*
PROCEDURE PR_CONFERMA_CAUSALE_PREV( p_id_sala              cd_sala.ID_SALA%TYPE,
                                    p_id_codice_resp       cd_liquidazione_sala.id_codice_resp%type,
                                    p_data                 DATE,
                                    p_esito OUT NUMBER)
IS 
--
BEGIN 
--
    SAVEPOINT SP_CONFERMA_CAUSALE_PREV;
    P_ESITO     := 1;
*/
    /*
      Eseguo update secco sulla tavola cd_proiezione
    */
/*
    UPDATE CD_LIQUIDAZIONE_SALA
    SET 
    ID_CODICE_RESP = P_ID_CODICE_RESP
    WHERE ID_SALA = P_ID_SALA 
    AND   DATA_RIF = P_DATA;
    --
  EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -3;
        RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_CONFERMA_CAUSALE_PREV: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_CONFERMA_CAUSALE_PREV;
--
END PR_CONFERMA_CAUSALE_PREV;
*/
-----------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALE_FROM_CHIUS_SETT
-- --------------------------------------------------------------------------------------------
--
-- DESCRIZIONE:  Funzione che permette di calcolare la causale corretta
--               da attribuire in una sala (cinema) in un dato giorno
--
-- OPERAZIONI:
--    Verifica se il giorno di osservazione per il cinema in questione 
--      rappresenta o meno un giorno di chiusura settimanale
--      In caso affermativo va a verificare la causale di partenza identificata dal parametro di input
--      in caso di casuale preventiva amministrativa la funzione restituisce la causale amministrativa
--      in caso di causale preventiva tecnica la funzione restituisce la causale corispondente al giorno di chiusura settimanale
--      in caso di causale a null restituisce la causale corispondente al giorno di chiusura settimanale
--      Se il giorno di osservazione non corrisponde ad un giorno di chiusura settimanale,
--      la funzione restituisce la casuale ricevuta in input
--
-- NOTE: 
--
-- INPUT:
--      p_data          data di osservazione
--      p_id_cinema     identificativo del cinema
--      p_id_causale    identificativo della causale di partenza
--
-- OUTPUT: lista richiesta
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, 20/09/2010
--
--  MODIFICHE:   
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALE_FROM_CHIUS_SETT( p_data           DATE,
                                         p_id_cinema      CD_CINEMA.ID_CINEMA%TYPE,
                                         p_id_causale     CD_CODICE_RESP.ID_CODICE_RESP%TYPE
                                        ) RETURN varchar2
IS
V_CAUSALE_OUTPUT number := 0;
V_GIORNO_CHIUSURA NUMBER := 0;
V_OUTPUT varchar2(200);
C_ELENCO PA_CD_ACQUISIZIONE_SPETT.C_CODICE_RESP;
V_ELENCO PA_CD_ACQUISIZIONE_SPETT.R_CODICE_RESP;
BEGIN
    V_CAUSALE_OUTPUT := p_id_causale;
    SELECT 
        count(COND.GIORNO_CHIUSURA) 
        INTO V_GIORNO_CHIUSURA 
    FROM 
        CD_CONDIZIONE_CONTRATTO COND, CD_CONTRATTO CON, 
        CD_CINEMA_CONTRATTO CC, CD_CINEMA CIN             
    WHERE CIN.ID_CINEMA = P_ID_CINEMA
        AND CC.ID_CINEMA = CIN.ID_CINEMA
        AND CON.ID_CONTRATTO = CC.ID_CONTRATTO
        AND P_DATA BETWEEN CON.DATA_INIZIO AND CON.DATA_FINE
        AND COND.ID_CINEMA_CONTRATTO = CC.ID_CINEMA_CONTRATTO
        AND COND.GIORNO_CHIUSURA = TO_CHAR(P_DATA, 'D');
    IF(V_GIORNO_CHIUSURA <> 0)THEN
--    dbms_output.put_line('p_data per il cinema e giorno di chiusura:');
    /*
    IL GIORNO DI OSSERVAZIONE E UN GIORNO DI CHISURA SETTIMANALE
    VERIFICO LA CAUSALE RICEVUTA IN INPUT
    */
        V_CAUSALE_OUTPUT := 23;
        IF(P_ID_CAUSALE is not NULL)THEN
            /*VERIFICO SE SI TRATTA DI UNA CAUSALE AMMINISTRATIVA*/
            C_ELENCO := PA_CD_ACQUISIZIONE_SPETT.FU_GET_CAUSALI_AMMINISTRATIVE;
            LOOP
                FETCH C_ELENCO INTO V_ELENCO;
                EXIT WHEN C_ELENCO%NOTFOUND;  
--                dbms_output.put_line('codice osservato:'||V_ELENCO.A_ID_CODICE_RESP);
                IF(V_ELENCO.A_ID_CODICE_RESP = P_ID_CAUSALE)THEN
--                    dbms_output.put_line('trovata occorrenza - V_CAUSALE_OUTPUT:'||V_CAUSALE_OUTPUT);
                    V_CAUSALE_OUTPUT := P_ID_CAUSALE;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
     END IF;
     if(V_CAUSALE_OUTPUT is not null )then
     select id_codice_resp||'-'||desc_codice
     into  V_OUTPUT
     from cd_codice_resp where id_codice_resp = V_CAUSALE_OUTPUT;
     end if;
     return  V_OUTPUT;
--    dbms_output.put_line('V_CAUSALE_OUTPUT:'|| V_CAUSALE_OUTPUT);
 EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_GET_CAUSALE_FROM_CHIUS_SETT: SI E VERIFICATO UN ERRORE:'||sqlerrm);
END FU_GET_CAUSALE_FROM_CHIUS_SETT;

--Modifica Mauro Viel, Altran Dicembre 2010 inserita gestione del nome cinema.
--         Antonio Colucci, TeoresiGroup srl, 16 Febbraio 2011
--              inserito filtro data sulla associativa eser_contratto per trattare casi di subentro esercente
FUNCTION FU_GET_MANCATA_PROIEZIONE(p_data_inizio date, p_data_fine date, p_cod_esercente vi_cd_societa_esercente.COD_ESERCENTE%type)  RETURN C_MANCATA_PROIEZIONE IS
v_mancata_proiezione c_mancata_proiezione;
BEGIN
open v_mancata_proiezione for 
select  eser.ragione_sociale as nome_esercente,
        pa_cd_cinema.FU_GET_NOME_CINEMA(ci.id_cinema,data_rif)as nome_cinema, 
        --ci.nome_cinema as nome_cinema, 
        com.comune as comune, 
        sa.nome_sala as sala, 
        to_char(data_rif,'dd/MM/yyyy') data,  
        DESC_CODICE problema, 
        ls.motivazione nota
from
 cd_comune COM,
 cd_cinema CI,
 cd_sala SA,
 cd_codice_resp cr,
 cd_liquidazione_sala LS,
 cd_cinema_contratto cico,
 cd_contratto co, 
 cd_eser_contratto esco,
 vi_cd_societa_esercente eser
 where LS.data_rif between p_data_inizio and p_data_fine --'01/11/2010' and '07/11/2010' -- periodo input da applicazione
  and FLG_PROIEZIONE_PUBB ='N'
  and cr.id_codice_resp = ls.id_codice_resp
  and cr.problematica= 'Problema tecnico Esercente'  -- and ls.id_codice_resp in (19,20,21,26)
  and SA.id_sala = ls.id_sala
  and CI.id_cinema = SA.id_cinema
  and CI.flg_annullato='N'
  and CI.flg_virtuale='N'
  and COM.id_comune = CI.id_comune 
  and  cico.ID_CINEMA = ci.ID_CINEMA 
  and sa.id_cinema = ci.ID_CINEMA
  and co.ID_CONTRATTO = cico.ID_CONTRATTO
  and esco.ID_CONTRATTO = co.ID_CONTRATTO
  and esco.DATA_INIZIO <= trunc(data_rif)
  and (esco.DATA_FINE is null or esco.DATA_FINE >= trunc(data_rif))
  and eser.COD_ESERCENTE = esco.COD_ESERCENTE
  and eser.cod_esercente = nvl(p_cod_esercente,eser.cod_esercente)
  order by eser.RAGIONE_SOCIALE, 
           --ci.nome_cinema,
           pa_cd_cinema.FU_GET_NOME_CINEMA(ci.id_cinema,data_rif), 
           com.comune, 
           sa.nome_sala, 
           data_rif;
  return v_mancata_proiezione;
END ;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_INFO_GESTORI_MOD_PLAYLIST
-- Restituisce le informazioni necessarie per l'invio delle mail ai gestori.
-- Tramite il valore in input le playlist vengono considerate o meno; ad esempio
-- se il valore di input e' 30, vengono prese in considerazione tutte le 
-- playlist che sono state modificate sino a 30 minuti fa.
-- Se l'e-mail del gestore finisce con "@postainternasipra.it" il record viene
-- automaticamente scartato.
--  
-- --------------------------------------------------------------------------------------------
-- INPUT:   p_minuti_da_adesso      il lasso temporale in minuti entro il quale
--                                  la playlist viene considerata
--          p_data_commerciale      la data commerciale di riferimento
--                                  [nullable]
--          p_id_sala               la sala della quale reperire le informazioni
--                                  [nullable]   
-- OUTPUT: Restituisce un record per ogni playlist 
--          a_data_modifica         la data di modifica dello snapshot playlist
--          a_data_commerciale      la data commerciale di riferimento della playlist
--          a_id_cinema             l'id del cinema di riferimento
--          a_nome_cinema           il nome del cinema di riferimento
--          a_id_sala               l'id della sala di riferimento
--          a_nome_sala             il nome della sala di riferimento
--          a_email                 l'indirizzo a cui mandare la mail di notifica
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi s.r.l., 30/11/2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_GESTORI_MOD_PLAYLIST(  p_minuti_da_adesso  NUMBER,
                                        p_data_commerciale  CD_ADV_SNAPSHOT_PLAYLIST.DATA_COMMERCIALE%TYPE,
                                        p_id_sala           CD_ADV_SNAPSHOT_PLAYLIST.ID_SALA%TYPE
                                     )
                                        RETURN C_INFO_GESTORI
IS
C_INFO C_INFO_GESTORI;
BEGIN
OPEN C_INFO FOR
    SELECT      CD_ADV_SNAPSHOT_PLAYLIST.DATA_MODIFICA,
                CD_ADV_SNAPSHOT_PLAYLIST.DATA_COMMERCIALE,
                VI_CD_INFO_GESTORE_SALA.ID_CINEMA,
                VI_CD_INFO_GESTORE_SALA.NOME_CINEMA,
                VI_CD_INFO_GESTORE_SALA.ID_SALA,
                VI_CD_INFO_GESTORE_SALA.NOME_SALA,
                VI_CD_INFO_GESTORE_SALA.EMAIL
    FROM        CD_ADV_SNAPSHOT_PLAYLIST,
                VI_CD_INFO_GESTORE_SALA
    WHERE       CD_ADV_SNAPSHOT_PLAYLIST.ID_SALA = VI_CD_INFO_GESTORE_SALA.ID_SALA
                -- La differenza e' in giorni, moltiplicando per 1440 la ottengo in minuti
    AND         ((SYSDATE - CD_ADV_SNAPSHOT_PLAYLIST.DATA_MODIFICA ) * 1440 ) < p_minuti_da_adesso
    AND         CD_ADV_SNAPSHOT_PLAYLIST.DATA_COMMERCIALE   = nvl(p_data_commerciale, CD_ADV_SNAPSHOT_PLAYLIST.DATA_COMMERCIALE)
    AND         CD_ADV_SNAPSHOT_PLAYLIST.ID_SALA            = nvl(p_id_sala, CD_ADV_SNAPSHOT_PLAYLIST.ID_SALA)
    AND         VI_CD_INFO_GESTORE_SALA.EMAIL NOT LIKE '%@postainternasipra.it'
    ORDER BY    VI_CD_INFO_GESTORE_SALA.ID_SALA, VI_CD_INFO_GESTORE_SALA.ID_CINEMA;
RETURN C_INFO;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20047, 'FU_INFO_GESTORI_MOD_PLAYLIST: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_INFO_GESTORI_MOD_PLAYLIST;
---------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ALLINEA_VERIFICA_TRASM
--
-- DESCRIZIONE:  Procedura che si occupa di aggiornare la tavola CD_LIQUIDAZIONE_SALA
--               con i dati estratti dalla verifica del trasmesso
--               Esegue una denormalizzazione della verifica del trasmesso sulla tavola indicata
--               LA PROCEDURA AGGIORNA TUTTI I DATI RECUPERATI DALLA QUERY
--               INDIPENDENTEMENTE DAL FATTO CHE CI SIANO DEI DATI DA MODIFICARE OPPURE NO
--               NON TOCCARE PARTE RELATIVA ALLA GESTIONE DEI TRIGGER
--
-- OPERAZIONI:
--   1) Esegue l'update del record individuato dalla chiave IdSchermo-Data_proieizione nella tavola CD_PROIEZIONE 
--
-- INPUT:   p_data_inizio         Data inizio di osservazione,
--          p_data_fine           data fine osservazione,
--          p_id_cinema           identificativo del cinema,
--          p_id_sala             identificativo della sala,
--          p_esito
--
-- OUTPUT: esito dell'operazione
--
-- REALIZZATORE: 
--              Antonio Colucci, Teoresi srl, 06 Dicembre 2010
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, 06 Aprile 2011
--                  Aggiunta gestione della colonna FLG_PROIEZIONE_PUBB in modo che
--                  se proiezione_ok = 0 and proiezione_err >1 ==> 'S'
--                  se proiezione_ok >0 ==> 'S'
--                  altrimenti 'N'
--              Tommaso D'Anna, Teoresi srl, 03/05/2011
--                  Inserita la gestione della data fine validita' della sala.
-------------------------------------------------------------------------------------------------

PROCEDURE PR_ALLINEA_VERIFICA_TRASM( p_data_inizio         DATE,
                                     p_data_fine           DATE,
                                     p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                     p_id_sala             CD_SALA.ID_SALA%TYPE,
                                     p_esito OUT NUMBER
                                    )
IS
--
BEGIN 
--
    SAVEPOINT SP_ALLINEA_VERIFICA;
    P_ESITO     := 1;
    begin
    --DBMS_OUTPUT.PUT_LINE('Inizio - '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
    PA_CD_UTILITY.PR_ABILITA_TRIGGER('N');
    PA_CD_TRIGGER.PR_DISABILITA_TRIGGER;
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data_inizio, p_data_fine);
    PA_CD_ADV_CINEMA.IMPOSTA_SALA(p_id_sala);
    FOR elenco in (
       select /*+ RULE */
            elenco_sale.data_commerciale,
            elenco_sale.id_cinema,
            elenco_sale.id_sala,
            elenco_sale.nome_cinema,
            elenco_sale.nome_sala,
            elenco_sale.comune,
            elenco_sale.programmata,
            elenco_sale.proiezioni_ok,
            elenco_sale.proiezioni_err,
            elenco_sale.proiezioni_test,
            elenco_sale.stato,
            elenco_sale.id_causale_prev,
            elenco_sale.CAUSALE_PREV,
            elenco_sale.id_causale_def,
            elenco_sale.CAUSALE_DEF,
            elenco_sale.tot_spettatori,
            elenco_sale.nota
        from (
            select /*+ RULE */ distinct
                h.data_commerciale,
                vi_cd_cinema.id id_cinema,
                h.id_sala,
                vi_cd_cinema.nome nome_cinema,
                vi_cd_sala.nome nome_sala,
                vi_cd_comune.nome comune,
                h.programmata,
                h.proiezioni_ok,
                (h.proiezioni_tot - h.proiezioni_ok) proiezioni_err,
                case
                    when com_test>0 then 1
                    else 0
                end proiezioni_test,
                case
                    when programmata=0 and com_test>0 then 16 --grigio
                    when programmata=0 then 8                 --bianco
                    when proiezioni_tot=0 then 32             --nero
                    --when proiezioni_ok<2 then 2             --rosso
                    when proiezioni_tot>proiezioni_ok then 4  --giallo
                    else 1                                    --verde
                end stato,
                VI_CD_SALE_CAUSALI_PREV.ID_CODICE_RESP id_causale_prev,
                cd_codice_resp.DESC_CODICE CAUSALE_PREV,
                causali_def.ID_CODICE_RESP id_causale_def,
                causali_def.DESC_CODICE CAUSALE_DEF,
                sum(num_spettatori) over (partition by cd_spettatori_eff.id_sala,cd_spettatori_eff.data_riferimento) tot_spettatori,
                causali_def.nota
            from
            (
                select /*+ RULE */ distinct
                    data_commerciale,
                    id_sala,
                    programmata,
                    sum(min(decode(durata_ok + fascia_ok + proiezione_ok + break_ok, 4, 1, 0))) over (partition by id_sala, data_commerciale) proiezioni_ok,
                    count(distinct data_inizio_proiezione) over (partition by id_sala, data_commerciale) proiezioni_tot,
                    max(com_test) com_test
                from
                vi_cd_comunicati_trasmessi t
                group by t.id_sala, data_inizio_proiezione, data_commerciale, programmata
            ) h,
            vi_cd_sala,
            vi_cd_cinema,
            vi_cd_comune,
            cd_spettatori_eff,
            VI_CD_SALE_CAUSALI_PREV,
            cd_codice_resp,
            CD_SALA
            ,(select /*+ RULE */
                id_sala,data_rif,desc_codice,
                cd_codice_resp.id_codice_resp,
                cd_liquidazione_sala.motivazione nota 
              from cd_liquidazione_sala, cd_codice_resp 
              where cd_liquidazione_sala.id_codice_resp = cd_codice_resp.id_codice_resp(+)
              and data_rif between p_data_inizio and p_data_fine
             )causali_def
            where
                VI_CD_SALE_CAUSALI_PREV.id_sala = h.id_sala
            and VI_CD_SALE_CAUSALI_PREV.data_RIF = h.DATA_COMMERCIALE
            and VI_CD_SALE_CAUSALI_PREV.id_codice_resp = cd_codice_resp.id_codice_resp (+)
            and causali_def.id_sala(+) = h.id_sala
            and causali_def.DATA_RIF(+) = h.DATA_COMMERCIALE
            and h.id_sala = vi_cd_sala.id
            and vi_cd_sala.id_cinema = vi_cd_cinema.id
            and vi_cd_comune.id = vi_cd_cinema.id_comune
            and data_commerciale between p_data_inizio and p_data_fine
            and (p_id_cinema is null or (vi_cd_cinema.id = p_id_cinema))
            and (p_id_sala is null or (vi_cd_sala.id = p_id_sala))
            and cd_spettatori_eff.id_sala(+) = h.id_sala
            and cd_spettatori_eff.data_riferimento(+) = h.data_commerciale
            AND vi_cd_sala.ID = CD_SALA.ID_SALA
            AND ( CD_SALA.DATA_FINE_VALIDITA IS NULL OR ( p_data_fine <= CD_SALA.DATA_FINE_VALIDITA ) )           
        ) elenco_sale
        --where p_flg_stato is null or bitand(cast(elenco_sale.stato as INTEGER), p_flg_stato)>0
        order by
            elenco_sale.data_commerciale,
            elenco_sale.nome_cinema,
            elenco_sale.comune,
            elenco_sale.id_cinema,
            elenco_sale.id_sala) 
       loop
       /*
       DBMS_OUTPUT.PUT_LINE('id_sala:'||elenco.id_sala||' - data_commerciale:'||elenco.data_commerciale);
       DBMS_OUTPUT.PUT_LINE('proiezioni_ok = '||elenco.proiezioni_ok||' - proiezioni_err = '||elenco.proiezioni_err||' - '||'stato = '||elenco.stato);
       DBMS_OUTPUT.PUT_LINE('------------------------------------------------------');*/
       update cd_liquidazione_sala
       set proiezioni_ok = nvl(elenco.proiezioni_ok,proiezioni_ok),
           proiezioni_err = nvl(elenco.proiezioni_err,proiezioni_err),
           stato = nvl(elenco.stato,stato),
           flg_proiezione_pubb = decode(((elenco.proiezioni_ok*10)+elenco.proiezioni_err),0,'N',1,'N','S')
       where cd_liquidazione_sala.id_sala = elenco.id_sala
       and   cd_liquidazione_sala.data_rif = elenco.data_commerciale;
       end loop;
    --commit;
    PA_CD_UTILITY.PR_ABILITA_TRIGGER('S');
    PA_CD_TRIGGER.PR_ABILITA_TRIGGER;
    --DBMS_OUTPUT.PUT_LINE('Fine - '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
end;
    --
  EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -3;
        RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_ALLINEA_VERIFICA_TRASM: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_ALLINEA_VERIFICA;
--
END PR_ALLINEA_VERIFICA_TRASM;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_SPETTACOLI_SALA
-- Restituisce l'elenco degli spettacoli previsti dalla programmazione inserita dal gestore
--  
-- --------------------------------------------------------------------------------------------
-- INPUT:   p_data_rif      data di riferimento
--          p_id_sala       identificativo della sala
--
-- OUTPUT: Restituisce le informazioni relative agli spettacoli previsti per la messa in
--          onda nella sala specificata e nella data di osservazione 
--
-- REALIZZATORE  
--          Antonio Colucci, Teoresi s.r.l., 16/12/2010
-- MODIFICHE
--          Tommaso D'Anna, Teoresi s.r.l., 22 Luglio 2011
--              Spostato il controllo sulle date di validita sull'esercente contratto invece 
--              che sul contratto
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETTACOLI_SALA(  p_data_rif      CD_LIQUIDAZIONE_SALA.DATA_RIF%TYPE,
                              p_id_sala       cd_sala.ID_SALA%TYPE
                            )RETURN C_INFO_SPETTACOLI
IS
C_spettacoli C_INFO_SPETTACOLI;
BEGIN
OPEN C_spettacoli FOR
    select distinct
        cd_cinema.id_cinema,
        cd_sala.id_sala,
        vi_cd_societa_esercente.ragione_sociale,
        gestori_utente.EMAIL,
        gestori_programmazione.id_spettacolo,
        cd_spettacolo.FLG_PROTETTO,
        cd_spettacolo.nome_spettacolo,
        cd_genere.DESC_GENERE,
        VENCD.fu_cd_string_agg(CD_TARGET.DESCR_TARGET) over (partition by cd_spettacolo.id_spettacolo) DESCR_TARGET,
        gestori_programmazione.NUMERO_PROIEZIONI,
        LPAD(FLOOR((gestori_programmazione.DATA_INIZIO - p_data_rif) * 24),2,0)
        ||':'||
        LPAD(TO_CHAR(gestori_programmazione.DATA_INIZIO, 'MI'),2,0)
        ||' - '||
        LPAD(FLOOR((gestori_programmazione.DATA_FINE - p_data_rif) * 24),2,0)
        ||':'||
        LPAD(TO_CHAR(gestori_programmazione.DATA_FINE, 'MI'),2,0) ORARIO
     from
        vi_cd_societa_esercente,
        cd_eser_contratto,
        cd_contratto,
        cd_cinema_contratto,
        cd_cinema,
        cd_sala,
        gestori_utente,
        gestori_utente_cinema,
        gestori_programmazione,
        cd_spettacolo,
        cd_spett_target,
        cd_target,
        cd_genere
    where
        vi_cd_societa_esercente.cod_esercente = cd_eser_contratto.cod_esercente
    and cd_eser_contratto.id_contratto = cd_contratto.id_contratto
    AND CD_ESER_CONTRATTO.DATA_INIZIO <= p_data_rif
    AND (CD_ESER_CONTRATTO.DATA_FINE IS NULL OR CD_ESER_CONTRATTO.DATA_FINE >= p_data_rif) 
    and cd_cinema_contratto.id_contratto = cd_contratto.id_contratto
    and cd_cinema.id_cinema = cd_cinema_contratto.id_cinema
    and cd_sala.id_cinema = cd_cinema.id_cinema
    and cd_sala.id_sala = nvl(p_id_sala,cd_sala.id_sala)
    and cd_sala.id_sala = gestori_programmazione.id_sala
    and trunc(gestori_programmazione.DATA_INIZIO) = p_data_rif
    and gestori_programmazione.id_spettacolo = cd_spettacolo.id_spettacolo
    and cd_sala.id_cinema = gestori_utente_cinema.id_cinema
    and gestori_utente_cinema.ID_UTENTE = gestori_utente.ID
    and cd_spettacolo.id_spettacolo = cd_spett_target.id_spettacolo(+)
    and cd_spett_target.id_target = cd_target.id_target(+)
    and cd_spettacolo.id_genere = cd_genere.id_genere(+)
    and instr(gestori_utente.EMAIL,'@postainternasipra.it') = 0
    order by cd_cinema.id_cinema,cd_sala.id_sala,orario;
RETURN C_spettacoli;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20047, 'FU_SPETTACOLI_SALA: SI E VERIFICATO UN ERRORE:'||SQLERRM);
END FU_SPETTACOLI_SALA;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_SALE_NO_COMUNICATI
-- Restituisce l'elenco della sale per le quali non sono previsti comunicati per
-- la data in questione
--  
-- --------------------------------------------------------------------------------------------
-- INPUT:   
--          p_data_rif              La data di riferimento  
-- OUTPUT:
--          Elenco di C_SALE_NO_COMUNICATI
--              contenente le coppie sala/cinema senza comunicati 
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi s.r.l., 04/05/2011
-- MODIFICHE
--          Tommaso D'Anna, Teoresi s.r.l., 09/05/2011
--              Aggiunta la join verso CD_PROIEZIONE
--          Tommaso D'Anna, Teoresi s.r.l., 13/07/2011
--              Rimosso flg_attivo e sostituito con data_inizio_validita
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALE_NO_COMUNICATI  (  
                                    p_data_rif          VI_CD_COMUNICATO_PREVISTO.DATA_COMMERCIALE%TYPE
                                ) RETURN C_SALE_NO_COMUNICATI
IS
C_SALE C_SALE_NO_COMUNICATI;
BEGIN
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI( p_data_rif, p_data_rif );
    PA_CD_ADV_CINEMA.IMPOSTA_SALA(null); 
    OPEN C_SALE FOR
        SELECT 
            DISTINCT (CD_SALA.ID_SALA),
            CD_SALA.ID_CINEMA
        FROM
            CD_SALA,
            CD_CINEMA,
            CD_SCHERMO,
            CD_PROIEZIONE            
        WHERE   CD_CINEMA.ID_CINEMA         = CD_SALA.ID_CINEMA
        AND     CD_SCHERMO.ID_SALA          = CD_SALA.ID_SALA
        AND     CD_PROIEZIONE.ID_SCHERMO    = CD_SCHERMO.ID_SCHERMO
        AND     CD_CINEMA.FLG_VIRTUALE      = 'N'
        AND     CD_CINEMA.FLG_ANNULLATO     = 'N'
        --AND     CD_CINEMA.FLG_ATTIVO        = 'S'
        AND     CD_CINEMA.DATA_INIZIO_VALIDITA <= trunc(p_data_rif)
        AND     nvl(CD_CINEMA.DATA_FINE_VALIDITA, trunc(p_data_rif)) >= trunc(p_data_rif)      
        AND     CD_SALA.FLG_ANNULLATO       = 'N'
        AND     CD_SALA.FLG_VISIBILE        = 'S'
        AND     CD_SALA.FLG_ARENA           = 'N'
        AND     ( ( CD_SALA.DATA_FINE_VALIDITA IS NULL ) OR ( p_data_rif <= CD_SALA.DATA_FINE_VALIDITA ) )
                    MINUS
        SELECT
            DISTINCT(CD_SALA.ID_SALA),
            CD_SALA.ID_CINEMA
        FROM 
            VI_CD_COMUNICATO_PREVISTO,
            CD_SALA
        WHERE   VI_CD_COMUNICATO_PREVISTO.ID_SALA = CD_SALA.ID_SALA;    
    RETURN C_SALE;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20047, 'FU_SALE_NO_COMUNICATI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_SALE_NO_COMUNICATI;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ELENCO_SALE_OVER_MIN
-- Restituisce l'elenco delle sale che hanno tutti i break sopra la durata minima.
-- Questo corrisponde all'elenco delle sale alle quali inviare la playlist.
--      All'interno del BREAK TRAILER vengono considerati i break
--          LOCALE
--          FRAME SCREEN
--          TRAILER
--      All'interno del BREAK INIZIO FILM vengono considerati i break
--          INIZIO FILM
--          SEGUI IL FILM
--          TOP SPOT
-- --------------------------------------------------------------------------------------------
-- INPUT:  p_data                data di riferimento della proiezione prevista
--         p_id_sala             sala di riferimento (null per tutte le sale)
-- OUTPUT: 
--          Lista di C_DETT_DURATA_COM_SALE
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 13 Giugno 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_SALE_OVER_MIN(       p_data              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                        p_id_sala           CD_SALA.ID_SALA%TYPE
                                ) RETURN C_SALA
IS
C_RETURN C_SALA;
BEGIN
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data,p_data);
    OPEN C_RETURN FOR
        SELECT
            ID_SALA
        FROM (
            --DEI DUE RISULTATI PRENDO SOLTANTO QUELLI CHE SODDISFANO I REQUISITI
            --MINIMI DI SECONDAGGIO BREAK PER L'INVIO
            SELECT 
               DISTINCT ID_SALA, 
               COUNT(*) AS NUM_BREAK_SOPRA_MINIMO
            FROM
                (
                --PRENDO SOLAMENTE I VALORI MINIMI PER SALA/TIPO BREAK
                --SE QUESTI SODDISFANO LE CONDIZIONI DI INVIO PLAYLIST ALLORA
                --LA SALA E' COPERTA (DUE RECORD PER SALA)
                SELECT 
                    RAGGRUPPAMENTO_MINIMO.ID_SALA,
                    RAGGRUPPAMENTO_MINIMO.ID_TIPO_BREAK,
                    MIN(RAGGRUPPAMENTO_MINIMO.DURATA_TOT_BREAK) AS DURATA_TOT_BREAK
                 FROM  
                    (
                    -- QUI RAGGRUPPO E SOMMO PER PROIEZIONI E TIPOLOGIE BREAK
                    -- HO QUATTRO RECORD PER OGNI SALA (2 PROIEZIONI x 2 BREAK)        
                    SELECT 
                        PROIEZIONE_E_RAGGRUPPAMENTO.ID_SALA,
                        PROIEZIONE_E_RAGGRUPPAMENTO.ID_TIPO_BREAK,
                        SUM(PROIEZIONE_E_RAGGRUPPAMENTO.DURATA_BREAK) AS DURATA_TOT_BREAK,
                        PROIEZIONE_E_RAGGRUPPAMENTO.ID_PROIEZIONE
                    FROM
                        (
                        --ELENCO SALE E PROIEZIONI DA RAGGRUPPARE PER TIPOLOGIA BREAK               
                        SELECT
                            LISTA_BREAK.ID_SALA,
                            CASE
                                --LOCALE
                                WHEN CD_BREAK.ID_TIPO_BREAK = 3     
                                    THEN (SELECT ID_TIPO_BREAK FROM CD_TIPO_BREAK WHERE DESC_TIPO_BREAK LIKE '%Trailer%')
                                --FRAME SCREEN
                                WHEN CD_BREAK.ID_TIPO_BREAK = 4     
                                    THEN (SELECT ID_TIPO_BREAK FROM CD_TIPO_BREAK WHERE DESC_TIPO_BREAK LIKE '%Trailer%')
                                --TRAILER
                                WHEN CD_BREAK.ID_TIPO_BREAK = 1     
                                    THEN (SELECT ID_TIPO_BREAK FROM CD_TIPO_BREAK WHERE DESC_TIPO_BREAK LIKE '%Trailer%')
                                --INIZIO FILM
                                WHEN CD_BREAK.ID_TIPO_BREAK = 2     
                                    THEN (SELECT ID_TIPO_BREAK FROM CD_TIPO_BREAK WHERE DESC_TIPO_BREAK LIKE '%Inizio Film%')
                                --SEGUI FILM
                                WHEN CD_BREAK.ID_TIPO_BREAK = 25    
                                    THEN (SELECT ID_TIPO_BREAK FROM CD_TIPO_BREAK WHERE DESC_TIPO_BREAK LIKE '%Inizio Film%')
                                --TOP SPOT
                                WHEN CD_BREAK.ID_TIPO_BREAK = 5     
                                    THEN (SELECT ID_TIPO_BREAK FROM CD_TIPO_BREAK WHERE DESC_TIPO_BREAK LIKE '%Inizio Film%')
                            END ID_TIPO_BREAK,
                            LISTA_BREAK.DURATA_BREAK,
                            CD_PROIEZIONE.ID_PROIEZIONE
                        FROM
                            (
                            -- ELENCO DEI BREAK (CON LA SUA DURATA) PER OGNI SALA                
                            SELECT
                                CD_COMUNICATO.ID_SALA, 
                                CD_COMUNICATO.ID_BREAK, 
                                SUM(CD_MATERIALE.DURATA) AS DURATA_BREAK
                            FROM
                                CD_COMUNICATO,
                                CD_BREAK,
                                CD_TIPO_BREAK,
                                CD_PRODOTTO_ACQUISTATO,    
                                CD_MATERIALE_DI_PIANO,
                                CD_MATERIALE,
                                CD_SALA,
                                CD_CINEMA
                            WHERE CD_COMUNICATO.DATA_EROGAZIONE_PREV = p_data
                            AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
                            AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                            AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
                            AND CD_COMUNICATO.ID_BREAK = CD_BREAK.ID_BREAK
                            AND CD_BREAK.FLG_ANNULLATO = 'N'
                            AND CD_BREAK.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
                            AND CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                            AND CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
                            AND CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO = CD_COMUNICATO.ID_MATERIALE_DI_PIANO
                            AND CD_MATERIALE_DI_PIANO.ID_MATERIALE = CD_MATERIALE.ID_MATERIALE
                            AND CD_COMUNICATO.ID_SALA = nvl( p_id_sala, CD_COMUNICATO.ID_SALA )
                            AND CD_COMUNICATO.ID_SALA = CD_SALA.ID_SALA
                            AND CD_SALA.FLG_VISIBILE = 'S'
                            AND CD_SALA.FLG_ANNULLATO = 'N'
                            AND CD_SALA.FLG_ARENA = 'N'
                            AND CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                            AND CD_CINEMA.FLG_VIRTUALE = 'N'
                            GROUP BY CD_COMUNICATO.ID_SALA, CD_COMUNICATO.ID_BREAK
                            ) LISTA_BREAK,
                            CD_BREAK,
                            CD_PROIEZIONE
                        WHERE CD_BREAK.ID_BREAK = LISTA_BREAK.ID_BREAK
                        AND CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
                        ) PROIEZIONE_E_RAGGRUPPAMENTO
                    GROUP BY PROIEZIONE_E_RAGGRUPPAMENTO.ID_SALA, PROIEZIONE_E_RAGGRUPPAMENTO.ID_TIPO_BREAK, PROIEZIONE_E_RAGGRUPPAMENTO.ID_PROIEZIONE
                    ORDER BY PROIEZIONE_E_RAGGRUPPAMENTO.ID_SALA, PROIEZIONE_E_RAGGRUPPAMENTO.ID_PROIEZIONE
                    ) RAGGRUPPAMENTO_MINIMO
                    GROUP BY RAGGRUPPAMENTO_MINIMO.ID_SALA, RAGGRUPPAMENTO_MINIMO.ID_TIPO_BREAK
            ) RAGGRUPPAMENTO_TOTALE,
            CD_TIPO_BREAK
            WHERE CD_TIPO_BREAK.ID_TIPO_BREAK = RAGGRUPPAMENTO_TOTALE.ID_TIPO_BREAK
            AND RAGGRUPPAMENTO_TOTALE.DURATA_TOT_BREAK >= CD_TIPO_BREAK.DURATA_MINIMA
            GROUP BY ID_SALA
            )
        WHERE NUM_BREAK_SOPRA_MINIMO = 2;
    RETURN C_RETURN;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20047, 'FU_ELENCO_SALE_OVER_MIN: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_ELENCO_SALE_OVER_MIN;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STATO_PLAYLIST
-- Restituisce l'elenco delle sale e il loro stato di sincronizzazione basandosi sulla vista
-- VI_CD_STATO_PLAYLIST.
-- --------------------------------------------------------------------------------------------
-- INPUT:  p_data_inizio         data inizio
--         p_data_fine           data fine
--         p_vs_sync_status      filtro di ricerca stato sync vs (1=sync 0=no sync)
--         p_vp_sync_status      filtro di ricerca stato sync vp (1=sync 0=no sync)
-- OUTPUT: 
--          Lista di C_STATO_PLAYLIST
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 13 Settembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STATO_PLAYLIST(     
                                p_data_inizio       CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                p_data_fine         CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                p_vs_sync_status    VI_CD_STATO_PLAYLIST.VS_SYNC%TYPE,
                                p_vp_sync_status    VI_CD_STATO_PLAYLIST.VP_SYNC%TYPE
                          ) RETURN C_STATO_PLAYLIST
IS
C_RETURN C_STATO_PLAYLIST;
BEGIN
    PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data_inizio,p_data_fine);
    OPEN C_RETURN FOR
        SELECT
            VI_CD_STATO_PLAYLIST.DATA_COMMERCIALE,
            CD_CINEMA.NOME_CINEMA,
            CD_COMUNE.COMUNE,
            CD_SALA.NOME_SALA,
            CD_CINEMA.ID_CINEMA,
            CD_SALA.ID_SALA,
            CD_ADV_CINEMA.IP_VIDEOSERVER,
            CD_ADV_SALA.IP_VIDEOPLAYER,
            VI_CD_STATO_PLAYLIST.COMUNICATI_SYNC,
            VI_CD_STATO_PLAYLIST.FASCE_SYNC,
            VI_CD_STATO_PLAYLIST.VS_SYNC,
            VI_CD_STATO_PLAYLIST.VP_SYNC
        FROM
            CD_SALA,
            CD_CINEMA,
            CD_COMUNE,
            CD_ADV_CINEMA,
            CD_ADV_SALA,
            VI_CD_STATO_PLAYLIST
        WHERE CD_SALA.ID_SALA IN    (    
                                        SELECT 
                                            DISTINCT ID_SALA
                                        FROM 
                                            VI_CD_STATO_PLAYLIST
                                        WHERE   VS_SYNC = nvl(p_vs_sync_status, VI_CD_STATO_PLAYLIST.VS_SYNC) 
                                        AND     VP_SYNC = nvl(p_vp_sync_status, VI_CD_STATO_PLAYLIST.VP_SYNC)
                                    )
        AND CD_CINEMA.ID_COMUNE             = CD_COMUNE.ID_COMUNE
        AND CD_CINEMA.ID_CINEMA             = CD_ADV_CINEMA.ID_CINEMA
        AND CD_SALA.ID_CINEMA               = CD_CINEMA.ID_CINEMA
        AND CD_ADV_SALA.ID_SALA             = CD_SALA.ID_SALA
        AND VI_CD_STATO_PLAYLIST.ID_SALA    = CD_SALA.ID_SALA
        ORDER BY
            DATA_COMMERCIALE,
            NOME_CINEMA, 
            COMUNE, 
            NOME_SALA;
    RETURN C_RETURN;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20047, 'FU_STATO_PLAYLIST: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_STATO_PLAYLIST;

END PA_CD_PLAYLIST; 
/

