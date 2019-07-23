CREATE OR REPLACE PACKAGE VENCD.PA_CD_RAGGR_INTERMED IS

v_stampa_raggr_intermed             VARCHAR2(3):='ON';

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              raggruppamenti intermediari
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_RAGGRUPPAMENTO_INTERMEDIARI           Inserimento di un raggruppamento intermediari nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_RAGGRUPPAMENTO_INTERMEDIARI            Eliminazione di un raggruppamento intermediari dal sistema
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_RAGGRUPPAMENTO_INTERMEDIARI
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_RAGGR_INTERMED(  p_id_ver_piano                          CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
                                        p_id_agenzia                            CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
                                        p_id_centro_media                       CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
                                       -- p_id_venditore_prodotto                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_PRODOTTO%TYPE,
                                        p_id_venditore_cliente                  CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
                                        p_id_piano                              CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
                                        p_data_decorrenza                       CD_RAGGRUPPAMENTO_INTERMEDIARI.DATA_DECORRENZA%TYPE,
							   			--p_aliquota_agenzia                      CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_AGENZIA%TYPE,
							   			--p_aliquota_venditore_cliente_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_COM%TYPE,
							   			--p_aliquota_venditore_cliente_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_DIR%TYPE,
							   			--p_aliquota_venditore_prodott_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_COM%TYPE,
							   			--p_aliquota_venditore_prodott_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_DIR%TYPE,
                                        --p_ind_sconto_sost_age                   CD_RAGGRUPPAMENTO_INTERMEDIARI.IND_SCONTO_SOST_AGE%TYPE,
                                        --p_perc_sconto_sost_age                  CD_RAGGRUPPAMENTO_INTERMEDIARI.PERC_SCONTO_SOST_AGE%TYPE,
                                        p_esito							OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_RAGGRUPPAMENTO_INTERMEDIARI
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_RAGGR_INTERMED(	p_id_raggruppamento              		IN CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE,
										p_esito			                        OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_RAGGRUPPAMENTO_INTERMEDIARI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_RAGGR_INTERMED(  p_id_ver_piano                          CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
                                        p_id_agenzia                            CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
                                        p_id_centro_media                       CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
--                                        p_id_venditore_prodotto                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_PRODOTTO%TYPE,
                                        p_id_venditore_cliente                  CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
                                        p_id_piano                              CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
                                        p_data_decorrenza                         CD_RAGGRUPPAMENTO_INTERMEDIARI.DATA_DECORRENZA%TYPE) RETURN VARCHAR2;
							   			--p_aliquota_agenzia                      CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_AGENZIA%TYPE,
							   			--p_aliquota_venditore_cliente_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_COM%TYPE,
							   			--p_aliquota_venditore_cliente_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_DIR%TYPE,
							   			--p_aliquota_venditore_prodott_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_COM%TYPE,
							   			--p_aliquota_venditore_prodott_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_DIR%TYPE,
                                      --  p_ind_sconto_sost_age                   CD_RAGGRUPPAMENTO_INTERMEDIARI.IND_SCONTO_SOST_AGE%TYPE,
                                       -- p_perc_sconto_sost_age                  CD_RAGGRUPPAMENTO_INTERMEDIARI.PERC_SCONTO_SOST_AGE%TYPE) RETURN VARCHAR2;

END PA_CD_RAGGR_INTERMED;
/

