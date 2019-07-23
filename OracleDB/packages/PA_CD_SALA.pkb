CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SALA IS
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_SALA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo sala nel sistema
--
-- OPERAZIONI:
--     1) Controlla se si vuole procedere con inserimento manuale od tramite sequence dell'id_sala
--   2) Nel caso di inserimento manuale controlla che non esistano altri sale con lo stesso id
--   3) Memorizza la sala (CD_SALA)
--
-- INPUT:
--      p_id_cinema                 id del cinema
--      p_id_tipo_audio             id del tipo audio
--      p_nome_sala                 nome della sala
--      p_numero_poltrone           numero delle poltrone
--      p_numero_proiezioni         numero indicativo delle proiezioni giornaliere
--      p_flg_arena                 flag che indica se trattasi di arena o sala classica
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -1  Inserimento non eseguito: esiste gia una sala con questo id
--   -2  Inserimento non eseguito: l'id sala e NULL
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--   -6  Inserimento non eseguito: la data di inizio validita e' inferiore a quella
--       relativa al cinema
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
----           Antonio Colucci, Teoresi srl, 09/09/2009 :
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
--              Tommaso D'Anna, Teoresi srl, 20/01/2011
--                      Inserito valore relativo alla visibilita della sala
--              Tommaso D'Anna, Teoresi srl, 07/07/2011
--                      Inserito valore relativo alla data inizio validita' della sala
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SALA( p_id_cinema                        CD_SALA.ID_CINEMA%TYPE,
                             p_id_tipo_audio                    CD_SALA.ID_TIPO_AUDIO%TYPE,
                             p_nome_sala                        CD_SALA.NOME_SALA%TYPE,
                             p_numero_poltrone                  CD_SALA.NUMERO_POLTRONE%TYPE,
                             p_numero_proiezioni                CD_SALA.NUMERO_PROIEZIONI%TYPE,
                             p_flg_arena                        CD_SALA.FLG_ARENA%TYPE,
                             p_visibile                         CD_SALA.FLG_VISIBILE%TYPE,
                             p_data_inizio_validita             CD_SALA.DATA_INIZIO_VALIDITA%TYPE,                           
                             p_misura_larghezza                 CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                             p_misura_lunghezza                 CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                             p_esito                            OUT NUMBER)
IS

v_id_sala       CD_SALA.ID_SALA%TYPE;
v_sc_esito      NUMBER(3);
v_data_inizio_val_cinema CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE;
--
BEGIN -- PR_INSERISCI_SALA

p_esito     := 1;
--P_ID_SALA := SALA_SEQ.NEXTVAL;
     --
    SAVEPOINT SP_PR_INSERISCI_SALA;
      --
        
    SELECT DATA_INIZIO_VALIDITA
    INTO v_data_inizio_val_cinema
    FROM CD_CINEMA
    WHERE ID_CINEMA = p_id_cinema;

    IF p_data_inizio_validita IS NOT NULL THEN        
        IF p_data_inizio_validita >= v_data_inizio_val_cinema THEN
      
             -- EFFETTUO L'INSERIMENTO
            INSERT INTO CD_SALA
                (
                    ID_CINEMA,
                    ID_TIPO_AUDIO,
                    NOME_SALA,
                    NUMERO_POLTRONE,
                    NUMERO_PROIEZIONI,
                    FLG_ARENA,
                    FLG_VISIBILE,
                    FLG_ANNULLATO,
                    DATA_INIZIO_VALIDITA,
                    UTEMOD,
                    DATAMOD
                )
            VALUES
                (
                    p_id_cinema,
                    p_id_tipo_audio,
                    p_nome_sala,
                    p_numero_poltrone,
                    p_numero_proiezioni,
                    nvl(p_flg_arena,'N'),
                    p_visibile,
                    'N',
                    trunc(p_data_inizio_validita),                
                    user,
                    FU_DATA_ORA
                 );

            SELECT CD_SALA_SEQ.CURRVAL
            INTO v_id_sala
            FROM DUAL;

            PA_CD_SCHERMO.PR_INSERISCI_SCHERMO(null,v_id_sala,null,p_misura_larghezza,p_misura_lunghezza,null,'S',v_sc_esito);
        ELSE
            p_esito := -6;   
        END IF;
    ELSE
        p_esito := -9;
    END IF;

EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20009, 'Procedura PR_INSERISCI_SALA: Insert non eseguita errore:'||sqlerrm);
        ROLLBACK TO SP_PR_INSERISCI_SALA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SALA
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un sala dal sistema
--
-- OPERAZIONI:
--   3) Elimina l'sala
--
-- INPUT: p_id_sala     identificativo della sala
--
-- OUTPUT: esito:
--    n  numero di record eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SALA(  p_id_sala        IN CD_SALA.ID_SALA%TYPE,
                            p_esito          OUT NUMBER)
