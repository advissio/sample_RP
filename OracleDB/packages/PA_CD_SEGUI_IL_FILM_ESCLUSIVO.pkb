CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SEGUI_IL_FILM_ESCLUSIVO AS

-------------------------------------------------------------------------------------------------
-- PROCEDURE FU_VERIFICA_DISPONIBILITA
--
-- DESCRIZIONE:  Funzione che permette di capire se la sala specifica e idonea
--               per l'inserimento di un nuovo comunicato in base a
--               disponibilita e/o incompatibilita di cliente
--
-- OPERAZIONI:
--   1)Verifico disponibilita in sala in termini di secondi
--   2)Verifico che il cliente in esame non sia gia 
--      presente nella sala per lo stesso giorno
--   3)Se il cliente e gia presente valuto se ci sono ancora sale disponibili
--      senza cliente, in caso copntrario forzo comunque inserimento 
--
-- INPUT:
--      id_prodotto_acquistato  identificativo del prodotto acquistato
--      id_sala                 identificativo della sala candidata all'associazione
--      giorno                  giorno in esame
--
-- OUTPUT: esito dell'operazione
--          1 - LA SALA E' DISPONIBILE ED IDONEA PER L'IMPOSTAZIONE
--          0 - LA SALA NON E' DISPONIBILE ED IDONEA PER L'IMPOSTAZIONE
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 16 Febbraio 2011
--
--  MODIFICHE: 
--              Tommaso D'Anna, Teoresi srl, 8 Giugno 2011
--                  - Inserita DISTINCT in SPETT_SALA_GIORNO per considerare anche i casi
--                  in cui il gestore inserisca due programmazioni identiche nello stesso giorno
--              Tommaso D'Anna, Teoresi srl, 23 Giugno 2011
--                  - Inserito il controllo sul contratto valido
-------------------------------------------------------------------------------------------------

 FUNCTION FU_VERIFICA_DISPONIBILITA( p_id_prodotto_acquistato   cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                      p_id_sala                  cd_sala.id_sala%type,
                                      p_giorno                   date,
                                      p_sale_non_idonee          varchar2
                                     ) RETURN NUMBER IS
 v_return               number := 1;
 v_disponibilita_sala   number;
 v_durata_com           number;
 v_id_cliente           varchar2(50);
 v_count_cliente        number;
 v_count_sale_cli       number := 0;
 v_count_sale_disp      number;
 begin
    --DBMS_OUTPUT.PUT_LINE('p_id_prodotto_acquistato'||p_id_prodotto_acquistato||'p_id_sala:'||p_id_sala||'p_giorno:'||p_giorno  );
    /*calcolo disponibilita*/
    v_disponibilita_sala := pa_cd_estrazione_prod_vendita.FU_AFFOLLAMENTO_SALA_STATO_NEW(p_giorno,p_giorno,p_id_sala);
    --v_disponibilita_sala := pa_cd_estrazione_prod_vendita.FU_AFFOLLAMENTO_SALA_STATO(p_giorno,p_giorno,p_id_sala,null,'PRE');
    /*recupero durata comunmicato candidato*/
    select  cd_coeff_cinema.durata
    into    v_durata_com
    from    cd_prodotto_acquistato,
            cd_formato_acquistabile,
            cd_coeff_cinema
    where   cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
    and     cd_prodotto_acquistato.id_formato = cd_formato_acquistabile.id_formato
    and     cd_formato_acquistabile.id_coeff = cd_coeff_cinema.id_coeff;
    if(v_disponibilita_sala>=v_durata_com)then
        /*verifico compatibilita cliente*/
        select  id_cliente  
        into    v_id_cliente
        from    cd_pianificazione,
                cd_prodotto_acquistato
        where   cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
        and     cd_prodotto_acquistato.STATO_DI_VENDITA = 'PRE'
        and     cd_prodotto_acquistato.id_piano = cd_pianificazione.id_piano
        and     cd_prodotto_acquistato.id_ver_piano = cd_pianificazione.id_ver_piano;
        --
        select  count(distinct id_cliente)
        into    v_count_cliente
        from    cd_pianificazione,
                cd_prodotto_acquistato,
                cd_break,
                cd_comunicato
        where   cd_comunicato.data_erogazione_prev = p_giorno
        and     cd_comunicato.id_sala = p_id_sala
        and     cd_comunicato.flg_annullato = 'N'
        and     cd_comunicato.flg_sospeso = 'N'
        and     cd_comunicato.cod_disattivazione is null
        and     cd_comunicato.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
        and     cd_prodotto_acquistato.flg_annullato = 'N'
        and     cd_prodotto_acquistato.flg_sospeso = 'N'
        and     cd_prodotto_acquistato.STATO_DI_VENDITA = 'PRE'
        and     cd_prodotto_acquistato.id_piano = cd_pianificazione.id_piano
        and     cd_prodotto_acquistato.id_ver_piano = cd_pianificazione.id_ver_piano
        and     cd_comunicato.id_break = cd_break.id_break
        --Controllo esistenza del cliente solo in specifici tipi_break 
        --Trailer-Inizio Film-Segui il film
        and     cd_break.id_tipo_break in (5,2,25)
        and     cd_pianificazione.id_cliente = v_id_cliente;
        if(v_count_cliente = 0) then
            /*SALA IDONEA*/
            v_return := 1;
        else
            /*Se il cliente e gia presente in sala (nei break specificati), 
            prima di marcarla come non idonea,controllo che non ci siano ancora
            delle sale idonee (tra quelle non ancora associate)*/
            --CONTROLLO - INIZIO
            --sale DISPONIBILI NON ASSOCIATE  
             select count(id_sala) into v_count_sale_disp
                from
                (
                with spett_sala_giorno as
                    (
                    select  cd_proiezione.id_schermo,
                            cd_proiezione.data_proiezione,
                            cd_proiezione_spett.id_spettacolo,
                            count(DISTINCT id_spettacolo) over (partition by CD_SCHERMO.ID_SCHERMO,data_proiezione)num_spett_giorno
                    from    cd_proiezione,
                            cd_proiezione_spett,
                            CD_CINEMA_CONTRATTO,
                            CD_CINEMA,
                            CD_CONTRATTO,
                            CD_SALA,
                            CD_SCHERMO                            
                    where   cd_proiezione.data_proiezione = p_giorno 
                    and     cd_proiezione.flg_annullato = 'N'
                    and     cd_proiezione_spett.id_proiezione = cd_proiezione.id_proiezione
                    AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                    AND     CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
                    AND     CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                    AND     CD_CINEMA_CONTRATTO.ID_CINEMA = CD_CINEMA.ID_CINEMA
                    AND     CD_CONTRATTO.ID_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CONTRATTO
                    AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE                    
                    )
                select  id_sala
                from    spett_sala_giorno,
                        cd_schermo,
                        cd_prodotto_acquistato
                where   spett_sala_giorno.id_schermo = cd_schermo.id_schermo
                and     spett_sala_giorno.num_spett_giorno = 1
                and     cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
                and     spett_sala_giorno.id_spettacolo = cd_prodotto_acquistato.id_spettacolo
                and     instr(p_sale_non_idonee,'*'||id_sala||'*') =0
                minus
                select id_sala
                from cd_sala_segui_film
                where id_prodotto_acquistato = p_id_prodotto_acquistato
                and   giorno = p_giorno
                and   flg_virtuale = 'N'
                );
                --sale disponibili NON ASSOCIATE E CON PRESENZA DEL CLIENTE
                select count(id_sala) into v_count_sale_cli from
                 (
                 select distinct sale_disp.id_sala
                 from
                        /*elenco delle sale disponibili non ancora associate*/
                        (
                        with spett_sala_giorno as
                                (
                                select  cd_proiezione.id_schermo,
                                        cd_proiezione.data_proiezione,
                                        cd_proiezione_spett.id_spettacolo,
                                        count(DISTINCT id_spettacolo) over (partition by CD_SCHERMO.ID_SCHERMO,data_proiezione)num_spett_giorno
                                from    cd_proiezione,
                                        cd_proiezione_spett,
                                        CD_CINEMA_CONTRATTO,
                                        CD_CINEMA,
                                        CD_CONTRATTO,
                                        CD_SALA,
                                        CD_SCHERMO                                        
                                where   cd_proiezione.data_proiezione = p_giorno 
                                and     cd_proiezione.flg_annullato = 'N'
                                and     cd_proiezione_spett.id_proiezione = cd_proiezione.id_proiezione
                                AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                                AND     CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
                                AND     CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                                AND     CD_CINEMA_CONTRATTO.ID_CINEMA = CD_CINEMA.ID_CINEMA
                                AND     CD_CONTRATTO.ID_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CONTRATTO
                                AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE                                
                                )
                            select  distinct cd_schermo.id_sala
                            from    spett_sala_giorno,
                                    cd_schermo,
                                    cd_prodotto_acquistato
                            where   spett_sala_giorno.id_schermo = cd_schermo.id_schermo
                            and     spett_sala_giorno.num_spett_giorno = 1
                            and     cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
                            and     spett_sala_giorno.id_spettacolo = cd_prodotto_acquistato.id_spettacolo
                        )sale_disp,
                        cd_comunicato,cd_sala,cd_cinema,
                        cd_prodotto_acquistato,cd_pianificazione,
                        cd_break
                 where   cd_comunicato.data_erogazione_prev = p_giorno
                 and     cd_comunicato.flg_annullato = 'N'
                 and     cd_comunicato.flg_sospeso = 'N'
                 and     cd_comunicato.cod_disattivazione is null
                 and     cd_comunicato.id_sala = cd_sala.id_sala
                 and     cd_cinema.id_cinema = cd_sala.id_cinema
                 and     cd_cinema.flg_virtuale = 'N'
                 and     cd_comunicato.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
                 and     cd_prodotto_acquistato.ID_PIANO = cd_pianificazione.ID_PIANO
                 and     cd_prodotto_acquistato.ID_VER_PIANO = cd_pianificazione.ID_VER_PIANO
                 and     cd_pianificazione.id_cliente = v_id_cliente
                 and     cd_prodotto_acquistato.flg_annullato = 'N'
                 and     cd_prodotto_acquistato.flg_sospeso = 'N'
                 and     cd_prodotto_acquistato.STATO_DI_VENDITA = 'PRE'
                 and     cd_comunicato.id_break = cd_break.id_break
                 and     cd_break.id_tipo_break in (2,5,25)
                 and     cd_comunicato.id_sala = sale_disp.id_sala
                 /*escludo le sale gia scartate perche non idonee magari per affollamento*/
                 and     instr(p_sale_non_idonee,'*'||sale_disp.id_sala||'*') =0
                 minus
                 select id_sala
                 from cd_sala_segui_film
                 where id_prodotto_acquistato = p_id_prodotto_acquistato
                 and   giorno = p_giorno
                 and   flg_virtuale = 'N'
                 );
                --Controllo sale disponibili con sale dipo con cliente
                 if(v_count_sale_disp > v_count_sale_cli)then
                 --Ho ancora sale disponibili quindi temporaneamente scarto
                    --DBMS_OUTPUT.PUT_LINE('p_id_sala:'||p_id_sala||'-SCARTATA TEMPORANEAMENTE'  );
                    v_return := 2;
                 else
                 --non ho piu sale disponibili senza concorrenza del cliente
                 --quindi MI ACCONTENTO ED INSERISCO
                   --DBMS_OUTPUT.PUT_LINE('p_id_sala:'||p_id_sala||'-MI ACCONTENTO ED INSERISCO'||'--v_count_sale_disp:'||v_count_sale_disp||'-'||'/v_count_sale_cli:'||v_count_sale_cli  );
                   v_return := 1;
                 end if;
            --CONTROLLO - FINE
        end if;
    else
        /*SALA NON IDONEA*/
        v_return := 0;
    end if;
