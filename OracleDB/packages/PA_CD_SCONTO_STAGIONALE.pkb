CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SCONTO_STAGIONALE IS
--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_SCONTO_STAGIONALE
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuov sconto stagionale nel sistema
--
-- OPERAZIONI:
--	 1) Controlla se l'intervallo di validita' dello sconto e contenuto in quello del listino
--   2) Controlla che non esistano per quel listino altri sconti la cui validita' si intersechi con quella
--      dello sconto che vogliamo inserire
--   3) Memorizza lo sconto stagionale indicato dall'utente
--
-- INPUT: 
--  p_data_inizio           data inizio di validita sconto stagionale
--  p_data_fine             data fine di validita sconto stagionale
--  p_perc_sconto           percentuale di sconto
--  p_id_listino            identificativo del listino 
--
-- OUTPUT: esito:
--    1  record inserito correttamente 
--    2  Inserimento non eseguito: violato il vincolo sull'intervallo di validita' dello sconto dentro il listino
--    3  Inserimento non eseguito: violato il vincolo sull'intersezione degli sconti di un listino   
--   -1  Inserimento non eseguito: si e' verificato un errore
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009 
--
--  MODIFICHE: 
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SCONTO_STAGIONALE(   p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                            p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                            p_perc_sconto           CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
                                            p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE,
                                            p_esito                 OUT NUMBER)
IS   
    v_id_sconto INTEGER:= 0;
    v_esito_validita INTEGER:= 0;
BEGIN 
    SAVEPOINT SP_PR_INSERISCI_SCONTO_STAG;
--  
-- eseguo i controlli di validita'  
    PA_CD_SCONTO_STAGIONALE.PR_VERIFICA_VALIDITA_SCONTO(p_data_inizio, p_data_fine, p_id_listino, v_id_sconto, v_esito_validita);      
--  
    p_esito := v_esito_validita;
    IF(p_esito=1)THEN 
        INSERT INTO CD_SCONTO_STAGIONALE 
            (DATA_INIZIO,
             DATA_FINE,
             PERC_SCONTO,
             ID_LISTINO)
        VALUES
            (p_data_inizio,
             p_data_fine,
             p_perc_sconto,
             p_id_listino);
    END IF;
--      
EXCEPTION 
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20027, 'Procedura PR_INSERISCI_SCONTO_STAGIONALE: Insert non eseguita '||
							FU_STAMPA_SCONTO_STAGIONALE(-1, p_data_inizio, p_data_fine, p_perc_sconto, p_id_listino)||'  '||SQLERRM);
    ROLLBACK TO SP_PR_INSERISCI_SCONTO_STAG; 
END; 
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_SCONTO_STAGIONALE     
--
-- DESCRIZIONE:  Esegue l'aggiornamento di una record preesistente
--
-- OPERAZIONI:
--	 1) Controlla se l'intervallo di validita' dello sconto e contenuto in quello del listino
--   2) Controlla che non esistano per quel listino altri sconti la cui validita' si intersechi con quella
--      dello sconto che vogliamo inserire
--   3) Memorizza lo sconto stagionale indicato dall'utente
--  
-- INPUT: 
--  p_id_sconto_stagionale  identificativo dello sconto stagionale
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_perc_sconto           percentuale di sconto
--  p_id_listino            identificativo del listino
--
-- OUTPUT: esito:
--    1  record aggiornato    
--    2  Modifica non eseguita: violato il vincolo sull'intervallo di validita' dello sconto dentro il listino
--    3  Modifica non eseguita: violato il vincolo sull'intersezione degli sconti di un listino   
--   -1  Modifica non eseguita: si e' verificato un errore
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009 
--
--  MODIFICHE: 
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_SCONTO_STAGIONALE(    p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                            p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                            p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                            p_perc_sconto           CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
                                            p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE,
                                            p_esito             OUT NUMBER)   
IS   
    v_esito_validita INTEGER:= 0;              
BEGIN 
    SAVEPOINT SP_PR_MODIFICA_SCONTO_STAG;
--  
-- eseguo i controlli di validita'  
    PA_CD_SCONTO_STAGIONALE.PR_VERIFICA_VALIDITA_SCONTO(p_data_inizio, p_data_fine, p_id_listino, p_id_sconto_stagionale, v_esito_validita);      
