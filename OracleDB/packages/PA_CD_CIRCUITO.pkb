CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_CIRCUITO IS
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_CIRCUITO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo circuito nel sistema
--
-- OPERAZIONI:
--   1) Memorizza il circuito (CD_CIRCUITO)
--
-- INPUT:
--      p_nome_circuito             nome del circuito
--      p_descr_circuito            descrizione del circuito
--      p_abbr_nome                 abbreviazione del nome del circuito
--      p_data_inizio_valid         data inizio validita
--      p_data_fine_valid           data fine validita
--      p_flag_atrio                flag che indica se il circuito e composto da atrii
--      p_flag_schermo              flag che indica se il circuito e composto da schermi
--      p_flag_cinema               flag che indica se il circuito e composto da cinema
--      p_flag_sala                 flag che indica se il circuito e composto da sale
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
PROCEDURE PR_INSERISCI_CIRCUITO(p_nome_circuito              CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                                p_descr_circuito             CD_CIRCUITO.DESC_CIRCUITO%TYPE,
                                p_abbr_nome                  CD_CIRCUITO.ABBR_NOME%TYPE,
                                p_data_inizio_valid          CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                                p_data_fine_valid            CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                                p_flag_atrio                 CD_CIRCUITO.FLG_ATRIO%TYPE,
                                p_flag_schermo               CD_CIRCUITO.FLG_SCHERMO%TYPE,
                                p_flag_cinema                CD_CIRCUITO.FLG_CINEMA%TYPE,
                                p_flag_sala                  CD_CIRCUITO.FLG_SALA%TYPE,
                                p_flag_arena                 CD_CIRCUITO.FLG_ARENA%TYPE,
                                p_flag_listino               CD_CIRCUITO.FLG_DEFINITO_A_LISTINO%TYPE,
                                p_livello                    CD_CIRCUITO.LIVELLO%TYPE,
                                p_esito                      OUT NUMBER)
IS
BEGIN -- PR_INSERISCI_CIRCUITO
   p_esito := 1;
   --P_ID_CIRCUITO := CIRCUITO_SEQ.NEXTVAL;
          SAVEPOINT SP_PR_INSERISCI_CIRCUITO;
       -- EFFETTUO L'INSERIMENTO
       INSERT INTO CD_CIRCUITO
         (NOME_CIRCUITO,
          DESC_CIRCUITO,
          ABBR_NOME,
          DATA_INIZIO_VALID,
          DATA_FINE_VALID,
          FLG_ATRIO,
          FLG_SCHERMO,
          FLG_CINEMA,
          FLG_SALA,
          FLG_ARENA,
          FLG_DEFINITO_A_LISTINO,          
          FLG_ANNULLATO,
          LIVELLO,
          UTEMOD,
          DATAMOD
         )
       VALUES
         (p_nome_circuito,
          p_descr_circuito,
          p_abbr_nome,
          p_data_inizio_valid,
          p_data_fine_valid,
          p_flag_atrio,
          p_flag_schermo,
          p_flag_cinema,
          p_flag_sala,
          p_flag_arena,
          p_flag_listino,
          'N',
          p_livello,
          user,
          FU_DATA_ORA
          );
          SELECT CD_CIRCUITO_SEQ.currval
          INTO p_esito
          FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_INSERISCI_CIRCUITO: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_CIRCUITO(p_nome_circuito,
                                                                                                                                                          p_descr_circuito,
                                                                                                                                                          p_abbr_nome,
                                                                                                                                                          p_data_inizio_valid,
                                                                                                                                                          p_data_fine_valid,
                                                                                                                                                          p_flag_atrio,
                                                                                                                                                          p_flag_schermo,
                                                                                                                                                          p_flag_cinema,
                                                                                                                                                          p_flag_sala));
        ROLLBACK TO SP_PR_INSERISCI_CIRCUITO;
END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CERCA_CIRCUITO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_nome_circuito         nome del circuito
--  p_data_inizio_valid     data inizio validita
--  p_data_fine_valid       data fine validita
--
-- OUTPUT: Restituisce i circuiti che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE     Roberto Barbaro, Teoresi srl, Febbraio 2010
--               aggiunta del vincolo sul flg_schermo 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_CIRCUITO( p_nome_circuito     CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                            p_data_inizio_valid CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                            p_data_fine_valid   CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                            p_flg_schermo       CD_CIRCUITO.FLG_SCHERMO%TYPE)
                            RETURN C_CIRCUITO
IS
   c_circuito_return C_CIRCUITO;
BEGIN
OPEN c_circuito_return  -- apre il cursore che contiene i cinema da selezionare
     FOR
        SELECT  CIRCUITO.ID_CIRCUITO, CIRCUITO.NOME_CIRCUITO,
                CIRCUITO.DATA_INIZIO_VALID, CIRCUITO.DATA_FINE_VALID
                FROM    CD_CIRCUITO CIRCUITO
        --WHERE   UPPER(NOME_CIRCUITO)  LIKE    '%'||UPPER(p_nome_circuito)||'%'
        WHERE   (DATA_INIZIO_VALID >= NVL(p_data_inizio_valid,DATA_INIZIO_VALID))
        AND     ((p_data_fine_valid     IS   NULL) OR (DATA_FINE_VALID IS NULL) OR (DATA_FINE_VALID  <=   p_data_fine_valid))
        AND     ((p_flg_schermo IS NULL) OR (p_flg_schermo=FLG_SCHERMO) OR FLG_ARENA = 'S')
        AND      FLG_ANNULLATO         =    'N'
        AND     (p_nome_circuito is null or upper(NOME_CIRCUITO)LIKE '%'||upper(p_nome_circuito)||'%')
        ORDER BY CIRCUITO.NOME_CIRCUITO;
    RETURN c_circuito_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'FUNZIONE FU_CERCA_CIRCUITO: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_CERCA_CIRCUITO;

-- --------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_CIRCUITO
--
-- DESCRIZIONE:  Esegue l'aggiornamento di un circuito nel sistema
--
-- OPERAZIONI:
--   Update
--
-- INPUT:
--      p_id_circuito               id del circuito
--      p_nome_circuito             nome del circuito
--      p_descr_circuito            descrizione del circuito
--      p_abbr_nome                 abbreviazione del nome del circuito
--      p_data_inizio_valid         data inizio validita
--      p_data_fine_valid           data fine validita
--      p_flag_atrio                flag che indica se il circuito e composto da atrii
--      p_flag_schermo              flag che indica se il circuito e composto da schermi
--      p_flag_cinema               flag che indica se il circuito e composto da cinema
--      p_flag_sala                 flag che indica se il circuito e composto da sale
--      p_flag_annullato            flag che indica se il circuito e valido
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Update non eseguita: i parametri per l'Update non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Agosto 2009
--
--  MODIFICHE:
--
PROCEDURE PR_MODIFICA_CIRCUITO (p_id_circuito                CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_nome_circuito              CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                                p_descr_circuito             CD_CIRCUITO.DESC_CIRCUITO%TYPE,
                                p_abbr_nome                  CD_CIRCUITO.ABBR_NOME%TYPE,
                                p_data_inizio_valid          CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                                p_data_fine_valid            CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                                p_flag_atrio                 CD_CIRCUITO.FLG_ATRIO%TYPE,
                                p_flag_schermo               CD_CIRCUITO.FLG_SCHERMO%TYPE,
                                p_flag_cinema                CD_CIRCUITO.FLG_CINEMA%TYPE,
                                p_flag_sala                  CD_CIRCUITO.FLG_SALA%TYPE,
                                p_flag_arena                 CD_CIRCUITO.FLG_ARENA%TYPE,
                                p_flag_listino               CD_CIRCUITO.FLG_DEFINITO_A_LISTINO%TYPE,  
                                p_flg_annullato              CD_CIRCUITO.FLG_ANNULLATO%TYPE,
                                p_livello                    CD_CIRCUITO.LIVELLO%TYPE,
                                p_esito                         OUT NUMBER)

IS
--
BEGIN -- PR_MODIFICHE_SALA
--
        p_esito := 1;
          SAVEPOINT SP_PR_MODIFICHE_CIRCUITO;
           -- EFFETTUA L'UPDATE
           UPDATE CD_CIRCUITO
           SET
              NOME_CIRCUITO             = (nvl(p_nome_circuito,NOME_CIRCUITO)),
              DESC_CIRCUITO             = (nvl(p_descr_circuito,DESC_CIRCUITO)),
              ABBR_NOME                 = (nvl(p_abbr_nome,ABBR_NOME)),
              DATA_INIZIO_VALID         = (nvl(p_data_inizio_valid,DATA_INIZIO_VALID)),
              DATA_FINE_VALID           = (nvl(p_data_fine_valid,DATA_FINE_VALID)),
              FLG_ATRIO                 = (nvl(p_flag_atrio,FLG_ATRIO)),
              FLG_CINEMA                = (nvl(p_flag_cinema,FLG_CINEMA)),
              FLG_SALA                  = (nvl(p_flag_sala,FLG_SALA)),
              FLG_SCHERMO               = (nvl(p_flag_schermo,FLG_SCHERMO)),
              FLG_ARENA                 = (nvl(p_flag_arena,FLG_ARENA)),
              FLG_DEFINITO_A_LISTINO    = (nvl(p_flag_listino,FLG_DEFINITO_A_LISTINO)),
              FLG_ANNULLATO             = (nvl(p_flg_annullato,FLG_ANNULLATO)),
              LIVELLO                   = (nvl(p_livello,LIVELLO))
          WHERE ID_CIRCUITO = p_id_circuito;
       --
       p_esito := SQL%ROWCOUNT;

  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Procedura PR_MODIFICA_CIRCUITO: Update non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_MODIFICHE_CIRCUITO;
  END;
---------------------------------------------------------------------------------------
-- Procedura  PR_AGGIORNA_CIRCUITO_BREAK 
-- DESCRIZIONE:  Esegue l'aggiornamento della tavola CD_CIRCUITO_TIPO_BREAK
--              in funzione del valore di p_flg_operazione passato in input.
--              Se p_flg_operazione = I ==> Inserisco
--                                  = D ==> Cancellazione
--                                  = A ==> Annullamento
--
-- OPERAZIONI:
--
-- INPUT:
--      p_id_circuito               id del circuito
--      p_id_tipo_break             identificativo del tipo break
--
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, 26/07/2011
--
--  MODIFICHE:
---------------------------------------------------------------------------------------                                
PROCEDURE PR_AGGIORNA_CIRCUITO_BREAK (p_id_circuito                CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                      p_id_tipo_break              CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                      p_flg_operazione             char,
                                      p_esito					   OUT NUMBER)
IS
v_num_rec NUMBER;
--
BEGIN -- PR_AGGIORNA_CIRCUITO_BREAK
--
        if(p_flg_operazione='I')then
        /*Inserisco nuova occorrenza*/
            select count(1)
            into   v_num_rec  
            from cd_circuito_tipo_break
            where id_circuito = p_id_circuito
            and   id_tipo_break = p_id_tipo_break
            and   flg_annullato = 'N';
            if(v_num_rec = 0)then
            insert into cd_circuito_tipo_break
                (
                id_circuito,
                id_tipo_break
                )
            values
                (
                p_id_circuito,
                p_id_tipo_break
                );
            end if;
            else if (p_flg_operazione='D')then
            /*Cancello occorrenza specificata*/
                delete from cd_circuito_tipo_break
                where id_circuito = p_id_circuito
                and   id_tipo_break = p_id_tipo_break;
                else if (p_flg_operazione='A')then
                /*Annullo occorrenza specificata*/
                    select count(1)
                    into   v_num_rec  
                    from cd_circuito_tipo_break
                    where id_circuito = p_id_circuito
                    and   id_tipo_break = p_id_tipo_break
                    and   flg_annullato = 'S';
                    if(v_num_rec = 0)then
                        update cd_circuito_tipo_break
                        set flg_annullato = 'S'
                        where id_circuito = p_id_circuito
                        and   id_tipo_break = p_id_tipo_break
                        and   flg_annullato = 'N';
                    end if;
                end if;
            end if;
        end if;
        p_esito := 1;
        SAVEPOINT SP_PR_AGGIORNA_CIRCUITO_BREAK;
           
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Procedura PR_AGGIORNA_CIRCUITO_BREAK: Aggiornamento non eseguito:'||sqlerrm);
        p_esito := -1;
        ROLLBACK TO SP_PR_AGGIORNA_CIRCUITO_BREAK;
  END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_CIRCUITO
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id del cinema
-- OUTPUT: Restituisce il dettaglio del circuito
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_CIRCUITO ( p_id_circuito      CD_CIRCUITO.ID_CIRCUITO%TYPE )
                                 RETURN C_CIRCUITO_DETT
