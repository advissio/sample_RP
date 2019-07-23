CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_TARIFFA IS
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_TARIFFA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo tariffa nel sistema per una coppia (listino, prodotto vendita)
--               Crea anche tutti gli ambienti di vendita relativi all'intervallo di date passate in input
-- MODIFICHE:    l'intervallo di creazione non e' piu' quello del listino bensi' quello della tariffa
--
-- INPUT:
--  p_id_prodotto_vendita   identificativo del prodotto di vendita
--  p_id_tipo_tariffa       identificativo del tipo di tariffa
--  p_id_formato            formato della tariffa
--  p_id_misura_prd_vendita taglio temporale al quale e associata la tariffa
--  p_id_listino            identificativo del listino
--  p_id_tipo_cinema        identificativo del tipo di cinema
--  p_importo               importo della tariffa
--  p_data_inizio           data inizio validita della tariffa
--  p_data_fine             data fine validita della tariffa
--
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo (>0 poiche' c'e' almeno il record della Tariffa)
--    < 0 la tariffa non puo' essere creata perche' le date sono sovrapposte a quelle di un'altra preesistente
--   -111 Inserimento non eseguito: si e' verificato un errore
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE:       Francesco Abbundo, Teoresi srl, Luglio 2009, Ottobre 2009, Gennaio 2010
--                  Tommaso D'Anna, Teoresi srl, 3 Febbraio 2011
--                      Aggiunta chiamata a funzione FU_COMPATIBILITA_TARIFFA
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_TARIFFA( p_id_prodotto_vendita      CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                p_id_tipo_tariffa          CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                p_id_formato               CD_TARIFFA.ID_FORMATO%TYPE,
                                p_id_misura_prd_vendita    CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                p_id_listino               CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_tipo_cinema           CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                                p_importo                  CD_TARIFFA.IMPORTO%TYPE,
                                p_data_inizio              CD_TARIFFA.DATA_INIZIO%TYPE,
                                p_data_fine                CD_TARIFFA.DATA_FINE%TYPE,
                                p_flg_stagionale           CD_TARIFFA.FLG_STAGIONALE%TYPE,
                                p_esito                    OUT NUMBER)
IS
    v_temp1             INTEGER:=0;
    v_cursor_luoghi     C_CODICI_LUOGHI;
    v_record_luogo      R_CODICI_LUOGHI;
    v_codice_luogo      CD_LUOGO.ID_LUOGO%TYPE;
    v_numero_giorni     INTEGER;
    v_id_circuito       CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_data_inizio       CD_TARIFFA.DATA_INIZIO%TYPE;
    v_data_fine         CD_TARIFFA.DATA_FINE%TYPE;
BEGIN
    p_esito:=0;
    SAVEPOINT SP_PR_INSERISCI_TARIFFA;
    v_temp1:=PA_CD_TARIFFA.FU_COMPATIBILITA_TARIFFA(p_id_prodotto_vendita, p_id_listino, null, p_data_inizio, p_data_fine,
                                                        p_id_misura_prd_vendita,p_id_tipo_tariffa,p_id_formato,p_id_tipo_cinema);
    IF(v_temp1<0)THEN
        p_esito:=v_temp1;
    ELSE
        INSERT INTO CD_TARIFFA
            (ID_PRODOTTO_VENDITA, ID_TIPO_TARIFFA, ID_FORMATO,
             ID_MISURA_PRD_VE, ID_LISTINO, ID_TIPO_CINEMA,
             IMPORTO, DATA_INIZIO, DATA_FINE, FLG_STAGIONALE)
        VALUES
            (p_id_prodotto_vendita, p_id_tipo_tariffa, p_id_formato,
             p_id_misura_prd_vendita, p_id_listino, p_id_tipo_cinema,
             p_importo, p_data_inizio, p_data_fine, p_flg_stagionale);
        p_esito:=1+PA_CD_TARIFFA.FU_GENERA_AMBIENTI(p_id_prodotto_vendita,p_id_listino,p_data_inizio,p_data_fine);
    END IF;
  EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_INSERISCI_TARIFFA: Insert non eseguita, si e'' verificato un errore. '
                                ||FU_STAMPA_TARIFFA(p_id_prodotto_vendita,p_id_tipo_tariffa,p_id_formato,
                                  p_id_misura_prd_vendita,p_id_listino,p_id_tipo_cinema,p_importo,p_data_inizio,
                                  p_data_fine,p_flg_stagionale)||'  SQLERRM '||SQLERRM);
        ROLLBACK TO SP_PR_INSERISCI_TARIFFA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_TARIFFA
--
-- DESCRIZIONE:  Esegue l'aggiornamento di una tariffa preesistente.
--            *) Se per la tariffa in questione esiste almeno un prodotto acquistato allora si puo' solo
--               modificare l'importo e/o estendere (ma non ridurre) l'estensione temporale.
--               Nel caso di modifica importo deve essere invocata la RICALCOLA_IMPORTI
--            *) Se per la tariffa in questione non esiste un prodotto acquistato allora e' possibile
--               modificare piu' informazioni
--               In entrambi i casi un estensione temporale (destra o sinistra) comporta la generazione
--               degli ambienti di vendita mancanti per le sole differenze temporali, mentre una
--               contrazione (possibile solo se non esiste un prodotto acuistato associato) comporta
--               l'eliminazione degli ambienti di vendita esistenti nell'intevallo temporale rimosso dalla tariffa
-- INPUT:
--  p_id_tariffa            id della tariffa da aggiornare
--  p_id_prodotto_vendita   identificativo del prodotto di vendita
--  p_id_tipo_tariffa       identificativo del tipo di tariffa
--  p_id_formato            formato della tariffa
--  p_id_misura_prd_vendita taglio temporale al quale e associata la tariffa
--  p_id_listino            identificativo del listino
--  p_id_tipo_cinema        identificativo del tipo di cinema
--  p_importo               importo della tariffa
--  p_data_inizio           data inizio validita della tariffa
--  p_data_fine             data fine validita della tariffa
--
--
-- OUTPUT: esito:
--    1  tariffa aggiornata correttamente
--   -1  Aggiornamento non eseguito: si e' verificato un errore
--   -200 + valore resituito da FU_VERIFICA_MODIFICABILITA  
--       Aggiornamento non eseguito, impossibile aggiungere la tariffa vedere i 
--       commenti di FU_VERIFICA_MODIFICABILITA
--   -3  Aggiornamento non eseguito, impossibile modificare valori diversi da data_fine e importo.
--   -4  Aggiornamento non eseguito, si e' tentato di restringere l'intervallo temporale di esistenza
--       di una tariffa per cui esiste un prodotto acquistato
-- REALIZZATORE:    Francesco Abbundo, Teoresi srl, Settembre 2009
-- MODIFICHE:       Francesco Abbundo, Teoresi srl, Ottobre 2009, Gennaio 2010
--                  Tommaso D'Anna, Teoresi srl, 27 Gennaio 2011
--                      Inserita la possibilita di restringere l'intervallo fino a dove permesso
--                      dai comunicati presenti.
--                  Tommaso D'Anna, Teoresi srl, 3 Febbraio 2011
--                      Aggiunta chiamata a funzione FU_COMPATIBILITA_TARIFFA
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_TARIFFA( p_id_tariffa               CD_TARIFFA.ID_TARIFFA%TYPE,
                               p_id_prodotto_vendita      CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                               p_id_tipo_tariffa          CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                               p_id_formato               CD_TARIFFA.ID_FORMATO%TYPE,
                               p_id_misura_prd_vendita    CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                               p_id_listino               CD_TARIFFA.ID_LISTINO%TYPE,
                               p_id_tipo_cinema           CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                               p_importo                  CD_TARIFFA.IMPORTO%TYPE,
                               p_data_inizio              CD_TARIFFA.DATA_INIZIO%TYPE,
                               p_data_fine                CD_TARIFFA.DATA_FINE%TYPE,
                               p_flg_stagionale           CD_TARIFFA.FLG_STAGIONALE%TYPE,
                               p_esito                    OUT NUMBER,
                               p_piani_errati             OUT VARCHAR2)
IS
    v_temp                  INTEGER;
    v_esito                 INTEGER;
    v_esegui_ricalcolo      INTEGER;
    v_id_tipo_tariffa       CD_TARIFFA.ID_TIPO_TARIFFA%TYPE;
    v_id_formato            CD_TARIFFA.ID_FORMATO%TYPE;
    v_importo               CD_TARIFFA.IMPORTO%TYPE;
    v_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE;
    v_data_fine             CD_TARIFFA.DATA_FINE%TYPE;
    v_flg_stagionale        CD_TARIFFA.FLG_STAGIONALE%TYPE;
    DATE_CURSOR             PA_CD_TARIFFA.C_INTERVALLO_DATE;
    DATE_RECORD             PA_CD_TARIFFA.R_INTERVALLO_DATE;    
BEGIN
    p_esito := 1;
    v_esegui_ricalcolo:=0;
    SAVEPOINT SP_PR_MODIFICA_TARIFFA;
    SELECT ID_TIPO_TARIFFA, ID_FORMATO, IMPORTO, DATA_INIZIO, DATA_FINE, FLG_STAGIONALE
    INTO   v_id_tipo_tariffa, v_id_formato, v_importo, v_data_inizio, v_data_fine, v_flg_stagionale
    FROM   CD_TARIFFA
    WHERE  ID_TARIFFA=p_id_tariffa;
    v_temp:=PA_CD_TARIFFA.FU_COMPATIBILITA_TARIFFA(p_id_prodotto_vendita, p_id_listino, p_id_tariffa, p_data_inizio, p_data_fine,
                                                        p_id_misura_prd_vendita,p_id_tipo_tariffa,p_id_formato,p_id_tipo_cinema);
    IF(v_temp<0)THEN
        p_esito:=-200+v_temp;-- non inseribile
    ELSE
        SELECT COUNT(ID_PRODOTTO_VENDITA)
        INTO   v_temp
        FROM   CD_PRODOTTO_ACQUISTATO
        WHERE  ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND    DATA_INIZIO >= v_data_inizio
        AND    DATA_FINE <= v_data_fine;
        IF(v_temp>0)THEN
        --se esiste un prodotto acquistato modifico solo l'estensione temporale prolungangola
        --e modifico l'importo (nel qual caso invoco una RICALCOLA_TARIFFA che la momento non c'e')
            IF((v_id_tipo_tariffa<>p_id_tipo_tariffa)OR(v_id_formato<>p_id_formato)OR(v_flg_stagionale<>p_flg_stagionale))THEN
                p_esito:=-3;-- si puo' modificare solo data_fine, data_inizio e importo
            ELSE
                IF( ( v_data_inizio < p_data_inizio ) OR ( v_data_fine > p_data_fine ) )THEN -- restringimento
                    DBMS_OUTPUT.PUT_LINE('Restringo...');
                    DBMS_OUTPUT.PUT_LINE(v_data_inizio || '<' || p_data_inizio);
                    DBMS_OUTPUT.PUT_LINE('oppure');
                    DBMS_OUTPUT.PUT_LINE(v_data_fine || '>' || p_data_fine);
                    --Controllo che le date di destinazione siano comprese entro le date dove non
                    --vi sono comunicati
                    DATE_CURSOR := PA_CD_TARIFFA.FU_INTERV_MOD_TAR(v_data_inizio, v_data_fine, p_id_prodotto_vendita, p_id_misura_prd_vendita, p_id_tipo_cinema, p_id_formato);
                    FETCH DATE_CURSOR INTO DATE_RECORD;
                    IF ( ( DATE_RECORD.a_data_min IS NULL ) AND ( DATE_RECORD.a_data_max IS NULL ) ) THEN
                    --Se a_data_min e a_data_max sono null significa che non ci sono comunicati per la 
                    --tariffa indicata, dunque posso modificare senza problemi!
                        DBMS_OUTPUT.PUT_LINE('Non ci sono comunicati...');                  
                        IF( p_data_inizio != v_data_inizio ) THEN
                            v_temp:=PA_CD_TARIFFA.PR_ELIMINA_AMBIENTI( p_id_tariffa, v_data_inizio, p_data_inizio-1 );
                        END IF;                               
                        IF( p_data_fine != v_data_fine ) THEN
                            v_temp:=PA_CD_TARIFFA.PR_ELIMINA_AMBIENTI( p_id_tariffa, p_data_fine+1, v_data_fine );
                        END IF;
                        --Non modifico p_esito che rimane a 1!        
                    ELSE
                    DBMS_OUTPUT.PUT_LINE('Ci sono comunicati...'); 
                    --Devo effettuare controlli sulle date! a_data_min e a_data_max NON sono null
                        IF ( p_data_inizio <= DATE_RECORD.a_data_min ) THEN
                            --In questo caso la data iniziale di modifica p_data_inizio e' compresa
                            --tra v_data_inizio (esclusa) e a_data_min (inclusa)
                            --SI PUO' MODIFICARE!
                            --Controllo la data max...
                            IF ( p_data_fine >= DATE_RECORD.a_data_max ) THEN
                                --In questo caso la data finale di modifica p_data_fine e' compresa
                                --tra a_data_max (inclusa) e v_data_fine (esclusa)
                                --SI PUO' MODIFICARE!
                                --Non modifico p_esito che rimane a 1!
                                --Controlli separati inizio/fine perche potrei stare modificando solo da un lato
                                IF( p_data_inizio != v_data_inizio )THEN
                                    DBMS_OUTPUT.PUT_LINE('|->|TARIFFA|'); 
                                    v_temp:=PA_CD_TARIFFA.PR_ELIMINA_AMBIENTI( p_id_tariffa, v_data_inizio, p_data_inizio-1 );
                                END IF;                               
                                IF( p_data_fine != v_data_fine )THEN
                                    DBMS_OUTPUT.PUT_LINE('|TARIFFA|<-|'); 
                                    v_temp:=PA_CD_TARIFFA.PR_ELIMINA_AMBIENTI( p_id_tariffa, p_data_fine+1, v_data_fine );
                                END IF;                         
                            ELSE
                                --In questo caso la data finale di modifica p_data_fine e' minore
                                --di a_data_max
                                --NON SI PUO' MODIFICARE, CI SONO COMUNICATI COINVOLTI!
                                p_esito:=-4;                               
                            END IF;                        
                        ELSE
                            --In questo caso la data iniziale di modifica p_data_inizio e' maggiore
                            --di a_data_min
                            --NON SI PUO' MODIFICARE, CI SONO COMUNICATI COINVOLTI!
                             p_esito:=-4;                               
                        END IF;  
                    END IF;                
                    CLOSE DATE_CURSOR;           
                ELSE --allargamento
                    DBMS_OUTPUT.PUT_LINE('Allargo...');          
                    IF( p_data_inizio < v_data_inizio ) THEN --allargo a sx
                        DBMS_OUTPUT.PUT_LINE('<-|TARIFFA|'); 
                        v_temp:=PA_CD_TARIFFA.FU_GENERA_AMBIENTI( p_id_prodotto_vendita, p_id_listino, p_data_inizio, v_data_inizio-1 );
                    END IF;
                    IF( v_data_fine < p_data_fine ) THEN --allargo a dx
                        DBMS_OUTPUT.PUT_LINE('|TARIFFA|->'); 
                        v_temp:=PA_CD_TARIFFA.FU_GENERA_AMBIENTI( p_id_prodotto_vendita, p_id_listino, v_data_fine+1, p_data_fine );
                    END IF;
                    IF( v_importo <> p_importo ) THEN
                        v_esegui_ricalcolo:=1;
                    END IF;
                END IF;
            END IF;
        ELSE
        --se invece non esiste alcun prodotto acquistato legato alla tariffa posso modificare tutto
            --se restringo la tariffa, prima la cancello e poi la ricreo con i nuovi parametri
            IF( p_data_fine < v_data_fine ) THEN
                v_temp:=PA_CD_TARIFFA.PR_ELIMINA_AMBIENTI( p_id_tariffa, p_data_fine+1, v_data_fine );
            END IF;
            IF( p_data_inizio > v_data_inizio ) THEN
                v_temp:=PA_CD_TARIFFA.PR_ELIMINA_AMBIENTI( p_id_tariffa, v_data_inizio, p_data_inizio-1 );
            END IF;
            IF( p_data_inizio<v_data_inizio ) THEN --allargo a sx
                v_temp:=PA_CD_TARIFFA.FU_GENERA_AMBIENTI( p_id_prodotto_vendita, p_id_listino, p_data_inizio, v_data_inizio-1 );
            END IF;
            IF( v_data_fine<p_data_fine ) THEN --allargo a dx
                v_temp:=PA_CD_TARIFFA.FU_GENERA_AMBIENTI( p_id_prodotto_vendita, p_id_listino, v_data_fine+1, p_data_fine );
            END IF;
        END IF;
        IF(p_esito=1)THEN
            UPDATE CD_TARIFFA
            SET
                ID_PRODOTTO_VENDITA = NVL(p_id_prodotto_vendita,ID_PRODOTTO_VENDITA),
                ID_TIPO_TARIFFA = NVL(p_id_tipo_tariffa,ID_TIPO_TARIFFA),
                ID_FORMATO = NVL(p_id_formato,ID_FORMATO),
                ID_MISURA_PRD_VE = NVL(p_id_misura_prd_vendita,ID_MISURA_PRD_VE),
                ID_LISTINO = NVL(p_id_listino,ID_LISTINO),
                ID_TIPO_CINEMA = NVL(p_id_tipo_cinema,ID_TIPO_CINEMA),
                IMPORTO = NVL(p_importo,IMPORTO),
                DATA_INIZIO = NVL(p_data_inizio,DATA_INIZIO),
                DATA_FINE  = NVL(p_data_fine,DATA_FINE),
                FLG_STAGIONALE = NVL(p_flg_stagionale,FLG_STAGIONALE)
            WHERE ID_TARIFFA = p_id_tariffa;
            IF(v_esegui_ricalcolo<>0)THEN
                --dbms_output.PUT_LINE('ID_tariffa='|| p_id_tariffa);
                PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_TARIFFA(p_id_tariffa,v_importo, p_importo, p_piani_errati);
            END IF;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_esito:=-1;
        RAISE_APPLICATION_ERROR(-20013, 'Procedura SP_PR_MODIFICA_TARIFFA: Update non eseguita si e'' verificato un errore '||SQLERRM);
        ROLLBACK TO SP_PR_MODIFICA_TARIFFA;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TARIFFA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Esegue la ricerca di una tariffa in base ai filtri passati come input
--               il valore NULL corrisponde al Jolly
-- INPUT:
--    p_id_tariffa                  id della tariffa da ricercare
--    p_id_tipo_tariffa             id del tipo di tariffa da ricercare
--    p_id_prodotto_vendita         id del prodotto di vendita
--    p_id_listino                  id del listino
--    p_id_formato_acquistabile     id del formato acquistabile
--    p_data_inizio                 data inizio tariffa
--    p_data_fine                   data fine tariffa
-- OUTPUT: cursore con gli elemnti trovati
--         (importo tipo_tariffa prodotto_vendita listino formato_acquistabile
--                sconto_stagionale data_inizio data_fine)
-- NOTA BENE: il campo prodotto_vendita e' una stringa composta come segue
--        DESC_PRODOTTO -in- NOME_CIRCUITO -vendita in- DESC_MOD_VENDITA -tipo break- DESC_TIPO_BREAK -fascia- DESC_FASCIA -area Nielsen- DESC_AREA
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TARIFFA(  p_id_tariffa                CD_TARIFFA.ID_TARIFFA%TYPE,
                            p_id_tipo_tariffa           CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                            p_id_prodotto_vendita       CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                            p_id_listino                CD_TARIFFA.ID_LISTINO%TYPE,
                            p_id_formato_acquistabile   CD_TARIFFA.ID_FORMATO%TYPE,
                            p_data_inizio               CD_TARIFFA.DATA_INIZIO%TYPE,
                            p_data_fine                 CD_TARIFFA.DATA_FINE%TYPE)
                            RETURN C_TARIFFA
IS
    v_return_cursor     C_TARIFFA;
BEGIN
    OPEN v_return_cursor
        FOR
            SELECT ID_TARIFFA,IMPORTO,
            (SELECT DESC_TIPO_TARIFFA FROM CD_TIPO_TARIFFA WHERE ID_TIPO_TARIFFA=CD_TARIFFA.ID_TIPO_TARIFFA) TIPO_TARIFFA,
            (SELECT
                (SELECT DESC_PRODOTTO FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB=CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB) ||' -in- '||
                (SELECT NOME_CIRCUITO FROM CD_CIRCUITO WHERE ID_CIRCUITO = CD_PRODOTTO_VENDITA.ID_CIRCUITO ) ||' -vendita in- '||
                (SELECT DESC_MOD_VENDITA FROM CD_MODALITA_VENDITA WHERE ID_MOD_VENDITA=CD_PRODOTTO_VENDITA.ID_MOD_VENDITA) ||
                NVL2((SELECT DESC_TIPO_BREAK FROM CD_TIPO_BREAK WHERE ID_TIPO_BREAK=CD_PRODOTTO_VENDITA.ID_TIPO_BREAK),' -tipo break- '||
                     (SELECT DESC_TIPO_BREAK FROM CD_TIPO_BREAK WHERE ID_TIPO_BREAK=CD_PRODOTTO_VENDITA.ID_TIPO_BREAK),'')||
                NVL2((SELECT DESC_FASCIA FROM CD_FASCIA WHERE ID_FASCIA=CD_PRODOTTO_VENDITA.ID_FASCIA),' -fascia- '||
                     (SELECT DESC_FASCIA FROM CD_FASCIA WHERE ID_FASCIA=CD_PRODOTTO_VENDITA.ID_FASCIA),'')
             FROM CD_PRODOTTO_VENDITA  WHERE CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA=CD_TARIFFA.ID_PRODOTTO_VENDITA)PRODOTTO_VENDITA ,
            (SELECT DESC_LISTINO FROM CD_LISTINO WHERE ID_LISTINO=CD_TARIFFA.ID_LISTINO) LISTINO,
            (NVL2((SELECT TO_CHAR(ID_COEFF) FROM CD_FORMATO_ACQUISTABILE WHERE ID_FORMATO = CD_TARIFFA.ID_FORMATO AND ROWNUM =1),
                  (SELECT TO_CHAR(DURATA) FROM CD_COEFF_CINEMA WHERE ID_COEFF IN (SELECT ID_COEFF FROM CD_FORMATO_ACQUISTABILE WHERE ID_FORMATO = CD_TARIFFA.ID_FORMATO AND ROWNUM =1))||'"',
                  (SELECT DESCRIZIONE FROM CD_FORMATO_ACQUISTABILE WHERE ID_FORMATO = CD_TARIFFA.ID_FORMATO AND ROWNUM =1))) FORMATO_ACQUISTABILE,
            (SELECT PERC_SCONTO FROM CD_SCONTO_STAGIONALE WHERE ID_LISTINO = CD_TARIFFA.ID_LISTINO AND CD_TARIFFA.FLG_STAGIONALE='S' AND ROWNUM=1) SCONTO_STAGIONALE,
            DATA_INIZIO,
            DATA_FINE, DESC_TARIFFA, ID_LISTINO, ID_FORMATO, ID_TIPO_TARIFFA, 
            CD_TARIFFA.ID_TIPO_CINEMA, CD_TARIFFA.ID_PRODOTTO_VENDITA, CD_TARIFFA.ID_MISURA_PRD_VE, 
            FLG_STAGIONALE, CD_TIPO_CINEMA.DESC_TIPO_CINEMA,CD_UNITA_MISURA_TEMP.DESC_UNITA
            FROM 
                CD_TARIFFA,
                CD_TIPO_CINEMA,
                CD_MISURA_PRD_VENDITA,
                CD_UNITA_MISURA_TEMP
            WHERE  CD_TARIFFA.ID_TARIFFA=NVL(p_id_tariffa,CD_TARIFFA.ID_TARIFFA)
            AND    CD_TARIFFA.ID_TIPO_TARIFFA=NVL(p_id_tipo_tariffa,CD_TARIFFA.ID_TIPO_TARIFFA)
            AND    CD_TARIFFA.ID_PRODOTTO_VENDITA=NVL(p_id_prodotto_vendita,CD_TARIFFA.ID_PRODOTTO_VENDITA)
            AND    CD_TARIFFA.ID_LISTINO=NVL(p_id_listino,CD_TARIFFA.ID_LISTINO)
			AND    (CD_TARIFFA.ID_FORMATO=NVL(p_id_formato_acquistabile,CD_TARIFFA.ID_FORMATO) OR (p_id_formato_acquistabile IS NULL AND CD_TARIFFA.ID_FORMATO IS NULL))        
            AND    CD_TARIFFA.DATA_INIZIO>=NVL(p_data_inizio,CD_TARIFFA.DATA_INIZIO)
            AND    CD_TARIFFA.DATA_FINE<=NVL(p_data_fine,CD_TARIFFA.DATA_FINE)
            AND    CD_TARIFFA.ID_TIPO_CINEMA = CD_TIPO_CINEMA.ID_TIPO_CINEMA(+)
            AND    CD_TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
            AND    CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
            order by DATA_INIZIO desc;
    RETURN v_return_cursor;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_CERCA_TARIFFA: Si e'' verificato un errore: '||SQLERRM);
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TIPO_TARIFFA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Esegue la ricerca di una tipologia tariffa in base ai filtri passati come input
--               il valore NULL corrisponde al Jolly
-- INPUT:
--    p_id_tipo_tariffa             id del tipo di tariffa da ricercare
--    p_desc_tariffa                descriziojne anche parziale del tipo tariffa da cercare
--
-- OUTPUT: cursore con gli elemnti trovati
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TIPO_TARIFFA( p_id_tipo_tariffa    CD_TIPO_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                p_desc_tipo_tariffa  CD_TIPO_TARIFFA.DESC_TIPO_TARIFFA%TYPE)
                            RETURN C_TIPO_TARIFFA
