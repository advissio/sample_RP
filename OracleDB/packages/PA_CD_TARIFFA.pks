CREATE OR REPLACE PACKAGE VENCD.PA_CD_TARIFFA IS
--
ERR_VARIAZIONE_TARIFFA  exception;
v_stampa_tariffa            VARCHAR2(3):='ON';
TYPE R_FORMATO_ACQUISTABILE IS RECORD
(
    a_id_formato        CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
    a_id_tipo_formato   CD_FORMATO_ACQUISTABILE.ID_TIPO_FORMATO%TYPE,
    a_tipo_formato      CD_TIPO_FORMATO.TIPO_FORMATO%TYPE,
    a_desc_formato      CD_TIPO_FORMATO.DESC_FORMATO%TYPE,
    a_id_coeff          CD_FORMATO_ACQUISTABILE.ID_COEFF%TYPE,
    a_durata            CD_COEFF_CINEMA.DURATA%TYPE,
    a_aliquota          CD_COEFF_CINEMA.ALIQUOTA%TYPE,
    a_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
    a_flg_valid         CD_FORMATO_ACQUISTABILE.FLG_VALID%TYPE,
    a_data_inizio_val   CD_COEFF_CINEMA.DATA_INIZIO_VAL%TYPE,
    a_data_fine_val     CD_COEFF_CINEMA.DATA_FINE_VAL%TYPE
);
TYPE R_CODICI_LUOGHI IS RECORD
(
    a_codice        CD_LUOGO.CODICE%TYPE
);
TYPE C_FORMATO_ACQUISTABILE      IS REF CURSOR RETURN R_FORMATO_ACQUISTABILE;
TYPE C_DETTAGLIO_FORMATO_ACQUIST IS REF CURSOR RETURN R_FORMATO_ACQUISTABILE;
TYPE C_CODICI_LUOGHI             IS REF CURSOR RETURN R_CODICI_LUOGHI;
--
TYPE R_FORMATO_TAB IS RECORD
(
    a_id_formato        CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
    a_durata            CD_COEFF_CINEMA.DURATA%TYPE
);
TYPE C_FORMATO_TAB      IS REF CURSOR RETURN R_FORMATO_TAB;
--
TYPE R_COEFF_CINEMA IS RECORD
(
    a_id_coeff          CD_COEFF_CINEMA.ID_COEFF%TYPE,
    a_durata            CD_COEFF_CINEMA.DURATA%TYPE,
    a_aliquota          CD_COEFF_CINEMA.ALIQUOTA%TYPE,
    a_data_inizio       CD_COEFF_CINEMA.DATA_INIZIO_VAL%TYPE,
    a_data_fine         CD_COEFF_CINEMA.DATA_FINE_VAL%TYPE
);
TYPE C_COEFF_CINEMA      IS REF CURSOR RETURN R_COEFF_CINEMA;
--
--
TYPE R_TIPO_FORMATO_ACQUISTABILE IS RECORD
(
    a_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
    a_tipo_formato      CD_TIPO_FORMATO.TIPO_FORMATO%TYPE,
    a_desc_formato      CD_TIPO_FORMATO.DESC_FORMATO%TYPE
);
TYPE C_TIPO_FORMATO IS REF CURSOR RETURN R_TIPO_FORMATO_ACQUISTABILE;
--
TYPE R_MAGGIORAZIONE IS RECORD
(
    a_id_maggiorazione              CD_MAGGIORAZIONE.ID_MAGGIORAZIONE%TYPE,
    a_descrizione                   CD_MAGGIORAZIONE.DESCRIZIONE%TYPE,
    a_percentuale                   CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE%TYPE,
    a_importo                       NUMBER,
    a_id_tipo_maggiorazione         CD_MAGGIORAZIONE.ID_TIPO_MAGG%TYPE,
    a_desc_tipo_maggiorazione       CD_TIPO_MAGG.TIPO_MAGG_DESC%TYPE
);
--
TYPE C_MAGGIORAZIONE      IS REF CURSOR RETURN R_MAGGIORAZIONE;

