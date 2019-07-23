CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_COMPONI_SCHERMI AS
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_COMP_SCHERMI
-- DESCRIZIONE:  restituisce, raggruppati per periodo, le sale accomunate
--               da proiezioni uguali. i dati di ingresso devono essere correttamente formattati
--               altrimenti l'output potrebbe essere errato
-- OUTPUT: cursore contenente i seguenti valori per riga
--    a_numero_sale           rappresenta il numero di sale che, nel periodo di riferimento, sono
--                            accomunate dalla stessa proiezione
--    a_numero_comunicati     il numero di comunicati che compongono la proiezione
--    a_data_ininzio          data inizio del periodo di riferimento
--    a_data_fine             data fine del periodo di riferimento
--    a_proid                 una stringa contenente le informazioni di composizione della proiezione
--
-- INPUT:
--    p_id_circuito           id del circuito da esaminare
--    p_data_inizio           data inizio del periodo di riferimento
--    p_data_fine             data fine del periodo di riferimento
--    p_id_cliente            id del cliente
--    p_cod_sogg              codice del soggetto
--    p_stato_vendita         stato di vendita
--    p_id_cinema             id del cinema
--    p_id_sala               id della sala
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Dicembre 2009
--
-- MODIFICHE
--         17/12/2010 Barbaro Roberto, Teoresi srl
--                  Eliminata l'estrazione dei secondi nominali e disponibili
--                  per un piu' ampio raggruppamento del dato
--         25/03/2010 Colucci Antonio, Teoresi srl
--                  Modificato il core della query di estrazione per migliorare i tempi di estrazione
--                  E' stata modificata la gestione del parametro p_id_cliente e p_id_cinema. 
--                  Viene fatta una Join solo se i parametri non sono nulli
--         08/06/2010 Marletta Angelo, Teoresi srl
--                  subquery edelweiss ottimizzata
--         06/09/2010 Marletta Angelo, Teoresi srl
--                  Ottimizzazione subquery edelweiss
--         24/09/2010 Marletta Angelo, Teoresi srl
--                  Aggiunto filtro soggetto, edelweiss unificata, ottimizzazione ricerca per circuito
--         28/09/2010 Marletta Angelo, Teoresi srl
--                  Funzione unificata per tutta la sezione composizione schermi
--         11/10/2010 Colucci Antonio, Teoresi srl
--                  inserito order by nel recupero della classe merceologica ed 
--                  inserito filtro (Livello = 1) nell'estrazione della categoria merceologica
-- --------------------------------------------------------------------------------------------
FUNCTION FU_COMP_SCHERMI   (p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                             p_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                             p_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                             p_id_cliente            VI_CD_CLIENTE.ID_CLIENTE%TYPE,
                             p_cod_sogg              PROSOGG.SO_INT_U_COD_INTERL%TYPE,
                             p_stato_di_vendita      CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                             p_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
                             p_id_sala               CD_SALA.ID_SALA%TYPE)
            				 return C_COMP_SCHERMI
IS
    v_return_value  C_COMP_SCHERMI;
BEGIN
    OPEN v_return_value FOR
    select distinct 
--        vencd.fu_cd_string_agg(distinct id_sala) over (partition by proid,dain,dafin) sale,
        count(distinct id_sala) over (partition by proid,dain,dafin) numsale,
        numcom,
        dain,
        dafin,
        proid
    from (
        select distinct
            id_sala,
            numcom,
            MIN(datapro) over (partition by proid,prog,id_sala) DAIN,
            MAX(datapro) over (partition by proid,prog,id_sala) DAFIN,
            proid
        from (
            SELECT distinct id_sala, numcom,proid,sum(nuovo) over(partition by id_sala order by datapro) prog, datapro from (
                SELECT 
                    id_sala,
                    NUMCOM,
                    PROID,
                    case
                        when row_number() over (partition by id_sala order by datapro)=1 then 1
                        when proid!=lag(proid) over (partition by id_sala order by datapro) then 1
                        else 0
                    end nuovo,
                    datapro
                FROM
                    (
                    --EDELWEISS 5
                    WITH SCHERMI AS
                    (SELECT ID_SCHERMO, ID_SALA FROM (                        
                        SELECT S.ID_SCHERMO,S.ID_SALA,null ID_CIRCUITO FROM CD_SCHERMO S
                        UNION ALL
                        SELECT S.ID_SCHERMO,S.ID_SALA, p_id_circuito ID_CIRCUITO
                            FROM CD_SCHERMO S,CD_CIRCUITO_SCHERMO C,CD_LISTINO L
                        WHERE
                            C.ID_SCHERMO = s.ID_SCHERMO
                            AND C.ID_LISTINO = L.ID_LISTINO
                            AND p_data_inizio BETWEEN L.DATA_INIZIO AND L.DATA_FINE+1
                            AND C.ID_CIRCUITO = p_id_circuito AND C.FLG_ANNULLATO = 'N'
                            AND p_id_circuito is not null
                        ) WHERE p_id_circuito IS NULL AND ID_CIRCUITO IS NULL OR ID_CIRCUITO = p_id_circuito)
                    SELECT DATAPRO,id_sala,PROID,NUMCOM
                    FROM (
                    SELECT
                    DATAPRO,
                    id_sala,
                    CASE WHEN
                        ROW_NUMBER() OVER (PARTITION BY DATAPRO,id_sala ORDER BY DATAPRO,id_sala,QUID) = 1 THEN 
                        ';' || VENCD.fu_cd_string_agg(quid) OVER (PARTITION BY DATAPRO,id_sala)
                        ELSE null
                    END PROID,
                    COUNT(1) OVER (PARTITION BY DATAPRO,id_sala) NUMCOM
                    FROM
                    (
                    SELECT DISTINCT
                    CD_COMUNICATO.DATA_EROGAZIONE_PREV DATAPRO,
                    sum(
                        distinct
                        case when PROSOGG.SO_INT_U_COD_INTERL=p_id_cliente then 1
                        else 0 end
                    ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_cliente,
                    sum(
                        distinct
                        case when PROSOGG.SO_COD_SOGG=p_cod_sogg then 1
                        else 0 end
                    ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_soggetto,
                    CD_COMUNICATO.ID_SALA id_sala,
                        LPAD(CD_BREAK.ID_TIPO_BREAK,2,0)                        -- tipo break
                        || LPAD(CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO,7,0)  -- soggetto di piano
                        || LPAD(CD_COEFF_CINEMA.DURATA,3,0)                     -- durata in secondi
                        || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_NT_COD_CAT_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_NT_COD_CAT_MERC),3,0)                -- categoria merceologica
                        || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_COD_CL_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_COD_CL_MERC),2,0)                  -- classe merceologica
                        || LPAD(CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO,9,0)       -- prodotto acquistato
                    QUID
                    FROM
                        CD_COMUNICATO,
                        CD_SOGGETTO_DI_PIANO,
                        PROSOGG,
                        CD_PRODOTTO_ACQUISTATO,
                        CD_FORMATO_ACQUISTABILE,
                        CD_COEFF_CINEMA,
                        CD_BREAK,
                        CD_PROIEZIONE,
                        SCHERMI,
                        CD_SALA,
                        CD_CINEMA
                    WHERE
                        --JOIN
                        CD_COMUNICATO.ID_SOGGETTO_DI_PIANO=CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO
                        --AND CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG(+)
                        AND (CD_SOGGETTO_DI_PIANO.DESCRIZIONE = 'SOGGETTO NON DEFINITO' 
                                or
                             CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG)
                        AND CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL = PROSOGG.SO_INT_U_COD_INTERL(+)
                        AND PROSOGG.LIVELLO (+) = 1 
                        AND CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                        AND CD_FORMATO_ACQUISTABILE.ID_FORMATO=CD_PRODOTTO_ACQUISTATO.ID_FORMATO
                        AND CD_COEFF_CINEMA.ID_COEFF=CD_FORMATO_ACQUISTABILE.ID_COEFF
                        AND CD_COMUNICATO.ID_BREAK=CD_BREAK.ID_BREAK
                        AND CD_BREAK.ID_PROIEZIONE=CD_PROIEZIONE.ID_PROIEZIONE
                        AND CD_PROIEZIONE.ID_SCHERMO=SCHERMI.ID_SCHERMO
                        AND SCHERMI.ID_SALA=CD_SALA.ID_SALA
                        AND CD_SALA.ID_CINEMA=CD_CINEMA.ID_CINEMA
                        --FILTRI
                        AND CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                        AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
                        AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                        AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL 
                        AND INSTR(UPPER(NVL(p_stato_di_vendita, CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)),CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA) >0
                        AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
                        AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
                        AND CD_PROIEZIONE.ID_FASCIA = 2
                        AND (p_id_sala is null OR CD_SALA.ID_SALA = p_id_sala)
                        AND (p_id_cinema is null OR CD_CINEMA.ID_CINEMA = p_id_cinema)
                        AND CD_CINEMA.FLG_VIRTUALE = 'N'
                    )t1
                        where (p_id_cliente is null or match_cliente = 1)
                        and (p_cod_sogg is null or match_soggetto = 1)
                    )t2
                    WHERE PROID IS NOT NULL
                    ORDER BY id_sala,DATAPRO,PROID
                 )EDELWEISS
            )
       )
    )
    ORDER BY dafin-dain,dain,numsale;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20036,'FUNCTION FU_COMP_SCHERMI: estrazione fallita ' || SQLERRM);
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_COMP_SINGOLO_SCHERMO
-- DESCRIZIONE:  restituisce, raggruppati per periodi, il dettaglio delle singole sale
--
-- OUTPUT: cursore contenente i seguenti valori per riga
--    a_id_sala              rappresenta il numero di sale che, nel periodo di riferimento, sono
--                           accomunate dalla stessa proiezione
--    a_numero_comunicati    il numero di comunicati che compongono la proiezione
--    a_data_inizio          data inizio del periodo di riferimento
--    a_data_fine            data fine del periodo di riferimento
--    a_proid                una stringa contenente le informazioni di composizione della proiezione
--    a_nome_cinema          il nome del cinema
--    a_nome_sala            il nome della sala
--
-- INPUT:
--    p_id_circuito           id del circuito da esaminare
--    p_data_inizio           data inizio del periodo di riferimento
--    p_data_fine             data fine del periodo di riferimento
--    p_id_cliente            id del cliente
--    p_cod_sogg              codice del soggetto
--    p_stato_vendita         stato di vendita
--    p_id_cinema             id del cinema
--    p_id_sala               id della sala
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Dicembre 2009
--
-- MODIFICHE
--         24/09/2010 Marletta Angelo, Teoresi srl
--                  Aggiunto filtro soggetto, edelweiss unificata, ottimizzazione ricerca per circuito
--         28/09/2010 Marletta Angelo, Teoresi srl
--                  Funzione unificata per tutta la sezione composizione singolo schermo
--         11/10/2010 Colucci Antonio, Teoresi srl
--                  inserito order by nel recupero della classe merceologica ed 
--                  inserito filtro (Livello = 1) nell'estrazione della categoria merceologica
--        Mauro Viel, Altran Dicembre 2010 inserita gestione del nome cinema.
-- --------------------------------------------------------------------------------------------
FUNCTION FU_COMP_SINGOLO_SCHERMO (p_id_circuito      CD_CIRCUITO.ID_CIRCUITO%TYPE,
                             p_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                             p_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
							 p_id_cliente            VI_CD_CLIENTE.ID_CLIENTE%TYPE,
            				 p_cod_sogg              PROSOGG.SO_INT_U_COD_INTERL%TYPE,
                             p_stato_di_vendita      CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                             p_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
                             p_id_sala               CD_SALA.ID_SALA%TYPE)
            				 return C_COMP_SINGOLO_SCHERMO
