CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SITUAZIONE_VENDUTO IS
/* -----------------------------------------------------------------------------------------------------------

   Descrizione: Package di  parametrizzazione delle estrazioni di venduto

----------------------------------------------------------------------------------------------------------- */
--
--
-- Variabili di package
P_categoria_pubb varchar2(20) := null;
P_stato_vend varchar2(3) := null;
P_cli_comm varchar2(8) := null;
P_area varchar2(2) := null;
P_sede varchar2(8) := null;
P_circuito number(4):= null;
P_tipo_break number(2):= null;
P_mod_vendita number(2):= null;
P_tipo_contratto varchar2(1):= null;
P_flg_arena varchar2(1):= null;
P_flg_abbinato varchar2(1):= null;
p_id_piano number:= null;
p_id_ver_piano number:=null;
p_no_div_tipo_contratto varchar2(1):= null;
--
--
-----------------------------------------------------------------------------------------------------------
-- Procedura: IMPOSTA_PARAMETRI
--
-- Input: valori da assegnare alle variabili di package.
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-- Michele Borgogno, 23/05/2010
--      Aggiunto filtro COD_CATEGORIA_PRODOTTO
-- Michele Borgogno, 31/05/2010
--      Aggionti filtri fl_arena, flg_abbinato
--Mauro Viel Altran Italia Aggiunto il filtro NO_DIV_TIPO_CONTRATTO per consentire oppure no la rotura per tipo_contratto (Commerciale/Direzionele)
-----------------------------------------------------------------------------------------------------------
procedure IMPOSTA_PARAMETRI(
  CATEGORIA_PUBB VARCHAR2,
  STATO_VEND VARCHAR2,
  CLI_COMM VARCHAR2,
  AREA VARCHAR2,
  SEDE VARCHAR2,
  CIRCUITO NUMBER,
  TIPO_BREAK NUMBER,
  MOD_VENDITA NUMBER,
  TIPO_CONTRATTO VARCHAR2,
  FLG_ARENA VARCHAR2,
  FLG_ABBINATO VARCHAR2,
  NO_DIV_TIPO_CONTRATTO VARCHAR2 DEFAULT 'N'
)
is
begin
  P_categoria_pubb := categoria_pubb;
  P_stato_vend := stato_vend;
  P_cli_comm   := cli_comm;
  P_area       := area;
  P_sede       := sede;
  P_circuito   := circuito;
  P_tipo_break := tipo_break;
  P_mod_vendita:= mod_vendita;
  P_tipo_contratto:= tipo_contratto;
  P_flg_arena := flg_arena;
  P_flg_abbinato := flg_abbinato;
  p_no_div_tipo_contratto := no_div_tipo_contratto;
end IMPOSTA_PARAMETRI;


--Mauro Viel Altran Italia Aggiunto il filtro NO_DIV_TIPO_CONTRATTO per consentire oppure no la rotura per tipo_contratto (Commerciale/Direzionele)
procedure IMPOSTA_PARAMETRI(
  CATEGORIA_PUBB VARCHAR2,
  STATO_VEND VARCHAR2,
  CLI_COMM VARCHAR2,
  AREA VARCHAR2,
  SEDE VARCHAR2,
  CIRCUITO NUMBER,
  TIPO_BREAK NUMBER,
  MOD_VENDITA NUMBER,
  TIPO_CONTRATTO VARCHAR2,
  FLG_ARENA VARCHAR2,
  FLG_ABBINATO VARCHAR2,
  ID_PIANO NUMBER,
  ID_VER_PIANO NUMBER,
  NO_DIV_TIPO_CONTRATTO VARCHAR2 DEFAULT 'N'
  )
  is
  begin
  IMPOSTA_PARAMETRI(CATEGORIA_PUBB, STATO_VEND, CLI_COMM, AREA, SEDE, CIRCUITO, TIPO_BREAK, MOD_VENDITA, TIPO_CONTRATTO, FLG_ARENA, FLG_ABBINATO,NO_DIV_TIPO_CONTRATTO);
  p_id_piano := id_piano;
  p_id_ver_piano := id_ver_piano;
  end;


-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_CATEGORIA_PUBB
--
-- Output: variabile di package P_CATEGORIA_PUBB
--
-- Realizzatore:
--	 Michele Borgogno, 23/05/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_CATEGORIA_PUBB RETURN varchar2
is
begin
  return P_CATEGORIA_PUBB;
end;
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_STATO_VEND
--
-- Output: variabile di package P_STATO_VEND
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_STATO_VEND RETURN varchar2
is
begin
  return P_STATO_VEND;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_CLI_COMM
--
-- Output: variabile di package P_CLI_COMM
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_CLI_COMM RETURN varchar2
is
begin
  return P_CLI_COMM;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_AREA
--
-- Output: variabile di package P_AREA
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_AREA RETURN varchar2
is
begin
  return P_AREA;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_SEDE
--
-- Output: variabile di package P_SEDE
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_SEDE RETURN varchar2
is
begin
  return P_SEDE;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_CIRCUITO
--
-- Output: variabile di package P_CIRCUITO
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_CIRCUITO RETURN number
is
begin
  return P_CIRCUITO;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_TIPO_BREAK
--
-- Output: variabile di package P_TIPO_BREAK
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_TIPO_BREAK RETURN number
is
begin
  return P_TIPO_BREAK;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_MOD_VENDITA
--
-- Output: variabile di package P_MOD_VENDITA
--
-- Realizzatore:
--	 luigi cipolla, 19/02/2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_MOD_VENDITA RETURN number
is
begin
  return P_MOD_VENDITA;
end;


-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, marzo 2010
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_situaz_venduto_prodotto   Estrae i dati relativi alla situazione del venduto del cliente/prodotto
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- Michele Borgogno, 23/05/2010
--      Aggiunto filtro cod categoria prodotto
--      31/05/2010 Aggiunti flg_arena, flg_abbinato
--Mauro Viel, 12/01/2010 insetiti i campi : giorni_medi, num_sale_medio. 
--                                          Trasformata la durata in durata_media.

FUNCTION fu_situaz_venduto_prodotto RETURN C_SITUAZ_VENDUTO_PRODOTTO IS
C_SIT_VENDUTO_PROD C_SITUAZ_VENDUTO_PRODOTTO;
BEGIN
OPEN C_SIT_VENDUTO_PROD FOR
    select
    sit.ID_PRODOTTO_ACQUISTATO,
    sit.CIRCUITO as circuito,
    decode(sit.BREAK, null,pp.DESC_PRODOTTO,sit.BREAK) as descTipoBreak,
    sit.MODALITA_VENDITA as descModVendita,
    sit.COD_CATEGORIA_PRODOTTO as codCategoriaProd,
    sit.DURATA_MEDIA as durata,
    sit.GIORNI_MEDI as giorniMedi,
    sit.NUM_SALE_MEDIO as numSaleMedio,
    --decode(sit.TIPO_CONTRATTO,'C','Comm.','Dir.') as TIPOCONTRATTO,
    decode(p_no_div_tipo_contratto,'S','-',decode(sit.TIPO_CONTRATTO,'C','Comm.','Dir.')) as TIPOCONTRATTO,
    sit.LORDO as impLordo,
    sit.SANATORIA as impSanatoria,
    sit.RECUPERO as impRecupero,
    sit.NETTO as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(netto, IMP_SC_COMM) as percScComm,
    sit.FLG_ARENA as flgArena,
    sit.FLG_ABBINATO as flgAbbinato
    from VI_CD_SIT_VENDUTO_PRODOTTO sit,
    cd_prodotto_acquistato pa,
      cd_prodotto_vendita pv,
      cd_prodotto_pubb pp
