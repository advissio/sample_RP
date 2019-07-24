CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_ATRIO IS
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_ATRIO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo atrio nel sistema
--
-- OPERAZIONI:
--     1) Controlla se si vuole procedere con inserimento manuale od tramite sequence dell'id_atrio
--   2) Nel caso di inserimento manuale controlla che non esistano altri atrii con lo stesso id
--   3) Memorizza l'atrio (CD_ATRIO)
--
-- INPUT:
--      p_desc_atrio            descrizione dell'atrio
--      p_id_cinema             id del cinema
--      p_num_distribuzioni     numero dei punti di distribuzione
--      p_num_esposizioni       numero delle aree di esposizione
--      p_num_scooter_moto      numero di posti scooter/moto
--      p_num_corner            numero dei corner
--      p_num_lcd               numero degli schermi LCD
--      p_num_automobili        numero di posti auto
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -1  Inserimento non eseguito: esiste gia un atrio con questo id
--   -2  Inserimento non eseguito: l'id atrio e NULL
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_ATRIO( p_desc_atrio              CD_ATRIO.DESC_ATRIO%TYPE,
                              p_id_cinema               CD_ATRIO.ID_CINEMA%TYPE,
                              p_num_distribuzioni       CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
                              p_num_esposizioni         CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
                              p_num_scooter_moto        CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
                              p_num_corner              CD_ATRIO.NUM_CORNER%TYPE,
                              p_num_lcd                 CD_ATRIO.NUM_LCD%TYPE,
                              p_num_automobili          CD_ATRIO.NUM_AUTOMOBILI%TYPE,
                              p_esito                    OUT NUMBER)
IS
--
v_vix   varchar2(10);

BEGIN -- PR_INSERISCI_ATRIO
   p_esito     := 1;
--P_ID_ATRIO := ATRIO_SEQ.NEXTVAL;
     --
          SAVEPOINT SP_PR_INSERISCI_ATRIO;
       -- EFFETTUO L'INSERIMENTO
       INSERT INTO CD_ATRIO
         (DESC_ATRIO,
          ID_CINEMA,
          NUM_DISTRIBUZIONI,
          NUM_ESPOSIZIONI,
          NUM_SCOOTER_MOTO,
          NUM_CORNER,
          NUM_LCD,
          NUM_AUTOMOBILI,
          FLG_ANNULLATO,
          UTEMOD,
          DATAMOD
         )
       VALUES
         (p_desc_atrio,
          p_id_cinema,
          p_num_distribuzioni,
          p_num_esposizioni,
          p_num_scooter_moto,
          p_num_corner,
          p_num_lcd,
          p_num_automobili,
          'N',
          user,
          FU_DATA_ORA
          );
       --
  EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
            WHEN OTHERS THEN
        P_ESITO := -11;
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_INSERISCI_ATRIO: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_ATRIO(  p_desc_atrio,
                                                                                                                                                      p_id_cinema,
                                                                                                                                                      p_num_distribuzioni,
                                                                                                                                                      p_num_esposizioni,
                                                                                                                                                      p_num_scooter_moto,
                                                                                                                                                      p_num_corner,
                                                                                                                                                      p_num_lcd,
                                                                                                                                                      p_num_automobili));
        ROLLBACK TO SP_PR_INSERISCI_ATRIO;
END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_ATRIO
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id dell'atrio
-- OUTPUT: Restituisce il dettaglio dell'atrio
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_ATRIO(p_id_atrio   IN CD_ATRIO.ID_ATRIO%TYPE)
                            RETURN C_DETTAGLIO_ATRIO
