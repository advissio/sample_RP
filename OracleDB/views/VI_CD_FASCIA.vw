CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_FASCIA
(ID, ID_PROIEZIONE, HH_INIZIO, MM_INIZIO, HH_FINE, 
 MM_FINE)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_FASCIA
--
-- DESCRIZIONE:
--   Estrae dinamicamente le fasce corrispondendi alle proiezioni
--   Per ogni coppia data/sala esiste una proiezione normale e una protetta.
--   Le due proiezioni vengono mappate in fasce orarie variabili a seconda della 
--   programmazione spettacolare inserita dal gestore.
--   Gli intervalli contenenti film normali oppure in cui non esiste una programmazione
--   vengono assegnati alla proiezione normale
--   Gli intervalli contenenti film per bambini (flaggati come protetti) vengono assegnati
--   alla proiezione protetta.
--   Gli intervalli vengono compattati il piu possibile in modo da minimizzarne il numero totale.   
--
-- REALIZZATORE: Angelo Marletta, Teoresi s.r.l. - 10/06/2010
-- MODIFICHE:
--    Antonio Colucci, Teoresi s.r.l. - 21/06/2010
--        Eliminato filtro sulla data in quanto superfluo perche la ricerca e per id_proiezione
--        ed in quanto perche l'MDB per l'invio della playlist non e in grado di "ricordare"
--        l'imposta parametri
--    Angelo Marletta, Teoresi s.r.l. - 23/06/2010
--        La vista usa cd_fascia per stabilire se la proiezione e protetta invece che cd_spettacolo
--        Gli intervalli vuoti (senza programmazione filmica) vengono associati alla proiezione
--        relativa all'intervallo precedente
--    Angelo Marletta, Teoresi s.r.l. - 23/06/2010
--        Rimosse fasce relative a proiezioni di arene
--    Angelo Marletta, Teoresi s.r.l. - 01/09/2010
--        Unica proiezione giornaliera nel caso in cui le due proiezioni tipo sono uguali
--        Esclusione sale virtuali e arene
-----------------------------------------------------------------------------------------------------
    row_number() over(order by id_proiezione) ID,
    id_proiezione,
    hh_inizio,
    mm_inizio,
    hh_fine,
    mm_fine
