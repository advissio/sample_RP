CREATE OR REPLACE PACKAGE VENCD.Pa_Cd_Pianificazione IS


v_stampa_importi_richiesta           VARCHAR2(3):='ON';

v_stampa_imp_rich_piano             VARCHAR2(3):='ON';

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione delle pianificazioni
--
-- --------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE Mauro Viel - Simone Bottani 2009
-- --------------------------------------------------------------------------------------------


PROCEDURE PR_TEST;



FUNCTION FU_GET_DATA_PER_IN(P_ID_PERIOD_SPECIALE cd_periodo_speciale.id_periodo_speciale%type, p_id_periodo cd_periodi_cinema.id_periodo%type)return DATE;
FUNCTION FU_GET_DATA_PER_FI(P_ID_PERIOD_SPECIALE cd_periodo_speciale.id_periodo_speciale%type,p_id_periodo cd_periodi_cinema.id_periodo%type)return DATE;

-- ECCEZIONE DELLA PIANIFICAZIONE
PIANIFICAZIONE_EXCEPTION EXCEPTION;
--RI GA DELLA PIANIFICAZIONE
--V_ROW_PIANIFICAZIONE   CD_PIANIFICAZIONE %ROWTYPE;

PROCEDURE PR_COUNT_PIANI(P_ID_PIANO IN CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO IN CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        ESITO OUT NUMBER );

PROCEDURE PR_INSERISCI_RICHIESTA(
                                 p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                                 p_data_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
                                 p_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 p_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                 p_stato_vendita CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 p_cod_categoria_prodotto CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_target CD_PIANIFICAZIONE.ID_TARGET%TYPE,
                                 p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                                 p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                                 p_lista_periodi  periodo_list_type,
                                 p_lista_intermediari intermediario_list_type,
                                 p_lista_soggetti soggetto_list_type,
                                 p_lista_formati id_list_type,
                                 p_id_piano OUT CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 p_id_ver_piano OUT CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 p_nota cd_pianificazione.NOTE%TYPE,
                                 p_tipo_contratto cd_pianificazione.TIPO_CONTRATTO%type
                                 );

PROCEDURE PR_MODIFICA_RICHIESTA(
                                 p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                                 p_data_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
                                 p_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 p_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                 p_stato_vendita CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 p_cod_categoria_prodotto CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_target CD_PIANIFICAZIONE.ID_TARGET%TYPE,
                                 p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                                 p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                                 p_lista_periodi  periodo_list_type,
                                 p_lista_intermediari intermediario_list_type,
                                 p_lista_soggetti soggetto_list_type,
                                 p_lista_formati id_list_type,
                                 p_nota cd_pianificazione.NOTE%TYPE,
                                 p_tipo_contratto cd_pianificazione.TIPO_CONTRATTO%type
);

PROCEDURE PR_INSERISCI_IMPORTI_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                        p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                        p_lista_periodi  periodo_list_type);

PROCEDURE PR_INSERISCI_IMPORTI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                        p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                        p_lista_periodi  periodo_list_type);

PROCEDURE PR_INSERISCI_IMPORTO_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_periodo PERIODO,
                                     p_id_periodo OUT CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE);

PROCEDURE PR_INSERISCI_IMPORTO_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_periodo PERIODO,
                                     p_id_periodo OUT CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE);

PROCEDURE PR_ELIMINA_IMPORTO_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_id_periodo CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE,
                                     p_periodo PERIODO,
                                     p_esito OUT NUMBER);

PROCEDURE PR_ELIMINA_IMPORTO_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_id_periodo CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE,
                                     p_periodo PERIODO,
                                     p_esito OUT NUMBER);

PROCEDURE PR_INSERISCI_FORMATI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                    p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                    p_lista_formati  id_list_type);

PROCEDURE PR_ELIMINA_FORMATI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                            p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                            p_id_formato  CD_FORMATI_PIANO.ID_FORMATO%TYPE);

PROCEDURE PR_INSERISCI_INTERMEDIARI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                    p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                    p_lista_intermediari  intermediario_list_type);

PROCEDURE PR_INSERISCI_SOGGETTI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                          p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                          p_lista_soggetti  soggetto_list_type);

PROCEDURE PR_ANNULLA_RIPRISTINA_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE, P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, V_FLAG char);


TYPE R_RICHIESTA_FULL IS RECORD
(
  id_piano                        CD_PIANIFICAZIONE.ID_PIANO%TYPE,
  id_ver_piano                    CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
  cod_sede                        CD_PIANIFICAZIONE.COD_SEDE%TYPE,
  cod_area                        CD_PIANIFICAZIONE.COD_AREA%TYPE,
  id_cliente                      CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
  id_responsabile_contatto        CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
  cod_categoria_prodotto          CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
  data_creazione_richiesta        CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
  data_invio_magazzino            CD_PIANIFICAZIONE.DATA_INVIO_MAGAZZINO%TYPE,
  data_trasformazione_in_piano    CD_PIANIFICAZIONE.DATA_TRASFORMAZIONE_IN_PIANO%TYPE,
  flg_annullato                   CD_PIANIFICAZIONE.FLG_ANNULLATO%TYPE,
  flg_sospeso                     CD_PIANIFICAZIONE.FLG_SOSPESO%TYPE,
  utente_invio_richiesta          CD_PIANIFICAZIONE.UTENTE_INVIO_RICHIESTA%TYPE,
  utemod                          CD_PIANIFICAZIONE.UTEMOD%TYPE,
  datamod                         CD_PIANIFICAZIONE.DATAMOD%TYPE,
  id_stato_lav                    CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
  id_target                       CD_PIANIFICAZIONE.ID_TARGET%TYPE,
  --id_soggetto_di_piano            CD_PIANIFICAZIONE.ID_SOGGETTO_DI_PIANO%TYPE,
  id_stato_vendita                CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
  flg_cambio_merce                CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
  flg_sipra_lab                   CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
  netto                           CD_IMPORTI_RICHIESTA.NETTO%TYPE,
  lordo                           CD_IMPORTI_RICHIESTA.LORDO%TYPE,
  perc_sc                         CD_IMPORTI_RICHIESTA.PERC_SC%TYPE,
  desc_area                       AREE.DESCRIZIONE_ESTESA%TYPE,
  desc_sede                       SEDI.DESCRIZIONE_ESTESA%TYPE,
  note                            cd_pianificazione.note%type,
  tipo_contartto                  cD_pianificazione.tipo_contratto%type
);


