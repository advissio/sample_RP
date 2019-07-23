CREATE OR REPLACE PACKAGE VENCD.PA_CD_MAGGIORAZIONE IS

v_stampa_maggiorazione             VARCHAR2(3):='ON';

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione delle
--              maggiorazioni
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_MAGGIORAZIONE           Inserimento di una maggiorazione nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_MAGGIORAZIONE             Eliminazione di una maggiorazione dal sistema
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_MAGGIORAZIONE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_MAGGIORAZIONE(   p_descrizione                  CD_MAGGIORAZIONE.DESCRIZIONE%TYPE,
                                        p_id_tipo_magg                 CD_MAGGIORAZIONE.ID_TIPO_MAGG%TYPE,
                                        p_percentuale_variazione       CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE%TYPE,
                                        p_esito					       OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_MAGGIORAZIONE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_MAGGIORAZIONE(	p_id_maggiorazione		IN CD_MAGGIORAZIONE.ID_MAGGIORAZIONE%TYPE,
								    p_esito     			OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_MAGGIORAZIONE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_MAGGIORAZIONE ( p_descrizione                  CD_MAGGIORAZIONE.DESCRIZIONE%TYPE,
                                   p_id_tipo_magg                 CD_MAGGIORAZIONE.ID_TIPO_MAGG%TYPE,
                                   p_percentuale_variazione       CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE%TYPE
                                   ) RETURN VARCHAR2;

END PA_CD_MAGGIORAZIONE;
/

