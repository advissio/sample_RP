CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_NUOVO_TARGET AS

-------------------------------------------------------------------------------------------------
-- PROCEDURE pr_agg_numero_sale_idonee_disp
--
-- INPUT: p_id_prodotto_acquistato  opzionale default null
--        p_data_inizio data inizio ricerca
--        p_data_fine data fine ricerca
--        p_id_target target da ricercare
--        p_esclusivo opzinale default 'S'
--        p_data_soglia data soglia di ricerca per il prelievo del dato dalla tavola di storico (cd_sala_target) o dal dato in linea.
--
--
-- DESCRIZIONE: Aggiorna il numero di sale idonne  disponibili sulla tavola di appoggio cd_sala_target dalla p_data_soglia in poi il cui default e la data di sistema.
--              In questo modo non verranno alterate le disponibilita nel passato. 
--
-- REALIZZATORE: Mauro Viel, Altran Italia, 6 Dicembre 2011
--
--  MODIFICHE: 

procedure pr_agg_numero_sale_idonee_disp(   p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                            p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                            p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                            p_data_soglia            date default trunc(sysdate))is
v_data_soglia  date := p_data_soglia; 
v_durata_break number:= 540.5;                                          
begin

select sum(durata_secondi)+0.5 into
v_durata_break
from  cd_tipo_break
where id_tipo_break in (1,2);  

if p_data_soglia  < p_data_inizio then
    v_data_soglia := p_data_inizio;
end if;
for sale in( 
   select distinct  max(NUM_SALE) over (partition by data_proiezione) AS num_sale_idonee_disp, data_proiezione
   from
   (
   select distinct
   data_proiezione,
   count(id_sala) over (partition by data_proiezione) num_sale
   from
   (    with sala_affollamento as
        (
        select
            distinct
            id_sala,  
            min(disponibilita) over (partition by id_sala) as affollamento
            from
            (
            select   distinct
                     cd_comunicato.id_sala,
                     (v_durata_break--(sum(distinct cd_tipo_break.durata_secondi) over (partition by cd_break.id_proiezione)
                     - 
                     sum (cd_coeff_cinema.durata) over (partition by cd_break.id_proiezione)) as disponibilita
            from    cd_sala,cd_cinema,
                    cd_comunicato,
                    cd_prodotto_acquistato,
                    cd_formato_acquistabile,
                    cd_coeff_cinema,
                    cd_tipo_break,
                    cd_break 
            where   cd_comunicato.flg_annullato = 'N'
            and     cd_comunicato.cod_disattivazione is null
            and     cd_comunicato.flg_sospeso = 'N'
            and     cd_comunicato.data_erogazione_prev between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine) --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
            and     cd_comunicato.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
            and     cd_prodotto_acquistato.stato_di_vendita = 'PRE'
            and     cd_prodotto_acquistato.id_formato = cd_formato_acquistabile.id_formato
            and     cd_formato_acquistabile.id_coeff = cd_coeff_cinema.id_coeff
            and     cd_comunicato.id_break = cd_break.id_break
            and     cd_break.id_tipo_break = cd_tipo_break.id_tipo_break
            and     cd_tipo_break.flg_annullato = 'N'
            and     (cd_tipo_break.data_fine is null or cd_tipo_break.data_fine> trunc(sysdate))
            and     cd_tipo_break.id_tipo_break  in (1,2)
            and     cd_comunicato.id_sala = cd_sala.id_sala
            and     cd_cinema.id_cinema = cd_sala.id_cinema
            and     cd_cinema.flg_virtuale = 'N'
            union
            select id_sala,v_durata_break as disponibilita
            from
                cd_sala,
                cd_cinema
            where
                cd_sala.id_cinema = cd_cinema.id_cinema
            and cd_cinema.flg_virtuale = 'N'
            )
        )
       select bacino_sale.id_sala, data_proiezione,affollamento as disponibilita
       from 
       (
        select
          distinct sa.ID_SALA,pro.data_proiezione
        from
          cd_contratto con,
          cd_cinema_contratto cc,
          cd_cinema cin,
          cd_sala sa,
          cd_schermo sch,
          cd_target tar,
          cd_spett_target spt,
          cd_spettacolo spe,
          cd_proiezione_spett ps,
          cd_proiezione pro
        where
        --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
              pro.DATA_PROIEZIONE between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine)  
          and pro.FLG_ANNULLATO = 'N'
          and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
          and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
          and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
          and tar.ID_TARGET = spt.id_target
          and tar.id_target = p_id_target               -- filtro target
          and sch.ID_SCHERMO = pro.ID_SCHERMO
          and sa.ID_SALA = sch.ID_SALA
          and sa.FLG_ANNULLATO = 'N'
          and cin.ID_CINEMA = sa.ID_CINEMA
          and cc.ID_CINEMA = cin.ID_CINEMA
          and con.ID_CONTRATTO = cc.ID_CONTRATTO
          and pro.DATA_PROIEZIONE BETWEEN con.DATA_INIZIO AND con.DATA_FINE
          and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
          (select 1
           from cd_proiezione_spett ps2,
                cd_proiezione pro2
           where pro2.ID_SCHERMO = sch.ID_SCHERMO
             and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
             and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
             and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                    and p_id_target not in               -- filtro target 
                    (select spt2.id_target
                     from cd_spett_target spt2
                     where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                    )
             and p_esclusivo = 'S'                 -- filtro programmazione esclusiva
          )
        )bacino_sale,sala_affollamento
        where sala_affollamento.id_sala = bacino_sale.id_sala
    )
    where disponibilita > 0
    UNION
    SELECT DISTINCT pro.DATA_PROIEZIONE, 0
    from cd_sala sa, 
        cd_schermo sch, cd_proiezione pro
    where  sch.ID_SALA = sa.ID_SALA
    and sa.FLG_ANNULLATO = 'N'
    and sa.FLG_VISIBILE = 'S'
    and pro.ID_SCHERMO = sch.ID_SCHERMO
    and pro.DATA_PROIEZIONE between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine)
    )
)
loop
    update  cd_sala_target
    set     NUM_SALE_DISP = sale.num_sale_idonee_disp
    where   id_prodotto_acquistato =  p_id_prodotto_acquistato
    and     giorno = sale.data_proiezione;