IS
    v_return_value  C_COMP_SINGOLO_SCHERMO;
BEGIN
    OPEN v_return_value FOR
        select distinct
            id_sala,
            numcom,
            MIN(datapro) over (partition by proid,prog) DAIN,
            MAX(datapro) over (partition by proid,prog) DAFIN,
            proid,
            NOME_CINEMA ||'-'||COMUNE NOCI,
            NOME_SALA NOSA 
        from (
            SELECT distinct id_sala, numcom,proid,sum(nuovo) over(partition by id_sala order by datapro) prog, datapro,
                NOME_CINEMA, NOME_SALA, COMUNE from (
                SELECT 
                    id_sala,
                    NUMCOM,
                    PROID,
                    case
                        when row_number() over (partition by id_sala order by datapro)=1 then 1
                        when proid!=lag(proid) over (partition by id_sala order by datapro) then 1
                        else 0
                    end nuovo,
                    datapro,
                    NOME_CINEMA, NOME_SALA, COMUNE
                FROM
                    (
                    --EDELWEISS SINGLE
                    WITH SCHERMI AS
                    (SELECT ID_SCHERMO, ID_SALA FROM (                        
                        SELECT S.ID_SCHERMO,S.ID_SALA,null ID_CIRCUITO FROM CD_SCHERMO S
                        UNION ALL
                        SELECT S.ID_SCHERMO,S.ID_SALA, p_id_circuito ID_CIRCUITO
                            FROM CD_SCHERMO S,CD_CIRCUITO_SCHERMO C,CD_LISTINO L
                        WHERE
                            C.ID_SCHERMO = s.ID_SCHERMO
                            AND C.ID_LISTINO = L.ID_LISTINO
                            AND p_data_inizio BETWEEN L.DATA_INIZIO AND L.DATA_FINE+1
                            AND C.ID_CIRCUITO = p_id_circuito AND C.FLG_ANNULLATO = 'N'
                            AND p_id_circuito is not null
                        ) WHERE p_id_circuito IS NULL AND ID_CIRCUITO IS NULL OR ID_CIRCUITO = p_id_circuito)
                    SELECT
                        DATAPRO,id_sala,PROID,NUMCOM,
                        NOME_CINEMA, NOME_SALA, COMUNE
                    FROM (
                    SELECT
                    DATAPRO,
                    id_sala,
                    CASE WHEN
                        ROW_NUMBER() OVER (PARTITION BY DATAPRO,id_sala ORDER BY DATAPRO,id_sala,QUID) = 1 THEN 
                        ';' || VENCD.fu_cd_string_agg(quid) OVER (PARTITION BY DATAPRO,id_sala)
                        ELSE null
                    END PROID,
                    COUNT(1) OVER (PARTITION BY DATAPRO,id_sala) NUMCOM,
                    NOME_CINEMA, NOME_SALA, COMUNE
                    FROM
                    (
                    SELECT DISTINCT
                    CD_COMUNICATO.DATA_EROGAZIONE_PREV DATAPRO,
                    sum(
                        distinct
                        case when PROSOGG.SO_INT_U_COD_INTERL=p_id_cliente then 1
                        else 0 end
                    ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_cliente,
                    sum(
                        distinct
                        case when PROSOGG.SO_COD_SOGG=p_cod_sogg then 1
                        else 0 end
                    ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_soggetto,
                    CD_COMUNICATO.ID_SALA id_sala,
                        LPAD(CD_BREAK.ID_TIPO_BREAK,2,0)                        -- tipo break
                        || LPAD(CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO,7,0)  -- soggetto di piano
                        || LPAD(CD_COEFF_CINEMA.DURATA,3,0)                     -- durata in secondi
                        || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_NT_COD_CAT_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_NT_COD_CAT_MERC),3,0)                -- categoria merceologica
                        || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_COD_CL_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_COD_CL_MERC),2,0)                  -- classe merceologica
                        || LPAD(CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO,9,0)       -- prodotto acquistato
                    QUID,
                    --CD_CINEMA.NOME_CINEMA,
                    pa_cd_cinema.FU_GET_NOME_CINEMA(cd_cinema.id_cinema,P_DATA_FINE) AS NOME_CINEMA,
                    CD_SALA.NOME_SALA,
                    CD_COMUNE.COMUNE
                    FROM
                        CD_COMUNICATO,
                        CD_SOGGETTO_DI_PIANO,
                        PROSOGG,
                        CD_PRODOTTO_ACQUISTATO,
                        CD_FORMATO_ACQUISTABILE,
                        CD_COEFF_CINEMA,
                        CD_BREAK,
                        CD_PROIEZIONE,
                        SCHERMI,
                        CD_SALA,
                        CD_CINEMA,
                        CD_COMUNE
                    WHERE
                        --JOIN
                        CD_COMUNICATO.ID_SOGGETTO_DI_PIANO=CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO
                        --AND CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG(+)
                        AND (CD_SOGGETTO_DI_PIANO.DESCRIZIONE = 'SOGGETTO NON DEFINITO' 
                                or
                             CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG)
                        AND CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL = PROSOGG.SO_INT_U_COD_INTERL(+)
                        AND PROSOGG.LIVELLO (+) = 1 
                        AND CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                        AND CD_FORMATO_ACQUISTABILE.ID_FORMATO=CD_PRODOTTO_ACQUISTATO.ID_FORMATO
                        AND CD_COEFF_CINEMA.ID_COEFF=CD_FORMATO_ACQUISTABILE.ID_COEFF
                        AND CD_COMUNICATO.ID_BREAK=CD_BREAK.ID_BREAK
                        AND CD_BREAK.ID_PROIEZIONE=CD_PROIEZIONE.ID_PROIEZIONE
                        AND CD_PROIEZIONE.ID_SCHERMO=SCHERMI.ID_SCHERMO
                        AND SCHERMI.ID_SALA=CD_SALA.ID_SALA
                        AND CD_SALA.ID_CINEMA=CD_CINEMA.ID_CINEMA
                        AND CD_COMUNE.ID_COMUNE=CD_CINEMA.ID_COMUNE
                        --FILTRI
                        AND CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                        AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
                        AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                        AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL 
                        AND INSTR(UPPER(NVL(p_stato_di_vendita, CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)),CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA) >0
                        AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
                        AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
                        AND CD_PROIEZIONE.ID_FASCIA = 2
                        AND (p_id_sala is null OR CD_SALA.ID_SALA = p_id_sala)
                        AND (p_id_cinema is null OR CD_CINEMA.ID_CINEMA = p_id_cinema)
                        AND CD_CINEMA.FLG_VIRTUALE = 'N'
                    )t1
                        where (p_id_cliente is null or match_cliente = 1)
                        and (p_cod_sogg is null or match_soggetto = 1)
                    )t2
                    WHERE PROID IS NOT NULL
                    ORDER BY id_sala,DATAPRO,PROID
                 )EDELWEISS
            )
        )
        ORDER BY NOCI, NOSA, DAIN, DAFIN; 
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20036,'FUNCTION FU_COMP_SINGOLO_SCHERMO: estrazione fallita ' || SQLERRM);
END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CLIENTE_SOGGETTO
-- DESCRIZIONE:  restituisce la descrizione del cliente e del soggetto di piano
-- OUTPUT: cursore contenente i seguenti valori per riga
--    a_desc_cliente          descrizione del cliente
--    a_desc_soggetto         descrizione del soggetto
-- INPUT:
--    p_id_soggetto_di_piano  id del soggetto di piano
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Dicembre 2009
--
-- MODIFICHE    Antonio Colucci, Teoresi srl, 7/01/2011
--              Inserita join mancante per ID_VER_PIANO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CLIENTE_SOGGETTO(p_id_soggetto_di_piano  CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE)
                            return C_CLIENTE_SOGGETTO
IS
    v_return_value  C_CLIENTE_SOGGETTO;
BEGIN
    OPEN v_return_value
        FOR
            SELECT VI_CD_CLIENTE.RAG_SOC_COGN CLIENTE, CD_SOGGETTO_DI_PIANO.DESCRIZIONE SOGGETTO
            FROM   VI_CD_CLIENTE, CD_PIANIFICAZIONE, CD_SOGGETTO_DI_PIANO
            WHERE  CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO = p_id_soggetto_di_piano
            AND    CD_SOGGETTO_DI_PIANO.ID_PIANO = CD_PIANIFICAZIONE.ID_PIANO
            AND    CD_SOGGETTO_DI_PIANO.ID_VER_PIANO = CD_PIANIFICAZIONE.ID_VER_PIANO
            AND    CD_PIANIFICAZIONE.ID_CLIENTE = VI_CD_CLIENTE.ID_CLIENTE;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20036,'FU_GET_CLIENTE_SOGGETTO: estrazione fallita ' || SQLERRM);
        OPEN v_return_value
            FOR
                SELECT '--' CLIENTE,'--' SOGGETTO FROM DUAL;
        RETURN v_return_value;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSEGNA_POS
-- DESCRIZIONE:  estrae l'elenco dei comunicati associati ai parametri di input
--               ed imposta la posizione desiderata ad ognuno di essi
-- OUTPUT: nessuno al momento
--
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_posizione              la posizione da impostare ai comunicati
--  p_data_inizio            data inizio del periodo di riferimento
--  p_data_fine              data fine del periodo di riferimento
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--  p_id_list_sale           la lista delle sale componenti il circuito
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Dicembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ASSEGNA_POS(p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                         p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                         p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                         p_posizione               CD_COMUNICATO.POSIZIONE%TYPE,
                         p_data_inizio             CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                         p_data_fine               CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                         p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                         p_id_list_sale            VARCHAR2)
IS
    tmpVar NUMBER;
    CURSOR c_lista_comunicati IS
        SELECT  ID_COMUNICATO
        FROM    CD_COMUNICATO, CD_TIPO_BREAK TBK, CD_BREAK BRK, CD_CIRCUITO_BREAK CIR_BRK,
                CD_BREAK_VENDITA BRK_VEN, CD_COEFF_CINEMA COEFF, CD_FORMATO_ACQUISTABILE FORM_ACQ,
                CD_PRODOTTO_ACQUISTATO PROD, CD_PROIEZIONE PRZ,
                CD_SCHERMO SCH
        WHERE   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND     p_id_tipo_break = TBK.ID_TIPO_BREAK
        AND     TBK.ID_TIPO_BREAK = BRK.ID_TIPO_BREAK
        AND     BRK.ID_BREAK = CIR_BRK.ID_BREAK
        AND     CIR_BRK.ID_CIRCUITO_BREAK = BRK_VEN.ID_CIRCUITO_BREAK
        AND     BRK_VEN.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
        AND     p_durata = COEFF.DURATA
        AND     COEFF.ID_COEFF = FORM_ACQ.ID_COEFF
        AND     FORM_ACQ.ID_FORMATO = PROD.ID_FORMATO
        AND     PROD.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
        AND     PROD.FLG_ANNULLATO = 'N'
        AND     PROD.FLG_SOSPESO = 'N'
        AND     PROD.COD_DISATTIVAZIONE IS NULL
        AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
        AND     BRK_VEN.FLG_ANNULLATO = 'N'
        AND     BRK.FLG_ANNULLATO = 'N'
        AND     TBK.FLG_ANNULLATO = 'N'
        AND     CIR_BRK.FLG_ANNULLATO = 'N'
        AND     PROD.STATO_DI_VENDITA = 'PRE'
        AND     PRZ.FLG_ANNULLATO = 'N'
        AND     SCH.FLG_ANNULLATO = 'N'
        AND     BRK.ID_PROIEZIONE = PRZ.ID_PROIEZIONE
        AND     PRZ.ID_SCHERMO = SCH.ID_SCHERMO
        --AND     SCH.ID_SALA NOT IN (SELECT ID_SALA FROM CD_SALA WHERE ID_SALA NOT IN (SELECT * FROM TABLE (p_id_list_sale)));
        AND     INSTR(p_id_list_sale,'PP'||TO_CHAR(NVL(SCH.ID_SALA,''))||'PP') > 0;