IS
    v_return_cursor     C_TIPO_TARIFFA;
BEGIN
    OPEN v_return_cursor
        FOR
            SELECT ID_TIPO_TARIFFA, DESC_TIPO_TARIFFA
            FROM   CD_TIPO_TARIFFA
            WHERE  CD_TIPO_TARIFFA.ID_TIPO_TARIFFA=NVL(p_id_tipo_tariffa,CD_TIPO_TARIFFA.ID_TIPO_TARIFFA)
            AND    CD_TIPO_TARIFFA.DESC_TIPO_TARIFFA=NVL(p_desc_tipo_tariffa,CD_TIPO_TARIFFA.DESC_TIPO_TARIFFA);
    RETURN v_return_cursor;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_CERCA_TIPO_TARIFFA: Si e'' verificato un errore  '||SQLERRM);
        OPEN v_return_cursor
            FOR
                SELECT NULL,NULL FROM DUAL;
        RETURN v_return_cursor;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_TARIFFA
--
-- DESCRIZIONE: Esegue l'eliminazione di un tariffa dal sistema se non eistono prodotti acquistati
--              associati ad essa.
--              Con la cancellazione della tariffa vengono altresi' eliminati tutti gli ambienti di
--              vendita legati al circuito relativo che evidentemente non sono piu' necessari
--
-- INPUT:
--      p_id_tariffa    id della tariffa di cui tentare l'eliminazione
--
-- OUTPUT: esito:
--    1  Tariffa eliminata con tutti gli ambienti relativi (eventualmente presenti nel DB)
--    2  Eliminazione non eseguita per l'esistenza di almeno un prodotto acquistato associato alla tariffa
--   -1  Eliminazione non effettuata a causa di un errore
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:   Francesco Abbundo, Teoresi srl, Ottobre 2009
--              Antonio Colucci, Teoresi srl, luglio 2010 
--              Risolta anomalia sulla eliminazione di una tariffa: 
--              non veniva fatto il controllo sulla data per capire se la stessa era eliminabile 
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_TARIFFA(  p_id_tariffa        IN CD_TARIFFA.ID_TARIFFA%TYPE,
                               p_esito             OUT NUMBER)
IS
    v_temp                  INTEGER;
    v_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE;
    v_data_inizio_tariffa   DATE;
    v_data_fine_tariffa     DATE;
BEGIN
    SAVEPOINT SP_PR_ELIMINA_TARIFFA;
    --recupero l'intervallo di validita' della tariffa
    SELECT DATA_INIZIO, DATA_FINE
    INTO   v_data_inizio_tariffa, v_data_fine_tariffa
    FROM   CD_TARIFFA
    WHERE  ID_TARIFFA=p_id_tariffa;
    SELECT COUNT(*)
    INTO   v_temp
    FROM   CD_PRODOTTO_ACQUISTATO,CD_PRODOTTO_VENDITA, CD_TARIFFA 
    WHERE  CD_TARIFFA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
    AND    (CD_TARIFFA.ID_TIPO_TARIFFA = 1 OR CD_TARIFFA.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO)
    AND    CD_TARIFFA.ID_MISURA_PRD_VE = CD_PRODOTTO_ACQUISTATO.ID_MISURA_PRD_VE
    AND    CD_TARIFFA.ID_TARIFFA=p_id_tariffa
    AND    CD_PRODOTTO_ACQUISTATO.DATA_INIZIO>=V_DATA_INIZIO_TARIFFA 
    AND    CD_PRODOTTO_ACQUISTATO.DATA_FINE<=V_DATA_FINE_TARIFFA;
--se non esistono prodotti acquistati per la tariffa posso cancellare tariffa e ambienti di vendita relativi
    IF(v_temp=0)THEN
        v_temp:=PA_CD_TARIFFA.PR_ELIMINA_AMBIENTI( p_id_tariffa,v_data_inizio_tariffa,v_data_fine_tariffa);
        --qui elimino le tariffe
        DELETE FROM CD_TARIFFA
        WHERE  CD_TARIFFA.ID_TARIFFA = p_id_tariffa;
        p_esito := 1;
    ELSE
        p_esito := 2;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_ELIMINA_TARIFFA: Delete tariffa >'||p_id_tariffa||'< non eseguita, si e'' verificato un errore. '||SQLERRM);
        p_esito:=-1;
        ROLLBACK TO SP_PR_ELIMINA_TARIFFA;
END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_TARIFFA
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- INPUT:
--  p_id_prodotto_vendita   identificativo del prodotto di vendita
--  p_id_tipo_tariffa       identificativo del tipo di tariffa
--  p_id_formato            formato della tariffa
--  p_id_misura_prd_vendita taglio temporale al quale e associata la tariffa
--  p_id_listino            identificativo del listino
--  p_id_tipo_cinema        identificativo del tipo di cinema
--  p_importo               importo della tariffa
--  p_data_inizio           data inizio validita della tariffa
--  p_data_fine             data fine validita della tariffa
--
-- OUTPUT: varchar che contiene i parametri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_TARIFFA(     p_id_prodotto_vendita      CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                p_id_tipo_tariffa          CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                p_id_formato               CD_TARIFFA.ID_FORMATO%TYPE,
                                p_id_misura_prd_vendita    CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                p_id_listino               CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_tipo_cinema           CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                                p_importo                  CD_TARIFFA.IMPORTO%TYPE,
                                p_data_inizio              CD_TARIFFA.DATA_INIZIO%TYPE,
                                p_data_fine                CD_TARIFFA.DATA_FINE%TYPE,
                                p_flag_stagionale          CD_TARIFFA.FLG_STAGIONALE%TYPE
                                )  RETURN VARCHAR2
IS
BEGIN
   IF v_stampa_tariffa = 'ON' THEN
     RETURN 'ID_PRODOTTO_VENDITA: '          || p_id_prodotto_vendita            || ', ' ||
            'ID_TIPO_TARIFFA: '|| p_id_tipo_tariffa    || ', ' ||
            'ID_FORMATO: '  || p_id_formato        || ', ' ||
            'ID_MISURA_PRD_VENDITA: ' || p_id_misura_prd_vendita        || ', ' ||
            'ID_LISTINO: '           || p_id_listino                || ', ' ||
            'ID_TIPO_CINEMA: '          || p_id_tipo_cinema           || ', ' ||
            'IMPORTO: '          || p_importo           || ', ' ||
            'DATA_INIZIO: '|| p_data_inizio    || ', ' ||
            'DATA_FINE: '|| p_data_fine    || ', ' ||
            'FLAG_STAGIONALE: '  ||p_flag_stagionale;
   END IF;
END  FU_STAMPA_TARIFFA;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_FORMATO_ACQUIST
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo formato acquistabile nel sistema
--               passando eventualmente dal coefficiente cinema
--
-- OPERAZIONI:
--   1) Se il tipo formato e 'Filmato'
--       1.1)Censisce un nuovo coefficiente cinema a condizione che non esista gia,
--             altrimenti non fa nulla e restituisce un esito coerente
--       1.2)Lega il coefficiente cinema appena creato al formato acquistabile (CD_FORMATO_ACQUISTABILE)
--   2)Se non e di tipo 'Filmato'
--       2.1)Censisco un nuovo formato acquistabile
-- INPUT:
--  p_tipo_formato    Tipo formato
--  p_desc_formato    Descrizione formato
--  p_id_coeff        id del coefficiente
--  p_dim_lunghezza   lunghezza
--  p_dim_larghezza    larghezza
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_FORMATO_ACQUIST(p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                       p_durata            CD_COEFF_CINEMA.DURATA%TYPE,
                                       p_aliquota          CD_COEFF_CINEMA.ALIQUOTA%TYPE,
                                       p_data_inizio_val   CD_COEFF_CINEMA.DATA_INIZIO_VAL%TYPE,
                                       p_data_fine_val     CD_COEFF_CINEMA.DATA_FINE_VAL%TYPE,
                                       p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
                                       p_esito             OUT NUMBER)
IS
v_tipo_formato CD_TIPO_FORMATO.TIPO_FORMATO%TYPE;
v_curval_coeff CD_COEFF_CINEMA.ID_COEFF%TYPE;
v_count_coeff  CD_COEFF_CINEMA.DURATA%TYPE;
BEGIN
    p_esito     := 1;
    v_curval_coeff :=0;
--
    SAVEPOINT SP_PR_INSERISCI_FORMATO_ACQU;
--
     SELECT TIPO_FORMATO INTO v_tipo_formato FROM CD_TIPO_FORMATO
            WHERE ID_TIPO_FORMATO=p_id_tipo_formato;
    IF(v_tipo_formato='Filmato')THEN
    --Censisco un nuovo coefficiente e un nuovo formato acquistabile
        SELECT COUNT(ID_COEFF) INTO v_count_coeff FROM CD_COEFF_CINEMA
            WHERE DURATA = p_durata
            AND   (DATA_FINE_VAL IS NULL OR DATA_FINE_VAL >= p_data_inizio_val);
        IF(v_count_coeff >0 )THEN
        --Coefficiente gia esistente - Non inserisco
        p_esito := -2;
        ELSE
            INSERT INTO CD_COEFF_CINEMA
            (
                DURATA,
                ALIQUOTA,
                DATA_INIZIO_VAL,
                DATA_FINE_VAL
            )
            VALUES
            (
                p_durata,
                p_aliquota,
                p_data_inizio_val,
                p_data_fine_val
            );
    --
            SELECT ID_COEFF INTO v_curval_coeff FROM CD_COEFF_CINEMA
            WHERE DURATA = p_durata
            AND   ALIQUOTA = p_aliquota
            AND   DATA_INIZIO_VAL = p_data_inizio_val
            AND   (p_data_fine_val is null or DATA_FINE_VAL = p_data_fine_val);
    --
            INSERT INTO CD_FORMATO_ACQUISTABILE
            (
                ID_COEFF,
                DESCRIZIONE,
                ID_TIPO_FORMATO
            )
            VALUES
            (
                v_curval_coeff,
                p_descrizione,
                p_id_tipo_formato
            );
            p_esito := SQL%ROWCOUNT;
     END IF;
--
--
    ELSE
        INSERT INTO CD_FORMATO_ACQUISTABILE
        (
            DESCRIZIONE,
            ID_TIPO_FORMATO
        )
        VALUES
        (
            p_descrizione,
            p_id_tipo_formato
        );
        p_esito := SQL%ROWCOUNT;
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_esito := -11;
            RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_INSERISCI_FORMATO_ACQUIST: Insert non eseguita, verificare i parametri - '||SQLERRM);
        ROLLBACK TO SP_PR_INSERISCI_FORMATO_ACQU;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_FORMATO_ACQUIST
--
-- DESCRIZIONE:  Esegue l'aggiornamento di un formato acquisto
--
-- OPERAZIONI:
--   Update
--
-- INPUT:
--  id_formato        id del  formato
--  p_tipo_formato    Tipo formato
--  p_desc_formato    Descrizione formato
--  p_id_coeff        id del coefficiente
--  p_dim_lunghezza   lunghezza
--  p_dim_larghezza   larghezza
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Update non eseguita: i parametri per l'Update non sono coerenti
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, 01 Ottobre 2009 - Refactoring
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_FORMATO_ACQUIST( p_id_formato        CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
                                       p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                       p_id_coeff          CD_FORMATO_ACQUISTABILE.ID_COEFF%TYPE,
                                       p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
                                       p_flg_valid         CD_FORMATO_ACQUISTABILE.FLG_VALID%TYPE,
                                       p_data_fine_val         CD_COEFF_CINEMA.DATA_FINE_VAL%TYPE,
                                       p_esito             OUT NUMBER)
IS

BEGIN -- PR_MODIFICA_FORMATO_ACQUIST
    p_esito := 1;
    SAVEPOINT SP_PR_MODIFICA_FORMATO_ACQUIST;
    UPDATE CD_FORMATO_ACQUISTABILE
        SET
            ID_COEFF = (nvl(p_id_coeff, ID_COEFF)),
            DESCRIZIONE = (nvl(p_descrizione, DESCRIZIONE)),
            ID_TIPO_FORMATO = (nvl(p_id_tipo_formato, ID_TIPO_FORMATO)),
            FLG_VALID = (nvl(p_flg_valid, FLG_VALID))
        WHERE ID_FORMATO = p_id_formato;
--
    UPDATE CD_COEFF_CINEMA
        SET
            DATA_FINE_VAL = (nvl(p_data_fine_val,DATA_FINE_VAL))
        WHERE
            ID_COEFF = p_id_coeff;
--    UPDATE CD_TIPO_FORMATO SET
--           TIPO_FORMATO = (nvl(p_tipo_formato, TIPO_FORMATO)),
--            DESC_FORMATO = (nvl(p_desc_formato, DESC_FORMATO))
--        WHERE ID_TIPO_FORMATO =
--        (SELECT ID_TIPO_FORMATO FROM CD_FORMATO_ACQUISTABILE
--        WHERE ID_FORMATO = p_id_formato);
    p_esito := SQL%ROWCOUNT;

    EXCEPTION
        WHEN OTHERS THEN
            p_esito := -11;
            RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_MODIFICA_FORMATO_ACQUIST: Update non eseguita, verificare la coerenza dei parametri'||FU_STAMPA_FORMATO_ACQUIST(p_id_tipo_formato,
                                                                                                                                                                          p_id_coeff,
                                                                                                                                                                          p_descrizione));
        ROLLBACK TO SP_PR_MODIFICA_FORMATO_ACQUIST;
END;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_FORMATO_ACQUIST
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un formato acquistabile dal sistema
--
-- OPERAZIONI:
--   1) Controllo impatti derivanti dalla eliminazione della tariffa
--   2) Elimina il formato acquistabile e il relativo coefficiente
--      dalla tabella CD_COEFF_CINEMA
--
-- INPUT:
--      p_id_formato    id del formato acquistabile
--
-- OUTPUT: esito:
--    n  numero di record eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--   -2  Eliminazione non eseguita: il formato selezionato e usato in una tariffa
--   -3  Eliminazione non eseguita: il formato e stato utilizzato in un prodotto acquistato
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Giugno 2009
--
--  MODIFICHE:      Antonio Colucci, Teoresi srl, 5 Ottobre 2009
--                  Refactoring: Valutazione Eliminazione Formato Acquistabile nel
--                  caso sia coinvolte in offerte commerciali o vendite
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_FORMATO_ACQUIST(p_id_formato        IN CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
                                     p_esito             OUT NUMBER)
IS
--
v_count_tariffe NUMBER := 0;
v_count_prodotti_acq NUMBER := 0;
--
BEGIN -- PR_ELIMINA_FORMATO_ACQUIST
    p_esito     := 1;
    SAVEPOINT SP_PR_ELIMINA_FORMATO_ACQ;
    -- Controllo eventuale coinvolgimento del formato selezionato in offerte commerciali
    SELECT COUNT(ID_FORMATO) INTO v_count_tariffe FROM CD_TARIFFA
        WHERE ID_FORMATO = p_id_formato;
    IF(v_count_tariffe >0 )THEN
    --Formato non eliminabile in quanto coinvolto in una offerta commerciale
        p_esito     := -2;
    ELSE
    --Controllo eventuale coinvolgimento del formato in vendite
        SELECT COUNT(ID_FORMATO) INTO v_count_prodotti_acq FROM CD_PRODOTTO_ACQUISTATO
            WHERE ID_FORMATO = p_id_formato;
        IF(v_count_prodotti_acq > 0)THEN
        --Formato non eliminabile in quanto coinvolto in una o piu vendite
            p_esito :=  -3;
        ELSE
            -- EFFETTUA L'ELIMINAZIONE DEL COEFFICIENTE da CD_COEFF_CINEMA
            DELETE FROM CD_COEFF_CINEMA
            WHERE ID_COEFF = (SELECT ID_COEFF FROM CD_FORMATO_ACQUISTABILE
                              WHERE ID_FORMATO = p_id_formato);
            -- EFFETTUA L'ELIMINAZIONE DEL FORMATO da CD_COEFF_CINEMA
            DELETE FROM CD_FORMATO_ACQUISTABILE
            WHERE ID_FORMATO = p_id_formato;
            p_esito := SQL%ROWCOUNT;
        END IF;
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_ELIMINA_FORMATO_ACQUIST: Delete non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_ELIMINA_FORMATO_ACQ;
END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_FORMATO_ACQUIST
-- DESCRIZIONE:  la funzione si occupa di formattare i valori passati
--
-- INPUT: parametri del formato acquistabile
--
-- OUTPUT: varchar che contiene i parametri formattati
--
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_STAMPA_FORMATO_ACQUIST(p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                   p_id_coeff          CD_FORMATO_ACQUISTABILE.ID_COEFF%TYPE,
                                   p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE)
                                   RETURN VARCHAR2
IS
BEGIN
    IF v_stampa_tariffa = 'ON' THEN
        RETURN  'ID_TIPO_FORMATO: '    || p_id_tipo_formato   || ', ' ||
                'ID_COEFF: '        || p_id_coeff       || ', ' ||
                'DESCRIZIONE: '   || p_descrizione;
    END IF;
END  FU_STAMPA_FORMATO_ACQUIST;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_FORMATO_ACQUIST
--
-- INPUT:  Id del formato acquistabile
-- OUTPUT: Restituisce il dettaglio del formato acquistabile
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_FORMATO_ACQUIST (p_id_formato      CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE )
                               RETURN C_DETTAGLIO_FORMATO_ACQUIST

IS
    c_formato_acquistabile_return C_DETTAGLIO_FORMATO_ACQUIST;
BEGIN
    OPEN c_formato_acquistabile_return  -- apre il cursore dettaglio del formato acquistabile
        FOR
            SELECT  FAQ.ID_FORMATO, TF.TIPO_FORMATO, TF.DESC_FORMATO, FAQ.ID_TIPO_FORMATO,
                    FAQ.ID_COEFF, COEFF.DURATA,COEFF.ALIQUOTA, FAQ.DESCRIZIONE, FAQ.FLG_VALID,
                    COEFF.DATA_INIZIO_VAL, COEFF.DATA_FINE_VAL
            FROM    CD_FORMATO_ACQUISTABILE FAQ, CD_COEFF_CINEMA COEFF, CD_TIPO_FORMATO TF
            WHERE   FAQ.ID_FORMATO = p_id_formato
            AND     TF.ID_TIPO_FORMATO = FAQ.ID_TIPO_FORMATO
            AND     COEFF.ID_COEFF(+) = FAQ.ID_COEFF;

    RETURN c_formato_acquistabile_return;
    EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_DETTAGLIO_FORMATO_ACQUIST: SI E'' VERIFICATO UN ERRORE');
END FU_DETTAGLIO_FORMATO_ACQUIST;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_COEFFICIENTI CINEMA
--
-- OUTPUT: Restituisce l'elenco dei coefficienti cinema disponibili a sistema
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, 02/10/2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_COEFF_CINEMA RETURN C_COEFF_CINEMA
--
IS
    c_coeff_cinema_return C_COEFF_CINEMA;
BEGIN
    OPEN c_coeff_cinema_return
        FOR
           SELECT DISTINCT COEFF_CINEMA.ID_COEFF, COEFF_CINEMA.DURATA, COEFF_CINEMA.ALIQUOTA,
       COEFF_CINEMA.DATA_INIZIO_VAL, COEFF_CINEMA.DATA_FINE_VAL
       FROM CD_COEFF_CINEMA COEFF_CINEMA, (
                SELECT DISTINCT ID_COEFF FROM CD_FORMATO_ACQUISTABILE
                WHERE FLG_VALID = 'S') V_FORMATI
       WHERE COEFF_CINEMA.ID_COEFF  <> V_FORMATI.ID_COEFF
       AND COEFF_CINEMA.DATA_FINE_VAL IS NULL OR COEFF_CINEMA.DATA_FINE_VAL >= SYSDATE
       ORDER BY DURATA;
--
    RETURN c_coeff_cinema_return;
    EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_CERCA_COEFF_CINEMA: SI E'' VERIFICATO UN ERRORE');
END FU_CERCA_COEFF_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_tipo_formato        Tipo formato
--  p_desc_tipo_formato   Descrizione tipo formato
--  p_id_coeff            id del coefficiente
--  p_descrizione         descrizione anche parziale del formato acquistabile
--
-- OUTPUT: Restituisce i formati acquistati che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_FORMATO_ACQUIST( p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                   p_id_coeff          CD_FORMATO_ACQUISTABILE.ID_COEFF%TYPE,
                                   p_descrizione       CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE,
                                   p_flg_valid         CD_FORMATO_ACQUISTABILE.FLG_VALID%TYPE
                                   )
                                   RETURN C_FORMATO_ACQUISTABILE
IS
    c_formato_acquistabile_return C_FORMATO_ACQUISTABILE;
BEGIN
    IF(p_flg_valid = 'S')THEN
    --Recuper Solo i Formati Validi
        OPEN c_formato_acquistabile_return
        FOR
            SELECT  FAQ.ID_FORMATO, TF.TIPO_FORMATO, TF.DESC_FORMATO,FAQ.ID_TIPO_FORMATO,
                    FAQ.ID_COEFF, COEFF.DURATA,COEFF.ALIQUOTA, FAQ.DESCRIZIONE, FAQ.FLG_VALID,
                    COEFF.DATA_INIZIO_VAL, COEFF.DATA_FINE_VAL
            FROM    CD_FORMATO_ACQUISTABILE FAQ, CD_COEFF_CINEMA COEFF, CD_TIPO_FORMATO TF
            WHERE   COEFF.ID_COEFF(+) = FAQ.ID_COEFF
                AND FAQ.FLG_VALID = p_flg_valid
                AND (COEFF.DATA_FINE_VAL IS NULL OR COEFF.DATA_FINE_VAL>=SYSDATE)
                AND (p_id_tipo_formato IS NULL OR FAQ.ID_TIPO_FORMATO =p_id_tipo_formato)
                AND TF.ID_TIPO_FORMATO = FAQ.ID_TIPO_FORMATO
                AND (p_id_coeff IS NULL OR FAQ.ID_COEFF  =  p_id_coeff)
                AND (p_descrizione IS NULL OR upper(FAQ.DESCRIZIONE)  like upper('%'||p_descrizione||'%'))
                ORDER BY TF.DESC_FORMATO, COEFF.DURATA;
    ELSE
        IF(p_flg_valid IS NULL)THEN
        --Recupero tutti i formati disponibili
             OPEN c_formato_acquistabile_return
            FOR
            SELECT  FAQ.ID_FORMATO, TF.TIPO_FORMATO, TF.DESC_FORMATO,FAQ.ID_TIPO_FORMATO,
                    FAQ.ID_COEFF, COEFF.DURATA,COEFF.ALIQUOTA, FAQ.DESCRIZIONE, FAQ.FLG_VALID,
                    COEFF.DATA_INIZIO_VAL, COEFF.DATA_FINE_VAL
            FROM    CD_FORMATO_ACQUISTABILE FAQ, CD_COEFF_CINEMA COEFF, CD_TIPO_FORMATO TF
            WHERE   COEFF.ID_COEFF(+) = FAQ.ID_COEFF
                AND (p_id_tipo_formato IS NULL OR FAQ.ID_TIPO_FORMATO =p_id_tipo_formato)
                AND TF.ID_TIPO_FORMATO = FAQ.ID_TIPO_FORMATO
                AND (p_id_coeff IS NULL OR FAQ.ID_COEFF  =  p_id_coeff)
                AND (p_descrizione IS NULL OR upper(FAQ.DESCRIZIONE)  like upper('%'||p_descrizione||'%'))
                ORDER BY TF.DESC_FORMATO, COEFF.DURATA;
        ELSE
        --Recupero i Formati NON Validi
           OPEN c_formato_acquistabile_return
        FOR
            SELECT  FAQ.ID_FORMATO, TF.TIPO_FORMATO, TF.DESC_FORMATO,FAQ.ID_TIPO_FORMATO,
                    FAQ.ID_COEFF, COEFF.DURATA,COEFF.ALIQUOTA, FAQ.DESCRIZIONE, FAQ.FLG_VALID,
                    COEFF.DATA_INIZIO_VAL, COEFF.DATA_FINE_VAL
            FROM    CD_FORMATO_ACQUISTABILE FAQ, CD_COEFF_CINEMA COEFF, CD_TIPO_FORMATO TF
            WHERE   COEFF.ID_COEFF(+) = FAQ.ID_COEFF
                AND (FAQ.FLG_VALID = p_flg_valid or COEFF.DATA_FINE_VAL <= SYSDATE)
                AND (p_id_tipo_formato IS NULL OR FAQ.ID_TIPO_FORMATO =p_id_tipo_formato)
                AND TF.ID_TIPO_FORMATO = FAQ.ID_TIPO_FORMATO
                AND (p_id_coeff IS NULL OR FAQ.ID_COEFF  =  p_id_coeff)
                AND (p_descrizione IS NULL OR upper(FAQ.DESCRIZIONE)  like upper('%'||p_descrizione||'%'))
                ORDER BY TF.DESC_FORMATO, COEFF.DURATA;
        END IF;
