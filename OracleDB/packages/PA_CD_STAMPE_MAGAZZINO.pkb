CREATE OR REPLACE PACKAGE BODY VENCD.pa_cd_stampe_magazzino
AS
/******************************************************************************
   NAME:       PA_CD_STAMPE_MAGAZZINO
   PURPOSE:

   REVISIONS:
   Ver        Date        Author                    Description
   ---------  ----------  ---------------           ------------------------------------
   1.0        09/09/2009   Mauro Viel Altran        1. Created this package body.
   2.0        10/09/2009   Daniela Spezia Altran    2. Modify
   2.1        14/06/2011   Aggiunta la costante V_FATTORE_MOLT_PROIEZ_ARENA x ottenere una sola proiezioen nelle arene
******************************************************************************/
--
--
-- VARIABILI DI PACKAGE
-- La variabile seguente (impostata a 4) serve per ottenere le proiezioni attese sulla base
-- degli schermi/sale di proiezione.
-- Sia nel caso della stampa proposta che nella stampa prodotti richiesti, vengono visualizzati il numero
-- di sale e il numero di proiezioni "attese". Quest'ultimo valore viene determinato nel modo seguente:
-- numero_schermi * fattore_moltiplicativo * numero_giorni_di proiezione
-- dove il numero di giorni di proiezione e dato dalla differenza (data_fine - data_inizio + 1)
-- (si somma 1 per comprendere entrambi i giorni di inizio e fine)
V_FATTORE_MOLT_PROIEZ_ATTESE NUMBER:= 4;

V_FATTORE_MOLT_PROIEZ_ARENA  NUMBER :=1;
--
----Creata da Mauro Viel Altran italia il 3/12/2009
--Dato un id_prodotto richiesto restituisce al sua durata in secondi.
--per le iniziative speciali la stringa vuota
FUNCTION FU_GET_FORMATO_PROD_RIC(P_ID_PRODOTTI_RICHIESTI cd_prodotti_richiesti.ID_PRODOTTI_RICHIESTI%type) RETURN varchar2 IS
v_durata cd_coeff_cinema.ID_COEFF%type;
BEGIN
   select durata into v_durata
    from cd_prodotti_richiesti ric,cd_formato_acquistabile forma , cd_coeff_cinema coeff
    where ric.id_prodotti_richiesti = P_ID_PRODOTTI_RICHIESTI
    and  ric.ID_FORMATO = forma.ID_FORMATO
    and  coeff.ID_COEFF = forma.ID_COEFF;
   RETURN v_durata;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       return ' ';
     WHEN OTHERS THEN
       return ' ';
END FU_GET_FORMATO_PROD_RIC;

-----------------------------------------------------------------------------------------------------
-- Funzione fu_importi_test
--
-- DESCRIZIONE:  Esegue l'estrazine del numero piano progressivo e degli importi. E' una funzioemn di demo
--
-- OPERAZIONI:
--     1) Esegue l
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resulser contenente periodo e importi
--
-- REALIZZATORE: Mauro Viel, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_importi_test (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN c_richiesta_test
   AS
      c_ric   c_richiesta_test;
   BEGIN
      OPEN c_ric FOR
         SELECT pia.id_piano AS idpiano, pia.id_ver_piano AS idprog,
                per || '/' || ciclo || '/' || anno AS periodo, lordo, netto,
                perc_sc AS persc
           FROM cd_importi_richiesta imp, cd_pianificazione pia
          WHERE pia.id_piano = p_id_piano
            AND pia.id_ver_piano = p_id_ver_piano
            AND pia.id_piano = imp.id_piano(+)
            AND pia.id_ver_piano = imp.id_ver_piano(+);

      RETURN c_ric;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error (-20003,
                                     'Funzione  fu_importi_test. errore'
                                  || SQLERRM
                                 );
   END fu_importi_test;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_importi_e_dati_base
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati correlati
-- al piano stesso (area, sede, cliente, target, stato di vendita, ...) e degli importi.
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resulset contenente i dati del piano, i dati dei periodi e gli importi
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_importi_e_dati_base (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN c_richiesta_stampa_importi
   AS
--
      c_ric   c_richiesta_stampa_importi;
--
   BEGIN
      OPEN c_ric FOR
         SELECT pian.id_piano as idPiano, pian.id_ver_piano as idVersionePiano,
            pa_cd_pianificazione.get_desc_responsabile(pian.ID_CLIENTE) as nomeCliente,
            pa_cd_pianificazione.get_desc_responsabile(pian.ID_RESPONSABILE_CONTATTO) as nomeRespContatto,
            pian.cod_area as codArea, pa_cd_pianificazione.get_desc_area(pian.COD_AREA) as descArea,
            pian.cod_sede as codSede, pa_cd_pianificazione.get_desc_sedi(pian.COD_SEDE) as descSede,
            (select sv.descrizione from cd_stato_di_vendita sv
                where pian.id_stato_vendita = sv.id_stato_vendita) as descStatoVendita,
            tar.nome_target as nomeTarget,
            pian.data_creazione_richiesta as dataCreaz, pian.data_invio_magazzino as dataInvioMagazzino,
            irp.anno||'/'||irp.ciclo||'/'||irp.per as periodo,
            per.DATA_INIZ as dataInizio, per.DATA_FINE as dataFine,
            ROUND(irp.netto, 2) as netto, ROUND(irp.lordo, 2) as lordo,
            TRUNC(irp.perc_sc, 3) as sconto, irp.nota as nota
           FROM
            cd_pianificazione pian,
            cd_target tar,
            cd_importi_richiesta irp,
            periodi per
          WHERE pian.id_piano = p_id_piano AND pian.id_ver_piano = p_id_ver_piano
            AND   (irp.id_piano  (+)= pian.id_piano)
            AND   (irp.id_ver_piano (+) = pian.id_ver_piano)
            AND   irp.FLG_ANNULLATO (+) = 'N'
            AND per.ANNO = irp.ANNO
            AND per.CICLO = irp.CICLO
            AND per.PER = irp.PER
            AND tar.id_target (+)= pian.id_target
            AND pian.FLG_ANNULLATO = 'N'
            and pian.FLG_SOSPESO = 'N'
        UNION
        (SELECT pian.id_piano as idPiano, pian.id_ver_piano as idVersionePiano,
                    pa_cd_pianificazione.get_desc_responsabile(pian.ID_CLIENTE) as nomeCliente,
                    pa_cd_pianificazione.get_desc_responsabile(pian.ID_RESPONSABILE_CONTATTO) as nomeRespContatto,
                    pian.cod_area as codArea, pa_cd_pianificazione.get_desc_area(pian.COD_AREA) as descArea,
                    pian.cod_sede as codSede, pa_cd_pianificazione.get_desc_sedi(pian.COD_SEDE) as descSede,
                    (select sv.descrizione from cd_stato_di_vendita sv
                        where pian.id_stato_vendita = sv.id_stato_vendita) as descStatoVendita,
                    tar.nome_target as nomeTarget,
                    pian.data_creazione_richiesta as dataCreaz, pian.data_invio_magazzino as dataInvioMagazzino,
                    '*' as periodo,
                    per.DATA_INIZIO as dataInizio, per.DATA_FINE as dataFine,
                    ROUND(irp.netto, 2) as netto, ROUND(irp.lordo, 2) as lordo,
                    TRUNC(irp.perc_sc, 3) as sconto, irp.nota as nota
                   FROM
                    cd_pianificazione pian,
                    cd_target tar,
                    cd_importi_richiesta irp,
                    cd_periodo_speciale per
                  WHERE pian.id_piano = p_id_piano AND pian.id_ver_piano = p_id_ver_piano
                    AND   (irp.id_piano  (+)= pian.id_piano)
                    AND   (irp.id_ver_piano (+) = pian.id_ver_piano)
                    AND   irp.FLG_ANNULLATO (+) = 'N'
                    AND per.id_periodo_speciale = irp.id_periodo_speciale
                    AND tar.id_target (+)= pian.id_target
                    AND pian.FLG_ANNULLATO = 'N'
                    and pian.FLG_SOSPESO = 'N')
        UNION
        (SELECT pian.id_piano as idPiano, pian.id_ver_piano as idVersionePiano,
                    pa_cd_pianificazione.get_desc_responsabile(pian.ID_CLIENTE) as nomeCliente,
                    pa_cd_pianificazione.get_desc_responsabile(pian.ID_RESPONSABILE_CONTATTO) as nomeRespContatto,
                    pian.cod_area as codArea, pa_cd_pianificazione.get_desc_area(pian.COD_AREA) as descArea,
                    pian.cod_sede as codSede, pa_cd_pianificazione.get_desc_sedi(pian.COD_SEDE) as descSede,
                    (select sv.descrizione from cd_stato_di_vendita sv
                        where pian.id_stato_vendita = sv.id_stato_vendita) as descStatoVendita,
                    tar.nome_target as nomeTarget,
                    pian.data_creazione_richiesta as dataCreaz, pian.data_invio_magazzino as dataInvioMagazzino,
                    '*' as periodo,
                    per.DATA_INIZIO as dataInizio, per.DATA_FINE as dataFine,
                    ROUND(irp.netto, 2) as netto, ROUND(irp.lordo, 2) as lordo,
                    TRUNC(irp.perc_sc, 3) as sconto, irp.nota as nota
                   FROM
                    cd_pianificazione pian,
                    cd_target tar,
                    cd_importi_richiesta irp,
                    cd_periodi_cinema per
                  WHERE pian.id_piano = p_id_piano AND pian.id_ver_piano = p_id_ver_piano
                    AND   (irp.id_piano  (+)= pian.id_piano)
                    AND   (irp.id_ver_piano (+) = pian.id_ver_piano)
                    AND   irp.FLG_ANNULLATO (+) = 'N'
                    AND per.id_periodo = irp.id_periodo
                    AND tar.id_target (+)= pian.id_target
                    AND pian.FLG_ANNULLATO = 'N'
                    and pian.FLG_SOSPESO = 'N')
        ORDER BY dataInizio, dataFine;
--
      RETURN c_ric;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_importi_e_dati_base in errore: '
                             || SQLERRM
                            );
   END fu_importi_e_dati_base;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_raggrupp_intermed
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati correlati
-- al raggruppamento intermediari del piano stesso.
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resulset contenente i dati del raggruppamento intermediari
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_raggrupp_intermed (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_RAGGRUPP_INTERMEDIARI
   AS
--
      c_ri   C_RAGGRUPP_INTERMEDIARI;
--
   BEGIN
      OPEN c_ri FOR
         SELECT ri.id_piano as idPiano, ri.id_ver_piano as idVersionePiano,
                ri.ID_AGENZIA as idAgenzia, a.RAG_SOC_COGN as agenzia,
                ri.ID_CENTRO_MEDIA as idCentroMedia, cm.RAG_SOC_COGN as centroMedia,
                ri.ID_VENDITORE_CLIENTE as idVendCliente,
                pa_cd_pianificazione.get_desc_responsabile(ri.ID_VENDITORE_CLIENTE) as vendCli
           FROM
            cd_raggruppamento_intermediari ri
                LEFT JOIN vi_cd_agenzia a ON ri.ID_AGENZIA = a.ID_AGENZIA
                LEFT JOIN vi_cd_centro_media cm ON ri.ID_CENTRO_MEDIA = cm.ID_CENTRO_MEDIA
          WHERE ri.id_piano = p_id_piano AND ri.id_ver_piano = p_id_ver_piano
            ORDER BY agenzia, centroMedia, vendCli;
--
      RETURN c_ri;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_raggrupp_intermed in errore: '
                             || SQLERRM
                            );
   END fu_raggrupp_intermed;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_tot_importi_rich
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali correlati
-- al piano stesso e utili per la stampa richiesta.
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resultset contenente i dati del raggruppamento intermediari
--
-- REALIZZATORE: Daniela Spezia, Altran , Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_tot_importi_rich (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_RICHIESTA_TOT_IMPORTI
   AS
--
      c_tot   C_RICHIESTA_TOT_IMPORTI;
--
   BEGIN
      OPEN c_tot FOR
         SELECT
               ROUND(SUM(irp.netto), 2) as totNetto,
               ROUND(SUM(irp.lordo), 2) as totLordo,
               TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(IRP.NETTO),0), NVL(SUM(IRP.LORDO),0) - NVL(SUM(IRP.NETTO),0)), 3) as totSconto
           FROM
            cd_pianificazione pian,
            cd_importi_richiesta irp
          WHERE pian.id_piano = p_id_piano AND pian.id_ver_piano = p_id_ver_piano
            AND   (irp.id_piano  (+)= pian.id_piano)
            AND   (irp.id_ver_piano (+) = pian.id_ver_piano)
            AND   irp.FLG_ANNULLATO (+) = 'N'
            AND pian.FLG_ANNULLATO = 'N'
            and pian.FLG_SOSPESO = 'N';
--
      RETURN c_tot;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_tot_importi_rich in errore: '
                             || SQLERRM
                            );
   END fu_tot_importi_rich;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dati_proposta
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati "di testata"
-- del piano stesso (area, cliente, responsabile di contatto, venditore cliente, agenzia)
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resulset contenente i dati della testata per la stampa proposta
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dati_proposta (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_TESTATA_PROPOSTA
   AS
--
      c_dati   C_TESTATA_PROPOSTA;
--
   BEGIN
      OPEN c_dati FOR
         SELECT pian.id_piano as idPiano, pian.id_ver_piano as idVersionePiano,
                pian.DATA_CREAZIONE_RICHIESTA as dataCreaz,
                pian.cod_area as codArea, pa_cd_pianificazione.get_desc_area(pian.COD_AREA) as descArea,
                pa_cd_pianificazione.get_desc_responsabile(pian.ID_CLIENTE) as nomeCliente,
                pa_cd_pianificazione.get_desc_responsabile(pian.ID_RESPONSABILE_CONTATTO) as nomeRespContatto,
                ri.ID_AGENZIA as idAgenzia, a.RAG_SOC_COGN as agenzia,
                ri.ID_VENDITORE_CLIENTE as idVendCliente,
                pa_cd_pianificazione.get_desc_responsabile(ri.ID_VENDITORE_CLIENTE) as vendCli,
                slav.DESCRIZIONE as statoLavorazione,
                sp.descrizione as descSoggettoPiano
           FROM
            cd_pianificazione pian, cd_raggruppamento_intermediari ri, vi_cd_agenzia a,
            cd_stato_lavorazione slav, cd_soggetto_di_piano sp
          WHERE pian.id_piano = p_id_piano
          AND  pian.id_ver_piano = p_id_ver_piano
          and ri.ID_PIANO (+)= pian.ID_PIANO and ri.ID_VER_PIANO (+)= pian.ID_VER_PIANO
          AND a.ID_AGENZIA (+)= ri.ID_AGENZIA
          AND pian.ID_STATO_LAV = slav.id_stato_lav
          AND pian.FLG_ANNULLATO = 'N'
          and pian.FLG_SOSPESO = 'N'
          and sp.id_piano (+)= pian.id_piano
          and sp.id_ver_piano (+)= pian.id_ver_piano;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dati_proposta in errore: '
                             || SQLERRM
                            );
   END fu_dati_proposta;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_proposta_tab
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati "di dettaglio"
-- del piano stesso; e possibile fornire ulteriori parametri corrispondenti a eventuali criteri di filtro
-- Questa function va usata nel caso di famiglia pubblicitaria TABELLARE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati di dettaglio per la stampa proposta
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE: Mauro Viel Altran 14/06/2011 inserita la chiamata 
--             fu_get_numero_proiezioni(idProdAcquistato,null) as numProiezioni
--             al fine di differenziare le proiezioni fra dale e arene. 
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dettaglio_proposta_tab (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_PROPOSTA
   AS
--
      c_dati   C_DETTAGLIO_PROPOSTA;
--
   BEGIN
      OPEN c_dati FOR
          select idSoggettoPiano, descSoggettoPiano,idProdAcquistato,descProdottoAcquistato,
          PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(idProdAcquistato) as numSchermi,
          /*(PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(idProdAcquistato) * V_FATTORE_MOLT_PROIEZ_ATTESE *
            (periodoVenditaAl - periodoVenditaDal + 1)) as numProiezioni, -- al momento restituisco sempre 4 volte proiezioni al giorno per ogni schermo!*/
          fu_get_numero_proiezioni(idProdAcquistato,null) as numProiezioni,  
          famigliaPubblicitaria,codFamigliaPubb,
          periodoVenditaDal, periodoVenditaAl,
          estensioneTemporale,circuito,tipoFilmato,modalitaVendita,statoVendita,formato,
          tariffaVariabile,tariffa,maggiorazione,lordo,nettoComm,nettoDir,scontoComm,scontoDir,
          percScontoComm,percScontoDir,sanatoria,recupero
          from
            (
                select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
               (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 (SELECT tb.desc_tipo_break from cd_tipo_break tb
                    where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                pa.STATO_DI_VENDITA as statoVendita,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 2) as tariffa,
                ROUND(pa.imp_maggiorazione, 2) as maggiorazione,
                ROUND(pa.IMP_LORDO, 2) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                    cd_prodotto_pubb pp, cd_comunicato c
                where pa.ID_PIANO = p_id_piano
                and pa.ID_VER_PIANO = p_id_ver_piano
                AND PA.ID_PRODOTTO_ACQUISTATO NOT IN
                    (
                    select idProdAcquistato from
                        (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                    pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                        from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                        where pa.ID_PIANO = p_id_piano
                        and pa.ID_VER_PIANO = p_id_ver_piano
                        and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                        and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                        and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                        and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and pa.flg_annullato = 'N'
                    and pa.flg_sospeso = 'N'
                    and pa.COD_DISATTIVAZIONE IS NULL
                    and c.FLG_ANNULLATO = 'N'
                    and c.FLG_SOSPESO = 'N'
                    and c.COD_DISATTIVAZIONE IS NULL
                    group by pa.ID_PRODOTTO_ACQUISTATO
                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                where conta.numSoggetti > 1
                )
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and c.FLG_ANNULLATO = 'N'
            and c.FLG_SOSPESO = 'N'
            and c.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N'

UNION
(select -pa.ID_PRODOTTO_ACQUISTATO idSoggettoPiano, '*' as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
               (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 (SELECT tb.desc_tipo_break from cd_tipo_break tb
                    where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                pa.STATO_DI_VENDITA as statoVendita,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 2) as tariffa,
                ROUND(pa.imp_maggiorazione, 2) as maggiorazione,
                ROUND(pa.IMP_LORDO, 2) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                    from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                        cd_prodotto_pubb pp
                    where pa.ID_PIANO = p_id_piano
                    and pa.ID_VER_PIANO = p_id_ver_piano
                    AND PA.ID_PRODOTTO_ACQUISTATO IN
                        (
                        select idProdAcquistato from
                            (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                        pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                            from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                            where pa.ID_PIANO = p_id_piano
                            and pa.ID_VER_PIANO = p_id_ver_piano
                            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                            and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                            and pa.flg_annullato = 'N'
                            and pa.flg_sospeso = 'N'
                            and pa.COD_DISATTIVAZIONE IS NULL
                            and c.FLG_ANNULLATO = 'N'
                            and c.FLG_SOSPESO = 'N'
                            and c.COD_DISATTIVAZIONE IS NULL
                            group by pa.ID_PRODOTTO_ACQUISTATO
                            order by pa.ID_PRODOTTO_ACQUISTATO) conta
                        where conta.numSoggetti > 1
                        )
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N')
            )
          order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dettaglio_proposta_tab in errore: '
                             || SQLERRM
                            );
   END fu_dettaglio_proposta_tab;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_proposta_isp
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati "di dettaglio"
-- del piano stesso; e possibile fornire ulteriori parametri corrispondenti a eventuali criteri di filtro
-- Questa function va usata nel caso di famiglia pubblicitaria INIZIATIVA SPECIALE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati di dettaglio per la stampa proposta
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dettaglio_proposta_isp (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_PROPOSTA
   AS
--
      c_dati   C_DETTAGLIO_PROPOSTA;
--
   BEGIN
   OPEN c_dati FOR
         select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto as descProdotto,
                0 as numSchermi, 0 as numProiezioni,
                (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 pp.desc_prodotto as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                 --(SELECT sv.descrizione from cd_stato_di_vendita sv
                --    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as statoVendita,
                    pa.STATO_DI_VENDITA as statoVendita,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                  --  0 as numSchermi, 0 as numProiezioni,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 2) as tariffa,
                ROUND(pa.imp_maggiorazione, 2) as maggiorazione,
                ROUND(pa.IMP_LORDO, 2) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and c.FLG_ANNULLATO = 'N'
            and c.FLG_SOSPESO = 'N'
            and c.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N'
            AND PA.ID_PRODOTTO_ACQUISTATO NOT IN
                (
                select idProdAcquistato from
                    (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                    from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                    where pa.ID_PIANO = p_id_piano
                    and pa.ID_VER_PIANO = p_id_ver_piano
                    and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                    and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                    and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                    and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and pa.flg_annullato = 'N'
                    and pa.flg_sospeso = 'N'
                    and pa.COD_DISATTIVAZIONE IS NULL
                    and c.FLG_ANNULLATO = 'N'
                    and c.FLG_SOSPESO = 'N'
                    and c.COD_DISATTIVAZIONE IS NULL
                    group by pa.ID_PRODOTTO_ACQUISTATO
                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                where conta.numSoggetti > 1
                )
            UNION
                (
                select -pa.ID_PRODOTTO_ACQUISTATO idSoggettoPiano, '*' as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto as descProdotto,
                0 as numSchermi, 0 as numProiezioni,
                (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 pp.desc_prodotto as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                 --(SELECT sv.descrizione from cd_stato_di_vendita sv
                --    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as statoVendita,
                    pa.STATO_DI_VENDITA as statoVendita,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                 --   0 as numSchermi, 0 as numProiezioni,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 2) as tariffa,
                ROUND(pa.imp_maggiorazione, 2) as maggiorazione,
                ROUND(pa.IMP_LORDO, 2) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and c.FLG_ANNULLATO = 'N'
            and c.FLG_SOSPESO = 'N'
            and c.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N'
            AND PA.ID_PRODOTTO_ACQUISTATO IN
                (
                select idProdAcquistato from
                    (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                    from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                    where pa.ID_PIANO = p_id_piano
                    and pa.ID_VER_PIANO = p_id_ver_piano
                    and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                    and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                    and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                    and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and pa.flg_annullato = 'N'
                    and pa.flg_sospeso = 'N'
                    and pa.COD_DISATTIVAZIONE IS NULL
                    and c.FLG_ANNULLATO = 'N'
                    and c.FLG_SOSPESO = 'N'
                    and c.COD_DISATTIVAZIONE IS NULL
                    group by pa.ID_PRODOTTO_ACQUISTATO
                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                where conta.numSoggetti > 1
                )
                )
            order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dettaglio_proposta_isp in errore: '
                             || SQLERRM
                            );
   END fu_dettaglio_proposta_isp;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_soggetto_tab
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- soggetto) dei prodotti acquistati associati a quel piano; metodo per il caso TABELLARE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_soggetto_tab (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_SOGG
   AS
--
      c_dati   C_TOTALI_SOGG;
--
   BEGIN
   OPEN c_dati FOR
         select base.idSoggettoPiano as idSoggettoPiano,
                base.periodoVenditaDal as periodoVenditaDal,
                base.periodoVenditaAl as periodoVenditaAl,
                ROUND(SUM(base.tariffa), 3) as totTariffa,
                ROUND(SUM(base.maggiorazione), 3) as totMaggiorazione,
                ROUND(SUM(base.lordo), 3) as totLordo,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 3) as totScontoC,
                ROUND(SUM(base.scontoDir), 3) as totScontoD,
                --TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoComm),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoComm),0), NVL(SUM(base.scontoComm),0)),0) - NVL(SUM(base.nettoComm),0)), 3) as totPercScontoC,
                --TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoDir),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoDir),0), NVL(SUM(base.scontoDir),0)),0) - NVL(SUM(base.nettoDir),0)), 3) as totPercScontoD,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoComm),0),NVL(SUM(base.scontoComm),0)),3) as totPercScontoC,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoDir),0), NVL(SUM(base.scontoDir),0)),3) as totPercScontoD,
                ROUND(SUM(base.sanatoria), 3) as totSanatoria,
                ROUND(SUM(base.recupero), 3) as totRecupero
            from
            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
               (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 (SELECT tb.desc_tipo_break from cd_tipo_break tb
                    where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                pa.STATO_DI_VENDITA as statoVendita,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 3) as tariffa,
                ROUND(pa.imp_maggiorazione, 3) as maggiorazione,
                ROUND(pa.IMP_LORDO, 3) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 3) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                    cd_prodotto_pubb pp, cd_comunicato c
                where pa.ID_PIANO = p_id_piano
                and pa.ID_VER_PIANO = p_id_ver_piano
                AND PA.ID_PRODOTTO_ACQUISTATO NOT IN
                    (
                    select idProdAcquistato from
                        (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                    pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                        from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                        where pa.ID_PIANO = p_id_piano
                        and pa.ID_VER_PIANO = p_id_ver_piano
                        and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                        and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                        and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                        and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and pa.flg_annullato = 'N'
                    and pa.flg_sospeso = 'N'
                    and pa.COD_DISATTIVAZIONE IS NULL
                    and c.FLG_ANNULLATO = 'N'
                    and c.FLG_SOSPESO = 'N'
                    and c.COD_DISATTIVAZIONE IS NULL
                    group by pa.ID_PRODOTTO_ACQUISTATO
                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                where conta.numSoggetti > 1
                )
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and c.FLG_ANNULLATO = 'N'
            and c.FLG_SOSPESO = 'N'
            and c.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N'
UNION
(select -pa.ID_PRODOTTO_ACQUISTATO idSoggettoPiano, '*' as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
               (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 (SELECT tb.desc_tipo_break from cd_tipo_break tb
                    where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                pa.STATO_DI_VENDITA as statoVendita,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 3) as tariffa,
                ROUND(pa.imp_maggiorazione, 3) as maggiorazione,
                ROUND(pa.IMP_LORDO, 3) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 3) as sanatoria, ROUND(pa.imp_recupero, 3) as recupero
                    from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                        cd_prodotto_pubb pp
                    where pa.ID_PIANO = p_id_piano
                    and pa.ID_VER_PIANO = p_id_ver_piano
                    AND PA.ID_PRODOTTO_ACQUISTATO IN
                        (
                        select idProdAcquistato from
                            (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                        pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                            from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                            where pa.ID_PIANO = p_id_piano
                            and pa.ID_VER_PIANO = p_id_ver_piano
                            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                            and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                            and pa.flg_annullato = 'N'
                            and pa.flg_sospeso = 'N'
                            and pa.COD_DISATTIVAZIONE IS NULL
                            and c.FLG_ANNULLATO = 'N'
                            and c.FLG_SOSPESO = 'N'
                            and c.COD_DISATTIVAZIONE IS NULL
                            group by pa.ID_PRODOTTO_ACQUISTATO
                            order by pa.ID_PRODOTTO_ACQUISTATO) conta
                        where conta.numSoggetti > 1
                        )
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N')
            ) base
            group by base.periodoVenditaDal, base.periodoVenditaAl, base.idSoggettoPiano;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_soggetto_tab in errore: '
                             || SQLERRM
                            );
   END fu_totali_soggetto_tab;
