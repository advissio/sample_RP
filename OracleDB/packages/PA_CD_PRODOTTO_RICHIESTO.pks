CREATE OR REPLACE PACKAGE VENCD.PA_CD_PRODOTTO_RICHIESTO IS
/******************************************************************************
   NAME:       PA_CD_PRODOTTO_RICHIESTO
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/11/2009             1. Created this package.
******************************************************************************/

TYPE R_PROD_RIC_PIANO IS RECORD
(
    a_id_prod_ric          CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
    a_id_piano             CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    a_id_ver_piano         CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    a_id_prodotto_vendita  CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    a_nome_prodotto_pubb   CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_circuito          CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_id_listino           CD_TARIFFA.ID_LISTINO%TYPE,
    a_data_inizio          CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    a_data_fine            CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    a_nome_circuito        CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_mod_vendita       CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita     CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
    a_desc_tipo_break      CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_desc_man             PC_MANIF.DES_MAN%TYPE,
    a_tariffa              CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
    a_lordo                CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    a_netto                CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE,
    a_netto_comm           CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    a_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_netto_dir            CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    a_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_maggiorazione        CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
    a_lordo_comm           CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    a_lordo_dir            CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    a_perc_sconto_comm     CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_perc_sconto_dir      CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    a_id_formato           CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
    a_desc_formato         VARCHAR2(40),
    a_durata               CD_COEFF_CINEMA.DURATA%TYPE,
    a_id_tipo_tariffa      CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
    a_id_unita_temp        CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE,
    a_tariffa_variabile    CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    a_cod_pos_rigore       CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    a_desc_pos_rigore      CD_POSIZIONE_RIGORE.DESCRIZIONE%TYPE,
    a_min_disp             NUMBER,
    a_max_disp             NUMBER,
    a_flg_acquistato       CD_PRODOTTI_RICHIESTI.FLG_ACQUISTATO%TYPE,
    a_settimana_sipra      VARCHAR2(30),
    a_num_ambienti         NUMBER,
    a_id_tipo_cinema       CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    a_id_spettacolo        cd_prodotti_richiesti.ID_SPETTACOLO%type,
    a_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type
);

TYPE C_PROD_RIC_PIANO IS REF CURSOR RETURN R_PROD_RIC_PIANO;

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

TYPE R_AREA_NIELSEN IS RECORD
(
    a_id_area_nielsen CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
    a_desc_area_nielsen CD_AREA_NIELSEN.DESC_AREA%TYPE,
    a_num_schermi NUMBER,
   a_regioni VARCHAR2(255)
);

TYPE C_AREA_NIELSEN IS REF CURSOR RETURN R_AREA_NIELSEN;

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

TYPE R_TOT_PROD_RIC_PIANO IS RECORD
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
TYPE C_TOT_PROD_RIC_PIANO IS REF CURSOR RETURN R_TOT_PROD_RIC_PIANO;
  -- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CREA_PROD_RICH_MODULO
-- Crea un nuovo prodotto acquistato, e i relativi comunicati, per un prodotto vendita in modulo
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_RICH_MODULO (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    p_sconto                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_id_spettacolo         cd_prodotti_richiesti.ID_SPETTACOLO%type,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_esito                 OUT NUMBER);
  -- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CREA_PROD_RICH_LIBERA
-- Crea un nuovo prodotto acquistato, e i relativi comunicati, per un prodotto vendita in libera
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_RICH_LIBERA (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    p_sconto                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_esito                    OUT NUMBER);
    
PROCEDURE PR_CREA_PROD_RICH_MULTIPLO (
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
    p_id_spettacolo cd_prodotti_richiesti.id_spettacolo%type,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_esito                    OUT NUMBER);    

