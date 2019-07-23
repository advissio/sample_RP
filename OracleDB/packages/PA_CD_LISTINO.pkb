CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_LISTINO IS
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_LISTINO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo listino nel sistema
--
-- OPERAZIONI:
--   1) Memorizza il listino (CD_LISTINO)
--
-- INPUT:
--      p_desc_listino  descrizione del listino
--      p_data_inizio   data di inizio
--      p_data_fine     data di fine
--
-- OUTPUT: esito:
--    n  ID del listino appena inserito
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Settembre 2009
--              Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011    
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_LISTINO(p_desc_listino               CD_LISTINO.DESC_LISTINO%TYPE,
                               p_data_inizio                CD_LISTINO.DATA_INIZIO%TYPE,
                               p_data_fine                  CD_LISTINO.DATA_FINE%TYPE,
                               p_cod_categoria_prodotto     CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,                               
                               p_esito                      OUT CD_LISTINO.ID_LISTINO%TYPE)
IS
BEGIN -- PR_INSERISCI_LISTINO
    p_esito     := -11;
    SAVEPOINT SP_PR_INSERISCI_LISTINO;
    INSERT INTO CD_LISTINO(
        DESC_LISTINO,
        DATA_INIZIO,
        DATA_FINE,
        COD_CATEGORIA_PRODOTTO)
    VALUES(
        p_desc_listino,
        p_data_inizio,
        p_data_fine,
        p_cod_categoria_prodotto);
    SELECT CD_LISTINO_SEQ.CURRVAL
    INTO   p_esito
    FROM   DUAL;
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20006, 'PROCEDURA PR_INSERISCI_LISTINO: Insert non eseguita, verificare la coerenza dei parametri '
                                    ||FU_STAMPA_LISTINO(p_desc_listino, p_data_inizio, p_data_fine));
        ROLLBACK TO SP_PR_INSERISCI_LISTINO;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_LISTINO
--
-- DESCRIZIONE:  Esegue l'aggiornamento di un nuovo listino nel sistema
--
-- OPERAZIONI:
--   1) Modifica il listino (CD_LISTINO)
--
-- INPUT:
--      p_id_listino    id del listino
--      p_desc_listino  descrizione del listino
--      p_data_inizio   data di inizio
--      p_data_fine     data di fine
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -11 Inserimento non eseguito: i parametri per la Update non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011    
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_LISTINO(p_id_listino              CD_LISTINO.ID_LISTINO%TYPE,
                              p_desc_listino            CD_LISTINO.DESC_LISTINO%TYPE,
                              p_data_inizio             CD_LISTINO.DATA_INIZIO%TYPE,
                              p_data_fine               CD_LISTINO.DATA_FINE%TYPE,
                              p_cod_categoria_prodotto  CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,
                              p_esito                   OUT NUMBER)
IS
BEGIN -- PR_MODIFICA_LISTINO
    p_esito := 1;
    SAVEPOINT SP_PR_MODIFICA_LISTINO;
    UPDATE CD_LISTINO
        SET
            DESC_LISTINO            = (nvl(p_desc_listino, DESC_LISTINO)),
            DATA_INIZIO             = (nvl(p_data_inizio, DATA_INIZIO)),
            DATA_FINE               = (nvl(p_data_fine, DATA_FINE)),
            COD_CATEGORIA_PRODOTTO  = (nvl(p_cod_categoria_prodotto, COD_CATEGORIA_PRODOTTO))
        WHERE ID_LISTINO = p_id_listino;
    p_esito := SQL%ROWCOUNT;
EXCEPTION
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20006, 'PROCEDURA PR_MODIFICA_LISTINO: Update non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_LISTINO(p_desc_listino,
                                                                                                                                                        p_data_inizio,
                                                                                                                                                        p_data_fine));
        ROLLBACK TO SP_PR_MODIFICA_LISTINO;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_LISTINO
--
-- DESCRIZIONE:  Esegue l'eliminazione di un listino dal sistema
--
-- OPERAZIONI:
--   1) Controlla l'esistenza di prodotti acquistati per il listino in oggetto
--   2) Se non vi sono prodotti acquistati associati, elimina gli ambiti di vendita
--   3) Elimina le tariffe associate al listino
--   4) Elimina gli sconti stagionali associati
--   5) Svuota il listino
--   6) Elimina il listino
--
-- INPUT:
--      p_id_listino    id del listino
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1 Impossibile cancellare il listino poiche vi sono prodotti acquistati
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, Ottobre 2010
--                  aggiunta condizione piu stringente per il controllo di eliminabilita di un listino
--                  non era sufficiente controllare l'esistenza di un prodotto di acquistato, e necessario 
--                  che il prodotto in questione sia anche acquistato nel periodo di validita della tariffa 
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_LISTINO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE,
                             p_esito        OUT NUMBER)
IS

   prod_acq  NUMBER;

BEGIN -- PR_ELIMINA_LISTINO
    --
    p_esito     := 1;
    --
    SELECT COUNT(*) INTO prod_acq
    FROM  CD_PRODOTTO_ACQUISTATO, CD_PRODOTTO_VENDITA,
          CD_TARIFFA, CD_LISTINO
    WHERE CD_LISTINO.ID_LISTINO  =   CD_TARIFFA.ID_LISTINO
    AND   CD_TARIFFA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
    AND   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
    AND   CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE
    AND   CD_PRODOTTO_ACQUISTATO.DATA_FINE BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE
    AND   CD_LISTINO.ID_LISTINO = p_id_listino;

    SAVEPOINT SP_PR_ELIMINA_LISTINO;

    IF (prod_acq>0) THEN
        p_esito:=-1;
    ELSE
        -- elimina gli ambiti di vendita associati al listino

        DELETE FROM CD_CINEMA_VENDITA WHERE CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA IN
            (SELECT CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
             FROM CD_CIRCUITO_CINEMA
             WHERE CD_CIRCUITO_CINEMA.ID_LISTINO = p_id_listino);

        DELETE FROM CD_ATRIO_VENDITA WHERE CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO IN
            (SELECT CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
             FROM CD_CIRCUITO_ATRIO
             WHERE CD_CIRCUITO_ATRIO.ID_LISTINO = p_id_listino);

        DELETE FROM CD_SALA_VENDITA WHERE CD_SALA_VENDITA.ID_CIRCUITO_SALA IN
            (SELECT CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
             FROM CD_CIRCUITO_SALA
             WHERE CD_CIRCUITO_SALA.ID_LISTINO = p_id_listino);

        DELETE FROM CD_BREAK_VENDITA WHERE CD_BREAK_VENDITA.ID_CIRCUITO_BREAK IN
            (SELECT CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
             FROM CD_CIRCUITO_BREAK
             WHERE CD_CIRCUITO_BREAK.ID_LISTINO = p_id_listino);

        -- elimina le tariffe associate al listino

        DELETE FROM CD_TARIFFA WHERE CD_TARIFFA.ID_LISTINO = p_id_listino;

        -- elimina gli sconti stagionali associati al listino

        DELETE FROM CD_SCONTO_STAGIONALE WHERE CD_SCONTO_STAGIONALE.ID_LISTINO = p_id_listino;

        -- svuota il listino

        PR_SVUOTA_LISTINO(p_id_listino,p_esito);

        -- effettua l'ELIMINAZIONE del listino

        DELETE FROM CD_LISTINO
        WHERE ID_LISTINO = p_id_listino;

        p_esito := SQL%ROWCOUNT;

    END IF;

    --

    EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_ELIMINA_LISTINO: Delete non eseguita, verificare la coerenza dei parametri '||SQLERRM);
        ROLLBACK TO SP_PR_ELIMINA_LISTINO;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_CLONA_LISTINO
--
-- DESCRIZIONE:  Clonazione di tutti i circuiti legati al listino
--               di origine verso il listino di destinazione
--
-- OPERAZIONI:
--   1) Seleziona e inserisce i circuiti collegati al listino di origine
--      associandoli al listino di destinazione
--
-- INPUT:
--      p_id_listino_orig    id del listino di origine
--      p_id_listino_dest    id del listino di destinazione
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella clonazione del listino
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Settembre 2009, Marzo 2010
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CLONA_LISTINO  (   p_id_listino_orig       IN CD_LISTINO.ID_LISTINO%TYPE,
                                p_id_listino_dest       IN CD_LISTINO.ID_LISTINO%TYPE,
                                p_esito                 OUT NUMBER)
IS
   v_esito_sc_stag NUMBER;
   v_id_listino    CD_LISTINO.ID_LISTINO%TYPE;
   v_esito_comp_sc NUMBER;
--   v_list_schermi  ID_SCHERMI_TYPE:=ID_SCHERMI_TYPE();
   i               NUMBER;
/*CURSOR c_id_circuito_schermo IS
    SELECT DISTINCT(ID_CIRCUITO)
    FROM   CD_CIRCUITO_SCHERMO
    WHERE  ID_LISTINO = p_id_listino_orig
	AND    FLG_ANNULLATO = 'N';*/
/*CURSOR c_id_schermo IS
    SELECT ID_SCHERMO, ID_CIRCUITO
    FROM   CD_CIRCUITO_SCHERMO
    WHERE  ID_LISTINO = p_id_listino_orig
	AND    FLG_ANNULLATO = 'N';*/
BEGIN
    p_esito := 1;
    v_esito_sc_stag := 1;
    SAVEPOINT SP_PR_CLONA_LISTINO;
    -- clonazione dei circuiti di atrio
    INSERT INTO CD_CIRCUITO_ATRIO(
        ID_ATRIO,
        ID_CIRCUITO,
        ID_LISTINO,
		FLG_ANNULLATO)
    SELECT
        ID_ATRIO,
        ID_CIRCUITO,
        p_id_listino_dest AS ID_LISTINO,
		FLG_ANNULLATO
    FROM  CD_CIRCUITO_ATRIO
    WHERE ID_LISTINO = p_id_listino_orig
	AND   FLG_ANNULLATO = 'N';
    -- clonazione dei circuiti di cinema
    INSERT INTO CD_CIRCUITO_CINEMA(
        ID_CINEMA,
        ID_CIRCUITO,
        ID_LISTINO,
		FLG_ANNULLATO)
    SELECT
        ID_CINEMA,
        ID_CIRCUITO,
        p_id_listino_dest AS ID_LISTINO,
		FLG_ANNULLATO
    FROM  CD_CIRCUITO_CINEMA
    WHERE ID_LISTINO = p_id_listino_orig
	AND   FLG_ANNULLATO = 'N';
    -- clonazione dei circuiti di sala
    INSERT INTO CD_CIRCUITO_SALA(
        ID_SALA,
        ID_CIRCUITO,
        ID_LISTINO,
		FLG_ANNULLATO)
    SELECT
        ID_SALA,
        ID_CIRCUITO,
        p_id_listino_dest AS ID_LISTINO,
		FLG_ANNULLATO
    FROM  CD_CIRCUITO_SALA
    WHERE ID_LISTINO = p_id_listino_orig
	AND   FLG_ANNULLATO = 'N';
    -- clonazione dei circuiti di schermo e, quindi, di break
    for circuito_schermo in
    (
        SELECT DISTINCT(ID_CIRCUITO)
        FROM   CD_CIRCUITO_SCHERMO
        WHERE  ID_LISTINO = p_id_listino_orig
    	AND    FLG_ANNULLATO = 'N'
    )loop
    PR_LISTINO_SCHERMO_CLONA(p_id_listino_dest,p_id_listino_orig,circuito_schermo.id_circuito,v_esito_comp_sc);
    commit;
    END LOOP;
    /*
    FOR circuito_schermo IN c_id_circuito_schermo LOOP
        i:=1;
        v_list_schermi.delete;
        FOR id_schermo IN c_id_schermo LOOP
            IF(id_schermo.id_circuito=circuito_schermo.id_circuito) THEN
                v_list_schermi.extend;
                v_list_schermi(i) := id_schermo.id_schermo;
                i:=i+1;
            END IF;
        END LOOP;
        PR_COMPONI_LISTINO_SCHERMO(p_id_listino_dest,circuito_schermo.id_circuito,v_list_schermi,v_esito_comp_sc);
        commit;
    END LOOP;
    */
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_CLONA_LISTINO: Clonazione non eseguita, si e'' verificato un errore '||SQLERRM);
        ROLLBACK TO SP_PR_CLONA_LISTINO;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CREA_E_CLONA_LISTINO
--
-- DESCRIZIONE:  Crea un nuovo listino e ne effettua contestualmente la clonazione da quello passato
--
-- OPERAZIONI:
--   1) Cea un nuovo listino e provvede alla clonazione con l'ausilio delle procedure gia' esistenti
--
-- INPUT:
--      p_id_listino_orig    id del listino di origine
--      p_desc_listino       descrizione del listino
--      p_data_inizio        data di inizio
--      p_data_fine          data di fine
--      p_id_listino_dest    id del listino di destinazione
--
-- OUTPUT: esito:
--             1  Operazione andata a buon fine
--            -1  Operazione non eseguita: si e verificato un errore
--        p_id_listino_dest:
--             n  l'id del nuovo listino
--            -1  Operazione non eseguita: si e verificato un errore
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Settembre 2009
--
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011    
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_E_CLONA_LISTINO (p_id_listino_orig    IN  CD_LISTINO.ID_LISTINO%TYPE,
                                   p_desc_listino       IN  CD_LISTINO.DESC_LISTINO%TYPE,
                                   p_data_inizio        IN  CD_LISTINO.DATA_INIZIO%TYPE,
                                   p_data_fine          IN  CD_LISTINO.DATA_FINE%TYPE,
                                   p_cod_categoria_prodotto CD_LISTINO.COD_CATEGORIA_PRODOTTO%TYPE,
                                   p_id_listino_dest    OUT CD_LISTINO.ID_LISTINO%TYPE,
                                   p_esito              OUT NUMBER)
IS
BEGIN
    SAVEPOINT SP_PR_CREA_E_CLONA_LISTINO;
    PR_INSERISCI_LISTINO(p_desc_listino, p_data_inizio, p_data_fine, p_cod_categoria_prodotto, p_id_listino_dest);
    IF(p_id_listino_dest<>-11)THEN
        PR_CLONA_LISTINO(p_id_listino_orig, p_id_listino_dest , p_esito);
        IF(p_esito<>1)THEN
            p_id_listino_dest:=-1;
            p_esito:=-1;
            ROLLBACK TO SP_PR_CREA_E_CLONA_LISTINO;
        END IF;
    ELSE
        p_id_listino_dest:=-1;
        p_esito:=-1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        p_id_listino_dest:=-1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_CREA_E_CLONA_LISTINO: Creazione/Clonazione non eseguita, si e'' verificato un errore '||SQLERRM);
        ROLLBACK TO SP_PR_CREA_E_CLONA_LISTINO;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_COMPONI_LISTINO_ATRIO
