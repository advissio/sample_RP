CREATE OR REPLACE PACKAGE VENCD.PA_CD_ESERCENTE IS


TYPE R_ESERCENTE IS RECORD
(
   a_cod_esercente     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
   a_rag_soc           VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE%TYPE,
   a_part_iva          VI_CD_SOCIETA_ESERCENTE.PART_IVA%TYPE,
   a_comune            VI_CD_SOCIETA_ESERCENTE.COMUNE%TYPE,
   a_provincia         VI_CD_SOCIETA_ESERCENTE.PROVINCIA%TYPE,
   a_indirizzo         VI_CD_SOCIETA_ESERCENTE.INDIRIZZO%TYPE,
   a_data_inizio       VI_CD_SOCIETA_ESERCENTE.DATA_INIZIO_VALIDITA%TYPE,
   a_data_fine         VI_CD_SOCIETA_ESERCENTE.DATA_FINE_VALIDITA%TYPE,
   a_rappr_legali      VARCHAR2(1024)    
);
TYPE C_ESERCENTE IS REF CURSOR RETURN R_ESERCENTE;

TYPE R_ESER_CONTRATTO IS RECORD
(
   a_id_contratto      CD_ESER_CONTRATTO.ID_CONTRATTO%TYPE,
   a_cod_esercente     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
   a_rag_soc           VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE%TYPE,
   a_part_iva          VI_CD_SOCIETA_ESERCENTE.PART_IVA%TYPE,
   a_data_inizio       DATE,
   a_data_fine         DATE    
);
TYPE C_ESER_CONTRATTO IS REF CURSOR RETURN R_ESER_CONTRATTO;

--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista

TYPE R_ESERCENTE_GRUPPI IS RECORD
(
   --a_id_gruppo              CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
   --a_nome_gruppo            CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
   --a_data_inizio_val        CD_SOCIETA_GRUPPO.DATA_INIZIO_VAL%TYPE,
   --a_data_fine_val          CD_SOCIETA_GRUPPO.DATA_FINE_VAL%TYPE     
   a_id_gruppo              VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
   a_nome_gruppo            VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
   a_data_inizio_val        VI_CD_SOCIETA_GRUPPO.DATA_INIZIO_VAL%TYPE,
   a_data_fine_val          VI_CD_SOCIETA_GRUPPO.DATA_FINE_VAL%TYPE
);
TYPE C_ESERCENTE_GRUPPI IS REF CURSOR RETURN R_ESERCENTE_GRUPPI;

TYPE R_CONTRATTO IS RECORD
(
   a_id_contratto           CD_CONTRATTO.ID_CONTRATTO%TYPE,
   a_cod_esercente          VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
   a_ragione_sociale        VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE%TYPE,
   a_data_inizio            CD_CONTRATTO.DATA_INIZIO%TYPE,
   a_data_fine              CD_CONTRATTO.DATA_FINE%TYPE,
   a_data_risoluzione       CD_CONTRATTO.DATA_RISOLUZIONE%TYPE,
   a_flg_arena              CD_CONTRATTO.FLG_ARENA%TYPE
);

TYPE C_CONTRATTO IS REF CURSOR RETURN R_CONTRATTO;

TYPE R_CONDIZIONE_CONTRATTO IS RECORD
(
   a_id_contratto           CD_CONTRATTO.ID_CONTRATTO%TYPE,
   a_id_cinema_contratto    CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE,
   a_id_perc_ripartizione   CD_PERCENTUALE_RIPARTIZIONE.ID_PERC_RIPARTIZIONE%TYPE,
   a_data_inizio            CD_CONTRATTO.DATA_INIZIO%TYPE,
   a_data_fine              CD_CONTRATTO.DATA_FINE%TYPE,
   a_categoria_prodotto     CD_PERCENTUALE_RIPARTIZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
   a_perc_ripartizione      CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE,
   a_desc_cat_prod          PC_CATEGORIA_PRODOTTO.DESCRIZIONE%TYPE,
   a_id_cinema              CD_CINEMA.ID_CINEMA%TYPE,
   a_nome_cinema            CD_CINEMA.NOME_CINEMA%TYPE,
   a_comune_cinema          CD_COMUNE.COMUNE%TYPE,
   a_giorno_chiusura        CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE,
   a_ferie_estive           CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE%TYPE,
   a_flag_ripartizione      CD_CINEMA_CONTRATTO.FLG_RIPARTIZIONE%TYPE,
   a_data_pagamento_fattura CD_CINEMA_CONTRATTO.DATA_PAGAMENTO_FATTURA%TYPE,
   a_quota_fissa            CD_CINEMA_CONTRATTO.IMPORTO%TYPE
  -- a_ferie_extra            CD_CONDIZIONE_CONTRATTO.NUM_FERIE_EXTRA%TYPE
);