IS
   c_circuito_dett_return C_CIRCUITO_DETT;
BEGIN
   OPEN c_circuito_dett_return  -- apre il cursore che conterra il dettaglio del cinema
     FOR
     SELECT ID_CIRCUITO, NOME_CIRCUITO, DESC_CIRCUITO, DATA_INIZIO_VALID,
            DATA_FINE_VALID, ABBR_NOME, FLG_ATRIO, FLG_SCHERMO,
            FLG_CINEMA, FLG_SALA, FLG_ARENA, FLG_DEFINITO_A_LISTINO, LIVELLO
     FROM   CD_CIRCUITO CIRCUITO
     WHERE  CIRCUITO.ID_CIRCUITO    =    p_id_circuito;
RETURN c_circuito_dett_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_DETTAGLIO_CIRCUITO: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_DETTAGLIO_CIRCUITO;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_CIRCUITO
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un circuito dal sistema
--
-- OPERAZIONI:
--  1) Elimina i prodotti di vendita associati (che a sua volta elimina tariffe e ambiti di vendita associati)
--  2) Elimina gli ambiti
--  3) Elimina il circuito stesso
--
-- INPUT:  Id del circuito
--
-- OUTPUT: esito:
--    1  Circuito eliminato con successo
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: 
--      Roberto Barbaro, Teoresi srl, Ottobre 2009
--
--  MODIFICHE:
--     Tommaso D'Anna, Teoresi srl, Novembre 2011
--          Aggiunta eliminazione dei riferimenti su CD_CIRCUITO_TIPO_BREAK che impediva l'eliminazione     
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_CIRCUITO(  p_id_circuito        IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_esito                OUT NUMBER)
IS

v_prdvend_esito     INTEGER;

BEGIN --
     p_esito:= 1;
     SAVEPOINT SP_PR_ELIMINA_CIRCUITO;

     --elimino i prodotti di vendita associati
        FOR PRDVEND IN(
                    SELECT ID_PRODOTTO_VENDITA FROM CD_PRODOTTO_VENDITA
                    WHERE ID_CIRCUITO = p_id_circuito
                    )
        LOOP
            PA_CD_PRODOTTO_VENDITA.PR_ELIMINA_PRODOTTO_VENDITA(PRDVEND.ID_PRODOTTO_VENDITA, v_prdvend_esito);
        END LOOP;

     --elimino gli ambiti di atrio
     DELETE FROM CD_CIRCUITO_ATRIO
     WHERE ID_CIRCUITO = p_id_circuito;

     --elimino gli ambiti di cinema
     DELETE FROM CD_CIRCUITO_CINEMA
     WHERE ID_CIRCUITO = p_id_circuito;

     --elimino gli ambiti di sala
     DELETE FROM CD_CIRCUITO_SALA
     WHERE ID_CIRCUITO = p_id_circuito;

     --elimino gli ambiti di schermo
     DELETE FROM CD_CIRCUITO_SCHERMO
     WHERE ID_CIRCUITO = p_id_circuito;

     --elimino gli ambiti di break
     DELETE FROM CD_CIRCUITO_BREAK
     WHERE ID_CIRCUITO = p_id_circuito;
     
     --elimino le associazioni tra circuito e tipo break
     DELETE FROM CD_CIRCUITO_TIPO_BREAK
     WHERE ID_CIRCUITO = p_id_circuito;     

     -- elimino il circuito stesso
     DELETE FROM CD_CIRCUITO
     WHERE ID_CIRCUITO = p_id_circuito;
     p_esito := SQL%ROWCOUNT;

EXCEPTION
          WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ELIMINA_CIRCUITO: Delete non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO SP_PR_ELIMINA_CIRCUITO;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ANNULLA_CIRCUITO
--
-- DESCRIZIONE:  Esegue l'annullamento di un circuito dal sistema
--
-- OPERAZIONI:
--   1) Annulla gli ambiti ad esso associati
--   2) Annulla i prodotti di vendita associati
--   3) Annulla il circuito stesso
--
-- INPUT:  Id del circuito
--
-- OUTPUT: esito:
--    1  Circuito annullato con successo
--   -1  Annullanto non eseguito: i parametri non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO(  p_id_circuito        IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_esito                OUT NUMBER,
                                p_piani_errati      OUT VARCHAR2)
IS

    v_flg_atrio     CHAR;
    v_flg_cinema    CHAR;
    v_flg_sala      CHAR;
    v_flg_schermo   CHAR;
    v_flg_arena     CHAR;
    v_atrio_esito   NUMBER;
    v_cinema_esito  NUMBER;
    v_sala_esito    NUMBER;
    v_schermo_esito NUMBER;
    v_prdvend_esito NUMBER;

BEGIN --
     p_esito:= 1;
     SAVEPOINT SP_PR_ANNULLA_CIRCUITO;
       -- effettua la selezione degli ambiti da annullare
     SELECT FLG_ATRIO, FLG_CINEMA, FLG_SALA, FLG_SCHERMO, FLG_ARENA
     INTO v_flg_atrio, v_flg_cinema, v_flg_sala, v_flg_schermo, v_flg_arena
     FROM CD_CIRCUITO
     WHERE ID_CIRCUITO = p_id_circuito;

     --annullo i circuiti atrio
     IF(v_flg_atrio='S')THEN
        FOR CIRC IN(
                    SELECT ID_CIRCUITO_ATRIO FROM CD_CIRCUITO_ATRIO
                    WHERE ID_CIRCUITO = p_id_circuito
                    )
        LOOP
            PR_ANNULLA_CIRCUITO_ATRIO(CIRC.ID_CIRCUITO_ATRIO, v_atrio_esito, p_piani_errati);
        END LOOP;
     END IF;

     --annullo i circuiti cinema
     IF(v_flg_cinema='S')THEN
        FOR CIRC IN(
                    SELECT ID_CIRCUITO_CINEMA FROM CD_CIRCUITO_CINEMA
                    WHERE ID_CIRCUITO = p_id_circuito
                    )
        LOOP
            PR_ANNULLA_CIRCUITO_CINEMA(CIRC.ID_CIRCUITO_CINEMA, v_cinema_esito,p_piani_errati);
        END LOOP;
     END IF;

     --annullo i circuiti sala
     IF(v_flg_sala='S')THEN
        FOR CIRC IN(
                    SELECT ID_CIRCUITO_SALA FROM CD_CIRCUITO_SALA
                    WHERE ID_CIRCUITO = p_id_circuito
                    )
        LOOP
            PR_ANNULLA_CIRCUITO_SALA(CIRC.ID_CIRCUITO_SALA, v_sala_esito,p_piani_errati);
        END LOOP;
     END IF;

    --annullo i circuiti schermo
     IF(v_flg_schermo='S')THEN
        FOR CIRC IN(
                    SELECT ID_CIRCUITO_SCHERMO FROM CD_CIRCUITO_SCHERMO
                    WHERE ID_CIRCUITO = p_id_circuito
                    )
        LOOP
            PR_ANNULLA_CIRCUITO_SCHERMO(CIRC.ID_CIRCUITO_SCHERMO, v_schermo_esito, p_piani_errati);
        END LOOP;
     END IF;

     --annullo i circuiti arena
     IF(v_flg_arena='S')THEN
        FOR CIRC IN(
                    SELECT ID_CIRCUITO_SCHERMO FROM CD_CIRCUITO_SCHERMO
                    WHERE ID_CIRCUITO = p_id_circuito
                    )
        LOOP
            PR_ANNULLA_CIRCUITO_SCHERMO(CIRC.ID_CIRCUITO_SCHERMO, v_schermo_esito, p_piani_errati);
        END LOOP;
     END IF;

    -- annullo i prodotti di vendita associati
    FOR PRDVEND IN(
                    SELECT ID_PRODOTTO_VENDITA FROM CD_PRODOTTO_VENDITA
                    WHERE ID_CIRCUITO = p_id_circuito
                    )
        LOOP
            PA_CD_PRODOTTO_VENDITA.PR_ANNULLA_PRODOTTO_VENDITA(PRDVEND.ID_PRODOTTO_VENDITA, v_prdvend_esito);
        END LOOP;

    --annullo il circuito stesso
    UPDATE CD_CIRCUITO
    SET FLG_ANNULLATO='S'
    WHERE ID_CIRCUITO = p_id_circuito
    AND FLG_ANNULLATO='N';

     p_esito := SQL%ROWCOUNT;
EXCEPTION
          WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO: Annullamento non eseguita, verificare la coerenza dei parametri '||SQLERRM);
        ROLLBACK TO SP_PR_ANNULLA_CIRCUITO;
END;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_CINEMA
--
-- DESCRIZIONE:  Esegue l'annullamento di un singolo circuito_cinema dal sistema
--                  dei relativi cinema_vendita, comunicati e prodotti acquistati
--                  se ne esistono
--               Cancella il circuito se non vi sono vendite o acquisti associati
--
-- OPERAZIONI:
--   1) Annulla/cancella il Circuito_Cinema, cinema_vendita, comunicati, prodotti_acquistati
--
-- INPUT:  Id del circuito cinema
--
-- OUTPUT: esito:
--    n     numero di elementi annullati per questo circuito
--          (Indica Circuito_Ambito annullato con successo)
--   -10    indica che il circuito_ambito specificato e' stato eleiminato in quanto
--          assenti ambiti_vendita associati
--   -1  Annullamento/cancellazione non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_CINEMA(p_id_circuito_cinema        IN CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA%TYPE,
                                     p_esito                    OUT NUMBER,
                                     p_piani_errati             OUT VARCHAR2)
IS
    v_id_circuito   CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_id_listino    CD_LISTINO.ID_LISTINO%TYPE;
    v_temp1 INTEGER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_ANNULLA_CIRCUITO_CINEMA;
    SELECT ID_CIRCUITO, ID_LISTINO
    INTO v_id_circuito, v_id_listino
    FROM CD_CIRCUITO_CINEMA
    WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA=p_id_circuito_cinema;
    SELECT COUNT(*)
    INTO v_temp1
    FROM CD_CINEMA_VENDITA
    WHERE CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA=p_id_circuito_cinema;
    --se il circuito e' vuoto lo elimino
    IF(v_temp1=0)THEN
        DELETE FROM CD_CIRCUITO_CINEMA WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA=p_id_circuito_cinema;
        p_esito := -10;
    ELSE -- altrimenti lo annullo insieme a tutti i suoi riferimenti
        FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_CINEMA_VENDITA IN (
                    SELECT CD_CINEMA_VENDITA.ID_CINEMA_VENDITA FROM CD_CINEMA_VENDITA
                    WHERE  CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = p_id_circuito_cinema) AND FLG_ANNULLATO='N')LOOP
            PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1,p_piani_errati);
            p_esito := p_esito + 1;
        END LOOP;
        UPDATE CD_CINEMA_VENDITA
        SET FLG_ANNULLATO='S'
        WHERE CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA=p_id_circuito_cinema
        AND   FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
        UPDATE CD_CIRCUITO_CINEMA
        SET FLG_ANNULLATO='S'
        WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA=p_id_circuito_cinema
        AND   FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
    END IF;
    EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_CINEMA: Annullamento/cancellazione non eseguito: si e'' verificato un problema');
        p_esito:=-1;
        ROLLBACK TO SP_PR_ANNULLA_CIRCUITO_CINEMA;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_ATRIO
