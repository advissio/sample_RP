CREATE OR REPLACE PACKAGE VENCD.PA_CD_SALA IS
v_stampa_sala                      VARCHAR2(3):='ON';
TYPE R_DETTAGLIO_SALA_SCHERMO IS RECORD
(
    a_id_sala                       CD_SALA.ID_SALA%TYPE,
    a_id_tipo_audio                 CD_SALA.ID_TIPO_AUDIO%TYPE,
    a_desc_tipo_audio               CD_TIPO_AUDIO.DESC_TIPO_AUDIO%TYPE,
    a_id_cinema                     CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema                   CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_sala                     CD_SALA.NOME_SALA%TYPE,
    a_numero_poltrone               CD_SALA.NUMERO_POLTRONE%TYPE,
    a_numero_proiezioni             CD_SALA.NUMERO_PROIEZIONI%TYPE,
    a_flag_arena                    CD_SALA.FLG_ARENA%TYPE,
    a_id_schermo                    CD_SCHERMO.ID_SCHERMO%TYPE,
    a_misura_larghezza              CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
    a_misura_lunghezza              CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
    a_visibile                      CD_SALA.FLG_VISIBILE%TYPE,
    a_data_inizio_validita          CD_SALA.DATA_INIZIO_VALIDITA%TYPE,
    a_data_fine_validita            CD_SALA.DATA_FINE_VALIDITA%TYPE,
    a_data_inizio_validita_cinema   CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE
);
TYPE C_DETTAGLIO_SALE_SCHERMI IS REF CURSOR RETURN R_DETTAGLIO_SALA_SCHERMO;
TYPE R_TIPO_AUDIO IS RECORD
(
    a_id_tipo_audio             CD_TIPO_AUDIO.ID_TIPO_AUDIO%TYPE,
    a_desc_tipo_audio           CD_TIPO_AUDIO.DESC_TIPO_AUDIO%TYPE
);
TYPE C_TIPO_AUDIO IS REF CURSOR RETURN R_TIPO_AUDIO;
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione delle
--              sale
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SALA( p_id_cinema                        CD_SALA.ID_CINEMA%TYPE,
                             p_id_tipo_audio                    CD_SALA.ID_TIPO_AUDIO%TYPE,
                             p_nome_sala                        CD_SALA.NOME_SALA%TYPE,
                             p_numero_poltrone                  CD_SALA.NUMERO_POLTRONE%TYPE,
                             p_numero_proiezioni                CD_SALA.NUMERO_PROIEZIONI%TYPE,
                             p_flg_arena                        CD_SALA.FLG_ARENA%TYPE,
                             p_visibile                         CD_SALA.FLG_VISIBILE%TYPE,
                             p_data_inizio_validita             CD_SALA.DATA_INIZIO_VALIDITA%TYPE,
                             p_misura_larghezza                 CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                             p_misura_lunghezza                 CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                             p_esito                            OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SALA(    p_id_sala        IN CD_SALA.ID_SALA%TYPE,
                              p_esito          OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SALA_CINEMA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SALA_CINEMA(    p_id_cinema        IN CD_CINEMA.ID_CINEMA%TYPE,
                                    p_esito            OUT NUMBER);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_SALA(p_id_sala        IN CD_SALA.ID_SALA%TYPE,
                          p_esito        OUT NUMBER,
                          p_piani_errati   OUT VARCHAR2);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_SALE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_SALE(p_lista_sale        IN id_sale_type,
                                p_esito                OUT NUMBER,
                                p_piani_errati   OUT VARCHAR2);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_SALA(p_id_sala        IN CD_SALA.ID_SALA%TYPE,
                           p_esito            OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_SALA(  p_id_sala                          CD_SALA.ID_SALA%TYPE,
                             p_id_cinema                        CD_SALA.ID_CINEMA%TYPE,
                             p_id_tipo_audio                    CD_SALA.ID_TIPO_AUDIO%TYPE,
                             p_nome_sala                        CD_SALA.NOME_SALA%TYPE,
                             p_numero_poltrone                  CD_SALA.NUMERO_POLTRONE%TYPE,
                             p_numero_proiezioni                CD_SALA.NUMERO_PROIEZIONI%TYPE,
                             p_flg_arena                        CD_SALA.FLG_ARENA%TYPE,
                             p_flg_annullato                    CD_SALA.FLG_ANNULLATO%TYPE,
                             p_visibile                         CD_SALA.FLG_VISIBILE%TYPE,
                             p_data_inizio_validita             CD_SALA.DATA_INIZIO_VALIDITA%TYPE,
                             p_data_fine_validita               CD_SALA.DATA_FINE_VALIDITA%TYPE,
                             p_id_schermo                       CD_SCHERMO.ID_SCHERMO%TYPE,
                             p_flg_sc_annullato                 CD_SCHERMO.FLG_ANNULLATO%TYPE,
                             p_misura_larghezza                 CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                             p_misura_lunghezza                 CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                             p_misura_pollici                   CD_SCHERMO.MISURA_POLLICI%TYPE,
                             p_esito                            OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_SALA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_SALA ( p_id_sala      CD_SALA.ID_SALA%TYPE )
                               RETURN C_DETTAGLIO_SALE_SCHERMI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_SALA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SALA(p_id_cinema                        CD_SALA.ID_CINEMA%TYPE,
                        p_id_tipo_audio                    CD_SALA.ID_TIPO_AUDIO%TYPE,
                        p_nome_sala                        CD_SALA.NOME_SALA%TYPE,
                        p_numero_poltrone                  CD_SALA.NUMERO_POLTRONE%TYPE,
                        p_numero_proiezioni                CD_SALA.NUMERO_PROIEZIONI%TYPE,
                        p_flg_arena                        CD_SALA.FLG_ARENA%TYPE
                        ) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_SALA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_SALA(p_id_sala   IN CD_SALA.ID_SALA%TYPE)
            RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_DESC_TIPO_AUDIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_DESC_TIPO_AUDIO(p_id_tipo_audio   IN CD_TIPO_AUDIO.ID_TIPO_AUDIO%TYPE)
            RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_TIPO_AUDIO
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_TIPO_AUDIO RETURN C_TIPO_AUDIO;
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_SALA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_SALA  (p_id_sala   IN CD_SALA.ID_SALA%TYPE)
            RETURN INTEGER;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_NUM_SALE_CIRCUITO
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_NUM_SALE_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER;

--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SALA_VENDUTA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALA_VENDUTA  (p_id_sala     IN CD_SALA.ID_SALA%TYPE)
            RETURN INTEGER;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_FINE_VALIDITA_SALA
--
-- INPUT:   p_id_sala           ID della sala di riferimento
--          p_data_fine_val     La data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 29 Aprile 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_FINE_VALIDITA_SALA(    p_id_sala           CD_SALA.ID_SALA%TYPE,
                                    p_data_fine_val     CD_SALA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER);  
END PA_CD_SALA; 
/

