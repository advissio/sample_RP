CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_BREAK IS

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_BREAK
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo break nel sistema
--
-- OPERAZIONI:
--	 1) Controlla se si vuole procedere con inserimento manuale od tramite sequence dell'id_break
--   2) Nela caso di inserimento manuale controlla che non esistano altri break con lo stesso id
--   3) Memorizza il break (CD_BREAK)
--
-- INPUT:
--      p_nome_break                nome del break
--      p_secondi_assegnati         numero dei secondi assegnati
--      p_id_proiezione             id della proiezione
--      p_id_tipo_break             id del tipo break
--
-- OUTPUT: esito:
--    n (>0)  L'id del break inserito
--   -11 Inserimento non eseguito: si e' verificato un errore
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Abbundo Francesco, Teoresi srl, Agosto 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_BREAK (p_nome_break         CD_BREAK.NOME_BREAK%TYPE,
                              p_secondi_nominali   CD_BREAK.SECONDI_NOMINALI%TYPE,
                              p_id_proiezione      CD_BREAK.ID_PROIEZIONE%TYPE,
                              p_id_tipo_break      CD_BREAK.ID_TIPO_BREAK%TYPE,
                              p_esito                OUT NUMBER)
IS
BEGIN
    SAVEPOINT SP_PR_INSERISCI_BREAK;
  --  DBMS_OUTPUT.PUT_LINE('Sono qui...ora');
     p_esito := PA_CD_BREAK.FU_ESISTE_BREAK(ABS(p_id_proiezione),p_id_tipo_break);
    -- DBMS_OUTPUT.PUT_LINE('Sono qui...e basta - '||p_esito);
  --   DBMS_OUTPUT.PUT_LINE('p_id_proiezione:>'||ABS(p_id_proiezione)||'<');
    IF(p_esito=0)THEN
        INSERT INTO CD_BREAK
            (NOME_BREAK,
             SECONDI_NOMINALI,
             ID_PROIEZIONE,
             ID_TIPO_BREAK,
             FLG_ANNULLATO)
           VALUES
             (p_nome_break,
              p_secondi_nominali,
              ABS(p_id_proiezione),
              p_id_tipo_break,
              'N');
        SELECT CD_BREAK_SEQ.CURRVAL
        INTO   p_esito
        FROM   DUAL;
    END IF;
    --DBMS_OUTPUT.PUT_LINE('Sono qui...fine');
EXCEPTION
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_INSERISCI_BREAK: Insert non eseguita, si e'' verificato un errore '
                                ||FU_STAMPA_BREAK(  p_nome_break,p_secondi_nominali,ABS(p_id_proiezione),p_id_tipo_break)
                                ||'-errore:'||sqlerrm);
        ROLLBACK TO SP_PR_INSERISCI_BREAK;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_BREAK
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un break dal sistema
--
-- OPERAZIONI:
--   3) Elimina il break
--
-- INPUT:
--      p_id_break                id del break
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
PROCEDURE PR_ELIMINA_BREAK(  p_id_break            IN CD_BREAK.ID_BREAK%TYPE,
                             p_esito            OUT NUMBER)
IS
BEGIN -- PR_ELIMINA_BREAK
--

p_esito     := 1;

     --
          SAVEPOINT ann_del;

       -- EFFETTUA L'ELIMINAZIONE
       DELETE FROM CD_BREAK
       WHERE ID_BREAK = p_id_break;
       --

       p_esito := SQL%ROWCOUNT;

  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_ELIMINA_BREAK: Delete non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO ann_del;

   END;


 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_BREAK
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i parametri
--
-- INPUT:
--      p_nome_break                nome del break
--      p_secondi_assegnati         numero dei secondi assegnati
--      p_id_proiezione             id della proiezione
--      p_id_tipo_break             id del tipo break
--      p_hh_prev                   ora prevista della proiezione del break
--      p_mm_prev                   minuto previsto della proiezione della break
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_STAMPA_BREAK    (p_nome_break          CD_BREAK.NOME_BREAK%TYPE,
                             p_secondi_nominali    CD_BREAK.SECONDI_NOMINALI%TYPE,
                             p_id_proiezione       CD_BREAK.ID_PROIEZIONE%TYPE,
                             p_id_tipo_break       CD_BREAK.ID_TIPO_BREAK%TYPE)  RETURN VARCHAR2
IS

BEGIN

