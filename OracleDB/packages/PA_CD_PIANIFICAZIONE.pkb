CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PIANIFICAZIONE IS
--
--
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE Questo package contiene procedure/funzioni necessarie per la gestione delle pianificazioni
--
-- --------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE Mauro Viel-Simone Bottani, Altran, 2009,
-- --------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_PIANIFICAZIONE
-- --------------------------------------------------------------------------------------------
--
--
--
PROCEDURE PR_TEST IS
V_TEST NUMBER;
BEGIN
    V_TEST:=2;
END;



FUNCTION FU_GET_DATA_PER_IN(P_ID_PERIOD_SPECIALE cd_periodo_speciale.id_periodo_speciale%type, p_id_periodo cd_periodi_cinema.id_periodo%type)return DATE is
V_DATE DATE;
BEGIN
if P_ID_PERIOD_SPECIALE is not null then
    select data_inizio into V_DATE
    from cd_periodo_speciale
    where id_periodo_speciale = P_ID_PERIOD_SPECIALE;
else
    select data_inizio into V_DATE
    from cd_periodi_cinema
    where id_periodo = P_ID_PERIODO;
end if;
return V_DATE;

END FU_GET_DATA_PER_IN;

FUNCTION FU_GET_DATA_PER_FI(P_ID_PERIOD_SPECIALE cd_periodo_speciale.id_periodo_speciale%type, p_id_periodo cd_periodi_cinema.id_periodo%type)return DATE IS
V_DATE DATE;
BEGIN
if P_ID_PERIOD_SPECIALE is not null then
    select data_fine into V_DATE
    from cd_periodo_speciale
    where id_periodo_speciale = P_ID_PERIOD_SPECIALE;
else
    select data_fine into V_DATE
    from cd_periodi_cinema
    where id_periodo = P_ID_PERIODO;
end if;
return V_DATE;
END FU_GET_DATA_PER_FI;



FUNCTION FU_TEST_1 RETURN NUMBER IS
V_TEST NUMBER;
BEGIN
    V_TEST := 42;
    RETURN V_TEST;
END FU_TEST_1;


PROCEDURE PR_COUNT_PIANI(P_ID_PIANO IN CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO IN CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        ESITO OUT NUMBER)IS
BEGIN
  SELECT COUNT (ID_PIANO)
  INTO ESITO
  FROM CD_PIANIFICAZIONE
  WHERE ID_PIANO = P_ID_PIANO
  AND   ID_VER_PIANO = P_ID_VER_PIANO;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END PR_COUNT_PIANI;


FUNCTION FU_CERCA_ASSSOGG(P_ID_PIANO     CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE)
                          RETURN C_ASSSOGG IS
CUR C_ASSSOGG;
BEGIN
  OPEN CUR FOR
  --comunicati
select PRP.DESC_PRODOTTO     AS DESCRIZIONE,
       CIR.NOME_CIRCUITO     AS NOME_CIRCUITO,
       SUM(PAQ.IMP_NETTO)    AS NETTO,
       SUM(PAQ.IMP_LORDO)    AS LORDO,
       MIN(IMP.IMP_SC_COMM) AS PERC_SC,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL) AS FORMATO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       COUNT(BDV.ID_BREAK_VENDITA) AS NUM_COMUNICATI,
       NULL AS NUM_SALE,
       NULL AS NUM_CINEMA,
       NULL AS NUM_ATRII
 from  CD_PRODOTTO_ACQUISTATO PAQ,
       CD_IMPORTI_PRODOTTO IMP,
       CD_COMUNICATO COM,
       CD_FORMATO_ACQUISTABILE FOA,
       CD_PRODOTTO_PUBB PRP,
       CD_MISURA_PRD_VENDITA MIS,
       CD_BREAK_VENDITA   BDV,
       CD_CIRCUITO CIR,
       CD_CIRCUITO_BREAK CBR
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_BREAK_VENDITA = BDV.ID_BREAK_VENDITA
 and   CBR.ID_CIRCUITO_BREAK = BDV.ID_CIRCUITO_BREAK
 and   CBR.ID_CIRCUITO = CIR.ID_CIRCUITO
 and   imp.ID_PRODOTTO_ACQUISTATO = paq.ID_PRODOTTO_ACQUISTATO
 group by
       PAQ.ID_PRODOTTO_ACQUISTATO,
       PRP.DESC_PRODOTTO,
       CIR.NOME_CIRCUITO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL)
UNION
--cinema
select PRP.DESC_PRODOTTO     AS DESCRIZIONE,
       CIR.NOME_CIRCUITO     AS NOME_CIRCUITO,
       SUM(PAQ.IMP_NETTO)    AS NETTO,
       SUM(PAQ.IMP_LORDO)    AS LORDO,
       MIN(imp.IMP_SC_COMM) AS PERC_SC,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL) AS FORMATO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       NULL AS NUM_COMUNICATI,
       NULL AS NUM_SALE,
       COUNT (CCI.ID_CINEMA) AS NUM_CINEMA,
       NULL AS NUM_ATRII
 from  CD_PRODOTTO_ACQUISTATO PAQ,
       CD_COMUNICATO COM,
       CD_FORMATO_ACQUISTABILE FOA,
       CD_PRODOTTO_PUBB PRP,
       CD_MISURA_PRD_VENDITA MIS,
       CD_CINEMA_VENDITA CDV,
       CD_CIRCUITO CIR,
       CD_CIRCUITO_CINEMA CCI,
       cd_importi_prodotto imp
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_CINEMA_VENDITA = CDV.ID_CINEMA_VENDITA
 and   CCI.ID_CIRCUITO_CINEMA = CDV.ID_CIRCUITO_CINEMA
 and   CCI.ID_CIRCUITO = CIR.ID_CIRCUITO
 and   imp.ID_PRODOTTO_ACQUISTATO = paq.ID_PRODOTTO_ACQUISTATO
 group by
       PAQ.ID_PRODOTTO_ACQUISTATO,
       PRP.DESC_PRODOTTO,
       CIR.NOME_CIRCUITO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL)
UNION
--sale
select PRP.DESC_PRODOTTO     AS DESCRIZIONE,
       CIR.NOME_CIRCUITO     AS NOME_CIRCUITO,
       SUM(PAQ.IMP_NETTO)    AS NETTO,
       SUM(PAQ.IMP_LORDO)    AS LORDO,
       MIN(imp.IMP_SC_COMM) AS PERC_SC,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL) AS FORMATO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       NULL AS NUM_COMUNICATI,
       COUNT (CIS.ID_SALA) AS NUM_SALE,
       NULL AS NUM_CINEMA,
       NULL AS NUM_ATRII
 from  CD_PRODOTTO_ACQUISTATO PAQ,
       CD_COMUNICATO COM,
       CD_FORMATO_ACQUISTABILE FOA,
       CD_PRODOTTO_PUBB PRP,
       CD_MISURA_PRD_VENDITA MIS,
       CD_SALA_VENDITA CSV,
       CD_CIRCUITO CIR,
       CD_CIRCUITO_SALA CIS,
       cd_importi_prodotto imp
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_SALA_VENDITA = CSV.ID_SALA_VENDITA
 and   CIS.ID_CIRCUITO_SALA = CSV.ID_CIRCUITO_SALA
 and   CIS.ID_CIRCUITO = CIR.ID_CIRCUITO
 and   paq.ID_PRODOTTO_ACQUISTATO = imp.ID_PRODOTTO_ACQUISTATO
 group by
       PAQ.ID_PRODOTTO_ACQUISTATO,
       PRP.DESC_PRODOTTO,
       CIR.NOME_CIRCUITO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL)
UNION
--atrii
select PRP.DESC_PRODOTTO     AS DESCRIZIONE,
       CIR.NOME_CIRCUITO     AS NOME_CIRCUITO,
       SUM(PAQ.IMP_NETTO)    AS NETTO,
       SUM(PAQ.IMP_LORDO)    AS LORDO,
       MIN(imp.IMP_SC_COMM) AS PERC_SC,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL) AS FORMATO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       NULL AS NUM_COMUNICATI,
       NULL AS NUM_CINEMA,
       NULL AS NUM_SALE,
       COUNT (CAT.ID_ATRIO) AS NUM_ATRII
 from  CD_PRODOTTO_ACQUISTATO PAQ,
       CD_COMUNICATO COM,
       CD_FORMATO_ACQUISTABILE FOA,
       CD_PRODOTTO_PUBB PRP,
       CD_MISURA_PRD_VENDITA MIS,
       CD_ATRIO_VENDITA CAV,
       CD_CIRCUITO CIR,
       CD_CIRCUITO_ATRIO CAT,
       cd_importi_prodotto imp
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_ATRIO_VENDITA = CAV.ID_ATRIO_VENDITA
 and   CAT.ID_CIRCUITO_ATRIO = CAV.ID_CIRCUITO_ATRIO
 and   CAT.ID_CIRCUITO = CIR.ID_CIRCUITO
 and   imp.ID_PRODOTTO_ACQUISTATO = paq.ID_PRODOTTO_ACQUISTATO
 group by
       PAQ.ID_PRODOTTO_ACQUISTATO,
       PRP.DESC_PRODOTTO,
       CIR.NOME_CIRCUITO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL);
  return CUR;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_ASSSOGG;


-- Mauro Viel, Altran, Agosto 2009
-- Modifica Mauro Viel Altran Italia Agosto 2010 sostituita la tavola CD_IMPORTI_RICHIESTI_PIANO con la tavola CD_PRODOTTI_RICHIESTI 
-- in modo da avere il richiesto sul prodotto.
FUNCTION FU_GET_PIANO_FULL(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PIANO_FULL IS
CUR C_PIANO_FULL;
v_lordo_eff NUMBER;
v_netto_eff NUMBER;
v_sconto_eff NUMBER;
v_perc_sconto_eff NUMBER;
BEGIN
   SELECT
   NVL(SUM(CD_PRODOTTO_ACQUISTATO.IMP_LORDO),0),
   NVL(SUM(CD_PRODOTTO_ACQUISTATO.IMP_NETTO),0)
   INTO v_lordo_eff, v_netto_eff
   FROM CD_PRODOTTO_ACQUISTATO,
   CD_PIANIFICAZIONE
   WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
   AND CD_PIANIFICAZIONE.ID_PIANO = CD_PRODOTTO_ACQUISTATO.ID_PIANO
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO
   AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO='N'
   AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO='N'
   AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL;
   --
   SELECT NVL(SUM(imp.IMP_SC_COMM),0)
   INTO v_sconto_eff
   FROM
   CD_PRODOTTO_ACQUISTATO,
   CD_PIANIFICAZIONE,
   cd_importi_prodotto imp
   WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
   AND CD_PIANIFICAZIONE.ID_PIANO = CD_PRODOTTO_ACQUISTATO.ID_PIANO
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO
   AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO='N'
   AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO='N'
   AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
   AND IMP.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO;
--
   SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_eff, v_sconto_eff)
   INTO v_perc_sconto_eff
   FROM DUAL;
--
    OPEN CUR for
    SELECT
        P.id_piano,
        P.id_ver_piano,
        P.cod_sede,
        P.cod_area,
        P.id_cliente,
        IU1.rag_soc_cogn as nome_cliente,
        P.id_responsabile_contatto,
        IU2.rag_soc_cogn as nome_responsabile_contatto,
        P.cod_categoria_prodotto,
        P.data_creazione_richiesta,
        P.data_invio_magazzino,
        P.data_trasformazione_in_piano,
        P.flg_annullato,
        P.flg_sospeso,
        P.utente_invio_richiesta,
        P.utemod,
        P.datamod,
        P.id_stato_lav,
        P.id_target,
--        P.id_soggetto_di_piano,
        P.id_stato_vendita,
        S.descr_breve AS STATO_VENDITA,
        P.flg_cambio_merce,
        P.flg_sipra_lab,
        p.tipo_contratto,
        NVL(SUM(PR.IMP_NETTO),0) as netto_piano,
        NVL(SUM(PR.IMP_LORDO),0) as lordo_piano,
        PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(PR.IMP_NETTO),0), NVL(SUM(PR.IMP_LORDO),0) - NVL(SUM(PR.IMP_NETTO),0)) as perc_sc_piano,
        v_netto_eff as NETTO_EFF,
        v_lordo_eff as LORDO_EFF,
        v_perc_sconto_eff as PERC_SC_EFF,
        get_desc_area(P.COD_AREA) as desc_area,
        get_desc_sedi(P.COD_SEDE) as desc_sede,
        P.DATA_PRENOTAZIONE,
        fu_get_stato_ven_comunicati(P_ID_PIANO, P_ID_VER_PIANO) AS STATO_VENDITA_COMUNICATI,
        P.cod_testata_editoriale,
        p.NOTE
    FROM   CD_PIANIFICAZIONE P,
           --CD_IMPORTI_RICHIESTI_PIANO IP,
           cd_prodotti_richiesti PR,
           INTERL_U IU1,
           INTERL_U IU2,
           CD_STATO_DI_VENDITA S
    WHERE   P.ID_PIANO = P_ID_PIANO
    AND     P.ID_VER_PIANO = P_ID_VER_PIANO
    AND     P.ID_PIANO=PR.ID_PIANO (+)
    AND     P.ID_VER_PIANO=PR.ID_VER_PIANO (+)
    AND     PR.FLG_ANNULLATO(+) = 'N'
    AND     PR.FLG_SOSPESO(+) = 'N'
    AND     P.ID_CLIENTE=IU1.COD_INTERL
    AND     P.ID_RESPONSABILE_CONTATTO=IU2.COD_INTERL
    AND     P.ID_STATO_VENDITA = S.ID_STATO_VENDITA
    GROUP BY         P.id_piano,
                     P.id_ver_piano,
                     P.cod_sede,
                     P.cod_area,
                     P.id_cliente,
                     IU1.rag_soc_cogn,
                     P.id_responsabile_contatto,
                     IU2.rag_soc_cogn,
                     P.cod_categoria_prodotto,
                     P.data_creazione_richiesta,
                     P.data_invio_magazzino,
                     P.data_trasformazione_in_piano,
                     P.flg_annullato,
                     P.flg_sospeso,
                     P.utente_invio_richiesta,
                     P.utemod,
                     P.datamod,
                     P.id_stato_lav,
                     P.id_target,
--                     P.id_soggetto_di_piano,
                     P.id_stato_vendita,
                     S.descr_breve,
                     P.flg_cambio_merce,
                     P.flg_sipra_lab,
                     P.data_prenotazione,
                     P.cod_testata_editoriale,
                     p.NOTE,
                     p.tipo_contratto;

    RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PIANO_FULL;



-- Mauro Viel, Altran, Agosto 2009
/*FUNCTION FU_GET_PIANO_FULL(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PIANO_FULL IS
CUR C_PIANO_FULL;
v_lordo_eff NUMBER;
v_netto_eff NUMBER;
v_sconto_eff NUMBER;
v_perc_sconto_eff NUMBER;
BEGIN
   SELECT
   NVL(SUM(CD_PRODOTTO_ACQUISTATO.IMP_LORDO),0),
   NVL(SUM(CD_PRODOTTO_ACQUISTATO.IMP_NETTO),0)
   INTO v_lordo_eff, v_netto_eff
   FROM CD_PRODOTTO_ACQUISTATO,
   CD_PIANIFICAZIONE
   WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
   AND CD_PIANIFICAZIONE.ID_PIANO = CD_PRODOTTO_ACQUISTATO.ID_PIANO
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO
   AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO='N'
   AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO='N'
   AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL;
   --
   SELECT NVL(SUM(imp.IMP_SC_COMM),0)
   INTO v_sconto_eff
   FROM
   CD_PRODOTTO_ACQUISTATO,
   CD_PIANIFICAZIONE,
   cd_importi_prodotto imp
   WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
   AND CD_PIANIFICAZIONE.ID_PIANO = CD_PRODOTTO_ACQUISTATO.ID_PIANO
   AND CD_PIANIFICAZIONE.ID_VER_PIANO = CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO
   AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO='N'
   AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO='N'
   AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
   AND IMP.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO;
--
   SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_eff, v_sconto_eff)
   INTO v_perc_sconto_eff
   FROM DUAL;
--
    OPEN CUR for
    SELECT
        P.id_piano,
        P.id_ver_piano,
        P.cod_sede,
        P.cod_area,
        P.id_cliente,
        IU1.rag_soc_cogn as nome_cliente,
        P.id_responsabile_contatto,
        IU2.rag_soc_cogn as nome_responsabile_contatto,
        P.cod_categoria_prodotto,
        P.data_creazione_richiesta,
        P.data_invio_magazzino,
        P.data_trasformazione_in_piano,
        P.flg_annullato,
        P.flg_sospeso,
        P.utente_invio_richiesta,
        P.utemod,
        P.datamod,
        P.id_stato_lav,
        P.id_target,
--        P.id_soggetto_di_piano,
        P.id_stato_vendita,
        S.descr_breve AS STATO_VENDITA,
        P.flg_cambio_merce,
        P.flg_sipra_lab,
        NVL(SUM(IP.NETTO),0) as netto_piano,
        NVL(SUM(IP.LORDO),0) as lordo_piano,
        PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(IP.NETTO),0), NVL(SUM(IP.LORDO),0) - NVL(SUM(IP.NETTO),0)) as perc_sc_piano,
        v_netto_eff as NETTO_EFF,
        v_lordo_eff as LORDO_EFF,
        v_perc_sconto_eff as PERC_SC_EFF,
        get_desc_area(P.COD_AREA) as desc_area,
        get_desc_sedi(P.COD_SEDE) as desc_sede,
        P.DATA_PRENOTAZIONE,
        fu_get_stato_ven_comunicati(P_ID_PIANO, P_ID_VER_PIANO) AS STATO_VENDITA_COMUNICATI,
        P.cod_testata_editoriale
    FROM   CD_PIANIFICAZIONE P,
           CD_IMPORTI_RICHIESTI_PIANO IP,
           INTERL_U IU1,
           INTERL_U IU2,
           CD_STATO_DI_VENDITA S
    WHERE   P.ID_PIANO = P_ID_PIANO
    AND     P.ID_VER_PIANO = P_ID_VER_PIANO
    AND     P.ID_PIANO=IP.ID_PIANO (+)
    AND     P.ID_VER_PIANO=IP.ID_VER_PIANO (+)
    AND     IP.FLG_ANNULLATO(+) = 'N'
    AND     P.ID_CLIENTE=IU1.COD_INTERL
    AND     P.ID_RESPONSABILE_CONTATTO=IU2.COD_INTERL
    AND     P.ID_STATO_VENDITA = S.ID_STATO_VENDITA
    GROUP BY         P.id_piano,
                     P.id_ver_piano,
                     P.cod_sede,
                     P.cod_area,
                     P.id_cliente,
                     IU1.rag_soc_cogn,
                     P.id_responsabile_contatto,
                     IU2.rag_soc_cogn,
                     P.cod_categoria_prodotto,
                     P.data_creazione_richiesta,
                     P.data_invio_magazzino,
                     P.data_trasformazione_in_piano,
                     P.flg_annullato,
                     P.flg_sospeso,
                     P.utente_invio_richiesta,
                     P.utemod,
                     P.datamod,
                     P.id_stato_lav,
                     P.id_target,
--                     P.id_soggetto_di_piano,
                     P.id_stato_vendita,
                     S.descr_breve,
                     P.flg_cambio_merce,
                     P.flg_sipra_lab,
                     P.data_prenotazione,
                     P.cod_testata_editoriale;

    RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PIANO_FULL;*/

--Mauro Viel, Altran, Agosto 2009
FUNCTION FU_GET_RICHIESTA_FULL(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_RICHIESTA_FULL IS
CUR C_RICHIESTA_FULL;
BEGIN
    OPEN CUR for
    SELECT
        id_piano,
        id_ver_piano,
        cod_sede,
        cod_area,
        id_cliente,
        id_responsabile_contatto,
        cod_categoria_prodotto,
        data_creazione_richiesta,
        data_invio_magazzino,
        data_trasformazione_in_piano,
        flg_annullato,
        flg_sospeso,
        utente_invio_richiesta,
        utemod,
        datamod,
        id_stato_lav,
        id_target,
        id_stato_vendita,
        flg_cambio_merce,
        flg_sipra_lab,
        netto,
        lordo,
        PA_PC_IMPORTI.FU_PERC_SC_COMM(netto,lordo - netto) as perc_sc,
        desc_area,
        desc_sede,
        note,
        tipo_contratto
        FROM
    (
    SELECT
        P.id_piano,
        P.id_ver_piano,
        P.cod_sede,
        P.cod_area,
        P.id_cliente,
        P.id_responsabile_contatto,
        P.cod_categoria_prodotto,
        P.data_creazione_richiesta,
        P.data_invio_magazzino,
        P.data_trasformazione_in_piano,
        P.flg_annullato,
        P.flg_sospeso,
        P.utente_invio_richiesta,
        P.utemod,
        P.datamod,
        P.id_stato_lav,
        P.id_target,
--        P.id_soggetto_di_piano,
        P.id_stato_vendita,
        P.flg_cambio_merce,
        P.flg_sipra_lab,
        NVL(SUM(IR.NETTO),0) as netto,
        NVL(SUM(IR.LORDO),0) as lordo,
        get_desc_area(P.COD_AREA) as desc_area,
        get_desc_sedi(P.COD_SEDE) as desc_sede,
        p.note,
        p.tipo_contratto
    FROM   CD_PIANIFICAZIONE P,
           CD_IMPORTI_RICHIESTA IR
    WHERE   P.ID_PIANO = P_ID_PIANO
    AND     P.ID_VER_PIANO = P_ID_VER_PIANO
    AND     P.ID_PIANO=IR.ID_PIANO (+)
    AND     P.ID_VER_PIANO=IR.ID_VER_PIANO (+)
    AND     IR.FLG_ANNULLATO(+) = 'N'
    GROUP BY         P.id_piano,
                     P.id_ver_piano,
                     P.cod_sede,
                     P.cod_area,
                     P.id_cliente,
                     P.id_responsabile_contatto,
                     P.cod_categoria_prodotto,
                     P.data_creazione_richiesta,
                     P.data_invio_magazzino,
                     P.data_trasformazione_in_piano,
                     P.flg_annullato,
                     P.flg_sospeso,
                     P.utente_invio_richiesta,
                     P.utemod,
                     P.datamod,
                     P.id_stato_lav,
                     P.id_target,
 --                    P.id_soggetto_di_piano,
                     P.id_stato_vendita,
                     P.flg_cambio_merce,
                     P.flg_sipra_lab,
                     p.note,
                     p.tipo_contratto);

    RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_RICHIESTA_FULL;

PROCEDURE PR_INSERISCI_RICHIESTA(
                                 p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                                 p_data_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
                                 p_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 p_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                 p_stato_vendita CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 p_cod_categoria_prodotto CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_target CD_PIANIFICAZIONE.ID_TARGET%TYPE,
                                 p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                                 p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                                 p_lista_periodi  periodo_list_type,
                                 p_lista_intermediari intermediario_list_type,
                                 p_lista_soggetti soggetto_list_type,
                                 p_lista_formati id_list_type,
                                 p_id_piano OUT CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 p_id_ver_piano OUT CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 p_nota cd_pianificazione.NOTE%TYPE,
                                 p_tipo_contratto cd_pianificazione.TIPO_CONTRATTO%type
                                 ) IS

BEGIN

SAVEPOINT PR_INSERISCI_RICHIESTA;

   INSERT INTO CD_PIANIFICAZIONE(
                                 CD_PIANIFICAZIONE.COD_AREA,
                                 CD_PIANIFICAZIONE.COD_SEDE,
                                 CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA,
                                 CD_PIANIFICAZIONE.ID_CLIENTE,
                                 CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO,
                                 CD_PIANIFICAZIONE.ID_STATO_LAV,
                                 CD_PIANIFICAZIONE.ID_STATO_VENDITA,
                                 CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO,
                                 CD_PIANIFICAZIONE.ID_TARGET,
                                 CD_PIANIFICAZIONE.FLG_SIPRA_LAB,
                                 CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE,
                                 CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE,
                                 CD_PIANIFICAZIONE.NOTE,
                                 CD_PIANIFICAZIONE.TIPO_CONTRATTO
                                 )
                          VALUES(p_cod_area,
                                 p_cod_sede,
                                 p_data_richiesta,
                                 p_cliente,
                                 p_responsabile_contatto,
                                 3,
                                 p_stato_vendita,
                                 p_cod_categoria_prodotto,
                                 p_target,
                                 p_sipra_lab,
                                 p_cambio_merce,
                                 PA_CD_MEZZO.FU_TESTATA_NAZIONALE,
                                 p_nota,
                                 p_tipo_contratto 
                                 );

SELECT CD_PIANIFICAZIONE_SEQ.CURRVAL INTO p_id_piano FROM DUAL;
p_id_ver_piano := 1;
--PR_INSERISCI_IMPORTI_PIANO(p_id_piano, p_id_ver_piano,p_lista_periodi);
PR_INSERISCI_FORMATI(p_id_piano,p_id_ver_piano,p_lista_formati);
PR_INSERISCI_IMPORTI_RICHIESTA(p_id_piano, p_id_ver_piano,p_lista_periodi);
PR_INSERISCI_INTERMEDIARI(p_id_piano, p_id_ver_piano,p_lista_intermediari);
PR_INSERISCI_SOGGETTI(p_id_piano, p_id_ver_piano,p_lista_soggetti);
EXCEPTION
	  WHEN OTHERS THEN
   --   raise;
   RAISE_APPLICATION_ERROR(-20019, 'PROCEDURA PR_INSERISCI_RICHIESTA: ERRORE INATTESO INSERENDO LA RICHIESTA '||SQLERRM);
      ROLLBACK TO PR_INSERISCI_RICHIESTA;
END PR_INSERISCI_RICHIESTA;

PROCEDURE PR_MODIFICA_RICHIESTA(
                                 p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                                 p_data_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
                                 p_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 p_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                 p_stato_vendita CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 p_cod_categoria_prodotto CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_target CD_PIANIFICAZIONE.ID_TARGET%TYPE,
                                 p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                                 p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                                 p_lista_periodi  periodo_list_type,
                                 p_lista_intermediari intermediario_list_type,
                                 p_lista_soggetti soggetto_list_type,
                                 p_lista_formati id_list_type,
                                 p_nota cd_pianificazione.NOTE%TYPE,
                                 p_tipo_contratto cd_pianificazione.TIPO_CONTRATTO%type

) IS
v_num NUMBER;
BEGIN

SAVEPOINT PR_MODIFICA_RICHIESTA;
--
    UPDATE CD_PIANIFICAZIONE SET
    COD_AREA = p_cod_area,
    COD_SEDE = p_cod_sede,
    ID_CLIENTE = p_cliente,
    ID_RESPONSABILE_CONTATTO = p_responsabile_contatto,
    ID_STATO_VENDITA = p_stato_vendita,
    COD_CATEGORIA_PRODOTTO = p_cod_categoria_prodotto,
    ID_TARGET = p_target,
    FLG_SIPRA_LAB = p_sipra_lab,
    FLG_CAMBIO_MERCE = p_cambio_merce,
    NOTE = p_nota,
    TIPO_CONTRATTO = p_tipo_contratto
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano;

PR_INSERISCI_FORMATI(p_id_piano,p_id_ver_piano,p_lista_formati);
PR_INSERISCI_IMPORTI_RICHIESTA(p_id_piano, p_id_ver_piano,p_lista_periodi);
PR_INSERISCI_INTERMEDIARI(p_id_piano, p_id_ver_piano,p_lista_intermediari);
PR_INSERISCI_SOGGETTI(p_id_piano, p_id_ver_piano,p_lista_soggetti);
EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
      ROLLBACK TO PR_MODIFICA_RICHIESTA;
END PR_MODIFICA_RICHIESTA;

PROCEDURE PR_INSERISCI_IMPORTI_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                         p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                         p_lista_periodi  periodo_list_type) IS
v_periodi PERIODO;
v_count NUMBER;
v_trovato BOOLEAN := FALSE;
BEGIN
IF p_lista_periodi.COUNT > 0 THEN
FOR i IN p_lista_periodi.FIRST..p_lista_periodi.LAST LOOP

      SELECT COUNT(1) INTO v_count FROM CD_IMPORTI_RICHIESTA
      WHERE ID_PIANO = p_id_piano
      AND ID_VER_PIANO = p_id_ver_piano
      AND (ANNO is null OR ANNO = p_lista_periodi(i).ANNO)
      AND (CICLO is null  OR CICLO = p_lista_periodi(i).CICLO)
      AND (PER  is null OR PER = p_lista_periodi(i).PER)
      AND (ID_PERIODO_SPECIALE is null OR  ID_PERIODO_SPECIALE = p_lista_periodi(i).ID_PERIODO_SPECIALE)
      AND (ID_PERIODO is null OR  ID_PERIODO = p_lista_periodi(i).ID_PERIODO);

     IF v_count = 0 THEN
     INSERT INTO CD_IMPORTI_RICHIESTA(
                                     ID_PIANO,
                                     ID_VER_PIANO,
                                     LORDO,
                                     NETTO,
                                     PERC_SC,
                                     ANNO,
                                     CICLO,
                                     PER,
                                     ID_PERIODO_SPECIALE,
                                     ID_PERIODO,
                                     NOTA)
    VALUES(p_id_piano,
           p_id_ver_piano,
           p_lista_periodi(i).IMPORTOLORDO,
           p_lista_periodi(i).IMPORTONETTO,
           p_lista_periodi(i).PERCSCONTO,
           p_lista_periodi(i).ANNO,
           p_lista_periodi(i).CICLO,
           p_lista_periodi(i).PER,
           p_lista_periodi(i).ID_PERIODO_SPECIALE,
           p_lista_periodi(i).ID_PERIODO,
           p_lista_periodi(i).NOTA);
 --
      ELSE
      UPDATE CD_IMPORTI_RICHIESTA
      SET LORDO = p_lista_periodi(i).IMPORTOLORDO,
      NETTO = p_lista_periodi(i).IMPORTONETTO,
      PERC_SC = p_lista_periodi(i).PERCSCONTO,
      NOTA = p_lista_periodi(i).NOTA
      WHERE ID_PIANO = p_id_piano
      AND ID_VER_PIANO = p_id_ver_piano
      AND (ANNO is null OR ANNO = p_lista_periodi(i).ANNO)
      AND (CICLO is null  OR CICLO = p_lista_periodi(i).CICLO)
      AND (PER  is null OR PER = p_lista_periodi(i).PER)
      AND (ID_PERIODO_SPECIALE is null OR  ID_PERIODO_SPECIALE = p_lista_periodi(i).ID_PERIODO_SPECIALE)
      AND (ID_PERIODO is null OR  ID_PERIODO = p_lista_periodi(i).ID_PERIODO);
   END IF;
