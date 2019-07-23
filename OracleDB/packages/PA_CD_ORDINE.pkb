CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_ORDINE IS


FUNCTION FU_STAMPA_ORDINE(    p_id_piano              CD_ORDINE.ID_PIANO%TYPE,
                              p_id_ver_piano          CD_ORDINE.ID_VER_PIANO%TYPE,
                              a_id_fruitore cd_ordine.ID_FRUITORI_DI_PIANO%TYPE,
                            --  p_id_tipo_committente   CD_ORDINE.ID_TIPO_COMMITTENTE%TYPE,
                              p_data_inizio           CD_ORDINE.DATA_INIZIO%TYPE,
                              p_data_fine             CD_ORDINE.DATA_FINE%TYPE
                            )  RETURN VARCHAR2
IS

BEGIN

IF v_stampa_ordine = 'ON'

    THEN

     RETURN 'ID_PIANO: '          || p_id_piano           || ', ' ||
            'ID_VER_PIANO: '          || p_id_ver_piano           || ', ' ||
            'ID_CLIENTE_FRUITORE: '|| a_id_fruitore    || ', ' ||
          --  'ID_TIPO_COMMITTENTE: '  || p_id_tipo_committente       || ', ' ||
            'DATA_INIZIO: ' || p_data_inizio        || ', ' ||
            'DATA_FINE: '          || p_data_fine;

END IF;

END  FU_STAMPA_ORDINE;

FUNCTION FU_GET_CLIENTE_FRUITORE RETURN C_CLIENTE_FRUITORE IS
v_clienti_fruitori C_CLIENTE_FRUITORE;
BEGIN
OPEN v_clienti_fruitori FOR
select r.cod_interl_f clifruamm, i.rag_soc_cogn, i.localita, i.indirizzo, i.dt_iniz_val, i.dt_fine_val
from interl_u i, raggruppamento_u r
where /* filtro 1: seleziona i clienti amm. associati al cliente commerciale del piano (tipo raggruppamento cccl) */
--r.cod_interl_p = :b01_pianirtv.int_u_cod_interl
r.tipo_raggrupp = 'CCCL'
and i.cod_interl = r.cod_interl_f /* join con interl_u */
and /* filtro 2: seleziona i clienti amm. che non sono classificati come agenzia o centro acquisti ( agz, caq ) */
not exists ( select 1 from classif_interl_u c where c.cod_interl = r.cod_interl_f and tipo_class in ( 'AGZ', 'CAQ' ) )
--and /* impone la intersezione del periodo di validita con il periodo di estensione del piano */
-- ( i.dt_iniz_val <= ( select max(data_fine) from piasetdur where pr_cod_piano = :b01_pianirtv.cod_piano and pr_vers_piano = :b01_pianirtv.vers_piano )
--and i.dt_fine_val >= ( select min(data_iniz) from piasetdur where pr_cod_piano = :b01_pianirtv.cod_piano and pr_vers_piano = :b01_pianirtv.vers_piano ) )
--and /* seleziona solo i clienti amm. non ancora associati al piano */
--not exists ( select 1 from pnfruamm where pr_cod_piano = :b01_pianirtv.cod_piano and pr_vers_piano = :b01_pianirtv.vers_piano and int_cod_cli_fru = r.cod_interl_f )
;
RETURN v_clienti_fruitori;
END FU_GET_CLIENTE_FRUITORE;


-----------------------------------------------------------------------------------------------------
-- Funzione FU_CERCA_PIANI_INVALIDI
--
-- DESCRIZIONE:  Restituisce la lista di piani candidati a diventare ordine con anomalie da correggere
--
-- OPERAZIONI:   In base ai filtri di ricerca, controlla tutti i piani che hanno dei prodotti acquistati 
--               prenotati che ancora devono confluire in un ordine. Se sussistono delle condizioni di anomalia 
--               (cliente, soggetto, fruitore, intermediario) viene restituito il piano, con l'indicazione
--               delle anomalie rilevate
--
--  INPUT:
--  P_ID_PIANO           Id del piano
--  P_ID_VER_PIANO       Versione del piano
--  P_ID_CLIENTE         Id del Cliente commerciale del piano
--  P_COD_AREA           Area del responsabile contatto
--  P_COD_SEDE           Sede del responsabile contatto
--  P_RESP_CONTATTO      Id del responsabile contatto
--  P_COD_AGENZIA        Codice agenzia
--  P_CENTRO_MEDIA       Centro media
--  P_DATA_INIZIO        Data di inizio del piano
--  P_DATA_FINE          Data di fine del piano
--
-- OUTPUT:
--   lista di piani validi
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:   
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PIANI_INVALIDI(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_COD_AGENZIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
                        P_CENTRO_MEDIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
                        P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                        P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                        P_COD_CATEGORIA_PRODOTTO  CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                        ) RETURN  C_PIANIFICAZIONE IS
CUR C_PIANIFICAZIONE;
BEGIN
    OPEN CUR for
SELECT 
           piani.id_piano id_piano,
           piani.id_ver_piano id_ver_piano,
           aree.DESCRIZIONE_ESTESA as desc_area,
           sedi.DESCRIZIONE_ESTESA as desc_sede,
           resp.RAG_SOC_COGN as responsabile_contatto,
           cliente.RAG_SOC_COGN as desc_cliente,
           --piani.ID_CLIENTE,
           piani.cod_categoria_prodotto,
           fp.id_fruitori_di_piano AS ID_FRUITORE,
           fruitore.COD_INTERL as id_cliente_fruitore,
           fruitore.RAG_SOC_COGN as desc_fruitore,
           pa_cd_ordine.FU_INTERM_ERRATO(piani.id_piano, piani.id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,fp.ID_FRUITORI_DI_PIANO) as INTERM_ERRATO,
           pa_cd_ordine.FU_SOGGETTO_ERRATO(piani.id_piano, piani.id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,fp.ID_FRUITORI_DI_PIANO) as SOGGETTO_ERRATO,
           pa_cd_ordine.FU_CLIENTE_ERRATO(piani.id_piano, piani.id_ver_piano, piani.id_cliente, P_DATA_INIZIO, P_DATA_FINE) as CLIENTE_ERRATO,
           pa_cd_ordine.FU_FRUITORE_ERRATO(piani.id_piano, piani.id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,fp.ID_FRUITORI_DI_PIANO) as FRUITORE_ERRATO,
           data_inizio_prod,
           data_fine_prod
from cd_pianificazione piani,
         VI_CD_AREE_SEDI_COMPET ARSE,
         aree,
         sedi,
         cd_fruitori_di_piano fp,
         interl_u fruitore,
         interl_u cliente,
         interl_u resp,
(
    select prodotti.fruitore, prodotti.id_piano, prodotti.id_ver_piano, netto_prodotti, netto_fatturato, prodotti.data_inizio_prod, prodotti.data_fine_prod-- - nvl(SUM(IMPF.IMPORTO_NETTO / (IMPF.DATA_FINE - IMPF.DATA_INIZIO + 1) * (LEAST(IMPF.DATA_FINE,::P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,::P_DATA_INIZIO) + 1)),0) as netto_mancante, pa.id_piano as piano_id, pa.id_ver_piano as piano_ver,data_inizio_prod,data_fine_prod
    from 
    (
        select pa.id_piano, pa.id_ver_piano, nvl(pa.id_fruitori_di_piano,-1) fruitore,
        SUM(ROUND(IMPP.IMP_NETTO / (PA.DATA_FINE - PA.DATA_INIZIO + 1) * (LEAST(PA.DATA_FINE,P_DATA_FINE) - GREATEST(PA.DATA_INIZIO,P_DATA_INIZIO) + 1),2)) AS netto_PRODOTTI,
        SUM( LEAST(PA.DATA_FINE,P_DATA_FINE) - GREATEST(PA.DATA_INIZIO,P_DATA_INIZIO) + 1) as giorni_prodotto,
        min(PA.DATA_INIZIO) as data_inizio_prod,
        max(PA.DATA_FINE) as data_fine_prod
        from cd_prodotto_acquistato pa, cd_importi_prodotto impp, cd_fruitori_di_piano fp
        --where PA.ID_PIANO = piani.id_piano
        --    AND PA.ID_VER_PIANO = piani.id_ver_piano
            where PA.FLG_SOSPESO = 'N'
            AND PA.FLG_ANNULLATO = 'N'
            AND PA.COD_DISATTIVAZIONE IS NULL
            AND PA.STATO_DI_VENDITA = 'PRE'
            AND IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
            --AND PA.ID_RAGGRUPPAMENTO IS NOT NULL
            --AND PA.ID_FRUITORI_DI_PIANO IS NOT NULL
            AND PA.ID_FRUITORI_DI_PIANO = FP.ID_FRUITORI_DI_PIANO(+)
            AND P_DATA_INIZIO <= PA.DATA_FINE
            AND P_DATA_FINE >= PA.DATA_INIZIO
            group by pa.id_fruitori_di_piano, pa.id_piano, pa.id_ver_piano
    ) prodotti,
    (
        select pa.id_piano, pa.id_ver_piano, nvl(pa.id_fruitori_di_piano,-1) fruitore,
        ROUND(nvl(SUM(IMPF.IMPORTO_NETTO / (IMPF.DATA_FINE - IMPF.DATA_INIZIO + 1) * (LEAST(IMPF.DATA_FINE,P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,P_DATA_INIZIO) + 1)),0),2) as netto_fatturato,
        NVL(SUM(LEAST(IMPF.DATA_FINE,P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,P_DATA_INIZIO) + 1),0) as giorni_fatturati
        from cd_prodotto_acquistato pa, cd_fruitori_di_piano fp, cd_importi_prodotto impp, cd_importi_fatturazione impf
        --where PA.ID_PIANO = piani.id_piano
        --    AND PA.ID_VER_PIANO = piani.id_ver_piano
            where PA.FLG_SOSPESO = 'N'
            AND PA.FLG_ANNULLATO = 'N'
            AND PA.COD_DISATTIVAZIONE IS NULL
            AND PA.STATO_DI_VENDITA = 'PRE'
            --AND PA.ID_RAGGRUPPAMENTO IS NOT NULL
            --AND PA.ID_FRUITORI_DI_PIANO IS NOT NULL
            AND PA.ID_FRUITORI_DI_PIANO = FP.ID_FRUITORI_DI_PIANO(+)
            AND P_DATA_INIZIO <= PA.DATA_FINE
            AND P_DATA_FINE >= PA.DATA_INIZIO
            AND IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
            AND IMPF.ID_IMPORTI_PRODOTTO(+) = IMPP.ID_IMPORTI_PRODOTTO
            AND IMPF.FLG_ANNULLATO(+) = 'N'
            AND P_DATA_INIZIO <= impf.DATA_FINE(+)
            AND P_DATA_FINE >= impf.DATA_INIZIO(+)
            group by pa.id_fruitori_di_piano, pa.id_piano, pa.id_ver_piano
    ) fatturato
    where fatturato.id_piano = prodotti.id_piano
    and fatturato.id_ver_piano = prodotti.id_ver_piano
    and fatturato.fruitore = prodotti.fruitore
    and (prodotti.netto_prodotti > fatturato.netto_fatturato + 0.05
        or ((
        select count(1) from cd_prodotto_acquistato pa, cd_fruitori_di_piano fp
        where PA.FLG_SOSPESO = 'N'
        AND PA.FLG_ANNULLATO = 'N'
        AND PA.COD_DISATTIVAZIONE IS NULL
        AND PA.STATO_DI_VENDITA = 'PRE'
        AND PA.ID_PIANO = prodotti.id_piano
        AND PA.ID_VER_PIANO = prodotti.id_ver_piano
        AND PA.IMP_NETTO = 0
        AND PA.ID_FRUITORI_DI_PIANO = FP.ID_FRUITORI_DI_PIANO(+)
        AND P_DATA_INIZIO <= PA.DATA_FINE
        AND P_DATA_FINE >= PA.DATA_INIZIO
    ) > 0
    AND
    ( 
        prodotti.giorni_prodotto > fatturato.giorni_fatturati)
    )
    )
     ) importi
    WHERE (P_ID_PIANO is null or PIANI.ID_PIANO  = P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIANI.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_ID_CLIENTE is null or PIANI.ID_CLIENTE  = P_ID_CLIENTE)
    AND   (P_COD_AREA IS NULL OR PIANI.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIANI.COD_SEDE = P_COD_SEDE)
    AND   (P_RESP_CONTATTO IS NULL OR PIANI.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO) 
    AND   (P_COD_CATEGORIA_PRODOTTO is null or PIANI.COD_CATEGORIA_PRODOTTO = P_COD_CATEGORIA_PRODOTTO)
    and   piani.DATA_INVIO_MAGAZZINO IS NOT  NULL
    AND   piani.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL
    AND   piani.FLG_SOSPESO ='N'
    AND   piani.FLG_ANNULLATO = 'N'
    AND cliente.COD_INTERL = piani.ID_CLIENTE
    AND resp.COD_INTERL = piani.ID_RESPONSABILE_CONTATTO
    AND ARSE.COD_AREA = piani.COD_AREA
    AND ARSE.COD_SEDE =piani.COD_SEDE
    AND piani.COD_AREA = AREE.COD_AREA
    AND piani.COD_SEDE = SEDI.COD_SEDE
    AND importi.ID_PIANO = PIANI.ID_PIANO
    AND importi.ID_VER_PIANO = PIANI.ID_VER_PIANO
    AND fp.ID_FRUITORI_DI_PIANO(+) = importi.fruitore
    AND fruitore.COD_INTERL(+) = fp.ID_CLIENTE_FRUITORE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S' , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(piani.ID_CLIENTE),'S') = 'S'
    order by piani.id_piano DESC
    /* WHERE (INTERM_ERRATO = 'S'
            OR SOGGETTO_ERRATO = 'S'
            OR CLIENTE_ERRATO = 'S'
            Or FRUITORE_ERRATO = 'S')*/;
--
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_PIANI_INVALIDI;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_CERCA_PIANI_VALIDI
--
-- DESCRIZIONE:  Restituisce la lista di piani candidati a diventare ordine
--
-- OPERAZIONI:   In base ai filtri di ricerca, controlla tutti i piani che hanno dei prodotti acquistati 
--               prenotati che ancora devono confluire in un ordine. Se tutte le condizioni di validita sono verificate 
--               il piano viene aggiunto alla lista di output
--
--  INPUT:
--  P_ID_PIANO           Id del piano
--  P_ID_VER_PIANO       Versione del piano
--  P_ID_CLIENTE         Id del Cliente commerciale del piano
--  P_COD_AREA           Area del responsabile contatto
--  P_COD_SEDE           Sede del responsabile contatto
--  P_RESP_CONTATTO      Id del responsabile contatto
--  P_COD_AGENZIA        Codice agenzia
--  P_CENTRO_MEDIA       Centro media
--  P_DATA_INIZIO        Data di inizio del piano
--  P_DATA_FINE          Data di fine del piano
--
-- OUTPUT:
--   lista di piani validi
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE: AMuro Viel, Altran inserito filtro di ricerca per  categoria prodotto.
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PIANI_VALIDI(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_COD_AGENZIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
                        P_CENTRO_MEDIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
                        P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                        P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                        P_COD_CATEGORIA_PRODOTTO  CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE
                        ) RETURN  C_PIANIFICAZIONE IS
CUR C_PIANIFICAZIONE;
BEGIN

OPEN CUR for
SELECT 
           piani.id_piano id_piano,
           piani.id_ver_piano id_ver_piano,
           aree.DESCRIZIONE_ESTESA as desc_area,
           sedi.DESCRIZIONE_ESTESA as desc_sede,
           resp.RAG_SOC_COGN as responsabile_contatto,
           cliente.RAG_SOC_COGN as desc_cliente,
           --piani.ID_CLIENTE,
           piani.cod_categoria_prodotto,
           fp.id_fruitori_di_piano AS ID_FRUITORE,
           fruitore.COD_INTERL as id_cliente_fruitore,
           fruitore.RAG_SOC_COGN as desc_fruitore,
           pa_cd_ordine.FU_INTERM_ERRATO(piani.id_piano, piani.id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,fp.ID_FRUITORI_DI_PIANO) as INTERM_ERRATO,
           pa_cd_ordine.FU_SOGGETTO_ERRATO(piani.id_piano, piani.id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,fp.ID_FRUITORI_DI_PIANO) as SOGGETTO_ERRATO,
           pa_cd_ordine.FU_CLIENTE_ERRATO(piani.id_piano, piani.id_ver_piano, piani.id_cliente, P_DATA_INIZIO, P_DATA_FINE) as CLIENTE_ERRATO,
           pa_cd_ordine.FU_FRUITORE_ERRATO(piani.id_piano, piani.id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,fp.ID_FRUITORI_DI_PIANO) as FRUITORE_ERRATO,
           data_inizio_prod,
           data_fine_prod
from cd_pianificazione piani,
         VI_CD_AREE_SEDI_COMPET ARSE,
         aree,
         sedi,
         cd_fruitori_di_piano fp,
         interl_u fruitore,
         interl_u cliente,
         interl_u resp,
