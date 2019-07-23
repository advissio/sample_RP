CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SIT_PROD_SETTIMANA
(ID_PRODOTTO_ACQUISTATO, PERIODO, CIRCUITO, BREAK, MODALITA_VENDITA, 
 COD_CATEGORIA_PRODOTTO, DURATA_MEDIA, GIORNI_MEDI, NUM_SALE_MEDIO, TIPO_CONTRATTO, 
 LORDO, SANATORIA, RECUPERO, NETTO, IMP_SC_COMM, 
 FLG_ARENA, FLG_ABBINATO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_SIT_PROD_SETTIMANA
--
-- DESCRIZIONE:
--   Estrae il venduto del prodotto per settimana, secondo la visibilita' dell'utente di sessione, rispondente ai parametri impostati
--   mediante le procedure PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI e PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI.
--
-- REALIZZATORE: Mauro Viel - 03/02/2011
--
-- MODIFICHE:
-----------------------------------------------------------------------------------------------------
/* congelato
        decode(DESC_MOD_VENDITA, 'Libera', round(SUM(DURATA)/avg(num_giorni_totale)/avg(num_sale_giorno))
*/                               --, round(SUM(DURATA)/avg(num_giorni_totale)) ) durata_media,
        --0 as ID_PRODOTTO_ACQUISTATO,
       -- sit.ID_PRODOTTO_ACQUISTATO,
                
        decode(sit.COD_CATEGORIA_PRODOTTO,'ISP', pa.ID_PRODOTTO_ACQUISTATO, 0) id_prodotto_acquistato,
        decode(irp.ANNO,null,to_char(pa.data_inizio,'DDMMYYYY')||'-'||to_char(pa.data_fine,'DDMMYYYY'),irp.ANNO||'-'||irp.ciclo||'-'||irp.PER) periodo,
        CIRCUITO,
        DESC_TIPO_BREAK AS BREAK,
        DESC_MOD_VENDITA AS MODALITA_VENDITA,
        sit.COD_CATEGORIA_PRODOTTO AS CATEGORIA_PROD,
        ROUND(SUM(DURATA)/AVG(NUM_GIORNI_TOTALE)) DURATA_MEDIA, 
        ROUND(AVG(NUM_GIORNI_TOTALE)) GIORNI_MEDI,
        ROUND(AVG(NUM_SALE_GIORNO))   NUM_SALE_MEDIO,
        TIPO_CONTRATTO,
        sum(sit.IMP_LORDO) AS LORDO,
        sum (sit.IMP_SANATORIA) AS SANATORIA,
        sum(sit.IMP_RECUPERO) AS RECUPERO,
        sum(sit.IMP_NETTO) AS NETTO,
        sum(IMP_SC_COMM) AS IMP_SC_COMM,
        FLG_ARENA,
        sit.FLG_ABBINATO
from vi_cd_base_situazione_venduto sit,
      cd_prodotto_acquistato pa,
      cd_prodotto_vendita pv,
      cd_prodotto_pubb pp,
      cd_importi_richiesti_piano irp
where pa.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA (+)
and   pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB (+)
and   sit.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO(+)
and   irp.ID_IMPORTI_RICHIESTI_PIANO = pa.ID_IMPORTI_RICHIESTI_PIANO
group by 
         decode(sit.COD_CATEGORIA_PRODOTTO,'ISP', pa.ID_PRODOTTO_ACQUISTATO, 0),
         decode(irp.ANNO,null,to_char(pa.data_inizio,'DDMMYYYY')||'-'||to_char(pa.data_fine,'DDMMYYYY'),irp.ANNO||'-'||irp.ciclo||'-'||irp.PER), 
         CIRCUITO,
         DESC_TIPO_BREAK,
         DESC_MOD_VENDITA,
         sit.COD_CATEGORIA_PRODOTTO,
         TIPO_CONTRATTO,
         FLG_ARENA,
         sit.FLG_ABBINATO
order by
        CIRCUITO,
        DESC_TIPO_BREAK,
        TIPO_CONTRATTO
/