--  
    p_esito := v_esito_validita;
    IF(p_esito=1)THEN 
        UPDATE CD_SCONTO_STAGIONALE 
        SET 
		    DATA_INIZIO = NVL(p_data_inizio,DATA_INIZIO),
            DATA_FINE   = NVL(p_data_fine,DATA_FINE),
            PERC_SCONTO = NVL(p_perc_sconto,PERC_SCONTO),
            ID_LISTINO  = NVL(p_id_listino,ID_LISTINO)
       WHERE ID_SCONTO_STAGIONALE = p_id_sconto_stagionale;
    END IF;
--          
EXCEPTION 
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20027, 'Procedura PR_MODIFICA_SCONTO_STAGIONALE: Update non eseguit0 '||
							FU_STAMPA_SCONTO_STAGIONALE(p_id_sconto_stagionale, p_data_inizio, p_data_fine, p_perc_sconto, p_id_listino)||'  '||SQLERRM);
    ROLLBACK TO SP_PR_MODIFICA_SCONTO_STAG;
END;
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE PR_ELIMINA_SCONTO_STAGIONALE
-- DESCRIZIONE:  Elimina uno sconto stagionale 
-- INPUT: l'id dell'elemento da eliminare
-- OUTPUT: 
--      1 elemento eliminato correttamente
--      2 elemento non presente
--      -1 elemento non eliminato
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009 
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SCONTO_STAGIONALE(p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                       p_esito                 OUT NUMBER)
IS
    v_esiste    INTEGER:=0;	  								   
BEGIN
--
    SAVEPOINT SP_PR_ELIMINA_SCONTO_STAG;
    SELECT COUNT(*)
        INTO   v_esiste
        FROM   CD_SCONTO_STAGIONALE
        WHERE  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE=p_id_sconto_stagionale;
--
    IF(v_esiste>0)THEN
	    DELETE FROM CD_SCONTO_STAGIONALE
		WHERE  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE=p_id_sconto_stagionale;
		p_esito:=1;
    ELSE
        p_esito:=2;
    END IF;
--    
EXCEPTION
    WHEN OTHERS THEN
	    RAISE_APPLICATION_ERROR(-20027, 'PROCEDURA FU_ELIMINA_SCONTO_STAGIONALE: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
		p_esito:=-1;
		ROLLBACK TO SP_PR_ELIMINA_SCONTO_STAG;     
END;	
--								   
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_SCONTO_STAGIONALE
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package 
--
-- INPUT: parametri dello sconto stagionale
--  p_id_sconto_stagionale  identificativo dello sconto stagionale
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_perc_sconto           percentuale di sconto
--  p_id_listino            identificativo del listino
--
-- OUTPUT: varchar che contiene i paramtetri
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009 
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SCONTO_STAGIONALE(   p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                        p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                        p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                        p_perc_sconto           CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE,
                                        p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE) 
                                        RETURN VARCHAR2
IS
BEGIN   
    IF v_stampa_sconto_stagionale = 'ON'
        THEN
         RETURN 'ID_SCONTO_STAGIONALE: '   || p_id_sconto_stagionale   || ', ' ||
                'DATA_INIZIO: '       || p_data_inizio       || ', ' ||
                'DATA_FINE: '         || p_data_fine         || ', ' || 
                'PERC_SCONTO: '         || p_perc_sconto         || ', ' || 
                'ID_LISTINO: '         || p_id_listino;
    END IF;
END  FU_STAMPA_SCONTO_STAGIONALE;
-- 
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ELENCO_SCONTI_STAGIONALI
-- DESCRIZIONE:  la funzione si occupa di reperire l'elenco degli sconti stagionali memorizzati in tabella 
--
-- INPUT:  Criteri di ricerca degli sconti stagionali (ID_LISTINO)
-- OUTPUT: Restituisce gli sconti stagionali che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009 
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_SCONTI_STAGIONALI(p_id_listino     CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE) 
						             RETURN C_SCONTO_STAGIONALE
IS
    c_sconto_stagionale_return C_SCONTO_STAGIONALE;
BEGIN
    OPEN c_sconto_stagionale_return
        FOR 
            SELECT   SCONTO.ID_SCONTO_STAGIONALE, SCONTO.DATA_INIZIO, SCONTO.DATA_FINE,
                     SCONTO.PERC_SCONTO, SCONTO.ID_LISTINO,
                     (SELECT CD_LISTINO.DESC_LISTINO
                        FROM CD_LISTINO
                       WHERE CD_LISTINO.ID_LISTINO = SCONTO.ID_LISTINO) DESC_LISTINO
                FROM CD_SCONTO_STAGIONALE SCONTO
               WHERE SCONTO.ID_LISTINO = NVL (p_id_listino, SCONTO.ID_LISTINO)
            ORDER BY SCONTO.ID_LISTINO, SCONTO.DATA_INIZIO;
    RETURN c_sconto_stagionale_return;    
--    
EXCEPTION  
		WHEN OTHERS THEN
		    RAISE_APPLICATION_ERROR(-20027, 'FUNZIONE FU_ELENCO_SCONTI_STAGIONALI: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
END FU_ELENCO_SCONTI_STAGIONALI;   
--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_VERIFICA_VALIDITA_SCONTO
--
-- DESCRIZIONE:  Verifica di validita' per l'inserimento e la modifica di uno sconto 
--
-- OPERAZIONI:
--	 1) Controlla se l'intervallo di validita' dello sconto e contenuto in quello del listino
--   2) Controlla che non esistano per quel listino altri sconti la cui validita' si intersechi con quella
--      dello sconto che vogliamo inserire
--
-- INPUT:
--      p_data_inizio               data inizio validita
--      p_data_fine                 data fine validita
--      p_id_listino                id del listino di riferimento
--      p_id_sconto_stagionale      id dello sconto stagionale
--
-- OUTPUT: esito:
--    1     nessun vincolo violato, lo sconto puo' essere inserito/modificato    
--    2     violato il vincolo sull'intervallo di validita' dello sconto dentro il listino
--    3     violato il vincolo sull'intersezione degli sconti di un listino
--   -1     sollevata una eccezione durante l'esecuzione 
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009 
--
--  MODIFICHE: 
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_VERIFICA_VALIDITA_SCONTO(   p_data_inizio           CD_SCONTO_STAGIONALE.DATA_INIZIO%TYPE,
                                            p_data_fine             CD_SCONTO_STAGIONALE.DATA_FINE%TYPE,
                                            p_id_listino            CD_SCONTO_STAGIONALE.ID_LISTINO%TYPE,
                                            p_id_sconto_stagionale  CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE%TYPE,
                                            p_esito                    OUT NUMBER)
