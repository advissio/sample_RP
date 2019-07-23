CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PROIEZIONE IS

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_PROIEZIONE_MULTI
--
-- DESCRIZIONE:  Genera le proiezioni per un periodo su una data sala
--
-- OPERAZIONI:
--   1) Cicla su tutti i giorni delle date indicate
--   2) Cicla sulle fasce orarie della tipologia "Fascia Proiezioni"
--   3) Se non esiste gia, crea una proiezione per ogni giorno - fascia - schermo
--   4) Se non esiste gia, crea un break per proiezione - tipo break
--
-- INPUT:
--      p_id_spettacolo             lo spettacolo da associare (facoltativo)
--      p_id_cinema                 il cinema su cui si intendono creare le proiezioni
--      p_id_sala                   la sala su cui si intendono creare le proiezioni (facoltativa)
--      p_data_inizio               data di inizio creazione
--      p_data_fine                 data di fine creazione
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita, ci sono problemi nella generazione delle proiezioni
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE:
--               Roberto Barbaro, Teoresi srl, Novembre 2009
--                  Modifiche rese necessarie dal cambiamento di logica delle proiezioni
--                  da proiezione puntuale (n al giorno rispetto al numero di proiezioni attese)
--                  a proiezione tipo (n per fascia di tipo "Fascia Proiezioni" al giorno)
--               Antonio Colucci, Teoresi srl, Settembre 2010
--                  modificato meccanismo di verifica esistenza proiezione,
--                  modificato meccanismo di recupero id_schermi sui quali generare le proiezioni
--               Simone Bottani, Altran, Settembre 2010
--                  Eliminata la possibilita di effettuare il recupero di proiezioni annullate
--               Tommaso D'Anna, Teoresi srl, 3 Maggio 2011
--                  Gestione della data validita' della sala
--               Antonio Colucci, Teoresi srl, 16 Maggio 2011
--                  Reinserimento recupero di una proiezione nel caso si tenti
--                  di creare una proiezione che e stata annullata in precedenza
--                  Per un corretto funzionamento e necessario che non esistano
--                  delle proiezioni VALIDE MA SENZA BREAK 
--              Mauro Viel Altran Italia Settembre 2011 (#MV01). Inserita la chiamata alla procedura 
--                         "pa_cd_prodotto_acquistato.pr_ripristina_sala" in modo da riattivare 
--                         i comunicati,relativi alla sala nelle date indicate, disattivati in fase di annullamento delle proiezioni.
--                         La procedura agira solo sui comunicati saltati (cioe quei comunicati che erano prenotati quando sono state annullate le
--                         proiezioni), eventuali comunicati annullati (cioe i comunicati che non erano prenotati  quando sono state annullate le 
--                         le proiezioni) non verranno ripristinati.
--              Antonio Colucci,    Teoresi srl, 29/11/2011
--                  Inserito ontrollo restrittivo sulla data inizio di repristino comunicati
--                  Ripristinero solo comunicati saltati a partire dal giorno corrente in poi   
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_PROIEZIONI_MULTI( p_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
                                         p_id_sala                   CD_SALA.ID_SALA%TYPE,
                                         p_data_inizio               DATE,
                                         p_data_fine                 DATE,
                                         p_esito                     OUT NUMBER)
IS
v_id_schermo        CD_SCHERMO.ID_SCHERMO%TYPE;
v_num_giorni        NUMBER;
v_data_proiezione   CD_PROIEZIONE.DATA_PROIEZIONE%TYPE;
v_esito             NUMBER;
v_esito_break       NUMBER;
v_id_proiezione     CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
v_data_validita     CD_SALA.DATA_FINE_VALIDITA%TYPE;
v_data_inizio_ripr  DATE;
BEGIN
    p_esito:=1;

    SAVEPOINT SP_PR_INSERISCI_PROIEZ_MULTI;

    v_num_giorni := p_data_fine - p_data_inizio;
        FOR x IN
        /*Elenco schermi sui quali creare le proiezioni*/ 
        (
            select 
                cd_schermo.id_schermo 
                from cd_sala,cd_schermo
            where 
                id_cinema = p_id_cinema
            and (p_id_sala is null or cd_sala.id_sala=p_id_sala)
            and cd_sala.id_sala = cd_schermo.id_sala
            and cd_sala.flg_annullato = 'N'
            and cd_schermo.flg_annullato = 'N'
            and ( ( cd_sala.DATA_FINE_VALIDITA IS NULL ) OR ( p_data_inizio <= cd_sala.DATA_FINE_VALIDITA  ) )
        ) LOOP
            FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni delle date del listino
                --DBMS_OUTPUT.PUT_LINE('start 3');
                v_data_proiezione   :=   p_data_inizio + k ;            
                
                SELECT DATA_FINE_VALIDITA
                INTO v_data_validita
                FROM CD_SALA, CD_SCHERMO
                WHERE ID_SCHERMO = x.ID_SCHERMO
                AND CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA;
                
                IF ( ( v_data_validita IS NULL ) OR ( v_data_proiezione <= v_data_validita ) ) THEN
                
                    FOR id_fascia IN (
                        select id_fascia from cd_fascia,cd_tipo_fascia
                        where  cd_tipo_fascia.DESC_TIPO = 'Fascia Proiezioni'
                        and	cd_tipo_fascia.id_tipo_fascia = cd_fascia.id_tipo_fascia
                    ) LOOP
                        v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(x.id_schermo,v_data_proiezione,id_fascia.id_fascia);
                        IF(v_id_proiezione=0)THEN
                        -- Crea una proiezione per ogni giorno - schermo
                            PA_CD_PROIEZIONE.PR_INSERISCI_PROIEZIONE(x.id_schermo, v_data_proiezione, id_fascia.id_fascia, v_esito);
                            SELECT CD_PROIEZIONE_SEQ.CURRVAL
                            INTO   v_id_proiezione
                            FROM   DUAL;
                            PA_CD_BREAK.PR_GENERA_BREAK_PROIEZIONE(v_id_proiezione, x.id_schermo,v_data_proiezione, v_esito_break);
                            --PA_CD_BREAK.PR_GENERA_BREAK_PRO_TEMP(v_id_proiezione, x.id_schermo,v_data_proiezione, v_esito_break);
                        ELSE
                            IF(v_id_proiezione<0)THEN
                                PA_CD_PROIEZIONE.PR_RECUPERA_PROIEZIONE(ABS(v_id_proiezione), v_esito);
                            
                            /*Se v_id_priezione >0 vuol dire che la proiezione esiste gia ed e valida
                              do per scontato che ad essa siano associati dei break validi*/
                            ELSE
                            /*vuol dire che la proiezione gia esiste.provo a lanciare cmq la genera break 
                            per coprire eventuali buchi di circuiti_break*/
                                PA_CD_BREAK.PR_GENERA_BREAK_PROIEZIONE(v_id_proiezione, x.id_schermo,v_data_proiezione, v_esito_break);
                                --PA_CD_BREAK.PR_GENERA_BREAK_PRO_TEMP(v_id_proiezione, x.id_schermo,v_data_proiezione, v_esito_break);
                            END IF;
                        END IF;
                        /*IF(v_id_proiezione<0)THEN*/
                            /*TEMPORANEO ABS(ID_PROIEZIONE)
                            SE ID_PROIEZIONE e NEGATIVA, VUOL DIRE CHE LA PROIEZIONE ESISTE GIa
                            MA e ANNULLATA,
                            QUINDI BISOGNA INVOCARE LA RECUPERA_PROIEZIONE*/
                            /*PRIMA DI GENERARE I BREAK RENDO VALIDE LE PROIEZIONI*/
                            /*
                            UPDATE  CD_PROIEZIONE
                            SET   FLG_ANNULLATO='N', NOTA=''
                            WHERE CD_PROIEZIONE.ID_PROIEZIONE = ABS(v_id_proiezione)
                            AND   CD_PROIEZIONE.FLG_ANNULLATO<>'N'
                            AND   TRUNC(CD_PROIEZIONE.DATA_PROIEZIONE) >= TRUNC(SYSDATE);
                            */
                        /*END IF;*/
                        /*LA CHIAMATA A GENERA BREAK DOVRa ESSERE FATTA SOLO SE NON ESISTE GIa UNA PROIEZIONE*/
                    END LOOP;
                    
                END IF;                
            END LOOP k;
        END LOOP x;
        --#MV01 Inizio
        --v_esito in caso di errore puo valere -1 o -11
        --v_esito_break in caso di errore vale -1
        --Ripristino i comunicati relativi alla sala in esame per le date in esame solo se non ci sono errori ovvero se 
        --i due esiti restituiscono valori positivi. Effettuo un nvl sui valori di ritorno delle procedure perche nel caso in cui 
        --solo una delle due e invocata l'altra restituira il valore null nell'esito.
        if nvl(v_esito,1) > 0 and nvl(v_esito_break,1) > 0 then
            if(p_data_inizio > trunc(sysdate))then
                v_data_inizio_ripr := p_data_inizio;
            else
               v_data_inizio_ripr := trunc(sysdate);
            end if;  
            pa_cd_prodotto_acquistato.pr_ripristina_sala(p_id_sala ,v_data_inizio_ripr,p_data_fine ,null); 
        end if;
       --#MV01 Fine        
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_INSERISCI_PROIEZIONI_MULTI: Errore durante la composizione, verificare la coerenza dei parametri, errore: '||SQLERRM);
        ROLLBACK TO SP_PR_INSERISCI_PROIEZ_MULTI;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_PROIEZIONE
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo proiezione nel sistema
--
-- OPERAZIONI:
--     1) Controlla se si vuole procedere con inserimento manuale od tramite sequence dell'id_proiezione
--   2) Nel caso di inserimento manuale controlla che non esistano altri proiezioni con lo stesso id
--   3) Memorizza la proiezione (CD_PROIEZIONE)
--
--  INPUT: parametri di inserimento di una nuova proiezione
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -1  Inserimento non eseguito: esiste gia una proiezione con questo id
--   -2  Inserimento non eseguito: l'id proiezione e NULL
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_PROIEZIONE( p_id_schermo                CD_PROIEZIONE.ID_SCHERMO%TYPE,
                                   p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                   p_id_fascia                 CD_PROIEZIONE.ID_FASCIA%TYPE,
                                   p_esito                     OUT NUMBER)
