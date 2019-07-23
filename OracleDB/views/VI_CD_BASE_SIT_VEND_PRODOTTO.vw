CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_BASE_SIT_VEND_PRODOTTO
(DATA_INIZIO_PERIODO, DATA_FINE_PERIODO, ID_PRODOTTO_ACQUISTATO, CIRCUITO, BREAK, 
 MODALITA_VENDITA, CATEGORIA_PROD, DURATA_MEDIA, GIORNI_MEDI, NUM_SALE_MEDIO, 
 TIPO_CONTRATTO, LORDO, SANATORIA, RECUPERO, NETTO, 
 IMP_SC_COMM, FLG_ARENA, FLG_ABBINATO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_BASE_SIT_VEND_PRODOTTO
--
-- DESCRIZIONE:
--   Estrae le informazioni base per il venduto del prodotto, secondo la visibilita' dell'utente di sessione, rispondente ai parametri impostati
--   mediante le procedure PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI e PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI.
--
-- REALIZZATORE: Mauro Viel - 24/02/2011
--
-- MODIFICHE:
        data_inizio_periodo,
        data_fine_periodo,
        decode(COD_CATEGORIA_PRODOTTO,'ISP', ID_PRODOTTO_ACQUISTATO, 0) ID_PRODOTTO_ACQUISTATO,
        CIRCUITO,
        DESC_TIPO_BREAK AS BREAK,
        DESC_MOD_VENDITA AS MODALITA_VENDITA,
        COD_CATEGORIA_PRODOTTO AS CATEGORIA_PROD,
        ROUND(SUM(DURATA)/AVG(NUM_GIORNI_TOTALE)) DURATA_MEDIA,
        ROUND(AVG(NUM_GIORNI_TOTALE)) GIORNI_MEDI,
        ROUND(AVG(NUM_SALE_GIORNO))   NUM_SALE_MEDIO,
        TIPO_CONTRATTO,
        sum(IMP_LORDO) AS LORDO,
        sum (IMP_SANATORIA) AS SANATORIA,
        sum(IMP_RECUPERO) AS RECUPERO,
        sum(IMP_NETTO) AS NETTO,
        sum(IMP_SC_COMM) AS IMP_SC_COMM,
        FLG_ARENA,
        FLG_ABBINATO
from vi_cd_base_situazione_venduto
group by decode(COD_CATEGORIA_PRODOTTO,'ISP', ID_PRODOTTO_ACQUISTATO, 0),
        CIRCUITO,
        DESC_TIPO_BREAK,
        DESC_MOD_VENDITA,
        COD_CATEGORIA_PRODOTTO,
        TIPO_CONTRATTO,
        FLG_ARENA,
        FLG_ABBINATO,
        data_inizio_periodo,
        data_fine_periodo
/



