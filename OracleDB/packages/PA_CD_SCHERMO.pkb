CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SCHERMO IS

FUNCTION FU_GET_NUM_SALE_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER IS
begin
null;
end;


/*

FUNCTION FU_GET_NUM_SALE_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER IS
v_num_sale NUMBER;
BEGIN
    SELECT COUNT(1) INTO v_num_sale FROM
    CD_SALA, CD_CIRCUITO_SALA, CD_CIRCUITO
    WHERE CD_CIRCUITO.ID_CIRCUITO = p_id_circuito
    AND CD_CIRCUITO_SALA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
    CD_SALA.ID_SALA = CD_CIRCUITO_SALA.ID_SALA;
    RETURN v_num_sale;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_GET_NUM_SALE_CIRCUITO: Impossibile valutare la richiesta');

END FU_GET_NUM_SALE_CIRCUITO;

*/
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_SCHERMO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo schermo nel sistema
--
-- OPERAZIONI:
--     1) Controlla se si vuole procedere con inserimento manuale od tramite sequence dell'id_schermo
--   2) Nel caso di inserimento manuale controlla che non esistano altri schermi con lo stesso id
--   3) Memorizza lo schermo (CD_SCHERMO)
--
-- INPUT: parametri di inserimento di un nuovo schermo
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -1  Inserimento non eseguito: esiste gia uno schermo con questo id
--   -2  Inserimento non eseguito: l'id schermo e NULL
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SCHERMO(p_desc_schermo             CD_SCHERMO.DESC_SCHERMO%TYPE,
                               p_id_sala                  CD_SCHERMO.ID_SALA%TYPE,
                               p_id_atrio                 CD_SCHERMO.ID_ATRIO%TYPE,
                               p_misura_larghezza         CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                               p_misura_lunghezza         CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                               p_misura_pollici           CD_SCHERMO.MISURA_POLLICI%TYPE,
                               p_flg_sala                CD_SCHERMO.FLG_SALA%TYPE,
                               p_esito                    OUT NUMBER)
IS
BEGIN -- PR_INSERISCI_SCHERMO
--
p_esito     := 1;
--P_ID_SCHERMO := SCHERMO_SEQ.NEXTVAL;
     --
          SAVEPOINT SP_PR_INSERISCI_SCHERMO;
      --
       -- effettuo l'INSERIMENTO
       INSERT INTO CD_SCHERMO
         (ID_SALA,
          ID_ATRIO,
          DESC_SCHERMO,
          MISURA_LARGHEZZA,
          MISURA_LUNGHEZZA,
          MISURA_POLLICI,
          FLG_SALA,
          FLG_ANNULLATO,
          UTEMOD,
          DATAMOD
         )
       VALUES
         (p_id_sala,
          p_id_atrio,
          p_desc_schermo,
          p_misura_larghezza,
          p_misura_lunghezza,
          p_misura_pollici,
          p_flg_sala,
          'N',
          user,
          FU_DATA_ORA
          );
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20010, 'PROCEDURA PR_INSERISCI_SCHERMO: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_SCHERMO(p_id_sala,
                                                                                                                                                        p_id_atrio,
                                                                                                                                                        p_misura_larghezza,
                                                                                                                                                        p_misura_lunghezza,
                                                                                                                                                        p_misura_pollici,
                                                                                                                                                        p_flg_sala));
        ROLLBACK TO SP_PR_INSERISCI_SCHERMO;
END;







-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SCHERMO
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di uno schermo dal sistema
--
-- OPERAZIONI:
--   1) Elimina lo schermo
--
-- INPUT:
--      p_id_schermo    id dello schermo
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
PROCEDURE PR_ELIMINA_SCHERMO(p_id_schermo   IN CD_SCHERMO.ID_SCHERMO%TYPE,
                             p_esito        OUT NUMBER)
IS

v_esito     INTEGER:= 0;

--
BEGIN -- PR_ELIMINA_SCHERMO
--
p_esito     := 1;
     --
          SAVEPOINT SP_PR_ELIMINA_SCHERMO;

       -- qui elimina le proiezioni collegate allo schermo
    FOR CIRC_PROIEZIONI IN(
                    SELECT DISTINCT(ID_PROIEZIONE) FROM CD_PROIEZIONE
                    WHERE ID_SCHERMO = p_id_schermo)
        LOOP
            PA_CD_PROIEZIONE.PR_ELIMINA_PROIEZIONE(CIRC_PROIEZIONI.ID_PROIEZIONE,v_esito);
        END LOOP;