from (
select u1.*, count(1) over (partition by data_commerciale,id_sala) num
from
(
--compattazione fasce
select
    t3.data_commerciale,
    t3.id_sala,
    t3.id_proiezione,
    --decodifica ore-minuti inizio
    floor(min(inizio)/60) hh_inizio, mod(min(inizio),60) mm_inizio,
    --decodifica ore-minuti fine
    floor(max(fine)/60) hh_fine, mod(max(fine),60) mm_fine,
    1 fascia_calcolata
from
(
select t2.*,
    --contatore_fascia: contatore progressivo che marca con uno stesso numero gli intervalli da compattare
    sum(nuova_fascia) over (partition by data_commerciale,id_sala order by inizio) contatore_fascia
from
(
select t1.*,
    --nuova_fascia: 1 se e l'intervallo ha un flag protetto diverso dal precedente, 0 altrimenti
    case when
        row_number() over (partition by t1.data_commerciale,t1.id_sala order by inizio) = 1 then 1
    when t1.flg_protetto != lag(t1.flg_protetto) over (partition by t1.data_commerciale,t1.id_sala order by inizio) then 1
        else 0
    end nuova_fascia
from (
    --intervalli esistenti in cd_proiezione_spett
    select
        pr.data_proiezione data_commerciale,sc.id_sala,
        (ps.hh_ini*60 + ps.mm_ini) inizio, --codifica orario di inizio tra 6*60 e 30*60
        (ps.hh_fine*60 + ps.mm_fine) fine, --codifica orario di fine tra 6*60 e 30*60
        fa.flg_protetta flg_protetto,
        ps.id_proiezione
    from
        cd_proiezione_spett ps, cd_proiezione pr, cd_schermo sc, cd_fascia fa, cd_sala sa, cd_cinema ci
    where
        ps.id_proiezione=pr.id_proiezione
        and pr.id_schermo=sc.id_schermo
        and pr.id_fascia=fa.id_fascia
        and pr.data_proiezione between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
        and sc.id_sala = sa.id_sala
        and sa.id_cinema = ci.id_cinema
        and sa.flg_arena = 'N'
        and sa.flg_annullato = 'N'
        and sa.flg_visibile = 'S'
        and ci.flg_virtuale = 'N'
        and ci.flg_annullato = 'N'
union
    --primo intervallo vuoto
    select * from (
    select
        pr.data_proiezione data_commerciale,sc.id_sala,
        6*60 inizio, -- ore 6
        min(ps.hh_ini*60 + ps.mm_ini) over (partition by pr.data_proiezione,sc.id_sala) fine, --inizio del primo intervallo esistente
        'N' flg_protetto,
        --ricerca id_proiezione taggata con N
        (select id_proiezione from cd_proiezione pr2,cd_fascia fa2 where pr2.id_fascia=fa2.id_fascia and pr2.data_proiezione=pr.data_proiezione and pr2.id_schermo=pr.id_schermo and fa2.flg_protetta='N') id_proiezione
    from
        cd_proiezione_spett ps, cd_proiezione pr, cd_schermo sc, cd_sala sa, cd_cinema ci
    where
        ps.id_proiezione=pr.id_proiezione
        and pr.id_schermo=sc.id_schermo
        and pr.data_proiezione between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
        and sc.id_sala = sa.id_sala
        and sa.id_cinema = ci.id_cinema
        and sa.flg_arena = 'N'
        and sa.flg_annullato = 'N'
        and sa.flg_visibile = 'S'
        and ci.flg_virtuale = 'N'
        and ci.flg_annullato = 'N'
    ) where flg_protetto='N'
union all
    --intervalli vuoti tranne il primo
    select
        pr.data_proiezione data_commerciale,sc.id_sala,
        (ps.hh_fine*60 + ps.mm_fine) inizio,
        nvl(lead(ps.hh_ini*60 + ps.mm_ini) over (partition by pr.data_proiezione,sa.id_sala order by hh_ini,mm_ini),30*60) fine,
        fa.flg_protetta flg_protetto,
        --id_proiezione dell'intervallo precedente
        pr.id_proiezione
    from
        cd_proiezione_spett ps, cd_proiezione pr, cd_schermo sc, cd_fascia fa, cd_sala sa, cd_cinema ci
    where
        ps.id_proiezione=pr.id_proiezione
        and pr.id_schermo=sc.id_schermo
        and pr.id_fascia = fa.id_fascia
        and pr.data_proiezione between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
        and sc.id_sala = sa.id_sala
        and sa.id_cinema = ci.id_cinema
        and sa.flg_arena = 'N'
        and sa.flg_annullato = 'N'
        and sa.flg_visibile = 'S'
        and ci.flg_virtuale = 'N'
        and ci.flg_annullato = 'N'
) t1, --calcolo colonna nuova_fascia
    (
    --per ogni coppia giorno-sala calcola se le due proiezioni tipo hanno una diversa composizione
    select
        distinct data_commerciale,id_sala,
        count(distinct hash_proiezione_tipo) over (partition by data_commerciale,id_sala) - 1 proiezioni_diverse
    from (
        select distinct
            vbr.data_commerciale,
            vbr.id_sala,
            sum(vco.posizione * vco.id_materiale * decode(vbr.TIPO_BREAK, 'Trailer', 1, 2)) over (partition by vbr.id_proiezione) hash_proiezione_tipo
        from
            vi_cd_comunicato vco, vi_cd_break vbr
        where
            vco.id_break = vbr.id )
    ) diff_proiezioni
  where inizio<fine --scarto eventuali intervalli vuoti
    and diff_proiezioni.data_commerciale = t1.data_commerciale
    and diff_proiezioni.id_sala = t1.id_sala
    and diff_proiezioni.proiezioni_diverse = 1 --prendo solo le sale con le due proiezioni tipo diverse
) t2 --calcolo colonna contatore_fascia
) t3 --compattazione per contatore_fascia
group by t3.data_commerciale,t3.id_sala,t3.contatore_fascia,t3.flg_protetto,t3.id_proiezione
--order by data_commerciale,id_sala, min(inizio)
--fine query di compattazione fasce
union all
--inizio vecchia vi_cd_break (per aggiungere i break delle sale senza spettacolo)
    select
        cd_proiezione.data_proiezione data_commerciale,
        cd_schermo.id_sala,
        cd_proiezione.id_proiezione,
        6 hh_inizio,0 mm_inizio,
        30 hh_fine,0 mm_fine,
        0 fascia_calcolata
    from
        cd_break, cd_proiezione, cd_schermo, cd_fascia, cd_sala, cd_cinema
    where
        cd_break.id_proiezione = cd_proiezione.id_proiezione
        and cd_proiezione.data_proiezione between pa_cd_adv_cinema.fu_data_inizio and pa_cd_adv_cinema.fu_data_fine
        and cd_proiezione.id_schermo = cd_schermo.id_schermo
        and cd_proiezione.id_fascia = cd_fascia.id_fascia
        and cd_fascia.flg_protetta = 'N'
        and cd_break.flg_annullato = 'N'
        and cd_schermo.id_sala = cd_sala.id_sala
        and cd_sala.id_cinema = cd_cinema.id_cinema
        and cd_sala.flg_arena = 'N'
        and cd_sala.flg_annullato = 'N'
        and cd_sala.flg_visibile = 'S'
        and cd_cinema.flg_virtuale = 'N'
        and cd_cinema.flg_annullato = 'N'
    group by cd_proiezione.id_proiezione, data_proiezione, cd_proiezione.data_proiezione, cd_schermo.id_sala
--fine vecchia vi_cd_break
) u1
) u2
where (u2.fascia_calcolata=1 or u2.num=1)
/



