CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PRODOTTO_RICHIESTO IS

-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_PROD_RICH_MODULO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto richiesto nel sistema
--               a partire da un prodotto vendita
--
--
-- OPERAZIONI:
--  1) Memorizza il prodotto richiesto
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_tariffa            id della tariffa
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Simone Bottani , Altran, Novembre 2009
--
--  MODIFICHE:
-- Mauro Viel Altran Italia  14 Febbraio 2011 inserito il parametro id_spettacolo, numero_massimo_scherm per il nuovo prodotto segui il film. 
-- Mauro Viel Altran Italia Novembre 2011 gestito il nuovo campo flg_esclusivo per il segui il film. Un nuovo prodotto nascera 
--                          con il campo flg_esclusivo impostato ad S. In fase d'associazione tale valore potraa essere variato.
--                          lo storico delle variazioni sara mantenuto dalla tavola cd_sala_segui_film.FLG_ESCLUSIVO.
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_RICH_MODULO (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    p_sconto                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_id_spettacolo         cd_prodotti_richiesti.ID_SPETTACOLO%type,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_esito                 OUT NUMBER)
IS

v_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
v_seq CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE;
v_seq_prev CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_netto CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_periodo_piano CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
v_id_periodo_richiesta CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE;
v_stato_lavorazione CD_STATO_LAVORAZIONE.STATO_PIANIFICAZIONE%TYPE;
v_flg_esclusivo cd_prodotto_acquistato.flg_esclusivo%type;
v_flg_segui_il_film cd_prodotto_vendita.FLG_SEGUI_IL_FILM%type; 
BEGIN
--
p_esito     := 1;

       SAVEPOINT PR_CREA_PROD_RICH_MODULO;
--
     v_lordo := p_lordo;
     v_netto := PA_PC_IMPORTI.FU_NETTO(p_lordo, p_sconto);
     --
     SELECT LAV.STATO_PIANIFICAZIONE
     INTO v_stato_lavorazione
     FROM CD_PIANIFICAZIONE P, CD_STATO_LAVORAZIONE LAV
     WHERE P.ID_PIANO = p_id_piano
     AND P.ID_VER_PIANO = p_id_ver_piano
     AND P.ID_STATO_LAV = LAV.ID_STATO_LAV;
     IF v_stato_lavorazione = 'RICHIESTA' THEN
        v_id_periodo_richiesta := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_RICHIESTA(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);
     ELSIF v_stato_lavorazione = 'PIANO' THEN
        v_id_periodo_piano := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_PIANO(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);
     END IF;
     
     --
       begin
        SELECT CD_PRODOTTI_RICHIESTI_SEQ.CURRVAL INTO v_seq_prev FROM DUAL;
        EXCEPTION  
        WHEN OTHERS THEN
        v_seq_prev := 0;
       end;
    
    select flg_segui_il_film 
    into  v_flg_segui_il_film
    from  cd_prodotto_vendita
    where id_prodotto_vendita = p_id_prodotto_vendita;
    
    if v_flg_segui_il_film = 'S' then
      v_flg_esclusivo := 'S';
    end if;
       
       INSERT INTO CD_PRODOTTI_RICHIESTI
         ( ID_PRODOTTO_VENDITA,
           ID_FORMATO,
           ID_PIANO,
           ID_VER_PIANO,
           ID_IMPORTI_RICHIESTA,
           ID_IMPORTI_RICHIESTI_PIANO,
           IMP_LORDO,
           IMP_MAGGIORAZIONE,
           IMP_TARIFFA,
           IMP_NETTO,
           DATA_INIZIO,
           DATA_FINE,
           ID_MISURA_PRD_VE,
           FLG_TARIFFA_VARIABILE,
           COD_POSIZIONE,
           ID_TIPO_CINEMA,
           ID_SPETTACOLO,
           NUMERO_MASSIMO_SCHERMI,
           FLG_ESCLUSIVO
          )
        SELECT p_id_prodotto_vendita,
         p_id_formato,
         p_id_piano,
         p_id_ver_piano,
         v_id_periodo_richiesta,
         v_id_periodo_piano,
         v_lordo,
         p_maggiorazione AS MAGGIORAZIONE,
         p_tariffa AS TARIFFA,
         v_netto,
         p_data_inizio,
         p_data_fine,
         TARIFFA.ID_MISURA_PRD_VE,
         p_tariffa_variabile,
         p_id_posizione_rigore,
         p_id_tipo_cinema,
         p_id_spettacolo,
         p_numero_massimo_schermi,
         v_flg_esclusivo
        FROM
        CD_UNITA_MISURA_TEMP, CD_MISURA_PRD_VENDITA,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.ID_LISTINO = p_id_listino
        AND TARIFFA.DATA_INIZIO <= p_data_inizio
        AND TARIFFA.DATA_FINE >= p_data_fine
        AND TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND CD_UNITA_MISURA_TEMP.ID_UNITA = p_unita_temp;

        SELECT CD_PRODOTTI_RICHIESTI_SEQ.CURRVAL INTO v_seq FROM DUAL;
        
        
        if v_seq= v_seq_prev then
            RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_CREA_PROD_RICH_MODULO: INSERT NON ESEGUITA ');
        end if;

       INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTI_RICHIESTI)
        SELECT
        'C',v_netto,p_sconto,v_seq
        FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTI_RICHIESTI)
        VALUES('D',0,0,v_seq);
  --
  IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
       FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
         PR_SALVA_MAGGIORAZIONE(v_seq, p_list_maggiorazioni(i));
     END LOOP;
   END IF;

   IF p_list_id_area IS NOT NULL AND p_list_id_area.COUNT > 0 THEN
        FOR i IN 1..p_list_id_area.COUNT LOOP
          INSERT INTO CD_AREE_PRODOTTI_RICHIESTI(ID_AREA_NIELSEN, ID_PRODOTTI_RICHIESTI)
            VALUES(p_list_id_area(i),v_seq);
        END LOOP;
   END IF;

    -- IF p_id_posizione_rigore IS NOT NULL THEN
     --   PR_SALVA_MAGGIORAZIONE(v_seq, 1);
    -- END IF;
--

    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_CREA_PROD_RICH_MODULO: INSERT NON ESEGUITA '|| SQLERRM);
        ROLLBACK TO PR_CREA_PROD_RICH_MODULO;
     END PR_CREA_PROD_RICH_MODULO;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_PROD_ACQ_LIBERA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto richiesto nel sistema
--               a partire da un prodotto vendita
--
--
-- OPERAZIONI:
--  1) Memorizza il prodotto richiesto
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_tariffa            id della tariffa
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_list_id_ambito        lista degli ambiti
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Simone Bottani , Altran, Luglio 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------

PROCEDURE PR_CREA_PROD_RICH_LIBERA (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    p_sconto                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_esito                    OUT NUMBER)
IS

v_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
v_seq CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_netto CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_periodo_richiesta CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE;
v_id_periodo_piano CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
v_stato_lavorazione CD_STATO_LAVORAZIONE.STATO_PIANIFICAZIONE%TYPE;
BEGIN
--

p_esito     := 1;
      SAVEPOINT PR_CREA_PROD_RICH_LIBERA;
--
     v_lordo := p_lordo;
     v_netto := PA_PC_IMPORTI.FU_NETTO(p_lordo, p_sconto);
--
     SELECT LAV.STATO_PIANIFICAZIONE
     INTO v_stato_lavorazione
     FROM CD_PIANIFICAZIONE P, CD_STATO_LAVORAZIONE LAV
     WHERE P.ID_PIANO = p_id_piano
     AND P.ID_VER_PIANO = p_id_ver_piano
     AND P.ID_STATO_LAV = LAV.ID_STATO_LAV;
     --
     IF v_stato_lavorazione = 'RICHIESTA' THEN
        v_id_periodo_richiesta := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_RICHIESTA(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);
     ELSIF v_stato_lavorazione = 'PIANO' THEN
        v_id_periodo_piano := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_PIANO(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);
     END IF;
     --
     
     INSERT INTO CD_PRODOTTI_RICHIESTI
         ( ID_PRODOTTO_VENDITA,
           ID_FORMATO,
           ID_PIANO,
           ID_VER_PIANO,
           ID_IMPORTI_RICHIESTA,
           ID_IMPORTI_RICHIESTI_PIANO,
           IMP_LORDO,
           IMP_MAGGIORAZIONE,
           IMP_TARIFFA,
           IMP_NETTO,
           DATA_INIZIO,
           DATA_FINE,
           ID_MISURA_PRD_VE,
           FLG_TARIFFA_VARIABILE,
           COD_POSIZIONE,
           ID_TIPO_CINEMA
          )
        SELECT p_id_prodotto_vendita,
         p_id_formato,
         p_id_piano,
         p_id_ver_piano,
         v_id_periodo_richiesta,
         v_id_periodo_piano,
         v_lordo AS IMP_LORDO,
         p_maggiorazione AS MAGGIORAZIONE,
         p_tariffa AS TARIFFA,
         v_netto,
         p_data_inizio,
         p_data_fine,
         TARIFFA.ID_MISURA_PRD_VE,
         p_tariffa_variabile,
         p_id_posizione_rigore,
         p_id_tipo_cinema
        FROM CD_UNITA_MISURA_TEMP, CD_MISURA_PRD_VENDITA,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND TARIFFA.ID_LISTINO = p_id_listino
        AND TARIFFA.DATA_INIZIO <= p_data_inizio
        AND TARIFFA.DATA_FINE >= p_data_fine
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND CD_UNITA_MISURA_TEMP.ID_UNITA = p_unita_temp;

        SELECT CD_PRODOTTI_RICHIESTI_SEQ.CURRVAL INTO v_seq FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTI_RICHIESTI)
        SELECT
        'C',v_netto,p_sconto,v_seq
        FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTI_RICHIESTI)
        VALUES('D',0,0,v_seq);

        IF p_list_id_ambito IS NOT NULL AND p_list_id_ambito.COUNT > 0 THEN
            IF p_id_ambito = 1 THEN
                FOR i IN 1..p_list_id_ambito.COUNT LOOP
                    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI(ID_PRODOTTI_RICHIESTI, ID_SCHERMO)
                    VALUES(v_seq,p_list_id_ambito(i));
                END LOOP;
            ELSIF p_id_ambito = 2 THEN
                FOR i IN 1..p_list_id_ambito.COUNT LOOP
                    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI(ID_PRODOTTI_RICHIESTI, ID_SALA)
                    VALUES(v_seq,p_list_id_ambito(i));
                END LOOP;
            ELSIF p_id_ambito = 3 THEN
                FOR i IN 1..p_list_id_ambito.COUNT LOOP
                    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI(ID_PRODOTTI_RICHIESTI, ID_ATRIO)
                    VALUES(v_seq,p_list_id_ambito(i));
                END LOOP;
            ELSIF p_id_ambito = 4 THEN
                FOR i IN 1..p_list_id_ambito.COUNT LOOP
                    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI(ID_PRODOTTI_RICHIESTI, ID_CINEMA)
                    VALUES(v_seq,p_list_id_ambito(i));
                END LOOP;
            END IF;

        END IF;

       IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
         FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
             PR_SALVA_MAGGIORAZIONE(v_seq, p_list_maggiorazioni(i));
         END LOOP;
       END IF;
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_CREA_PROD_RICH_LIBERA: INSERT NON ESEGUITA, ERRORE: '||SQLERRM);
        ROLLBACK TO PR_CREA_PROD_RICH_LIBERA;
     END PR_CREA_PROD_RICH_LIBERA;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_PROD_RICH_MULTIPLO
--
-- DESCRIZIONE:  Effettua l'inserimento multiplo di prodotti, compresi tra le date di inizio e di fine indicate
--               nel sistema
--
--
-- OPERAZIONI:
--  1) Seleziona la tariffa per ogni settimana compresa nel periodo
--  2) Calcola gli importi relativi
--  3) Inserisce il prodotto
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_list_id_ambito        Lista di ambienti del prodotto
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_id_formato            id del formato acquistabile
--  p_perc_sconto           Percentuale di sconto applicata
--  p_unita_temp            unita temporale del prodotto inserito (Settimana, Mese ecc)
--  p_id_listino            id del listino utilizzato
--  p_id_posizione_rigore   id della posizione di rigore, se richiesta
--  p_tariffa_variabile     flag che indica se il prodotto e da creare con tariffa variabile o meno (il flag puo assumere il valore S o N)
--  p_list_maggiorazioni    lista di maggiorazioni applicate al prodotto acquistato
--  p_list_id_area          lista di aree nielsen applicate al prodotto acquistato. Viene utilizzato solo se il prodotto e geo split
--  p_id_tipo_cinema        id del tipo cinema del prodotto di vendita
--
-- OUTPUT: p_esito:
--    1 Inserimento eseguito correttamente 
--
-- REALIZZATORE: Simone Bottani , Altran, Maggio 2010
-- MODIFICHE:    Mauro Viel, Altran, Febbraio  aggiunto p_id_spettacolo,p_num_massimo_schermi per segui il film
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_RICH_MULTIPLO (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_perc_sconto           NUMBER,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_id_circuito           CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
    p_id_spettacolo         cd_prodotti_richiesti.id_spettacolo%type,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_esito                    OUT NUMBER) IS