IS
c_atrio_dettaglio_return C_DETTAGLIO_ATRIO;
BEGIN
OPEN c_atrio_dettaglio_return  -- apre il cursore che conterra il dettaglio del cinema
     FOR
        SELECT  ATRIO.ID_ATRIO, CINEMA.ID_CINEMA, CINEMA.NOME_CINEMA,
                ATRIO.DESC_ATRIO, ATRIO.NUM_AUTOMOBILI,
                ATRIO.NUM_CORNER, ATRIO.NUM_DISTRIBUZIONI, ATRIO.NUM_ESPOSIZIONI,
                ATRIO.NUM_LCD, ATRIO.NUM_SCOOTER_MOTO
        FROM    CD_CINEMA CINEMA, CD_ATRIO ATRIO
        WHERE   ATRIO.ID_ATRIO              =   p_id_atrio
        AND     ATRIO.ID_CINEMA             =   CINEMA.ID_CINEMA;
RETURN c_atrio_dettaglio_return;
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'FUNZIONE FU_DETTAGLIO_ATRIO: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_DETTAGLIO_ATRIO;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_ATRIO
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un atrio dal sistema
--
-- OPERAZIONI:
--   3) Elimina l'atrio
--
-- INPUT:
--      p_id_atrio            id dell'atrio
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
PROCEDURE PR_ELIMINA_ATRIO(  p_id_atrio        IN CD_ATRIO.ID_ATRIO%TYPE,
                             p_esito        OUT NUMBER)
IS
--
BEGIN -- PR_ELIMINA_ATRIO
--
p_esito     := 1;
          SAVEPOINT SP_PR_ELIMINA_ATRIO;

        -- elimino il circuito atrio
        DELETE FROM CD_ATRIO_VENDITA
        WHERE ID_CIRCUITO_ATRIO IN
            (SELECT ID_CIRCUITO_ATRIO FROM CD_CIRCUITO_ATRIO
             WHERE ID_ATRIO = p_id_atrio);

        DELETE FROM CD_CIRCUITO_ATRIO
        WHERE ID_ATRIO = p_id_atrio;

        -- qui elimino gli schermi e le proiezioni associate
          PA_CD_SCHERMO.PR_ELIMINA_SCHERMO_ATRIO(p_id_atrio,p_esito);

       -- EFFETTUA L'ELIMINAZIONE
       DELETE FROM CD_ATRIO
       WHERE id_atrio = p_id_atrio;
       --
       p_esito := SQL%ROWCOUNT;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_ELIMINA_ATRIO: Delete non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_ELIMINA_ATRIO;
  END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_ATRIO_CINEMA
--
-- DESCRIZIONE:  Esegue l'eliminazione degli atrii associati al cinema
--
-- OPERAZIONI:
--   3) Elimina gli atrii
--
-- INPUT:
--      p_id_cinema            id del cinema
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
PROCEDURE PR_ELIMINA_ATRIO_CINEMA(    p_id_cinema        IN CD_CINEMA.ID_CINEMA%TYPE,
                                    p_esito            OUT NUMBER)
IS
CURSOR c_atrii IS
        SELECT  ID_ATRIO FROM CD_ATRIO
        WHERE id_cinema = p_id_cinema;
--
BEGIN -- PR_ELIMINA_ATRIO_CINEMA
--
p_esito     := 1;
          SAVEPOINT SP_PR_ELIMINA_ATRIO_CINEMA;
        FOR atrio in c_atrii LOOP
             PR_ELIMINA_ATRIO(atrio.ID_ATRIO,p_esito);
        END LOOP;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_ELIMINA_ATRIO_CINEMA: Delete non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_ELIMINA_ATRIO_CINEMA;
  END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_ATRIO
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di un atrio
--                  degli schermi, dei relativi circuiti
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- OPERAZIONI:
--   1) Cancella logicamente atrio, schermi, circuiti_ambiti
--      ambiti_vendita, comunicati, prodotti
-- INPUT:  Id dell'atrio
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_ATRIO(p_id_atrio        IN CD_ATRIO.ID_ATRIO%TYPE,
                           p_esito           OUT NUMBER,
                           p_piani_errati    OUT VARCHAR2)