IS

BEGIN -- PR_INSERISCI_PROIEZIONE
--

p_esito     := 1;

     --
          SAVEPOINT ann_ins;
      --

       -- EFFETTUO L'INSERIMENTO
       INSERT INTO CD_PROIEZIONE
         (ID_SCHERMO,
          DATA_PROIEZIONE,
          ID_FASCIA,
          UTEMOD,
          DATAMOD
         )
       VALUES
         (p_id_schermo,
          p_data_proiezione,
          p_id_fascia,
          user,
          FU_DATA_ORA
          );
       --

--

  EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_INSERISCI_PROIEZIONE: Insert non eseguita, verificare la coerenza dei parametri: '||sqlerrm);
        ROLLBACK TO ann_ins;

END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_PROIEZIONE
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un proiezione dal sistema
--
-- OPERAZIONI:
--   1) Elimina la proiezione
--
-- INPUT:
--      p_id_proiezione     id della proiezione
--
-- OUTPUT: esito:
--    n  numero di record eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Settembre 2009
--
--  MODIFICHE:   Antonio Colucci, Teoresi srl, Settembre 2010
--                  Cambiate query per eliminazioni in cascata e aggiunta anche 
--                  eliminazione delle possibili associazioni con spettacoli nella tavola cd_proiezioni_spett
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_PROIEZIONE(  p_id_proiezione        IN CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                  p_esito                OUT NUMBER)
IS

--
BEGIN -- PR_ELIMINA_PROIEZIONE
--

p_esito     := 1;

    SAVEPOINT SP_PR_ELIMINA_PROIEZIONE;

    --elimino i break di vendita
    delete from cd_break_vendita where id_break_vendita 
    in (select id_break_vendita 
        from  cd_break_vendita,
          cd_circuito_break,
          cd_break,
          cd_proiezione
    where cd_proiezione.id_proiezione = p_id_proiezione
    AND   CD_PROIEZIONE.DATA_PROIEZIONE > SYSDATE
    and   cd_break.id_proiezione = cd_proiezione.id_proiezione
    and   cd_circuito_break.id_break = cd_break.id_break
    and   cd_break_vendita.id_circuito_break = cd_circuito_break.id_circuito_break);
    --DBMS_OUTPUT.PUT_LINE('in PR_ELIMINA_PROIEZIONE 2 id '||p_id_proiezione);
    p_esito := p_esito + SQL%ROWCOUNT;
    --elimino i circuiti break
    DELETE from cd_circuito_break where id_circuito_break
    in (select id_circuito_break from  cd_circuito_break,
                 cd_break,
                 cd_proiezione
            where cd_proiezione.id_proiezione = p_id_proiezione
            AND   CD_PROIEZIONE.DATA_PROIEZIONE > SYSDATE
            and   cd_break.id_proiezione = cd_proiezione.id_proiezione
            and   cd_circuito_break.id_break = cd_break.id_break);

    --DBMS_OUTPUT.PUT_LINE('in PR_ELIMINA_PROIEZIONE 3 id '||p_id_proiezione);
    p_esito := p_esito + SQL%ROWCOUNT;
    --elimino i break
    DELETE from  cd_break where id_break 
    in ( select id_break from
                cd_break,
                cd_proiezione
            where cd_proiezione.id_proiezione = p_id_proiezione
            AND   CD_PROIEZIONE.DATA_PROIEZIONE > SYSDATE
            and   cd_break.id_proiezione = cd_proiezione.id_proiezione);

    --DBMS_OUTPUT.PUT_LINE('in PR_ELIMINA_PROIEZIONE 4 id '||p_id_proiezione);
    p_esito := p_esito + SQL%ROWCOUNT;
    --elimino possibili associazioni con spettacoli
    DELETE FROM CD_PROIEZIONE_SPETT WHERE ID_PROIEZIONE = P_ID_PROIEZIONE;
    p_esito := p_esito + SQL%ROWCOUNT;
    --elimino le proiezioni valide
    DELETE FROM CD_PROIEZIONE
    WHERE  ID_PROIEZIONE = p_id_proiezione
	AND    CD_PROIEZIONE.DATA_PROIEZIONE > SYSDATE;

    --DBMS_OUTPUT.PUT_LINE('in PR_ELIMINA_PROIEZIONE 5 id '||p_id_proiezione);
    p_esito := p_esito + SQL%ROWCOUNT;

  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_ELIMINA_PROIEZIONE: Delete non eseguita, verificare la coerenza dei parametri id '||p_id_proiezione||' '||sqlerrm);
        ROLLBACK TO SP_PR_ELIMINA_PROIEZIONE;
  END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESISTE_PROIEZIONE
