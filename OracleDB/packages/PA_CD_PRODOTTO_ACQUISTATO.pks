CREATE OR REPLACE PACKAGE VENCD.PA_CD_PRODOTTO_ACQUISTATO IS

v_stampa_prodotto_acquistato             VARCHAR2(3):='ON';

TYPE R_PRODOTTO_PUBB IS RECORD
(
     ID_PRODOTTO_PUBB CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
     DESC_PRODOTTO    CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE
);

TYPE R_CIRCUITO IS RECORD
(
     ID_CIRCUITO   CD_CIRCUITO.ID_CIRCUITO%TYPE,
     NOME_CIRCUITO CD_CIRCUITO.NOME_CIRCUITO%TYPE
);

TYPE R_MODALITA_VEND IS RECORD
(
     ID_MOD_VENDITA   CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
     DESC_MOD_VENDITA CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE
);

TYPE R_ASSSOGG IS RECORD
(
       DESCRIZIONE CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
       NOME_CIRCUITO CD_CIRCUITO.NOME_CIRCUITO%TYPE,
       NETTO CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE,
       LORDO CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
       PERC_SC CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
       FORMATO VARCHAR2(16),
       ID_PRDOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
       NUM_COMUNICATI NUMBER,
       NUM_SALE NUMBER,
       NUM_CINEMA NUMBER,
       NUM_ATRII NUMBER
);

TYPE R_SCHERMI IS RECORD
(
    p_id_comunicato                VARCHAR(100),
    p_id_cinema                    CD_CINEMA.ID_CINEMA%TYPE,
    p_nome_cinema                  CD_CINEMA.NOME_CINEMA%TYPE,
    p_comune_cinema                CD_COMUNE.COMUNE%TYPE,
    p_provincia_cinema             CD_PROVINCIA.PROVINCIA%TYPE,
    p_regione_cinema               CD_REGIONE.NOME_REGIONE%TYPE,
    p_nome_ambiente                VARCHAR2(40),
  --  p_data_erogazione_prev         CD_COMUNICATO.data_erogazione_prev%TYPE,
    p_tipo_luogo                   VARCHAR2(2),
    p_flg_annullato                CD_COMUNICATO.flg_annullato%TYPE
) ;

TYPE R_PROVINCIA IS RECORD
(
    p_id_provincia                 CD_PROVINCIA.ID_PROVINCIA%TYPE,
    p_nome_provincia               CD_PROVINCIA.PROVINCIA%TYPE
) ;

TYPE C_ASSSOGG       IS REF CURSOR RETURN R_ASSSOGG;
TYPE C_CIRCUITO      IS REF CURSOR RETURN R_CIRCUITO;
TYPE C_PRODOTTO_PUBB IS REF CURSOR RETURN R_PRODOTTO_PUBB;
TYPE C_MODALITA_VEND IS REF CURSOR RETURN R_MODALITA_VEND;
TYPE C_LISTA_SCHERMI IS REF CURSOR RETURN R_SCHERMI;
TYPE C_PROVINCIA     IS REF CURSOR RETURN R_PROVINCIA;

TYPE R_COMUNE IS RECORD
(
    a_id_comune                  CD_COMUNE.ID_COMUNE%TYPE,
    a_comune                     CD_COMUNE.COMUNE%TYPE
);
TYPE C_COMUNE IS REF CURSOR RETURN R_COMUNE;

TYPE R_AREA_NIELSEN IS RECORD
(
    a_id_area_nielsen CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
    a_desc_area_nielsen CD_AREA_NIELSEN.DESC_AREA%TYPE--,
   -- a_num_schermi NUMBER,
   --a_regioni VARCHAR2(255)
);

TYPE C_AREA_NIELSEN IS REF CURSOR RETURN R_AREA_NIELSEN;

TYPE R_PROD_AFFOLL IS RECORD
(
     a_id_prodotto_acquistato   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
     a_id_formato   CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
     a_id_tipo_break   CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE
);

TYPE C_PROD_AFFOLL IS REF CURSOR RETURN R_PROD_AFFOLL;
--Record che contiene le informazioni sui prodotti acquistati
TYPE R_INFO_PROD_ACQ IS RECORD
(
    a_imprec             NUMBER,
    a_flg_annullato        VARCHAR2(1), 
    a_flg_sospeso        VARCHAR2(1),
    a_stato                VARCHAR2(3),
    a_implordsal        NUMBER,
    a_coddis            VARCHAR2(1),
    a_codatt            VARCHAR2(1),
    a_data_fine            DATE,
    a_darecupero        VARCHAR2(1),
    a_saltato            VARCHAR2(1),
    a_recuperato        VARCHAR2(1),
    a_comsaltati        VARCHAR2(1),
    a_validi            NUMBER,
    a_nonvalidi            NUMBER,
    a_saltati            NUMBER,
    a_totale            NUMBER
);
--cursore del tipo di record sopra definito
TYPE C_INFO_PROD_ACQ IS REF CURSOR RETURN R_INFO_PROD_ACQ;