--  
    --DBMS_OUTPUT.PUT_LINE('VERIFICA DISPONIBILITA VALORE:'||v_return);
    return v_return;
    EXCEPTION
       WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR(-20016, 'FUNZIONE FU_VERIFICA_DISPONIBILITA: SI E VERIFICATO UN ERRORE:'||SQLERRM);
 end FU_VERIFICA_DISPONIBILITA;
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_GESTISCI_PRODOTTO
--
-- DESCRIZIONE:  Procedura che permette di gestire il singolo prodotto segui il film
--              secondo in parametri di input passati
--
-- OPERAZIONI:
--   1)Recupero le informaizoni caratterizzanti il prodotto_acquistato passato come parametro
--   2)Verifico che il prodotto in esame sia stato gia trattato 
--      (questo in funzione della presenza di record nella tavola CD_SALA_SEGUI_FILM )
--      in caso contrario creo elementi in tavola
--   3)Invoco procedura di disassociazione sale non piu idonee
--   4)Se il valore di soglia impostato e diverso da null
--     Invoco procedura per disassociare sale fino al raggiungimento della soglia.
--      Se anche il nuovo valore di soglia fosse maggiore di quello preesistente, 
--      la procedura non farebbe nulla
--     Aggiorno valore di soglia nella tavola di gestione prodoto segui film
--   5)Invoco procedura di associazione sala
--
-- INPUT:
--          p_id_prodotto_acquistato  identificativo del prodotto da trattare
--          p_giorno                  giorno specifico
--          p_soglia                  soglia da impostare per l'associazione
--                                    SE NULL concludo che non ci sono aggiornamenti di soglia
--
-- OUTPUT: esito dell'operazione
--         1    Gestion del prodotto avvenuta con successo 
--        -2    Errori durante la procedura di gestione 
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 18 Febbraio 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_GESTISCI_PRODOTTO(p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                p_giorno                    date,
                                p_soglia                    number,
                                p_esito                     out number
                               ) is
--
v_num_prod_trattati     number;
v_esito_operazione      number := 0;
v_data_inizio           date;
v_data_fine             date;
v_id_spettacolo         number;  
v_soglia                number;                 
  begin
    P_ESITO := 1;
    SAVEPOINT SP_GESTISCI_PRODOTTO;
    /*verifico che sia stato gia trattato (presenza nella tavola DI GESTIONE)
        in caso contrario creo
      DOPO DI CHE
        disassocio eventuali sale non piu idonee
        associo o disassocio fino a soglia in base al
      */
    select  data_inizio,data_fine,id_spettacolo
    into    v_data_inizio,v_data_fine,v_id_spettacolo
    from    cd_prodotto_acquistato
    where   cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato;
--    
    select  count(id_prodotto_acquistato)
    into    v_num_prod_trattati
    from    cd_sala_segui_film
    where   id_prodotto_acquistato = p_id_prodotto_acquistato
    and     giorno = p_giorno;
    if(v_num_prod_trattati = 0)then
        /*Il prodotto non e stato mai trattato quindi 
          prima di proseguire popolo tavola.*/
        PR_POPOLA_TAVOLA(p_id_prodotto_acquistato,p_giorno,p_giorno,p_soglia,v_esito_operazione);
        --PR_POPOLA_TAVOLA(p_id_prodotto_acquistato,v_data_inizio,v_data_fine,p_soglia,v_esito_operazione);
    end if;
    PR_DISASSOCIA_SALE_NON_IDONEE(p_id_prodotto_acquistato,v_id_spettacolo,p_giorno,v_esito_operazione);
    if(p_soglia is not null)then
        /*Anche se soglia new e maggiore di soglia old la chiamo ugualmente
        nella peggiore delle ipotesi non fa nulla*/
        PR_DISASSOCIA_FINO_A_SOGLIA(p_id_prodotto_acquistato,v_id_spettacolo,p_giorno,p_soglia,v_esito_operazione);
        /*aggiorno valore della soglia nella tavola del prodotto*/
        update
                cd_sala_segui_film
        set     soglia = p_soglia
        where   id_prodotto_acquistato = p_id_prodotto_acquistato
        and     giorno = p_giorno;
    else
        /*recupero soglia attuale prima di associare altrimenti passerei null*/
        select distinct soglia into v_soglia
        from cd_sala_segui_film
        where id_prodotto_acquistato = p_id_prodotto_acquistato
        and   giorno = p_giorno;
    end if;
    PR_ASSOCIA_SALE(p_id_prodotto_acquistato,v_id_spettacolo,p_giorno,nvl(p_soglia,v_soglia),v_esito_operazione);
    p_esito := v_esito_operazione;
    EXCEPTION
       WHEN OTHERS THEN
       P_ESITO := -2;
       RAISE_APPLICATION_ERROR(-20016, 'PROCEDURA PR_GESTISCI_PRODOTTO: SI E VERIFICATO UN ERRORE:'||SQLERRM);
       ROLLBACK TO SP_GESTISCI_PRODOTTO;
 end PR_GESTISCI_PRODOTTO;
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_AGGIORNA_PRODOTTO
--
-- DESCRIZIONE:  Procedura richiamata tramite job_db che si occupera di 
--              aggiornare le sale associate per tutti i prodotti SEGUI IL FILM
--              in corso alla data di esecuzione 
--
-- OPERAZIONI:
--   1)Recupero di tutti i prodotti SEGUI IL FILM che sono in corso alla
--      data impostata come parametro
--   2)Per ogni prodotto recuperato e invocata la procedura GESTISCI_PRODOTTO
--      per ogni giorno del prodotto a partire da sysdate e
--      con valore di soglia a null
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione
--         1    Aggiornamento avvenuto con successo 
--        -2    Errori durante la procedura di aggiornamento 
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 17 Febbraio 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_AGGIORNA_PRODOTTO( p_giorno                    date
                                ) is
--
v_num_prod_trattati     number;
v_esito_operazione      number := 0;             
  begin
    SAVEPOINT SP_AGGIORNA_PRODOTTO;
    /*Recupero tutti i prodotti SEGUI IL FILM validi alla data di ricerca*/
    for elenco_prodotti in
    (
        select  cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO,
                cd_prodotto_acquistato.DATA_INIZIO,
                cd_prodotto_acquistato.DATA_FINE
        from    cd_prodotto_acquistato,
                cd_prodotto_vendita
        where   p_giorno between cd_prodotto_acquistato.data_inizio and cd_prodotto_acquistato.data_fine
        and     cd_prodotto_acquistato.flg_annullato = 'N'
        and     cd_prodotto_acquistato.flg_sospeso = 'N'
        and     cd_prodotto_acquistato.STATO_DI_VENDITA = 'PRE'
        and     cd_prodotto_acquistato.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita
        and     cd_prodotto_vendita.FLG_SEGUI_IL_FILM = 'S'
    )loop
        /*per ognuno di questi verifico che siano stati gia trattati (presenza nella tavola DI GESTIONE)
            in caso contrario creo
          DOPO DI CHE
            disassocio eventuali sale non piu idonee
            associo fino a soglia
          */
        --DBMS_OUTPUT.PUT_LINE('prodotto da trattare:'||elenco_prodotti.ID_PRODOTTO_ACQUISTATO );
        select  count(id_prodotto_acquistato)
        into    v_num_prod_trattati
        from    cd_sala_segui_film
        where   id_prodotto_acquistato = elenco_prodotti.ID_PRODOTTO_ACQUISTATO;
        /*Se Il prodotto non e stato mai trattato quindi 
              prima di proseguire popolo tavola*/
        /*if(v_num_prod_trattati = 0)then
            pr_popola_tavola(elenco_prodotti.ID_PRODOTTO_ACQUISTATO,elenco_prodotti.data_inizio,elenco_prodotti.data_fine,null,v_esito_operazione);
        end if;*/
        /*Tratto solo i prodotti gia gestiti almeno una volta*/
        if(v_num_prod_trattati > 0)then
        --DBMS_OUTPUT.PUT_LINE('prodotto pronto per essere aggiornato');
            for prodotto_giorno in 
            (
                select  distinct
                        cd_sala_segui_film.id_prodotto_acquistato,
                        cd_prodotto_acquistato.id_spettacolo,
                        cd_sala_segui_film.soglia,
                        cd_sala_segui_film.giorno
                from    
                        cd_sala_segui_film,
                        cd_prodotto_acquistato
                where   cd_sala_segui_film.id_prodotto_acquistato = elenco_prodotti.ID_PRODOTTO_ACQUISTATO
                and     cd_sala_segui_film.giorno >= trunc(sysdate) 
                and     cd_sala_segui_film.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
            )loop
                --DBMS_OUTPUT.PUT_LINE('procedo');
                PR_DISASSOCIA_SALE_NON_IDONEE(elenco_prodotti.id_prodotto_acquistato,prodotto_giorno.id_spettacolo,prodotto_giorno.giorno,v_esito_operazione);
                PR_ASSOCIA_SALE(elenco_prodotti.id_prodotto_acquistato,prodotto_giorno.id_spettacolo,prodotto_giorno.giorno,prodotto_giorno.soglia,v_esito_operazione);
            end loop;--fine ciclo sui giorni del singolo prodotto
        end if;
        --
    end loop;--fine ciclo tutti i prodotti segui il film
    ----------------    ESECUZIONE COMMIT DENTRO LA PROCEDURA   ---------------------------------------------------
    COMMIT;
    ----------------    ESECUZIONE COMMIT DENTRO LA PROCEDURA   ---------------------------------------------------
     EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20016, 'PROCEDURA PR_AGGIORNA_PRODOTTO: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_AGGIORNA_PRODOTTO;
 end PR_AGGIORNA_PRODOTTO;
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_SALE
--
-- DESCRIZIONE:  Procedura che permette di associare le sale virtuali a sale reali
--               per la messa in onda del prodotto SEGUI IL FILM
--
-- OPERAZIONI:
--   1)Recupero il numero di sale REALI ASSOCIATE e una stringa contenente i 
--      corrispondenti id_sala in funzione del il prodotto indicato
--   2)Fino a quando non e raggiunto il valore di soglia o non ci sono piu sale
--      disponibili recupero una sala in modo RANDOM tra quelle 
--      idonee per il prodotto SEGUI FILM 
--   3)Per ogni sala RANDOM imposto sala reale su comunicato associato a sala virtuale
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione
--         1    Associazione avvenuta con successo 
--        -2    Errori durante la procedura di associazione 
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 15 Febbraio 2011
--
--  MODIFICHE: 
--              Tommaso D'Anna, Teoresi srl, 8 Giugno 2011
--                  - Inserita DISTINCT in SPETT_SALA_GIORNO per considerare anche i casi
--                  in cui il gestore inserisca due programmazioni identiche nello stesso giorno
--              Tommaso D'Anna, Teoresi srl, 23 Giugno 2011
--                  - Inserito il controllo sul contratto valido
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_ASSOCIA_SALE( p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                            p_id_spettacolo             cd_spettacolo.id_spettacolo%type,
                            p_giorno                    date,
                            p_soglia_new                number,
                            p_esito                     out number
                           ) is
