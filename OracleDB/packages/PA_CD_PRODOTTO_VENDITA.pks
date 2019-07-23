CREATE OR REPLACE PACKAGE VENCD.PA_CD_PRODOTTO_VENDITA IS

v_stampa_prodotto_vendita             VARCHAR2(3):='ON';

TYPE R_MANIF IS RECORD
(
    a_cod_man        PC_MANIF.COD_MAN%TYPE,
    a_des_man       PC_MANIF.DES_MAN%TYPE
);
TYPE C_MANIF IS REF CURSOR RETURN R_MANIF;

TYPE R_UNITA_MIS_TEMP IS RECORD
(
    a_id_unita        CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    a_desc_unita      CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE
);
TYPE C_UNITA_MIS_TEMP IS REF CURSOR RETURN R_UNITA_MIS_TEMP;


TYPE R_MODALITA_VENDITA IS RECORD
(
    a_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita      CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE
);
TYPE C_MODALITA_VENDITA IS REF CURSOR RETURN R_MODALITA_VENDITA;
/*Tipo utilizzato per la ricerca di un prodotto di vendita 
  all'interno del popup di tariffa*/
TYPE R_ELENCO_PRODOTTO_VEND IS RECORD
(
    a_id_prodotto_vendita   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_id_prodotto_pubb      CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
    a_desc_prodotto         CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
	a_desc_tipo_break       CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
	a_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita      CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
    a_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito         CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
    a_desc_fascia           CD_FASCIA.DESC_FASCIA%TYPE
);
TYPE C_ELENCO_PRODOTTO_VEND IS REF CURSOR RETURN R_ELENCO_PRODOTTO_VEND;
/*Tipo utilizzato per la ricerca di un prodotto di vendita*/
TYPE R_LISTA_PRD_VND IS RECORD
(
    a_id_prodotto_vendita   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_id_prodotto_pubb      CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
    a_desc_prodotto         CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
	a_desc_tipo_break       CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
	a_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita      CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
    a_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito         CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
    a_desc_fascia           CD_FASCIA.DESC_FASCIA%TYPE,
    a_id_unita              VARCHAR2(20),
    a_desc_unita            CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
    a_nome_target           cd_target.nome_target%type
);
TYPE C_LISTA_PRD_VND IS REF CURSOR RETURN R_LISTA_PRD_VND;

