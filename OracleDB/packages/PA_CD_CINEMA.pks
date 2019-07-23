CREATE OR REPLACE PACKAGE VENCD.PA_CD_CINEMA IS
v_stampa_cinema   VARCHAR2(3):='ON';
TYPE R_CINEMA IS RECORD
(
    a_id_cinema		  CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE,
    a_id_tipo_cinema  CD_CINEMA.ID_TIPO_CINEMA%TYPE,
    a_id_comune       CD_CINEMA.ID_COMUNE%TYPE,
    a_indirizzo       CD_CINEMA.INDIRIZZO%TYPE,
    a_comune          CD_COMUNE.COMUNE%TYPE,
    a_pubb_locale     CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
    a_tipo            CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_count_atrii     NUMBER(2),
    a_count_cinema    NUMBER(2),
    a_count_arene     NUMBER(2)
);
TYPE C_CINEMA IS REF CURSOR RETURN R_CINEMA;
TYPE R_DETTAGLIO_CINEMA IS RECORD
(
    a_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema               CD_CINEMA.NOME_CINEMA%TYPE,
    a_id_tipo_cinema            CD_CINEMA.ID_TIPO_CINEMA%TYPE,
    a_id_comune                 CD_CINEMA.ID_COMUNE%TYPE,
    a_comune                    CD_COMUNE.COMUNE%TYPE,
    a_locale                    CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
    a_concessione               CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE%TYPE,
    a_indirizzo                 CD_CINEMA.INDIRIZZO%TYPE,
    a_cap                       CD_CINEMA.CAP%TYPE,
    a_regione                   CD_REGIONE.NOME_REGIONE%TYPE,
    a_area_geografica           CD_AREA_GEOGRAFICA.POSIZIONE%TYPE,
    a_area_nielsen              CD_AREA_NIELSEN.DESC_AREA%TYPE,
    a_id_area_nielsen           CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
    a_id_regione                CD_REGIONE.ID_REGIONE%TYPE,
    a_id_area_geografica        CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
    a_tipo                      CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_id_atrio                  CD_ATRIO.ID_ATRIO%TYPE,
    a_desc_atrio                CD_ATRIO.DESC_ATRIO%TYPE,
    a_num_distribuzioni         CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
    a_num_esposizioni           CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
    a_num_scooter_moto          CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
    a_num_corner                CD_ATRIO.NUM_CORNER%TYPE,
    a_num_lcd                   CD_ATRIO.NUM_LCD%TYPE,
    a_num_automobili            CD_ATRIO.NUM_AUTOMOBILI%TYPE,
    a_id_sala                   CD_SALA.ID_SALA%TYPE,
    a_id_tipo_audio             CD_SALA.ID_TIPO_AUDIO%TYPE,
    a_nome_sala                 CD_SALA.NOME_SALA%TYPE,
    a_numero_poltrone           CD_SALA.NUMERO_POLTRONE%TYPE,
    a_numero_proiezioni         CD_SALA.NUMERO_PROIEZIONI%TYPE,
    a_flag_arena                CD_SALA.FLG_ARENA%TYPE,
    --a_flg_attivo                CD_CINEMA.FLG_ATTIVO%TYPE,
    a_recapito                  CD_CINEMA.RECAPITO_POSTA%TYPE,
    a_data_inizio_validita      CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE,
    a_data_fine_validita        CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
    a_flg_virtuale              CD_CINEMA.FLG_VIRTUALE%TYPE
);
TYPE C_DETTAGLIO_CINEMA IS REF CURSOR RETURN R_DETTAGLIO_CINEMA;
TYPE R_SALA IS RECORD
(
    a_id_sala                   CD_SALA.ID_SALA%TYPE,
    a_id_tipo_audio             CD_SALA.ID_TIPO_AUDIO%TYPE,
    a_desc_tipo_audio           CD_TIPO_AUDIO.DESC_TIPO_AUDIO%TYPE,
    a_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema               CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_comune               CD_COMUNE.COMUNE%TYPE,
    a_nome_sala                 CD_SALA.NOME_SALA%TYPE,
    a_numero_poltrone           CD_SALA.NUMERO_POLTRONE%TYPE,
    a_numero_proiezioni         CD_SALA.NUMERO_PROIEZIONI%TYPE,
    a_flag_arena                CD_SALA.FLG_ARENA%TYPE,
    a_visibile                  CD_SALA.FLG_VISIBILE%TYPE
);
TYPE C_SALE IS REF CURSOR RETURN R_SALA;
TYPE R_ATRIO IS RECORD
(
    a_id_atrio                  CD_ATRIO.ID_ATRIO%TYPE,
    a_desc_atrio                CD_ATRIO.DESC_ATRIO%TYPE,
    a_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema               CD_CINEMA.NOME_CINEMA%TYPE,
    a_num_distribuzioni         CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
    a_num_esposizioni           CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
    a_num_scooter_moto          CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
    a_num_corner                CD_ATRIO.NUM_CORNER%TYPE,
    a_num_lcd                   CD_ATRIO.NUM_LCD%TYPE,
    a_num_automobili            CD_ATRIO.NUM_AUTOMOBILI%TYPE
);
TYPE C_ATRII IS REF CURSOR RETURN R_ATRIO;
TYPE R_REGIONE IS RECORD
(
    a_id_regione                  CD_REGIONE.ID_REGIONE%TYPE,
    a_nome_regione                CD_REGIONE.NOME_REGIONE%TYPE
);
TYPE C_REGIONE IS REF CURSOR RETURN R_REGIONE;
TYPE R_AREA_NIELSEN IS RECORD
(
    a_id_area_nielsen          CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
    a_desc_area_nielsen        CD_AREA_NIELSEN.DESC_AREA%TYPE
);
TYPE C_AREA_NIELSEN IS REF CURSOR RETURN R_AREA_NIELSEN;
TYPE R_AREA_GEOGRAFICA IS RECORD
(
    a_id_area_geografica          CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
    a_posizione                   CD_AREA_GEOGRAFICA.POSIZIONE%TYPE
);
TYPE C_AREA_GEOGRAFICA IS REF CURSOR RETURN R_AREA_GEOGRAFICA;
TYPE R_COMUNE IS RECORD
(
    a_id_comune                  CD_COMUNE.ID_COMUNE%TYPE,
    a_comune                     CD_COMUNE.COMUNE%TYPE
);
TYPE C_COMUNE IS REF CURSOR RETURN R_COMUNE;
TYPE R_TIPO_CINEMA IS RECORD
(
    a_id_tipo_cinema          CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
    a_desc_tipo_cinema        CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE
);
TYPE C_TIPO_CINEMA IS REF CURSOR RETURN R_TIPO_CINEMA;
TYPE R_DIRETTORE IS RECORD
(
    a_id_direttore                    CD_DIRETTORE.ID_DIRETTORE%TYPE,
    a_nome                            CD_DIRETTORE.NOME%TYPE,
    a_cognome                         CD_DIRETTORE.COGNOME%TYPE,
    a_telelefono                      CD_DIRETTORE.TELEFONO%TYPE,
    a_e_mail                          CD_DIRETTORE.E_MAIL%TYPE
);
TYPE C_DIRETTORE IS REF CURSOR RETURN R_DIRETTORE;
TYPE R_STORIA_NOME_CINEMA IS RECORD
(
    a_id_nome_cinema    CD_NOME_CINEMA.ID_NOME_CINEMA%TYPE,
    a_id_cinema         CD_NOME_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema       CD_NOME_CINEMA.NOME_CINEMA%TYPE,
    a_data_inizio_val   CD_NOME_CINEMA.DATA_INIZIO%TYPE,
    a_data_fine_val     CD_NOME_CINEMA.DATA_FINE%TYPE
);
TYPE C_STORIA_NOME_CINEMA IS REF CURSOR RETURN R_STORIA_NOME_CINEMA;
TYPE R_CINEMA_SALA_STAMPA IS RECORD
(
    a_id_cinema		        CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
    a_id_comune             CD_CINEMA.ID_COMUNE%TYPE,
    a_comune                CD_COMUNE.COMUNE%TYPE,
    a_id_provincia          CD_PROVINCIA.ID_PROVINCIA%TYPE,
    a_provincia             CD_PROVINCIA.PROVINCIA%TYPE,
    a_id_regione            CD_REGIONE.ID_REGIONE%TYPE,
    a_regione               CD_REGIONE.NOME_REGIONE%TYPE,
    a_id_tipo_cinema        CD_CINEMA.ID_TIPO_CINEMA%TYPE,
    a_tipo_cinema           CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,    
    a_indirizzo             CD_CINEMA.INDIRIZZO%TYPE,
    a_cap                   CD_CINEMA.CAP%TYPE,
    a_data_inizio_val_cin   CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE,
    a_data_fine_va_cin      CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
    a_id_area_nielsen       CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
    a_id_sala		        CD_SALA.ID_SALA%TYPE,
    a_nome_sala             CD_SALA.NOME_SALA%TYPE,        
    a_data_inizio_val_sal   CD_SALA.DATA_INIZIO_VALIDITA%TYPE,
    a_data_fine_val_sal     CD_SALA.DATA_FINE_VALIDITA%TYPE,
    a_flag_arena            CD_SALA.FLG_ARENA%TYPE,
    a_id_circuito_corr      CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_circuito_corr         CD_CIRCUITO.NOME_CIRCUITO%TYPE     
);
TYPE C_CINEMA_SALA_STAMPA IS REF CURSOR RETURN R_CINEMA_SALA_STAMPA;
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              cinema
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PRESENZA_SALE_O_ATRII(p_id_cinema IN CD_CINEMA.ID_CINEMA%TYPE)
   RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_RICERCA_CINEMA
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_CINEMA(p_nome_cinema          CD_CINEMA.NOME_CINEMA%TYPE,
                           p_id_tipo_cinema       CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                           p_id_comune            CD_CINEMA.ID_COMUNE%TYPE,
                           p_flg_pubb_locale      CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                           p_id_area_nielsen      CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                           p_id_area_geografica   CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                           p_id_regione           CD_REGIONE.ID_REGIONE%TYPE,
                           p_flg_arena            CD_SALA.FLG_ARENA%TYPE,
                           p_flg_virtuale         CD_CINEMA.FLG_VIRTUALE%TYPE,
                           p_flg_valido           VARCHAR2)
                           RETURN C_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SALE_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALE_CINEMA      ( p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                               p_id_area_nielsen    CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                               p_id_tipo_cinema     CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                               p_id_comune          CD_CINEMA.ID_COMUNE%TYPE,
                               p_visibile           CD_SALA.FLG_VISIBILE%TYPE,
                               p_flg_virtuale       CD_CINEMA.FLG_VIRTUALE%TYPE,
                               p_flg_valido         VARCHAR2)
                               RETURN C_SALE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ARENE_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ARENE_CINEMA      ( p_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
                               p_id_area_nielsen    CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                               p_id_tipo_cinema     CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                               p_id_comune          CD_CINEMA.ID_COMUNE%TYPE,
                               p_visibile           CD_SALA.FLG_VISIBILE%TYPE,
                               p_flg_virtuale       CD_CINEMA.FLG_VIRTUALE%TYPE,
                               p_flg_valido         VARCHAR2)
                               RETURN C_SALE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ATRII_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ATRII_CINEMA      ( p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                               p_id_area_nielsen    CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                               p_id_tipo_cinema     CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                               p_id_comune          CD_CINEMA.ID_COMUNE%TYPE)
                               RETURN C_ATRII;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_CINEMA ( p_id_cinema      CD_CINEMA.ID_CINEMA%TYPE )
                               RETURN C_DETTAGLIO_CINEMA;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_CINEMA
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_CINEMA(p_nome_cinema             CD_CINEMA.NOME_CINEMA%TYPE,
                              p_id_tipo_cinema          CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                              p_id_comune               CD_CINEMA.ID_COMUNE%TYPE,
                              p_flg_pubb_locale         CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                              p_flg_concessione         CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE%TYPE,
                              p_indirizzo               CD_CINEMA.INDIRIZZO%TYPE,
                              p_flg_virtuale            CD_CINEMA.FLG_VIRTUALE%TYPE,
                              p_cap                     CD_CINEMA.CAP%TYPE,
                              p_id_direttore_complesso  CD_DIRETTORE.ID_DIRETTORE%TYPE,
                              --p_flg_attivo              CD_CINEMA.FLG_ATTIVO%TYPE,
                              p_recapito                CD_CINEMA.RECAPITO_POSTA%TYPE,
                              p_data_inizio_val         CD_NOME_CINEMA.DATA_INIZIO%TYPE,                           
							  p_esito			        OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ASSOCIA_DIR_COMPLESSO
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_DIR_COMPLESSO  (p_id_cinema               CD_CINEMA.ID_CINEMA%TYPE,
                                     p_id_direttore_complesso  CD_DIRETTORE.ID_DIRETTORE%TYPE,
                                     p_esito			       OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_CINEMA
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_CINEMA(p_id_cinema		IN CD_CINEMA.ID_CINEMA%TYPE,
							p_esito			OUT NUMBER);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CINEMA
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CINEMA(p_id_cinema		IN CD_CINEMA.ID_CINEMA%TYPE,
							p_esito			OUT NUMBER,
                            p_piani_errati  OUT VARCHAR2);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_CINEMA
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_CINEMA(p_lista_cinema	IN id_cinema_type,
							      p_esito			OUT NUMBER,
                                  p_piani_errati  OUT VARCHAR2);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CINEMA
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CINEMA(p_id_cinema		IN CD_CINEMA.ID_CINEMA%TYPE,
							 p_esito			OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_CINEMA
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_CINEMA( p_id_cinema               CD_CINEMA.ID_CINEMA%TYPE,
                              p_nome_cinema             CD_CINEMA.NOME_CINEMA%TYPE,
                              p_id_comune               CD_CINEMA.ID_COMUNE%TYPE,
                              p_flg_pubb_locale         CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                              p_flg_concessione         CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE%TYPE,
                              p_indirizzo               CD_CINEMA.INDIRIZZO%TYPE,
                              p_cap                     CD_CINEMA.CAP%TYPE,
                              p_id_tipo_cinema          CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                              p_flg_virtuale            CD_CINEMA.FLG_VIRTUALE%TYPE,
                              p_flg_annullato           CD_CINEMA.FLG_ANNULLATO%TYPE,
                              --p_flg_attivo              CD_CINEMA.FLG_ATTIVO%TYPE,
                              p_recapito                CD_CINEMA.RECAPITO_POSTA%TYPE,
                              p_data_inizio_validita    CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE,                              
                              p_data_fine_validita      CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                              p_esito					OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_REGIONE
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_REGIONE(p_id_area_geografica  CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                            p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE
                               )RETURN C_REGIONE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_AREA_NIELSEN
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_AREA_NIELSEN RETURN C_AREA_NIELSEN;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_AREA_GEOGRAFICA
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_AREA_GEOGRAFICA RETURN C_AREA_GEOGRAFICA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_COMUNE
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_COMUNE( p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                            p_id_area_geografica  CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                            p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE
                            )RETURN C_COMUNE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_TIPO_CINEMA
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_TIPO_CINEMA RETURN C_TIPO_CINEMA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_DIRETTORE_COMPLESSO
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_DIRETTORE_COMPLESSO RETURN C_DIRETTORE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_CINEMA
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_CINEMA (   p_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE,
                              p_id_tipo_cinema  CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                              p_id_comune       CD_CINEMA.ID_COMUNE%TYPE,
                              p_flag_virtuale   CD_CINEMA.FLG_VIRTUALE%TYPE) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_CINEMA(p_id_cinema   IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN CD_CINEMA.NOME_CINEMA%TYPE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_CINEMA_AS
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_CINEMA_AS(p_id_as    IN CD_ATRIO.ID_ATRIO%TYPE,
                                 p_flag_as  IN INTEGER)
            RETURN VARCHAR2;
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_CINEMA  (p_id_cinema   IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN INTEGER;

--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CINEMA_VENDUTO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CINEMA_VENDUTO  (p_id_cinema   IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN INTEGER;
            
            
FUNCTION FU_GET_NOME_CINEMA(P_ID_CINEMA CD_CINEMA.ID_CINEMA%TYPE, P_DATA DATE default sysdate) RETURN  CD_CINEMA.NOME_CINEMA%TYPE;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STORIA_NOME_CINEMA
--
-- INPUT:  ID del cinema del quale si vuole lo storico dei nomi
--
-- OUTPUT:  lista di nomi con date inizio/fine
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 22 Dicembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STORIA_NOME_CINEMA( p_id_cinema  CD_CINEMA.ID_CINEMA%TYPE)
            RETURN C_STORIA_NOME_CINEMA;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_NUOVO_NOME_CINEMA
--
-- INPUT:   p_id_cinema         ID del cinema del quale si sta aggiungendo il nuovo nome
--          p_nome_cinema       Il nuovo nome del cinema
--          p_data_inizio_val   La data dal quale il cinema cambia nome
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 23 Dicembre 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_NUOVO_NOME_CINEMA( p_id_cinema         CD_NOME_CINEMA.ID_CINEMA%TYPE,
                                p_nome_cinema       CD_NOME_CINEMA.NOME_CINEMA%TYPE,
                                p_data_inizio_val   CD_NOME_CINEMA.DATA_INIZIO%TYPE,
                                p_esito             OUT NUMBER);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INIZIO_VALIDITA_CINEMA
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_inizio_val   La data di inizio validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 7 Luglio 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INIZIO_VALIDITA_CINEMA(    p_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
                                        p_data_inizio_val   CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE,
                                        p_esito             OUT NUMBER);                                          
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_FINE_VALIDITA_CINEMA
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_fine_val     La data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 29 Aprile 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_FINE_VALIDITA_CINEMA(  p_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
                                    p_data_fine_val     CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER);                                                    
--

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_VALIDITA_CINEMA
--
-- INPUT:  ID del cinema del quale si vogliono le informazioni di inizio e fine 
--         validita'
--
-- OUTPUT:  C_STORIA_NOME_CINEMA con date inizio/fine; usa questo CURSOR perche'
--          contiene le stesse informazioni richieste
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 8 Luglio 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_VALIDITA_CINEMA( p_id_cinema  CD_CINEMA.ID_CINEMA%TYPE)
            RETURN C_STORIA_NOME_CINEMA;                                                 
--

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_ELENCO_CINEMA
--
-- INPUT:
--      Campi di ricerca per la stampa:
--      p_nome_cinema
--      p_id_tipo_cinema
--      p_id_comune
--      p_flg_pubb_locale
--      p_id_area_nielsen
--      p_id_area_geografica
--      p_id_regione
--      p_flg_arena
--      p_flg_virtuale
--      p_flg_valido
--
-- OUTPUT:  Cursore C_CINEMA_SALA_STAMPA contenente le informazioni richieste
--
-- REALIZZATORE  
--              Tommaso D'Anna, Teoresi srl, 2 Settembre 2011
-- MODIFICHE
--              Tommaso D'Anna, Teoresi srl, 3 Ottobre 2011
--                  Inserita HINT ALL_ROWS
--              Tommaso D'Anna, Teoresi srl, 24 Novembre 2011
--                  Inserito controllo sulla validita' del cinema
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_ELENCO_CINEMA(   p_nome_cinema          CD_CINEMA.NOME_CINEMA%TYPE,
                                    p_id_tipo_cinema       CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                                    p_id_comune            CD_CINEMA.ID_COMUNE%TYPE,
                                    p_flg_pubb_locale      CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                                    p_id_area_nielsen      CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                                    p_id_area_geografica   CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                                    p_id_regione           CD_REGIONE.ID_REGIONE%TYPE,
                                    p_flg_arena            CD_SALA.FLG_ARENA%TYPE,
                                    p_flg_virtuale         CD_CINEMA.FLG_VIRTUALE%TYPE,
                                    p_flg_valido           VARCHAR2
                                )
                                    RETURN C_CINEMA_SALA_STAMPA;
-- --------------------------------------------------------------------------------------------
END PA_CD_CINEMA; 
/

