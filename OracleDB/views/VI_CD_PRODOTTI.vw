CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_PRODOTTI
(ID_PRODOTTO_ACQUISTATO, DATA_INIZIO_PERIODO, DATA_FINE_PERIODO, CIRCUITO, BREAK, 
 MODALITA_VENDITA, CATEGORIA_PROD, DURATA_MEDIA, GIORNI_MEDI, NUM_SALE_MEDIO, 
 TIPO_CONTRATTO, LORDO, SANATORIA, RECUPERO, NETTO, 
 IMP_SC_COMM, FLG_ARENA, FLG_ABBINATO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_PRODOTTI
--
-- DESCRIZIONE:
--  Estrae i prodotti vendibili e venduti , secondo la visibilita' dell'utente di sessione, rispondente ai parametri impostati
--   mediante le procedure PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI e PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI.
--
-- REALIZZATORE: Mauro Viel - 24/02/2011
--
-- MODIFICHE:      
nvl(venduto.id_prodotto_acquistato,vendibili.id_prodotto_acquistato) as id_prodotto_acquistato,
nvl(venduto.DATA_INIZIO_PERIODO,vendibili.DATA_INIZIO_PERIODO) as DATA_INIZIO_PERIODO,
nvl(venduto.DATA_FINE_PERIODO,vendibili.DATA_FINE_PERIODO) as DATA_FINE_PERIODO,
nvl(venduto.CIRCUITO,vendibili.CIRCUITO) as CIRCUITO,
nvl(venduto.BREAK,vendibili.BREAK) as BREAK,
nvl(venduto.MODALITA_VENDITA,vendibili.MODALITA_VENDITA) as MODALITA_VENDITA,
nvl(venduto.CATEGORIA_PROD,vendibili.CATEGORIA_PROD) as CATEGORIA_PROD,
nvl(venduto.DURATA_MEDIA,vendibili.DURATA_MEDIA) as DURATA_MEDIA,
nvl(venduto.GIORNI_MEDI,vendibili.GIORNI_MEDI) as  GIORNI_MEDI,
nvl(venduto.NUM_SALE_MEDIO,vendibili.NUM_SALE_MEDIO) as NUM_SALE_MEDI,
nvl(venduto.TIPO_CONTRATTO,vendibili.TIPO_CONTRATTO) as TIPO_CONTRATTO, 
nvl(venduto.LORDO,vendibili.LORDO) as LORDO,
nvl(venduto.SANATORIA,vendibili.SANATORIA) as SANATORIA, 
nvl(venduto.RECUPERO,vendibili.RECUPERO) as RECUPERO,
nvl(venduto.NETTO,vendibili.NETTO) as NETTO,
nvl(venduto.IMP_SC_COMM,vendibili.IMP_SC_COMM) as IMP_SC_COMM ,
nvl(venduto.FLG_ARENA,vendibili.FLG_ARENA) as FLG_ARENA,
nvl(venduto.FLG_ABBINATO,vendibili.FLG_ABBINATO) as FLG_ABBINATO
from VI_CD_PRODOTTI_VENDIBILI vendibili , VI_CD_BASE_SIT_VEND_PRODOTTO venduto 
where vendibili.id_prodotto_acquistato   =  venduto.id_prodotto_acquistato (+)
and   vendibili.circuito  =  venduto.circuito (+)
and   vendibili.break  =  venduto.break  (+)
and   vendibili.modalita_vendita   = venduto.modalita_vendita (+)
and   vendibili.categoria_prod  = venduto.categoria_prod  (+) 
and   vendibili.TIPO_CONTRATTO    =  venduto.TIPO_CONTRATTO (+)
and   vendibili.DATA_INIZIO_PERIODO = venduto.DATA_INIZIO_PERIODO (+)
and   vendibili.DATA_FINE_PERIODO = venduto.DATA_FINE_PERIODO (+)
/