TYPE R_POSIZIONE_RIGORE IS RECORD
(
    a_id_posizione_fissa            CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    a_id_descrizione                CD_POSIZIONE_RIGORE.DESCRIZIONE%TYPE,
    a_percentuale                   CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE%TYPE
);
TYPE C_POSIZIONE_RIGORE      IS REF CURSOR RETURN R_POSIZIONE_RIGORE;
--
TYPE R_TARIFFA IS RECORD
(
    a_id_tariffa                CD_TARIFFA.ID_TARIFFA%TYPE,
    a_importo                   CD_TARIFFA.IMPORTO%TYPE,
    a_tipo_tariffa              VARCHAR2(255),
    a_desc_prodotto_vendita     VARCHAR2(255),
    a_listino                   VARCHAR2(255),
    a_formato_acquistabile      VARCHAR2(255),
    a_sconto_stagionale         CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
    a_data_inizio               CD_TARIFFA.DATA_INIZIO%TYPE,
    a_data_fine                 CD_TARIFFA.DATA_FINE%TYPE,
    a_desc_tariffa              CD_TARIFFA.DESC_TARIFFA%TYPE,
    a_id_listino                CD_TARIFFA.ID_LISTINO%TYPE,
    a_id_formato_acquistabile   CD_TARIFFA.ID_FORMATO%TYPE,
    a_id_tipo_tariffa           CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
    a_id_tipo_cinema            CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
    a_id_prodotto_vendita       CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
    a_id_misura_prd_ve          CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
    a_flg_stagionale            CD_TARIFFA.FLG_STAGIONALE%TYPE,
    a_desc_tipo_cinema          CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_desc_unita                CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE
);
--
TYPE C_TARIFFA IS REF CURSOR RETURN R_TARIFFA;
--
TYPE R_TARIFFA_EXP IS RECORD
(
    a_id_tariffa                CD_TARIFFA.ID_TARIFFA%TYPE,
    a_importo                   CD_TARIFFA.IMPORTO%TYPE,
    a_data_inizio               CD_TARIFFA.DATA_INIZIO%TYPE,
    a_data_fine                 CD_TARIFFA.DATA_FINE%TYPE,
    a_flg_stagionale            CD_TARIFFA.FLG_STAGIONALE%TYPE,
    a_id_misura_prd_ve          CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
    a_id_formato                CD_TARIFFA.ID_FORMATO%TYPE,
    a_id_prodotto_vendita       CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
    a_id_tipo_tariffa           CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
    a_id_tipo_cinema            CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
    a_id_listino                CD_TARIFFA.ID_LISTINO%TYPE,
    a_nome_circuito             CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_desc_mod_vendita          CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
    a_desc_prodotto             CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_desc_tipo_break           CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_durata                    CD_COEFF_CINEMA.DURATA%TYPE,
    a_desc_unita                CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE
);
--
TYPE C_TARIFFA_EXP IS REF CURSOR RETURN R_TARIFFA_EXP;
TYPE R_TIPO_TARIFFA IS RECORD
(
    a_id_tipo_tariffa       CD_TIPO_TARIFFA.ID_TIPO_TARIFFA%TYPE,
    a_desc_tipo_tariffa     CD_TIPO_TARIFFA.DESC_TIPO_TARIFFA%TYPE
);
--
TYPE C_TIPO_TARIFFA IS REF CURSOR RETURN R_TIPO_TARIFFA;
--
TYPE R_TIPO_MISURA_PRD_VE IS RECORD
(
    a_id_misura_prd_ve  CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE%TYPE,
    a_desc_unita        CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
    a_prodotto_pubb     CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_gruppo            CD_GRUPPO_TIPI_PUBB.DESC_GRUPPO%TYPE
);
--
TYPE C_TIPO_MISURA_PRD_VE IS REF CURSOR RETURN R_TIPO_MISURA_PRD_VE;
--
-- types aggiunti da daniela spezia, ottobre 2009, per il ricalcolo della tariffa
TYPE R_PROD_ACQ_CALC_TARIF IS RECORD
(
    a_id_prod_acq          CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_id_prod_vend         cd_prodotto_acquistato.ID_PRODOTTO_VENDITA%TYPE,
    a_tariffa              CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    a_imp_lordo            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    a_imp_netto            CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE,
    a_maggiorazione        cd_prodotto_acquistato.IMP_MAGGIORAZIONE%TYPE,
    a_recupero             cd_prodotto_acquistato.IMP_RECUPERO%TYPE,
    a_sanatoria            cd_prodotto_acquistato.IMP_SANATORIA%TYPE,
    a_tipo_fam_pubb        cd_pianificazione.COD_CATEGORIA_PRODOTTO%TYPE,
    a_flg_tariffa_var      cd_prodotto_acquistato.FLG_TARIFFA_VARIABILE%TYPE,
    a_data_inizio           cd_prodotto_acquistato.DATA_INIZIO%TYPE,
    a_data_fine             cd_prodotto_acquistato.DATA_FINE%TYPE,
    a_id_misura_temp       cd_prodotto_acquistato.ID_MISURA_PRD_VE%TYPE
);
--
TYPE C_PROD_ACQ_CALC_TARIF IS REF CURSOR RETURN R_PROD_ACQ_CALC_TARIF;
--
TYPE R_IMPORTI_PROD IS RECORD
(
    a_id_prod_acq          CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_id_importi_prod      cd_importi_prodotto.ID_IMPORTI_PRODOTTO%TYPE,
    a_tipo_contratto       cd_importi_prodotto.TIPO_CONTRATTO%TYPE,
    a_imp_netto            cd_importi_prodotto.IMP_NETTO%TYPE,
    a_imp_sc_comm          cd_importi_prodotto.IMP_SC_COMM%TYPE--,
--    a_perc_sconto_age      cd_importi_prodotto.PERC_SCONTO_SOST_AGE%TYPE,
--    a_aliquota             cd_importi_prodotto.PERC_VEND_CLI%TYPE
);
--
TYPE C_IMPORTI_PROD IS REF CURSOR RETURN R_IMPORTI_PROD;
--
TYPE R_INTERVALLO_DATE IS RECORD
(
    a_data_min              CD_TARIFFA.DATA_INIZIO%TYPE,
    a_data_max              CD_TARIFFA.DATA_FINE%TYPE
);
TYPE C_INTERVALLO_DATE IS REF CURSOR RETURN R_INTERVALLO_DATE;
--
--
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione delle
--              tariffe
--              (Luglio 2009) aggiunte procedure/funzioni per la gestione dei formati
--              acquistabili
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_TARIFFA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_TARIFFA(  p_id_prodotto_vendita              CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                 p_id_tipo_tariffa                  CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                 p_id_formato                       CD_TARIFFA.ID_FORMATO%TYPE,
                                 p_id_misura_prd_vendita            CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                 p_id_listino                       CD_TARIFFA.ID_LISTINO%TYPE,
                                 p_id_tipo_cinema                   CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                                 p_importo                          CD_TARIFFA.IMPORTO%TYPE,
                                 p_data_inizio                      CD_TARIFFA.DATA_INIZIO%TYPE,
                                 p_data_fine                        CD_TARIFFA.DATA_FINE%TYPE,
                                 p_flg_stagionale                   CD_TARIFFA.FLG_STAGIONALE%TYPE,
                                 p_esito                            OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_TARIFFA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_TARIFFA(  p_id_tariffa               CD_TARIFFA.ID_TARIFFA%TYPE,
                                p_id_prodotto_vendita      CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                p_id_tipo_tariffa          CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                p_id_formato               CD_TARIFFA.ID_FORMATO%TYPE,
                                p_id_misura_prd_vendita    CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                p_id_listino               CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_tipo_cinema           CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                                p_importo                  CD_TARIFFA.IMPORTO%TYPE,
                                p_data_inizio              CD_TARIFFA.DATA_INIZIO%TYPE,
                                p_data_fine                CD_TARIFFA.DATA_FINE%TYPE,
                                p_flg_stagionale           CD_TARIFFA.FLG_STAGIONALE%TYPE,
                                p_esito                    OUT NUMBER,
                                p_piani_errati  OUT VARCHAR2);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TARIFFA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TARIFFA(  p_id_tariffa                CD_TARIFFA.ID_TARIFFA%TYPE,
                            p_id_tipo_tariffa           CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                            p_id_prodotto_vendita       CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                            p_id_listino                CD_TARIFFA.ID_LISTINO%TYPE,
                            p_id_formato_acquistabile   CD_TARIFFA.ID_FORMATO%TYPE,
                            p_data_inizio               CD_TARIFFA.DATA_INIZIO%TYPE,
                            p_data_fine                 CD_TARIFFA.DATA_FINE%TYPE)
                            RETURN C_TARIFFA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TIPO_TARIFFA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TIPO_TARIFFA( p_id_tipo_tariffa    CD_TIPO_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                p_desc_tipo_tariffa  CD_TIPO_TARIFFA.DESC_TIPO_TARIFFA%TYPE)
                            RETURN C_TIPO_TARIFFA;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_TARIFFA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_TARIFFA(p_id_tariffa     IN CD_TARIFFA.ID_TARIFFA%TYPE,
                             p_esito          OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_TARIFFA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_TARIFFA(p_id_prodotto_vendita              CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                           p_id_tipo_tariffa                  CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                           p_id_formato                       CD_TARIFFA.ID_FORMATO%TYPE,
                           p_id_misura_prd_vendita            CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                           p_id_listino                       CD_TARIFFA.ID_LISTINO%TYPE,
                           p_id_tipo_cinema                   CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                           p_importo                          CD_TARIFFA.IMPORTO%TYPE,
                           p_data_inizio                      CD_TARIFFA.DATA_INIZIO%TYPE,
                           p_data_fine                        CD_TARIFFA.DATA_FINE%TYPE,
                           p_flag_stagionale                  CD_TARIFFA.FLG_STAGIONALE%TYPE
                           ) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_FORMATO_ACQUIST(p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                       p_durata            CD_COEFF_CINEMA.DURATA%TYPE,
                                       p_aliquota          CD_COEFF_CINEMA.ALIQUOTA%TYPE,
                                       p_data_inizio_val   CD_COEFF_CINEMA.DATA_INIZIO_VAL%TYPE,
                                       p_data_fine_val     CD_COEFF_CINEMA.DATA_FINE_VAL%TYPE,
                                       p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
                                       p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_FORMATO_ACQUIST( p_id_formato        CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
                                       p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                       p_id_coeff          CD_FORMATO_ACQUISTABILE.ID_COEFF%TYPE,
                                       p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
                                       p_flg_valid         CD_FORMATO_ACQUISTABILE.FLG_VALID%TYPE,
                                       p_data_fine_val     CD_COEFF_CINEMA.DATA_FINE_VAL%TYPE,
                                       p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_FORMATO_ACQUIST(p_id_formato        IN CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
                                     p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_FORMATO_ACQUIST(p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                   p_id_coeff          CD_FORMATO_ACQUISTABILE.ID_COEFF%TYPE,
                                   p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE)
                                   RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_FORMATO_ACQUIST (p_id_formato      CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE )
                               RETURN C_DETTAGLIO_FORMATO_ACQUIST;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_COEFF_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_COEFF_CINEMA RETURN C_COEFF_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TIPI_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TIPI_FORMATO_ACQUIST( p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                        p_tipo_formato      CD_TIPO_FORMATO.TIPO_FORMATO%TYPE,
                                        p_desc_formato      CD_TIPO_FORMATO.DESC_FORMATO%TYPE)
                                        RETURN C_TIPO_FORMATO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_FORMATO_ACQUIST( p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                   p_id_coeff          CD_FORMATO_ACQUISTABILE.ID_COEFF%TYPE,
                                   p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
                                   p_flg_valid         CD_FORMATO_ACQUISTABILE.FLG_VALID%TYPE)
                                   RETURN C_FORMATO_ACQUISTABILE;

FUNCTION FU_GET_FORMATO_TAB
RETURN C_FORMATO_TAB;

FUNCTION FU_GET_ALIQUOTA(p_id_formato  CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE)
RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_GIORNI_TRASCORSI
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_GIORNI_TRASCORSI(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, p_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE) RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_MAGGIORAZIONI
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_MAGGIORAZIONI(p_id_tipo_magg CD_MAGGIORAZIONE.ID_TIPO_MAGG%TYPE) RETURN C_MAGGIORAZIONE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_POSIZIONI_RIGORE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_POSIZIONI_RIGORE RETURN C_POSIZIONE_RIGORE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_MAGGIORAZIONI_PRODOTTO
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_MAGGIORAZIONI_PRODOTTO(p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_MAGGIORAZIONE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CALCOLA_MAGGIORAZIONE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_CALCOLA_MAGGIORAZIONE(p_tariffa NUMBER, p_percentuale NUMBER) RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_TARIFFA_RIPARAMETRATA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_TARIFFA_RIPARAMETRATA(p_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE, p_id_formato CD_TARIFFA.ID_FORMATO%TYPE) RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_MAGGIORAZIONI_NON_FISSE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_MAGGIORAZIONI_NON_FISSE(p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE) RETURN C_MAGGIORAZIONE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_MISURE_PRD_VE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_MISURE_PRD_VE(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN C_TIPO_MISURA_PRD_VE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_DATE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_DATE(p_data1_inizio DATE, p_data1_fine DATE, p_data2_inizio DATE, p_data2_fine DATE ) RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_DATE_INFO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_DATE_INFO(p_data1_inizio DATE, p_data1_fine DATE, p_data2_inizio DATE, p_data2_fine DATE ) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VER_CREABILITA_TARIFFA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VER_CREABILITA_TARIFFA(p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                   p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
                                   p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                                   p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                                   p_id_misura_prd_vendita CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                   p_id_tipo_tariffa       CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                   p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE,
                                   p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE)
                                   RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VER_MODIFICABILITA_TARIFFA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VER_MODIFICABILITA_TARIFFA(p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                       p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
                                       p_id_tariffa            CD_TARIFFA.ID_TARIFFA%TYPE,
                                       p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                                       p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                                       p_id_misura_prd_vendita CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                       p_id_tipo_tariffa       CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                       p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE,
                                       p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE)
                                   RETURN INTEGER;
-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_GENERA_AMBIENTI
-------------------------------------------------------------------------------------------------
FUNCTION FU_GENERA_AMBIENTI( p_id_prodotto_vendita      CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                              p_id_listino               CD_TARIFFA.ID_LISTINO%TYPE,
                              p_data_inizio              CD_TARIFFA.DATA_INIZIO%TYPE,
                              p_data_fine                CD_TARIFFA.DATA_FINE%TYPE) RETURN INTEGER;
-----------------------------------------------------------------------------------------------------
-- Function PR_ELIMINA_AMBIENTI
-------------------------------------------------------------------------------------------------
FUNCTION PR_ELIMINA_AMBIENTI(  p_id_tariffa        IN CD_TARIFFA.ID_TARIFFA%TYPE,
                                p_data_inizio_canc  DATE,
                                p_data_fine_canc    DATE) RETURN INTEGER;
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_BR
-------------------------------------------------------------------------------------------------
PROCEDURE PR_REFRESH_TARIFFE_BR(p_id_listino         CD_TARIFFA.ID_LISTINO%TYPE,
                             p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                             p_id_circuito_break  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK%TYPE,
                             p_data_proiezione    CD_PROIEZIONE.DATA_PROIEZIONE%TYPE);
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_CIN
-------------------------------------------------------------------------------------------------
PROCEDURE PR_REFRESH_TARIFFE_CIN(p_id_listino         CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_id_circuito_cinema  CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA%TYPE);
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_ATR
-------------------------------------------------------------------------------------------------
PROCEDURE PR_REFRESH_TARIFFE_ATR(p_id_listino         CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_id_circuito_atrio  CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO%TYPE);
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_SAL
-------------------------------------------------------------------------------------------------
PROCEDURE PR_REFRESH_TARIFFE_SAL(p_id_listino         CD_TARIFFA.ID_LISTINO%TYPE,
                                 p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_id_circuito_sala  CD_CIRCUITO_SALA.ID_CIRCUITO_SALA%TYPE);
--
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_ALLINEA_TARIFFA_PER_ELIM    Daniela Spezia, Altran, ottobre 2009
-- questa procedura permette il ricalcolo della tariffa (e di tutti gli importi ad essa collegati
-- a livello di prodotto acquistato) a seguito di una eliminazione di sala o atrio
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ALLINEA_TARIFFA_PER_ELIM(p_id_sala             cd_sala.ID_SALA%TYPE,
                                   p_id_atrio               cd_atrio.ID_ATRIO%TYPE,
                                   p_id_circuito            cd_circuito.ID_CIRCUITO%TYPE,
                                   p_id_listino             cd_listino.ID_LISTINO%TYPE,
                                   p_esito                   OUT NUMBER,
                                   p_piani_errati           OUT VARCHAR2);
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_RICALCOLA_TARIFFE       Daniela Spezia, Altran, ottobre 2009
-- questa procedura esegue l'effettivo ricalcolo della tariffa (e di tutti gli importi ad essa collegati
-- a livello di prodotto acquistato) a seguito di una eliminazione di sala o atrio per l'elenco di
-- prodotti acquistati correlati a quella sala o atrio; dopo aver determinato i nuovi importi
-- aggiorna la banca dati (tabelle cd_prodotto_acquistato e cd_import_prodotto)
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFE( p_lista_prod_acq         C_PROD_ACQ_CALC_TARIF,
                                p_id_sala                cd_sala.ID_SALA%TYPE,
                                p_id_atrio               cd_atrio.ID_ATRIO%TYPE,
                                p_esito                  OUT NUMBER,
                                p_piani_errati           OUT VARCHAR2);
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_RICALCOLA_TARIFFA_VARFIX       Daniela Spezia, Altran, ottobre 2009
-- questa procedura esegue l'effettivo ricalcolo della tariffa (e di tutti gli altri importi) per il
-- prodotto acquistato fornito in input; per eseguire il ricalcolo viene richiamata la procedura
-- PA_CD_IMPORTI.MODIFICA_IMPORTI() con il nuovo importo della tariffa
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA_VARFIX(p_id_prodotto_acquistato  cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_id_prodotto_vendita   cd_prodotto_vendita.ID_PRODOTTO_VENDITA%TYPE,
                                        p_tipo_famiglia_pubb    cd_pianificazione.COD_CATEGORIA_PRODOTTO%TYPE,
                                        p_id_sala               cd_sala.ID_SALA%TYPE,
                                        p_id_atrio              cd_atrio.ID_ATRIO%TYPE,
                                        p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
                                        p_maggiorazione         cd_prodotto_acquistato.IMP_MAGGIORAZIONE%TYPE,
                                        p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
                                        p_lordo_c               NUMBER,
                                        p_lordo_d               NUMBER,
                                        p_netto_c               cd_importi_prodotto.IMP_NETTO%TYPE,
                                        p_netto_d               cd_importi_prodotto.IMP_NETTO%TYPE,
--                                        p_perc_sc_c             cd_importi_prodotto.PERC_SCONTO_SOST_AGE%TYPE,
--                                        p_perc_sc_d             cd_importi_prodotto.PERC_SCONTO_SOST_AGE%TYPE,
                                        p_sconto_c              cd_importi_prodotto.IMP_SC_COMM%TYPE,
                                        p_sconto_d              cd_importi_prodotto.IMP_SC_COMM%TYPE,
                                        p_sanatoria             cd_prodotto_acquistato.IMP_SANATORIA%TYPE,
                                        p_recupero              cd_prodotto_acquistato.IMP_RECUPERO%TYPE,
                                        p_id_importi_c          cd_importi_prodotto.ID_IMPORTI_PRODOTTO%TYPE,
                                        p_id_importi_d          cd_importi_prodotto.ID_IMPORTI_PRODOTTO%TYPE,
                                        p_flg_tariffa_var       cd_prodotto_acquistato.FLG_TARIFFA_VARIABILE%TYPE,
                                        p_data_inizio           cd_prodotto_acquistato.DATA_INIZIO%TYPE,
                                        p_data_fine             cd_prodotto_acquistato.DATA_FINE%TYPE,
                                        p_misura_temp           cd_prodotto_acquistato.ID_MISURA_PRD_VE%TYPE,
                                        p_esito                  OUT NUMBER);
--
-----------------------------------------------------------------------------------------------------
-- Function FU_GET_NUM_SALE_PV       Daniela Spezia, Altran, ottobre 2009
-- questa funzione conta il numero di sale correlate al prodotto di vendita indicato
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_SALE_PV(p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE)
                        RETURN NUMBER;
--
-----------------------------------------------------------------------------------------------------
-- Function FU_GET_NUM_ATRI_PV       Daniela Spezia, Altran, ottobre 2009
-- questa funzione conta il numero di atrii correlati al prodotto di vendita indicato
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_ATRI_PV(p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE)
                        RETURN NUMBER;
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_GET_IMPORTI_PROD           Daniela Spezia, Altran, ottobre 2009
-- questa procedura restituisce, dato l'id prodotto acquistato, i dati relativi agli importi commerciali
-- o direzioni ad esso collegati
-------------------------------------------------------------------------------------------------
PROCEDURE PR_GET_IMPORTI_PROD(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_tipo_contratto    cd_importi_prodotto.TIPO_CONTRATTO%TYPE,
                                p_record_importi    OUT R_IMPORTI_PROD,
                                p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TARIFFA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INTERV_MOD_TAR( p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                            p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                            p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                            p_id_misura_prd_ve      CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                            p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                            p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE
                          )
                          RETURN C_INTERVALLO_DATE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_COMPATIBILITA_TARIFFA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_COMPATIBILITA_TARIFFA( p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                   p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
                                   p_id_tariffa            CD_TARIFFA.ID_TARIFFA%TYPE,
                                   p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                                   p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                                   p_id_misura_prd_vendita CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                   p_id_tipo_tariffa       CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                   p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE,
                                   p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE)
                               RETURN INTEGER; 

function fu_get_importo(p_id_tariffa cd_tariffa.id_tariffa%type) return cd_tariffa.importo%type;                                                        
function fu_tariffa_to_export(p_id_listino cd_tariffa.id_listino%type,p_data_riferimento date) return c_tariffa_exp;
                                
END PA_CD_TARIFFA; 
/

