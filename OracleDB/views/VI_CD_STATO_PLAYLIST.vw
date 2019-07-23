CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_STATO_PLAYLIST
(ID, DATA_COMMERCIALE, ID_CINEMA, ID_SALA, ID_PLAYLIST, 
 DATA_PLAYLIST, COMUNICATI_SYNC, FASCE_SYNC, VS_SYNC, VP_SYNC)
AS 
select /*+ RULE */
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_STATO_PLAYLIST
--
-- DESCRIZIONE:
--   Estrae le informazioni sullo stato di sincronizzazione della playlist in tutto il sistema
--   I risultati includono solo le sale per cui e prevista una programmazione pubblicitaria
--   Richiede la parametrizzazione tramite la procedura IMPOSTA_PARAMETRI
--   Significato delle colonne:
--      data_commerciale: data commerciale di riferimento
--      id_cinema:        id cinema relativo alla sala
--      id_sala:          sala di riferimento
--      id_playlist:     id di cd_adv_snapshot_playlist corrispondente all'ultima playlist generata
--                       null se non e stata ancora generata la playlist
--      data_playlist:   data in cui e stata generata la playlist
--                       null se non e stata ancora generata la playlist
--      comunicati_sync: 1 se la playlist e sincronizzata con i comunicati,
--                       0 se c'e qualche differenza (deve essere rigenerata la playlist)
--      fasce_sync:      1 se le fasce sono sincronizzate con la programmazione filmica
--                       0 se c'e qualche differenza (deve essere rigenerata la playlist),
--                       null se non e stata ancora generata la playlist
--      vs_sync:         1 se il video server ha ricevuto la playlist, 0 altrimenti
--                       null se non e stata ancora generata la playlist
--      vp_sync:         1 se il video player ha ricevuto la playlist, 0 altrimenti
--                       null se non e stata ancora generata la playlist
--
-- REALIZZATORE: Angelo Marletta, Teoresi s.r.l., 05/07/2010
--
-- MODIFICHE:
--      12/07/2010, Aggiunta colonna ID, Angelo Marletta
--      25/08/2011, Inserito HINT per ottimizzare performance query Antonio Colucci
--      21/10/2011, Inserita una DISTINCT per risolvere il problema di visualizzazione
--                  in blu dello stato delle playlist nel passato, a seguito della creazione
--                  dei fake snapshot su cd_adv_comunicato. Tommaso D'Anna
-----------------------------------------------------------------------------------------------------
row_number() over(order by programmazione.data_commerciale, programmazione.id_sala) ID,
programmazione.data_commerciale,
programmazione.id_cinema,
programmazione.id_sala,
playlist.id_playlist,
playlist.data_modifica data_playlist,
case when programmazione.hash_playlist=playlist.hash_playlist then 1
else 0 end comunicati_sync,
case when fasce_new.id_sala is null and playlist.id_playlist is not null then 1
when playlist.id_playlist is null then null
else 0 end fasce_sync,
stato_vs vs_sync,
stato_vp vp_sync
from
(
    --Programmazione comunicati dalle viste
    select /*+ RULE */ distinct
    vbr.data_commerciale,vbr.id_sala,vsa.id_cinema,
    sum(mod(id_proiezione*vbr.id*vco.id,1e7)*vco.posizione*vco.id_materiale) over(partition by vbr.data_commerciale,vbr.id_sala) hash_playlist
    from vi_cd_break vbr, vi_cd_comunicato vco, vi_cd_sala vsa
    where vbr.id = vco.id_break and vbr.id_sala = vsa.id
) programmazione,
(
    --Snapshot piu recente delle viste
    select /*+ RULE */ distinct
    data_commerciale,id_sala,id_playlist,
    stato_vs,
    stato_vp,
    data_modifica,
    sum(mod(id_proiezione*id_break*id_comunicato,1e7)*posizione*id_materiale) over (partition by data_commerciale, id_sala) hash_playlist
    from (
        select /*+ RULE */ DISTINCT --TDA 21/10/2011
        pl.id_cinema,id_sala,data_commerciale,id_proiezione,
        sco.id_comunicato,sbr.id_break,smat.id_materiale,sco.posizione,stato_vp,stato_vs,
        case when data_modifica=max(data_modifica) over (partition by data_commerciale,id_sala) then 1
        else 0 end last_playlist,
        data_modifica,pl.id id_playlist
        from cd_adv_snapshot_playlist pl, cd_adv_snapshot_break sbr,
        cd_adv_snapshot_comunicato sco, cd_adv_snapshot_materiale smat
        where pl.id = sbr.id_playlist
        and sbr.id = sco.id_break
        and sco.id_materiale = smat.id
        and pl.data_commerciale between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
    ) where last_playlist = 1
) playlist,
(
  --Fasce aggiornate
  select /*+ RULE */ distinct vbr.data_commerciale,vbr.id_sala,
      sum(vfa.hh_inizio*60+vfa.mm_inizio + (vfa.hh_fine*60+vfa.mm_fine)*1440 + vfa.id_proiezione) over(partition by vbr.data_commerciale,vbr.id_sala) hash_fasce_programmazione
  from
      vi_cd_fascia vfa, vi_cd_break vbr
      where vfa.id_proiezione = vbr.id_proiezione
      and vbr.tipo_break = 'Trailer'
  minus
  --Fasce nelle ultime playlist generate
  select /*+ RULE */ distinct data_commerciale, id_sala,
      sum(hh_inizio*60+mm_inizio + (hh_fine*60+mm_fine)*1440 + id_proiezione) over(partition by data_commerciale,id_sala) hash_fasce_playlist
  from (
      select /*+ RULE */ distinct id_playlist,pl.data_commerciale,pl.id_sala,id_proiezione,hh_inizio,mm_inizio,hh_fine,mm_fine,
          case when data_modifica=max(data_modifica) over (partition by data_commerciale,id_sala) then 1
          else 0 end last_playlist
      from
          cd_adv_snapshot_fascia sfa, cd_adv_snapshot_playlist pl
      where sfa.id_playlist=pl.id and pl.data_commerciale between pa_cd_adv_cinema.fu_data_inizio and pa_cd_adv_cinema.fu_data_fine
      ) where last_playlist=1
) fasce_new
where programmazione.data_commerciale=playlist.data_commerciale(+)
and programmazione.id_sala=playlist.id_sala(+)
and programmazione.data_commerciale=fasce_new.data_commerciale(+)
and programmazione.id_sala=fasce_new.id_sala(+)
order by programmazione.data_commerciale, programmazione.id_sala
/