where pa.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA (+)
and   pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB (+)
and   sit.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO (+);
return  C_SIT_VENDUTO_PROD;

-----------------------------
END fu_situaz_venduto_prodotto;





-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, maggio 2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_sit_vend_prod_no_tipo_contr   Estrae i dati relativi alla situazione 
--                                               del venduto del prodotto senza rottura per tipo contratto
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:

FUNCTION fu_sit_vend_prod_no_tipo_contr RETURN C_SITUAZ_VENDUTO_PRODOTTO IS
C_SIT_VENDUTO_PROD C_SITUAZ_VENDUTO_PRODOTTO;
BEGIN
OPEN C_SIT_VENDUTO_PROD FOR
select ID_PRODOTTO_ACQUISTATO, 
       CIRCUITO as circuito, 
       BREAK as descTipoBreak, 
       MODALITA_VENDITA as descModVendita, 
       COD_CATEGORIA_PRODOTTO as codCategoriaProd, 
       DURATA_MEDIA as durata, 
       GIORNI_MEDI as giorniMedi, 
       NUM_SALE_MEDIO as numSaleMedio,
       '-'  as TIPOCONTRATTO,
       sum(LORDO) as impLordo, 
       sum(SANATORIA) as impSanatoria, 
       sum(RECUPERO)  as impRecupero, 
       sum(NETTO) as impNetto, 
       sum(IMP_SC_COMM) as percScComm, 
       FLG_ARENA as flgArena,
       FLG_ABBINATO as flgAbbinato       
from vi_cd_sit_venduto_prodotto
group by 
ID_PRODOTTO_ACQUISTATO, CIRCUITO, BREAK, MODALITA_VENDITA, COD_CATEGORIA_PRODOTTO, 
 DURATA_MEDIA, GIORNI_MEDI, NUM_SALE_MEDIO,  FLG_ARENA, 
 FLG_ABBINATO ,decode(tipo_contratto,'C','C','C');
return C_SIT_VENDUTO_PROD;
END;


-----------------------------------------------------------------------------------------------------------
--
--  Daniela Spezia, altran, febbraio 2010
--  Modifiche 
--  Simone Bottani, Altran, Settembre 2010
--  Eliminati campi non necessari
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_situaz_venduto   Estrae i dati relativi alla situazione del venduto
-- --------------------------------------------------------------------------------------------
FUNCTION fu_situaz_venduto RETURN C_SITUAZ_VENDUTO IS
   c_dati C_SITUAZ_VENDUTO;
   BEGIN
   OPEN c_dati FOR
         select
    base.id_piano, base.id_ver_piano,     
    base.clienteComm as clienteComm, 
    --base.desSogg as desSogg,
    --base.area as area, base.gruppo as gruppo, 
    base.tipoContratto as tipoContratto,
    base.impLordo as impLordo, base.impSanatoria as impSanatoria,
    base.impRecupero as impRecupero, base.impNetto as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(base.impNetto, base.impScComm) as percScComm--,
    --base.circuito as circuito, base.descTipoBreak as descTipoBreak,
    --base.descModVendita as descModVendita,
    --base.codCategoriaProd as codCategoriaProd,
    --base.flgArena as flgArena,
    --base.flgAbbinato as flgAbbinato
    from (select
                id_piano,id_ver_piano,
                id_cliente_comm, CLIENTE_COMM as clienteComm,
                --cod_sogg, DES_SOGG as desSogg, cod_area, AREA as area,
                cod_sede, GRUPPO as gruppo, decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as tipoContratto,
                sum(IMP_LORDO) as impLordo, sum(IMP_SANATORIA) as impSanatoria,
                sum(IMP_RECUPERO) as impRecupero, sum(IMP_NETTO) as impNetto,
                sum(IMP_SC_COMM) as impScComm
                --, id_circuito, CIRCUITO as circuito,
                --id_tipo_break, DESC_TIPO_BREAK as descTipoBreak,
                --id_mod_vendita, DESC_MOD_VENDITA as descModVendita,
                --COD_CATEGORIA_PRODOTTO as codCategoriaProd,
                --FLG_ARENA as flgArena,
                --FLG_ABBINATO as flgAbbinato
             from VI_CD_SITUAZIONE_VENDUTO
             group by --COD_AREA,AREA, COD_SEDE, GRUPPO, 
             id_cliente_comm, cliente_comm,
                --cod_sogg, des_sogg, 
                id_piano,id_ver_piano,
                TIPO_CONTRATTO
                --id_circuito, circuito,id_tipo_break, DESC_TIPO_BREAK,id_mod_vendita, DESC_MOD_VENDITA, COD_CATEGORIA_PRODOTTO, FLG_ARENA, FLG_ABBINATO,
             ) base
             ORDER BY CLIENTECOMM, ID_PIANO, TIPOCONTRATTO;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20035,
                                'Funzione fu_situaz_venduto in errore: '
                             || SQLERRM
                            );
   END fu_situaz_venduto;
   
   -----------------------------------------------------------------------------------------------------------
