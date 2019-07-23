CREATE OR REPLACE PACKAGE VENCD.PA_CD_PERIODO_SPECIALE IS

v_stampa_periodo_speciale          VARCHAR2(3):='ON';

TYPE R_DATA_INIZIO_P_SPEC IS RECORD
(
 a_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE
);

TYPE C_DATA_INIZIO_P_SPEC IS REF CURSOR RETURN R_DATA_INIZIO_P_SPEC;

TYPE R_DATA_FINE_P_SPEC IS RECORD
(
 a_data_fine CD_PERIODO_SPECIALE.DATA_FINE%TYPE
);

TYPE R_PER_SPECIALE IS RECORD
( a_id_periodo_speciale  CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE,
  a_data_inizio          CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
  a_data_fine            CD_PERIODO_SPECIALE.DATA_FINE%TYPE
);
TYPE C_PER_SPECIALE IS REF CURSOR RETURN R_PER_SPECIALE;

TYPE C_DATA_FINE_P_SPEC IS REF CURSOR RETURN R_DATA_FINE_P_SPEC;

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              periodi speciali
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_PERIODO_SPECIALE           Inserimento di uno periodo speciale nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_PERIODO_SPECIALE            Eliminazione di uno periodo speciale dal sistema
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_PERIODO_SPECIALE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_PERIODO_SPECIALE(p_data_inizio                       CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
                                        p_data_fine                         CD_PERIODO_SPECIALE.DATA_FINE%TYPE,
                                        p_esito                             OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_PERIODO_SPECIALE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_PERIODO_SPECIALE( p_id_periodo_speciale        IN CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE,
                                       p_esito                       OUT NUMBER);

FUNCTION FU_CERCA_PERIODO_SPEC(p_id_periodo_speciale        CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE,
                               p_data_inizio                CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
                               p_data_fine                  CD_PERIODO_SPECIALE.DATA_FINE%TYPE)
                               RETURN C_PER_SPECIALE;

--Restituisce le date inizio dei periodi speciali
FUNCTION FU_GET_DATA_INIZIO_P_SPEC RETURN C_DATA_INIZIO_P_SPEC;

--Restituisce le date fine per una data inizio dei periodi speciali
FUNCTION FU_GET_DATA_FINE_P_SPEC (p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE) RETURN C_DATA_FINE_P_SPEC;
FUNCTION FU_GET_ID_PERIODO_SPEC(p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE, p_data_fine CD_PERIODO_SPECIALE.DATA_FINE%TYPE) RETURN CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_PERIODO_SPECIALE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_PERIODO_SPECIALE(p_data_inizio                       CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
                                    p_data_fine                         CD_PERIODO_SPECIALE.DATA_FINE%TYPE
                                    ) RETURN VARCHAR2;
                                    
PROCEDURE PR_INSERISCI_PERIODO_ISP(p_data_inizio    CD_PERIODI_CINEMA.DATA_INIZIO%TYPE,
                                   p_data_fine      CD_PERIODI_CINEMA.DATA_FINE%TYPE,
                                   p_id_periodo     OUT NUMBER);
                                   
FUNCTION FU_COMPATIB_UNITA_TEMP(p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_PERIODO_SPECIALE.DATA_FINE%TYPE) RETURN NUMBER;
                                
FUNCTION FU_COMPATIB_UNITA_TEMP_TAB(p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE, p_data_fine CD_PERIODO_SPECIALE.DATA_FINE%TYPE) RETURN NUMBER;
                              

END PA_CD_PERIODO_SPECIALE; 
/

