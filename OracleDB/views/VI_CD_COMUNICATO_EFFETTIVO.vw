CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_COMUNICATO_EFFETTIVO
(DATA_COMMERCIALE, ID_SALA, ID_PROIEZIONE, ID_BREAK, ID_TIPO_BREAK, 
 ID_COMUNICATO, ID_MATERIALE, POSIZIONE, POSIZIONE_RELATIVA, PROGRESSIVO, 
 DATA_INIZIO_PROIEZIONE, DATA_INIZIO_BREAK, DATA_EROGAZIONE_EFF, DURATA_PREV, DURATA_EFF, 
 DURATA_BREAK, HASH_PROIEZIONE, HASH_BREAK, FLAG_IERI)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_COMUNICATO_EFFETTIVO
--
-- DESCRIZIONE:
--   Estrae i comunicati effettivi proiettati nelle sale
--   Per ogni break e proiezione viene calcolato un hash che tiene conto dell'ordine effettivo di
--   trasmissione dei comunicati
--   L'hash viene calcolato come la somma dei prodotti tra id comunicato e posizione relativa
--   all'interno del break o della proiezione corrispondente
--   Necessita obbligatoriamente della parametrizzazione mediante PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI.
--   Legge anche la parametrizzazione tramite mediante PA_CD_ADV_CINEMA.IMPOSTA_SALA.
--   Usata dalla sezione di verifica del trasmesso
--
-- REALIZZATORE: Angelo Marletta, 20/04/2010
--
--   Modifiche:
--    04/05/2010, Angelo Marletta
--      Cambiato calcolo inizio proiezione
--      Aggiunto ordinamento
--    09/09/2010, Angelo Marletta
--      Filtro su data commerciale sostituito con filtro su data erogazione effettiva
--      Query ottimizzata
--    06/10/2010, Angelo Marletta
--      Rimosso utilizzo di vi_cd_comunicato (prestazioni)
--      Aggiunto flag_ieri, impostato la playlist effettiva e quella del giorno precedente
--    07/10/2010, Angelo Marletta
--      Perfezionato il raggruppamento di proiezioni e break anche nei casi piu anomali
--    31/03/2011, Antonio Colucci
--      Inserita Gestione Segui il Film
-----------------------------------------------------------------------------------------------------
    data_commerciale,id_sala,id_proiezione,id_break,id_tipo_break,id_comunicato,id_materiale,
    posizione,posizione_relativa,progressivo,
    data_inizio_proiezione,data_inizio_break,
    data_erogazione_eff,durata_prev,durata_eff,durata_break,
    SUM(posizione_relativa * id_comunicato) OVER (PARTITION BY id_sala,id_proiezione, progressivo) hash_proiezione,
    SUM(posizione_relativa * id_comunicato) OVER (PARTITION BY id_sala,id_proiezione, id_break, progressivo) hash_break,
    flag_ieri
from (
SELECT
    data_commerciale,flag_ieri,id_sala,id_proiezione,id_break,progressivo_proiezione progressivo,id_tipo_break,id_comunicato,id_materiale,posizione,data_erogazione_eff,durata_prev,durata_eff,
    --calcolo data inizio proiezione
    min(data_erogazione_eff) over (partition by data_commerciale,id_sala,id_proiezione,progressivo_proiezione) data_inizio_proiezione,
    --calcolo data inizio break
    min(data_erogazione_eff) OVER (PARTITION BY data_commerciale,id_sala,id_proiezione,progressivo_proiezione,id_tipo_break) data_inizio_break,
    --calcolo posizione relativa
    ROW_NUMBER() OVER (PARTITION BY data_commerciale,id_sala,id_proiezione,progressivo_proiezione,id_tipo_break ORDER BY data_erogazione_eff) posizione_relativa,
    --calcolo durata break
    sum(durata_eff) over (PARTITION BY data_commerciale,id_sala,id_proiezione,progressivo_proiezione,id_tipo_break) durata_break
FROM
    (
    select t3.*, sum(nuova_proiezione) over (partition by data_commerciale,id_sala order by data_erogazione_eff) progressivo_proiezione from (
    select
        t2.*,
        case
            when id_tipo_break=1 AND nuovo_break=1 then 1
            when lag(id_tipo_break) over(partition by data_commerciale,id_sala,id_proiezione order by data_erogazione_eff) = id_tipo_break
            AND lag(progressivo) over(partition by data_commerciale,id_sala,id_proiezione order by data_erogazione_eff) != progressivo then 1
            else 0
        end nuova_proiezione
    from (
    select
        t1.*,
        case
            when row_number() over (partition by data_commerciale,id_sala,id_proiezione,id_break order by data_erogazione_eff) = 1
            OR lag(id_tipo_break) over(partition by data_commerciale,id_sala,id_proiezione order by data_erogazione_eff) != id_tipo_break
            OR (lag(id_tipo_break) over(partition by data_commerciale,id_sala,id_proiezione order by data_erogazione_eff) = id_tipo_break
                AND lag(progressivo) over(partition by data_commerciale,id_sala,id_proiezione order by data_erogazione_eff) != progressivo) then 1
            else 0
        end nuovo_break
    from (
        select
            trunc(data_erogazione_eff-1/4) data_commerciale,
            decode(data_erogazione_prev,trunc(data_erogazione_eff-1/4)-1,1,0) flag_ieri,
            co.id_sala,
            br.id_proiezione,
            case
                --Trailer
                when br.id_tipo_break = 1 then br.id_break
                --Inizio Film
                when br.id_tipo_break = 2 then br.id_break
                --Locale
                when br.id_tipo_break = 3 then
                (select id_break from cd_break where id_proiezione=br.id_proiezione and id_tipo_break=1)
                --Frame Screen
                when br.id_tipo_break = 4 then
                (select id_break from cd_break where id_proiezione=br.id_proiezione and id_tipo_break=1)
                --Top Spot
                when br.id_tipo_break = 5 then
                (select id_break from cd_break where id_proiezione=br.id_proiezione and id_tipo_break=2)
                --Segui Film
                when br.id_tipo_break = 25 then
                (select id_break from cd_break where id_proiezione=br.id_proiezione and id_tipo_break=2)
            end id_break,
            adv.progressivo,
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
                --Segui il Film
                when br.id_tipo_break = 25 then 2
            end id_tipo_break,
            co.id_comunicato,
            mat.id_materiale,
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
                --Segui il Film
                when br.id_tipo_break = 25 then co.posizione
            end posizione,
            adv.data_erogazione_eff,
            mat.durata durata_prev,
            adv.durata durata_eff,
            CASE WHEN (adv.durata >= mat.durata) THEN 1
            ELSE 0 END durata_ok
        from
            cd_adv_comunicato adv,
            cd_comunicato co,
            cd_break br,
            cd_materiale_di_piano matp,
            cd_materiale mat
        where
            adv.id_comunicato(+)=co.id_comunicato
            AND co.id_break = br.id_break
            AND co.id_materiale_di_piano = matp.id_materiale_di_piano
            AND matp.id_materiale = mat.id_materiale
            AND co.data_erogazione_prev BETWEEN pa_cd_adv_cinema.fu_data_inizio-1 AND pa_cd_adv_cinema.fu_data_fine
            AND co.id_sala = NVL(pa_cd_adv_cinema.fu_id_sala, co.id_sala)
        ) t1 WHERE
            data_commerciale BETWEEN pa_cd_adv_cinema.fu_data_inizio AND pa_cd_adv_cinema.fu_data_fine
        ) t2
        ORDER BY data_commerciale,id_sala,data_erogazione_eff
        ) t3
    ) EFF
)
/



