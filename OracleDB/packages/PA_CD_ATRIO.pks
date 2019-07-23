CREATE OR REPLACE PACKAGE VENCD.PA_CD_ATRIO IS
v_stampa_atrio			VARCHAR2(3):='ON';

TYPE R_DETTAGLIO_ATRIO IS RECORD
(
    a_id_atrio                  CD_ATRIO.ID_ATRIO%TYPE,
    a_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema               CD_CINEMA.NOME_CINEMA%TYPE,
    a_desc_atrio                CD_ATRIO.DESC_ATRIO%TYPE,
    a_num_automobili            CD_ATRIO.NUM_AUTOMOBILI%TYPE,
    a_num_corner                CD_ATRIO.NUM_CORNER%TYPE,
    a_num_distribuzioni         CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
    a_num_esposizioni           CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
    a_num_lcd                   CD_ATRIO.NUM_LCD%TYPE,
    a_num_scooter_moto          CD_ATRIO.NUM_SCOOTER_MOTO%TYPE
);
TYPE C_DETTAGLIO_ATRIO IS REF CURSOR RETURN R_DETTAGLIO_ATRIO;

TYPE R_DETTAGLIO_ATRIO_SCHERMI IS RECORD
(
    a_id_schermo                CD_SCHERMO.ID_SCHERMO%TYPE,
    a_desc_schermo              CD_SCHERMO.DESC_SCHERMO%TYPE,
    a_misura_pollici            CD_SCHERMO.MISURA_POLLICI%TYPE
);
TYPE C_DETTAGLIO_ATRIO_SCHERMI IS REF CURSOR RETURN R_DETTAGLIO_ATRIO_SCHERMI;

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione degli
--              atrii
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:  Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_ATRIO(   p_desc_atrio            CD_ATRIO.DESC_ATRIO%TYPE,
                                p_id_cinema             CD_ATRIO.ID_CINEMA%TYPE,
                                p_num_distribuzioni     CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
                                p_num_esposizioni       CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
                                p_num_scooter_moto      CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
                                p_num_corner            CD_ATRIO.NUM_CORNER%TYPE,
                                p_num_lcd               CD_ATRIO.NUM_LCD%TYPE,
                                p_num_automobili        CD_ATRIO.NUM_AUTOMOBILI%TYPE,
                                --p_flg_annullato         CD_ATRIO.FLG_ANNULLATO%TYPE,
							    p_esito					OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_ATRIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_ATRIO ( p_id_atrio      CD_ATRIO.ID_ATRIO%TYPE )
                               RETURN C_DETTAGLIO_ATRIO;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_ATRIO(	p_id_atrio		IN CD_ATRIO.ID_ATRIO%TYPE,
							p_esito			OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_ATRIO_CINEMA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_ATRIO_CINEMA(	p_id_cinema		IN CD_CINEMA.ID_CINEMA%TYPE,
							        p_esito			OUT NUMBER);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_ATRIO(p_id_atrio		IN CD_ATRIO.ID_ATRIO%TYPE,
						   p_esito			OUT NUMBER,
						   p_piani_errati   OUT VARCHAR2);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_ATRII
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_ATRII(p_lista_atrii	   IN id_atrii_type,
							     p_esito		   OUT NUMBER,
								 p_piani_errati    OUT VARCHAR2);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_ATRIO(p_id_atrio		IN CD_ATRIO.ID_ATRIO%TYPE,
						    p_esito			OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_ATRIO(  p_id_atrio                CD_ATRIO.ID_ATRIO%TYPE,
                              p_desc_atrio              CD_ATRIO.DESC_ATRIO%TYPE,
                              p_id_cinema               CD_ATRIO.ID_CINEMA%TYPE,
                              p_num_distribuzioni       CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
                              p_num_esposizioni         CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
                              p_num_scooter_moto        CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
                              p_num_corner              CD_ATRIO.NUM_CORNER%TYPE,
                              p_num_lcd                 CD_ATRIO.NUM_LCD%TYPE,
                              p_num_automobili          CD_ATRIO.NUM_AUTOMOBILI%TYPE,
                              p_flg_annullato           CD_ATRIO.FLG_ANNULLATO%TYPE,
                              p_esito					OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_ATRIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_ATRIO       (p_desc_atrio            CD_ATRIO.DESC_ATRIO%TYPE,
                                p_id_cinema             CD_ATRIO.ID_CINEMA%TYPE,
                                p_num_distribuzioni     CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
                                p_num_esposizioni       CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
                                p_num_scooter_moto      CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
                                p_num_corner            CD_ATRIO.NUM_CORNER%TYPE,
                                p_num_lcd               CD_ATRIO.NUM_LCD%TYPE,
                                p_num_automobili        CD_ATRIO.NUM_AUTOMOBILI%TYPE
                                ) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_ATRIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_ATRIO(p_id_atrio  IN CD_ATRIO.ID_ATRIO%TYPE)
            RETURN VARCHAR2;
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_ATRIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_ATRIO  (p_id_atrio   IN CD_ATRIO.ID_ATRIO%TYPE)
            RETURN INTEGER;
--

--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SCHERMI_ATRIO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMI_ATRIO  (p_id_atrio   IN CD_ATRIO.ID_ATRIO%TYPE)
            RETURN C_DETTAGLIO_ATRIO_SCHERMI;
--

--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ATRIO_VENDUTO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ATRIO_VENDUTO  (p_id_atrio     IN CD_ATRIO.ID_ATRIO%TYPE)
            RETURN INTEGER;

END PA_CD_ATRIO;
/

