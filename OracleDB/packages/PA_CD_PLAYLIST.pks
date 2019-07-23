CREATE OR REPLACE PACKAGE VENCD.PA_CD_PLAYLIST AS
--
TYPE R_STATO_PLAYLIST_PERIODO IS RECORD
(
    a_data_commerciale    DATE,
    a_sale_vendute        NUMBER,
    a_sale_allineate      NUMBER,
    a_vp_ok               NUMBER,
    a_vs_ok               NUMBER,
    a_vs_tot              NUMBER,
    a_sale_disp           NUMBER,
    a_sale_senza_playlist NUMBER
);
TYPE C_STATO_PLAYLIST_PERIODO IS REF CURSOR RETURN R_STATO_PLAYLIST_PERIODO;
--
TYPE R_LAST_PLAYLIST IS RECORD
(
    a_data_commerciale    DATE,
    a_id_sala             NUMBER,
    a_data_modifica       DATE,
    a_id_playlist         NUMBER,
    a_id_proiezione       NUMBER,
    a_id_break            NUMBER,
    a_tipo                NUMBER,
    a_id_comunicato       NUMBER,
    a_id_materiale        VI_CD_MATERIALE.ID%TYPE,
    a_desc_sogg           VI_CD_COMUNICATO.DES_SOGG%TYPE,
    a_posizione           VI_CD_COMUNICATO.POSIZIONE%TYPE,
    a_posizione_relativa  NUMBER,
    a_durata              VI_CD_MATERIALE.DURATA%TYPE,
    a_cliente             VI_CD_CLIENTE.RAG_SOC_COGN%TYPE,
    a_fasce               VARCHAR2(20)
);
TYPE C_LAST_PLAYLIST IS REF CURSOR RETURN R_LAST_PLAYLIST;
--
TYPE R_GET_PLAYLIST IS RECORD
(
    a_data_commerciale    DATE,
    a_id_sala             NUMBER,
    a_data_modifica       DATE,
    a_id_playlist         NUMBER,
    a_id_proiezione       NUMBER,
    a_id_break            NUMBER,
    a_tipo                NUMBER,
    a_id_comunicato       NUMBER,
    a_id_materiale        VI_CD_MATERIALE.ID%TYPE,
    a_desc_sogg           VI_CD_COMUNICATO.DES_SOGG%TYPE,
    a_posizione           VI_CD_COMUNICATO.POSIZIONE%TYPE,
    a_posizione_relativa  NUMBER,
    a_durata              VI_CD_MATERIALE.DURATA%TYPE,
    a_cliente             VI_CD_CLIENTE.RAG_SOC_COGN%TYPE,
    a_fasce               VARCHAR2(20)
);
TYPE C_GET_PLAYLIST IS REF CURSOR RETURN R_GET_PLAYLIST;
--
TYPE R_VERIFICA_PROIEZIONI IS RECORD
(
    a_data_commerciale      DATE,
    a_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
    a_id_sala               CD_SALA.ID_SALA%TYPE,
    a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_sala             CD_SALA.NOME_SALA%TYPE,
    a_comune                CD_COMUNE.COMUNE%TYPE,
    a_programmata           NUMBER,
    a_proiezioni_ok         NUMBER,
    a_proiezioni_err        NUMBER,
    a_proiezioni_test       NUMBER,
    a_stato                 NUMBER,
    a_id_causale_prev       CD_CODICE_RESP.ID_CODICE_RESP%type,
    a_causale_prev          CD_CODICE_RESP.DESC_CODICE%type,
    a_id_causale_def        CD_CODICE_RESP.ID_CODICE_RESP%type,
    a_causale_def           CD_CODICE_RESP.DESC_CODICE%type,
    a_tot_spettatori        number,
    a_nota                  cd_liquidazione_sala.motivazione%type,
    a_stato_sala            cd_adv_sala.STATO%type
);
TYPE C_VERIFICA_PROIEZIONI IS REF CURSOR RETURN R_VERIFICA_PROIEZIONI;
--
TYPE R_VERIFICA_PROIEZIONI_DETT IS RECORD
(
    a_id_sala                 NUMBER,
    a_id_proiezione           NUMBER,
    a_id_comunicato           NUMBER,
    a_id_tipo_break           NUMBER,
    a_durata_break_prev       NUMBER,
    a_progressivo             NUMBER,
    a_data_inizio_proiezione  DATE,
    a_data_inizio_break       DATE,
    a_data_erogazione_eff     DATE,
    a_durata_break_eff        NUMBER,
    a_id_materiale            NUMBER,
    a_durata_prev             NUMBER,
    a_durata_eff              NUMBER,
    a_durata_ok               NUMBER,
    a_fascia_ok               NUMBER,
    a_proiezione_ok           NUMBER,
    a_break_ok                NUMBER,
    a_com_test                NUMBER,
    a_cliente                 VI_CD_CLIENTE.RAG_SOC_COGN%TYPE,
    a_titolo                  CD_MATERIALE.TITOLO%TYPE,
    a_soggetto                CD_MATERIALE_SOGGETTI.DES_SOGG%TYPE,
    a_id_fascia               NUMBER
);
TYPE C_VERIFICA_PROIEZIONI_DETT IS REF CURSOR RETURN R_VERIFICA_PROIEZIONI_DETT;