--                           
 v_num_sale_associate   number := 0;
 /*inizializzo le stringhe in modo da non avere all'istante iniziale dei valori a null */
 v_sale_associate       varchar2(32767) ;
 v_sale_non_idonee      varchar2(32767) := '-';
 v_sala_virtuale        NUMBER;
 v_sala_disponibile     number;
 v_esito_impostazione   number := 0;
 v_exit                 number := 0;
 begin
 /*in questa fase sto associando, quindi vuol dire a che monte e stato 
    effettuato un controllo su eventuali vecchie sale associate non 
    piu valide e quindi DISASSOCIATE
 */
    /*Recupero il numero attuale di sale REALI ASSOCIATE 
      e una stringa contenente i corrispondenti id_sala  
      per il prodotto indicato*/
    P_ESITO := 1;
    SAVEPOINT SP_ASSOCIA_SALE;
    select  count(id_sala),
            '-'||FU_CD_STRING_AGG('*'||id_sala||'*')
            into v_num_sale_associate,v_sale_associate
    from    cd_sala_segui_film
    where   id_prodotto_acquistato = p_id_prodotto_acquistato
    and     giorno = p_giorno
    and     flg_virtuale = 'N';
    /*  CONDIZIONI DI USCITA DAL CICLO WHILE
            -   v_num_sale_associate = p_soglia_new 
            -   v_num_sale_associate<p_soglia_new ma non ci sono + sale disponibili/idonee
            -   v_sala_virtuale = 0, la soglia non e stata raggiunta ma non ci sono + sale virtuali ==> SOGLIA IMPOSTATA > 531
    */
     while (v_num_sale_associate<p_soglia_new and v_exit = 0) LOOP
     /* Recupero una sala virtuale 
        e la sostituisco con una sala (scelta  in modo RANDOM) 
        tra quelle disponibili
        Per essere sicuro di trattare eventuali sale reali disassociate(divenute virtuali)
        ordino per datamod desc in modon da prendere quella modificata + di recente
        */
        select id_sala INTO v_sala_virtuale
        from
        (   select
            id_sala,datamod 
            from    cd_sala_segui_film 
            where   id_prodotto_acquistato = p_id_prodotto_acquistato
            and     giorno = p_giorno
            and     flg_virtuale = 'S'
            union 
            select 0 id_sala,(sysdate-500/*numero casuale per avere una data bassa*/) datamod from dual
            order by datamod desc,id_sala desc
        )where rownum = 1;
        if(v_sala_virtuale <> 0) then
            /*recupero sala disponibile diversa da quelle gia associate e da 
            quelle eventualmnete non idonee e provo ad impostarla come REALE*/
            select id_sala into v_sala_disponibile
            from
            (
                with spett_sala_giorno as
                    (
                    select  cd_proiezione.id_schermo,
                            cd_proiezione.data_proiezione,
                            cd_proiezione_spett.id_spettacolo,
                            count(DISTINCT id_spettacolo) over (partition by CD_SCHERMO.ID_SCHERMO,data_proiezione)num_spett_giorno
                    from    cd_proiezione,
                            cd_proiezione_spett,
                            CD_CINEMA_CONTRATTO,
                            CD_CINEMA,
                            CD_CONTRATTO,
                            CD_SALA,
                            CD_SCHERMO
                    where   cd_proiezione.data_proiezione = p_giorno 
                    and     cd_proiezione.flg_annullato = 'N'
                    and     cd_proiezione_spett.id_proiezione = cd_proiezione.id_proiezione
                    AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                    AND     CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
                    AND     CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                    AND     CD_CINEMA_CONTRATTO.ID_CINEMA = CD_CINEMA.ID_CINEMA
                    AND     CD_CONTRATTO.ID_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CONTRATTO
                    AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE                    
                    )
                select  id_sala
                from    spett_sala_giorno,
                        cd_schermo
                where   spett_sala_giorno.id_schermo = cd_schermo.id_schermo
                and     spett_sala_giorno.num_spett_giorno = 1
                and     spett_sala_giorno.id_spettacolo = p_id_spettacolo
                and     instr(v_sale_associate,'*'||id_sala||'*')=0
                and     instr(v_sale_non_idonee,'*'||id_sala||'*') =0
                order by dbms_random.value
            ) where rownum = 1;
            /*se ho trovato la sala*/
            if(v_sala_disponibile is not null) then
                /*IMPOSTO SALA REALE*/
                PR_IMPOSTA_SALA(p_id_prodotto_acquistato,v_sala_virtuale,v_sala_disponibile,p_giorno,v_sale_non_idonee,v_esito_impostazione);
                if(v_esito_impostazione = 1)then
                --DBMS_OUTPUT.PUT_LINE('sala:'||v_sala_disponibile||' associata correttamente'  );
                /*l'operazione e andata a buon fine
                  aggiorno stringa delle sale associate e il numero delle stesse*/
                    v_sale_associate := v_sale_associate||'*'||v_sala_disponibile||'*;';
                    --DBMS_OUTPUT.PUT_LINE('sala_associate:'||v_sale_associate);
                    v_num_sale_associate := v_num_sale_associate+1;
                else 
                    if(v_esito_impostazione = -1) then
                        --DBMS_OUTPUT.PUT_LINE('sala:'||v_sala_disponibile||' non associata - aggiorno sale non idonee'  );
                        /*aggiorno sale non idonee*/
                        v_sale_non_idonee := v_sale_non_idonee||'*'||v_sala_disponibile||'*;';
                    else
                        if(v_esito_impostazione = -10)then
                        --DBMS_OUTPUT.PUT_LINE('sala:'||v_sala_disponibile||' scartata temporaneamente'  );
                        --sala temporaneamente scartata
                        --non aggiorno elenco sale non disponibili
                        null;
                        end if;
                    end if;
                
                end if;
            else
                /*non ho piu sale disponibili*/
                v_exit := 1;
            end if;
        else
            /*non ho piu sale virtuali*/
            v_exit := 1;
        end if;
--     
     END LOOP;
     IF(instr(v_sale_non_idonee,';')>1) then
        p_esito := -4;
     end if;
     
     EXCEPTION
        when no_data_found then
        null;
        --DBMS_OUTPUT.PUT_LINE('non ho piu sale disponibili - esco - v_sale_associate:'||v_sale_associate||' - v_sale_non_idonee:'||v_sale_non_idonee);
        WHEN OTHERS THEN
        P_ESITO := -2;
        RAISE_APPLICATION_ERROR(-20016, 'PROCEDURA PR_ASSOCIA_SALE: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_ASSOCIA_SALE;
 end;
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_DISASSOCIA_SALE_NON_IDONEE
--
-- DESCRIZIONE:  Procedura che permette di disassociare le sale reale 
--               ripristinandole come sale Virtuali
--               per la messa in onda del prodotto SEGUI IL FILM
--
-- OPERAZIONI:
--   1)Per ogni sala che non rientra piu nell'elenco delle 
--      sale idonee per il prodotto in esame e sono gia associate
--      invoco la procedura PR_RIPRISTINA_SALA
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione che dipende dall'esito del ripristino
--          0 non sono state trovate sale non idonee 
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 15 Febbraio 2011
--
--  MODIFICHE: 
--              Tommaso D'Anna, Teoresi srl, 8 Giugno 2011
--                  - Inserita DISTINCT in SPETT_SALA_GIORNO per considerare anche i casi
--                  in cui il gestore inserisca due programmazioni identiche nello stesso giorno
--              Tommaso D'Anna, Teoresi srl, 23 Giugno 2011
--                  - Inserito il controllo sul contratto valido
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_DISASSOCIA_SALE_NON_IDONEE(   p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                            p_id_spettacolo             cd_spettacolo.id_spettacolo%type,
                                            p_giorno                    date,
                                            p_esito                     out number
                                         ) is
--
 v_esito_impostazione   number :=0;                           
 begin
    /*Recupero tutte le eventuali sale associate ma non piu idonee per il prodotto SEGUI IL FILM*/
     for sale_non_idonee in 
            (   select distinct cd_sala_segui_film.id_sala
                from
                    ( with spett_sala_giorno as
                            (
                            select  cd_proiezione.id_schermo,
                                    cd_proiezione.data_proiezione,
                                    cd_proiezione_spett.id_spettacolo,
                                    count(DISTINCT id_spettacolo) over (partition by CD_SCHERMO.ID_SCHERMO,data_proiezione)num_spett_giorno
                            from    cd_proiezione,
                                    cd_proiezione_spett,
                                    CD_CINEMA_CONTRATTO,
                                    CD_CINEMA,
                                    CD_CONTRATTO,
                                    CD_SALA,
                                    CD_SCHERMO
                            where   cd_proiezione.data_proiezione = p_giorno 
                            and     cd_proiezione.flg_annullato = 'N'
                            and     cd_proiezione_spett.id_proiezione = cd_proiezione.id_proiezione                AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                            AND     CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
                            AND     CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                            AND     CD_CINEMA_CONTRATTO.ID_CINEMA = CD_CINEMA.ID_CINEMA
                            AND     CD_CONTRATTO.ID_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CONTRATTO
                            AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE
                            )
                        select  FU_CD_STRING_AGG('*'||id_sala||'*') elenco
                        from    spett_sala_giorno,
                                cd_schermo
                        where   spett_sala_giorno.id_schermo = cd_schermo.id_schermo
                        and     spett_sala_giorno.num_spett_giorno = 1
                        and     spett_sala_giorno.id_spettacolo = p_id_spettacolo
                    )sale_disponibili,
                    cd_sala_segui_film
                where
                        cd_sala_segui_film.id_prodotto_acquistato = p_id_prodotto_acquistato
                and     cd_sala_segui_film.flg_virtuale = 'N'
                and     cd_sala_segui_film.GIORNO = p_giorno 
                /*recupero quelle sale disponibili ma non presenti tra quelle gia associate*/
                and     instr(sale_disponibili.elenco,'*'||cd_sala_segui_film.id_sala||'*')=0
           ) LOOP
         PR_RIPRISTINA_SALA(p_id_prodotto_acquistato,sale_non_idonee.id_sala,p_giorno,v_esito_impostazione);
         --DBMS_OUTPUT.PUT_LINE('sala disassociata:'||sale_non_idonee.id_sala);
     END LOOP;
     p_esito := v_esito_impostazione;
 end PR_DISASSOCIA_SALE_NON_IDONEE;
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_DISASSOCIA_FINO_A_SOGLIA
--
-- DESCRIZIONE:  Procedura che permette di disassociare le sale reale 
--               ripristinandole come sale Virtuali
--               per la messa in onda del prodotto SEGUI IL FILM
--
-- OPERAZIONI:
--   1)Fino a quando non e raggiunto il valore di soglia
--      scelgo una sala reale gia associata in modo random e
--      invoco la procedura PR_RIPRISTINA_SALA
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione che dipende dall'esito del ripristino
--          0 non e stata disassociata alcuna sala 
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 15 Febbraio 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_DISASSOCIA_FINO_A_SOGLIA(  p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                         p_id_spettacolo             cd_spettacolo.id_spettacolo%type,
                                         p_giorno                    date,
                                         p_soglia                    number,
                                         p_esito                     out number
                                       ) is
--
 v_esito_impostazione   number :=0; 
 v_num_sale_associate   number :=0;      
 v_sala_candidata       number :=0;                  
 begin
    /*
        Fino a quando non e raggiunto il valore impostato di soglia
        Disassocio delle sale scelte RANDOM tra quelle reali gia associate
    */
    select  count(id_sala)
    into    v_num_sale_associate
    from    cd_sala_segui_film
    where   id_prodotto_acquistato = p_id_prodotto_acquistato
    and     giorno = p_giorno
    and     flg_virtuale = 'N';
     while (v_num_sale_associate > p_soglia) LOOP
        /*Seleziono riga random da disassociare*/
        select id_sala
        into   v_sala_candidata
        from
        (
            select  id_sala
            from    cd_sala_segui_film
            where   id_prodotto_acquistato = p_id_prodotto_acquistato
            and     giorno = p_giorno
            and     flg_virtuale = 'N'
            order by dbms_random.value
         )where rownum = 1;
         PR_RIPRISTINA_SALA(p_id_prodotto_acquistato,v_sala_candidata,p_giorno,v_esito_impostazione);
         if(v_esito_impostazione = 1)then
            v_num_sale_associate := v_num_sale_associate-1;
         end if;
     END LOOP;
     p_esito := v_esito_impostazione;
 end PR_DISASSOCIA_FINO_A_SOGLIA;
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_IMPOSTA_SALA
--
-- DESCRIZIONE:  Procedura che permette di impostare sala reale 
--              al posto della sala virtuale in tutti i punti previsti
--
-- OPERAZIONI:
--   0)Verifico che ci sia disponibilita nella sala candidata alla associazione
--   1)Recupero identificativi del circuito e prodotto di vendita riferiti al 
--      prodotto acquistato in esame
--   2)Per ogni id_comunicato e fascia relativi alla sala da rimpiazzare
--      recuopero una sala virtuale candidata al rimpiazzo  
--   3)Estraggo identificativi del brek e break di vendita legati alla sala viruale 
--   4)Aggiorno tavola cd_comunicato e cd_sala_segui_film 
--   5)Riordino posizioni dei comunicati restanti in sala 
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione
--          1   impostazione eseguita con successo
--         -1   sala non disponibile per l'inserimento del nuovo comunicato 
--         -2   errore non gestito
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 15 Febbraio 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
--
PROCEDURE PR_IMPOSTA_SALA(  p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                            p_sala_virtuale              number,
                            p_sala_disponibile           number,
                            p_giorno                     date,
                            p_sale_non_idonee            varchar2,
                            p_esito                      out number
                          ) is