-- DESCRIZIONE:  la funzione controlla l'esistenza una proiezione nel sistema
--
-- INPUT:
--      p_id_fascia         id della fascia oraria
--      p_id_schermo        id dello schermo
--      p_data_proiezione   data della proiezione
--
-- OUTPUT: number - numero di proiezioni esistenti secondo i parametri specificati
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE  Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESISTE_PROIEZIONE(p_id_schermo                CD_PROIEZIONE.ID_SCHERMO%TYPE,
                              p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                              p_id_fascia                 CD_FASCIA.ID_FASCIA%TYPE
                              ) RETURN INTEGER
IS
    v_id_proiezione     INTEGER:=0;
    v_flg               CD_PROIEZIONE.FLG_ANNULLATO%TYPE;
BEGIN
    SELECT   COUNT(*)
    INTO     v_id_proiezione
    FROM     CD_PROIEZIONE
    WHERE    (ID_FASCIA       =   p_id_fascia OR p_id_fascia IS NULL)
    AND      ID_SCHERMO      =   p_id_schermo
    AND      DATA_PROIEZIONE =   p_data_proiezione;
    IF(v_id_proiezione>0)THEN
        SELECT   CD_PROIEZIONE.ID_PROIEZIONE, CD_PROIEZIONE.FLG_ANNULLATO
        INTO     v_id_proiezione, v_flg
        FROM     CD_PROIEZIONE
        WHERE    (ID_FASCIA      =   p_id_fascia OR p_id_fascia IS NULL)
        AND      ID_SCHERMO      =   p_id_schermo
        AND      DATA_PROIEZIONE =   p_data_proiezione
        /*AAAAAAAA*/
        and rownum=1
        order by id_proiezione;
        /*AAAAAAAA*/
        IF(v_flg='S')THEN
            v_id_proiezione:=-v_id_proiezione;
        END IF;
    END IF;
    RETURN v_id_proiezione;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'FU_ESISTE_PROIEZIONE: si e'' verificato un errore inatteso '||SQLERRM);
        return 0;
END FU_ESISTE_PROIEZIONE;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESISTE_PROIEZIONE
-- DESCRIZIONE:  la funzione controlla l'esistenza una proiezione nel sistema senza specificare la fascia
--
-- INPUT:
--      p_id_schermo        id dello schermo
--      p_data_proiezione   data della proiezione
--
-- OUTPUT: number - numero di proiezioni esistenti secondo i parametri specificati
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Novembre 2009
--
-- MODIFICHE  Francesco Abbundo, Teoresi srl, Novembre 2009
-- --------------------------------------------------------------------------------------------
/*
FUNCTION FU_ESISTE_PROIEZIONE(p_id_schermo                CD_PROIEZIONE.ID_SCHERMO%TYPE,
                              p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE
                              ) RETURN INTEGER
IS
    v_id_proiezione     INTEGER:=0;
    v_flg               CD_PROIEZIONE.FLG_ANNULLATO%TYPE;
BEGIN
    SELECT   COUNT(*)
    INTO     v_id_proiezione
    FROM     CD_PROIEZIONE
    WHERE    ID_SCHERMO      =   p_id_schermo
    AND      DATA_PROIEZIONE =   p_data_proiezione;
    RETURN v_id_proiezione;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'FU_ESISTE_PROIEZIONE: si e'' verificato un errore inatteso '||SQLERRM);
        return 0;
END FU_ESISTE_PROIEZIONE;
*/
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_PROIEZIONE_VENDUTA
-- DESCRIZIONE:  la funzione controlla l'esistenza una proiezione venduta nel sistema
--
-- INPUT:
--      p_id_proiezione     id della proiezione
--
-- OUTPUT: number - numero di proiezioni vendute
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_PROIEZIONE_VENDUTA(p_id_proiezione             CD_PROIEZIONE.ID_PROIEZIONE%TYPE
                               ) RETURN INTEGER
IS

v_count_proiezioni     INTEGER:=0;

BEGIN

    SELECT  COUNT(1)
    INTO    v_count_proiezioni
    FROM    CD_COMUNICATO
    WHERE   ID_BREAK_VENDITA IN
                (SELECT ID_BREAK_VENDITA
                 FROM   CD_BREAK_VENDITA
                 WHERE  ID_CIRCUITO_BREAK IN
                             (SELECT    ID_CIRCUITO_BREAK
                              FROM      CD_CIRCUITO_BREAK
                              WHERE     ID_BREAK IN
                                       (SELECT     ID_BREAK
                                        FROM       CD_BREAK
                                        WHERE      ID_PROIEZIONE=p_id_proiezione)));


    RETURN v_count_proiezioni;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'FU_PROIEZIONE_VENDUTA: si e'' verificato un errore inatteso '||SQLERRM);
        return 0;
END FU_PROIEZIONE_VENDUTA;