END LOOP;

  FOR TEMP IN(SELECT ANNO,CICLO,PER,ID_PERIODO_SPECIALE, ID_PERIODO
            FROM CD_IMPORTI_RICHIESTA
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano)LOOP
    FOR i IN p_lista_periodi.FIRST..p_lista_periodi.LAST LOOP
        IF  (TEMP.ANNO is null OR TEMP.ANNO = p_lista_periodi(i).ANNO)
            AND (TEMP.CICLO is null OR TEMP.CICLO = p_lista_periodi(i).CICLO)
            AND (TEMP.PER is null OR TEMP.PER = p_lista_periodi(i).PER)
            AND (TEMP.ID_PERIODO_SPECIALE is null OR TEMP.ID_PERIODO_SPECIALE = p_lista_periodi(i).ID_PERIODO_SPECIALE) 
            AND (TEMP.ID_PERIODO is null OR TEMP.ID_PERIODO = p_lista_periodi(i).ID_PERIODO)THEN
--            p_lista_periodi(i).ANNO = TEMP.ANNO
--            AND p_lista_periodi(i).CICLO = TEMP.CICLO
--            AND p_lista_periodi(i).PER = TEMP.PER
--            AND p_lista_periodi(i).ID_PERIODO_SPECIALE = TEMP.ID_PERIODO_SPECIALE THEN
            v_trovato := TRUE;
            EXIT;
        END IF;

    END LOOP;
            IF v_trovato = FALSE THEN
--
            DELETE FROM CD_IMPORTI_RICHIESTA
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano
            AND (ANNO is null OR ANNO = TEMP.ANNO)
            AND (CICLO is null OR CICLO = TEMP.CICLO)
            AND (PER is null OR PER = TEMP.PER)
            AND (ID_PERIODO_SPECIALE is null OR ID_PERIODO_SPECIALE = TEMP.ID_PERIODO_SPECIALE)
            AND (ID_PERIODO is null OR ID_PERIODO = TEMP.ID_PERIODO);
        END IF;
        v_trovato := FALSE;
END LOOP;
END IF;

IF p_lista_periodi.COUNT = 0 THEN
      SELECT COUNT(1) INTO v_count FROM CD_IMPORTI_RICHIESTA
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano;
      IF v_count = 1 THEN
            DELETE FROM CD_IMPORTI_RICHIESTA
                WHERE ID_PIANO = p_id_piano
                AND ID_VER_PIANO = p_id_ver_piano;
      END IF;

END IF;

EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_INSERISCI_IMPORTI_RICHIESTA;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_INSERISCI_IMPORTI_PIANO
--
-- DESCRIZIONE: Inserisce una lista di importi in un piano
--
-- OPERAZIONI:
--   1) Cicla la lista di importi, e la aggiunge al piano
-- INPUT:  Id del piano, id Versione del piano, Lista di importi
-- OUTPUT:
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
--  MODIFICHE:
--

PROCEDURE PR_INSERISCI_IMPORTI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                         p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                         p_lista_periodi  periodo_list_type) IS
v_periodi PERIODO;
v_count NUMBER;
v_trovato BOOLEAN := FALSE;
v_esito NUMBER;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
BEGIN
IF p_lista_periodi IS NOT NULL AND p_lista_periodi.COUNT > 0 THEN
FOR i IN p_lista_periodi.FIRST..p_lista_periodi.LAST LOOP

     SELECT COUNT(1) INTO v_count FROM CD_IMPORTI_RICHIESTI_PIANO
      WHERE ID_PIANO = p_id_piano
      AND ID_VER_PIANO = p_id_ver_piano
      AND (ANNO is null OR ANNO = p_lista_periodi(i).ANNO)
      AND (CICLO is null  OR CICLO = p_lista_periodi(i).CICLO)
      AND (PER  is null OR PER = p_lista_periodi(i).PER)
      AND (ID_PERIODO_SPECIALE is null OR  ID_PERIODO_SPECIALE = p_lista_periodi(i).ID_PERIODO_SPECIALE);
--
     IF v_count = 0 THEN
     INSERT INTO CD_IMPORTI_RICHIESTI_PIANO(
                                     ID_PIANO,
                                     ID_VER_PIANO,
                                     LORDO,
                                     NETTO,
                                     PERC_SC,
                                     ANNO,
                                     CICLO,
                                     PER,
                                     ID_PERIODO_SPECIALE,
                                     NOTA)
    VALUES(p_id_piano,
           p_id_ver_piano,
           p_lista_periodi(i).IMPORTOLORDO,
           p_lista_periodi(i).IMPORTONETTO,
           p_lista_periodi(i).PERCSCONTO,
           p_lista_periodi(i).ANNO,
           p_lista_periodi(i).CICLO,
           p_lista_periodi(i).PER,
           p_lista_periodi(i).ID_PERIODO_SPECIALE,
           p_lista_periodi(i).NOTA);
 --
      ELSE
      UPDATE CD_IMPORTI_RICHIESTI_PIANO
      SET LORDO = p_lista_periodi(i).IMPORTOLORDO,
      NETTO = p_lista_periodi(i).IMPORTONETTO,
      PERC_SC = p_lista_periodi(i).PERCSCONTO,
      NOTA = p_lista_periodi(i).NOTA
      WHERE ID_PIANO = p_id_piano
      AND ID_VER_PIANO = p_id_ver_piano
      AND (ANNO is null OR ANNO = p_lista_periodi(i).ANNO)
      AND (CICLO is null  OR CICLO = p_lista_periodi(i).CICLO)
      AND (PER  is null OR PER = p_lista_periodi(i).PER)
      AND (ID_PERIODO_SPECIALE is null OR  ID_PERIODO_SPECIALE = p_lista_periodi(i).ID_PERIODO_SPECIALE);
   END IF;
   END LOOP;

  FOR TEMP IN(SELECT ANNO,CICLO,PER,ID_PERIODO_SPECIALE
            FROM CD_IMPORTI_RICHIESTI_PIANO
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano)LOOP
    FOR i IN p_lista_periodi.FIRST..p_lista_periodi.LAST LOOP
        IF  (TEMP.ANNO is null OR TEMP.ANNO = p_lista_periodi(i).ANNO)
            AND (TEMP.CICLO is null OR TEMP.CICLO = p_lista_periodi(i).CICLO)
            AND (TEMP.PER is null OR TEMP.PER = p_lista_periodi(i).PER)
            AND (TEMP.ID_PERIODO_SPECIALE is null OR TEMP.ID_PERIODO_SPECIALE = p_lista_periodi(i).ID_PERIODO_SPECIALE) THEN
--            p_lista_periodi(i).ANNO = TEMP.ANNO
--            AND p_lista_periodi(i).CICLO = TEMP.CICLO
--            AND p_lista_periodi(i).PER = TEMP.PER
--            AND p_lista_periodi(i).ID_PERIODO_SPECIALE = TEMP.ID_PERIODO_SPECIALE THEN
            v_trovato := TRUE;
            EXIT;
        END IF;

    END LOOP;
            IF v_trovato = FALSE THEN
--


                DELETE FROM CD_IMPORTI_RICHIESTI_PIANO
                WHERE ID_PIANO = p_id_piano
                AND ID_VER_PIANO = p_id_ver_piano
                AND (ANNO is null OR ANNO = TEMP.ANNO)
                AND (CICLO is null OR CICLO = TEMP.CICLO)
                AND (PER is null OR PER = TEMP.PER)
                AND (ID_PERIODO_SPECIALE is null OR ID_PERIODO_SPECIALE = TEMP.ID_PERIODO_SPECIALE);
 --
                IF TEMP.ANNO IS NOT NULL AND TEMP.CICLO IS NOT NULL AND TEMP.PER IS NOT NULL THEN
                    SELECT DATA_INIZ, DATA_FINE
                    INTO v_data_inizio, v_data_fine
                    FROM PERIODI
                    WHERE ANNO = TEMP.ANNO
                    AND CICLO = TEMP.CICLO
                    AND PER = TEMP.PER;
                ELSIF TEMP.ID_PERIODO_SPECIALE IS NOT NULL THEN
                    SELECT DATA_INIZIO, DATA_FINE
                    INTO v_data_inizio, v_data_fine
                    FROM CD_PERIODO_SPECIALE
                    WHERE ID_PERIODO_SPECIALE = TEMP.ID_PERIODO_SPECIALE;
                END IF;
                FOR PACQ IN (SELECT * FROM CD_PRODOTTO_ACQUISTATO
                             WHERE ID_PIANO = p_id_piano
                             AND ID_VER_PIANO = p_id_ver_piano
                             AND FLG_ANNULLATO = 'N'
                             AND FLG_SOSPESO = 'N'
                             AND COD_DISATTIVAZIONE IS NULL
                             AND DATA_INIZIO BETWEEN v_data_inizio AND v_data_fine)LOOP
                PA_CD_PRODOTTO_ACQUISTATO.PR_ANNULLA_PRODOTTO_ACQUIST(PACQ.ID_PRODOTTO_ACQUISTATO,'MAG',v_esito);
                END LOOP;
                UPDATE CD_PRODOTTI_RICHIESTI
                SET FLG_ANNULLATO = 'S'
                WHERE ID_PIANO = p_id_piano
                AND ID_VER_PIANO = p_id_ver_piano
                AND FLG_ANNULLATO = 'N'
                AND FLG_SOSPESO = 'N'
                AND DATA_INIZIO BETWEEN v_data_inizio AND v_data_fine;
            END IF;
        v_trovato := FALSE;
END LOOP;
 END IF;

IF p_lista_periodi.COUNT = 0 THEN
      SELECT COUNT(1) INTO v_count FROM CD_IMPORTI_RICHIESTI_PIANO
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano;
      IF v_count = 1 THEN
            DELETE FROM CD_IMPORTI_RICHIESTI_PIANO
                WHERE ID_PIANO = p_id_piano
                AND ID_VER_PIANO = p_id_ver_piano;
      END IF;

END IF;

EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_INSERISCI_IMPORTI_PIANO;

PROCEDURE PR_INSERISCI_IMPORTO_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_periodo PERIODO,
                                     p_id_periodo OUT CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE) IS
--
BEGIN
     INSERT INTO CD_IMPORTI_RICHIESTI_PIANO(
                                     ID_PIANO,
                                     ID_VER_PIANO,
                                     LORDO,
                                     NETTO,
                                     PERC_SC,
                                     ANNO,
                                     CICLO,
                                     PER,
                                     ID_PERIODO_SPECIALE,
                                     ID_PERIODO,
                                     NOTA)
        VALUES(p_id_piano,
               p_id_ver_piano,
               p_periodo.IMPORTOLORDO,
               p_periodo.IMPORTONETTO,
               p_periodo.PERCSCONTO,
               p_periodo.ANNO,
               p_periodo.CICLO,
               p_periodo.PER,
               p_periodo.ID_PERIODO_SPECIALE,
               p_periodo.ID_PERIODO,
               p_periodo.NOTA);
     SELECT CD_IMPORTI_RICHIESTI_PIANO_SEQ.CURRVAL INTO p_id_periodo FROM DUAL;
EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_INSERISCI_IMPORTO_PIANO;

PROCEDURE PR_INSERISCI_IMPORTO_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_periodo PERIODO,
                                     p_id_periodo OUT CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE) IS
--
BEGIN
     INSERT INTO CD_IMPORTI_RICHIESTA(
                                     ID_PIANO,
                                     ID_VER_PIANO,
                                     LORDO,
                                     NETTO,
                                     PERC_SC,
                                     ANNO,
                                     CICLO,
                                     PER,
                                     ID_PERIODO_SPECIALE,
                                     ID_PERIODO,
                                     NOTA)
    VALUES(p_id_piano,
           p_id_ver_piano,
           p_periodo.IMPORTOLORDO,
           p_periodo.IMPORTONETTO,
           p_periodo.PERCSCONTO,
           p_periodo.ANNO,
           p_periodo.CICLO,
           p_periodo.PER,
           p_periodo.ID_PERIODO_SPECIALE,
           p_periodo.ID_PERIODO,
           p_periodo.NOTA);
    SELECT CD_IMPORTI_RICHIESTA_SEQ.CURRVAL INTO p_id_periodo FROM DUAL;
END PR_INSERISCI_IMPORTO_RICHIESTA;

PROCEDURE PR_ELIMINA_IMPORTO_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_id_periodo CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE,
                                     p_periodo PERIODO,
                                     p_esito OUT NUMBER) IS
v_num_prodotti NUMBER := 0;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
BEGIN
    p_esito := 1;
    IF p_periodo.ANNO IS NOT NULL AND p_periodo.CICLO IS NOT NULL AND p_periodo.PER IS NOT NULL THEN
        SELECT DATA_INIZ, DATA_FINE
        INTO v_data_inizio, v_data_fine
        FROM PERIODI
        WHERE ANNO = p_periodo.ANNO
        AND CICLO = p_periodo.CICLO
        AND PER = p_periodo.PER;
    ELSIF p_periodo.ID_PERIODO_SPECIALE IS NOT NULL THEN
        SELECT DATA_INIZIO, DATA_FINE
        INTO v_data_inizio, v_data_fine
        FROM CD_PERIODO_SPECIALE
        WHERE ID_PERIODO_SPECIALE = p_periodo.ID_PERIODO_SPECIALE;
    ELSIF p_periodo.ID_PERIODO IS NOT NULL THEN
        SELECT DATA_INIZIO, DATA_FINE
        INTO v_data_inizio, v_data_fine
        FROM CD_PERIODI_CINEMA
        WHERE ID_PERIODO = p_periodo.ID_PERIODO;
    END IF;
    --
    SELECT COUNT(1)
         INTO v_num_prodotti
         FROM CD_PRODOTTO_ACQUISTATO
         WHERE ID_PIANO = p_id_piano
         AND ID_VER_PIANO = p_id_ver_piano
         AND FLG_ANNULLATO = 'N'
         AND FLG_SOSPESO = 'N'
         AND COD_DISATTIVAZIONE IS NULL
         AND ID_IMPORTI_RICHIESTI_PIANO = p_id_periodo;
    --
    IF v_num_prodotti = 0 THEN
        SELECT COUNT(1)
         INTO v_num_prodotti
         FROM CD_PRODOTTI_RICHIESTI
         WHERE ID_PIANO = p_id_piano
         AND ID_VER_PIANO = p_id_ver_piano
         AND FLG_ANNULLATO = 'N'
         AND FLG_SOSPESO = 'N'
         AND ID_IMPORTI_RICHIESTI_PIANO = p_id_periodo;
    END IF;

    IF v_num_prodotti > 0 THEN
        p_esito := -2;
    ELSE
        UPDATE CD_IMPORTI_RICHIESTI_PIANO
        SET FLG_ANNULLATO = 'S'
        WHERE ID_IMPORTI_RICHIESTI_PIANO = p_id_periodo;
        --DELETE FROM CD_IMPORTI_RICHIESTI_PIANO
        --WHERE ID_IMPORTI_RICHIESTI_PIANO = p_id_periodo;
    END IF;
EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_ELIMINA_IMPORTO_PIANO;

PROCEDURE PR_ELIMINA_IMPORTO_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                     p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                     p_id_periodo CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE,
                                     p_periodo PERIODO,
                                     p_esito OUT NUMBER) IS
v_num_prodotti NUMBER := 0;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
BEGIN
    p_esito := 1;
    IF p_periodo.ANNO IS NOT NULL AND p_periodo.CICLO IS NOT NULL AND p_periodo.PER IS NOT NULL THEN
        SELECT DATA_INIZ, DATA_FINE
        INTO v_data_inizio, v_data_fine
        FROM PERIODI
        WHERE ANNO = p_periodo.ANNO
        AND CICLO = p_periodo.CICLO
        AND PER = p_periodo.PER;
    ELSIF p_periodo.ID_PERIODO_SPECIALE IS NOT NULL THEN
        SELECT DATA_INIZIO, DATA_FINE
        INTO v_data_inizio, v_data_fine
        FROM CD_PERIODO_SPECIALE
        WHERE ID_PERIODO_SPECIALE = p_periodo.ID_PERIODO_SPECIALE;
    ELSIF p_periodo.ID_PERIODO IS NOT NULL THEN
        SELECT DATA_INIZIO, DATA_FINE
        INTO v_data_inizio, v_data_fine
        FROM CD_PERIODI_CINEMA
        WHERE ID_PERIODO = p_periodo.ID_PERIODO;
    END IF;
    --
    SELECT COUNT(1)
         INTO v_num_prodotti
         FROM CD_PRODOTTI_RICHIESTI
         WHERE ID_PIANO = p_id_piano
         AND ID_VER_PIANO = p_id_ver_piano
         AND FLG_ANNULLATO = 'N'
         AND FLG_SOSPESO = 'N'
         AND ID_IMPORTI_RICHIESTA = p_id_periodo;

   IF v_num_prodotti > 0 THEN
        p_esito := -2;
   ELSE
        UPDATE CD_IMPORTI_RICHIESTA
        SET FLG_ANNULLATO = 'S'
        WHERE ID_IMPORTI_RICHIESTA = p_id_periodo;
        --DELETE FROM CD_IMPORTI_RICHIESTA
        --WHERE ID_IMPORTI_RICHIESTA = p_id_periodo;
         UPDATE CD_PRODOTTI_RICHIESTI
         SET  ID_IMPORTI_RICHIESTA = NULL
         WHERE ID_PIANO = p_id_piano
         AND ID_VER_PIANO = p_id_ver_piano
         AND ID_IMPORTI_RICHIESTA = p_id_periodo
         AND (FLG_ANNULLATO = 'S' OR FLG_SOSPESO = 'S') ;
        
   END IF;
EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_ELIMINA_IMPORTO_RICHIESTA;

PROCEDURE PR_INSERISCI_INTERMEDIARI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                             p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                             p_lista_intermediari  intermediario_list_type) IS
v_intermediari INTERMEDIARIO;
v_count NUMBER;
v_num_interm NUMBER;
v_trovato BOOLEAN := FALSE;
BEGIN
--
IF p_lista_intermediari IS NOT NULL AND p_lista_intermediari.COUNT > 0 THEN

  FOR i IN p_lista_intermediari.FIRST..p_lista_intermediari.LAST LOOP


    SELECT COUNT(1)
    INTO v_num_interm
    FROM CD_RAGGRUPPAMENTO_INTERMEDIARI
    WHERE ID_PIANO = p_id_piano
    AND  ID_VER_PIANO = p_id_ver_piano
    AND  ID_RAGGRUPPAMENTO = p_lista_intermediari(i).ID_RAGGRUPPAMENTO;
    --AND  p_lista_intermediari(i).ID_VENDITORE_CLIENTE   is null or ID_VENDITORE_CLIENTE = p_lista_intermediari(i).ID_VENDITORE_CLIENTE
    --AND  p_lista_intermediari(i).ID_AGENZIA             is null or ID_AGENZIA =  p_lista_intermediari(i).ID_AGENZIA
    --AND  p_lista_intermediari(i).ID_CENTRO_MEDIA        is null or ID_CENTRO_MEDIA = p_lista_intermediari(i).ID_CENTRO_MEDIA;


    IF v_num_interm = 0 THEN
        INSERT INTO CD_RAGGRUPPAMENTO_INTERMEDIARI(ID_PIANO,
                                                   ID_VER_PIANO,
                                                   ID_VENDITORE_CLIENTE,
                                                   --ID_VENDITORE_PRODOTTO,
                                                   ID_AGENZIA,
                                                   ID_CENTRO_MEDIA,
                                                   DATA_DECORRENZA--,
                                                   --IND_SCONTO_SOST_AGE,
                                                   --PERC_SCONTO_SOST_AGE
                                                   )
        VALUES (p_id_piano,
               p_id_ver_piano,
               p_lista_intermediari(i).ID_VENDITORE_CLIENTE,
               --p_lista_intermediari(i).ID_VENDITORE_PRODOTTO,
               p_lista_intermediari(i).ID_AGENZIA,
               p_lista_intermediari(i).ID_CENTRO_MEDIA,
               p_lista_intermediari(i).DATA_VALIDITA--,
              -- '0',
               --0
               );
         else
         update CD_RAGGRUPPAMENTO_INTERMEDIARI
         set  ID_VENDITORE_CLIENTE = p_lista_intermediari(i).ID_VENDITORE_CLIENTE,
              ID_AGENZIA =  p_lista_intermediari(i).ID_AGENZIA,
              ID_CENTRO_MEDIA = p_lista_intermediari(i).ID_CENTRO_MEDIA,
              DATA_DECORRENZA = p_lista_intermediari(i).DATA_VALIDITA
         where ID_RAGGRUPPAMENTO = p_lista_intermediari(i).ID_RAGGRUPPAMENTO;

         FOR PACQ IN (SELECT PA.ID_PRODOTTO_ACQUISTATO
                      FROM CD_PRODOTTO_ACQUISTATO PA
                      WHERE FLG_ANNULLATO = 'N'
                      AND FLG_SOSPESO = 'N'
                      AND COD_DISATTIVAZIONE IS NULL
                      AND ID_RAGGRUPPAMENTO = p_lista_intermediari(i).ID_RAGGRUPPAMENTO)LOOP
            PA_CD_ORDINE.PR_MODIFICA_ALIQUOTE(p_lista_intermediari(i).ID_RAGGRUPPAMENTO,PACQ.ID_PRODOTTO_ACQUISTATO);
         END LOOP;
    END IF;
  END LOOP;
--

  FOR TEMP IN(SELECT ID_RAGGRUPPAMENTO
            FROM CD_RAGGRUPPAMENTO_INTERMEDIARI
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano)LOOP
    FOR i IN p_lista_intermediari.FIRST..p_lista_intermediari.LAST LOOP
        IF p_lista_intermediari(i).ID_RAGGRUPPAMENTO IS NULL OR p_lista_intermediari(i).ID_RAGGRUPPAMENTO = TEMP.ID_RAGGRUPPAMENTO THEN
            v_trovato := TRUE;
            EXIT;
        END IF;

    END LOOP;
            IF v_trovato = FALSE THEN
                UPDATE CD_PRODOTTO_ACQUISTATO
                SET ID_RAGGRUPPAMENTO = NULL
                WHERE ID_RAGGRUPPAMENTO = TEMP.ID_RAGGRUPPAMENTO
                AND FLG_ANNULLATO = 'S';
    --
                DELETE FROM CD_RAGGRUPPAMENTO_INTERMEDIARI
                WHERE ID_PIANO = p_id_piano
                AND ID_VER_PIANO = p_id_ver_piano
                AND ID_RAGGRUPPAMENTO = TEMP.ID_RAGGRUPPAMENTO;
        END IF;
        v_trovato := FALSE;
END LOOP;

END IF;
EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_INSERISCI_INTERMEDIARI;

PROCEDURE PR_INSERISCI_SOGGETTI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                p_lista_soggetti  soggetto_list_type) IS
v_soggetti SOGGETTO;
v_num_sogg NUMBER;
v_sogg_non_def CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
v_trovato BOOLEAN := FALSE;
BEGIN
IF p_lista_soggetti IS NOT NULL AND p_lista_soggetti.COUNT > 0 THEN
FOR i IN p_lista_soggetti.FIRST..p_lista_soggetti.LAST LOOP

    SELECT COUNT(1)
    INTO v_num_sogg
    FROM CD_SOGGETTO_DI_PIANO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano
    AND DESCRIZIONE = p_lista_soggetti(i).DESCRIZIONE
    AND INT_U_COD_INTERL = p_lista_soggetti(i).INT_U_COD_INTERL;

    IF (v_num_sogg = 0) THEN
        INSERT INTO CD_SOGGETTO_DI_PIANO(ID_PIANO,
                                     ID_VER_PIANO,
                                     DESCRIZIONE,
                                     INT_U_COD_INTERL,
                                     COD_SOGG)
                               VALUES(p_id_piano,
                                      p_id_ver_piano,
                                      p_lista_soggetti(i).DESCRIZIONE,
                                      p_lista_soggetti(i).INT_U_COD_INTERL,
                                      p_lista_soggetti(i).COD_SOGG);
    END IF;
END LOOP;

begin
--Controllo se dei soggetti sono stati eliminati
SELECT ID_SOGGETTO_DI_PIANO
INTO v_sogg_non_def
FROM CD_SOGGETTO_DI_PIANO
WHERE ID_PIANO = p_id_piano
AND ID_VER_PIANO = p_id_ver_piano
AND DESCRIZIONE = 'SOGGETTO NON DEFINITO';
exception
when no_data_found then
v_sogg_non_def :=null;
end;

FOR TEMP IN(SELECT *
            FROM CD_SOGGETTO_DI_PIANO
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano)LOOP
    FOR i IN p_lista_soggetti.FIRST..p_lista_soggetti.LAST LOOP
        IF p_lista_soggetti(i).DESCRIZIONE = TEMP.DESCRIZIONE THEN
            v_trovato := TRUE;
            EXIT;
        END IF;

    END LOOP;
            IF v_trovato = FALSE THEN
            UPDATE CD_COMUNICATO
            SET ID_SOGGETTO_DI_PIANO = v_sogg_non_def
            WHERE ID_PRODOTTO_ACQUISTATO IN
            (SELECT ID_PRODOTTO_ACQUISTATO
             FROM CD_PRODOTTO_ACQUISTATO
             WHERE ID_PIANO = p_id_piano
             AND ID_VER_PIANO = p_id_ver_piano)
            AND ID_SOGGETTO_DI_PIANO = TEMP.ID_SOGGETTO_DI_PIANO;