IF v_stampa_break = 'ON'

    THEN

     RETURN 'NOME_BREAK: '          || p_nome_break           || ', ' ||
            'SECONDI_NOMINALI: '|| p_secondi_nominali || ', ' ||
            'ID_PROIEZIONE: '  || p_id_proiezione        || ', ' ||
            'ID_TIPO_BREAK: ' || p_id_tipo_break;


END IF;

END  FU_STAMPA_BREAK;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_TIPO_BREAK
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo tipo break nel sistema, e genera anche i nuovi break
--               Vedi documentazione PR_GENERA_NUOVI_BREAK
-- OPERAZIONI:
--   1) Inserisce/ripristina il tipo break
--
-- INPUT:
--      p_desc_tipo_break       descrizione del tipo break
--      p_rif_orario_trasm      orario di riferimento
--      p_durata_secondi        durata espressa in secondi
--      p_data_inizio           data inizio validita
--      p_data_fine             data fine validita
--
-- OUTPUT: esito:
--    id_tipo_break del record appena inserito
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
--  REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_TIPO_BREAK(p_desc_tipo_break     CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                                  p_progr_trasm         CD_TIPO_BREAK.PROGR_TRASMISSIONE%TYPE,
                                  p_durata_secondi      CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                                  p_data_inizio         CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                                  p_data_fine           CD_TIPO_BREAK.DATA_FINE%TYPE,
                                  p_flg_locale          CD_TIPO_BREAK.FLG_LOCALE%TYPE,
                                  p_esito               OUT NUMBER)
IS
    v_esito INTEGER;
BEGIN
    SAVEPOINT SP_PR_INSERISCI_TIPO_BREAK;
    INSERT INTO CD_TIPO_BREAK
         (DESC_TIPO_BREAK,
          PROGR_TRASMISSIONE,
          DURATA_SECONDI,
          FLG_ANNULLATO,
          DATA_INIZIO,
          DATA_FINE,
          FLG_LOCALE)
       VALUES
         (p_desc_tipo_break,
          p_progr_trasm,
          p_durata_secondi,
          'N',
          p_data_inizio,
          p_data_fine,
          p_flg_locale);
    SELECT CD_TIPO_BREAK_SEQ.CURRVAL
    INTO   p_esito
    FROM   DUAL;
    PA_CD_BREAK.PR_GENERA_NUOVI_BREAK (p_esito,v_esito);
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20015, 'PROCEDURA PR_INSERISCI_TIPO_BREAK: Insert non eseguita, si e'' verificato un errore '
            ||FU_STAMPA_TIPO_BREAK(p_desc_tipo_break,p_durata_secondi,p_data_inizio,p_data_fine,p_flg_locale)||'  '||SQLERRM);
        ROLLBACK TO SP_PR_INSERISCI_TIPO_BREAK;
END;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_TIPO_BREAK
--
-- DESCRIZIONE:  Esegue l'aggiornamento di un tipo break
--
-- OPERAZIONI:
--   Update
--
-- INPUT:
--      p_desc_tipo_break       descrizione del tipo break
--      p_rif_orario_trasm      orario di riferimento
--      p_durata_secondi        durata espressa in secondi
--      p_data_inizio           data inizio validita
--      p_data_fine             data fine validita
--
-- OUTPUT: esito:
--    1  Tipo Break modificato
--   -1  Update non eseguita: c'e' stato un errore
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_TIPO_BREAK    (p_id_tipo_break     CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                     p_desc_tipo_break   CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                                     p_progr_trasm       CD_TIPO_BREAK.PROGR_TRASMISSIONE%TYPE,
                                     p_durata_secondi    CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                                     p_data_inizio       CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                                     p_data_fine         CD_TIPO_BREAK.DATA_FINE%TYPE,
                                     p_flg_locale        CD_TIPO_BREAK.FLG_LOCALE%TYPE,
                                     p_esito             OUT NUMBER)