-- elimino i circuiti schermo relativi
       DELETE FROM CD_CIRCUITO_SCHERMO
	   WHERE ID_SCHERMO = p_id_schermo;
       -- effettua l'ELIMINAZIONE
       DELETE FROM CD_SCHERMO
       WHERE ID_SCHERMO = p_id_schermo;
       --
    p_esito := SQL%ROWCOUNT;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Procedura PR_ELIMINA_SCHERMO: Delete non eseguita, '|| SQLERRM) ;
        ROLLBACK TO SP_PR_ELIMINA_SCHERMO;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SCHERMO_SALA
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di uno schermo per sala
--
-- OPERAZIONI:
--   1) Elimina lo schermo
--
-- INPUT:
--      p_id_sala    id dello sala
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
PROCEDURE PR_ELIMINA_SCHERMO_SALA(p_id_sala      IN CD_SALA.ID_SALA%TYPE,
                                  p_esito        OUT NUMBER)
IS

--
CURSOR c_schermo IS
        SELECT  ID_SCHERMO FROM CD_SCHERMO
        WHERE ID_SALA = p_id_sala;
--
BEGIN -- PR_ELIMINA_SCHERMO_SALA
--
        p_esito     := 1;
          SAVEPOINT SP_PR_ELIMINA_SCHERMO_SALA;
        FOR schermo in c_schermo LOOP
             PR_ELIMINA_SCHERMO(schermo.ID_SCHERMO,p_esito);
        END LOOP;
       --
       p_esito := SQL%ROWCOUNT;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Procedura PR_ELIMINA_SCHERMO_SALA: Delete non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_ELIMINA_SCHERMO_SALA;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SCHERMO_ATRIO
--
-- DESCRIZIONE:  Esegue l'eliminazione degli schermi di un atrio
--
-- OPERAZIONI:
--   1) Elimina lo schermo
--
-- INPUT:
--      p_id_atrio    id dell atrio
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SCHERMO_ATRIO(p_id_atrio     IN CD_ATRIO.ID_ATRIO%TYPE,
                                   p_esito        OUT NUMBER)
IS

--
CURSOR c_schermo IS
        SELECT  ID_SCHERMO FROM CD_SCHERMO
        WHERE ID_ATRIO = p_id_atrio;
--
BEGIN -- PR_ELIMINA_SCHERMO_ATRIO
--
        p_esito     := 1;
          SAVEPOINT SP_PR_ELIMINA_SCHERMO_ATRIO;
        FOR schermo in c_schermo LOOP
             PR_ELIMINA_SCHERMO(schermo.ID_SCHERMO,p_esito);
        END LOOP;
       --
       p_esito := SQL%ROWCOUNT;
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Procedura PR_ELIMINA_SCHERMO_ATRIO: Delete non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_ELIMINA_SCHERMO_ATRIO;
END;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_SCHERMO
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di uno schermo
--                  dei relativi circuiti
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- OPERAZIONI:
--   1) Cancella logicamente schermi, circuiti_ambiti
--      ambiti_vendita, comunicati, prodotti
-- INPUT:  Id dello schermo
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_SCHERMO(p_id_schermo      IN CD_SCHERMO.ID_SCHERMO%TYPE,
                             p_esito           OUT NUMBER,
                             p_piani_errati    OUT VARCHAR2)
IS
    v_esito     NUMBER:=0;