IS
    v_esito     NUMBER:=0;
    v_esito_tar NUMBER:=0;
BEGIN
    p_esito     := 0;
    --SEZIONE SCHERMI E BREAK
    FOR TEMP IN(SELECT DISTINCT CD_SCHERMO.ID_SCHERMO
                FROM  CD_SCHERMO
                WHERE CD_SCHERMO.ID_ATRIO = p_id_atrio
                AND   CD_SCHERMO.FLG_ANNULLATO<>'S')LOOP
        PA_CD_SCHERMO.PR_ANNULLA_SCHERMO(TEMP.ID_SCHERMO, v_esito, p_piani_errati);
        p_esito:=p_esito+v_esito;
    END LOOP;
    --SEZIONE ATRII
    FOR TEMP IN(SELECT ID_COMUNICATO
                FROM   CD_COMUNICATO
                WHERE  CD_COMUNICATO.ID_ATRIO_VENDITA IN(
                   SELECT DISTINCT CD_ATRIO_VENDITA.ID_ATRIO_VENDITA
                   FROM  CD_ATRIO_VENDITA
                   WHERE CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO IN(
                      SELECT DISTINCT CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
                      FROM  CD_CIRCUITO_ATRIO
                      WHERE CD_CIRCUITO_ATRIO.ID_ATRIO = p_id_atrio
                      AND   CD_CIRCUITO_ATRIO.ID_LISTINO IN (
                         SELECT DISTINCT CD_LISTINO.ID_LISTINO
                         FROM  CD_LISTINO
                         WHERE CD_LISTINO.DATA_FINE > SYSDATE)
                      AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO<>'S'))
                AND CD_COMUNICATO.FLG_ANNULLATO<>'S') LOOP
        PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(TEMP.ID_COMUNICATO, 'PAL',v_esito, p_piani_errati);
        IF((v_esito=5) OR (v_esito=15) OR (v_esito=25)) THEN
            p_esito := p_esito + 1;
        END IF;
    END LOOP;
    --recupero gli atrii di vendita
    UPDATE  CD_ATRIO_VENDITA
    SET FLG_ANNULLATO='S'
    WHERE  CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO IN(
       SELECT DISTINCT CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
       FROM  CD_CIRCUITO_ATRIO
       WHERE CD_CIRCUITO_ATRIO.ID_ATRIO = p_id_atrio
       AND   CD_CIRCUITO_ATRIO.ID_LISTINO IN (
          SELECT DISTINCT CD_LISTINO.ID_LISTINO
          FROM CD_LISTINO
          WHERE CD_LISTINO.DATA_FINE > SYSDATE)
       AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO<>'S')
    AND CD_ATRIO_VENDITA.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti atrio
    UPDATE  CD_CIRCUITO_ATRIO
    SET FLG_ANNULLATO='S'
    WHERE CD_CIRCUITO_ATRIO.ID_ATRIO = p_id_atrio
    AND   CD_CIRCUITO_ATRIO.ID_LISTINO IN (
       SELECT DISTINCT CD_LISTINO.ID_LISTINO
       FROM  CD_LISTINO
       WHERE CD_LISTINO.DATA_FINE > SYSDATE)
    AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --infine l'atrio
    UPDATE  CD_ATRIO
    SET FLG_ANNULLATO='S'
    WHERE  CD_ATRIO.ID_ATRIO = p_id_atrio
    AND    CD_ATRIO.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    FOR LISTINO IN (SELECT DISTINCT CD_LISTINO.ID_LISTINO
       FROM  CD_LISTINO
       WHERE CD_LISTINO.DATA_FINE > SYSDATE)LOOP
        PA_CD_TARIFFA.PR_ALLINEA_TARIFFA_PER_ELIM(p_id_atrio, null, null, LISTINO.ID_LISTINO, v_esito_tar, p_piani_errati);
    END LOOP;
 EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_ANNULLA_ATRIO: Eliminazione logica non eseguita: si e'' verificato un errore inatteso '||SQLERRM);
        p_esito := -1;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_ATRII
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di una lista di atrii
--               Per maggiori dettagli guardare la documentaione di
--               PA_CD_ATRIO.PR_ANNULLA_ATRIO
-- INPUT: Lista di Id degli atrii
-- OUTPUT: esito:
--    n  numero degli atrii annullati (che dovrebbe coincidere con p_lista_atrii.COUNT)
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_ATRII(p_lista_atrii       IN id_atrii_type,
                                 p_esito           OUT NUMBER,
                                 p_piani_errati    OUT VARCHAR2)