--
            DELETE FROM CD_SOGGETTO_DI_PIANO
            WHERE ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano
            AND DESCRIZIONE = TEMP.DESCRIZIONE
            AND INT_U_COD_INTERL = TEMP.INT_U_COD_INTERL;
        END IF;
        v_trovato := FALSE;
END LOOP;

END IF;
END PR_INSERISCI_SOGGETTI;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_INSERISCI_FORMATI
--
-- DESCRIZIONE: Inserisce i formati associati ad un piano
--
-- OPERAZIONI:
--   1) Cicla la lista di formati e la aggiunge al piano
-- INPUT:  Id del piano, id Versione del piano, Lista di formati
-- OUTPUT:
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
--  MODIFICHE:
--
PROCEDURE PR_INSERISCI_FORMATI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                               p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                               p_lista_formati  id_list_type) IS
--
v_num_formati NUMBER;
BEGIN
IF p_lista_formati.COUNT > 0 THEN
    --DELETE FROM CD_FORMATI_PIANO
    --WHERE CD_FORMATI_PIANO.ID_PIANO = p_id_piano
    --AND CD_FORMATI_PIANO.ID_VER_PIANO = p_id_ver_piano;
    FOR i IN p_lista_formati.FIRST..p_lista_formati.LAST LOOP
        SELECT COUNT(1)
        INTO v_num_formati
        FROM CD_FORMATI_PIANO
        WHERE ID_PIANO = p_id_piano
        AND ID_VER_PIANO = p_id_ver_piano
        AND ID_FORMATO = p_lista_formati(i);
        IF v_num_formati = 0 THEN
            INSERT INTO CD_FORMATI_PIANO(ID_PIANO,
                                         ID_VER_PIANO,
                                         ID_FORMATO)
                                       VALUES(p_id_piano,
                                              p_id_ver_piano,
                                              p_lista_formati(i));
        END IF;
    END LOOP;
END IF;

END PR_INSERISCI_FORMATI;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_ELIMINA_FORMATI
--
-- DESCRIZIONE: Elimina i formati associati ad un piano
--
-- INPUT:  Id del piano, id Versione del piano, id del formato di piano
-- OUTPUT:
--
-- REALIZZATORE  Michele Borgogno, Altran, Gennaio 2010
--
--  MODIFICHE:
--
PROCEDURE PR_ELIMINA_FORMATI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                            p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                            p_id_formato  CD_FORMATI_PIANO.ID_FORMATO%TYPE) IS
--
BEGIN

    DELETE FROM CD_FORMATI_PIANO
        WHERE ID_PIANO = p_id_piano
        AND ID_VER_PIANO = p_id_ver_piano
        AND ID_FORMATO = p_id_formato;

END PR_ELIMINA_FORMATI_PIANO;
--
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CANCELLA_PIANIFICAZIONE
-- --------------------------------------------------------------------------------------------
--Modifiche Mauro Viel Altran Genanio 2011 ineserita la "UPDATE CD_PRODOTTO_ACQUISTATO 
--                                                       SET FLG_SOSPESO = 'N'"
--
PROCEDURE PR_ANNULLA_RIPRISTINA_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                      P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                      V_FLAG char) IS
v_esito NUMBER;
BEGIN
  IF v_flag = 'S' THEN
       --necessaria perche la PA_CD_PRODOTTO_ACQUISTATO.PR_ANNULLA_PRODOTTO_ACQUIS tratti il dato
       
       UPDATE CD_PRODOTTO_ACQUISTATO
       SET FLG_SOSPESO = 'N'
       WHERE ID_PIANO = p_id_piano
       AND ID_VER_PIANO = p_id_ver_piano 
       AND FLG_SOSPESO = 'S';
       
       FOR PACQ IN (SELECT * FROM CD_PRODOTTO_ACQUISTATO
                     WHERE ID_PIANO = p_id_piano
                     AND ID_VER_PIANO = p_id_ver_piano
                     AND FLG_ANNULLATO = 'N'
                     AND FLG_SOSPESO = 'N'
                     AND COD_DISATTIVAZIONE IS NULL)
       LOOP
           UPDATE CD_COMUNICATO
           SET FLG_SOSPESO = 'N'
           WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO;
           
           PA_CD_PRODOTTO_ACQUISTATO.PR_ANNULLA_PRODOTTO_ACQUIST(PACQ.ID_PRODOTTO_ACQUISTATO,'MAG',v_esito);
           
           UPDATE CD_PRODOTTO_ACQUISTATO
           SET FLG_SOSPESO = 'S'
           WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO;
           
           UPDATE CD_COMUNICATO
           SET FLG_SOSPESO = 'S'
           WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO;
           
        END LOOP;
        --
       FOR PRIC IN (SELECT * FROM CD_PRODOTTI_RICHIESTI
                     WHERE ID_PIANO = p_id_piano
                     AND ID_VER_PIANO = p_id_ver_piano
                     AND FLG_ANNULLATO = 'N'
                     AND FLG_SOSPESO = 'N')LOOP
            PA_CD_PRODOTTO_RICHIESTO.PR_ANNULLA_PRODOTTO_RICHIESTO(PRIC.ID_PRODOTTI_RICHIESTI);
        END LOOP;        
  ELSE
       FOR PACQ IN (SELECT * FROM CD_PRODOTTO_ACQUISTATO
                     WHERE ID_PIANO = p_id_piano
                     AND ID_VER_PIANO = p_id_ver_piano
                     AND FLG_ANNULLATO = 'N'
                     AND FLG_SOSPESO = 'S'
                     AND COD_DISATTIVAZIONE IS NULL)
        LOOP
                     UPDATE CD_PRODOTTO_ACQUISTATO
                     SET FLG_SOSPESO = 'N'
                     WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO;
                     
                     ---PA_CD_PRODOTTO_ACQUISTATO.PR_RECUPERA_PRODOTTO_ACQUIST(PACQ.ID_PRODOTTO_ACQUISTATO,'MAG',v_esito);
                     UPDATE CD_COMUNICATO
                     SET FLG_SOSPESO = 'N'
                     WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO;
        END LOOP;  
        --
       FOR PRIC IN (SELECT * FROM CD_PRODOTTI_RICHIESTI
                     WHERE ID_PIANO = p_id_piano
                     AND ID_VER_PIANO = p_id_ver_piano
                     AND FLG_ANNULLATO = 'N'
                     AND FLG_SOSPESO = 'N')LOOP
            PA_CD_PRODOTTO_RICHIESTO.PR_RIPRISTINA_PRODOTTO_RIC(PRIC.ID_PRODOTTI_RICHIESTI);
         END LOOP;
         
         
           update cd_pianificazione
           set flg_sospeso='N' --,
           where id_piano = p_id_piano
           and   id_ver_piano = p_id_ver_piano;
  END IF;
  
  
  
  update cd_pianificazione
  set flg_annullato=v_flag --,
  where id_piano = p_id_piano
  and   id_ver_piano = p_id_ver_piano;
  --
  /*update cd_prodotto_acquistato
  set flg_annullato=v_flag --,
  where id_piano = p_id_piano
  and   id_ver_piano = p_id_ver_piano;

  update cd_prodotti_richiesti
  set flg_annullato=v_flag
  where id_piano = p_id_piano
  and id_ver_piano = p_id_ver_piano;

  update cd_comunicato
  set flg_annullato =v_flag
  where id_prodotto_acquistato IN
  (     select id_prodotto_acquistato from
        cd_prodotto_acquistato
        where id_PIANO =p_id_piano
        and id_ver_piano =p_id_ver_piano
   );*/

EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END  PR_ANNULLA_RIPRISTINA_PIANO ;
--

-----------------------------------------------------------------------------------------------------
-- Function  FU_CERCA_PIANIFICAZIONE
--
-- DESCRIZIONE:  Ricerca una richiesta secondo i parametri specificati
--
--
--
-- REALIZZATORE: Mauro Viel, Altran, 2009
-- Modifiche Mauro Viel Altran Ottobre 2010 (MVOTT#1) inserito il nuovo stato di lavorazione 6 Richiesta con piani annullati
--
-------------------------------------------------------------------------------------------------


FUNCTION FU_CERCA_RICHIESTA(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
--                                 P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                 --P_INVIATA_MAGAZZINO CHAR,
                                 P_ID_STATO_VENDITA CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
                                 P_COD_CATEGORIA_PRODOTTO CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                                 ) RETURN  C_PIANIFICAZIONE IS
--V_ROW CD_PIANIFICAZIONE%ROWTYPE;
CUR C_PIANIFICAZIONE;
BEGIN
    OPEN CUR for
    --SELECT id_piano,id_ver_piano,get_desc_are(cod_area),get_desc_responsabile(id_responsabile_contatto),id_cliente_fruitore,importo_netto,importo_lordo,a_data_creazione
    --SELECT A.id_piano,A.id_ver_piano,GET_DESC_AREA(cod_area) as cod_area,get_desc_responsabile(id_responsabile_contatto) as id_responsabile_contatto,get_desc_cliente(id_cliente_fruitore)as id_cliente_fruitore,netto,lordo,perc_sc,data_creazione_richiesta
    SELECT PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           GET_DESC_AREA(PIA.cod_area) as cod_area,
           get_desc_responsabile(id_responsabile_contatto) as id_responsabile_contatto,
           get_desc_cliente(id_cliente)as id_cliente_fruitore,
           sum(nvl(netto,0)) as netto ,
           sum(nvl(lordo,0)) as lordo,
           min(nvl(perc_sc,0)) as perc_sc ,
           to_char(data_creazione_richiesta,'DD/MM/YYYY') as data_creazione_richiesta,
           --nvl(to_char(min (per.data_iniz),'DD/MM/YYYY'),'-') as periodo_inizio,
           --nvl(to_char(max(per.data_fine),'DD/MM/YYYY'),'-') as periodo_fine,
           to_char(least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_inizio,
           to_char(greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_fine,
           PIA.id_stato_lav,
           PIA.cod_categoria_prodotto
    FROM CD_PIANIFICAZIONE PIA,
         CD_IMPORTI_RICHIESTA IMP,
         periodi PER,
         VI_CD_AREE_SEDI_COMPET ARSE
    WHERE (P_ID_PIANO is null or PIA.ID_PIANO =P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIA.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_ID_CLIENTE is null or PIA.ID_CLIENTE  = P_ID_CLIENTE)
    AND   (P_COD_AREA IS NULL OR PIA.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIA.COD_SEDE = P_COD_SEDE)
    AND   (P_COD_CATEGORIA_PRODOTTO IS NULL OR PIA.COD_CATEGORIA_PRODOTTO = P_COD_CATEGORIA_PRODOTTO)
    AND   ((P_ID_STATO_LAV IN (3,4) and PIA.ID_STATO_LAV  = P_ID_STATO_LAV)
             OR (P_ID_STATO_LAV = 5 and PIA.ID_STATO_LAV  IN (1,2,5)) OR (P_ID_STATO_LAV = 6  and PIA.ID_STATO_LAV  IN (1,2))) --MVOTT#1
    AND   (P_RESP_CONTATTO IS NULL OR PIA.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO)
    AND   (IMP.ID_PIANO  (+)= PIA.ID_PIANO)
    AND   (IMP.ID_VER_PIANO (+) = PIA.ID_VER_PIANO)
    AND IMP.FLG_ANNULLATO (+) = 'N'
   -- AND   (PIA.DATA_INVIO_MAGAZZINO IS NULL)
   -- AND  (PIA.DATA_TRASFORMAZIONE_IN_PIANO IS NULL)
    AND   (PIA.FLG_SOSPESO   =  decode(P_ID_STATO_LAV,6,'S','N')) --MVOTT#1
    AND   (PIA.FLG_ANNULLATO =  decode(P_ID_STATO_LAV,6,'S','N'))--MVOTT#1 
    AND PER.ANNO (+)= IMP.ANNO
    AND PER.CICLO (+)= IMP.CICLO
    AND PER.PER (+)= IMP.PER
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S')  = 'S'
    group by PIA.id_piano,
             PIA.id_ver_piano,
             PIA.cod_area,
             id_responsabile_contatto,
             id_cliente,
             data_creazione_richiesta,
             PIA.ID_STATO_LAV,
             PIA.cod_categoria_prodotto
             --imp.id_periodo_speciale
    order by PIA.id_piano DESC;
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_RICHIESTA;
--
--
--
--
--
function get_desc_sedi(p_cod_sede sedi.cod_sede%type) return sedi.DESCRIZIONE_ESTESA%type is
V_DESCRIZIONE_ESTESA sedi.DESCRIZIONE_ESTESA%type;
begin
select DESCRIZIONE_ESTESA into V_DESCRIZIONE_ESTESA
from sedi
where cod_sede =p_cod_sede;
return V_DESCRIZIONE_ESTESA;
end;
--
--
function get_desc_area(p_cod_area aree.cod_area%type) return aree.DESCRIZIONE_ESTESA%type is
V_DESCRIZIONE_ESTESA aree.DESCRIZIONE_ESTESA%type;
begin
select DESCRIZIONE_ESTESA into V_DESCRIZIONE_ESTESA
from aree
where cod_area = p_cod_area;
return V_DESCRIZIONE_ESTESA;
end;
--
function get_desc_cliente(p_id_cliente VI_CD_cliente.ID_CLIENTE%type) return VI_CD_CLIENTE.RAG_SOC_COGN%type is
V_RAG_SOC_COGN VI_CD_CLIENTE.RAG_SOC_COGN%type;
begin
select RAG_SOC_COGN into V_RAG_SOC_COGN
from VI_CD_CLIENTE
where id_cliente  = p_id_cliente;
return V_RAG_SOC_COGN;
end;
--
--
function get_desc_responsabile(p_id_responsabile_contatto interl_u.cod_interl%type) return VI_CD_CLIENTE.RAG_SOC_COGN%type is
V_RAG_SOC_COGN interl_u.RAG_SOC_COGN%type;
begin
select RAG_SOC_COGN into V_RAG_SOC_COGN
from interl_u
where cod_interl  = p_id_responsabile_contatto;
return V_RAG_SOC_COGN;
end;
--
--
function fu_get_tipo_committente  return C_INTERMEDIARIO is
Cur C_INTERMEDIARIO;
begin
OPEN CUR for
select
ID_tipo_committente,
RAG_SOC_COGN ,
INDIRIZZO ,
LOCALITA ,
COD_FISC ,
area,
get_desc_area(AREA) as DESC_AREA ,
sede,
get_desc_sedi(SEDE) as DESC_SEDE,
NULL AS dt_iniz_val,
NULL AS dt_fine_val
from vi_cd_tipo_committente;
return cur;
end;
--
--
--Modifiche MV 20/12/2010 in serita VI_CD_AREE_SEDI_COMPET al posto di aree

function fu_get_responsabile_contatto(P_data_creazione_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE)  return C_RESPONSABILE_CONTATTO is
v_responsabili C_RESPONSABILE_CONTATTO;
BEGIN
OPEN v_responsabili for
--select distinct ve.cod_interl cod_vend, ve.ragsoc rag_soc, vg.GV_AS_AR_COD_AREA cod_area, vg.gv_as_se_cod_sede cod_sede, ar.descriz area, se.des_sede sede
select distinct ve.cod_interl cod_vend, ve.ragsoc rag_soc, vg.GV_AS_AR_COD_AREA cod_area, vg.gv_as_se_cod_sede cod_sede, ar.des_area area, se.des_sede sede
from sedi se, venditori ve, vendgr vg, VI_CD_AREE_SEDI_COMPET ar --aree ar--V_RT_AREE_COMPET ar
where /* filtro: (1) venditori appartenenti alle aree di competenza dell'utente di sessione */
vg.gv_as_ar_cod_area = ar.cod_area
and /* .. e (2) validi alla data di creazione del piano ( data chiusura venditore di gruppo posteriore alla data di creazione piano ) */
nvl( vg.data_app_fine, P_data_creazione_richiesta ) >= P_data_creazione_richiesta
and /* join con tabella venditori: */
vg.ve_tipo_vend = ve.tipo_vend
and vg.ve_cod_vend = ve.cod_vend
and /* .. (3) considera i venditori non annullati, .. */
nvl( ve.flag_ann, 'N' ) != 'S'
and /* .. (4) considera i venditori validi ( data chiusura venditore posteriore alla data di creazione piano ) */
nvl( ve.dt_fine_val, P_data_creazione_richiesta ) >= P_data_creazione_richiesta
and /* join con sede: descrizione sede */ se.cod_sede = vg.gv_as_se_cod_sede
order by ve.ragsoc;
return v_responsabili;
end;
--
---RESTITUISCE L'ELENCO DELLE AREE-
--
/*FUNCTION FU_GET_AREA RETURN C_SCELTA_AREA IS
    c_area C_SCELTA_AREA;
    BEGIN
    OPEN c_area FOR
   SELECT COD_AREA,DESCRIZ,DES_ABBR FROM AREE;
    RETURN c_AREA;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_GET_AREA;*/

  FUNCTION FU_GET_AREA RETURN C_SCELTA_AREA IS
    c_area C_SCELTA_AREA;
    BEGIN
    OPEN c_area FOR
    SELECT COD_AREA,DESCRIZ,DES_ABBR FROM VI_CD_AREE_COMPET order by data_a_valid desc, descriz;--AREE;
    RETURN c_AREA;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_GET_AREA;
--
--
/*FUNCTION FU_GET_SEDE RETURN C_SCELTA_SEDE IS
    C_SEDE C_SCELTA_SEDE;
    BEGIN
    OPEN C_SEDE FOR
    SELECT COD_SEDE,DES_SEDE,DES_ABBR FROM SEDI;
    RETURN C_SEDE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_GET_SEDE;*/

  FUNCTION FU_GET_SEDE RETURN C_SCELTA_SEDE IS
    C_SEDE C_SCELTA_SEDE;
    BEGIN
    OPEN C_SEDE FOR
    SELECT COD_SEDE, DES_SEDE_ESTESA AS DES_SEDE, DES_ABBR_SEDE  FROM VI_CD_AREE_SEDI_COMPET;
    RETURN C_SEDE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_GET_SEDE;
--
  FUNCTION FU_GET_SOGGETTO(p_id_cliente VI_CD_CLIENTE.ID_CLIENTE%type)  RETURN C_SOGGETTO is
    C_SOGG C_SOGGETTO;
    BEGIN
    OPEN C_SOGG FOR
       select null, int_u_cod_interl AS COD_INTERL,des_sogg, nielscat.DES_CAT_MERC, nielscl.DES_CL_MERC, soggetti.COD_SOGG
        from nielscat, nielscl,
        soggetti
         where int_u_cod_interl = p_id_cliente
         and nl_cod_cl_merc = nielscl.COD_CL_MERC
         and nl_nt_cod_cat_merc = nielscat.cod_cat_merc
         and nielscl.NT_COD_CAT_MERC = nielscat.COD_CAT_MERC
         and des_sogg != 'SOGGETTO NON DEFINITO'
         and soggetti.FLAG_ANN = 'N'
         union
         select null, int_u_cod_interl AS COD_INTERL,des_sogg, NULL, NULL, soggetti.COD_SOGG
        from
        soggetti
         where int_u_cod_interl = p_id_cliente
         and (nl_cod_cl_merc is null OR nl_nt_cod_cat_merc IS NULL)
        and des_sogg != 'SOGGETTO NON DEFINITO'
        and soggetti.FLAG_ANN = 'N';
    RETURN C_SOGG;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_GET_SOGGETTO;

  FUNCTION FU_GET_SOGGETTO_NON_DEF(p_id_cliente VI_CD_CLIENTE.ID_CLIENTE%type)  RETURN R_SOGGETTO is
    R_SOGG R_SOGGETTO;
    BEGIN
       select null, int_u_cod_interl AS COD_INTERL,des_sogg, nielscat.DES_CAT_MERC, nielscl.DES_CL_MERC, soggetti.COD_SOGG
        into R_SOGG
        from nielscat, nielscl,
        soggetti
         where int_u_cod_interl = p_id_cliente
         and nl_cod_cl_merc = nielscl.COD_CL_MERC
         and nl_nt_cod_cat_merc = nielscat.cod_cat_merc
         and nielscl.NT_COD_CAT_MERC = nielscat.COD_CAT_MERC
         and des_sogg = 'SOGGETTO NON DEFINITO'
         and soggetti.FLAG_ANN = 'N'
         union
         select null, int_u_cod_interl AS COD_INTERL,des_sogg, NULL, NULL, soggetti.COD_SOGG
        from
        soggetti
         where int_u_cod_interl = p_id_cliente
         and (nl_cod_cl_merc is null OR nl_nt_cod_cat_merc IS NULL)
        and des_sogg = 'SOGGETTO NON DEFINITO'
        and soggetti.FLAG_ANN = 'N';
    RETURN R_SOGG;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_GET_SOGGETTO_NON_DEF;
--
PROCEDURE PR_SOSPENDI_RIPRISTINA
                            (
                            P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                            P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                            P_OP VARCHAR2
                            ) IS
v_flag  char(1):='N';
BEGIN
    if p_op ='SOSPENDI' then
        v_flag := 'S';
    end if;

    if v_flag = 'N' then
        update  cd_prodotto_acquistato pa
        set pa.flg_sospeso = v_flag
        where pa.id_piano     = p_id_piano
        and   pa.id_ver_piano = p_id_ver_piano
        and pa.flg_annullato = 'N'
        and pa.cod_disattivazione is null
        and exists (select * from cd_comunicato c where
                   c.id_prodotto_acquistato = pa.id_prodotto_acquistato
                   and trunc(c.data_erogazione_prev) >= trunc(sysdate));

        update  cd_comunicato
        set flg_sospeso =v_flag
        where flg_annullato = 'N'
        and cod_disattivazione is null
        and id_prodotto_acquistato in (select id_prodotto_acquistato
                                         from cd_prodotto_acquistato
                                         where id_piano     = p_id_piano
                                         and   id_ver_piano = p_id_ver_piano
                                         and   flg_annullato = 'N'
                                         and   cod_disattivazione is null)
        and  trunc(data_erogazione_prev) >= trunc(sysdate);
        
        for prod in
        (
            select id_prodotto_acquistato
            from cd_prodotto_acquistato pa
            where pa.id_piano     = p_id_piano
            and   pa.id_ver_piano = p_id_ver_piano
            and pa.flg_annullato = 'N'
            and pa.cod_disattivazione is null
            and exists (select * from cd_comunicato c where
                       c.id_prodotto_acquistato = pa.id_prodotto_acquistato
                       and trunc(c.data_erogazione_prev) >= trunc(sysdate))
        )
        LOOP
            pa_cd_prodotto_acquistato.PR_AGGIORNA_SINTESI_PRODOTTO(prod.id_prodotto_acquistato);
        END LOOP;    
    else
        update  cd_prodotto_acquistato pa
        set pa.flg_sospeso = v_flag
        where pa.id_piano     = p_id_piano
        and   pa.id_ver_piano = p_id_ver_piano
        and pa.flg_annullato = 'N'
        and pa.cod_disattivazione is null;

       update  cd_comunicato
        set flg_sospeso =v_flag
        where flg_annullato = 'N'
        and cod_disattivazione is null
        and id_prodotto_acquistato in (select id_prodotto_acquistato
                                         from cd_prodotto_acquistato
                                         where id_piano     = p_id_piano
                                         and   id_ver_piano = p_id_ver_piano
                                         and   flg_annullato = 'N'
                                         and cod_disattivazione is null);
                                         
        for prod in
        (
             select id_prodotto_acquistato
             from cd_prodotto_acquistato
             where id_piano     = p_id_piano
             and   id_ver_piano = p_id_ver_piano
             and   flg_annullato = 'N'
             and cod_disattivazione is null
        )
        LOOP
            pa_cd_prodotto_acquistato.PR_AGGIORNA_SINTESI_PRODOTTO(prod.id_prodotto_acquistato);
        END LOOP;                                             
                                               
    end if;


    update cd_pianificazione
    set flg_sospeso = v_flag
    where id_piano     = p_id_piano
    and   id_ver_piano = p_id_ver_piano;
    
   

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END  PR_SOSPENDI_RIPRISTINA;



--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_IMPORTI_RICHIESTA
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un importo richiesta dal sistema
--
-- OPERAZIONI:
--   3) Elimina l'importo richiesta
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Mauro Viel Altran, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_IMPORTI_RICHIESTA(  p_id_importi_richiesta		IN CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE,
									  p_esito		            	    OUT NUMBER)
IS
--
--
--
BEGIN -- PR_ELIMINA_IMPORTI_RICHIESTA
--
--
p_esito 	:= 1;
--
--
  		SAVEPOINT ann_del;
--
	   -- EFFETTUA L'eliminazione
	   UPDATE CD_IMPORTI_RICHIESTA
       SET FLG_ANNULLATO = 'S'
	   WHERE ID_IMPORTI_RICHIESTA = p_id_importi_richiesta;
       --DELETE FROM CD_IMPORTI_RICHIESTA
	   --WHERE ID_IMPORTI_RICHIESTA = p_id_importi_richiesta;
    --
--
	p_esito := SQL%ROWCOUNT;

  EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20018, 'PROCEDURA PR_ELIMINA_IMPORTI_RICHIESTA: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI');
		ROLLBACK TO ann_del;

END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_IMPORTI_RICHIESTA
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Mauro Viel Altran, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_STAMPA_IMPORTI_RICHIESTA(   p_id_ver_piano                  CD_IMPORTI_RICHIESTA.ID_VER_PIANO%TYPE,
                                        p_id_piano                      CD_IMPORTI_RICHIESTA.ID_PIANO%TYPE,
                                        p_id_periodo_speciale           CD_IMPORTI_RICHIESTA.ID_PERIODO_SPECIALE%TYPE,
                                        p_id_periodo                    CD_IMPORTI_RICHIESTA.ID_PERIODO%TYPE,
                                        p_lordo                         CD_IMPORTI_RICHIESTA.LORDO%TYPE,
                                        p_netto                         CD_IMPORTI_RICHIESTA.NETTO%TYPE,
                                        p_perc_sc                       CD_IMPORTI_RICHIESTA.PERC_SC%TYPE,
                                        p_anno                          CD_IMPORTI_RICHIESTA.ANNO%TYPE,
    			   			            p_ciclo                         CD_IMPORTI_RICHIESTA.CICLO%TYPE,
    			   			            p_per                           CD_IMPORTI_RICHIESTA.PER%TYPE) RETURN VARCHAR2
IS

BEGIN

IF v_stampa_importi_richiesta = 'ON'

    THEN

     RETURN 'ID_VER_PIANO: '          || p_id_ver_piano          || ', ' ||
            'ID_PIANO: '          || p_id_piano            || ', ' ||
            'ID_PERIODO_SPECIALE: '|| p_id_periodo_speciale   || ', ' ||
            'ID_PERIODO: '  || p_id_periodo       || ', ' ||
            'LORDO: ' || p_lordo       || ', ' ||
            'NETTO: '          || p_netto               || ', ' ||
            'PERC_SC: '          || p_perc_sc                   || ', ' ||
            'ANNO: '      || p_anno         || ', '||
            'CICLO: '      || p_ciclo        || ', '||
            'PER: '      || p_per ;

END IF;

END  FU_STAMPA_IMPORTI_RICHIESTA;


-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_PRODOTTO_VENDITA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo importo richiesta piano nel sistema
--
-- OPERAZIONI:
--   1) Memorizza l'importo richiesta piano (CD_IMP_RICH_PIANO)
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Mauro Viel Altran, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_IMP_RICH_PIANO(  p_id_ver_piano                  CD_IMPORTI_RICHIESTI_PIANO.ID_VER_PIANO%TYPE,
                                        p_id_piano                      CD_IMPORTI_RICHIESTI_PIANO.ID_PIANO%TYPE,
                                        p_id_periodo_speciale           CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO_SPECIALE%TYPE,
                                        p_id_periodo                    CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO%TYPE,
                                        p_lordo                         CD_IMPORTI_RICHIESTI_PIANO.LORDO%TYPE,
                                        p_netto                         CD_IMPORTI_RICHIESTI_PIANO.NETTO%TYPE,
                                        p_perc_sc                       CD_IMPORTI_RICHIESTI_PIANO.PERC_SC%TYPE,
                                        p_anno                          CD_IMPORTI_RICHIESTI_PIANO.ANNO%TYPE,
							   			p_ciclo                         CD_IMPORTI_RICHIESTI_PIANO.CICLO%TYPE,
							   			p_per                           CD_IMPORTI_RICHIESTI_PIANO.PER%TYPE,
							   			p_esito							OUT NUMBER)
