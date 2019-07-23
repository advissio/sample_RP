CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_FASCIA IS 

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_FASCIA
--
-- DESCRIZIONE:  Esegue l'inserimento di una nuova fascia nel sistema
--
-- OPERAZIONI:
--   1) Memorizza la fascia (CD_FASCIA)
--
-- INPUT:
--      p_id_tipo_fascia    id del tipo fascia
--      p_desc_fascia       descrizione della fascia
--      p_ora_inizio        ora di inizio
--      p_ora_fine          ora di fine
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo	
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009 
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_FASCIA(  p_id_tipo_fascia        CD_FASCIA.ID_TIPO_FASCIA%TYPE,
                                p_desc_fascia           CD_FASCIA.DESC_FASCIA%TYPE,
                                p_hh_inizio             CD_FASCIA.HH_INIZIO%TYPE,
                                p_mm_inizio             CD_FASCIA.MM_INIZIO%TYPE,
                            	p_hh_fine               CD_FASCIA.HH_FINE%TYPE,
                                p_mm_fine               CD_FASCIA.MM_FINE%TYPE,
         					    p_esito					OUT NUMBER)
IS                 
BEGIN 
    p_esito 	:= 1;
  	SAVEPOINT SP_PR_INSERISCI_FASCIA;
        INSERT INTO CD_FASCIA 
	       (ID_TIPO_FASCIA,
		    DESC_FASCIA,
		    HH_INIZIO,
			MM_INIZIO,
		    HH_FINE,
			MM_FINE)
	    VALUES
	       (p_id_tipo_fascia,
		    p_desc_fascia,
		    p_hh_inizio,
			p_mm_inizio,
		    p_hh_fine,
			p_mm_fine);
EXCEPTION 
		WHEN OTHERS THEN
    		p_esito := -11;
    		RAISE_APPLICATION_ERROR(-20004, 'Procedura PR_INSERISCI_FASCIA: Insert non eseguita, verificare la coerenza dei parametri '||
    		                            FU_STAMPA_FASCIA(p_id_tipo_fascia, p_desc_fascia));
    		ROLLBACK TO SP_PR_INSERISCI_FASCIA; 
END; 
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_FASCIA     
--
-- DESCRIZIONE:  Esegue l'aggiornamento di una fascia oraria preesistente
--  
-- OPERAZIONI:
--   Aggiorna la fascia (CD_FASCIA)
-- INPUT: l'id della fascia e i valori che si desidera aggiornare
-- OUTPUT: esito:
--    n  numero di record aggiornati	
--   -11 Modifica non eseguito: si e' verificatoun errore
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Agosto 2009 
--
--  MODIFICHE: 
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_FASCIA(  p_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
                               p_id_tipo_fascia        CD_FASCIA.ID_TIPO_FASCIA%TYPE,
                               p_desc_fascia           CD_FASCIA.DESC_FASCIA%TYPE,
                               p_hh_inizio             CD_FASCIA.HH_INIZIO%TYPE,
                               p_mm_inizio             CD_FASCIA.MM_INIZIO%TYPE,
                               p_hh_fine               CD_FASCIA.HH_FINE%TYPE,
                               p_mm_fine               CD_FASCIA.MM_FINE%TYPE,
                               p_flag_annullato        CD_FASCIA.FLG_ANNULLATO%TYPE,
         					   p_esito				   OUT NUMBER)
IS                 
BEGIN 
    p_esito 	:= 0;
    SAVEPOINT SP_PR_MODIFICA_FASCIA;
  	UPDATE CD_FASCIA 
	     SET 
		    ID_TIPO_FASCIA = nvl(p_id_tipo_fascia,ID_TIPO_FASCIA),
		    DESC_FASCIA    = nvl(p_desc_fascia, DESC_FASCIA),
		    HH_INIZIO     = nvl(p_hh_inizio,HH_INIZIO), 
		    MM_INIZIO     = nvl(p_mm_inizio,MM_INIZIO), 
		    HH_FINE       = nvl(p_hh_fine,HH_FINE), 
		    MM_FINE       = nvl(p_mm_fine,MM_FINE), 
		    FLG_ANNULLATO  = nvl(p_flag_annullato,FLG_ANNULLATO) 
	   WHERE ID_FASCIA = p_id_fascia;
	p_esito := SQL%ROWCOUNT;
	EXCEPTION
		WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20004, 'Procedura PR_MODIFICA_FASCIA: Update non eseguita, si e'' verificato un errore '||SQLERRM);
		ROLLBACK TO SP_PR_MODIFICA_FASCIA; 