(
    select prodotti.fruitore, prodotti.id_piano, prodotti.id_ver_piano, netto_prodotti, netto_fatturato, prodotti.data_inizio_prod, prodotti.data_fine_prod-- - nvl(SUM(IMPF.IMPORTO_NETTO / (IMPF.DATA_FINE - IMPF.DATA_INIZIO + 1) * (LEAST(IMPF.DATA_FINE,::P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,::P_DATA_INIZIO) + 1)),0) as netto_mancante, pa.id_piano as piano_id, pa.id_ver_piano as piano_ver,data_inizio_prod,data_fine_prod
    from 
    (
        select pa.id_piano, pa.id_ver_piano, nvl(pa.id_fruitori_di_piano,-1) fruitore,
        SUM(ROUND(IMPP.IMP_NETTO / (PA.DATA_FINE - PA.DATA_INIZIO + 1) * (LEAST(PA.DATA_FINE,P_DATA_FINE) - GREATEST(PA.DATA_INIZIO,P_DATA_INIZIO) + 1),2)) AS netto_PRODOTTI,
        SUM( LEAST(PA.DATA_FINE,P_DATA_FINE) - GREATEST(PA.DATA_INIZIO,P_DATA_INIZIO) + 1) as giorni_prodotto,
        min(PA.DATA_INIZIO) as data_inizio_prod,
        max(PA.DATA_FINE) as data_fine_prod
        from cd_prodotto_acquistato pa, cd_importi_prodotto impp, cd_fruitori_di_piano fp
        --where PA.ID_PIANO = piani.id_piano
        --    AND PA.ID_VER_PIANO = piani.id_ver_piano
            where PA.FLG_SOSPESO = 'N'
            AND PA.FLG_ANNULLATO = 'N'
            AND PA.COD_DISATTIVAZIONE IS NULL
            AND PA.STATO_DI_VENDITA = 'PRE'
            AND IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
            --AND PA.ID_RAGGRUPPAMENTO IS NOT NULL
            --AND PA.ID_FRUITORI_DI_PIANO IS NOT NULL
            AND PA.ID_FRUITORI_DI_PIANO = FP.ID_FRUITORI_DI_PIANO(+)
            AND P_DATA_INIZIO <= PA.DATA_FINE
            AND P_DATA_FINE >= PA.DATA_INIZIO
            group by pa.id_fruitori_di_piano, pa.id_piano, pa.id_ver_piano
    ) prodotti,
    (
        select pa.id_piano, pa.id_ver_piano, nvl(pa.id_fruitori_di_piano,-1) fruitore,
        ROUND(nvl(SUM(IMPF.IMPORTO_NETTO / (IMPF.DATA_FINE - IMPF.DATA_INIZIO + 1) * (LEAST(IMPF.DATA_FINE,P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,P_DATA_INIZIO) + 1)),-1),2) as netto_fatturato,
        NVL(SUM(LEAST(IMPF.DATA_FINE,P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,P_DATA_INIZIO) + 1),0) as giorni_fatturati
        from cd_prodotto_acquistato pa, cd_fruitori_di_piano fp, cd_importi_prodotto impp, cd_importi_fatturazione impf
        --where PA.ID_PIANO = piani.id_piano
        --    AND PA.ID_VER_PIANO = piani.id_ver_piano
            where PA.FLG_SOSPESO = 'N'
            AND PA.FLG_ANNULLATO = 'N'
            AND PA.COD_DISATTIVAZIONE IS NULL
            AND PA.STATO_DI_VENDITA = 'PRE'
            --AND PA.ID_RAGGRUPPAMENTO IS NOT NULL
            --AND PA.ID_FRUITORI_DI_PIANO IS NOT NULL
            AND PA.ID_FRUITORI_DI_PIANO = FP.ID_FRUITORI_DI_PIANO(+)
            AND P_DATA_INIZIO <= PA.DATA_FINE
            AND P_DATA_FINE >= PA.DATA_INIZIO
            AND IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
            AND IMPF.ID_IMPORTI_PRODOTTO(+) = IMPP.ID_IMPORTI_PRODOTTO
            AND IMPF.FLG_ANNULLATO(+) = 'N'
            --and impf.DATA_INIZIO(+) >= p_data_inizio
            --and impf.DATA_FINE(+) <= p_data_fine
            AND P_DATA_INIZIO <= impf.DATA_FINE(+)
            AND P_DATA_FINE >= impf.DATA_INIZIO(+)
            group by pa.id_fruitori_di_piano, pa.id_piano, pa.id_ver_piano
    ) fatturato
    where fatturato.id_piano = prodotti.id_piano
    and fatturato.id_ver_piano = prodotti.id_ver_piano
    and fatturato.fruitore = prodotti.fruitore
    and (
        prodotti.netto_prodotti > fatturato.netto_fatturato + 0.05
        or ((
        select count(1) from cd_prodotto_acquistato pa, cd_fruitori_di_piano fp
        where PA.FLG_SOSPESO = 'N'
        AND PA.FLG_ANNULLATO = 'N'
        AND PA.COD_DISATTIVAZIONE IS NULL
        AND PA.STATO_DI_VENDITA = 'PRE'
        AND PA.ID_PIANO = prodotti.id_piano
        AND PA.ID_VER_PIANO = prodotti.id_ver_piano
        AND PA.IMP_NETTO = 0
        AND PA.ID_FRUITORI_DI_PIANO = FP.ID_FRUITORI_DI_PIANO(+)
        AND P_DATA_INIZIO <= PA.DATA_FINE
        AND P_DATA_FINE >= PA.DATA_INIZIO
    ) > 0
    AND
    ( 
        prodotti.giorni_prodotto > fatturato.giorni_fatturati)
    )
    )
     ) importi
    WHERE (P_ID_PIANO is null or PIANI.ID_PIANO  = P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIANI.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_COD_CATEGORIA_PRODOTTO is null or PIANI.COD_CATEGORIA_PRODOTTO = P_COD_CATEGORIA_PRODOTTO)
    AND   (P_ID_CLIENTE is null or PIANI.ID_CLIENTE  = P_ID_CLIENTE)
    AND   (P_COD_AREA IS NULL OR PIANI.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIANI.COD_SEDE = P_COD_SEDE)
    AND   (P_RESP_CONTATTO IS NULL OR PIANI.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO) 
    and piani.id_piano = importi.id_piano
    and piani.id_ver_piano = importi.id_ver_piano
    and   piani.DATA_INVIO_MAGAZZINO IS NOT  NULL
    AND   piani.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL
    AND   piani.FLG_SOSPESO ='N'
    AND   piani.FLG_ANNULLATO = 'N'
    AND cliente.cod_interl = piani.ID_CLIENTE
    AND resp.COD_INTERL = piani.ID_RESPONSABILE_CONTATTO
    AND ARSE.COD_AREA = piani.COD_AREA
    AND ARSE.COD_SEDE =piani.COD_SEDE
    AND piani.COD_AREA = AREE.COD_AREA
    AND piani.COD_SEDE = SEDI.COD_SEDE
    AND fp.ID_FRUITORI_DI_PIANO = importi.fruitore
    AND FP.ID_CLIENTE_FRUITORE = fruitore.cod_interl
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S' , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(piani.ID_CLIENTE),'S') = 'S'
    order by piani.id_piano DESC
     /*WHERE (INTERM_ERRATO = 'N'
            AND SOGGETTO_ERRATO = 'N'
            AND CLIENTE_ERRATO = 'N'
            AND FRUITORE_ERRATO = 'N')*/;
--
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_PIANI_VALIDI;


--Restituisce 1 se l'ordine rispetta il criterio di ricerca.
---T tutti gli ordini restituisce  sempre 1
---S restituisce 1 se l'ordine e stato stampato.
---N restituisce 1 se l'ordine non e stato stampato.

FUNCTION FU_VERIFICA_STAMPA(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE, P_TIPO_RICERCA CHAR) RETURN CHAR IS
v_count number;
BEGIN
    IF UPPER(P_TIPO_RICERCA) ='TUTTI' THEN
        RETURN '1';
    ELSIF UPPER(P_TIPO_RICERCA) ='SI' THEN
        select COUNT(1)
        into v_count  
        from cd_stampe_ordine 
        where id_ordine = p_id_ordine;
        if v_count >=1 then
            return '1';
         else 
            return '0';
        end if;
    ELSE --'No' 
        select COUNT(1)
        into v_count  
        from cd_stampe_ordine 
        where id_ordine = p_id_ordine;
        if v_count = 0 then
            return '1';
         else 
            return '0';
        end if;    
    END IF;    
END FU_VERIFICA_STAMPA;


-----------------------------------------------------------------------------------------------------
-- Funzione FU_CERCA_ORDINI
--
-- DESCRIZIONE:  Restituisce la lista degli ordini presenti nel sistema
--
-- OPERAZIONI:   In base ai filtri di ricerca, restituisce gli ordini cercati
--
--  INPUT:
--  P_ID_PIANO           Id del piano
--  P_ID_VER_PIANO       Versione del piano
--  P_ID_CLIENTE         Id del Cliente commerciale del piano
--  P_COD_AREA           Area del responsabile contatto
--  P_COD_SEDE           Sede del responsabile contatto
--  P_RESP_CONTATTO      Id del responsabile contatto
--  P_COD_AGENZIA        Codice agenzia
--  P_CENTRO_MEDIA       Centro media
--  P_DATA_INIZIO        Data di inizio del piano
--  P_DATA_FINE          Data di fine del piano
--  P_ID_FRUITORE        Id del cliente fruitore dell'ordine
--  P_ID_PROGR           Progressivo dell'ordine
--  P_TIPO_RICERCA_DATE  Tipo di ricerca per data: se vale 1 l'ordine e restituito
--                       se anche solo una parte dell'intervallo inserito e nell'ordine,
--                       se vale 2 l'ordine deve essere strettamente incluso nell'intervallo
--
-- OUTPUT:
--   lista di ordini
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE: Mauro Viel Altran Italia Aprile 2010 : Eliminata la condizione che storna dal totale i sospesi di fattirazione (mv 20/04/2010) 
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_ORDINI(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                        P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                        P_ID_CLIENTE   VI_CD_CLIENTE_FRUITORE.ID_FRUITORE%TYPE,
                        P_COD_AREA CD_PIANIFICAZIONE.COD_AREA%TYPE,
                        P_COD_SEDE CD_PIANIFICAZIONE.COD_SEDE%TYPE,
                        P_RESP_CONTATTO CD_PIANIFICAZIONE.ID_RESPONSABILE_CONTATTO%TYPE,
                        P_COD_AGENZIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
                        P_CENTRO_MEDIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
                        P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                        P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                        P_ID_FRUITORE CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE,
                        P_ID_PROGR CD_ORDINE.COD_PRG_ORDINE%TYPE,
                        P_TIPO_RICERCA_DATE NUMBER,
                        P_COD_CATEGORIA_PRODOTTO  CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                        P_ANNULLATO CD_ORDINE.FLG_ANNULLATO%TYPE,
                        P_STAMPATO VARCHAR2)
                        RETURN  C_ORDINE IS
CUR C_ORDINE;
BEGIN

    OPEN CUR for
    SELECT PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           ORD.ID_ORDINE,
           ORD.COD_PRG_ORDINE,
           ORD.DATA_INIZIO,
           ORD.DATA_FINE,
           FRUITORE.ID_FRUITORE,
           FRUITORE.RAG_SOC_COGN as desc_fruitore,
           ORD.ID_CLIENTE_COMMITTENTE,
           aree.DESCRIZIONE_ESTESA as desc_area,
           sedi.DESCRIZIONE_ESTESA as desc_sede,
           resp.RAG_SOC_COGN as responsabile_contatto,
           cliente_committente.RAG_SOC_COGN as desc_cliente_committente,
           ORD.ID_COND_PAGAMENTO,
           cliente_commerciale.RAG_SOC_COGN as desc_cliente_commerciale,
           ORD.TIPO_COMMITTENTE,
           (SELECT NVL(SUM(IMPORTO_NETTO),0) from cd_importi_fatturazione 
            WHERE ID_ORDINE = ORD.ID_ORDINE
            --AND   FLG_SOSPESO = 'N'-- mv 20/04/2010
            AND FLG_INCLUSO_IN_ORDINE = 'S'
            AND FLG_ANNULLATO = 'N') as totale_netto,
            ORD.FLG_ANNULLATO
    FROM
         VI_CD_AREE_SEDI_COMPET ARSE,
         aree,
         sedi,
         interl_u cliente_committente,
         interl_u resp,
         vi_cd_cliente_fruitore fruitore,
         cd_fruitori_di_piano fp,
         vi_cd_cliente cliente_commerciale,
         CD_ORDINE ord,
         CD_PIANIFICAZIONE pia
    WHERE (P_ID_PIANO is null or PIA.ID_PIANO =P_ID_PIANO)
    AND   (P_ID_VER_PIANO is null or PIA.ID_VER_PIANO  = P_ID_VER_PIANO)
    AND   (P_COD_CATEGORIA_PRODOTTO is null or PIA.COD_CATEGORIA_PRODOTTO = P_COD_CATEGORIA_PRODOTTO)
    AND   (P_ID_PROGR is null or ORD.COD_PRG_ORDINE = P_ID_PROGR)
    AND   (P_ID_CLIENTE is null or ORD.ID_FRUITORI_DI_PIANO = (SELECT ID_FRUITORI_DI_PIANO FROM CD_FRUITORI_DI_PIANO
                                                               WHERE ID_CLIENTE_FRUITORE = P_ID_CLIENTE
                                                               AND ID_PIANO = pia.ID_PIANO
                                                               AND ID_VER_PIANO = pia.ID_VER_PIANO))
    AND   (P_COD_AREA IS NULL OR PIA.COD_AREA = P_COD_AREA)
    AND   (P_COD_SEDE IS NULL OR PIA.COD_SEDE = P_COD_SEDE)
    AND   (P_RESP_CONTATTO IS NULL OR PIA.ID_RESPONSABILE_CONTATTO = P_RESP_CONTATTO)
    AND   (PIA.DATA_INVIO_MAGAZZINO IS NOT  NULL)
    AND   (PIA.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL)
    AND   (P_TIPO_RICERCA_DATE = 1 AND ((P_DATA_INIZIO is null or (P_DATA_INIZIO <= ORD.DATA_FINE))
    AND   (P_DATA_FINE is null or (P_DATA_FINE >= ORD.DATA_INIZIO))) 
    OR    (P_TIPO_RICERCA_DATE = 2 AND P_DATA_INIZIO >= ORD.DATA_INIZIO AND P_DATA_FINE <= ORD.DATA_FINE))
    AND    PIA.FLG_SOSPESO ='N'
    AND    PIA.FLG_ANNULLATO = 'N'
    AND    ord.ID_PIANO = pia.ID_PIANO
    AND    ord.ID_VER_PIANO = pia.ID_VER_PIANO
    AND    ord.FLG_ANNULLATO = P_ANNULLATO
    AND    ord.FLG_SOSPESO = 'N'
    AND   (P_ID_FRUITORE IS NULL OR ORD.ID_FRUITORI_DI_PIANO = P_ID_FRUITORE)
    AND   fp.ID_FRUITORI_DI_PIANO = ORD.ID_FRUITORI_DI_PIANO
    AND   fruitore.ID_FRUITORE = fp.ID_CLIENTE_FRUITORE
    AND cliente_committente.COD_INTERL = ORD.ID_CLIENTE_COMMITTENTE
    AND cliente_commerciale.ID_CLIENTE = PIA.ID_CLIENTE
    AND resp.COD_INTERL = PIA.ID_RESPONSABILE_CONTATTO
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    AND PIA.COD_AREA = AREE.COD_AREA
    AND PIA.COD_SEDE = SEDI.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
    AND FU_VERIFICA_STAMPA(ORD.ID_ORDINE, P_STAMPATO) = '1'
    group by ORD.ID_ORDINE,
             PIA.id_piano,
             PIA.id_ver_piano,
             ORD.COD_PRG_ORDINE,
             ORD.DATA_INIZIO,
             ORD.DATA_FINE,
             FRUITORE.ID_FRUITORE,
             FRUITORE.RAG_SOC_COGN,
             ORD.ID_CLIENTE_COMMITTENTE,
             aree.DESCRIZIONE_ESTESA,
             sedi.DESCRIZIONE_ESTESA,
             resp.RAG_SOC_COGN,
             cliente_committente.RAG_SOC_COGN,
             ORD.ID_COND_PAGAMENTO,
             cliente_commerciale.RAG_SOC_COGN,
             ORD.TIPO_COMMITTENTE,
             ORD.FLG_ANNULLATO
    order by PIA.id_piano DESC, ord.COD_PRG_ORDINE DESC;
--
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_CERCA_ORDINI;

PROCEDURE PR_TRASFORMA_PIANO_ORDINE(
                                    P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                    P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE) IS
v_prova NUMBER;
    BEGIN
     v_prova := 1;
     EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END PR_TRASFORMA_PIANO_ORDINE;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_INTERM_ERRATO
--
-- DESCRIZIONE:  Controlla se gli intermediari associati ai prodotti acquistati di un piano 
--               sono ancora validi
--
-- OPERAZIONI:   
--
--  INPUT:
--  P_ID_PIANO           Id del piano
--  P_ID_VER_PIANO       Versione del piano
--  P_DATA_INIZIO        Data di inizio del piano
--  P_DATA_FINE          Data di fine del piano
--  P_ID_FRUITORE        Id del cliente fruitore dell'ordine
--
-- OUTPUT:
--   'S' se gli intermediari sono validi, 'N' se anche un solo intermediario non e piu valido
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_INTERM_ERRATO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                          P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                          P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                          P_ID_FRUITORE CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE) RETURN VARCHAR2 IS
v_errato VARCHAR2(1) := 'N';
v_intermediari NUMBER;
v_sqlcode_portafoglio NUMBER;
v_sqlerrm_portafoglio VARCHAR2(255);
v_decorrenza CD_RAGGRUPPAMENTO_INTERMEDIARI.DATA_DECORRENZA%TYPE;
v_venditore_cliente CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE;
v_agenzia CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE;
v_centro_media CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE;
p_esito NUMBER;
BEGIN
 /*   SELECT COUNT(1)
    INTO v_intermediari
    FROM
    CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PIANO = P_ID_PIANO
    AND PA.ID_VER_PIANO = P_ID_VER_PIANO
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.COD_DISATTIVAZIONE IS NULL
    AND PA.STATO_DI_VENDITA = 'PRE'
    AND (P_ID_FRUITORE IS NULL OR PA.ID_FRUITORI_DI_PIANO = P_ID_FRUITORE)
    AND PA.DATA_INIZIO <= P_DATA_FINE
    AND PA.DATA_FINE >= P_DATA_INIZIO
    AND PA.ID_RAGGRUPPAMENTO IS NULL;
    IF v_intermediari > 0 THEN
        v_errato := 'S';
    END IF;
    */
    FOR PACQ IN (SELECT DISTINCT PA.ID_RAGGRUPPAMENTO, PA.DGC, PIA.ID_CLIENTE
                FROM CD_PRODOTTO_ACQUISTATO PA, CD_PIANIFICAZIONE PIA
                WHERE PA.ID_PIANO = P_ID_PIANO
                AND PA.ID_VER_PIANO = P_ID_VER_PIANO
                AND PIA.ID_PIANO = PA.ID_PIANO
                AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
                AND PA.FLG_ANNULLATO = 'N'
                AND PA.FLG_SOSPESO = 'N'
                AND PA.COD_DISATTIVAZIONE IS NULL
                AND PA.STATO_DI_VENDITA = 'PRE'
                AND PA.DATA_INIZIO <= P_DATA_FINE
                AND PA.DATA_FINE >= P_DATA_INIZIO
                AND (P_ID_FRUITORE IS NULL OR PA.ID_FRUITORI_DI_PIANO = P_ID_FRUITORE)) LOOP
    
    IF PACQ.ID_RAGGRUPPAMENTO IS NULL THEN
        v_errato := 'S';  
        EXIT;
    END IF;
    SELECT RI.DATA_DECORRENZA, RI.ID_AGENZIA, RI.ID_CENTRO_MEDIA
    INTO v_decorrenza, v_agenzia, v_centro_media
    FROM CD_RAGGRUPPAMENTO_INTERMEDIARI RI
    WHERE RI.ID_RAGGRUPPAMENTO = PACQ.ID_RAGGRUPPAMENTO;
    --
    --dbms_output.PUT_LINE('Id raggruppamento: '||PACQ.ID_RAGGRUPPAMENTO);
    --dbms_output.PUT_LINE('Dgc: '||PACQ.DGC);
    --dbms_output.PUT_LINE('Decorrenza: '||v_decorrenza);
    --dbms_output.PUT_LINE('Venditore cliente: '||v_venditore_cliente);
    --dbms_output.PUT_LINE('v_agenzia: '||v_agenzia);
    --dbms_output.PUT_LINE('v_centro_media: '||v_centro_media);
    IF v_venditore_cliente IS NOT NULL THEN
        p_esito:=pa_pc_portafoglio.fu_get_venditori_dgc('NO_RAISE',  -- mod_operativa_exception   
                                                  PACQ.DGC,
                                                  'C',-- c_tipo_contratto,
                                                  v_decorrenza,
                                                  PACQ.ID_CLIENTE,                              
                                                  v_agenzia,                          
                                                  v_centro_media,                                       
                                                  v_sqlcode_portafoglio,
                                                  v_sqlerrm_portafoglio,
                                                  'VC');
       --dbms_output.PUT_LINE('Chiamata VC; esito: '||p_esito);
       --dbms_output.PUT_LINE('v_sqlcode_portafoglio'||v_sqlcode_portafoglio);
       --dbms_output.PUT_LINE('v_sqlerrm_portafoglio'||v_sqlerrm_portafoglio);
       IF p_esito < 0 THEN
        v_errato := 'S';  
        EXIT;
       END IF;
    END IF;    
    /*
    IF v_agenzia IS NOT NULL THEN
        p_esito:=pa_pc_portafoglio.fu_get_venditori_dgc('NO_RAISE',  -- mod_operativa_exception   
                                                  PACQ.DGC,
                                                  'C',-- c_tipo_contratto,
                                                  v_decorrenza,
                                                  PACQ.ID_CLIENTE,                              
                                                  v_agenzia,                          
                                                  v_centro_media,                                       
                                                  v_sqlcode_portafoglio,
                                                  v_sqlerrm_portafoglio,
                                                  'VA');
       --dbms_output.PUT_LINE('Chiamata VA; esito: '||p_esito);
       IF p_esito < 0 THEN
        v_errato := 'S';  
        EXIT;
       END IF;
    END IF; 
    
    
    IF v_centro_media IS NOT NULL THEN
        p_esito:=pa_pc_portafoglio.fu_get_venditori_dgc('NO_RAISE',  -- mod_operativa_exception   
                                                  PACQ.DGC,
                                                  'C',-- c_tipo_contratto,
                                                  v_decorrenza,
                                                  PACQ.ID_CLIENTE,                              
                                                  v_agenzia,                          
                                                  v_centro_media,                                       
                                                  v_sqlcode_portafoglio,
                                                  v_sqlerrm_portafoglio,
                                                  'VM');
       --dbms_output.PUT_LINE('Chiamata VM; esito: '||p_esito);
       IF p_esito < 0 THEN
        v_errato := 'S';  
        EXIT;
       END IF;
    END IF;     
    */                                              

   END LOOP; 