BEGIN
    p_esito     := 0;
    -- qui annullo le proiezioni collegate allo schermo
    FOR CIRC_PROIEZIONI IN(SELECT DISTINCT(ID_PROIEZIONE) FROM CD_PROIEZIONE WHERE ID_SCHERMO = p_id_schermo)LOOP
        PA_CD_PROIEZIONE.PR_ANNULLA_PROIEZIONE(CIRC_PROIEZIONI.ID_PROIEZIONE,'Annullato lo schermo di riferimento',v_esito, p_piani_errati);
    END LOOP;
    --seleziono i circuiti schermo
    UPDATE  CD_CIRCUITO_SCHERMO
    SET FLG_ANNULLATO='S'
    WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO = p_id_schermo
    AND    CD_CIRCUITO_SCHERMO.ID_LISTINO IN(
              SELECT DISTINCT CD_LISTINO.ID_LISTINO
              FROM CD_LISTINO
              WHERE CD_LISTINO.DATA_FINE > SYSDATE)
    AND    CD_CIRCUITO_SCHERMO.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;

	--seleziono gli schermi validi, sia di atrio che di sala
    UPDATE  CD_SCHERMO
    SET FLG_ANNULLATO='S'
    WHERE CD_SCHERMO.ID_SCHERMO = p_id_schermo
    AND CD_SCHERMO.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
 EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Procedura PR_ANNULLA_SCHERMO: Eliminazione logica non eseguita: si e'' verificato un errore inatteso');
        p_esito := -1;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_SCHERMI
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di una lista di schermi
--               Per maggiori dettagli guardare la documentaione di
--               PA_CD_SCHERMO.PR_ANNULLA_SCHERMO
-- INPUT: Lista di Id delgli schermi
-- OUTPUT: esito:
--    n  numero degli schemri annullati (che dovrebbe coincidere con p_lista_schermi.COUNT)
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_SCHERMI(p_lista_schermi	   IN id_schermi_type,
							      p_esito		       OUT NUMBER,
                                  p_piani_errati       OUT VARCHAR2)
IS
    v_temp  INTEGER:=0;
BEGIN
    SAVEPOINT SP_PR_ANNULLA_LISTA_SCHERMI;
    p_esito:=0;
    FOR i IN 1..p_lista_schermi.COUNT LOOP
	    PA_CD_SCHERMO.PR_ANNULLA_SCHERMO(p_lista_schermi(i),v_temp,p_piani_errati);
		IF(v_temp>=0)THEN
	        p_esito:=p_esito+1;
		ELSE
	        p_esito:=p_esito-1;
		END IF;
	END LOOP;
EXCEPTION
  	WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20009, 'Procedura PR_ANNULLA_LISTA_SCHERMI: Eliminazione logica non eseguita: si e'' verificato un errore inatteso');
		p_esito := -1;
		ROLLBACK TO SP_PR_ANNULLA_LISTA_SCHERMI;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_SCHERMO
--
-- DESCRIZIONE:  Esegue il recupero da cancellazione logioca di uno schermo
--                  dei relativi circuiti
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- OPERAZIONI:
--   1) Recupera logicamente schermi, circuiti_ambiti
--      ambiti_vendita, comunicati
-- INPUT:  Id dello schermo
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Recupero non eseguito: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_SCHERMO(p_id_schermo      IN CD_SCHERMO.ID_SCHERMO%TYPE,
                              p_esito           OUT NUMBER)