--
    END IF;

--
    RETURN c_formato_acquistabile_return;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_CERCA_FORMATO_ACQUIST: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_FORMATO_ACQUIST(p_id_tipo_formato,
                                                                                                                                                                            p_id_coeff, p_descrizione));
END FU_CERCA_FORMATO_ACQUIST;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TIPI_FORMATO_ACQUIST
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_id_tipo_formato        id Tipo formato
--  p_desc_formato           Descrizione tipo formato
--
-- OUTPUT: Restituisce i tipi di formati acquistati che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, 02 Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TIPI_FORMATO_ACQUIST( p_id_tipo_formato   CD_TIPO_FORMATO.ID_TIPO_FORMATO%TYPE,
                                        p_tipo_formato      CD_TIPO_FORMATO.TIPO_FORMATO%TYPE,
                                        p_desc_formato      CD_TIPO_FORMATO.DESC_FORMATO%TYPE)
                                        RETURN C_TIPO_FORMATO
IS
    c_tipo_formato_return C_TIPO_FORMATO;
BEGIN
    OPEN c_tipo_formato_return
        FOR
            SELECT TIPO_FORMATO.ID_TIPO_FORMATO,
                   TIPO_FORMATO.TIPO_FORMATO, TIPO_FORMATO.DESC_FORMATO
                FROM CD_TIPO_FORMATO TIPO_FORMATO
                     WHERE p_id_tipo_formato IS NULL OR TIPO_FORMATO.ID_TIPO_FORMATO = p_id_tipo_formato
                     AND   p_tipo_formato IS NULL OR UPPER(TIPO_FORMATO.TIPO_FORMATO) LIKE '%'||UPPER(p_tipo_formato)||'%'
                     AND   p_desc_formato IS NULL OR UPPER(TIPO_FORMATO.DESC_FORMATO) LIKE '%'||UPPER(p_desc_formato)||'%';
--
    RETURN c_tipo_formato_return;
--
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_CERCA_TIPI_FORMATO_ACQUIST: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI - ID_TIPO_FORMATO:'||p_id_tipo_formato||' p_desc_formato:'||p_desc_formato );
END FU_CERCA_TIPI_FORMATO_ACQUIST;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_FORMATO_TAB
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: Restituisce i formati acquistati collegati ad una tariffa
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_FORMATO_TAB RETURN C_FORMATO_TAB IS
v_formato_return C_FORMATO_TAB;
BEGIN
--
    OPEN v_formato_return
    FOR
        SELECT  ACQ.ID_FORMATO, COEFF.DURATA
        FROM  CD_FORMATO_ACQUISTABILE ACQ, CD_COEFF_CINEMA COEFF
        WHERE (COEFF.DATA_FINE_VAL IS NULL OR COEFF.DATA_FINE_VAL < sysdate)
        AND ACQ.ID_COEFF = COEFF.ID_COEFF
        AND ACQ.ID_TIPO_FORMATO = 1
        ORDER BY COEFF.DURATA;
    RETURN v_formato_return;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_GET_FORMATO_TAB: SI E'' VERIFICATO UN ERRORE');
END FU_GET_FORMATO_TAB;

FUNCTION FU_GET_ALIQUOTA(p_id_formato  CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE) RETURN NUMBER IS
    c_aliquota NUMBER;
BEGIN
            BEGIN
            SELECT  COEFF.ALIQUOTA 
            INTO c_aliquota
            FROM    CD_COEFF_CINEMA COEFF,  CD_FORMATO_ACQUISTABILE FAQ
            WHERE FAQ.ID_FORMATO = p_id_formato
            AND FAQ.ID_COEFF = COEFF.ID_COEFF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                c_aliquota := 1;
            END;    
    RETURN c_aliquota;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_GET_ALIQUOTA: SI E'' VERIFICATO UN ERRORE');

END FU_GET_ALIQUOTA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_GIORNI_TRASCORSI
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  restituisce il numero di giorni, dati la data inizio e una misura temporale (settimana, mese ecc)
-- INPUT:
--  p_data_inizio        Data di inizio del periodo
--  p_unita_temp         Unita temporale
-- OUTPUT: Restituisce il numero di giorni
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
/*FUNCTION FU_GET_GIORNI_TRASCORSI(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, p_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE) RETURN NUMBER IS
v_num_giorni NUMBER;
v_data_temp CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
BEGIN
   IF p_unita_temp = 1 THEN
      v_num_giorni := 1;
   ELSIF p_unita_temp = 2 THEN
      v_num_giorni := 7;
   ELSIF p_unita_temp = 3 THEN
      SELECT add_months(p_data_inizio -1, 1) INTO v_data_temp FROM dual;
      v_num_giorni := v_data_temp - p_data_inizio + 1;
   ELSIF p_unita_temp = 4 THEN
      SELECT add_months(p_data_inizio -1, 2) INTO v_data_temp FROM dual;
      v_num_giorni := v_data_temp - p_data_inizio + 1;
   ELSIF p_unita_temp = 5 THEN
      SELECT add_months(p_data_inizio -1, 3) INTO v_data_temp FROM dual;
      v_num_giorni := v_data_temp - p_data_inizio + 1;
   ELSIF p_unita_temp = 6 THEN
      SELECT add_months(p_data_inizio -1, 4) INTO v_data_temp FROM dual;
      v_num_giorni := v_data_temp - p_data_inizio + 1;
   ELSIF p_unita_temp = 7 THEN
      SELECT add_months(p_data_inizio -1, 6) INTO v_data_temp FROM dual;
      v_num_giorni := v_data_temp - p_data_inizio + 1;
   ELSIF p_unita_temp = 8 THEN
      SELECT add_months(p_data_inizio -1, 12) INTO v_data_temp FROM dual;
      v_num_giorni := v_data_temp - p_data_inizio + 1;
   ELSIF p_unita_temp = 9 THEN
      v_num_giorni := 2;
   ELSIF p_unita_temp = 11 THEN
      v_num_giorni := 14;      
   ELSIF p_unita_temp = 12 THEN
        v_num_giorni := 15;
   ELSIF p_unita_temp = 13 THEN
        v_num_giorni := 8;
   ELSIF p_unita_temp = 14 THEN
        v_num_giorni := 3;     
   END IF;
RETURN v_num_giorni;
  EXCEPTION
WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20013, 'FU_GET_GIORNI_TRASCORSI: SI E'' VERIFICATO UN ERRORE');

END FU_GET_GIORNI_TRASCORSI;--*/


FUNCTION FU_GET_GIORNI_TRASCORSI(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, p_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE) RETURN NUMBER IS
v_num_giorni number;
v_data_temp        cd_prodotto_acquistato.data_inizio%type;
v_numero_di_giorni cd_unita_misura_temp.numero_di_giorni%type;
v_numero_di_mesi   cd_unita_misura_temp.numero_di_mesi%type;
BEGIN
   --dbms_output.PUT_LINE('FU_GET_GIORNI_TRASCORSI');
   select numero_di_giorni,numero_di_mesi  
   into   v_numero_di_giorni,v_numero_di_mesi
   from   cd_unita_misura_temp
   where  id_unita = p_unita_temp;
   if( v_numero_di_giorni = 0 and v_numero_di_mesi = 0) then
      RAISE_APPLICATION_ERROR(-20013,'Numero di giorni e numero di mesi a 0 per la misura temporale (id_unita) :'|| p_unita_temp);
   else
      if(v_numero_di_mesi != 0) then
         --SELECT add_months(p_data_inizio -1, v_numero_di_mesi) INTO v_data_temp FROM dual;
         v_data_temp := add_months(p_data_inizio -1, v_numero_di_mesi);
         v_num_giorni := v_data_temp - p_data_inizio + 1;
      else
        v_num_giorni :=v_numero_di_giorni;      
      end if;
   end if;
  RETURN v_num_giorni;
  EXCEPTION
WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20013, 'FU_GET_GIORNI_TRASCORSI: SI E'' VERIFICATO UN ERRORE , ERRORE :'||SQLERRM);

END FU_GET_GIORNI_TRASCORSI;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_MAGGIORAZIONI
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: Restituisce tutte le maggiorazioni disponibili
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_MAGGIORAZIONI(p_id_tipo_magg CD_MAGGIORAZIONE.ID_TIPO_MAGG%TYPE) RETURN C_MAGGIORAZIONE IS
v_magg_return C_MAGGIORAZIONE;
BEGIN
--
    OPEN v_magg_return
    FOR
        SELECT  CD_MAGGIORAZIONE.ID_MAGGIORAZIONE, CD_MAGGIORAZIONE.DESCRIZIONE,
                CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE, 0 AS IMPORTO,
                CD_MAGGIORAZIONE.ID_TIPO_MAGG, CD_TIPO_MAGG.TIPO_MAGG_DESC
        FROM  CD_MAGGIORAZIONE, CD_TIPO_MAGG
        WHERE CD_TIPO_MAGG.ID_TIPO_MAGG = CD_MAGGIORAZIONE.ID_TIPO_MAGG
        AND (p_id_tipo_magg IS NULL OR CD_MAGGIORAZIONE.ID_TIPO_MAGG = p_id_tipo_magg);
    RETURN v_magg_return;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_GET_MAGGIORAZIONI: SI E'' VERIFICATO UN ERRORE');
END FU_GET_MAGGIORAZIONI;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_POSIZIONI_RIGORE
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: Restituisce tutte le posizioni di rigore disponibili
--
-- REALIZZATORE  Simone Bottani, Altran, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_POSIZIONI_RIGORE RETURN C_POSIZIONE_RIGORE IS
v_pos_rigore_return C_POSIZIONE_RIGORE;
BEGIN
--
    OPEN v_pos_rigore_return
    FOR
        SELECT  POS.COD_POSIZIONE, POS.DESCRIZIONE,
                MAG.PERCENTUALE_VARIAZIONE
        FROM  CD_POSIZIONE_RIGORE POS, CD_MAGGIORAZIONE MAG
        WHERE MAG.ID_MAGGIORAZIONE = 1;
    RETURN v_pos_rigore_return;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_GET_POSIZIONI_RIGORE: SI E'' VERIFICATO UN ERRORE');
