CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_COMUNICATO_OLD
(ID, ID_BREAK, ID_MATERIALE, POSIZIONE, DES_SOGG)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_COMUNICATO
--
-- DESCRIZIONE:
--   Estrae i Comunicati validi per la messa in onda.
--   Necessita obbligatoriamente della parametrizzazione mediante PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI.
--   Se si cercano i comunicati relativi a una singola sala si puo usare la funzione PA_CD_ADV_CINEMA.IMPOSTA_SALA
--   Usata dal sistema ADV_Cinema per la trasmissione delle playlist verso i cinema.
--
-- REALIZZATORE: Colucci Antonio, 22/01/2010
--
-- Modifiche: Antonio Colucci, 23/03/2010
--              Inserimento funzione INSERT per ottimizzazione query ai fini delle performance
--              per estrazione comunicati Trailer e Inizio Film
--            Antonio Colucci,  16/03/2010
--              Inserita gestione comunicati per tipologia break Locale
--            Angelo Marletta, 06/07/2010
--              Miglioramento prestazioni
--            Angelo Marletta, 03/08/2010
--              Aggiunto filtro per parametro id_sala (opzionale)             
--            Angelo Marletta, 03/08/2010
--              Ottimizzazione con utilizzo id id_break in cd_comunicato             
-----------------------------------------------------------------------------------------------------
ID, ID_BREAK, ID_MATERIALE, POSIZIONE, DES_SOGG from
(
    --COMUNICATI REALI
    select 
        co.ID_COMUNICATO ID,
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
        end id_break,
        mat_pi.ID_MATERIALE,
        case
            --Trailer
            when br.id_tipo_break = 1 then co.posizione
            --Inizio Film
            when br.id_tipo_break = 2 then co.posizione
            --Locale
            when br.id_tipo_break = 3 then co.posizione-100
            --Frame Screen
            when br.id_tipo_break = 4 then -1
            --Top Spot
            when br.id_tipo_break = 5 then 92
        end posizione,
        sogg.DES_SOGG
    from
        CD_SCHERMO sc,
        CD_PROIEZIONE pr,
        CD_BREAK br,
        CD_PRODOTTO_ACQUISTATO prod_acq,
        CD_MATERIALE_DI_PIANO mat_pi,
        CD_COMUNICATO co,
        CD_SOGGETTO_DI_PIANO sogg_pi,
        SOGGETTI sogg
    where
        --join
        pr.id_proiezione = br.id_proiezione
        and pr.id_schermo = sc.id_schermo
        and br.ID_BREAK = co.ID_BREAK
        and mat_pi.id_materiale_di_piano = co.id_materiale_di_piano
        and prod_acq.ID_PRODOTTO_ACQUISTATO = co.ID_PRODOTTO_ACQUISTATO
        and co.ID_SOGGETTO_DI_PIANO = sogg_pi.ID_SOGGETTO_DI_PIANO
        and sogg_pi.COD_SOGG = sogg.COD_SOGG
        --filtri
        and sc.id_sala = nvl(PA_CD_ADV_CINEMA.FU_ID_SALA, sc.id_sala)
        and pr.DATA_PROIEZIONE BETWEEN PA_CD_ADV_CINEMA.FU_DATA_INIZIO AND PA_CD_ADV_CINEMA.FU_DATA_FINE
        and pr.flg_annullato = 'N'
        and br.id_tipo_break <= 5
        and br.flg_annullato = 'N'
        and co.flg_annullato='N'
        and co.flg_sospeso='N'
        and co.cod_disattivazione IS NULL
        and co.flg_tutela='N'
        and prod_acq.stato_di_vendita='PRE'
UNION ALL
    --GINGLE DI APERTURA TRAILER E TOPSPOT
    select distinct
        case
            when br.id_tipo_break = 1 then pr.id_schermo + pr.ID_FASCIA*1000
            when br.id_tipo_break = 5 then pr.id_schermo + pr.ID_FASCIA*1000 + 5000
            else null
        end ID, -- attribuisco id_comunicato in modo da renderlo univoco nella giornata
        case
            when br.id_tipo_break = 1 then br.id_break
            when br.id_tipo_break = 5 then (select id_break from cd_break where id_proiezione=pr.id_proiezione and id_tipo_break=2)
            else null
        end id_break,
        --Materiale 237 e il Gingle SIPRA
        237 id_materiale,
        case
            when br.id_tipo_break = 1 then -2
            when br.id_tipo_break = 5 then 91
            else null
        end posizione,
        case
            when br.id_tipo_break = 1 then 'GINGLE TRAILER'
            when br.id_tipo_break = 5 then 'GINGLE TOP SPOT'
            else null
        end DES_SOGG
    from
        CD_SCHERMO sc,
        CD_PROIEZIONE pr,
        CD_BREAK br,
        CD_PRODOTTO_ACQUISTATO prod_acq,
        CD_MATERIALE_DI_PIANO mat_pi,
        CD_COMUNICATO co,
        CD_SOGGETTO_DI_PIANO sogg_pi,
        SOGGETTI sogg
    where
        --join
        pr.id_proiezione = br.id_proiezione
        and pr.id_schermo = sc.id_schermo
        and br.ID_BREAK = co.ID_BREAK
        and mat_pi.id_materiale_di_piano = co.id_materiale_di_piano
        and prod_acq.ID_PRODOTTO_ACQUISTATO = co.ID_PRODOTTO_ACQUISTATO
        and co.ID_SOGGETTO_DI_PIANO = sogg_pi.ID_SOGGETTO_DI_PIANO
        and sogg_pi.COD_SOGG = sogg.COD_SOGG
        --filtri
        and sc.id_sala = nvl(PA_CD_ADV_CINEMA.FU_ID_SALA, sc.id_sala)
        and pr.DATA_PROIEZIONE BETWEEN PA_CD_ADV_CINEMA.FU_DATA_INIZIO AND PA_CD_ADV_CINEMA.FU_DATA_FINE
        and pr.flg_annullato = 'N'
        and br.id_tipo_break in (1,5)
        and br.flg_annullato = 'N'
        and co.flg_annullato='N'
        and co.flg_sospeso='N'
        and co.cod_disattivazione IS NULL
        and co.flg_tutela='N'
        and prod_acq.stato_di_vendita='PRE'
) where id_break is not null
/