--
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_soggetto_isp
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- soggetto) dei prodotti acquistati associati a quel piano; metodo per il caso INIZIATIVE SPECIALI
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_soggetto_isp (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_SOGG
   AS
--
      c_dati   C_TOTALI_SOGG;
--
   BEGIN
   OPEN c_dati FOR
         select base.idSoggettoPiano as idSoggettoPiano,
                base.periodoVenditaDal as periodoVenditaDal,
                base.periodoVenditaAl as periodoVenditaAl,
                ROUND(SUM(base.tariffa), 0) as totTariffa,
                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 3) as totLordo,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC,
                ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoComm),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoComm),0), NVL(SUM(base.scontoComm),0)),0) - NVL(SUM(base.nettoComm),0)), 3) as totPercScontoC,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoDir),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoDir),0), NVL(SUM(base.scontoDir),0)),0) - NVL(SUM(base.nettoDir),0)), 3) as totPercScontoD,
                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
                ROUND(SUM(base.recupero), 0) as totRecupero
            from
            (
                select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
                (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 pp.desc_prodotto as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                 --(SELECT sv.descrizione from cd_stato_di_vendita sv
                --    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as statoVendita,
                    pa.STATO_DI_VENDITA as statoVendita,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                    0 as numSchermi,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 0) as tariffa,
                ROUND(pa.imp_maggiorazione, 0) as maggiorazione,
                ROUND(pa.IMP_LORDO, 3) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and c.FLG_ANNULLATO = 'N'
            and c.FLG_SOSPESO = 'N'
            and c.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N'
            AND PA.ID_PRODOTTO_ACQUISTATO NOT IN
                (
                select idProdAcquistato from
                    (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                    from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                    where pa.ID_PIANO = p_id_piano
                    and pa.ID_VER_PIANO = p_id_ver_piano
                    and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                    and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                    and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                    and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and pa.flg_annullato = 'N'
                    and pa.flg_sospeso = 'N'
                    and pa.COD_DISATTIVAZIONE IS NULL
                    and c.FLG_ANNULLATO = 'N'
                    and c.FLG_SOSPESO = 'N'
                    and c.COD_DISATTIVAZIONE IS NULL
                    group by pa.ID_PRODOTTO_ACQUISTATO
                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                where conta.numSoggetti > 1
                )
            UNION
                (
                select -pa.ID_PRODOTTO_ACQUISTATO idSoggettoPiano, '*' as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
                (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 pp.desc_prodotto as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                 --(SELECT sv.descrizione from cd_stato_di_vendita sv
                --    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as statoVendita,
                    pa.STATO_DI_VENDITA as statoVendita,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                    0 as numSchermi,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 0) as tariffa,
                ROUND(pa.imp_maggiorazione, 0) as maggiorazione,
                ROUND(pa.IMP_LORDO, 3) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and c.FLG_ANNULLATO = 'N'
            and c.FLG_SOSPESO = 'N'
            and c.COD_DISATTIVAZIONE IS NULL
            and pv.FLG_ANNULLATO = 'N'
            AND PA.ID_PRODOTTO_ACQUISTATO IN
                (
                select idProdAcquistato from
                    (select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                    from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
                    where pa.ID_PIANO = p_id_piano
                    and pa.ID_VER_PIANO = p_id_ver_piano
                    and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                    and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                    and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                    and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and pa.flg_annullato = 'N'
                    and pa.flg_sospeso = 'N'
                    and pa.COD_DISATTIVAZIONE IS NULL
                    and c.FLG_ANNULLATO = 'N'
                    and c.FLG_SOSPESO = 'N'
                    and c.COD_DISATTIVAZIONE IS NULL
                    group by pa.ID_PRODOTTO_ACQUISTATO
                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                where conta.numSoggetti > 1
                )
               )
            ) base
            group by base.periodoVenditaDal, base.periodoVenditaAl, base.idSoggettoPiano;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_soggetto_isp in errore: '
                             || SQLERRM
                            );
   END fu_totali_soggetto_isp;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_piano_tab
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- l'intero piano) dei prodotti acquistati associati a quel piano; metodo per il caso TABELLARE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_piano_tab (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_PIANO
   AS
--
      c_dati   C_TOTALI_PIANO;
--
   BEGIN
   OPEN c_dati FOR
         select ROUND(SUM(base.tariffa), 0) as totTariffa,
                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 3) as totLordo,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC,
                ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoComm),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoComm),0), NVL(SUM(base.scontoComm),0)),0) - NVL(SUM(base.nettoComm),0)), 3) as totPercScontoC,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoDir),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoDir),0), NVL(SUM(base.scontoDir),0)),0) - NVL(SUM(base.nettoDir),0)), 3) as totPercScontoD,
                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
                ROUND(SUM(base.recupero), 0) as totRecupero
            from
            (select distinct pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
                            pa.IMP_LORDO as lordo,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as nettoComm,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as nettoDir,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as scontoComm,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as scontoDir,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                        from CD_PRODOTTO_ACQUISTATO pa
                        where pa.ID_PIANO = p_id_piano
                        and pa.ID_VER_PIANO = p_id_ver_piano
                        and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                        and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                        and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                        and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                        and pa.flg_annullato = 'N'
                        and pa.flg_sospeso = 'N'
                        and pa.COD_DISATTIVAZIONE IS NULL
            ) base;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_piano_tab in errore: '
                             || SQLERRM
                            );
   END fu_totali_piano_tab;
--
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_piano_isp
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- l'intero piano) dei prodotti acquistati associati a quel piano; metodo per il caso INIZIATIVE SPECIALI
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , NOvembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_piano_isp (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_PIANO
   AS
--
   BEGIN

         RETURN PA_CD_STAMPE_MAGAZZINO.fu_totali_piano_tab(p_id_piano, p_id_ver_piano, p_id_stato_vendita,
                                                    p_id_raggruppamento, p_data_inizio, p_data_fine);
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_piano_isp in errore: '
                             || SQLERRM
                            );
   END fu_totali_piano_isp;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_famiglia_pubb
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce il codice categoria prodotto
-- associato a quel piano, ovvero l'indicazione della famiglia pubblicitaria
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:il codice corrispondente
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_famiglia_pubb (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_FAMIGLIA_PUBB
   AS
    v_return_value C_FAMIGLIA_PUBB;
--
   BEGIN
    OPEN v_return_value FOR
      /*select distinct pp.cod_categoria_prodotto as codCategoriaProdotto
        from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_pubb pp, cd_prodotto_vendita pv
        where pa.ID_PIANO = p_id_piano
        and pa.ID_VER_PIANO = p_id_ver_piano
        and pv.id_prodotto_vendita = pa.id_prodotto_vendita
        and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
        and pa.flg_annullato = 'N';*/
        select COD_CATEGORIA_PRODOTTO as codCategoriaProdotto
        from  cd_pianificazione
        where ID_PIANO = p_id_piano
        and ID_VER_PIANO = p_id_ver_piano
        and flg_annullato = 'N'
        and flg_sospeso = 'N';
--
      RETURN v_return_value;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_famiglia_pubb in errore: '
                             || SQLERRM
                            );
   END fu_famiglia_pubb;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dati_piano
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fornisce i dati caratteristici di quel piano
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dati_piano (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_DATI_PIANO
   AS
--
      c_dati   C_DATI_PIANO;
--
   BEGIN
      OPEN c_dati FOR
         SELECT pian.id_piano as idPiano, pian.id_ver_piano as idVersionePiano, pian.DATA_CREAZIONE_RICHIESTA as dataCreaz,
                pian.cod_area as codArea, pa_cd_pianificazione.get_desc_area(pian.COD_AREA) as descArea,
                pa_cd_pianificazione.get_desc_responsabile(pian.ID_CLIENTE) as nomeCliente,
                pa_cd_pianificazione.get_desc_responsabile(pian.ID_RESPONSABILE_CONTATTO) as nomeRespContatto,
                slav.DESCRIZIONE as statoLavorazione
           FROM
            cd_pianificazione pian, cd_stato_lavorazione slav
          WHERE pian.id_piano = p_id_piano
          AND  pian.id_ver_piano = p_id_ver_piano
          AND pian.ID_STATO_LAV = slav.id_stato_lav
          and pian.flg_annullato = 'N'
          and pian.flg_sospeso = 'N';
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dati_piano in errore: '
                             || SQLERRM
                            );
   END fu_dati_piano;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_ragg_int_no_cm
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati correlati
-- al raggruppamento intermediari del piano stesso. Sono esclusi i dati relativi al centro media
-- (non visualizzato nella stampa calendario)
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resultset contenente i dati del raggruppamento intermediari
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_ragg_int_no_cm (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_RAGG_INT_NO_CM
   AS
--
      c_ri   C_RAGG_INT_NO_CM;
--
   BEGIN
      OPEN c_ri FOR
        SELECT distinct ri.id_piano as idPiano, ri.id_ver_piano as idVersionePiano,
                ri.ID_AGENZIA as idAgenzia, a.RAG_SOC_COGN as agenzia,
               ri.ID_VENDITORE_CLIENTE as idVendCliente,
                pa_cd_pianificazione.get_desc_responsabile(ri.ID_VENDITORE_CLIENTE) as vendCli
           FROM
            cd_raggruppamento_intermediari ri, vi_cd_agenzia a
            WHERE ri.id_piano = p_id_piano
            AND  ri.id_ver_piano = p_id_ver_piano
            AND a.ID_AGENZIA (+)= ri.ID_AGENZIA
            and (ri.ID_AGENZIA is not null OR ri.ID_VENDITORE_CLIENTE is not null);
--
      RETURN c_ri;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_ragg_int_no_cm in errore: '
                             || SQLERRM
                            );
   END fu_ragg_int_no_cm;
   
   