-----------------------------------------------------------------------------------------------------
-- Procedura PR_GENERA_PROIEZIONI
--
-- DESCRIZIONE:  Genera le proiezioni per un periodo su tutti gli schermi del sistema
--
-- OPERAZIONI:
--   1) Scorre l'insieme degli schermi da associare al listino
--   2) Associa gli schermi al listino tramite il circuito
--   3) Cicla su tutti i giorni delle date del listino
--   4) Cicla su tutte le fasce orarie di tipo "Fascia Proiezioni"
--   5) Se non esiste gia, crea una proiezione per ogni giorno - fascia - schermo
--   6) Se non esiste gia, crea un break per proiezione - tipo break
--   7) Associa i break al listino tramite il circuito
--   nel caso in cui il listino schermo era preesistente, viene semplicemente recuperato
--
-- INPUT:
--      p_data_inizio       data di inizio
--      p_data_fine         data di fine
--
-- OUTPUT: esito:
--    1  Operazione andata a buon fine
--   -1  Operazione non eseguita, ci sono problemi nella generazione delle proiezioni
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE
--                  Modifiche rese necessarie dal cambiamento di logica delle proiezioni
--                  da proiezione puntuale (n al giorno rispetto al numero di proiezioni attese)
--                  a proiezione tipo (n per fascia di tipo "Fascia Proiezioni" al giorno)
--               Simone Bottani, Altran, Settembre 2010
--                  Eliminata la possibilita di effettuare il recupero di proiezioni annullate
--               Tommaso D'Anna, Teoresi srl, 3 Maggio 2011
--                  Gestione della data validita' della sala
--               Antonio Colucci, Teoresi srl, 16 Maggio 2011
--                  Reinserimento recupero di una proiezione nel caso si tenti
--                  di creare una proiezione che e stata annullata in precedenza
--                  Per un corretto funzionamento e necessario che non esistano
--                  delle proiezioni VALIDE MA SENZA BREAK 
-------------------------------------------------------------------------------------------------
PROCEDURE PR_GENERA_PROIEZIONI   ( p_data_inizio               DATE,
                                   p_data_fine                 DATE,
                                   p_esito                     OUT NUMBER)
IS
    v_num_giorni         NUMBER;
    v_data_proiezione    CD_PROIEZIONE.DATA_PROIEZIONE%TYPE;
    v_esito              NUMBER;
    v_esito_break        NUMBER;
    v_id_proiezione      CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
    v_esiste_gia         INTEGER:=0;
    v_data_validita     CD_SALA.DATA_FINE_VALIDITA%TYPE;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_GENERA_PROIEZIONI;

    v_num_giorni := p_data_fine - p_data_inizio;
    --DBMS_OUTPUT.PUT_LINE('num giorni: '||v_num_giorni);
    FOR myId IN 
        (
            SELECT 
                 CD_SCHERMO.ID_SCHERMO 
            FROM CD_SCHERMO,
                 cd_sala 
            WHERE 
                cd_schermo.id_sala = cd_sala.id_sala 
            AND CD_SCHERMO.FLG_ANNULLATO = 'N'
            and cd_sala.flg_annullato = 'N'
            and ( ( cd_sala.DATA_FINE_VALIDITA IS NULL ) OR ( p_data_inizio <= cd_sala.DATA_FINE_VALIDITA  ) )
        ) LOOP    -- cicla sull'insieme degli schermi da comporre
            FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni delle date del listino
            
            v_data_proiezione   :=   p_data_inizio + k ;
        
            SELECT DATA_FINE_VALIDITA
            INTO v_data_validita
            FROM CD_SALA, CD_SCHERMO
            WHERE ID_SCHERMO = myId.ID_SCHERMO
            AND CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA;
            
            IF ( ( v_data_validita IS NULL ) OR ( v_data_proiezione <= v_data_validita ) ) THEN        
        
                FOR id_fascia IN   (SELECT  ID_FASCIA
                                    FROM    CD_FASCIA
                                    WHERE   ID_TIPO_FASCIA IN
                                        (SELECT ID_TIPO_FASCIA
                                         FROM   CD_TIPO_FASCIA
                                         WHERE  DESC_TIPO = 'Fascia Proiezioni')) LOOP
                    v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(myId.ID_SCHERMO,v_data_proiezione,id_fascia.id_fascia);
                    IF(v_id_proiezione=0)THEN
                        -- Crea una proiezione per ogni giorno - schermo
                            PA_CD_PROIEZIONE.PR_INSERISCI_PROIEZIONE(myId.id_schermo, v_data_proiezione, id_fascia.id_fascia, v_esito);
                            SELECT CD_PROIEZIONE_SEQ.CURRVAL
                            INTO   v_id_proiezione
                            FROM   DUAL;
                            PA_CD_BREAK.PR_GENERA_BREAK_PROIEZIONE(v_id_proiezione, myId.id_schermo,v_data_proiezione, v_esito_break);
                            --PA_CD_BREAK.PR_GENERA_BREAK_PRO_TEMP(v_id_proiezione, myId.id_schermo,v_data_proiezione, v_esito_break);
                        ELSE
                            IF(v_id_proiezione<0)THEN
                                PA_CD_PROIEZIONE.PR_RECUPERA_PROIEZIONE(ABS(v_id_proiezione), v_esito);
                            ELSE
                            /*vuol dire che la proiezione gia esiste.provo a lanciare cmq la genera break 
                            per coprire eventuali buchi di circuiti_break*/
                                PA_CD_BREAK.PR_GENERA_BREAK_PROIEZIONE(v_id_proiezione, myId.id_schermo,v_data_proiezione, v_esito_break);
                                --PA_CD_BREAK.PR_GENERA_BREAK_PRO_TEMP(v_id_proiezione, myId.id_schermo,v_data_proiezione, v_esito_break);
                            END IF;
                            /*Se v_id_priezione >0 vuol dire che la proiezione esiste gia ed e valida
                              do per scontato che ad essa siano associati dei break validi*/
                        END IF;
                        /*IF(v_id_proiezione<0)THEN*/
                            /*TEMPORANEO ABS(ID_PROIEZIONE)
                            SE ID_PROIEZIONE e NEGATIVA, VUOL DIRE CHE LA PROIEZIONE ESISTE GIa
                            MA e ANNULLATA,
                            QUINDI BISOGNA INVOCARE LA RECUPERA_PROIEZIONE*/
                            /*PRIMA DI GENERARE I BREAK RENDO VALIDE LE PROIEZIONI*/
                            /*
                            UPDATE  CD_PROIEZIONE
                            SET   FLG_ANNULLATO='N', NOTA=''
                            WHERE CD_PROIEZIONE.ID_PROIEZIONE = ABS(v_id_proiezione)
                            AND   CD_PROIEZIONE.FLG_ANNULLATO<>'N'
                            AND   TRUNC(CD_PROIEZIONE.DATA_PROIEZIONE) >= TRUNC(SYSDATE);
                            */
                        /*END IF;*/
                        /*LA CHIAMATA A GENERA BREAK DOVRa ESSERE FATTA SOLO SE NON ESISTE GIa UNA PROIEZIONE*/
                END LOOP;
                
            END IF;
        END LOOP k;
    END LOOP;
    --DBMS_OUTPUT.PUT_LINE('start end');
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.PUT_LINE('Procedura PR_COMPONI_LISTINO_SCHERMO :' ||sqlerrm);
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_GENERA_PROIEZIONI: Errore durante la composizione, verificare la coerenza dei parametri, errore: '||SQLERRM);
        ROLLBACK TO SP_PR_GENERA_PROIEZIONI;
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_PROIEZIONE
-- --------------------------------------------------------------------------------------------
-- INPUT:  Criteri di ricerca delle proiezioni
-- OUTPUT: Restituisce le proiezioni che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE     Antonio Colucci, Teoresi srl, Settembre 2010
--                  Eliminati parametri fascia e spettacolo come criteri di ricerca
--                  Inserito codice_responsabilita tra i criteri di ricerca
--                      null==>Tutti
--                      -10 ==>Solo Disponibili
--                      id  ==> id
--                  modificato ref cursor ritornato dalla funzione
--                  la funzione di ricerca ritorna non + un elenco di id_proiezioni 
--                      ma un elenco di coppie di id_proiezioni
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PROIEZIONE(p_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
                             p_id_sala                   CD_SALA.ID_SALA%TYPE,
                             p_data_inizio               DATE,
                             p_data_fine                 DATE,
                             p_id_codice_resp            cd_codice_resp.ID_CODICE_RESP%TYPE,
                             p_flg_annullato             CD_PROIEZIONE.FLG_ANNULLATO%TYPE)
                             RETURN C_PROIEZIONE