IS
--
BEGIN -- PR_ELIMINA_SALA
--
   p_esito     := 1;
          SAVEPOINT SP_PR_ELIMINA_SALA;

        -- elimino il circuito sala
        DELETE FROM CD_SALA_VENDITA
        WHERE ID_CIRCUITO_SALA IN
            (SELECT ID_CIRCUITO_SALA FROM CD_CIRCUITO_SALA
             WHERE ID_SALA = p_id_sala);

        DELETE FROM CD_CIRCUITO_SALA
        WHERE ID_SALA = p_id_sala;

        -- qui elimino gli schermi e le proiezioni associate
          PA_CD_SCHERMO.PR_ELIMINA_SCHERMO_SALA(p_id_sala,p_esito);

       -- EFFETTUA L'ELIMINAZIONE
       DELETE FROM CD_SALA
       WHERE ID_SALA = p_id_sala;
       --
       p_esito := SQL%ROWCOUNT;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Procedura PR_ELIMINA_SALA: Delete non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_ELIMINA_SALA;
  END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SALA_CINEMA
--
-- DESCRIZIONE:  Esegue l'eliminazione delle sale e degli schermi associati al cinema
--
-- OPERAZIONI:
--   1) Elimina le sale
--
-- OUTPUT: esito:
--    n  numero di record eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SALA_CINEMA(    p_id_cinema        IN CD_CINEMA.ID_CINEMA%TYPE,
                                    p_esito            OUT NUMBER)
IS
CURSOR c_sale IS
        SELECT  ID_SALA FROM CD_SALA
        WHERE id_cinema = p_id_cinema;
--
BEGIN -- PR_ELIMINA_SALA_CINEMA
--
p_esito     := 1;
          SAVEPOINT SP_PR_ELIMINA_SALA_CINEMA;
        FOR sala in c_sale LOOP
             PR_ELIMINA_SALA(sala.ID_SALA,p_esito);
        END LOOP;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_ELIMINA_SALA: Delete non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_ELIMINA_SALA_CINEMA;
  END;
-- ---------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_SALA
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di una sala
--                  degli schermi, dei relativi circuiti
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- OPERAZIONI:
--   1) Cancella logicamente sala, schermi, circuiti_ambiti
--      ambiti_vendita, comunicati, prodotti
-- INPUT:  Id della sala da annullare
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_SALA(p_id_sala        IN CD_SALA.ID_SALA%TYPE,
                          p_esito          OUT NUMBER,
                          p_piani_errati   OUT VARCHAR2)
IS
    v_esito     NUMBER:=0;
    v_esito_tar NUMBER:=0;