function fu_get_sala_isp(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return varchar2 is
v_sale varchar2(1000):= '';
begin
for c in
    (
        select distinct(nome_sala) as nome_sala 
        from cd_comunicato com, cd_sala_vendita sv,cd_circuito_sala cs, cd_sala sa 
        where com.id_prodotto_acquistato = p_id_prodotto_acquistato
        and   com.ID_SALA_VENDITA = sv.ID_SALA_VENDITA
        and   sv.ID_CIRCUITO_SALA = cs.ID_CIRCUITO_SALA
        and   sa.ID_SALA = cs.ID_SALA
    )
loop
v_sale := v_sale || ' ' || c.nome_sala;  
end loop;
return v_sale;
end  fu_get_sala_isp;

  
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_calendario_isp
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati "di dettaglio"
-- del piano stesso; e possibile fornire ulteriori parametri corrispondenti a eventuali criteri di filtro
-- Questa function va usata nel caso di famiglia pubblicitaria INIZIATIVE SPECIALI per la stampa calendario
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati di dettaglio per la stampa calendario
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE:   Mauro Viel, Altran, Dicembre 2010, inserita la gestione del nome cinema.
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dettaglio_calendario_isp (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_CALENDARIO
   AS
--
      c_dati   C_DETTAGLIO_CALENDARIO;
--
   BEGIN
      OPEN c_dati FOR
         select distinct
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
                circ.ID_CIRCUITO as idCircuito,
                circ.NOME_CIRCUITO as nomeCircuito,
                pa.STATO_DI_VENDITA as codStato,
                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                (select pp.desc_prodotto from cd_prodotto_pubb pp
                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB) as tipoPubb,
                (select mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                cin.id_cinema as idCinema,
                --cin.nome_cinema as nomeCinema,
                pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,pa.data_fine) as nomeCinema,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as comuneCinema,
                (select abbr from cd_provincia prov, cd_comune comune
                        where comune.id_comune = cin.id_comune
                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
                '' as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
                0 as numProiezioni,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                0 as posizione
                from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                     cd_circuito circ, cd_circuito_cinema cc, cd_cinema cin, cd_comunicato com, cd_cinema_vendita cv
                where pa.ID_PIANO = p_id_piano
                  and pa.ID_VER_PIANO = p_id_ver_piano
                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                  and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                  and circ.ID_CIRCUITO = pv.ID_CIRCUITO
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and pv.FLG_ANNULLATO = 'N'
                  and circ.FLG_ANNULLATO = 'N'
                  and cc.flg_annullato = 'N'
                  and cin.flg_annullato = 'N'
                  and cc.id_circuito = circ.ID_CIRCUITO
                  and cc.id_cinema = cin.id_cinema
                  and cv.id_cinema_vendita = com.ID_CINEMA_VENDITA
                  and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  and cc.ID_CIRCUITO_CINEMA = cv.id_circuito_cinema
                  and com.flg_annullato = 'N'
                  and com.flg_sospeso = 'N'
                  and com.COD_DISATTIVAZIONE IS NULL
        union
        (select distinct
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
                circ.ID_CIRCUITO as idCircuito,
                circ.NOME_CIRCUITO as nomeCircuito,
                pa.STATO_DI_VENDITA as codStato,
                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                (select pp.desc_prodotto from cd_prodotto_pubb pp
                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB) as tipoPubb,
                (select mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                cin.id_cinema as idCinema,
                pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,pa.data_fine) as nomeCinema,
                --cin.nome_cinema as nomeCinema,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as comuneCinema,
                (select abbr from cd_provincia prov, cd_comune comune
                        where comune.id_comune = cin.id_comune
                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
                '' as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
                0 as numProiezioni,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                0 as posizione
                from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                    cd_circuito circ, cd_cinema cin, cd_circuito_atrio ca, cd_atrio atr,cd_comunicato com, cd_atrio_vendita av
                where pa.ID_PIANO = p_id_piano
                  and pa.ID_VER_PIANO = p_id_ver_piano
                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                  and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                  and circ.ID_CIRCUITO = pv.ID_CIRCUITO
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and pv.FLG_ANNULLATO = 'N'
                  and circ.FLG_ANNULLATO = 'N'
                  and cin.flg_annullato = 'N'
                  and ca.flg_annullato = 'N'
                  and atr.flg_annullato = 'N'
                  and ca.id_circuito = circ.ID_CIRCUITO
                  and ca.id_atrio = atr.id_atrio
                  and atr.id_cinema = cin.id_cinema
                  and av.id_atrio_vendita = com.ID_ATRIO_VENDITA
                  and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  and ca.ID_CIRCUITO_ATRIO = av.id_circuito_atrio
                  and com.flg_annullato = 'N'
                  and com.flg_sospeso = 'N'
                  and com.COD_DISATTIVAZIONE IS NULL
                  )
        union
        (select distinct
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
                circ.ID_CIRCUITO as idCircuito,
                circ.NOME_CIRCUITO as nomeCircuito,
                pa.STATO_DI_VENDITA as codStato,
                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                (select pp.desc_prodotto from cd_prodotto_pubb pp
                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB) as tipoPubb,
                (select mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                cin.id_cinema as idCinema,
                --cin.nome_cinema as nomeCinema,
                pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,pa.data_fine) as nomeCinema,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as comuneCinema,
                (select abbr from cd_provincia prov, cd_comune comune
                        where comune.id_comune = cin.id_comune
                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
                fu_get_sala_isp(pa.id_prodotto_acquistato) as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
                0 as numProiezioni,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                0 as posizione
                from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                    cd_circuito circ, cd_cinema cin, cd_circuito_sala cs, cd_sala sa,cd_comunicato com, cd_sala_vendita sv
                where pa.ID_PIANO = p_id_piano
                  and pa.ID_VER_PIANO = p_id_ver_piano
                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                  and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                  and circ.ID_CIRCUITO = pv.ID_CIRCUITO
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and pv.FLG_ANNULLATO = 'N'
                  and circ.FLG_ANNULLATO = 'N'
                  and cin.flg_annullato = 'N'
                  and cs.FLG_ANNULLATO = 'N'
                  and sa.flg_annullato = 'N'
                  and cs.id_circuito = circ.ID_CIRCUITO
                  and cs.id_sala = sa.id_sala
                  and sa.id_cinema = cin.id_cinema
                  and sv.id_sala_vendita = com.ID_sala_VENDITA
                  and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  and cs.ID_CIRCUITO_SALA = sv.id_circuito_sala
                  and com.flg_annullato = 'N'
                  and com.flg_sospeso = 'N'
                  and com.COD_DISATTIVAZIONE IS NULL
                  )
            order by idCircuito, tipoPubb, modalitaVendita, formato, idSoggettoPiano, nomeCinema;
--
      RETURN c_dati;
      -- SPEZIA, 1.12.2009 quella che segue dovrebbe essere la query corretta, sostituire
--      OPEN c_dati FOR
--            select distinct
--                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
--                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
--                (select distinct sp.descrizione from cd_soggetto_di_piano sp
--                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
--                circ.ID_CIRCUITO as idCircuito,
--                circ.NOME_CIRCUITO as nomeCircuito,
--                pa.STATO_DI_VENDITA as codStato,
--                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
--                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
--                (select pp.desc_prodotto from cd_prodotto_pubb pp, cd_prodotto_vendita pv
--                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB
--                    and pv.id_prodotto_vendita = pa.id_prodotto_vendita) as tipoPubb,
--                (select mv.desc_mod_vendita from cd_modalita_vendita mv, cd_prodotto_vendita pv
--                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA
--                    and pv.id_prodotto_vendita = pa.id_prodotto_vendita) as modalitaVendita,
--                cin.id_cinema as idCinema,
--                cin.nome_cinema as nomeCinema,
--                (select comune.comune from cd_comune comune
--                        where comune.id_comune = cin.id_comune) as comuneCinema,
--                (select abbr from cd_provincia prov, cd_comune comune
--                        where comune.id_comune = cin.id_comune
--                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
--                '' as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
--                0 as numProiezioni,
--                (select fa.descrizione from cd_formato_acquistabile fa
--                    where fa.id_formato = pa.id_formato) as formato,
--                0 as posizione
--                from CD_PRODOTTO_ACQUISTATO pa, CD_COMUNICATO c, cd_circuito circ,
--                     cd_cinema_vendita cven, cd_circuito_cinema cc, cd_cinema cin
--                where pa.ID_PIANO = p_id_piano
--                  and pa.ID_VER_PIANO = p_id_ver_piano
--                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--                  and pa.flg_annullato = 'N'
--                  and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--                  and c.data_erogazione_prev >= nvl(p_data_inizio, c.data_erogazione_prev)
--                  and c.data_erogazione_prev <= nvl(p_data_fine, c.data_erogazione_prev)
--                  and c.id_cinema_vendita = cven.id_cinema_vendita
--                  and cc.id_circuito_cinema = cven.ID_CIRCUITO_CINEMA
--                  and cc.id_cinema = cin.id_cinema
--                  and circ.id_circuito = cc.id_circuito
--        union
--        (select distinct
--                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
--                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
--                (select distinct sp.descrizione from cd_soggetto_di_piano sp
--                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
--                circ.ID_CIRCUITO as idCircuito,
--                circ.NOME_CIRCUITO as nomeCircuito,
--                pa.STATO_DI_VENDITA as codStato,
--                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
--                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
--                (select pp.desc_prodotto from cd_prodotto_pubb pp, cd_prodotto_vendita pv
--                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB
--                    and pv.id_prodotto_vendita = pa.id_prodotto_vendita) as tipoPubb,
--                (select mv.desc_mod_vendita from cd_modalita_vendita mv, cd_prodotto_vendita pv
--                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA
--                    and pv.id_prodotto_vendita = pa.id_prodotto_vendita) as modalitaVendita,
--                cin.id_cinema as idCinema,
--                cin.nome_cinema as nomeCinema,
--                (select comune.comune from cd_comune comune
--                        where comune.id_comune = cin.id_comune) as comuneCinema,
--                (select abbr from cd_provincia prov, cd_comune comune
--                        where comune.id_comune = cin.id_comune
--                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
--                '' as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
--                0 as numProiezioni,
--                (select fa.descrizione from cd_formato_acquistabile fa
--                    where fa.id_formato = pa.id_formato) as formato,
--                0 as posizione
--                from CD_PRODOTTO_ACQUISTATO pa, CD_COMUNICATO c, cd_circuito circ,
--                    cd_atrio_vendita av, cd_cinema cin, cd_circuito_atrio ca, cd_atrio atr
--                where pa.ID_PIANO = p_id_piano
--                  and pa.ID_VER_PIANO = p_id_ver_piano
--                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--                  and pa.flg_annullato = 'N'
--                  and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--                  and c.data_erogazione_prev >= nvl(p_data_inizio, c.data_erogazione_prev)
--                  and c.data_erogazione_prev <= nvl(p_data_fine, c.data_erogazione_prev)
--                  and c.id_atrio_vendita = av.id_atrio_vendita
--                  and ca.id_circuito_atrio = av.ID_CIRCUITO_ATRIO
--                  and ca.id_atrio = atr.id_atrio
--                  and atr.id_cinema = cin.id_cinema
--                  and circ.id_circuito = ca.id_circuito)
--        union
--        (select distinct
--                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
--                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
--                (select distinct sp.descrizione from cd_soggetto_di_piano sp
--                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
--                circ.ID_CIRCUITO as idCircuito,
--                circ.NOME_CIRCUITO as nomeCircuito,
--                pa.STATO_DI_VENDITA as codStato,
--                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
--                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
--                (select pp.desc_prodotto from cd_prodotto_pubb pp, cd_prodotto_vendita pv
--                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB
--                    and pv.id_prodotto_vendita = pa.id_prodotto_vendita) as tipoPubb,
--                (select mv.desc_mod_vendita from cd_modalita_vendita mv, cd_prodotto_vendita pv
--                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA
--                    and pv.id_prodotto_vendita = pa.id_prodotto_vendita) as modalitaVendita,
--                cin.id_cinema as idCinema,
--                cin.nome_cinema as nomeCinema,
--                (select comune.comune from cd_comune comune
--                        where comune.id_comune = cin.id_comune) as comuneCinema,
--                (select abbr from cd_provincia prov, cd_comune comune
--                        where comune.id_comune = cin.id_comune
--                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
--                '' as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
--                0 as numProiezioni,
--                (select fa.descrizione from cd_formato_acquistabile fa
--                    where fa.id_formato = pa.id_formato) as formato,
--                0 as posizione
--                from CD_PRODOTTO_ACQUISTATO pa, CD_COMUNICATO c, cd_circuito circ,
--                    cd_sala_vendita sv, cd_cinema cin, cd_circuito_sala cs, cd_sala sa
--                where pa.ID_PIANO = p_id_piano
--                  and pa.ID_VER_PIANO = p_id_ver_piano
--                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--                  and pa.flg_annullato = 'N'
--                  and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--                  and c.data_erogazione_prev >= nvl(p_data_inizio, c.data_erogazione_prev)
--                  and c.data_erogazione_prev <= nvl(p_data_fine, c.data_erogazione_prev)
--                  and c.id_sala_vendita = sv.id_sala_vendita
--                  and cs.id_circuito_sala = sv.ID_CIRCUITO_SALA
--                  and cs.id_sala = sa.id_sala
--                  and sa.id_cinema = cin.id_cinema
--                  and circ.id_circuito = cs.id_circuito)
--            order by idSoggettoPiano, idCircuito, tipoPubb, modalitaVendita, nomeCinema, formato;
--      RETURN c_dati;
      -- fine Spezia 1.12.2009
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dettaglio_calendario_isp in errore: '
                             || SQLERRM
                            );
   END fu_dettaglio_calendario_isp;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_get_circuiti_e_date
--
-- DESCRIZIONE:  Estrae le informazioni relative ai circuiti (con le date di proiezione
--                               associate) collegati a un determinato piano; si usa per la stampa calendario
--                               nel caso si tratti di un piano tabellare
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati cercati
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_get_circuiti_e_date (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_CIRCUITO_E_DATE
   AS
--
      c_dati  C_CIRCUITO_E_DATE;
--
   BEGIN
      OPEN c_dati FOR
         select distinct
            pa.id_prodotto_acquistato as idProdottoAcquistato,
            pv.ID_CIRCUITO as idCircuito,
            pa.DATA_INIZIO as dataInizio,
            pa.DATA_FINE as dataFine
            from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv
                  where pa.ID_PIANO = p_id_piano
                  and pa.ID_VER_PIANO = p_id_ver_piano
                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                  and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and pv.FLG_ANNULLATO = 'N'
                  order by pa.DATA_INIZIO, pa.DATA_FINE, pv.ID_CIRCUITO;
                -- order by pv.ID_CIRCUITO, pa.DATA_INIZIO, pa.DATA_FINE;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_get_circuiti_e_date in errore: '
                             || SQLERRM
                            );
   END fu_get_circuiti_e_date;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_get_cal_dett_pa_pv
--
-- DESCRIZIONE:  Estrae le informazioni relative al prodotto acquistato e al prodotto di
--                               vendita collegati a un determinato piano; si usa per la stampa calendario
--                               nel caso si tratti di un piano tabellare
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati cercati
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_get_cal_dett_pa_pv (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_CAL_PA_PV
   AS
--
      c_dati   C_DETTAGLIO_CAL_PA_PV;
--
   BEGIN
    OPEN c_dati FOR
        select idprodacquistato,idSoggettoPiano, descSoggettoPiano, idCircuito, codStato, descStato,
                tipoPubb, modalitaVendita, periodoProiezDal, periodoProiezAl, formato, posizione
                from
            (
            select distinct
                        (select sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
                            where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
                         (select sp.descrizione from cd_soggetto_di_piano sp
                            where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
                         pv.ID_CIRCUITO as idCircuito,
                         pa.STATO_DI_VENDITA as codStato,
                        (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                                       where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                         (SELECT tb.desc_tipo_break from cd_tipo_break tb
                                       where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoPubb,
                         (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                                      where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                         pa.ID_PRODOTTO_ACQUISTATO as IDPRODACQUISTATO,
                         pa.DATA_INIZIO as periodoProiezDal,
                         pa.DATA_FINE as periodoProiezAl,
                         PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
                         0 as posizione
                            from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv, cd_comunicato c
                            where pa.ID_PIANO = p_id_piano
                                and pa.ID_VER_PIANO = p_id_ver_piano
                                AND PA.ID_PRODOTTO_ACQUISTATO NOT IN
                                (
                                select idProdAcquistato from
                                    (select count(distinct c1.id_soggetto_di_piano) as numSoggetti,
                                                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                                    from cd_comunicato c1, CD_PRODOTTO_ACQUISTATO pa
                                    where pa.ID_PIANO = p_id_piano
                                    and pa.ID_VER_PIANO = p_id_ver_piano
                                    and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                                    and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                                    and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                                    and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                                    and c1.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                                    and pa.flg_annullato = 'N'
                                    and pa.flg_sospeso = 'N'
                                    and pa.COD_DISATTIVAZIONE IS NULL
                                    and c1.FLG_ANNULLATO = 'N'
                                    and c1.FLG_SOSPESO = 'N'
                                    and c1.COD_DISATTIVAZIONE IS NULL
                                    group by pa.ID_PRODOTTO_ACQUISTATO
                                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                                    where conta.numSoggetti > 1
                                )
                                and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                                and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                                and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                                and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                                and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                                and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                                and pa.flg_annullato = 'N'
                                and pa.flg_sospeso = 'N'
                                and pa.COD_DISATTIVAZIONE IS NULL
                                and c.FLG_ANNULLATO = 'N'
                                and c.FLG_SOSPESO = 'N'
                                and c.COD_DISATTIVAZIONE IS NULL
                                and pv.FLG_ANNULLATO = 'N'
            )
            UNION
            (
                select pa.ID_PRODOTTO_ACQUISTATO as idprodacquistato,-pa.ID_PRODOTTO_ACQUISTATO as idSoggettoPiano, '*' as descSoggettoPiano,
                pv.ID_CIRCUITO as idCircuito,
                         pa.STATO_DI_VENDITA as codStato,
                        (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                                       where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                         (SELECT tb.desc_tipo_break from cd_tipo_break tb
                                       where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoPubb,
                         (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                                      where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                         pa.DATA_INIZIO as periodoProiezDal,
                         pa.DATA_FINE as periodoProiezAl,
                         PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
                         0 as posizione
                            from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv, cd_comunicato c
                            where pa.ID_PIANO = p_id_piano
                                and pa.ID_VER_PIANO = p_id_ver_piano
                                AND PA.ID_PRODOTTO_ACQUISTATO IN
                                (
                                select idProdAcquistato from
                                    (select count(distinct c1.id_soggetto_di_piano) as numSoggetti,
                                                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
                                    from cd_comunicato c1, CD_PRODOTTO_ACQUISTATO pa
                                    where pa.ID_PIANO = p_id_piano
                                    and pa.ID_VER_PIANO = p_id_ver_piano
                                    and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                                    and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                                    and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                                    and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                                    and c1.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                                    and pa.flg_annullato = 'N'
                                    and pa.flg_sospeso = 'N'
                                    and pa.COD_DISATTIVAZIONE IS NULL
                                    and c1.FLG_ANNULLATO = 'N'
                                    and c1.FLG_SOSPESO = 'N'
                                    and c1.COD_DISATTIVAZIONE IS NULL
                                    group by pa.ID_PRODOTTO_ACQUISTATO
                                    order by pa.ID_PRODOTTO_ACQUISTATO) conta
                                    where conta.numSoggetti > 1
                                )
                                and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                                and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                                and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                                and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                                and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                                and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                                and pa.flg_annullato = 'N'
                                and pa.flg_sospeso = 'N'
                                and pa.COD_DISATTIVAZIONE IS NULL
                                and c.FLG_ANNULLATO = 'N'
                                and c.FLG_SOSPESO = 'N'
                                and c.COD_DISATTIVAZIONE IS NULL
                                and pv.FLG_ANNULLATO = 'N'
            )
                                order by periodoProiezDal, periodoProiezAl, idCircuito, tipoPubb, modalitaVendita, formato, idSoggettoPiano;
    RETURN c_dati;
--      OPEN c_dati FOR
--         select distinct
--            (select sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
--                where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
--             (select sp.descrizione from cd_soggetto_di_piano sp
--                where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
--             pv.ID_CIRCUITO as idCircuito,
--             pa.STATO_DI_VENDITA as codStato,
--            (select sv.DESCRIZIONE from cd_stato_di_vendita sv
--                           where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
--             (SELECT tb.desc_tipo_break from cd_tipo_break tb
--                           where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoPubb,
--             (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
--                          where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
--             pa.DATA_INIZIO as periodoProiezDal,
--             pa.DATA_FINE as periodoProiezAl,
--             PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
--             0 as posizione
--                from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv, cd_comunicato c
--                where pa.ID_PIANO = p_id_piano
--                    and pa.ID_VER_PIANO = p_id_ver_piano
--                    and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--                    and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--                    and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--                    and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--                    and pv.id_prodotto_vendita = pa.id_prodotto_vendita
--                    and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--                    and pa.flg_annullato = 'N'
--                    order by periodoProiezDal, periodoProiezAl, idCircuito, tipoPubb, modalitaVendita, formato, idSoggettoPiano;
--                  --order by idSoggettoPiano, idCircuito, tipoPubb, modalitaVendita, periodoProiezDal, periodoProiezAl, formato;
----
--      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_get_cal_dett_pa_pv in errore: '
                             || SQLERRM
                            );
   END fu_get_cal_dett_pa_pv;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_get_cal_dett_cine
--
-- DESCRIZIONE:  Estrae le informazioni relative al cinema e alla sala (con numero di
--                               proeizioni) collegati a un determinato piano; si usa per la stampa calendario
--                               nel caso si tratti di un piano tabellare
--
-- INPUT:
--      p_id_circuito
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati cercati
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE: Michele Borgogno, Altran, Novembre 2009
--             Mauro Viel, Altran Settembre 2010 eliminate le sale virtuali
--             Mauro Viel, Altran Dicembre 2010 inserita gestione nome_cinama.
--             Mauro Viel, Altran Luglio   2011 inserito il parametro p_id_prodotto_acquistato necessario per gestire 
--                                         due prodotti per lo stesso circuito nello stesso periodo. Necessita avuta per sedui il film
--                                         3D - 2D
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_get_cal_dett_cine (
        p_id_prototto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
   --     p_id_circuito       cd_circuito.id_circuito%TYPE,
        p_id_piano           CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
        p_id_ver_piano       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
        p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
        p_id_raggruppamento  CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
        p_stato_di_vendita   CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
        p_data_inizio        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_CAL_CINEMA
   AS
--
      c_dati  C_DETTAGLIO_CAL_CINEMA;
--
   BEGIN
      OPEN c_dati FOR
--         select distinct  cir.id_circuito as idCircuito, cir.nome_circuito as nomeCircuito,
--                cinema.id_cinema as idCinema, cinema.nome_cinema as nomeCinema,
--                comune.comune as comuneCinema, prov.abbr as provinciaCinema,
--                sala.nome_sala as nomeSala,
--                (select count (id_proiezione) from cd_proiezione, cd_schermo  sch2
--                    where sch2.ID_SALA = sala.ID_SALA
--                    and cd_proiezione.id_schermo = sch2.id_schermo
--                    and cd_proiezione.DATA_PROIEZIONE >= p_data_inizio
--                    and cd_proiezione.DATA_PROIEZIONE <= p_data_fine) as numProiezioni
--            from cd_circuito cir, cd_circuito_schermo cir_sch, cd_schermo  sch,
--                cd_sala  sala, cd_cinema cinema, cd_comune comune, cd_provincia prov
--            where cir.ID_CIRCUITO = p_id_circuito
--            and   cir.ID_CIRCUITO = cir_sch.ID_CIRCUITO
--            and   sch.id_schermo=cir_sch.ID_SCHERMO
--            and   sch.ID_SALA = sala.ID_SALA
--            and   sala.ID_CINEMA = cinema.ID_CINEMA
--            and   cinema.ID_COMUNE = comune.ID_COMUNE
--            and   comune.ID_PROVINCIA = prov.ID_PROVINCIA
--            order by cir.id_circuito, cinema.nome_cinema, comune.comune, sala.nome_sala;

         select distinct id_prodotto_acquistato, schermo.id_circuito as idCircuito, nome_circuito as nomeCircuito,
                cin.id_cinema as idCinema, pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,p_data_fine) as nomeCinema,
                --cin.nome_cinema as nomeCinema,
                comune.comune as comuneCinema, prov.abbr as provinciaCinema,
                sa.id_sala as idSala,
                sa.nome_sala as nomeSala,
                -1 as numProiezioni
                /*,
                (select count (id_proiezione) from cd_proiezione, cd_schermo  sch2
                    where sch2.ID_SALA = sa.ID_SALA
                    and cd_proiezione.id_schermo = sch2.id_schermo
                    and cd_proiezione.DATA_PROIEZIONE >= p_data_inizio
                    and cd_proiezione.DATA_PROIEZIONE <= p_data_fine) as numProiezioni */
                from
                    cd_cinema cin,
                    cd_sala sa,
                    cd_comune comune,
                    cd_provincia prov,
                    (select
                    pa.id_prodotto_acquistato,
                    sch.id_sala,
                    cir.id_circuito,
                    cir.nome_circuito--,
                    --count(distinct pr.id_proiezione) as numProiezioni
                     from
                       cd_schermo sch,
                       cd_proiezione pr,
                       cd_break br,
                       cd_circuito_break cir_br,
                       cd_circuito cir,
                       cd_break_vendita  brv,
                       cd_comunicato c,
                       cd_prodotto_acquistato pa
                       where pa.id_piano = p_id_piano
                      and pa.id_ver_piano = p_id_ver_piano
                      and  pa.ID_PRODOTTO_ACQUISTATO = p_id_prototto_acquistato
                      and (p_id_raggruppamento is null or pa.id_raggruppamento = p_id_raggruppamento)
                      and (p_stato_di_vendita = '-1' or pa.stato_di_vendita = p_stato_di_vendita)
                      and cir.id_circuito = p_id_circuito
                     -- and (length(trim(p_stato_di_vendita)||'*') =1 or pa.stato_di_vendita = p_stato_di_vendita)
                    --  and (length(trim(p_id_raggruppamento)||'*') =1  or pa.id_raggruppamento = p_id_raggruppamento)
                      and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                      and (p_data_inizio IS NULL OR c.data_erogazione_prev >= p_data_inizio)
                      and (p_data_fine IS NULL OR c.data_erogazione_prev <= p_data_fine)
                      and (p_data_inizio IS NULL OR pr.DATA_PROIEZIONE >= p_data_inizio)
                      and (p_data_fine IS NULL OR pr.DATA_PROIEZIONE <= p_data_fine)
                      and c.id_break_vendita = brv.id_break_vendita
                      and brv.id_circuito_break = cir_br.id_circuito_break
                      and br.id_break = cir_br.id_break
                      and cir.id_circuito = cir_br.id_circuito
                      and pr.id_proiezione = br.id_proiezione
                      and sch.id_schermo = pr.id_schermo
                      and br.flg_annullato = 'N'
                      and pr.flg_annullato = 'N'
                      and sch.flg_annullato = 'N'
                      and brv.flg_annullato = 'N'
                      and pa.flg_annullato = 'N'
                      and pa.FLG_SOSPESO = 'N'
                      and pa.COD_DISATTIVAZIONE IS NULL
                      and c.flg_annullato = 'N'
                      and c.FLG_SOSPESO = 'N'
                      and c.COD_DISATTIVAZIONE IS NULL
                      and cir_br.flg_annullato = 'N'
                      and cir.flg_annullato = 'N'
                      --group by
                      --sch.id_sala,
                      --cir.id_circuito,
                      --cir.nome_circuito
                      ) schermo
                  where schermo.ID_SALA = sa.ID_SALA
                  and sa.ID_CINEMA = cin.ID_CINEMA
                  and comune.id_comune = cin.id_comune
                  and prov.id_provincia = comune.id_provincia
                  and cin.flg_annullato = 'N'
                  and cin.flg_virtuale = 'N'
                  and sa.flg_annullato = 'N'
                  --order by nome_cinema, comune.comune, sa.nome_sala;
                  order by pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,p_data_fine), comune.comune, sa.nome_sala;
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_get_cal_dett_cine in errore: '
                             || SQLERRM
                            );
   END fu_get_cal_dett_cine;
   
   
   
   
   -----------------------------------------------------------------------------------------------------------------
   --
-----------------------------------------------------------------------------------------------------
-- Funzione fu_get_cal_dett_cine_xls
--
-- DESCRIZIONE:  Estrae le informazioni relative al cinema e alla sala (con numero di
--                               proeizioni) collegati a un determinato piano; si usa per la stampa calendario
--                               nel caso si tratti di un piano tabellare
--
-- INPUT:
--      p_id_circuito
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati cercati
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE: Michele Borgogno, Altran, Novembre 2009
--             Mauro Viel, Altran Settembre 2010 eliminate le sale virtuali
--             Mauro Viel, Altran Dicembre 2010 inserita gestione nome_cinama.
--             Mauro Viel, Altran Febbraio 2010 duplicata la procedura per la stampa xls
--             Mauro Viel, Altran Luglio   2011 inserito il parametro p_id_prodotto_acquistato necessario per gestire 
--                                         due prodotti per lo stesso circuito nello stesso periodo. Necessita avuta per sedui il film
--                                         3D - 2D
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_get_cal_dett_cine_xls (
   --     p_id_circuito       cd_circuito.id_circuito%TYPE,
        p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, 
        p_id_piano           CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
        p_id_ver_piano       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
        p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
        p_id_raggruppamento  CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
        p_stato_di_vendita   CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
        p_data_inizio        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_CAL_CINEMA_XLS
   AS
--
      c_dati  C_DETTAGLIO_CAL_CINEMA_XLS;
--
   BEGIN
      OPEN c_dati FOR
--         select distinct  cir.id_circuito as idCircuito, cir.nome_circuito as nomeCircuito,
--                cinema.id_cinema as idCinema, cinema.nome_cinema as nomeCinema,
--                comune.comune as comuneCinema, prov.abbr as provinciaCinema,
--                sala.nome_sala as nomeSala,
--                (select count (id_proiezione) from cd_proiezione, cd_schermo  sch2
--                    where sch2.ID_SALA = sala.ID_SALA
--                    and cd_proiezione.id_schermo = sch2.id_schermo
--                    and cd_proiezione.DATA_PROIEZIONE >= p_data_inizio
--                    and cd_proiezione.DATA_PROIEZIONE <= p_data_fine) as numProiezioni
--            from cd_circuito cir, cd_circuito_schermo cir_sch, cd_schermo  sch,
--                cd_sala  sala, cd_cinema cinema, cd_comune comune, cd_provincia prov
--            where cir.ID_CIRCUITO = p_id_circuito
--            and   cir.ID_CIRCUITO = cir_sch.ID_CIRCUITO
--            and   sch.id_schermo=cir_sch.ID_SCHERMO
--            and   sch.ID_SALA = sala.ID_SALA
--            and   sala.ID_CINEMA = cinema.ID_CINEMA
--            and   cinema.ID_COMUNE = comune.ID_COMUNE
--            and   comune.ID_PROVINCIA = prov.ID_PROVINCIA
--            order by cir.id_circuito, cinema.nome_cinema, comune.comune, sala.nome_sala;

         select distinct id_prodotto_acquistato,schermo.id_circuito as idCircuito, nome_circuito as nomeCircuito,
                cin.id_cinema as idCinema, pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,p_data_fine) as nomeCinema,
                --cin.nome_cinema as nomeCinema,
                comune.comune as comuneCinema, prov.provincia as provinciaCinema,
                reg.nome_regione as regioneCinema, 
                sa.id_sala as idSala,
                sa.nome_sala as nomeSala,
                -1 as numProiezioni
                /*,
                (select count (id_proiezione) from cd_proiezione, cd_schermo  sch2
                    where sch2.ID_SALA = sa.ID_SALA
                    and cd_proiezione.id_schermo = sch2.id_schermo
                    and cd_proiezione.DATA_PROIEZIONE >= p_data_inizio
                    and cd_proiezione.DATA_PROIEZIONE <= p_data_fine) as numProiezioni */
                from
                    cd_cinema cin,
                    cd_sala sa,
                    cd_comune comune,
                    cd_provincia prov,
                    cd_regione reg,
                    (select
                    pa.id_prodotto_acquistato,
                    sch.id_sala,
                    cir.id_circuito,
                    cir.nome_circuito--,
                    --count(distinct pr.id_proiezione) as numProiezioni
                     from
                       cd_schermo sch,
                       cd_proiezione pr,
                       cd_break br,
                       cd_circuito_break cir_br,
                       cd_circuito cir,
                       cd_break_vendita  brv,
                       cd_comunicato c,
                       cd_prodotto_acquistato pa
                      where pa.id_prodotto_Acquistato = p_id_prodotto_acquistato 
                      and pa.id_piano = p_id_piano
                      and pa.id_ver_piano = p_id_ver_piano
                      and (p_id_raggruppamento is null or pa.id_raggruppamento = p_id_raggruppamento)
                      and (p_stato_di_vendita = '-1' or pa.stato_di_vendita = p_stato_di_vendita)
                      and cir.id_circuito = p_id_circuito
                     -- and (length(trim(p_stato_di_vendita)||'*') =1 or pa.stato_di_vendita = p_stato_di_vendita)
                    --  and (length(trim(p_id_raggruppamento)||'*') =1  or pa.id_raggruppamento = p_id_raggruppamento)
                      and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                      and (p_data_inizio IS NULL OR c.data_erogazione_prev >= p_data_inizio)
                      and (p_data_fine IS NULL OR c.data_erogazione_prev <= p_data_fine)
                      and (p_data_inizio IS NULL OR pr.DATA_PROIEZIONE >= p_data_inizio)
                      and (p_data_fine IS NULL OR pr.DATA_PROIEZIONE <= p_data_fine)
                      and c.id_break_vendita = brv.id_break_vendita
                      and brv.id_circuito_break = cir_br.id_circuito_break
                      and br.id_break = cir_br.id_break
                      and cir.id_circuito = cir_br.id_circuito
                      and pr.id_proiezione = br.id_proiezione
                      and sch.id_schermo = pr.id_schermo
                      and br.flg_annullato = 'N'
                      and pr.flg_annullato = 'N'
                      and sch.flg_annullato = 'N'
                      and brv.flg_annullato = 'N'
                      and pa.flg_annullato = 'N'
                      and pa.FLG_SOSPESO = 'N'
                      and pa.COD_DISATTIVAZIONE IS NULL
                      and c.flg_annullato = 'N'
                      and c.FLG_SOSPESO = 'N'
                      and c.COD_DISATTIVAZIONE IS NULL
                      and cir_br.flg_annullato = 'N'
                      and cir.flg_annullato = 'N'
                      --group by
                      --sch.id_sala,
                      --cir.id_circuito,
                      --cir.nome_circuito
                      ) schermo
                  where schermo.ID_SALA = sa.ID_SALA
                  and sa.ID_CINEMA = cin.ID_CINEMA
                  and comune.id_comune = cin.id_comune
                  and prov.id_provincia = comune.id_provincia
                  and prov.ID_REGIONE = reg.ID_REGIONE
                  and cin.flg_annullato = 'N'
                  and cin.flg_virtuale = 'N'
                  and sa.flg_annullato = 'N'
                  --order by nome_cinema, comune.comune, sa.nome_sala;
                  order by pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,p_data_fine), comune.comune, sa.nome_sala;
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_get_cal_dett_cine_xls in errore: '
                             || SQLERRM
                            );
   END fu_get_cal_dett_cine_xls;
   
   
   -----------------------------------------------------------------------------------------------------------------
   
   
   
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dati_prod_rich
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati correlati
-- al piano stesso (area, sede, cliente) e dei prodotti richiesti
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resulset contenente i dati del piano, i dati dei periodi e gli importi
--
-- REALIZZATORE: Daniela Spezia, Altran , Novembre 2009
--
--  MODIFICHE:Mauro Viel Altran 14/06/2011 inserita la chiamata 
--             fu_get_numero_proiezioni(null,pr.id_prodotti_richiesti) as numProiezioni
--             al fine di differenziare le proiezioni fra dale e arene. 
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dati_prod_rich (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_PROD_RICHIESTI_IMPORTI
   AS
--
      c_ric   C_PROD_RICHIESTI_IMPORTI;
--
   BEGIN
      OPEN c_ric FOR
         select pr.ID_PIANO as idPiano, pr.ID_VER_PIANO as idVersionePiano,
                pr.ID_PRODOTTI_RICHIESTI as prodottoRichiestoId,
                FU_GET_FORMATO_PROD_RIC(pr.id_prodotti_richiesti) as formatoTab,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pr.id_formato) as formatoIsp,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                (SELECT tb.desc_tipo_break from cd_tipo_break tb
                    where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoFilmato,
                (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                (select pb.DESC_PRODOTTO from CD_PRODOTTO_PUBB pb
                    where pb.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB) as descProdotto,
                pr.data_inizio as dataInizio, pr.data_fine as dataFine,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pr.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                /*(select count (distinct id_schermo) from cd_circuito_schermo cs
                    where cs.id_circuito = pv.ID_CIRCUITO
                    and cs.flg_annullato = 'N') as numSchermi,*/ PA_CD_PRODOTTO_RICHIESTO.FU_GET_NUM_AMBIENTI(pr.id_prodotti_richiesti) as numSchermi,
                /*(select count (distinct id_schermo) * V_FATTORE_MOLT_PROIEZ_ATTESE * (pr.data_fine - pr.data_inizio + 1)
                    from cd_circuito_schermo cs
                    where cs.id_circuito = pv.ID_CIRCUITO
                    and cs.flg_annullato = 'N') as numProiezioni, -- al momento resituisco sempre 4 proiez al giorno per ogni schermo!*/
                fu_get_numero_proiezioni(null,pr.id_prodotti_richiesti) as numProiezioni, --(PA_CD_PRODOTTO_RICHIESTO.FU_GET_NUM_AMBIENTI(pr.id_prodotti_richiesti) * V_FATTORE_MOLT_PROIEZ_ATTESE * (pr.data_fine - pr.data_inizio + 1)) as numProiezioni, -- al momento resituisco sempre 4 proiez al giorno per ogni schermo!
                pr.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pr.imp_tariffa, 0) as tariffa, ROUND(pr.imp_maggiorazione, 0) as maggiorazione,
                ROUND(pr.imp_lordo, 0) as lordo, ROUND(pr.imp_netto, 0) as netto,
                TRUNC(ipc.IMP_NETTO, 3) as nettoComm, TRUNC(ipd.IMP_NETTO, 3) as nettoDir,
                ROUND(ipc.IMP_SC_COMM, 0) as scontoComm, ROUND(ipd.IMP_SC_COMM, 0) as scontoDir,
                TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipc.imp_netto, ipc.imp_sc_comm),0), 3) as percScontoComm,
                TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto, ipd.imp_sc_comm),0), 3) as percScontoDir
        from cd_prodotti_richiesti pr, cd_importi_prodotto ipc, cd_importi_prodotto ipd,
            cd_pianificazione pian, CD_PRODOTTO_VENDITA pv
        where pr.flg_annullato = 'N'
        and pr.FLG_SOSPESO = 'N'
        and pr.id_piano = p_id_piano and pr.id_ver_piano = p_id_ver_piano
        and pian.id_piano = pr.id_piano and pian.id_ver_piano = pr.id_ver_piano
        and pian.FLG_ANNULLATO = 'N'
        and pian.FLG_SOSPESO = 'N'
        and pv.FLG_ANNULLATO = 'N'
        and pv.ID_PRODOTTO_VENDITA = pr.ID_PRODOTTO_VENDITA
        and ipc.id_prodotti_richiesti = pr.id_prodotti_richiesti
        and ipc.TIPO_CONTRATTO = 'C'
        and ipd.id_prodotti_richiesti = pr.id_prodotti_richiesti
        and ipd.TIPO_CONTRATTO = 'D'
        order by pr.data_inizio, pr.data_fine;
--
      RETURN c_ric;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dati_prod_rich in errore: '
                             || SQLERRM
                            );
   END fu_dati_prod_rich;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_tot_prod_rich
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali correlati
-- ai prodotti richiesti; i totali suddetti sono calcolati raggruppando i dati per data inizio-fine
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resultset contenente i dati del raggruppamento intermediari
--
-- REALIZZATORE: Daniela Spezia, Altran , Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_tot_prod_rich (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_TOTALI_PROD_RICH
   AS
--
      c_tot   C_TOTALI_PROD_RICH;
--
   BEGIN
      OPEN c_tot FOR
         select
                base.dataInizio as dataInizio, base.dataFine as dataFine,
                ROUND(SUM(base.tariffa), 0) as totTariffa, ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 0) as totLordo, ROUND(SUM(base.netto), 0) as totNetto,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC, TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC, ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoComm),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoComm),0), NVL(SUM(base.scontoComm),0)),0) - NVL(SUM(base.nettoComm),0)), 3) as totPercScontoC,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoDir),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoDir),0), NVL(SUM(base.scontoDir),0)),0) - NVL(SUM(base.nettoDir),0)), 3) as totPercScontoD
             from
            (select pr.data_inizio as dataInizio, pr.data_fine as dataFine,
                    pr.imp_tariffa as tariffa, pr.imp_maggiorazione as maggiorazione,
                    pr.imp_lordo as lordo, pr.imp_netto as netto,
                    ipc.IMP_NETTO as nettoComm, ipd.IMP_NETTO as nettoDir,
                    ipc.IMP_SC_COMM as scontoComm, ipd.IMP_SC_COMM as scontoDir,
                    NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipc.imp_netto, ipc.imp_sc_comm),0) as percScontoComm,
                    NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto, ipd.imp_sc_comm),0) as percScontoDir
                from cd_prodotti_richiesti pr, cd_importi_prodotto ipc, cd_importi_prodotto ipd,
                    cd_pianificazione pian, cd_prodotto_vendita pv
                where pr.flg_annullato = 'N'
                and pr.FLG_SOSPESO = 'N'
                and pr.id_piano = p_id_piano and pr.id_ver_piano = p_id_ver_piano
                and pian.id_piano = pr.id_piano and pian.id_ver_piano = pr.id_ver_piano
                and pian.FLG_ANNULLATO = 'N'
                and pian.FLG_SOSPESO = 'N'
                and pv.FLG_ANNULLATO = 'N'
                and pv.ID_PRODOTTO_VENDITA = pr.ID_PRODOTTO_VENDITA
                and ipc.id_prodotti_richiesti = pr.id_prodotti_richiesti
                and ipc.TIPO_CONTRATTO = 'C'
                and ipd.id_prodotti_richiesti = pr.id_prodotti_richiesti
                and ipd.TIPO_CONTRATTO = 'D'
                order by pr.data_inizio, pr.data_fine) base
            group by base.dataInizio, base.dataFine;
