CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_BREAK2
(ID, ID_PROIEZIONE, ID_SALA, DATA_COMMERCIALE, DATA_PREV, 
 HH_INIZIO, MM_INIZIO, HH_FINE, MM_FINE, TIPO_BREAK)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_BREAK2
--
-- DESCRIZIONE:
--   Estrae i Break validi per la messa in onda, da cui vengono generate le playlist.
--   Per ogni coppia data/sala esiste una proiezione normale e una protetta.
--   Le due proiezioni vengono mappate in fasce orarie variabili a seconda della 
--   programmazione spettacolare inserita dal gestore.
--   Gli intervalli contenenti film normali oppure in cui non esiste una programmazione
--   vengono assegnati alla proiezione normale
--   Gli intervalli contenenti film per bambini (flaggati come protetti) vengono assegnati
--   alla proiezione protetta.
--   Gli intervalli vengono compattati il piu possibile per minimizzarne il numero totale.   
--
-- REALIZZATORE: Angelo Marletta, Teoresi s.r.l. - 27/05/2010
--
-----------------------------------------------------------------------------------------------------
    id,id_proiezione,id_sala,data_commerciale,data_prev,
    hh_inizio,mm_inizio,hh_fine,mm_fine,tipo_break
from
(
select u1.*, count(1) over (partition by id_sala,data_commerciale) num_break
from
(
--inizio query di compattazione fasce
select
br.id_break id,
t4.id_proiezione,
t4.id_sala,
t4.data_commerciale,
t4.data_commerciale data_prev,
floor(inizio/60) hh_inizio, mod(inizio,60) mm_inizio, --decodifica ore-minuti inizio
floor(fine/60) hh_fine, mod(fine,60) mm_fine, --decodifica ore-minuti fine
tb.desc_tipo_break tipo_break,
1 spettacolo_programmato
from
(
--compattazione fasce
select 
    t3.data_commerciale,t3.id_sala,
    min(inizio) inizio,max(fine) fine,t3.flg_protetto,t3.id_proiezione
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
        row_number() over (partition by data_commerciale,id_sala order by inizio) = 1 then 1
    when t1.flg_protetto != lag(t1.flg_protetto) over (partition by data_commerciale,id_sala order by inizio) then 1
        else 0   
    end nuova_fascia
from (
    --intervalli esistenti in cd_proiezione_spett
    select
        pr.data_proiezione data_commerciale,sc.id_sala,
        (ps.hh_ini*60 + ps.mm_ini) inizio, --codifica orario di inizio tra 6*60 e 30*60
        (ps.hh_fine*60 + ps.mm_fine) fine, --codifica orario di fine tra 6*60 e 30*60
        sp.flg_protetto,
        ps.id_proiezione
    from
        cd_proiezione_spett ps, cd_proiezione pr, cd_schermo sc, cd_spettacolo sp
    where
        ps.id_proiezione=pr.id_proiezione
        and pr.id_schermo=sc.id_schermo
        and ps.id_spettacolo=sp.id_spettacolo
        and pr.data_proiezione between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
union all
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
        cd_proiezione_spett ps, cd_proiezione pr, cd_schermo sc, cd_spettacolo sp
    where
        ps.id_proiezione=pr.id_proiezione
        and pr.id_schermo=sc.id_schermo
        and ps.id_spettacolo=sp.id_spettacolo
        and pr.data_proiezione between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
    ) where flg_protetto='N'
union all
    --intervalli vuoti tranne il primo
    --TODO: assegnare intervallo alla proiezione dell'intervallo precedente
    select * from (
    select
        pr.data_proiezione data_commerciale,sc.id_sala,
        (ps.hh_fine*60 + ps.mm_fine) inizio,
        nvl(lead(ps.hh_ini*60 + ps.mm_ini) over (partition by pr.data_proiezione,id_sala order by hh_ini,mm_ini),30*60) fine,
        'N' flg_protetto,
        --ricerca id_proiezione taggata con N
        (select id_proiezione from cd_proiezione pr2,cd_fascia fa2 where pr2.id_fascia=fa2.id_fascia and pr2.data_proiezione=pr.data_proiezione and pr2.id_schermo=pr.id_schermo and fa2.flg_protetta='N') id_proiezione
    from
        cd_proiezione_spett ps, cd_proiezione pr, cd_schermo sc, cd_spettacolo sp
    where
        ps.id_proiezione=pr.id_proiezione
        and pr.id_schermo=sc.id_schermo
        and ps.id_spettacolo=sp.id_spettacolo
        and pr.data_proiezione between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
    ) where flg_protetto='N'
) t1 --calcolo colonna nuova_fascia
    where inizio<fine --scarto eventuali intervalli vuoti
) t2 --calcolo colonna contatore_fascia
) t3 --compattazione per contatore_fascia
group by t3.data_commerciale,t3.id_sala,t3.contatore_fascia,t3.flg_protetto,t3.id_proiezione
) t4, cd_break br, cd_tipo_break tb --join con i break
where t4.id_proiezione = br.id_proiezione
and br.id_tipo_break = tb.id_tipo_break
and br.flg_annullato = 'N'
and tb.desc_tipo_break in ('Trailer','Inizio Film')
--fine query di compattazione fasce
union all
--inizio vecchia vi_cd_break (per aggiungere i break delle sale senza spettacolo)
SELECT
ID_BREAK as ID, CD_PROIEZIONE.ID_PROIEZIONE,ID_SALA,
DATA_PROIEZIONE
AS DATA_COMMERCIALE
,DATA_PROIEZIONE AS DATA_PREV,
6 HH_INIZIO,0 MM_INIZIO,
30 HH_FINE,0 MM_FINE,
CD_TIPO_BREAK.DESC_TIPO_BREAK AS TIPO_BREAK,
0 spettacolo_programmato
FROM CD_BREAK, CD_PROIEZIONE, CD_SCHERMO, CD_TIPO_BREAK, CD_FASCIA
WHERE CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
AND   CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN PA_CD_ADV_CINEMA.FU_DATA_INIZIO AND PA_CD_ADV_CINEMA.FU_DATA_FINE
AND   CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
AND   CD_PROIEZIONE.ID_FASCIA = CD_FASCIA.ID_FASCIA
AND   CD_FASCIA.FLG_PROTETTA = 'N'
AND   CD_BREAK.FLG_ANNULLATO = 'N'
AND   CD_TIPO_BREAK.ID_TIPO_BREAK = CD_BREAK.ID_TIPO_BREAK
AND   CD_TIPO_BREAK.DESC_TIPO_BREAK IN ('Trailer', 'Inizio Film')
--fine vecchia vi_cd_break
) u1
) u2
where u2.spettacolo_programmato=1 or (u2.spettacolo_programmato=0 and u2.num_break=2)
--order by data_commerciale,id_sala,hh_inizio,mm_inizio,tipo_break desc;
/