TYPE R_PIANO_FULL IS RECORD
(
  id_piano                        CD_PIANIFICAZIONE.ID_PIANO%TYPE,
  id_ver_piano                    CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
  cod_sede                        CD_PIANIFICAZIONE.COD_SEDE%TYPE,
  cod_area                        CD_PIANIFICAZIONE.COD_AREA%TYPE,
  id_cliente                      CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
  nome_cliente                    INTERL_U.RAG_SOC_COGN%TYPE,
  id_responsabile_contatto        CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
  nome_responsabile_contatto      INTERL_U.RAG_SOC_COGN%TYPE,
  cod_categoria_prodotto          CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
  data_creazione_richiesta        CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
  data_invio_magazzino            CD_PIANIFICAZIONE.DATA_INVIO_MAGAZZINO%TYPE,
  data_trasformazione_in_piano    CD_PIANIFICAZIONE.DATA_TRASFORMAZIONE_IN_PIANO%TYPE,
  flg_annullato                   CD_PIANIFICAZIONE.FLG_ANNULLATO%TYPE,
  flg_sospeso                     CD_PIANIFICAZIONE.FLG_SOSPESO%TYPE,
  utente_invio_richiesta          CD_PIANIFICAZIONE.UTENTE_INVIO_RICHIESTA%TYPE,
  utemod                          CD_PIANIFICAZIONE.UTEMOD%TYPE,
  datamod                         CD_PIANIFICAZIONE.DATAMOD%TYPE,
  id_stato_lav                    CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
  id_target                       CD_PIANIFICAZIONE.ID_TARGET%TYPE,
  id_stato_vendita                CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
  desc_stato_vendita              CD_STATO_DI_VENDITA.DESCRIZIONE%TYPE,
  flg_cambio_merce                CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
  flg_sipra_lab                   CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
  netto_eff                       CD_IMPORTI_RICHIESTA.NETTO%TYPE,
  lordo_eff                       CD_IMPORTI_RICHIESTA.LORDO%TYPE,
  perc_sc_eff                     CD_IMPORTI_RICHIESTA.PERC_SC%TYPE,
  netto_piano                     CD_IMPORTI_RICHIESTI_PIANO.NETTO%TYPE,
  lordo_piano                     CD_IMPORTI_RICHIESTI_PIANO.LORDO%TYPE,
  perc_sc_piano                   CD_IMPORTI_RICHIESTI_PIANO.PERC_SC%TYPE,
  desc_area                       AREE.DESCRIZIONE_ESTESA%TYPE,
  desc_sede                       SEDI.DESCRIZIONE_ESTESA%TYPE,
  data_prenotazione               CD_PIANIFICAZIONE.DATA_PRENOTAZIONE%TYPE,
  stato_ven_comunicati            CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE,
  cod_testata_editoriale          CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE%TYPE,
  note                            cd_pianificazione.note%type,
  tipo_contratto                  cd_pianificazione.tipo_contratto%type
);


TYPE R_PIANIFICAZIONE IS RECORD
(
    a_id_piano       cd_pianificazione.ID_PIANO%type,
    a_id_ver_piano      cd_pianificazione.ID_VER_PIANO%type,
    a_cod_area           cd_pianificazione.COD_AREA%type,
    a_id_resp_contatto  cd_pianificazione.ID_RESPONSABILE_CONTATTO%type,
    a_id_cliente        cd_pianificazione.ID_CLIENTE%type,
    a_importo_netto  cd_importi_richiesta.NETTO%type,
    a_importo_lordo  cd_importi_richiesta.LORDO%type,
    a_perc_sc               cd_importi_richiesta.PERC_SC%type,
    a_data_creazione varchar2(10),
    a_data_iniz periodi.DATA_INIZ%type,
    a_data_fine periodi.DATA_FINE%type,
    a_id_stato_lav   cd_pianificazione.ID_STATO_LAV%type,
    a_cod_categoria_prodotto    cd_pianificazione.COD_CATEGORIA_PRODOTTO%type
);

TYPE R_SCELTA_INTERMEDIARIO IS RECORD
(
    ID_int  vi_cd_cliente.ID_cliente%type,
    A_RAG_SOC_COGN vi_cd_cliente.RAG_SOC_COGN%type,
    A_INDIRIZZO vi_cd_cliente.INDIRIZZO%type,
    A_LOCALITA vi_cd_cliente.LOCALITA%type,
    A_COD_FISC vi_cd_cliente.COD_FISC%type,
    A_AREA vi_cd_cliente.AREA%type,
    A_SEDE vi_cd_cliente.SEDE%type,
    A_DESC_AREA varchar2(200),
    A_DESC_SEDE varchar2(200),
    dt_iniz_val interl_u.DT_INIZ_VAL%TYPE,
    dt_fine_val interl_u.DT_FINE_VAL%TYPE

);