--
      RETURN c_tot;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_tot_prod_rich in errore: '
                             || SQLERRM
                            );
   END fu_tot_prod_rich;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_tot_prod_rich_piano
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali correlati
-- ai prodotti richiesti; i totali suddetti sono calcolati per piano
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resultset contenente i dati del raggruppamento intermediari
--
-- REALIZZATORE: Daniela Spezia, Altran , Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_tot_prod_rich_piano (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE
   )
      RETURN C_TOTALI_PROD_RICH_PIANO
   AS
--
      c_tot   C_TOTALI_PROD_RICH_PIANO;
--
   BEGIN
      OPEN c_tot FOR
         select
                ROUND(SUM(base.tariffa), 0) as totTariffa, ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 0) as totLordo, ROUND(SUM(base.netto), 0) as totNetto,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC, TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC, ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoComm),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoComm),0), NVL(SUM(base.scontoComm),0)),0) - NVL(SUM(base.nettoComm),0)), 3) as totPercScontoC,
                TRUNC(PA_PC_IMPORTI.FU_PERC_SC_COMM(NVL(SUM(base.nettoDir),0), NVL(PA_PC_IMPORTI.fu_lordo_comm(NVL(SUM(base.nettoDir),0), NVL(SUM(base.scontoDir),0)),0) - NVL(SUM(base.nettoDir),0)), 3) as totPercScontoD
             from
            (select pr.imp_tariffa as tariffa, pr.imp_maggiorazione as maggiorazione,
                    pr.imp_lordo as lordo, pr.imp_netto as netto,
                    ipc.IMP_NETTO as nettoComm, ipd.IMP_NETTO as nettoDir,
                    ipc.IMP_SC_COMM as scontoComm, ipd.IMP_SC_COMM as scontoDir,
                    NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipc.imp_netto, ipc.imp_sc_comm),0) as percScontoComm,
                    NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto, ipd.imp_sc_comm),0) as percScontoDir
                from cd_prodotti_richiesti pr, cd_importi_prodotto ipc, cd_importi_prodotto ipd,
                    cd_pianificazione pian, cd_prodotto_vendita pv
                where pr.flg_annullato = 'N'
                and pr.FLG_SOSPESO = 'N'
                and pr.id_piano = p_id_piano and pr.id_ver_piano = p_id_ver_piano
                and pian.id_piano = pr.id_piano and pian.id_ver_piano = pr.id_ver_piano
                and pian.FLG_ANNULLATO = 'N'
                and pian.FLG_SOSPESO = 'N'
                and pv.FLG_ANNULLATO = 'N'
                and pv.ID_PRODOTTO_VENDITA = pr.ID_PRODOTTO_VENDITA
                and ipc.id_prodotti_richiesti = pr.id_prodotti_richiesti
                and ipc.TIPO_CONTRATTO = 'C'
                and ipd.id_prodotti_richiesti = pr.id_prodotti_richiesti
                and ipd.TIPO_CONTRATTO = 'D') base;
--
      RETURN c_tot;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_tot_prod_rich_piano in errore: '
                             || SQLERRM
                            );
   END fu_tot_prod_rich_piano;
--
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_proposta_tab_old
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati "di dettaglio"
-- del piano stesso; e possibile fornire ulteriori parametri corrispondenti a eventuali criteri di filtro
-- Questa function va usata nel caso di famiglia pubblicitaria TABELLARE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati di dettaglio per la stampa proposta
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dettaglio_proposta_tab_old (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_PROPOSTA
   AS
--
      c_dati   C_DETTAGLIO_PROPOSTA;
--
   BEGIN
   -- modifica del 30.11.2009
--      OPEN c_dati FOR
--      select idSoggettoPiano, descSoggettoPiano,idProdAcquistato,descProdottoAcquistato,
--      PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(idProdAcquistato) as numSchermi,
--      famigliaPubblicitaria,codFamigliaPubb,periodoVenditaDal,periodoVenditaAl,
--      estensioneTemporale,circuito,tipoFilmato,modalitaVendita,statoVendita,formato,
--      tariffaVariabile,tariffa,maggiorazione,lordo,nettoComm,nettoDir,scontoComm,scontoDir,
--      percScontoComm,percScontoDir,sanatoria,recupero
--      from (
--         select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
--                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
--               (select cp.descrizione from pc_categoria_prodotto cp
--                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
--                pp.cod_categoria_prodotto as codFamigliaPubb,
--                (select min(pa2.DATA_INIZIO) from CD_PRODOTTO_ACQUISTATO pa2
--                    where pa2.id_piano = pa.id_piano
--                    and pa2.id_ver_piano = pa.id_ver_piano
--                    group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaDal,
--                (select max(pa2.DATA_FINE) from CD_PRODOTTO_ACQUISTATO pa2
--                    where pa2.id_piano = pa.id_piano
--                    and pa2.id_ver_piano = pa.id_ver_piano
--                    group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaAl,
--                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
--                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
--                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
--                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
--                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
--                 (SELECT tb.desc_tipo_break from cd_tipo_break tb
--                    where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoFilmato,
--                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
--                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
--                pa.STATO_DI_VENDITA as statoVendita,
--                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
--                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
--                ROUND(pa.imp_tariffa, 0) as tariffa,
--                ROUND(pa.imp_maggiorazione, 0) as maggiorazione,
--                ROUND(pa.IMP_LORDO, 0) as lordo,
--                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'C') as nettoComm,
--                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'D') as nettoDir,
--                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'C') as scontoComm,
--                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'D') as scontoDir,
--                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
--                    from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
--                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
--                    from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
--                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
--            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
--                cd_prodotto_pubb pp, cd_comunicato c
--            where pa.ID_PIANO = p_id_piano
--            and pa.ID_VER_PIANO = p_id_ver_piano
--            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
--            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
--            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
--            and pa.flg_annullato = 'N')
--            order by idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato;
----
--      RETURN c_dati;
      OPEN c_dati FOR
          select idSoggettoPiano, descSoggettoPiano,idProdAcquistato,descProdottoAcquistato,
          PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(idProdAcquistato) as numSchermi,
          0 as numProiezioni,
          famigliaPubblicitaria,codFamigliaPubb,
          periodoVenditaDal, periodoVenditaAl,
          estensioneTemporale,circuito,tipoFilmato,modalitaVendita,statoVendita,formato,
          tariffaVariabile,tariffa,maggiorazione,lordo,nettoComm,nettoDir,scontoComm,scontoDir,
          percScontoComm,percScontoDir,sanatoria,recupero
          from (
         select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
               (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                (select min(pa2.DATA_INIZIO) from CD_PRODOTTO_ACQUISTATO pa2
                    where pa2.id_piano = pa.id_piano
                    and pa2.id_ver_piano = pa.id_ver_piano
                    group by c.ID_SOGGETTO_DI_PIANO) as periodoVendDal,
                (select max(pa2.DATA_FINE) from CD_PRODOTTO_ACQUISTATO pa2
                    where pa2.id_piano = pa.id_piano
                    and pa2.id_ver_piano = pa.id_ver_piano
                    group by c.ID_SOGGETTO_DI_PIANO) as periodoVendAl,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 (SELECT tb.desc_tipo_break from cd_tipo_break tb
                    where tb.id_tipo_break = pv.ID_TIPO_BREAK) as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                pa.STATO_DI_VENDITA as statoVendita,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as formato,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 0) as tariffa,
                ROUND(pa.imp_maggiorazione, 0) as maggiorazione,
                ROUND(pa.IMP_LORDO, 0) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL)
            order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dettaglio_proposta_tab_old in errore: '
                             || SQLERRM
                            );
   END fu_dettaglio_proposta_tab_old;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_proposta_isp_old
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati "di dettaglio"
-- del piano stesso; e possibile fornire ulteriori parametri corrispondenti a eventuali criteri di filtro
-- Questa function va usata nel caso di famiglia pubblicitaria INIZIATIVA SPECIALE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati di dettaglio per la stampa proposta
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dettaglio_proposta_isp_old (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_PROPOSTA
   AS
--
      c_dati   C_DETTAGLIO_PROPOSTA;
--
   BEGIN
   -- modifica del 30.11.2009
--      OPEN c_dati FOR
--         select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
--                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
--                (select cp.descrizione from pc_categoria_prodotto cp
--                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
--                pp.cod_categoria_prodotto as codFamigliaPubb,
--                (select min(pa2.DATA_INIZIO) from CD_PRODOTTO_ACQUISTATO pa2
--                    where pa2.id_piano = pa.id_piano
--                    and pa2.id_ver_piano = pa.id_ver_piano
--                    group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaDal,
--                (select max(pa2.DATA_FINE) from CD_PRODOTTO_ACQUISTATO pa2
--                    where pa2.id_piano = pa.id_piano
--                    and pa2.id_ver_piano = pa.id_ver_piano
--                    group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaAl,
--                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
--                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
--                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
--                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
--                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
--                 pp.desc_prodotto as tipoFilmato,
--                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
--                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
--                 --(SELECT sv.descrizione from cd_stato_di_vendita sv
--                --    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as statoVendita,
--                    pa.STATO_DI_VENDITA as statoVendita,
--                (select fa.descrizione from cd_formato_acquistabile fa
--                    where fa.id_formato = pa.id_formato) as formato,
--                    0 as numSchermi,
--                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
--                ROUND(pa.imp_tariffa, 0) as tariffa,
--                ROUND(pa.imp_maggiorazione, 0) as maggiorazione,
--                ROUND(pa.IMP_LORDO, 0) as lordo,
--                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'C') as nettoComm,
--                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'D') as nettoDir,
--                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'C') as scontoComm,
--                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'D') as scontoDir,
--                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
--                    from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
--                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
--                    from cd_importi_prodotto imp_prod
--                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
--                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
--            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
--                cd_prodotto_pubb pp, cd_comunicato c
--            where pa.ID_PIANO = p_id_piano
--            and pa.ID_VER_PIANO = p_id_ver_piano
--            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
--            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
--            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
--            and pa.flg_annullato = 'N'
--            order by idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato;
----
--      RETURN c_dati;
      OPEN c_dati FOR
         select distinct sp.id_soggetto_di_piano as idSoggettoPiano, sp.descrizione as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato, pp.desc_prodotto descProdottoAcquistato,
                (select cp.descrizione from pc_categoria_prodotto cp
                    where pp.cod_categoria_prodotto = cp.COD) as famigliaPubblicitaria,
                pp.cod_categoria_prodotto as codFamigliaPubb,
                pa.DATA_INIZIO as periodoVenditaDal,
                pa.DATA_FINE as periodoVenditaAl,
                (select umt.desc_unita from cd_misura_prd_vendita mpv, cd_unita_misura_temp umt
                    where mpv.id_misura_prd_ve = pa.ID_MISURA_PRD_VE
                    and umt.id_unita = mpv.id_unita) as estensioneTemporale,
                (SELECT circ.NOME_CIRCUITO from cd_circuito circ
                    where circ.ID_CIRCUITO = pv.ID_CIRCUITO) as circuito,
                 pp.desc_prodotto as tipoFilmato,
                 (SELECT mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                 --(SELECT sv.descrizione from cd_stato_di_vendita sv
                --    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as statoVendita,
                    pa.STATO_DI_VENDITA as statoVendita,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                    0 as numSchermi, 0 as numProiezioni,
                pa.FLG_TARIFFA_VARIABILE as tariffaVariabile,
                ROUND(pa.imp_tariffa, 0) as tariffa,
                ROUND(pa.imp_maggiorazione, 0) as maggiorazione,
                ROUND(pa.IMP_LORDO, 0) as lordo,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as nettoComm,
                (select TRUNC(imp_prod.imp_netto, 3) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as nettoDir,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as scontoComm,
                (select ROUND(imp_prod.imp_sc_comm, 0) from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as scontoDir,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'C') as percScontoComm,
                (select TRUNC(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0), 3)
                    from cd_importi_prodotto imp_prod
                    where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                    and imp_prod.tipo_contratto = 'D') as percScontoDir,
                ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
            from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dettaglio_proposta_isp_old in errore: '
                             || SQLERRM
                            );
   END fu_dettaglio_proposta_isp_old;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_soggetto_tab_old
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- soggetto) dei prodotti acquistati associati a quel piano; metodo per il caso TABELLARE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_soggetto_tab_old (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_SOGG
   AS
--
      c_dati   C_TOTALI_SOGG;
--
   BEGIN
   -- modifica del 30.11.2009
--      OPEN c_dati FOR
--         select base.idSoggettoPiano as idSoggettoPiano,
--                ROUND(SUM(base.tariffa), 0) as totTariffa,
--                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
--                ROUND(SUM(base.lordo), 0) as totLordo,
--                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
--                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
--                ROUND(SUM(base.scontoComm), 0) as totScontoC,
--                ROUND(SUM(base.scontoDir), 0) as totScontoD,
--                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
--                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
--                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
--                ROUND(SUM(base.recupero), 0) as totRecupero
--            from
--            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
--                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
--                            pp.cod_categoria_prodotto as codFamigliaPubb,
--                            (select min(pa2.DATA_INIZIO) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaDal,
--                            (select max(pa2.DATA_FINE) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaAl,
--                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
--                            pv.ID_CIRCUITO as circuito,
--                            pv.ID_TIPO_BREAK as tipoFilmato,
--                            pv.ID_MOD_VENDITA as modalitaVendita,
--                            pa.STATO_DI_VENDITA as statoVendita,
--                            (select count (distinct id_schermo) from cd_circuito_schermo cs
--                                where id_circuito = pv.ID_CIRCUITO) as numSchermi,
--                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
--                            pa.IMP_LORDO as lordo,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as nettoComm,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as nettoDir,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as scontoComm,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as scontoDir,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
--                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
--                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
--                            cd_prodotto_pubb pp, cd_comunicato c
--                        where pa.ID_PIANO = p_id_piano
--                        and pa.ID_VER_PIANO = p_id_ver_piano
--                        and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--                        and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--                        and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--                        and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--                        and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--                        and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
--                        and pv.id_prodotto_vendita = pa.id_prodotto_vendita
--                        and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
--                        and pa.flg_annullato = 'N'
--                        order by idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita
--            ) base
--            group by base.idSoggettoPiano;
----
--      RETURN c_dati;
OPEN c_dati FOR
         select base.idSoggettoPiano as idSoggettoPiano,
                base.periodoVenditaDal as periodoVenditaDal,
                base.periodoVenditaAl as periodoVenditaAl,
                ROUND(SUM(base.tariffa), 0) as totTariffa,
                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 0) as totLordo,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC,
                ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
                ROUND(SUM(base.recupero), 0) as totRecupero
            from
            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
                            pp.cod_categoria_prodotto as codFamigliaPubb,
                            pa.DATA_INIZIO as periodoVenditaDal,
                            pa.DATA_FINE as periodoVenditaAl,
                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
                            pv.ID_CIRCUITO as circuito,
                            pv.ID_TIPO_BREAK as tipoFilmato,
                            pv.ID_MOD_VENDITA as modalitaVendita,
                            pa.STATO_DI_VENDITA as statoVendita,
                            (select count (distinct id_schermo) from cd_circuito_schermo cs
                                where id_circuito = pv.ID_CIRCUITO) as numSchermi,
                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
                            pa.IMP_LORDO as lordo,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as nettoComm,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as nettoDir,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as scontoComm,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as scontoDir,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                            cd_prodotto_pubb pp, cd_comunicato c
                        where pa.ID_PIANO = p_id_piano
                        and pa.ID_VER_PIANO = p_id_ver_piano
                        and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                        and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                        and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                        and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                        and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                        and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
                        and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                        and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
                        and pa.flg_annullato = 'N'
                        and pa.flg_sospeso = 'N'
                        and pa.COD_DISATTIVAZIONE IS NULL
                        order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita
            ) base
            group by base.periodoVenditaDal, base.periodoVenditaAl, base.idSoggettoPiano;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_soggetto_tab_old in errore: '
                             || SQLERRM
                            );
   END fu_totali_soggetto_tab_old;
--
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_soggetto_isp_old
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- soggetto) dei prodotti acquistati associati a quel piano; metodo per il caso INIZIATIVE SPECIALI
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_soggetto_isp_old (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_SOGG
   AS
--
      c_dati   C_TOTALI_SOGG;
--
   BEGIN
   -- modifica del 30.11.2009
--      OPEN c_dati FOR
--         select base.idSoggettoPiano as idSoggettoPiano,
--                ROUND(SUM(base.tariffa), 0) as totTariffa,
--                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
--                ROUND(SUM(base.lordo), 0) as totLordo,
--                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
--                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
--                ROUND(SUM(base.scontoComm), 0) as totScontoC,
--                ROUND(SUM(base.scontoDir), 0) as totScontoD,
--                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
--                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
--                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
--                ROUND(SUM(base.recupero), 0) as totRecupero
--            from
--            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
--                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
--                            pp.cod_categoria_prodotto as codFamigliaPubb,
--                            (select min(pa2.DATA_INIZIO) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaDal,
--                            (select max(pa2.DATA_FINE) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaAl,
--                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
--                            pv.ID_CIRCUITO as circuito,
--                            pp.desc_prodotto as tipoFilmato,
--                            pv.ID_MOD_VENDITA as modalitaVendita,
--                            pa.STATO_DI_VENDITA as statoVendita,
--                            pa.id_formato as formato,
--                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
--                            pa.IMP_LORDO as lordo,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as nettoComm,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as nettoDir,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as scontoComm,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as scontoDir,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
--                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
--                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
--                cd_prodotto_pubb pp, cd_comunicato c
--            where pa.ID_PIANO = p_id_piano
--            and pa.ID_VER_PIANO = p_id_ver_piano
--            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
--            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
--            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
--            and pa.flg_annullato = 'N'
--            order by idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato
--            ) base
--            group by base.idSoggettoPiano;
----
--      RETURN c_dati;
OPEN c_dati FOR
         select base.idSoggettoPiano as idSoggettoPiano,
                base.periodoVenditaDal as periodoVenditaDal,
                base.periodoVenditaAl as periodoVenditaAl,
                ROUND(SUM(base.tariffa), 0) as totTariffa,
                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 0) as totLordo,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC,
                ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
                ROUND(SUM(base.recupero), 0) as totRecupero
            from
            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
                            pp.cod_categoria_prodotto as codFamigliaPubb,
                            pa.DATA_INIZIO as periodoVenditaDal,
                            pa.DATA_FINE as periodoVenditaAl,
                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
                            pv.ID_CIRCUITO as circuito,
                            pp.desc_prodotto as tipoFilmato,
                            pv.ID_MOD_VENDITA as modalitaVendita,
                            pa.STATO_DI_VENDITA as statoVendita,
                            pa.id_formato as formato,
                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
                            pa.IMP_LORDO as lordo,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as nettoComm,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as nettoDir,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as scontoComm,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as scontoDir,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato
            ) base
            group by base.periodoVenditaDal, base.periodoVenditaAl, base.idSoggettoPiano;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_soggetto_isp_old in errore: '
                             || SQLERRM
                            );
   END fu_totali_soggetto_isp_old;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_piano_tab_old
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- l'intero piano) dei prodotti acquistati associati a quel piano; metodo per il caso TABELLARE
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_piano_tab_old (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_PIANO
   AS
--
      c_dati   C_TOTALI_PIANO;
--
   BEGIN
   -- modifica del 30.11.2009
--      OPEN c_dati FOR
--         select ROUND(SUM(base.tariffa), 0) as totTariffa,
--                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
--                ROUND(SUM(base.lordo), 0) as totLordo,
--                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
--                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
--                ROUND(SUM(base.scontoComm), 0) as totScontoC,
--                ROUND(SUM(base.scontoDir), 0) as totScontoD,
--                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
--                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
--                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
--                ROUND(SUM(base.recupero), 0) as totRecupero
--            from
--            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
--                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
--                            pp.cod_categoria_prodotto as codFamigliaPubb,
--                            (select min(pa2.DATA_INIZIO) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaDal,
--                            (select max(pa2.DATA_FINE) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaAl,
--                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
--                            pv.ID_CIRCUITO as circuito,
--                            pv.ID_TIPO_BREAK as tipoFilmato,
--                            pv.ID_MOD_VENDITA as modalitaVendita,
--                            pa.STATO_DI_VENDITA as statoVendita,
--                            (select count (distinct id_schermo) from cd_circuito_schermo cs
--                                where id_circuito = pv.ID_CIRCUITO) as numSchermi,
--                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
--                            pa.IMP_LORDO as lordo,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as nettoComm,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as nettoDir,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as scontoComm,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as scontoDir,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
--                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
--                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
--                            cd_prodotto_pubb pp, cd_comunicato c
--                        where pa.ID_PIANO = p_id_piano
--                        and pa.ID_VER_PIANO = p_id_ver_piano
--                        and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--                        and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--                        and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--                        and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--                        and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--                        and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
--                        and pv.id_prodotto_vendita = pa.id_prodotto_vendita
--                        and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
--                        and pa.flg_annullato = 'N'
--                        order by idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita
--            ) base;
----
--      RETURN c_dati;
OPEN c_dati FOR
         select ROUND(SUM(base.tariffa), 0) as totTariffa,
                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 0) as totLordo,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC,
                ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
                ROUND(SUM(base.recupero), 0) as totRecupero
            from
            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
                            pp.cod_categoria_prodotto as codFamigliaPubb,
                            pa.DATA_INIZIO as periodoVenditaDal,
                            pa.DATA_FINE as periodoVenditaAl,
                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
                            pv.ID_CIRCUITO as circuito,
                            pv.ID_TIPO_BREAK as tipoFilmato,
                            pv.ID_MOD_VENDITA as modalitaVendita,
                            pa.STATO_DI_VENDITA as statoVendita,
                            (select count (distinct id_schermo) from cd_circuito_schermo cs
                                where id_circuito = pv.ID_CIRCUITO) as numSchermi,
                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
                            pa.IMP_LORDO as lordo,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as nettoComm,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as nettoDir,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as scontoComm,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as scontoDir,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                            cd_prodotto_pubb pp, cd_comunicato c
                        where pa.ID_PIANO = p_id_piano
                        and pa.ID_VER_PIANO = p_id_ver_piano
                        and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                        and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                        and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                        and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                        and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                        and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
                        and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                        and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
                        and pa.flg_annullato = 'N'
                        and pa.flg_sospeso = 'N'
                        and pa.COD_DISATTIVAZIONE IS NULL
                        order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita
            ) base;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_piano_tab_old in errore: '
                             || SQLERRM
                            );
   END fu_totali_piano_tab_old;
