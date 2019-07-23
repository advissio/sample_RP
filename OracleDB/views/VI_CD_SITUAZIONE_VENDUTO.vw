CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SITUAZIONE_VENDUTO
(ID_PIANO, ID_VER_PIANO, COD_SOGG, DES_SOGG, TIPO_CONTRATTO, 
 IMP_LORDO, IMP_SANATORIA, IMP_RECUPERO, IMP_NETTO, IMP_SC_COMM, 
 ID_CLIENTE_COMM, CLIENTE_COMM, COD_AREA, AREA, COD_SEDE, 
 GRUPPO, ID_CIRCUITO, CIRCUITO, ID_TIPO_BREAK, DESC_TIPO_BREAK, 
 ID_MOD_VENDITA, DESC_MOD_VENDITA, COD_CATEGORIA_PRODOTTO, FLG_ARENA, FLG_ABBINATO)
AS 
select
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_SITUAZIONE_VENDUTO
--
-- DESCRIZIONE:
--   Estrae il venduto, secondo la visibilita' dell'utente di sessione, rispondente ai parametri impostati
--   mediante le procedure PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI e PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI.
--
-- REALIZZATORE: Daniela Spezia, Altran 24/02/2010
--
-- MODIFICHE:
--   Mauro Viel, 31/08/2010 
--  Aggiunto id_piano id_ver piano fra i valori restituiti dalla vista
-----------------------------------------------------------------------------------------------------
  ID_PIANO,
  ID_VER_PIANO,
  cod_sogg,
  DES_SOGG,
  TIPO_CONTRATTO,
  sum(IMP_LORDO) as IMP_LORDO,
  sum(IMP_SANATORIA) as IMP_SANATORIA,
  sum(IMP_RECUPERO) as IMP_RECUPERO,
  sum(IMP_NETTO) as IMP_NETTO,
  sum(IMP_SC_COMM) as IMP_SC_COMM,
  ID_CLIENTE_COMM,
  CLIENTE_COMM,
  COD_AREA,
  AREA,
  COD_SEDE,
  GRUPPO,
  id_circuito,
  CIRCUITO,
  id_tipo_break,
  DESC_TIPO_BREAK,
  id_mod_vendita,
  DESC_MOD_VENDITA,
  COD_CATEGORIA_PRODOTTO,
  FLG_ARENA,
  FLG_ABBINATO
from VI_CD_BASE_SITUAZIONE_VENDUTO
group by
  COD_AREA,
  AREA,
  COD_SEDE,
  GRUPPO,
  id_cliente_comm,
  cliente_comm,
  cod_sogg,
  des_sogg,
  TIPO_CONTRATTO,
  id_circuito,
  circuito,
  id_tipo_break,
  DESC_TIPO_BREAK,
  id_mod_vendita,
  DESC_MOD_VENDITA,
  COD_CATEGORIA_PRODOTTO,
  FLG_ARENA,
  FLG_ABBINATO,
  ID_PIANO,
  ID_VER_PIANO
/



