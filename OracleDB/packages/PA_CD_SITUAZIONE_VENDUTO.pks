CREATE OR REPLACE PACKAGE VENCD.PA_CD_SITUAZIONE_VENDUTO IS
/* -----------------------------------------------------------------------------------------------------------

   Descrizione: Package di parametrizzazione delle estrazioni di venduto
   
   29/09/2010 Mauro Viel Altran Italia : Aggiunto il costruttore con id_piano id_ver_piano e i due getter

----------------------------------------------------------------------------------------------------------- */
--
--
--Record contenente i dati di base per la situazione venduto
--Autore Daniela Spezia Febbraio 2010
--
TYPE R_SITUAZ_VENDUTO IS RECORD
(
    id_piano cd_pianificazione.id_piano%type,
    id_piano_ver cd_pianificazione.id_ver_piano%type,
    clienteComm         VARCHAR2(70),
    --desSogg             VARCHAR2(100),
    --area                VARCHAR2(15),
    --gruppo              VARCHAR2(15),
    tipoContratto       CHAR,
    impLordo            NUMBER,
    impSanatoria        NUMBER,
    impRecupero         NUMBER,
    impNetto            NUMBER,
    percScComm          NUMBER--,
    --nomeCircuito        VARCHAR2(30),
    --descTipoBreak       VARCHAR2(100),
    --descModVendita      VARCHAR2(30),
    --codCategoriaProd    VARCHAR(20),
    --flgArena            VARCHAR(1),
    --flgAbbinato         VARCHAR(1)
) ;
--

TYPE C_SITUAZ_VENDUTO IS REF CURSOR RETURN R_SITUAZ_VENDUTO;

TYPE R_SITUAZ_VENDUTO_DETTAGLIO IS RECORD
(
    id_piano cd_pianificazione.id_piano%type,
    id_piano_ver cd_pianificazione.id_ver_piano%type,
    clienteComm         VARCHAR2(70),
    desSogg             VARCHAR2(100),
    area                VARCHAR2(15),
    gruppo              VARCHAR2(15),
    tipoContratto       CHAR,
    impLordo            NUMBER,
    impSanatoria        NUMBER,
    impRecupero         NUMBER,
    impNetto            NUMBER,
    percScComm          NUMBER,
    nomeCircuito        VARCHAR2(30),
    descTipoBreak       VARCHAR2(100),
    descModVendita      VARCHAR2(30),
    codCategoriaProd    VARCHAR(20),
    flgArena            VARCHAR(1),
    flgAbbinato         VARCHAR(1)
) ;
--
TYPE C_SITUAZ_VENDUTO_DETTAGLIO IS REF CURSOR RETURN R_SITUAZ_VENDUTO_DETTAGLIO;


TYPE R_SIT_VEND_DETT_PROD IS RECORD
(
    id_piano cd_pianificazione.id_piano%type,
    id_piano_ver cd_pianificazione.id_ver_piano%type,
    id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
    clienteComm         VARCHAR2(70),
    desSogg             VARCHAR2(100),
    area                VARCHAR2(15),
    gruppo              VARCHAR2(15),
    tipoContratto       CHAR,
    impLordo            NUMBER,
    data_inizio_periodo DATE,
    data_fine_periodo   DATE,
    impNetto            NUMBER,
    percScComm          NUMBER,
    durata              NUMBER,
    nomeCircuito        VARCHAR2(30),
    descTipoBreak       VARCHAR2(100),
    descModVendita      VARCHAR2(30),
    codCategoriaProd    VARCHAR(20),
    flgArena            VARCHAR(1),
    flgAbbinato         VARCHAR(1)
) ;

TYPE C_SIT_VEND_DETT_PROD  IS REF CURSOR RETURN R_SIT_VEND_DETT_PROD;

--


--Record contenenete le informazioni per la situazione di venduto del prodotto.
--Mauro Viel Altran Italia marzo 2010

TYPE R_SITUAZ_VENDUTO_PRODOTTO IS RECORD
(
    ID_PRODOTTO_ACQUISTATO cd_prodotto_acquistato.id_prodotto_acquistato%type,
    CIRCUITO VARCHAR2(30),
    BREAK VARCHAR2(100),
    MODALITA_VENDITA  VARCHAR2(30),
    COD_CATEGORIA_PRODOTTO VARCHAR(20),
    DURATA NUMBER,
    GIORNI_MEDI NUMBER,
    NUM_SALE_MEDIO NUMBER,
    TIPO_CONTRATTO VARCHAR2(10),
    LORDO NUMBER,
    SANATORIA NUMBER,
    RECUPERO NUMBER,
    IMP_NETTO NUMBER,
    PERC_SC_COMM NUMBER,
    flgArena            VARCHAR(1),
    flgAbbinato         VARCHAR(1)
);

--Tipo contenenete le informazioni per la situazione di venduto del prodotto.
--Mauro Viel Altran Italia marzo 2010

TYPE C_SITUAZ_VENDUTO_PRODOTTO IS REF CURSOR RETURN R_SITUAZ_VENDUTO_PRODOTTO;



--Record contenenete le informazioni per la situazione di venduto del prodotto settimana.
--Mauro Viel Altran Italia febbraio 2011