--
-- DESCRIZIONE:  Esegue l'annullamento di un singolo circuito_atrio dal sistema
--                  dei relativi atrio_vendita, comunicati e prodotti acquistati
--                  se ne esistono
--               Cancella il circuito se non vi sono vendite o acquisti associati
--
-- OPERAZIONI:
--   1) Annulla/cancella il Circuito_atrio, atrio_vendita, comunicati, prodotti_acquistati
--
-- INPUT:  Id del circuito atrio
--
-- OUTPUT: esito:
--    n     numero di elementi annullati per questo circuito
--          (Indica Circuito_Ambito annullato con successo)
--   -10    indica che il circuito_ambito specificato e' stato eleiminato in quanto
--          assenti ambiti_vendita associati
--   -1  Annullamento/cancellazione non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_ATRIO(p_id_circuito_atrio        IN CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO%TYPE,
                                    p_esito                    OUT NUMBER,
                                    p_piani_errati          OUT VARCHAR2)
IS
    v_id_circuito   CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_id_listino    CD_LISTINO.ID_LISTINO%TYPE;
    v_id_atrio      CD_ATRIO.ID_ATRIO%TYPE;
    v_temp1 INTEGER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_ANNULLA_CIRCUITO_ATRIO;
    SELECT ID_CIRCUITO, ID_LISTINO, ID_ATRIO
    INTO v_id_circuito, v_id_listino, v_id_atrio
    FROM CD_CIRCUITO_ATRIO
    WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO=p_id_circuito_atrio;
    SELECT COUNT(*)
    INTO v_temp1
    FROM CD_ATRIO_VENDITA
    WHERE CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO=p_id_circuito_atrio;
    --se il circuito e' vuoto lo elimino
    IF(v_temp1=0)THEN
        DELETE FROM CD_CIRCUITO_ATRIO WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO=p_id_circuito_atrio;
        p_esito := -10;
    ELSE -- altrimenti lo annullo insieme a tutti i suoi riferimenti
        FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_ATRIO_VENDITA IN (
                    SELECT CD_ATRIO_VENDITA.ID_ATRIO_VENDITA FROM CD_ATRIO_VENDITA
                    WHERE  CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = p_id_circuito_atrio) AND FLG_ANNULLATO='N')LOOP
            PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1,p_piani_errati);
            p_esito := p_esito + 1;
        END LOOP;
        UPDATE CD_ATRIO_VENDITA
        SET FLG_ANNULLATO='S'
        WHERE CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO=p_id_circuito_atrio
        AND   FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
        UPDATE CD_CIRCUITO_ATRIO
        SET FLG_ANNULLATO='S'
        WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO=p_id_circuito_atrio
        AND   FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
        --PA_CD_TARIFFA.PR_ALLINEA_TARIFFA_PER_ELIM(null, v_id_atrio, v_id_circuito, v_temp1);
    END IF;
    EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_ATRIO: Annullamento/cancellazione non eseguito: si e'' verificato un problema');
        p_esito:=-1;
        ROLLBACK TO SP_PR_ANNULLA_CIRCUITO_ATRIO;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_SALA
--
-- DESCRIZIONE:  Esegue l'annullamento di un singolo circuito_sala dal sistema
--                  dei relativi sala_vendita, comunicati e prodotti acquistati
--                  se ne esistono
--               Cancella il circuito se non vi sono vendite o acquisti associati
--
--
-- OPERAZIONI:
--   1) Annulla/cancella il Circuito_Sala, sala_vendita, comunicati, prodotti_acquistati
--
-- INPUT:  Id del circuito sala
--
-- OUTPUT: esito:
--    n     numero di elementi annullati per questo circuito
--          (Indica Circuito_Ambito annullato con successo)
--   -10    indica che il circuito_ambito specificato e' stato eleiminato in quanto
--          assenti ambiti_vendita associati
--   -1  Annullamento/cancellazione non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_SALA(p_id_circuito_sala        IN CD_CIRCUITO_SALA.ID_CIRCUITO_SALA%TYPE,
                                     p_esito                OUT NUMBER,
                                     p_piani_errati         OUT VARCHAR2)
IS
    v_id_circuito   CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_id_listino    CD_LISTINO.ID_LISTINO%TYPE;
    v_id_sala       CD_SALA.ID_SALA%TYPE;
    v_temp1 INTEGER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_ANNULLA_CIRCUITO_SALA;
    SELECT ID_CIRCUITO, ID_LISTINO, ID_SALA
    INTO v_id_circuito, v_id_listino, v_id_sala
    FROM CD_CIRCUITO_SALA
    WHERE CD_CIRCUITO_SALA.ID_CIRCUITO_SALA=p_id_circuito_sala;
    SELECT COUNT(*)
    INTO v_temp1
    FROM CD_SALA_VENDITA
    WHERE CD_SALA_VENDITA.ID_CIRCUITO_SALA=p_id_circuito_sala;
    --se il circuito e' vuoto lo elimino
    IF(v_temp1=0)THEN
        DELETE FROM CD_CIRCUITO_SALA WHERE CD_CIRCUITO_SALA.ID_CIRCUITO_SALA=p_id_circuito_sala;
        p_esito := -10;
    ELSE -- altrimenti lo annullo insieme a tutti i suoi riferimenti
        FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_SALA_VENDITA IN (
                    SELECT CD_SALA_VENDITA.ID_SALA_VENDITA FROM CD_SALA_VENDITA
                    WHERE  CD_SALA_VENDITA.ID_CIRCUITO_SALA = p_id_circuito_sala) AND FLG_ANNULLATO='N')LOOP
            PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1,p_piani_errati);
            p_esito := p_esito + 1;
        END LOOP;
        UPDATE CD_SALA_VENDITA
        SET FLG_ANNULLATO='S'
        WHERE CD_SALA_VENDITA.ID_CIRCUITO_SALA=p_id_circuito_sala
        AND   FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
        UPDATE CD_CIRCUITO_SALA
        SET FLG_ANNULLATO='S'
        WHERE CD_CIRCUITO_SALA.ID_CIRCUITO_SALA=p_id_circuito_sala
        AND   FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
        --PA_CD_TARIFFA.PR_ALLINEA_TARIFFA_PER_ELIM(v_id_sala, null, v_id_circuito, v_temp1);
    END IF;
    EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_SALA: Annullamento/cancellazione non eseguito: si e'' verificato un problema '||SQLERRM);
        p_esito:=-1;
        ROLLBACK TO SP_PR_ANNULLA_CIRCUITO_SALA;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CIRCUITO_SCHERMO
--
-- DESCRIZIONE:  Esegue l'annullamento di un singolo circuito_schermo dal sistema
--                  dei relativi circuiti_break, dei break_vendita, comunicati e
--                  prodotti acquistati, se ne esistono
--               Cancella i circuito se non vi sono vendite o acquisti associati
--               Infine cancella il circuito_schermo se non esistono circuiti_break associati
--
-- OPERAZIONI:
--   1) Annulla/cancella il Circuito_Schermo, circuiti_break ,break_vendita,
--        comunicati, prodotti_acquistati (relativi ai break di vendita naturalmente)
--
-- INPUT:  Id del circuito schermo
--
-- OUTPUT: esito:
--    n     numero di elementi annullati per questo circuito
--          (Indica Circuito_Ambito annullato con successo)
--   -1  Annullamento/cancellazione non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, Maggio 2011
--                  Tentativo di ottimizzazione divindendo i due cicli annidati in due cicli distinti
--              Antonio Colucci, Teoresi srl, 23/06/2011
--                  Adeguamento procedura al nuovo algoritmo per l'annullamento dei
--                  comunicati per una sala. L'obiettivo e migliorare le prestazioni 
--                  delle operazioni 
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CIRCUITO_SCHERMO(p_id_circuito_schermo    IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO%TYPE,
                                      p_esito               OUT NUMBER,
                                      p_piani_errati        OUT VARCHAR2)