/*Tipo utilizzato per ottenere le informazioni di dettaglio di un prodotto di vendita*/
TYPE R_DETTAGLIO_PRODOTTO_VENDITA IS RECORD
(
    a_id_prodotto_vendita   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_flg_annullato         CD_PRODOTTO_VENDITA.FLG_ANNULLATO%TYPE,
    a_id_prodotto_pubb      CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
    a_desc_prodotto         CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
	a_desc_tipo_break       CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
	a_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita      CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
    a_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito         CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_tariffa            CD_TARIFFA.ID_TARIFFA%TYPE,
    a_importo               CD_TARIFFA.IMPORTO%TYPE,
    a_data_inizio_tariffa   CD_TARIFFA.DATA_INIZIO%TYPE,
    a_data_fine_tariffa     CD_TARIFFA.DATA_FINE%TYPE,
    a_cod_man               PC_MANIF.COD_MAN%TYPE,
    a_des_man               PC_MANIF.DES_MAN%TYPE,
    a_definito_al_listino   CD_PRODOTTO_VENDITA.FLG_DEFINITO_A_LISTINO%TYPE,
    a_id_target             CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
    a_nome_target           CD_TARGET.NOME_TARGET%TYPE,
    a_flg_abbinato          CD_PRODOTTO_VENDITA.FLG_ABBINATO%TYPE,
    a_flg_segui_il_film     CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE,
    a_misura_pdr_vendita    CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
    a_id_unita              CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE,
    a_unita_temporale       CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE
);
TYPE C_DETTAGLIO_PRODOTTO_VENDITA IS REF CURSOR RETURN R_DETTAGLIO_PRODOTTO_VENDITA;
--
-- tipi inseriti da Spezia per la modifica dei secondi assegnati
TYPE R_MODIFICA_SEC_ASSEGNATI IS RECORD
(
    a_id_prodotto_vendita   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_id_listino            cd_circuito_break.ID_LISTINO%TYPE,
    a_desc_listino          cd_listino.DESC_LISTINO%TYPE,
    a_id_circuito           cd_circuito_break.ID_CIRCUITO%TYPE,
    a_nome_circuito         cd_circuito.NOME_CIRCUITO%TYPE,
    a_id_tipo_break         cd_prodotto_vendita.ID_TIPO_BREAK%TYPE,
    a_desc_tipo_break       cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    a_id_mod_vendita        cd_prodotto_vendita.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita      cd_modalita_vendita.DESC_MOD_VENDITA%TYPE,
    a_numero_break          NUMBER(9),
    a_secondi_assegnati     cd_break_vendita.SECONDI_ASSEGNATI%TYPE,
    a_secondi_totali        cd_tipo_break.DURATA_SECONDI%TYPE
);
TYPE C_MODIFICA_SEC_ASSEGNATI IS REF CURSOR RETURN R_MODIFICA_SEC_ASSEGNATI;
--
TYPE R_MOD_SEC_ASSE_PROD_SCELTO IS RECORD
(
    a_id_listino            cd_circuito_break.ID_LISTINO%TYPE,
    a_id_prodotto_vendita   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_numero_break          NUMBER(9),
    a_secondi_assegnati     cd_break_vendita.SECONDI_ASSEGNATI%TYPE,
    a_durata_sec_totali     cd_tipo_break.DURATA_SECONDI%TYPE,
    a_data_iniz             PERIODI.DATA_INIZ%TYPE,
    a_data_fine             PERIODI.DATA_FINE%TYPE
);
TYPE C_MOD_SEC_ASSE_PROD_SCELTO IS REF CURSOR RETURN R_MOD_SEC_ASSE_PROD_SCELTO;
--
TYPE R_MOD_SEC_ASSE_PROD_COMPL IS RECORD
(
    a_id_listino            cd_circuito_break.ID_LISTINO%TYPE,
    a_id_prodotto_vendita   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_numero_break          NUMBER(9),
    a_secondi_assegnati     cd_break_vendita.SECONDI_ASSEGNATI%TYPE,
    a_desc_prodotto         CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_nome_circuito         cd_circuito.NOME_CIRCUITO%TYPE,
    a_desc_mod_vendita      cd_modalita_vendita.DESC_MOD_VENDITA%TYPE,
    a_desc_tipo_break       cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    a_data_iniz             PERIODI.DATA_INIZ%TYPE,
    a_data_fine             PERIODI.DATA_FINE%TYPE
);
TYPE C_MOD_SEC_ASSE_PROD_COMPL IS REF CURSOR RETURN R_MOD_SEC_ASSE_PROD_COMPL;

TYPE R_VER_ASSEGNATO IS RECORD
(
    a_nome_cinema       CD_CINEMA.NOME_CINEMA%TYPE,
    a_pubb_locale       CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
    a_id_sala           CD_SALA.ID_SALA%TYPE,
    a_nome_sala         CD_SALA.NOME_SALA%TYPE,
    a_data_iniz         periodi.DATA_INIZ%TYPE,
    a_data_fine         periodi.DATA_FINE%TYPE,
    a_anno              periodi.ANNO%TYPE,
    a_ciclo             periodi.CICLO%TYPE,
    a_periodo           periodi.PER%TYPE,
    a_sec_vendibili     INTEGER,
    a_sec_assegnati     INTEGER
);
TYPE C_VER_ASSEGNATO IS REF CURSOR RETURN R_VER_ASSEGNATO;

TYPE R_DETT_ASSEGNATO IS RECORD
(
    a_sec_assegnati     INTEGER,
    a_sec_nominali      INTEGER,
    a_id_prod_vendita   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE
);
TYPE C_DETT_ASSEGNATO IS REF CURSOR RETURN R_DETT_ASSEGNATO;

TYPE R_COD_TIPO_PUBB IS RECORD
(
    a_id_tipo_pubb  CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
    a_cod_tipo_pubb CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE
);
TYPE C_COD_TIPO_PUBB IS REF CURSOR RETURN R_COD_TIPO_PUBB;
--
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              prodotti di vendita
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_PRODOTTO_VENDITA           Inserimento di un prodotto di vendita nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_MODIFICA_PRODOTTO_VENDITA            Modifica di un prodotto di vendita dal sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_PRODOTTO_VENDITA            Eliminazione di un prodotto di vendita dal sistema
-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_DETTAGLIO_PRODOTTO_VENDITA          Visualizza il dettaglio dei prodotti di vendita in base al listino
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_PRODOTTO_VENDITA(p_id_circuito               CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
                                        p_id_mod_vendita            CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE,
                                        p_id_prodotto_pubb          CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE,
                                        p_id_tipo_break             CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE,
                                        p_cod_man                   CD_PRODOTTO_VENDITA.COD_MAN%TYPE,
                                        p_flg_definito_a_listino    CD_PRODOTTO_VENDITA.FLG_DEFINITO_A_LISTINO%TYPE,
                                        p_id_target                 CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
                                        p_flg_abbinato              CD_PRODOTTO_VENDITA.FLG_ABBINATO%TYPE,
                                        p_flg_segui_il_film         CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE,
										p_esito				OUT NUMBER);


