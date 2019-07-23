CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_COMUNICATO_PREVISTO
(DATA_COMMERCIALE, ID_SALA, ID_PROIEZIONE, ID_BREAK, ID_TIPO_BREAK, 
 ID_COMUNICATO, ID_MATERIALE, POSIZIONE, POSIZIONE_RELATIVA, DURATA_PROIEZIONE, 
 DURATA_BREAK, NUMERO_SPOT, DURATA, ID_FASCIA, HASH_PROIEZIONE, 
 HASH_BREAK)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_COMUNICATO_PREVISTO
--
-- DESCRIZIONE:
--   Estrae i comunicati previsti dalla pianificazione
--   Per ogni break e proiezione viene calcolato un hash che tiene conto dell'ordine previsto di
--   trasmissione dei comunicati
--   L'hash viene calcolato come la somma dei prodotti tra id comunicato e posizione relativa
--   all'interno del break o della proiezione corrispondente
--   Necessita obbligatoriamente della parametrizzazione mediante PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI.
--   Usata dalla sezione di verifica del trasmesso
--
-- REALIZZATORE: Angelo Marletta, 19/04/2010
--
-- MODIFICHE:
--   Angelo Marletta, 10/05/2010:
--      L'estrazione dei comunicati viene fatta dalle viste
--   Angelo Marletta, 25/06/2010:
--      Eliminati join con cd_prodotto_acquistato, cd_proiezione, cd_comunicato, cd_fascia
--      Aggiunto filtro che esclude comunicati fittizi
--   Angelo Marletta, 28/06/2010:
--      Ripristinato id_fascia di cd_proiezione nel recordset
--   Angelo Marletta, 10/09/2010:
--      Ottimizzazione query
--   Angelo Marletta, 06/10/2010:
--      Sistemato calcolo di id_tipo_break e tipo_break nel caso di break Locale e Frame Screen
--   Luigi Cipolla
--      Aggiunta la colonna numero_spot
--   Antonio Colucci,31/03/2011:
--      Inserita gestione tipo break Segui Film
-----------------------------------------------------------------------------------------------------
  PREV.DATA_COMMERCIALE
 ,PREV.ID_SALA
 ,PREV.ID_PROIEZIONE
 ,PREV.ID_BREAK
 ,PREV.ID_TIPO_BREAK
 ,PREV.ID_COMUNICATO
 ,PREV.ID_MATERIALE
 ,PREV.POSIZIONE
 ,PREV.POSIZIONE_RELATIVA
 ,PREV.DURATA_PROIEZIONE
 ,PREV.DURATA_BREAK
 ,PREV.numero_spot
 ,PREV.DURATA
 ,PREV.ID_FASCIA
 ,SUM(posizione_relativa * id_comunicato) OVER (PARTITION BY id_proiezione) hash_proiezione
 ,SUM(posizione_relativa * id_comunicato) OVER (PARTITION BY id_proiezione, id_break) hash_break