IS

v_return_value C_PROIEZIONE;

BEGIN
        PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(p_data_inizio, p_data_fine);
        OPEN v_return_value
        FOR
            SELECT  distinct vencd.fu_cd_string_agg(CD_PROIEZIONE.ID_PROIEZIONE) OVER (PARTITION BY CD_PROIEZIONE.DATA_PROIEZIONE,CD_CINEMA.ID_CINEMA,CD_SALA.ID_SALA,NOTA) id_proiezioni,
                    CD_PROIEZIONE.DATA_PROIEZIONE, 
                    CD_CINEMA.ID_CINEMA, CD_CINEMA.NOME_CINEMA,CD_COMUNE.COMUNE, 
                    CD_SALA.ID_SALA, CD_SALA.NOME_SALA,
                    VI_CD_SALE_CAUSALI_PREV.id_codice_resp,
                    cd_codice_resp.desc_codice,
                    cd_proiezione.flg_annullato,NOTA
            FROM    CD_PROIEZIONE, CD_CINEMA, CD_SALA,
                    CD_SCHERMO,
                    CD_COMUNE,cd_codice_resp,
                    VI_CD_SALE_CAUSALI_PREV
            WHERE   CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
            and     CD_CINEMA.ID_COMUNE = CD_COMUNE.ID_COMUNE
            AND     CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
            AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
            AND     (p_id_cinema IS NULL OR CD_CINEMA.ID_CINEMA = p_id_cinema)
            AND     (p_id_sala IS NULL OR CD_SALA.ID_SALA = p_id_sala)
            AND     (CD_PROIEZIONE.DATA_PROIEZIONE between p_data_inizio and p_data_fine)
            AND     (p_flg_annullato = 'T' or CD_PROIEZIONE.FLG_ANNULLATO=p_flg_annullato)
            and     (p_id_codice_resp is null or VI_CD_SALE_CAUSALI_PREV.id_codice_resp = p_id_codice_resp)
            and     CD_SALA.ID_SALA = VI_CD_SALE_CAUSALI_PREV.id_sala
            and     CD_PROIEZIONE.DATA_PROIEZIONE = VI_CD_SALE_CAUSALI_PREV.DATA_RIF 
            and     VI_CD_SALE_CAUSALI_PREV.id_codice_resp = cd_codice_resp.id_codice_resp(+)
            order by CD_PROIEZIONE.DATA_PROIEZIONE,CD_CINEMA.NOME_CINEMA,CD_COMUNE.COMUNE,CD_SALA.NOME_SALA;

RETURN v_return_value;

EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'PROCEDURA PR_CERCA_PROIEZIONE: Ricerca non eseguita, verificare la coerenza dei parametri '||sqlerrm);

END FU_CERCA_PROIEZIONE;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ASSOCIA_FILM
--
-- DESCRIZIONE:  Associa uno spettacolo alle proiezioni in un dato periodo
--
-- OPERAZIONI:
--   1) Aggiorna lo spettacolo per il periodo e le sale indicate
--
-- INPUT:
--      p_id_sala           id della sala
--      p_id_spettacolo     id dello spettacolo
--      p_data_inizio       data inizio
--      p_data_fine         data fine
--      p_id_fascia         fascia oraria
--
-- OUTPUT: esito:
--    n  numero di record aggiornati
--   -1  Associazione non eseguita: i parametri per la Update non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
/*
PROCEDURE PR_ASSOCIA_FILM ( p_id_sala                   CD_SALA.ID_SALA%TYPE,
                            p_id_spettacolo             CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                            p_data_inizio               DATE,
                            p_data_fine                 DATE,
                            p_id_fascia                 CD_FASCIA.ID_FASCIA%TYPE,
                            p_esito                     OUT NUMBER)
IS

--
BEGIN -- PR_ASSOCIA_FILM
--

p_esito     := 1;


          SAVEPOINT ann_associa_film;

        UPDATE  CD_PROIEZIONE
        SET     ID_SPETTACOLO = p_id_spettacolo
        WHERE   DATA_PROIEZIONE >= p_data_inizio
        AND     DATA_PROIEZIONE <= p_data_fine
        AND     (p_id_fascia IS NULL OR CD_PROIEZIONE.ID_FASCIA = p_id_fascia)
        AND     ID_SCHERMO IN
                (SELECT ID_SCHERMO
                 FROM CD_SCHERMO
                 WHERE ID_SALA = p_id_sala);

        p_esito := SQL%ROWCOUNT;


  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Associazione non eseguita: i parametri per la Update non sono coerenti');
        ROLLBACK TO ann_associa_film;
  END;
*/
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_PROIEZIONE
--
-- DESCRIZIONE:  Esegue la cancellazione logica di una proiezione,
--                  dei relativi circuiti, degli ambiti vendita e dei comunicati
--
-- OPERAZIONI:
--   1) Cancella logicamente proiezioni, circuiti_ambiti
--      ambiti_vendita, comunicati
-- INPUT:  Id della proiezione
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
--  MODIFICHE:Antonio Colucci, Teoresi srl, 20/06/2011
--            Tentativo di ottimizzazione esecuzione annullamento sale
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_PROIEZIONE(p_id_proiezione 	IN CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                p_nota              IN CD_PROIEZIONE.NOTA%TYPE,
						        p_esito		        OUT NUMBER,
                                p_piani_errati        OUT VARCHAR2)
IS
    v_esito     NUMBER:=0;
BEGIN
    p_esito     := 0;
    FOR TEMP IN(
            select id_comunicato 
            from cd_comunicato,cd_break
            where 
                cd_break.id_proiezione = p_id_proiezione
            and cd_comunicato.id_break = cd_break.id_break
            and cd_comunicato.flg_annullato = 'N'
            and cd_comunicato.flg_sospeso = 'N'
            and cd_comunicato.cod_disattivazione is null
    ) LOOP        
        PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(TEMP.ID_COMUNICATO, 'PAL',v_esito,p_piani_errati);
        IF((v_esito=5) OR (v_esito=15) OR (v_esito=25)) THEN
            p_esito := p_esito + 1;
        END IF;
    END LOOP;
