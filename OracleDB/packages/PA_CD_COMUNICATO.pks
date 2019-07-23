CREATE OR REPLACE PACKAGE VENCD.PA_CD_COMUNICATO AS
/***************************************************************************************
   NAME:       PA_CD_COMUNICATO
   AUTHOR:     Mauro Viel (Altran)
   PURPOSE:   Questo package contiene procedure/funzioni necessarie per la gestione dei
              comunicati
   REVISIONS:
   Ver        Date        Author                Description
   ---------  ----------  ---------------       ------------------------------------
   1.0        17/06/2009  Mauro Viel (Altran) Created this package.
****************************************************************************************/


TYPE R_AMBITI_VENDITA IS RECORD
(
    A_ID_AMBITO_VENDITA INTEGER
) ;

--TYPE R_COMUNICATI_SOGGETTO IS RECORD
--(
--    p_id_comunicato                CD_COMUNICATO.id_comunicato%TYPE,
--    p_nome_circuito                CD_CIRCUITO.nome_circuito%TYPE,
--    p_desc_prodotto                CD_PRODOTTO_PUBB.desc_prodotto%TYPE,
--    p_data_erogazione_prev         CD_COMUNICATO.data_erogazione_prev%TYPE,
--    p_id_soggetto_di_piano         CD_COMUNICATO.id_soggetto_di_piano%TYPE,
--    p_descrizione                  CD_SOGGETTO_DI_PIANO.descrizione%TYPE,
--    p_flg_annullato                CD_COMUNICATO.flg_annullato%TYPE
--) ;

TYPE R_COMUNICATI_SOGGETTO IS RECORD
(
    p_id_soggetto_di_piano         CD_COMUNICATO.id_soggetto_di_piano%TYPE,
    p_descrizione                  CD_SOGGETTO_DI_PIANO.descrizione%TYPE,
    p_cod_soggetto_di_piano        CD_SOGGETTO_DI_PIANO.COD_SOGG%TYPE,
    p_titolo_mat                   CD_MATERIALE.TITOLO%TYPE,
    p_id_comunicato                VARCHAR(100),
    p_id_cinema                    CD_CINEMA.ID_CINEMA%TYPE,
    p_nome_cinema                  CD_CINEMA.NOME_CINEMA%TYPE,
    p_comune_cinema                CD_COMUNE.COMUNE%TYPE,
    p_provincia_cinema             CD_PROVINCIA.PROVINCIA%TYPE,
    p_regione_cinema               CD_REGIONE.NOME_REGIONE%TYPE,
    p_nome_ambiente                VARCHAR2(40),
    p_data_erogazione_prev         CD_COMUNICATO.data_erogazione_prev%TYPE,
    p_tipo_luogo                   VARCHAR2(2),
    p_flg_annullato                CD_COMUNICATO.flg_annullato%TYPE
) ;

TYPE C_LISTA_AMBITI IS REF CURSOR RETURN R_AMBITI_VENDITA;
TYPE C_LISTA_COMUNICATI_SOGGETTO IS REF CURSOR RETURN R_COMUNICATI_SOGGETTO;

-- eccezione del comunicato
comunicato_exception EXCEPTION;

TYPE R_CINEMA IS RECORD
(
    a_id_cinema       CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE
);

TYPE C_CINEMA IS REF CURSOR RETURN R_CINEMA;