END FU_GET_POSIZIONI_RIGORE;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_MAGGIORAZIONI_PRODOTTO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: Restituisce tutte le maggiorazioni disponibili
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_MAGGIORAZIONI_PRODOTTO(
          p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_MAGGIORAZIONE IS
v_magg_return C_MAGGIORAZIONE;
BEGIN
--
    OPEN v_magg_return
    FOR
        SELECT  CD_MAGGIORAZIONE.ID_MAGGIORAZIONE,
                CD_MAGGIORAZIONE.DESCRIZIONE,
                CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE,
                FU_CALCOLA_MAGGIORAZIONE(CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
                CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE) AS IMPORTO,
                CD_MAGGIORAZIONE.ID_TIPO_MAGG,
                CD_TIPO_MAGG.TIPO_MAGG_DESC
        FROM   CD_TIPO_MAGG, CD_MAGGIORAZIONE, CD_MAGG_PRODOTTO, CD_PRODOTTO_ACQUISTATO
        WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
        AND CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE = CD_MAGGIORAZIONE.ID_MAGGIORAZIONE
        AND CD_TIPO_MAGG.ID_TIPO_MAGG = CD_MAGGIORAZIONE.ID_TIPO_MAGG;
    RETURN v_magg_return;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_GET_MAGGIORAZIONI_PRODOTTO: SI E'' VERIFICATO UN ERRORE');
END FU_GET_MAGGIORAZIONI_PRODOTTO;

FUNCTION FU_CALCOLA_MAGGIORAZIONE(p_tariffa NUMBER, p_percentuale NUMBER) RETURN NUMBER IS
  v_importo NUMBER;
  BEGIN
    v_importo := ROUND(p_tariffa * p_percentuale / 100,2);
    RETURN v_importo;
END FU_CALCOLA_MAGGIORAZIONE;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_TARIFFA_RIPARAMETRATA
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: Effettua la riparametrizzazione di una tariffa
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_TARIFFA_RIPARAMETRATA(p_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE, p_id_formato CD_TARIFFA.ID_FORMATO%TYPE) RETURN NUMBER IS

  v_importo NUMBER;
  v_tipo_tariffa CD_TARIFFA.ID_TIPO_TARIFFA%TYPE;
  v_aliquota CD_COEFF_CINEMA.ALIQUOTA%TYPE;
  BEGIN
    SELECT CD_TARIFFA.ID_TIPO_TARIFFA, CD_TARIFFA.IMPORTO
    INTO v_tipo_tariffa, v_importo
    FROM CD_TARIFFA
    WHERE CD_TARIFFA.ID_TARIFFA = p_id_tariffa;
--
    IF v_tipo_tariffa = 1 THEN
        IF p_id_formato IS NOT NULL AND p_id_formato <> -1 THEN
            SELECT ALIQUOTA
            INTO v_aliquota
            FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE
            WHERE CD_FORMATO_ACQUISTABILE.ID_FORMATO = p_id_formato
            AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF;
        ELSE
            v_aliquota := 1;
        END IF;
        v_importo := v_importo * v_aliquota;
    END IF;
    RETURN v_importo;
END FU_GET_TARIFFA_RIPARAMETRATA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_MAGGIORAZIONI_NON_FISSE
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: Restituisce le maggiorazioni disponibili, tranne quelle di tipo prosizione fissa
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
-- MODIFICHE    Antonio Colucci, Teoresi srl, 10/03/2011
--              Possibilita di estrarre anche lo sconto quantita (Mod.Vendita 2 - Tipo Magg. 41)
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_MAGGIORAZIONI_NON_FISSE(p_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE) RETURN C_MAGGIORAZIONE IS
v_magg_return C_MAGGIORAZIONE;
BEGIN
--
    OPEN v_magg_return
    FOR
        SELECT  CD_MAGGIORAZIONE.ID_MAGGIORAZIONE, CD_MAGGIORAZIONE.DESCRIZIONE,
                CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE, 0 AS IMPORTO,
                CD_MAGGIORAZIONE.ID_TIPO_MAGG, CD_TIPO_MAGG.TIPO_MAGG_DESC
        FROM  CD_MAGGIORAZIONE, CD_TIPO_MAGG
        WHERE CD_TIPO_MAGG.ID_TIPO_MAGG = CD_MAGGIORAZIONE.ID_TIPO_MAGG
        AND CD_MAGGIORAZIONE.ID_TIPO_MAGG != 1;
       /*AND ( (p_id_mod_vendita = 3 AND CD_MAGGIORAZIONE.ID_TIPO_MAGG = 3)
            or
                (p_id_mod_vendita <> 3 AND CD_MAGGIORAZIONE.ID_TIPO_MAGG = 41));*/
    RETURN v_magg_return;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_MAGGIORAZIONI_NON_FISSE: SI E'' VERIFICATO UN ERRORE');
END FU_GET_MAGGIORAZIONI_NON_FISSE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_MISURE_PRD_VE
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: Restituisce un REF CURSOR con le misure prodotto vendita
--
-- REALIZZATORE:  Francesco Abbundo, Teoresi srl, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_MISURE_PRD_VE(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN C_TIPO_MISURA_PRD_VE
IS
    v_return_cursor C_TIPO_MISURA_PRD_VE;
BEGIN
    OPEN v_return_cursor
    FOR
        SELECT CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE,
        (SELECT CD_UNITA_MISURA_TEMP.DESC_UNITA
         FROM   CD_UNITA_MISURA_TEMP
         WHERE  CD_UNITA_MISURA_TEMP.ID_UNITA = CD_MISURA_PRD_VENDITA.ID_UNITA) DESC_UNITA,
        (SELECT CD_PRODOTTO_PUBB.DESC_PRODOTTO
         FROM   CD_PRODOTTO_PUBB
         WHERE  CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB=CD_MISURA_PRD_VENDITA.ID_PRODOTTO_PUBB) PRODOTTO_PUBB,
        NVL((SELECT CD_GRUPPO_TIPI_PUBB.DESC_GRUPPO
             FROM   CD_GRUPPO_TIPI_PUBB
             WHERE  CD_GRUPPO_TIPI_PUBB.ID_GRUPPO_TIPI_PUBB IN(
                    SELECT CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB
                    FROM   CD_PRODOTTO_PUBB
                    WHERE  CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB=CD_MISURA_PRD_VENDITA.ID_PRODOTTO_PUBB)),'NO') GRUPPO
        FROM CD_MISURA_PRD_VENDITA
        WHERE CD_MISURA_PRD_VENDITA.ID_PRODOTTO_PUBB=(SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA=p_id_prodotto_vendita)
        ORDER BY CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE;
    RETURN v_return_cursor;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_DAMMI_MISURE_PRD_VE: SI E'' VERIFICATO UN ERRORE '||SQLERRM);
END FU_DAMMI_MISURE_PRD_VE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_DATE
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: verifica le relazioni di intersezione tra due intervalli di temporali
-- INPUT: p_data1_inizio , p_data1_fine , p_data2_inizio , p_data2_fine
--        rappresentano rispettivamente gli estremi dei due intervalli
--
-- OUTPUT:
--       1      p_data1_fine < p_data2_inizio
--              intervallo uno inferiore a intervallo due
--       2      p_data1_fine = p_data2_inizio
--              intervallo uno inferiore a intervallo due con data fine uno uguale a data inizio due
--       3      p_data1_fine > p_data2_inizio e p_data1_fine <= p_data2_fine e p_data1_inizio < p_data2_inizio
--              intervallo uno parzialmente sopvrapposto  a intervallo due, con intervallo uno a sinistra
--       4      p_data1_inizio >= p_data2_inizio e p_data1_fine <= p_data2_fine
--              intervallo uno interno a intervallo due
--       5      p_data1_fine > p_data2_fine e p_data1_inizio < p_data2_fine e p_data1_inizio >= p_data2_inizio
--              intervallo uno parzialmente sopvrapposto  a intervallo due, con intervallo uno a destra
--       6      p_data1_inizio = p_data2_fine
--              intervallo uno superiore a intervallo due con data inizio uno uguale a data fine due
--       7      p_data1_inizio > p_data2_fine
--              intervallo uno superiore a intervallo due
--       8      p_data1_inizio <= p_data2_inizio e p_data1_fine >= p_data2_fine
--              intervallo uno contiene a intervallo due
--       9      situazione imprevista il risultato e' inaffidabile
--      -2      i dati inseriti sono inconsistenti
--      -1      si e' verificato un errore
-- REALIZZATORE:  Francesco Abbundo, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_DATE(p_data1_inizio DATE, p_data1_fine DATE, p_data2_inizio DATE, p_data2_fine DATE )
RETURN INTEGER
IS
    v_return_value  INTEGER;
BEGIN
    IF(p_data1_inizio IS NULL OR p_data1_fine IS NULL OR p_data2_inizio IS NULL OR p_data2_fine IS NULL OR (p_data1_inizio>p_data1_fine) OR (p_data2_inizio>p_data2_fine))THEN
       v_return_value:=-2;
    ELSE
        IF(p_data1_fine<p_data2_inizio)THEN
            v_return_value:=1;
           ELSE
            IF(p_data1_fine = p_data2_inizio)THEN
                v_return_value:=2;
            ELSE
                IF(p_data1_fine > p_data2_inizio AND p_data1_fine <= p_data2_fine AND p_data1_inizio < p_data2_inizio)THEN
                    v_return_value:=3;
                ELSE
                    IF(p_data1_inizio >= p_data2_inizio AND p_data1_fine <= p_data2_fine)THEN
                        v_return_value:=4;
                    ELSE
                        IF(p_data1_fine > p_data2_fine AND  p_data1_inizio < p_data2_fine AND p_data1_inizio >= p_data2_inizio)THEN
                            v_return_value:=5;
                        ELSE
                            IF(p_data1_inizio = p_data2_fine)THEN
                                v_return_value:=6;
                            ELSE
                                IF(p_data1_inizio > p_data2_fine)THEN
                                    v_return_value:=7;
                                ELSE
                                    IF(p_data1_inizio <= p_data2_inizio AND p_data1_fine >= p_data2_fine)THEN
                                        v_return_value:=8;
                                    ELSE
                                        v_return_value:=9;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        v_return_value:=-1;
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_VERIFICA_DATE: SI E'' VERIFICATO UN ERRORE '||SQLERRM);
        RETURN v_return_value;
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_DATE_INFO
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: verifica le relazioni di intersezione tra due intervalli di temporali
-- INPUT: p_data1_inizio , p_data1_fine , p_data2_inizio , p_data2_fine
--        rappresentano rispettivamente gli estremi dei due intervalli
--
-- OUTPUT: la rappresentazione stringa dello stato cosi' composta:
--              i primi due caratteri contenenti lo stato, uno spazio, la descrizione dello stato
--       1      p_data1_fine < p_data2_inizio
--              intervallo uno inferiore a intervallo due
--       2      p_data1_fine = p_data2_inizio
--              intervallo uno inferiore a intervallo due con data fine uno uguale a data inizio due
--       3      p_data1_fine > p_data2_inizio e p_data1_fine <= p_data2_fine e p_data1_inizio < p_data2_inizio
--              intervallo uno parzialmente sopvrapposto  a intervallo due, con intervallo uno a sinistra
--       4      p_data1_inizio >= p_data2_inizio e p_data1_fine <= p_data2_fine
--              intervallo uno interno a intervallo due
--       5      p_data1_fine > p_data2_fine e p_data1_inizio < p_data2_fine e p_data1_inizio >= p_data2_inizio
--              intervallo uno parzialmente sopvrapposto  a intervallo due, con intervallo uno a destra
--       6      p_data1_inizio = p_data2_fine
--              intervallo uno superiore a intervallo due con data inizio uno uguale a data fine due
--       7      p_data1_inizio > p_data2_fine
--              intervallo uno superiore a intervallo due
--       8      p_data1_inizio <= p_data2_inizio e p_data1_fine >= p_data2_fine
--              intervallo uno contiene a intervallo due
--       9      situazione imprevista il risultato e' inaffidabile
--      -2      i dati inseriti sono inconsistenti
--      -1      si e' verificato un errore
-- REALIZZATORE:  Francesco Abbundo, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_DATE_INFO(p_data1_inizio DATE, p_data1_fine DATE, p_data2_inizio DATE, p_data2_fine DATE )
RETURN VARCHAR2
IS
    v_return_value  VARCHAR2(240);
BEGIN
    IF(p_data1_inizio IS NULL OR p_data1_fine IS NULL OR p_data2_inizio IS NULL OR p_data2_fine IS NULL OR (p_data1_inizio>p_data1_fine) OR (p_data2_inizio>p_data2_fine))THEN
       v_return_value:='-2 I dati inseriti sono inconsistenti';
    ELSE
        IF(p_data1_fine<p_data2_inizio)THEN
            v_return_value:='+1 p_data1_fine < p_data2_inizio, intervallo uno inferiore a intervallo due';
           ELSE
            IF(p_data1_fine = p_data2_inizio)THEN
                v_return_value:='+2 p_data1_fine = p_data2_inizio, intervallo uno inferiore a intervallo due con data fine uno uguale a data inizio due';
            ELSE
                IF(p_data1_fine > p_data2_inizio AND p_data1_fine <= p_data2_fine AND p_data1_inizio < p_data2_inizio)THEN
                    v_return_value:='+3 p_data1_fine > p_data2_inizio e p_data1_fine <= p_data2_fine e p_data1_inizio < p_data2_inizio, intervallo uno parzialmente sopvrapposto  a intervallo due, con intervallo uno a sinistra';
                ELSE
                    IF(p_data1_inizio >= p_data2_inizio AND p_data1_fine <= p_data2_fine)THEN
                        v_return_value:='+4 p_data1_inizio >= p_data2_inizio e p_data1_fine <= p_data2_fine, intervallo uno interno a intervallo due';
                    ELSE
                        IF(p_data1_fine > p_data2_fine AND  p_data1_inizio < p_data2_fine AND p_data1_inizio >= p_data2_inizio)THEN
                            v_return_value:='+5 p_data1_fine > p_data2_fine e p_data1_inizio < p_data2_fine e p_data1_inizio >= p_data2_inizio, intervallo uno parzialmente sopvrapposto  a intervallo due, con intervallo uno a destra';
                        ELSE
                            IF(p_data1_inizio = p_data2_fine)THEN
                                v_return_value:='+6 p_data1_inizio = p_data2_fine, intervallo uno superiore a intervallo due con data inizio uno uguale a data fine due';
                            ELSE
                                IF(p_data1_inizio > p_data2_fine)THEN
                                    v_return_value:='+7 p_data1_inizio > p_data2_fine, intervallo uno superiore a intervallo due';
                                ELSE
                                    IF(p_data1_inizio <= p_data2_inizio AND p_data1_fine >= p_data2_fine)THEN
                                        v_return_value:='+8 p_data1_inizio <= p_data2_inizio e p_data1_fine >= p_data2_fine, intervallo uno contiene a intervallo due';
                                    ELSE
                                        v_return_value:='+9 situazione imprevista il risultato e'' inaffidabile';
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        v_return_value:='-1 Si e'' verificato un errore';
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_VERIFICA_DATE_INFO: SI E'' VERIFICATO UN ERRORE '||SQLERRM);
        RETURN v_return_value;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VER_CREABILITA_TARIFFA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: verifica che dato un listino ed un prodotto vendita, non ci siano gia' altre tariffe
--              nel periodo in cui si desidera crearne una nuova
-- INPUT:   p_id_prodotto_vendita       il prodotto vendita selezionato
--          p_id_listino                il listino scelto come riferimento
--          p_data_inizio, p_data_fine  gli estremi temporali della tariffa
--          p_id_misura_prd_vendita     misura del prodottto vendita 
--          p_id_tipo_tariffa           tipo tariffa
--          p_id_formato                formato acquistabile
--          p_id_tipo_cinema            tipo cinema
--
-- OUTPUT:
--      RIFIUTI
-- v_return_value -1 --Tipo tariffa base per questo prodotto gia' esistente, non si puo'' inserire!
-- v_return_value -2 --Le date inserite sono esterne al listino di riferimento
-- v_return_value -3 --Formato acquistabile NULL per tariffa fissa gia' esistente, non si puo'' inserire!
-- v_return_value -4 --Tipo cinema NULL per questo prodotto gia'' presente, non si puo'' inserire!
-- v_return_value -5 --Esiste gia'' il tipo cinema inserito per questo prodotto, non si puo'' inserire!
-- v_return_value  0 --valore di inizializzazione, non si puo' procedere
--      CONSENSI
-- v_return_value  1 --La tariffa puo' essere creata. Date diverse, si puo' inserire!
-- v_return_value  2 --Prima tariffa per questo prodotto, si puo'' inserire!
-- v_return_value  3 --Nuova misura temporale per questo prodotto, si puo'' inserire!
-- v_return_value  4 --Nuovo formato acquistabile per questo prodotto, si puo'' inserire!
-- v_return_value  5 --Nuovo tipo cinema per questo prodotto, si puo'' inserire!    
-- v_return_value  6 --Listini diversi, si puo' inserire!
-- v_return_value  7 --Primo tipo cinema NULL per questo prodotto, si puo'' inserire!   
--
-- REALIZZATORE:  Francesco Abbundo, Teoresi srl, Ottobre 2009
--
-- MODIFICHE:  Francesco Abbundo, Teoresi srl, Gennaio 2010
FUNCTION FU_VER_CREABILITA_TARIFFA(p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                   p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
                                   p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                                   p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                                   p_id_misura_prd_vendita CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                   p_id_tipo_tariffa       CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                   p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE,
                                   p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE)                       
                                   RETURN INTEGER
IS
    v_inizio_listino          DATE;
    v_fine_listino            DATE;
    v_temp                    INTEGER;
    v_esito_listino           VARCHAR2(2);
    v_esito_prod_ven          VARCHAR2(2);
    v_esito_date              VARCHAR2(2);
    v_esito_misura_prd_ve     VARCHAR2(2);
    v_esito_tipo_tariffa      VARCHAR2(2);
    v_esito_formato           VARCHAR2(2);
    v_esito_tipo_cinema       VARCHAR2(2);    
    v_esito_desc_tipo_tariffa VARCHAR2(100);
    v_return_value            INTEGER;
    v_formato_nullo           INTEGER;  
    v_tipo_cinema_nullo       INTEGER;
    
BEGIN
    SELECT  CD_LISTINO.DATA_INIZIO, CD_LISTINO.DATA_FINE
    INTO    v_inizio_listino, v_fine_listino
    FROM    CD_LISTINO
    WHERE   CD_LISTINO.ID_LISTINO=p_id_listino;
    IF((v_inizio_listino>p_data_inizio)OR(v_fine_listino<p_data_fine))THEN
        v_return_value:=-2; -- le date inserite sono esterne al listino di riferimento
    ELSE
        v_return_value:=0; --tutto bene
        --se e' la prima tariffa del listino
        SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
        INTO  v_esito_listino   
        FROM  CD_TARIFFA
        WHERE CD_TARIFFA.ID_LISTINO = p_id_listino;
        IF(v_esito_listino='KO')THEN
            DBMS_OUTPUT.PUT_LINE('Esistono tariffe per questo listino, altre verifiche in corso...');
            --se i prodotti di vendita sono diversi allora ok
            SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
            INTO  v_esito_prod_ven   
            FROM  CD_TARIFFA
            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
            IF(v_esito_prod_ven='OK')THEN
                v_return_value:=2;--Prima tariffa per questo prodotto, si puo'' inserire!
                DBMS_OUTPUT.PUT_LINE('Prima tariffa per questo prodotto, si puo'' inserire! '||v_return_value);
            ELSE        
                DBMS_OUTPUT.PUT_LINE('Esistono tariffe per questo prodotto, altre verifiche in corso...');
                --se almeno i periodi sono disgiunti ok
                SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                INTO  v_esito_date 
                FROM  CD_TARIFFA
                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7;
                IF(v_esito_date='KO')THEN
                    DBMS_OUTPUT.PUT_LINE('Date sovrapposte, altre verifiche in corso...');
                    --se almeno le misure temporali sono diverse allora ok
                    SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                    INTO  v_esito_misura_prd_ve  
                    FROM  CD_TARIFFA
                    WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                    AND   CD_TARIFFA.ID_PRODOTTO_VENDITA=p_id_prodotto_vendita
                    AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita;
                    IF(v_esito_misura_prd_ve='KO')THEN
                        DBMS_OUTPUT.PUT_LINE('Esiste gia'' la misura temporale inserita per questo prodotto, altre verifiche in corso...');
                        --se sono qui i periodi sono (anche solo parzialmente) coincidenti e verifico se la tariffa e' fissa 
                        SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                        INTO  v_esito_tipo_tariffa  
                        FROM  CD_TARIFFA
                        WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                        AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                        AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                        AND   p_id_tipo_tariffa = 2; --fissa
                        IF(v_esito_tipo_tariffa='KO')THEN
                            DBMS_OUTPUT.PUT_LINE('Tipo tariffa fissa, altre verifiche in corso...');
                            --se i formati sono diversi allora ok altrimenti no
                            SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                            INTO  v_esito_formato  
                            FROM  CD_TARIFFA
                            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND   CD_TARIFFA.ID_FORMATO = p_id_formato
                            AND   p_id_tipo_tariffa = 2; --fissa
                            --prelevo il valore di formato nullo, posso inserirne uno solo con formato nullo
                            SELECT COUNT(*)
                            INTO  v_formato_nullo  
                            FROM  CD_TARIFFA
                            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND   CD_TARIFFA.ID_FORMATO IS NULL
                            AND   p_id_tipo_tariffa = 2; --fissa
                            IF((v_esito_formato='KO') AND (p_id_formato IS NOT NULL))THEN
                                DBMS_OUTPUT.PUT_LINE('Esiste gia'' il formato acquistabile inserito per questo prodotto, altre verifiche in corso...');
                                --se i periodi sono (anche solo parzialmente) coincidenti e la tariffa e' fissa il formato uguale 
                                --ma il tipo cinema e' diverso allora ok 
                                SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                                INTO  v_esito_tipo_cinema
                                FROM  CD_TARIFFA
                                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                AND   CD_TARIFFA.ID_FORMATO = p_id_formato
                                AND   p_id_tipo_tariffa = 2
                                AND   CD_TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema;
                                --prelevo il valore di tipo cinema nullo, posso inserirne uno solo con tipo cinema nullo
                                SELECT COUNT(*)
                                INTO  v_tipo_cinema_nullo
                                FROM  CD_TARIFFA
                                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                AND   CD_TARIFFA.ID_FORMATO = p_id_formato
                                AND   p_id_tipo_tariffa = 2
                                AND   CD_TARIFFA.ID_TIPO_CINEMA IS NULL;
                                IF((v_esito_tipo_cinema='KO') AND (p_id_tipo_cinema IS NOT NULL))THEN
                                    v_return_value:=-5;--Esiste gia'' il tipo cinema inserito per questo prodotto, non si puo'' inserire!
                                    DBMS_OUTPUT.PUT_LINE('Esiste gia'' il tipo cinema inserito per questo prodotto, non si puo'' inserire! '||v_return_value);
                                ELSE
                                    IF((v_esito_tipo_cinema='OK') AND (p_id_tipo_cinema IS NOT NULL))THEN
                                        v_return_value:=5;--Nuovo tipo cinema per questo prodotto, si puo'' inserire!    
                                        DBMS_OUTPUT.PUT_LINE('Nuovo tipo cinema per questo prodotto, si puo'' inserire! '||v_return_value);
                                    ELSE
                                        IF((v_esito_tipo_cinema='OK') AND (p_id_tipo_cinema IS NULL))THEN
                                            IF(v_tipo_cinema_nullo=0)THEN
                                                v_return_value:=7;--Primo tipo cinema NULL per questo prodotto, si puo'' inserire!    
                                                DBMS_OUTPUT.PUT_LINE('Primo tipo cinema NULL per questo prodotto, si puo'' inserire! '||v_return_value);
                                            ELSE
                                                v_return_value:=-4;--Tipo cinema NULL per questo prodotto gia'' presente, non si puo'' inserire!
                                                DBMS_OUTPUT.PUT_LINE('Tipo cinema NULL per questo prodotto gia'' presente, non si puo'' inserire! '||v_return_value);
                                            END IF;    
                                        END IF;
                                    END IF;
                                END IF;
                            ELSE
                                IF((v_esito_formato='OK') AND (p_id_formato IS NOT NULL))THEN
                                    v_return_value:=4;--Nuovo formato acquistabile per questo prodotto, si puo'' inserire!
                                    DBMS_OUTPUT.PUT_LINE('Nuovo formato acquistabile per questo prodotto, si puo'' inserire! '||v_return_value);
                                ELSE
                                    IF((v_esito_formato='OK') AND (p_id_formato IS NULL))THEN --se formao e' null c'e' un problema
                                        v_return_value:=-3;--Formato acquistabile NULL per tariffa fissa, non si puo'' inserire!
                                        DBMS_OUTPUT.PUT_LINE('Formato acquistabile NULL per tariffa fissa, non si puo'' inserire! '||v_return_value);
                                    END IF;
                                END IF;    
                            END IF;
                        ELSE
                            --invece se i periodi sono (anche solo parzialmente) coincidenti e la tariffa e' base, se sono qui vuol dire 
                            --che le misure temporali sono uguali, quindi no 
                            SELECT CD_TIPO_TARIFFA.DESC_TIPO_TARIFFA
                            INTO   v_esito_desc_tipo_tariffa 
                            FROM   CD_TIPO_TARIFFA, CD_TARIFFA
                            WHERE  CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND    CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND    CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND    CD_TIPO_TARIFFA.ID_TIPO_TARIFFA = p_id_tipo_tariffa;
                            v_return_value:=-1;--Tipo tariffa base per questo prodotto, non si puo'' inserire!
                            DBMS_OUTPUT.PUT_LINE('Tipo tariffa '||v_esito_desc_tipo_tariffa||' per questo prodotto, non si puo'' inserire! '||v_return_value);
                        END IF;
                    ELSE
                        v_return_value:=3;--Nuova misura temporale per questo prodotto, si puo'' inserire!
                        DBMS_OUTPUT.PUT_LINE('Nuova misura temporale per questo prodotto, si puo'' inserire! '||v_return_value);
                    END IF;
                ELSE
                    v_return_value:=1; --Date diverse, si puo' inserire!
                    DBMS_OUTPUT.PUT_LINE('Date disgiunte, si puo'' inserire! '||v_return_value);
                END IF;
            END IF;    
        ELSE
            v_return_value:=6; --Listini diversi, si puo' inserire!
            DBMS_OUTPUT.PUT_LINE('Listini diversi, si puo'' inserire! '||v_return_value);
        END IF;    
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        v_return_value:=-10;
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_VER_CREBILITA_TARIFFA: SI E'' VERIFICATO UN ERRORE '||SQLERRM);
        RETURN v_return_value;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VER_MODIFICABILITA_TARIFFA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: verifica che dato un listino ed un prodotto vendita, non ci siano gia' altre tariffe
--              nel periodo in cui si desidera estendere o contrarre una preesistente
-- INPUT:   p_id_prodotto_vendita       il prodotto vendita selezionato
--          p_id_listino                il listino scelto come riferimento
--          p_data_inizio, p_data_fine  gli estremi temporali della tariffa
--          p_id_misura_prd_vendita     misura del prodottto vendita 
--          p_id_tipo_tariffa           tipo tariffa
--          p_id_formato                formato acquistabile
--          p_id_tipo_cinema            tipo cinema
--
-- OUTPUT:
--      RIFIUTI
-- v_return_value -1 --Tipo tariffa base su base per questo prodotto gia' esistente, non si puo' modificare!
-- v_return_value -2 --Le date inserite sono esterne al listino di riferimento
-- v_return_value -3 --Formato acquistabile NULL per tariffa fissa gia' esistente, non si puo' modificare!
-- v_return_value -4 --Tipo cinema NULL per questo prodotto gia' presente, non si puo' modificare!
-- v_return_value -5 --Esiste gia' il tipo cinema inserito per questo prodotto, non si puo' modificare!
-- v_return_value  0 --valore di inizializzazione, non si puo' procedere
--      CONSENSI
-- v_return_value  1 --La tariffa puo' essere modificata. Date diverse, si puo' modificare!
-- v_return_value  2 --Prima tariffa per questo prodotto, si puo' modificare!
-- v_return_value  3 --Nuova misura temporale per questo prodotto, si puo' modificare!
-- v_return_value  4 --Nuovo formato acquistabile per questo prodotto, si puo'' modificare!
-- v_return_value  5 --Nuovo tipo cinema per questo prodotto, si puo' modificare!    
-- v_return_value  6 --Listini diversi, si puo' modificare!
-- v_return_value  7 --Primo tipo cinema NULL per questo prodotto, si puo' modificare!
-- v_return_value  8 --Tipo tariffa base su fissa per questo prodotto gia' esistente, si puo' modificare! 
--
-- REALIZZATORE:  Francesco Abbundo, Teoresi srl, Ottobre 2009
--
-- MODIFICHE:   Francesco Abbundo, Teoresi srl, Gennaio 2010
--              Tommaso D'Anna, Teoresi srl, 01/02/2011
--              Inserita gestione in caso di accavallamento di una tariffa di tipo base
FUNCTION FU_VER_MODIFICABILITA_TARIFFA(p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                       p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
                                       p_id_tariffa            CD_TARIFFA.ID_TARIFFA%TYPE,
                                       p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                                       p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                                       p_id_misura_prd_vendita CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                       p_id_tipo_tariffa       CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                       p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE,
                                       p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE)
                                   RETURN INTEGER
IS
    v_inizio_listino          DATE;
    v_fine_listino            DATE;
    v_temp                    INTEGER;
    v_esito_listino           VARCHAR2(2);
    v_esito_prod_ven          VARCHAR2(2);
    v_esito_date              VARCHAR2(2);
    v_esito_misura_prd_ve     VARCHAR2(2);
    v_esito_tipo_tariffa      VARCHAR2(2);
    v_esito_formato           VARCHAR2(2);
    v_esito_tipo_cinema       VARCHAR2(2);    
    v_esito_desc_tipo_tariffa VARCHAR2(100);
    v_return_value            INTEGER;
    v_formato_nullo           INTEGER;  
    v_tipo_cinema_nullo       INTEGER;
BEGIN
    SELECT  CD_LISTINO.DATA_INIZIO, CD_LISTINO.DATA_FINE
    INTO    v_inizio_listino, v_fine_listino
    FROM    CD_LISTINO
    WHERE   CD_LISTINO.ID_LISTINO=p_id_listino;
    IF((v_inizio_listino>p_data_inizio)OR(v_fine_listino<p_data_fine))THEN
        v_return_value:=-2; -- le date inserite sono esterne al listino di riferimento
    ELSE
        v_return_value:=0; --tutto bene
        --se e' la prima tariffa per il listino
        SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
        INTO  v_esito_listino   
        FROM  CD_TARIFFA
        WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
        AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa;
        IF(v_esito_listino='KO')THEN
            DBMS_OUTPUT.PUT_LINE('Esistono tariffe per questo listino, altre verifiche in corso...');
            --se i prodotti di vendita sono diversi allora ok
            SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
            INTO  v_esito_prod_ven   
            FROM  CD_TARIFFA
            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA=p_id_prodotto_vendita
            AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa;
            IF(v_esito_prod_ven='OK')THEN
                v_return_value:=2;--Prima tariffa per questo prodotto, si puo'' inserire!
                DBMS_OUTPUT.PUT_LINE('Prima tariffa per questo prodotto, si puo'' inserire! '||v_return_value);
            ELSE        
                DBMS_OUTPUT.PUT_LINE('Esistono tariffe per questo prodotto, altre verifiche in corso...');
                --se almeno i periodi sono disgiunti ok
                SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                INTO  v_esito_date 
                FROM  CD_TARIFFA
                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa;
                IF(v_esito_date='KO')THEN
                    DBMS_OUTPUT.PUT_LINE('Date sovrapposte, altre verifiche in corso...');
                    --se almeno le misure temporali sono diverse allora ok
                    SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                    INTO  v_esito_misura_prd_ve  
                    FROM  CD_TARIFFA
                    WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                    AND   CD_TARIFFA.ID_PRODOTTO_VENDITA=p_id_prodotto_vendita
                    AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7                    
                    AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa;
                    IF(v_esito_misura_prd_ve='KO')THEN
                        DBMS_OUTPUT.PUT_LINE('Esiste gia'' la misura temporale inserita per questo prodotto, altre verifiche in corso...');
                        --se sono qui i periodi sono (anche solo parzialmente) coincidenti, verifico se la tariffa e' fissa 
                        SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                        INTO  v_esito_tipo_tariffa  
                        FROM  CD_TARIFFA
                        WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                        AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                        AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                        AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa
                        AND   p_id_tipo_tariffa = 2; --fissa
                        IF(v_esito_tipo_tariffa='KO')THEN
                            DBMS_OUTPUT.PUT_LINE('Tipo tariffa fissa, altre verifiche in corso...');
                            --se i formati sono diversi allora ok altrimenti no
                            SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                            INTO  v_esito_formato  
                            FROM  CD_TARIFFA
                            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND   CD_TARIFFA.ID_FORMATO = p_id_formato
                            AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa
                            AND   p_id_tipo_tariffa = 2; --fissa
                            --prelevo il valore di formato nullo, posso inserirne uno solo con formato nullo
                            SELECT COUNT(*)
                            INTO  v_formato_nullo  
                            FROM  CD_TARIFFA
                            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa
                            AND   CD_TARIFFA.ID_FORMATO IS NULL
                            AND   p_id_tipo_tariffa = 2; --fissa
                            IF((v_esito_formato='KO') AND (p_id_formato IS NOT NULL))THEN
                                DBMS_OUTPUT.PUT_LINE('Esiste gia'' il formato acquistabile inserito per questo prodotto, altre verifiche in corso...');
                                --se i periodi sono (anche solo parzialmente) coincidenti e la tariffa e' fissa il formato uguale 
                                --ma il tipo cinema e' diverso allora ok 
                                SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                                INTO  v_esito_tipo_cinema
                                FROM  CD_TARIFFA
                                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                AND   CD_TARIFFA.ID_FORMATO = p_id_formato
                                AND   p_id_tipo_tariffa = 2 --fissa
                                AND   CD_TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema
                                AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa;
                                --prelevo il valore di tipo cinema nullo, posso inserirne uno solo con tipo cinema nullo
                                SELECT COUNT(*)
                                INTO  v_tipo_cinema_nullo
                                FROM  CD_TARIFFA
                                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                AND   CD_TARIFFA.ID_FORMATO = p_id_formato
                                AND   p_id_tipo_tariffa = 2 --fissa
                                AND   CD_TARIFFA.ID_TIPO_CINEMA IS NULL
                                AND   CD_TARIFFA.ID_TARIFFA <> p_id_tariffa;
                                IF((v_esito_tipo_cinema='KO') AND (p_id_tipo_cinema IS NOT NULL))THEN
                                    v_return_value:=-5;--Esiste gia'' il tipo cinema inserito per questo prodotto, non si puo' inserire!
                                    DBMS_OUTPUT.PUT_LINE('Esiste gia'' il tipo cinema inserito per questo prodotto, non si puo'' inserire! '||v_return_value);
                                ELSE
                                    IF((v_esito_tipo_cinema='OK') AND (p_id_tipo_cinema IS NOT NULL))THEN
                                        v_return_value:=5;--Nuovo tipo cinema per questo prodotto, si puo'' inserire!    
                                        DBMS_OUTPUT.PUT_LINE('Nuovo tipo cinema per questo prodotto, si puo'' inserire! '||v_return_value);
                                    ELSE
                                        IF((v_esito_tipo_cinema='OK') AND (p_id_tipo_cinema IS NULL))THEN
                                            IF(v_tipo_cinema_nullo=0)THEN
                                                v_return_value:=7;--Primo tipo cinema NULL per questo prodotto, si puo' inserire!    
                                                DBMS_OUTPUT.PUT_LINE('Primo tipo cinema NULL per questo prodotto, si puo'' inserire! '||v_return_value);
                                            ELSE
                                                v_return_value:=-4;--Tipo cinema NULL per questo prodotto gia' presente, non si puo'' inserire!
                                                DBMS_OUTPUT.PUT_LINE('Tipo cinema NULL per questo prodotto gia'' presente, non si puo'' inserire! '||v_return_value);
                                            END IF;    
                                        END IF;
                                    END IF;
                                END IF;
                            ELSE
                                IF((v_esito_formato='OK') AND (p_id_formato IS NOT NULL))THEN
                                    v_return_value:=4;--Nuovo formato acquistabile per questo prodotto, si puo'' inserire!
                                    DBMS_OUTPUT.PUT_LINE('Nuovo formato acquistabile per questo prodotto, si puo'' inserire! '||v_return_value);
                                ELSE
                                    IF((v_esito_formato='OK') AND (p_id_formato IS NULL))THEN --se formao e' null c'e' un problema
                                        v_return_value:=-3;--Formato acquistabile NULL per tariffa fissa, non si puo' inserire!
                                        DBMS_OUTPUT.PUT_LINE('Formato acquistabile NULL per tariffa fissa, non si puo'' inserire! '||v_return_value);
                                    END IF;
                                END IF;    
                            END IF;
                        ELSE
                            --invece se i periodi sono (anche solo parzialmente) coincidenti e la tariffa e' base
                            --posso modificare soltanto se la tariffa che si sovrappone e' fissa
                            SELECT DECODE(COUNT(*), 0 , 'OK', 'KO' )
                            INTO   v_esito_desc_tipo_tariffa 
                            FROM   CD_TARIFFA
                            WHERE  CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND    CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND    CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND    CD_TARIFFA.ID_TARIFFA <> p_id_tariffa
                            AND    PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                            AND    PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7                          
                            AND    CD_TARIFFA.ID_TIPO_TARIFFA = 1; --base
                            IF(v_esito_desc_tipo_tariffa='KO')THEN
                                --in questo caso la tariffa base si sovrappone con un'altra base
                                v_return_value:=-1;--Tipo tariffa base su base per questo prodotto, non si puo' inserire!
                                DBMS_OUTPUT.PUT_LINE('Il tipo tariffa che si sovrappone e'' BASE per questo prodotto, non si puo'' inserire! '||v_return_value);
                            ELSE
                                --in questo caso la tariffa base si sovrappone con una fissa
                                v_return_value:=8; --Tipo tariffa base su fissa per questo prodotto, si puo' inserire!
                                DBMS_OUTPUT.PUT_LINE('Il tipo tariffa che si sovrappone e'' FISSA per questo prodotto, si puo'' inserire! '||v_return_value);                                    
                            END IF;
                        END IF;
                    ELSE
                        v_return_value:=3;--Nuova misura temporale per questo prodotto, si puo' inserire!
                        DBMS_OUTPUT.PUT_LINE('Nuova misura temporale per questo prodotto, si puo'' inserire! '||v_return_value);
                    END IF;
                ELSE
                    v_return_value:=1; --Date diverse, si puo' inserire!
                    DBMS_OUTPUT.PUT_LINE('Date disgiunte, si puo'' inserire! '||v_return_value);
                END IF;
            END IF;    
        ELSE
            v_return_value:=6; --Listini diversi, si puo' inserire!
            DBMS_OUTPUT.PUT_LINE('Listini diversi, si puo'' inserire! '||v_return_value);
        END IF;    
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        v_return_value:=-1;
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_VER_MODIFICABILITA_TARIFFA: SI E'' VERIFICATO UN ERRORE '||SQLERRM);
        RETURN v_return_value;
END;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_GENERA_AMBIENTI
--
-- DESCRIZIONE:  crea tutti gli ambiti di vendita relativi al prodotto di vendita passati
--
--
-- INPUT:
--  p_id_prodotto_vendita   identificativo del prodotto di vendita
--  p_id_listino            identificativo del listino
--  p_data_inizio           data inizio generazione ambienti di vendita
--  p_data_fine             data fine generazione ambienti di vendita
--
--
-- OUTPUT: esito:
--    n  numero di record generati (>0 perche' parte da uno)
--    -1 Inserimento non eseguito: si e' verificato un errore
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Ottobre 2009
--
-- MODIFICHE:
--          Tommaso D'Anna, Teoresi s.r.l., 8 Settembre 2011
--              Inserito popolamento denormalizzazione ID_SALA su CD_BREAK_VENDITA
-------------------------------------------------------------------------------------------------
FUNCTION FU_GENERA_AMBIENTI(p_id_prodotto_vendita  CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                            p_id_listino           CD_TARIFFA.ID_LISTINO%TYPE,
                            p_data_inizio          CD_TARIFFA.DATA_INIZIO%TYPE,
                            p_data_fine            CD_TARIFFA.DATA_FINE%TYPE) RETURN INTEGER
IS
    v_codice_luogo        CD_LUOGO.ID_LUOGO%TYPE;
    v_numero_giorni       INTEGER;
    v_id_circuito         CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_dimmi_se_esisto_gia INTEGER;
    v_return_value        INTEGER;
BEGIN
    v_return_value     := 1;
    SAVEPOINT SP_PR_GENERA_AMBIENTI;
    --recupero il circuito
    SELECT ID_CIRCUITO
    INTO   v_id_circuito
    FROM   CD_PRODOTTO_VENDITA
    WHERE  ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
    --recupero le informazioni sul numero dei giorni
    v_numero_giorni:=p_data_fine-p_data_inizio;
    FOR tabs IN(SELECT TABA.COD_TIPO_PUBB, TABB.CODICE
                  FROM (SELECT COD_TIPO_PUBB FROM VENPC.PC_TIPI_PUBBLICITA WHERE COD_TIPO_PUBB IN (
                            SELECT COD_TIPO_PUBB FROM CD_TIPO_PUBB_GRUPPO WHERE ID_GRUPPO_TIPI_PUBB IN (
                                SELECT ID_GRUPPO_TIPI_PUBB FROM CD_GRUPPO_TIPI_PUBB WHERE ID_GRUPPO_TIPI_PUBB IN (
                                    SELECT ID_GRUPPO_TIPI_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                                        SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita))))
                        OR COD_TIPO_PUBB IN (SELECT COD_TIPO_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                            SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita))) TABA,
                       (SELECT COD_TIPO_PUBB, CODICE FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB WHERE CD_LUOGO_TIPO_PUBB.ID_LUOGO = CD_LUOGO.ID_LUOGO) TABB
                  WHERE TABA.COD_TIPO_PUBB = TABB.COD_TIPO_PUBB) LOOP
            IF(tabs.codice='CIN')THEN
                DBMS_OUTPUT.PUT_LINE('CIN');
                --scorro i circuiti cinema
                FOR CA IN(SELECT ID_CIRCUITO_CINEMA FROM CD_CIRCUITO_CINEMA WHERE ID_CIRCUITO=v_id_circuito AND ID_LISTINO=p_id_listino) LOOP
                    FOR GIORNO IN 0..v_numero_giorni LOOP
                        SELECT COUNT(*)
                        INTO v_dimmi_se_esisto_gia
                        FROM CD_CINEMA_VENDITA
                        WHERE CD_CINEMA_VENDITA.DATA_EROGAZIONE = p_data_inizio + GIORNO
                        AND   CD_CINEMA_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                        AND   CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = CA.ID_CIRCUITO_CINEMA 
                        AND   CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
                        IF(v_dimmi_se_esisto_gia = 0)THEN
                            INSERT INTO CD_CINEMA_VENDITA
                                (DATA_EROGAZIONE, COD_TIPO_PUBB, FLG_ANNULLATO, ID_CIRCUITO_CINEMA, ID_PRODOTTO_VENDITA)
                            VALUES
                                (p_data_inizio + GIORNO, tabs.COD_TIPO_PUBB, 'N', CA.ID_CIRCUITO_CINEMA, p_id_prodotto_vendita);
                            v_return_value:=v_return_value+1;    
                        END IF;       
                    END LOOP;
                END LOOP;
            ELSE
                IF(tabs.codice='ATR')THEN
                    DBMS_OUTPUT.PUT_LINE('ATR');
                    --scorro i circuiti atrio
                    FOR CA IN(SELECT ID_CIRCUITO_ATRIO FROM CD_CIRCUITO_ATRIO WHERE ID_CIRCUITO=v_id_circuito AND ID_LISTINO=p_id_listino) LOOP
                        FOR GIORNO IN 0..v_numero_giorni LOOP
                            SELECT COUNT(*)
                            INTO v_dimmi_se_esisto_gia
                            FROM CD_ATRIO_VENDITA
                            WHERE CD_ATRIO_VENDITA.DATA_EROGAZIONE = p_data_inizio + GIORNO
                            AND   CD_ATRIO_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                            AND   CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = CA.ID_CIRCUITO_ATRIO 
                            AND   CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
                            IF(v_dimmi_se_esisto_gia = 0)THEN
                                INSERT INTO CD_ATRIO_VENDITA
                                    (DATA_EROGAZIONE, COD_TIPO_PUBB, FLG_ANNULLATO, ID_CIRCUITO_ATRIO, ID_PRODOTTO_VENDITA)
                                VALUES
                                    (p_data_inizio + GIORNO, tabs.COD_TIPO_PUBB, 'N', CA.ID_CIRCUITO_ATRIO, p_id_prodotto_vendita);
                                v_return_value:=v_return_value+1;
                            END IF;    
                        END LOOP;
                    END LOOP;
                ELSE
                    IF(tabs.codice='SAL')THEN
                        DBMS_OUTPUT.PUT_LINE('SAL');
                        --scorro i circuiti sala
                        FOR CA IN(SELECT ID_CIRCUITO_SALA FROM CD_CIRCUITO_SALA WHERE ID_CIRCUITO=v_id_circuito AND ID_LISTINO=p_id_listino) LOOP
                            FOR GIORNO IN 0..v_numero_giorni LOOP
                                SELECT COUNT(*)
                                INTO v_dimmi_se_esisto_gia
                                FROM CD_SALA_VENDITA
                                WHERE CD_SALA_VENDITA.DATA_EROGAZIONE = p_data_inizio + GIORNO
                                AND   CD_SALA_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                                AND   CD_SALA_VENDITA.ID_CIRCUITO_SALA = CA.ID_CIRCUITO_SALA 
                                AND   CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
                                IF(v_dimmi_se_esisto_gia = 0)THEN
                                    INSERT INTO CD_SALA_VENDITA
                                       (DATA_EROGAZIONE, COD_TIPO_PUBB, FLG_ANNULLATO, ID_CIRCUITO_SALA, ID_PRODOTTO_VENDITA)
                                    VALUES
                                       (p_data_inizio + GIORNO, tabs.COD_TIPO_PUBB, 'N', CA.ID_CIRCUITO_SALA, p_id_prodotto_vendita);
                                    v_return_value:=v_return_value+1;
                                END IF;    
                            END LOOP;
                        END LOOP;
                    ELSE
                        IF(tabs.codice='SCA') OR (tabs.codice='SCS')THEN
                            DBMS_OUTPUT.PUT_LINE('SCA');
                            --ed ora seleziono i circuiti break associati al listino, al circuito ed ai break filtrati sul tipo break
                            FOR CA IN ( SELECT 
                                            CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK,
                                            CD_PROIEZIONE.DATA_PROIEZIONE, 
                                            CD_CIRCUITO_SCHERMO.FLG_ANNULLATO,
                                            CD_SCHERMO.ID_SALA
                                        FROM   CD_SCHERMO,CD_CIRCUITO_SCHERMO,CD_PRODOTTO_VENDITA,CD_CIRCUITO_BREAK,CD_PROIEZIONE,CD_BREAK
                                        WHERE  CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
                                        AND    CD_BREAK.ID_TIPO_BREAK = CD_PRODOTTO_VENDITA.ID_TIPO_BREAK
                                        AND    CD_PROIEZIONE.ID_SCHERMO=CD_CIRCUITO_SCHERMO.ID_SCHERMO
                                        AND    CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                                        AND    CD_CIRCUITO_BREAK.ID_BREAK   = CD_BREAK.ID_BREAK
                                        AND    CD_CIRCUITO_BREAK.ID_CIRCUITO= v_id_circuito
                                        AND    CD_CIRCUITO_BREAK.ID_LISTINO = p_id_listino
                                        AND    CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA=p_id_prodotto_vendita
                                        AND    CD_CIRCUITO_SCHERMO.ID_CIRCUITO= v_id_circuito
                                        AND    CD_CIRCUITO_SCHERMO.ID_LISTINO = p_id_listino
                                        AND    CD_CIRCUITO_SCHERMO.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
                                        AND    CD_SCHERMO.FLG_SALA=NVL2(NULLIF(tabs.codice,'SCS'),'N','S')) LOOP
                                SELECT COUNT(*)
                                INTO v_dimmi_se_esisto_gia
                                FROM CD_BREAK_VENDITA
                                WHERE CD_BREAK_VENDITA.DATA_EROGAZIONE = CA.DATA_PROIEZIONE
                                AND   CD_BREAK_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                                AND   CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CA.ID_CIRCUITO_BREAK 
                                AND   CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
                                IF(v_dimmi_se_esisto_gia = 0)THEN        
                                    INSERT INTO CD_BREAK_VENDITA
                                        (DATA_EROGAZIONE, COD_TIPO_PUBB, FLG_ANNULLATO, ID_CIRCUITO_BREAK, ID_PRODOTTO_VENDITA, SECONDI_ASSEGNATI, ID_SALA)
                                    VALUES
                                        (CA.DATA_PROIEZIONE, tabs.COD_TIPO_PUBB, CA.FLG_ANNULLATO, CA.ID_CIRCUITO_BREAK, p_id_prodotto_vendita, 0, CA.ID_SALA);
                                    v_return_value:=v_return_value+1;
                                END IF;    
                            END LOOP;
                        END IF;
                    END IF;
                END IF;
            END IF;
    END LOOP;
    RETURN v_return_value;
EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
    WHEN OTHERS THEN
        v_return_value:= -1;
        RETURN v_return_value;
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_GENERA_AMBIENTI: Generazione non eseguita. '||SQLERRM);
        ROLLBACK TO SP_PR_GENERA_AMBIENTI;
END;
-----------------------------------------------------------------------------------------------------
-- Function PR_ELIMINA_AMBIENTI
--
-- DESCRIZIONE: Esegue l'eliminazione degli ambienti legati a un prodotto di vendita per uno dato periodo
--
-- INPUT:
--      p_id_tariffa        id della tariffa di cui tentare l'eliminazione
--      p_data_inizio_canc  inizio intervallo da cancellare
--      p_data_fine_canc    fine intervallo da cancellare
-- OUTPUT: esito:
--    1  ambienti cancellati correttamente (se ce ne sono)
--    2  ambienti non cancellati perche' ci sono ancora tariffe per il prodotto nel perioo
--   -1  Eliminazione non effettuata a causa di un errore
-- REALIZZATORE:    Francesco Abbundo, Teoresi srl, Ottobre 2009
-- MODIFICHE:       Francesco Abbundo, Teoresi srl, Gennaio 2010
--                  Tommaso D'Anna, Teoresi srl, 27 Gennaio 2011
--                      Aggiunto l'annullamento degli ambienti in caso di comunicati annullati
-------------------------------------------------------------------------------------------------
FUNCTION PR_ELIMINA_AMBIENTI(  p_id_tariffa        IN CD_TARIFFA.ID_TARIFFA%TYPE,
                               p_data_inizio_canc  DATE,
                               p_data_fine_canc    DATE) RETURN INTEGER
IS
    v_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE;
    v_id_listino            CD_TARIFFA.ID_LISTINO%TYPE;
    v_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_vendo                 DATE;
    v_numero_tariffe        INTEGER;
    v_return_value          INTEGER;
    v_numero_com_annullati  INTEGER;
BEGIN
    SAVEPOINT SP_PR_ELIMINA_AMBIENTI;
    --recupero il prodotto di vendita e le date
    SELECT ID_PRODOTTO_VENDITA, ID_LISTINO
    INTO   v_id_prodotto_vendita, v_id_listino
    FROM   CD_TARIFFA
    WHERE  ID_TARIFFA=p_id_tariffa;
    
    SELECT ID_CIRCUITO
    INTO   v_id_circuito
    FROM   CD_PRODOTTO_VENDITA
    WHERE  ID_PRODOTTO_VENDITA = v_id_prodotto_vendita;
    
    v_return_value:= 2;
    
    v_vendo:=p_data_inizio_canc;
    WHILE v_vendo <= p_data_fine_canc LOOP
        SELECT COUNT(*)
        INTO   v_numero_tariffe 
        FROM   CD_TARIFFA ciu, CD_TARIFFA ccio
        WHERE  ciu.ID_PRODOTTO_VENDITA = ccio.ID_PRODOTTO_VENDITA 
        AND    ciu.ID_TARIFFA = p_id_tariffa
        AND    ccio.ID_TARIFFA <> p_id_tariffa
        AND    v_vendo BETWEEN ccio.DATA_INIZIO AND ccio.DATA_FINE;

        IF(v_numero_tariffe = 0) THEN
            --Verifico la presenza di comunicati annullati per v_vendo
            SELECT  COUNT(*)
            INTO    v_numero_com_annullati 
            FROM    CD_COMUNICATO, CD_PRODOTTO_ACQUISTATO 
            WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = v_vendo
            AND     CD_COMUNICATO.FLG_ANNULLATO = 'S';
            
            IF (v_numero_com_annullati = 0) THEN
                --Posso eliminare! Non mi vi sono comunicati annullati!
                --Qui elimina i break di vendita
                DELETE  FROM  CD_BREAK_VENDITA
                WHERE   CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND     DATA_EROGAZIONE = v_vendo
                AND     ID_CIRCUITO_BREAK IN(SELECT ID_CIRCUITO_BREAK FROM CD_CIRCUITO_BREAK
                                             WHERE  ID_CIRCUITO=v_id_circuito
                                             AND    ID_LISTINO =v_id_listino);
                --Qui elimina le sale di vendita
                DELETE FROM CD_SALA_VENDITA
                WHERE  CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND    DATA_EROGAZIONE = v_vendo
                AND    ID_CIRCUITO_SALA IN(SELECT ID_CIRCUITO_SALA FROM CD_CIRCUITO_SALA
                                             WHERE  ID_CIRCUITO=v_id_circuito
                                             AND    ID_LISTINO =v_id_listino);
                --Qui elimino gli atrii di vendita
                DELETE FROM CD_ATRIO_VENDITA
                WHERE  CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND    DATA_EROGAZIONE = v_vendo
                AND    ID_CIRCUITO_ATRIO IN(SELECT ID_CIRCUITO_ATRIO FROM CD_CIRCUITO_ATRIO
                                             WHERE  ID_CIRCUITO=v_id_circuito
                                             AND    ID_LISTINO =v_id_listino);
                --Qui elimino i cinema di vendita
                DELETE FROM CD_CINEMA_VENDITA
                WHERE  CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND    DATA_EROGAZIONE = v_vendo
                AND    ID_CIRCUITO_CINEMA IN(SELECT ID_CIRCUITO_CINEMA FROM CD_CIRCUITO_CINEMA
                                             WHERE  ID_CIRCUITO=v_id_circuito
                                             AND    ID_LISTINO =v_id_listino);
                v_return_value:= 1;            
            ELSE
                --In questo caso esistono comunicati annullati. Annullo i break piuttosto che
                --eliminarli!
                --Qui annulla i break di vendita
                UPDATE  CD_BREAK_VENDITA
                SET     FLG_ANNULLATO='S'
                WHERE   CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND     DATA_EROGAZIONE=v_vendo
                AND     ID_CIRCUITO_BREAK IN(SELECT ID_CIRCUITO_BREAK FROM CD_CIRCUITO_BREAK
                                             WHERE  ID_CIRCUITO=v_id_circuito
                                             AND    ID_LISTINO =v_id_listino);
                --Qui annulla le sale di vendita
                UPDATE  CD_SALA_VENDITA
                SET     FLG_ANNULLATO='S'
                WHERE   CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND     DATA_EROGAZIONE=v_vendo
                AND     ID_CIRCUITO_SALA IN(SELECT ID_CIRCUITO_SALA FROM CD_CIRCUITO_SALA
                                            WHERE  ID_CIRCUITO=v_id_circuito
                                            AND    ID_LISTINO =v_id_listino);
                --Qui annulla gli atrii di vendita
                UPDATE  CD_ATRIO_VENDITA
                SET     FLG_ANNULLATO='S'
                WHERE   CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND     DATA_EROGAZIONE=v_vendo
                AND     ID_CIRCUITO_ATRIO IN(SELECT ID_CIRCUITO_ATRIO FROM CD_CIRCUITO_ATRIO
                                             WHERE  ID_CIRCUITO=v_id_circuito
                                             AND    ID_LISTINO =v_id_listino);
                --Qui annulla i cinema di vendita
                UPDATE  CD_CINEMA_VENDITA
                SET     FLG_ANNULLATO='S'
                WHERE   CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND     DATA_EROGAZIONE=v_vendo
                AND     ID_CIRCUITO_CINEMA IN(SELECT ID_CIRCUITO_CINEMA FROM CD_CIRCUITO_CINEMA
                                              WHERE  ID_CIRCUITO=v_id_circuito
                                              AND    ID_LISTINO =v_id_listino);
                v_return_value:= 1;            
            END IF;
        END IF;
        v_vendo:=v_vendo+1;
    END LOOP;                                 
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_ELIMINA_AMBIENTI: Delete non eseguita, si e'' verificato un errore. '||SQLERRM);
        v_return_value:=-1;
        RETURN v_return_value;
        ROLLBACK TO SP_PR_ELIMINA_AMBIENTI;
END;
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_BR
-----------------------------------------------------------------------------------------------------
-- DESCRIZIONE: chiamata dall'interno della creazione di un break PA_CD_BREAK.PR_GENERA_BREAK_PROIEZIONE
--              si occupa di generare gli eventuali break di vendita per quelle tariffe create prima
--              della creazione di un insieme di proiezioni (quindi break, circuiti_break)
--
-- INPUT:
--      p_id_listino         l'id del listino in cui e' stato inserito il nuovo circuito_break
--      p_id_circuito        l'id del circuito in cui e' stato inserito il nuovo circuito_break
--        p_id_circuito_break  l'ide del nuovo circuito break appena inserito
--        p_data_proiezione    la data di proiezione relativa al break del circuito_break
--
-- OUTPUT: nessun risultato previsto, solo un eccezione in caso di errore
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Ottobre 2009, Gennaio 2010
--
-- MODIFICHE:
--          Tommaso D'Anna, Teoresi s.r.l., 8 Settembre 2011
--              Inserito popolamento denormalizzazione ID_SALA su CD_BREAK_VENDITA
-------------------------------------------------------------------------------------------------
PROCEDURE PR_REFRESH_TARIFFE_BR(p_id_listino         CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_id_circuito_break  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK%TYPE,
                                p_data_proiezione    CD_PROIEZIONE.DATA_PROIEZIONE%TYPE)
IS
    v_tipo_break            INTEGER;
    v_count_tb              INTEGER;
    v_flg                   CD_CIRCUITO_SCHERMO.FLG_ANNULLATO%TYPE;
    v_dimmi_se_esisto_gia   INTEGER;
    v_id_sala               CD_SCHERMO.ID_SALA%TYPE;
BEGIN
    SAVEPOINT SP_PR_REFRESH_TARIFFE_BR;
    FOR temp IN(SELECT ID_PRODOTTO_VENDITA FROM CD_TARIFFA
                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA IN (
                      SELECT ID_PRODOTTO_VENDITA FROM CD_PRODOTTO_VENDITA
                                            WHERE ID_CIRCUITO = p_id_circuito)
                AND   p_data_proiezione BETWEEN CD_TARIFFA.DATA_INIZIO AND CD_TARIFFA.DATA_FINE)LOOP
        SELECT CD_PRODOTTO_VENDITA.ID_TIPO_BREAK
        INTO   v_tipo_break
        FROM   CD_PRODOTTO_VENDITA
        WHERE  CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA=temp.ID_PRODOTTO_VENDITA;
        FOR tabs IN(SELECT TABA.COD_TIPO_PUBB, TABB.CODICE
                  FROM (SELECT COD_TIPO_PUBB FROM VENPC.PC_TIPI_PUBBLICITA WHERE COD_TIPO_PUBB IN (
                            SELECT COD_TIPO_PUBB FROM CD_TIPO_PUBB_GRUPPO WHERE ID_GRUPPO_TIPI_PUBB IN (
                                SELECT ID_GRUPPO_TIPI_PUBB FROM CD_GRUPPO_TIPI_PUBB WHERE ID_GRUPPO_TIPI_PUBB IN (
                                    SELECT ID_GRUPPO_TIPI_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                                        SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))))
                        OR COD_TIPO_PUBB IN (SELECT COD_TIPO_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                            SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))) TABA,
                       (SELECT COD_TIPO_PUBB, CODICE FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB WHERE CD_LUOGO_TIPO_PUBB.ID_LUOGO = CD_LUOGO.ID_LUOGO) TABB
                  WHERE TABA.COD_TIPO_PUBB = TABB.COD_TIPO_PUBB) LOOP
            SELECT COUNT(*)
            INTO   v_count_tb
            FROM   CD_BREAK, CD_CIRCUITO_BREAK
            WHERE  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK=p_id_circuito_break
            AND    CD_CIRCUITO_BREAK.ID_BREAK=CD_BREAK.ID_BREAK
            AND    CD_BREAK.ID_TIPO_BREAK = v_tipo_break;
            SELECT FLG_ANNULLATO
            INTO   v_flg
            FROM   CD_CIRCUITO_SCHERMO
            WHERE  CD_CIRCUITO_SCHERMO.ID_CIRCUITO=p_id_circuito
            AND    CD_CIRCUITO_SCHERMO.ID_LISTINO =p_id_listino
            AND    CD_CIRCUITO_SCHERMO.ID_SCHERMO IN (SELECT ID_SCHERMO FROM CD_SCHERMO WHERE ID_SCHERMO IN(
                        SELECT ID_SCHERMO FROM CD_PROIEZIONE WHERE ID_PROIEZIONE IN(
                               SELECT ID_PROIEZIONE FROM CD_BREAK WHERE ID_BREAK IN(
                                      SELECT ID_BREAK FROM CD_CIRCUITO_BREAK WHERE ID_CIRCUITO_BREAK=p_id_circuito_break))));
            SELECT ID_SALA
            INTO v_id_sala
            FROM CD_SCHERMO WHERE ID_SCHERMO IN(
                                    SELECT ID_SCHERMO FROM CD_PROIEZIONE WHERE ID_PROIEZIONE IN(
                                           SELECT ID_PROIEZIONE FROM CD_BREAK WHERE ID_BREAK IN(
                                                  SELECT ID_BREAK FROM CD_CIRCUITO_BREAK WHERE ID_CIRCUITO_BREAK=p_id_circuito_break)));                     
            IF((v_count_tb>0)AND((tabs.CODICE='SCA') OR (tabs.CODICE='SCS')))THEN
                SELECT COUNT(*)
                INTO  v_dimmi_se_esisto_gia
                FROM  CD_BREAK_VENDITA
                WHERE CD_BREAK_VENDITA.DATA_EROGAZIONE = p_data_proiezione
                AND   CD_BREAK_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                AND   CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = p_id_circuito_break 
                AND   CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA;
                IF(v_dimmi_se_esisto_gia = 0)THEN        
                    INSERT INTO CD_BREAK_VENDITA
                        (DATA_EROGAZIONE,
                        COD_TIPO_PUBB,
                        FLG_ANNULLATO,
                        ID_CIRCUITO_BREAK,
                        ID_PRODOTTO_VENDITA,
                        SECONDI_ASSEGNATI,
                        ID_SALA)
                    VALUES
                        (p_data_proiezione,
                        tabs.COD_TIPO_PUBB,
                        v_flg,
                        p_id_circuito_break,
                        temp.ID_PRODOTTO_VENDITA,
                        0,
                        v_id_sala);
                END IF;    
            END IF;
        END LOOP;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_REFRESH_TARIFFE_BR: si e'' verificato un errore. '||SQLERRM);
        ROLLBACK TO SP_PR_REFRESH_TARIFFE_BR;