--
--  Simone Bottani, Altran, Settembre 2010
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_situaz_venduto_dettaglio   Estrae i dati relativi alla situazione del venduto per il dettaglio cliente
-- --------------------------------------------------------------------------------------------
FUNCTION fu_situaz_venduto_dettaglio RETURN C_SITUAZ_VENDUTO_DETTAGLIO IS
   c_dati C_SITUAZ_VENDUTO_DETTAGLIO;
   BEGIN
   OPEN c_dati FOR
         select
    base.id_piano, base.id_ver_piano,     
    base.clienteComm as clienteComm, 
    base.desSogg as desSogg,
    base.area as area, base.gruppo as gruppo, 
    base.tipoContratto as tipoContratto,
    base.impLordo as impLordo, base.impSanatoria as impSanatoria,
    base.impRecupero as impRecupero, base.impNetto as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(base.impNetto, base.impScComm) as percScComm,
    base.circuito as circuito, base.descTipoBreak as descTipoBreak,
    base.descModVendita as descModVendita,
    base.codCategoriaProd as codCategoriaProd,
    base.flgArena as flgArena,
    base.flgAbbinato as flgAbbinato
    from (select
                id_piano,id_ver_piano,
                id_cliente_comm, CLIENTE_COMM as clienteComm,
                cod_sogg, DES_SOGG as desSogg, cod_area, AREA as area,
                cod_sede, GRUPPO as gruppo, decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as tipoContratto,
                sum(IMP_LORDO) as impLordo, sum(IMP_SANATORIA) as impSanatoria,
                sum(IMP_RECUPERO) as impRecupero, sum(IMP_NETTO) as impNetto,
                sum(IMP_SC_COMM) as impScComm, id_circuito, CIRCUITO as circuito,
                id_tipo_break, DESC_TIPO_BREAK as descTipoBreak,
                id_mod_vendita, DESC_MOD_VENDITA as descModVendita,
                COD_CATEGORIA_PRODOTTO as codCategoriaProd,
                FLG_ARENA as flgArena,
                FLG_ABBINATO as flgAbbinato
             from VI_CD_SITUAZIONE_VENDUTO
             group by COD_AREA,AREA, COD_SEDE, GRUPPO, 
             id_cliente_comm, cliente_comm,
                cod_sogg, des_sogg, 
                id_piano,id_ver_piano,
                TIPO_CONTRATTO,
                id_circuito, circuito,id_tipo_break, DESC_TIPO_BREAK,id_mod_vendita, 
                DESC_MOD_VENDITA, COD_CATEGORIA_PRODOTTO, FLG_ARENA, FLG_ABBINATO
             ) base
             ORDER BY CLIENTECOMM, ID_PIANO, TIPOCONTRATTO;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20035,
                                'Funzione fu_situaz_venduto in errore: '
                             || SQLERRM
                            );
   END fu_situaz_venduto_dettaglio;   
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_TIPO_CONTRATTO
--
-- Output: variabile di package P_TIPO_CONTRATTO
--
-- Realizzatore:
--	 Simone Bottani, Altran, Maggio 2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_TIPO_CONTRATTO RETURN varchar2 is
begin
    return P_TIPO_CONTRATTO;
end FU_TIPO_CONTRATTO;
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_FLG_ARENA
--
-- Output: variabile di package P_FLG_ARENA
--
-- Realizzatore:
--	 Michele Borgongo, Altran, Maggio 2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_FLG_ARENA RETURN varchar2 is
begin
    return P_FLG_ARENA;
end FU_FLG_ARENA;
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_FLG_ABBINATO
--
-- Output: variabile di package P_FLG_ABBINATO
--
-- Realizzatore:
--	 Michele Borgongo, Altran, Maggio 2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_FLG_ABBINATO RETURN varchar2 is
begin
    return P_FLG_ABBINATO;
end FU_FLG_ABBINATO;

function FU_GET_ID_PIANO RETURN number is
begin
    return p_id_piano;
end FU_GET_ID_PIANO;
function FU_GET_ID_VER_PIANO RETURN number is
begin
    return p_id_ver_piano;
end  FU_GET_ID_VER_PIANO; 




function  fu_sit_vend_dettaglio_prodotto return C_SIT_VEND_DETT_PROD   is
c C_SIT_VEND_DETT_PROD;
begin
open c for
 select
    base.id_piano, 
    base.id_ver_piano,
    base.id_prodotto_acquistato,     
    base.clienteComm as clienteComm, 
    base.desSogg as desSogg,
    base.area as area, base.gruppo as gruppo, 
    base.tipoContratto as tipoContratto,
    base.impLordo as impLordo, 
    base.data_inizio_periodo ,
    base.data_fine_periodo,
    base.impNetto as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(base.impNetto, base.impScComm) as percScComm,
    durata,
    base.circuito as circuito, base.descTipoBreak as descTipoBreak,
    base.descModVendita as descModVendita,
    base.codCategoriaProd as codCategoriaProd,
    base.flgArena as flgArena,
    base.flgAbbinato as flgAbbinato
    from (select
                id_piano,id_ver_piano,
                id_prodotto_acquistato,
                data_inizio_periodo,
                data_fine_periodo,
                id_cliente_comm, CLIENTE_COMM as clienteComm,
                cod_sogg, DES_SOGG as desSogg, cod_area, AREA as area,
                cod_sede, GRUPPO as gruppo, decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as tipoContratto,
                sum(IMP_LORDO) as impLordo, 
                sum(IMP_NETTO) as impNetto,
                sum(IMP_SC_COMM) as impScComm, id_circuito, CIRCUITO as circuito,
                durata,
                id_tipo_break, DESC_TIPO_BREAK as descTipoBreak,
                id_mod_vendita, DESC_MOD_VENDITA as descModVendita,
                COD_CATEGORIA_PRODOTTO as codCategoriaProd,
                FLG_ARENA as flgArena,
                FLG_ABBINATO as flgAbbinato
             from 
             (
                    select
                      ID_PIANO,
                      ID_VER_PIANO,
                      id_prodotto_acquistato,
                      cod_sogg,
                      DES_SOGG,
                      TIPO_CONTRATTO,
                      data_inizio_periodo,
                      data_fine_periodo,
                      sum(IMP_LORDO) as IMP_LORDO,
                      sum(IMP_NETTO) as IMP_NETTO,
                      sum(IMP_SC_COMM) as IMP_SC_COMM,
                      durata,
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
                      durata,
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
                      ID_VER_PIANO,
                      id_prodotto_acquistato,
                      data_inizio_periodo,
                      data_fine_periodo
             )
             group by  durata, COD_AREA,AREA, COD_SEDE, GRUPPO, 
             id_cliente_comm, cliente_comm,
                cod_sogg, des_sogg, 
                id_piano,id_ver_piano,
                TIPO_CONTRATTO,
                id_circuito, circuito,id_tipo_break, DESC_TIPO_BREAK,id_mod_vendita, 
                DESC_MOD_VENDITA, COD_CATEGORIA_PRODOTTO, FLG_ARENA, FLG_ABBINATO,
                id_prodotto_acquistato,
                data_inizio_periodo,
                data_fine_periodo
             ) base
             ORDER BY CLIENTECOMM, ID_PIANO, TIPOCONTRATTO;
return c;
end fu_sit_vend_dettaglio_prodotto;