BEGIN
   tmpVar := 0;
          FOR ID_COMUNICATO IN c_lista_comunicati LOOP
               PR_ASSEGNA_POS_COM(ID_COMUNICATO.ID_COMUNICATO,p_posizione);
          END LOOP;
   EXCEPTION
       WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20037,'PROCEDURA PR_ASSEGNA_POS: errore ' || SQLERRM);
END PR_ASSEGNA_POS;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSEGNA_POS_II
-- DESCRIZIONE:  estrae l'elenco dei comunicati associati ai parametri di input
--               ed imposta la posizione desiderata ad ognuno di essi
-- OUTPUT: 
--  nessuno al momento
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_posizione              la posizione da impostare ai comunicati
--  p_session_id             la sessione HTTP di riferimento per la ricerca
--  p_proid                  il proid al quale fare riferimento per identificare l'elenco di spot
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 20 Dicembre 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ASSEGNA_POS_II(    p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                p_posizione               CD_COMUNICATO.POSIZIONE%TYPE,
                                p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                              
                                p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                           )
IS
    tmpVar NUMBER;
    CURSOR c_lista_comunicati IS
        SELECT  ID_COMUNICATO
        FROM    CD_COMUNICATO, 
                CD_TIPO_BREAK, 
                CD_COEFF_CINEMA, 
                CD_FORMATO_ACQUISTABILE,
                CD_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_VENDITA, 
                CD_RICERCA_COMP_SCHERMI
        WHERE   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
        AND     CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
        AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid           
        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
        AND     CD_TIPO_BREAK.ID_TIPO_BREAK = CD_PRODOTTO_VENDITA.ID_TIPO_BREAK
        AND     CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
        AND     CD_COEFF_CINEMA.DURATA = p_durata
        AND     CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF
        AND     CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
        AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = CD_RICERCA_COMP_SCHERMI.DATA_RIF        
        AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
        AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
        AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
        AND     CD_COMUNICATO.ID_SALA = CD_RICERCA_COMP_SCHERMI.ID_SALA;
BEGIN
   tmpVar := 0;
          FOR ID_COMUNICATO IN c_lista_comunicati LOOP
               PR_ASSEGNA_POS_COM(ID_COMUNICATO.ID_COMUNICATO,p_posizione);
          END LOOP;
   EXCEPTION
       WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20037,'PROCEDURA PR_ASSEGNA_POS: errore ' || SQLERRM);
END PR_ASSEGNA_POS_II;

PROCEDURE PR_ASSEGNA_POS_COM(p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE,
                             p_posizione     CD_COMUNICATO.POSIZIONE%TYPE) IS
tmpVar NUMBER;
v_idcomunicato CD_COMUNICATO.ID_COMUNICATO%TYPE;
v_posizione CD_COMUNICATO.POSIZIONE%TYPE;

BEGIN
   tmpVar := 0;

   BEGIN

    SELECT COM.ID_COMUNICATO INTO v_idcomunicato
    FROM CD_COMUNICATO COM, CD_BREAK_VENDITA BRK_VEN, CD_CIRCUITO_BREAK CIR_BRK, CD_BREAK BRK, CD_PRODOTTO_ACQUISTATO PROD
    WHERE   COM.ID_BREAK_VENDITA = BRK_VEN.ID_BREAK_VENDITA
    AND   BRK_VEN.ID_CIRCUITO_BREAK = CIR_BRK.ID_CIRCUITO_BREAK
    AND   CIR_BRK.ID_BREAK = BRK.ID_BREAK
    AND   COM.POSIZIONE = p_posizione
    AND   PROD.FLG_ANNULLATO = 'N'
    AND   PROD.FLG_SOSPESO = 'N'
    AND   PROD.COD_DISATTIVAZIONE IS NULL
    AND   COM.FLG_ANNULLATO = 'N'
    AND   COM.FLG_SOSPESO = 'N'
    AND   COM.COD_DISATTIVAZIONE IS NULL
    AND   BRK_VEN.FLG_ANNULLATO = 'N'
    AND   CIR_BRK.FLG_ANNULLATO = 'N'
    AND   BRK.FLG_ANNULLATO = 'N'
    AND   PROD.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
    AND   PROD.STATO_DI_VENDITA = 'PRE'
    AND BRK.ID_BREAK =
        (SELECT BRK.ID_BREAK
        FROM CD_BREAK BRK, CD_BREAK_VENDITA BRK_VEN, CD_COMUNICATO COM,CD_CIRCUITO_BREAK CIR_BRK
        WHERE COM.ID_COMUNICATO = p_id_comunicato
        AND   COM.ID_BREAK_VENDITA = BRK_VEN.ID_BREAK_VENDITA
        AND   BRK_VEN.ID_CIRCUITO_BREAK = CIR_BRK.ID_CIRCUITO_BREAK
        AND   COM.FLG_ANNULLATO = 'N'
        AND   COM.FLG_SOSPESO = 'N'
        AND   COM.COD_DISATTIVAZIONE IS NULL
        AND   BRK_VEN.FLG_ANNULLATO = 'N'
        AND   CIR_BRK.FLG_ANNULLATO = 'N'
        AND   BRK.FLG_ANNULLATO = 'N'
        AND   CIR_BRK.ID_BREAK = BRK.ID_BREAK);

   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     v_idcomunicato := 0;
    UPDATE CD_COMUNICATO
    SET    POSIZIONE = p_posizione
    WHERE  ID_COMUNICATO = p_id_comunicato
    AND    FLG_ANNULLATO = 'N'
    AND    FLG_SOSPESO = 'N'
    AND    COD_DISATTIVAZIONE IS NULL;
    --DBMS_OUTPUT.PUT_LINE('Ex Comunicato '||p_id_comunicato||' v_id_comunicato '||v_idcomunicato||' p_id_comunicato '||p_id_comunicato);
    END;
    IF(v_idcomunicato > 0)THEN

        SELECT POSIZIONE INTO v_posizione FROM CD_COMUNICATO
        WHERE  ID_COMUNICATO = p_id_comunicato
        AND    FLG_ANNULLATO = 'N'
        AND    FLG_SOSPESO = 'N'
        AND    COD_DISATTIVAZIONE IS NULL;

        UPDATE CD_COMUNICATO
        SET    POSIZIONE = p_posizione
        WHERE  ID_COMUNICATO = p_id_comunicato
        AND    FLG_ANNULLATO = 'N'
        AND    FLG_SOSPESO = 'N'
        AND    COD_DISATTIVAZIONE IS NULL;

        UPDATE CD_COMUNICATO
        SET    POSIZIONE = v_posizione
        WHERE  ID_COMUNICATO = v_idcomunicato
        AND    FLG_ANNULLATO = 'N'
        AND    FLG_SOSPESO = 'N'
        AND    COD_DISATTIVAZIONE IS NULL;
        --DBMS_OUTPUT.PUT_LINE('>0 Comunicato '||p_id_comunicato||' p_posizione '||p_posizione||' v_id_comunicato '||v_idcomunicato||' v_posizione '||v_posizione);
    END IF;

   EXCEPTION
     WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR(-20038,'PROCEDURA PR_ASSEGNA_POS_COM: errore ' || SQLERRM);
END PR_ASSEGNA_POS_COM;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_POSIZ_COMUNICATO
-- DESCRIZIONE:  restituisce informazioni circa la posizione di un comunicato
--
-- OUTPUT: una stringa composta da NUMERO1 ASTERISCO NUMERO2 ASTERISCO
--         ove gli asterischi hanno una funzione separatoria mentre
--         NUMERO1 rappresenta la posizione dei comunicati nel break
--                 un numero negativo indica la mancanza di omogeneita' nella posizione
--                 nello specifico -1000 non ha posizione, -100 ne ha tante diverse
--         NUMERO2 rappresenta la posizione di rigore dei comunicati nel break
--                 un numero negativo indica la mancanza di omogeneita' nella posizione
--                 nello specifico -1000 non ha posizione, -100 ne ha tante diverse
--         la stringa -1*-1* indica una situazione di errore
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_data_inizio            data inizio del periodo di riferimento
--  p_data_fine              data fine del periodo di riferimento
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--  p_id_list_sale           la lista delle sale componenti il circuito
--
--  REALIZZATORE  Roberto Barbaro, Teoresi srl, Dicembre 2009
--
--  MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_POSIZ_COMUNICATO(p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                             p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                             p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                             p_data_inizio             CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                             p_data_fine               CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                             p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                             p_id_list_sale            VARCHAR2) RETURN VARCHAR2
IS
    v_posizione  VARCHAR2(12);
    v_parte1     VARCHAR2(6);
    v_parte2     VARCHAR2(6);
    v_temp1      INTEGER;
    v_temp2      INTEGER;
BEGIN
    v_posizione := '';
    SELECT  COUNT(DISTINCT POSIZIONE), COUNT(DISTINCT POSIZIONE_DI_RIGORE)
    INTO    v_temp1, v_temp2
    FROM    CD_SCHERMO, CD_COMUNICATO, CD_TIPO_BREAK, CD_BREAK, CD_CIRCUITO_BREAK,
            CD_BREAK_VENDITA, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
            CD_PRODOTTO_ACQUISTATO, CD_PROIEZIONE
    WHERE   CD_PROIEZIONE.FLG_ANNULLATO = 'N'
    AND     CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
    AND     CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
    AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
    AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
    AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
    AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
    AND     CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
    AND     CD_BREAK_VENDITA.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
    AND     CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
    AND     CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
    AND     CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_BREAK.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
    AND     CD_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
    AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_SCHERMO.FLG_ANNULLATO = 'N'
        -- ZONA FILTRI
    AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
    AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
    AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
    AND     CD_COEFF_CINEMA.DURATA = p_durata
    --AND     CD_SCHERMO.ID_SALA NOT IN (SELECT ID_SALA FROM CD_SALA WHERE ID_SALA NOT IN (SELECT * FROM TABLE (p_id_list_sale)));
    AND     INSTR(p_id_list_sale,'PP'||TO_CHAR(NVL(CD_SCHERMO.ID_SALA,''))||'PP') > 0;
    -- ZONA FILTRI
    IF(v_temp1=0)THEN
        v_parte1:='-1000*'; --ce n'e' piu di una
    ELSE
        IF(v_temp1=1)THEN
            SELECT  DISTINCT  POSIZIONE||'*'
            INTO    v_parte1
            FROM    CD_SCHERMO, CD_COMUNICATO, CD_TIPO_BREAK, CD_BREAK, CD_CIRCUITO_BREAK,
                    CD_BREAK_VENDITA, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
                    CD_PRODOTTO_ACQUISTATO, CD_PROIEZIONE
            WHERE   CD_PROIEZIONE.FLG_ANNULLATO = 'N'
            AND     CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
            AND     CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
            AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
            AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
            AND     CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
            AND     CD_BREAK_VENDITA.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
            AND     CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
            AND     CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
            AND     CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_BREAK.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
            AND     CD_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_SCHERMO.FLG_ANNULLATO = 'N'
            -- ZONA FILTRI
            AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
            AND     CD_COEFF_CINEMA.DURATA = p_durata