IS
    v_id_circuito   CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_id_listino    CD_LISTINO.ID_LISTINO%TYPE;
    v_id_schermo    CD_SCHERMO.ID_SCHERMO%TYPE;
    v_id_sala       CD_SALA.ID_SALA%TYPE;
    v_id_atrio      CD_ATRIO.ID_ATRIO%TYPE;
    v_data_inizio   DATE;
    v_data_fine     DATE;
    v_esito_tar     NUMBER:=0;
    v_temp1         INTEGER:=0;
    v_count         NUMBER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_ANNULLA_CIRCUITO_SCHERMO;
    SELECT distinct
         CD_CIRCUITO_SCHERMO.ID_CIRCUITO, CD_CIRCUITO_SCHERMO.ID_LISTINO, 
         CD_CIRCUITO_SCHERMO.ID_SCHERMO,data_inizio,data_fine,cd_schermo.id_sala
    into v_id_circuito,v_id_listino,v_id_schermo,
         v_data_inizio,v_data_fine,v_id_sala
    FROM CD_CIRCUITO_SCHERMO,cd_listino,cd_schermo
    WHERE CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO=p_id_circuito_schermo
    and   CD_CIRCUITO_SCHERMO.flg_annullato = 'N'
    and   cd_circuito_schermo.id_listino = cd_listino.id_listino
    and   cd_circuito_schermo.id_schermo = cd_schermo.id_schermo;
    /*
    FOR  pippo IN(SELECT CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK FROM   CD_PROIEZIONE, CD_BREAK, CD_CIRCUITO_BREAK
                   WHERE  CD_CIRCUITO_BREAK.ID_CIRCUITO=v_id_circuito AND    CD_CIRCUITO_BREAK.ID_LISTINO=v_id_listino
                   AND    CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK AND    CD_CIRCUITO_BREAK.FLG_ANNULLATO='N'
                   AND    CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE AND CD_PROIEZIONE.ID_SCHERMO =v_id_schermo)LOOP
        BEGIN
            -- seleziono i comunicati relativi al singolo break di vendita
            FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_BREAK_VENDITA IN (
                            SELECT CD_BREAK_VENDITA.ID_BREAK_VENDITA FROM CD_BREAK_VENDITA
                            WHERE  CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = pippo.ID_CIRCUITO_BREAK) AND FLG_ANNULLATO='N'
                            AND COD_DISATTIVAZIONE IS NULL)LOOP
                PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1,p_piani_errati);
                p_esito := p_esito + 1;
            END LOOP;
            --seleziono quindi il break di vendita
            UPDATE CD_BREAK_VENDITA
            SET FLG_ANNULLATO='S'
            WHERE  CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = pippo.ID_CIRCUITO_BREAK
            AND FLG_ANNULLATO='N';
            p_esito := p_esito + SQL%ROWCOUNT;
            --questo il circuito break che non ha break di vendita e che quindi si possono eliminare se ci riesco
            UPDATE CD_CIRCUITO_BREAK
            SET FLG_ANNULLATO='S'
            WHERE  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK = pippo.ID_CIRCUITO_BREAK;
            p_esito := p_esito + SQL%ROWCOUNT;
        END;
    END LOOP;
    */
    /*ANNULLO EVENTUALI COMUNICATI ASSOCIATI*/
    /*for elenco_comunicati in
    (
        select cd_comunicato.id_comunicato
        from
            cd_circuito_break,
            cd_break,cd_proiezione,
            cd_break_vendita,
            cd_comunicato,cd_listino
        where cd_circuito_break.id_circuito = v_id_circuito
        and   cd_circuito_break.id_listino =  v_id_listino
        and   cd_listino.id_listino =  v_id_listino
        and   cd_circuito_break.id_break = cd_break.id_break
        and   cd_break.id_proiezione = cd_proiezione.id_proiezione
        and   cd_proiezione.id_schermo = v_id_schermo
        and   cd_proiezione.data_proiezione between cd_listino.data_inizio and cd_listino.data_fine
        and   cd_proiezione.flg_annullato = 'N'
        and   cd_circuito_break.flg_annullato = 'N'
        and   cd_circuito_break.id_circuito_break = cd_break_vendita.id_circuito_break
        and   cd_break_vendita.flg_annullato = 'N'
        and   cd_comunicato.flg_annullato = 'N'
        and   cd_comunicato.flg_sospeso = 'N'
        and   cd_comunicato.cod_disattivazione is null
        and   cd_comunicato.id_break_vendita = cd_break_vendita.id_break_vendita
    )loop
        PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(elenco_comunicati.ID_COMUNICATO,'PAL',v_temp1,p_piani_errati);
        p_esito := p_esito + 1;
    end loop;*/
    /*ANNULLO COMUNICATI*/
    for elenco in
     (
         select  distinct
                 cd_prodotto_acquistato.id_prodotto_acquistato,
                 cd_sala.id_sala 
         from 
                 cd_comunicato,
                 cd_prodotto_acquistato,
                 cd_sala,
                 cd_cinema,cd_prodotto_vendita
         where   cd_sala.id_sala = v_id_sala
         and     cd_sala.id_cinema = cd_cinema.id_cinema
         and     cd_sala.id_sala = cd_comunicato.id_sala
         and     cd_sala.flg_arena = 'N'
         and     cd_sala.flg_visibile = 'S'
         and     cd_cinema.flg_virtuale = 'N'
         and     cd_comunicato.data_erogazione_prev between v_data_inizio and v_data_fine
         and     cd_comunicato.flg_annullato = 'N'
         and     cd_comunicato.flg_sospeso = 'N'
         and     cd_comunicato.cod_disattivazione is null
         and     cd_comunicato.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
         and     cd_prodotto_acquistato.flg_annullato = 'N'
         and     cd_prodotto_acquistato.flg_sospeso = 'N'
         and     cd_prodotto_acquistato.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita
         and     cd_prodotto_vendita.id_circuito = v_id_circuito
    )loop
        /*select count(1)
         into v_count
         from cd_comunicato com
         where com.id_prodotto_acquistato = elenco.id_prodotto_acquistato
         and   com.id_sala = elenco.id_sala
         and   com.data_erogazione_prev < trunc(sysdate)
         and   com.flg_annullato = 'N'
         and   com.flg_sospeso = 'N'
         and   com.cod_disattivazione is null;*/
         --if v_count =0 then
            pa_cd_prodotto_acquistato.PR_ANNULLA_SALA(elenco.id_prodotto_acquistato,v_data_inizio,v_data_fine,elenco.id_sala,'PAL',p_esito);
         --end if;
    end loop;
    /*ANNULLO BREAK DI VENDITA*/
    update 
          cd_break_vendita
    set   flg_annullato = 'S'
    where id_circuito_break in
    (
      select  cd_circuito_break.id_circuito_break
      from
              cd_circuito_break,
              cd_break,
              cd_proiezione,
              cd_schermo
      where
              cd_proiezione.data_proiezione between v_data_inizio and v_data_fine
      and     cd_proiezione.id_schermo = cd_schermo.id_schermo
      and     cd_schermo.id_sala = v_id_sala
      and     cd_break.id_proiezione = cd_proiezione.id_proiezione
      and     cd_break.id_break = cd_circuito_break.id_break
      and     cd_break.flg_annullato = 'N'
      and     cd_circuito_break.flg_annullato = 'N'
      and     cd_circuito_break.id_circuito = v_id_circuito
    )
    and flg_annullato = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
    update   
            cd_circuito_break
    set flg_annullato = 'S'
    where   id_circuito_break
    in
    (
        select  distinct cd_circuito_break.id_circuito_break--,nome_circuito
        from
                cd_circuito_break,
                cd_break,
                cd_proiezione,
                cd_schermo
        where
                cd_proiezione.data_proiezione between v_data_inizio and v_data_fine
        and     cd_proiezione.id_schermo = cd_schermo.id_schermo
        and     cd_schermo.id_sala = v_id_sala
        and     cd_break.id_proiezione = cd_proiezione.id_proiezione
        and     cd_break.id_break = cd_circuito_break.id_break
        and     cd_break.flg_annullato = 'N'
        and     cd_circuito_break.flg_annullato = 'N'
        and     cd_circuito_break.id_circuito = v_id_circuito
    )
    and flg_annullato = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
    /*
    FOR elenco_circuito_break in
    (
        select cd_circuito_break.id_circuito_break
        from
            cd_circuito_break,
            cd_break,cd_proiezione,cd_listino
        where cd_circuito_break.id_circuito = v_id_circuito
        and   cd_circuito_break.id_listino =  v_id_listino
        and   cd_listino.id_listino = v_id_listino
        and   cd_proiezione.data_proiezione between cd_listino.data_inizio and cd_listino.data_fine  
        and   cd_circuito_break.id_break = cd_break.id_break
        and   cd_break.id_proiezione = cd_proiezione.id_proiezione
        and   cd_proiezione.id_schermo = v_id_schermo
        and   cd_proiezione.flg_annullato = 'N'
        and   cd_circuito_break.flg_annullato = 'N'
    )loop
        UPDATE CD_BREAK_VENDITA
        SET FLG_ANNULLATO='S'
        WHERE  CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = elenco_circuito_break.ID_CIRCUITO_BREAK
        AND FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
        UPDATE CD_CIRCUITO_BREAK
        SET FLG_ANNULLATO='S'
        WHERE  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK = elenco_circuito_break.ID_CIRCUITO_BREAK
        AND FLG_ANNULLATO='N';
        p_esito := p_esito + SQL%ROWCOUNT;
    end loop;
    */
    --annullo circuito_schermo
    UPDATE CD_CIRCUITO_SCHERMO
    SET FLG_ANNULLATO='S'
    WHERE CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO=p_id_circuito_schermo
    AND FLG_ANNULLATO='N';
    p_esito := p_esito + SQL%ROWCOUNT;
    SELECT COUNT(ID_SALA)
    INTO   v_id_sala
    FROM   CD_SCHERMO
    WHERE  CD_SCHERMO.ID_SCHERMO = v_id_schermo;
    IF(v_id_sala>0)THEN
        SELECT ID_SALA
        INTO   v_id_sala
        FROM   CD_SCHERMO
        WHERE  CD_SCHERMO.ID_SCHERMO = v_id_schermo;
        PA_CD_TARIFFA.PR_ALLINEA_TARIFFA_PER_ELIM(v_id_sala, null, v_id_circuito, v_id_listino, v_esito_tar,p_piani_errati);
    ELSE
        SELECT ID_ATRIO
        INTO   v_id_atrio
        FROM   CD_SCHERMO
        WHERE  CD_SCHERMO.ID_SCHERMO = v_id_schermo;
        PA_CD_TARIFFA.PR_ALLINEA_TARIFFA_PER_ELIM(null, v_id_atrio, v_id_circuito, v_id_listino, v_esito_tar,p_piani_errati);
    END IF;
EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_SCHERMO: Annullamento/cancellazione non eseguito: si e'' verificato un problema col circuito '||p_id_circuito_schermo||'    '||sqlerrm);
        p_esito:=-1;
        ROLLBACK TO SP_PR_ANNULLA_CIRCUITO_SCHERMO;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_CINEMA
-- annulla una lista di circuiti invocando ripetutamente la relativa stored procedure
-- questa procedura consente di gestire l'annullamento di piu' circuiti con un'unica transazione
-- INPUT:  l'elenco dei circuiti da annullare
-- OUTPUT: 1  operazione andata a buon fine
--         -1 Si e' verificato un errore, nessun circuito e' stato annullato
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_CINEMA(p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                   p_id_circuito        IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                   p_id_lista_cinema    IN id_cinema_type,
                                   p_esito              OUT NUMBER,
                                   p_piani_errati       OUT VARCHAR2)
IS
 v_temp INTEGER;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_ANN_LISTA_CIRC_CINEMA;
    FOR i IN 1..p_id_lista_cinema.COUNT LOOP
        v_temp:=FU_DAMMI_CIRCUITO_CINEMA(p_id_listino,p_id_circuito,p_id_lista_cinema(i));
        IF(v_temp>0)THEN
            PR_ANNULLA_CIRCUITO_CINEMA(v_temp,p_esito,p_piani_errati);
            IF(p_esito=-1)THEN
                ROLLBACK TO SP_PR_ANN_LISTA_CIRC_CINEMA;
            END IF;
        END IF;
    END LOOP;
    IF(p_esito<>-1)THEN
        p_esito:=1;
    END IF;
EXCEPTION
      WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANN_LISTA_CIRC_CINEMA: Errore durante l''annullamento lista circuiti   '|| SQLERRM);
        ROLLBACK TO SP_PR_ANN_LISTA_CIRC_CINEMA;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_ATRIO
-- annulla una lista di circuiti invocando ripetutamente la relativa stored procedure
-- questa procedura consente di gestire l'annullamento di piu' circuiti con un'unica transazione
-- INPUT:  l'elenco dei circuiti da annullare
-- OUTPUT: 1  operazione andata a buon fine
--         -1 Si e' verificato un errore, nessun circuito e' stato annullato
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_ATRIO(p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                  p_id_circuito         IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_lista_atrii        IN id_atrii_type,
                                  p_esito                OUT NUMBER,
                                  p_piani_errati         OUT NUMBER)
IS
v_temp INTEGER;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_ANN_LISTA_CIRC_ATRIO;
    FOR i IN 1..p_id_lista_atrii.COUNT LOOP
        v_temp:=FU_DAMMI_CIRCUITO_ATRIO(p_id_listino,p_id_circuito,p_id_lista_atrii(i));
        IF(v_temp>0)THEN
            PR_ANNULLA_CIRCUITO_ATRIO(v_temp,p_esito,p_piani_errati);
            IF(p_esito=-1)THEN
                ROLLBACK TO SP_PR_ANN_LISTA_CIRC_ATRIO;
            END IF;
        END IF;
    END LOOP;
    IF(p_esito<>-1)THEN
        p_esito:=1;
    END IF;
EXCEPTION
      WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANN_LISTA_CIRC_ATRIO: Errore durante l''annullamento lista circuiti   '|| SQLERRM);
        ROLLBACK TO SP_PR_ANN_LISTA_CIRC_ATRIO;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_SALA
-- annulla una lista di circuiti invocando ripetutamente la relativa stored procedure
-- questa procedura consente di gestire l'annullamento di piu' circuiti con un'unica transazione
-- INPUT:  l'elenco dei circuiti da annullare
-- OUTPUT: 1  operazione andata a buon fine
--         -1 Si e' verificato un errore, nessun circuito e' stato annullato
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_SALA(p_id_listino            IN CD_LISTINO.ID_LISTINO%TYPE,
                                 p_id_circuito          IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_id_lista_sale        IN id_sale_type,
                                 p_esito                OUT NUMBER,
                                 p_piani_errati         OUT NUMBER)