-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, gennaio 2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_situaz_venduto_prodotto_ps   Estrae i dati relativi alla situazione del venduto del cliente/prodotto per un periodo_speciale
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: --Mauro Viel Altran 23/11/2011 inserita la decode sul tipo_contratto  --#MV01
FUNCTION fu_situaz_venduto_prodotto_ps RETURN C_SITUAZ_VENDUTO_PRODOTTO IS
C_SIT_VENDUTO_PROD C_SITUAZ_VENDUTO_PRODOTTO;
BEGIN
OPEN C_SIT_VENDUTO_PROD FOR

    
    
    select 
    decode(codCategoriaProd,'ISP', ID_PRODOTTO_ACQUISTATO, 0) as ID_PRODOTTO_ACQUISTATO,
    circuito,
    descTipoBreak,
    descModVendita,
    codCategoriaProd,
    round(avg(DURATA)) as durata,
    round(avg(giorniMedi)) as giorniMedi,
    round(avg(numSaleMedio)) numSaleMedio,
    TIPOCONTRATTO,
    sum(impLordo) as impLordo,
    sum(impSanatoria) as impSanatoria,
    sum(impRecupero) as impRecupero,
    sum(impNetto) as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(sum(impNetto), sum(IMP_SC_COMM)) as percScComm,
    flgArena, 
    flgAbbinato
    from(
    select
    ID_PRODOTTO_ACQUISTATO,
    CIRCUITO as circuito,
    BREAK as descTipoBreak,
    MODALITA_VENDITA as descModVendita,
    COD_CATEGORIA_PRODOTTO as codCategoriaProd,
    DURATA_MEDIA as durata,
    GIORNI_MEDI as giorniMedi,
    NUM_SALE_MEDIO as numSaleMedio,
    --decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as TIPOCONTRATTO,
    decode(p_no_div_tipo_contratto,'S','-',decode(TIPO_CONTRATTO,'C','Comm.','Dir.')) as TIPOCONTRATTO,
    LORDO as impLordo,
    SANATORIA as impSanatoria,
    RECUPERO as impRecupero,
    NETTO as impNetto,
    --PA_PC_IMPORTI.FU_PERC_SC_COMM(netto, IMP_SC_COMM) as percScComm,
    IMP_SC_COMM,
    FLG_ARENA as flgArena,
    FLG_ABBINATO as flgAbbinato
    from 
    (
        SELECT
        ID_PRODOTTO_ACQUISTATO, 
        data_inizio_periodo,
        data_fine_periodo,      
        CIRCUITO,
        DESC_TIPO_BREAK AS BREAK,
        DESC_MOD_VENDITA AS MODALITA_VENDITA,
        COD_CATEGORIA_PRODOTTO,
        ROUND(SUM(DURATA)/AVG(NUM_GIORNI_TOTALE)) DURATA_MEDIA, 
        ROUND(AVG(NUM_GIORNI_TOTALE)) GIORNI_MEDI,
        ROUND(AVG(NUM_SALE_GIORNO))   NUM_SALE_MEDIO,
        decode(pa_cd_situazione_venduto.FU_NO_DIV_TIPO_CONTRATTO,'S','C',TIPO_CONTRATTO) AS TIPO_CONTRATTO, --TIPO_CONTRATTO, --#MV01,
        --tipo_contratto,
        sum (IMP_LORDO) AS LORDO,
        sum (IMP_SANATORIA) AS SANATORIA,
        sum(IMP_RECUPERO) AS RECUPERO,
        sum(IMP_NETTO) AS NETTO,
        sum(IMP_SC_COMM) AS IMP_SC_COMM,
        FLG_ARENA,
        FLG_ABBINATO
        from 
        (
               select
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
              --,SPOT.POSIZIONE_DI_RIGORE
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
              ,null as flg_arena --SA.flg_arena
              ,PV.flg_abbinato   
            from
              --cd_posizione_rigore POS,
              cd_coeff_cinema DUR,
              cd_formato_acquistabile FO,
              cd_modalita_vendita MV,
              cd_tipo_break TB,
              cd_circuito CIR,   
              --cd_circuito_schermo CIS,  
              --cd_schermo SCH,   
              cd_prodotto_vendita PV,
              sedi SE,
              aree AR,
              vi_cd_clicomm CC,
              VI_CD_AREE_SEDI_COMPET ARSE,
              cd_pianificazione PIA,
              ----------------------------------------------------------------------------------
              (                  
                 select
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
                ,decode( to_char(IMP_FATT.ID_ORDINE), null, 'N', 'S' ) COMPLETATO_AMM
                ,IMP_FATT.ID_ORDINE
                ,IMP_FATT.PERC_SCONTO_SOST_AGE
                ,IMP_FATT.PERC_VEND_CLI
                ,ORD.ID_CLIENTE_COMMITTENTE
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
                           from cd_sintesi_prod_acq spa, cd_periodo_speciale ps
                           where spa.data_fine < trunc(sysdate)
                             and ((spa.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                    or
                                  (spa.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                    or
                                  (spa.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and spa.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                 )
                             and ps.DATA_INIZIO = spa.DATA_INIZIO
                             and ps.DATA_FINE   = spa.DATA_FINE   
                           union
                           -- prodotto acquistato a cavallo o successivo a sysdate
                           select
                             id_prodotto_acquistato
                            ,id_soggetto_di_piano
                            ,data_erogazione_prev
                            ,num_giorni_totale
                            ,count(distinct id_soggetto_di_piano) over (partition by id_prodotto_acquistato,data_erogazione_prev) num_soggetti_giorno
                             /* news: conteggio di num_sale_giorno */
                            ,count(distinct id_sala) over (partition by id_prodotto_acquistato,data_erogazione_prev) num_sale_giorno
                           from
                             (select distinct
                                PA_TOT.id_prodotto_acquistato
                               ,PA_TOT.data_inizio
                               ,PA_TOT.data_fine
                               ,PA_TOT.data_erogazione_prev
                               ,SPOT.id_soggetto_di_piano
                                /* news: conteggio di num_sale_giorno */
                               ,SPOT.id_sala
                               ,PA_TOT.num_giorni_totale
                              from
                                cd_comunicato SPOT,
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
                                         cd_prodotto_acquistato PA, cd_periodo_speciale ps
                                       where PA.data_fine >= trunc(sysdate) and
                                             ((PA.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                             )
                                         and flg_annullato='N'
                                         and flg_sospeso='N'
                                         and ps.DATA_INIZIO = pa.DATA_INIZIO
                                         and ps.DATA_FINE   = pa.DATA_FINE 
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
                                      cd_prodotto_acquistato PA,
                                      cd_periodo_speciale ps
                                    where PA.data_fine >= trunc(sysdate) and
                                             ((PA.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                             )
                                      and ps.DATA_INIZIO = pa.DATA_INIZIO
                                      and ps.DATA_FINE   = pa.DATA_FINE        
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
                                and SPOT.data_erogazione_prev = decode (flag_giorno, 'EFF', PA_TOT.data_erogazione_prev, SPOT.data_erogazione_prev)
                                and SPOT.flg_annullato='N'
                                and SPOT.flg_sospeso='N'
                                and SPOT.cod_disattivazione is null
                             )
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
                ) SPOT
              ----------------------------------------------------------------------------------
            where
              SPOT.STATO_DI_VENDITA = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_STATO_VEND, SPOT.STATO_DI_VENDITA)
              and PIA.COD_CATEGORIA_PRODOTTO = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_CATEGORIA_PUBB, PIA.COD_CATEGORIA_PRODOTTO) 
              and PIA.ID_PIANO = SPOT.ID_PIANO
              and PIA.ID_VER_PIANO = SPOT.ID_VER_PIANO
              and PIA.ID_CLIENTE = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_CLI_COMM, PIA.ID_CLIENTE)
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
              --and CIR.id_circuito = CIS.id_circuito
              --and CIS.id_schermo = SCH.id_schermo  
              --and SCH.id_sala = SA.id_sala
              --
              and ( PV.id_tipo_break is null or PV.id_tipo_break = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_TIPO_BREAK, PV.id_tipo_break))
              and PV.flg_abbinato = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_FLG_ABBINATO, PV.flg_abbinato)          
              and TB.id_tipo_break (+)= PV.id_tipo_break
              and PV.id_mod_vendita = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_MOD_VENDITA, PV.id_mod_vendita)   
              and MV.id_mod_vendita = PV.id_mod_vendita
              and FO.id_formato = SPOT.id_formato
              and DUR.id_coeff (+)= FO.id_coeff
              --and POS.COD_POSIZIONE(+) = SPOT.posizione_di_rigore
              and SPOT.TIPO_CONTRATTO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_TIPO_CONTRATTO, SPOT.TIPO_CONTRATTO)
              and spot.ID_PRODOTTO_ACQUISTATO in
              (select ID_PRODOTTO_ACQUISTATO
              from
              cd_sala SA,
              cd_comunicato com
              where com.id_prodotto_acquistato = spot.id_prodotto_acquistato
              and sa.ID_SALA (+)= com.ID_SALA
              and com.FLG_ANNULLATO ='N'
              and com.FLG_SOSPESO ='N'
              and com.COD_DISATTIVAZIONE is null
              and ( SA.flg_arena is null or SA.flg_arena = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_FLG_ARENA, SA.flg_arena))
              and spot.ID_PIANO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_GET_ID_PIANO,SPOT.ID_PIANO)
              and spot.ID_VER_PIANO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_GET_ID_VER_PIANO,SPOT.ID_VER_PIANO)
               )
  )   --
        group by
        id_prodotto_acquistato,
        CIRCUITO,
        DESC_TIPO_BREAK,
        DESC_MOD_VENDITA,
        COD_CATEGORIA_PRODOTTO,
        TIPO_CONTRATTO,
        FLG_ARENA,
        FLG_ABBINATO,
        data_inizio_periodo,
        data_fine_periodo
        order by
        CIRCUITO,
        DESC_TIPO_BREAK,
        TIPO_CONTRATTO
    )
   )
   group by 
   decode(codCategoriaProd,'ISP', ID_PRODOTTO_ACQUISTATO, 0),
    circuito,
    descTipoBreak,
    descModVendita,
    codCategoriaProd,
    tipocontratto,
    flgArena, 
    flgAbbinato;
       
