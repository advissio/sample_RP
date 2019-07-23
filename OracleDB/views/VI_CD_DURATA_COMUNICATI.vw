CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_DURATA_COMUNICATI
(DATA_COMMERCIALE, ID_CINEMA, ID_SALA, HH_INIZIO, MM_INIZIO, 
 HH_FINE, MM_FINE, TIPO, ID_MATERIALE, DURATA, 
 POSIZIONE, SOGGETTO, CLIENTE, DURATA_BREAK, DURATA_PROIEZIONE, 
 HASH_PLAYLIST)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_DURATA_COMUNICATI
--
-- DESCRIZIONE:
--   Estrae i Comunicati validi per la messa in onda, corredati della durata.
--   Usata dal sistema ADV_Cinema per la comunicazione ai gestori dei cinema.
--
-- REALIZZATORE: Luigi Cipolla, 21/01/2010
--
-- MODIFICHE:
--    25/03/2010, Angelo Marletta:
--       L'estrazione viene effettuata dalle tabelle snapshot delle playlist generate (Angelo Marletta)
--    16/06/2010, Antonio Colucci:
--       Cambiata la tavola dove reperire le informazioni di fascia del break (CD_ADV_SNAPSHOT_FASCIA)
--    23/06/2010, Angelo Marletta:
--       La vista recupera solo l'ultima playlist generata per sala, in base alla data_modifica
--       Prima di usare la vista bisogna chiamare la procedura IMPOSTA_PARAMETRI
--    07/07/2010, Angelo Marletta:
--       Aggiunta colonna id_cinema
--    02/09/2010, Angelo Marletta:
--       Aggiunte colonne: durata_break, durata_proiezione, hash_playlist
--       Rimosse colonne: id_proiezione, id_break
--    08/09/2010, Angelo Marletta:
--       Inseriti soggetto e durata nel calcolo dell'hash playlist, al posto di id_materiale
--
-----------------------------------------------------------------------------------------------------
data_commerciale,id_cinema,id_sala,
hh_inizio,mm_inizio,hh_fine,mm_fine,decode(tipo, 'Trailer', tipo, 'Inizio Film') tipo,
id_materiale,durata,posizione,soggetto,cliente,
sum(durata) over (partition by data_commerciale, id_sala, hh_inizio, mm_inizio, id_proiezione, id_break) durata_break,
sum(durata) over (partition by data_commerciale, id_sala, hh_inizio, mm_inizio, id_proiezione) durata_proiezione,
sum(decode(tipo, 'Trailer', 1, 2) * (DBMS_UTILITY.GET_HASH_VALUE(soggetto,2,1048576) + durata) * posizione * (hh_inizio*60 + mm_inizio)) over (partition by data_commerciale, id_sala) hash_playlist
from
(
select
  play.data_commerciale,
  play.id_cinema,
  play.id_sala,
  br.id_proiezione,
  br.id as id_break,
  fascia.hh_inizio, fascia.mm_inizio, fascia.hh_fine, fascia.mm_fine,
  br.tipo,
  com.posizione, com.desc_sogg as soggetto,
  cli.rag_soc_cogn as cliente,
  mat.id_materiale,
  mat.durata,play.data_modifica,
  max(play.data_modifica) over (partition by data_commerciale,id_sala) max_data_modifica
from
  interl_u cli,
  cd_adv_snapshot_materiale mat,
  cd_adv_snapshot_break br,
  cd_adv_snapshot_comunicato com,
  cd_adv_snapshot_playlist play,
  cd_adv_snapshot_fascia fascia
where br.id = com.id_break
  and play.ID = fascia.id_playlist
  and br.id_proiezione = fascia.id_proiezione
  and mat.id = com.id_materiale
  and cli.cod_interl = mat.id_cliente
  and br.id_playlist = play.id
  and data_commerciale between PA_CD_ADV_CINEMA.FU_DATA_INIZIO and PA_CD_ADV_CINEMA.FU_DATA_FINE
)
where data_modifica=max_data_modifica
--order by id_sala,data_commerciale,hh_inizio,mm_inizio,tipo desc,posizione
/