TYPE C_CONDIZIONE_CONTRATTO IS REF CURSOR RETURN R_CONDIZIONE_CONTRATTO;

--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista

TYPE R_ESERCENTE_CINEMA IS RECORD
(
   a_id_cinema              CD_CINEMA.ID_CINEMA%TYPE,
   a_nome_cinema            CD_CINEMA.NOME_CINEMA%TYPE,
   a_comune                 CD_COMUNE.COMUNE%TYPE,
   a_data_inizio            VI_CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
   a_data_fine              VI_CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE
   --a_data_inizio           CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
   --a_data_fine             CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE   
);
TYPE C_ESERCENTE_CINEMA IS REF CURSOR RETURN R_ESERCENTE_CINEMA;

--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista

TYPE R_GRUPPO IS RECORD
(
   a_id_gruppo             VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
   a_nome_gruppo           VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
   a_data_inizio           VI_CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
   a_data_fine             VI_CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE
   
   /*a_id_gruppo             CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
   a_nome_gruppo           CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
   a_data_inizio           CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
   a_data_fine             CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE */  
   
   
);
TYPE C_GRUPPO IS REF CURSOR RETURN R_GRUPPO;

TYPE R_QUOTA_ESERCENTE IS RECORD
(
   a_cod_esercente         VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
   a_nome_esercente        VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE%TYPE,
   a_quota_esercente       CD_QUOTA_ESERCENTE.QUOTA_ESERCENTE%TYPE,
   a_stato                 CD_QUOTA_ESERCENTE.STATO_LAVORAZIONE%TYPE,
   a_nome_gruppo           VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
   a_gg_san_rit_part       CD_QUOTA_ESERCENTE.GG_SAN_RIT_PART%TYPE,
--   a_gg_ferie_conteggiate  CD_QUOTA_ESERCENTE.GG_FERIE_CONTEGGIATE%TYPE,
   a_gg_chiusura_conc      CD_QUOTA_ESERCENTE.GG_CHIUSURA_CONC%TYPE,
   a_quota_tab             cd_quota_tab.RICAVO_TAB%type,
   a_quota_isp             cd_quota_isp.RICAVO_ISP%type
);
TYPE C_QUOTA_ESERCENTE IS REF CURSOR RETURN R_QUOTA_ESERCENTE;

TYPE R_LIQUIDAZIONE IS RECORD
(
   a_id_liquidazione       CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE,
   a_fatturato             CD_LIQUIDAZIONE.RICAVO_NETTO%TYPE,
   a_spettatori            CD_LIQUIDAZIONE.SPETTATORI_EFF%TYPE,
   a_fatt_spett            CD_LIQUIDAZIONE.RICAVO_NETTO%TYPE,
   a_stato                 CD_LIQUIDAZIONE.STATO_LAVORAZIONE%TYPE
);
TYPE C_LIQUIDAZIONE IS REF CURSOR RETURN R_LIQUIDAZIONE;

TYPE R_CINEMA_CONTRATTO IS RECORD
(
   a_id_cinema_contratto    CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE,
   a_id_cinema              CD_CINEMA.ID_CINEMA%TYPE,
   a_nome_cinema            CD_CINEMA.NOME_CINEMA%TYPE,
   a_comune_cinema          CD_COMUNE.COMUNE%TYPE,
   a_giorno_chiusura        CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE,
   a_ferie_estive           CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE%TYPE
   --a_ferie_extra            CD_CONDIZIONE_CONTRATTO.NUM_FERIE_EXTRA%TYPE
);

TYPE C_CINEMA_CONTRATTO IS REF CURSOR RETURN R_CINEMA_CONTRATTO;