RETURN v_errato;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_INTERM_ERRATO;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_SOGGETTO_ERRATO
--
-- DESCRIZIONE:  Controlla se esistono ancora dei comunicati associati al soggetto non definito,
--               per i prodotti acquistati di un piano
--
-- OPERAZIONI:   
--
--  INPUT:
--  P_ID_PIANO           Id del piano
--  P_ID_VER_PIANO       Versione del piano
--  P_DATA_INIZIO        Data di inizio del piano
--  P_DATA_FINE          Data di fine del piano
--  P_ID_FRUITORE        Id del cliente fruitore dell'ordine
--
-- OUTPUT:
--   'S' se tutti i soggetti sono validi, 'N' se esiste ancora un comunicato con soggetto non definito
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_SOGGETTO_ERRATO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                            P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                            P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                            P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                            P_ID_FRUITORE CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE) RETURN VARCHAR2 IS
v_errato VARCHAR2(1) := 'N';
v_num_comunicati NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_num_comunicati
    FROM
    CD_SOGGETTO_DI_PIANO SOGG,
    CD_COMUNICATO COM,
    CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PIANO = P_ID_PIANO
    AND PA.ID_VER_PIANO = P_ID_VER_PIANO
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.COD_DISATTIVAZIONE IS NULL
    AND PA.STATO_DI_VENDITA = 'PRE'
    AND (P_ID_FRUITORE IS NULL OR PA.ID_FRUITORI_DI_PIANO = P_ID_FRUITORE)
    AND PA.DATA_INIZIO <= P_DATA_FINE
    AND PA.DATA_FINE >= P_DATA_INIZIO
    AND COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
    AND COM.ID_SOGGETTO_DI_PIANO = SOGG.ID_SOGGETTO_DI_PIANO
    AND COM.FLG_ANNULLATO = 'N'
    AND COM.FLG_SOSPESO = 'N'
    AND COM.COD_DISATTIVAZIONE IS NULL
    AND SOGG.DESCRIZIONE = 'SOGGETTO NON DEFINITO';
    IF v_num_comunicati > 0 THEN
        v_errato := 'S';
    END IF;
    RETURN v_errato;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_SOGGETTO_ERRATO;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_CLIENTE_ERRATO
--
-- DESCRIZIONE:  Controlla se il cliente commerciale di un piano e valido
--
-- OPERAZIONI:   In base ai filtri di ricerca, restituisce gli ordini cercati
--
--  INPUT:
--  P_ID_PIANO           Id del piano
--  P_ID_VER_PIANO       Versione del piano
--  P_DATA_INIZIO        Data di inizio del piano
--  P_DATA_FINE          Data di fine del piano
--  P_ID_FRUITORE        Id del cliente fruitore dell'ordine
--
-- OUTPUT:
--   'S' se il cliente e valido, 'N' se il cliente non e valido
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CLIENTE_ERRATO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                           P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                           P_ID_CLIENTE CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                           P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                           P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE) RETURN VARCHAR2 IS
v_errato VARCHAR2(1) := 'N';
v_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE;
v_clienti_validi number;
BEGIN
    select count(1) 
    into v_clienti_validi
    from v_rt_clicomm
    where cod_interl = p_id_cliente
    and ((P_DATA_INIZIO between DT_INIZ_VAL and DT_FINE_VAL)
        or
       (P_DATA_FINE between DT_INIZ_VAL and DT_FINE_VAL));
    IF v_clienti_validi = 0 THEN
        v_errato := 'S';
     END IF;
RETURN v_errato;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_CLIENTE_ERRATO;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_FRUITORE_ERRATO
--
-- DESCRIZIONE:  Controlla se il i clienti fruitori associati ai prodotti acquistati
--               di un piano sono validi
--
-- OPERAZIONI:   
--
--  INPUT:
--  P_ID_PIANO           Id del piano
--  P_ID_VER_PIANO       Versione del piano
--  P_DATA_INIZIO        Data di inizio del piano
--  P_DATA_FINE          Data di fine del piano
--  P_ID_FRUITORE        Id del cliente fruitore dell'ordine
--
-- OUTPUT:
--   'S' se i fruitori sono validi, 'N' se almeno un fruitore non e valido
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_FRUITORE_ERRATO(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                            P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                            P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                            P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                            P_ID_FRUITORE CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE) RETURN VARCHAR2 IS
v_errato VARCHAR2(1) := 'N';
v_num_fruitori NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_num_fruitori
    FROM CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PIANO = P_ID_PIANO
    AND PA.ID_VER_PIANO = P_ID_VER_PIANO
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.DATA_INIZIO <= P_DATA_FINE
    AND PA.DATA_FINE >= P_DATA_INIZIO
    AND PA.STATO_DI_VENDITA = 'PRE'
    AND (P_ID_FRUITORE IS NULL OR PA.ID_FRUITORI_DI_PIANO = P_ID_FRUITORE)
    AND PA.ID_FRUITORI_DI_PIANO IS NULL;
    IF v_num_fruitori > 0 THEN
        v_errato := 'S';
    END IF;
    RETURN v_errato;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_FRUITORE_ERRATO;

/*PROCEDURE PR_CREA_ORDINE(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                      P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                      P_ORDINE_VECCHIO CD_ORDINE.ID_ORDINE%TYPE,
                      P_DATA_INIZIO CD_ORDINE.DATA_INIZIO%TYPE,
                      P_DATA_FINE CD_ORDINE.DATA_FINE%TYPE,
                      P_ID_ORDINE OUT CD_ORDINE.ID_ORDINE%TYPE) IS

v_progressivo CD_ORDINE.COD_PRG_ORDINE%TYPE := 0;
v_giorno_inizio_prod NUMBER;
v_giorno_fine_prod NUMBER;
v_data_inizio_fatt CD_IMPORTI_FATTURAZIONE.DATA_INIZIO%TYPE;
v_data_fine_fatt CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE;
v_giorni_periodo NUMBER;
v_netto_giorno NUMBER;
v_netto_parziale NUMBER;
v_num_importi NUMBER;
BEGIN
    SAVEPOINT PR_CREA_ORDINE;
--
    IF P_ORDINE_VECCHIO IS NULL THEN
        SELECT NVL(MAX(COD_PRG_ORDINE),0)
        INTO v_progressivo
        FROM CD_ORDINE
        WHERE ID_PIANO = P_ID_PIANO
        AND ID_VER_PIANO = P_ID_VER_PIANO;
    --
        v_progressivo := v_progressivo +1;

        INSERT INTO CD_ORDINE(ID_PIANO, ID_VER_PIANO, COD_PRG_ORDINE, ID_CLIENTE_FRUITORE)
        SELECT P_ID_PIANO, P_ID_VER_PIANO, v_progressivo,
        (SELECT id_cliente_fruitore from cd_fruitori_di_piano
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
             and rownum = 1) AS FRUITORE
        FROM DUAL;
    --
        SELECT CD_ORDINE_SEQ.CURRVAL INTO P_ID_ORDINE FROM DUAL;
    ELSE
        P_ID_ORDINE := P_ORDINE_VECCHIO;
    END IF;
    FOR PACQ IN (SELECT * FROM CD_PRODOTTO_ACQUISTATO PA
                WHERE ID_PIANO = P_ID_PIANO
                AND ID_VER_PIANO = P_ID_VER_PIANO
                AND FLG_ANNULLATO = 'N'
                AND FLG_SOSPESO = 'N'
                AND STATO_DI_VENDITA = 'PRE'
                AND
                ((SELECT COUNT(1) FROM CD_IMPORTI_PRODOTTO IMPP, CD_IMPORTI_FATTURAZIONE IMPF
                     WHERE IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                     AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO) = 0
                     OR (SELECT COUNT(1) FROM CD_IMPORTI_PRODOTTO IMPP, CD_IMPORTI_FATTURAZIONE IMPF
                     WHERE IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                     AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                     AND IMPF.ID_ORDINE IS NULL) > 0)
                ORDER BY DATA_INIZIO)LOOP

        FOR IMPP IN (SELECT * FROM CD_IMPORTI_PRODOTTO IMP
                     WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO
                     AND (TIPO_CONTRATTO = 'C'
                     OR (TIPO_CONTRATTO = 'D' AND IMP_NETTO > 0))  ) LOOP
            v_giorno_inizio_prod := to_number(to_char(PACQ.DATA_INIZIO,'DD'));
            v_giorno_fine_prod := to_number(to_char(PACQ.DATA_FINE,'DD'));
            v_netto_giorno := IMPP.IMP_NETTO / (PACQ.DATA_FINE - PACQ.DATA_INIZIO +1);
            IF v_giorno_inizio_prod <= 15 THEN
                v_data_inizio_fatt := PACQ.DATA_INIZIO - v_giorno_inizio_prod +1;
                v_data_fine_fatt := v_data_inizio_fatt + 14;
                IF v_giorno_fine_prod <= 15 THEN
                    INSERT INTO CD_IMPORTI_FATTURAZIONE(IMPORTO_NETTO, DATA_INIZIO, DATA_FINE, ID_ORDINE, ID_IMPORTI_PRODOTTO)
                    VALUES(IMPP.IMP_NETTO, v_data_inizio_fatt, v_data_fine_fatt, P_ID_ORDINE, IMPP.ID_IMPORTI_PRODOTTO);
                ELSE
                    v_giorni_periodo := v_data_fine_fatt - PACQ.DATA_INIZIO +1;
                    v_netto_parziale := ROUND(v_netto_giorno * v_giorni_periodo,2);
                    INSERT INTO CD_IMPORTI_FATTURAZIONE(IMPORTO_NETTO, DATA_INIZIO, DATA_FINE, ID_ORDINE, ID_IMPORTI_PRODOTTO)
                    VALUES(v_netto_parziale, v_data_inizio_fatt, v_data_fine_fatt, P_ID_ORDINE, IMPP.ID_IMPORTI_PRODOTTO);
                    v_data_inizio_fatt := v_data_fine_fatt + 1;
                    v_data_fine_fatt := LAST_DAY(v_data_inizio_fatt);
                    SELECT COUNT(1)
                    INTO v_num_importi
                    FROM CD_IMPORTI_FATTURAZIONE
                    WHERE ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                    AND DATA_INIZIO = v_data_inizio_fatt
                    AND DATA_FINE = v_data_fine_fatt
                    AND ID_ORDINE IS NULL;
                    v_netto_parziale := IMPP.IMP_NETTO - v_netto_parziale;
                    IF v_num_importi = 0 THEN
                        v_giorni_periodo := PACQ.DATA_FINE - v_data_inizio_fatt +1;
                        INSERT INTO CD_IMPORTI_FATTURAZIONE(IMPORTO_NETTO, DATA_INIZIO, DATA_FINE, ID_ORDINE, ID_IMPORTI_PRODOTTO)
                        VALUES(v_netto_parziale, v_data_inizio_fatt, v_data_fine_fatt, P_ID_ORDINE, IMPP.ID_IMPORTI_PRODOTTO);
                    END IF;
                END IF;
            ELSE
                v_data_inizio_fatt := PACQ.DATA_INIZIO - v_giorno_inizio_prod + 16;
                v_data_fine_fatt := LAST_DAY(v_data_inizio_fatt);
                IF PACQ.DATA_FINE <= v_data_fine_fatt THEN
                    INSERT INTO CD_IMPORTI_FATTURAZIONE(IMPORTO_NETTO, DATA_INIZIO, DATA_FINE, ID_ORDINE, ID_IMPORTI_PRODOTTO)
                    VALUES(IMPP.IMP_NETTO, v_data_inizio_fatt, v_data_fine_fatt, P_ID_ORDINE, IMPP.ID_IMPORTI_PRODOTTO);
                ELSE
                    v_data_inizio_fatt := v_data_fine_fatt +1;
                    v_data_fine_fatt := v_data_inizio_fatt +15;
                    v_giorni_periodo := v_data_fine_fatt - PACQ.DATA_INIZIO +1;
                    v_netto_parziale := ROUND(v_netto_giorno * v_giorni_periodo,2);
                    INSERT INTO CD_IMPORTI_FATTURAZIONE(IMPORTO_NETTO, DATA_INIZIO, DATA_FINE, ID_ORDINE, ID_IMPORTI_PRODOTTO)
                    VALUES(v_netto_parziale, v_data_inizio_fatt, v_data_fine_fatt, P_ID_ORDINE, IMPP.ID_IMPORTI_PRODOTTO);
                    v_data_inizio_fatt := v_data_fine_fatt + 1;
                    v_data_fine_fatt := v_data_inizio_fatt + 15;
                    SELECT COUNT(1)
                    INTO v_num_importi
                    FROM CD_IMPORTI_FATTURAZIONE
                    WHERE ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                    AND DATA_INIZIO = v_data_inizio_fatt
                    AND DATA_FINE = v_data_fine_fatt
                    AND ID_ORDINE IS NULL;
                    IF v_num_importi = 0 THEN
                        v_giorni_periodo := PACQ.DATA_FINE - v_data_inizio_fatt;
                        v_netto_parziale := IMPP.IMP_NETTO - v_netto_parziale;
                        INSERT INTO CD_IMPORTI_FATTURAZIONE(IMPORTO_NETTO, DATA_INIZIO, DATA_FINE, ID_ORDINE, ID_IMPORTI_PRODOTTO)
                        VALUES(v_netto_parziale, v_data_inizio_fatt, v_data_fine_fatt, P_ID_ORDINE, IMPP.ID_IMPORTI_PRODOTTO);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    UPDATE CD_ORDINE
    SET DATA_INIZIO = (SELECT MIN(DATA_INIZIO) FROM CD_IMPORTI_FATTURAZIONE WHERE ID_ORDINE = P_ID_ORDINE),
        DATA_FINE = (SELECT MAX(DATA_FINE) FROM CD_IMPORTI_FATTURAZIONE WHERE ID_ORDINE = P_ID_ORDINE)
    WHERE ID_ORDINE = P_ID_ORDINE;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_CREA_ORDINE: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_CREA_ORDINE;
END PR_CREA_ORDINE;
*/



PROCEDURE PR_CREA_ORDINE_PARZIALE(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                      P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                      P_ORDINE_VECCHIO CD_ORDINE.ID_ORDINE%TYPE,
                      P_DATA_INIZIO CD_ORDINE.DATA_INIZIO%TYPE,
                      P_DATA_FINE CD_ORDINE.DATA_FINE%TYPE,
                      P_ID_FRUITORE CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE,
                      P_ID_ORDINE OUT CD_ORDINE.ID_ORDINE%TYPE) IS

v_progressivo CD_ORDINE.COD_PRG_ORDINE%TYPE := 0;
v_giorno_inizio_prod NUMBER;
v_giorno_fine_prod NUMBER;
v_data_inizio_fatt CD_IMPORTI_FATTURAZIONE.DATA_INIZIO%TYPE;
v_data_fine_fatt CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE;
v_data_inizio_temp CD_IMPORTI_FATTURAZIONE.DATA_INIZIO%TYPE;
v_data_fine_temp CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE;
v_data_inizio_seg CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE;
v_giorni_compresi NUMBER;
v_netto_giorno NUMBER;
v_netto_parziale NUMBER;
v_num_importi NUMBER;
v_netto_fatturazione NUMBER := 0;
v_giorni_fatturati NUMBER := 0;
v_giorni_prodotto NUMBER;
v_netto_fatturato NUMBER := 0;
v_list_imp_fatt id_list_type := id_list_type();
v_index NUMBER :=1;
v_committente CD_FRUITORI_DI_PIANO.ID_CLIENTE_FRUITORE%TYPE;
v_id_cond_pagamento  cd_ordine.id_cond_pagamento%type:= '01';
BEGIN
    
