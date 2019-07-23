CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_PAGAMENTO_SIAE
(ID_COMUNICATO, DATA_EROGAZIONE_PREV, ID_SALA, ID_MATERIALE, COD_AREA, 
 DESC_AREA, ID_CLIENTE, CLIENTE, ID_SOGGETTO, SOGGETTO, 
 ID_FORMATO, TITOLO_MATERIALE, FLG_SIAE, AUTORE, TITOLO_COLONNA, 
 IMPORTO_SIAE, IMPORTO_SIAE_PAGATO, NOME_CINEMA, COMUNE, NOME_SALA, 
 DURATA, DATA_CONFERMA_SIAE, FLG_VIRTUALE)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_PAGAMENTO_SIAE
--
-- DESCRIZIONE: Vista contenente tutte le informazioni necessarie per il pagamento degli oneri S.I.A.E.
--
-- REALIZZATORE: Mauro Viel Altran - 01/02/2009
--
-- MODIFICHE:
--   Lugi Cipolla - 02/02/2010
--     Modificata la struttura della vista per migliorare le performance
--   Luigi Cipolla - 01/03/2010
--     Eliminata la colonna num_schermi, in quanto calcolata esternamente.
--   Luigi Cipolla - 02/03/2010
--     Inserita la colonna Area.
--  Mauro Viel 9/06/2010
-- Inserita funzione di raggruppamento fittizia sulla colonna DATA_CONFERMA_SIAE perche se messa in raggruppamento 
-- duplicava l'importo dovuto solo dopo la conferma.
-- Mauro Viel 30/08/2011 Inserita la clausola per escludere le sale virtuali. Per i prodotti target/segui 
--                      il film l'esclusione viene comunque fatta perche le sale virtuali vengono 
--                      annullate in fase di ricalcolo della tariffa.    
--Mauro Viel 20/09/2011 Eliminata la clausola sulla sala virtuale ed esposto il flg_virtuale                   
-----------------------------------------------------------------------------------------------------
comunicati.ID_COMUNICATO,
comunicati.DATA_EROGAZIONE_PREV,
comunicati.ID_SALA,
mat.ID_MATERIALE,
A.cod_area,
a.descriz DESC_AREA,
cli.COD_INTERL as ID_CLIENTE,
cli.RAGSOC as CLIENTE,
sog.COD_SOGG as ID_SOGGETTO,
sog.DES_SOGG as SOGGETTO,
pa.ID_FORMATO,
mat.titolo as titolo_materiale,
mat.flg_siae,
colonna.AUTORE,
colonna.TITOLO as titolo_colonna,
decode(mat.FLG_SIAE,'S',TASIAE.importo_siae,0) as importo_siae,
comunicati.importo_siae_pagato,
cinema.nome_cinema,
comune.comune,
sala.nome_sala,
mat.durata,
comunicati.data_conferma_siae,
cinema.flg_virtuale
from
 cd_comune comune,
 cd_cinema cinema,
 cd_sala sala,
 cd_tariffa_siae TASIAE,
 aree A,
 cd_pianificazione PIA,
 cd_prodotto_acquistato pa,
 cd_colonna_sonora colonna,
 soggetti sog,
 cd_materiale_soggetti mat_sog,
 clicomm cli,
 cd_materiale mat,
 cd_materiale_di_piano mat_pia,
 -- estrae uno solo dei comunicati tipo per ciascuna sala/giorno
 (select min (com.id_comunicato) id_comunicato,
          min(com.ID_PRODOTTO_ACQUISTATO) ID_PRODOTTO_ACQUISTATO,  -- funzione di raggruppamento fittizia
          max(com.importo_siae) importo_siae_pagato,
          com.DATA_EROGAZIONE_PREV,
          com.id_materiale_di_piano,
          com.ID_SALA,
           max(com.DATA_CONFERMA_SIAE) as DATA_CONFERMA_SIAE
  from cd_comunicato COM
where com.FLG_ANNULLATO = 'N'
  and com.FLG_SOSPESO = 'N'
  and com.COD_DISATTIVAZIONE IS NULL
  group by com.DATA_EROGAZIONE_PREV, com.ID_MATERIALE_di_piano, com.ID_SALA--, com.DATA_CONFERMA_SIAE
 ) comunicati
where
    mat_pia.ID_MATERIALE_DI_PIANO = comunicati.ID_MATERIALE_DI_PIANO
and mat.ID_MATERIALE = mat_pia.ID_MATERIALE
and cli.COD_INTERL = mat.ID_CLIENTE
and mat_sog.ID_MATERIALE = mat.ID_MATERIALE
and sog.cod_sogg = mat_sog.COD_SOGG
and colonna.ID_COLONNA_SONORA (+) =  mat.ID_COLONNA_SONORA
and pa.ID_PRODOTTO_ACQUISTATO = comunicati.ID_PRODOTTO_ACQUISTATO
and pia.id_piano = pa.id_piano
and pia.id_ver_piano = pa.id_ver_piano
and A.cod_area = pia.cod_area
and TASIAE.ID_FORMATO = pa.id_formato
and comunicati.data_erogazione_prev between TASIAE.data_inizio_validita and nvl(TASIAE.data_fine_validita,to_date('01012099','DDMMYYYY'))
and sala.id_sala = comunicati.id_sala
and cinema.id_cinema = sala.id_cinema
and comune.id_comune = cinema.id_comune
--and cinema.flg_virtuale = 'N'
/