TYPE R_SCELTA_AREA IS RECORD
(
    A_COD_AREA AREE.COD_AREA%TYPE,
    A_DESCRIZ AREE.DESCRIZ%TYPE,
    A_DES_ABBR AREE.DES_ABBR%TYPE
);


TYPE C_SCELTA_AREA IS REF CURSOR RETURN R_SCELTA_AREA;
TYPE C_RICHIESTA_FULL IS REF CURSOR RETURN R_RICHIESTA_FULL;
TYPE C_PIANO_FULL IS REF CURSOR RETURN R_PIANO_FULL;

TYPE R_RAGGRUPPAMENTO IS RECORD
(
    A_ID_RAGGRUPPAMENTO CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE,
    A_DATA_DECORRENZA CD_RAGGRUPPAMENTO_INTERMEDIARI.DATA_DECORRENZA%TYPE,
    A_ID_AGENZIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
    A_NOME_AGENZIA INTERL_U.RAG_SOC_COGN%TYPE,
    A_ID_CENTRO_MEDIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
    A_NOME_CENTRO_MEDIA INTERL_U.RAG_SOC_COGN%TYPE,
    A_ID_VEN_CLIENTE CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
    A_NOME_VEN_CLIENTE INTERL_U.RAG_SOC_COGN%TYPE,
    A_PROGRESSIVO CD_RAGGRUPPAMENTO_INTERMEDIARI.PROGRESSIVO%TYPE
    --A_ID_VEN_PRODOTTO CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_PRODOTTO%TYPE,
    --A_NOME_VEN_PRODOTTO INTERL_U.RAG_SOC_COGN%TYPE
);

TYPE C_RAGGRUPPAMENTO IS REF CURSOR RETURN R_RAGGRUPPAMENTO;