TYPE R_DETT_QUOTA_ESERCENTE_TAB IS RECORD
(
   a_id_sala            CD_SALA.ID_SALA%TYPE,
   a_nome_sala          CD_SALA.NOME_SALA%TYPE,
   a_nome_cinema        CD_CINEMA.NOME_CINEMA%TYPE,
   a_comune             CD_COMUNE.COMUNE%TYPE,
   a_num_spettatori     CD_QUOTA_TAB.NUM_SPETTATORI%TYPE,
   a_ricavo_tab         CD_QUOTA_TAB.RICAVO_TAB%TYPE,
   a_num_giorni_decur   CD_QUOTA_TAB.NUM_GIORNI_DECUR%TYPE,
   a_perc_ripartizione  CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE,
   a_fatturato          CD_QUOTA_TAB.IMP_FATTURATO%TYPE,
   a_pre_decurtazione   CD_QUOTA_TAB.QTA_PRE_DECURTAZIONE%TYPE,
   a_imp_decurtazione   CD_QUOTA_TAB.IMP_DECURTAZIONE%TYPE,
   a_mancata_proiezione CD_QUOTA_TAB.GG_MANCATA_PROIEZIONE%TYPE,
   a_gg_sanatoria       CD_QUOTA_TAB.GG_SANATORIA%TYPE,
   a_id_liquidazione    CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE,
   a_importo_sanatoria  CD_QUOTA_TAB.IMP_SANATORIA%TYPE
);
TYPE C_DETT_QUOTA_ESERCENTE_TAB IS REF CURSOR RETURN R_DETT_QUOTA_ESERCENTE_TAB;



TYPE R_DETT_QUOTA_ESERCENTE_ISP IS RECORD
(
   a_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
   a_nome_cinema        CD_CINEMA.NOME_CINEMA%TYPE,
   a_comune             CD_COMUNE.COMUNE%TYPE,
   a_ricavo_ISP         CD_QUOTA_ISP.RICAVO_ISP%TYPE,
   a_perc_ripartizione  CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE,
   a_fatturato          CD_QUOTA_ISP.IMP_FATTURATO%TYPE
);
TYPE C_DETT_QUOTA_ESERCENTE_ISP IS REF CURSOR RETURN R_DETT_QUOTA_ESERCENTE_ISP;



-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CERCA_ESERCENTE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_ESERCENTE(p_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
                            p_rag_soc           VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE%TYPE,
                            p_comune            VI_CD_SOCIETA_ESERCENTE.COMUNE%TYPE)
                            RETURN C_ESERCENTE;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTE_GRUPPI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESERCENTE_GRUPPI(p_cod_esercente   VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE)
                             RETURN C_ESERCENTE_GRUPPI;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTE_CONTRATTI
-- --------------------------------------------------------------------------------------------
--FUNCTION FU_ESERCENTE_CONTRATTI(p_cod_esercente   VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE)
--                             RETURN C_ESERCENTE_CONTRATTI;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTE_CINEMA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESERCENTE_CINEMA(p_cod_esercente   VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE)
                             RETURN C_ESERCENTE_CINEMA;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTI_GRUPPO
----Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESERCENTI_GRUPPO(p_id_gruppo        VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                            p_inclusione        NUMBER)
                            RETURN C_ESERCENTE;
                            
--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista
                            
FUNCTION FU_CERCA_GRUPPI(p_nome              VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
                         p_data_inizio       VI_CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
                         p_data_fine         VI_CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE) RETURN C_GRUPPO;

--MODIFICHE: Mauro Viel Altran  la procedura  con l'utilizzo della vista vi_cd_gruppo_esercente non e piu utilizzata          
                 

/*PROCEDURE PR_ASSOCIA_ESERCENTE_GRUPPO(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_gruppo CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE%TYPE,
                                      p_esito OUT NUMBER);*/
  
--MODIFICHE: Mauro Viel Altran  la procedura  con l'utilizzo della vista vi_cd_gruppo_esercente non e piu utilizzata                                      
                                      
/*PROCEDURE PR_ELIMINA_ESERCENTE_GRUPPO(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_gruppo CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE%TYPE,
                                      p_esito OUT NUMBER);    */
--MODIFICHE: Mauro Viel Altran  la procedura  con l'utilizzo della vista vi_cd_gruppo_esercente non e piu utilizzata                                    

/*PROCEDURE PR_SALVA_GRUPPO_ESERCENTE(p_nome              CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
                          p_data_inizio       CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
                          p_data_fine         CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE,
                          p_esito OUT NUMBER);  */                              

FUNCTION FU_CINEMA_ESERCENTE(p_cod_esercente    VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            p_inclusione        NUMBER)
                            RETURN C_ESERCENTE_CINEMA;
                            