IS
BEGIN
    p_esito     := 0;
	SAVEPOINT SP_PR_RECUPERA_SCHERMO;
    --SEZIONE SCHERMI E BREAK
    -- manca il recupero eventuale dei comunicati
    --qui recupero i break di vendita
    UPDATE  CD_BREAK_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_BREAK_VENDITA.ID_CIRCUITO_BREAK IN(
       SELECT DISTINCT ID_CIRCUITO_BREAK
       FROM (SELECT DISTINCT CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK, CD_CIRCUITO_BREAK.ID_BREAK
             FROM  CD_CIRCUITO_BREAK
             WHERE CD_CIRCUITO_BREAK.ID_BREAK IN(
                SELECT DISTINCT CD_BREAK.ID_BREAK
                FROM  CD_BREAK
                WHERE CD_BREAK.ID_PROIEZIONE IN(
                   SELECT DISTINCT CD_PROIEZIONE.ID_PROIEZIONE
                     FROM  CD_PROIEZIONE
                     WHERE CD_PROIEZIONE.ID_SCHERMO = p_id_schermo
                  AND   CD_PROIEZIONE.DATA_PROIEZIONE > SYSDATE))
             AND   CD_CIRCUITO_BREAK.ID_LISTINO IN(
                      SELECT DISTINCT CD_LISTINO.ID_LISTINO
                          FROM  CD_LISTINO
                      WHERE CD_LISTINO.DATA_FINE > SYSDATE)
             AND CD_CIRCUITO_BREAK.FLG_ANNULLATO='S'))
    AND CD_BREAK_VENDITA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti break
    UPDATE  CD_CIRCUITO_BREAK
    SET FLG_ANNULLATO='N'
    WHERE CD_CIRCUITO_BREAK.ID_BREAK IN(
       SELECT DISTINCT CD_BREAK.ID_BREAK
       FROM  CD_BREAK
       WHERE CD_BREAK.ID_PROIEZIONE IN(
          SELECT DISTINCT CD_PROIEZIONE.ID_PROIEZIONE
            FROM  CD_PROIEZIONE
            WHERE CD_PROIEZIONE.ID_SCHERMO = p_id_schermo
          AND   CD_PROIEZIONE.DATA_PROIEZIONE > SYSDATE))
    AND   CD_CIRCUITO_BREAK.ID_LISTINO IN(
             SELECT DISTINCT CD_LISTINO.ID_LISTINO
             FROM  CD_LISTINO
             WHERE CD_LISTINO.DATA_FINE > SYSDATE)
    AND CD_CIRCUITO_BREAK.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --seleziono i circuiti schermo
    UPDATE  CD_CIRCUITO_SCHERMO
    SET FLG_ANNULLATO='N'
    WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO = p_id_schermo
    AND    CD_CIRCUITO_SCHERMO.ID_LISTINO IN(
              SELECT DISTINCT CD_LISTINO.ID_LISTINO
              FROM CD_LISTINO
              WHERE CD_LISTINO.DATA_FINE > SYSDATE)
    AND    CD_CIRCUITO_SCHERMO.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --seleziono gli schermi validi, sia di atrio che di sala
    UPDATE  CD_SCHERMO
    SET FLG_ANNULLATO='N'
    WHERE CD_SCHERMO.ID_SCHERMO = p_id_schermo
    AND CD_SCHERMO.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
 EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Procedura PR_RECUPERA_SCHERMO: Recupero non eseguito: si e'' verificato un errore inatteso');
		ROLLBACK TO SP_PR_RECUPERA_SCHERMO;
        p_esito := -1;
END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_SCHERMO
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- INPUT: parametri dello schermo
--
-- OUTPUT: varchar che contiene i parametri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SCHERMO(    p_id_sala                  CD_SCHERMO.ID_SALA%TYPE,
                               p_id_atrio                 CD_SCHERMO.ID_ATRIO%TYPE,
                               p_misura_larghezza         CD_SCHERMO.MISURA_LARGHEZZA%TYPE,
                               p_misura_lunghezza         CD_SCHERMO.MISURA_LUNGHEZZA%TYPE,
                               p_misura_pollici           CD_SCHERMO.MISURA_POLLICI%TYPE,
                               p_flg_sala                CD_SCHERMO.FLG_SALA%TYPE)  RETURN VARCHAR2
IS
BEGIN
  IF v_stampa_schermo = 'ON'
    THEN
     RETURN 'ID_SALA: '          || p_id_sala            || ', ' ||
            'ID_ATRIO: '      || p_id_atrio         || ', '||
            'MISURA_LARGHEZZA: '           || p_misura_larghezza                || ', ' ||
            'MISURA_LUNGHEZZA: '          || p_misura_lunghezza           || ', ' ||
            'MISURA_POLLICI: '          || p_misura_pollici            || ', ' ||
            'FLG_SALA: '      || p_flg_sala;
