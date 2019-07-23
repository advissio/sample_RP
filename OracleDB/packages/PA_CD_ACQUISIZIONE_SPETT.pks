CREATE OR REPLACE PACKAGE VENCD.PA_CD_ACQUISIZIONE_SPETT IS

v_stampa_acquisizione             VARCHAR2(3):='ON';
TYPE R_SPETT_SALA IS RECORD
(
    a_id_sala               CD_SALA.ID_SALA%TYPE,
    a_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_sala             CD_SALA.NOME_SALA%TYPE,
    a_comune                CD_COMUNE.COMUNE%TYPE,
    a_tot_spettatori        NUMBER,
    a_nome_circuito         cd_circuito.nome_circuito%type,
    a_data_inizio           DATE,
    a_data_fine             DATE,
    a_data_rif              DATE
);
TYPE C_SPETT_SALA IS REF CURSOR RETURN R_SPETT_SALA;

TYPE R_SPETT_CINEMA IS RECORD
(
    a_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
    a_comune                CD_COMUNE.COMUNE%TYPE,
    a_provincia             CD_PROVINCIA.PROVINCIA%TYPE,
    a_regione               CD_REGIONE.NOME_REGIONE%TYPE,
    a_ragione_sociale       interl_u.RAG_SOC_COGN%TYPE,
    a_tipo_cinema           CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_tot_spettatori        NUMBER,
    a_data_inizio           DATE,
    a_data_fine             DATE,
    a_data_rif              DATE
);
TYPE C_SPETT_CINEMA IS REF CURSOR RETURN R_SPETT_CINEMA;

TYPE R_SPETT_CIRCUITO IS RECORD
(
    a_nome_circuito         cd_circuito.nome_circuito%type,
    a_tot_cinema            NUMBER,
    a_tot_sale              NUMBER,
    a_tot_spettatori        NUMBER,
    a_data_inizio           DATE,
    a_data_fine             DATE,
    a_data_rif              DATE
);
TYPE C_SPETT_CIRCUITO IS REF CURSOR RETURN R_SPETT_CIRCUITO;

TYPE R_SPETT_ESERCENTE IS RECORD
(
    a_ragione_sociale       interl_u.RAG_SOC_COGN%TYPE,
    a_tot_cinema            NUMBER,
    a_tot_sale              NUMBER,
    a_tot_spettatori        NUMBER,
    a_data_inizio           DATE,
    a_data_fine             DATE,
    a_data_rif              DATE
);
TYPE C_SPETT_ESERCENTE IS REF CURSOR RETURN R_SPETT_ESERCENTE;

TYPE R_SPETT_FILM IS RECORD
(
    a_nome_spettacolo       CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_DESC_GENERE             cd_genere.DESC_GENERE%type,
    a_target                  varchar2(1000),
    a_tot_cinema            NUMBER,
    a_tot_sale              NUMBER,
    a_tot_spettatori        NUMBER,
    a_data_inizio           DATE,
    a_data_fine             DATE
);
TYPE C_SPETT_FILM IS REF CURSOR RETURN R_SPETT_FILM;
--
TYPE R_SPETT_GENERE IS RECORD
(
    a_DESC_GENERE             cd_genere.DESC_GENERE%type,
    a_tot_cinema            NUMBER,
    a_tot_sale              NUMBER,
    a_tot_spettatori        NUMBER,
    a_data_inizio           DATE,
    a_data_fine             DATE
);
TYPE C_SPETT_GENERE IS REF CURSOR RETURN R_SPETT_GENERE;
--
TYPE R_SPETT_NIELSEN IS RECORD
(
    a_area_nielsen          CD_AREA_NIELSEN.DESC_AREA%TYPE,
    a_tot_cinema            NUMBER,
    a_tot_sale              NUMBER,
    a_tot_spettatori        NUMBER,
    a_data_inizio           DATE,
    a_data_fine             DATE,
    a_data_rif              DATE
);
TYPE C_SPETT_NIELSEN IS REF CURSOR RETURN R_SPETT_NIELSEN;

TYPE R_SPETT_TIPOCINEMA IS RECORD
(
    a_area_nielsen          CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_tot_cinema            NUMBER,
    a_tot_sale              NUMBER,
    a_tot_spettatori        NUMBER,
    a_data_inizio           DATE,
    a_data_fine             DATE,
    a_data_rif              DATE
);
TYPE C_SPETT_TIPOCINEMA IS REF CURSOR RETURN R_SPETT_TIPOCINEMA;