return  C_SIT_VENDUTO_PROD;

-----------------------------
END fu_situaz_venduto_prodotto_ps;



-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, maggio 2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_sit_vend_prod_no_tipo_contr   Estrae i dati relativi alla situazione 
--                                           del venduto del prodotto senza rottura per tipo contratto
--                                           su di un periodo speciale.
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:

FUNCTION fu_sit_ven_prod_no_tip_cont_ps RETURN C_SITUAZ_VENDUTO_PRODOTTO IS
C_SIT_VENDUTO_PROD C_SITUAZ_VENDUTO_PRODOTTO;
BEGIN
OPEN C_SIT_VENDUTO_PROD FOR
    with sitps as 
   (select
    0 as ID_PRODOTTO_ACQUISTATO,
    CIRCUITO,
    BREAK,
    MODALITA_VENDITA,
    COD_CATEGORIA_PRODOTTO,
    DURATA_MEDIA,
    GIORNI_MEDI,
    NUM_SALE_MEDIO,
    TIPO_CONTRATTO, --decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as TIPOCONTRATTO,
    LORDO,
    SANATORIA,
    RECUPERO,
    NETTO,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(netto, IMP_SC_COMM) as percScComm,
    FLG_ARENA,
    FLG_ABBINATO
    from 
    (
        SELECT 
        data_inizio_periodo,
        data_fine_periodo,      
        CIRCUITO,
        DESC_TIPO_BREAK AS BREAK,
        DESC_MOD_VENDITA AS MODALITA_VENDITA,
        COD_CATEGORIA_PRODOTTO,
        ROUND(SUM(DURATA)/AVG(NUM_GIORNI_TOTALE)) DURATA_MEDIA, 
        ROUND(AVG(NUM_GIORNI_TOTALE)) GIORNI_MEDI,
        ROUND(AVG(NUM_SALE_GIORNO))   NUM_SALE_MEDIO,
        TIPO_CONTRATTO,
        sum (IMP_LORDO) AS LORDO,
        sum (IMP_SANATORIA) AS SANATORIA,
        sum(IMP_RECUPERO) AS RECUPERO,
        sum(IMP_NETTO) AS NETTO,
        sum(IMP_SC_COMM) AS IMP_SC_COMM,
        FLG_ARENA,
        FLG_ABBINATO
        from 
        (
               select
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
              --,SPOT.POSIZIONE_DI_RIGORE
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
              ,null as flg_arena --SA.flg_arena
              ,PV.flg_abbinato   
            from
              --cd_posizione_rigore POS,
              cd_coeff_cinema DUR,
              cd_formato_acquistabile FO,
              cd_modalita_vendita MV,
              cd_tipo_break TB,
              cd_circuito CIR,   
              --cd_circuito_schermo CIS,  
              --cd_schermo SCH,   
              cd_prodotto_vendita PV,
              sedi SE,
              aree AR,
              vi_cd_clicomm CC,
              VI_CD_AREE_SEDI_COMPET ARSE,
              cd_pianificazione PIA,
              ----------------------------------------------------------------------------------
              (                  
                 select
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
                ,decode( to_char(IMP_FATT.ID_ORDINE), null, 'N', 'S' ) COMPLETATO_AMM
                ,IMP_FATT.ID_ORDINE
                ,IMP_FATT.PERC_SCONTO_SOST_AGE
                ,IMP_FATT.PERC_VEND_CLI
                ,ORD.ID_CLIENTE_COMMITTENTE
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
                           from cd_sintesi_prod_acq spa, cd_periodo_speciale ps
                           where spa.data_fine < trunc(sysdate)
                             and ((spa.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                    or
                                  (spa.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                    or
                                  (spa.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and spa.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                 )
                             and ps.DATA_INIZIO = spa.DATA_INIZIO
                             and ps.DATA_FINE   = spa.DATA_FINE   
                           union
                           -- prodotto acquistato a cavallo o successivo a sysdate
                           select
                             id_prodotto_acquistato
                            ,id_soggetto_di_piano
                            ,data_erogazione_prev
                            ,num_giorni_totale
                            ,count(distinct id_soggetto_di_piano) over (partition by id_prodotto_acquistato,data_erogazione_prev) num_soggetti_giorno
                             /* news: conteggio di num_sale_giorno */
                            ,count(distinct id_sala) over (partition by id_prodotto_acquistato,data_erogazione_prev) num_sale_giorno
                           from
                             (select distinct
                                PA_TOT.id_prodotto_acquistato
                               ,PA_TOT.data_inizio
                               ,PA_TOT.data_fine
                               ,PA_TOT.data_erogazione_prev
                               ,SPOT.id_soggetto_di_piano
                                /* news: conteggio di num_sale_giorno */
                               ,SPOT.id_sala
                               ,PA_TOT.num_giorni_totale
                              from
                                cd_comunicato SPOT,
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
                                         cd_prodotto_acquistato PA, cd_periodo_speciale ps
                                       where PA.data_fine >= trunc(sysdate) and
                                             ((PA.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                             )
                                         and flg_annullato='N'
                                         and flg_sospeso='N'
                                         and ps.DATA_INIZIO = pa.DATA_INIZIO
                                         and ps.DATA_FINE   = pa.DATA_FINE 
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
                                      cd_prodotto_acquistato PA,
                                      cd_periodo_speciale ps
                                    where PA.data_fine >= trunc(sysdate) and
                                             ((PA.data_inizio between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_fine between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                               or
                                               (PA.data_inizio < PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and PA.data_fine > PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE)
                                             )
                                      and ps.DATA_INIZIO = pa.DATA_INIZIO
                                      and ps.DATA_FINE   = pa.DATA_FINE        
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
                                and SPOT.data_erogazione_prev = decode (flag_giorno, 'EFF', PA_TOT.data_erogazione_prev, SPOT.data_erogazione_prev)
                                and SPOT.flg_annullato='N'
                                and SPOT.flg_sospeso='N'
                                and SPOT.cod_disattivazione is null
                             )
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
                ) SPOT
              ----------------------------------------------------------------------------------
            where
              SPOT.STATO_DI_VENDITA = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_STATO_VEND, SPOT.STATO_DI_VENDITA)
              and PIA.COD_CATEGORIA_PRODOTTO = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_CATEGORIA_PUBB, PIA.COD_CATEGORIA_PRODOTTO) 
              and PIA.ID_PIANO = SPOT.ID_PIANO
              and PIA.ID_VER_PIANO = SPOT.ID_VER_PIANO
              and PIA.ID_CLIENTE = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_CLI_COMM, PIA.ID_CLIENTE)
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
              --and CIR.id_circuito = CIS.id_circuito
              --and CIS.id_schermo = SCH.id_schermo  
              --and SCH.id_sala = SA.id_sala
              --
              and ( PV.id_tipo_break is null or PV.id_tipo_break = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_TIPO_BREAK, PV.id_tipo_break))
              and PV.flg_abbinato = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_FLG_ABBINATO, PV.flg_abbinato)          
              and TB.id_tipo_break (+)= PV.id_tipo_break
              and PV.id_mod_vendita = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_MOD_VENDITA, PV.id_mod_vendita)   
              and MV.id_mod_vendita = PV.id_mod_vendita
              and FO.id_formato = SPOT.id_formato
              and DUR.id_coeff (+)= FO.id_coeff
              --and POS.COD_POSIZIONE(+) = SPOT.posizione_di_rigore
              and SPOT.TIPO_CONTRATTO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_TIPO_CONTRATTO, SPOT.TIPO_CONTRATTO)
              and spot.ID_PRODOTTO_ACQUISTATO in
              (select ID_PRODOTTO_ACQUISTATO
              from
              cd_sala SA,
              cd_comunicato com
              where com.id_prodotto_acquistato = spot.id_prodotto_acquistato
              and sa.ID_SALA (+)= com.ID_SALA
              and com.FLG_ANNULLATO ='N'
              and com.FLG_SOSPESO ='N'
              and com.COD_DISATTIVAZIONE is null
              and ( SA.flg_arena is null or SA.flg_arena = nvl( PA_CD_SITUAZIONE_VENDUTO.FU_FLG_ARENA, SA.flg_arena))
              and spot.ID_PIANO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_GET_ID_PIANO,SPOT.ID_PIANO)
              and spot.ID_VER_PIANO = nvl(PA_CD_SITUAZIONE_VENDUTO.FU_GET_ID_VER_PIANO,SPOT.ID_VER_PIANO)
               )
  )   
        group by
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
   )