BEGIN
    p_esito     := 0;
    --SEZIONE SCHERMI E BREAK
    FOR TEMP IN(SELECT DISTINCT CD_SCHERMO.ID_SCHERMO
                FROM  CD_SCHERMO
                WHERE CD_SCHERMO.ID_SALA = p_id_sala
                AND CD_SCHERMO.FLG_ANNULLATO<>'S')LOOP
        PA_CD_SCHERMO.PR_ANNULLA_SCHERMO(TEMP.ID_SCHERMO, v_esito, p_piani_errati);
        p_esito:=p_esito+v_esito;
    END LOOP;
    --SEZIONE SALE
     FOR TEMP IN(SELECT ID_COMUNICATO
                FROM CD_COMUNICATO
                WHERE  CD_COMUNICATO.ID_SALA_VENDITA IN(
                   SELECT DISTINCT CD_SALA_VENDITA.ID_SALA_VENDITA
                   FROM CD_SALA_VENDITA
                   WHERE CD_SALA_VENDITA.ID_CIRCUITO_SALA IN(
                      SELECT DISTINCT CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
                      FROM  CD_CIRCUITO_SALA
                      WHERE CD_CIRCUITO_SALA.ID_SALA = p_id_sala
                      AND  CD_CIRCUITO_SALA.ID_LISTINO IN(
                         SELECT DISTINCT CD_LISTINO.ID_LISTINO
                         FROM  CD_LISTINO
                         WHERE CD_LISTINO.DATA_FINE > SYSDATE)
                AND CD_CIRCUITO_SALA.FLG_ANNULLATO<>'S'))
                AND CD_COMUNICATO.FLG_ANNULLATO<>'S'
                AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL) LOOP
        PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(TEMP.ID_COMUNICATO, 'PAL',v_esito,p_piani_errati);
        IF((v_esito=5) OR (v_esito=15) OR (v_esito=25)) THEN
            p_esito := p_esito + 1;
        END IF;
    END LOOP;
    --qui recupero le sale di vednita
    UPDATE  CD_SALA_VENDITA
    SET FLG_ANNULLATO='S'
    WHERE  CD_SALA_VENDITA.ID_CIRCUITO_SALA IN(
       SELECT DISTINCT CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
       FROM  CD_CIRCUITO_SALA
       WHERE CD_CIRCUITO_SALA.ID_SALA = p_id_sala
       AND  CD_CIRCUITO_SALA.ID_LISTINO IN(
          SELECT DISTINCT CD_LISTINO.ID_LISTINO
          FROM  CD_LISTINO
          WHERE CD_LISTINO.DATA_FINE > SYSDATE)
       AND CD_CIRCUITO_SALA.FLG_ANNULLATO<>'S')
    AND CD_SALA_VENDITA.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti sala
    UPDATE  CD_CIRCUITO_SALA
    SET FLG_ANNULLATO='S'
    WHERE CD_CIRCUITO_SALA.ID_SALA = p_id_sala
    AND  CD_CIRCUITO_SALA.ID_LISTINO IN(
       SELECT DISTINCT CD_LISTINO.ID_LISTINO
       FROM  CD_LISTINO
       WHERE CD_LISTINO.DATA_FINE > SYSDATE)
    AND CD_CIRCUITO_SALA.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --infine le sale
    UPDATE  CD_SALA
    SET FLG_ANNULLATO='S'
    WHERE CD_SALA.ID_SALA = p_id_sala
    AND   CD_SALA.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    
    FOR LISTINO IN (SELECT DISTINCT CD_LISTINO.ID_LISTINO
       FROM  CD_LISTINO
       WHERE CD_LISTINO.DATA_FINE > SYSDATE)LOOP
        PA_CD_TARIFFA.PR_ALLINEA_TARIFFA_PER_ELIM(p_id_sala, null, null, LISTINO.ID_LISTINO, v_esito_tar, p_piani_errati);
    END LOOP;
 EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Procedura PR_ANNULLA_SALA: Eliminazione logica non eseguita: si e'' verificato un errore inatteso '||SQLERRM);
        p_esito := -1;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_SALE
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di una lista di sale
--               Per maggiori dettagli guardare la documentaione di
--               PA_CD_SALA.PR_ANNULLA_SALA
-- INPUT: Lista di Id delle sale
-- OUTPUT: esito:
--    n  numero delle sale annullate (che dovrebbe coincidere con p_lista_sale.COUNT)
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_SALE(p_lista_sale       IN id_sale_type,
                                p_esito               OUT NUMBER,
                                p_piani_errati   OUT VARCHAR2)
IS
    v_temp  INTEGER:=0;
BEGIN
    SAVEPOINT SP_PR_ANNULLA_LISTA_SALE;
    p_esito:=0;
    FOR i IN 1..p_lista_sale.COUNT LOOP
        PA_CD_SALA.PR_ANNULLA_SALA(p_lista_sale(i),v_temp, p_piani_errati);
        IF(v_temp>=0)THEN
            p_esito:=p_esito+1;
        ELSE
            p_esito:=p_esito-1;
        END IF;
    END LOOP;
EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Procedura PR_ANNULLA_LISTA_SALE: Eliminazione logica non eseguita: si e'' verificato un errore inatteso '||SQLERRM);
        p_esito := -1;
        ROLLBACK TO SP_PR_ANNULLA_LISTA_SALE;
END;
-- ---------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_SALA
--
-- DESCRIZIONE:  Esegue il recupero da cancellazione logioca di una sala
--                  degli schermi, dei relativi circuiti
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- OPERAZIONI:
--   1) Recupera logicamente sala, schermi, circuiti_ambiti
--      ambiti_vendita, comunicati
-- INPUT:  Id della sala da recuperare
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Recupero non eseguito: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--  Antonio Colucci, Teoresi srl, 09/09/2009 :
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_SALA(p_id_sala        IN CD_SALA.ID_SALA%TYPE,
                           p_esito          OUT NUMBER)
IS
    v_esito     NUMBER:=0;
