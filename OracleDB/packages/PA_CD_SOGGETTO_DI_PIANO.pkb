CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SOGGETTO_DI_PIANO IS 

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_SOGGETTO_DI_PIANO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo soggetto di piano nel sistema
--
-- OPERAZIONI:
--   1) Memorizza il soggetto di piano (CD_SOGGETTO_DI_PIANO)
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
PROCEDURE PR_INSERISCI_SOGGETTO_DI_PIANO(p_descrizione                       CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE,
                                         p_esito                             OUT NUMBER)
IS                 

BEGIN -- PR_INSERISCI_SOGGETTO_DI_PIANO
--
     
p_esito     := 1;
--P_ID_SOGGETTO_DI_PIANO := SOGGETTO_DI_PIANO_SEQ.NEXTVAL;
      
     --
          SAVEPOINT ann_ins;
      --
   
    -- effettuo l'INSERIMENTO           
       INSERT INTO CD_SOGGETTO_DI_PIANO 
         (DESCRIZIONE--,
          --UTEMOD,
          --DATAMOD
         )
       VALUES
         (p_descrizione--,
          --user,
          --FU_DATA_ORA
          );

EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20024, 'PROCEDURA PR_INSERISCI_SOGGETTO_DI_PIANO: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_SOGGETTO_DI_PIANO(p_descrizione));
        ROLLBACK TO ann_ins; 
    
END; 
     
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SOGGETTO_DI_PIANO
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un soggetto di piano dal sistema
--
-- OPERAZIONI:
--   3) Elimina il soggetto di piano
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
PROCEDURE PR_ELIMINA_SOGGETTO_DI_PIANO( p_id_soggetto_di_piano   IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                        p_esito                  OUT NUMBER)
IS                 

--
BEGIN -- PR_ELIMINA_SOGGETTO_DI_PIANO
--
     
p_esito     := 1;
      
     --
          SAVEPOINT ann_del;
      
  
       -- effettua l'ELIMINAZIONE        
       DELETE FROM CD_SOGGETTO_DI_PIANO 
       WHERE ID_SOGGETTO_DI_PIANO = p_id_soggetto_di_piano;
       --
    p_esito := SQL%ROWCOUNT;       
       
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20024, 'Procedura PR_ELIMINA_SOGGETTO_DI_PIANO: Delete non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO ann_del; 
  

END; 

 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_SOGGETTO_DI_PIANO
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package 
--
-- OUTPUT: varchar che contiene i parametri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009 
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
                          

FUNCTION FU_STAMPA_SOGGETTO_DI_PIANO(p_descrizione                          CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE
                                    )  RETURN VARCHAR2
IS

BEGIN   

IF v_stampa_soggetto_di_piano = 'ON'

    THEN
     
     RETURN 'DESCRIZIONE: '           || p_descrizione;                              
     
END IF;
     
END  FU_STAMPA_SOGGETTO_DI_PIANO;

END PA_CD_SOGGETTO_DI_PIANO; 
/

