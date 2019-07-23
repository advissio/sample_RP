CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_FATTURAZIONE
(COD_MEZZO, COD_GC, COD_SOTTOSISTEMA, COD_PIANO, VERSIONE_PIANO, 
 PRG_ORDINE, ID_IMPORTI_FATTURAZIONE, COD_TIPO_CONTRATTO, IND_SSDA, PERC_SSDA, 
 COD_CONDIZIONE_PAGAMENTO, COD_CLI_COMM, TIPO_COMMITTENTE, COD_CLI_COMMITTENTE, COD_CLI_AMM, 
 COD_AREA, COD_SEDE, COD_AGZ, COD_CACQ, COD_VEND_RESP_CONT, 
 COD_VEND_CLI, DATA_DECORR_INTERM, PERC_DIR_VEND_CLI, COD_VEND_AGZ, COD_VEND_CACQ, 
 COD_VEND_PROD, PERC_DIR_AGZ, PERC_DIR_CACQ, PERC_DIR_VEND_AGZ, PERC_DIR_VEND_CACQ, 
 PERC_DIR_VEND_PROD, DES_PRODOTTO, COD_TESTATA_ED, DATA_INIZIO, DATA_FINE, 
 DATA_PRIMA_PRENOTAZIONE, COD_SOGG, DES_SOGG, STATO_VENDITA, STATO_CONTABILE, 
 DATA_STATO_CONTABILE, FLAG_INV_FATT, FLG_SOSPESO, DATA_FATTURAZIONE, DGC_TC_ID, 
 LORDO, NETTO, SC_TECNICI, SC_COMM, COD_TIPO_PRODUZ, 
 UNI_MIS, FORMATO_DURATA, TIPO_SALA, FAT_ANNULLATO, COD_CATEGORIA_PRODOTTO)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_FATTURAZIONE
