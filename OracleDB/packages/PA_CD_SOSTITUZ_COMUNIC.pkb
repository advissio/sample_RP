CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SOSTITUZ_COMUNIC IS 

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_SOSTITUZ_COMUNIC
--
-- DESCRIZIONE:  Esegue l'inserimento di una nuova sostituzione di comunicato nel sistema
--
-- OPERAZIONI:
--  1) Memorizza la sostituzione di comunicato (CD_SOSTITUZIONE_COMUNICATO)
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo    
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009 
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SOSTITUZ_COMUNIC(    p_id_comunicato     CD_SOSTITUZIONE_COMUNICATO.ID_COMUNICATO%TYPE,
                                            p_versione          CD_SOSTITUZIONE_COMUNICATO.VERSIONE%TYPE,
                                            p_data              CD_SOSTITUZIONE_COMUNICATO.DATA%TYPE,
                                            p_causale           CD_SOSTITUZIONE_COMUNICATO.CAUSALE%TYPE,
                                            p_esito                                  OUT NUMBER)
IS                 

BEGIN -- PR_INSERISCI_SOSTITUZ_COMUNIC
--

p_esito     := 1;
--P_SOSTITUZ_COMUNIC := SOSTITUZ_COMUNIC_SEQ.NEXTVAL;
      
     --
          SAVEPOINT ann_ins;
      --
       -- effettuo l'INSERIMENTO           
       INSERT INTO CD_SOSTITUZIONE_COMUNICATO 
         ( ID_COMUNICATO,
           VERSIONE,
           DATA,
           CAUSALE--,
          --UTEMOD,
          --DATAMOD
         )
       VALUES
         ( p_id_comunicato,
           p_versione,
           p_data,
           p_causale--,
          --user,
          --FU_DATA_ORA
          );
       -- 
       
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20025, 'PROCEDURA PR_INSERISCI_SOSTITUZ_COMUNIC: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_SOSTITUZ_COMUNIC( p_id_comunicato,
                                                                                                                                                                           p_versione,
                                                                                                                                                                           p_data,
                                                                                                                                                                           p_causale));
        ROLLBACK TO ann_ins; 
          
  
END; 
     
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SOSTITUZ_COMUNIC
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un sostituzione di comunicato dal sistema
--
-- OPERAZIONI:
--   3) Elimina la sostituzione di comunicato
--
-- OUTPUT: esito:
--    n  numero di records eliminati     
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009 
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SOSTITUZ_COMUNIC(  p_id_sostituz_comunic        IN CD_SOSTITUZIONE_COMUNICATO.ID_SOSTITUZIONE_COMUNICATO%TYPE,
                                        p_esito                        OUT NUMBER)
IS                 


--
BEGIN -- PR_ELIMINA_SOSTITUZ_COMUNIC
--
     
p_esito     := 1;
      
     --
          SAVEPOINT ann_del;
      
       -- EFFETTUA L'eliminazione        
       DELETE FROM CD_SOSTITUZIONE_COMUNICATO
       WHERE ID_SOSTITUZIONE_COMUNICATO = p_id_sostituz_comunic;
       --
    
    p_esito := SQL%ROWCOUNT;       
       
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20025, 'PROCEDURA PR_ELIMINA_SOSTITUZ_COMUNIC: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI');
        ROLLBACK TO ann_del; 
  
END; 

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_SOSTITUZ_COMUNIC
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package 
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009 
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
                          

FUNCTION FU_STAMPA_SOSTITUZ_COMUNIC(    p_id_comunicato     CD_SOSTITUZIONE_COMUNICATO.ID_COMUNICATO%TYPE,
                                        p_versione          CD_SOSTITUZIONE_COMUNICATO.VERSIONE%TYPE,
                                        p_data              CD_SOSTITUZIONE_COMUNICATO.DATA%TYPE,
                                        p_causale           CD_SOSTITUZIONE_COMUNICATO.CAUSALE%TYPE) RETURN VARCHAR2
IS

BEGIN   

IF v_stampa_sostituz_comunic = 'ON'

    THEN
     
     RETURN 'ID_COMUNICATO: '          || p_id_comunicato           || ', ' ||
            'VERSIONE: '          || p_versione            || ', ' ||
            'DATA: '|| p_data    || ', ' ||
            'CAUSALE: '  ||  p_causale ;
     
END IF;
     
END  FU_STAMPA_SOSTITUZ_COMUNIC;


END PA_CD_SOSTITUZ_COMUNIC; 
/