--
    IF P_ORDINE_VECCHIO IS NULL THEN
        SELECT NVL(MAX(COD_PRG_ORDINE),0)
        INTO v_progressivo
        FROM CD_ORDINE
        WHERE ID_PIANO = P_ID_PIANO
        AND ID_VER_PIANO = P_ID_VER_PIANO
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N';
    --
        v_progressivo := v_progressivo +1;

        SELECT ID_CLIENTE_FRUITORE
        INTO v_committente
        FROM CD_FRUITORI_DI_PIANO
        WHERE ID_FRUITORI_DI_PIANO = P_ID_FRUITORE;
        
        select decode(flg_cambio_merce,'N','01','S','19') 
        into  v_id_cond_pagamento 
        from  cd_pianificazione
        where id_piano = p_id_piano
        and   id_ver_piano = p_id_ver_piano;

        INSERT INTO CD_ORDINE(ID_PIANO, ID_VER_PIANO, COD_PRG_ORDINE, ID_FRUITORI_DI_PIANO, DATA_INIZIO, DATA_FINE, TIPO_COMMITTENTE, ID_CLIENTE_COMMITTENTE,ID_COND_PAGAMENTO)
        SELECT P_ID_PIANO, P_ID_VER_PIANO, v_progressivo,
        P_ID_FRUITORE,
        P_DATA_INIZIO, P_DATA_FINE,
        'CL',v_committente,v_id_cond_pagamento--'01'
        FROM DUAL;
    --
        SELECT CD_ORDINE_SEQ.CURRVAL INTO P_ID_ORDINE FROM DUAL;
    ELSE
        P_ID_ORDINE := P_ORDINE_VECCHIO;
        UPDATE CD_ORDINE
        SET DATA_INIZIO = P_DATA_INIZIO
        WHERE ID_ORDINE = P_ID_ORDINE
        AND DATA_INIZIO > P_DATA_INIZIO;
        UPDATE CD_ORDINE
        SET DATA_FINE = P_DATA_FINE
        WHERE ID_ORDINE = P_ID_ORDINE
        AND DATA_FINE < P_DATA_FINE;
    END IF;
    --
    FOR PACQ IN (SELECT * FROM CD_PRODOTTO_ACQUISTATO PA
                WHERE ID_PIANO = P_ID_PIANO
                AND ID_VER_PIANO = P_ID_VER_PIANO
                AND FLG_ANNULLATO = 'N'
                AND FLG_SOSPESO = 'N'
                AND COD_DISATTIVAZIONE IS NULL
                AND STATO_DI_VENDITA = 'PRE'
                AND ID_FRUITORI_DI_PIANO = P_ID_FRUITORE
                AND (   (PA.DATA_INIZIO < P_DATA_INIZIO AND PA.DATA_FINE >= P_DATA_INIZIO)
                     OR (PA.DATA_INIZIO >= P_DATA_INIZIO AND PA.DATA_FINE <= P_DATA_FINE)
                     OR (PA.DATA_INIZIO <= P_DATA_FINE AND PA.DATA_FINE > P_DATA_FINE)
                     OR (PA.DATA_INIZIO < P_DATA_INIZIO AND PA.DATA_FINE > P_DATA_FINE))
                ORDER BY DATA_INIZIO)LOOP

            SELECT NVL(TOT_NETTO,0)
            INTO v_netto_fatturazione
            FROM
                (SELECT SUM(IMPF.IMPORTO_NETTO) AS TOT_NETTO
                 FROM CD_IMPORTI_FATTURAZIONE IMPF, CD_ORDINE ORD
                          WHERE IMPF.ID_ORDINE = ORD.ID_ORDINE
                          AND IMPF.FLG_ANNULLATO = 'N'
                          AND ORD.FLG_ANNULLATO = 'N'
                          AND ORD.FLG_SOSPESO = 'N'
                          AND IMPF.ID_IMPORTI_PRODOTTO IN
                           (SELECT ID_IMPORTI_PRODOTTO FROM CD_IMPORTI_PRODOTTO
                            WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO));
            SELECT NVL(SUM(GIORNI),0)
            INTO v_giorni_fatturati
            FROM
                (SELECT SUM(LEAST(IMPF.DATA_FINE, P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,P_DATA_INIZIO) +1) / COUNT(1) AS GIORNI, COUNT(1)
                 FROM CD_IMPORTI_FATTURAZIONE IMPF, CD_ORDINE ORD
                          WHERE IMPF.ID_ORDINE = ORD.ID_ORDINE
                          AND ORD.FLG_ANNULLATO = 'N'
                          AND ORD.FLG_SOSPESO = 'N'
                          AND IMPF.DATA_INIZIO <= P_DATA_FINE
                          AND IMPF.DATA_FINE >= P_DATA_INIZIO
                          AND IMPF.FLG_ANNULLATO = 'N'
                          AND IMPF.ID_IMPORTI_PRODOTTO IN
                           (SELECT ID_IMPORTI_PRODOTTO FROM CD_IMPORTI_PRODOTTO
                            WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO)
                 GROUP BY  IMPF.DATA_INIZIO, IMPF.DATA_FINE);
            v_giorni_compresi := LEAST(PACQ.DATA_FINE,P_DATA_FINE) - GREATEST(PACQ.DATA_INIZIO,P_DATA_INIZIO) +1;    
            IF v_giorni_compresi > v_giorni_fatturati THEN                        
            --IF PACQ.IMP_NETTO > v_netto_fatturazione THEN
                --dbms_output.put_line('Prodotto acquistato con id: '||PACQ.ID_PRODOTTO_ACQUISTATO);
                v_giorni_prodotto := PACQ.DATA_FINE - PACQ.DATA_INIZIO +1;
                /* SELECT COUNT(DISTINCT DATA_EROGAZIONE_PREV)
                INTO v_giorni_prodotto
                FROM CD_COMUNICATO
                WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO
                AND FLG_ANNULLATO = 'N'
                AND FLG_SOSPESO = 'N'
                AND COD_DISATTIVAZIONE IS NULL;*/
                --dbms_output.put_line('Giorni da fatturare nel periodo: '||v_giorni_prodotto);
                FOR IMPP IN (SELECT * FROM CD_IMPORTI_PRODOTTO IMP
                     WHERE ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO
                     ) LOOP
                     v_netto_fatturazione := ROUND(IMPP.IMP_NETTO / v_giorni_prodotto * v_giorni_compresi,2);
                      --dbms_output.put_line('Netto fatturazione: '||v_netto_fatturazione);
                    v_index := 1;
                    --dbms_output.put_line('Importo prodotto con id: '||IMPP.ID_IMPORTI_PRODOTTO);
                    v_list_imp_fatt := id_list_type();
                    FOR IMPF IN (SELECT CD_IMPORTI_FATTURAZIONE.* FROM CD_IMPORTI_FATTURAZIONE, CD_ORDINE
                                WHERE CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                                AND CD_IMPORTI_FATTURAZIONE.FLG_ANNULLATO = 'N'
                                AND CD_ORDINE.ID_ORDINE = CD_IMPORTI_FATTURAZIONE.ID_ORDINE
                                AND CD_ORDINE.FLG_ANNULLATO = 'N'
                                AND CD_ORDINE.FLG_SOSPESO = 'N'
                                ORDER BY CD_IMPORTI_FATTURAZIONE.DATA_INIZIO)LOOP
                      v_list_imp_fatt.EXTEND;
                      v_list_imp_fatt(v_index) := IMPF.ID_IMPORTI_FATTURAZIONE;
                      v_index := v_index +1;
                    END LOOP;
                    --dbms_output.put_line('Numero di importi fatturazione: '||v_list_imp_fatt.COUNT);
                    v_data_inizio_fatt := GREATEST(PACQ.DATA_INIZIO,P_DATA_INIZIO);
                    v_data_fine_fatt := LEAST(PACQ.DATA_FINE,P_DATA_FINE);
                    --dbms_output.put_line('Data inizio fatturazione: '||v_data_inizio_fatt);
                    --dbms_output.put_line('Data fine fatturazione: '||v_data_fine_fatt);
                    --dbms_output.put_line('Numero di importi fatturazione: '||v_list_imp_fatt.COUNT);
                    IF v_list_imp_fatt.COUNT = 0 THEN
                    PR_CREA_IMPORTO_FATTURAZIONE(
                                                 IMPP.ID_IMPORTI_PRODOTTO,
                                                 IMPP.IMP_NETTO,
                                                 P_ID_ORDINE,
                                                 V_GIORNI_PRODOTTO,
                                                 v_data_inizio_fatt,
                                                 v_data_fine_fatt);
                    ELSE
                        FOR i IN 1..v_list_imp_fatt.COUNT LOOP
                            SELECT DATA_INIZIO, DATA_FINE
                            INTO v_data_inizio_temp, v_data_fine_temp
                            FROM CD_IMPORTI_FATTURAZIONE
                            WHERE ID_IMPORTI_FATTURAZIONE = v_list_imp_fatt(i);
                            --dbms_output.put_line('Data inizio temp: '||v_data_inizio_temp);
                            --dbms_output.put_line('Data fine temp: '||v_data_fine_temp);
                            IF i = 1 AND v_data_inizio_temp > v_data_inizio_fatt THEN
                               -- v_data_fine_fatt := v_data_inizio_temp - 1;
                                PR_CREA_IMPORTO_FATTURAZIONE(
                                     IMPP.ID_IMPORTI_PRODOTTO,
                                     IMPP.IMP_NETTO,
                                     P_ID_ORDINE,
                                     V_GIORNI_PRODOTTO,
                                     v_data_inizio_fatt,
                                     LEAST(P_DATA_FINE,v_data_inizio_temp - 1));
                            END IF;
                            IF v_list_imp_fatt.COUNT > i THEN
                            --dbms_output.put_line('Importo fatturazione i+1:'||v_list_imp_fatt(i+1));
                            --dbms_output.put_line('Numero elementi:'||v_list_imp_fatt.COUNT);
                            --dbms_output.put_line('indice'||i);
                            SELECT DATA_INIZIO
                            INTO v_data_inizio_seg
                            FROM CD_IMPORTI_FATTURAZIONE
                            WHERE ID_IMPORTI_FATTURAZIONE = v_list_imp_fatt(i+1);
                            IF v_data_fine_temp < v_data_inizio_seg -1 THEN
                                PR_CREA_IMPORTO_FATTURAZIONE(
                                     IMPP.ID_IMPORTI_PRODOTTO,
                                     IMPP.IMP_NETTO,
                                     P_ID_ORDINE,
                                     V_GIORNI_PRODOTTO,
                                     GREATEST(P_DATA_INIZIO,v_data_fine_temp + 1),
                                     LEAST(P_DATA_FINE,v_data_inizio_seg -1));
                                END IF;
                            END IF;
                            IF v_list_imp_fatt.COUNT = i AND v_data_fine_temp < v_data_fine_fatt THEN
                                PR_CREA_IMPORTO_FATTURAZIONE(
                                     IMPP.ID_IMPORTI_PRODOTTO,
                                     IMPP.IMP_NETTO,
                                     P_ID_ORDINE,
                                     V_GIORNI_PRODOTTO,
                                     GREATEST(P_DATA_INIZIO,v_data_fine_temp +1),
                                     v_data_fine_fatt);
                            END IF;
                        END LOOP;
                    END IF;
    --
                END LOOP;
            END IF;
     END LOOP;
    UPDATE CD_ORDINE ORD
    SET DATA_INIZIO = LEAST(ORD.DATA_INIZIO,NVL(to_date('31122099','DDMMYYYY'),(SELECT MIN(DATA_INIZIO) FROM CD_IMPORTI_FATTURAZIONE WHERE ID_ORDINE = P_ID_ORDINE))),
        DATA_FINE = GREATEST(ORD.DATA_FINE,NVL(to_date('01011999','DDMMYYYY'),(SELECT MAX(DATA_FINE) FROM CD_IMPORTI_FATTURAZIONE WHERE ID_ORDINE = P_ID_ORDINE)))
    WHERE ORD.ID_ORDINE = P_ID_ORDINE;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_CREA_ORDINE_PARZIALE: Si e'' verificato un errore  '||SQLERRM);
END PR_CREA_ORDINE_PARZIALE;

FUNCTION FU_DETTAGLIO_ORDINE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE) RETURN  C_ORDINE IS
CUR C_ORDINE;
BEGIN
    OPEN CUR for
    SELECT PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           ORD.ID_ORDINE,
           ORD.COD_PRG_ORDINE,
           ORD.DATA_INIZIO,
           ORD.DATA_FINE,
           FRUITORE.ID_FRUITORE,
           FRUITORE.RAG_SOC_COGN as desc_fruitore,
           ORD.ID_CLIENTE_COMMITTENTE,
           aree.DESCRIZIONE_ESTESA as desc_area,
           sedi.DESCRIZIONE_ESTESA as desc_sede,
           resp.RAG_SOC_COGN as responsabile_contatto,
           cliente.RAG_SOC_COGN as desc_cliente_committente,
           ORD.ID_COND_PAGAMENTO,
           cliente_commerciale.RAG_SOC_COGN as desc_cliente_commerciale,
           ORD.TIPO_COMMITTENTE,
           0 AS TOTALE_NETTO,
           ORD.FLG_ANNULLATO
    FROM
         VI_CD_AREE_SEDI_COMPET ARSE,
         aree,
         sedi,
         interl_u cliente,
         interl_u resp,
         vi_cd_cliente_fruitore fruitore,
         cd_fruitori_di_piano fp,
         vi_cd_cliente cliente_commerciale,
         CD_ORDINE ord,
         CD_PIANIFICAZIONE pia
    WHERE ID_ORDINE = P_ID_ORDINE
    AND    ord.ID_PIANO = pia.ID_PIANO
    AND    ord.ID_VER_PIANO = pia.ID_VER_PIANO
    AND    ord.FLG_ANNULLATO = 'N'
    AND    ord.FLG_SOSPESO = 'N'
    AND   FP.ID_FRUITORI_DI_PIANO = ORD.ID_FRUITORI_DI_PIANO
    AND FRUITORE.ID_FRUITORE = FP.ID_CLIENTE_FRUITORE
    AND cliente.COD_INTERL = ORD.ID_CLIENTE_COMMITTENTE
    AND cliente_commerciale.ID_CLIENTE = PIA.ID_CLIENTE
    AND resp.COD_INTERL = PIA.ID_RESPONSABILE_CONTATTO
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    and aree.COD_AREA = ARSE.COD_AREA
    and sedi.COD_SEDE = ARSE.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S'  , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
    order by PIA.id_piano DESC, ord.COD_PRG_ORDINE DESC;
--
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_DETTAGLIO_ORDINE;

PROCEDURE PR_CREA_IMPORTO_FATTURAZIONE(P_ID_IMPORTO_PRODOTTO CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE,
                                       P_NETTO CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE,
                                       P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE,
                                       P_GIORNI_PRODOTTO NUMBER,
                                       P_DATA_INIZIO CD_IMPORTI_FATTURAZIONE.DATA_INIZIO%TYPE,
                                       P_DATA_FINE CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE) IS
--
v_netto_fatturazione CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
v_netto_fatturato CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
v_giorni_fatturati NUMBER;
v_giorni_compresi NUMBER;
v_descrizione CD_IMPORTI_FATTURAZIONE.DESC_PRODOTTO%TYPE;
v_tipo_break CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE;
v_desc_tipo_break CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE;
v_netto_soggetto CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
v_netto_parziale CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE := 0;
v_index NUMBER := 0;
v_num_sogg NUMBER := 1;
V_PERC_SSDA CD_IMPORTI_FATTURAZIONE.PERC_SCONTO_SOST_AGE%TYPE;
V_ID_COND_PAGAMENTO CD_ORDINE.ID_COND_PAGAMENTO%TYPE;
V_PERC_VEND_CLI CD_IMPORTI_FATTURAZIONE.PERC_VEND_CLI%TYPE;
V_RAGGRUPPAMENTO_INTERMEDIARI CD_RAGGRUPPAMENTO_INTERMEDIARI%ROWTYPE;
V_DGC_TC_ID CD_IMPORTI_PRODOTTO.DGC_TC_ID%TYPE;
BEGIN
     v_giorni_compresi := P_DATA_FINE - P_DATA_INIZIO +1;
     /*SELECT COUNT(DISTINCT C.DATA_EROGAZIONE_PREV)
     INTO v_giorni_compresi
     FROM CD_COMUNICATO C, CD_IMPORTI_PRODOTTO IMPP
     WHERE IMPP.ID_IMPORTI_PRODOTTO = P_ID_IMPORTO_PRODOTTO
     AND C.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
     AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_INIZIO AND P_DATA_FINE
     AND C.FLG_ANNULLATO = 'N'
     AND C.FLG_SOSPESO = 'N'
     AND C.COD_DISATTIVAZIONE IS NULL;
     */
     --
     SELECT PV.ID_TIPO_BREAK, CIR.NOME_CIRCUITO ||' - '||MV.DESC_MOD_VENDITA AS DESC_PRODOTTO
     INTO v_tipo_break, v_descrizione
     FROM CD_IMPORTI_PRODOTTO IMPP, CD_PRODOTTO_ACQUISTATO PA, CD_PRODOTTO_VENDITA PV,
          CD_CIRCUITO CIR, CD_MODALITA_VENDITA MV
     WHERE IMPP.ID_IMPORTI_PRODOTTO = P_ID_IMPORTO_PRODOTTO
     AND IMPP.ID_PRODOTTO_aCQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
     AND PA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
     AND PV.ID_CIRCUITO = CIR.ID_CIRCUITO
     AND PV.ID_MOD_VENDITA = MV.ID_MOD_VENDITA;
--
     IF v_tipo_break IS NOT NULL THEN
        SELECT DESC_TIPO_BREAK
        INTO v_desc_tipo_break
        FROM CD_TIPO_BREAK
        WHERE ID_TIPO_BREAK = v_tipo_break;
        v_descrizione := v_descrizione || ' - ' || v_desc_tipo_break;
     END IF;

     SELECT NVL(GIORNI,0), NVL(NETTO_FATTURATO,0)
     INTO v_giorni_fatturati, v_netto_fatturato
     FROM
     (SELECT SUM(IMPF.DATA_FINE - IMPF.DATA_INIZIO +1) AS GIORNI, SUM(IMPF.IMPORTO_NETTO) AS NETTO_FATTURATO FROM CD_IMPORTI_FATTURAZIONE IMPF
               WHERE IMPF.ID_IMPORTI_PRODOTTO = P_ID_IMPORTO_PRODOTTO
               AND IMPF.FLG_ANNULLATO = 'N');
     --          
     IF (p_giorni_prodotto > v_giorni_fatturati + v_giorni_compresi) THEN
         v_netto_fatturazione := ROUND(P_NETTO / p_giorni_prodotto * v_giorni_compresi,2);
     ELSE
         v_netto_fatturazione := P_NETTO - v_netto_fatturato;
     END IF;
     SELECT COUNT(DISTINCT COM.ID_SOGGETTO_DI_PIANO)
     INTO v_num_sogg
     FROM CD_COMUNICATO COM,
     CD_PRODOTTO_ACQUISTATO PA,
     CD_IMPORTI_PRODOTTO IMPP
     WHERE IMPP.ID_IMPORTI_PRODOTTO = P_ID_IMPORTO_PRODOTTO
     AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
     AND COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
     AND COM.FLG_ANNULLATO = 'N'
     AND COM.FLG_SOSPESO = 'N'
     AND COM.COD_DISATTIVAZIONE IS NULL;
     --
     FOR SOGG IN (SELECT DISTINCT COM.ID_SOGGETTO_DI_PIANO
                 FROM CD_COMUNICATO COM,
                 CD_PRODOTTO_ACQUISTATO PA,
                 CD_IMPORTI_PRODOTTO IMPP
                 WHERE IMPP.ID_IMPORTI_PRODOTTO = P_ID_IMPORTO_PRODOTTO
                 AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
                 AND COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                 AND COM.FLG_ANNULLATO = 'N'
                 AND COM.FLG_SOSPESO = 'N'
                 AND COM.COD_DISATTIVAZIONE IS NULL
                 GROUP BY COM.ID_SOGGETTO_DI_PIANO) LOOP
    --
         v_index := v_index +1;
         IF v_index < v_num_sogg THEN
            v_netto_soggetto := ROUND(v_netto_fatturazione / v_num_sogg,2);
         ELSE
            v_netto_soggetto := v_netto_fatturazione - v_netto_parziale;
         END IF;


         SELECT ID_COND_PAGAMENTO
         INTO V_ID_COND_PAGAMENTO
         FROM CD_ORDINE
         WHERE ID_ORDINE = P_ID_ORDINE;

        SELECT RAG.* INTO V_RAGGRUPPAMENTO_INTERMEDIARI FROM
        CD_PRODOTTO_ACQUISTATO PA,CD_RAGGRUPPAMENTO_INTERMEDIARI RAG,CD_IMPORTI_PRODOTTO  IP
        WHERE IP.ID_IMPORTI_PRODOTTO = P_ID_IMPORTO_PRODOTTO
        AND   IP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
        AND   RAG.ID_RAGGRUPPAMENTO = PA.ID_RAGGRUPPAMENTO;
