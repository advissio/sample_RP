CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_BASE_SITUAZIONE_VENDUTO
(DATA_TRASM, DATA_INIZIO_PERIODO, DATA_FINE_PERIODO, ID_PIANO, ID_VER_PIANO, 
 ID_PRODOTTO_ACQUISTATO, COD_SOGG, DES_SOGG, COD_CATEGORIA_PRODOTTO, STATO_DI_VENDITA, 
 NUM_SALE_GIORNO, NUM_GIORNI_TOTALE, TIPO_CONTRATTO, IMP_LORDO, IMP_SANATORIA, 
 IMP_RECUPERO, IMP_NETTO, IMP_SC_COMM, ID_CLIENTE_COMM, CLIENTE_COMM, 
 COD_AREA, AREA, COD_SEDE, GRUPPO, ID_CIRCUITO, 
 CIRCUITO, ID_TIPO_BREAK, DESC_TIPO_BREAK, ID_MOD_VENDITA, DESC_MOD_VENDITA, 
 DURATA, FLG_ARENA, FLG_ABBINATO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_BASE_SITUAZIONE_VENDUTO
--
-- DESCRIZIONE:
--   Estrae il venduto, secondo la visibilita' dell'utente di sessione, rispondente ai parametri impostati
--   mediante le procedure PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI e PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI.
--
-- REALIZZATORE: Luigi Cipolla - 18/02/2010
--
-- MODIFICHE:
--   Luigi Cipolla, 24/02/2010
--     Inserimento colonne DATA_INIZIO_PERIODO e DATA_FINE_PERIODO
--   Simone Bottani, 05/05/2010
--     Aggiunto filtro su tipo contratto
--   Michele Borgogno, 20/05/2010
--     Aggiunti outer join su cd_tipo_break e su cd_coeff_cinema
--     Aggiunta la condizione is null su PV.id_tipo_break
--   Michele Borgogno, 23/05/2010
--     Aggiunto filtro categoria prodotto.
--   Michele Borgogno, 31/05/2010
--     Aggiunto filtri flg_arena e flg_abbinato.
--   Mauro Viel, 31/08/2010
--     Aggiunto id_piano id_ver piano fra i valori restituiti dalla vista
--   Mauro Viel, 16/09/2010
--     Eliminate le colonne num_sale e posizione_di_rigore
--   Mauro Viel, 11/01/2011 
--     Inserite le colonne : spot.num_giorni_totale e  spot.num_sale_giorno.
--   Mauro Viel, 11/11/2011 
--     Modificato la modalita' di filtro flg_arena.
-----------------------------------------------------------------------------------------------------
   SPOT.DATA_EROGAZIONE_PREV   data_trasm
  ,SPOT.DATA_INIZIO_PERIODO
  ,SPOT.DATA_FINE_PERIODO
  ,SPOT.ID_PIANO
  ,SPOT.ID_VER_PIANO
  ,SPOT.ID_PRODOTTO_ACQUISTATO
  ,SPOT.COD_SOGG
  ,SPOT.DESCRIZIONE            des_sogg
  ,PIA.COD_CATEGORIA_PRODOTTO
  ,SPOT.STATO_DI_VENDITA
  ,SPOT.NUM_SALE_GIORNO
  ,SPOT.NUM_GIORNI_TOTALE
  ,SPOT.TIPO_CONTRATTO
  ,SPOT.IMP_LORDO
  ,SPOT.IMP_SANATORIA
  ,SPOT.IMP_RECUPERO
  ,SPOT.IMP_NETTO
  ,SPOT.IMP_SC_COMM
  ,PIA.ID_CLIENTE              ID_CLIENTE_COMM
  ,CC.RAG_SOC_COGN             cliente_comm
  ,AR.COD_AREA
  ,AR.DESCRIZ area
  ,SE.COD_SEDE
  ,SE.DES_SEDE gruppo
  ,CIR.id_circuito
  ,CIR.nome_circuito           circuito
  ,TB.id_tipo_break
  ,TB.desc_tipo_break
  ,MV.id_mod_vendita
  ,MV.desc_mod_vendita
  ,DUR.durata
  ,CIR.flg_arena
  ,PV.flg_abbinato
from
  cd_coeff_cinema DUR,
  cd_formato_acquistabile FO,
  cd_modalita_vendita MV,
  cd_tipo_break TB,
  cd_circuito CIR,
  cd_prodotto_vendita PV,
  sedi SE,
  aree AR,
  vi_cd_clicomm CC,
  VI_CD_AREE_SEDI_COMPET ARSE,
  cd_pianificazione PIA,
  vi_cd_base_supporto_vendite SPOT
where SPOT.ID_PIANO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_GET_ID_PIANO, SPOT.ID_PIANO)
  and SPOT.ID_VER_PIANO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_GET_ID_VER_PIANO, SPOT.ID_VER_PIANO)
  and SPOT.STATO_DI_VENDITA = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_STATO_VEND, SPOT.STATO_DI_VENDITA)
  and SPOT.TIPO_CONTRATTO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_TIPO_CONTRATTO, SPOT.TIPO_CONTRATTO)
  and PIA.ID_PIANO = SPOT.ID_PIANO
  and PIA.ID_VER_PIANO = SPOT.ID_VER_PIANO
  and PIA.ID_CLIENTE = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_CLI_COMM, PIA.ID_CLIENTE)
  and PIA.COD_CATEGORIA_PRODOTTO = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_CATEGORIA_PUBB, PIA.COD_CATEGORIA_PRODOTTO)
  and PIA.COD_AREA = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_AREA, PIA.COD_AREA)
  and PIA.COD_SEDE = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_SEDE, PIA.COD_SEDE)
  and ARSE.COD_AREA = PIA.COD_AREA
  and ARSE.COD_SEDE =PIA.COD_SEDE
  and decode( FU_UTENTE_PRODUTTORE , 'S' , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
  and CC.ID_CLIENTE = PIA.ID_CLIENTE
  and AR.COD_AREA = PIA.COD_AREA
  and SE.COD_SEDE = PIA.COD_SEDE
  and PV.id_prodotto_vendita = SPOT.id_prodotto_vendita
  and PV.id_circuito = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_CIRCUITO, PV.id_circuito)
  and CIR.id_circuito = PV.id_circuito
  and CIR.flg_arena = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_FLG_ARENA, CIR.flg_arena)
  and ( PV.id_tipo_break is null or PV.id_tipo_break = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_TIPO_BREAK, PV.id_tipo_break))
  and PV.flg_abbinato = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_FLG_ABBINATO, PV.flg_abbinato)
  and TB.id_tipo_break (+)= PV.id_tipo_break
  and PV.id_mod_vendita = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_MOD_VENDITA, PV.id_mod_vendita)
  and MV.id_mod_vendita = PV.id_mod_vendita
  and FO.id_formato = SPOT.id_formato
  and DUR.id_coeff (+)= FO.id_coeff
/