end loop;
end pr_agg_numero_sale_idonee_disp;


-------------------------------------------------------------------------------------------------
-- PROCEDURE pr_aggiorna_numero_sale_idonee
--
-- INPUT: p_id_prodotto_acquistato  opzionale default null
--        p_data_inizio data inizio ricerca
--        p_data_fine data fine ricerca
--        p_id_target target da ricercare
--        p_esclusivo opzinale default 'S'
--        p_data_soglia data soglia di ricerca per il prelievo del dato dalla tavola di storico (cd_sala_target) o dal dato in linea.
--
--
-- DESCRIZIONE: Aggiorna il numero di sale idonne sulla tavola di appoggio cd_sala_target dalla p_data_soglia in poi il cui default e la data di sistema.
--              In questo modo non verranno alterate le disponibilita nel passato
--
-- REALIZZATORE: Mauro Viel, Altran Italia, 6 Dicembre 2011
--
--  MODIFICHE: 

procedure pr_aggiorna_numero_sale_idonee(
                                            p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                            p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                            p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                            p_data_soglia            date default trunc(sysdate))is
v_data_soglia  date := p_data_soglia;                                            
begin
if p_data_soglia  < p_data_inizio then
    v_data_soglia := p_data_inizio;
end if;
for sale in 
    (
        select  distinct count(id_sala)  over (partition by  data_proiezione) as num_sale_idonee, data_proiezione
        from
        (                   
             select
              distinct sa.ID_SALA,pro.data_proiezione
            from
              cd_contratto con,
              cd_cinema_contratto cc,
              cd_cinema cin,
              cd_sala sa,
              cd_schermo sch,
              cd_target tar,
              cd_spett_target spt,
              cd_spettacolo spe,
              cd_proiezione_spett ps,
              cd_proiezione pro
            where
            --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
                  pro.DATA_PROIEZIONE between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine)  
              and pro.FLG_ANNULLATO = 'N'
              and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
              and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
              and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
              and tar.ID_TARGET = spt.id_target
              and tar.id_target = p_id_target               -- filtro target
              and sch.ID_SCHERMO = pro.ID_SCHERMO
              and sa.ID_SALA = sch.ID_SALA
              and sa.FLG_ANNULLATO = 'N'
              and cin.ID_CINEMA = sa.ID_CINEMA
              and cc.ID_CINEMA = cin.ID_CINEMA
              and con.ID_CONTRATTO = cc.ID_CONTRATTO
              and pro.DATA_PROIEZIONE BETWEEN con.DATA_INIZIO AND con.DATA_FINE
              and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
              (select 1
               from cd_proiezione_spett ps2,
                    cd_proiezione pro2
               where pro2.ID_SCHERMO = sch.ID_SCHERMO
                 and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
                 and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
                 and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                        and p_id_target not in               -- filtro target 
                        (select spt2.id_target
                         from cd_spett_target spt2
                         where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                        )
                 and p_esclusivo = 'S'                 -- filtro programmazione esclusiva
              )
        )                    
    )
loop
    update  cd_sala_target
    set     NUM_SALE_IDONEE = sale.num_sale_idonee
    where   id_prodotto_acquistato =  p_id_prodotto_acquistato
    and     giorno = sale.data_proiezione;
end loop;
end pr_aggiorna_numero_sale_idonee;
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_GESTISCI_PRODOTTO
--
-- DESCRIZIONE:  Procedura che permette di gestire il singolo prodotto target
--              secondo in parametri di input passati
--
-- OPERAZIONI:
--   1)Recupero le informaizoni caratterizzanti il prodotto_acquistato passato come parametro
--   2)Verifico che il prodotto in esame sia stato gia trattato 
--      (questo in funzione della presenza di record nella tavola CD_SALA_TARGET )
--      in caso contrario creo elementi in tavola
--   3)Invoco procedura di disassociazione sale non piu idonee
--   4)Se il valore di soglia impostato e diverso da null
--     Invoco procedura per disassociare sale fino al raggiungimento della soglia.
--      Se anche il nuovo valore di soglia fosse maggiore di quello preesistente, 
--      la procedura non farebbe nulla
--     Aggiorno valore di soglia nella tavola di gestione prodoto target
--   5)Invoco procedura di associazione sala
--   6)Inserisco tracciatura della modalita si scelta delle sale esclusiva parziale
--   7)Aggiorno Colonne di denormalizzazione sale idonee e sale idonee disp.
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
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 18 Febbraio 2011  ???
--
--  MODIFICHE:  Mauro Viel Altran Italia, 13/12/2012 : inserita la nvl sul flg_esclusivo
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
v_flg_esclusivo         cd_prodotto_acquistato.flg_esclusivo%type;   
v_id_target             number;           
  begin
    P_ESITO := 1;
    SAVEPOINT SP_GESTISCI_PRODOTTO;
    /*verifico che sia stato gia trattato (presenza nella tavola DI GESTIONE)
        in caso contrario creo
      DOPO DI CHE
        disassocio eventuali sale non piu idonee
        associo o disassocio fino a soglia in base al
      */
    select  data_inizio,data_fine,nvl(flg_esclusivo,'S'),id_target
    into    v_data_inizio,v_data_fine,v_flg_esclusivo,v_id_target
    from    cd_prodotto_acquistato,cd_prodotto_vendita
    where   cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
    and     cd_prodotto_vendita.id_prodotto_vendita = cd_prodotto_acquistato.id_prodotto_vendita;