--
v_stato_lavorazione CD_STATO_LAVORAZIONE.STATO_PIANIFICAZIONE%TYPE;
v_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
v_tariffa_ambiente CD_TARIFFA.IMPORTO%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_listino CD_TARIFFA.ID_LISTINO%TYPE;
v_sconto_stagionale CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
v_data_inizio CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE;
v_misura_temp CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE;
v_num_ambienti NUMBER;
v_imp_tariffa CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE;
v_imp_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_imp_maggiorazione CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE := 0;
--v_id_spettacolo cd_prodotti_richiesti.id_spettacolo%type;
BEGIN

    --
    SELECT LAV.STATO_PIANIFICAZIONE
    INTO v_stato_lavorazione
    FROM CD_PIANIFICAZIONE P, CD_STATO_LAVORAZIONE LAV
    WHERE P.ID_PIANO = p_id_piano
    AND P.ID_VER_PIANO = p_id_ver_piano
    AND P.ID_STATO_LAV = LAV.ID_STATO_LAV;
    --
    FOR PERIODO IN (
                    SELECT DATA_INIZ, DATA_FINE
                    FROM
                    (
                        SELECT PER.DATA_INIZ, PER.DATA_FINE
                        FROM PERIODI PER, CD_IMPORTI_RICHIESTI_PIANO IRP
                        WHERE IRP.ID_PIANO = p_id_piano
                        AND IRP.ID_VER_PIANO = p_id_ver_piano
                        AND IRP.ANNO = PER.ANNO
                        AND IRP.CICLO = PER.CICLO
                        AND IRP.PER = PER.PER
                        AND PER.DATA_INIZ >= p_data_inizio
                        AND PER.DATA_FINE <= p_data_fine
                        AND v_stato_lavorazione = 'PIANO'
                        UNION
                        SELECT PER.DATA_INIZ, PER.DATA_FINE
                        FROM PERIODI PER, CD_IMPORTI_RICHIESTA IR
                        WHERE IR.ID_PIANO = p_id_piano
                        AND IR.ID_VER_PIANO = p_id_ver_piano
                        AND IR.ANNO = PER.ANNO
                        AND IR.CICLO = PER.CICLO
                        AND IR.PER = PER.PER
                        AND PER.DATA_INIZ >= p_data_inizio
                        AND PER.DATA_FINE <= p_data_fine
                        AND v_stato_lavorazione = 'RICHIESTA'
                    )
                    ORDER BY DATA_INIZ
            ) LOOP
        v_id_tariffa := null;
        v_data_inizio := PERIODO.DATA_INIZ;
        v_data_fine := PERIODO.DATA_FINE;
        v_num_ambienti := 0;
        BEGIN
        SELECT TARIFFA.ID_TARIFFA, PV.ID_MOD_VENDITA, MIS.ID_MISURA_PRD_VE, L.ID_LISTINO
        INTO v_id_tariffa, v_mod_vendita, v_misura_temp, v_id_listino
        FROM CD_UNITA_MISURA_TEMP U, CD_MISURA_PRD_VENDITA MIS,
        CD_PRODOTTO_VENDITA PV, CD_LISTINO L, CD_TARIFFA TARIFFA
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.DATA_INIZIO <= v_data_inizio
        AND TARIFFA.DATA_FINE >= v_data_fine
        AND TARIFFA.ID_LISTINO = L.ID_LISTINO
        AND L.DATA_INIZIO <= v_data_inizio
        AND L.DATA_FINE >= v_data_fine
        AND TARIFFA.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND MIS.ID_UNITA = U.ID_UNITA
        AND MIS.ID_UNITA = p_unita_temp;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            NULL;
        END;
        --
        IF v_id_tariffa IS NOT NULL THEN
            v_sconto_stagionale := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_SCONTO_STAGIONALE(p_id_prodotto_vendita,v_data_inizio,v_data_fine,p_id_formato,v_misura_temp);
            v_tariffa_ambiente := PA_CD_UTILITY.FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(v_id_tariffa, p_id_formato),v_sconto_stagionale);
            --
            IF v_mod_vendita = 1 THEN
                v_num_ambienti := p_list_id_ambito.COUNT;
            ELSIF v_mod_vendita = 2 THEN
                v_num_ambienti := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_AMBIENTI(p_id_prodotto_vendita, v_data_inizio, v_data_fine);
            ELSIF v_mod_vendita = 3 THEN
                FOR i IN 1..p_list_id_area.COUNT LOOP
                    v_num_ambienti := v_num_ambienti + PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_SCHERMI_NIELSEN(p_list_id_area(i), p_id_prodotto_vendita, p_id_circuito, v_data_inizio, v_data_fine);
                END LOOP;
            END IF;
            --
            v_imp_tariffa := v_tariffa_ambiente * v_num_ambienti;
            IF p_list_maggiorazioni.COUNT > 0 THEN
                FOR MAGG IN (SELECT * FROM CD_MAGGIORAZIONE M
                WHERE M.ID_MAGGIORAZIONE IN (SELECT * FROM TABLE(cast (p_list_maggiorazioni as num_array)))
                ) LOOP
                    v_imp_maggiorazione := v_imp_maggiorazione + ROUND((v_imp_tariffa * MAGG.PERCENTUALE_VARIAZIONE / 100),2);
                END LOOP;
            END IF;            
            v_imp_lordo := v_imp_tariffa + v_imp_maggiorazione;
            v_imp_sconto := PA_PC_IMPORTI.FU_SCONTO_COMM_3(v_imp_lordo, p_perc_sconto);
            --
            IF v_mod_vendita = 1 THEN
                PR_CREA_PROD_RICH_LIBERA (
                p_id_prodotto_vendita,
                p_id_piano,
                p_id_ver_piano,
                p_list_id_ambito,
                p_id_ambito,
                v_data_inizio,
                v_data_fine,
                p_id_formato,
                v_imp_tariffa,
                v_imp_lordo,
                v_imp_sconto,
                v_imp_maggiorazione,
                p_unita_temp,
                v_id_listino,
                p_id_posizione_rigore,
                p_tariffa_variabile,
                p_list_maggiorazioni,
                p_id_tipo_cinema,
                p_esito);
            ELSIF v_mod_vendita = 2 THEN
                PR_CREA_PROD_RICH_MODULO (
                p_id_prodotto_vendita,
                p_id_piano,
                p_id_ver_piano,
                v_data_inizio,
                v_data_fine,
                p_id_formato,
                v_imp_tariffa,
                v_imp_lordo,
                v_imp_sconto,
                v_imp_maggiorazione,
                p_unita_temp,
                v_id_listino,
                p_id_posizione_rigore,
                p_tariffa_variabile,
                p_list_maggiorazioni,
                p_list_id_area,
                p_id_tipo_cinema,
                p_id_spettacolo,
                p_numero_massimo_schermi,
                p_esito);
            ELSIF v_mod_vendita = 3 THEN
                PR_CREA_PROD_RICH_MODULO (
                p_id_prodotto_vendita,
                p_id_piano,
                p_id_ver_piano,
                v_data_inizio,
                v_data_fine,
                p_id_formato,
                v_imp_tariffa,
                v_imp_lordo,
                v_imp_sconto,
                v_imp_maggiorazione,
                p_unita_temp,
                v_id_listino,
                p_id_posizione_rigore,
                p_tariffa_variabile,
                p_list_maggiorazioni,
                p_list_id_area,
                p_id_tipo_cinema,
                p_id_spettacolo,
                p_numero_massimo_schermi,
                p_esito);                
            END IF;
        END IF;
    END LOOP;
END PR_CREA_PROD_RICH_MULTIPLO;        

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ACQUISTA_PROD_RIC
--
-- DESCRIZIONE:  Esegue l'acquisto di un prodotto richiesto
--
-- OPERAZIONI:
--   1) Recupera le informazioni sul prodotto richiesto, ambienti e aree nielsen
--   2) Chiama la procedura per l'acquisto del prodotto, a seconda della 
--     sua modalita di vendita (Libera, Modulo, Geo split)
--
--  INPUT:
--  p_id_prodotto_richiesto Id del prodotto richiesto
--  p_id_prodotto_vendita   Id del prodotto di vendita acquistato
--- p_id_piano              Id del piano
--  p_id_ver_piano          id della versione del piano
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_id_formato            id del formato acquistabile
--  p_tariffa               importo di tariffa
--  p_lordo                 importo lordo
--  p_lordo_comm            importo lordo commerciale
--  p_lordo_dir             importo lordo direzionale
--  p_sconto_comm           importo di sconto commerciale
--  p_sconto_dir            importo di sconto direzionale
--  p_maggiorazione         importo di maggiorazione
--  p_unita_temp            unita temporale del prodotto inserito (Settimana, Mese ecc)
--  p_id_listino            id del listino utilizzato
--  p_num_ambiti            numero di ambienti per cui viene creato il prodotto acquistato
--  p_id_posizione_rigore   id della posizione di rigore, se richiesta
--  p_tariffa_variabile     flag che indica se il prodotto e da creare con tariffa variabile o meno (il flag puo assumere il valore S o N)
--  p_id_tipo_cinema        id del tipo cinema del prodotto di vendita
--  p_list_maggiorazioni    lista di maggiorazioni applicate al prodotto acquistato
--
-- OUTPUT: esito:
--    1 Prodotto acquistato correttamente
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Simone Bottani , Altran, Luglio 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Febbraio 2010
--               aggiunte le modifiche conseguenti al cambio firma di pr_crea_prod_acq_modulo
--             Mauro Viel Altran Italia, Febbraio 2011 
--            inserito il nuovo parametro p_id_spettacolo,p_numero_massimo_schermi per la nuova modalita di vendita segui il film.   
--              
--            Mauro Viel  Altran Italia, Aprile 2011  inserita la gestione dei prodotti 
--                        segui il film venduti a cavallo di listino introdotta la procedura PR_CREA_PROD_ACQ_MODULO_SEGUI_FILM
--            Mauro Viel Altran Italia, Luglio 2011 inserito il numero di ambienti 
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ACQUISTA_PROD_RIC (
    p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_id_spettacolo         CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_esito                 OUT NUMBER)
IS
v_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
v_list_id_area id_list_type;
v_id_ambiente CD_LUOGO_TIPO_PUBB.ID_LUOGO%TYPE;
v_index NUMBER := 1;
v_list_id_ambito id_list_type;
v_id_prodotto_acquistato   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_id_tariffa           cd_tariffa.id_tariffa%type;
v_flg_segui_il_film    cd_prodotto_vendita.flg_segui_il_film%type;
v_numero_ambienti      number;


BEGIN
--
p_esito     := 1;
         SAVEPOINT PR_ACQUISTA_PROD_RIC;
--
        SELECT ID_MOD_VENDITA,flg_segui_il_film
        INTO v_id_mod_vendita,v_flg_segui_il_film
        FROM CD_PRODOTTO_VENDITA
        WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
        
        v_numero_ambienti := fu_get_num_ambienti(p_id_prodotto_richiesto);
        
       
        --
        IF v_id_mod_vendita = 1 THEN
--        
            BEGIN
                SELECT LTP.ID_LUOGO
                INTO v_id_ambiente
                FROM CD_LUOGO_TIPO_PUBB LTP, CD_PRODOTTO_PUBB PUB, CD_PRODOTTO_VENDITA PR_VEN
                WHERE PR_VEN.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND PR_VEN.ID_PRODOTTO_PUBB = PUB.ID_PRODOTTO_PUBB
                AND PUB.COD_TIPO_PUBB IS NOT NULL
                AND PUB.COD_TIPO_PUBB = LTP.COD_TIPO_PUBB;
            END;
            v_list_id_ambito := id_list_type();
            IF v_id_ambiente = 1 THEN
                FOR AMBIENTI IN (SELECT ID_SCHERMO
                            FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                            WHERE ID_PRODOTTI_RICHIESTI = P_ID_PRODOTTO_RICHIESTO) LOOP
                    v_list_id_ambito.EXTEND;
                    v_list_id_ambito(v_index) := AMBIENTI.ID_SCHERMO;
                    v_index := v_index +1;
                END LOOP;
            ELSIF v_id_ambiente = 2 THEN
                FOR AMBIENTI IN (SELECT ID_SALA
                            FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                            WHERE ID_PRODOTTI_RICHIESTI = P_ID_PRODOTTO_RICHIESTO) LOOP
                    v_list_id_ambito.EXTEND;
                    v_list_id_ambito(v_index) := AMBIENTI.ID_SALA;
                    v_index := v_index +1;
                END LOOP;
            ELSIF v_id_ambiente = 3 THEN
                FOR AMBIENTI IN (SELECT ID_ATRIO
                            FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                            WHERE ID_PRODOTTI_RICHIESTI = P_ID_PRODOTTO_RICHIESTO) LOOP
                    v_list_id_ambito.EXTEND;
                    v_list_id_ambito(v_index) := AMBIENTI.ID_ATRIO;
                    v_index := v_index +1;
                END LOOP;
            ELSIF v_id_ambiente = 4 THEN
                FOR AMBIENTI IN (SELECT ID_CINEMA
                            FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                            WHERE ID_PRODOTTI_RICHIESTI = P_ID_PRODOTTO_RICHIESTO) LOOP
                    v_list_id_ambito.EXTEND;
                    v_list_id_ambito(v_index) := AMBIENTI.ID_CINEMA;
                    v_index := v_index +1;
                END LOOP;
            END IF;
--
            PA_CD_PRODOTTO_ACQUISTATO.PR_CREA_PROD_ACQ_LIBERA (
                p_id_prodotto_vendita,
                p_id_piano,
                p_id_ver_piano,
                v_list_id_ambito,
                v_id_ambiente,
                p_data_inizio,
                p_data_fine,
                p_id_formato,
                p_tariffa,
                p_lordo,
                p_lordo_comm,
                p_lordo_dir,
                p_sconto_comm,
                p_sconto_dir,
                p_maggiorazione,
                p_unita_temp,
                p_id_listino,
                v_numero_ambienti,--p_num_ambiti, 
                p_id_posizione_rigore,
                p_tariffa_variabile,
                p_list_maggiorazioni,
                p_id_tipo_cinema,
                null,
                v_id_prodotto_acquistato,
                p_esito);
        ELSIF v_id_mod_vendita = 2 THEN            
            v_list_id_area := ID_LIST_TYPE();
            if v_flg_segui_il_film ='N' then
                PA_CD_PRODOTTO_ACQUISTATO.PR_CREA_PROD_ACQ_MODULO (
                    p_id_prodotto_vendita,
                    p_id_piano,
                    p_id_ver_piano,
                    v_id_ambiente,
                    p_data_inizio,
                    p_data_fine,
                    p_id_formato,
                    p_tariffa,
                    p_lordo,
                    p_lordo_comm,
                    p_lordo_dir,
                    p_sconto_comm,
                    p_sconto_dir,
                    p_maggiorazione,
                    p_unita_temp,
                    p_id_listino,
                    p_num_ambiti,
                    p_id_posizione_rigore,
                    p_tariffa_variabile,
                    p_id_tipo_cinema,
                    p_list_maggiorazioni,
                    v_list_id_area,
                    NULL,
                    p_id_spettacolo,
                    p_numero_massimo_schermi,
                    v_numero_ambienti,
                    v_id_prodotto_acquistato,
                    p_esito);
            else
                 ---Determino la tariffa corretta
            
                    select min(id_tariffa) as id_tariffa
                    into v_id_tariffa
                    from
                    cd_unita_misura_temp, cd_misura_prd_vendita,
                    cd_prodotto_vendita pv, cd_tariffa tariffa
                    where pv.id_prodotto_vendita = p_id_prodotto_vendita
                    and tariffa.id_prodotto_vendita = pv.id_prodotto_vendita
                    and  ((p_data_inizio between tariffa.data_inizio  and tariffa.data_fine ) or (p_data_fine between tariffa.data_inizio  and tariffa.data_fine))
                    and tariffa.id_misura_prd_ve = cd_misura_prd_vendita.id_misura_prd_ve
                    and (tariffa.id_tipo_tariffa = 1 or p_id_formato is null or tariffa.id_formato = p_id_formato)
                    and cd_misura_prd_vendita.id_unita = cd_unita_misura_temp.id_unita
                    and cd_unita_misura_temp.id_unita = p_unita_temp
                    and    pa_cd_tariffa.fu_get_giorni_trascorsi(p_data_inizio,cd_unita_misura_temp.id_unita) = p_data_fine - p_data_inizio +1;

            
            
                 ---Acquisto il prodotto
                       
                  PA_CD_PRODOTTO_ACQUISTATO.PR_CREA_PROD_MODULO_SEGUI_FILM(
                    p_id_prodotto_vendita,
                    p_id_piano,
                    p_id_ver_piano,
                    v_id_ambiente,
                    p_data_inizio,
                    p_data_fine,
                    p_id_formato,
                    p_tariffa,
                    p_lordo,
                    p_lordo_comm,
                    p_lordo_dir,
                    p_sconto_comm,
                    p_sconto_dir,
                    p_maggiorazione,
                    p_unita_temp,
                    p_id_listino,
                    p_num_ambiti,
                    p_id_posizione_rigore,
                    p_tariffa_variabile,
                    p_id_tipo_cinema,
                    p_list_maggiorazioni,
                    v_list_id_area,
                    NULL,
                    p_id_spettacolo,
                    p_numero_massimo_schermi,
                    v_numero_ambienti,
                    v_id_tariffa,
                    v_id_prodotto_acquistato,
                    p_esito);
             end if;                       
        ELSIF v_id_mod_vendita = 3 THEN
               v_list_id_area := ID_LIST_TYPE();
               FOR AREE IN (SELECT ID_AREA_NIELSEN
                            FROM CD_AREE_PRODOTTI_RICHIESTI
                            WHERE ID_PRODOTTI_RICHIESTI = P_ID_PRODOTTO_RICHIESTO) LOOP
                    v_list_id_area.EXTEND;
                    v_list_id_area(v_index) := AREE.ID_AREA_NIELSEN;
                    v_index := v_index +1;
               END LOOP;
