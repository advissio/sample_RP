CREATE OR REPLACE PACKAGE VENCD.PA_CD_SOGGETTO_DI_PIANO IS

v_stampa_soggetto_di_piano          VARCHAR2(3):='ON';                           

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei 
--              soggetti di piano
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_INSERISCI_SOGGETTO_DI_PIANO           Inserimento di uno soggetto di piano nel sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_ELIMINA_SOGGETTO_DI_PIANO            Eliminazione di uno soggetto di piano dal sistema   
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009 
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: 
-- --------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_SOGGETTO_DI_PIANO      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SOGGETTO_DI_PIANO(p_descrizione                          CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
                                         p_esito                                OUT NUMBER);     
                                                                 
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SOGGETTO_DI_PIANO      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SOGGETTO_DI_PIANO( p_id_soggetto_di_piano        IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                        p_esito                       OUT NUMBER);    
                                
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_SOGGETTO_DI_PIANO      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SOGGETTO_DI_PIANO(p_descrizione                          CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE
                                    ) RETURN VARCHAR2;     

END PA_CD_SOGGETTO_DI_PIANO; 
/