--                           
 v_disponibilita        number := 0;
 v_id_break_vendita     number;
 v_id_break             number;
 v_id_circuito          number;
 v_id_prodotto_vendita  number;
 v_id_comunicato        number;
 v_posiz_comunicato     number;
 v_esiste_pos_rigore number;
--
 begin
    SAVEPOINT SP_IMPOSTA_SALA;
    p_esito := 1;
    --DBMS_OUTPUT.PUT_LINE('PR_IMPOSTA_SALA : p_id_prodotto_acquistato'||p_id_prodotto_acquistato||' p_sala_virtuale:'||p_sala_virtuale||' p_giorno:'||p_giorno||' p_sala_disponibile:'||p_sala_disponibile  );
    /*Prima di procedere con l'impostazione verifico ci sia disponibilita nella sala*/
    v_disponibilita := fu_verifica_disponibilita(p_id_prodotto_acquistato,p_sala_disponibile,p_giorno,p_sale_non_idonee);
    if(v_disponibilita = 1)then
        /*recupero il circuito e il prodotto di vendita corrispondenti*/
        select id_circuito,cd_prodotto_acquistato.id_prodotto_vendita
        into   v_id_circuito, v_id_prodotto_vendita
        from  cd_prodotto_acquistato,
              cd_prodotto_vendita
        where cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
        and   cd_prodotto_acquistato.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita;
        --DBMS_OUTPUT.PUT_LINE('AAAA');
        /*della sala candidata 
          DEVO TROVARE ID_BREAK E ID_BREAK_VENDITA 
          PER OGNI PROIEZIONE TIPO/id_comunicato della sala virtuale*/
        for c_proiezione in (SELECT ID_COMUNICATO, ID_FASCIA
                            FROM    CD_PROIEZIONE, 
                                    CD_BREAK,
                                    CD_COMUNICATO
                            WHERE CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                            AND CD_COMUNICATO.DATA_EROGAZIONE_PREV = p_giorno
                            AND CD_COMUNICATO.ID_SALA = p_sala_virtuale
                            AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
                            AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                            AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
                            AND CD_BREAK.ID_BREAK = CD_COMUNICATO.ID_BREAK
                            AND CD_BREAK.FLG_ANNULLATO = 'N'
                            AND CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
                            AND CD_PROIEZIONE.FLG_ANNULLATO = 'N' 
                        ) LOOP
             --DBMS_OUTPUT.PUT_LINE('PROVA:p_sala_disponibile:'||p_sala_disponibile||'-'||'v_id_circuito:'||v_id_circuito||'-v_id_prodotto_vendita:'||v_id_prodotto_vendita||'-c_proiezione.id_fascia:'||c_proiezione.id_fascia);
            SELECT  DISTINCT 
                    CD_BREAK_VENDITA.ID_BREAK_VENDITA, CD_BREAK.ID_BREAK
            INTO    v_id_break_vendita, v_id_break
            FROM    CD_BREAK_VENDITA, 
                    CD_CIRCUITO_BREAK,
                    CD_BREAK,
                    CD_PROIEZIONE,
                    CD_SCHERMO
            WHERE   CD_SCHERMO.ID_SALA = p_sala_disponibile
            AND     CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
            AND     CD_PROIEZIONE.FLG_ANNULLATO = 'N'
            AND     CD_PROIEZIONE.DATA_PROIEZIONE = p_giorno
            AND     CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
            AND     CD_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
            AND     CD_CIRCUITO_BREAK.ID_CIRCUITO = v_id_circuito
            AND     CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
            AND     CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
            AND     CD_PROIEZIONE.ID_FASCIA = c_proiezione.id_fascia;
            --DBMS_OUTPUT.PUT_LINE('BBBBB');
            /*RIMPIAZZO RIFERIMENTI SALA VIRTUALE CON RIFERIMENTI SALA REALE*/
            --DBMS_OUTPUT.PUT_LINE('p_sala_disponibile:'||p_sala_disponibile||' v_id_break_vendita:'||v_id_break_vendita||' v_id_break:'||v_id_break||' com:'||c_proiezione.ID_COMUNICATO  );
            /*PRIMA DI PROCEDERE CON L'UPDATE, VERIFICO CHE NON CI SIA UNA EVENTUALE POSIZIONE PREFERENZIALE DEL COMUNICATO*/
            SELECT COUNT(1)
            INTO    v_posiz_comunicato 
            FROM    CD_COMUNICATO_STO
            WHERE   ID_COMUNICATO = c_proiezione.ID_COMUNICATO;
            IF(v_posiz_comunicato>0)THEN
                /*
                Verifico concorrenza della posizione avuta dal comunicato
                nella sala in esame
                */
                SELECT NVL(POSIZIONE,-100) 
                INTO   v_posiz_comunicato
                FROM    CD_COMUNICATO
                WHERE  ID_COMUNICATO = c_proiezione.ID_COMUNICATO;
                /*Verifico che l'eventuale posizione concorrente 
                non sia anche di rigore*/
                select count(1)
                into v_esiste_pos_rigore
                from cd_comunicato
                where id_break = v_id_break
                and  posizione_di_rigore  = v_posiz_comunicato;
            END IF;
            UPDATE CD_COMUNICATO
            SET ID_SALA = p_sala_disponibile,
            ID_BREAK_VENDITA = v_id_break_vendita,
            ID_BREAK = v_id_break
            WHERE ID_COMUNICATO = c_proiezione.ID_COMUNICATO;
--          
            IF(v_posiz_comunicato>0 and  v_esiste_pos_rigore = 0)THEN
            /*Richiesta posizione preferenziale
              Richiamata solo se 
                il comunicato in sala virtuale che si sta rimpiazzando aveva gia una posizione impostata
                se nella sala in esame non esiste gia un comunicato che abbia la posizione trovata come di rigore*/
                PA_CD_PRODOTTO_ACQUISTATO.PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,c_proiezione.ID_COMUNICATO,v_posiz_comunicato);
            ELSE
            /*imposto posizione classica*/
                PA_CD_PRODOTTO_ACQUISTATO.PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,c_proiezione.ID_COMUNICATO);
            END IF;
            
--            
        END LOOP;
        /*questo deve essere l'ultima operazione
        se le altre sono andate a buon fine*/
        update cd_sala_segui_film
        set id_sala = p_sala_disponibile,
            flg_virtuale = 'N'
        where id_prodotto_acquistato = p_id_prodotto_acquistato
        and   giorno = p_giorno
        and   id_sala = p_sala_virtuale;
    else
        --v_disponibilita = 2 vuol dire che la sala e stata temporaneamente scartata per 
        --concorrente presenza del cliente in sala 
        if(v_disponibilita = 2)then
            --DBMS_OUTPUT.PUT_LINE('SCARTATA TEMP IMPOSTA_SALA - p_id_sala:'||p_sala_disponibile);
            p_esito := -10;
        else
            --DBMS_OUTPUT.PUT_LINE('ERRORE IMPOSTA_SALA - p_id_sala:'||p_sala_disponibile);
            p_esito := -1;
        end if;
    end if;
    EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -2;
        RAISE_APPLICATION_ERROR(-20012, 'IMPOSTA_SALA: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_IMPOSTA_SALA;
 end; 
--
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_RIPRISTINA_SALA
--
-- DESCRIZIONE:  Procedura che permette di impostare sala reale 
--              al posto della sala virtuale in tutti i punti previsti
--
-- OPERAZIONI:
--   1)Recupero identificativi del circuito e prodotto di vendita riferiti al 
--      prodotto acquistato in esame
--   2)Per ogni id_comunicato e fascia relativi alla sala da rimpiazzare
--      recuopero una sala virtuale candidata al rimpiazzo  
--   3)Estraggo identificativi del brek e break di vendita legati alla sala viruale 
--   4)Aggiorno tavola cd_comunicato e cd_sala_segui_film 
--   5)Riordino posizioni dei comunicati restanti in sala 
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione
--          1   impostazione eseguita con successo
--         -2   errore non PREVISTO
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 15 Febbraio 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
--
PROCEDURE PR_RIPRISTINA_SALA(   p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                p_sala_reale                 number,
                                p_giorno                     date,
                                p_esito                      out number
                              ) is