--
               PA_CD_PRODOTTO_ACQUISTATO.PR_CREA_PROD_ACQ_MODULO (
                p_id_prodotto_vendita,
                p_id_piano,
                p_id_ver_piano,
                v_id_ambiente,
                p_data_inizio,
                p_data_fine,
                p_id_formato,
                p_tariffa,
                p_lordo,
                p_lordo_comm,
                p_lordo_dir,
                p_sconto_comm,
                p_sconto_dir,
                p_maggiorazione,
                p_unita_temp,
                p_id_listino,
                p_num_ambiti,
                p_id_posizione_rigore,
                p_tariffa_variabile,
                p_id_tipo_cinema,
                p_list_maggiorazioni,
                v_list_id_area,
                NULL,
                p_id_spettacolo,
                p_numero_massimo_schermi,
                v_numero_ambienti,
                v_id_prodotto_acquistato,
                p_esito);
        END IF;
        UPDATE CD_PRODOTTI_RICHIESTI
        SET FLG_ACQUISTATO = 'S'
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
        
        --dbms_output.PUT_LINE('v_id_prodotto_acquistato:'||v_id_prodotto_acquistato);
        PA_CD_UTILITY.PR_CORREGGI_TARIFFE_PROD_ACQ(v_id_prodotto_acquistato);
     /* EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
      WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_ACQUISTA_PROD_RIC: INSERT NON ESEGUITA, ERRORE: '||SQLERRM);
        ROLLBACK TO PR_ACQUISTA_PROD_RIC;*/
     END PR_ACQUISTA_PROD_RIC;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_APPLICA_MAGGIORAZIONE
--
-- DESCRIZIONE:  Associa una maggiorazione ad un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_id_maggiorazione            Id della maggiorazione
--
--  OUTPUT:
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------

PROCEDURE PR_SALVA_MAGGIORAZIONE(
                                p_id_prodotto_richiesto  CD_MAGG_PRODOTTO.ID_PRODOTTI_RICHIESTI%TYPE,
                                p_id_maggiorazione       CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE%TYPE) IS
--
v_num NUMBER;
v_num_pos_fissa NUMBER;
BEGIN
/*    SELECT COUNT(1)
    INTO v_num
    FROM CD_MAGG_PRODOTTO
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND ID_MAGGIORAZIONE = p_id_maggiorazione;

    SELECT COUNT(1)
    INTO v_num_pos_fissa
    FROM  CD_MAGGIORAZIONE M, CD_MAGG_PRODOTTO MP
    WHERE MP.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE
    AND M.ID_TIPO_MAGG = 1;

    IF v_num_pos_fissa = 1 THEN
        DELETE FROM CD_MAGG_PRODOTTO WHERE
        ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND ID_MAGGIORAZIONE IN
        (SELECT M.ID_MAGGIORAZIONE FROM  CD_MAGGIORAZIONE M, CD_MAGG_PRODOTTO MP
        WHERE MP.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE
        AND M.ID_TIPO_MAGG = 1 );
    END IF;
*/
--    IF v_num = 0 THEN
        INSERT INTO CD_MAGG_PRODOTTO(ID_PRODOTTI_RICHIESTI, ID_MAGGIORAZIONE)
        VALUES(p_id_prodotto_richiesto,p_id_maggiorazione);
--    END IF;
EXCEPTION
  WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_APPLICA_MAGGIORAZIONE: Errore');
END PR_SALVA_MAGGIORAZIONE;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_PROD_ACQUISTATI_PIANO
--
-- DESCRIZIONE:  Restituisce tutti i prodotti acquistati di un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--
--  OUTPUT: lista di prodotti acquistati appartenenti al piano
--
-- REALIZZATORE: Simone Bottani , Altran, Novembre 2009
--
--  MODIFICHE:
--            Mauro Viel Altran, Aprile 2011 rimpiazzata  la clausole: 
--           and PR_RIC.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
--           con AND  ((PR_RIC.DATA_INIZIO between TAR.DATA_INIZIO  and TAR.DATA_FINE ) or (PR_RIC.DATA_FINE between TAR.DATA_INIZIO  and TAR.DATA_FINE))
--           e la min(TAR.ID_LISTINO) over (partition by cir.id_circuito) as id_listino 
--           in modo da poter visualizzare i prodotti a cavallo di listino.
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_PROD_RICHIESTI_PIANO(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_tipo_disp VARCHAR2,
                                      p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_PROD_RIC_PIANO IS
--
v_prodotti C_PROD_RIC_PIANO;
v_descr_stato_vendita CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
BEGIN
--
   IF p_stato_vendita IS NOT NULL AND p_stato_vendita <> -1 THEN
    SELECT DESCR_BREVE
    INTO v_descr_stato_vendita
    FROM CD_STATO_DI_VENDITA
    WHERE ID_STATO_VENDITA = p_stato_vendita;
   END IF;
OPEN v_prodotti FOR
    SELECT 
           distinct
           ID_PRODOTTI_RICHIESTI,
           ID_PIANO,
           ID_VER_PIANO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           ID_LISTINO,
           DATA_INIZIO,
           DATA_FINE,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA, IMP_LORDO, IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS IMP_LORDO_COMM,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS IMP_LORDO_DIR,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS PERC_SCONTO_COMM,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS PERC_SCONTO_DIR,
           ID_FORMATO, DESCRIZIONE AS DESC_FORMATO,
           DURATA,
           ID_TIPO_TARIFFA,
           ID_UNITA,
           FLG_TARIFFA_VARIABILE,
           COD_POS_FISSA, DESC_POS_FISSA,
           SUBSTR(disp,1,INSTR(disp,'|',1,1) -1) as disponibilita_minima,
           SUBSTR(disp,INSTR(disp,'|',1,1) +1,length(disp)) as disponibilita_massima,
           FLG_ACQUISTATO,
           SETTIMANA_SIPRA,
           0 as num_ambienti,--FU_GET_NUM_AMBIENTI(ID_PRODOTTI_RICHIESTI) AS NUM_AMBIENTI,
           ID_TIPO_CINEMA,
           id_spettacolo,
           numero_massimo_schermi
        FROM
        (SELECT
           PR_RIC.ID_PRODOTTI_RICHIESTI,
           PR_RIC.ID_PIANO,
           PR_RIC.ID_VER_PIANO,
           PR_VEN.ID_PRODOTTO_VENDITA,
           PR_PUB.DESC_PRODOTTO,
           CIR.ID_CIRCUITO,
           CIR.NOME_CIRCUITO,
           MOD_VEN.ID_MOD_VENDITA,
           MOD_VEN.DESC_MOD_VENDITA,
           TI_BR.DESC_TIPO_BREAK,
           MAN.DES_MAN,
           PR_RIC.IMP_TARIFFA, PR_RIC.IMP_LORDO, PR_RIC.IMP_NETTO,
           IMP_PRD_D.IMP_NETTO as IMP_NETTO_DIR,
           IMP_PRD_D.IMP_SC_COMM as IMP_SC_DIR,
           IMP_PRD_C.IMP_NETTO as IMP_NETTO_COMM,
           IMP_PRD_C.IMP_SC_COMM as IMP_SC_COMM,
           PR_RIC.IMP_MAGGIORAZIONE,
           MIS.ID_UNITA,
           PR_RIC.DATA_INIZIO,
           PR_RIC.DATA_FINE,
           PR_RIC.FLG_TARIFFA_VARIABILE,
           F_ACQ.ID_FORMATO, F_ACQ.DESCRIZIONE,
           COEF.DURATA,
           TAR.ID_TIPO_TARIFFA,
           --TAR.ID_LISTINO,
           min(TAR.ID_LISTINO) over (partition by cir.id_circuito) as id_listino,
           POS.COD_POSIZIONE AS COD_POS_FISSA, POS.DESCRIZIONE AS DESC_POS_FISSA,
           PR_RIC.FLG_ACQUISTATO,
           PERIODO.ANNO ||'-'||PERIODO.CICLO||'-'||PERIODO.PER AS SETTIMANA_SIPRA,
           PR_RIC.ID_TIPO_CINEMA,
           PR_RIC.ID_SPETTACOLO,
           PR_RIC.NUMERO_MASSIMO_SCHERMI,
           '0|0' as disp--(SELECT pa_cd_estrazione_prod_vendita.fu_affollamento(p_tipo_disp,PR_VEN.ID_PRODOTTO_VENDITA, v_descr_stato_vendita,PR_RIC.DATA_INIZIO, PR_RIC.DATA_FINE) FROM DUAL) disp
        FROM
           PERIODI PERIODO,
           PC_MANIF MAN,
           CD_TIPO_BREAK TI_BR,
           CD_MODALITA_VENDITA MOD_VEN,
           CD_CIRCUITO CIR,
           CD_PRODOTTO_PUBB PR_PUB,
           CD_TARIFFA TAR,
           CD_PRODOTTO_VENDITA PR_VEN,
           CD_COEFF_CINEMA COEF,
           CD_FORMATO_ACQUISTABILE F_ACQ,
           CD_MISURA_PRD_VENDITA MIS,
           CD_IMPORTI_PRODOTTO IMP_PRD_D,
           CD_IMPORTI_PRODOTTO IMP_PRD_C,
           CD_PRODOTTI_RICHIESTI PR_RIC,
           CD_POSIZIONE_RIGORE POS
        WHERE PR_RIC.ID_PIANO = p_id_piano
        and PR_RIC.ID_VER_PIANO = p_id_ver_piano
        and PR_RIC.FLG_ANNULLATO = 'N'
        and PR_RIC.FLG_SOSPESO = 'N'
        and IMP_PRD_C.ID_PRODOTTI_RICHIESTI = PR_RIC.ID_PRODOTTI_RICHIESTI
        and IMP_PRD_C.TIPO_CONTRATTO = 'C'
        and IMP_PRD_D.ID_PRODOTTI_RICHIESTI = PR_RIC.ID_PRODOTTI_RICHIESTI
        and IMP_PRD_D.TIPO_CONTRATTO = 'D'
        and F_ACQ.ID_FORMATO = PR_RIC.ID_FORMATO
        AND COEF.ID_COEFF(+) = F_ACQ.ID_COEFF
        and MIS.ID_MISURA_PRD_VE = PR_RIC.ID_MISURA_PRD_VE
        and PR_VEN.ID_PRODOTTO_VENDITA = PR_RIC.ID_PRODOTTO_VENDITA
        and TAR.ID_PRODOTTO_VENDITA = PR_VEN.ID_PRODOTTO_VENDITA
        and (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PR_RIC.ID_FORMATO)
        and TAR.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE
        --and PR_RIC.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
        --and PR_RIC.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
        AND  ((PR_RIC.DATA_INIZIO between TAR.DATA_INIZIO  and TAR.DATA_FINE ) or (PR_RIC.DATA_FINE between TAR.DATA_INIZIO  and TAR.DATA_FINE))
        and PR_PUB.ID_PRODOTTO_PUBB = PR_VEN.ID_PRODOTTO_PUBB
        and CIR.ID_CIRCUITO = PR_VEN.ID_CIRCUITO
        and MOD_VEN.ID_MOD_VENDITA = PR_VEN.ID_MOD_VENDITA
        and TI_BR.ID_TIPO_BREAK (+) = PR_VEN.ID_TIPO_BREAK
        and MAN.COD_MAN(+) = PR_VEN.COD_MAN
        and POS.COD_POSIZIONE (+) = PR_RIC.COD_POSIZIONE
        and PR_RIC.DATA_INIZIO = PERIODO.DATA_INIZ (+)
        and PR_RIC.DATA_FINE = PERIODO.DATA_FINE (+)
        and (pr_ric.ID_TIPO_CINEMA is null or  pr_ric.ID_TIPO_CINEMA  = tar.ID_TIPO_CINEMA)
        )
        ORDER BY DATA_INIZIO,DATA_FINE,ID_CIRCUITO;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_PROD_RICHIESTI_PIANO;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_NUM_PROD_RICH
--
-- DESCRIZIONE:  Restituisce il numero di prodotti richiesti per un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--
--  OUTPUT: numero di prodotti
--
-- REALIZZATORE: Simone Bottani , Altran, Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_PROD_RICH(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                              p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER IS
v_num_prodotti NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_num_prodotti
    FROM CD_PRODOTTI_RICHIESTI
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano
    AND FLG_ANNULLATO = 'N'
    AND FLG_SOSPESO = 'N';
    RETURN v_num_prodotti;
EXCEPTION
   WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_NUM_PROD_RICH: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
END FU_GET_NUM_PROD_RICH;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_NUM_PROD_RICH
--
-- DESCRIZIONE:  Restituisce il numero di prodotti richiesti acquistati per un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--
--  OUTPUT: numero di prodotti richiesti acquistati
--
-- REALIZZATORE: Michele Borgogno , Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_PROD_RICH_ACQ(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                              p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER IS
v_num_prodotti NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_num_prodotti
    FROM CD_PRODOTTI_RICHIESTI
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano
    AND FLG_ACQUISTATO = 'S'
    AND FLG_ANNULLATO = 'N'
    AND FLG_SOSPESO = 'N';
    RETURN v_num_prodotti;
EXCEPTION
   WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_NUM_PROD_RICH_ACQ: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
END FU_GET_NUM_PROD_RICH_ACQ;

FUNCTION FU_GET_MAGGIORAZIONI_PRODOTTO(
          p_id_prodotto_richiesto CD_MAGG_PRODOTTO.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_MAGGIORAZIONE IS
v_magg_return C_MAGGIORAZIONE;
BEGIN
--
    OPEN v_magg_return
    FOR
        SELECT  CD_MAGGIORAZIONE.ID_MAGGIORAZIONE,
                CD_MAGGIORAZIONE.DESCRIZIONE,
                CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE,
                PA_CD_TARIFFA.FU_CALCOLA_MAGGIORAZIONE(CD_PRODOTTI_RICHIESTI.IMP_TARIFFA,
                CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE) AS IMPORTO,
                CD_MAGGIORAZIONE.ID_TIPO_MAGG,
                CD_TIPO_MAGG.TIPO_MAGG_DESC
        FROM   CD_TIPO_MAGG, CD_MAGGIORAZIONE, CD_MAGG_PRODOTTO, CD_PRODOTTI_RICHIESTI
        WHERE CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND CD_MAGG_PRODOTTO.ID_PRODOTTI_RICHIESTI = CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI
        AND CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE = CD_MAGGIORAZIONE.ID_MAGGIORAZIONE
        AND CD_TIPO_MAGG.ID_TIPO_MAGG = CD_MAGGIORAZIONE.ID_TIPO_MAGG;
    RETURN v_magg_return;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'FUNZIONE FU_GET_MAGGIORAZIONI_PRODOTTO: SI E'' VERIFICATO UN ERRORE');
END FU_GET_MAGGIORAZIONI_PRODOTTO;

PROCEDURE PR_MODIFICA_PRODOTTO_RICHIESTO(
                    p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                    p_imp_tariffa CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
                    p_imp_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
                    p_imp_maggiorazione CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
                    p_netto_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_netto_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_posizione_rigore CD_PRODOTTI_RICHIESTI.COD_POSIZIONE%TYPE,
                    p_id_formato CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
                    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
                    p_list_maggiorazioni    id_list_type) IS
--
BEGIN
    UPDATE CD_PRODOTTI_RICHIESTI SET
                         IMP_TARIFFA = p_imp_tariffa,
                         IMP_LORDO = p_imp_lordo,
                         IMP_NETTO = p_netto_comm + p_netto_dir,
                         IMP_MAGGIORAZIONE = p_imp_maggiorazione,
                         ID_FORMATO = p_id_formato,
                         COD_POSIZIONE = p_posizione_rigore,
                         FLG_TARIFFA_VARIABILE = p_tariffa_variabile
    WHERE CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
--
    UPDATE CD_IMPORTI_PRODOTTO
    SET IMP_NETTO = p_netto_comm,
    IMP_SC_COMM = p_sconto_comm
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND TIPO_CONTRATTO = 'C';
--
    UPDATE CD_IMPORTI_PRODOTTO
    SET IMP_NETTO = p_netto_dir,
    IMP_SC_COMM = p_sconto_dir
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND TIPO_CONTRATTO = 'D';
--
  DELETE FROM CD_MAGG_PRODOTTO
  WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
  IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
  --     IF p_list_maggiorazioni.COUNT = 0 THEN
  --         DELETE FROM CD_MAGG_PRODOTTO
  --         WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
  --     ELSE
           FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
             PR_SALVA_MAGGIORAZIONE(p_id_prodotto_richiesto, p_list_maggiorazioni(i));
           END LOOP;
   --  END IF;
   END IF;
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
END PR_MODIFICA_PRODOTTO_RICHIESTO;
--
PROCEDURE PR_ANNULLA_PRODOTTO_RICHIESTO(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) IS
BEGIN
    UPDATE CD_PRODOTTI_RICHIESTI
    SET FLG_ANNULLATO = 'S'
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
END PR_ANNULLA_PRODOTTO_RICHIESTO;

PROCEDURE PR_RIPRISTINA_PRODOTTO_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) IS
BEGIN
    UPDATE CD_PRODOTTI_RICHIESTI
    SET FLG_ANNULLATO = 'N'
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
END PR_RIPRISTINA_PRODOTTO_RIC;

FUNCTION FU_GET_RIPARAMETRA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE, p_id_formato CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE) RETURN NUMBER IS
--v_aliquota_vecchia CD_COEFF_CINEMA.ID_COEFF%TYPE;
--v_aliquota_nuova CD_COEFF_CINEMA.ID_COEFF%TYPE;
--v_vecchia_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE := 0;
   BEGIN
--
    SELECT IMP_TARIFFA / ALIQUOTA *
    (SELECT ALIQUOTA
    --INTO v_aliquota_nuova
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE
    WHERE CD_FORMATO_ACQUISTABILE.ID_FORMATO = p_id_formato
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF)
    --INTO v_aliquota_vecchia, v_vecchia_tariffa
    INTO v_nuova_tariffa
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE, CD_PRODOTTI_RICHIESTI
    WHERE CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTI_RICHIESTI.ID_FORMATO
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF;
--
 /*   SELECT ALIQUOTA
    INTO v_aliquota_nuova
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE
    WHERE CD_FORMATO_ACQUISTABILE.ID_FORMATO = p_id_formato
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF;
    */
--
    --v_nuova_tariffa := (v_vecchia_tariffa / v_aliquota_vecchia) * v_aliquota_nuova;
 --   SELECT v_vecchia_tariffa / v_aliquota_vecchia * v_aliquota_nuova
  --  INTO v_nuova_tariffa
  --  FROM DUAL;
    RETURN v_nuova_tariffa;
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
END FU_GET_RIPARAMETRA_PROD_RIC;

FUNCTION FU_GET_SCHERMI_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_SCHERMI_PA IS
v_sale_return C_SCHERMI_PA;
BEGIN
OPEN v_sale_return FOR
     SELECT SC.ID_SCHERMO, TC.DESC_TIPO_CINEMA, CI.NOME_CINEMA, COM.COMUNE, PROV.ABBR AS PROVINCIA, REG.NOME_REGIONE, SA.NOME_SALA AS DESC_SCHERMO, 0 AS PASSAGGI--, COUNT(ID_BREAK) AS PASSAGGI
     FROM
      CD_COMUNE COM, CD_TIPO_CINEMA TC, CD_CINEMA CI, CD_SALA SA, CD_SCHERMO SC, CD_PROVINCIA PROV, CD_REGIONE REG
    WHERE SC.ID_SCHERMO IN
    (SELECT ID_SCHERMO FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)
    AND SC.FLG_ANNULLATO = 'N'
    AND SA.ID_SALA = SC.ID_SALA
    AND SA.FLG_ANNULLATO = 'N'
    AND CI.ID_CINEMA = SA.ID_CINEMA
    AND CI.FLG_ANNULLATO = 'N'
    AND CI.ID_TIPO_CINEMA = TC.ID_TIPO_CINEMA
    AND COM.ID_COMUNE = CI.ID_COMUNE
    AND PROV.ID_PROVINCIA = COM.ID_PROVINCIA
    AND REG.ID_REGIONE = PROV.ID_REGIONE
    ORDER BY NOME_CINEMA;
    RETURN v_sale_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_SCHERMI_PROD_RIC;

FUNCTION FU_GET_ATRII_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_AMBIENTI_PA IS
v_atrii_return C_AMBIENTI_PA;
BEGIN
OPEN v_atrii_return FOR
  SELECT DISTINCT(A.ID_ATRIO), A.DESC_ATRIO, CIN.NOME_CINEMA || ' - ' || COM.COMUNE AS NOME_CINEMA
    FROM
    CD_COMUNE COM, CD_TIPO_CINEMA TC, CD_CINEMA CIN, CD_ATRIO A, CD_PROVINCIA PROV, CD_REGIONE REG
    WHERE A.ID_ATRIO IN
    (SELECT ID_ATRIO FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)
    AND CIN.ID_CINEMA = A.ID_CINEMA
    AND CIN.FLG_ANNULLATO = 'N'
    AND CIN.ID_TIPO_CINEMA = TC.ID_TIPO_CINEMA
    AND COM.ID_COMUNE = CIN.ID_COMUNE
    AND PROV.ID_PROVINCIA = COM.ID_PROVINCIA
    AND REG.ID_REGIONE = PROV.ID_REGIONE
    ORDER BY NOME_CINEMA;
    RETURN v_atrii_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_ATRII_PROD_RIC;

FUNCTION FU_GET_AREE_NIELSEN_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_AREA_NIELSEN IS
v_aree_nielsen C_AREA_NIELSEN;
v_id_prodotto_vendita CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE;
v_data_inizio CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE;
v_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE;
BEGIN
   SELECT PR.ID_PRODOTTO_VENDITA, PR.DATA_INIZIO, PR.DATA_FINE, PV.ID_CIRCUITO
   INTO v_id_prodotto_vendita, v_data_inizio, v_data_fine, v_id_circuito
   FROM CD_PRODOTTI_RICHIESTI PR, CD_PRODOTTO_VENDITA PV
   WHERE PR.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
   AND PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA;
   OPEN v_aree_nielsen FOR
      SELECT ID_AREA_NIELSEN, DESC_AREA,
      PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_SCHERMI_NIELSEN(ID_AREA_NIELSEN, v_id_prodotto_vendita, v_id_circuito, v_data_inizio, v_data_fine) AS NUM_SCHERMI,
      PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_REGIONI_NIELSEN(ID_AREA_NIELSEN) AS REGIONI
      FROM CD_AREA_NIELSEN
      WHERE ID_AREA_NIELSEN IN
      (SELECT ID_AREA_NIELSEN FROM CD_AREE_PRODOTTI_RICHIESTI
      WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto);
   RETURN  v_aree_nielsen;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_AREA_NIELSEN: ERRORE '||SQLERRM);

END FU_GET_AREE_NIELSEN_PROD_RIC;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_COUNT_PROD_RIC_PERIODO
--
-- DESCRIZIONE:  Restituisce il numero di prodotti richiesti di un determinato periodo di un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_data_inizio           data inizio del periodo
--  p_data_fine             data fine del periodo
--
--  OUTPUT: numero di prodotti richiesti
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------

FUNCTION FU_COUNT_PROD_RIC_PERIODO(p_id_piano CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
                                   p_id_ver_piano CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
                                   p_data_inizio CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
                                   p_data_fine CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE) RETURN NUMBER IS
 --                                p_tipo_periodo VARCHAR2) RETURN NUMBER IS