--
-- DESCRIZIONE:  Composizione dei circuiti di atrio associati al
--               listino di riferimento
--               Se gia' esiste, allora lo recupera
--
-- OPERAZIONI:
--   1) Scorre l'insieme degli atrii da associare al listino
--
-- INPUT:
--      p_id_listino        id del listino
--      p_id_circuito       id del circuito
--      p_list_id_atrii     lista degli id degli atrii
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella composizione del listino
--   >10 indica che il circuito e' stao recuperato, ed il valore (diminuito di 10) restituisce il numero
--               di elementi recuperati
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_ATRIO  (    p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito              IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_atrii         IN id_atrii_type,
                                        p_esito                 OUT NUMBER)
IS
    v_esiste_gia            INTEGER:=0;
    v_id_circ_listino       INTEGER:=-1;
    v_id_circuito_atrio     INTEGER;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_COMPONI_LISTINO_ATRIO;
     FOR i IN 1..p_list_id_atrii.COUNT LOOP  -- cicla sull'insieme degli atrii da comporre
     SELECT COUNT(*)
        INTO  v_esiste_gia
        FROM  CD_CIRCUITO_ATRIO
        WHERE CD_CIRCUITO_ATRIO.ID_ATRIO    = p_list_id_atrii(i)
        AND   CD_CIRCUITO_ATRIO.ID_CIRCUITO = p_id_circuito
        AND   CD_CIRCUITO_ATRIO.ID_LISTINO  = p_id_listino;
        IF(v_esiste_gia = 0) THEN
            --DBMS_OUTPUT.PUT_LINE('ID_ATRIO:'|| p_list_id_atrii(i)||'   ID_CIRCUITO:'|| p_id_circuito ||'   ID_LISTINO'||p_id_listino ||' ---> Inserito');
            INSERT INTO CD_CIRCUITO_ATRIO          -- effettua l'inserimento
            (ID_ATRIO,
             ID_CIRCUITO,
             ID_LISTINO
            )
            VALUES
            (p_list_id_atrii(i),
             p_id_circuito,
             p_id_listino
            );
            SELECT CD_CIRCUITO_ATRIO_SEQ.CURRVAL
            INTO   v_id_circuito_atrio
            FROM   DUAL;
            PA_CD_TARIFFA.PR_REFRESH_TARIFFE_ATR(p_id_listino,p_id_circuito,v_id_circuito_atrio);
        ELSE
           -- DBMS_OUTPUT.PUT_LINE('ID_SCHERMO:'|| p_list_id_schermi(i)||'   ID_CIRCUITO:'|| p_id_circuito ||'   ID_LISTINO'||p_id_listino ||' ---> NON Inserito');
            SELECT CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
            INTO v_id_circ_listino
            FROM CD_CIRCUITO_ATRIO
            WHERE CD_CIRCUITO_ATRIO.ID_ATRIO = p_list_id_atrii(i)
            AND CD_CIRCUITO_ATRIO.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_ATRIO.ID_LISTINO = p_id_listino;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_ATRIO(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;
            END IF;
        END IF;
    END LOOP;
    EXCEPTION
          WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_LISTINO_ATRIO: Errore durante la composizione, verificare la coerenza dei parametri  '
        || SQLERRM);
        ROLLBACK TO SP_PR_COMPONI_LISTINO_ATRIO;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_COMPONI_LISTINO_SALA
--
-- DESCRIZIONE:  Composizione dei circuiti di sala associati al
--               listino di riferimento
--
-- OPERAZIONI:
--   1) Scorre l'insieme delle sale da associare al listino
--
-- INPUT:
--      p_id_listino        id del listino
--      p_id_circuito       id del circuito
--      p_list_id_sale      lista degli id delle sale
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella composizione del listino
--   >10 indica che il circuito e' stao recuperato, ed il valore (diminuito di 10) restituisce il numero
--               di elementi recuperati
--
-- REALIZZATORE: 
--              Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: 
--              Francesco Abbundo, Teoresi srl, Luglio 2009
-------------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_SALA  (    p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito              IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_sale          IN id_sale_type,
                                        p_esito                 OUT NUMBER)
IS
    v_esiste_gia          INTEGER:=0;
    v_id_circ_listino     INTEGER:=-1;
    v_id_circuito_sala    INTEGER;
BEGIN
 p_esito:=1;
    SAVEPOINT SP_PR_COMPONI_LISTINO_SALA;
     FOR i IN 1..p_list_id_sale.COUNT LOOP    -- cicla sull'insieme delle sale da comporre
        SELECT COUNT(*)
        INTO v_esiste_gia
        FROM CD_CIRCUITO_SALA
        WHERE CD_CIRCUITO_SALA.ID_SALA = p_list_id_sale(i)
            AND CD_CIRCUITO_SALA.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_SALA.ID_LISTINO = p_id_listino;
        IF(v_esiste_gia = 0) THEN
           -- DBMS_OUTPUT.PUT_LINE('ID_SALA:'|| p_list_id_sale(i)||'   ID_CIRCUITO:'|| p_id_circuito ||'   ID_LISTINO'||p_id_listino ||' ---> Inserito');
            INSERT INTO CD_CIRCUITO_SALA          -- effettua l'inserimento
            (ID_SALA,
             ID_CIRCUITO,
             ID_LISTINO
            )
            VALUES
            (p_list_id_sale(i),
             p_id_circuito,
             p_id_listino
            );
            SELECT CD_CIRCUITO_SALA_SEQ.CURRVAL
            INTO   v_id_circuito_sala
            FROM   DUAL;
            PA_CD_TARIFFA.PR_REFRESH_TARIFFE_SAL(p_id_listino,p_id_circuito,v_id_circuito_sala);
        ELSE
           -- DBMS_OUTPUT.PUT_LINE('ID_SCHERMO:'|| p_list_id_schermi(i)||'   ID_CIRCUITO:'|| p_id_circuito ||'   ID_LISTINO'||p_id_listino ||' ---> NON Inserito');
            SELECT CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
            INTO v_id_circ_listino
            FROM CD_CIRCUITO_SALA
            WHERE CD_CIRCUITO_SALA.ID_SALA = p_list_id_sale(i)
            AND CD_CIRCUITO_SALA.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_SALA.ID_LISTINO = p_id_listino;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_SALA(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;  
            END IF;            
        END IF;
    END LOOP;
    EXCEPTION
          WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_LISTINO_SALA: Errore durante la composizione, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_COMPONI_LISTINO_SALA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_COMPONI_LISTINO_CINEMA
--
-- DESCRIZIONE:  Composizione dei circuiti di cinema associati al
--               listino di riferimento
--
-- OPERAZIONI:
--   1) Scorre l'insieme dei cinema da associare al listino
--
-- INPUT:
--      p_id_listino        id del listino
--      p_id_circuito       id del circuito
--      p_list_id_cinema    lista degli id dei cinema
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella composizione del listino
--   >10 indica che il circuito e' stao recuperato, ed il valore (diminuito di 10) restituisce il numero
--               di elementi recuperati
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_CINEMA  (  p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito           IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_cinema        IN id_cinema_type,
                                        p_esito                 OUT NUMBER)
IS
    v_esiste_gia            INTEGER:=0;
    v_id_circ_listino       INTEGER:=-1;
    v_id_circuito_cinema    INTEGER;
BEGIN
   p_esito:=1;
    SAVEPOINT SP_PR_COMPONI_LISTINO_CINEMA;
     FOR i IN 1..p_list_id_cinema.COUNT LOOP    -- cicla sull'insieme dei cinema da comporre
        SELECT COUNT(*)
        INTO v_esiste_gia
        FROM CD_CIRCUITO_CINEMA
        WHERE CD_CIRCUITO_CINEMA.ID_CINEMA = p_list_id_cinema(i)
            AND CD_CIRCUITO_CINEMA.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_CINEMA.ID_LISTINO = p_id_listino;
        IF(v_esiste_gia = 0) THEN
        --    DBMS_OUTPUT.PUT_LINE('ID_CINEMA:'|| p_list_id_cinema(i)||'   ID_CIRCUITO:'|| p_id_circuito ||'   ID_LISTINO'||p_id_listino ||' ---> Inserito');
            INSERT INTO CD_CIRCUITO_CINEMA          -- effettua l'inserimento
            (ID_CINEMA,
             ID_CIRCUITO,
             ID_LISTINO
            )
            VALUES
            (p_list_id_cinema(i),
             p_id_circuito,
             p_id_listino
            );
            SELECT CD_CIRCUITO_CINEMA_SEQ.CURRVAL
            INTO   v_id_circuito_cinema
            FROM   DUAL;
            PA_CD_TARIFFA.PR_REFRESH_TARIFFE_CIN(p_id_listino,p_id_circuito,v_id_circuito_cinema);
        ELSE
           -- DBMS_OUTPUT.PUT_LINE('ID_SCHERMO:'|| p_list_id_schermi(i)||'   ID_CIRCUITO:'|| p_id_circuito ||'   ID_LISTINO'||p_id_listino ||' ---> NON Inserito');
            SELECT CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
            INTO v_id_circ_listino
            FROM CD_CIRCUITO_CINEMA
            WHERE CD_CIRCUITO_CINEMA.ID_CINEMA = p_list_id_cinema(i)
            AND CD_CIRCUITO_CINEMA.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_CINEMA.ID_LISTINO = p_id_listino;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_CINEMA(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;
            END IF;
        END IF;
    END LOOP;
    EXCEPTION
          WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_LISTINO_CINEMA: Errore durante la composizione, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_COMPONI_LISTINO_CINEMA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_COMPONI_LISTINO_ARENA
--
-- DESCRIZIONE:  Composizione dei circuiti di schermo (di ARENE) associati al
--               listino di riferimento oppure lo recupera se esiste gia'
--
-- OPERAZIONI:
--   1) Scorre l'insieme degli schermi (recuperati dalle arene) da associare al listino
--   2) Associa gli schermi al listino tramite il circuito
--   3) Cicla su tutti i giorni delle date del listino
--   5) Cicla sulle proiezioni esistenti
--   6) Cicla sui break esistenti
--   7) Associa i break al listino tramite il circuito
--   nel caso in cui il listino schermo era preesistente, viene semplicemente recuperato
--
-- INPUT:
--      p_id_listino        id del listino
--      p_id_circuito       id del circuito
--      p_list_id_arene     lista degli id delle arene dalle quali recuperare gli schermi
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella composizione del listino
--   >10 indica che il circuito e' stato recuperato, ed il valore (diminuito di 10) restituisce il numero
--               di elementi recuperati
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Maggio 2010
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_ARENA  ( p_id_listino          IN CD_LISTINO.ID_LISTINO%TYPE,
                                      p_id_circuito         IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                      p_list_id_arene       IN id_list_type,
                                      p_esito               OUT NUMBER)
IS
    v_num_proiezioni     CD_SALA.NUMERO_PROIEZIONI%TYPE;
    v_num_giorni         NUMBER;
    v_date_start         CD_LISTINO.DATA_INIZIO%TYPE;
    v_date_end           CD_LISTINO.DATA_FINE%TYPE;
    v_id_fascia          CD_FASCIA.ID_FASCIA%TYPE;
    v_data_proiezione    CD_PROIEZIONE.DATA_PROIEZIONE%TYPE;
    v_id_proiezione      CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
    v_id_break           CD_BREAK.ID_BREAK%TYPE;
    v_esito_ins_break    NUMBER;
    v_esito_comp_break   NUMBER;
    v_list_break         id_break_type;
    v_break_count        NUMBER;
    v_esiste_gia         INTEGER:=0;
    v_id_circ_listino    INTEGER:=-1;
    v_id_schermo         NUMBER;
    CURSOR c_tipo_break IS
        SELECT ID_TIPO_BREAK
        FROM   CD_CIRCUITO_TIPO_BREAK
	    WHERE  FLG_ANNULLATO = 'N'
        and    id_circuito = p_id_circuito;
BEGIN
    p_esito := 1;
    v_break_count := 1;
    SAVEPOINT SP_PR_COMPONI_LISTINO_ARENA;
    SELECT DATA_INIZIO, DATA_FINE
    INTO   v_date_start, v_date_end
    FROM   CD_LISTINO
    WHERE  ID_LISTINO = p_id_listino;
    v_num_giorni := v_date_end - v_date_start;
    FOR i IN 1..p_list_id_arene.COUNT LOOP    -- cicla sull'insieme degli schermi da comporre
        select id_schermo into v_id_schermo from cd_schermo where id_sala = p_list_id_arene(i);
        SELECT COUNT(*)
        INTO  v_esiste_gia
        FROM  CD_CIRCUITO_SCHERMO
        WHERE CD_CIRCUITO_SCHERMO.ID_SCHERMO = v_id_schermo
        AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
        AND   CD_CIRCUITO_SCHERMO.ID_LISTINO = p_id_listino;
        IF(v_esiste_gia = 0)THEN
            INSERT INTO CD_CIRCUITO_SCHERMO          -- associa gli schermi al listino tramite il circuito
               (ID_SCHERMO, ID_CIRCUITO, ID_LISTINO)
            VALUES
               (v_id_schermo, p_id_circuito, p_id_listino);
            FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni delle date del listino
                FOR id_fascia IN (SELECT ID_FASCIA FROM CD_FASCIA WHERE ID_TIPO_FASCIA IN(
                                        SELECT ID_TIPO_FASCIA FROM CD_TIPO_FASCIA WHERE DESC_TIPO = 'Fascia Proiezioni')) LOOP
                    v_data_proiezione    :=   v_date_start + k ;
                    v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(v_id_schermo,v_data_proiezione,id_fascia.id_fascia);
                    IF(v_id_proiezione != 0)THEN
                        FOR IDP IN(SELECT  ID_PROIEZIONE
                                   FROM    CD_PROIEZIONE
                                   WHERE   CD_PROIEZIONE.ID_SCHERMO      = v_id_schermo
                                   AND     CD_PROIEZIONE.DATA_PROIEZIONE = v_data_proiezione) LOOP
                            v_id_proiezione:=IDP.ID_PROIEZIONE;
                            FOR tipo_break in c_tipo_break LOOP
                                v_id_break := PA_CD_BREAK.FU_ESISTE_BREAK(v_id_proiezione, tipo_break.id_tipo_break);
                                IF(v_id_break > 0) THEN -- esiste
                                    v_list_break(v_break_count)    :=  v_id_break;
                                    v_break_count := v_break_count + 1;
                                END IF;
                            END LOOP tipo_break;
                        END LOOP IDP;
                    END IF;
                END LOOP;
            END LOOP k;
        ELSE
            SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
            INTO   v_id_circ_listino
            FROM   CD_CIRCUITO_SCHERMO
            WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO  = v_id_schermo
            AND    CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
            AND    CD_CIRCUITO_SCHERMO.ID_LISTINO  = p_id_listino;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_SCHERMO(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;
            END IF;
        END IF;
    END LOOP;
    IF (v_break_count > 1) THEN
        PR_COMPONI_LISTINO_BREAK(p_id_listino, p_id_circuito, v_list_break, v_esito_comp_break);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.PUT_LINE('Procedura PR_COMPONI_LISTINO_SCHERMO :' ||sqlerrm);
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_LISTINO_ARENA: Errore durante la composizione, verificare la coerenza dei parametri, errore: '||SQLERRM);
        ROLLBACK TO SP_PR_COMPONI_LISTINO_ARENA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_COMPONI_LISTINO_SCHERMO
--
-- DESCRIZIONE:  Composizione dei circuiti di schermo associati al
--               listino di riferimento  oppure lo recupera se esiste gia'
--
-- OPERAZIONI:
--   1) Scorre l'insieme degli schermi da associare al listino
--   2) Associa gli schermi al listino tramite il circuito
--   3) Cicla su tutti i giorni delle date del listino
--   5) Cicla sulle proiezioni esistenti
--   6) Cicla sui break esistenti
--   7) Associa i break al listino tramite il circuito
--   nel caso in cui il listino schermo era preesistente, viene semplicemente recuperato
--
-- INPUT:
--      p_id_listino        id del listino
--      p_id_circuito       id del circuito
--      p_list_id_schermi   lista degli id degli schermi
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella composizione del listino
--   >10 indica che il circuito e' stato recuperato, ed il valore (diminuito di 10) restituisce il numero
--               di elementi recuperati
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Luglio 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
--  MODIFICHE: Roberto Barbaro, Teoresi srl, Settembre 2009
--
--  MODIFICHE: Roberto Barbaro, Teoresi srl, Novembre 2009
--          Modificata la gestione del numero di proiezioni:
--          tolte dal campo NUMERO_PROIEZIONI di CD_SALA
--          e prese dalle fasce associate al tipo "Fascia Proiezioni"
--              Tommaso D'Anna, Teoresi srl, 29 Novembre 2011
--                  Inserita chiamata a PA_CD_PRODOTTO_ACQUISTATO.PR_RIPRISTINA_SALA
-------------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_SCHERMO  ( p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito           IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_schermi       IN id_schermi_type,
                                        p_esito                 OUT NUMBER)