IS
v_temp INTEGER;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_ANN_LISTA_CIRC_SALA;
    FOR i IN 1..p_id_lista_sale.COUNT LOOP
        v_temp:=FU_DAMMI_CIRCUITO_SALA(p_id_listino,p_id_circuito,p_id_lista_sale(i));
           IF(v_temp>0)THEN
            PR_ANNULLA_CIRCUITO_SALA(v_temp,p_esito,p_piani_errati);
            IF(p_esito=-1)THEN
                ROLLBACK TO SP_PR_ANN_LISTA_CIRC_SALA;
            END IF;
        END IF;
    END LOOP;
    IF(p_esito<>-1)THEN
        p_esito:=1;
    END IF;
EXCEPTION
      WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANN_LISTA_CIRC_SALA: Errore durante l''annullamento lista circuiti   '|| SQLERRM);
        ROLLBACK TO SP_PR_ANN_LISTA_CIRC_SALA;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_SCHERMO
-- annulla una lista di circuiti invocando ripetutamente la relativa stored procedure
-- questa procedura consente di gestire l'annullamento di piu' circuiti con un'unica transazione
-- INPUT:  l'elenco dei circuiti da annullare
-- OUTPUT: 1  operazione andata a buon fine
--         -1 Si e' verificato un errore, nessun circuito e' stato annullato
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_SCHERMO(p_id_listino        IN CD_LISTINO.ID_LISTINO%TYPE,
                                    p_id_circuito       IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_lista_schermi    IN id_schermi_type,
                                    p_esito                OUT NUMBER,
                                    p_piani_errati      OUT VARCHAR2)
IS
v_temp INTEGER;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_ANN_LISTA_CIRC_SCHERMO;
    FOR i IN 1..p_id_lista_schermi.COUNT LOOP
        v_temp:=FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino,p_id_circuito,p_id_lista_schermi(i));
        IF(v_temp>0)THEN
            PR_ANNULLA_CIRCUITO_SCHERMO(v_temp,p_esito, p_piani_errati);
            IF(p_esito=-1)THEN
                ROLLBACK TO SP_PR_ANN_LISTA_CIRC_SCHERMO;
            END IF;
        END IF;
    END LOOP;
    IF(p_esito<>-1)THEN
        p_esito:=1;
    END IF;
EXCEPTION
      WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANN_LISTA_CIRC_SCHERMO: Errore durante l''annullamento lista circuiti   '|| SQLERRM);
        ROLLBACK TO SP_PR_ANN_LISTA_CIRC_SCHERMO;
END;
--------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_LISTA_CIRC_ARENA
-- annulla una lista di circuiti invocando ripetutamente la relativa stored procedure
-- questa procedura consente di gestire l'annullamento di piu' circuiti con un'unica transazione
-- INPUT:  l'elenco dei circuiti da annullare
-- OUTPUT: 1  operazione andata a buon fine
--         -1 Si e' verificato un errore, nessun circuito e' stato annullato
--
--  REALIZZATORE: Antonio Colucci, Teoresi srl, Maggio 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_LISTA_CIRC_ARENA(p_id_listino          IN CD_LISTINO.ID_LISTINO%TYPE,
                                    p_id_circuito       IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_list_arene    IN id_list_type,
                                    p_esito             OUT NUMBER,
                                    p_piani_errati      OUT VARCHAR2)
IS
v_temp         INTEGER;
v_id_schermo   NUMBER;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_ANN_LISTA_CIRC_ARENA;
    FOR i IN 1..p_id_list_arene.COUNT LOOP
        SELECT ID_SCHERMO INTO v_id_schermo FROM CD_SCHERMO WHERE ID_SALA = p_id_list_arene(i);
        v_temp:=FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino,p_id_circuito,v_id_schermo);
        IF(v_temp>0)THEN
            PR_ANNULLA_CIRCUITO_SCHERMO(v_temp,p_esito, p_piani_errati);
            IF(p_esito=-1)THEN
                ROLLBACK TO SP_PR_ANN_LISTA_CIRC_ARENA;
            END IF;
        END IF;
    END LOOP;
    IF(p_esito<>-1)THEN
        p_esito:=1;
    END IF;
EXCEPTION
      WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANN_LISTA_CIRC_ARENA: Errore durante l''annullamento lista circuiti   '|| SQLERRM);
        ROLLBACK TO SP_PR_ANN_LISTA_CIRC_ARENA;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANN_BLOCCO_LISTA_CIRC
-- dati in ingresso un elemco di atrii, schermi, cinema, sale
-- gestisco in un'unica transazione l'annullamento dei relativi circuiti/listino
-- INPUT: id listino, id circuito ed elenchi ambienti dei quali annullare i circuiti/listino
-- OUTPUT: 1 tutto andato a buon fine
--        -1 si e' verificato un errore, nessun circuito annullato
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Settembre 2009
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANN_BLOCCO_LISTA_CIRC( p_id_listino           IN CD_LISTINO.ID_LISTINO%TYPE,
                                    p_id_circuito          IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_list_id_cinema       IN id_cinema_type,
                                    p_list_id_atrii        IN id_atrii_type,
                                    p_list_id_sale         IN id_sale_type,
                                    p_list_id_schermi      IN id_schermi_type,
                                    p_list_id_arene        IN id_list_type,
                                    p_esito                OUT NUMBER,
                                    p_piani_errati         OUT VARCHAR2)
IS
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_ANN_BLOCCO_LISTA_CIRC;
    PR_ANN_LISTA_CIRC_ATRIO(p_id_listino, p_id_circuito, p_list_id_atrii, p_esito,p_piani_errati);
    IF(p_esito<>-1)THEN
        PR_ANN_LISTA_CIRC_SALA(p_id_listino, p_id_circuito, p_list_id_sale, p_esito,p_piani_errati);
        IF(p_esito<>-1)THEN
            PR_ANN_LISTA_CIRC_CINEMA(p_id_listino, p_id_circuito, p_list_id_cinema, p_esito,p_piani_errati);
            IF(p_esito<>-1)THEN
                PR_ANN_LISTA_CIRC_SCHERMO(p_id_listino, p_id_circuito, p_list_id_schermi, p_esito, p_piani_errati);
                IF(p_esito<>-1)THEN
                    PR_ANN_LISTA_CIRC_ARENA(p_id_listino, p_id_circuito, p_list_id_arene, p_esito, p_piani_errati);
                END IF;
            END IF;
        END IF;
    END IF;
    IF(p_esito<>-1)THEN
        p_esito:=1;
    ELSE
        ROLLBACK TO SP_PR_ANN_BLOCCO_LISTA_CIRC;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'Procedura SP_PR_ANN_BLOCCO_LISTA_CIRC: Errore durante l''annullamento in blocco dei listini/circuiti: ' ||sqlerrm );
        ROLLBACK TO SP_PR_ANN_BLOCCO_LISTA_CIRC;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_CINEMA
--
-- DESCRIZIONE:  Esegue il ripristino di un singolo circuito_cinema dal sistema
--                  dei relativi cinema_vendita, comunicati e prodotti acquistati
--                  se ne esistono
--
-- OPERAZIONI:
--   1) Rispristina il Circuito_Cinema, cinema_vendita, comunicati, prodotti_acquistati
--
-- INPUT:  Id del circuito cinema
--
-- OUTPUT: esito:
--    n     numero di elementi ripristinati per questo circuito
--          (Indica Circuito_Ambito ripristinato con successo)
--   -1  Rispristino non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_CINEMA(p_id_circuito_cinema        IN CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA%TYPE,
                                     p_esito                    OUT NUMBER)
IS
    v_temp1 INTEGER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_RECUPERA_CIRCUITO_CINEMA;
    FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_CINEMA_VENDITA IN (
                SELECT CD_CINEMA_VENDITA.ID_CINEMA_VENDITA FROM CD_CINEMA_VENDITA
                WHERE  CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = p_id_circuito_cinema) AND FLG_ANNULLATO='N'
                AND COD_DISATTIVAZIONE IS NULL)LOOP
        PA_CD_COMUNICATO.PR_RECUPERA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1);
        p_esito := p_esito + 1;
    END LOOP;
    UPDATE CD_CINEMA_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA=p_id_circuito_cinema
    AND   FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    UPDATE CD_CIRCUITO_CINEMA
    SET FLG_ANNULLATO='N'
    WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA=p_id_circuito_cinema
    AND   FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;

EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_CINEMA: Annullamento/cancellazione non eseguito: si e'' verificato un problema');
        p_esito:=-1;
        ROLLBACK TO SP_PR_RECUPERA_CIRCUITO_CINEMA;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_ATRIO
--
-- DESCRIZIONE:  Esegue il recupero di un singolo circuito_atrio dal sistema
--                  dei relativi atrio_vendita, comunicati e prodotti acquistati
--                  se ne esistono
--
-- OPERAZIONI:
--   1) Recupera il Circuito_atrio, atrio_vendita, comunicati, prodotti_acquistati
--
-- INPUT:  Id del circuito atrio
--
-- OUTPUT: esito:
--    n     numero di elementi recuperati per questo circuito
--          (Indica Circuito_Ambito recuperato con successo)
--   -1  Recupero non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_ATRIO(p_id_circuito_atrio        IN CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO%TYPE,
                                    p_esito                    OUT NUMBER)
IS
    v_temp1 INTEGER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_RECUPERA_CIRCUITO_ATRIO;
    FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_ATRIO_VENDITA IN (
                SELECT CD_ATRIO_VENDITA.ID_ATRIO_VENDITA FROM CD_ATRIO_VENDITA
                WHERE  CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = p_id_circuito_atrio) AND FLG_ANNULLATO='N'
                AND COD_DISATTIVAZIONE IS NULL)LOOP
        PA_CD_COMUNICATO.PR_RECUPERA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1);
        p_esito := p_esito + 1;
    END LOOP;
    UPDATE CD_ATRIO_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO=p_id_circuito_atrio
    AND   FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    UPDATE CD_CIRCUITO_ATRIO
    SET FLG_ANNULLATO='N'
    WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO=p_id_circuito_atrio
    AND   FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;

EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_ATRIO: Annullamento/cancellazione non eseguito: si e'' verificato un problema');
        p_esito:=-1;
        ROLLBACK TO SP_PR_RECUPERA_CIRCUITO_ATRIO;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_SALA
--
-- DESCRIZIONE:  Esegue il recupero di un singolo circuito_sala dal sistema
--                  dei relativi sala_vendita, comunicati e prodotti acquistati
--                  se ne esistono
--
--
-- OPERAZIONI:
--   1) Recupera il Circuito_Sala, sala_vendita, comunicati, prodotti_acquistati
--
-- INPUT:  Id del circuito sala
--
-- OUTPUT: esito:
--    n     numero di elementi recuperati per questo circuito
--          (Indica Circuito_Ambito recuperato con successo)
--   -1  Recupero non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_SALA(p_id_circuito_sala        IN CD_CIRCUITO_SALA.ID_CIRCUITO_SALA%TYPE,
                                     p_esito                OUT NUMBER)
IS
    v_temp1 INTEGER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_RECUPERA_CIR_SALA;
    FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_SALA_VENDITA IN (
                SELECT CD_SALA_VENDITA.ID_SALA_VENDITA FROM CD_SALA_VENDITA
                WHERE  CD_SALA_VENDITA.ID_CIRCUITO_SALA = p_id_circuito_sala) AND FLG_ANNULLATO='N'
                AND COD_DISATTIVAZIONE IS NULL)LOOP
        PA_CD_COMUNICATO.PR_RECUPERA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1);
        p_esito := p_esito + 1;
    END LOOP;
    UPDATE CD_SALA_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_SALA_VENDITA.ID_CIRCUITO_SALA=p_id_circuito_sala
    AND   FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    UPDATE CD_CIRCUITO_SALA
    SET FLG_ANNULLATO='N'
    WHERE CD_CIRCUITO_SALA.ID_CIRCUITO_SALA=p_id_circuito_sala
    AND   FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;

EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_SALA: Annullamento/cancellazione non eseguito: si e'' verificato un problema');
        p_esito:=-1;
        ROLLBACK TO SP_PR_RECUPERA_CIR_SALA;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CIRCUITO_SCHERMO
--
-- DESCRIZIONE:  Esegue il recupero di un singolo circuito_schermo dal sistema
--                  dei relativi circuiti_break, dei break_vendita, comunicati e
--                  prodotti acquistati, se ne esistono
--
-- OPERAZIONI:
--   1) Recupera il Circuito_Schermo, circuiti_break ,break_vendita,
--        comunicati, prodotti_acquistati (relativi ai break di vendita naturalmente)
--
-- INPUT:  Id del circuito schermo
--
-- OUTPUT: esito:
--    n     numero di elementi recuperati per questo circuito
--          (Indica Circuito_Ambito recuperato con successo)
--   -1  Recupero non eseguito: si e' verificato un problema
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CIRCUITO_SCHERMO(p_id_circuito_schermo    IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO%TYPE,
                                      p_esito               OUT NUMBER)
IS
    v_id_circuito   CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_id_listino    CD_LISTINO.ID_LISTINO%TYPE;
    v_id_schermo    CD_SCHERMO.ID_SCHERMO%TYPE;
    v_temp1 INTEGER:=0;
BEGIN
    p_esito:= 0;
    SAVEPOINT SP_PR_RECUPERA_CIR_SCHERMO;
    SELECT ID_CIRCUITO, ID_LISTINO, ID_SCHERMO
    INTO v_id_circuito, v_id_listino, v_id_schermo
    FROM CD_CIRCUITO_SCHERMO
    WHERE CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO=p_id_circuito_schermo;
    FOR  pippo IN(SELECT  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK FROM   CD_PROIEZIONE, CD_BREAK, CD_CIRCUITO_BREAK
                   WHERE  CD_CIRCUITO_BREAK.ID_CIRCUITO=v_id_circuito AND    CD_CIRCUITO_BREAK.ID_LISTINO=v_id_listino
                   AND    CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK AND    CD_CIRCUITO_BREAK.FLG_ANNULLATO='S'
                   AND    CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE AND CD_PROIEZIONE.ID_SCHERMO =v_id_schermo)LOOP
        BEGIN
            -- seleziono i comunicati relativi al singolo break di vendita
            FOR myC IN( SELECT ID_COMUNICATO FROM CD_COMUNICATO WHERE CD_COMUNICATO.ID_BREAK_VENDITA IN (
                            SELECT CD_BREAK_VENDITA.ID_BREAK_VENDITA FROM CD_BREAK_VENDITA
                            WHERE  CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = pippo.ID_CIRCUITO_BREAK) AND FLG_ANNULLATO='S'
                            AND COD_DISATTIVAZIONE IS NULL)LOOP
                PA_CD_COMUNICATO.PR_RECUPERA_COMUNICATO(myC.ID_COMUNICATO,'PAL',v_temp1);
                p_esito := p_esito + 1;
            END LOOP;
            --seleziono quindi il break di vendita
            UPDATE CD_BREAK_VENDITA
            SET FLG_ANNULLATO='N'
            WHERE  CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = pippo.ID_CIRCUITO_BREAK
            AND FLG_ANNULLATO='S';
            p_esito := p_esito + SQL%ROWCOUNT;
            -- se arrivo qui non potevo cancellare il circuito break, quinid lo annullo
            UPDATE CD_CIRCUITO_BREAK
            SET FLG_ANNULLATO='N'
            WHERE  CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK = pippo.ID_CIRCUITO_BREAK;
            p_esito := p_esito + SQL%ROWCOUNT;
        END;
    END LOOP;

    UPDATE CD_CIRCUITO_SCHERMO
    SET FLG_ANNULLATO='N'
    WHERE CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO=p_id_circuito_schermo
    AND FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Procedura PR_ANNULLA_CIRCUITO_SCHERMO: Annullamento/cancellazione non eseguito: si e'' verificato un problema');
        p_esito:=-1;
        ROLLBACK TO SP_PR_RECUPERA_CIR_SCHERMO;
END;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_CIRCUITO
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i parametri
--
-- INPUT:
--      p_nome_circuito             nome del circuito
--      p_descr_circuito            descrizione del circuito
--      p_abbr_nome                 abbreviazione del nome del circuito
--      p_data_inizio_valid         data inizio validita
--      p_data_fine_valid           data fine validita
--      p_flag_atrio                flag che indica se il circuito e composto da atrii
--      p_flag_schermo              flag che indica se il circuito e composto da schermi
--      p_flag_cinema               flag che indica se il circuito e composto da cinema
--      p_flag_sala                 flag che indica se il circuito e composto da sale

--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_CIRCUITO(p_nome_circuito              CD_CIRCUITO.NOME_CIRCUITO%TYPE,
                            p_descr_circuito             CD_CIRCUITO.DESC_CIRCUITO%TYPE,
                            p_abbr_nome                  CD_CIRCUITO.ABBR_NOME%TYPE,
                            p_data_inizio_valid          CD_CIRCUITO.DATA_INIZIO_VALID%TYPE,
                            p_data_fine_valid            CD_CIRCUITO.DATA_FINE_VALID%TYPE,
                            p_flag_atrio                 CD_CIRCUITO.FLG_ATRIO%TYPE,
                            p_flag_schermo               CD_CIRCUITO.FLG_SCHERMO%TYPE,
                            p_flag_cinema                CD_CIRCUITO.FLG_CINEMA%TYPE,
                            p_flag_sala                  CD_CIRCUITO.FLG_SALA%TYPE)  RETURN VARCHAR2
IS
BEGIN
   IF v_stampa_circuito = 'ON'
   THEN
   RETURN 'NOME_CIRCUITO: '          || p_nome_circuito           || ', ' ||
            'DESCR_CIRCUITO: '          || p_descr_circuito            || ', ' ||
            'ABBR_NOME: '|| p_abbr_nome    || ', ' ||
            'DATA_INIZIO_VALID: '  || p_data_inizio_valid        || ', ' ||
            'DATA_FINE_VALID: ' || p_data_fine_valid        || ', ' ||
            'FLG_ATRIO: '          || p_flag_atrio              || ', ' ||
            'FLG_SCHERMO: '          || p_flag_schermo                   || ', ' ||
            'FLG_CINEMA: '      || p_flag_cinema         || ', '||
            'FLG_SALA: '          || p_flag_sala;
   END IF;
END  FU_STAMPA_CIRCUITO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_CINEMA
-- INPUT:  ID del listino ID del circuito ID del cinema
-- OUTPUT:  ID del circuito cinema se esiste -1 altrimenti
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_CINEMA(p_id_listino   IN CD_CIRCUITO_CINEMA.ID_LISTINO%TYPE,
                                  p_id_circuito  IN CD_CIRCUITO_CINEMA.ID_CIRCUITO%TYPE,
                                  p_id_cinema    IN CD_CIRCUITO_CINEMA.ID_CINEMA%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
BEGIN
    IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_cinema IS NOT NULL) THEN
         SELECT CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
        INTO v_return_value
        FROM CD_CIRCUITO_CINEMA
        WHERE CD_CIRCUITO_CINEMA.ID_LISTINO=p_id_listino
        AND CD_CIRCUITO_CINEMA.ID_CIRCUITO=p_id_circuito
        AND CD_CIRCUITO_CINEMA.ID_CINEMA=p_id_cinema
        AND FLG_ANNULLATO='N';
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_DAMMI_CIRCUITO_CINEMA: Impossibile valutare la richiesta '||SQLERRM);
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_ATRIO
-- INPUT:  ID del listino ID del circuito ID dell'atrio
-- OUTPUT:  ID del circuito atrio se esiste -1 altrimenti
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_ATRIO(p_id_listino   IN CD_CIRCUITO_ATRIO.ID_LISTINO%TYPE,
                                 p_id_circuito  IN CD_CIRCUITO_ATRIO.ID_CIRCUITO%TYPE,
                                 p_id_atrio     IN CD_CIRCUITO_ATRIO.ID_ATRIO%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
BEGIN
    IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_atrio IS NOT NULL) THEN
        SELECT CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
        INTO  v_return_value
        FROM  CD_CIRCUITO_ATRIO
        WHERE CD_CIRCUITO_ATRIO.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_ATRIO.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_ATRIO.ID_ATRIO=p_id_atrio
       AND FLG_ANNULLATO='N';
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_DAMMI_CIRCUITO_ATRIO: Impossibile valutare la richiesta');
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_SALA
-- INPUT:  ID del listino ID del circuito ID della sala
-- OUTPUT:  ID del circuito sala se esiste -1 altrimenti
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_SALA(p_id_listino  IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
                                p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
BEGIN
    IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_sala IS NOT NULL) THEN
        SELECT CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
        INTO  v_return_value
        FROM  CD_CIRCUITO_SALA
        WHERE CD_CIRCUITO_SALA.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_SALA.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_SALA.ID_SALA=p_id_sala
        AND FLG_ANNULLATO='N';
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_DAMMI_CIRCUITO_SALA: Impossibile valutare la richiesta');
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_ARENA
-- INPUT:  ID del listino ID del circuito ID della sala
-- OUTPUT:  ID del circuito sala se esiste -1 altrimenti
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE: Antonio Colucci, Teoresi srl, 28/04/2010
--            Cambiata tabella dove fare la verifica sulla presenza di un'arena in un circuito.
--            In arena vengono trasmessi dei comunicati in degli schermi, non in delle sale
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_ARENA(p_id_listino  IN CD_CIRCUITO_SALA.ID_LISTINO%TYPE,
                                 p_id_circuito IN CD_CIRCUITO_SALA.ID_CIRCUITO%TYPE,
                                 p_id_sala     IN CD_CIRCUITO_SALA.ID_SALA%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
BEGIN
    IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_sala IS NOT NULL) THEN
        SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
        INTO  v_return_value
        FROM  CD_CIRCUITO_SCHERMO
        WHERE CD_CIRCUITO_SCHERMO.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_SCHERMO.ID_SCHERMO IN (SELECT ID_SCHERMO FROM CD_SCHERMO 
                                                 WHERE CD_SCHERMO.ID_SALA = p_id_sala)
        AND FLG_ANNULLATO='N';
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_DAMMI_CIRCUITO_SALA: Impossibile valutare la richiesta');
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_CIRCUITO_SCHERMO
-- INPUT:  ID del listino ID del circuito ID dello schermo
-- OUTPUT:  ID del circuito schermo se esiste -1 altrimenti
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino   IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                   p_id_circuito  IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
                                   p_id_schermo   IN CD_CIRCUITO_SCHERMO.ID_SCHERMO%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
BEGIN
    IF (p_id_listino IS NOT NULL)AND(p_id_circuito IS NOT NULL)AND(p_id_schermo IS NOT NULL) THEN
        SELECT CD_CIRCUITO_SCHERMO.ID_CIRCUITO_SCHERMO
        INTO v_return_value
        FROM  CD_CIRCUITO_SCHERMO
        WHERE CD_CIRCUITO_SCHERMO.ID_LISTINO=p_id_listino
        AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO=p_id_circuito
        AND   CD_CIRCUITO_SCHERMO.ID_SCHERMO=p_id_schermo
        AND FLG_ANNULLATO='N';
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_DAMMI_CIRCUITO_SCHERMO: Impossibile valutare la richiesta '||SQLERRM);
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_AMBITI_CIRCUITO_L
-- INPUT:   ID del listino ID del circuito ID del cinema  ed il flag per il filtro sulla pubblicita' locale
--          l'ID del cinema puo' essere nullo, se e' presente aggiunge un filtro ai suoi soli elementi
-- OUTPUT:  un cursore contenente
--          NomeAmbito, IDAmbito, IDCircuitoAmbito, InfoVendita, TipoAmbito,
--          NomeAS, CinemaPadre
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE Francesco Abbundo, Teoresi srl, Settembre 2009
--           Roberto Barbaro, Teoresi srl, Gennaio 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_AMBITI_CIRCUITO_L(p_id_listino              IN CD_CIRCUITO_SCHERMO.ID_LISTINO%TYPE,
                                    p_id_circuito              IN CD_CIRCUITO_SCHERMO.ID_CIRCUITO%TYPE,
                                    p_id_cinema                IN CD_CINEMA.ID_CINEMA%TYPE )
            RETURN C_ELENCO_AMBITI