/*PROCEDURE PR_ASSOCIA_ESERCENTE_CINEMA(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_cinema CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE%TYPE,
                                      p_esito OUT NUMBER);
                                      
PROCEDURE PR_ELIMINA_ESERCENTE_CINEMA(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_cinema CD_CINEMA.ID_CINEMA%TYPE,
                                      p_esito OUT NUMBER); 
                                                                      
*/

--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista

FUNCTION FU_CERCA_GRUPPI_ESERCENTE(p_cod_esercente VI_CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE) RETURN C_GRUPPO;

FUNCTION FU_CONTRATTI_ESERCENTE(p_cod_esercente CD_ESER_CONTRATTO.COD_ESERCENTE%TYPE,
                                p_id_cinema CD_CINEMA.ID_CINEMA%TYPE) RETURN C_CONTRATTO;
FUNCTION FU_ESERCENTI_CONTRATTO(p_id_contratto   cd_contratto.id_contratto%TYPE) RETURN C_ESER_CONTRATTO;                                

PROCEDURE PR_INSERISCI_CONTRATTO(p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                 p_data_inizio CD_CONTRATTO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_CONTRATTO.DATA_FINE%TYPE,
                                 p_flg_arena CD_CONTRATTO.FLG_ARENA%TYPE,
                                 p_id_contratto OUT CD_CONTRATTO.ID_CONTRATTO%TYPE,
                                 p_esito       OUT NUMBER
                                 );
                                 
PROCEDURE PR_INSERISCI_CONTRATTO_CINEMA(p_id_contratto CD_CONTRATTO.ID_CONTRATTO%TYPE,
                                        p_id_cinema CD_CINEMA.ID_CINEMA%TYPE,
                                        p_giorno_chiusura CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE,
                                        p_ferie_estive CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE%TYPE,
                                        p_importo CD_CINEMA_CONTRATTO.IMPORTO%TYPE,
                                        p_data_pagamento CD_CINEMA_CONTRATTO.DATA_PAGAMENTO_FATTURA%TYPE,
                                        p_esito       OUT NUMBER
                                        );
                                        
PROCEDURE PR_INSERISCI_PERC_RIPARTIZIONE(p_id_contratto CD_CINEMA_CONTRATTO.ID_CONTRATTO%TYPE,
                                        p_id_cinema CD_CINEMA_CONTRATTO.ID_CINEMA%TYPE,
                                        p_data_inizio  CD_PERCENTUALE_RIPARTIZIONE.DATA_INIZIO%TYPE,
                                        p_data_fine  CD_PERCENTUALE_RIPARTIZIONE.DATA_FINE%TYPE,
                                        p_categoria_prodotto CD_PERCENTUALE_RIPARTIZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                        p_perc_ripartizione CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE,
                                        p_esito       OUT NUMBER
                                        );
                                                                      
PROCEDURE PR_MODIFICA_CONTRATTO( p_id_contratto CD_CONTRATTO.ID_CONTRATTO%TYPE,
                                 p_data_inizio CD_CONTRATTO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_CONTRATTO.DATA_FINE%TYPE,
                                 p_data_risoluzione CD_CONTRATTO.DATA_RISOLUZIONE%TYPE,
                                 p_flg_arena CD_CONTRATTO.FLG_ARENA%TYPE,
                                 p_esito       OUT NUMBER
                                 );     
PROCEDURE PR_MODIFICA_CONTRATTO_CINEMA(p_id_cinema_contratto CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE,
                                 p_giorno_chiusura CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE,
                                 p_ferie_estive CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE%TYPE,
                                 p_importo CD_CINEMA_CONTRATTO.IMPORTO%TYPE,
                                 p_data_pagamento CD_CINEMA_CONTRATTO.DATA_PAGAMENTO_FATTURA%TYPE,
                                 p_esito       OUT NUMBER
                                 );

PROCEDURE PR_MODIFICA_PERC_RIPARTIZIONE( p_id_perc_ripartizione CD_PERCENTUALE_RIPARTIZIONE.ID_PERC_RIPARTIZIONE%TYPE,
                                 p_data_inizio CD_CONTRATTO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_CONTRATTO.DATA_FINE%TYPE,
                                 p_categoria_prodotto CD_PERCENTUALE_RIPARTIZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_perc_ripartizione CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE,
                                 p_esito       OUT NUMBER
                                 );