TYPE R_PRO_SALA_LIQUIDAZ IS RECORD
(
    a_id_sala               CD_SALA.ID_SALA%TYPE,
    a_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_sala             CD_SALA.NOME_SALA%TYPE,
    a_comune                CD_COMUNE.COMUNE%TYPE,
    a_tot_spettatori        NUMBER,
    a_data_rif              DATE,
    a_proiezione_pubb       cd_liquidazione_sala.FLG_PROIEZIONE_PUBB%type,
    a_id_codice_resp        cd_liquidazione_sala.id_codice_resp%type,
    a_cod_resp              VARCHAR2(30),
    a_motivazione           VARCHAR2(200),
    a_flg_programmazione    cd_liquidazione_sala.FLG_PROGRAMMAZIONE%TYPE,
    a_decurtazione          cd_codice_resp.AGGREGAZIONE%TYPE,
    a_desc_cinetel          cd_causale_cinetel.DESC_CINETEL%TYPE,
    a_id_causale_prev       cd_codice_resp.id_codice_resp%type
);
TYPE C_PRO_SALA_LIQUIDAZ IS REF CURSOR RETURN R_PRO_SALA_LIQUIDAZ;


TYPE R_CODICE_RESP IS RECORD
(
    a_id_codice_resp        cd_CODICE_RESP.ID_CODICE_RESP%type,
    a_desc_codice           cd_codice_resp.DESC_CODICE%TYPE,
    a_problematica          cd_codice_resp.PROBLEMATICA%type,
    a_aggregazione          cd_codice_resp.AGGREGAZIONE%type
);
TYPE C_CODICE_RESP IS REF CURSOR RETURN R_CODICE_RESP;
--
TYPE R_CAUSALE_CINETEL IS RECORD
(
    a_id_cinetel            CD_CAUSALE_CINETEL.ID_CINETEL%type,
    a_desc_cinetel          CD_CAUSALE_CINETEL.DESC_CINETEL%TYPE
);
TYPE C_CAUSALE_CINETEL IS REF CURSOR RETURN R_CAUSALE_CINETEL;
--
TYPE R_CONFRONTO_SALA IS RECORD
(
    a_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
    a_id_sala               CD_SALA.ID_SALA%TYPE,
    a_nome_cinema           VARCHAR2(200),
    a_nome_sala             CD_SALA.NOME_SALA%TYPE,
    a_mese                  VARCHAR2(20),
    a_tot_spettatori        VARCHAR2(200)
);
TYPE C_CONFRONTO_SALA IS REF CURSOR RETURN R_CONFRONTO_SALA;
TYPE R_CONFRONTO_CINEMA IS RECORD
(
    a_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema           VARCHAR2(200),
    a_mese                  VARCHAR2(20),
    a_tot_spettatori        VARCHAR2(200)
);
TYPE C_CONFRONTO_CINEMA IS REF CURSOR RETURN R_CONFRONTO_CINEMA;
TYPE R_CONFRONTO_CIRCUITO IS RECORD
(
    a_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito         VARCHAR2(200),
    a_mese                  VARCHAR2(20),
    a_tot_spettatori        VARCHAR2(200)
);
TYPE C_CONFRONTO_CIRCUITO IS REF CURSOR RETURN R_CONFRONTO_CIRCUITO;
--
TYPE R_CONFRONTO_ESERCENTE IS RECORD
(
    a_cod_esercente         VARCHAR2(200),
    a_ragione_sociale       VARCHAR2(200),
    a_mese                  VARCHAR2(20),
    a_tot_spettatori        VARCHAR2(200)
);
TYPE C_CONFRONTO_ESERCENTE IS REF CURSOR RETURN R_CONFRONTO_ESERCENTE;
--
TYPE R_CONFRONTO_GRUPPO IS RECORD
(
    a_id_gruppo_esercente   VARCHAR2(200),
    a_nome_gruppo           VARCHAR2(200),
    a_mese                  VARCHAR2(20),
    a_tot_spettatori        VARCHAR2(200)
);
TYPE C_CONFRONTO_GRUPPO IS REF CURSOR RETURN R_CONFRONTO_GRUPPO;
--
TYPE R_CONFRONTO_TIPO_CINEMA IS RECORD
(
    a_id_tipo_cinema         VARCHAR2(200),
    a_desc_tipo_cinema       VARCHAR2(200),
    a_mese                   VARCHAR2(20),
    a_tot_spettatori         VARCHAR2(200)
);
TYPE C_CONFRONTO_TIPO_CINEMA IS REF CURSOR RETURN R_CONFRONTO_TIPO_CINEMA;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ALLINEA_DATI_ACQUISITI
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ALLINEA_DATI_ACQUISITI(p_esito OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_CINEMA_GIORNO
-- --------------------------------------------------------------------------------------------
/*
FUNCTION FU_SPETT_CINEMA_GIORNO(  p_data_inizio         DATE,
                                  p_data_fine           DATE,
                                  p_id_cinema           CD_CINEMA.ID_CINEMA%TYPE
                               )  RETURN VARCHAR2;
*/
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_CINEMA_SETTIMANA
-- --------------------------------------------------------------------------------------------
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
                                   ) RETURN C_SPETT_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_SALA_SETTIMANA
