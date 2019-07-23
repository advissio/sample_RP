CREATE OR REPLACE PACKAGE VENCD.PA_CD_BREAK IS

v_stampa_break              VARCHAR2(3):='ON';
v_stampa_tipo_break         VARCHAR2(3):='ON';

TYPE R_TIPO_BREAK IS RECORD
(
    a_id_tipo_break     CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
    a_desc_tipo_break   CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_progr_trasm       CD_TIPO_BREAK.PROGR_TRASMISSIONE%TYPE,
	a_durata_secondi    CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
    a_data_inizio       CD_TIPO_BREAK.DATA_INIZIO%TYPE,
    a_data_fine         CD_TIPO_BREAK.DATA_FINE%TYPE,
	a_flg_locale        CD_TIPO_BREAK.FLG_LOCALE%TYPE
);

TYPE C_TIPO_BREAK IS REF CURSOR RETURN R_TIPO_BREAK;
TYPE C_DETTAGLIO_TIPO_BREAK IS REF CURSOR RETURN R_TIPO_BREAK;
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              break e dei tipi break
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_BREAK
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_BREAK(p_nome_break          CD_BREAK.NOME_BREAK%TYPE,
                             p_secondi_nominali    CD_BREAK.SECONDI_NOMINALI%TYPE,
                             p_id_proiezione       CD_BREAK.ID_PROIEZIONE%TYPE,
                             p_id_tipo_break       CD_BREAK.ID_TIPO_BREAK%TYPE,
                             --p_flg_annullato       CD_BREAK.FLG_ANNULLATO%TYPE,
							 p_esito	 		   OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_BREAK
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_BREAK(p_id_break		IN CD_BREAK.ID_BREAK%TYPE,
						   p_esito			OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_BREAK
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_BREAK    (p_nome_break          CD_BREAK.NOME_BREAK%TYPE,
                             p_secondi_nominali    CD_BREAK.SECONDI_NOMINALI%TYPE,
                             p_id_proiezione       CD_BREAK.ID_PROIEZIONE%TYPE,
                             p_id_tipo_break       CD_BREAK.ID_TIPO_BREAK%TYPE) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_TIPO_BREAK       (p_desc_tipo_break     CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                                         p_progr_trasm         CD_TIPO_BREAK.PROGR_TRASMISSIONE%TYPE,
										 p_durata_secondi      CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                                         p_data_inizio         CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                                         p_data_fine           CD_TIPO_BREAK.DATA_FINE%TYPE,
                                         p_flg_locale          CD_TIPO_BREAK.FLG_LOCALE%TYPE,
										 p_esito               OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_TIPO_BREAK       (p_id_tipo_break     CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                        p_desc_tipo_break   CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                                        p_progr_trasm       CD_TIPO_BREAK.PROGR_TRASMISSIONE%TYPE,
                                        p_durata_secondi    CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                                        p_data_inizio       CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                                        p_data_fine         CD_TIPO_BREAK.DATA_FINE%TYPE,
									    p_flg_locale        CD_TIPO_BREAK.FLG_LOCALE%TYPE,
                                        p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_TIPO_BREAK( p_id_tipo_break        IN CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                 p_esito                OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_TIPO_BREAK(p_desc_tipo_break     CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                              p_durata_secondi      CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                              p_data_inizio         CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                              p_data_fine           CD_TIPO_BREAK.DATA_FINE%TYPE,
                              p_flg_locale          CD_TIPO_BREAK.FLG_LOCALE%TYPE
                              )RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_ESISTE_BREAK
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESISTE_BREAK(p_id_proiezione                 CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                         p_id_tipo_break                 CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE
                         ) RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_TIPO_BREAK (p_id_tipo_break      CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE )
                               RETURN C_DETTAGLIO_TIPO_BREAK;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TIPO_BREAK(p_id_tipo_break      CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                             p_desc_tipo_break    CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                             p_progr_trasm        CD_TIPO_BREAK.PROGR_TRASMISSIONE%TYPE,
                             p_durata_secondi     CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                             p_data_inizio        CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                             p_data_fine          CD_TIPO_BREAK.DATA_FINE%TYPE ,
							 p_flg_locale         CD_TIPO_BREAK.FLG_LOCALE%TYPE
                             )RETURN C_TIPO_BREAK;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_GENERA_NUOVI_BREAK
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_GENERA_NUOVI_BREAK (p_id_tipo_break IN  CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                 p_esito         OUT INTEGER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_GENERA_BREAK_PROIEZIONE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_GENERA_BREAK_PROIEZIONE (p_id_proiezione   IN  CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                      p_id_schermo      IN  CD_SCHERMO.ID_SCHERMO%TYPE,
                                      p_data_proiezione IN  CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                      p_esito         OUT INTEGER);
--    
/*                                  
PROCEDURE PR_GENERA_BREAK_PRO_TEMP (p_id_proiezione   IN  CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                    p_id_schermo      IN  CD_SCHERMO.ID_SCHERMO%TYPE,
                                    p_data_proiezione IN  CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                    p_esito         OUT INTEGER);                                      
*/

END PA_CD_BREAK; 
/