PROCEDURE PR_SUBENTRO_ESERCENTE(p_id_contratto          cd_contratto.id_contratto%type,
                                p_vecchio_esercente     vi_cd_societa_esercente.cod_esercente%type,
                                p_nuovo_esercente       vi_cd_societa_esercente.cod_esercente%type,
                                p_data_subentro         date,
                                p_esito OUT             NUMBER);
--                                                                                                                         
FUNCTION FU_CONDIZIONI_CONTRATTO(p_id_contratto CD_CINEMA_CONTRATTO.ID_CONTRATTO%TYPE,
                                 p_id_cinema_contratto CD_PERCENTUALE_RIPARTIZIONE.ID_CINEMA_CONTRATTO%TYPE
                                 ) RETURN C_CONDIZIONE_CONTRATTO;

/*FUNCTION FU_RAPPRESENTANTI_LEGALI(p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE) RETURN VARCHAR2;*/

--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista

FUNCTION FU_QUOTE_ESERCENTI(p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE, 
                            p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                            p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                            p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE) RETURN C_QUOTA_ESERCENTE;
                            
--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista                            

PROCEDURE PR_CALCOLA_QUOTE_LIQUIDAZIONE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                  p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                  p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                  p_esito OUT NUMBER);
                                  
--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista                                  

PROCEDURE PR_PAGA_QUOTE_ESERCENTI(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                  p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                  p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                  p_esito OUT NUMBER);
                                  
PROCEDURE PR_CALCOLA_LIQUIDAZIONE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                  p_esito OUT NUMBER);
                                  
--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista                                  
                                  
PROCEDURE PR_CALCOLA_QUOTA_TAB(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                p_esito OUT NUMBER);                                                                    

PROCEDURE PR_CALCOLA_QUOTA_ISP(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                p_esito OUT NUMBER);

--Mauro Viel Altran 13/04/2010 modificato tipo per utilizzo della vista

PROCEDURE PR_CALCOLA_QUOTA_ESERCENTE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                     p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                     p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                     p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                     p_esito OUT NUMBER);
                                     
FUNCTION FU_CINEMA_CONTRATTO(p_id_contratto CD_CONTRATTO.ID_CONTRATTO%TYPE) RETURN C_CINEMA_CONTRATTO;

FUNCTION FU_LIQUIDAZIONE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                         p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE) RETURN C_LIQUIDAZIONE;

PROCEDURE PR_GENERA_LIQUIDAZIONE_SALA(P_DATA CD_LIQUIDAZIONE_SALA.DATA_RIF%TYPE);

FUNCTION FU_DETT_QUOTA_ESERCENTE_TAB(P_COD_ESERCENTE     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            P_DATA_INIZIO       CD_LIQUIDAZIONE.DATA_INIZIO%TYPE,
                            P_DATA_FINE         CD_LIQUIDAZIONE.DATA_FINE%TYPE) RETURN C_DETT_QUOTA_ESERCENTE_TAB;
                            
FUNCTION FU_GET_CODICE_RESPONSABILITA(P_ID_SALA CD_SALA.ID_SALA%TYPE, P_DATA_RIF CD_LIQUIDAZIONE_SALA.DATA_RIF%TYPE) RETURN CD_CODICE_RESP.ID_CODICE_RESP%TYPE; 


FUNCTION FU_DETT_QUOTA_ESERCENTE_ISP(P_COD_ESERCENTE     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            P_DATA_INIZIO       CD_LIQUIDAZIONE.DATA_INIZIO%TYPE,
                            P_DATA_FINE         CD_LIQUIDAZIONE.DATA_FINE%TYPE) RETURN C_DETT_QUOTA_ESERCENTE_ISP ;
                                               
PROCEDURE PR_CALCOLA_FERIE_CINEMA(p_liquidazione CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE,
                                p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                p_esito OUT NUMBER);
                                
                                
FUNCTION FU_CINEMA_ARENA_ESERCENTE(p_cod_esercente    VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            p_flg_arena    CD_SALA.FLG_ARENA%TYPE 
                              )
                            RETURN C_ESERCENTE_CINEMA;
                            
PROCEDURE PR_ELIMINA_CINEMA_CONTRATTO(p_id_cinema_contratto CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE,
                                      p_esito OUT NUMBER);
                                      