--    
    select  count(id_prodotto_acquistato)
    into    v_num_prod_trattati
    from    cd_sala_target
    where   id_prodotto_acquistato = p_id_prodotto_acquistato
    and     giorno = p_giorno;
    if(v_num_prod_trattati = 0)then
        null;
        /*Il prodotto non e stato mai trattato quindi 
          prima di proseguire popolo tavola.*/
        PR_POPOLA_TAVOLA(p_id_prodotto_acquistato,p_giorno,p_giorno,p_soglia,v_esito_operazione);
    end if;
    PR_DISASSOCIA_SALE_NON_IDONEE(p_id_prodotto_acquistato,v_id_target,p_giorno,v_esito_operazione);
    if(p_soglia is not null)then
        /*Anche se soglia new e maggiore di soglia old la chiamo ugualmente
        nella peggiore delle ipotesi non fa nulla*/
    PR_DISASSOCIA_FINO_A_SOGLIA(p_id_prodotto_acquistato,p_giorno,p_soglia,v_esito_operazione);
        /*aggiorno valore della soglia nella tavola del prodotto*/
        update  cd_sala_target
        set     soglia = p_soglia,
                flg_esclusivo = v_flg_esclusivo
        where   id_prodotto_acquistato = p_id_prodotto_acquistato
        and     giorno = p_giorno;
    else
        /*recupero soglia attuale prima di associare altrimenti passerei null*/
        select distinct soglia into v_soglia
        from cd_sala_target
        where id_prodotto_acquistato = p_id_prodotto_acquistato
        and   giorno = p_giorno;
    end if;
    PR_ASSOCIA_SALE(p_id_prodotto_acquistato,v_id_target,p_giorno,nvl(p_soglia,v_soglia),v_esito_operazione);
    PR_AGGIORNA_NUMERO_SALE_IDONEE(p_id_prodotto_acquistato,p_giorno,p_giorno,v_id_target,v_flg_esclusivo,trunc(sysdate));
    PR_AGG_NUMERO_SALE_IDONEE_DISP(p_id_prodotto_acquistato,p_giorno,p_giorno,v_id_target,v_flg_esclusivo,trunc(sysdate));
    p_esito := v_esito_operazione;
    EXCEPTION
       WHEN OTHERS THEN
       P_ESITO := -2;
       RAISE_APPLICATION_ERROR(-20016, 'PROCEDURA PR_GESTISCI_PRODOTTO: SI E VERIFICATO UN ERRORE:'||SQLERRM);
       ROLLBACK TO SP_GESTISCI_PRODOTTO;
 end PR_GESTISCI_PRODOTTO;
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_AGGIORNA_PRODOTTO
--
-- DESCRIZIONE:  Procedura richiamata tramite job_db che si occupera di 
--              aggiornare le sale associate per tutti i prodotti TARGET
--              in corso alla data di esecuzione 
--
-- OPERAZIONI:
--   1)Recupero di tutti i prodotti TARGET che sono in corso alla
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
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 5 Dicembre 2011
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
    /*Recupero tutti i prodotti target validi alla data di ricerca*/
    for elenco_prodotti in
    (
        select  cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO,
                cd_prodotto_acquistato.DATA_INIZIO,
                cd_prodotto_acquistato.DATA_FINE,
                cd_prodotto_vendita.id_target
        from    cd_prodotto_acquistato,
                cd_prodotto_vendita
        where   p_giorno between cd_prodotto_acquistato.data_inizio and cd_prodotto_acquistato.data_fine
        and     cd_prodotto_acquistato.flg_annullato = 'N'
        and     cd_prodotto_acquistato.flg_sospeso = 'N'
        and     cd_prodotto_acquistato.STATO_DI_VENDITA = 'PRE'
        and     cd_prodotto_acquistato.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita
        and     cd_prodotto_vendita.id_target is not null
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
        from    cd_sala_target
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
                        cd_sala_target.id_prodotto_acquistato,
                        cd_prodotto_acquistato.id_spettacolo,
                        cd_sala_target.soglia,
                        cd_sala_target.giorno
                from    
                        cd_sala_target,
                        cd_prodotto_acquistato
                where   cd_sala_target.id_prodotto_acquistato = elenco_prodotti.ID_PRODOTTO_ACQUISTATO
                and     cd_sala_target.giorno >= trunc(sysdate) 
                and     cd_sala_target.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
            )loop
                --DBMS_OUTPUT.PUT_LINE('procedo');
                PR_DISASSOCIA_SALE_NON_IDONEE(elenco_prodotti.id_prodotto_acquistato,elenco_prodotti.id_target,prodotto_giorno.giorno,v_esito_operazione);
                PR_ASSOCIA_SALE(elenco_prodotti.id_prodotto_acquistato,elenco_prodotti.id_target,prodotto_giorno.giorno,prodotto_giorno.soglia,v_esito_operazione);
            end loop;--fine ciclo sui giorni del singolo prodotto
        end if;
        --
    end loop;--fine ciclo tutti i prodotti TARGET
    ----------------    ESECUZIONE COMMIT DENTRO LA PROCEDURA   ---------------------------------------------------
    COMMIT;
    ----------------    ESECUZIONE COMMIT DENTRO LA PROCEDURA   ---------------------------------------------------
     EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20016, 'PROCEDURA PR_AGGIORNA_PRODOTTO: SI E VERIFICATO UN ERRORE:'||SQLERRM);
        ROLLBACK TO SP_AGGIORNA_PRODOTTO;
 end PR_AGGIORNA_PRODOTTO;
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
-- REALIZZATORE: Mauro Viel Altran Italia, 2 Dicembre 2011
--
--  MODIFICHE: 
--
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
v_flg_esclusivo      cd_prodotto_acquistato.flg_esclusivo%type;
v_id_target          cd_prodotto_vendita.id_target%type;                         
 begin
    SAVEPOINT SP_POPOLA_TAVOLA;
--    
    p_esito := 1;
    

    select nvl(flg_esclusivo,'S'), id_target 
    into   v_flg_esclusivo,v_id_target
    from   cd_prodotto_acquistato pa,
           cd_prodotto_vendita    pv
    where  pa.id_prodotto_acquistato = p_id_prodotto_acquistato
    and    pa.id_prodotto_vendita    = pv.id_prodotto_vendita;
    
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
            where cd_prodotto_vendita.id_target = v_id_target
            and cd_prodotto_vendita.id_circuito = cd_circuito_schermo.id_circuito
            and cd_circuito_schermo.id_schermo = cd_schermo.id_schermo
            and cd_schermo.id_sala = cd_sala.id_sala
            and cd_cinema.id_cinema = cd_sala.id_cinema
            and cd_cinema.flg_virtuale = 'S'
        )LOOP
        insert into cd_sala_target
        (id_prodotto_acquistato,id_sala,giorno,soglia,flg_virtuale,flg_esclusivo,num_sale_idonee,num_sale_disp)
        values
        (p_id_prodotto_acquistato,elenco_sale.id_sala,p_data_inizio+k,nvl(p_soglia,90),'S',v_flg_esclusivo,0,0); --TODO saranno da gestire
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
--
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_SALE
--
-- DESCRIZIONE:  Procedura che permette di associare le sale virtuali a sale reali
--               per la messa in onda del prodotto TARGET, in funzione della 
--               valorizzazione del parametro flg_esclusivo
--
-- OPERAZIONI:
--   1)Recupero il numero di sale REALI ASSOCIATE e una stringa contenente i 
--      corrispondenti id_sala in funzione del il prodotto indicato
--   2)Fino a quando non e raggiunto il valore di soglia o non ci sono piu sale
--      disponibili recupero una sala in modo RANDOM tra quelle 
--      idonee per il prodotto TARGET 
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
--  MODIFICHE: Mauro Viel Altran Italia, 13/12/2011 inserita la nvl su flg_esclusivo
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_ASSOCIA_SALE( p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                            p_id_target                 cd_target.id_target%type,
                            p_giorno                    date,
                            p_soglia_new                number,
                            p_esito                     out number
                           ) is