IS
    v_num_proiezioni        CD_SALA.NUMERO_PROIEZIONI%TYPE;
    v_num_giorni            NUMBER;
    v_date_start            CD_LISTINO.DATA_INIZIO%TYPE;
    v_date_end              CD_LISTINO.DATA_FINE%TYPE;
    v_id_fascia             CD_FASCIA.ID_FASCIA%TYPE;
    v_data_proiezione       CD_PROIEZIONE.DATA_PROIEZIONE%TYPE;
    v_id_proiezione         CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
    v_id_break              CD_BREAK.ID_BREAK%TYPE;
    v_esito_ins_break       NUMBER;
    v_esito_comp_break      NUMBER;
    v_list_break            id_break_type;
    v_break_count           NUMBER;
    v_esiste_gia            INTEGER:=0;
    v_id_circ_listino       INTEGER:=-1;
    v_data_inizio_listino   CD_LISTINO.DATA_INIZIO%TYPE;
    v_data_fine_listino     CD_LISTINO.DATA_FINE%TYPE;
    v_data_inizio           CD_LISTINO.DATA_INIZIO%TYPE;
    v_id_sala               CD_SCHERMO.ID_SALA%TYPE;
    CURSOR c_tipo_break IS
        SELECT ID_TIPO_BREAK
        FROM   CD_CIRCUITO_TIPO_BREAK
	    WHERE  FLG_ANNULLATO = 'N'
        and    id_circuito = p_id_circuito;
BEGIN
    p_esito := 1;
    v_break_count := 1;
    SAVEPOINT SP_PR_COMPONI_LISTINO_SCHERMO;
    SELECT DATA_INIZIO, DATA_FINE
    INTO   v_date_start, v_date_end
    FROM   CD_LISTINO
    WHERE  ID_LISTINO = p_id_listino;
    v_num_giorni := v_date_end - v_date_start;
    FOR i IN 1..p_list_id_schermi.COUNT LOOP    -- cicla sull'insieme degli schermi da comporre
        SELECT COUNT(*)
        INTO  v_esiste_gia
        FROM  CD_CIRCUITO_SCHERMO
        WHERE CD_CIRCUITO_SCHERMO.ID_SCHERMO = p_list_id_schermi(i)
        AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
        AND   CD_CIRCUITO_SCHERMO.ID_LISTINO = p_id_listino;
        IF(v_esiste_gia = 0)THEN
            INSERT INTO CD_CIRCUITO_SCHERMO          -- associa gli schermi al listino tramite il circuito
               (ID_SCHERMO, ID_CIRCUITO, ID_LISTINO)
            VALUES
               (p_list_id_schermi(i), p_id_circuito, p_id_listino);
            FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni delle date del listino
                FOR id_fascia IN (SELECT ID_FASCIA FROM CD_FASCIA WHERE ID_TIPO_FASCIA IN(
                                        SELECT ID_TIPO_FASCIA FROM CD_TIPO_FASCIA WHERE DESC_TIPO = 'Fascia Proiezioni')) LOOP
                    v_data_proiezione    :=   v_date_start + k ;
                    v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(p_list_id_schermi(i),v_data_proiezione,id_fascia.id_fascia);
                    IF(v_id_proiezione != 0)THEN
                        FOR IDP IN(SELECT  ID_PROIEZIONE
                                   FROM    CD_PROIEZIONE
                                   WHERE   CD_PROIEZIONE.ID_SCHERMO      = p_list_id_schermi(i)
                                   AND     CD_PROIEZIONE.DATA_PROIEZIONE = v_data_proiezione) LOOP
                            v_id_proiezione:=IDP.ID_PROIEZIONE;
                            FOR tipo_break in c_tipo_break LOOP
                                v_id_break := PA_CD_BREAK.FU_ESISTE_BREAK(v_id_proiezione, tipo_break.id_tipo_break);
                                IF(v_id_break > 0) THEN -- esiste
                                    v_list_break(v_break_count)    :=  v_id_break;
                                    v_break_count := v_break_count + 1;
                                END IF;
                            END LOOP tipo_break;
                        END LOOP IDP;
                    END IF;
                END LOOP;
            END LOOP k;
        ELSE
            SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
            INTO   v_id_circ_listino
            FROM   CD_CIRCUITO_SCHERMO
            WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO  = p_list_id_schermi(i)
            AND    CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
            AND    CD_CIRCUITO_SCHERMO.ID_LISTINO  = p_id_listino;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_SCHERMO(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;
                SELECT
                    DATA_INIZIO,
                    DATA_FINE
                INTO
                    v_data_inizio_listino,
                    v_data_fine_listino
                FROM CD_LISTINO
                WHERE ID_LISTINO = p_id_listino;
                IF ( trunc(SYSDATE) <= v_data_fine_listino ) THEN
                    IF ( v_data_inizio_listino > trunc(SYSDATE) ) THEN
                        v_data_inizio := v_data_inizio_listino;
                    ELSE
                        v_data_inizio := trunc(SYSDATE);
                    END IF;  
                    SELECT 
                        ID_SALA 
                    INTO
                        v_id_sala
                    FROM 
                        CD_SCHERMO 
                    WHERE ID_SCHERMO = p_list_id_schermi(i);             
                    PA_CD_PRODOTTO_ACQUISTATO.PR_RIPRISTINA_SALA(v_id_sala, v_data_inizio, v_data_fine_listino, p_id_circuito);
                END IF;                
            END IF;
        END IF;
    END LOOP;
    IF (v_break_count > 1) THEN
        PR_COMPONI_LISTINO_BREAK(p_id_listino, p_id_circuito, v_list_break, v_esito_comp_break);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.PUT_LINE('Procedura PR_COMPONI_LISTINO_SCHERMO :' ||sqlerrm);
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_LISTINO_SCHERMO: Errore durante la composizione, verificare la coerenza dei parametri, errore: '||SQLERRM);
        ROLLBACK TO SP_PR_COMPONI_LISTINO_SCHERMO;
END;
PROCEDURE PR_COMPONI_SCHERMO_TEMP  ( p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito           IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_list_id_schermi       IN id_schermi_type,
                                        p_esito                 OUT NUMBER)
IS
    v_num_proiezioni     CD_SALA.NUMERO_PROIEZIONI%TYPE;
    v_num_giorni         NUMBER;
    v_date_start         CD_LISTINO.DATA_INIZIO%TYPE;
    v_date_end           CD_LISTINO.DATA_FINE%TYPE;
    v_id_fascia          CD_FASCIA.ID_FASCIA%TYPE;
    v_data_proiezione    CD_PROIEZIONE.DATA_PROIEZIONE%TYPE;
    v_id_proiezione      CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
    v_id_break           CD_BREAK.ID_BREAK%TYPE;
    v_esito_ins_break    NUMBER;
    v_esito_comp_break   NUMBER;
    v_list_break         id_break_type;
    v_break_count        NUMBER;
    v_esiste_gia         INTEGER:=0;
    v_id_circ_listino    INTEGER:=-1;
    CURSOR c_tipo_break IS
        SELECT ID_TIPO_BREAK
        FROM   CD_CIRCUITO_TIPO_BREAK
	    WHERE  FLG_ANNULLATO = 'N'
        and    id_circuito = p_id_circuito;
BEGIN
    p_esito := 1;
    v_break_count := 1;
    SAVEPOINT SP_PR_COMPONI_SCHERMO_TEMP;
    SELECT DATA_INIZIO, DATA_FINE
    INTO   v_date_start, v_date_end
    FROM   CD_LISTINO
    WHERE  ID_LISTINO = p_id_listino;
    v_num_giorni := v_date_end - v_date_start;
    FOR i IN 1..p_list_id_schermi.COUNT LOOP    -- cicla sull'insieme degli schermi da comporre
        SELECT COUNT(*)
        INTO  v_esiste_gia
        FROM  CD_CIRCUITO_SCHERMO
        WHERE CD_CIRCUITO_SCHERMO.ID_SCHERMO = p_list_id_schermi(i)
        AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
        AND   CD_CIRCUITO_SCHERMO.ID_LISTINO = p_id_listino;
        IF(v_esiste_gia = 0)THEN
            INSERT INTO CD_CIRCUITO_SCHERMO          -- associa gli schermi al listino tramite il circuito
               (ID_SCHERMO, ID_CIRCUITO, ID_LISTINO)
            VALUES
               (p_list_id_schermi(i), p_id_circuito, p_id_listino);
            FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni delle date del listino
                FOR id_fascia IN (SELECT ID_FASCIA FROM CD_FASCIA WHERE ID_TIPO_FASCIA IN(
                                        SELECT ID_TIPO_FASCIA FROM CD_TIPO_FASCIA WHERE DESC_TIPO = 'Fascia Proiezioni')) LOOP
                    v_data_proiezione    :=   v_date_start + k ;
                    v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(p_list_id_schermi(i),v_data_proiezione,id_fascia.id_fascia);
                    IF(v_id_proiezione != 0)THEN
                        FOR IDP IN(SELECT  ID_PROIEZIONE
                                   FROM    CD_PROIEZIONE
                                   WHERE   CD_PROIEZIONE.ID_SCHERMO      = p_list_id_schermi(i)
                                   AND     CD_PROIEZIONE.DATA_PROIEZIONE = v_data_proiezione) LOOP
                            v_id_proiezione:=IDP.ID_PROIEZIONE;
                            FOR tipo_break in c_tipo_break LOOP
                                v_id_break := PA_CD_BREAK.FU_ESISTE_BREAK(v_id_proiezione, tipo_break.id_tipo_break);
                                IF(v_id_break > 0) THEN -- esiste
                                    v_list_break(v_break_count)    :=  v_id_break;
                                    v_break_count := v_break_count + 1;
                                END IF;
                            END LOOP tipo_break;
                        END LOOP IDP;
                    END IF;
                END LOOP;
            END LOOP k;
        ELSE
            SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
            INTO   v_id_circ_listino
            FROM   CD_CIRCUITO_SCHERMO
            WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO  = p_list_id_schermi(i)
            AND    CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
            AND    CD_CIRCUITO_SCHERMO.ID_LISTINO  = p_id_listino;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_SCHERMO(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;
            END IF;
        END IF;
    END LOOP;
    IF (v_break_count > 1) THEN
        PR_COMPONI_BREAK_TEMP(p_id_listino, p_id_circuito, v_list_break, v_esito_comp_break);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.PUT_LINE('Procedura PR_COMPONI_LISTINO_SCHERMO :' ||sqlerrm);
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_SCHERMO_TEMP: Errore durante la composizione, verificare la coerenza dei parametri, errore: '||SQLERRM);
        ROLLBACK TO SP_PR_COMPONI_SCHERMO_TEMP;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_COMPONI_LISTINO_SCHERMO_CLONA
--
-- DESCRIZIONE:  Composizione dei circuiti di schermo associati al
--               listino di riferimento  oppure lo recupera se esiste gia'
--               copiata dalla procedura PR_COMPONI_LISTINO_SCHERMO SENZA L'USO DELL'ARRAY DI SCHERMI
--               TENTATIVO DI OTTIMIZZAZIONE
--               USATA SOLO NELLA PROCEDURA DI CLONAZIONE LISTINO 
--
-- OPERAZIONI:
--   1) Scorre l'insieme degli schermi da associare al listino
--   2) Associa gli schermi al listino tramite il circuito
--   3) Cicla su tutti i giorni delle date del listino
--   5) Cicla sulle proiezioni esistenti
--   6) Cicla sui break esistenti
--   7) Associa i break al listino tramite il circuito
--   nel caso in cui il listino schermo era preesistente, viene semplicemente recuperato
--
-- INPUT:
--      p_id_listino        id del listino
--      p_id_listino_orig   id del listino originario dal quale recuperare gli schermi
--      p_id_circuito       id del circuito
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella composizione del listino
--   >10 indica che il circuito e' stato recuperato, ed il valore (diminuito di 10) restituisce il numero
--               di elementi recuperati
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Aprile 2011
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_LISTINO_SCHERMO_CLONA  ( p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_listino_orig       IN CD_LISTINO.ID_LISTINO%TYPE,
                                        p_id_circuito           IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        p_esito                 OUT NUMBER)
IS
    v_num_proiezioni     CD_SALA.NUMERO_PROIEZIONI%TYPE;
    v_num_giorni         NUMBER;
    v_date_start         CD_LISTINO.DATA_INIZIO%TYPE;
    v_date_end           CD_LISTINO.DATA_FINE%TYPE;
    v_id_fascia          CD_FASCIA.ID_FASCIA%TYPE;
    v_data_proiezione    CD_PROIEZIONE.DATA_PROIEZIONE%TYPE;
    v_id_proiezione      CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
    v_id_break           CD_BREAK.ID_BREAK%TYPE;
    v_esito_ins_break    NUMBER;
    v_esito_comp_break   NUMBER;
    v_list_break         id_break_type;
    v_break_count        NUMBER;
    v_esiste_gia         INTEGER:=0;
    v_id_circ_listino    INTEGER:=-1;
    CURSOR c_tipo_break IS
       SELECT ID_TIPO_BREAK
        FROM   CD_CIRCUITO_TIPO_BREAK
	    WHERE  FLG_ANNULLATO = 'N'
        and    id_circuito = p_id_circuito;