END; 
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_FASCIA
--
-- DESCRIZIONE:  Esegue l'eliminazione di una fascia dal sistema
--              l'eliminazione e' logica se esistono proiezioni per quella fascia
--              altrimenti la fascia viene eliminata fisicamente dal DB
-- OPERAZIONI:
--   3) Elimina la fascia
--
-- INPUT:  p_id_fascia l'identificativo della fascia da eliminare
-- OUTPUT: esito:
--    n  numero di records eliminati 	
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009 
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_FASCIA(  p_id_fascia		IN CD_FASCIA.ID_FASCIA%TYPE,
							  p_esito			OUT NUMBER)
IS                 
BEGIN
    p_esito 	:= 0;
    SAVEPOINT PR_ELIMINA_FASCIA;
    DELETE FROM CD_FASCIA 
	WHERE  ID_FASCIA = p_id_fascia;
    p_esito := SQL%ROWCOUNT;       
EXCEPTION
    WHEN OTHERS THEN
	RAISE_APPLICATION_ERROR(-20004, 'Procedura PR_ELIMINA_FASCIA: Delete non eseguita, verificare la coerenza dei parametri');
	ROLLBACK TO PR_ELIMINA_FASCIA; 
END; 

 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_FASCIA
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package 
--
-- INPUT:
--      p_id_tipo_fascia    id del tipo fascia
--      p_desc_fascia       descrizione della fascia
--      p_ora_inizio        ora di inizio
--      p_ora_fine          ora di fine
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009 
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
                          

FUNCTION FU_STAMPA_FASCIA(  p_id_tipo_fascia            CD_FASCIA.ID_TIPO_FASCIA%TYPE,
                            p_desc_fascia               CD_FASCIA.DESC_FASCIA%TYPE
                            )  RETURN VARCHAR2
IS

BEGIN   

IF v_stampa_fascia = 'ON'

    THEN
     
     RETURN 'ID_TIPO_FASCIA: '          || p_id_tipo_fascia           || ', ' ||
            'DESC_FASCIA: '          || p_desc_fascia;  
     
END IF;
     
END  FU_STAMPA_FASCIA;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_TIPO_FASCIA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo tipo fascia nel sistema
--
-- OPERAZIONI:
--   1) Memorizza lo sconto stagionale (CD_TIPO_FASCIA)
--
-- INPUT:
--      p_desc_tipo       descrizione del tipo della fascia
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
PROCEDURE PR_INSERISCI_TIPO_FASCIA(p_desc_tipo                         CD_TIPO_FASCIA.DESC_TIPO%TYPE,
                                   p_esito                             OUT NUMBER)
IS                 

--
BEGIN -- PR_INSERISCI_TIPO_FASCIA
--
p_esito     := 1;
--P_ID_TIPO_FASCIA := TIPO_FASCIA_SEQ.NEXTVAL;
      
     --
          SAVEPOINT ann_ins;
      --

       -- effettuo l'INSERIMENTO           
       INSERT INTO CD_TIPO_FASCIA 
         (DESC_TIPO,
          UTEMOD,
          DATAMOD
         )
       VALUES
         (p_desc_tipo,
          user,
          FU_DATA_ORA
          );
            
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN

            p_esito := -11;
            RAISE_APPLICATION_ERROR(-20004, 'PROCEDURA PR_INSERISCI_TIPO_FASCIA: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_TIPO_FASCIA(p_desc_tipo
                                                                                                                                                                    ));
            ROLLBACK TO ann_ins;  

END; 
     
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_TIPO_FASCIA
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un tipo fascia dal sistema
--
-- OPERAZIONI:
--   3) Elimina il tipo fascia
--
-- INPUT:
--      p_id_tipo_fascia       id del tipo della fascia
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
PROCEDURE PR_ELIMINA_TIPO_FASCIA(p_id_tipo_fascia       IN CD_TIPO_FASCIA.ID_TIPO_FASCIA%TYPE,
                                 p_esito                OUT NUMBER)   
IS                 

v_quante_fasce      NUMBER(5);

--
BEGIN -- PR_ELIMINA_TIPO_FASCIA
--
     