v_count NUMBER;

BEGIN
--       IF p_tipo_periodo = 'SPE' THEN
            SELECT COUNT(ID_PRODOTTI_RICHIESTI) INTO v_count FROM CD_PRODOTTI_RICHIESTI PR
                WHERE PR.ID_PIANO = p_id_piano
                AND PR.ID_VER_PIANO = p_id_ver_piano
                AND PR.DATA_INIZIO = p_data_inizio
                AND PR.DATA_FINE = p_data_fine
                AND PR.FLG_ANNULLATO = 'N'
                AND PR.FLG_SOSPESO = 'N';

   RETURN  v_count;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FU_COUNT_PROD_RIC_PERIODO: ERRORE '||SQLERRM);

END FU_COUNT_PROD_RIC_PERIODO;

FUNCTION FU_GET_NUM_AMBIENTI(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN NUMBER IS
v_num_ambienti number := 0;
v_num_ambienti_temp number := 0;
v_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE;
v_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
v_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE;
v_data_inizio CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE;
v_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type;

BEGIN
    SELECT PV.ID_PRODOTTO_VENDITA, PV.ID_MOD_VENDITA, PV.ID_CIRCUITO, PR.DATA_INIZIO, PR.DATA_FINE
    INTO v_id_prodotto_vendita, v_mod_vendita, v_circuito, v_data_inizio, v_data_fine
    FROM CD_PRODOTTI_RICHIESTI PR, CD_PRODOTTO_VENDITA PV
    WHERE PR.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA;
    
    IF v_mod_vendita = 1 THEN
        SELECT COUNT(1) 
        INTO v_num_ambienti
        FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
    ELSIF v_mod_vendita = 2 THEN
        select numero_massimo_schermi
        into   v_numero_massimo_schermi
        from   cd_prodotti_richiesti
        where  ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
        if nvl(v_numero_massimo_schermi,0) = 0 then 
            v_num_ambienti := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_AMBIENTI(v_id_prodotto_vendita, v_data_inizio, v_data_fine);
        else
            v_num_ambienti := v_numero_massimo_schermi;
        end if;
    ELSIF v_mod_vendita = 3 THEN
        FOR AREE IN(SELECT * FROM CD_AREE_PRODOTTI_RICHIESTI
             WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)LOOP
            v_num_ambienti_temp := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_SCHERMI_NIELSEN(AREE.ID_AREA_NIELSEN, v_id_prodotto_vendita, v_circuito,v_data_inizio, v_data_fine);
            v_num_ambienti := v_num_ambienti + v_num_ambienti_temp;
        END LOOP;     
    END IF;
    RETURN v_num_ambienti;
END FU_GET_NUM_AMBIENTI;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_AMBIENTI_PROD_RIC
--
-- DESCRIZIONE:  Modifica gli ambienti di un prodotto richiesto
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      id dell'importo prodotto
--  p_list_id_ambito              lista di ambienti da associare al prodotto
--
--  OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Marzo 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_AMBIENTI_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                        p_list_id_ambito        id_list_type) IS
--
v_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE;
--v_id_tariffa CD_PRODOTTO_VENDITA.ID_TARIFFA%TYPE;
v_luoghi PA_CD_ESTRAZIONE_PROD_VENDITA.C_LUOGO;
v_ambiente PA_CD_ESTRAZIONE_PROD_VENDITA.R_LUOGO;
v_schermi C_SCHERMI_PA;
v_schermo_rec R_SCHERMI_PA;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_unita_temp CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;
v_trovato BOOLEAN;
v_imp_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_piani_errati VARCHAR2(20000);
v_num_ambienti NUMBER;
v_schermo_presente NUMBER;
v_string_id_ambito   varchar(32000);
v_string_ambiti_prodotto   varchar(32000);
v_id_luogo CD_LUOGO.ID_LUOGO%TYPE;
BEGIN
    
    SELECT PR.ID_PIANO, PR.ID_VER_PIANO, PR.ID_PRODOTTO_VENDITA, PV.ID_CIRCUITO, PR.DATA_INIZIO, PR.DATA_FINE, PR.ID_FORMATO,  PR.IMP_TARIFFA, MIS.ID_UNITA, TAR.ID_TARIFFA
    INTO v_id_piano, v_id_ver_piano, v_id_prodotto_vendita, v_id_circuito, v_data_inizio, v_data_fine,  v_id_formato, v_imp_tariffa, v_unita_temp, v_id_tariffa
    FROM CD_MISURA_PRD_VENDITA MIS, CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTI_RICHIESTI PR
    WHERE PR.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND   PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA
    AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
    AND TAR.DATA_INIZIO <= PR.DATA_INIZIO
    AND TAR.DATA_FINE >= PR.DATA_FINE
    AND (PR.ID_TIPO_CINEMA IS NULL OR PR.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
    AND (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PR.ID_FORMATO)
    AND PR.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE
    AND TAR.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE;
    --
    v_id_luogo := FU_GET_LUOGO_PROD_RIC(p_id_prodotto_richiesto);
    --
    v_num_ambienti := FU_GET_NUM_AMBIENTI(p_id_prodotto_richiesto);
    --
    v_nuova_tariffa := ROUND(v_imp_tariffa / v_num_ambienti,2);
    --
    FOR i IN p_list_id_ambito.FIRST..p_list_id_ambito.LAST LOOP
          v_string_id_ambito := v_string_id_ambito||LPAD(p_list_id_ambito(i),5,'0')||'|';
    END LOOP;
    --
    IF v_id_luogo = 1 THEN
        PR_MODIFICA_SCHERMI_PROD_RIC(p_id_prodotto_richiesto, v_string_id_ambito);
    ELSIF v_id_luogo = 2 THEN
        PR_MODIFICA_SALE_PROD_RIC(p_id_prodotto_richiesto, v_string_id_ambito);
    ELSIF v_id_luogo = 3 THEN
        PR_MODIFICA_ATRII_PROD_RIC(p_id_prodotto_richiesto, v_string_id_ambito);
    ELSIF v_id_luogo = 4 THEN
        PR_MODIFICA_CINEMA_PROD_RIC(p_id_prodotto_richiesto, v_string_id_ambito);
    END IF;
    --
    PR_RICALCOLA_TARIFFA_PROD_RIC(p_id_prodotto_richiesto,
                                  v_imp_tariffa,
                                  v_nuova_tariffa,
                                  'S',
                                  v_piani_errati);
                                  
END PR_MODIFICA_AMBIENTI_PROD_RIC;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_AMBIENTI_PROD_RIC
--
-- DESCRIZIONE:  Modifica le aree nielsen di un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      id dell'importo prodotto
--  p_list_id_area               lista di aree da associare al prodotto
--
--  OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Febbraio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_AREE_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                    p_list_id_area        id_list_type) IS

