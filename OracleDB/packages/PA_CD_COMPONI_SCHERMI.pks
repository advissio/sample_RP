CREATE OR REPLACE PACKAGE VENCD.PA_CD_COMPONI_SCHERMI AS

/******************************************************************************
   NAME:       PA_CD_COMPONI_SCHERMI
   PURPOSE:    raccogliere tutte le sp riguardanti la composizione dei break
               e affini

   REVISIONS:
   Ver        Date        Author             Description
   ---------  ----------  ---------------    ----------------------------------
   1.0        03/12/2009  Abbundo Francesco  Teoresi srl

******************************************************************************/
TYPE R_COMP_SCHERMI IS RECORD
(
    a_numero_sale           NUMBER(4),
	a_numero_comunicati     NUMBER(4),
	a_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
	a_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
	a_proid                 VARCHAR2(1000)
);
TYPE C_COMP_SCHERMI IS REF CURSOR RETURN R_COMP_SCHERMI;
--
TYPE R_COMP_SINGOLO_SCHERMO IS RECORD
(
    a_id_sala               NUMBER(4),
	a_numero_comunicati     NUMBER(4),
	a_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
	a_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
	a_proid                 VARCHAR2(1000),
	a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
	a_nome_sala             CD_SALA.NOME_SALA%TYPE
);
TYPE C_COMP_SINGOLO_SCHERMO IS REF CURSOR RETURN R_COMP_SINGOLO_SCHERMO;

-- --------------------------------------------------------------------------------------------
-- TYPE R_CLIENTE_SOGGETTO
-- --------------------------------------------------------------------------------------------
TYPE R_CLIENTE_SOGGETTO IS RECORD
(
    a_desc_cliente   VI_CD_CLIENTE.RAG_SOC_COGN%TYPE,
	a_desc_soggetto  CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE
);
TYPE C_CLIENTE_SOGGETTO IS REF CURSOR RETURN R_CLIENTE_SOGGETTO;

type R_SALE is record
(
id_sala   CD_SALA.ID_SALA%TYPE,
nome_sala CD_SALA.NOME_SALA%TYPE,
nome      varchar(120)
);

type c_sale IS REF CURSOR RETURN R_SALE;

TYPE R_INFO_PIANO IS RECORD
(
    a_id_piano       CD_PIANIFICAZIONE.ID_PIANO%TYPE,
    a_id_ver_piano   CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
    a_id_cliente     VI_CD_CLIENTE.ID_CLIENTE%TYPE,
    a_rag_soc_cogn   VI_CD_CLIENTE.RAG_SOC_COGN%TYPE,
    a_data_inizio    CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
	a_data_fine      CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
);
TYPE C_INFO_PIANO IS REF CURSOR RETURN R_INFO_PIANO;

TYPE R_DETT_MATERIALI IS RECORD
(
    a_count_comunicati      NUMBER(20),
    a_id_materiale          CD_MATERIALE.ID_MATERIALE%TYPE,
    a_titolo                CD_MATERIALE.TITOLO%TYPE,
	a_descrizione           CD_MATERIALE.DESCRIZIONE%TYPE
);
TYPE C_DETT_MATERIALI IS REF CURSOR RETURN R_DETT_MATERIALI;

TYPE R_DES_MERC IS RECORD
(
    a_des_sett_merc         NIELSETT.DES_SETT_MERC%TYPE,
    a_des_cat_merc          NIELSCAT.DES_CAT_MERC%TYPE,
    a_des_cl_merc           NIELSCL.DES_CL_MERC%TYPE
);
TYPE C_DES_MERC IS REF CURSOR RETURN R_DES_MERC;

