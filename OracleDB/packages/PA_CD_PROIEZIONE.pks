CREATE OR REPLACE PACKAGE VENCD.PA_CD_PROIEZIONE IS

v_stampa_proiezione         VARCHAR2(3):='ON';

ESISTE_PROIEZIONE_EXCEPTION EXCEPTION;

TYPE R_PROIEZIONE IS RECORD
(
    a_id_proiezioni         varchar2(200),
    a_data_proiezione       CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
    a_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
    a_desc_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
    a_comune                CD_COMUNE.COMUNE%TYPE,
    a_id_sala               CD_SALA.ID_SALA%TYPE,
	a_desc_sala             CD_SALA.NOME_SALA%TYPE,
    a_id_codice_resp        cd_codice_resp.ID_CODICE_RESP%type,
    a_desc_codice           cd_codice_resp.DESC_CODICE%type,
    a_flg_annullato         cd_proiezione.FLG_ANNULLATO%TYPE,
    a_note                  CD_PROIEZIONE.NOTA%TYPE
);
TYPE C_PROIEZIONE IS REF CURSOR RETURN R_PROIEZIONE;

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione delle
--              proiezioni
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_PROIEZIONE          Inserimento di una proiezione nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_PROIEZIONE_MULTI    Inserimento di una serie di proiezioni nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_PROIEZIONE            Eliminazione di una proiezione dal sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_MODIFICA_PROIEZIONE           Modifica di una proiezione del sistema
-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_ESISTE_PROIEZIONE             Controlla l'esistenza una proiezione nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_GENERA_PROIEZIONI             Genera le proiezioni per un periodo
--                                     su tutti gli schermi del sistema
-- ---------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_SPOSTA_PROIEZIONI             Sposta le proiezioni di una sala
--                                     da un periodo ad un altro
-- ---------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_PROIEZIONE     Esegue l'annullamento logico delle proiezioni
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_PROIEZIONE        Ricerca le proiezioni valide
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_PROIEZIONE_MULTI
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_PROIEZIONI_MULTI( p_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
                                         p_id_sala                   CD_SALA.ID_SALA%TYPE,
                                         p_data_inizio               DATE,
                                         p_data_fine                 DATE,
                                         p_esito                     OUT NUMBER);
PROCEDURE PR_INSERISCI_PROIEZIONE( p_id_schermo                CD_PROIEZIONE.ID_SCHERMO%TYPE,
                                   p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                   p_id_fascia                 CD_PROIEZIONE.ID_FASCIA%TYPE,
                                   p_esito                     OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_PROIEZIONE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_PROIEZIONE(    p_id_proiezione        IN CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                    p_esito                OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESISTE_PROIEZIONE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESISTE_PROIEZIONE(p_id_schermo                CD_PROIEZIONE.ID_SCHERMO%TYPE,
                              p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                              p_id_fascia                 CD_FASCIA.ID_FASCIA%TYPE
                              ) RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESISTE_PROIEZIONE
-- --------------------------------------------------------------------------------------------
/*
FUNCTION FU_ESISTE_PROIEZIONE(p_id_schermo                CD_PROIEZIONE.ID_SCHERMO%TYPE,
                              p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE
                              ) RETURN INTEGER;
*/
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_PROIEZIONE_VENDUTA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PROIEZIONE_VENDUTA(p_id_proiezione             CD_PROIEZIONE.ID_PROIEZIONE%TYPE
                               ) RETURN INTEGER;


-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_GENERA_PROIEZIONI
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_GENERA_PROIEZIONI   ( p_data_inizio               DATE,
                                   p_data_fine                 DATE,
                                   p_esito                     OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_PROIEZIONE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PROIEZIONE(p_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
                             --p_id_spettacolo             CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                             p_id_sala                   CD_SALA.ID_SALA%TYPE,
                             p_data_inizio               DATE,
                             p_data_fine                 DATE,
                             --p_id_fascia                 CD_FASCIA.ID_FASCIA%TYPE,
                             p_id_codice_resp            CD_codice_resp.ID_CODICE_RESP%type,
                             p_flg_annullato             CD_PROIEZIONE.FLG_ANNULLATO%TYPE)
                             RETURN C_PROIEZIONE;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ASSOCIA_FILM
-- --------------------------------------------------------------------------------------------
/*
PROCEDURE PR_ASSOCIA_FILM ( p_id_sala                   CD_SALA.ID_SALA%TYPE,
                            p_id_spettacolo             CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                            p_data_inizio               DATE,
                            p_data_fine                 DATE,
                            p_id_fascia                 CD_FASCIA.ID_FASCIA%TYPE,
                            p_esito                     OUT NUMBER);
*/
-- ---------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_PROIEZIONE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_PROIEZIONE(p_id_proiezione 	IN CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                p_nota              IN CD_PROIEZIONE.NOTA%TYPE,
						        p_esito		        OUT NUMBER,
                                p_piani_errati        OUT VARCHAR2);
--                                
PROCEDURE PR_ANNULLA_SALA_PRO(p_id_cinema         IN CD_CINEMA.ID_CINEMA%TYPE,
                              p_id_sala           IN CD_SALA.id_sala%type,
                              p_data_inizio       in date,
                              p_data_fine         in date,
                              p_nota              IN CD_PROIEZIONE.NOTA%TYPE,
						      p_esito		      OUT NUMBER
                             );
--                                
PROCEDURE PR_ANNULLA_DISP_SALA( p_id_cinema         IN CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala           IN CD_SALA.id_sala%type,
                                p_data_inizio       in date,
                                p_data_fine         in date,
                                p_nota              in VARCHAR2,
                                p_esito             out number);
-- ---------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_PROIEZIONE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_PROIEZIONE(p_id_proiezione 	IN CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
						         p_esito		    OUT NUMBER);


-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_SPOSTA_PROIEZIONI
-- --------------------------------------------------------------------------------------------
/*
PROCEDURE PR_SPOSTA_PROIEZIONI   (p_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
                                  p_id_sala                   CD_SALA.ID_SALA%TYPE,
                                  p_data_inizio_da            DATE,
                                  p_data_fine_da              DATE,
                                  p_data_inizio_a             DATE,
                                  p_nota                      CD_PROIEZIONE.NOTA%TYPE,
                                  p_esito                     OUT NUMBER,
                                  p_piani_errati              OUT VARCHAR2);
*/
END PA_CD_PROIEZIONE; 
/

