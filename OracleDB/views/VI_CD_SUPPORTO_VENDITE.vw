CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SUPPORTO_VENDITE
(COD_MEZZO, COD_GC, COD_DGC, COD_TIPO_CONTRATTO, COD_EDITORE, 
 COD_TESTATA_ED, COD_RETE, COD_PIANO, VERSIONE_PIANO, DATA_TRASMISSIONE, 
 COD_SOGG, DES_SOGG, FORMATO_DURATA, COD_MANIFESTAZIONE, STATO_VENDITA, 
 DATA_STATO_VENDITA, DATA_DECORR_INTERM, ORIGINE_RICAVO, COMPLETATO_AMM, COD_AREA, 
 COD_SEDE, COD_CLI_COMM, COD_CLI_AMM, COD_CLI_COMMITTENTE, COD_AGZ, 
 COD_CACQ, COD_VEND_RESP_CONT, COD_VEND_CLI, COD_VEND_AGZ, COD_VEND_CACQ, 
 COD_VEND_PROD, PERC_SSDA, PERC_DIR_AGZ, PERC_DIR_CACQ, PERC_DIR_VEND_CLI, 
 PERC_DIR_VEND_AGZ, PERC_DIR_VEND_CACQ, PERC_DIR_VEND_PROD, IMP_LORDO_EURO, IMP_NETTO_EURO, 
 IMP_SC_SAN_EURO, IMP_SC_REC_EURO, IMP_SC_FIN_EURO, IMP_SC_OMAG_EURO, COD_CONDIZIONE_PAGAMENTO, 
 COD_VENDITA, TIPO_SALA, STATO_PRODOTTO_SIPRALAB, STATO_CLIENTE_ESTERO, COD_LISTINO)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_SUPPORTO_VENDITE
