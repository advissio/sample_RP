CREATE OR REPLACE PACKAGE VENCD.PA_CD_SCHERMO IS
v_stampa_schermo          VARCHAR2(3):='ON';
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione degli
--              schermi
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009

TYPE R_SCHERMI IS RECORD
(
    a_id_schermo       CD_SCHERMO.ID_SCHERMO%TYPE,
    a_nome_schermo     CD_SCHERMO.DESC_SCHERMO%TYPE
);

TYPE C_SCHERMI IS REF CURSOR RETURN R_SCHERMI;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SCHERMO(p_desc_schermo             CD_SCHERMO.DESC_SCHERMO%TYPE,
                               p_id_sala                  CD_SCHERMO.ID_SALA%TYPE,
                               p_id_atrio                 CD_SCHERMO.ID_ATRIO%TYPE,
                               p_misura_larghezza         CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                               p_misura_lunghezza         CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                               p_misura_pollici           CD_SCHERMO.MISURA_POLLICI%TYPE,
                               p_flg_sala                 CD_SCHERMO.FLG_SALA%TYPE,
                               p_esito                    OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SCHERMO(   p_id_schermo           IN CD_SCHERMO.ID_SCHERMO%TYPE,
                                p_esito                OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SCHERMO_SALA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SCHERMO_SALA(  p_id_sala              IN CD_SALA.ID_SALA%TYPE,
                                    p_esito                OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SCHERMO_ATRIO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SCHERMO_ATRIO( p_id_atrio             IN CD_ATRIO.ID_ATRIO%TYPE,
                                    p_esito                OUT NUMBER);


-- ---------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_SCHERMO(p_id_schermo	IN CD_SCHERMO.ID_SCHERMO%TYPE,
						     p_esito		OUT NUMBER,
                             p_piani_errati OUT VARCHAR2);
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_SCHERMI
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_SCHERMI(p_lista_schermi	    IN id_schermi_type,
							       p_esito			    OUT NUMBER,
                                   p_piani_errati       OUT VARCHAR2);
-- ---------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_SCHERMO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_SCHERMO(p_id_schermo	IN CD_SCHERMO.ID_SCHERMO%TYPE,
						      p_esito		OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_SCHERMO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SCHERMO(    p_id_sala                  CD_SCHERMO.ID_SALA%TYPE,
                               p_id_atrio                 CD_SCHERMO.ID_ATRIO%TYPE,
                               p_misura_larghezza         CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                               p_misura_lunghezza         CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                               p_misura_pollici           CD_SCHERMO.MISURA_POLLICI%TYPE,
                               p_flg_sala                 CD_SCHERMO.FLG_SALA%TYPE) RETURN VARCHAR2;
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_SCHERMO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_SCHERMO  (p_id_schermo   IN CD_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SCHERMI_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SCHERMI_CINEMA (p_id_cinema CD_CINEMA.ID_CINEMA%TYPE,p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,p_data_inizio cd_proiezione.data_proiezione%type,p_data_fine cd_proiezione.data_proiezione%type) RETURN C_SCHERMI;

--
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_NUM_SCHERMI_CIRCUITO
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_NUM_SCHERMI_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER;

END PA_CD_SCHERMO;
/