TYPE R_LUOGO IS RECORD
(
    a_id_luogo      CD_LUOGO.ID_LUOGO%TYPE,
    a_desc_luogo    CD_LUOGO.DESC_LUOGO%TYPE
);
TYPE C_LUOGO IS REF CURSOR RETURN R_LUOGO;


TYPE R_ID_PRODOTTO_ACQUISTATO IS RECORD
(
    A_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE
);    

TYPE C_ID_PRODOTTO_ACQUISTATO IS REF CURSOR RETURN R_ID_PRODOTTO_ACQUISTATO;


FUNCTION FU_CERCA_CIRCUITO      RETURN C_CIRCUITO;
FUNCTION FU_CERCA_PRODOTTO_PUBB RETURN C_PRODOTTO_PUBB;
FUNCTION FU_CERCA_MODALITA_VEND RETURN C_MODALITA_VEND;


-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              prodotti acquistati
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_PRODOTTO_ACQUIST           Inserimento di un prodotto acquistato nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_PRODOTTO_ACQUIST            Eliminazione di un prodotto acquistato dal sistema
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:  Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------

--
--TYPE id_ambito_type  IS TABLE OF INTEGER INDEX BY BINARY_INTEGER;

--TYPE ID_AMBITO_TYPE  IS TABLE OF  NUMBER;
--
FUNCTION FU_CERCA_ASSSOGG(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                          P_ID_SOGGETTO  CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                          P_ID_CIRCUITO  CD_CIRCUITO.ID_CIRCUITO%TYPE,
                          P_ID_PRODOTTO_PUBLLICITARIO CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
                          P_ID_MODALITA_VENDITA CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
                          P_DATA_INIZIO  DATE,
                          P_DATA_FINE    DATE) RETURN C_ASSSOGG;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_PRODOTTO_ACQUIST
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_PRODOTTO_ACQUIST  (    p_id_prodotto_acquistato        IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                            p_esito                            OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_PRODOTTO_ACQUIST
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_PRODOTTO_ACQUIST  (p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_chiamante              VARCHAR2,
                                        p_esito                     IN OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_PRODOTTO_ACQUIST
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_PRODOTTO_ACQUIST  (p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_chiamante              VARCHAR2,
                                         p_esito                  OUT NUMBER);

PROCEDURE PR_SOSPENDI_PRODOTTO_ACQUIST  (p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_esito                     IN OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CREA_PROD_ACQ_MODULO
-- Crea un nuovo prodotto acquistato, e i relativi comunicati, per un prodotto vendita in modulo
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_ACQ_MODULO (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_spettacolo         CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE,
    p_numero_massimo_schermi NUMBER,
    p_numero_ambienti        NUMBER,
    p_id_prod_acquistato    OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    p_esito                    OUT NUMBER);
    
    
    
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CREA_PROD_ACQ_MODULO
-- Crea un nuovo prodotto acquistato, e i relativi comunicati, per un prodotto vendita in modulo
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_MODULO_SEGUI_FILM (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_spettacolo         CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE,
    p_numero_massimo_schermi NUMBER,
    p_numero_ambienti        NUMBER,
    p_id_tariffa            cd_tariffa.id_tariffa%type,
    p_id_prod_acquistato    OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    p_esito                    OUT NUMBER);    

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CREA_PROD_ACQ_LIBERA
-- Crea un nuovo prodotto acquistato, e i relativi comunicati, per un prodotto vendita in libera
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_ACQ_LIBERA (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_prodotto_acquistato OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    p_esito                  OUT NUMBER);

PROCEDURE PR_CREA_PRODOTTO_MULTIPLO (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_perc_sconto           NUMBER,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_id_circuito           CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
    p_id_spettacolo         cd_prodotto_acquistato.ID_SPETTACOLO%type,
    p_numero_massimo_schermi NUMBER,
    p_esito                    OUT NUMBER);

TYPE R_PROD_ACQ IS RECORD
(
    a_id_prod_acq          CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_tariffa              CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    a_id_lordo             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    a_id_netto             CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE,
    a_id_sconto            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_perc_sconto          CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_id_piano             CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    a_id_ver_piano         CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    a_nome_cliente         INTERL_U.RAG_SOC_COGN%TYPE,
    a_num_schermi          NUMBER,
    a_num_comunicati       NUMBER,
    a_stato_vendita        CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
    a_desc_formato         VARCHAR2(10),
    a_desc_soggetto        CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
    a_area_vendita         AREE.DES_ABBR%TYPE,
    a_imp_lordo_saltato    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE
);

TYPE C_PROD_ACQ IS REF CURSOR RETURN R_PROD_ACQ;

TYPE R_PROD_SALTO_RECUPERO IS RECORD
(
    a_salto_recupero       VARCHAR2(1),
    a_id_prod_acq          CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_tariffa              CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    a_id_lordo             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    a_id_netto             CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE,
    a_id_sconto            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_perc_sconto          CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_id_piano             CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    a_id_ver_piano         CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    a_nome_cliente         INTERL_U.RAG_SOC_COGN%TYPE,
    a_num_schermi          NUMBER,
    a_num_comunicati       NUMBER,
    a_stato_vendita        CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
    a_desc_formato         VARCHAR2(10),
    a_desc_soggetto        CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
    a_area_vendita         AREE.DES_ABBR%TYPE,
    a_imp_lordo_saltato    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE,
    a_imp_recupero         CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE,
    a_nome_circuito        CD_CIRCUITO.NOME_CIRCUITO%TYPE, 
    a_desc_tipo_break      CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE, 
    a_desc_mod_vendita     CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE
);
TYPE C_PROD_SALTO_RECUPERO IS REF CURSOR RETURN R_PROD_SALTO_RECUPERO;

TYPE R_PROD_ACQ_PIANO IS RECORD
(
    a_id_prod_acq          CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_id_prod_vendita      CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    a_nome_prodotto_pubb   CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_circuito          CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito        CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_mod_vendita       CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita     CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
    a_id_tipo_break        CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
    a_desc_tipo_break      CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_desc_man             PC_MANIF.DES_MAN%TYPE,
    a_tariffa              CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    a_lordo                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    a_netto                CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE,
    a_netto_comm           CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    a_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_netto_dir            CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    a_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_maggiorazione        CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    a_recupero             CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE,
    a_sanatoria            CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE,
    a_id_tipo_tariffa      CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
    a_lordo_comm           CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    a_lordo_dir            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    a_perc_sconto_comm     CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_perc_sconto_dir      CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_id_raggruppamento    CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
    a_id_fruitore          CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE,
    a_stato_di_vendita     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
    a_cod_soggetto         CD_SOGGETTO_DI_PIANO.COD_SOGG%TYPE,
    a_desc_soggetto        CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
    a_titolo_mat           CD_MATERIALE.TITOLO%TYPE,
    a_num_schermi          NUMBER,
    a_num_sale             NUMBER,
    a_num_atrii            NUMBER,
    a_num_cinema           NUMBER,
    a_num_comunicati       NUMBER,
    a_id_formato           CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
    a_desc_formato         VARCHAR2(40),
    a_durata               CD_COEFF_CINEMA.DURATA%TYPE,
    a_cod_pos_rigore       CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    a_desc_pos_rigore      CD_POSIZIONE_RIGORE.DESCRIZIONE%TYPE,
    a_tariffa_variabile    CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    a_data_inizio          CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    a_data_fine            CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    a_settimana_sipra      VARCHAR2(30),
    a_id_tipo_cinema       CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    a_data_modifica        CD_PRODOTTO_ACQUISTATO.DATAMOD%TYPE
);

TYPE C_PROD_ACQ_PIANO IS REF CURSOR RETURN R_PROD_ACQ_PIANO;

TYPE R_PROD_ACQ_SOGG IS RECORD
(
    a_id_prod_acq          CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_nome_prodotto_pubb   CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_circuito          CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito        CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_desc_mod_vendita     CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
    a_id_tipo_break        CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
    a_desc_tipo_break      CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_desc_man             PC_MANIF.DES_MAN%TYPE,
    a_tariffa              CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    a_lordo                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    a_netto                CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE,
    a_sconto               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
  --  a_netto_dir            CD_PRODOTTO_ACQUISTATO.IMP_NETTO_DIR%TYPE,
    a_maggiorazione        CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    a_recupero             CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE,
    a_sanatoria            CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE,
    a_perc_sconto          CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_id_raggruppamento    CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
    a_desc_soggetto        CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
    a_num_schermi          NUMBER,
    a_num_sale             NUMBER,
    a_num_atrii            NUMBER,
    a_num_cinema           NUMBER,
    a_num_comunicati       NUMBER,
    a_id_formato           CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
    a_desc_formato         VARCHAR2(10)

);

TYPE C_PROD_ACQ_SOGG IS REF CURSOR RETURN R_PROD_ACQ_SOGG;

TYPE R_TOT_PROD_ACQ_PIANO IS RECORD
(
    a_num_prodotti         NUMBER,
    a_sum_tariffa          NUMBER,
    a_sum_lordo            NUMBER,
    a_sum_netto            NUMBER,
    a_sum_sconto           NUMBER,
    a_sum_netto_dir        NUMBER,
    a_sum_maggiorazione    NUMBER,
    a_sum_recupero         NUMBER,
    a_sum_sanatoria        NUMBER,
    a_avg_sconto           NUMBER,
    a_sum_netto_com        NUMBER,
    a_sum_netto_com_dir    NUMBER,
    a_sum_perc_sc_com      NUMBER,
    a_sum_perc_sc_dir      NUMBER
);
TYPE C_TOT_PROD_ACQ_PIANO IS REF CURSOR RETURN R_TOT_PROD_ACQ_PIANO;


TYPE R_STATO_VENDITA IS RECORD
(
    a_id_stato_vendita        CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE,
    a_desc_mod_vendita        CD_STATO_DI_VENDITA.DESCRIZIONE%TYPE,
    a_desc_breve_mod_vendita  CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE,
    a_stati_successivi        CD_STATO_DI_VENDITA.STATI_SUCCESSIVI%TYPE
);

TYPE C_STATO_VENDITA IS REF CURSOR RETURN R_STATO_VENDITA;

TYPE R_SCHERMI_PA IS RECORD
(
    a_id_schermo      CD_SCHERMO.ID_SCHERMO%TYPE,
    a_tipo_cinema     CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_comune     CD_COMUNE.COMUNE%TYPE,
    a_nome_provincia  CD_PROVINCIA.ABBR%TYPE,
    a_nome_regione    CD_REGIONE.NOME_REGIONE%TYPE,
    a_nome_schermo    CD_SCHERMO.DESC_SCHERMO%TYPE,
    a_passaggi        NUMBER
);

TYPE C_SCHERMI_PA IS REF CURSOR RETURN R_SCHERMI_PA;

TYPE R_AMBIENTI_PA IS RECORD
(
    a_id_ambiente        NUMBER,
    a_desc_ambiente      VARCHAR2(40),
    a_nome_cinema        CD_CINEMA.NOME_CINEMA%TYPE
);

TYPE C_AMBIENTI_PA IS REF CURSOR RETURN R_AMBIENTI_PA;

TYPE R_PRODOTTO_SALTATO IS RECORD
(
    a_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_id_piano                  CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    a_id_ver_piano              CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    a_id_circuito               CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito             CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_formato                CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    a_durata                    CD_COEFF_CINEMA.DURATA%TYPE,
    a_id_misura                 CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE%TYPE,
    a_id_unita_temp             CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE,
    a_id_cliente                CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
    a_desc_cliente              INTERL_U.RAG_SOC_COGN%TYPE,
    a_id_tipo_break             CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
    a_desc_tipo_break           CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_id_tipo_cinema            CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    a_posizione_rigore          CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
    --a_id_soggetto             CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
    --a_desc_soggetto           CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
    --a_id_materiale            CD_MATERIALE.ID_MATERIALE%TYPE,
    --a_titolo_materiale        CD_MATERIALE.TITOLO%TYPE,
    a_num_sale_saltate          NUMBER,
    a_num_sale_recuperate       NUMBER,
    --a_maggiorazioni             VARCHAR2(255),
    a_netto_comm                NUMBER,
    a_netto_dir                 NUMBER,
    a_perc_sconto_comm          NUMBER,
    a_perc_sconto_dir           NUMBER
    --a_circuiti_recupero         VARCHAR2(255)
);

TYPE C_PRODOTTO_SALTATO IS REF CURSOR RETURN R_PRODOTTO_SALTATO;

TYPE R_PRODOTTO_SPECIALE IS RECORD
(
    a_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_cliente                   interl_u.RAG_SOC_COGN%TYPE,
    a_id_piano                  CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    a_id_ver_piano              CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    a_data_inizio               CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    a_data_fine                 CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    a_nome_target_spettacolo    varchar2(1000),
    a_durata                    CD_COEFF_CINEMA.DURATA%TYPE,
    a_num_sale_previste         NUMBER,
    a_num_sale_ottenute         NUMBER,
    a_recuperato                CHAR,
    a_id_target                 cd_prodotto_vendita.ID_TARGET%type
);


TYPE C_PRODOTTO_SPECIALE IS REF CURSOR RETURN R_PRODOTTO_SPECIALE;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_PROD_ACQUISTATI
-- recupera i prodotti acquistati inclusi nella data selezionata
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_PROD_ACQUISTATI(
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine   CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE) RETURN C_PROD_ACQ;


-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_PROD_SALTO_RECUPERO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROD_SALTO_RECUPERO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) 
RETURN C_PROD_SALTO_RECUPERO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RICALCOLA_RECUPERO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_RECUPERO (p_id_prodotto_acquistato   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_nuovo_recupero           CD_TARIFFA.IMPORTO%TYPE,
                                 p_esito                    OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_EFFETTUA_RECUPERO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_EFFETTUA_RECUPERO (p_id_prodotto_recupero IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_saltato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_esito                  OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_EFFETTUA_RECUPERO2
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_EFFETTUA_RECUPERO2 (p_id_prodotto_recupero IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_saltato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_tipo_contratto       IN CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO%TYPE,
                                p_esito                  OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_PRESENTE_IN_TAB_RECUPERO
-- --------------------------------------------------------------------------------------------                                
FUNCTION FU_PRESENTE_IN_TAB_RECUPERO(p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE)
                                     RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_INFO_PROD_ACQ
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_INFO_PROD_ACQ (p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE)
                          RETURN C_INFO_PROD_ACQ;                                     
FUNCTION FU_GET_PROD_ACQUISTATI_PIANO(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                      p_flg_annullato CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO%TYPE,
                                      p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_PROD_ACQ_PIANO;

FUNCTION FU_GET_PROD_ACQ_PIANO_SOSPESO(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_PROD_ACQ_PIANO;

FUNCTION FU_GET_PROD_ACQUISTATI_SOGG(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_PROD_ACQ_SOGG;

FUNCTION GET_COD_SOGGETTO(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2;

FUNCTION GET_DESC_SOGGETTO(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE;


FUNCTION GET_TITOLO_MATERIALE(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN CD_MATERIALE.TITOLO%TYPE;

FUNCTION FU_GET_TOTALI_PROD_ACQ(
                                  p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                  p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN C_TOT_PROD_ACQ_PIANO;


FUNCTION FU_GET_FORMATO_PROD_ACQ(
                        p_id_prod_acq CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2;


PROCEDURE PR_SALVA_MAGGIORAZIONE(
                                p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_maggiorazione       CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE%TYPE);

PROCEDURE PR_RIMUOVI_MAGGIORAZIONE(
                                p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_maggiorazione       CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE%TYPE,
                                p_imp_maggiorazione      OUT NUMBER);

PROCEDURE MODIFICA_PRODOTTO_ACQUISTATO(
                    p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                    p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                    p_imp_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
                    p_imp_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
                    p_imp_sanatoria CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE,
                    p_imp_recupero CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE,
                    p_imp_maggiorazione CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
                    p_netto_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_netto_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                    p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                    p_id_tariffa_variabile CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
                    p_lordo_saltato CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE,
                    p_list_maggiorazioni    id_list_type);

PROCEDURE PR_ASSOCIA_INTERMEDIARI(
                    p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                    p_id_raggruppamento CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
                    p_esito OUT NUMBER);

PROCEDURE PR_ASSOCIA_FRUITORE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                              p_id_fruitore_di_piano CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE,
                              p_esito OUT NUMBER);

PROCEDURE PR_ASSOCIA_SOGGETTO_PRODOTTO(
                    p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                    p_id_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                    p_esito    OUT NUMBER);

PROCEDURE PR_ASSOCIA_SOGGETTO_COMUNICATO(
                    p_id_comunicato           CD_COMUNICATO.ID_COMUNICATO%TYPE,
                    p_id_soggetto             CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                    p_esito                      OUT NUMBER);

PROCEDURE PR_ASSOCIAZIONE_PERC_SOGGETTI(p_id_piano  CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                            p_id_ver_piano  CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                            p_lista_id_soggetti     id_list_type,
                            p_lista_percentuali     id_list_type,
                            p_id_sogg_non_def       NUMBER,
                            p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                            p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                            p_esito                 OUT NUMBER);

PROCEDURE PR_ASSOCIA_MATERIALE_PRODOTTO(p_id_prodotto_acquistato         CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_id_materiale_piano             CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE,
                                        p_esito                          OUT NUMBER);

PROCEDURE PR_ASSOCIA_MATERIALE_COM(p_id_comunicato            CD_COMUNICATO.ID_COMUNICATO%TYPE,
                                   p_id_materiale_piano       CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE,
                                   p_esito                    OUT NUMBER);
                                   
PROCEDURE PR_ASSOCIAZIONE_PERC_MATERIALI(p_id_piano  CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                            p_id_ver_piano  CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                            p_lista_id_soggetti     id_list_type,
                            p_lista_id_materiali    id_list_type,
                            p_lista_percentuali     id_list_type,
                            p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                            p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                            p_esito                 OUT NUMBER);
                                   
FUNCTION FU_CHECK_DURATA_PROD_MAT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                  p_id_materiale_di_piano CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE) RETURN NUMBER;

FUNCTION FU_VER_MESSA_IN_ONDA_PIANO(p_id_piano cd_prodotto_acquistato.id_piano%type,
                                    p_id_ver_piano cd_prodotto_acquistato.id_ver_piano%type) RETURN char;

FUNCTION FU_VER_DOPO_ONDA_PIANO(p_id_piano cd_prodotto_acquistato.id_piano%type,
                                    p_id_ver_piano cd_prodotto_acquistato.id_ver_piano%type) RETURN char;                                    

/*******************************************************************************
 VERIFICA MESSA IN ONDA
 Author:  Michele Borgogno , Altran, Ottobre 2009

 Per mezzo di questa funzione si puo verificare la messa in onda di un
 particolare prodotto acquistato
*******************************************************************************/
FUNCTION  FU_VERIFICA_MESSA_IN_ONDA(p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%type) RETURN char;

FUNCTION  FU_VERIFICA_DOPO_MESSA_IN_ONDA(p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%type) RETURN char;

FUNCTION  FU_VERIFICA_FATTURAZIONE(p_id_prodotto_acquistato IN cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN char;

FUNCTION  FU_VER_INCLUSIONE_IN_ORDINE(p_id_prodotto_acquistato IN cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN char;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_RIPARAMETRA_PROD_ACQ
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_RIPARAMETRA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE) RETURN NUMBER;
FUNCTION FU_GET_RICALCOLA_IMP_SALT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE) RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_STATI_VENDITA_PR_ACQ
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_STATI_VENDITA_PR_ACQ(
                                    p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                    p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                    p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_STATO_VENDITA;

FUNCTION FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_NUM_AMBIENTI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_NUM_COMUNICATI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_RICALCOLA_TARIFFA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA( p_id_tariffa        CD_TARIFFA.ID_TARIFFA%TYPE,
                                p_vecchio_importo   CD_TARIFFA.IMPORTO%TYPE,
                                p_nuovo_importo     CD_TARIFFA.IMPORTO%TYPE,
                                p_piani_errati OUT VARCHAR2);

PROCEDURE PR_RICALCOLA_TARIFFA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_vecchio_importo   CD_TARIFFA.IMPORTO%TYPE,
                                p_nuovo_importo     CD_TARIFFA.IMPORTO%TYPE,
                                p_flg_variazione_ambienti VARCHAR2,
                                p_piani_errati OUT VARCHAR2);

PROCEDURE PR_ANNULLA_SCHERMO_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                      p_id_schermo CD_SCHERMO.ID_SCHERMO%TYPE,
                                      p_esito OUT NUMBER,
                                      p_piani_errati OUT VARCHAR2);

PROCEDURE PR_RIPRISTINA_SCHERMO_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                      p_id_schermo CD_SCHERMO.ID_SCHERMO%TYPE,
                                      p_esito OUT NUMBER,
                                      p_piani_errati OUT VARCHAR2);
FUNCTION FU_GET_SOGG_PROD_ACQ(
                              p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                              p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN VARCHAR2;

PROCEDURE PR_IMPOSTA_POSIZIONE(
                                p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE);

FUNCTION  FU_ELENCO_SCHERMI(p_id_prodotto_acquistato IN CD_COMUNICATO.id_prodotto_acquistato%TYPE,
                            p_id_regione IN CD_REGIONE.ID_REGIONE%TYPE,
                            p_id_provincia IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
                            p_id_comune IN CD_COMUNE.ID_COMUNE%TYPE,
                            p_id_cinema IN CD_CINEMA.id_cinema%TYPE,
                            p_id_sala IN CD_SALA.ID_SALA%TYPE)
                            RETURN C_LISTA_SCHERMI;

FUNCTION FU_VERIFICA_POS_RIGORE(
                                p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_vendita  CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                p_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                p_list_ambienti id_list_type) RETURN NUMBER;

FUNCTION FU_RICERCA_PROVINCE(p_id_regione  CD_REGIONE.ID_REGIONE%TYPE) RETURN C_PROVINCIA;

FUNCTION FU_RICERCA_COMUNI(p_id_provincia CD_PROVINCIA.ID_PROVINCIA%TYPE)RETURN C_COMUNE;

FUNCTION FU_GET_SCHERMI_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_SCHERMI_PA;
FUNCTION FU_GET_ATRII_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AMBIENTI_PA;
FUNCTION FU_GET_SALE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AMBIENTI_PA;
FUNCTION FU_GET_CINEMA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AMBIENTI_PA;
FUNCTION FU_GET_AREE_NIELSEN_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AREA_NIELSEN;
FUNCTION FU_COUNT_PROD_ACQ_PERIODO(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                 p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                 p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN NUMBER;
  --                               p_tipo_periodo VARCHAR2) RETURN NUMBER;

PROCEDURE PR_RICALCOLA_IMP_FAT(p_id_importo_prodotto CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_PRODOTTO%TYPE,
                               p_vecchio_netto CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE,
                               p_nuovo_netto CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE);

PROCEDURE PR_MODIFICA_RAGGRUPPAMENTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                      p_id_raggruppamento CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE);

PROCEDURE PR_MODIFICA_FRUITORE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                               p_id_fruitore CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE);

FUNCTION FU_GET_NUM_IMPORTI_FAT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER;

PROCEDURE PR_MODIFICA_AMBIENTI_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                              p_list_id_ambito        id_list_type);

PROCEDURE PR_MODIFICA_AREE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_list_id_area        id_list_type);

FUNCTION FU_GET_DETT_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_PROD_ACQ_PIANO;

PROCEDURE PR_MODIFICA_IMPORTI_PRODOTTO(p_id_importi_prodotto CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE, p_netto_nuovo CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE, p_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE);
FUNCTION FU_GET_PROD_ACQ_AFFOLL(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN C_PROD_AFFOLL;

PROCEDURE PR_MODIFICA_STATO_VENDITA(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE);

PROCEDURE PR_SALVA_POS_RIGORE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                              p_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                              p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE);
                              
PROCEDURE PR_ELIMINA_BUCO_POSIZIONE_PACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE);
                                    
PROCEDURE PR_ELIMINA_BUCO_POSIZIONE_COM(p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE);                                    

FUNCTION FU_GET_PRESENZA_TOP_SPOT(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE) RETURN NUMBER;                                                          

FUNCTION FU_GET_LUOGO_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN CD_LUOGO.ID_LUOGO%TYPE;

PROCEDURE PR_MODIFICA_SCHERMI_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2);

PROCEDURE PR_MODIFICA_ATRII_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2);

PROCEDURE PR_MODIFICA_SALE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2);
                                       
PROCEDURE PR_MODIFICA_CINEMA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2);

FUNCTION FU_GET_NOME_CINEMA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2;

PROCEDURE PR_MODIFICA_IMPORTI_MASSIVA(p_list_prodotti id_list_type, 
                                      p_lordo_comm_tot CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE, 
                                      p_lordo_dir_tot CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE, 
                                      p_netto_comm_tot NUMBER, 
                                      p_netto_dir_tot NUMBER, 
                                      p_esito OUT NUMBER);

FUNCTION FU_GET_PROD_SALE_SALTATE(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE, 
                                  p_id_circuito_saltato CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_circuito_recupero CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN C_PRODOTTO_SALTATO;

FUNCTION FU_GET_PROD_SALE_RECUPERATE(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE, 
                                  p_id_circuito_saltato CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_circuito_recupero CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN C_PRODOTTO_SALTATO;

FUNCTION FU_MAGGIORAZIONI_PRODOTTO(p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2;

FUNCTION FU_CIRCUITI_RECUPERO(p_id_circuito CD_CIRCUITO_RECUPERO.ID_CIRCUITO_SALTATO%TYPE) RETURN VARCHAR2;

PROCEDURE PR_RECUPERA_SALE(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, 
                           p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                           p_id_circuito_saltato CD_CIRCUITO.ID_CIRCUITO%TYPE,
                           p_id_circuito_recupero CD_CIRCUITO.ID_CIRCUITO%TYPE,
                           p_tipo_disponibilita_sala varchar2);

PROCEDURE PR_RECUPERA_SALE_PRODOTTO(p_id_prodotto_originale CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                    p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                    p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, 
                                    p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                    p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_tipo_break CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                    p_id_misura_prd_ve CD_PRODOTTO_ACQUISTATO.ID_MISURA_PRD_VE%TYPE,
                                    p_id_tipo_cinema CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
                                    p_posizione_di_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                                    p_netto_comm NUMBER,
                                    p_netto_dir NUMBER,
                                    p_perc_sc_comm NUMBER,
                                    p_perc_sc_dir NUMBER,
                                    p_sale id_list_type,
                                    p_list_maggiorazioni id_list_type,
                                    p_id_prodotto_acquistato OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_esito OUT NUMBER);

PROCEDURE PR_CORREGGI_IMPORTI_RECUPERO(p_id_prodotto_originale CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, 
                                    p_id_prodotto_recupero CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_list_maggiorazioni id_list_type);        
                                                                
PROCEDURE PR_CORREGGI_IMPORTI_RECUPERO2(p_id_prodotto_originale CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, 
                                    p_id_prodotto_recupero CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_list_maggiorazioni id_list_type);

FUNCTION FU_GET_NUM_SCHERMI_TARGET(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE, p_sale_reali VARCHAR2) RETURN NUMBER;

FUNCTION FU_GET_TARIFFA_PRODOTTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER;


FUNCTION FU_VERIFICA_POS_RIGORE_BATCH(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                p_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
                                ) RETURN NUMBER;
                                
PROCEDURE  PR_IMPOSTA_POSIZIONE_ESC (p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE);
                                
PROCEDURE  PR_SINTESI_PROD_ACQ (p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE default null);

PROCEDURE PR_AGGIORNA_SINTESI_PRODOTTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE );


function fu_get_cod_posizione_rig(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_posizione_rigore.COD_POSIZIONE%type;
function fu_get_des_posizione_rig(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_posizione_rigore.descrizione%type;


procedure PR_AGGIORNA_IMP_SALT(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type , p_id_formato cd_formato_acquistabile.id_formato%type);

FUNCTION FU_GET_NUM_SCHERMI_SEGUI_FILM(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_sale_reali VARCHAR2) RETURN NUMBER;


PROCEDURE PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE,p_posizione cd_comunicato.POSIZIONE%type);

procedure pr_espropria_posizione(p_posizione cd_comunicato.posizione%type,
                                 p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, 
                                 p_id_break cd_break.id_break%type);
                                 
function fu_get_nome_spettacolo(p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_spettacolo.NOME_SPETTACOLO%type;


procedure  pr_modifica_spettacolo (p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type, p_id_spettacolo cd_spettacolo.id_spettacolo%type, p_numero_massimo_schermi cd_prodotto_acquistato.numero_massimo_schermi%type);

function fu_get_numero_massimo_schermi(p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_prodotto_acquistato.numero_massimo_schermi%type;

function fu_get_spettacolo_associato(p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type) return char;

procedure pr_recupera_prodotti_speciali(p_data_inizio cd_prodotto_acquistato.data_inizio%type, p_data_fine cd_prodotto_acquistato.data_fine%type);

procedure pr_recupera_prodotto_speciale(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, p_numero_sale number,p_data_inizio cd_prodotto_acquistato.data_inizio%type, p_data_fine cd_prodotto_acquistato.data_fine%type );

function fu_elenco_prodotti_speciali(p_data_inizio cd_prodotto_acquistato.data_inizio%type,p_data_fine cd_prodotto_acquistato.data_fine%type, p_stato_di_vendita cd_prodotto_acquistato.stato_di_vendita%type ) return  c_prodotto_speciale;

function fu_elenco_prod_speciali_rec(p_data_inizio cd_prodotto_acquistato.data_inizio%type,p_data_fine cd_prodotto_acquistato.data_fine%type, p_stato_di_vendita cd_prodotto_acquistato.stato_di_vendita%type ) return  c_prodotto_speciale;

procedure pr_ricalcola_tariffa_prodotto(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE);

function fu_verifica_presenza_target(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return number;


PROCEDURE  PR_ANNULLA_SALA(p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.id_prodotto_acquistato%TYPE,
                                 p_data_inizio cd_prodotto_acquistato.data_inizio%type,
                                 p_data_fine cd_prodotto_acquistato.data_fine%type,
                                 p_id_sala IN cd_sala.id_sala%type,
                                 p_chiamante VARCHAR2,
                                 p_esito IN OUT NUMBER
                                 );  
                                 
procedure pr_ripristina_sala(p_id_sala cd_sala.id_sala%type,
                                               p_data_inizio cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                               p_data_fine cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                               p_id_circuito cd_circuito.id_circuito%type
                                               );      
                                                    
function fu_prodotti_periodi_speciali(p_data_inizio date,p_data_fine date) return c_id_prodotto_acquistato;

function  fu_get_perc_esatta_importo(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                                              p_tipo_contratto cd_importi_prodotto.tipo_contratto%type ) return number;
PROCEDURE PR_CREA_RECUPERO_LIBERA (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_importo_recupero      CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_prodotto_acquistato OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    p_esito                  OUT NUMBER); 

function fu_get_costo_ambiente(p_id_prodotto_acquistato  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) return number;                                                                                                                                                                   

END PA_CD_PRODOTTO_ACQUISTATO; 
/