BEGIN
    p_esito     := 0;
    SAVEPOINT SP_PR_RECUPERA_SALA;
    --SEZIONE SCHERMI E BREAK
    -- manca il recupero eventuale dei comunicati
    FOR TEMP IN(SELECT DISTINCT CD_SCHERMO.ID_SCHERMO
                FROM  CD_SCHERMO
                WHERE CD_SCHERMO.ID_SALA = p_id_sala
                AND CD_SCHERMO.FLG_ANNULLATO='S')LOOP
        PA_CD_SCHERMO.PR_RECUPERA_SCHERMO(TEMP.ID_SCHERMO, v_esito);
        p_esito:=p_esito+v_esito;
    END LOOP;
    --SEZIONE SALE
    -- manca il recupero eventuale dei comunicati
    --qui recupero le sale di vednita
    UPDATE  CD_SALA_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE  CD_SALA_VENDITA.ID_CIRCUITO_SALA IN(
       SELECT DISTINCT CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
       FROM  CD_CIRCUITO_SALA
       WHERE CD_CIRCUITO_SALA.ID_SALA = p_id_sala
       AND  CD_CIRCUITO_SALA.ID_LISTINO IN(
          SELECT DISTINCT CD_LISTINO.ID_LISTINO
          FROM  CD_LISTINO
          WHERE CD_LISTINO.DATA_FINE > SYSDATE)
       AND CD_CIRCUITO_SALA.FLG_ANNULLATO='S')
    AND CD_SALA_VENDITA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti sala
    UPDATE  CD_CIRCUITO_SALA
    SET FLG_ANNULLATO='N'
    WHERE CD_CIRCUITO_SALA.ID_SALA = p_id_sala
    AND  CD_CIRCUITO_SALA.ID_LISTINO IN(
       SELECT DISTINCT CD_LISTINO.ID_LISTINO
       FROM  CD_LISTINO
       WHERE CD_LISTINO.DATA_FINE > SYSDATE)
    AND CD_CIRCUITO_SALA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --infine le sale
    UPDATE  CD_SALA
    SET FLG_ANNULLATO='N'
    WHERE CD_SALA.ID_SALA = p_id_sala
    AND   CD_SALA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
 EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Procedura PR_RECUPERA_SALA: Recupero non eseguito: si e'' verificato un errore inatteso');
        p_esito := -1;
        ROLLBACK TO SP_PR_RECUPERA_SALA;
END;
-- Procedura PR_MODIFICA_SALA
--
-- DESCRIZIONE:  Esegue l'aggiornamento di una sala nel sistema
--
-- OPERAZIONI:
--   Update
-- INPUT:
--      p_id_cinema                 id del cinema
--      p_id_tipo_audio             id del tipo audio
--      p_nome_sala                 nome della sala
--      p_numero_poltrone           numero delle poltrone
--      p_numero_proiezioni         numero indicativo delle proiezioni giornaliere
--      p_flg_arena                 flag che indica se trattasi di arena o sala classica
--      p_flg_annullato             flag che indica se la sala e valida
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Update non eseguita: i parametri per l'Update non sono coerenti
--   -6  Update non eseguita: data inizio validita inferiore a quella della validita' del cinema
--   -7  Update non eseguita: data fine validita inferiore a quella della validita' del cinema
--   -8  Update non eseguita: inferiore a quella di inizio validita' della sala
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--  Antonio Colucci, Teoresi srl, 09/09/2009 :
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
--
--  Tommaso D'Anna, Teoresi srl, 21/01/2011
--              Inserita modifica visibilita sala
--  Tommaso D'Anna, Teoresi srl, 26/04/2011
--              Inserita data fine validita
--  Tommaso D'Anna, Teoresi srl, 07/07/2011
--              Inserito valore relativo alla data inizio validita' della sala
PROCEDURE PR_MODIFICA_SALA(  p_id_sala                          CD_SALA.ID_SALA%TYPE,
                             p_id_cinema                        CD_SALA.ID_CINEMA%TYPE,
                             p_id_tipo_audio                    CD_SALA.ID_TIPO_AUDIO%TYPE,
                             p_nome_sala                        CD_SALA.NOME_SALA%TYPE,
                             p_numero_poltrone                  CD_SALA.NUMERO_POLTRONE%TYPE,
                             p_numero_proiezioni                CD_SALA.NUMERO_PROIEZIONI%TYPE,
                             p_flg_arena                        CD_SALA.FLG_ARENA%TYPE,
                             p_flg_annullato                    CD_SALA.FLG_ANNULLATO%TYPE,
                             p_visibile                         CD_SALA.FLG_VISIBILE%TYPE,
                             p_data_inizio_validita             CD_SALA.DATA_INIZIO_VALIDITA%TYPE,
                             p_data_fine_validita               CD_SALA.DATA_FINE_VALIDITA%TYPE,
                             p_id_schermo                       CD_SCHERMO.ID_SCHERMO%TYPE,
                             p_flg_sc_annullato                 CD_SCHERMO.FLG_ANNULLATO%TYPE,
                             p_misura_larghezza                 CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                             p_misura_lunghezza                 CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                             p_misura_pollici                   CD_SCHERMO.MISURA_POLLICI%TYPE,
                             p_esito                            OUT NUMBER)