BEGIN
    p_esito := 1;
    v_break_count := 1;
    SAVEPOINT SP_PR_LISTINO_SCHERMO_CLONA;
    SELECT DATA_INIZIO, DATA_FINE
    INTO   v_date_start, v_date_end
    FROM   CD_LISTINO
    WHERE  ID_LISTINO = p_id_listino;
    v_num_giorni := v_date_end - v_date_start;
    for list_id_schermi in
        (
            select distinct id_schermo
            from cd_circuito_schermo
            where id_listino = p_id_listino_orig
            AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
            and   flg_annullato = 'N'
        )LOOP
        SELECT COUNT(*)
        INTO  v_esiste_gia
        FROM  CD_CIRCUITO_SCHERMO
        WHERE CD_CIRCUITO_SCHERMO.ID_SCHERMO = list_id_schermi.id_schermo
        AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
        AND   CD_CIRCUITO_SCHERMO.ID_LISTINO = p_id_listino;
        IF(v_esiste_gia = 0)THEN
            INSERT INTO CD_CIRCUITO_SCHERMO          -- associa gli schermi al listino tramite il circuito
               (ID_SCHERMO, ID_CIRCUITO, ID_LISTINO)
            VALUES
               (list_id_schermi.id_schermo, p_id_circuito, p_id_listino);
            FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni delle date del listino
                FOR id_fascia IN (SELECT ID_FASCIA FROM CD_FASCIA WHERE ID_TIPO_FASCIA IN(
                                        SELECT ID_TIPO_FASCIA FROM CD_TIPO_FASCIA WHERE DESC_TIPO = 'Fascia Proiezioni')) LOOP
                    v_data_proiezione    :=   v_date_start + k ;
                    v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(list_id_schermi.id_schermo,v_data_proiezione,id_fascia.id_fascia);
                    IF(v_id_proiezione != 0)THEN
                        FOR IDP IN(SELECT  ID_PROIEZIONE
                                   FROM    CD_PROIEZIONE
                                   WHERE   CD_PROIEZIONE.ID_SCHERMO      = list_id_schermi.id_schermo
                                   AND     CD_PROIEZIONE.DATA_PROIEZIONE = v_data_proiezione) LOOP
                            v_id_proiezione:=IDP.ID_PROIEZIONE;
                            FOR tipo_break in c_tipo_break LOOP
                                v_id_break := PA_CD_BREAK.FU_ESISTE_BREAK(v_id_proiezione, tipo_break.id_tipo_break);
                                IF(v_id_break > 0) THEN -- esiste
                                    v_list_break(v_break_count)    :=  v_id_break;
                                    v_break_count := v_break_count + 1;
                                END IF;
                            END LOOP tipo_break;
                        END LOOP IDP;
                    END IF;
                END LOOP;
            END LOOP k;
        ELSE
            SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
            INTO   v_id_circ_listino
            FROM   CD_CIRCUITO_SCHERMO
            WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO  = list_id_schermi.id_schermo
            AND    CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
            AND    CD_CIRCUITO_SCHERMO.ID_LISTINO  = p_id_listino;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_SCHERMO(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;
            END IF;
        END IF;
    END LOOP;
    IF (v_break_count > 1) THEN
        PR_COMPONI_LISTINO_BREAK(p_id_listino, p_id_circuito, v_list_break, v_esito_comp_break);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.PUT_LINE('Procedura PR_COMPONI_LISTINO_SCHERMO :' ||sqlerrm);
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_LISTINO_SCHERMO_CLONA: Errore durante la composizione, verificare la coerenza dei parametri, errore: '||SQLERRM);
        ROLLBACK TO SP_PR_LISTINO_SCHERMO_CLONA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_COMPONI_LISTINO_BREAK
--
-- DESCRIZIONE:  Composizione dei circuiti di break associati al
--               listino di riferimento
--
-- OPERAZIONI:
--   1) Scorre l'insieme dei break da associare al listino
--
-- INPUT:
--      p_id_listino        id del listino
--      p_id_circuito       id del circuito
--      p_list_id_break     lista degli id dei break
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita: si e verificato un errore nella composizione del listino
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2008
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_LISTINO_BREAK  (p_id_listino      IN CD_LISTINO.ID_LISTINO%TYPE,
                                     p_id_circuito     IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                     p_list_id_break   IN id_break_type,
                                     p_esito           OUT NUMBER)
IS
  v_non_ce    INTEGER:=0;
  v_data_app  DATE;
  v_id_circuito_break   CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK%TYPE;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_COMPONI_LISTINO_BREAK;
     FOR i IN 1..p_list_id_break.COUNT LOOP    -- cicla sull'insieme dei break da comporre
        v_non_ce:=0;
        SELECT COUNT(*)
        INTO  v_non_ce
        FROM  CD_CIRCUITO_BREAK
        WHERE CD_CIRCUITO_BREAK.ID_BREAK    = p_list_id_break(i)
        AND   CD_CIRCUITO_BREAK.ID_CIRCUITO = p_id_circuito
        AND   CD_CIRCUITO_BREAK.ID_LISTINO  = p_id_listino;
        IF(v_non_ce=0)THEN
            --dbms_output.PUT_LINE(p_list_id_break(i)||'  '||p_id_circuito||'  '||p_id_listino);
            INSERT INTO CD_CIRCUITO_BREAK          -- effettua l'inserimento
            (ID_BREAK,
             ID_CIRCUITO,
             ID_LISTINO)
            VALUES
            (p_list_id_break(i),
             p_id_circuito,
             p_id_listino);
            SELECT CD_CIRCUITO_BREAK_SEQ.CURRVAL
            INTO v_id_circuito_break
            FROM DUAL;
            SELECT CD_PROIEZIONE.DATA_PROIEZIONE
            INTO   v_data_app
            FROM   CD_PROIEZIONE, CD_BREAK
            WHERE  CD_BREAK.ID_BREAK=p_list_id_break(i)
            AND    CD_BREAK.ID_PROIEZIONE= CD_PROIEZIONE.ID_PROIEZIONE;
            PA_CD_TARIFFA.PR_REFRESH_TARIFFE_BR(p_id_listino,p_id_circuito,v_id_circuito_break,v_data_app);
        END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.PUT_LINE('Procedura PR_COMPONI_LISTINO_BREAK :' ||sqlerrm);
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_LISTINO_BREAK: Errore durante la composizione, verificare la coerenza dei parametri, errore: ' ||sqlerrm );
        ROLLBACK TO SP_PR_COMPONI_LISTINO_BREAK;
END;
PROCEDURE PR_COMPONI_BREAK_TEMP  (p_id_listino      IN CD_LISTINO.ID_LISTINO%TYPE,
                                  p_id_circuito     IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_list_id_break   IN id_break_type,
                                  p_esito           OUT NUMBER)
IS
  v_non_ce    INTEGER:=0;
  v_data_app  DATE;
  v_id_circuito_break   CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK%TYPE;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_COMPONI_BREAK_TEMP;
    FOR i IN 1..p_list_id_break.COUNT LOOP    -- cicla sull'insieme dei break da comporre
        v_non_ce:=0;
        SELECT COUNT(*)
        INTO  v_non_ce
        FROM  CD_CIRCUITO_BREAK
        WHERE CD_CIRCUITO_BREAK.ID_BREAK    = p_list_id_break(i)
        AND   CD_CIRCUITO_BREAK.ID_CIRCUITO = p_id_circuito
        AND   CD_CIRCUITO_BREAK.ID_LISTINO  = p_id_listino;
        IF(v_non_ce=0)THEN
            --dbms_output.PUT_LINE(p_list_id_break(i)||'  '||p_id_circuito||'  '||p_id_listino);
            INSERT INTO CD_CIRCUITO_BREAK          -- effettua l'inserimento
            (ID_BREAK,
             ID_CIRCUITO,
             ID_LISTINO)
            VALUES
            (p_list_id_break(i),
             p_id_circuito,
             p_id_listino);
            SELECT CD_CIRCUITO_BREAK_SEQ.CURRVAL
            INTO v_id_circuito_break
            FROM DUAL;
            SELECT CD_PROIEZIONE.DATA_PROIEZIONE
            INTO   v_data_app
            FROM   CD_PROIEZIONE, CD_BREAK
            WHERE  CD_BREAK.ID_BREAK=p_list_id_break(i)
            AND    CD_BREAK.ID_PROIEZIONE= CD_PROIEZIONE.ID_PROIEZIONE;
            PA_CD_TARIFFA.PR_REFRESH_TARIFFE_BR(p_id_listino,p_id_circuito,v_id_circuito_break,v_data_app);
        END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.PUT_LINE('Procedura PR_COMPONI_LISTINO_BREAK :' ||sqlerrm);
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura PR_COMPONI_LISTINO_BREAK: Errore durante la composizione, verificare la coerenza dei parametri, errore: ' ||sqlerrm );
        ROLLBACK TO SP_PR_COMPONI_BREAK_TEMP;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_COMPONI_BLOCCO_LISTINI
-- dati in ingresso un elemco di atrii, schermi, cinema, sale
-- gestisco in un'unica transazione la creazione dei relativi circuiti/listino
-- INPUT: id listino, id circuito ed elenchi ambienti per i quali creare i circuiti/listino
-- OUTPUT: 1 tutto andato a buon fine
--        -1 si e' verificato un errore, nessun circuito creato
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COMPONI_BLOCCO_LISTINI( p_id_listino           IN CD_LISTINO.ID_LISTINO%TYPE,
                                     p_id_circuito          IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                     p_list_id_cinema       IN id_cinema_type,
                                     p_list_id_atrii        IN id_atrii_type,
                                     p_list_id_sale         IN id_sale_type,
                                     p_list_id_schermi      IN id_schermi_type,
                                     p_list_id_arene        IN id_list_type,
                                     p_esito                OUT NUMBER)
IS
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_COMPONI_BLOCCO_LISTINI;
    PR_COMPONI_LISTINO_ATRIO(p_id_listino, p_id_circuito, p_list_id_atrii, p_esito);
    IF(p_esito<>-1)THEN
        PR_COMPONI_LISTINO_SALA(p_id_listino, p_id_circuito, p_list_id_sale, p_esito);
        IF(p_esito<>-1)THEN
            PR_COMPONI_LISTINO_CINEMA(p_id_listino, p_id_circuito, p_list_id_cinema, p_esito);
            IF(p_esito<>-1)THEN
                PR_COMPONI_LISTINO_SCHERMO(p_id_listino, p_id_circuito, p_list_id_schermi, p_esito);
                IF(p_esito<>-1)THEN
                    PR_COMPONI_LISTINO_ARENA(p_id_listino, p_id_circuito, p_list_id_arene, p_esito);
                END IF;
            END IF;
        END IF;
    END IF;
    IF(p_esito<>-1)THEN
        p_esito:=1;
    ELSE
        ROLLBACK TO SP_PR_COMPONI_BLOCCO_LISTINI;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura SP_PR_COMPONI_BLOCCO_LISTINI: Errore durante la composizione in blocco dei listini/circuiti: ' ||sqlerrm );
        ROLLBACK TO SP_PR_COMPONI_BLOCCO_LISTINI;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_LISTINO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--      p_id_listino    id del listino
-- OUTPUT: Restituisce il dettaglio del listino
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Agosto 2009
--
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011    
-- --------------------------------------------------------------------------------------------

FUNCTION FU_DETTAGLIO_LISTINO  (p_id_listino        IN CD_LISTINO.ID_LISTINO%TYPE)
                                RETURN C_DETT_LISTINO
IS
    v_return_value C_DETT_LISTINO;
BEGIN

    OPEN v_return_value
        FOR
         SELECT 
            CD_LISTINO.ID_LISTINO, 
            CD_LISTINO.DESC_LISTINO, 
            CD_LISTINO.DATA_INIZIO AS DATA_INIZIO_LISTINO,
            CD_LISTINO.DATA_FINE AS DATA_FINE_LISTINO,
            CD_LISTINO.COD_CATEGORIA_PRODOTTO,
            CD_SCONTO_STAGIONALE.ID_SCONTO_STAGIONALE,
            CD_SCONTO_STAGIONALE.PERC_SCONTO, 
            CD_SCONTO_STAGIONALE.DATA_INIZIO AS DATA_INIZIO_SCONTO,
            CD_SCONTO_STAGIONALE.DATA_FINE AS DATA_FINE_SCONTO
         FROM   CD_LISTINO, CD_SCONTO_STAGIONALE
         WHERE  CD_LISTINO.ID_LISTINO = CD_SCONTO_STAGIONALE.ID_LISTINO(+)
         AND    CD_LISTINO.ID_LISTINO = p_id_listino;

    RETURN v_return_value;

END FU_DETTAGLIO_LISTINO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_LISTINO
-- --------------------------------------------------------------------------------------------
-- INPUT:  Criteri di ricerca dei listini
-- OUTPUT: Restituisce i listini che rispondono ai criteri di ricerca
--          se uno o piu' parametri di ingresso sono nulli viene considerato come *
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011              
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_LISTINO(p_desc_listino     CD_LISTINO.DESC_LISTINO%TYPE,
                          p_data_inizio      CD_LISTINO.DATA_INIZIO%TYPE,
                          p_data_fine        CD_LISTINO.DATA_FINE%TYPE)
                         RETURN C_LISTINO
IS
    v_return_value C_LISTINO;
BEGIN
    OPEN v_return_value
        FOR
         SELECT distinct listino.ID_LISTINO, listino.DESC_LISTINO, listino.DATA_INIZIO, listino.DATA_FINE, listino.COD_CATEGORIA_PRODOTTO,
                 NVL (circuito_sala.count_sala, 0)
               + NVL (circuito_atrio.count_atrio, 0)
               + NVL (circuito_schermo.count_schermo, 0)
               + NVL (circuito_cinema.count_cinema, 0) AS count_compos
          FROM cd_listino listino,
               (SELECT   a.id_listino, COUNT (a.id_listino) AS count_sala
                    FROM cd_circuito_sala a
                GROUP BY id_listino) circuito_sala,
               (SELECT   a.id_listino, COUNT (a.id_listino) AS count_atrio
                    FROM cd_circuito_atrio a
                GROUP BY id_listino) circuito_atrio,
               (SELECT   a.id_listino, COUNT (a.id_listino) AS count_schermo
                    FROM cd_circuito_schermo a
                GROUP BY id_listino) circuito_schermo,
               (SELECT   a.id_listino, COUNT (a.id_listino) AS count_cinema
                    FROM cd_circuito_cinema a
                GROUP BY id_listino) circuito_cinema
         WHERE listino.id_listino = circuito_schermo.id_listino(+)
            AND listino.id_listino = circuito_cinema.id_listino(+)
            AND listino.id_listino = circuito_atrio.id_listino(+)
            AND listino.id_listino = circuito_sala.id_listino(+)
            AND listino.DATA_INIZIO >= nvl(p_data_inizio,listino.DATA_INIZIO)
            AND listino.DATA_FINE <= nvl(p_data_fine,listino.DATA_FINE)
            AND upper(listino.DESC_LISTINO) LIKE upper('%'||nvl(p_desc_listino,listino.DESC_LISTINO)||'%')
            order by listino.data_inizio desc;
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'PROCEDURA PR_CERCA_LISTINO: Ricerca non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_LISTINO(p_desc_listino,
                                                                                                                                                    p_data_inizio,
                                                                                                                                                    p_data_fine));