p_esito     := 0;
      
     --
          SAVEPOINT ann_del;
      
        -- ricavo il numero di fasce orarie per tipologia di fascia
        v_quante_fasce := FU_NUMERO_FASCE_TIPO(p_id_tipo_fascia);
       
       IF v_quante_fasce = 0
       THEN
            BEGIN
                -- effettua l'ELIMINAZIONE fisica       
                DELETE FROM CD_TIPO_FASCIA 
                WHERE ID_TIPO_FASCIA = p_id_tipo_fascia;
      
                p_esito := SQL%ROWCOUNT;       
            END;
       ELSE
            BEGIN
                -- effettua l'ELIMINAZIONE logica tipo fascia
                UPDATE CD_TIPO_FASCIA
                SET  FLG_ANNULLATO = 'S'
                WHERE ID_TIPO_FASCIA = p_id_tipo_fascia;
                
                -- effettua l'ELIMINAZIONE logica fasce collegate
                UPDATE CD_FASCIA
                SET  FLG_ANNULLATO = 'S'
                WHERE ID_TIPO_FASCIA = p_id_tipo_fascia;
                p_esito := SQL%ROWCOUNT;
                
            END;
       END IF;
       
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Procedura PR_ELIMINA_TIPO_FASCIA: Delete non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO ann_del; 
  

END; 

 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_TIPO_FASCIA
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package 
--
-- OUTPUT: varchar che contiene i parametri
--
-- INPUT:
--      p_desc_tipo       descrizione del tipo della fascia
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009 
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
                          

FUNCTION FU_STAMPA_TIPO_FASCIA(p_desc_tipo                         CD_TIPO_FASCIA.DESC_TIPO%TYPE
                               )RETURN VARCHAR2
IS

BEGIN   

IF v_stampa_tipo_fascia = 'ON'

    THEN
     
     RETURN 'DESC_TIPO: '       || p_desc_tipo;
         
END IF;
     
END  FU_STAMPA_TIPO_FASCIA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_TIPO_FASCIA    
-- DESCRIZIONE:  la funzione si occupa di estrarre i tipi fasce 
--               che rispondono ai criteri di ricerca 
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009 
--
-- MODIFICHE  
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_TIPO_FASCIA RETURN C_TIPO_FASCIA
IS

c_tipo_fascia_return C_TIPO_FASCIA;

BEGIN

OPEN c_tipo_fascia_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR 
        SELECT  ID_TIPO_FASCIA, DESC_TIPO
        FROM    CD_TIPO_FASCIA
        WHERE   FLG_ANNULLATO='N';

RETURN c_tipo_fascia_return;
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20004, 'FUNZIONE FU_RICERCA_TIPO_FASCIA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');

END FU_RICERCA_TIPO_FASCIA;  

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_FASCIA    
-- DESCRIZIONE:  la funzione si occupa di estrarre le fasce
--               che rispondono ai criteri di ricerca 
--
-- OUTPUT: cursore che contiene i records
--
-- INPUT:
--      p_id_tipo_fascia       id del tipo della fascia
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009 
--
-- MODIFICHE  Francesco Abbundo, Teoresi srl, Novembre 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_FASCIA( p_id_tipo_fascia          CD_TIPO_FASCIA.ID_TIPO_FASCIA%TYPE)
                            RETURN C_FASCIA
IS
    c_fascia_return C_FASCIA;
BEGIN
    OPEN c_fascia_return  -- apre il cursore che conterra i tipi cinema da selezionare
        FOR 
    	    SELECT   ID_FASCIA, DESC_FASCIA, HH_INIZIO, MM_INIZIO, HH_FINE, MM_FINE, ID_TIPO_FASCIA
            FROM     CD_FASCIA
            WHERE    ID_TIPO_FASCIA = nvl(p_id_tipo_fascia, ID_TIPO_FASCIA)        
            AND      FLG_ANNULLATO = 'N';
    RETURN c_fascia_return;
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_FASCIA: SI E VERIFICATO UN ERRORE');
END FU_RICERCA_FASCIA;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_NUMERO_FASCE_TIPO
-- DESCRIZIONE:  la funzione si occupa di contare le fasce orarie esistenti per tipo fascia
--
-- INPUT:  id_tipo_fascia del tipo fascia di cui si intende contare il numero di fasce
-- OUTPUT: esito della procedura. Valori possibili:
--				  n = numero di fasce orarie
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009 
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
                          

FUNCTION FU_NUMERO_FASCE_TIPO(p_id_tipo_fascia IN CD_TIPO_FASCIA.ID_TIPO_FASCIA%TYPE)
							  RETURN NUMBER 
IS
-- DICHIARAZIONE DELLE VARIABILI DI COMODO

v_count_fasce	 NUMBER(3);   

BEGIN   
	 
        SELECT  COUNT(*) INTO v_count_fasce
        FROM    CD_FASCIA FASCIA, CD_TIPO_FASCIA TIPO_FASCIA
        WHERE   FASCIA.ID_TIPO_FASCIA          =       TIPO_FASCIA.ID_TIPO_FASCIA;
                     
      RETURN v_count_fasce;

END  FU_NUMERO_FASCE_TIPO;

END PA_CD_FASCIA; 
/

