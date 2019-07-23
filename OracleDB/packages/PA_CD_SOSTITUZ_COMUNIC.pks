CREATE OR REPLACE PACKAGE VENCD.PA_CD_SOSTITUZ_COMUNIC IS

v_stampa_sostituz_comunic             VARCHAR2(3):='ON';                                  

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione delle 
--              sostituzioni di comunicati
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_INSERISCI_SOSTITUZIONE_COMUNICATO           Inserimento di una sostituzione di comunicato nel sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_ELIMINA_SOSTITUZIONE_COMUNICATO            Eliminazione di una sostituzione di comunicato dal sistema   
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009 
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: 
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_SOSTITUZIONE_COMUNICATO      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SOSTITUZ_COMUNIC(    p_id_comunicato     CD_SOSTITUZIONE_COMUNICATO.ID_COMUNICATO%TYPE,
                                            p_versione          CD_SOSTITUZIONE_COMUNICATO.VERSIONE%TYPE,
                                            p_data              CD_SOSTITUZIONE_COMUNICATO.DATA%TYPE,
                                            p_causale           CD_SOSTITUZIONE_COMUNICATO.CAUSALE%TYPE,
                                            p_esito                OUT NUMBER);     
                                                                 
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SOSTITUZIONE_COMUNICATO      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SOSTITUZ_COMUNIC(    p_id_sostituz_comunic               IN CD_SOSTITUZIONE_COMUNICATO.ID_SOSTITUZIONE_COMUNICATO%TYPE,
                                        p_esito                             OUT NUMBER);     
                                        
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_SOSTITUZIONE_COMUNICATO      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SOSTITUZ_COMUNIC(     p_id_comunicato     CD_SOSTITUZIONE_COMUNICATO.ID_COMUNICATO%TYPE,
                                         p_versione          CD_SOSTITUZIONE_COMUNICATO.VERSIONE%TYPE,
                                         p_data              CD_SOSTITUZIONE_COMUNICATO.DATA%TYPE,
                                         p_causale           CD_SOSTITUZIONE_COMUNICATO.CAUSALE%TYPE) RETURN VARCHAR2;     

END PA_CD_SOSTITUZ_COMUNIC; 
/