IS
BEGIN
    SAVEPOINT SP_PR_MODIFICA_TIPO_BREAK;
    UPDATE CD_TIPO_BREAK
        SET
            DESC_TIPO_BREAK = (nvl(p_desc_tipo_break, DESC_TIPO_BREAK)),
            PROGR_TRASMISSIONE = (nvl(p_progr_trasm, PROGR_TRASMISSIONE)),
            DURATA_SECONDI = (nvl(p_durata_secondi, DURATA_SECONDI)),
            DATA_INIZIO = (nvl(p_data_inizio, DATA_INIZIO)),
            DATA_FINE = (nvl(p_data_fine, DATA_FINE)),
            FLG_LOCALE = (NVL(p_flg_locale, FLG_LOCALE))
        WHERE ID_TIPO_BREAK = p_id_tipo_break;
    p_esito := 1;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_MODIFICA_TIPO_BREAK: Update non eseguita, si e'' verificato un errore. '
                                    ||FU_STAMPA_TIPO_BREAK(p_desc_tipo_break, p_durata_secondi, p_data_inizio,p_data_fine,p_flg_locale));
        ROLLBACK TO SP_PR_MODIFICA_TIPO_BREAK;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_TIPO_BREAK
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un tipo break dal sistema
--               Nel caso in cui esistano Break Associati a questo tipo break
--               la cancellazione e' solo logica
--
-- OPERAZIONI:
--   3) Elimina/Annulla  il tipo break
--
-- INPUT:
--      p_id_tipo_break       id del tipo break
--
-- OUTPUT: esito:
--    1  tipo break eliminato
--    2  tipo break annullato
--   -1  Eliminazione/Annullamento non eseguito: c'e' stato un problema in fase di cancellazione
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Agosto 2009
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_TIPO_BREAK( p_id_tipo_break   IN CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                 p_esito           OUT NUMBER)
IS
    v_count_brk_ass INTEGER:=0;
BEGIN
    SELECT COUNT(*)
    INTO v_count_brk_ass
    FROM   CD_BREAK
    WHERE  CD_BREAK.ID_TIPO_BREAK=p_id_tipo_break;
    SAVEPOINT SP_PR_ELIMINA_TIPO_BREAK;
    IF(v_count_brk_ass=0)THEN
        DELETE FROM CD_TIPO_BREAK
        WHERE  ID_TIPO_BREAK = p_id_tipo_break;
        p_esito:=1;
    ELSE
        UPDATE CD_TIPO_BREAK
        SET    FLG_ANNULLATO = 'S'
        WHERE  ID_TIPO_BREAK = p_id_tipo_break
        AND    FLG_ANNULLATO = 'N';
        p_esito:=2;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20015, 'Procedura PR_ELIMINA_TIPO_BREAK: Delete non eseguita, si e'' verificato un errore.');
        p_esito:=-1;
        ROLLBACK TO SP_PR_ELIMINA_TIPO_BREAK;
END;

 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_TIPO_BREAK
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i parametri
--
-- INPUT:
--      p_desc_tipo_break       descrizione del tipo break
--      p_rif_orario_trasm      orario di riferimento
--      p_durata_secondi        durata espressa in secondi
--      p_data_inizio           data inizio validita
--      p_data_fine             data fine validita
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_TIPO_BREAK(p_desc_tipo_break   CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                              p_durata_secondi    CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                              p_data_inizio       CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                              p_data_fine         CD_TIPO_BREAK.DATA_FINE%TYPE,
                              p_flg_locale        CD_TIPO_BREAK.FLG_LOCALE%TYPE
                              )RETURN VARCHAR2
IS
BEGIN
IF v_stampa_tipo_break = 'ON'
    THEN
     RETURN 'DESC_TIPO_BREAK: '    || p_desc_tipo_break       || ', ' ||
            'DURATA_SECONDI: '     || p_durata_secondi        || ', ' ||
            'DATA_INIZIO: '        || p_data_inizio           || ', ' ||
            'DATA_FINE: '          || p_data_fine             || ', ' ||
            'FLG_LOCALE'           || p_flg_locale;

END IF;

END  FU_STAMPA_TIPO_BREAK;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESISTE_BREAK
-- DESCRIZIONE:  la funzione controlla l'esistenza una proiezione nel sistema
--
-- OUTPUT: l'id del break secondo i parametri specificati se esiste
--         0 se non esiste
-- INPUT:
--      p_id_proiezione       id della proiezione
--      p_id_tipo_break       id del tipo break
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_ESISTE_BREAK(p_id_proiezione                 CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                         p_id_tipo_break                 CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE
                         ) RETURN INTEGER
IS

v_id_break     INTEGER;

BEGIN

    --DBMS_OUTPUT.PUT_LINE('FUNCTION IN FU_ESISTE_BREAK');
    --DBMS_OUTPUT.PUT_LINE('FUNCTION IN FU_ESISTE_BREAK: '||p_id_proiezione||' '||p_id_tipo_break);

    SELECT   COUNT(*)
    INTO     v_id_break
    FROM     CD_BREAK
    WHERE    ID_PROIEZIONE       =   p_id_proiezione
    AND      ID_TIPO_BREAK       =   p_id_tipo_break;

    IF(v_id_break>0)THEN
        SELECT   ID_BREAK
        INTO     v_id_break
        FROM     CD_BREAK
        WHERE    ID_PROIEZIONE       =   p_id_proiezione
        AND      ID_TIPO_BREAK       =   p_id_tipo_break;
    END IF;

    RETURN v_id_break;