select ID_PRODOTTO_ACQUISTATO, 
       CIRCUITO as circuito, 
       BREAK as descTipoBreak, 
       MODALITA_VENDITA as descModVendita, 
       COD_CATEGORIA_PRODOTTO as codCategoriaProd, 
       DURATA_MEDIA as durata, 
       GIORNI_MEDI as giorniMedi, 
       NUM_SALE_MEDIO as numSaleMedio,
       '-' as TIPOCONTRATTO,
       sum(LORDO) as impLordo, 
       sum(SANATORIA) as impSanatoria, 
       sum(RECUPERO)  as impRecupero, 
       sum(NETTO) as impNetto, 
       sum(percScComm) as percScComm, 
       FLG_ARENA as flgArena,
       FLG_ABBINATO as flgAbbinato        
        from 
        sitps 
        group by 
        ID_PRODOTTO_ACQUISTATO, 
        CIRCUITO, 
        BREAK, 
        MODALITA_VENDITA, 
        COD_CATEGORIA_PRODOTTO, 
        DURATA_MEDIA, 
        GIORNI_MEDI, 
        NUM_SALE_MEDIO,  
        FLG_ARENA, 
        FLG_ABBINATO, 
        decode(TIPO_CONTRATTO,'C','C','C')
        order by
        circuito,
        descTipoBreak;     
return  C_SIT_VENDUTO_PROD;
-----------------------------
END fu_sit_ven_prod_no_tip_cont_ps;




-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, febbraio  2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_sit_prod_settimana   Estrae i dati relativi alla situazione del venduto del cliente/prodotto/settimana
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:
-- 

FUNCTION fu_sit_prod_settimana RETURN C_SITUAZ_PRODOTTO_SETTIMANA IS
C_SIT_VENDUTO_PROD C_SITUAZ_PRODOTTO_SETTIMANA;
BEGIN
OPEN C_SIT_VENDUTO_PROD FOR
    select 
    ID_PRODOTTO_ACQUISTATO,
    circuito,
    BREAK as descTipoBreak,
    MODALITA_VENDITA as descModVendita,
    periodo,
    COD_CATEGORIA_PRODOTTO as codCategoriaProd,
    DURATA_MEDIA as durata,
    GIORNI_MEDI as giorniMedi,
    NUM_SALE_MEDIO as numSaleMedio,
    decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as TIPOCONTRATTO,
    LORDO as impLordo,
    SANATORIA as impSanatoria,
    RECUPERO as impRecupero,
    NETTO as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(netto, IMP_SC_COMM) as percScComm,
    FLG_ARENA as flgArena,
    FLG_ABBINATO as flgAbbinato
    from VI_CD_SIT_PROD_SETTIMANA;
    
