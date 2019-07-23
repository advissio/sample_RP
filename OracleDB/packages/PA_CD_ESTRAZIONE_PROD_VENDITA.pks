CREATE OR REPLACE PACKAGE VENCD.PA_CD_ESTRAZIONE_PROD_VENDITA AS
/***************************************************************************************
   NAME:       PA_CD_ESTRAZIONE_PROD_VENDITA
   AUTHOR:     Mauro Viel (Altran)
   PURPOSE:   Questo package contiene procedure/funzioni necessarie per l'estrazione
              del prodotto di vendita


   REVISIONS:
   Ver        Date        Author                Description
   ---------  ----------  ---------------       ------------------------------------
   1.0        17/06/2009  Mauro Viel (Altran) Created this package.
****************************************************************************************/
--
 --Contiene le informazioni di una riga della lista dei prodotti acquistabili per categoria tabellare.

TYPE R_DISPONIBILITA IS RECORD
(
    a_disponibilita_minima  number,
    a_disponibilita_massima number
);

TYPE C_DISPONIBILITA IS REF CURSOR RETURN R_DISPONIBILITA;

TYPE R_AFFOLL_CIRCUITO IS RECORD
(
    a_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
    a_nome_circuito CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_tipo_break   CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
    a_desc_tipo_break   CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_disponibilita_minima  number,
    a_disponibilita_massima number
);

TYPE C_AFFOLL_CIRCUITO IS REF CURSOR RETURN R_AFFOLL_CIRCUITO;
--Mauro Viel Altran 10/02/2011 inserito il FLG_SEGUI_IL_FILM
TYPE R_LISTA_VENDITA_TAB IS RECORD
(
    A_ID_CIRCUITO CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
    A_ID_PRODOTTO_VENDITA CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    A_CIRCUITO CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    A_PRODOTTO_PUBBLICITARIO CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    A_TIPOLOGIA_BREAK   CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    A_DURATA_BREAK      CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
    A_ID_LISTINO        CD_TARIFFA.ID_LISTINO%TYPE,
    A_NUMERO_BREAK NUMBER,
    A_NUM_SCHERMI NUMBER,
    a_tariffa_riparametrata CD_TARIFFA.IMPORTO%TYPE,
    a_tariffa_originale CD_TARIFFA.IMPORTO%TYPE,
    a_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE,
    a_id_tipo_tariffa CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
    a_id_unita CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    a_desc_unita CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
    A_SCONTO_STAGIONALE CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
    a_id_tipo_cinema CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
    A_DISPONIBILITA_MINIMA NUMBER,
    A_DISPONIBILITA_MASSIMA NUMBER,
    A_FLG_SEGUI_IL_FILM cd_prodotto_vendita.FLG_SEGUI_IL_FILM%TYPE
    
) ;

--Contiene le informazioni di una riga della lista dei prodotti acquistabili per categoria iniziativa speciale.
TYPE R_LISTA_VENDITA_IS IS RECORD
(
    a_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
    a_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_circuito CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_prodotto_pubblicitario CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_listino CD_LISTINO.ID_LISTINO%TYPE,
    a_numero_comunicati NUMBER,
    a_numero_ambienti NUMBER,
    a_disponibilita  NUMBER,
    a_tariffa CD_TARIFFA.IMPORTO%TYPE,
    a_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE,
    a_sconto_stagionale CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
    a_id_ambito CD_LUOGO.ID_LUOGO%TYPE,
    a_id_unita CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    a_desc_unita CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
    a_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
    a_desc_formato CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
    a_id_tipo_cinema CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
    a_desc_tipo_cinema CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE
) ;

--E' LA LISTA DI VENDITA
TYPE C_LISTA_VENDITA_TAB IS REF CURSOR RETURN R_LISTA_VENDITA_TAB;
TYPE C_LISTA_VENDITA_IS IS REF CURSOR RETURN R_LISTA_VENDITA_IS;



TYPE R_MODALITA_VENDITA IS RECORD
(
    a_id_mod_vendita          CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
    a_desc_mod_vendita        CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE
);

TYPE C_MODALITA_VENDITA IS REF CURSOR RETURN R_MODALITA_VENDITA;

TYPE R_STATO_VENDITA IS RECORD
(
    a_id_stato_vendita        CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE,
    a_desc_mod_vendita        CD_STATO_DI_VENDITA.DESCRIZIONE%TYPE,
    a_desc_breve_mod_vendita  CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE
);

TYPE C_STATO_VENDITA IS REF CURSOR RETURN R_STATO_VENDITA;