--
        SELECT DGC_TC_ID
        INTO V_DGC_TC_ID
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_IMPORTI_PRODOTTO = P_ID_IMPORTO_PRODOTTO;
--
        V_PERC_SSDA      :=  FU_CD_GET_PERC_SSDA(V_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO,V_ID_COND_PAGAMENTO);
        V_PERC_VEND_CLI  :=  FU_CD_GET_PERC_CLI(V_DGC_TC_ID ,V_ID_COND_PAGAMENTO ,V_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO);
--
         INSERT INTO CD_IMPORTI_FATTURAZIONE(IMPORTO_NETTO, DATA_INIZIO, DATA_FINE, ID_ORDINE, ID_IMPORTI_PRODOTTO, ID_SOGGETTO_DI_PIANO,DESC_PRODOTTO,PERC_SCONTO_SOST_AGE,PERC_VEND_CLI)
         VALUES(v_netto_soggetto, P_DATA_INIZIO, P_DATA_FINE, P_ID_ORDINE, P_ID_IMPORTO_PRODOTTO, SOGG.ID_SOGGETTO_DI_PIANO, v_descrizione,V_PERC_SSDA,V_PERC_VEND_CLI);
     --
         v_netto_parziale := v_netto_parziale + v_netto_soggetto;
     END LOOP;

END PR_CREA_IMPORTO_FATTURAZIONE;

FUNCTION FU_GET_CLIENTE_COMMITTENTE(P_ID_CLIENTE RAGGRUPPAMENTO_U.COD_INTERL_P%TYPE,
                                    P_TIPO_RAGGR RAGGRUPPAMENTO_U.TIPO_RAGGRUPP%TYPE,
                                    P_DATA_INIZIO CD_ORDINE.DATA_INIZIO%TYPE,
                                    P_DATA_FINE CD_ORDINE.DATA_FINE%TYPE) RETURN C_CLIENTE_COMMITTENTE IS
v_clienti_committenti C_CLIENTE_COMMITTENTE;
BEGIN
    IF P_TIPO_RAGGR = 'CL' THEN
        OPEN v_clienti_committenti FOR
        select iu.cod_interl, iu.rag_soc_cogn from interl_u iu
        where iu.cod_interl = P_ID_CLIENTE;
    ELSE
        OPEN v_clienti_committenti FOR
        select distinct iu.cod_interl, iu.rag_soc_cogn--, iu.rag_soc_br_nome, iu.indirizzo, iu.localita
        from interl_u iu, raggruppamento_u rg, classif_interl_u cl
        where rg.tipo_raggrupp = 'FRCO'
        and iu.cod_interl =  rg.cod_interl_f
        and cl.cod_interl = iu.cod_interl
        and cl.tipo_class = P_TIPO_RAGGR
        and rg.cod_interl_p = P_ID_CLIENTE
        and P_DATA_INIZIO >= iu.dt_iniz_val
        and P_DATA_FINE <= iu.dt_fine_val
        order by 2;
    END IF;
RETURN v_clienti_committenti;
END FU_GET_CLIENTE_COMMITTENTE;

FUNCTION FU_GET_COND_PAGAMENTO(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE) RETURN C_COND_PAGAMENTO IS
v_cond_pagamento C_COND_PAGAMENTO;
BEGIN
    OPEN v_cond_pagamento FOR
    SELECT COD_CPAG, DES_CPAG FROM COND_PAGAMENTO;
RETURN v_cond_pagamento;
END FU_GET_COND_PAGAMENTO;

PROCEDURE PR_MODIFICA_ORDINE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE,
                             P_COND_PAGAMENTO CD_ORDINE.ID_COND_PAGAMENTO%TYPE,
                             P_ID_COMMITTENTE CD_ORDINE.ID_CLIENTE_COMMITTENTE%TYPE,
                             P_TIPO_COMMITTENTE CD_ORDINE.TIPO_COMMITTENTE%TYPE) IS
v_cond_pagamento CD_ORDINE.ID_COND_PAGAMENTO%TYPE;
v_id_committente CD_ORDINE.ID_CLIENTE_COMMITTENTE%TYPE;
v_perc_cli NUMBER;
BEGIN
     
     SELECT ID_COND_PAGAMENTO, ID_CLIENTE_COMMITTENTE
     INTO v_cond_pagamento, v_id_committente
     FROM CD_ORDINE 
     WHERE ID_ORDINE = P_ID_ORDINE;
     --
     IF v_id_committente != P_ID_COMMITTENTE THEN
        UPDATE CD_ORDINE
        SET ID_CLIENTE_COMMITTENTE = P_ID_COMMITTENTE,
        TIPO_COMMITTENTE = P_TIPO_COMMITTENTE
        WHERE ID_ORDINE = P_ID_ORDINE;
        --
        UPDATE CD_IMPORTI_FATTURAZIONE
        SET STATO_FATTURAZIONE = 'DAR'
        WHERE ID_ORDINE = P_ID_ORDINE
        AND STATO_FATTURAZIONE = 'TRA';
     END IF;
     --
     IF v_cond_pagamento != P_COND_PAGAMENTO THEN
        UPDATE CD_ORDINE
        SET ID_COND_PAGAMENTO = P_COND_PAGAMENTO
        WHERE ID_ORDINE = P_ID_ORDINE;
        --
        UPDATE CD_IMPORTI_FATTURAZIONE
        SET STATO_FATTURAZIONE = 'DAR'
        WHERE ID_ORDINE = P_ID_ORDINE
        AND STATO_FATTURAZIONE = 'TRA'
        AND FLG_ANNULLATO = 'N';
        FOR PACQ IN (SELECT DISTINCT PA.ID_PRODOTTO_ACQUISTATO, PA.ID_RAGGRUPPAMENTO
             FROM CD_PRODOTTO_ACQUISTATO PA,
             CD_IMPORTI_PRODOTTO IMPP,
             CD_IMPORTI_FATTURAZIONE IMPF
             WHERE IMPF.ID_ORDINE = P_ID_ORDINE
             AND IMPF.FLG_ANNULLATO = 'N'
             AND IMPP.ID_IMPORTI_PRODOTTO = IMPF.ID_IMPORTI_PRODOTTO
             AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
             AND PA.FLG_ANNULLATO = 'N'
             AND PA.FLG_SOSPESO = 'N'
             AND PA.COD_DISATTIVAZIONE IS NULL
         )LOOP
            PR_MODIFICA_ALIQUOTE(PACQ.ID_RAGGRUPPAMENTO, PACQ.ID_PRODOTTO_ACQUISTATO);
         END LOOP;
     END IF;
     --
        /* FOR FAT IN(SELECT
                    IMPF.ID_IMPORTI_FATTURAZIONE,
                    IMPP.DGC_TC_ID,
                    RI.DATA_DECORRENZA,
                    PIA.ID_CLIENTE,
                    RI.ID_VENDITORE_CLIENTE
                    FROM CD_IMPORTI_FATTURAZIONE IMPF,
                         CD_IMPORTI_PRODOTTO IMPP,
                         CD_PRODOTTO_ACQUISTATO PA,
                         CD_RAGGRUPPAMENTO_INTERMEDIARI RI,
                         CD_PIANIFICAZIONE PIA
                      WHERE ID_ORDINE = P_ID_ORDINE
                      AND IMPP.ID_IMPORTI_PRODOTTO = IMPF.ID_IMPORTI_PRODOTTO
                      AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
                      AND RI.ID_RAGGRUPPAMENTO = PA.ID_RAGGRUPPAMENTO
                      AND PIA.ID_PIANO = PA.ID_PIANO
                      AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO)LOOP
             v_perc_cli := FU_CD_GET_PERC_CLI(FAT.DGC_TC_ID,v_cond_pagamento,FAT.DATA_DECORRENZA,FAT.ID_CLIENTE,FAT.ID_VENDITORE_CLIENTE);
             UPDATE CD_IMPORTI_FATTURAZIONE
            SET PERC_VEND_CLI = v_perc_cli
             WHERE ID_IMPORTI_FATTURAZIONE = FAT.ID_IMPORTI_FATTURAZIONE;
         END LOOP;  */
END PR_MODIFICA_ORDINE;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ANNULLA_ORDINE
--
-- DESCRIZIONE:  Effettua l'annullamento o l'eliminazione di un ordine
--
-- OPERAZIONI:  
--             1) Verifica se l'ordine e gia stato stampato
--             2) Se la condizione precedente non si verifica si eliminano gli importi
--                in DAT, e si annullano quelli in DAR e TRA e i prodotti in DAR,TRA Passano in DAR.
--             4) Se l'ordine non ha piu importi collegati viene eliminato, altrimenti annullato logicamente
--
--  INPUT:
--  P_ID_ORDINE           Id dell'ordine
--
-- OUTPUT:
--   P_ESITO: 
--           1 eliminazione avvenuta correttamente
--           -3 impossibile eliminare perche l'ordine e stato stampato
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_ORDINE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE, P_ESITO OUT NUMBER) IS
v_num_importi_tra NUMBER := 0;
v_num_stampe NUMBER;
v_importi_rimasti NUMBER;
BEGIN
    P_ESITO := 1;
    -- 
    --SELECT COUNT(1)
    --INTO v_num_importi_tra
    --FROM CD_IMPORTI_FATTURAZIONE
    --WHERE ID_ORDINE = P_ID_ORDINE
    --AND FLG_ANNULLATO = 'N'
    --AND (STATO_FATTURAZIONE = 'TRA' OR STATO_FATTURAZIONE = 'DAR');
    --
    SELECT COUNT(1)
    INTO v_num_stampe
    FROM CD_STAMPE_ORDINE
    WHERE ID_ORDINE = P_ID_ORDINE;
    --
    IF v_num_importi_tra > 0 THEN
        P_ESITO := -2;
    --ELSIF v_num_stampe > 0 THEN
    --    P_ESITO := -3;
    ELSE
        IF v_num_stampe > 0 THEN
            UPDATE CD_IMPORTI_FATTURAZIONE
            SET FLG_ANNULLATO = 'S'
            WHERE ID_ORDINE = P_ID_ORDINE
            AND FLG_ANNULLATO = 'N'
            AND STATO_FATTURAZIONE = 'DAT';
            
            UPDATE CD_IMPORTI_FATTURAZIONE
            SET FLG_ANNULLATO = 'S',  STATO_FATTURAZIONE ='DAR'
            WHERE ID_ORDINE = P_ID_ORDINE
            AND FLG_ANNULLATO = 'N'
            AND STATO_FATTURAZIONE IN('DAR','TRA');
            
            --            
            UPDATE CD_ORDINE
            SET FLG_ANNULLATO = 'S'
            WHERE ID_ORDINE = P_ID_ORDINE;
            
        ELSE
            DELETE FROM CD_IMPORTI_FATTURAZIONE
            WHERE ID_ORDINE = P_ID_ORDINE
            AND STATO_FATTURAZIONE = 'DAT';
            --
            UPDATE CD_IMPORTI_FATTURAZIONE
            SET FLG_ANNULLATO = 'S',  STATO_FATTURAZIONE ='DAR'
            WHERE ID_ORDINE = P_ID_ORDINE
            AND FLG_ANNULLATO = 'N'
            AND STATO_FATTURAZIONE IN('DAR','TRA');
            --
            SELECT COUNT(1)
            INTO v_importi_rimasti
            FROM CD_IMPORTI_FATTURAZIONE
            WHERE ID_ORDINE = P_ID_ORDINE;
            --
            IF v_importi_rimasti > 0 THEN
                UPDATE CD_ORDINE
                SET FLG_ANNULLATO = 'S'
                WHERE ID_ORDINE = P_ID_ORDINE;
            ELSE
                DELETE FROM CD_ORDINE
                WHERE ID_ORDINE = P_ID_ORDINE;
            END IF;
        END IF;
    END IF;    
EXCEPTION
    WHEN OTHERS THEN
    P_ESITO := -1;
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_ANNULLA_ORDINE: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_ANNULLA_ORDINE;
END PR_ANNULLA_ORDINE;

PROCEDURE PR_SOSPENDI_ORDINE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE) IS
BEGIN
     UPDATE CD_ORDINE
     SET FLG_SOSPESO = 'S'
     WHERE ID_ORDINE = P_ID_ORDINE;
END PR_SOSPENDI_ORDINE;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE FU_GET_IMP_FATTURAZIONE
--
-- DESCRIZIONE:  Rirorna la lista di importi di fatturazione dell'ordine
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_ordine           Id dell'ordine
--
-- OUTPUT:
--   lista di importi di fatturazione
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_IMP_FATTURAZIONE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE,
                                 P_DATA_INIZIO CD_IMPORTI_FATTURAZIONE.DATA_INIZIO%TYPE,
                                 P_DATA_FINE CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE,
                                 P_TIPO_CONTRATTO CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO%TYPE,
                                 P_FLG_SOSPESO CD_IMPORTI_FATTURAZIONE.FLG_SOSPESO%TYPE) RETURN  C_IMP_FATTURAZIONE IS
CUR C_IMP_FATTURAZIONE;
v_id_piano CD_ORDINE.ID_PIANO%TYPE;
v_id_ver_piano CD_ORDINE.ID_VER_PIANO%TYPE;
v_data_inizio_ord CD_ORDINE.DATA_INIZIO%TYPE;
v_data_fine_ord CD_ORDINE.DATA_FINE%TYPE;
BEGIN

    SELECT ID_PIANO, ID_VER_PIANO, DATA_INIZIO, DATA_FINE
    INTO v_id_piano, v_id_ver_piano, v_data_inizio_ord, v_data_fine_ord
    FROM CD_ORDINE 
    WHERE ID_ORDINE = P_ID_ORDINE;
    --
    OPEN CUR for
    SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO as ID_PRODOTTO,
       IMP_FAT.DESC_PRODOTTO as DESC_PRODOTTO,
       IMP_FAT.ID_IMPORTI_FATTURAZIONE as ID_IMPORTO,
       IMP_FAT.IMPORTO_NETTO as IMP_NETTO,
       IMP_FAT.STATO_FATTURAZIONE as STATO,
       IMP_FAT.ID_SOGGETTO_DI_PIANO as ID_SOGG_PIANO,
       IMP_FAT.ID_ORDINE as ID_ORDINE,
       IMP_FAT.FLG_INCLUSO_IN_ORDINE as FLG_INCLUSO,
       IMP_FAT.FLG_SOSPESO as FLG_SOSPESO,
       IMP_FAT.DATA_INIZIO as DATA_INIZIO,
       IMP_FAT.DATA_FINE as DATA_FINE,
       SOGG.DESCRIZIONE as DESC_SOGG_PIANO,
       ORD.ID_PIANO || '/' || ORD.ID_VER_PIANO || '/' || ORD.COD_PRG_ORDINE AS COD_ORDINE,
       DECODE(IMP_PRO.TIPO_CONTRATTO,'C','Commerciale','Direzionale') AS TIPO_CONTRATTO,
       PR_ACQ.IMP_NETTO as NETTO_PRODOTTO,
       ROUND(PR_ACQ.IMP_NETTO / (PR_ACQ.DATA_FINE - PR_ACQ.DATA_INIZIO + 1) * (IMP_FAT.DATA_FINE - IMP_FAT.DATA_INIZIO + 1),2) AS NETTO_PARZIALE
    FROM CD_ORDINE ORD,
         CD_PIANIFICAZIONE PIA,
         CD_PRODOTTO_ACQUISTATO PR_ACQ,
         CD_IMPORTI_PRODOTTO IMP_PRO,
         CD_IMPORTI_FATTURAZIONE IMP_FAT,
         CD_SOGGETTO_DI_PIANO SOGG
    WHERE ORD.ID_ORDINE = P_ID_ORDINE
       AND ORD.ID_PIANO = PIA.ID_PIANO
       AND ORD.ID_VER_PIANO = PIA.ID_VER_PIANO
       AND PIA.ID_PIANO = PR_ACQ.ID_PIANO
       AND PIA.ID_VER_PIANO = PR_ACQ.ID_VER_PIANO
       AND PR_ACQ.FLG_ANNULLATO = 'N'
       AND PR_ACQ.FLG_SOSPESO = 'N'
       AND PR_ACQ.COD_DISATTIVAZIONE IS NULL
       AND PR_ACQ.ID_PRODOTTO_ACQUISTATO = IMP_PRO.ID_PRODOTTO_ACQUISTATO
       AND IMP_PRO.ID_IMPORTI_PRODOTTO = IMP_FAT.ID_IMPORTI_PRODOTTO
       AND IMP_PRO.TIPO_CONTRATTO = NVL(P_TIPO_CONTRATTO,IMP_PRO.TIPO_CONTRATTO)
       AND IMP_FAT.ID_ORDINE = P_ID_ORDINE
       AND IMP_FAT.FLG_ANNULLATO = 'N'
       AND IMP_FAT.ID_SOGGETTO_DI_PIANO = SOGG.ID_SOGGETTO_DI_PIANO
      -- AND IMP_FAT.IMPORTO_NETTO <> 0
       AND IMP_FAT.FLG_SOSPESO = NVL(P_FLG_SOSPESO,IMP_FAT.FLG_SOSPESO)
       AND (P_DATA_INIZIO IS NULL OR IMP_FAT.DATA_INIZIO >= P_DATA_INIZIO)
       AND (P_DATA_FINE IS NULL OR IMP_FAT.DATA_FINE <= P_DATA_FINE)
       AND (
              (PR_ACQ.IMP_NETTO = 0 AND IMP_PRO.TIPO_CONTRATTO = 'C') OR
              (IMP_FAT.IMPORTO_NETTO > 0) 
            )
    UNION
    SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO as ID_PRODOTTO,
       IMP_FAT.DESC_PRODOTTO as DESC_PRODOTTO,
       IMP_FAT.ID_IMPORTI_FATTURAZIONE as ID_IMPORTO,
       IMP_FAT.IMPORTO_NETTO as IMP_NETTO,
       IMP_FAT.STATO_FATTURAZIONE as STATO,
       IMP_FAT.ID_SOGGETTO_DI_PIANO as ID_SOGG_PIANO,
       IMP_FAT.ID_ORDINE as ID_ORDINE,
       IMP_FAT.FLG_INCLUSO_IN_ORDINE as FLG_INCLUSO,
       IMP_FAT.FLG_SOSPESO as FLG_SOSPESO,
       IMP_FAT.DATA_INIZIO as DATA_INIZIO,
       IMP_FAT.DATA_FINE as DATA_FINE,
       SOGG.DESCRIZIONE as DESC_SOGG_PIANO,
       ORD.ID_PIANO || '/' || ORD.ID_VER_PIANO || '/' || ORD.COD_PRG_ORDINE AS COD_ORDINE,
       DECODE(IMP_PRO.TIPO_CONTRATTO,'C','Commerciale','Direzionale') AS TIPO_CONTRATTO,
       PR_ACQ.IMP_NETTO as NETTO_PRODOTTO,
       ROUND(PR_ACQ.IMP_NETTO / (PR_ACQ.DATA_FINE - PR_ACQ.DATA_INIZIO + 1) * (IMP_FAT.DATA_FINE - IMP_FAT.DATA_INIZIO + 1),2) AS NETTO_PARZIALE
       FROM CD_ORDINE ORD,
         CD_PIANIFICAZIONE PIA,
         CD_PRODOTTO_ACQUISTATO PR_ACQ,
         CD_IMPORTI_PRODOTTO IMP_PRO,
         CD_IMPORTI_FATTURAZIONE IMP_FAT,
         CD_SOGGETTO_DI_PIANO SOGG 
       WHERE ORD.ID_PIANO = v_id_piano
       AND ORD.ID_VER_PIANO = v_id_ver_piano
       AND ORD.ID_ORDINE != P_ID_ORDINE
       AND ORD.FLG_ANNULLATO = 'N'
       AND PIA.ID_PIANO = PR_ACQ.ID_PIANO
       AND PIA.ID_VER_PIANO = PR_ACQ.ID_VER_PIANO
       AND PR_ACQ.FLG_ANNULLATO = 'N'
       AND PR_ACQ.FLG_SOSPESO = 'N'
       AND PR_ACQ.COD_DISATTIVAZIONE IS NULL
       AND PR_ACQ.ID_PRODOTTO_ACQUISTATO = IMP_PRO.ID_PRODOTTO_ACQUISTATO
       AND IMP_PRO.ID_IMPORTI_PRODOTTO = IMP_FAT.ID_IMPORTI_PRODOTTO
       AND IMP_PRO.TIPO_CONTRATTO = NVL(P_TIPO_CONTRATTO,IMP_PRO.TIPO_CONTRATTO)
       AND IMP_FAT.ID_ORDINE = ORD.ID_ORDINE
       AND IMP_FAT.ID_SOGGETTO_DI_PIANO = SOGG.ID_SOGGETTO_DI_PIANO
       AND IMP_FAT.FLG_INCLUSO_IN_ORDINE = 'N'
       AND IMP_FAT.FLG_ANNULLATO = 'N'
       AND IMP_FAT.FLG_SOSPESO = NVL(P_FLG_SOSPESO,IMP_FAT.FLG_SOSPESO)
       AND IMP_FAT.DATA_INIZIO >= v_data_inizio_ord
       AND IMP_FAT.DATA_FINE <= v_data_fine_ord
       AND (P_DATA_INIZIO IS NULL OR IMP_FAT.DATA_INIZIO >= P_DATA_INIZIO)
       AND (P_DATA_FINE IS NULL OR IMP_FAT.DATA_FINE <= P_DATA_FINE)
       AND (
              (PR_ACQ.IMP_NETTO = 0 AND IMP_PRO.TIPO_CONTRATTO = 'C') OR
              (IMP_FAT.IMPORTO_NETTO > 0) 
            )
    ORDER BY DATA_INIZIO, ID_PRODOTTO;