IS
    v_return_value  C_ELENCO_AMBITI;
    v_niente        VARCHAR2(240):='   ';
    v_ambiti        tipo_nome_ambiti;
    v_flg_cinema    VARCHAR2(240);
    v_flg_atrio     VARCHAR2(240);
    v_flg_sala      VARCHAR2(240);
    v_flg_schermo   VARCHAR2(240);
    v_flg_arena     VARCHAR2(240);
    v_flg_vendita_pubb_locale  CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE:=null;
    v_id_cinema     CD_CINEMA.ID_CINEMA%TYPE:=p_id_cinema;
    v_temp          VARCHAR2(240);
BEGIN
    v_ambiti(1):='CINEMA';
    v_ambiti(2):='ATRIO';
    v_ambiti(3):='SALA';
    v_ambiti(4):='SCHERMO_SALA';
    v_ambiti(5):='SCHERMO_ATRIO';
    v_ambiti(6):='ARENA';
    SELECT NOME_CIRCUITO
    INTO   v_temp
    FROM   CD_CIRCUITO
    WHERE  ID_CIRCUITO=p_id_circuito;
    IF(v_temp='Locale')THEN
        v_flg_vendita_pubb_locale:='S';
        v_id_cinema:=null;
    END IF;
    SELECT FLG_CINEMA, FLG_ATRIO, FLG_SALA, FLG_SCHERMO, FLG_ARENA
    INTO v_flg_cinema, v_flg_atrio, v_flg_sala, v_flg_schermo, v_flg_arena
    FROM    CD_CIRCUITO
    WHERE   CD_CIRCUITO.ID_CIRCUITO =p_id_circuito
    AND     (CD_CIRCUITO.FLG_ANNULLATO IS NULL OR CD_CIRCUITO.FLG_ANNULLATO='N');
    OPEN v_return_value
        FOR
        SELECT C1.NOME_CINEMA NomeAmbito, C1.ID_CINEMA IDAmbito, PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_CINEMA(p_id_listino,p_id_circuito,C1.ID_CINEMA) IDCircuitoAmbito,
            PA_CD_LISTINO.FU_CINEMA_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito,C1.ID_CINEMA) InfoVendita,v_ambiti(1) TipoAmbito,v_niente NomeAS,v_niente CinemaPadre,
            (SELECT COMUNE FROM CD_COMUNE WHERE ID_COMUNE = C1.ID_COMUNE) comune
        FROM CD_CINEMA C1
        WHERE C1.ID_CINEMA >0
        AND v_flg_cinema<>'N'
        AND C1.FLG_ANNULLATO='N'
        AND C1.ID_CINEMA=NVL(v_id_cinema,C1.ID_CINEMA)
        AND C1.FLG_VENDITA_PUBB_LOCALE = nvl(v_flg_vendita_pubb_locale, C1.FLG_VENDITA_PUBB_LOCALE)
        UNION
        SELECT C1.DESC_ATRIO NomeAmbito, C1.ID_ATRIO IDAmbito, PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_ATRIO(p_id_listino,p_id_circuito,C1.ID_ATRIO) IDCircuitoAmbito,
            PA_CD_LISTINO.FU_ATRIO_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito,C1.ID_ATRIO) InfoVendita,v_ambiti(2) TipoAmbito,
            v_niente NomeAS,PA_CD_CINEMA.FU_DAMMI_NOME_CINEMA(C1.ID_CINEMA) CinemaPadre,
            (SELECT COMUNE FROM CD_COMUNE, CD_CINEMA WHERE CD_COMUNE.ID_COMUNE = CD_CINEMA.ID_COMUNE AND C1.ID_CINEMA = CD_CINEMA.ID_CINEMA) comune
        FROM CD_ATRIO C1
        WHERE C1.ID_ATRIO >0
        AND v_flg_atrio<>'N'
        AND C1.FLG_ANNULLATO='N'
        AND C1.ID_ATRIO IN( SELECT ID_ATRIO FROM CD_ATRIO WHERE CD_ATRIO.ID_CINEMA=NVL(v_id_cinema,CD_ATRIO.ID_CINEMA)
                            AND    CD_ATRIO.ID_CINEMA IN(SELECT ID_CINEMA FROM CD_CINEMA WHERE FLG_VENDITA_PUBB_LOCALE= NVL(v_flg_vendita_pubb_locale, FLG_VENDITA_PUBB_LOCALE))
                           )
        UNION
        SELECT C1.NOME_SALA NomeAmbito, C1.ID_SALA IDAmbito, PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_SALA(p_id_listino,p_id_circuito,C1.ID_SALA) IDCircuitoAmbito,
            PA_CD_LISTINO.FU_SALA_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito,C1.ID_SALA) InfoVendita,v_ambiti(3) TipoAmbito,
            v_niente NomeAS,PA_CD_CINEMA.FU_DAMMI_NOME_CINEMA(C1.ID_CINEMA) CinemaPadre,
            (SELECT COMUNE FROM CD_COMUNE, CD_CINEMA WHERE CD_COMUNE.ID_COMUNE = CD_CINEMA.ID_COMUNE AND C1.ID_CINEMA = CD_CINEMA.ID_CINEMA) comune
        FROM CD_SALA C1
        WHERE C1.ID_SALA >0
        AND v_flg_sala<>'N'
        AND C1.FLG_ARENA<>'S'
        AND C1.FLG_ANNULLATO='N'
        AND C1.ID_SALA IN(  SELECT ID_SALA FROM CD_SALA WHERE  CD_SALA.ID_CINEMA=NVL(v_id_cinema,CD_SALA.ID_CINEMA)
                            AND    CD_SALA.ID_CINEMA IN(SELECT ID_CINEMA FROM CD_CINEMA WHERE FLG_VENDITA_PUBB_LOCALE= NVL(v_flg_vendita_pubb_locale, FLG_VENDITA_PUBB_LOCALE))
                         )
        UNION
        SELECT C1.DESC_SCHERMO NomeAmbito, C1.ID_SCHERMO IDAmbito, PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino,p_id_circuito,C1.ID_SCHERMO) IDCircuitoAmbito,
            PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito,C1.ID_SCHERMO) InfoVendita,v_ambiti(4) TipoAmbito,
            PA_CD_SALA.FU_DAMMI_NOME_SALA(C1.ID_SALA) NomeAS,PA_CD_CINEMA.FU_DAMMI_NOME_CINEMA_AS(C1.ID_SALA,2) CinemaPadre,
            (SELECT COMUNE FROM CD_COMUNE, CD_CINEMA, CD_SALA WHERE CD_COMUNE.ID_COMUNE = CD_CINEMA.ID_COMUNE AND CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA AND C1.ID_SALA = CD_SALA.ID_SALA) comune
        FROM CD_SCHERMO C1
        WHERE C1.ID_SCHERMO >0
        AND C1.FLG_SALA<>'N'
        AND v_flg_schermo<>'N'
        AND C1.FLG_ANNULLATO='N'
        AND C1.ID_SALA IN(SELECT ID_SALA FROM CD_SALA WHERE CD_SALA.ID_CINEMA=NVL(v_id_cinema,CD_SALA.ID_CINEMA)
                          AND    CD_SALA.ID_CINEMA IN(SELECT ID_CINEMA FROM CD_CINEMA WHERE FLG_VENDITA_PUBB_LOCALE= NVL(v_flg_vendita_pubb_locale, FLG_VENDITA_PUBB_LOCALE))
                          /*Recupero solo gli schermi in genere che non appartengono ad Arene*/
                          AND    FLG_ARENA = 'N'
                         )
        UNION
        SELECT C1.DESC_SCHERMO NomeAmbito, C1.ID_SCHERMO IDAmbito, PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_SCHERMO(p_id_listino,p_id_circuito,C1.ID_SCHERMO) IDCircuitoAmbito,
            PA_CD_LISTINO.FU_SCHERMO_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito,C1.ID_SCHERMO) InfoVendita,v_ambiti(5) TipoAmbito,
            PA_CD_ATRIO.FU_DAMMI_NOME_ATRIO(C1.ID_ATRIO) NomeAS,PA_CD_CINEMA.FU_DAMMI_NOME_CINEMA_AS(C1.ID_ATRIO,1) CinemaPadre,
            (SELECT COMUNE FROM CD_COMUNE, CD_CINEMA, CD_ATRIO WHERE CD_COMUNE.ID_COMUNE = CD_CINEMA.ID_COMUNE AND CD_ATRIO.ID_CINEMA = CD_CINEMA.ID_CINEMA AND C1.ID_ATRIO = CD_ATRIO.ID_ATRIO) comune
        FROM CD_SCHERMO C1
        WHERE C1.ID_SCHERMO >0
        AND C1.FLG_SALA='N'
        AND v_flg_schermo<>'N'
        AND C1.FLG_ANNULLATO='N'
        AND C1.ID_SALA IN(SELECT ID_SALA FROM CD_SALA WHERE CD_SALA.ID_CINEMA=NVL(v_id_cinema,CD_SALA.ID_CINEMA)
                          AND    CD_SALA.ID_CINEMA IN(SELECT ID_CINEMA FROM CD_CINEMA WHERE FLG_VENDITA_PUBB_LOCALE= NVL(v_flg_vendita_pubb_locale, FLG_VENDITA_PUBB_LOCALE))
                         )
        UNION
        SELECT C1.NOME_SALA NomeAmbito, C1.ID_SALA IDAmbito, PA_CD_CIRCUITO.FU_DAMMI_CIRCUITO_ARENA(p_id_listino,p_id_circuito,C1.ID_SALA) IDCircuitoAmbito,
            PA_CD_LISTINO.FU_ARENA_IN_CIRCUITO_LISTINO(p_id_listino,p_id_circuito,C1.ID_SALA) InfoVendita,v_ambiti(6) TipoAmbito,
            v_niente NomeAS,PA_CD_CINEMA.FU_DAMMI_NOME_CINEMA(C1.ID_CINEMA) CinemaPadre,
            (SELECT COMUNE FROM CD_COMUNE, CD_CINEMA WHERE CD_COMUNE.ID_COMUNE = CD_CINEMA.ID_COMUNE AND C1.ID_CINEMA = CD_CINEMA.ID_CINEMA) comune
        FROM CD_SALA C1
        WHERE C1.ID_SALA >0
        AND v_flg_arena<>'N'
        AND C1.FLG_ARENA<>'N'
        AND C1.FLG_ANNULLATO='N'
        AND C1.ID_SALA IN(  SELECT ID_SALA FROM CD_SALA WHERE  CD_SALA.ID_CINEMA=NVL(v_id_cinema,CD_SALA.ID_CINEMA)
                            AND    CD_SALA.ID_CINEMA IN(SELECT ID_CINEMA FROM CD_CINEMA WHERE FLG_VENDITA_PUBB_LOCALE= NVL(v_flg_vendita_pubb_locale, FLG_VENDITA_PUBB_LOCALE))
                         )
        ORDER BY CinemaPadre,Comune, NomeAS, NomeAmbito,TipoAmbito ;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            OPEN v_return_value -- restituisco un cursore vuoto valido
                FOR
                SELECT C1.NOME_CINEMA NomeAmbito, C1.ID_CINEMA IDAmbito, C1.ID_CINEMA IDCircuitoAmbito,
                    C1.ID_CINEMA InfoVendita,v_ambiti(1) TipoAmbito,v_niente NomeAS,v_niente CinemaPadre, null
                FROM CD_CINEMA C1
                WHERE C1.ID_CINEMA = -9990;
            RETURN v_return_value;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_ELENCO_AMBITI_CIRCUITO_L: Impossibile valutare la richiesta');