--    
    update CD_BREAK_VENDITA
    SET FLG_ANNULLATO='S'
    WHERE CD_BREAK_VENDITA.ID_CIRCUITO_BREAK IN
            (
                select id_circuito_break
                from cd_circuito_break,cd_break
                where cd_break.id_proiezione = p_id_proiezione
                and   cd_break.id_break = cd_circuito_break.id_break
                and   cd_circuito_break.flg_annullato = 'N'
            )
    AND CD_BREAK_VENDITA.FLG_ANNULLATO = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti break
    UPDATE  CD_CIRCUITO_BREAK
    SET FLG_ANNULLATO='S'
    WHERE CD_CIRCUITO_BREAK.ID_BREAK IN
        (
           SELECT CD_BREAK.ID_BREAK
           FROM  CD_BREAK
           WHERE CD_BREAK.ID_PROIEZIONE  = p_id_proiezione
        )
     AND CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
    --seleziono i break
    UPDATE  CD_BREAK
    SET FLG_ANNULLATO='S'
    WHERE  CD_BREAK.ID_PROIEZIONE = p_id_proiezione
    AND FLG_ANNULLATO='N';
    p_esito := p_esito + SQL%ROWCOUNT;
        --seleziono le proiezioni valide
    UPDATE  CD_PROIEZIONE
    SET     FLG_ANNULLATO='S', NOTA=p_nota
    WHERE   CD_PROIEZIONE.ID_PROIEZIONE = p_id_proiezione
    AND     CD_PROIEZIONE.FLG_ANNULLATO = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
    /*TEMPORANEAMENTE INSERISCO COMMIT*/
    COMMIT;
    /*TEMPORANEAMENTE INSERISCO COMMIT*/
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_ANNULLA_PROIEZIONE: Eliminazione logica non eseguita: si e'' verificato un errore inatteso'|| sqlerrm);
        p_esito := -1;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_SALA_PRO
--
-- DESCRIZIONE:  Esegue la cancellazione logica di una proiezione,
--                  dei relativi circuiti, degli ambiti vendita e dei comunicati
--
-- OPERAZIONI:
--   1) Cancella logicamente proiezioni, circuiti_ambiti
--      ambiti_vendita, comunicati
-- INPUT:  Id della proiezione
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
--  MODIFICHE:Antonio Colucci, Teoresi srl, 20/06/2011
--            Tentativo di ottimizzazione esecuzione annullamento sale
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_SALA_PRO(p_id_cinema         IN CD_CINEMA.ID_CINEMA%TYPE,
                              p_id_sala           IN CD_SALA.id_sala%type,
                              p_data_inizio       in date,
                              p_data_fine         in date,
                              p_nota              IN CD_PROIEZIONE.NOTA%TYPE,
						      p_esito		      OUT NUMBER
                              )
IS
    v_esito     NUMBER:=0;
BEGIN
    p_esito     := 0;
    
