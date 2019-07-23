CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SIT_VENDUTO_PRO_20110224
(ID_PRODOTTO_ACQUISTATO, CIRCUITO, BREAK, MODALITA_VENDITA, COD_CATEGORIA_PRODOTTO, 
 DURATA_MEDIA, GIORNI_MEDI, NUM_SALE_MEDIO, TIPO_CONTRATTO, LORDO, 
 SANATORIA, RECUPERO, NETTO, IMP_SC_COMM, FLG_ARENA, 
 FLG_ABBINATO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_SIT_VENDUTO_PRODOTTO
--
-- DESCRIZIONE:
--   Estrae il venduto del prodotto, secondo la visibilita' dell'utente di sessione, rispondente ai parametri impostati
--   mediante le procedure PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI e PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI.
--
-- REALIZZATORE: Mauro Viel - 10/03/2010
--
-- MODIFICHE:
--   Michele Borgogno, 23/05/2010
--     Aggiunto cod_categoria_prodotto
--   Mauro Viel, 16/06/2010
--     Eliminato il raggrupppamento per  ID_PRODOTTO_ACQUISTATO sostituita la
--     min sulla durata con la sum in modo da raggruppare i prodotti x
--     CIRCUITO,DESC_TIPO_BREAK,DESC_MOD_VENDITA,COD_CATEGORIA_PRODOTTO,TIPO_CONTRATTO,FLG_ARENA,FLG_ABBINATO
--   Luigi Cipolla, 07/01/2011
--     Inserimento colonne giorni_medi, num_sale_medio e durata_media.
--
--  Mauro Viel 21/01/2011
--  Eliminata la colonna ID_PRODOTTO_ACQUISTATO
--  Mauro Viel 07/02/2011 inserita la somma dei giorni nella situazione del
--  venduto prodotto al variare del periodo
-- Mauro Viel 21/02/2011
--Sostituita la somma della durata e la somma delle sale con la media. 
-----------------------------------------------------------------------------------------------------
/* congelato
        decode(DESC_MOD_VENDITA, 'Libera', round(SUM(DURATA)/avg(num_giorni_totale)/avg(num_sale_giorno))
*/                               --, round(SUM(DURATA)/avg(num_giorni_totale)) ) durata_media,
        ID_PRODOTTO_ACQUISTATO,
        CIRCUITO,
        BREAK,
        MODALITA_VENDITA,
        CATEGORIA_PROD,
        round(avg(DURATA_MEDIA)) DURATA_MEDIA,
        --sum(DURATA_MEDIA)  DURATA_MEDIA,
        sum(GIORNI_MEDI)  GIORNI_MEDI,
        --sum(NUM_SALE_MEDIO)  NUM_SALE_MEDIO,
        round(avg(NUM_SALE_MEDIO))  NUM_SALE_MEDIO,
        TIPO_CONTRATTO,
        sum(LORDO)  LORDO,
        sum(SANATORIA) SANATORIA,
        sum(RECUPERO)  RECUPERO,
        sum(NETTO)  NETTO,
        sum(IMP_SC_COMM)  IMP_SC_COMM,
        FLG_ARENA,
        FLG_ABBINATO
from(
select
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
)
group by
ID_PRODOTTO_ACQUISTATO,
TIPO_CONTRATTO,
        CIRCUITO,
        BREAK,
        MODALITA_VENDITA,
        CATEGORIA_PROD,
        FLG_ARENA,
        FLG_ABBINATO,
        GIORNI_MEDI
order by CIRCUITO,
         BREAK,
         MODALITA_VENDITA,
         TIPO_CONTRATTO,
         FLG_ARENA,
         FLG_ABBINATO
/



