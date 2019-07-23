CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_LIQUIDAZIONE_ESERCENTE
(ID_QUOTA_ESERCENTE, COD_ESERCENTE, ESERCENTE, QUOTA, STATO_LAVORAZIONE, 
 DATA_INIZIO, DATA_FINE)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_LIQUIDAZIONE_ESERCENTE
--
-- DESCRIZIONE:
--   Estrae la liquidazione esercente,  per gli stati diversi dalla 
--   anteprima
--   
--
-- REALIZZATORE: Mauro Viel Altran  - 21/04/2010
--
-- MODIFICHE:
--   
--
-----------------------------------------------------------------------------------------------------
distinct q.id_quota_esercente,es.cod_esercente, es.ragione_sociale, q.quota_esercente, q.stato_lavorazione,liq.data_inizio,liq.data_fine
        from vi_cd_societa_gruppo gr, vi_cd_gruppo_esercente ge,  vi_cd_societa_esercente es, cd_liquidazione liq, cd_quota_esercente q
        where gr.cod_esercente(+) = es.cod_esercente
        and ge.id_gruppo_esercente = gr.id_gruppo_esercente
        and q.id_liquidazione = liq.id_liquidazione
        and es.cod_esercente = q.cod_esercente
        and q.STATO_LAVORAZIONE != 'ANT'
        order by es.ragione_sociale
/