EXCEPTION
         WHEN NO_DATA_FOUND THEN
         RETURN 0;

END FU_ESISTE_BREAK;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_TIPO_BREAK
-- INPUT:  Id del tipo break
-- OUTPUT: Restituisce il dettaglio del tipo break
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_TIPO_BREAK (p_id_tipo_break      CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE )
                               RETURN C_DETTAGLIO_TIPO_BREAK
IS
    c_tipo_break_return C_DETTAGLIO_TIPO_BREAK;
BEGIN
    OPEN c_tipo_break_return  -- apre il cursore dettaglio del tipo break
        FOR
            SELECT  ID_TIPO_BREAK, DESC_TIPO_BREAK, PROGR_TRASMISSIONE, DURATA_SECONDI, DATA_INIZIO, DATA_FINE, FLG_LOCALE
            FROM    CD_TIPO_BREAK
            WHERE   ID_TIPO_BREAK = p_id_tipo_break
            AND     FLG_ANNULLATO = 'N';
    RETURN c_tipo_break_return;
EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20015, 'FUNZIONE FU_DETTAGLIO_TIPO_BREAK: SI E'' VERIFICATO UN ERRORE');
END FU_DETTAGLIO_TIPO_BREAK;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_TIPO_BREAK
-- INPUT:  Criteri di ricerca dei tipi break
-- OUTPUT: Restituisce i tipi break che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_TIPO_BREAK(p_id_tipo_break      CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                             p_desc_tipo_break    CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
                             p_progr_trasm        CD_TIPO_BREAK.PROGR_TRASMISSIONE%TYPE,
                             p_durata_secondi     CD_TIPO_BREAK.DURATA_SECONDI%TYPE,
                             p_data_inizio        CD_TIPO_BREAK.DATA_INIZIO%TYPE,
                             p_data_fine          CD_TIPO_BREAK.DATA_FINE%TYPE ,
                             p_flg_locale         CD_TIPO_BREAK.FLG_LOCALE%TYPE
                             )RETURN C_TIPO_BREAK
IS
    c_tipo_break_return C_TIPO_BREAK;
BEGIN
    OPEN c_tipo_break_return
        FOR
            SELECT  TB.ID_TIPO_BREAK, TB.DESC_TIPO_BREAK,
                    TB.PROGR_TRASMISSIONE, TB.DURATA_SECONDI,
                    TB.DATA_INIZIO, TB.DATA_FINE, TB.FLG_LOCALE
            FROM    CD_TIPO_BREAK TB
            WHERE   TB.ID_TIPO_BREAK     = NVL(p_id_tipo_break, TB.ID_TIPO_BREAK)
                AND TB.DESC_TIPO_BREAK   LIKE '%'||NVL(p_desc_tipo_break, TB.DESC_TIPO_BREAK)||'%'
                AND TB.PROGR_TRASMISSIONE = NVL(p_progr_trasm, TB.PROGR_TRASMISSIONE)
                AND TB.DURATA_SECONDI    = NVL(p_durata_secondi, TB.DURATA_SECONDI)
                AND TB.DATA_INIZIO       = NVL(p_data_inizio, TB.DATA_INIZIO)
                AND ((TB.DATA_FINE = NVL(p_data_fine, TB.DATA_FINE)) OR (TB.DATA_FINE IS NULL))
                AND TB.FLG_ANNULLATO     = 'N'
                AND TB.FLG_LOCALE        = NVL(p_flg_locale, TB.FLG_LOCALE)
                ORDER BY TB.ID_TIPO_BREAK;
    RETURN c_tipo_break_return;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20015, 'FUNZIONE FU_CERCA_TIPO_BREAK: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '
                                           ||FU_STAMPA_TIPO_BREAK(p_desc_tipo_break, p_durata_secondi, p_data_inizio, p_data_fine,p_flg_locale));