FUNCTION FU_DISPONIBILITA_FERIE(P_ID_PROIEZIONE     CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                P_ID_CODICE_RESP    cd_codice_resp.ID_CODICE_RESP%TYPE)
                            RETURN NUMBER;
FUNCTION FU_DISP_FERIE_CONSUNTIVO(  P_ID_sala           cd_sala.id_sala%TYPE,
                                    P_ID_CODICE_RESP    cd_codice_resp.ID_CODICE_RESP%TYPE)
                            RETURN NUMBER;
                            
PROCEDURE PR_IMPOSTA_GIORNO_CHIUSURA(P_ID_PROIEZIONE    CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                     P_ID_CODICE_RESP   cd_codice_resp.ID_CODICE_RESP%TYPE,
                                     P_ESITO OUT NUMBER);


                                     
PROCEDURE PR_SALVA_GIORNI_SANATORIA(p_id_sala cd_sala.id_sala%type,
                                     p_id_liquidazione cd_liquidazione.ID_LIQUIDAZIONE%type,
                                     p_gg_sanatoria cd_quota_tab.gg_SANATORIA%type,
                                     p_esito       OUT NUMBER
                                 );  
                                 
                                 
FUNCTION FU_GET_QUOTA_TAB(p_data_inizio cd_liquidazione.DATA_INIZIO%type, p_data_fine cd_liquidazione.DATA_FINE%type, p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%type) RETURN NUMBER;                                                                   
FUNCTION FU_GET_QUOTA_ISP(p_data_inizio cd_liquidazione.DATA_INIZIO%type, p_data_fine cd_liquidazione.DATA_FINE%type, p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%type) RETURN NUMBER;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RISOLUZIONE_CONTRATTO
--  Effettua l'update di CD_CONTRATTO in relazione alla fine validita di un cinema
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_fine_val     La data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 2 Maggio 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RISOLUZIONE_CONTRATTO( p_id_cinema         CD_CINEMA_CONTRATTO.ID_CINEMA%TYPE,
                                    p_data_fine_val     CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER);   
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_RISOL_CONTR
--  Effettua l'update di CD_CONTRATTO in relazione alla rivalidita di un cinema
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_risoluzione  La vecchia data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 2 Maggio 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_RISOL_CONTR(   p_id_cinema         CD_CINEMA_CONTRATTO.ID_CINEMA%TYPE,
                                    p_data_risoluzione  CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER);       
                                    
--- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_RAGGR_QUOTE_ESER
-- Estrae le informazioni riguardanti le quote esercenti per un periodo
--
-- INPUT
--          p_cod_esercente     codice dell'esercente 
--          p_id_gruppo         codice gruppo
--          p_data_inizio       data inizio raggruppamento 
--          p_data_fine         data fine raggruppamento
--
-- OUTPUT
--          Cursore di R_QUOTA_ESERCENTE contenente le quote raggruppate
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 1 Dicembre 2011
-- --------------------------------------------------------------------------------------------                                    
FUNCTION FU_RAGGR_QUOTE_ESER(   p_cod_esercente     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE, 
                                p_id_gruppo         VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                p_data_inizio       CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine         CD_LIQUIDAZIONE.DATA_FINE%TYPE
                            ) RETURN C_QUOTA_ESERCENTE;
                            
--- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_GET_RAGGR_QUOTA_TAB
-- Estrae la quota tabellare raggruppata per periodo
--
-- INPUT
--          p_data_inizio       data inizio raggruppamento 
--          p_data_fine         data fine raggruppamento
--          p_cod_esercente     codice dell'esercente
-- OUTPUT
--          La quota cercata
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 1 Dicembre 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RAGGR_QUOTA_TAB(    p_data_inizio   CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                    p_data_fine     CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                    p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE
                               ) RETURN NUMBER;
                               
--- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_GET_RAGGR_QUOTA_ISP
-- Estrae la quota iniziative speciali raggruppata per periodo
--
-- INPUT
--          p_data_inizio       data inizio raggruppamento 
--          p_data_fine         data fine raggruppamento
--          p_cod_esercente     codice dell'esercente
-- OUTPUT
--          La quota cercata
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 1 Dicembre 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RAGGR_QUOTA_ISP(    p_data_inizio   CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                    p_data_fine     CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                    p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE
                               ) RETURN NUMBER;                                                                                                                                                          

END PA_CD_ESERCENTE; 
/