--            AND     CD_SCHERMO.ID_SALA NOT IN (SELECT ID_SALA FROM CD_SALA WHERE ID_SALA NOT IN (SELECT * FROM TABLE (p_id_list_sale)));
            AND     INSTR(p_id_list_sale,'PP'||TO_CHAR(NVL(CD_SCHERMO.ID_SALA,''))||'PP') > 0;
        ELSE
            v_parte1:='-100*';-- non ve ne sono
        END IF;
    END IF;
    IF(v_temp2=0)THEN
        v_parte2:='-1000*'; --ce n'e' piu di una
    ELSE
        IF(v_temp2=1)THEN
            SELECT  DISTINCT  POSIZIONE_DI_RIGORE||'*'
            INTO    v_parte2
            FROM    CD_SCHERMO, CD_COMUNICATO, CD_TIPO_BREAK, CD_BREAK, CD_CIRCUITO_BREAK,
                    CD_BREAK_VENDITA, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
                    CD_PRODOTTO_ACQUISTATO, CD_PROIEZIONE
            WHERE   CD_PROIEZIONE.FLG_ANNULLATO = 'N'
            AND     CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
            AND     CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
            AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
            AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
            AND     CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
            AND     CD_BREAK_VENDITA.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
            AND     CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
            AND     CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
            AND     CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_BREAK.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
            AND     CD_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_SCHERMO.FLG_ANNULLATO = 'N'
            -- ZONA FILTRI
            AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
            AND     CD_COEFF_CINEMA.DURATA = p_durata
            -- AND     CD_SCHERMO.ID_SALA NOT IN (SELECT ID_SALA FROM CD_SALA WHERE ID_SALA NOT IN (SELECT * FROM TABLE (p_id_list_sale)));
            AND     INSTR(p_id_list_sale,'PP'||TO_CHAR(NVL(CD_SCHERMO.ID_SALA,''))||'PP') > 0;
        ELSE
            v_parte2:='-100*';-- non ve ne sono
        END IF;
    END IF;
    v_posizione:=v_parte1||v_parte2;
    RETURN v_posizione;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_POSIZ_COMUNICATO: errore ' || SQLERRM);
    RETURN '-1*-1*';
END FU_POSIZ_COMUNICATO;


-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_POSIZ_COMUNICATO_II
-- DESCRIZIONE:  restituisce informazioni circa la posizione di un comunicato
--
-- OUTPUT: una stringa composta da NUMERO1 ASTERISCO NUMERO2 ASTERISCO
--         ove gli asterischi hanno una funzione separatoria mentre
--         NUMERO1 rappresenta la posizione dei comunicati nel break
--                 un numero negativo indica la mancanza di omogeneita' nella posizione
--                 nello specifico -1000 non ha posizione, -100 ne ha tante diverse
--         NUMERO2 rappresenta la posizione di rigore dei comunicati nel break
--                 un numero negativo indica la mancanza di omogeneita' nella posizione
--                 nello specifico -1000 non ha posizione, -100 ne ha tante diverse
--         la stringa -1*-1* indica una situazione di errore
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_session_id             la sessione HTTP di riferimento per la ricerca
--  p_proid                  il proid al quale fare riferimento per identificare l'elenco di spot
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 20 Dicembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_POSIZ_COMUNICATO_II(    p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                    p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                    p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                    p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                               
                                    p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                               ) RETURN VARCHAR2
IS
    v_posizione  VARCHAR2(12);
    v_parte1     VARCHAR2(6);
    v_parte2     VARCHAR2(6);
    v_temp1      INTEGER;
    v_temp2      INTEGER;
BEGIN
    v_posizione := '';
SELECT  COUNT(DISTINCT POSIZIONE), COUNT(DISTINCT POSIZIONE_DI_RIGORE)
    INTO    v_temp1, v_temp2
    FROM    CD_COMUNICATO, CD_TIPO_BREAK, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
            CD_PRODOTTO_ACQUISTATO, CD_PRODOTTO_VENDITA, CD_RICERCA_COMP_SCHERMI
    WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
    AND     CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
    AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid    
    AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
    AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
    AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
    AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
    AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
        -- ZONA FILTRI
    AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
    AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = CD_RICERCA_COMP_SCHERMI.DATA_RIF
    AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
    AND     CD_COEFF_CINEMA.DURATA = p_durata
    AND     CD_COMUNICATO.ID_SALA = CD_RICERCA_COMP_SCHERMI.ID_SALA;
    -- ZONA FILTRI
    IF(v_temp1=0)THEN
        v_parte1:='-1000*'; --ce n'e' piu di una
    ELSE
        IF(v_temp1=1)THEN
            SELECT  DISTINCT  POSIZIONE||'*'
            INTO    v_parte1
            FROM    CD_COMUNICATO, CD_TIPO_BREAK, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
                    CD_PRODOTTO_ACQUISTATO, CD_PRODOTTO_VENDITA, CD_RICERCA_COMP_SCHERMI
            WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
            AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid                
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
            AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
            AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
            AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
                -- ZONA FILTRI
            AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = CD_RICERCA_COMP_SCHERMI.DATA_RIF
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
            AND     CD_COEFF_CINEMA.DURATA = p_durata
            AND     CD_COMUNICATO.ID_SALA = CD_RICERCA_COMP_SCHERMI.ID_SALA;
        ELSE
            v_parte1:='-100*';-- non ve ne sono
        END IF;
    END IF;
    IF(v_temp2=0)THEN
        v_parte2:='-1000*'; --ce n'e' piu di una
    ELSE
        IF(v_temp2=1)THEN
            SELECT  DISTINCT  POSIZIONE_DI_RIGORE||'*'
            INTO    v_parte2
            FROM    CD_COMUNICATO, CD_TIPO_BREAK, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
                    CD_PRODOTTO_ACQUISTATO, CD_PRODOTTO_VENDITA, CD_RICERCA_COMP_SCHERMI
            WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
            AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid                
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
            AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
            AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
            AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
                -- ZONA FILTRI
            AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = CD_RICERCA_COMP_SCHERMI.DATA_RIF
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
            AND     CD_COEFF_CINEMA.DURATA = p_durata
            AND     CD_COMUNICATO.ID_SALA = CD_RICERCA_COMP_SCHERMI.ID_SALA;
        ELSE
            v_parte2:='-100*';-- non ve ne sono
        END IF;
    END IF;
    v_posizione:=v_parte1||v_parte2;
    RETURN v_posizione;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_POSIZ_COMUNICATO_II: errore ' || SQLERRM);
    RETURN '-1*-1*';
END FU_POSIZ_COMUNICATO_II;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_MATERIALI_COM_FLAG
-- DESCRIZIONE:  restituisce un'informazione sui materiali di un gruppo di comunicati
--
-- OUTPUT: 0   vuol dire che ad almeno uno dei comunicati dell'insieme
--             non e' associato un materiale
--         1   vuol dire che a tutti i comunicati dell'insieme
--             e' associato un materiale
--        -1   indica una disdicevole condizione di errore
--
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_data_inizio            data inizio del periodo di riferimento
--  p_data_fine              data fine del periodo di riferimento
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--  p_id_list_sale           la lista delle sale componenti il circuito
--
--  REALIZZATORE  Abbundo Francesco, Roberto Barbaro, Teoresi srl, Gennaio 2010
--
--  MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALI_COM_FLAG(p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                               p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                               p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                               p_data_inizio             CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_data_fine               CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                               p_id_list_sale            id_list_type) RETURN INTEGER
IS
    v_temp1        INTEGER;
    v_temp2        INTEGER;
    v_return_value INTEGER;
BEGIN
    SELECT  COUNT(CD_COMUNICATO.ID_COMUNICATO), COUNT(CD_COMUNICATO.ID_MATERIALE_DI_PIANO)
    INTO    v_temp1, v_temp2
    FROM    CD_SCHERMO, CD_COMUNICATO, CD_TIPO_BREAK, CD_BREAK, CD_CIRCUITO_BREAK,
            CD_BREAK_VENDITA, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
            CD_PRODOTTO_ACQUISTATO, CD_PROIEZIONE
    WHERE   CD_PROIEZIONE.FLG_ANNULLATO = 'N'
    AND     CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
    AND     CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
    AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
    AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
    --AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
    AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
    AND     CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
    AND     CD_BREAK_VENDITA.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
    AND     CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
    AND     CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
    AND     CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_BREAK.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
    AND     CD_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
    AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_SCHERMO.FLG_ANNULLATO = 'N'
    -- ZONA FILTRI
    AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
    AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
    AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
    AND     CD_COEFF_CINEMA.DURATA = p_durata
    AND     CD_SCHERMO.ID_SALA NOT IN (SELECT ID_SALA FROM CD_SALA
                    WHERE ID_SALA NOT IN (SELECT * FROM TABLE (p_id_list_sale)));
    -- ZONA FILTRI
    IF(v_temp1=v_temp2)THEN
        v_return_value:=1;
    ELSE
        v_return_value:=0;
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_MATERIALI_COM_FLAG: errore ' || SQLERRM);
    RETURN -1;
END FU_MATERIALI_COM_FLAG;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_MATERIALI_COM_FLAG_II
-- DESCRIZIONE:  restituisce un'informazione sui materiali di un gruppo di comunicati
--
-- OUTPUT: 0   vuol dire che ad almeno uno dei comunicati dell'insieme
--             non e' associato un materiale
--         1   vuol dire che a tutti i comunicati dell'insieme
--             e' associato un materiale
--        -1   indica una disdicevole condizione di errore
--
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_session_id             la sessione HTTP di riferimento per la ricerca
--  p_proid                  il proid al quale fare riferimento per identificare l'elenco di spot
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 20 Dicembre 2010
-- MODIFICHE     Tommaso D'Anna, Teoresi srl, 20 Giugno 2010
--                  Commentato il filtro sullo stato di vendita per visualizzare anche lo stato dei 
--                  materiali correttamente per OPZ e ACO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALI_COM_FLAG_II(  p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                    p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                    p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                    p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                                     
                                    p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                                  ) RETURN INTEGER  
IS
    v_temp1        INTEGER;
    v_temp2        INTEGER;
    v_return_value INTEGER;
BEGIN
    SELECT  COUNT(CD_COMUNICATO.ID_COMUNICATO), COUNT(CD_COMUNICATO.ID_MATERIALE_DI_PIANO)
    INTO    v_temp1, v_temp2
    FROM    CD_COMUNICATO, CD_TIPO_BREAK, CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE,
            CD_PRODOTTO_ACQUISTATO, CD_PRODOTTO_VENDITA, CD_RICERCA_COMP_SCHERMI
    WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
    AND     CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
    AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid    
    AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
    AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
    --AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
    AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
    AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
    AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
    AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
    AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
        -- ZONA FILTRI
    AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
    AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = CD_RICERCA_COMP_SCHERMI.DATA_RIF
    AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
    AND     CD_COEFF_CINEMA.DURATA = p_durata
    AND     CD_COMUNICATO.ID_SALA = CD_RICERCA_COMP_SCHERMI.ID_SALA;
    -- ZONA FILTRI
    IF(v_temp1=v_temp2)THEN
        v_return_value:=1;
    ELSE
        v_return_value:=0;
    END IF;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_MATERIALI_COM_FLAG: errore ' || SQLERRM);
    RETURN -1;
END FU_MATERIALI_COM_FLAG_II;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_PIANO_COMUNIC
-- DESCRIZIONE:  restituisce informazioni sul piano associato al gruppo di comunicati
--
-- OUTPUT: info sul piano
--
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_data_inizio            data inizio del periodo di riferimento
--  p_data_fine              data fine del periodo di riferimento
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--  p_id_list_sale           la lista delle sale componenti il circuito
--
--  REALIZZATORE   Roberto Barbaro, Teoresi srl, Gennaio 2010
--
--  MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_PIANO_COMUNIC(p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                               p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                               p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                               p_data_inizio             CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_data_fine               CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                               p_id_list_sale            id_list_type) RETURN C_INFO_PIANO
IS
    v_return_value  C_INFO_PIANO;