TYPE R_MATERIALE_SIAE IS RECORD
(
    a_id_materiale       VI_CD_PAGAMENTO_SIAE.ID_MATERIALE%TYPE,
    a_cliente            VI_CD_PAGAMENTO_SIAE.CLIENTE%TYPE,
    a_soggetto           VI_CD_PAGAMENTO_SIAE.SOGGETTO%TYPE,
    a_desc_materiale     VI_CD_PAGAMENTO_SIAE.TITOLO_MATERIALE%TYPE,
    a_durata             VI_CD_PAGAMENTO_SIAE.DURATA%TYPE,
    a_autore_colonna     VI_CD_PAGAMENTO_SIAE.AUTORE%TYPE,
    a_titolo_colonna     VI_CD_PAGAMENTO_SIAE.TITOLO_COLONNA%TYPE,
    a_flg_siae           VI_CD_PAGAMENTO_SIAE.FLG_SIAE%TYPE,
    a_num_passaggi       NUMBER,
    a_importo_pagato     VI_CD_PAGAMENTO_SIAE.IMPORTO_SIAE_PAGATO%TYPE,
    a_importo_dovuto     VI_CD_PAGAMENTO_SIAE.IMPORTO_SIAE%TYPE,
    a_importo_siae       VI_CD_PAGAMENTO_SIAE.IMPORTO_SIAE%TYPE,
    a_num_schermi        NUMBER,
    a_causale            CD_MATERIALE.CAUSALE%TYPE,
    a_desc_area          VI_CD_PAGAMENTO_SIAE.DESC_AREA%TYPE,
    a_nazionalita        CD_MATERIALE.NAZIONALITA%TYPE,
    a_agenzia_produz     CD_MATERIALE.AGENZIA_PRODUZ%TYPE,
    a_desc_estesa        CD_MATERIALE.DESCRIZIONE%TYPE
);

TYPE C_MATERIALE_SIAE IS REF CURSOR RETURN R_MATERIALE_SIAE;

TYPE R_CENSURA_MATERIALE_SIAE IS RECORD
(
    a_id_materiale       VI_CD_PAGAMENTO_SIAE.ID_MATERIALE%TYPE,
    a_cliente            VI_CD_PAGAMENTO_SIAE.CLIENTE%TYPE,
    a_soggetto           VI_CD_PAGAMENTO_SIAE.SOGGETTO%TYPE,
    a_desc_materiale     VI_CD_PAGAMENTO_SIAE.TITOLO_MATERIALE%TYPE,
    a_durata             VI_CD_PAGAMENTO_SIAE.DURATA%TYPE,
    a_autore_colonna     VI_CD_PAGAMENTO_SIAE.AUTORE%TYPE,
    a_titolo_colonna     VI_CD_PAGAMENTO_SIAE.TITOLO_COLONNA%TYPE,
    a_flg_siae           VI_CD_PAGAMENTO_SIAE.FLG_SIAE%TYPE,
    a_num_passaggi       NUMBER,
    a_importo_pagato     VI_CD_PAGAMENTO_SIAE.IMPORTO_SIAE_PAGATO%TYPE,
    a_importo_dovuto     VI_CD_PAGAMENTO_SIAE.IMPORTO_SIAE%TYPE,
    a_importo_siae       VI_CD_PAGAMENTO_SIAE.IMPORTO_SIAE%TYPE,
    a_num_schermi        NUMBER,
    a_causale            CD_MATERIALE.CAUSALE%TYPE,
    a_desc_area          VI_CD_PAGAMENTO_SIAE.DESC_AREA%TYPE,
    a_nazionalita        CD_MATERIALE.NAZIONALITA%TYPE,
    a_agenzia_produz     CD_MATERIALE.AGENZIA_PRODUZ%TYPE,
    a_desc_estesa        CD_MATERIALE.DESCRIZIONE%TYPE,
    a_data_autorizz      CD_MATERIALE.DATA_AUT_INVIO_MINISTERO%TYPE,
    a_data_consegna      CD_MATERIALE.DATA_CONSEGNA_MINISTERO%TYPE,
    a_data_nulla_osta    CD_MATERIALE.DATA_RIL_NULLAOSTA_MINISTERO%TYPE,
    a_num_protocollo     CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO%TYPE,
    a_traduzione_titolo  CD_MATERIALE.TRADUZIONE_TITOLO%TYPE
);

TYPE C_CENSURA_MATERIALE_SIAE IS REF CURSOR RETURN R_CENSURA_MATERIALE_SIAE;

/*******************************************************************************
 ANNULLA COMUNICATO
 Author:  Francesco Abbundo, Teoresi Group, Settembre 2009
 Annulla logicamente  il comunicato.
 Aggiunto un parametro discriminatorio sul chiamante.
*******************************************************************************/
  PROCEDURE PR_ANNULLA_COMUNICATO(p_id_comunicato IN  CD_COMUNICATO.id_comunicato%TYPE,
                                  p_chiamante     IN  VARCHAR2,
                                  p_esito         IN OUT NUMBER,
                                  p_piani_errati  OUT VARCHAR2);