--
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_totali_piano_isp_old
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei totali (per
-- l'intero piano) dei prodotti acquistati associati a quel piano; metodo per il caso INIZIATIVE SPECIALI
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti; nel caso dello sconto invece della somma viene
-- fornito il max fra i valori presenti
--
-- REALIZZATORE: Daniela Spezia, Altran , NOvembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_totali_piano_isp_old (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_TOTALI_PIANO
   AS
--
      c_dati   C_TOTALI_PIANO;
--
   BEGIN
   -- modifica del 30.11.2009
--      OPEN c_dati FOR
--         select ROUND(SUM(base.tariffa), 0) as totTariffa,
--                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
--                ROUND(SUM(base.lordo), 0) as totLordo,
--                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
--                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
--                ROUND(SUM(base.scontoComm), 0) as totScontoC,
--                ROUND(SUM(base.scontoDir), 0) as totScontoD,
--                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
--                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
--                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
--                ROUND(SUM(base.recupero), 0) as totRecupero
--            from
--            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
--                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
--                            pp.cod_categoria_prodotto as codFamigliaPubb,
--                            (select min(pa2.DATA_INIZIO) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaDal,
--                            (select max(pa2.DATA_FINE) from CD_PRODOTTO_ACQUISTATO pa2
--                                where pa2.id_piano = pa.id_piano
--                                and pa2.id_ver_piano = pa.id_ver_piano
--                                group by c.ID_SOGGETTO_DI_PIANO) as periodoVenditaAl,
--                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
--                            pv.ID_CIRCUITO as circuito,
--                            pp.desc_prodotto as tipoFilmato,
--                            pv.ID_MOD_VENDITA as modalitaVendita,
--                            pa.STATO_DI_VENDITA as statoVendita,
--                            pa.id_formato as formato,
--                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
--                            pa.IMP_LORDO as lordo,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as nettoComm,
--                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as nettoDir,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as scontoComm,
--                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as scontoDir,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
--                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
--                                from cd_importi_prodotto imp_prod
--                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
--                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
--                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
--                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
--                cd_prodotto_pubb pp, cd_comunicato c
--            where pa.ID_PIANO = p_id_piano
--            and pa.ID_VER_PIANO = p_id_ver_piano
--            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
--            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
--            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
--            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
--            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
--            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
--            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
--            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
--            and pa.flg_annullato = 'N'
--            order by idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato
--            ) base;
----
--      RETURN c_dati;
OPEN c_dati FOR
         select ROUND(SUM(base.tariffa), 0) as totTariffa,
                ROUND(SUM(base.maggiorazione), 0) as totMaggiorazione,
                ROUND(SUM(base.lordo), 3) as totLordo,
                TRUNC(SUM(base.nettoComm), 3) as totNettoC,
                TRUNC(SUM(base.nettoDir), 3) as totNettoD,
                ROUND(SUM(base.scontoComm), 0) as totScontoC,
                ROUND(SUM(base.scontoDir), 0) as totScontoD,
                TRUNC(AVG(base.percScontoComm), 3) as totPercScontoC,
                TRUNC(AVG(base.percScontoDir), 3) as totPercScontoD,
                ROUND(SUM(base.sanatoria), 0) as totSanatoria,
                ROUND(SUM(base.recupero), 0) as totRecupero
            from
            (select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
                            pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato,
                            pp.cod_categoria_prodotto as codFamigliaPubb,
                            pa.DATA_INIZIO as periodoVenditaDal,
                            pa.DATA_FINE as periodoVenditaAl,
                            pa.ID_MISURA_PRD_VE as estensioneTemporale,
                            pv.ID_CIRCUITO as circuito,
                            pp.desc_prodotto as tipoFilmato,
                            pv.ID_MOD_VENDITA as modalitaVendita,
                            pa.STATO_DI_VENDITA as statoVendita,
                            pa.id_formato as formato,
                            pa.imp_tariffa as tariffa, pa.imp_maggiorazione as maggiorazione,
                            pa.IMP_LORDO as lordo,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as nettoComm,
                            (select imp_prod.imp_netto from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as nettoDir,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as scontoComm,
                            (select imp_prod.imp_sc_comm from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as scontoDir,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'C') as percScontoComm,
                            (select NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(imp_prod.imp_netto, imp_prod.imp_sc_comm),0)
                                from cd_importi_prodotto imp_prod
                                where imp_prod.id_prodotto_acquistato = pa.id_prodotto_acquistato
                                and imp_prod.tipo_contratto = 'D') as percScontoDir,
                            ROUND(pa.imp_sanatoria, 0) as sanatoria, ROUND(pa.imp_recupero, 0) as recupero
                        from CD_PRODOTTO_ACQUISTATO pa, cd_soggetto_di_piano sp, cd_prodotto_vendita pv,
                cd_prodotto_pubb pp, cd_comunicato c
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO
            and pv.id_prodotto_vendita = pa.id_prodotto_vendita
            and pv.ID_PRODOTTO_PUBB = pp.ID_PRODOTTO_PUBB
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            order by periodoVenditaDal, periodoVenditaAl, idSoggettoPiano, circuito, tipoFilmato, modalitaVendita, statoVendita, formato
            ) base;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_totali_piano_isp_old in errore: '
                             || SQLERRM
                            );
   END fu_totali_piano_isp_old;
--
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_num_sogg_prod_acq
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce il numero di soggetti differenti per
--                                  tutti i prodotti acquistati del piano in esame
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , NOvembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_num_sogg_prod_acq (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_NUM_SOGG_PROD_ACQ
   AS
--
      c_dati   C_NUM_SOGG_PROD_ACQ;
--
   BEGIN
   OPEN c_dati FOR
         select count(distinct c.id_soggetto_di_piano) as numSoggetti,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
            from cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
            where pa.ID_PIANO = p_id_piano
                and pa.ID_VER_PIANO = p_id_ver_piano
                and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                and pa.flg_annullato = 'N'
                and pa.flg_sospeso = 'N'
                and pa.COD_DISATTIVAZIONE IS NULL
                and c.FLG_ANNULLATO = 'N'
                and c.FLG_SOSPESO = 'N'
                and c.COD_DISATTIVAZIONE IS NULL
                group by pa.ID_PRODOTTO_ACQUISTATO
                order by pa.ID_PRODOTTO_ACQUISTATO;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_num_sogg_prod_acq in errore: '
                             || SQLERRM
                            );
   END fu_num_sogg_prod_acq;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_desc_sogg_prod_acq
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce la descrizione
--               dei soggetti differenti per tutti i prodotti acquistati del piano in esame
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_desc_sogg_prod_acq (
      p_id_piano       cd_pianificazione.id_piano%TYPE,
      p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
      p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
      p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_SOGG_PROD_ACQ
   AS
--
      c_dati   C_SOGG_PROD_ACQ;
--
   BEGIN
   OPEN c_dati FOR
         select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
                sp.descrizione as descSoggettoPiano,
                pa.ID_PRODOTTO_ACQUISTATO as idProdAcquistato
            from cd_soggetto_di_piano sp, cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa
            where pa.ID_PIANO = p_id_piano
            and pa.ID_VER_PIANO = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
            and sp.ID_SOGGETTO_DI_PIANO = c.ID_SOGGETTO_DI_PIANO
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and c.FLG_ANNULLATO = 'N'
            and c.FLG_SOSPESO = 'N'
            and c.COD_DISATTIVAZIONE IS NULL
            order by pa.ID_PRODOTTO_ACQUISTATO;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_desc_sogg_prod_acq in errore: '
                             || SQLERRM
                            );
   END fu_desc_sogg_prod_acq;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_num_prod_acq_dir_si
--
-- DESCRIZIONE:  Fornisce il numero di prodotti acquistati (per il piano in esame) che
-- hanno almeno un valore del netto direzionale maggiore di zero
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: Il numero di prodotti acquistati con un netto direzionale
--
-- REALIZZATORE: Daniela Spezia, Altran , Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
FUNCTION fu_num_prod_acq_dir_si(p_id_piano       cd_pianificazione.id_piano%TYPE,
                                  p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
                                  p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                  p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                  p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                  p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE)
    RETURN NUMBER IS
    v_num_prodotti NUMBER;
    BEGIN
        select count(1) INTO v_num_prodotti
            from cd_prodotto_acquistato pa, cd_importi_prodotto ipd
            where pa.id_piano = p_id_piano and pa.id_ver_piano = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and ipd.id_prodotto_acquistato = pa.id_prodotto_acquistato
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and ipd.TIPO_CONTRATTO = 'D'
            and ipd.imp_netto > 0;
        RETURN v_num_prodotti;
    EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20028, 'Function fu_num_prod_acq_dir_si in errore: ' || SQLERRM);
    END fu_num_prod_acq_dir_si;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_num_prod_rich_dir_si
--
-- DESCRIZIONE:  Fornisce il numero di prodotti richiesti (per il piano in esame) che
-- hanno almeno un valore del netto direzionale maggiore di zero
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: Il numero di prodotti richiesti con un netto direzionale
--
-- REALIZZATORE: Daniela Spezia, Altran , Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
FUNCTION fu_num_prod_rich_dir_si(p_id_piano       cd_pianificazione.id_piano%TYPE,
                                  p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE)
    RETURN NUMBER IS
    v_num_prodotti NUMBER;
    BEGIN
        select count(1) INTO v_num_prodotti
            from cd_prodotti_richiesti pr, cd_importi_prodotto ipd
            where pr.id_piano = p_id_piano and pr.id_ver_piano = p_id_ver_piano
            and ipd.id_prodotti_richiesti = pr.id_prodotti_richiesti
            and pr.flg_annullato = 'N'
            and pr.flg_sospeso = 'N'
            and ipd.TIPO_CONTRATTO = 'D'
            and ipd.imp_netto > 0;
        RETURN v_num_prodotti;
    EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20028, 'Function fu_num_prod_rich_dir_si in errore: ' || SQLERRM);
    END fu_num_prod_rich_dir_si;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_elenco_schermi_tab
--
-- DESCRIZIONE:  Estrae per il caso tabellare  l'elenco degli schermi di proiezione del piano in esame
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati cercati
--
-- REALIZZATORE: Daniela Spezia, Altran , Dicembre 2009
-- Modifiche : Mauro Viel, Altran Dicembre 2010 inserita gestione del nome cinema. 
-------------------------------------------------------------------------------------------------
--
FUNCTION fu_elenco_schermi_tab (
        p_id_piano           CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
        p_id_ver_piano       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
        p_id_stato_vendita   cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento  CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_ELENCO_SCHERMI
   AS
--
      c_dati  C_DETTAGLIO_ELENCO_SCHERMI;
--
   BEGIN
      OPEN c_dati FOR
         select distinct cin.id_cinema as idCinema, 
                --cin.nome_cinema as nomeCinema,
                pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,schermo.data_fine) as nomeCinema,
                comune.comune as comuneCinema, prov.abbr as provinciaCinema,
                reg.NOME_REGIONE as regioneCinema,
                sa.id_sala as idSala,
                sa.nome_sala as nomeSala
                from
                    cd_cinema cin,
                    cd_sala sa,
                    cd_comune comune,
                    cd_provincia prov,
                    cd_regione reg,
                    (select
                    pa.data_fine,
                    sch.id_sala,
                    cir.id_circuito,
                    cir.nome_circuito
                    from
                       cd_schermo sch,
                       cd_proiezione pr,
                       cd_break br,
                       cd_circuito_break cir_br,
                       cd_circuito cir,
                       cd_break_vendita  brv,
                       cd_comunicato c,
                       cd_prodotto_acquistato pa
                       where pa.id_piano = p_id_piano
                      and pa.id_ver_piano = p_id_ver_piano
                      and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                      and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                      and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                      and c.data_erogazione_prev >= nvl(p_data_inizio, c.data_erogazione_prev)
                      and c.data_erogazione_prev <= nvl(p_data_fine, c.data_erogazione_prev)
                      and pr.DATA_PROIEZIONE >= nvl(p_data_inizio, pr.DATA_PROIEZIONE)
                      and pr.DATA_PROIEZIONE <= nvl(p_data_fine, pr.DATA_PROIEZIONE)
                      and c.id_break_vendita = brv.id_break_vendita
                      and brv.id_circuito_break = cir_br.id_circuito_break
                      and br.id_break = cir_br.id_break
                      and cir.id_circuito = cir_br.id_circuito
                      and pr.id_proiezione = br.id_proiezione
                      and sch.id_schermo = pr.id_schermo
                      and br.flg_annullato = 'N'
                      and pr.flg_annullato = 'N'
                      and sch.flg_annullato = 'N'
                      and brv.flg_annullato = 'N'
                      and pa.flg_annullato = 'N'
                      and pa.FLG_SOSPESO = 'N'
                      and pa.COD_DISATTIVAZIONE IS NULL
                      and c.flg_annullato = 'N'
                      and c.FLG_SOSPESO = 'N'
                      and c.COD_DISATTIVAZIONE IS NULL
                      and cir_br.flg_annullato = 'N'
                      and cir.flg_annullato = 'N'
                      ) schermo
                  where cin.flg_virtuale = 'N' 
                  and   schermo.ID_SALA = sa.ID_SALA
                  and   sa.ID_CINEMA = cin.ID_CINEMA
                  and   comune.id_comune = cin.id_comune
                  and   prov.id_provincia = comune.id_provincia
                  and   reg.ID_REGIONE = prov.ID_REGIONE
                  and   cin.flg_annullato = 'N'
                  and   sa.flg_annullato = 'N'
                  order by pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,schermo.data_fine), comune.comune, sa.nome_sala;
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR(-20028, 'Function fu_elenco_schermi_tab in errore: ' || SQLERRM);
   END fu_elenco_schermi_tab;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_estremi_periodo_proiez
--
-- DESCRIZIONE:  Estrae per il caso tabellare  l'elenco degli schermi di proiezione del piano in esame
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati cercati
--
-- REALIZZATORE: Daniela Spezia, Altran , Dicembre 2009
--
-------------------------------------------------------------------------------------------------
--
FUNCTION fu_estremi_periodo_proiez (
        p_id_piano           CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
        p_id_ver_piano       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
        p_id_stato_vendita   cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento  CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_ESTREMI_PERIODO
   AS
--
      c_dati  C_ESTREMI_PERIODO;
--
   BEGIN
      OPEN c_dati FOR
         select min(pa.DATA_INIZIO) as dataInizio, max(pa.DATA_FINE) as dataFine
          from cd_prodotto_acquistato pa
          where pa.id_piano = p_id_piano
          AND  pa.id_ver_piano = p_id_ver_piano
          and pa.flg_annullato = 'N'
          and pa.flg_sospeso = 'N'
          and pa.COD_DISATTIVAZIONE IS NULL
          and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
          and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
          and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
          and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE);
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR(-20028, 'Function fu_estremi_periodo_proiez in errore: ' || SQLERRM);
   END fu_estremi_periodo_proiez;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_testata_ordine
--
-- DESCRIZIONE:  Fornendo il numero identificativo dell'ordine fonisce l'estrazione dei dati "di testata"
-- dell'ordine stesso (piano, versione, area, responsabile di contatto, agenzia)
--
-- INPUT:
--      p_id_ordine
--
-- OUTPUT: esito:Resulset contenente i dati della testata per la stampa ordine
--
-- REALIZZATORE: Daniela Spezia, Altran , Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_testata_ordine (
      p_id_ordine   cd_ordine.id_ordine%TYPE
   )
      RETURN C_TESTATA_ORDINE
   AS
--
      c_dati   C_TESTATA_ORDINE;
--
   BEGIN
      OPEN c_dati FOR
         SELECT
                pian.id_piano as pianoId, pian.id_ver_piano as versionePianoId,
                ord.COD_PRG_ORDINE as progressivoOrdine,
                pian.cod_area as codArea, pa_cd_pianificazione.get_desc_area(pian.COD_AREA) as descArea,
                pa_cd_pianificazione.get_desc_responsabile(pian.ID_RESPONSABILE_CONTATTO) as nomeRespContatto,
                ri.ID_AGENZIA as idAgenzia, a.RAG_SOC_COGN as agenzia,
                (select des_cpag from cond_pagamento
                    where cod_cpag = ord.ID_COND_PAGAMENTO) as condPagamento,
                ord.DATA_INIZIO as dataInizioOrdine, ord.DATA_FINE as dataFineOrdine
           FROM
            cd_pianificazione pian, cd_raggruppamento_intermediari ri, vi_cd_agenzia a,
            cd_ordine ord
              WHERE ord.ID_ORDINE = p_id_ordine
              and pian.id_piano = ord.id_piano
              AND  pian.id_ver_piano = ord.id_ver_piano
              and ri.ID_PIANO (+)= pian.ID_PIANO and ri.ID_VER_PIANO (+)= pian.ID_VER_PIANO
              AND a.ID_AGENZIA (+)= ri.ID_AGENZIA
              AND pian.FLG_ANNULLATO = 'N'
              AND pian.FLG_SOSPESO = 'N'
              and ord.flg_annullato = 'N'
              and ord.flg_sospeso = 'N';
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_testata_ordine in errore: '
                             || SQLERRM
                            );
   END fu_testata_ordine;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_cliente_fruitore
--
-- DESCRIZIONE:  Fornendo il numero identificativo dell'ordine fonisce l'estrazione dei dati relativi
-- al cliente fruitore dell'ordine stesso
--
-- INPUT:
--      p_id_ordine
--
-- OUTPUT: esito:Resulset contenente i dati del cliente fruitore per la stampa ordine
--
-- REALIZZATORE: Daniela Spezia, Altran , Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_cliente_fruitore (
      p_id_ordine   cd_ordine.id_ordine%TYPE
   )
      RETURN C_CLI_FRUITORE_ORDINE
   AS
--
      c_dati   C_CLI_FRUITORE_ORDINE;
--
   BEGIN
      OPEN c_dati FOR
         select cf.cod_interl as idCliente, cf.rag_soc_br_nome as nome, cf.rag_soc_cogn as cognome,
            cf.indirizzo as indirizzo, cf.cap as cap, cf.localita as localita, cf.provincia as provincia,
            cf.nazione as nazione, cf.sesso as sesso, cf.cod_fisc as codiceFiscale,
            cf.part_iva as partitaIva
            from interl_u cf, cd_ordine ord, cd_fruitori_di_piano fp
            where ord.id_ordine = p_id_ordine
            and ord.id_fruitori_di_piano = fp.ID_FRUITORI_DI_PIANO
            and fp.ID_CLIENTE_FRUITORE = cf.cod_interl
            and ord.flg_annullato = 'N'
            and ord.flg_sospeso = 'N';
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_cliente_fruitore in errore: '
                             || SQLERRM
                            );
   END fu_cliente_fruitore;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_cliente_committ
--
-- DESCRIZIONE:  Fornendo il numero identificativo dell'ordine fonisce
-- l'estrazione dei dati relativi al cliente committente dell'ordine stesso
--
-- INPUT:
--      p_id_ordine
--
-- OUTPUT: esito:Resulset contenente i dati del cliente committente per la stampa ordine
--
-- REALIZZATORE: Daniela Spezia, Altran , Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_cliente_committ (
      p_id_ordine cd_ordine.id_ordine%type
   )
      RETURN C_CLI_FRUITORE_ORDINE
   AS
--
      c_dati   C_CLI_FRUITORE_ORDINE;
--
   BEGIN
      OPEN c_dati FOR

         select cf.cod_interl as idCliente, ' ' as nome, cf.rag_soc_cogn as cognome,
                cf.indirizzo as indirizzo, cf.cap as cap, cf.localita as localita, cf.provincia as provincia,
                cf.nazione as nazione, cf.sesso as sesso, cf.cod_fisc as codiceFiscale,
                cf.PART_IVA as partitaIva
            from interl_u cf, cd_ordine ord
            where ord.ID_ORDINE = p_id_ordine
            and cf.cod_interl = ord.ID_CLIENTE_COMMITTENTE
            and ord.FLG_ANNULLATO = 'N'
            and ord.FLG_SOSPESO = 'N';
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_cliente_committ in errore: '
                             || SQLERRM
                            );
   END fu_cliente_committ;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_ordine
--
-- DESCRIZIONE:  Fornendo il numero piano e versione dell'ordine fonisce l'estrazione dei dati di dettaglio
-- dell'ordine stesso
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--
-- OUTPUT: esito:Resulset contenente i dati di dettaglio per la stampa ordine
--
-- REALIZZATORE: Daniela Spezia, Altran , Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dettaglio_ordine (
      p_id_ordine cd_ordine.id_ordine%type
   )
      RETURN C_PRODOTTO_ORDINE
   AS
--
      c_dati   C_PRODOTTO_ORDINE;
--
   BEGIN
      OPEN c_dati FOR
         SELECT ifatt.desc_prodotto as descProdotto,
                --(select min(data_inizio) from cd_importi_fatturazione
                --        where id_ordine = ifatt.id_ordine) as dataInizio,
                --(select max(data_fine) from cd_importi_fatturazione
                --        where id_ordine = ifatt.id_ordine) as dataFine,
                ifatt.data_inizio as dataInizio, ifatt.data_fine as dataFine,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(pa.ID_PRODOTTO_ACQUISTATO) as numSale,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(pa.ID_PRODOTTO_ACQUISTATO) as numAmbienti,
                PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(pa.ID_PRODOTTO_ACQUISTATO) as durataTab,
                (select fa.descrizione from cd_formato_acquistabile fa
                        where fa.id_formato = pa.id_formato) as formatoIsp,
                0 as tariffa,
                ifatt.IMPORTO_NETTO as netto,
                NVL(ifatt.PERC_SCONTO_SOST_AGE, 0) as percSconto,
                (SELECT (SUM (ifatt2.IMPORTO_NETTO))
                    from cd_importi_fatturazione ifatt2, cd_prodotto_acquistato pa2, cd_importi_prodotto ip2
                    where ifatt2.id_ordine = p_id_ordine
                    --and ifatt2.flg_sospeso = 'N' MV 20/04/2010
                    and ifatt2.FLG_ANNULLATO = 'N'
                    and pa2.FLG_ANNULLATO = 'N'
                    and pa2.flg_sospeso = 'N'
                    and pa2.COD_DISATTIVAZIONE IS NULL
                    and ip2.ID_PRODOTTO_ACQUISTATO = pa2.ID_PRODOTTO_ACQUISTATO
                    and ip2.id_importi_prodotto = ifatt2.ID_IMPORTI_PRODOTTO) as totaleNetto,
                ifatt.stato_fatturazione as statoFatturaz,
                ip.tipo_contratto as tipoContratto,
                pa.id_prodotto_acquistato as idProdAcq,
                pa.imp_netto as nettoProdAcq
                from cd_importi_fatturazione ifatt, cd_prodotto_acquistato pa, cd_importi_prodotto ip
                where ifatt.id_ordine = p_id_ordine
                and ifatt.FLG_ANNULLATO = 'N'
                --and ifatt.flg_sospeso = 'N' MV 20/04/2010
                and pa.FLG_ANNULLATO = 'N'
                and pa.flg_sospeso = 'N'
                and pa.COD_DISATTIVAZIONE IS NULL
                and ip.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                and ip.id_importi_prodotto = ifatt.ID_IMPORTI_PRODOTTO
                and ifatt.flg_incluso_in_ordine = 'S'
                order by ifatt.data_inizio, ifatt.data_fine, ifatt.desc_prodotto, pa.id_prodotto_acquistato;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_dettaglio_ordine in errore: '
                             || SQLERRM
                            );
   END fu_dettaglio_ordine;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_desc_sogg_ordine
--
-- DESCRIZIONE:  Fornendo l'identificativo dell'ordine fornisce la descrizione
--               dei soggetti differenti per tutti i prodotti acquistati dell'ordine in esame;
--               l'id prodotto acquistato in output non viene valorizzato
--
-- INPUT:
--      p_id_ordine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_desc_sogg_ordine (
      p_id_ordine cd_ordine.id_ordine%type
   )
      RETURN C_SOGG_PROD_ACQ
   AS
--
      c_dati   C_SOGG_PROD_ACQ;
--
   BEGIN
   OPEN c_dati FOR
         select distinct sp.id_soggetto_di_piano as idSoggettoPiano,
                sp.descrizione as descSoggettoPiano,
                '' as idProdAcquistato
            from cd_soggetto_di_piano sp, cd_comunicato c, CD_PRODOTTO_ACQUISTATO pa,
        cd_importi_fatturazione ifatt, cd_importi_prodotto ip
        where ifatt.id_ordine = p_id_ordine
        and ifatt.FLG_ANNULLATO = 'N'
        --and ifatt.flg_sospeso = 'N' mv 20/04/2010
        and ip.id_importi_prodotto = ifatt.ID_IMPORTI_PRODOTTO
        and ip.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
        and pa.flg_annullato = 'N'
        and pa.flg_sospeso = 'N'
        and pa.COD_DISATTIVAZIONE IS NULL
        and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
        and c.FLG_ANNULLATO = 'N'
        and c.FLG_SOSPESO = 'N'
        and c.COD_DISATTIVAZIONE IS NULL
        and sp.ID_SOGGETTO_DI_PIANO = c.ID_SOGGETTO_DI_PIANO;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_desc_sogg_ordine in errore: '
                             || SQLERRM
                            );
   END fu_desc_sogg_ordine;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_lista_copie_conf_ordine