--                           
 v_num_sale_associate     number := 0;
 /*inizializzo le stringhe in modo da non avere all'istante iniziale dei valori a null */
 v_sale_associate         varchar2(32767) ;
 v_sale_non_idonee        varchar2(32767) := '-';
 v_sala_virtuale          NUMBER;
 v_sala_disponibile       number;
 v_esito_impostazione     number := 0;
 v_exit                   number := 0;
 v_esclusivo              cd_prodotto_acquistato.flg_esclusivo%type;
 begin
 /*in questa fase sto associando, quindi vuol dire a che monte e stato 
    effettuato un controllo su eventuali vecchie sale associate non 
    piu valide e quindi DISASSOCIATE
 */
    /*Recupero il numero attuale di sale REALI ASSOCIATE 
      e una stringa contenente i corrispondenti id_sala  
      per il prodotto indicato*/
    P_ESITO := 1;
    
    select nvl(flg_esclusivo,'S')
    into   v_esclusivo
    from   cd_prodotto_acquistato
    where  id_prodotto_acquistato = p_id_prodotto_acquistato; 
    
    SAVEPOINT SP_ASSOCIA_SALE;
    select  count(id_sala),
            '-'||FU_CD_STRING_AGG('*'||id_sala||'*')
            into v_num_sale_associate,v_sale_associate
    from    cd_sala_target
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
        ordino per datamod desc in modo da prendere quella modificata + di recente
        */
        select id_sala INTO v_sala_virtuale
        from
        (   select
            id_sala,datamod 
            from    cd_sala_target 
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
                select
                  distinct sa.ID_SALA
                from
                  cd_contratto con,
                  cd_cinema_contratto cc,
                  cd_cinema cin,
                  cd_sala sa,
                  cd_schermo sch,
                  cd_target tar,
                  cd_spett_target spt,
                  cd_spettacolo spe,
                  cd_proiezione_spett ps,
                  cd_proiezione pro
                where
                --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
                      pro.DATA_PROIEZIONE = p_giorno  
                  and pro.FLG_ANNULLATO = 'N'
                  and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                  and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                  and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
                  and tar.ID_TARGET = spt.id_target
                  and tar.id_target = p_id_target               -- filtro target
                  and sch.ID_SCHERMO = pro.ID_SCHERMO
                  and sa.ID_SALA = sch.ID_SALA
                  and sa.FLG_ANNULLATO = 'N'
                  and cin.ID_CINEMA = sa.ID_CINEMA
                  and cc.ID_CINEMA = cin.ID_CINEMA
                  and con.ID_CONTRATTO = cc.ID_CONTRATTO
                  and p_giorno BETWEEN con.DATA_INIZIO AND con.DATA_FINE
                  and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
                  (select 1
                   from cd_proiezione_spett ps2,
                        cd_proiezione pro2
                   where pro2.ID_SCHERMO = sch.ID_SCHERMO
                     and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
                     and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
                     and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                            and p_id_target not in               -- filtro target 
                            (select spt2.id_target
                             from cd_spett_target spt2
                             where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                            )
                     and v_esclusivo = 'S'                 -- filtro programmazione esclusiva
                  )
                  and     instr(v_sale_associate,'*'||sch.id_sala||'*')=0
                  and     instr(v_sale_non_idonee,'*'||sch.id_sala||'*') =0
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
--   4)Aggiorno tavola cd_comunicato e cd_sala_target con identificativo della sala e valore di flg_esclusivo
--   5)Riordino posizioni dei comunicati restanti in sala 
--
-- INPUT:
--
-- OUTPUT: esito dell'operazione
--          1   impostazione eseguita con successo
--         -1   sala non disponibile per l'inserimento del nuovo comunicato 
--         -2   errore non gestito
--
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 5 Dicembre 2011
--
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
 v_esiste_pos_rigore    number;
 v_esclusivo            cd_prodotto_acquistato.flg_esclusivo%type;
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
            /*RIMPIAZZO RIFERIMENTI SALA VIRTUALE CON RIFERIMENTI SALA REALE*/
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
        
        select nvl(flg_esclusivo,'S')
        into   v_esclusivo
        from   cd_prodotto_acquistato
        where  id_prodotto_acquistato = p_id_prodotto_acquistato; 
        /*questo deve essere l'ultima operazione
        se le altre sono andate a buon fine*/
        update cd_sala_target
        set id_sala = p_sala_disponibile,
            flg_virtuale = 'N',
            flg_esclusivo = v_esclusivo
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
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 5 Dicembre 2011
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
 v_id_break_vendita     number;
 v_id_break             number;
 v_id_circuito          number;
 v_id_prodotto_vendita  number;
 v_id_comunicato        number;
 v_sala_virtuale        number;
 v_flg_esclusivo        cd_prodotto_acquistato.flg_esclusivo%type;
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
                        AND CD_BREAK.ID_BREAK = CD_COMUNICATO.ID_BREAK
                        AND CD_PROIEZIONE.ID_PROIEZIONE = CD_BREAK.ID_PROIEZIONE
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
            from    cd_sala_target 
            where   cd_sala_target.id_prodotto_acquistato = p_id_prodotto_acquistato
            and     cd_sala_target.flg_virtuale = 'S'
            and     cd_sala_target.giorno = p_giorno
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
    
    select nvl(flg_esclusivo,'S')
    into   v_flg_esclusivo
    from   cd_prodotto_acquistato
    where  id_prodotto_acquistato = p_id_prodotto_acquistato; 
    
    update cd_sala_target
    set id_sala      = v_sala_virtuale,
        flg_virtuale = 'S',
        flg_esclusivo    = v_flg_esclusivo 
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
--
--
-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_DISASSOCIA_SALE_NON_IDONEE
--
-- DESCRIZIONE:  Procedura che permette di disassociare le sale reale 
--               ripristinandole come sale Virtuali
--               per la messa in onda del prodotto TARGET
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
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 5 Dicembre 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_DISASSOCIA_SALE_NON_IDONEE(   p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                            p_id_target                 cd_target.id_target%type,
                                            p_giorno                    date,
                                            p_esito                     out number
                                         ) is
