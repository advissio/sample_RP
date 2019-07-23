CREATE OR REPLACE PACKAGE VENCD.PA_CD_SCONTO_STAGIONALE IS
/******************************************************************************
   NAME:       PA_CD_SCONTO_STAGIONALE
   PURPOSE:     Questo package contiene procedure/funzioni necessarie per la gestione dello sconto stagionale

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/08/2009  Spezia Daniela   Created this package.
******************************************************************************/
v_stampa_sconto_stagionale      VARCHAR2(3):='ON';
TYPE R_SCONTO_STAGIONALE IS RECORD 
(
    a_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
    a_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
    a_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
    a_perc_sconto           CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
    a_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE, 
	a_desc_listino          CD_LISTINO.DESC_LISTINO%TYPE
);
TYPE C_SCONTO_STAGIONALE IS REF CURSOR RETURN R_SCONTO_STAGIONALE;
--
TYPE R_SCONTO_DATE IS RECORD 
(
    a_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
    a_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
    a_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
    a_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE
);
TYPE C_SCONTO_DATE IS REF CURSOR RETURN R_SCONTO_DATE;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_INSERISCI_SCONTO_STAGIONALE          Inserimento di uno sconto stagionale nel sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_MODIFICA_SCONTO_STAGIONALE           Modifica di uno sconto stagionale nel sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_ELIMINA_SCONTO_STAGIONALE            Eliminazione di uno sconto stagionale dal sistema   
-- --------------------------------------------------------------------------------------------
-- FUNCTION  
--    FU_ELENCO_SCONTI_STAGIONALI      Funzione di ricerca di uno sconto stagionale nel sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_VERIFICA_VALIDITA_SCONTO   Verifica la validita dell'intervallo temporale proposto per lo sconto  
-- --------------------------------------------------------------------------------------------
--
PROCEDURE PR_INSERISCI_SCONTO_STAGIONALE(   p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                            p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                            p_perc_sconto           CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
                                            p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE,
                                            p_esito                 OUT NUMBER);     
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_SCONTO_STAGIONALE    
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_SCONTO_STAGIONALE(    p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                            p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                            p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                            p_perc_sconto           CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
                                            p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE,
                                            p_esito             OUT NUMBER);     
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SCONTO_STAGIONALE     
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SCONTO_STAGIONALE(     p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                            p_esito                   OUT NUMBER);    
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_SPETTACOLO      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SCONTO_STAGIONALE (  p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                        p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                        p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                        p_perc_sconto           CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
                                        p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE) 
                                        RETURN VARCHAR2;     

--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_SCONTI_STAGIONALI      
-- --------------------------------------------------------------------------------------------
  FUNCTION FU_ELENCO_SCONTI_STAGIONALI( p_id_listino     CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE) 
                                        RETURN C_SCONTO_STAGIONALE; 
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_VERIFICA_VALIDITA_SCONTO   Verifica la validita dell'intervallo temporale proposto per lo sconto  
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_VERIFICA_VALIDITA_SCONTO(   p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                            p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                            p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE,
                                            p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                            p_esito                    OUT NUMBER);
-- 
END PA_CD_SCONTO_STAGIONALE; 
/