IS

BEGIN -- PR_INSERISCI_IMP_RICH_PIANO
--

p_esito 	:= 1;
--P_IMP_RICH_PIANO := IMP_RICH_PIANO_SEQ.NEXTVAL;

	 --
  		SAVEPOINT ann_ins;
  	--
       -- effettuo l'INSERIMENTO
	   INSERT INTO CD_IMPORTI_RICHIESTI_PIANO
	     ( ID_VER_PIANO,
           ID_PIANO,
           ID_PERIODO_SPECIALE,
           ID_PERIODO,
           LORDO,
           NETTO,
           PERC_SC,
           ANNO,
		   CICLO,
		   PER--,
	      --UTEMOD,
	      --DATAMOD
	     )
	   VALUES
	     ( p_id_ver_piano,
           p_id_piano,
           p_id_periodo_speciale,
           p_id_periodo,
           p_lordo,
           p_netto,
           p_perc_sc,
           p_anno,
		   p_ciclo,
		   p_per--,
		   --user,
		   --FU_DATA_ORA
		  );
	   --

	EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
		WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20017, 'PROCEDURA PR_INSERISCI_IMP_RICH_PIANO: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_IMP_RICH_PIANO( p_id_ver_piano,
                                                                                                                                                                       p_id_piano,
                                                                                                                                                                       p_id_periodo_speciale,
                                                                                                                                                                       p_id_periodo,
                                                                                                                                                                       p_lordo,
                                                                                                                                                                       p_netto,
                                                                                                                                                                       p_perc_sc,
                                                                                                                                                                       p_anno,
                                                                                                                                                            		   p_ciclo,
                                                                                                                                                            		   p_per));
		ROLLBACK TO ann_ins;


END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_IMP_RICH_PIANO
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un importo richiesta piano dal sistema
--
-- OPERAZIONI:
--   3) Elimina l'importo richiesta piano
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Mauro Viel, Altran, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_IMP_RICH_PIANO(  p_id_importi_richiesti_piano		IN CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE,
									  p_esito		            	    OUT NUMBER)
IS


--
BEGIN -- PR_ELIMINA_IMP_RICH_PIANO
--

p_esito 	:= 1;

	 --
  		SAVEPOINT ann_del;

	   -- EFFETTUA L'eliminazione
       UPDATE  CD_IMPORTI_RICHIESTI_PIANO
       SET FLG_ANNULLATO = 'N'
	   WHERE ID_IMPORTI_RICHIESTI_PIANO = p_id_importi_richiesti_piano;
	   --DELETE FROM CD_IMPORTI_RICHIESTI_PIANO
	   --WHERE ID_IMPORTI_RICHIESTI_PIANO = p_id_importi_richiesti_piano;
	   --

	p_esito := SQL%ROWCOUNT;

  EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20017, 'PROCEDURA PR_ELIMINA_IMP_RICH_PIANO: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI');
		ROLLBACK TO ann_del;

END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_IMP_RICH_PIANO
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Mauro  Viel, Altran, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_STAMPA_IMP_RICH_PIANO(  p_id_ver_piano                  CD_IMPORTI_RICHIESTI_PIANO.ID_VER_PIANO%TYPE,
                                    p_id_piano                      CD_IMPORTI_RICHIESTI_PIANO.ID_PIANO%TYPE,
                                    p_id_periodo_speciale           CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO_SPECIALE%TYPE,
                                    p_id_periodo                    CD_IMPORTI_RICHIESTI_PIANO.ID_PERIODO%TYPE,
                                    p_lordo                         CD_IMPORTI_RICHIESTI_PIANO.LORDO%TYPE,
                                    p_netto                         CD_IMPORTI_RICHIESTI_PIANO.NETTO%TYPE,
                                    p_perc_sc                       CD_IMPORTI_RICHIESTI_PIANO.PERC_SC%TYPE,
                                    p_anno                          CD_IMPORTI_RICHIESTI_PIANO.ANNO%TYPE,
			   			            p_ciclo                         CD_IMPORTI_RICHIESTI_PIANO.CICLO%TYPE,
			   			            p_per                           CD_IMPORTI_RICHIESTI_PIANO.PER%TYPE) RETURN VARCHAR2
IS

BEGIN

IF v_stampa_imp_rich_piano = 'ON'

    THEN

     RETURN 'ID_VER_PIANO: '          || p_id_ver_piano          || ', ' ||
            'ID_PIANO: '          || p_id_piano            || ', ' ||
            'ID_PERIODO_SPECIALE: '|| p_id_periodo_speciale   || ', ' ||
            'ID_PERIODO: '  || p_id_periodo       || ', ' ||
            'LORDO: ' || p_lordo       || ', ' ||
            'NETTO: '          || p_netto               || ', ' ||
            'PERC_SC: '          || p_perc_sc                   || ', ' ||
            'ANNO: '      || p_anno         || ', '||
            'CICLO: '      || p_ciclo        || ', '||
            'PER: '      || p_per ;

END IF;

END  FU_STAMPA_IMP_RICH_PIANO;


-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_ANNI_PERIODO_ALL
-- DESCRIZIONE:  restituisce gli anni presenti nella tabella periodo incondizionatamante dalla data di sistema
--
-- OUTPUT: cursore con gli anni distinti
--
--
-- REALIZZATORE  Mauro  Viel, Altran, Febbraio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_ANNI_PERIODO_ALL RETURN C_ANNO IS
v_anni C_ANNO;
BEGIN
    OPEN v_anni FOR
        SELECT DISTINCT(ANNO)
        FROM PERIODI
        ORDER BY ANNO DESC;
RETURN v_anni;
END FU_GET_ANNI_PERIODO_ALL;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_MESI_PERIODO_ALL
-- DESCRIZIONE:  restituisce gli anni presenti nella tabella periodo incondizionatamante dall data di sistema
--
-- OUTPUT: cursore con gli anni distinti
--
--
-- REALIZZATORE  Mauro  Viel, Altran, Febbraio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_MESI_PERIODO_ALL(p_anno PERIODI.ANNO%TYPE) RETURN C_CICLO IS
v_mesi C_CICLO;
BEGIN
    OPEN v_mesi FOR
     SELECT DISTINCT(PERIODI.CICLO) AS MESE
        FROM PERIODI
        WHERE PERIODI.ANNO = p_anno;
RETURN v_mesi;
END FU_GET_MESI_PERIODO_ALL;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_SETTIMANE_PERIODO
-- DESCRIZIONE:  restituisce le settimane presenti per un dato mese/anno incondizionatamante dall data di sistema
--
-- OUTPUT: cursore con le settimane
--
--
-- REALIZZATORE  Mauro  Viel, Altran, Febbraio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_SETTIMANE_PERIODO_ALL(p_anno PERIODI.ANNO%TYPE, p_mese PERIODI.CICLO%TYPE) RETURN C_SETTIMANA IS
v_settimane C_SETTIMANA;
BEGIN
    OPEN v_settimane FOR
     SELECT PER AS SETTIMANA, CICLO, ANNO, DATA_INIZ, DATA_FINE
        FROM PERIODI
        WHERE PERIODI.ANNO = p_anno
        AND PERIODI.CICLO = p_mese;
RETURN v_settimane;
END FU_GET_SETTIMANE_PERIODO_ALL;


-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_ANNI_PERIODO
-- DESCRIZIONE:  restituisce gli anni presenti nella tabella periodo
--
-- OUTPUT: cursore con gli anni distinti
--
--
-- REALIZZATORE  Simone Bottani, Altran, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_ANNI_PERIODO RETURN C_ANNO IS
v_anni C_ANNO;
BEGIN
    OPEN v_anni FOR
        SELECT DISTINCT(ANNO)
        FROM PERIODI
        WHERE DATA_FINE > sysdate
        ORDER BY ANNO DESC;
RETURN v_anni;
END FU_GET_ANNI_PERIODO;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_MESI_PERIODO
-- DESCRIZIONE:  restituisce gli anni presenti nella tabella periodo
--
-- OUTPUT: cursore con gli anni distinti
--
--
-- REALIZZATORE  Simone Bottani, Altran, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_MESI_PERIODO(p_anno PERIODI.ANNO%TYPE) RETURN C_CICLO IS
v_mesi C_CICLO;
BEGIN
    OPEN v_mesi FOR
     SELECT DISTINCT(PERIODI.CICLO) AS MESE
        FROM PERIODI
        WHERE PERIODI.ANNO = p_anno
        AND DATA_FINE > sysdate;
RETURN v_mesi;
END FU_GET_MESI_PERIODO;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_SETTIMANE_PERIODO
-- DESCRIZIONE:  restituisce le settimane presenti per un dato mese/anno
--
-- OUTPUT: cursore con le settimane
--
--
-- REALIZZATORE  Simone Bottani, Altran, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_SETTIMANE_PERIODO(p_anno PERIODI.ANNO%TYPE, p_mese PERIODI.CICLO%TYPE) RETURN C_SETTIMANA IS
v_settimane C_SETTIMANA;
BEGIN
    OPEN v_settimane FOR
     SELECT PER AS SETTIMANA, CICLO, ANNO, DATA_INIZ, DATA_FINE
        FROM PERIODI
        WHERE PERIODI.ANNO = p_anno
        AND PERIODI.CICLO = p_mese
        AND DATA_FINE > sysdate;
RETURN v_settimane;
END FU_GET_SETTIMANE_PERIODO;

FUNCTION FU_GENERA_SETTIMANE(p_data_inizio PERIODI.DATA_INIZ%TYPE, p_data_fine PERIODI.DATA_FINE%TYPE) RETURN C_SETTIMANA IS
v_settimane C_SETTIMANA;
BEGIN
    OPEN v_settimane FOR
    SELECT PER AS SETTIMANA, CICLO AS MESE, ANNO, DATA_INIZ, DATA_FINE
          FROM PERIODI P
          WHERE P.DATA_INIZ BETWEEN p_data_inizio AND p_data_fine OR
                  P.DATA_FINE BETWEEN p_data_inizio AND p_data_fine
          ORDER BY ANNO, CICLO, PER;
RETURN  v_settimane;
END FU_GENERA_SETTIMANE;


FUNCTION FU_GET_STATO_LAVORAZIONE(p_stato_pianificazione cd_stato_lavorazione.STATO_PIANIFICAZIONE%TYPE) RETURN C_STATO_LAVORAZIONE IS
v_stati_lavorazione C_STATO_LAVORAZIONE;
BEGIN
    OPEN v_stati_lavorazione FOR
    SELECT ID_STATO_LAV, DESCRIZIONE
    FROM  CD_STATO_LAVORAZIONE
    WHERE CD_STATO_LAVORAZIONE.STATO_PIANIFICAZIONE =p_stato_pianificazione;
RETURN v_stati_lavorazione;
END FU_GET_STATO_LAVORAZIONE;

FUNCTION FU_GET_CLIENTI(p_filtro_ricerca VI_CD_CLIENTE.RAG_SOC_COGN%TYPE) RETURN C_INTERMEDIARIO IS
v_clienti C_INTERMEDIARIO;
BEGIN
OPEN v_clienti FOR
    SELECT ID_CLIENTE,
    RAG_SOC_COGN,
    INDIRIZZO,
    LOCALITA,
    COD_FISC,
    AREA,
    SEDE,
    NULL,
    NULL,
    NULL,
    NULL
    --A_DESC_AREA varchar2(200),
    --A_DESC_SEDE varchar2(200)
    FROM VI_CD_CLIENTE
    WHERE (p_filtro_ricerca IS NULL OR UPPER(RAG_SOC_COGN) like UPPER('%'||p_filtro_ricerca||'%'))
    ORDER BY RAG_SOC_COGN;
RETURN  v_clienti;
END FU_GET_CLIENTI;


FUNCTION FU_GET_CLIENTI_TARGET(p_id_target cd_prodotto_vendita.id_target%type,
                               p_id_cliente cd_pianificazione.id_cliente%type, 
                               p_data_inizio cd_prodotto_acquistato.data_inizio%type,
                               p_data_fine cd_prodotto_acquistato.data_fine%type ) RETURN C_INTERMEDIARIO IS
v_clienti C_INTERMEDIARIO;
BEGIN
OPEN v_clienti FOR
        select  distinct cliente.cod_interl as ID_CLIENTE,
        RAG_SOC_COGN,
        INDIRIZZO,
        LOCALITA,
        COD_FISC,
        AREA,
        SEDE,
        NULL,
        NULL,
        NULL,
        NULL 
from   cd_pianificazione pia, 
       interl_u cliente,
       cd_prodotto_acquistato pa, 
       cd_prodotto_vendita pv
where  pia.id_piano = pa.id_piano
and    pia.id_ver_piano = pa.id_ver_piano
and    pia.flg_annullato = 'N'
and    pia.ID_CLIENTE = cliente.COD_INTERL
and    pia.id_cliente = nvl(p_id_cliente,pia.id_cliente )
and    pa.flg_annullato = 'N'
and    pa.flg_sospeso = 'N'
and    pa.id_prodotto_vendita = pv.id_prodotto_vendita
and    pa.data_inizio = p_data_inizio
and    pa.data_fine   =  nvl(p_data_fine,pa.data_fine)
and    pv.id_prodotto_vendita =  pa.id_prodotto_vendita
and    pv.id_target = nvl(p_id_target,pv.id_target)
ORDER BY RAG_SOC_COGN;
RETURN  v_clienti;
END FU_GET_CLIENTI_TARGET;


FUNCTION FU_GET_CLIENTI_RICERCA RETURN C_INTERMEDIARIO IS
v_clienti C_INTERMEDIARIO;
BEGIN
OPEN v_clienti FOR
    SELECT COD_INTERL AS ID_CLIENTE,
           RAGSOC     AS RAG_SOC_COGN,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
    --A_DESC_AREA varchar2(200),
    --A_DESC_SEDE varchar2(200)
    FROM CLICOMM
    ORDER BY RAGSOC;
RETURN  v_clienti;
END FU_GET_CLIENTI_RICERCA;



FUNCTION FU_GET_TARGET RETURN C_TARGET IS
v_target C_TARGET;
BEGIN
OPEN v_target FOR
SELECT ID_TARGET, NOME_TARGET, DESCR_TARGET
FROM CD_TARGET
WHERE FLG_ANNULLATO='N';
RETURN v_target;
END FU_GET_TARGET;



/******************************************************************************
   NAME:       PR_MODIFICA_STATO_LAVORAZIONE
   PURPOSE:

   REVISIONS:
   Ver        Date        Author                     Description
   ---------  ----------  ---------------     ------------------------------------
   1.0        08/09/2009    Mauro Viel Altran italia    Imposta lo stato di lavorazine.
                                                        Si vuole cantralizzare questa operazione

******************************************************************************/


PROCEDURE PR_MODIFICA_STATO_LAVORAZIONE(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE, P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, P_ID_STATO_LAVORAZIONE cd_pianificazione.id_stato_lav%type) is
BEGIN
   update cd_pianificazione
   set id_stato_lav   = P_ID_STATO_LAVORAZIONE
   where id_piano     = p_id_piano
   and   id_ver_piano = p_id_ver_piano ;
 EXCEPTION
     WHEN OTHERS THEN
       RAISE;
END PR_MODIFICA_STATO_LAVORAZIONE;




function  fu_get_intermediario
(
                                    p_det_gest_commerciale        in        varchar2,
                                    p_tipo_contratto              in        varchar2,
                                    p_data_decorrenza             in        date,
                                    p_cliente                     in        varchar2,
                                    p_agenzia                     in        varchar2,
                                    p_centro_media                in        varchar2,
									p_tipo_venditore			  in		varchar2,
                                    p_gest_comm					  in		varchar2
) return  C_VENDITORI IS

v_esito char(2);
v_sqlcode_portafoglio    number;
v_sqlerrm_portafoglio    varchar2(1000);




/******************************************************************************
   NAME:       fu_get_intermediario
   PURPOSE:

   REVISIONS:
   Ver        Date        Author                     Description
   ---------  ----------  ---------------     ------------------------------------
   1.0        30/07/2009    Mauro Viel Altran italia     Restituisce l'elenco degli intermediari associati al
                                                         al cliente per mezzo di chaimate di portafoglio




******************************************************************************/

cur c_venditori ;




BEGIN



   v_esito := pa_pc_portafoglio.fu_get_venditori(null,  -- mod_operativa_exception
                                                 p_tipo_contratto,--'C',-- tipo_contratto
                                                 p_data_decorrenza,--sysdate,        -- data_decorrenza
                                                  p_cliente,
                                                  p_agenzia,
                                                  p_centro_media,
                                                  v_sqlcode_portafoglio,-- out    number
                                                  v_sqlerrm_portafoglio,-- out    varchar2
                                                  p_tipo_venditore,
                                                  p_gest_comm);

  OPEN cur for select * from VI_PC_PORTAFOGLIO_VENDITORI;
  return cur;
  EXCEPTION
     WHEN OTHERS THEN
       RAISE;
END fu_get_intermediario;



function fu_get_gest_comm(P_COD_MEZZO gest_comm.MEZ_COD_MEZZO%type) return C_TIPI_GEST_COMM IS
CUR C_TIPI_GEST_COMM;
BEGIN
--open cur for select id from  gest_comm where MEZ_COD_MEZZO = P_COD_MEZZO;
open cur for select pa_cd_mezzo.FU_GEST_COMM as id from dual;
return cur;
  EXCEPTION
     WHEN OTHERS THEN
       RAISE;
END;


----------------------------------------------------------------------
--Funzione di ricerca delle pianificazioni presenti a sistema
--Realizzatore del commento Antonio Colucci 05/01/2011
--
--Realizzatore: ipoteticamente Michele Fadda, Altran Italia
--modifiche precedenti alla seguente non pervenute
--Modifiche     Antonio Colucci, Teoresi srl, 05/01/2011
--              Cambiato modalita di reperimentodella descrizione del soggetto
--              E' stato richiesto che tale descrizione venisse recuperata da CLICOMM
--              piuttosto che da VI_CD_CLIENTE, in quanto tale vista non considera i Clienti non + validi
----------------------------------------------------------------------

/*FUNCTION FU_CERCA_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_STATO_VENDITA CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE,
                        P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
                        P_DATA_INIZIO PERIODI.DATA_INIZ%TYPE,
                        P_DATA_FINE PERIODI.DATA_FINE%TYPE,
                        P_COD_CATEGORIA_PRODOTTO CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                        ) RETURN  C_PIANIFICAZIONE IS
CUR C_PIANIFICAZIONE;
v_stato_vendita CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
BEGIN
    IF P_STATO_VENDITA IS NOT NULL THEN
        SELECT DESCR_BREVE INTO v_stato_vendita
        FROM CD_STATO_DI_VENDITA
        WHERE ID_STATO_VENDITA = P_STATO_VENDITA;
    END IF;
    --
    OPEN CUR for
    select id_piano, id_ver_piano,cod_area,id_responsabile_contatto,id_cliente_fruitore,
        netto, lordo, perc_sc, data_creazione_richiesta, to_char(per_inizio,'DD/MM/YYYY') as periodo_inizio,
        to_char(per_fine,'DD/MM/YYYY') as periodo_fine, id_stato_lav, cod_categoria_prodotto from (
    SELECT PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           GET_DESC_AREA(PIA.cod_area) as cod_area,
           get_desc_responsabile(id_responsabile_contatto) as id_responsabile_contatto,
           --get_desc_cliente(id_cliente)as id_cliente_fruitore,
           clicomm.RAGSOC id_cliente_fruitore,
           sum(nvl(netto,0)) as netto ,
           sum(nvl(lordo,0)) as lordo,
           min(nvl(perc_sc,0)) as perc_sc ,
           to_char(data_creazione_richiesta,'DD/MM/YYYY') as data_creazione_richiesta,
           --nvl(to_char(min (per.data_iniz),'DD/MM/YYYY'),'-') as periodo_inizio,
           --nvl(to_char(max(per.data_fine),'DD/MM/YYYY'),'-') as periodo_fine,
--           to_char(least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_inizio,
--           to_char(greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_fine,
           least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))) as per_inizio,
           greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))) as per_fine,
           PIA.id_stato_lav,
           PIA.cod_categoria_prodotto
    FROM CD_PIANIFICAZIONE PIA,
         CD_IMPORTI_RICHIESTI_PIANO IMP,
         periodi PER,
         CD_PRODOTTO_ACQUISTATO PRA,
         VI_CD_AREE_SEDI_COMPET ARSE,
         CLICOMM
    WHERE (P_ID_PIANO is null or PIA.ID_PIANO =P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIA.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_COD_CATEGORIA_PRODOTTO IS NULL OR PIA.COD_CATEGORIA_PRODOTTO = P_COD_CATEGORIA_PRODOTTO)
    AND   (P_ID_CLIENTE is null or PIA.ID_CLIENTE  = P_ID_CLIENTE)
    AND   (P_COD_AREA IS NULL OR PIA.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIA.COD_SEDE = P_COD_SEDE)
--    AND   (P_ID_SOGGETTO IS NULL OR  PIA.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
    AND   (P_RESP_CONTATTO IS NULL OR PIA.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO)
    AND   (P_ID_STATO_LAV is null or PIA.ID_STATO_LAV  = P_ID_STATO_LAV)
 --   AND   (P_DATA_INIZIO is null or PER.DATA_INIZ = P_DATA_INIZIO or FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo) = P_DATA_INIZIO)
 --   AND   (P_DATA_FINE is null or PER.DATA_FINE  = P_DATA_FINE or FU_GET_DATA_PER_SPEC_FI(imp.id_periodo_speciale,imp.id_periodo) = P_DATA_FINE)
--    AND   (P_DATA_INIZIO is null or P_DATA_INIZIO >= least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))))
--    AND   (P_DATA_FINE is null or P_DATA_FINE = periodo_fine)
    AND   (IMP.ID_PIANO  (+)= PIA.ID_PIANO)
    AND   (IMP.ID_VER_PIANO (+) = PIA.ID_VER_PIANO)
    AND   IMP.FLG_ANNULLATO = 'N'
    AND   (PIA.DATA_INVIO_MAGAZZINO IS NOT  NULL)
    AND   (PIA.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL)
    AND   (PIA.FLG_SOSPESO ='N')
    AND   (PIA.FLG_ANNULLATO = 'N')
    --AND   PIA.ID_STATO_LAV =  P_ID_STATO_LAV
    AND PER.ANNO (+)= IMP.ANNO
    AND PER.CICLO (+)= IMP.CICLO
    AND PER.PER (+)= IMP.PER
    AND PIA.ID_PIANO     = PRA.ID_PIANO (+)
    AND PIA.ID_VER_PIANO = PRA.ID_VER_PIANO (+)
    AND (v_stato_vendita is null OR PRA.STATO_DI_VENDITA = v_stato_vendita)
    AND  PRA.FLG_ANNULLATO (+) =  'N'
    AND PRA.FLG_SOSPESO (+) = 'N'
    AND PRA.COD_DISATTIVAZIONE (+)  is null
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
    and pia.id_cliente = clicomm.COD_INTERL
    group by PIA.id_piano,
             PIA.id_ver_piano,
             PIA.cod_area,
             id_responsabile_contatto,
             --id_cliente,
             data_creazione_richiesta,
             PIA.ID_STATO_LAV,
             PIA.cod_categoria_prodotto,
             clicomm.RAGSOC
             --imp.id_periodo_speciale
    order by PIA.id_piano DESC)
 --   where ((P_DATA_INIZIO is not null and P_DATA_FINE is not null) and (P_DATA_INIZIO <= periodo_inizio and P_DATA_FINE >= periodo_fine));
--    where (P_DATA_INIZIO is null or (P_DATA_INIZIO <= per_inizio))
--    and (P_DATA_FINE is null or (P_DATA_FINE >= per_fine));
    where (P_DATA_INIZIO is null or (P_DATA_INIZIO <= per_fine))
    and (P_DATA_FINE is null or (P_DATA_FINE >= per_inizio));
--
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_PIANO;*/