IS
v_data_inizio_val_cinema CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE;
--
BEGIN -- PR_MODIFICHE_SALA
--
    p_esito := 1;
    SAVEPOINT SP_PR_MODIFICHE_SALA;
    
    SELECT DATA_INIZIO_VALIDITA
    INTO v_data_inizio_val_cinema
    FROM CD_CINEMA
    WHERE ID_CINEMA = p_id_cinema;
    
    IF p_data_inizio_validita IS NOT NULL THEN
        IF p_data_inizio_validita >= v_data_inizio_val_cinema THEN
            IF ( 
                ( p_data_fine_validita >= p_data_inizio_validita )
                    OR
                ( p_data_fine_validita IS NULL )
               )
            THEN    
                -- EFFETTUA L'UPDATE
                UPDATE CD_SALA
                SET
                    ID_CINEMA = (nvl(p_id_cinema,ID_CINEMA)),
                    ID_TIPO_AUDIO = (nvl(p_id_tipo_audio,ID_TIPO_AUDIO)),
                    NOME_SALA = (nvl(p_nome_sala,NOME_SALA)),
                    NUMERO_POLTRONE = (nvl(p_numero_poltrone,NUMERO_POLTRONE)),
                    NUMERO_PROIEZIONI = (nvl(p_numero_proiezioni,NUMERO_PROIEZIONI)),
                    FLG_ARENA = (nvl(p_flg_arena,FLG_ARENA)),
                    FLG_ANNULLATO = (nvl(p_flg_annullato,FLG_ANNULLATO)),
                    FLG_VISIBILE = (nvl(p_visibile,FLG_VISIBILE)),
                    DATA_INIZIO_VALIDITA = (nvl(p_data_inizio_validita,DATA_INIZIO_VALIDITA))
                WHERE ID_SALA = p_id_sala;
                   --
                p_esito := SQL%ROWCOUNT;
        
                IF p_esito > 0 THEN
                    IF (
                        ( p_data_fine_validita >= v_data_inizio_val_cinema )
                            OR
                        ( p_data_fine_validita IS NULL ) 
                        )THEN            
                        PR_FINE_VALIDITA_SALA( p_id_sala, p_data_fine_validita, p_esito );
                    ELSE
                        p_esito := -7;
                    END IF;
                END IF;
        
                UPDATE CD_SCHERMO
                SET
                   FLG_ANNULLATO = (nvl(p_flg_sc_annullato,FLG_ANNULLATO)),
                   MISURA_LARGHEZZA = (nvl(p_misura_larghezza,MISURA_LARGHEZZA)),
                   MISURA_LUNGHEZZA = (nvl(p_misura_lunghezza,MISURA_LUNGHEZZA)),
                   MISURA_POLLICI = (nvl(p_misura_pollici,MISURA_POLLICI))
                WHERE ID_SCHERMO = p_id_schermo;
            ELSE
                p_esito := -8;  
            END IF;
        ELSE
            p_esito := -7;    
        END IF;
    ELSE
        p_esito := -9;
    END IF;
    
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Procedura PR_MODIFICA_SALA: Update non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_MODIFICHE_SALA;
  END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_SALA
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id della sala
-- OUTPUT: Restituisce il dettaglio della sala e del relativo schermo associato
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--  Antonio Colucci, Teoresi srl, 09/09/2009 :
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
--  Antonio Colucci, Teoresi srl, 28/09/2009:
--              Aggiunta informazione ID_CINEMA,NOME_CINEMA  in REF_CUR di ritorno
--  Tommaso D'Anna, Teoresi srl, 20/01/2011
--              Aggiunta informazione FLG_VISIBILE in REF_CUR di ritorno
--  Tommaso D'Anna, Teoresi srl, 07/07/2011
--              Inserito valore relativo alla data inizio validita' della sala
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_SALA ( p_id_sala      CD_SALA.ID_SALA%TYPE )
                             RETURN C_DETTAGLIO_SALE_SCHERMI