/*select 
       nvl(vi_cd_prodotti_venduti.id_prodotto_acquistato, vi_cd_prodotti_vendibili.id_prodotto_acquistato) as id_prodotto_acquistato,
       nvl(vi_cd_prodotti_venduti.circuito, vi_cd_prodotti_vendibili.circuito)  as circuito,
       nvl(vi_cd_prodotti_venduti.descTipoBreak, vi_cd_prodotti_vendibili.break) as descTipoBreak,
       nvl(vi_cd_prodotti_venduti.descModVendita, vi_cd_prodotti_vendibili.modalita_vendita) as descModVendita,
       nvl(vi_cd_prodotti_venduti.periodo, vi_cd_prodotti_vendibili.periodo) as periodo,
       nvl(vi_cd_prodotti_venduti.codCategoriaProd, vi_cd_prodotti_vendibili.categoria_prod) as codCategoriaProd,
       nvl(vi_cd_prodotti_venduti.durata, vi_cd_prodotti_vendibili.durata_media) as durata ,
       nvl(vi_cd_prodotti_venduti.giorniMedi, vi_cd_prodotti_vendibili.giorni_medi) as giorniMedi ,
       nvl(vi_cd_prodotti_venduti.numSaleMedio, vi_cd_prodotti_vendibili.num_sale_medio) as numSaleMedio,
       nvl(vi_cd_prodotti_venduti.tipoContratto, vi_cd_prodotti_vendibili.tipo_contratto) as tipocontratto,
       nvl(vi_cd_prodotti_venduti.impLordo, vi_cd_prodotti_vendibili.lordo) as impLordo,
       nvl(vi_cd_prodotti_venduti.impSanatoria, vi_cd_prodotti_vendibili.sanatoria) as impSanatoria,
       nvl(vi_cd_prodotti_venduti.impRecupero, vi_cd_prodotti_vendibili.recupero) as impRecupero,
       nvl(vi_cd_prodotti_venduti.impNetto, vi_cd_prodotti_vendibili.netto) as impNetto,
       nvl(vi_cd_prodotti_venduti.percScComm, vi_cd_prodotti_vendibili.imp_sc_comm) as percScComm,
       nvl(vi_cd_prodotti_venduti.flgArena, vi_cd_prodotti_vendibili.flg_arena) as flgArena,
       nvl(vi_cd_prodotti_venduti.flgAbbinato, vi_cd_prodotti_vendibili.flg_abbinato) as flgAbbinato       
from
VI_CD_PRODOTTI_VENDIBILI,        
(
    select 
    ID_PRODOTTO_ACQUISTATO,
    circuito,
    BREAK as descTipoBreak,
    MODALITA_VENDITA as descModVendita,
    periodo,
    COD_CATEGORIA_PRODOTTO as codCategoriaProd,
    DURATA_MEDIA as durata,
    GIORNI_MEDI as giorniMedi,
    NUM_SALE_MEDIO as numSaleMedio,
    decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as TIPOCONTRATTO,
    LORDO as impLordo,
    SANATORIA as impSanatoria,
    RECUPERO as impRecupero,
    NETTO as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(netto, IMP_SC_COMM) as percScComm,
    FLG_ARENA as flgArena,
    FLG_ABBINATO as flgAbbinato
    from VI_CD_SIT_PROD_SETTIMANA
)vi_cd_prodotti_venduti
where vi_cd_prodotti_vendibili.id_prodotto_acquistato   =  vi_cd_prodotti_venduti.id_prodotto_acquistato (+)
and   vi_cd_prodotti_vendibili.circuito   =  vi_cd_prodotti_venduti.circuito (+)
and   vi_cd_prodotti_vendibili.break  =  vi_cd_prodotti_venduti.descTipoBreak  (+)
and   vi_cd_prodotti_vendibili.modalita_vendita   =  vi_cd_prodotti_venduti.descModVendita (+)
and   vi_cd_prodotti_vendibili.categoria_prod  =  vi_cd_prodotti_venduti.codCategoriaProd  (+) 
and   vi_cd_prodotti_vendibili.tipo_contratto    =  vi_cd_prodotti_venduti.tipocontratto (+)
and   vi_cd_prodotti_vendibili.periodo = vi_cd_prodotti_venduti.periodo (+); */
return  C_SIT_VENDUTO_PROD;

-----------------------------
END fu_sit_prod_settimana;




-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, gennaio 2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_sit_prod_settimana_ps   Estrae i dati relativi alla situazione del venduto del cliente/prodotto/prodotto per un periodo_speciale
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:

FUNCTION fu_sit_prod_settimana_ps RETURN C_SITUAZ_PRODOTTO_SETTIMANA IS
C_SIT_VENDUTO_PROD C_SITUAZ_PRODOTTO_SETTIMANA;
BEGIN
OPEN C_SIT_VENDUTO_PROD FOR
    select 
    ID_PRODOTTO_ACQUISTATO,
    circuito,
    BREAK as descTipoBreak,
    MODALITA_VENDITA as descModVendita,
    periodo,
    COD_CATEGORIA_PRODOTTO as codCategoriaProd,
    DURATA_MEDIA as durata,
    GIORNI_MEDI as giorniMedi,
    NUM_SALE_MEDIO as numSaleMedio,
    decode(TIPO_CONTRATTO,'C','Comm.','Dir.') as TIPOCONTRATTO,
    LORDO as impLordo,
    SANATORIA as impSanatoria,
    RECUPERO as impRecupero,
    NETTO as impNetto,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(netto, IMP_SC_COMM) as percScComm,
    FLG_ARENA as flgArena,
    FLG_ABBINATO as flgAbbinato
    from VI_CD_SIT_PROD_SETTIMANA prod_set, cd_periodo_speciale ps
    where  prod_set.PERIODO = to_char(ps.data_inizio,'DDMMYYYY')||'-'||to_char(ps.data_fine,'DDMMYYYY');
 
return  C_SIT_VENDUTO_PROD;

-----------------------------

END fu_sit_prod_settimana_ps;


-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, novembre 2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_affollamento   Estrae i dati relativi all'affollamento
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:

FUNCTION fu_affollamento RETURN c_affollamento IS
v_affollamento c_affollamento;
BEGIN
OPEN v_affollamento for
    select anno, ciclo, '' as periodo,tipo_break, '' as circuito
    , round(avg(affoll_medio_giorno)) affoll_medio
    , round(avg(affoll_medio_non_pagato_giorno)) affoll_medio_non_pagato
    , round(avg(tot_sale_giorno)) num_medio_sale
    from
    (
    select anno, ciclo, tipo_break, data_trasm, gg.tot_sale_giorno
    , sum(affoll)/ gg.tot_sale_giorno affoll_medio_giorno
    , sum(affoll_non_pagato)/ gg.tot_sale_giorno affoll_medio_non_pagato_giorno
    from
    (
    select data_proiezione, count(distinct pro.id_schermo) tot_sale_giorno
    from
      cd_cinema ci,
      cd_sala sa,
      cd_schermo sch,
      cd_proiezione pro
    where data_proiezione between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE
    and pro.flg_annullato = 'N'
    and sch.id_schermo=pro.id_schermo
    and sa.id_sala = sch.id_sala
    and flg_arena='N'
    and ci.id_cinema = sa.id_cinema
    and flg_virtuale='N'
    group by data_proiezione
    ) gg,
    (
    select anno, ciclo
    , tb_trasm.desc_tipo_break tipo_break
    , circuito, data_trasm
    --, sum(decode(imp_netto, 0, durata, 0)) durata_non_pagato
    , sum(durata)*num_sale_giorno affoll
    , sum(decode(imp_netto, 0, durata, 0))*num_sale_giorno affoll_non_pagato
    from
      cd_tipo_break tb_trasm,
      cd_tipo_break tb,
      periodi pe,
      VI_CD_BASE_SITUAZIONE_VENDUTO SV
    where data_trasm between pe.data_iniz and pe.data_fine
      and flg_arena = 'N'
      and tb.id_tipo_break = SV.id_tipo_break
      and tb_trasm.id_tipo_break = tb.id_tipo_break_proiezione
    group by anno, ciclo, tb_trasm.desc_tipo_break
    , circuito, data_trasm, num_sale_giorno
    ) vv
    where gg.data_proiezione = vv.data_trasm
    group by anno, ciclo, tipo_break, data_trasm, gg.tot_sale_giorno
    )
    group by anno, ciclo, tipo_break
    order by anno, ciclo, tipo_break desc;