-- Michele Fadda, Altran, 2009
FUNCTION FU_CERCA_PIANO_SOSP(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_ID_STATO_VENDITA CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                        P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE) RETURN  C_PIANIFICAZIONE IS
--V_ROW CD_PIANIFICAZIONE%ROWTYPE;
CUR C_PIANIFICAZIONE;
BEGIN
    OPEN CUR for
    SELECT PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           GET_DESC_AREA(PIA.cod_area) as cod_area,
           get_desc_responsabile(id_responsabile_contatto) as id_responsabile_contatto,
           get_desc_cliente(id_cliente)as id_cliente_fruitore,
           sum(nvl(netto,0)) as netto ,
           sum(nvl(lordo,0)) as lordo,
           min(nvl(perc_sc,0)) as perc_sc ,
           to_char(data_creazione_richiesta,'DD/MM/YYYY') as data_creazione_richiesta,
           --nvl(to_char(min (per.data_iniz),'DD/MM/YYYY'),'-') as periodo_inizio,
           --nvl(to_char(max(per.data_fine),'DD/MM/YYYY'),'-') as periodo_fine,
           to_char(least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_inizio,
           to_char(greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_fine,
           PIA.id_stato_lav,
           PIA.cod_categoria_prodotto
    FROM CD_PIANIFICAZIONE PIA,
         CD_IMPORTI_RICHIESTI_PIANO IMP,
         periodi PER,
         VI_CD_AREE_SEDI_COMPET ARSE
    WHERE (P_ID_PIANO is null or PIA.ID_PIANO =P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIA.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_ID_CLIENTE is null or PIA.ID_CLIENTE  = P_ID_CLIENTE)
    AND   (P_COD_AREA IS NULL OR PIA.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIA.COD_SEDE = P_COD_SEDE)
--    AND   (P_ID_SOGGETTO IS NULL OR  PIA.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
    AND   (P_ID_STATO_LAV IS NULL OR  PIA.ID_STATO_LAV = P_ID_STATO_LAV)
    AND   (P_RESP_CONTATTO IS NULL OR PIA.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO)
    AND   (IMP.ID_PIANO  (+)= PIA.ID_PIANO)
    AND   (IMP.ID_VER_PIANO (+) = PIA.ID_VER_PIANO)
    AND   IMP.FLG_ANNULLATO = 'N'
    AND   (PIA.DATA_INVIO_MAGAZZINO IS NOT  NULL)
    AND   (PIA.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL)
    AND   (PIA.FLG_SOSPESO ='S')
    AND   (PIA.FLG_ANNULLATO ='N')
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
    AND PER.ANNO (+)= IMP.ANNO
    AND PER.CICLO (+)= IMP.CICLO
    AND PER.PER (+)= IMP.PER
      group by PIA.id_piano,
             PIA.id_ver_piano,
             PIA.cod_area,
             id_responsabile_contatto,
             id_cliente,
             data_creazione_richiesta,
             PIA.ID_STATO_LAV,
             PIA.cod_categoria_prodotto
             --imp.id_periodo_speciale
      order by PIA.id_piano DESC;
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_PIANO_SOSP;


/******************************************************************************
   NAME:       fu_get_intermediario
   PURPOSE:

   REVISIONS:
   Ver        Date        Author                     Description
   ---------  ----------  ---------------     ------------------------------------
   1.0        30/07/2009    Mauro Viel Altran italia     marca la richiesta come inviata
                                                         attribuendo il corretto stato di vendita.
                                                         verifica l'esistenza del soggetto. Nel caso sia
                                                         assenta attribuisce il soggetto non definito.



******************************************************************************/

PROCEDURE PR_INVIA_RICHIESTA(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                   P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) is
--v_id_soggetto_di_piano cd_soggetto_di_piano.id_soggetto_di_piano%type;
v_count_soggetto number;
v_id_cliente cd_pianificazione.id_cliente%type;
v_id_stato_lav cd_pianificazione.id_stato_lav%type;
v_cod_sogg soggetti.cod_sogg%type;
BEGIN


select id_stato_lav,id_cliente into v_id_stato_lav,v_id_cliente
from  cd_pianificazione
where id_piano = p_id_piano
and   id_ver_piano = p_id_ver_piano;

if v_id_stato_lav <> 3 then
    raise_application_error(-20001, 'PR_INVIA_RICHIESTA: La richiesta non puo essere inviata a magazzino perche il suo stato di lavorazione non e da inviare');
end if;

select count(1) into v_count_soggetto
from  cd_soggetto_di_piano
where id_piano = p_id_piano
and   id_ver_piano = p_id_ver_piano
and  descrizione ='SOGGETTO NON DEFINITO';
--
if v_count_soggetto =0  then
--
    SELECT COD_SOGG
    INTO v_cod_sogg
    FROM SOGGETTI
    WHERE INT_U_COD_INTERL = v_id_cliente
    AND DES_SOGG = 'SOGGETTO NON DEFINITO';
--
    INSERT INTO CD_SOGGETTO_DI_PIANO (DESCRIZIONE,
    INT_U_COD_INTERL, ID_PIANO, ID_VER_PIANO, COD_SOGG ) VALUES (
    'SOGGETTO NON DEFINITO' , v_id_cliente, p_id_piano, p_id_ver_piano, v_cod_sogg);
--
end if;

update cd_pianificazione
set    DATA_INVIO_MAGAZZINO=SYSDATE,
       UTENTE_INVIO_RICHIESTA=USER,
       ID_STATO_LAV = 4
where  ID_PIANO     = P_ID_PIANO
and    id_ver_piano = P_ID_VER_PIANO
and    DATA_INVIO_MAGAZZINO is null;



EXCEPTION
WHEN OTHERS THEN
RAISE;
END;

PROCEDURE PR_TRASFORMA_IN_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) is

v_data_invio cd_pianificazione.DATA_INVIO_MAGAZZINO%type;
v_num_fruitori NUMBER;
v_cliente cd_pianificazione.ID_CLIENTE%TYPE;
v_id_fruitore cd_fruitori_di_piano.ID_CLIENTE_FRUITORE%TYPE;
BEGIN
---verifico che la richiesta sia stata inviata a magazzino
SAVEPOINT PR_TRASFORMA_IN_PIANO;
select DATA_INVIO_MAGAZZINO
into v_data_invio
from cd_pianificazione
where  ID_PIANO     = P_ID_PIANO
and    id_ver_piano = P_ID_VER_PIANO;

if v_data_invio is not null then

update cd_pianificazione
set    DATA_TRASFORMAZIONE_IN_PIANO=SYSDATE,
       ID_STATO_LAV = 1
where  ID_PIANO     = P_ID_PIANO
and    id_ver_piano = P_ID_VER_PIANO;

insert into cd_importi_richiesti_piano (ID_PIANO,ID_VER_PIANO,LORDO,NETTO,PERC_SC,ID_PERIODO_SPECIALE,ID_PERIODO,ANNO,CICLO,PER, NOTA)
select ID_PIANO,ID_VER_PIANO,LORDO,NETTO,PERC_SC,ID_PERIODO_SPECIALE,ID_PERIODO,ANNO,CICLO,PER,NOTA from cd_importi_richiesta
where id_piano=P_ID_PIANO
and id_ver_piano =P_ID_VER_PIANO
and flg_annullato = 'N';
--
update cd_prodotti_richiesti pr
set id_importi_richiesti_piano =
(
    select imp.id_importi_richiesti_piano
    from cd_importi_richiesti_piano imp, periodi p
    where imp.anno = p.anno
    and imp.ciclo = p.ciclo
    and imp.per = p.per
    and imp.id_piano = pr.id_piano
    and imp.id_ver_piano = pr.id_ver_piano
    and pr.data_inizio = p.data_iniz
    and pr.data_fine = p.data_fine
    union
    select imp.id_importi_richiesti_piano
    from cd_importi_richiesti_piano imp, cd_periodo_speciale ps
    where imp.id_periodo_speciale = ps.id_periodo_speciale
    and imp.id_piano = pr.id_piano
    and imp.id_ver_piano = pr.id_ver_piano
    and ps.data_inizio = pr.data_inizio
    and ps.data_fine = pr.data_fine
    union
    select imp.id_importi_richiesti_piano
    from cd_importi_richiesti_piano imp, cd_periodi_cinema pc
    where imp.id_periodo = pc.id_periodo
    and imp.id_piano = pr.id_piano
    and imp.id_ver_piano = pr.id_ver_piano
    and pc.data_inizio = pr.data_inizio
    and pc.data_fine = pr.data_fine   
)
where id_piano=P_ID_PIANO
and id_ver_piano =P_ID_VER_PIANO;
--
select id_cliente
into v_cliente
from cd_pianificazione
where  ID_PIANO     = P_ID_PIANO
and    id_ver_piano = P_ID_VER_PIANO;
--
  SELECT COUNT (1)
  INTO v_num_fruitori
        FROM
        VI_CD_CLIENTE_FRUITORE FR,
        RAGGRUPPAMENTO_U RAG
        WHERE RAG.tipo_raggrupp='CCCL'
        AND RAG.COD_INTERL_P = v_cliente
        AND RAG.COD_INTERL_F = FR.ID_FRUITORE
        AND sysdate BETWEEN RAG.DT_INIZ_VAL AND RAG.DT_FINE_VAL;
  --
  IF v_num_fruitori = 1 THEN
      SELECT FR.ID_FRUITORE
  INTO v_id_fruitore
        FROM
        VI_CD_CLIENTE_FRUITORE FR,
        RAGGRUPPAMENTO_U RAG
        WHERE RAG.tipo_raggrupp='CCCL'
        AND RAG.COD_INTERL_P = v_cliente
        AND RAG.COD_INTERL_F = FR.ID_FRUITORE
        AND sysdate BETWEEN RAG.DT_INIZ_VAL AND RAG.DT_FINE_VAL;

  insert into cd_fruitori_di_piano(id_piano, id_ver_piano, id_cliente_fruitore)
  values(P_ID_PIANO, P_ID_VER_PIANO, v_id_fruitore);

  END IF;

else
    raise_application_error(-20001, 'PR_TRASFORMA_IN_PIANO: La richiesta non puo essere trasformata in piano perche non inviata a magazzino');
end if;
EXCEPTION
WHEN OTHERS THEN
RAISE;
ROLLBACK TO PR_TRASFORMA_IN_PIANO;
END;

FUNCTION FU_GET_INTERMEDIARIO_CLIENTE(p_det_gest_commerciale        in        varchar2,
                                     p_tipo_contratto              in        varchar2,
                                     p_data_decorrenza             in        date,
                                     p_cliente                     in        varchar2,
                                     p_agenzia                     in        varchar2,
                                     p_centro_media                in        varchar2,
									 p_tipo_venditore			  in		varchar2,
                                     p_gest_comm					  in		varchar2,
                                     p_stringa_ricerca             in        varchar2)
                                    RETURN C_INTERMEDIARIO IS
v_intermediario C_INTERMEDIARIO;
v_esito char(100);
v_sqlcode_portafoglio    number;
v_sqlerrm_portafoglio    varchar2(10000);
BEGIN
--
   v_esito := pa_pc_portafoglio.fu_get_venditori(null,  -- mod_operativa_exception
                                                 p_tipo_contratto,--'C',-- tipo_contratto
                                                 p_data_decorrenza,--sysdate,        -- data_decorrenza
                                                 p_cliente,
                                                 p_agenzia,
                                                 p_centro_media,
                                                 v_sqlcode_portafoglio,-- out    number
                                                 v_sqlerrm_portafoglio,-- out    varchar2
                                                 p_tipo_venditore,
                                                 p_gest_comm);
  OPEN v_intermediario for select COD_INTERL, RAG_SOC_COGN, INDIRIZZO, LOCALITA, COD_FISC, AREA, SEDE, NULL, NULL, DT_INIZ_VAL, DT_FINE_VAL
  FROM VI_PC_PORTAFOGLIO_VENDITORI v, interl_u i
  WHERE i.COD_INTERL = v.venditore;
  RETURN v_intermediario;
END FU_GET_INTERMEDIARIO_CLIENTE;

FUNCTION FU_GET_AGENZIE(p_data_decorrenza CACQCOMM.DT_FINE_VAL%TYPE, p_stringa_ricerca VARCHAR2) RETURN C_INTERMEDIARIO IS
v_agenzia C_INTERMEDIARIO;
BEGIN
IF p_stringa_ricerca IS NULL THEN
OPEN v_agenzia FOR
SELECT c.COD_INTERL, RAG_SOC_COGN, c.INDIRIZZO, c.LOCALITA, COD_FISC, AREA, SEDE, NULL, NULL, to_char(c.dt_iniz_val,'dd/mm/yyyy') dt_iniz_val, to_char(c.dt_fine_val,'dd/mm/yyyy') dt_fine_val
  from cacqcomm c, interl_u i
  where i.cod_interl = c.cod_interl
  and tipo_cod = 'Z' and flag_ann != 'S'
  and p_data_decorrenza between c.dt_iniz_val and c.dt_fine_val--;
  
   --union select 'A' ord, null, null, to_char(null), to_char(null),
 -- null, null from dual order by 1, 3
 union 
 select 'A' ord, null, null, null, null, null, null, NULL, NULL,'' dt_iniz_val, '' dt_fine_val from dual order by 1, 3;
ELSE
OPEN v_agenzia FOR
SELECT c.COD_INTERL, RAG_SOC_COGN, c.INDIRIZZO, c.LOCALITA, COD_FISC, AREA, SEDE, NULL, NULL, to_char(c.dt_iniz_val,'dd/mm/yyyy') dt_iniz_val, to_char(c.dt_fine_val,'dd/mm/yyyy') dt_fine_val
  from cacqcomm c, interl_u i
  where i.cod_interl = c.cod_interl
  and tipo_cod = 'Z' and flag_ann != 'S'
  and p_data_decorrenza between c.dt_iniz_val and c.dt_fine_val
  and UPPER(i.RAG_SOC_COGN) like UPPER('%'||p_stringa_ricerca||'%');
END IF;
RETURN v_agenzia;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_AGENZIE;

FUNCTION FU_GET_CENTRI_MEDIA(p_data_decorrenza CACQCOMM.DT_FINE_VAL%TYPE, p_stringa_ricerca VARCHAR2) RETURN C_INTERMEDIARIO IS
v_centro_media C_INTERMEDIARIO;
BEGIN
IF p_stringa_ricerca IS NULL THEN
OPEN v_centro_media FOR
SELECT c.COD_INTERL, RAG_SOC_COGN, c.INDIRIZZO, c.LOCALITA, COD_FISC, AREA, SEDE, NULL, NULL, to_char(c.dt_iniz_val,'dd/mm/yyyy') dt_iniz_val, to_char(c.dt_fine_val,'dd/mm/yyyy') dt_fine_val
  from cacqcomm c, interl_u i
  where i.cod_interl = c.cod_interl
  and tipo_cod = 'C' and flag_ann != 'S'
  and p_data_decorrenza between c.dt_iniz_val and c.dt_fine_val
  ORDER BY RAG_SOC_COGN;
  -- union select 'A' ord, null, null, to_char(null), to_char(null),
  -- null, null from dual order by 1, 3
ELSE
OPEN v_centro_media FOR
SELECT c.COD_INTERL, RAG_SOC_COGN, c.INDIRIZZO, c.LOCALITA, COD_FISC, AREA, SEDE, NULL, NULL, to_char(c.dt_iniz_val,'dd/mm/yyyy') dt_iniz_val, to_char(c.dt_fine_val,'dd/mm/yyyy') dt_fine_val
  from cacqcomm c, interl_u i
  where i.cod_interl = c.cod_interl
  and tipo_cod = 'C' and flag_ann != 'S'
  and p_data_decorrenza between c.dt_iniz_val and c.dt_fine_val
  and UPPER(i.RAG_SOC_COGN) like UPPER('%'||p_stringa_ricerca||'%')
  ORDER BY RAG_SOC_COGN;
END IF;
RETURN v_centro_media;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_CENTRI_MEDIA;


FUNCTION FU_GET_PERIODI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO IS
v_periodo C_PERIODO;
BEGIN
    OPEN v_periodo FOR
SELECT
    IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
    PER.DATA_INIZ,
    PER.DATA_FINE,
    PER.ANNO,
    PER.CICLO,
    PER.PER,
    LORDO,
    NETTO,
    PERC_SC,
    NVL(SUM(ACQ.IMP_LORDO),0) / 2 as LORDO_EFF,
    NVL(SUM(ACQ.IMP_NETTO),0) / 2 as NETTO_EFF,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)) as PERC_SC_EFF,
    NOTA
    FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
    PERIODI per,
    CD_PIANIFICAZIONE pia,
    CD_PRODOTTO_ACQUISTATO ACQ,
    CD_IMPORTI_PRODOTTO IMP_PR 
    WHERE per.ANNO = IMP.ANNO --(+)
    AND per.CICLO = IMP.CICLO --(+)
    AND per.PER = IMP.PER --(+)
    AND IMP.FLG_ANNULLATO = 'N'
    AND pia.ID_PIANO = p_id_piano
    AND pia.ID_VER_PIANO = p_id_ver_piano
    AND IMP.ID_PIANO = pia.ID_PIANO
    AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
    AND ACQ.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
    AND ACQ.ID_PIANO = pia.ID_PIANO
    AND ACQ.ID_VER_PIANO = pia.ID_VER_PIANO
    AND ACQ.FLG_ANNULLATO = 'N'
    AND ACQ.FLG_SOSPESO   = 'N'
    AND ACQ.COD_DISATTIVAZIONE IS NULL
    AND IMP_PR.ID_PRODOTTO_ACQUISTATO = ACQ.ID_PRODOTTO_ACQUISTATO
    GROUP BY
    IMP.ID_IMPORTI_RICHIESTI_PIANO,
    PER.DATA_INIZ,
    PER.DATA_FINE,
    PER.ANNO,
    PER.CICLO,
    PER.PER,
    LORDO,
    NETTO,
    PERC_SC,
    NOTA
    UNION
    select IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
    PER.DATA_INIZ,
    PER.DATA_FINE,
    PER.ANNO,
    PER.CICLO,
    PER.PER,
    LORDO,
    NETTO,
    PERC_SC,
    0 as LORDO_EFF,
    0 as NETTO_EFF,
    0 as PERC_SC_EFF,
    NOTA
    FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
    PERIODI per,
    CD_PIANIFICAZIONE pia--,
    --CD_PRODOTTO_ACQUISTATO ACQ
    WHERE per.ANNO = IMP.ANNO
    AND per.CICLO = IMP.CICLO
    AND per.PER = IMP.PER --(+)
    AND IMP.FLG_ANNULLATO = 'N'
    AND not exists (select * from cd_prodotto_acquistato 
                    where ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
                    and cd_prodotto_acquistato.id_piano = p_id_piano and cd_prodotto_acquistato.id_ver_piano = p_id_ver_piano
                    AND FLG_ANNULLATO = 'N' AND FLG_SOSPESO = 'N' AND COD_DISATTIVAZIONE IS NULL)
    AND pia.ID_PIANO = p_id_piano
    AND pia.ID_VER_PIANO = p_id_ver_piano
    AND IMP.ID_PIANO = pia.ID_PIANO
    AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO;
    RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_PIANO;



FUNCTION FU_NETTO_RICHIESTO(P_ID_IMPORTI_RICHIESTI_PIANO  CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE) RETURN NUMBER IS
V_NETTO NUMBER;
begin
SELECT  
NVL(SUM(RICH.IMP_NETTO),0) / 2  into V_NETTO
FROM 
CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PRODOTTI_RICHIESTI RICH,
CD_IMPORTI_PRODOTTO IMP_PR
WHERE  RICH.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
AND RICH.ID_PIANO = IMP.ID_PIANO
AND RICH.ID_VER_PIANO = IMP.ID_VER_PIANO
AND RICH.FLG_ANNULLATO = 'N'
AND RICH.FLG_SOSPESO   = 'N'  
AND IMP_PR.ID_PRODOTTI_RICHIESTI = RICH.ID_PRODOTTI_RICHIESTI
AND IMP.ID_IMPORTI_RICHIESTI_PIANO = P_ID_IMPORTI_RICHIESTI_PIANO; 
RETURN V_NETTO;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END  FU_NETTO_RICHIESTO;


FUNCTION FU_PERC_SC_RICHIESTO(P_ID_IMPORTI_RICHIESTI_PIANO  CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE) RETURN NUMBER IS
V_PERC_SC NUMBER;
begin
SELECT  
NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)),0) into V_PERC_SC
FROM 
CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PRODOTTI_RICHIESTI RICH,
CD_IMPORTI_PRODOTTO IMP_PR
WHERE  RICH.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
AND RICH.ID_PIANO = IMP.ID_PIANO
AND RICH.ID_VER_PIANO = IMP.ID_VER_PIANO
AND RICH.FLG_ANNULLATO = 'N'
AND RICH.FLG_SOSPESO   = 'N'  
AND IMP_PR.ID_PRODOTTI_RICHIESTI = RICH.ID_PRODOTTI_RICHIESTI
AND IMP.ID_IMPORTI_RICHIESTI_PIANO = P_ID_IMPORTI_RICHIESTI_PIANO; 
RETURN V_PERC_SC;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END  FU_PERC_SC_RICHIESTO;




FUNCTION FU_LORDO_RICHIESTO(P_ID_IMPORTI_RICHIESTI_PIANO  CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE) RETURN NUMBER IS
V_LORDO NUMBER;
begin
SELECT  
NVL(SUM(RICH.IMP_LORDO),0) / 2 into V_LORDO
--NVL(SUM(RICH.IMP_NETTO),0) / 2  into V_NETTO
--PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)) as PERC_SC_EFF,
FROM 
CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PRODOTTI_RICHIESTI RICH,
CD_IMPORTI_PRODOTTO IMP_PR
WHERE  RICH.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
AND RICH.ID_PIANO = IMP.ID_PIANO
AND RICH.ID_VER_PIANO = IMP.ID_VER_PIANO
AND RICH.FLG_ANNULLATO = 'N'
AND RICH.FLG_SOSPESO   = 'N'  
AND IMP_PR.ID_PRODOTTI_RICHIESTI = RICH.ID_PRODOTTI_RICHIESTI
AND IMP.ID_IMPORTI_RICHIESTI_PIANO = P_ID_IMPORTI_RICHIESTI_PIANO; 
RETURN V_LORDO;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END  FU_LORDO_RICHIESTO;




--------------------------------------
--Realizzatore Mauro Viel Altran Italia Giugno 2010
--Procedura aggiunta per gestire sul dettaglio di piano l'importo richiesto derivante dal prodotto richiesto. Non e stata modificata 
--la procedura FU_GET_PERIODI_PIANO perche id_importo_richiesto_piano e utilizzato anche in altre sezioni del piano.
--

FUNCTION FU_GET_PERIODI_PIANO_IMPORTI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO IS
v_periodo C_PERIODO;
BEGIN
    OPEN v_periodo FOR
SELECT
    IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
    PER.DATA_INIZ,
    PER.DATA_FINE,
    PER.ANNO,
    PER.CICLO,
    PER.PER,
    FU_LORDO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS LORDO,
    FU_NETTO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)    AS NETTO, 
    FU_PERC_SC_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS PERC_SC, 
    NVL(SUM(ACQ.IMP_LORDO),0) / 2 as LORDO_EFF,
    NVL(SUM(ACQ.IMP_NETTO),0) / 2 as NETTO_EFF,
    PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)) as PERC_SC_EFF,
    NOTA
    FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
    PERIODI per,
    CD_PIANIFICAZIONE pia,
    CD_PRODOTTO_ACQUISTATO ACQ,
    CD_IMPORTI_PRODOTTO IMP_PR 
    WHERE per.ANNO = IMP.ANNO --(+)
    AND per.CICLO = IMP.CICLO --(+)
    AND per.PER = IMP.PER --(+)
    AND IMP.FLG_ANNULLATO = 'N'
    AND pia.ID_PIANO = p_id_piano
    AND pia.ID_VER_PIANO = p_id_ver_piano
    AND IMP.ID_PIANO = pia.ID_PIANO
    AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
    AND ACQ.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
    AND ACQ.ID_PIANO = pia.ID_PIANO
    AND ACQ.ID_VER_PIANO = pia.ID_VER_PIANO
    AND ACQ.FLG_ANNULLATO = 'N'
    AND ACQ.FLG_SOSPESO   = 'N'
    AND ACQ.COD_DISATTIVAZIONE IS NULL
    AND IMP_PR.ID_PRODOTTO_ACQUISTATO = ACQ.ID_PRODOTTO_ACQUISTATO
    GROUP BY
    IMP.ID_IMPORTI_RICHIESTI_PIANO,
    PER.DATA_INIZ,
    PER.DATA_FINE,
    PER.ANNO,
    PER.CICLO,
    PER.PER,
    --LORDO,
    --NETTO,
    --PERC_SC,
    NOTA
    UNION
    select IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
    PER.DATA_INIZ,
    PER.DATA_FINE,
    PER.ANNO,
    PER.CICLO,
    PER.PER,
    FU_LORDO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS LORDO,
    FU_NETTO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)    AS NETTO, 
    FU_PERC_SC_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS PERC_SC,
    0 as LORDO_EFF,
    0 as NETTO_EFF,
    0 as PERC_SC_EFF,
    NOTA
    FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
    PERIODI per,
    CD_PIANIFICAZIONE pia--,
    --CD_PRODOTTO_ACQUISTATO ACQ
    WHERE per.ANNO = IMP.ANNO
    AND per.CICLO = IMP.CICLO
    AND per.PER = IMP.PER --(+)
    AND IMP.FLG_ANNULLATO = 'N'
    AND not exists (select * from cd_prodotto_acquistato 
                    where ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
                    and cd_prodotto_acquistato.id_piano = p_id_piano and cd_prodotto_acquistato.id_ver_piano = p_id_ver_piano
                    AND FLG_ANNULLATO = 'N' AND FLG_SOSPESO = 'N' AND COD_DISATTIVAZIONE IS NULL)
    AND pia.ID_PIANO = p_id_piano
    AND pia.ID_VER_PIANO = p_id_ver_piano
    AND IMP.ID_PIANO = pia.ID_PIANO
    AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO;
    RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_PIANO_IMPORTI;

-------------------------------------------------


FUNCTION FU_GET_PERIODI_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO IS
v_periodo C_PERIODO;
BEGIN
    OPEN v_periodo FOR
select IMP.ID_IMPORTI_RICHIESTA AS ID_PERIODO_PIANO,
PER.DATA_INIZ,
PER.DATA_FINE,
PER.ANNO,
PER.CICLO,
PER.PER,
LORDO,
NETTO,
PERC_SC,
0 as LORDO_EFF,
0 as NETTO_EFF,
0 as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTA IMP,
PERIODI per,
CD_PIANIFICAZIONE pia--,
--CD_PRODOTTO_ACQUISTATO ACQ
WHERE per.ANNO = IMP.ANNO --(+)
AND per.CICLO = IMP.CICLO --(+)
AND per.PER = IMP.PER --(+)
AND IMP.FLG_ANNULLATO = 'N'
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO;
    RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_RICHIESTA;

FUNCTION FU_GET_PERIODI_SPEC_RIC(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_SPECIALE IS
v_periodo C_PERIODO_SPECIALE;
BEGIN
    OPEN v_periodo FOR
select
IMP.ID_IMPORTI_RICHIESTA as ID_PERIODO_PIANO,
PER.ID_PERIODO_SPECIALE,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
0 as LORDO_EFF,
0 as NETTO_EFF,
0 as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTA IMP,
CD_PERIODO_SPECIALE per,
CD_PIANIFICAZIONE pia--,
--CD_PRODOTTO_ACQUISTATO ACQ
WHERE per.ID_PERIODO_SPECIALE = IMP.ID_PERIODO_SPECIALE --(+)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
AND IMP.FLG_ANNULLATO = 'N';
    RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_SPEC_RIC;

FUNCTION FU_GET_PERIODI_SPEC_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_SPECIALE IS
v_periodo C_PERIODO_SPECIALE;
BEGIN
    OPEN v_periodo FOR
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO_SPECIALE,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
NVL(SUM(ACQ.IMP_LORDO),0) / 2 as LORDO_EFF,
NVL(SUM(ACQ.IMP_NETTO),0) / 2 as NETTO_EFF,
PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)) as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODO_SPECIALE per,
CD_PIANIFICAZIONE pia,
CD_PRODOTTO_ACQUISTATO ACQ,
CD_IMPORTI_PRODOTTO IMP_PR
WHERE per.ID_PERIODO_SPECIALE = IMP.ID_PERIODO_SPECIALE --(+)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
AND IMP.FLG_ANNULLATO = 'N'
AND ACQ.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
AND ACQ.FLG_ANNULLATO = 'N'
AND ACQ.FLG_SOSPESO = 'N'
AND ACQ.COD_DISATTIVAZIONE IS NULL
AND IMP_PR.ID_PRODOTTO_ACQUISTATO = ACQ.ID_PRODOTTO_ACQUISTATO
GROUP BY
IMP.ID_IMPORTI_RICHIESTI_PIANO,
PER.ID_PERIODO_SPECIALE,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
NOTA
UNION
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO_SPECIALE,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
0 as LORDO_EFF,
0 as NETTO_EFF,
0 as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODO_SPECIALE per,
CD_PIANIFICAZIONE pia--,
--CD_PRODOTTO_ACQUISTATO ACQ
WHERE per.ID_PERIODO_SPECIALE = IMP.ID_PERIODO_SPECIALE
AND IMP.FLG_ANNULLATO = 'N'
AND not exists (select * from cd_prodotto_acquistato 
               where ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO-- and DATA_FINE  =PER.data_fine
               and cd_prodotto_acquistato.id_piano = p_id_piano and cd_prodotto_acquistato.id_ver_piano = p_id_ver_piano
               AND FLG_ANNULLATO = 'N' AND FLG_SOSPESO = 'N' AND COD_DISATTIVAZIONE IS NULL)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO;
RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_SPEC_PIANO;



--------------------------------------
--Realizzatore Mauro Viel Altran Italia Giugno 2010
--Procedura aggiunta per gestire sul dettaglio di piano l'importo richiesto derivante dal prodotto richiesto. Non e stata modificata 
--la procedura FU_GET_PERIODI_SPEC_PIANO perche id_importo_richiesto_piano e utilizzato anche in altre sezioni del piano.
--