TYPE R_SIT_VEND_PRODOTTO_SETTIMANA IS RECORD
(
    ID_PRODOTTO_ACQUISTATO cd_prodotto_acquistato.id_prodotto_acquistato%type,
    CIRCUITO VARCHAR2(30),
    BREAK VARCHAR2(100),
    MODALITA_VENDITA  VARCHAR2(30),
    PERIODO VARCHAR2(30),
    COD_CATEGORIA_PRODOTTO VARCHAR(20),
    DURATA NUMBER,
    GIORNI_MEDI NUMBER,
    NUM_SALE_MEDIO NUMBER,
    TIPO_CONTRATTO VARCHAR2(10),
    LORDO NUMBER,
    SANATORIA NUMBER,
    RECUPERO NUMBER,
    IMP_NETTO NUMBER,
    PERC_SC_COMM NUMBER,
    flgArena            VARCHAR(1),
    flgAbbinato         VARCHAR(1)
);


--Tipo contenenete le informazioni per la situazione di venduto del prodotto.
--Mauro Viel Altran Italia marzo 2010

TYPE C_SITUAZ_PRODOTTO_SETTIMANA IS REF CURSOR RETURN R_SIT_VEND_PRODOTTO_SETTIMANA;

--tipo per l'estrazione dell'affollamento Mauro Viel Altran Italia. 
type r_affollamento is record
 ( anno    number,
   ciclo   number,
   periodo number,
   tipo_break cd_tipo_break.DESC_TIPO_BREAK%type,
   circuito   cd_circuito.NOME_CIRCUITO%type,
   affoll_medio number,
   affoll_medio_non_pagato number,
   num_medio_sale number
 
 );
 
 type c_affollamento  IS REF CURSOR RETURN r_affollamento; 

-----------------------------------------------------------------------------------------------------------
-- Procedura: IMPOSTA_PARAMETRI
--
-- input: valori DATA_INIZIO e DATA_FINE da assegnare alle variabili di package.
--
-- realizzatore:
--	 luigi cipolla, 30/12/2009
--
-- modifiche:
--  Simone Bottani, Altran, Maggio 2010
--  Aggiunto parametro tipo contratto
--  Michele Borgogno, Altran, Maggio 2010
--      Aggiunti flg_arena, flg_abbinato
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
  no_div_tipo_contratto varchar2 DEFAULT 'N');
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
function FU_CATEGORIA_PUBB RETURN varchar2;
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
function FU_STATO_VEND RETURN varchar2;
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
function FU_CLI_COMM RETURN varchar2;
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
function FU_AREA RETURN varchar2;
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
function FU_SEDE RETURN varchar2;
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
function FU_CIRCUITO RETURN number;
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
function FU_TIPO_BREAK RETURN number;
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
function FU_MOD_VENDITA RETURN number;
-----------------------------------------------------------------------------------------------------------
--
--  Daniela Spezia, altran, febbraio 2010
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_situaz_venduto   Estrae i dati relativi alla situazione del venduto
-- --------------------------------------------------------------------------------------------
FUNCTION fu_situaz_venduto RETURN C_SITUAZ_VENDUTO;

-----------------------------------------------------------------------------------------------------------
--
--  Simone Bottani, altran, settembre 2010
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_situaz_venduto_dettaglio   Estrae i dati relativi alla situazione del venduto per il dettaglio cliente
-- --------------------------------------------------------------------------------------------
FUNCTION fu_situaz_venduto_dettaglio RETURN C_SITUAZ_VENDUTO_DETTAGLIO;

-----------------------------------------------------------------------------------------------------------
--
--  Mauro  Viel, Altran, marzo 2010
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_situaz_venduto_prodotto   Estrae i dati relativi alla situazione del venduto del cliente/prodotto
-- --------------------------------------------------------------------------------------------


FUNCTION fu_situaz_venduto_prodotto RETURN C_SITUAZ_VENDUTO_PRODOTTO;
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
function FU_TIPO_CONTRATTO RETURN varchar2;
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_FLG_ARENA
--
-- Output: variabile di package P_FLG_ARENA
--
-- Realizzatore:
--	 Michele Borgogno, Altran, Maggio 2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_FLG_ARENA RETURN varchar2;
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_FLG_ABBINATO
--
-- Output: variabile di package P_FLG_ABBINATO
--
-- Realizzatore:
--	 Michele Borgogno, Altran, Maggio 2010
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_FLG_ABBINATO RETURN varchar2;



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
  no_div_tipo_contratto varchar2 DEFAULT 'N'
  );
  
 

 function FU_GET_ID_PIANO RETURN number;
 function  FU_GET_ID_VER_PIANO RETURN number;
 function fu_sit_vend_dettaglio_prodotto return C_SIT_VEND_DETT_PROD;
 
 FUNCTION fu_situaz_venduto_prodotto_ps RETURN C_SITUAZ_VENDUTO_PRODOTTO;
 FUNCTION fu_sit_ven_prod_no_tip_cont_ps RETURN C_SITUAZ_VENDUTO_PRODOTTO;
 
 FUNCTION fu_sit_prod_settimana_ps RETURN C_SITUAZ_PRODOTTO_SETTIMANA;
 FUNCTION fu_sit_prod_settimana RETURN C_SITUAZ_PRODOTTO_SETTIMANA;
 
 
 FUNCTION fu_sit_vend_prod_no_tipo_contr RETURN C_SITUAZ_VENDUTO_PRODOTTO;
 
 
FUNCTION fu_affollamento RETURN c_affollamento;

function FU_NO_DIV_TIPO_CONTRATTO RETURN varchar2;

FUNCTION fu_affollamento_periodo RETURN c_affollamento;

FUNCTION fu_affollamento_circuito RETURN c_affollamento;

END PA_CD_SITUAZIONE_VENDUTO; 
/