IS
    v_temp  INTEGER:=0;
BEGIN
    SAVEPOINT SP_PR_ANNULLA_LISTA_ATRII;
    p_esito:=0;
    FOR i IN 1..p_lista_atrii.COUNT LOOP
        PA_CD_ATRIO.PR_ANNULLA_ATRIO(p_lista_atrii(i),v_temp, p_piani_errati);
        IF(v_temp>=0)THEN
            p_esito:=p_esito+1;
        ELSE
            p_esito:=p_esito-1;
        END IF;
    END LOOP;
EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_ANNULLA_LISTA_ATRII: Eliminazione logica non eseguita: si e'' verificato un errore inatteso '||SQLERRM);
        p_esito := -1;
        ROLLBACK TO SP_PR_ANNULLA_LISTA_ATRII;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_ATRIO
--
-- DESCRIZIONE:  Esegue il recupero da cancellazione logioca di un atrio
--                  degli schermi, dei relativi circuiti
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- OPERAZIONI:
--   1) Recupera logicamente atrio, schermi, circuiti_ambiti
--      ambiti_vendita, comunicati
-- INPUT:  Id dell'atrio
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Recupero non eseguito: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_ATRIO(p_id_atrio        IN CD_ATRIO.ID_ATRIO%TYPE,
                            p_esito           OUT NUMBER)
IS
    v_esito     NUMBER:=0;
BEGIN
    p_esito     := 0;
    SAVEPOINT SP_PR_RECUPERA_ATRIO;
    --SEZIONE SCHERMI E BREAK
    -- manca il recupero eventuale dei comunicati
    FOR TEMP IN(SELECT DISTINCT CD_SCHERMO.ID_SCHERMO
                FROM  CD_SCHERMO
                WHERE CD_SCHERMO.ID_ATRIO = p_id_atrio
                AND   CD_SCHERMO.FLG_ANNULLATO='S')LOOP
        PA_CD_SCHERMO.PR_RECUPERA_SCHERMO(TEMP.ID_SCHERMO, v_esito);
        p_esito:=p_esito+v_esito;
    END LOOP;
    --SEZIONE ATRII
    -- manca il recupero eventuale dei comunicati
    --recupero gli atrii di vendita
    UPDATE  CD_ATRIO_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE  CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO IN(
       SELECT DISTINCT CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
       FROM  CD_CIRCUITO_ATRIO
       WHERE CD_CIRCUITO_ATRIO.ID_ATRIO = p_id_atrio
       AND   CD_CIRCUITO_ATRIO.ID_LISTINO IN (
          SELECT DISTINCT CD_LISTINO.ID_LISTINO
          FROM CD_LISTINO
          WHERE CD_LISTINO.DATA_FINE > SYSDATE)
       AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO='S')
    AND CD_ATRIO_VENDITA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti atrio
    UPDATE  CD_CIRCUITO_ATRIO
    SET FLG_ANNULLATO='N'
    WHERE CD_CIRCUITO_ATRIO.ID_ATRIO = p_id_atrio
    AND   CD_CIRCUITO_ATRIO.ID_LISTINO IN (
       SELECT DISTINCT CD_LISTINO.ID_LISTINO
       FROM  CD_LISTINO
       WHERE CD_LISTINO.DATA_FINE > SYSDATE)
    AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --infine l'atrio
    UPDATE  CD_ATRIO
    SET FLG_ANNULLATO='N'
    WHERE  CD_ATRIO.ID_ATRIO = p_id_atrio
    AND    CD_ATRIO.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
 EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_RECUPERA_ATRIO: Recupero non eseguito: si e'' verificato un errore inatteso');
        p_esito := -1;
        ROLLBACK TO SP_PR_RECUPERA_ATRIO;
