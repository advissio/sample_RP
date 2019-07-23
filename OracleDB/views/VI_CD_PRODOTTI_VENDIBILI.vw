CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_PRODOTTI_VENDIBILI
(ID_PRODOTTO_ACQUISTATO, DATA_INIZIO_PERIODO, DATA_FINE_PERIODO, PERIODO, CIRCUITO, 
 BREAK, MODALITA_VENDITA, CATEGORIA_PROD, DURATA_MEDIA, GIORNI_MEDI, 
 NUM_SALE_MEDIO, TIPO_CONTRATTO, LORDO, SANATORIA, RECUPERO, 
 NETTO, IMP_SC_COMM, FLG_ARENA, FLG_ABBINATO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica vi_cd_prodotti_vendibili
--
-- DESCRIZIONE:
--  Estrae i prodotti vendibili , secondo la visibilita' dell'utente di sessione, rispondente ai parametri impostati
--   mediante le procedure PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI e PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI.
--
-- REALIZZATORE: Mauro Viel - 24/02/2011
--
-- MODIFICHE:            
 0 as id_prodotto_acquistato,
               per.data_iniz  as DATA_INIZIO_PERIODO,
               per.data_fine as DATA_FINE_PERIODO,
               per.ANNO ||'-'|| per.ciclo||'-'||per.PER as periodo, 
               cir.NOME_CIRCUITO as circuito ,
               tb.DESC_TIPO_BREAK as break,  
               mod_ven.DESC_MOD_VENDITA as MODALITA_VENDITA ,
               pr_pub.COD_CATEGORIA_PRODOTTO as CATEGORIA_PROD , 
               0 as DURATA_MEDIA, 
               0 as GIORNI_MEDI,
               0 as NUM_SALE_MEDIO,
              v_tipo_contratto.tipo_contratto as TIPO_CONTRATTO,
               0 as LORDO,
               0 as SANATORIA,
               0 as RECUPERO,
               0 as NETTO,
               0 as IMP_SC_COMM,
               '' as FLG_ARENA,
               pv.FLG_ABBINATO as FLG_ABBINATO 
        from periodi per,
             cd_prodotto_vendita pv,
             cd_circuito cir,
             cd_tipo_break tb,
             cd_tariffa tar,
             cd_listino li,
             cd_prodotto_pubb pr_pub,
             cd_modalita_vendita mod_ven,
             (select 'C' as tipo_contratto  from dual
                union
              select 'D' as tipo_contratto  from dual
             ) v_tipo_contratto
        where per.data_iniz>= pa_cd_supporto_vendite.FU_DATA_INIZIO
        and   per.data_fine<= pa_cd_supporto_vendite.FU_DATA_FINE
        and   pv.FLG_ANNULLATO = 'N'
        and   pv.ID_CIRCUITO = cir.ID_CIRCUITO
        and   pv.ID_TIPO_BREAK = tb.ID_TIPO_BREAK (+)
        and   tar.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA
        and   pv.ID_PRODOTTO_PUBB = pr_pub.ID_PRODOTTO_PUBB
        and   pv.ID_MOD_VENDITA =  mod_ven.ID_MOD_VENDITA
        and   pr_pub.COD_CATEGORIA_PRODOTTO = nvl(pa_cd_situazione_venduto.FU_CATEGORIA_PUBB,pr_pub.COD_CATEGORIA_PRODOTTO)
        and   li.ID_LISTINO = tar.ID_LISTINO
        and   tar.DATA_INIZIO >= pa_cd_supporto_vendite.FU_DATA_INIZIO
        and   tar.DATA_FINE <= pa_cd_supporto_vendite.FU_DATA_FINE
/