FUNCTION FU_GET_PERIODI_SPEC_PIANO_IMP(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_SPECIALE IS
v_periodo C_PERIODO_SPECIALE;
BEGIN
    OPEN v_periodo FOR
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO_SPECIALE,
PER.DATA_INIZIO,
PER.DATA_FINE,
--LORDO,
--NETTO,
--PERC_SC,
FU_LORDO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS LORDO,
FU_NETTO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)    AS NETTO, 
FU_PERC_SC_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS PERC_SC,
NVL(SUM(ACQ.IMP_LORDO),0) / 2 as LORDO_EFF,
NVL(SUM(ACQ.IMP_NETTO),0) / 2 as NETTO_EFF,
PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)) as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODO_SPECIALE per,
CD_PIANIFICAZIONE pia,
CD_PRODOTTO_ACQUISTATO ACQ,
CD_IMPORTI_PRODOTTO IMP_PR
WHERE per.ID_PERIODO_SPECIALE = IMP.ID_PERIODO_SPECIALE --(+)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
AND IMP.FLG_ANNULLATO = 'N'
AND ACQ.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
AND ACQ.FLG_ANNULLATO = 'N'
AND ACQ.FLG_SOSPESO = 'N'
AND ACQ.COD_DISATTIVAZIONE IS NULL
AND IMP_PR.ID_PRODOTTO_ACQUISTATO  = ACQ.ID_PRODOTTO_ACQUISTATO
GROUP BY
IMP.ID_IMPORTI_RICHIESTI_PIANO,
PER.ID_PERIODO_SPECIALE,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
NOTA
UNION
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO_SPECIALE,
PER.DATA_INIZIO,
PER.DATA_FINE,
--LORDO,
--NETTO,
--PERC_SC,
FU_LORDO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS LORDO,
FU_NETTO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)    AS NETTO, 
FU_PERC_SC_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS PERC_SC,
0 as LORDO_EFF,
0 as NETTO_EFF,
0 as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODO_SPECIALE per,
CD_PIANIFICAZIONE pia--,
--CD_PRODOTTO_ACQUISTATO ACQ
WHERE per.ID_PERIODO_SPECIALE = IMP.ID_PERIODO_SPECIALE
AND IMP.FLG_ANNULLATO = 'N'
AND not exists (select * from cd_prodotto_acquistato 
               where ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO-- and DATA_FINE  =PER.data_fine
               and cd_prodotto_acquistato.id_piano = p_id_piano and cd_prodotto_acquistato.id_ver_piano = p_id_ver_piano
               AND FLG_ANNULLATO = 'N' AND FLG_SOSPESO = 'N' AND COD_DISATTIVAZIONE IS NULL)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO;
RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_SPEC_PIANO_IMP;

----------------------------------

FUNCTION FU_GET_PERIODI_ISP_RIC(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_ISP IS
v_periodo C_PERIODO_ISP;
BEGIN
    OPEN v_periodo FOR
select
IMP.ID_IMPORTI_RICHIESTA as ID_PERIODO_PIANO,
PER.ID_PERIODO,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
0 as LORDO_EFF,
0 as NETTO_EFF,
0 as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTA IMP,
CD_PERIODI_CINEMA per,
CD_PIANIFICAZIONE pia--,
--CD_PRODOTTO_ACQUISTATO ACQ
WHERE per.ID_PERIODO = IMP.ID_PERIODO --(+)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
AND IMP.FLG_ANNULLATO = 'N';
    RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_ISP_RIC;

FUNCTION FU_GET_PERIODI_ISP_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_ISP IS
v_periodo C_PERIODO_ISP;
BEGIN
    OPEN v_periodo FOR
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
NVL(SUM(ACQ.IMP_LORDO),0) / 2 as LORDO_EFF,
NVL(SUM(ACQ.IMP_NETTO),0) / 2 as NETTO_EFF,
PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)) as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODI_CINEMA per,
CD_PIANIFICAZIONE pia,
CD_PRODOTTO_ACQUISTATO ACQ,
CD_IMPORTI_PRODOTTO IMP_PR
WHERE per.ID_PERIODO = IMP.ID_PERIODO --(+)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
AND IMP.FLG_ANNULLATO = 'N'
--AND ACQ.DATA_INIZIO BETWEEN PER.DATA_INIZIO AND PER.DATA_FINE
AND ACQ.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
AND ACQ.ID_PIANO = pia.ID_PIANO
AND ACQ.ID_VER_PIANO = pia.ID_VER_PIANO
AND ACQ.FLG_ANNULLATO = 'N'
AND ACQ.FLG_SOSPESO   = 'N'
AND ACQ.COD_DISATTIVAZIONE IS NULL
AND IMP_PR.ID_PRODOTTO_ACQUISTATO (+)= ACQ.ID_PRODOTTO_ACQUISTATO
GROUP BY
IMP.ID_IMPORTI_RICHIESTI_PIANO,
PER.ID_PERIODO,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
NOTA
Union
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
0 as LORDO_EFF,
0 as NETTO_EFF,
0 as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODI_CINEMA per,
CD_PIANIFICAZIONE pia--,
--CD_PRODOTTO_ACQUISTATO ACQ
WHERE per.ID_PERIODO = IMP.ID_PERIODO
AND IMP.FLG_ANNULLATO = 'N'
AND not exists (select * from cd_prodotto_acquistato 
                --where DATA_INIZIO BETWEEN PER.DATA_INIZIO AND PER.DATA_FINE -- and DATA_FINE  =PER.data_fine
                where ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
                and cd_prodotto_acquistato.id_piano = p_id_piano and cd_prodotto_acquistato.id_ver_piano = p_id_ver_piano
                AND FLG_ANNULLATO = 'N' AND FLG_SOSPESO = 'N' AND COD_DISATTIVAZIONE IS NULL)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO;
RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_ISP_PIANO;


------------------------

--------------------------------------
--Realizzatore Mauro Viel Altran Italia Giugno 2010
--Procedura aggiunta per gestire sul dettaglio di piano l'importo richiesto derivante dal prodotto richiesto. Non e stata modificata 
--la procedura FU_GET_PERIODI_ISP perche id_importo_richiesto_piano e utilizzato anche in altre sezioni del piano.
--

FUNCTION FU_GET_PERIODI_ISP_PIANO_IMP(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_PERIODO_ISP IS
v_periodo C_PERIODO_ISP;
BEGIN
    OPEN v_periodo FOR
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO,
PER.DATA_INIZIO,
PER.DATA_FINE,
--LORDO,
--NETTO,
--PERC_SC,
FU_LORDO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS LORDO,
FU_NETTO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)    AS NETTO, 
FU_PERC_SC_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS PERC_SC,
NVL(SUM(ACQ.IMP_LORDO),0) / 2 as LORDO_EFF,
NVL(SUM(ACQ.IMP_NETTO),0) / 2 as NETTO_EFF,
PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP_PR.IMP_NETTO),SUM(IMP_PR.IMP_SC_COMM)) as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODI_CINEMA per,
CD_PIANIFICAZIONE pia,
CD_PRODOTTO_ACQUISTATO ACQ,
CD_IMPORTI_PRODOTTO IMP_PR
WHERE per.ID_PERIODO = IMP.ID_PERIODO --(+)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO
AND IMP.FLG_ANNULLATO = 'N'
--AND ACQ.DATA_INIZIO BETWEEN PER.DATA_INIZIO AND PER.DATA_FINE
AND ACQ.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
AND ACQ.ID_PIANO = pia.ID_PIANO
AND ACQ.ID_VER_PIANO = pia.ID_VER_PIANO
AND ACQ.FLG_ANNULLATO = 'N'
AND ACQ.FLG_SOSPESO   = 'N'
AND ACQ.COD_DISATTIVAZIONE IS NULL
AND IMP_PR.ID_PRODOTTO_ACQUISTATO (+)= ACQ.ID_PRODOTTO_ACQUISTATO
GROUP BY
IMP.ID_IMPORTI_RICHIESTI_PIANO,
PER.ID_PERIODO,
PER.DATA_INIZIO,
PER.DATA_FINE,
LORDO,
NETTO,
PERC_SC,
NOTA
Union
select
IMP.ID_IMPORTI_RICHIESTI_PIANO AS ID_PERIODO_PIANO,
PER.ID_PERIODO,
PER.DATA_INIZIO,
PER.DATA_FINE,
--LORDO,
--NETTO,
--PERC_SC,
FU_LORDO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS LORDO,
FU_NETTO_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)    AS NETTO, 
FU_PERC_SC_RICHIESTO(IMP.ID_IMPORTI_RICHIESTI_PIANO)  AS PERC_SC,
0 as LORDO_EFF,
0 as NETTO_EFF,
0 as PERC_SC_EFF,
NOTA
FROM CD_IMPORTI_RICHIESTI_PIANO IMP,
CD_PERIODI_CINEMA per,
CD_PIANIFICAZIONE pia--,
--CD_PRODOTTO_ACQUISTATO ACQ
WHERE per.ID_PERIODO = IMP.ID_PERIODO
AND IMP.FLG_ANNULLATO = 'N'
AND not exists (select * from cd_prodotto_acquistato 
                --where DATA_INIZIO BETWEEN PER.DATA_INIZIO AND PER.DATA_FINE -- and DATA_FINE  =PER.data_fine
                where ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
                and cd_prodotto_acquistato.id_piano = p_id_piano and cd_prodotto_acquistato.id_ver_piano = p_id_ver_piano
                AND FLG_ANNULLATO = 'N' AND FLG_SOSPESO = 'N' AND COD_DISATTIVAZIONE IS NULL)
AND pia.ID_PIANO = p_id_piano
AND pia.ID_VER_PIANO = p_id_ver_piano
AND IMP.ID_PIANO = pia.ID_PIANO
AND IMP.ID_VER_PIANO = pia.ID_VER_PIANO;
RETURN v_periodo;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_PERIODI_ISP_PIANO_IMP;


------------------------

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_SOGGETTI_PIANO
--
-- DESCRIZIONE:  Restituisce la lista dei soggetti legati ad un piano
--
-- OPERAZIONI:
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT: Restitusice la lista di soggetti legati al piano
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SOGGETTI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_SOGGETTO IS

v_soggetto C_SOGGETTO;
BEGIN
        OPEN v_soggetto FOR
         SELECT id_soggetto_di_piano,  SP.int_u_cod_interl,descrizione ,nielscat.DES_CAT_MERC, nielscl.DES_CL_MERC,  SP.cod_sogg
        FROM CD_SOGGETTO_DI_PIANO SP, SOGGETTI SOG, NIELSCL, NIELSCAT
        WHERE SP.ID_PIANO = p_id_piano
        AND SP.ID_VER_PIANO = p_id_ver_piano
        AND SOG.int_u_cod_interl = SP.INT_U_COD_INTERL
        --AND SOG.COD_SOGG = SP.COD_SOGG
        AND SOG.DES_SOGG = SP.DESCRIZIONE
        and SOG.nl_cod_cl_merc = nielscl.COD_CL_MERC
        and SOG.nl_nt_cod_cat_merc = nielscat.cod_cat_merc
        and sog.FLAG_ANN = 'N'
        and nielscl.NT_COD_CAT_MERC = nielscat.COD_CAT_MERC
        union
        SELECT id_soggetto_di_piano,  SP.int_u_cod_interl,descrizione, null as des_cat_merc, null as DES_CL_MERC,  SP.cod_sogg
        FROM CD_SOGGETTO_DI_PIANO SP, SOGGETTI SOG
        WHERE SP.ID_PIANO = p_id_piano
        AND SP.ID_VER_PIANO = p_id_ver_piano
        AND SOG.int_u_cod_interl = SP.INT_U_COD_INTERL
        AND SOG.DES_SOGG = SP.DESCRIZIONE
        and sog.FLAG_ANN = 'N'
        AND (SOG.nl_cod_cl_merc IS NULL OR SOG.nl_nt_cod_cat_merc IS NULL);

    RETURN v_soggetto;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_SOGGETTI_PIANO;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_SOGGETTI_PRODOTTO
--
-- DESCRIZIONE:  Restituisce la lista dei soggetti legati ad un piano per l'associazione
--               ai prodotti
--
-- OPERAZIONI:
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT: Restitusice la lista di soggetti legati al piano
--
-- REALIZZATORE  Michele Borgogno, Altran, Ottobre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SOGGETTI_PRODOTTO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_SOGGETTO_PROD IS

v_soggetto C_SOGGETTO_PROD;
BEGIN
        OPEN v_soggetto FOR
           SELECT id_soggetto_di_piano,int_u_cod_interl,descrizione,perc_distribuzione,NULL, NULL
         --   nielscat.DES_CAT_MERC, nielscl.DES_CL_MERC
        FROM CD_SOGGETTO_DI_PIANO --NIELSCAT, NIELSCL,
        WHERE ID_PIANO = p_id_piano
        AND ID_VER_PIANO = p_id_ver_piano;
     --   AND CATEGORIA_MERCEOLOGICA= NIELSCAT.COD_CAT_MERC (+);
    RETURN v_soggetto;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_SOGGETTI_PRODOTTO;

FUNCTION FU_GET_FORMATI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_FORMATI IS
v_formati C_FORMATI;
BEGIN
        OPEN v_formati FOR
           SELECT CD_FORMATI_PIANO.ID_FORMATO, CD_COEFF_CINEMA.DURATA
        FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE, CD_FORMATI_PIANO
        WHERE CD_FORMATI_PIANO.ID_PIANO = p_id_piano
        AND CD_FORMATI_PIANO.ID_VER_PIANO = p_id_ver_piano
        AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_FORMATI_PIANO.ID_FORMATO
        AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF
        ORDER BY CD_COEFF_CINEMA.DURATA;
    RETURN v_formati;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_FORMATI_PIANO;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_RAGGRUPPAMENTI_PIANO
--
-- DESCRIZIONE:  Restituisce la lista dei raggruppamenti di intermediari legati ad un piano
--
-- OPERAZIONI:
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT: Restituisce la lista dei raggruppamenti di intermediari legati ad un piano
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RAGGRUPPAMENTI_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_RAGGRUPPAMENTO IS

v_raggr C_RAGGRUPPAMENTO;
BEGIN
        OPEN v_raggr FOR
        SELECT
            R.ID_RAGGRUPPAMENTO,
            R.DATA_DECORRENZA,
            R.ID_AGENZIA,
            I1.RAG_SOC_COGN AS NOME_AGENZIA,
            R.ID_CENTRO_MEDIA,
            I2.RAG_SOC_COGN AS NOME_CENTRO_MEDIA,
            R.ID_VENDITORE_CLIENTE,
            I3.RAG_SOC_COGN AS NOME_VEN_CLIENTE,
            R.PROGRESSIVO AS PROGRESSIVO
--            R.ID_VENDITORE_PRODOTTO, I4.RAG_SOC_COGN AS NOME_VEN_PRODOTTO
        FROM CD_RAGGRUPPAMENTO_INTERMEDIARI R,
             INTERL_U I1,
             INTERL_U I2,
             INTERL_U I3--,
             --INTERL_U I4
        WHERE ID_PIANO = p_id_piano
        AND ID_VER_PIANO = p_id_ver_piano
        AND R.ID_AGENZIA = I1.COD_INTERL (+)
        AND R.ID_CENTRO_MEDIA = I2.COD_INTERL (+)
        AND R.ID_VENDITORE_CLIENTE = I3.COD_INTERL (+)
        ORDER BY PROGRESSIVO;
--        AND R.ID_VENDITORE_PRODOTTO = I4.COD_INTERL (+);
    RETURN v_raggr;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_RAGGRUPPAMENTI_PIANO;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_ULTIMA_PIANO
--
-- DESCRIZIONE: Imposta un piano come ultiamto o in lavorazione
--
-- OPERAZIONI:
--   1) A seconda del parametro di input imposta un piano a "ultimato" o "in lavorazione"
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT:
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ULTIMA_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, p_tipo_elaborazione VARCHAR2) IS
v_stato_lav CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE := 2;
BEGIN
    IF p_tipo_elaborazione = 'IN_LAVORAZIONE' THEN
        v_stato_lav := 1;
    END IF;
    UPDATE CD_PIANIFICAZIONE SET ID_STATO_LAV = v_stato_lav
    WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
    AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano;
EXCEPTION
WHEN OTHERS THEN
 raise_application_error(-20001, 'PR_ULTIMA_PIANO: errore non atteso, controllare i parametri di input: p_tipo_elaborazione:'||p_tipo_elaborazione||'p_id_piano'||p_id_piano);
END PR_ULTIMA_PIANO;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_MODIFICA_IMPORTO_PIANO
--
-- DESCRIZIONE: procedura che effettua la modifica di un piano
--
-- OPERAZIONI:
--   1)
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT: -2 Errore
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_IMPORTO_PIANO(P_ID_IMPORTO CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE, P_LORDO CD_IMPORTI_RICHIESTI_PIANO.LORDO%TYPE, P_NETTO CD_IMPORTI_RICHIESTI_PIANO.NETTO%TYPE, P_SCONTO CD_IMPORTI_RICHIESTI_PIANO.PERC_SC%TYPE) IS
BEGIN
      UPDATE CD_IMPORTI_RICHIESTI_PIANO IMP
      SET LORDO = P_LORDO, NETTO = P_NETTO, PERC_SC = P_SCONTO
      WHERE IMP.ID_IMPORTI_RICHIESTI_PIANO = P_ID_IMPORTO;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END PR_MODIFICA_IMPORTO_PIANO;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_MODIFICA_IMPORTO_RICHIESTA
--
-- DESCRIZIONE: procedura che effettua la modifica dell'importo di una richiesta
--
-- OPERAZIONI:
--   1)
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT: -2 Errore
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_IMPORTO_RICHIESTA(P_ID_IMPORTO CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE, P_LORDO CD_IMPORTI_RICHIESTA.LORDO%TYPE, P_NETTO CD_IMPORTI_RICHIESTA.NETTO%TYPE, P_SCONTO CD_IMPORTI_RICHIESTA.PERC_SC%TYPE) IS
BEGIN
      UPDATE CD_IMPORTI_RICHIESTA IMP
      SET LORDO = P_LORDO, NETTO = P_NETTO, PERC_SC = P_SCONTO
      WHERE IMP.ID_IMPORTI_RICHIESTA = P_ID_IMPORTO;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END PR_MODIFICA_IMPORTO_RICHIESTA;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_MODIFICA_PIANO
--
-- DESCRIZIONE: procedura che effettua la modifica di un piano
--
-- OPERAZIONI:
--   1)
-- INPUT:  Id del piano, id Versione del piano
-- OUTPUT:   1 Piano modificato correttamente
--          -1 Errore generico
--          -2 Modifica dello stato di vendita non valido
--          -3 Modifica del cliente commerciale non possibile per l'esistenza dell'ordine
--
-- REALIZZATORE  Simone Bottani, Altran, Agosto 2009
--
--  MODIFICHE:
--  16/02/2010 Michele Borgogno. Aggiunta la modifica del fruitore, del soggetto e del materiale di
--      piano nel caso in cui sia variato il cliente.
--  11/06/2010 Michele borgogno. Aggiunta chiamata a verifica_tutela.
--  27/09/2010 Mauro Viel (MV01) eliminato il controllo sulla presenza di ordino nel caso in cui varia solo il responsabile di contatto.
--  17/02/2010 Mauro Viel inserita la gestione del dgc al variare della testata editoriale
--  20/06/2011 Mauro Viel inserto il parametro tipo_contratto
-- --------------------------------------------------------------------------------------------

PROCEDURE PR_MODIFICA_PIANO(
                                    p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                    p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                    p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                    p_id_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                    p_lista_periodi  periodo_list_type,
                                    p_lista_intermediari intermediario_list_type,
                                    p_lista_soggetti soggetto_list_type,
                                    p_id_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                    p_cod_testata CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE%TYPE,
                                    p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                    p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                                    p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                                    p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                                    p_tipo_contratto CD_PIANIFICAZIONE.TIPO_CONTRATTO%TYPE,
                                    p_esito OUT NUMBER) IS

v_num_ordini NUMBER;
v_num_fruitori NUMBER;
v_id_vecchio_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE;
v_id_cliente_fruitore CD_FRUITORI_DI_PIANO.ID_CLIENTE_FRUITORE%TYPE;
v_cod_testata_editoriale cd_pianificazione.COD_TESTATA_EDITORIALE%TYPE;
v_cod_sogg_non_def NUMBER;
v_sogg_non_def R_SOGGETTO;
v_id_sogg_piano cd_soggetto_di_piano.ID_SOGGETTO_DI_PIANO%TYPE;
v_vecchio_id_resp_contatto  cd_pianificazione.ID_RESPONSABILE_CONTATTO%TYPE;
v_sala_arena varchar2(10);
v_id_tipo_pubb CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE;
v_dgc CD_PRODOTTO_ACQUISTATO.DGC%TYPE;
v_dgc_tc_id_C CD_IMPORTI_PRODOTTO.DGC_TC_ID%TYPE;
v_dgc_tc_id_D CD_IMPORTI_PRODOTTO.DGC_TC_ID%TYPE;
BEGIN
p_esito := 1;
SAVEPOINT PR_MODIFICA_PIANO;

    SELECT COUNT(1) INTO v_num_ordini FROM CD_ORDINE WHERE id_piano = p_id_piano
        AND id_ver_piano = p_id_ver_piano
        AND FLG_SOSPESO = 'N'
        AND FLG_ANNULLATO = 'N';
    SELECT ID_CLIENTE INTO v_id_vecchio_cliente FROM CD_PIANIFICAZIONE WHERE ID_PIANO = p_id_piano
        AND ID_VER_PIANO = P_ID_VER_PIANO;


   SELECT id_responsabile_contatto INTO v_vecchio_id_resp_contatto FROM CD_PIANIFICAZIONE WHERE ID_PIANO = p_id_piano
   AND ID_VER_PIANO = P_ID_VER_PIANO;
   
   --MV01 Inizio
   IF (p_id_responsabile_contatto <> v_vecchio_id_resp_contatto and p_id_cliente = v_id_vecchio_cliente) then
       v_num_ordini := 0;
   end if;
   --MV01 Fine 

    IF (v_num_ordini <> 0 and (p_id_cliente <> v_id_vecchio_cliente or p_id_responsabile_contatto <> v_vecchio_id_resp_contatto ))THEN
        p_esito := -3;
    ELSE

        IF p_id_cliente IS NOT NULL AND p_id_responsabile_contatto IS NOT NULL THEN
            
            select cod_testata_editoriale
            into v_cod_testata_editoriale
            from cd_pianificazione
            where id_piano = p_id_piano
            and   id_ver_piano = p_id_ver_piano;
            
            UPDATE CD_PIANIFICAZIONE SET ID_CLIENTE = p_id_cliente,
                 ID_RESPONSABILE_CONTATTO = p_id_responsabile_contatto,
                 COD_TESTATA_EDITORIALE = NVL(p_cod_testata,COD_TESTATA_EDITORIALE),
                 COD_AREA = p_cod_area,
                 COD_SEDE = p_cod_sede,
                 FLG_SIPRA_LAB = NVL(p_sipra_lab,FLG_SIPRA_LAB),
                 FLG_CAMBIO_MERCE = NVL(p_cambio_merce, FLG_CAMBIO_MERCE),
                 TIPO_CONTRATTO = NVL(p_tipo_contratto,TIPO_CONTRATTO)
            WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
            AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano;
            
            IF v_cod_testata_editoriale <> p_cod_testata THEN
                
                BEGIN
                    for c in 
                    (select id_prodotto_acquistato, id_prodotto_vendita
                            from cd_prodotto_acquistato
                            where id_piano = p_id_piano
                            and   id_ver_piano = p_id_ver_piano
                            and   flg_annullato =  'N'
                            and   flg_annullato =  'N'
                            and   cod_disattivazione is null
                    )
                    loop
                        SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB,DECODE(FLG_ARENA,'S', 'ARENA','SALA')
                        INTO  v_id_tipo_pubb,v_sala_arena
                        FROM  CD_PRODOTTO_VENDITA,CD_CIRCUITO
                        WHERE CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = c.id_prodotto_vendita
                        AND   CD_CIRCUITO.ID_CIRCUITO = CD_PRODOTTO_VENDITA.ID_CIRCUITO;
        --
                        v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, p_cod_testata,v_sala_arena);
                        
                    
                        update  cd_prodotto_acquistato
                        set  DGC = v_dgc
                        where id_prodotto_acquistato = c.id_prodotto_acquistato
                        and   flg_annullato =  'N'
                        and   flg_annullato =  'N'
                        and   cod_disattivazione is null;

                        v_dgc_tc_id_C := FU_CD_GET_DGC_TC(v_dgc, 'C');
                       
                    
                        update  cd_importi_prodotto 
                        set dgc_tc_id = v_dgc_tc_id_C
                        where  id_prodotto_acquistato = c.id_prodotto_acquistato
                        and  tipo_contratto = 'C';

                        v_dgc_tc_id_D := FU_CD_GET_DGC_TC(v_dgc, 'D');
                        
                    
                        update  cd_importi_prodotto 
                        set dgc_tc_id = v_dgc_tc_id_D
                        where  id_prodotto_acquistato = c.id_prodotto_acquistato
                        and  tipo_contratto = 'D';
                        
                     end loop;
                     
                END;
            
            END IF;
        END IF;
        IF p_id_stato_vendita IS NOT NULL THEN
            FOR TEMP IN
              (SELECT ID_STATO_VENDITA, STATI_SUCCESSIVI
                FROM CD_STATO_DI_VENDITA, CD_PRODOTTO_ACQUISTATO
                WHERE CD_PRODOTTO_ACQUISTATO.ID_PIANO = p_id_piano
                AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = p_id_ver_piano
                AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
                AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
                AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL
                AND CD_STATO_DI_VENDITA.DESCR_BREVE = CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)LOOP
                IF (instr(TEMP.STATI_SUCCESSIVI,p_id_stato_vendita) = 0) THEN
                    p_esito := -2;
                    EXIT;
                END IF;
            END LOOP;
    		IF p_esito >=0 THEN
                PR_SALVA_STATI_VENDITA_PIANO(p_id_piano, p_id_ver_piano, p_id_stato_vendita);
            END IF;
        END IF;

        IF (p_id_cliente <> v_id_vecchio_cliente) THEN
                --Aggiornamento dei fruitori di piano nel caso in cui venga modificato il cliente
                --L'update viene effettuato anche sui prodotti non validi per gestire la possibilita di recupero dei comunicati
                UPDATE CD_PRODOTTO_ACQUISTATO SET ID_FRUITORI_DI_PIANO = NULL
                    WHERE ID_PIANO = p_id_piano
                    AND ID_VER_PIANO = p_id_ver_piano;
    --
                DELETE FROM CD_FRUITORI_DI_PIANO
                    WHERE ID_PIANO = p_id_piano
                    AND ID_VER_PIANO = p_id_ver_piano;

                v_id_cliente_fruitore := pa_cd_pianificazione.FU_VERIFICA_FRUITORE_CLIENTE(p_id_cliente, sysdate);
                --dbms_output.put_line('v_id_cliente_fruitore = '||v_id_cliente_fruitore);
                IF (v_id_cliente_fruitore is not null) THEN
                    pa_cd_pianificazione.PR_INSERISCI_FRUITORE_PIANO(p_id_piano, p_id_ver_piano, v_id_cliente_fruitore, sysdate);
                    UPDATE CD_PRODOTTO_ACQUISTATO
                        SET ID_FRUITORI_DI_PIANO = (SELECT id_fruitori_di_piano from cd_fruitori_di_piano
                            WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano and rownum = 1)
                        WHERE ID_PIANO = p_id_piano
                        AND ID_VER_PIANO = p_id_ver_piano;
                ELSE
                    UPDATE CD_PRODOTTO_ACQUISTATO
                        SET ID_FRUITORI_DI_PIANO = NULL
                        WHERE ID_PIANO = p_id_piano
                        AND ID_VER_PIANO = p_id_ver_piano;
                END IF;
                --Aggiornamento dei soggetti e dei materiali di piano nel caso in cui venga modificato il cliente
                --Viene inserito fra i soggetti di piano il soggetto non definito del nuovo cliente

                UPDATE  CD_COMUNICATO
                    SET ID_SOGGETTO_DI_PIANO = null, ID_MATERIALE_DI_PIANO = null
                    WHERE id_prodotto_acquistato IN (SELECT id_prodotto_acquistato
                        FROM CD_PRODOTTO_ACQUISTATO
                        WHERE id_piano = p_id_piano
                        AND id_ver_piano= p_id_ver_piano);

                DELETE FROM CD_MATERIALE_DI_PIANO WHERE ID_PIANO = p_id_piano
                    AND ID_VER_PIANO = p_id_ver_piano;
                DELETE FROM CD_SOGGETTO_DI_PIANO WHERE ID_PIANO = p_id_piano
                    AND ID_VER_PIANO = p_id_ver_piano;

                v_sogg_non_def := PA_CD_PIANIFICAZIONE.FU_GET_SOGGETTO_NON_DEF(p_id_cliente);
                --dbms_output.put_line('v_sogg_non_def_descrizione = '||v_sogg_non_def.a_descrizione);
                --dbms_output.put_line('v_sogg_non_def_int_u_cod_interl = '||v_sogg_non_def.a_int_u_cod_interl);
                --dbms_output.put_line('v_sogg_non_def_cod_sogg = '||v_sogg_non_def.a_cod_sogg);
                INSERT INTO CD_SOGGETTO_DI_PIANO(ID_PIANO, ID_VER_PIANO, DESCRIZIONE,INT_U_COD_INTERL,
                                                 COD_SOGG)
                    VALUES(p_id_piano, p_id_ver_piano, v_sogg_non_def.a_descrizione,v_sogg_non_def.a_int_u_cod_interl,
                           v_sogg_non_def.a_cod_sogg);

                SELECT id_soggetto_di_piano into v_id_sogg_piano from cd_soggetto_di_piano
                WHERE id_piano = p_id_piano
                and id_ver_piano = p_id_ver_piano
                and rownum = 1;
                --dbms_output.put_line('v_id_sogg_piano = '||v_id_sogg_piano);

                FOR PA IN (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO, PR_ACQ.DATA_INIZIO, PR_ACQ.DATA_FINE
                    FROM CD_PRODOTTO_ACQUISTATO PR_ACQ
                    WHERE PR_ACQ.ID_PIANO = p_id_piano
                    AND PR_ACQ.ID_VER_PIANO = p_id_ver_piano)
     --               AND PR_ACQ.FLG_ANNULLATO = 'N'
     --               AND PR_ACQ.FLG_SOSPESO = 'N'
     --               AND PR_ACQ.COD_DISATTIVAZIONE IS NULL
                    LOOP
                    PA_CD_PRODOTTO_ACQUISTATO.PR_ASSOCIA_SOGGETTO_PRODOTTO(PA.ID_PRODOTTO_ACQUISTATO, v_id_sogg_piano, p_esito);
                    PA_CD_PRODOTTO_ACQUISTATO.PR_ASSOCIA_MATERIALE_PRODOTTO(PA.ID_PRODOTTO_ACQUISTATO, null, p_esito);
                END LOOP;
                --
                PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(p_id_piano, p_id_ver_piano,p_id_cliente, null, null);
                --
                FOR ORD IN (SELECT ID_ORDINE FROM CD_ORDINE
                            WHERE ID_PIANO = p_id_piano
                            AND ID_VER_PIANO = p_id_ver_piano
                            AND FLG_ANNULLATO = 'N') LOOP
                    PA_CD_ORDINE.PR_ANNULLA_ORDINE(ORD.ID_ORDINE, p_esito);
                END LOOP;
        END IF;
    END IF;
    /*ELSE
        p_esito := -3;
    END IF;*/