END;
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_CIN
-------------------------------------------------------------------------------------------------
-- DESCRIZIONE: chiamata dall'interno della creazione di un circuito cinema
--              si occupa di generare gli eventuali cinema di vendita per quelle tariffe create prima
--              della creazione di un insieme di circuiti cinema
--
-- INPUT:
--      p_id_listino         l'id del listino in cui e' stato inserito il nuovo circuito_break
--      p_id_circuito        l'id del circuito in cui e' stato inserito il nuovo circuito_break
--        p_id_circuito_cinema l'ide del nuovo circuito cinema appena inserito
--
-- OUTPUT: nessun risultato previsto, solo un eccezione in caso di errore
--
-- REALIZZATORE: Francesco Abbundo, Roberto Barbaro, Teoresi srl, Ottobre 2009, Gennaio 2010
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_REFRESH_TARIFFE_CIN(p_id_listino         CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_id_circuito_cinema  CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA%TYPE)
IS
    v_temp                  INTEGER;
    v_dimmi_se_esisto_gia   INTEGER;
BEGIN
    SAVEPOINT SP_PR_REFRESH_TARIFFE_CIN;
    FOR temp IN(SELECT ID_PRODOTTO_VENDITA,DATA_INIZIO,DATA_FINE FROM CD_TARIFFA
                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA IN (
                      SELECT ID_PRODOTTO_VENDITA FROM CD_PRODOTTO_VENDITA
                                            WHERE ID_CIRCUITO = p_id_circuito))LOOP
        FOR tabs IN(SELECT TABA.COD_TIPO_PUBB, TABB.CODICE
                  FROM (SELECT COD_TIPO_PUBB FROM VENPC.PC_TIPI_PUBBLICITA WHERE COD_TIPO_PUBB IN (
                            SELECT COD_TIPO_PUBB FROM CD_TIPO_PUBB_GRUPPO WHERE ID_GRUPPO_TIPI_PUBB IN (
                                SELECT ID_GRUPPO_TIPI_PUBB FROM CD_GRUPPO_TIPI_PUBB WHERE ID_GRUPPO_TIPI_PUBB IN (
                                    SELECT ID_GRUPPO_TIPI_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                                        SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))))
                        OR COD_TIPO_PUBB IN (SELECT COD_TIPO_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                            SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))) TABA,
                       (SELECT COD_TIPO_PUBB, CODICE FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB WHERE CD_LUOGO_TIPO_PUBB.ID_LUOGO = CD_LUOGO.ID_LUOGO) TABB
                  WHERE TABA.COD_TIPO_PUBB = TABB.COD_TIPO_PUBB) LOOP
            IF(tabs.CODICE='CIN')THEN
                v_temp:=temp.DATA_FINE-temp.DATA_INIZIO;
                FOR GIORNO IN 0..v_temp LOOP
                        SELECT COUNT(*)
                        INTO v_dimmi_se_esisto_gia
                        FROM  CD_CINEMA_VENDITA
                        WHERE CD_CINEMA_VENDITA.DATA_EROGAZIONE = temp.DATA_INIZIO+GIORNO
                        AND   CD_CINEMA_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                        AND   CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = p_id_circuito_cinema
                        AND   CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA;
                        IF(v_dimmi_se_esisto_gia = 0)THEN
                            INSERT INTO CD_CINEMA_VENDITA
                                (DATA_EROGAZIONE, COD_TIPO_PUBB, FLG_ANNULLATO, ID_CIRCUITO_CINEMA, ID_PRODOTTO_VENDITA)
                            VALUES
                                (temp.DATA_INIZIO+GIORNO, tabs.COD_TIPO_PUBB, 'N', p_id_circuito_cinema, temp.ID_PRODOTTO_VENDITA);
                        END IF;
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_REFRESH_TARIFFE_CIN: si e'' verificato un errore. '||SQLERRM);
        ROLLBACK TO SP_PR_REFRESH_TARIFFE_CIN;