from
(
select
    data_commerciale,
    id_sala,
    id_proiezione,
    id_break,
    id_tipo_break,
    id_comunicato,
    id_materiale,
    posizione,
    ROW_NUMBER() OVER (PARTITION BY id_proiezione,id_break ORDER BY posizione) posizione_relativa,
    SUM(durata) OVER (PARTITION BY id_proiezione) durata_proiezione,
    SUM(durata) OVER (PARTITION BY id_proiezione, id_break) durata_break,
    COUNT(id_comunicato) OVER (PARTITION BY id_proiezione, id_break) numero_spot,
    durata,
    id_fascia
    from (
    select
        pr.data_proiezione data_commerciale,
        sc.id_sala,
        pr.id_proiezione,
        co.id_comunicato id_comunicato,
        case
            --Trailer
            when br.id_tipo_break = 1 then 'Trailer'
            --Inizio Film
            when br.id_tipo_break = 2 then 'Inizio Film'
            --Locale
            when br.id_tipo_break = 3 then 'Trailer'
            --Frame Screen
            when br.id_tipo_break = 4 then 'Trailer'
            --Top Spot
            when br.id_tipo_break = 5 then 'Inizio Film'
            --Segui Film
            when br.id_tipo_break = 25 then 'Inizio Film'
        end tipo_break,
        case
            --Trailer
            when br.id_tipo_break = 1 then 1
            --Inizio Film
            when br.id_tipo_break = 2 then 2
            --Locale
            when br.id_tipo_break = 3 then 1
            --Frame Screen
            when br.id_tipo_break = 4 then 1
            --Top Spot
            when br.id_tipo_break = 5 then 2
            --Segui Film
            when br.id_tipo_break = 25 then 2
        end id_tipo_break,
        mat.durata durata,
        case
            --Trailer
            when br.id_tipo_break = 1 then br.id_break
            --Inizio Film
            when br.id_tipo_break = 2 then br.id_break
            --Locale
            when br.id_tipo_break = 3 then
            (select id_break from cd_break where id_proiezione=pr.id_proiezione and id_tipo_break=1)
            --Frame Screen
            when br.id_tipo_break = 4 then
            (select id_break from cd_break where id_proiezione=pr.id_proiezione and id_tipo_break=1)
            --Top Spot
            when br.id_tipo_break = 5 then
            (select id_break from cd_break where id_proiezione=pr.id_proiezione and id_tipo_break=2)
            --Segui Film
            when br.id_tipo_break = 25 then
            (select id_break from cd_break where id_proiezione=pr.id_proiezione and id_tipo_break=2)
        end id_break,
        mat_pi.ID_MATERIALE,
        case
            --Trailer
            when br.id_tipo_break = 1 then co.posizione
            --Inizio Film
            when br.id_tipo_break = 2 then co.posizione-20
            --Locale
            when br.id_tipo_break = 3 then co.posizione-100
            --Frame Screen
            when br.id_tipo_break = 4 then -1
            --Top Spot
            when br.id_tipo_break = 5 then 92
            --Segui Film
            when br.id_tipo_break = 25 then co.posizione
        end posizione,
        sogg.DES_SOGG,
        pr.id_fascia
    from
        CD_SCHERMO sc,
        CD_PROIEZIONE pr,
        CD_BREAK br,
        CD_PRODOTTO_ACQUISTATO prod_acq,
        CD_MATERIALE_DI_PIANO mat_pi,
        CD_MATERIALE mat,
        CD_COMUNICATO co,
        CD_SOGGETTO_DI_PIANO sogg_pi,
        SOGGETTI sogg
    where
        --join
        pr.id_proiezione = br.id_proiezione
        and pr.id_schermo = sc.id_schermo
        and br.ID_BREAK = co.ID_BREAK
        and mat_pi.id_materiale_di_piano = co.id_materiale_di_piano
        and mat_pi.id_materiale = mat.id_materiale
        and prod_acq.ID_PRODOTTO_ACQUISTATO = co.ID_PRODOTTO_ACQUISTATO
        and co.ID_SOGGETTO_DI_PIANO = sogg_pi.ID_SOGGETTO_DI_PIANO
        and sogg_pi.COD_SOGG = sogg.COD_SOGG
        --filtri
        and sc.id_sala = nvl(PA_CD_ADV_CINEMA.FU_ID_SALA, sc.id_sala)
        and pr.DATA_PROIEZIONE BETWEEN PA_CD_ADV_CINEMA.FU_DATA_INIZIO AND PA_CD_ADV_CINEMA.FU_DATA_FINE
        and pr.flg_annullato = 'N'
        and br.id_tipo_break <> 24 --TRATTO TUTTI I BREAK TRANNE IL SUMMER_BREAK
        and br.flg_annullato = 'N'
        and co.flg_annullato='N'
        and co.flg_sospeso='N'
        and co.cod_disattivazione IS NULL
        and co.flg_tutela='N'
        and prod_acq.stato_di_vendita='PRE'
) where id_break is not null
) PREV
ORDER BY data_commerciale, id_sala, id_proiezione, id_tipo_break, posizione
/