TYPE R_MANCATA_PROIEZIONE IS RECORD
(
  a_nome_esercente vi_cd_societa_esercente.RAGIONE_SOCIALE%type,
  a_nome_cinema cd_cinema.nome_cinema%type, 
  a_comune cd_comune.comune%type, 
  a_nome_sala cd_sala.nome_sala%type, 
  a_data varchar(10),  
  a_problema varchar2(100),  
  a_nota varchar2 (100)
);

TYPE C_MANCATA_PROIEZIONE IS REF CURSOR RETURN R_MANCATA_PROIEZIONE;

TYPE R_INFO_GESTORI IS RECORD
(
    a_data_modifica     CD_ADV_SNAPSHOT_PLAYLIST.DATA_MODIFICA%TYPE,
    a_data_commerciale  CD_ADV_SNAPSHOT_PLAYLIST.DATA_COMMERCIALE%TYPE,
    a_id_cinema         VI_CD_INFO_GESTORE_SALA.ID_CINEMA%TYPE,
    a_nome_cinema       VI_CD_INFO_GESTORE_SALA.NOME_CINEMA%TYPE,
    a_id_sala           VI_CD_INFO_GESTORE_SALA.ID_SALA%TYPE,
    a_nome_sala         VI_CD_INFO_GESTORE_SALA.NOME_SALA%TYPE,
    a_email             VI_CD_INFO_GESTORE_SALA.EMAIL%TYPE
);
TYPE C_INFO_GESTORI IS REF CURSOR RETURN R_INFO_GESTORI;

TYPE R_INFO_SPETTACOLI IS RECORD
(
    a_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
    a_id_sala            CD_SALA.ID_SALA%TYPE,
    a_ragione_sociale    vi_cd_societa_esercente.ragione_sociale%TYPE,
    a_email              gestori_utente.EMAIL%TYPE,
    a_id_spettacolo      cd_spettacolo.id_spettacolo%TYPE,
    a_flg_protetto       cd_spettacolo.FLG_PROTETTO%type,
    a_nome_spettacolo    cd_spettacolo.nome_spettacolo%TYPE,
    a_desc_target        cd_target.DESCR_TARGET%type,
    a_desc_genere        cd_genere.DESC_GENERE%type,
    a_numero_proiezioni  NUMBER,
    a_orario             varchar2(20)
);
TYPE C_INFO_SPETTACOLI IS REF CURSOR RETURN R_INFO_SPETTACOLI;

TYPE R_SALE_NO_COMUNICATI IS RECORD
(
    a_id_sala            CD_SALA.ID_SALA%TYPE,
    a_id_cinema          CD_CINEMA.ID_CINEMA%TYPE
);
TYPE C_SALE_NO_COMUNICATI IS REF CURSOR RETURN R_SALE_NO_COMUNICATI;

TYPE R_DETT_DURATA_COM_SALE IS RECORD
(
    a_id_sala               CD_SALA.ID_SALA%TYPE,
    a_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
    a_durata_totale_break   NUMBER,
    a_id_proiezione         CD_PROIEZIONE.ID_PROIEZIONE%TYPE
);
TYPE C_DETT_DURATA_COM_SALE IS REF CURSOR RETURN R_DETT_DURATA_COM_SALE;

TYPE R_SALA IS RECORD
(
    a_id_sala            CD_SALA.ID_SALA%TYPE
);
TYPE C_SALA IS REF CURSOR RETURN R_SALA;