END;
-- Procedura PR_MODIFICA_ATRIO
--
-- DESCRIZIONE:  Esegue l'aggiornamento di un atrio nel sistema
--
-- OPERAZIONI:
--   Update
--
-- INPUT:
--      p_desc_atrio            descrizione dell'atrio
--      p_id_cinema             id del cinema
--      p_num_distribuzioni     numero dei punti di distribuzione
--      p_num_esposizioni       numero delle aree di esposizione
--      p_num_scooter_moto      numero di posti scooter/moto
--      p_num_corner            numero dei corner
--      p_num_lcd               numero degli schermi LCD
--      p_num_automobili        numero di posti auto
--      p_flg_annullato         flag che indica se l'atrio e valida
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Upsate non eseguito: i parametri per l'Udate non sono coerenti
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--

PROCEDURE PR_MODIFICA_ATRIO(  p_id_atrio                CD_ATRIO.ID_ATRIO%TYPE,
                              p_desc_atrio              CD_ATRIO.DESC_ATRIO%TYPE,
                              p_id_cinema               CD_ATRIO.ID_CINEMA%TYPE,
                              p_num_distribuzioni       CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
                              p_num_esposizioni         CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
                              p_num_scooter_moto        CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
                              p_num_corner              CD_ATRIO.NUM_CORNER%TYPE,
                              p_num_lcd                 CD_ATRIO.NUM_LCD%TYPE,
                              p_num_automobili          CD_ATRIO.NUM_AUTOMOBILI%TYPE,
                              p_flg_annullato           CD_ATRIO.FLG_ANNULLATO%TYPE,
                              p_esito                    OUT NUMBER)
IS
--
BEGIN -- PR_MODIFICHE_ATRIO
--
        p_esito := 1;
          SAVEPOINT SP_PR_MODIFICA_ATRIO;
           -- EFFETTUA L'UPDATE
           UPDATE CD_ATRIO
           SET
              DESC_ATRIO = (nvl(p_desc_atrio,DESC_ATRIO)),
              ID_CINEMA = (nvl(p_id_cinema,ID_CINEMA)),
              NUM_DISTRIBUZIONI = (nvl(p_num_distribuzioni,NUM_DISTRIBUZIONI)),
              NUM_ESPOSIZIONI = (nvl(p_num_esposizioni,NUM_ESPOSIZIONI)),
              NUM_SCOOTER_MOTO = (nvl(p_num_scooter_moto,NUM_SCOOTER_MOTO)),
              NUM_CORNER = (nvl(p_num_corner,NUM_CORNER)),
              NUM_LCD = (nvl(p_num_lcd,NUM_LCD)),
              NUM_AUTOMOBILI = (nvl(p_num_automobili,NUM_AUTOMOBILI)),
              FLG_ANNULLATO = (nvl(p_flg_annullato,FLG_ANNULLATO))
          WHERE ID_ATRIO = p_id_atrio;
       --
       p_esito := SQL%ROWCOUNT;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Procedura PR_MODIFICA_ATRIO: Update non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_MODIFICA_ATRIO;
  END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_ATRIO
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i paramtetri
--
-- INPUT:
--      p_desc_atrio            descrizione dell'atrio
--      p_id_cinema             id del cinema
--      p_num_distribuzioni     numero dei punti di distribuzione
--      p_num_esposizioni       numero delle aree di esposizione
--      p_num_scooter_moto      numero di posti scooter/moto
--      p_num_corner            numero dei corner
--      p_num_lcd               numero degli schermi LCD
--      p_num_automobili        numero di posti auto
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_ATRIO(     p_desc_atrio              CD_ATRIO.DESC_ATRIO%TYPE,
                              p_id_cinema               CD_ATRIO.ID_CINEMA%TYPE,
                              p_num_distribuzioni       CD_ATRIO.NUM_DISTRIBUZIONI%TYPE,
                              p_num_esposizioni         CD_ATRIO.NUM_ESPOSIZIONI%TYPE,
                              p_num_scooter_moto        CD_ATRIO.NUM_SCOOTER_MOTO%TYPE,
                              p_num_corner              CD_ATRIO.NUM_CORNER%TYPE,
                              p_num_lcd                 CD_ATRIO.NUM_LCD%TYPE,
                              p_num_automobili          CD_ATRIO.NUM_AUTOMOBILI%TYPE
                            )  RETURN VARCHAR2
