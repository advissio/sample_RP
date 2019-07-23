CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_STATO_MATERIALE
(ID_MATERIALE, DATA_INSERIMENTO, AVANZAMENTO, NUM_CINEMA_SINCRONIZZATI, NUM_CINEMA_NON_SINCRONIZZATI, 
 CINEMA_NON_SINCRONIZZATI)
AS 
select distinct
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_STATO_MATERIALE
--
-- DESCRIZIONE:
--   Estrae le informazioni sullo stato di sincronizzazione dei materiali nel sistema ADVDCINEMA
--   Significato delle colonne:
--      id_materiale: id del materiale (da cd_materiale) 
--      data_inserimento: data in cui e stato inserito il materiale
--      avanzamento: percentuale di avanzamento globale di trasferimento
--      num_cinema_sincronizzati: numero di cinema sincronizzati
--      num_cinema_non_sincronizzati: numero di cinema sincronizzati
--      cinema_non_sincronizzati: lista csv dei cinema non ancora sincronizzati
--
-- REALIZZATORE: Angelo Marletta, Teoresi s.r.l., 15/07/2010
-- MODIFICHE:
--          Tommaso D'Anna, Teoresi s.r.l., 15 Settembre 2011
--              Inserita la join con VI_CD_CINEMA in modo da ottenere soltanto
--              gli stati di sync relativi a cinema validi
-----------------------------------------------------------------------------------------------------
    id_materiale,
    data_inserimento,
    100 * count(uptodate) over (partition by id_materiale) / (select count(*) from vi_cd_cinema where id!=78) avanzamento,
    count(uptodate) over (partition by id_materiale) num_cinema_sincronizzati,
    count(*) over (partition by id_materiale)-count(uptodate) over (partition by id_materiale) num_cinema_non_sincronizzati,
    case when count(*) over (partition by id_materiale)-count(uptodate) over (partition by id_materiale) = 0 then null
    else fu_cd_string_agg(id_cinema) keep (dense_rank first order by uptodate nulls first) over (partition by id_materiale) end
    cinema_non_sincronizzati
from
    (
    select
        mat.id id_materiale,mat.data_inserimento,
        id_cinema,
        case when last_rsync - data_inserimento > 0 then 1
        else null end uptodate 
    from
        (select * from vi_cd_materiale where nome_file is not null) mat,
        (
            select 
                cd_adv_job.id_cinema,
                max(data_inizio_esecuzione) last_rsync 
            from 
                cd_adv_job,
                VI_CD_CINEMA 
            where esito_rsynch         = 0
            AND CD_ADV_JOB.ID_CINEMA   = VI_CD_CINEMA.ID
            group by cd_adv_job.id_cinema
        ) rsync
    )
/