--
-- DESCRIZIONE:  Fornendo l'identificativo dell'ordine fornisce l'elenco di tutte le differenti
--               copie conformi salvate su db
--
-- INPUT:
--      p_id_ordine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_lista_copie_conf_ordine (
      p_id_ordine cd_ordine.id_ordine%type
   )
      RETURN C_COPIE_CONF_ORDINE
   AS
--
      c_dati   C_COPIE_CONF_ORDINE;
--
   BEGIN
   OPEN c_dati FOR
         select id_stampe_ordine as stampaOrdineId, id_ordine as ordineId,
                data_stampa as dataStampa, flg_ordine_modificato as flgOrdineModificato
            from cd_stampe_ordine
            where id_ordine = p_id_ordine
            order by id_stampe_ordine desc;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_lista_copie_conf_ordine in errore: '
                             || SQLERRM
                            );
   END fu_lista_copie_conf_ordine;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_copia_conf_ordine
--
-- DESCRIZIONE:  Fornendo l'identificativo dell'ordine fornisce l'elenco di tutte le differenti
--               copie conformi salvate su db
--
-- INPUT:
--      p_id_ordine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_copia_conf_ordine (
      p_id_stampa cd_stampe_ordine.id_stampe_ordine%type
   )
      RETURN C_DATI_COPIA_CONF_ORDINE
   AS
--
      c_dati   C_DATI_COPIA_CONF_ORDINE;
--
   BEGIN
   OPEN c_dati FOR
         select pdf as datiPdf
            from cd_stampe_ordine
            where id_stampe_ordine = p_id_stampa;
--
      RETURN c_dati;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_copia_conf_ordine in errore: '
                             || SQLERRM
                            );
   END fu_copia_conf_ordine;
--
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA pr_ins_copia_conf_ordine
-- DESCRIZIONE:  Esegue l'inserimento di una nuova copia conforme
--
-- OPERAZIONI:
-- 1) Memorizza un pdf relativo all'ordine in esame per la data indicata
--
-- INPUT: l'identificativo dell'ordine, la data di stampa e l'array di byte corrispondente al pdf
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -1 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Daniela Spezia, Altran Febbraio 2010
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE pr_ins_copia_conf_ordine(p_id_ordine cd_stampe_ordine.ID_ORDINE%type,
                                    p_data_stampa cd_stampe_ordine.DATA_STAMPA%type,
                                    p_pdf cd_stampe_ordine.pdf%type,
                                    p_esito             OUT NUMBER)
IS
BEGIN
    p_esito     := 1;
    SAVEPOINT sp_pr_ins_copia_conf_ordine;
    INSERT INTO cd_stampe_ordine
        (ID_ORDINE, DATA_STAMPA, PDF)
       VALUES
         (p_id_ordine, p_data_stampa, p_pdf);
--
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20028, 'PROCEDURA pr_ins_copia_conf_ordine - Insert non eseguita, errore: '||SQLERRM);
        ROLLBACK TO sp_pr_ins_copia_conf_ordine;
END;
--
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA pr_ins_copia_conf_null
-- DESCRIZIONE:  Esegue l'inserimento di una copia conforme vuota
--
-- OPERAZIONI:
-- 1) Memorizza un pdf vuoto relativo all'ordine in esame per la data indicata
--
-- INPUT: l'identificativo dell'ordine, la data di stampa
--
-- OUTPUT: esito:
--    l'identificativo del record appena inserito
--   -1 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Daniela Spezia, Altran Febbraio 2010
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE pr_ins_copia_conf_null(p_id_ordine cd_stampe_ordine.ID_ORDINE%type,
                                    p_data_stampa cd_stampe_ordine.DATA_STAMPA%type,
                                    p_id_stampa_ordine out cd_stampe_ordine.ID_STAMPE_ORDINE%type)
IS
BEGIN
    p_id_stampa_ordine     := 0;
    SAVEPOINT sp_pr_ins_copia_conf_null;
-- eseguo l'inserimento
    INSERT INTO cd_stampe_ordine
        (ID_ORDINE, DATA_STAMPA, PDF)
       VALUES
         (p_id_ordine, p_data_stampa, EMPTY_BLOB());
-- eseguo la lettura dell'id dell'ultimo record inserito
    SELECT CD_STAMPE_ORDINE_SEQ.CURRVAL INTO p_id_stampa_ordine FROM DUAL;
--
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_id_stampa_ordine := -1;
        RAISE_APPLICATION_ERROR(-20028, 'PROCEDURA pr_ins_copia_conf_null - Insert non eseguita, errore: '||SQLERRM);
        ROLLBACK TO sp_pr_ins_copia_conf_null;
END;
--
-----------------------------------------------------------------------------------------------------
-- Funzione fu_lungh_copia_ordine
--
-- DESCRIZIONE:  Fornendo l'identificativo della stampa ordine fornisce la lunghezza di quel campo
--
-- INPUT:
--      p_id_stampa
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , Febbraio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_lungh_copia_ordine (
      p_id_stampa cd_stampe_ordine.id_stampe_ordine%type
   )
      RETURN INTEGER
   AS
--
      lungh   INTEGER;
--
   BEGIN
         select dbms_lob.getlength(pdf) into lungh
            from cd_stampe_ordine
            where id_stampe_ordine = p_id_stampa;
--
      RETURN lungh;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20028,
                                'Funzione fu_lungh_copia_ordine in errore: '
                             || SQLERRM
                            );
   END fu_lungh_copia_ordine;
--
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA pr_upd_copia_conf
-- DESCRIZIONE:  Esegue l'update della copia conforme specificata
--
-- INPUT: l'identificativo della stampa, il numero di byte da inserire
-- e l'array di byte corrispondente alla porzione di pdf da inserire
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -1 Inserimento non eseguito
--
-- REALIZZATORE: Daniela Spezia, Altran Febbraio 2010
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE pr_upd_copia_conf(p_id_stampa cd_stampe_ordine.ID_STAMPE_ORDINE%type,
                                    p_num_byte INTEGER,
                                    p_buffer RAW,
                                    p_esito out number)
IS
    v_pdf_attuale   BLOB;
BEGIN
    p_esito         := 1;
    SAVEPOINT sp_pr_upd_copia_conf;
-- leggo il contenuto del campo pdf esistente
    SELECT PDF INTO v_pdf_attuale FROM CD_STAMPE_ORDINE WHERE ID_STAMPE_ORDINE = p_id_stampa FOR UPDATE;
-- aggiorno il valore del campo
    DBMS_LOB.WRITEAPPEND(v_pdf_attuale, p_num_byte, p_buffer);
--
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20028, 'PROCEDURA pr_upd_copia_conf - Update non eseguita, errore: '||SQLERRM);
        ROLLBACK TO sp_pr_upd_copia_conf;
END;
--
-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_FILM
--
-- DESCRIZIONE:  Restituisce i film per ogni prodotto di un piano con il relativo numero medio di sale
--
-- INPUT:        id_piano  
--               id_ver_piano   
--
-- REALIZZATORE: Michele Borgogno, Altran, Settembre 2010
--
-- MODIFICHE:    Mauro Viel Altran, Marzo 2011 inseriti i due parametri p_data_inizio e p_data_fine
--               Mauro Viel Altran, Marzo 2011 inserito il paramatro p_target per stampare solo i target o tutti i prodotti
-------------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_FILM(p_id_piano cd_prodotto_acquistato.ID_PIANO%TYPE, p_id_ver_piano cd_prodotto_acquistato.ID_VER_PIANO%TYPE, p_data_inizio cd_prodotto_acquistato.data_inizio%TYPE, p_data_fine cd_prodotto_acquistato.data_fine%TYPE, p_target char ) RETURN C_FILM IS
v_film C_FILM;
BEGIN
   
    OPEN v_film FOR
        select id_prodotto_acquistato, data_inizio, data_fine, stato_di_vendita, durata, media_tot_settimana, desc_circuito, desc_tipo_break, nome_spettacolo, round(sum(num_sale)/(data_fine - data_inizio +1)) media_sale, pa_cd_stampe_magazzino.prod_sogg(id_prodotto_acquistato) as desc_sogg
        from
        (
        select P_A.id_prodotto_acquistato, P_A.data_inizio, P_A.data_fine, P_A.stato_di_vendita, P_A.durata, P_A.media_tot_settimana, P_A.desc_circuito, P_A.desc_tipo_break,        
               co.data_erogazione_prev, spe.nome_spettacolo, count(distinct co.id_sala) num_sale
        from
          cd_spettacolo spe,
          cd_proiezione_spett ps,
          cd_proiezione pro,
          cd_schermo sch,
          cd_comunicato co,
         (select id_prodotto_acquistato, stato_di_vendita, durata, data_inizio, data_fine, desc_circuito, desc_tipo_break, trunc(avg(num_sale_giorno)) media_tot_settimana
          from
           (select pa.id_prodotto_acquistato, sv.descrizione as stato_di_vendita, cc.durata, pa.data_inizio, pa.data_fine, com.data_erogazione_prev, cir.desc_circuito, tb.desc_tipo_break, count(distinct com.id_sala) num_sale_giorno
            from
                cd_circuito cir,
                cd_tipo_break tb,
                cd_prodotto_vendita pv,
                cd_comunicato com,
                cd_prodotto_acquistato pa,
                cd_stato_di_vendita sv,
                cd_formato_acquistabile fa,
                cd_coeff_cinema cc
            where pa.id_piano = p_id_piano
              and pa.id_ver_piano = p_id_ver_piano
              and pa.data_inizio >= nvl(p_data_inizio, pa.data_inizio)
              and pa.data_fine <= nvl(p_data_fine, pa.DATA_FINE)
              and pa.flg_annullato='N'
              and pa.flg_sospeso = 'N'
              and pa.cod_disattivazione is null
              and com.id_prodotto_acquistato = pa.id_prodotto_acquistato
              and com.flg_annullato='N'
              and com.flg_sospeso='N'
              and com.cod_disattivazione is null
              and pa.id_prodotto_vendita = pv.id_prodotto_vendita
              and nvl(pv.id_target,-1) = decode(p_target,'S',pv.id_target,-1)
              and tb.id_tipo_break = pv.id_tipo_break
              and cir.id_circuito = pv.id_circuito
              and sv.descr_breve = pa.stato_di_vendita
              and fa.ID_FORMATO = pa.ID_FORMATO
              and cc.ID_COEFF = fa.ID_COEFF
            group by pa.id_prodotto_acquistato, sv.descrizione, cc.durata, pa.data_inizio, pa.data_fine, com.data_erogazione_prev, cir.desc_circuito, tb.desc_tipo_break
           )
          group by id_prodotto_acquistato, stato_di_vendita, durata, data_inizio, data_fine, desc_circuito, desc_tipo_break
         ) P_A
        where co.id_prodotto_acquistato = P_A.id_prodotto_acquistato
          and co.flg_annullato='N'
          and co.flg_sospeso='N'
          and co.cod_disattivazione is null
          and sch.id_sala = co.id_sala
          and pro.data_proiezione = co.data_erogazione_prev
          and pro.id_schermo = sch.id_schermo
          and ps.id_proiezione = pro.id_proiezione
          and spe.id_spettacolo = ps.id_spettacolo
        group by P_A.id_prodotto_acquistato, P_A.stato_di_vendita, P_A.durata, P_A.data_inizio, P_A.data_fine, P_A.media_tot_settimana, P_A.desc_circuito, P_A.desc_tipo_break, co.data_erogazione_prev, spe.nome_spettacolo
        )
        group by id_prodotto_acquistato, data_inizio, data_fine, stato_di_vendita, durata, media_tot_settimana, desc_circuito, desc_tipo_break, nome_spettacolo
        order by data_inizio, data_fine, id_prodotto_acquistato, nome_spettacolo;
    RETURN v_film;
END FU_ELENCO_FILM;
--

function prod_sogg(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return varchar2 is
 v_descrizione varchar2(600) :='';
 begin
  for c in (
  select distinct sopia.DESCRIZIONE 
  from   cd_comunicato co, cd_soggetto_di_piano sopia
  where  co.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
  and    sopia.ID_SOGGETTO_DI_PIANO = co.ID_SOGGETTO_DI_PIANO
  and    co.FLG_ANNULLATO = 'N'
  and    co.FLG_SOSPESO = 'N'
  and    co.COD_DISATTIVAZIONE is null
  )
  loop
      IF (c.descrizione != 'SOGGETTO NON DEFINITO') THEN
        v_descrizione := v_descrizione || ', ' || c.descrizione;
      END IF;
  end loop;
--
  IF (v_descrizione = '') THEN
    v_descrizione := ', SOGGETTO NON DEFINITO';
  END IF;
  return substr(v_descrizione,2, length(v_descrizione));
 end prod_sogg;
--



function fu_dett_previsione_fattura(p_id_piano cd_pianificazione.id_piano%type,p_id_ver_piano cd_pianificazione.id_ver_piano%type, p_data_inizio date, p_data_fine date)  return c_previsione_fattura is
v_previsione_fattura c_previsione_fattura;
v_min_data_inizio cd_prodotto_acquistato.DATA_INIZIO%type;
v_max_data_fine cd_prodotto_acquistato.DATA_FINE%type;

begin

if p_data_inizio is null or p_data_fine is null then
    select min(data_inizio), max(data_fine) 
    into  v_min_data_inizio, v_max_data_fine
    from cd_prodotto_acquistato 
    where id_piano= p_id_piano
    and   id_ver_piano = p_id_ver_piano
    and   flg_annullato='N'
    and   flg_sospeso ='N'
    and   cod_disattivazione is null;
else
    v_min_data_inizio := p_data_inizio;
    v_max_data_fine := p_data_fine;
end if; 


PA_CD_SUPPORTO_VENDITE.IMPOSTA_PARAMETRI(v_min_data_inizio, v_max_data_fine);
PA_CD_SITUAZIONE_VENDUTO.IMPOSTA_PARAMETRI(null, null, null, null, null, null, null, null, null, null, null,p_id_piano,p_id_ver_piano);


OPEN v_previsione_fattura FOR
select data_inizio,data_fine,imp_netto,tipo_contratto from
(
    select to_date('01' || to_char(data_trasm,'MM') ||  to_char(data_trasm,'YYYY'),'DDMMYYYY')   as  data_inizio, to_date('15'|| to_char(data_trasm,'MM') ||  to_char(data_trasm,'YYYY'),'DDMMYYYY')   as data_fine,sum(imp_netto) imp_netto, tipo_contratto from vi_cd_base_situazione_venduto where to_char(data_trasm,'DD') between '01' and '15' group by to_char(data_trasm,'MM'),to_char(data_trasm,'YYYY'),tipo_contratto
    union
    select to_date('16' || to_char(data_trasm,'MM') || to_char(data_trasm,'YYYY'),'DDMMYYYY')   as data_inizio, to_date(to_char(last_day(data_trasm),'DD')|| to_char(data_trasm,'MM') ||  to_char(data_trasm,'YYYY'),'DDMMYYYY')  as data_fine, sum(imp_netto) imp_netto, tipo_contratto from vi_cd_base_situazione_venduto where to_char(data_trasm,'DD') between '16' and '31' group by to_char(data_trasm,'MM'),to_char(data_trasm,'YYYY'),tipo_contratto,to_char(last_day(data_trasm),'DD')
)
order by data_inizio,data_fine,imp_netto,tipo_contratto;
return v_previsione_fattura;

end;


function fu_elenco_decurtazioni(p_data_inizio date,p_data_fine date,p_cod_esercente vi_cd_societa_esercente.COD_ESERCENTE%type) return C_STAMPA_DECURTAZIONE is
V_STAMPA_DECURTAZIONE C_STAMPA_DECURTAZIONE;
begin

open V_STAMPA_DECURTAZIONE
for select SA.id_cinema,LS.id_sala, pa_cd_cinema.FU_GET_NOME_CINEMA(ci.id_cinema,p_data_fine) as nome_cinema, SA.nome_sala, co.comune, LS.data_rif, CR.descrizione_estesa
    from
      cd_codice_resp CR,
      cd_liquidazione_sala LS,
      cd_sala SA,
      cd_cinema ci,
      cd_comune co,
      CD_ESER_CONTRATTO EC, CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC, VI_CD_SOCIETA_ESERCENTE ES
      WHERE  EC.COD_ESERCENTE = ES.COD_ESERCENTE
      AND    C.ID_CONTRATTO = EC.ID_CONTRATTO
      AND    CC.ID_CONTRATTO = C.ID_CONTRATTO
      AND    CC.ID_CINEMA = ci.ID_CINEMA
      AND    ES.COD_ESERCENTE = p_cod_esercente
      and SA.id_cinema =ci.ID_CINEMA-- !!! FILTRO CINEMA !!!
      and LS.data_rif between p_data_inizio and p_data_fine -- !!! FILTRO GIORNO !!!
      and LS.id_sala = SA.id_sala
      and sa.id_cinema = ci.id_cinema
      and ci.ID_COMUNE = co.id_comune
      and LS.FLG_PROIEZIONE_PUBB='N'
      and CR.id_codice_resp = LS.id_codice_resp
      and CR.AGGREGAZIONE = 'RE'
      order by ci.nome_cinema, SA.nome_sala, co.comune, LS.data_rif;
      
return V_STAMPA_DECURTAZIONE;
end fu_elenco_decurtazioni;




-----------------------------------------------------------------------------------------------------
-- Funzione fu_num_prod_acq_dir_lordo_si
--
-- DESCRIZIONE:  Fornisce il numero di prodotti acquistati (per il piano in esame) che
-- hanno almeno un valore del lordo direzionale maggiore di zero
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: Il numero di prodotti acquistati con un netto direzionale
--
-- REALIZZATORE: Mauro Viel, Altran , Gennaio  2011
--
--  MODIFICHE: Mauro Viel Altran, Maggio 2011 inserito il controllo ipd.IMP_NETTO + ipd.IMP_SC_COMM >0
--             al posto di PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto,ipd.imp_sc_comm) > 0
--             in modo da mostrare sempre gli importi direzionali se presenti con limporto lordo >0 
--             la precedente condizione non mostrava gli importi aventi sconto commerciale direzionale a zero.
--
-------------------------------------------------------------------------------------------------
--
FUNCTION fu_num_prod_acq_dir_lordo_si(p_id_piano       cd_pianificazione.id_piano%TYPE,
                                  p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
                                  p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                  p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                  p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                  p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE)
    RETURN NUMBER IS
    v_num_prodotti NUMBER;
    BEGIN
        select count(1) INTO v_num_prodotti
            from cd_prodotto_acquistato pa, cd_importi_prodotto ipd
            where pa.id_piano = p_id_piano and pa.id_ver_piano = p_id_ver_piano
            and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
            and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
            and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
            and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
            and ipd.id_prodotto_acquistato = pa.id_prodotto_acquistato
            and pa.flg_annullato = 'N'
            and pa.flg_sospeso = 'N'
            and pa.COD_DISATTIVAZIONE IS NULL
            and ipd.TIPO_CONTRATTO = 'D'
            and ipd.IMP_NETTO + ipd.IMP_SC_COMM >0;
            --and PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto,ipd.imp_sc_comm) > 0;
        RETURN v_num_prodotti;
    EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20028, 'Function fu_num_prod_acq_dir_lordo_si in errore: ' || SQLERRM);
    END fu_num_prod_acq_dir_lordo_si;
--
-----------------------------------------------------------------------------------------------------

--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_PROIEZIONE_ESEGUITA  
--
-- DESCRIZIONE:   Ritorna 1 se la proiezione e' andata in onda, 0 altrimenti
--
-- INPUT:
--      p_id_sala       La sala di riferimento
--      p_data_rif      La data di riferimento
--
-- OUTPUT: 
--      -1              - funzione in errore
--      0               - proiezione non andata in onda
--      1               - proiezione andata in onda
--
-- REALIZZATORE:
--      Tommaso D'Anna, Teoresi srl, 07 Febbraio 2011
--
-- MODIFICHE:
--      Tommaso D'Anna, Teoresi srl, 12 Aprile 2011
--                      - La query non va piu su CD_LIQUIDAZIONE_SALA ma direttametne
--                          su CD_ADV_COMUNICATO      
-------------------------------------------------------------------------------------------------
FUNCTION FU_PROIEZIONE_ESEGUITA(    p_id_prodotto_acquistato    CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_id_sala                   CD_COMUNICATO.ID_SALA%TYPE,
                                    p_data_rif                  CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE
                               )
    RETURN NUMBER IS
    v_esito_proiez NUMBER;
    BEGIN
