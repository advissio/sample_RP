CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PRODOTTO_ACQUISTATO
IS
-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_CIRCUITO
--
-- DESCRIZIONE:  Restituisce tutti i circuiti presenti sul sistema
--
-- OPERAZIONI:
--   1) Seleziona tutti i circuiti presenti sul sistema
--
-- INPUT:
--
-- OUTPUT:
--    Cursore con i circuiti presenti nel sistema
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_CIRCUITO RETURN C_CIRCUITO IS
CUR C_CIRCUITO;
BEGIN
    OPEN CUR FOR
    SELECT ID_CIRCUITO,
           NOME_CIRCUITO
    FROM CD_CIRCUITO;
  RETURN CUR;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END  FU_CERCA_CIRCUITO;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_PRODOTTO_PUBB
--
-- DESCRIZIONE:  Restituisce tutti i prodotti pubblicitari presenti sul sistema
--
-- OPERAZIONI:
--   1) Seleziona tutti i prodotti pubblicitari presenti sul sistema
--
-- INPUT:
--
-- OUTPUT:
--    Cursore con i prodotti pubblicitari presenti nel sistema
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PRODOTTO_PUBB RETURN C_PRODOTTO_PUBB IS
CUR C_PRODOTTO_PUBB;
BEGIN
    OPEN CUR FOR
    SELECT ID_PRODOTTO_PUBB,
           DESC_PRODOTTO
    FROM CD_PRODOTTO_PUBB;
  RETURN CUR;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END  FU_CERCA_PRODOTTO_PUBB;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_MODALITA_VEND
--
-- DESCRIZIONE:  Restituisce le modalita di vendita presenti sul sistema
--
-- OPERAZIONI:
--   1) Seleziona le modalita di vendita presenti sul sistema
--
-- INPUT:
--
-- OUTPUT:
--    Cursore le modalita di vendita presenti nel sistema
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_MODALITA_VEND RETURN C_MODALITA_VEND IS
CUR C_MODALITA_VEND;
BEGIN
    OPEN CUR FOR
    SELECT ID_MOD_VENDITA,
           DESC_MOD_VENDITA
    FROM CD_MODALITA_VENDITA;
  RETURN CUR;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END  FU_CERCA_MODALITA_VEND;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_ASSSOGG
--
-- DESCRIZIONE:  Cerca i comunicati associati ad un soggetto, raggruppati per prodotto acquistato; i parametri di input sono i filtri per
--               restringere il risultato della ricerca
--
-- OPERAZIONI:
--
--
-- INPUT:
--       P_ID_PIANO                   Id del piano
--       P_ID_VER_PIANO               Versione del piano
--       P_ID_SOGGETTO                Id del soggetto
--       P_ID_CIRCUITO                Id del circuito
--       P_ID_PRODOTTO_PUBLLICITARIO  Id del prodotto pubblicitario
--       P_ID_MODALITA_VENDITA        Id della modalita di vendita
--       P_DATA_INIZIO                Data di inizio del prodotto acquistato
--       P_DATA_FINE                  Data di fine del prodotto acquistato
--
-- OUTPUT:
--    Cursore le modalita di vendita presenti nel sistema
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_ASSSOGG(P_ID_PIANO CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                          P_ID_VER_PIANO CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                          P_ID_SOGGETTO  CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                          P_ID_CIRCUITO  CD_CIRCUITO.ID_CIRCUITO%TYPE,
                          P_ID_PRODOTTO_PUBLLICITARIO CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
                          P_ID_MODALITA_VENDITA CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
                          P_DATA_INIZIO  DATE,
                          P_DATA_FINE    DATE)
                          RETURN C_ASSSOGG IS
CUR C_ASSSOGG;
BEGIN
  OPEN CUR FOR
  --comunicati
select PRP.DESC_PRODOTTO     AS DESCRIZIONE,
       CIR.NOME_CIRCUITO     AS NOME_CIRCUITO,
       SUM(PAQ.IMP_NETTO)    AS NETTO,
       SUM(PAQ.IMP_LORDO)    AS LORDO,
   --    MIN(PAQ.IMP_SC_COMM) AS PERC_SC,
       0 AS PERC_SC,
       decode(FOA.ID_TIPO_FORMATO,2,FOA.DESCRIZIONE,NULL) AS FORMATO,
       PAQ.ID_PRODOTTO_ACQUISTATO,
       COUNT(BDV.ID_BREAK_VENDITA) AS NUM_COMUNICATI,
       NULL AS NUM_SALE,
       NULL AS NUM_CINEMA,
       NULL AS NUM_ATRII
 from  CD_PRODOTTO_ACQUISTATO PAQ,
       CD_COMUNICATO COM,
       CD_FORMATO_ACQUISTABILE FOA,
       CD_PRODOTTO_PUBB PRP,
       CD_MISURA_PRD_VENDITA MIS,
       CD_BREAK_VENDITA   BDV,
       CD_CIRCUITO CIR,
       CD_CIRCUITO_BREAK CBR,
       CD_PIANIFICAZIONE PIA
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   (P_ID_SOGGETTO is NULL or COM.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
 and   (P_ID_CIRCUITO is NULL or CIR.ID_CIRCUITO = P_ID_CIRCUITO)
 and   (P_DATA_INIZIO IS NULL OR PAQ.DATA_INIZIO <= P_DATA_INIZIO)
 and   (P_DATA_FINE IS NULL OR PAQ.DATA_FINE >= P_DATA_FINE)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_BREAK_VENDITA = BDV.ID_BREAK_VENDITA
 and   CBR.ID_CIRCUITO_BREAK = BDV.ID_CIRCUITO_BREAK
 and   CBR.ID_CIRCUITO = CIR.ID_CIRCUITO
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
   --    MIN(PAQ.IMP_SCO_COMM) AS PERC_SC,
   0 AS PERC_SC,
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
       CD_CIRCUITO_CINEMA CCI
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   (P_ID_SOGGETTO is NULL or COM.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
 and   (P_ID_CIRCUITO is NULL or CIR.ID_CIRCUITO = P_ID_CIRCUITO)
 and   (P_ID_PRODOTTO_PUBLLICITARIO is null OR PRP.ID_PRODOTTO_PUBB=P_ID_PRODOTTO_PUBLLICITARIO)
 and   (P_DATA_INIZIO IS NULL OR PAQ.DATA_INIZIO <= P_DATA_INIZIO)
 and   (P_DATA_FINE IS NULL OR PAQ.DATA_FINE >= P_DATA_FINE)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_CINEMA_VENDITA = CDV.ID_CINEMA_VENDITA
 and   CCI.ID_CIRCUITO_CINEMA = CDV.ID_CIRCUITO_CINEMA
 and   CCI.ID_CIRCUITO = CIR.ID_CIRCUITO
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
 --      MIN(PAQ.IMP_SCO_COMM) AS PERC_SC,
       0 AS PERC_SC,
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
       CD_CIRCUITO_SALA CIS
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   (P_ID_SOGGETTO is NULL or COM.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
 and   (P_ID_CIRCUITO is NULL or CIR.ID_CIRCUITO = P_ID_CIRCUITO)
 and   (P_ID_PRODOTTO_PUBLLICITARIO is null OR PRP.ID_PRODOTTO_PUBB=P_ID_PRODOTTO_PUBLLICITARIO)
 and   (P_DATA_INIZIO IS NULL OR PAQ.DATA_INIZIO <= P_DATA_INIZIO)
 and   (P_DATA_FINE IS NULL OR PAQ.DATA_FINE >= P_DATA_FINE)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_SALA_VENDITA = CSV.ID_SALA_VENDITA
 and   CIS.ID_CIRCUITO_SALA = CSV.ID_CIRCUITO_SALA
 and   CIS.ID_CIRCUITO = CIR.ID_CIRCUITO
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
 --      MIN(PAQ.IMP_SCO_COMM) AS PERC_SC,
 0 AS PERC_SC,
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
       CD_CIRCUITO_ATRIO CAT
 where
       1=1
 and   (P_ID_PIANO IS NULL OR PAQ.ID_PIANO = P_ID_PIANO)
 and   (P_ID_VER_PIANO IS NULL OR PAQ.ID_VER_PIANO = P_ID_VER_PIANO)
 and   (P_ID_SOGGETTO is NULL or COM.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
 and   (P_ID_CIRCUITO is NULL or CIR.ID_CIRCUITO = P_ID_CIRCUITO)
 and   (P_ID_PRODOTTO_PUBLLICITARIO is null OR PRP.ID_PRODOTTO_PUBB=P_ID_PRODOTTO_PUBLLICITARIO)
 and   (P_DATA_INIZIO IS NULL OR PAQ.DATA_INIZIO <= P_DATA_INIZIO)
 and   (P_DATA_FINE IS NULL OR PAQ.DATA_FINE >= P_DATA_FINE)
 and   PAQ.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
 and   FOA.ID_FORMATO = PAQ.ID_FORMATO
 and   MIS.id_misura_prd_ve = PAQ.ID_MISURA_PRD_VE
 and   PRP.ID_PRODOTTO_PUBB = MIS.ID_PRODOTTO_PUBB
 and   COM.ID_ATRIO_VENDITA = CAV.ID_ATRIO_VENDITA
 and   CAT.ID_CIRCUITO_ATRIO = CAV.ID_CIRCUITO_ATRIO
 and   CAT.ID_CIRCUITO = CIR.ID_CIRCUITO
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

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_PRODOTTO_ACQUIST
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un prodotto acquistato dal sistema
--
-- OPERAZIONI:
--   1) Elimina il prodotto acquistato
--
-- INPUT:
--      p_id_prodotto_acquistato    id del prodotto acquistato
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_PRODOTTO_ACQUIST(  p_id_prodotto_acquistato        IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_esito                            OUT NUMBER)
IS


--
BEGIN -- PR_ELIMINA_PRODOTTO_ACQUIST
--

p_esito     := 1;

     --
          SAVEPOINT ann_del;

       -- EFFETTUA L'eliminazione
       DELETE FROM CD_PRODOTTO_ACQUISTATO
       WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
       --

    p_esito := SQL%ROWCOUNT;

  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ELIMINA_PRODOTTO_ACQUISTATO: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI '||SQLERRM);
        ROLLBACK TO ann_del;

END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_PRODOTTO_ACQUIST
-- DESCRIZIONE:  Esegue l'annullamento di un prodotto acquistato
--
-- OPERAZIONI:
--   1) Annulla il prodotto acquistato
--
-- INPUT:
--      p_id_prodotto_acquistato    id del prodotto acquistato
--      p_chiamante                 discriminante sul chiamante in base al quale possono cambiare le
--                                  operazioni effettuate in questa fase di annullamento
--                                  i valori ammessi sono PAL (palinsesto) MAG (magazzino)
--                                  MIO (messa in onda) CAM (Completamento Amministrativo)
-- OUTPUT: esito:
--    1   annullamento eseguito dal Palinsesto
--    2   annullamento eseguito dal Magazzino
--    3   annullamento eseguito dalla Messa in onda
--    4   annullamento eseguito dal Completamento amministrativo
--  100   annullamento NON effettuato, il chiamante non e' stato riconosciuto
--   -11  Annullamento non eseguito, si e' verificato un errore
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Settembre 2009
--
--  MODIFICHE: Simone Bottani, Altran, Febbraio 2010 (aggiunta la chiamata a PR_ELIMINA_BUCO_POSIZIONE)
--             Mauro Viel, Altran, Novembre 2010 (aggiunta gestione della fatturazione: se un prodotto e stato
--                                                trattato dalla fatturazione non gli annullo raggruppamento intermediari e fruitori)
--             Mauro Viel, Altran, Gennaio  2011 aggiunta la chiamata alla procedura PR_AGGIORNA_SINTESI_PRODOTTO 
--                                               in modo da mantenere aggionata la situazioen del venduto.
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_PRODOTTO_ACQUIST(p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                      p_chiamante              VARCHAR2,
                                      p_esito                  IN OUT NUMBER)
IS
v_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
v_fatturazione number;
BEGIN
    select count(1) into v_fatturazione
    from cd_importi_prodotto ip , cd_importi_fatturazione impf
    where ip.id_prodotto_acquistato = p_id_prodotto_acquistato
    and   impf.ID_IMPORTI_PRODOTTO = ip.ID_IMPORTI_PRODOTTO
    and   impf.STATO_FATTURAZIONE in ('DAR','TRA');
    p_esito := 100;
    SAVEPOINT SP_PR_ANNULLA_PRODOTTO_ACQUIST;
    IF(p_chiamante='PAL')THEN
        p_esito:=1;
        if v_fatturazione >0 then
            UPDATE CD_PRODOTTO_ACQUISTATO
            SET    FLG_ANNULLATO='S'
            WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
            AND    FLG_ANNULLATO='N'
            AND    FLG_SOSPESO='N'
            AND    COD_DISATTIVAZIONE IS NULL;
        else
            UPDATE CD_PRODOTTO_ACQUISTATO
            SET    FLG_ANNULLATO='S', ID_FRUITORI_DI_PIANO=null,
                   ID_RAGGRUPPAMENTO = null
            WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
            AND    FLG_ANNULLATO='N'
            AND    FLG_SOSPESO='N'
            AND    COD_DISATTIVAZIONE IS NULL;
        end if;
    ELSE
        IF(p_chiamante='MAG')THEN
            p_esito:=2;
            if v_fatturazione >0 then
                UPDATE CD_PRODOTTO_ACQUISTATO
                SET    FLG_ANNULLATO='S'
                WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                AND    FLG_ANNULLATO='N'
                AND    FLG_SOSPESO='N'
                AND    COD_DISATTIVAZIONE IS NULL;
            else
            UPDATE CD_PRODOTTO_ACQUISTATO
                SET    FLG_ANNULLATO='S', ID_FRUITORI_DI_PIANO=null,
                       ID_RAGGRUPPAMENTO = null
                WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                AND    FLG_ANNULLATO='N'
                AND    FLG_SOSPESO='N'
                AND    COD_DISATTIVAZIONE IS NULL;
            end if;
        ELSE
            IF(p_chiamante='MIO')THEN
                p_esito:=3;
                if v_fatturazione >0 then
                    UPDATE CD_PRODOTTO_ACQUISTATO
                    SET    FLG_ANNULLATO='S'
                    WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                    AND    FLG_ANNULLATO='N'
                    AND    FLG_SOSPESO='N'
                    AND    COD_DISATTIVAZIONE IS NULL;
                else
                    UPDATE CD_PRODOTTO_ACQUISTATO
                    SET    FLG_ANNULLATO='S', ID_FRUITORI_DI_PIANO=null,
                           ID_RAGGRUPPAMENTO = null
                    WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                    AND    FLG_ANNULLATO='N'
                    AND    FLG_SOSPESO='N'
                    AND    COD_DISATTIVAZIONE IS NULL;
                end if;
            ELSE
                IF(p_chiamante='CAM')THEN
                    p_esito:=4;
                    if v_fatturazione >0 then
                        UPDATE CD_PRODOTTO_ACQUISTATO
                        SET    FLG_ANNULLATO='S'
                        WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                        AND    FLG_ANNULLATO='N'
                        AND    FLG_SOSPESO='N'
                        AND    COD_DISATTIVAZIONE IS NULL;
                    else
                        UPDATE CD_PRODOTTO_ACQUISTATO
                        SET    FLG_ANNULLATO='S', ID_FRUITORI_DI_PIANO=null,
                               ID_RAGGRUPPAMENTO = null
                        WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                        AND    FLG_ANNULLATO='N'
                        AND    FLG_SOSPESO='N'
                        AND    COD_DISATTIVAZIONE IS NULL;
                    end if;
                END IF;
            END IF;
        END IF;
    END IF;
    --
    SELECT STATO_DI_VENDITA
    INTO v_stato_vendita
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    --
    IF v_stato_vendita = 'PRE' THEN
        PR_ELIMINA_BUCO_POSIZIONE_PACQ(p_id_prodotto_acquistato);
    END IF;
    --
    PA_CD_ORDINE.PR_ANNULLA_ORDINE_PRD_ACQ(p_id_prodotto_acquistato);
    --Se il chiamante e MAG annullo anche tutti i comunicati del prodotto acquistato annullato
    IF (p_esito=2) THEN
        UPDATE CD_COMUNICATO
        SET    CD_COMUNICATO.FLG_ANNULLATO='S'
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_ANNULLATO='N'
        AND    FLG_SOSPESO='N'
        AND    COD_DISATTIVAZIONE IS NULL;
    END IF;
    
    PR_AGGIORNA_SINTESI_PRODOTTO(p_id_prodotto_acquistato);
    
EXCEPTION
      WHEN OTHERS THEN
    p_esito:=-11;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ANNULLA_PRODOTTO_ACQUISTATO: non eseguita, si e'' verificato un errore '||SQLERRM);
    ROLLBACK TO SP_PR_ANNULLA_PRODOTTO_ACQUIST;
END PR_ANNULLA_PRODOTTO_ACQUIST;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_PRODOTTO_ACQUIST
-- DESCRIZIONE:  Esegue il recupero di un prodotto acquistato
--
-- OPERAZIONI:
--   1) Recupera il prodotto acquistato
--
-- INPUT:
--      p_id_prodotto_acquistato    id del prodotto acquistato
--      p_chiamante                 discriminante sul chiamante in base al quale possono cambiare le
--                                  operazioni effettuate in questa fase di annullamento
--                                  i valori ammessi sono PAL (palinsesto) MAG (magazzino)
--                                  MIO (messa in onda) CAM (Completamento Amministrativo)
-- OUTPUT: esito:
--    1   recupero eseguito dal Palinsesto
--    2   recupero eseguito dal Magazzino
--    3   recupero eseguito dalla Messa in onda
--    4   recupero eseguito dal Completamento amministrativo
--  100   recupero NON effettuato, il chiamante non e' stato riconosciuto
--   -11  recupero non eseguito, si e' verificato un errore
--
--  REALIZZATORE: Michele Borgogno, Altran, Ottobre 2009
--
--  MODIFICHE: 
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_PRODOTTO_ACQUIST  (p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_chiamante              VARCHAR2,
                                         p_esito                  OUT NUMBER)
IS
BEGIN
    p_esito := 100;
    SAVEPOINT SP_PR_REC_PRODOTTO_ACQUIST;
--    IF(p_chiamante='PAL')THEN
--        UPDATE CD_PRODOTTO_ACQUISTATO
--        SET    FLG_ANNULLATO='S'
--        WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
--        AND    FLG_ANNULLATO='N';
--        p_esito:=1;
--    ELSE
        IF(p_chiamante='MAG')THEN
            UPDATE CD_PRODOTTO_ACQUISTATO
               SET    FLG_ANNULLATO='N'
               WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
            AND    FLG_ANNULLATO='S';
            p_esito:=2;
        ELSE
--            IF(p_chiamante='MIO')THEN
--                p_esito:=3;
--                UPDATE CD_PRODOTTO_ACQUISTATO
--                SET    FLG_ANNULLATO='S'
--                WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
--                AND    FLG_ANNULLATO='N';
--            ELSE
--                IF(p_chiamante='CAM')THEN
--                    p_esito:=4;
--                    UPDATE CD_PRODOTTO_ACQUISTATO
--                    SET    FLG_ANNULLATO='S'
--                    WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
--                    AND    FLG_ANNULLATO='N';
--                END IF;
--            END IF;
            p_esito := 100;
        END IF;
        IF(p_esito=2) THEN
            UPDATE CD_COMUNICATO
               SET    FLG_ANNULLATO='N'
               WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
            AND    FLG_ANNULLATO='S';
        END IF;
--    END IF;
EXCEPTION
      WHEN OTHERS THEN
    p_esito:=-11;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_RECUPERA_PRODOTTO_ACQUISTATO: non eseguita, si e'' verificato un errore '||SQLERRM);
    ROLLBACK TO SP_PR_REC_PRODOTTO_ACQUIST;
END;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_SOSPENDI_PRODOTTO_ACQUIST
-- DESCRIZIONE:  Sospende un prodotto acquistato
--
-- OPERAZIONI:
--   1) Sospende il prodotto acquistato
--
-- INPUT:
--      p_id_prodotto_acquistato    id del prodotto acquistato

--  REALIZZATORE: Michele Borgogno, Altran, Novembre 2009
--
--  MODIFICHE: Mauro Viel,Altran, Aprile 2011 inserita la chiamata  alla procedura PR_AGGIORNA_SINTESI_PRODOTTO
--                                in modo che i prodotti sospesi non vengano mostrati al supporto vendita
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_SOSPENDI_PRODOTTO_ACQUIST (p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_esito                  IN OUT NUMBER)
IS
v_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
BEGIN
    p_esito := 100;
    SAVEPOINT SP_PR_ANNULLA_PRODOTTO_ACQUIST;

    UPDATE CD_PRODOTTO_ACQUISTATO
        SET    FLG_SOSPESO='S'
        WHERE  ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
         AND    FLG_SOSPESO='N';
         
        --Sospendo anche tutti i comunicati del prodotto acquistato sospeso

        UPDATE CD_COMUNICATO
        SET    CD_COMUNICATO.FLG_SOSPESO='S'
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_SOSPESO='N';
        
        --
        SELECT STATO_DI_VENDITA
        INTO v_stato_vendita
        FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
        
        --
        IF v_stato_vendita = 'PRE' THEN
            PR_ELIMINA_BUCO_POSIZIONE_PACQ(p_id_prodotto_acquistato);
        END IF;
       
        PR_AGGIORNA_SINTESI_PRODOTTO(p_id_prodotto_acquistato);
        --
       
EXCEPTION
      WHEN OTHERS THEN
    p_esito:=-11;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_SOSPENDI_PRODOTTO_ACQUISTATO: non eseguita, si e'' verificato un errore '||SQLERRM);
    ROLLBACK TO SP_PR_ANNULLA_PRODOTTO_ACQUIST;
END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_PROD_ACQ_MODULO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto acquistato di tipo modulo o geosplit
--               nel sistema, creando i relativi comunicati
--
--
-- OPERAZIONI:
--  1) Seleziona la descrizione dello stato di vendita
--  2) Seleziona il soggetto da associare ai comunicati. Se esiste un solo soggetto con descrizione
--     differente da 'SOGGETTO NON DEFINITO' viene associato quello
--  3) Seleziona la testata editoriale, il prodotto pubblicitario, il dgc
--  4) Calcola i valori di netto commerciale e direzionale
--  5) Inserisce il prodotto acquistato, verificando lo sconto stagionale e la tariffa in base al coefficiente cinema
--  6) Inserisce gli importi prodotto, commerciale e direzionale, legati al prodotto acquistato
--  7) Inserisce le informazioni sulle maggiorazioni e le aree nielsen collegate
--  8) Inserisce i comunicati, verificando se si tratta di un prodotto modulo o geosplit
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_id_formato            id del formato acquistabile
--  p_tariffa               importo di tariffa
--  p_lordo                 importo lordo
--  p_lordo_comm            importo lordo commerciale
--  p_lordo_dir             importo lordo direzionale
--  p_sconto_comm           importo di sconto commerciale
--  p_sconto_dir            importo di sconto direzionale
--  p_maggiorazione         importo di maggiorazione
--  p_unita_temp            unita temporale del prodotto inserito (Settimana, Mese ecc)
--  p_id_listino            id del listino utilizzato
--  p_num_ambiti            numero di ambienti per cui viene creato il prodotto acquistato
--  p_id_posizione_rigore   id della posizione di rigore, se richiesta
--  p_tariffa_variabile     flag che indica se il prodotto e da creare con tariffa variabile o meno (il flag puo assumere il valore S o N)
--  p_id_tipo_cinema        id del tipo cinema del prodotto di vendita
--  p_list_maggiorazioni    lista di maggiorazioni applicate al prodotto acquistato
--  p_list_id_area          lista di aree nielsen applicate al prodotto acquistato. Viene utilizzato solo se il prodotto e geo split
--
-- OUTPUT: p_esito:
--    1 Inserimento eseguito correttamente
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--         p_id_prod_acquistato
--    contiene l'ID del prodotto acquistato, valore che ha senso se p_esito vale 1
--
-- REALIZZATORE: Simone Bottani , Altran, Luglio 2009
--
--  MODIFICHE:
--  se e presente un solo cliente fruitore di piano viene associato al prodotto 05/01/2010 Michele Borgogno
--             Francesco Abbundo, Teoresi srl, Febbraio 2010
--             Aggiunto l'inserimento del COD_ATTIVAZIONE
--             e l'ID del prodotto acquistato appena inserito dalla procedura
--inserito il parametro id_spettacolo x l'implementazione di segui il film. 
--inserito il parametro numero_massimo_schermi x l'implementazione di segui il film.
--inserito il parametro numero_ambienti.
--Mauro Viel Altran Italia Novembre 2011 gestito il nuovo campo flg_esclusivo per il segui il film. Un nuovo prodotto nascera 
--                          con il campo flg_esclusivo impostato ad S. in fase d'associazione tale valore potraa essere variato.
--                          lo storico delle variazioni sara mantenuto dalla tavola cd_sala_segui_film.FLG_ESCLUSIVO. 
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_ACQ_MODULO (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_spettacolo         CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE,
    p_numero_massimo_schermi NUMBER,
    p_numero_ambienti        NUMBER,
    p_id_prod_acquistato    OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,      
    p_esito                 OUT NUMBER)
IS
--
v_id_soggetto_piano CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
v_seq_prev CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_seq CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_numero_comunicati NUMBER;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_tipo_pubb CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE;
v_stato_vendita CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
v_soggetto CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
v_dgc CD_PRODOTTO_ACQUISTATO.DGC%TYPE;
v_cod_testata CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE%TYPE;
v_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_comm CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_count_sogg NUMBER;
v_id_periodo CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
v_sala_arena varchar2(10);
v_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE;
v_num_comunicati NUMBER;
v_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE;
v_flg_segui_il_film CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE;
v_flg_esclusivo cd_prodotto_acquistato.flg_esclusivo%type;
BEGIN
--
p_esito     := 1;

         SAVEPOINT PR_CREA_PROD_ACQ_MODULO;

       SELECT DESCR_BREVE, ID_CLIENTE
       INTO v_stato_vendita, v_id_cliente
       FROM CD_PIANIFICAZIONE, CD_STATO_DI_VENDITA
       WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
       AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
       AND CD_STATO_DI_VENDITA.ID_STATO_VENDITA = CD_PIANIFICAZIONE.ID_STATO_VENDITA;
--
    SELECT COUNT(1)
    INTO v_count_sogg
    FROM CD_SOGGETTO_DI_PIANO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano;
--
      SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano
        AND (
          v_count_sogg = 1
        OR
          v_count_sogg = 2 AND DESCRIZIONE != 'SOGGETTO NON DEFINITO'
        OR
          v_count_sogg > 2
          AND DESCRIZIONE = 'SOGGETTO NON DEFINITO');
--
     BEGIN
       SELECT COD_TESTATA_EDITORIALE
       INTO v_cod_testata
       FROM CD_PIANIFICAZIONE
       WHERE ID_PIANO = p_id_piano
       AND ID_VER_PIANO = p_id_ver_piano;
--
       SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB,DECODE(FLG_ARENA,'S', 'ARENA','SALA'), CD_CIRCUITO.ID_CIRCUITO, CD_PRODOTTO_VENDITA.ID_TARGET,CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM
       INTO  v_id_tipo_pubb,v_sala_arena, v_id_circuito,v_id_target,v_flg_segui_il_film
       FROM  CD_PRODOTTO_VENDITA,CD_CIRCUITO
       WHERE CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
       AND   CD_CIRCUITO.ID_CIRCUITO = CD_PRODOTTO_VENDITA.ID_CIRCUITO;
       
       
       if v_flg_segui_il_film = 'S' then
           v_flg_esclusivo := 'S';
       end if;
--
--       v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata);
         v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata,v_sala_arena);
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
             v_dgc := '';
           raise;
     END;
--
     v_id_periodo := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_PIANO(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);

     --dbms_output.PUT_LINE('dgc:'||v_dgc);
     --dbms_output.PUT_LINE('v_soggetto'||v_soggetto);
     v_lordo := p_lordo;
     v_netto_comm := PA_PC_IMPORTI.FU_NETTO(p_lordo_comm, p_sconto_comm);
     v_netto_dir := PA_PC_IMPORTI.FU_NETTO(p_lordo_dir, p_sconto_dir);
     v_netto := v_netto_comm + v_netto_dir;
     
     begin
        SELECT CD_PRODOTTO_ACQUISTATO_SEQ.CURRVAL INTO v_seq_prev FROM DUAL;
        EXCEPTION  
        WHEN OTHERS THEN
        v_seq_prev := 0;
     end;
     
     INSERT INTO CD_PRODOTTO_ACQUISTATO
         ( ID_PRODOTTO_VENDITA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           ID_FORMATO,
           ID_SPETTACOLO,
           NUMERO_MASSIMO_SCHERMI,
           NUMERO_AMBIENTI,
           ID_GENERE,
           ID_PIANO,
           ID_VER_PIANO,
           ID_IMPORTI_RICHIESTI_PIANO,
           STATO_DI_VENDITA,
           IMP_LORDO,
           IMP_MAGGIORAZIONE,
           IMP_RECUPERO,
           IMP_TARIFFA,
           IMP_SANATORIA,
           IMP_NETTO,
           DATA_INIZIO,
           DATA_FINE,
           ID_MISURA_PRD_VE,
           FLG_TARIFFA_VARIABILE,
           DGC,
           ID_TIPO_CINEMA,
           COD_ATTIVAZIONE,
           FLG_ESCLUSIVO
          )
        SELECT p_id_prodotto_vendita,
        (SELECT id_raggruppamento from cd_raggruppamento_intermediari
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS INTERMEDIARIO,
        (SELECT id_fruitori_di_piano from cd_fruitori_di_piano
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS FRUITORE,
        p_id_formato,
        p_id_spettacolo,
        p_numero_massimo_schermi,
        p_numero_ambienti,
        NULL,
        p_id_piano,
        p_id_ver_piano,
        v_id_periodo,
        v_stato_vendita,
         v_lordo,
         p_maggiorazione AS MAGGIORAZIONE,
         0 AS RECUPERO,
         p_tariffa AS TARIFFA,
         0 AS SANATORIA,
         v_netto,
         p_data_inizio,
         p_data_fine,
         TARIFFA.ID_MISURA_PRD_VE,
         p_tariffa_variabile,
         v_dgc,
         p_id_tipo_cinema,
         p_cod_attivazione,
         v_flg_esclusivo
        FROM
        CD_UNITA_MISURA_TEMP, CD_MISURA_PRD_VENDITA,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.DATA_INIZIO <= p_data_inizio
        AND TARIFFA.DATA_FINE >= p_data_fine
        AND TARIFFA.ID_LISTINO = p_id_listino 
        AND TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        --AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND CD_UNITA_MISURA_TEMP.ID_UNITA = p_unita_temp;

        /*FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
            dbms_output.PUT_LINE(p_list_maggiorazioni(i));
        END LOOP;*/

        SELECT CD_PRODOTTO_ACQUISTATO_SEQ.CURRVAL INTO v_seq FROM DUAL;
       
        if v_seq= v_seq_prev then
            RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PROD_ACQ_MODULO: INSERT NON ESEGUITA ');
        end if;
     
        p_id_prod_acquistato:=v_seq;--aggiunto Abbundo francesco, Febbraio 2010
        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'C',v_netto_comm,p_sconto_comm,v_seq,FU_CD_GET_DGC_TC(v_dgc,'C')
        FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'D',v_netto_dir,p_sconto_dir,v_seq,FU_CD_GET_DGC_TC(v_dgc,'D')
        FROM DUAL;

  IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
     --FOR i IN p_list_maggiorazioni.FIRST..p_list_maggiorazioni.LAST LOOP
       FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
         PR_SALVA_MAGGIORAZIONE(v_seq, p_list_maggiorazioni(i));
     END LOOP;
   END IF;

   IF p_list_id_area IS NOT NULL AND p_list_id_area.COUNT > 0 THEN
        FOR i IN 1..p_list_id_area.COUNT LOOP
          INSERT INTO CD_AREE_PRODOTTO_ACQUISTATO(ID_AREA_NIELSEN, ID_PRODOTTO_ACQUISTATO)
          --VALUES(1,v_seq);
            VALUES(p_list_id_area(i),v_seq);
        END LOOP;
   END IF;
    -- IF p_id_posizione_rigore IS NOT NULL THEN
     --   PR_SALVA_MAGGIORAZIONE(v_seq, 1);
    -- END IF;
       IF p_list_id_area.COUNT = 0 THEN
            PA_CD_COMUNICATO.PR_CREA_COMUNICATI_MODULO(p_id_prod_acquistato,
                                           p_id_prodotto_vendita,
                                           p_id_ambito,
                                           v_id_circuito,
                                           p_data_inizio,
                                           p_data_fine,
                                           p_id_formato,
                                           p_unita_temp,
                                           v_soggetto,
                                           p_id_posizione_rigore,
                                           v_id_target,
                                           v_flg_segui_il_film);
      ELSE
            PA_CD_COMUNICATO.PR_CREA_COMUNICATI_NIELSEN(p_id_prod_acquistato,
                                           p_id_prodotto_vendita,
                                           p_id_ambito,
                                           v_id_circuito,
                                           p_data_inizio,
                                           p_data_fine,
                                           p_id_formato,
                                           p_unita_temp,
                                           v_soggetto,
                                           p_id_posizione_rigore,
                                           p_list_id_area);
      END IF;
      --
      SELECT COUNT(1)
      INTO v_num_comunicati
      FROM CD_COMUNICATO
      WHERE ID_PRODOTTO_ACQUISTATO = p_id_prod_acquistato
      AND ROWNUM <= 1;
      --
      IF v_num_comunicati = 0 THEN
        RAISE_APPLICATION_ERROR(-20027, 'PROCEDURA PR_CREA_PROD_ACQ_MODULO: ERRORE NELL''INSERIMENTO DEI COMUNICATI '|| SQLERRM);
      END IF;
      PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(p_id_piano, p_id_ver_piano, v_id_cliente, v_soggetto, null);
      EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
      WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PROD_ACQ_MODULO: INSERT NON ESEGUITA '|| SQLERRM);
        ROLLBACK TO PR_CREA_PROD_ACQ_MODULO;
     END PR_CREA_PROD_ACQ_MODULO;
     



-- Procedura PR_CREA_PROD_MODULO_SEGUI_FILM
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto acquistato di tipo modulo 
--               nel sistema, creando i relativi comunicati UTILIZZANDO ID_TARIFFA  UTILIZZATO SOLO PER IL SEGUI IL FILM
--
--
-- OPERAZIONI:
--  1) Seleziona la descrizione dello stato di vendita
--  2) Seleziona il soggetto da associare ai comunicati. Se esiste un solo soggetto con descrizione
--     differente da 'SOGGETTO NON DEFINITO' viene associato quello
--  3) Seleziona la testata editoriale, il prodotto pubblicitario, il dgc
--  4) Calcola i valori di netto commerciale e direzionale
--  5) Inserisce il prodotto acquistato, verificando lo sconto stagionale e la tariffa in base al coefficiente cinema
--  6) Inserisce gli importi prodotto, commerciale e direzionale, legati al prodotto acquistato
--  7) Inserisce le informazioni sulle maggiorazioni e le aree nielsen collegate
--  8) Inserisce i comunicati, verificando se si tratta di un prodotto modulo o geosplit
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_id_formato            id del formato acquistabile
--  p_tariffa               importo di tariffa
--  p_lordo                 importo lordo
--  p_lordo_comm            importo lordo commerciale
--  p_lordo_dir             importo lordo direzionale
--  p_sconto_comm           importo di sconto commerciale
--  p_sconto_dir            importo di sconto direzionale
--  p_maggiorazione         importo di maggiorazione
--  p_unita_temp            unita temporale del prodotto inserito (Settimana, Mese ecc)
--  p_id_listino            id del listino utilizzato
--  p_num_ambiti            numero di ambienti per cui viene creato il prodotto acquistato
--  p_id_posizione_rigore   id della posizione di rigore, se richiesta
--  p_tariffa_variabile     flag che indica se il prodotto e da creare con tariffa variabile o meno (il flag puo assumere il valore S o N)
--  p_id_tipo_cinema        id del tipo cinema del prodotto di vendita
--  p_list_maggiorazioni    lista di maggiorazioni applicate al prodotto acquistato
--  p_list_id_area          lista di aree nielsen applicate al prodotto acquistato. Viene utilizzato solo se il prodotto e geo split
--
-- OUTPUT: p_esito:
--    1 Inserimento eseguito correttamente
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--         p_id_prod_acquistato
--    contiene l'ID del prodotto acquistato, valore che ha senso se p_esito vale 1
--
-- REALIZZATORE: Simone Bottani , Altran, Luglio 2009
--
--  MODIFICHE:
--  se e presente un solo cliente fruitore di piano viene associato al prodotto 05/01/2010 Michele Borgogno
--             Francesco Abbundo, Teoresi srl, Febbraio 2010
--             Aggiunto l'inserimento del COD_ATTIVAZIONE
--             e l'ID del prodotto acquistato appena inserito dalla procedura
--inserito il parametro id_spettacolo x l'implementazione di segui il film. 
--inserito il parametro numero_massimo_schermi x l'implementazione di segui il film.
--inserito l'id della tariffa
--inserito il valore di default 'S'
-------------------------------------------------------------------------------------------------


     
     
PROCEDURE PR_CREA_PROD_MODULO_SEGUI_FILM (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_spettacolo         CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE,
    p_numero_massimo_schermi NUMBER,
    p_numero_ambienti        NUMBER,
    p_id_tariffa            cd_tariffa.ID_TARIFFA%type,
    p_id_prod_acquistato    OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,      
    p_esito                 OUT NUMBER)
IS
--
v_id_soggetto_piano CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
v_seq CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_seq_prev CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_numero_comunicati NUMBER;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_tipo_pubb CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE;
v_stato_vendita CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
v_soggetto CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
v_dgc CD_PRODOTTO_ACQUISTATO.DGC%TYPE;
v_cod_testata CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE%TYPE;
v_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_comm CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_count_sogg NUMBER;
v_id_periodo CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
v_sala_arena varchar2(10);
v_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE;
v_num_comunicati NUMBER;
v_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE;
v_flg_segui_il_film CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE;
BEGIN
--
p_esito     := 1;

         SAVEPOINT PR_CREA_PROD_ACQ_MODULO;

       SELECT DESCR_BREVE, ID_CLIENTE
       INTO v_stato_vendita, v_id_cliente
       FROM CD_PIANIFICAZIONE, CD_STATO_DI_VENDITA
       WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
       AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
       AND CD_STATO_DI_VENDITA.ID_STATO_VENDITA = CD_PIANIFICAZIONE.ID_STATO_VENDITA;
--
    SELECT COUNT(1)
    INTO v_count_sogg
    FROM CD_SOGGETTO_DI_PIANO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano;
--
      SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano
        AND (
          v_count_sogg = 1
        OR
          v_count_sogg = 2 AND DESCRIZIONE != 'SOGGETTO NON DEFINITO'
        OR
          v_count_sogg > 2
          AND DESCRIZIONE = 'SOGGETTO NON DEFINITO');
--
     BEGIN
       SELECT COD_TESTATA_EDITORIALE
       INTO v_cod_testata
       FROM CD_PIANIFICAZIONE
       WHERE ID_PIANO = p_id_piano
       AND ID_VER_PIANO = p_id_ver_piano;
--
       SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB,DECODE(FLG_ARENA,'S', 'ARENA','SALA'), CD_CIRCUITO.ID_CIRCUITO, CD_PRODOTTO_VENDITA.ID_TARGET,CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM
       INTO  v_id_tipo_pubb,v_sala_arena, v_id_circuito,v_id_target,v_flg_segui_il_film
       FROM  CD_PRODOTTO_VENDITA,CD_CIRCUITO
       WHERE CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
       AND   CD_CIRCUITO.ID_CIRCUITO = CD_PRODOTTO_VENDITA.ID_CIRCUITO;
--
--       v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata);
         v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata,v_sala_arena);
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
             v_dgc := '';
           raise;
     END;
--
     v_id_periodo := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_PIANO(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);

     --dbms_output.PUT_LINE('dgc:'||v_dgc);
     --dbms_output.PUT_LINE('v_soggetto'||v_soggetto);
     v_lordo := p_lordo;
     v_netto_comm := PA_PC_IMPORTI.FU_NETTO(p_lordo_comm, p_sconto_comm);
     v_netto_dir := PA_PC_IMPORTI.FU_NETTO(p_lordo_dir, p_sconto_dir);
     v_netto := v_netto_comm + v_netto_dir;
     
     begin
        SELECT CD_PRODOTTO_ACQUISTATO_SEQ.CURRVAL INTO v_seq_prev FROM DUAL;
        EXCEPTION  
        WHEN OTHERS THEN
        v_seq_prev := 0;
     end;
     
     INSERT INTO CD_PRODOTTO_ACQUISTATO
         ( ID_PRODOTTO_VENDITA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           ID_FORMATO,
           ID_SPETTACOLO,
           NUMERO_MASSIMO_SCHERMI,
           NUMERO_AMBIENTI,
           ID_GENERE,
           ID_PIANO,
           ID_VER_PIANO,
           ID_IMPORTI_RICHIESTI_PIANO,
           STATO_DI_VENDITA,
           IMP_LORDO,
           IMP_MAGGIORAZIONE,
           IMP_RECUPERO,
           IMP_TARIFFA,
           IMP_SANATORIA,
           IMP_NETTO,
           DATA_INIZIO,
           DATA_FINE,
           ID_MISURA_PRD_VE,
           FLG_TARIFFA_VARIABILE,
           DGC,
           ID_TIPO_CINEMA,
           COD_ATTIVAZIONE,
           FLG_ESCLUSIVO
          )
        SELECT p_id_prodotto_vendita,
        (SELECT id_raggruppamento from cd_raggruppamento_intermediari
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS INTERMEDIARIO,
        (SELECT id_fruitori_di_piano from cd_fruitori_di_piano
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS FRUITORE,
        p_id_formato,
        p_id_spettacolo,
        p_numero_massimo_schermi,
        p_numero_ambienti,
        NULL,
        p_id_piano,
        p_id_ver_piano,
        v_id_periodo,
        v_stato_vendita,
         v_lordo,
         p_maggiorazione AS MAGGIORAZIONE,
         0 AS RECUPERO,
         p_tariffa AS TARIFFA,
         0 AS SANATORIA,
         v_netto,
         p_data_inizio,
         p_data_fine,
         TARIFFA.ID_MISURA_PRD_VE,
         p_tariffa_variabile,
         v_dgc,
         p_id_tipo_cinema,
         p_cod_attivazione,
         'S'
        FROM
        CD_UNITA_MISURA_TEMP, CD_MISURA_PRD_VENDITA,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.ID_TARIFFA = p_id_tariffa
        AND TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        --AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND CD_UNITA_MISURA_TEMP.ID_UNITA = p_unita_temp;

        /*FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
            dbms_output.PUT_LINE(p_list_maggiorazioni(i));
        END LOOP;*/
       
    

       SELECT CD_PRODOTTO_ACQUISTATO_SEQ.CURRVAL INTO v_seq FROM DUAL;
       
       
        if v_seq= v_seq_prev then
            RAISE_APPLICATION_ERROR(-20027, 'PR_CREA_PROD_MODULO_SEGUI_FILM: INSERT NON ESEGUITA ');
        end if;
  
        p_id_prod_acquistato:=v_seq;--aggiunto Abbundo francesco, Febbraio 2010
       INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'C',v_netto_comm,p_sconto_comm,v_seq,FU_CD_GET_DGC_TC(v_dgc,'C')
        FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'D',v_netto_dir,p_sconto_dir,v_seq,FU_CD_GET_DGC_TC(v_dgc,'D')
        FROM DUAL;

  IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
     --FOR i IN p_list_maggiorazioni.FIRST..p_list_maggiorazioni.LAST LOOP
       FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
         PR_SALVA_MAGGIORAZIONE(v_seq, p_list_maggiorazioni(i));
     END LOOP;
   END IF;

   IF p_list_id_area IS NOT NULL AND p_list_id_area.COUNT > 0 THEN
        FOR i IN 1..p_list_id_area.COUNT LOOP
          INSERT INTO CD_AREE_PRODOTTO_ACQUISTATO(ID_AREA_NIELSEN, ID_PRODOTTO_ACQUISTATO)
          --VALUES(1,v_seq);
            VALUES(p_list_id_area(i),v_seq);
        END LOOP;
   END IF;
    -- IF p_id_posizione_rigore IS NOT NULL THEN
     --   PR_SALVA_MAGGIORAZIONE(v_seq, 1);
    -- END IF;
    
    
       IF p_list_id_area.COUNT = 0 THEN
            PA_CD_COMUNICATO.PR_CREA_COMUNICATI_MODULO(p_id_prod_acquistato,
                                           p_id_prodotto_vendita,
                                           p_id_ambito,
                                           v_id_circuito,
                                           p_data_inizio,
                                           p_data_fine,
                                           p_id_formato,
                                           p_unita_temp,
                                           v_soggetto,
                                           p_id_posizione_rigore,
                                           v_id_target,
                                           v_flg_segui_il_film);
      ELSE
            PA_CD_COMUNICATO.PR_CREA_COMUNICATI_NIELSEN(p_id_prod_acquistato,
                                           p_id_prodotto_vendita,
                                           p_id_ambito,
                                           v_id_circuito,
                                           p_data_inizio,
                                           p_data_fine,
                                           p_id_formato,
                                           p_unita_temp,
                                           v_soggetto,
                                           p_id_posizione_rigore,
                                           p_list_id_area);
      END IF;
      --
      SELECT COUNT(1)
      INTO v_num_comunicati
      FROM CD_COMUNICATO
      WHERE ID_PRODOTTO_ACQUISTATO = p_id_prod_acquistato
      AND ROWNUM <= 1;

      --
      IF v_num_comunicati = 0 THEN
        RAISE_APPLICATION_ERROR(-20027, 'PROCEDURA PR_CREA_PROD_MODULO_SEGUI_FILM: ERRORE NELL''INSERIMENTO DEI COMUNICATI '|| SQLERRM);
      END IF;
      PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(p_id_piano, p_id_ver_piano, v_id_cliente, v_soggetto, null);
      EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
      WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PROD_MODULO_SEGUI_FILM: INSERT NON ESEGUITA '|| SQLERRM);
        ROLLBACK TO PR_CREA_PROD_ACQ_MODULO;
     END PR_CREA_PROD_MODULO_SEGUI_FILM;


-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_PROD_ACQ_LIBERA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto acquistato venduto in libera
--
--
--
-- OPERAZIONI:
--  1) Seleziona la descrizione dello stato di vendita
--  2) Seleziona il soggetto da associare ai comunicati. Se esiste un solo soggetto con descrizione
--     differente da 'SOGGETTO NON DEFINITO' viene associato quello
--  3) Seleziona la testata editoriale, il prodotto pubblicitario, il dgc
--  4) Calcola i valori di netto commerciale e direzionale
--  5) Inserisce il prodotto acquistato, verificando lo sconto stagionale e la tariffa in base al coefficiente cinema
--  6) Inserisce gli importi prodotto, commerciale e direzionale, legati al prodotto acquistato
--  7) Inserisce le informazioni sulle maggiorazioni collegate
--  8) Inserisce i comunicati per gli ambienti scelti
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_list_id_ambito        vettore contentente gli id degli ambienti acquistati
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_id_formato            id del formato acquistabile
--  p_tariffa               importo di tariffa
--  p_lordo                 importo lordo
--  p_lordo_comm            importo lordo commerciale
--  p_lordo_dir             importo lordo direzionale
--  p_sconto_comm           importo di sconto commerciale
--  p_sconto_dir            importo di sconto direzionale
--  p_maggiorazione         importo di maggiorazione
--  p_unita_temp            unita temporale del prodotto inserito (Settimana, Mese ecc)
--  p_id_listino            id del listino utilizzato
--  p_num_ambiti            numero di ambienti per cui viene creato il prodotto acquistato
--  p_id_posizione_rigore   id della posizione di rigore, se richiesta
--  p_tariffa_variabile     flag che indica se il prodotto e da creare con tariffa variabile o meno (il flag puo assumere il valore S o N)
--  p_id_tipo_cinema        id del tipo cinema del prodotto di vendita
--  p_list_maggiorazioni    lista di maggiorazioni applicate al prodotto acquistato
--  p_list_id_area          lista di aree nielsen applicate al prodotto acquistato. Viene utilizzato solo se il prodotto e geo split
--
-- OUTPUT: esito:
--    1  Prodotto inserito correttamente
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Simone Bottani , Altran, Luglio 2009
--
--  MODIFICHE:
--  se e presente un solo cliente fruitore di piano viene associato al prodotto 05/01/2010 Michele Borgogno
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PROD_ACQ_LIBERA (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_prodotto_acquistato OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    p_esito                  OUT NUMBER)
IS
--
v_id_soggetto_piano CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
v_seq NATURAL;
v_numero_comunicati NUMBER;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_tipo_pubb CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE;
v_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
v_soggetto CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
v_cod_testata CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE%TYPE;
v_dgc CD_PRODOTTO_ACQUISTATO.DGC%TYPE;
v_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_comm CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_count_sogg NUMBER;
v_id_periodo CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
v_sala_arena varchar2(10);
v_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE;
v_num_comunicati NUMBER;
BEGIN
--
p_esito     := 1;

       SAVEPOINT PR_CREA_PROD_ACQ_LIBERA;

       SELECT DESCR_BREVE, ID_CLIENTE
       INTO v_stato_vendita, v_id_cliente
       FROM CD_PIANIFICAZIONE, CD_STATO_DI_VENDITA
       WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
       AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
       AND CD_STATO_DI_VENDITA.ID_STATO_VENDITA = CD_PIANIFICAZIONE.ID_STATO_VENDITA;
--
    SELECT COUNT(1)
    INTO v_count_sogg
    FROM CD_SOGGETTO_DI_PIANO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano;
--
      SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano
        AND (
          v_count_sogg = 1
        OR
          v_count_sogg = 2 AND DESCRIZIONE != 'SOGGETTO NON DEFINITO'
        OR
          v_count_sogg > 2
          AND DESCRIZIONE = 'SOGGETTO NON DEFINITO');

/*    SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano
        AND (
          (SELECT COUNT(ID_SOGGETTO_DI_PIANO) FROM CD_SOGGETTO_DI_PIANO
          WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano) = 2
          OR DESCRIZIONE = 'SOGGETTO NON DEFINITO');*/
         --
     BEGIN
     --dbms_output.PUT_LINE('p_id_piano: '||p_id_piano);
     --  dbms_output.PUT_LINE('p_id_prodotto_vendita: '||p_id_prodotto_vendita);
      SELECT COD_TESTATA_EDITORIALE
       INTO v_cod_testata
       FROM CD_PIANIFICAZIONE
       WHERE ID_PIANO = p_id_piano
       AND ID_VER_PIANO = p_id_ver_piano;
--
       SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB,DECODE(FLG_ARENA,'S', 'ARENA','SALA'), CD_CIRCUITO.ID_CIRCUITO
       INTO v_id_tipo_pubb,v_sala_arena, v_id_circuito
       FROM CD_PRODOTTO_VENDITA,CD_CIRCUITO
       WHERE CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
       AND   CD_CIRCUITO.ID_CIRCUITO = CD_PRODOTTO_VENDITA.ID_CIRCUITO;
--
--       v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata );
       v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata,v_sala_arena);

         EXCEPTION
             WHEN NO_DATA_FOUND THEN
             v_dgc := '';
           raise;
     END;

     v_id_periodo := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_PIANO(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);

     v_lordo := p_lordo;
     v_netto_comm := PA_PC_IMPORTI.FU_NETTO(p_lordo_comm, p_sconto_comm);
     v_netto_dir := PA_PC_IMPORTI.FU_NETTO(p_lordo_dir, p_sconto_dir);
     v_netto := v_netto_comm + v_netto_dir;
--
     INSERT INTO CD_PRODOTTO_ACQUISTATO
         ( ID_PRODOTTO_VENDITA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           ID_FORMATO,
           ID_SPETTACOLO,
           ID_GENERE,
           ID_PIANO,
           ID_VER_PIANO,
           NUMERO_AMBIENTI,
           ID_IMPORTI_RICHIESTI_PIANO,
           STATO_DI_VENDITA,
           IMP_LORDO,
           IMP_MAGGIORAZIONE,
    --       IMP_NETTO_DIR,
           IMP_RECUPERO,
           IMP_TARIFFA,
           IMP_SANATORIA,
       --       IMP_SCO_COMM,
           IMP_NETTO,
       --       STATO_FATTURAZIONE,
           DATA_INIZIO,
           DATA_FINE,
           ID_MISURA_PRD_VE,
           FLG_TARIFFA_VARIABILE,
           DGC,
           ID_TIPO_CINEMA,
           COD_ATTIVAZIONE
          )
        SELECT p_id_prodotto_vendita,
        (SELECT id_raggruppamento from cd_raggruppamento_intermediari
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS INTERMEDIARIO,
        (SELECT id_fruitori_di_piano from cd_fruitori_di_piano
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS FRUITORE,
        p_id_formato,
        NULL,
        NULL,
        p_id_piano,
        p_id_ver_piano,
        p_num_ambiti,
        v_id_periodo,
        v_stato_vendita,
         v_lordo AS IMP_LORDO,
         p_maggiorazione AS MAGGIORAZIONE,
   --      0 AS IMP_NETTO_DIR,
         0 AS RECUPERO,
         p_tariffa AS TARIFFA,
         0 AS SANATORIA,
   --      PA_PC_IMPORTI.FU_SCONTO_COMM_3(p_lordo, p_sconto) * p_num_ambiti AS SCO_COMM,
         v_netto,
  --       NULL,
         p_data_inizio,
         p_data_fine,
         TARIFFA.ID_MISURA_PRD_VE,
         p_tariffa_variabile,
         v_dgc,
         p_id_tipo_cinema,
         p_cod_attivazione
        FROM CD_UNITA_MISURA_TEMP, CD_MISURA_PRD_VENDITA,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND TARIFFA.ID_LISTINO = p_id_listino
        AND TARIFFA.DATA_INIZIO <= p_data_inizio
        AND TARIFFA.DATA_FINE >= p_data_fine
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND CD_UNITA_MISURA_TEMP.ID_UNITA = p_unita_temp;
--
        SELECT CD_PRODOTTO_ACQUISTATO_SEQ.CURRVAL INTO v_seq FROM DUAL;
        p_id_prodotto_acquistato := v_seq;
--
        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'C',v_netto_comm,p_sconto_comm,v_seq,FU_CD_GET_DGC_TC(v_dgc,'C')
        FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'D',v_netto_dir,p_sconto_dir,v_seq,FU_CD_GET_DGC_TC(v_dgc,'D')
        FROM DUAL;

   IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
     FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
         PR_SALVA_MAGGIORAZIONE(v_seq, p_list_maggiorazioni(i));
     END LOOP;
   END IF;
        -- IF p_id_posizione_rigore IS NOT NULL THEN
         --   PR_SALVA_MAGGIORAZIONE(v_seq, 1);
        -- END IF;
--
       PA_CD_COMUNICATO.PR_CREA_COMUNICATI_LIBERA(p_id_prodotto_acquistato,
                                          p_id_prodotto_vendita,
                                           p_id_ambito,
                                           v_id_circuito,
                                           p_data_inizio,
                                           p_data_fine,
                                           p_list_id_ambito,
                                           p_id_formato,
                                           p_unita_temp,
                                           v_soggetto,
                                           p_id_posizione_rigore);
   --
   SELECT COUNT(1)
   INTO v_num_comunicati
   FROM CD_COMUNICATO
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
   AND ROWNUM <= 1;
   --
   IF v_num_comunicati = 0 THEN
     RAISE_APPLICATION_ERROR(-20027, 'PROCEDURA PR_CREA_PROD_ACQ_LIBERA: ERRORE NELL''INSERIMENTO DEI COMUNICATI '|| SQLERRM);
   END IF;
   PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(p_id_piano, p_id_ver_piano, v_id_cliente, v_soggetto, null);
   EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PROD_ACQ_LIBERA: INSERT NON ESEGUITA, ERRORE: '||SQLERRM);
        ROLLBACK TO PR_CREA_PROD_ACQ_LIBERA;

     END PR_CREA_PROD_ACQ_LIBERA;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_PRODOTTO_MULTIPLO
--
-- DESCRIZIONE:  Effettua l'inserimento multiplo di prodotti, compresi tra le date di inizio e di fine indicate
--               nel sistema, creando i relativi comunicati
--
--
-- OPERAZIONI:
--  1) Seleziona la tariffa per ogni settimana compresa nel periodo
--  2) Calcola gli importi relativi
--  3) Inserisci il prodotto
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_list_id_ambito        Lista di ambienti del prodotto
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_id_formato            id del formato acquistabile
--  p_perc_sconto           Percentuale di sconto applicata
--  p_unita_temp            unita temporale del prodotto inserito (Settimana, Mese ecc)
--  p_id_listino            id del listino utilizzato
--  p_id_posizione_rigore   id della posizione di rigore, se richiesta
--  p_tariffa_variabile     flag che indica se il prodotto e da creare con tariffa variabile o meno (il flag puo assumere il valore S o N)
--  p_list_maggiorazioni    lista di maggiorazioni applicate al prodotto acquistato
--  p_list_id_area          lista di aree nielsen applicate al prodotto acquistato. Viene utilizzato solo se il prodotto e geo split
--  p_id_tipo_cinema        id del tipo cinema del prodotto di vendita
--
-- OUTPUT: p_esito:
--    1 Inserimento eseguito correttamente
--
-- REALIZZATORE: Simone Bottani , Altran, Maggio 2010
-- Modifiche : Mauro Viel Altran Italia 14/02/2010 inserito il parametro  p_id_spettacolo x il segui il film.
--             Mauro Viel Altran Italia 13/07/2011 inseritpo il parametro p_numero_ambienti
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_PRODOTTO_MULTIPLO (
    p_id_prodotto_vendita   CD_PRODOTTI_RICHIESTI.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTI_RICHIESTI.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTI_RICHIESTI.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTI_RICHIESTI.ID_FORMATO%TYPE,
    p_perc_sconto           NUMBER,
    p_unita_temp            CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTI_RICHIESTI.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_list_id_area          id_list_type,
    p_id_tipo_cinema        CD_PRODOTTI_RICHIESTI.ID_TIPO_CINEMA%TYPE,
    p_id_circuito           CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
    p_id_spettacolo         cd_prodotto_acquistato.ID_SPETTACOLO%type,
    p_numero_massimo_schermi NUMBER,
    p_esito                    OUT NUMBER) IS
--
v_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
v_tariffa_ambiente CD_TARIFFA.IMPORTO%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_sconto_stagionale CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
v_data_inizio CD_PRODOTTI_RICHIESTI.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTI_RICHIESTI.DATA_FINE%TYPE;
v_misura_temp CD_PRODOTTI_RICHIESTI.ID_MISURA_PRD_VE%TYPE;
v_num_ambienti NUMBER;
v_imp_tariffa CD_PRODOTTI_RICHIESTI.IMP_TARIFFA%TYPE;
v_imp_lordo CD_PRODOTTI_RICHIESTI.IMP_LORDO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_imp_maggiorazione CD_PRODOTTI_RICHIESTI.IMP_MAGGIORAZIONE%TYPE := 0;
v_imp_zero number := 0;
v_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_id_listino CD_TARIFFA.ID_LISTINO%TYPE;
v_string_id_ambito   varchar(32000);
v_posizione_disponibile NUMBER;
v_esito NUMBER := 0;
BEGIN
    --
    SAVEPOINT PR_CREA_PRODOTTO_MULTIPLO;
    p_esito := 1;
    IF p_list_id_ambito.COUNT > 0 THEN
        FOR i IN p_list_id_ambito.FIRST..p_list_id_ambito.LAST LOOP
              v_string_id_ambito := v_string_id_ambito||LPAD(p_list_id_ambito(i),5,'0')||'|';
        END LOOP;
    END IF;
    FOR PERIODO IN (SELECT PER.DATA_INIZ, PER.DATA_FINE FROM
                    PERIODI PER, CD_IMPORTI_RICHIESTI_PIANO IRP
                    WHERE IRP.ID_PIANO = p_id_piano
                    AND IRP.ID_VER_PIANO = p_id_ver_piano
                    AND IRP.ANNO = PER.ANNO
                    AND IRP.CICLO = PER.CICLO
                    AND IRP.PER = PER.PER
                    AND PER.DATA_INIZ >= p_data_inizio
                    AND PER.DATA_FINE <= p_data_fine
                    ORDER BY PER.DATA_INIZ
                    ) LOOP
        v_data_inizio := PERIODO.DATA_INIZ;
        v_data_fine := PERIODO.DATA_FINE;
        v_id_tariffa := null;
        v_num_ambienti := 0;
        v_posizione_disponibile := 0;
        BEGIN
        SELECT TARIFFA.ID_TARIFFA, PV.ID_MOD_VENDITA, MIS.ID_MISURA_PRD_VE, TARIFFA.ID_LISTINO
        INTO v_id_tariffa, v_mod_vendita, v_misura_temp, v_id_listino
        FROM CD_UNITA_MISURA_TEMP U, CD_MISURA_PRD_VENDITA MIS,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.DATA_INIZIO <= v_data_inizio
        AND TARIFFA.DATA_FINE >= v_data_fine
        AND TARIFFA.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND MIS.ID_UNITA = U.ID_UNITA
        AND MIS.ID_UNITA = p_unita_temp;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            NULL;
        END;
        --
        IF v_id_tariffa IS NOT NULL THEN
            v_sconto_stagionale := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_SCONTO_STAGIONALE(p_id_prodotto_vendita,v_data_inizio,v_data_fine,p_id_formato,v_misura_temp);
            v_tariffa_ambiente := PA_CD_UTILITY.FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(v_id_tariffa, p_id_formato),v_sconto_stagionale);
            --
            IF v_mod_vendita = 1 THEN
                v_num_ambienti := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_AMBIENTI_LIBERA(p_id_prodotto_vendita, v_data_inizio, v_data_fine, v_string_id_ambito);
            ELSIF v_mod_vendita = 2 THEN
                v_num_ambienti := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_AMBIENTI(p_id_prodotto_vendita, v_data_inizio, v_data_fine);
            ELSIF v_mod_vendita = 3 THEN
                FOR i IN 1..p_list_id_area.COUNT LOOP
                    v_num_ambienti := v_num_ambienti + PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_SCHERMI_NIELSEN(p_list_id_area(i), p_id_prodotto_vendita, p_id_circuito, v_data_inizio, v_data_fine);
                END LOOP;
            END IF;
            v_imp_tariffa := v_tariffa_ambiente * v_num_ambienti;
            --
            IF p_list_maggiorazioni.COUNT > 0 THEN
                FOR MAGG IN (SELECT * FROM CD_MAGGIORAZIONE M
                WHERE M.ID_MAGGIORAZIONE IN (SELECT * FROM TABLE(cast (p_list_maggiorazioni as num_array)))
                ) LOOP
                    v_imp_maggiorazione := v_imp_maggiorazione + ROUND((v_imp_tariffa * MAGG.PERCENTUALE_VARIAZIONE / 100),2);
                END LOOP;
            END IF;
            v_imp_lordo := v_imp_tariffa + v_imp_maggiorazione;
            v_imp_sconto := PA_PC_IMPORTI.FU_SCONTO_COMM_3(v_imp_lordo, p_perc_sconto);
            --
            IF p_id_posizione_rigore IS NOT NULL THEN
                IF v_mod_vendita = 1 THEN
                    v_posizione_disponibile := PA_CD_PRODOTTO_ACQUISTATO.FU_VERIFICA_POS_RIGORE(
                        NULL,
                        p_id_prodotto_vendita,
                        p_id_posizione_rigore,
                        PERIODO.DATA_INIZ,
                        PERIODO.DATA_FINE,
                        p_list_id_ambito);
                ELSIF v_mod_vendita = 2 THEN
                    v_posizione_disponibile := PA_CD_PRODOTTO_ACQUISTATO.FU_VERIFICA_POS_RIGORE(
                        NULL,
                        p_id_prodotto_vendita,
                        p_id_posizione_rigore,
                        PERIODO.DATA_INIZ,
                        PERIODO.DATA_FINE,
                        NULL);
                ELSIF v_mod_vendita = 3 THEN
                    v_posizione_disponibile := PA_CD_PRODOTTO_ACQUISTATO.FU_VERIFICA_POS_RIGORE(
                        NULL,
                        p_id_prodotto_vendita,
                        p_id_posizione_rigore,
                        PERIODO.DATA_INIZ,
                        PERIODO.DATA_FINE,
                        p_list_id_area);
                END IF;
                IF v_posizione_disponibile > 0 THEN
                    p_esito := -2;
                END IF;
            END IF;
            IF v_posizione_disponibile = 0 THEN
                IF v_mod_vendita = 1 THEN
                    PR_CREA_PROD_ACQ_LIBERA (
                    p_id_prodotto_vendita,
                    p_id_piano,
                    p_id_ver_piano,
                    p_list_id_ambito,
                    p_id_ambito,
                    v_data_inizio,
                    v_data_fine,
                    p_id_formato,
                    v_imp_tariffa,
                    v_imp_lordo,
                    v_imp_lordo,
                    v_imp_zero,
                    v_imp_sconto,
                    v_imp_zero,
                    v_imp_maggiorazione,
                    p_unita_temp,
                    v_id_listino,
                    v_num_ambienti,
                    p_id_posizione_rigore,
                    p_tariffa_variabile,
                    p_list_maggiorazioni,
                    p_id_tipo_cinema,
                    NULL,
                    v_id_prodotto_acquistato,
                    v_esito);
             ELSIF v_mod_vendita = 2 THEN
                    PR_CREA_PROD_ACQ_MODULO (
                    p_id_prodotto_vendita,
                    p_id_piano,
                    p_id_ver_piano,
                    p_id_ambito,
                    v_data_inizio,
                    v_data_fine,
                    p_id_formato,
                    v_imp_tariffa,
                    v_imp_lordo,
                    v_imp_lordo,
                    v_imp_zero,
                    v_imp_sconto,
                    v_imp_zero,
                    v_imp_maggiorazione,
                    p_unita_temp,
                    v_id_listino,
                    v_num_ambienti,
                    p_id_posizione_rigore,
                    p_tariffa_variabile,
                    p_id_tipo_cinema,
                    p_list_maggiorazioni,
                    id_list_type(),
                    NULL,
                    p_id_spettacolo, 
                    p_numero_massimo_schermi,
                    v_num_ambienti,
                    v_id_prodotto_acquistato,
                    v_esito);
                ELSIF v_mod_vendita = 3 THEN
                    PR_CREA_PROD_ACQ_MODULO (
                    p_id_prodotto_vendita,
                    p_id_piano,
                    p_id_ver_piano,
                    p_id_ambito,
                    v_data_inizio,
                    v_data_fine,
                    p_id_formato,
                    v_imp_tariffa,
                    v_imp_lordo,
                    v_imp_lordo,
                    v_imp_zero,
                    v_imp_sconto,
                    v_imp_zero,
                    v_imp_maggiorazione,
                    p_unita_temp,
                    v_id_listino,
                    v_num_ambienti,
                    p_id_posizione_rigore,
                    p_tariffa_variabile,
                    p_id_tipo_cinema,
                    p_list_maggiorazioni,
                    p_list_id_area,
                    NULL,
                    p_id_spettacolo,
                    p_numero_massimo_schermi,
                    v_num_ambienti,
                    v_id_prodotto_acquistato,
                    v_esito);
                END IF;
            END IF;
        END IF;
    END LOOP;
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN
        p_esito := -1;
        ROLLBACK TO PR_CREA_PRODOTTO_MULTIPLO;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PRODOTTO_MULTIPLO: INSERT NON ESEGUITA, ERRORE: '||SQLERRM);
END PR_CREA_PRODOTTO_MULTIPLO;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_PROD_ACQUISTATI
--
-- DESCRIZIONE:  Restituisce tutti i prodotto acquistati compresi tra due date,
--               e filtrati per prodotto di vendita
--
-- OPERAZIONI: Seleziona i prodotti acquistati, recuperando il numero di ambienti relativo
--
--
-- INPUT:
--       p_data_inizio                Data di inizio del prodotto acquistato
--       p_data_fine                  Data di fine del prodotto acquistato
--       p_id_prodotto_vendita        Id del prodotto di vendita
--
-- OUTPUT:
--    Cursore con i prodotti acquistati trovati
--
-- REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Febbraio 2010
--              aggiunti alcuni campi nel cursore di ritorno
--
--           Mauro Viel Altran, Settembre 2011 eliminata la chiamata alla fu_get_num_ambienti
--           inserita la colonna numero_ambienti.
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROD_ACQUISTATI(
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine   CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE) RETURN C_PROD_ACQ IS

v_prodotti C_PROD_ACQ;
BEGIN
OPEN v_prodotti FOR
  SELECT
       DISTINCT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
       CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
       CD_PRODOTTO_ACQUISTATO.IMP_LORDO,
       CD_PRODOTTO_ACQUISTATO.IMP_NETTO,
       SUM(IMP.IMP_SC_COMM) AS IMP_SCO_COMM,
       PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(IMP.IMP_NETTO),SUM(IMP.IMP_SC_COMM)) AS PERC_SCONTO_COMM,
       CD_PRODOTTO_ACQUISTATO.ID_PIANO,
       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO,
       INTERL_U.RAG_SOC_COGN,
       --FU_GET_NUM_AMBIENTI(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS NUM_AMBIENTI,
       CD_PRODOTTO_ACQUISTATO.NUMERO_AMBIENTI AS NUM_AMBIENTI,
       0 AS NUM_COMUNICATI, --FU_GET_NUM_COMUNICATI(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS NUM_COMUNICATI,
       CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA,
       FU_GET_FORMATO_PROD_ACQ(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) as DESC_FORMATO,
       FU_GET_SOGG_PROD_ACQ(CD_PRODOTTO_ACQUISTATO.ID_PIANO, CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO) AS DESC_SOGGETTO,
       AREE.DES_ABBR AS AREA_VENDITA,
       IMP.IMP_LORDO_SALTATO
  FROM INTERL_U,
       CD_PIANIFICAZIONE,
       CD_IMPORTI_PRODOTTO IMP,
       CD_PRODOTTO_ACQUISTATO,
       CD_FORMATO_ACQUISTABILE,
       CD_PRODOTTO_VENDITA,
       AREE
  WHERE CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN p_data_inizio AND p_data_fine
  AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
  AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
  AND COD_DISATTIVAZIONE IS NULL
  AND CD_PRODOTTO_ACQUISTATO.ID_PIANO = CD_PIANIFICAZIONE.ID_PIANO
  AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = CD_PIANIFICAZIONE.ID_VER_PIANO
  AND IMP.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
  AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
  AND CD_PIANIFICAZIONE.FLG_ANNULLATO = 'N'
  AND CD_PIANIFICAZIONE.FLG_SOSPESO = 'N'
  AND CD_PIANIFICAZIONE.ID_CLIENTE = INTERL_U.COD_INTERL
  AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
  AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
  AND CD_PIANIFICAZIONE.COD_AREA = AREE.COD_AREA
  GROUP BY
      CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
      CD_PRODOTTO_ACQUISTATO.NUMERO_AMBIENTI,
      CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
      CD_PRODOTTO_ACQUISTATO.IMP_LORDO,
      CD_PRODOTTO_ACQUISTATO.IMP_NETTO,
      CD_PRODOTTO_ACQUISTATO.ID_PIANO,
      CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO,
      RAG_SOC_COGN,
      DES_ABBR,
      STATO_DI_VENDITA,
      IMP.IMP_LORDO_SALTATO;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_PROD_ACQUISTATI;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FFU_GET_PROD_ACQ_AFFOLL
--
-- DESCRIZIONE:  Restituisce gli id e i formati dei prodotti acquistati del piano
--               per il controllo di affollamento
--
-- INPUT:
--       p_id_piano
--       p_id_ver_piano
--
-- OUTPUT:
--    Cursore con i prodotti acquistati trovati
--
-- REALIZZATORE: Michele Borgogno, Altran, febbraio 2010
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROD_ACQ_AFFOLL(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN C_PROD_AFFOLL IS

v_prodotti C_PROD_AFFOLL;
BEGIN
OPEN v_prodotti FOR
SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO, PR_ACQ.ID_FORMATO, TI_BR.ID_TIPO_BREAK
    FROM CD_PRODOTTO_ACQUISTATO PR_ACQ, CD_TIPO_BREAK TI_BR, CD_PRODOTTO_VENDITA PR_VEN
    WHERE PR_ACQ.ID_PIANO = p_id_piano
    AND PR_ACQ.ID_VER_PIANO = p_id_ver_piano
    AND PR_ACQ.FLG_ANNULLATO = 'N'
    AND PR_ACQ.FLG_SOSPESO = 'N'
    AND PR_ACQ.COD_DISATTIVAZIONE IS NULL
    AND PR_VEN.ID_PRODOTTO_VENDITA = PR_ACQ.ID_PRODOTTO_VENDITA
    AND TI_BR.ID_TIPO_BREAK (+)= PR_VEN.ID_TIPO_BREAK;

return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_PROD_ACQ_AFFOLL;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_PROD_SALTO_RECUPERO
--
-- DESCRIZIONE:  restituisce tutti i prodotti recupero e salto relativi al cliente di un certo prodotto_acquistato
--
--
-- INPUT:
--       p_id_prodotto_acquistato       ID del prodotto_acquistato
--
-- OUTPUT:
--    Cursore con i prodotti acquistati trovati
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Febbraio 2010
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROD_SALTO_RECUPERO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE)
RETURN C_PROD_SALTO_RECUPERO IS
v_prodotti C_PROD_SALTO_RECUPERO;
BEGIN
OPEN v_prodotti FOR
  SELECT DISTINCT 'R' SALTO_RECUPERO, CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
       CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
       CD_PRODOTTO_ACQUISTATO.IMP_LORDO,
       CD_PRODOTTO_ACQUISTATO.IMP_NETTO,
       SUM(CD_IMPORTI_PRODOTTO.IMP_SC_COMM) AS IMP_SCO_COMM,
       PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(CD_IMPORTI_PRODOTTO.IMP_NETTO),SUM(CD_IMPORTI_PRODOTTO.IMP_SC_COMM)) AS PERC_SCONTO_COMM,
       CD_PRODOTTO_ACQUISTATO.ID_PIANO,
       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO,
       INTERL_U.RAG_SOC_COGN,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS NUM_SCHERMI,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_COMUNICATI(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS NUM_COMUNICATI,
       CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) as DESC_FORMATO,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_SOGG_PROD_ACQ(CD_PRODOTTO_ACQUISTATO.ID_PIANO, CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO) AS DESC_SOGGETTO,
       AREE.DES_ABBR AS AREA_VENDITA,
       (SELECT SUM(CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO) FROM CD_IMPORTI_PRODOTTO WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS "IMP_LORDO_SALTATO",
       CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO,
       CD_CIRCUITO.NOME_CIRCUITO,
       CD_TIPO_BREAK.DESC_TIPO_BREAK,
       CD_MODALITA_VENDITA.DESC_MOD_VENDITA
  FROM INTERL_U,
       CD_PIANIFICAZIONE,
       CD_IMPORTI_PRODOTTO,
       CD_PRODOTTO_ACQUISTATO,
       CD_FORMATO_ACQUISTABILE,
       CD_PRODOTTO_VENDITA,
       AREE,
       CD_MODALITA_VENDITA, CD_TIPO_BREAK, CD_CIRCUITO
  WHERE CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
  AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
  AND COD_DISATTIVAZIONE IS NULL
  AND CD_PRODOTTO_ACQUISTATO.ID_PIANO = CD_PIANIFICAZIONE.ID_PIANO
  AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = CD_PIANIFICAZIONE.ID_VER_PIANO
  AND CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
  AND CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
  AND CD_PRODOTTO_VENDITA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
  AND CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
  AND CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = CD_MODALITA_VENDITA.ID_MOD_VENDITA
  AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
  AND CD_PIANIFICAZIONE.FLG_ANNULLATO = 'N'
  AND CD_PIANIFICAZIONE.FLG_SOSPESO = 'N'
  AND CD_PIANIFICAZIONE.ID_CLIENTE = INTERL_U.COD_INTERL
  AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
  AND CD_PRODOTTO_ACQUISTATO.DATA_FINE >= SYSDATE
  AND (SELECT SUM(CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO) FROM CD_IMPORTI_PRODOTTO WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO)=0
  AND    CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE = 'R'
  AND   (SELECT COUNT(*)
         FROM   CD_COMUNICATO
         WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
         AND    CD_COMUNICATO.FLG_ANNULLATO = 'N'
         AND    CD_COMUNICATO.FLG_SOSPESO = 'N'
         AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NOT NULL) =0
         AND   ((SELECT COUNT(*)
                            FROM   CD_RECUPERO_PRODOTTO
                            WHERE  CD_RECUPERO_PRODOTTO.ID_PRODOTTO_RECUPERO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO)=0
                           OR
                           (SELECT SUM(CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO)
                            FROM   CD_RECUPERO_PRODOTTO
                            WHERE  CD_RECUPERO_PRODOTTO.ID_PRODOTTO_RECUPERO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO)>0
                          )
  AND CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO IN(SELECT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                    FROM   CD_PRODOTTO_ACQUISTATO
                    WHERE  CD_PRODOTTO_ACQUISTATO.ID_PIANO IN (
                        SELECT DISTINCT CD_PRODOTTO_ACQUISTATO.ID_PIANO
                        FROM   CD_PIANIFICAZIONE,CD_PRODOTTO_ACQUISTATO,
                               (SELECT CD_PIANIFICAZIONE.ID_CLIENTE, CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO
                                FROM   CD_PIANIFICAZIONE, CD_PRODOTTO_ACQUISTATO
                                WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                                AND    CD_PRODOTTO_ACQUISTATO.ID_PIANO=CD_PIANIFICAZIONE.ID_PIANO) ORBETTINO
                        WHERE  CD_PRODOTTO_ACQUISTATO.ID_PIANO=CD_PIANIFICAZIONE.ID_PIANO
                        AND    CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO = ORBETTINO.COD_CATEGORIA_PRODOTTO
                        AND    CD_PIANIFICAZIONE.ID_CLIENTE = ORBETTINO.ID_CLIENTE)
                            )
  AND CD_PIANIFICAZIONE.COD_AREA = AREE.COD_AREA
  GROUP BY
      CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
      CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
      CD_PRODOTTO_ACQUISTATO.IMP_LORDO,
      CD_PRODOTTO_ACQUISTATO.IMP_NETTO,
      CD_PRODOTTO_ACQUISTATO.ID_PIANO,
      CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO,
      RAG_SOC_COGN,
      DES_ABBR,
      STATO_DI_VENDITA,
      CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO,
      CD_CIRCUITO.NOME_CIRCUITO,
      CD_TIPO_BREAK.DESC_TIPO_BREAK,
      CD_MODALITA_VENDITA.DESC_MOD_VENDITA
UNION
SELECT DISTINCT 'S' SALTO_RECUPERO, CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
       CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
       CD_PRODOTTO_ACQUISTATO.IMP_LORDO,
       CD_PRODOTTO_ACQUISTATO.IMP_NETTO,
       SUM(CD_IMPORTI_PRODOTTO.IMP_SC_COMM) AS IMP_SCO_COMM,
       PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM(CD_IMPORTI_PRODOTTO.IMP_NETTO),SUM(CD_IMPORTI_PRODOTTO.IMP_SC_COMM)) AS PERC_SCONTO_COMM,
       CD_PRODOTTO_ACQUISTATO.ID_PIANO,
       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO,
       INTERL_U.RAG_SOC_COGN,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS NUM_SCHERMI,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_COMUNICATI(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS NUM_COMUNICATI,
       CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_FORMATO_PROD_ACQ(CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) as DESC_FORMATO,
       PA_CD_PRODOTTO_ACQUISTATO.FU_GET_SOGG_PROD_ACQ(CD_PRODOTTO_ACQUISTATO.ID_PIANO, CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO) AS DESC_SOGGETTO,
       AREE.DES_ABBR AS AREA_VENDITA,
       (SELECT SUM(CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO) FROM CD_IMPORTI_PRODOTTO WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO) AS "IMP_LORDO_SALTATO",
       CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO,
       CD_CIRCUITO.NOME_CIRCUITO,
       CD_TIPO_BREAK.DESC_TIPO_BREAK,
       CD_MODALITA_VENDITA.DESC_MOD_VENDITA
  FROM INTERL_U,
       CD_PIANIFICAZIONE,
       CD_IMPORTI_PRODOTTO,
       CD_PRODOTTO_ACQUISTATO,
       CD_FORMATO_ACQUISTABILE,
       CD_PRODOTTO_VENDITA,
       AREE,
       CD_MODALITA_VENDITA, CD_TIPO_BREAK, CD_CIRCUITO
  WHERE CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
  AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
  AND COD_DISATTIVAZIONE IS NULL
  AND CD_PRODOTTO_ACQUISTATO.ID_PIANO = CD_PIANIFICAZIONE.ID_PIANO
  AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = CD_PIANIFICAZIONE.ID_VER_PIANO
  AND CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
  AND CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
  AND CD_PRODOTTO_VENDITA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
  AND CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK
  AND CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = CD_MODALITA_VENDITA.ID_MOD_VENDITA
  AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
  AND CD_PIANIFICAZIONE.FLG_ANNULLATO = 'N'
  AND CD_PIANIFICAZIONE.FLG_SOSPESO = 'N'
  AND CD_PIANIFICAZIONE.ID_CLIENTE = INTERL_U.COD_INTERL
  AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
    AND CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO IN(SELECT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                    FROM   CD_PRODOTTO_ACQUISTATO
                    WHERE  CD_PRODOTTO_ACQUISTATO.ID_PIANO IN (
                        SELECT DISTINCT CD_PRODOTTO_ACQUISTATO.ID_PIANO
                        FROM   CD_PIANIFICAZIONE,CD_PRODOTTO_ACQUISTATO,
                               (SELECT CD_PIANIFICAZIONE.ID_CLIENTE, CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO
                                FROM   CD_PIANIFICAZIONE, CD_PRODOTTO_ACQUISTATO
                                WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                                AND    CD_PRODOTTO_ACQUISTATO.ID_PIANO=CD_PIANIFICAZIONE.ID_PIANO) ORBETTINO
                        WHERE  CD_PRODOTTO_ACQUISTATO.ID_PIANO=CD_PIANIFICAZIONE.ID_PIANO
                        AND    CD_PIANIFICAZIONE.COD_CATEGORIA_PRODOTTO = ORBETTINO.COD_CATEGORIA_PRODOTTO
                        AND    CD_PIANIFICAZIONE.ID_CLIENTE = ORBETTINO.ID_CLIENTE)
                            )
  AND   CD_PRODOTTO_ACQUISTATO.DATA_FINE BETWEEN (SYSDATE-15) AND (SYSDATE+60)
  AND   (SELECT SUM(CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO) FROM CD_IMPORTI_PRODOTTO WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO)>0
  AND CD_PIANIFICAZIONE.COD_AREA = AREE.COD_AREA
  GROUP BY
      CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO,
      CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
      CD_PRODOTTO_ACQUISTATO.IMP_LORDO,
      CD_PRODOTTO_ACQUISTATO.IMP_NETTO,
      CD_PRODOTTO_ACQUISTATO.ID_PIANO,
      CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO,
      RAG_SOC_COGN,
      DES_ABBR,
      STATO_DI_VENDITA,
      CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO,
      CD_CIRCUITO.NOME_CIRCUITO,
      CD_TIPO_BREAK.DESC_TIPO_BREAK,
      CD_MODALITA_VENDITA.DESC_MOD_VENDITA;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20044, 'Procedura FU_GET_PROD_SALTO_RECUPERO: si e'' verificato un errore. '||SQLERRM);
END FU_GET_PROD_SALTO_RECUPERO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RICALCOLA_RECUPERO
--
-- DESCRIZIONE:  effettua il ricalcolo degli importi dovuti alla modifica dell'importo recupero
--
--
--  INPUT:
--     p_id_prodotto_acquistato     l'id del prodotto interessato
--     p__nuovo_recupero            il nuovo valore dell'importo recupero
--  OUTPUT:
--     p_esito          l'esito dell'operazione
--           -1         errore, operazione non effettuata
--            1         operazione andata a buon fine
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Febbraio 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_RECUPERO (p_id_prodotto_acquistato   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_nuovo_recupero           CD_TARIFFA.IMPORTO%TYPE,
                                 p_esito                    OUT NUMBER)
IS
    v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_netto                     CD_PRODOTTO_aCQUISTATO.IMP_NETTO%TYPE;
    v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
    v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
    v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
    v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
    v_id_importo_prodotto_c     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
    v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_id_importo_prodotto_d     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
    v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_netto_comm_vecchio        CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_netto_dir_vecchio         CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_stato_v                   CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
BEGIN
    p_esito:=-1;
    SAVEPOINT SP_PR_RICALCOLA_RECUPERO;
    SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, STATO_DI_VENDITA
    INTO v_lordo, v_netto, v_maggiorazione, v_sanatoria, v_recupero, v_tariffa,v_stato_v
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'C';
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'D';
    v_netto_comm_vecchio := v_netto_comm;
    v_netto_dir_vecchio := v_netto_dir;
    v_lordo_comm := v_netto_comm + v_imp_sc_comm;
    v_lordo_dir := v_netto_dir + v_imp_sc_dir;
    v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm, v_imp_sc_comm);
    v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir, v_imp_sc_dir);
    IF(v_recupero!=p_nuovo_recupero)THEN
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
        v_imp_sc_dir,v_sanatoria,v_recupero,p_nuovo_recupero,'9',p_esito);
    END IF;
    v_netto:= v_netto_comm + v_netto_dir;
    UPDATE CD_PRODOTTO_ACQUISTATO
    SET IMP_TARIFFA = v_tariffa,
        IMP_LORDO = v_lordo,
        IMP_NETTO = v_netto,
        IMP_MAGGIORAZIONE = v_maggiorazione,
        IMP_SANATORIA = v_sanatoria,
        IMP_RECUPERO = v_recupero
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    UPDATE CD_IMPORTI_PRODOTTO
    SET IMP_NETTO = v_netto_comm,
    IMP_SC_COMM = v_imp_sc_comm
    WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_c;
    PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_IMP_FAT(v_id_importo_prodotto_c,v_netto_comm_vecchio,v_netto_comm);
    UPDATE CD_IMPORTI_PRODOTTO
    SET IMP_NETTO = v_netto_dir,
    IMP_SC_COMM = v_imp_sc_dir
    WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_d;
    PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_IMP_FAT(v_id_importo_prodotto_d,v_netto_dir_vecchio,v_netto_dir);
    IF(v_stato_v!='PRE')THEN
        PA_CD_PRODOTTO_ACQUISTATO.PR_MODIFICA_STATO_VENDITA(p_id_prodotto_acquistato, 'ACO');
        PA_CD_PRODOTTO_ACQUISTATO.PR_MODIFICA_STATO_VENDITA(p_id_prodotto_acquistato, 'PRE');
    END IF;
    p_esito:=1;
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20033, 'Procedura SP_PR_RICALCOLA_RECUPERO: si e'' verificato un errore '||SQLERRM);
        ROLLBACK TO SP_PR_RICALCOLA_RECUPERO;
END PR_RICALCOLA_RECUPERO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_EFFETTUA_RECUPERO
--
-- DESCRIZIONE:  effettua il recupero di un prodotto saltato andando a modificare le relative
--               tabelle, creando le relative relazioni
--               discrimina tra la quota direzionale e quella commmerciale invocando la
--               SP PR_RICALCOLA_RECUPERO2, dando priorita' alla quota direzionale
--
--  INPUT:
--     p_id_prodotto_recupero     l'id del prodotto che recupera
--     p_id_prodotto_saltato      l'id del prodotto saltato
--  OUTPUT:
--     p_esito         l'esito dell'operazione
--          -1         errore, operazione non effettuata
--           1         operazione andata a buon fine
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Febbraio 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_EFFETTUA_RECUPERO (p_id_prodotto_recupero IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_saltato  IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_esito                   OUT NUMBER)
IS
    v_lordo_saltato_d       CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
    v_lordo_saltato_c       CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_EFFETTUA_RECUPERO;
    --prima recupero l'importo lordo saltato direzionale
    SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
    INTO   v_lordo_saltato_d
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
    IF(v_lordo_saltato_d>0)THEN
        PR_EFFETTUA_RECUPERO2(p_id_prodotto_recupero,p_id_prodotto_saltato,'D',p_esito);
    END IF;
    IF(p_esito=1)THEN
        --poi quello commerciale
        SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
        INTO   v_lordo_saltato_c
        FROM   CD_IMPORTI_PRODOTTO
        WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
        AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
        IF(v_lordo_saltato_c>0)THEN
            PR_EFFETTUA_RECUPERO2(p_id_prodotto_recupero,p_id_prodotto_saltato,'C',p_esito);
        END IF;
    END IF;
    IF(p_esito<>1)THEN
         p_esito:=-1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20033, 'Procedura SP_PR_EFFETTUA_RECUPERO: si e'' verificato un errore '||SQLERRM);
        ROLLBACK TO SP_PR_EFFETTUA_RECUPERO;
END PR_EFFETTUA_RECUPERO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_EFFETTUA_RECUPERO2
--
-- DESCRIZIONE:  effettua il recupero di un prodotto saltato andando a modificare le relative
--               tabelle, creando le relative relazioni
--
--
--  INPUT:
--     p_id_prodotto_recupero     l'id del prodotto che recupera
--     p_id_prodotto_saltato      l'id del prodotto saltato
--     p_tipo_contratto           il tipo di contratto su cui operare
--  OUTPUT:
--     p_esito          l'esito dell'operazione
--           -1         errore, operazione non effettuata
--            1         operazione andata a buon fine
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Febbraio 2010
--
--  MODIFICHE: Mauro Viel Altran Italia  Ottobre 2011: Sostituita la chaimata alla proceura PA_PC_IMPORTI.FU_PERC_SC_COMM con PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA
--                                        in modo da ottenere il numero massimo di decimali per scongiurare problemi di arrotondamento.  #MV01
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_EFFETTUA_RECUPERO2 (p_id_prodotto_recupero IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_saltato  IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_tipo_contratto       IN CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO%TYPE,
                                p_esito                   OUT NUMBER)
IS
    v_lordoS          INTEGER:=0;
    v_lordoSaltatoS   INTEGER:=0;
    v_recuperoS       INTEGER:=0;
    v_lordoR          INTEGER:=0;
    v_lordoSaltatoR   INTEGER:=0;
    v_recuperoR       INTEGER:=0;
    v_quopa           INTEGER:=0;
    v_impre           INTEGER:=0;
    v_implosa         INTEGER:=0;
    v_gia_scontato    INTEGER:=0;--indica che ho gia' preimpostato le percentuali di sconto
    v_scomm                     CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_scondir                   CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_netto                     CD_PRODOTTO_aCQUISTATO.IMP_NETTO%TYPE;
    v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
    v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
    v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
    v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
    v_id_importo_prodotto_c     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
    v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_id_importo_prodotto_d     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
    v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_netto_comm_vecchio        CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_netto_dir_vecchio         CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_stato_v                   CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
    v_concludi                  NUMBER;
    v_rec_in_rec                NUMBER;
BEGIN
    p_esito:=1;
    SAVEPOINT SP_PR_EFFETTUA_RECUPERO2;
    v_gia_scontato:=MOD(FU_PRESENTE_IN_TAB_RECUPERO(p_id_prodotto_recupero),10);
    IF(((p_tipo_contratto='C')AND((v_gia_scontato=0)OR(v_gia_scontato=1)))OR((p_tipo_contratto='D')AND((v_gia_scontato=0)OR(v_gia_scontato=2))))THEN
        SELECT IMP_NETTO, IMP_SC_COMM
        INTO v_netto_comm, v_imp_sc_comm
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
        AND TIPO_CONTRATTO = 'C';
        --v_scomm:=PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm,v_imp_sc_comm); #MV01
        v_scomm:=PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(v_netto_comm,v_imp_sc_comm);
        SELECT IMP_NETTO, IMP_SC_COMM
        INTO v_netto_comm, v_imp_sc_comm
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
        AND TIPO_CONTRATTO = 'D';
        --v_scondir:= PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm,v_imp_sc_comm); #MV01
        v_scondir:= PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(v_netto_comm,v_imp_sc_comm);
        SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, STATO_DI_VENDITA
        INTO v_lordo, v_netto, v_maggiorazione, v_sanatoria, v_recupero, v_tariffa,v_stato_v
        FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero;
        SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
        INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
        AND TIPO_CONTRATTO = 'C';
        SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
        INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
        AND TIPO_CONTRATTO = 'D';
        v_netto_comm_vecchio := v_netto_comm;
        v_netto_dir_vecchio := v_netto_dir;
        v_lordo_comm := v_netto_comm + v_imp_sc_comm;
        v_lordo_dir := v_netto_dir + v_imp_sc_dir;
        v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm, v_imp_sc_comm);--vecchio scomm
        v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir, v_imp_sc_dir);--vecchio scondir
        IF(v_scomm!=v_perc_sc_comm)THEN
                PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                v_imp_sc_dir,v_sanatoria,v_recupero,v_scomm,'41',p_esito);
        END IF;
        IF(v_scondir!=v_perc_sc_dir)THEN
                PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                v_imp_sc_dir,v_sanatoria,v_recupero,v_scondir,'42',p_esito);
        END IF;
        v_netto:= v_netto_comm + v_netto_dir;
        UPDATE CD_PRODOTTO_ACQUISTATO
        SET IMP_TARIFFA = v_tariffa,
            IMP_LORDO = v_lordo,
            IMP_NETTO = v_netto,
            IMP_MAGGIORAZIONE = v_maggiorazione,
            IMP_SANATORIA = v_sanatoria,
            IMP_RECUPERO = v_recupero
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero;
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_comm,
        IMP_SC_COMM = v_imp_sc_comm
        WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_c;
        PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_IMP_FAT(v_id_importo_prodotto_c,v_netto_comm_vecchio,v_netto_comm);
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_dir,
        IMP_SC_COMM = v_imp_sc_dir
        WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_d;
    END IF;
    SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
    INTO   v_lordoSaltatoS
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO=p_tipo_contratto;
    SELECT  NVL(CD_PRODOTTO_ACQUISTATO.IMP_LORDO,0), NVL(CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO,0)
    INTO    v_lordoS, v_recuperoS
    FROM    CD_PRODOTTO_ACQUISTATO
    WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato;
    SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
    INTO   v_lordoSaltatoR
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO=p_tipo_contratto;
    SELECT  NVL(CD_PRODOTTO_ACQUISTATO.IMP_LORDO,0), NVL(CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO,0)
    INTO    v_lordoR, v_recuperoR
    FROM    CD_PRODOTTO_ACQUISTATO
    WHERE   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero;
    v_rec_in_rec:=MOD(FU_PRESENTE_IN_TAB_RECUPERO(p_id_prodotto_recupero),10);
    v_concludi:=0;
    IF(v_recuperoR>0)THEN
        v_quopa:=LEAST(v_lordoSaltatoS,v_recuperoR);
        v_implosa := GREATEST(0,v_lordoSaltatoS-v_recuperoR);
        v_impre := v_recuperoR-LEAST(v_lordoSaltatoS,v_recuperoR);
        v_concludi:=1;
    ELSE
        IF(v_rec_in_rec=0)THEN
            v_quopa:=LEAST(v_lordoSaltatoS,v_lordoR);
            v_implosa := GREATEST(0,v_lordoSaltatoS-v_lordoR);
            v_impre := v_lordoR-LEAST(v_lordoSaltatoS,v_lordoR);
            v_concludi:=1;
        END IF;
    END IF;
    IF(v_concludi=1)THEN
        UPDATE  CD_IMPORTI_PRODOTTO
        SET     IMP_LORDO_SALTATO = v_implosa
        WHERE   CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
        AND     CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO=p_tipo_contratto;
        INSERT  INTO CD_RECUPERO_PRODOTTO (ID_PRODOTTO_SALTATO, ID_PRODOTTO_RECUPERO, DATA_RECUPERO, QUOTA_PARTE, TIPO_CONTRATTO)
        VALUES  (p_id_prodotto_saltato, p_id_prodotto_recupero, SYSDATE, v_quopa, p_tipo_contratto);
        PR_RICALCOLA_RECUPERO (p_id_prodotto_recupero,v_impre,p_esito);
    END IF;
    IF(p_esito<>1)THEN
        p_esito:=-1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20033, 'Procedura SP_PR_EFFETTUA_RECUPERO2: si e'' verificato un errore '||SQLERRM);
        ROLLBACK TO SP_PR_EFFETTUA_RECUPERO2;
END PR_EFFETTUA_RECUPERO2;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_PRESENTE_IN_TAB_RECUPERO
--
-- DESCRIZIONE:  utilizzata per verificare la presenza nella tabella CD_RECUPERO_PRODOTTO
--               di un prodotto acquistato come RECUPERO
--
--  INPUT:
--     p_id_prodotto_acquistato     l'id del prodotto che recupera
--
--  OUTPUT:
--    0    l'elemento non e' presente in tabella
--    x1   l'elemento a recupero e' presente in tabella solo come direzionale
--    x2   l'elemento a recupero e' presente in tabella solo come commerciale
--    x3   l'elemento a recupero e' presente in tabella sia come direzionale che come commerciale
--    1x   l'elemento saltato e' presente in tabella solo come direzionale
--    2x   l'elemento saltato e' presente in tabella solo come commerciale
--    3x   l'elemento saltato e' presente in tabella sia come direzionale che come commerciale
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Marzo 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PRESENTE_IN_TAB_RECUPERO(p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE)
RETURN NUMBER
IS
    v_count_dir NUMBER := 0;
    v_count_com NUMBER := 0;
    v_retval    NUMBER :=0;
BEGIN
    --ricerca quota direzionale recupero
    SELECT COUNT(*)
    INTO   v_count_dir
    FROM   CD_RECUPERO_PRODOTTO
    WHERE  ID_PRODOTTO_RECUPERO=p_id_prodotto_acquistato
    AND    TIPO_CONTRATTO='D';
    --ricerca quota commerciale recupero
    SELECT COUNT(*)
    INTO   v_count_com
    FROM   CD_RECUPERO_PRODOTTO
    WHERE  ID_PRODOTTO_RECUPERO=p_id_prodotto_acquistato
    AND    TIPO_CONTRATTO='C';
    v_retval:=v_count_com*2+v_count_dir;
    --ricerca quota direzionale salto
    SELECT COUNT(*)
    INTO   v_count_dir
    FROM   CD_RECUPERO_PRODOTTO
    WHERE  ID_PRODOTTO_SALTATO=p_id_prodotto_acquistato
    AND    TIPO_CONTRATTO='D';
    --ricerca quota commerciale salto
    SELECT COUNT(*)
    INTO   v_count_com
    FROM   CD_RECUPERO_PRODOTTO
    WHERE  ID_PRODOTTO_SALTATO=p_id_prodotto_acquistato
    AND    TIPO_CONTRATTO='C';
    v_retval:=v_retval+10*(v_count_com*2+v_count_dir);
    RETURN v_retval;
END FU_PRESENTE_IN_TAB_RECUPERO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_INFO_PROD_ACQ
--
-- DESCRIZIONE: Resituisce delle informazioni su un determinato prodotto acquistato
--              per il dettaglio guardare la parte dedicata alla descrizione dell'OUTPUT
--
--  INPUT:
--     p_id_prodotto_acquistato     l'id del prodotto acquistato
--
--  OUTPUT: restituisce un cursore con le seguenti informazioni
--      IMPREC             NUMERO il valore dell'importo recupero
--      FLG_ANNULLATO      STRING il flag annullato (S,N)
--      FLG_SOSPESO        STRING il flag sospeso   (S,N)
--      STATO              STRING lo stato di vendita (OPZ,...) '-' vuol dire NULLO
--      IMPLORDSAL         NUMERO il valore dell'importo lordo saltato
--      CODDIS             STRING codice disattivazione
--      CODATT             STRING codice attivazione
--      DATA_FINE          DATE   data fine validita' prodotto
--      DARECUPERO         STRING indica se un prodotto e' da recupero (S,N) (puo' recuperarne altri)
--      SALTATO            STRING indica se un prodotto e' saltato (S,N)
--      RECUPERATO         STRING indica se un prodotto e' stato recuperato (S,N) (implica che e' stato saltato)
--      COMSALTATI         STRING esistono comunicati saltati per questo prodotto acquistato? (S,N)
--      VALIDI             NUMBER il numero di comunicati validi
--      NONVALIDI          NUMBER il numero di comunicati non validi
--      SALTATI            NUMBER il numero di comunicati saltati
--      TOTALE             NUMBER il numero totale di comunicati
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Marzo 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_INFO_PROD_ACQ (p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE)
                          RETURN C_INFO_PROD_ACQ
IS
   v_prodotti C_INFO_PROD_ACQ;
BEGIN
    OPEN v_prodotti FOR
        --query generale che restituisce tutte le informazioni
        SELECT IMPREC, FLG_ANNULLATO, FLG_SOSPESO, STATO,
               IMPLORDSAL, CODDIS, CODATT, DATA_FINE,
               DARECUPERO, SALTATO, RECUPERATO,
               COMSALTATI, VALIDI, NONVALIDI, SALTATI, TOTALE
        FROM
        -- qui recupero le informazioni sulla presenza di recupero, flag annullato, flag sospeso,
        -- stato di vendita, importolordo saltato, codice disattivazione, codice attivazione e data fine
        (SELECT NVL(CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO,0)IMPREC ,
               CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO, CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO,
               NVL(CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA,'---') STATO, NVL((SELECT SUM(CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO) FROM CD_IMPORTI_PRODOTTO WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO),0) IMPLORDSAL,
               NVL(CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE,'-') CODDIS, NVL(CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE,'-') CODATT,
               CD_PRODOTTO_ACQUISTATO.DATA_FINE
        FROM   CD_IMPORTI_PRODOTTO, CD_PRODOTTO_ACQUISTATO
        WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND    CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO)  GENERALI,
        --Controllo se e' un prodotto da recupero
        (SELECT DECODE(COUNT(1),0,'N','S') DARECUPERO
        FROM   CD_PRODOTTO_ACQUISTATO
        WHERE  CD_PRODOTTO_ACQUISTATO.DATA_FINE BETWEEN (SYSDATE-15) AND (SYSDATE+60)
        AND    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND    CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE = 'R') RECUPERO,
        --Controllo se e' saltato
        (SELECT DECODE(SUM(CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO),0,'N','S') SALTATO
        FROM   CD_IMPORTI_PRODOTTO, CD_PRODOTTO_ACQUISTATO
        WHERE  CD_PRODOTTO_ACQUISTATO.DATA_FINE BETWEEN (SYSDATE-15) AND (SYSDATE+60)
        AND    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND    CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO)SALTO,
        --controllo se un certo prodotto saltato e' stato recuperato
        (SELECT DECODE(PA_CD_PRODOTTO_ACQUISTATO.FU_PRESENTE_IN_TAB_RECUPERO(p_id_prodotto_acquistato),0,'N','S') RECUPERATO FROM DUAL
        )SALTORECUPERO,
        --esistono comunicati saltati per questo prodotto acquistato?
        (SELECT DECODE(COUNT(*), 0, 'N', 'S') COMSALTATI
         FROM   CD_COMUNICATO
         WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
         AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
         AND    CD_COMUNICATO.FLG_SOSPESO='N'
         AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NOT NULL) ESISTCOMSALTATI,
        --comunicati validi
        (SELECT COUNT(*) VALIDI
         FROM   CD_COMUNICATO
         WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
         AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
         AND    CD_COMUNICATO.FLG_SOSPESO='N'
         AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL)COMVALIDI,
        --comunicati non validi
        (SELECT COUNT(*)  NONVALIDI
         FROM   CD_COMUNICATO
         WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
         AND    (CD_COMUNICATO.FLG_ANNULLATO <>'N' OR CD_COMUNICATO.FLG_SOSPESO<>'N'))COMNONVALIDI,
        --comunicati saltati
        (SELECT COUNT(*) SALTATI
         FROM   CD_COMUNICATO
         WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
         AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
         AND    CD_COMUNICATO.FLG_SOSPESO='N'
         AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NOT NULL) COMSALTATI,
        --totale comunicati
        (SELECT COUNT(*) TOTALE
         FROM   CD_COMUNICATO
         WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato)COMTOTALI;
    return v_prodotti;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20045, 'Function FU_GET_INFO_PROD_ACQ: si e'' verificato un errore. '||SQLERRM);
END FU_GET_INFO_PROD_ACQ;
-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_PROD_ACQUISTATI_PIANO
--
-- DESCRIZIONE:  Restituisce tutti i prodotti acquistati di un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_data_inizio           Data di inizio del periodo cercato
--  p_data_fine             Data di fine del periodo cercato
--  p_flg_annullati         Flg di annullamento
--  OUTPUT: lista di prodotti acquistati appartenenti al piano
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--            Simone Bottani , Altran, Settembre 2009
--            Aggiunto il parametro flag di annullamento
--
-------------------------------------------------------------------------------------------------
--FU_GET_PROD_ACQUISTATI_PIANO_OLD

FUNCTION FU_GET_PROD_ACQUISTATI_PIANO_O(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                      p_flg_annullato CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO%TYPE,
                                      p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_PROD_ACQ_PIANO IS
--
v_prodotti C_PROD_ACQ_PIANO;
BEGIN
OPEN v_prodotti FOR
    SELECT ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA, IMP_LORDO, IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE, IMP_RECUPERO, IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS IMP_LORDO_COMM,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS IMP_LORDO_DIR,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS PERC_SCONTO_COMM,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS PERC_SCONTO_DIR,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           GET_COD_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as COD_SOGGETTO,
           GET_DESC_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as DESC_SOGGETTO,
           GET_TITOLO_MATERIALE(ID_PRODOTTO_ACQUISTATO) as TITOLO_MAT,
           --count(distinct ID_SCHERMO) num_schermi,
           fu_get_num_ambienti(id_prodotto_acquistato) num_schermi,
           count(distinct ID_SALA) num_sale,
           count(distinct ID_ATRIO) num_atrii,
           count(distinct ID_CINEMA) num_cinema,
           0 as num_comunicati,
           ID_FORMATO,
           DESCRIZIONE AS DESC_FORMATO,
           DURATA,
           COD_POS_FISSA, DESC_POS_FISSA,
           FLG_TARIFFA_VARIABILE,
           DATA_INIZIO,
           DATA_FINE,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD
    FROM
        (SELECT CIR_CIN.ID_CINEMA,
               --CIR_CIN.ID_CIRCUITO_CINEMA, CIN_VEN.ID_CINEMA_VENDITA,
               FV_COM_BRK_SALA_ATR.*
        FROM
               CD_CIRCUITO_CINEMA CIR_CIN,
               CD_CINEMA_VENDITA CIN_VEN,
            (SELECT CIR_ATR.ID_ATRIO,
                   --CIR_ATR.ID_CIRCUITO_ATRIO, ATRIO_VEN.ID_ATRIO_VENDITA,
                   FV_COM_BRK_SALA.*
            FROM
                   CD_CIRCUITO_ATRIO CIR_ATR,
                   CD_ATRIO_VENDITA ATR_VEN,
                (SELECT CIR_SALA.ID_SALA,
                       --CIR_SALA.ID_CIRCUITO_SALA, SALA_VEN.ID_SALA_VENDITA,
                       FV_COM_BRK.*
                  FROM
                       CD_CIRCUITO_SALA CIR_SALA,
                       CD_SALA_VENDITA SALA_VEN,
                (SELECT CD_SCHERMO.ID_SCHERMO,
                       --PROIEZ.ID_PROIEZIONE, CD_BREAK.ID_BREAK, CIR_BR.ID_CIRCUITO_BREAK, BR_VEN.ID_BREAK_VENDITA,
                       FV_COM.*
                FROM
                       CD_SCHERMO,
                       --CD_PROIEZIONE PROIEZ,
                      -- CD_BREAK,
                      -- CD_CIRCUITO_BREAK CIR_BR,
                      -- CD_BREAK_VENDITA  BR_VEN,
                       (SELECT 
                               PR_ACQ.ID_PRODOTTO_ACQUISTATO,
                               PR_ACQ.ID_PRODOTTO_VENDITA,
                               PR_PUB.DESC_PRODOTTO,
                               CD_CIRCUITO.ID_CIRCUITO,
                               CD_CIRCUITO.NOME_CIRCUITO,
                               MOD_VEN.ID_MOD_VENDITA,
                               MOD_VEN.DESC_MOD_VENDITA,
                               TI_BR.ID_TIPO_BREAK,
                               TI_BR.DESC_TIPO_BREAK,
                               PC_MANIF.DES_MAN,
                               PR_ACQ.ID_RAGGRUPPAMENTO,
                               PR_ACQ.ID_FRUITORI_DI_PIANO,
                               PR_ACQ.STATO_DI_VENDITA,
                               PR_ACQ.IMP_TARIFFA, PR_ACQ.IMP_LORDO, PR_ACQ.IMP_NETTO,
                               PR_ACQ.FLG_TARIFFA_VARIABILE,
                               PR_ACQ.DATA_INIZIO,
                               PR_ACQ.DATA_FINE,
                               PR_ACQ.ID_TIPO_CINEMA,
                               IMP_PRD_D.IMP_NETTO as IMP_NETTO_DIR,
                               IMP_PRD_D.IMP_SC_COMM as IMP_SC_DIR,
                               IMP_PRD_C.IMP_NETTO as IMP_NETTO_COMM,
                               IMP_PRD_C.IMP_SC_COMM as IMP_SC_COMM,
                               PR_ACQ.IMP_MAGGIORAZIONE, PR_ACQ.IMP_RECUPERO, PR_ACQ.IMP_SANATORIA,
                               COM.ID_COMUNICATO, COM.ID_BREAK_VENDITA, COM.ID_SALA AS SALA_COM, COM.ID_SALA_VENDITA, COM.ID_ATRIO_VENDITA, COM.ID_CINEMA_VENDITA,
                               POS.COD_POSIZIONE AS COD_POS_FISSA, POS.DESCRIZIONE AS DESC_POS_FISSA,
                               F_ACQ.ID_FORMATO, F_ACQ.DESCRIZIONE, COEF.DURATA, TAR.ID_TIPO_TARIFFA,
                               PERIODO.ANNO ||'-'||PERIODO.CICLO||'-'||PERIODO.PER AS SETTIMANA_SIPRA,
                               PR_ACQ.DATAMOD
                         FROM
                               CD_SALA SALA,
                               PERIODI PERIODO,
                               CD_POSIZIONE_RIGORE POS,
                               CD_COMUNICATO COM,
                               PC_MANIF,
                               CD_TIPO_BREAK TI_BR,
                               CD_MODALITA_VENDITA MOD_VEN,
                               CD_CIRCUITO,
                               CD_PRODOTTO_PUBB PR_PUB,
                               CD_TARIFFA TAR,
                               CD_PRODOTTO_VENDITA PR_VEN,
                               CD_COEFF_CINEMA COEF,
                               CD_FORMATO_ACQUISTABILE F_ACQ,
                               CD_IMPORTI_PRODOTTO IMP_PRD_D,
                               CD_IMPORTI_PRODOTTO IMP_PRD_C,
                               CD_PRODOTTO_ACQUISTATO PR_ACQ
                          WHERE PR_ACQ.ID_PIANO = p_id_piano
                            and PR_ACQ.ID_VER_PIANO = p_id_ver_piano
                            and PR_ACQ.FLG_ANNULLATO = p_flg_annullato
                            and PR_ACQ.FLG_SOSPESO = 'N'
                            and PR_ACQ.COD_DISATTIVAZIONE is null
                           --AND PR_ACQ.STATO_DI_VENDITA = NVL(p_stato_vendita, PR_ACQ.STATO_DI_VENDITA)
                            and (p_stato_vendita IS NULL OR  instr(p_stato_vendita, PR_ACQ.STATO_DI_VENDITA)>0)
                            and IMP_PRD_C.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and IMP_PRD_C.TIPO_CONTRATTO = 'C'
                            and IMP_PRD_D.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and IMP_PRD_D.TIPO_CONTRATTO = 'D'
                            and F_ACQ.ID_FORMATO = PR_ACQ.ID_FORMATO
                            AND COEF.ID_COEFF(+) = F_ACQ.ID_COEFF
                            and PR_VEN.ID_PRODOTTO_VENDITA = PR_ACQ.ID_PRODOTTO_VENDITA
                            and TAR.ID_PRODOTTO_VENDITA = PR_VEN.ID_PRODOTTO_VENDITA
                            and PR_ACQ.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
                            and PR_ACQ.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
                            and PR_ACQ.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE
                            and (PR_ACQ.ID_TIPO_CINEMA IS NULL OR PR_ACQ.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
                            and (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PR_ACQ.ID_FORMATO)
                            and PR_PUB.ID_PRODOTTO_PUBB = PR_VEN.ID_PRODOTTO_PUBB
                            and CD_CIRCUITO.ID_CIRCUITO = PR_VEN.ID_CIRCUITO
                            and MOD_VEN.ID_MOD_VENDITA = PR_VEN.ID_MOD_VENDITA
                            and TI_BR.ID_TIPO_BREAK(+) = PR_VEN.ID_TIPO_BREAK
                            and PC_MANIF.COD_MAN(+) = PR_VEN.COD_MAN
                            and COM.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and COM.FLG_ANNULLATO=p_flg_annullato
                            and COM.FLG_SOSPESO='N'
                            and COM.COD_DISATTIVAZIONE IS NULL
                           -- AND COM.ID_SALA  (+)= SALA.ID_SALA
                            AND (COM.ID_SALA IS NULL OR COM.ID_SALA = SALA.ID_SALA)
                            AND SALA.FLG_VISIBILE = 'S'
                            and POS.COD_POSIZIONE (+) = COM.POSIZIONE_DI_RIGORE
                            and PR_ACQ.DATA_INIZIO = PERIODO.DATA_INIZ (+)
                            and PR_ACQ.DATA_FINE = PERIODO.DATA_FINE (+)
                            ) FV_COM
             where CD_SCHERMO.ID_SALA(+) = FV_COM.SALA_COM
             --where BR_VEN.ID_BREAK_VENDITA(+) = FV_COM.ID_BREAK_VENDITA
              --and CIR_BR.ID_CIRCUITO_BREAK(+) = BR_VEN.ID_CIRCUITO_BREAK
             -- and CD_BREAK.ID_BREAK(+) = CIR_BR.ID_BREAK
             -- and PROIEZ.ID_PROIEZIONE(+) = CD_BREAK.ID_PROIEZIONE
             -- and CD_SCHERMO.ID_SCHERMO(+) = PROIEZ.ID_SCHERMO
            ) FV_COM_BRK
            where SALA_VEN.ID_SALA_VENDITA(+) = FV_COM_BRK.ID_SALA_VENDITA
              and CIR_SALA.ID_CIRCUITO_SALA(+) = SALA_VEN.ID_CIRCUITO_SALA
            ) FV_COM_BRK_SALA
        where ATR_VEN.ID_ATRIO_VENDITA(+) = FV_COM_BRK_SALA.ID_ATRIO_VENDITA
          and CIR_ATR.ID_CIRCUITO_ATRIO(+) = ATR_VEN.ID_CIRCUITO_ATRIO
        ) FV_COM_BRK_SALA_ATR
    where CIN_VEN.ID_CINEMA_VENDITA(+) = FV_COM_BRK_SALA_ATR.ID_CINEMA_VENDITA
      and CIR_CIN.ID_CIRCUITO_CINEMA(+) = CIN_VEN.ID_CIRCUITO_CINEMA
    ) FV_COM_BRK_SALA_ATR_CIN
    group by
           ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA,
           IMP_LORDO,
           IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE,
           IMP_RECUPERO,
           IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           ID_FORMATO,
           DESCRIZIONE,
           DURATA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           COD_POS_FISSA,
           DESC_POS_FISSA,
           FLG_TARIFFA_VARIABILE,
           DATA_INIZIO,
           DATA_FINE,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD
           order by DATA_INIZIO,DATA_FINE,ID_CIRCUITO;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_PROD_ACQUISTATI_PIANO_O;



-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_PROD_ACQUISTATI_PIANO_SOSPESO
--
-- DESCRIZIONE:  Restituisce tutti i prodotti acquistati di un piano sospeso
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_data_inizio           Data di inizio del periodo cercato
--  p_data_fine             Data di fine del periodo cercato
--
--  OUTPUT: lista di prodotti acquistati appartenenti al piano sospeso
--
-- REALIZZATORE: Michele Borgogno , Altran, Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROD_ACQ_PIANO_SOSPESO(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_PROD_ACQ_PIANO IS
--
v_prodotti C_PROD_ACQ_PIANO;
BEGIN
OPEN v_prodotti FOR
    SELECT ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA, IMP_LORDO, IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE, IMP_RECUPERO, IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS IMP_LORDO_COMM,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS IMP_LORDO_DIR,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS PERC_SCONTO_COMM,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS PERC_SCONTO_DIR,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           GET_COD_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as COD_SOGGETTO,
           GET_DESC_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as DESC_SOGGETTO,
           GET_TITOLO_MATERIALE(ID_PRODOTTO_ACQUISTATO) as TITOLO_MAT,
           count(distinct ID_SCHERMO) num_schermi,
           count(distinct ID_SALA) num_sale,
           count(distinct ID_ATRIO) num_atrii,
           count(distinct ID_CINEMA) num_cinema,
           --count(distinct ID_COMUNICATO) as num_comunicati,
           0 as num_comunicati,
           ID_FORMATO,
           DESCRIZIONE AS DESC_FORMATO,
           DURATA,
           COD_POS_FISSA, DESC_POS_FISSA,
           FLG_TARIFFA_VARIABILE,
           DATA_INIZIO,
           DATA_FINE,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD
    FROM
        (SELECT CIR_CIN.ID_CINEMA,
               --CIR_CIN.ID_CIRCUITO_CINEMA, CIN_VEN.ID_CINEMA_VENDITA,
               FV_COM_BRK_SALA_ATR.*
        FROM
               CD_CIRCUITO_CINEMA CIR_CIN,
               CD_CINEMA_VENDITA CIN_VEN,
            (SELECT CIR_ATR.ID_ATRIO,
                   --CIR_ATR.ID_CIRCUITO_ATRIO, ATRIO_VEN.ID_ATRIO_VENDITA,
                   FV_COM_BRK_SALA.*
            FROM
                   CD_CIRCUITO_ATRIO CIR_ATR,
                   CD_ATRIO_VENDITA ATR_VEN,
                (SELECT CIR_SALA.ID_SALA,
                       --CIR_SALA.ID_CIRCUITO_SALA, SALA_VEN.ID_SALA_VENDITA,
                       FV_COM_BRK.*
                  FROM
                       CD_CIRCUITO_SALA CIR_SALA,
                       CD_SALA_VENDITA SALA_VEN,
                (SELECT CD_SCHERMO.ID_SCHERMO,
                       --PROIEZ.ID_PROIEZIONE, CD_BREAK.ID_BREAK, CIR_BR.ID_CIRCUITO_BREAK, BR_VEN.ID_BREAK_VENDITA,
                       FV_COM.*
                FROM
                       CD_SCHERMO,
                       CD_PROIEZIONE PROIEZ,
                       CD_BREAK,
                       CD_CIRCUITO_BREAK CIR_BR,
                       CD_BREAK_VENDITA  BR_VEN,
                       (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO,
                               PR_ACQ.ID_PRODOTTO_VENDITA,
                               PR_PUB.DESC_PRODOTTO,
                               CD_CIRCUITO.ID_CIRCUITO,
                               CD_CIRCUITO.NOME_CIRCUITO,
                               MOD_VEN.ID_MOD_VENDITA,
                               MOD_VEN.DESC_MOD_VENDITA,
                               TI_BR.ID_TIPO_BREAK,
                               TI_BR.DESC_TIPO_BREAK,
                               PC_MANIF.DES_MAN,
                               PR_ACQ.ID_RAGGRUPPAMENTO,
                               PR_ACQ.ID_FRUITORI_DI_PIANO,
                               PR_ACQ.STATO_DI_VENDITA,
                               PR_ACQ.IMP_TARIFFA, PR_ACQ.IMP_LORDO, PR_ACQ.IMP_NETTO,
                               PR_ACQ.FLG_TARIFFA_VARIABILE,
                               PR_ACQ.DATA_INIZIO,
                               PR_ACQ.DATA_FINE,
                               PR_ACQ.ID_TIPO_CINEMA,
                               IMP_PRD_D.IMP_NETTO as IMP_NETTO_DIR,
                               IMP_PRD_D.IMP_SC_COMM as IMP_SC_DIR,
                               IMP_PRD_C.IMP_NETTO as IMP_NETTO_COMM,
                               IMP_PRD_C.IMP_SC_COMM as IMP_SC_COMM,
                                PR_ACQ.IMP_MAGGIORAZIONE, PR_ACQ.IMP_RECUPERO, PR_ACQ.IMP_SANATORIA,
                               COM.ID_COMUNICATO, COM.ID_BREAK_VENDITA, COM.ID_SALA_VENDITA, COM.ID_ATRIO_VENDITA, COM.ID_CINEMA_VENDITA,
                               POS.COD_POSIZIONE AS COD_POS_FISSA, POS.DESCRIZIONE AS DESC_POS_FISSA,
                               F_ACQ.ID_FORMATO, F_ACQ.DESCRIZIONE, COEF.DURATA, TAR.ID_TIPO_TARIFFA,
                               PERIODO.ANNO ||'-'||PERIODO.CICLO||'-'||PERIODO.PER AS SETTIMANA_SIPRA,
                               PR_ACQ.DATAMOD
                         FROM
                               PERIODI PERIODO,
                               CD_POSIZIONE_RIGORE POS,
                               CD_COMUNICATO COM,
                               PC_MANIF,
                               CD_TIPO_BREAK TI_BR,
                               CD_MODALITA_VENDITA MOD_VEN,
                               CD_CIRCUITO,
                               CD_PRODOTTO_PUBB PR_PUB,
                               CD_TARIFFA TAR,
                               CD_PRODOTTO_VENDITA PR_VEN,
                               CD_COEFF_CINEMA COEF,
                               CD_FORMATO_ACQUISTABILE F_ACQ,
                               CD_IMPORTI_PRODOTTO IMP_PRD_D,
                               CD_IMPORTI_PRODOTTO IMP_PRD_C,
                               CD_PRODOTTO_ACQUISTATO PR_ACQ
                          WHERE PR_ACQ.ID_PIANO = p_id_piano
                            and PR_ACQ.ID_VER_PIANO = p_id_ver_piano
                            and PR_ACQ.FLG_ANNULLATO = 'N'
                            and PR_ACQ.FLG_SOSPESO = 'S'
                            and PR_ACQ.COD_DISATTIVAZIONE is null
                            and IMP_PRD_C.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and IMP_PRD_C.TIPO_CONTRATTO = 'C'
                            and IMP_PRD_D.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and IMP_PRD_D.TIPO_CONTRATTO = 'D'
                            and F_ACQ.ID_FORMATO = PR_ACQ.ID_FORMATO
                            AND COEF.ID_COEFF(+) = F_ACQ.ID_COEFF
                            and PR_VEN.ID_PRODOTTO_VENDITA = PR_ACQ.ID_PRODOTTO_VENDITA
                            and TAR.ID_PRODOTTO_VENDITA = PR_VEN.ID_PRODOTTO_VENDITA
                            and PR_ACQ.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
                            and PR_ACQ.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
                            and PR_PUB.ID_PRODOTTO_PUBB = PR_VEN.ID_PRODOTTO_PUBB
                            and CD_CIRCUITO.ID_CIRCUITO = PR_VEN.ID_CIRCUITO
                            and MOD_VEN.ID_MOD_VENDITA = PR_VEN.ID_MOD_VENDITA
                            and TI_BR.ID_TIPO_BREAK(+) = PR_VEN.ID_TIPO_BREAK
                            and PC_MANIF.COD_MAN(+) = PR_VEN.COD_MAN
                            and COM.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and COM.FLG_ANNULLATO='N'
                            and COM.FLG_SOSPESO='S'
                            and COM.COD_DISATTIVAZIONE IS NULL
                            and POS.COD_POSIZIONE (+) = COM.POSIZIONE_DI_RIGORE
                            and PR_ACQ.DATA_INIZIO = PERIODO.DATA_INIZ (+)
                            and PR_ACQ.DATA_FINE = PERIODO.DATA_FINE (+)
                            ) FV_COM
            where BR_VEN.ID_BREAK_VENDITA(+) = FV_COM.ID_BREAK_VENDITA
              and CIR_BR.ID_CIRCUITO_BREAK(+) = BR_VEN.ID_CIRCUITO_BREAK
              and CD_BREAK.ID_BREAK(+) = CIR_BR.ID_BREAK
              and PROIEZ.ID_PROIEZIONE(+) = CD_BREAK.ID_PROIEZIONE
              and CD_SCHERMO.ID_SCHERMO(+) = PROIEZ.ID_SCHERMO
            ) FV_COM_BRK
            where SALA_VEN.ID_SALA_VENDITA(+) = FV_COM_BRK.ID_SALA_VENDITA
              and CIR_SALA.ID_CIRCUITO_SALA(+) = SALA_VEN.ID_CIRCUITO_SALA
            ) FV_COM_BRK_SALA
        where ATR_VEN.ID_ATRIO_VENDITA(+) = FV_COM_BRK_SALA.ID_ATRIO_VENDITA
          and CIR_ATR.ID_CIRCUITO_ATRIO(+) = ATR_VEN.ID_CIRCUITO_ATRIO
        ) FV_COM_BRK_SALA_ATR
    where CIN_VEN.ID_CINEMA_VENDITA(+) = FV_COM_BRK_SALA_ATR.ID_CINEMA_VENDITA
      and CIR_CIN.ID_CIRCUITO_CINEMA(+) = CIN_VEN.ID_CIRCUITO_CINEMA
    ) FV_COM_BRK_SALA_ATR_CIN
    group by
           ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA,
           IMP_LORDO,
           IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE,
           IMP_RECUPERO,
           IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           ID_FORMATO,
           DESCRIZIONE,
           DURATA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           COD_POS_FISSA,
           DESC_POS_FISSA,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_PROD_ACQ_PIANO_SOSPESO;
-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_PROD_ACQUISTATI_SOGG
--
-- DESCRIZIONE:  Restituisce tutti i prodotti acquistati di un piano da associare ad un soggetto
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_data_inizio           Data di inizio del periodo cercato
--  p_data_fine             Data di fine del periodo cercato
--
--  OUTPUT: lista di prodotti acquistati appartenenti al piano
--
-- REALIZZATORE: Michele Borgogno , Altran, Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROD_ACQUISTATI_SOGG(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_PROD_ACQ_SOGG IS
--
v_prodotti C_PROD_ACQ_SOGG;
BEGIN
OPEN v_prodotti FOR
    SELECT ID_PRODOTTO_ACQUISTATO,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA, IMP_LORDO, IMP_NETTO, IMP_SCO_COMM,
        --   IMP_NETTO_DIR,
            IMP_MAGGIORAZIONE, IMP_RECUPERO, IMP_SANATORIA,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO,IMP_SCO_COMM) AS PERC_SCONTO_COMM,
           ID_RAGGRUPPAMENTO,
           GET_DESC_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as DESC_SOGGETTO,
           count(distinct ID_SCHERMO) num_schermi,
           count(distinct ID_SALA) num_sale,
           count(distinct ID_ATRIO) num_atrii,
           count(distinct ID_CINEMA) num_cinema,
           --count(distinct ID_COMUNICATO) as num_comunicati,
           0 as num_comunicati,
           ID_FORMATO,
           DESCRIZIONE AS DESC_FORMATO
    FROM
        (SELECT CIR_CIN.ID_CINEMA,
               --CIR_CIN.ID_CIRCUITO_CINEMA, CIN_VEN.ID_CINEMA_VENDITA,
               FV_COM_BRK_SALA_ATR.*
        FROM
               CD_CIRCUITO_CINEMA CIR_CIN,
               CD_CINEMA_VENDITA CIN_VEN,
            (SELECT CIR_ATR.ID_ATRIO,
                   --CIR_ATR.ID_CIRCUITO_ATRIO, ATRIO_VEN.ID_ATRIO_VENDITA,
                   FV_COM_BRK_SALA.*
            FROM
                   CD_CIRCUITO_ATRIO CIR_ATR,
                   CD_ATRIO_VENDITA ATR_VEN,
                (SELECT CIR_SALA.ID_SALA,
                       --CIR_SALA.ID_CIRCUITO_SALA, SALA_VEN.ID_SALA_VENDITA,
                       FV_COM_BRK.*
                  FROM
                       CD_CIRCUITO_SALA CIR_SALA,
                       CD_SALA_VENDITA SALA_VEN,
                (SELECT CD_SCHERMO.ID_SCHERMO,
                       --PROIEZ.ID_PROIEZIONE, CD_BREAK.ID_BREAK, CIR_BR.ID_CIRCUITO_BREAK, BR_VEN.ID_BREAK_VENDITA,
                       FV_COM.*
                FROM
                       CD_SCHERMO,
                       CD_PROIEZIONE PROIEZ,
                       CD_BREAK,
                       CD_CIRCUITO_BREAK CIR_BR,
                       CD_BREAK_VENDITA  BR_VEN,
                       (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO,
                               PR_PUB.DESC_PRODOTTO,
                               CD_CIRCUITO.ID_CIRCUITO,
                               CD_CIRCUITO.NOME_CIRCUITO,
                               MOD_VEN.DESC_MOD_VENDITA,
                               TI_BR.ID_TIPO_BREAK,
                               TI_BR.DESC_TIPO_BREAK,
                               PC_MANIF.DES_MAN,
                               PR_ACQ.ID_RAGGRUPPAMENTO,
                               PR_ACQ.IMP_TARIFFA, PR_ACQ.IMP_LORDO, PR_ACQ.IMP_NETTO,
                               -- PR_ACQ.IMP_SCO_COMM,
                               0 AS IMP_SCO_COMM,
                            --   PR_ACQ.IMP_NETTO_DIR,
                                PR_ACQ.IMP_MAGGIORAZIONE, PR_ACQ.IMP_RECUPERO, PR_ACQ.IMP_SANATORIA,
                               COM.ID_COMUNICATO, COM.ID_BREAK_VENDITA, COM.ID_SALA_VENDITA, COM.ID_ATRIO_VENDITA, COM.ID_CINEMA_VENDITA,
                               F_ACQ.ID_FORMATO, F_ACQ.DESCRIZIONE
                         FROM
                               CD_COMUNICATO COM,
                               PC_MANIF,
                               CD_TIPO_BREAK TI_BR,
                               CD_MODALITA_VENDITA MOD_VEN,
                               CD_CIRCUITO,
                               CD_PRODOTTO_PUBB PR_PUB,
                               CD_PRODOTTO_VENDITA PR_VEN,
                               CD_FORMATO_ACQUISTABILE F_ACQ,
                               CD_PRODOTTO_ACQUISTATO PR_ACQ
                          WHERE PR_ACQ.ID_PIANO = p_id_piano
                            and PR_ACQ.ID_VER_PIANO = p_id_ver_piano
                            and PR_ACQ.FLG_ANNULLATO = 'N'
                            and PR_ACQ.FLG_SOSPESO = 'N'
                            and PR_ACQ.COD_DISATTIVAZIONE is null
                            and F_ACQ.ID_FORMATO = PR_ACQ.ID_FORMATO
                            and PR_VEN.ID_PRODOTTO_VENDITA = PR_ACQ.ID_PRODOTTO_VENDITA
                            and PR_PUB.ID_PRODOTTO_PUBB = PR_VEN.ID_PRODOTTO_PUBB
                            and CD_CIRCUITO.ID_CIRCUITO = PR_VEN.ID_CIRCUITO
                            and MOD_VEN.ID_MOD_VENDITA = PR_VEN.ID_MOD_VENDITA
                            and TI_BR.ID_TIPO_BREAK(+) = PR_VEN.ID_TIPO_BREAK
                            and PC_MANIF.COD_MAN(+) = PR_VEN.COD_MAN
                            and COM.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and COM.FLG_ANNULLATO='N'
                            and COM.FLG_SOSPESO='N'
                            and COM.COD_DISATTIVAZIONE IS NULL) FV_COM
            where BR_VEN.ID_BREAK_VENDITA(+) = FV_COM.ID_BREAK_VENDITA
              and CIR_BR.ID_CIRCUITO_BREAK(+) = BR_VEN.ID_CIRCUITO_BREAK
              and CD_BREAK.ID_BREAK(+) = CIR_BR.ID_BREAK
              and PROIEZ.ID_PROIEZIONE(+) = CD_BREAK.ID_PROIEZIONE
              and CD_SCHERMO.ID_SCHERMO(+) = PROIEZ.ID_SCHERMO
            ) FV_COM_BRK
            where SALA_VEN.ID_SALA_VENDITA(+) = FV_COM_BRK.ID_SALA_VENDITA
              and CIR_SALA.ID_CIRCUITO_SALA(+) = SALA_VEN.ID_CIRCUITO_SALA
            ) FV_COM_BRK_SALA
        where ATR_VEN.ID_ATRIO_VENDITA(+) = FV_COM_BRK_SALA.ID_ATRIO_VENDITA
          and CIR_ATR.ID_CIRCUITO_ATRIO(+) = ATR_VEN.ID_CIRCUITO_ATRIO
        ) FV_COM_BRK_SALA_ATR
    where CIN_VEN.ID_CINEMA_VENDITA(+) = FV_COM_BRK_SALA_ATR.ID_CINEMA_VENDITA
      and CIR_CIN.ID_CIRCUITO_CINEMA(+) = CIN_VEN.ID_CIRCUITO_CINEMA
    ) FV_COM_BRK_SALA_ATR_CIN
    group by
           ID_PRODOTTO_ACQUISTATO,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA,
           IMP_LORDO,
           IMP_NETTO,
           IMP_SCO_COMM,
    --       IMP_NETTO_DIR,
           IMP_MAGGIORAZIONE,
           IMP_RECUPERO,
           IMP_SANATORIA,
           ID_FORMATO,
           DESCRIZIONE,
           ID_RAGGRUPPAMENTO;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_PROD_ACQUISTATI_SOGG;

-----------------------------------------------------------------------------------------------------
-- Funzione GET_COD_SOGGETTO
--
-- DESCRIZIONE:  Restituisce il codice del soggetto di un prodotto acquistato
--
--
-- OPERAZIONI:
--            1) Verifica il numero di soggetti associati ai comunicati del prodotto acquistato
--            2) Restituisce il codice del soggetto
--
--  INPUT:
--  p_id_prodotto_acquistato   id del prodotto acquistato
--  OUTPUT:
--      se tutti i comunicati del prodotto acquistato sono associati ad un unico soggetto
--      restituisce il suo codice, altrimenti restituisce *
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION GET_COD_SOGGETTO(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2 IS
cod_soggetto VARCHAR2(6);

num_righe NUMBER;

BEGIN
    SELECT COUNT(DISTINCT ID_SOGGETTO_DI_PIANO) INTO num_righe
        FROM CD_COMUNICATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;
    --
    if num_righe = 1
        then
            SELECT DISTINCT sdp.COD_SOGG INTO cod_soggetto
                FROM CD_SOGGETTO_DI_PIANO sdp, CD_COMUNICATO com
                WHERE com.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND sdp.ID_SOGGETTO_DI_PIANO = com.ID_SOGGETTO_DI_PIANO
                AND com.FLG_ANNULLATO = 'N'
                AND com.FLG_SOSPESO = 'N'
                AND com.COD_DISATTIVAZIONE IS NULL;
        else
            cod_soggetto := '*';
    end if;

RETURN cod_soggetto;
END GET_COD_SOGGETTO;

-----------------------------------------------------------------------------------------------------
-- Funzione GET_DESC_SOGGETTO
--
-- DESCRIZIONE:  Restituisce la descrizione del soggetto di un prodotto acquistato
--
--
-- OPERAZIONI:
--            1) Verifica il numero di soggetti associati ai comunicati del prodotto acquistato
--            2) Restituisce la descrizione del soggetto
--
--  INPUT:
--      p_id_prodotto_acquistato   id del prodotto acquistato
--  OUTPUT:
--      se tutti i comunicati del prodotto acquistato sono associati ad un unico soggetto
--      restituisce la sua descrizione, altrimenti restituisce *
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION GET_DESC_SOGGETTO(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE IS
desc_soggetto CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE;

num_righe NUMBER;

BEGIN

    SELECT COUNT(DISTINCT ID_SOGGETTO_DI_PIANO) INTO num_righe
        FROM CD_COMUNICATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;
     --   AND sdp.ID_SOGGETTO_DI_PIANO = com.ID_SOGGETTO_DI_PIANO;
    if num_righe = 1
        then
            SELECT DISTINCT sdp.DESCRIZIONE INTO desc_soggetto
                FROM CD_SOGGETTO_DI_PIANO sdp, CD_COMUNICATO com
                WHERE com.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND com.FLG_ANNULLATO = 'N'
                AND com.FLG_SOSPESO = 'N'
                AND com.COD_DISATTIVAZIONE IS NULL
                AND sdp.ID_SOGGETTO_DI_PIANO = com.ID_SOGGETTO_DI_PIANO;
        else
            desc_soggetto := '*';
    end if;

RETURN desc_soggetto;
END GET_DESC_SOGGETTO;

-----------------------------------------------------------------------------------------------------
-- Funzione GET_TITOLO_MATERIALE
--
-- DESCRIZIONE:  Restituisce il titolo del materiale di un prodotto acquistato
--
--
-- OPERAZIONI:
--            1) Verifica il numero di materiali associati ai comunicati del prodotto acquistato
--            2) Restituisce il titolo del materiale
--
--  INPUT:
--      p_id_prodotto_acquistato   id del prodotto acquistato
--  OUTPUT:
--      se tutti i comunicati del prodotto acquistato sono associati ad un unico materiale
--      restituisce il suo titolo, altrimenti restituisce *
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION GET_TITOLO_MATERIALE(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN CD_MATERIALE.TITOLO%TYPE IS
titolo_materiale CD_MATERIALE.TITOLO%TYPE;

num_righe NUMBER;

BEGIN

    SELECT COUNT(DISTINCT NVL(ID_MATERIALE_DI_PIANO,0)) INTO num_righe
        FROM CD_COMUNICATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;
     --   AND sdp.ID_SOGGETTO_DI_PIANO = com.ID_SOGGETTO_DI_PIANO;

    if num_righe = 1
        then
            SELECT DISTINCT MAT.TITOLO INTO titolo_materiale
                FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT, CD_COMUNICATO COM
                WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND COM.FLG_ANNULLATO = 'N'
                AND COM.FLG_SOSPESO = 'N'
                AND COM.COD_DISATTIVAZIONE is null
                AND MAT_PIA.ID_MATERIALE_DI_PIANO = COM.ID_MATERIALE_DI_PIANO
                AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE;
        else
            titolo_materiale := '*';
    end if;

RETURN titolo_materiale;
END GET_TITOLO_MATERIALE;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_TOTALI_PROD_ACQ
--
-- DESCRIZIONE:  Restituisce informazioni sui totali di importi (lordo, netto ecc) di prodotti acquistati in un piano
--
--
-- OPERAZIONI:
--            1) Estrae tutti i prodotti acquistati di un piano e restituisce la somma degli importi
--
--  INPUT:
--      p_id_piano   id del piano
--      p_id_ver_piano
--  OUTPUT:
--      se tutti i comunicati del prodotto acquistato sono associati ad un unico materiale
--      restituisce il suo titolo, altrimenti restituisce *
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_TOTALI_PROD_ACQ(
                                  p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                  p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN C_TOT_PROD_ACQ_PIANO IS
--
v_prodotti C_TOT_PROD_ACQ_PIANO;
BEGIN
OPEN v_prodotti FOR


  SELECT NUM_PRODOTTI,
       SUM_TARIFFA,
       SUM_LORDO,
       SUM_NETTO,
       SUM_SCONTO,
       0 AS SUM_NETTO_DIR,
       SUM_MAGGIORAZIONE,
       SUM_RECUPERO,
       SUM_SANATORIA,
       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM_NETTO, SUM_SCONTO),0) AS AVG_SCONTO,
       TRUNC(nettoComm, 3) as TOT_NETTO_C, TRUNC(nettoDir, 3) as TOT_NETTO_D,
       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoComm, scComCom),0) as TOT_PERC_SCONTO_C,
       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoDir, scComDir),0) as TOT_PERC_SCONTO_D
       --TRUNC(AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoComm, scComCom),0)),3) as TOT_PERC_SCONTO_C,
       --TRUNC(AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(nettoDir, scComDir),0)),3) as TOT_PERC_SCONTO_D
       --TRUNC(percScontoComm, 3) as TOT_PERC_SCONTO_C,
       --TRUNC(percScontoDir, 3) as TOT_PERC_SCONTO_D
    FROM(
    SELECT
       COUNT(pr.ID_PRODOTTO_ACQUISTATO) AS NUM_PRODOTTI,
       NVL(SUM(pr.IMP_TARIFFA),0) AS SUM_TARIFFA,
       NVL(SUM(pr.IMP_LORDO),0) AS SUM_LORDO,
       NVL(SUM(pr.IMP_NETTO),0) AS SUM_NETTO,
       0 AS SUM_SCONTO,
       0 AS SUM_NETTO_DIR,
       NVL(SUM(pr.IMP_MAGGIORAZIONE),0) AS SUM_MAGGIORAZIONE,
       NVL(SUM(pr.IMP_RECUPERO),0) AS SUM_RECUPERO,
       NVL(SUM(pr.IMP_SANATORIA),0) AS SUM_SANATORIA,
       NVL(SUM(ipc.IMP_NETTO), 0) as nettoComm,
       NVL(SUM(ipd.IMP_NETTO), 0) as nettoDir,
       NVL(SUM(ipc.imp_sc_comm), 0) as scComCom,
       NVL(SUM(ipd.imp_sc_comm), 0) as scComDir
       --AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipc.imp_netto, ipc.imp_sc_comm),0)) as percScontoComm,
       --AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto, ipd.imp_sc_comm),0)) as percScontoDir
  FROM CD_PRODOTTO_ACQUISTATO pr, cd_importi_prodotto ipc, cd_importi_prodotto ipd
  WHERE pr.ID_PIANO = p_id_piano
  AND pr.ID_VER_PIANO = p_id_ver_piano
  AND pr.FLG_ANNULLATO = 'N'
  AND pr.FLG_SOSPESO = 'N'
  AND pr.COD_DISATTIVAZIONE IS NULL
  and ipc.id_prodotto_acquistato = pr.id_prodotto_acquistato
  and ipc.TIPO_CONTRATTO = 'C'
  and ipd.id_prodotto_acquistato = pr.id_prodotto_acquistato
  and ipd.TIPO_CONTRATTO = 'D'
  );

    /*SELECT NUM_PRODOTTI,
       SUM_TARIFFA,
       SUM_LORDO,
       SUM_NETTO,
       SUM_SCONTO,
       0 AS SUM_NETTO_DIR,
       SUM_MAGGIORAZIONE,
       SUM_RECUPERO,
       SUM_SANATORIA,
       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM_NETTO, SUM_SCONTO),0) AS AVG_SCONTO,
       TRUNC(nettoComm, 3) as TOT_NETTO_C, TRUNC(nettoDir, 3) as TOT_NETTO_D,
       TRUNC(percScontoComm, 3) as TOT_PERC_SCONTO_C,
       TRUNC(percScontoDir, 3) as TOT_PERC_SCONTO_D
    FROM(
    SELECT
       COUNT(pr.ID_PRODOTTO_ACQUISTATO) AS NUM_PRODOTTI,
       NVL(SUM(pr.IMP_TARIFFA),0) AS SUM_TARIFFA,
       NVL(SUM(pr.IMP_LORDO),0) AS SUM_LORDO,
       NVL(SUM(pr.IMP_NETTO),0) AS SUM_NETTO,
    --   SUM(IMP_SCO_COMM) AS SUM_SCONTO,
       0 AS SUM_SCONTO,
  --     SUM(IMP_NETTO_DIR) AS SUM_NETTO_DIR,
       0 AS SUM_NETTO_DIR,
       NVL(SUM(pr.IMP_MAGGIORAZIONE),0) AS SUM_MAGGIORAZIONE,
       NVL(SUM(pr.IMP_RECUPERO),0) AS SUM_RECUPERO,
       NVL(SUM(pr.IMP_SANATORIA),0) AS SUM_SANATORIA,
       NVL(SUM(ipc.IMP_NETTO), 0) as nettoComm, NVL(SUM(ipd.IMP_NETTO), 0) as nettoDir,
       AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipc.imp_netto, ipc.imp_sc_comm),0)) as percScontoComm,
       AVG(NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(ipd.imp_netto, ipd.imp_sc_comm),0)) as percScontoDir
  FROM CD_PRODOTTO_ACQUISTATO pr, cd_importi_prodotto ipc, cd_importi_prodotto ipd
  WHERE pr.ID_PIANO = p_id_piano
  AND pr.ID_VER_PIANO = p_id_ver_piano
  AND pr.FLG_ANNULLATO = 'N'
  AND pr.FLG_SOSPESO = 'N'
  AND pr.COD_DISATTIVAZIONE IS NULL
  and ipc.id_prodotto_acquistato = pr.id_prodotto_acquistato
  and ipc.TIPO_CONTRATTO = 'C'
  and ipd.id_prodotto_acquistato = pr.id_prodotto_acquistato
  and ipd.TIPO_CONTRATTO = 'D');*/

--    SELECT NUM_PRODOTTI,
--       SUM_TARIFFA,
--       SUM_LORDO,
--       SUM_NETTO,
--       SUM_SCONTO,
--       0 AS SUM_NETTO_DIR,
--       SUM_MAGGIORAZIONE,
--       SUM_RECUPERO,
--       SUM_SANATORIA,
--       NVL(PA_PC_IMPORTI.FU_PERC_SC_COMM(SUM_NETTO, SUM_SCONTO),0) AS AVG_SCONTO
--    FROM(
--    SELECT
--       COUNT(ID_PRODOTTO_ACQUISTATO) AS NUM_PRODOTTI,
--       NVL(SUM(IMP_TARIFFA),0) AS SUM_TARIFFA,
--       NVL(SUM(IMP_LORDO),0) AS SUM_LORDO,
--       NVL(SUM(IMP_NETTO),0) AS SUM_NETTO,
--    --   SUM(IMP_SCO_COMM) AS SUM_SCONTO,
--    0 AS SUM_SCONTO,
--  --     SUM(IMP_NETTO_DIR) AS SUM_NETTO_DIR,
--       0 AS SUM_NETTO_DIR,
--       NVL(SUM(IMP_MAGGIORAZIONE),0) AS SUM_MAGGIORAZIONE,
--       NVL(SUM(IMP_RECUPERO),0) AS SUM_RECUPERO,
--       NVL(SUM(IMP_SANATORIA),0) AS SUM_SANATORIA
--  FROM CD_PRODOTTO_ACQUISTATO
--  WHERE CD_PRODOTTO_ACQUISTATO.ID_PIANO = p_id_piano
--  AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = p_id_ver_piano
--  AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO = 'N'
--  AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N')
  --AND CD_PRODOTTO_ACQUISTATO.DATA_INIZIO BETWEEN p_data_inizio AND p_data_fine
--  ;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_TOTALI_PROD_ACQ;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_FORMATO_PROD_ACQ
--
-- DESCRIZIONE:  Restituisce la descrizione del formato acquistabile di un prodotto acquistato
--
--
-- OPERAZIONI:
--            1) Verifica il prodotto di vendita del prodotto acquistato, e restituisce
--               la descrizione del formato acquistabile collegata
--
--  INPUT:
--      p_id_prod_acq   id del prodotto acquistato
--  OUTPUT:
--      stringa la descrizione del formato acquistabile di un prodotto acquistato,
--      * se e un prodotto che contiene altri prodotti (es. Sponsorizzazione)
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_FORMATO_PROD_ACQ(
                        p_id_prod_acq CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2 IS
--
v_formato_return CD_FORMATO_ACQUISTABILE.DESCRIZIONE%TYPE;
v_id_prod_pubb CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE;
    BEGIN
--
    SELECT CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
    INTO v_id_prod_pubb
    FROM CD_PRODOTTO_PUBB, CD_PRODOTTO_VENDITA, CD_PRODOTTO_ACQUISTATO
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prod_acq
    AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
    AND CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB = CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB;

    IF v_id_prod_pubb != 8 AND v_id_prod_pubb != 9 THEN
         SELECT FORMATO
         INTO v_formato_return
         FROM (
         SELECT TO_CHAR(CD_COEFF_CINEMA.DURATA) AS FORMATO
            FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE, CD_PRODOTTO_ACQUISTATO
            WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prod_acq
            AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
            AND CD_FORMATO_ACQUISTABILE.ID_TIPO_FORMATO = 1
            AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF
          UNION
          SELECT CD_FORMATO_ACQUISTABILE.DESCRIZIONE AS FORMATO
            FROM CD_FORMATO_ACQUISTABILE, CD_PRODOTTO_ACQUISTATO
            WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prod_acq
            AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
            AND CD_FORMATO_ACQUISTABILE.ID_TIPO_FORMATO = 2);
    ELSE
        --Fatto per semplicita, poi bisognera gestire bene il caso particolare
        --di un prodotto di tipo sponsorizzazione o special weekend, andando
        -- a vedere tutti i sottoprodotti venduti insieme
        v_formato_return := '*';
    END IF;
    RETURN v_formato_return;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_FORMATO_PROD_ACQ;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_APPLICA_MAGGIORAZIONE
--
-- DESCRIZIONE:  Associa una maggiorazione ad un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_id_maggiorazione            Id della maggiorazione
--
--  OUTPUT:
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_SALVA_MAGGIORAZIONE(
                                p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_maggiorazione       CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE%TYPE) IS
--
v_num NUMBER;
v_num_pos_fissa NUMBER;
BEGIN
/*    SELECT COUNT(1)
    INTO v_num
    FROM CD_MAGG_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND ID_MAGGIORAZIONE = p_id_maggiorazione;
--
    SELECT COUNT(1)
    INTO v_num_pos_fissa
    FROM  CD_MAGGIORAZIONE M, CD_MAGG_PRODOTTO MP
    WHERE MP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE
    AND M.ID_TIPO_MAGG = 1;

    IF v_num_pos_fissa = 1 THEN
        DELETE FROM CD_MAGG_PRODOTTO WHERE
        ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND ID_MAGGIORAZIONE IN
        (SELECT M.ID_MAGGIORAZIONE FROM  CD_MAGGIORAZIONE M, CD_MAGG_PRODOTTO MP
        WHERE MP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE
        AND M.ID_TIPO_MAGG = 1 );
    END IF;
*/
--    IF v_num = 0 THEN
        INSERT INTO CD_MAGG_PRODOTTO(ID_PRODOTTO_ACQUISTATO, ID_MAGGIORAZIONE)
        VALUES(p_id_prodotto_acquistato,p_id_maggiorazione);
--    END IF;
EXCEPTION
  WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_APPLICA_MAGGIORAZIONE: Errore');
END PR_SALVA_MAGGIORAZIONE;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_RIMUOVI_MAGGIORAZIONE
--
-- DESCRIZIONE:  Elimina l'associazione tra una maggiorazione ed un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_id_maggiorazione            Id della maggiorazione
--
--  OUTPUT:
--  p_imp_maggiorazione           Nuovo importo di maggiorazione
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RIMUOVI_MAGGIORAZIONE(
                                p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_maggiorazione       CD_MAGG_PRODOTTO.ID_MAGGIORAZIONE%TYPE,
                                p_imp_maggiorazione      OUT NUMBER) IS
v_perc_maggiorazione CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE%TYPE;
BEGIN
    SAVEPOINT PR_RIMUOVI_MAGGIORAZIONE;
--
   SELECT PERCENTUALE_VARIAZIONE
    INTO v_perc_maggiorazione
    FROM CD_MAGGIORAZIONE
    WHERE ID_MAGGIORAZIONE = p_id_maggiorazione;

--
SELECT IMP_MAGGIORAZIONE -
    PA_CD_TARIFFA.FU_CALCOLA_MAGGIORAZIONE(CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA,
                v_perc_maggiorazione)
    INTO p_imp_maggiorazione
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
--
    UPDATE CD_PRODOTTO_ACQUISTATO
    SET IMP_MAGGIORAZIONE = p_imp_maggiorazione
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
--
    DELETE FROM CD_MAGG_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND ID_MAGGIORAZIONE = p_id_maggiorazione;
EXCEPTION
  WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_RIMUOVI_MAGGIORAZIONE: Errore');
  ROLLBACK TO PR_RIMUOVI_MAGGIORAZIONE;
END PR_RIMUOVI_MAGGIORAZIONE;

-----------------------------------------------------------------------------------------------------
-- Procedura MODIFICA_PRODOTTO_ACQUISTATO
--
-- DESCRIZIONE:  Effettua la modifica di un prodotto acquistato
--
--
-- OPERAZIONI: Modifica il prodotto acquistato
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_stato_vendita               Stato di vendita
--  p_imp_tariffa                 importo di tariffa
--  p_imp_lordo                   importo lordo
--  p_imp_sanatoria               importo sanatoria
--  p_imp_recupero                importo di recupero
--  p_imp_maggiorazione           importo di maggiorazione
--  p_netto_comm                  importo netto
--  p_sconto_comm                 importo di sconto commerciale
--  p_netto_dir                   importo netto direzionale
--  p_sconto_dir                  importo di sconto direzionale
--  p_posizione_rigore            Posizione di rigore richiesta
--  p_id_formato                  id del formato acquistabile del prodotto
--  p_id_tariffa_variabile        Flg di tariffa variabile
--  p_lordo_saltato               Importo lordo saltato
--  p_list_maggiorazioni          Lista di maggiorazioni applicate al prodotto
--
--  OUTPUT:
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--  04/03/201 Michele Borgogno AGGIUNTO IN INPUT L'IMPORTO LORDO SALTATO
-------------------------------------------------------------------------------------------------
PROCEDURE MODIFICA_PRODOTTO_ACQUISTATO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                    p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                    p_imp_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
                    p_imp_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
                    p_imp_sanatoria CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE,
                    p_imp_recupero CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE,
                    p_imp_maggiorazione CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
                    p_netto_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_netto_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
                    p_sconto_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
                    p_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                    p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                    p_id_tariffa_variabile CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
                    p_lordo_saltato CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE,
                    p_list_maggiorazioni    id_list_type) IS
--
v_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE;
v_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE;
v_netto_comm_vecchio CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_netto_dir_vecchio CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm_vecchio CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_imp_sc_dir_vecchio CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_importo_prodotto CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_vecchio_stato_ven CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
BEGIN
    SAVEPOINT MODIFICA_PRODOTTO_ACQUISTATO;
/*
--***************************************************************************************************************
-- PER chi modifichera' questa query: le due quesry sottostanti servono per recuperare rispettivamente
-- la quota direzionale e la quota commerciale dell'importo lordo saltato.
-- Per cui allo stessomodo (con le relative UPDATE/SET) vanno aggiornati   (F. Abbundo)
--***************************************************************************************************************
    SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
    INTO   v_lordo_saltato_d
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
       --poi quello commerciale
       SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
       INTO   v_lordo_saltato_c
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_saltato
    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
*/
    UPDATE CD_PRODOTTO_ACQUISTATO SET
                         IMP_TARIFFA = p_imp_tariffa,
                         IMP_LORDO = p_imp_lordo,
                         IMP_NETTO = p_netto_dir + p_netto_comm,
                         IMP_SANATORIA = p_imp_sanatoria,
                         IMP_RECUPERO = p_imp_recupero,
                         IMP_MAGGIORAZIONE = p_imp_maggiorazione,
                         ID_FORMATO = p_id_formato,
                         FLG_TARIFFA_VARIABILE = p_id_tariffa_variabile,
                         IMP_LORDO_SALTATO = p_lordo_saltato
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    --
    PR_MODIFICA_STATO_VENDITA(p_id_prodotto_acquistato,p_stato_vendita);
    --
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto, v_netto_comm_vecchio,v_imp_sc_comm_vecchio
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'C';
--
    IF v_netto_comm_vecchio != p_netto_comm OR v_imp_sc_comm_vecchio != p_sconto_comm THEN
        PR_MODIFICA_IMPORTI_PRODOTTO(v_id_importo_prodotto,p_netto_comm,p_sconto_comm);
        --
        PR_RICALCOLA_IMP_FAT(v_id_importo_prodotto,v_netto_comm_vecchio,p_netto_comm);
    END IF;
    
    
--
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto, v_netto_dir_vecchio,v_imp_sc_dir_vecchio
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'D';

    IF v_netto_dir_vecchio != p_netto_dir OR v_imp_sc_dir_vecchio != p_sconto_dir THEN
        PR_MODIFICA_IMPORTI_PRODOTTO(v_id_importo_prodotto,p_netto_dir,p_sconto_dir);
        --
        PR_RICALCOLA_IMP_FAT(v_id_importo_prodotto,v_netto_dir_vecchio,p_netto_dir);
    END IF;
--
    PR_SALVA_POS_RIGORE(p_id_prodotto_acquistato,p_posizione_rigore,p_stato_vendita);
--
  DELETE FROM CD_MAGG_PRODOTTO
  WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
  IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
       FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
         PR_SALVA_MAGGIORAZIONE(p_id_prodotto_acquistato, p_list_maggiorazioni(i));
       END LOOP;
   END IF;
--
EXCEPTION
  WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA MODIFICA_PRODOTTO_ACQUISTATO: Errore' ||SQLERRM);
  ROLLBACK TO MODIFICA_PRODOTTO_ACQUISTATO;
END MODIFICA_PRODOTTO_ACQUISTATO;


-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_RIPARAMETRA_PROD_ACQ
--
-- DESCRIZIONE:  Calcola la tariffa di un prodotto acquistato
--
--
-- OPERAZIONI: In base al formato acquistabile passato viene riparametrata la tariffa del prodotto acquistato
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_id_formato                  id del formato acquistabile del prodotto
--
--  OUTPUT: importo di tariffa riparametrato
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_RIPARAMETRA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE) RETURN NUMBER IS
--v_aliquota_vecchia CD_COEFF_CINEMA.ID_COEFF%TYPE;
--v_aliquota_nuova CD_COEFF_CINEMA.ID_COEFF%TYPE;
--v_vecchia_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE := 0;
   BEGIN
--
    SELECT IMP_TARIFFA / ALIQUOTA *
    (SELECT ALIQUOTA
    --INTO v_aliquota_nuova
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE
    WHERE CD_FORMATO_ACQUISTABILE.ID_FORMATO = p_id_formato
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF)
    --INTO v_aliquota_vecchia, v_vecchia_tariffa
    INTO v_nuova_tariffa
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE, CD_PRODOTTO_ACQUISTATO
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF;
--
 /*   SELECT ALIQUOTA
    INTO v_aliquota_nuova
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE
    WHERE CD_FORMATO_ACQUISTABILE.ID_FORMATO = p_id_formato
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF;
    */
--
    --v_nuova_tariffa := (v_vecchia_tariffa / v_aliquota_vecchia) * v_aliquota_nuova;
 --   SELECT v_vecchia_tariffa / v_aliquota_vecchia * v_aliquota_nuova
  --  INTO v_nuova_tariffa
  --  FROM DUAL;
    RETURN v_nuova_tariffa;
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
END FU_GET_RIPARAMETRA_PROD_ACQ;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_RICALCOLA_IMP_SALT
--
-- DESCRIZIONE:  Calcola il lordo saltato di un prodotto acquistato
--
--
-- OPERAZIONI: In base al formato acquistabile passato viene riparametrata l'importo lordo saltato del prodotto acquistato
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_id_formato                  id del formato acquistabile del prodotto
--
--  OUTPUT: importo lordo saltato riparametrato
--
-- REALIZZATORE: Michele Borgogno, Altran, Marzo 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_RICALCOLA_IMP_SALT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE) RETURN NUMBER IS
--v_aliquota_vecchia CD_COEFF_CINEMA.ID_COEFF%TYPE;
--v_aliquota_nuova CD_COEFF_CINEMA.ID_COEFF%TYPE;
--v_vecchia_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuovo_imp_salt CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE := 0;
   BEGIN
--
--***************************************************************************************************************
-- PER chi modifichera' questa query: la riga sottostante recupera la somma delle due componenti relative all'importo
-- lordo saltato dalla tabella CD_IMPORTI_PRODOTTO (F. Abbundo)
--(SELECT SUM(CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO) FROM CD_IMPORTI_PRODOTTO WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO)
--***************************************************************************************************************
    SELECT IMP_LORDO_SALTATO / ALIQUOTA *
    (SELECT ALIQUOTA
    --INTO v_aliquota_nuova
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE
    WHERE CD_FORMATO_ACQUISTABILE.ID_FORMATO = p_id_formato
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF)
    --INTO v_aliquota_vecchia, v_vecchia_tariffa
    INTO v_nuovo_imp_salt
    FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE, CD_PRODOTTO_ACQUISTATO
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
    AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF;

    RETURN v_nuovo_imp_salt;
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
END FU_GET_RICALCOLA_IMP_SALT;

-----------------------------------------------------------------------------------------------------
-- fUNCZIONE FU_GET_STATI_VENDITA_PR_ACQ
--
-- DESCRIZIONE:  Restituisce lo stato di vendita di un prodotto acquistato,
--               oppure tutti gli stati di vendita dei prodotti acquistati di un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano                    Id del piano
--  p_id_ver_piano                Versione del piano
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--
--  OUTPUT: Lista di stati di vendita
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_STATI_VENDITA_PR_ACQ(
                                    p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                    p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                    p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_STATO_VENDITA IS
v_stati_vendita C_STATO_VENDITA;
BEGIN
 OPEN v_stati_vendita FOR
    SELECT ID_STATO_VENDITA, DESCRIZIONE, DESCR_BREVE, STATI_SUCCESSIVI
    FROM CD_STATO_DI_VENDITA, CD_PRODOTTO_ACQUISTATO
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PIANO = p_id_piano
    AND CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO = p_id_ver_piano
    AND (p_id_prodotto_acquistato IS NULL OR CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato)
    AND CD_STATO_DI_VENDITA.ID_STATO_VENDITA = CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA;
RETURN v_stati_vendita;
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
END FU_GET_STATI_VENDITA_PR_ACQ;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_INTERMEDIARI
--
-- DESCRIZIONE:  Associa un intermediario ad un prodotto acquistato
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto acquistato
--  p_id_raggruppamento                Id del raggruppamento di intermediari
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_INTERMEDIARI(p_id_prodotto_acquistato         CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                  p_id_raggruppamento              CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
                                  p_esito                           OUT NUMBER)
IS

BEGIN -- PR_ASSOCIA_INTERMEDIARI

        p_esito     := 1;

        SAVEPOINT pa_cd_prodotto_intermediari;

        -- effettuo l'UPDATE
        UPDATE CD_PRODOTTO_ACQUISTATO SET ID_RAGGRUPPAMENTO = p_id_raggruppamento
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

        PA_CD_ORDINE.PR_MODIFICA_ALIQUOTE(p_id_raggruppamento,p_id_prodotto_acquistato);

EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIA_INTERMEDIARI: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI ');
        ROLLBACK TO pa_cd_prodotto_intermediari;

END;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_INTERMEDIARI
--
-- DESCRIZIONE:  Associa un fruitore ad un prodotto acquistato
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto acquistato
--  p_id_fruitore                      Id del fruitore
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE: Mauro Viel Altran Italia Maggio 2011: Annullamento degli importi di fatturazione 
--                                                   e annullamneto dell'ordine se non ci sono piu
--                                                   importi di fatturazione validi (FLG_ANNULLATO ='N')
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_FRUITORE(p_id_prodotto_acquistato         CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                              p_id_fruitore_di_piano           CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE,
                              p_esito                          OUT NUMBER)
IS
v_fruitore CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE;
v_num_ordine number;
v_num_importi number;
v_id_ordine cd_ordine.id_ordine%type;
BEGIN -- PR_ASSOCIA_FRUITORE

        p_esito     := 1;

        SAVEPOINT pa_cd_prodotto_fruitori;
        --
        SELECT ID_FRUITORI_DI_PIANO
        INTO v_fruitore
        FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
        --
        IF nvl(v_fruitore,0) != p_id_fruitore_di_piano THEN
            -- effettuo l'UPDATE
            UPDATE CD_PRODOTTO_ACQUISTATO SET ID_FRUITORI_DI_PIANO = p_id_fruitore_di_piano
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

            --PA_CD_ORDINE.PR_MODIFICA_FRUITORE(p_id_fruitore_di_piano, p_id_prodotto_acquistato,p_esito);
            
            --Imposto gli importi di fatturazione relativi al prodotto
            
            select count(id_ordine)
            into v_num_ordine
            from  CD_IMPORTI_FATTURAZIONE
            WHERE ID_IMPORTI_PRODOTTO IN 
                              (
                                SELECT ID_IMPORTI_PRODOTTO
                                FROM   CD_IMPORTI_PRODOTTO
                                WHERE  ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                                            
                              )
            and rownum =1;      
            
            if v_num_ordine >0 then
            
                UPDATE CD_IMPORTI_FATTURAZIONE
                SET FLG_ANNULLATO = 'S'
                WHERE ID_IMPORTI_PRODOTTO IN 
                                              (
                                                SELECT ID_IMPORTI_PRODOTTO
                                                FROM   CD_IMPORTI_PRODOTTO
                                                WHERE  ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                                            
                                              )
                AND FLG_ANNULLATO = 'N'
                AND STATO_FATTURAZIONE = 'DAT';
            
                UPDATE CD_IMPORTI_FATTURAZIONE
                SET FLG_ANNULLATO = 'S',  STATO_FATTURAZIONE ='DAR'
                WHERE ID_IMPORTI_PRODOTTO IN 
                                              (
                                                SELECT ID_IMPORTI_PRODOTTO
                                                FROM   CD_IMPORTI_PRODOTTO
                                                WHERE  ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                                            
                                              )
                AND FLG_ANNULLATO = 'N'
                AND STATO_FATTURAZIONE IN('DAR','TRA');
            
            
                select id_ordine
                into v_id_ordine
                from  CD_IMPORTI_FATTURAZIONE
                WHERE ID_IMPORTI_PRODOTTO IN 
                                  (
                                    SELECT ID_IMPORTI_PRODOTTO
                                    FROM   CD_IMPORTI_PRODOTTO
                                    WHERE  ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                                            
                                  )
                and rownum =1;      
            
            
                select count(1)
                into v_num_importi
                from cd_importi_fatturazione 
                where id_ordine =  v_id_ordine
                and  FLG_ANNULLATO = 'N';
            
                if  v_num_importi = 0 then                  
                    UPDATE CD_ORDINE
                    SET FLG_ANNULLATO = 'S'
                    WHERE ID_ORDINE = V_ID_ORDINE
                    AND  FLG_ANNULLATO ='N';
                end if;
            
            end if;    
        END IF;
        EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIA_FRUITORE: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI ');
        ROLLBACK TO pa_cd_prodotto_fruitori;
END PR_ASSOCIA_FRUITORE;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_SOGGETTO_PRODOTTO
--
-- DESCRIZIONE:  Associa un soggetto ad un prodotto acquistato
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto acquistato
--  p_id_soggetto                      Id del soggetto
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Ottobre 2009
--
--  MODIFICHE:
--  11/06/2010 Michele borgogno. Aggiunta chiamata a verifica_tutela.
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_SOGGETTO_PRODOTTO(p_id_prodotto_acquistato         CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_id_soggetto                    CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_esito                            OUT NUMBER)
IS

v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;

BEGIN -- PR_ASSOCIA_SOGGETTO_PRODOTTO

        p_esito     := 1;

        SAVEPOINT pa_cd_prodotto_soggetto;

        SELECT ID_PIANO, ID_VER_PIANO INTO v_id_piano, v_id_ver_piano
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

        -- effettuo l'UPDATE
        UPDATE CD_COMUNICATO SET ID_SOGGETTO_DI_PIANO = p_id_soggetto,
        ID_MATERIALE_DI_PIANO = null
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;
        --
        PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(v_id_piano, v_id_ver_piano, null, p_id_soggetto, null);
        --
        PA_CD_ORDINE.PR_MODIFICA_SOGGETTO_ORDINE(p_id_prodotto_acquistato, p_esito);

        PR_AGGIORNA_SINTESI_PRODOTTO(p_id_prodotto_acquistato);

EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIA_SOGGETTO_PRODOTTO: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI ');
        ROLLBACK TO pa_cd_prodotto_soggetto;
END;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_SOGGETTO_COMUNICATO
--
-- DESCRIZIONE:  Associa un soggetto ad un comunicato
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_comunicato                    Id del comunicato
--  p_id_soggetto                      Id del soggetto
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_SOGGETTO_COMUNICATO(p_id_comunicato           CD_COMUNICATO.ID_COMUNICATO%TYPE,
                                         p_id_soggetto             CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_esito                   OUT NUMBER)
IS

V_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;

BEGIN -- PR_ASSOCIA_SOGGETTO_COMUNICATO

        p_esito     := 1;

        SAVEPOINT pa_cd_comunicato_soggetto;

        -- effettuo l'UPDATE
        UPDATE CD_COMUNICATO SET ID_SOGGETTO_DI_PIANO = p_id_soggetto,
        ID_MATERIALE_DI_PIANO = null
        WHERE ID_COMUNICATO = p_id_comunicato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;

        SELECT ID_PRODOTTO_ACQUISTATO
        INTO   V_ID_PRODOTTO_ACQUISTATO
        FROM CD_COMUNICATO
        WHERE ID_COMUNICATO = p_id_comunicato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;

        PR_AGGIORNA_SINTESI_PRODOTTO(V_ID_PRODOTTO_ACQUISTATO);

        --
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIA_SOGGETTO_COMUNICATO: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI MSG='||SQLERRM);
        ROLLBACK TO pa_cd_comunicato_soggetto;

END;

PROCEDURE PR_ASSOCIAZIONE_PERC_SOGGETTI(p_id_piano  CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                        p_id_ver_piano  CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                        p_lista_id_soggetti     id_list_type,
                                        p_lista_percentuali     id_list_type,
                                        p_id_sogg_non_def       NUMBER,
                                        p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                        p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                        p_esito                 OUT NUMBER)
IS

v_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_data_temp CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_id_sogg_piano CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE;
v_lista_comunicati_soggetto PA_CD_COMUNICATO.C_LISTA_COMUNICATI_SOGGETTO;
v_count_schermi_tot NUMBER;
v_count_schermi_perc NUMBER;
v_temp_schermi_perc NUMBER;
v_tot_percentuali NUMBER;
v_id_min NUMBER;
v_id_max NUMBER;
v_array_schermi_perc id_list_type := id_list_type();
v_count NUMBER;
BEGIN

    p_esito     := 1;
    SAVEPOINT pa_cd_prodotto_soggetto;

    FOR PA IN (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO, PR_ACQ.DATA_INIZIO, PR_ACQ.DATA_FINE
                -- INTO v_id_prodotto_acquistato, v_data_inizio, v_data_fine
       FROM CD_PRODOTTO_ACQUISTATO PR_ACQ
       WHERE PR_ACQ.ID_PIANO = p_id_piano
       AND PR_ACQ.ID_VER_PIANO = p_id_ver_piano
       AND PR_ACQ.FLG_ANNULLATO = 'N'
       AND PR_ACQ.FLG_SOSPESO = 'N'
       AND PR_ACQ.COD_DISATTIVAZIONE IS NULL
       AND (p_data_inizio is null or (p_data_inizio <= PR_ACQ.DATA_FINE))
       AND (p_data_fine is null or (p_data_fine >= PR_ACQ.DATA_INIZIO))) LOOP

        --FOR i IN 1..v_id_prodotto_acquistato.COUNT LOOP

  --          v_lista_comunicati_soggetto = FU_COMUNICATI_SOGGETTO(p_id_prodotto_acquistato(i)
  --                                 null,null,null,null,null,null,null);
            IF (p_data_inizio is null) THEN
                v_data_temp := PA.DATA_INIZIO;
                v_data_inizio := PA.DATA_INIZIO;
            ELSE
                v_data_temp := p_data_inizio;
                v_data_inizio := p_data_inizio;
            END IF;
            IF (p_data_fine is null) THEN
                v_data_fine := PA.DATA_FINE;
            ELSE
                v_data_fine := p_data_fine;
            END IF;

--                dbms_output.put_line('datainizio = '||v_data_inizio);
--                dbms_output.put_line('datafine = '||v_data_fine);
            WHILE v_data_temp BETWEEN v_data_inizio AND v_data_fine LOOP
--                dbms_output.put_line('PROD = '||PA.ID_PRODOTTO_ACQUISTATO);
--                dbms_output.put_line('DATA = '||v_data_temp);
                SELECT COUNT(DISTINCT(SC.ID_SCHERMO)) INTO v_count_schermi_tot
                    FROM CD_COMUNICATO COM, CD_BREAK_VENDITA BRV, CD_CIRCUITO_BREAK CIR,
                         CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SC
                    WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                    AND COM.DATA_EROGAZIONE_PREV = v_data_temp
                    AND COM.FLG_ANNULLATO = 'N'
                    AND COM.FLG_SOSPESO = 'N'
                    AND COM.COD_DISATTIVAZIONE IS NULL
                    AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
                    AND CIR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                    AND BR.ID_BREAK = CIR.ID_BREAK
                    AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
                    AND SC.ID_SCHERMO = PR.ID_SCHERMO;

--                dbms_output.put_line('sch_tot='|| v_count_schermi_tot);
                v_tot_percentuali := 0;
                FOR i IN 1..p_lista_percentuali.COUNT LOOP
                    v_tot_percentuali := v_tot_percentuali + p_lista_percentuali(i);
                END LOOP;
                v_temp_schermi_perc := 0;
                IF (v_tot_percentuali = 100) THEN
                    FOR i IN 1..p_lista_percentuali.COUNT LOOP
                        IF(i < p_lista_percentuali.COUNT) THEN
                            v_count_schermi_perc := v_count_schermi_tot*p_lista_percentuali(i)/100;
                            v_array_schermi_perc.extend;
                            v_array_schermi_perc(i) := v_count_schermi_perc;
                            v_temp_schermi_perc := v_temp_schermi_perc + v_count_schermi_perc;
--                            dbms_output.put_line('sch_perc='||  v_array_schermi_perc(i));
                        ELSE
                            v_array_schermi_perc.extend;
                            v_array_schermi_perc(i) := v_count_schermi_tot - v_temp_schermi_perc;
                            v_temp_schermi_perc := v_count_schermi_tot;
 --                           dbms_output.put_line('sch_perc='||  v_array_schermi_perc(i));
                        END IF;
                    END LOOP;
                ELSE
                    FOR i IN 1..p_lista_percentuali.COUNT LOOP
                        v_count_schermi_perc := v_count_schermi_tot*p_lista_percentuali(i)/100;
                        v_array_schermi_perc.extend;
                        v_array_schermi_perc(i) := v_count_schermi_perc;
                        v_temp_schermi_perc := v_temp_schermi_perc + v_count_schermi_perc;
                    END LOOP;
                END IF;

                --perc

                FOR sc IN (SELECT ID_SCHERMO, ROWNUM as v_num_riga
                            FROM (SELECT DISTINCT SCH.ID_SCHERMO
                                    FROM CD_COMUNICATO COM, CD_BREAK_VENDITA BRV, CD_CIRCUITO_BREAK CIR,
                                        CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SCH
                                    WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                                    AND COM.DATA_EROGAZIONE_PREV = v_data_temp
                                    AND COM.FLG_ANNULLATO = 'N'
                                    AND COM.FLG_SOSPESO = 'N'
                                    AND COM.COD_DISATTIVAZIONE IS NULL
                                    AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
                                    AND CIR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                                    AND BR.ID_BREAK = CIR.ID_BREAK
                                    AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
                                    AND SCH.ID_SCHERMO = PR.ID_SCHERMO)
                                    ORDER BY v_num_riga) LOOP

                    v_count := 1;
                    FOR i IN 1..v_array_schermi_perc.COUNT LOOP
                        IF (sc.v_num_riga BETWEEN v_count AND v_array_schermi_perc(i)+v_count) THEN
                            v_id_sogg_piano := p_lista_id_soggetti(i);
                        END IF;
                        IF (sc.v_num_riga > v_temp_schermi_perc) THEN
                            v_id_sogg_piano := p_id_sogg_non_def;
                        END IF;
                        v_count := v_count + v_array_schermi_perc(i);
                    END LOOP;

--                    dbms_output.put_line('RIGA='|| sc.v_num_riga);
--                    dbms_output.put_line('SOGG='||  v_id_sogg_piano);
--                    dbms_output.put_line('SCH ='||   sc.ID_SCHERMO);
                    IF (v_id_sogg_piano is not null) THEN
                        UPDATE CD_COMUNICATO SET ID_SOGGETTO_DI_PIANO = v_id_sogg_piano,
                        ID_MATERIALE_DI_PIANO = null
                        WHERE ID_COMUNICATO IN
                            (SELECT COM.ID_COMUNICATO
                                FROM CD_COMUNICATO COM, CD_BREAK_VENDITA BRV, CD_CIRCUITO_BREAK CIR,
                                     CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SCH
                                WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                                AND COM.DATA_EROGAZIONE_PREV = v_data_temp
                                AND COM.FLG_ANNULLATO = 'N'
                                AND COM.FLG_SOSPESO = 'N'
                                AND COM.COD_DISATTIVAZIONE IS NULL
                                AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
                                AND CIR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                                AND BR.ID_BREAK = CIR.ID_BREAK
                                AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
                                AND SCH.ID_SCHERMO = PR.ID_SCHERMO
                                and SCH.id_schermo = sc.id_schermo);
                    END IF;

                END LOOP;

                v_data_temp := v_data_temp + 1;

            END LOOP;
            PA_CD_ORDINE.PR_MODIFICA_SOGGETTO_ORDINE(PA.ID_PRODOTTO_ACQUISTATO, p_esito);
            PR_AGGIORNA_SINTESI_PRODOTTO(PA.ID_PRODOTTO_ACQUISTATO);

        END LOOP;

    FOR i IN 1..p_lista_id_soggetti.COUNT LOOP
        UPDATE CD_SOGGETTO_DI_PIANO SET PERC_DISTRIBUZIONE = p_lista_percentuali(i)
            WHERE ID_SOGGETTO_DI_PIANO = p_lista_id_soggetti(i);
        --
        PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(p_id_piano, p_id_ver_piano, null, p_lista_id_soggetti(i), null);
    END LOOP;

EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIAZIONE_PERC_SOGGETTI: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI ');
        ROLLBACK TO pa_cd_prodotto_soggetto;

END;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_MATERIALE_PRODOTTO
--
-- DESCRIZIONE:  Associa un materiale ad un prodotto acquistato
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto acquistato
--  p_id_materiale                      Id del materiale
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Dicembre 2009
--
--  MODIFICHE:
--  11/06/2010 Michele borgogno. Aggiunta chiamata a verifica_tutela.
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_MATERIALE_PRODOTTO(p_id_prodotto_acquistato         CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_id_materiale_piano             CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE,
                                        p_esito                          OUT NUMBER)
IS

v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;

BEGIN -- PR_ASSOCIA_MATERIALE_PRODOTTO

        p_esito     := 1;

        SAVEPOINT pa_cd_prodotto_materiale;

        SELECT ID_PIANO, ID_VER_PIANO INTO v_id_piano, v_id_ver_piano
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

        -- effettuo l'UPDATE
        UPDATE CD_COMUNICATO SET ID_MATERIALE_DI_PIANO = p_id_materiale_piano
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;

        PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(v_id_piano, v_id_ver_piano, null, null, p_id_materiale_piano);

EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIA_MATERIALE_PRODOTTO: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI ');
        ROLLBACK TO pa_cd_prodotto_materiale;

END;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIA_MATERIALE_COM
--
-- DESCRIZIONE:  Associa un materiale ad un comunicato
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_comunicato                    Id del comunicato
--  p_id_materiale_piano               Id del materiale di piano
--
-- OUTPUT: esito:
--    n  numero di record modificati con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Michele Borgogno , Altran, Dicembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_MATERIALE_COM(p_id_comunicato           CD_COMUNICATO.ID_COMUNICATO%TYPE,
                                   p_id_materiale_piano             CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE,
                                   p_esito                    OUT NUMBER)
IS

BEGIN -- PR_ASSOCIA_MATERIALE_COM

        p_esito     := 1;

        SAVEPOINT pa_cd_comunicato_materiale;

        -- effettuo l'UPDATE
        UPDATE CD_COMUNICATO SET ID_MATERIALE_DI_PIANO = p_id_materiale_piano
        WHERE ID_COMUNICATO = p_id_comunicato
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL;
EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIA_MATERIALE_COM: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI MSG='||SQLERRM);
        ROLLBACK TO pa_cd_comunicato_materiale;

END;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ASSOCIAZIONE_PERC_MATERIALI
--
-- DESCRIZIONE:  Associa i materiali di piano a tutti i comunicati in base alle percentuali definite.
--               L'associazione in percentuale viene effettuata su ogni prodotto acquistato per ogni giorno del periodo,
--               se e gia associato un soggetto al quale il materiale appartiene
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano                    Id del piano
--  p_id_ver_piano
--  p_lista_id_soggetti           Lista soggetti di piano
--  p_lista_id_materiali          Lista materiali di piano
--  p_lista_percentuali           Lista percentuali
--
-- OUTPUT: esito:
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--  11/06/2010 Michele borgogno. Aggiunta chiamata a verifica_tutela.
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIAZIONE_PERC_MATERIALI(p_id_piano  CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                         p_id_ver_piano  CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                         p_lista_id_soggetti     id_list_type,
                                         p_lista_id_materiali    id_list_type,
                                         p_lista_percentuali     id_list_type,
                                         p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                         p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                         p_esito                 OUT NUMBER)
IS

v_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_data_temp CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_id_sogg_piano CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE;
v_lista_comunicati_soggetto PA_CD_COMUNICATO.C_LISTA_COMUNICATI_SOGGETTO;
v_count_schermi_tot NUMBER;
v_count_schermi_perc NUMBER;
v_tot_schermi_perc NUMBER;
v_id_min NUMBER;
v_id_max NUMBER;
v_array_schermi_perc id_list_type := id_list_type();
v_count NUMBER;

--v_id_sogg_piano CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_mat_piano CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE;
v_array_materiali id_list_type := id_list_type();
v_array_percentuali id_list_type := id_list_type();
v_percentuale NUMBER;
v_tot_percentuali NUMBER;
v_temp_schermi_perc NUMBER;
v_count_mat_sogg NUMBER;
v_index NUMBER;
BEGIN

    p_esito     := 1;
    SAVEPOINT pa_cd_prodotto_soggetto;

    FOR PA IN (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO, PR_ACQ.DATA_INIZIO, PR_ACQ.DATA_FINE
       FROM CD_PRODOTTO_ACQUISTATO PR_ACQ
       WHERE PR_ACQ.ID_PIANO = p_id_piano
       AND PR_ACQ.ID_VER_PIANO = p_id_ver_piano
       AND PR_ACQ.FLG_ANNULLATO = 'N'
       AND PR_ACQ.FLG_SOSPESO = 'N'
       AND PR_ACQ.COD_DISATTIVAZIONE IS NULL
       AND (p_data_inizio is null or (p_data_inizio <= PR_ACQ.DATA_FINE))
       AND (p_data_fine is null or (p_data_fine >= PR_ACQ.DATA_INIZIO))) LOOP

       IF (p_data_inizio is null) THEN
           v_data_temp := PA.DATA_INIZIO;
           v_data_inizio := PA.DATA_INIZIO;
       ELSE
           v_data_temp := p_data_inizio;
           v_data_inizio := p_data_inizio;
       END IF;
       IF (p_data_fine is null) THEN
           v_data_fine := PA.DATA_FINE;
       ELSE
           v_data_fine := p_data_fine;
       END IF;

       WHILE v_data_temp BETWEEN v_data_inizio AND v_data_fine LOOP
--                dbms_output.put_line('PROD = '||PA.ID_PRODOTTO_ACQUISTATO);
--                dbms_output.put_line('DATA = '||v_data_temp);

            -- Per ogni soggetto di piano creo un array di materiali del soggetto e uno
            -- di rispettive percentuali.
            FOR i IN 1..p_lista_id_soggetti.COUNT LOOP
                v_id_sogg_piano := p_lista_id_soggetti(i);
--                dbms_output.put_line('SOGG = '||v_id_sogg_piano);

                SELECT COUNT(DISTINCT(SC.ID_SCHERMO)) INTO v_count_schermi_tot
                    FROM CD_COMUNICATO COM, CD_BREAK_VENDITA BRV, CD_CIRCUITO_BREAK CIR,
                         CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SC
                    WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                    AND COM.DATA_EROGAZIONE_PREV = v_data_temp
                    AND COM.ID_SOGGETTO_DI_PIANO = v_id_sogg_piano
                    AND COM.FLG_ANNULLATO = 'N'
                    AND COM.FLG_SOSPESO = 'N'
                    AND COM.COD_DISATTIVAZIONE IS NULL
                    AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
                    AND CIR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                    AND BR.ID_BREAK = CIR.ID_BREAK
                    AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
                    AND SC.ID_SCHERMO = PR.ID_SCHERMO;


--              dbms_output.put_line('sch_tot='|| v_count_schermi_tot);
                IF (v_count_schermi_tot > 0) THEN
                    v_temp_schermi_perc := 0;
                    v_index := 1;
                    v_array_materiali := id_list_type();
                    v_array_percentuali := id_list_type();
                    v_array_schermi_perc := id_list_type();
                    v_tot_percentuali := 0;
                    FOR i IN 1..p_lista_percentuali.COUNT LOOP
                        v_id_mat_piano := p_lista_id_materiali(i);
                        v_percentuale := p_lista_percentuali(i);
                        -- Se il materiale appartiene al soggetto lo aggiungo all'array
                        SELECT COUNT(1) INTO v_count_mat_sogg FROM CD_SOGGETTO_DI_PIANO SOGG_PIA, SOGGETTI SOGG,
                          CD_MATERIALE_SOGGETTI MAT_SOGG, CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
                          WHERE SOGG_PIA.ID_SOGGETTO_DI_PIANO = v_id_sogg_piano
                          AND MAT_PIA.ID_MATERIALE_DI_PIANO = v_id_mat_piano
                          AND SOGG.COD_SOGG = SOGG_PIA.COD_SOGG
                          AND MAT_SOGG.COD_SOGG = SOGG.COD_SOGG
                          AND MAT_SOGG.ID_MATERIALE = MAT.ID_MATERIALE
                          AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE;
--                          dbms_output.put_line('COUNT_MAT='|| v_count_mat_sogg);
                          IF (v_count_mat_sogg > 0) THEN
                            v_array_materiali.extend;
                            v_array_materiali(v_index) := v_id_mat_piano;
                            v_array_percentuali.extend;
                            v_array_percentuali(v_index) := v_percentuale;
                            v_index := v_index+1;
                            v_tot_percentuali := v_tot_percentuali + v_percentuale;
--                            dbms_output.put_line('MAT='|| v_id_mat_piano);
--                            dbms_output.put_line('PERC='|| v_percentuale);
                          END IF;
                          v_id_mat_piano := null;
                    END LOOP;
                    -- Una volta creati gli array dei materiali e delle percentuali calcolo il numero di schermi
                    -- per ogni materiale
                    IF (v_tot_percentuali = 100) THEN
                        FOR i IN 1..v_array_percentuali.COUNT LOOP
                            IF(i < v_array_percentuali.COUNT) THEN
                                v_count_schermi_perc := v_count_schermi_tot*v_array_percentuali(i)/100;
                                v_array_schermi_perc.extend;
                                v_array_schermi_perc(i) := v_count_schermi_perc;
                                v_temp_schermi_perc := v_temp_schermi_perc + v_count_schermi_perc;
--                                dbms_output.put_line('sch='|| v_temp_schermi_perc);
                            ELSE
                                v_array_schermi_perc.extend;
                                v_array_schermi_perc(i) := v_count_schermi_tot - v_temp_schermi_perc;
                                v_temp_schermi_perc := v_count_schermi_tot;
--                                dbms_output.put_line('sch100='|| v_array_schermi_perc(i));
                            END IF;
                        END LOOP;
                    ELSE
                        FOR i IN 1..v_array_percentuali.COUNT LOOP
                            v_count_schermi_perc := v_count_schermi_tot*v_array_percentuali(i)/100;
                            v_array_schermi_perc.extend;
                            v_array_schermi_perc(i) := v_count_schermi_perc;
                            v_temp_schermi_perc := v_temp_schermi_perc + v_count_schermi_perc;
--                            dbms_output.put_line('sch='|| v_temp_schermi_perc);
                        END LOOP;
                    END IF;

                    --Effettuo l'update del materiale di piano sui comunicati
                    FOR sc IN (SELECT ID_SCHERMO, ROWNUM as v_num_riga
                                FROM (SELECT DISTINCT SCH.ID_SCHERMO
                                        FROM CD_COMUNICATO COM, CD_BREAK_VENDITA BRV, CD_CIRCUITO_BREAK CIR,
                                            CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SCH
                                        WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                                        AND COM.DATA_EROGAZIONE_PREV = v_data_temp
                                        AND COM.ID_SOGGETTO_DI_PIANO = v_id_sogg_piano
                                        AND COM.FLG_ANNULLATO = 'N'
                                        AND COM.FLG_SOSPESO = 'N'
                                        AND COM.COD_DISATTIVAZIONE IS NULL
                                        AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
                                        AND CIR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                                        AND BR.ID_BREAK = CIR.ID_BREAK
                                        AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
                                        AND SCH.ID_SCHERMO = PR.ID_SCHERMO)
                                        ORDER BY v_num_riga) LOOP
                      v_count := 1;
                      FOR i IN 1..v_array_schermi_perc.COUNT LOOP
--                          dbms_output.put_line('SCHERMI!!!='|| v_array_schermi_perc(i));
--                          dbms_output.put_line('NUMRIGA!!!='|| sc.v_num_riga);
--                          dbms_output.put_line('TOTSCH!!!='|| v_temp_schermi_perc);
                          IF (sc.v_num_riga BETWEEN v_count AND v_array_schermi_perc(i)+v_count) THEN
                              v_id_mat_piano :=  v_array_materiali(i);
                          END IF;
                          IF (sc.v_num_riga > v_temp_schermi_perc) THEN
                              v_id_mat_piano := null;
                          END IF;
                          v_count := v_count + v_array_schermi_perc(i);
                      END LOOP;
--                      dbms_output.put_line('RIGA='|| sc.v_num_riga);
--                      dbms_output.put_line('MAT='||  v_id_mat_piano);
--                      dbms_output.put_line('SCH ='||   sc.ID_SCHERMO);
                      UPDATE CD_COMUNICATO SET ID_MATERIALE_DI_PIANO = v_id_mat_piano WHERE ID_COMUNICATO IN
                          (SELECT COM.ID_COMUNICATO
                              FROM CD_COMUNICATO COM, CD_BREAK_VENDITA BRV, CD_CIRCUITO_BREAK CIR,
                                   CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SCH
                              WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                              AND COM.DATA_EROGAZIONE_PREV = v_data_temp
                              AND COM.ID_SOGGETTO_DI_PIANO = v_id_sogg_piano
                              AND COM.FLG_ANNULLATO = 'N'
                              AND COM.FLG_SOSPESO = 'N'
                              AND COM.COD_DISATTIVAZIONE IS NULL
                              AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
                              AND CIR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                              AND BR.ID_BREAK = CIR.ID_BREAK
                              AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
                              AND SCH.ID_SCHERMO = PR.ID_SCHERMO
                              and SCH.id_schermo = sc.id_schermo);
                    END LOOP;
                    --Aggiorno le percentuali dei materiali di piano
                    FOR i IN 1..v_array_materiali.COUNT LOOP
                        UPDATE CD_MATERIALE_DI_PIANO SET PERC_DISTRIBUZIONE = v_array_percentuali(i)
                            WHERE ID_MATERIALE_DI_PIANO = v_array_materiali(i);
                        --
                        PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(p_id_piano, p_id_ver_piano, null, null, v_array_materiali(i));
                    END LOOP;

                END IF;
            END LOOP;
            v_data_temp := v_data_temp + 1;
        END LOOP;
    END LOOP;

EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato

        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_ASSOCIAZIONE_PERC_MATERIALI: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI ');
        ROLLBACK TO pa_cd_prodotto_soggetto;

END;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE FU_CHECK_DURATA_PROD_MAT
--
-- DESCRIZIONE:  Controlla che la durata del prodotto sia compatibile con la durata
--               del materiale da associare
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto
--  p_id_materiale_piano               Id del materiale di piano
--
-- OUTPUT:
--    n  numero di record. Se e 0 la durata del materiale non e compatibile con il prodotto
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------

FUNCTION FU_CHECK_DURATA_PROD_MAT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                  p_id_materiale_di_piano CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE) RETURN NUMBER IS
v_num_prod NUMBER;
BEGIN

    SELECT COUNT(DISTINCT NVL(PROD.ID_PRODOTTO_ACQUISTATO, 0)) INTO v_num_prod FROM CD_PRODOTTO_ACQUISTATO PROD, CD_MATERIALE_DI_PIANO MAT_PIA,
           CD_FORMATO_ACQUISTABILE FOR_ACQ, CD_COEFF_CINEMA COE, CD_MATERIALE MAT
           WHERE PROD.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
           AND PROD.FLG_ANNULLATO = 'N'
           AND PROD.FLG_SOSPESO = 'N'
           AND PROD.COD_DISATTIVAZIONE IS NULL
           AND FOR_ACQ.ID_FORMATO = PROD.ID_FORMATO
           AND COE.ID_COEFF = FOR_ACQ.ID_COEFF
           AND MAT_PIA.ID_MATERIALE_DI_PIANO = p_id_materiale_di_piano
           AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE
           AND MAT.DURATA = COE.DURATA;

    RETURN v_num_prod;

EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_CHECK_DURATA_PROD_MAT: ERRORE '||SQLERRM);
        ROLLBACK TO pa_cd_prodotto_intermediari;
END FU_CHECK_DURATA_PROD_MAT;


-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_NUM_SCHERMI
--
-- DESCRIZIONE:  Restituisce il numero di schermi che sono stati acquistati in un prodotto
--
-- OPERAZIONI: Controlla tutti gli schermi associati ai comunicati di un prodotto acquistato,
--             e restituisce il numero di schermi totale
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto
--
-- OUTPUT: Numero di schermi del prodotto acquistato
--
--
-- REALIZZATORE: Simone Bottani, Altran, Ottobre 2009
--
--  MODIFICHE:  Mauro Viel, Altran, Febbraio 2011 inserita la chimata alla funzione 
--              FU_GET_NUM_SCHERMI_TARGET 
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER IS
v_num_schermi   NUMBER;
v_id_target     CD_PRODOTTO_VENDITA.ID_TARGET%TYPE;
v_segui_il_film CD_PRODOTTo_VENDITA.FLG_SEGUI_IL_FILM%TYPE;

BEGIN

    SELECT PV.ID_TARGET, PV.FLG_SEGUI_IL_FILM
    INTO v_id_target, v_segui_il_film
    FROM CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
    AND PV.FLG_ANNULLATO = 'N';

    IF v_segui_il_film = 'S' THEN
        v_num_schermi := FU_GET_NUM_SCHERMI_SEGUI_FILM(p_id_prodotto_acquistato, 'N');
    ELSE    
        IF v_id_target IS NULL THEN
            SELECT COUNT(DISTINCT(SC.ID_SCHERMO))
            INTO v_num_schermi
            FROM  CD_SALA S, CD_SCHERMO SC, CD_PROIEZIONE PR, CD_BREAK BRK, CD_CIRCUITO_BREAK C_BRK, CD_BREAK_VENDITA BRK_V, CD_COMUNICATO COM
            WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND COM.FLG_ANNULLATO = 'N'
            AND COM.FLG_SOSPESO = 'N'
            AND COM.COD_DISATTIVAZIONE IS NULL
            AND BRK_V.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
            AND BRK_V.FLG_ANNULLATO = 'N'
            AND C_BRK.ID_CIRCUITO_BREAK = BRK_V.ID_CIRCUITO_BREAK
            AND C_BRK.FLG_ANNULLATO = 'N'
            AND BRK.ID_BREAK = C_BRK.ID_BREAK
            AND BRK.FLG_ANNULLATO='N'
            AND PR.ID_PROIEZIONE = BRK.ID_PROIEZIONE
            AND PR.FLG_ANNULLATO='N'
            AND SC.ID_SCHERMO = PR.ID_SCHERMO
            AND SC.FLG_ANNULLATO = 'N'
            AND S.ID_SALA = SC.ID_SALA
            AND S.FLG_ANNULLATO = 'N'
            AND S.FLG_VISIBILE = 'S';
        ELSE
            v_num_schermi := FU_GET_NUM_SCHERMI_TARGET(p_id_prodotto_acquistato, v_id_target, 'N');
        END IF;
    END IF;    

    --
    RETURN v_num_schermi;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_NUM_SCHERMI: ERRORE '||SQLERRM);
        ROLLBACK TO pa_cd_prodotto_intermediari;
END FU_GET_NUM_SCHERMI;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_NUM_AMBIENTI
--
-- DESCRIZIONE:  Restituisce il numero di ambienti che sono stati acquistati in un prodotto
--
-- OPERAZIONI:
--             1) Verifica in quale ambiente viene venduto il prodotto
--             2)Controlla tutti gli ambienti associati ai comunicati di un prodotto acquistato,
--             e restituisce il numero di ambienti totale
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto
--
-- OUTPUT: Numero di ambienti del prodotto acquistato
--
--
-- REALIZZATORE: Simone Bottani, Altran, Aprile 2010
--
--  MODIFICHE: Mauro Viel, Altran, Febbraio 2011 inserita la chiamata alla funzione  
--                         FU_GET_NUM_SCHERMI_SEGUI_FILM                     
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_AMBIENTI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER IS
v_num_ambienti NUMBER;
v_luogo CD_LUOGO.ID_LUOGO%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE;
v_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE;
v_segui_il_film CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE;
BEGIN
   BEGIN
   SELECT CD_LUOGO.ID_LUOGO, CD_PRODOTTO_VENDITA.ID_TARGET,CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM
   INTO v_luogo, v_id_target,v_segui_il_film
     FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB, CD_PRODOTTO_VENDITA, CD_PRODOTTO_PUBB, CD_PRODOTTO_ACQUISTATO
     WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
     AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
     AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
     AND CD_PRODOTTO_PUBB.COD_TIPO_PUBB = CD_LUOGO_TIPO_PUBB.COD_TIPO_PUBB
     AND CD_LUOGO.ID_LUOGO = CD_LUOGO_TIPO_PUBB.ID_LUOGO;
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
       v_luogo := 6;
   END;
    --
    IF v_luogo = 1 THEN
      IF v_segui_il_film = 'N' THEN
            IF v_id_target IS NULL THEN
                SELECT COUNT(DISTINCT(SC.ID_SCHERMO))
                INTO v_num_ambienti
                FROM  CD_SALA S, CD_SCHERMO SC, CD_PROIEZIONE PR, CD_BREAK BRK, CD_CIRCUITO_BREAK C_BRK, CD_BREAK_VENDITA BRK_V, CD_COMUNICATO COM
                WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND COM.FLG_ANNULLATO = 'N'
                AND COM.FLG_SOSPESO = 'N'
                AND COM.COD_DISATTIVAZIONE IS NULL
                AND BRK_V.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
                AND BRK_V.FLG_ANNULLATO = 'N'
                AND C_BRK.ID_CIRCUITO_BREAK = BRK_V.ID_CIRCUITO_BREAK
                AND C_BRK.FLG_ANNULLATO = 'N'
                AND BRK.ID_BREAK = C_BRK.ID_BREAK
                AND BRK.FLG_ANNULLATO='N'
                AND PR.ID_PROIEZIONE = BRK.ID_PROIEZIONE
                AND PR.FLG_ANNULLATO='N'
                AND SC.ID_SCHERMO = PR.ID_SCHERMO
                AND SC.FLG_ANNULLATO = 'N'
                AND S.ID_SALA = SC.ID_SALA
                AND S.FLG_ANNULLATO = 'N'
                AND S.FLG_VISIBILE = 'S';
            ELSE
                v_num_ambienti := FU_GET_NUM_SCHERMI_TARGET(p_id_prodotto_acquistato, v_id_target, 'N');
            END IF;
      ELSE
            v_num_ambienti := FU_GET_NUM_SCHERMI_SEGUI_FILM(p_id_prodotto_acquistato, 'N');      
      END IF; 
    ELSIF v_luogo = 2 THEN
         SELECT COUNT(DISTINCT(S.ID_SALA))
        INTO v_num_ambienti
        FROM  CD_SALA S, CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO P_ACQ,CD_SALA_VENDITA SV, CD_CIRCUITO_SALA CS
        WHERE P_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND P_ACQ.FLG_ANNULLATO = 'N'
        AND P_ACQ.FLG_SOSPESO = 'N'
        AND P_ACQ.COD_DISATTIVAZIONE IS NULL
        AND COM.ID_PRODOTTO_ACQUISTATO = P_ACQ.ID_PRODOTTO_ACQUISTATO
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SV.ID_SALA_VENDITA = COM.ID_SALA_VENDITA
        AND SV.FLG_ANNULLATO = 'N'
        AND CS.ID_CIRCUITO_SALA = SV.ID_CIRCUITO_SALA
        AND CS.FLG_ANNULLATO = 'N'
        AND S.ID_SALA = CS.ID_SALA
        AND S.FLG_ANNULLATO='N'
        AND s.FLG_VISIBILE = 'S';
    ELSIF v_luogo = 3 THEN
         SELECT COUNT(DISTINCT(A.ID_ATRIO))
        INTO v_num_ambienti
        FROM  CD_ATRIO A, CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO P_ACQ,CD_ATRIO_VENDITA AV, CD_CIRCUITO_ATRIO CA
        WHERE P_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND P_ACQ.FLG_ANNULLATO = 'N'
        AND P_ACQ.FLG_SOSPESO = 'N'
        AND P_ACQ.COD_DISATTIVAZIONE IS NULL
        AND COM.ID_PRODOTTO_ACQUISTATO = P_ACQ.ID_PRODOTTO_ACQUISTATO
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND AV.ID_ATRIO_VENDITA = COM.ID_ATRIO_VENDITA
        AND AV.FLG_ANNULLATO = 'N'
        AND CA.ID_CIRCUITO_ATRIO = AV.ID_CIRCUITO_ATRIO
        AND CA.FLG_ANNULLATO = 'N'
        AND A.ID_ATRIO = CA.ID_ATRIO
        AND A.FLG_ANNULLATO='N';
    ELSIF v_luogo = 4 THEN
         SELECT COUNT(DISTINCT(C.ID_CINEMA))
        INTO v_num_ambienti
        FROM  CD_CINEMA C, CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO P_ACQ,CD_CINEMA_VENDITA SV, CD_CIRCUITO_CINEMA CS
        WHERE P_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND P_ACQ.FLG_ANNULLATO = 'N'
        AND P_ACQ.FLG_SOSPESO = 'N'
        AND P_ACQ.COD_DISATTIVAZIONE IS NULL
        AND COM.ID_PRODOTTO_ACQUISTATO = P_ACQ.ID_PRODOTTO_ACQUISTATO
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SV.ID_CINEMA_VENDITA = COM.ID_CINEMA_VENDITA
        AND SV.FLG_ANNULLATO = 'N'
        AND CS.ID_CIRCUITO_CINEMA = SV.ID_CIRCUITO_CINEMA
        AND CS.FLG_ANNULLATO = 'N'
        AND C.ID_CINEMA = CS.ID_CINEMA
        AND C.FLG_ANNULLATO='N';
    ELSIF v_luogo = 6 THEN
        v_num_ambienti := 1;
    END IF;
    RETURN v_num_ambienti;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_NUM_AMBIENTI: ERRORE '||SQLERRM);
        ROLLBACK TO pa_cd_prodotto_intermediari;
END FU_GET_NUM_AMBIENTI;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_NUM_COMUNICATI
--
-- DESCRIZIONE:  Restituisce il numero di comunicati in un prodotto
--
-- OPERAZIONI: Effettua una count dei comunicati presenti sul prodotto acquistato
--
--  INPUT:
--  p_id_prodotto_acquistato           Id del prodotto
--
-- OUTPUT: Numero di comunicati del prodotto acquistato
--
--
-- REALIZZATORE: Simone Bottani, Altran, Ottobre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_COMUNICATI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER IS
v_num_comunicati NUMBER;
BEGIN
SELECT COUNT(ID_COMUNICATO)
INTO v_num_comunicati
FROM  CD_COMUNICATO COM,CD_PRODOTTO_ACQUISTATO P_ACQ
WHERE P_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
AND COM.ID_PRODOTTO_ACQUISTATO = P_ACQ.ID_PRODOTTO_ACQUISTATO
AND COM.FLG_ANNULLATO = 'N'
AND COM.FLG_SOSPESO = 'N'
AND COM.COD_DISATTIVAZIONE IS NULL;
RETURN v_num_comunicati;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20026, 'FUNZIONE FU_GET_NUM_COMUNICATI: ERRORE '||SQLERRM);
        ROLLBACK TO pa_cd_prodotto_intermediari;

END FU_GET_NUM_COMUNICATI;

/*******************************************************************************
 VERIFICA MESSA IN ONDA PIANO
 Author:  Michele Borgogno , Altran, Gennaio 2010

 Per mezzo di questa funzione si puo verificare la prossimita di messa in onda dei
 prodotti di un piano.
 Restituisce S nel caso incui i comunicati di un prodotto acquistato del piano sono prossimi alla messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION FU_VER_MESSA_IN_ONDA_PIANO(p_id_piano cd_prodotto_acquistato.id_piano%type,
                                    p_id_ver_piano cd_prodotto_acquistato.id_ver_piano%type) RETURN char IS

v_id_prodotto_acquistato cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE;
v_esito char:= 'X';

BEGIN

    FOR PA IN (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO
        FROM CD_PRODOTTO_ACQUISTATO PR_ACQ
        WHERE PR_ACQ.ID_PIANO = p_id_piano
        AND PR_ACQ.ID_VER_PIANO = p_id_ver_piano
        AND PR_ACQ.FLG_ANNULLATO = 'N'
        AND PR_ACQ.FLG_SOSPESO = 'N'
        AND PR_ACQ.COD_DISATTIVAZIONE is null
        AND PR_ACQ.STATO_DI_VENDITA = 'PRE') LOOP

        IF PA.ID_PRODOTTO_ACQUISTATO IS NOT NULL THEN
            v_esito := FU_VERIFICA_MESSA_IN_ONDA(PA.ID_PRODOTTO_ACQUISTATO);
        ELSE
            v_esito := 'X';
        END IF;
        IF (v_esito = 'S') THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN v_esito;

EXCEPTION
    WHEN  no_data_found  THEN
        RETURN 'X';
 --       RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VER_MESSA_IN_ONDA_PIANO:. Errore: ' || SQLERRM);
END FU_VER_MESSA_IN_ONDA_PIANO;

/*******************************************************************************
 VERIFICA DOPO MESSA IN ONDA PIANO
 Author:  Michele Borgogno , Altran, Gennaio 2010

 Per mezzo di questa funzione si puo verificare il periodo di post messa in onda dei
 prodotti di un piano.
 Restituisce S nel caso incui i comunicati sono compresi nel periodo
 post messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION FU_VER_DOPO_ONDA_PIANO(p_id_piano cd_prodotto_acquistato.id_piano%type,
                                p_id_ver_piano cd_prodotto_acquistato.id_ver_piano%type) RETURN char IS

v_id_prodotto_acquistato cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE;
v_esito CHAR;

BEGIN

    FOR PA IN (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO
        FROM CD_PRODOTTO_ACQUISTATO PR_ACQ
        WHERE PR_ACQ.ID_PIANO = p_id_piano
        AND PR_ACQ.ID_VER_PIANO = p_id_ver_piano
        AND PR_ACQ.FLG_ANNULLATO = 'N'
        AND PR_ACQ.FLG_SOSPESO = 'N'
        AND PR_ACQ.COD_DISATTIVAZIONE is null
        AND PR_ACQ.STATO_DI_VENDITA = 'PRE') LOOP

        IF PA.ID_PRODOTTO_ACQUISTATO IS NOT NULL THEN
            v_esito := FU_VERIFICA_DOPO_MESSA_IN_ONDA(PA.ID_PRODOTTO_ACQUISTATO);
        ELSE
            v_esito := 'X';
        END IF;

        IF (v_esito = 'S') THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN v_esito;

EXCEPTION
    WHEN  no_data_found  THEN
        RETURN 'X';
 --       RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VER_DOPO_ONDA_PIANO:. Errore: ' || SQLERRM);
END FU_VER_DOPO_ONDA_PIANO;

/*******************************************************************************
 VERIFICA MESSA IN ONDA
 Author:  Michele Borgogno , Altran, Ottobre 2009

 Per mezzo di questa funzione si puo verificare la messa in onda di un
 particolare prodotto acquistato.
 Restituisce S nel caso incui i comunicati del prodotto acquistato sono prossimi alla messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION  FU_VERIFICA_MESSA_IN_ONDA(p_id_prodotto_acquistato IN cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN char IS

v_data_erogazione_prev cd_comunicato.data_erogazione_prev%TYPE;

BEGIN

SELECT min(com.data_erogazione_prev) as data_erogazione_prev
INTO v_data_erogazione_prev
FROM cd_comunicato com ,cd_prodotto_acquistato prd
WHERE com.id_prodotto_acquistato = prd.id_prodotto_acquistato
and   prd.id_prodotto_acquistato = p_id_prodotto_acquistato
and   prd.COD_DISATTIVAZIONE is null
and   prd.FLG_ANNULLATO = 'N'
and   prd.FLG_SOSPESO   = 'N'
and   prd.STATO_DI_VENDITA = 'PRE'
and   com.COD_DISATTIVAZIONE is null
and   com.FLG_ANNULLATO = 'N'
and   com.FLG_SOSPESO   = 'N';

IF v_data_erogazione_prev IS NOT NULL THEN
    RETURN PA_CD_COMUNICATO.FU_VERIFICA_MESSA_IN_ONDA(v_data_erogazione_prev);
ELSE
    RETURN 'X';
END IF;

EXCEPTION
    WHEN  no_data_found  THEN
        RETURN 'X';
 --       RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
END FU_VERIFICA_MESSA_IN_ONDA;

/*******************************************************************************
 VERIFICA DOPO MESSA IN ONDA
 Author:  Michele Borgogno , Altran, Gennaio 2010

 Per mezzo di questa funzione si puo verificare la dopo messa in onda di un
 particolare prodotto acquistato.
 Restituisce S nel caso incui i comunicati del prodotto acquistato sono compresi nel periodo
 di dopo messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION  FU_VERIFICA_DOPO_MESSA_IN_ONDA(p_id_prodotto_acquistato IN cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN char IS

v_id_comunicato cd_comunicato.ID_COMUNICATO%TYPE;
v_data_erogazione_prev  cd_comunicato.DATA_EROGAZIONE_PREV%TYPE;

BEGIN

SELECT com.id_comunicato, com.data_erogazione_prev
INTO v_id_comunicato, v_data_erogazione_prev
FROM cd_comunicato com ,cd_prodotto_acquistato prd
WHERE com.id_prodotto_acquistato = prd.id_prodotto_acquistato
and   prd.id_prodotto_acquistato = p_id_prodotto_acquistato
and   prd.COD_DISATTIVAZIONE is null
and   prd.FLG_ANNULLATO = 'N'
and   prd.FLG_SOSPESO   = 'N'
and   prd.STATO_DI_VENDITA = 'PRE'
AND rownum < 2
ORDER BY com.DATA_EROGAZIONE_PREV DESC;

IF v_id_comunicato IS NOT NULL THEN
    RETURN PA_CD_COMUNICATO.FU_VERIFICA_DOPO_MESSA_IN_ONDA(v_id_comunicato);
ELSE
    RETURN 'X';
END IF;

EXCEPTION
    WHEN  no_data_found  THEN
        RETURN 'X';
 --       RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_DOPO_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
END FU_VERIFICA_DOPO_MESSA_IN_ONDA;

/*******************************************************************************
 VERIFICA FATTURAZIONE
 Author:  Michele Borgogno , Altran, Ottobre 2009

 Per mezzo di questa funzione si puo verificare la messa in onda di un
 particolare prodotto acquistato.
 Restituisce S nel caso incui i comunicati del prodotto acquistato sono prossimi alla messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION  FU_VERIFICA_FATTURAZIONE(p_id_prodotto_acquistato IN cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN char IS

v_count NUMBER;

BEGIN

select count(1) into v_count from cd_prodotto_acquistato prd,
    cd_importi_fatturazione fat, cd_importi_prodotto imp
    where prd.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    and prd.FLG_ANNULLATO = 'N'
    and prd.FLG_SOSPESO = 'N'
    and prd.COD_DISATTIVAZIONE is null
    and imp.ID_PRODOTTO_ACQUISTATO = prd.ID_PRODOTTO_ACQUISTATO
    and fat.ID_IMPORTI_PRODOTTO = imp.ID_IMPORTI_PRODOTTO
    and (fat.STATO_FATTURAZIONE = 'TRA' or fat.STATO_FATTURAZIONE = 'DAR')
    AND FAT.FLG_ANNULLATO = 'N';

IF v_count > 0 THEN
    RETURN 'S';
ELSE
    RETURN 'N';
END IF;

EXCEPTION
    WHEN  no_data_found  THEN
        RETURN 'X';
 --       RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_FATTURAZIONE:. Errore: ' || SQLERRM);
END FU_VERIFICA_FATTURAZIONE;

/*******************************************************************************
 VERIFICA PRESENZA ORDINI
 Author:  Michele Borgogno , Altran, febbraio 2010

 Verifica che il prodotto sia incluso in un ordine

*******************************************************************************/

FUNCTION  FU_VER_INCLUSIONE_IN_ORDINE(p_id_prodotto_acquistato IN cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN char IS

v_count NUMBER;

BEGIN

select count(1) into v_count from cd_prodotto_acquistato prd,
    cd_importi_fatturazione fat, cd_importi_prodotto imp
    where prd.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    and prd.FLG_ANNULLATO = 'N'
    and prd.FLG_SOSPESO = 'N'
    and prd.COD_DISATTIVAZIONE is null
    and imp.ID_PRODOTTO_ACQUISTATO = prd.ID_PRODOTTO_ACQUISTATO
    and fat.ID_IMPORTI_PRODOTTO = imp.ID_IMPORTI_PRODOTTO
    AND FAT.FLG_ANNULLATO = 'N';
--    and (fat.STATO_FATTURAZIONE = 'TRA' or fat.STATO_FATTURAZIONE = 'DAR');

IF v_count > 0 THEN
    RETURN 'S';
ELSE
    RETURN 'N';
END IF;

EXCEPTION
    WHEN  no_data_found  THEN
        RETURN 'X';
 --       RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_INCLUSIONE_IN_ORDINE:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VER_INCLUSIONE_IN_ORDINE:. Errore: ' || SQLERRM);
END FU_VER_INCLUSIONE_IN_ORDINE;


-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_RICALCOLA_TARIFFA
-- DESCRIZIONE:  Effettua il ricalcolo a seguito di una specifica variazione dell'importo di una tariffa
--
-- OPERAZIONI: Chiama la procedura per il ricalcolo della tariffa per tutti i prodotti
--             che sono stati acquistati per la tariffa richiesta
--
-- INPUT:
--      p_id_tariffa        id della tariffa oggetto della modifica
--      p_vecchio_importo   importo precedente alla variazione riguardante la tariffa in esame
--      p_nuovo_importo     nuovo importo dopo la variazione
--
-- OUTPUT:
--      p_piani_errati      lista con gli id di tutti i piani che non e stato possibile correggere
--
--  REALIZZATORE: Francesco Abbundo, Teoresi srl, Ottobre 2009
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA( p_id_tariffa        CD_TARIFFA.ID_TARIFFA%TYPE,
                                p_vecchio_importo   CD_TARIFFA.IMPORTO%TYPE,
                                p_nuovo_importo     CD_TARIFFA.IMPORTO%TYPE,
                                p_piani_errati OUT VARCHAR2)
IS

    v_esito NUMBER := 0;
BEGIN
    SAVEPOINT SP_PR_RICALCOLA_TARIFFA;
    FOR PA IN (SELECT PACQ.* FROM CD_PRODOTTO_ACQUISTATO PACQ, CD_PRODOTTO_VENDITA PV, CD_TARIFFA TAR
               WHERE TAR.ID_TARIFFA = p_id_tariffa
               AND PV.ID_PRODOTTO_VENDITA = TAR.ID_PRODOTTO_VENDITA
               AND PACQ.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
               AND PACQ.FLG_ANNULLATO = 'N'
               AND PACQ.FLG_ANNULLATO = 'N'
               AND PACQ.COD_DISATTIVAZIONE IS NULL
               AND (PACQ.ID_TIPO_CINEMA IS NULL OR PACQ.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
               AND PACQ.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE) LOOP

    IF p_vecchio_importo <> p_nuovo_importo THEN
        PR_RICALCOLA_TARIFFA_PROD_ACQ(PA.ID_PRODOTTO_ACQUISTATO,p_vecchio_importo,p_nuovo_importo,'N',p_piani_errati);
    END IF;
   END LOOP;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURE PR_RICALCOLA_TARIFFA: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO SP_PR_RICALCOLA_TARIFFA;
END PR_RICALCOLA_TARIFFA;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_RICALCOLA_TARIFFA_PROD_ACQ
-- DESCRIZIONE:  Effettua il ricalcolo della tariffa di un prodotto acquistato
--
-- OPERAZIONI:
--            1) Se il flag vale N il nuovo importo viene ricalcolato verificando lo
--               sconto stagionale e l'eventuale riparametrizzazione
--            2) Dato il numero di schermi viene calcolato l'importo totale
--            3) Nel caso in cui il prodotto abbia la tariffa variabile vengono modificati tutti gli importi
--            4) Nel caso in cui la tariffa non sia variabile si cerca di mantenere il netto
--               diminuendo lo sconto. Nel caso in cui non sia possibile c'e una situazione di errore
--               viene aggiunto in output l'id del piano, in modo da poterlo correggere manualmente
--
--            5) Vengono modificati gli importi di fatturazione relativi al prodotto acquistato
-- INPUT:
--      p_id_prodotto_acquistato        id del prodotto acquistato
--      p_vecchio_importo               importo precedente alla variazione riguardante la tariffa in esame
--      p_nuovo_importo                 nuovo importo dopo la variazione
--      p_flg_variazione_schermi Flag che indica se l'operazione e un cambio nel numero di schermi
--      (schermo annullato o ripristinato) o una variazione di tariffa. Nel primo caso il parametro
--      vale S, altrimenti N
--
--
-- OUTPUT:
--      p_piani_errati      lista con gli id di tutti i piani che non e stato possibile correggere
--
--  REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE: Mauro Viel, Altran, Luglio 2011, inserito aggiornamento del numero ambienti sul prodotto acquistato.
--             Mauro Viel Altran, Ottobre 2011, sostituita la chiamata di FU_PERC_SC_COMM  con FU_PERC_SC_COMM_ESATTA 
--             al fine di avere il numero massimo di decimali #MV01
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_vecchio_importo   CD_TARIFFA.IMPORTO%TYPE,
                                        p_nuovo_importo     CD_TARIFFA.IMPORTO%TYPE,
                                        p_flg_variazione_ambienti VARCHAR2,
                                        p_piani_errati OUT VARCHAR2
                                        )
IS
    v_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_netto CD_PRODOTTO_aCQUISTATO.IMP_NETTO%TYPE;
    v_maggiorazione CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
    v_recupero CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
    v_sanatoria CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
    v_lordo_comm CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_lordo_dir CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_netto_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_netto_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_perc_sc_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_perc_sc_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_imp_sc_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_imp_sc_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
    v_vecchio_importo CD_TARIFFA.IMPORTO%TYPE;
    v_sconto_stag CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
    v_aliquota CD_COEFF_CINEMA.ALIQUOTA%TYPE;
    v_nuovo_importo CD_TARIFFA.IMPORTO%TYPE;
    v_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE;
    v_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
    v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
    v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
    v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
    v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;
    v_esito NUMBER := 0;
    v_num_ambienti NUMBER;
    v_id_misura_temp CD_PRODOTTO_ACQUISTATO.ID_MISURA_PRD_VE%TYPE;
    v_flg_tar_var CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE;
    v_netto_comm_vecchio CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_netto_dir_vecchio CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
    v_id_importo_prodotto_c CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
    v_id_importo_prodotto_d CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
BEGIN
    SAVEPOINT PR_RICALCOLA_TARIFFA_PROD_ACQ;
    v_nuovo_importo := p_nuovo_importo;

    SELECT ID_PRODOTTO_VENDITA, ID_FORMATO, FLG_TARIFFA_VARIABILE, ID_PIANO, ID_VER_PIANO, DATA_INIZIO, DATA_FINE, ID_MISURA_PRD_VE, IMP_TARIFFA
    INTO v_id_prodotto_vendita, v_id_formato, v_flg_tar_var, v_id_piano, v_id_ver_piano, v_data_inizio, v_data_fine,v_id_misura_temp, v_vecchio_importo
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

    IF p_flg_variazione_ambienti  = 'N' THEN

        v_sconto_stag := pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(v_id_prodotto_vendita, v_data_inizio, v_data_fine,v_id_formato,v_id_misura_temp);
        v_aliquota := PA_CD_TARIFFA.FU_GET_ALIQUOTA(v_id_formato);
        v_nuovo_importo := ROUND(v_nuovo_importo * v_aliquota,2);
        v_nuovo_importo := PA_CD_UTILITY.FU_CALCOLA_IMPORTO(v_nuovo_importo,v_sconto_stag);

    END IF;

    --dbms_output.put_line(' v_nuovo_importo='|| v_nuovo_importo);

    v_num_ambienti := FU_GET_NUM_AMBIENTI(p_id_prodotto_acquistato);
    v_nuovo_importo := ROUND(v_nuovo_importo * v_num_ambienti,2);

     --dbms_output.put_line(' v_num_schermi='|| v_num_schermi);
     --dbms_output.put_line(' v_nuovo_importo dopo='|| v_nuovo_importo);
     --dbms_output.put_line(' vecchio importo='|| v_vecchio_importo);
    SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO
    INTO v_lordo, v_netto, v_maggiorazione, v_sanatoria, v_recupero
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'C';

    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
    INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'D';

    v_netto_comm_vecchio := v_netto_comm;
    v_netto_dir_vecchio := v_netto_dir;
    v_lordo_comm := v_netto_comm + v_imp_sc_comm;
    v_lordo_dir := v_netto_dir + v_imp_sc_dir;
    
    --#MV01 inizio
    --v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm, v_imp_sc_comm);
    --v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir, v_imp_sc_dir);
    v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(v_netto_comm, v_imp_sc_comm);
    v_perc_sc_dir  := PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(v_netto_dir,  v_imp_sc_dir);
    --#MV01 fine

    /*dbms_output.put_line(' v_netto_comm='|| v_netto_comm);
    dbms_output.put_line(' v_netto_dir='|| v_netto_dir);
    dbms_output.put_line(' v_lordo='|| v_lordo);
    dbms_output.put_line(' v_lordo_comm='|| v_lordo_comm);
    dbms_output.put_line(' v_lordo_dir='|| v_lordo_dir);
    dbms_output.PUT_LINE('flg tariffa variabile: '||v_flg_tar_var);
    */
    IF v_nuovo_importo != v_vecchio_importo THEN
        IF v_maggiorazione > 0 THEN
            v_maggiorazione := 0;
            FOR MAG IN (SELECT M.PERCENTUALE_VARIAZIONE
                        FROM CD_MAGG_PRODOTTO MP, CD_MAGGIORAZIONE M
                        WHERE MP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                        AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE) LOOP
                v_maggiorazione := v_maggiorazione + PA_CD_TARIFFA.FU_CALCOLA_MAGGIORAZIONE(v_nuovo_importo,MAG.PERCENTUALE_VARIAZIONE);
            END LOOP;
        --dbms_output.put_line('maggiorazione rilevata: nuovo valore di maggiorazione='|| v_maggiorazione);
        END IF;
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_vecchio_importo,v_maggiorazione,
        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
        v_imp_sc_dir,v_sanatoria,v_recupero,v_nuovo_importo,'0',v_esito);
        if v_flg_tar_var = 'N' then
            BEGIN
    --
                /*dbms_output.put_line('Sono in tariffa variabile');
                dbms_output.put_line(' v_netto_comm='|| v_netto_comm);
                dbms_output.put_line(' v_netto_dir='|| v_netto_dir);
                dbms_output.put_line(' v_netto_comm_vecchio='|| v_netto_comm_vecchio);
                dbms_output.put_line(' v_netto_dir_vecchio='|| v_netto_dir_vecchio);
                */
                IF v_netto_comm != v_netto_comm_vecchio THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_vecchio_importo,v_maggiorazione,
                    v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                    v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                    v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_comm_vecchio,'31',v_esito);
                END IF;
                IF v_netto_dir != v_netto_dir_vecchio THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_nuovo_importo,v_maggiorazione,
                    v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                    v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                    v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_dir_vecchio,'32',v_esito);
                END IF;
            EXCEPTION
            WHEN OTHERS THEN
                --dbms_output.put_line('Eccezione nella modifica di un prodotto con flg = N');
                --dbms_output.put_line(' vecchio importo='||p_vecchio_importo);
                --dbms_output.put_line(' nuovo importo='|| v_nuovo_importo);
                PA_CD_IMPORTI.MODIFICA_IMPORTI(v_nuovo_importo,v_maggiorazione,
                v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                v_imp_sc_dir,v_sanatoria,v_recupero,p_vecchio_importo,'0',v_esito);
                p_piani_errati := p_piani_errati || v_id_piano||'/'||v_id_ver_piano||', ';
            END;
        end if;

        v_netto:= v_netto_comm + v_netto_dir;
        --dbms_output.put_line(' v_nuova_maggiorazione='|| v_maggiorazione);
        UPDATE CD_PRODOTTO_ACQUISTATO
        SET IMP_TARIFFA = v_nuovo_importo,
            IMP_LORDO = v_lordo,
            IMP_NETTO = v_netto,
            IMP_MAGGIORAZIONE = v_maggiorazione,
            IMP_SANATORIA = v_sanatoria,
            IMP_RECUPERO = v_recupero,
            NUMERO_AMBIENTI = v_num_ambienti
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

       /* UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_comm,
            IMP_SC_COMM = v_imp_sc_comm
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND TIPO_CONTRATTO = 'C';

        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_dir,
            IMP_SC_COMM = v_imp_sc_dir
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND TIPO_CONTRATTO = 'D';*/

        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_comm,
        IMP_SC_COMM = v_imp_sc_comm
        WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_c;

        PR_RICALCOLA_IMP_FAT(v_id_importo_prodotto_c,v_netto_comm_vecchio,v_netto_comm);
    --
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_netto_dir,
        IMP_SC_COMM = v_imp_sc_dir
        WHERE ID_IMPORTI_PRODOTTO = v_id_importo_prodotto_d;

        PR_RICALCOLA_IMP_FAT(v_id_importo_prodotto_d,v_netto_dir_vecchio,v_netto_dir);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20026, 'PR_RICALCOLA_TARIFFA_PROD_ACQ: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_RICALCOLA_TARIFFA_PROD_ACQ;
END PR_RICALCOLA_TARIFFA_PROD_ACQ;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_ANNULLA_SCHERMO_PROD_ACQ
-- DESCRIZIONE:  Effettua l'annullamento di uno schermo per un prodotto acquistato,
--               ricalcolando la sua tariffa decurtando la parte di importo relativa
--               allo schermo eliminato
--
-- INPUT:
--      p_id_prodotto_acquistato        id del prodotto acquistato
--      p_id_schermo                    id dello schermo eliminato
--
-- OUTPUT:
--      p_esito
--             1: eliminazione avvenuta correttamente
--            -1: errore durante l'eliminazione
--      p_piani_errati      lista con gli id di tutti i piani che non e stato possibile correggere
--
--  REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:  : Mauro Viel Altran Italia Ottobre 2011 : Sostituita la chaimata alla proceura PA_PC_IMPORTI.FU_PERC_SC_COMM con PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA
--                                        in modo da ottenere il numero massimo di decimali per scongiurare problemi di arrotondamento.  #MV01

-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_SCHERMO_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                      p_id_schermo CD_SCHERMO.ID_SCHERMO%TYPE,
                                      p_esito OUT NUMBER,
                                      p_piani_errati OUT VARCHAR2) IS
v_num_schermi NUMBER;
v_vecchia_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_tariffa_tmp CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_flg_variazione_schermi VARCHAR2(1);
v_perc_sc_comm NUMBER;
v_perc_sc_dir NUMBER;
BEGIN
    SAVEPOINT PR_ANNULLA_SCHERMO_PROD_ACQ;
    p_esito := 1;
    v_flg_variazione_schermi := 'S';
    v_num_schermi := FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato);

    SELECT IMP_TARIFFA
    INTO v_vecchia_tariffa
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    v_nuova_tariffa   := ROUND((v_vecchia_tariffa / (v_num_schermi + 1)),2);
    --v_nuova_tariffa := ROUND(((v_tariffa_tmp * v_num_schermi) / (v_num_schermi+1)),2);

    --Salvo la percentuale di sconto originaria per eventuali recuperi
    --SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO,IMP_SC_COMM) #MV01
    SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(IMP_NETTO,IMP_SC_COMM)-- #MV01
    INTO v_perc_sc_comm
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'C';
    --
    --SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO,IMP_SC_COMM) #MV01
    SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(IMP_NETTO,IMP_SC_COMM) --#MV01
    INTO v_perc_sc_dir
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'D';
    --
    UPDATE CD_IMPORTI_PRODOTTO
    SET PERC_SC_ORIG = v_perc_sc_comm
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'C';
    --
    UPDATE CD_IMPORTI_PRODOTTO
    SET PERC_SC_ORIG = v_perc_sc_dir
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND TIPO_CONTRATTO = 'D';
    --
    PR_RICALCOLA_TARIFFA_PROD_ACQ(p_id_prodotto_acquistato, v_vecchia_tariffa, v_nuova_tariffa,v_flg_variazione_schermi,p_piani_errati);
EXCEPTION
    WHEN OTHERS THEN
    p_esito := -1;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURE PR_RICALCOLA_TARIFFA: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO SP_PR_RICALCOLA_TARIFFA;
END;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_RIPRISTINA_SCHERMO_PROD_ACQ
-- DESCRIZIONE:  Effettua il ripristino di uno schermo per un prodotto acquistato,
--               ricalcolando la sua tariffa incrementando la parte di importo relativa
--               allo schermo aggiunto
--
-- INPUT:
--      p_id_prodotto_acquistato        id del prodotto acquistato
--      p_id_schermo                    id dello schermo aggiunto
--
-- OUTPUT:
--      p_esito
--             1: eliminazione avvenuta correttamente
--            -1: errore durante l'eliminazione
--      p_piani_errati      lista con gli id di tutti i piani che non e stato possibile correggere
--
--  REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RIPRISTINA_SCHERMO_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                      p_id_schermo CD_SCHERMO.ID_SCHERMO%TYPE,
                                      p_esito OUT NUMBER,
                                      p_piani_errati OUT VARCHAR2) IS
v_num_schermi NUMBER;
v_vecchia_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_tariffa_tmp CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_flg_variazione_schermi VARCHAR2(1);
BEGIN
    SAVEPOINT PR_ANNULLA_SCHERMO_PROD_ACQ;
    p_esito := 1;
    v_flg_variazione_schermi := 'S';
    v_num_schermi := FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato);

    SELECT IMP_TARIFFA
    INTO v_vecchia_tariffa
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

    v_vecchia_tariffa   := ROUND((v_vecchia_tariffa / (v_num_schermi - 1)),2);
    --v_nuova_tariffa := ROUND(((v_tariffa_tmp * v_num_schermi) / (v_num_schermi+1)),2);
    PR_RICALCOLA_TARIFFA_PROD_ACQ(p_id_prodotto_acquistato, v_vecchia_tariffa, v_vecchia_tariffa,v_flg_variazione_schermi,p_piani_errati);

EXCEPTION
    WHEN OTHERS THEN
    p_esito := -1;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURE PR_RICALCOLA_TARIFFA: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO SP_PR_RICALCOLA_TARIFFA;
END PR_RIPRISTINA_SCHERMO_PROD_ACQ;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE FU_GET_SOGG_PROD_ACQ
-- DESCRIZIONE:  Restituisce il soggetto di un piano, se ad un piano sono associati
--               piu soggetti viene restituito *
--
-- INPUT:
--      p_id_piano        id del piano
--      p_id_ver_piano    versione del piano
--
-- OUTPUT:
--  REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SOGG_PROD_ACQ(
                              p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                              p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE) RETURN VARCHAR2 IS
--
v_soggetto CD_SOGGETTO_DI_PIANO.DESCRIZIONE%TYPE := '*';
v_num_sogg NUMBER;
BEGIN
       SELECT COUNT(ID_SOGGETTO_DI_PIANO)
       INTO v_num_sogg
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano;
--
IF v_num_sogg = 1 THEN
        v_soggetto := 'SOGGETTO NON DEFINITO';
ELSIF v_num_sogg = 2 THEN
       SELECT DESCRIZIONE
        INTO v_soggetto
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano
        AND DESCRIZIONE <> 'SOGGETTO NON DEFINITO';
END IF;
RETURN v_soggetto;
EXCEPTION
     WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Funzione FU_GET_SOGG_PROD_ACQ:. Errore: ' || SQLERRM);
END FU_GET_SOGG_PROD_ACQ;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_IMPOSTA_POSIZIONE
-- DESCRIZIONE:  Effettua l'impostazione della posizione dei comunicati di un prodotto acquistato
--               viene utilizzata quando il prodotto passa in stato Prenotato
--
-- OPERAZIONI:
--            1) Verifica se i comunicati del prodotto acquistato hanno una posizione di rigore
--            2) Se il prodotto ha impostata la posizione di rigore i suoi comunicati vengono impostati
--               in quella posizione. Es. posizione di rigore = 90, tutti i comunicati avranno posizione 90.
--               Vengono cercati tutti i comunicati che concorrono agli stessi break dei comunicati del prodotto
--               selezionato, e quelli con posizione uguale o minore vengono spostati nella prima posizione
--               inferiore disponibile
--            3) Se non e impostata una posizione di rigore i comunicati vengono inseriti nell'ultima posizione
--               disponibile nel break
-- INPUT:
--      p_id_prodotto_acquistato        id del prodotto acquistato
--
-- OUTPUT:
--
--  REALIZZATORE: Simone Bottani, Altran, Dicembre 2009
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_IMPOSTA_POSIZIONE(
                                p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE) IS
v_pos CD_COMUNICATO.POSIZIONE%TYPE;
v_pos_vuota CD_COMUNICATO.POSIZIONE%TYPE;
v_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_num_pos_rigore NUMBER;
v_pos_rig_temp CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_trovato BOOLEAN;
BEGIN
   SAVEPOINT PR_IMPOSTA_POSIZIONE;
--
   SELECT DISTINCT NVL(POSIZIONE_DI_RIGORE,0)
   INTO v_pos_rigore
   FROM CD_COMUNICATO
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

    --dbms_output.put_line('v_pos_rigore:'||v_pos_rigore);
--
   FOR COM IN(SELECT COM.ID_COMUNICATO, COM.ID_BREAK_VENDITA, COM.POSIZIONE, BR.ID_BREAK
            FROM
            CD_BREAK BR,
            CD_CIRCUITO_BREAK CBR,
            CD_BREAK_VENDITA BRV,
            CD_COMUNICATO COM
            WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND (p_id_comunicato IS NULL OR COM.ID_COMUNICATO = p_id_comunicato)
            AND COM.FLG_ANNULLATO = 'N'
            AND COM.FLG_SOSPESO = 'N'
            AND COM.COD_DISATTIVAZIONE IS NULL
            AND COM.DATA_EROGAZIONE_PREV >= TRUNC(SYSDATE)
            AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
            AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
            AND BR.ID_BREAK = CBR.ID_BREAK
            )LOOP
--
             --dbms_output.PUT_LINE('Id comunicato nuovo: '||COM.ID_COMUNICATO);
             --dbms_output.PUT_LINE('Id break: '||COM.ID_BREAK);
       IF v_pos_rigore <> 0 THEN
           FOR COM_BREAK IN (SELECT COM2.ID_COMUNICATO, COM2.POSIZIONE, BR.ID_BREAK
           FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
          -- WHERE COM2.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
           WHERE COM2.FLG_ANNULLATO = 'N'
           AND COM2.FLG_SOSPESO = 'N'
           AND COM2.COD_DISATTIVAZIONE IS NULL
           AND COM2.POSIZIONE <= v_pos_rigore
           AND COM2.POSIZIONE <> 1 AND COM2.POSIZIONE <> 2
           AND COM2.POSIZIONE_DI_RIGORE IS NULL
           AND PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
           AND PA.FLG_ANNULLATO = 'N'
           AND PA.FLG_SOSPESO = 'N'
           AND PA.COD_DISATTIVAZIONE IS NULL
           AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
           AND PA.STATO_DI_VENDITA = 'PRE'
           AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
           AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
           AND BR.ID_BREAK = CBR.ID_BREAK
           AND BR.ID_BREAK = COM.ID_BREAK
           ORDER BY COM2.POSIZIONE DESC)LOOP
                --dbms_output.put_line('ID_COMUNICATO:'||COM_BREAK.ID_COMUNICATO);
                --dbms_output.put_line('ID_BREAK:'||COM_BREAK.ID_BREAK);
                --dbms_output.put_line('Posizione nel break:'||COM_BREAK.POSIZIONE);
                v_trovato := FALSE;
                v_pos := v_pos_rigore;
                FOR POS IN (SELECT ID_COMUNICATO, POSIZIONE, POSIZIONE_DI_RIGORE
                --INTO v_pos
                            FROM CD_COMUNICATO C, CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA
                            --WHERE C.ID_BREAK_VENDITA = COM_BREAK.ID_BREAK_VENDITA
                            WHERE C.ID_COMUNICATO <> COM_BREAK.ID_COMUNICATO
                            AND C.FLG_ANNULLATO = 'N'
                            AND C.FLG_SOSPESO = 'N'
                            AND C.COD_DISATTIVAZIONE IS NULL
                            AND C.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                            --AND C.POSIZIONE_DI_RIGORE IS NULL
                            AND C.POSIZIONE < COM_BREAK.POSIZIONE
                            AND PA.STATO_DI_VENDITA = 'PRE'
                            AND PA.FLG_ANNULLATO = 'N'
                            AND PA.FLG_SOSPESO = 'N'
                            AND PA.COD_DISATTIVAZIONE IS NULL
                            AND BRV.ID_BREAK_VENDITA = C.ID_BREAK_VENDITA
                            AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                            AND BR.ID_BREAK = CBR.ID_BREAK
                            AND BR.ID_BREAK = COM_BREAK.ID_BREAK
                            ORDER BY C.POSIZIONE DESC)LOOP
                v_pos := POS.POSIZIONE;
                IF POS.POSIZIONE_DI_RIGORE IS NULL THEN
                    v_trovato := TRUE;
                    EXIT;
                END IF;

                END LOOP;
                IF v_trovato = FALSE THEN
                    --v_pos := v_pos -1;
                    v_pos := COM_BREAK.POSIZIONE -1;
                END IF;
                --dbms_output.put_line('Nuova Posizione:'||v_pos);
                UPDATE
                CD_COMUNICATO
                SET POSIZIONE = v_pos
                WHERE ID_COMUNICATO = COM_BREAK.ID_COMUNICATO;
                --AND POSIZIONE != v_pos;
           END LOOP;

           UPDATE CD_COMUNICATO
           SET POSIZIONE = v_pos_rigore
           WHERE CD_COMUNICATO.ID_COMUNICATO = COM.ID_COMUNICATO;
           --AND POSIZIONE != v_pos_rigore;
       ELSE
           v_pos_vuota := 91;
           v_pos := 90;
           FOR POS_RIG IN (SELECT POSIZIONE,POSIZIONE_DI_RIGORE
           FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
           WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
           AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
           --AND COM2.POSIZIONE_DI_RIGORE IS NOT NULL
           AND COM2.POSIZIONE >= 85
           AND COM2.FLG_ANNULLATO = 'N'
           AND COM2.FLG_SOSPESO = 'N'
           AND COM2.COD_DISATTIVAZIONE IS NULL
           AND PA.STATO_DI_VENDITA = 'PRE'
           AND PA.FLG_ANNULLATO = 'N'
           AND PA.FLG_SOSPESO = 'N'
           AND PA.COD_DISATTIVAZIONE IS NULL
           AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
           AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
           AND BR.ID_BREAK = CBR.ID_BREAK
           AND BR.ID_BREAK = COM.ID_BREAK
           ORDER BY POSIZIONE DESC) LOOP
                IF POS_RIG.POSIZIONE != v_pos THEN
                    --EXIT;
                    SELECT COUNT(1)
                    INTO v_num_pos_rigore
                    FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
                   WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
                   AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
                   AND COM2.POSIZIONE_DI_RIGORE IS NOT NULL
                   AND COM2.POSIZIONE <= POS_RIG.POSIZIONE
                   AND COM2.POSIZIONE > 2
                   AND COM2.FLG_ANNULLATO = 'N'
                   AND COM2.FLG_SOSPESO = 'N'
                   AND COM2.COD_DISATTIVAZIONE IS NULL
                   AND PA.STATO_DI_VENDITA = 'PRE'
                   AND PA.FLG_ANNULLATO = 'N'
                   AND PA.FLG_SOSPESO = 'N'
                   AND PA.COD_DISATTIVAZIONE IS NULL
                   AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
                   AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                   AND BR.ID_BREAK = CBR.ID_BREAK
                   AND BR.ID_BREAK = COM.ID_BREAK;
                   --
                   --dbms_output.PUT_LINE('Num pos rigore: '||v_num_pos_rigore);
                   --dbms_output.PUT_LINE('Posizione: '||POS_RIG.POSIZIONE);
                   IF v_num_pos_rigore > 0 THEN
                        v_pos_vuota := v_pos;
                        EXIT;
                   END IF;
                   --
                END IF;
                v_pos := POS_RIG.POSIZIONE -1;
           END LOOP;
           --dbms_output.PUT_LINE('Posizione vuota:'||v_pos_vuota);
           IF v_pos_vuota != 91 THEN
                v_pos := v_pos_vuota;
                --dbms_output.PUT_LINE('Rilevato buco; v_pos:'||v_pos);
           ELSE
               SELECT NVL(MIN(POSIZIONE),91)
               INTO v_pos
               FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
               WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
               AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
               AND COM2.POSIZIONE <> 1 AND COM2.POSIZIONE <> 2
               AND COM2.FLG_ANNULLATO = 'N'
               AND COM2.FLG_SOSPESO = 'N'
               AND COM2.COD_DISATTIVAZIONE IS NULL
               AND PA.STATO_DI_VENDITA = 'PRE'
               AND PA.FLG_ANNULLATO = 'N'
               AND PA.FLG_SOSPESO = 'N'
               AND PA.COD_DISATTIVAZIONE IS NULL
               AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
               AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
               AND BR.ID_BREAK = CBR.ID_BREAK
               AND BR.ID_BREAK = COM.ID_BREAK;
            --
               v_pos := v_pos - 1;
            --
            --dbms_output.PUT_LINE('Non e stato rilevato buco; v_pos:'||v_pos);
           END IF;
           --dbms_output.PUT_LINE('Posizione del comunicato:'||v_pos);
           UPDATE CD_COMUNICATO
           SET POSIZIONE = v_pos
           WHERE CD_COMUNICATO.ID_COMUNICATO = COM.ID_COMUNICATO;
           --AND POSIZIONE != v_pos;
        --
         END IF;
   END LOOP;
   EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_IMPOSTA_POSIZIONE: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_IMPOSTA_POSIZIONE;
END PR_IMPOSTA_POSIZIONE;

  /*******************************************************************************
   ELENCO SCHERMI DEL PRODOTTO ACQUISTATO
  Author:  Michele Borgogno, Altran, Novembre 2009

   Elenco di schermi appartenenti ad un prodotto acquistato
*******************************************************************************/
    FUNCTION  FU_ELENCO_SCHERMI(p_id_prodotto_acquistato IN CD_COMUNICATO.id_prodotto_acquistato%TYPE,
                                p_id_regione IN CD_REGIONE.ID_REGIONE%TYPE,
                                p_id_provincia IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
                                p_id_comune IN CD_COMUNE.ID_COMUNE%TYPE,
                                p_id_cinema IN CD_CINEMA.id_cinema%TYPE,
                                p_id_sala IN CD_SALA.ID_SALA%TYPE) RETURN C_LISTA_SCHERMI IS
    v_lista_schermi C_LISTA_SCHERMI;
    BEGIN
--
        OPEN v_lista_schermi FOR
        select min(ID_COMUNICATO) ||'_'||max(id_comunicato) as id_comunicato, ID_CINEMA, NOME_CINEMA, COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA, NOME_AMBIENTE,-- DATA_EROGAZIONE,
        luogo,  FLG_ANNULLATO
        from
          (select
                c.id_comunicato as ID_COMUNICATO,
                cin.id_cinema as ID_CINEMA,
                cin.nome_cinema as NOME_CINEMA,
                comune.comune as COMUNE_CINEMA,
                provincia.provincia as PROVINCIA_CINEMA,
                regione.nome_regione as REGIONE_CINEMA,
      --          (select comune.comune from cd_comune comune
      --                  where comune.id_comune = cin.id_comune) as COMUNE_CINEMA,
      --          (select regione.nome_regione from cd_regione regione, cd_provincia provincia, cd_comune comune
       --                 where comune.id_comune = cin.id_comune
       --                 and provincia.id_provincia = comune.id_provincia
       --                 and regione.id_regione = provincia.id_regione) as REGIONE_CINEMA,
                sa.nome_sala as NOME_AMBIENTE,
                --c.data_erogazione_prev as DATA_EROGAZIONE,
                'TA' as luogo,
                c.FLG_ANNULLATO as FLG_ANNULLATO
                from CD_PRODOTTO_ACQUISTATO pa,
                    cd_comunicato c,
                    cd_circuito_break cir_br,
                    cd_cinema cin,
                    cd_sala sa,
                    cd_break_vendita brv,
                    cd_break br,
                    cd_proiezione pr,
                    cd_schermo  sch,
                    cd_comune comune,
                    cd_provincia provincia,
                    cd_regione regione
                where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
                  and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  AND (p_id_cinema IS NULL OR cin.id_cinema = p_id_cinema)
                  AND (p_id_comune IS NULL OR comune.id_comune = p_id_comune)
                  AND (p_id_provincia IS NULL OR provincia.id_provincia = p_id_provincia)
                  AND (p_id_regione IS NULL OR regione.id_regione = p_id_regione)
                  AND (p_id_sala IS NULL OR sa.id_sala = p_id_sala)
                  and pa.flg_annullato = 'N'
                  and pa.flg_sospeso = 'N'
                  and pa.cod_disattivazione is null
                  and c.flg_annullato = 'N'
                  and c.flg_sospeso = 'N'
                  and c.cod_disattivazione is null
                  and c.id_break_vendita = brv.id_break_vendita
                  and brv.id_circuito_break = cir_br.id_circuito_break
                  and br.id_break = cir_br.id_break
                  and pr.id_proiezione = br.id_proiezione
                  and sch.id_schermo = pr.id_schermo
                  and sch.ID_SALA = sa.ID_SALA
                  and sa.ID_CINEMA = cin.ID_CINEMA
                  and comune.id_comune = cin.id_comune
                  and provincia.id_provincia = comune.id_provincia
                  and regione.id_regione = provincia.id_regione)
                 group by ID_CINEMA, NOME_CINEMA, COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA,NOME_AMBIENTE,--DATA_EROGAZIONE,
                 luogo,  FLG_ANNULLATO;--group by DATA_EROGAZIONE;--, ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, ID_COMUNICATO, ID_CINEMA, NOME_CINEMA,COMUNE_CINEMA, NOME_AMBIENTE, luogo, FLG_ANNULLATO;

        RETURN v_lista_schermi;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_ELENCO_SCHERMI;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_VERIFICA_POS_RIGORE
-- DESCRIZIONE:  Verifica se una posizione di rigore puo essere assegnata
--               ad un prodotto acquistato.
--
-- INPUT:
--       p_id_prodotto_vendita: id del prodotto di vendita che si vuole vendere
--       p_pos_rigore: posizione di rigore
--       p_data_inizio: data di inizio del prodotto
--       p_data_fine: data di fine del prodotto
--
-- OUTPUT: p_esito
--
--  REALIZZATORE: Simone Bottani, Altran, Novembre 2009
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_VERIFICA_POS_RIGORE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                p_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                p_list_ambienti id_list_type) RETURN NUMBER IS
v_num_comunicati NUMBER := 0;
--v_id_tipo_break CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE;
v_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
BEGIN
    if (p_id_prodotto_vendita is null) then
    --dbms_output.put_line('Prodotto vendita nullo');
        select count(cd_break.id_break)
        into v_num_comunicati
        from cd_break_vendita, cd_break,cd_circuito_break
        where cd_break_vendita.id_break_vendita in
        (select  id_break_vendita from cd_comunicato where DATA_EROGAZIONE_PREV
        BETWEEN p_data_inizio AND p_data_fine
        AND posizione_di_rigore = p_pos_rigore
        and id_prodotto_acquistato != p_id_prodotto_acquistato
        and FLG_ANNULLATO = 'N'
        and FLG_SOSPESO = 'N'
        and cod_disattivazione is null)
        and cd_break_vendita.FLG_ANNULLATO = 'N'
        and   cd_break_vendita.ID_CIRCUITO_BREAK = cd_circuito_break.ID_CIRCUITO_BREAK
        and cd_circuito_break.FLG_ANNULLATO = 'N'
        and   cd_break.id_break = cd_circuito_break.id_break
        and cd_break.FLG_ANNULLATO = 'N'
        and cd_break.id_break in (
       select cd_break.id_break from cd_break_vendita, cd_break,cd_circuito_break
        where cd_break_vendita.id_break_vendita in
        (select  id_break_vendita from cd_comunicato
        where id_prodotto_acquistato = p_id_prodotto_acquistato and FLG_ANNULLATO = 'N'
        and flg_sospeso = 'N'
        and cod_disattivazione is null)
        and cd_break_vendita.FLG_ANNULLATO = 'N'
        and   cd_break_vendita.ID_CIRCUITO_BREAK = cd_circuito_break.ID_CIRCUITO_BREAK
        and cd_circuito_break.FLG_ANNULLATO = 'N'
        and   cd_break.id_break = cd_circuito_break.id_break
        and cd_break.FLG_ANNULLATO = 'N');
    else
    --dbms_output.put_line('Prodotto vendita non nullo: '||p_id_prodotto_vendita);
    --dbms_output.put_line('Passo 2: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
        select id_mod_vendita
        into v_mod_vendita
        from cd_prodotto_vendita
        where id_prodotto_vendita = p_id_prodotto_vendita;
        --dbms_output.put_line('Id mod vendita: '||v_mod_vendita||'Ora: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
        if v_mod_vendita = 1 then--Libera
        --dbms_output.put_line('Ramo1');
            select count(1)
            into v_num_comunicati
            from cd_schermo, cd_proiezione,
            (select cd_break.id_proiezione, cd_break.id_break from
            cd_circuito_break,cd_break_vendita,cd_break
            where cd_break_vendita.id_prodotto_vendita = p_id_prodotto_vendita
            and cd_break_vendita.DATA_EROGAZIONE BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO IN (select * from table(p_list_ambienti))
            and br.id_break in
            (
            select id_break
            from cd_schermo, cd_proiezione,
            (select cd_break.id_proiezione, cd_break.id_break
            from cd_break, cd_circuito_break,cd_break_vendita, cd_comunicato
            where cd_comunicato.posizione_di_rigore = p_pos_rigore
            and cd_comunicato.data_erogazione_prev BETWEEN p_data_inizio AND p_data_fine
            and cd_comunicato.FLG_ANNULLATO = 'N'
            and cd_comunicato.FLG_SOSPESO = 'N'
            and cd_comunicato.COD_DISATTIVAZIONE IS NULL
            and cd_break_vendita.id_break_vendita = cd_comunicato.id_break_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO IN (select * from table(p_list_ambienti))
            );
        elsif v_mod_vendita = 2 then
        --dbms_output.put_line('Ramo2');
            select count(1)
            into v_num_comunicati
            from cd_break_vendita,cd_break,cd_circuito_break
            --where cd_comunicato.posizione_di_rigore = p_pos_rigore
            where cd_break_vendita.id_prodotto_vendita = p_id_prodotto_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            and cd_break.id_break in
            (select cd_break.id_break
            from cd_comunicato, cd_break_vendita,cd_break,cd_circuito_break
            where cd_comunicato.posizione_di_rigore = p_pos_rigore
            and cd_comunicato.FLG_ANNULLATO = 'N'
            and cd_comunicato.FLG_SOSPESO = 'N'
            and cd_comunicato.COD_DISATTIVAZIONE IS NULL
            and cd_comunicato.data_erogazione_prev BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.id_break_vendita = cd_comunicato.id_break_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N');
        elsif v_mod_vendita = 3 then
            --dbms_output.put_line('Ramo3: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
            --dbms_output.put_line('Prodotto vendita: '||p_id_prodotto_vendita);
            --dbms_output.put_line('Posizione rigore: '||p_pos_rigore);
            select count(1)
            into v_num_comunicati
            from cd_sala, cd_schermo, cd_proiezione,
            (select cd_break.id_proiezione, cd_break.id_break from
            cd_circuito_break,cd_break_vendita,cd_break
            where cd_break_vendita.id_prodotto_vendita = p_id_prodotto_vendita
            and cd_break_vendita.DATA_EROGAZIONE BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_sala.ID_SALA = cd_schermo.ID_SALA
            and cd_sala.FLG_ANNULLATO = 'N'
            and cd_sala.id_sala in
           (select id_sala from cd_sala
           where flg_annullato = 'N'
           and id_cinema in
               (select id_cinema from cd_cinema
               where flg_annullato = 'N'
               and id_comune in
                   (select id_comune from cd_comune where id_provincia in
                       (select id_provincia from cd_provincia where id_regione in
                            (select id_regione from cd_regione where id_regione in
                                  (select id_regione from cd_nielsen_regione where id_area_nielsen IN (select * from table(p_list_ambienti))))))))
           and br.id_break in
           (
           select id_break
            from cd_sala, cd_schermo, cd_proiezione,
            (select cd_break.id_break
            from cd_comunicato, cd_break_vendita,cd_break,cd_circuito_break
            where cd_comunicato.posizione_di_rigore = p_pos_rigore
            and cd_comunicato.FLG_ANNULLATO = 'N'
            and cd_comunicato.FLG_SOSPESO = 'N'
            and cd_comunicato.COD_DISATTIVAZIONE IS NULL
            and cd_comunicato.data_erogazione_prev BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.id_break_vendita = cd_comunicato.id_break_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_sala.ID_SALA = cd_schermo.ID_SALA
            and cd_sala.FLG_ANNULLATO = 'N'
            and cd_sala.id_sala in
           (select id_sala from cd_sala
           where flg_annullato = 'N'
           and id_cinema in
               (select id_cinema from cd_cinema
               where flg_annullato = 'N'
               and id_comune in
                   (select id_comune from cd_comune where id_provincia in
                       (select id_provincia from cd_provincia where id_regione in
                            (select id_regione from cd_regione where id_regione in
                                  (select id_regione from cd_nielsen_regione where id_area_nielsen IN (select * from table(p_list_ambienti)))))))));
        end if;
    end if;
    --dbms_output.put_line('Numero comunicati 1: '||v_num_comunicati||'Ora: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
    IF (v_num_comunicati IS NULL) THEN
        v_num_comunicati := 0;
    END IF;
    --dbms_output.put_line('Numero comunicati 2: '||v_num_comunicati||'Ora: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
RETURN v_num_comunicati;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_VERIFICA_POS_RIGORE: Si e'' verificato un errore  '||SQLERRM);
END FU_VERIFICA_POS_RIGORE;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_PROVINCE
-- DESCRIZIONE:  la funzione si occupa di estrarre le province
--               che rispondono ai criteri di ricerca
--
-- INPUT:
--      p_id_regione        id dell'area geografica
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Michele Borgogno, Altran, Dicembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_PROVINCE(p_id_regione  CD_REGIONE.ID_REGIONE%TYPE) RETURN C_PROVINCIA
IS
   c_province_return C_PROVINCIA;
BEGIN
   OPEN c_province_return
     FOR
        SELECT  PROVINCIA.ID_PROVINCIA, PROVINCIA.PROVINCIA
        FROM    CD_PROVINCIA PROVINCIA
        WHERE   (p_id_regione IS NULL OR PROVINCIA.ID_REGIONE = p_id_regione)
        ORDER BY PROVINCIA.PROVINCIA;
RETURN c_province_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_PROVINCE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_RICERCA_PROVINCE;

 --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_COMUNI
-- DESCRIZIONE:  la funzione si occupa di estrarre i comuni
--               che rispondono ai criteri di ricerca
--
-- INPUT:
--      p_id_provincia              id della provincia
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Michele Borgogno, Altran, Dicembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_COMUNI( p_id_provincia        CD_PROVINCIA.ID_PROVINCIA%TYPE
                           )RETURN C_COMUNE
IS
   c_comune_return C_COMUNE;
BEGIN
   OPEN c_comune_return
     FOR
        SELECT  COMUNE.ID_COMUNE, COMUNE.COMUNE
        FROM    CD_COMUNE COMUNE
        WHERE   (p_id_provincia IS NULL OR COMUNE.ID_PROVINCIA = p_id_provincia)
        ORDER BY COMUNE.COMUNE;
RETURN c_comune_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_COMUNI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_RICERCA_COMUNI;

--------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SCHERMI_PROD_ACQ
-- DESCRIZIONE:  Restituisce gli schermi di un prodotto acquistato
--
-- INPUT:
--      p_id_prodotto_acquistato   id del prodotto acquistato
--
-- OUTPUT: cursore che contiene i record con gli schermi trovati
--
--
-- REALIZZATORE  Simone Bottani, Altran Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SCHERMI_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_SCHERMI_PA IS
v_sale_return C_SCHERMI_PA;
BEGIN
OPEN v_sale_return FOR
    SELECT DISTINCT(ID_SCHERMO), DESC_TIPO_CINEMA, NOME_CINEMA, COMUNE, PROVINCIA, NOME_REGIONE, NOME_SALA AS DESC_SCHERMO, PASSAGGI
   FROM
     (
     SELECT SC.ID_SCHERMO, TC.DESC_TIPO_CINEMA, CI.NOME_CINEMA, COM.COMUNE, PROV.ABBR AS PROVINCIA, REG.NOME_REGIONE, SA.NOME_SALA, COUNT(ID_BREAK) AS PASSAGGI
     FROM
      CD_COMUNE COM, CD_TIPO_CINEMA TC, CD_CINEMA CI, CD_SALA SA, CD_SCHERMO SC, CD_PROIEZIONE PR, CD_PROVINCIA PROV, CD_REGIONE REG,
     (SELECT CD_BREAK.ID_PROIEZIONE, CD_CIRCUITO.NOME_CIRCUITO, CD_BREAK.ID_BREAK
      FROM CD_BREAK, CD_CIRCUITO, CD_CIRCUITO_BREAK, CD_BREAK_VENDITA, CD_COMUNICATO
      WHERE CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
      AND CD_COMUNICATO.FLG_ANNULLATO = 'N'
      AND CD_COMUNICATO.FLG_SOSPESO = 'N'
      AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL
      AND CD_BREAK_VENDITA.ID_BREAK_VENDITA = CD_COMUNICATO.ID_BREAK_VENDITA
      AND CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
      AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
      AND CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
      AND CD_CIRCUITO.ID_CIRCUITO = CD_CIRCUITO_BREAK.ID_CIRCUITO
      AND CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK) BRK
    WHERE BRK.ID_PROIEZIONE = PR.ID_PROIEZIONE
    AND PR.FLG_ANNULLATO = 'N'
    AND SC.ID_SCHERMO = PR.ID_SCHERMO
    AND SC.FLG_ANNULLATO = 'N'
    AND SA.ID_SALA = SC.ID_SALA
    AND SA.FLG_ANNULLATO = 'N'
    AND CI.ID_CINEMA = SA.ID_CINEMA
    AND CI.FLG_ANNULLATO = 'N'
    AND CI.ID_TIPO_CINEMA = TC.ID_TIPO_CINEMA
    AND COM.ID_COMUNE = CI.ID_COMUNE
    AND PROV.ID_PROVINCIA = COM.ID_PROVINCIA
    AND REG.ID_REGIONE = PROV.ID_REGIONE
    GROUP BY
    SC.ID_SCHERMO,
    DESC_TIPO_CINEMA,
    NOME_CINEMA,
    COMUNE,
    ABBR,
    NOME_REGIONE,
    SA.NOME_SALA)
    ORDER BY NOME_CINEMA;
    RETURN v_sale_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_SCHERMI_PROD_ACQ;

--------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_ATRII_PROD_ACQ
-- DESCRIZIONE:  Restituisce gli atrii di un prodotto acquistato di tipo iniziativa speciale
--
-- INPUT:
--      p_id_prodotto_acquistato   id del prodotto acquistato
--
-- OUTPUT: cursore che contiene i record con gli atrii trovati
--
--
-- REALIZZATORE  Simone Bottani, Altran Aprile 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_ATRII_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AMBIENTI_PA IS
v_atrii_return C_AMBIENTI_PA;
BEGIN
OPEN v_atrii_return FOR
      SELECT DISTINCT(A.ID_ATRIO), A.DESC_ATRIO, CIN.NOME_CINEMA || ' - ' || COM.COMUNE AS NOME_CINEMA
        FROM  CD_COMUNE COM, CD_CINEMA CIN, CD_ATRIO A, CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO P_ACQ,CD_ATRIO_VENDITA AV, CD_CIRCUITO_ATRIO CA
        WHERE P_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND P_ACQ.FLG_ANNULLATO = 'N'
        AND P_ACQ.FLG_SOSPESO = 'N'
        AND P_ACQ.COD_DISATTIVAZIONE IS NULL
        AND COM.ID_PRODOTTO_ACQUISTATO = P_ACQ.ID_PRODOTTO_ACQUISTATO
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND AV.ID_ATRIO_VENDITA = COM.ID_ATRIO_VENDITA
        AND AV.FLG_ANNULLATO = 'N'
        AND CA.ID_CIRCUITO_ATRIO = AV.ID_CIRCUITO_ATRIO
        AND CA.FLG_ANNULLATO = 'N'
        AND A.ID_ATRIO = CA.ID_ATRIO
        AND A.FLG_ANNULLATO='N'
        AND CIN.ID_CINEMA = A.ID_CINEMA
        AND CIN.FLG_ANNULLATO = 'N'
        AND COM.ID_COMUNE = CIN.ID_COMUNE;
    RETURN v_atrii_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_ATRII_PROD_ACQ;

--------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SALE_PROD_ACQ
-- DESCRIZIONE:  Restituisce le sale di un prodotto acquistato di tipo iniziativa speciale
--
-- INPUT:
--      p_id_prodotto_acquistato   id del prodotto acquistato
--
-- OUTPUT: cursore che contiene i record con le sale trovate
--
--
-- REALIZZATORE  Simone Bottani, Altran Aprile 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_SALE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AMBIENTI_PA IS
v_sale_return C_AMBIENTI_PA;
BEGIN
OPEN v_sale_return FOR
      SELECT DISTINCT(S.ID_SALA), S.NOME_SALA, CIN.NOME_CINEMA || ' - ' || COM.COMUNE AS NOME_CINEMA
        FROM  CD_COMUNE COM, CD_CINEMA CIN, CD_SALA S, CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO P_ACQ,CD_SALA_VENDITA SV, CD_CIRCUITO_SALA CS
        WHERE P_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND P_ACQ.FLG_ANNULLATO = 'N'
        AND P_ACQ.FLG_SOSPESO = 'N'
        AND P_ACQ.COD_DISATTIVAZIONE IS NULL
        AND COM.ID_PRODOTTO_ACQUISTATO = P_ACQ.ID_PRODOTTO_ACQUISTATO
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SV.ID_SALA_VENDITA = COM.ID_SALA_VENDITA
        AND SV.FLG_ANNULLATO = 'N'
        AND CS.ID_CIRCUITO_SALA = SV.ID_CIRCUITO_SALA
        AND CS.FLG_ANNULLATO = 'N'
        AND S.ID_SALA = CS.ID_SALA
        AND S.FLG_ANNULLATO='N'
        AND CIN.ID_CINEMA = S.ID_CINEMA
        AND CIN.FLG_ANNULLATO = 'N'
        AND COM.ID_COMUNE = CIN.ID_COMUNE;
    RETURN v_sale_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_SALE_PROD_ACQ;

--------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CINEMA_PROD_ACQ
-- DESCRIZIONE:  Restituisce i cinema di un prodotto acquistato di tipo iniziativa speciale
--
-- INPUT:
--      p_id_prodotto_acquistato   id del prodotto acquistato
--
-- OUTPUT: cursore che contiene i record con i cinema trovati
--
--
-- REALIZZATORE  Simone Bottani, Altran Aprile 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CINEMA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AMBIENTI_PA IS
v_sale_return C_AMBIENTI_PA;
BEGIN
OPEN v_sale_return FOR
      SELECT DISTINCT(CIN.ID_CINEMA), NULL,CIN.NOME_CINEMA || ' - ' || COM.COMUNE AS NOME_CINEMA
        FROM  CD_COMUNE COM, CD_CINEMA CIN, CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO P_ACQ,CD_CINEMA_VENDITA SV, CD_CIRCUITO_CINEMA CS
        WHERE P_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND P_ACQ.FLG_ANNULLATO = 'N'
        AND P_ACQ.FLG_SOSPESO = 'N'
        AND P_ACQ.COD_DISATTIVAZIONE IS NULL
        AND COM.ID_PRODOTTO_ACQUISTATO = P_ACQ.ID_PRODOTTO_ACQUISTATO
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SV.ID_CINEMA_VENDITA = COM.ID_CINEMA_VENDITA
        AND SV.FLG_ANNULLATO = 'N'
        AND CS.ID_CIRCUITO_CINEMA = SV.ID_CIRCUITO_CINEMA
        AND CS.FLG_ANNULLATO = 'N'
        AND CIN.ID_CINEMA = CS.ID_CINEMA
        AND CIN.FLG_ANNULLATO = 'N'
        AND COM.ID_COMUNE = CIN.ID_COMUNE;
    RETURN v_sale_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_CINEMA_PROD_ACQ;

--------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_AREE_NIELSEN_PROD_ACQ
-- DESCRIZIONE:  Restituisce le aree nielsen di un prodotto acquistato
--
-- INPUT:
--      p_id_prodotto_acquistato   id del prodotto acquistato
--
-- OUTPUT: cursore che contiene i record con le aree trovate
--
--
-- REALIZZATORE  Simone Bottani, Altran Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_AREE_NIELSEN_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_AREA_NIELSEN IS
v_aree_nielsen C_AREA_NIELSEN;
BEGIN
   OPEN v_aree_nielsen FOR
      SELECT ID_AREA_NIELSEN, DESC_AREA--,
     --PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_NUM_SCHERMI_NIELSEN(ID_AREA_NIELSEN, p_id_prodotto_vendita, p_id_circuito, p_data_inizio, p_data_fine) AS NUM_SCHERMI,
     --PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_REGIONI_NIELSEN(ID_AREA_NIELSEN) AS REGIONI
      FROM CD_AREA_NIELSEN
      WHERE ID_AREA_NIELSEN IN
      (SELECT ID_AREA_NIELSEN FROM CD_AREE_PRODOTTO_ACQUISTATO
      WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato);
   RETURN  v_aree_nielsen;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_AREA_NIELSEN: ERRORE '||SQLERRM);

END FU_GET_AREE_NIELSEN_PROD_ACQ;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_COUNT_PROD_ACQ_PERIODO
--
-- DESCRIZIONE:  Restituisce il numero di prodotti acquistati di un determinato periodo di un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_data_inizio           data inizio del periodo
--  p_data_fine             data fine del periodo
--
--  OUTPUT: numero di prodotti richiesti
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_COUNT_PROD_ACQ_PERIODO(p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                 p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                 p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN NUMBER IS
 --                                p_tipo_periodo VARCHAR2) RETURN NUMBER IS

v_count NUMBER;

BEGIN
--       IF p_tipo_periodo = 'SPE' THEN
            SELECT COUNT(ID_PRODOTTO_ACQUISTATO) INTO v_count FROM CD_PRODOTTO_ACQUISTATO PR
                WHERE PR.ID_PIANO = p_id_piano
                AND PR.ID_VER_PIANO = p_id_ver_piano
                AND PR.DATA_INIZIO = p_data_inizio
                AND PR.DATA_FINE = p_data_fine
                AND PR.FLG_ANNULLATO = 'N'
                AND PR.FLG_SOSPESO = 'N';

   RETURN  v_count;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FU_COUNT_PROD_ACQ_PERIODO: ERRORE '||SQLERRM);

END FU_COUNT_PROD_ACQ_PERIODO;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_RICALCOLA_IMP_FAT
--
-- DESCRIZIONE:  Effettua il ricalcolo degli importi fatturazione, quando viene modificato l'importo
--               di un prodotto a cui fanno riferimento
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_importo_prodotto      id dell'importo prodotto
--  p_vecchio_netto            vecchio netto dell'importo prodotto
--  p_nuovo_netto              nuovo netto dell'importo prodotto
--
--  OUTPUT:
--
-- REALIZZATORE: Michele Borgogno , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_IMP_FAT(p_id_importo_prodotto CD_IMPORTI_FATTURAZIONE.ID_IMPORTI_PRODOTTO%TYPE,
                               p_vecchio_netto CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE,
                               p_nuovo_netto CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE) IS
v_netto_giorno CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
v_netto_parziale CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE := 0;
v_num_importi NUMBER;
v_giorni_fattura NUMBER;
v_netto_importo CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
v_indice_importi NUMBER := 0;
v_indice_soggetti NUMBER := 0;
v_num_sogg NUMBER;
v_netto_soggetto CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
v_netto_soggetto_parziale CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
BEGIN
    --dbms_output.put_line('p_nuovo_netto: '||p_nuovo_netto);
    IF p_nuovo_netto = 0 THEN
        UPDATE CD_IMPORTI_FATTURAZIONE
        SET IMPORTO_NETTO = 0
        WHERE ID_IMPORTI_PRODOTTO = p_id_importo_prodotto
        AND FLG_ANNULLATO = 'N';
    ELSE
        SELECT (p_nuovo_netto / (DATA_FINE - DATA_INIZIO + 1))
        INTO v_netto_giorno
        FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PRODOTTO_ACQUISTATO IN
        (SELECT ID_PRODOTTO_ACQUISTATO FROM CD_IMPORTI_PRODOTTO
         WHERE ID_IMPORTI_PRODOTTO = p_id_importo_prodotto);
        SELECT COUNT(1)
        INTO v_num_importi
        FROM CD_IMPORTI_FATTURAZIONE
        WHERE ID_IMPORTI_PRODOTTO = p_id_importo_prodotto
        AND FLG_ANNULLATO = 'N';
        --

        FOR IMPF IN (SELECT IMP_FAT.IMPORTO_NETTO, IMP_FAT.ID_IMPORTI_FATTURAZIONE FROM CD_IMPORTI_FATTURAZIONE IMP_FAT
                         WHERE IMP_FAT.ID_IMPORTI_PRODOTTO = p_id_importo_prodotto
                         AND FLG_ANNULLATO = 'N') LOOP
            --dbms_output.put_line('importo_fatturazione: '||IMPF.ID_IMPORTI_FATTURAZIONE);
            IF v_indice_importi < v_num_importi THEN
                SELECT DATA_FINE - DATA_INIZIO +1
                INTO v_giorni_fattura
                FROM CD_IMPORTI_FATTURAZIONE
                WHERE ID_IMPORTI_FATTURAZIONE = IMPF.ID_IMPORTI_FATTURAZIONE
                AND FLG_ANNULLATO = 'N';
                v_netto_importo := ROUND(v_giorni_fattura * v_netto_giorno,2);
                v_netto_parziale := v_netto_parziale + v_netto_importo;
            ELSE
                v_netto_importo := p_nuovo_netto - v_netto_parziale;
            END IF;
            --dbms_output.put_line('v_netto_importo: '||v_netto_importo);
            v_indice_soggetti := 0;
            v_netto_soggetto_parziale := 0;
            FOR SOGG IN (SELECT DISTINCT COM.ID_SOGGETTO_DI_PIANO, COUNT(DISTINCT COM.ID_SOGGETTO_DI_PIANO) AS NUM_SOGG
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
                    IF v_indice_soggetti < SOGG.NUM_SOGG THEN
                        v_netto_soggetto := ROUND(v_netto_importo / SOGG.NUM_SOGG,2);
                    ELSE
                        v_netto_soggetto := v_netto_importo - v_netto_soggetto_parziale;
                    END IF;
                    --dbms_output.put_line('v_netto_soggetto: '||v_netto_soggetto);
                    UPDATE CD_IMPORTI_FATTURAZIONE
                    SET IMPORTO_NETTO = v_netto_soggetto
                    WHERE ID_IMPORTI_FATTURAZIONE = IMPF.ID_IMPORTI_FATTURAZIONE;
                    v_netto_soggetto_parziale := v_netto_soggetto_parziale + v_netto_soggetto;
                    v_indice_soggetti := v_indice_soggetti +1;
                END LOOP;
                v_indice_importi := v_indice_importi +1;
        END LOOP;
    END IF;
    UPDATE CD_IMPORTI_FATTURAZIONE
    SET STATO_FATTURAZIONE = 'DAR'
    WHERE ID_IMPORTI_PRODOTTO = p_id_importo_prodotto
    AND STATO_FATTURAZIONE = 'TRA';
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PR_RICALCOLA_IMP_FAT: ERRORE '||SQLERRM);

END PR_RICALCOLA_IMP_FAT;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_RAGGRUPPAMENTO
--
-- DESCRIZIONE:  Modifica il raggruppamento intermediari di un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato  id del prodotto acquistato
--  p_id_raggruppamento       id del raggruppamento intermediari
--
--  OUTPUT:
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_RAGGRUPPAMENTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                      p_id_raggruppamento CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE) IS
v_id_cond_pagamento CD_ORDINE.ID_COND_PAGAMENTO%TYPE;
v_perc_ssda CD_IMPORTI_FATTURAZIONE.PERC_SCONTO_SOST_AGE%TYPE;
v_perc_vend_cli CD_IMPORTI_FATTURAZIONE.PERC_VEND_CLI%TYPE;
BEGIN
    FOR IMPP IN (SELECT IMP.ID_IMPORTI_PRODOTTO, IMP.DGC_TC_ID, IMP.TIPO_CONTRATTO
                 FROM CD_IMPORTI_PRODOTTO IMP WHERE
                 ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato)LOOP
        --
        FOR IMPF IN (SELECT FAT.ID_IMPORTI_FATTURAZIONE, ORD.ID_COND_PAGAMENTO FROM CD_IMPORTI_FATTURAZIONE FAT, CD_ORDINE ORD
                    WHERE FAT.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
                    AND FAT.FLG_ANNULLATO = 'N'
                    AND FAT.ID_ORDINE = ORD.ID_ORDINE
                    AND ORD.FLG_ANNULLATO = 'N') LOOP
            v_perc_ssda := PA_CD_ORDINE.FU_CD_GET_PERC_SSDA(p_id_raggruppamento,IMPF.ID_COND_PAGAMENTO);
            v_perc_vend_cli := PA_CD_ORDINE.FU_CD_GET_PERC_CLI(IMPP.DGC_TC_ID, IMPF.ID_COND_PAGAMENTO, p_id_raggruppamento);
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
    END LOOP;
END PR_MODIFICA_RAGGRUPPAMENTO;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_RAGGRUPPAMENTO
--
-- DESCRIZIONE:  Modifica il fruitore di un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato  id del prodotto acquistato
--  p_id_fruitore              id del fruitore
--
--  OUTPUT:
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_FRUITORE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                               p_id_fruitore CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE) IS
v_esito NUMBER;
BEGIN
    FOR ORD IN (SELECT DISTINCT O.ID_ORDINE FROM CD_ORDINE O, CD_IMPORTI_FATTURAZIONE FAT, CD_IMPORTI_PRODOTTO IMP
                WHERE IMP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND FAT.ID_IMPORTI_PRODOTTO = IMP.ID_IMPORTI_PRODOTTO
                AND O.ID_ORDINE = FAT.ID_ORDINE)LOOP
        PA_CD_ORDINE.PR_ANNULLA_ORDINE(ORD.ID_ORDINE,v_esito);
    END LOOP;
END PR_MODIFICA_FRUITORE;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_NUM_IMPORTI_FAT
--
-- DESCRIZIONE:  Restituisce il numero di importi fatturazione trattati dalla fatturazione
--               per un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      id dell'importo prodotto
--
--  OUTPUT: Numero di importi fatturazione
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_IMPORTI_FAT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER IS
v_num_importi NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_num_importi
    FROM
         CD_PRODOTTO_ACQUISTATO PA,
         CD_IMPORTI_PRODOTTO IMPP,
         CD_IMPORTI_FATTURAZIONE IMPF
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
    AND IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
    AND (IMPF.STATO_FATTURAZIONE = 'TRA' OR IMPF.STATO_FATTURAZIONE = 'DAR')
    AND IMPF.FLG_ANNULLATO = 'N';
RETURN v_num_importi;
END FU_GET_NUM_IMPORTI_FAT;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_AMBIENTI_PROD_ACQ
--
-- DESCRIZIONE:  Modifica gli ambienti di un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      id dell'importo prodotto
--  p_list_id_ambito              lista di ambienti da associare al prodotto
--
--  OUTPUT:
--
-- REALIZZATORE: Simone Bottani, Altran, Febbraio 2010
--
--  
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_AMBIENTI_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                        p_list_id_ambito        id_list_type) IS
--
v_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE;
--v_id_tariffa CD_PRODOTTO_VENDITA.ID_TARIFFA%TYPE;
v_luoghi PA_CD_ESTRAZIONE_PROD_VENDITA.C_LUOGO;
v_ambiente PA_CD_ESTRAZIONE_PROD_VENDITA.R_LUOGO;
v_schermi C_SCHERMI_PA;
v_schermo_rec R_SCHERMI_PA;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_unita_temp CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;
v_soggetto CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
v_count_sogg NUMBER;
v_id_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_num_comunicati NUMBER;
v_trovato BOOLEAN;
v_imp_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_piani_errati VARCHAR2(20000);
v_num_ambienti NUMBER;
v_string_id_ambito   varchar2(32000);
v_string_ambiti_prodotto   varchar2(32000);
v_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
v_luogo CD_LUOGO.ID_LUOGO%TYPE;
BEGIN

    SELECT PA.ID_PIANO, PA.ID_VER_PIANO, PA.ID_PRODOTTO_VENDITA, PV.ID_CIRCUITO, PA.DATA_INIZIO, PA.DATA_FINE, PA.ID_FORMATO,  PA.IMP_TARIFFA, MIS.ID_UNITA, TAR.ID_TARIFFA, PA.STATO_DI_VENDITA
    INTO v_id_piano, v_id_ver_piano, v_id_prodotto_vendita, v_id_circuito, v_data_inizio, v_data_fine,  v_id_formato, v_imp_tariffa, v_unita_temp, v_id_tariffa, v_stato_vendita
    FROM CD_MISURA_PRD_VENDITA MIS, CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND   PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
    AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
    AND TAR.DATA_INIZIO <= PA.DATA_INIZIO
    AND TAR.DATA_FINE >= PA.DATA_FINE
    AND (PA.ID_TIPO_CINEMA IS NULL OR PA.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
    AND (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PA.ID_FORMATO)
    AND PA.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE
    AND TAR.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE;
    --
    SELECT COUNT(DISTINCT C.ID_SOGGETTO_DI_PIANO)
    INTO v_count_sogg
    FROM CD_SOGGETTO_DI_PIANO S, CD_COMUNICATO C
    WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND C.ID_SOGGETTO_DI_PIANO = S.ID_SOGGETTO_DI_PIANO
    AND S.DESCRIZIONE != 'SOGGETTO NON DEFINITO';
--
    IF v_count_sogg > 0 THEN
       SELECT C.ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
       FROM CD_SOGGETTO_DI_PIANO S, CD_COMUNICATO C
       WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
       AND C.FLG_ANNULLATO = 'N'
       AND C.FLG_SOSPESO = 'N'
       AND C.COD_DISATTIVAZIONE IS NULL
       AND S.ID_SOGGETTO_DI_PIANO = C.ID_SOGGETTO_DI_PIANO
       AND S.DESCRIZIONE != 'SOGGETTO NON DEFINITO'
       AND ROWNUM = 1;
    ELSE
       SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
       FROM CD_SOGGETTO_DI_PIANO
       WHERE ID_PIANO = v_id_piano
       AND   ID_VER_PIANO = v_id_ver_piano
       AND DESCRIZIONE = 'SOGGETTO NON DEFINITO';
    END IF;
   --
    FOR i IN p_list_id_ambito.FIRST..p_list_id_ambito.LAST LOOP
          v_string_id_ambito := v_string_id_ambito||LPAD(p_list_id_ambito(i),5,'0')||'|';
    end LOOP;
    --
    v_num_ambienti := FU_GET_NUM_AMBIENTI(p_id_prodotto_acquistato);

    v_nuova_tariffa := ROUND(v_imp_tariffa / v_num_ambienti,2);

    v_luogo := FU_GET_LUOGO_PROD_ACQ(p_id_prodotto_acquistato);

    IF v_luogo = 1 THEN
        PR_MODIFICA_SCHERMI_PROD_ACQ(p_id_prodotto_acquistato,
                                 v_data_inizio,
                                 v_data_fine,
                                 v_id_prodotto_vendita,
                                 v_soggetto,
                                 v_id_circuito,
                                 v_stato_vendita,
                                 v_string_id_ambito);
    ELSIF v_luogo = 2 THEN
        PR_MODIFICA_SALE_PROD_ACQ(p_id_prodotto_acquistato,
                                 v_data_inizio,
                                 v_data_fine,
                                 v_id_prodotto_vendita,
                                 v_soggetto,
                                 v_id_circuito,
                                 v_stato_vendita,
                                 v_string_id_ambito);
    ELSIF v_luogo = 3 THEN
        PR_MODIFICA_ATRII_PROD_ACQ(p_id_prodotto_acquistato,
                                 v_data_inizio,
                                 v_data_fine,
                                 v_id_prodotto_vendita,
                                 v_soggetto,
                                 v_id_circuito,
                                 v_stato_vendita,
                                 v_string_id_ambito);
    ELSIF v_luogo = 4 THEN
        PR_MODIFICA_CINEMA_PROD_ACQ(p_id_prodotto_acquistato,
                                 v_data_inizio,
                                 v_data_fine,
                                 v_id_prodotto_vendita,
                                 v_soggetto,
                                 v_id_circuito,
                                 v_stato_vendita,
                                 v_string_id_ambito);
    END IF;
    PR_RICALCOLA_TARIFFA_PROD_ACQ(p_id_prodotto_acquistato,
                      v_imp_tariffa,
                      v_nuova_tariffa,
                      'S',
                      v_piani_errati);
                    
END PR_MODIFICA_AMBIENTI_PROD_ACQ;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_AMBIENTI_PROD_ACQ
--
-- DESCRIZIONE:  Modifica le aree nielsen di un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      id dell'importo prodotto
--  p_list_id_area               lista di aree da associare al prodotto
--
--  OUTPUT:
--
-- REALIZZATORE: Simone Bottani, Altran, Febbraio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_AREE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_list_id_area        id_list_type) IS

v_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;
v_count_sogg NUMBER;
v_soggetto CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_unita_temp CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_imp_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_id_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_aree C_AREA_NIELSEN;
v_area_rec R_AREA_NIELSEN;
v_trovato BOOLEAN;
v_vecchia_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_nuova_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_piani_errati VARCHAR2(20000);
v_num_schermi NUMBER;
v_list_id_aree_prodotto id_list_type := id_list_type();
v_num_aree_vecchio NUMBER;
v_id_maggiorazione CD_MAGGIORAZIONE.ID_MAGGIORAZIONE%TYPE;
v_nuovo_importo_magg CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_prodotto_acquistato_cur C_PROD_ACQ_PIANO;
v_prodotto_acquistato_rec R_PROD_ACQ_PIANO;
v_esito NUMBER;
v_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
BEGIN

    SELECT PA.ID_PIANO, PA.ID_VER_PIANO, PA.ID_PRODOTTO_VENDITA, PV.ID_CIRCUITO, PA.DATA_INIZIO, PA.DATA_FINE, PA.ID_FORMATO,  PA.IMP_TARIFFA, MIS.ID_UNITA, TAR.ID_TARIFFA, PA.STATO_DI_VENDITA
        INTO v_id_piano, v_id_ver_piano, v_id_prodotto_vendita, v_id_circuito, v_data_inizio, v_data_fine,  v_id_formato, v_imp_tariffa, v_unita_temp, v_id_tariffa, v_stato_vendita
        FROM CD_MISURA_PRD_VENDITA MIS, CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
        WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND   PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
        AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TAR.DATA_INIZIO <= PA.DATA_INIZIO
        AND TAR.DATA_FINE >= PA.DATA_FINE
        AND (PA.ID_TIPO_CINEMA IS NULL OR PA.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
        AND (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PA.ID_FORMATO)
        AND TAR.ID_MISURA_PRD_VE = MIS.ID_MISURA_PRD_VE;
--
    IF v_count_sogg > 0 THEN
       SELECT C.ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
       FROM CD_SOGGETTO_DI_PIANO S, CD_COMUNICATO C
       WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
       AND C.FLG_ANNULLATO = 'N'
       AND C.FLG_SOSPESO = 'N'
       AND C.COD_DISATTIVAZIONE IS NULL
       AND S.ID_SOGGETTO_DI_PIANO = C.ID_SOGGETTO_DI_PIANO
       AND S.DESCRIZIONE != 'SOGGETTO NON DEFINITO'
       AND ROWNUM = 1;
    ELSE
       SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
       FROM CD_SOGGETTO_DI_PIANO
       WHERE ID_PIANO = v_id_piano
       AND   ID_VER_PIANO = v_id_ver_piano
       AND DESCRIZIONE = 'SOGGETTO NON DEFINITO';
    END IF;
   --
   BEGIN
   SELECT DISTINCT POSIZIONE_DI_RIGORE
   INTO v_id_posizione_rigore
   FROM CD_COMUNICATO
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
   AND FLG_ANNULLATO = 'N'
   AND FLG_SOSPESO = 'N'
   AND COD_DISATTIVAZIONE IS NULL;
   EXCEPTION
        WHEN OTHERS THEN
        NULL;
   END;
    SELECT COUNT(1)
    INTO v_num_aree_vecchio
    FROM CD_AREE_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    --
    v_num_schermi := FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato);
    v_vecchia_tariffa := ROUND(v_imp_tariffa / v_num_schermi,2);
    --
    v_aree := FU_GET_AREE_NIELSEN_PROD_ACQ(p_id_prodotto_acquistato);
    --dbms_output.put_line('controllo aree eliminate');
    LOOP
      FETCH v_aree INTO v_area_rec;
      EXIT WHEN v_aree%NOTFOUND;
           --dbms_output.put_line('area'||v_area_rec.a_id_area_nielsen);
           v_trovato := FALSE;
           v_list_id_aree_prodotto.EXTEND;
           v_list_id_aree_prodotto(v_aree%ROWCOUNT) := v_area_rec.a_id_area_nielsen;
           FOR i IN 1..p_list_id_area.COUNT LOOP
                --dbms_output.put_line('area input '||p_list_id_area(i));
                IF p_list_id_area(i) = v_area_rec.a_id_area_nielsen THEN
                    --dbms_output.put_line('area trovata '||v_area_rec.a_id_area_nielsen);
                    v_trovato := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF v_trovato = FALSE THEN
            --dbms_output.put_line('elimino area '||v_area_rec.a_id_area_nielsen);
                UPDATE CD_COMUNICATO
                SET FLG_ANNULLATO = 'S'
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND FLG_ANNULLATO = 'N'
                AND ID_COMUNICATO IN
                (SELECT ID_COMUNICATO FROM CD_COMUNICATO
                 WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                 AND ID_SALA IN
                       (SELECT ID_SALA FROM CD_SALA WHERE ID_CINEMA IN
                           (SELECT ID_CINEMA FROM CD_CINEMA WHERE ID_COMUNE IN
                               (SELECT ID_COMUNE FROM CD_COMUNE WHERE ID_PROVINCIA IN
                                   (SELECT ID_PROVINCIA FROM CD_PROVINCIA WHERE ID_REGIONE IN
                                        (SELECT ID_REGIONE FROM CD_REGIONE WHERE ID_REGIONE IN
                                              (SELECT ID_REGIONE FROM CD_NIELSEN_REGIONE WHERE ID_AREA_NIELSEN = v_area_rec.a_id_area_nielsen)))))));
            --
            DELETE FROM CD_AREE_PRODOTTO_ACQUISTATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND ID_AREA_NIELSEN = v_area_rec.a_id_area_nielsen;
            --
            END IF;
    END LOOP;
    CLOSE v_aree;

    FOR i IN 1..p_list_id_area.COUNT LOOP
            v_trovato := FALSE;
            FOR j IN 1..v_list_id_aree_prodotto.COUNT LOOP
                IF p_list_id_area(i) = v_list_id_aree_prodotto(j) THEN
                    v_trovato := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF v_trovato = FALSE THEN
            --dbms_output.put_line('aggiungo area '||p_list_id_area(i));
                INSERT INTO CD_COMUNICATO (
                      VERIFICATO,
                      --SS_PREV,
                      /*MM_INIZIO_PREV,
                      HH_INIZIO_PREV,
                      MM_FINE_PREV,
                      HH_FINE_PREV,*/
                      ID_PRODOTTO_ACQUISTATO,
                      ID_BREAK_VENDITA,
                      ID_CINEMA_VENDITA,
                      ID_ATRIO_VENDITA,
                      ID_SALA_VENDITA,
                      DATA_EROGAZIONE_PREV,
                      FLG_ANNULLATO,
                      --DGC,
                      ID_SOGGETTO_DI_PIANO,
                      POSIZIONE_DI_RIGORE,
                      ID_SALA,
                      ID_BREAK)
                      (
                      SELECT 'N',
                       /*CD_FASCIA.MM_INIZIO, CD_FASCIA.HH_INIZIO,
                       CD_FASCIA.MM_FINE, CD_FASCIA.HH_FINE,*/
                       p_id_prodotto_acquistato,
                       ID_BREAK_VENDITA,NULL,NULL,NULL,
                       CD_BREAK_VENDITA.DATA_EROGAZIONE,'N',v_soggetto,v_id_posizione_rigore,CD_SCHERMO.ID_SALA,CD_BREAK.ID_BREAK
                        FROM CD_BREAK_VENDITA, CD_CIRCUITO_BREAK, CD_BREAK, CD_SCHERMO, CD_PROIEZIONE, CD_FASCIA
                        WHERE CD_CIRCUITO_BREAK.ID_CIRCUITO = v_id_circuito
                        AND CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
                        AND CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                        AND CD_BREAK_VENDITA.DATA_EROGAZIONE BETWEEN v_data_inizio AND v_data_fine
                        AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
                        AND CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
                        --AND CD_BREAK_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb
                        AND CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
                        AND CD_BREAK.FLG_ANNULLATO = 'N'
                        AND CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
                        AND CD_PROIEZIONE.ID_FASCIA = CD_FASCIA.ID_FASCIA
                        AND CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
                        AND CD_SCHERMO.FLG_ANNULLATO = 'N'
                        AND CD_SCHERMO.ID_SALA IN
                               (SELECT ID_SALA FROM CD_SALA WHERE ID_CINEMA IN
                                   (SELECT ID_CINEMA FROM CD_CINEMA WHERE ID_COMUNE IN
                                       (SELECT ID_COMUNE FROM CD_COMUNE WHERE ID_PROVINCIA IN
                                           (SELECT ID_PROVINCIA FROM CD_PROVINCIA WHERE ID_REGIONE IN
                                                (SELECT ID_REGIONE FROM CD_REGIONE WHERE ID_REGIONE IN
                                                      (SELECT ID_REGIONE FROM CD_NIELSEN_REGIONE WHERE ID_AREA_NIELSEN = p_list_id_area(i))))))));
        INSERT INTO CD_AREE_PRODOTTO_ACQUISTATO
        (ID_PRODOTTO_ACQUISTATO,ID_AREA_NIELSEN)
        values
        (p_id_prodotto_acquistato,p_list_id_area(i));
        --
        END IF;
    END LOOP;
    IF v_stato_vendita = 'PRE' THEN
        FOR C IN (SELECT ID_COMUNICATO
                  FROM CD_COMUNICATO
                  WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                  AND FLG_ANNULLATO = 'N'
                  AND FLG_SOSPESO = 'N'
                  AND COD_DISATTIVAZIONE IS NULL
                  AND POSIZIONE IS NULL
                  ) LOOP
            PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,c.ID_COMUNICATO);
        END LOOP;
    END IF;
   --
    v_num_schermi := FU_GET_NUM_SCHERMI(p_id_prodotto_acquistato);
    v_nuova_tariffa := ROUND(v_imp_tariffa / v_num_schermi,2);

    --dbms_output.put_line('v_nuova_tariffa'||v_nuova_tariffa);
    IF v_num_aree_vecchio != p_list_id_area.COUNT THEN
        DELETE FROM CD_MAGG_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND ID_MAGGIORAZIONE IN
        (SELECT ID_MAGGIORAZIONE
        FROM CD_MAGGIORAZIONE
        WHERE ID_TIPO_MAGG = 3);

        IF p_list_id_area.COUNT < 4 THEN
            IF p_list_id_area.COUNT = 1 THEN
                v_id_maggiorazione := 2;
            ELSIF p_list_id_area.COUNT = 2 THEN
                v_id_maggiorazione := 3;
            ELSIF p_list_id_area.COUNT = 3 THEN
                v_id_maggiorazione := 4;
            END IF;
        --
            PR_SALVA_MAGGIORAZIONE(p_id_prodotto_acquistato,v_id_maggiorazione);
        END IF;
        --
        v_nuovo_importo_magg := 0;
        FOR MAG IN (SELECT M.PERCENTUALE_VARIAZIONE
                    FROM CD_MAGG_PRODOTTO MP, CD_MAGGIORAZIONE M
                    WHERE MP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND M.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE) LOOP
            --dbms_output.put_line('v_vecchia_tariffa'||v_imp_tariffa);
            --dbms_output.put_line('Perc Maggiorazione: '||MAG.PERCENTUALE_VARIAZIONE);
            v_nuovo_importo_magg := v_nuovo_importo_magg + PA_CD_TARIFFA.FU_CALCOLA_MAGGIORAZIONE(v_imp_tariffa,MAG.PERCENTUALE_VARIAZIONE);
        END LOOP;
        --dbms_output.put_line('Nuovo importo maggiorazione: '||v_nuovo_importo_magg);
        v_prodotto_acquistato_cur := FU_GET_DETT_PROD_ACQ(p_id_prodotto_acquistato);
        --v_esito := v_prodotto_acquistato.a_tariffa;
        FETCH v_prodotto_acquistato_cur INTO v_prodotto_acquistato_rec;
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_prodotto_acquistato_rec.a_tariffa, v_prodotto_acquistato_rec.a_maggiorazione, v_prodotto_acquistato_rec.a_lordo,
                                    v_prodotto_acquistato_rec.a_lordo_comm, v_prodotto_acquistato_rec.a_lordo_dir, v_prodotto_acquistato_rec.a_netto_comm, v_prodotto_acquistato_rec.a_netto_dir,
                                    v_prodotto_acquistato_rec.a_perc_sconto_comm, v_prodotto_acquistato_rec.a_perc_sconto_dir, v_prodotto_acquistato_rec.a_sc_comm, v_prodotto_acquistato_rec.a_sc_dir,
                                    v_prodotto_acquistato_rec.a_sanatoria, v_prodotto_acquistato_rec.a_recupero, v_nuovo_importo_magg, '1', v_esito);
        --
        UPDATE CD_PRODOTTO_ACQUISTATO
        SET IMP_TARIFFA = v_prodotto_acquistato_rec.a_tariffa,
            IMP_MAGGIORAZIONE = v_prodotto_acquistato_rec.a_maggiorazione,
            IMP_LORDO = v_prodotto_acquistato_rec.a_lordo,
            IMP_NETTO = v_prodotto_acquistato_rec.a_netto_comm + v_prodotto_acquistato_rec.a_netto_dir,
            IMP_RECUPERO = v_prodotto_acquistato_rec.a_recupero,
            IMP_SANATORIA = v_prodotto_acquistato_rec.a_sanatoria
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
        --
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_prodotto_acquistato_rec.a_netto_comm,
            IMP_SC_COMM = v_prodotto_acquistato_rec.a_sc_comm
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND TIPO_CONTRATTO = 'C';
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = v_prodotto_acquistato_rec.a_netto_dir,
            IMP_SC_COMM = v_prodotto_acquistato_rec.a_sc_dir
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND TIPO_CONTRATTO = 'D';
        CLOSE v_prodotto_acquistato_cur;
    END IF;
    --
    PR_RICALCOLA_TARIFFA_PROD_ACQ(p_id_prodotto_acquistato,
                          v_vecchia_tariffa,
                          v_vecchia_tariffa,
                          'S',
                          v_piani_errati);
    --
END PR_MODIFICA_AREE_PROD_ACQ;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_DETT_PROD_ACQ
--
-- DESCRIZIONE:  Restituisce il dettaglio di un prodotto acquistato
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato    id del prodotto acquistato
--  OUTPUT:      prodotto acquistato
--
-- REALIZZATORE: Simone Bottani , Altran, Febbraio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_DETT_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_PROD_ACQ_PIANO IS
v_prodotti C_PROD_ACQ_PIANO;
BEGIN
OPEN v_prodotti FOR
    SELECT ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA, IMP_LORDO, IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE, IMP_RECUPERO, IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS IMP_LORDO_COMM,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS IMP_LORDO_DIR,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS PERC_SCONTO_COMM,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS PERC_SCONTO_DIR,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           GET_COD_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as COD_SOGGETTO,
           GET_DESC_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as DESC_SOGGETTO,
           GET_TITOLO_MATERIALE(ID_PRODOTTO_ACQUISTATO) as TITOLO_MAT,
           count(distinct ID_SCHERMO) num_schermi,
           count(distinct ID_SALA) num_sale,
           count(distinct ID_ATRIO) num_atrii,
           count(distinct ID_CINEMA) num_cinema,
           count(distinct ID_COMUNICATO) as num_comunicati,
           ID_FORMATO,
           DESCRIZIONE AS DESC_FORMATO,
           DURATA,
           COD_POS_FISSA, DESC_POS_FISSA,
           FLG_TARIFFA_VARIABILE,
           DATA_INIZIO,
           DATA_FINE,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD
    FROM
        (SELECT CIR_CIN.ID_CINEMA,
               --CIR_CIN.ID_CIRCUITO_CINEMA, CIN_VEN.ID_CINEMA_VENDITA,
               FV_COM_BRK_SALA_ATR.*
        FROM
               CD_CIRCUITO_CINEMA CIR_CIN,
               CD_CINEMA_VENDITA CIN_VEN,
            (SELECT CIR_ATR.ID_ATRIO,
                   --CIR_ATR.ID_CIRCUITO_ATRIO, ATRIO_VEN.ID_ATRIO_VENDITA,
                   FV_COM_BRK_SALA.*
            FROM
                   CD_CIRCUITO_ATRIO CIR_ATR,
                   CD_ATRIO_VENDITA ATR_VEN,
                (SELECT CIR_SALA.ID_SALA,
                       --CIR_SALA.ID_CIRCUITO_SALA, SALA_VEN.ID_SALA_VENDITA,
                       FV_COM_BRK.*
                  FROM
                       CD_CIRCUITO_SALA CIR_SALA,
                       CD_SALA_VENDITA SALA_VEN,
                (SELECT CD_SCHERMO.ID_SCHERMO,
                       --PROIEZ.ID_PROIEZIONE, CD_BREAK.ID_BREAK, CIR_BR.ID_CIRCUITO_BREAK, BR_VEN.ID_BREAK_VENDITA,
                       FV_COM.*
                FROM
                       CD_SCHERMO,
                       CD_PROIEZIONE PROIEZ,
                       CD_BREAK,
                       CD_CIRCUITO_BREAK CIR_BR,
                       CD_BREAK_VENDITA  BR_VEN,
                       (SELECT PR_ACQ.ID_PRODOTTO_ACQUISTATO,
                               PR_ACQ.ID_PRODOTTO_VENDITA,
                               PR_PUB.DESC_PRODOTTO,
                               CD_CIRCUITO.ID_CIRCUITO,
                               CD_CIRCUITO.NOME_CIRCUITO,
                               MOD_VEN.ID_MOD_VENDITA,
                               MOD_VEN.DESC_MOD_VENDITA,
                               TI_BR.ID_TIPO_BREAK,
                               TI_BR.DESC_TIPO_BREAK,
                               PC_MANIF.DES_MAN,
                               PR_ACQ.ID_RAGGRUPPAMENTO,
                               PR_ACQ.ID_FRUITORI_DI_PIANO,
                               PR_ACQ.STATO_DI_VENDITA,
                               PR_ACQ.IMP_TARIFFA, PR_ACQ.IMP_LORDO, PR_ACQ.IMP_NETTO,
                               PR_ACQ.FLG_TARIFFA_VARIABILE,
                               PR_ACQ.DATA_INIZIO,
                               PR_ACQ.DATA_FINE,
                               PR_ACQ.ID_TIPO_CINEMA,
                               IMP_PRD_D.IMP_NETTO as IMP_NETTO_DIR,
                               IMP_PRD_D.IMP_SC_COMM as IMP_SC_DIR,
                               IMP_PRD_C.IMP_NETTO as IMP_NETTO_COMM,
                               IMP_PRD_C.IMP_SC_COMM as IMP_SC_COMM,
                               PR_ACQ.IMP_MAGGIORAZIONE, PR_ACQ.IMP_RECUPERO, PR_ACQ.IMP_SANATORIA,
                               COM.ID_COMUNICATO, COM.ID_BREAK_VENDITA, COM.ID_SALA_VENDITA, COM.ID_ATRIO_VENDITA, COM.ID_CINEMA_VENDITA,
                               POS.COD_POSIZIONE AS COD_POS_FISSA, POS.DESCRIZIONE AS DESC_POS_FISSA,
                               F_ACQ.ID_FORMATO, F_ACQ.DESCRIZIONE, COEF.DURATA, TAR.ID_TIPO_TARIFFA,
                               PERIODO.ANNO ||'-'||PERIODO.CICLO||'-'||PERIODO.PER AS SETTIMANA_SIPRA,
                               PR_ACQ.DATAMOD
                         FROM
                               PERIODI PERIODO,
                               CD_POSIZIONE_RIGORE POS,
                               CD_COMUNICATO COM,
                               PC_MANIF,
                               CD_TIPO_BREAK TI_BR,
                               CD_MODALITA_VENDITA MOD_VEN,
                               CD_CIRCUITO,
                               CD_PRODOTTO_PUBB PR_PUB,
                               CD_TARIFFA TAR,
                               CD_PRODOTTO_VENDITA PR_VEN,
                               CD_COEFF_CINEMA COEF,
                               CD_FORMATO_ACQUISTABILE F_ACQ,
                               CD_IMPORTI_PRODOTTO IMP_PRD_D,
                               CD_IMPORTI_PRODOTTO IMP_PRD_C,
                               CD_PRODOTTO_ACQUISTATO PR_ACQ
                          WHERE PR_ACQ.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                            and PR_ACQ.FLG_ANNULLATO = 'N'
                            and PR_ACQ.FLG_SOSPESO = 'N'
                            and PR_ACQ.COD_DISATTIVAZIONE is null
                            and IMP_PRD_C.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and IMP_PRD_C.TIPO_CONTRATTO = 'C'
                            and IMP_PRD_D.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and IMP_PRD_D.TIPO_CONTRATTO = 'D'
                            and F_ACQ.ID_FORMATO = PR_ACQ.ID_FORMATO
                            AND COEF.ID_COEFF(+) = F_ACQ.ID_COEFF
                            and PR_VEN.ID_PRODOTTO_VENDITA = PR_ACQ.ID_PRODOTTO_VENDITA
                            and TAR.ID_PRODOTTO_VENDITA = PR_VEN.ID_PRODOTTO_VENDITA
                            and PR_ACQ.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
                            and PR_ACQ.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
                            and PR_ACQ.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE
                            and (PR_ACQ.ID_TIPO_CINEMA IS NULL OR PR_ACQ.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
                            and (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PR_ACQ.ID_FORMATO)
                            and PR_PUB.ID_PRODOTTO_PUBB = PR_VEN.ID_PRODOTTO_PUBB
                            and CD_CIRCUITO.ID_CIRCUITO = PR_VEN.ID_CIRCUITO
                            and MOD_VEN.ID_MOD_VENDITA = PR_VEN.ID_MOD_VENDITA
                            and TI_BR.ID_TIPO_BREAK(+) = PR_VEN.ID_TIPO_BREAK
                            and PC_MANIF.COD_MAN(+) = PR_VEN.COD_MAN
                            and COM.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
                            and COM.FLG_ANNULLATO='N'
                            and COM.FLG_SOSPESO='N'
                            and COM.COD_DISATTIVAZIONE IS NULL
                            and POS.COD_POSIZIONE (+) = COM.POSIZIONE_DI_RIGORE
                            and PR_ACQ.DATA_INIZIO = PERIODO.DATA_INIZ (+)
                            and PR_ACQ.DATA_FINE = PERIODO.DATA_FINE (+)
                            ) FV_COM
             where BR_VEN.ID_BREAK_VENDITA(+) = FV_COM.ID_BREAK_VENDITA
              and CIR_BR.ID_CIRCUITO_BREAK(+) = BR_VEN.ID_CIRCUITO_BREAK
              and CD_BREAK.ID_BREAK(+) = CIR_BR.ID_BREAK
              and PROIEZ.ID_PROIEZIONE(+) = CD_BREAK.ID_PROIEZIONE
              and CD_SCHERMO.ID_SCHERMO(+) = PROIEZ.ID_SCHERMO
            ) FV_COM_BRK
            where SALA_VEN.ID_SALA_VENDITA(+) = FV_COM_BRK.ID_SALA_VENDITA
              and CIR_SALA.ID_CIRCUITO_SALA(+) = SALA_VEN.ID_CIRCUITO_SALA
            ) FV_COM_BRK_SALA
        where ATR_VEN.ID_ATRIO_VENDITA(+) = FV_COM_BRK_SALA.ID_ATRIO_VENDITA
          and CIR_ATR.ID_CIRCUITO_ATRIO(+) = ATR_VEN.ID_CIRCUITO_ATRIO
        ) FV_COM_BRK_SALA_ATR
    where CIN_VEN.ID_CINEMA_VENDITA(+) = FV_COM_BRK_SALA_ATR.ID_CINEMA_VENDITA
      and CIR_CIN.ID_CIRCUITO_CINEMA(+) = CIN_VEN.ID_CIRCUITO_CINEMA
    ) FV_COM_BRK_SALA_ATR_CIN
    group by
           ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA,
           IMP_LORDO,
           IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE,
           IMP_RECUPERO,
           IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           ID_FORMATO,
           DESCRIZIONE,
           DURATA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           COD_POS_FISSA,
           DESC_POS_FISSA,
           FLG_TARIFFA_VARIABILE,
           DATA_INIZIO,
           DATA_FINE,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD
           order by DATA_INIZIO,DATA_FINE,ID_CIRCUITO;
return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_DETT_PROD_ACQ;

PROCEDURE PR_MODIFICA_IMPORTI_PRODOTTO(p_id_importi_prodotto CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE, p_netto_nuovo CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE, p_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE) is
    BEGIN
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = p_netto_nuovo,
            IMP_SC_COMM = p_sconto
        WHERE ID_IMPORTI_PRODOTTO = p_id_importi_prodotto;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_MODIFICA_IMPORTI_PRODOTTO: Errore' ||SQLERRM);
END PR_MODIFICA_IMPORTI_PRODOTTO;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_MODIFICA_STATO_VENDITA(
--
-- DESCRIZIONE:  Modifica lo stato di vendita di un prodotto acquistato
--
--
-- OPERAZIONI: In base al formato acquistabile passato viene riparametrata la tariffa del prodotto acquistato
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_stato_vendita               Nuovo stato di vendita del prodotto
--
--  OUTPUT:
--
-- OPERAZIONI:     1) Modifica lo stato di vendita del prodotto acquistato
--                 2) Verifica se si tratta di una prenotazione, in quel caso imposta la posizione
--                    ai comunicati del prodotto acquistato
-- REALIZZATORE: Simone Bottani , Altran, Gennaio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_STATO_VENDITA(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) IS
--
v_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE;
v_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE;
v_vecchio_stato_ven CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
v_luogo CD_LUOGO.ID_LUOGO%TYPE;
BEGIN
    SELECT STATO_DI_VENDITA
    INTO v_vecchio_stato_ven
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    --
   v_luogo := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_LUOGO_PROD_ACQ(p_id_prodotto_acquistato);

   IF p_stato_vendita = 'PRE' AND v_vecchio_stato_ven != 'PRE' THEN
            SELECT ID_PIANO, ID_VER_PIANO
            INTO v_id_piano, v_id_ver_piano
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
--
            UPDATE CD_PIANIFICAZIONE
            SET DATA_PRENOTAZIONE = SYSDATE
            WHERE ID_PIANO = v_id_piano
            AND ID_VER_PIANO = v_id_ver_piano
            AND DATA_PRENOTAZIONE IS NULL;
            IF v_luogo = 1 THEN
                PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,NULL);
            END IF;
   ELSIF v_vecchio_stato_ven = 'PRE' AND p_stato_vendita != 'PRE' THEN
            IF v_luogo = 1 THEN
                PR_ELIMINA_BUCO_POSIZIONE_PACQ(p_id_prodotto_acquistato);
            END IF;
   END IF;
   UPDATE CD_PRODOTTO_ACQUISTATO SET
                     STATO_DI_VENDITA = p_stato_vendita
    WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PR_MODIFICA_STATO_VENDITA: ERRORE '||SQLERRM);
END PR_MODIFICA_STATO_VENDITA;


PROCEDURE PR_SALVA_POS_RIGORE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                              p_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                              p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) IS
v_pos_rigore_vecchia CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
BEGIN

    SELECT DISTINCT NVL(POSIZIONE_DI_RIGORE,91)
    INTO v_pos_rigore_vecchia
    FROM CD_COMUNICATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    --
    UPDATE CD_COMUNICATO SET
                         POSIZIONE_DI_RIGORE = p_pos_rigore
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    --
    IF p_stato_vendita = 'PRE' AND v_pos_rigore_vecchia != p_pos_rigore THEN
        PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,NULL);
    END IF;
END PR_SALVA_POS_RIGORE;

-----------------------------------------------------------------------------------------------------
-- PROCEDURE PR_ELIMINA_BUCO_POSIZIONE(
--
-- DESCRIZIONE:  Dopo che un comunicato e stato annullato, oppure lo stqato di vendita del suo prodotto
--               da prenotato diventa opzionato, puo verificarsi un "buco" nelle posizioni del suo break,
--               posizioni di rigore che non rispettano piu la posizione acquistata. In questo caso viene scelto
--               un altro comunicato, se presente, per sostituire il comunicato annullato
--
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato      Id del prodotto acquistato
--  p_id_comunicato               Id del comunicato
--
--  OUTPUT:
--
-- OPERAZIONI:     1) Cicla in tutti i comunicati del prodotto acquistato (o il singolo comunicato)
--                 2) Controlla se la posizione del comunicato potrebbe causare un buco (maggiore della posizione 85)
--                 3) Verifica se esistono posizioni di rigore in posizione inferiore al comunicato
--                 4) Seleziono un comunicato nel break per eliminare il buco
-- REALIZZATORE: Simone Bottani , Altran, Febbraio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_BUCO_POSIZIONE_PACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) IS
--
BEGIN

       FOR COM IN(SELECT C.ID_COMUNICATO, C.ID_PRODOTTO_ACQUISTATO, C.POSIZIONE, C.ID_BREAK_VENDITA, BR.ID_BREAK
            FROM
            CD_BREAK BR,
            CD_CIRCUITO_BREAK CBR,
            CD_BREAK_VENDITA BRV,
            CD_COMUNICATO C
            WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND C.FLG_ANNULLATO = 'N'
            AND C.FLG_SOSPESO = 'N'
            AND C.COD_DISATTIVAZIONE IS NULL
            AND BRV.ID_BREAK_VENDITA = C.ID_BREAK_VENDITA
            AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
            AND BR.ID_BREAK = CBR.ID_BREAK
            )LOOP
                PR_ELIMINA_BUCO_POSIZIONE_COM(COM.ID_COMUNICATO);
        END LOOP;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PR_ELIMINA_BUCO_POSIZIONE_PACQ: ERRORE '||SQLERRM);
END PR_ELIMINA_BUCO_POSIZIONE_PACQ;

PROCEDURE PR_ELIMINA_BUCO_POSIZIONE_COM(p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE) IS
--
v_posizione CD_COMUNICATO.POSIZIONE%TYPE;
v_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE;
v_num_pos_rigore NUMBER;
v_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_id_break CD_BREAK.ID_BREAK%TYPE;
BEGIN

       SELECT C.ID_PRODOTTO_ACQUISTATO, C.POSIZIONE, BR.ID_BREAK
            INTO v_id_prodotto_acquistato, v_posizione, v_id_break
            FROM
            CD_BREAK BR,
            CD_CIRCUITO_BREAK CBR,
            CD_BREAK_VENDITA BRV,
            CD_COMUNICATO C
            WHERE C.ID_COMUNICATO = p_id_comunicato
            --AND C.FLG_ANNULLATO = 'N'
            --AND C.FLG_SOSPESO = 'N'
            --AND C.COD_DISATTIVAZIONE IS NULL
            AND BRV.ID_BREAK_VENDITA = C.ID_BREAK_VENDITA
            AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
            AND BR.ID_BREAK = CBR.ID_BREAK;
            --
            --dbms_output.PUT_LINE('Id comunicato: '||COM.ID_COMUNICATO);
            --dbms_output.PUT_LINE('Posizione: '||COM.POSIZIONE);
            IF v_posizione > 85 THEN
                --
                SELECT COUNT(1)
                INTO v_num_pos_rigore
                FROM CD_PRODOTTO_ACQUISTATO PA, CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_COMUNICATO COM2
                WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
                AND PA.ID_PRODOTTO_ACQUISTATO <> v_id_prodotto_acquistato
                AND COM2.POSIZIONE_DI_RIGORE IS NOT NULL
                AND COM2.POSIZIONE <= v_posizione
                AND COM2.POSIZIONE > 2
                AND COM2.FLG_ANNULLATO = 'N'
                AND COM2.FLG_SOSPESO = 'N'
                AND COM2.COD_DISATTIVAZIONE IS NULL
                AND COM2.ID_COMUNICATO != p_id_comunicato
                AND PA.STATO_DI_VENDITA = 'PRE'
                AND PA.FLG_ANNULLATO = 'N'
                AND PA.FLG_SOSPESO = 'N'
                AND PA.COD_DISATTIVAZIONE IS NULL
                AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
                AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                AND BR.ID_BREAK = CBR.ID_BREAK
                AND BR.ID_BREAK = v_id_break;
                --
                --dbms_output.PUT_LINE('Numero di pos rigore: '||v_num_pos_rigore);
                IF v_num_pos_rigore > 0 THEN
                    BEGIN
                    --dbms_output.PUT_LINE('Id break: '||COM.ID_BREAK);
                    SELECT ID_COMUNICATO
                    INTO v_id_comunicato
                    FROM
                    (
                    SELECT COM2.ID_COMUNICATO
                    FROM CD_PRODOTTO_ACQUISTATO PA, CD_BREAK BR, CD_CIRCUITO_BREAK CBR,
                    CD_BREAK_VENDITA BRV, CD_COMUNICATO COM2
                    WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
                    AND PA.ID_PRODOTTO_ACQUISTATO <> v_id_prodotto_acquistato
                    AND COM2.POSIZIONE_DI_RIGORE IS NULL
                    AND COM2.POSIZIONE < v_posizione
                    AND COM2.FLG_ANNULLATO = 'N'
                    AND COM2.FLG_SOSPESO = 'N'
                    AND COM2.COD_DISATTIVAZIONE IS NULL
                    AND COM2.ID_COMUNICATO != p_id_comunicato
                    AND PA.STATO_DI_VENDITA = 'PRE'
                    AND PA.FLG_ANNULLATO = 'N'
                    AND PA.FLG_SOSPESO = 'N'
                    AND PA.COD_DISATTIVAZIONE IS NULL
                    AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
                    AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                    AND BR.ID_BREAK = CBR.ID_BREAK
                    AND BR.ID_BREAK = v_id_break
                    ORDER BY COM2.POSIZIONE
                    )
                    WHERE ROWNUM = 1;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;
                        WHEN OTHERS THEN
                        RAISE;
                    END;
                    --
                    IF v_id_comunicato IS NOT NULL THEN
                        UPDATE CD_COMUNICATO
                        SET POSIZIONE = v_posizione
                        WHERE ID_COMUNICATO = v_id_comunicato;
                    END IF;
                END IF;
            END IF;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PR_ELIMINA_BUCO_POSIZIONE_COM: ERRORE '||SQLERRM);
END PR_ELIMINA_BUCO_POSIZIONE_COM;

/******************************************************************************
   NAME:        FU_GET_PRESENZA_TOP_SPOT
   PURPOSE:     Calcola  la presenza di top spot sul prodotto acquistato
                restituiece 1 se non vi e disponibilita sulla proiezione
                2 sul break. Zero altrimenti.

   1.0       15/02/2010   Michele Borgogno - Mauro Viel Altran  Marzo 2010
******************************************************************************/

FUNCTION FU_GET_PRESENZA_TOP_SPOT(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE) RETURN NUMBER IS

v_numero_prodotti number;
BEGIN

v_numero_prodotti := 0;
select count(distinct(pa.id_prodotto_acquistato)) into v_numero_prodotti
    from cd_prodotto_acquistato pa,
         cd_comunicato com,
         cd_prodotto_vendita pro_ven,
         cd_break_vendita brk_ven,
         cd_circuito_break cir_bre,
         cd_proiezione pro,
         cd_break brk,
        (select pro.id_proiezione,pa.ID_PRODOTTO_ACQUISTATO,brk.id_tipo_break
            from cd_prodotto_acquistato pa,
                cd_comunicato com,
                cd_prodotto_vendita pro_ven,
                cd_break_vendita brk_ven,
                cd_circuito_break cir_bre,
                cd_break brk,
                cd_proiezione pro
            where  pa.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            and    pro_ven.ID_PRODOTTO_VENDITA = pa.ID_PRODOTTO_VENDITA
            and    brk_ven.ID_PRODOTTO_VENDITA = pro_ven.ID_PRODOTTO_VENDITA
            and    com.ID_BREAK_VENDITA = brk_ven.ID_BREAK_VENDITA
            and    com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
            and    brk_ven.ID_CIRCUITO_BREAK  = cir_bre.ID_CIRCUITO_BREAK
            and    cir_bre.ID_BREAK  = brk.ID_BREAK
            and    brk.ID_PROIEZIONE = pro.ID_PROIEZIONE
            and    com.FLG_ANNULLATO = 'N'
            and    com.FLG_SOSPESO = 'N'
--            and    (brk.ID_BREAK = 4 or brk.ID_BREAK = 5)
            group by pro.id_proiezione,brk.id_tipo_break,pa.ID_PRODOTTO_ACQUISTATO
        )proiezioni_prodotto
    where  pro_ven.ID_PRODOTTO_VENDITA = pa.ID_PRODOTTO_VENDITA
    and    brk_ven.ID_PRODOTTO_VENDITA = pro_ven.ID_PRODOTTO_VENDITA
    and    com.ID_BREAK_VENDITA = brk_ven.ID_BREAK_VENDITA
    and    com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
    and    brk_ven.ID_CIRCUITO_BREAK  = cir_bre.ID_CIRCUITO_BREAK
    and    cir_bre.ID_BREAK  = brk.ID_BREAK
    and    brk.ID_PROIEZIONE = pro.ID_PROIEZIONE
    and    com.FLG_ANNULLATO = 'N'
    and    com.FLG_SOSPESO = 'N'
    and    pa.FLG_ANNULLATO = 'N'
    and    pa.FLG_SOSPESO = 'N'
    and    pa.COD_DISATTIVAZIONE is null
    and    pa.STATO_DI_VENDITA = 'PRE'
    and    proiezioni_prodotto.ID_PRODOTTO_ACQUISTATO != pa.ID_PRODOTTO_ACQUISTATO
    and    proiezioni_prodotto.id_proiezione = pro.id_proiezione
    and    proiezioni_prodotto.id_tipo_break  = brk.ID_TIPO_BREAK;

    return v_numero_prodotti;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'FUNZIONE FU_GET_PRESENZA_TOP_SPOT: ERRORE '||SQLERRM);
END FU_GET_PRESENZA_TOP_SPOT;

FUNCTION FU_GET_LUOGO_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN CD_LUOGO.ID_LUOGO%TYPE IS
v_luogo_return CD_LUOGO.ID_LUOGO%TYPE;
BEGIN
    BEGIN
    SELECT CD_LUOGO.ID_LUOGO
    INTO v_luogo_return
     FROM CD_LUOGO, CD_LUOGO_TIPO_PUBB, CD_PRODOTTO_VENDITA, CD_PRODOTTO_PUBB, CD_PRODOTTO_ACQUISTATO
     WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
     AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
     AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
     AND CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB IS NULL
     AND CD_PRODOTTO_PUBB.COD_TIPO_PUBB = CD_LUOGO_TIPO_PUBB.COD_TIPO_PUBB
     AND CD_LUOGO.ID_LUOGO = CD_LUOGO_TIPO_PUBB.ID_LUOGO;
     EXCEPTION WHEN NO_DATA_FOUND THEN
        v_luogo_return := 6;
     END;
RETURN v_luogo_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_LUOGO_PROD_ACQ;

PROCEDURE PR_MODIFICA_SCHERMI_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2) IS
--
v_string_ambiti_prodotto   varchar2(32000);
v_id_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
   BEGIN
       BEGIN
       SELECT DISTINCT POSIZIONE_DI_RIGORE
       INTO v_id_posizione_rigore
       FROM CD_COMUNICATO
       WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
       AND FLG_ANNULLATO = 'N'
       AND FLG_SOSPESO = 'N'
       AND COD_DISATTIVAZIONE IS NULL;
       EXCEPTION
            WHEN OTHERS THEN
            NULL;
       END;
    FOR SC_PR IN (SELECT DISTINCT S.ID_SCHERMO
                  FROM CD_SCHERMO S, CD_COMUNICATO C
                  WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                  AND C.FLG_ANNULLATO = 'N'
                  AND C.FLG_SOSPESO = 'N'
                  AND C.COD_DISATTIVAZIONE IS NULL
                  AND C.ID_SALA = S.ID_SALA)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(SC_PR.ID_SCHERMO,5,'0')||'|';
    END LOOP;

   UPDATE CD_COMUNICATO
   SET FLG_ANNULLATO = 'S',
   POSIZIONE = NULL
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
   AND ID_SALA IN
   (SELECT ID_SALA FROM CD_SCHERMO SC
   WHERE instr ('|'||p_string_id_ambito||'|','|'||LPAD(SC.ID_SCHERMO,5,'0')||'|') < 1
   AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(SC.ID_SCHERMO,5,'0')||'|') >= 1);

            INSERT INTO CD_COMUNICATO (
              VERIFICATO,
              ID_PRODOTTO_ACQUISTATO,
              ID_BREAK_VENDITA,
              ID_CINEMA_VENDITA,
              ID_ATRIO_VENDITA,
              ID_SALA_VENDITA,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
--              DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE,
              ID_SALA,
              ID_BREAK)
              (
              SELECT 'N',
               p_id_prodotto_acquistato,
               ID_BREAK_VENDITA,NULL,NULL,NULL,
               CD_BREAK_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,v_id_posizione_rigore, CD_SCHERMO.ID_SALA, CD_BREAK.ID_BREAK
                FROM CD_BREAK_VENDITA, CD_CIRCUITO_BREAK, CD_SCHERMO, CD_PROIEZIONE, CD_BREAK, CD_FASCIA
                WHERE CD_CIRCUITO_BREAK.ID_CIRCUITO = p_id_circuito
                AND CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
                AND CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
                AND CD_BREAK_VENDITA.DATA_EROGAZIONE BETWEEN p_data_inizio AND p_data_fine
                AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
                AND CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
                AND CD_BREAK.FLG_ANNULLATO = 'N'
                AND CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
                AND CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
                AND CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                AND CD_FASCIA.ID_FASCIA = CD_PROIEZIONE.ID_FASCIA
                AND CD_SCHERMO.FLG_ANNULLATO = 'N'
                AND instr ('|'||p_string_id_ambito||'|','|'||LPAD(CD_SCHERMO.ID_SCHERMO,5,'0')||'|') >= 1
                AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(CD_SCHERMO.ID_SCHERMO,5,'0')||'|') < 1);

                IF p_stato_vendita = 'PRE' THEN
                    FOR C IN (SELECT ID_COMUNICATO
                              FROM CD_COMUNICATO
                              WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                              AND FLG_ANNULLATO = 'N'
                              AND FLG_SOSPESO = 'N'
                              AND COD_DISATTIVAZIONE IS NULL
                              AND POSIZIONE IS NULL
                              ) LOOP
                        PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,c.ID_COMUNICATO);
                    END LOOP;
                END IF;
END PR_MODIFICA_SCHERMI_PROD_ACQ;

PROCEDURE PR_MODIFICA_ATRII_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2) IS
--
v_string_ambiti_prodotto   varchar2(32000);
v_id_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
   BEGIN

    FOR ATRIO_PR IN (SELECT DISTINCT A.ID_ATRIO
                  FROM CD_ATRIO A, CD_CIRCUITO_ATRIO CA, CD_ATRIO_VENDITA AV, CD_COMUNICATO C
                  WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                  AND C.FLG_ANNULLATO = 'N'
                  AND C.FLG_SOSPESO = 'N'
                  AND C.COD_DISATTIVAZIONE IS NULL
                  AND AV.ID_ATRIO_VENDITA = C.ID_ATRIO_VENDITA
                  AND CA.ID_CIRCUITO_ATRIO = AV.ID_CIRCUITO_ATRIO
                  AND A.ID_ATRIO = CA.ID_ATRIO)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(ATRIO_PR.ID_ATRIO,5,'0')||'|';
    END LOOP;

   UPDATE CD_COMUNICATO C
   SET FLG_ANNULLATO = 'S'
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
   AND ID_ATRIO_VENDITA IN
   (
    SELECT ID_ATRIO_VENDITA
    FROM CD_ATRIO A, CD_CIRCUITO_ATRIO CA, CD_ATRIO_VENDITA AV
    WHERE AV.ID_ATRIO_VENDITA = C.ID_ATRIO_VENDITA
    AND CA.ID_CIRCUITO_ATRIO = AV.ID_CIRCUITO_ATRIO
    AND A.ID_ATRIO = CA.ID_ATRIO
    AND instr ('|'||p_string_id_ambito||'|','|'||LPAD(A.ID_ATRIO,5,'0')||'|') < 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(A.ID_ATRIO,5,'0')||'|') >= 1);

      INSERT INTO CD_COMUNICATO (
          VERIFICATO,
          ID_PRODOTTO_ACQUISTATO,
          ID_ATRIO_VENDITA,
          DATA_EROGAZIONE_PREV,
          FLG_ANNULLATO,
          ID_SOGGETTO_DI_PIANO)
          (SELECT 'N',
           p_id_prodotto_acquistato,
          ID_ATRIO_VENDITA,--0,0,
           CD_ATRIO_VENDITA.DATA_EROGAZIONE,'N',p_soggetto
            FROM CD_ATRIO, CD_ATRIO_VENDITA, CD_CIRCUITO_ATRIO
            WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO = 'N'
            AND CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
            AND CD_ATRIO_VENDITA.FLG_ANNULLATO = 'N'
            AND CD_ATRIO_VENDITA.DATA_EROGAZIONE between p_data_inizio and p_data_fine
            AND CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
            AND CD_ATRIO.ID_ATRIO = CD_CIRCUITO_ATRIO.ID_ATRIO
            AND CD_ATRIO.FLG_ANNULLATO = 'N'
            AND instr ('|'||p_string_id_ambito||'|','|'||LPAD(CD_ATRIO.ID_ATRIO,5,'0')||'|') >= 1
            AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(CD_ATRIO.ID_ATRIO,5,'0')||'|') < 1);
--
END PR_MODIFICA_ATRII_PROD_ACQ;

PROCEDURE PR_MODIFICA_SALE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2) IS
--
v_string_ambiti_prodotto   varchar2(32000);
v_id_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
   BEGIN

    FOR SALA_PR IN (SELECT DISTINCT A.ID_SALA
                  FROM CD_SALA A, CD_CIRCUITO_SALA CA, CD_SALA_VENDITA AV, CD_COMUNICATO C
                  WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                  AND C.FLG_ANNULLATO = 'N'
                  AND C.FLG_SOSPESO = 'N'
                  AND C.COD_DISATTIVAZIONE IS NULL
                  AND AV.ID_SALA_VENDITA = C.ID_SALA_VENDITA
                  AND CA.ID_CIRCUITO_SALA = AV.ID_CIRCUITO_SALA
                  AND A.ID_SALA = CA.ID_SALA)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(SALA_PR.ID_SALA,5,'0')||'|';
    END LOOP;

   UPDATE CD_COMUNICATO C
   SET FLG_ANNULLATO = 'S'
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
   AND ID_SALA_VENDITA IN
   (
    SELECT ID_SALA_VENDITA
    FROM CD_SALA S, CD_CIRCUITO_SALA CA, CD_SALA_VENDITA AV
    WHERE AV.ID_SALA_VENDITA = C.ID_SALA_VENDITA
    AND CA.ID_CIRCUITO_SALA = AV.ID_CIRCUITO_SALA
    AND S.ID_SALA = CA.ID_SALA
    AND instr ('|'||p_string_id_ambito||'|','|'||LPAD(S.ID_SALA,5,'0')||'|') < 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(S.ID_SALA,5,'0')||'|') >= 1);

      INSERT INTO CD_COMUNICATO (
          VERIFICATO,
          ID_PRODOTTO_ACQUISTATO,
          ID_SALA_VENDITA,
          DATA_EROGAZIONE_PREV,
          FLG_ANNULLATO,
          ID_SOGGETTO_DI_PIANO)
          (SELECT 'N',
           p_id_prodotto_acquistato,
          ID_SALA_VENDITA,--0,0,
           CD_SALA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto
            FROM CD_SALA, CD_SALA_VENDITA, CD_CIRCUITO_SALA
            WHERE CD_CIRCUITO_SALA.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_SALA.FLG_ANNULLATO = 'N'
            AND CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
            AND CD_SALA_VENDITA.FLG_ANNULLATO = 'N'
            AND CD_SALA_VENDITA.DATA_EROGAZIONE between p_data_inizio and p_data_fine
            AND CD_SALA_VENDITA.ID_CIRCUITO_SALA = CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
            AND CD_SALA.ID_SALA = CD_CIRCUITO_SALA.ID_SALA
            AND CD_SALA.FLG_ANNULLATO = 'N'
            AND instr ('|'||p_string_id_ambito||'|','|'||LPAD(CD_SALA.ID_SALA,5,'0')||'|') >= 1
            AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(CD_SALA.ID_SALA,5,'0')||'|') < 1);
--
END PR_MODIFICA_SALE_PROD_ACQ;

PROCEDURE PR_MODIFICA_CINEMA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                       p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
                                       p_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                       p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                       p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                       p_string_id_ambito        varchar2) IS
--
v_string_ambiti_prodotto   varchar2(32000);
v_id_posizione_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
   BEGIN

    FOR CINEMA_PR IN (SELECT DISTINCT CIN.ID_CINEMA
                  FROM CD_CINEMA CIN, CD_CIRCUITO_CINEMA CA, CD_CINEMA_VENDITA AV, CD_COMUNICATO C
                  WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                  AND C.FLG_ANNULLATO = 'N'
                  AND C.FLG_SOSPESO = 'N'
                  AND C.COD_DISATTIVAZIONE IS NULL
                  AND AV.ID_CINEMA_VENDITA = C.ID_CINEMA_VENDITA
                  AND CA.ID_CIRCUITO_CINEMA = AV.ID_CIRCUITO_CINEMA
                  AND CIN.ID_CINEMA = CA.ID_CINEMA)LOOP
        v_string_ambiti_prodotto := v_string_ambiti_prodotto||LPAD(CINEMA_PR.ID_CINEMA,5,'0')||'|';
    END LOOP;

   UPDATE CD_COMUNICATO C
   SET FLG_ANNULLATO = 'S'
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
   AND ID_CINEMA_VENDITA IN
   (
    SELECT ID_CINEMA_VENDITA
    FROM CD_CINEMA CIN, CD_CIRCUITO_CINEMA CA, CD_CINEMA_VENDITA AV
    WHERE AV.ID_CINEMA_VENDITA = C.ID_CINEMA_VENDITA
    AND CA.ID_CIRCUITO_CINEMA = AV.ID_CIRCUITO_CINEMA
    AND CIN.ID_CINEMA = CA.ID_CINEMA
    AND instr ('|'||p_string_id_ambito||'|','|'||LPAD(CIN.ID_CINEMA,5,'0')||'|') < 1
    AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(CIN.ID_CINEMA,5,'0')||'|') >= 1);

      INSERT INTO CD_COMUNICATO (
          VERIFICATO,
          ID_PRODOTTO_ACQUISTATO,
          ID_CINEMA_VENDITA,
          DATA_EROGAZIONE_PREV,
          FLG_ANNULLATO,
          ID_SOGGETTO_DI_PIANO)
          (SELECT 'N',
           p_id_prodotto_acquistato,
          ID_CINEMA_VENDITA,--0,0,
           CD_CINEMA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto
            FROM CD_CINEMA, CD_CINEMA_VENDITA, CD_CIRCUITO_CINEMA
            WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO = p_id_circuito
            AND CD_CIRCUITO_CINEMA.FLG_ANNULLATO = 'N'
            AND CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
            AND CD_CINEMA_VENDITA.FLG_ANNULLATO = 'N'
            AND CD_CINEMA_VENDITA.DATA_EROGAZIONE between p_data_inizio and p_data_fine
            AND CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
            AND CD_CINEMA.ID_CINEMA = CD_CIRCUITO_CINEMA.ID_CINEMA
            AND CD_CINEMA.FLG_ANNULLATO = 'N'
            AND instr ('|'||p_string_id_ambito||'|','|'||LPAD(CD_CINEMA.ID_CINEMA,5,'0')||'|') >= 1
            AND instr ('|'||v_string_ambiti_prodotto||'|','|'||LPAD(CD_CINEMA.ID_CINEMA,5,'0')||'|') < 1);
--
END PR_MODIFICA_CINEMA_PROD_ACQ;


--           Modifiche:
--           Mauro Viel Altran, Settembre 2011 eliminata la chiamata alla fu_get_num_ambienti
--           inserita la colonna numero_ambienti.


FUNCTION FU_GET_NOME_CINEMA_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2 IS
    --
    v_num_ambienti NUMBER;
    v_nome_cinema VARCHAR2(150);
    BEGIN
    select numero_ambienti 
    into  v_num_ambienti
    from  cd_prodotto_acquistato
    where id_prodotto_acquistato = p_id_prodotto_acquistato;
    --v_num_ambienti := FU_GET_NUM_AMBIENTI(p_id_prodotto_acquistato);
    IF v_num_ambienti > 1 THEN
        v_nome_cinema := '*';
    ELSE
        SELECT CIN.NOME_CINEMA || ' - ' || COM.COMUNE
        INTO v_nome_cinema
        FROM CD_CINEMA CIN, CD_COMUNE COM,
        (SELECT A.ID_CINEMA FROM CD_COMUNICATO C, CD_ATRIO_VENDITA AV,
        CD_CIRCUITO_ATRIO CA, CD_ATRIO A
        WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND C.FLG_ANNULLATO = 'N'
        AND C.FLG_SOSPESO = 'N'
        AND C.COD_DISATTIVAZIONE IS NULL
        AND ROWNUM = 1
        AND AV.ID_ATRIO_VENDITA = C.ID_ATRIO_VENDITA
        AND AV.FLG_ANNULLATO = 'N'
        AND CA.ID_CIRCUITO_ATRIO = AV.ID_CIRCUITO_ATRIO
        AND CA.FLG_ANNULLATO = 'N'
        AND A.ID_ATRIO = CA.ID_ATRIO
        AND A.FLG_ANNULLATO = 'N'
        UNION
        SELECT S.ID_CINEMA FROM CD_COMUNICATO C, CD_SALA_VENDITA SV,
        CD_CIRCUITO_SALA CS, CD_SALA S
        WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND C.FLG_ANNULLATO = 'N'
        AND C.FLG_SOSPESO = 'N'
        AND C.COD_DISATTIVAZIONE IS NULL
        AND ROWNUM = 1
        AND SV.ID_SALA_VENDITA = C.ID_SALA_VENDITA
        AND SV.FLG_ANNULLATO = 'N'
        AND CS.ID_CIRCUITO_SALA = SV.ID_CIRCUITO_SALA
        AND CS.FLG_ANNULLATO = 'N'
        AND S.ID_SALA = CS.ID_SALA
        AND S.FLG_ANNULLATO = 'N'
        UNION
        SELECT CC.ID_CINEMA FROM CD_COMUNICATO C, CD_CINEMA_VENDITA CV,
        CD_CIRCUITO_CINEMA CC
        WHERE C.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND C.FLG_ANNULLATO = 'N'
        AND C.FLG_SOSPESO = 'N'
        AND C.COD_DISATTIVAZIONE IS NULL
        AND ROWNUM = 1
        AND CV.ID_CINEMA_VENDITA = C.ID_CINEMA_VENDITA
        AND CV.FLG_ANNULLATO = 'N'
        AND CC.ID_CIRCUITO_CINEMA = CV.ID_CIRCUITO_CINEMA
        AND CC.FLG_ANNULLATO = 'N'
        ) AMB
        WHERE CIN.ID_CINEMA = AMB.ID_CINEMA
        AND COM.ID_COMUNE = CIN.ID_COMUNE;
    END IF;
    RETURN v_nome_cinema;
END FU_GET_NOME_CINEMA_PROD_ACQ;

PROCEDURE PR_MODIFICA_IMPORTI_MASSIVA(p_list_prodotti id_list_type,
                                      p_lordo_comm_tot CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
                                      p_lordo_dir_tot CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
                                      p_netto_comm_tot NUMBER,
                                      p_netto_dir_tot NUMBER,
                                      p_esito OUT NUMBER) IS
--
v_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
v_lordo_tot                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE := p_lordo_comm_tot + p_lordo_dir_tot;
v_netto_tot                 CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE := p_netto_comm_tot + p_netto_dir_tot;
v_lordo_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_coeff_ripartizione        NUMBER;
v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto                     CD_PRODOTTO_aCQUISTATO.IMP_NETTO%TYPE;
v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
v_id_importo_prodotto_c     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_importo_prodotto_d     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_stato_vendita             CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
v_id_formato                CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_tariffa_variabile         CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE;
v_lordo_saltato             CD_PRODOTTO_ACQUISTATO.IMP_LORDO_SALTATO%TYPE;
v_pos_rigore                CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_netto_orig                CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_lordo_comm_temp           CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE := 0;
v_lordo_dir_temp            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE := 0;
v_netto_comm_temp           CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE := 0;
v_netto_dir_temp            CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE := 0;
v_ind_maggiorazioni         NUMBER;
v_list_maggiorazioni        id_list_type;
 --
    BEGIN
    IF p_list_prodotti IS NOT NULL AND p_list_prodotti.COUNT > 0 THEN
       FOR i IN 1..p_list_prodotti.COUNT LOOP
            v_id_prodotto_acquistato := p_list_prodotti(i);
            SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, STATO_DI_VENDITA, ID_FORMATO, FLG_TARIFFA_VARIABILE, IMP_LORDO_SALTATO
            INTO v_lordo, v_netto, v_maggiorazione, v_sanatoria, v_recupero, v_tariffa, v_stato_vendita, v_id_formato, v_tariffa_variabile, v_lordo_saltato
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato;
            SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
            INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
            AND TIPO_CONTRATTO = 'C';
            SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM
            INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
            AND TIPO_CONTRATTO = 'D';
            --
            SELECT DISTINCT POSIZIONE_DI_RIGORE
            INTO v_pos_rigore
            FROM CD_COMUNICATO
            WHERE ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato;
            --
            v_lordo_comm := v_netto_comm + v_imp_sc_comm;
            v_lordo_dir := v_netto_dir + v_imp_sc_dir;
            v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm, v_imp_sc_comm);
            v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir, v_imp_sc_dir);
            v_netto_orig := v_netto_comm + v_netto_dir;
            IF i < p_list_prodotti.COUNT THEN

                --
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                v_coeff_ripartizione := (v_lordo_comm + v_lordo_dir) / v_lordo_tot;
                --dbms_output.PUT_LINE('v_lordo_tot: '||v_lordo_tot);
                v_lordo_com_prodotto := ROUND(p_lordo_comm_tot * v_coeff_ripartizione,2);
                --dbms_output.PUT_LINE('coeff: '||v_coeff_ripartizione);
                --dbms_output.PUT_LINE('v_lordo_com_prodotto: '||v_lordo_com_prodotto);

                IF v_lordo_com_prodotto != v_lordo_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_com_prodotto,'21',p_esito);
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                v_lordo_dir_prodotto := ROUND(p_lordo_dir_tot * v_coeff_ripartizione,2);
                IF v_lordo_dir_prodotto != v_lordo_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir_prodotto,'22',p_esito);
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                --dbms_output.PUT_LINE('v_lordo_comm: '||v_lordo_comm);
                --v_coeff_ripartizione := (v_netto_comm + v_netto_dir) / v_netto_tot;
                --(v_lordo_comm / v_netto_comm)
                IF p_netto_comm_tot = 0 THEN
                    v_coeff_ripartizione := 0;
                ELSE
                    IF v_netto_comm = 0 THEN
                        v_coeff_ripartizione := (p_netto_comm_tot / p_lordo_comm_tot) *(v_lordo_comm * v_perc_sc_comm / 100) / p_netto_comm_tot;
                    ELSE
                        v_coeff_ripartizione := (p_netto_comm_tot / p_lordo_comm_tot) * (v_netto_comm * (v_lordo_comm / v_netto_comm)) / p_netto_comm_tot;
                    END IF;
                END IF;
                --dbms_output.PUT_LINE('coeff: '||v_coeff_ripartizione);
                --dbms_output.PUT_LINE('v_netto_tot: '||v_netto_tot);
                v_netto_com_prodotto := ROUND(p_netto_comm_tot * v_coeff_ripartizione,2);
                --dbms_output.PUT_LINE('v_netto_com_prodotto: '||v_netto_com_prodotto);
                --
                IF v_netto_com_prodotto != v_netto_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_com_prodotto,'31',p_esito);
                END IF;

                --
                IF p_netto_dir_tot = 0 THEN
                    v_coeff_ripartizione := 0;
                ELSE
                    IF v_netto_dir = 0 THEN
                        v_coeff_ripartizione := (p_netto_dir_tot / p_lordo_dir_tot) * (v_lordo_dir * v_perc_sc_dir / 100) / p_netto_dir_tot;
                   ELSE
                        v_coeff_ripartizione := (p_netto_dir_tot / p_lordo_dir_tot) * (v_netto_dir * (v_lordo_dir / v_netto_dir)) / p_netto_dir_tot;
                    END IF;
                END IF;
                v_netto_dir_prodotto := ROUND(p_netto_dir_tot* v_coeff_ripartizione,2);
                --dbms_output.PUT_LINE('v_netto_dir_prodotto: '||v_netto_dir_prodotto);
                IF v_netto_dir_prodotto != v_netto_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_dir_prodotto,'32',p_esito);
                END IF;
                --
                v_lordo_comm_temp := v_lordo_comm_temp + v_lordo_comm;
                v_lordo_dir_temp := v_lordo_dir_temp + v_lordo_dir;
                v_netto_comm_temp := v_netto_comm_temp + v_netto_comm;
                v_netto_dir_temp := v_netto_dir_temp + v_netto_dir;
            ELSE
                --dbms_output.PUT_LINE('ultimo prodotto');
                v_lordo_com_prodotto := p_lordo_comm_tot - v_lordo_comm_temp;
                --dbms_output.PUT_LINE('v_lordo_com_prodotto: '||v_lordo_com_prodotto);
                IF v_lordo_com_prodotto != v_lordo_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_com_prodotto,'21',p_esito);
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --dbms_output.PUT_LINE('v_netto_com: '||v_netto_comm);
                v_lordo_dir_prodotto := p_lordo_dir_tot - v_lordo_dir_temp;
                --dbms_output.PUT_LINE('v_lordo_dir_prodotto: '||v_lordo_dir_prodotto);
                IF v_lordo_dir_prodotto != v_lordo_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir_prodotto,'22',p_esito);
                 --   dbms_output.PUT_LINE('v_lordo_com 1: '||v_lordo_comm);
                END IF;
                --
                v_netto_com_prodotto := p_netto_comm_tot - v_netto_comm_temp;
                --dbms_output.PUT_LINE('v_netto_com_prodotto: '||v_netto_com_prodotto);
                IF v_netto_com_prodotto != v_netto_comm THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_com_prodotto,'31',p_esito);
                END IF;
                --
                v_netto_dir_prodotto := p_netto_dir_tot - v_netto_dir_temp;
                --dbms_output.PUT_LINE('v_netto_dir_prodotto: '||v_netto_dir_prodotto);
                IF v_netto_dir_prodotto != v_netto_dir THEN
                    PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_netto_dir_prodotto,'32',p_esito);
                END IF;
            END IF;

            v_ind_maggiorazioni := 1;
            v_list_maggiorazioni := id_list_type();
            FOR MAG IN (SELECT * FROM CD_MAGG_PRODOTTO
                        WHERE ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato) LOOP
                v_list_maggiorazioni.EXTEND;
                v_list_maggiorazioni(v_ind_maggiorazioni) := MAG.ID_MAGGIORAZIONE;
                v_ind_maggiorazioni := v_ind_maggiorazioni +1;
            END LOOP;
            MODIFICA_PRODOTTO_ACQUISTATO(v_id_prodotto_acquistato,
                v_stato_vendita,
                v_tariffa,
                v_lordo,
                v_sanatoria,
                v_recupero,
                v_maggiorazione,
                v_netto_comm,
                v_imp_sc_comm,
                v_netto_dir,
                v_imp_sc_dir,
                v_pos_rigore,
                v_id_formato,
                v_tariffa_variabile,
                v_lordo_saltato,
                v_list_maggiorazioni);
    END LOOP;
   END IF;
END PR_MODIFICA_IMPORTI_MASSIVA;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_PROD_SALE_SALTATE
--
-- DESCRIZIONE:  Restituisce i prodotti che hanno avuto della sale saltate in un periodo
--
--
-- OPERAZIONI:
--
--  INPUT:
--          p_data_inizio           Data di inizio del periodo
--          p_data_fine             Data di fine del periodo
--          p_id_circuito_saltato   Circuito su cui cercare i prodotti saltati
--          p_id_circuito_recupero  Circuito su cui effettuare i recuperi
--  OUTPUT:
--          Lista di prodotti saltati
--
--
-- REALIZZATORE: Simone Bottani , Altran, Luglio 2010
--
--  MODIFICHE: Mauro Viel Altran Italia : Sostituita la chaimata alla proceura PA_PC_IMPORTI.FU_PERC_SC_COMM con PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA
--                                        in modo da ottenere il numero massimo di decimali per scongiurare problemi di arrotondamento.  --#MV01
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_PROD_SALE_SALTATE(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                  p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                  p_id_circuito_saltato CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_circuito_recupero CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN C_PRODOTTO_SALTATO IS
v_prodotti C_PRODOTTO_SALTATO;
BEGIN
    OPEN v_prodotti FOR
    SELECT ID_PRODOTTO_ACQUISTATO, ID_PIANO, ID_VER_PIANO,
    ID_CIRCUITO, NOME_CIRCUITO, ID_FORMATO, DURATA,
    ID_MISURA_PRD_VE, ID_UNITA,
    ID_CLIENTE, RAG_SOC_COGN, ID_TIPO_BREAK,
    DESC_TIPO_BREAK, ID_TIPO_CINEMA, POSIZIONE_DI_RIGORE,-- DESCRIZIONE, TITOLO,
    NUM_SALE_SALTATE, NUM_SALE_RECUPERATE,
    NETTO_COMM, NETTO_DIR,
    PERC_SCONTO_COMM,PERC_SCONTO_DIR
    FROM
    (
        SELECT PA.ID_PRODOTTO_ACQUISTATO,PIA.ID_PIANO, PIA.ID_VER_PIANO,
        CIR.ID_CIRCUITO, CIR.NOME_CIRCUITO, PA.ID_FORMATO, COEF.DURATA,
        PA.ID_MISURA_PRD_VE, MIS.ID_UNITA, PA.ID_TIPO_CINEMA,
        PIA.ID_CLIENTE, I.RAG_SOC_COGN, TB.ID_TIPO_BREAK, TB.DESC_TIPO_BREAK,
        --SOG.ID_SOGGETTO_DI_PIANO, SOG.DESCRIZIONE, MAT.ID_MATERIALE, MAT.TITOLO
        (SELECT COUNT(DISTINCT ID_SALA) FROM CD_COMUNICATO COM2
            WHERE COM2.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
            AND FLG_ANNULLATO = 'N'
            AND FLG_SOSPESO = 'N'
            AND COD_DISATTIVAZIONE IS NOT NULL
            AND ID_SALA NOT IN
            (
                SELECT DISTINCT ID_SALA FROM CD_COMUNICATO COM3
                WHERE COM3.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                AND FLG_ANNULLATO = 'N'
                AND FLG_SOSPESO = 'N'
                AND COD_DISATTIVAZIONE IS NULL
            )
         ) AS NUM_SALE_SALTATE,
         --FU_MAGGIORAZIONI_PRODOTTO(PA.ID_PRODOTTO_ACQUISTATO)  AS MAGGIORAZIONI,
        (SELECT IMP_NETTO
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                AND TIPO_CONTRATTO = 'C') AS NETTO_COMM,
        (SELECT IMP_NETTO
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                AND TIPO_CONTRATTO = 'D') AS NETTO_DIR,
        (SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(IMP_NETTO,IMP_SC_COMM) --#MV01
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                AND TIPO_CONTRATTO = 'C') AS PERC_SCONTO_COMM,
        (SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(IMP_NETTO,IMP_SC_COMM) --#MV01
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                AND TIPO_CONTRATTO = 'D') AS PERC_SCONTO_DIR,
        (SELECT COUNT(DISTINCT ID_SALA)
         FROM CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO PA1,CD_RECUPERO_PRODOTTO REC
         WHERE REC.ID_PRODOTTO_SALTATO = PA.ID_PRODOTTO_ACQUISTATO
         AND PA1.ID_PRODOTTO_ACQUISTATO = REC.ID_PRODOTTO_RECUPERO
         AND PA1.FLG_ANNULLATO = 'N'
         AND PA1.FLG_SOSPESO = 'N'
         AND PA1.COD_DISATTIVAZIONE IS NULL
         AND COM.ID_PRODOTTO_ACQUISTATO = PA1.ID_PRODOTTO_ACQUISTATO
         AND COM.FLG_ANNULLATO = 'N'
         AND COM.FLG_SOSPESO = 'N'
         AND COM.COD_DISATTIVAZIONE IS NULL) AS NUM_SALE_RECUPERATE,
         --0 AS NUM_SALE_RECUPERATE,
         (SELECT POSIZIONE_DI_RIGORE
         FROM CD_COMUNICATO COM
         WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
         AND COM.FLG_ANNULLATO = 'N'
         AND COM.FLG_SOSPESO = 'N'
         AND COM.COD_DISATTIVAZIONE IS NULL
         AND ROWNUM = 1) AS POSIZIONE_DI_RIGORE
        FROM --CD_MAGG_PRODOTTO MAG,
        CD_MISURA_PRD_VENDITA MIS,
        CD_TIPO_BREAK TB,
        CD_COEFF_CINEMA COEF,
        CD_FORMATO_ACQUISTABILE FORMATO, INTERL_U I, CD_PIANIFICAZIONE PIA,
        --CD_MATERIALE MAT, CD_MATERIALE_DI_PIANO MP, CD_SOGGETTO_DI_PIANO SOG,
        CD_CIRCUITO CIR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
        WHERE PA.DATA_INIZIO = p_data_inizio
        AND PA.DATA_FINE = p_data_fine
        AND PA.STATO_DI_VENDITA = 'PRE'
        AND PA.FLG_ANNULLATO = 'N'
        AND PA.FLG_SOSPESO = 'N'
        AND PA.ID_PRODOTTO_ACQUISTATO IN
        (
            SELECT DISTINCT COM.ID_PRODOTTO_ACQUISTATO
            FROM CD_COMUNICATO COM
            WHERE COM.ID_SALA IN
            (SELECT DISTINCT ID_SALA FROM CD_COMUNICATO COM2
            WHERE COM2.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
            AND FLG_ANNULLATO = 'N'
            AND FLG_SOSPESO = 'N'
            AND COD_DISATTIVAZIONE IS NOT NULL
            MINUS
            SELECT DISTINCT ID_SALA FROM CD_COMUNICATO COM3
            WHERE COM3.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
            AND FLG_ANNULLATO = 'N'
            AND FLG_SOSPESO = 'N'
            AND COD_DISATTIVAZIONE IS NULL
        )
        )
        AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
        AND TB.ID_TIPO_BREAK = PV.ID_TIPO_BREAK
        AND CIR.ID_CIRCUITO = PV.ID_CIRCUITO
      --  AND PV.ID_CIRCUITO = NVL(p_id_circuito_saltato, PV.ID_CIRCUITO)
        --AND SOG.ID_SOGGETTO_DI_PIANO = COM.ID_SOGGETTO_DI_PIANO
        --AND MP.ID_MATERIALE_DI_PIANO = COM.ID_MATERIALE_DI_PIANO
        --AND MAT.ID_MATERIALE = MP.ID_MATERIALE
        AND PIA.ID_PIANO = PA.ID_PIANO
        AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
        AND PIA.COD_CATEGORIA_PRODOTTO = 'TAB'
        AND PIA.FLG_ANNULLATO = 'N'
        AND PIA.FLG_SOSPESO = 'N'
        AND I.COD_INTERL = PIA.ID_CLIENTE
        AND FORMATO.ID_FORMATO = PA.ID_FORMATO
        AND COEF.ID_COEFF = FORMATO.ID_COEFF
        AND MIS.ID_MISURA_PRD_VE = PA.ID_MISURA_PRD_VE
    )
    WHERE NUM_SALE_SALTATE > NUM_SALE_RECUPERATE
    ORDER BY ID_PIANO, ID_TIPO_BREAK, ID_CIRCUITO;
        --, ID_SOGGETTO_DI_PIANO, DESCRIZIONE, ID_MATERIALE, TITOLO, MAGGIORAZIONI
RETURN v_prodotti;
END FU_GET_PROD_SALE_SALTATE;

FUNCTION FU_GET_PROD_SALE_RECUPERATE(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                  p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                  p_id_circuito_saltato CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                  p_id_circuito_recupero CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN C_PRODOTTO_SALTATO IS
v_prodotti C_PRODOTTO_SALTATO;
BEGIN
    OPEN v_prodotti FOR
    SELECT PA.ID_PRODOTTO_ACQUISTATO, PA.ID_PIANO, PA.ID_VER_PIANO,
    PV.ID_CIRCUITO, CIR.NOME_CIRCUITO, PA.ID_FORMATO, COEF.DURATA,
    PA.ID_MISURA_PRD_VE, MIS.ID_UNITA,
    PIA.ID_CLIENTE, CLIENTE.RAG_SOC_COGN, PV.ID_TIPO_BREAK,
    TB.DESC_TIPO_BREAK, PA.ID_TIPO_CINEMA,
    (SELECT POSIZIONE_DI_RIGORE
         FROM CD_COMUNICATO COM
         WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
         AND COM.FLG_ANNULLATO = 'N'
         AND COM.FLG_SOSPESO = 'N'
         AND COM.COD_DISATTIVAZIONE IS NULL
         AND ROWNUM = 1) AS POSIZIONE_DI_RIGORE,-- DESCRIZIONE, TITOLO,
    0 AS NUM_SALE_SALTATE,
    (SELECT COUNT(DISTINCT ID_SALA)
     FROM CD_COMUNICATO COM
     WHERE COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
     AND COM.FLG_ANNULLATO = 'N'
     AND COM.FLG_SOSPESO = 'N'
     AND COM.COD_DISATTIVAZIONE IS NULL) AS NUM_SALE_RECUPERATE,
     0 AS NETTO_COMM, 0 AS NETTO_DIR,
    (SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO,IMP_SC_COMM)
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
        AND TIPO_CONTRATTO = 'C') AS PERC_SCONTO_COMM,
    (SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO,IMP_SC_COMM)
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
        AND TIPO_CONTRATTO = 'D') AS PERC_SCONTO_DIR
    FROM CD_MISURA_PRD_VENDITA MIS, CD_COEFF_CINEMA COEF, CD_FORMATO_ACQUISTABILE F,
         CD_TIPO_BREAK TB, CD_CIRCUITO CIR, CD_PRODOTTO_VENDITA PV,
         INTERL_U CLIENTE, CD_PIANIFICAZIONE PIA, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.DATA_INIZIO = p_data_inizio
    AND PA.DATA_FINE = p_data_fine
    AND PA.COD_ATTIVAZIONE IS NOT NULL
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.COD_DISATTIVAZIONE IS NULL
    AND PIA.ID_PIANO = PA.ID_PIANO
    AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
    AND PIA.COD_CATEGORIA_PRODOTTO = 'TAB'
    AND CLIENTE.COD_INTERL = PIA.ID_CLIENTE
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
    AND CIR.ID_CIRCUITO = PV.ID_CIRCUITO
    AND TB.ID_TIPO_BREAK = PV.ID_TIPO_BREAK
    AND F.ID_FORMATO = PA.ID_FORMATO
    AND COEF.ID_COEFF = F.ID_COEFF
    AND MIS.ID_MISURA_PRD_VE = PA.ID_MISURA_PRD_VE;
RETURN v_prodotti;
END FU_GET_PROD_SALE_RECUPERATE;


FUNCTION FU_MAGGIORAZIONI_PRODOTTO(p_id_prodotto_acquistato CD_MAGG_PRODOTTO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2 IS
v_maggiorazioni VARCHAR2(255) := '';
BEGIN
    FOR MAG IN (SELECT * FROM CD_MAGG_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            ORDER BY ID_MAGGIORAZIONE) LOOP
        v_maggiorazioni := v_maggiorazioni || '-' || MAG.ID_MAGGIORAZIONE;
    END LOOP;
RETURN v_maggiorazioni;
END FU_MAGGIORAZIONI_PRODOTTO;

FUNCTION FU_CIRCUITI_RECUPERO(p_id_circuito CD_CIRCUITO_RECUPERO.ID_CIRCUITO_SALTATO%TYPE) RETURN VARCHAR2 IS
v_circuiti VARCHAR2(255) := '';
BEGIN
    FOR CIR IN (SELECT * FROM CD_CIRCUITO_RECUPERO
            WHERE ID_CIRCUITO_SALTATO = p_id_circuito
            ORDER BY PRIORITA) LOOP
        v_circuiti := v_circuiti || '-' || CIR.ID_CIRCUITO_RECUPERATO;
    END LOOP;
RETURN v_circuiti;
END FU_CIRCUITI_RECUPERO;

--Mauro Viel Altran Italia Luglio 2011 in serito il recupero delle sole 
--sale a diponibilita totale su tutto il periodo. In precedenza venivano 
--considerate idonee anche le sale con disponibilita parziale 
--Mauro Viel Altran Italia Luglio 2011 inserito il parametro 
--p_tipo_disponibilita_sala i cui voalori sono totale 'T' e
--parziele 'P' in questo modo puo essere scelta la modalita di recupero.

PROCEDURE PR_RECUPERA_SALE(p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                           p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                           p_id_circuito_saltato CD_CIRCUITO.ID_CIRCUITO%TYPE,
                           p_id_circuito_recupero CD_CIRCUITO.ID_CIRCUITO%TYPE,
                           p_tipo_disponibilita_sala varchar2) IS
--
v_prodotti_saltati C_PRODOTTO_SALTATO;
v_prodotto_rec R_PRODOTTO_SALTATO;
v_sale_da_recuperare NUMBER;
v_sale_recuperate NUMBER;
p_circuiti id_list_type := id_list_type();
v_circuito NUMBER;
v_sale_nuove id_list_type;
v_ind_sale NUMBER;
p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
p_esito NUMBER;
v_list_maggiorazioni id_list_type;
v_ind_maggiorazioni NUMBER;
BEGIN
    -- CURSOR v_prodotti_saltati IS
     v_prodotti_saltati := FU_GET_PROD_SALE_SALTATE(p_data_inizio,
                                     p_data_fine,
                                     p_id_circuito_saltato,
                                     p_id_circuito_recupero);
    -- INTO v_prodotti_saltati
     --FROM DUAL;
     LOOP
        FETCH v_prodotti_saltati INTO v_prodotto_rec;
        EXIT WHEN v_prodotti_saltati%NOTFOUND;
       -- FOR v_prodotto_rec IN v_prodotti_saltati
     -- Ciclo per recuperare i prodotti
         --IF v_prodotto_rec.a_id_piano = 563 THEN ----LEVARE  and   v_prodotto_rec.a_id_piano = 563
            v_sale_da_recuperare := v_prodotto_rec.a_num_sale_saltate - v_prodotto_rec.a_num_sale_recuperate;
            v_sale_recuperate := 0;
            v_list_maggiorazioni := id_list_type();
            v_ind_maggiorazioni := 1;
            --dbms_output.PUT_LINE('Id Prodotto: '||v_prodotto_rec.a_id_prodotto_acquistato);
            FOR MAG IN (SELECT * FROM CD_MAGG_PRODOTTO
                        WHERE ID_PRODOTTO_ACQUISTATO = v_prodotto_rec.a_id_prodotto_acquistato) LOOP
                v_list_maggiorazioni.EXTEND;
                v_list_maggiorazioni(v_ind_maggiorazioni) := MAG.ID_MAGGIORAZIONE;
                v_ind_maggiorazioni := v_ind_maggiorazioni +1;
            END LOOP;
            --
            FOR CIRCUITI IN (SELECT * FROM CD_CIRCUITO_RECUPERO
                         WHERE ID_CIRCUITO_SALTATO = v_prodotto_rec.a_id_circuito
                         ORDER BY PRIORITA
                )LOOP
               -- dbms_output.PUT_LINE('Id circuito recupero: '||CIRCUITI.ID_CIRCUITO_RECUPERATO);
                -- Chiamo funzione per recuperare le sale che hanno ancora disponibilita
                v_sale_nuove := id_list_type();
                v_ind_sale := 1;
                for sale in (select   id_sala, sum(disponibilita) as disponibilita  from (
                select id_sala, disponibilita from
                (
                select distinct com.id_sala, brk.tempo_proiezione - sum(coef.durata) as disponibilita
              --  into v_affollamento
                from
                    cd_prodotto_acquistato pa1, cd_formato_acquistabile fa,cd_coeff_cinema coef, cd_comunicato com,cd_break br,
                (select sum(br1.secondi_nominali) as tempo_proiezione, br1.id_proiezione--, cir_bre1.id_circuito_break --coef.durata, br1.ID_PROIEZIONE
                from
                cd_break br1,
                (
                select id_proiezione,secondi_nominali, ID_BREAK
                from
                (
                select distinct sc.id_sala, count(distinct pr.id_proiezione) over (partition by sc.id_sala) numvolte,br.id_proiezione,secondi_nominali, br.ID_BREAK
                                                from
                                                cd_break br,
                                                cd_break_vendita brkv,
                                                cd_circuito_break cir_bre,
                                                cd_schermo sc,
                                                cd_proiezione pr
                                                where   cir_bre.ID_CIRCUITO =CIRCUITI.ID_CIRCUITO_RECUPERATO
                                                and     cir_bre.FLG_ANNULLATO = 'N'
                                                and     brkv.id_circuito_break = cir_bre.id_circuito_break
                                                and     brkv.data_erogazione between p_data_inizio and p_data_fine
                                                and     pr.data_proiezione   between p_data_inizio and p_data_fine 
                                                and     brkv.FLG_ANNULLATO = 'N'
                                                and     br.id_break = cir_bre.id_break
                                                and     br.FLG_ANNULLATO = 'N'
                                                and     pr.ID_PROIEZIONE = br.ID_PROIEZIONE
                                                and     sc.ID_SCHERMO = pr.ID_SCHERMO
                                                and     pr.FLG_ANNULLATO = 'N'                                              
                ) 
                where numvolte = decode(p_tipo_disponibilita_sala,'T',(p_data_fine - p_data_inizio + 1)*2,'P',numvolte) --Scarto le sale che non sono disponibili per ogni giorno di vendita se il parametro p_tipo_disponibilita_sala ='T'                
                /*select distinct br.id_proiezione,secondi_nominali, br.ID_BREAK
                from
                cd_break br,
                cd_break_vendita brkv,
                cd_circuito_break cir_bre
                where   cir_bre.ID_CIRCUITO = CIRCUITI.ID_CIRCUITO_RECUPERATO
                and     cir_bre.FLG_ANNULLATO = 'N'
                and     brkv.id_circuito_break = cir_bre.id_circuito_break
                and     brkv.data_erogazione between p_data_inizio and p_data_fine
                and     brkv.FLG_ANNULLATO = 'N'
                and     br.id_break = cir_bre.id_break
                and     br.FLG_ANNULLATO = 'N'*/
                 )proiez
                where br1.ID_BREAK = proiez.ID_BREAK
                and   br1.FLG_ANNULLATO = 'N'
                --    La durata dei break di tipo frame screen e top spot non vanno
                --    sommati al tempo di proiezione
                and   br1.ID_TIPO_BREAK != 4
                and   br1.ID_TIPO_BREAK != 5
                group by br1.ID_PROIEZIONE
                ) brk
                where br.ID_PROIEZIONE = brk.id_proiezione
                and br.FLG_ANNULLATO = 'N'
                and com.id_break = br.id_break
                and com.FLG_ANNULLATO = 'N'
                and com.FLG_SOSPESO = 'N'
                and com.COD_DISATTIVAZIONE IS NULL
                and   pa1.id_prodotto_acquistato = com.id_prodotto_acquistato
                and   pa1.FLG_ANNULLATO = 'N'
                and   pa1.FLG_SOSPESO = 'N'
                and   pa1.COD_DISATTIVAZIONE IS NULL
                and   pa1.id_formato = fa.id_formato
                and   fa.id_coeff = coef.id_coeff
                and   pa1.stato_di_vendita = 'PRE'
                group by com.id_sala, br.id_proiezione,tempo_proiezione
                union 
                select id_sala, min(secondi_nominali) as disponibilita
                from
                (
                    select sum(br.SECONDI_NOMINALI) as secondi_nominali, pr.id_proiezione, sc.id_sala
                     from
                     cd_schermo sc,
                     cd_proiezione pr,
                     cd_break br,
                     cd_break_vendita brkv,
                     cd_circuito_break cir_bre
                     where   cir_bre.id_circuito = CIRCUITI.ID_CIRCUITO_RECUPERATO
                     and     cir_bre.FLG_ANNULLATO = 'N'
                     and     brkv.id_circuito_break = cir_bre.ID_CIRCUITO_BREAK
                     and     brkv.data_erogazione between p_data_inizio and p_data_fine
                     and     brkv.FLG_ANNULLATO = 'N'
                     and     br.id_break = cir_bre.id_break
                     and     br.FLG_ANNULLATO = 'N'
                     and     br.ID_TIPO_BREAK not in (4,5)
                     and     pr.ID_PROIEZIONE = br.ID_PROIEZIONE
                     and     sc.ID_SCHERMO = pr.ID_SCHERMO
                     and     sc.ID_SALA NOT IN
                     (select distinct id_sala from cd_comunicato
                     where data_erogazione_prev between p_data_inizio and p_data_fine
                     and flg_annullato = 'N'
                     and flg_sospeso = 'N'
                     and cod_disattivazione is null
                     and id_sala is not null
                     )
                     group by pr.id_proiezione, sc.id_sala
                     having sum(rownum) = decode(p_tipo_disponibilita_sala,'T',(p_data_fine - p_data_inizio + 1)*2,'P',sum(rownum)) --Scarto le sale che non sono disponibili per ogni giorno di vendita se il parametro p_tipo_disponibilita_sala ='T'
                     )
                group by id_sala
                )
                --Scarto le sale che non hanno disponibilita
                --o su cui e gia presente il cliente
                where disponibilita >= v_prodotto_rec.a_durata
                and ID_SALA NOT IN
                (
                    select distinct com3.id_sala
                    from cd_comunicato com3, cd_prodotto_acquistato pa3, cd_pianificazione pia
                    where pia.id_cliente = v_prodotto_rec.a_id_cliente
                    and pia.flg_annullato = 'N'
                    and pia.flg_sospeso = 'N'
                    and pa3.id_piano = pia.id_piano
                    and pa3.id_ver_piano = pia.id_ver_piano
                    and pa3.flg_annullato = 'N'
                    and pa3.flg_sospeso = 'N'
                    and pa3.cod_disattivazione is null
                    and pa3.STATO_DI_VENDITA = 'PRE'
                    and com3.id_prodotto_acquistato = pa3.id_prodotto_acquistato
                    and com3.flg_annullato = 'N'
                    and com3.flg_sospeso = 'N'
                    and com3.cod_disattivazione is null
                    and com3.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
                    and com3.ID_SALA IS NOT NULL
                )
                and (v_prodotto_rec.a_id_tipo_break not in(4,5)
                    or ID_SALA NOT IN
                    (
                    select distinct com4.id_sala
                    from cd_comunicato com4, cd_prodotto_acquistato pa4, cd_prodotto_vendita pv
                    where pa4.flg_annullato = 'N'
                    and pa4.flg_sospeso = 'N'
                    and pa4.cod_disattivazione is null
                    and pa4.STATO_DI_VENDITA = 'PRE'
                    and com4.id_prodotto_acquistato = pa4.id_prodotto_acquistato
                    and com4.flg_annullato = 'N'
                    and com4.flg_sospeso = 'N'
                    and com4.cod_disattivazione is null
                    and com4.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
                    and com4.ID_SALA IS NOT NULL
                    and pv.ID_PRODOTTO_VENDITA = pa4.ID_PRODOTTO_VENDITA
                    and pv.ID_TIPO_BREAK = v_prodotto_rec.a_id_tipo_break
                    )
                )
                order by disponibilita desc
                )
                where rownum <= v_sale_da_recuperare
                group by id_sala
                )-------------------------->

                loop
                   v_sale_nuove.EXTEND;

                 v_sale_nuove(v_ind_sale) := sale.ID_SALA;
                    v_ind_sale := v_ind_sale +1;
                   -- dbms_output.PUT_LINE('Sala per il recupero: '|| sale.ID_SALA ||','|| sale.disponibilita);
                END LOOP;
                IF v_sale_nuove.COUNT > 0   THEN

                    --dbms_output.PUT_LINE('v_sale_nuove: '|| v_sale_nuove.count);
                    PR_RECUPERA_SALE_PRODOTTO(v_prodotto_rec.a_id_prodotto_acquistato,
                                    v_prodotto_rec.a_id_piano,
                                    v_prodotto_rec.a_id_ver_piano,
                                    p_data_inizio,
                                    p_data_fine,
                                    CIRCUITI.ID_CIRCUITO_RECUPERATO,
                                    v_prodotto_rec.a_id_tipo_break,
                                    v_prodotto_rec.a_id_formato,
                                    v_prodotto_rec.a_id_misura,
                                    v_prodotto_rec.a_id_tipo_cinema,
                                    v_prodotto_rec.a_posizione_rigore,
                                    v_prodotto_rec.a_netto_comm,
                                    v_prodotto_rec.a_netto_dir,
                                    v_prodotto_rec.a_perc_sconto_comm,
                                    v_prodotto_rec.a_perc_sconto_dir,
                                    v_sale_nuove,
                                    v_list_maggiorazioni,
                                    p_id_prodotto_acquistato,
                                    p_esito);
                    --
                    v_sale_recuperate := v_sale_recuperate + v_sale_nuove.COUNT;
                    IF v_sale_recuperate = v_sale_da_recuperare THEN
                        EXIT;
                    ELSE
                      v_sale_da_recuperare := v_sale_da_recuperare - v_sale_recuperate;
                    END IF;
                END IF;
            END LOOP;
           -- END IF;
        END LOOP;
     CLOSE v_prodotti_saltati;
END PR_RECUPERA_SALE;


PROCEDURE PR_RECUPERA_SALE_PRODOTTO(p_id_prodotto_originale CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                    p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                    p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                    p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                    p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_tipo_break CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                    p_id_misura_prd_ve CD_PRODOTTO_ACQUISTATO.ID_MISURA_PRD_VE%TYPE,
                                    p_id_tipo_cinema CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
                                    p_posizione_di_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                                    p_netto_comm NUMBER,
                                    p_netto_dir NUMBER,
                                    p_perc_sc_comm NUMBER,
                                    p_perc_sc_dir NUMBER,
                                    p_sale id_list_type,
                                    p_list_maggiorazioni id_list_type,
                                    p_id_prodotto_acquistato OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_esito OUT NUMBER) IS
--
--v_num_sale NUMBER;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE;
v_id_listino CD_TARIFFA.ID_LISTINO%TYPE;
v_id_misura CD_TARIFFA.ID_MISURA_PRD_VE%TYPE;
v_id_unita_temp CD_MISURA_PRD_VENDITA.ID_UNITA%TYPE;
v_sconto_stagionale CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
v_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_maggiorazione CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE := 0;
v_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_tariffa_originale CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_imp_sc_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;

BEGIN


    --v_num_sale := p_sale.COUNT;

    --dbms_output.PUT_LINE('p_id_tipo_break: '||p_id_tipo_break);
    for c in (
    SELECT TAR.ID_TARIFFA, PV.ID_PRODOTTO_VENDITA, TAR.ID_LISTINO, MIS.ID_UNITA
    --INTO v_id_tariffa, v_id_prodotto_vendita, v_id_listino, v_id_unita_temp
    FROM CD_MISURA_PRD_VENDITA MIS, CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV
    WHERE PV.ID_CIRCUITO = p_id_circuito
    AND PV.ID_TIPO_BREAK = p_id_tipo_break
    AND PV.FLG_ANNULLATO = 'N'
    AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
    AND TAR.DATA_INIZIO <= p_data_inizio
    AND TAR.DATA_FINE >= p_data_fine
    AND TAR.ID_MISURA_PRD_VE = p_id_misura_prd_ve
    AND MIS.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE
    AND PV.FLG_DEFINITO_A_LISTINO = 'N'
    )
    loop

        v_id_tariffa:= c.id_tariffa;
        v_id_prodotto_vendita:= c.id_prodotto_vendita;
        v_id_listino := c.id_listino;
        v_id_unita_temp := c.id_unita;
        v_sconto_stagionale := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_SCONTO_STAGIONALE(v_id_prodotto_vendita, p_data_inizio, p_data_fine, p_id_formato, p_id_misura_prd_ve);
        --dbms_output.put_line('v_sconto_stagionale: '||v_sconto_stagionale);
       -- dbms_output.put_line('v_id_tariffa: '||v_id_tariffa);
        --dbms_output.put_line('v_sconto_stagionale: '||v_sconto_stagionale);
        v_tariffa := PA_CD_UTILITY.FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(v_id_tariffa, p_id_formato),v_sconto_stagionale);
        --dbms_output.put_line('v_tariffo: '||v_tariffa);


        SELECT IMP_TARIFFA
        INTO v_tariffa_originale
        FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale;
        v_tariffa_originale := v_tariffa_originale / FU_GET_NUM_AMBIENTI(p_id_prodotto_originale);
    --
        --dbms_output.put_line('v_tariffa_originale: '||v_tariffa_originale);
        --dbms_output.put_line('v_tariffa: '||v_tariffa);
        IF v_tariffa = v_tariffa_originale THEN
            --RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_RECUPERA_SALE_PRODOTTO: RECUPERO PRODOTTO NON ESEGUITO PERCHE'' LE TARIFFE SONO DIFFERENTI '||SQLERRM);
            v_tariffa := v_tariffa_originale;
            exit;
        end if;

     end loop;

      IF v_tariffa != v_tariffa_originale THEN
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_RECUPERA_SALE_PRODOTTO: RECUPERO PRODOTTO NON ESEGUITO PERCHE'' LE TARIFFE SONO DIFFERENTI '||SQLERRM);
      else
           v_tariffa := v_tariffa * p_sale.COUNT;
           FOR MAGG IN (SELECT MAG.PERCENTUALE_VARIAZIONE FROM CD_MAGGIORAZIONE MAG, CD_MAGG_PRODOTTO MP
                         WHERE MP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
                         AND MAG.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE) LOOP
                --
                v_maggiorazione := ROUND(v_maggiorazione + (v_tariffa * MAGG.PERCENTUALE_VARIAZIONE / 100),2);
            END LOOP;
           -- dbms_output.put_line('p_sale.COUNT: '||p_sale.COUNT || 'tariffa :'|| v_tariffa);

             -- dbms_output.put_line('p_sale.COUNT: '||p_sale.COUNT || 'tariffa :'|| v_tariffa);
            v_lordo := v_tariffa + v_maggiorazione;
            
            v_imp_sc_comm := PA_PC_IMPORTI.FU_SCONTO_COMM_3(v_lordo,p_perc_sc_comm); 
  
            PR_CREA_PROD_ACQ_LIBERA (
            v_id_prodotto_vendita,
            p_id_piano,
            p_id_ver_piano,
            p_sale,
            1,
            p_data_inizio,
            p_data_fine,
            p_id_formato,
            v_tariffa,
            v_lordo,-- lordo
            v_lordo,-- lordo comm
            0,        --lordo dir
            v_imp_sc_comm,
            0, -- perc sc dir
            v_maggiorazione,
            v_id_unita_temp,
            v_id_listino,
            p_sale.COUNT,
            p_posizione_di_rigore,
            'S',
            p_list_maggiorazioni,
            p_id_tipo_cinema,
            'R',
            p_id_prodotto_acquistato,
            p_esito);
            --
            PR_CORREGGI_IMPORTI_RECUPERO2(p_id_prodotto_originale,p_id_prodotto_acquistato, p_list_maggiorazioni);
      END IF;
END PR_RECUPERA_SALE_PRODOTTO;

PROCEDURE PR_CORREGGI_IMPORTI_RECUPERO(p_id_prodotto_originale CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_id_prodotto_recupero CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_list_maggiorazioni id_list_type) IS
--
--v_lordo_tot                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE := p_lordo_comm_tot + p_lordo_dir_tot;
--v_netto_tot                 CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE := p_netto_comm_tot + p_netto_dir_tot;
v_lordo_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_coeff_ripartizione        NUMBER;
v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto                     CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
v_id_importo_prodotto_c     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_importo_prodotto_d     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_saltato             CD_PRODOTTO_ACQUISTATO.IMP_LORDO_SALTATO%TYPE;
p_esito NUMBER;
v_pos_rigore                CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_id_formato                CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_tariffa_variabile         CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE;
v_lordo_dir_orig            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_dir_orig          NUMBER;
BEGIN

   SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, IMP_LORDO_SALTATO, ID_FORMATO, FLG_TARIFFA_VARIABILE
    INTO v_lordo, v_netto, v_maggiorazione, v_sanatoria, v_recupero, v_tariffa, v_lordo_saltato, v_id_formato, v_tariffa_variabile
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero;
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
    INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm, v_lordo_comm
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
    AND TIPO_CONTRATTO = 'C';
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
    INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir, v_lordo_dir
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
    AND TIPO_CONTRATTO = 'D';
    v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm,v_imp_sc_comm);
    v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir,v_imp_sc_dir);

    SELECT IMP_NETTO + IMP_SC_COMM, PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO,IMP_SC_COMM)
    INTO v_lordo_dir_orig, v_perc_sc_dir_orig
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
    AND TIPO_CONTRATTO = 'D';
    v_lordo_dir_orig := v_lordo_dir_orig / FU_GET_NUM_AMBIENTI(p_id_prodotto_originale) * FU_GET_NUM_AMBIENTI(p_id_prodotto_recupero);
    v_lordo_dir_orig := ROUND(v_lordo_dir_orig,2);
       SELECT DISTINCT POSIZIONE_DI_RIGORE
            INTO v_pos_rigore
            FROM CD_COMUNICATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale;
    --
    /*dbms_output.PUT_LINE('v_lordo_dir_orig: '||v_lordo_dir_orig);
    dbms_output.PUT_LINE('v_tariffa: '||v_tariffa);
    dbms_output.PUT_LINE('v_maggiorazione: '||v_maggiorazione);
    dbms_output.PUT_LINE('v_lordo: '||v_lordo);
    dbms_output.PUT_LINE('v_lordo_comm: '||v_lordo_comm);
    dbms_output.PUT_LINE('v_lordo_dir: '||v_lordo_dir);
    dbms_output.PUT_LINE('v_netto_comm: '||v_netto_comm);
    dbms_output.PUT_LINE('v_netto_dir: '||v_netto_dir);
    dbms_output.PUT_LINE('v_perc_sc_comm: '||v_perc_sc_comm);
    dbms_output.PUT_LINE('v_perc_sc_dir: '||v_perc_sc_dir);
    dbms_output.PUT_LINE('v_imp_sc_comm: '||v_imp_sc_comm);
    dbms_output.PUT_LINE('v_imp_sc_dir: '||v_imp_sc_dir);
    dbms_output.PUT_LINE('v_sanatoria: '||v_sanatoria);
    dbms_output.PUT_LINE('v_recupero: '||v_recupero);
    */
    IF v_lordo_dir_orig != v_lordo_dir THEN
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                            v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                            v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                            v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir_orig,'22',p_esito);
    END IF;
    --
    /*PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                    v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                    v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                    v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir,'22',p_esito);*/
    --
    /*PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_perc_sc_comm,'41',p_esito);
                        */
    --
    IF v_perc_sc_dir_orig != v_perc_sc_dir THEN
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_perc_sc_dir_orig,'42',p_esito);
    END IF;
    MODIFICA_PRODOTTO_ACQUISTATO(p_id_prodotto_recupero,
                'OPZ',
                v_tariffa,
                v_lordo,
                v_sanatoria,
                v_recupero,
                v_maggiorazione,
                v_netto_comm,
                v_imp_sc_comm,
                v_netto_dir,
                v_imp_sc_dir,
                v_pos_rigore,
                v_id_formato,
                v_tariffa_variabile,
                v_lordo_saltato,
                p_list_maggiorazioni);

     PR_MODIFICA_STATO_VENDITA(p_id_prodotto_recupero,'ACO');
     PR_MODIFICA_STATO_VENDITA(p_id_prodotto_recupero,'PRE');
    --
END PR_CORREGGI_IMPORTI_RECUPERO;

-------------------Modifiche Mauro Viel Altran Ottobre 2011: sostituita la chiamata  PA_CD_IMPORTI.MODIFICA_IMPORTI
------------------con codice 52 in modo da poter utilizzare la percentuele di sconto con piu di 2 decimali in modo da eliminare
------------------problemi di arrotondamento.
------------------Mauro Viel Altran Novembre 2011 inserita la chiamata alla procedura pa_pc_importi.FU_LORDO_COMM  
------------------perche il recupero manuale a fronte di tarifffe diverse sposta l'eccesso sul recupero. La procedura di recupero sale  utilizza
------------------tariffe a schermo uguali fra salto e recupero e quindi l'importo recupero non era mai valorizzato. #MV01 

PROCEDURE PR_CORREGGI_IMPORTI_RECUPERO2(p_id_prodotto_originale CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_id_prodotto_recupero CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_list_maggiorazioni id_list_type) IS
--
--v_lordo_tot                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE := p_lordo_comm_tot + p_lordo_dir_tot;
--v_netto_tot                 CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE := p_netto_comm_tot + p_netto_dir_tot;
v_lordo_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_coeff_ripartizione        NUMBER;
v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto                     CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
v_id_importo_prodotto_c     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_importo_prodotto_d     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_saltato             CD_PRODOTTO_ACQUISTATO.IMP_LORDO_SALTATO%TYPE;
v_lordo_saltato_comm        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
v_lordo_saltato_dir         CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
p_esito NUMBER;
v_pos_rigore                CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_id_formato                CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_tariffa_variabile         CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE;
v_lordo_dir_orig            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm_orig         NUMBER;
v_perc_sc_dir_orig          NUMBER;
--v_recuperato                NUMBER;
v_imp_sc_dir_new            number;
BEGIN

   SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, ID_FORMATO, FLG_TARIFFA_VARIABILE, IMP_LORDO_SALTATO
    INTO v_lordo, v_netto, v_maggiorazione, v_sanatoria, v_recupero, v_tariffa,  v_id_formato, v_tariffa_variabile, v_lordo_saltato
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero;
    --#MV01
    v_lordo := pa_pc_importi.FU_LORDO_COMM(v_lordo,v_sanatoria,v_recupero);
    --
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
    INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm, v_lordo_comm
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
    AND TIPO_CONTRATTO = 'C';
    --
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
    INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir, v_lordo_dir
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
    AND TIPO_CONTRATTO = 'D';
    --v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm,v_imp_sc_comm);
    --v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir,v_imp_sc_dir);

    SELECT IMP_LORDO_SALTATO, PERC_SC_ORIG
    INTO v_lordo_saltato_comm, v_perc_sc_comm_orig
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
    AND TIPO_CONTRATTO = 'C';

    SELECT IMP_NETTO + IMP_SC_COMM, IMP_LORDO_SALTATO, PERC_SC_ORIG
    INTO v_lordo_dir_orig, v_lordo_saltato_dir, v_perc_sc_dir_orig
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
    AND TIPO_CONTRATTO = 'D';
    
    
    v_lordo_saltato_dir := LEAST(v_lordo_saltato_dir, v_lordo);
    --v_lordo_dir_orig := v_lordo_dir_orig / FU_GET_NUM_AMBIENTI(p_id_prodotto_originale) * FU_GET_NUM_AMBIENTI(p_id_prodotto_recupero);
    --v_lordo_dir_orig := ROUND(v_lordo_dir_orig,2);
       SELECT DISTINCT POSIZIONE_DI_RIGORE
            INTO v_pos_rigore
            FROM CD_COMUNICATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale;
    --
    /*dbms_output.PUT_LINE('v_lordo_dir_orig: '||v_lordo_dir_orig);
    dbms_output.PUT_LINE('v_tariffa: '||v_tariffa);
    dbms_output.PUT_LINE('v_maggiorazione: '||v_maggiorazione);
    dbms_output.PUT_LINE('v_lordo: '||v_lordo);
    dbms_output.PUT_LINE('v_lordo_comm: '||v_lordo_comm);
    dbms_output.PUT_LINE('v_lordo_dir: '||v_lordo_dir);
    dbms_output.PUT_LINE('v_netto_comm: '||v_netto_comm);
    dbms_output.PUT_LINE('v_netto_dir: '||v_netto_dir);
    dbms_output.PUT_LINE('v_perc_sc_comm: '||v_perc_sc_comm);
    dbms_output.PUT_LINE('v_perc_sc_dir: '||v_perc_sc_dir);
    dbms_output.PUT_LINE('v_imp_sc_comm: '||v_imp_sc_comm);
    dbms_output.PUT_LINE('v_imp_sc_dir: '||v_imp_sc_dir);
    dbms_output.PUT_LINE('v_sanatoria: '||v_sanatoria);
    dbms_output.PUT_LINE('v_recupero: '||v_recupero);
    */
    --dbms_output.PUT_LINE('v_lordo_saltato_dir: '||v_lordo_saltato_dir);
    IF v_lordo_saltato_dir > 0 THEN
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                            v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                            v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                            v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_saltato_dir,'22',p_esito);

        IF v_perc_sc_dir_orig != v_perc_sc_dir THEN
        
        --MV#01 Inizio 
        /*PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_perc_sc_dir_orig,'42',p_esito);*/
                        
            v_imp_sc_dir_new := PA_PC_IMPORTI.FU_SCONTO_COMM_3(v_lordo,v_perc_sc_dir_orig);
       
            PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_imp_sc_dir_new,'52',p_esito);                        
        --MV#01 Fine                
                
                        
        END IF;

    END IF;
    --
    /*PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                    v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                    v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                    v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir,'22',p_esito);*/
                 
    IF v_perc_sc_comm_orig != v_perc_sc_comm THEN
    
        
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_perc_sc_comm_orig,'41',p_esito);   
      
    --
    END IF;
    MODIFICA_PRODOTTO_ACQUISTATO(p_id_prodotto_recupero,
                'OPZ',
                v_tariffa,
                v_lordo,
                v_sanatoria,
                v_recupero,
                v_maggiorazione,
                v_netto_comm,
                v_imp_sc_comm,
                v_netto_dir,
                v_imp_sc_dir,
                v_pos_rigore,
                v_id_formato,
                v_tariffa_variabile,
                v_lordo_saltato,
                p_list_maggiorazioni);

     PR_MODIFICA_STATO_VENDITA(p_id_prodotto_recupero,'ACO');
     PR_MODIFICA_STATO_VENDITA(p_id_prodotto_recupero,'PRE');
     --
     INSERT INTO CD_RECUPERO_PRODOTTO(ID_PRODOTTO_SALTATO, ID_PRODOTTO_RECUPERO,
     DATA_RECUPERO, TIPO_CONTRATTO,QUOTA_PARTE)
     VALUES(p_id_prodotto_originale,p_id_prodotto_recupero, sysdate, 'C', v_lordo_comm);
     INSERT INTO CD_RECUPERO_PRODOTTO(ID_PRODOTTO_SALTATO, ID_PRODOTTO_RECUPERO,
     DATA_RECUPERO, TIPO_CONTRATTO, QUOTA_PARTE)
     VALUES(p_id_prodotto_originale,p_id_prodotto_recupero, sysdate, 'D',v_lordo_dir);
     
     
     --
     
     UPDATE CD_IMPORTI_PRODOTTO
     SET IMP_LORDO_SALTATO = IMP_LORDO_SALTATO - v_lordo_comm
     WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
     AND TIPO_CONTRATTO = 'C';
     UPDATE CD_IMPORTI_PRODOTTO
     SET IMP_LORDO_SALTATO = IMP_LORDO_SALTATO - v_lordo_dir
     WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
     AND TIPO_CONTRATTO = 'D';
    --
END PR_CORREGGI_IMPORTI_RECUPERO2;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_NUM_MEDIO_SCHERMI
--
-- DESCRIZIONE:  Restituisce il numero medio di schermi nella settimana per il calcolo della tariffa
--
-- INPUT:  p_id_prodotto_acquistato: Id del prodotto acquistato
--
-- OUTPUT:
--
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE: Mauro Viel, Altran, Dicembre 2010: inserita la durata effettiva del prodotto: prima era 7 gg.
--                                                nel listino 2010/2011 alcuni prodotti target hanno durata 6 giorni. oppure un giorno.
--             Mauro Viel Altran Italia Aprile 2011 inserito il numero massimo di schermi.
--             Mauro Viel Altran Italia Maggio 2011 inserita la gestione del v_flg_ricalcolo_tariffa. 
--                               La procedura esporra gli schermi virtuali visibili del circuito fino al ricalcolo della tariffa. 
--                               Dopo esporra il numero di schermi medi del prodotto. 
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_NUM_SCHERMI_TARGET(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE, p_sale_reali VARCHAR2) RETURN NUMBER IS
v_num_schermi NUMBER;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine   CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_schermi_virtuali NUMBER;
v_sale_reali VARCHAR2(1);
v_numero_massimo_schermi cd_prodotto_acquistato.numero_massimo_schermi%type;
v_flg_ricalcolo_tariffa cd_prodotto_acquistato.flg_ricalcolo_tariffa%type;
v_id_prodotto_vendita cd_prodotto_acquistato.id_prodotto_vendita%type;
BEGIN
     select  numero_massimo_schermi
     into    v_numero_massimo_schermi
     from cd_prodotto_Acquistato
     where id_prodotto_acquistato =  p_id_prodotto_acquistato;
     
     v_sale_reali := p_sale_reali;
     ----------------------------
     IF v_sale_reali = 'N' THEN
        
        select data_inizio,data_fine,flg_ricalcolo_tariffa,id_prodotto_vendita
        into   v_data_inizio,v_data_fine,v_flg_ricalcolo_tariffa,v_id_prodotto_vendita
        from   cd_prodotto_acquistato pa
        where  id_prodotto_acquistato = p_id_prodotto_acquistato;
        
        
        IF v_flg_ricalcolo_tariffa = 'S' THEN
            v_sale_reali := 'S';
        ELSE
        --
            if v_numero_massimo_schermi is null then
                /*SELECT COUNT(DISTINCT S.ID_SALA)
                INTO v_num_schermi
                FROM CD_SALA S, CD_COMUNICATO COM
                WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND COM.FLG_ANNULLATO = 'N'
                AND COM.FLG_SOSPESO = 'N'
                AND COM.COD_DISATTIVAZIONE IS NULL
                AND S.ID_SALA = COM.ID_SALA
                AND S.FLG_VISIBILE = 'S';*/
                
       
                SELECT COUNT(DISTINCT(SC.ID_SCHERMO))
                INTO v_num_schermi
                FROM  CD_CINEMA CIN, CD_SALA S, CD_SCHERMO SC, CD_PRODOTTO_VENDITA P_VEN, CD_PROIEZIONE PR, CD_BREAK_VENDITA BRK_V, CD_BREAK BRK, CD_CIRCUITO_BREAK C_BRK
                WHERE BRK_V.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                AND BRK_V.DATA_EROGAZIONE BETWEEN v_data_inizio AND v_data_fine
                AND BRK_V.FLG_ANNULLATO = 'N'
                AND c_brk.ID_CIRCUITO_BREAK = BRK_V.ID_CIRCUITO_BREAK
                AND c_brk.FLG_ANNULLATO='N'
                AND brk.ID_BREAK = c_brk.ID_BREAK
                and brk.FLG_ANNULLATO = 'N'
                AND PR.ID_PROIEZIONE = BRK.ID_PROIEZIONE
                AND PR.FLG_ANNULLATO = 'N'
                AND P_VEN.ID_PRODOTTO_VENDITA = BRK_V.ID_PRODOTTO_VENDITA
                AND P_VEN.FLG_ANNULLATO = 'N'
                AND sc.id_schermo = pr.ID_SCHERMO
                AND sc.FLG_ANNULLATO = 'N'
                AND s.ID_SALA = sc.ID_SALA
                AND s.FLG_ANNULLATO = 'N'
                AND s.FLG_VISIBILE = 'S'
                AND CIN.ID_CINEMA = S.ID_CINEMA
                AND CIN.FLG_ANNULLATO = 'N'
                AND (P_VEN.ID_TARGET IS NULL OR CIN.FLG_VIRTUALE = 'S')
                AND (P_VEN.FLG_SEGUI_IL_FILM ='N' OR CIN.FLG_VIRTUALE = 'S');
            else
                v_num_schermi:=v_numero_massimo_schermi;
            end if;
        END IF;
        
     END IF;     
     
     
     v_numero_massimo_schermi := nvl(v_numero_massimo_schermi,80);
     
     ----------------------------
     /*IF v_sale_reali = 'N' THEN
        SELECT COUNT(1)
        INTO v_schermi_virtuali
        FROM CD_SCHERMO_VIRTUALE_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
        IF v_schermi_virtuali > 0 THEN
            v_sale_reali := 'S';
        ELSE
        
        --
            SELECT COUNT(DISTINCT S.ID_SALA)
            INTO v_num_schermi
            FROM CD_SALA S, CD_COMUNICATO COM
            WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND COM.FLG_ANNULLATO = 'N'
            AND COM.FLG_SOSPESO = 'N'
            AND COM.COD_DISATTIVAZIONE IS NULL
            AND S.ID_SALA = COM.ID_SALA
            AND S.FLG_VISIBILE = 'S';
        END IF;
        
     END IF;*/
     IF v_sale_reali = 'S' THEN
        /*SELECT DATA_INIZIO,DATA_FINE
        INTO v_data_inizio,v_data_fine
        FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;*/
        --
        select NVL(TRUNC(AVG(SUM(SALE))),0)--SALE, DATA_EROGAZIONE_PREV--
        INTO v_num_schermi
        from
        (
        SELECT COUNT(1) AS SALE, DATA_EROGAZIONE_PREV--NVL(TRUNC(AVG(COUNT(1))),0)
        FROM
        (
        SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
        FROM CD_SPETT_TARGET ST, CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,CD_PROIEZIONE PRO,
        CD_CINEMA CIN, CD_SCHERMO SC, CD_SALA SA, CD_COMUNICATO COM
        WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SA.ID_SALA = COM.ID_SALA
        AND CIN.ID_CINEMA = SA.ID_CINEMA
        AND CIN.FLG_VIRTUALE = 'N'
        AND SC.ID_SALA = SA.ID_SALA
        AND PRO.ID_SCHERMO = SC.ID_SCHERMO
        --AND PRO.DATA_PROIEZIONE = SV.GIORNO
        AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
        AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
        AND ST.ID_SPETTACOLO = SPE.ID_SPETTACOLO
        AND ST.ID_TARGET = p_id_target
        MINUS
        SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
        FROM CD_CINEMA CIN, CD_SALA SA, CD_COMUNICATO COM
        WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SA.ID_SALA = COM.ID_SALA
        AND CIN.ID_CINEMA = SA.ID_CINEMA
        AND (CIN.FLG_VIRTUALE = 'S'
            OR SA.ID_SALA IN
            (
                SELECT SC.ID_SALA
                FROM CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                CD_PROIEZIONE PRO, CD_SCHERMO SC
                WHERE SC.ID_SALA = SA.ID_SALA
                AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                AND PRO.DATA_PROIEZIONE = COM.DATA_EROGAZIONE_PREV
                AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
                AND SPE.ID_SPETTACOLO NOT IN
                (
                    SELECT ID_SPETTACOLO
                    FROM CD_SPETT_TARGET
                )
                AND SPE.ID_SPETTACOLO NOT IN
                (
                    SELECT ID_SPETTACOLO
                    FROM CD_SPETT_TARGET
                    WHERE ID_TARGET = p_id_target
                )
            )
        )
        )
        GROUP BY DATA_EROGAZIONE_PREV
        UNION
        select 0 AS SALE, DATA_EROGAZIONE_PREV
    --     into v_giorno
         from
         (
         /*select v_data_fine -7 + rownum as DATA_EROGAZIONE_PREV
         from all_objects
         where rownum <=7*/
         select v_data_fine -(v_data_fine - v_data_inizio +1) + rownum as DATA_EROGAZIONE_PREV
         from all_objects
         where rownum <=v_data_fine - v_data_inizio +1
         )
         )
         GROUP BY DATA_EROGAZIONE_PREV
         ORDER BY DATA_EROGAZIONE_PREV;
        IF v_num_schermi > v_numero_massimo_schermi THEN
            v_num_schermi := v_numero_massimo_schermi;
        END IF;
    END IF;
    --
    RETURN v_num_schermi;
END FU_GET_NUM_SCHERMI_TARGET;

--Mauro Viel Altran  inserito adeguamento della determinazione della tariffa 
-- per i prodotti a cavallo di listino e/o tariffa MV01
--
FUNCTION FU_GET_TARIFFA_PRODOTTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER IS
--
v_tariffa CD_TARIFFA.IMPORTO%TYPE;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
BEGIN
    SELECT MIN(ID_TARIFFA) ID_TARIFFA
    INTO v_id_tariffa
    FROM CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
    AND PV.FLG_ANNULLATO = 'N'
    AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
    --AND TAR.ID_FORMATO = PA.ID_FORMATO
    AND TAR.ID_MISURA_PRD_VE = PA.ID_MISURA_PRD_VE
   -- AND TAR.DATA_INIZIO <= PA.DATA_INIZIO MV01
    --AND TAR.DATA_FINE >= PA.DATA_FINE;  MV01
    AND  ((PA.DATA_INIZIO between TAR.DATA_INIZIO  and TAR.DATA_FINE ) or (PA.DATA_FINE between TAR.DATA_INIZIO  and TAR.DATA_FINE));-- MV01
    --
    SELECT
    PA_CD_UTILITY.FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(v_id_tariffa, pa.id_formato),pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(pa.ID_PRODOTTO_VENDITA, pa.data_inizio, pa.data_fine, pa.id_formato,pa.id_misura_prd_ve)) AS tariffa_riparametrata
    INTO v_tariffa
    FROM CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
    RETURN v_tariffa;
END FU_GET_TARIFFA_PRODOTTO;


-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_VERIFICA_POS_RIGORE_BATCH
-- DESCRIZIONE:  Verifica se una posizione di rigore puo essere assegnata
--               ad un prodotto acquistato selezionando gli ambienti dalla base dati. Alla PR_VERIFICA_POS_RIGORE
--               gli ambienti vengono passati in input
--
-- INPUT:
--       p_id_prodotto_vendita: id del prodotto di vendita che si vuole vendere
--       p_pos_rigore: posizione di rigore
--       p_data_inizio: data di inizio del prodotto
--       p_data_fine: data di fine del prodotto
--
-- OUTPUT: p_esito
--
--  REALIZZATORE: Mauro Viel, Altran, Ottobre 2010
--
--  MODIFICHE:


FUNCTION FU_VERIFICA_POS_RIGORE_BATCH(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                p_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
                                ) RETURN NUMBER IS
v_num_comunicati NUMBER := 0;
--v_id_tipo_break CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE;
v_mod_vendita CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE;
BEGIN
    if (p_id_prodotto_vendita is null) then
    --dbms_output.put_line('Prodotto vendita nullo');
        select count(cd_break.id_break)
        into v_num_comunicati
        from cd_break_vendita, cd_break,cd_circuito_break
        where cd_break_vendita.id_break_vendita in
        (select  id_break_vendita from cd_comunicato where DATA_EROGAZIONE_PREV
        BETWEEN p_data_inizio AND p_data_fine
        AND posizione_di_rigore = p_pos_rigore
        and id_prodotto_acquistato != p_id_prodotto_acquistato
        and FLG_ANNULLATO = 'N'
        and FLG_SOSPESO = 'N'
        and cod_disattivazione is null)
        and cd_break_vendita.FLG_ANNULLATO = 'N'
        and   cd_break_vendita.ID_CIRCUITO_BREAK = cd_circuito_break.ID_CIRCUITO_BREAK
        and cd_circuito_break.FLG_ANNULLATO = 'N'
        and   cd_break.id_break = cd_circuito_break.id_break
        and cd_break.FLG_ANNULLATO = 'N'
        and cd_break.id_break in (
       select cd_break.id_break from cd_break_vendita, cd_break,cd_circuito_break
        where cd_break_vendita.id_break_vendita in
        (select  id_break_vendita from cd_comunicato
        where id_prodotto_acquistato = p_id_prodotto_acquistato and FLG_ANNULLATO = 'N'
        and flg_sospeso = 'N'
        and cod_disattivazione is null)
        and cd_break_vendita.FLG_ANNULLATO = 'N'
        and   cd_break_vendita.ID_CIRCUITO_BREAK = cd_circuito_break.ID_CIRCUITO_BREAK
        and cd_circuito_break.FLG_ANNULLATO = 'N'
        and   cd_break.id_break = cd_circuito_break.id_break
        and cd_break.FLG_ANNULLATO = 'N');
    else
    --dbms_output.put_line('Prodotto vendita non nullo: '||p_id_prodotto_vendita);
    --dbms_output.put_line('Passo 2: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
        select id_mod_vendita
        into v_mod_vendita
        from cd_prodotto_vendita
        where id_prodotto_vendita = p_id_prodotto_vendita;
        --dbms_output.put_line('Id mod vendita: '||v_mod_vendita||'Ora: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
        if v_mod_vendita = 1 then--Libera
        --dbms_output.put_line('Ramo1');
            select count(1)
            into v_num_comunicati
            from cd_schermo, cd_proiezione,
            (select cd_break.id_proiezione, cd_break.id_break from
            cd_circuito_break,cd_break_vendita,cd_break
            where cd_break_vendita.id_prodotto_vendita = p_id_prodotto_vendita
            and cd_break_vendita.DATA_EROGAZIONE BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO IN (select distinct id_schermo
                                           from  cd_sala sa,
                                                 cd_schermo sc,
                                                 cd_comunicato com
                                            where com.id_sala  = sa.id_sala
                                            and   sa.ID_SALA = sc.ID_SALA
                                            and   com.FLG_ANNULLATO = 'N'
                                            and   com.FLG_SOSPESO = 'N'
                                            and   cod_disattivazione is null
                                            and   com.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato)
            and br.id_break in
            (
            select id_break
            from cd_schermo, cd_proiezione,
            (select cd_break.id_proiezione, cd_break.id_break
            from cd_break, cd_circuito_break,cd_break_vendita, cd_comunicato
            where cd_comunicato.posizione_di_rigore = p_pos_rigore
            and cd_comunicato.data_erogazione_prev BETWEEN p_data_inizio AND p_data_fine
            and cd_comunicato.FLG_ANNULLATO = 'N'
            and cd_comunicato.FLG_SOSPESO = 'N'
            and cd_comunicato.COD_DISATTIVAZIONE IS NULL
            and cd_break_vendita.id_break_vendita = cd_comunicato.id_break_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO IN (select distinct id_schermo
                                           from  cd_sala sa,
                                                 cd_schermo sc,
                                                 cd_comunicato com
                                            where com.id_sala  = sa.id_sala
                                            and   sa.ID_SALA = sc.ID_SALA
                                            and   com.FLG_ANNULLATO = 'N'
                                            and   com.FLG_SOSPESO = 'N'
                                            and   cod_disattivazione is null
                                            and   com.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato)
            );
        elsif v_mod_vendita = 2 then
        --dbms_output.put_line('Ramo2');
            select count(1)
            into v_num_comunicati
            from cd_break_vendita,cd_break,cd_circuito_break
            --where cd_comunicato.posizione_di_rigore = p_pos_rigore
            where cd_break_vendita.id_prodotto_vendita = p_id_prodotto_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            and cd_break.id_break in
            (select cd_break.id_break
            from cd_comunicato, cd_break_vendita,cd_break,cd_circuito_break
            where cd_comunicato.posizione_di_rigore = p_pos_rigore
            and cd_comunicato.FLG_ANNULLATO = 'N'
            and cd_comunicato.FLG_SOSPESO = 'N'
            and cd_comunicato.COD_DISATTIVAZIONE IS NULL
            and cd_comunicato.data_erogazione_prev BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.id_break_vendita = cd_comunicato.id_break_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N');
        elsif v_mod_vendita = 3 then
            select count(1)
            into v_num_comunicati
            from cd_sala, cd_schermo, cd_proiezione,
            (select cd_break.id_proiezione, cd_break.id_break from
            cd_circuito_break,cd_break_vendita,cd_break
            where cd_break_vendita.id_prodotto_vendita = p_id_prodotto_vendita
            and cd_break_vendita.DATA_EROGAZIONE BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_sala.ID_SALA = cd_schermo.ID_SALA
            and cd_sala.FLG_ANNULLATO = 'N'
            and cd_sala.id_sala in
           (select id_sala from cd_sala
           where flg_annullato = 'N'
           and id_cinema in
               (select id_cinema from cd_cinema
               where flg_annullato = 'N'
               and id_comune in
                   (select id_comune from cd_comune where id_provincia in
                       (select id_provincia from cd_provincia where id_regione in
                            (select id_regione from cd_regione where id_regione in
                                  (select id_regione from cd_nielsen_regione where id_area_nielsen IN (select an.id_area_nielsen
                                                                                                       from   cd_aree_prodotto_acquistato ap,
                                                                                                              cd_area_nielsen an
                                                                                                       where  an.id_area_nielsen = ap.id_area_nielsen
                                                                                                       and    ap.id_prodotto_acquistato = p_id_prodotto_acquistato)))))))
           and br.id_break in
           (
           select id_break
            from cd_sala, cd_schermo, cd_proiezione,
            (select cd_break.id_break
            from cd_comunicato, cd_break_vendita,cd_break,cd_circuito_break
            where cd_comunicato.posizione_di_rigore = p_pos_rigore
            and cd_comunicato.FLG_ANNULLATO = 'N'
            and cd_comunicato.FLG_SOSPESO = 'N'
            and cd_comunicato.COD_DISATTIVAZIONE IS NULL
            and cd_comunicato.data_erogazione_prev BETWEEN p_data_inizio AND p_data_fine
            and cd_break_vendita.id_break_vendita = cd_comunicato.id_break_vendita
            and cd_break_vendita.FLG_ANNULLATO = 'N'
            and cd_circuito_break.ID_CIRCUITO_BREAK = cd_break_vendita.ID_CIRCUITO_BREAK
            and cd_circuito_break.FLG_ANNULLATO = 'N'
            and cd_break.ID_BREAK = cd_circuito_break.ID_BREAK
            and cd_break.FLG_ANNULLATO = 'N'
            ) br
            where br.id_proiezione = cd_proiezione.id_proiezione
            and cd_proiezione.FLG_ANNULLATO = 'N'
            and cd_schermo.ID_SCHERMO = cd_proiezione.ID_SCHERMO
            and cd_schermo.FLG_ANNULLATO = 'N'
            and cd_sala.ID_SALA = cd_schermo.ID_SALA
            and cd_sala.FLG_ANNULLATO = 'N'
            and cd_sala.id_sala in
           (select id_sala from cd_sala
           where flg_annullato = 'N'
           and id_cinema in
               (select id_cinema from cd_cinema
               where flg_annullato = 'N'
               and id_comune in
                   (select id_comune from cd_comune where id_provincia in
                       (select id_provincia from cd_provincia where id_regione in
                            (select id_regione from cd_regione where id_regione in
                                  (select id_regione from cd_nielsen_regione where id_area_nielsen IN (select an.id_area_nielsen
                                                                                                       from   cd_aree_prodotto_acquistato ap,
                                                                                                              cd_area_nielsen an
                                                                                                       where  an.id_area_nielsen = ap.id_area_nielsen
                                                                                                       and    ap.id_prodotto_acquistato = p_id_prodotto_acquistato))))))));
        end if;
    end if;
    --dbms_output.put_line('Numero comunicati 1: '||v_num_comunicati||'Ora: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
    IF (v_num_comunicati IS NULL) THEN
        v_num_comunicati := 0;
    END IF;
    --dbms_output.put_line('Numero comunicati 2: '||v_num_comunicati||'Ora: '||to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS'));
RETURN v_num_comunicati;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_VERIFICA_POS_RIGORE_BATCH: Si e'' verificato un errore  '||SQLERRM);
END FU_VERIFICA_POS_RIGORE_BATCH;


-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_IMPOSTA_POSIZIONE_ESC
-- DESCRIZIONE:  Assegna la posizione di rigore scelta, se disponibile, altrimenti
--               verifica se esiste una posizione di rigore dispoonibile diversa  da
--               quella scelta. Se nessuna delle posizioni di rigore e disponibile allora viene
--               impostata una posizione non di rigore.
--
-- INPUT:
--       p_id_prodotto_vendita: id del prodotto di vendita che si vuole vendere
--       p_pos_rigore: posizione di rigore
--       p_data_inizio: data di inizio del prodotto
--       p_data_fine: data di fine del prodotto
--
-- OUTPUT: p_esito
--
--  REALIZZATORE: Mauro Viel, Altran, Ottobre 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE  PR_IMPOSTA_POSIZIONE_ESC (p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) IS
v_com           number:= 0;
v_pos           number;
v_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE;
v_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
begin
    select distinct posizione_di_rigore into v_pos
    from cd_comunicato where id_prodotto_acquistato = p_id_prodotto_acquistato ;

    if  v_pos >0 then
        select
        id_prodotto_vendita,
        data_inizio,
        data_fine
        into
        v_id_prodotto_vendita,
        v_data_inizio,
        v_data_fine
        from cd_prodotto_acquistato
        where id_prodotto_acquistato = p_id_prodotto_acquistato;

        v_com:=FU_VERIFICA_POS_RIGORE_BATCH(null ,v_id_prodotto_vendita ,v_pos,v_data_inizio ,v_data_fine );
        --dbms_output.PUT_LINE('Posizione ='|| V_POS || ', disponibile');
       if  v_com >0 then -- cerco se esiste almeno una posizione di rigore disponibile diversa da quella richiesta
            for c_pos in (select cod_posizione from cd_posizione_rigore where cod_posizione != v_pos order by cod_posizione desc)
            loop
                 v_pos := c_pos.cod_posizione;
                 --dbms_output.PUT_LINE('Verifico la disponibilita per la posizione: '|| v_pos);
                 v_com:=FU_VERIFICA_POS_RIGORE_BATCH(null ,v_id_prodotto_vendita ,v_pos,v_data_inizio ,v_data_fine );
                 if  v_com = 0 then
                    --dbms_output.PUT_LINE('Posizione='|| V_POS||' disponibilie');
                    exit;
                 end if;
            end loop;
        end if;
     end if;

        if v_com = 0 then --aggiorno con la nuova posizione di rigore e la imposto , nel caso in cui il prodotto non aveva in origine una posizione di rigore richiamo comunque la assegna posizione
            --dbms_output.PUT_LINE('Assegno la posizione'|| V_POS);
            UPDATE CD_COMUNICATO
            SET POSIZIONE_DI_RIGORE = v_pos
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
            PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,null);
        else -- non esistono posizioni di rigore disponibili assegno una posizione arbitraria
            --dbms_output.PUT_LINE(' Non esistono posizioni di rigore disponibili assegno una posizione arbitraria');
            --dbms_output.PUT_LINE('pos'|| V_POS);
            UPDATE CD_COMUNICATO
            SET POSIZIONE_DI_RIGORE = null
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
            PR_IMPOSTA_POSIZIONE(p_id_prodotto_acquistato,null);
        end if;
END PR_IMPOSTA_POSIZIONE_ESC;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_SINTESI_PROD_ACQ
-- DESCRIZIONE:  Gestisce l'inserimento nella tavola di comodo CD_SINTESI_PROD_ACQ dei prodotti
--               acquistati gia terminati.
--
-- INPUT:
--       p_id_prodotto_acquistato: id del prodotto acquistato OPZIONALE
--
--  REALIZZATORE: Luigi Cipolla, 16 Novembre 2010
--
--  MODIFICHE:   
--    Mauro Viel, Altran Italia, 13 Gennaio 2011
--       inserito il campo num_sale_giorno
--    Mauro Viel, Altran Italia, 18 Gennaio 2011
--      Correzione del calcolo num_sale_giorno
--    Mauro Viel, Altran Italia, 28/03/2011
--       inserito il  <=  sulla data_fine del prodotto_acquistato (in precedenza solo <) perche l'elaborazione 
--       e stata spostata alle ore 20 del giorno corrente primna era alle 02:00. 
--    Luigi Cipolla, 01/06/2011
--       Ottimizzazione estrazione  [LC#1]
--    Luigi Cipolla, 03/06/2011
--     Completamento dell'intervento del 01/06/2011 [LC#2].
--    Mauro Viel, Altran Italia, 08/06/2011  [MV#1]
--       Eliminazione della chiamata PA_CD_SUPPORTO_VENDITE.FU_DATA_INIZIO e
--       PA_CD_SUPPORTO_VENDITE.FU_DATA_FINE e inserimento del join con cd_prodotto_acquistato 
--        
-- --------------------------------------------------------------------------------------------
PROCEDURE  PR_SINTESI_PROD_ACQ (p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE default null)
IS
BEGIN
  insert into cd_sintesi_prod_acq (ID_PRODOTTO_ACQUISTATO
                                   ,ID_SOGGETTO_DI_PIANO
                                   ,DATA_EROGAZIONE_PREV
                                   ,DATA_INIZIO
                                   ,DATA_FINE
                                   ,NUM_GIORNI_TOTALE
                                   ,NUM_SOGGETTI_GIORNO
                                   ,NUM_SALE_GIORNO
                                   ,DATAMOD
                                   ,UTEMOD)
  (
   select distinct -- [LC#2] aggiunta distinct a causa del prodotto cartesiano effettuato tra SPOT e PA_TOT nei casi di flag_giorno='EFF'
     PA_TOT.id_prodotto_acquistato,
     SPOT.id_soggetto_di_piano,
     PA_TOT.data_erogazione_prev,
     PA_TOT.data_inizio,
     PA_TOT.data_fine,
     PA_TOT.num_giorni_totale,
     /* news: conteggio di num_sale_giorno */
     --SPOT.num_soggetti_giorno,
    decode (flag_giorno, 'EFF', SPOT.num_soggetti_giorno, 1) num_soggetti_giorno,   --[LC#2] aggiunta decode
    /* news: conteggio di num_sale_giorno */
    --SPOT.num_sale_giorno,
    decode (flag_giorno, 'EFF', SPOT.num_sale_giorno, 0) num_sale_giorno,           --[LC#2] aggiunta decode
    sysdate,
    user
   from
        (
         -- [MV#1] inizio
         -- [LC#1] inizio
         -- sostituisce la tavola cd_comunicato
            select distinct
            com.id_prodotto_acquistato, data_erogazione_prev, id_soggetto_di_piano
           --,pa.NUMERO_AMBIENTI as  num_sale_giorno
           ,count(distinct id_sala) over (partition by com.id_prodotto_acquistato, data_erogazione_prev) num_sale_giorno
           ,count(distinct id_soggetto_di_piano) over (partition by com.id_prodotto_acquistato,data_erogazione_prev) num_soggetti_giorno
           from
             cd_comunicato com,
             cd_prodotto_acquistato pa
           where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
           and com.id_prodotto_acquistato = pa.id_prodotto_acquistato
           and com.flg_annullato='N'
           and com.flg_sospeso='N'
           and com.cod_disattivazione is null
         -- [LC#1] fine
         -- [MV#1] fine
        ) SPOT,
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
              (select to_date('01/01/2010','dd/mm/yyyy') -1 + rownum as giorno
               from
                 cd_coeff_cinema,
                 cd_tipo_cinema
               where rownum <= trunc(sysdate) - to_date('01/01/2010','dd/mm/yyyy') +1
              ) giorni,
              -- P_A : prodotti acquistati validi nel periodo richiesto
              (select
                 PA.id_prodotto_acquistato,
                 PA.data_inizio,
                 PA.data_fine
               from
                 cd_prodotto_acquistato PA
               where PA.data_fine <= trunc(sysdate)
                  and ( p_id_prodotto_acquistato is null
                        or
                          p_id_prodotto_acquistato is not null
                          and
                          PA.id_prodotto_acquistato = p_id_prodotto_acquistato
                      )
                  and not exists
                     (select 1
                      from CD_SINTESI_PROD_ACQ SPA
                      where SPA.id_prodotto_acquistato = PA.id_prodotto_acquistato
                     )
                 and flg_annullato='N'
                 and flg_sospeso='N'
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
              cd_prodotto_acquistato PA
               where PA.data_fine <= trunc(sysdate)
                  and ( p_id_prodotto_acquistato is null
                        or
                          p_id_prodotto_acquistato is not null
                          and
                          PA.id_prodotto_acquistato = p_id_prodotto_acquistato
                      )
                  and not exists
                     (select 1
                      from CD_SINTESI_PROD_ACQ SPA
                      where SPA. id_prodotto_acquistato = PA. id_prodotto_acquistato
                     )
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
  );
END PR_SINTESI_PROD_ACQ;

-- --------------------------------------------------------------------------------------------
-- PROCEDURE  PR_AGGIORNA_SINTESI_PRODOTTO
-- DESCRIZIONE:  Gestisce l'aggiornamento nella tavola di comodo CD_SINTESI_PROC_ACQ dei prodotti
--               acquistati gia terminati che hanno subito variazioen di soggetto.
--
-- INPUT:
--       p_id_prodotto_acquistato: id del prodotto acquistato
--
--  REALIZZATORE: Mauro Viel Altran Italia, 17 Novembre 2010
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------


PROCEDURE  PR_AGGIORNA_SINTESI_PRODOTTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE ) IS
BEGIN

 delete cd_sintesi_prod_acq  where id_prodotto_acquistato = p_id_prodotto_acquistato;
 PR_SINTESI_PROD_ACQ(p_id_prodotto_acquistato);

END PR_AGGIORNA_SINTESI_PRODOTTO;




function fu_get_cod_posizione_rig(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_posizione_rigore.COD_POSIZIONE%type is
v_cod_posizione cd_posizione_rigore.COD_POSIZIONE%type;
begin

select pos.COD_POSIZIONE--, pos.DESCRIZIONE
into v_cod_posizione
from  cd_comunicato com, 
      cd_sala sa, 
      cd_posizione_rigore pos
where id_prodotto_acquistato = p_id_prodotto_acquistato
--and   com.flg_annullato ='N'
--and   com.flg_sospeso ='N'
--and   com.COD_DISATTIVAZIONE is not null
and   sa.id_sala = com.id_sala
and   sa.FLG_VISIBILE ='S'
and   pos.COD_POSIZIONE (+) = com.POSIZIONE_DI_RIGORE
and rownum =1;
return v_cod_posizione;
end fu_get_cod_posizione_rig;


function fu_get_des_posizione_rig(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_posizione_rigore.descrizione%type is
v_descrizione cd_posizione_rigore.descrizione%type;
begin

select  pos.descrizione
into v_descrizione
from  cd_comunicato com, 
      cd_sala sa, 
      cd_posizione_rigore pos
where id_prodotto_acquistato = p_id_prodotto_acquistato
--and   com.flg_annullato ='N'
--and   com.flg_sospeso ='N'
--and   com.COD_DISATTIVAZIONE is not null
and   sa.id_sala = com.id_sala
and   sa.FLG_VISIBILE ='S'
and   pos.COD_POSIZIONE (+) = com.POSIZIONE_DI_RIGORE
and rownum =1;
return v_descrizione;
end fu_get_des_posizione_rig;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_PROD_ACQUISTATI_PIANO
--
-- DESCRIZIONE:  Restituisce tutti i prodotti acquistati di un piano
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_data_inizio           Data di inizio del periodo cercato
--  p_data_fine             Data di fine del periodo cercato
--  p_flg_annullati         Flg di annullamento
--  OUTPUT: lista di prodotti acquistati appartenenti al piano
--
-- REALIZZATORE: Simone Bottani , Altran, Settembre 2009
--
--  MODIFICHE:
--            Simone Bottani , Altran, Settembre 2009
--            Aggiunto il parametro flag di annullamento
--
--            Mauro Viel Altran, Aprile 2011 eliminate le clausole: 
--           and PR_ACQ.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
--           and PR_ACQ.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
--           in modo da poter visualizzare i prodotti a cavallo di listino.
--           
--           Mauro Viel Altran, Settembre 2011 eliminata la chiamata alla fu_get_num_ambienti
--           inserita la colonna numero_ambienti.
-------------------------------------------------------------------------------------------------


FUNCTION FU_GET_PROD_ACQUISTATI_PIANO(
                                      p_id_piano CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                      p_id_ver_piano CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                      p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                      p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                      p_flg_annullato CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO%TYPE,
                                      p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_PROD_ACQ_PIANO IS
--
v_prodotti C_PROD_ACQ_PIANO;
BEGIN

OPEN v_prodotti FOR
    SELECT ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA, IMP_LORDO, IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE, IMP_RECUPERO, IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS IMP_LORDO_COMM,
           PA_PC_IMPORTI.FU_LORDO_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS IMP_LORDO_DIR,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_COMM,IMP_SC_COMM) AS PERC_SCONTO_COMM,
           PA_PC_IMPORTI.FU_PERC_SC_COMM(IMP_NETTO_DIR,IMP_SC_DIR) AS PERC_SCONTO_DIR,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           GET_COD_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as COD_SOGGETTO,
           GET_DESC_SOGGETTO(ID_PRODOTTO_ACQUISTATO) as DESC_SOGGETTO,
           GET_TITOLO_MATERIALE(ID_PRODOTTO_ACQUISTATO) as TITOLO_MAT,
           --count(distinct ID_SCHERMO) num_schermi,
           --FU_GET_NUM_AMBIENTI(id_prodotto_acquistato) num_schermi,
           numero_ambienti as num_schermi,
           0 num_sale,
           0 num_atrii,
           0 num_cinema,
           0 as num_comunicati,
           ID_FORMATO,
           DESCRIZIONE AS DESC_FORMATO,
           DURATA,
           fu_get_cod_posizione_rig(id_prodotto_acquistato)  as COD_POS_FISSA, 
           fu_get_des_posizione_rig(id_prodotto_acquistato) as  DESC_POS_FISSA,
           FLG_TARIFFA_VARIABILE,
           DATA_INIZIO,
           DATA_FINE,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD
    FROM
   (SELECT PR_ACQ.NUMERO_AMBIENTI,
           PR_ACQ.ID_PRODOTTO_ACQUISTATO,
           PR_ACQ.ID_PRODOTTO_VENDITA,
           PR_PUB.DESC_PRODOTTO,
           CD_CIRCUITO.ID_CIRCUITO,
           CD_CIRCUITO.NOME_CIRCUITO,
           MOD_VEN.ID_MOD_VENDITA,
           MOD_VEN.DESC_MOD_VENDITA,
           TI_BR.ID_TIPO_BREAK,
           TI_BR.DESC_TIPO_BREAK,
           PC_MANIF.DES_MAN,
           PR_ACQ.ID_RAGGRUPPAMENTO,
           PR_ACQ.ID_FRUITORI_DI_PIANO,
           PR_ACQ.STATO_DI_VENDITA,
           PR_ACQ.IMP_TARIFFA, PR_ACQ.IMP_LORDO, PR_ACQ.IMP_NETTO,
           PR_ACQ.FLG_TARIFFA_VARIABILE,
           PR_ACQ.DATA_INIZIO,
           PR_ACQ.DATA_FINE,
           PR_ACQ.ID_TIPO_CINEMA,
           IMP_PRD_D.IMP_NETTO as IMP_NETTO_DIR,
           IMP_PRD_D.IMP_SC_COMM as IMP_SC_DIR,
           IMP_PRD_C.IMP_NETTO as IMP_NETTO_COMM,
           IMP_PRD_C.IMP_SC_COMM as IMP_SC_COMM,
           PR_ACQ.IMP_MAGGIORAZIONE, PR_ACQ.IMP_RECUPERO, PR_ACQ.IMP_SANATORIA,
           F_ACQ.ID_FORMATO, F_ACQ.DESCRIZIONE, COEF.DURATA, TAR.ID_TIPO_TARIFFA,
           PERIODO.ANNO ||'-'||PERIODO.CICLO||'-'||PERIODO.PER AS SETTIMANA_SIPRA,
           PR_ACQ.DATAMOD
     FROM
           PERIODI PERIODO,
           PC_MANIF,
           CD_TIPO_BREAK TI_BR,
           CD_MODALITA_VENDITA MOD_VEN,
           CD_CIRCUITO,
           CD_PRODOTTO_PUBB PR_PUB,
           CD_TARIFFA TAR,
           CD_PRODOTTO_VENDITA PR_VEN,
           CD_COEFF_CINEMA COEF,
           CD_FORMATO_ACQUISTABILE F_ACQ,
           CD_IMPORTI_PRODOTTO IMP_PRD_D,
           CD_IMPORTI_PRODOTTO IMP_PRD_C,
           CD_PRODOTTO_ACQUISTATO PR_ACQ
      WHERE PR_ACQ.ID_PIANO = p_id_piano
        and PR_ACQ.ID_VER_PIANO = p_id_ver_piano
        and PR_ACQ.FLG_ANNULLATO = p_flg_annullato
        and PR_ACQ.FLG_SOSPESO = 'N'
        and PR_ACQ.COD_DISATTIVAZIONE is null
        and (p_stato_vendita IS NULL OR  instr(p_stato_vendita, PR_ACQ.STATO_DI_VENDITA)>0)
        and IMP_PRD_C.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
        and IMP_PRD_C.TIPO_CONTRATTO = 'C'
        and IMP_PRD_D.ID_PRODOTTO_ACQUISTATO = PR_ACQ.ID_PRODOTTO_ACQUISTATO
        and IMP_PRD_D.TIPO_CONTRATTO = 'D'
        and F_ACQ.ID_FORMATO = PR_ACQ.ID_FORMATO
        AND COEF.ID_COEFF(+) = F_ACQ.ID_COEFF
        and PR_VEN.ID_PRODOTTO_VENDITA = PR_ACQ.ID_PRODOTTO_VENDITA
        and TAR.ID_PRODOTTO_VENDITA = PR_VEN.ID_PRODOTTO_VENDITA
        --and PR_ACQ.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
        --and PR_ACQ.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
        and PR_ACQ.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE
        and (PR_ACQ.ID_TIPO_CINEMA IS NULL OR PR_ACQ.ID_TIPO_CINEMA = TAR.ID_TIPO_CINEMA)
        and (TAR.ID_TIPO_TARIFFA = 1 OR TAR.ID_FORMATO = PR_ACQ.ID_FORMATO)
        and PR_PUB.ID_PRODOTTO_PUBB = PR_VEN.ID_PRODOTTO_PUBB
        and CD_CIRCUITO.ID_CIRCUITO = PR_VEN.ID_CIRCUITO
        and MOD_VEN.ID_MOD_VENDITA = PR_VEN.ID_MOD_VENDITA
        and TI_BR.ID_TIPO_BREAK(+) = PR_VEN.ID_TIPO_BREAK
        and PC_MANIF.COD_MAN(+) = PR_VEN.COD_MAN
        and PR_ACQ.DATA_INIZIO = PERIODO.DATA_INIZ (+)
        and PR_ACQ.DATA_FINE = PERIODO.DATA_FINE (+)  
    ) 
    group by
           NUMERO_AMBIENTI,
           ID_PRODOTTO_ACQUISTATO,
           ID_PRODOTTO_VENDITA,
           DESC_PRODOTTO,
           ID_CIRCUITO,
           NOME_CIRCUITO,
           ID_MOD_VENDITA,
           DESC_MOD_VENDITA,
           ID_TIPO_BREAK,
           DESC_TIPO_BREAK,
           DES_MAN,
           IMP_TARIFFA,
           IMP_LORDO,
           IMP_NETTO,
           IMP_NETTO_COMM,
           IMP_SC_COMM,
           IMP_NETTO_DIR,
           IMP_SC_DIR,
           IMP_MAGGIORAZIONE,
           IMP_RECUPERO,
           IMP_SANATORIA,
           ID_TIPO_TARIFFA,
           ID_FORMATO,
           DESCRIZIONE,
           DURATA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           STATO_DI_VENDITA,
           FLG_TARIFFA_VARIABILE,
           DATA_INIZIO,
           DATA_FINE,
           SETTIMANA_SIPRA,
           ID_TIPO_CINEMA,
           DATAMOD
           order by DATA_INIZIO,DATA_FINE,ID_CIRCUITO;


return v_prodotti;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
END FU_GET_PROD_ACQUISTATI_PIANO;



-----------------------------------------------------------------------------------------------------
-- Funzione PR_AGGIORNA_IMP_SALT
--
-- DESCRIZIONE:  Aggiorna l'importo di lordo saltatao su importi prodotto al variare del formato di vendita
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato              id del prodotto 
--  p_id_formato                          id del formato di vendita
--  OUTPUT: 
--
-- REALIZZATORE: Mauro Viel  , Altran, Gennaio  2011
--
-- NOTE:  Sara da gestire la quoda di importo saltato dierzionele quando il pacchetto 
--        degli importi lo fara.
--
--  MODIFICHE: Mauro Viel Marzo 2011 la funzione e da applicare solo ai prodotti della tabellare
--           
--            
--
-------------------------------------------------------------------------------------------------

procedure PR_AGGIORNA_IMP_SALT(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type , p_id_formato cd_formato_acquistabile.id_formato%type) is

V_IMP_LORDO_SALTATO_C NUMBER;
V_IMP_LORDO_SALTATO_D NUMBER;
V_IMP_LORDO_SALTATO_RIP NUMBER;
V_NEW_IMP_LORDO_SALTATO_C NUMBER;
v_cod_categoria_prodotto cd_pianificazione.cod_categoria_prodotto%type;

BEGIN

select cod_categoria_prodotto
into   v_cod_categoria_prodotto
from   cd_pianificazione pia, cd_prodotto_acquistato pa 
where  pia.id_piano = pa.id_piano
and    pia.id_ver_piano = pa.id_ver_piano
and    id_prodotto_Acquistato = p_id_prodotto_acquistato;

if v_cod_categoria_prodotto = 'TAB' then



select  IMP_LORDO_SALTATO
into    V_IMP_LORDO_SALTATO_C
from    cd_importi_prodotto
where   id_prodotto_Acquistato = p_id_prodotto_acquistato
and     tipo_contratto ='C';


select  IMP_LORDO_SALTATO
into    V_IMP_LORDO_SALTATO_D
from    cd_importi_prodotto
where   id_prodotto_Acquistato = p_id_prodotto_acquistato
and     tipo_contratto ='D';





SELECT (V_IMP_LORDO_SALTATO_C+V_IMP_LORDO_SALTATO_D) / ALIQUOTA *
(SELECT ALIQUOTA
FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE
WHERE CD_FORMATO_ACQUISTABILE.ID_FORMATO = p_id_formato
AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF)
INTO V_IMP_LORDO_SALTATO_RIP
FROM CD_COEFF_CINEMA, CD_FORMATO_ACQUISTABILE, CD_PRODOTTO_ACQUISTATO
WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
AND CD_FORMATO_ACQUISTABILE.ID_FORMATO = CD_PRODOTTO_ACQUISTATO.ID_FORMATO
AND CD_COEFF_CINEMA.ID_COEFF = CD_FORMATO_ACQUISTABILE.ID_COEFF;

--dbms_output.PUT_LINE('V_IMP_LORDO_SALTATO_RIP:'||V_IMP_LORDO_SALTATO_RIP);
--dbms_output.PUT_LINE('V_IMP_LORDO_SALTATO_RIP_C:'||V_IMP_LORDO_SALTATO_C);
--dbms_output.PUT_LINE('V_IMP_LORDO_SALTATO_RIP_D:'||V_IMP_LORDO_SALTATO_D);

V_NEW_IMP_LORDO_SALTATO_C :=  V_IMP_LORDO_SALTATO_RIP - V_IMP_LORDO_SALTATO_D;

--dbms_output.PUT_LINE('V_NEW_IMP_LORDO_SALTATO_C:'||V_NEW_IMP_LORDO_SALTATO_C);

if  V_NEW_IMP_LORDO_SALTATO_C != V_IMP_LORDO_SALTATO_C then
    --dbms_output.PUT_LINE('aggiorno l''importo');
    update  cd_importi_prodotto
    set     IMP_LORDO_SALTATO = V_NEW_IMP_LORDO_SALTATO_C 
    where   id_prodotto_acquistato = p_id_prodotto_acquistato
    and     tipo_contratto ='C';
end if; 

end if;

END PR_AGGIORNA_IMP_SALT;




-----------------------------------------------------------------------------------------------------
-- Funzione FU_GET_NUM_SCHERMI_SEGUI_FILM
--
-- DESCRIZIONE:  Conteggia le sale di un prodotto segui il film
--
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_prodotto_acquistato              id del prodotto 
---  numero di sale del prodotto
--  OUTPUT: 
--
-- REALIZZATORE: Mauro Viel  , Altran, Febbraio   2011
--
-- NOTE:  
--
--  MODIFICHE: Mauro Viel, Altran Novembre 2011 modificata la logica di estrazione degli schermi. 
--                        Consideriamo solo gli schermi reali associati al comunicato --#MV01 
--           
--            
--
-------------------------------------------------------------------------------------------------


-------------------
FUNCTION FU_GET_NUM_SCHERMI_SEGUI_FILM(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_sale_reali VARCHAR2) RETURN NUMBER IS
v_num_schermi NUMBER;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine   CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_schermi_virtuali NUMBER;
v_id_spettacolo CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE;
v_sale_reali VARCHAR2(1);
v_numero_massimo_schermi cd_prodotto_acquistato.NUMERO_MASSIMO_SCHERMI%type;
v_flg_ricalcolo_tariffa cd_prodotto_acquistato.flg_ricalcolo_tariffa%type;

BEGIN

     v_sale_reali := p_sale_reali;

     select numero_massimo_schermi
     into   v_numero_massimo_schermi
     from cd_prodotto_acquistato
     where id_prodotto_acquistato = p_id_prodotto_acquistato;
     
     v_numero_massimo_schermi :=  nvl(v_numero_massimo_schermi,0);
     
     IF v_sale_reali = 'N' THEN
        select flg_ricalcolo_tariffa
        into   v_flg_ricalcolo_tariffa
        from   cd_prodotto_acquistato
        where  id_prodotto_acquistato = p_id_prodotto_acquistato;  
        IF v_flg_ricalcolo_tariffa ='S' THEN
            v_sale_reali := 'S';
        ELSE
            v_num_schermi := v_numero_massimo_schermi;
        END IF;
     END IF;
     
    
  
     
    IF v_sale_reali = 'S' THEN
    
    
        SELECT NVL(trunc(AVG(SUM(SALE))),0)
        INTO v_num_schermi
        FROM
        (
            SELECT COUNT(DISTINCT COM.ID_SALA) AS SALE, COM.DATA_EROGAZIONE_PREV
            FROM   CD_CINEMA CIN,
                   CD_SALA SA, 
                   CD_COMUNICATO COM
            WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND   COM.FLG_ANNULLATO = 'N'
            AND   COM.FLG_SOSPESO = 'N'
            AND   COM.COD_DISATTIVAZIONE IS NULL
            AND   SA.ID_SALA = COM.ID_SALA
            AND   CIN.ID_CINEMA = SA.ID_CINEMA
            AND   CIN.FLG_VIRTUALE = 'N'
            GROUP BY COM.DATA_EROGAZIONE_PREV
        )
        GROUP BY DATA_EROGAZIONE_PREV;
        
        
        IF v_num_schermi > v_numero_massimo_schermi THEN
            v_num_schermi := v_numero_massimo_schermi;
        END IF; --Si venderanno sempre gli schemi effettivamente richiesti in fase di acquisto anche nel caso di eccesso di associazione*/
        
        
/*         SELECT DATA_INIZIO,DATA_FINE, ID_SPETTACOLO
            INTO v_data_inizio,v_data_fine,v_id_spettacolo
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
        --
        select NVL(trunc(AVG(SUM(SALE))),0)--SALE, DATA_EROGAZIONE_PREV--
        INTO v_num_schermi
        from
        (
        SELECT COUNT(1) AS SALE, DATA_EROGAZIONE_PREV--NVL(TRUNC(AVG(COUNT(1))),0)
        FROM
        (
        SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
        FROM  CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,CD_PROIEZIONE PRO,
        CD_CINEMA CIN, CD_SCHERMO SC, CD_SALA SA, CD_COMUNICATO COM
        WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SA.ID_SALA = COM.ID_SALA
        AND CIN.ID_CINEMA = SA.ID_CINEMA
        AND CIN.FLG_VIRTUALE = 'N'
        AND SC.ID_SALA = SA.ID_SALA
        AND PRO.ID_SCHERMO = SC.ID_SCHERMO
        AND PS.ID_PROIEZIONE  = PRO.ID_PROIEZIONE
        AND SPE.ID_SPETTACOLO = v_id_spettacolo 
        AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
        MINUS
        SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
        FROM CD_CINEMA CIN, CD_SALA SA, CD_COMUNICATO COM
        WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SA.ID_SALA = COM.ID_SALA
        AND CIN.ID_CINEMA = SA.ID_CINEMA
        AND (CIN.FLG_VIRTUALE = 'S'
            OR SA.ID_SALA IN
            (
                SELECT SC.ID_SALA
                FROM CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                CD_PROIEZIONE PRO, CD_SCHERMO SC
                WHERE SC.ID_SALA = SA.ID_SALA
                AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                AND PRO.DATA_PROIEZIONE = COM.DATA_EROGAZIONE_PREV
                AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO    
                AND SPE.ID_SPETTACOLO != v_id_spettacolo
            )
        )
        )
        GROUP BY DATA_EROGAZIONE_PREV
        UNION
        select 0 AS SALE, DATA_EROGAZIONE_PREV
         from
         (
         select v_data_fine -(v_data_fine - v_data_inizio +1) + rownum as DATA_EROGAZIONE_PREV
         from all_objects
         where rownum <=v_data_fine - v_data_inizio +1
         )
         )
         GROUP BY DATA_EROGAZIONE_PREV
         ORDER BY DATA_EROGAZIONE_PREV;
         IF v_num_schermi > v_numero_massimo_schermi THEN
            v_num_schermi := v_numero_massimo_schermi;
         END IF; --Si venderanno sempre gli schemi effettivamente venduti*/
   
   end if;
    RETURN v_num_schermi;
END FU_GET_NUM_SCHERMI_SEGUI_FILM;


--copia di backup
FUNCTION OFU_GET_NUM_SCHERMI_SEGUI_FILM(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_sale_reali VARCHAR2) RETURN NUMBER IS
v_num_schermi NUMBER;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine   CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_schermi_virtuali NUMBER;
v_id_spettacolo CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE;
v_sale_reali VARCHAR2(1);
v_numero_massimo_schermi cd_prodotto_acquistato.NUMERO_MASSIMO_SCHERMI%type;
v_flg_ricalcolo_tariffa cd_prodotto_acquistato.flg_ricalcolo_tariffa%type;

BEGIN

     v_sale_reali := p_sale_reali;

     select numero_massimo_schermi
     into   v_numero_massimo_schermi
     from cd_prodotto_acquistato
     where id_prodotto_acquistato = p_id_prodotto_acquistato;
     
     v_numero_massimo_schermi :=  nvl(v_numero_massimo_schermi,0);
     
     IF v_sale_reali = 'N' THEN
        select flg_ricalcolo_tariffa
        into   v_flg_ricalcolo_tariffa
        from   cd_prodotto_acquistato
        where  id_prodotto_acquistato = p_id_prodotto_acquistato;  
        IF v_flg_ricalcolo_tariffa ='S' THEN
            v_sale_reali := 'S';
        ELSE
            v_num_schermi := v_numero_massimo_schermi;
        END IF;
     END IF;
     
    
  
     
    IF v_sale_reali = 'S' THEN
         SELECT DATA_INIZIO,DATA_FINE, ID_SPETTACOLO
            INTO v_data_inizio,v_data_fine,v_id_spettacolo
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
        --
        select NVL(trunc(AVG(SUM(SALE))),0)--SALE, DATA_EROGAZIONE_PREV--
        INTO v_num_schermi
        from
        (
        SELECT COUNT(1) AS SALE, DATA_EROGAZIONE_PREV--NVL(TRUNC(AVG(COUNT(1))),0)
        FROM
        (
        SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
        FROM  CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,CD_PROIEZIONE PRO,
        CD_CINEMA CIN, CD_SCHERMO SC, CD_SALA SA, CD_COMUNICATO COM
        WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SA.ID_SALA = COM.ID_SALA
        AND CIN.ID_CINEMA = SA.ID_CINEMA
        AND CIN.FLG_VIRTUALE = 'N'
        AND SC.ID_SALA = SA.ID_SALA
        AND PRO.ID_SCHERMO = SC.ID_SCHERMO
        AND PS.ID_PROIEZIONE  = PRO.ID_PROIEZIONE
        AND SPE.ID_SPETTACOLO = v_id_spettacolo 
        AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
        MINUS
        SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
        FROM CD_CINEMA CIN, CD_SALA SA, CD_COMUNICATO COM
        WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND COM.FLG_ANNULLATO = 'N'
        AND COM.FLG_SOSPESO = 'N'
        AND COM.COD_DISATTIVAZIONE IS NULL
        AND SA.ID_SALA = COM.ID_SALA
        AND CIN.ID_CINEMA = SA.ID_CINEMA
        AND (CIN.FLG_VIRTUALE = 'S'
            OR SA.ID_SALA IN
            (
                SELECT SC.ID_SALA
                FROM CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                CD_PROIEZIONE PRO, CD_SCHERMO SC
                WHERE SC.ID_SALA = SA.ID_SALA
                AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                AND PRO.DATA_PROIEZIONE = COM.DATA_EROGAZIONE_PREV
                AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO    
                AND SPE.ID_SPETTACOLO != v_id_spettacolo
            )
        )
        )
        GROUP BY DATA_EROGAZIONE_PREV
        UNION
        select 0 AS SALE, DATA_EROGAZIONE_PREV
         from
         (
         select v_data_fine -(v_data_fine - v_data_inizio +1) + rownum as DATA_EROGAZIONE_PREV
         from all_objects
         where rownum <=v_data_fine - v_data_inizio +1
         )
         )
         GROUP BY DATA_EROGAZIONE_PREV
         ORDER BY DATA_EROGAZIONE_PREV;
         IF v_num_schermi > v_numero_massimo_schermi THEN
            v_num_schermi := v_numero_massimo_schermi;
         END IF; --Si venderanno sempre gli schemi effettivamente venduti
   
   end if;
    RETURN v_num_schermi;
END OFU_GET_NUM_SCHERMI_SEGUI_FILM;



------------------

procedure pr_espropria_posizione(p_posizione cd_comunicato.posizione%type,
                                 p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, 
                                 p_id_break cd_break.id_break%type) is                                       
begin
for c in(
SELECT com2.posizione, com2.id_comunicato
FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
AND COM2.POSIZIONE <> 1 AND COM2.POSIZIONE <> 2
AND COM2.POSIZIONE <= p_posizione
AND COM2.FLG_ANNULLATO = 'N'
AND COM2.FLG_SOSPESO = 'N'
AND COM2.COD_DISATTIVAZIONE IS NULL
AND PA.STATO_DI_VENDITA = 'PRE'
AND PA.FLG_ANNULLATO = 'N'
AND PA.FLG_SOSPESO = 'N'
AND PA.COD_DISATTIVAZIONE IS NULL
AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
AND BR.ID_BREAK = CBR.ID_BREAK
AND BR.ID_BREAK = p_id_break
order by posizione desc)
loop
    update cd_comunicato
    set posizione = c.posizione - 1
    where id_comunicato = c.id_comunicato;
end loop;

   
exception 
when others then
   raise;               
end  pr_espropria_posizione;





PROCEDURE PR_IMPOSTA_POSIZIONE(
                                p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                p_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE,
                                p_posizione cd_comunicato.POSIZIONE%type
                                ) IS
v_pos CD_COMUNICATO.POSIZIONE%TYPE;
v_pos_vuota CD_COMUNICATO.POSIZIONE%TYPE;
v_pos_rigore CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_num_pos_rigore NUMBER;
v_pos_rig_temp CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_trovato BOOLEAN;
v_pos_assegnata number;
BEGIN
      
   SAVEPOINT PR_IMPOSTA_POSIZIONE;
--
   SELECT DISTINCT NVL(POSIZIONE_DI_RIGORE,0)
   INTO v_pos_rigore
   FROM CD_COMUNICATO
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;

    --dbms_output.put_line('v_pos_rigore:'||v_pos_rigore);
--
   FOR COM IN(SELECT COM.ID_COMUNICATO, COM.ID_BREAK_VENDITA, COM.POSIZIONE, BR.ID_BREAK
            FROM
            CD_BREAK BR,
            CD_CIRCUITO_BREAK CBR,
            CD_BREAK_VENDITA BRV,
            CD_COMUNICATO COM
            WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND (p_id_comunicato IS NULL OR COM.ID_COMUNICATO = p_id_comunicato)
            AND COM.FLG_ANNULLATO = 'N'
            AND COM.FLG_SOSPESO = 'N'
            AND COM.COD_DISATTIVAZIONE IS NULL
            AND COM.DATA_EROGAZIONE_PREV >= TRUNC(SYSDATE)
            AND BRV.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
            AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
            AND BR.ID_BREAK = CBR.ID_BREAK
            )LOOP
--
             --dbms_output.PUT_LINE('Id comunicato nuovo: '||COM.ID_COMUNICATO);
             --dbms_output.PUT_LINE('Id break: '||COM.ID_BREAK);
       IF v_pos_rigore <> 0 THEN
           FOR COM_BREAK IN (SELECT COM2.ID_COMUNICATO, COM2.POSIZIONE, BR.ID_BREAK
           FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
          -- WHERE COM2.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
           WHERE COM2.FLG_ANNULLATO = 'N'
           AND COM2.FLG_SOSPESO = 'N'
           AND COM2.COD_DISATTIVAZIONE IS NULL
           AND COM2.POSIZIONE <= v_pos_rigore
           AND COM2.POSIZIONE <> 1 AND COM2.POSIZIONE <> 2
           AND COM2.POSIZIONE_DI_RIGORE IS NULL
           AND PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
           AND PA.FLG_ANNULLATO = 'N'
           AND PA.FLG_SOSPESO = 'N'
           AND PA.COD_DISATTIVAZIONE IS NULL
           AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
           AND PA.STATO_DI_VENDITA = 'PRE'
           AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
           AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
           AND BR.ID_BREAK = CBR.ID_BREAK
           AND BR.ID_BREAK = COM.ID_BREAK
           ORDER BY COM2.POSIZIONE DESC)LOOP
                --dbms_output.put_line('ID_COMUNICATO:'||COM_BREAK.ID_COMUNICATO);
                --dbms_output.put_line('ID_BREAK:'||COM_BREAK.ID_BREAK);
                --dbms_output.put_line('Posizione nel break:'||COM_BREAK.POSIZIONE);
                v_trovato := FALSE;
                v_pos := v_pos_rigore;
                FOR POS IN (SELECT ID_COMUNICATO, POSIZIONE, POSIZIONE_DI_RIGORE
                --INTO v_pos
                            FROM CD_COMUNICATO C, CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA
                            --WHERE C.ID_BREAK_VENDITA = COM_BREAK.ID_BREAK_VENDITA
                            WHERE C.ID_COMUNICATO <> COM_BREAK.ID_COMUNICATO
                            AND C.FLG_ANNULLATO = 'N'
                            AND C.FLG_SOSPESO = 'N'
                            AND C.COD_DISATTIVAZIONE IS NULL
                            AND C.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                            --AND C.POSIZIONE_DI_RIGORE IS NULL
                            AND C.POSIZIONE < COM_BREAK.POSIZIONE
                            AND PA.STATO_DI_VENDITA = 'PRE'
                            AND PA.FLG_ANNULLATO = 'N'
                            AND PA.FLG_SOSPESO = 'N'
                            AND PA.COD_DISATTIVAZIONE IS NULL
                            AND BRV.ID_BREAK_VENDITA = C.ID_BREAK_VENDITA
                            AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                            AND BR.ID_BREAK = CBR.ID_BREAK
                            AND BR.ID_BREAK = COM_BREAK.ID_BREAK
                            ORDER BY C.POSIZIONE DESC)LOOP
                v_pos := POS.POSIZIONE;
                IF POS.POSIZIONE_DI_RIGORE IS NULL THEN
                    v_trovato := TRUE;
                    EXIT;
                END IF;

                END LOOP;
                IF v_trovato = FALSE THEN
                    --v_pos := v_pos -1;
                    v_pos := COM_BREAK.POSIZIONE -1;
                END IF;
                --dbms_output.put_line('Nuova Posizione:'||v_pos);
                UPDATE
                CD_COMUNICATO
                SET POSIZIONE = v_pos
                WHERE ID_COMUNICATO = COM_BREAK.ID_COMUNICATO;
                --AND POSIZIONE != v_pos;
           END LOOP;

           UPDATE CD_COMUNICATO
           SET POSIZIONE = v_pos_rigore
           WHERE CD_COMUNICATO.ID_COMUNICATO = COM.ID_COMUNICATO;
           --AND POSIZIONE != v_pos_rigore;
       ELSE
           v_pos_vuota := 91;
           v_pos := 90;
           FOR POS_RIG IN (SELECT POSIZIONE,POSIZIONE_DI_RIGORE
           FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
           WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
           AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
           --AND COM2.POSIZIONE_DI_RIGORE IS NOT NULL
           AND COM2.POSIZIONE >= 85
           AND COM2.FLG_ANNULLATO = 'N'
           AND COM2.FLG_SOSPESO = 'N'
           AND COM2.COD_DISATTIVAZIONE IS NULL
           AND PA.STATO_DI_VENDITA = 'PRE'
           AND PA.FLG_ANNULLATO = 'N'
           AND PA.FLG_SOSPESO = 'N'
           AND PA.COD_DISATTIVAZIONE IS NULL
           AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
           AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
           AND BR.ID_BREAK = CBR.ID_BREAK
           AND BR.ID_BREAK = COM.ID_BREAK
           ORDER BY POSIZIONE DESC) LOOP
                IF POS_RIG.POSIZIONE != v_pos THEN
                    --EXIT;
                    SELECT COUNT(1)
                    INTO v_num_pos_rigore
                    FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
                   WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
                   AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
                   AND COM2.POSIZIONE_DI_RIGORE IS NOT NULL
                   AND COM2.POSIZIONE <= POS_RIG.POSIZIONE
                   AND COM2.POSIZIONE > 2
                   AND COM2.FLG_ANNULLATO = 'N'
                   AND COM2.FLG_SOSPESO = 'N'
                   AND COM2.COD_DISATTIVAZIONE IS NULL
                   AND PA.STATO_DI_VENDITA = 'PRE'
                   AND PA.FLG_ANNULLATO = 'N'
                   AND PA.FLG_SOSPESO = 'N'
                   AND PA.COD_DISATTIVAZIONE IS NULL
                   AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
                   AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
                   AND BR.ID_BREAK = CBR.ID_BREAK
                   AND BR.ID_BREAK = COM.ID_BREAK;
                   --
                   --dbms_output.PUT_LINE('Num pos rigore: '||v_num_pos_rigore);
                   --dbms_output.PUT_LINE('Posizione: '||POS_RIG.POSIZIONE);
                   IF v_num_pos_rigore > 0 THEN
                        v_pos_vuota := v_pos;
                        EXIT;
                   END IF;
                   --
                END IF;
                v_pos := POS_RIG.POSIZIONE -1;
           END LOOP;
           --dbms_output.PUT_LINE('Posizione vuota:'||v_pos_vuota);
           IF v_pos_vuota != 91 THEN
                v_pos := v_pos_vuota;
                --dbms_output.PUT_LINE('Rilevato buco; v_pos:'||v_pos);
           ELSE
               SELECT NVL(MIN(POSIZIONE),91)
               INTO v_pos
               FROM CD_BREAK BR, CD_CIRCUITO_BREAK CBR, CD_BREAK_VENDITA BRV, CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO COM2
               WHERE PA.ID_PRODOTTO_ACQUISTATO = COM2.ID_PRODOTTO_ACQUISTATO
               AND PA.ID_PRODOTTO_ACQUISTATO <> p_id_prodotto_acquistato
               AND COM2.POSIZIONE <> 1 AND COM2.POSIZIONE <> 2
               AND COM2.FLG_ANNULLATO = 'N'
               AND COM2.FLG_SOSPESO = 'N'
               AND COM2.COD_DISATTIVAZIONE IS NULL
               AND PA.STATO_DI_VENDITA = 'PRE'
               AND PA.FLG_ANNULLATO = 'N'
               AND PA.FLG_SOSPESO = 'N'
               AND PA.COD_DISATTIVAZIONE IS NULL
               AND BRV.ID_BREAK_VENDITA = COM2.ID_BREAK_VENDITA
               AND CBR.ID_CIRCUITO_BREAK = BRV.ID_CIRCUITO_BREAK
               AND BR.ID_BREAK = CBR.ID_BREAK
               AND BR.ID_BREAK = COM.ID_BREAK;
            --
                         
              if v_pos = 91 or v_pos - 1 >= p_posizione then --verifico se e l'unico comunicato nel break
                    v_pos := v_pos - 1;
              else
                 --scalo tutti i comunicati di una posizione  e  
                 --esproprio la posizione al comunicato che ha la mia desiderata
                 v_pos := p_posizione;
                 pr_espropria_posizione(p_posizione,p_id_prodotto_acquistato, com.id_break);
              end if;   
            --dbms_output.PUT_LINE('Non e stato rilevato buco; v_pos:'||v_pos);
           END IF;
           --dbms_output.PUT_LINE('Posizione del comunicato:'||v_pos);
           UPDATE CD_COMUNICATO
           SET POSIZIONE = v_pos
           WHERE CD_COMUNICATO.ID_COMUNICATO = COM.ID_COMUNICATO;
           --AND POSIZIONE != v_pos;
        --
         END IF;
   END LOOP;  
   EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'PROCEDURE PR_IMPOSTA_POSIZIONE: Si e'' verificato un errore  '||SQLERRM);
    ROLLBACK TO PR_IMPOSTA_POSIZIONE;
END PR_IMPOSTA_POSIZIONE;

function fu_get_nome_spettacolo(p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_spettacolo.NOME_SPETTACOLO%type is
v_nome_spettacolo cd_spettacolo.nome_spettacolo%type;
begin

select spet.nome_spettacolo 
into v_nome_spettacolo
from cd_prodotto_acquistato pa, cd_prodotto_vendita pv,cd_spettacolo spet
where pa.id_prodotto_vendita = pv.id_prodotto_vendita
and   pv.flg_segui_il_film = 'S'
and   spet.id_spettacolo = pa.id_spettacolo
and   pa.flg_annullato ='N'
and   pa.flg_sospeso ='N'
and   pa.cod_disattivazione is null
and   pa.id_prodotto_acquistato = p_id_prodotto_acquistato;
return v_nome_spettacolo;
end fu_get_nome_spettacolo;



function fu_get_numero_massimo_schermi(p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type) return cd_prodotto_acquistato.numero_massimo_schermi%type is
v_numero_massimo_schermi cd_prodotto_acquistato.numero_massimo_schermi%type;
begin

select numero_massimo_schermi 
into v_numero_massimo_schermi
from cd_prodotto_acquistato pa
where   pa.flg_annullato ='N'
and   pa.flg_sospeso ='N'
and   pa.cod_disattivazione is null
and   pa.id_prodotto_acquistato = p_id_prodotto_acquistato;
return v_numero_massimo_schermi;
end fu_get_numero_massimo_schermi;


procedure pr_modifica_spettacolo (p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type, p_id_spettacolo cd_spettacolo.id_spettacolo%type, p_numero_massimo_schermi cd_prodotto_acquistato.numero_massimo_schermi%type) is
begin
update cd_prodotto_acquistato 
set id_spettacolo = p_id_spettacolo,
    numero_massimo_schermi = p_numero_massimo_schermi
where id_prodotto_acquistato = p_id_prodotto_acquistato;
end;


function fu_get_spettacolo_associato(p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type) return char is
v_numero_occorrenze char(1);
begin

select decode(count(1),0,'N','S')
into v_numero_occorrenze
from cd_sala_segui_film
where id_prodotto_acquistato = p_id_prodotto_acquistato;
return v_numero_occorrenze;

end fu_get_spettacolo_associato;


-----------------------------------------------------------------------------------------------------
-- Funzione PR_RECUPERA_PRODOTTI_SPECIALI
--
-- DESCRIZIONE:  Effettua la creazione di prodotti a target/Segui il film il cui numero di sale ottenute risulta essere minore del richiesto.
--               I prodotti, che devono essere prenotati, vengono ricercati nell'intervallo compreso fra le due date di input.
--
-- OPERAZIONI:
--
--  INPUT:
--   p_data_inizio, p_data_fine data inizio e fine dei ricerca dei prodotti. 
---  numero di sale del prodotto
--  OUTPUT: 
--
-- REALIZZATORE: Mauro Viel  , Altran, Marzo    2011
--
-- NOTE:  
--
--  MODIFICHE:
--           
--            
--
-------------------------------------------------------------------------------------------------





PROCEDURE PR_RECUPERA_PRODOTTI_SPECIALI(P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) IS

v_numero_sale NUMBER;
BEGIN
   
   for pa in 
   (
   select  PA.DATA_INIZIO,PA.DATA_FINE,pa.id_prodotto_acquistato, nvl(numero_massimo_schermi,80) as numero_schermi_attesi,fu_get_num_schermi_target(pa.id_prodotto_acquistato,pv.id_target,'S') as numero_schermi_ottenuti
    from   cd_prodotto_acquistato pa ,cd_prodotto_vendita pv
    where  pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and    pa.stato_di_vendita    ='PRE'
    and    pv.id_target is not null 
    and    pa.flg_annullato ='N'
    and    pa.FLG_SOSPESO ='N'
    and    pa.COD_DISATTIVAZIONE is  null
    and    pv.flg_annullato ='N'
    --and    pa.data_fine < trunc(sysdate)
    and    pa.data_inizio = p_data_inizio
    and    pa.data_fine = p_data_fine
    union 
    select  PA.DATA_INIZIO,PA.DATA_FINE,pa.id_prodotto_acquistato, numero_massimo_schermi as numero_schermi_attesi, fu_get_num_schermi_segui_film(pa.id_prodotto_acquistato,'S') as numero_schermi_ottenuti
    from   cd_prodotto_acquistato pa ,cd_prodotto_vendita pv
    where  pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and    pa.stato_di_vendita    ='PRE'
    and    pv.FLG_SEGUI_IL_FILM ='S'
    and    pa.flg_annullato ='N'
    and    pa.FLG_SOSPESO ='N'
    and    pa.COD_DISATTIVAZIONE is  null
    and    pv.flg_annullato ='N'
    --and    pa.data_fine < trunc(sysdate)
    and    pa.data_inizio = p_data_inizio
    and    pa.data_fine = p_data_fine
   )
   LOOP
        v_numero_sale := pa.numero_schermi_attesi - pa.numero_schermi_ottenuti;
            
        if v_numero_sale = 0 then
             v_numero_sale := pa.numero_schermi_attesi;
        end if;
        
        --pr_recupera_prodotto_speciale(pa.id_prodotto_acquistato, v_numero_sale ,pa.numero_schermi_ottenuti );
        pr_recupera_prodotto_speciale(pa.id_prodotto_acquistato, v_numero_sale,null,null);
   END LOOP;


   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END PR_RECUPERA_PRODOTTI_SPECIALI;



-----------------------------------------------------------------------------------------------------
-- Funzione PR_CORREGGI_IMP_RECUPERO_SPEC
--
-- DESCRIZIONE:  Effettua la correzioen degli importi dopo la creazioen del prodotto. La procedura deve essere differenziata dalla
--               correggi importi perche i prodotti target e segui il film vengono recuperati durante il perisodo di trasmissione
--               l'importo saltato non e ancora definito.
--
-- OPERAZIONI:
--
--
-- REALIZZATORE: Mauro Viel  , Altran, aprile    2011
--
-- NOTE:  
--
--  MODIFICHE:
--           
--            
--
-------------------------------------------------------------------------------------------------


PROCEDURE PR_CORREGGI_IMP_RECUPERO_SPEC(p_id_prodotto_originale CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_id_prodotto_recupero CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_list_maggiorazioni id_list_type) IS
--
--v_lordo_tot                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE := p_lordo_comm_tot + p_lordo_dir_tot;
--v_netto_tot                 CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE := p_netto_comm_tot + p_netto_dir_tot;
v_lordo_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_coeff_ripartizione        NUMBER;
v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto                     CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
v_id_importo_prodotto_c     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_importo_prodotto_d     CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_lordo_saltato             CD_PRODOTTO_ACQUISTATO.IMP_LORDO_SALTATO%TYPE;
v_lordo_saltato_comm        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
v_lordo_saltato_dir         CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
p_esito NUMBER;
v_pos_rigore                CD_COMUNICATO.POSIZIONE_DI_RIGORE%TYPE;
v_id_formato                CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_tariffa_variabile         CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE;
v_lordo_dir_orig            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm_orig         NUMBER;
v_perc_sc_dir_orig          NUMBER;
--v_recuperato                NUMBER;
BEGIN

   SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, ID_FORMATO, FLG_TARIFFA_VARIABILE, IMP_LORDO_SALTATO
    INTO v_lordo, v_netto, v_maggiorazione, v_sanatoria, v_recupero, v_tariffa,  v_id_formato, v_tariffa_variabile, v_lordo_saltato
    FROM CD_PRODOTTO_ACQUISTATO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero;
    --
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
    INTO v_id_importo_prodotto_c, v_netto_comm, v_imp_sc_comm, v_lordo_comm
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
    AND TIPO_CONTRATTO = 'C';
    --
    SELECT ID_IMPORTI_PRODOTTO, IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
    INTO v_id_importo_prodotto_d, v_netto_dir, v_imp_sc_dir, v_lordo_dir
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_recupero
    AND TIPO_CONTRATTO = 'D';
    --v_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_comm,v_imp_sc_comm);
    --v_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(v_netto_dir,v_imp_sc_dir);

    SELECT IMP_LORDO_SALTATO, PERC_SC_ORIG
    INTO v_lordo_saltato_comm, v_perc_sc_comm_orig
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
    AND TIPO_CONTRATTO = 'C';

    SELECT IMP_NETTO + IMP_SC_COMM, IMP_LORDO_SALTATO, PERC_SC_ORIG
    INTO v_lordo_dir_orig, v_lordo_saltato_dir, v_perc_sc_dir_orig
    FROM CD_IMPORTI_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
    AND TIPO_CONTRATTO = 'D';
    v_lordo_saltato_dir := LEAST(v_lordo_saltato_dir, v_lordo);
    --v_lordo_dir_orig := v_lordo_dir_orig / FU_GET_NUM_AMBIENTI(p_id_prodotto_originale) * FU_GET_NUM_AMBIENTI(p_id_prodotto_recupero);
    --v_lordo_dir_orig := ROUND(v_lordo_dir_orig,2);
       SELECT DISTINCT POSIZIONE_DI_RIGORE
            INTO v_pos_rigore
            FROM CD_COMUNICATO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale;
    --
    /*dbms_output.PUT_LINE('v_lordo_dir_orig: '||v_lordo_dir_orig);
    dbms_output.PUT_LINE('v_tariffa: '||v_tariffa);
    dbms_output.PUT_LINE('v_maggiorazione: '||v_maggiorazione);
    dbms_output.PUT_LINE('v_lordo: '||v_lordo);
    dbms_output.PUT_LINE('v_lordo_comm: '||v_lordo_comm);
    dbms_output.PUT_LINE('v_lordo_dir: '||v_lordo_dir);
    dbms_output.PUT_LINE('v_netto_comm: '||v_netto_comm);
    dbms_output.PUT_LINE('v_netto_dir: '||v_netto_dir);
    dbms_output.PUT_LINE('v_perc_sc_comm: '||v_perc_sc_comm);
    dbms_output.PUT_LINE('v_perc_sc_dir: '||v_perc_sc_dir);
    dbms_output.PUT_LINE('v_imp_sc_comm: '||v_imp_sc_comm);
    dbms_output.PUT_LINE('v_imp_sc_dir: '||v_imp_sc_dir);
    dbms_output.PUT_LINE('v_sanatoria: '||v_sanatoria);
    dbms_output.PUT_LINE('v_recupero: '||v_recupero);
    */
    dbms_output.PUT_LINE('v_lordo_saltato_dir: '||v_lordo_saltato_dir);
    IF v_lordo_saltato_dir > 0 THEN
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                            v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                            v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                            v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_saltato_dir,'22',p_esito);

        IF v_perc_sc_dir_orig != v_perc_sc_dir THEN
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_perc_sc_dir_orig,'42',p_esito);
        END IF;

    END IF;
    --
    /*PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                    v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                    v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                    v_imp_sc_dir,v_sanatoria,v_recupero,v_lordo_dir,'22',p_esito);*/
    IF v_perc_sc_comm_orig != v_perc_sc_comm THEN
        PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
                        v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
                        v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
                        v_imp_sc_dir,v_sanatoria,v_recupero,v_perc_sc_comm_orig,'41',p_esito);

    --
    END IF;
    MODIFICA_PRODOTTO_ACQUISTATO(p_id_prodotto_recupero,
                'OPZ',
                v_tariffa,
                v_lordo,
                v_sanatoria,
                v_recupero,
                v_maggiorazione,
                v_netto_comm,
                v_imp_sc_comm,
                v_netto_dir,
                v_imp_sc_dir,
                v_pos_rigore,
                v_id_formato,
                v_tariffa_variabile,
                v_lordo_saltato,
                p_list_maggiorazioni);

     PR_MODIFICA_STATO_VENDITA(p_id_prodotto_recupero,'ACO');
     PR_MODIFICA_STATO_VENDITA(p_id_prodotto_recupero,'PRE');
     --
     INSERT INTO CD_RECUPERO_PRODOTTO(ID_PRODOTTO_SALTATO, ID_PRODOTTO_RECUPERO,
     DATA_RECUPERO, TIPO_CONTRATTO,QUOTA_PARTE)
     VALUES(p_id_prodotto_originale,p_id_prodotto_recupero, sysdate, 'C', v_lordo_comm);
     INSERT INTO CD_RECUPERO_PRODOTTO(ID_PRODOTTO_SALTATO, ID_PRODOTTO_RECUPERO,
     DATA_RECUPERO, TIPO_CONTRATTO, QUOTA_PARTE)
     VALUES(p_id_prodotto_originale,p_id_prodotto_recupero, sysdate, 'D',v_lordo_dir);
     
     
     --
     
     UPDATE CD_IMPORTI_PRODOTTO
     SET IMP_LORDO_SALTATO =  v_lordo_comm
     WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
     AND TIPO_CONTRATTO = 'C';
     UPDATE CD_IMPORTI_PRODOTTO
     SET IMP_LORDO_SALTATO =  v_lordo_dir
     WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_originale
     AND TIPO_CONTRATTO = 'D';
    --
END  PR_CORREGGI_IMP_RECUPERO_SPEC;



-----------------------------------------------------------------------------------------------------
-- Funzione PR_RECUPERA_PRODOTTO_SPECIALE
--
-- DESCRIZIONE:  Effettua la creazione di un prodotto con le stesse caratteristiche 
--               del prodotto di origine con un numero di sale uguale al numero inputato.
--               Se non viene indicato un periodo (p_data_inizio e p_data_fine non valorizzate) la procedura genera
--               il prodotto nel periodo successivo a quello indicato.
-- OPERAZIONI:
--
--  INPUT:
--   P_ID_PRODOTTO_ACQUISTATO id del prodotto d'origine, P_NUMERO_SALE numero di sale che avra il prodotto
---  P_data_inizio, p_data_fine l'inervallo di tempo in cui verra creato il prodotto; se non specificato sara
--   il periodo immediatamente successivo a quello del prodotto d'origine.
--  OUTPUT: 
--
-- REALIZZATORE: Mauro Viel  , Altran, Marzo    2011
--
-- NOTE:  
--
--  MODIFICHE: Mauro Viel Altran Italia Ottobre 2011: 
--                                        Sostituita la chiamata alla proceura PA_PC_IMPORTI.FU_PERC_SC_COMM 
--                                        con PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA
--                                        in modo da ottenere il numero massimo di decimali per scongiurare 
--                                        problemi di arrotondamento.  
--           
--            
--
-------------------------------------------------------------------------------------------------
--PROCEDURE PR_RECUPERA_PRODOTTO_SPECIALE(P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, P_NUMERO_SALE NUMBER,P_NUMERO_SCHERMI_OTTENUTI NUMBER) IS
PROCEDURE PR_RECUPERA_PRODOTTO_SPECIALE(P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, P_NUMERO_SALE NUMBER,P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE, P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE ) IS


V_NETTO_COMM NUMBER;
V_NETTO_DIR  NUMBER;
V_PERC_SCONTO_COMM NUMBER;
V_PERC_SCONTO_DIR  NUMBER;
V_ID_AMBITO NUMBER := 1;
v_id_prodotto_acquistato     CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;      
v_esito                  NUMBER;
v_id_spettacolo         CD_PRODOTTO_ACQUISTATO.ID_SPETTACOLO%TYPE;
v_list_maggiorazioni id_list_type;
v_ind_maggiorazioni NUMBER;
--v_numero_sale NUMBER;
v_posizione_rigore cd_posizione_rigore.COD_POSIZIONE%type;

v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_tariffa_originale CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_maggiorazione CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE := 0;
v_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_imp_sc_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_sconto_stagionale CD_SCONTO_STAGIONALE.PERC_SCONTO%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE;
v_tariffa CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_id_formato       cd_prodotto_acquistato.id_formato%type;
v_data_inizio   cd_prodotto_acquistato.data_inizio%type;
v_data_fine     cd_prodotto_acquistato.data_fine%type;
v_gg_prodotto   number;
v_id_piano      cd_prodotto_acquistato.id_piano%type;
v_id_ver_piano  cd_prodotto_acquistato.id_ver_piano%type;
v_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE;

v_id_unita_misura_temp   cd_unita_misura_temp.id_unita%type;
v_id_misura_prd_ve cd_misura_prd_vendita.id_misura_prd_ve%type;
v_id_listino   cd_listino.ID_LISTINO%type;
v_id_importi_richiesti_piano cd_importi_richiesti_piano.id_importi_richiesti_piano%type;
v_periodo PERIODO;
v_settimana_sipra number;
v_flg_segui_il_film cd_prodotto_vendita.flg_segui_il_film%type;

--v_numero_schermi_ottenuti number;

BEGIN

-----------------------------------
            
           DBMS_OUTPUT.PUT_LINE('p_id_prodotto_acquistato:'||p_id_prodotto_acquistato);

            
            /*31/03/2011 commentato per richiesta di Luigi Cipolla i prodotti posso avere tariffe differenti.
            v_numero_schermi_ottenuti:= p_numero_schermi_ottenuti;
            
            if v_numero_schermi_ottenuti is null or v_numero_schermi_ottenuti = 0  then
                v_numero_schermi_ottenuti:= fu_get_num_ambienti(p_id_prodotto_acquistato);
            end if;
            */
            
    
   
            SELECT IMP_NETTO
            INTO   V_NETTO_COMM
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
            AND TIPO_CONTRATTO = 'C';
            
            SELECT IMP_NETTO
            INTO   V_NETTO_DIR
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
            AND TIPO_CONTRATTO = 'D';
            
            SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(IMP_NETTO,IMP_SC_COMM) 
            INTO   V_PERC_SCONTO_COMM
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
            AND TIPO_CONTRATTO = 'C';
             
            SELECT PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(IMP_NETTO,IMP_SC_COMM)
            INTO   V_PERC_SCONTO_DIR
            FROM CD_IMPORTI_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
            AND TIPO_CONTRATTO = 'D'; 
            
             FOR MAG IN (SELECT * FROM CD_MAGG_PRODOTTO
                        WHERE ID_PRODOTTO_ACQUISTATO =p_id_prodotto_acquistato) LOOP
                v_list_maggiorazioni.EXTEND;
                v_list_maggiorazioni(v_ind_maggiorazioni) := MAG.ID_MAGGIORAZIONE;
                v_ind_maggiorazioni := v_ind_maggiorazioni +1;
            END LOOP;
            
           
            
            
            select data_inizio,data_fine,imp_tariffa,id_formato,id_prodotto_vendita,id_piano,id_ver_piano,id_tipo_cinema,id_spettacolo,id_misura_prd_ve 
            into   v_data_inizio,v_data_fine,v_tariffa_originale,v_id_formato,v_id_prodotto_vendita,v_id_piano,v_id_ver_piano,v_id_tipo_cinema,v_id_spettacolo,v_id_misura_prd_ve --,v_numero_massimo_schermi  
            from   cd_prodotto_acquistato 
            where  id_prodotto_acquistato = p_id_prodotto_acquistato;
            
            select id_unita 
            into v_id_unita_misura_temp
            from cd_misura_prd_vendita
            where id_misura_prd_ve = v_id_misura_prd_ve;
            
            select distinct posizione_di_rigore
            into v_posizione_rigore
            from cd_comunicato
            where id_prodotto_acquistato = p_id_prodotto_acquistato
            and   flg_annullato ='N'
            and   flg_sospeso ='N'
            and   cod_disattivazione is null;
            
          
            if p_data_inizio is null and p_data_fine is null then
                v_gg_prodotto :=  v_data_fine - v_data_inizio +1;
                v_data_inizio :=  v_data_fine+1;
                v_data_fine   :=  v_data_fine+v_gg_prodotto;
            else
                v_data_inizio :=  p_data_inizio;
                v_data_fine   :=  p_data_fine;
            end if;
              
           
            DBMS_OUTPUT.PUT_LINE('v_id_prodotto_vendita'||v_id_prodotto_vendita||'v_id_misura_prd_ve:'||v_id_misura_prd_ve ||',v_data_inizio:'||v_data_inizio||',v_data_fine:'||v_data_fine);   


            --RICERCO UNA tariffa e un listino valido per il prodotto 
            --nel caso di prodotti segui il film, che si basano su periodi speciali un prodotto a recupero potrebbe trovasi a cavallo di 
            -- due listini. in tal caso la procedura non e in grado di effettuare il recupero.
            begin
                select tar.id_listino, tar.id_tariffa,pv.flg_segui_il_film
                into v_id_listino, v_id_tariffa,v_flg_segui_il_film
                from cd_tariffa tar, 
                cd_prodotto_vendita pv
                where tar.id_prodotto_vendita = pv.id_prodotto_vendita
                and   pv.id_prodotto_vendita  = v_id_prodotto_vendita
                and tar.id_misura_prd_ve= v_id_misura_prd_ve
                and tar.data_inizio <= v_data_inizio
                and tar.data_fine >= v_data_fine;
                exception
                    when no_data_found then
                        RAISE_APPLICATION_ERROR(-20026, 'Impossibile recuperare uno o piu prodotti perche il prodotto a recupero si trova a cavallo di due listini');
           end;
            
            v_sconto_stagionale := PA_CD_ESTRAZIONE_PROD_VENDITA.FU_GET_SCONTO_STAGIONALE(v_id_prodotto_vendita, v_data_inizio, v_data_fine, v_id_formato, v_id_misura_prd_ve);
            v_tariffa := PA_CD_UTILITY.FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(v_id_tariffa, v_id_formato),v_sconto_stagionale);
            
            /*31/03/2011 commentato per richiesta di Luigi Cipolla i prodotti posso avere tariffe differenti.
            v_tariffa_originale := v_tariffa_originale /v_numero_schermi_ottenuti;---FUNZIONA SE E STATO FATTO IL RICALCOLA TARIFFA
            
    --
            IF v_tariffa = v_tariffa_originale THEN
                v_tariffa := v_tariffa_originale;
            else
               
                RAISE_APPLICATION_ERROR(-20026, 'Recupero prodotto non eseguito perche il prodotto saltato e quello a recupero hanno tariffe differenti');    
            end if;  
            
            */
            
   
           v_tariffa := v_tariffa * p_numero_sale;
           FOR MAGG IN (SELECT MAG.PERCENTUALE_VARIAZIONE FROM CD_MAGGIORAZIONE MAG, CD_MAGG_PRODOTTO MP
                         WHERE MP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                         AND MAG.ID_MAGGIORAZIONE = MP.ID_MAGGIORAZIONE) LOOP
                --
                v_maggiorazione := ROUND(v_maggiorazione + (v_tariffa * MAGG.PERCENTUALE_VARIAZIONE / 100),2);
            END LOOP;
          
            v_lordo := v_tariffa + v_maggiorazione;
            v_imp_sc_comm := PA_PC_IMPORTI.FU_SCONTO_COMM_3(v_lordo,V_PERC_SCONTO_COMM);
            
            
            --DBMS_OUTPUT.PUT_LINE('4');
            
            SELECT count(ID_IMPORTI_RICHIESTI_PIANO)
            INTO  v_id_importi_richiesti_piano
            FROM
            ( 
                 SELECT ID_IMPORTI_RICHIESTI_PIANO
                 FROM CD_IMPORTI_RICHIESTI_PIANO IRP, PERIODI PER
                 WHERE ID_PIANO = v_id_piano
                 AND ID_VER_PIANO = v_id_ver_piano
                 AND FLG_ANNULLATO = 'N'
                 AND PER.ANNO = IRP.ANNO
                 AND PER.CICLO = IRP.CICLO
                 AND PER.PER = IRP.PER
                 AND PER.DATA_INIZ = v_data_inizio
                 AND PEr.DATA_FINE = v_data_fine
                 UNION
                 SELECT ID_IMPORTI_RICHIESTI_PIANO
                 FROM CD_IMPORTI_RICHIESTI_PIANO IRP, CD_PERIODO_SPECIALE PS
                 WHERE ID_PIANO = v_id_piano
                 AND ID_VER_PIANO =v_id_ver_piano
                 AND FLG_ANNULLATO = 'N'
                 AND PS.ID_PERIODO_SPECIALE = IRP.ID_PERIODO_SPECIALE
                 AND PS.DATA_INIZIO = v_data_inizio
                 AND PS.DATA_FINE = v_data_fine
                 UNION
                 SELECT ID_IMPORTI_RICHIESTI_PIANO
                 FROM CD_IMPORTI_RICHIESTI_PIANO IRP, CD_PERIODI_CINEMA PC
                 WHERE ID_PIANO = v_id_piano
                 AND ID_VER_PIANO = v_id_ver_piano
                 AND FLG_ANNULLATO = 'N'
                 AND PC.ID_PERIODO = IRP.ID_PERIODO
                 AND PC.DATA_INIZIO = v_data_inizio
                 AND PC.DATA_FINE = v_data_fine
               );
            
             DBMS_OUTPUT.PUT_LINE('v_id_importi_richiesti_piano:'||v_id_importi_richiesti_piano);
            
            if v_id_importi_richiesti_piano = 0 then
              
              v_periodo := periodo(null,null,null,null,null,null,null,null,null); 
              v_periodo.IMPORTOLORDO:=0;
              v_periodo.IMPORTONETTO:=0;
              v_periodo.PERCSCONTO:=0;
              v_periodo.NOTA:=NULL;
              v_periodo.ID_PERIODO:=NULL;
              
              -- VERIFICO SE E' SETTIMANA SIPRA OPPURE PERIODO SPECIALE
              
              select count(1)
              into  v_settimana_sipra
              from periodi
              where data_iniz = v_data_inizio
              and   data_fine = v_data_fine;
              
              
              if  v_settimana_sipra = 0 then
                 --CREO IL PERIODO SPECIALE PERIODO E LO LEGO AL PIANO     
                   insert into cd_periodo_speciale(data_inizio,data_fine)
                   values(v_data_inizio,v_data_fine);
            
                   select CD_PERIODO_SPECIALE_SEQ.CURRVAL
                   into v_periodo.ID_PERIODO_SPECIALE
                   from dual;
                   
              else
                  select anno,ciclo,per
                  into v_periodo.anno,v_periodo.ciclo,v_periodo.per
                  from periodi
                  where data_iniz = v_data_inizio
                  and   data_fine = v_data_fine; 
              end if;
              
              
              
              pa_cd_pianificazione.pr_inserisci_importo_piano(v_id_piano,v_id_ver_piano,v_periodo, v_id_importi_richiesti_piano);
               
            end if;
            
            if v_flg_segui_il_film ='S' then
                pr_crea_prod_modulo_segui_film(v_id_prodotto_vendita,v_id_piano,v_id_ver_piano,v_id_ambito,v_data_inizio,v_data_fine,v_id_formato,v_tariffa,v_lordo,v_lordo,0,v_imp_sc_comm,0,v_maggiorazione,v_id_unita_misura_temp,v_id_listino,p_numero_sale,v_posizione_rigore,'S',v_id_tipo_cinema,v_list_maggiorazioni,id_list_type(),'R',v_id_spettacolo,p_numero_sale,p_numero_sale,v_id_tariffa,v_id_prodotto_acquistato,v_esito);
            else
                pr_crea_prod_acq_modulo(v_id_prodotto_vendita,v_id_piano,v_id_ver_piano,v_id_ambito,v_data_inizio,v_data_fine,v_id_formato,v_tariffa,v_lordo,v_lordo,0,v_imp_sc_comm,0,v_maggiorazione,v_id_unita_misura_temp,v_id_listino,p_numero_sale,v_posizione_rigore,'S',v_id_tipo_cinema,v_list_maggiorazioni,id_list_type(),'R',v_id_spettacolo,p_numero_sale,p_numero_sale,v_id_prodotto_acquistato,v_esito);
            end if;
            PR_CORREGGI_IMP_RECUPERO_SPEC(p_id_prodotto_acquistato,v_id_prodotto_acquistato, v_list_maggiorazioni);
            
            --DBMS_OUTPUT.PUT_LINE('v_id_prodotto_acquistato='||v_id_prodotto_acquistato);
-----------------------------------

END PR_RECUPERA_PRODOTTO_SPECIALE;

FUNCTION FU_ELENCO_PRODOTTI_SPECIALI(P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE, P_STATO_DI_VENDITA CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE ) RETURN  C_PRODOTTO_SPECIALE IS
V_PRODOTTO_SPECIALE C_PRODOTTO_SPECIALE;
BEGIN
OPEN V_PRODOTTO_SPECIALE FOR
    select pa.id_prodotto_acquistato,cliente.RAG_SOC_COGN as cliente,
    pa.id_piano,pa.id_ver_piano,pa.data_inizio,pa.data_fine,spe.nome_spettacolo as TARGET_SPETTACOLO,coef.durata as durata,nvl(numero_massimo_schermi,80) as  num_sale_previste,0 as num_sale_ottenute,decode(rp.ID_PRODOTTO_SALTATO,null,'N','S') as recuperato,pv.id_target--pa_cd_prodotto_acquistato.fu_get_num_ambienti(pa.id_prodotto_acquistato) as num_sale_ottenute,decode(rp.ID_PRODOTTO_SALTATO,null,'N','S') as recuperato
    from cd_prodotto_acquistato pa, cd_prodotto_vendita pv,cd_spettacolo spe,cd_formato_acquistabile fa, cd_coeff_cinema coef,cd_recupero_prodotto rp,interl_u cliente, cd_pianificazione pia
    where pa.flg_annullato ='N'
    and   pa.flg_sospeso ='N'
    and   pa.cod_disattivazione is null
    and   stato_di_vendita = P_STATO_DI_VENDITA --'PRE'
    and   pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and   pv.flg_segui_il_film ='S'
    and   spe.id_spettacolo = pa.ID_SPETTACOLO
    and   pa.data_inizio  = p_data_inizio
    and   pa.data_fine    = nvl(p_data_fine,pa.data_fine)
    and   fa.id_formato = pa.id_formato
    and   coef.id_coeff = fa.id_coeff
    and   pa.ID_PRODOTTO_ACQUISTATO = rp.ID_PRODOTTO_SALTATO (+)
    and   rp.TIPO_CONTRATTO (+) = 'C'    
    and   pia.ID_PIANO = pa.ID_PIANO
    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
    and   cliente.COD_INTERL = pia.ID_CLIENTE
    union
    select pa.id_prodotto_acquistato,cliente.RAG_SOC_COGN as cliente,
    pa.id_piano,pa.id_ver_piano,pa.data_inizio,pa.data_fine,ta.NOME_TARGET as TARGET_SPETTACOLO,coef.durata as durata,nvl(numero_massimo_schermi,80)  as num_sale_previste,0 as num_sale_ottenute,decode(rp.ID_PRODOTTO_SALTATO,null,'N','S') as recuperato,pv.id_target--pa_cd_prodotto_acquistato.fu_get_num_ambienti(pa.id_prodotto_acquistato) as num_sale_ottenute,decode(rp.ID_PRODOTTO_SALTATO,null,'N','S') as recuperato
    from cd_prodotto_acquistato pa, cd_prodotto_vendita pv, cd_target ta,cd_formato_acquistabile fa, cd_coeff_cinema coef,cd_recupero_prodotto rp,interl_u cliente, cd_pianificazione pia
    where pa.flg_annullato ='N'
    and   pa.flg_sospeso ='N'
    and   pa.cod_disattivazione is null
    and   stato_di_vendita = P_STATO_DI_VENDITA--'PRE'
    and   pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and   pv.id_target is not null 
    and   ta.id_target  = pv.id_target
    and   pa.data_inizio  = p_data_inizio
    and   pa.data_fine    = nvl(p_data_fine,pa.data_fine)
    and   fa.id_formato = pa.id_formato
    and   coef.id_coeff = fa.id_coeff
    and   pa.ID_PRODOTTO_ACQUISTATO = rp.ID_PRODOTTO_SALTATO (+)
    and   rp.TIPO_CONTRATTO (+) = 'C'
    and   pia.ID_PIANO = pa.ID_PIANO
    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
    and   cliente.COD_INTERL = pia.ID_CLIENTE
    and   pia.ID_PIANO = pa.ID_PIANO
    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
    and   cliente.COD_INTERL = pia.ID_CLIENTE
    and   not exists --non possono essere recuperati prodotti se esiste gia un prodotto nel periodo successivo 
    (
        select pa1.*
        from   cd_pianificazione pia1, cd_prodotto_vendita pv1, cd_prodotto_acquistato pa1
        where   pia1.id_piano = pa1.id_piano
        and     pia1.id_ver_piano = pa1.id_ver_piano
        and     pa1.id_prodotto_vendita = pv1.id_prodotto_vendita
        and     pv1.id_target = pv.id_target
        and     pia1.id_cliente = pia.id_cliente
        and     pa1.data_inizio = pa.data_fine+1
        and     nvl(pa1.COD_ATTIVAZIONE,'@') != 'R'
        and     pa1.data_fine = pa.data_fine+(pa.data_fine - pa.data_inizio +1)
        and     pa1.flg_annullato ='N'
        and     pa1.flg_sospeso ='N'
        and     pa1.stato_di_vendita = P_STATO_DI_VENDITA--'PRE'
    );
RETURN V_PRODOTTO_SPECIALE; 

END FU_ELENCO_PRODOTTI_SPECIALI;



FUNCTION FU_ELENCO_PROD_SPECIALI_REC(P_DATA_INIZIO CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,P_DATA_FINE CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE, P_STATO_DI_VENDITA CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE ) RETURN  C_PRODOTTO_SPECIALE IS
V_PRODOTTO_SPECIALE C_PRODOTTO_SPECIALE;
BEGIN
OPEN V_PRODOTTO_SPECIALE FOR
    select pa2.id_prodotto_acquistato,cliente.RAG_SOC_COGN as cliente,
    pa2.id_piano,pa2.id_ver_piano,pa2.data_inizio,pa2.data_fine,spe.nome_spettacolo as TARGET_SPETTACOLO,coef.durata as durata,nvl(pa2.numero_massimo_schermi,80)  as num_sale_previste,0 as num_sale_ottenute,'N' as recuperato,pv.id_target--pa_cd_prodotto_acquistato.fu_get_num_ambienti(pa2.id_prodotto_acquistato) as num_sale_ottenute,'N' as recuperato
    from cd_prodotto_acquistato pa, cd_prodotto_vendita pv, cd_spettacolo spe,cd_formato_acquistabile fa, cd_coeff_cinema coef,cd_recupero_prodotto rp, cd_prodotto_acquistato pa2,interl_u cliente, cd_pianificazione pia
    where pa.flg_annullato ='N'
    and   pa.flg_sospeso ='N'
    and   pa.cod_disattivazione is null
    and   pa.stato_di_vendita = P_STATO_DI_VENDITA--'PRE'
    and   pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and   pv.flg_segui_il_film ='S'
    and   spe.id_spettacolo = pa.ID_SPETTACOLO
    and   pa.data_inizio  = p_data_inizio
    and   pa.data_fine    = nvl(p_data_fine,pa.data_fine)
    and   fa.id_formato = pa.id_formato
    and   coef.id_coeff = fa.id_coeff
    and   pa.ID_PRODOTTO_ACQUISTATO = rp.ID_PRODOTTO_SALTATO
    and   rp.TIPO_CONTRATTO = 'C'
    and   pa2.ID_PRODOTTO_ACQUISTATO = rp.ID_PRODOTTO_RECUPERO
    and   pa2.flg_annullato ='N'
    and   pa2.flg_sospeso ='N'
    and   pa2.cod_disattivazione is null
    and   pa2.cod_attivazione = 'R'
    and   pia.ID_PIANO = pa.ID_PIANO
    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
    and   cliente.COD_INTERL = pia.ID_CLIENTE
    union
    select pa2.id_prodotto_acquistato,cliente.RAG_SOC_COGN as cliente,
    pa2.id_piano,pa2.id_ver_piano,pa2.data_inizio,pa2.data_fine,ta.NOME_TARGET as TARGET_SPETTACOLO,coef.durata as durata,nvl(pa2.numero_massimo_schermi,80)  as num_sale_previste,0 as num_sale_ottenute,'N' as recuperato, pv.id_target--pa_cd_prodotto_acquistato.fu_get_num_ambienti(pa2.id_prodotto_acquistato) as num_sale_ottenute,'N' as recuperato
    from cd_prodotto_acquistato pa, cd_prodotto_vendita pv, cd_target ta,cd_formato_acquistabile fa, cd_coeff_cinema coef,cd_recupero_prodotto rp, cd_prodotto_acquistato pa2,interl_u cliente, cd_pianificazione pia
    where pa.flg_annullato ='N'
    and   pa.flg_sospeso ='N'
    and   pa.cod_disattivazione is null
    and   pa.stato_di_vendita = P_STATO_DI_VENDITA--'PRE'
    and   pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and   pv.id_target is not null 
    and   ta.id_target  = pv.id_target
    and   pa.data_inizio  = p_data_inizio
    and   pa.data_fine    = nvl(p_data_fine,pa.data_fine)
    and   fa.id_formato = pa.id_formato
    and   coef.id_coeff = fa.id_coeff
    and   pa.ID_PRODOTTO_ACQUISTATO = rp.ID_PRODOTTO_SALTATO
    and   rp.TIPO_CONTRATTO = 'C'
    and   pa2.ID_PRODOTTO_ACQUISTATO = rp.ID_PRODOTTO_RECUPERO
    and   pa2.flg_annullato ='N'
    and   pa2.flg_sospeso ='N'
    and   pa2.cod_disattivazione is null
    and   pa2.cod_attivazione = 'R'
    and   pia.ID_PIANO = pa.ID_PIANO
    and   pia.ID_VER_PIANO = pa.ID_VER_PIANO
    and   cliente.COD_INTERL = pia.ID_CLIENTE;
    return V_PRODOTTO_SPECIALE;
END FU_ELENCO_PROD_SPECIALI_REC;    


procedure pr_ricalcola_tariffa_prodotto(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE) IS
v_piani_errati VARCHAR2(1024);
v_importo CD_TARIFFA.IMPORTO%TYPE;
v_cod_attivazione cd_prodotto_acquistato.cod_attivazione%type;
v_numero_ambienti number;
v_numero_ambienti_iniziale number;
v_id_prodotto_saltato cd_recupero_prodotto.id_prodotto_saltato%type;
v_importo_a_recupero cd_prodotto_acquistato.imp_recupero%type;
v_importo_lordo_saltato cd_prodotto_acquistato.imp_lordo_saltato%type;
v_imp_lordo_saltato_orig cd_prodotto_acquistato.imp_lordo_saltato%type;
/*v_lordo_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;*/


------------
v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto                     CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
v_lordo_saltato             CD_PRODOTTO_ACQUISTATO.IMP_LORDO_SALTATO%TYPE;
v_id_formato                CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_tariffa_variabile         CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE;
v_esito                     number;
v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_list_maggiorazioni id_list_type;
v_ind_maggiorazioni NUMBER;
v_posizione_rigore cd_posizione_rigore.COD_POSIZIONE%type;
------------

BEGIN

        update cd_prodotto_acquistato
        set flg_ricalcolo_tariffa = 'S'
        where id_prodotto_acquistato = p_id_prodotto_acquistato;
        
        
        --Annullo i comunicati che riferiscono sale virtuali 
        
        update cd_comunicato 
        set flg_annullato ='S'
        where id_comunicato in 
        (
            select id_comunicato 
            from  cd_sala sa,
                  cd_comunicato com,
                  cd_cinema ci
            where com.id_sala = sa.id_sala
            and   com.id_prodotto_acquistato = p_id_prodotto_acquistato 
            and   ci.id_cinema = sa.id_cinema
            and   ci.flg_virtuale = 'S'
        );


        v_importo := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_TARIFFA_PRODOTTO(P_ID_PRODOTTO_ACQUISTATO);
        PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_TARIFFA_PROD_ACQ(P_ID_PRODOTTO_ACQUISTATO,
                                        v_importo,
                                        v_importo,
                                        'S',
                                        v_piani_errati);
      select cod_attivazione  
      into   v_cod_attivazione
      from   cd_prodotto_acquistato
      where id_prodotto_acquistato = p_id_prodotto_acquistato;                                      

      if  v_cod_attivazione ='R' then
            
           
          
      
            select id_prodotto_saltato,quota_parte
            into   v_id_prodotto_saltato,v_imp_lordo_saltato_orig
            from  cd_recupero_prodotto
            where id_prodotto_recupero = p_id_prodotto_acquistato
            and tipo_contratto = 'C';  
             
            --correggo l'importo lordo saltato del prodotto saltato con l'effettivo numero di schsrmi saltati.
            v_numero_ambienti:=PA_CD_PRODOTTO_ACQUISTATO.fu_get_num_ambienti(v_id_prodotto_saltato);
      
            select nvl(numero_massimo_schermi,80) 
            into   v_numero_ambienti_iniziale 
            from   cd_prodotto_acquistato
            where id_prodotto_acquistato = v_id_prodotto_saltato; 
            
            
            v_importo_lordo_saltato := (v_numero_ambienti_iniziale - v_numero_ambienti)* v_importo;
            v_importo_a_recupero  := v_imp_lordo_saltato_orig - v_importo_lordo_saltato  ;
            

            update cd_recupero_prodotto
            set  quota_parte  = v_importo_lordo_saltato
            where id_prodotto_saltato = v_id_prodotto_saltato
            and tipo_contratto = 'C'; 
            
            update cd_importi_prodotto
            set imp_lordo_saltato  = v_importo_lordo_saltato
            where id_prodotto_acquistato = v_id_prodotto_saltato
            and tipo_contratto = 'C'; 
            
            
            --dbms_output.PUT_LINE(' v_importo_lordo_saltato:'|| v_importo_lordo_saltato);
            --dbms_output.PUT_LINE(' v_importo_a_recupero:'|| v_importo_a_recupero);
            
         if v_importo_a_recupero >0 then
                --imposto la differenza  d'importo (importo_lordo saltato preventivato con importo lordo saltato effettivo) sull'importo a recupero.
            
            
                SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, IMP_LORDO_SALTATO, ID_FORMATO, FLG_TARIFFA_VARIABILE
                INTO    v_lordo,  v_netto,   v_maggiorazione,   v_sanatoria, v_recupero, v_tariffa, v_lordo_saltato, v_id_formato, v_tariffa_variabile
                FROM CD_PRODOTTO_ACQUISTATO
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
            
            
            
            
                SELECT  IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
                INTO  v_netto_comm, v_imp_sc_comm, v_lordo_comm
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND TIPO_CONTRATTO = 'C';
        --
                SELECT  IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
                INTO  v_netto_dir, v_imp_sc_dir, v_lordo_dir
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND TIPO_CONTRATTO = 'D';
            
            
              PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
              v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
              v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
              v_imp_sc_dir,v_sanatoria,v_recupero,v_importo_a_recupero,'9',v_esito);
          
              FOR MAG IN (SELECT * FROM CD_MAGG_PRODOTTO
                            WHERE ID_PRODOTTO_ACQUISTATO =p_id_prodotto_acquistato) LOOP
                    v_list_maggiorazioni.EXTEND;
                    v_list_maggiorazioni(v_ind_maggiorazioni) := MAG.ID_MAGGIORAZIONE;
                    v_ind_maggiorazioni := v_ind_maggiorazioni +1;
                END LOOP;
          
          
          
               select distinct posizione_di_rigore
                into v_posizione_rigore
                from cd_comunicato
                where id_prodotto_acquistato = p_id_prodotto_acquistato
                and   flg_annullato ='N'
                and   flg_sospeso ='N'
                and   cod_disattivazione is null;
          
               pa_cd_prodotto_Acquistato.MODIFICA_PRODOTTO_ACQUISTATO(p_id_prodotto_acquistato,
                    'PRE',
                    v_tariffa,
                    v_lordo,
                    v_sanatoria,
                    v_recupero,
                    v_maggiorazione,
                    v_netto_comm,
                    v_imp_sc_comm,
                    v_netto_dir,
                    v_imp_sc_dir,
                    v_posizione_rigore,
                    v_id_formato,
                    v_tariffa_variabile,
                    v_lordo_saltato,
                    v_list_maggiorazioni);
         end if;      
            
      end if;                                         
                                        
end pr_ricalcola_tariffa_prodotto;

--verifica se un prodotto e a target e se il cliente  e presente nel periodo sucessivo. 
-- 0 assente 
-- >0 presente 
function fu_verifica_presenza_target(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return number is
v_return number;
v_id_cliente cd_pianificazione.id_cliente%type;
v_id_target  cd_prodotto_vendita.id_target%type;
v_data_inizio  cd_prodotto_acquistato.data_inizio%type;
v_data_fine  cd_prodotto_acquistato.data_fine%type; 
v_gg_prodotto   number;
begin

v_return := 0;

select pia.id_cliente, pv.id_target,pa.data_inizio,pa.data_fine
into   v_id_cliente, v_id_target,v_data_inizio,v_data_fine 
from   cd_pianificazione pia, cd_prodotto_vendita pv, cd_prodotto_acquistato pa
where  pia.id_piano = pa.id_piano
and    pia.id_ver_piano = pa.id_ver_piano
and    pa.id_prodotto_vendita = pv.id_prodotto_vendita
and    pa.id_prodotto_acquistato = p_id_prodotto_acquistato;
if v_id_target is null then 
    return v_return;
else

    v_gg_prodotto :=  v_data_fine - v_data_inizio +1;
    v_data_inizio :=  v_data_fine+1;
    v_data_fine   :=  v_data_fine+v_gg_prodotto;

    --dbms_output.PUT_LINE('v_data_inizio:'||v_data_inizio);
    --dbms_output.PUT_LINE('v_data_fine:'||v_data_fine);

    select count(1) 
    into  v_return
    from   cd_pianificazione pia, cd_prodotto_vendita pv, cd_prodotto_acquistato pa
    where  pia.id_piano = pa.id_piano
    and    pia.id_ver_piano = pa.id_ver_piano
    and    pa.id_prodotto_vendita = pv.id_prodotto_vendita
    and    pv.id_target = v_id_target
    and    pia.id_cliente = v_id_cliente
    and    pa.data_inizio = v_data_inizio
    and    pa.data_fine = v_data_fine;
    return v_return;
    
end if;
end fu_verifica_presenza_target;




PROCEDURE  PR_ANNULLA_SALA(p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.id_prodotto_acquistato%TYPE,
                                 p_data_inizio cd_prodotto_acquistato.data_inizio%type,
                                 p_data_fine cd_prodotto_acquistato.data_fine%type,
                                 p_id_sala IN cd_sala.id_sala%type,
                                 p_chiamante VARCHAR2,
                                 p_esito IN OUT NUMBER
                                 )
IS
    
    v_stato_vendita          CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
    v_numero_comunicati      INTEGER;
    v_num_com_validi         INTEGER;
    v_comunicati_annullati   INTEGER;
    v_temp                   INTEGER:=0;
    v_num_ambienti_old        NUMBER;
    v_num_ambienti            NUMBER;
    v_importo_prima_c        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_importo_dopo_c         CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_importo_lordo_c        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
    v_importo_prima_d        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_importo_dopo_d         CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
    v_importo_lordo_d        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
    v_numcom_saltati         INTEGER;
    v_numcom_totali          INTEGER;
    v_esito_schermo          NUMBER;
    v_piani_errati           VARCHAR2(200);
    v_numero_sale_prodotto   NUMBER;
    v_numero_sale_periodo   NUMBER;
    
BEGIN
    p_esito := 10;
    SAVEPOINT PR_ANNULLA_SALA;
    
    
    select count(id_comunicato)
    into  v_numero_sale_prodotto
    from  cd_comunicato
    where id_sala = p_id_sala
    and   id_prodotto_acquistato = p_id_prodotto_acquistato
    and   flg_annullato ='N'
    and   flg_sospeso ='N'
    and cod_disattivazione is null;
    
    select count(id_comunicato)
    into  v_numero_sale_periodo
    from  cd_comunicato
    where id_sala = p_id_sala
    and   id_prodotto_acquistato = p_id_prodotto_acquistato
    and   flg_annullato ='N'
    and   flg_sospeso ='N'
    and   cod_disattivazione is null
    and   data_erogazione_prev between  p_data_inizio and  p_data_fine;
    
    if  v_numero_sale_prodotto = v_numero_sale_periodo then
   
        SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
        INTO   v_importo_prima_c       
        FROM   CD_IMPORTI_PRODOTTO
        WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
        
        SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
        INTO   v_importo_prima_d       
        FROM   CD_IMPORTI_PRODOTTO
        WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
        
        v_num_ambienti_old := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(p_id_prodotto_acquistato);
        
    end if;

    IF(p_chiamante='MAG')THEN

            UPDATE CD_COMUNICATO
            SET    CD_COMUNICATO.FLG_ANNULLATO='S'
            WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND    CD_COMUNICATO.DATA_EROGAZIONE_PREV between  p_data_inizio and  p_data_fine
            AND    CD_COMUNICATO.ID_SALA = p_id_sala
            AND    CD_COMUNICATO.FLG_ANNULLATO='N';
            p_esito:=2;
    --altrimenti devo capire se bisogna effettuare il salto o meno
    ELSE
        IF(p_chiamante='PAL')THEN
           
                SELECT CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA
                INTO   v_stato_vendita
                FROM   CD_PRODOTTO_ACQUISTATO
                WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO;
                        
                --devo pero' verificare se il metodo chiamante
                IF v_stato_vendita='PRE' THEN
                    p_esito:=4; --deve saltare
                    
                    UPDATE CD_COMUNICATO
                    SET    CD_COMUNICATO.COD_DISATTIVAZIONE='S'
                    WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_COMUNICATO.DATA_EROGAZIONE_PREV between  p_data_inizio and  p_data_fine
                    AND    CD_COMUNICATO.ID_SALA = p_id_sala
                    AND    CD_COMUNICATO.COD_DISATTIVAZIONE is null;
                ELSE
                    p_esito:=5; --non deve saltare
                    --annullo il comunicato a questo punto
                    UPDATE CD_COMUNICATO
                    SET    CD_COMUNICATO.FLG_ANNULLATO='S'
                    WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_COMUNICATO.DATA_EROGAZIONE_PREV between  p_data_inizio and  p_data_fine
                    AND    CD_COMUNICATO.ID_SALA = p_id_sala
                    AND    CD_COMUNICATO.FLG_ANNULLATO='N';
                END IF;
        END IF;
    END IF;
    IF(v_stato_vendita='PRE' and  p_chiamante='MAG' )THEN --Non ha senso chiamare la elimina buco posizione 
        for c in                                          --Se il chiamante e  Palinsesto perche annullera la sala nella 
        (                                                 --totalita del giorno.
            select id_comunicato 
            from   cd_comunicato 
            where  id_prodotto_acquistato  = p_id_prodotto_acquistato
            and    id_sala = p_id_sala
            AND    data_erogazione_prev between  p_data_inizio and  p_data_fine
            --nessun controllo sulla validita dei comunicati perche li ho appena disattivati/annullati
        )
        loop
            PA_CD_PRODOTTO_ACQUISTATO.PR_ELIMINA_BUCO_POSIZIONE_COM(c.id_comunicato);
        end loop;
    END IF;
    
    
    if  v_numero_sale_prodotto = v_numero_sale_periodo then
            v_num_ambienti := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(p_id_prodotto_acquistato);
            --
            IF(v_num_ambienti != v_num_ambienti_old) THEN
                PA_CD_PRODOTTO_ACQUISTATO.PR_ANNULLA_SCHERMO_PROD_ACQ(p_id_prodotto_acquistato, null,  v_esito_schermo,v_piani_errati);
                IF(p_esito=4)THEN
                    SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
                    INTO   v_importo_dopo_c       
                    FROM   CD_IMPORTI_PRODOTTO
                    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
        
                    SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
                    INTO   v_importo_dopo_d       
                    FROM   CD_IMPORTI_PRODOTTO
                    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';        

                    --recupero precedente importo lordo saltato
                    SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
                    INTO   v_importo_lordo_c       
                    FROM   CD_IMPORTI_PRODOTTO
                    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
            
                    SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
                    INTO   v_importo_lordo_d       
                    FROM   CD_IMPORTI_PRODOTTO
                    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
            
                    --aggiornamento dell'importo lordo saltato
                    UPDATE CD_IMPORTI_PRODOTTO
                    SET    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO = (v_importo_lordo_c + v_importo_prima_c - v_importo_dopo_c)       
                    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
            
                    UPDATE CD_IMPORTI_PRODOTTO
                    SET    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO = (v_importo_lordo_d + v_importo_prima_d - v_importo_dopo_d)       
                    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
                END IF;
            END IF;
        --
            IF((p_esito=2) OR (p_esito=5))THEN
                SELECT COUNT(*)
                INTO   v_num_com_validi
                FROM   CD_COMUNICATO
                WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
                AND    CD_COMUNICATO.FLG_ANNULLATO='N'
                AND    CD_COMUNICATO.FLG_SOSPESO='N'
                AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL;

                IF(v_num_com_validi=0)THEN
                    PR_ANNULLA_PRODOTTO_ACQUIST(p_id_prodotto_acquistato,p_chiamante,v_temp);
                    IF((v_temp=100) OR (v_temp<0))THEN
                        p_esito:=p_esito+20;
                    ELSE
                        p_esito:=p_esito+10;
                    END IF;
                END IF;
            END IF;
        --
    

        IF(p_esito=4)THEN
            SELECT COUNT(*)
            INTO   v_numcom_saltati
            FROM   CD_COMUNICATO
            WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
            AND    CD_COMUNICATO.FLG_SOSPESO='N'
            AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NOT NULL;
        --
            SELECT COUNT(*)
            INTO   v_numcom_totali
            FROM   CD_COMUNICATO
            WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=p_id_prodotto_acquistato
            AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
            AND    CD_COMUNICATO.FLG_SOSPESO='N';
        --
            IF((v_numcom_saltati=v_numcom_totali)AND(v_numcom_totali>0))THEN
                UPDATE CD_PRODOTTO_ACQUISTATO
                SET    CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE = 'S'
                WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
            END IF;
        END IF;
        
    END IF;---
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_ANNULLA_SALA: operazione non eseguita, si e'' verificato un errore  '||SQLERRM);
        ROLLBACK TO SP_PR_ANNULLA_SALA;
END PR_ANNULLA_SALA;


procedure pr_ripristina_sala(p_id_sala cd_sala.id_sala%type,
                                               p_data_inizio cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                               p_data_fine cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                               p_id_circuito cd_circuito.id_circuito%type
                                               )
                                               is
v_importo number;
v_piani_errati varchar2(1000);
begin


    for prodotti in
    (
        select distinct id_prodotto_acquistato
        from   cd_comunicato co,
               cd_break_vendita brv,
               cd_circuito_break cb,
               cd_break br,
               cd_proiezione pr
        where  co.cod_disattivazione is not null
        and    co.id_sala = p_id_sala
        and    co.data_erogazione_prev between p_data_inizio and p_data_fine
        and    co.id_prodotto_acquistato in 
        (
            select id_prodotto_acquistato
            from  cd_prodotto_acquistato pa,
                  cd_prodotto_vendita pv, 
                  cd_circuito cir
             where pa.id_prodotto_acquistato = co.id_prodotto_acquistato
             and   pv.id_prodotto_vendita    = pa.id_prodotto_vendita
             and   pv.id_circuito            = nvl(p_id_circuito,cir.id_circuito)
        )
        and  brv.id_break_vendita =  co.id_break_vendita
        and  brv.flg_annullato = 'N'
        and  cb.id_circuito_break = brv.id_circuito_break
        and  cb.id_circuito = nvl(p_id_circuito,cb.id_circuito)
        and  cb.flg_annullato = 'N'
        and  br.id_break = cb.id_break
        and  br.flg_annullato ='N'
        and  pr.id_proiezione = br.id_proiezione
        and  pr.flg_annullato ='N'
    ) 
    loop
        
            update cd_comunicato 
            set    cod_disattivazione = null
            where  id_sala = p_id_sala
            and    data_erogazione_prev between p_data_inizio and p_data_fine
            and    id_prodotto_acquistato = prodotti.id_prodotto_acquistato; 
        
            v_importo := pa_cd_prodotto_acquistato.fu_get_tariffa_prodotto(prodotti.id_prodotto_acquistato);
            
            --dbms_output.PUT_LINE('v_importo:'||v_importo);
    
            pa_cd_prodotto_acquistato.pr_ricalcola_tariffa_prod_acq(prodotti.id_prodotto_acquistato,
                                                                v_importo,
                                                                v_importo,
                                                                'S',
                                                                v_piani_errati);
                                           
            update  cd_importi_prodotto
            set     imp_lordo_saltato = imp_lordo_saltato - v_importo
            where   id_prodotto_acquistato =  prodotti.id_prodotto_acquistato
            and     tipo_contratto = 'C'; 
                                                                            
    end loop;                                                            
end pr_ripristina_sala;


function fu_prodotti_periodi_speciali(p_data_inizio date,p_data_fine date) return c_id_prodotto_acquistato is
v_id_prodotto_acquistato c_id_prodotto_acquistato; 
begin
    
    open v_id_prodotto_acquistato for
        select pa.id_prodotto_acquistato --count(1),co.id_sala,pa.id_prodotto_acquistato,pa.DATA_FINE, pa.DATA_INIZIO
        from  cd_periodo_speciale ps,
              cd_prodotto_acquistato pa,
              cd_pianificazione pia,
              cd_prodotto_vendita pv,
              cd_comunicato co,
              cd_sala sa
        where ps.data_inizio = pa.data_inizio
        and   ps.data_fine = pa.data_fine
        and   pa.flg_annullato = 'N'
        and   pa.flg_sospeso   = 'N'
        and   pa.cod_disattivazione is null 
        and   pa.stato_di_vendita ='PRE'
        and  ((p_data_inizio between pa.data_inizio  and pa.data_fine ) or (p_data_fine between pa.data_inizio  and pa.data_fine))
        and   pa.id_prodotto_vendita = pv.id_prodotto_vendita
        and   pa.id_piano = pia.id_piano
        and   pa.id_ver_piano = pia.id_ver_piano
        and   pia.cod_categoria_prodotto = 'TAB'
        and   co.id_prodotto_acquistato = pa.id_prodotto_acquistato
        and   co.flg_annullato = 'N'
        and   co.flg_sospeso   = 'N'
        and   co.cod_disattivazione is not null
        and   co.id_sala = sa.id_sala
        and   sa.flg_arena ='N'
        and   pv.id_target is null
        and   pv.flg_segui_il_film = 'N'
        and   pv.flg_abbinato ='N'
        and   not exists (select * from cd_recupero_prodotto where id_prodotto_saltato = pa.id_prodotto_acquistato) --ecludo i prodotti gia recuperati
        group by co.id_sala, pa.id_prodotto_acquistato,pa.data_fine, pa.data_inizio
        having count(1)/2 = (pa.data_fine - pa.data_inizio) +1;
    return v_id_prodotto_acquistato;
    end fu_prodotti_periodi_speciali;
    
function  fu_get_perc_esatta_importo(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                                              p_tipo_contratto cd_importi_prodotto.tipo_contratto%type ) return number is
v_netto CD_IMPORTI_PRODOTTO.IMP_NETTO%type;
v_imp_sc CD_IMPORTI_PRODOTTO.IMP_SC_COMM%type;
begin
    
        SELECT IMP_NETTO, IMP_SC_COMM
        INTO v_netto, v_imp_sc
        FROM CD_IMPORTI_PRODOTTO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND TIPO_CONTRATTO = p_tipo_contratto;
        
        return PA_PC_IMPORTI.FU_PERC_SC_COMM_ESATTA(v_netto,v_imp_sc);
end  fu_get_perc_esatta_importo;   




-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_RECUPERO_PROD_ACQ_LIBERA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto acquistato venduto in libera
--
--
--
-- OPERAZIONI:
--  1) Seleziona la descrizione dello stato di vendita
--  2) Seleziona il soggetto da associare ai comunicati. Se esiste un solo soggetto con descrizione
--     differente da 'SOGGETTO NON DEFINITO' viene associato quello
--  3) Seleziona la testata editoriale, il prodotto pubblicitario, il dgc
--  4) Calcola i valori di netto commerciale e direzionale
--  5) Inserisce il prodotto acquistato, verificando lo sconto stagionale e la tariffa in base al coefficiente cinema
--  6) Inserisce gli importi prodotto, commerciale e direzionale, legati al prodotto acquistato
--  7) Inserisce le informazioni sulle maggiorazioni collegate
--  8) Inserisce i comunicati per gli ambienti scelti
--
--  INPUT:
--  p_id_prodotto_vendita   id del prodotto di vendita
--  p_id_piano              id del piano
--  p_id_ver_piano          id della versione del piano
--  p_list_id_ambito        vettore contentente gli id degli ambienti acquistati
--  p_id_ambito             id dell'ambito
--  p_data_inizio           data inizio validita
--  p_data_fine             data fine validita
--  p_id_formato            id del formato acquistabile
--  p_tariffa               importo di tariffa
--  p_lordo                 importo lordo
--  p_lordo_comm            importo lordo commerciale
--  p_lordo_dir             importo lordo direzionale
--  p_sconto_comm           importo di sconto commerciale
--  p_sconto_dir            importo di sconto direzionale
--  p_maggiorazione         importo di maggiorazione
--  p_unita_temp            unita temporale del prodotto inserito (Settimana, Mese ecc)
--  p_id_listino            id del listino utilizzato
--  p_num_ambiti            numero di ambienti per cui viene creato il prodotto acquistato
--  p_id_posizione_rigore   id della posizione di rigore, se richiesta
--  p_tariffa_variabile     flag che indica se il prodotto e da creare con tariffa variabile o meno (il flag puo assumere il valore S o N)
--  p_id_tipo_cinema        id del tipo cinema del prodotto di vendita
--  p_list_maggiorazioni    lista di maggiorazioni applicate al prodotto acquistato
--  p_list_id_area          lista di aree nielsen applicate al prodotto acquistato. Viene utilizzato solo se il prodotto e geo split
--
-- OUTPUT: esito:
--    1  Prodotto inserito correttamente
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Simone Bottani , Altran, Luglio 2009
--
--  MODIFICHE:
--  se e presente un solo cliente fruitore di piano viene associato al prodotto 05/01/2010 Michele Borgogno
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_RECUPERO_LIBERA (
    p_id_prodotto_vendita   CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE,
    p_id_piano              CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
    p_id_ver_piano          CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
    p_list_id_ambito        id_list_type,
    p_id_ambito             NUMBER,
    p_data_inizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    p_data_fine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    p_id_formato            CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
    p_tariffa               CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    p_lordo                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_comm            CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_lordo_dir             CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    p_sconto_comm           CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_sconto_dir            CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    p_maggiorazione         CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    p_importo_recupero      CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE,
    p_unita_temp            CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
    p_id_listino            CD_TARIFFA.ID_LISTINO%TYPE,
    p_num_ambiti            NUMBER,
    p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
    p_tariffa_variabile     CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    p_list_maggiorazioni    id_list_type,
    p_id_tipo_cinema        CD_PRODOTTO_ACQUISTATO.ID_TIPO_CINEMA%TYPE,
    p_cod_attivazione       CD_PRODOTTO_ACQUISTATO.COD_ATTIVAZIONE%TYPE,
    p_id_prodotto_acquistato OUT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    p_esito                  OUT NUMBER)
IS
--
v_id_soggetto_piano CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE;
v_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE;
v_seq NATURAL;
v_numero_comunicati NUMBER;
v_id_tariffa CD_TARIFFA.ID_TARIFFA%TYPE;
v_id_tipo_pubb CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE;
v_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
v_soggetto CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
v_cod_testata CD_PIANIFICAZIONE.COD_TESTATA_EDITORIALE%TYPE;
v_dgc CD_PRODOTTO_ACQUISTATO.DGC%TYPE;
v_lordo CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_comm CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_imp_sconto CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_count_sogg NUMBER;
v_id_periodo CD_IMPORTI_RICHIESTI_PIANO.ID_IMPORTI_RICHIESTI_PIANO%TYPE;
v_sala_arena varchar2(10);
v_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE;
v_num_comunicati NUMBER;
BEGIN
--
p_esito     := 1;

       SAVEPOINT PR_CREA_PROD_ACQ_LIBERA;

       SELECT DESCR_BREVE, ID_CLIENTE
       INTO v_stato_vendita, v_id_cliente
       FROM CD_PIANIFICAZIONE, CD_STATO_DI_VENDITA
       WHERE CD_PIANIFICAZIONE.ID_PIANO = p_id_piano
       AND CD_PIANIFICAZIONE.ID_VER_PIANO = p_id_ver_piano
       AND CD_STATO_DI_VENDITA.ID_STATO_VENDITA = CD_PIANIFICAZIONE.ID_STATO_VENDITA;
--
    SELECT COUNT(1)
    INTO v_count_sogg
    FROM CD_SOGGETTO_DI_PIANO
    WHERE ID_PIANO = p_id_piano
    AND ID_VER_PIANO = p_id_ver_piano;
--
      SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano
        AND (
          v_count_sogg = 1
        OR
          v_count_sogg = 2 AND DESCRIZIONE != 'SOGGETTO NON DEFINITO'
        OR
          v_count_sogg > 2
          AND DESCRIZIONE = 'SOGGETTO NON DEFINITO');

/*    SELECT ID_SOGGETTO_DI_PIANO
       INTO v_soggetto
        FROM CD_SOGGETTO_DI_PIANO
        WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano
        AND (
          (SELECT COUNT(ID_SOGGETTO_DI_PIANO) FROM CD_SOGGETTO_DI_PIANO
          WHERE ID_PIANO = p_id_piano AND ID_VER_PIANO = p_id_ver_piano) = 2
          OR DESCRIZIONE = 'SOGGETTO NON DEFINITO');*/
         --
     BEGIN
     --dbms_output.PUT_LINE('p_id_piano: '||p_id_piano);
     --  dbms_output.PUT_LINE('p_id_prodotto_vendita: '||p_id_prodotto_vendita);
      SELECT COD_TESTATA_EDITORIALE
       INTO v_cod_testata
       FROM CD_PIANIFICAZIONE
       WHERE ID_PIANO = p_id_piano
       AND ID_VER_PIANO = p_id_ver_piano;
--
       SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB,DECODE(FLG_ARENA,'S', 'ARENA','SALA'), CD_CIRCUITO.ID_CIRCUITO
       INTO v_id_tipo_pubb,v_sala_arena, v_id_circuito
       FROM CD_PRODOTTO_VENDITA,CD_CIRCUITO
       WHERE CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
       AND   CD_CIRCUITO.ID_CIRCUITO = CD_PRODOTTO_VENDITA.ID_CIRCUITO;
--
--       v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata );
       v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, v_cod_testata,v_sala_arena);

         EXCEPTION
             WHEN NO_DATA_FOUND THEN
             v_dgc := '';
           raise;
     END;

     v_id_periodo := PA_CD_PIANIFICAZIONE.FU_GET_PERIODO_PIANO(p_id_piano, p_id_ver_piano, p_data_inizio, p_data_fine);

     v_lordo := p_lordo;
     v_netto_comm := PA_PC_IMPORTI.FU_NETTO(p_lordo_comm, p_sconto_comm);
     v_netto_dir := PA_PC_IMPORTI.FU_NETTO(p_lordo_dir, p_sconto_dir);
     v_netto := v_netto_comm + v_netto_dir;
--
     INSERT INTO CD_PRODOTTO_ACQUISTATO
         ( ID_PRODOTTO_VENDITA,
           ID_RAGGRUPPAMENTO,
           ID_FRUITORI_DI_PIANO,
           ID_FORMATO,
           ID_SPETTACOLO,
           ID_GENERE,
           ID_PIANO,
           ID_VER_PIANO,
           NUMERO_AMBIENTI,
           ID_IMPORTI_RICHIESTI_PIANO,
           STATO_DI_VENDITA,
           IMP_LORDO,
           IMP_MAGGIORAZIONE,
    --       IMP_NETTO_DIR,
           IMP_RECUPERO,
           IMP_TARIFFA,
           IMP_SANATORIA,
       --       IMP_SCO_COMM,
           IMP_NETTO,
       --       STATO_FATTURAZIONE,
           DATA_INIZIO,
           DATA_FINE,
           ID_MISURA_PRD_VE,
           FLG_TARIFFA_VARIABILE,
           DGC,
           ID_TIPO_CINEMA,
           COD_ATTIVAZIONE
          )
        SELECT p_id_prodotto_vendita,
        (SELECT id_raggruppamento from cd_raggruppamento_intermediari
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS INTERMEDIARIO,
        (SELECT id_fruitori_di_piano from cd_fruitori_di_piano
         WHERE id_piano = p_id_piano and id_ver_piano = p_id_ver_piano
         and rownum = 1) AS FRUITORE,
        p_id_formato,
        NULL,
        NULL,
        p_id_piano,
        p_id_ver_piano,
        p_num_ambiti,
        v_id_periodo,
        v_stato_vendita,
         v_lordo AS IMP_LORDO,
         p_maggiorazione AS MAGGIORAZIONE,
   --      0 AS IMP_NETTO_DIR,
         p_importo_recupero AS RECUPERO,--0 AS RECUPERO,
         p_tariffa AS TARIFFA,
         0 AS SANATORIA,
   --      PA_PC_IMPORTI.FU_SCONTO_COMM_3(p_lordo, p_sconto) * p_num_ambiti AS SCO_COMM,
         v_netto,
  --       NULL,
         p_data_inizio,
         p_data_fine,
         TARIFFA.ID_MISURA_PRD_VE,
         p_tariffa_variabile,
         v_dgc,
         p_id_tipo_cinema,
         p_cod_attivazione
        FROM CD_UNITA_MISURA_TEMP, CD_MISURA_PRD_VENDITA,
        CD_PRODOTTO_VENDITA PV, CD_TARIFFA TARIFFA, DUAL
        WHERE PV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND TARIFFA.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
        AND TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND TARIFFA.ID_LISTINO = p_id_listino
        AND TARIFFA.DATA_INIZIO <= p_data_inizio
        AND TARIFFA.DATA_FINE >= p_data_fine
        AND (TARIFFA.ID_TIPO_TARIFFA = 1 OR p_id_formato IS NULL OR TARIFFA.ID_FORMATO = p_id_formato)
        AND (TARIFFA.ID_TIPO_CINEMA IS NULL OR TARIFFA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND CD_UNITA_MISURA_TEMP.ID_UNITA = p_unita_temp;
--
        SELECT CD_PRODOTTO_ACQUISTATO_SEQ.CURRVAL INTO v_seq FROM DUAL;
        p_id_prodotto_acquistato := v_seq;
--
        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'C',v_netto_comm,p_sconto_comm,v_seq,FU_CD_GET_DGC_TC(v_dgc,'C')
        FROM DUAL;

        INSERT INTO CD_IMPORTI_PRODOTTO(TIPO_CONTRATTO, IMP_NETTO, IMP_SC_COMM, ID_PRODOTTO_ACQUISTATO,DGC_TC_ID)
        SELECT
        'D',v_netto_dir,p_sconto_dir,v_seq,FU_CD_GET_DGC_TC(v_dgc,'D')
        FROM DUAL;

   IF p_list_maggiorazioni IS NOT NULL AND p_list_maggiorazioni.COUNT > 0 THEN
     FOR i IN 1..p_list_maggiorazioni.COUNT LOOP
         PR_SALVA_MAGGIORAZIONE(v_seq, p_list_maggiorazioni(i));
     END LOOP;
   END IF;
        -- IF p_id_posizione_rigore IS NOT NULL THEN
         --   PR_SALVA_MAGGIORAZIONE(v_seq, 1);
        -- END IF;
--
       PA_CD_COMUNICATO.PR_CREA_COMUNICATI_LIBERA(p_id_prodotto_acquistato,
                                          p_id_prodotto_vendita,
                                           p_id_ambito,
                                           v_id_circuito,
                                           p_data_inizio,
                                           p_data_fine,
                                           p_list_id_ambito,
                                           p_id_formato,
                                           p_unita_temp,
                                           v_soggetto,
                                           p_id_posizione_rigore);
   --
   SELECT COUNT(1)
   INTO v_num_comunicati
   FROM CD_COMUNICATO
   WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
   AND ROWNUM <= 1;
   --
   IF v_num_comunicati = 0 THEN
     RAISE_APPLICATION_ERROR(-20027, 'PROCEDURA PR_CREA_PROD_ACQ_LIBERA: ERRORE NELL''INSERIMENTO DEI COMUNICATI '|| SQLERRM);
   END IF;
   PA_CD_TUTELA.PR_ANNULLA_PER_TUTELA(p_id_piano, p_id_ver_piano, v_id_cliente, v_soggetto, null);
   EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
    WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PROD_ACQ_LIBERA: INSERT NON ESEGUITA, ERRORE: '||SQLERRM);
        ROLLBACK TO PR_CREA_PROD_ACQ_LIBERA;

     END PR_CREA_RECUPERO_LIBERA;



function fu_get_costo_ambiente(p_id_prodotto_acquistato  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) return number is
v_costo_ambiente number;
begin
    select imp_tariffa/numero_ambienti
    into   v_costo_ambiente  
    from cd_prodotto_acquistato 
    where id_prodotto_acquistato = p_id_prodotto_acquistato;
    return v_costo_ambiente;
end  fu_get_costo_ambiente;

END PA_CD_PRODOTTO_ACQUISTATO; 
/