END FU_CERCA_TIPO_BREAK;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GENERA_NUOVI_BREAK
-- seleziono tutte le proiezioni che cadono nell'intevallo di validita' del tipo_break passato
-- e per ognuno di essi genero un break.
-- Inserisco anche i break nelle composizioni circuito/listino
-- per tutte le proiezioni che insistono su schermi che si trovano in un circuito/listino
--
-- INPUT:  l'id della nuova tipologia di break
-- OUTPUT: n numero di break generati
--         -1 si e' verificato un errore, nessun break generato
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Agosto 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_GENERA_NUOVI_BREAK (p_id_tipo_break IN  CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                 p_esito         OUT INTEGER)
IS
    v_esito_ins_break    NUMBER;
    v_esito_comp_break   NUMBER;
    v_break_count        INTEGER:=0;
    v_list_break         pa_cd_listino.id_break_type;
BEGIN
    SAVEPOINT SP_FU_GENERA_NUOVI_BREAK;
    FOR myData IN(SELECT   CD_PROIEZIONE.DATA_PROIEZIONE, CD_TIPO_BREAK.DESC_TIPO_BREAK,
                           CD_TIPO_BREAK.DURATA_SECONDI, CD_PROIEZIONE.ID_PROIEZIONE, CD_TIPO_BREAK.ID_TIPO_BREAK
                  FROM     CD_PROIEZIONE, CD_TIPO_BREAK
                  WHERE    CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN TRUNC(GREATEST(CD_TIPO_BREAK.DATA_INIZIO,SYSDATE)) AND NVL(CD_TIPO_BREAK.DATA_FINE,CD_PROIEZIONE.DATA_PROIEZIONE)
                  AND      CD_TIPO_BREAK.ID_TIPO_BREAK   =  p_id_tipo_break) LOOP
        PA_CD_BREAK.PR_INSERISCI_BREAK(myData.DATA_PROIEZIONE||'_'||myData.DESC_TIPO_BREAK,
                        myData.DURATA_SECONDI,myData.ID_PROIEZIONE,myData.ID_TIPO_BREAK,v_esito_ins_break);
        IF(v_esito_ins_break>0)THEN
            --creo la lista dei break che sto inserendo
            FOR myCL IN(SELECT DISTINCT CD_CIRCUITO_SCHERMO.ID_LISTINO, CD_CIRCUITO_SCHERMO.ID_CIRCUITO
                          FROM   CD_LISTINO, CD_PROIEZIONE, CD_CIRCUITO_SCHERMO
                          WHERE  CD_CIRCUITO_SCHERMO.ID_SCHERMO= CD_PROIEZIONE.ID_SCHERMO
                          AND    CD_PROIEZIONE.ID_PROIEZIONE=myData.ID_PROIEZIONE
                          AND    CD_LISTINO.ID_LISTINO=CD_CIRCUITO_SCHERMO.ID_LISTINO
                          AND    CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE) LOOP
                v_list_break(1) :=  v_esito_ins_break;
                v_break_count:=v_break_count+1;
                PA_CD_LISTINO.PR_COMPONI_LISTINO_BREAK(myCL.id_listino, myCL.id_circuito, v_list_break, v_esito_comp_break);
            END LOOP;
        END IF;
    END LOOP;
    p_esito:=v_break_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20015, 'FUNZIONE FU_GENERA_NUOVI_BREAK: si e'' verificato un errore '||SQLERRM);
        p_esito:=-1;
        ROLLBACK TO SP_FU_GENERA_NUOVI_BREAK;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_GENERA_BREAK_PROIEZIONE