--                           
 v_id_break_vendita number;
 v_id_break         number;
 v_id_circuito      number;
 v_id_prodotto_vendita  number;
 v_id_comunicato    number;
 v_sala_virtuale     number;
 begin
    SAVEPOINT SP_RIPRISTINA_SALA;
    --DBMS_OUTPUT.PUT_LINE('PR_RIPRISTINA_SALA : p_id_prodotto_acquistato'||p_id_prodotto_acquistato||' p_id_sala:'||p_sala_reale||' p_giorno:'||p_giorno  );
    p_esito := 1;
    /*recupero il circuito e il prodotto di vendita corrispondenti*/
    select id_circuito,cd_prodotto_acquistato.id_prodotto_vendita
    into   v_id_circuito, v_id_prodotto_vendita
    from  cd_prodotto_acquistato,
          cd_prodotto_vendita
    where cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
    and   cd_prodotto_acquistato.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita;
    /*della sala reale da ripristinare 
      DEVO TROVARE ID_BREAK E ID_BREAK_VENDITA 
      PER OGNI PROIEZIONE TIPO/id_comunicato 
      della sala virtuale con cui rimpiazzare*/
    for c_proiezione in (SELECT ID_COMUNICATO, ID_FASCIA
                        FROM    CD_PROIEZIONE, 
                                CD_BREAK,
                                CD_COMUNICATO
                        WHERE CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                        AND CD_COMUNICATO.DATA_EROGAZIONE_PREV = p_giorno
                        AND CD_COMUNICATO.ID_SALA = p_sala_reale
                        --AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
                        --AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                        --AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
                        AND CD_BREAK.ID_BREAK = CD_COMUNICATO.ID_BREAK
                        --AND CD_BREAK.FLG_ANNULLATO = 'N'
                        AND CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
                        --AND CD_PROIEZIONE.FLG_ANNULLATO = 'N' 
                    ) LOOP
        /*prima di estrarre id_break e id_break_vendita devo trovare una sale virtuale idonea*/
        select id_sala 
        into    v_sala_virtuale
        from
        (
            select  cd_sala.id_sala
            from 
                    cd_circuito_schermo,
                    cd_schermo,
                    cd_sala,cd_cinema
            where   id_circuito = v_id_circuito
            and     cd_circuito_schermo.id_schermo = cd_schermo.id_schermo
            and     cd_circuito_schermo.flg_annullato = 'N'
            and     cd_schermo.id_sala = cd_sala.id_sala
            and     cd_cinema.id_cinema = cd_sala.id_cinema
            and     cd_cinema.flg_virtuale = 'S'
            minus
            select  id_sala
            from    cd_sala_segui_film 
            where   cd_sala_segui_film.id_prodotto_acquistato = p_id_prodotto_acquistato
            and     cd_sala_segui_film.flg_virtuale = 'S'
            and     cd_sala_segui_film.giorno = p_giorno
            order by id_sala desc
        )where rownum = 1;
        if (v_sala_virtuale is not null) then
            SELECT  DISTINCT 
                    CD_BREAK_VENDITA.ID_BREAK_VENDITA, CD_BREAK.ID_BREAK
            INTO    v_id_break_vendita, v_id_break
            FROM    CD_BREAK_VENDITA, 
                    CD_CIRCUITO_BREAK,
                    CD_BREAK,
                    CD_PROIEZIONE,
                    CD_SCHERMO
            WHERE   CD_SCHERMO.ID_SALA = v_sala_virtuale
            AND     CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
            AND     CD_PROIEZIONE.FLG_ANNULLATO = 'N'
            AND     CD_PROIEZIONE.DATA_PROIEZIONE = p_giorno
            AND     CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
            AND     CD_BREAK.FLG_ANNULLATO = 'N'
            AND     CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
            AND     CD_CIRCUITO_BREAK.ID_CIRCUITO = v_id_circuito
            AND     CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
            AND     CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
            AND     CD_PROIEZIONE.ID_FASCIA = c_proiezione.id_fascia;
            /*RIMPIAZZO RIFERIMENTI SALA VIRTUALE CON RIFERIMENTI SALA REALE*/
            --DBMS_OUTPUT.PUT_LINE('v_sala_virtuale'||v_sala_virtuale||' v_id_break_vendita:'||v_id_break_vendita||' v_id_break:'||v_id_break||' PROIEZIONE:'||c_proiezione.ID_COMUNICATO  );
            UPDATE CD_COMUNICATO
            SET ID_SALA = v_sala_virtuale,
            ID_BREAK_VENDITA = v_id_break_vendita,
            ID_BREAK = v_id_break
            WHERE ID_COMUNICATO = c_proiezione.ID_COMUNICATO;
            --DBMS_OUTPUT.PUT_LINE('DOPO UPDATE' );
            --
            /*Riordino le posizione dei comunicati nella sala dopo la rimozione del comunicato in esame*/
            PA_CD_PRODOTTO_ACQUISTATO.PR_ELIMINA_BUCO_POSIZIONE_COM(c_proiezione.ID_COMUNICATO);
            --    
        else
            /*
                ERRORE
                INCOSISTENZA DEI DATI PERCHe C'e UNA SALA DA RIMPIAZZARE
                MA NON SONO STATE TROVATE SALE VIRTUALI "VUOTE O NON ASSOCIATE" 
            */
            RAISE OPERATION_NOT_PERMITTED;
        end if;
        
    END LOOP;
    /*questo deve essere l'ultima operazione
    se le altre sono andate a buon fine*/
    update cd_sala_segui_film
    set id_sala = v_sala_virtuale,
        flg_virtuale = 'S'
    where id_prodotto_acquistato = p_id_prodotto_acquistato
    and   giorno = p_giorno
    and   id_sala = p_sala_reale;
   
    EXCEPTION
        when no_data_found then
        P_ESITO := -5;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_RIPRISTINA_SALA: RILEVATA UNA INCONSISTENZA DEL DATO - NON SONO STATE TROVATE DELLE SALE VIRTUALI:'||SQLERRM);
        ROLLBACK TO SP_IMPOSTA_SALA;
        WHEN OTHERS THEN
        P_ESITO := -2;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_RIPRISTINA_SALA: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_IMPOSTA_SALA;
 end PR_RIPRISTINA_SALA; 
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_POPOLA_TAVOLA
--
-- DESCRIZIONE: Procedura che si occupa di popolare la tavola
--              CD_SALA_SEGUI_FILM nel caso di un nuovo prodotto che non e stato ancora
--              trattato dalla applicazione
--
-- OPERAZIONI:
--   1) Per ogni giorno individuato dal prodotto e per ogni sala virtuale
--      contenuta nel circuito SEGUI_FILM
--      inserisco nuovo record
--      SE SOGLIA E' NULL ==> INSERISCO COME VALORE DI DEFAULT 90
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione
--          1   popolamento andato con successo
--         -2   errore non PREVISTO
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 17 Febbraio 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------
--
PROCEDURE PR_POPOLA_TAVOLA(  p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                             p_data_inizio                date,
                             p_data_fine                  date,
                             p_soglia                     number,
                             p_esito                      out number
                             ) is
--
v_num_giorni NUMBER := (p_data_fine-p_data_inizio);                           
 begin
    SAVEPOINT SP_POPOLA_TAVOLA;
--    
    p_esito := 1;
    if(p_data_inizio = p_data_fine)then --sto trattando un solo giorno
       v_num_giorni := 1;
    end if;
    for k IN 0..v_num_giorni LOOP
        for elenco_sale in 
        (
            select  
                distinct cd_sala.id_sala
            from 
                cd_prodotto_vendita,
                cd_schermo,
                cd_sala,cd_cinema,
                cd_circuito_schermo
            where cd_prodotto_vendita.flg_segui_il_film = 'S'
            and cd_prodotto_vendita.id_circuito = cd_circuito_schermo.id_circuito
            and cd_circuito_schermo.id_schermo = cd_schermo.id_schermo
            and cd_schermo.id_sala = cd_sala.id_sala
            and cd_cinema.id_cinema = cd_sala.id_cinema
            and cd_cinema.flg_virtuale = 'S'
        )LOOP
        insert into cd_sala_segui_film
        (id_prodotto_acquistato,id_sala,giorno,soglia,flg_virtuale)
        values
        (p_id_prodotto_acquistato,elenco_sale.id_sala,p_data_inizio+k,nvl(p_soglia,90),'S');
        END LOOP;
        if(p_data_inizio = p_data_fine)then --sto trattando un solo giorno
           exit;
        end if;
    end LOOP;
   
    EXCEPTION
        WHEN OTHERS THEN
        P_ESITO := -2;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_POPOLA_TAVOLA: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_POPOLA_TAVOLA;
 end PR_POPOLA_TAVOLA;  
 
 
-------------------------------------------------------------------------------------------------
-- Procedura PR_RICALCOLA_TARIFFA
--
-- DESCRIZIONE:  Effettua il ricalcolo della tariffa dei prodotti a segui il film  presenti in un periodo
--
-- INPUT:  p_id_cliente:  codice del cliente; parametro opzionale
--         p_data_inizio: data di inizio del periodo cercato
--         p_data_fine:   data di fine del periodo cercato
--
-- OUTPUT: 
-- REALIZZATORE: Mauro Viel, Altran, Febbraio 2011
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) IS

v_piani_errati VARCHAR2(1024);
v_importo CD_TARIFFA.IMPORTO%TYPE;
BEGIN
    FOR PACQ IN
    (
         SELECT ID_PRODOTTO_ACQUISTATO, PA.STATO_DI_VENDITA, PV.ID_PRODOTTO_VENDITA, PV.ID_CIRCUITO,  TAR.IMPORTO
         FROM CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA, CD_PIANIFICAZIONE PIA
         WHERE PA.DATA_INIZIO = p_data_inizio
         AND PA.DATA_FINE = p_data_fine
         AND PA.FLG_ANNULLATO = 'N'
         AND PA.FLG_SOSPESO = 'N'
         AND PA.COD_DISATTIVAZIONE IS NULL
         AND PA.STATO_DI_VENDITA = 'PRE'
         AND PIA.ID_PIANO = PA.ID_PIANO
         AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
         AND PIA.FLG_ANNULLATO = 'N'
         AND PIA.FLG_SOSPESO = 'N'
         AND PIA.ID_CLIENTE = NVL(p_id_cliente,PIA.ID_CLIENTE)
         AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
         AND PV.FLG_SEGUI_IL_FILM = 'S'
         AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
         AND TAR.DATA_INIZIO <= p_data_inizio
         AND TAR.DATA_FINE >= p_data_fine
         AND TAR.ID_MISURA_PRD_VE = PA.ID_MISURA_PRD_VE
    ) 
    LOOP
        PR_RICALCOLA_TARIFFA_PRODOTTO(PACQ.ID_PRODOTTO_ACQUISTATO);                                       
    END LOOP;
END PR_RICALCOLA_TARIFFA; 



-------------------------------------------------------------------------------------------------
-- Procedura PR_RICALCOLA_TARIFFA_PRODOTTO
--
-- DESCRIZIONE:  Effettua il ricalcolo della tariffa per il prodottosegui il film indicato
--
-- INPUT:  p_id_prodotto_acquistato

--
-- OUTPUT: 
-- REALIZZATORE: Mauro Viel, Altran, Febbraio 2011
--
--  MODIFICHE: Mauro Viel, Altran Giugno 2011 : Inserito l'annullamento delle sale virtuali dopo 
--                                              il ricalcolo della tariffa.
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA_PRODOTTO(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE) IS

v_piani_errati VARCHAR2(1024);
v_importo CD_TARIFFA.IMPORTO%TYPE;
BEGIN
        update cd_prodotto_acquistato
        set flg_ricalcolo_tariffa = 'S'
        where id_prodotto_acquistato = p_id_prodotto_acquistato;
        v_importo := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_TARIFFA_PRODOTTO(P_ID_PRODOTTO_ACQUISTATO);
        PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_TARIFFA_PROD_ACQ(P_ID_PRODOTTO_ACQUISTATO,
                                        v_importo,
                                        v_importo,
                                        'S',
                                        v_piani_errati);
                                        
        --Annullo i comunicati che riferiscono sale virtuali
         
        update cd_comunicato 
        set flg_annullato ='S'
        where id_comunicato in 
        (
            select id_comunicato 
            from  cd_sala sa,
                  cd_comunicato com,
                  cd_cinema ci
            where com.id_sala = sa.id_sala
            and   com.id_prodotto_acquistato = p_id_prodotto_acquistato 
            and   ci.id_cinema = sa.id_cinema
            and   ci.flg_virtuale = 'S'
        );                                
                                       
END PR_RICALCOLA_TARIFFA_PRODOTTO; 


-------------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_PROD_SEGUI_IL_FILM
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista di prodotti "Segui
--              il Film" che corrisponde ai criteri di ricerca inseriti
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--              p_stato_vendita         stato di vendita
--              p_id_spettacolo         id dello spettacolo
--              p_id_cliente            id del cliente
--
-- OUTPUT:
--              lista di
--                  R_PRODOTTO_SEGUI_IL_FILM
--              elenco dei prodotti "Segui il Film" corrispondenti ai criteri
--              di ricerca
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 8 Marzo 2011
-- MODIFICHE:
--              Tommaso D'Anna, Teoresi srl, 22 Marzo 2011
--                  -   Aggiunta chiamata a FU_GET_SPETTACOLO_ASSOCIATO per cambiare il valore di
--                      default
--              Tommaso D'Anna, Teoresi srl, 08 Giugno 2011
--                  -   Aggiunto filtro su GIORNO e FLG_VIRTUALE all'interno della seconda select
--                      per la UNION per fare in modo che anche dopo la prima associazione il valore
--                      mostrato sia MAX_SALE se il giorno non e' stato associato
-------------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_PROD_SEGUI_IL_FILM  (
                                            p_data_inizio   CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                            p_data_fine     CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                            p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                            p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                            p_id_cliente    INTERL_U.COD_INTERL%TYPE
                                        )
                                 RETURN C_PRODOTTO_SEGUI_IL_FILM