TYPE R_INFO_RISCHI_COMUNICATO IS RECORD
(
    a_rischio_target        VARCHAR2(1),
    a_rischio_segui_film    VARCHAR2(1),
    a_rischio_tutela        VARCHAR2(1),
    a_descrizione_target    CD_TARGET.DESCR_TARGET%TYPE,
    a_nome_spettacolo       CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_id_materiale          CD_MATERIALE.ID_MATERIALE%TYPE,
    a_titolo_materiale      CD_MATERIALE.TITOLO%TYPE,
    a_id_cliente            CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
    a_id_materiale_di_piano CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE   
);
TYPE C_INFO_RISCHI_COMUNICATO IS REF CURSOR RETURN R_INFO_RISCHI_COMUNICATO;

TYPE R_INFO_MERCEOLOGIA IS RECORD
(
    a_desc_categ_merc       VENCOM.NIELSCAT.DES_CAT_MERC%TYPE,
    a_desc_classe_merc      VENCOM.NIELSCL.DES_CL_MERC%TYPE   
);
TYPE C_INFO_MERCEOLOGIA IS REF CURSOR RETURN R_INFO_MERCEOLOGIA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_COMP_SCHERMI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_COMP_SCHERMI  (p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                           p_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                           p_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                           p_id_cliente            VI_CD_CLIENTE.ID_CLIENTE%TYPE,
                           p_cod_sogg              PROSOGG.SO_INT_U_COD_INTERL%TYPE,
                           p_stato_di_vendita      CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                           p_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
                           p_id_sala               CD_SALA.ID_SALA%TYPE)
            			 return C_COMP_SCHERMI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_COMP_SINGOLO_SCHERMO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_COMP_SINGOLO_SCHERMO (p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                             p_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                             p_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
							 p_id_cliente            VI_CD_CLIENTE.ID_CLIENTE%TYPE,
            				 p_cod_sogg              PROSOGG.SO_INT_U_COD_INTERL%TYPE,
                             p_stato_di_vendita      CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                             p_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
                             p_id_sala               CD_SALA.ID_SALA%TYPE)
            				 return C_COMP_SINGOLO_SCHERMO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CLIENTE_SOGGETTO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CLIENTE_SOGGETTO(p_id_soggetto_di_piano  CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE)
							return C_CLIENTE_SOGGETTO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSEGNA_POS
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ASSEGNA_POS(p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                         p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                         p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                         p_posizione               CD_COMUNICATO.POSIZIONE%TYPE,
                         p_data_inizio             CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                         p_data_fine               CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
						 p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                         p_id_list_sale            VARCHAR2);
-- --------------------------------------------------------------------------------------------
--  PROCEDURE PR_ASSEGNA_POS_COM
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ASSEGNA_POS_COM(p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE,
                             p_posizione     CD_COMUNICATO.POSIZIONE%TYPE);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_POSIZ_COMUNICATO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_POSIZ_COMUNICATO(p_id_sogg       CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                             p_id_tipo_break CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                             p_durata        CD_COEFF_CINEMA.DURATA%TYPE,
                             p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                             p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
        					 p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                             p_id_list_sale            VARCHAR2) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_MATERIALI_COM_FLAG