IS
c_sala_dettaglio_return C_DETTAGLIO_SALE_SCHERMI;
BEGIN
OPEN c_sala_dettaglio_return  -- apre il cursore che conterra il dettaglio del cinema
     FOR
        SELECT  SALA.ID_SALA, TIPO_AUDIO.ID_TIPO_AUDIO, DESC_TIPO_AUDIO,
                CINEMA.ID_CINEMA, NOME_CINEMA, NOME_SALA,
                NUMERO_POLTRONE, NUMERO_PROIEZIONI,
                FLG_ARENA, ID_SCHERMO,
                MISURA_LARGHEZZA, MISURA_LUNGHEZZA, FLG_VISIBILE, 
                SALA.DATA_INIZIO_VALIDITA, SALA.DATA_FINE_VALIDITA,
                CINEMA.DATA_INIZIO_VALIDITA AS DATA_INIZIO_VALIDITA_CINEMA
        FROM    CD_CINEMA CINEMA, CD_SALA SALA, CD_SCHERMO SCHERMO,
                CD_TIPO_AUDIO TIPO_AUDIO
        WHERE   SALA.ID_SALA                =   SCHERMO.ID_SALA(+)
        AND     TIPO_AUDIO.ID_TIPO_AUDIO    =   SALA.ID_TIPO_AUDIO
        AND     SALA.ID_SALA                =   p_id_sala
        AND     SALA.ID_CINEMA              =   CINEMA.ID_CINEMA;
RETURN c_sala_dettaglio_return;
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'FUNZIONE FU_DETTAGLIO_SALA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_DETTAGLIO_SALA;
  -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_SALA
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
--  Antonio Colucci, Teoresi srl, 09/09/2009 :
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SALA(p_id_cinema                        CD_SALA.ID_CINEMA%TYPE,
                        p_id_tipo_audio                    CD_SALA.ID_TIPO_AUDIO%TYPE,
                        p_nome_sala                        CD_SALA.NOME_SALA%TYPE,
                        p_numero_poltrone                  CD_SALA.NUMERO_POLTRONE%TYPE,
                        p_numero_proiezioni                CD_SALA.NUMERO_PROIEZIONI%TYPE,
                        p_flg_arena                       CD_SALA.FLG_ARENA%TYPE
                        )  RETURN VARCHAR2
IS
BEGIN
IF v_stampa_sala = 'ON'
  THEN
     RETURN 'ID_CINEMA: '          || p_id_cinema           || ', ' ||
            'ID_TIPO_AUDIO: '          || p_id_tipo_audio            || ', ' ||
            'NOME_SALA: '|| p_nome_sala    || ', ' ||
            'NUMERO_POLTRONE: ' || p_numero_poltrone        || ', ' ||
            'NUMERO_PROIEZIONI: '           || p_numero_proiezioni                || ', ' ||
            'FLG_ARENA: '          || p_flg_arena;
END IF;
END  FU_STAMPA_SALA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_SALA
-- INPUT:  ID della sala di cui si vuole il nome
-- OUTPUT:  il nome della sala

-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_SALA(p_id_sala   IN CD_SALA.ID_SALA%TYPE)
            RETURN VARCHAR2
IS
    v_return_value CD_SALA.NOME_SALA%TYPE:='--';
BEGIN
    IF (p_id_sala IS NOT NULL) THEN
        SELECT CD_SALA.NOME_SALA
        INTO v_return_value
        FROM CD_SALA
        WHERE CD_SALA.ID_SALA=p_id_sala;
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '--';
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20009, 'Function FU_DAMMI_NOME_SALA: Impossibile valutare la richiesta');
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_DESC_AUDIO
-- INPUT:  ID del tipo audio di cui si vuole la descrizione
-- OUTPUT:  la descrizione dell'audio

-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_DESC_TIPO_AUDIO(p_id_tipo_audio   IN CD_TIPO_AUDIO.ID_TIPO_AUDIO%TYPE)
            RETURN VARCHAR2
IS
    v_return_value CD_TIPO_AUDIO.DESC_TIPO_AUDIO%TYPE:='--';
BEGIN
    IF (p_id_tipo_audio IS NOT NULL) THEN
        SELECT CD_TIPO_AUDIO.DESC_TIPO_AUDIO
        INTO v_return_value
        FROM CD_TIPO_AUDIO
        WHERE CD_TIPO_AUDIO.ID_TIPO_AUDIO=p_id_tipo_audio;
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '--';
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20009, 'Function FU_DAMMI_DESC_TIPO_AUDIO: Impossibile valutare la richiesta');
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_TIPO_AUDIO
-- DESCRIZIONE:  la funzione si occupa di estrarre i tipi audio
--               che rispondono ai criteri di ricerca
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_TIPO_AUDIO RETURN C_TIPO_AUDIO
IS
   c_tipo_audio_return C_TIPO_AUDIO;
BEGIN
   OPEN c_tipo_audio_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR
        SELECT  ID_TIPO_AUDIO, DESC_TIPO_AUDIO
        FROM    CD_TIPO_AUDIO;
