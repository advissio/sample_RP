CREATE OR REPLACE PACKAGE VENCD.PA_CD_MATERIALE IS
v_stampa_materiale             VARCHAR2(3):='ON';
TYPE R_MAT_DA_ASSOCIARE IS RECORD
(
       A_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
       A_DATA_INIZIO            CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
       A_DATA_FINE              CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
       A_ID_PIANO               CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
       A_ID_VER_PIANO           CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
       A_NOME_CIRCUITO          CD_CIRCUITO.NOME_CIRCUITO%TYPE,
       A_MODALITA_VENDITA       CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE, 
       A_FORMATO                CD_COEFF_CINEMA.DURATA%TYPE, 
       A_STATO_DI_VENDITA       CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
       A_TIPO_BREAK             CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
       A_CLIENTE                interl_u.RAG_SOC_COGN%TYPE
);
TYPE C_MAT_DA_ASSOCIARE IS REF CURSOR RETURN R_MAT_DA_ASSOCIARE ;
TYPE R_MATERIALE IS RECORD
(
    a_id_materiale              CD_MATERIALE.ID_MATERIALE%TYPE,
    a_titolo                    CD_MATERIALE.TITOLO%TYPE,
    a_nome_file                 CD_MATERIALE.NOME_FILE%TYPE,
    a_durata                    CD_MATERIALE.DURATA%TYPE,
    a_desc_cliente              INTERL_U.RAG_SOC_COGN%TYPE,
    a_data_inizio               CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
    a_data_fine                 CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
    a_desc_sogg                 CD_MATERIALE_SOGGETTI.DES_SOGG%type,
    a_avanzamento               NUMBER,
    a_num_cinema_sinc           NUMBER,
    a_num_cinema_non_sinc       NUMBER,
    a_cinema_non_sinc           VARCHAR2(1000),
    a_visto_censura_presente    VARCHAR2(2)
);
TYPE C_MATERIALE IS REF CURSOR RETURN R_MATERIALE;
TYPE R_MATERIALE_ASS IS RECORD
(
    a_id_materiale_di_piano  CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE,
    a_id_materiale           CD_MATERIALE_DI_PIANO.ID_MATERIALE%TYPE,
    a_perc_distribuzione     CD_MATERIALE_DI_PIANO.PERC_DISTRIBUZIONE%TYPE,
    a_titolo                 CD_MATERIALE.TITOLO%TYPE,
    a_cod_interl             SOGGETTI.INT_U_COD_INTERL%TYPE,
    a_des_sogg               SOGGETTI.DES_SOGG%TYPE,
    a_cod_sogg               CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE,
    a_flg_approvazione       CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
    a_durata                 CD_MATERIALE.DURATA%TYPE,
    a_nome_file              CD_MATERIALE.NOME_FILE%TYPE
);
TYPE C_MATERIALE_ASS IS REF CURSOR RETURN R_MATERIALE_ASS;
TYPE R_DETTAGLIO_MATERIALE IS RECORD
(
    a_id_materiale          CD_MATERIALE.ID_MATERIALE%TYPE,
    a_descrizione           CD_MATERIALE.DESCRIZIONE%TYPE,
    a_nome_file             CD_MATERIALE.NOME_FILE%TYPE,
    a_url_bassa_ris         CD_MATERIALE.URL_BASSA_RISOLUZIONE%TYPE,
    a_titolo                CD_MATERIALE.TITOLO%TYPE,
    a_durata                CD_MATERIALE.DURATA%TYPE,
    a_flg_multiprodotto     CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE,
    a_id_cliente            CD_MATERIALE.ID_CLIENTE%TYPE,
    a_agengia_produz        CD_MATERIALE.AGENZIA_PRODUZ%TYPE,
    a_flg_siae              CD_MATERIALE.FLG_SIAE%TYPE,
    a_id_colonna_sonora     CD_MATERIALE.ID_COLONNA_SONORA%TYPE,
    a_data_inizio_vaidita   CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
    a_data_fine_validita    CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
    a_data_inserimento      CD_MATERIALE.DATA_INSERIMENTO%TYPE,
    a_traduzione_titolo     CD_MATERIALE.TRADUZIONE_TITOLO%TYPE,
    a_id_codifica           CD_MATERIALE.ID_CODIFICA%TYPE,
    a_desc_cliente          INTERL_U.RAG_SOC_COGN%TYPE,
    a_desc_codifica         CD_ANAG_CODIFICHE.DESCRIZIONE%TYPE,
    a_desc_colonna          CD_COLONNA_SONORA.TITOLO%TYPE,
    a_nazionalita           CD_MATERIALE.NAZIONALITA%TYPE,
    a_causale               CD_MATERIALE.CAUSALE%TYPE,
    a_flg_approvazione      CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
    a_flg_protetto          CD_MATERIALE.FLG_PROTETTO%TYPE,
    a_id_visto_censura      CD_VISTO_CENSURA.ID_VISTO_CENSURA%TYPE,
    a_numero_protocollo     CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO%TYPE,
    a_data_protocollo       CD_MATERIALE.DATA_RIL_NULLAOSTA_MINISTERO%TYPE
);
TYPE C_DETTAGLIO_MATERIALE IS REF CURSOR RETURN R_DETTAGLIO_MATERIALE;
TYPE R_CODIFICHE IS RECORD
(
    a_id_codifica          CD_ANAG_CODIFICHE.ID_CODIFICA%TYPE,
    a_descrizione          CD_ANAG_CODIFICHE.DESCRIZIONE%TYPE,
    a_id_nome              CD_ANAG_CODIFICHE.NOME%TYPE
);
TYPE C_CODIFICHE IS REF CURSOR RETURN R_CODIFICHE;
TYPE R_COLONNA_SONORA IS RECORD
(
    a_id_colonna           CD_COLONNA_SONORA.ID_COLONNA_SONORA%TYPE,
    a_titolo               CD_COLONNA_SONORA.TITOLO%TYPE,
    a_autore               CD_COLONNA_SONORA.AUTORE%TYPE,
    a_nota                 CD_COLONNA_SONORA.NOTA%TYPE
);
TYPE C_COLONNA_SONORA IS REF CURSOR RETURN R_COLONNA_SONORA;
TYPE R_SOGGETTO_MATERIALE IS RECORD
(
    a_id_materiale_soggetti   CD_MATERIALE_SOGGETTI.ID_MATERIALE_SOGGETTI%TYPE,
    a_id_materiale            CD_MATERIALE_SOGGETTI.ID_MATERIALE%TYPE,
    a_data_inizio             CD_MATERIALE_SOGGETTI.DATA_INIZIO_VALIDITA%TYPE,
    a_data_fine               CD_MATERIALE_SOGGETTI.DATA_FINE_VALIDITA%TYPE,
    a_cod_sogg                CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE,
    a_des_sogg                SOGGETTI.DES_SOGG%TYPE
);
TYPE C_SOGGETTO_MATERIALE IS REF CURSOR RETURN R_SOGGETTO_MATERIALE;