END FU_CERCA_LISTINO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_LISTINI_NON_VUOTI
--
-- INPUT:
-- OUTPUT: Restituisce l'elenco dei listini vuoti
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Settembre 2009
--
-- MODIFICHE:   Inserita gestione del codice categoria prodotto
--              Tommaso D'Anna, Teoresi srl, 5 Settembre 2011   
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_LISTINI_NON_VUOTI
                            RETURN C_LISTINO
IS
    v_return_value C_LISTINO;
BEGIN
    OPEN v_return_value
        FOR
         SELECT ID_LISTINO, DESC_LISTINO, DATA_INIZIO, DATA_FINE, COD_CATEGORIA_PRODOTTO,1
         FROM   CD_LISTINO
         WHERE  FU_LISTINO_VUOTO_PIENO(ID_LISTINO)=1;
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'PROCEDURA FU_CERCA_LISTINI_NON_VUOTI: Ricerca non eseguita, si e'' verificato un errore '||SQLERRM);
END FU_CERCA_LISTINI_NON_VUOTI;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_LISTINO
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i paramtetri
--
-- INPUT:
--      p_desc_listino  descrizione del listino
--      p_data_inizio   data di inizio
--      p_data_fine     data di fine
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_LISTINO(p_desc_listino            CD_LISTINO.DESC_LISTINO%TYPE,
                           p_data_inizio             CD_LISTINO.DATA_INIZIO%TYPE,
                           p_data_fine               CD_LISTINO.DATA_FINE%TYPE)  RETURN VARCHAR2
IS
BEGIN
   IF v_stampa_listino = 'ON' THEN
      RETURN 'DESC_LISTINO: '          || p_desc_listino           || ', ' ||
            'DATA_INIZIO: '          || p_DATA_INIZIO            || ', ' ||
            'DATA_FINE: '      || p_data_fine  ;