IS
C_RETURN  C_PRODOTTO_SEGUI_IL_FILM;
--
BEGIN
    OPEN C_RETURN
    FOR
        SELECT DISTINCT
            ID_PRODOTTO_ACQUISTATO,
            DATA_INIZIO_PROD_ACQ,
            DATA_FINE_PROD_ACQ,
            NUMERO_MASSIMO_SCHERMI,
            STATO_DI_VENDITA,
            ID_PIANO,
            ID_VER_PIANO,
            ID_CLIENTE,
            NOME_CLIENTE,
            ID_SPETTACOLO,
            NOME_SPETTACOLO,
            DATA_INIZIO_SPETTACOLO,
            DATA_FINE_SPETTACOLO,
            FLG_PROTETTO,
            GIORNO,
            SUM( SOGLIA )   OVER ( PARTITION BY ID_PRODOTTO_ACQUISTATO,GIORNO ) 
                AS SOGLIA,
            SUM( ASSEGNATO )OVER ( PARTITION BY ID_PRODOTTO_ACQUISTATO,GIORNO ) 
                AS ASSEGNATO
        FROM
        (
            SELECT DISTINCT
                CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_ACQUISTATO.DATA_INIZIO AS DATA_INIZIO_PROD_ACQ,
                CD_PRODOTTO_ACQUISTATO.DATA_FINE AS DATA_FINE_PROD_ACQ,
                CD_PRODOTTO_ACQUISTATO.NUMERO_MASSIMO_SCHERMI,
                CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA,
                CD_PIANIFICAZIONE.ID_PIANO,
                CD_PIANIFICAZIONE.ID_VER_PIANO,
                INTERL_U.COD_INTERL AS ID_CLIENTE,
                INTERL_U.RAG_SOC_COGN AS NOME_CLIENTE,
                CD_SPETTACOLO.ID_SPETTACOLO,
                CD_SPETTACOLO.NOME_SPETTACOLO,
                CD_SPETTACOLO.DATA_INIZIO AS DATA_INIZIO_SPETTACOLO,
                CD_SPETTACOLO.DATA_FINE AS DATA_FINE_SPETTACOLO,
                CD_SPETTACOLO.FLG_PROTETTO,
                CD_SALA_SEGUI_FILM.GIORNO,
                CD_SALA_SEGUI_FILM.SOGLIA,
                COUNT( ID_SALA ) OVER ( PARTITION BY CD_SALA_SEGUI_FILM.ID_PRODOTTO_ACQUISTATO,CD_SALA_SEGUI_FILM.GIORNO ) 
                    AS ASSEGNATO
            FROM
                CD_PRODOTTO_ACQUISTATO,
                CD_PIANIFICAZIONE,
                INTERL_U,
                CD_SPETTACOLO,
                CD_SALA_SEGUI_FILM,
                CD_PRODOTTO_VENDITA
            -- SEZIONE JOIN --
            WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA    =   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM           =   'S'
            AND CD_PRODOTTO_VENDITA.FLG_ANNULLATO               =   'N'
            AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO            =   'N'
            AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO              =   'N' 
            AND CD_PRODOTTO_ACQUISTATO.ID_PIANO                 =   CD_PIANIFICAZIONE.ID_PIANO
            AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO             =   CD_PIANIFICAZIONE.ID_VER_PIANO 
            AND CD_PIANIFICAZIONE.ID_CLIENTE                    =   INTERL_U.COD_INTERL
            AND CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO            =   CD_SPETTACOLO.ID_SPETTACOLO
            AND CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO   =   CD_SALA_SEGUI_FILM.ID_PRODOTTO_ACQUISTATO
            AND CD_SALA_SEGUI_FILM.FLG_VIRTUALE                 =   'N'
            -- SEZIONE FILTRI --
            AND CD_PRODOTTO_ACQUISTATO.DATA_INIZIO              =   p_data_inizio
            AND CD_PRODOTTO_ACQUISTATO.DATA_FINE                =   p_data_fine
            AND instr(UPPER(nvl(p_stato_vendita, CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)), CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA) > 0
            AND CD_SPETTACOLO.ID_SPETTACOLO                     =   nvl( p_id_spettacolo, CD_SPETTACOLO.ID_SPETTACOLO )
            AND CD_PIANIFICAZIONE.ID_CLIENTE                    =   nvl( p_id_cliente, CD_PIANIFICAZIONE.ID_CLIENTE )
                --UNION
            UNION
                --UNION
            SELECT DISTINCT
                CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_ACQUISTATO.DATA_INIZIO AS DATA_INIZIO_PROD_ACQ,
                CD_PRODOTTO_ACQUISTATO.DATA_FINE AS DATA_FINE_PROD_ACQ,
                CD_PRODOTTO_ACQUISTATO.NUMERO_MASSIMO_SCHERMI,
                CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA,
                CD_PIANIFICAZIONE.ID_PIANO,
                CD_PIANIFICAZIONE.ID_VER_PIANO,
                INTERL_U.COD_INTERL AS ID_CLIENTE,
                INTERL_U.RAG_SOC_COGN AS NOME_CLIENTE,
                CD_SPETTACOLO.ID_SPETTACOLO,
                CD_SPETTACOLO.NOME_SPETTACOLO,
                CD_SPETTACOLO.DATA_INIZIO AS DATA_INIZIO_SPETTACOLO,
                CD_SPETTACOLO.DATA_FINE AS DATA_FINE_SPETTACOLO,
                CD_SPETTACOLO.FLG_PROTETTO,
                CD_COMUNICATO.DATA_EROGAZIONE_PREV 
                    AS GIORNO,
                CASE
                    (   
                        SELECT COUNT(1)
                        FROM CD_SALA_SEGUI_FILM
                        WHERE ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                        AND GIORNO = CD_COMUNICATO.DATA_EROGAZIONE_PREV
                        AND FLG_VIRTUALE = 'N'                        
                    ) 
                    WHEN 
                        0 
                    THEN 
                        CD_PRODOTTO_ACQUISTATO.NUMERO_MASSIMO_SCHERMI
                    ELSE 
                        0
                END
                    AS SOGLIA,
                0 
                    AS ASSEGNATO
            FROM
                    CD_PRODOTTO_ACQUISTATO,
                    CD_PIANIFICAZIONE,
                    INTERL_U,
                    CD_SPETTACOLO,
                    CD_PRODOTTO_VENDITA,
                    CD_COMUNICATO
            -- SEZIONE JOIN --
            WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA    =   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM           =   'S'
            AND CD_PRODOTTO_VENDITA.FLG_ANNULLATO               =   'N'
            AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO            =   'N'
            AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO              =   'N' 
            AND CD_PRODOTTO_ACQUISTATO.ID_PIANO                 =   CD_PIANIFICAZIONE.ID_PIANO
            AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO             =   CD_PIANIFICAZIONE.ID_VER_PIANO 
            AND CD_PIANIFICAZIONE.ID_CLIENTE                    =   INTERL_U.COD_INTERL
            AND CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO            =   CD_SPETTACOLO.ID_SPETTACOLO
            AND CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO   =   CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
            AND CD_COMUNICATO.FLG_ANNULLATO                     =   'N'
            AND CD_COMUNICATO.FLG_SOSPESO                       =   'N' 
            -- SEZIONE FILTRI --
            AND CD_PRODOTTO_ACQUISTATO.DATA_INIZIO              =   p_data_inizio
            AND CD_PRODOTTO_ACQUISTATO.DATA_FINE                =   p_data_fine
            AND instr(UPPER(nvl(p_stato_vendita, CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)), CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA) > 0
            AND CD_SPETTACOLO.ID_SPETTACOLO                     =   nvl( p_id_spettacolo, CD_SPETTACOLO.ID_SPETTACOLO )
            AND CD_PIANIFICAZIONE.ID_CLIENTE                    =   nvl( p_id_cliente, CD_PIANIFICAZIONE.ID_CLIENTE )           
        )
        ORDER BY 
            ID_PRODOTTO_ACQUISTATO, 
            GIORNO
        ;
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_RICERCA_PROD_SEGUI_IL_FILM: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI!');
--
END FU_RICERCA_PROD_SEGUI_IL_FILM;


-------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_DATE_PRODOTTI
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista delle date inizio/fine
--              relative a tutti i prodotti di tipo "Segui il Film"
--
-- INPUT:
--              NOTHING
--
-- OUTPUT:
--              lista di
--                  R_DATE_PRODOTTI
--              elenco delle coppie di date inizio/fine relative a tutti i 
--              prodotti di tipo "Segui il Film"
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 4 Marzo 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATE_PRODOTTI 
                                RETURN C_DATE_PRODOTTI 
IS
C_RETURN C_DATE_PRODOTTI;
BEGIN
    OPEN C_RETURN FOR
        SELECT DISTINCT
            CD_PRODOTTO_ACQUISTATO.DATA_INIZIO,
            CD_PRODOTTO_ACQUISTATO.DATA_FINE
        FROM 
            CD_PRODOTTO_ACQUISTATO,
            CD_PRODOTTO_VENDITA
        WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  =   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND     CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM       =   'S'
        AND     CD_PRODOTTO_VENDITA.FLG_ANNULLATO           =   'N'
        AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        =   'N'
        AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO          =   'N'
        ORDER BY CD_PRODOTTO_ACQUISTATO.DATA_INIZIO DESC;
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_DATE_PRODOTTI: SI E VERIFICATO UN ERRORE!');
END FU_GET_DATE_PRODOTTI;

-------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SALE_GIORNO_IDONEE
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              dei singoli giorni con le sale idonee 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--              p_id_spettacolo         id dello spettacolo
--
-- OUTPUT:
--              lista di
--                  R_NUM_SALE_DATA
--              elenco delle coppie di date / numero sale
--
-- REALIZZATORE:
--              Antonio Colucci, Teoresi srl, 9 Marzo 2011
--  MODIFICHE: 
--              Tommaso D'Anna, Teoresi srl, 8 Giugno 2011
--                  - Inserita DISTINCT in SPETT_SALA_GIORNO per considerare anche i casi
--                  in cui il gestore inserisca due programmazioni identiche nello stesso giorno
--              Tommaso D'Anna, Teoresi srl, 23 Giugno 2011
--                  - Inserito il controllo sul contratto valido
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_SALE_GIORNO_IDONEE(
                                            p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_id_spettacolo CD_PROIEZIONE_SPETT.ID_SPETTACOLO%TYPE
                                   )
                                RETURN C_NUM_SALE_DATA
IS
C_RETURN C_NUM_SALE_DATA;
BEGIN
    OPEN C_RETURN FOR
        SELECT DISTINCT
            DATA_PROIEZIONE,
            SUM( NUM_SALE ) OVER ( PARTITION BY DATA_PROIEZIONE ) 
                AS NUM_SALE
            FROM (
                WITH SPETT_SALA_GIORNO AS
                    (
                        SELECT  CD_PROIEZIONE.ID_SCHERMO,
                                CD_PROIEZIONE.DATA_PROIEZIONE,
                                CD_PROIEZIONE_SPETT.ID_SPETTACOLO,
                                COUNT(DISTINCT ID_SPETTACOLO) OVER (PARTITION BY CD_SCHERMO.ID_SCHERMO,DATA_PROIEZIONE)NUM_SPETT_GIORNO
                        FROM    CD_PROIEZIONE,
                                CD_PROIEZIONE_SPETT,
                                CD_CINEMA_CONTRATTO,
                                CD_CINEMA,
                                CD_CONTRATTO,
                                CD_SALA,
                                CD_SCHERMO
                        WHERE   CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                        AND     CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                        AND     CD_PROIEZIONE_SPETT.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
                        AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                        AND     CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
                        AND     CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                        AND     CD_CINEMA_CONTRATTO.ID_CINEMA = CD_CINEMA.ID_CINEMA
                        AND     CD_CONTRATTO.ID_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CONTRATTO
                        AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE
                    )
                SELECT  DISTINCT
                        SPETT_SALA_GIORNO.DATA_PROIEZIONE,
                        COUNT(DISTINCT ID_SALA) OVER (PARTITION BY DATA_PROIEZIONE,ID_SPETTACOLO) NUM_SALE
                FROM 
                        SPETT_SALA_GIORNO,
                        CD_SCHERMO
                WHERE   SPETT_SALA_GIORNO.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
                AND     SPETT_SALA_GIORNO.NUM_SPETT_GIORNO = 1
                AND     SPETT_SALA_GIORNO.ID_SPETTACOLO = p_id_spettacolo
                    --UNION
                UNION
                    --UNION
                SELECT DISTINCT 
                    DATA_PROIEZIONE,
                    0 AS NUM_SALE
                FROM
                        CD_PROIEZIONE
                WHERE
                        DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                AND     CD_PROIEZIONE.FLG_ANNULLATO = 'N')                  
            ORDER BY DATA_PROIEZIONE;
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_SALE_GIORNO_DISPONIBILI: SI E VERIFICATO UN ERRORE!');
END FU_GET_SALE_GIORNO_IDONEE;