--
-- DESCRIZIONE:
--   Estrae i comunicati del Mezzo Cinema per la Fatturazione, rispondenti ai parametri impostati
--   mediante la procedura PA_CD_FATTURAZIONE.PR_SET_PARAMETRI
--
-- REALIZZATORE: Luigi Cipolla - 05/01/2010
--
-- MODIFICHE:
--   Luigi Cipolla - 13/01/2010
--   Luigi Cipolla - 22/01/2010
--     Esclusi importi di fatturazione pari a 0 nel caso di stato fatturazione 'DAT'
--   Luigi Cipolla - 17/05/2010
--     Introduzione delle tipologie di estrazione "CO" e "RG"
--   Simone Bottani - 01/06/2010
--     Aggiunto controllo sull'annullamento degli importi fatturazione
--   Luigi Cipolla - 28/07/2010 [LC#4]
--     Modificata origine del campo DATA_STATO_CONTABILE da DATA_FATTURAZIONE a DATAMOD_FATTURAZIONE.
--     Aggiunto NVL su PA_CD_FATTURAZIONE.FU_DATA_FINE.
--   Simone Bottani - 06/08/2010
--     Nella ricerca EP ed ED vengono considerati anche gli importi TRA, se sono annullati
--   Luigi Cipolla - 19/11/2010 [LC#5]
--     Rimosso filtro comunicati annullati
--   Luigi Cipolla - 15/12/2010 [LC#6]
--     Aggiunta colonna COD_CATEGORIA_PRODOTTO
--   Luigi Cipolla - 16/12/2010 [LC#7]
--     Revisione completa della query, finalizzata al miglioramento dei tempi di risposta.
--     Il cardine della modifica e' la sostituzione delle tabella pivot CD_comunicato con la tabella
--     cd_ordine (nella tipologia di estrazione 'EP') e con la tabella cd_importi_fatturazione (in
--     tutti gli altri tipi di estrazione).
--   Luigi Cipolla - 18/10/2011 [LC#7]
--     Aggiunta la parametrizzazione della CATEGORIA_PRODOTTO.
-----------------------------------------------------------------------------------------------------
  PA_CD_MEZZO.fu_mezzo                                       COD_MEZZO
 ,PA_CD_MEZZO.fu_gest_comm                                   COD_GC
 ,PA_CD_MEZZO.fu_sottosistema                                COD_SOTTOSISTEMA
 ,PA_FATT.id_piano                                           COD_PIANO
 ,PA_FATT.id_ver_piano                                       VERSIONE_PIANO
 ,PA_FATT.COD_PRG_ORDINE                                     PRG_ORDINE
 ,PA_FATT.ID_IMPORTI_FATTURAZIONE
 ,PA_FATT.TIPO_CONTRATTO                                     COD_TIPO_CONTRATTO
 ,decode(nvl(PA_FATT.PERC_SCONTO_SOST_AGE,0), 0, 'N', 'S')  IND_SSDA
 ,PA_FATT.PERC_SCONTO_SOST_AGE                               PERC_SSDA
 ,PA_FATT.ID_COND_PAGAMENTO                                  COD_CONDIZIONE_PAGAMENTO
 ,PIA.id_cliente                                             COD_CLI_COMM
 ,PA_FATT.TIPO_COMMITTENTE
 ,PA_FATT.ID_CLIENTE_COMMITTENTE                             COD_CLI_COMMITTENTE
 ,CLI_AMM.ID_CLIENTE_FRUITORE                                COD_CLI_AMM
 ,PIA.cod_area                                               COD_AREA
 ,PIA.cod_sede                                               COD_SEDE
 ,INTERM.ID_AGENZIA                                          COD_AGZ
 ,INTERM.ID_CENTRO_MEDIA                                     COD_CACQ
 ,PIA.ID_RESPONSABILE_CONTATTO                               COD_VEND_RESP_CONT
 ,INTERM.ID_VENDITORE_CLIENTE                                COD_VEND_CLI
 ,INTERM.DATA_DECORRENZA                                     DATA_DECORR_INTERM
 ,PA_FATT.PERC_VEND_CLI                                      PERC_DIR_VEND_CLI
 ,to_char(null)                                            COD_VEND_AGZ
 ,to_char(null)                                            COD_VEND_CACQ
 ,to_char(null)                                            COD_VEND_PROD
 ,to_number(null)                                          PERC_DIR_AGZ
 ,to_number(null)                                          PERC_DIR_CACQ
 ,to_number(null)                                          PERC_DIR_VEND_AGZ
 ,to_number(null)                                          PERC_DIR_VEND_CACQ
 ,to_number(null)                                          PERC_DIR_VEND_PROD
 ,PA_FATT.DESC_PRODOTTO                                      DES_PRODOTTO
 ,PIA.cod_testata_editoriale                                 COD_TESTATA_ED
 ,PA_FATT.DATA_INIZIO                                        DATA_INIZIO
 ,PA_FATT.DATA_FINE                                          DATA_FINE
 ,PIA.DATA_PRENOTAZIONE                                      DATA_PRIMA_PRENOTAZIONE
 ,PA_FATT.cod_sogg                                           COD_SOGG
 ,PA_FATT.descrizione                                        DES_SOGG
 ,case
    when FAT_ANNULLATO = 'S' then 'ANN'
                              else PA_FATT.stato_di_vendita
  end    AS                                                 STATO_VENDITA
 ,PA_FATT.STATO_FATTURAZIONE                                 STATO_CONTABILE
 ,PA_FATT.DATAMOD_FATTURAZIONE                               DATA_STATO_CONTABILE  --[LC#4]
 ,decode(PA_FATT.TIPO_COMMITTENTE,'CL','1','AZ','2','CM','3','AL','4') FLAG_INV_FATT
 ,PA_FATT.FLG_SOSPESO
 ,PA_FATT.DATA_FATTURAZIONE
 ,PA_FATT.DGC_TC_ID
 ,PA_FATT.IMP_LORDO                                          LORDO
 ,PA_FATT.IMP_NETTO                                          NETTO
 ,PA_FATT.SC_TECNICI                                         SC_TECNICI
 ,PA_FATT.IMP_SC_COMM                                        SC_COMM
 ,'1'                                                        COD_TIPO_PRODUZ
 ,'S'                                                        UNI_MIS
 ,COEFF.durata                                               FORMATO_DURATA
 ,decode( CIRC.flg_arena, 'N', 'SALA', 'S', 'ARENA')        TIPO_SALA
 ,FAT_ANNULLATO
 ,PIA.COD_CATEGORIA_PRODOTTO --[LC#6]
from
  cd_circuito CIRC,
  cd_fruitori_di_piano CLI_AMM,
  cd_raggruppamento_intermediari INTERM,
  cd_prodotto_vendita PR_VEN,
  cd_coeff_cinema COEFF,
  cd_formato_acquistabile FORMATO,
  cd_pianificazione PIA,
   -- PA_FATT : prodotti rilevanti per la fatturazione, nel periodo richiesto, compresi annullati, con le informazioni amministrative
   -- [LC#7] inizio
  (select
     I_F.DATA_INIZIO
    ,I_F.DATA_FINE
    ,null                        IMP_LORDO
    ,null                        SC_TECNICI
    ,null                        IMP_SC_COMM
    ,I_F.IMP_NETTO
    ,I_F.ID_ORDINE
    ,I_F.ID_IMPORTI_FATTURAZIONE
    ,I_F.DATA_FATTURAZIONE
    ,I_F.STATO_FATTURAZIONE
    ,I_F.DATAMOD_FATTURAZIONE
    ,I_F.FLG_SOSPESO
    ,I_F.DESC_PRODOTTO
    ,I_F.PERC_SCONTO_SOST_AGE
    ,I_F.PERC_VEND_CLI
    ,I_F.FAT_ANNULLATO
    ,I_F.id_soggetto_di_piano
    ,I_F.id_importi_prodotto
    ,I_F.id_piano
    ,I_F.id_ver_piano
    ,I_F.COD_PRG_ORDINE
    ,I_F.ID_CLIENTE_COMMITTENTE
    ,I_F.TIPO_COMMITTENTE
    ,I_F.ID_COND_PAGAMENTO
    ,SO_PI.cod_sogg
    ,SO_PI.descrizione
    ,IMP.id_prodotto_acquistato
    ,IMP.TIPO_CONTRATTO
    ,IMP.DGC_TC_ID
    ,PA.DGC
    ,PA.stato_di_vendita
    ,PA.id_formato
    ,PA.id_prodotto_vendita
    ,PA.id_raggruppamento
    ,PA.id_fruitori_di_piano
    ,PA.flg_annullato
    ,PA.flg_sospeso  flg_sospeso_piano  -- sospensione di piano
   from
     cd_prodotto_acquistato PA,
     cd_importi_prodotto IMP,
     cd_soggetto_di_piano SO_PI,
     -- I_F: importi di fatturazione
     (select
        IMP_FATT.DATA_INIZIO        DATA_INIZIO
       ,IMP_FATT.DATA_FINE          DATA_FINE
       ,IMP_FATT.IMPORTO_NETTO      IMP_NETTO
       ,IMP_FATT.ID_ORDINE
       ,IMP_FATT.ID_IMPORTI_FATTURAZIONE
       ,IMP_FATT.DATA_FATTURAZIONE
       ,IMP_FATT.STATO_FATTURAZIONE
       ,IMP_FATT.DATAMOD_FATTURAZIONE
       ,IMP_FATT.FLG_SOSPESO
       ,IMP_FATT.DESC_PRODOTTO
       ,IMP_FATT.PERC_SCONTO_SOST_AGE
       ,IMP_FATT.PERC_VEND_CLI
       ,IMP_FATT.FLG_ANNULLATO AS FAT_ANNULLATO
       ,IMP_FATT.id_soggetto_di_piano
       ,IMP_FATT.id_importi_prodotto
       ,ORD.id_piano
       ,ORD.id_ver_piano
       ,ORD.COD_PRG_ORDINE
       ,ORD.ID_CLIENTE_COMMITTENTE
       ,ORD.TIPO_COMMITTENTE
       ,ORD.ID_COND_PAGAMENTO
      from
        cd_ordine ORD,
        cd_importi_fatturazione IMP_FATT
      where PA_CD_FATTURAZIONE.FU_TIPO_ESTRAZIONE!='EP'
          and    (PA_CD_FATTURAZIONE.FU_DATA_INIZIO is null
                  or
                  PA_CD_FATTURAZIONE.FU_DATA_INIZIO is not null
                  and IMP_FATT.DATA_INIZIO >= PA_CD_FATTURAZIONE.FU_DATA_INIZIO)
             and (PA_CD_FATTURAZIONE.FU_DATA_FINE is null
                  or
                  PA_CD_FATTURAZIONE.FU_DATA_FINE is not null
                  and IMP_FATT.DATA_FINE <= PA_CD_FATTURAZIONE.FU_DATA_FINE)
        and ORD.ID_ORDINE = IMP_FATT.ID_ORDINE
      union
      select
        IMP_FATT.DATA_INIZIO        DATA_INIZIO
       ,IMP_FATT.DATA_FINE          DATA_FINE
       ,IMP_FATT.IMPORTO_NETTO      IMP_NETTO
       ,IMP_FATT.ID_ORDINE
       ,IMP_FATT.ID_IMPORTI_FATTURAZIONE
       ,IMP_FATT.DATA_FATTURAZIONE
       ,IMP_FATT.STATO_FATTURAZIONE
       ,IMP_FATT.DATAMOD_FATTURAZIONE
       ,IMP_FATT.FLG_SOSPESO
       ,IMP_FATT.DESC_PRODOTTO
       ,IMP_FATT.PERC_SCONTO_SOST_AGE
       ,IMP_FATT.PERC_VEND_CLI
       ,IMP_FATT.FLG_ANNULLATO AS FAT_ANNULLATO
       ,IMP_FATT.id_soggetto_di_piano
       ,IMP_FATT.id_importi_prodotto
       ,ORD.id_piano
       ,ORD.id_ver_piano
       ,ORD.COD_PRG_ORDINE
       ,ORD.ID_CLIENTE_COMMITTENTE
       ,ORD.TIPO_COMMITTENTE
       ,ORD.ID_COND_PAGAMENTO
      from
        cd_importi_fatturazione IMP_FATT,
        cd_ordine ORD
      where PA_CD_FATTURAZIONE.FU_TIPO_ESTRAZIONE='EP'
        and ORD.id_piano = PA_CD_FATTURAZIONE.FU_ID_PIANO
        and ORD.id_ver_piano = PA_CD_FATTURAZIONE.FU_ID_VER_PIANO
        and ORD.COD_PRG_ORDINE = PA_CD_FATTURAZIONE.FU_COD_PRG_ORDINE
        and IMP_FATT.ID_ORDINE = ORD.ID_ORDINE
       ) I_F
   where SO_PI.id_soggetto_di_piano = I_F.id_soggetto_di_piano
     and IMP.id_importi_prodotto = I_F.id_importi_prodotto
     and PA.id_prodotto_acquistato = IMP.id_prodotto_acquistato
     -- esclude le righe DAT con netto 0 (tutto Direzionale o tutto Commerciale)
     and (    ( I_F.STATO_FATTURAZIONE = 'DAT' and IMP.IMP_NETTO>0 )
           or ( I_F.STATO_FATTURAZIONE != 'DAT'))
     and I_F.DATA_INIZIO <= nvl(PA_CD_FATTURAZIONE.FU_DATA_FINE, I_F.DATA_INIZIO)   --[LC#4]
  ) PA_FATT
   -- [LC#7] fine
where PIA.id_piano = PA_FATT.id_piano
  and PIA.id_ver_piano = PA_FATT.id_ver_piano
  and nvl(PA_CD_FATTURAZIONE.FU_CATEGORIA_PRODOTTO, PIA.COD_CATEGORIA_PRODOTTO) = PIA.COD_CATEGORIA_PRODOTTO --[LC#7]
  and ( PIA.COD_CATEGORIA_PRODOTTO='TAB'
         or
        PIA.COD_CATEGORIA_PRODOTTO='ISP' and
        PA_FATT.DATA_INIZIO >=TO_DATE('01102011','DDMMYYYY')
       )
  and FORMATO.id_formato = PA_FATT.id_formato
  and COEFF.id_coeff(+) = FORMATO.id_coeff
  and PR_VEN.id_prodotto_vendita = PA_FATT.id_prodotto_vendita
  and INTERM.id_raggruppamento = PA_FATT.id_raggruppamento
  and CLI_AMM.ID_FRUITORI_DI_PIANO(+) = PA_FATT.ID_FRUITORI_DI_PIANO
  and CIRC.id_circuito = PR_VEN.id_circuito
  and ( (PA_CD_FATTURAZIONE.FU_TIPO_ESTRAZIONE='EP'
          and (PA_FATT.STATO_FATTURAZIONE in ('DAR', 'DAT')
          or (PA_FATT.STATO_FATTURAZIONE = 'TRA' and PA_FATT.FAT_ANNULLATO = 'S'))
          and PA_FATT.id_piano = PA_CD_FATTURAZIONE.FU_ID_PIANO
          and PA_FATT.id_ver_piano = PA_CD_FATTURAZIONE.FU_ID_VER_PIANO
          and PA_FATT.COD_PRG_ORDINE = PA_CD_FATTURAZIONE.FU_COD_PRG_ORDINE)
         OR
         (PA_CD_FATTURAZIONE.FU_TIPO_ESTRAZIONE='ED'
          and (PA_FATT.STATO_FATTURAZIONE in ('DAR', 'DAT')
          or (PA_FATT.STATO_FATTURAZIONE = 'TRA' and PA_FATT.FAT_ANNULLATO = 'S')))
         OR
         (PA_CD_FATTURAZIONE.FU_TIPO_ESTRAZIONE='CO'
          and PA_FATT.stato_di_vendita = 'PRE')
         OR
         (PA_CD_FATTURAZIONE.FU_TIPO_ESTRAZIONE='RG'
          and PA_FATT.STATO_FATTURAZIONE in ('DAR', 'TRA')
          and PA_FATT.DATAMOD_FATTURAZIONE >= PA_CD_FATTURAZIONE.FU_DATA_STATO_CONT_INIZIO
          and PA_FATT.flg_annullato='N'
          and PA_FATT.flg_sospeso_piano='N' ) -- sospensione di piano
      )
/