TYPE R_PROCURA IS RECORD
(
    a_id_procura                    CD_PROCURA.ID_PROCURA%TYPE,
    a_nome                          CD_PROCURA.NOME%TYPE,
    a_cognome                       CD_PROCURA.COGNOME%TYPE,
    a_data_inizio_val               CD_PROCURA.DATA_INIZIO_VAL%TYPE,
    a_data_fine_val                 CD_PROCURA.DATA_FINE_VAL%TYPE,
    a_num_ci                        CD_PROCURA.NUM_CI%TYPE,
    a_comune_ci                     CD_PROCURA.COMUNE_CI%TYPE,
    a_data_rilascio_ci              CD_PROCURA.DATA_RILASCIO_CI%TYPE,
    a_data_ril_nullaosta_ministero  CD_MATERIALE.DATA_RIL_NULLAOSTA_MINISTERO%TYPE,
    a_numero_protocollo_ministero   CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO%TYPE,
    a_titolo                        CD_MATERIALE.TITOLO%TYPE    
);
TYPE C_PROCURA IS REF CURSOR RETURN R_PROCURA;
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei
--              materiali
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Antonio Colucci, Teoresi srl, Dicembre 2009
--            Implementazione procedure di gestione dei materiali
--              - Dettaglio Materiale
--              - Ricerca Materiale
--              - Inserimento Materiale
--              - Modifica Materiale
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_MATERIALE
-- --------------------------------------------------------------------------------------------
-- Inserimento di un nuovo materiale nel sistema
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_MATERIALE(p_descrizione              CD_MATERIALE.DESCRIZIONE%TYPE,
							     p_id_codifica              CD_MATERIALE.ID_CODIFICA%TYPE,
                                 p_id_colonna_sonora        CD_MATERIALE.ID_COLONNA_SONORA%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_url_bassa_risoluzione    CD_MATERIALE.URL_BASSA_RISOLUZIONE%TYPE,
                                 p_durata                   CD_MATERIALE.DURATA%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
							     p_agenzia_prod             CD_MATERIALE.AGENZIA_PRODUZ%TYPE,
                                 p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_flg_siae                 CD_MATERIALE.FLG_SIAE%TYPE,
                                 p_data_inizio_validita     CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine_validita       CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_traduzione_titolo        CD_MATERIALE.TRADUZIONE_TITOLO%TYPE,
                                 p_cod_soggetto             SOGGETTI.COD_SOGG%TYPE,
                                 p_nazionalita              CD_MATERIALE.NAZIONALITA%TYPE,
                                 p_causale                  CD_MATERIALE.CAUSALE%TYPE,
                                 p_flg_approvazione         CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
                                 p_flg_protetto             CD_MATERIALE.FLG_PROTETTO%TYPE,
                                 p_esito					OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_MATERIALE
-- --------------------------------------------------------------------------------------------
-- Modifica di un materiale nel sistema
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_MATERIALE( p_id_materiale             CD_MATERIALE.ID_MATERIALE%TYPE,
                                 p_descrizione              CD_MATERIALE.DESCRIZIONE%TYPE,
							     p_id_codifica              CD_MATERIALE.ID_CODIFICA%TYPE,
                                 p_id_colonna_sonora        CD_MATERIALE.ID_COLONNA_SONORA%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_url_bassa_risoluzione    CD_MATERIALE.URL_BASSA_RISOLUZIONE%TYPE,
                                 p_durata                   CD_MATERIALE.DURATA%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
							     p_agenzia_prod             CD_MATERIALE.AGENZIA_PRODUZ%TYPE,
                                 p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_flg_siae                 CD_MATERIALE.FLG_SIAE%TYPE,
                                 p_data_inizio_validita     CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine_validita       CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_traduzione_titolo        CD_MATERIALE.TRADUZIONE_TITOLO%TYPE,
                                 p_nazionalita              CD_MATERIALE.NAZIONALITA%TYPE,
                                 p_cod_sogg                 CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE,
                                 p_causale                  CD_MATERIALE.CAUSALE%TYPE,
                                 p_flg_approvazione         CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
                                 p_flg_protetto             CD_MATERIALE.FLG_PROTETTO%TYPE,
                                 p_esito					OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_MATERIALE
-- Procedura di Eliminazione di un materiale
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_MATERIALE(	p_id_materiale		IN CD_MATERIALE.ID_MATERIALE%TYPE,
								p_esito			    OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_COLONNA
-- --------------------------------------------------------------------------------------------
-- Inserimento di un nuova colonna sonora
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_COLONNA(  p_titolo                   CD_COLONNA_SONORA.TITOLO%TYPE,
                                 p_autore                   CD_COLONNA_SONORA.AUTORE%TYPE,
                                 p_nota                     CD_COLONNA_SONORA.NOTA%TYPE,
                                 p_esito					OUT NUMBER);
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_MATERIALE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_MATERIALE(   p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_data_inizio              CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine                CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
                                 p_id_materiale             CD_MATERIALE.ID_MATERIALE%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE,
                                 p_flg_approvazione         CD_MATERIALE.FLG_APPROVAZIONE%TYPE,
                                 p_flg_protetto             CD_MATERIALE.FLG_PROTETTO%TYPE,
                                 p_num_protocollo           CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO%TYPE,
                                 p_visto_cerca              VARCHAR2)
                                 RETURN C_MATERIALE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_COLONNA_SONORA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_COLONNA_SONORA(p_titolo              CD_COLONNA_SONORA.TITOLO%TYPE,
                                   p_autore              CD_COLONNA_SONORA.AUTORE%TYPE)
                                   RETURN C_COLONNA_SONORA;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_MODIFICA_COLONNA_SONORA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_COLONNA_SONORA(p_id_colonna_sonora   CD_COLONNA_SONORA.ID_COLONNA_SONORA%TYPE,
                                     p_titolo              CD_COLONNA_SONORA.TITOLO%TYPE,
                                     p_autore              CD_COLONNA_SONORA.AUTORE%TYPE,
                                     p_nota                CD_COLONNA_SONORA.NOTA%TYPE,
							         p_esito		        OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_ELIMINA_COLONNA_SONORA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_COLONNA_SONORA(p_id_colonna_sonora   CD_COLONNA_SONORA.ID_COLONNA_SONORA%TYPE,
							        p_esito		        OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_CODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_CODIFICHE RETURN C_CODIFICHE;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_MATERIALE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_MATERIALE(   p_id_materiale             CD_MATERIALE.ID_MATERIALE%TYPE)
                                 RETURN C_DETTAGLIO_MATERIALE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_MATERIALE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_MATERIALE(    p_titolo                   CD_MATERIALE.TITOLO%TYPE,
                                 p_nome_file                CD_MATERIALE.NOME_FILE%TYPE,
                                 p_data_inizio              CD_MATERIALE.DATA_INIZIO_VALIDITA%TYPE,
                                 p_data_fine                CD_MATERIALE.DATA_FINE_VALIDITA%TYPE,
                                 p_id_cliente               CD_MATERIALE.ID_CLIENTE%TYPE,
                                 p_flg_multiprodotto        CD_MATERIALE.FLG_MULTIPRODOTTO%TYPE)  RETURN VARCHAR2;
FUNCTION FU_GET_MATERIALI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_MATERIALE_ASS;
FUNCTION FU_GET_MATERIALI(p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE,
                          p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                          p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN C_MATERIALE_ASS;
PROCEDURE PR_SALVA_MAT_PIANO(p_id_materiale CD_MATERIALE_DI_PIANO.ID_MATERIALE%TYPE,
                             p_id_piano CD_MATERIALE_DI_PIANO.ID_PIANO%TYPE,
                             p_id_ver_piano CD_MATERIALE_DI_PIANO.ID_VER_PIANO%TYPE,
                             p_id_mat_piano OUT CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE);
--
FUNCTION FU_GET_SOGGETTO_MATERIALE(p_id_materiale CD_MATERIALE_SOGGETTI.ID_MATERIALE%TYPE) RETURN C_SOGGETTO_MATERIALE;
FUNCTION FU_GET_MATERIALI_SOGGETTO(p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE) RETURN C_MATERIALE;

---------------------------------------------------------------------------------------------
-- DESCRIZIONE  Funzione che restituisce l'elenco delle procure dove il flag annullato e uguale a 'N' 
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 17 Novembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROCURE_VALIDE 
RETURN C_PROCURA;
---------------------------------------------------------------------------------------------
-- DESCRIZIONE  Procedura che inserisce un nuovo visto censura. Il blob che conterra il pdf del visto
--              sara un a EMPTY_BLOB() che verra aggiornato dal sistema tramite la classe BLOBManager 
--
-- REALIZZATORE Tommaso D'Anna, Teoresi srl, 17 Novembre 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_VISTO_CENSURA(   p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE, 
                                        p_id_procura CD_PROCURA.ID_PROCURA%TYPE, 
                                        p_esito OUT NUMBER);
---------------------------------------------------------------------------------------------
-- DESCRIZIONE  Procedura che modifica un visto censura esistente con un nuovo valore di procura. 
--
-- REALIZZATORE Tommaso D'Anna, Teoresi srl, 17 Novembre 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_VISTO_CENSURA(    p_id_materiale CD_VISTO_CENSURA.ID_MATERIALE%TYPE, 
                                        p_id_procura CD_VISTO_CENSURA.ID_PROCURA%TYPE, 
                                        p_esito OUT NUMBER);
---------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo procedura restituisce l'elenco dei prodotti che non hanno ancora un materiale associato nel periodo indicato 
-- per lo stato di vendita indicato 
--             
--
-- REALIZZATORE  Mauro Viel Altran Italia Luglio 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_PRODOTTI_SENZA_MATER(P_DATA_INIZIO            CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                        P_DATA_FINE              CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                        P_STATO_DI_VENDITA       CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE
                                        ) 
                                        RETURN C_MAT_DA_ASSOCIARE;
---------------------------------------------------------------------------------------------
-- DESCRIZIONE  Funzione che permette di ottenere le informazioni di anagrafica della procura
--              legata al visto censura in osservazione e identificato dall' id 
--             
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Novembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_PROCURA(P_ID_VISTO_CENSURA       CD_VISTO_CENSURA.ID_VISTO_CENSURA%TYPE) 
                              RETURN C_PROCURA;
FUNCTION FU_GET_FIRMA_VALIDA RETURN BLOB; 
FUNCTION FU_GET_FIRMA_DICH_SOST(p_id_procura CD_PROCURA.ID_PROCURA%TYPE) 
                             RETURN BLOB;                                                    
PROCEDURE PR_AUTORIZZA_MATERIALE( p_id_materiale IN CD_MATERIALE.ID_MATERIALE%TYPE,p_data_autorizzazione date,
							    p_esito OUT NUMBER);
PROCEDURE PR_CONSEGNA_MAT_MINISTERO(p_id_materiale IN CD_MATERIALE.ID_MATERIALE%TYPE,
                                    p_data_consegna CD_MATERIALE.DATA_CONSEGNA_MINISTERO%TYPE,
							        p_esito OUT NUMBER);
PROCEDURE PR_RILASCIO_NULLA_OSTA(p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE,
                                 p_data_ril_nulla_osta CD_MATERIALE.DATA_RIL_NULLAOSTA_MINISTERO%TYPE,
                                 p_protocollo CD_MATERIALE.NUMERO_PROTOCOLLO_MINISTERO%TYPE,
							     p_esito OUT NUMBER);
--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_MATERIALE_SOTTO_TUTELA
--
-- DESCRIZIONE: 
--      Funzione che recupera un flag 'S' o 'N' indicante se il materiale e' sotto tutela o no
--
--
-- REALIZZATORE:
--      Tommaso D'Anna, Teoresi s.r.l., 23 Maggio 2011              
--              
-- --------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALE_SOTTO_TUTELA(p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE) RETURN VARCHAR;
--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_MATERIALI_SOTTO_TUTELA
--
-- DESCRIZIONE: 
--      Funzione che recupera un flag 'S' o 'N' indicante se almeno un materiale di quelli 
--      inseriti e' sotto tutela
--
--      Usato con una stringa del tipo MMATERIALE_1MMMATERIALE_2MMMATERIALE_3M
--
--
-- REALIZZATORE:
--      Tommaso D'Anna, Teoresi s.r.l., 25 Maggio 2011              
--              
-- --------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALI_SOTTO_TUTELA(p_stringa_materiali VARCHAR) RETURN VARCHAR;
END PA_CD_MATERIALE; 
/