END;
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_ATR
-------------------------------------------------------------------------------------------------
-- DESCRIZIONE: chiamata dall'interno della creazione di un circuito atrio
--              si occupa di generare gli eventuali atrii di vendita per quelle tariffe create prima
--              della creazione di un insieme di circuiti atrio
--
-- INPUT:
--      p_id_listino         l'id del listino in cui e' stato inserito il nuovo circuito_break
--      p_id_circuito        l'id del circuito in cui e' stato inserito il nuovo circuito_break
--        p_id_circuito_atrio  l'id del nuovo circuito atrio appena inserito
--
-- OUTPUT: nessun risultato previsto, solo un eccezione in caso di errore
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Ottobre 2009, Gennaio 2010
-------------------------------------------------------------------------------------------------
PROCEDURE PR_REFRESH_TARIFFE_ATR(p_id_listino         CD_TARIFFA.ID_LISTINO%TYPE,
                                p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_id_circuito_atrio  CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO%TYPE)
IS
    v_temp                  INTEGER;
    v_dimmi_se_esisto_gia   INTEGER;
BEGIN
    SAVEPOINT SP_PR_REFRESH_TARIFFE_ATR;
    FOR temp IN(SELECT ID_PRODOTTO_VENDITA,DATA_INIZIO,DATA_FINE FROM CD_TARIFFA
                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA IN (
                      SELECT ID_PRODOTTO_VENDITA FROM CD_PRODOTTO_VENDITA
                                            WHERE ID_CIRCUITO = p_id_circuito))LOOP
        FOR tabs IN(SELECT TABA.COD_TIPO_PUBB, TABB.CODICE
                  FROM (SELECT COD_TIPO_PUBB FROM VENPC.PC_TIPI_PUBBLICITA WHERE COD_TIPO_PUBB IN (
                            SELECT COD_TIPO_PUBB FROM CD_TIPO_PUBB_GRUPPO WHERE ID_GRUPPO_TIPI_PUBB IN (
                                SELECT ID_GRUPPO_TIPI_PUBB FROM CD_GRUPPO_TIPI_PUBB WHERE ID_GRUPPO_TIPI_PUBB IN (
                                    SELECT ID_GRUPPO_TIPI_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                                        SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))))
                        OR COD_TIPO_PUBB IN (SELECT COD_TIPO_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                            SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))) TABA,
                       (SELECT COD_TIPO_PUBB, CODICE FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB WHERE CD_LUOGO_TIPO_PUBB.ID_LUOGO = CD_LUOGO.ID_LUOGO) TABB
                  WHERE TABA.COD_TIPO_PUBB = TABB.COD_TIPO_PUBB) LOOP
            IF(tabs.CODICE='ATR')THEN
                v_temp:=temp.DATA_FINE-temp.DATA_INIZIO;
                FOR GIORNO IN 0..v_temp LOOP
                        SELECT COUNT(*)
                        INTO v_dimmi_se_esisto_gia
                        FROM CD_ATRIO_VENDITA
                        WHERE CD_ATRIO_VENDITA.DATA_EROGAZIONE = temp.DATA_INIZIO+GIORNO
                        AND   CD_ATRIO_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                        AND   CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = p_id_circuito_atrio
                        AND   CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA;
                        IF(v_dimmi_se_esisto_gia = 0)THEN
                            INSERT INTO CD_ATRIO_VENDITA
                                (DATA_EROGAZIONE, COD_TIPO_PUBB, FLG_ANNULLATO, ID_CIRCUITO_ATRIO, ID_PRODOTTO_VENDITA)
                            VALUES
                                (temp.DATA_INIZIO+GIORNO, tabs.COD_TIPO_PUBB, 'N', p_id_circuito_atrio, temp.ID_PRODOTTO_VENDITA);
                        END IF;    
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_REFRESH_TARIFFE_ATR: si e'' verificato un errore. '||SQLERRM);
        ROLLBACK TO SP_PR_REFRESH_TARIFFE_ATR;
END;
-----------------------------------------------------------------------------------------------------
-- Procedure PR_REFRESH_TARIFFE_SAL
-------------------------------------------------------------------------------------------------
-- DESCRIZIONE: chiamata dall'interno della creazione di un circuito sala
--              si occupa di generare le eventuali sale di vendita per
--              quelle tariffe create prima della creazione di un insieme
--              di circuiti sala
--
-- INPUT:   p_id_listino        l'id del listino in cui e' stato inserito il nuovo circuito_break
--          p_id_circuito       l'id del circuito in cui e' stato inserito il nuovo circuito_break
--          p_id_circuito_sala  l'id del nuovo circuito sala appena inserito
--
-- OUTPUT: nessun risultato previsto, solo un eccezione in caso di errore
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Ottobre 2009, Gennaio 2010
--
-------------------------------------------------------------------------------------------------

PROCEDURE PR_REFRESH_TARIFFE_SAL(   p_id_listino CD_TARIFFA.ID_LISTINO%TYPE,
                                    p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_circuito_sala CD_CIRCUITO_SALA.ID_CIRCUITO_SALA%TYPE)
IS
    v_temp                  INTEGER;
    v_dimmi_se_esisto_gia   INTEGER;
BEGIN
    SAVEPOINT SP_PR_REFRESH_TARIFFE_SAL;
    FOR temp IN(SELECT ID_PRODOTTO_VENDITA,DATA_INIZIO,DATA_FINE FROM CD_TARIFFA
                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                AND CD_TARIFFA.ID_PRODOTTO_VENDITA IN (
                        SELECT ID_PRODOTTO_VENDITA FROM CD_PRODOTTO_VENDITA
                        WHERE ID_CIRCUITO = p_id_circuito))LOOP
        FOR tabs IN(SELECT TABA.COD_TIPO_PUBB, TABB.CODICE
                    FROM (SELECT COD_TIPO_PUBB FROM VENPC.PC_TIPI_PUBBLICITA WHERE COD_TIPO_PUBB IN (
                        SELECT COD_TIPO_PUBB FROM CD_TIPO_PUBB_GRUPPO WHERE ID_GRUPPO_TIPI_PUBB IN (
                            SELECT ID_GRUPPO_TIPI_PUBB FROM CD_GRUPPO_TIPI_PUBB WHERE ID_GRUPPO_TIPI_PUBB IN (
                                SELECT ID_GRUPPO_TIPI_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                                    SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))))
                    OR COD_TIPO_PUBB IN (SELECT COD_TIPO_PUBB FROM CD_PRODOTTO_PUBB WHERE ID_PRODOTTO_PUBB IN (
                        SELECT ID_PRODOTTO_PUBB FROM CD_PRODOTTO_VENDITA WHERE ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA))) TABA,
                            (SELECT COD_TIPO_PUBB, CODICE FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB WHERE CD_LUOGO_TIPO_PUBB.ID_LUOGO = CD_LUOGO.ID_LUOGO) TABB
                    WHERE TABA.COD_TIPO_PUBB = TABB.COD_TIPO_PUBB) LOOP
            IF(tabs.CODICE='SAL')THEN
                v_temp:=temp.DATA_FINE-temp.DATA_INIZIO;
                FOR GIORNO IN 0..v_temp LOOP
                    SELECT COUNT(*)
                    INTO v_dimmi_se_esisto_gia
                    FROM CD_SALA_VENDITA
                    WHERE CD_SALA_VENDITA.DATA_EROGAZIONE = temp.DATA_INIZIO+GIORNO
                    AND   CD_SALA_VENDITA.COD_TIPO_PUBB = tabs.COD_TIPO_PUBB
                    AND   CD_SALA_VENDITA.ID_CIRCUITO_SALA = p_id_circuito_sala 
                    AND   CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = temp.ID_PRODOTTO_VENDITA;
                    IF(v_dimmi_se_esisto_gia = 0)THEN
                        INSERT INTO CD_SALA_VENDITA
                            (DATA_EROGAZIONE, COD_TIPO_PUBB, FLG_ANNULLATO, ID_CIRCUITO_SALA, ID_PRODOTTO_VENDITA)
                        VALUES
                            (temp.DATA_INIZIO+GIORNO, tabs.COD_TIPO_PUBB, 'N', p_id_circuito_sala, temp.ID_PRODOTTO_VENDITA);
                    END IF;    
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_REFRESH_TARIFFE_SAL: si e'' verificato un errore. '||SQLERRM);
        ROLLBACK TO SP_PR_REFRESH_TARIFFE_SAL;
END;
--
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_ALLINEA_TARIFFA_PER_ELIM
-------------------------------------------------------------------------------------------------
-- DESCRIZIONE: questa procedura permette il ricalcolo della tariffa (e di tutti gli importi ad essa collegati
-- a livello di prodotto acquistato) a seguito di una eliminazione di sala o atrio
--
-- INPUT:   p_id_sala        l'id della sala che viene eliminata (null se viene eliminato un atrio)
--          p_id_atrio       l'id dell'atrio che viene eliminato (null se viene eliminata una sala)
--
-- OUTPUT: il numero di record modificati (1 record identifica un prodotto acquistato)
--
-- REALIZZATORE: Daniela Spezia, Altran, Ottobre 2009
-- MODIFICHE:    Daniela Spezia, Altran, Gennaio 2010 - si ricalcola anche il caso con tariffa variabile N
--              in modo che pur variando la tariffa il netto resti uguale (si diminuisce la percentuale di
--              sconto)
--              Antonio Colucci, Teoresi srl, Maggio 2011
--              Ottimizzazione wuery di estrazione prodotti acquistati per TAB-SALA
--              in base alle denormalizzazioni sulla tavola cd_comunicato
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ALLINEA_TARIFFA_PER_ELIM(p_id_sala             cd_sala.ID_SALA%TYPE,
                                   p_id_atrio               cd_atrio.ID_ATRIO%TYPE,
                                   p_id_circuito            cd_circuito.ID_CIRCUITO%TYPE,
                                   p_id_listino             cd_listino.ID_LISTINO%TYPE,
                                   p_esito                  OUT NUMBER,
                                   p_piani_errati           OUT VARCHAR2)
IS
    v_prod_tab              C_PROD_ACQ_CALC_TARIF;
    v_prod_isp              C_PROD_ACQ_CALC_TARIF;
    v_num_prod_tab          NUMBER;
    v_num_prod_isp          NUMBER;
    v_esito_tmp1            NUMBER:=0;
    v_esito_tmp2            NUMBER:=0;
BEGIN
    SAVEPOINT SP_PR_ALLINEA_TARIFFA_PER_ELIM;
--
    p_esito := 0;
-- determino se sono nel caso di eliminazione dell'atrio o della sala
-- e ricerco conseguentemente i prodotti acquistati correlati
    IF (p_id_atrio IS NULL)THEN
    -- sono nel caso della eliminazione sala; cerco i prodotti con tariffa variabile da TAB e ISP
    -- TAB
        OPEN v_prod_tab FOR
            select pa.id_prodotto_acquistato, pa.ID_PRODOTTO_VENDITA, pa.IMP_TARIFFA,
                    pa.IMp_LORDO, pa.IMp_NETTO, pa.IMp_MAGGIORAZIONE,
                    pa.IMp_RECUPERO, pa.IMp_SANATORIA, pian.COD_CATEGORIA_PRODOTTO,
                    pa.FLG_TARIFFA_VARIABILE, pa.data_inizio, pa.data_fine, pa.ID_MISURA_PRD_VE
            from cd_prodotto_acquistato pa, cd_pianificazione pian,
            cd_prodotto_vendita,cd_listino
            where pa.ID_PRODOTTO_ACQUISTATO IN
                (select comun.id_prodotto_acquistato
                     from cd_comunicato comun
                     where flg_annullato = 'N'
                     and flg_sospeso = 'N'
                     and cod_disattivazione is null
                     and comun.ID_SALA = p_id_sala
                 )
            and pa.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita
            and cd_prodotto_vendita.id_circuito = p_id_circuito
            and cd_listino.id_listino = p_id_listino
            and pa.data_inizio between cd_listino.data_inizio and cd_listino.data_fine 
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            AND pa.COD_DISATTIVAZIONE IS NULL
            --and pa.FLG_TARIFFA_VARIABILE = 'S'
            and pian.id_piano = pa.id_piano and pian.id_ver_piano = pa.id_ver_piano
            order by pa.id_prodotto_acquistato;
        v_num_prod_tab := SQL%ROWCOUNT;
        --dbms_output.put_line('Numero prodotti: '||v_num_prod_tab);
        -- ISP
        OPEN v_prod_isp FOR
            select pa.id_prodotto_acquistato, pa.ID_PRODOTTO_VENDITA, pa.IMP_TARIFFA,
                    pa.IMP_LORDO, pa.IMP_NETTO, pa.IMP_MAGGIORAZIONE,
                    pa.IMP_RECUPERO, pa.IMP_SANATORIA, pian.COD_CATEGORIA_PRODOTTO,
                    pa.FLG_TARIFFA_VARIABILE, pa.data_inizio, pa.data_fine,pa.ID_MISURA_PRD_VE
            from cd_prodotto_acquistato pa, cd_pianificazione pian
            where pa.ID_PRODOTTO_VENDITA IN
                (SELECT sala_ven.ID_PRODOTTO_VENDITA
                     FROM CD_SALA_VENDITA sala_ven, cd_circuito_sala circ_sala
                     WHERE sala_ven.id_circuito_sala = circ_sala.id_circuito_sala
                     AND (p_id_circuito is null or circ_sala.id_circuito = p_id_circuito)
                     AND circ_sala.id_sala = p_id_sala)
            and pa.flg_annullato = 'N'
            --and pa.FLG_TARIFFA_VARIABILE = 'S'
            and pian.id_piano = pa.id_piano and pian.id_ver_piano = pa.id_ver_piano
            order by pa.id_prodotto_acquistato;
        v_num_prod_isp := SQL%ROWCOUNT;
    ELSE
    -- sono nel caso della eliminazione atrio; cerco i prodotti da TAB e ISP
    -- TAB
        OPEN v_prod_tab FOR
            select pa.id_prodotto_acquistato, pa.ID_PRODOTTO_VENDITA, pa.IMP_TARIFFA,
                    pa.IMP_LORDO, pa.IMP_NETTO, pa.IMP_MAGGIORAZIONE,
                    pa.IMP_RECUPERO, pa.IMP_SANATORIA, pian.COD_CATEGORIA_PRODOTTO,
                    pa.FLG_TARIFFA_VARIABILE, pa.data_inizio, pa.data_fine,pa.ID_MISURA_PRD_VE
            from cd_prodotto_acquistato pa, cd_pianificazione pian
            where pa.ID_PRODOTTO_ACQUISTATO IN
                (select comun.id_prodotto_acquistato
                     from cd_comunicato comun
                     where comun.flg_annullato = 'N'
                     and   comun.flg_sospeso = 'N'
                     and   comun.cod_disattivazione is null
                     and comun.ID_BREAK_VENDITA IN
                     (SELECT bv.ID_BREAK_VENDITA
                             FROM   CD_BREAK_VENDITA bv
                             WHERE  bv.flg_annullato = 'N'
                             AND bv.ID_CIRCUITO_BREAK IN
                             (SELECT  circ_b.ID_CIRCUITO_BREAK
                                          FROM      CD_CIRCUITO_BREAK circ_b
                                          WHERE circ_b.flg_annullato = 'N'
                                          AND circ_b.id_listino = p_id_listino
                                          AND (p_id_circuito is null or circ_b.id_circuito = p_id_circuito)
                                          AND circ_b.ID_BREAK IN
                                          (SELECT  br.ID_BREAK
                                                    FROM       CD_BREAK br
                                                    WHERE      br.flg_Annullato = 'N'
                                                    AND br.ID_PROIEZIONE IN
                                                    (SELECT pro.id_proiezione
                                                        from cD_proiezione pro, cd_schermo sche
                                                        where pro.flg_annullato = 'N'
                                                        and sche.flg_annullato = 'N'
                                                        and pro.id_schermo = sche.id_schermo
                                                        and sche.id_atrio = p_id_atrio)))))
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.cod_disattivazione is null
            --and pa.FLG_TARIFFA_VARIABILE = 'S'
            and pian.id_piano = pa.id_piano and pian.id_ver_piano = pa.id_ver_piano
            order by pa.id_prodotto_acquistato;
        v_num_prod_tab := SQL%ROWCOUNT;
        -- ISP
        OPEN v_prod_isp FOR
            select pa.id_prodotto_acquistato, pa.ID_PRODOTTO_VENDITA, pa.IMP_TARIFFA,
                        pa.IMP_LORDO, pa.IMP_NETTO, pa.IMP_MAGGIORAZIONE,
                        pa.IMP_RECUPERO, pa.IMP_SANATORIA, pian.COD_CATEGORIA_PRODOTTO,
                        pa.FLG_TARIFFA_VARIABILE, pa.data_inizio, pa.data_fine,pa.ID_MISURA_PRD_VE
            from cd_prodotto_acquistato pa, cd_pianificazione pian
            where pa.ID_PRODOTTO_VENDITA IN
                (SELECT atrio_ven.ID_PRODOTTO_VENDITA
                     FROM CD_ATRIO_VENDITA atrio_ven, cd_circuito_atrio circ_atrio
                     WHERE atrio_ven.id_circuito_atrio = circ_atrio.id_circuito_atrio
                     AND circ_atrio.id_atrio = p_id_atrio)
            and pa.flg_annullato = 'N'
            --and pa.FLG_TARIFFA_VARIABILE = 'S'
            and pian.id_piano = pa.id_piano and pian.id_ver_piano = pa.id_ver_piano
            order by pa.id_prodotto_acquistato;
        v_num_prod_isp := SQL%ROWCOUNT;
    END IF;