v_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;
v_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_unita_temp CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_imp_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_id_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_aree C_AREA_NIELSEN;
v_area_rec R_AREA_NIELSEN;
v_aree_prodotto C_AREA_NIELSEN;
v_trovato BOOLEAN;
v_vecchia_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_piani_errati VARCHAR2(20000);
v_num_schermi NUMBER;
v_list_id_aree_prodotto id_list_type := id_list_type();
v_num_aree_vecchio NUMBER;
v_id_maggiorazione CD_MAGGIORAZIONE.ID_MAGGIORAZIONE%TYPE;
v_nuovo_importo_magg CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_prodotto_richiesto_cur C_PROD_RIC_PIANO;
v_prodotto_richiesto_rec R_PROD_RIC_PIANO;
v_esito NUMBER;
v_sanatoria number := 0;
v_recupero number := 0;
BEGIN
    
    SELECT PR.ID_PIANO, PR.ID_VER_PIANO, PR.ID_PRODOTTO_VENDITA, PV.ID_CIRCUITO, PR.DATA_INIZIO, PR.DATA_FINE, PR.ID_FORMATO,  PR.IMP_TARIFFA, MIS.ID_UNITA, TAR.ID_TARIFFA
        INTO v_id_piano, v_id_ver_piano, v_id_prodotto_vendita, v_id_circuito, v_data_inizio, v_data_fine,  v_id_formato, v_imp_tariffa, v_unita_temp, v_id_tariffa
        FROM CD_MISURA_PRD_VENDITA MIS, CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTI_RICHIESTI PR
        WHERE PR.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND   PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA
        AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TAR.DATA_INIZIO <= PR.DATA_INIZIO
        AND TAR.DATA_FINE >= PR.DATA_FINE
        AND (PR.ID_TIPO_CINEMA IS NULL OR PR.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
        AND (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PR.ID_FORMATO)
        AND TAR.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE;
    --
    v_aree := FU_GET_AREE_NIELSEN_PROD_RIC(p_id_prodotto_richiesto);
    SELECT COUNT(1)
    INTO v_num_aree_vecchio
    FROM CD_AREE_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
     v_num_schermi := 0;
    LOOP
      FETCH v_aree INTO v_area_rec;
      EXIT WHEN v_aree%NOTFOUND;
           --dbms_output.put_line('area'||v_area_rec.a_id_area_nielsen);
           v_num_schermi := v_num_schermi + v_area_rec.a_num_schermi;
           v_trovato := FALSE;
           v_list_id_aree_prodotto.EXTEND;
           v_list_id_aree_prodotto(v_aree%ROWCOUNT) := v_area_rec.a_id_area_nielsen;
           FOR i IN 1..p_list_id_area.COUNT LOOP
                --dbms_output.put_line('area input '||p_list_id_area(i));
                IF p_list_id_area(i) = v_area_rec.a_id_area_nielsen THEN
                    --dbms_output.put_line('area trovata '||v_area_rec.a_id_area_nielsen);
                    v_trovato := TRUE;
                    
                    EXIT;
                END IF;
            END LOOP;
            IF v_trovato = FALSE THEN
            --dbms_output.put_line('elimino area '||v_area_rec.a_id_area_nielsen);
            --
            DELETE FROM CD_AREE_PRODOTTI_RICHIESTI
            WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
            AND ID_AREA_NIELSEN = v_area_rec.a_id_area_nielsen;
            --
            END IF;            
    END LOOP;
    CLOSE v_aree;
    --dbms_output.PUT_LINE('Schermi vecchi: '||v_num_schermi);
    v_vecchia_tariffa := ROUND(v_imp_tariffa / v_num_schermi,2);
    FOR i IN 1..p_list_id_area.COUNT LOOP
            v_trovato := FALSE;
            FOR j IN 1..v_list_id_aree_prodotto.COUNT LOOP
                IF p_list_id_area(i) = v_list_id_aree_prodotto(j) THEN
                    v_trovato := TRUE;
                    EXIT;
                END IF;    
            END LOOP;
            IF v_trovato = FALSE THEN
            --dbms_output.put_line('aggiungo area '||p_list_id_area(i));
        INSERT INTO CD_AREE_PRODOTTI_RICHIESTI
        (ID_PRODOTTI_RICHIESTI,ID_AREA_NIELSEN)
        VALUES
        (p_id_prodotto_richiesto,p_list_id_area(i));
        --
        END IF;
    END LOOP;
   -- 
    IF v_num_aree_vecchio != p_list_id_area.COUNT THEN
        DELETE FROM CD_MAGG_PRODOTTO
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND ID_MAGGIORAZIONE IN
        (SELECT ID_MAGGIORAZIONE
        FROM CD_MAGGIORAZIONE
        WHERE ID_TIPO_MAGG = 3);
        --
        IF p_list_id_area.COUNT < 4 THEN
            IF p_list_id_area.COUNT = 1 THEN
                v_id_maggiorazione := 2;
            ELSIF p_list_id_area.COUNT = 2 THEN
                v_id_maggiorazione := 3;
            ELSIF p_list_id_area.COUNT = 3 THEN
                v_id_maggiorazione := 4;    
            END IF;
        --
        PR_SALVA_MAGGIORAZIONE(p_id_prodotto_richiesto,v_id_maggiorazione);
        --
        END IF;
        v_nuovo_importo_magg := 0;
        FOR MAG IN (SELECT M.PERCENTUALE_VARIAZIONE
                    FROM CD_MAGG_PRODOTTO MP, CD_MAGGIORAZIONE M
                    WHERE MP.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
                    AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE) LOOP
            --dbms_output.put_line('v_vecchia_tariffa'||v_imp_tariffa);
            --dbms_output.put_line('Perc Maggiorazione: '||MAG.PERCENTUALE_VARIAZIONE);
            v_nuovo_importo_magg := v_nuovo_importo_magg + PA_CD_TARIFFA.FU_CALCOLA_MAGGIORAZIONE(v_imp_tariffa,MAG.PERCENTUALE_VARIAZIONE);
        END LOOP;
        --dbms_output.put_line('Nuovo importo maggiorazione: '||v_nuovo_importo_magg);
        v_prodotto_richiesto_cur := FU_GET_DETT_PROD_RIC(p_id_prodotto_richiesto);
        --v_esito := v_prodotto_acquistato.a_tariffa;
        FETCH v_prodotto_richiesto_cur INTO v_prodotto_richiesto_rec;
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_prodotto_richiesto_rec.a_tariffa, v_prodotto_richiesto_rec.a_maggiorazione, v_prodotto_richiesto_rec.a_lordo,
                                    v_prodotto_richiesto_rec.a_lordo_comm, v_prodotto_richiesto_rec.a_lordo_dir, v_prodotto_richiesto_rec.a_netto_comm, v_prodotto_richiesto_rec.a_netto_dir,
                                    v_prodotto_richiesto_rec.a_perc_sconto_comm, v_prodotto_richiesto_rec.a_perc_sconto_dir, v_prodotto_richiesto_rec.a_sc_comm, v_prodotto_richiesto_rec.a_sc_dir,
                                    v_sanatoria, v_recupero, v_nuovo_importo_magg, '1', v_esito);
        --
        UPDATE CD_PRODOTTI_RICHIESTI
        SET IMP_TARIFFA = v_prodotto_richiesto_rec.a_tariffa,
            IMP_MAGGIORAZIONE = v_prodotto_richiesto_rec.a_maggiorazione,
            IMP_LORDO = v_prodotto_richiesto_rec.a_lordo,
            IMP_NETTO = v_prodotto_richiesto_rec.a_netto_comm + v_prodotto_richiesto_rec.a_netto_dir
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
        --
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_prodotto_richiesto_rec.a_netto_comm,
            IMP_SC_COMM = v_prodotto_richiesto_rec.a_sc_comm
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND TIPO_CONTRATTO = 'C';
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_prodotto_richiesto_rec.a_netto_dir,
            IMP_SC_COMM = v_prodotto_richiesto_rec.a_sc_dir
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND TIPO_CONTRATTO = 'D';
        CLOSE v_prodotto_richiesto_cur;
    END IF;
    --
    PR_RICALCOLA_TARIFFA_PROD_RIC(p_id_prodotto_richiesto,
                          v_vecchia_tariffa,
                          v_vecchia_tariffa,
                          'S',
                          v_piani_errati);
   EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'Procedura PR_MODIFICA_AREE_PROD_RIC: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
                              
END PR_MODIFICA_AREE_PROD_RIC;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_RICALCOLA_TARIFFA_PROD_ACQ
-- DESCRIZIONE:  Effettua il ricalcolo della tariffa di un prodotto acquistato
--
-- OPERAZIONI: 
--            1) Se il flag vale N il nuovo importo viene ricalcolato verificando lo 
--               sconto stagionale e l'eventuale riparametrizzazione
--            2) Dato il numero di schermi viene calcolato l'importo totale
--            3) Nel caso in cui il prodotto abbia la tariffa variabile vengono modificati tutti gli importi
--            4) Nel caso in cui la tariffa non sia variabile si cerca di mantenere il netto 
--               diminuendo lo sconto. Nel caso in cui non sia possibile c'e una situazione di errore
--               viene aggiunto in output l'id del piano, in modo da poterlo correggere manualmente
--               
--            5) Vengono modificati gli importi di fatturazione relativi al prodotto acquistato
-- INPUT:
--      p_id_prodotto_acquistato        id del prodotto acquistato
--      p_vecchio_importo               importo precedente alla variazione riguardante la tariffa in esame
--      p_nuovo_importo                 nuovo importo dopo la variazione
--      p_flg_variazione_schermi Flag che indica se l'operazione e un cambio nel numero di schermi
--      (schermo annullato o ripristinato) o una variazione di tariffa. Nel primo caso il parametro 
--      vale S, altrimenti N
--
--
-- OUTPUT:
--      p_piani_errati      lista con gli id di tutti i piani che non e stato possibile correggere
--
--  REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE: Mauro Viel Altran Italia  Ottobre 2011: Sostituita la chiamata alla proceura PA_PC_IMPORTI.FU_PERC_SC_COMM con PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA
--                                        in modo da ottenere il numero massimo di decimali per scongiurare problemi di arrotondamento.  #MV01 

-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                        p_vecchio_importo   CD_TARIFFA.IMPORTO%TYPE,
                                        p_nuovo_importo     CD_TARIFFA.IMPORTO%TYPE,
                                        p_flg_variazione_schermi VARCHAR2,
                                        p_piani_errati OUT VARCHAR2
                                        )
IS
    v_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
    v_netto CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
    v_maggiorazione CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE;
    v_recupero NUMBER := 0;
    v_sanatoria NUMBER := 0;
    v_lordo_comm CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
    v_lordo_dir CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
    v_netto_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_netto_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_perc_sc_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_perc_sc_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_imp_sc_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_imp_sc_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_vecchio_importo CD_TARIFFA.IMPORTO%TYPE;
    v_sconto_stag CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
    v_aliquota CD_COEFF_CINEMA.ALIQUOTA%TYPE;
    v_nuovo_importo CD_TARIFFA.IMPORTO%TYPE;
    v_id_prodotto_vendita CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE;
    v_id_formato CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE;
    v_data_inizio CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE;
    v_data_fine CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE;
    v_id_piano CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE;
    v_id_ver_piano CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE;
    v_esito NUMBER := 0;
    v_num_schermi NUMBER;
    v_id_misura_temp CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE;
    v_flg_tar_var CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE;
    v_netto_comm_vecchio CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_netto_dir_vecchio CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_id_importo_prodotto_c CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
    v_id_importo_prodotto_d CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
    v_id_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
    v_aree C_AREA_NIELSEN;
    v_area_rec R_AREA_NIELSEN;