IS
BEGIN
IF v_stampa_atrio = 'ON'
    THEN
     RETURN 'DESC_ATRIO: '          || p_desc_atrio           || ', ' ||
            'ID_CINEMA: '          || p_id_cinema            || ', ' ||
            'NUM_DISTRIBUZIONI: '|| p_num_distribuzioni    || ', ' ||
            'NUM_ESPOSIZIONI: '  || p_num_esposizioni        || ', ' ||
            'NUM_SCOOTER_MOTO: ' || p_num_scooter_moto        || ', ' ||
            'NUM_CORNER: '          || p_num_corner               || ', ' ||
            'NUM_LCD: '          || p_num_lcd                   || ', ' ||
            'NUM_AUTOMOBILI: '      || p_num_automobili;
END IF;
END  FU_STAMPA_ATRIO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_ATRIO
-- INPUT:  ID dell'atrio di cui si vuole il nome
-- OUTPUT:  il nome dell'atrio

-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_ATRIO(p_id_atrio  IN CD_ATRIO.ID_ATRIO%TYPE)
            RETURN VARCHAR2
IS
    v_return_value CD_ATRIO.DESC_ATRIO%TYPE:='--';
BEGIN
    IF (p_id_atrio IS NOT NULL) THEN
        SELECT CD_ATRIO.DESC_ATRIO
        INTO v_return_value
        FROM CD_ATRIO
        WHERE CD_ATRIO.ID_ATRIO=p_id_atrio;
    END IF;

    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '--';
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20009, 'Function FU_DAMMI_NOME_ATRIO: Impossibile valutare la richiesta');
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_ATRIO
-- INPUT:  ID dell'Atrio del quale si vuole lo stato
-- OUTPUT:  0   l'atrio NON appartiene a nessun circuito/lisitno
--          1   l'atrio appartiene a qualche circuito/lisitno ma NON e' in un prodotto vendita
--          2   l'atrio appartiene a qualche circuito/lisitno, e' in un prodotto vendita,
--                                      ma NON e' in un prodotto acquistato
--          3   l'atrio appartiene a qualche circuito/lisitno e' in un prodotto vendita,
--                                      ed e' in un prodotto acquistato
--          -10 l'atrio non esiste
--          -1  si e' verificato un errore
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_ATRIO (p_id_atrio   IN CD_ATRIO.ID_ATRIO%TYPE)
            RETURN INTEGER
IS
    v_return_value  INTEGER;
    v_stato         INTEGER;
    v_id_listino    INTEGER;
    v_id_circuito   INTEGER;