-- per ognuno dei record sul prodotto acquistato reperiti, procedo con l'allineamento tariffa
    PA_CD_TARIFFA.PR_RICALCOLA_TARIFFE(v_prod_tab, p_id_sala, p_id_atrio, v_esito_tmp1,p_piani_errati);
    PA_CD_TARIFFA.PR_RICALCOLA_TARIFFE(v_prod_isp, p_id_sala, p_id_atrio, v_esito_tmp2,p_piani_errati);
    p_esito := v_esito_tmp1 + v_esito_tmp2;
--
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20030, 'Procedura PR_ALLINEA_TARIFFA_PER_ELIM: Update non eseguito '||SQLERRM);
    ROLLBACK TO SP_PR_ALLINEA_TARIFFA_PER_ELIM;
END;
--
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_RICALCOLA_TARIFFE
-------------------------------------------------------------------------------------------------
-- DESCRIZIONE: questa procedura esegue l'effettivo ricalcolo della tariffa (e di tutti gli importi ad essa collegati
-- a livello di prodotto acquistato) a seguito di una eliminazione di sala o atrio per l'elenco di
-- prodotti acquistati correlati a quella sala o atrio; dopo aver determinato i nuovi importi
-- aggiorna la banca dati (tabelle cd_prodotto_acquistato e cd_import_prodotto)
--
-- INPUT:   p_lista_prod_acq l'elenco dei prodotti acquistati collegati alla sala/atrio eliminato
--          p_id_sala        l'id della sala che viene eliminata (null se viene eliminato un atrio)
--          p_id_atrio       l'id dell'atrio che viene eliminato (null se viene eliminata una sala)
--
-- OUTPUT: il numero di record modificati (1 record identifica un prodotto acquistato)
--
-- REALIZZATORE: Daniela Spezia, Altran, Ottobre 2009
-- MODIFICHE:    Daniela Spezia, Altran, Gennaio 2010 - si ricalcola anche il caso con tariffa variabile N
--              in modo che pur variando la tariffa il netto resti uguale (si diminuisce la percentuale di
--              sconto)
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFE( p_lista_prod_acq         C_PROD_ACQ_CALC_TARIF,
                                p_id_sala                cd_sala.ID_SALA%TYPE,
                                p_id_atrio               cd_atrio.ID_ATRIO%TYPE,
                                p_esito                  OUT NUMBER,
                                p_piani_errati           OUT VARCHAR2)
IS
    v_temp              NUMBER:=0;
    v_record_prod_acq   R_PROD_ACQ_CALC_TARIF;
    v_record_comm       R_IMPORTI_PROD;
    v_record_direz      R_IMPORTI_PROD;
    v_esito_rec_c       NUMBER;
    v_esito_rec_d       NUMBER;
    -- campi per l'input e output della procedura pc_cd_importi.modifica_importi()
    v_tariffa           NUMBER;
    v_maggioraz         NUMBER;
    v_lordo             NUMBER;
    v_lordo_comm        NUMBER;
    v_lordo_dir         NUMBER;
    v_netto_comm        NUMBER;
    v_netto_dir         NUMBER;
    v_perc_sc_c         NUMBER;
    v_perc_sc_d         NUMBER;
    v_sconto_comm       NUMBER;
    v_sconto_dir        NUMBER;
    v_sanatoria         NUMBER;
    v_recupero          NUMBER;
    v_id_imp_prod_c     cd_importi_prodotto.ID_IMPORTI_PRODOTTO%TYPE;
    v_id_imp_prod_d     cd_importi_prodotto.ID_IMPORTI_PRODOTTO%TYPE;
    v_data_inizio       cd_prodotto_acquistato.data_inizio%type;
    v_data_fine         cd_prodotto_acquistato.data_fine%type;
    v_id_piano          cd_prodotto_acquistato.ID_PIANO%type;
    v_id_ver_piano      cd_prodotto_acquistato.ID_VER_PIANO%type;
BEGIN
    SAVEPOINT SP_PR_RICALCOLA_TARIFFE;
--
    p_esito:=0;
    p_piani_errati := ' ';
    LOOP
        BEGIN
        FETCH p_lista_prod_acq INTO v_record_prod_acq;
        EXIT WHEN p_lista_prod_acq%NOTFOUND;
        --
        -- reperisco i record relativi ai valori direzionale e commerciale dalla cd_importi_prodotto ...
        PA_CD_TARIFFA.PR_GET_IMPORTI_PROD(v_record_prod_acq.a_id_prod_acq, 'C', v_record_comm, v_esito_rec_c);
        PA_CD_TARIFFA.PR_GET_IMPORTI_PROD(v_record_prod_acq.a_id_prod_acq, 'D', v_record_direz, v_esito_rec_d);
        --
        -- ... quindi determino i valori del lordo commerciale e direzionale
        -- e valorizzo opportunamente tutti i parametri di input della pc_cd_importi.modifica_importi()
        v_tariffa := v_record_prod_acq.a_tariffa;
        v_maggioraz := v_record_prod_acq.a_maggiorazione;
        v_lordo := v_record_prod_acq.a_imp_lordo;
        v_lordo_comm := PA_PC_IMPORTI.FU_LORDO_COMM(v_record_comm.a_imp_netto, v_record_comm.a_imp_sc_comm);
        v_lordo_dir := PA_PC_IMPORTI.FU_LORDO_COMM(v_record_direz.a_imp_netto, v_record_direz.a_imp_sc_comm);
        v_netto_comm := v_record_comm.a_imp_netto;
        v_netto_dir := v_record_direz.a_imp_netto;
        v_sconto_comm := v_record_comm.a_imp_sc_comm;
        v_sconto_dir := v_record_direz.a_imp_sc_comm;
        --v_perc_sc_c := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm, v_sconto_comm);
        --v_perc_sc_d := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir, v_sconto_dir);
        v_sanatoria := v_record_prod_acq.a_sanatoria;
        v_recupero := v_record_prod_acq.a_recupero;
        v_id_imp_prod_c := v_record_comm.a_id_importi_prod;
        v_id_imp_prod_d := v_record_direz.a_id_importi_prod;
        v_data_inizio := v_record_prod_acq.a_data_inizio;
        v_data_fine := v_record_prod_acq.a_data_fine;
        --
        -- richiamo la procedura che esegue il vero e proprio ricalcolo della tariffa
        -- 07.01.2010: distinguo i casi di tariffa fissa e variabile: modifico la procedura seguente e
        -- le passo il flag_tariffa_variabile
       dbms_output.put_line('Chiamo il ricalcolo per il prodotto acquistato con id: '||v_record_prod_acq.a_id_prod_acq);
        PR_RICALCOLA_TARIFFA_VARFIX(v_record_prod_acq.a_id_prod_acq, v_record_prod_acq.a_id_prod_vend,
                                            v_record_prod_acq.a_tipo_fam_pubb, p_id_sala, p_id_atrio,
                                            v_tariffa, v_maggioraz, v_lordo, v_lordo_comm, v_lordo_dir,
                                            v_netto_comm, v_netto_dir, --v_perc_sc_c, v_perc_sc_d,
                                            v_sconto_comm, v_sconto_dir, v_sanatoria, v_recupero,
                                            v_id_imp_prod_c, v_id_imp_prod_d,
                                            v_record_prod_acq.a_flg_tariffa_var, v_data_inizio, v_data_fine, v_record_prod_acq.a_id_misura_temp, v_temp);
        IF(v_temp>=0)THEN
            p_esito:=p_esito+1;
        END IF;

       EXCEPTION
       WHEN ERR_VARIAZIONE_TARIFFA then
       SELECT ID_PIANO, ID_VER_PIANO
       INTO v_id_piano, v_id_ver_piano
       FROM CD_PRODOTTO_ACQUISTATO
       WHERE ID_PRODOTTO_ACQUISTATO = v_record_prod_acq.a_id_prod_acq;
       p_piani_errati := p_piani_errati || v_id_piano||'/'||v_id_ver_piano||', ';
       END;
    END LOOP;

    CLOSE p_lista_prod_acq;

EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20030, 'Procedura PR_RICALCOLA_TARIFFE: Update non eseguito '||SQLERRM);
    ROLLBACK TO SP_PR_RICALCOLA_TARIFFE;
END;
--
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_RICALCOLA_TARIFFA_VARFIX
-------------------------------------------------------------------------------------------------
-- DESCRIZIONE: questa procedura esegue l'effettivo ricalcolo della tariffa (e di tutti gli altri importi) per il
-- prodotto acquistato fornito in input; per eseguire il ricalcolo viene richiamata la procedura
-- PA_CD_IMPORTI.MODIFICA_IMPORTI() con il nuovo importo della tariffa
--
-- INPUT:
--  p_id_prodotto_acquistato    identificativo del prodotto acquistato in esame
--  p_id_prodotto_vendita       identificativo del prodotto di vendita (ottenuto dal prodotto acquistato)
--  p_tipo_famiglia_pubb        identificativo della famiglia pubblicitaria
--  p_id_sala                   identificativo della sala (null se la procedura e legata all'eliminazione di un atrio)
--  p_id_atrio                  identificativo dell'atrio (null se la procedura e legata all'eliminazione di una sala)
--  p_tariffa                   importo tariffa (relativo al prodotto acquistato)
--  p_maggiorazione             importo maggiorazione (relativo al prodotto acquistato)
--  p_lordo                     importo lordo (relativo al prodotto acquistato)
--  p_lordo_c                   importo lordo commerciale (calcolato sulla base del netto e dello sconto)
--  p_lordo_d                   importo lordo direzionale (calcolato sulla base del netto e dello sconto)
--  p_netto_c                   importo netto commerciale (relativo al prod. acquistato tramite la tabella cd_importi_prodotto)
--  p_netto_d                   importo netto direzionale (relativo al prod. acquistato tramite la tabella cd_importi_prodotto)
--  p_perc_sc_c                 percentuale sconto commerciale (relativo al prod. acquistato tramite la tabella cd_importi_prodotto)
--  p_perc_sc_d                 percentuale sconto direzionale (relativo al prod. acquistato tramite la tabella cd_importi_prodotto)
--  p_sconto_c                  importo sconto commerciale (relativo al prod. acquistato tramite la tabella cd_importi_prodotto)
--  p_sconto_d                  importo sconto direzionale (relativo al prod. acquistato tramite la tabella cd_importi_prodotto)
--  p_sanatoria                 importo sanatoria (relativo al prodotto acquistato)
--  p_recupero                  importo recupero (relativo al prodotto acquistato)
--  p_id_importi_c              identificativo degli importi commerciali (relativi al prodotto acquistato)
--  p_id_importi_d              identificativo degli importi direzionali (relativi al prodotto acquistato)
--  p_flg_tariffa_var           flag che distingue i casi a tariffa variabile (S) e fissa (N)
--
-- OUTPUT: l'esito del ricalcolo tariffa e dei conseguenti aggiornamenti su Db;
--          1 indica che il ricalcolo in esame e' stato eseguito con successo
--          -1 indica che il ricalcolo in esame ha incontrato dei problemi e quindi il db non e' stato aggiornato
--
-- REALIZZATORE: Daniela Spezia, Altran, Ottobre 2009
-- MODIFICHE:    Daniela Spezia, Altran, Gennaio 2010 - si ricalcola anche il caso con tariffa variabile N
--              in modo che pur variando la tariffa il netto resti uguale (si diminuisce la percentuale di
--              sconto)
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA_VARFIX(p_id_prodotto_acquistato  cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_id_prodotto_vendita   cd_prodotto_vendita.ID_PRODOTTO_VENDITA%TYPE,
                                        p_tipo_famiglia_pubb    cd_pianificazione.COD_CATEGORIA_PRODOTTO%TYPE,
                                        p_id_sala               cd_sala.ID_SALA%TYPE,
                                        p_id_atrio              cd_atrio.ID_ATRIO%TYPE,
                                        p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
                                        p_maggiorazione         cd_prodotto_acquistato.IMP_MAGGIORAZIONE%TYPE,
                                        p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
                                        p_lordo_c               NUMBER,
                                        p_lordo_d               NUMBER,
                                        p_netto_c               cd_importi_prodotto.IMP_NETTO%TYPE,
                                        p_netto_d               cd_importi_prodotto.IMP_NETTO%TYPE,
                                      --  p_perc_sc_c             cd_importi_prodotto.PERC_SCONTO_SOST_AGE%TYPE,
                                      --  p_perc_sc_d             cd_importi_prodotto.PERC_SCONTO_SOST_AGE%TYPE,
                                        p_sconto_c              cd_importi_prodotto.IMP_SC_COMM%TYPE,
                                        p_sconto_d              cd_importi_prodotto.IMP_SC_COMM%TYPE,
                                        p_sanatoria             cd_prodotto_acquistato.IMP_SANATORIA%TYPE,
                                        p_recupero              cd_prodotto_acquistato.IMP_RECUPERO%TYPE,
                                        p_id_importi_c          cd_importi_prodotto.ID_IMPORTI_PRODOTTO%TYPE,
                                        p_id_importi_d          cd_importi_prodotto.ID_IMPORTI_PRODOTTO%TYPE,
                                        p_flg_tariffa_var       cd_prodotto_acquistato.FLG_TARIFFA_VARIABILE%TYPE,
                                        p_data_inizio           cd_prodotto_acquistato.DATA_INIZIO%TYPE,
                                        p_data_fine             cd_prodotto_acquistato.DATA_FINE%TYPE,
                                        p_misura_temp           cd_prodotto_acquistato.ID_MISURA_PRD_VE%TYPE,
                                        p_esito                  OUT NUMBER)
IS
    v_num_schermi               NUMBER;
    v_num_sale                  NUMBER;
    v_num_atri                  NUMBER;
    v_tariffa_base              NUMBER;
    v_aliquota_coeff_cin        NUMBER;
    v_tariffa_normalizz         NUMBER;
    v_nuovo_importo_tariffa     NUMBER;
    v_nuovo_lordo               NUMBER;
    v_nuovo_netto               NUMBER;
    v_nuova_maggiorazione       NUMBER;
    v_nuovo_sconto              NUMBER;
    -- campi per l'input e output della procedura pc_cd_importi.modifica_importi()
    v_tariffa           NUMBER:= nvl(p_tariffa, 0);
    v_maggioraz         NUMBER:= nvl(p_maggiorazione, 0);
    v_lordo             NUMBER:= nvl(p_lordo, 0);
    v_lordo_comm        NUMBER:= nvl(p_lordo_c, 0);
    v_lordo_dir         NUMBER:= nvl(p_lordo_d, 0);
    v_netto_comm        NUMBER:= nvl(p_netto_c, 0);
    v_netto_dir         NUMBER:= nvl(p_netto_d, 0);
    v_perc_sc_c         NUMBER:= PA_PC_IMPORTI.FU_PERC_SC_COMM(p_netto_c, p_sconto_c);
    v_perc_sc_d         NUMBER:= PA_PC_IMPORTI.FU_PERC_SC_COMM(p_netto_d, p_sconto_d);
    v_sconto_comm       NUMBER:= nvl(p_sconto_c, 0);
    v_sconto_dir        NUMBER:= nvl(p_sconto_d, 0);
    v_sanatoria         NUMBER:= nvl(p_sanatoria, 0);
    v_recupero          NUMBER:= nvl(p_recupero, 0);
    v_netto_origine_c  NUMBER;
    v_netto_origine_d  NUMBER;
    v_sconto_stag      CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
    v_formato          CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
    v_piani_errati     VARCHAR2(20000);
--
BEGIN
    SAVEPOINT SP_PR_RICALCOLA_TARIFFA_VARFIX;
--
    p_esito := 0;
-- memorizzo i vecchi valori del netto, che saranno utili nel caso di tariffa fissa
    v_netto_origine_c := v_netto_comm;
    v_netto_origine_d := v_netto_dir;
-- determino i valori per il calcolo dei nuovi importi ed eseguo il calcolo
    SELECT importo INTO v_tariffa_base from cd_tariffa
    where id_prodotto_vendita = p_id_prodotto_vendita
    and p_data_inizio BETWEEN DATA_INIZIO AND DATA_FINE
    and p_data_fine BETWEEN DATA_INIZIO AND DATA_FINE;

    SELECT cc.aliquota, pa.id_formato
    into v_aliquota_coeff_cin, v_formato
        from cd_prodotto_acquistato pa, cd_formato_acquistabile f, cd_coeff_cinema cc
        where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
        and f.id_formato = pa.id_formato
        and cc.id_coeff = f.id_coeff;

    IF(v_aliquota_coeff_cin IS NULL) THEN
        v_aliquota_coeff_cin := 1;
    END IF;

    v_sconto_stag := pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(p_id_prodotto_vendita, p_data_inizio, p_data_fine,v_formato,p_misura_temp);

    v_tariffa_normalizz := ROUND((v_tariffa_base - (v_tariffa_base * v_sconto_stag / 100)) * v_aliquota_coeff_cin,2);
    --
    IF(p_tipo_famiglia_pubb = 'TAB') THEN
        v_num_schermi := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato);
        v_nuovo_importo_tariffa := v_tariffa_normalizz * v_num_schermi;
    ELSE
        IF(p_id_atrio IS NULL) THEN
            v_num_sale := PA_CD_TARIFFA.FU_GET_NUM_SALE_PV(p_id_prodotto_vendita);
            v_nuovo_importo_tariffa := v_tariffa_normalizz * v_num_sale;
        ELSE
            v_num_atri := PA_CD_TARIFFA.FU_GET_NUM_ATRI_PV(p_id_prodotto_vendita);
            v_nuovo_importo_tariffa := v_tariffa_normalizz * v_num_atri;
        END IF;
    END IF;
-- richiamo il package importi per gli altri calcoli
   /* dbms_output.put_line('Tariffa: '||v_tariffa);
    dbms_output.put_line('Maggiorazione: '||v_maggioraz);
    dbms_output.put_line('Lordo tot: '||v_lordo);
    dbms_output.put_line('Lordo comm: '||v_lordo_comm);
    dbms_output.put_line('Lordo dir: '||v_lordo_dir);
    dbms_output.put_line('Netto comm: '||v_netto_comm);
    dbms_output.put_line('Netto dir: '||v_netto_dir);
    dbms_output.put_line('P sconto comm: '||v_perc_sc_c);
    dbms_output.put_line('P sconto dir: '|| v_perc_sc_d);
    dbms_output.put_line('Imp sconto comm: '||v_sconto_comm);
    dbms_output.put_line('Imp scpmnto dir: '||v_sconto_dir);
    dbms_output.put_line('nuova tariffa: '||v_nuovo_importo_tariffa);
    */
    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa, v_maggioraz, v_lordo, v_lordo_comm, v_lordo_dir,
                                    v_netto_comm, v_netto_dir, v_perc_sc_c, v_perc_sc_d,
                                    v_sconto_comm, v_sconto_dir, v_sanatoria, v_recupero,
                                    v_nuovo_importo_tariffa, '0', p_esito);
-- nel caso della tariffa VARIABILE si procede semplicemente con l'aggiornamento
-- per la tariffa FISSA invece si deve verificare l'importo originario:
-- se quello nuovo e' minore si deve cercare di riportarlo al valore originario diminuendo lo sconto
-- se lo sconto in questo modo assume valori <= 0 allora non si fa l'aggiornamento e si avvisa l'utente
    IF(p_flg_tariffa_var = 'N')THEN
        IF(v_netto_origine_c != v_netto_comm OR v_netto_origine_d != v_netto_dir)THEN
            -- richiamo per la eventuale riduzione dello sconto, sia commerciale che direzionale
            IF(v_netto_origine_c != v_netto_comm)THEN
                PA_CD_IMPORTI.MODIFICA_IMPORTI(v_nuovo_importo_tariffa, v_maggioraz, v_lordo,
                                                v_lordo_comm, v_lordo_dir, v_netto_comm, v_netto_dir,
                                                v_perc_sc_c, v_perc_sc_d, v_sconto_comm, v_sconto_dir,
                                                v_sanatoria, v_recupero, v_netto_origine_c, '31', p_esito);
            END IF;
            IF(v_netto_origine_d != v_netto_dir)THEN
                PA_CD_IMPORTI.MODIFICA_IMPORTI(v_nuovo_importo_tariffa, v_maggioraz, v_lordo,
                                                v_lordo_comm, v_lordo_dir, v_netto_comm, v_netto_dir,
                                                v_perc_sc_c, v_perc_sc_d, v_sconto_comm, v_sconto_dir,
                                                v_sanatoria, v_recupero, v_netto_origine_d, '32', p_esito);
            END IF;
        END IF;
    END IF;
-- eseguo l'aggiornamento su db: prima la tabella prodotto acquistato
            PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_TARIFFA_PROD_ACQ(p_id_prodotto_acquistato,
                              v_nuovo_importo_tariffa,
                              v_tariffa,
                              'S',
                              v_piani_errati);
    /*UPDATE CD_PRODOTTO_ACQUISTATO
        SET
            IMP_TARIFFA = v_nuovo_importo_tariffa,
            IMP_MAGGIORAZIONE = v_maggioraz,
            IMP_RECUPERO = v_recupero,
            IMP_SANATORIA = v_sanatoria,
            IMP_LORDO = v_lordo,
            IMP_NETTO = v_netto_comm + v_netto_dir
       WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
--
-- poi la tabella cd_importi_prodotto, 2 volte (commerciale e direzionale)
-- nel caso di tariffa fissa potrebbero essere cambiati i valori di sconto
    UPDATE CD_IMPORTI_PRODOTTO
        SET
            IMP_NETTO = v_netto_comm, --p_netto_c,
            IMP_SC_COMM = v_sconto_comm -- p_sconto_c--,
        --    PERC_SCONTO_SOST_AGE = p_perc_sc_c
        WHERE ID_IMPORTI_PRODOTTO = p_id_importi_c;
    --
    UPDATE CD_IMPORTI_PRODOTTO
        SET
            IMP_NETTO = v_netto_dir, --p_netto_d,
            IMP_SC_COMM = v_sconto_dir--p_sconto_d--,
        --    PERC_SCONTO_SOST_AGE = p_perc_sc_d
        WHERE ID_IMPORTI_PRODOTTO = p_id_importi_d;
--*/
    p_esito := 1;
--
EXCEPTION
    WHEN pa_cd_importi.PERC_SCONTO_NON_VALIDA THEN
        p_esito := -1;
        RAISE ERR_VARIAZIONE_TARIFFA;
    when pa_cd_importi.ERR_VERIFICA then
        p_esito := -1;
        RAISE ERR_VARIAZIONE_TARIFFA;
    when pa_cd_importi.ERR_IMPORTO_VARIATO then
        p_esito := -1;
        RAISE ERR_VARIAZIONE_TARIFFA;
    when pa_cd_importi.ERRORE_GENERICO then
        p_esito := -1;
        RAISE ERR_VARIAZIONE_TARIFFA;
    when pa_cd_importi.VALORE_NEGATIVO then
        p_esito := -1;
        RAISE ERR_VARIAZIONE_TARIFFA;
    when pa_cd_importi.NETTO_ECCESSIVO then
        p_esito := -1;
        RAISE ERR_VARIAZIONE_TARIFFA;
    when others then
        p_esito := -1;
        RAISE ERR_VARIAZIONE_TARIFFA;
END;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_NUM_SALE_PV
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: il numero di sale correlate al prodotto di vendita indicato; tali sale devono avere
-- il flag FLG_ANNULLATO = 'N'
--
-- REALIZZATORE:  Daniela Spezia, Altran, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_SALE_PV(p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE)
                        RETURN NUMBER
IS
num_sale NUMBER;
--
BEGIN
--
    SELECT COUNT(DISTINCT sal.ID_SALA) INTO num_sale
        FROM cd_circuito_sala circ_s, cd_sala_vendita s_ven, cd_sala sal
        WHERE s_ven.id_prodotto_vendita = p_id_prodotto_vendita
        AND s_ven.id_circuito_sala  = circ_s.ID_CIRCUITO_SALA
        AND circ_s.ID_SALA = sal.ID_SALA
        AND sal.FLG_ANNULLATO = 'N';
--
RETURN num_sale;
END FU_GET_NUM_SALE_PV;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_NUM_ATRI_PV
-- --------------------------------------------------------------------------------------------
-- INPUT:
--
-- OUTPUT: il numero di atrii correlati al prodotto di vendita indicato
--
-- REALIZZATORE:  Daniela Spezia, Altran, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_ATRI_PV(p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE)
                        RETURN NUMBER