BEGIN
    OPEN v_return_value
            FOR
            SELECT  DISTINCT PROD.ID_PIANO, PROD.ID_VER_PIANO, VI_CD_CLIENTE.ID_CLIENTE, VI_CD_CLIENTE.RAG_SOC_COGN, PROD.DATA_INIZIO, PROD.DATA_FINE
                FROM    CD_COMUNICATO, CD_TIPO_BREAK TBK, CD_BREAK BRK, CD_CIRCUITO_BREAK CIR_BRK,
                        CD_BREAK_VENDITA BRK_VEN, CD_COEFF_CINEMA COEFF, CD_FORMATO_ACQUISTABILE FORM_ACQ,
                        CD_PRODOTTO_ACQUISTATO PROD, CD_PROIEZIONE PRZ, CD_SCHERMO SCH, CD_PIANIFICAZIONE PIANO,
                        VI_CD_CLIENTE
                WHERE   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
                AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND     p_id_tipo_break = TBK.ID_TIPO_BREAK
                AND     TBK.ID_TIPO_BREAK = BRK.ID_TIPO_BREAK
                AND     BRK.ID_BREAK = CIR_BRK.ID_BREAK
                AND     CIR_BRK.ID_CIRCUITO_BREAK = BRK_VEN.ID_CIRCUITO_BREAK
                AND     BRK_VEN.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
                AND     p_durata = COEFF.DURATA
                AND     COEFF.ID_COEFF = FORM_ACQ.ID_COEFF
                AND     FORM_ACQ.ID_FORMATO = PROD.ID_FORMATO
                AND     PROD.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
                AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
                AND     PROD.FLG_ANNULLATO = 'N'
                AND     PROD.FLG_SOSPESO = 'N'
                AND     PROD.COD_DISATTIVAZIONE IS NULL
                AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
                AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
                AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
                AND     BRK_VEN.FLG_ANNULLATO = 'N'
                AND     BRK.FLG_ANNULLATO = 'N'
                AND     TBK.FLG_ANNULLATO = 'N'
                AND     CIR_BRK.FLG_ANNULLATO = 'N'
                -- AND     PROD.STATO_DI_VENDITA = 'PRE'
                AND     PRZ.FLG_ANNULLATO = 'N'
                AND     SCH.FLG_ANNULLATO = 'N'
                AND     BRK.ID_PROIEZIONE = PRZ.ID_PROIEZIONE
                AND     PRZ.ID_SCHERMO = SCH.ID_SCHERMO
                AND     PROD.ID_PIANO = PIANO.ID_PIANO
                AND     PROD.ID_VER_PIANO = PIANO.ID_VER_PIANO
                AND     PIANO.ID_CLIENTE = VI_CD_CLIENTE.ID_CLIENTE
                AND     SCH.ID_SALA NOT IN (SELECT ID_SALA FROM CD_SALA
                            WHERE ID_SALA NOT IN (SELECT * FROM TABLE (p_id_list_sale)));
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_INFO_PIANO_COMUNIC: errore ' || SQLERRM);
END FU_INFO_PIANO_COMUNIC;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_PIANO_COMUNIC_II
-- DESCRIZIONE:  restituisce informazioni sul piano associato al gruppo di comunicati
--
-- OUTPUT: info sul piano
--
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_session_id             la sessione HTTP di riferimento per la ricerca
--  p_proid                  il proid al quale fare riferimento per identificare l'elenco di spot
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 20 Dicembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_PIANO_COMUNIC_II(  p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                    p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                    p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                    p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                                     
                                    p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                                 ) 
                                 RETURN C_INFO_PIANO
IS
    v_return_value  C_INFO_PIANO;
BEGIN
    OPEN v_return_value
            FOR
            SELECT DISTINCT CD_PRODOTTO_ACQUISTATO.ID_PIANO, 
                            CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO, 
                            VI_CD_CLIENTE.ID_CLIENTE, 
                            VI_CD_CLIENTE.RAG_SOC_COGN,
                            CD_PRODOTTO_ACQUISTATO.DATA_INIZIO,
                            CD_PRODOTTO_ACQUISTATO.DATA_FINE
            FROM    CD_COMUNICATO, 
                    CD_TIPO_BREAK, 
                    CD_COEFF_CINEMA, 
                    CD_FORMATO_ACQUISTABILE,
                    CD_PRODOTTO_ACQUISTATO,
                    CD_PRODOTTO_VENDITA, 
                    CD_RICERCA_COMP_SCHERMI,
                    CD_PIANIFICAZIONE,
                    VI_CD_CLIENTE
            WHERE   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
            AND     CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
            AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid           
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = CD_PRODOTTO_VENDITA.ID_TIPO_BREAK
            AND     CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
            AND     CD_COEFF_CINEMA.DURATA = p_durata
            AND     CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF
            AND     CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = CD_RICERCA_COMP_SCHERMI.DATA_RIF        
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
            --AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'
            AND     CD_PRODOTTO_ACQUISTATO.ID_PIANO = CD_PIANIFICAZIONE.ID_PIANO
            AND     CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = CD_PIANIFICAZIONE.ID_VER_PIANO
            AND     CD_PIANIFICAZIONE.ID_CLIENTE = VI_CD_CLIENTE.ID_CLIENTE       
            AND     CD_COMUNICATO.ID_SALA = CD_RICERCA_COMP_SCHERMI.ID_SALA;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_INFO_PIANO_COMUNIC: errore ' || SQLERRM);
END FU_INFO_PIANO_COMUNIC_II;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_MATERIALI
-- DESCRIZIONE:  restituisce informazioni sui materiali associati al gruppo di comunicati
--
-- OUTPUT: info sui materiali
--
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_data_inizio            data inizio del periodo di riferimento
--  p_data_fine              data fine del periodo di riferimento
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--  p_id_list_sale           la lista delle sale componenti il circuito
--
--  REALIZZATORE   Roberto Barbaro, Teoresi srl, Gennaio 2010
--
--  MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION     FU_DETT_MATERIALI(p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                               p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                               p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                               p_data_inizio             CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_data_fine               CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                               p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                               p_id_list_sale            id_list_type) RETURN C_DETT_MATERIALI
IS
    v_return_value  C_DETT_MATERIALI;
BEGIN
    OPEN v_return_value
            FOR
            SELECT  COUNT(ID_COMUNICATO) COMUN, CD_MATERIALE.ID_MATERIALE, CD_MATERIALE.TITOLO, CD_MATERIALE.DESCRIZIONE
        FROM    CD_COMUNICATO, CD_TIPO_BREAK TBK, CD_BREAK BRK, CD_CIRCUITO_BREAK CIR_BRK,
                CD_BREAK_VENDITA BRK_VEN, CD_COEFF_CINEMA COEFF, CD_FORMATO_ACQUISTABILE FORM_ACQ,
                CD_PRODOTTO_ACQUISTATO PROD, CD_PROIEZIONE PRZ, CD_SCHERMO SCH, CD_MATERIALE_DI_PIANO, CD_MATERIALE
        WHERE   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND     p_id_tipo_break = TBK.ID_TIPO_BREAK
        AND     TBK.ID_TIPO_BREAK = BRK.ID_TIPO_BREAK
        AND     BRK.ID_BREAK = CIR_BRK.ID_BREAK
        AND     CIR_BRK.ID_CIRCUITO_BREAK = BRK_VEN.ID_CIRCUITO_BREAK
        AND     BRK_VEN.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
        AND     p_durata = COEFF.DURATA
        AND     COEFF.ID_COEFF = FORM_ACQ.ID_COEFF
        AND     FORM_ACQ.ID_FORMATO = PROD.ID_FORMATO
        AND     PROD.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
        AND     PROD.FLG_SOSPESO = 'N'
        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
        AND     PROD.FLG_ANNULLATO = 'N'
        AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
        AND     BRK_VEN.FLG_ANNULLATO = 'N'
        AND     BRK.FLG_ANNULLATO = 'N'
        AND     TBK.FLG_ANNULLATO = 'N'
        AND     CIR_BRK.FLG_ANNULLATO = 'N'
        --AND     PROD.STATO_DI_VENDITA = 'PRE'
        AND     PRZ.FLG_ANNULLATO = 'N'
        AND     SCH.FLG_ANNULLATO = 'N'
        AND     BRK.ID_PROIEZIONE = PRZ.ID_PROIEZIONE
        AND     PRZ.ID_SCHERMO = SCH.ID_SCHERMO
        AND     CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO(+) = CD_COMUNICATO.ID_MATERIALE_DI_PIANO
        AND     CD_MATERIALE_DI_PIANO.ID_MATERIALE = CD_MATERIALE.ID_MATERIALE(+)
        AND     SCH.ID_SALA NOT IN (SELECT ID_SALA FROM CD_SALA
                    WHERE ID_SALA NOT IN (SELECT * FROM TABLE (p_id_list_sale)))
        GROUP BY CD_MATERIALE.ID_MATERIALE, CD_MATERIALE.DESCRIZIONE, CD_MATERIALE.TITOLO;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_DETT_MATERIALI: errore ' || SQLERRM);
END FU_DETT_MATERIALI;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_MATERIALI_II
-- DESCRIZIONE:  restituisce informazioni sui materiali associati al gruppo di comunicati
--
-- OUTPUT: info sui materiali
--
-- INPUT:
--  p_id_sogg                id del soggetto di piano
--  p_id_tipo_break          id del tipo break
--  p_durata                 la durata del comunicato
--  p_session_id             la sessione HTTP di riferimento per la ricerca
--  p_proid                  il proid al quale fare riferimento per identificare l'elenco di spot
--  p_id_prodotto_acquistato id del prodotto acquistato cui i comunicati si riferiscono
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 20 Dicembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETT_MATERIALI_II(  p_id_sogg                 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                p_id_tipo_break           CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                p_durata                  CD_COEFF_CINEMA.DURATA%TYPE,
                                p_session_id              CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                p_proid                   CD_RICERCA_COMP_SCHERMI.PROID%TYPE,                                     
                                p_id_prodotto_acquistato  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE
                             )  RETURN C_DETT_MATERIALI
IS
    v_return_value  C_DETT_MATERIALI;
BEGIN
    OPEN v_return_value
            FOR
            SELECT  COUNT(ID_COMUNICATO) COMUN, 
                    CD_MATERIALE.ID_MATERIALE, 
                    CD_MATERIALE.TITOLO, 
                    CD_MATERIALE.DESCRIZIONE
            FROM    CD_COMUNICATO, 
                    CD_TIPO_BREAK, 
                    CD_COEFF_CINEMA, 
                    CD_FORMATO_ACQUISTABILE,
                    CD_PRODOTTO_ACQUISTATO,
                    CD_PRODOTTO_VENDITA, 
                    CD_RICERCA_COMP_SCHERMI,
                    CD_MATERIALE_DI_PIANO, 
                    CD_MATERIALE
            WHERE   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO = p_id_sogg
            AND     CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
            AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid           
            AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = p_id_tipo_break
            AND     CD_TIPO_BREAK.ID_TIPO_BREAK = CD_PRODOTTO_VENDITA.ID_TIPO_BREAK
            AND     CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
            AND     CD_COEFF_CINEMA.DURATA = p_durata
            AND     CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF
            AND     CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV = CD_RICERCA_COMP_SCHERMI.DATA_RIF        
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
            AND     CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_COMUNICATO.FLG_ANNULLATO = 'N'
            AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
            AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
            AND     CD_TIPO_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO(+) = CD_COMUNICATO.ID_MATERIALE_DI_PIANO
            AND     CD_MATERIALE_DI_PIANO.ID_MATERIALE = CD_MATERIALE.ID_MATERIALE(+)            
            --AND     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA = 'PRE'    
            AND     CD_COMUNICATO.ID_SALA = CD_RICERCA_COMP_SCHERMI.ID_SALA
            GROUP BY CD_MATERIALE.ID_MATERIALE, CD_MATERIALE.DESCRIZIONE, CD_MATERIALE.TITOLO;
    RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_DETT_MATERIALI: errore ' || SQLERRM);
