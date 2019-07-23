CREATE OR REPLACE PACKAGE VENCD.PA_CD_LISTINO IS
v_stampa_listino          VARCHAR2(3):='ON';
--Stando alla documentazione, per poter essere
--accessibili da Java, questi tipi devono essere dichiarati a livello di
--schema e non di package, altrimenti non risultano visibili.
--Francesco Abbundo, Teoresi srl, Agosto 2009
/*TYPE id_atrii_type        IS TABLE OF CD_CIRCUITO_ATRIO.ID_ATRIO%TYPE INDEX BY BINARY_INTEGER;
TYPE id_sale_type         IS TABLE OF CD_CIRCUITO_SALA.ID_SALA%TYPE INDEX BY BINARY_INTEGER;
TYPE id_cinema_type       IS TABLE OF CD_CIRCUITO_CINEMA.ID_CINEMA%TYPE INDEX BY BINARY_INTEGER;
TYPE id_schermi_type      IS TABLE OF CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE INDEX BY BINARY_INTEGER;
*/
TYPE id_break_type        IS TABLE OF CD_CIRCUITO_BREAK.ID_BREAK%TYPE INDEX BY BINARY_INTEGER;
TYPE R_LISTINO IS RECORD
(
    a_id_listino                CD_LISTINO.ID_LISTINO%TYPE,
	a_desc_listino              CD_LISTINO.DESC_LISTINO%TYPE,
	a_data_inizio               CD_LISTINO.DATA_INIZIO%TYPE,
	a_data_fine                 CD_LISTINO.DATA_FINE%TYPE,
    a_cod_categoria_prodotto    CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,
	a_counter_card              NUMBER
);
TYPE C_LISTINO IS REF CURSOR RETURN R_LISTINO;
TYPE R_DETT_LISTINO IS RECORD
(
    a_id_listino                CD_LISTINO.ID_LISTINO%TYPE,
	a_desc_listino              CD_LISTINO.DESC_LISTINO%TYPE,
	a_data_inizio               CD_LISTINO.DATA_INIZIO%TYPE,
	a_data_fine                 CD_LISTINO.DATA_FINE%TYPE,
    a_cod_categoria_prodotto    CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,    
    a_id_sconto                 CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
	a_perc_sconto               CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
    a_data_inizio_sconto        CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
	a_data_fine_sconto          CD_SCONTO_STAGIONALE.DATA_FINE%TYPE
);
TYPE C_DETT_LISTINO IS REF CURSOR RETURN R_DETT_LISTINO;
TYPE R_AMBITO_IN_VENDITA IS RECORD
(
    a_id_circuito           INTEGER,
	a_nome_circuito         VARCHAR2(240),
	a_info_vendita          INTEGER
);
TYPE C_AMBITO_IN_VENDITA IS REF CURSOR RETURN R_AMBITO_IN_VENDITA;
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              listini
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_LISTINO          Inserimento di un listino nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_LISTINO            Eliminazione di un listino dal sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_CLONA_LISTINO              Clonazione di tutti i circuiti legati al listino di origine
--                                  verso il listino di destinazione
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_COMPONI_LISTINO_ATRIO      Composizione dei circuiti di atrio associati al
--                                  listino di riferimento
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_COMPONI_LISTINO_SALA       Composizione dei circuiti di sala associati al
--                                  listino di riferimento
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_COMPONI_LISTINO_CINEMA     Composizione dei circuiti di cinema associati al
--                                  listino di riferimento
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_COMPONI_LISTINO_SCHERMO    Composizione dei circuiti di schermo associati al
--                                  listino di riferimento
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_COMPONI_LISTINO_BREAK      Composizione dei circuiti di break associati al
--                                  listino di riferimento
-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_STAMPA_LISTINO             Stampa i parametri relativi al listino
-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_DETTAGLIO_LISTINO          Recupera i dettagli relativi al listino
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_LISTINO
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011              
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_LISTINO(p_desc_listino            CD_LISTINO.DESC_LISTINO%TYPE,
                               p_data_inizio             CD_LISTINO.DATA_INIZIO%TYPE,
                               p_data_fine               CD_LISTINO.DATA_FINE%TYPE,
                               p_cod_categoria_prodotto  CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,
							   p_esito					 OUT CD_LISTINO.ID_LISTINO%TYPE);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_LISTINO
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011              
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_LISTINO(p_id_listino              CD_LISTINO.ID_LISTINO%TYPE,
                              p_desc_listino            CD_LISTINO.DESC_LISTINO%TYPE,
                              p_data_inizio             CD_LISTINO.DATA_INIZIO%TYPE,
                              p_data_fine               CD_LISTINO.DATA_FINE%TYPE,
                              p_cod_categoria_prodotto  CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,                              
							  p_esito					 OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_LISTINO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_LISTINO(	p_id_listino		IN CD_LISTINO.ID_LISTINO%TYPE,
								p_esito				OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CLONA_LISTINO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CLONA_LISTINO  (	p_id_listino_orig		IN CD_LISTINO.ID_LISTINO%TYPE,
								p_id_listino_dest   	IN CD_LISTINO.ID_LISTINO%TYPE,
                                p_esito                 OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CREA_E_CLONA_LISTINO
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011              
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_E_CLONA_LISTINO (p_id_listino_orig	IN  CD_LISTINO.ID_LISTINO%TYPE,
								   p_desc_listino       IN  CD_LISTINO.DESC_LISTINO%TYPE,
                                   p_data_inizio        IN  CD_LISTINO.DATA_INIZIO%TYPE,
                                   p_data_fine          IN  CD_LISTINO.DATA_FINE%TYPE,
                                   p_cod_categoria_prodotto  CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,                                   
							       p_id_listino_dest   	OUT CD_LISTINO.ID_LISTINO%TYPE,
                                   p_esito              OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_LISTINO_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_ATRIO  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        								p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_atrii         IN id_atrii_type,
                                        p_esito                 OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_LISTINO_ARENA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_ARENA  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        								p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_arene         IN ID_LIST_TYPE,
                                        p_esito                 OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_LISTINO_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_SALA  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        								p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_sale          IN id_sale_type,
                                        p_esito                 OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_LISTINO_CINEMA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_CINEMA  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        								p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_cinema        IN id_cinema_type,
                                        p_esito                 OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_LISTINO_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_SCHERMO  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_schermi       IN id_schermi_type,
                                        p_esito                 OUT NUMBER);
PROCEDURE PR_COMPONI_SCHERMO_TEMP  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_schermi       IN id_schermi_type,
                                        p_esito                 OUT NUMBER);                                        
-------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_LISTINO_SCHERMO_CLONA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_LISTINO_SCHERMO_CLONA  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_listino_orig 		IN CD_LISTINO.ID_LISTINO%TYPE,
        								p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        --p_list_id_schermi       IN id_schermi_type,
                                        p_esito                 OUT NUMBER);
-- -
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_LISTINO_BREAK
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_BREAK  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
        								p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_break         IN id_break_type,
                                        p_esito                 OUT NUMBER);
