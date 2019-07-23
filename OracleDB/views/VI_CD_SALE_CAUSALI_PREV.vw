CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SALE_CAUSALI_PREV
(ID_SALA, DATA_RIF, ID_CODICE_RESP, DESC_CODICE_PREV)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_SALE_CAUSALI_PREV
--
-- DESCRIZIONE:
--   Estrae l'elenco di delle causali impostate su tutte le sale in un determinato periodo
--   fatta ECCEZIONE per le sale appartenenti a cinema VIRTUALI
--   Necessita obbligatoriamente della parametrizzazione mediante PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI
--   per l'impostazione delle date di osservazione.
--   Usata dalla sezione di verifica del trasmesso
--
-- REALIZZATORE: Antonio Colucci Teoresi srl, 22/09/2010
-- MODIFICHE:     Antonio Colucci Teoresi srl, 02/12/2010
--            	Inserita colonna DESC_CODICE_PREV
-----------------------------------------------------------------------------------------------------
    distinct 
        id_sala,
        data_rif,
        sum(id_codice_resp) over (partition by id_sala,data_rif) id_codice_resp,
        VENCD.fu_cd_string_agg(desc_codice_prev) over (partition by id_sala,data_rif) desc_codice_prev
    from(
    select
        cd_sala_indisp.id_sala,
        cd_sala_indisp.data_rif,
        cd_sala_indisp.id_codice_resp,
        cd_codice_resp.desc_codice desc_codice_prev
        from 
            cd_sala_indisp,
            cd_codice_resp
        where cd_sala_indisp.data_rif between pa_cd_adv_cinema.fu_data_inizio and pa_cd_adv_cinema.fu_data_fine
        and cd_codice_resp.id_codice_resp = cd_sala_indisp.id_codice_resp
        union
        select
        cd_schermo.id_sala,
        cd_proiezione.data_proiezione data_rif,
        null id_codice_resp,
        null desc_codice_prev
        from cd_proiezione,cd_schermo
             ,cd_sala,cd_cinema
        where cd_proiezione.id_schermo = cd_schermo.id_schermo
        and cd_proiezione.data_proiezione between pa_cd_adv_cinema.fu_data_inizio and pa_cd_adv_cinema.fu_data_fine
        and cd_schermo.id_sala = cd_sala.id_sala
        and cd_sala.id_cinema = cd_cinema.id_cinema
        and cd_cinema.flg_virtuale = 'N'
    )
/