END FU_DETT_MATERIALI_II;

-- --------------------------------------------------------------------------------------------
-- FUNCTION fu_elenco_sale
-- DESCRIZIONE:  restituisce l'elenco delle sale in base ai criteri di ricerca impostati
--
-- OUTPUT: elenco delle sale dove e prevista la stessa programmazione pubblicitaria
--
-- INPUT:
-- p_id_circuito                identificativo del circuito
-- p_id_cliente                 identificativo del cliente
-- p_id_fascia                  identificativo della fascia oraria
-- p_proid                      codice identificativo del gruppo di comunicati
-- p_data_inizio                data inizio della ricerca
-- p_data_fine                  data_fine della ricerca
-- p_stato_di_vendita           stato di vendita del gruppo di comunicati
--
--  REALIZZATORE   Antonio Colucci, Teoresigroup, Gennaio 2010
--  NOTA: La funzione c'era gia ma non era descritta da alcun commento 
--  MODIFICHE
--         08/06/2010 Marletta Angelo, Teoresi srl
--                  subquery edelweiss ottimizzata
--         06/09/2010 Marletta Angelo, Teoresi srl
--                  Ottimizzazione subquery edelweiss
--         24/09/2010 Marletta Angelo, Teoresi srl
--                  Aggiunto filtro soggetto, edelweiss unificata, ottimizzazione ricerca per circuito
--         11/10/2010 Colucci Antonio, Teoresi srl
--                  inserito order by nel recupero della classe merceologica ed 
--                  inserito filtro (Livello = 1) nell'estrazione della categoria merceologica
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_SALE(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, 
                        p_id_cliente VI_CD_CLIENTE.ID_CLIENTE%TYPE,
                        P_PROID VARCHAR2, 
                        P_DATA_INIZIO DATE,
                        P_DATA_FINE DATE, 
                        p_stato_di_vendita VARCHAR2,
                        p_data_inizio_intervallo DATE,
                        p_data_fine_intervallo DATE
                        ) RETURN C_SALE IS
V_SALE C_SALE;
p_cod_sogg              PROSOGG.SO_INT_U_COD_INTERL%TYPE;
p_id_cinema             CD_CINEMA.ID_CINEMA%TYPE;
p_id_sala               CD_SALA.ID_SALA%TYPE;
BEGIN
OPEN V_SALE FOR
SELECT DISTINCT INSIEME_UNO.ID_SALA, NOME_SALA, NOME_CINEMA||' - '||COMUNE NOME
FROM CD_CINEMA CINEMA, CD_COMUNE COMUNE,CD_SALA SALA,
(
    select distinct
            id_sala,
            proid,
            MIN(datapro) over (partition by proid,prog,id_sala) DAIN,
            MAX(datapro) over (partition by proid,prog,id_sala) DAFIN
        from (
            SELECT distinct id_sala, numcom,proid,sum(nuovo) over(partition by id_sala order by datapro) prog, datapro from (
                SELECT 
                    id_sala,
                    NUMCOM,
                    PROID,
                    case
                        when row_number() over (partition by id_sala order by datapro)=1 then 1
                        when proid!=lag(proid) over (partition by id_sala order by datapro) then 1
                        else 0
                    end nuovo,
                    datapro
                FROM
                    (
                    --EDELWEISS 5
                    WITH SCHERMI AS
                    (SELECT ID_SCHERMO, ID_SALA FROM (                        
                        SELECT S.ID_SCHERMO,S.ID_SALA,null ID_CIRCUITO FROM CD_SCHERMO S
                        UNION ALL
                        SELECT S.ID_SCHERMO,S.ID_SALA, p_id_circuito ID_CIRCUITO
                            FROM CD_SCHERMO S,CD_CIRCUITO_SCHERMO C,CD_LISTINO L
                        WHERE
                            C.ID_SCHERMO = s.ID_SCHERMO
                            AND C.ID_LISTINO = L.ID_LISTINO
                            AND p_data_inizio BETWEEN L.DATA_INIZIO AND L.DATA_FINE+1
                            AND C.ID_CIRCUITO = p_id_circuito AND C.FLG_ANNULLATO = 'N'
                            AND p_id_circuito is not null
                        ) WHERE p_id_circuito IS NULL AND ID_CIRCUITO IS NULL OR ID_CIRCUITO = p_id_circuito)
                    SELECT DATAPRO,id_sala,PROID,NUMCOM
                    FROM (
                    SELECT
                    DATAPRO,
                    id_sala,
                    CASE WHEN
                        ROW_NUMBER() OVER (PARTITION BY DATAPRO,id_sala ORDER BY DATAPRO,id_sala,QUID) = 1 THEN 
                        ';' || VENCD.fu_cd_string_agg(quid) OVER (PARTITION BY DATAPRO,id_sala)
                        ELSE null
                    END PROID,
                    COUNT(1) OVER (PARTITION BY DATAPRO,id_sala) NUMCOM
                    FROM
                    (
                    SELECT DISTINCT
                    CD_COMUNICATO.DATA_EROGAZIONE_PREV DATAPRO,
                    sum(
                        distinct
                        case when PROSOGG.SO_INT_U_COD_INTERL=p_id_cliente then 1
                        else 0 end
                    ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_cliente,
                    sum(
                        distinct
                        case when PROSOGG.SO_COD_SOGG=p_cod_sogg then 1
                        else 0 end
                    ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_soggetto,
                    CD_COMUNICATO.ID_SALA id_sala,
                        LPAD(CD_BREAK.ID_TIPO_BREAK,2,0)                        -- tipo break
                        || LPAD(CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO,7,0)  -- soggetto di piano
                        || LPAD(CD_COEFF_CINEMA.DURATA,3,0)                     -- durata in secondi
                        || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_NT_COD_CAT_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_NT_COD_CAT_MERC),3,0)                -- categoria merceologica
                        || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_COD_CL_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_COD_CL_MERC),2,0)                  -- classe merceologica
                        || LPAD(CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO,9,0)       -- prodotto acquistato
                    QUID
                    FROM
                        CD_COMUNICATO,
                        CD_SOGGETTO_DI_PIANO,
                        PROSOGG,
                        CD_PRODOTTO_ACQUISTATO,
                        CD_FORMATO_ACQUISTABILE,
                        CD_COEFF_CINEMA,
                        CD_BREAK,
                        CD_PROIEZIONE,
                        SCHERMI,
                        CD_SALA,
                        CD_CINEMA
                    WHERE
                        --JOIN
                        CD_COMUNICATO.ID_SOGGETTO_DI_PIANO=CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO
                        --AND CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG(+)
                        AND (CD_SOGGETTO_DI_PIANO.DESCRIZIONE = 'SOGGETTO NON DEFINITO' 
                                or
                             CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG)
                        AND CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL = PROSOGG.SO_INT_U_COD_INTERL(+)
                        AND PROSOGG.LIVELLO = 1
                        AND CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                        AND CD_FORMATO_ACQUISTABILE.ID_FORMATO=CD_PRODOTTO_ACQUISTATO.ID_FORMATO
                        AND CD_COEFF_CINEMA.ID_COEFF=CD_FORMATO_ACQUISTABILE.ID_COEFF
                        AND CD_COMUNICATO.ID_BREAK=CD_BREAK.ID_BREAK
                        AND CD_BREAK.ID_PROIEZIONE=CD_PROIEZIONE.ID_PROIEZIONE
                        AND CD_PROIEZIONE.ID_SCHERMO=SCHERMI.ID_SCHERMO
                        AND SCHERMI.ID_SALA=CD_SALA.ID_SALA
                        AND CD_SALA.ID_CINEMA=CD_CINEMA.ID_CINEMA
                        --FILTRI
                        AND CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                        AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
                        AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                        AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL 
                        AND INSTR(UPPER(NVL(p_stato_di_vendita, CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)),CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA) >0
                        AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
                        AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
                        AND CD_PROIEZIONE.ID_FASCIA = 2
                        AND (p_id_sala is null OR CD_SALA.ID_SALA = p_id_sala)
                        AND (p_id_cinema is null OR CD_CINEMA.ID_CINEMA = p_id_cinema)
                        AND CD_CINEMA.FLG_VIRTUALE = 'N'
                    )t1
                        where (p_id_cliente is null or match_cliente = 1)
                        and (p_cod_sogg is null or match_soggetto = 1)
                    )t2
                    WHERE PROID IS NOT NULL
                    ORDER BY id_sala,DATAPRO,PROID
                 )EDELWEISS
            )
       )
)INSIEME_UNO
WHERE  PROID = P_PROID
AND DAIN = p_data_inizio_intervallo
AND DAFIN = p_data_fine_intervallo
AND SALA.ID_SALA = INSIEME_UNO.ID_SALA
AND SALA.ID_CINEMA = CINEMA.ID_CINEMA
AND CINEMA.ID_COMUNE = COMUNE.ID_COMUNE
ORDER BY NOME, NOME_SALA;
RETURN V_SALE;

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20038,'FUNZIONE FU_ELENCO_SALE: ERRORE ' || SQLERRM);

END FU_ELENCO_SALE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_POS_PRIVILEGIATA
-- DESCRIZIONE:  Restituisce la posizione privilegiata sulla base della posizione di rigore
--
-- OUTPUT: una stringa contenente la posizione privilegiata
-- INPUT:
--  p_pos_rigore             la posizione di rigore
--
--  REALIZZATORE  Roberto Barbaro, Teoresi srl, Gennaio 2010
--
--  MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_POS_PRIVILEGIATA(p_pos_rigore          CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE)
                                 RETURN VARCHAR2
IS
    v_posizione  VARCHAR2(12);
BEGIN
    v_posizione := '';

        SELECT DESCRIZIONE
        INTO   v_posizione
        FROM   CD_POSIZIONE_RIGORE
        WHERE  COD_POSIZIONE=p_pos_rigore;

    RETURN v_posizione;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_GET_POS_PRIVILEGIATA: errore ' || SQLERRM);
END FU_GET_POS_PRIVILEGIATA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_DES_INFO_MERC
-- DESCRIZIONE:  Restituisce la descrizione di settore, categoria e classe merceologica di un comunicato
--
-- OUTPUT: le tre descrizioni in oggetto
-- INPUT:
--  p_cat_merc             codice della categoria merceologica
--  p_cl_merc              codice della classe merceologica
--
--  REALIZZATORE  Roberto Barbaro, Teoresi srl, Febbraio 2010
--
--  MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_DES_INFO_MERC(p_cat_merc    PROSOGG.NL_NT_COD_CAT_MERC%TYPE,
                              p_cl_merc     PROSOGG.NL_COD_CL_MERC%TYPE)
                                 RETURN C_DES_MERC
IS
    v_des_merc  C_DES_MERC;
BEGIN

    OPEN V_DES_MERC FOR
        SELECT  DES_SETT_MERC, DES_CAT_MERC, DES_CL_MERC
        FROM    NIELSETT, NIELSCAT, NIELSCL
        WHERE   NIELSCL.NT_COD_CAT_MERC=p_cat_merc
        AND     NIELSCL.COD_CL_MERC=p_cl_merc
        AND     NIELSCAT.COD_CAT_MERC=NIELSCL.NT_COD_CAT_MERC
        AND     NIELSETT.COD_SETT_MERC=NIELSCAT.NS_COD_SETT_MERC;

    RETURN v_des_merc;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20038,'FU_GET_DES_INFO_MERC: errore ' || SQLERRM);