IS
    v_data_in_listino       CD_LISTINO.DATA_INIZIO%TYPE;
    v_data_f_listino        CD_LISTINO.DATA_FINE%TYPE;    
    v_cursor_sconti_listino C_SCONTO_DATE;
    r_record_sconto_listino R_SCONTO_DATE;        
BEGIN 
    p_esito:=1;
--
-- determino l'intervallo di validita' del listino e faccio la relativa verifica     
    SELECT CD_LISTINO.DATA_INIZIO, CD_LISTINO.DATA_FINE
		INTO   v_data_in_listino, v_data_f_listino 
		FROM   CD_LISTINO 
		WHERE  CD_LISTINO.ID_LISTINO = p_id_listino;
--        
    IF(p_data_inizio<v_data_in_listino OR p_data_fine>v_data_f_listino)THEN
        p_esito:=2;
    ELSE
        -- posso procedere, verifico che non ci sia intersezione con altri sconti dello stesso listino
        -- escluso lo sconto 'attuale' (per l'inserimento assegno un valore 0 a id_sconto_stagionale)
        OPEN v_cursor_sconti_listino FOR
        SELECT   SCONTO.ID_SCONTO_STAGIONALE, SCONTO.DATA_INIZIO, SCONTO.DATA_FINE, SCONTO.ID_LISTINO
               FROM CD_SCONTO_STAGIONALE SCONTO
               WHERE SCONTO.ID_LISTINO = p_id_listino
               AND SCONTO.ID_SCONTO_STAGIONALE <> p_id_sconto_stagionale
               ORDER BY SCONTO.DATA_INIZIO;
--            
        LOOP
            FETCH v_cursor_sconti_listino into r_record_sconto_listino;
            EXIT WHEN v_cursor_sconti_listino%NOTFOUND;
--            
            IF(p_data_inizio<=r_record_sconto_listino.a_data_fine AND p_data_fine>=r_record_sconto_listino.a_data_inizio)THEN
                p_esito:=3;
            END IF;
        END LOOP;
        CLOSE v_cursor_sconti_listino;
--        
    END IF; 
--    
EXCEPTION  
    WHEN OTHERS THEN
            p_esito:=-1;
		    RAISE_APPLICATION_ERROR(-20027, 'PROCEDURE PR_VERIFICA_VALIDITA_SCONTO: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);         
END PR_VERIFICA_VALIDITA_SCONTO;
--                                                                                   
END PA_CD_SCONTO_STAGIONALE; 
/