BEGIN
    v_return_value:=-10;
    IF(p_id_atrio>0)THEN
        v_id_listino:=-10;
          v_id_circuito:=-10;
          v_return_value:=-10; --valore di comodo per la ricerca del max
          v_stato:=-10;
        FOR L1 in (select DISTINCT CD_LISTINO.ID_LISTINO FROM CD_LISTINO) LOOP
            FOR C1 in (select DISTINCT CD_CIRCUITO.ID_CIRCUITO FROM CD_CIRCUITO) LOOP
                v_stato:=PA_CD_LISTINO.FU_ATRIO_IN_CIRCUITO_LISTINO(L1.ID_LISTINO, C1.ID_CIRCUITO, p_id_atrio);
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
            RAISE_APPLICATION_ERROR(-20000, 'Function FU_DAMMI_NOME_ATRIO: Impossibile valutare la richiesta'||SQLERRM);
        v_return_value:=-1;
        RETURN v_return_value;
END;
--

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_SCHERMI_ATRIO
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id dell'atrio
-- OUTPUT: Restituisce il dettaglio degli schermi associati all'atrio
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SCHERMI_ATRIO  (p_id_atrio   IN CD_ATRIO.ID_ATRIO%TYPE)
                            RETURN C_DETTAGLIO_ATRIO_SCHERMI
IS
c_schermi_dettaglio_return C_DETTAGLIO_ATRIO_SCHERMI;
BEGIN
OPEN c_schermi_dettaglio_return  -- apre il cursore che conterra il dettaglio del cinema
     FOR
        SELECT  ID_SCHERMO, DESC_SCHERMO, MISURA_POLLICI
        FROM    CD_ATRIO ATRIO, CD_SCHERMO SCHERMO
        WHERE   ATRIO.ID_ATRIO              =   SCHERMO.ID_ATRIO
        AND     ATRIO.ID_ATRIO                =   p_id_atrio;
RETURN c_schermi_dettaglio_return;
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'FUNZIONE FU_DETTAGLIO_ATRIO: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_SCHERMI_ATRIO;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ATRIO_VENDUTO
--
--  La funzione restituisce il numero di comunicati associati all atrio
--
-- INPUT:  ID dell atrio
-- OUTPUT:  n numero dei comunicati associati all atrio
--          -1 si e' verificato un errore
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ATRIO_VENDUTO(p_id_atrio  IN CD_ATRIO.ID_ATRIO%TYPE)
                             RETURN INTEGER
IS
    v_return_value_atrio            INTEGER:=0;
    v_return_value_schermo_atrio    INTEGER:=0;
    v_return_value                  INTEGER:=0;

BEGIN

     -- qui controlla se ci sono circuiti atrio venduti
     FOR CIRC_ATRIO IN(
                    SELECT DISTINCT(ID_CIRCUITO) FROM CD_CIRCUITO_ATRIO
                    WHERE ID_ATRIO = p_id_atrio)
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_atrio := PA_CD_CIRCUITO.FU_CIRCUITO_VENDUTO(CIRC_ATRIO.ID_CIRCUITO);
            v_return_value := v_return_value + v_return_value_atrio + v_return_value_schermo_atrio;
        END LOOP;

    -- qui controlla se ci sono circuiti schermo di atrio venduti
    FOR CIRC_PROIEZIONE_ATRIO IN(
                    SELECT DISTINCT(ID_PROIEZIONE) FROM CD_PROIEZIONE
                    WHERE ID_SCHERMO IN
                        (SELECT ID_SCHERMO FROM CD_SCHERMO
                         WHERE ID_ATRIO = p_id_atrio))
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_schermo_atrio := PA_CD_PROIEZIONE.FU_PROIEZIONE_VENDUTA(CIRC_PROIEZIONE_ATRIO.ID_PROIEZIONE);
            v_return_value := v_return_value + v_return_value_atrio + v_return_value_schermo_atrio;
        END LOOP;

    RETURN v_return_value;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000, 'Function FU_ATRIO_VENDUTO: Impossibile valutare la richiesta '||sqlerrm);
            v_return_value:=-1;
            RETURN v_return_value;
END FU_ATRIO_VENDUTO;

END PA_CD_ATRIO; 
/