/*******************************************************************************
 RECUPERA COMUNICATO
 Author:  Francesco Abbundo, Teoresi Group, Settembre 2009
 Recupera un comunicato precedentemente annullato logicamente.
 Aggiunto un parametro discriminatorio sul chiamante.
*******************************************************************************/
  PROCEDURE PR_RECUPERA_COMUNICATO(p_id_comunicato IN  CD_COMUNICATO.id_comunicato%TYPE,
                                   p_chiamante     IN  VARCHAR2,
                                   p_esito         OUT NUMBER);
/*******************************************************************************
 SALTA COMUNICATO
 Author:  Francesco Abbundo, Teoresi Group, Settembre 2009
 Effettua il salto del comunicato
*******************************************************************************/
PROCEDURE PR_SALTA_COMUNICATO(p_id_comunicato  IN CD_COMUNICATO.id_comunicato%TYPE,
                                p_esito OUT NUMBER);

/*******************************************************************************
 VERIFICA MESSA IN ONDA
 Author:  Mauro Viel , Altran, Ottobre 2009

 Per mezzo di questa funzione si puo verificare la messa in onda di un
 particolare comunicato
*******************************************************************************/
 --FUNCTION  FU_VERIFICA_MESSA_IN_ONDA(p_id_comunicato IN cd_comunicato.id_comunicato%type) RETURN char;
FUNCTION FU_VERIFICA_MESSA_IN_ONDA(v_data_erogazione_prev  cd_comunicato.DATA_EROGAZIONE_PREV%type) RETURN char;

FUNCTION  FU_VERIFICA_DOPO_MESSA_IN_ONDA(p_id_comunicato IN cd_comunicato.id_comunicato%type) RETURN char;
FUNCTION  FU_VERIFICA_MESSA_IN_ONDA_COM(p_id_comunicato  cd_comunicato.ID_COMUNICATO%type) RETURN char;

/*******************************************************************************
 PR_CREA_COMUNICATI_MODULO
 Author:  Simone Bottani, Altran, Luglio 2009

 Inserisce tutti i comunicati partendo da un prodotto acquistato
*******************************************************************************/
  PROCEDURE PR_CREA_COMUNICATI_MODULO(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                 p_id_ambito NUMBER,
                                 p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_data_fine   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                 p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                 p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
                                 p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
                                 p_flg_segui_il_film CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE
                                 );

/*******************************************************************************
 PR_CREA_COMUNICATI_LIBERA
 Author:  Simone Bottani, Altran, Luglio 2009

 Inserisce tutti i comunicati partendo da un prodotto acquistato
*******************************************************************************/
  PROCEDURE PR_CREA_COMUNICATI_LIBERA(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                 p_id_ambito NUMBER,
                                 p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_data_fine   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_list_id_ambito id_list_type,
                                 p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                 p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                 p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE);

/*******************************************************************************
 PR_CREA_COMUNICATI_NIELSEN
 Author:  Simone Bottani, Altran, Luglio 2009

 Inserisce tutti i comunicati partendo da un prodotto acquistato,
 per le aree nielsen indicate
*******************************************************************************/
  PROCEDURE PR_CREA_COMUNICATI_NIELSEN(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                 p_id_ambito NUMBER,
                                 p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_data_fine   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                 p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                 p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
                                 p_list_id_area id_list_type);
--
/*******************************************************************************
 PR_INSERT_COMUNICATI_SCHERMO
 Author:  Simone Bottani, Altran, Agosto 2009

 Inserisci i comunicati per i break appartenenti agli schermi scelti
*******************************************************************************/

   PROCEDURE PR_INSERT_COMUNICATI_SCHERMO(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
                                         p_num_giorni NUMBER,
                                        -- p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE);


/*******************************************************************************
 PR_INSERT_COMUNICATI_CINEMA
 Author:  Simone Bottani, Altran, Luglio 2009

 Aggiorna tutti i comunicati di un prodotto acquistato inserendo il cinema di vendita
*******************************************************************************/
    PROCEDURE PR_INSERT_COMUNICATI_CINEMA(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_num_giorni NUMBER,
--                                         p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE);
/*******************************************************************************
 PR_INSERT_COMUNICATI_ATRIO
 Author:  Simone Bottani, Altran, Luglio 2009

 Aggiorna tutti i comunicati di un prodotto acquistato inserendo l'atrio di vendita
*******************************************************************************/
    PROCEDURE PR_INSERT_COMUNICATI_ATRIO(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_num_giorni NUMBER,
                                        -- p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE);