END FU_ELENCO_AMBITI_CIRCUITO_L;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_AMBITI_CIRCUITO_T
-- INPUT:  ID della tariffa e ID del circuito ID del cinema
--          l'ID del cinema puo' essere nullo, se e' presente aggiunge un filtro ai suoi soli elementi
-- OUTPUT:  un cursore contenente
--          Nome Ambito, ID Ambito, ID_Circuito_AMBITO, Info di vendita, Tipo Ambito,
--          NomeAtrioSala, NomeCinemaPadre
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_AMBITI_CIRCUITO_T(p_id_tariffa   IN CD_TARIFFA.ID_TARIFFA%TYPE,
                                   p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                   p_id_cinema    IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN C_ELENCO_AMBITI
IS
    v_id_listino CD_TARIFFA.ID_LISTINO%TYPE;
    v_return_value C_ELENCO_AMBITI;
BEGIN
    SELECT CD_TARIFFA.ID_LISTINO
    INTO v_id_listino
    FROM    CD_TARIFFA
    WHERE   CD_TARIFFA.ID_TARIFFA = p_id_tariffa;
    v_return_value:=PA_CD_CIRCUITO.FU_ELENCO_AMBITI_CIRCUITO_L(v_id_listino,p_id_circuito,p_id_cinema);
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            OPEN v_return_value -- restituisco un cursore vuoto valido
                FOR
                SELECT C1.NOME_CINEMA NomeAmbito, C1.ID_CINEMA IDAmbito, C1.ID_CINEMA IDCircuitoAmbito,
                    C1.ID_CINEMA InfoVendita, 'TipoAmbito','NomeAS','CinemaPadre', null
                FROM CD_CINEMA C1
                WHERE C1.ID_CINEMA = -9990;
            RETURN v_return_value;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_ELENCO_AMBITI_CIRCUITO_T: Impossibile valutare la richiesta');
END FU_ELENCO_AMBITI_CIRCUITO_T;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_CIRCUITO
-- INPUT:  ID del circuito di cui si vuole il nome
-- OUTPUT:  il nome del circuito
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_CIRCUITO(p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
            RETURN VARCHAR2
IS
    v_return_value CD_CIRCUITO.NOME_CIRCUITO%TYPE:='--';
BEGIN
    IF (p_id_circuito IS NOT NULL) THEN
        SELECT CD_CIRCUITO.NOME_CIRCUITO
        INTO  v_return_value
        FROM  CD_CIRCUITO
        WHERE CD_CIRCUITO.ID_CIRCUITO=p_id_circuito;
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '--';
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_DAMMI_NOME_CIRCUITO: Impossibile valutare la richiesta');
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_VERIFICA_CIRCUITO_VUOTO
-- INPUT:  ID del listino ID del circuito
-- OUTPUT:  n numero di elementi ancora presenti nel circuito (0 il circuito e' vuoto)
--          -1 si e' verificato un errore
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_CIRCUITO_VUOTO(p_id_listino   IN CD_LISTINO.ID_LISTINO%TYPE,
                                    p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
            RETURN INTEGER
IS
    v_return_value INTEGER:=0;
    myCur PA_CD_CIRCUITO.C_ELENCO_AMBITI;
    myRec PA_CD_CIRCUITO.R_ELENCO_AMBITI;
BEGIN
    IF (p_id_circuito IS NOT NULL AND p_id_listino IS NOT NULL) THEN
        myCur:= PA_CD_CIRCUITO.FU_ELENCO_AMBITI_CIRCUITO_L(p_id_listino,p_id_circuito,NULL);
        LOOP
            FETCH myCur into myRec;
            EXIT WHEN myCur%NOTFOUND;
            IF(myRec.a_infor_vendita>=0 and myRec.a_id_circuito_ambito>0)THEN
                v_return_value:=v_return_value+1 ;
            END IF;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Elementi ancora presenti nel circuito '||v_return_value);
        CLOSE myCur;
    END IF;
    /*
    IF(v_return_value=0) THEN
        UPDATE CD_PRODOTTO_VENDITA
        SET FLG_ANNULLATO='S'
        WHERE CD_PRODOTTO_VENDITA.ID_CIRCUITO=v_id_circuito;
    END IF;
    RETURN v_return_value;
    */
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_VERIFICA_CIRCUITO_VUOTO: Impossibile valutare la richiesta');
            v_return_value:=-1;
            RETURN v_return_value;
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CIRCUITO_VENDUTO
--
--  La funzione restituisce il numero di comunicati associati al circuito
--
-- INPUT:  ID del circuito
-- OUTPUT:  n numero di circuiti venduti
--          -1 si e' verificato un errore
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CIRCUITO_VENDUTO(p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
                             RETURN INTEGER
IS
    v_return_value INTEGER:=0;
BEGIN

    SELECT COUNT(1)
    INTO v_return_value
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_VENDITA IN
        (SELECT ID_PRODOTTO_VENDITA
         FROM CD_PRODOTTO_VENDITA
         WHERE ID_CIRCUITO = p_id_circuito);

    RETURN v_return_value;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_CIRCUITO_VENDUTO: Impossibile valutare la richiesta '||sqlerrm);
            v_return_value:=-1;
            RETURN v_return_value;
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CIRCUITO_TIPO_BREAK
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CIRCUITO_TIPO_BREAK(p_id_circuito  IN CD_CIRCUITO.ID_CIRCUITO%TYPE)
                             RETURN C_CIRCUITO_BREAK IS
    v_return_value C_CIRCUITO_BREAK;
BEGIN
    open v_return_value
    for
        select  id_circuito,
                cd_circuito_tipo_break.id_tipo_break,
                desc_tipo_break,
                'S' associato
        from    cd_circuito_tipo_break,cd_tipo_break
        where   cd_circuito_tipo_break.id_circuito = p_id_circuito
        and     cd_circuito_tipo_break.flg_annullato = 'N'
        and     cd_circuito_tipo_break.id_tipo_break = cd_tipo_break.id_tipo_break
        union   
        select  p_id_circuito id_circuito,
                id_tipo_break,
                desc_tipo_break,
                'N' associato
        from    cd_tipo_break
        where   id_tipo_break not in 
                (
                select  cd_circuito_tipo_break.id_tipo_break
                from    cd_circuito_tipo_break
                where   cd_circuito_tipo_break.id_circuito = p_id_circuito
                and     cd_circuito_tipo_break.flg_annullato = 'N'
                ) ;
    RETURN v_return_value;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_CIRCUITO_TIPO_BREAK: Impossibile valutare la richiesta '||sqlerrm);
END; 
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_CIRCUITI
-- --------------------------------------------------------------------------------------------
-- INPUT 
--          p_id_listino        Id del listino da stampare
--          p_id_circuito       Id del circuito da stampare   
-- OUTPUT 
--          Restituisce i dettagli per la stampa del circuito
--
-- REALIZZATORE
--          Tommaso D'Anna, Teoresi s.r.l. 18 Luglio 2011
-- MODIFICHE
--          Tommaso D'Anna, Teoresi s.r.l. 8 Novembre 2011
--              -   Inserita una decode in modo che, se non e selezionato un circuito,
--                  non vengano mostrati i circuiti che comprendono tutte le sale, come
--                  Target, Segui il Film...
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_CIRCUITI(
                                p_id_listino    CD_LISTINO.ID_LISTINO%TYPE,
                                p_id_circuito   CD_CIRCUITO.ID_CIRCUITO%TYPE 
                           )
                                RETURN C_CIRCUITO_STAMPA
IS
   C_RETURN C_CIRCUITO_STAMPA;
BEGIN
    OPEN C_RETURN
        FOR
            SELECT
                CD_LISTINO.ID_LISTINO,
                CD_LISTINO.DESC_LISTINO,
                CD_CIRCUITO.ID_CIRCUITO,
                CD_CIRCUITO.NOME_CIRCUITO,
                CD_COMUNE.ID_COMUNE,
                CD_COMUNE.COMUNE,
                CD_PROVINCIA.ID_PROVINCIA,
                CD_PROVINCIA.PROVINCIA,
                CD_REGIONE.ID_REGIONE,
                CD_REGIONE.NOME_REGIONE,
                CD_CINEMA.ID_CINEMA,
                CD_CINEMA.NOME_CINEMA,
                CD_SALA.ID_SALA,
                CD_SALA.NOME_SALA,
                CD_CIRCUITO.FLG_DEFINITO_A_LISTINO,
                CD_CIRCUITO.FLG_ARENA
            FROM 
                CD_CIRCUITO_SCHERMO,
                CD_CIRCUITO,
                CD_SCHERMO,
                CD_SALA,
                CD_CINEMA,
                CD_COMUNE,
                CD_PROVINCIA,
                CD_REGIONE,
                CD_LISTINO
            -- Sezione JOIN --      
            WHERE   CD_CIRCUITO_SCHERMO.ID_CIRCUITO     = CD_CIRCUITO.ID_CIRCUITO
            AND     CD_CIRCUITO_SCHERMO.ID_SCHERMO      = CD_SCHERMO.ID_SCHERMO
            AND     CD_CIRCUITO_SCHERMO.ID_LISTINO      = CD_LISTINO.ID_LISTINO
            AND     CD_SCHERMO.ID_SALA                  = CD_SALA.ID_SALA
            AND     CD_SALA.ID_CINEMA                   = CD_CINEMA.ID_CINEMA
            AND     CD_CINEMA.ID_COMUNE                 = CD_COMUNE.ID_COMUNE
            AND     CD_COMUNE.ID_PROVINCIA              = CD_PROVINCIA.ID_PROVINCIA
            AND     CD_PROVINCIA.ID_REGIONE             = CD_REGIONE.ID_REGIONE
            -- Sezione FLAG --
            AND     CD_CIRCUITO_SCHERMO.FLG_ANNULLATO   = 'N'
            AND     CD_CIRCUITO.FLG_ANNULLATO           = 'N'
            AND     CD_SALA.FLG_VISIBILE                = 'S'
            AND     CD_CINEMA.FLG_ANNULLATO             = 'N'
            AND     CD_CINEMA.FLG_VIRTUALE              = 'N'
            -- Sezione FILTRI --
            AND     CD_CIRCUITO_SCHERMO.ID_LISTINO      = nvl ( p_id_listino, CD_CIRCUITO_SCHERMO.ID_LISTINO )
            AND     CD_CIRCUITO_SCHERMO.ID_CIRCUITO     = nvl ( p_id_circuito, CD_CIRCUITO_SCHERMO.ID_CIRCUITO )
            AND     CD_CIRCUITO.LIVELLO                 > decode( p_id_circuito, null, 0, -4 )
            ORDER BY
                    CD_LISTINO.DATA_INIZIO, 
                    CD_CIRCUITO.NOME_CIRCUITO,  
                    CD_CINEMA.NOME_CINEMA, 
                    CD_COMUNE.COMUNE,
                    CD_SALA.NOME_SALA;
        RETURN C_RETURN;        
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_STAMPA_CIRCUITI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_STAMPA_CIRCUITI;

END PA_CD_CIRCUITO; 
/