--    
    update
    cd_break_vendita
    set flg_annullato = 'S'
    where  id_circuito_break in
    (
       select  id_circuito_break 
       from    cd_circuito_break,
               cd_break,
               cd_proiezione,
               cd_schermo,
               cd_sala,
               cd_cinema
       where
               (p_id_sala is null or cd_sala.id_sala = p_id_sala)
       and     (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
       and     cd_sala.id_cinema = cd_cinema.id_cinema
       and     cd_sala.id_sala = cd_schermo.id_sala
       and     cd_schermo.id_schermo = cd_proiezione.id_schermo
       and     cd_proiezione.data_proiezione between p_data_inizio and p_data_fine
       and     cd_proiezione.flg_annullato = 'N'
       and     cd_sala.flg_arena = 'N'
       and     cd_sala.flg_visibile = 'S'
       and     cd_cinema.flg_virtuale = 'N'
       and     cd_break.id_proiezione = cd_proiezione.id_proiezione
       and     cd_break.id_break = cd_circuito_break.id_break
       and     cd_break.flg_annullato = 'N'
       and     cd_circuito_break.flg_annullato = 'N'
    )
    and flg_annullato = 'N';
--    
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti break
    update
    cd_circuito_break
    set flg_annullato = 'S'
    where id_break in
    (
       select  id_break 
       from    cd_break,
               cd_proiezione,
               cd_schermo,
               cd_sala,
               cd_cinema
       where
               (p_id_sala is null or cd_sala.id_sala = p_id_sala)
       and     (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
       and     cd_sala.id_cinema = cd_cinema.id_cinema
       and     cd_sala.id_sala = cd_schermo.id_sala
       and     cd_schermo.id_schermo = cd_proiezione.id_schermo
       and     cd_proiezione.data_proiezione between p_data_inizio and p_data_fine
       and     cd_proiezione.flg_annullato = 'N'
       and     cd_sala.flg_arena = 'N'
       and     cd_sala.flg_visibile = 'S'
       and     cd_cinema.flg_virtuale = 'N'
       and     cd_break.id_proiezione = cd_proiezione.id_proiezione
       and     cd_break.flg_annullato = 'N'
    )
    and cd_circuito_break.flg_annullato = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
    --seleziono i break
    update cd_break
    set flg_annullato = 'S'
    where  id_proiezione in 
    (
       select  id_proiezione 
       from    cd_proiezione,
               cd_schermo,
               cd_sala,
               cd_cinema
       where
               (p_id_sala is null or cd_sala.id_sala = p_id_sala)
       and     (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
       and     cd_sala.id_cinema = cd_cinema.id_cinema
       and     cd_sala.id_sala = cd_schermo.id_sala
       and     cd_schermo.id_schermo = cd_proiezione.id_schermo
       and     cd_proiezione.data_proiezione between p_data_inizio and p_data_fine
       and     cd_proiezione.flg_annullato = 'N'
       and     cd_sala.flg_arena = 'N'
       and     cd_sala.flg_visibile = 'S'
       and     cd_cinema.flg_virtuale = 'N'
    )
    and flg_annullato = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
        --seleziono le proiezioni valide
    update cd_proiezione
    set flg_annullato = 'S',
        nota = p_nota
    where id_proiezione in 
    (
       select  id_proiezione 
       from    cd_proiezione,
               cd_schermo,
               cd_sala,
               cd_cinema
       where
               (p_id_sala is null or cd_sala.id_sala = p_id_sala)
       and     (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
       and     cd_sala.id_cinema = cd_cinema.id_cinema
       and     cd_sala.id_sala = cd_schermo.id_sala
       and     cd_schermo.id_schermo = cd_proiezione.id_schermo
       and     cd_proiezione.data_proiezione between p_data_inizio and p_data_fine
       and     cd_proiezione.flg_annullato = 'N'
       and     cd_sala.flg_arena = 'N'
       and     cd_sala.flg_visibile = 'S'
       and     cd_cinema.flg_virtuale = 'N'
    )
    and flg_annullato = 'N';
    p_esito := p_esito + SQL%ROWCOUNT;
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_ANNULLA_SALA_PRO: Eliminazione logica non eseguita: si e'' verificato un errore inatteso'|| sqlerrm);
        p_esito := -1;
END;
--
--
--Procedura che permette di annullare la disponibgilita delle sale
--passando dai periodi e dai prodotti acquistati, anziche dalle singole proiezioni
-- e comunicati
--Antonio Colucci Teoresi srl, luglio 2011
--
PROCEDURE PR_ANNULLA_DISP_SALA( p_id_cinema         IN CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_sala           IN CD_SALA.id_sala%type,
                                p_data_inizio       in date,
                                p_data_fine         in date,
                                p_nota              varchar2,
                                p_esito             out number)
IS
    v_esito     NUMBER:=0;
    v_count     number:=-1;
BEGIN
     p_esito     := 0;
     /*
        Annullo le sale andando a valutare i prodotti associati
      */
     for elenco in
     (
         select  distinct
                 cd_prodotto_acquistato.id_prodotto_acquistato,
                 cd_sala.id_sala 
         from 
                 cd_comunicato,
                 cd_prodotto_acquistato,
                 cd_sala,
                 cd_cinema
         where   (p_id_sala is null or cd_sala.id_sala = p_id_sala)
         and     (p_id_cinema is null or cd_cinema.id_cinema = p_id_cinema)
         and     cd_sala.id_cinema = cd_cinema.id_cinema
         and     cd_sala.id_sala = cd_comunicato.id_sala
         and     cd_sala.flg_arena = 'N'
         and     cd_sala.flg_visibile = 'S'
         and     cd_cinema.flg_virtuale = 'N'
         and     cd_comunicato.data_erogazione_prev between p_data_inizio and p_data_fine
         and     cd_comunicato.flg_annullato = 'N'
         and     cd_comunicato.flg_sospeso = 'N'
         and     cd_comunicato.cod_disattivazione is null
         and     cd_comunicato.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
         and     cd_prodotto_acquistato.flg_annullato = 'N'
         and     cd_prodotto_acquistato.flg_sospeso = 'N'
    )loop
         /*select count(1)
         into v_count
         from cd_comunicato com
         where com.id_prodotto_acquistato = elenco.id_prodotto_acquistato
         and   com.id_sala = elenco.id_sala
         and   com.data_erogazione_prev < trunc(sysdate)
         and   com.flg_annullato = 'N'
         and   com.flg_sospeso = 'N'
         and   com.cod_disattivazione is null;
         if v_count =0 then*/
            pa_cd_prodotto_acquistato.PR_ANNULLA_SALA(elenco.id_prodotto_acquistato,p_data_inizio,p_data_fine,elenco.id_sala,'PAL',v_esito);
         --end if;   
    end loop;
    /*
        Annullo la struttura a palinsesto sulla quale si reggevano i comunicati
        presenti nelle sale
    */     
    PR_ANNULLA_SALA_PRO(p_id_cinema,p_id_sala,p_data_inizio,p_data_fine,p_nota,p_esito);
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_ANNULLA_DISP_SALA: si e'' verificato un errore inatteso: '|| sqlerrm);
        p_esito := -1;
END;                                
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_PROIEZIONE
--
-- DESCRIZIONE:  Esegue il recupero dalla cancellazione logica di una proiezione,
--                  dei relativi circuiti, degli ambiti vendita e dei comunicati
--
-- OPERAZIONI:
--   1) Recupera proiezioni, circuiti_ambiti, ambiti_vendita, comunicati
--      cancellate logicamente
--
-- INPUT:  Id della proiezione
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
--  MODIFICHE:   Francesco Abbundo, Teoresi srl
--               Simone Bottani, Altran, Luglio 2010
--               Vengono recuperate anche le proiezioni del giorno in corso
--               Antonio Colucci, Teoresi srl, Settembre 2010
--                  Commentata chiamata a procedura di Recupera Comunicati da parte del palinsesto
--                  visto che operazioni di recupero proiezioni sul palinsesto non riattivano 
--                  eventuali comunicati annullati
--              Antonio Colucci, Teoresi srl, 21/07/2011
--                  Ottimizzazione procedura di recupero delle proiezioni
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_PROIEZIONE(p_id_proiezione     IN CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                 p_esito            OUT NUMBER)
IS
    v_esito     NUMBER:=0;
BEGIN
    p_esito     := 0;
    --SEZIONE SCHERMI E BREAK
    -- qui seleziono i comunicati
    /*#####A.C.##########*/
    /*
    FOR TEMP IN(SELECT CD_COMUNICATO.ID_COMUNICATO
                FROM  CD_COMUNICATO, CD_BREAK_VENDITA, CD_CIRCUITO_BREAK, CD_BREAK, CD_PROIEZIONE, CD_CIRCUITO_SCHERMO
                WHERE TRUNC(CD_PROIEZIONE.DATA_PROIEZIONE) >= TRUNC(SYSDATE)
                AND   CD_PROIEZIONE.ID_PROIEZIONE = p_id_proiezione
                AND   CD_CIRCUITO_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                AND   CD_CIRCUITO_SCHERMO.ID_CIRCUITO = CD_CIRCUITO_BREAK.ID_CIRCUITO
                AND   CD_CIRCUITO_SCHERMO.ID_LISTINO = CD_CIRCUITO_BREAK.ID_LISTINO
                AND   CD_CIRCUITO_SCHERMO.FLG_ANNULLATO = 'N'
				AND   CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
				AND   CD_BREAK.ID_BREAK = CD_CIRCUITO_BREAK.ID_BREAK
				AND   CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK = CD_BREAK_VENDITA.ID_CIRCUITO_BREAK
				AND   CD_CIRCUITO_BREAK.FLG_ANNULLATO<>'N'
				AND   CD_BREAK_VENDITA.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
                AND   CD_COMUNICATO.FLG_ANNULLATO<>'N') LOOP
        PA_CD_COMUNICATO.PR_RECUPERA_COMUNICATO(TEMP.ID_COMUNICATO, 'PAL',v_esito);
        IF((v_esito=5) OR (v_esito=15) OR (v_esito=25)) THEN
            p_esito := p_esito + 1;
        END IF;
    END LOOP;
    */
    /*#####A.C.##########*/
    --qui recupero i break di vendita
    UPDATE  CD_BREAK_VENDITA
    SET FLG_ANNULLATO='N'
    where id_circuito_break in
    (
        select id_circuito_break
        from cd_circuito_break,cd_break
        where cd_break.id_proiezione = p_id_proiezione
        and   cd_break.id_break = cd_circuito_break.id_break
    )
    and flg_annullato = 'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti break
    UPDATE  CD_CIRCUITO_BREAK
    SET FLG_ANNULLATO='N'
    where id_circuito_break in
    (
        select id_circuito_break
        from cd_circuito_break,cd_break
        where cd_break.id_proiezione = p_id_proiezione
        and   cd_break.id_break = cd_circuito_break.id_break
    )
    and flg_annullato = 'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --seleziono i break
    UPDATE  CD_BREAK
    SET FLG_ANNULLATO='N'
    WHERE  CD_BREAK.ID_PROIEZIONE = p_id_proiezione
    and flg_annullato = 'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --seleziono le proiezioni valide
    UPDATE  CD_PROIEZIONE
    SET FLG_ANNULLATO='N', NOTA=''
    WHERE CD_PROIEZIONE.ID_PROIEZIONE = p_id_proiezione
    AND CD_PROIEZIONE.FLG_ANNULLATO = 'S';
    p_esito := p_esito + SQL%ROWCOUNT;
 EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_RECUPERA_PROIEZIONE: Eliminazione logica non eseguita: si e'' verificato un errore inatteso');
        p_esito := -1;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_SPOSTA_PROIEZIONI
--
-- DESCRIZIONE:  Sposta le proiezioni di una sala da un periodo ad un altro
--
-- OPERAZIONI:
--   1) Controlla se esistono gia proiezioni nel periodo di destinazione
--   2) Crea nuove proiezioni per tutti i giorni di provenienza
--   3) Annulla le proiezioni di provenienza
--
-- INPUT:
--      p_id_sala           id della sala
--      p_data_inizio_da    data di inizio del periodo da spostare
--      p_data_fine_da      data di fine del periodo da spostare
--      p_data_inizio_a     data di inizio di destinazione
--      p_nota              note dell'utente
--
-- OUTPUT: esito:
--    n  Numero di proiezioni spostate
--   -1  Operazione non eseguita, ci sono problemi nello spostamento delle proiezioni
--   -11 Impossibile spostare poiche esistono gia delle proiezioni nel periodo di destinazione
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE
--
-------------------------------------------------------------------------------------------------
/*
PROCEDURE PR_SPOSTA_PROIEZIONI   (p_id_cinema                 CD_CINEMA.ID_CINEMA%TYPE,
                                  p_id_sala                   CD_SALA.ID_SALA%TYPE,
                                  p_data_inizio_da            DATE,
                                  p_data_fine_da              DATE,
                                  p_data_inizio_a             DATE,
                                  p_nota                      CD_PROIEZIONE.NOTA%TYPE,
                                  p_esito                     OUT NUMBER,
                                  p_piani_errati              OUT VARCHAR2)
IS
    v_num_giorni            NUMBER;
    v_id_schermo            CD_SCHERMO.ID_SCHERMO%TYPE;
    v_data_proiezione_da    DATE;
    v_data_proiezione_a     DATE;
    v_esito                 NUMBER;
    v_id_proiezione         CD_PROIEZIONE.ID_PROIEZIONE%TYPE;
    v_list_schermi      ID_SCHERMI_TYPE:=ID_SCHERMI_TYPE();
    i                   NUMBER;
CURSOR c_id_schermo IS
    SELECT  ID_SCHERMO
    FROM    CD_SCHERMO
    WHERE   ID_SALA IN
        (SELECT ID_SALA
         FROM   CD_SALA
         WHERE  ID_CINEMA=p_id_cinema);
BEGIN

    SAVEPOINT SP_PR_SPOSTA_PROIEZIONI;

    p_esito:=0;

    i:=1;

    IF(p_id_sala IS NOT NULL) THEN

        SELECT  ID_SCHERMO
        INTO    v_id_schermo
        FROM    CD_SCHERMO
        WHERE   CD_SCHERMO.ID_SALA = p_id_sala;

        v_list_schermi.extend;
        v_list_schermi(i) := v_id_schermo;

    ELSE

        FOR id_schermo IN c_id_schermo LOOP
            v_list_schermi.extend;
            v_list_schermi(i) := id_schermo.id_schermo;
            i:=i+1;
        END LOOP;

    END IF;

    v_num_giorni    :=  p_data_fine_da - p_data_inizio_da;

    FOR x IN 1..v_list_schermi.count LOOP
        FOR j IN 0..v_num_giorni LOOP  -- controllo se esiste gia una proiezione nel periodo di destinazione

            IF (FU_ESISTE_PROIEZIONE(v_list_schermi(x),p_data_inizio_a + j) != 0) THEN
               RAISE ESISTE_PROIEZIONE_EXCEPTION;
            END IF;

        END LOOP;
    END LOOP;

    FOR x IN 1..v_list_schermi.count LOOP
        FOR k IN 0..v_num_giorni LOOP   -- Cicla su tutti i giorni
            --DBMS_OUTPUT.PUT_LINE('start 3');
            v_data_proiezione_da   :=   p_data_inizio_da + k ;
            v_data_proiezione_a    :=   p_data_inizio_a + k ;
            v_id_proiezione := PA_CD_PROIEZIONE.FU_ESISTE_PROIEZIONE(v_list_schermi(x),v_data_proiezione_da);

            IF(v_id_proiezione > 0) THEN

                FOR     v_time_rec IN (
                SELECT  ID_PROIEZIONE, ID_SPETTACOLO, ID_FASCIA
                FROM    CD_PROIEZIONE
                WHERE   DATA_PROIEZIONE = v_data_proiezione_da
                AND     FLG_ANNULLATO<>'S'
                AND     ID_SCHERMO = v_list_schermi(x))

                LOOP

                    PA_CD_PROIEZIONE.PR_INSERISCI_PROIEZIONE(v_time_rec.ID_SPETTACOLO, v_list_schermi(x), v_data_proiezione_a, v_time_rec.ID_FASCIA, v_esito);
                    p_esito :=  p_esito+1;

                    --IF(FU_PROIEZIONE_VENDUTA(v_time_rec.ID_PROIEZIONE)>0) THEN

                        PR_ANNULLA_PROIEZIONE(v_time_rec.ID_PROIEZIONE, p_nota, v_esito,p_piani_errati);

                    --ELSE

                    --    PR_ELIMINA_PROIEZIONE(v_time_rec.ID_PROIEZIONE,v_esito);

                    --END IF;

                END LOOP;

            END IF;
        END LOOP k;
    END LOOP;

EXCEPTION
    WHEN ESISTE_PROIEZIONE_EXCEPTION THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20125, 'Procedura PR_SPOSTA_PROIEZIONI: Esistono proiezioni valide nel periodo di destinazione');
        ROLLBACK TO SP_PR_SPOSTA_PROIEZIONI;
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_SPOSTA_PROIEZIONI: Errore durante lo spostamento, verificare la coerenza dei parametri, errore: '||SQLERRM);
        ROLLBACK TO SP_PR_SPOSTA_PROIEZIONI;
END;
*/
END PA_CD_PROIEZIONE; 
/