--
-- DESCRIZIONE:
--   Estrae i comunicati del Mezzo Cinema per il Supporto Vendite, rispondenti ai parametri impostati
--   mediante la procedura PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI
--
-- REALIZZATORE: Luigi Cipolla - 29/12/2009
--
-- MODIFICHE:
--   Luigi Cipolla - 29/12/2009
--     Modificata la ripartizione degli importi per giorno/soggetto, coerente con la fatturazione.
--   Luigi Cipolla - 08/01/2010
--     Modificato il reperimento del DGC.
--   Luigi Cipolla - 12/02/2010
--     Correzione join con cd_importi_fatturazione.
--   Luigi Cipolla - 15/02/2010
--     Inserita vista intermedia VI_CD_BASE_SUPPORTO_VENDITE.
--   Luigi Cipolla - 24/05/2010
--     Valorizzazione colonna COD_VENDITA.
--   Luigi Cipolla - 16/06/2010
--     Modifica join con VI_PC_DGC_X_CINEMA con l'aggiunta della colonna tipo_sala.
--   Mauro Viel, 04/08/2011 [MV01]
--     Esposizione della percentuale di sconto sostitutivo di agenzia (PERC_SSDA) anche in assenza dell'ordine. 
--     Se PERC_SSDA e' nullo, verifico se agenzia oppure il centro media sono nulli. Se sono nulli restituisco 0,
--     altrimenti determino la percentuale di sconto in base alle condizioni di pagamento . 
--   Luigi Cipolla - 22/08/2011 [LC#01]
--     Esposizione delle condizioni di pagamento anche in assenza dell'ordine: 19 (Cambio merce) se la pianificazione 
--     e' cambio merce, 01 (45 giorni data fattura) altrimenti . 
-----------------------------------------------------------------------------------------------------
  PA_CD_MEZZO.fu_mezzo                                      COD_MEZZO
 ,PA_CD_MEZZO.fu_gest_comm                                  COD_GC
 ,V_DGC.DGC                                                 COD_DGC
 ,SPOT.TIPO_CONTRATTO                                       COD_TIPO_CONTRATTO
 ,'999'                                                     COD_EDITORE
 ,PIA.cod_testata_editoriale                                COD_TESTATA_ED
 ,to_char(null)                                             COD_RETE
 ,SPOT.id_piano                                             COD_PIANO
 ,SPOT.id_ver_piano                                         VERSIONE_PIANO
 ,SPOT.data_erogazione_prev                                 DATA_TRASMISSIONE
 ,SPOT.cod_sogg                                             COD_SOGG
 ,SPOT.descrizione                                          DES_SOGG
 ,COEFF.durata                                              FORMATO_DURATA
 ,PR_VEN.cod_man                                            COD_MANIFESTAZIONE
 ,SPOT.stato_di_vendita                                     STATO_VENDITA
 ,to_date(null)                                            DATA_STATO_VENDITA
 ,INTERM.DATA_DECORRENZA                                    DATA_DECORR_INTERM
 ,substr(PA_PC_COSTANTI.FU_GET_CONSTANT_ORIGINE_RICAVO,1,1)    ORIGINE_RICAVO
 ,SPOT.COMPLETATO_AMM                                       COMPLETATO_AMM
 ,PIA.cod_area                                              COD_AREA
 ,PIA.cod_sede                                              COD_SEDE
 ,PIA.id_cliente                                            COD_CLI_COMM
 ,CLI_AMM.ID_CLIENTE_FRUITORE                               COD_CLI_AMM
 ,SPOT.ID_CLIENTE_COMMITTENTE                               COD_CLI_COMMITTENTE
 ,INTERM.ID_AGENZIA                                         COD_AGZ
 ,INTERM.ID_CENTRO_MEDIA                                    COD_CACQ
 ,PIA.ID_RESPONSABILE_CONTATTO                              COD_VEND_RESP_CONT
 ,INTERM.ID_VENDITORE_CLIENTE                               COD_VEND_CLI
 ,to_char(null)                                            COD_VEND_AGZ
 ,to_char(null)                                            COD_VEND_CACQ
 ,to_char(null)                                            COD_VEND_PROD
 -- [MV01] [LC#01]
 ,nvl(SPOT.PERC_SCONTO_SOST_AGE,
      decode(INTERM.ID_AGENZIA||INTERM.ID_CENTRO_MEDIA, null, 0
                                                            , (SELECT MAX_DIR
                                                               FROM   COND_PAGAMENTO
                                                               WHERE  COD_CPAG = decode(PIA.flg_cambio_merce,'S','19','01') )
            )  
     )                                                     PERC_SSDA
 ,to_number(null)                                          PERC_DIR_AGZ
 ,to_number(null)                                          PERC_DIR_CACQ
 ,SPOT.PERC_VEND_CLI                                        PERC_DIR_VEND_CLI
 ,to_number(null)                                          PERC_DIR_VEND_AGZ
 ,to_number(null)                                          PERC_DIR_VEND_CACQ
 ,to_number(null)                                          PERC_DIR_VEND_PROD
 ,SPOT.IMP_LORDO                                            IMP_LORDO_EURO
 ,SPOT.IMP_NETTO                                            IMP_NETTO_EURO
 ,SPOT.IMP_SANATORIA                                        IMP_SC_SAN_EURO
 ,SPOT.IMP_RECUPERO                                         IMP_SC_REC_EURO
 ,0                                                         IMP_SC_FIN_EURO
 ,SPOT.IMP_SC_COMM                                          IMP_SC_OMAG_EURO
 -- [LC#01]
 ,nvl( SPOT.ID_COND_PAGAMENTO,
       decode(PIA.flg_cambio_merce,'S','19','01'))          COD_CONDIZIONE_PAGAMENTO
 ,decode( PR_VEN.flg_abbinato, 'N', 'STD', 'S', 'ABB')      COD_VENDITA
 ,decode( CIRC.flg_arena, 'N', 'SALA', 'S', 'ARENA')        TIPO_SALA
 ,PIA.FLG_SIPRA_LAB                                         STATO_PRODOTTO_SIPRALAB
 ,PIA.FLG_CLIENTE_ESTERO                                    STATO_CLIENTE_ESTERO
 ,PIA.ID_PC_LISTINI                                         COD_LISTINO
 
from
  VI_PC_DGC_X_CINEMA V_DGC,  -- vista di reperimento DGC
  ( select pp.id_prodotto_pubb, tp.cod_tipo_pubb
    from pc_tipi_pubblicita tp,
          cd_prodotto_pubb pp
    where tp.cod_tipo_pubb = pp.cod_tipo_pubb
    union
    select pp.id_prodotto_pubb, min(tp.cod_tipo_pubb)
    from pc_tipi_pubblicita tp,
         cd_tipo_pubb_gruppo tpg,
         cd_prodotto_pubb pp
    where tpg.id_gruppo_tipi_pubb = pp.id_gruppo_tipi_pubb
      and tp.cod_tipo_pubb = tpg.cod_tipo_pubb
    group by pp.id_prodotto_pubb
  ) PR_PUB,
  cd_circuito CIRC,
  cd_fruitori_di_piano CLI_AMM,
  cd_raggruppamento_intermediari INTERM,
  cd_prodotto_vendita PR_VEN,
  cd_coeff_cinema COEFF,
  cd_formato_acquistabile FORMATO,
  cd_pianificazione PIA,
  -- SPOT : comunicati validi, nel periodo richiesto, raggruppati per data e soggetto, con le informazioni di prodotto acquistato, importi e amministrative
  VI_CD_BASE_SUPPORTO_VENDITE SPOT
where PIA.id_piano = SPOT.id_piano
  and PIA.id_ver_piano = SPOT.id_ver_piano
  and FORMATO.id_formato = SPOT.id_formato
  and COEFF.id_coeff(+) = FORMATO.id_coeff
  and PR_VEN.id_prodotto_vendita = SPOT.id_prodotto_vendita
  and INTERM.id_raggruppamento = SPOT.id_raggruppamento
  and CLI_AMM.ID_FRUITORI_DI_PIANO(+) = SPOT.ID_FRUITORI_DI_PIANO
  and CIRC.id_circuito = PR_VEN.id_circuito
  -- Join di reperimento DGC
  and PR_PUB.id_prodotto_pubb = PR_VEN.ID_PRODOTTO_PUBB
  AND V_DGC.TIPO_PUBB = PR_PUB.cod_tipo_pubb
  AND V_DGC.testata_editoriale = PIA.cod_testata_editoriale
  and V_DGC.TIPO_SALA = decode( CIRC.flg_arena, 'N', 'SALA', 'S', 'ARENA')
/