END FU_GET_DES_INFO_MERC;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_POPOLA_RCS
-- DESCRIZIONE:  
--      popola la tabella di ricerca composizione schermi. Prima della chiamata
--      svecchia la tabella, eliminando tutte le ricerche piu' vecchie di p_vecchiaia 
--      minuti e le eventuali ricerche effettuate nel corso della stessa sessione HTTP.
-- OUTPUT: 
--      p_esito                 se negativo indica un errore
-- INPUT:
--      p_id_circuito           id del circuito da esaminare
--      p_data_inizio           data inizio del periodo di riferimento
--      p_data_fine             data fine del periodo di riferimento
--      p_id_cliente            id del cliente
--      p_cod_sogg              codice del soggetto
--      p_stato_vendita         stato di vendita
--      p_id_cinema             id del cinema
--      p_id_sala               id della sala
--      p_session_id            id della sessione HTTP attiva
--      p_vecchiaia             il valore in minuti che indica dopo quanto una sessione e' considerata 
--                              da cancellare
-- REALIZZATORE  
--      Tommaso D'Anna, Teoresi srl, 13/12/2010
--      Modifiche 
---     Mauro Viel Altran Italia 29/03/2011  inserito outer join  su  PROSOGG.LIVELLO (+)
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_POPOLA_RCS(   p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                            p_data_inizio           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                            p_data_fine             CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                            p_id_cliente            VI_CD_CLIENTE.ID_CLIENTE%TYPE,
                            p_cod_sogg              PROSOGG.SO_INT_U_COD_INTERL%TYPE,
                            p_stato_di_vendita      CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                            p_id_cinema             CD_CINEMA.ID_CINEMA%TYPE,
                            p_id_sala               CD_SALA.ID_SALA%TYPE,
                            p_session_id            CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                            p_vecchiaia             NUMBER,
                            p_esito                 OUT NUMBER) 
IS
BEGIN
    p_esito:= 1;
    
    SAVEPOINT SP_PR_POPOLA_RCS;
    
    DELETE FROM CD_RICERCA_COMP_SCHERMI
    WHERE  ((SYSDATE - CD_RICERCA_COMP_SCHERMI.DATA_RICERCA ) * 1440 ) > p_vecchiaia
    OR     SESSION_ID = p_session_id;    
    
    FOR COMP_SCHERMI IN 
    (
       --EDELWEISS 5
        WITH SCHERMI AS
        (SELECT ID_SCHERMO, ID_SALA FROM (                        
            SELECT S.ID_SCHERMO,S.ID_SALA,null ID_CIRCUITO FROM CD_SCHERMO S
            UNION ALL
            SELECT S.ID_SCHERMO,S.ID_SALA, p_id_circuito ID_CIRCUITO
                FROM CD_SCHERMO S,CD_CIRCUITO_SCHERMO C,CD_LISTINO L
            WHERE
                C.ID_SCHERMO = s.ID_SCHERMO
                AND C.ID_LISTINO = L.ID_LISTINO
                AND p_data_inizio BETWEEN L.DATA_INIZIO AND L.DATA_FINE+1
                AND C.ID_CIRCUITO = p_id_circuito AND C.FLG_ANNULLATO = 'N'
                AND p_id_circuito is not null
            ) WHERE p_id_circuito IS NULL AND ID_CIRCUITO IS NULL OR ID_CIRCUITO = p_id_circuito)
        SELECT DATAPRO,ID_SALA,PROID,NUMCOM
        FROM (
            SELECT
            DATAPRO,
            ID_SALA,
            CASE WHEN
                ROW_NUMBER() OVER (PARTITION BY DATAPRO,ID_SALA ORDER BY DATAPRO,ID_SALA,QUID) = 1 THEN 
                ';' || VENCD.fu_cd_string_agg(quid) OVER (PARTITION BY DATAPRO,ID_SALA)
                ELSE null
            END PROID,
            COUNT(1) OVER (PARTITION BY DATAPRO,ID_SALA) NUMCOM
            FROM
            (
                SELECT DISTINCT
                CD_COMUNICATO.DATA_EROGAZIONE_PREV DATAPRO,
                sum(
                    distinct
                    case when PROSOGG.SO_INT_U_COD_INTERL=p_id_cliente then 1
                    else 0 end
                ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_cliente,
                sum(
                    distinct
                    case when PROSOGG.SO_COD_SOGG=p_cod_sogg then 1
                    else 0 end
                ) over(partition by CD_COMUNICATO.DATA_EROGAZIONE_PREV,CD_COMUNICATO.ID_SALA) match_soggetto,
                CD_COMUNICATO.ID_SALA id_sala,
                    LPAD(CD_BREAK.ID_TIPO_BREAK,2,0)                        -- tipo break
                    || LPAD(CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO,7,0)  -- soggetto di piano
                    || LPAD(CD_COEFF_CINEMA.DURATA,3,0)                     -- durata in secondi
                    || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_NT_COD_CAT_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_NT_COD_CAT_MERC),3,0)                -- categoria merceologica
                    || LPAD(FIRST_VALUE(NVL(PROSOGG.NL_COD_CL_MERC,0)) OVER (PARTITION BY CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL order by PROSOGG.NL_COD_CL_MERC),2,0)                  -- classe merceologica
                    || LPAD(CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO,9,0)       -- prodotto acquistato
                QUID
                FROM
                    CD_COMUNICATO,
                    CD_SOGGETTO_DI_PIANO,
                    PROSOGG,
                    CD_PRODOTTO_ACQUISTATO,
                    CD_FORMATO_ACQUISTABILE,
                    CD_COEFF_CINEMA,
                    CD_BREAK,
                    CD_PROIEZIONE,
                    SCHERMI,
                    CD_SALA,
                    CD_CINEMA
                WHERE
                    --JOIN
                    CD_COMUNICATO.ID_SOGGETTO_DI_PIANO=CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO
                    --AND CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG(+)
                    AND (CD_SOGGETTO_DI_PIANO.DESCRIZIONE = 'SOGGETTO NON DEFINITO' 
                            or
                         CD_SOGGETTO_DI_PIANO.DESCRIZIONE = PROSOGG.SO_DES_SOGG )
                    AND CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL = PROSOGG.SO_INT_U_COD_INTERL(+)
                    AND PROSOGG.LIVELLO (+) = 1 
                    AND CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                    AND CD_FORMATO_ACQUISTABILE.ID_FORMATO=CD_PRODOTTO_ACQUISTATO.ID_FORMATO
                    AND CD_COEFF_CINEMA.ID_COEFF=CD_FORMATO_ACQUISTABILE.ID_COEFF
                    AND CD_COMUNICATO.ID_BREAK=CD_BREAK.ID_BREAK
                    AND CD_BREAK.ID_PROIEZIONE=CD_PROIEZIONE.ID_PROIEZIONE
                    AND CD_PROIEZIONE.ID_SCHERMO=SCHERMI.ID_SCHERMO
                    AND SCHERMI.ID_SALA=CD_SALA.ID_SALA
                    AND CD_SALA.ID_CINEMA=CD_CINEMA.ID_CINEMA
                    --FILTRI
                    AND CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                    AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
                    AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                    AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL 
                    AND INSTR(UPPER(NVL(p_stato_di_vendita, CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)),CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA) >0
                    AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
                    AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
                    AND CD_PROIEZIONE.ID_FASCIA = 2
                    AND     (p_id_sala      IS NULL OR CD_SALA.ID_SALA      = p_id_sala)
                    AND     (p_id_cinema    IS NULL OR CD_CINEMA.ID_CINEMA  = p_id_cinema)
                    AND CD_CINEMA.FLG_VIRTUALE = 'N'
            )t1
                WHERE   (p_id_cliente   IS NULL OR match_cliente        = 1)
                AND     (p_cod_sogg     IS NULL OR match_soggetto       = 1)
        )t2
        WHERE PROID IS NOT NULL
        ORDER BY ID_SALA,DATAPRO,PROID 
    )
    LOOP
        INSERT INTO CD_RICERCA_COMP_SCHERMI
        (
            SESSION_ID,
            ID_SALA,
            DATA_RIF,
            PROID,
            NUM_COMUNICATI
        )
        VALUES
        (
            p_session_id,
            COMP_SCHERMI.ID_SALA,
            COMP_SCHERMI.DATAPRO,
            COMP_SCHERMI.PROID,
            COMP_SCHERMI.NUMCOM
        );
    END LOOP;    
   
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20437,'PROCEDURA PR_POPOLA_RCS: errore ' || SQLERRM);
        ROLLBACK TO SP_PR_POPOLA_RCS;
END PR_POPOLA_RCS;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_RCS
-- DESCRIZIONE: restituisce, raggruppati per periodo, le sale accomunate
--              da proiezioni uguali.
-- OUTPUT:  cursore contenente i seguenti valori per riga
--      a_numero_sale           rappresenta il numero di sale che, nel periodo di riferimento, sono
--                            accomunate dalla stessa proiezione
--      a_numero_comunicati     il numero di comunicati che compongono la proiezione
--      a_data_ininzio          data inizio del periodo di riferimento
--      a_data_fine             data fine del periodo di riferimento
--      a_proid                 una stringa contenente le informazioni di composizione della proiezione
--
-- INPUT:
--      p_session_id            id della sessione HTTP attiva
--
--  REALIZZATORE
--      Tommaso D'Anna, Teoresi srl, 14/12/2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RCS( p_session_id CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE )
                                 RETURN C_COMP_SCHERMI
IS
    V_COMP_SCHERMI C_COMP_SCHERMI;
BEGIN
    OPEN V_COMP_SCHERMI FOR
        SELECT DISTINCT
            COUNT(DISTINCT ID_SALA) OVER (PARTITION BY PROID) AS NUMERO_SALE,
            NUM_COMUNICATI AS NUMERO_COMUNICATI,
            MIN(DATA_RIF) OVER (PARTITION BY PROID) AS DATA_INIZIO,
            MAX(DATA_RIF) OVER (PARTITION BY PROID) AS DATA_FINE,
            PROID
        FROM
            CD_RICERCA_COMP_SCHERMI
        WHERE SESSION_ID = p_session_id
        ORDER BY NUMERO_SALE DESC;
    RETURN V_COMP_SCHERMI;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20095,'FU_GET_RCS: errore ' || SQLERRM);
END FU_GET_RCS;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_RCS_SINGOLO
-- DESCRIZIONE: restituisce, raggruppati per periodo, l'elenco delle sale con i
--              corrispondenti comunicati.Se l'intervallo di ricerca e maggiore di un giorno
--              ogni sala viene raggruppata nel tempo im base alla composizione dei comunicati 
-- OUTPUT:  cursore contenente i seguenti valori per riga
--      a_nome_cinema           
--      a_comune
--      a_nome_sala
--      a_numero_comunicati     il numero di comunicati che compongono la proiezione
--      a_data_ininzio          data inizio del periodo di riferimento
--      a_data_fine             data fine del periodo di riferimento
--      a_proid                 una stringa contenente le informazioni di composizione della proiezione
--
-- INPUT:
--      p_session_id            id della sessione HTTP attiva
--
--  REALIZZATORE
--      Antonio Colucci , Teoresi srl, 07/01/2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RCS_SINGOLO( p_session_id CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE )
                           RETURN C_COMP_SINGOLO_SCHERMO
IS
    V_COMP_SCHERMO_SINGOLO C_COMP_SINGOLO_SCHERMO;