END IF;
END  FU_STAMPA_LISTINO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CINEMA_IN_CIRCUITO_LISTINO
-- INPUT:  ID del listino ID del circuito ID del cinema
-- OUTPUT:  0 il cinema (e tutti i suoi componenti) NON appartiene al circuito
--          1 il cinema (o uno dei suoi componenti) appartiene al circuito ma
--            ne' esso ne' alcuno dei suoi componenti e' in un prodotto vendita
--          2 il cinema (o uno dei suoi componenti) appartiene al circuito,
--            esso (o almeno uno dei suoi componenti) e' in un prodotto vendita,
--            ma ne' esso ne' alcuno dei suoi componenti e' in un prodotto acquistato
--          3 il cinema (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed i suoi comunicati sono solamente nel futuro
--          4 il cinema (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed esistono comunicati nel passato o per oggi
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--          Tommaso D'Anna, Teoresi srl, 17 Novembre 2011
--              Aggiunto un quarto stato in relazione ai comunicati nel passato/futuro
--                  NOTA BENE   --- Il vecchio stato 3 "ROSSO" diviene stato 4
--                              --- Il nuovo stato 3 diviene "ARANCIO"
--          Tommaso D'Anna, Teoresi srl, 29 Novembre 2011
--              Modificato il funzionamento della query per adeguarla ad interrogare 
--              la tavola CD_CINEMA_VENDITA   
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CINEMA_IN_CIRCUITO_LISTINO(p_id_listino   IN CD_CIRCUITO_CINEMA.ID_LISTINO%TYPE,
                                       p_id_circuito  IN CD_CIRCUITO_CINEMA.ID_CIRCUITO%TYPE,
                                       p_id_cinema    IN CD_CIRCUITO_CINEMA.ID_CINEMA%TYPE)
            RETURN INTEGER
IS
    v_return_value  INTEGER:=0;
    v_tar           INTEGER;
    v_com           INTEGER;  
BEGIN
    IF(PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_CINEMA(p_id_listino, p_id_circuito, p_id_cinema)>0)THEN
        v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        /*IF(v_return_value<4)THEN
            FOR L1 in (SELECT DISTINCT ID_ATRIO FROM CD_ATRIO WHERE ID_CINEMA=p_id_cinema) LOOP
                v_temp1:=PA_CD_LISTINO.FU_ATRIO_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito, L1.ID_ATRIO);
                IF(v_temp1>v_return_value)THEN
                    v_return_value:=v_temp1;
                END IF;
                EXIT WHEN(v_return_value=4);
            END LOOP;
        END IF;
        IF(v_return_value<4)THEN
            FOR L1 in (SELECT DISTINCT ID_SALA FROM CD_SALA WHERE ID_CINEMA=p_id_cinema) LOOP
                v_temp1:=PA_CD_LISTINO.FU_SALA_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito, L1.ID_SALA);
                IF(v_temp1>v_return_value)THEN
                    v_return_value:=v_temp1;
                END IF;
                EXIT WHEN(v_return_value=4);
            END LOOP;
        END IF;
        */
        /*2011.11.29_TDA*/
        SELECT 
            COUNT(ID_COMUNICATO)
        INTO    
            v_com
        FROM 
            CD_COMUNICATO,
            CD_CIRCUITO_CINEMA,
            CD_CINEMA_VENDITA,
            CD_PRODOTTO_ACQUISTATO,
            CD_PRODOTTO_VENDITA,
            CD_LISTINO
        WHERE   CD_LISTINO.ID_LISTINO                       = p_id_listino
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO             = p_id_circuito
        AND     CD_CIRCUITO_CINEMA.ID_CINEMA                = p_id_cinema
        AND     CD_CIRCUITO_CINEMA.ID_CIRCUITO              = CD_PRODOTTO_VENDITA.ID_CIRCUITO
        AND     CD_CIRCUITO_CINEMA.ID_LISTINO               = CD_LISTINO.ID_LISTINO
        AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE 
        AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND     CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA        = CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
        AND     CD_COMUNICATO.ID_CINEMA_VENDITA             = CD_CINEMA_VENDITA.ID_CINEMA_VENDITA
        AND     CD_COMUNICATO.FLG_ANNULLATO                 = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO                   = 'N'
        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO        = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV          <= TRUNC(SYSDATE)
        AND     ROWNUM <= 1;
        IF( v_com > 0 ) THEN
            -- Se qui v_com > 0 vuol dire che esistono comunicati nel passato o per oggi
            v_return_value:=4;
        ELSE     
            SELECT 
                COUNT(ID_COMUNICATO)
            INTO    
                v_com
        FROM 
            CD_COMUNICATO,
            CD_CIRCUITO_CINEMA,
            CD_CINEMA_VENDITA,
            CD_PRODOTTO_ACQUISTATO,
            CD_PRODOTTO_VENDITA,
            CD_LISTINO
            WHERE   CD_LISTINO.ID_LISTINO                       = p_id_listino
            AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO             = p_id_circuito
            AND     CD_CIRCUITO_CINEMA.ID_CINEMA                = p_id_cinema
            AND     CD_CIRCUITO_CINEMA.ID_CIRCUITO              = CD_PRODOTTO_VENDITA.ID_CIRCUITO
            AND     CD_CIRCUITO_CINEMA.ID_LISTINO               = CD_LISTINO.ID_LISTINO
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE 
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND     CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA        = CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
            AND     CD_COMUNICATO.ID_CINEMA_VENDITA             = CD_CINEMA_VENDITA.ID_CINEMA_VENDITA
            AND     CD_COMUNICATO.FLG_ANNULLATO                 = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO                   = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO        = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV          > TRUNC(SYSDATE)
            AND     ROWNUM <= 1;
            IF( v_com > 0 )THEN
                -- Se qui v_com > 0 vuol dire che esistono comunicati solo nel futuro
                v_return_value:=3;
            ELSE
                -- Non esistono ancora sono comunicati, verifico se esistono i prodotti di vendita
                SELECT 
                    COUNT(ID_TARIFFA)
                INTO
                    v_tar
                FROM
                    CD_TARIFFA,
                    CD_PRODOTTO_VENDITA
                WHERE   CD_TARIFFA.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
                AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
                AND     CD_TARIFFA.ID_LISTINO           = p_id_listino
                AND     ROWNUM <=1;
                IF( v_tar > 0 )THEN
                    v_return_value:=2;
                END IF;
            END IF;
        END IF;        
        /*2011.11.29_TDA*/        
    END IF;
    /*IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_cinema IS NOT NULL) THEN
        SELECT COUNT(*)
        INTO  v_temp1
        FROM  CD_CIRCUITO_CINEMA
        WHERE CD_CIRCUITO_CINEMA.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_CINEMA.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_CINEMA.ID_CINEMA=p_id_cinema;
        IF(v_temp1>0) THEN
            v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        END IF;
    END IF;*/
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_CINEMA_IN_CIRCUITO_LISTINO: Impossibile valutare la richiesta'||SQLERRM);
        RETURN -1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ATRIO_IN_CIRCUITO_LISTINO
-- INPUT:  ID del listino ID del circuito ID dell'atrio
-- OUTPUT:  0 l'atrio (e tutti i suoi componenti) NON appartiene al circuito
--          1 l'atrio (o uno dei suoi componenti) appartiene al circuito ma
--            ne' esso ne' alcuno dei suoi componenti e' in un prodotto vendita
--          2 l'atrio (o uno dei suoi componenti) appartiene al circuito,
--            esso (o almeno uno dei suoi componenti) e' in un prodotto vendita,
--            ma ne' esso ne' alcuno dei suoi componenti e' in un prodotto acquistato
--          3 l'atrio (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed i suoi comunicati sono solamente nel futuro
--          4 l'atrio (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed esistono comunicati nel passato o per oggi
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--          Tommaso D'Anna, Teoresi srl, 17 Novembre 2011
--              Aggiunto un quarto stato in relazione ai comunicati nel passato/futuro
--                  NOTA BENE   --- Il vecchio stato 3 "ROSSO" diviene stato 4
--                              --- Il nuovo stato 3 diviene "ARANCIO"
--          Tommaso D'Anna, Teoresi srl, 29 Novembre 2011
--              Modificato il funzionamento della query per adeguarla ad interrogare 
--              la tavola CD_ATRIO_VENDITA   
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ATRIO_IN_CIRCUITO_LISTINO(p_id_listino   IN CD_CIRCUITO_ATRIO.ID_LISTINO%TYPE,
                                      p_id_circuito  IN CD_CIRCUITO_ATRIO.ID_CIRCUITO%TYPE,
                                      p_id_atrio     IN CD_CIRCUITO_ATRIO.ID_ATRIO%TYPE)
RETURN INTEGER
IS
    v_return_value  INTEGER:=0;
    v_tar           INTEGER;
    v_com           INTEGER;    
BEGIN
    IF(PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_ATRIO(p_id_listino, p_id_circuito, p_id_atrio)>0)THEN
        v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        /*IF(v_return_value<4)THEN
            FOR L1 in (SELECT DISTINCT ID_SCHERMO FROM CD_SCHERMO WHERE ID_ATRIO = p_id_atrio) LOOP
                v_temp1:=PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito, L1.ID_SCHERMO);
                IF(v_temp1>v_return_value)THEN
                    v_return_value:=v_temp1;
                END IF;
                EXIT WHEN(v_return_value=4);
            END LOOP;
        END IF;
        */
        /*2011.11.29_TDA*/
        SELECT 
            COUNT(ID_COMUNICATO)
        INTO    
            v_com
        FROM 
            CD_COMUNICATO,
            CD_CIRCUITO_ATRIO,
            CD_ATRIO_VENDITA,
            CD_PRODOTTO_ACQUISTATO,
            CD_PRODOTTO_VENDITA,
            CD_LISTINO
        WHERE   CD_LISTINO.ID_LISTINO                       = p_id_listino
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO             = p_id_circuito
        AND     CD_CIRCUITO_ATRIO.ID_ATRIO                  = p_id_atrio
        AND     CD_CIRCUITO_ATRIO.ID_CIRCUITO               = CD_PRODOTTO_VENDITA.ID_CIRCUITO
        AND     CD_CIRCUITO_ATRIO.ID_LISTINO                = CD_LISTINO.ID_LISTINO
        AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE 
        AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND     CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO          = CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
        AND     CD_COMUNICATO.ID_ATRIO_VENDITA              = CD_ATRIO_VENDITA.ID_ATRIO_VENDITA
        AND     CD_COMUNICATO.FLG_ANNULLATO                 = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO                   = 'N'
        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO        = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV          <= TRUNC(SYSDATE)
        AND     ROWNUM <= 1;
        IF( v_com > 0 ) THEN
            -- Se qui v_com > 0 vuol dire che esistono comunicati nel passato o per oggi
            v_return_value:=4;
        ELSE     
            SELECT 
                COUNT(ID_COMUNICATO)
            INTO    
                v_com
            FROM 
                CD_COMUNICATO,
                CD_CIRCUITO_ATRIO,
                CD_ATRIO_VENDITA,
                CD_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_VENDITA,
                CD_LISTINO
            WHERE   CD_LISTINO.ID_LISTINO                       = p_id_listino
            AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO             = p_id_circuito
            AND     CD_CIRCUITO_ATRIO.ID_ATRIO                  = p_id_atrio
            AND     CD_CIRCUITO_ATRIO.ID_CIRCUITO               = CD_PRODOTTO_VENDITA.ID_CIRCUITO
            AND     CD_CIRCUITO_ATRIO.ID_LISTINO                = CD_LISTINO.ID_LISTINO
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE 
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND     CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO          = CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
            AND     CD_COMUNICATO.ID_ATRIO_VENDITA              = CD_ATRIO_VENDITA.ID_ATRIO_VENDITA
            AND     CD_COMUNICATO.FLG_ANNULLATO                 = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO                   = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO        = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV          > TRUNC(SYSDATE)
            AND     ROWNUM <= 1;
            IF( v_com > 0 )THEN
                -- Se qui v_com > 0 vuol dire che esistono comunicati solo nel futuro
                v_return_value:=3;
            ELSE
                -- Non esistono ancora sono comunicati, verifico se esistono i prodotti di vendita
                SELECT 
                    COUNT(ID_TARIFFA)
                INTO
                    v_tar
                FROM
                    CD_TARIFFA,
                    CD_PRODOTTO_VENDITA
                WHERE   CD_TARIFFA.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
                AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
                AND     CD_TARIFFA.ID_LISTINO           = p_id_listino
                AND     ROWNUM <=1;
                IF( v_tar > 0 )THEN
                    v_return_value:=2;
                END IF;
            END IF;
        END IF;        
        /*2011.11.29_TDA*/
    END IF;
    /*IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_atrio IS NOT NULL) THEN
        SELECT COUNT(*)
        INTO  v_temp1
        FROM  CD_CIRCUITO_ATRIO
        WHERE CD_CIRCUITO_ATRIO.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_ATRIO.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_ATRIO.ID_ATRIO=p_id_atrio;
        IF(v_temp1>0) THEN
            v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        END IF;
    END IF;*/
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_ATRIO_IN_CIRCUITO_LISTINO: Impossibile valutare la richiesta');
        RETURN -1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SALA_IN_CIRCUITO_LISTINO
-- INPUT:  ID del listino ID del circuito ID della sala
-- OUTPUT:  0 la sala (e tutti i suoi componenti) NON appartiene al circuito
--          1 la sala (o uno dei suoi componenti) appartiene al circuito ma
--            ne' esso ne' alcuno dei suoi componenti e' in un prodotto vendita
--          2 la sala (o uno dei suoi componenti) appartiene al circuito,
--            esso (o almeno uno dei suoi componenti) e' in un prodotto vendita,
--            ma ne' esso ne' alcuno dei suoi componenti e' in un prodotto acquistato
--          3 la sala (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed i suoi comunicati sono solamente nel futuro
--          4 la sala (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed esistono comunicati nel passato o per oggi
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--          Tommaso D'Anna, Teoresi srl, 17 Novembre 2011
--              Aggiunto un quarto stato in relazione ai comunicati nel passato/futuro
--                  NOTA BENE   --- Il vecchio stato 3 "ROSSO" diviene stato 4
--                              --- Il nuovo stato 3 diviene "ARANCIO"
--          Tommaso D'Anna, Teoresi srl, 29 Novembre 2011
--              Modificato il funzionamento della query per adeguarla ad interrogare 
--              la tavola CD_SALA_VENDITA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALA_IN_CIRCUITO_LISTINO(p_id_listino  IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                     p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
                                     p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
            RETURN INTEGER
IS
    v_return_value  INTEGER:=0;
    v_tar           INTEGER;
    v_com           INTEGER;  
BEGIN
    IF(PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_SALA(p_id_listino, p_id_circuito, p_id_sala)>0)THEN
        v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        /*IF(v_return_value<4)THEN
            FOR L1 in (SELECT DISTINCT ID_SCHERMO FROM CD_SCHERMO WHERE ID_SALA = p_id_sala) LOOP
                v_temp1:=PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito, L1.ID_SCHERMO);
                IF(v_temp1>v_return_value)THEN
                    v_return_value:=v_temp1;
                END IF;
                EXIT WHEN(v_return_value=4);
            END LOOP;
        END IF;
        */
        /*2011.11.29_TDA*/
        SELECT 
            COUNT(ID_COMUNICATO)
        INTO    
            v_com
        FROM 
            CD_COMUNICATO,
            CD_CIRCUITO_SALA,
            CD_SALA_VENDITA,
            CD_PRODOTTO_ACQUISTATO,
            CD_PRODOTTO_VENDITA,
            CD_LISTINO
        WHERE   CD_LISTINO.ID_LISTINO                       = p_id_listino
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO             = p_id_circuito
        AND     CD_CIRCUITO_SALA.ID_SALA                    = p_id_sala
        AND     CD_CIRCUITO_SALA.ID_CIRCUITO                = CD_PRODOTTO_VENDITA.ID_CIRCUITO
        AND     CD_CIRCUITO_SALA.ID_LISTINO                 = CD_LISTINO.ID_LISTINO
        AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE 
        AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND     CD_SALA_VENDITA.ID_CIRCUITO_SALA            = CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
        AND     CD_COMUNICATO.ID_SALA_VENDITA               = CD_SALA_VENDITA.ID_SALA_VENDITA
        AND     CD_COMUNICATO.FLG_ANNULLATO                 = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO                   = 'N'
        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO        = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV          <= TRUNC(SYSDATE)
        AND     ROWNUM <= 1;
        IF( v_com > 0 ) THEN
            -- Se qui v_com > 0 vuol dire che esistono comunicati nel passato o per oggi
            v_return_value:=4;
        ELSE     
            SELECT 
                COUNT(ID_COMUNICATO)
            INTO    
                v_com
            FROM 
                CD_COMUNICATO,
                CD_CIRCUITO_SALA,
                CD_SALA_VENDITA,
                CD_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_VENDITA,
                CD_LISTINO
            WHERE   CD_LISTINO.ID_LISTINO                       = p_id_listino
            AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO             = p_id_circuito
            AND     CD_CIRCUITO_SALA.ID_SALA                    = p_id_sala
            AND     CD_CIRCUITO_SALA.ID_CIRCUITO                = CD_PRODOTTO_VENDITA.ID_CIRCUITO
            AND     CD_CIRCUITO_SALA.ID_LISTINO                 = CD_LISTINO.ID_LISTINO
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE 
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND     CD_SALA_VENDITA.ID_CIRCUITO_SALA            = CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
            AND     CD_COMUNICATO.ID_SALA_VENDITA               = CD_SALA_VENDITA.ID_SALA_VENDITA
            AND     CD_COMUNICATO.FLG_ANNULLATO                 = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO                   = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO        = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV          > TRUNC(SYSDATE)
            AND     ROWNUM <= 1;
            IF( v_com > 0 )THEN
                -- Se qui v_com > 0 vuol dire che esistono comunicati solo nel futuro
                v_return_value:=3;
            ELSE
                -- Non esistono ancora sono comunicati, verifico se esistono i prodotti di vendita
                SELECT 
                    COUNT(ID_TARIFFA)
                INTO
                    v_tar
                FROM
                    CD_TARIFFA,
                    CD_PRODOTTO_VENDITA
                WHERE   CD_TARIFFA.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
                AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
                AND     CD_TARIFFA.ID_LISTINO           = p_id_listino
                AND     ROWNUM <= 1;
                IF( v_tar > 0 )THEN
                    v_return_value:=2;
                END IF;
            END IF;
        END IF;        
        /*2011.11.29_TDA*/        
    END IF;
    /*IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_sala IS NOT NULL) THEN
        SELECT COUNT(*)
        INTO  v_temp1
        FROM  CD_CIRCUITO_SALA
        WHERE CD_CIRCUITO_SALA.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_SALA.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_SALA.ID_SALA=p_id_sala;
        IF(v_temp1>0) THEN
            v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        END IF;
    END IF;*/
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_SALA_IN_CIRCUITO_LISTINO: Impossibile valutare la richiesta');
        RETURN -1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ARENA_IN_CIRCUITO_LISTINO
-- INPUT:  ID del listino ID del circuito ID della sala
-- OUTPUT:  0 la sala (e tutti i suoi componenti) NON appartiene al circuito
--          1 la sala (o uno dei suoi componenti) appartiene al circuito ma
--            ne' esso ne' alcuno dei suoi componenti e' in un prodotto vendita
--          2 la sala (o uno dei suoi componenti) appartiene al circuito,
--            esso (o almeno uno dei suoi componenti) e' in un prodotto vendita,
--            ma ne' esso ne' alcuno dei suoi componenti e' in un prodotto acquistato
--          3 la sala (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed i suoi comunicati sono solamente nel futuro
--          4 la sala (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed esistono comunicati nel passato o per oggi
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--            Tommaso D'Anna, Teoresi srl, 17 Novembre 2011
--              Aggiunto un quarto stato in relazione ai comunicati nel passato/futuro
--                  NOTA BENE   --- Il vecchio stato 3 "ROSSO" diviene stato 4
--                              --- Il nuovo stato 3 diviene "ARANCIO"
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ARENA_IN_CIRCUITO_LISTINO(p_id_listino  IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                      p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
                                      p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
    v_temp1 INTEGER:=0;
BEGIN
    IF(PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_ARENA(p_id_listino, p_id_circuito, p_id_sala)>0)THEN
        v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        IF(v_return_value<4)THEN
            FOR L1 in (SELECT DISTINCT ID_SCHERMO FROM CD_SCHERMO WHERE ID_SALA = p_id_sala) LOOP
                v_temp1:=PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito, L1.ID_SCHERMO);
                IF(v_temp1>v_return_value)THEN
                    v_return_value:=v_temp1;
                END IF;
                EXIT WHEN(v_return_value=4);
            END LOOP;
        END IF;
    END IF;
    /*IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_sala IS NOT NULL) THEN
        SELECT COUNT(*)
        INTO  v_temp1
        FROM  CD_CIRCUITO_SALA
        WHERE CD_CIRCUITO_SALA.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_SALA.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_SALA.ID_SALA=p_id_sala;
        IF(v_temp1>0) THEN
            v_return_value:=FU_VENDUTO_ACQUISTATO(p_id_listino,p_id_circuito);
        END IF;
    END IF;*/
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_ARENA_IN_CIRCUITO_LISTINO: Impossibile valutare la richiesta');
        RETURN -1;
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SCHERMO_IN_CIRCUITO_LIS_LIB
-- DESCRIZIONE: da usare per circuiti con modalita' di vendita in libera
-- INPUT:  ID del listino ID del circuito ID dello schermo
-- OUTPUT:  0 lo schermo (e tutti i suoi componenti) NON appartiene al circuito
--          1 lo schermo (o uno dei suoi componenti) appartiene al circuito ma
--            ne' esso ne' alcuno dei suoi componenti e' in un prodotto vendita
--          2 lo schermo (o uno dei suoi componenti) appartiene al circuito,
--            esso (o almeno uno dei suoi componenti) e' in un prodotto vendita,
--            ma ne' esso ne' alcuno dei suoi componenti e' in un prodotto acquistato
--          3 lo schermo (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed i suoi comunicati sono solamente nel futuro
--          4 lo schermo (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--            ed esistono comunicati nel passato o per oggi
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Ottobre 2009
--
-- MODIFICHE  Luigi Cipolla, Sipra, Ottobre 2009
--            Antonio Colucci, Teoresi srl, Maggio 2011
--              Ottimizzazione query per il recupero info vendita in funzione 
--              denormalizzazioni eseguite inserite cu cd_comunicato
--            Tommaso D'Anna, Teoresi srl, 17 Novembre 2011
--              Aggiunto un quarto stato in relazione ai comunicati nel passato/futuro
--                  NOTA BENE   --- Il vecchio stato 3 "ROSSO" diviene stato 4
--                              --- Il nuovo stato 3 diviene "ARANCIO"
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMO_IN_CIRCUITO_LIS_LIB(p_id_listino  IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                        p_id_circuito IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
                                        p_id_schermo  IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
    v_tar       INTEGER;
    v_com       INTEGER;
BEGIN
    v_return_value:=0;
    IF(PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino, p_id_circuito, p_id_schermo)>0)THEN
        v_return_value:=1;
        /*SELECT count(ID_TARIFFA) num_tariffe, count(ID_COMUNICATO) num_comunicati
        INTO v_tar, v_com
        FROM CD_TARIFFA tar,
          CD_PRODOTTO_VENDITA prven,
          CD_COMUNICATO spot,
          CD_BREAK_VENDITA brven,
          CD_CIRCUITO_BREAK cirbr,
          CD_BREAK br,
          CD_PROIEZIONE pro,
          CD_LISTINO lis
        WHERE lis.id_listino=p_id_listino
          and pro.ID_SCHERMO=p_id_schermo
          and pro.data_proiezione between lis.data_inizio and lis.data_fine
          and br.ID_PROIEZIONE = pro.ID_PROIEZIONE
          and cirbr.ID_BREAK = br.ID_BREAK
          and cirbr.ID_CIRCUITO=p_id_circuito
          and brven.ID_CIRCUITO_BREAK = cirbr.ID_CIRCUITO_BREAK
          and spot.ID_BREAK_VENDITA(+) = brven.ID_BREAK_VENDITA
          and spot.FLG_ANNULLATO(+)='N'
          and spot.FLG_SOSPESO = 'N'
          and spot.COD_DISATTIVAZIONE IS NULL
          and prven.ID_PRODOTTO_VENDITA = brven.ID_PRODOTTO_VENDITA
          and tar.ID_PRODOTTO_VENDITA = prven.ID_PRODOTTO_VENDITA;
        IF(v_com>0)THEN
            v_return_value:=3;
        ELSE
            IF(v_tar>0)THEN
                v_return_value:=2;
            END IF;
        END IF;*/
        /*A.C.*/
        SELECT 
                COUNT(ID_COMUNICATO)
                INTO V_COM
        FROM 
                CD_COMUNICATO,
                CD_SCHERMO,
                CD_SALA,
                CD_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_VENDITA,
                CD_LISTINO
        WHERE
                CD_LISTINO.ID_LISTINO = p_id_listino
        AND     CD_SCHERMO.ID_SCHERMO = p_id_schermo                
        AND     CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
        AND     CD_SALA.ID_SALA = CD_COMUNICATO.ID_SALA
        AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
        AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE 
        AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV <= TRUNC(SYSDATE)
        AND     ROWNUM <= 1;
        IF( v_com > 0 ) THEN
            -- Se qui v_com > 0 vuol dire che esistono comunicati nel passato o per oggi
            v_return_value:=4;
        ELSE     
            select 
                    count(id_comunicato)
                    into v_com
            from 
                    cd_comunicato,
                    cd_schermo,
                    cd_sala,
                    cd_prodotto_acquistato,
                    cd_prodotto_vendita,
                    cd_listino
            where
                    cd_listino.id_listino = p_id_listino
            and     cd_schermo.id_schermo = p_id_schermo                
            and     cd_schermo.id_sala = cd_sala.id_sala
            and     cd_sala.id_sala = cd_comunicato.id_sala
            and     cd_comunicato.flg_annullato = 'N'
            and     cd_comunicato.flg_sospeso = 'N'
            and     cd_comunicato.cod_disattivazione is null
            and     cd_comunicato.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
            and     cd_prodotto_acquistato.flg_annullato = 'N'
            and     cd_prodotto_acquistato.data_inizio between cd_listino.data_inizio and cd_listino.data_fine 
            and     cd_prodotto_acquistato.id_prodotto_vendita  = cd_prodotto_vendita.id_prodotto_vendita
            and     cd_prodotto_vendita.id_circuito = p_id_circuito
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV > TRUNC(SYSDATE)
            and     rownum <= 1;
            IF( v_com > 0 )THEN
                -- Se qui v_com > 0 vuol dire che esistono comunicati solo nel futuro
                v_return_value:=3;
            ELSE
                -- Non esistono ancora sono comunicati, verifico se esistono i prodotti di vendita
                select count(id_tariffa)
                into    v_tar
                from    cd_tariffa,cd_prodotto_vendita
                where 
                        cd_tariffa.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita
                and     cd_prodotto_vendita.id_circuito = p_id_circuito
                and     cd_tariffa.id_listino = p_id_listino
                and     rownum <=1;
                IF(v_tar>0)THEN
                    v_return_value:=2;
                END IF;
            END IF;
            /*A.C.*/
        END IF;
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_SCHERMO_IN_CIRCUITO_LIS_LIB: Impossibile valutare la richiesta '||SQLERRM);
            RETURN -1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SCHERMO_IN_CIRCUITO_LISTINO
--- DESCRIZIONE: da usare per circuiti con modalita' di vendita in modulo
-- INPUT:  ID del listino ID del circuito ID dello schermo
-- OUTPUT:  0 lo schermo (e tutti i suoi componenti) NON appartiene al circuito
--          1 lo schermo (o uno dei suoi componenti) appartiene al circuito ma
--            ne' esso ne' alcuno dei suoi componenti e' in un prodotto vendita
--          2 lo schermo (o uno dei suoi componenti) appartiene al circuito,
--            esso (o almeno uno dei suoi componenti) e' in un prodotto vendita,
--            ma ne' esso ne' alcuno dei suoi componenti e' in un prodotto acquistato
--          3 lo schermo (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--
-- REALIZZATORE:  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE: Francesco Abbundo, Teoresi srl, Ottobre 2009
--             --- ATTENZIONE --- ATTENZIONE --- ATTENZIONE ---
--              Se si vuole modificare questa funzione, effettuare gli stessi
--              nuovi controlli inseriti su FU_SCHERMO_IN_CIRCUITO_LIS_LIB
---            --- ATTENZIONE --- ATTENZIONE --- ATTENZIONE --- 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMO_IN_CIRCUITO_LIS_MOD(p_id_listino  IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                        p_id_circuito IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
                                        p_id_schermo  IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER;
    v_temp1 INTEGER;
BEGIN
    v_return_value  :=0;
    SELECT COUNT(*)
    INTO v_temp1
    FROM CD_CIRCUITO_SCHERMO
    WHERE ID_SCHERMO=p_id_schermo
    AND ID_CIRCUITO = p_id_circuito
    AND ID_LISTINO = p_id_listino
    AND FLG_ANNULLATO='N';
    --se e' all'interno mi domando com'e' il listino
    --prima cerco il venduto
    IF(v_temp1>0)THEN
        v_return_value:=1;--sono almeno nel circuito
        SELECT count(*)
        INTO v_temp1
        FROM  CD_PRODOTTO_VENDITA, CD_TARIFFA,CD_PRODOTTO_ACQUISTATO, CD_LISTINO
        WHERE CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
        AND   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA=CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND   CD_TARIFFA.ID_LISTINO=p_id_listino
        AND   CD_TARIFFA.ID_LISTINO=CD_LISTINO.ID_LISTINO
        AND   CD_TARIFFA.ID_PRODOTTO_VENDITA=CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND   CD_TARIFFA.DATA_INIZIO<=CD_PRODOTTO_ACQUISTATO.DATA_INIZIO
        AND   CD_TARIFFA.DATA_FINE>=CD_PRODOTTO_ACQUISTATO.DATA_FINE
        AND   CD_LISTINO.DATA_FINE >= CD_TARIFFA.DATA_FINE
        AND   CD_LISTINO.DATA_INIZIO<=CD_TARIFFA.DATA_INIZIO
        AND   CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO='N'
        AND   CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
        AND   CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL;
        IF(v_temp1>0)THEN --ho del venduto
            v_return_value:=3;
        ELSE
            --se non c'e' venduto vedo se c'e' un prodotto di vendita associato al circuito
            SELECT COUNT(*)
            INTO v_temp1
            FROM  CD_PRODOTTO_VENDITA, CD_TARIFFA, CD_LISTINO
            WHERE CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
            AND   CD_TARIFFA.ID_LISTINO=p_id_listino
            AND   CD_TARIFFA.ID_LISTINO=CD_LISTINO.ID_LISTINO
            AND   CD_TARIFFA.ID_PRODOTTO_VENDITA=CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND   CD_LISTINO.DATA_FINE >= CD_TARIFFA.DATA_FINE
            AND   CD_LISTINO.DATA_INIZIO<=CD_TARIFFA.DATA_INIZIO
            AND   CD_PRODOTTO_VENDITA.FLG_ANNULLATO='N';
            IF(v_temp1>0)THEN --ho un prodotto di vendita
                v_return_value:=2;
            END IF;
        END IF;
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Function FU_SCHERMO_IN_CIRCUITO_LIS_MOD: Si e'' verificato un errore '||SQLERRM);
        RETURN -1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SCHERMO_IN_CIRCUITO_LISTINO
-- DESCRIZIONE: in base alla modalita' di vendita del circuito invoca la stored procedure opportuna
-- INPUT:  ID del listino ID del circuito ID dello schermo
-- OUTPUT:  VALORI RESTITUITI DALLE STORED PROCEDURE INVOCATE:
--          0 lo schermo (e tutti i suoi componenti) NON appartiene al circuito
--          1 lo schermo (o uno dei suoi componenti) appartiene al circuito ma
--            ne' esso ne' alcuno dei suoi componenti e' in un prodotto vendita
--          2 lo schermo (o uno dei suoi componenti) appartiene al circuito,
--            esso (o almeno uno dei suoi componenti) e' in un prodotto vendita,
--            ma ne' esso ne' alcuno dei suoi componenti e' in un prodotto acquistato
--          3 lo schermo (o uno dei suoi componenti) appartiene al circuito
--            esso (o uno dei suoi componenti) e' in un prodotto vendita,
--            ed esso (o uno dei suoi componenti) e' in un prodotto acquistato
--
--         -1  si e' verificato un errore.
--         -2  ci sono piu' modalita' di vendita associate al circuito
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMO_IN_CIRCUITO_LISTINO(p_id_listino  IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                        p_id_circuito IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
                                        p_id_schermo  IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER;
    v_temp1 INTEGER;
    v_temp2 VARCHAR2(30);
BEGIN
    v_return_value  :=0;
    IF(PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino, p_id_circuito, p_id_schermo)>0)THEN
        v_return_value:=1;
		/**
        SELECT COUNT(DESC_MOD_VENDITA)
        INTO   v_temp1
        FROM   CD_MODALITA_VENDITA
        WHERE  ID_MOD_VENDITA = (SELECT DISTINCT CD_PRODOTTO_VENDITA.ID_MOD_VENDITA
                                FROM   CD_PRODOTTO_VENDITA
                                WHERE  ID_CIRCUITO=p_id_circuito);
        IF(v_temp1>1)THEN
            v_return_value:=-2;
        ELSE
            IF(v_temp1=1)THEN
                SELECT DESC_MOD_VENDITA
                INTO   v_temp2
                FROM   CD_MODALITA_VENDITA
                WHERE ID_MOD_VENDITA = (SELECT DISTINCT CD_PRODOTTO_VENDITA.ID_MOD_VENDITA
                FROM   CD_PRODOTTO_VENDITA
                WHERE  ID_CIRCUITO=p_id_circuito);
                IF(v_temp2='Libera')THEN --libera
                    v_return_value:=PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LIS_LIB(p_id_listino,p_id_circuito,p_id_schermo);
                ELSE  --modulo
                    v_return_value:=PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LIS_MOD(p_id_listino,p_id_circuito,p_id_schermo);
                END IF;
            END IF;
        END IF;*/
		v_return_value:=PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LIS_LIB(p_id_listino,p_id_circuito,p_id_schermo);
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Function FU_SCHERMO_IN_CIRCUITO_LISTINO: Si e'' verificato un errore '||SQLERRM);
        RETURN -1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VENDUTO_ACQUISTATO
-- INPUT:  ID del listino, ID del circuito
-- OUTPUT:  1 il circuito NON e' in un prodotto vendita
--          2 il circuito e' in un prodotto vendita ma NON e' in un prodotto acquistato
--          3 il circuito e' in un prodotto vendita ed e' in un prodotto acquistato
--            e la data inizio del prodotto acquistato e nel futuro
--          4 il circuito e' in un prodotto vendita ed e' in un prodotto acquistato
--            e la data inizio di almeno un prodotto acquistato e minore o uguale ad oggi
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--            Tommaso D'Anna, Teoresi srl, 17 Novembre 2011
--              Aggiunto un quarto stato in relazione ai prodotti acquistati nel passato/futuro
--                  NOTA BENE   --- Il vecchio stato 3 "ROSSO" diviene stato 4
--                              --- Il nuovo stato 3 diviene "ARANCIO"
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VENDUTO_ACQUISTATO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE,
                               p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
            RETURN INTEGER
IS
    v_return_value  INTEGER:=0;
    v_temp1         INTEGER:=0;
BEGIN
    v_return_value:=1;
    SELECT COUNT(*)
    INTO  v_temp1
    FROM  CD_PRODOTTO_VENDITA, CD_TARIFFA--, CD_LISTINO
    WHERE CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
    AND   CD_TARIFFA.ID_LISTINO=p_id_listino
    AND   CD_TARIFFA.ID_PRODOTTO_VENDITA=CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
    --AND   CD_LISTINO.ID_LISTINO=CD_TARIFFA.ID_LISTINO
    --AND   CD_LISTINO.DATA_FINE > SYSDATE
    AND   CD_PRODOTTO_VENDITA.ID_MOD_VENDITA= 2;
    IF( v_temp1 > 0 ) THEN
        v_return_value:=2;
        SELECT COUNT(*)
        INTO  v_temp1
        FROM  CD_PRODOTTO_ACQUISTATO
        WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA IN(
             SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
             FROM   CD_PRODOTTO_VENDITA
             WHERE  CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito
             AND    CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = 2);
        IF( v_temp1 > 0 ) THEN
            -- Se sono qui il circuito e' in un prodotto vendita ed e' 
            -- in un prodotto acquistato
            -- Conto quanti prodotti acquistati hanno come data inizio una data
            -- inferiore o uguale ad oggi per quel circuito
            SELECT COUNT(*)
            INTO  v_temp1
            FROM  CD_PRODOTTO_ACQUISTATO
            WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA IN(
                 SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
                 FROM   CD_PRODOTTO_VENDITA
                 WHERE  CD_PRODOTTO_VENDITA.ID_CIRCUITO     = p_id_circuito
                 AND    CD_PRODOTTO_VENDITA.ID_MOD_VENDITA  = 2)
            AND CD_PRODOTTO_ACQUISTATO.DATA_INIZIO <= TRUNC(SYSDATE);
            IF( v_temp1 > 0 ) THEN
                -- Se sono qui esiste almeno un prodotto acquistato in modulo 
                -- con quel circuito tale che la sua data di inizio e' gia passata
                -- dunque il circuito diventa intoccabile  
                v_return_value:=4;
            ELSE
                -- Se sono qui tutti i un prodotti acquistati in modulo 
                -- con quel circuito hanno una data di inizio futura
                -- dunque il circuito diventa ancora modificabile  
                v_return_value:=3;
            END IF;
        END IF;
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_VENDUTO_ACQUISTATO: Impossibile valutare la richiesta '||SQLERRM);
        RETURN 1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_AMBITI_IN_VENDITA
--
-- INPUT:  ID listino di cui verificare la svuotabilita'
-- OUTPUT:  Restituisce tutti circuiti in vendita o acquistati per ogni ambito attinente al
--          listino che si puo' svuotare se il cursore restituito e' vuoto.
--          In cursore contiene IDCircuito, NomeCircuito, Infovendita

--          Infovendita assume tre valori distinti (se esite) come specificato in FU_VENDUTO_ACQUISTATO
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_AMBITI_IN_VENDITA(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN C_AMBITO_IN_VENDITA
IS
    v_return_value C_AMBITO_IN_VENDITA;
BEGIN
    OPEN v_return_value
        FOR
        SELECT DISTINCT  CD_CIRCUITO_ATRIO.ID_CIRCUITO IDCircuito,
                PA_CD_CIRCUITO.FU_DAMMI_NOME_CIRCUITO(CD_CIRCUITO_ATRIO.ID_CIRCUITO) NomeCircuito,
                PA_CD_LISTINO.FU_VENDUTO_ACQUISTATO(p_id_listino,CD_CIRCUITO_ATRIO.ID_CIRCUITO) InfoVendita
        FROM    CD_CIRCUITO_ATRIO
        JOIN    CD_ATRIO_VENDITA
        ON      CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO=CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
                AND CD_CIRCUITO_ATRIO.ID_LISTINO=p_id_listino
        UNION
        SELECT  DISTINCT CD_CIRCUITO_CINEMA.ID_CIRCUITO IDCircuito,
                PA_CD_CIRCUITO.FU_DAMMI_NOME_CIRCUITO(CD_CIRCUITO_CINEMA.ID_CIRCUITO) NomeCircuito,
                PA_CD_LISTINO.FU_VENDUTO_ACQUISTATO(p_id_listino,CD_CIRCUITO_CINEMA.ID_CIRCUITO) InfoVendita
        FROM    CD_CIRCUITO_CINEMA
        JOIN    CD_CINEMA_VENDITA
        ON      CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA=CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
                AND CD_CIRCUITO_CINEMA.ID_LISTINO=p_id_listino
        UNION
        SELECT  DISTINCT CD_CIRCUITO_SALA.ID_CIRCUITO IDCircuito,
                PA_CD_CIRCUITO.FU_DAMMI_NOME_CIRCUITO(CD_CIRCUITO_SALA.ID_CIRCUITO) NomeCircuito,
                PA_CD_LISTINO.FU_VENDUTO_ACQUISTATO(p_id_listino,CD_CIRCUITO_SALA.ID_CIRCUITO) InfoVendita
        FROM    CD_CIRCUITO_SALA
        JOIN    CD_SALA_VENDITA
        ON      CD_SALA_VENDITA.ID_CIRCUITO_SALA=CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
                AND CD_CIRCUITO_SALA.ID_LISTINO=p_id_listino
        UNION
        SELECT  DISTINCT CD_CIRCUITO_BREAK.ID_CIRCUITO IDCircuito,
                PA_CD_CIRCUITO.FU_DAMMI_NOME_CIRCUITO(CD_CIRCUITO_BREAK.ID_CIRCUITO) NomeCircuito,
                PA_CD_LISTINO.FU_VENDUTO_ACQUISTATO(p_id_listino,CD_CIRCUITO_BREAK.ID_CIRCUITO) InfoVendita
        FROM    CD_CIRCUITO_BREAK
        JOIN    CD_BREAK_VENDITA
        ON      CD_BREAK_VENDITA.ID_CIRCUITO_BREAK=CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
                AND CD_CIRCUITO_BREAK.ID_LISTINO=p_id_listino;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN v_return_value;
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Function FU_AMBITI_IN_VENDITA: Impossibile valutare la richiesta');
END FU_AMBITI_IN_VENDITA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_LISTINO_VUOTO_PIENO
--    Verifica che un listino contenga o meno elementi al fine di dichiararlo vuoto o non vuoto.
--    prima pero' verifica la sua esistenza.
-- INPUT:  ID listino di cui verificare se e' pieno o vuoto
-- OUTPUT:  0 il listino e' vuoto
--          1 il listino non e' vuoto
--          2 il listino non esiste
--         -1 si e' verificato un errore imprevisto
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_LISTINO_VUOTO_PIENO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=1;
    v_temp         INTEGER:=0;
BEGIN
    SELECT COUNT(*)
    INTO   v_temp
    FROM   CD_LISTINO
    WHERE  ID_LISTINO=p_id_listino;
    IF(v_temp>0)THEN
        v_temp:=0;
        SELECT COUNT(*)
        INTO   v_temp
        FROM   CD_CIRCUITO_ATRIO
        WHERE  ID_LISTINO=p_id_listino;
        IF(v_temp=0)THEN
            SELECT COUNT(*)
            INTO   v_temp
            FROM   CD_CIRCUITO_SALA
            WHERE  ID_LISTINO=p_id_listino;
            IF(v_temp=0)THEN
                SELECT COUNT(*)
                INTO   v_temp
                FROM   CD_CIRCUITO_SCHERMO
                WHERE  ID_LISTINO=p_id_listino;
                IF(v_temp=0)THEN
                    SELECT COUNT(*)
                    INTO   v_temp
                    FROM   CD_CIRCUITO_BREAK
                    WHERE  ID_LISTINO=p_id_listino;
                    IF(v_temp=0)THEN
                        SELECT COUNT(*)
                        INTO   v_temp
                        FROM   CD_CIRCUITO_CINEMA
                        WHERE  ID_LISTINO=p_id_listino;
                        IF(v_temp=0)THEN
                            v_return_value:=0;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    ELSE
        v_return_value:=2;
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        v_return_value:=-1;
        RETURN v_return_value;
        RAISE_APPLICATION_ERROR(-20006, 'Function FU_LISTINO_VUOTO_PIENO: Si e'' verificato un errore '||SQLERRM);
END FU_LISTINO_VUOTO_PIENO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_SVUOTA_LISTINO
-- INPUT:  ID listino da vuotare
-- OUTPUT:  Restituisce il numero di elementi eliminati complessivamente ( da zero in su)
--                      -1 in caso di eccezione generica
--                      -10 se il listino non e' svuotabile
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_SVUOTA_LISTINO(p_id_listino    IN CD_LISTINO.ID_LISTINO%TYPE,
                            p_esito            OUT INTEGER)
IS
    v_myCur C_AMBITO_IN_VENDITA;
    v_myRec R_AMBITO_IN_VENDITA;
BEGIN
    p_esito:=0;
    SAVEPOINT SP_PR_SVUOTA_LISTINO;
    v_myCur:=FU_AMBITI_IN_VENDITA(p_id_listino);
    FETCH v_myCur into v_myRec;
    IF(v_myCur%NOTFOUND)THEN
        DELETE FROM CD_CIRCUITO_CINEMA WHERE CD_CIRCUITO_CINEMA.ID_LISTINO=p_id_listino;
        p_esito:= SQL%ROWCOUNT;
        DELETE FROM CD_CIRCUITO_ATRIO WHERE CD_CIRCUITO_ATRIO.ID_LISTINO=p_id_listino;
        p_esito:=p_esito + SQL%ROWCOUNT;
        DELETE FROM CD_CIRCUITO_SALA WHERE CD_CIRCUITO_SALA.ID_LISTINO=p_id_listino;
        p_esito:=p_esito + SQL%ROWCOUNT;
        DELETE FROM CD_CIRCUITO_SCHERMO WHERE CD_CIRCUITO_SCHERMO.ID_LISTINO=p_id_listino;
        p_esito:=p_esito + SQL%ROWCOUNT;
        DELETE FROM CD_CIRCUITO_BREAK WHERE CD_CIRCUITO_BREAK.ID_LISTINO=p_id_listino;
        p_esito:=p_esito + SQL%ROWCOUNT;
    ELSE
        p_esito:=-10;
    END IF;
    CLOSE v_myCur;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_SVUOTA_LISTINO: Impossibile valutare la richiesta'|| sqlerrm);
            ROLLBACK TO SP_PR_SVUOTA_LISTINO;
            p_esito:= -1;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_PREPARA_MODIFICA_COMP
--
--  QUESTA PROCEDURA E' STATA STRALCIATA DALL'ANALISI IL GIORNO VENERDI' 17 LUGLIO 2009
--
-- INPUT:  ID listino da modificare
-- OUTPUT:  Restituisce il numero di elementi eliminati complessivamente ( da zero in su)
--                      -1 in caso di eccezione generica
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_PREPARA_MODIFICA_COMP(p_id_listino IN CD_LISTINO.ID_LISTINO%TYPE,
                                   p_esito        OUT INTEGER)
IS
BEGIN
    SAVEPOINT SP_PR_PREPARA_MODIFICA_COMP;
    DELETE  FROM CD_CIRCUITO_CINEMA  WHERE   CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA IN
        (   SELECT CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA FROM CD_CIRCUITO_CINEMA WHERE CD_CIRCUITO_CINEMA.ID_LISTINO=p_id_listino
            MINUS
            SELECT  CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA FROM    CD_CIRCUITO_CINEMA, CD_CINEMA_VENDITA
            WHERE   CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA=CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
                    AND CD_CIRCUITO_CINEMA.ID_LISTINO=p_id_listino
        );
    p_esito:= SQL%ROWCOUNT;
    DELETE  FROM CD_CIRCUITO_ATRIO  WHERE   CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO IN
        (   SELECT CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO FROM CD_CIRCUITO_ATRIO WHERE CD_CIRCUITO_ATRIO.ID_LISTINO=p_id_listino
            MINUS
            SELECT  CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO FROM    CD_CIRCUITO_ATRIO, CD_ATRIO_VENDITA
            WHERE   CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO=CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
                    AND CD_CIRCUITO_ATRIO.ID_LISTINO=p_id_listino
        );
    p_esito:=p_esito + SQL%ROWCOUNT;
    DELETE  FROM CD_CIRCUITO_SALA  WHERE   CD_CIRCUITO_SALA.ID_CIRCUITO_SALA IN
        (   SELECT CD_CIRCUITO_SALA.ID_CIRCUITO_SALA FROM CD_CIRCUITO_SALA WHERE CD_CIRCUITO_SALA.ID_LISTINO=p_id_listino
            MINUS
            SELECT  CD_CIRCUITO_SALA.ID_CIRCUITO_SALA FROM    CD_CIRCUITO_SALA, CD_SALA_VENDITA
            WHERE   CD_SALA_VENDITA.ID_CIRCUITO_SALA=CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
                    AND CD_CIRCUITO_SALA.ID_LISTINO=p_id_listino
        );
    p_esito:=p_esito + SQL%ROWCOUNT;
    DELETE  FROM CD_CIRCUITO_SCHERMO WHERE CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO IN
        (    SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO FROM CD_CIRCUITO_SCHERMO WHERE CD_CIRCUITO_SCHERMO.ID_LISTINO=p_id_listino
            MINUS
            SELECT  DISTINCT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
            FROM    CD_CIRCUITO_SCHERMO, CD_CIRCUITO_BREAK, CD_BREAK_VENDITA
            WHERE   CD_BREAK_VENDITA.ID_CIRCUITO_BREAK=CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
                    AND CD_CIRCUITO_SCHERMO.ID_CIRCUITO=CD_CIRCUITO_BREAK.ID_CIRCUITO
                    AND CD_CIRCUITO_BREAK.ID_LISTINO=p_id_listino
        );
    p_esito:=p_esito + SQL%ROWCOUNT;
    DELETE  FROM CD_CIRCUITO_BREAK  WHERE   CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK IN
        (   SELECT CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK FROM CD_CIRCUITO_BREAK WHERE CD_CIRCUITO_BREAK.ID_LISTINO=p_id_listino
            MINUS
            SELECT  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK FROM    CD_CIRCUITO_BREAK, CD_BREAK_VENDITA
            WHERE   CD_BREAK_VENDITA.ID_CIRCUITO_BREAK=CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
                    AND CD_CIRCUITO_BREAK.ID_LISTINO=p_id_listino
        );
    p_esito:=p_esito + SQL%ROWCOUNT;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_SVUOTA_LISTINO: Impossibile valutare la richiesta'|| sqlerrm);
            ROLLBACK TO SP_PR_PREPARA_MODIFICA_COMP;
            p_esito:= -1;
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DATA_INIZIO
--    Restituisce la data di inizio del listino
-- INPUT:  ID listino
-- OUTPUT:  Data inizio listino
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DATA_INIZIO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN DATE
IS
    v_return_value DATE;
BEGIN
    SELECT DATA_INIZIO
    INTO   v_return_value
    FROM   CD_LISTINO
    WHERE  ID_LISTINO=p_id_listino;

    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Function FU_DATA_INIZIO: Si e'' verificato un errore '||SQLERRM);
END FU_DATA_INIZIO;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DATA_FINE
--    Restituisce la data di fine del listino
-- INPUT:  ID listino
-- OUTPUT:  Data fine listino
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DATA_FINE(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE)
            RETURN DATE
IS
    v_return_value DATE;
BEGIN
    SELECT DATA_FINE
    INTO   v_return_value
    FROM   CD_LISTINO
    WHERE  ID_LISTINO=p_id_listino;

    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Function FU_DATA_FINE: Si e'' verificato un errore '||SQLERRM);
END FU_DATA_FINE;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_COPIA_COMPONI_CIRCUITO
--
--  Procedura che permette di copiare la composizione degli schermi per un circuito 
--  in un determinato listino in un altro circuito/listino 
--
-- INPUT:  
--      listino_orig    listino da cui copiare 
--      listino_dest    listino di destinazione dove riversare i dati
--      circuito_orig   circuito da cui copiare la composizione degli schermi 
--      circuito_dest   circuito di destinazione dove riversare la composizione degli schermi
-- OUTPUT:  Restituisce il numero di elementi eliminati complessivamente ( da zero in su)
--                      -1 in caso di eccezione generica
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Giugno 2011
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_COPIA_COMPONI_CIRCUITO  (   p_id_listino_orig      IN CD_LISTINO.ID_LISTINO%TYPE,
                                         p_id_listino_dest      IN CD_LISTINO.ID_LISTINO%TYPE,
                                         p_id_circuito_orig     IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_id_circuito_dest     IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         p_esito                OUT NUMBER)
IS
    v_num_proiezioni     CD_SALA.NUMERO_PROIEZIONI%TYPE;
    v_num_giorni         NUMBER;
    v_date_start         CD_LISTINO.DATA_INIZIO%TYPE;
    v_date_end           CD_LISTINO.DATA_FINE%TYPE;
    v_id_fascia          CD_FASCIA.ID_FASCIA%TYPE;
    v_data_proiezione    CD_PROIEZIONE.DATA_PROIEZIONE%TYPE;
    v_id_proiezione      CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
    v_id_break           CD_BREAK.ID_BREAK%TYPE;
    v_esito_ins_break    NUMBER;
    v_esito_comp_break   NUMBER;
    v_list_break         id_break_type;
    v_break_count        NUMBER;
    v_esiste_gia         INTEGER:=0;
    v_id_circ_listino    INTEGER:=-1;
    CURSOR c_tipo_break IS
        SELECT ID_TIPO_BREAK
        FROM   CD_CIRCUITO_TIPO_BREAK
	    WHERE  FLG_ANNULLATO = 'N'
        and    id_circuito = p_id_circuito_dest;
BEGIN
    p_esito := 1;
    v_break_count := 1;
    SAVEPOINT Sp_PR_LISTINO_SCHERMO_CLONA;
    SELECT DATA_INIZIO, DATA_FINE
    INTO   v_date_start, v_date_end
    FROM   CD_LISTINO
    WHERE  ID_LISTINO = p_id_listino_dest;
    v_num_giorni := v_date_end - v_date_start;
    for list_id_schermi in
        (
            select distinct id_schermo
            from cd_circuito_schermo
            where id_listino = p_id_listino_orig
            AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito_orig
            and   flg_annullato = 'N'
        )LOOP
        SELECT COUNT(*)
        INTO  v_esiste_gia
        FROM  CD_CIRCUITO_SCHERMO
        WHERE CD_CIRCUITO_SCHERMO.ID_SCHERMO = list_id_schermi.id_schermo
        AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito_dest
        AND   CD_CIRCUITO_SCHERMO.ID_LISTINO = p_id_listino_dest;
        IF(v_esiste_gia = 0)THEN
            INSERT INTO CD_CIRCUITO_SCHERMO          -- associa gli schermi al listino tramite il circuito
               (ID_SCHERMO, ID_CIRCUITO, ID_LISTINO)
            VALUES
               (list_id_schermi.id_schermo, p_id_circuito_dest, p_id_listino_dest);
            FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni delle date del listino
                FOR id_fascia IN (SELECT ID_FASCIA FROM CD_FASCIA WHERE ID_TIPO_FASCIA IN(
                                        SELECT ID_TIPO_FASCIA FROM CD_TIPO_FASCIA WHERE DESC_TIPO = 'Fascia Proiezioni')) LOOP
                    v_data_proiezione    :=   v_date_start + k ;
                    v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(list_id_schermi.id_schermo,v_data_proiezione,id_fascia.id_fascia);
                    IF(v_id_proiezione != 0)THEN
                        FOR IDP IN(SELECT  ID_PROIEZIONE
                                   FROM    CD_PROIEZIONE
                                   WHERE   CD_PROIEZIONE.ID_SCHERMO      = list_id_schermi.id_schermo
                                   AND     CD_PROIEZIONE.DATA_PROIEZIONE = v_data_proiezione) LOOP
                            v_id_proiezione:=IDP.ID_PROIEZIONE;
                            FOR tipo_break in c_tipo_break LOOP
                                v_id_break := PA_CD_BREAK.FU_ESISTE_BREAK(v_id_proiezione, tipo_break.id_tipo_break);
                                IF(v_id_break > 0) THEN -- esiste
                                    v_list_break(v_break_count)    :=  v_id_break;
                                    v_break_count := v_break_count + 1;
                                END IF;
                            END LOOP tipo_break;
                        END LOOP IDP;
                    END IF;
                END LOOP;
            END LOOP k;
        ELSE
            SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
            INTO   v_id_circ_listino
            FROM   CD_CIRCUITO_SCHERMO
            WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO  = list_id_schermi.id_schermo
            AND    CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito_dest
            AND    CD_CIRCUITO_SCHERMO.ID_LISTINO  = p_id_listino_dest;
            PA_CD_CIRCUITO.PR_RECUPERA_CIRCUITO_SCHERMO(v_id_circ_listino, p_esito);
            IF(p_esito>=0)THEN
                p_esito:=p_esito+10;
            END IF;
        END IF;
        commit;
    END LOOP;
    IF (v_break_count > 1) THEN
        pa_cd_listino.PR_COMPONI_LISTINO_BREAK(p_id_listino_dest, p_id_circuito_dest, v_list_break, v_esito_comp_break);
    END IF;
    commit;
END;

END PA_CD_LISTINO; 
/