-------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SALE_GIORNO_DISPONIBILI
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              dei singoli giorni con le sale disponibili 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--              p_id_spettacolo         id dello spettacolo
--              p_stato_vendita         lo stato di vendita del prodotto acquistato
--
-- OUTPUT:
--              lista di
--                  R_NUM_SALE_DATA
--              elenco delle coppie di date / numero sale
--
-- REALIZZATORE:
--              Antonio Colucci, Teoresi srl, 9 Marzo 2011
--  MODIFICHE: 
--              Tommaso D'Anna, Teoresi srl, 8 Giugno 2011
--                  - Inserita DISTINCT in SPETT_SALA_GIORNO per considerare anche i casi
--                  in cui il gestore inserisca due programmazioni identiche nello stesso giorno
--              Tommaso D'Anna, Teoresi srl, 23 Giugno 2011
--                  - Inserito il controllo sul contratto valido
--              Tommaso D'Anna, Teoresi srl, 2 Novembre 2011
--                  - Inserita HINT RULE per velocizzare la query
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_SALE_GIORNO_DISPONIBILI(
                                            p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_id_spettacolo CD_PROIEZIONE_SPETT.ID_SPETTACOLO%TYPE,
                                            p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE                                            
                                       )
                                RETURN C_NUM_SALE_DATA
IS
C_RETURN C_NUM_SALE_DATA;
BEGIN
    OPEN C_RETURN FOR
        SELECT /*+ RULE*/ DISTINCT
            DATA_PROIEZIONE,
            SUM( NUM_SALE ) OVER ( PARTITION BY DATA_PROIEZIONE ) 
                AS NUM_SALE
            FROM (    
                WITH SPETT_SALA_GIORNO AS
                    (
                    SELECT  CD_PROIEZIONE.ID_SCHERMO,
                            CD_PROIEZIONE.DATA_PROIEZIONE,
                            CD_PROIEZIONE_SPETT.ID_SPETTACOLO,
                            COUNT(DISTINCT ID_SPETTACOLO) OVER (PARTITION BY CD_SCHERMO.ID_SCHERMO,DATA_PROIEZIONE)NUM_SPETT_GIORNO
                    FROM    CD_PROIEZIONE,
                            CD_PROIEZIONE_SPETT,
                            CD_CINEMA_CONTRATTO,
                            CD_CINEMA,
                            CD_CONTRATTO,
                            CD_SALA,
                            CD_SCHERMO
                    WHERE   CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                    AND     CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                    AND     CD_PROIEZIONE_SPETT.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
                    AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                    AND     CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
                    AND     CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                    AND     CD_CINEMA_CONTRATTO.ID_CINEMA = CD_CINEMA.ID_CINEMA
                    AND     CD_CONTRATTO.ID_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CONTRATTO
                    AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE                    
                    )
                SELECT DISTINCT
                        SPETT_SALA_GIORNO.DATA_PROIEZIONE,
                        --CD_SCHERMO.ID_SALA
                        COUNT(DISTINCT CD_SCHERMO.ID_SALA) OVER (PARTITION BY DATA_PROIEZIONE,ID_SPETTACOLO) NUM_SALE                
                FROM 
                SPETT_SALA_GIORNO,
                (
                    select
                    id_sala,
                    DATA_EROGAZIONE_PREV,
                    min(disponibilita) over (partition by id_sala) disponibilita,
                    540 TOT_GIORNO
                     from(
                       SELECT DISTINCT
                                 ID_SALA,
                                 CD_COMUNICATO.DATA_EROGAZIONE_PREV,
                                 (540 - SUM(CD_COEFF_CINEMA.DURATA) OVER (PARTITION BY CD_BREAK.ID_PROIEZIONE)) AS DISPONIBILITA
                        FROM    CD_COMUNICATO,
                                CD_PRODOTTO_ACQUISTATO,
                                CD_FORMATO_ACQUISTABILE,
                                CD_COEFF_CINEMA,
                                CD_BREAK 
                        WHERE   CD_COMUNICATO.FLG_ANNULLATO = 'N'
                        AND     CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
                        AND     CD_COMUNICATO.FLG_SOSPESO = 'N'
                        AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
                        AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                        AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
                        AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
                        AND     instr(CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA,p_stato_vendita)>0
                        AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO = CD_FORMATO_ACQUISTABILE.ID_FORMATO
                        AND     CD_FORMATO_ACQUISTABILE.ID_COEFF = CD_COEFF_CINEMA.ID_COEFF
                        AND     CD_COMUNICATO.ID_BREAK = CD_BREAK.ID_BREAK
                        union
                        select distinct
                            cd_sala.id_sala,
                            data_proiezione DATA_EROGAZIONE_PREV,
                            540 as disponibilita
                    	from
                    		cd_sala,
                            cd_cinema,
                            cd_schermo,
                            cd_proiezione
                        where
                            cd_proiezione.data_proiezione between p_data_inizio AND p_data_fine
                        and cd_proiezione.flg_annullato = 'N'
                        and cd_proiezione.id_schermo = cd_schermo.id_schermo
                        and cd_schermo.id_sala = cd_sala.id_sala
                        and cd_sala.id_cinema = cd_cinema.id_cinema
                        and cd_cinema.flg_virtuale = 'N'
                    )
                )SALE_GIORNO_DISPONIBILITA,
                CD_SCHERMO
                WHERE   SPETT_SALA_GIORNO.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
                AND     SPETT_SALA_GIORNO.NUM_SPETT_GIORNO = 1
                AND     SPETT_SALA_GIORNO.ID_SPETTACOLO = p_id_spettacolo
                AND     CD_SCHERMO.ID_SALA = SALE_GIORNO_DISPONIBILITA.ID_SALA
                AND     SALE_GIORNO_DISPONIBILITA.DISPONIBILITA <= SALE_GIORNO_DISPONIBILITA.TOT_GIORNO
                    --UNION
                UNION
                    --UNION
                SELECT DISTINCT 
                    DATA_PROIEZIONE,
                    0 AS NUM_SALE
                FROM
                        CD_PROIEZIONE
                WHERE
                        DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                AND     CD_PROIEZIONE.FLG_ANNULLATO = 'N')                  
            ORDER BY DATA_PROIEZIONE
            ;
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_SALE_GIORNO_DISPONIBILI: SI E VERIFICATO UN ERRORE!');
END FU_GET_SALE_GIORNO_DISPONIBILI;

-------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SPETT_SEGUI_IL_FILM
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              degli spettacoli relativi a prodotti di tipo "Segui il Film" 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--
-- OUTPUT:
--              lista di
--                  R_SPETTACOLO
--              elenco degli spettacoli 
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 11 Marzo 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_SPETT_SEGUI_IL_FILM(
                                        p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                        p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE
                                   )
                                RETURN C_SPETTACOLO
IS
C_RETURN C_SPETTACOLO;
BEGIN
    OPEN C_RETURN FOR
            SELECT DISTINCT
                CD_SPETTACOLO.ID_SPETTACOLO,
                CD_SPETTACOLO.NOME_SPETTACOLO,
                CD_SPETTACOLO.DATA_INIZIO,
                CD_SPETTACOLO.DATA_FINE,    
                CD_SPETTACOLO.DURATA_SPETTACOLO,
                CD_SPETTACOLO.FLG_PROTETTO,
                CD_SPETTACOLO.ID_DISTRIBUTORE 
            FROM 
                CD_SPETTACOLO,
                CD_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_VENDITA
            WHERE   CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM       =   'S'
            AND     CD_PRODOTTO_VENDITA.FLG_ANNULLATO           =   'N'
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  =   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        =   'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO          =   'N'
            AND     CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO        =   CD_SPETTACOLO.ID_SPETTACOLO
            AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO          =   p_data_inizio
            AND     CD_PRODOTTO_ACQUISTATO.DATA_FINE            =   p_data_fine
            ;
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_SPETT_SEGUI_IL_FILM: SI E VERIFICATO UN ERRORE!');
END FU_GET_SPETT_SEGUI_IL_FILM;

-------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CLIENTI_SEGUI_IL_FILM
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              dei clienti relativi a prodotti di tipo "Segui il Film" 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--
-- OUTPUT:
--              lista di
--                  R_CLIENTE
--              elenco dei clienti
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 11 Marzo 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_CLIENTI_SEGUI_IL_FILM(
                                        p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                        p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE
                                   )
                                RETURN C_CLIENTE
IS
C_RETURN C_CLIENTE;
BEGIN
    OPEN C_RETURN FOR 
            SELECT DISTINCT
                INTERL_U.COD_INTERL,
                INTERL_U.RAG_SOC_BR_NOME,
                INTERL_U.RAG_SOC_COGN,
                INTERL_U.INDIRIZZO,
                INTERL_U.LOCALITA,
                INTERL_U.CAP,
                INTERL_U.NAZIONE,
                INTERL_U.COD_FISC,
                INTERL_U.NUM_CIVICO,
                INTERL_U.PROVINCIA,
                INTERL_U.SESSO,
                INTERL_U.AREA,
                INTERL_U.SEDE,
                INTERL_U.NOME,
                INTERL_U.COGNOME
            FROM 
                CD_SPETTACOLO,
                CD_PRODOTTO_ACQUISTATO,
                CD_PRODOTTO_VENDITA,
                INTERL_U,
                CD_PIANIFICAZIONE
            WHERE   CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM       =   'S'
            AND     CD_PRODOTTO_VENDITA.FLG_ANNULLATO           =   'N'
            AND     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA  =   CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
            AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO        =   'N'
            AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO          =   'N'
            AND     CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO        =   CD_SPETTACOLO.ID_SPETTACOLO
            AND     CD_PRODOTTO_ACQUISTATO.ID_PIANO             =   CD_PIANIFICAZIONE.ID_PIANO
            AND     CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO         =   CD_PIANIFICAZIONE.ID_VER_PIANO            
            AND     CD_PIANIFICAZIONE.ID_CLIENTE                =   INTERL_U.COD_INTERL
            AND     CD_PRODOTTO_ACQUISTATO.DATA_INIZIO          =   p_data_inizio
            AND     CD_PRODOTTO_ACQUISTATO.DATA_FINE            =   p_data_fine
            ;
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_CLIENTI_SEGUI_IL_FILM: SI E VERIFICATO UN ERRORE!');
END FU_GET_CLIENTI_SEGUI_IL_FILM;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_SALE_GIORNO_ASSOCIATE
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalla data inserita in input)
--              delle sale associate per il prodotto acquistato selezionato
--
-- INPUT:
--              p_data_proiezione           data di ricerca
--              p_id_prodotto_acquistato    l'id del prodotto acquistato
--
-- OUTPUT:
--              lista di
--                  R_SALA
--              elenco delle sale
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 25 Luglio 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_DETT_SALE_GIORNO_ASSOCIATE (
                                            p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                            p_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE
                                        )
                                RETURN C_SALA