--
 v_esito_impostazione   number :=0;
 v_flg_esclusivo       cd_prodotto_acquistato.flg_esclusivo%type;

                          
 begin
    select flg_esclusivo
    into   v_flg_esclusivo
    from   cd_prodotto_acquistato
    where  id_prodotto_acquistato = p_id_prodotto_acquistato; 
    /*Recupero tutte le eventuali sale associate ma non piu idonee per il prodotto TARGET*/
     for sale_non_idonee in 
            (   select distinct cd_sala_target.id_sala
                from
                    ( 
                    select  FU_CD_STRING_AGG('*'||ID_SALA||'*') elenco
                    from
                    (
                        select
                          distinct sa.ID_SALA
                        from
                          cd_contratto con,
                          cd_cinema_contratto cc,
                          cd_cinema cin,
                          cd_sala sa,
                          cd_schermo sch,
                          cd_target tar,
                          cd_spett_target spt,
                          cd_spettacolo spe,
                          cd_proiezione_spett ps,
                          cd_proiezione pro
                        where
                        --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
                              pro.DATA_PROIEZIONE = p_giorno  
                          and pro.FLG_ANNULLATO = 'N'
                          and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                          and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                          and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
                          and tar.ID_TARGET = spt.id_target
                          and tar.id_target = p_id_target               -- filtro target
                          and sch.ID_SCHERMO = pro.ID_SCHERMO
                          and sa.ID_SALA = sch.ID_SALA
                          and sa.FLG_ANNULLATO = 'N'
                          and cin.ID_CINEMA = sa.ID_CINEMA
                          and cc.ID_CINEMA = cin.ID_CINEMA
                          and con.ID_CONTRATTO = cc.ID_CONTRATTO
                          and p_giorno BETWEEN con.DATA_INIZIO AND con.DATA_FINE
                          and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
                          (select 1
                           from cd_proiezione_spett ps2,
                                cd_proiezione pro2
                           where pro2.ID_SCHERMO = sch.ID_SCHERMO
                             and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
                             and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
                             and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                                    and p_id_target not in               -- filtro target 
                                    (select spt2.id_target
                                     from cd_spett_target spt2
                                     where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                                    )
                             and v_flg_esclusivo = 'S'                 -- filtro programmazione esclusiva
                          )
                     )
                )sale_disponibili,
                cd_sala_target
                where
                        cd_sala_target.id_prodotto_acquistato = p_id_prodotto_acquistato
                and     cd_sala_target.flg_virtuale = 'N'
                and     cd_sala_target.GIORNO = p_giorno 
                /*recupero quelle sale disponibili ma non presenti tra quelle gia associate*/
                and     instr(sale_disponibili.elenco,'*'||cd_sala_target.id_sala||'*')=0
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
--               per la messa in onda del prodotto target
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
-- REALIZZATORE: Antonio Colucci, Teoresigroup srl, 5 Dicembre 2011
--
--  MODIFICHE: 
-------------------------------------------------------------------------------------------------

 PROCEDURE PR_DISASSOCIA_FINO_A_SOGLIA(  p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
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
    from    cd_sala_target
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
            from    cd_sala_target
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
-- PROCEDURE FU_GET_SALE_GIORNO_IDONEE
--
-- INPUT: p_id_prodotto_acquistato  opzionale default null
--        p_data_inizio data inizio ricerca
--        p_data_fine data fine ricerca
--        p_id_target target da ricercare
--        p_esclusivo opzinale default 'S'
--        p_data_soglia data soglia di ricerca per il prelievo del dato dalla tavola di storico (cd_sala_target) o dal dato in linea.
--
--
-- DESCRIZIONE:  Funzione che restituisce le sale idonne in un periodo. La funzione estrarra il numero di sale a esclusiva programmazione a meno che il flag_esclusivo e 'N'.
--               Se la campagna di un dato cliente e terminata il dato verra prelevato dalla tavola di storico
--
-- REALIZZATORE: Mauro Viel, Altran Italia, 5 Dicembre 2011
--
--  MODIFICHE: 

FUNCTION FU_GET_SALE_GIORNO_IDONEE(
                                    p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                    p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                    p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                    p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                    p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                    p_data_soglia            date default trunc(sysdate)
                                )
                                RETURN C_NUM_SALE_DATA
IS
C_RETURN C_NUM_SALE_DATA;
v_data_soglia  date := p_data_soglia;                                            
begin
if p_data_soglia  < p_data_inizio then
    v_data_soglia := p_data_inizio;
end if;

if  p_id_prodotto_acquistato is not null and   p_data_soglia > p_data_fine  then --Se la campagna non e terminata devo prendere sempre la disponibilita non storicizzata
        open c_return for
        select distinct num_sale_idonee, 
                        giorno  as data_proiezione
        from   cd_sala_target
        where  id_prodotto_acquistato = p_id_prodotto_acquistato 
        order  by data_proiezione;
else --parte del prodotto e storicizzato e parte no
        open c_return for
          select  distinct count(id_sala)  over (partition by  data_proiezione) as num_sale_idonee, data_proiezione
            from
            (
                select
                  distinct sa.ID_SALA,pro.data_proiezione
                from
                  cd_contratto con,
                  cd_cinema_contratto cc,
                  cd_cinema cin,
                  cd_sala sa,
                  cd_schermo sch,
                  cd_target tar,
                  cd_spett_target spt,
                  cd_spettacolo spe,
                  cd_proiezione_spett ps,
                  cd_proiezione pro
                where
                --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
                      pro.DATA_PROIEZIONE between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine)  
                  and pro.FLG_ANNULLATO = 'N'
                  and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                  and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                  and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
                  and tar.ID_TARGET = spt.id_target
                  and tar.id_target = p_id_target               -- filtro target
                  and sch.ID_SCHERMO = pro.ID_SCHERMO
                  and sa.ID_SALA = sch.ID_SALA
                  and sa.FLG_ANNULLATO = 'N'
                  and cin.ID_CINEMA = sa.ID_CINEMA
                  and cc.ID_CINEMA = cin.ID_CINEMA
                  and con.ID_CONTRATTO = cc.ID_CONTRATTO
                  and pro.DATA_PROIEZIONE BETWEEN con.DATA_INIZIO AND con.DATA_FINE
                  and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
                  (select 1
                   from cd_proiezione_spett ps2,
                        cd_proiezione pro2
                   where pro2.ID_SCHERMO = sch.ID_SCHERMO
                     and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
                     and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
                     and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                            and p_id_target not in               -- filtro target 
                            (select spt2.id_target
                             from cd_spett_target spt2
                             where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                            )
                     and p_esclusivo = 'S'                 -- filtro programmazione esclusiva
                  )
             )
            union
            select distinct num_sale_idonee, 
                   giorno  as data_proiezione
            from   cd_sala_target 
            where  giorno < v_data_soglia
            and id_prodotto_acquistato = p_id_prodotto_acquistato
            --and decode(p_id_prodotto_acquistato,null,1,2)=2 --deve restituire l'insieme 
                                                               --vuoto se id_prodotto_acquistato 
                                                               --e null in questo modo nel mostrare le disponibilita in presenza di
                                                               --piu prodotti faciamo vedere la disponibilita non stoticizzata 
    order  by data_proiezione;
end if;    
return C_RETURN;
END FU_GET_SALE_GIORNO_IDONEE;




-------------------------------------------------------------------------------------------------
-- PROCEDURE FU_GET_SALE_GIORNO_IDONEE_DISP
--
-- INPUT: p_id_prodotto_acquistato  opzionale default null
--        p_data_inizio data inizio ricerca
--        p_data_fine data fine ricerca
--        p_id_target target da ricercare
--        p_esclusivo opzinale default 'S'
--        p_data_soglia data soglia di ricerca per il prelievo del dato dalla tavola di storico (cd_sala_target) o dal dato in linea.
--
--
-- DESCRIZIONE:  Funzione che restituisce le sale idonne in un periodo. la funzione estrarra il numero di sale a esclusiva programmazione a meno che il flag_esclusivo e 'N'.
--               Se la campagna di un dato cliente e terminata il dato verra prelevato dalla tavola di storico. Gli affollamenti di sala sono sottrtti alla disponibilita
--               totale di 9 miniti (540 sec.) affolalmento totale per sala break.
--               Attenzione alla durata nominale di due break viene sommato 1/2 secondo
--               perche se siamo esattamente a 540 secondi di affolalmento dopo l'associazione non verranno conteggiate
--               le sale esattamente a 540 secondi di affollamento.
--              
--
-- REALIZZATORE: Mauro Viel, Altran Italia, 5 Dicembre 2011
--
--  MODIFICHE: 


function fu_get_sale_giorno_idonee_disp (p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                         p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                         p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                         p_data_soglia            date default trunc(sysdate)
                                         ) return c_num_sale_data is

C_RETURN C_NUM_SALE_DATA;
v_data_soglia  date := p_data_soglia; 
v_durata_break number:= 540.5;                                           
begin

select sum(durata_secondi)+0.5 
into v_durata_break
from  cd_tipo_break
where id_tipo_break in (1,2); 

if p_data_soglia  < p_data_inizio then
    v_data_soglia := p_data_inizio;
end if;

if  p_id_prodotto_acquistato is not null and  p_data_soglia > p_data_fine  then --Se la campagna non e terminata devo prendere sempre la disponibilita non storicizzata
    open c_return for
    select distinct num_sale_disp, 
                    giorno  as data_proiezione
    from   cd_sala_target
    where  id_prodotto_acquistato = p_id_prodotto_acquistato 
    order  by data_proiezione;
else --parte del prodotto e storicizzato e parte no
   open c_return for        
   select distinct  max(NUM_SALE) over (partition by data_proiezione) AS num_sale_idonee, data_proiezione
   from
   (
   select distinct
   data_proiezione,
   count(id_sala) over (partition by data_proiezione) num_sale
   from
   (    with sala_affollamento as
        (
        select
            distinct
            id_sala,  
            min(disponibilita) over (partition by id_sala) as affollamento
            from
            (
            select   distinct
                     cd_comunicato.id_sala,
                     (v_durata_break--(sum(distinct cd_tipo_break.durata_secondi) over (partition by cd_break.id_proiezione)
                     - 
                     sum (cd_coeff_cinema.durata) over (partition by cd_break.id_proiezione)) as disponibilita
            from    cd_sala,cd_cinema,
                    cd_comunicato,
                    cd_prodotto_acquistato,
                    cd_formato_acquistabile,
                    cd_coeff_cinema,
                    cd_tipo_break,
                    cd_break 
            where   cd_comunicato.flg_annullato = 'N'
            and     cd_comunicato.cod_disattivazione is null
            and     cd_comunicato.flg_sospeso = 'N'
            and     cd_comunicato.data_erogazione_prev between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine) --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
            and     cd_comunicato.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
            and     cd_prodotto_acquistato.stato_di_vendita = 'PRE'
            and     cd_prodotto_acquistato.id_formato = cd_formato_acquistabile.id_formato
            and     cd_formato_acquistabile.id_coeff = cd_coeff_cinema.id_coeff
            and     cd_comunicato.id_break = cd_break.id_break
            and     cd_break.id_tipo_break = cd_tipo_break.id_tipo_break
            and     cd_tipo_break.flg_annullato = 'N'
            and     (cd_tipo_break.data_fine is null or cd_tipo_break.data_fine> trunc(sysdate))
            and     cd_tipo_break.id_tipo_break  in (1,2)
            and     cd_comunicato.id_sala = cd_sala.id_sala
            and     cd_cinema.id_cinema = cd_sala.id_cinema
            and     cd_cinema.flg_virtuale = 'N'
            union
            select id_sala,v_durata_break as disponibilita
            from
                cd_sala,
                cd_cinema
            where
                cd_sala.id_cinema = cd_cinema.id_cinema
            and cd_cinema.flg_virtuale = 'N'
            )
        )
       select bacino_sale.id_sala, data_proiezione,affollamento as disponibilita
       from 
       (
            select
              distinct sa.ID_SALA,pro.data_proiezione
            from
              cd_contratto con,
              cd_cinema_contratto cc,
              cd_cinema cin,
              cd_sala sa,
              cd_schermo sch,
              cd_target tar,
              cd_spett_target spt,
              cd_spettacolo spe,
              cd_proiezione_spett ps,
              cd_proiezione pro
            where
            --se p_id_propdotto_acquistato e nullo prendo la data inizio in modo da considerare la situazione per tutto il periodo on line; in questa situazione la tavoal di storico restituira l'insieme vuoto.--Altrimenti prendo la situazione alla data di soglia (default sysdate)
                  pro.DATA_PROIEZIONE between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine)  
              and pro.FLG_ANNULLATO = 'N'
              and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
              and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
              and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
              and tar.ID_TARGET = spt.id_target
              and tar.id_target = p_id_target               -- filtro target
              and sch.ID_SCHERMO = pro.ID_SCHERMO
              and sa.ID_SALA = sch.ID_SALA
              and sa.FLG_ANNULLATO = 'N'
              and cin.ID_CINEMA = sa.ID_CINEMA
              and cc.ID_CINEMA = cin.ID_CINEMA
              and con.ID_CONTRATTO = cc.ID_CONTRATTO
              and pro.DATA_PROIEZIONE BETWEEN con.DATA_INIZIO AND con.DATA_FINE
              and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
              (select 1
               from cd_proiezione_spett ps2,
                    cd_proiezione pro2
               where pro2.ID_SCHERMO = sch.ID_SCHERMO
                 and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
                 and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
                 and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                        and p_id_target not in               -- filtro target 
                        (select spt2.id_target
                         from cd_spett_target spt2
                         where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                        )
                 and p_esclusivo = 'S'                 -- filtro programmazione esclusiva
              )
        )bacino_sale,sala_affollamento
        where sala_affollamento.id_sala = bacino_sale.id_sala
    )
    where disponibilita > 0
    UNION
    SELECT DISTINCT pro.DATA_PROIEZIONE, 0
    from cd_sala sa, 
        cd_schermo sch, cd_proiezione pro
    where  sch.ID_SALA = sa.ID_SALA
    and sa.FLG_ANNULLATO = 'N'
    and sa.FLG_VISIBILE = 'S'
    and pro.ID_SCHERMO = sch.ID_SCHERMO
    and pro.DATA_PROIEZIONE between TRUNC(decode(p_id_prodotto_acquistato,null,p_data_inizio,v_data_soglia)) and TRUNC(p_data_fine)
    union
    select distinct giorno  as data_proiezione,
           num_sale_disp 
    from   cd_sala_target 
    where  giorno < v_data_soglia
    and id_prodotto_acquistato = p_id_prodotto_acquistato
    )
    order by DATA_PROIEZIONE;