return  v_affollamento;
end fu_affollamento;


-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, novembre 2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_affollamento   Estrae i dati relativi all'affollamento
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:

FUNCTION fu_affollamento_periodo RETURN c_affollamento IS
v_affollamento c_affollamento;
BEGIN
OPEN v_affollamento for
    select anno, ciclo, per as periodo,tipo_break, '' as circuito
    , round(avg(affoll_medio_giorno)) affoll_medio
    , round(avg(affoll_medio_non_pagato_giorno)) affoll_medio_non_pagato
    , round(avg(tot_sale_giorno)) num_medio_sale
    from
    (
    select anno, ciclo,per, tipo_break, data_trasm, gg.tot_sale_giorno
    , sum(affoll)/ gg.tot_sale_giorno affoll_medio_giorno
    , sum(affoll_non_pagato)/ gg.tot_sale_giorno affoll_medio_non_pagato_giorno
    from
    (
    select data_proiezione, count(distinct pro.id_schermo) tot_sale_giorno
    from
      cd_cinema ci,
      cd_sala sa,
      cd_schermo sch,
      cd_proiezione pro
    where data_proiezione between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE
    and pro.flg_annullato = 'N'
    and sch.id_schermo=pro.id_schermo
    and sa.id_sala = sch.id_sala
    and flg_arena='N'
    and ci.id_cinema = sa.id_cinema
    and flg_virtuale='N'
    group by data_proiezione
    ) gg,
    (
    select anno, ciclo,per
    , tb_trasm.desc_tipo_break tipo_break
    , circuito, data_trasm
    --, sum(decode(imp_netto, 0, durata, 0)) durata_non_pagato
    , sum(durata)*num_sale_giorno affoll
    , sum(decode(imp_netto, 0, durata, 0))*num_sale_giorno affoll_non_pagato
    from
      cd_tipo_break tb_trasm,
      cd_tipo_break tb,
      periodi pe,
      VI_CD_BASE_SITUAZIONE_VENDUTO SV
    where data_trasm between pe.data_iniz and pe.data_fine
      and flg_arena = 'N'
      and tb.id_tipo_break = SV.id_tipo_break
      and tb_trasm.id_tipo_break = tb.id_tipo_break_proiezione
    group by anno, ciclo, tb_trasm.desc_tipo_break
    , circuito, data_trasm, num_sale_giorno,per
    ) vv
    where gg.data_proiezione = vv.data_trasm
    group by anno, ciclo,per, tipo_break, data_trasm, gg.tot_sale_giorno
    )
    group by anno, ciclo,per, tipo_break
    order by anno, ciclo,per,tipo_break desc;
return  v_affollamento;
END fu_affollamento_periodo;


-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, novembre 2011
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_affollamento   Estrae i dati relativi all'affollamento
-- --------------------------------------------------------------------------------------------
-- MODIFICHE:

FUNCTION fu_affollamento_circuito RETURN c_affollamento IS
v_affollamento c_affollamento;
BEGIN
OPEN v_affollamento for
  select anno, ciclo, '' as periodo, tipo_break, circuito
, round(avg(affoll_medio_giorno)) affoll_medio
, round(avg(affoll_medio_non_pagato_giorno)) affoll_medio_non_pagato
, round(avg(num_sale_giorno)) num_medio_sale
from
(
select anno, ciclo, tipo_break, circuito, data_trasm, num_sale_giorno
, sum(affoll)/ num_sale_giorno affoll_medio_giorno
, sum(affoll_non_pagato)/ num_sale_giorno affoll_medio_non_pagato_giorno
from
(
select anno, ciclo
, tb_trasm.desc_tipo_break tipo_break
, circuito, max(num_sale_giorno) num_sale_giorno
, data_trasm
, sum(decode(imp_netto, 0, durata, 0)) durata_non_pagato
, sum(durata*num_sale_giorno) affoll
, sum(decode(imp_netto, 0, durata, 0)*num_sale_giorno) affoll_non_pagato
from
  cd_tipo_break tb_trasm,
  cd_tipo_break tb,
  periodi pe,
  (
    select
      gg.data_proiezione data_trasm, gg.nome_circuito circuito, gg.id_tipo_break
      , nvl(SV.num_sale_giorno, gg.num_sale_giorno) num_sale_giorno, nvl(SV.durata, 0) durata, nvl(SV.imp_netto, 0) imp_netto
    from
      VI_CD_BASE_SITUAZIONE_VENDUTO SV,
      (
        select data_proiezione, nome_circuito, ctb.id_tipo_break, count(distinct pro.id_schermo) num_sale_giorno
        from
          cd_circuito_tipo_break ctb,
          cd_circuito cir,
          cd_circuito_schermo csc,
          cd_listino li,
          cd_cinema ci,
          cd_sala sa,
          cd_schermo sch,
          cd_proiezione pro
        where data_proiezione between PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO and  PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE
        and pro.flg_annullato = 'N'
        and pro.id_fascia=1
        and sch.id_schermo = pro.id_schermo
        and sa.id_sala = sch.id_sala
        and sa.flg_arena = 'N'
        and ci.id_cinema = sa.id_cinema
        and ci.flg_virtuale='N'
        and pro.data_proiezione between li.data_inizio and li.data_fine
        and li.cod_categoria_prodotto='TAB'
        and csc.id_schermo = pro.id_schermo
        and csc.id_listino = li.id_listino
        and cir.id_circuito = csc.id_circuito
        and cir.flg_arena='N'
        and cir.flg_definito_a_listino='S'
        and ctb.id_circuito = cir.id_circuito
        and ctb.flg_annullato = 'N'
        group by data_proiezione, nome_circuito, ctb.id_tipo_break
      ) gg
    where gg.data_proiezione = SV.data_trasm(+)
      and gg.nome_circuito = SV.circuito(+)
      and gg.id_tipo_break = SV.id_tipo_break(+)
      and nvl(SV.flg_arena,'N') = 'N'
      and nvl(SV.STATO_DI_VENDITA,'PRE') = 'PRE'
  ) FV
where FV.data_trasm between pe.data_iniz and pe.data_fine
  and tb.id_tipo_break = FV.id_tipo_break
  and tb_trasm.id_tipo_break = tb.id_tipo_break_proiezione
group by anno, ciclo, tb_trasm.desc_tipo_break
, circuito, data_trasm
) vv
group by anno, ciclo, tipo_break, circuito, data_trasm, num_sale_giorno
)
group by anno, ciclo, tipo_break, circuito
order by anno, ciclo, tipo_break desc, circuito;
return  v_affollamento;
END fu_affollamento_circuito;

function FU_NO_DIV_TIPO_CONTRATTO RETURN varchar2 is
begin
    return P_NO_DIV_TIPO_CONTRATTO;
end FU_NO_DIV_TIPO_CONTRATTO;

END PA_CD_SITUAZIONE_VENDUTO; 
/