RETURN c_tipo_audio_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'FUNZIONE FU_RICERCA_TIPO_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_RICERCA_TIPO_AUDIO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_SALA
-- INPUT:  ID della Sala della quale si vuole lo stato
-- OUTPUT:  0   la sala NON appartiene a nessun circuito/lisitno
--          1   la sala appartiene a qualche circuito/lisitno ma NON e' in un prodotto vendita
--          2   la sala appartiene a qualche circuito/lisitno, e' in un prodotto vendita,
--                                      ma NON e' in un prodotto acquistato
--          3   la sala appartiene a qualche circuito/lisitno e' in un prodotto vendita,
--                                      ed e' in un prodotto acquistato
--          -10 la sala non esiste
--          -1  si e' verificato un errore
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_SALA (p_id_sala   IN CD_SALA.ID_SALA%TYPE)
            RETURN INTEGER
IS
    v_return_value  INTEGER;
    v_stato         INTEGER;
    v_id_listino    INTEGER;
    v_id_circuito   INTEGER;
BEGIN
    v_return_value:=-10;
    IF(p_id_sala>0)THEN
        v_id_listino:=-10;
          v_id_circuito:=-10;
          v_return_value:=-10; --valore di comodo per la ricerca del max
          v_stato:=-10;
        FOR L1 in (select DISTINCT CD_LISTINO.ID_LISTINO FROM CD_LISTINO) LOOP
            FOR C1 in (select DISTINCT CD_CIRCUITO.ID_CIRCUITO FROM CD_CIRCUITO) LOOP
                v_stato:=PA_CD_LISTINO.FU_SALA_IN_CIRCUITO_LISTINO(L1.ID_LISTINO, C1.ID_CIRCUITO, p_id_sala);
                IF(v_stato>v_return_value)THEN
                    v_return_value:=v_stato;
                    v_id_listino:=L1.ID_LISTINO;
                    v_id_circuito:=C1.ID_CIRCUITO;
                END IF;
                EXIT WHEN(v_return_value=3);
            END LOOP;
        EXIT WHEN(v_return_value=3);
        END LOOP;
   END IF;
    RETURN v_return_value;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20009, 'Function FU_DAMMI_NOME_SALA: Impossibile valutare la richiesta');
        v_return_value:=-1;
        RETURN v_return_value;
END;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_NUM_SALE_CIRCUITO
-- Restituisce il numero di sale che appartiene ad un circuito
-- INPUT:  Id del circuito per il quale si vuole fare la ricerca
-- OUTPUT:  Numero delle sale trovate
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_NUM_SALE_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER IS
v_num_sale NUMBER;
BEGIN
    SELECT COUNT(DISTINCT CD_SALA.ID_SALA)
     INTO v_num_sale
    FROM
    CD_SALA, CD_SCHERMO, CD_PROIEZIONE, CD_BREAK, CD_CIRCUITO_BREAK, CD_CIRCUITO
    WHERE CD_CIRCUITO.ID_CIRCUITO = p_id_circuito
    AND CD_CIRCUITO_BREAK.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
    AND CD_BREAK.ID_BREAK = CD_CIRCUITO_BREAK.ID_BREAK
    AND CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
    AND CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
    AND CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA;
    RETURN v_num_sale;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_GET_NUM_SALE_CIRCUITO: Impossibile valutare la richiesta');

END FU_GET_NUM_SALE_CIRCUITO;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SALA_VENDUTA
--
--  La funzione restituisce il numero di comunicati associati alla sala
--
-- INPUT:  ID della sala
-- OUTPUT:  n numero dei comunicati associati alla sala
--          -1 si e' verificato un errore
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALA_VENDUTA(p_id_sala  IN CD_SALA.ID_SALA%TYPE)
                             RETURN INTEGER
IS
    v_return_value_sala             INTEGER:=0;
    v_return_value_schermo_sala     INTEGER:=0;
    v_return_value                  INTEGER:=0;

BEGIN

     -- qui controlla se ci sono circuiti sala venduti
     FOR CIRC_SALA IN(
                    SELECT DISTINCT(ID_CIRCUITO) FROM CD_CIRCUITO_SALA
                    WHERE ID_SALA = p_id_sala)
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_sala := PA_CD_CIRCUITO.FU_CIRCUITO_VENDUTO(CIRC_SALA.ID_CIRCUITO);
            v_return_value := v_return_value + v_return_value_sala + v_return_value_schermo_sala;
        END LOOP;

    -- qui controlla se ci sono circuiti schermo di sala venduti
    FOR CIRC_PROIEZIONE_SALA IN(
                    SELECT DISTINCT(ID_PROIEZIONE) FROM CD_PROIEZIONE
                    WHERE ID_SCHERMO IN
                        (SELECT ID_SCHERMO FROM CD_SCHERMO
                         WHERE ID_SALA = p_id_sala))
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_schermo_sala := PA_CD_PROIEZIONE.FU_PROIEZIONE_VENDUTA(CIRC_PROIEZIONE_SALA.ID_PROIEZIONE);
            v_return_value := v_return_value + v_return_value_sala + v_return_value_schermo_sala;
        END LOOP;

    RETURN v_return_value;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_SALA_VENDUTA: Impossibile valutare la richiesta '||sqlerrm);
            v_return_value:=-1;
            RETURN v_return_value;