--
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END FU_GET_IMP_FATTURAZIONE;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_SOSPENDI_IMP_FATT
--
-- DESCRIZIONE:  Update del FLG_SOSPESO di un importo di fatturazione di un ordine
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_importi_fatturazione           Id del prodotto acquistato
--  p_flg_sospeso                      Id del fruitore
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_SOSPENDI_IMP_FATT(p_id_importi_fatturazione CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_FATTURAZIONE%TYPE,
                                 p_flg_sospeso CD_IMPORTI_FATTURAZIONE.FLG_SOSPESO%TYPE,
                                 p_esito OUT NUMBER)
IS

BEGIN
        p_esito     := 1;
        SAVEPOINT pa_cd_sospeso_fatt;

        -- effettuo l'UPDATE
        UPDATE CD_IMPORTI_FATTURAZIONE SET FLG_SOSPESO = p_flg_sospeso
        WHERE ID_IMPORTI_FATTURAZIONE = p_id_importi_fatturazione;


EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_SOSPENDI_IMP_FATT: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI ');
        ROLLBACK TO pa_cd_prodotto_fruitori;

END PR_SOSPENDI_IMP_FATT;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_UPDATE_IDORDINE_FATT
--
-- DESCRIZIONE:  Update di ID_ORDINE di un importo di fatturazione di un ordine
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_importi_fatturazione           Id del prodotto acquistato
--  p_id_ordine                         Id dell'ordine
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INCLUDI_IMP_FATT(p_id_ordine CD_IMPORTI_FATTURAZIONE.ID_ORDINE%TYPE,
                              p_id_importi_fatturazione CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_FATTURAZIONE%TYPE,
                              p_flg_incluso CD_IMPORTI_FATTURAZIONE.FLG_INCLUSO_IN_ORDINE%TYPE,
                              p_esito OUT NUMBER)
IS
v_id_ordine_importo CD_IMPORTI_FATTURAZIONE.ID_ORDINE%TYPE;
v_data_inizio_imp CD_IMPORTI_FATTURAZIONE.DATA_INIZIO%TYPE;
v_data_fine_imp CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE;
v_soggetto CD_IMPORTI_FATTURAZIONE.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_prodotto_acquistato CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE;
BEGIN
        p_esito     := 1;
        SAVEPOINT pa_cd_sospeso_fatt;
        --
        SELECT IMPF.ID_ORDINE, IMPF.DATA_INIZIO, IMPF.DATA_FINE, IMPF.ID_SOGGETTO_DI_PIANO, IMPP.ID_PRODOTTO_ACQUISTATO
        INTO v_id_ordine_importo, v_data_inizio_imp, v_data_fine_imp, v_soggetto, v_id_prodotto_acquistato
        FROM CD_IMPORTI_FATTURAZIONE IMPF, CD_IMPORTI_PRODOTTO IMPP
        WHERE IMPF.ID_IMPORTI_FATTURAZIONE = p_id_importi_fatturazione
        AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO;
        -- effettuo l'UPDATE
        UPDATE CD_IMPORTI_FATTURAZIONE 
        SET FLG_INCLUSO_IN_ORDINE = p_flg_incluso
        WHERE ID_IMPORTI_FATTURAZIONE = p_id_importi_fatturazione;
        --
        IF v_id_ordine_importo != p_id_ordine AND p_flg_incluso = 'S' THEN
            UPDATE CD_IMPORTI_FATTURAZIONE
            SET ID_ORDINE = p_id_ordine
            WHERE ID_IMPORTI_FATTURAZIONE = p_id_importi_fatturazione;
            
            UPDATE CD_IMPORTI_FATTURAZIONE
            SET ID_ORDINE = p_id_ordine
            WHERE ID_ORDINE = v_id_ordine_importo
            AND ID_IMPORTI_FATTURAZIONE != p_id_importi_fatturazione
            AND FLG_ANNULLATO = 'N'
            AND ID_IMPORTI_PRODOTTO IN
            (SELECT ID_IMPORTI_PRODOTTO
             FROM CD_IMPORTI_PRODOTTO
             WHERE ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato)
            AND DATA_INIZIO = v_data_inizio_imp
            AND DATA_FINE = v_data_fine_imp
            AND ID_SOGGETTO_DI_PIANO = v_soggetto
            AND IMPORTO_NETTO = 0;
        END IF;

EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_INCLUDI_IMP_FATT: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI '||SQLERRM);
        ROLLBACK TO pa_cd_prodotto_fruitori;

END PR_INCLUDI_IMP_FATT;


FUNCTION FU_CD_GET_PERC_CLI(P_DGC_TC_ID CD_IMPORTI_PRODOTTO.DGC_TC_ID%TYPE,P_ID_COND_PAGAMENTO CD_ORDINE.ID_COND_PAGAMENTO%TYPE,P_ID_RAGGRUPPAMENTO CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE) RETURN NUMBER IS
/******************************************************************************
   NAME:       FU_GET_PERC_CLI
   PURPOSE:    Determina la percentuale del cliente

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        08/01/2010   Mauro Viel   Altran Italia     1. Created this function.

******************************************************************************/
v_aliq_venditore_cliente    number:=0;
v_aliq_venditore_agenzia    number;
v_aliq_venditore_c_media    number;
v_aliq_specialista_prodotto number;
v_aliq_coproduttore         number;
v_tipo_cond_pag				varchar2(1);
v_sqlcode_portafoglio       number;
v_sqlerrm_portafoglio       varchar2(700);
v_esito number :=-1;
V_RAGGRUPPAMENTO_INTERMEDIARI CD_RAGGRUPPAMENTO_INTERMEDIARI%ROWTYPE;
V_ID_CLIENTE CD_PIANIFICAZIONE.ID_CLIENTE%TYPE;
BEGIN

    SELECT RAG.* INTO V_RAGGRUPPAMENTO_INTERMEDIARI FROM
    CD_RAGGRUPPAMENTO_INTERMEDIARI RAG
    WHERE RAG.ID_RAGGRUPPAMENTO = P_ID_RAGGRUPPAMENTO;
    --
    select decode(nat_CPAG, 'C', nat_CPAG, null)
    into v_tipo_cond_pag
    from cond_pagamento
    where cod_cpag=P_ID_COND_PAGAMENTO;
    --
    SELECT ID_CLIENTE
        INTO   V_ID_CLIENTE
        FROM   CD_PIANIFICAZIONE
        WHERE  ID_PIANO     = V_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO
        AND    ID_VER_PIANO = V_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO;
    --    
    v_esito :=pa_pc_portafoglio.fu_get_aliquote(
                               'RAISE',--
                               P_DGC_TC_ID,--'001',
                               v_tipo_cond_pag,--null
                               V_RAGGRUPPAMENTO_INTERMEDIARI.DATA_DECORRENZA,--sysdate
                               V_ID_CLIENTE,--CC000149
                               --V_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA,-- p_agenzia
                               null,
                               null,--p_centro_media
                               V_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE,--AG000745
                               null,--p_venditore_agenzia
                               null,--p_venditore_c_media
                               null,--p_specialista_prodotto
                               null,--  p_coproduttore
                                  v_aliq_venditore_cliente        ,
                                  v_aliq_venditore_agenzia        ,
                                  v_aliq_venditore_c_media        ,
                                  v_aliq_specialista_prodotto    ,
                                  v_aliq_coproduttore            ,
                               v_sqlcode_portafoglio        ,
                               v_sqlerrm_portafoglio         );

return nvl(v_aliq_venditore_cliente,0);
EXCEPTION
  WHEN OTHERS THEN
   v_aliq_venditore_cliente := -1;
   v_esito :=-100;
   raise;
END FU_CD_GET_PERC_CLI;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_DESC_FRUITORE
--
-- DESCRIZIONE:  Restituisce la descrizione di un cliente fruitore
--
-- OPERAZIONI:
--
--  INPUT:
--  P_ID_FRUITORE           Id del fruitore                    
--
-- OUTPUT: Stringa contenente la descrizione del cliente
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_DESC_FRUITORE(P_ID_FRUITORE CD_FRUITORI_DI_PIANO.ID_FRUITORI_DI_PIANO%TYPE) RETURN interl_u.RAG_SOC_COGN%TYPE IS
v_desc_fruitore vi_cd_cliente_fruitore.RAG_SOC_COGN%TYPE;
BEGIN
    IF P_ID_FRUITORE IS NOT NULL THEN
        SELECT VCF.RAG_SOC_COGN
        INTO v_desc_fruitore
        FROM CD_FRUITORI_DI_PIANO FP,
             VI_CD_CLIENTE_FRUITORE VCF
        WHERE FP.ID_FRUITORI_DI_PIANO = P_ID_FRUITORE
        AND VCF.ID_FRUITORE = FP.ID_CLIENTE_FRUITORE;
    END IF;
    RETURN v_desc_fruitore;
END FU_GET_DESC_FRUITORE;


-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_CD_GET_PERC_SSDA
--
-- DESCRIZIONE:  Restituisce l'aliquota dell'agenzia
--
-- OPERAZIONI:
--
--  INPUT: 
--  P_ID_RAGGRUPPAMENTO     Id del ragruppamento intermediari
--  P_ID_COND_PAGAMENTO     Condizione di pagamento                    
--
-- OUTPUT: Valore dell'aliquota
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CD_GET_PERC_SSDA(P_ID_RAGGRUPPAMENTO CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE, P_ID_COND_PAGAMENTO CD_ORDINE.ID_COND_PAGAMENTO%TYPE ) RETURN NUMBER IS
V_PERC_SCONTO_SOST_AGE CD_IMPORTI_FATTURAZIONE.PERC_SCONTO_SOST_AGE%TYPE:= 0;
V_ID_AGENZIA      CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE;
V_ID_CENTRO_MEDIA CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE;
BEGIN

  SELECT ID_AGENZIA,ID_CENTRO_MEDIA
  INTO V_ID_AGENZIA,V_ID_CENTRO_MEDIA
  FROM CD_RAGGRUPPAMENTO_INTERMEDIARI
  WHERE ID_RAGGRUPPAMENTO = P_ID_RAGGRUPPAMENTO;

  IF V_ID_AGENZIA  IS NULL AND   V_ID_CENTRO_MEDIA  IS NULL THEN
      RETURN V_PERC_SCONTO_SOST_AGE;
  ELSE
      SELECT MAX_DIR
      INTO   V_PERC_SCONTO_SOST_AGE
      FROM   COND_PAGAMENTO
      WHERE  COD_CPAG = P_ID_COND_PAGAMENTO;
      RETURN V_PERC_SCONTO_SOST_AGE;
  END IF;
   EXCEPTION
     WHEN OTHERS THEN
       RAISE;
END FU_CD_GET_PERC_SSDA;

FUNCTION FU_GET_FRUITORI RETURN C_CLIENTE_FRUITORE IS
v_clienti C_CLIENTE_FRUITORE;
BEGIN
OPEN v_clienti FOR
    SELECT ID_FRUITORE,
           RAG_SOC_COGN,
           NULL,
           NULL,
           NULL,
           NULL
    FROM VI_CD_CLIENTE_FRUITORE
    ORDER BY RAG_SOC_COGN;
RETURN  v_clienti;
END FU_GET_FRUITORI;

PROCEDURE PR_MODIFICA_ALIQUOTE(P_ID_RAGGRUPPAMENTO CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE, P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) IS
/******************************************************************************
   NAME:       PR_MODIFICA_ALIQUOTE
   PURPOSE:    Modifica le aliquote dell'agenzia e del venditore cliente per un prodotto acquistato

   REVISIONS:
   Ver        Date          Author                         Description
   ---------  ----------    ---------------                ------------------------------------
   1.0        Gennaio 2010  Simone Bottani Altran        1. Created this function.


******************************************************************************/

v_perc_ssda CD_IMPORTI_FATTURAZIONE.PERC_SCONTO_SOST_AGE%TYPE;
V_ID_COND_PAGAMENTO CD_ORDINE.ID_COND_PAGAMENTO%TYPE;
v_perc_vend_cli CD_IMPORTI_FATTURAZIONE.PERC_VEND_CLI%TYPE;
BEGIN
    FOR IMPF IN (SELECT FAT.ID_IMPORTI_FATTURAZIONE, ORD.ID_COND_PAGAMENTO, IMP.DGC_TC_ID
                 FROM CD_IMPORTI_FATTURAZIONE FAT, CD_IMPORTI_PRODOTTO IMP, CD_ORDINE ORD
                 WHERE IMP.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                 AND FAT.ID_IMPORTI_PRODOTTO = IMP.ID_IMPORTI_PRODOTTO
                 AND FAT.FLG_ANNULLATO = 'N'
                 AND ORD.ID_ORDINE = FAT.ID_ORDINE
                 AND ORD.FLG_ANNULLATO = 'N'
                 AND ORD.FLG_SOSPESO = 'N') LOOP
    
        v_perc_ssda      :=  FU_CD_GET_PERC_SSDA(P_ID_RAGGRUPPAMENTO,IMPF.ID_COND_PAGAMENTO);
        v_perc_vend_cli  :=  FU_CD_GET_PERC_CLI(IMPF.DGC_TC_ID,IMPF.ID_COND_PAGAMENTO,P_ID_RAGGRUPPAMENTO);
        --
        UPDATE CD_IMPORTI_FATTURAZIONE
        SET PERC_SCONTO_SOST_AGE = v_perc_ssda,
            PERC_VEND_CLI = v_perc_vend_cli
        WHERE ID_IMPORTI_FATTURAZIONE = IMPF.ID_IMPORTI_FATTURAZIONE;
        --
        UPDATE CD_IMPORTI_FATTURAZIONE
        SET STATO_FATTURAZIONE = 'DAR'
        WHERE ID_IMPORTI_FATTURAZIONE = IMPF.ID_IMPORTI_FATTURAZIONE
        AND STATO_FATTURAZIONE = 'TRA';
    END LOOP;
END PR_MODIFICA_ALIQUOTE;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_MODIFICA_FRUITORE
--
-- DESCRIZIONE:  Modifica di un fruitore di un prodotto acquistato
--
-- OPERAZIONI:   Per tutti gli ordini che fanno riferimento al fruitore e al prodotto acquistato
--               vengono eliminati gli ordini relativi                
--
--  INPUT: 
--  P_ID_FRUITORE                Id del cliente fruitore
--  P_ID_PRODOTTO_ACQUISTATO     Id del prodotto acquistato                   
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_FRUITORE(P_ID_FRUITORE CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE, P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,P_ESITO OUT NUMBER) IS
BEGIN

    FOR ORDINI IN ( SELECT ID_ORDINE
                    FROM CD_IMPORTI_FATTURAZIONE
                    WHERE ID_IMPORTI_PRODOTTO IN
                    (
                        SELECT ID_IMPORTI_PRODOTTO FROM CD_IMPORTI_PRODOTTO
                        WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                    )
                    AND ID_ORDINE IN
                    (SELECT ID_ORDINE FROM CD_ORDINE
                     WHERE ID_FRUITORI_DI_PIANO = P_ID_FRUITORE
                     AND FLG_ANNULLATO = 'N')) LOOP
    
        PR_ANNULLA_ORDINE(ORDINI.ID_ORDINE,P_ESITO);
    END LOOP;                 