TYPE R_STATO_PLAYLIST IS RECORD
(
    a_data_commerciale  VI_CD_STATO_PLAYLIST.DATA_COMMERCIALE%TYPE,
    a_nome_cinema       CD_CINEMA.NOME_CINEMA%TYPE,
    a_comune            CD_COMUNE.COMUNE%TYPE,
    a_nome_sala         CD_SALA.NOME_SALA%TYPE,
    a_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
    a_id_sala           CD_SALA.ID_SALA%TYPE,
    a_ip_vs             CD_ADV_CINEMA.IP_VIDEOSERVER%TYPE,
    a_ip_vp             CD_ADV_SALA.IP_VIDEOPLAYER%TYPE,
    a_comunicati_sync   VI_CD_STATO_PLAYLIST.COMUNICATI_SYNC%TYPE,
    a_fasce_sync        VI_CD_STATO_PLAYLIST.FASCE_SYNC%TYPE,
    a_vs_sync           VI_CD_STATO_PLAYLIST.VS_SYNC%TYPE,
    a_vp_sync           VI_CD_STATO_PLAYLIST.VP_SYNC%TYPE
);
TYPE C_STATO_PLAYLIST IS REF CURSOR RETURN R_STATO_PLAYLIST;
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STATO_PLAYLIST_PERIODO
-- Fornisce delle statistiche di sintesi sulle sale relative a un certo intervallo di date
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
FUNCTION FU_STATO_PLAYLIST_PERIODO(p_data_inizio DATE, p_data_fine DATE) RETURN C_STATO_PLAYLIST_PERIODO;
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
-- MODIFICHE
--              Tommaso D'Anna, Teoresi srl, 16 Settembre 2011
--                  Aggiunto il cappello per reperire correttamente il numero di VS allineati completamente.
--                  La funzione in precedenza considerava allineato un VS che aveva anche una sola playlist
--                  allineata.
--  
FUNCTION FU_LAST_PLAYLIST(p_data_commerciale DATE, p_id_sala NUMBER) RETURN C_LAST_PLAYLIST;
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
-- MODIFICHE
FUNCTION FU_GET_PLAYLIST(p_data_commerciale DATE, p_id_sala NUMBER, p_data_modifica DATE) RETURN C_GET_PLAYLIST;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_PROIEZIONI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_PROIEZIONI( p_data_inizio         DATE,
                                 p_data_fine           DATE,
                                 p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                 p_id_sala             CD_SALA.ID_SALA%TYPE,
                                 p_flg_stato           INTEGER
                              ) RETURN C_VERIFICA_PROIEZIONI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_PROIEZIONI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VER_PRO_TEMPO_REALE( p_data_inizio         DATE,
                                 p_data_fine           DATE,
                                 p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                 p_id_sala             CD_SALA.ID_SALA%TYPE,
                                 p_flg_stato           INTEGER
                              ) RETURN C_VERIFICA_PROIEZIONI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_PROIEZIONI_DETTAGLIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_PROIEZIONI_DETT( p_data           DATE,
                                 p_id_sala             CD_SALA.ID_SALA%TYPE,
                                 p_id_fascia           CD_FASCIA.ID_FASCIA%TYPE
                              ) RETURN C_VERIFICA_PROIEZIONI_DETT;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_IMPOSTA_CAUSALE_PREV
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_IMPOSTA_CAUSALE_PREV(  p_id_sala               cd_sala.ID_SALA%TYPE,
                                    p_id_codice_resp        cd_codice_resp.id_codice_resp%type,
                                    p_data_inizio           DATE,
                                    p_data_fine             DATE,
                                    p_esito OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_IMPOSTA_CAUSALE_DEF
-- --------------------------------------------------------------------------------------------
/*PROCEDURE PR_IMPOSTA_CAUSALE_DEF(  p_id_sala               cd_sala.ID_SALA%TYPE,
                                   p_id_codice_resp        cd_liquidazione_sala.id_codice_resp%type,
                                   p_data                  DATE,
                                   p_esito OUT NUMBER);*/
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CONFERMA_CAUSALE_PREV
-- --------------------------------------------------------------------------------------------
/*
PROCEDURE PR_CONFERMA_CAUSALE_PREV(p_id_sala               cd_sala.ID_SALA%TYPE,
                                   p_id_codice_resp        cd_liquidazione_sala.id_codice_resp%type,
                                   p_data                  DATE,
                                   p_esito OUT NUMBER);                                   
*/
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALE_FROM_CHIUSURA_SETT
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALE_FROM_CHIUS_SETT( p_data           DATE,
                                         p_id_cinema      CD_CINEMA.ID_CINEMA%TYPE,
                                         p_id_causale     CD_CODICE_RESP.ID_CODICE_RESP%TYPE
                                        ) RETURN VARCHAR2;
--

FUNCTION FU_GET_MANCATA_PROIEZIONE(p_data_inizio date, p_data_fine date, p_cod_esercente vi_cd_societa_esercente.COD_ESERCENTE%type)  RETURN C_MANCATA_PROIEZIONE;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_GESTORI_MOD_PLAYLIST
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_GESTORI_MOD_PLAYLIST(  p_minuti_da_adesso  NUMBER,
                                        p_data_commerciale  CD_ADV_SNAPSHOT_PLAYLIST.DATA_COMMERCIALE%TYPE,
                                        p_id_sala           CD_ADV_SNAPSHOT_PLAYLIST.ID_SALA%TYPE
                                      ) RETURN C_INFO_GESTORI;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ALLINEA_VERIFICA_TRASM
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ALLINEA_VERIFICA_TRASM( p_data_inizio         DATE,
                                     p_data_fine           DATE,
                                     p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
                                     p_id_sala             CD_SALA.ID_SALA%TYPE,
                                     p_esito OUT NUMBER
                                    );
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETTACOLI_SALA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETTACOLI_SALA(  p_data_rif          cd_liquidazione_sala.DATA_RIF%TYPE,
                              p_id_sala           CD_SALA.ID_SALA%TYPE
                           ) RETURN C_INFO_SPETTACOLI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SALE_NO_COMUNICATI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALE_NO_COMUNICATI  (  
                                    p_data_rif          VI_CD_COMUNICATO_PREVISTO.DATA_COMMERCIALE%TYPE
                                ) RETURN C_SALE_NO_COMUNICATI;
                                
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
                                ) RETURN C_SALA;
                           
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
                          ) RETURN C_STATO_PLAYLIST;
                      
END PA_CD_PLAYLIST; 
/