IS
num_atri NUMBER;
--
BEGIN
--
    SELECT COUNT(DISTINCT atr.ID_ATRIO) INTO num_atri
        FROM cd_circuito_atrio circ_a, cd_atrio_vendita a_ven, cd_atrio atr
        WHERE a_ven.id_prodotto_vendita = p_id_prodotto_vendita
        AND a_ven.id_circuito_atrio  = circ_a.ID_CIRCUITO_ATRIO
        AND circ_a.ID_ATRIO = atr.ID_ATRIO
        AND atr.FLG_ANNULLATO = 'N';
--
RETURN num_atri;
END FU_GET_NUM_ATRI_PV;
--
--
-----------------------------------------------------------------------------------------------------
-- Procedure PR_GET_IMPORTI_PROD
-------------------------------------------------------------------------------------------------
-- DESCRIZIONE: questa procedura restituisce, dato l'id prodotto acquistato, i dati relativi agli importi commerciali
-- o direzioni ad esso collegati
--
-- INPUT:
-- p_id_prodotto_acquistato     identificativo del prodotto acquistato
-- p_tipo_contratto             identificativo degli importi commerciali (C) o direzionali (D)
--
-- OUTPUT: gli importi (commerciali o direzionali) del prodotto acquistato fornito in input
--
-- REALIZZATORE: Daniela Spezia, Altran, Ottobre 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_GET_IMPORTI_PROD(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_tipo_contratto    cd_importi_prodotto.TIPO_CONTRATTO%TYPE,
                                p_record_importi    OUT R_IMPORTI_PROD,
                                p_esito             OUT NUMBER)
IS
BEGIN
    p_esito := 0;
    select ID_PRODOTTO_ACQUISTATO, ID_IMPORTI_PRODOTTO, TIPO_CONTRATTO, IMP_NETTO,
        IMP_SC_COMM--, PERC_SCONTO_SOST_AGE, PERC_VEND_CLI
        into p_record_importi
     from cd_importi_prodotto
     where id_prodotto_acquistato = p_id_prodotto_acquistato
     and tipo_contratto = p_tipo_contratto;
--
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20030, 'Errore in esecuzione di PR_GET_IMPORTI_PROD: '||SQLERRM);
END;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INTERV_MOD_TAR
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Restituisce la data minima e massima entro le quali sono contenuti
--               comunicati all'interno dei prodotti acquistati selezionati
-- INPUT:
--    p_data_inizio                 data iniziale di ricerca prodotti acquistati
--    p_data_fine                   data finale di ricerca prodotti acquistati
--    p_id_prodotto_vendita         id del prodotto di vendita
--    p_id_misura_prd_ve            id della misura del prodotto di vendita
--    p_id_tipo_cinema              id del tipo cinema
--    p_id_formato                  id del formato
-- OUTPUT: cursore contenente la data minima e la massima.
--         La tariffa e' modificabile all'esterno di quell'intervallo.
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 26 Gennaio 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INTERV_MOD_TAR( p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                            p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                            p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                            p_id_misura_prd_ve      CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                            p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE,
                            p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE
                            )
                            RETURN C_INTERVALLO_DATE
IS
    v_return_cursor     C_INTERVALLO_DATE;
BEGIN
    OPEN v_return_cursor
        FOR
            SELECT 
                MIN(DATA_INIZIO)    AS DATA_MIN, 
                MAX(DATA_FINE)      AS DATA_MAX
            FROM 
                CD_PRODOTTO_ACQUISTATO
            -- Il periodo del prodotto acquistato e' compreso tra le date inizio-fine selezionate
            WHERE  ( ( CD_PRODOTTO_ACQUISTATO.DATA_INIZIO  BETWEEN p_data_inizio AND p_data_fine )
            OR       ( CD_PRODOTTO_ACQUISTATO.DATA_FINE    BETWEEN p_data_inizio AND p_data_fine ) )
            -- Il prodotto di vendita e' quello selezionato
            AND CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
            -- La misura del prodotto di vendita e' quella selezionata
            -- (caso verificato spesso nelle iniziative speciali)
            AND CD_PRODOTTO_ACQUISTATO.ID_MISURA_PRD_VE = p_id_misura_prd_ve
            --Il formato e' quello selezionato
            --(evita accavallamenti nel tabellare)
            AND CD_PRODOTTO_ACQUISTATO.ID_FORMATO = p_id_formato
            -- Il tipo cinema o e null (TAB) o e quello selezionato (ISP)
            AND ( CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA IS NULL 
                OR CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA = p_id_tipo_cinema )
            AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
            AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N';
    RETURN v_return_cursor;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_INTERV_MOD_TAR(' || p_data_inizio || ',' || p_data_fine || ','|| p_id_prodotto_vendita || ','|| p_id_misura_prd_ve || ','|| p_id_tipo_cinema || ','|| p_id_formato || '): Si e'' verificato un errore: '|| SQLERRM );
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_COMPATIBILITA_TARIFFA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Verifica che dato un listino, un prodotto vendita ed altri input
--              non ci siano limitazioni per la creazione/modifica della tariffa
-- INPUT:   p_id_prodotto_vendita       il prodotto vendita selezionato
--          p_id_listino                il listino scelto come riferimento
--          p_data_inizio, p_data_fine  gli estremi temporali della tariffa
--          p_id_misura_prd_vendita     misura del prodottto vendita 
--          p_id_tipo_tariffa           tipo tariffa
--          p_id_formato                formato acquistabile
--          p_id_tipo_cinema            tipo cinema
-- OUTPUT:
--      CONSENSI
--          v_return_value  7   --Prima tariffa per il listino in questione
--          v_return_value  6   --Intervalli NON sovrapposti
--          v_return_value  5   --Nuova misura temporale
--          v_return_value  4   --Formato acquistabile non ancora esistente (sia esso NULL o no)
--          v_return_value  3   --Primo tipo cinema di tipo NULL
--          v_return_value  2   --Nuovo tipo cinema
--          v_return_value  1   --Prima tariffa per il prodotto in questione  
--      RIFIUTI
--          v_return_value  0   --Valore di inizializzazione
--          v_return_value -1   --Date esterne al listino di riferimento
--          v_return_value -2   --Tipo cinema gia esistente
--          v_return_value -3   --Tipo cinema di tipo NULL gia esistente
--          v_return_value -4   --Formato acquistabile di tipo NULL gia esistente
--          v_return_value -5   --Tariffa FISSA su BASE per questo prodotto con misure temporali uguali
--          v_return_value -6   --Tariffa BASE su BASE per questo prodotto
--          v_return_value -7   --Tariffa BASE su FISSA per questo prodotto con misure temporali uguali
--          v_return_value -8   --Errore generico
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 3 Febbraio 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_COMPATIBILITA_TARIFFA(  p_id_prodotto_vendita   CD_TARIFFA.ID_PRODOTTO_VENDITA%TYPE,
                                    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
                                    p_id_tariffa            CD_TARIFFA.ID_TARIFFA%TYPE,
                                    p_data_inizio           CD_TARIFFA.DATA_INIZIO%TYPE,
                                    p_data_fine             CD_TARIFFA.DATA_FINE%TYPE,
                                    p_id_misura_prd_vendita CD_TARIFFA.ID_MISURA_PRD_VE%TYPE,
                                    p_id_tipo_tariffa       CD_TARIFFA.ID_TIPO_TARIFFA%TYPE,
                                    p_id_formato            CD_TARIFFA.ID_FORMATO%TYPE,
                                    p_id_tipo_cinema        CD_TARIFFA.ID_TIPO_CINEMA%TYPE)
                                   RETURN INTEGER
IS
    v_inizio_listino          DATE;
    v_fine_listino            DATE;
    v_temp                    INTEGER;
    v_esito_listino           VARCHAR2(2);
    v_esito_prod_ven          VARCHAR2(2);
    v_esito_date              VARCHAR2(2);
    v_esito_misura_prd_ve     VARCHAR2(2);
    v_esito_tipo_tariffa      VARCHAR2(2);
    v_esito_formato           VARCHAR2(2);
    v_esito_tipo_cinema       VARCHAR2(2); 
    v_esito_tipi_diversi      VARCHAR2(2);
    v_return_value            INTEGER;
    v_formato_nullo           INTEGER;  
    v_tipo_cinema_nullo       INTEGER;
BEGIN
    SELECT  CD_LISTINO.DATA_INIZIO, CD_LISTINO.DATA_FINE
    INTO    v_inizio_listino, v_fine_listino
    FROM    CD_LISTINO
    WHERE   CD_LISTINO.ID_LISTINO=p_id_listino;
    IF( ( v_inizio_listino > p_data_inizio ) OR ( v_fine_listino < p_data_fine ) )THEN
        v_return_value:=-1; --date inserite esterne al listino di riferimento
    ELSE
        v_return_value:=0; --tutto bene
        --E' la prima tariffa del LISTINO?
        SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
        INTO  v_esito_listino   
        FROM  CD_TARIFFA
        WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
        AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa ); 
        --NOTA--
        --Con questo controllo posso usare la funzione sia per l'inserimento che per la modifica
        IF(v_esito_listino='NO')THEN
            DBMS_OUTPUT.PUT_LINE('Esistono tariffe per questo listino, altre verifiche in corso...');
            --E' la prima tariffa per questo prodotto?
            SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
            INTO  v_esito_prod_ven   
            FROM  CD_TARIFFA
            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
            AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa );
            IF(v_esito_prod_ven='SI')THEN
                --La tariffa e' la prima per il listino
                v_return_value:=1;  --Prima tariffa per questo prodotto, si puo' inserire!
                DBMS_OUTPUT.PUT_LINE('Prima tariffa per questo prodotto, si puo'' inserire/modificare!');
            ELSE
                --La tariffa non e' la prima per il listino   
                DBMS_OUTPUT.PUT_LINE('Esistono tariffe per questo prodotto, altre verifiche in corso...');
                --La tariffa e' la prima in quelle date di riferimento?
                SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
                INTO  v_esito_date 
                FROM  CD_TARIFFA
                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7;
                IF(v_esito_date='NO')THEN
                    --Intervalli sovrapposti
                    DBMS_OUTPUT.PUT_LINE('Intervalli sovrapposti, altre verifiche in corso...');
                    --La misura temporale e diversa da quelle delle tariffe presenti?
                    SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
                    INTO  v_esito_misura_prd_ve  
                    FROM  CD_TARIFFA
                    WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                    AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                    AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                    AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita;
                    IF(v_esito_misura_prd_ve='NO')THEN
                        --Misure temporali uguali
                        DBMS_OUTPUT.PUT_LINE('Esiste gia'' la misura temporale inserita per questo prodotto, altre verifiche in corso...');
                        --La tariffa che sto esaminando e BASE? 
                        SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
                        INTO  v_esito_tipo_tariffa  
                        FROM  CD_TARIFFA
                        WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                        AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                        AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                        AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                        AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                        AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                        AND   p_id_tipo_tariffa = 2;    -- tariffa esaminata FISSA
                        IF(v_esito_tipo_tariffa='NO')THEN
                            --Tariffa FISSA--
                            DBMS_OUTPUT.PUT_LINE('Tipo tariffa FISSA, altre verifiche in corso...');
                            --In questo intervallo, sono l'unica tariffa FISSA? (I tipi tariffa sono diversi?)
                            SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
                            INTO  v_esito_tipi_diversi  
                            FROM  CD_TARIFFA
                            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                            AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                            AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                            AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND   p_id_tipo_tariffa = 2             -- tariffa esaminata FISSA                            
                            AND   CD_TARIFFA.ID_TIPO_TARIFFA = 2;   -- altre tariffe FISSA
                            IF(v_esito_tipi_diversi='NO')THEN
                                --Tariffa FISSA sovrapposta a tariffa FISSA
                                DBMS_OUTPUT.PUT_LINE('Tipo tariffa FISSA, sovrapposta ad altra tariffa FISSA, altre verifiche in corso...');
                                --Tra le tariffe sovrapposte, in quante il tipo formato e' null?
                                SELECT COUNT(*)
                                INTO  v_formato_nullo  
                                FROM  CD_TARIFFA
                                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                                AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                AND   p_id_tipo_tariffa = 2             -- tariffa esaminata FISSA                            
                                AND   CD_TARIFFA.ID_TIPO_TARIFFA = 2    -- altre tariffe FISSA
                                AND   CD_TARIFFA.ID_FORMATO IS NULL;
                                --Il tipo formato e' diverso da quello delle tariffe sovrapposte?
                                SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
                                INTO  v_esito_formato  
                                FROM  CD_TARIFFA
                                WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                                AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                                AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                AND   p_id_tipo_tariffa = 2             -- tariffa esaminata FISSA                            
                                AND   CD_TARIFFA.ID_TIPO_TARIFFA = 2    -- altre tariffe FISSA
                                AND   ( p_id_formato IS NULL OR CD_TARIFFA.ID_FORMATO = p_id_formato );
                                --NOTA--
                                --Nel caso in cui il tipo formato sia null e non sia il primo, v_esito_formato tornerebbe NO,
                                --mentre p_id_formato sarebbe null. Si va quindi nella clausola ELSE!
                                IF( (p_id_formato IS NOT NULL)) AND (v_esito_formato='NO') THEN
                                    --Tipo formato uguale a quelli sovrapposti e non null, verifico il tipo cinema
                                    DBMS_OUTPUT.PUT_LINE('Esiste gia'' il formato acquistabile inserito per questo prodotto, altre verifiche in corso...');
                                    --Tra le tariffe sovrapposte, in quante il tipo cinema e' null?
                                    SELECT COUNT(*)
                                    INTO  v_tipo_cinema_nullo
                                    FROM  CD_TARIFFA
                                    WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                    AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                    AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                                    AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                    AND   p_id_tipo_tariffa = 2             -- tariffa esaminata FISSA                            
                                    AND   CD_TARIFFA.ID_TIPO_TARIFFA = 2    -- altre tariffe FISSA
                                    AND   CD_TARIFFA.ID_TIPO_CINEMA IS NULL;
                                    --Il tipo cinema e' diverso da quello delle tariffe sovrapposte?                        
                                    SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
                                    INTO  v_esito_tipo_cinema
                                    FROM  CD_TARIFFA
                                    WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                                    AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                    AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                                    AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                                    AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                                    AND   p_id_tipo_tariffa = 2             -- tariffa esaminata FISSA                            
                                    AND   CD_TARIFFA.ID_TIPO_TARIFFA = 2    -- altre tariffe FISSA
                                    AND   ( p_id_tipo_cinema IS NULL OR CD_TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema );
                                    IF (p_id_tipo_cinema IS NOT NULL) THEN
                                        --p_id_tipo_cinema non null
                                        DBMS_OUTPUT.PUT_LINE('Il tipo cinema inserito e'' diverso da NULL, altre verifiche in corso...');
                                        IF (v_esito_tipo_cinema='SI') THEN
                                            --p_id_tipo_cinema non null e diverso da quello delle tariffe sovrapposte
                                            DBMS_OUTPUT.PUT_LINE('Nuovo tipo cinema per questo prodotto, si puo'' inserire/modificare! ');
                                            v_return_value:=2;  --Nuovo tipo cinema per questo prodotto, si puo' inserire/modificare!                                               
                                        ELSE
                                            --p_id_tipo_cinema non null e uguale a quello delle tariffe sovrapposte
                                            DBMS_OUTPUT.PUT_LINE('Esiste gia'' il tipo cinema inserito per questo prodotto, non si puo'' inserire/modificare! ');                                            
                                            v_return_value:=-2; --Esiste gia' il tipo cinema inserito per questo prodotto, non si puo' inserire/modificare!                                          
                                        END IF;
                                    ELSE
                                        --p_id_tipo_cinema null
                                        DBMS_OUTPUT.PUT_LINE('Il tipo cinema inserito e'' NULL, altre verifiche in corso...');
                                        IF (v_esito_tipo_cinema='SI') THEN
                                            --p_id_tipo_cinema null e diverso da quello delle tariffe sovrapposte
                                            DBMS_OUTPUT.PUT_LINE('Primo tipo cinema NULL per questo prodotto, si puo'' inserire/modificare! ');                                            
                                            v_return_value:=3;  --Primo tipo cinema NULL per questo prodotto, si puo' inserire/modificare!                                               
                                        ELSE
                                            --p_id_tipo_cinema null e uguale a quello delle tariffe sovrapposte
                                            DBMS_OUTPUT.PUT_LINE('Tipo cinema NULL per questo prodotto gia'' presente, non si puo'' inserire/modificare! ');
                                            v_return_value:=-3; --Tipo cinema NULL per questo prodotto gia' presente, non si puo' inserire/modificare!                                                                                        
                                        END IF;                                        
                                    END IF;                             
                                ELSE
                                    --p_id_formato e' null OPPURE il tipo formato e' diverso da quello di una delle 
                                    --tariffe sovrapposte.
                                    DBMS_OUTPUT.PUT_LINE('Il formato acquistabile inserito e'' null OPPURE diverso da quello delle tariffe sovrapposte, altre verifiche in corso...');
                                    IF(v_esito_formato='SI') THEN
                                        --p_id_formato diverso da quello delle tariffe sovrapposte
                                        DBMS_OUTPUT.PUT_LINE('Nuovo formato acquistabile per tariffa FISSA, si puo'' inserire/modificare! ');                                    
                                        v_return_value:=4; --Formato acquistabile non esistente per questa tariffa FISSA, si puo' inserire/modificare!
                                    ELSE
                                        DBMS_OUTPUT.PUT_LINE('Formato acquistabile NULL per tariffa FISSA gia'' esistente, non si puo'' inserire/modificare!');
                                        --p_id_formato uguale a quello delle tariffe sovrapposte
                                        --NOTA--
                                        --Sono qui solo se questa e' una nuova occorrenza di tipo_tariffa = NULL
                                        v_return_value:=-4; --Formato acquistabile NULL gia' esistente per questa tariffa FISSA, non si puo' inserire/modificare!
                                    END IF;                                    
                                END IF;                                
                            ELSE
                                --Tariffa FISSA sovrapposta a tariffa BASE
                                DBMS_OUTPUT.PUT_LINE('Tipo tariffa FISSA sovrapposta ad altra tariffa BASE');
                                --Le misure temporali sono sicuramente uguali
                                DBMS_OUTPUT.PUT_LINE('Misure temporali uguali, non si puo'' inserire/modificare!');
                                v_return_value:=-5; --Tariffa FISSA su BASE per questo prodotto con misure temporali uguali, non si puo' inserire/modificare!  
                            END IF;                  
                        ELSE
                            --Tariffa BASE--
                            DBMS_OUTPUT.PUT_LINE('Tipo tariffa BASE, altre verifiche in corso...');
                            --In questo intervallo, sono l'unica tariffa BASE? (I tipi tariffa sono diversi?)
                            SELECT DECODE(COUNT(*), 0 , 'SI', 'NO' )
                            INTO  v_esito_tipi_diversi  
                            FROM  CD_TARIFFA
                            WHERE CD_TARIFFA.ID_LISTINO = p_id_listino
                            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND   ( p_id_tariffa IS NULL OR CD_TARIFFA.ID_TARIFFA <> p_id_tariffa )
                            AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>1
                            AND   PA_CD_TARIFFA.FU_VERIFICA_DATE(p_data_inizio, p_data_fine, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE)<>7
                            AND   CD_TARIFFA.ID_MISURA_PRD_VE = p_id_misura_prd_vendita
                            AND   p_id_tipo_tariffa = 1             -- tariffa esaminata BASE                            
                            AND   CD_TARIFFA.ID_TIPO_TARIFFA = 1;   -- altre tariffe BASE
                            IF(v_esito_tipi_diversi='NO')THEN
                                --Tariffa BASE sovrapposta a tariffa BASE
                                DBMS_OUTPUT.PUT_LINE('Tipo tariffa BASE sovrapposta ad altra tariffa BASE, non si puo'' inserire/modificare!');
                                v_return_value:=-6; --Tariffa BASE su BASE per questo prodotto, non si puo' inserire/modificare!
                            ELSE
                                --Tariffa BASE sovrapposta a tariffa FISSA
                                DBMS_OUTPUT.PUT_LINE('Tipo tariffa BASE sovrapposta ad altra tariffa FISSA');
                                --Le misure temporali sono sicuramente uguali
                                DBMS_OUTPUT.PUT_LINE('Misure temporali uguali, non si puo'' inserire/modificare!');
                                v_return_value:=-7; --Tariffa BASE su FISSA per questo prodotto con misure temporali uguali, non si puo' inserire/modificare!                                                                                 
                            END IF;
                        END IF;
                    ELSE
                        --Misure temporali diverse
                        DBMS_OUTPUT.PUT_LINE('Nuova misura temporale per questo prodotto, si puo'' inserire/modificare!');
                        v_return_value:=5;  --Nuova misura temporale per questo prodotto, si puo' inserire/modificare!
                    END IF;
                ELSE
                   --Intervalli NON sovrapposti
                    DBMS_OUTPUT.PUT_LINE('Intervalli NON sovrapposti, si puo'' inserire/modificare!');                   
                    v_return_value:=6; --Intervalli NON sovrapposti, si puo' inserire/modificare!
                END IF;
            END IF;    
        ELSE
            --Prima tariffa del listino
            DBMS_OUTPUT.PUT_LINE('Prima tariffa per il listino in questione, si puo'' inserire/modificare! '||v_return_value);            
            v_return_value:=7; --Prima tariffa, si puo' inserire/modificare!
        END IF;    
    END IF;
    DBMS_OUTPUT.PUT_LINE('RETURN VALUE: '||v_return_value);
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        v_return_value:=-8;
        RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_COMPATIBILITA_TARIFFA: SI E'' VERIFICATO UN ERRORE '||SQLERRM);
        RETURN v_return_value;
END;

function fu_get_importo(p_id_tariffa cd_tariffa.id_tariffa%type) return cd_tariffa.importo%type is
v_importo cd_tariffa.importo%type;
begin
select importo
into  v_importo
from   cd_tariffa
where  id_tariffa = p_id_tariffa;
return v_importo;
end fu_get_importo;
/*

Metodo che Permette di ottenere l'elenco delle tariffe presenti per il listino indicato come parametro
e valide alla data di riferimento impostata
Funzione utilizzata per la sezione Copia Tariffe

Data Creazione 31/10/2011 Antonio Colucci, Teoresi srl

*/
function fu_tariffa_to_export(p_id_listino cd_tariffa.id_listino%type,p_data_riferimento date) return c_tariffa_exp
is
v_return_cursor     C_TARIFFA_EXP;
BEGIN
    OPEN v_return_cursor
        FOR
            select distinct 
                   id_tariffa,
                   importo,
                   cd_tariffa.data_inizio,
                   cd_tariffa.data_fine,
                   flg_stagionale,
                   cd_tariffa.id_misura_prd_ve,
                   cd_tariffa.id_formato,
                   cd_tariffa.id_prodotto_vendita,
                   id_tipo_tariffa,
                   cd_tariffa.id_tipo_cinema,
                   id_listino,
                   nome_circuito,
                   desc_mod_vendita,
                   desc_prodotto,
                   desc_tipo_break,
                   durata,
                   desc_unita
             from cd_tariffa,
                  cd_prodotto_vendita,
                  cd_circuito,
                  cd_modalita_vendita,
                  cd_prodotto_pubb,
                  cd_tipo_break,
                  cd_misura_prd_vendita,
                  cd_unita_misura_temp,
                  cd_tipo_cinema,
                  cd_formato_acquistabile,
                  cd_coeff_cinema
            where id_listino = p_id_listino
            and p_data_riferimento between cd_tariffa.data_inizio and cd_tariffa.data_fine
            and cd_tariffa.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita
            and cd_prodotto_vendita.id_circuito = cd_circuito.id_circuito
            and cd_prodotto_vendita.id_tipo_break = cd_tipo_break.id_tipo_break(+)
            and cd_prodotto_vendita.id_prodotto_pubb = cd_prodotto_pubb.id_prodotto_pubb
            and cd_tariffa.id_misura_prd_ve = cd_misura_prd_vendita.id_misura_prd_ve
            and cd_misura_prd_vendita.id_unita = cd_unita_misura_temp.id_unita
            and cd_tariffa.id_tipo_cinema = cd_tipo_cinema.id_tipo_cinema(+)
            and cd_prodotto_vendita.id_mod_vendita = cd_modalita_vendita.id_mod_vendita
            and cd_tariffa.id_formato = cd_formato_acquistabile.id_formato
            and cd_formato_acquistabile.id_coeff = cd_coeff_cinema.id_coeff(+);
    RETURN v_return_cursor;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'Errore in funzione tariffa_to_export:' || SQLERRM );
end fu_tariffa_to_export;
END PA_CD_TARIFFA; 
/