-- --------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALI_COM_FLAG(p_id_sogg       CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                               p_id_tipo_break CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                               p_durata        CD_COEFF_CINEMA.DURATA%TYPE,
                               p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
							   p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                               p_id_list_sale  id_list_type) RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_PIANO_COMUNIC
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_PIANO_COMUNIC(p_id_sogg       CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                               p_id_tipo_break CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                               p_durata        CD_COEFF_CINEMA.DURATA%TYPE,
                               p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
							   p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                               p_id_list_sale  id_list_type) RETURN C_INFO_PIANO;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_MATERIALI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETT_MATERIALI(p_id_sogg       CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                           p_id_tipo_break CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                           p_durata        CD_COEFF_CINEMA.DURATA%TYPE,
                           p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                           p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
			               p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                           p_id_list_sale  id_list_type) RETURN C_DETT_MATERIALI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_SALE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_SALE(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, 
                        p_id_cliente VI_CD_CLIENTE.ID_CLIENTE%TYPE,
                        P_PROID VARCHAR2, 
                        P_DATA_INIZIO DATE,
                        P_DATA_FINE DATE, 
                        p_stato_di_vendita VARCHAR2,
                        p_data_inizio_intervallo DATE,
                        p_data_fine_intervallo DATE
                        ) RETURN c_sale;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_POS_PRIVILEGIATA    Restituisce la posizione privilegiata sulla base della posizione di rigore
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_POS_PRIVILEGIATA(p_pos_rigore          CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE)
                                 RETURN VARCHAR2;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_DES_INFO_MERC    Restituisce la descrizione di settore, categoria e classe merceologica di un comunicato
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_DES_INFO_MERC(p_cat_merc    PROSOGG.NL_NT_COD_CAT_MERC%TYPE,
                              p_cl_merc     PROSOGG.NL_COD_CL_MERC%TYPE)
                                 RETURN C_DES_MERC;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_POPOLA_RCS     Popola la tabella di ricerca composizione schermi
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_POPOLA_RCS(    p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                            p_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                            p_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                            p_id_cliente            VI_CD_CLIENTE.ID_CLIENTE%TYPE,
                            p_cod_sogg              PROSOGG.SO_INT_U_COD_INTERL%TYPE,
                            p_stato_di_vendita      CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                            p_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
                            p_id_sala               CD_SALA.ID_SALA%TYPE,
                            p_session_id            CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                            p_vecchiaia             NUMBER,
                            p_esito                 OUT NUMBER
                        );
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_RCS      Restituisce i valori della ricerca composizione schermi effettuata
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RCS(    p_session_id            CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE
                   ) RETURN C_COMP_SCHERMI;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_RCS_SINGOLO      Restituisce i valori della ricerca composizione singolo schermo effettuata
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RCS_SINGOLO(p_session_id        CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE) 
                        RETURN C_COMP_SINGOLO_SCHERMO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_SALE_RCS
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_SALE_RCS(    p_session_id            CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                p_proid                 CD_RICERCA_COMP_SCHERMI.PROID%TYPE
                           ) RETURN C_SALE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_POSIZ_COMUNICATO_II
-- --------------------------------------------------------------------------------------------
FUNCTION FU_POSIZ_COMUNICATO_II(    p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                    p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                    p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                    p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                               
                                    p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                                ) RETURN VARCHAR2;
-- --------------------------------------------------------------------------------------------
-- FU_MATERIALI_COM_FLAG_II
-- --------------------------------------------------------------------------------------------                                
FUNCTION FU_MATERIALI_COM_FLAG_II(  p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                    p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                    p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                    p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                                     
                                    p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                                  ) RETURN INTEGER;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSEGNA_POS_II
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ASSEGNA_POS_II(p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                            p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                            p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                            p_posizione               CD_COMUNICATO.POSIZIONE%TYPE,
                            p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                            p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                              
                            p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                           );  
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_PIANO_COMUNIC_II
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_PIANO_COMUNIC_II(  p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                    p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                    p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                    p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                                     
                                    p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                                  ) RETURN C_INFO_PIANO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_MATERIALI_II
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETT_MATERIALI_II(  p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                                     
                                p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                             ) RETURN C_DETT_MATERIALI;
                             
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CORE_INFO_RISCHI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CORE_INFO_RISCHI(  
                                p_id_prodotto_acquistato        CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_soggetto_di_piano             CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE
                            ) RETURN C_INFO_RISCHI_COMUNICATO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_RISCHI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_RISCHI(  
                                p_id_prodotto_acquistato        CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_soggetto_di_piano             CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE
                            ) RETURN C_INFO_RISCHI_COMUNICATO;                                                                                                                                                                                                                                            
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_MERCEOLOGIA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_MERCEOLOGIA(  
                                p_categ_merc        VENCOM.NIELSCAT.COD_CAT_MERC%TYPE,
                                p_classe_merc       VENCOM.NIELSCL.COD_CL_MERC%TYPE
                            ) RETURN C_INFO_MERCEOLOGIA;                                                                                                                                                                                                                                            
                         
END PA_CD_COMPONI_SCHERMI; 
/