BEGIN
    SAVEPOINT PR_RICALCOLA_TARIFFA_PROD_RIC;
    v_nuovo_importo := p_nuovo_importo;

    SELECT PV.ID_PRODOTTO_VENDITA, ID_FORMATO, FLG_TARIFFA_VARIABILE, ID_PIANO, ID_VER_PIANO, DATA_INIZIO, DATA_FINE, ID_MISURA_PRD_VE, IMP_TARIFFA, ID_MOD_VENDITA
    INTO v_id_prodotto_vendita, v_id_formato, v_flg_tar_var, v_id_piano, v_id_ver_piano, v_data_inizio, v_data_fine,v_id_misura_temp, v_vecchio_importo, v_id_mod_vendita
    FROM CD_PRODOTTI_RICHIESTI PR, CD_PRODOTTO_VENDITA PV
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA;

    IF p_flg_variazione_schermi  = 'N' THEN

        v_sconto_stag := pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(v_id_prodotto_vendita, v_data_inizio, v_data_fine,v_id_formato,v_id_misura_temp);
        v_aliquota := PA_CD_TARIFFA.FU_GET_ALIQUOTA(v_id_formato);
        v_nuovo_importo := ROUND(v_nuovo_importo * v_aliquota,2);
        v_nuovo_importo := PA_CD_UTILITY.FU_CALCOLA_IMPORTO(v_nuovo_importo,v_sconto_stag);

    END IF;

    --dbms_output.put_line(' v_nuovo_importo='|| v_nuovo_importo);

    IF v_id_mod_vendita = 1 THEN
        SELECT COUNT(1)
        INTO v_num_schermi
        FROM CD_AMBIENTI_PRODOTTI_RICHIESTI 
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
    ELSIF v_id_mod_vendita = 3 THEN
    v_aree := FU_GET_AREE_NIELSEN_PROD_RIC(p_id_prodotto_richiesto);
    --dbms_output.put_line('controllo aree eliminate');
    v_num_schermi := 0;
    LOOP
      FETCH v_aree INTO v_area_rec;
      EXIT WHEN v_aree%NOTFOUND;
           v_num_schermi := v_num_schermi + v_area_rec.a_num_schermi;
    END LOOP;
    CLOSE v_aree;
    END IF;    
    v_nuovo_importo := ROUND(v_nuovo_importo * v_num_schermi,2);

    -- dbms_output.put_line(' v_num_schermi='|| v_num_schermi);
    -- dbms_output.put_line(' v_nuovo_importo dopo='|| v_nuovo_importo);
    -- dbms_output.put_line(' vecchio importo='|| v_vecchio_importo);
    SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE
    INTO v_lordo, v_netto, v_maggiorazione
    FROM CD_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;

    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND TIPO_CONTRATTO = 'C';

    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND TIPO_CONTRATTO = 'D';

    v_netto_comm_vecchio := v_netto_comm;
    v_netto_dir_vecchio := v_netto_dir;
    v_lordo_comm := v_netto_comm + v_imp_sc_comm;
    v_lordo_dir := v_netto_dir + v_imp_sc_dir;
    --v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm, v_imp_sc_comm); #MV01
     v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(v_netto_comm, v_imp_sc_comm); --#MV01
    --v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir, v_imp_sc_dir); #MV01 
    v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(v_netto_dir, v_imp_sc_dir); --#MV01

    --dbms_output.put_line(' v_netto_comm='|| v_netto_comm);
    --dbms_output.put_line(' v_netto_dir='|| v_netto_dir);
    --dbms_output.put_line(' v_lordo='|| v_lordo);
    --dbms_output.put_line(' v_lordo_comm='|| v_lordo_comm);
    --dbms_output.put_line(' v_lordo_dir='|| v_lordo_dir);
    --dbms_output.PUT_LINE('flg tariffa variabile: '||v_flg_tar_var);
    
    IF v_nuovo_importo != v_vecchio_importo THEN
        IF v_maggiorazione > 0 THEN
        v_maggiorazione := 0;
        FOR MAG IN (SELECT M.PERCENTUALE_VARIAZIONE
                    FROM CD_MAGG_PRODOTTO MP, CD_MAGGIORAZIONE M
                    WHERE MP.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
                    AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE) LOOP
            v_maggiorazione := v_maggiorazione + PA_CD_TARIFFA.FU_CALCOLA_MAGGIORAZIONE(v_nuovo_importo,MAG.PERCENTUALE_VARIAZIONE);
        END LOOP;
        --dbms_output.put_line('maggiorazione rilevata: nuovo valore di maggiorazione='|| v_maggiorazione);
        END IF;
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_vecchio_importo,v_maggiorazione,
        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
        v_imp_sc_dir,v_sanatoria,v_recupero,v_nuovo_importo,'0',v_esito);
        if v_flg_tar_var = 'N' then
            BEGIN
    --
                --dbms_output.put_line('Sono in tariffa variabile');
                --dbms_output.put_line(' v_netto_comm='|| v_netto_comm);
                --dbms_output.put_line(' v_netto_dir='|| v_netto_dir);
                --dbms_output.put_line(' v_netto_comm_vecchio='|| v_netto_comm_vecchio);
                --dbms_output.put_line(' v_netto_dir_vecchio='|| v_netto_dir_vecchio);
            
                IF v_netto_comm != v_netto_comm_vecchio THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_vecchio_importo,v_maggiorazione,
                    v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                    v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                    v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_comm_vecchio,'31',v_esito);
                END IF;
                IF v_netto_dir != v_netto_dir_vecchio THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_nuovo_importo,v_maggiorazione,
                    v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                    v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                    v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_dir_vecchio,'32',v_esito);
                END IF;
            EXCEPTION
            WHEN OTHERS THEN
                --dbms_output.put_line('Eccezione nella modifica di un prodotto con flg = N');
                --dbms_output.put_line(' vecchio importo='||p_vecchio_importo);
                --dbms_output.put_line(' nuovo importo='|| v_nuovo_importo);
                PA_CD_IMPORTI.MODIFICA_IMPORTI(v_nuovo_importo,v_maggiorazione,
                v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                v_imp_sc_dir,v_sanatoria,v_recupero,p_vecchio_importo,'0',v_esito);
                p_piani_errati := p_piani_errati || v_id_piano||'/'||v_id_ver_piano||', ';
            END;
        end if;

        v_netto:= v_netto_comm + v_netto_dir;

        UPDATE CD_PRODOTTI_RICHIESTI
        SET IMP_TARIFFA = v_nuovo_importo,
            IMP_LORDO = v_lordo,
            IMP_NETTO = v_netto,
            IMP_MAGGIORAZIONE = v_maggiorazione
        WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto;
        --
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_comm,
        IMP_SC_COMM = v_imp_sc_comm
        WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_c;
        --
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_dir,
        IMP_SC_COMM = v_imp_sc_dir
        WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_d;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20026, 'PR_RICALCOLA_TARIFFA_PROD_RIC: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_RICALCOLA_TARIFFA_PROD_RIC;
END PR_RICALCOLA_TARIFFA_PROD_RIC;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_DETT_PROD_RIC
--
-- DESCRIZIONE:  Restituisce tutti i prodotti acquistati di un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_richiesto id del prodotto richiesto
--
--  OUTPUT: lista di prodotti acquistati appartenenti al piano
--
-- REALIZZATORE: Simone Bottani , Altran, Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_DETT_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN C_PROD_RIC_PIANO IS
--
v_prodotti C_PROD_RIC_PIANO;
v_descr_stato_vendita CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
BEGIN
--
   /*IF p_stato_vendita IS NOT NULL AND p_stato_vendita <> -1 THEN
    SELECT DESCR_BREVE
    INTO v_descr_stato_vendita
    FROM CD_STATO_DI_VENDITA
    WHERE ID_STATO_VENDITA = p_stato_vendita;
   END IF;*/
OPEN v_prodotti FOR
    SELECT ID_PRODOTTI_RICHIESTI,
           ID_PIANO,
           ID_VER_PIANO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           ID_LISTINO,
           DATA_INIZIO,
           DATA_FINE,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA, IMP_LORDO, IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS IMP_LORDO_COMM,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS IMP_LORDO_DIR,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS PERC_SCONTO_COMM,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS PERC_SCONTO_DIR,
           ID_FORMATO, DESCRIZIONE AS DESC_FORMATO,
           DURATA,
           ID_TIPO_TARIFFA,
           ID_UNITA,
           FLG_TARIFFA_VARIABILE,
           COD_POS_FISSA, DESC_POS_FISSA,
           SUBSTR(disp,1,INSTR(disp,'|',1,1) -1) as disponibilita_minima,
           SUBSTR(disp,INSTR(disp,'|',1,1) +1,length(disp)) as disponibilita_massima,
           FLG_ACQUISTATO,
           SETTIMANA_SIPRA,
           FU_GET_NUM_AMBIENTI(ID_PRODOTTI_RICHIESTI) AS NUM_AMBIENTI,
           ID_TIPO_CINEMA,
           id_spettacolo,
           numero_massimo_schermi
        FROM
        (SELECT
           PR_RIC.ID_PRODOTTI_RICHIESTI,
           PR_RIC.ID_PIANO,
           PR_RIC.ID_VER_PIANO,
           PR_VEN.ID_PRODOTTO_VENDITA,
           PR_PUB.DESC_PRODOTTO,
           CIR.ID_CIRCUITO,
           CIR.NOME_CIRCUITO,
           MOD_VEN.ID_MOD_VENDITA,
           MOD_VEN.DESC_MOD_VENDITA,
           TI_BR.DESC_TIPO_BREAK,
           MAN.DES_MAN,
           PR_RIC.IMP_TARIFFA, PR_RIC.IMP_LORDO, PR_RIC.IMP_NETTO,
           IMP_PRD_D.IMP_NETTO as IMP_NETTO_DIR,
           IMP_PRD_D.IMP_SC_COMM as IMP_SC_DIR,
           IMP_PRD_C.IMP_NETTO as IMP_NETTO_COMM,
           IMP_PRD_C.IMP_SC_COMM as IMP_SC_COMM,
           PR_RIC.IMP_MAGGIORAZIONE,
           MIS.ID_UNITA,
           PR_RIC.DATA_INIZIO,
           PR_RIC.DATA_FINE,
           PR_RIC.FLG_TARIFFA_VARIABILE,
           F_ACQ.ID_FORMATO, F_ACQ.DESCRIZIONE, COEF.DURATA,
           TAR.ID_TIPO_TARIFFA,
           TAR.ID_LISTINO,
           POS.COD_POSIZIONE AS COD_POS_FISSA, POS.DESCRIZIONE AS DESC_POS_FISSA,
           PR_RIC.FLG_ACQUISTATO,
           PERIODO.ANNO ||'-'||PERIODO.CICLO||'-'||PERIODO.PER AS SETTIMANA_SIPRA,
           PR_RIC.ID_TIPO_CINEMA,
           pr_ric.ID_SPETTACOLO,
           pr_ric.NUMERO_MASSIMO_SCHERMI,
           '0|0' as disp--(SELECT pa_cd_estrazione_prod_vendita.fu_affollamento(p_tipo_disp,PR_VEN.ID_PRODOTTO_VENDITA, v_descr_stato_vendita,PR_RIC.DATA_INIZIO, PR_RIC.DATA_FINE) FROM DUAL) disp
        FROM
           PERIODI PERIODO,
           PC_MANIF MAN,
           CD_TIPO_BREAK TI_BR,
           CD_MODALITA_VENDITA MOD_VEN,
           CD_CIRCUITO CIR,
           CD_PRODOTTO_PUBB PR_PUB,
           CD_TARIFFA TAR,
           CD_PRODOTTO_VENDITA PR_VEN,
           CD_COEFF_CINEMA COEF,
           CD_FORMATO_ACQUISTABILE F_ACQ,
           CD_MISURA_PRD_VENDITA MIS,
           CD_IMPORTI_PRODOTTO IMP_PRD_D,
           CD_IMPORTI_PRODOTTO IMP_PRD_C,
           CD_PRODOTTI_RICHIESTI PR_RIC,
           CD_POSIZIONE_RIGORE POS
        WHERE PR_RIC.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        and PR_RIC.FLG_ANNULLATO = 'N'
        and PR_RIC.FLG_SOSPESO = 'N'
        and IMP_PRD_C.ID_PRODOTTI_RICHIESTI = PR_RIC.ID_PRODOTTI_RICHIESTI
        and IMP_PRD_C.TIPO_CONTRATTO = 'C'
        and IMP_PRD_D.ID_PRODOTTI_RICHIESTI = PR_RIC.ID_PRODOTTI_RICHIESTI
        and IMP_PRD_D.TIPO_CONTRATTO = 'D'
        and F_ACQ.ID_FORMATO = PR_RIC.ID_FORMATO
        AND COEF.ID_COEFF(+) = F_ACQ.ID_COEFF
        and MIS.ID_MISURA_PRD_VE = PR_RIC.ID_MISURA_PRD_VE
        and PR_VEN.ID_PRODOTTO_VENDITA = PR_RIC.ID_PRODOTTO_VENDITA
        and TAR.ID_PRODOTTO_VENDITA = PR_VEN.ID_PRODOTTO_VENDITA
        and (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PR_RIC.ID_FORMATO)
        and PR_RIC.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
        and PR_RIC.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
        and PR_PUB.ID_PRODOTTO_PUBB = PR_VEN.ID_PRODOTTO_PUBB
        and CIR.ID_CIRCUITO = PR_VEN.ID_CIRCUITO
        and MOD_VEN.ID_MOD_VENDITA = PR_VEN.ID_MOD_VENDITA
        and TI_BR.ID_TIPO_BREAK(+) = PR_VEN.ID_TIPO_BREAK
        and MAN.COD_MAN(+) = PR_VEN.COD_MAN
        and POS.COD_POSIZIONE (+) = PR_RIC.COD_POSIZIONE
        and PR_RIC.DATA_INIZIO = PERIODO.DATA_INIZ (+)
        and PR_RIC.DATA_FINE = PERIODO.DATA_FINE (+)
        )
        ORDER BY DATA_INIZIO,DATA_FINE,ID_CIRCUITO;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_DETT_PROD_RIC;

FUNCTION FU_GET_LUOGO_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN CD_LUOGO.ID_LUOGO%TYPE IS
v_luogo_return CD_LUOGO.ID_LUOGO%TYPE;
BEGIN
    BEGIN
    SELECT CD_LUOGO.ID_LUOGO
    INTO v_luogo_return
     FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB, CD_PRODOTTO_VENDITA, CD_PRODOTTO_PUBB, CD_PRODOTTI_RICHIESTI 
     WHERE CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
     AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA
     AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
     AND CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB IS NULL
     AND CD_PRODOTTO_PUBB.COD_TIPO_PUBB = CD_LUOGO_TIPO_PUBB.COD_TIPO_PUBB
     AND CD_LUOGO.ID_LUOGO = CD_LUOGO_TIPO_PUBB.ID_LUOGO;
     EXCEPTION WHEN NO_DATA_FOUND THEN
        v_luogo_return := 6;
     END;
RETURN v_luogo_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_LUOGO_PROD_RIC;
--
PROCEDURE PR_MODIFICA_SCHERMI_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                       v_string_id_ambito     varchar) IS
        --
    v_string_ambiti_prodotto varchar(32000);
    BEGIN
    FOR SC_PR IN (SELECT ID_SCHERMO 
                  FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                  WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(SC_PR.ID_SCHERMO,5,'0')||'|';
    END LOOP;
    --
    DELETE FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_SCHERMO,5,'0')||'|') < 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_SCHERMO,5,'0')||'|') >= 1;
    --
    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI
    (ID_PRODOTTI_RICHIESTI,ID_SCHERMO)
    (SELECT p_id_prodotto_richiesto, ID_SCHERMO
    FROM CD_SCHERMO
    WHERE instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_SCHERMO,5,'0')||'|') >= 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_SCHERMO,5,'0')||'|') < 1);
END PR_MODIFICA_SCHERMI_PROD_RIC;
--
PROCEDURE PR_MODIFICA_ATRII_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                     v_string_id_ambito     varchar) IS
        --
    v_string_ambiti_prodotto varchar(32000);
    BEGIN
    FOR SC_PR IN (SELECT ID_ATRIO 
                  FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                  WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(SC_PR.ID_ATRIO,5,'0')||'|';
    END LOOP;
    --
    DELETE FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_ATRIO,5,'0')||'|') < 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_ATRIO,5,'0')||'|') >= 1;
    --
    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI
    (ID_PRODOTTI_RICHIESTI,ID_ATRIO)
    (SELECT p_id_prodotto_richiesto, ID_ATRIO
    FROM CD_ATRIO
    WHERE instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_ATRIO,5,'0')||'|') >= 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_ATRIO,5,'0')||'|') < 1);
END PR_MODIFICA_ATRII_PROD_RIC;

--
PROCEDURE PR_MODIFICA_SALE_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                     v_string_id_ambito     varchar) IS
        --
    v_string_ambiti_prodotto varchar(32000);
    BEGIN
    FOR SC_PR IN (SELECT ID_SALA 
                  FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                  WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(SC_PR.ID_SALA,5,'0')||'|';
    END LOOP;
    --
    DELETE FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_SALA,5,'0')||'|') < 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_SALA,5,'0')||'|') >= 1;
    --
    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI
    (ID_PRODOTTI_RICHIESTI,ID_SALA)
    (SELECT p_id_prodotto_richiesto, ID_SALA
    FROM CD_SALA
    WHERE instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_SALA,5,'0')||'|') >= 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_SALA,5,'0')||'|') < 1);