END PR_MODIFICA_FRUITORE;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ANNULLA_ORDINE_PRD_ACQ
--
-- DESCRIZIONE:  Elimina tutti gli ordini di un prodotto acquistato
--
-- OPERAZIONI:            
--
--  INPUT: 
--  P_ID_PRODOTTO_ACQUISTATO     Id del prodotto acquistato                   
--
-- OUTPUT: P_ESITO
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------

PROCEDURE PR_ANNULLA_ORDINE_PRD_ACQ(P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) IS
v_num_importi_tra NUMBER;
v_num_stampe NUMBER;
v_importi_rimasti NUMBER;
BEGIN
     FOR ORD IN (SELECT DISTINCT IMPF.ID_ORDINE
                 FROM CD_ORDINE O, CD_IMPORTI_FATTURAZIONE IMPF, 
                 CD_IMPORTI_PRODOTTO IMPP
                 WHERE IMPP.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                 AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                 AND IMPF.FLG_ANNULLATO = 'N'
                 AND O.ID_ORDINE = IMPF.ID_ORDINE
                 AND O.FLG_ANNULLATO = 'N'
                 )LOOP
        --         
        --PR_ANNULLA_ORDINE(ORD.ID_ORDINE,P_ESITO);
            SELECT COUNT(1)
            INTO v_num_stampe
            FROM CD_STAMPE_ORDINE
            WHERE ID_ORDINE = ORD.ID_ORDINE;
            --
            IF v_num_stampe > 0 THEN
                UPDATE CD_IMPORTI_FATTURAZIONE
                SET FLG_ANNULLATO = 'S'
                WHERE ID_ORDINE = ORD.ID_ORDINE
                AND FLG_ANNULLATO = 'N'
                AND ID_IMPORTI_PRODOTTO IN
                (
                    SELECT ID_IMPORTI_PRODOTTO
                    FROM CD_IMPORTI_PRODOTTO
                    WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                );
                SELECT COUNT(1)
                INTO v_importi_rimasti
                FROM CD_IMPORTI_FATTURAZIONE
                WHERE ID_ORDINE = ORD.ID_ORDINE
                AND FLG_ANNULLATO = 'N';
                IF v_importi_rimasti = 0 THEN
                    UPDATE CD_ORDINE
                    SET FLG_ANNULLATO = 'S'
                    WHERE ID_ORDINE = ORD.ID_ORDINE;
                END IF;
            ELSE
                DELETE FROM CD_IMPORTI_FATTURAZIONE
                WHERE ID_ORDINE = ORD.ID_ORDINE
                AND STATO_FATTURAZIONE = 'DAT'
                AND ID_IMPORTI_PRODOTTO IN
                (
                    SELECT ID_IMPORTI_PRODOTTO
                    FROM CD_IMPORTI_PRODOTTO
                    WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                );
                --
                UPDATE CD_IMPORTI_FATTURAZIONE
                SET FLG_ANNULLATO = 'S'
                WHERE ID_ORDINE = ORD.ID_ORDINE
                AND FLG_ANNULLATO = 'N'
                AND STATO_FATTURAZIONE IN ('DAR','TRA')
                AND ID_IMPORTI_PRODOTTO IN
                (
                    SELECT ID_IMPORTI_PRODOTTO
                    FROM CD_IMPORTI_PRODOTTO
                    WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                );
                SELECT COUNT(1)
                INTO v_importi_rimasti
                FROM CD_IMPORTI_FATTURAZIONE
                WHERE ID_ORDINE = ORD.ID_ORDINE;
                IF v_importi_rimasti = 0 THEN
                    DELETE FROM CD_ORDINE
                    WHERE ID_ORDINE = ORD.ID_ORDINE;
                END IF;
                SELECT COUNT(1)
                INTO v_importi_rimasti
                FROM CD_IMPORTI_FATTURAZIONE
                WHERE ID_ORDINE = ORD.ID_ORDINE
                AND FLG_ANNULLATO = 'N';
                IF v_importi_rimasti = 0 THEN
                    UPDATE CD_ORDINE
                    SET FLG_ANNULLATO = 'S'
                    WHERE ID_ORDINE = ORD.ID_ORDINE;
                END IF;
        END IF;
     END LOOP;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_ANNULLA_ORDINE_PRD_ACQ: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_ANNULLA_ORDINE;
END PR_ANNULLA_ORDINE_PRD_ACQ;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_MODIFICA_SOGGETTO_ORDINE
--
-- DESCRIZIONE:  Effettua il ricalcolo degli importi fatturazione di un ordine
--               se sono stati modificati i soggetti di un prodotto acquistato
--
-- OPERAZIONI:            
--
--  INPUT: 
--  P_ID_PRODOTTO_ACQUISTATO     Id del prodotto acquistato                   
--
-- OUTPUT: P_ESITO
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_SOGGETTO_ORDINE(P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, P_ESITO OUT NUMBER) IS
v_soggetti_fatturati id_list_type := id_list_type();
v_soggetti_prodotto id_list_type := id_list_type();
v_index NUMBER := 1;
v_uguali NUMBER := 1;
v_netto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_giorno CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_soggetto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_parziale CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE := 0;
v_num_importi NUMBER;
v_giorni_prodotto NUMBER;
v_perc_ssda CD_IMPORTI_FATTURAZIONE.PERC_SCONTO_SOST_AGE%TYPE;
v_id_cond_pagamento CD_ORDINE.ID_COND_PAGAMENTO%TYPE;
v_perc_vend_cli CD_IMPORTI_FATTURAZIONE.PERC_VEND_CLI%TYPE;
v_trovato BOOLEAN := FALSE;
v_desc_prodotto CD_IMPORTI_FATTURAZIONE.DESC_PRODOTTO%TYPE;
v_id_importi_prodotto CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_id_importi_prodotto_com cd_importi_fatturazione.id_importi_prodotto%TYPE;
v_vecchio_importo_com CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
v_id_importi_prodotto_dir cd_importi_fatturazione.id_importi_prodotto%TYPE;
v_vecchio_importo_dir CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
BEGIN
    SAVEPOINT PR_MODIFICA_SOGGETTO_ORDINE;
    --
    FOR SOGG_FATT IN (SELECT DISTINCT IMPF.ID_SOGGETTO_DI_PIANO FROM CD_IMPORTI_FATTURAZIONE IMPF, CD_IMPORTI_PRODOTTO IMPP
    WHERE IMPP.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
    AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
    AND IMPF.FLG_ANNULLATO = 'N'
    ORDER BY IMPF.ID_SOGGETTO_DI_PIANO) LOOP
        v_soggetti_fatturati.EXTEND;
        v_soggetti_fatturati(v_index) := SOGG_FATT.ID_SOGGETTO_DI_PIANO;
        v_index := v_index +1;
        --dbms_output.put_line('Soggetto fatturazione: '||SOGG_FATT.ID_SOGGETTO_DI_PIANO);
    END LOOP;
    
    IF v_soggetti_fatturati.COUNT > 0 THEN
    --
    v_index := 1;
        --
        FOR SOGG_PROD IN (SELECT DISTINCT C.ID_SOGGETTO_DI_PIANO FROM CD_COMUNICATO C, CD_PRODOTTO_ACQUISTATO PA
        WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
        AND C.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
        AND C.FLG_ANNULLATO = 'N'
        AND C.FLG_SOSPESO = 'N'
        AND C.COD_DISATTIVAZIONE IS NULL
        ORDER BY C.ID_SOGGETTO_DI_PIANO) LOOP
            v_soggetti_prodotto.EXTEND;
            v_soggetti_prodotto(v_index) := SOGG_PROD.ID_SOGGETTO_DI_PIANO;
            v_index := v_index +1;
            --dbms_output.put_line('Soggetto prodotto: '||SOGG_PROD.ID_SOGGETTO_DI_PIANO);
        END LOOP;
        --
        IF v_soggetti_fatturati.COUNT = v_soggetti_prodotto.COUNT THEN
            FOR i IN 1..v_soggetti_fatturati.COUNT LOOP
                IF v_soggetti_fatturati(i) != v_soggetti_prodotto(i) THEN
                    v_uguali := 0;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            v_uguali := 0;
        END IF;
        --
        --dbms_output.PUT_LINE('v_soggetti_fatturati.COUNT: '||v_soggetti_fatturati.COUNT);
        --dbms_output.PUT_LINE('v_soggetti_prodotto.COUNT: '||v_soggetti_prodotto.COUNT);
        --dbms_output.put_line('Soggetti uguali: '||v_uguali);
        IF v_uguali = 0 THEN
            SELECT DATA_FINE - DATA_INIZIO +1
            INTO v_giorni_prodotto
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO;
            
            SELECT IP.ID_IMPORTI_PRODOTTO,SUM(IMPORTO_NETTO)
            INTO v_id_importi_prodotto_com, v_vecchio_importo_com
            FROM CD_IMPORTI_FATTURAZIONE FAT,  CD_IMPORTI_PRODOTTO IP
            where FAT.id_importi_prodotto = IP.id_importi_prodotto
            AND FAT.FLG_ANNULLATO = 'N'
            and ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
            AND TIPO_CONTRATTO = 'C'
            GROUP BY IP.ID_IMPORTI_PRODOTTO;
            
            SELECT IP.ID_IMPORTI_PRODOTTO,SUM(IMPORTO_NETTO)
            INTO v_id_importi_prodotto_dir, v_vecchio_importo_dir
            FROM CD_IMPORTI_FATTURAZIONE FAT,  CD_IMPORTI_PRODOTTO IP
            where FAT.id_importi_prodotto = IP.id_importi_prodotto
            AND FAT.FLG_ANNULLATO = 'N'
            and ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
            AND TIPO_CONTRATTO = 'D'
            GROUP BY IP.ID_IMPORTI_PRODOTTO;
            
            FOR i IN 1..v_soggetti_prodotto.COUNT LOOP
                --dbms_output.put_line('Soggetto prodotto: '||v_soggetti_prodotto(i));
                SELECT COUNT(1)
                INTO v_num_importi
                FROM CD_IMPORTI_FATTURAZIONE IMPF, CD_IMPORTI_PRODOTTO IMPP
                WHERE IMPP.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                AND IMPF.FLG_ANNULLATO = 'N'
                AND IMPF.ID_SOGGETTO_DI_PIANO = v_soggetti_prodotto(i);
                --dbms_output.put_line('Num importi:'||v_num_importi);
                IF v_num_importi > 0 THEN
                    FOR IMP_PROD IN (SELECT IMPF.ID_IMPORTI_FATTURAZIONE, IMPP.IMP_NETTO, IMPF.DATA_INIZIO, IMPF.DATA_FINE
                                     FROM CD_IMPORTI_FATTURAZIONE IMPF, CD_IMPORTI_PRODOTTO IMPP
                                     WHERE IMPP.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                                     AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                                     AND IMPF.FLG_ANNULLATO = 'N'
                                     AND IMPF.ID_SOGGETTO_DI_PIANO = v_soggetti_prodotto(i))LOOP
                        --
                        
                        --IF i < v_soggetti_prodotto.COUNT THEN
                            v_netto_giorno := IMP_PROD.IMP_NETTO / v_soggetti_prodotto.COUNT / v_giorni_prodotto;
                            v_netto_soggetto := ROUND(v_netto_giorno * (IMP_PROD.DATA_FINE - IMP_PROD.DATA_INIZIO +1),2);
                        --dbms_output.put_line('v_netto_giorno:'||v_netto_giorno);
                        --dbms_output.put_line('giorni prodotto:'||IMP_PROD.DATA_FINE - IMP_PROD.DATA_INIZIO +1);
                        --dbms_output.put_line('v_netto_soggetto:'||v_netto_soggetto);
                        --ELSE
                        --    v_netto_soggetto := IMP_PROD.IMP_NETTO - v_netto_parziale;
                        --END IF;
                        --
                        --dbms_output.put_line('IMP_PROD.ID_IMPORTI_FATTURAZIONE:'||IMP_PROD.ID_IMPORTI_FATTURAZIONE);
                        UPDATE CD_IMPORTI_FATTURAZIONE
                        SET IMPORTO_NETTO = v_netto_soggetto
                        WHERE ID_SOGGETTO_DI_PIANO = v_soggetti_prodotto(i)
                        AND FLG_ANNULLATO = 'N'
                        AND ID_IMPORTI_FATTURAZIONE = IMP_PROD.ID_IMPORTI_FATTURAZIONE;
                        -- 
                         UPDATE CD_IMPORTI_FATTURAZIONE
                         SET STATO_FATTURAZIONE = 'DAR'
                         WHERE ID_SOGGETTO_DI_PIANO = v_soggetti_prodotto(i)
                         AND STATO_FATTURAZIONE = 'TRA'
                         AND ID_IMPORTI_FATTURAZIONE = IMP_PROD.ID_IMPORTI_FATTURAZIONE;
                        -- 
                         v_netto_parziale := v_netto_parziale + v_netto_soggetto;
                    END LOOP;
                
                ELSE
                    
                     FOR ORD IN(SELECT DISTINCT IMPF.ID_IMPORTI_PRODOTTO, IMPP.IMP_NETTO, IMPF.ID_ORDINE, O.ID_COND_PAGAMENTO, IMPP.DGC_TC_ID, IMPF.DATA_INIZIO, IMPF.DATA_FINE, PA.ID_RAGGRUPPAMENTO
                                FROM CD_ORDINE O, CD_IMPORTI_FATTURAZIONE IMPF, CD_IMPORTI_PRODOTTO IMPP, CD_PRODOTTO_ACQUISTATO PA
                                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
                                AND IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                                AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                                AND IMPF.FLG_ANNULLATO = 'N'
                                AND O.ID_ORDINE = IMPF.ID_ORDINE
                                AND O.FLG_ANNULLATO = 'N'
                                AND O.FLG_SOSPESO = 'N')LOOP
                         --
                         --dbms_output.PUT_LINE('ORD.IMP_NETTO: '||ORD.IMP_NETTO);
                         --IF i < v_soggetti_prodotto.COUNT THEN
                            v_netto_giorno := ORD.IMP_NETTO / v_soggetti_prodotto.COUNT / v_giorni_prodotto;
                            --dbms_output.PUT_LINE('v_netto_giorno: '||v_netto_giorno);
                            v_netto_soggetto := ROUND(v_netto_giorno * (ORD.DATA_FINE - ORD.DATA_INIZIO +1),2);
                         --ELSE
                         --   v_netto_soggetto := ORD.IMP_NETTO - v_netto_parziale;
                         --END IF;
                         --dbms_output.PUT_LINE('v_netto_soggetto: '||v_netto_soggetto);
                         v_perc_ssda      :=  FU_CD_GET_PERC_SSDA(ORD.ID_RAGGRUPPAMENTO,ORD.ID_COND_PAGAMENTO);
                         v_perc_vend_cli  :=  FU_CD_GET_PERC_CLI(ORD.DGC_TC_ID,ORD.ID_COND_PAGAMENTO,ORD.ID_RAGGRUPPAMENTO);
                         v_desc_prodotto := FU_GET_DESC_PRODOTTO(ORD.ID_IMPORTI_PRODOTTO);
                         INSERT INTO CD_IMPORTI_FATTURAZIONE(ID_ORDINE,ID_IMPORTI_PRODOTTO,DATA_INIZIO,DATA_FINE, IMPORTO_NETTO, ID_SOGGETTO_DI_PIANO, PERC_SCONTO_SOST_AGE, PERC_VEND_CLI, DESC_PRODOTTO)
                         VALUES(ORD.ID_ORDINE, ORD.ID_IMPORTI_PRODOTTO, ORD.DATA_INIZIO, ORD.DATA_FINE,v_netto_soggetto, v_soggetti_prodotto(i),v_perc_ssda,v_perc_vend_cli, v_desc_prodotto);
                         v_netto_parziale := v_netto_parziale + v_netto_soggetto;
                     END LOOP;
                END IF;
                --dbms_output.PUT_LINE('v_netto_parziale: '||v_netto_parziale);
            END LOOP;
           --
           --dbms_output.PUT_LINE('Controllo se ho cancellato dei soggetti');
           FOR i IN 1..v_soggetti_fatturati.COUNT LOOP
               v_trovato := FALSE;
               
               FOR j IN 1..v_soggetti_prodotto.COUNT LOOP
                    IF v_soggetti_fatturati(i) = v_soggetti_prodotto(j) THEN
                        --dbms_output.PUT_LINE('Soggetto prodotto: '||v_soggetti_prodotto(j));
                        v_trovato := TRUE;
                        EXIT;
                    END IF;
               END LOOP;
               IF v_trovato = FALSE THEN
                    --dbms_output.PUT_LINE('Eliminato il soggetto: '||v_soggetti_fatturati(i));
                     --dbms_output.PUT_LINE('Id prodotto acquistato: '||P_ID_PRODOTTO_ACQUISTATO);
                    UPDATE CD_IMPORTI_FATTURAZIONE 
                    SET IMPORTO_NETTO = 0
                    WHERE ID_SOGGETTO_DI_PIANO = v_soggetti_fatturati(i)
                    AND FLG_ANNULLATO = 'N'
                    AND ID_IMPORTI_PRODOTTO IN
                    (SELECT ID_IMPORTI_PRODOTTO FROM CD_IMPORTI_PRODOTTO
                     WHERE ID_PRODOTTO_ACQUISTATO IN
                        (SELECT ID_PRODOTTO_ACQUISTATO FROM CD_PRODOTTO_ACQUISTATO
                        WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO));
                    --
                    UPDATE CD_IMPORTI_FATTURAZIONE 
                    SET STATO_FATTURAZIONE = 'DAR'
                    WHERE ID_SOGGETTO_DI_PIANO = v_soggetti_fatturati(i)
                    AND FLG_ANNULLATO = 'N'
                    AND STATO_FATTURAZIONE = 'TRA'
                    AND ID_IMPORTI_PRODOTTO IN
                    (SELECT ID_IMPORTI_PRODOTTO FROM CD_IMPORTI_PRODOTTO
                     WHERE ID_PRODOTTO_ACQUISTATO IN
                        (SELECT ID_PRODOTTO_ACQUISTATO FROM CD_PRODOTTO_ACQUISTATO
                           WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO));
               END IF;
           END LOOP;
        
        --Controllo correttezza dati

        PR_VERIFICA_IMPORTI(v_id_importi_prodotto_com, v_vecchio_importo_com);
        PR_VERIFICA_IMPORTI(v_id_importi_prodotto_dir, v_vecchio_importo_dir);
        END IF;
    END IF;        