FUNCTION FU_GET_PROD_RICHIESTI_PIANO(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_tipo_disp VARCHAR2,
                                      p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_PROD_RIC_PIANO;

FUNCTION FU_GET_NUM_PROD_RICH(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                              p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_NUM_PROD_RICH_ACQ(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                              p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_MAGGIORAZIONI_PRODOTTO(
          p_id_prodotto_richiesto CD_MAGG_PRODOTTO.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_MAGGIORAZIONE;


PROCEDURE PR_SALVA_MAGGIORAZIONE(
                                p_id_prodotto_richiesto  CD_MAGG_PRODOTTO.ID_PRODOTTI_RICHIESTI%TYPE,
                                p_id_maggiorazione       CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE%TYPE);

PROCEDURE PR_MODIFICA_PRODOTTO_RICHIESTO(
                    p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                    p_imp_tariffa CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
                    p_imp_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
                    p_imp_maggiorazione CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
                    p_netto_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_netto_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_posizione_rigore CD_PRODOTTI_RICHIESTI.COD_POSIZIONE%TYPE,
                    p_id_formato CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
                    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
                    p_list_maggiorazioni    id_list_type);

PROCEDURE PR_ANNULLA_PRODOTTO_RICHIESTO(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE);
PROCEDURE PR_RIPRISTINA_PRODOTTO_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE);
FUNCTION FU_GET_RIPARAMETRA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE, p_id_formato CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_SCHERMI_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_SCHERMI_PA;
FUNCTION FU_GET_AREE_NIELSEN_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_AREA_NIELSEN;
FUNCTION FU_COUNT_PROD_RIC_PERIODO(p_id_piano CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
                                 p_id_ver_piano CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
                                 p_data_inizio CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
                                 p_data_fine CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE) RETURN NUMBER;
 --                                p_tipo_periodo VARCHAR2) RETURN NUMBER;

FUNCTION FU_GET_NUM_AMBIENTI(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN NUMBER;

PROCEDURE PR_MODIFICA_AMBIENTI_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                        p_list_id_ambito        id_list_type);

PROCEDURE PR_MODIFICA_AREE_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                    p_list_id_area        id_list_type);
                                    
PROCEDURE PR_RICALCOLA_TARIFFA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                        p_vecchio_importo   CD_TARIFFA.IMPORTO%TYPE,
                                        p_nuovo_importo     CD_TARIFFA.IMPORTO%TYPE,
                                        p_flg_variazione_schermi VARCHAR2,
                                        p_piani_errati OUT VARCHAR2);

FUNCTION FU_GET_DETT_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_PROD_RIC_PIANO;

FUNCTION FU_GET_ATRII_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_AMBIENTI_PA;

FUNCTION FU_GET_LUOGO_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN CD_LUOGO.ID_LUOGO%TYPE;

PROCEDURE PR_MODIFICA_SCHERMI_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                       v_string_id_ambito varchar);
PROCEDURE PR_MODIFICA_ATRII_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                     v_string_id_ambito     varchar);

PROCEDURE PR_MODIFICA_SALE_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                     v_string_id_ambito     varchar);

PROCEDURE PR_MODIFICA_CINEMA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                     v_string_id_ambito     varchar);

PROCEDURE PR_ACQUISTA_PROD_RIC (
    p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
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
    p_id_spettacolo         CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_esito                    OUT NUMBER);
    
PROCEDURE PR_ACQUISTO_MASSIVO (
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_esito                 OUT NUMBER);

FUNCTION FU_GET_NOME_CINEMA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN VARCHAR2;        

PROCEDURE PR_MODIFICA_IMPORTI_MASSIVA(p_list_prodotti id_list_type, 
                                      p_lordo_comm_tot CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE, 
                                      p_lordo_dir_tot CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE, 
                                      p_netto_comm_tot NUMBER, 
                                      p_netto_dir_tot NUMBER, 
                                      p_esito OUT NUMBER);
                                      
FUNCTION FU_GET_TOTALI_PROD_RIC(
                                  p_id_piano CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
                                  p_id_ver_piano CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE) RETURN C_TOT_PROD_RIC_PIANO;
                                  
function fu_get_nome_spettacolo(p_id_prodotto_richiesto  cd_prodotti_richiesti.id_prodotti_richiesti%type) return cd_spettacolo.NOME_SPETTACOLO%type;


PROCEDURE PR_CREA_PROD_MODULO_SEGUI_FILM (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    p_sconto                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_id_spettacolo         cd_prodotti_richiesti.ID_SPETTACOLO%type,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_id_tariffa            cd_tariffa.ID_TARIFFA%type,
    p_esito                 OUT NUMBER);
                                                                            
END PA_CD_PRODOTTO_RICHIESTO; 
/