END PR_MODIFICA_SALE_PROD_RIC;

PROCEDURE PR_MODIFICA_CINEMA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE,
                                     v_string_id_ambito     varchar) IS
        --
    v_string_ambiti_prodotto varchar(32000);
    BEGIN
    FOR SC_PR IN (SELECT ID_CINEMA 
                  FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                  WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(SC_PR.ID_CINEMA,5,'0')||'|';
    END LOOP;
    --
    DELETE FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
    WHERE ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
    AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_CINEMA,5,'0')||'|') < 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_CINEMA,5,'0')||'|') >= 1;
    --
    INSERT INTO CD_AMBIENTI_PRODOTTI_RICHIESTI
    (ID_PRODOTTI_RICHIESTI,ID_CINEMA)
    (SELECT p_id_prodotto_richiesto, ID_CINEMA
    FROM CD_CINEMA
    WHERE instr ('|'||v_string_id_ambito||'|','|'||LPAD(ID_CINEMA,5,'0')||'|') >= 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(ID_CINEMA,5,'0')||'|') < 1);
   
END PR_MODIFICA_CINEMA_PROD_RIC;



-----------------------------------------------------------------------------------------------------
-- Funzione PR_ACQUISTO_MASSIVO
--
-- DESCRIZIONE:  Effettua l'acquisto di tutti i prodotti ancora non acquistati del piano 
--
--
-- OPERAZIONI:
--
--
-- REALIZZATORE: Simone Bottani , Altran, Novembre 2009
--
--  MODIFICHE: Mauro Viel, Altran Italia, Aprile 2011 
--             modificata la query di estrazione della tariffa. Per consentire l'acquisto di prodotti 
--            a cavallo di due listini.Verra prelevata la tariffa piu vecchia solo per i prodotti segui il film 
-------------------------------------------------------------------------------------------------



PROCEDURE PR_ACQUISTO_MASSIVO (
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_esito                 OUT NUMBER) IS
    --
    v_lordo_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_lordo_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_sconto_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_sconto_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_num_ambienti NUMBER;
    v_id_listino CD_LISTINO.ID_LISTINO%TYPE;
    v_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE;
    v_list_maggiorazioni id_list_type := id_list_type();
    v_esito NUMBER;
    v_posizione_disponibile NUMBER;
    v_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
    v_list_ambienti id_list_type;
    v_index NUMBER;
    v_flg_segui_il_film cd_prodotto_vendita.FLG_SEGUI_IL_FILM%type;
    --
    BEGIN
    SAVEPOINT PR_ACQUISTO_MASSIVO;
    p_esito := 1;
    FOR PR IN (SELECT * FROM CD_PRODOTTI_RICHIESTI
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano
    AND FLG_ANNULLATO = 'N'
    AND FLG_SOSPESO = 'N'
    AND FLG_ACQUISTATO = 'N') LOOP
    --
        v_list_ambienti := id_list_type();
        v_index := 1;
        v_posizione_disponibile := 0;
        
         select pv.FLG_SEGUI_IL_FILM
        into v_flg_segui_il_film
        from cd_prodotti_richiesti prod, cd_prodotto_vendita pv 
        where id_prodotti_richiesti = pr.id_prodotti_richiesti
        and  prod.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA;
        
        if v_flg_segui_il_film = 'N' then
            SELECT TARIFFA.ID_LISTINO, U.ID_UNITA, PV.ID_MOD_VENDITA
            INTO v_id_listino, v_unita_temp, v_mod_vendita
            FROM CD_UNITA_MISURA_TEMP U, CD_MISURA_PRD_VENDITA MIS,
            CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
            WHERE PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA
            AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
            --AND TARIFFA.ID_LISTINO = p_id_listino
            AND TARIFFA.DATA_INIZIO <= PR.DATA_INIZIO
            AND TARIFFA.DATA_FINE >= PR.DATA_FINE
            AND MIS.ID_MISURA_PRD_VE = PR.ID_MISURA_PRD_VE
            AND TARIFFA.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE
            AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR PR.ID_FORMATO = TARIFFA.ID_FORMATO)
            --AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
            AND MIS.ID_UNITA = U.ID_UNITA;
        else
            SELECT min(TARIFFA.ID_LISTINO) as ID_LISTINO, 
                   min(U.ID_UNITA) as ID_UNITA, 
                   min(PV.ID_MOD_VENDITA) as ID_MOD_VENDITA
            INTO v_id_listino, v_unita_temp, v_mod_vendita
            FROM CD_UNITA_MISURA_TEMP U, CD_MISURA_PRD_VENDITA MIS,
            CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
            WHERE PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA
            AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
            AND  ((PR.DATA_INIZIO between TARIFFA.DATA_INIZIO  and TARIFFA.DATA_FINE ) or (PR.DATA_FINE between TARIFFA.DATA_INIZIO  and TARIFFA.DATA_FINE))
            AND MIS.ID_MISURA_PRD_VE = PR.ID_MISURA_PRD_VE
            AND TARIFFA.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE
            AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR PR.ID_FORMATO = TARIFFA.ID_FORMATO)
            --AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
            AND MIS.ID_UNITA = U.ID_UNITA;        
        end if;
        
                
        IF PR.COD_POSIZIONE IS NOT NULL THEN
            IF v_mod_vendita = 1 THEN
                FOR AMBIENTI IN (SELECT ID_SCHERMO
                        FROM CD_AMBIENTI_PRODOTTI_RICHIESTI
                        WHERE ID_PRODOTTI_RICHIESTI = PR.ID_PRODOTTI_RICHIESTI) LOOP
                v_list_ambienti.EXTEND;
                v_list_ambienti(v_index) := AMBIENTI.ID_SCHERMO;
                v_index := v_index +1;
                END LOOP;
            ELSIF v_mod_vendita = 3 THEN
                FOR AREE IN (SELECT ID_AREA_NIELSEN
                        FROM CD_AREE_PRODOTTI_RICHIESTI
                        WHERE ID_PRODOTTI_RICHIESTI = PR.ID_PRODOTTI_RICHIESTI) LOOP
                v_list_ambienti.EXTEND;
                v_list_ambienti(v_index) := AREE.ID_AREA_NIELSEN;
                v_index := v_index +1;
                END LOOP;
            
            END IF;
            v_posizione_disponibile := PA_CD_PRODOTTO_ACQUISTATO.FU_VERIFICA_POS_RIGORE(NULL,
                                PR.ID_PRODOTTO_VENDITA,
                                PR.COD_POSIZIONE,
                                PR.DATA_INIZIO,
                                PR.DATA_FINE,
                                v_list_ambienti);
            IF v_posizione_disponibile > 0 THEN
                p_esito := -2;
            END IF;
        END IF;
        IF v_posizione_disponibile = 0 THEN
            SELECT IMP_NETTO + IMP_SC_COMM, IMP_SC_COMM
            INTO v_lordo_comm, v_sconto_comm
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTI_RICHIESTI = PR.ID_PRODOTTI_RICHIESTI
            AND TIPO_CONTRATTO = 'C';
            --
            SELECT IMP_NETTO + IMP_SC_COMM, IMP_SC_COMM
            INTO v_lordo_dir, v_sconto_dir
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTI_RICHIESTI = PR.ID_PRODOTTI_RICHIESTI
            AND TIPO_CONTRATTO = 'D';
            v_num_ambienti := FU_GET_NUM_AMBIENTI(PR.ID_PRODOTTI_RICHIESTI);
            --
            PR_ACQUISTA_PROD_RIC (
                PR.ID_PRODOTTI_RICHIESTI,
                PR.ID_PRODOTTO_VENDITA,
                p_id_piano,
                p_id_ver_piano,
                PR.DATA_INIZIO,
                PR.DATA_FINE,
                PR.ID_FORMATO,
                PR.IMP_TARIFFA,
                PR.IMP_LORDO,
                v_lordo_comm,
                v_lordo_dir,
                v_sconto_comm,
                v_sconto_dir,
                PR.IMP_MAGGIORAZIONE,
                v_unita_temp,
                v_id_listino,
                v_num_ambienti,
                PR.COD_POSIZIONE,
                PR.FLG_TARIFFA_VARIABILE,
                v_list_maggiorazioni,
                PR.ID_TIPO_CINEMA,
                PR.id_spettacolo,
                PR.numero_massimo_schermi,
                v_esito);
        END IF;  
    END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        p_esito := -1;
        ROLLBACK TO PR_ACQUISTO_MASSIVO;
      RAISE;
END PR_ACQUISTO_MASSIVO;

FUNCTION FU_GET_NOME_CINEMA_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) RETURN VARCHAR2 IS
    --
    v_num_ambienti NUMBER;
    v_nome_cinema VARCHAR2(150);
    v_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
    v_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
    BEGIN
    v_num_ambienti := FU_GET_NUM_AMBIENTI(p_id_prodotto_richiesto);
    IF v_num_ambienti > 1 THEN
        v_nome_cinema := '*';
    ELSE
        SELECT PV.ID_MOD_VENDITA, PV.ID_CIRCUITO
        INTO v_mod_vendita, v_circuito
        FROM CD_PRODOTTI_RICHIESTI PR, CD_PRODOTTO_VENDITA PV
        WHERE PR.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
        AND PV.ID_PRODOTTO_VENDITA = PR.ID_PRODOTTO_VENDITA;
        --
        IF v_mod_vendita = 1 THEN
            SELECT CIN2.NOME_CINEMA || ' - ' || COM.COMUNE
            INTO v_nome_cinema
            FROM 
            CD_CINEMA CIN2,CD_CINEMA CIN, CD_COMUNE COM, 
            CD_SALA S, CD_ATRIO A, CD_AMBIENTI_PRODOTTI_RICHIESTI AMB
            WHERE AMB.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto
            AND A.ID_ATRIO(+) = AMB.ID_ATRIO
            AND S.ID_SALA(+) = AMB.ID_SALA
            AND CIN.ID_CINEMA(+) = AMB.ID_CINEMA
            AND (A.ID_CINEMA IS NULL OR CIN2.ID_CINEMA = A.ID_CINEMA)
            AND (S.ID_CINEMA IS NULL OR CIN2.ID_CINEMA = S.ID_CINEMA)
            AND (CIN.ID_CINEMA IS NULL OR CIN2.ID_CINEMA = CIN.ID_CINEMA)
            AND COM.ID_COMUNE = CIN2.ID_COMUNE
            AND ROWNUM = 1;            
        ELSIF v_mod_vendita = 2 THEN
            SELECT CIN.NOME_CINEMA || ' - ' || COM.COMUNE
            INTO v_nome_cinema
            FROM CD_CINEMA CIN, CD_COMUNE COM, CD_CIRCUITO_CINEMA CC
            WHERE CC.ID_CIRCUITO = v_circuito
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND COM.ID_COMUNE = CIN.ID_COMUNE;
        END IF;
    END IF;
    RETURN v_nome_cinema;
END FU_GET_NOME_CINEMA_PROD_RIC;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_TOTALI_PROD_RIC
--
-- DESCRIZIONE:  Restituisce informazioni sui totali di importi (lordo, netto ecc) di prodotti acquistati in un piano
--
--
-- OPERAZIONI:
--            1) Estrae tutti i prodotti acquistati di un piano e restituisce la somma degli importi
--
--  INPUT:
--      p_id_piano   id del piano
--      p_id_ver_piano
--  OUTPUT: 
--      se tutti i comunicati del prodotto acquistato sono associati ad un unico materiale
--      restituisce il suo titolo, altrimenti restituisce *
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_TOTALI_PROD_RIC(
                                  p_id_piano CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
                                  p_id_ver_piano CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE) RETURN C_TOT_PROD_RIC_PIANO IS
--
v_prodotti C_TOT_PROD_RIC_PIANO;
BEGIN
OPEN v_prodotti FOR
  SELECT NUM_PRODOTTI,
       SUM_TARIFFA,
       SUM_LORDO,
       SUM_NETTO,
       SUM_SCONTO,
       0 AS SUM_NETTO_DIR,
       SUM_MAGGIORAZIONE,
       0 AS SUM_RECUPERO,
       0 AS SUM_SANATORIA,
       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM_NETTO, SUM_SCONTO),0) AS AVG_SCONTO,
       TRUNC(nettoComm, 3) as TOT_NETTO_C, TRUNC(nettoDir, 3) as TOT_NETTO_D,
       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoComm, scComCom),0) as TOT_PERC_SCONTO_C,
       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoDir, scComDir),0) as TOT_PERC_SCONTO_D
       --TRUNC(AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoComm, scComCom),0)),3) as TOT_PERC_SCONTO_C,
       --TRUNC(AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoDir, scComDir),0)),3) as TOT_PERC_SCONTO_D
       --TRUNC(percScontoComm, 3) as TOT_PERC_SCONTO_C,
       --TRUNC(percScontoDir, 3) as TOT_PERC_SCONTO_D
    FROM(
    SELECT
       COUNT(pr.ID_PRODOTTI_RICHIESTI) AS NUM_PRODOTTI,
       NVL(SUM(pr.IMP_TARIFFA),0) AS SUM_TARIFFA,
       NVL(SUM(pr.IMP_LORDO),0) AS SUM_LORDO,
       NVL(SUM(pr.IMP_NETTO),0) AS SUM_NETTO,
       0 AS SUM_SCONTO,
       0 AS SUM_NETTO_DIR,
       NVL(SUM(pr.IMP_MAGGIORAZIONE),0) AS SUM_MAGGIORAZIONE,
       --NVL(SUM(pr.IMP_RECUPERO),0) AS SUM_RECUPERO,
       --NVL(SUM(pr.IMP_SANATORIA),0) AS SUM_SANATORIA,
       NVL(SUM(ipc.IMP_NETTO), 0) as nettoComm, 
       NVL(SUM(ipd.IMP_NETTO), 0) as nettoDir,
       NVL(SUM(ipc.imp_sc_comm), 0) as scComCom, 
       NVL(SUM(ipd.imp_sc_comm), 0) as scComDir
       --AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipc.imp_netto, ipc.imp_sc_comm),0)) as percScontoComm,
       --AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto, ipd.imp_sc_comm),0)) as percScontoDir
  FROM CD_PRODOTTI_RICHIESTI pr, cd_importi_prodotto ipc, cd_importi_prodotto ipd
  WHERE pr.ID_PIANO = p_id_piano
  AND pr.ID_VER_PIANO = p_id_ver_piano
  AND pr.FLG_ANNULLATO = 'N'
  AND pr.FLG_SOSPESO = 'N'
  and ipc.id_prodotti_richiesti = pr.id_prodotti_richiesti
  and ipc.TIPO_CONTRATTO = 'C'
  and ipd.id_prodotti_richiesti = pr.id_prodotti_richiesti
  and ipd.TIPO_CONTRATTO = 'D'
  );
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_TOTALI_PROD_RIC;