--        SELECT COUNT(1) INTO v_esito_proiez
--        FROM    CD_LIQUIDAZIONE_SALA 
--        WHERE   ID_SALA = p_id_sala
--        AND     DATA_RIF = p_data_rif
--        AND     FLG_PROGRAMMAZIONE = 'S'
--        AND     FLG_PROIEZIONE_PUBB = 'S';
        SELECT DECODE( COUNT(1), 0, 0, 1 ) INTO v_esito_proiez
        FROM 
            CD_COMUNICATO,
            CD_MATERIALE_DI_PIANO,
            CD_MATERIALE,
            CD_ADV_COMUNICATO
        WHERE CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND CD_COMUNICATO.ID_SALA = p_id_sala
        AND CD_COMUNICATO.DATA_EROGAZIONE_PREV = p_data_rif
        AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
        AND CD_COMUNICATO.FLG_SOSPESO = 'N'
        AND CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO = CD_COMUNICATO.ID_MATERIALE_DI_PIANO
        AND CD_MATERIALE.ID_MATERIALE = CD_MATERIALE_DI_PIANO.ID_MATERIALE
        AND CD_ADV_COMUNICATO.ID_COMUNICATO = CD_COMUNICATO.ID_COMUNICATO
        AND TRUNC(CD_COMUNICATO.DATA_EROGAZIONE_PREV) = TRUNC(CD_ADV_COMUNICATO.DATA_EROGAZIONE_EFF)
        AND CD_ADV_COMUNICATO.DURATA >= CD_MATERIALE.DURATA;
        RETURN v_esito_proiez;
    EXCEPTION
        WHEN OTHERS THEN
        v_esito_proiez:=-1;
        RAISE_APPLICATION_ERROR(-20028, 'FU_PROIEZIONE_ESEGUITA in errore: ' || SQLERRM);
    END FU_PROIEZIONE_ESEGUITA;
    
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALE 
--
-- DESCRIZIONE:   Ritorna la chiave di CD_CODICE_RESP per la causale
--
-- INPUT:
--      p_id_sala       La sala di riferimento
--      p_data_rif      La data di riferimento
--
-- OUTPUT: 
--      X              - la chiave di CD_CODICE_RESP per la causale
--
-- REALIZZATORE:
--      Tommaso D'Anna, Teoresi srl, 06 Aprile 2011
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALE(            p_id_sala   CD_LIQUIDAZIONE_SALA.ID_SALA%TYPE,
                                    p_data_rif  CD_LIQUIDAZIONE_SALA.DATA_RIF%TYPE
                               )
    RETURN NUMBER IS
    v_causale NUMBER;
    v_count NUMBER;
    BEGIN
        v_causale := -1;
        SELECT  COUNT(1) INTO v_count
        FROM    CD_LIQUIDAZIONE_SALA 
        WHERE   ID_SALA = p_id_sala
        AND     DATA_RIF = p_data_rif;
        IF ( v_count > 0 ) THEN
            SELECT  ID_CODICE_RESP INTO v_causale
            FROM    CD_LIQUIDAZIONE_SALA 
            WHERE   ID_SALA = p_id_sala
            AND     DATA_RIF = p_data_rif;        
        END IF;
        RETURN v_causale;
    EXCEPTION
        WHEN OTHERS THEN
        v_causale:=-1;
        RAISE_APPLICATION_ERROR(-20047, 'FU_GET_CAUSALE in errore: ' || SQLERRM);
    END FU_GET_CAUSALE;   
    
    --
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_calendario_isp
--
-- DESCRIZIONE:  Fornendo il numero piano e il numero versione fonisce l'estrazione dei dati "di dettaglio"
-- del piano stesso; e possibile fornire ulteriori parametri corrispondenti a eventuali criteri di filtro
-- Questa function va usata nel caso di famiglia pubblicitaria INIZIATIVE SPECIALI per la stampa calendario
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_stato_vendita
--      p_id_raggruppamento
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: esito:Resulset contenente i dati di dettaglio per la stampa calendario
--
-- REALIZZATORE: Daniela Spezia, Altran , Ottobre 2009
--
--  MODIFICHE:   Mauro Viel, Altran, Dicembre 2010, inserita la gestione del nome cinema.
--               Duplicata dalla  fu_dettaglio_calendario_isp per la stampa xls.
-------------------------------------------------------------------------------------------------
--
   FUNCTION fu_dettaglio_cal_isp_xls (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_CALENDARIO_XLS
   AS
--
      c_dati   C_DETTAGLIO_CALENDARIO_XLS;
--
   BEGIN
      OPEN c_dati FOR
         select distinct
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
                circ.ID_CIRCUITO as idCircuito,
                circ.NOME_CIRCUITO as nomeCircuito,
                pa.STATO_DI_VENDITA as codStato,
                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                (select pp.desc_prodotto from cd_prodotto_pubb pp
                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB) as tipoPubb,
                (select mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                cin.id_cinema as idCinema,
                --cin.nome_cinema as nomeCinema,
                pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,pa.data_fine) as nomeCinema,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as comuneCinema,
                (select provincia from cd_provincia prov, cd_comune comune
                        where comune.id_comune = cin.id_comune
                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,  
                (select nome_regione from cd_provincia prov, cd_comune comune, cd_regione reg
                      where comune.id_comune = cin.id_comune
                      and prov.id_provincia = comune.id_provincia
                      and prov.ID_REGIONE = reg.ID_REGIONE) as regioneCinema,                        
                '' as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
                0 as numProiezioni,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                0 as posizione
                from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                     cd_circuito circ, cd_circuito_cinema cc, cd_cinema cin, cd_comunicato com, cd_cinema_vendita cv
                where pa.ID_PIANO = p_id_piano
                  and pa.ID_VER_PIANO = p_id_ver_piano
                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                  and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                  and circ.ID_CIRCUITO = pv.ID_CIRCUITO
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and pv.FLG_ANNULLATO = 'N'
                  and circ.FLG_ANNULLATO = 'N'
                  and cc.flg_annullato = 'N'
                  and cin.flg_annullato = 'N'
                  and cc.id_circuito = circ.ID_CIRCUITO
                  and cc.id_cinema = cin.id_cinema
                  and cv.id_cinema_vendita = com.ID_CINEMA_VENDITA
                  and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  and cc.ID_CIRCUITO_CINEMA = cv.id_circuito_cinema
                  and com.flg_annullato = 'N'
                  and com.flg_sospeso = 'N'
                  and com.COD_DISATTIVAZIONE IS NULL
        union
        (select distinct
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
                circ.ID_CIRCUITO as idCircuito,
                circ.NOME_CIRCUITO as nomeCircuito,
                pa.STATO_DI_VENDITA as codStato,
                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                (select pp.desc_prodotto from cd_prodotto_pubb pp
                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB) as tipoPubb,
                (select mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                cin.id_cinema as idCinema,
                pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,pa.data_fine) as nomeCinema,
                --cin.nome_cinema as nomeCinema,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as comuneCinema,
                (select provincia from cd_provincia prov, cd_comune comune
                        where comune.id_comune = cin.id_comune
                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
               (select nome_regione from cd_provincia prov, cd_comune comune, cd_regione reg
                      where comune.id_comune = cin.id_comune
                      and prov.id_provincia = comune.id_provincia
                      and prov.ID_REGIONE = reg.ID_REGIONE) as regioneCinema,                        
                '' as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
                0 as numProiezioni,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                0 as posizione
                from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                    cd_circuito circ, cd_cinema cin, cd_circuito_atrio ca, cd_atrio atr,cd_comunicato com, cd_atrio_vendita av
                where pa.ID_PIANO = p_id_piano
                  and pa.ID_VER_PIANO = p_id_ver_piano
                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                  and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                  and circ.ID_CIRCUITO = pv.ID_CIRCUITO
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and pv.FLG_ANNULLATO = 'N'
                  and circ.FLG_ANNULLATO = 'N'
                  and cin.flg_annullato = 'N'
                  and ca.flg_annullato = 'N'
                  and atr.flg_annullato = 'N'
                  and ca.id_circuito = circ.ID_CIRCUITO
                  and ca.id_atrio = atr.id_atrio
                  and atr.id_cinema = cin.id_cinema
                  and av.id_atrio_vendita = com.ID_ATRIO_VENDITA
                  and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  and ca.ID_CIRCUITO_ATRIO = av.id_circuito_atrio
                  and com.flg_annullato = 'N'
                  and com.flg_sospeso = 'N'
                  and com.COD_DISATTIVAZIONE IS NULL
                  )
        union
        (select distinct
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as idSoggettoPiano,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp, cd_comunicato c
                    where c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                    and sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as descSoggettoPiano,
                circ.ID_CIRCUITO as idCircuito,
                circ.NOME_CIRCUITO as nomeCircuito,
                pa.STATO_DI_VENDITA as codStato,
                (select sv.DESCRIZIONE from cd_stato_di_vendita sv
                    where pa.STATO_DI_VENDITA = sv.DESCR_BREVE) as descStato,
                (select pp.desc_prodotto from cd_prodotto_pubb pp
                    where pp.ID_PRODOTTO_PUBB = pv.ID_PRODOTTO_PUBB) as tipoPubb,
                (select mv.desc_mod_vendita from cd_modalita_vendita mv
                    where mv.id_mod_vendita = pv.ID_MOD_VENDITA) as modalitaVendita,
                cin.id_cinema as idCinema,
                --cin.nome_cinema as nomeCinema,
                pa_cd_cinema.FU_GET_NOME_CINEMA(cin.id_cinema,pa.data_fine) as nomeCinema,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as comuneCinema,
                (select provincia from cd_provincia prov, cd_comune comune
                        where comune.id_comune = cin.id_comune
                        and prov.id_provincia = comune.id_provincia) as provinciaCinema,
               (select nome_regione from cd_provincia prov, cd_comune comune, cd_regione reg
                      where comune.id_comune = cin.id_comune
                      and prov.id_provincia = comune.id_provincia
                      and prov.ID_REGIONE = reg.ID_REGIONE) as regioneCinema,                        
                fu_get_sala_isp(pa.id_prodotto_acquistato) as nomeSala, null as periodoProiezDal, null as periodoProiezAl,
                0 as numProiezioni,
                (select fa.descrizione from cd_formato_acquistabile fa
                    where fa.id_formato = pa.id_formato) as formato,
                0 as posizione
                from CD_PRODOTTO_ACQUISTATO pa, cd_prodotto_vendita pv,
                    cd_circuito circ, cd_cinema cin, cd_circuito_sala cs, cd_sala sa,cd_comunicato com, cd_sala_vendita sv
                where pa.ID_PIANO = p_id_piano
                  and pa.ID_VER_PIANO = p_id_ver_piano
                  and pa.STATO_DI_VENDITA = NVL (p_id_stato_vendita, pa.STATO_DI_VENDITA)
                  and NULLIF(p_id_raggruppamento, pa.ID_RAGGRUPPAMENTO) is null
                  and pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                  and pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                  and pv.id_prodotto_vendita = pa.id_prodotto_vendita
                  and circ.ID_CIRCUITO = pv.ID_CIRCUITO
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and pv.FLG_ANNULLATO = 'N'
                  and circ.FLG_ANNULLATO = 'N'
                  and cin.flg_annullato = 'N'
                  and cs.FLG_ANNULLATO = 'N'
                  and sa.flg_annullato = 'N'
                  and cs.id_circuito = circ.ID_CIRCUITO
                  and cs.id_sala = sa.id_sala
                  and sa.id_cinema = cin.id_cinema
                  and sv.id_sala_vendita = com.ID_sala_VENDITA
                  and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  and cs.ID_CIRCUITO_SALA = sv.id_circuito_sala
                  and com.flg_annullato = 'N'
                  and com.flg_sospeso = 'N'
                  and com.COD_DISATTIVAZIONE IS NULL
                  )
            order by idCircuito, tipoPubb, modalitaVendita, formato, idSoggettoPiano, nomeCinema;
--
      RETURN c_dati;   
     end  fu_dettaglio_cal_isp_xls;  
     
     
     
     function fu_dett_certificazione_breve(p_id_piano               cd_pianificazione.id_piano%type,
                                           p_id_ver_piano           cd_pianificazione.id_ver_piano%type,
                                           p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                           p_data_inizio            cd_prodotto_acquistato.data_inizio%type,
                                           p_data_fine              cd_prodotto_acquistato.data_fine%type 
     ) return c_certificazione_breve as
     
     v_certificazione_breve c_certificazione_breve;
     begin
        open v_certificazione_breve for
        select distinct id_prodotto_acquistato,DATA_INIZIO,DATA_FINE,cod_area,des_area,reponsabile_contatto,cliente,nome_agenzia,venditore_cliente, durata,
                CIRCUITO  ,TIPO_BREAK , soggetto, DATA_EROGAZIONE_PREV  as giorno,sum(proiettato) as numero_proiezioni--, --pa_cd_prodotto_acquistato.FU_GET_NUM_AMBIENTI(id_prodotto_acquistato) as numero_sale
                from 
                (
                    select pa.id_prodotto_acquistato,
                           ar.COD_AREA,
                           ar.DESCRIZIONE_ESTESA des_area,
                           responsabile.RAG_SOC_COGN as reponsabile_contatto,
                           cliente.RAG_SOC_COGN as cliente,
                           agenzia.RAG_SOC_COGN as nome_agenzia,
                           venditore.RAG_SOC_COGN as venditore_cliente,
                           pa.DATA_INIZIO,
                           pa.DATA_FINE,
                           cir.NOME_CIRCUITO AS CIRCUITO, 
                           br.DESC_TIPO_BREAK AS TIPO_BREAK, 
                           coef.durata,
                           com.id_sala, 
                           pa_cd_stampe_magazzino.FU_PROIEZIONE_ESEGUITA(p_id_prodotto_acquistato, com.id_sala, com.DATA_EROGAZIONE_PREV) PROIETTATO,
                           com.DATA_EROGAZIONE_PREV,
                           sog.DESCRIZIONE as soggetto
                    from cd_prodotto_acquistato pa,
                         cd_raggruppamento_intermediari rag, 
                         cd_pianificazione pia,
                         aree ar,
                         interl_u responsabile,
                         interl_u cliente,
                         interl_u agenzia,
                         interl_u venditore,
                         cd_prodotto_vendita pv,
                         cd_circuito cir, 
                         cd_tipo_break br, 
                         cd_formato_acquistabile fo,
                         cd_coeff_cinema coef,
                         cd_comunicato com,
                         cd_sala sa,
                         cd_cinema ci,
                         cd_soggetto_di_piano sog
                    where pa.id_piano      = nvl(p_id_piano,pa.id_piano)
                    and   pa.id_ver_piano  = nvl(p_id_ver_piano,pa.id_ver_piano)
                    and   pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                    and   pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and   pa.flg_annullato = 'N'
                    and   pa.flg_sospeso ='N'
                    and   pa.COD_DISATTIVAZIONE is null
                    and   pa.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA
                    and   pa.ID_FORMATO = fo.ID_FORMATO
                    and   coef.ID_COEFF = fo.ID_COEFF
                    and   pv.ID_CIRCUITO = cir.ID_CIRCUITO
                    and   pv.ID_TIPO_BREAK = br.ID_TIPO_BREAK  
                    and   com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and   com.flg_annullato = 'N'
                    and   com.flg_sospeso ='N'
                    and   com.COD_DISATTIVAZIONE is null
                    and   com.id_sala = sa.id_sala
                    and   sa.FLG_VISIBILE = 'S'
                    and   sa.ID_cinema = ci.ID_CINEMA
                    and   ci.FLG_VIRTUALE = 'N'
                    and   com.ID_SOGGETTO_DI_PIANO = sog.ID_SOGGETTO_DI_PIANO
                    and   pia.ID_PIANO = pa.ID_PIANO
                    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
                    and   pia.COD_AREA = ar.COD_AREA
                    and   pia.ID_RESPONSABILE_CONTATTO = responsabile.COD_INTERL
                    and   pia.id_cliente = cliente.COD_INTERL
                    and   rag.ID_PIANO = pia.ID_PIANO
                    and   rag.ID_VER_PIANO = pia.ID_VER_PIANO
                    and   rag.ID_AGENZIA = agenzia.COD_INTERL
                    and   rag.ID_VENDITORE_CLIENTE = venditore.COD_INTERL
                    and   pa.ID_PRODOTTO_ACQUISTATO= p_id_prodotto_acquistato
                    group by  pa.id_prodotto_acquistato,ar.cod_area,ar.descrizione_estesa,responsabile.RAG_SOC_COGN,cliente.RAG_SOC_COGN,agenzia.RAG_SOC_COGN,venditore.rag_soc_cogn,
                              pa.DATA_INIZIO,pa.DATA_FINE, cir.NOME_CIRCUITO  , br.DESC_TIPO_BREAK , coef.durata,sog.DESCRIZIONE,com.DATA_EROGAZIONE_PREV,com.id_sala
                )
                group by id_prodotto_acquistato, cod_area,des_area,reponsabile_contatto,cliente,nome_agenzia,venditore_cliente,
                         DATA_INIZIO,DATA_FINE, CIRCUITO  ,TIPO_BREAK , durata, soggetto,DATA_EROGAZIONE_PREV
                order by giorno;
        return v_certificazione_breve;
     end fu_dett_certificazione_breve;
     
     
     
     function fu_get_prodotti(         p_id_piano               cd_pianificazione.id_piano%type,
                                       p_id_ver_piano            cd_pianificazione.id_ver_piano%type,
                                       p_data_inizio             cd_prodotto_acquistato.data_inizio%type,
                                       p_data_fine               cd_prodotto_acquistato.data_fine%type 
     ) return c_prodotto is
     v_prodotto  c_prodotto; 
     begin
        open v_prodotto for
        select id_prodotto_acquistato,data_inizio,data_fine
        from cd_prodotto_acquistato pa
        where pa.id_piano      = nvl(p_id_piano,pa.id_piano)
        and   pa.id_ver_piano  = nvl(p_id_ver_piano,pa.id_ver_piano)
        and   pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
        and   pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
        and   pa.flg_annullato = 'N'
        and   pa.flg_sospeso ='N'
        and   pa.COD_DISATTIVAZIONE is null
        order by pa.data_inizio, pa.data_fine;
        return v_prodotto;
     
     end fu_get_prodotti;
     
     
     
-----------------------------------------------------------------------------------------------------
-- Funzione fu_dettaglio_certificazione
--
-- DESCRIZIONE:  Restituisce i dati relativi alla certificazione semplice di un piano
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_id_prodotto_acquistato
--      p_data_proiezione
--      p_id_sala
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: 
--          Un cursore c_certificazione contenente le informazioni di dettaglio
--
-- REALIZZATORE: 
--          Tommaso D'Anna, Teoresi s.r.l., Febbraio 2011
--
--  MODIFICHE:  
--          Tommaso D'Anna, Teoresi s.r.l., 16 Maggio 2011
--              Aggiunta outer join su ID_AGENZIA
--          Tommaso D'Anna, Teoresi s.r.l., 10 Giugno 2011
--              Esclusione delle arene dalla stampa
--          Tommaso D'Anna, Teoresi s.r.l., 15 Giugno 2011
--              Inserito controllo incrociato sulle date per far funzionare il filtro
--              data inizio/fine
-------------------------------------------------------------------------------------------------     
      function fu_dett_certificazione      (p_id_piano               cd_pianificazione.id_piano%type,
                                            p_id_ver_piano           cd_pianificazione.id_ver_piano%type,
                                            p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                            p_data_proiezione        cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                            p_id_sala                cd_sala.ID_SALA%type,
                                            p_data_inizio            cd_prodotto_acquistato.data_inizio%type,
                                            p_data_fine              cd_prodotto_acquistato.data_fine%type 
     ) return c_certificazione as
     v_certificazione c_certificazione;
     begin
     open v_certificazione for
     select                
                           pa.id_prodotto_acquistato,
                           pa.DATA_INIZIO as DATA_INIZIO,
                           pa.DATA_FINE as DATA_FINE,
                           ar.COD_AREA as COD_AREA,
                           ar.DESCRIZIONE_ESTESA DES_AREA,
                           responsabile.RAG_SOC_COGN as REPONSABILE_CONTATTO,
                           cliente.RAG_SOC_COGN as CLIENTE,
                           agenzia.RAG_SOC_COGN as NOME_AGENZIA,
                           venditore.RAG_SOC_COGN as VENDITORE_CLIENTE,
                           cir.NOME_CIRCUITO AS CIRCUITO, 
                           br.DESC_TIPO_BREAK AS TIPO_BREAK, 
                           coef.durata as DURATA,
                           ci.NOME_CINEMA as NOME_CINEMA,
                           co.COMUNE as COMUNE,
                           prov.ABBR as PROVINCIA,
                           com.id_sala as ID_SALA,
                           sa.nome_sala as NOME_SALA, 
                           FU_PROIEZIONE_ESEGUITA(p_id_prodotto_acquistato, com.id_sala, com.DATA_EROGAZIONE_PREV) PROIETTATO,
                           FU_GET_CAUSALE(com.id_sala,com.DATA_EROGAZIONE_PREV) CAUSALE,
                           com.DATA_EROGAZIONE_PREV as DATA_PROIEZIONE,
                           sog.DESCRIZIONE as SOGGETTO
                    from cd_prodotto_acquistato pa,
                         cd_raggruppamento_intermediari rag, 
                         cd_pianificazione pia,
                         aree ar,
                         interl_u responsabile,
                         interl_u cliente,
                         interl_u agenzia,
                         interl_u venditore,
                         cd_prodotto_vendita pv,
                         cd_circuito cir, 
                         cd_tipo_break br, 
                         cd_formato_acquistabile fo,
                         cd_coeff_cinema coef,
                         cd_comunicato com,
                         cd_sala sa,
                         cd_cinema ci,
                         cd_comune co,
                         cd_provincia prov,
                         cd_soggetto_di_piano sog
                    where pa.id_piano      = nvl(p_id_piano,pa.id_piano)
                    and   pa.id_ver_piano  = nvl(p_id_ver_piano,pa.id_ver_piano)
                    AND   PA.DATA_INIZIO    <=  nvl(p_data_fine,    PA.DATA_FINE)
                    AND   PA.DATA_FINE      >=  nvl(p_data_inizio,  PA.DATA_INIZIO)
                    and   pa.flg_annullato = 'N'
                    and   pa.flg_sospeso ='N'
                    and   pa.COD_DISATTIVAZIONE is null
                    and   pa.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA
                    and   pa.ID_FORMATO = fo.ID_FORMATO
                    and   coef.ID_COEFF = fo.ID_COEFF
                    and   pv.ID_CIRCUITO = cir.ID_CIRCUITO
                    and   pv.ID_TIPO_BREAK = br.ID_TIPO_BREAK  
                    and   com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and   com.flg_annullato = 'N'
                    and   com.flg_sospeso ='N'
                    and   com.COD_DISATTIVAZIONE is null
                    and   com.id_sala = sa.id_sala
                    and   sa.FLG_VISIBILE = 'S'
                    and   sa.FLG_ARENA = 'N'
                    and   sa.ID_cinema = ci.ID_CINEMA
                    and   ci.ID_COMUNE = co.ID_COMUNE
                    and   co.ID_PROVINCIA = prov.ID_PROVINCIA
                    and   ci.FLG_VIRTUALE = 'N'
                    and   com.ID_SOGGETTO_DI_PIANO = sog.ID_SOGGETTO_DI_PIANO
                    and   pia.ID_PIANO = pa.ID_PIANO
                    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
                    and   pia.COD_AREA = ar.COD_AREA
                    and   pia.ID_RESPONSABILE_CONTATTO = responsabile.COD_INTERL
                    and   pia.id_cliente = cliente.COD_INTERL
                    and   rag.ID_PIANO = pia.ID_PIANO
                    and   rag.ID_VER_PIANO = pia.ID_VER_PIANO
                    and   rag.ID_AGENZIA = agenzia.COD_INTERL (+)
                    and   rag.ID_VENDITORE_CLIENTE = venditore.COD_INTERL
                    and   pa.ID_PRODOTTO_ACQUISTATO= p_id_prodotto_acquistato
                    and   com.DATA_EROGAZIONE_PREV = p_data_proiezione
                    and   com.id_sala=p_id_sala
                    group by  pa.id_prodotto_acquistato,ar.cod_area,ar.descrizione_estesa,responsabile.RAG_SOC_COGN,cliente.RAG_SOC_COGN,agenzia.RAG_SOC_COGN,venditore.rag_soc_cogn,ci.NOME_CINEMA, co.COMUNE,prov.ABBR,
                              pa.DATA_INIZIO,pa.DATA_FINE, cir.NOME_CIRCUITO  , br.DESC_TIPO_BREAK , coef.durata,sog.DESCRIZIONE,com.DATA_EROGAZIONE_PREV,com.id_sala, sa.nome_sala;
                  return v_certificazione;
                  end  fu_dett_certificazione;
                  
-------------------------------------------------------------------------------------------------
--  MODIFICHE: 
--          Tommaso D'Anna, Teoresi s.r.l., 10 Giugno 2011
--              Esclusione delle arene dalla stampa
-------------------------------------------------------------------------------------------------            
function fu_get_sale_prodotto(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type
) return c_sale_prodotto
as
v_sale_prodotto c_sale_prodotto;
begin 
    open v_sale_prodotto for
    select distinct(com.id_sala) as id_sala
    from  cd_comunicato com, cd_sala sa, cd_cinema ci
    where com.id_prodotto_acquistato = p_id_prodotto_acquistato
    and   com.flg_annullato = 'N'
    and   com.flg_sospeso = 'N'
    and   com.COD_DISATTIVAZIONE is null
    and   com.ID_SALA = sa.ID_SALA
    and   sa.FLG_VISIBILE = 'S'
    and   sa.ID_CINEMA = ci.ID_CINEMA
    and   sa.FLG_ARENA = 'N'
    and   ci.FLG_VIRTUALE = 'N';
return  v_sale_prodotto;

end fu_get_sale_prodotto;




-- FUNCTION FU_PROIEZIONE_ESEGUITA  
--
-- DESCRIZIONE:   Restituisce  il numero di proiezioni  effettive/previste
--
-- INPUT:
--      p_id_sala               La sala di riferimento
--      p_data_commerciale      La data commerciale,
--      p_id_materiale          Il materiale andato in onda 
--      
--
--
-- REALIZZATORE:
--      Mauro Viel Altran Italia Febbraio 2010
-------------------------------------------------------------------------------------------------
FUNCTION FU_NUMERO_PROIEZIONI(p_id_sala   CD_COMUNICATO.ID_SALA%TYPE,
                              p_data_erogazione_prev  CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                              p_id_materiale  CD_MATERIALE.ID_MATERIALE%TYPE
                              )
    RETURN   varchar2 IS
    v_proiezioni varchar2(50):= '0/0';
BEGIN

    pa_cd_adv_cinema.imposta_parametri(p_data_erogazione_prev,p_data_erogazione_prev);
    pa_cd_adv_cinema.imposta_sala(p_id_sala);

 
    select distinct  
    count(id_materiale) over (partition by data_commerciale,id_sala,id_materiale)
    ||
    '/'
    ||max(progressivo) over (partition by data_commerciale,id_sala) com_eff
    into v_proiezioni
    from vi_cd_comunicati_trasmessi
    where programmata = 1
    and  id_materiale = p_id_materiale;
        
    return  v_proiezioni;
EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return '0/0';
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20028, 'FU_NUMERO_PROIEZIONI in errore: ' || SQLERRM);
        
END FU_NUMERO_PROIEZIONI;



      function fu_dett_certificazione_estesa    (p_id_piano               cd_pianificazione.id_piano%type,
                                            p_id_ver_piano           cd_pianificazione.id_ver_piano%type,
                                            p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                            p_data_proiezione        cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                            p_id_sala                cd_sala.ID_SALA%type,
                                            p_data_inizio            cd_prodotto_acquistato.data_inizio%type,
                                            p_data_fine              cd_prodotto_acquistato.data_fine%type 
     ) return c_certificazione_estesa as
     v_certificazione c_certificazione_estesa;
     begin
     open v_certificazione for
     select pa.id_prodotto_acquistato,
                           pa.DATA_INIZIO as DATA_INIZIO,
                           pa.DATA_FINE as DATA_FINE,
                           ar.COD_AREA as COD_AREA,
                           ar.DESCRIZIONE_ESTESA DES_AREA,
                           responsabile.RAG_SOC_COGN as REPONSABILE_CONTATTO,
                           cliente.RAG_SOC_COGN as CLIENTE,
                           agenzia.RAG_SOC_COGN as NOME_AGENZIA,
                           venditore.RAG_SOC_COGN as VENDITORE_CLIENTE,
                           cir.NOME_CIRCUITO AS CIRCUITO, 
                           br.DESC_TIPO_BREAK AS TIPO_BREAK, 
                           coef.durata as DURATA,
                           ci.NOME_CINEMA as NOME_CINEMA,
                           co.COMUNE as COMUNE,
                           prov.ABBR as PROVINCIA,
                           com.id_sala as ID_SALA,
                           sa.nome_sala as NOME_SALA, 
                           FU_NUMERO_PROIEZIONI(com.id_sala,com.DATA_EROGAZIONE_PREV,mat_pia.id_materiale) AS NUMERO_PROIEZIONI,
                           com.DATA_EROGAZIONE_PREV as DATA_PROIEZIONE,
                           sog.DESCRIZIONE as SOGGETTO
                    from cd_prodotto_acquistato pa,
                         cd_raggruppamento_intermediari rag, 
                         cd_pianificazione pia,
                         aree ar,
                         interl_u responsabile,
                         interl_u cliente,
                         interl_u agenzia,
                         interl_u venditore,
                         cd_prodotto_vendita pv,
                         cd_circuito cir, 
                         cd_tipo_break br, 
                         cd_formato_acquistabile fo,
                         cd_coeff_cinema coef,
                         cd_comunicato com,
                         cd_materiale_di_piano mat_pia,
                         cd_sala sa,
                         cd_cinema ci,
                         cd_comune co,
                         cd_provincia prov,
                         cd_soggetto_di_piano sog
                    where pa.id_piano      = nvl(p_id_piano,pa.id_piano)
                    and   pa.id_ver_piano  = nvl(p_id_ver_piano,pa.id_ver_piano)
                    and   pa.DATA_INIZIO >= nvl(p_data_inizio, pa.DATA_INIZIO)
                    and   pa.DATA_FINE <= nvl(p_data_fine, pa.DATA_FINE)
                    and   pa.flg_annullato = 'N'
                    and   pa.flg_sospeso ='N'
                    and   pa.COD_DISATTIVAZIONE is null
                    and   pa.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA
                    and   pa.ID_FORMATO = fo.ID_FORMATO
                    and   coef.ID_COEFF = fo.ID_COEFF
                    and   pv.ID_CIRCUITO = cir.ID_CIRCUITO
                    and   pv.ID_TIPO_BREAK = br.ID_TIPO_BREAK  
                    and   com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                    and   com.flg_annullato = 'N'
                    and   com.flg_sospeso ='N'
                    and   com.COD_DISATTIVAZIONE is null
                    and   com.id_sala = sa.id_sala
                    and   sa.FLG_VISIBILE = 'S'
                    and   sa.ID_cinema = ci.ID_CINEMA
                    and   ci.ID_COMUNE = co.ID_COMUNE
                    and   co.ID_PROVINCIA = prov.ID_PROVINCIA
                    and   ci.FLG_VIRTUALE = 'N'
                    and   com.ID_SOGGETTO_DI_PIANO = sog.ID_SOGGETTO_DI_PIANO
                    and   pia.ID_PIANO = pa.ID_PIANO
                    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
                    and   pia.COD_AREA = ar.COD_AREA
                    and   pia.ID_RESPONSABILE_CONTATTO = responsabile.COD_INTERL
                    and   pia.id_cliente = cliente.COD_INTERL
                    and   rag.ID_PIANO = pia.ID_PIANO
                    and   rag.ID_VER_PIANO = pia.ID_VER_PIANO
                    and   rag.ID_AGENZIA = agenzia.COD_INTERL
                    and   rag.ID_VENDITORE_CLIENTE = venditore.COD_INTERL
                    and   pa.ID_PRODOTTO_ACQUISTATO= p_id_prodotto_acquistato
                    and   com.DATA_EROGAZIONE_PREV = p_data_proiezione
                    and   com.id_sala=p_id_sala
                    and   mat_pia.id_piano  = pia.id_piano   
                    and   mat_pia.ID_VER_PIANO  = pia.id_ver_piano
                    and   mat_pia.ID_MATERIALE_DI_PIANO  = nvl(com.ID_MATERIALE_DI_PIANO, mat_pia.ID_MATERIALE_DI_PIANO)
                    group by  pa.id_prodotto_acquistato,ar.cod_area,ar.descrizione_estesa,responsabile.RAG_SOC_COGN,cliente.RAG_SOC_COGN,agenzia.RAG_SOC_COGN,venditore.rag_soc_cogn,ci.NOME_CINEMA, co.COMUNE,prov.ABBR,
                              pa.DATA_INIZIO,pa.DATA_FINE, cir.NOME_CIRCUITO  , br.DESC_TIPO_BREAK , coef.durata,sog.DESCRIZIONE,com.DATA_EROGAZIONE_PREV,com.id_sala, sa.nome_sala,mat_pia.id_materiale;
                  return v_certificazione;
     end  fu_dett_certificazione_estesa;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_POST_VALUT_SPETT
--
-- DESCRIZIONE:  Funzione che permette di recuperare un prospetto
--               delle sale dove e andato in onda uno specifico cliente 
--               indicato attraverso l'identificativo del piano.
--               Nel prospetto vengono evidenziate, tra le altre, informazioni su:
--               - Numero di Sale con stessa data di trasmissione
--               - Numero di spettatori del gruppo di sale in esame
--               - Data di trasmissione
--
--
-- INPUT:
--      P_ID_PIANO          identificativo del piano
--      P_ID_VER_PIANO      identificativo della versione di piano
--
-- OUTPUT: lista di gruppi di sale omogenee in funzione 
--         della data di messa in onda
--          
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Aprile 2011
--
--  MODIFICHE:  Antonio Colucci, Teoresi srl, 12 Settembre 2011
--              Inserita la media giornaliera degli spettatori nella estrazione
--             
-------------------------------------------------------------------------------------------------
FUNCTION FU_POST_VALUT_SPETT    ( P_ID_PIANO               CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                  P_ID_VER_PIANO           CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE
                                ) RETURN C_POST_VALUT_SPETT
IS
V_POST_VALUT_SPETT C_POST_VALUT_SPETT;
BEGIN
    open V_POST_VALUT_SPETT for
    select distinct
            data_erogazione, 
            num_sale, 
            spettatori,
            ciclo_chiuso,
            data_iniz,
            data_fine,
           case
            when ciclo_chiuso = 'SI' then 
                floor(
                ((select sum(cd_spettatori_eff.num_spettatori) from cd_spettatori_eff where data_riferimento between  data_iniz and data_fine)/(data_fine-data_iniz+1)
                /
                (select count(distinct cd_spettatori_eff.id_sala) from cd_spettatori_eff
                where data_riferimento between data_iniz and data_fine))
                *num_sale)
            else    0
        end media_spett_giorno,
        /*(((select sum(cd_spettatori_eff.num_spettatori) from cd_spettatori_eff where data_riferimento between  data_iniz and data_fine))/(data_fine-data_iniz+1)
                /
                (select count(distinct cd_spettatori_eff.id_sala) from cd_spettatori_eff
                where data_riferimento between data_iniz and data_fine
                and num_spettatori > 0)) media_per_sala,
        ((select sum(cd_spettatori_eff.num_spettatori) from cd_spettatori_eff where data_riferimento between  data_iniz and data_fine))/(data_fine-data_iniz+1) speet_div_periodo,*/
        (select count(distinct cd_spettatori_eff.id_sala) from cd_spettatori_eff
                where data_riferimento between data_iniz and data_fine) num_sale_periodo,
        (select sum(cd_spettatori_eff.num_spettatori) from cd_spettatori_eff where data_riferimento between  data_iniz and data_fine) sum_spett
        from
        (
        select
            data_erogazione, 
            num_sale, 
            spettatori,
            ciclo_chiuso,
            min(data_iniz) over (partition by ciclo) data_iniz, 
            max(data_fine) over (partition by ciclo) data_fine
        from
        (
        select distinct
            data_erogazione, 
            count(distinct spot.id_sala) over (partition by data_erogazione)num_sale, 
            sum(cd_spettatori_eff.NUM_SPETTATORI) over (partition by data_erogazione) spettatori,
            (select 
                case
                    when max(data_fine) > trunc(sysdate) then 'NO'
                    else 'SI'
                end ciclo_chiuso
            from periodi
            where ciclo in (
                            select  ciclo 
                            from    periodi 
                            where data_erogazione between data_iniz and data_fine
                          )
            and anno = to_char(data_erogazione,'YYYY')
            )ciclo_chiuso
        from
            cd_spettatori_eff,
                 (
                 select   distinct
                          cd_comunicato.data_erogazione_prev data_erogazione, 
                          cd_comunicato.id_prodotto_acquistato, 
                          cd_comunicato.id_sala
                 from
                          cd_cinema,
                          cd_sala,
                          cd_comunicato,
                          cd_prodotto_acquistato
                  where   cd_prodotto_acquistato.id_piano = p_id_piano
                  and     cd_prodotto_acquistato.id_ver_piano = nvl(p_id_ver_piano,cd_prodotto_acquistato.id_ver_piano)
                  and     cd_prodotto_acquistato.flg_annullato = 'N'
                  and     cd_comunicato.id_prodotto_acquistato  = cd_prodotto_acquistato.id_prodotto_acquistato
                  and     cd_comunicato.flg_annullato = 'N'
                  and     cd_comunicato.cod_disattivazione is null
                  and     cd_comunicato.flg_sospeso = 'N'
                  and     cd_sala.flg_arena = 'N'
                  and     cd_sala.id_sala = cd_comunicato.ID_SALA
                  and     cd_cinema.id_cinema = cd_sala.id_cinema
                  and     cd_cinema.flg_virtuale = 'N'
                 ) spot
         where   cd_spettatori_eff.DATA_RIFERIMENTO(+) = spot.data_erogazione
         and     cd_spettatori_eff.ID_SALA(+) = spot.ID_SALA
         )spettatori,periodi
         where  ciclo in (
                            select  ciclo 
                            from    periodi 
                            where spettatori.data_erogazione between data_iniz and data_fine
                          )
         and    anno = to_char(spettatori.data_erogazione,'YYYY')
         )complessivo
         order by data_erogazione;
   return V_POST_VALUT_SPETT;
END FU_POST_VALUT_SPETT;
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_POST_VALUT_PIANO
--
-- DESCRIZIONE:  Funzione che permette di recuperare un prospetto
--               delle sale dove e andato in onda uno specifico cliente 
--               indicato attraverso l'identificativo del piano.
--               Nel prospetto vengono evidenziate, tra le altre, informazioni su:
--               - Numero di Sale con stessa posizione di trasmissione,data,durata
--               - Posizione di trasmissione
--               - Numero di spettatori del gruppo di sale in esame
--               - Tipo di break in cui e stato trasmesso
--
--
-- INPUT:
--      P_ID_PIANO          identificativo del piano
--      P_ID_VER_PIANO      identificativo della versione di piano
--
-- OUTPUT: lista di gruppi di sale omogenee in funzione 
--         di posizione di trasmissione,data,durata
--          
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Aprile 2011
--
--  MODIFICHE: 
--             
-------------------------------------------------------------------------------------------------
FUNCTION FU_POST_VALUT_PIANO    ( P_ID_PIANO               CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                  P_ID_VER_PIANO           CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                  P_ORDINAMENTO            number
                                ) RETURN C_POST_VALUT_PIANO
IS
V_POST_VALUT_PIANO  C_POST_VALUT_PIANO;
V_DATA_INIZIO       DATE;
V_DATA_FINE         DATE;
BEGIN
    SELECT  MIN(DATA_INIZIO),MAX(DATA_FINE)
    INTO    V_DATA_INIZIO,V_DATA_FINE
    FROM    CD_PRODOTTO_ACQUISTATO
    WHERE   ID_PIANO = P_ID_PIANO
    AND     ID_VER_PIANO = nvl(p_id_ver_piano,id_ver_piano);
--    
    open V_POST_VALUT_PIANO for
    /*ESTRAGGO, TRA GLI ALTRI, NUMERO DELLE SALE E SOMMA DEGLI SPETTATORI PER GRUPPO DI SALE*/
        select distinct
            data_erogazione,
            posizione,
            count(id_sala) over (partition by data_erogazione,posizione,durata) num_sale,
            sum(num_spettatori) over (partition by data_erogazione,posizione,durata) totale_spett,
            durata,
            round(avg(DURATA_BREAK) over (partition by data_erogazione,posizione,durata)) durata_break_media,
            desc_tipo_break
        from
        (
            with comunicati_previsti as
            (   /*RECUPERO LE INFORMAZIONI RELATIVE ALL'INSIEME DEI COMUNICATI NELLE SALE
                  GESTENDO LE POSIZIONI RELATIVE IN FUNZIONE DEL NUMERO DI COMUNICATI
                  COMPLESSIVO NELLA SALA-GIORNO-BREAK
                */
                select 
                  id_sala,
                  posizione,
                  num_comunicati,
                  ROW_NUMBER() OVER (PARTITION BY data_erogazione,id_break ORDER BY posizione) posizione_relativa,
                  durata,
                  durata_break,
                  data_erogazione,
                  id_prodotto_acquistato,
                  id_break,
                  desc_tipo_break
            from
                (   
                    select  distinct
                            cd_comunicato.id_sala,
                            posizione,
                            count(id_comunicato) over (partition by cd_comunicato.data_erogazione_prev,cd_comunicato.id_break) num_comunicati,
                            cd_materiale.durata,
                            sum(cd_materiale.durata) over (partition by cd_comunicato.data_erogazione_prev,cd_comunicato.id_break) durata_break,
                            data_erogazione_prev data_erogazione,
                            cd_comunicato.id_prodotto_acquistato,
                            min(cd_comunicato.id_break) over (partition by cd_comunicato.data_erogazione_prev,cd_comunicato.id_sala,cd_comunicato.id_prodotto_acquistato) id_break,
                            desc_tipo_break
                    from    cd_comunicato,cd_break,
                            cd_tipo_break,
                            cd_materiale,
                            cd_materiale_di_piano,
                            cd_sala,
                            cd_cinema
                    where   cd_comunicato.data_erogazione_prev between V_DATA_INIZIO and V_DATA_FINE
                    and     cd_comunicato.flg_annullato = 'N'
                    and     cd_comunicato.flg_sospeso = 'N'
                    and     cd_comunicato.cod_disattivazione is null
                    and     cd_comunicato.id_break = cd_break.id_break
                    and     cd_break.id_tipo_break = cd_tipo_break.id_tipo_break
                    and     cd_comunicato.id_materiale_di_piano = cd_materiale_di_piano.id_materiale_di_piano
                    and     cd_materiale_di_piano.id_materiale = cd_materiale.id_materiale
                    and     cd_comunicato.id_sala = cd_sala.id_sala
                    and     cd_sala.id_cinema = cd_cinema.id_cinema
                    and     cd_cinema.flg_virtuale = 'N'
                )
            )
            /*EVIDENZIO LE EVENTUALI POSIZIONI ULTIMA-PENULTIMA
              ED
              RICAVO GLI SPETTATORI COMPLESSIVA PER SALA-GIORNO*/
            select  distinct
                    comunicati_previsti.id_sala,
                    case
                        when posizione_relativa = num_comunicati then 'Ultima'
                        when posizione_relativa = (num_comunicati-1) then 'Penultima'
                        else ''||posizione_relativa
                    end posizione,
                    durata,
                    durata_break,
                    data_erogazione,
                    sum(num_spettatori) over (partition by cd_spettatori_eff.id_sala,data_riferimento) num_spettatori,
                    desc_tipo_break
            from
                    comunicati_previsti,
                    cd_prodotto_acquistato,
                    cd_spettatori_eff
            where   comunicati_previsti.id_prodotto_acquistato = cd_prodotto_acquistato.id_prodotto_acquistato
            and     cd_prodotto_acquistato.id_piano = p_id_piano
            and     cd_prodotto_acquistato.id_ver_piano = nvl(p_id_ver_piano,cd_prodotto_acquistato.id_ver_piano)
            and     comunicati_previsti.id_sala = cd_spettatori_eff.id_sala(+)
            and     comunicati_previsti.data_erogazione = cd_spettatori_eff.data_riferimento(+)
        )comunicati_previsti
        /*ORDINAMENTI PREVISTI
            Vengono inseriti dei null perche la decode tratta solo
            tipi di dati omogenei*/
        /* p_ordinamento = 1)durata_break_media, data_erogazione, posizione*/
        /* p_ordinamento = 2) posizione, data_erogazione, durata_break_media  */
        /* p_ordinamento = 3 - else - data_erogazione, posizione  */
        order by decode(p_ordinamento,1,durata_break_media,2,null,/*else*/null)
        ,decode(p_ordinamento,1,null,2,posizione,/*else*/null)
        ,decode(p_ordinamento,1,data_erogazione,2,data_erogazione,/*else*/data_erogazione)
        ,decode(p_ordinamento,1,posizione,2,null,/*else*/null)
        ,decode(p_ordinamento,1,null,2,durata_break_media,/*else*/null)
        ,decode(p_ordinamento,1,null,2,null,/*else*/posizione);
    return V_POST_VALUT_PIANO;
END FU_POST_VALUT_PIANO;
--
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_POST_VALUT_FILM
--
-- DESCRIZIONE:  Funzione che permette di recuperare un prospetto
--               delle sale dove e andato in onda uno specifico cliente 
--               indicato attraverso l'identificativo del piano.
--               Nel prospetto vengono evidenziate, tra le altre, informazioni su:
--               - Nome dello spettacolo
--               - Genere dello spettacolo
--               - Data di prima messa in onda dello spettacolo
--               - Data di ultima messa in onda dello spettacolo
--               - Numero di sale con stesso film per il piano in esame
--
--
-- INPUT:
--      P_ID_PIANO          identificativo del piano
--      P_ID_VER_PIANO      identificativo della versione di piano
--
-- OUTPUT: lista di gruppi di sale omogenee in funzione 
--         di spettacolo e genere
--          
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Aprile 2011
--
--  MODIFICHE: 
--             
-------------------------------------------------------------------------------------------------
FUNCTION FU_POST_VALUT_FILM    (P_ID_PIANO               CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                P_ID_VER_PIANO           CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE
                               ) RETURN C_POST_VALUT_FILM
IS
V_POST_VALUT_FILM C_POST_VALUT_FILM;
BEGIN
    open V_POST_VALUT_FILM for
        select distinct
            data_inizio,
            data_fine, 
            nome_spettacolo, 
            genere,
            target,
            num_sale,
            sum(num_spettatori) over (partition by aaa.id_spettacolo) tot_spettatori
        from
        (
            select distinct
                elenco_dati.id_spettacolo,
                data_inizio,
                data_fine, 
                nome_spettacolo, 
                genere,
                vencd.fu_cd_string_agg(nome_target) over (partition by elenco_dati.id_spettacolo) target,
                num_sale
            from
            (
                select distinct
                        id_spettacolo,
                        min(data) over (partition by id_spettacolo) data_inizio, 
                        max(data) over (partition by id_spettacolo) data_fine, 
                        nome_spettacolo, 
                        genere,
                        sum(num_sale) over (partition by id_spettacolo) num_sale
                from
                (    
                    select distinct
                        data,
                        cd_spettacolo.id_spettacolo,
                        cd_spettacolo.nome_spettacolo,
                        cd_genere.id_genere,
                        cd_genere.desc_genere genere,
                        count(distinct spot.id_sala) over (partition by data,cd_spettacolo.id_spettacolo)num_sale
                    from
                        cd_genere,
                        cd_spettacolo,
                        cd_proiezione_spett,
                        cd_proiezione,
                        cd_schermo,
                        (
                            select distinct
                              cd_comunicato.data_erogazione_prev data, 
                              cd_comunicato.id_prodotto_acquistato, 
                              cd_comunicato.id_sala
                            from
                              cd_cinema,
                              cd_sala,
                              cd_comunicato,
                              cd_prodotto_acquistato
                            where cd_prodotto_acquistato.id_piano = p_id_piano
                            and cd_prodotto_acquistato.id_ver_piano = nvl(p_id_ver_piano,cd_prodotto_acquistato.id_ver_piano)
                            and cd_prodotto_acquistato.flg_annullato = 'N'
                            and cd_comunicato.id_prodotto_acquistato  = cd_prodotto_acquistato.id_prodotto_acquistato
                            and cd_comunicato.flg_annullato = 'N'
                            and cd_comunicato.cod_disattivazione is null
                            and cd_comunicato.flg_sospeso = 'N'
                            and cd_sala.id_sala = cd_comunicato.ID_SALA
                            and cd_cinema.id_cinema = cd_sala.id_cinema
                            and cd_cinema.flg_virtuale = 'N'
                        ) spot
                    where cd_schermo.id_sala = spot.id_sala
                    and   cd_proiezione.data_proiezione = spot.data
                    and   cd_proiezione.id_schermo = cd_schermo.id_schermo
                    and   cd_proiezione_spett.id_proiezione = cd_proiezione.id_proiezione
                    and   cd_spettacolo.id_spettacolo = cd_proiezione_spett.id_spettacolo
                    and   cd_genere.id_genere=cd_spettacolo.id_genere
                )order by nome_spettacolo
            )elenco_dati,
             cd_target,
             cd_spett_target
            where 
                elenco_dati.id_spettacolo = cd_spett_target.id_spettacolo
            and cd_spett_target.id_target = cd_target.id_target
        )aaa,cd_spettatori_eff
        where   aaa.id_spettacolo = cd_spettatori_eff.id_spettacolo
        and     cd_spettatori_eff.data_riferimento between aaa.data_inizio and aaa.data_fine
        order by genere,nome_spettacolo;
    return V_POST_VALUT_FILM;
END FU_POST_VALUT_FILM;     


FUNCTION fu_asterisco_sala_variabile(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN varchar2 IS
v_return  varchar2(1) := 'N';
begin
    select decode(count(1),0,'N','S')
    into v_return 
    from  cd_prodotto_acquistato pa, cd_prodotto_vendita pv
    where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
    and   pv.id_prodotto_vendita = pa.id_prodotto_vendita
    and   pa.flg_annullato ='N'
    and   pa.flg_sospeso ='N'
    and   pa.COD_DISATTIVAZIONE is null
    and   (pv.id_target is not null or pv.flg_segui_il_film ='S')
    and   pa.flg_ricalcolo_tariffa = 'N';
return v_return;
END fu_asterisco_sala_variabile;
/**
    Antonio Colucci, Teoresi srl, 23/05/2011
    Funzione che permette di ottenere la ragione sociale
    del cliente dato l'ID DEL PIANO
**/
FUNCTION fu_nome_cliente(p_id_piano cd_pianificazione.id_piano%type) RETURN varchar2
IS
v_return  varchar2(100);
begin
select 
        rag_soc_cogn
        into  v_return
from 
cd_pianificazione,interl_u
where id_piano = p_id_piano
and cd_pianificazione.ID_CLIENTE = interl_u.COD_INTERL;
return v_return;
end;                


---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_PROD_CERTIFICAZIONE
--
-- DESCRIZIONE:  Ritorna l'elenco dei prodotti acquistati necessari per la certificazione piani
--
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: lista di c_prodotto
--          
--
-- REALIZZATORE: Tommaso D'Anna, 26 Maggio 2011
--
--  MODIFICHE: 
--          Tommaso D'Anna, Teoresi s.r.l., 10 Giugno 2011
--              Esclusione delle arene dalla stampa       
-------------------------------------------------------------------------------------------------
 FUNCTION FU_GET_PROD_CERTIFICAZIONE(  p_id_piano       CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                       p_id_ver_piano   CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                       p_data_inizio    CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine      CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE 
     ) RETURN C_PRODOTTO is
 V_PRODOTTO  C_PRODOTTO; 
 BEGIN
    OPEN V_PRODOTTO FOR
    SELECT ID_PRODOTTO_ACQUISTATO,DATA_INIZIO,DATA_FINE
    FROM 
        CD_PRODOTTO_ACQUISTATO PA,
        CD_PRODOTTO_VENDITA PV,
        CD_CIRCUITO CI
    WHERE PA.ID_PIANO       =   nvl(p_id_piano,     PA.ID_PIANO)
    AND   PA.ID_VER_PIANO   =   nvl(p_id_ver_piano, PA.ID_VER_PIANO)
    AND   PA.DATA_INIZIO    <=  nvl(p_data_fine,    PA.DATA_FINE)
    AND   PA.DATA_FINE      >=  nvl(p_data_inizio,  PA.DATA_INIZIO)
    AND   PA.FLG_ANNULLATO  =   'N'
    AND   PA.FLG_SOSPESO    =   'N'
    AND   PA.COD_DISATTIVAZIONE IS NULL
    AND   PA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
    AND   PV.ID_CIRCUITO = CI.ID_CIRCUITO
    AND   CI.FLG_ARENA = 'N'
    ORDER BY PA.DATA_INIZIO, PA.DATA_FINE;
    RETURN V_PRODOTTO;
 END FU_GET_PROD_CERTIFICAZIONE;
 
 function fu_get_numero_proiezioni(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, 
                                   p_id_prodotti_richiesti cd_prodotti_richiesti.id_prodotti_richiesti%type
                                   ) return number is
 v_data_inizio cd_prodotto_acquistato.data_inizio%type;
 v_data_fine cd_prodotto_acquistato.data_fine%type;
 v_flg_arena cd_circuito.flg_arena%type;
 v_numero_ambienti  number;
 v_fatt number;
 begin
 
 
 
 if p_id_prodotto_acquistato is not null then
    select 
        data_inizio,
        data_fine,
        flg_arena 
        into
        v_data_inizio,
        v_data_fine,
        v_flg_arena
    from    cd_prodotto_acquistato pa,
            cd_prodotto_vendita pv,
            cd_circuito cir
    where   pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and     pv.id_circuito = cir.id_circuito
    and     pa.id_prodotto_acquistato = p_id_prodotto_acquistato;
     v_numero_ambienti := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato);
 
 else
    if p_id_prodotti_richiesti is not null then
    
        --(PA_CD_PRODOTTO_RICHIESTO.FU_GET_NUM_AMBIENTI(pr.id_prodotti_richiesti) * V_FATTORE_MOLT_PROIEZ_ATTESE * (pr.data_fine - pr.data_inizio + 1)) as numProiezioni, -- al momento resituisco sempre 4 proiez al giorno per ogni schermo!
        select 
            data_inizio,
            data_fine,
            flg_arena 
            into
            v_data_inizio,
            v_data_fine,
            v_flg_arena
        from    cd_prodotti_richiesti pr,
                cd_prodotto_vendita pv,
                cd_circuito cir
        where   pr.id_prodotto_vendita = pv.id_prodotto_vendita
        and     pv.id_circuito = cir.id_circuito
        and     pr.id_prodotti_richiesti = p_id_prodotti_richiesti;
        v_numero_ambienti := PA_CD_PRODOTTO_RICHIESTO.FU_GET_NUM_AMBIENTI(p_id_prodotti_richiesti);
    else
        return 0; --non e mai possibile xche almeno uno dei due parametri deve essere valorizzario.
    end if;
    
 end if;
 
 if v_flg_arena ='S' then
    v_fatt :=  V_FATTORE_MOLT_PROIEZ_ARENA;
 else
    v_fatt :=  V_FATTORE_MOLT_PROIEZ_ATTESE;
 end if;
 
 return (v_numero_ambienti * v_fatt * (v_data_fine - v_data_inizio + 1));
 
 end fu_get_numero_proiezioni;
 
 

 
END pa_cd_stampe_magazzino; 
/