BEGIN
    OPEN V_COMP_SCHERMO_SINGOLO FOR
        select distinct
            cd_ricerca_comp_schermi.id_sala,
            cd_ricerca_comp_schermi.NUM_COMUNICATI NUMCOM,
            min(data_rif) over (partition by cd_ricerca_comp_schermi.id_sala,cd_ricerca_comp_schermi.proid) DAIN,
            max(data_rif) over (partition by cd_ricerca_comp_schermi.id_sala,cd_ricerca_comp_schermi.proid) DAFIN,
            cd_ricerca_comp_schermi.proid,
            cd_cinema.nome_cinema ||'-'||cd_comune.comune NOCI,
            cd_sala.nome_sala NOSA
        from 
            cd_ricerca_comp_schermi,
            cd_cinema,
            cd_sala,
            cd_comune
        where
            cd_ricerca_comp_schermi.session_id = p_session_id
        and cd_ricerca_comp_schermi.id_sala = cd_sala.id_sala
        and cd_sala.id_cinema = cd_cinema.id_cinema
        and cd_cinema.id_comune = cd_comune.id_comune;
    RETURN V_COMP_SCHERMO_SINGOLO;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20095,'FU_GET_RCS_SINGOLO: errore durante l''estrazione dei dati' || SQLERRM);
END FU_GET_RCS_SINGOLO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_SALE_RCS
-- DESCRIZIONE:  restituisce l'elenco delle sale in base ai criteri di ricerca impostati
--
-- INPUT:
--      p_session_id            id della sessione HTTP attiva
--      p_proid                 il PROID di riferimento
-- OUTPUT:  cursore contenente i seguenti valori per riga
--      a_id_sala               id della sala di riferimento
--      a_nome_sala             nome della sala di riferimento
--      a_nome                  coppia nome cinema - comune
--
--  REALIZZATORE
--      Tommaso D'Anna, Teoresi srl, 14/12/2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_SALE_RCS(    p_session_id    CD_RICERCA_COMP_SCHERMI.SESSION_ID%TYPE,
                                p_proid         CD_RICERCA_COMP_SCHERMI.PROID%TYPE 
                            )
                                 RETURN C_SALE
IS
    V_SALE C_SALE;
BEGIN
    OPEN V_SALE FOR
        SELECT DISTINCT
            CD_RICERCA_COMP_SCHERMI.ID_SALA,
            CD_CINEMA.NOME_CINEMA || ' - ' || CD_COMUNE.COMUNE AS NOME,
            CD_SALA.NOME_SALA
        FROM
            CD_RICERCA_COMP_SCHERMI,
            CD_SALA,
            CD_CINEMA,
            CD_COMUNE
        WHERE   CD_RICERCA_COMP_SCHERMI.SESSION_ID = p_session_id
        AND     CD_RICERCA_COMP_SCHERMI.PROID = p_proid
        AND     CD_RICERCA_COMP_SCHERMI.ID_SALA = CD_SALA.ID_SALA
        AND     CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
        AND     CD_CINEMA.ID_COMUNE = CD_COMUNE.ID_COMUNE
        ORDER BY ID_SALA;
    RETURN V_SALE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20095,'FU_ELENCO_SALE_RCS: errore ' || SQLERRM);
END FU_ELENCO_SALE_RCS;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CORE_INFO_RISCHI
-- DESCRIZIONE:  restituisce l'elenco dei possibili rischi (target, segui il film,
--               tutela) di un prodotto acquistato. Viene utilizzata dal cappello
--               FU_INFO_RISCHI
--
-- INPUT:
--      p_id_prodotto_acquistato      id del prodotto acquistato di riferimento
--      p_id_soggetto_di_piano        id del soggetto di piano di riferimento  
--
-- OUTPUT:  C_INFO_RISCHI_COMUNICATO con valorizzati:
--      a_rischio_target        
--      a_rischio_segui_film
--      a_descrizione_target
--      a_nome_spettacolo        
--      a_id_cliente           
--      a_id_soggetto_di_piano
--      a_id_materiale_di_piano
--          I tre ID verranno usati per chiamare la FU_VERIFICA_TUTELA
--
--  REALIZZATORE
--      Tommaso D'Anna, Teoresi srl, 13 Aprile 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CORE_INFO_RISCHI(    
                                p_id_prodotto_acquistato        CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_soggetto_di_piano             CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE
                            )
                                 RETURN C_INFO_RISCHI_COMUNICATO
IS
    V_INFO_RISCHI_COMUNICATO C_INFO_RISCHI_COMUNICATO;
BEGIN
    OPEN V_INFO_RISCHI_COMUNICATO FOR
        SELECT DISTINCT 
            decode(CD_PRODOTTO_VENDITA.ID_TARGET, null, 'N','S') 
                AS RISCHIO_TARGET,
            CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM 
                AS RISCHIO_SEGUI_IL_FILM,
            null
                AS RISCHIO_TUTELA,
            CD_TARGET.DESCR_TARGET
                AS DESCRIZIONE_TARGET,
            CD_SPETTACOLO.NOME_SPETTACOLO
                AS NOME_SPETTACOLO,               
            CD_MATERIALE.ID_MATERIALE   
                AS ID_MATERIALE,
            CD_MATERIALE.TITOLO
                AS TITOLO_MATERIALE,               
            CD_PIANIFICAZIONE.ID_CLIENTE,
            CD_COMUNICATO.ID_MATERIALE_DI_PIANO
        FROM 
            CD_PRODOTTO_ACQUISTATO,
            CD_PRODOTTO_VENDITA,
            CD_PIANIFICAZIONE,
            CD_COMUNICATO,
            CD_MATERIALE_DI_PIANO,
            CD_MATERIALE,
            CD_TARGET,
            CD_SPETTACOLO
        WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO   = p_id_prodotto_acquistato
        AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO              = 'N'
        AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA      = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND     CD_PRODOTTO_ACQUISTATO.ID_PIANO                 = CD_PIANIFICAZIONE.ID_PIANO
        AND     CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO             = CD_PIANIFICAZIONE.ID_VER_PIANO
        AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO   = CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
        AND     CD_PRODOTTO_VENDITA.ID_TARGET                   = CD_TARGET.ID_TARGET (+)
        AND     CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO            = CD_SPETTACOLO.ID_SPETTACOLO (+)
        AND     CD_COMUNICATO.ID_SOGGETTO_DI_PIANO              = p_soggetto_di_piano
        AND     CD_COMUNICATO.FLG_ANNULLATO                     = 'N'
        AND     CD_COMUNICATO.FLG_SOSPESO                       = 'N'
        AND     CD_COMUNICATO.ID_MATERIALE_DI_PIANO             = CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO(+)
        AND     CD_MATERIALE.ID_MATERIALE(+)                    = CD_MATERIALE_DI_PIANO.ID_MATERIALE;
    RETURN V_INFO_RISCHI_COMUNICATO;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20095,'FU_CORE_INFO_RISCHI: errore ' || SQLERRM);
END FU_CORE_INFO_RISCHI;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_RISCHI
-- DESCRIZIONE:  restituisce l'elenco dei possibili rischi (target, segui il film,
--               tutela) di un prodotto acquistato.
--
-- INPUT:
--      p_id_prodotto_acquistato      id del prodotto acquistato di riferimento
--      p_id_soggetto_di_piano        id del soggetto di piano di riferimento 
--
-- OUTPUT:  C_INFO_RISCHI_COMUNICATO con tutti i dati valorizzati.
--
--  REALIZZATORE:
--      Tommaso D'Anna, Teoresi srl, 13 Aprile 2011
--  MODIFICHE:
--      Tommaso D'Anna, Teoresi srl, 26 Maggio 2011
--      p_soggetto_di_piano contiene erroneamente ID_SOGGETTO_DI_PIANO
--      recupero di COD_SOGG tramite ID_SOGGETTO_DI_PIANO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_RISCHI(    
                            p_id_prodotto_acquistato        CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                            p_soggetto_di_piano             CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE
                       )
                        RETURN C_INFO_RISCHI_COMUNICATO
IS
    V_INFO_RISCHI_COMUNICATO        C_INFO_RISCHI_COMUNICATO;
    RECORD_INFO_RISCHI_COMUNICATO   R_INFO_RISCHI_COMUNICATO;
BEGIN
    V_INFO_RISCHI_COMUNICATO := FU_CORE_INFO_RISCHI(p_id_prodotto_acquistato, p_soggetto_di_piano);
    FETCH V_INFO_RISCHI_COMUNICATO INTO RECORD_INFO_RISCHI_COMUNICATO;
    OPEN V_INFO_RISCHI_COMUNICATO FOR
        SELECT
            RECORD_INFO_RISCHI_COMUNICATO.a_rischio_target
                AS RISCHIO_TARGET,
            RECORD_INFO_RISCHI_COMUNICATO.a_rischio_segui_film
                AS RISCHIO_SEGUI_IL_FILM,
           -- FU_VERIFICA_TUTELA(RECORD_INFO_RISCHI_COMUNICATO.a_id_cliente, p_soggetto_di_piano, RECORD_INFO_RISCHI_COMUNICATO.a_id_materiale_di_piano)
                FU_CD_VERIFICA_TUTELA(RECORD_INFO_RISCHI_COMUNICATO.a_id_cliente, CD_SOGGETTO_DI_PIANO.COD_SOGG, RECORD_INFO_RISCHI_COMUNICATO.a_id_materiale) 
                AS RISCHIO_TUTELA,
            RECORD_INFO_RISCHI_COMUNICATO.a_descrizione_target
                AS DESCRIZIONE_TARGET,
            RECORD_INFO_RISCHI_COMUNICATO.a_nome_spettacolo
                AS NOME_SPETTACOLO,                
            RECORD_INFO_RISCHI_COMUNICATO.a_id_materiale
                AS ID_MATERIALE,
            RECORD_INFO_RISCHI_COMUNICATO.a_titolo_materiale
                AS TITOLO_MATERIALE,                       
            RECORD_INFO_RISCHI_COMUNICATO.a_id_cliente
                AS ID_CLIENTE,
            RECORD_INFO_RISCHI_COMUNICATO.a_id_materiale_di_piano
                AS ID_MATERIALE_DI_PIANO
        FROM 
            CD_SOGGETTO_DI_PIANO
        WHERE CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO = p_soggetto_di_piano;
    RETURN V_INFO_RISCHI_COMUNICATO;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20095,'FU_CORE_INFO_RISCHI: errore ' || SQLERRM);
END FU_INFO_RISCHI;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_MERCEOLOGIA
-- DESCRIZIONE:  restituisce la descrizione della merceologia di un prodotto acquistato.
--
-- INPUT:
--       p_categ_merc           categoria merceologica
--       p_classe_merc          classe merceologica
--
-- OUTPUT:  C_INFO_MERCEOLOGIA con tutti i dati valorizzati.
--
--  REALIZZATORE
--      Tommaso D'Anna, Teoresi srl, 19 Aprile 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_MERCEOLOGIA(    
                                p_categ_merc        VENCOM.NIELSCAT.COD_CAT_MERC%TYPE,
                                p_classe_merc       VENCOM.NIELSCL.COD_CL_MERC%TYPE
                            )   RETURN C_INFO_MERCEOLOGIA
IS
    V_INFO_MERCEOLOGIA C_INFO_MERCEOLOGIA;
BEGIN
    OPEN V_INFO_MERCEOLOGIA FOR
        SELECT 
            VENCOM.NIELSCAT.DES_CAT_MERC
                AS DESCRIZIONE_CATEGORIA,
            VENCOM.NIELSCL.DES_CL_MERC
                AS DESCRIZIONE_CLASSE
        FROM 
            VENCOM.NIELSCAT, 
            VENCOM.NIELSCL
        WHERE VENCOM.NIELSCAT.COD_CAT_MERC = p_categ_merc
        AND VENCOM.NIELSCL.COD_CL_MERC = p_classe_merc
        AND VENCOM.NIELSCL.NT_COD_CAT_MERC = VENCOM.NIELSCAT.COD_CAT_MERC;
    RETURN V_INFO_MERCEOLOGIA;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20095,'FU_INFO_MERCEOLOGIA: errore ' || SQLERRM);
END FU_INFO_MERCEOLOGIA;

END PA_CD_COMPONI_SCHERMI; 
/

