CREATE OR REPLACE PACKAGE VENCD.PA_CD_CIRCUITO IS
v_stampa_circuito            VARCHAR2(3):='ON';
TYPE tipo_nome_ambiti     IS TABLE OF VARCHAR2(240)  INDEX BY BINARY_INTEGER;
TYPE R_CIRCUITO IS RECORD
(
   a_id_circuito       CD_CIRCUITO.ID_CIRCUITO%TYPE,
   a_nome_circuito     CD_CIRCUITO.NOME_CIRCUITO%TYPE,
   a_data_inizio_valid CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
   a_data_fine_valid   CD_CIRCUITO.DATA_FINE_VALID%TYPE
);
TYPE C_CIRCUITO IS REF CURSOR RETURN R_CIRCUITO;
TYPE R_CIRCUITO_DETT IS RECORD
(
   a_id_circuito       CD_CIRCUITO.ID_CIRCUITO%TYPE,
   a_nome_circuito     CD_CIRCUITO.NOME_CIRCUITO%TYPE,
   a_descr_circuito    CD_CIRCUITO.DESC_CIRCUITO%TYPE,
   a_data_inizio_valid CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
   a_data_fine_valid   CD_CIRCUITO.DATA_FINE_VALID%TYPE,
   a_abbr_nome         CD_CIRCUITO.ABBR_NOME%TYPE,
   a_flag_atrio        CD_CIRCUITO.FLG_ATRIO%TYPE,
   a_flag_schermo      CD_CIRCUITO.FLG_SCHERMO%TYPE,
   a_flag_cinema       CD_CIRCUITO.FLG_CINEMA%TYPE,
   a_flag_sala         CD_CIRCUITO.FLG_SALA%TYPE,
   a_flag_arena        CD_CIRCUITO.FLG_ARENA%TYPE,
   p_flag_listino      CD_CIRCUITO.FLG_DEFINITO_A_LISTINO%TYPE,
   a_livello           CD_CIRCUITO.LIVELLO%TYPE
);
TYPE C_CIRCUITO_DETT IS REF CURSOR RETURN R_CIRCUITO_DETT;
TYPE R_ELENCO_AMBITI IS RECORD
(
    a_nome_ambito           VARCHAR2(240),
	a_id_ambito             INTEGER,
	a_id_circuito_ambito    INTEGER,
	a_infor_vendita         INTEGER,
	a_tipo_ambito           VARCHAR2(240),
	a_nome_sala_atrio       VARCHAR2(240),
	a_nome_cinema           VARCHAR2(240),
    a_comune                CD_COMUNE.COMUNE%TYPE
);
TYPE C_ELENCO_AMBITI IS REF CURSOR RETURN R_ELENCO_AMBITI;
TYPE R_CIRCUITO_BREAK IS RECORD
(
   a_id_circuito       CD_CIRCUITO.ID_CIRCUITO%TYPE,
   a_id_tipo_break     CD_tipo_break.id_tipo_break%TYPE,
   a_desc_tipo_break   CD_tipo_break.desc_tipo_break%TYPE,
   a_flg_associato     char
);
TYPE C_CIRCUITO_BREAK IS REF CURSOR RETURN R_CIRCUITO_BREAK;
TYPE R_CIRCUITO_STAMPA IS RECORD
(
    a_id_listino                CD_LISTINO.ID_LISTINO%TYPE,
    a_desc_listino              CD_LISTINO.DESC_LISTINO%TYPE,
    a_id_circuito               CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito             CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_comune                 CD_COMUNE.ID_COMUNE%TYPE,
    a_comune                    CD_COMUNE.COMUNE%TYPE,
    a_id_provincia              CD_PROVINCIA.ID_PROVINCIA%TYPE,
    a_provincia                 CD_PROVINCIA.PROVINCIA%TYPE,
    a_id_regione                CD_REGIONE.ID_REGIONE%TYPE,
    a_regione                   CD_REGIONE.NOME_REGIONE%TYPE,
    a_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema               CD_CINEMA.NOME_CINEMA%TYPE,
    a_id_sala                   CD_SALA.ID_SALA%TYPE,
    a_nome_sala                 CD_SALA.NOME_SALA%TYPE,
    a_flg_definito_a_listino    CD_CIRCUITO.FLG_DEFINITO_A_LISTINO%TYPE,
    a_flg_arena                 CD_CIRCUITO.FLG_ARENA%TYPE
);
TYPE C_CIRCUITO_STAMPA IS REF CURSOR RETURN R_CIRCUITO_STAMPA;
-----------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              circuiti
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_CIRCUITO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_CIRCUITO(p_nome_circuito              CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                                p_descr_circuito             CD_CIRCUITO.DESC_CIRCUITO%TYPE,
                                p_abbr_nome                  CD_CIRCUITO.ABBR_NOME%TYPE,
                                p_data_inizio_valid          CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                                p_data_fine_valid            CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                                p_flag_atrio                 CD_CIRCUITO.FLG_ATRIO%TYPE,
                                p_flag_schermo               CD_CIRCUITO.FLG_SCHERMO%TYPE,
                                p_flag_cinema                CD_CIRCUITO.FLG_CINEMA%TYPE,
                                p_flag_sala                  CD_CIRCUITO.FLG_SALA%TYPE,
                                p_flag_arena                 CD_CIRCUITO.FLG_ARENA%TYPE,
                                p_flag_listino               CD_CIRCUITO.FLG_DEFINITO_A_LISTINO%TYPE,
                                --p_flg_annullato              CD_CIRCUITO.FLG_ANNULLATO%TYPE,
                                p_livello                    CD_CIRCUITO.LIVELLO%TYPE,
                                p_esito						 OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CERCA_CIRCUITO
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_CIRCUITO( p_nome_circuito     CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                            p_data_inizio_valid CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                            p_data_fine_valid   CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                            p_flg_schermo       CD_CIRCUITO.FLG_SCHERMO%TYPE)
                            RETURN C_CIRCUITO;

-----------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              circuiti
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Agosto 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_CIRCUITO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_CIRCUITO (p_id_circuito                CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_nome_circuito              CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                                p_descr_circuito             CD_CIRCUITO.DESC_CIRCUITO%TYPE,
                                p_abbr_nome                  CD_CIRCUITO.ABBR_NOME%TYPE,
                                p_data_inizio_valid          CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                                p_data_fine_valid            CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                                p_flag_atrio                 CD_CIRCUITO.FLG_ATRIO%TYPE,
                                p_flag_schermo               CD_CIRCUITO.FLG_SCHERMO%TYPE,
                                p_flag_cinema                CD_CIRCUITO.FLG_CINEMA%TYPE,
                                p_flag_sala                  CD_CIRCUITO.FLG_SALA%TYPE,
                                p_flag_arena                 CD_CIRCUITO.FLG_ARENA%TYPE,
                                p_flag_listino               CD_CIRCUITO.FLG_DEFINITO_A_LISTINO%TYPE,
                                p_flg_annullato              CD_CIRCUITO.FLG_ANNULLATO%TYPE,
                                p_livello                    CD_CIRCUITO.LIVELLO%TYPE,
                                p_esito						 OUT NUMBER);
---------------------------------------------------------------------------------------
----------------------------- PR_AGGIORNA_CIRCUITO_BREAK ------------------------------
---------------------------------------------------------------------------------------                                
PROCEDURE PR_AGGIORNA_CIRCUITO_BREAK (p_id_circuito                CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                      p_id_tipo_break              CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                      p_flg_operazione             char,
                                      p_esito					   OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_CIRCUITO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_CIRCUITO ( p_id_circuito      CD_CIRCUITO.ID_CIRCUITO%TYPE )
                                 RETURN C_CIRCUITO_DETT;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_CIRCUITO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_CIRCUITO(p_id_circuito		IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
							  p_esito			OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO(p_id_circuito		IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
							  p_esito			OUT NUMBER,
                              p_piani_errati    OUT VARCHAR2);


-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_CINEMA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_CINEMA(p_id_circuito_cinema		IN CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA%TYPE,
							         p_esito			        OUT NUMBER,
                                     p_piani_errati             OUT VARCHAR2);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_ATRIO(p_id_circuito_atrio		IN CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO%TYPE,
							         p_esito			    OUT NUMBER,
                                     p_piani_errati         OUT VARCHAR2);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_SALA(p_id_circuito_sala		IN CD_CIRCUITO_SALA.ID_CIRCUITO_SALA%TYPE,
							       p_esito			        OUT NUMBER,
                                   p_piani_errati        OUT VARCHAR2);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_SCHERMO(p_id_circuito_schermo	IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO%TYPE,
							          p_esito			    OUT NUMBER,
                                      p_piani_errati        OUT VARCHAR2);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_CINEMA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_CINEMA( p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        						    p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
									p_id_lista_cinema		IN id_cinema_type,
							        p_esito			        OUT NUMBER,
                                    p_piani_errati          OUT VARCHAR2);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_ATRIO( p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        						   p_id_circuito        IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
								   p_id_lista_atrii		IN id_atrii_type,
							       p_esito			    OUT NUMBER,
                                   p_piani_errati       OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_SALA(p_id_listino    IN CD_LISTINO.ID_LISTINO%TYPE,
        						 p_id_circuito   IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
								 p_id_lista_sale IN id_sale_type,
							     p_esito		 OUT NUMBER,
                                 p_piani_errati  OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_SCHERMO(p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        						    p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
									p_id_lista_schermi	    IN id_schermi_type,
							        p_esito			        OUT NUMBER,
                                    p_piani_errati          OUT VARCHAR2);
-- PROCEDURA PR_ANN_LISTA_CIRC_ARENA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_ARENA(p_id_listino    		    IN CD_LISTINO.ID_LISTINO%TYPE,
        						    p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
									p_id_list_arene	        IN id_list_type,
							        p_esito			        OUT NUMBER,
                                    p_piani_errati          OUT VARCHAR2);
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_BLOCCO_LISTA_CIRC
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_BLOCCO_LISTA_CIRC( p_id_listino           IN CD_LISTINO.ID_LISTINO%TYPE,
                                    p_id_circuito          IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
									p_list_id_cinema       IN id_cinema_type,
                                    p_list_id_atrii        IN id_atrii_type,
									p_list_id_sale         IN id_sale_type,
                                    p_list_id_schermi      IN id_schermi_type,
                                    p_list_id_arene        IN id_list_type,
									p_esito                OUT NUMBER,
                                    p_piani_errati         OUT VARCHAR2);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_CINEMA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_CINEMA(p_id_circuito_cinema		IN CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA%TYPE,
							         p_esito			        OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_ATRIO(p_id_circuito_atrio		IN CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO%TYPE,
							         p_esito			        OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_SALA(p_id_circuito_sala		IN CD_CIRCUITO_SALA.ID_CIRCUITO_SALA%TYPE,
							       p_esito			        OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_SCHERMO(p_id_circuito_schermo	IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO%TYPE,
							          p_esito			    OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_CIRUCITO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_CIRCUITO(p_nome_circuito              CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                            p_descr_circuito             CD_CIRCUITO.DESC_CIRCUITO%TYPE,
                            p_abbr_nome                  CD_CIRCUITO.ABBR_NOME%TYPE,
                            p_data_inizio_valid          CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                            p_data_fine_valid            CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                            p_flag_atrio                 CD_CIRCUITO.FLG_ATRIO%TYPE,
                            p_flag_schermo               CD_CIRCUITO.FLG_SCHERMO%TYPE,
                            p_flag_cinema                CD_CIRCUITO.FLG_CINEMA%TYPE,
                            p_flag_sala                  CD_CIRCUITO.FLG_SALA%TYPE) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_CINEMA(p_id_listino   IN CD_CIRCUITO_CINEMA.ID_LISTINO%TYPE,
                                  p_id_circuito  IN CD_CIRCUITO_CINEMA.ID_CIRCUITO%TYPE,
								  p_id_cinema    IN CD_CIRCUITO_CINEMA.ID_CINEMA%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_ATRIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_ATRIO(p_id_listino   IN CD_CIRCUITO_ATRIO.ID_LISTINO%TYPE,
                                 p_id_circuito  IN CD_CIRCUITO_ATRIO.ID_CIRCUITO%TYPE,
								p_id_atrio     IN CD_CIRCUITO_ATRIO.ID_ATRIO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_SALA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_SALA(p_id_listino   IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
								p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_ARENA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_ARENA(p_id_listino  IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                 p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
                                 p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
             RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_SCHERMO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino   IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                   p_id_circuito  IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
								   p_id_schermo   IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_AMBITI_CIRCUITO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_AMBITI_CIRCUITO_L(p_id_listino               IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                     p_id_circuito              IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
									 p_id_cinema                IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN C_ELENCO_AMBITI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_AMBITI_CIRCUITO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_AMBITI_CIRCUITO_T(p_id_tariffa   IN CD_TARIFFA.ID_TARIFFA%TYPE,
                                     p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
									 p_id_cinema    IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN C_ELENCO_AMBITI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_CIRCUITO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_CIRCUITO(p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
            RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_CIRCUITO_VUOTO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_CIRCUITO_VUOTO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE,
                                    p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CIRCUITO_VENDUTO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CIRCUITO_VENDUTO(p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
                             RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CIRCUITO_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CIRCUITO_TIPO_BREAK(p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
                             RETURN C_CIRCUITO_BREAK;                             
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_CIRCUITI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_CIRCUITI(
                                p_id_listino    CD_LISTINO.ID_LISTINO%TYPE,
                                p_id_circuito   CD_CIRCUITO.ID_CIRCUITO%TYPE 
                           )
                                RETURN C_CIRCUITO_STAMPA;

END PA_CD_CIRCUITO; 
/

