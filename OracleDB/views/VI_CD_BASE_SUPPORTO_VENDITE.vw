CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_BASE_SUPPORTO_VENDITE
(DATA_EROGAZIONE_PREV, COD_SOGG, DESCRIZIONE, ID_PIANO, ID_VER_PIANO, 
 STATO_DI_VENDITA, ID_PRODOTTO_ACQUISTATO, ID_FORMATO, ID_PRODOTTO_VENDITA, ID_RAGGRUPPAMENTO, 
 ID_FRUITORI_DI_PIANO, TIPO_CONTRATTO, DATA_INIZIO_PERIODO, DATA_FINE_PERIODO, NUM_GIORNI_TOTALE, 
 NUM_SALE_GIORNO, IMP_LORDO, IMP_SANATORIA, IMP_RECUPERO, IMP_NETTO, 
 IMP_SC_COMM, COMPLETATO_AMM, ID_ORDINE, PERC_SCONTO_SOST_AGE, PERC_VEND_CLI, 
 ID_CLIENTE_COMMITTENTE, ID_COND_PAGAMENTO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_BASE_SUPPORTO_VENDITE
--
-- DESCRIZIONE:
--   Estrae i comunicati del Mezzo Cinema per il Supporto Vendite, rispondenti ai parametri impostati
--   mediante la procedura PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI.
--   La vista e stata realizzata per essere utilizzata anche in ambito magazzino Cinema.
--
-- REALIZZATORE: Luigi Cipolla - 15/02/2010
--
-- MODIFICHE:
--   Luigi Cipolla, 24/02/2010
--     Inserimento colonne DATA_INIZIO_PERIODO e DATA_FINE_PERIODO
--   Simone Bottani, 01/06/2010
--     Aggiunto controllo sull'annullamento degli importi fatturazione
--   Luigi Cipolla, 07/09/2010
--     Arrotondamento importi alla quarta cifra decimale.
--   Luigi Cipolla, 15/09/2010
--     Revisione completa causa ripartizione importi di prodotto su tutti i giorni del periodo, indipendentemente
--     dalla trasmissione di comunicati.
--   Luigi Cipolla, 06/12/2010
--     Miglioramento delle prestazioni mediante l'introduzione della tavola cd_sintesi_prod_acq.
--   Luigi Cipolla, 07/01/2011
--     Inserimento colonne num_giorni_totale e num_sale_giorno.
--   Luigi Cipolla, 01/06/2011
--     Ottimizzazione estrazione [LC#1].
--   Luigi Cipolla, 03/06/2011
--     Completamento dell'intervento del 01/06/2011 [LC#2].
--   Mauro Viel, 04/08/2011 [MV01]
--     Esposizione delle condizioni di pagamento anche in assenza dell'ordine: 19 (Cambio merce) se la pianificazione 
--     e' cambio merce, 01 (45 giorni data fattura) altrimenti . 
--   Luigi Cipolla - 22/08/2011 [LC#3]
--     Trasferimento sulla vista VI_CD_SUPPORTO_VENDITE delle modifiche effettuate il 04/08/2011. 
--
-----------------------------------------------------------------------------------------------------
     SP_IMP.data_erogazione_prev
    ,SP_IMP.cod_sogg
    ,SP_IMP.descrizione
    ,SP_IMP.id_piano
    ,SP_IMP.id_ver_piano
    ,SP_IMP.stato_di_vendita
    ,SP_IMP.id_prodotto_acquistato
    ,SP_IMP.id_formato
    ,SP_IMP.id_prodotto_vendita
    ,SP_IMP.id_raggruppamento
    ,SP_IMP.id_fruitori_di_piano
    ,SP_IMP.TIPO_CONTRATTO
    ,SP_IMP.DATA_INIZIO                                      DATA_INIZIO_PERIODO
    ,SP_IMP.DATA_FINE                                        DATA_FINE_PERIODO
     /* news: estrazione di num_giorni_totale */
    ,SP_IMP.num_giorni_totale
     /* news: conteggio di num_sale_giorno */
    ,SP_IMP.num_sale_giorno
    ,round(SP_IMP.IMP_LORDO / SP_IMP.giorni_per_sogg ,4)     IMP_LORDO
    ,round(SP_IMP.IMP_SANATORIA / SP_IMP.giorni_per_sogg ,4) IMP_SANATORIA
    ,round(SP_IMP.IMP_RECUPERO / SP_IMP.giorni_per_sogg ,4)  IMP_RECUPERO
    ,round(SP_IMP.IMP_NETTO / SP_IMP.giorni_per_sogg ,4)     IMP_NETTO
    ,round(SP_IMP.IMP_SC_COMM / SP_IMP.giorni_per_sogg ,4)   IMP_SC_COMM
    ,decode( to_char(IMP_FATT.ID_ORDINE), null, 'N', 'S' )   COMPLETATO_AMM
    ,IMP_FATT.ID_ORDINE
    ,IMP_FATT.PERC_SCONTO_SOST_AGE
    ,IMP_FATT.PERC_VEND_CLI
    ,ORD.ID_CLIENTE_COMMITTENTE
    --[MV01] [LC#3]
    ,ORD.ID_COND_PAGAMENTO   
   from
     cd_ordine ORD,
     cd_importi_fatturazione IMP_FATT,
     -- SP_IMP : comunicati validi, nel periodo richiesto, raggruppati per data e soggetto, con le informazioni di prodotto acquistato e importi
    (select
       SP_ACQ.data_erogazione_prev
      ,SP_ACQ.cod_sogg
      ,SP_ACQ.descrizione
      ,SP_ACQ.id_soggetto_di_piano
      ,SP_ACQ.num_giorni_totale * SP_ACQ.num_soggetti_giorno giorni_per_sogg
       /* news: estrazione di num_giorni_totale */
      ,SP_ACQ.num_giorni_totale
       /* news: conteggio di num_sale_giorno */
     ,SP_ACQ.num_sale_giorno
      ,SP_ACQ.id_piano
      ,SP_ACQ.id_ver_piano
      ,SP_ACQ.stato_di_vendita
      ,SP_ACQ.id_prodotto_acquistato
      ,SP_ACQ.id_formato
      ,SP_ACQ.id_prodotto_vendita
      ,SP_ACQ.id_raggruppamento
      ,SP_ACQ.id_fruitori_di_piano
      ,SP_ACQ.DATA_INIZIO
      ,SP_ACQ.DATA_FINE
      ,IMP.id_importi_prodotto
      ,IMP.TIPO_CONTRATTO
      ,decode(IMP.TIPO_CONTRATTO,
              'C', decode( IMP.IMP_NETTO + IMP.IMP_SC_COMM, 0, 0, IMP.IMP_NETTO + IMP.IMP_SC_COMM + SP_ACQ.IMP_SANATORIA + SP_ACQ.IMP_RECUPERO),
              'D', IMP.IMP_NETTO + IMP.IMP_SC_COMM + decode(IMP_COMM.IMP_NETTO + IMP_COMM.IMP_SC_COMM, 0, SP_ACQ.IMP_SANATORIA + SP_ACQ.IMP_RECUPERO, 0))
         IMP_LORDO
      ,decode(IMP.TIPO_CONTRATTO,
              'C', decode( IMP_COMM.IMP_NETTO + IMP_COMM.IMP_SC_COMM, 0, 0, SP_ACQ.IMP_SANATORIA),
              'D', decode( IMP_COMM.IMP_NETTO + IMP_COMM.IMP_SC_COMM, 0, SP_ACQ.IMP_SANATORIA, 0)) IMP_SANATORIA
      ,decode(IMP.TIPO_CONTRATTO,
              'C', decode( IMP_COMM.IMP_NETTO + IMP_COMM.IMP_SC_COMM, 0, 0, SP_ACQ.IMP_RECUPERO),
              'D', decode( IMP_COMM.IMP_NETTO + IMP_COMM.IMP_SC_COMM, 0, SP_ACQ.IMP_RECUPERO, 0)) IMP_RECUPERO
      ,IMP.IMP_NETTO
      ,IMP.IMP_SC_COMM
     from
       cd_importi_prodotto IMP_COMM,
       cd_importi_prodotto IMP,
       -- SP_ACQ : comunicati validi, nel periodo richiesto, raggruppati per data e soggetto, con le informazioni di prodotto acquistato
      (select
            fw_SPOT_voluti.data_erogazione_prev
            ,fw_SPOT_voluti.cod_sogg
            ,fw_SPOT_voluti.descrizione
            ,fw_SPOT_voluti.id_soggetto_di_piano
            ,fw_SPOT_voluti.num_giorni_totale
            ,fw_SPOT_voluti.num_soggetti_giorno
             /* news: conteggio di num_sale_giorno */
            ,fw_SPOT_voluti.num_sale_giorno
            ,PR_ACQ.id_piano
            ,PR_ACQ.id_ver_piano
            ,PR_ACQ.stato_di_vendita
            ,PR_ACQ.id_prodotto_acquistato
            ,PR_ACQ.id_formato
            ,PR_ACQ.id_prodotto_vendita
            ,PR_ACQ.id_raggruppamento
            ,PR_ACQ.id_fruitori_di_piano
            ,PR_ACQ.imp_recupero
            ,PR_ACQ.imp_sanatoria
            ,PR_ACQ.DATA_INIZIO
            ,PR_ACQ.DATA_FINE
       from
         cd_prodotto_acquistato PR_ACQ,
         -- fw_SPOT_voluti : comunicati validi, nel periodo richiesto, raggruppati per data e soggetto
        (select
             SPOT_SOGG.id_prodotto_acquistato
            ,SPOT_SOGG.data_erogazione_prev
            ,SO_PI.cod_sogg
            ,SO_PI.descrizione
            ,SPOT_SOGG.id_soggetto_di_piano
            ,SPOT_SOGG.num_giorni_totale
            ,SPOT_SOGG.num_soggetti_giorno
             /* news: conteggio di num_sale_giorno */
            ,SPOT_SOGG.num_sale_giorno
         from
           cd_soggetto_di_piano SO_PI,
               -- SPOT_SOGG : comunicati validi, nel periodo richiesto, raggruppati per data e soggetto
              (-- prodotto acquistato interamente precedente a sysdate
               select
                 id_prodotto_acquistato
                ,id_soggetto_di_piano
                ,data_erogazione_prev
                ,num_giorni_totale
                ,num_soggetti_giorno
                 /* news: conteggio di num_sale_giorno */
                ,num_sale_giorno
               from cd_sintesi_prod_acq
               where data_fine < trunc(sysdate)
                 and ((data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                        or
                      (data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                        or
                      (data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                     )
               union
               -- prodotto acquistato a cavallo o successivo a sysdate
               select distinct -- [LC#2] aggiunta distinct a causa del prodotto cartesiano effettuato tra SPOT e PA_TOT nei casi di flag_giorno='EFF'
                    PA_TOT.id_prodotto_acquistato
                   ,SPOT.id_soggetto_di_piano
                   ,PA_TOT.data_erogazione_prev
                   ,PA_TOT.num_giorni_totale
                    /* news: conteggio di num_sale_giorno */
                   ,decode (flag_giorno, 'EFF', SPOT.num_soggetti_giorno, 1) num_soggetti_giorno   --[LC#2] aggiunta decode
                   /* news: conteggio di num_sale_giorno */
                   ,decode (flag_giorno, 'EFF', SPOT.num_sale_giorno, 0) num_sale_giorno           --[LC#2] aggiunta decode
                  from
                    (
                      -- [LC#1] inizio
                      -- sostituisce la tavola cd_comunicato
                      /* devo conteggiare num_sale_giorno e num_soggetti_giorno tra i soli comunicati validi */
                      select distinct
                        id_prodotto_acquistato, data_erogazione_prev, id_soggetto_di_piano
                        ,count(distinct id_sala) over (partition by id_prodotto_acquistato, data_erogazione_prev) num_sale_giorno
                        ,count(distinct id_soggetto_di_piano) over (partition by id_prodotto_acquistato,data_erogazione_prev) num_soggetti_giorno
                      from
                        cd_comunicato
                      where data_erogazione_prev between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE
                        and flg_annullato='N'
                        and flg_sospeso='N'
                        and cod_disattivazione is null
                      -- [LC#1] fine
                    ) SPOT,
                    -- PA_TOT : prodotti acquistati e relative informazioni con tutti i giorni compresi tra data_inizio e data_fine
                    (select
                       PA_giorni.id_prodotto_acquistato
                      ,PA_giorni.data_inizio
                      ,PA_giorni.data_fine
                      ,PA_giorni.giorno data_erogazione_prev
                      ,PA_giorni.num_giorni_totale
                      ,nvl(PA_giorni_eff.flag_giorno, PA_giorni.flag_giorno) flag_giorno
                     from
                       -- PA_giorni: prodotti acquistati con tutti i giorni compresi tra data_inizio e data_fine
                       (select
                          P_A.id_prodotto_acquistato
                         ,P_A.data_inizio
                         ,P_A.data_fine
                         ,giorni.giorno
                         ,P_A.data_fine - P_A.data_inizio +1 num_giorni_totale
                         ,'ANN' flag_giorno
                        from
                          -- giorni : generatore di giorni
                          (select PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO -1 + rownum as giorno
                           from
                             cd_coeff_cinema,
                             cd_tipo_cinema
                           where rownum <= PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE - PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO +1
                          ) giorni,
                          -- P_A : prodotti acquistati validi nel periodo richiesto
                          (select
                             PA.id_prodotto_acquistato,
                             PA.data_inizio,
                             PA.data_fine
                           from
                             cd_prodotto_acquistato PA
                           where PA.data_fine >= trunc(sysdate) and
                                 ((PA.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                   or
                                   (PA.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                   or
                                   (PA.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                 )
                             and flg_annullato='N'
                             and flg_sospeso='N'
                          ) P_A
                        where giorni.giorno between P_A.data_inizio and P_A.data_fine
                       ) PA_giorni,
                       -- PA_giorni_eff :
                       (select distinct
                          PA.id_prodotto_acquistato
                         ,PA.data_inizio
                         ,PA.data_fine
                         ,giorni_eff.data_erogazione_prev
                         ,'EFF' flag_giorno
                        from
                          cd_comunicato giorni_eff,
                          cd_prodotto_acquistato PA
                        where PA.data_fine >= trunc(sysdate) and
                                 ((PA.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                   or
                                   (PA.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                   or
                                   (PA.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                 )
                          and PA.flg_annullato='N'
                          and PA.flg_sospeso='N'
                          and giorni_eff.id_prodotto_acquistato = PA.id_prodotto_acquistato
                          and giorni_eff.flg_annullato='N'
                          and giorni_eff.flg_sospeso='N'
                          and giorni_eff.cod_disattivazione is null
                       ) PA_giorni_eff
                     where PA_giorni.id_prodotto_acquistato = PA_giorni_eff.id_prodotto_acquistato(+)
                       and PA_giorni.giorno = PA_giorni_eff.data_erogazione_prev(+)
                    ) PA_TOT
                  where SPOT.id_prodotto_acquistato = PA_TOT.id_prodotto_acquistato
                    /* effettua il prodotto cartesiano SPOT-PA_TOT solo se flag_giorno='EFF', cioe' quando il giorno da PA_TOT = ANN e quindi
                       e' assente in SPOT. */
                    and SPOT.data_erogazione_prev = decode (flag_giorno, 'EFF', PA_TOT.data_erogazione_prev, SPOT.data_erogazione_prev)
              ) SPOT_SOGG
         where SPOT_SOGG.data_erogazione_prev between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE
           and SO_PI.id_soggetto_di_piano = SPOT_SOGG.id_soggetto_di_piano
        ) fw_SPOT_voluti
       where PR_ACQ.id_prodotto_acquistato = fw_SPOT_voluti.id_prodotto_acquistato
      ) SP_ACQ
     where IMP.id_prodotto_acquistato = SP_ACQ.id_prodotto_acquistato
       and IMP_COMM.id_prodotto_acquistato = SP_ACQ.id_prodotto_acquistato
       and IMP_COMM.TIPO_CONTRATTO = 'C'
    ) SP_IMP
   where SP_IMP.IMP_LORDO >0 -- esclude le righe con tutti gli importi a 0 (tutto Direzionale o tutto Commerciale)
     and IMP_FATT.id_importi_prodotto(+) = SP_IMP.id_importi_prodotto
     and IMP_FATT.flg_annullato(+) = 'N'
     and IMP_FATT.id_soggetto_di_piano(+) = SP_IMP.id_soggetto_di_piano
     and SP_IMP.data_erogazione_prev between IMP_FATT.DATA_INIZIO(+) and IMP_FATT.DATA_FINE(+)
     and ORD.ID_ORDINE(+) = IMP_FATT.ID_ORDINE
/