EXCEPTION
    WHEN OTHERS THEN
    P_ESITO := -1;
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_MODIFICA_SOGGETTO_ORDINE: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_MODIFICA_SOGGETTO_ORDINE;
END PR_MODIFICA_SOGGETTO_ORDINE;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_DESC_PRODOTTO
--
-- DESCRIZIONE:  Restituisce la descrizione di un prodotto
--
-- OPERAZIONI:            
--
--  INPUT: 
--  P_ID_IMPORTI_PRODOTTO     Id dell'importo prodotto                  
--
-- OUTPUT: Stringa contenente la descrizione del prodotto
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_DESC_PRODOTTO(P_ID_IMPORTI_PRODOTTO CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE) RETURN VARCHAR2 IS
v_descrizione CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE;
v_tipo_break CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE;
v_desc_tipo_break CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE;
BEGIN     
     SELECT PV.ID_TIPO_BREAK, CIR.NOME_CIRCUITO ||' - '||MV.DESC_MOD_VENDITA AS DESC_PRODOTTO
     INTO v_tipo_break, v_descrizione
     FROM CD_IMPORTI_PRODOTTO IMPP, CD_PRODOTTO_ACQUISTATO PA, CD_PRODOTTO_VENDITA PV,
          CD_CIRCUITO CIR, CD_MODALITA_VENDITA MV
     WHERE IMPP.ID_IMPORTI_PRODOTTO = P_ID_IMPORTI_PRODOTTO
     AND IMPP.ID_PRODOTTO_aCQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
     AND PA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
     AND PV.ID_CIRCUITO = CIR.ID_CIRCUITO
     AND PV.ID_MOD_VENDITA = MV.ID_MOD_VENDITA;
--
     IF v_tipo_break IS NOT NULL THEN
        SELECT DESC_TIPO_BREAK
        INTO v_desc_tipo_break
        FROM CD_TIPO_BREAK
        WHERE ID_TIPO_BREAK = v_tipo_break;
        v_descrizione := v_descrizione || ' - ' || v_desc_tipo_break;
     END IF;
     RETURN v_descrizione;
END FU_GET_DESC_PRODOTTO;


-----------------------------------------------------------------------------------------------------
-- Procedura PR_VERIFICA_IMPORTI
--
-- DESCRIZIONE:  Controlla che gli importi di fatturazione siano stati inseriti correttamente,
--               particolarmente per verificare l'arrotondamento degli importi
--
-- OPERAZIONI:            
--
--  INPUT: 
--  P_ID_IMPORTI_PRODOTTO     Id dell'importo prodotto                  
--  P_VECCHIO_IMPORTO         Vecchio valore di importo netto
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_VERIFICA_IMPORTI(P_ID_IMPORTI_PRODOTTO CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE, P_VECCHIO_IMPORTO CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE) IS
v_netto CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_netto_parziale CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;

BEGIN
        --Controllo correttezza dati
       -- dbms_output.put_line('P_ID_IMPORTI_PRODOTTO:'||P_ID_IMPORTI_PRODOTTO);
       -- dbms_output.put_line('P_VECCHIO_IMPORTO:'||P_VECCHIO_IMPORTO);


            
            --
        --dbms_output.put_line('P_ID_IMPORTI_PRODOTTO:'||P_ID_IMPORTI_PRODOTTO);
        --dbms_output.put_line('P_VECCHIO_IMPORTO:'||p_vecchio_importo);
            SELECT SUM(IMPORTO_NETTO)
            INTO v_netto_parziale
            FROM CD_IMPORTI_FATTURAZIONE
            WHERE ID_IMPORTI_PRODOTTO = P_ID_IMPORTI_PRODOTTO;
        --
        v_netto_parziale := p_vecchio_importo - v_netto_parziale;
        --dbms_output.put_line('v_netto_parziale:'||v_netto_parziale);
        UPDATE CD_IMPORTI_FATTURAZIONE
        SET IMPORTO_NETTO = IMPORTO_NETTO + v_netto_parziale
        WHERE ID_IMPORTI_PRODOTTO = p_id_importi_prodotto
        AND ID_IMPORTI_FATTURAZIONE = 
        (SELECT MAX(ID_IMPORTI_FATTURAZIONE) 
        FROM CD_IMPORTI_FATTURAZIONE
        WHERE ID_IMPORTI_PRODOTTO = p_id_importi_prodotto);
END PR_VERIFICA_IMPORTI;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_IMPORTI_COMPATIBILI
--
-- DESCRIZIONE:  Restituisce gli importi di fatturazione compatibili.
--               Per essere compatibili gli importi devono avere lo stesso importo prodotto
--               e soggetto dell'importo fatturazione passato in input
--
-- OPERAZIONI:            
--
--  INPUT: 
--  P_ID_IMP_FAT              Id dell'importo fatturazione per cui cercare gli importi compatibili
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_IMPORTI_COMPATIBILI(P_ID_IMP_FAT CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_FATTURAZIONE%TYPE) RETURN  C_IMP_FATTURAZIONE IS
CUR C_IMP_FATTURAZIONE;
v_soggetto CD_IMPORTI_FATTURAZIONE.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_importo_prodotto CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;

BEGIN
    SELECT IMPF.ID_SOGGETTO_DI_PIANO, IMPP.ID_IMPORTI_PRODOTTO
    INTO v_soggetto, v_id_importo_prodotto
    FROM CD_PRODOTTO_ACQUISTATO PA, CD_IMPORTI_PRODOTTO IMPP, CD_IMPORTI_FATTURAZIONE IMPF
    WHERE IMPF.ID_IMPORTI_FATTURAZIONE = P_ID_IMP_FAT
    AND IMPP.ID_IMPORTI_PRODOTTO = IMPF.ID_IMPORTI_PRODOTTO
    AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.COD_DISATTIVAZIONE IS NULL;
    --
    OPEN CUR for
       SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO as ID_PRODOTTO,
       IMP_FAT.DESC_PRODOTTO as DESC_PRODOTTO,
       IMP_FAT.ID_IMPORTI_FATTURAZIONE as ID_IMPORTO,
       IMP_FAT.IMPORTO_NETTO as IMP_NETTO,
       IMP_FAT.STATO_FATTURAZIONE as STATO,
       IMP_FAT.ID_SOGGETTO_DI_PIANO as ID_SOGG_PIANO,
       IMP_FAT.ID_ORDINE as ID_ORDINE,
       IMP_FAT.FLG_INCLUSO_IN_ORDINE as FLG_INCLUSO,
       IMP_FAT.FLG_SOSPESO as FLG_SOSPESO,
       IMP_FAT.DATA_INIZIO as DATA_INIZIO,
       IMP_FAT.DATA_FINE as DATA_FINE,
       SOGG.DESCRIZIONE as DESC_SOGG_PIANO,
       ORD.ID_PIANO || '/' || ORD.ID_VER_PIANO || '/' || ORD.COD_PRG_ORDINE AS COD_ORDINE,
       DECODE(IMP_PRO.TIPO_CONTRATTO,'C','Commerciale','Direzionale') AS TIPO_CONTRATTO,
       PR_ACQ.IMP_NETTO as NETTO_PRODOTTO,
       NULL
    FROM 
         CD_PRODOTTO_ACQUISTATO PR_ACQ,
         CD_IMPORTI_PRODOTTO IMP_PRO,
         CD_SOGGETTO_DI_PIANO SOGG, 
         CD_ORDINE ORD,
         CD_IMPORTI_FATTURAZIONE IMP_FAT
    WHERE IMP_FAT.ID_IMPORTI_PRODOTTO = v_id_importo_prodotto
    AND IMP_FAT.FLG_ANNULLATO = 'N'
    AND IMP_FAT.ID_SOGGETTO_DI_PIANO = v_soggetto
    AND IMP_FAT.ID_IMPORTI_FATTURAZIONE <> P_ID_IMP_FAT
    AND IMP_FAT.STATO_FATTURAZIONE = 'DAT'
    AND IMP_FAT.ID_SOGGETTO_DI_PIANO = SOGG.ID_SOGGETTO_DI_PIANO
    AND ORD.ID_ORDINE = IMP_FAT.ID_ORDINE
    AND ORD.FLG_ANNULLATO = 'N'
    AND ORD.FLG_SOSPESO = 'N'
    AND IMP_PRO.ID_IMPORTI_PRODOTTO = IMP_FAT.ID_IMPORTI_PRODOTTO
    AND PR_ACQ.ID_PRODOTTO_ACQUISTATO = IMP_PRO.ID_PRODOTTO_ACQUISTATO
    AND PR_ACQ.FLG_ANNULLATO = 'N'
    AND PR_ACQ.FLG_SOSPESO = 'N'
    AND PR_ACQ.COD_DISATTIVAZIONE IS NULL
    ORDER BY DATA_INIZIO, ID_PRODOTTO;
RETURN CUR ;
EXCEPTION
WHEN OTHERS THEN
RAISE;    
END FU_GET_IMPORTI_COMPATIBILI;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_SPOSTA_IMPORTI
--
-- DESCRIZIONE:  Sposta una parte di netto da un importo fatturazione ad un altro
--
-- OPERAZIONI:            
--
--  INPUT: 
--  P_ID_IMP_FAT_1             Id dell'importo fatturazione originario
--  P_ID_IMP_FAT_2             Id dell'importo fatturazione di destinazione
--  P_IMPORTO                  Importo da spostare
--
-- OUTPUT:
--  P_NUOVO_NETTO_1            Nuovo valore di netto dell'importo fatturazione originario
--  P_NUOVO_NETTO_2            Nuovo valore di netto dell'importo fatturazione di destinazione
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_SPOSTA_IMPORTI(P_ID_IMP_FAT_1 CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_FATTURAZIONE%TYPE,P_ID_IMP_FAT_2 CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_FATTURAZIONE%TYPE, P_IMPORTO CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE, P_NUOVO_NETTO_1 OUT CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE, P_NUOVO_NETTO_2 OUT CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE) IS
BEGIN
    UPDATE CD_IMPORTI_FATTURAZIONE
    SET IMPORTO_NETTO = IMPORTO_NETTO - P_IMPORTO
    WHERE ID_IMPORTI_FATTURAZIONE = P_ID_IMP_FAT_1;
    --
    SELECT IMPORTO_NETTO
    INTO P_NUOVO_NETTO_1
    FROM CD_IMPORTI_FATTURAZIONE
    WHERE ID_IMPORTI_FATTURAZIONE = P_ID_IMP_FAT_1;
    --
    UPDATE CD_IMPORTI_FATTURAZIONE
    SET IMPORTO_NETTO = IMPORTO_NETTO + P_IMPORTO
    WHERE ID_IMPORTI_FATTURAZIONE = P_ID_IMP_FAT_2;
    --
    SELECT IMPORTO_NETTO
    INTO P_NUOVO_NETTO_2
    FROM CD_IMPORTI_FATTURAZIONE
    WHERE ID_IMPORTI_FATTURAZIONE = P_ID_IMP_FAT_2;   
EXCEPTION
WHEN OTHERS THEN
RAISE;  
END PR_SPOSTA_IMPORTI;

PROCEDURE PR_ESTENDI_PERIODO(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE,P_DATA_INIZIO CD_ORDINE.DATA_INIZIO%TYPE, P_DATA_FINE CD_ORDINE.DATA_FINE%TYPE, P_ESITO OUT NUMBER) IS
v_min_data CD_IMPORTI_FATTURAZIONE.DATA_INIZIO%TYPE;
v_max_data CD_IMPORTI_FATTURAZIONE.DATA_FINE%TYPE;
BEGIN
    SELECT MIN(DATA_INIZIO), MAX(DATA_FINE)
    INTO v_min_data, v_max_data
    FROM CD_IMPORTI_FATTURAZIONE
    WHERE ID_ORDINE = P_ID_ORDINE
    AND FLG_ANNULLATO = 'N';
    
    IF P_DATA_INIZIO <= v_min_data AND P_DATA_FINE >= v_max_data THEN
        UPDATE CD_ORDINE 
        SET DATA_INIZIO = P_DATA_INIZIO,
            DATA_FINE = P_DATA_FINE
        WHERE ID_ORDINE = P_ID_ORDINE;
        P_ESITO := 1;
    ELSE
        P_ESITO := -2;
    END IF;
EXCEPTION
WHEN OTHERS THEN
    P_ESITO := -1;
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_ESTENDI_PERIODO: Si e'' verificato un errore  '||SQLERRM);
END PR_ESTENDI_PERIODO;

PROCEDURE PR_CREA_ORDINE(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                      P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                      P_ORDINE_VECCHIO CD_ORDINE.ID_ORDINE%TYPE,
                      P_DATA_INIZIO CD_ORDINE.DATA_INIZIO%TYPE,
                      P_DATA_FINE CD_ORDINE.DATA_FINE%TYPE,
                      P_ID_FRUITORE CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE,
                      P_ID_ORDINE OUT CD_ORDINE.ID_ORDINE%TYPE) IS
                      
    v_ordine_vecchio CD_ORDINE.ID_ORDINE%TYPE := P_ORDINE_VECCHIO;
    v_data_inizio_temp CD_ORDINE.DATA_INIZIO%TYPE := P_DATA_INIZIO;
    v_data_fine_temp CD_ORDINE.DATA_FINE%TYPE := P_DATA_FINE;
    v_giorno_inizio number;
    BEGIN
        SAVEPOINT PR_CREA_ORDINE;
        
        WHILE v_data_inizio_temp <= P_DATA_FINE LOOP
            --
            --dbms_output.PUT_LINE('Data inizio: '||v_data_inizio_temp);
            v_giorno_inizio := to_number(to_char(v_data_inizio_temp,'DD'));
            IF v_giorno_inizio <= 15 THEN
                v_data_fine_temp := LEAST(P_DATA_FINE,v_data_inizio_temp - v_giorno_inizio + 15);
            ELSE
                v_data_fine_temp := LEAST(P_DATA_FINE,LAST_DAY(v_data_inizio_temp));
            END IF;
            --
            --dbms_output.PUT_LINE('Data fine: '||v_data_fine_temp);
            --dbms_output.PUT_LINE('Id ordine: '||v_ordine_vecchio);
            PR_CREA_ORDINE_PARZIALE(P_ID_PIANO,
                          P_ID_VER_PIANO,
                          v_ordine_vecchio,
                          v_data_inizio_temp,
                          v_data_fine_temp,
                          P_ID_FRUITORE,
                          P_ID_ORDINE);          
        v_ordine_vecchio := P_ID_ORDINE;
        v_data_inizio_temp := v_data_fine_temp +1;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_CREA_ORDINE: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_CREA_ORDINE;
END PR_CREA_ORDINE;    

---PR_IMPOSTA_FLG_MODIFICA_ORDINE
---Realizzatore Mauro Viel Altran Italia Aprile 2010
---Consente di la modifica del flg_modifica_ordine

PROCEDURE PR_IMPOSTA_FLG_MODIFICA_ORDINE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE, P_FLG_ORDINE_MODIFICATO CD_STAMPE_ORDINE.FLG_ORDINE_MODIFICATO%TYPE) IS
BEGIN
 
 UPDATE CD_STAMPE_ORDINE 
 SET    FLG_ORDINE_MODIFICATO = 'S'
 WHERE  ID_ORDINE = P_ID_ORDINE;
 
END PR_IMPOSTA_FLG_MODIFICA_ORDINE;


---Inserita la clausola  "and IFA.IMPORTO_NETTO > 0" in modo da eliminare le righe
--doppie generate da aliquote divese per la quota commerciale e direzionale. 
--La prodedura non visualizera gli intermediari legati a prodotti con sconto 100. 

FUNCTION FU_GET_INTERMEDIARI(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE) RETURN C_INTERMEDIARI IS
INTERMEDIARI C_INTERMEDIARI;
BEGIN

open INTERMEDIARI for
select --VE.cognome as COGNOME_VENDITORE, 
       VE.RAG_SOC_COGN as NOME_VENDITORE, 
       IFA.perc_vend_cli AS PERCENTULE_VENDITORE, 
       AG.RAG_SOC_COGN AS NOME_AGENZIA, 
       CM.RAG_SOC_COGN AS NOME_CENTRO_MEDIA, 
       IFA.PERC_SCONTO_SOST_AGE  as PERCENTULE_SCONTO_SOSTITUTIVO
from
         v_centro_media CM,
         vi_cd_agenzia AG,
         interl_u VE,
         cd_raggruppamento_intermediari RI,
         cd_prodotto_acquistato PA,
         cd_importi_prodotto IP,
         cd_importi_fatturazione IFA
where    IFA.id_ordine = P_ID_ORDINE
and      IFA.flg_annullato='N'
and      IFA.FLG_INCLUSO_IN_ORDINE ='S'
and      IFA.FLG_SOSPESO ='N'
and      IFA.IMPORTO_NETTO > 0
and      IP.id_importi_prodotto = IFA.id_importi_prodotto
and      PA.id_prodotto_acquistato = IP.id_prodotto_acquistato
and      pa.flg_annullato = 'N'
and      pa.flg_sospeso = 'N'
and      pa.cod_disattivazione is null
and      RI.id_raggruppamento = PA.id_raggruppamento
and      VE.cod_interl=RI.id_venditore_cliente
and      AG.id_agenzia(+) = RI.id_agenzia
and      CM.id_centro_media(+) = RI.id_centro_media
group by VE.RAG_SOC_COGN, IFA.perc_vend_cli, AG.RAG_SOC_COGN, CM.RAG_SOC_COGN, IFA.PERC_SCONTO_SOST_AGE;

       
RETURN INTERMEDIARI;

EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'FUNCTION FU_GET_INTERMEDIARI: Si e'' verificato un errore  '||SQLERRM);
END FU_GET_INTERMEDIARI;


FUNCTION FU_GET_STATO_FATTURAZIONE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE) RETURN C_STATO_FATTURAZIONE IS
STATO_FATTURAZIONE c_STATO_FATTURAZIONE;
BEGIN
    open STATO_FATTURAZIONE for
    select decode(count(1),0,'DAFATTURARE','FATTURATO') as STATO_FATTURAZIONE
    from cd_importi_fatturazione  
    where id_ordine = P_ID_ORDINE
    and  flg_incluso_in_ordine = 'S'
    and  flg_annullato ='N'
    and  stato_fatturazione in ('DAR','TRA');
return STATO_FATTURAZIONE;
END;


FUNCTION FU_GET_STAMPE_ORDINE(P_ID_ORDINE CD_ORDINE.ID_ORDINE%TYPE) RETURN C_STAMPE_ORDINE IS
V_STAMPE_ORDINE C_STAMPE_ORDINE;
BEGIN
open V_STAMPE_ORDINE
for select id_stampe_ordine,flg_ordine_modificato, 'S'  as flg_esiste  
from cd_stampe_ordine where id_ordine = p_id_ordine 
union  
select  0 as id_stampe_ordine, 'N' as flg_ordine_modificato, 'N' as flg_esiste
from dual 
order by id_stampe_ordine desc;
return V_STAMPE_ORDINE;
END FU_GET_STAMPE_ORDINE;

END PA_CD_ORDINE; 
/