PROCEDURE PR_MODIFICA_IMPORTI_MASSIVA(p_list_prodotti id_list_type, 
                                      p_lordo_comm_tot CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE, 
                                      p_lordo_dir_tot CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE, 
                                      p_netto_comm_tot NUMBER, 
                                      p_netto_dir_tot NUMBER, 
                                      p_esito OUT NUMBER) IS
--
v_id_prodotto_richiesto     CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE;
v_lordo_tot                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE := p_lordo_comm_tot + p_lordo_dir_tot;
v_netto_tot                 CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE := p_netto_comm_tot + p_netto_dir_tot;  
v_lordo_com_prodotto        CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_lordo_dir_prodotto        CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_netto_com_prodotto        CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
v_netto_dir_prodotto        CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
v_coeff_ripartizione        NUMBER;
v_lordo                     CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_netto                     CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
v_maggiorazione             CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE;
v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
v_id_importo_prodotto_c     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_importo_prodotto_d     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_comm                CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_lordo_dir                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_formato                CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE;
v_tariffa_variabile         CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE;
v_pos_rigore                CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_netto_orig                CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
v_lordo_comm_temp           CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE := 0;
v_lordo_dir_temp            CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE := 0;
v_netto_comm_temp           CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE := 0;
v_netto_dir_temp            CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE := 0;
v_ind_maggiorazioni         NUMBER;
v_list_maggiorazioni        id_list_type;
v_sanatoria                 NUMBER := 0;
v_recupero                  NUMBER := 0;
 --   
    BEGIN
    IF p_list_prodotti IS NOT NULL AND p_list_prodotti.COUNT > 0 THEN
       FOR i IN 1..p_list_prodotti.COUNT LOOP
            v_id_prodotto_richiesto := p_list_prodotti(i);
            SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_TARIFFA, ID_FORMATO, FLG_TARIFFA_VARIABILE, COD_POSIZIONE
            INTO v_lordo, v_netto, v_maggiorazione, v_tariffa, v_id_formato, v_tariffa_variabile, v_pos_rigore
            FROM CD_PRODOTTI_RICHIESTI
            WHERE ID_PRODOTTI_RICHIESTI =  v_id_prodotto_richiesto;
            SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
            INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTI_RICHIESTI = v_id_prodotto_richiesto
            AND TIPO_CONTRATTO = 'C';
            SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
            INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTI_RICHIESTI = v_id_prodotto_richiesto
            AND TIPO_CONTRATTO = 'D';
            --
            v_lordo_comm := v_netto_comm + v_imp_sc_comm;
            v_lordo_dir := v_netto_dir + v_imp_sc_dir;
            v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm, v_imp_sc_comm); 
            v_perc_sc_dir  := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir, v_imp_sc_dir); 
            v_netto_orig := v_netto_comm + v_netto_dir;
            IF i < p_list_prodotti.COUNT THEN 

                --
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                v_coeff_ripartizione := (v_lordo_comm + v_lordo_dir) / v_lordo_tot;
                --dbms_output.PUT_LINE('v_lordo_tot: '||v_lordo_tot);
                v_lordo_com_prodotto := ROUND(p_lordo_comm_tot * v_coeff_ripartizione,2);
                --dbms_output.PUT_LINE('coeff: '||v_coeff_ripartizione);
                --dbms_output.PUT_LINE('v_lordo_com_prodotto: '||v_lordo_com_prodotto);
            
                IF v_lordo_com_prodotto != v_lordo_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_com_prodotto,'21',p_esito);    
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                v_lordo_dir_prodotto := ROUND(p_lordo_dir_tot * v_coeff_ripartizione,2);
                IF v_lordo_dir_prodotto != v_lordo_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir_prodotto,'22',p_esito);    
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                --dbms_output.PUT_LINE('v_lordo_comm: '||v_lordo_comm);
                --v_coeff_ripartizione := (v_netto_comm + v_netto_dir) / v_netto_tot;
                --(v_lordo_comm / v_netto_comm)
                IF p_netto_comm_tot = 0 THEN
                    v_coeff_ripartizione := 0;
                ELSE
                    IF v_netto_comm = 0 THEN
                        v_coeff_ripartizione := (p_netto_comm_tot / p_lordo_comm_tot) *(v_lordo_comm * v_perc_sc_comm / 100) / p_netto_comm_tot;
                    ELSE
                        v_coeff_ripartizione := (p_netto_comm_tot / p_lordo_comm_tot) * (v_netto_comm * (v_lordo_comm / v_netto_comm)) / p_netto_comm_tot;
                    END IF;
                END IF;    
                --dbms_output.PUT_LINE('coeff: '||v_coeff_ripartizione);
                --dbms_output.PUT_LINE('v_netto_tot: '||v_netto_tot);
                v_netto_com_prodotto := ROUND(p_netto_comm_tot * v_coeff_ripartizione,2);
                --dbms_output.PUT_LINE('v_netto_com_prodotto: '||v_netto_com_prodotto);
                --
                IF v_netto_com_prodotto != v_netto_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_com_prodotto,'31',p_esito);    
                END IF;
            
                --
                IF p_netto_dir_tot = 0 THEN
                    v_coeff_ripartizione := 0;
                ELSE
                    IF v_netto_dir = 0 THEN
                        v_coeff_ripartizione := (p_netto_dir_tot / p_lordo_dir_tot) * (v_lordo_dir * v_perc_sc_dir / 100) / p_netto_dir_tot;
                   ELSE
                        v_coeff_ripartizione := (p_netto_dir_tot / p_lordo_dir_tot) * (v_netto_dir * (v_lordo_dir / v_netto_dir)) / p_netto_dir_tot;
                    END IF;
                END IF;   
                v_netto_dir_prodotto := ROUND(p_netto_dir_tot* v_coeff_ripartizione,2);
                --dbms_output.PUT_LINE('v_netto_dir_prodotto: '||v_netto_dir_prodotto);
                IF v_netto_dir_prodotto != v_netto_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_dir_prodotto,'32',p_esito);
                END IF;
                --
                v_lordo_comm_temp := v_lordo_comm_temp + v_lordo_comm;
                v_lordo_dir_temp := v_lordo_dir_temp + v_lordo_dir;
                v_netto_comm_temp := v_netto_comm_temp + v_netto_comm;
                v_netto_dir_temp := v_netto_dir_temp + v_netto_dir;                
            ELSE
                --dbms_output.PUT_LINE('ultimo prodotto');
                v_lordo_com_prodotto := p_lordo_comm_tot - v_lordo_comm_temp;
                --dbms_output.PUT_LINE('v_lordo_com_prodotto: '||v_lordo_com_prodotto);
                IF v_lordo_com_prodotto != v_lordo_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_com_prodotto,'21',p_esito);    
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                v_lordo_dir_prodotto := p_lordo_dir_tot - v_lordo_dir_temp;
                --dbms_output.PUT_LINE('v_lordo_dir_prodotto: '||v_lordo_dir_prodotto);
                IF v_lordo_dir_prodotto != v_lordo_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir_prodotto,'22',p_esito);    
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --
                v_netto_com_prodotto := p_netto_comm_tot - v_netto_comm_temp;
                --dbms_output.PUT_LINE('v_netto_com_prodotto: '||v_netto_com_prodotto);
                IF v_netto_com_prodotto != v_netto_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_com_prodotto,'31',p_esito);    
                END IF;
                --
                v_netto_dir_prodotto := p_netto_dir_tot - v_netto_dir_temp;
                --dbms_output.PUT_LINE('v_netto_dir_prodotto: '||v_netto_dir_prodotto);
                IF v_netto_dir_prodotto != v_netto_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_dir_prodotto,'32',p_esito);
                END IF;                
            END IF;
            
            v_ind_maggiorazioni := 1;
            v_list_maggiorazioni := id_list_type();
            FOR MAG IN (SELECT * FROM CD_MAGG_PRODOTTO
                        WHERE ID_PRODOTTI_RICHIESTI = v_id_prodotto_richiesto) LOOP
                v_list_maggiorazioni.EXTEND;
                v_list_maggiorazioni(v_ind_maggiorazioni) := MAG.ID_MAGGIORAZIONE;
                v_ind_maggiorazioni := v_ind_maggiorazioni +1;
            END LOOP;
            --
            PR_MODIFICA_PRODOTTO_RICHIESTO(
                    v_id_prodotto_richiesto,
                    v_tariffa,
                    v_lordo,
                    v_maggiorazione,
                    v_netto_comm,
                    v_imp_sc_comm,
                    v_netto_dir,
                    v_imp_sc_dir,
                    v_pos_rigore,
                    v_id_formato,
                    v_tariffa_variabile,
                    v_list_maggiorazioni);
    END LOOP;
   END IF;
END PR_MODIFICA_IMPORTI_MASSIVA;


function fu_get_nome_spettacolo(p_id_prodotto_richiesto  cd_prodotti_richiesti.id_prodotti_richiesti%type) return cd_spettacolo.NOME_SPETTACOLO%type is
v_nome_spettacolo cd_spettacolo.nome_spettacolo%type;
begin

select spet.nome_spettacolo 
into v_nome_spettacolo
from cd_prodotti_richiesti pr, cd_prodotto_vendita pv,cd_spettacolo spet
where pr.id_prodotto_vendita = pv.id_prodotto_vendita
and   pv.flg_segui_il_film = 'S'
and   spet.id_spettacolo = pr.id_spettacolo
and   pr.flg_annullato ='N'
and   pr.flg_sospeso ='N'
and   pr.id_prodotti_richiesti = p_id_prodotto_richiesto;

return v_nome_spettacolo;
end fu_get_nome_spettacolo;



-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_PROD_MODULO_SEGUI_FILM
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto richiesto nel sistema
--               a partire da un prodotto vendita
--
--
-- OPERAZIONI:
--  1) Memorizza il prodotto richiesto
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_tariffa            id della tariffa
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Simone Bottani , Altran, Novembre 2009
--
--  MODIFICHE:
-- Mauro Viel Altran Italia  14 Febbraio 2011 inserito il parametro id_spettacolo, numero_massimo_scherm per il nuovo prodotto segui il film. 
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_MODULO_SEGUI_FILM (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE,
    p_sconto                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_id_spettacolo         cd_prodotti_richiesti.ID_SPETTACOLO%type,
    p_numero_massimo_schermi cd_prodotti_richiesti.NUMERO_MASSIMO_SCHERMI%type,
    p_id_tariffa            cd_tariffa.ID_TARIFFA%type,
    p_esito                 OUT NUMBER)
IS

v_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
v_seq CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE;
v_seq_prev CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_netto CD_PRODOTTI_RICHIESTI.IMP_NETTO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_periodo_piano CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
v_id_periodo_richiesta CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE;
v_stato_lavorazione CD_STATO_LAVORAZIONE.STATO_PIANIFICAZIONE%TYPE;
BEGIN
--
p_esito     := 1;

       SAVEPOINT PR_CREA_PROD_RICH_MODULO;
--
     v_lordo := p_lordo;
     v_netto := PA_PC_IMPORTI.FU_NETTO(p_lordo, p_sconto);
     --
     SELECT LAV.STATO_PIANIFICAZIONE
     INTO v_stato_lavorazione
     FROM CD_PIANIFICAZIONE P, CD_STATO_LAVORAZIONE LAV
     WHERE P.ID_PIANO = p_id_piano
     AND P.ID_VER_PIANO = p_id_ver_piano
     AND P.ID_STATO_LAV = LAV.ID_STATO_LAV;
     IF v_stato_lavorazione = 'RICHIESTA' THEN
        v_id_periodo_richiesta := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_RICHIESTA(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);
     ELSIF v_stato_lavorazione = 'PIANO' THEN
        v_id_periodo_piano := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_PIANO(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);
     END IF;
     
     
       begin
        SELECT CD_PRODOTTI_RICHIESTI_SEQ.CURRVAL INTO v_seq_prev FROM DUAL;
        EXCEPTION  
        WHEN OTHERS THEN
        v_seq_prev := 0;
       end;
     --
       INSERT INTO CD_PRODOTTI_RICHIESTI
         ( ID_PRODOTTO_VENDITA,
           ID_FORMATO,
           ID_PIANO,
           ID_VER_PIANO,
           ID_IMPORTI_RICHIESTA,
           ID_IMPORTI_RICHIESTI_PIANO,
           IMP_LORDO,
           IMP_MAGGIORAZIONE,
           IMP_TARIFFA,
           IMP_NETTO,
           DATA_INIZIO,
           DATA_FINE,
           ID_MISURA_PRD_VE,
           FLG_TARIFFA_VARIABILE,
           COD_POSIZIONE,
           ID_TIPO_CINEMA,
           ID_SPETTACOLO,
           NUMERO_MASSIMO_SCHERMI,
           FLG_ESCLUSIVO
          )
        SELECT p_id_prodotto_vendita,
         p_id_formato,
         p_id_piano,
         p_id_ver_piano,
         v_id_periodo_richiesta,
         v_id_periodo_piano,
         v_lordo,
         p_maggiorazione AS MAGGIORAZIONE,
         p_tariffa AS TARIFFA,
         v_netto,
         p_data_inizio,
         p_data_fine,
         TARIFFA.ID_MISURA_PRD_VE,
         p_tariffa_variabile,
         p_id_posizione_rigore,
         p_id_tipo_cinema,
         p_id_spettacolo,
         p_numero_massimo_schermi,
         'S'
        FROM
        CD_UNITA_MISURA_TEMP, CD_MISURA_PRD_VENDITA,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.ID_TARIFFA = p_id_tariffa
        AND TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND CD_UNITA_MISURA_TEMP.ID_UNITA = p_unita_temp;

        SELECT CD_PRODOTTI_RICHIESTI_SEQ.CURRVAL INTO v_seq FROM DUAL;
        
        if v_seq= v_seq_prev then
            RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_CREA_PROD_MODULO_SEGUI_FILM: INSERT NON ESEGUITA ');
        end if;

       INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTI_RICHIESTI)
        SELECT
        'C',v_netto,p_sconto,v_seq
        FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTI_RICHIESTI)
        VALUES('D',0,0,v_seq);
  --
  IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
       FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
         PR_SALVA_MAGGIORAZIONE(v_seq, p_list_maggiorazioni(i));
     END LOOP;
   END IF;

   IF p_list_id_area IS NOT NULL AND p_list_id_area.COUNT > 0 THEN
        FOR i IN 1..p_list_id_area.COUNT LOOP
          INSERT INTO CD_AREE_PRODOTTI_RICHIESTI(ID_AREA_NIELSEN, ID_PRODOTTI_RICHIESTI)
            VALUES(p_list_id_area(i),v_seq);
        END LOOP;
   END IF;

    -- IF p_id_posizione_rigore IS NOT NULL THEN
     --   PR_SALVA_MAGGIORAZIONE(v_seq, 1);
    -- END IF;
--

    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_CREA_PROD_MODULO_SEGUI_FILM: INSERT NON ESEGUITA '|| SQLERRM);
        ROLLBACK TO PR_CREA_PROD_RICH_MODULO;
     END PR_CREA_PROD_MODULO_SEGUI_FILM;



END PA_CD_PRODOTTO_RICHIESTO; 
/