FUNCTION FU_GET_RICHIESTA_FULL(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_RICHIESTA_FULL;

FUNCTION FU_GET_PIANO_FULL(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PIANO_FULL;


TYPE R_SCELTA_SEDE IS RECORD
(
    A_COD_SEDE SEDI.COD_SEDE%TYPE,
    A_DESCRIZ SEDI.DES_SEDE%TYPE,
    A_DES_ABBR SEDI.DES_ABBR%TYPE,
    A_DES_ESTESA VI_CD_AREE_SEDI_COMPET.DES_SEDE_ESTESA%type
);

TYPE C_SCELTA_SEDE IS REF CURSOR RETURN R_SCELTA_AREA;

TYPE R_SOGGETTO IS RECORD
(
  a_id_soggetto_di_piano CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
  a_int_u_cod_interl soggetti.int_u_cod_interl%type,
  a_descrizione CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
  a_desc_cat_merc nielscat.DES_CAT_MERC%type,
  a_desc_cl_merc nielscl.DES_CL_MERC%type,
  a_cod_sogg soggetti.COD_SOGG%TYPE
);

TYPE C_SOGGETTO IS REF CURSOR RETURN R_SOGGETTO;

TYPE R_SOGGETTO_PROD IS RECORD
(
  a_id_soggetto_di_piano CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
  a_int_u_cod_interl soggetti.int_u_cod_interl%type,
  a_descrizione CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
  a_perc_distribuzione CD_SOGGETTO_DI_PIANO.PERC_DISTRIBUZIONE%TYPE,
  a_desc_cat_merc nielscat.DES_CAT_MERC%type,
  a_desc_cl_merc nielscl.DES_CL_MERC%type
);

TYPE C_SOGGETTO_PROD IS REF CURSOR RETURN R_SOGGETTO_PROD;

TYPE C_INTERMEDIARIO IS REF CURSOR RETURN R_SCELTA_INTERMEDIARIO;

TYPE C_PIANIFICAZIONE IS REF CURSOR RETURN R_PIANIFICAZIONE;

TYPE R_ANNO IS RECORD
(
 a_anno PERIODI.ANNO%TYPE
);

TYPE C_ANNO IS REF CURSOR RETURN R_ANNO;

TYPE R_CICLO IS RECORD
(
 a_ciclo PERIODI.CICLO%TYPE

);

TYPE C_CICLO IS REF CURSOR RETURN R_CICLO;

TYPE R_SETTIMANA IS RECORD
(
 a_settimana PERIODI.PER%TYPE,
 a_mese PERIODI.CICLO%TYPE,
 a_anno PERIODI.ANNO%TYPE,
 a_inizio PERIODI.DATA_INIZ%TYPE,
 a_fine PERIODI.DATA_FINE%TYPE
);

TYPE C_SETTIMANA IS REF CURSOR RETURN R_SETTIMANA;

TYPE R_STATO_LAVORAZIONE IS RECORD
(
 a_id_stato_lav CD_STATO_LAVORAZIONE.ID_STATO_LAV%TYPE,
 a_descrizione CD_STATO_LAVORAZIONE.DESCRIZIONE%TYPE
);

TYPE C_STATO_LAVORAZIONE IS REF CURSOR RETURN R_STATO_LAVORAZIONE;

TYPE R_RESPONSABILE_CONTATTO IS RECORD
(
 a_cod_interl VENDITORI.COD_INTERL%TYPE,
 a_rag_soc VENDITORI.RAGSOC%TYPE,
 a_cod_area VENDGR.GV_AS_AR_COD_AREA%TYPE,
 a_cod_sede VENDGR.GV_AS_SE_COD_SEDE%TYPE,
 a_desc_area AREE.DESCRIZ%TYPE,
 a_desc_sede SEDI.DES_SEDE%TYPE
);

TYPE C_RESPONSABILE_CONTATTO IS REF CURSOR RETURN R_RESPONSABILE_CONTATTO;

TYPE R_TARGET IS RECORD
(
 a_id_target CD_TARGET.ID_TARGET%TYPE,
 a_nome_target CD_TARGET.NOME_TARGET%TYPE,
 a_descr_target CD_TARGET.DESCR_TARGET%TYPE
);

TYPE C_TARGET IS REF CURSOR RETURN R_TARGET;


TYPE R_VENDITORI IS RECORD
(
    A_CLASSEINTERVENTO VI_PC_PORTAFOGLIO_VENDITORI.CLASSEINTERVENTO%TYPE,
    A_CONVENZIONE VI_PC_PORTAFOGLIO_VENDITORI.CONVENZIONE%TYPE,
    A_DES_TIPOINTERVENTO VI_PC_PORTAFOGLIO_VENDITORI.DES_TIPOINTERVENTO%TYPE,
    A_DIRITTOPROVV VI_PC_PORTAFOGLIO_VENDITORI.DIRITTOPROVV%TYPE,
    A_INTERLOCUTORE VI_PC_PORTAFOGLIO_VENDITORI.INTERLOCUTORE%TYPE,
    A_TIPOCOMPORTAMENTO VI_PC_PORTAFOGLIO_VENDITORI.TIPOCOMPORTAMENTO%TYPE,
    A_TIPODIRITTOPROVV VI_PC_PORTAFOGLIO_VENDITORI.TIPODIRITTOPROVV%TYPE,
    A_TIPOINTERLOCUTORE VI_PC_PORTAFOGLIO_VENDITORI.TIPOINTERLOCUTORE%TYPE,
    A_TIPOINTERVENTO VI_PC_PORTAFOGLIO_VENDITORI.TIPOINTERVENTO%TYPE,
    A_VENDITORE VI_PC_PORTAFOGLIO_VENDITORI.VENDITORE%TYPE
);

TYPE R_PERIODO IS RECORD
(
      IDPERIODO     CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE,
      DATAINIZIO    PERIODI.DATA_INIZ%TYPE,
      DATAFINE      PERIODI.DATA_FINE%TYPE,
      ANNO          NUMBER(4),
      CICLO         NUMBER(2),
      PER           VARCHAR2(1 BYTE),
      IMPORTOLORDO   NUMBER,
      IMPORTONETTO   NUMBER,
      PERCSCONTO     NUMBER,
      LORDOEFF      NUMBER,
      NETTOEFF      NUMBER,
      SCONTOEFF     NUMBER,
      NOTA          CD_IMPORTI_RICHIESTA.NOTA%TYPE
);

TYPE C_PERIODO IS REF CURSOR RETURN R_PERIODO;

TYPE R_PERIODO_SPECIALE IS RECORD
(
      ID_PERIODO_PIANO      CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE,
      ID_PERIODO_SPECIALE   CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE,
      DATAINIZIO            CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
      DATAFINE              CD_PERIODO_SPECIALE.DATA_FINE%TYPE,
      IMPORTOLORDO          NUMBER,
      IMPORTONETTO          NUMBER,
      PERCSCONTO            NUMBER,
      LORDOEFF              NUMBER,
      NETTOEFF              NUMBER,
      SCONTOEFF             NUMBER,
      NOTA                  CD_IMPORTI_RICHIESTA.NOTA%TYPE
);

TYPE C_PERIODO_SPECIALE IS REF CURSOR RETURN R_PERIODO_SPECIALE;

TYPE R_PERIODO_ISP IS RECORD
(
      ID_PERIODO_PIANO      CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE,
      ID_PERIODO            CD_PERIODI_CINEMA.ID_PERIODO%TYPE,
      DATAINIZIO            CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
      DATAFINE              CD_PERIODO_SPECIALE.DATA_FINE%TYPE,
      IMPORTOLORDO          NUMBER,
      IMPORTONETTO          NUMBER,
      PERCSCONTO            NUMBER,
      LORDOEFF              NUMBER,
      NETTOEFF              NUMBER,
      SCONTOEFF             NUMBER,
      NOTA                  CD_IMPORTI_RICHIESTA.NOTA%TYPE
);

TYPE C_PERIODO_ISP IS REF CURSOR RETURN R_PERIODO_ISP;

TYPE C_VENDITORI IS REF CURSOR RETURN R_VENDITORI;

type NUM_ARRAY IS VARRAY (100) OF NUMBER;

TYPE R_DATE_PERIODO IS RECORD
(
 a_data_inizio PERIODI.DATA_INIZ%TYPE,
 a_data_fine   PERIODI.DATA_FINE%TYPE
);

TYPE C_DATE_PERIODO IS REF CURSOR RETURN R_DATE_PERIODO;


function  fu_get_intermediario
(
                                    p_det_gest_commerciale        in        varchar2,
                                    p_tipo_contratto              in        varchar2,
                                    p_data_decorrenza             in        date,
                                    p_cliente                     in        varchar2,
                                    p_agenzia                     in        varchar2,
                                    p_centro_media                in        varchar2,
									p_tipo_venditore			  in		varchar2,
                                    p_gest_comm					  in		varchar2
) return  C_VENDITORI;



TYPE R_TIPI_GEST_COMM IS RECORD
(
    id_gest gest_comm.ID%type
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



TYPE C_TIPI_GEST_COMM IS REF CURSOR RETURN R_TIPI_GEST_COMM;

TYPE C_ASSSOGG IS REF CURSOR RETURN R_ASSSOGG;

TYPE R_FORMATI IS RECORD
(
    a_id_formato CD_FORMATI_PIANO.ID_FORMATO%TYPE,
    a_durata CD_COEFF_CINEMA.DURATA%TYPE
);

TYPE C_FORMATI IS REF CURSOR RETURN R_FORMATI;

TYPE R_FRUITORE IS RECORD
(
    a_id_fruitore VI_CD_CLIENTE_FRUITORE.ID_FRUITORE%TYPE,
    a_nome        VI_CD_CLIENTE_FRUITORE.RAG_SOC_COGN%TYPE,
    a_descr_breve VI_CD_CLIENTE_FRUITORE.RAG_SOC_BR_NOME%TYPE,
    a_localita    VI_CD_CLIENTE_FRUITORE.LOCALITA%TYPE,
    a_indirizzo   VI_CD_CLIENTE_FRUITORE.INDIRIZZO%TYPE,
    a_area        aree.DESCRIZIONE_ESTESA%type,
    a_sede        sedi.DESCRIZIONE_ESTESA%type
);

TYPE C_FRUITORE IS REF CURSOR RETURN R_FRUITORE;

TYPE R_FRUITORE_DI_PIANO IS RECORD
(
    a_id_fruitore VI_CD_CLIENTE_FRUITORE.ID_FRUITORE%TYPE,
    a_id_fruitore_di_piano CD_FRUITORI_DI_PIANO.ID_FRUITORI_DI_PIANO%TYPE,
    a_nome        VI_CD_CLIENTE_FRUITORE.RAG_SOC_COGN%TYPE,
    a_desc_breve  VI_CD_CLIENTE_FRUITORE.RAG_SOC_BR_NOME%TYPE,
    a_localita    VI_CD_CLIENTE_FRUITORE.LOCALITA%TYPE,
    a_indirizzo   VI_CD_CLIENTE_FRUITORE.INDIRIZZO%TYPE,
    a_area        aree.DESCRIZIONE_ESTESA%type,
    a_sede        sedi.DESCRIZIONE_ESTESA%type,
    a_data_decorrenza CD_FRUITORI_DI_PIANO.DATA_DECORRENZA%TYPE,
    a_progressivo CD_FRUITORI_DI_PIANO.PROGRESSIVO%TYPE
);

TYPE C_FRUITORE_DI_PIANO IS REF CURSOR RETURN R_FRUITORE_DI_PIANO;

TYPE R_DATA_PER IS RECORD
(
 a_data_inizio PERIODI.DATA_INIZ%TYPE
);

TYPE C_DATA_PER IS REF CURSOR RETURN R_DATA_PER;
--
FUNCTION FU_TEST_1 return number;

function fu_get_gest_comm(P_COD_MEZZO gest_comm.MEZ_COD_MEZZO%type) return C_TIPI_GEST_COMM;


FUNCTION FU_CERCA_RICHIESTA(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 P_ID_CLIENTE CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
--                                 P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                -- P_INVIATA_MAGAZZINO CHAR,
                                 P_ID_STATO_VENDITA CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
                                 P_COD_CATEGORIA_PRODOTTO CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                                 ) RETURN C_PIANIFICAZIONE;


function get_desc_area(p_cod_area aree.cod_area%type) return aree.DESCRIZIONE_ESTESA%type;

function get_desc_cliente(p_id_cliente vi_cd_cliente.ID_CLIENTE%type) return vi_cd_cliente.RAG_SOC_COGN%type;

function get_desc_responsabile(p_id_responsabile_contatto interl_u.cod_interl%type) return vi_cd_cliente.RAG_SOC_COGN%type;

---
--Scelta intermediari

function fu_get_tipo_committente  return C_INTERMEDIARIO;

function get_desc_sedi(p_cod_sede sedi.cod_sede%type) return sedi.DESCRIZIONE_ESTESA%type;


--function fu_get_responsabile_contatto  return C_INTERMEDIARIO;

FUNCTION FU_GET_RESPONSABILE_CONTATTO(P_data_creazione_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE) RETURN C_RESPONSABILE_CONTATTO;

FUNCTION FU_GET_AREA RETURN C_SCELTA_AREA;

FUNCTION FU_GET_SEDE RETURN C_SCELTA_SEDE;

FUNCTION FU_GET_SOGGETTO(p_id_cliente vi_cd_cliente.ID_CLIENTE%type)  RETURN C_SOGGETTO;

FUNCTION FU_GET_SOGGETTO_NON_DEF(p_id_cliente VI_CD_CLIENTE.ID_CLIENTE%type)  RETURN R_SOGGETTO;
FUNCTION FU_GET_CLIENTI(p_filtro_ricerca VI_CD_CLIENTE.RAG_SOC_COGN%TYPE) RETURN C_INTERMEDIARIO;
FUNCTION FU_GET_CLIENTI_RICERCA RETURN C_INTERMEDIARIO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_IMPORTI_RICHIESTA           Inserimento di un importo richiesto nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_IMPORTI_RICHIESTA            Eliminazione di un importo richiesto dal sistema
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_IMPORTI_RICHIESTA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_IMPORTI_RICHIESTA(	p_id_importi_richiesta		IN CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE,
										p_esito			            OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_IMPORTI_RICHIESTA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_IMPORTI_RICHIESTA(   p_id_ver_piano                  CD_IMPORTI_RICHIESTA.ID_VER_PIANO%TYPE,
                                        p_id_piano                      CD_IMPORTI_RICHIESTA.ID_PIANO%TYPE,
                                        p_id_periodo_speciale           CD_IMPORTI_RICHIESTA.ID_PERIODO_SPECIALE%TYPE,
                                        p_id_periodo                    CD_IMPORTI_RICHIESTA.ID_PERIODO%TYPE,
                                        p_lordo                         CD_IMPORTI_RICHIESTA.LORDO%TYPE,
                                        p_netto                         CD_IMPORTI_RICHIESTA.NETTO%TYPE,
                                        p_perc_sc                       CD_IMPORTI_RICHIESTA.PERC_SC%TYPE,
                                        p_anno                          CD_IMPORTI_RICHIESTA.ANNO%TYPE,
    			   			            p_ciclo                         CD_IMPORTI_RICHIESTA.CICLO%TYPE,
    			   			            p_per                           CD_IMPORTI_RICHIESTA.PER%TYPE
    			   			            ) RETURN VARCHAR2;



-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_INSERISCI_IMPORTI_RICHIESTI_PIANO           Inserimento di un importo richiesto piano nel sistema
-- --------------------------------------------------------------------------------------------
-- PROCEDURE
--    PR_ELIMINA_IMPORTI_RICHIESTI_PIANO            Eliminazione di un importo richiesto piano dal sistema
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_IMPORTI_RICHIESTI_PIANO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_IMP_RICH_PIANO(  p_id_ver_piano                  CD_IMPORTI_RICHIESTI_PIANO.ID_VER_PIANO%TYPE,
                                        p_id_piano                      CD_IMPORTI_RICHIESTI_PIANO.ID_PIANO%TYPE,
                                        p_id_periodo_speciale           CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO_SPECIALE%TYPE,
                                        p_id_periodo                    CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO%TYPE,
                                        p_lordo                         CD_IMPORTI_RICHIESTI_PIANO.LORDO%TYPE,
                                        p_netto                         CD_IMPORTI_RICHIESTI_PIANO.NETTO%TYPE,
                                        p_perc_sc                       CD_IMPORTI_RICHIESTI_PIANO.PERC_SC%TYPE,
                                        p_anno                          CD_IMPORTI_RICHIESTI_PIANO.ANNO%TYPE,
							   			p_ciclo                         CD_IMPORTI_RICHIESTI_PIANO.CICLO%TYPE,
							   			p_per                           CD_IMPORTI_RICHIESTI_PIANO.PER%TYPE,
							   			p_esito							OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_IMPORTI_RICHIESTI_PIANO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_IMP_RICH_PIANO(	p_id_importi_richiesti_piano		IN CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE,
										        p_esito			            OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_IMPORTI_RICHIESTI_PIANO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_IMP_RICH_PIANO(  p_id_ver_piano                  CD_IMPORTI_RICHIESTI_PIANO.ID_VER_PIANO%TYPE,
                                    p_id_piano                      CD_IMPORTI_RICHIESTI_PIANO.ID_PIANO%TYPE,
                                    p_id_periodo_speciale           CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO_SPECIALE%TYPE,
                                    p_id_periodo                    CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO%TYPE,
                                    p_lordo                         CD_IMPORTI_RICHIESTI_PIANO.LORDO%TYPE,
                                    p_netto                         CD_IMPORTI_RICHIESTI_PIANO.NETTO%TYPE,
                                    p_perc_sc                       CD_IMPORTI_RICHIESTI_PIANO.PERC_SC%TYPE,
                                    p_anno                          CD_IMPORTI_RICHIESTI_PIANO.ANNO%TYPE,
			   			            p_ciclo                         CD_IMPORTI_RICHIESTI_PIANO.CICLO%TYPE,
			   			            p_per                           CD_IMPORTI_RICHIESTI_PIANO.PER%TYPE
			   			            ) RETURN VARCHAR2;


---CONSENTE IL RIPRISTINO E L'ANNULLAMENTO
PROCEDURE PR_SOSPENDI_RIPRISTINA(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, P_OP VARCHAR2);

--Restituisce gli anni inseriti in PERIODO
FUNCTION FU_GET_ANNI_PERIODO RETURN C_ANNO;

--Restituisce gli anni inseriti in PERIODO
FUNCTION FU_GET_MESI_PERIODO(p_anno PERIODI.ANNO%TYPE) RETURN C_CICLO;

--Restituisce il numero di settimane dato un anno e mese
FUNCTION FU_GET_SETTIMANE_PERIODO(p_anno PERIODI.ANNO%TYPE, p_mese PERIODI.CICLO%TYPE) RETURN C_SETTIMANA;


FUNCTION FU_GET_ANNI_PERIODO_ALL RETURN C_ANNO;

FUNCTION FU_GET_MESI_PERIODO_ALL(p_anno PERIODI.ANNO%TYPE) RETURN C_CICLO;

FUNCTION FU_GET_SETTIMANE_PERIODO_ALL(p_anno PERIODI.ANNO%TYPE, p_mese PERIODI.CICLO%TYPE) RETURN C_SETTIMANA;


--Restituisce il numero di settimane sipra nel periodo indicato
FUNCTION FU_GENERA_SETTIMANE(p_data_inizio PERIODI.DATA_INIZ%TYPE, p_data_fine PERIODI.DATA_FINE%TYPE) RETURN C_SETTIMANA;

--Restituisce gli stati di lavorazione
FUNCTION FU_GET_STATO_LAVORAZIONE(p_stato_pianificazione cd_stato_lavorazione.STATO_PIANIFICAZIONE%TYPE) RETURN C_STATO_LAVORAZIONE;

--Restituisce i target
FUNCTION FU_GET_TARGET RETURN C_TARGET;

FUNCTION FU_CERCA_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_STATO_VENDITA CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE,
                        P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
                        P_DATA_INIZIO PERIODI.DATA_INIZ%TYPE,
                        P_DATA_FINE PERIODI.DATA_FINE%TYPE,
                         P_COD_CATEGORIA_PRODOTTO CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                        ) RETURN  C_PIANIFICAZIONE;

FUNCTION FU_CERCA_PIANO_SOSP(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_ID_STATO_VENDITA CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                        P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE) RETURN  C_PIANIFICAZIONE ;

PROCEDURE PR_INVIA_RICHIESTA(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE, P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE);


PROCEDURE PR_TRASFORMA_IN_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE, P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE);


FUNCTION FU_GET_INTERMEDIARIO_CLIENTE(p_det_gest_commerciale        in        varchar2,
                                    p_tipo_contratto              in        varchar2,
                                    p_data_decorrenza             in        date,
                                    p_cliente                     in        varchar2,
                                    p_agenzia                     in        varchar2,
                                    p_centro_media                in        varchar2,
									p_tipo_venditore			  in		varchar2,
                                    p_gest_comm					  in		varchar2,
                                    p_stringa_ricerca             in        varchar2)
                                    RETURN C_INTERMEDIARIO;

FUNCTION FU_GET_AGENZIE(p_data_decorrenza CACQCOMM.DT_FINE_VAL%TYPE, p_stringa_ricerca VARCHAR2) RETURN C_INTERMEDIARIO;

FUNCTION FU_GET_CENTRI_MEDIA(p_data_decorrenza CACQCOMM.DT_FINE_VAL%TYPE, p_stringa_ricerca VARCHAR2) RETURN C_INTERMEDIARIO;


FUNCTION FU_GET_PERIODI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO;

FUNCTION FU_GET_PERIODI_PIANO_IMPORTI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO;

FUNCTION FU_GET_SOGGETTI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_SOGGETTO;

FUNCTION FU_GET_SOGGETTI_PRODOTTO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_SOGGETTO_PROD;

FUNCTION FU_GET_FORMATI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_FORMATI;

PROCEDURE PR_ULTIMA_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, p_tipo_elaborazione VARCHAR2);

PROCEDURE PR_MODIFICA_IMPORTO_PIANO(P_ID_IMPORTO CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE, P_LORDO CD_IMPORTI_RICHIESTI_PIANO.LORDO%TYPE, P_NETTO CD_IMPORTI_RICHIESTI_PIANO.NETTO%TYPE, P_SCONTO CD_IMPORTI_RICHIESTI_PIANO.PERC_SC%TYPE);

PROCEDURE PR_MODIFICA_IMPORTO_RICHIESTA(P_ID_IMPORTO CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE, P_LORDO CD_IMPORTI_RICHIESTA.LORDO%TYPE, P_NETTO CD_IMPORTI_RICHIESTA.NETTO%TYPE, P_SCONTO CD_IMPORTI_RICHIESTA.PERC_SC%TYPE);

PROCEDURE PR_MODIFICA_STATO_LAVORAZIONE(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE, P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, P_ID_STATO_LAVORAZIONE cd_pianificazione.id_stato_lav%type);

PROCEDURE PR_MODIFICA_PIANO(
                            p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                            p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                            p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                            p_id_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                            p_lista_periodi  periodo_list_type,
                            p_lista_intermediari intermediario_list_type,
                            p_lista_soggetti soggetto_list_type,
                            p_id_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                            p_cod_testata CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE%TYPE,
                            p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                            p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                            p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                            p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                            p_tipo_contratto CD_PIANIFICAZIONE.TIPO_CONTRATTO%TYPE,
                            p_esito OUT NUMBER);

FUNCTION FU_GET_NOME_CLIENTE(p_id_cliente INTERL_U.COD_INTERL%TYPE) RETURN CHAR;

FUNCTION FU_GET_STATO_VEN_COMUNICATI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN VARCHAR;

FUNCTION FU_GET_RAGGRUPPAMENTI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_RAGGRUPPAMENTO;

FUNCTION FU_GET_PERIODI_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO;

FUNCTION FU_GET_PERIODI_SPEC_RIC(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_SPECIALE;

FUNCTION FU_GET_PERIODI_SPEC_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_SPECIALE;

FUNCTION FU_GET_PERIODI_SPEC_PIANO_IMP(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_SPECIALE;

FUNCTION FU_GET_PERIODI_ISP_RIC(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_ISP;

FUNCTION FU_GET_PERIODI_ISP_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_ISP;

FUNCTION FU_GET_PERIODI_ISP_PIANO_IMP(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_ISP;

PROCEDURE PR_SALVA_STATI_VENDITA_PIANO(
                                 p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                 p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                 p_id_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE);

FUNCTION FU_GET_RAGGRUPPAMENTO(p_id_raggruppamento CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE) RETURN C_RAGGRUPPAMENTO;



PROCEDURE PR_SALVA_SOGG_PIANO(p_id_piano CD_SOGGETTO_DI_PIANO.ID_PIANO%TYPE,p_id_ver_piano CD_SOGGETTO_DI_PIANO.ID_VER_PIANO%TYPE,p_cliente CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL%TYPE, p_descrizione CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE, p_cod_sogg CD_SOGGETTO_DI_PIANO.COD_SOGG%TYPE, p_id_soggetto OUT CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE);

PROCEDURE PR_ELIMINA_SOGG_PIANO(p_id_sogg_piano CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE);

PROCEDURE PR_ELIMINA_MAT_PIANO(p_id_mat_piano CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE, p_esito OUT NUMBER);

PROCEDURE PR_ELIMINA_RAGGR_PIANO(p_id_raggr_piano CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE, p_id_piano CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE, p_esito OUT NUMBER);

FUNCTION FU_GET_DESC_SOGGETTO(p_id_soggetto SOGGETTI.COD_SOGG%TYPE) RETURN VARCHAR;

FUNCTION FU_GET_FRUITORI_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE, P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_FRUITORE_DI_PIANO;

FUNCTION FU_GET_FRUITORI_CLIENTE(P_ID_CLIENTE CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, P_DATA_DECORRENZA RAGGRUPPAMENTO_U.DT_INIZ_VAL%TYPE) RETURN C_FRUITORE;

FUNCTION FU_VERIFICA_FRUITORE_CLIENTE(P_ID_CLIENTE CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, P_DATA_DECORRENZA RAGGRUPPAMENTO_U.DT_INIZ_VAL%TYPE) RETURN CD_FRUITORI_DI_PIANO.ID_CLIENTE_FRUITORE%TYPE;

PROCEDURE PR_INSERISCI_FRUITORE_PIANO(p_id_piano CD_FRUITORI_DI_PIANO.ID_PIANO%TYPE,p_id_ver_piano CD_FRUITORI_DI_PIANO.ID_VER_PIANO%TYPE,p_id_fruitore CD_FRUITORI_DI_PIANO.ID_CLIENTE_FRUITORE%TYPE,p_data_decorrenza cd_fruitori_di_piano.data_decorrenza%type);

PROCEDURE PR_ELIMINA_FRUITORE_PIANO(p_id_piano CD_FRUITORI_DI_PIANO.ID_PIANO%TYPE,p_id_ver_piano CD_FRUITORI_DI_PIANO.ID_VER_PIANO%TYPE,p_id_fruitore_di_piano CD_FRUITORI_DI_PIANO.ID_FRUITORI_DI_PIANO%TYPE);

FUNCTION FU_GET_CLIENTE_FRUITORE(p_id_fruitore_di_piano CD_FRUITORI_DI_PIANO.ID_FRUITORI_DI_PIANO%TYPE) RETURN C_FRUITORE_DI_PIANO;

FUNCTION FU_IS_PIANO_CAMBIO_MERCE(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN VARCHAR2;

FUNCTION FU_ESISTE_DIREZIONALE(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN VARCHAR2;

PROCEDURE PR_PIANO_CAMBIO_MERCE(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, p_flg_cambio_merce VARCHAR2);

FUNCTION FU_GET_NUM_PRODOTTI_PROPOSTI(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE, p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_DATE_PERIODI RETURN C_DATE_PERIODO;


FUNCTION FU_GET_SOGGETTO_DI_PIANO(P_ID_SOGGETTO_DI_PIANO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE ) RETURN C_SOGGETTO_PROD;

FUNCTION FU_PERIODI_CONSECUTIVI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                             p_data_inizio DATE, p_data_fine DATE) RETURN NUMBER;

FUNCTION FU_GET_PERIODO_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                          p_data_inizio DATE, p_data_fine DATE) RETURN CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;

FUNCTION FU_GET_PERIODO_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                              p_data_inizio DATE, p_data_fine DATE) RETURN CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE;
                              
FUNCTION FU_NETTO_RICHIESTO(P_ID_IMPORTI_RICHIESTI_PIANO  CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE) RETURN NUMBER;                              

FUNCTION FU_PERC_SC_RICHIESTO(P_ID_IMPORTI_RICHIESTI_PIANO  CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE) RETURN NUMBER;

FUNCTION FU_LORDO_RICHIESTO(P_ID_IMPORTI_RICHIESTI_PIANO  CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_DATA_INIZIO_PER RETURN C_DATA_PER;

FUNCTION FU_GET_DATA_FINE_PER(p_data_inizio PERIODI.DATA_INIZ%TYPE) RETURN C_DATA_PER;

FUNCTION FU_GET_NUM_PRODOTTI_PROP_PRE(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE, p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER;

FUNCTION FU_GET_DATE_PERIODI_E_SPECIALI(P_TIPO_PERIODO VARCHAR2) RETURN C_DATE_PERIODO;

FUNCTION FU_GET_DATE_PRODOTTI_TARGET RETURN C_DATE_PERIODO;

FUNCTION FU_GET_DATE_PRODOTTI_SPECIALI(P_STATO_VENDITA CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE ) RETURN C_DATE_PERIODO;


FUNCTION FU_GET_CLIENTI_TARGET(p_id_target cd_prodotto_vendita.id_target%type,
                               p_id_cliente cd_pianificazione.id_cliente%type, 
                               p_data_inizio cd_prodotto_acquistato.data_inizio%type,
                               p_data_fine cd_prodotto_acquistato.data_fine%type ) RETURN C_INTERMEDIARIO;

/*FUNCTION FU_CERCA_PIANO_NEW(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_STATO_VENDITA CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE,
                        P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
                        P_DATA_INIZIO PERIODI.DATA_INIZ%TYPE,
                        P_DATA_FINE PERIODI.DATA_FINE%TYPE,
                        P_COD_CATEGORIA_PRODOTTO CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                        ) RETURN  C_PIANIFICAZIONE;*/
                        
PROCEDURE PR_INSERISCI_RICHIESTA_2(
                                 p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                                 p_data_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
                                 p_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 p_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                 p_stato_vendita CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 p_cod_categoria_prodotto CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_target CD_PIANIFICAZIONE.ID_TARGET%TYPE,
                                 p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                                 p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                                 --p_lista_periodi  periodo_list_type,
                                 p_lista_intermediari intermediario_list_type,
                                 p_lista_soggetti soggetto_list_type,
                                 p_lista_formati id_list_type,
                                 p_id_piano OUT CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 p_id_ver_piano OUT CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 p_nota cd_pianificazione.NOTE%TYPE,
                                 p_tipo_contratto cd_pianificazione.TIPO_CONTRATTO%type
                                 );                        

END Pa_Cd_Pianificazione; 
/