-- --------------------------------------------------------------------------------------------
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
                                )RETURN C_SPETT_SALA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_SALA_SETTIMANA
-- --------------------------------------------------------------------------------------------
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
                               )RETURN C_SPETT_CIRCUITO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_ESERCENTE_SETTIMANA
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
                                )RETURN C_SPETT_ESERCENTE;
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
                                )RETURN C_SPETT_NIELSEN;
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
                                )RETURN C_SPETT_FILM;
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
                                )RETURN C_SPETT_GENERE;
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
                                )RETURN C_SPETT_TIPOCINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_PARAMETRI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_PARAMETRI(    p_data_riferimento         CD_SPETTATORI_EFF.DATA_RIFERIMENTO%TYPE,
                                 p_num_spettatori           CD_SPETTATORI_EFF.NUM_SPETTATORI%TYPE,
                                 p_id_sala                  CD_SPETTATORI_EFF.ID_SALA%TYPE
                                 )  RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_PRO_SALA_LIQUIDAZIONE
-- --------------------------------------------------------------------------------------------
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
                                     ) RETURN C_PRO_SALA_LIQUIDAZ;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CODICI_RESP
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CODICI_RESP RETURN C_CODICE_RESP;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CODICI_RESP
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALI_TECNICHE RETURN C_CODICE_RESP;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CODICI_RESP
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALI_AMMINISTRATIVE RETURN C_CODICE_RESP;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_PRO_SALA_LIQUID
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_IMPOSTA_CAUSALE_DEF(  p_id_sala               cd_liquidazione_sala.ID_SALA%TYPE,
                                   p_data_rif              cd_liquidazione_sala.DATA_RIF%TYPE,
                                   p_id_codice_resp        cd_liquidazione_sala.id_codice_resp%type,
                                   p_motivazione           cd_liquidazione_sala.motivazione%type,
                                   p_esito OUT NUMBER);
FUNCTION FU_GET_CAUSALI_CINETEL RETURN C_CAUSALE_CINETEL;

FUNCTION FU_CONFRONTO_SPETT_SALA(  p_id_circuito        CD_CIRCUITO.id_CIRCUITO%TYPE,
                                   p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                   p_id_sala            CD_SALA.ID_SALA%TYPE,
                                   p_data_inizio        DATE,
                                   p_data_fine          DATE
                                ) return C_CONFRONTO_SALA;
FUNCTION FU_CONFRONTO_SPETT_CINEMA(    p_id_circuito        CD_CIRCUITO.id_CIRCUITO%TYPE,
                                       p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                       p_data_inizio        DATE,
                                       p_data_fine          DATE
                                    ) return C_CONFRONTO_CINEMA;
FUNCTION FU_CONFRONTO_SPETT_CIRCUITO(  p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_data_inizio        DATE,
                                       p_data_fine          DATE
                                    ) return C_CONFRONTO_CIRCUITO;
FUNCTION FU_CONFRONTO_SPETT_ESERCENTE(  p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                        p_id_sala            CD_SALA.ID_SALA%TYPE,
                                        p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_data_inizio        DATE,
                                        p_data_fine          DATE
                                      ) return C_CONFRONTO_ESERCENTE;
FUNCTION FU_CONFRONTO_SPETT_ESERCENTE_T(  p_id_cinema            CD_CINEMA.ID_CINEMA%TYPE,
                                        p_id_sala                   CD_SALA.ID_SALA%TYPE,
                                        p_id_circuito               CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_data_inizio_rif           DATE,
                                        p_data_fine_rif             DATE,
                                        p_data_inizio_conf          DATE,
                                        p_data_fine_conf            DATE
                                      ) return C_CONFRONTO_ESERCENTE;                                      
FUNCTION FU_CONFRONTO_SPETT_TIPO_CINEMA(  p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                          p_id_sala            CD_SALA.ID_SALA%TYPE,
                                          p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                          p_data_inizio        DATE,
                                          p_data_fine          DATE
                                      ) return C_CONFRONTO_TIPO_CINEMA;
FUNCTION FU_CONFRONTO_SPETT_GRUPPO(  p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                     p_id_sala            CD_SALA.ID_SALA%TYPE,
                                     p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                     p_data_inizio        DATE,
                                     p_data_fine          DATE
                                   ) return C_CONFRONTO_GRUPPO;                                      
PROCEDURE PR_ALLINEA_NUMERO_SPETTATORI(p_id_sala cd_spettatori_eff.ID_SALA%type, p_data_riferimento cd_spettatori_eff.DATA_RIFERIMENTO%type, p_num_spettatori cd_spettatori_eff.NUM_SPETTATORI%type);

PROCEDURE PR_ALLINEA_FATTO_SPETTATORI(p_data_inizio  DATE, p_data_fine DATE);

END PA_CD_ACQUISIZIONE_SPETT; 
/