END FU_SALA_VENDUTA;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_FINE_VALIDITA_SALA
--
-- INPUT:   p_id_sala           ID della sala di riferimento
--          p_data_fine_val     La data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--          1 - E' stata validata/invalidata solo la sala
--          2 - E' stato invalidato anche il cinema; la sala invalidata era l'ultima valida
--          3 - Si e' rivalidato il cinema a seguito della rivalutazione di una sala
--         -1 - Si e' verificato un errore
--         -8 - Data fine validita inferiore a quella di inizio validita' della sala                 
--
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 29 Aprile 2011
--              Tommaso D'Anna, Teoresi srl, 07/07/2011
--                  Inserito valore relativo alla data inizio validita' della sala
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_FINE_VALIDITA_SALA(    p_id_sala           CD_SALA.ID_SALA%TYPE,
                                    p_data_fine_val     CD_SALA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER)
IS
    v_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE;
    v_sale_valide_num           NUMBER;
    v_data_validita             CD_CINEMA.DATA_FINE_VALIDITA%TYPE;
    v_data_inizio_val           CD_SALA.DATA_INIZIO_VALIDITA%TYPE;    
BEGIN
    SAVEPOINT SP_PR_FINE_VALIDITA_SALA;
    
    SELECT trunc(DATA_INIZIO_VALIDITA)
    INTO v_data_inizio_val
    FROM CD_SALA
    WHERE ID_SALA = p_id_sala;
    
    IF ( 
        ( p_data_fine_val >= v_data_inizio_val )
            OR
        ( p_data_fine_val IS NULL )
       )
    THEN    
        -- EFFETTUA L'UPDATE DELLA SALA
        UPDATE CD_SALA
        SET
           DATA_FINE_VALIDITA = p_data_fine_val
        WHERE ID_SALA = p_id_sala;
    
        -- SE LA SALA NON E' PIU' VALIDA ED E' L'ULTIMA, ANNULLO LA VALIDITA ANCHE AL CINEMA
        -- SE INVECE IL CINEMA ERA ANNULLATO E ORA LA SALA NON LO E' PIU', LO RIVALIDO
        SELECT ID_CINEMA
        INTO v_id_cinema
        FROM CD_SALA
        WHERE ID_SALA = p_id_sala;
    
        SELECT COUNT(1)
        INTO v_sale_valide_num
        FROM CD_SALA
        WHERE DATA_FINE_VALIDITA IS NULL
        AND ID_CINEMA = v_id_cinema;  
    
        IF
             v_sale_valide_num = 0
        THEN
            --ANNULLO ANCHE IL CINEMA
            SELECT MAX( DATA_FINE_VALIDITA )
            INTO v_data_validita
            FROM CD_SALA
            WHERE ID_CINEMA = v_id_cinema;        
        
            PA_CD_CINEMA.PR_FINE_VALIDITA_CINEMA( v_id_cinema, v_data_validita, p_esito );
        
            p_esito := 2;
        ELSE
            SELECT DATA_FINE_VALIDITA
            INTO v_data_validita
            FROM CD_CINEMA
            WHERE ID_CINEMA = v_id_cinema;
        
            IF ( v_data_validita IS NOT NULL AND p_data_fine_val IS NULL )THEN
                --SI E' RIVALIDATO IL CINEMA
                PA_CD_ESERCENTE.PR_ANNULLA_RISOL_CONTR( v_id_cinema, v_data_validita, p_esito); 
            
                UPDATE CD_CINEMA
                SET
                   DATA_FINE_VALIDITA = null
                WHERE ID_CINEMA = v_id_cinema;
            
                p_esito := 3;
            ELSE
                --LA MODIFICA RIGUARDA SOLO LA SALA
                p_esito := 1;        
            END IF;                           
        END IF;
    ELSE
        p_esito := -8;  
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'Procedura PR_FINE_VALIDITA_SALA: Update non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_FINE_VALIDITA_SALA;
END;

END PA_CD_SALA; 
/