TYPE R_STATO_VENDITA_SELECT IS RECORD
(
    a_id_stato_vendita        CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE,
    a_desc_mod_vendita        CD_STATO_DI_VENDITA.DESCRIZIONE%TYPE,
    a_descr_breve             CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE
);

TYPE C_STATO_VENDITA_SELECT IS REF CURSOR RETURN R_STATO_VENDITA_SELECT;

TYPE R_STATO_VENDITA_PROD IS RECORD
(
    a_descr_breve             CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE,
    a_desc_mod_vendita        CD_STATO_DI_VENDITA.DESCRIZIONE%TYPE
);

TYPE C_STATO_VENDITA_PROD IS REF CURSOR RETURN R_STATO_VENDITA_PROD;

TYPE R_LUOGO IS RECORD
(
    a_id_luogo      CD_LUOGO.ID_LUOGO%TYPE,
	a_desc_luogo    CD_LUOGO.DESC_LUOGO%TYPE
);
TYPE C_LUOGO IS REF CURSOR RETURN R_LUOGO;

TYPE R_BREAK IS RECORD
(
    a_nome_circuito   CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_nome_break      CD_BREAK.NOME_BREAK%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_sala       CD_SALA.NOME_SALA%TYPE,
    a_durata          CD_BREAK.SECONDI_NOMINALI%TYPE,
    a_id_break        CD_BREAK.ID_BREAK%TYPE
);
TYPE C_BREAK IS REF CURSOR RETURN R_BREAK;

TYPE R_SALE IS RECORD
(
    a_id_sala         CD_SALA.ID_SALA%TYPE,
    a_nome_sala       CD_SALA.NOME_SALA%TYPE,
    a_nome_circuito   CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE
);

TYPE R_SCHERMI_LIBERA IS RECORD
(
    a_id_schermo      CD_SCHERMO.ID_SCHERMO%TYPE,
    a_tipo_cinema     CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_comune     CD_COMUNE.COMUNE%TYPE,
    a_nome_provincia  CD_PROVINCIA.ABBR%TYPE,
    a_nome_regione    CD_REGIONE.NOME_REGIONE%TYPE,
    a_nome_schermo    CD_SCHERMO.DESC_SCHERMO%TYPE,
    a_passaggi        NUMBER,
    a_disponibilita   NUMBER,
    a_id_sala         cd_sala.ID_SALA%TYPE
);

TYPE C_SCHERMI_LIBERA IS REF CURSOR RETURN R_SCHERMI_LIBERA;

TYPE C_SALE IS REF CURSOR RETURN R_SALE;

TYPE R_CINEMA IS RECORD
(
    a_id_cinema       CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_circuito   CD_CIRCUITO.NOME_CIRCUITO%TYPE
);

TYPE C_CINEMA IS REF CURSOR RETURN R_CINEMA;

TYPE R_ATRII IS RECORD
(
    a_id_atrio        CD_ATRIO.ID_ATRIO%TYPE,
    a_nome_atrio      CD_ATRIO.DESC_ATRIO%TYPE,
    a_nome_circuito   CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE
);

TYPE C_ATRII IS REF CURSOR RETURN R_ATRII;

TYPE R_PERIODO IS RECORD
(
a_id_unita CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
a_id_desc_unita CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE
);

TYPE C_PERIODO IS REF CURSOR RETURN R_PERIODO;

TYPE R_AREA_NIELSEN IS RECORD
(
    a_id_area_nielsen CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
    a_desc_area_nielsen CD_AREA_NIELSEN.DESC_AREA%TYPE,
    a_num_schermi NUMBER,
    a_regioni VARCHAR2(255)
);

TYPE C_AREA_NIELSEN IS REF CURSOR RETURN R_AREA_NIELSEN;