END IF;
END  FU_STAMPA_SCHERMO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_SCHERMO
-- INPUT:  ID dello Schermo del quale si vuole lo stato
-- OUTPUT:  0   lo schermo NON appartiene a nessun circuito/lisitno
--          1   lo schermo appartiene a qualche circuito/lisitno ma NON e' in un prodotto vendita
--          2   lo schermo appartiene a qualche circuito/lisitno, e' in un prodotto vendita,
--                                      ma NON e' in un prodotto acquistato
--          3   lo schermo appartiene a qualche circuito/lisitno e' in un prodotto vendita,
--                                      ed e' in un prodotto acquistato
--          -10 lo schermo non esiste
--          -1  si e' verificato un errore
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_SCHERMO (p_id_schermo   IN CD_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER
IS
    v_return_value  INTEGER;
	v_stato         INTEGER;
	v_id_listino    INTEGER;
	v_id_circuito   INTEGER;
BEGIN
    v_return_value:=-10;
    IF(p_id_schermo>0)THEN
        v_id_listino:=-10;
  		v_id_circuito:=-10;
  		v_return_value:=-10; --valore di comodo per la ricerca del max
      	v_stato:=-10;
        FOR L1 in (select DISTINCT CD_LISTINO.ID_LISTINO FROM CD_LISTINO) LOOP
            FOR C1 in (select DISTINCT CD_CIRCUITO.ID_CIRCUITO FROM CD_CIRCUITO) LOOP
			    v_stato:=PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LISTINO(L1.ID_LISTINO, C1.ID_CIRCUITO, p_id_schermo);
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
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_DAMMI_NOME_SCHERMO: Impossibile valutare la richiesta');
		v_return_value:=-1;
		RETURN v_return_value;
END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_SCHERMI_CINEMA
-- DESCRIZIONE:  Restituisce gli schermi appartenenti ad un cinema
-- INPUT: p_id_cinema: id del cinema
-- OUTPUT: ref cursor con gli schermi trovati per il cinema
--
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SCHERMI_CINEMA(p_id_cinema CD_CINEMA.ID_CINEMA%TYPE,p_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,p_data_inizio cd_proiezione.data_proiezione%type,p_data_fine cd_proiezione.data_proiezione%type) RETURN C_SCHERMI IS
v_schermi C_SCHERMI;
BEGIN
  OPEN v_schermi FOR
      SELECT DISTINCT CD_SCHERMO.ID_SCHERMO, CD_SALA.NOME_SALA AS DESC_SCHERMO
  FROM
       CD_PROIEZIONE,
       CD_SCHERMO,
       CD_SALA,
       CD_CINEMA,
        (SELECT CD_BREAK.ID_PROIEZIONE, CD_CIRCUITO.NOME_CIRCUITO, CD_BREAK.ID_BREAK
          FROM CD_BREAK, CD_CIRCUITO, CD_CIRCUITO_BREAK, CD_BREAK_VENDITA
          WHERE CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
          AND CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
          AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
          AND CD_CIRCUITO.ID_CIRCUITO = p_id_circuito
          AND CD_CIRCUITO.FLG_ANNULLATO = 'N'
          AND CD_CIRCUITO_BREAK.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
          AND CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
          AND CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
          AND CD_BREAK.FLG_ANNULLATO = 'N'
          AND   (p_data_inizio IS NULL OR CD_BREAK_VENDITA.DATA_EROGAZIONE >= p_data_inizio)
          AND   (p_data_fine IS NULL OR CD_BREAK_VENDITA.DATA_EROGAZIONE <= p_data_fine)) BRK
  WHERE
       CD_CINEMA.ID_CINEMA = p_id_cinema
       AND CD_CINEMA.ID_CINEMA = CD_SALA.ID_CINEMA
       AND CD_SALA.FLG_ANNULLATO = 'N'
       AND CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
       AND CD_SCHERMO.FLG_ANNULLATO = 'N'
       AND CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
       AND BRK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
       AND CD_PROIEZIONE.FLG_ANNULLATO = 'N';
       RETURN v_schermi;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_GET_SCHERMI_CINEMA: Impossibile valutare la richiesta');
END FU_GET_SCHERMI_CINEMA;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_NUM_SCHERMI_CIRCUITO
-- DESCRIZIONE:  Restituisce il numero di schermi appartenenti ad un circuito
-- INPUT: p_id_circuito: id del circuito
-- OUTPUT: Numero di schermi trovati per il circuito
--
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_NUM_SCHERMI_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER IS
v_num_schermi NUMBER;
BEGIN
    SELECT COUNT(1) INTO v_num_schermi FROM
    CD_SCHERMO, CD_CIRCUITO_SCHERMO, CD_CIRCUITO
    WHERE CD_CIRCUITO.ID_CIRCUITO = p_id_circuito
    AND CD_CIRCUITO_SCHERMO.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
    AND CD_SCHERMO.ID_SCHERMO = CD_CIRCUITO_SCHERMO.ID_SCHERMO;
    RETURN v_num_schermi;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_GET_SCHERMI_CINEMA: Impossibile valutare la richiesta');

END FU_GET_NUM_SCHERMI_CIRCUITO;

--
END PA_CD_SCHERMO;
/

