CREATE OR REPLACE PACKAGE VENCD.PA_CD_FASCIA IS

v_stampa_tipo_fascia          VARCHAR2(3):='ON';
v_stampa_fascia               VARCHAR2(3):='ON';  

TYPE R_TIPO_FASCIA IS RECORD 
(
    a_id_tipo_fascia          CD_TIPO_FASCIA.ID_TIPO_FASCIA%TYPE,
    a_desc_tipo               CD_TIPO_FASCIA.DESC_TIPO%TYPE
);

TYPE C_TIPO_FASCIA IS REF CURSOR RETURN R_TIPO_FASCIA;                         

TYPE R_FASCIA IS RECORD 
(
    a_id_fascia               CD_FASCIA.ID_FASCIA%TYPE,
    a_desc_fascia             CD_FASCIA.DESC_FASCIA%TYPE,
    a_hh_inizio               CD_FASCIA.HH_INIZIO%TYPE,
    a_mm_inizio               CD_FASCIA.MM_INIZIO%TYPE,
	a_hh_fine                 CD_FASCIA.HH_FINE%TYPE,
    a_mm_fine                 CD_FASCIA.MM_FINE%TYPE,
	a_id_tipo_fascia          CD_FASCIA.ID_TIPO_FASCIA%TYPE
);

TYPE C_FASCIA IS REF CURSOR RETURN R_FASCIA;

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione delle 
--              fasce e dei tipi fascia
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_INSERISCI_FASCIA                Inserimento di una fascia nel sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_ELIMINA_FASCIA                  Eliminazione di una fascia dal sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_INSERISCI_TIPO_FASCIA           Inserimento di un tipo fascia nel sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    PR_ELIMINA_TIPO_FASCIA             Eliminazione di un tipo fascia dal sistema   
-- --------------------------------------------------------------------------------------------
-- PROCEDURE  
--    FU_RICERCA_TIPO_FASCIA             Estrazione delle tipologie di fasce orarie presenti
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009 
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
-- --------------------------------------------------------------------------------------------  
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_FASCIA      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_FASCIA(  p_id_tipo_fascia        CD_FASCIA.ID_TIPO_FASCIA%TYPE,
                                p_desc_fascia           CD_FASCIA.DESC_FASCIA%TYPE,
                                p_hh_inizio             CD_FASCIA.HH_INIZIO%TYPE,
                                p_mm_inizio             CD_FASCIA.MM_INIZIO%TYPE,
                            	p_hh_fine               CD_FASCIA.HH_FINE%TYPE,
                                p_mm_fine               CD_FASCIA.MM_FINE%TYPE,
         					    p_esito					OUT NUMBER);	
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_FASCIA      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_FASCIA(  p_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
                               p_id_tipo_fascia        CD_FASCIA.ID_TIPO_FASCIA%TYPE,
                               p_desc_fascia           CD_FASCIA.DESC_FASCIA%TYPE,
                               p_hh_inizio             CD_FASCIA.HH_INIZIO%TYPE,
                               p_mm_inizio             CD_FASCIA.MM_INIZIO%TYPE,
                               p_hh_fine               CD_FASCIA.HH_FINE%TYPE,
                               p_mm_fine               CD_FASCIA.MM_FINE%TYPE,
                               p_flag_annullato        CD_FASCIA.FLG_ANNULLATO%TYPE,
         					   p_esito				   OUT NUMBER);	
                                                                 
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_FASCIA      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_FASCIA(	p_id_fascia		IN CD_FASCIA.ID_FASCIA%TYPE,
								p_esito			OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_FASCIA     
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_FASCIA ( p_id_tipo_fascia            CD_FASCIA.ID_TIPO_FASCIA%TYPE,
                            p_desc_fascia               CD_FASCIA.DESC_FASCIA%TYPE
                            ) RETURN VARCHAR2; 
                            
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_TIPO_FASCIA      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_TIPO_FASCIA      (p_desc_tipo                         CD_TIPO_FASCIA.DESC_TIPO%TYPE,
                                         p_esito                             OUT NUMBER);     
                                                                 
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_TIPO_FASCIA      
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_TIPO_FASCIA(p_id_tipo_fascia        IN CD_TIPO_FASCIA.ID_TIPO_FASCIA%TYPE,
                                 p_esito                 OUT NUMBER);    
                                
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_TIPO_FASCIA      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_TIPO_FASCIA(p_desc_tipo                         CD_TIPO_FASCIA.DESC_TIPO%TYPE
                               )RETURN VARCHAR2;       

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_TIPO_FASCIA      
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_TIPO_FASCIA RETURN C_TIPO_FASCIA; 

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_FASCIA      
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_FASCIA( p_id_tipo_fascia          CD_TIPO_FASCIA.ID_TIPO_FASCIA%TYPE)
                            RETURN C_FASCIA; 

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_NUMERO_FASCE_TIPO
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009 
-- --------------------------------------------------------------------------------------------
                          

FUNCTION FU_NUMERO_FASCE_TIPO(p_id_tipo_fascia IN CD_TIPO_FASCIA.ID_TIPO_FASCIA%TYPE) 
   RETURN NUMBER; 


END PA_CD_FASCIA; 
/