-- genera i break relativi a tutti i tipi break esistenti per la proiezione
-- ed eventualmente genera anche i circuiti break relativi
--
-- INPUT:  l'id della proiezione
--          id dello schermo su cui insiste la proiezione
--          la data della proiezione.
-- OUTPUT: 1 break generati
--         -1 si e' verificato un errore, nessun break generato
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Agosto 2009
--
-- MODIFICHE  Roberto Barbaro, Teoresi srl, Settembre 2009
--            Francesco Abbundo, Teoresi srl, Settembre 2009 (Introdotta la gestione della pubblicita' locale)
--            Antonio Colucci, Teoresi srl, Agosto 2010
--                  modificato meccanismo di recupero informazioni sulla pubblicita locale nei cinema
--            Antonio Colucci, Teoresi srl, 5/11/2010
--                  inserito controllo per la creazione del break di tipo Summer solo per 
--                  quegli schermi appartenenti ad Arene
--            Antonio Colucci, Teoresi srl, 08/07/2011
--                  Modificato meccanismo di creazione delle associazioni circuito-break
--                  in funzione dei tipi break associati ai circuiti
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_GENERA_BREAK_PROIEZIONE (p_id_proiezione   IN  CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                      p_id_schermo      IN  CD_SCHERMO.ID_SCHERMO%TYPE,
                                      p_data_proiezione IN  CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                      p_esito         OUT INTEGER)
IS
    v_id_break          CD_BREAK.ID_BREAK%TYPE;
    v_esito_ins_break   NUMBER;
    v_flag_vpl          CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE:='N';
    v_flag_cpl          CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE%TYPE:='N';
    v_temp              INTEGER;
    v_id_circuito_break CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK%TYPE;
    v_count_arena       INTEGER;
BEGIN
    SAVEPOINT SP_PR_GENERA_BREAK_PROIEZIONE;
    p_esito := 1;
    --Verifico che lo sia una Arena
    SELECT COUNT(1) 
    INTO v_count_arena
    FROM CD_SALA,CD_SCHERMO
    WHERE 
         CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
    AND  CD_SALA.FLG_ARENA = 'S'
    AND  cd_schermo.id_schermo =  p_id_schermo;
    SELECT CD_CINEMA.FLG_VENDITA_PUBB_LOCALE, CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE
    INTO   v_flag_vpl, v_flag_cpl
    FROM   CD_CINEMA,cd_sala,cd_schermo
        WHERE  cd_sala.id_cinema = cd_cinema.id_cinema
        and	   cd_schermo.id_sala =cd_sala.id_sala
        and	   cd_schermo.id_schermo = p_id_schermo;        
    FOR tipo_break in (SELECT ID_TIPO_BREAK, DURATA_SECONDI, DESC_TIPO_BREAK
                       FROM   CD_TIPO_BREAK
                       WHERE  CD_TIPO_BREAK.DATA_INIZIO<=p_data_proiezione
                       AND    NVL(CD_TIPO_BREAK.DATA_FINE,p_data_proiezione) >= p_data_proiezione)LOOP
        v_id_break := PA_CD_BREAK.FU_ESISTE_BREAK(p_id_proiezione, tipo_break.id_tipo_break);
        IF(v_id_break <= 0) THEN --non esiste
            IF(tipo_break.desc_tipo_break<>'Locale')THEN
                /*Il Top Spot deve essere creato SEMPRE...sia sulle arene che sugli schermi standard*/
                IF((tipo_break.ID_TIPO_BREAK<>24 and v_count_arena=0) or tipo_break.ID_TIPO_BREAK = 5)THEN--Controllo che non si tratti di Summer Break
                    PA_CD_BREAK.PR_INSERISCI_BREAK(p_data_proiezione||'_'||tipo_break.desc_tipo_break,  -- Crea un break per proiezione - tipo break
                    tipo_break.durata_secondi,p_id_proiezione,tipo_break.id_tipo_break,v_esito_ins_break);
                ELSE
                    /*Controllo che lo schermo in quetione sia un'arena oppure no
                    per la creazione dei break summer*/
                    if(v_count_arena>0 and tipo_break.ID_TIPO_BREAK=24)then
                        PA_CD_BREAK.PR_INSERISCI_BREAK(p_data_proiezione||'_'||tipo_break.desc_tipo_break,  -- Crea un break per proiezione - tipo break
                        tipo_break.durata_secondi,p_id_proiezione,tipo_break.id_tipo_break,v_esito_ins_break);
                    end if;
                END IF;
                
            ELSE
                IF(v_flag_vpl='S') THEN
                    IF(v_flag_cpl='N')THEN
                        tipo_break.durata_secondi:=0;
                    END IF;
                    PA_CD_BREAK.PR_INSERISCI_BREAK(p_data_proiezione||'_'||tipo_break.desc_tipo_break,  -- Crea un break per proiezione - tipo break
                          tipo_break.durata_secondi,p_id_proiezione,tipo_break.id_tipo_break,v_esito_ins_break);
                END IF;
            END IF;
        ELSE
            v_esito_ins_break:=v_id_break;
        END IF;
            
    END LOOP;
    FOR myLC IN 
        (
        select  cd_break.id_break,
                cd_circuito_tipo_break.id_circuito,
                cd_circuito_schermo.id_listino
        from    cd_listino,
                cd_break,
                cd_proiezione,
                cd_circuito_schermo,
                cd_circuito_tipo_break
        where   p_data_proiezione between cd_listino.data_inizio and cd_listino.data_fine
        and     cd_proiezione.data_proiezione = p_data_proiezione
        and     cd_proiezione.flg_annullato = 'N'
        and     cd_proiezione.id_schermo = p_id_schermo
        and     cd_break.id_proiezione = cd_proiezione.id_proiezione
        and     cd_circuito_schermo.id_listino = cd_listino.id_listino
        and     cd_circuito_schermo.id_schermo = p_id_schermo
        and     cd_circuito_schermo.flg_annullato = 'N'
        and     cd_circuito_schermo.id_circuito = cd_circuito_tipo_break.id_circuito
        and     cd_circuito_tipo_break.flg_annullato = 'N'
        and     cd_circuito_tipo_break.id_tipo_break = cd_break.id_tipo_break
        ) LOOP
            SELECT COUNT(*)
            INTO   v_temp
            FROM   CD_CIRCUITO_BREAK
            WHERE  CD_CIRCUITO_BREAK.ID_BREAK=myLC.id_break
            AND    CD_CIRCUITO_BREAK.ID_CIRCUITO=myLC.ID_CIRCUITO
            AND    CD_CIRCUITO_BREAK.ID_LISTINO=myLC.ID_LISTINO
            and    CD_CIRCUITO_BREAK.flg_annullato = 'N';
            IF(v_temp=0)THEN
                INSERT INTO CD_CIRCUITO_BREAK          -- effettua l'inserimento
                (ID_BREAK, ID_CIRCUITO, ID_LISTINO)
                VALUES
                (myLC.id_break, myLC.ID_CIRCUITO, myLC.ID_LISTINO);
                 SELECT CD_CIRCUITO_BREAK_SEQ.CURRVAL
                 INTO   v_id_circuito_break
                 FROM   DUAL;
                 PA_CD_TARIFFA.PR_REFRESH_TARIFFE_BR(myLC.ID_LISTINO,myLC.ID_CIRCUITO,v_id_circuito_break,p_data_proiezione);
            END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20015, 'PROCEDURE PR_GENERA_BREAK_PROIEZIONE: si e'' verificato un errore '||SQLERRM);
        p_esito:=-1;
        ROLLBACK TO SP_PR_GENERA_BREAK_PROIEZIONE;