PROCEDURE PR_COMPONI_BREAK_TEMP  (	p_id_listino    		IN CD_LISTINO.ID_LISTINO%TYPE,
    								p_id_circuito          	IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_list_id_break         IN id_break_type,
                                    p_esito                 OUT NUMBER);                                        
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_BLOCCO_LISTINI
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_BLOCCO_LISTINI( p_id_listino           IN CD_LISTINO.ID_LISTINO%TYPE,
                                     p_id_circuito          IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
									 p_list_id_cinema       IN id_cinema_type,
                                     p_list_id_atrii        IN id_atrii_type,
									 p_list_id_sale         IN id_sale_type,
                                     p_list_id_schermi      IN id_schermi_type,
                                     p_list_id_arene        IN id_list_type,
									 p_esito                OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_LISTINO
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011              
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_LISTINO  (p_id_listino		IN CD_LISTINO.ID_LISTINO%TYPE)
                                RETURN C_DETT_LISTINO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_LISTINO
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011              
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_LISTINO(p_desc_listino     CD_LISTINO.DESC_LISTINO%TYPE,
                          p_data_inizio      CD_LISTINO.DATA_INIZIO%TYPE,
                          p_data_fine        CD_LISTINO.DATA_FINE%TYPE)
                         RETURN C_LISTINO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_LISTINI_NON_VUOTI
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011              
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_LISTINI_NON_VUOTI
                         RETURN C_LISTINO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_LISTINO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_LISTINO(p_desc_listino            CD_LISTINO.DESC_LISTINO%TYPE,
                           p_data_inizio             CD_LISTINO.DATA_INIZIO%TYPE,
                           p_data_fine               CD_LISTINO.DATA_FINE%TYPE) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CINEMA_IN_CIRCUITO_LISTINO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CINEMA_IN_CIRCUITO_LISTINO(p_id_listino   IN CD_CIRCUITO_CINEMA.ID_LISTINO%TYPE,
                                       p_id_circuito  IN CD_CIRCUITO_CINEMA.ID_CIRCUITO%TYPE,
									   p_id_cinema    IN CD_CIRCUITO_CINEMA.ID_CINEMA%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ATRIO_IN_CIRCUITO_LISTINO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ATRIO_IN_CIRCUITO_LISTINO(p_id_listino   IN CD_CIRCUITO_ATRIO.ID_LISTINO%TYPE,
                                      p_id_circuito  IN CD_CIRCUITO_ATRIO.ID_CIRCUITO%TYPE,
									  p_id_atrio     IN CD_CIRCUITO_ATRIO.ID_ATRIO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SALA_IN_CIRCUITO_LISTINO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALA_IN_CIRCUITO_LISTINO(p_id_listino   IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                     p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
									 p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ARENA_IN_CIRCUITO_LISTINO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ARENA_IN_CIRCUITO_LISTINO(p_id_listino  IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                      p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
                                      p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
            RETURN INTEGER;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SCHERMO_IN_CIRCUITO_LIS_LIB
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMO_IN_CIRCUITO_LIS_LIB(p_id_listino   IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                        p_id_circuito  IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
									    p_id_schermo   IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SCHERMO_IN_CIRCUITO_LIS_MOD
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMO_IN_CIRCUITO_LIS_MOD(p_id_listino   IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                        p_id_circuito  IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
									    p_id_schermo   IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SCHERMO_IN_CIRCUITO_LISTINO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMO_IN_CIRCUITO_LISTINO(p_id_listino   IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                        p_id_circuito  IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
									    p_id_schermo   IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VENDUTO_ACQUISTATO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VENDUTO_ACQUISTATO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE,
                               p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_AMBITI_IN_VENDITA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_AMBITI_IN_VENDITA(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN C_AMBITO_IN_VENDITA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_LISTINO_VUOTO_PIENO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_LISTINO_VUOTO_PIENO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_SVUOTA_LISTINO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_SVUOTA_LISTINO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE,
							p_esito		    OUT INTEGER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_PREPARA_MODIFICA_COMP
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_PREPARA_MODIFICA_COMP(p_id_listino IN CD_LISTINO.ID_LISTINO%TYPE,
							       p_esito		OUT INTEGER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DATA_INIZIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DATA_INIZIO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN DATE;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DATA_FINE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DATA_FINE(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN DATE;
PROCEDURE PR_COPIA_COMPONI_CIRCUITO  (   p_id_listino_orig      IN CD_LISTINO.ID_LISTINO%TYPE,
                                         p_id_listino_dest      IN CD_LISTINO.ID_LISTINO%TYPE,
                                         p_id_circuito_orig     IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_id_circuito_dest     IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_esito           OUT NUMBER);

END PA_CD_LISTINO; 
/