IS
C_RETURN C_SALA;
BEGIN
    OPEN C_RETURN FOR
        SELECT
            CD_CINEMA.ID_CINEMA,
            CD_SALA.ID_SALA,
            ( CD_CINEMA.NOME_CINEMA || ' - ' || CD_COMUNE.COMUNE ) AS NOME_CINEMA,
            CD_SALA.NOME_SALA        
        FROM 
            CD_SALA_SEGUI_FILM,
            CD_SALA,
            CD_CINEMA,
            CD_COMUNE
        WHERE   CD_SALA_SEGUI_FILM.ID_PRODOTTO_ACQUISTATO   = p_id_prodotto_acquistato
        AND     CD_SALA_SEGUI_FILM.GIORNO                   = p_data_proiezione
        AND     CD_SALA_SEGUI_FILM.FLG_VIRTUALE             = 'N'
        AND     CD_SALA_SEGUI_FILM.ID_SALA                  = CD_SALA.ID_SALA 
        AND     CD_SALA.ID_CINEMA                           = CD_CINEMA.ID_CINEMA
        AND     CD_CINEMA.ID_COMUNE                         = CD_COMUNE.ID_COMUNE
        ORDER BY
            NOME_CINEMA,
            CD_SALA.NOME_SALA;       
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_DETT_SALE_GIORNO_ASSOCIATE: SI E VERIFICATO UN ERRORE!');
END FU_DETT_SALE_GIORNO_ASSOCIATE;

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_SALE_GIORNO_DISPONIB
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalla data inserita in input)
--              delle sale disponibili per lo spettacolo selezionato
--
-- INPUT:
--              p_data_proiezione           data di ricerca
--              p_id_spettacolo             l'id dello spettacolo
--              p_stato_vendita             lo stato di vendita del prodotto acquistato
--
-- OUTPUT:
--              lista di
--                  R_SALA
--              elenco delle sale
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 26 Luglio 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_DETT_SALE_GIORNO_DISPONIB(
                                        p_data_proiezione   CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                        p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                        p_stato_vendita     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE
                                     )
                                    RETURN C_SALA
IS
C_RETURN C_SALA;
BEGIN
    OPEN C_RETURN FOR 
        WITH SPETT_SALA_GIORNO AS
            (
            SELECT  CD_PROIEZIONE.ID_SCHERMO,
                    CD_PROIEZIONE.DATA_PROIEZIONE,
                    CD_PROIEZIONE_SPETT.ID_SPETTACOLO,
                    COUNT(DISTINCT ID_SPETTACOLO) 
                        OVER (PARTITION BY CD_SCHERMO.ID_SCHERMO,DATA_PROIEZIONE) NUM_SPETT_GIORNO
            FROM    CD_PROIEZIONE,
                    CD_PROIEZIONE_SPETT,
                    CD_CINEMA_CONTRATTO,
                    CD_CINEMA,
                    CD_CONTRATTO,
                    CD_SALA,
                    CD_SCHERMO
            WHERE   CD_PROIEZIONE.DATA_PROIEZIONE       = p_data_proiezione
            AND     CD_PROIEZIONE.FLG_ANNULLATO         = 'N'
            AND     CD_PROIEZIONE_SPETT.ID_PROIEZIONE   = CD_PROIEZIONE.ID_PROIEZIONE
            AND     CD_SCHERMO.ID_SCHERMO               = CD_PROIEZIONE.ID_SCHERMO
            AND     CD_SCHERMO.ID_SALA                  = CD_SALA.ID_SALA
            AND     CD_SALA.ID_CINEMA                   = CD_CINEMA.ID_CINEMA
            AND     CD_CINEMA_CONTRATTO.ID_CINEMA       = CD_CINEMA.ID_CINEMA
            AND     CD_CONTRATTO.ID_CONTRATTO           = CD_CINEMA_CONTRATTO.ID_CONTRATTO
            AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE                  
            )
        SELECT DISTINCT
            CD_CINEMA.ID_CINEMA,
            CD_SALA.ID_SALA,
            ( CD_CINEMA.NOME_CINEMA || ' - ' || CD_COMUNE.COMUNE ) AS NOME_CINEMA,
            CD_SALA.NOME_SALA  
        FROM 
            SPETT_SALA_GIORNO,
            (
                SELECT
                ID_SALA,
                DATA_EROGAZIONE_PREV,
                MIN(DISPONIBILITA) OVER (PARTITION BY ID_SALA) DISPONIBILITA,
                540 TOT_GIORNO
                 FROM(
                   SELECT DISTINCT
                             ID_SALA,
                             CD_COMUNICATO.DATA_EROGAZIONE_PREV,
                             (540 - SUM(CD_COEFF_CINEMA.DURATA) 
                                OVER (PARTITION BY CD_BREAK.ID_PROIEZIONE)) AS DISPONIBILITA
                    FROM    CD_COMUNICATO,
                            CD_PRODOTTO_ACQUISTATO,
                            CD_FORMATO_ACQUISTABILE,
                            CD_COEFF_CINEMA,
                            CD_BREAK 
                    WHERE   CD_COMUNICATO.FLG_ANNULLATO                                         = 'N'
                    AND     CD_COMUNICATO.COD_DISATTIVAZIONE                                    IS NULL
                    AND     CD_COMUNICATO.FLG_SOSPESO                                           = 'N'
                    AND     CD_COMUNICATO.DATA_EROGAZIONE_PREV                                  = p_data_proiezione
                    AND     CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO                                = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                    AND     CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO                                = 'N'
                    AND     CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO                                  = 'N'
                    AND     instr(CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA, p_stato_vendita )    > 0
                    AND     CD_PRODOTTO_ACQUISTATO.ID_FORMATO                                   = CD_FORMATO_ACQUISTABILE.ID_FORMATO
                    AND     CD_FORMATO_ACQUISTABILE.ID_COEFF                                    = CD_COEFF_CINEMA.ID_COEFF
                    AND     CD_COMUNICATO.ID_BREAK                                              = CD_BREAK.ID_BREAK
                    UNION
                    SELECT DISTINCT
                        CD_SALA.ID_SALA,
                        DATA_PROIEZIONE DATA_EROGAZIONE_PREV,
                        540 AS DISPONIBILITA
                	FROM
                		CD_SALA,
                        CD_CINEMA,
                        CD_SCHERMO,
                        CD_PROIEZIONE
                    WHERE
                        CD_PROIEZIONE.DATA_PROIEZIONE   = p_data_proiezione
                    AND CD_PROIEZIONE.FLG_ANNULLATO     = 'N'
                    AND CD_PROIEZIONE.ID_SCHERMO        = CD_SCHERMO.ID_SCHERMO
                    AND CD_SCHERMO.ID_SALA              = CD_SALA.ID_SALA
                    AND CD_SALA.ID_CINEMA               = CD_CINEMA.ID_CINEMA
                    AND CD_CINEMA.FLG_VIRTUALE          = 'N'
                )
            ) SALE_GIORNO_DISPONIBILITA,
            CD_SCHERMO,
            CD_SALA,
            CD_CINEMA,
            CD_COMUNE            
        WHERE   SPETT_SALA_GIORNO.ID_SCHERMO            =   CD_SCHERMO.ID_SCHERMO
        AND     SPETT_SALA_GIORNO.NUM_SPETT_GIORNO      =   1
        AND     SPETT_SALA_GIORNO.ID_SPETTACOLO         =   p_id_spettacolo
        AND     CD_SCHERMO.ID_SALA                      =   SALE_GIORNO_DISPONIBILITA.ID_SALA
        AND     CD_SCHERMO.ID_SALA                      =   CD_SALA.ID_SALA 
        AND     CD_SALA.ID_CINEMA                       =   CD_CINEMA.ID_CINEMA
        AND     CD_CINEMA.ID_COMUNE                         = CD_COMUNE.ID_COMUNE                        
        AND     SALE_GIORNO_DISPONIBILITA.DISPONIBILITA <=  SALE_GIORNO_DISPONIBILITA.TOT_GIORNO
        ORDER BY
            NOME_CINEMA,
            CD_SALA.NOME_SALA;          
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_DETT_SALE_GIORNO_DISPONIB: SI E VERIFICATO UN ERRORE!');
END FU_DETT_SALE_GIORNO_DISPONIB;                                     
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_SALE_GIORNO_IDONEE
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalla data inserita in input)
--              delle sale disponibili per lo spettacolo selezionato
--
-- INPUT:
--              p_data_proiezione           data di ricerca
--              p_id_spettacolo             l'id dello spettacolo
--              p_stato_vendita             lo stato di vendita del prodotto acquistato
--
-- OUTPUT:
--              lista di
--                  R_SALA
--              elenco delle sale
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 26 Luglio 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_DETT_SALE_GIORNO_IDONEE(
                                        p_data_proiezione   CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                        p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE
                                     )
                                    RETURN C_SALA
IS
C_RETURN C_SALA;
BEGIN
    OPEN C_RETURN FOR 
        WITH SPETT_SALA_GIORNO AS
            (
                SELECT  CD_PROIEZIONE.ID_SCHERMO,
                        CD_PROIEZIONE.DATA_PROIEZIONE,
                        CD_PROIEZIONE_SPETT.ID_SPETTACOLO,
                        COUNT(DISTINCT ID_SPETTACOLO) 
                            OVER (PARTITION BY CD_SCHERMO.ID_SCHERMO,DATA_PROIEZIONE) NUM_SPETT_GIORNO
                FROM    CD_PROIEZIONE,
                        CD_PROIEZIONE_SPETT,
                        CD_CINEMA_CONTRATTO,
                        CD_CINEMA,
                        CD_CONTRATTO,
                        CD_SALA,
                        CD_SCHERMO
                WHERE   CD_PROIEZIONE.DATA_PROIEZIONE       = p_data_proiezione
                AND     CD_PROIEZIONE.FLG_ANNULLATO         = 'N'
                AND     CD_PROIEZIONE_SPETT.ID_PROIEZIONE   = CD_PROIEZIONE.ID_PROIEZIONE
                AND     CD_SCHERMO.ID_SCHERMO               = CD_PROIEZIONE.ID_SCHERMO
                AND     CD_SCHERMO.ID_SALA                  = CD_SALA.ID_SALA
                AND     CD_SALA.ID_CINEMA                   = CD_CINEMA.ID_CINEMA
                AND     CD_CINEMA_CONTRATTO.ID_CINEMA       = CD_CINEMA.ID_CINEMA
                AND     CD_CONTRATTO.ID_CONTRATTO           = CD_CINEMA_CONTRATTO.ID_CONTRATTO
                AND     CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE
            )
        SELECT DISTINCT
                CD_CINEMA.ID_CINEMA,
                CD_SALA.ID_SALA,
                ( CD_CINEMA.NOME_CINEMA || ' - ' || CD_COMUNE.COMUNE ) AS NOME_CINEMA,
                CD_SALA.NOME_SALA 
        FROM 
                SPETT_SALA_GIORNO,
                CD_SCHERMO,
                CD_SALA,
                CD_CINEMA,
                CD_COMUNE
        WHERE   SPETT_SALA_GIORNO.ID_SCHERMO            =   CD_SCHERMO.ID_SCHERMO
        AND     SPETT_SALA_GIORNO.NUM_SPETT_GIORNO      =   1
        AND     SPETT_SALA_GIORNO.ID_SPETTACOLO         =   p_id_spettacolo 
        AND     CD_SCHERMO.ID_SALA                      =   CD_SALA.ID_SALA 
        AND     CD_SALA.ID_CINEMA                       =   CD_CINEMA.ID_CINEMA
        AND     CD_CINEMA.ID_COMUNE                         = CD_COMUNE.ID_COMUNE                     
        ORDER BY
            NOME_CINEMA,
            CD_SALA.NOME_SALA;                 
    RETURN C_RETURN;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_DETT_SALE_GIORNO_IDONEE: SI E VERIFICATO UN ERRORE!');
END FU_DETT_SALE_GIORNO_IDONEE;
--
END PA_CD_SEGUI_IL_FILM_ESCLUSIVO; 
/