end if;
return c_return;            
end fu_get_sale_giorno_idonee_disp;
--

-------------------------------------------------------------------------------------------------
-- PROCEDURE FU_VERIFICA_DISPONIBILITA
--
-- DESCRIZIONE:  Funzione che permette di capire se la sala specifica e idonea
--               per l'inserimento di un nuovo comunicato in base a
--               disponibilita e/o incompatibilita di cliente
--
-- OPERAZIONI:
--   0)Calcolo il target in esame
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
 v_id_target            number;
 v_esclusivo            char;
 begin
    /*Recupero l'id del target legato al prodotto*/
    select  id_target,nvl(flg_esclusivo,'S') into v_id_target,v_esclusivo
    from    cd_prodotto_vendita,cd_prodotto_acquistato
    where   cd_prodotto_acquistato.id_prodotto_acquistato = p_id_prodotto_acquistato
    and     cd_prodotto_acquistato.id_prodotto_vendita = cd_prodotto_vendita.id_prodotto_vendita;
    /*calcolo disponibilita*/
    v_disponibilita_sala := pa_cd_estrazione_prod_vendita.FU_AFFOLLAMENTO_SALA_STATO_NEW(p_giorno,p_giorno,p_id_sala);
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
                (   select
                      distinct sa.ID_SALA
                    from
                      cd_contratto con,
                      cd_cinema_contratto cc,
                      cd_cinema cin,
                      cd_sala sa,
                      cd_schermo sch,
                      cd_target tar,
                      cd_spett_target spt,
                      cd_spettacolo spe,
                      cd_proiezione_spett ps,
                      cd_proiezione pro
                    where
                          pro.DATA_PROIEZIONE = p_giorno  
                      and pro.FLG_ANNULLATO = 'N'
                      and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                      and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                      and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
                      and tar.ID_TARGET = spt.id_target
                      and tar.id_target = v_id_target               -- filtro target
                      and sch.ID_SCHERMO = pro.ID_SCHERMO
                      and sa.ID_SALA = sch.ID_SALA
                      and sa.FLG_ANNULLATO = 'N'
                      and cin.ID_CINEMA = sa.ID_CINEMA
                      and cc.ID_CINEMA = cin.ID_CINEMA
                      and con.ID_CONTRATTO = cc.ID_CONTRATTO
                      and p_giorno BETWEEN con.DATA_INIZIO AND con.DATA_FINE
                      and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
                      (select 1
                       from cd_proiezione_spett ps2,
                            cd_proiezione pro2
                       where pro2.ID_SCHERMO = sch.ID_SCHERMO
                         and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
                         and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
                         and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                                and v_id_target not in               -- filtro target 
                                (select spt2.id_target
                                 from cd_spett_target spt2
                                 where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                                )
                         and v_esclusivo = 'S'                 -- filtro programmazione esclusiva
                      )
                    and     instr(p_sale_non_idonee,'*'||sa.id_sala||'*') =0
                    minus
                    select id_sala
                    from  cd_sala_target
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
                        (select
                          distinct sa.ID_SALA,pro.data_proiezione
                        from
                          cd_contratto con,
                          cd_cinema_contratto cc,
                          cd_cinema cin,
                          cd_sala sa,
                          cd_schermo sch,
                          cd_target tar,
                          cd_spett_target spt,
                          cd_spettacolo spe,
                          cd_proiezione_spett ps,
                          cd_proiezione pro
                        where
                              pro.DATA_PROIEZIONE = p_giorno  
                          and pro.FLG_ANNULLATO = 'N'
                          and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                          and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                          and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
                          and tar.ID_TARGET = spt.id_target
                          and tar.id_target = v_id_target               -- filtro target
                          and sch.ID_SCHERMO = pro.ID_SCHERMO
                          and sa.ID_SALA = sch.ID_SALA
                          and sa.FLG_ANNULLATO = 'N'
                          and cin.ID_CINEMA = sa.ID_CINEMA
                          and cc.ID_CINEMA = cin.ID_CINEMA
                          and con.ID_CONTRATTO = cc.ID_CONTRATTO
                          and p_giorno BETWEEN con.DATA_INIZIO AND con.DATA_FINE
                          and not exists   -- non esistono altre programmazioni filmiche non aventi il target ricercato, se si vuole programmazione esclusiva
                          (select 1
                           from cd_proiezione_spett ps2,
                                cd_proiezione pro2
                           where pro2.ID_SCHERMO = sch.ID_SCHERMO
                             and pro2.DATA_PROIEZIONE = pro.DATA_PROIEZIONE
                             and ps2.ID_PROIEZIONE = pro2.ID_PROIEZIONE
                             and ps2.ID_SPETTACOLO != ps.ID_SPETTACOLO
                                    and v_id_target not in               -- filtro target 
                                    (select spt2.id_target
                                     from cd_spett_target spt2
                                     where spt2.ID_SPETTACOLO = ps2.ID_SPETTACOLO
                                    )
                             and v_esclusivo = 'S'                 -- filtro programmazione esclusiva
                          )
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
                 from  cd_sala_target
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
    return v_return;
    EXCEPTION
       WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR(-20016, 'FUNZIONE FU_VERIFICA_DISPONIBILITA: SI E VERIFICATO UN ERRORE:'||SQLERRM);
 end FU_VERIFICA_DISPONIBILITA;
 

-------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_SALE_WEB
--
-- DESCRIZIONE:  Procedura necessaria per il transitorio dal vecchio al nuovo target. Ha gli stessi parametri della 
--               vecchia procedura di associazioen ma richiama il nuovo core. Sara dismessa con il rifaciemnto grafico della 
--               pagina jsp di associazione.
--

PROCEDURE PR_ASSOCIA_SALE_WEB(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, 
                          p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, 
                          p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, 
                          p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, 
                          p_soglia id_list_type) IS
v_esito   number;    
v_giorno  date := p_data_inizio;
                      
BEGIN
FOR PR_TARGET IN(
                     SELECT ID_PRODOTTO_ACQUISTATO
                     FROM CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA, CD_PIANIFICAZIONE PIA
                     WHERE PA.DATA_INIZIO = p_data_inizio
                     AND PA.DATA_FINE = p_data_fine
                     AND PA.FLG_ANNULLATO = 'N'
                     AND PA.FLG_SOSPESO = 'N'
                     AND PA.COD_DISATTIVAZIONE IS NULL
                     AND PA.STATO_DI_VENDITA = 'PRE'
                     AND PIA.ID_PIANO = PA.ID_PIANO
                     AND PIA.ID_VER_PIANO = PIA.ID_VER_PIANO
                     AND PIA.FLG_ANNULLATO = 'N'
                     AND PIA.FLG_SOSPESO = 'N'
                     AND PIA.ID_CLIENTE = NVL(p_id_cliente,PIA.ID_CLIENTE)
                     AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
                     AND PV.ID_TARGET IS NOT NULL
                     AND PV.ID_TARGET = NVL(p_id_target, PV.ID_TARGET)
                     ) 
loop
    v_giorno:= p_data_inizio;
    for i in p_soglia.first..p_soglia.last
    loop
        IF(v_giorno>=trunc(sysdate))THEN
            PR_GESTISCI_PRODOTTO(pr_target.id_prodotto_acquistato,v_giorno,p_soglia(i),v_esito);
        END IF;
        v_giorno  := v_giorno +1;
    end loop;
end loop;                     
END PR_ASSOCIA_SALE_WEB;


-------------------------------------------------------------------------------------------------
-- PROCEDURE FU_SOGLIE_PERIODO
--
-- DESCRIZIONE:  Procedura necessaria per il transitorio dal vecchio al nuovo target. Ha gli stessi parametri della 
--               vecchia procedura di restituzione delle soglie ma richiama il nuovo core. Sara dismessa con il rifaciemnto grafico della 
--               pagina jsp di associazione.
--


FUNCTION FU_SOGLIE_PERIODO(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_NUM_SALE_DATA IS
v_soglie_settimana C_NUM_SALE_DATA;    
BEGIN
     OPEN v_soglie_settimana FOR
     SELECT SOGLIA,GIORNO
     FROM
     (
         SELECT DISTINCT SOGLIA, GIORNO
         FROM CD_PRODOTTO_ACQUISTATO PA, CD_SALA_TARGET SVP, CD_PRODOTTO_VENDITA PV,CD_PIANIFICAZIONE PIA
         WHERE PA.ID_PRODOTTO_ACQUISTATO  = nvl(P_ID_PRODOTTO_ACQUISTATO,PA.ID_PRODOTTO_ACQUISTATO)
         AND PA.ID_PRODOTTO_ACQUISTATO = SVP.ID_PRODOTTO_ACQUISTATO
         AND PA.FLG_ANNULLATO = 'N'
         AND PA.FLG_SOSPESO = 'N'
         AND PA.COD_DISATTIVAZIONE IS NULL
         AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
         AND PV.ID_TARGET = p_id_target
         AND GIORNO BETWEEN p_data_inizio AND p_data_fine
         AND PIA.ID_PIANO = PA.ID_PIANO
         AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
         AND PIA.ID_CLIENTE = nvl(p_id_cliente,PIA.ID_CLIENTE)         
         GROUP BY GIORNO, SOGLIA
         ORDER BY GIORNO, SOGLIA DESC
     );
RETURN v_soglie_settimana;
END FU_SOGLIE_PERIODO;
 
 --
END PA_CD_NUOVO_TARGET; 
/