/*IF p_esito >=0 THEN
    PR_INSERISCI_IMPORTI_PIANO(p_id_piano, p_id_ver_piano,p_lista_periodi);
    PR_INSERISCI_INTERMEDIARI(p_id_piano, p_id_ver_piano,p_lista_intermediari);
    PR_INSERISCI_SOGGETTI(p_id_piano, p_id_ver_piano,p_lista_soggetti);
END IF;*/
EXCEPTION
WHEN OTHERS THEN
RAISE;
p_esito := -1;
ROLLBACK TO PR_MODIFICA_PIANO;
END PR_MODIFICA_PIANO;

FUNCTION FU_GET_NOME_CLIENTE(p_id_cliente INTERL_U.COD_INTERL%TYPE) RETURN CHAR IS
v_nome INTERL_U.RAG_SOC_COGN%TYPE;
BEGIN
     SELECT RAG_SOC_COGN INTO v_nome
     FROM INTERL_U
     WHERE COD_INTERL = p_id_cliente;
   RETURN v_nome;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_NOME_CLIENTE;

FUNCTION FU_GET_STATO_VEN_COMUNICATI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN VARCHAR IS

v_num_stati NUMBER;
v_stati_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
BEGIN
    v_stati_vendita := '';

    SELECT COUNT(DISTINCT(CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)) INTO v_num_stati
    FROM
    CD_PRODOTTO_ACQUISTATO, CD_PIANIFICAZIONE
    WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
    AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
    AND CD_PRODOTTO_ACQUISTATO.ID_PIANO = CD_PIANIFICAZIONE.ID_PIANO
    AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = CD_PIANIFICAZIONE.ID_VER_PIANO
    AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
    AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
    AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL;

    IF v_num_stati = 1 THEN
        SELECT DESCR_BREVE INTO v_stati_vendita
        FROM CD_STATO_DI_VENDITA
        WHERE DESCR_BREVE =
       (SELECT DISTINCT(CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA)
        FROM
        CD_PRODOTTO_ACQUISTATO, CD_PIANIFICAZIONE
        WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
        AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
        AND CD_PRODOTTO_ACQUISTATO.ID_PIANO = CD_PIANIFICAZIONE.ID_PIANO
        AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = CD_PIANIFICAZIONE.ID_VER_PIANO
        AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
        AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
        AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL);
    ELSIF v_num_stati > 1 THEN
        v_stati_vendita := '*';
    END IF;
  RETURN v_stati_vendita;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_STATO_VEN_COMUNICATI;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA    PR_SALVA_STATI_VENDITA_PIANO
--
-- DESCRIZIONE: Modifica lo stato di vendita di
--              tutti i prodotti acquistati di un piano
--
-- OPERAZIONI:
--   1) A seconda del parametro di input imposta un piano a "ultimato" o "in lavorazione"
-- INPUT:  Id del piano, id Versione del piano, Id di stato di vendita
-- OUTPUT:
--
-- REALIZZATORE  Simone Bottani, Altran, Settembre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------

PROCEDURE PR_SALVA_STATI_VENDITA_PIANO(
                                 p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                 p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                 p_id_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) IS
--
v_nuovo_stato CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
BEGIN
    SAVEPOINT PR_SALVA_STATI_VENDITA_PIANO;
    --
    SELECT DESCR_BREVE
    INTO v_nuovo_stato
    FROM CD_STATO_DI_VENDITA
    WHERE ID_STATO_VENDITA = p_id_stato_vendita;
    --
    FOR PRD IN(SELECT ID_PRODOTTO_ACQUISTATO FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PIANO = p_id_piano
        AND ID_VER_PIANO = p_id_ver_piano
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL)
    LOOP
        PA_CD_PRODOTTO_ACQUISTATO.PR_MODIFICA_STATO_VENDITA(PRD.ID_PRODOTTO_ACQUISTATO,v_nuovo_stato);
    END LOOP;

    /*
    SELECT DESCR_BREVE
    INTO v_nuovo_stato
    FROM CD_STATO_DI_VENDITA
    WHERE ID_STATO_VENDITA = p_id_stato_vendita;
--
    UPDATE CD_PRODOTTO_ACQUISTATO SET
    STATO_DI_VENDITA = v_nuovo_stato
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PIANO = p_id_piano
    AND  CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = p_id_ver_piano
    AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
    AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
    AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL;
--
    --IF v_nuovo_stato = 'PRE' THEN
     IF v_nuovo_stato = 'PRE'  and  v_vecchio_stato_ven != 'PRE' THEN
--
    UPDATE CD_PIANIFICAZIONE
    SET DATA_PRENOTAZIONE = SYSDATE
    WHERE ID_PIANO =p_id_piano
    AND   ID_VER_PIANO =p_id_ver_piano;
--
    FOR PRD IN(SELECT * FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PIANO = p_id_piano
        AND ID_VER_PIANO = p_id_ver_piano
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL)
    LOOP
        PA_CD_PRODOTTO_ACQUISTATO.PR_IMPOSTA_POSIZIONE(PRD.ID_PRODOTTO_ACQUISTATO,NULL);
    END LOOP;
    END IF;
    */
EXCEPTION
WHEN OTHERS THEN
    ROLLBACK TO PR_SALVA_STATI_VENDITA_PIANO;
RAISE;
END PR_SALVA_STATI_VENDITA_PIANO;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_RAGGRUPPAMENTO
--
-- DESCRIZIONE:  Restituisce un intermediario dato il suo id
--
-- OPERAZIONI:
-- INPUT:  Id del raggruppamento
-- OUTPUT: Restituisce l'intermediario
--
-- REALIZZATORE  Simone Bottani, Altran, Ottobre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RAGGRUPPAMENTO(p_id_raggruppamento CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE) RETURN C_RAGGRUPPAMENTO IS

v_raggr C_RAGGRUPPAMENTO;
BEGIN
        OPEN v_raggr FOR
        SELECT
            R.ID_RAGGRUPPAMENTO,
            R.DATA_DECORRENZA,
            R.ID_AGENZIA,
            I1.RAG_SOC_COGN AS NOME_AGENZIA,
            R.ID_CENTRO_MEDIA,
            I2.RAG_SOC_COGN AS NOME_CENTRO_MEDIA,
            R.ID_VENDITORE_CLIENTE,
            I3.RAG_SOC_COGN AS NOME_VEN_CLIENTE,
            R.PROGRESSIVO AS PROGRESSIVO
            --R.ID_VENDITORE_PRODOTTO,
            --I4.RAG_SOC_COGN AS NOME_VEN_PRODOTTO
        FROM CD_RAGGRUPPAMENTO_INTERMEDIARI R,
             INTERL_U I1,
             INTERL_U I2,
             INTERL_U I3,
             INTERL_U I4
        WHERE R.ID_RAGGRUPPAMENTO = p_id_raggruppamento
        AND R.ID_AGENZIA = I1.COD_INTERL (+)
        AND R.ID_CENTRO_MEDIA = I2.COD_INTERL (+)
        AND R.ID_VENDITORE_CLIENTE = I3.COD_INTERL (+);
        --AND R.ID_VENDITORE_PRODOTTO = I4.COD_INTERL (+);
    RETURN v_raggr;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_RAGGRUPPAMENTO;


PROCEDURE PR_SALVA_SOGG_PIANO(p_id_piano CD_SOGGETTO_DI_PIANO.ID_PIANO%TYPE,p_id_ver_piano CD_SOGGETTO_DI_PIANO.ID_VER_PIANO%TYPE,p_cliente CD_SOGGETTO_DI_PIANO.INT_U_COD_INTERL%TYPE, p_descrizione CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE, p_cod_sogg CD_SOGGETTO_DI_PIANO.COD_SOGG%TYPE, p_id_soggetto OUT CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE)is
v_exist number;
begin
select count(1)
into v_exist
from   CD_SOGGETTO_DI_PIANO
where  ID_PIANO         = p_id_piano
and    ID_VER_PIANO     = p_id_ver_piano
and    INT_U_COD_INTERL = p_cliente
and    DESCRIZIONE      = p_descrizione
and    COD_SOGG         = p_cod_sogg;
if v_exist =0 then
insert into CD_SOGGETTO_DI_PIANO (ID_PIANO,ID_VER_PIANO,INT_U_COD_INTERL,DESCRIZIONE, COD_SOGG)
                          values (p_id_piano,p_id_ver_piano,p_cliente,p_descrizione, p_cod_sogg);

       SELECT CD_SOGGETTO_DI_PIANO_SEQ.CURRVAL INTO p_id_soggetto FROM DUAL;
end if;
EXCEPTION
WHEN OTHERS THEN
RAISE;
end PR_SALVA_SOGG_PIANO;

PROCEDURE PR_ELIMINA_SOGG_PIANO(p_id_sogg_piano CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE) IS

BEGIN

    UPDATE CD_COMUNICATO SET ID_SOGGETTO_DI_PIANO = null
        WHERE ID_SOGGETTO_DI_PIANO = p_id_sogg_piano
        AND
        (FLG_ANNULLATO = 'S' OR FLG_SOSPESO = 'S' OR COD_DISATTIVAZIONE IS NOT NULL);

	DELETE FROM CD_SOGGETTO_DI_PIANO
	WHERE ID_SOGGETTO_DI_PIANO = p_id_sogg_piano;

    delete from cd_materiale_di_piano
    where id_materiale_di_piano in (
         select mat_pia.id_materiale_di_piano from cd_materiale_di_piano mat_pia, cd_materiale mat,
             cd_materiale_soggetti mat_sogg, soggetti sogg, cd_soggetto_di_piano sogg_pia
             where mat_pia.id_materiale =  mat.id_materiale
             and   mat.id_materiale = mat_sogg.id_materiale
             and   mat_sogg.cod_sogg = sogg.cod_sogg
             and   sogg.cod_sogg = sogg_pia.cod_sogg
             and   sogg_pia.id_soggetto_di_piano = p_id_sogg_piano);

EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_ELIMINA_SOGG_PIANO;

PROCEDURE PR_ELIMINA_MAT_PIANO(p_id_mat_piano CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE, p_esito OUT NUMBER)IS

v_count NUMBER;

BEGIN

    update cd_comunicato set id_materiale_di_piano = null
    where id_materiale_di_piano = p_id_mat_piano
    and (flg_annullato = 'S' or flg_sospeso = 'S' or cod_disattivazione is not null);

    select count(1) into v_count 
    from cd_comunicato c ,cd_prodotto_acquistato p
    where c.id_materiale_di_piano = p_id_mat_piano
    and   p.id_prodotto_acquistato = c.id_prodotto_acquistato
    and   p.flg_annullato='N'
    and   p.flg_sospeso='N'
    and   p.cod_disattivazione is null
    and   c.flg_annullato='N'
    and   c.flg_sospeso='N'
    and   p.cod_disattivazione is null;
    

    if v_count = 0 then
    	DELETE FROM CD_MATERIALE_DI_PIANO
    	WHERE ID_MATERIALE_DI_PIANO = p_id_mat_piano;
    end if;

    p_esito := v_count;

EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_ELIMINA_MAT_PIANO;


PROCEDURE PR_ELIMINA_RAGGR_PIANO(p_id_raggr_piano CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE,
                                 p_id_piano CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
                                 p_esito OUT NUMBER) IS

v_count NUMBER;
BEGIN
    SELECT count(1) into v_count FROM CD_RAGGRUPPAMENTO_INTERMEDIARI 
    WHERE ID_PIANO = p_id_piano;
   
    IF v_count > 1 THEN
	    DELETE CD_RAGGRUPPAMENTO_INTERMEDIARI
	    WHERE ID_RAGGRUPPAMENTO = p_id_raggr_piano;
    END IF;
    
    p_esito := v_count;
EXCEPTION
	  WHEN OTHERS THEN
	  RAISE;
END PR_ELIMINA_RAGGR_PIANO;


FUNCTION FU_GET_DESC_SOGGETTO(p_id_soggetto SOGGETTI.COD_SOGG%TYPE) RETURN VARCHAR IS

v_ret VARCHAR2(25);

BEGIN
        SELECT des_sogg
        INTO   v_ret
        FROM   SOGGETTI
        WHERE  COD_SOGG = p_id_soggetto;

RETURN v_ret;

EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_DESC_SOGGETTO;

FUNCTION FU_GET_FRUITORI_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE, P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN C_FRUITORE_DI_PIANO IS
v_fruitore C_FRUITORE_DI_PIANO;
BEGIN
        OPEN v_fruitore FOR
        SELECT
        FR.ID_FRUITORE,
        FP.ID_FRUITORI_DI_PIANO,
        FR.RAG_SOC_COGN,
        FR.RAG_SOC_BR_NOME,
        FR.LOCALITA,
        FR.INDIRIZZO,
        get_desc_area(FR.AREA) as desc_area,
        get_desc_sedi(FR.SEDE) as desc_sede,
        FP.DATA_DECORRENZA,
        FP.PROGRESSIVO
        FROM
        VI_CD_CLIENTE_FRUITORE FR,
        CD_FRUITORI_DI_PIANO FP
        WHERE FP.ID_PIANO = P_ID_PIANO
        AND FP.ID_VER_PIANO = P_ID_VER_PIANO
        AND FP.ID_CLIENTE_FRUITORE = FR.ID_FRUITORE
        ORDER BY FP.PROGRESSIVO;
    RETURN v_fruitore;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_FRUITORI_PIANO;

FUNCTION FU_GET_FRUITORI_CLIENTE(P_ID_CLIENTE CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, P_DATA_DECORRENZA RAGGRUPPAMENTO_U.DT_INIZ_VAL%TYPE) RETURN C_FRUITORE IS
v_fruitore C_FRUITORE;
BEGIN
        OPEN v_fruitore FOR
        SELECT
        FR.ID_FRUITORE,
        FR.RAG_SOC_COGN,
        FR.RAG_SOC_BR_NOME,
        FR.LOCALITA,
        FR.INDIRIZZO,
        get_desc_area(FR.AREA) as desc_area,
        get_desc_sedi(FR.SEDE) as desc_sede
        FROM
        VI_CD_CLIENTE_FRUITORE FR,
        RAGGRUPPAMENTO_U RAG
        WHERE RAG.tipo_raggrupp='CCCL'
        AND RAG.COD_INTERL_P = P_ID_CLIENTE
        AND RAG.COD_INTERL_F = FR.ID_FRUITORE
        AND P_DATA_DECORRENZA BETWEEN RAG.DT_INIZ_VAL AND RAG.DT_FINE_VAL;
    RETURN v_fruitore;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_FRUITORI_CLIENTE;

FUNCTION FU_VERIFICA_FRUITORE_CLIENTE(P_ID_CLIENTE CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, P_DATA_DECORRENZA RAGGRUPPAMENTO_U.DT_INIZ_VAL%TYPE) RETURN CD_FRUITORI_DI_PIANO.ID_CLIENTE_FRUITORE%TYPE IS
v_id_fruitore CD_FRUITORI_DI_PIANO.ID_CLIENTE_FRUITORE%TYPE;
v_num_fruitori NUMBER;
BEGIN

    SELECT COUNT(1) INTO v_num_fruitori
        FROM VI_CD_CLIENTE_FRUITORE FR, RAGGRUPPAMENTO_U RAG
        WHERE RAG.tipo_raggrupp='CCCL'
        AND RAG.COD_INTERL_P = P_ID_CLIENTE
        AND RAG.COD_INTERL_F = FR.ID_FRUITORE
        AND SYSDATE BETWEEN RAG.DT_INIZ_VAL AND RAG.DT_FINE_VAL;
--    GROUP BY ID_FRUITORE;

    IF (v_num_fruitori = 1) THEN
        SELECT id_fruitore INTO v_id_fruitore
            FROM VI_CD_CLIENTE_FRUITORE FR, RAGGRUPPAMENTO_U RAG
            WHERE RAG.tipo_raggrupp='CCCL'
            AND RAG.COD_INTERL_P = P_ID_CLIENTE
            AND RAG.COD_INTERL_F = FR.ID_FRUITORE
            AND SYSDATE BETWEEN RAG.DT_INIZ_VAL AND RAG.DT_FINE_VAL;
        RETURN v_id_fruitore;
    ELSE
        RETURN null;
    END IF;

EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_VERIFICA_FRUITORE_CLIENTE;

PROCEDURE PR_INSERISCI_FRUITORE_PIANO(p_id_piano CD_FRUITORI_DI_PIANO.ID_PIANO%TYPE,p_id_ver_piano CD_FRUITORI_DI_PIANO.ID_VER_PIANO%TYPE,p_id_fruitore CD_FRUITORI_DI_PIANO.ID_CLIENTE_FRUITORE%TYPE,p_data_decorrenza cd_fruitori_di_piano.data_decorrenza%type) IS
BEGIN
    INSERT INTO CD_FRUITORI_DI_PIANO(ID_PIANO, ID_VER_PIANO, ID_CLIENTE_FRUITORE,DATA_DECORRENZA)
    VALUES (p_id_piano, p_id_ver_piano, p_id_fruitore,p_data_decorrenza);
EXCEPTION
WHEN OTHERS THEN
RAISE;
END PR_INSERISCI_FRUITORE_PIANO;

PROCEDURE PR_ELIMINA_FRUITORE_PIANO(p_id_piano CD_FRUITORI_DI_PIANO.ID_PIANO%TYPE,p_id_ver_piano CD_FRUITORI_DI_PIANO.ID_VER_PIANO%TYPE,p_id_fruitore_di_piano CD_FRUITORI_DI_PIANO.ID_FRUITORI_DI_PIANO%TYPE) IS
BEGIN
    DELETE FROM CD_FRUITORI_DI_PIANO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano
    AND ID_FRUITORI_DI_PIANO = p_id_fruitore_di_piano;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END PR_ELIMINA_FRUITORE_PIANO;

--- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_CLIENTE_FRUITORE
--
-- DESCRIZIONE:  Restituisce un cliente fruitore dato il suo id_fruitore_di_piano
--
-- OPERAZIONI:
-- INPUT:  Id fruitore di piano
-- OUTPUT: Restituisce il cliente fruitore del prodotto acquistato
--
-- REALIZZATORE  Michele Borgogno, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_CLIENTE_FRUITORE(p_id_fruitore_di_piano CD_FRUITORI_DI_PIANO.ID_FRUITORI_DI_PIANO%TYPE) RETURN C_FRUITORE_DI_PIANO IS
v_fruitore C_FRUITORE_DI_PIANO;
BEGIN
        OPEN v_fruitore FOR
        SELECT
        FR.ID_FRUITORE,
        FP.ID_FRUITORI_DI_PIANO,
        FR.RAG_SOC_COGN,
        FR.RAG_SOC_BR_NOME,
        FR.LOCALITA,
        FR.INDIRIZZO,
        get_desc_area(FR.AREA) as desc_area,
        get_desc_sedi(FR.SEDE) as desc_sede,
        FP.DATA_DECORRENZA,
        FP.PROGRESSIVO
        FROM
        VI_CD_CLIENTE_FRUITORE FR,
        CD_FRUITORI_DI_PIANO FP
        WHERE FP.ID_FRUITORI_DI_PIANO = p_id_fruitore_di_piano
        AND FP.ID_CLIENTE_FRUITORE = FR.ID_FRUITORE;
    RETURN v_fruitore;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_CLIENTE_FRUITORE;