/*******************************************************************************
 PR_INSERT_COMUNICATI_SALA
 Author:  Simone Bottani, Altran, Luglio 2009

 Aggiorna tutti i comunicati di un prodotto acquistato inserendo la sala di vendita
*******************************************************************************/
    PROCEDURE PR_INSERT_COMUNICATI_SALA(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_num_giorni NUMBER,
                                        -- p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE);

/*******************************************************************************
 FU_GET_NUM_COMUNICATI
 Author:  Simone Bottani, Altran, Settembre 2009

 Restituisce il numero di comunicati abbinati ad un prodotto acquistato
*******************************************************************************/

FUNCTION FU_GET_NUM_COMUNICATI(p_id_prd_acq CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER;



/*******************************************************************************

 FU_GET_DGC_CD

 Author:  Mauro Viel, Altran, Settembre 2009

Determina il Detteglio di gestione commerciale (DGC) per mezzo della
chiamata alla procedura PA_PC_DGC.fu_get_DGC
*******************************************************************************/

--FUNCTION FU_GET_DGC_CD(p_cod_tipo_pubb CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE) RETURN VARCHAR2;

FUNCTION FU_COMUNICATI_SOGGETTO(p_id_prodotto_acquistato IN CD_COMUNICATO.id_prodotto_acquistato%TYPE,
                                p_data_erogazione_from IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                p_data_erogazione_to IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                p_id_regione IN CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_provincia IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
                                p_id_comune IN CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_cinema IN CD_CINEMA.id_cinema%TYPE,
                                p_id_soggetto IN CD_SOGGETTO_DI_PIANO.id_soggetto_di_piano%TYPE)
                                RETURN C_LISTA_COMUNICATI_SOGGETTO;

FUNCTION FU_GET_ELENCO_CINEMA RETURN C_CINEMA;

PROCEDURE PR_CONFERMA_PAGAMENTO_SIAE(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE, p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE, p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE);

FUNCTION FU_MATERIALI_SIAE(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE, p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE, p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE) RETURN C_MATERIALE_SIAE;

-----PROVA LISTA COMUNICATI SOGGETTO DI PAOLO------------------
TYPE REC_GRUPPI_COM IS RECORD (
    ID_SOGGETTO_DI_PIANO  CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
    DESC_SOGG_DI_PIANO    CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
    COD_SOGG_DI_PIANO     CD_SOGGETTO_DI_PIANO.COD_SOGG%TYPE,
    TITOLO_MAT 						CD_MATERIALE.TITOLO%TYPE,
    ID_STR_COMUNICATO			VARCHAR2(3200),
    ID_CINEMA             CD_CINEMA.ID_CINEMA%TYPE,
    NOME_CINEMA						CD_CINEMA.NOME_CINEMA%TYPE,
    COMUNE_CINEMA					CD_COMUNE.COMUNE%TYPE,
    PROVINCIA_CINEMA			CD_PROVINCIA.PROVINCIA%TYPE,
    REGIONE_CINEMA				CD_REGIONE.NOME_REGIONE%TYPE,
    NOME_AMBIENTE					CD_SALA.NOME_SALA%TYPE,
    DATA_EROGAZIONE				DATE,
    LUOGO									VARCHAR2(3),
    FLG_ANNULLATO					VARCHAR2(1)
);

TYPE TAB_GRUPPI_COM IS TABLE OF REC_GRUPPI_COM;

TYPE REC_TEMP IS RECORD (
    ID_SOGGETTO_DI_PIANO  CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
    DESC_SOGG_DI_PIANO    CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
    COD_SOGG_DI_PIANO     CD_SOGGETTO_DI_PIANO.COD_SOGG%TYPE,
    TITOLO_MAT 						CD_MATERIALE.TITOLO%TYPE,
    ID_COMUNICATO					cd_comunicato.ID_COMUNICATO%TYPE,
    ID_CINEMA             CD_CINEMA.ID_CINEMA%TYPE,
    NOME_CINEMA						CD_CINEMA.NOME_CINEMA%TYPE,
    COMUNE_CINEMA					CD_COMUNE.COMUNE%TYPE,
    PROVINCIA_CINEMA			CD_PROVINCIA.PROVINCIA%TYPE,
    REGIONE_CINEMA				CD_REGIONE.NOME_REGIONE%TYPE,
    NOME_AMBIENTE					CD_SALA.NOME_SALA%TYPE,
    DATA_EROGAZIONE				DATE,
    LUOGO									VARCHAR2(3),
    FLG_ANNULLATO					VARCHAR2(1)
);

TYPE TAB_TEMP_REC IS TABLE OF REC_TEMP INDEX BY BINARY_INTEGER;
TAB_TEMP TAB_TEMP_REC;

TYPE C_GRUPPI_COM IS REF CURSOR RETURN REC_GRUPPI_COM;

--VARIABILI PER LA LISTA GRUPPI COMUNICATI DI PAOLO----
PROCEDURE PR_SETTA_VARIABILI_COM (P_ID_PRODOTTO_ACQUISTATO IN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
							P_DATA_EROGAZIONE_FROM IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                            P_DATA_EROGAZIONE_TO IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                            P_ID_REGIONE IN CD_REGIONE.ID_REGIONE%TYPE,
                            P_ID_PROVINCIA IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
                            P_ID_COMUNE IN CD_COMUNE.ID_COMUNE%TYPE,
                            P_ID_CINEMA IN CD_CINEMA.ID_CINEMA%TYPE,
                            P_ID_SOGGETTO IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE);
	
FUNCTION FU_RIT_PROD_ACQUISTATO RETURN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE;
FUNCTION FU_DATA_DA   RETURN   DATE;
FUNCTION FU_DATA_A    RETURN   DATE;
FUNCTION FU_REGIONE   RETURN   CD_REGIONE.ID_REGIONE%TYPE;
FUNCTION FU_PROVINCIA	RETURN   CD_PROVINCIA.ID_PROVINCIA%TYPE;
FUNCTION FU_COMUNE    RETURN	  CD_COMUNE.ID_COMUNE%TYPE;
FUNCTION FU_CINEMA    RETURN   CD_CINEMA.ID_CINEMA%TYPE;
FUNCTION FU_SOGGETTO  RETURN   CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;

FUNCTION  FU_GRUPPI_COMUNICATI (P_ID_PRODOTTO_ACQUISTATO IN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
							   P_DATA_EROGAZIONE_FROM IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
	                           P_DATA_EROGAZIONE_TO IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
	                           P_ID_REGIONE IN CD_REGIONE.ID_REGIONE%TYPE,
	                           P_ID_PROVINCIA IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
	                           P_ID_COMUNE IN CD_COMUNE.ID_COMUNE%TYPE,
	                           P_ID_CINEMA IN CD_CINEMA.ID_CINEMA%TYPE,
	                           P_ID_SOGGETTO IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE
	                           ) RETURN TAB_GRUPPI_COM PIPELINED;
                               
FUNCTION  FU_LISTA_GRUPPI_COMUNICATI(p_id_prodotto_acquistato IN CD_COMUNICATO.id_prodotto_acquistato%TYPE,
                                     p_data_erogazione_from IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                     p_data_erogazione_to IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                     p_id_regione IN CD_REGIONE.ID_REGIONE%TYPE,
                                     p_id_provincia IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
                                     p_id_comune IN CD_COMUNE.ID_COMUNE%TYPE,
                                     p_id_cinema IN CD_CINEMA.id_cinema%TYPE,
                                     p_id_soggetto IN CD_SOGGETTO_DI_PIANO.id_soggetto_di_piano%TYPE
                                     ) RETURN C_GRUPPI_COM;

FUNCTION FU_CENSURA_MATERIALI_SIAE(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, 
                                    p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, 
                                    p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE, 
                                    p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE, 
                                    p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE, 
                                    p_stato varchar2) RETURN C_CENSURA_MATERIALE_SIAE;
-----------------------------------------------------------------------------                               
END PA_CD_COMUNICATO; 
/