END;
/*
PROCEDURE PR_GENERA_BREAK_PRO_TEMP (p_id_proiezione   IN  CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                    p_id_schermo      IN  CD_SCHERMO.ID_SCHERMO%TYPE,
                                    p_data_proiezione IN  CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                    p_esito         OUT INTEGER)
IS
    v_id_break          CD_BREAK.ID_BREAK%TYPE;
    v_esito_ins_break   NUMBER;
    v_flag_vpl          CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE:='N';
    v_flag_cpl          CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE%TYPE:='N';
    v_temp              INTEGER;
    v_id_circuito_break CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK%TYPE;
    v_count_arena       INTEGER;
BEGIN
    SAVEPOINT SP_PR_GENERA_BREAK_PRO_TEMP;
    p_esito := 1;
    --Verifico che lo sia una Arena
    SELECT COUNT(1) 
    INTO v_count_arena
    FROM CD_SALA,CD_SCHERMO
    WHERE 
         CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
    AND  CD_SALA.FLG_ARENA = 'S'
    AND  cd_schermo.id_schermo =  p_id_schermo;
    SELECT CD_CINEMA.FLG_VENDITA_PUBB_LOCALE, CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE
    INTO   v_flag_vpl, v_flag_cpl
    FROM   CD_CINEMA,cd_sala,cd_schermo
        WHERE  cd_sala.id_cinema = cd_cinema.id_cinema
        and	   cd_schermo.id_sala =cd_sala.id_sala
        and	   cd_schermo.id_schermo = p_id_schermo;        
    FOR tipo_break in (SELECT ID_TIPO_BREAK, DURATA_SECONDI, DESC_TIPO_BREAK
                       FROM   CD_TIPO_BREAK
                       WHERE  CD_TIPO_BREAK.DATA_INIZIO<=p_data_proiezione
                       AND    NVL(CD_TIPO_BREAK.DATA_FINE,p_data_proiezione) >= p_data_proiezione)LOOP
        v_id_break := PA_CD_BREAK.FU_ESISTE_BREAK(p_id_proiezione, tipo_break.id_tipo_break);
        IF(v_id_break <= 0) THEN --non esiste
            IF(tipo_break.desc_tipo_break<>'Locale')THEN
            */
                /*Il Top Spot deve essere creato SEMPRE...sia sulle arene che sugli schermi standard*/
               /* IF((tipo_break.ID_TIPO_BREAK<>24 and v_count_arena=0) or tipo_break.ID_TIPO_BREAK = 5)THEN--Controllo che non si tratti di Summer Break
                    PA_CD_BREAK.PR_INSERISCI_BREAK(p_data_proiezione||'_'||tipo_break.desc_tipo_break,  -- Crea un break per proiezione - tipo break
                    tipo_break.durata_secondi,p_id_proiezione,tipo_break.id_tipo_break,v_esito_ins_break);
                ELSE*/
                    /*Controllo che lo schermo in quetione sia un'arena oppure no
                    per la creazione dei break summer*/
                   /* if(v_count_arena>0 and tipo_break.ID_TIPO_BREAK=24)then
                        PA_CD_BREAK.PR_INSERISCI_BREAK(p_data_proiezione||'_'||tipo_break.desc_tipo_break,  -- Crea un break per proiezione - tipo break
                        tipo_break.durata_secondi,p_id_proiezione,tipo_break.id_tipo_break,v_esito_ins_break);
                    end if;
                END IF;
                
            ELSE
                IF(v_flag_vpl='S') THEN
                    IF(v_flag_cpl='N')THEN
                        tipo_break.durata_secondi:=0;
                    END IF;
                    PA_CD_BREAK.PR_INSERISCI_BREAK(p_data_proiezione||'_'||tipo_break.desc_tipo_break,  -- Crea un break per proiezione - tipo break
                          tipo_break.durata_secondi,p_id_proiezione,tipo_break.id_tipo_break,v_esito_ins_break);
                END IF;
            END IF;
        ELSE
            v_esito_ins_break:=v_id_break;
        END IF;
            
    END LOOP;
    FOR myLC IN 
        (
        select  cd_break.id_break,
                cd_circuito_tipo_break.id_circuito,
                cd_circuito_schermo.id_listino
        from    cd_listino,
                cd_break,
                cd_proiezione,
                cd_circuito_schermo,
                cd_circuito_tipo_break
        where   p_data_proiezione between cd_listino.data_inizio and cd_listino.data_fine
        and     cd_proiezione.data_proiezione = p_data_proiezione
        and     cd_proiezione.flg_annullato = 'N'
        and     cd_proiezione.id_schermo = p_id_schermo
        and     cd_break.id_proiezione = cd_proiezione.id_proiezione
        and     cd_circuito_schermo.id_listino = cd_listino.id_listino
        and     cd_circuito_schermo.id_schermo = p_id_schermo
        and     cd_circuito_schermo.flg_annullato = 'N'
        and     cd_circuito_schermo.id_circuito = cd_circuito_tipo_break.id_circuito
        and     cd_circuito_tipo_break.flg_annullato = 'N'
        and     cd_circuito_tipo_break.id_tipo_break = cd_break.id_tipo_break
        ) LOOP
            SELECT COUNT(*)
            INTO   v_temp
            FROM   CD_CIRCUITO_BREAK
            WHERE  CD_CIRCUITO_BREAK.ID_BREAK=myLC.id_break
            AND    CD_CIRCUITO_BREAK.ID_CIRCUITO=myLC.ID_CIRCUITO
            AND    CD_CIRCUITO_BREAK.ID_LISTINO=myLC.ID_LISTINO
            and    CD_CIRCUITO_BREAK.flg_annullato = 'N';
            IF(v_temp=0)THEN
                INSERT INTO CD_CIRCUITO_BREAK          -- effettua l'inserimento
                (ID_BREAK, ID_CIRCUITO, ID_LISTINO)
                VALUES
                (myLC.id_break, myLC.ID_CIRCUITO, myLC.ID_LISTINO);
                 SELECT CD_CIRCUITO_BREAK_SEQ.CURRVAL
                 INTO   v_id_circuito_break
                 FROM   DUAL;
                 PA_CD_TARIFFA.PR_REFRESH_TARIFFE_BR(myLC.ID_LISTINO,myLC.ID_CIRCUITO,v_id_circuito_break,p_data_proiezione);
            END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20015, 'PROCEDURE PR_GENERA_BREAK_PROIEZIONE: si e'' verificato un errore '||SQLERRM);
        p_esito:=-1;
        ROLLBACK TO SP_PR_GENERA_BREAK_PRO_TEMP;
END PR_GENERA_BREAK_PRO_TEMP;*/
--
END PA_CD_BREAK; 
/