FUNCTION FU_IS_PIANO_CAMBIO_MERCE(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN VARCHAR2 IS
v_cambio_merce VARCHAR2(1);
BEGIN

    SELECT FLG_CAMBIO_MERCE
    INTO v_cambio_merce
    FROM CD_PIANIFICAZIONE
    WHERE ID_PIANO = p_id_piano
    AND id_ver_piano = p_id_ver_piano;
    RETURN v_cambio_merce;
END FU_IS_PIANO_CAMBIO_MERCE;

FUNCTION FU_ESISTE_DIREZIONALE(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) RETURN VARCHAR2 IS
v_direzionali VARCHAR2(1) := 'N';
v_num_direzionali NUMBER;
BEGIN

    SELECT COUNT(1)
    INTO v_num_direzionali
    FROM CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PIANO = p_id_piano
    AND PA.ID_VER_PIANO = p_id_ver_piano
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.COD_DISATTIVAZIONE IS NULL
    AND EXISTS (SELECT * FROM CD_IMPORTI_PRODOTTO IMPP
                WHERE IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                AND IMPP.TIPO_CONTRATTO = 'D'
                AND IMPP.IMP_NETTO > 0);
    IF v_num_direzionali > 0 THEN
        v_direzionali := 'S';
    END IF;
    RETURN v_direzionali;
END FU_ESISTE_DIREZIONALE;

PROCEDURE PR_PIANO_CAMBIO_MERCE(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE, p_flg_cambio_merce VARCHAR2) IS
BEGIN
    UPDATE CD_PIANIFICAZIONE SET FLG_CAMBIO_MERCE = p_flg_cambio_merce
    WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
    AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano;
EXCEPTION
WHEN OTHERS THEN
 raise_application_error(-20001, 'PR_PIANO_CAMBIO_MERCE: errore non atteso'||SQLERRM);
END PR_PIANO_CAMBIO_MERCE;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_DATA_INIZIO_PERIODO_SPEC
-- DESCRIZIONE:  restituisce le date inizio dei periodi speciali
--
-- REALIZZATORE  Michele Borgogno, Altran, Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATE_PERIODI RETURN C_DATE_PERIODO IS
v_data  C_DATE_PERIODO;
BEGIN
    OPEN v_data FOR
        SELECT data_iniz, data_fine FROM periodi
        WHERE data_iniz > TO_DATE('01012010','DDMMYYYY')
        AND data_fine > TO_DATE('01012010','DDMMYYYY')
        ORDER BY data_iniz, data_fine ASC;
RETURN v_data;
END FU_GET_DATE_PERIODI;




-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_DATE_PERIODI_E_SPECIALI
-- DESCRIZIONE:  restituisce le date inizio dei periodi o  speciali in funzione del parametro passato 1 periodi, 2 periodi speciali
--
-- REALIZZATORE  Mauro Viel, Altran, Febbraio  2011
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATE_PERIODI_E_SPECIALI(P_TIPO_PERIODO VARCHAR2) RETURN C_DATE_PERIODO IS
v_data  C_DATE_PERIODO;
BEGIN
    IF P_TIPO_PERIODO = 1 THEN
        OPEN v_data FOR
        SELECT data_iniz, data_fine 
        FROM periodi
        WHERE data_iniz  > TO_DATE('01012010','DDMMYYYY')
        AND data_fine > TO_DATE('01012010','DDMMYYYY')
        ORDER BY data_iniz, data_fine ASC;
   ELSE 
        OPEN v_data FOR
        /*select data_inizio as data_iniz, data_fine   
        from cd_periodo_speciale
        WHERE  data_inizio >= TO_DATE('01012010','DDMMYYYY')
        AND data_fine >= TO_DATE('01012010','DDMMYYYY')
        ORDER BY data_iniz, data_fine ASC;*/
        select distinct pa.data_inizio as data_iniz, pa.data_fine   
        from cd_periodo_speciale ps, 
             cd_prodotto_acquistato pa,
             cd_comunicato co,
             cd_sala sa
        where  pa.STATO_DI_VENDITA = 'PRE'
        and    pa.data_inizio = ps.data_inizio
        and    pa.data_fine = ps.data_fine
        and    pa.FLG_ANNULLATO = 'N'
        and    pa.FLG_SOSPESO = 'N'
        and    pa.cod_disattivazione is null
        and    co.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_acquistato
        and    co.FLG_ANNULLATO= 'N'
        and    co.flg_sospeso ='N'
        and    co.cod_disattivazione is not null
        and    sa.id_sala = co.id_sala
        group by co.id_sala, pa.id_prodotto_acquistato,pa.data_fine, pa.data_inizio
        having count(1)/2 = (pa.data_fine - pa.data_inizio) +1
        order by pa.data_inizio, pa.data_fine asc;
   END IF;     
RETURN v_data;
END FU_GET_DATE_PERIODI_E_SPECIALI;



-- FUNZIONE FU_GET_DATE_PRODOTTI_TARGET
-- DESCRIZIONE:  restituisce le date inizio dei periodi dei prodotti a target
--
-- REALIZZATORE  Mauro Viel, Marzo, Febbraio  2011
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATE_PRODOTTI_TARGET RETURN C_DATE_PERIODO IS
v_data  C_DATE_PERIODO;
BEGIN
    OPEN v_data FOR
        select  distinct data_inizio, data_fine
        from  cd_prodotto_acquistato pa, 
              cd_prodotto_vendita pv
        where pv.id_prodotto_vendita = pa.id_prodotto_vendita
        and   pa.flg_annullato = 'N'
        and   pa.flg_sospeso ='N'
        and   pa.cod_disattivazione is null
        and   pv.id_target is not null
        ORDER BY data_inizio desc;
RETURN v_data;
END FU_GET_DATE_PRODOTTI_TARGET;

FUNCTION FU_GET_DATE_PRODOTTI_SPECIALI(P_STATO_VENDITA CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE ) RETURN C_DATE_PERIODO IS
v_data  C_DATE_PERIODO;
BEGIN
OPEN v_data FOR
select  distinct data_inizio, data_fine
        from  cd_prodotto_acquistato pa, 
              cd_prodotto_vendita pv
        where pv.id_prodotto_vendita = pa.id_prodotto_vendita
        and   pa.flg_annullato = 'N'
        and   pa.flg_sospeso ='N'
        and   pa.cod_disattivazione is null
        and   (pv.id_target is not null or pv.flg_segui_il_film ='S')
        and   pa.stato_di_vendita =P_STATO_VENDITA
        and   pa.data_inizio = nvl(P_DATA_INIZIO, pa.data_inizio)
        and   pa.data_fine   = nvl(P_DATA_FINE, pa.data_fine)
        ORDER BY data_inizio desc;
RETURN v_data;
END FU_GET_DATE_PRODOTTI_SPECIALI;



-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_NUM_PRODOTTI_PROPOSTI
-- DESCRIZIONE:  Restituisce il numero di prodotti proposti di un piano
-- INPUT: id_piano, id_ver_piano
-- OUTPUT: Numero di prodotti proposti del piano
--
--
-- REALIZZATORE Michele Borgogno, Altran, Marzo 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_NUM_PRODOTTI_PROPOSTI(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE, p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER IS
v_num_prodotti NUMBER;
BEGIN
    SELECT COUNT(1) INTO v_num_prodotti FROM
        CD_PRODOTTO_ACQUISTATO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano
    AND FLG_ANNULLATO = 'N'
    AND FLG_SOSPESO = 'N'
    AND COD_DISATTIVAZIONE IS NULL;
    
    RETURN v_num_prodotti;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_GET_NUM_PRODOTTI_PROPOSTI: Impossibile valutare la richiesta');

END FU_GET_NUM_PRODOTTI_PROPOSTI;


-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_NUM_PRODOTTI_PROP_PRE
-- DESCRIZIONE:  Restituisce il numero di prodotti proposti  prenotati di un piano
-- INPUT: id_piano, id_ver_piano
-- OUTPUT: Numero di prodotti proposti  prenotati del piano
--
--
-- REALIZZATORE MMauro Viel, Altran, Novembre 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_GET_NUM_PRODOTTI_PROP_PRE(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE, p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN NUMBER IS
v_num_prodotti NUMBER;
BEGIN
    SELECT COUNT(1) INTO v_num_prodotti FROM
        CD_PRODOTTO_ACQUISTATO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano
    AND FLG_ANNULLATO = 'N'
    AND FLG_SOSPESO = 'N'
    AND COD_DISATTIVAZIONE IS NULL
    AND STATO_DI_VENDITA ='PRE';
    
    RETURN v_num_prodotti;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FFU_GET_NUM_PRODOTTI_PROPOSTI_PRENOTATI: Impossibile valutare la richiesta');

END FU_GET_NUM_PRODOTTI_PROP_PRE;

FUNCTION FU_GET_SOGGETTO_DI_PIANO(P_ID_SOGGETTO_DI_PIANO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE) RETURN C_SOGGETTO_PROD IS
v_soggetto C_SOGGETTO_PROD;
BEGIN
        OPEN v_soggetto FOR
           SELECT id_soggetto_di_piano,int_u_cod_interl,descrizione,perc_distribuzione,NULL, NULL
        FROM CD_SOGGETTO_DI_PIANO 
        WHERE ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO_DI_PIANO;
    RETURN v_soggetto;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END;

FUNCTION FU_PERIODI_CONSECUTIVI(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                             p_data_inizio DATE, p_data_fine DATE) RETURN NUMBER IS
    --
    v_stato_lavorazione CD_STATO_LAVORAZIONE.STATO_PIANIFICAZIONE%TYPE;
    v_giorni_periodi NUMBER := 0;
    v_giorni_compresi NUMBER := 0;
    p_esito NUMBER := 1;
    BEGIN
        SELECT LAV.STATO_PIANIFICAZIONE
        INTO v_stato_lavorazione
        FROM CD_PIANIFICAZIONE P, CD_STATO_LAVORAZIONE LAV
        WHERE P.ID_PIANO = p_id_piano
        AND P.ID_VER_PIANO = p_id_ver_piano
        AND P.ID_STATO_LAV = LAV.ID_STATO_LAV;
        v_giorni_compresi := p_data_fine - p_data_inizio + 1;
        FOR PERIODO IN (
                    SELECT DATA_INIZ, DATA_FINE
                    FROM
                    (
                        SELECT PER.DATA_INIZ, PER.DATA_FINE
                        FROM PERIODI PER, CD_IMPORTI_RICHIESTI_PIANO IRP
                        WHERE IRP.ID_PIANO = p_id_piano
                        AND IRP.ID_VER_PIANO = p_id_ver_piano
                        AND IRP.ANNO = PER.ANNO
                        AND IRP.CICLO = PER.CICLO
                        AND IRP.PER = PER.PER
                        AND IRP.FLG_ANNULLATO = 'N'
                        AND PER.DATA_INIZ >= p_data_inizio
                        AND PER.DATA_FINE <= p_data_fine
                        AND v_stato_lavorazione = 'PIANO'
                        UNION
                        SELECT PER.DATA_INIZ, PER.DATA_FINE
                        FROM PERIODI PER, CD_IMPORTI_RICHIESTA IR
                        WHERE IR.ID_PIANO = p_id_piano
                        AND IR.ID_VER_PIANO = p_id_ver_piano
                        AND IR.ANNO = PER.ANNO
                        AND IR.CICLO = PER.CICLO
                        AND IR.PER = PER.PER
                        AND IR.FLG_ANNULLATO = 'N'
                        AND PER.DATA_INIZ >= p_data_inizio
                        AND PER.DATA_FINE <= p_data_fine
                        AND v_stato_lavorazione = 'RICHIESTA'
                    )
                    ORDER BY DATA_INIZ
            ) LOOP
                v_giorni_periodi := v_giorni_periodi + (PERIODO.DATA_FINE - PERIODO.DATA_INIZ + 1);
            END LOOP;
            IF v_giorni_compresi != v_giorni_periodi THEN
                p_esito := -1;
            END IF;    
            --
            RETURN p_esito;
END FU_PERIODI_CONSECUTIVI; 
                            
FUNCTION FU_GET_PERIODO_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                          p_data_inizio DATE, p_data_fine DATE) RETURN CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE IS
--
v_id_periodo CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
BEGIN    
    SELECT ID_IMPORTI_RICHIESTI_PIANO
     INTO v_id_periodo
    FROM
    ( 
    SELECT ID_IMPORTI_RICHIESTI_PIANO
     FROM CD_IMPORTI_RICHIESTI_PIANO IRP, PERIODI PER
     WHERE ID_PIANO = p_id_piano
     AND ID_VER_PIANO = p_id_ver_piano
     AND FLG_ANNULLATO = 'N'
     AND PER.ANNO = IRP.ANNO
     AND PER.CICLO = IRP.CICLO
     AND PER.PER = IRP.PER
     AND PER.DATA_INIZ = p_data_inizio
     AND PEr.DATA_FINE = p_data_fine
     UNION
     SELECT ID_IMPORTI_RICHIESTI_PIANO
     FROM CD_IMPORTI_RICHIESTI_PIANO IRP, CD_PERIODO_SPECIALE PS
     WHERE ID_PIANO = p_id_piano
     AND ID_VER_PIANO = p_id_ver_piano
     AND FLG_ANNULLATO = 'N'
     AND PS.ID_PERIODO_SPECIALE = IRP.ID_PERIODO_SPECIALE
     AND PS.DATA_INIZIO = p_data_inizio
     AND PS.DATA_FINE = p_data_fine
     UNION
     SELECT ID_IMPORTI_RICHIESTI_PIANO
     FROM CD_IMPORTI_RICHIESTI_PIANO IRP, CD_PERIODI_CINEMA PC
     WHERE ID_PIANO = p_id_piano
     AND ID_VER_PIANO = p_id_ver_piano
     AND FLG_ANNULLATO = 'N'
     AND PC.ID_PERIODO = IRP.ID_PERIODO
     AND PC.DATA_INIZIO = p_data_inizio
     AND PC.DATA_FINE = p_data_fine
     );
     RETURN v_id_periodo;
END FU_GET_PERIODO_PIANO;

FUNCTION FU_GET_PERIODO_RICHIESTA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE, p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                              p_data_inizio DATE, p_data_fine DATE) RETURN CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE IS
--
v_id_periodo CD_IMPORTI_RICHIESTA.ID_IMPORTI_RICHIESTA%TYPE;
BEGIN    
    SELECT ID_IMPORTI_RICHIESTA
     INTO v_id_periodo
    FROM
    ( 
    SELECT ID_IMPORTI_RICHIESTA
     FROM CD_IMPORTI_RICHIESTA IRP, PERIODI PER
     WHERE ID_PIANO = p_id_piano
     AND ID_VER_PIANO = p_id_ver_piano
     AND FLG_ANNULLATO = 'N'
     AND PER.ANNO = IRP.ANNO
     AND PER.CICLO = IRP.CICLO
     AND PER.PER = IRP.PER
     AND PER.DATA_INIZ = p_data_inizio
     AND PER.DATA_FINE = p_data_fine
     UNION
     SELECT ID_IMPORTI_RICHIESTA
     FROM CD_IMPORTI_RICHIESTA IRP, CD_PERIODO_SPECIALE PS
     WHERE ID_PIANO = p_id_piano
     AND ID_VER_PIANO = p_id_ver_piano
     AND FLG_ANNULLATO = 'N'
     AND PS.ID_PERIODO_SPECIALE = IRP.ID_PERIODO_SPECIALE
     AND PS.DATA_INIZIO = p_data_inizio
     AND PS.DATA_FINE = p_data_fine
     UNION
     SELECT ID_IMPORTI_RICHIESTA
     FROM CD_IMPORTI_RICHIESTA IRP, CD_PERIODI_CINEMA PC
     WHERE ID_PIANO = p_id_piano
     AND ID_VER_PIANO = p_id_ver_piano
     AND FLG_ANNULLATO = 'N'
     AND PC.ID_PERIODO = IRP.ID_PERIODO
     AND PC.DATA_INIZIO = p_data_inizio
     AND PC.DATA_FINE = p_data_fine
     );
     RETURN v_id_periodo;
END FU_GET_PERIODO_RICHIESTA;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_DATA_INIZIO_PER
-- DESCRIZIONE:  restituisce le date inizio dei periodi + periodi speciali
--
-- REALIZZATORE  Michele Borgogno, Altran, Luglio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATA_INIZIO_PER RETURN C_DATA_PER IS
v_data_inizio  C_DATA_PER;
BEGIN
    OPEN v_data_inizio FOR
        SELECT DISTINCT(DATA_INIZ) as data_inizio
        FROM PERIODI
        union
        SELECT DISTINCT(DATA_INIZIO) as data_inizio
        FROM CD_PERIODO_SPECIALE
        ORDER BY data_inizio DESC;
RETURN v_data_inizio;
END FU_GET_DATA_INIZIO_PER;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_DATA_FINE_PER
-- DESCRIZIONE:  restituisce le date fine per una data inizio dei periodi + periodi speciali

-- REALIZZATORE  Michele Borgogno, Altran, Luglio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATA_FINE_PER(p_data_inizio PERIODI.DATA_INIZ%TYPE) RETURN C_DATA_PER IS
v_data_fine C_DATA_PER;
BEGIN
    OPEN v_data_fine FOR
        SELECT DISTINCT(PERIODI.DATA_FINE) as data_fine
        FROM PERIODI
        WHERE PERIODI.DATA_INIZ = p_data_inizio
        union
        SELECT DISTINCT(CD_PERIODO_SPECIALE.DATA_FINE) as data_fine
        FROM CD_PERIODO_SPECIALE
        WHERE CD_PERIODO_SPECIALE.DATA_INIZIO = p_data_inizio
        ORDER BY data_fine DESC;
RETURN v_data_fine;
END FU_GET_DATA_FINE_PER;


----------------------------------------------------------------------
--Funzione di ricerca delle pianificazioni presenti a sistema
--Realizzatore del commento Antonio Colucci 05/01/2011
--
--Realizzatore: ipoteticamente Michele Fadda, Altran Italia
--modifiche precedenti alla seguente non pervenute
--Modifiche     Antonio Colucci, Teoresi srl, 05/01/2011
--              Cambiato modalita di reperimentodella descrizione del soggetto
--              E' stato richiesto che tale descrizione venisse recuperata da CLICOMM
--              piuttosto che da VI_CD_CLIENTE, in quanto tale vista non considera i Clienti non + validi
--              Mauro Viel Altran 17/01/2010 se viene specificato uno stato di vendita 
--              si la data_inizio e data_fine dal cd_prodotto_acquistato. Altrimenti  da CD_IMPORTI_RICHIESTI_PIANO.
----------------------------------------------------------------------

FUNCTION FU_CERCA_PIANO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_ID_SOGGETTO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_STATO_VENDITA CD_STATO_DI_VENDITA.ID_STATO_VENDITA%TYPE,
                        P_ID_STATO_LAV CD_PIANIFICAZIONE.ID_STATO_LAV%TYPE,
                        P_DATA_INIZIO PERIODI.DATA_INIZ%TYPE,
                        P_DATA_FINE PERIODI.DATA_FINE%TYPE,
                        P_COD_CATEGORIA_PRODOTTO CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                        ) RETURN  C_PIANIFICAZIONE IS
CUR C_PIANIFICAZIONE;
v_stato_vendita CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
BEGIN
    IF P_STATO_VENDITA IS NOT NULL THEN
    
        SELECT DESCR_BREVE INTO v_stato_vendita
        FROM CD_STATO_DI_VENDITA
        WHERE ID_STATO_VENDITA = P_STATO_VENDITA;
        
        OPEN CUR for
           select id_piano, id_ver_piano,cod_area,id_responsabile_contatto,id_cliente_fruitore,
        netto, lordo, perc_sc, data_creazione_richiesta, to_char(per_inizio,'DD/MM/YYYY') as periodo_inizio,
        to_char(per_fine,'DD/MM/YYYY') as periodo_fine, id_stato_lav, cod_categoria_prodotto from (
    SELECT PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           GET_DESC_AREA(PIA.cod_area) as cod_area,
           get_desc_responsabile(id_responsabile_contatto) as id_responsabile_contatto,
           --get_desc_cliente(id_cliente)as id_cliente_fruitore,
           clicomm.RAGSOC id_cliente_fruitore,
           sum(nvl(netto,0)) as netto ,
           sum(nvl(lordo,0)) as lordo,
           min(nvl(perc_sc,0)) as perc_sc ,
           to_char(data_creazione_richiesta,'DD/MM/YYYY') as data_creazione_richiesta,
           --nvl(to_char(min (per.data_iniz),'DD/MM/YYYY'),'-') as periodo_inizio,
           --nvl(to_char(max(per.data_fine),'DD/MM/YYYY'),'-') as periodo_fine,
--           to_char(least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_inizio,
--           to_char(greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_fine,
           least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))) as per_inizio,
           greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))) as per_fine,
           PIA.id_stato_lav,
           PIA.cod_categoria_prodotto
    FROM CD_PIANIFICAZIONE PIA,
         CD_IMPORTI_RICHIESTI_PIANO IMP,
         periodi PER,
         CD_PRODOTTO_ACQUISTATO PRA,
         VI_CD_AREE_SEDI_COMPET ARSE,
         CLICOMM
    WHERE (P_ID_PIANO is null or PIA.ID_PIANO =P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIA.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_COD_CATEGORIA_PRODOTTO IS NULL OR PIA.COD_CATEGORIA_PRODOTTO = P_COD_CATEGORIA_PRODOTTO)
    AND   (P_ID_CLIENTE is null or PIA.ID_CLIENTE  = P_ID_CLIENTE)
    AND   (P_COD_AREA IS NULL OR PIA.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIA.COD_SEDE = P_COD_SEDE)
--    AND   (P_ID_SOGGETTO IS NULL OR  PIA.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
    AND   (P_RESP_CONTATTO IS NULL OR PIA.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO)
    AND   (P_ID_STATO_LAV is null or PIA.ID_STATO_LAV  = P_ID_STATO_LAV)
 --   AND   (P_DATA_INIZIO is null or PER.DATA_INIZ = P_DATA_INIZIO or FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo) = P_DATA_INIZIO)
 --   AND   (P_DATA_FINE is null or PER.DATA_FINE  = P_DATA_FINE or FU_GET_DATA_PER_SPEC_FI(imp.id_periodo_speciale,imp.id_periodo) = P_DATA_FINE)
--    AND   (P_DATA_INIZIO is null or P_DATA_INIZIO >= least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))))
--    AND   (P_DATA_FINE is null or P_DATA_FINE = periodo_fine)
    AND   (IMP.ID_PIANO  (+)= PIA.ID_PIANO)
    AND   (IMP.ID_VER_PIANO (+) = PIA.ID_VER_PIANO)
    AND   IMP.FLG_ANNULLATO = 'N'
    AND   (PIA.DATA_INVIO_MAGAZZINO IS NOT  NULL)
    AND   (PIA.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL)
    AND   (PIA.FLG_SOSPESO ='N')
    AND   (PIA.FLG_ANNULLATO = 'N')
    --AND   PIA.ID_STATO_LAV =  P_ID_STATO_LAV
    AND PER.ANNO (+)= IMP.ANNO
    AND PER.CICLO (+)= IMP.CICLO
    AND PER.PER (+)= IMP.PER
    AND PIA.ID_PIANO     = PRA.ID_PIANO (+)
    AND PIA.ID_VER_PIANO = PRA.ID_VER_PIANO (+)
    AND (v_stato_vendita is null OR PRA.STATO_DI_VENDITA = v_stato_vendita)
    AND  PRA.FLG_ANNULLATO (+) =  'N'
    AND PRA.FLG_SOSPESO (+) = 'N'
    AND PRA.COD_DISATTIVAZIONE (+)  is null
    AND PRA.ID_IMPORTI_RICHIESTI_PIANO = IMP.ID_IMPORTI_RICHIESTI_PIANO
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
    and pia.id_cliente = clicomm.COD_INTERL
    group by PIA.id_piano,
             PIA.id_ver_piano,
             PIA.cod_area,
             id_responsabile_contatto,
             --id_cliente,
             data_creazione_richiesta,
             PIA.ID_STATO_LAV,
             PIA.cod_categoria_prodotto,
             clicomm.RAGSOC
             --imp.id_periodo_speciale
    order by PIA.id_piano DESC)
 --   where ((P_DATA_INIZIO is not null and P_DATA_FINE is not null) and (P_DATA_INIZIO <= periodo_inizio and P_DATA_FINE >= periodo_fine));
--    where (P_DATA_INIZIO is null or (P_DATA_INIZIO <= per_inizio))
--    and (P_DATA_FINE is null or (P_DATA_FINE >= per_fine));
    where (P_DATA_INIZIO is null or (P_DATA_INIZIO <= per_fine))
    and (P_DATA_FINE is null or (P_DATA_FINE >= per_inizio));
    ELSE        
        OPEN CUR for
    select id_piano, id_ver_piano,cod_area,id_responsabile_contatto,id_cliente_fruitore,
        netto, lordo, perc_sc, data_creazione_richiesta, to_char(per_inizio,'DD/MM/YYYY') as periodo_inizio,
        to_char(per_fine,'DD/MM/YYYY') as periodo_fine, id_stato_lav, cod_categoria_prodotto from (
    SELECT PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           GET_DESC_AREA(PIA.cod_area) as cod_area,
           get_desc_responsabile(id_responsabile_contatto) as id_responsabile_contatto,
           --get_desc_cliente(id_cliente)as id_cliente_fruitore,
           clicomm.RAGSOC id_cliente_fruitore,
           sum(nvl(netto,0)) as netto ,
           sum(nvl(lordo,0)) as lordo,
           min(nvl(perc_sc,0)) as perc_sc ,
           to_char(data_creazione_richiesta,'DD/MM/YYYY') as data_creazione_richiesta,
           --nvl(to_char(min (per.data_iniz),'DD/MM/YYYY'),'-') as periodo_inizio,
           --nvl(to_char(max(per.data_fine),'DD/MM/YYYY'),'-') as periodo_fine,
--           to_char(least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_inizio,
--           to_char(greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))),'DD/MM/YYYY') as periodo_fine,
           least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))) as per_inizio,
           greatest(nvl(max(per.data_fine),to_date('31121999','DDMMYYYY')),nvl(max(FU_GET_DATA_PER_FI(imp.id_periodo_speciale,imp.id_periodo)),to_date('31121999','DDMMYYYY'))) as per_fine,
           PIA.id_stato_lav,
           PIA.cod_categoria_prodotto
    FROM CD_PIANIFICAZIONE PIA,
         CD_IMPORTI_RICHIESTI_PIANO IMP,
         periodi PER,
         CD_PRODOTTO_ACQUISTATO PRA,
         VI_CD_AREE_SEDI_COMPET ARSE,
         CLICOMM
    WHERE (P_ID_PIANO is null or PIA.ID_PIANO =P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIA.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_COD_CATEGORIA_PRODOTTO IS NULL OR PIA.COD_CATEGORIA_PRODOTTO = P_COD_CATEGORIA_PRODOTTO)
    AND   (P_ID_CLIENTE is null or PIA.ID_CLIENTE  = P_ID_CLIENTE)
    AND   (P_COD_AREA IS NULL OR PIA.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIA.COD_SEDE = P_COD_SEDE)
--    AND   (P_ID_SOGGETTO IS NULL OR  PIA.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
    AND   (P_RESP_CONTATTO IS NULL OR PIA.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO)
    AND   (P_ID_STATO_LAV is null or PIA.ID_STATO_LAV  = P_ID_STATO_LAV)
 --   AND   (P_DATA_INIZIO is null or PER.DATA_INIZ = P_DATA_INIZIO or FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo) = P_DATA_INIZIO)
 --   AND   (P_DATA_FINE is null or PER.DATA_FINE  = P_DATA_FINE or FU_GET_DATA_PER_SPEC_FI(imp.id_periodo_speciale,imp.id_periodo) = P_DATA_FINE)
--    AND   (P_DATA_INIZIO is null or P_DATA_INIZIO >= least(nvl(min(per.data_iniz),to_date('31122999','DDMMYYYY')),nvl(min(FU_GET_DATA_PER_IN(imp.id_periodo_speciale,imp.id_periodo)),to_date('31122999','DDMMYYYY'))))
--    AND   (P_DATA_FINE is null or P_DATA_FINE = periodo_fine)
    AND   (IMP.ID_PIANO  (+)= PIA.ID_PIANO)
    AND   (IMP.ID_VER_PIANO (+) = PIA.ID_VER_PIANO)
    AND   IMP.FLG_ANNULLATO = 'N'
    AND   (PIA.DATA_INVIO_MAGAZZINO IS NOT  NULL)
    AND   (PIA.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL)
    AND   (PIA.FLG_SOSPESO ='N')
    AND   (PIA.FLG_ANNULLATO = 'N')
    --AND   PIA.ID_STATO_LAV =  P_ID_STATO_LAV
    AND PER.ANNO (+)= IMP.ANNO
    AND PER.CICLO (+)= IMP.CICLO
    AND PER.PER (+)= IMP.PER
    AND PIA.ID_PIANO     = PRA.ID_PIANO (+)
    AND PIA.ID_VER_PIANO = PRA.ID_VER_PIANO (+)
    AND (v_stato_vendita is null OR PRA.STATO_DI_VENDITA = v_stato_vendita)
    AND  PRA.FLG_ANNULLATO (+) =  'N'
    AND PRA.FLG_SOSPESO (+) = 'N'
    AND PRA.COD_DISATTIVAZIONE (+)  is null
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
    and pia.id_cliente = clicomm.COD_INTERL
    group by PIA.id_piano,
             PIA.id_ver_piano,
             PIA.cod_area,
             id_responsabile_contatto,
             --id_cliente,
             data_creazione_richiesta,
             PIA.ID_STATO_LAV,
             PIA.cod_categoria_prodotto,
             clicomm.RAGSOC
             --imp.id_periodo_speciale
    order by PIA.id_piano DESC)
 --   where ((P_DATA_INIZIO is not null and P_DATA_FINE is not null) and (P_DATA_INIZIO <= periodo_inizio and P_DATA_FINE >= periodo_fine));
--    where (P_DATA_INIZIO is null or (P_DATA_INIZIO <= per_inizio))
--    and (P_DATA_FINE is null or (P_DATA_FINE >= per_fine));
    where (P_DATA_INIZIO is null or (P_DATA_INIZIO <= per_fine))
    and (P_DATA_FINE is null or (P_DATA_FINE >= per_inizio));         
    END IF;
    --
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_PIANO;


PROCEDURE PR_INSERISCI_RICHIESTA_2(
                                 p_cod_area CD_PIANIFICAZIONE.COD_AREA%TYPE,
                                 p_cod_sede CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                                 p_data_richiesta CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
                                 p_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                 p_responsabile_contatto CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                                 p_stato_vendita CD_PIANIFICAZIONE.ID_STATO_VENDITA%TYPE,
                                 p_cod_categoria_prodotto CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_target CD_PIANIFICAZIONE.ID_TARGET%TYPE,
                                 p_sipra_lab CD_PIANIFICAZIONE.FLG_SIPRA_LAB%TYPE,
                                 p_cambio_merce CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE%TYPE,
                                 --p_lista_periodi  periodo_list_type,
                                 p_lista_intermediari intermediario_list_type,
                                 p_lista_soggetti soggetto_list_type,
                                 p_lista_formati id_list_type,
                                 p_id_piano OUT CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                 p_id_ver_piano OUT CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                 p_nota cd_pianificazione.NOTE%TYPE,
                                 p_tipo_contratto cd_pianificazione.TIPO_CONTRATTO%type
                                 ) IS

BEGIN

SAVEPOINT PR_INSERISCI_RICHIESTA;

   INSERT INTO CD_PIANIFICAZIONE(
                                 CD_PIANIFICAZIONE.COD_AREA,
                                 CD_PIANIFICAZIONE.COD_SEDE,
                                 CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA,
                                 CD_PIANIFICAZIONE.ID_CLIENTE,
                                 CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO,
                                 CD_PIANIFICAZIONE.ID_STATO_LAV,
                                 CD_PIANIFICAZIONE.ID_STATO_VENDITA,
                                 CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO,
                                 CD_PIANIFICAZIONE.ID_TARGET,
                                 CD_PIANIFICAZIONE.FLG_SIPRA_LAB,
                                 CD_PIANIFICAZIONE.FLG_CAMBIO_MERCE,
                                 CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE,
                                 CD_PIANIFICAZIONE.NOTE,
                                 CD_PIANIFICAZIONE.TIPO_CONTRATTO
                                 )
                          VALUES(p_cod_area,
                                 p_cod_sede,
                                 p_data_richiesta,
                                 p_cliente,
                                 p_responsabile_contatto,
                                 3,
                                 p_stato_vendita,
                                 p_cod_categoria_prodotto,
                                 p_target,
                                 p_sipra_lab,
                                 p_cambio_merce,
                                 PA_CD_MEZZO.FU_TESTATA_NAZIONALE,
                                 p_nota,
                                 p_tipo_contratto 
                                 );

SELECT CD_PIANIFICAZIONE_SEQ.CURRVAL INTO p_id_piano FROM DUAL;
p_id_ver_piano := 1;
--PR_INSERISCI_IMPORTI_PIANO(p_id_piano, p_id_ver_piano,p_lista_periodi);
PR_INSERISCI_FORMATI(p_id_piano,p_id_ver_piano,p_lista_formati);
--PR_INSERISCI_IMPORTI_RICHIESTA(p_id_piano, p_id_ver_piano,p_lista_periodi);
PR_INSERISCI_INTERMEDIARI(p_id_piano, p_id_ver_piano,p_lista_intermediari);
PR_INSERISCI_SOGGETTI(p_id_piano, p_id_ver_piano,p_lista_soggetti);
EXCEPTION
	  WHEN OTHERS THEN
   --   raise;
   RAISE_APPLICATION_ERROR(-20019, 'PROCEDURA PR_INSERISCI_RICHIESTA: ERRORE INATTESO INSERENDO LA RICHIESTA '||SQLERRM);
      ROLLBACK TO PR_INSERISCI_RICHIESTA;
END PR_INSERISCI_RICHIESTA_2;

END Pa_Cd_Pianificazione; 
/