-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_PRODOTTO_VENDITA( p_id_prodotto_vendita       CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                        p_id_circuito               CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
                                        p_id_mod_vendita            CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE,
                                        p_id_prodotto_pubb          CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE,
                                        p_id_tipo_break             CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE,
                                        p_cod_man                   CD_PRODOTTO_VENDITA.COD_MAN%TYPE,
                                        p_flg_definito_a_listino    CD_PRODOTTO_VENDITA.FLG_DEFINITO_A_LISTINO%TYPE,
                                        p_id_target                 CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
                                        p_flg_abbinato              CD_PRODOTTO_VENDITA.FLG_ABBINATO%TYPE,
                                        p_flg_segui_il_film         CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE,
                                        p_esito				  OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_PRODOTTO_VENDITA(	p_id_prodotto_vendita		IN CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
										p_esito			            OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_PRODOTTO_VENDITA(p_id_circuito       CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
                                    p_id_mod_vendita    CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE,
                                    p_id_prodotto_pubb  CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE,
                                    p_id_fascia         CD_PRODOTTO_VENDITA.ID_FASCIA%TYPE,
                                    p_id_tipo_break     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE,
                                    p_cod_man           CD_PRODOTTO_VENDITA.COD_MAN%TYPE,
									p_flg_annullato     CD_PRODOTTO_VENDITA.FLG_ANNULLATO%TYPE)
									RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_ELENCO_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_PRODOTTO_VENDITA (p_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
                                    p_id_prd_pubb           CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
                                    p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_cod_man               PC_MANIF.COD_MAN%TYPE,
                                    p_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
                                    p_categoria_prod        CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%type)
                                    RETURN C_ELENCO_PRODOTTO_VEND;
-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PRODOTTO_VENDITA (p_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
                                    p_id_prd_pubb           CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
                                    p_id_mis_temp           CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                    p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_cod_man               PC_MANIF.COD_MAN%TYPE,
                                    p_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
                                    p_categoria_prod        CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%type,
                                    p_flg_annullato         CD_PRODOTTO_VENDITA.FLG_ANNULLATO%TYPE,
                                    p_id_target             CD_PRODOTTO_VENDITA.ID_TARGET%TYPE)
                                    RETURN C_LISTA_PRD_VND;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_DETTAGLIO_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_PRODOTTO_VENDITA (p_id_prodotto_vendita     CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE)
                                        RETURN C_DETTAGLIO_PRODOTTO_VENDITA;


-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_DETTAGLIO_PRODOTTO_VENDITA_LISTINO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETT_PROD_VEND_LISTINO (p_id_listino     CD_LISTINO.DESC_LISTINO%TYPE,
                                    p_cat_prodotto   PC_CATEGORIA_PRODOTTO.COD%TYPE)
                                    RETURN C_DETTAGLIO_PRODOTTO_VENDITA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_MODALITA_VENDITA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_MODALITA_VENDITA (p_desc_mod_vendita      CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE)
                                    RETURN C_MODALITA_VENDITA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_UNITA_MIS_TEMP
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_UNITA_MIS_TEMP (p_desc_unita      CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
                                  p_id_prod_pubb    CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE)
                                  RETURN C_UNITA_MIS_TEMP;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_PRODOTTO_VENDITA_VENDUTO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PRODOTTO_VENDITA_VENDUTO(p_id_prodotto_vendita      CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE
                                    ) RETURN INTEGER;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_PRODOTTO_VENDITA(p_id_prodotto_vendita	    IN CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
						              p_esito		            OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_PRODOTTO_VENDITA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_PRODOTTO_VENDITA(p_id_prodotto_vendita	IN CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
						               p_esito		            OUT NUMBER);


-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_MANIF
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_MANIF (p_des_man      PC_MANIF.DES_MAN%TYPE)
                         RETURN C_MANIF;
--
-- FUNCTION FU_MOD_SEC_CERCA_PROD_DATO
-- Questa function determina i dati del prodotto di vendita indicato da visualizzare nella
-- pagina di modifica dei secondi vendibili assegnati
-- Spezia, ottobre 2009
--
FUNCTION FU_MOD_SEC_CERCA_PROD_DATO (p_id_listino            cd_circuito_break.ID_LISTINO%TYPE,
                                   p_id_prodotto_vendita     cd_prodotto_vendita.ID_PRODOTTO_VENDITA%TYPE,
                                   p_anno_inizio             periodi.ANNO%TYPE,
                                   p_ciclo_inizio            periodi.CICLO%TYPE,
                                   p_periodo_inizio          periodi.PER%TYPE,
                                   p_anno_fine               periodi.ANNO%TYPE,
                                   p_ciclo_fine              periodi.CICLO%TYPE,
                                   p_periodo_fine            periodi.PER%TYPE
)
                                                RETURN C_MOD_SEC_ASSE_PROD_SCELTO;
--
-- FUNCTION FU_MOD_SEC_CERCA_PROD_COMPL
-- Questa function determina i dati dei prodotti di vendita diversi da quello indicato ma che insistono
-- sui medesimi break di vendita, dati da visualizzare nella pagina di modifica dei secondi vendibili assegnati
-- Spezia, ottobre 2009
--
FUNCTION FU_MOD_SEC_CERCA_PROD_COMPL (p_id_listino            cd_circuito_break.ID_LISTINO%TYPE,
                                   p_id_prodotto_vendita     cd_prodotto_vendita.ID_PRODOTTO_VENDITA%TYPE,
                                   p_anno_inizio             periodi.ANNO%TYPE,
                                   p_ciclo_inizio            periodi.CICLO%TYPE,
                                   p_periodo_inizio          periodi.PER%TYPE,
                                   p_anno_fine               periodi.ANNO%TYPE,
                                   p_ciclo_fine              periodi.CICLO%TYPE,
                                   p_periodo_fine            periodi.PER%TYPE
                                   )
                                                RETURN C_MOD_SEC_ASSE_PROD_COMPL;
--
-- PROCEDURE PR_MODIFICA_SECONDI
-- Questa procedura modifica i secondi vendibili assegnati per tutti i break_vendita che hanno
-- il listino e il prodotto di vendita indicati
-- Spezia, settembre 2009
--
PROCEDURE PR_MODIFICA_SECONDI(    p_id_listino             cd_circuito_break.ID_LISTINO%TYPE,
                                   p_id_prodotto_vendita     cd_break_vendita.ID_PRODOTTO_VENDITA%TYPE,
                                   p_secondi_vendibili       cd_break_vendita.SECONDI_ASSEGNATI%TYPE,
                                   p_anno_inizio             periodi.ANNO%TYPE,
                                   p_ciclo_inizio            periodi.CICLO%TYPE,
                                   p_periodo_inizio          periodi.PER%TYPE,
                                   p_anno_fine               periodi.ANNO%TYPE,
                                   p_ciclo_fine              periodi.CICLO%TYPE,
                                   p_periodo_fine            periodi.PER%TYPE,
                                   p_esito                   OUT NUMBER);

--
-- PROCEDURE FU_DATA_PERIODO
--
FUNCTION FU_DATA_PERIODO (p_anno             periodi.ANNO%TYPE,
                          p_ciclo            periodi.CICLO%TYPE,
                          p_periodo          periodi.PER%TYPE
                          )
                          RETURN PA_CD_PIANIFICAZIONE.C_SETTIMANA;

--
-- PROCEDURE FU_VERIFICA_ASSEGNATO
--
FUNCTION FU_VERIFICA_ASSEGNATO (p_cinema                  CD_CINEMA.ID_CINEMA%TYPE,
                                 p_sala                    CD_SALA.ID_SALA%TYPE,
                                 p_anno_inizio             periodi.ANNO%TYPE,
                                 p_ciclo_inizio            periodi.CICLO%TYPE,
                                 p_periodo_inizio          periodi.PER%TYPE,
                                 p_anno_fine               periodi.ANNO%TYPE,
                                 p_ciclo_fine              periodi.CICLO%TYPE,
                                 p_periodo_fine            periodi.PER%TYPE
                                 )
                                 RETURN C_VER_ASSEGNATO;

--
-- PROCEDURE FU_DETTAGLIO_ASSEGNATO
--
FUNCTION FU_DETTAGLIO_ASSEGNATO (p_sala                    CD_SALA.ID_SALA%TYPE,
                                 p_anno                    periodi.ANNO%TYPE,
                                 p_ciclo                   periodi.CICLO%TYPE,
                                 p_periodo                 periodi.PER%TYPE
                                 )
                                 RETURN C_DETT_ASSEGNATO;


FUNCTION FU_GET_COD_TIPO_PUBB(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN C_COD_TIPO_PUBB;

END PA_CD_PRODOTTO_VENDITA; 
/