FUNCTION ELENCO_PRODOTTI_VENDITA_TAB(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE,p_id_mod_vendita cd_prodotto_vendita.ID_MOD_VENDITA%type, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio cd_listino.data_inizio%type, p_data_fine cd_listino.data_fine%type,p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE, p_tipo_disp VARCHAR2) RETURN C_LISTA_VENDITA_TAB;
FUNCTION ELENCO_PROD_VENDITA_TAB_RIC(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE,p_id_mod_vendita cd_prodotto_vendita.ID_MOD_VENDITA%type, p_data_inizio cd_listino.data_inizio%type, p_data_fine cd_listino.data_fine%type,p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE) RETURN C_LISTA_VENDITA_TAB;
FUNCTION ELENCO_PRODOTTI_VENDITA_IS(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE,p_id_mod_vendita cd_prodotto_vendita.ID_MOD_VENDITA%type, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio cd_listino.data_inizio%type, p_data_fine cd_listino.data_fine%type ) RETURN C_LISTA_VENDITA_IS;
FUNCTION ELENCO_PROD_VENDITA_IS_RIC(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE,p_id_mod_vendita cd_prodotto_vendita.ID_MOD_VENDITA%type, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio cd_listino.data_inizio%type, p_data_fine cd_listino.data_fine%type ) RETURN C_LISTA_VENDITA_IS;
FUNCTION FU_GET_MODALITA_VENDITA RETURN C_MODALITA_VENDITA;
FUNCTION FU_GET_STATO_VENDITA RETURN C_STATO_VENDITA;
FUNCTION FU_GET_SELECT_STATO_VENDITA RETURN C_STATO_VENDITA_SELECT;
FUNCTION FU_GET_DISPONIBILITA_IS(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE) RETURN CHAR;
FUNCTION FU_GET_LUOGO_PROD_VENDITA(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN C_LUOGO;
FUNCTION FU_GET_BREAK_LIBERA(p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE, p_id_cinema CD_CINEMA.ID_CINEMA%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,p_id_schermo CD_SCHERMO.ID_SCHERMO%TYPE, p_data_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE,p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE) RETURN C_BREAK;


FUNCTION FU_GET_SCHERMI_LIBERA(
p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
 p_id_tipo_cinema CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
  p_id_cinema CD_CINEMA.ID_CINEMA%TYPE,
   p_id_comune CD_COMUNE.ID_COMUNE%TYPE,
    p_id_provincia CD_PROVINCIA.ID_PROVINCIA%TYPE,
     p_id_regione CD_REGIONE.ID_REGIONE%TYPE,
      p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
       p_id_schermo CD_SCHERMO.ID_SCHERMO%TYPE,
        p_data_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE,
        p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE) RETURN C_SCHERMI_LIBERA;

FUNCTION FU_GET_SALE_CIRCUITO(p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE) RETURN C_SALE;
FUNCTION FU_GET_SALE_LIBERA(p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,p_id_cinema CD_CINEMA.ID_CINEMA%TYPE, p_id_comune CD_COMUNE.ID_COMUNE%TYPE, p_id_regione CD_REGIONE.ID_REGIONE%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_SALA_VENDITA.DATA_EROGAZIONE%TYPE,p_data_fine CD_SALA_VENDITA.DATA_EROGAZIONE%TYPE, p_id_tipo_cinema CD_TARIFFA.ID_TIPO_CINEMA%TYPE) RETURN C_SALE;
FUNCTION FU_GET_CINEMA_CIRCUITO(P_ID_CIRCUITO CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE, P_ID_PRODOTTO_VENDITA CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,P_DATA_INIZIO cd_proiezione.data_proiezione%type,P_DATA_FINE cd_proiezione.data_proiezione%type, p_id_ambito CD_LUOGO.ID_LUOGO%TYPE, p_id_comune CD_COMUNE.ID_COMUNE%TYPE, p_id_tipo_cinema CD_TARIFFA.ID_TIPO_CINEMA%TYPE) RETURN C_CINEMA;
FUNCTION FU_GET_ATRII_CIRCUITO(p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE) RETURN C_ATRII;
FUNCTION FU_GET_ATRII_LIBERA(p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,p_id_cinema CD_CINEMA.ID_CINEMA%TYPE, p_id_comune CD_COMUNE.ID_COMUNE%TYPE, p_id_regione CD_REGIONE.ID_REGIONE%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_ATRIO_VENDITA.DATA_EROGAZIONE%TYPE,p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE, p_id_tipo_cinema CD_TARIFFA.ID_TIPO_CINEMA%TYPE) RETURN C_ATRII;
FUNCTION FU_GET_CINEMA_LIBERA(p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,p_id_comune CD_COMUNE.ID_COMUNE%TYPE, p_id_regione CD_REGIONE.ID_REGIONE%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_SALA_VENDITA.DATA_EROGAZIONE%TYPE,p_data_fine CD_SALA_VENDITA.DATA_EROGAZIONE%TYPE, p_id_tipo_cinema CD_TARIFFA.ID_TIPO_CINEMA%TYPE) RETURN C_CINEMA;
FUNCTION FU_COUNT_AMBITI_CIRCUITO(p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE, p_id_ambito CD_LUOGO.ID_LUOGO%TYPE) RETURN NUMBER;
FUNCTION FU_GET_PERIODI(p_data_inizio CD_TARIFFA.DATA_INIZIO%TYPE,p_data_fine CD_TARIFFA.DATA_FINE%TYPE) RETURN C_PERIODO;
FUNCTION FU_IS_PERIODO_SETTIMANA(p_data_inizio CD_TARIFFA.DATA_INIZIO%TYPE,p_data_fine CD_TARIFFA.DATA_FINE%TYPE) RETURN NUMBER;
FUNCTION FU_IS_PERIODO_QUINDICINALE(p_data_inizio CD_TARIFFA.DATA_INIZIO%TYPE,p_data_fine CD_TARIFFA.DATA_FINE%TYPE) RETURN NUMBER;
FUNCTION FU_GET_UNITA_PROD_VENDITA(p_id_prod_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN C_PERIODO;

FUNCTION FU_GET_ATRII_DISPONIBILI(
                                  p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                  p_data_inizio CD_ATRIO_VENDITA.DATA_EROGAZIONE%TYPE,
                                  p_id_listino CD_CIRCUITO_ATRIO.ID_LISTINO%TYPE,
                                  p_id_prodotto_vendita CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN NUMBER;

FUNCTION FU_GET_SALE_DISPONIBILI(
                                  p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                  p_data_inizio CD_SALA_VENDITA.DATA_EROGAZIONE%TYPE,
                                  p_id_listino CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                  p_id_prodotto_vendita CD_SALA_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN NUMBER;

FUNCTION FU_GET_CINEMA_DISPONIBILI(
                                  p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                  p_data_inizio CD_CINEMA_VENDITA.DATA_EROGAZIONE%TYPE,
                                  p_id_listino CD_CIRCUITO_CINEMA.ID_LISTINO%TYPE,
                                  p_id_prodotto_vendita CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN NUMBER;


--
--
-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_STATI_VEND_SUCC_VAL
--
-- DESCRIZIONE:  fonisce l'elenco degli stati di vendita (usato generalmente nelle combo)
-- aventi il campo "stati_successivi" valorizzato
--
-- OUTPUT: Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
FUNCTION FU_GET_STATI_VEND_SUCC_VAL RETURN C_STATO_VENDITA_SELECT;

function fu_verifica_affollamento(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, p_stato_di_vendita cd_prodotto_acquistato.stato_di_vendita%type )  return number;
function fu_calcola_affollamento(p_tipo_affollamento in varchar2 ,p_id_prodotto_vendita  in cd_prodotto_acquistato.id_prodotto_vendita%type, p_stato_di_vendita in cd_prodotto_acquistato.stato_di_vendita%type, p_data_inizio cd_prodotto_acquistato.data_inizio%type, p_data_fine cd_prodotto_acquistato.data_fine%type) return R_DISPONIBILITA;
function fu_affollamento(p_tipo_affollamento in varchar2 ,p_id_prodotto_vendita  in cd_prodotto_acquistato.id_prodotto_vendita%type, p_stato_di_vendita in cd_prodotto_acquistato.stato_di_vendita%type, p_data_inizio cd_prodotto_acquistato.data_inizio%type, p_data_fine cd_prodotto_acquistato.data_fine%type) return VARCHAR2;
FUNCTION FU_GET_STATI_VENDITA(p_tipo VARCHAR2, p_stato_ven CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_STATO_VENDITA_SELECT;
FUNCTION FU_GET_STATI_VENDITA_PROD(p_tipo VARCHAR2, p_stato_ven CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_STATO_VENDITA_PROD;
FUNCTION FU_GET_NUM_SCHERMI(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE, p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE) RETURN NUMBER;
FUNCTION FU_GET_ID_STATO_VENDITA(p_descr_breve CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE) RETURN CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE;
FUNCTION FU_GET_AREE_NIELSEN(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE, p_data_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE, p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE) RETURN C_AREA_NIELSEN;
FUNCTION FU_GET_NUM_SCHERMI_NIELSEN(p_id_area_nielsen CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,p_data_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE, p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE) RETURN NUMBER;
FUNCTION FU_GET_REGIONI_NIELSEN(p_id_area_nielsen CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE) RETURN VARCHAR2;
FUNCTION FU_GET_NUM_AMBIENTI(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE, p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE) RETURN NUMBER;

FUNCTION FU_GET_NUM_AMBIENTI_LIBERA(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE, p_data_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE, p_ambienti VARCHAR2) RETURN NUMBER;

FUNCTION FU_GET_SCONTO_STAGIONALE(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_data_inizio CD_TARIFFA.DATA_INIZIO%TYPE, p_data_fine CD_TARIFFA.DATA_FINE%TYPE, p_id_formato CD_TARIFFA.ID_FORMATO%TYPE, p_misura_temp CD_TARIFFA.ID_MISURA_PRD_VE%TYPE) RETURN CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;

FUNCTION FU_GET_AFFOLLAMENTO_PRODOTTO(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE,p_id_formato cd_prodotto_acquistato.ID_FORMATO%TYPE) RETURN NUMBER;

FUNCTION FU_AFFOLLAMENTO_CIRCUITO(p_tipo_affollamento in varchar2, p_id_circuito in cd_circuito.id_circuito%type, p_stato_di_vendita in CD_STATO_DI_VENDITA.id_stato_vendita%type,p_data_inizio cd_prodotto_acquistato.data_inizio%type, p_data_fine cd_prodotto_acquistato.data_fine%type) return C_AFFOLL_CIRCUITO;

FUNCTION FU_AFFOLLAMENTO_SALA(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_sala CD_SALA.ID_SALA%TYPE, p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER;
FUNCTION FU_AFFOLLAMENTO_SALA_STATO(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_sala CD_SALA.ID_SALA%TYPE, p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,p_descr_breve CD_STATO_DI_VENDITA.DESCR_BREVE%type) RETURN NUMBER;
------------NUOVA FUNZIONE PER CALCOLO DELL'AFFOLLAMENTO---------------------------------------------------
FUNCTION FU_AFFOLLAMENTO_SALA_STATO_NEW(
                                        p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, 
                                        p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, 
                                        p_id_sala CD_SALA.ID_SALA%TYPE--, 
                                        --p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        --p_descr_breve CD_STATO_DI_VENDITA.DESCR_BREVE%type
                                       ) RETURN NUMBER;
--------------------------------------------------------------------------------------------------
FUNCTION FU_GET_SCONTO_STAGIONALE(p_id_listino CD_LISTINO.ID_LISTINO%TYPE, p_data_inizio CD_TARIFFA.DATA_INIZIO%TYPE, p_data_fine CD_TARIFFA.DATA_FINE%TYPE) RETURN CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
FUNCTION FU_GET_AREA_NIELSEN_SALA(p_id_sala CD_SALA.ID_SALA%TYPE) RETURN CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE;




TYPE R_LISTA_VENDITA_IS_NEW IS RECORD
(
    a_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
    a_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
    a_circuito CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_prodotto_pubblicitario CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_id_listino CD_LISTINO.ID_LISTINO%TYPE,
    a_numero_comunicati NUMBER,
    a_numero_ambienti NUMBER,
    a_disponibilita  NUMBER,
    a_tariffa CD_TARIFFA.IMPORTO%TYPE,
    a_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE,
    a_sconto_stagionale CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
    a_id_ambito CD_LUOGO.ID_LUOGO%TYPE,
    a_id_unita CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    a_desc_unita CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
    a_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
    a_desc_formato CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
    a_id_tipo_cinema CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
    a_desc_tipo_cinema CD_TIPO_CINEMA.DESC_TIPO_CINEMA%TYPE,
    a_durata_in_giorni number,
    a_durata_periodo number
) ;

TYPE C_LISTA_VENDITA_IS_NEW IS REF CURSOR RETURN R_LISTA_VENDITA_IS_NEW;

FUNCTION ELENCO_PRODOTTI_VENDITA_IS_NEW(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE,p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE) RETURN C_LISTA_VENDITA_IS_NEW;--, p_luogo cd_luogo.desc_luogo%type ) RETURN C_LISTA_VENDITA_IS_NEW;

FUNCTION ELENCO_PRODOTTI_VEN_SPEC_TAB(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE, p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE, p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE, p_tipo_disp VARCHAR2) RETURN C_LISTA_VENDITA_TAB;

FUNCTION LISTA_PROD_VEND_SPEC_TAB_RIC(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE, p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE, p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE) RETURN C_LISTA_VENDITA_TAB;

FUNCTION ELENCO_PRODOTTI_VENDITA_TABNEW(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE, p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE, p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE, p_tipo_disp VARCHAR2) RETURN C_LISTA_VENDITA_TAB;

FUNCTION ELENCO_PRODOTTI_VENDITA_TABNE2(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE, p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE, p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE, p_tipo_disp VARCHAR2) RETURN C_LISTA_VENDITA_TAB;

FUNCTION ELENCO_PRODOTTI_VENDITA_TAB_DE(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE, p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE, p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE, p_tipo_disp VARCHAR2) RETURN C_LISTA_VENDITA_TAB;
FUNCTION ELENCO_PROD_VENDITA_TAB_RIC_DE(p_categoria_prodotto CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE, p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE, p_data_inizio CD_LISTINO.DATA_INIZIO%TYPE, p_data_fine CD_LISTINO.DATA_FINE%TYPE, p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE) RETURN C_LISTA_VENDITA_TAB;

END PA_CD_ESTRAZIONE_PROD_VENDITA; 
/

