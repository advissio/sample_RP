CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_ESERCENTE IS 

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CERCA_ESERCENTE
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_id_cinema         il cinema attualmente associato
--  p_rag_soc           la ragione sociale
--  p_comune            il comune di appartenenza
--
-- OUTPUT: Restituisce gli esercenti che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Febbraio 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_ESERCENTE(p_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
                            p_rag_soc           VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE%TYPE,
                            p_comune            VI_CD_SOCIETA_ESERCENTE.COMUNE%TYPE)
                            RETURN C_ESERCENTE
IS
   c_esercente_return C_ESERCENTE;
BEGIN
OPEN c_esercente_return  -- apre il cursore che contiene gli esercenti da selezionare
     FOR
         SELECT     DISTINCT ES.COD_ESERCENTE, ES.RAGIONE_SOCIALE,
                    ES.PART_IVA, ES.COMUNE,
                    ES.PROVINCIA, ES.INDIRIZZO, ES.DATA_INIZIO_VALIDITA, ES.DATA_FINE_VALIDITA,
                    '' as RAPPR_LEGALI --FU_RAPPRESENTANTI_LEGALI(ES.COD_ESERCENTE) as RAPPR_LEGALI
         FROM       VI_CD_SOCIETA_ESERCENTE ES, 
         CD_ESER_CONTRATTO EC, 
         CD_CONTRATTO C, 
         CD_CINEMA_CONTRATTO CC
         WHERE      ES.COD_ESERCENTE = EC.COD_ESERCENTE(+)
      --   AND        SYSDATE BETWEEN NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) AND NVL(EC.DATA_FINA,to_Date('31122999','DDMMYYYY'))
         AND        UPPER(ES.RAGIONE_SOCIALE) LIKE ('%'||UPPER(NVL(p_rag_soc,ES.RAGIONE_SOCIALE))||'%')
         AND        ES.COMUNE LIKE ('%'||UPPER(NVL(p_comune,ES.COMUNE))||'%')
      --   AND        SYSDATE BETWEEN NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) AND NVL(ES.DATA_FINE_VALIDITA,to_Date('31122999','DDMMYYYY'))
         AND        C.ID_CONTRATTO(+) = EC.ID_CONTRATTO
         AND        CC.ID_CONTRATTO(+) = C.ID_CONTRATTO
         AND        (p_id_cinema IS NULL OR CC.ID_CINEMA = p_id_cinema)
      /* AND        (   p_id_cinema IS NULL
                        OR
                        (
                            
                            CC.ID_CINEMA = p_id_cinema 
                            AND CD_CINEMA_ESERCENTE.DATA_INIZIO_VAL <= SYSDATE
                            AND 
                            (
                                CD_CINEMA_ESERCENTE.DATA_FINE_VAL IS NULL
                                OR
                                CD_CINEMA_ESERCENTE.DATA_FINE_VAL >= SYSDATE
                            )
                        )
                    )*/  
                    ORDER BY ES.RAGIONE_SOCIALE;
    RETURN c_esercente_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'FUNZIONE FU_CERCA_ESERCENTE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||SQLERRM);
END FU_CERCA_ESERCENTE;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTE_GRUPPI
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente      identificativo dell esercente
--
-- OUTPUT: Restituisce i gruppi legati all esercente
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Febbraio 2010
-- Mauro Viel Altran 13/04/2010 sostituita la tavola cd_gruppo_esercente con la vista vi_cd_gruppo_esercente 
-- e la tavola cd_societa_gruppo con la vista vi_cd_societa_gruppo
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESERCENTE_GRUPPI(p_cod_esercente   VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE)
                             RETURN C_ESERCENTE_GRUPPI
IS
   c_esercente_return C_ESERCENTE_GRUPPI;
BEGIN
OPEN c_esercente_return  -- apre il cursore che contiene gli esercenti da selezionare
     FOR
         SELECT VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE, VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO, 
                VI_CD_SOCIETA_GRUPPO.DATA_INIZIO_VAL, 
                VI_CD_SOCIETA_GRUPPO.DATA_FINE_VAL
         FROM   VI_CD_GRUPPO_ESERCENTE, VI_CD_SOCIETA_GRUPPO, VI_CD_SOCIETA_ESERCENTE
         WHERE  VI_CD_SOCIETA_GRUPPO.COD_ESERCENTE = VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE
         AND    VI_CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE = VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE
         AND    VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE = p_cod_esercente;
    RETURN c_esercente_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'FUNZIONE FU_ESERCENTE_GRUPPI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||SQLERRM);
END FU_ESERCENTE_GRUPPI;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTE_CONTRATTI
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente      identificativo dell esercente
--
-- OUTPUT: Restituisce i contratti legati all esercente
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Febbraio 2010
-- --------------------------------------------------------------------------------------------
--FUNCTION FU_ESERCENTE_CONTRATTI(p_cod_esercente   VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE)
--                                RETURN C_ESERCENTE_CONTRATTI
--IS
--   c_esercente_return C_ESERCENTE_CONTRATTI;
--BEGIN
--OPEN c_esercente_return  -- apre il cursore che contiene gli esercenti da selezionare
--     FOR
--         SELECT CD_CONTRATTO.ID_CONTRATTO, CD_CONTRATTO.DATA_INIZIO,
--                CD_CONTRATTO.DATA_FINE, CD_CONTRATTO.DATA_RISOLUZIONE
--         FROM   CD_CONTRATTO, CD_ESER_CONTRATTO, VI_CD_SOCIETA_ESERCENTE
--         WHERE  CD_ESER_CONTRATTO.COD_ESERCENTE = VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE
--         AND    CD_ESER_CONTRATTO.ID_CONTRATTO = CD_CONTRATTO.ID_CONTRATTO
--         AND    VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE = p_cod_esercente;
--    RETURN c_esercente_return;
--EXCEPTION
--        WHEN OTHERS THEN
--        RAISE_APPLICATION_ERROR(-20003, 'FUNZIONE FU_ESERCENTE_CONTRATTI: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||SQLERRM);
--END FU_ESERCENTE_CONTRATTI;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTE_CINEMA
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente      identificativo dell esercente
--
-- OUTPUT: Restituisce i cinema legati all esercente
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Febbraio 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESERCENTE_CINEMA(p_cod_esercente   VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE)
                             RETURN C_ESERCENTE_CINEMA
IS
   c_esercente_return C_ESERCENTE_CINEMA;
BEGIN
OPEN c_esercente_return  -- apre il cursore che contiene gli esercenti da selezionare
     FOR
         SELECT DISTINCT CD_CINEMA.ID_CINEMA, CD_CINEMA.NOME_CINEMA, CD_COMUNE.COMUNE, C.DATA_INIZIO AS DATA_INIZIO_VAL, C.DATA_FINE AS DATA_FINE_VAL
         FROM   CD_CINEMA, CD_COMUNE,CD_ESER_CONTRATTO EC, CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC, VI_CD_SOCIETA_ESERCENTE ES
         WHERE  EC.COD_ESERCENTE = ES.COD_ESERCENTE
         AND    C.ID_CONTRATTO = EC.ID_CONTRATTO
         AND    CC.ID_CONTRATTO = C.ID_CONTRATTO
         AND    CC.ID_CINEMA = CD_CINEMA.ID_CINEMA
         AND    CD_CINEMA.ID_COMUNE = CD_COMUNE.ID_COMUNE
         AND    ES.COD_ESERCENTE = p_cod_esercente
         ORDER BY ES.RAGIONE_SOCIALE;
    RETURN c_esercente_return;
EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'FUNZIONE FU_ESERCENTE_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||SQLERRM);
END FU_ESERCENTE_CINEMA;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTI_GRUPPO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_id_gruppo         il gruppo esercenti cercato
--  p_inclusione        1 se se l'esercente cercato deve appartenere al gruppo richiesto, 0 se non deve essere incluso
--
-- OUTPUT: Restituisce gli esercenti che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
---Mauro Viel Altran 13/04/2010 sostituita la tavola cd_gruppo_esercente con la vista vi_cd_gruppo_esercente 
-- e la tavola cd_societa_gruppo con la vista vi_cd_societa_gruppo
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESERCENTI_GRUPPO(p_id_gruppo        VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                            p_inclusione        NUMBER)
                            RETURN C_ESERCENTE IS
c_esercente_return C_ESERCENTE;
BEGIN
IF p_inclusione = 1 THEN
    OPEN c_esercente_return  -- apre il cursore che contiene gli esercenti da selezionare
     FOR
         SELECT     DISTINCT ESERCENTE.COD_ESERCENTE, ESERCENTE.RAGIONE_SOCIALE,
                    ESERCENTE.PART_IVA, ESERCENTE.COMUNE,
                    ESERCENTE.PROVINCIA, ESERCENTE.INDIRIZZO,
                    ESERCENTE.DATA_INIZIO_VALIDITA, ESERCENTE.DATA_FINE_VALIDITA,
                    '' as RAPPR_LEGALI-- FU_RAPPRESENTANTI_LEGALI(ESERCENTE.COD_ESERCENTE) as RAPPR_LEGALI
         FROM       VI_CD_SOCIETA_ESERCENTE ESERCENTE, VI_CD_SOCIETA_GRUPPO GRUPPO
         WHERE      GRUPPO.ID_GRUPPO_ESERCENTE = p_id_gruppo
         AND        ESERCENTE.COD_ESERCENTE = GRUPPO.COD_ESERCENTE
         AND        ESERCENTE.DATA_INIZIO_VALIDITA <= SYSDATE
         AND        (
                        ESERCENTE.DATA_FINE_VALIDITA IS NULL
                        OR
                        ESERCENTE.DATA_FINE_VALIDITA >= SYSDATE
                    )
         ORDER BY ESERCENTE.RAGIONE_SOCIALE;
ELSIF p_inclusione = 0 THEN
    OPEN c_esercente_return  -- apre il cursore che contiene gli esercenti da selezionare
     FOR
         SELECT     DISTINCT ESERCENTE.COD_ESERCENTE, ESERCENTE.RAGIONE_SOCIALE,
                    ESERCENTE.PART_IVA, ESERCENTE.COMUNE,
                    ESERCENTE.PROVINCIA, ESERCENTE.INDIRIZZO,
                    ESERCENTE.DATA_INIZIO_VALIDITA, ESERCENTE.DATA_FINE_VALIDITA,
                    '' as RAPPR_LEGALI --FU_RAPPRESENTANTI_LEGALI(ESERCENTE.COD_ESERCENTE) as RAPPR_LEGALI
         FROM       VI_CD_SOCIETA_ESERCENTE ESERCENTE, VI_CD_SOCIETA_GRUPPO GRUPPO
         WHERE      ESERCENTE.COD_ESERCENTE = GRUPPO.COD_ESERCENTE(+)
         AND        GRUPPO.ID_GRUPPO_ESERCENTE IS NULL
         AND        SYSDATE BETWEEN NVL(ESERCENTE.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY'))
         AND        NVL(ESERCENTE.DATA_FINE_VALIDITA,to_date('31122100','DDMMYYYY'))
         AND        SYSDATE BETWEEN NVL(GRUPPO.DATA_INIZIO_VAL,to_date('01011900','DDMMYYYY'))
         AND        NVL(GRUPPO.DATA_FINE_VAL,to_date('31122100','DDMMYYYY'))
         ORDER BY ESERCENTE.RAGIONE_SOCIALE;
END IF;    
RETURN c_esercente_return;

END FU_ESERCENTI_GRUPPO; 

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CERCA_GRUPPI
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_id_nome              nome del gruppo
--  p_data_inizio          data inizio validita del gruppo
--  p_data_fine            data fine validita del gruppo
-- OUTPUT: Restituisce i gruppi esercenti che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Michele Borgogno, Altran, Marzo 2010
-- Mauro Viel Altran 13/04/2010 sostituita la tavola cd_gruppo_esercente con la vista vi_cd_gruppo_esercente
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_GRUPPI(p_nome              VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
                         p_data_inizio       VI_CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
                         p_data_fine         VI_CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE) RETURN C_GRUPPO IS
c_gruppo_ret C_GRUPPO;

BEGIN
    OPEN c_gruppo_ret 
    FOR
        SELECT ID_GRUPPO_ESERCENTE, NOME_GRUPPO, DATA_INIZIO, DATA_FINE
        FROM VI_CD_GRUPPO_ESERCENTE
        WHERE (p_nome IS NULL OR UPPER(NOME_GRUPPO) LIKE ('%'||UPPER(p_nome)||'%'))
        AND   (p_data_inizio IS NULL OR DATA_INIZIO = p_data_inizio)
        AND   (p_data_fine IS NULL OR DATA_FINE >= p_data_fine)
        ORDER BY NOME_GRUPPO;
   
    RETURN c_gruppo_ret;

END FU_CERCA_GRUPPI;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE PR_ASSOCIA_ESERCENTE_GRUPPO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente     Codice dell'esercente da associare al gruppo
--  p_id_gruppo         Gruppo da associare
--  p_esito             Esito della procedura
--
-- OUTPUT: Aggiunge una nuova associazione tra un esercente e un gruppo esercente
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
--MODIFICHE: Mauro Viel Altran  la procedura  con l'utilizzo della vista vi_cd_gruppo_esercente non e piu utilizzata  
-- --------------------------------------------------------------------------------------------
/*PROCEDURE PR_ASSOCIA_ESERCENTE_GRUPPO(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_gruppo CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE%TYPE,
                                      p_esito OUT NUMBER) IS
    --
    BEGIN
    UPDATE CD_SOCIETA_GRUPPO
    SET DATA_FINE_VAL = SYSDATE - 1
    WHERE COD_ESERCENTE = p_cod_esercente
    AND SYSDATE BETWEEN DATA_INIZIO_VAL AND NVL(DATA_FINE_VAL,to_date('31122999','DDMMYYYY'));
    --
    INSERT INTO CD_SOCIETA_GRUPPO(COD_ESERCENTE, ID_GRUPPO_ESERCENTE, DATA_INIZIO_VAL)
    VALUES(p_cod_esercente, p_id_gruppo, trunc(sysdate));
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20003, 'PROCEDURA PR_ASSOCIA_ESERCENTE_GRUPPO: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);  
END PR_ASSOCIA_ESERCENTE_GRUPPO;    */                                  
-- --------------------------------------------------------------------------------------------
-- FUNZIONE PR_ELIMINA_ESERCENTE_GRUPPO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente     Codice dell'esercente da eliminare dal gruppo
--  p_id_gruppo         Gruppo
--  p_esito             Esito della procedura
--
-- OUTPUT: Aggiunge una nuova associazione tra un esercente e un gruppo esercente
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- MODIFICHE: Mauro Viel Altran  la procedura  con l'utilizzo della vista vi_cd_gruppo_esercente non e piu utilizzata  
-- --------------------------------------------------------------------------------------------                                      
/*PROCEDURE PR_ELIMINA_ESERCENTE_GRUPPO(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_gruppo CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE%TYPE,
                                      p_esito OUT NUMBER) IS
    --
    BEGIN
    DELETE FROM CD_SOCIETA_GRUPPO
    WHERE COD_ESERCENTE = p_cod_esercente
    AND ID_GRUPPO_ESERCENTE = p_id_gruppo;
                                                                         
    EXCEPTION  
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20004, 'PROCEDURA PR_ELIMINA_ESERCENTE_GRUPPO: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
        ROLLBACK TO SP_PR_ASSOCIA_ESERCENTE_CINEMA;
END PR_ELIMINA_ESERCENTE_GRUPPO;*/

-- Procedura PR_SALVA_GRUPPO_ESERCENTE
--
-- DESCRIZIONE:  Inserisce un nuovo gruppo esercente
--
-- OPERAZIONI:
--
--  INPUT:
--  p_id_nome              nome del gruppo
--  p_data_inizio          data inizio validita del gruppo
--  p_data_fine            data fine validita del gruppo
--
--  OUTPUT:
--
-- REALIZZATORE: Michele Borgogno , Altran, marzo 2010
--
--  MODIFICHE: Mauro Viel Altran  la procedura  con l'utilizzo della vista vi_cd_gruppo_esercente non e piu utilizzata
--
-------------------------------------------------------------------------------------------------
/*PROCEDURE PR_SALVA_GRUPPO_ESERCENTE(p_nome              CD_GRUPPO_ESERCENTE.NOME_GRUPPO%TYPE,
                          p_data_inizio       CD_GRUPPO_ESERCENTE.DATA_INIZIO%TYPE,
                          p_data_fine         CD_GRUPPO_ESERCENTE.DATA_FINE%TYPE,
                          p_esito OUT NUMBER) IS

BEGIN

    INSERT INTO CD_GRUPPO_ESERCENTE(NOME_GRUPPO, DATA_INIZIO, DATA_FINE)
    VALUES(p_nome,p_data_inizio,p_data_fine);

EXCEPTION
  WHEN OTHERS THEN
  p_esito := -1;
  RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_SALVA_GRUPPO_ESERCENTE: Errore');
END PR_SALVA_GRUPPO_ESERCENTE;*/

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CINEMA_ESERCENTE
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente     L'esercente selezionato
--  p_inclusione        1 se se il cinema cercato deve associato all'esercente, 0 se non deve essere incluso
--
-- OUTPUT: Restituisce i cinema associati all'esercente in ingresso
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CINEMA_ESERCENTE(p_cod_esercente    VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            p_inclusione        NUMBER)
                            RETURN C_ESERCENTE_CINEMA IS
c_cinema_return C_ESERCENTE_CINEMA;
BEGIN
    IF p_cod_esercente IS NULL THEN
        OPEN c_cinema_return FOR
        SELECT CIN.ID_CINEMA, CIN.NOME_CINEMA, COM.COMUNE, null as DATA_INIZIO_VAL, null as DATA_FINE_VAL
        FROM CD_COMUNE COM, CD_CINEMA CIN
        WHERE CIN.ID_COMUNE = COM.ID_COMUNE
        ORDER BY CIN.NOME_CINEMA, COM.COMUNE;
    ELSE
        IF p_inclusione = 1 THEN
            OPEN c_cinema_return FOR
            SELECT DISTINCT CIN.ID_CINEMA, CIN.NOME_CINEMA, COM.COMUNE, C.DATA_INIZIO As DATA_INIZIO_VAL, C.DATA_FINE as DATA_FINE_VAL
            FROM CD_COMUNE COM, CD_CINEMA CIN, CD_ESER_CONTRATTO EC, CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC
            WHERE EC.COD_ESERCENTE = NVL(p_cod_esercente,EC.COD_ESERCENTE)
            --AND SYSDATE BETWEEN NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) AND NVL(EC.DATA_FINA,to_date('31122999','DDMMYYYY'))
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            --AND SYSDATE BETWEEN C.DATA_INIZIO AND NVL(C.DATA_FINE,to_date('31122999','DDMMYYYY'))
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND COM.ID_COMUNE = CIN.ID_COMUNE
            ORDER BY CIN.NOME_CINEMA, COM.COMUNE;
        ELSIF p_inclusione = 0 THEN
            OPEN c_cinema_return FOR
            SELECT DISTINCT CIN.ID_CINEMA, CIN.NOME_CINEMA, COM.COMUNE,null as DATA_INIZIO_VAL, null as DATA_FINE_VAL
            FROM CD_COMUNE COM, CD_CINEMA CIN, CD_ESER_CONTRATTO EC, CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC
            WHERE EC.COD_ESERCENTE = NVL(p_cod_esercente,EC.COD_ESERCENTE)
            --AND SYSDATE BETWEEN EC.DATA_INIZIO AND NVL(EC.DATA_FINA,to_date('31122999','DDMMYYYY'))
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            --AND SYSDATE BETWEEN C.DATA_INIZIO AND NVL(C.DATA_FINE,to_date('31122999','DDMMYYYY'))
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND COM.ID_COMUNE = CIN.ID_COMUNE
            ORDER BY CIN.NOME_CINEMA, COM.COMUNE;
        END IF;        
    END IF;
    return c_cinema_return;
END FU_CINEMA_ESERCENTE;






FUNCTION FU_CINEMA_ARENA_ESERCENTE(p_cod_esercente    VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            p_flg_arena    CD_SALA.FLG_ARENA%TYPE 
                              )
                            RETURN C_ESERCENTE_CINEMA IS
c_cinema_return C_ESERCENTE_CINEMA;
BEGIN
    IF p_cod_esercente IS NULL THEN
        OPEN c_cinema_return FOR
        SELECT DISTINCT CIN.ID_CINEMA, CIN.NOME_CINEMA, COM.COMUNE, null as DATA_INIZIO_VAL, null as DATA_FINE_VAL
        FROM CD_COMUNE COM, CD_CINEMA CIN, cd_sala sa 
        WHERE CIN.ID_COMUNE = COM.ID_COMUNE
        AND SA.ID_CINEMA = CIN.ID_CINEMA
        AND (p_flg_arena is null or SA.FLG_ARENA = p_flg_arena)
        ORDER BY CIN.NOME_CINEMA, COM.COMUNE;
    ELSE
            OPEN c_cinema_return FOR
            SELECT DISTINCT CIN.ID_CINEMA, CIN.NOME_CINEMA, COM.COMUNE, C.DATA_INIZIO As DATA_INIZIO_VAL, C.DATA_FINE as DATA_FINE_VAL
            FROM CD_COMUNE COM, CD_CINEMA CIN, CD_SALA SA, CD_ESER_CONTRATTO EC, CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC
            WHERE EC.COD_ESERCENTE = NVL(p_cod_esercente,EC.COD_ESERCENTE)
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND SA.ID_CINEMA = CIN.ID_CINEMA
            AND (p_flg_arena is null or SA.FLG_ARENA = p_flg_arena)
            AND COM.ID_COMUNE = CIN.ID_COMUNE
            ORDER BY CIN.NOME_CINEMA, COM.COMUNE;     
    END IF;
    return c_cinema_return;
END FU_CINEMA_ARENA_ESERCENTE;




/*
-- --------------------------------------------------------------------------------------------
-- FUNZIONE PR_ASSOCIA_ESERCENTE_CINEMA
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente     Codice dell'esercente da associare al cinema
--  p_id_cinema         Cinema da associare
--  p_esito             Esito della procedura
--
-- OUTPUT: Aggiunge una nuova associazione tra un esercente e un gruppo esercente
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_ESERCENTE_CINEMA(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_cinema CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE%TYPE,
                                      p_esito OUT NUMBER) IS
    --
    BEGIN
    INSERT INTO CD_CINEMA_ESERCENTE(COD_ESERCENTE, ID_CINEMA, DATA_INIZIO_VAL)
    VALUES(p_cod_esercente, p_id_cinema, trunc(sysdate));
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20005, 'PROCEDURA PR_ASSOCIA_ESERCENTE_CINEMA: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);  
END PR_ASSOCIA_ESERCENTE_CINEMA;                                      
-- --------------------------------------------------------------------------------------------
-- FUNZIONE PR_ELIMINA_ESERCENTE_GRUPPO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente     Codice dell'esercente da eliminare dal gruppo
--  p_id_cinema         Id del cinema
--  p_esito             Esito della procedura
--
-- OUTPUT: Aggiunge una nuova associazione tra un esercente e un cinema
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------                                      
PROCEDURE PR_ELIMINA_ESERCENTE_CINEMA(p_cod_esercente CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE,
                                      p_id_cinema CD_CINEMA_ESERCENTE.ID_CINEMA%TYPE,
                                      p_esito OUT NUMBER) IS
    --
    BEGIN
    DELETE FROM CD_CINEMA_ESERCENTE
    WHERE COD_ESERCENTE = p_cod_esercente
    AND ID_CINEMA = p_id_cinema;
    EXCEPTION  
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20006, 'PROCEDURA PR_ELIMINA_ESERCENTE_CINEMA: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_ELIMINA_ESERCENTE_CINEMA;
*/

-- Mauro Viel Altran 13/04/2010 sostituita la tavola cd_gruppo_esercente con la vista vi_cd_gruppo_esercente 
-- e la tavola cd_societa_gruppo con la vista vi_cd_societa_gruppo

FUNCTION FU_CERCA_GRUPPI_ESERCENTE(p_cod_esercente VI_CD_SOCIETA_GRUPPO.COD_ESERCENTE%TYPE) RETURN C_GRUPPO IS
c_gruppo_ret C_GRUPPO;

BEGIN
    OPEN c_gruppo_ret 
    FOR
        SELECT G.ID_GRUPPO_ESERCENTE, NOME_GRUPPO, SG.DATA_INIZIO_VAL AS DATA_INIZIO, SG.DATA_FINE_VAL AS DATA_FINE
        FROM VI_CD_GRUPPO_ESERCENTE G, VI_CD_SOCIETA_GRUPPO SG
        WHERE SG.COD_ESERCENTE = p_cod_esercente
        AND G.ID_GRUPPO_ESERCENTE = SG.ID_GRUPPO_ESERCENTE
        AND SYSDATE BETWEEN SG.DATA_INIZIO_VAL AND NVL(SG.DATA_FINE_VAL,to_date('31122999','DDMMYYYY'))
        ORDER BY NOME_GRUPPO;
    RETURN c_gruppo_ret;
END FU_CERCA_GRUPPI_ESERCENTE;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CONTRATTI_ESERCENTE
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente     L'esercente selezionato
--
-- OUTPUT: Restituisce i contratti legati all'esercente in ingresso
--
-- REALIZZATORE  Michele Borgogno, Altran, Marzo 2010
-- Modifica      MAuro Viel Altran  Dicembre 2011 modificato il filtro cinema #MV01
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CONTRATTI_ESERCENTE(p_cod_esercente CD_ESER_CONTRATTO.COD_ESERCENTE%TYPE,
                                p_id_cinema CD_CINEMA.ID_CINEMA%TYPE)
                            RETURN C_CONTRATTO IS
c_contratti_return C_CONTRATTO;
BEGIN

    OPEN c_contratti_return FOR
        SELECT  
                DISTINCT c.ID_CONTRATTO, 
                es.COD_ESERCENTE, 
                es.RAGIONE_SOCIALE, 
                c.DATA_INIZIO,c.DATA_FINE, 
                c.DATA_RISOLUZIONE, 
                c.FLG_ARENA
        FROM    CD_COMUNE com, 
                CD_CINEMA cin, 
                CD_CINEMA_CONTRATTO cc, 
                CD_CONTRATTO c,
                CD_ESER_CONTRATTO ec, 
                VI_CD_SOCIETA_ESERCENTE es
        WHERE   es.COD_ESERCENTE = NVL(p_cod_esercente,es.COD_ESERCENTE)
        AND     ec.COD_ESERCENTE = es.COD_ESERCENTE
        AND     c.ID_CONTRATTO = ec.ID_CONTRATTO
        AND     cc.ID_CONTRATTO(+) = c.ID_CONTRATTO
        --AND     (cc.ID_CINEMA IS NULL OR cc.ID_CINEMA = NVL(p_id_cinema,cc.ID_CINEMA));  #MV01 
        AND     (nvl(cc.ID_CINEMA,0) = NVL(p_id_cinema,nvl(cc.ID_CINEMA,0))); ---filtro Cinema   #MV01


    return c_contratti_return;
END FU_CONTRATTI_ESERCENTE;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ESERCENTI_CONTRATTO
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_id_contratto       identificativo del contratto
--
-- OUTPUT: Restituisce lo storico degli esercenti che sono subentrati nel contratto
--         nel corso del tempo
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, gennaio 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ESERCENTI_CONTRATTO(p_id_contratto   cd_contratto.id_contratto%TYPE) 
                                RETURN C_ESER_CONTRATTO IS
c_return C_ESER_CONTRATTO;
BEGIN

    OPEN c_return FOR
        select distinct 
                cd_eser_contratto.ID_CONTRATTO,
                cd_eser_contratto.COD_ESERCENTE,
                vi_cd_societa_esercente.RAGIONE_SOCIALE,
                vi_cd_societa_esercente.PART_IVA,
                cd_eser_contratto.DATA_INIZIO,
                cd_eser_contratto.data_fine
        from 
                cd_eser_contratto,
                vi_cd_societa_esercente
        where   cd_eser_contratto.COD_ESERCENTE = vi_cd_societa_esercente.cod_esercente
        and     cd_eser_contratto.id_contratto = nvl(p_id_contratto,cd_eser_contratto.id_contratto)
        order by ragione_sociale;
    return c_return;
END FU_ESERCENTI_CONTRATTO;
-- --------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_CONTRATTO
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:         Inserisce un nuovo contratto per un esercente
-- INPUT:
--  p_cod_esercente     Codice dell'esercente associato al contratto
--  p_data_inizio       Data di inizio del contratto
--  p_data_fine         Data di fine del contratto
--
-- OUTPUT: 
--  p_id_contratto      Id del contratto creato, se la procedura e terminata correttamente
--  p_esito             Esito della procedura
--
-- REALIZZATORE  
--          Simone Bottani, Altran, Marzo 2010
-- MODIFICHE
--          Tommaso D'Anna, Teoresi s.r.l., 11 Luglio 2011
--          - Inserito controllo validita' data inizio/data fine
-- --------------------------------------------------------------------------------------------                                      
PROCEDURE PR_INSERISCI_CONTRATTO(p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                 p_data_inizio CD_CONTRATTO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_CONTRATTO.DATA_FINE%TYPE,
                                 p_flg_arena CD_CONTRATTO.FLG_ARENA%TYPE,
                                 p_id_contratto OUT CD_CONTRATTO.ID_CONTRATTO%TYPE,
                                 p_esito       OUT NUMBER
                                 ) IS

v_num_contratti NUMBER;
BEGIN
    IF p_data_fine < p_data_inizio THEN
        p_esito := -3;
    ELSE
        p_esito := 1;
        SAVEPOINT PR_INSERISCI_CONTRATTO;
        --
        INSERT INTO CD_CONTRATTO(DATA_INIZIO, DATA_FINE, FLG_ARENA)
        VALUES
        (TRUNC(p_data_inizio),TRUNC(p_data_fine), p_flg_arena);
        SELECT CD_CONTRATTO_SEQ.CURRVAL INTO p_id_contratto FROM DUAL;
        --
        INSERT INTO CD_ESER_CONTRATTO(ID_CONTRATTO, COD_ESERCENTE, DATA_INIZIO, DATA_FINE)
        VALUES
        (p_id_contratto, p_cod_esercente, p_data_inizio, p_data_fine);
        --    
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20007, 'PROCEDURA PR_INSERISCI_CONTRATTO: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
        ROLLBACK TO PR_INSERISCI_CONTRATTO;
END PR_INSERISCI_CONTRATTO;

-- --------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_CONTRATTO_CINEMA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Associa un cinema ad un contratto esistente
-- INPUT:
--  p_id_contratto      Id del contratto
--  p_id_cinema         Id del cinema 
--  p_giorno_chiusura   Giorno di chiusura settimanale del cinema
--  p_ferie_estive      Numero di giorni di ferie estive per il cinema
--  p_ferie_extra       Numero di giorni di ferie extra per il cinema
-- OUTPUT: 
--  p_esito             Esito della procedura: 
--                            1 Eseguito correttamente
--                            -1 Errore generico
--                            -2 Esiste gia un contratto valido per quel cinema nel periodo indicato
--                            -3 Primo contratto per il cinema e data inizio validita differente da
--                                  quella del cinema
--                            -4 Data inizio validita' del contratto inferiore alla data inizio validita
--                                  del cinema
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------                                      
PROCEDURE PR_INSERISCI_CONTRATTO_CINEMA(p_id_contratto CD_CONTRATTO.ID_CONTRATTO%TYPE,
                                        p_id_cinema CD_CINEMA.ID_CINEMA%TYPE,
                                        p_giorno_chiusura CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE,
                                        p_ferie_estive CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE%TYPE,
                                        p_importo CD_CINEMA_CONTRATTO.IMPORTO%TYPE,
                                        p_data_pagamento CD_CINEMA_CONTRATTO.DATA_PAGAMENTO_FATTURA%TYPE,
                                        p_esito       OUT NUMBER
                                        ) IS 
v_id_cinema_contratto   CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE;   
v_num_contratti         NUMBER; 
v_flg_arena             CD_CONTRATTO.FLG_ARENA%TYPE;
v_data_inizio_cin       CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE;
v_data_inizio_con       CD_CONTRATTO.DATA_INIZIO%TYPE;
    BEGIN
    p_esito := 1;
    SAVEPOINT PR_INSERISCI_CONTRATTO_CINEMA;
    --
    
    SELECT COUNT(1)
    INTO v_num_contratti
    FROM CD_CINEMA_CONTRATTO
    WHERE CD_CINEMA_CONTRATTO.ID_CINEMA = p_id_cinema;
    -- Per verificare che il contratto sia il primo per il cinema in questione
    
    SELECT trunc(DATA_INIZIO_VALIDITA)
    INTO v_data_inizio_cin
    FROM CD_CINEMA
    WHERE ID_CINEMA = p_id_cinema;
        
    SELECT trunc(DATA_INIZIO)
    INTO v_data_inizio_con
    FROM CD_CONTRATTO
    WHERE ID_CONTRATTO = p_id_contratto;       
    
    IF v_num_contratti = 0 THEN
        -- E' il primo contratto per il cinema        
        IF  v_data_inizio_cin != v_data_inizio_con THEN
            p_esito := -3;
        END IF;        
    END IF;
         
    IF p_esito > 0 THEN
        IF v_data_inizio_con < v_data_inizio_cin THEN
            p_esito := -4;
        ELSE
            SELECT COUNT(1)
            INTO v_num_contratti
            FROM CD_CONTRATTO C1, CD_CONTRATTO C2, CD_CINEMA_CONTRATTO CC
            WHERE CC.ID_CINEMA = p_id_cinema
            AND C2.ID_CONTRATTO = CC.ID_CONTRATTO
            AND C1.ID_CONTRATTO = p_id_contratto
            AND C1.DATA_FINE >= C2.DATA_INIZIO
            AND C1.DATA_INIZIO <= NVL(C2.DATA_RISOLUZIONE,C2.DATA_FINE);
            --
            IF v_num_contratti > 0 THEN
                p_esito := -2;
            ELSE
                SELECT FLG_ARENA
                INTO v_flg_arena
                FROM CD_CONTRATTO
                WHERE ID_CONTRATTO = p_id_contratto;    
                INSERT INTO CD_CINEMA_CONTRATTO(ID_CONTRATTO, ID_CINEMA, IMPORTO, DATA_PAGAMENTO_FATTURA, FLG_RIPARTIZIONE)
                VALUES
                (p_id_contratto, p_id_cinema, p_importo, p_data_pagamento,'S');
                SELECT CD_CINEMA_CONTRATTO_SEQ.CURRVAL INTO v_id_cinema_contratto FROM DUAL;
                --
                IF v_flg_arena = 'N' THEN
                    INSERT INTO CD_CONDIZIONE_CONTRATTO(ID_CINEMA_CONTRATTO,GIORNO_CHIUSURA, NUM_FERIE_ESTIVE)
                    VALUES
                    (v_id_cinema_contratto,p_giorno_chiusura, p_ferie_estive);
                END IF;
            END IF;         
        END IF;     
    END IF;      
    --
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20008, 'PROCEDURA PR_INSERISCI_CONTRATTO_CINEMA: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
        ROLLBACK TO PR_INSERISCI_CONTRATTO_CINEMA;
END PR_INSERISCI_CONTRATTO_CINEMA;                                        
-- --------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_PERC_RIPARTIZIONE
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Associa una nuova percentuale di ripartizione ad un contratto esistente
-- INPUT:
--  p_id_contratto         Id del contratto
--  p_id_cinema            Id del cinema 
--  p_data_inizio          Data di inizio di validita della percentuale di ripartizione
--  p_data_fine            Data di fine di validita della percentuale di ripartizione
--  p_categoria_prodotto   Categoria prodotto (Tabellare o Iniziativa Speciale) della percentuale di ripartizione
--  p_perc_ripartizione    Percentuale di ripartizione di competenza dell'esercente
-- OUTPUT: 
--  p_esito                Esito della procedura 
--                             1 Eseguito correttamente
--                            -1 Errore generico
--                            -2 Esiste gia una percentuale di ripartizione per il contratto nel periodo richiesto
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------                                      
PROCEDURE PR_INSERISCI_PERC_RIPARTIZIONE(p_id_contratto CD_CINEMA_CONTRATTO.ID_CONTRATTO%TYPE,
                                        p_id_cinema CD_CINEMA_CONTRATTO.ID_CINEMA%TYPE,
                                        p_data_inizio CD_PERCENTUALE_RIPARTIZIONE.DATA_INIZIO%TYPE,
                                        p_data_fine CD_PERCENTUALE_RIPARTIZIONE.DATA_FINE%TYPE,
                                        p_categoria_prodotto CD_PERCENTUALE_RIPARTIZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                        p_perc_ripartizione CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE,
                                        p_esito       OUT NUMBER
                                        ) IS
--
v_id_cinema_contratto CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE;
v_num_contratti NUMBER;
BEGIN
    p_esito := 1;
    SELECT COUNT(1)
    INTO v_num_contratti
    FROM CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC, CD_PERCENTUALE_RIPARTIZIONE PR
    WHERE PR.COD_CATEGORIA_PRODOTTO = p_categoria_prodotto
    AND PR.DATA_FINE >= p_data_inizio
    AND PR.DATA_INIZIO <= p_data_fine
    AND CC.ID_CINEMA_CONTRATTO = PR.ID_CINEMA_CONTRATTO
    AND CC.ID_CINEMA = p_id_cinema
    AND CC.ID_CONTRATTO = p_id_contratto;
    --
    IF v_num_contratti > 0 THEN
        p_esito := -2;
    ELSE
        SELECT ID_CINEMA_CONTRATTO
        INTO v_id_cinema_contratto
        FROM CD_CINEMA_CONTRATTO
        WHERE ID_CONTRATTO = p_id_contratto
        AND ID_CINEMA = p_id_cinema;
        --
        INSERT INTO CD_PERCENTUALE_RIPARTIZIONE(ID_CINEMA_CONTRATTO,COD_CATEGORIA_PRODOTTO, PERC_RIPARTIZIONE, DATA_INIZIO, DATA_FINE)
        VALUES
        (v_id_cinema_contratto, p_categoria_prodotto, p_perc_ripartizione,TRUNC(p_data_inizio),TRUNC(p_data_fine));
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20009, 'PROCEDURA PR_INSERISCI_PERC_RIPARTIZIONE: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_INSERISCI_PERC_RIPARTIZIONE;

-- --------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_CONTRATTO
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:         Modifica un contratto esistente
-- INPUT:
--  p_id_contratto      Id del contratto
--  p_data_inizio       Data di inizio del contratto
--  p_data_fine         Data di fine del contratto
--  p_data_risoluzione  Data di risoluzione del contratto
--
-- OUTPUT: 
--  p_esito             Esito della procedura
--                            1 Eseguito correttamente
--                           -1 Errore generico
--                           -2 Esiste gia un contratto valido per quel cinema nel periodo indicato
--                           -3 Data fine minore di data inizio!
--                           -5 Cambio data validita' cinema per il primo contratto
--
-- REALIZZATORE  
--          Simone Bottani, Altran, Marzo 2010
-- MODIFICHE
--          Tommaso D'Anna, Teoresi s.r.l., 11 Luglio 2011
--          - Inserito controllo validita' data inizio/data fine
-- --------------------------------------------------------------------------------------------                                      
PROCEDURE PR_MODIFICA_CONTRATTO( p_id_contratto CD_CONTRATTO.ID_CONTRATTO%TYPE,
                                 p_data_inizio CD_CONTRATTO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_CONTRATTO.DATA_FINE%TYPE,
                                 p_data_risoluzione CD_CONTRATTO.DATA_RISOLUZIONE%TYPE,
                                 p_flg_arena CD_CONTRATTO.FLG_ARENA%TYPE,
                                 p_esito       OUT NUMBER
                                 ) 
IS
--
v_num_contratti NUMBER;
v_date          DATE;
BEGIN
    p_esito := 1;
    IF p_data_fine < p_data_inizio THEN
        p_esito := -3;
    ELSE
        --Numero di contratti per il cinema al quale questo contratto e' associato
        SELECT COUNT(1)
        INTO v_num_contratti
        FROM CD_CINEMA_CONTRATTO
        WHERE ID_CINEMA IN (
            SELECT ID_CINEMA 
            FROM CD_CINEMA_CONTRATTO 
            WHERE ID_CONTRATTO = p_id_contratto 
        );
            
        IF v_num_contratti = 1 THEN
            -- E' l'unico contratto, quindi il primo
            SELECT DISTINCT (DATA_INIZIO_VALIDITA)
            INTO v_date
            FROM CD_CINEMA
            WHERE ID_CINEMA IN (
                SELECT ID_CINEMA 
                FROM CD_CINEMA_CONTRATTO 
                WHERE ID_CONTRATTO = p_id_contratto 
            );
            -- Non posso cambiare la data di validita! 
            IF ( p_data_inizio != v_date ) THEN
                p_esito := -5;           
            END IF;    
        END IF;     
    
        IF ( p_esito > 0 ) THEN
            --Controllo la sovrapposizione dei contratti
            SELECT COUNT(1)
            INTO v_num_contratti
            FROM CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC
            WHERE CC.ID_CONTRATTO != p_id_contratto
            AND CC.ID_CINEMA IN (SELECT ID_CINEMA FROM CD_CINEMA_CONTRATTO WHERE ID_CONTRATTO = p_id_contratto)
            AND C.ID_CONTRATTO = CC.ID_CONTRATTO
            AND NVL(C.DATA_RISOLUZIONE,C.DATA_FINE) >= p_data_inizio
            AND C.DATA_INIZIO <= p_data_fine;
            --
            IF v_num_contratti > 0 THEN
                p_esito := -2;
            ELSE                     
                SAVEPOINT PR_MODIFICA_CONTRATTO;
                UPDATE CD_CONTRATTO
                SET DATA_INIZIO = TRUNC(p_data_inizio),
                DATA_FINE = TRUNC(p_data_fine),
                DATA_RISOLUZIONE = TRUNC(p_data_risoluzione),
                FLG_ARENA = p_flg_arena
                WHERE ID_CONTRATTO = p_id_contratto;
                --
                UPDATE CD_ESER_CONTRATTO
                SET DATA_INIZIO = p_data_inizio,
                DATA_FINE = p_data_fine
                WHERE ID_CONTRATTO = p_id_contratto;
            END IF;          
        END IF;  
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20007, 'PROCEDURA PR_MODIFICA_CONTRATTO: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
        ROLLBACK TO PR_MODIFICA_CONTRATTO;
END PR_MODIFICA_CONTRATTO;
-- --------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_CONTRATTO_CINEMA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Associa un cinema ad un contratto esistente
-- INPUT:
--  p_id_cinema_contratto      Id del contratto cinema
--  p_giorno_chiusura          Giorno di chiusura settimanale del cinema
--  p_ferie_estive             Numero di giorni di ferie estive per il cinema
--  p_ferie_extra              Numero di giorni di ferie extra per il cinema
-- OUTPUT: 
--  p_esito             Esito della procedura:
--                            1 Eseguito correttamente
--                           -1 Errore generico
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------                                      
PROCEDURE PR_MODIFICA_CONTRATTO_CINEMA(p_id_cinema_contratto CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE,
                                 p_giorno_chiusura CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE,
                                 p_ferie_estive CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE%TYPE,
                                 p_importo CD_CINEMA_CONTRATTO.IMPORTO%TYPE,
                                 p_data_pagamento CD_CINEMA_CONTRATTO.DATA_PAGAMENTO_FATTURA%TYPE,
                                 p_esito       OUT NUMBER
                                 ) IS
BEGIN
    p_esito := 1;
    
    UPDATE CD_CINEMA_CONTRATTO
    SET IMPORTO = p_importo,
        DATA_PAGAMENTO_FATTURA = p_data_pagamento
    WHERE ID_CINEMA_CONTRATTO = p_id_cinema_contratto;
    --        
    UPDATE CD_CONDIZIONE_CONTRATTO
    SET GIORNO_CHIUSURA = p_giorno_chiusura,
        NUM_FERIE_ESTIVE = p_ferie_estive
    WHERE ID_CINEMA_CONTRATTO = p_id_cinema_contratto;
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20007, 'PR_MODIFICA_CONTRATTO_CINEMA: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);  
END PR_MODIFICA_CONTRATTO_CINEMA;                                     

-- --------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_PERC_RIPARTIZIONE
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Modifica una percentuale di ripartizione
-- INPUT:
--  p_id_perc_ripartizione         Id della percentuale di ripartizione
--  p_data_inizio                  Data di inizio di validita della percentuale di ripartizione
--  p_data_fine                    Data di fine di validita della percentuale di ripartizione
--  p_categoria_prodotto           Categoria prodotto (Tabellare o Iniziativa Speciale) della percentuale di ripartizione
--  p_perc_ripartizione            Percentuale di ripartizione di competenza dell'esercente
-- OUTPUT: 
--  p_esito                Esito della procedura
--                             1 Eseguito correttamente
--                            -1 Errore generico
--                            -2 Esiste gia una percentuale di ripartizione per il contratto nel periodo richiesto
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------                                      
PROCEDURE PR_MODIFICA_PERC_RIPARTIZIONE( p_id_perc_ripartizione CD_PERCENTUALE_RIPARTIZIONE.ID_PERC_RIPARTIZIONE%TYPE,
                                 p_data_inizio CD_CONTRATTO.DATA_INIZIO%TYPE,
                                 p_data_fine CD_CONTRATTO.DATA_FINE%TYPE,
                                 p_categoria_prodotto CD_PERCENTUALE_RIPARTIZIONE.COD_CATEGORIA_PRODOTTO%TYPE,
                                 p_perc_ripartizione CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE,
                                 p_esito       OUT NUMBER
                                 ) IS
v_num_contratti NUMBER;
BEGIN
    p_esito := 1;
    --
    SELECT COUNT(1)
    INTO v_num_contratti
    FROM CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC, CD_PERCENTUALE_RIPARTIZIONE PR
    WHERE PR.ID_PERC_RIPARTIZIONE != p_id_perc_ripartizione
    AND CC.ID_CINEMA_CONTRATTO = 
    (SELECT ID_CINEMA_CONTRATTO FROM CD_PERCENTUALE_RIPARTIZIONE PR2
     WHERE PR2.ID_PERC_RIPARTIZIONE = p_id_perc_ripartizione)
    AND PR.COD_CATEGORIA_PRODOTTO = p_categoria_prodotto
    AND PR.DATA_FINE >= p_data_inizio
    AND PR.DATA_INIZIO <= p_data_fine
    AND PR.ID_CINEMA_CONTRATTO = CC.ID_CINEMA_CONTRATTO
    AND C.ID_CONTRATTO = CC.ID_CONTRATTO;
    --
    IF v_num_contratti > 0 THEN
        p_esito := -2;
    ELSE
        UPDATE CD_PERCENTUALE_RIPARTIZIONE
        SET COD_CATEGORIA_PRODOTTO = p_categoria_prodotto, 
        PERC_RIPARTIZIONE = p_perc_ripartizione,
        DATA_INIZIO = TRUNC(p_data_inizio),
        DATA_FINE = TRUNC(p_data_fine)
        WHERE ID_PERC_RIPARTIZIONE = p_id_perc_ripartizione;
    END IF;    
END PR_MODIFICA_PERC_RIPARTIZIONE;    
-- --------------------------------------------------------------------------------------------
-- Procedura PR_SUBENTRO_ESERCENTE
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Permette la gestione di un subentro nel contratto Esercente-Sipra
--
-- OPERAZIONI PREVISTE: valorizzazione (data_subentro-1(giorno)) al vecchio esercente 
--                      associato all'identificativo del contratto passato come parametro (tavola CD_ESER_CONTRATTO)
--                      inserimento nuova occorrenza per il nuovo esercente (tavola CD_ESER_CONTRATTO)
--                      a questo livello non viene fatto alcun controllo sull'ugualianza esercente/(esercente-1)
--                      si suppone fatto prima della chiamata  
--
-- INPUT:
--  p_id_contratto      identificativo del contratto
--  p_nuovo_esercente   identificativo dell'esercente che sta subentrando
--  p_data_subentro     data del subentro del nuovo esercente
--
-- OUTPUT: 
--  p_esito             Esito della procedura
--                             1 Eseguito correttamente
--                            -1 Errore generico
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Gennaio 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_SUBENTRO_ESERCENTE(p_id_contratto          cd_contratto.id_contratto%type,
                                p_vecchio_esercente     vi_cd_societa_esercente.cod_esercente%type,
                                p_nuovo_esercente       vi_cd_societa_esercente.cod_esercente%type,
                                p_data_subentro         date,
                                p_esito OUT             NUMBER)
IS
v_data_fine DATE;
BEGIN
    p_esito := 1;
    SAVEPOINT SP_SUBENTRO_ESERCENTE;
    select data_fine into v_data_fine 
    from cd_contratto
    where id_contratto = p_id_contratto;
    --
    /*Aggiorno vecchio esercente*/
    update cd_eser_contratto
    set   data_fine     = (p_data_subentro - 1)
    where id_contratto  = p_id_contratto
    and   cod_esercente = p_vecchio_esercente;
    /*Inserisco nuovo esercente nel contratto*/
    insert into cd_eser_contratto
    (id_contratto,cod_esercente,data_inizio,data_fine)
    values
    (p_id_contratto,p_nuovo_esercente,p_data_subentro,v_data_fine);
    --
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20007, 'ERRORE DURANTE PROCEDURA SP_SUBENTRO_ESERCENTE:'||SQLERRM);
        ROLLBACK TO SP_SUBENTRO_ESERCENTE;
END PR_SUBENTRO_ESERCENTE;
-- --------------------------------------------------------------------------------------------
-- Funzione FU_CONDIZIONI_CONTRATTO
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Restituisce le condizioni contrattuali e le percentuali di ripartizione di un contratto
-- INPUT:
--  p_id_contratto         Id del contratto
-- OUTPUT: 
--  Lista di condizioni contrattuali
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------                                      
FUNCTION FU_CONDIZIONI_CONTRATTO(p_id_contratto CD_CINEMA_CONTRATTO.ID_CONTRATTO%TYPE,
                                 p_id_cinema_contratto CD_PERCENTUALE_RIPARTIZIONE.ID_CINEMA_CONTRATTO%TYPE) RETURN C_CONDIZIONE_CONTRATTO IS
c_contratti_return C_CONDIZIONE_CONTRATTO;
BEGIN
        OPEN c_contratti_return FOR
        SELECT  cc.ID_CONTRATTO, cc.ID_CINEMA_CONTRATTO, pr.ID_PERC_RIPARTIZIONE,  pr.DATA_INIZIO, pr.DATA_FINE,
                pr.COD_CATEGORIA_PRODOTTO, pr.PERC_RIPARTIZIONE, cp.DESCRIZIONE, cin.ID_CINEMA, cin.NOME_CINEMA, com.COMUNE,
                PA_CD_UTILITY.GET_DAY(COND.GIORNO_CHIUSURA) AS GIORNO_CHIUSURA, cond.NUM_FERIE_ESTIVE, 
                cc.FLG_RIPARTIZIONE, cc.DATA_PAGAMENTO_FATTURA, cc.IMPORTO
        FROM    CD_PERCENTUALE_RIPARTIZIONE pr, 
                PC_CATEGORIA_PRODOTTO cp, CD_CONDIZIONE_CONTRATTO COND, CD_CINEMA_CONTRATTO cc, CD_CINEMA cin, CD_COMUNE com
        WHERE   (p_id_contratto IS NULL OR cc.ID_CONTRATTO = p_id_contratto)
        AND     (p_id_cinema_contratto IS NULL OR cc.ID_CINEMA_CONTRATTO = p_id_cinema_contratto)
        AND     pr.ID_CINEMA_CONTRATTO(+) = cc.ID_CINEMA_CONTRATTO
        AND     cin.ID_CINEMA = cc.ID_CINEMA
        AND     com.ID_COMUNE = cin.ID_COMUNE
        AND     cp.COD(+) = pr.COD_CATEGORIA_PRODOTTO
        AND     COND.ID_CINEMA_CONTRATTO(+) = cc.ID_CINEMA_CONTRATTO;
RETURN c_contratti_return;
END FU_CONDIZIONI_CONTRATTO;
-- --------------------------------------------------------------------------------------------
-- Funzione FU_RAPPRESENTANTI_LEGALI
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Restituisce i rappresentanti legali di un esercente
-- INPUT:
--  p_cod_esercente         Codice dell'esercente
-- OUTPUT: 
--  Stringa con i rappresentanti legati concatenati
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------                                      
/*FUNCTION FU_RAPPRESENTANTI_LEGALI(p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE) RETURN VARCHAR2 IS
v_rappr_legali VARCHAR2(1024) := '';
    BEGIN
    FOR RESP IN(SELECT RESPONSABILE_LEGALE FROM VI_CD_SOCIETA_ESERCENTE ES
         WHERE ES.COD_ESERCENTE = p_cod_esercente) LOOP
        v_rappr_legali := v_rappr_legali || RESP.RESPONSABILE_LEGALE || ', ';
    END LOOP;     
    RETURN v_rappr_legali;
END FU_RAPPRESENTANTI_LEGALI;*/

-- --------------------------------------------------------------------------------------------
-- Funzione FU_QUOTE_ESERCENTI
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE:  Restituisce le quote esercenti per un periodo
-- INPUT:
--  p_cod_esercente         Codice dell'esercente
--  p_data_inizio           Inizio del periodo di liquidazione
--  p_data_fine             Fine del periodo di liquidazione
-- OUTPUT: 
-- Quote esercenti trovate
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- Mauro Viel Altran 13/04/2010 sostituita la tavola cd_gruppo_esercente con la vista vi_cd_gruppo_esercente
-- Mauro Viel Altran 28/01/2011 inserita la quota tab e la quota isp.
-- --------------------------------------------------------------------------------------------                                      
FUNCTION FU_QUOTE_ESERCENTI(p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE, 
                            p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                            p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                            p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE
                            ) RETURN C_QUOTA_ESERCENTE IS
v_quote C_QUOTA_ESERCENTE;
v_esito NUMBER;
    BEGIN
    --
    OPEN v_quote FOR
        SELECT DISTINCT ES.COD_ESERCENTE, ES.RAGIONE_SOCIALE, Q.QUOTA_ESERCENTE, 
        DECODE(Q.STATO_LAVORAZIONE,'ANT','Anteprima','DAL','Da liquidare','LIQ','Liquidato') AS STATO_LAVORAZIONE,
        GE.NOME_GRUPPO, Q.GG_SAN_RIT_PART, Q.GG_CHIUSURA_CONC, FU_GET_QUOTA_TAB(p_data_inizio,p_data_fine, ES.COD_ESERCENTE) as quota_tab, FU_GET_QUOTA_ISP(p_data_inizio,p_data_fine, ES.COD_ESERCENTE) as quota_isp
        FROM VI_CD_SOCIETA_GRUPPO GR, VI_CD_GRUPPO_ESERCENTE GE,  VI_CD_SOCIETA_ESERCENTE ES, CD_LIQUIDAZIONE LIQ, CD_QUOTA_ESERCENTE Q
        WHERE (p_cod_esercente IS NULL OR Q.COD_ESERCENTE = p_cod_esercente)
        AND GR.COD_ESERCENTE(+) = ES.COD_ESERCENTE
        AND GE.ID_GRUPPO_ESERCENTE = GR.ID_GRUPPO_ESERCENTE
        AND (p_id_gruppo IS NULL OR GR.ID_GRUPPO_ESERCENTE = p_id_gruppo)
        AND NVL(GR.DATA_FINE_VAL,to_Date('31122999','DDMMYYYY')) >= p_data_inizio
        AND GR.DATA_INIZIO_VAL <= p_data_fine
        AND Q.ID_LIQUIDAZIONE = LIQ.ID_LIQUIDAZIONE
        AND LIQ.DATA_INIZIO = TRUNC(p_data_inizio)
        AND LIQ.DATA_FINE = TRUNC(p_data_fine)
        AND ES.COD_ESERCENTE = Q.COD_ESERCENTE
        ORDER BY ES.RAGIONE_SOCIALE;
RETURN v_quote;
END FU_QUOTE_ESERCENTI;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CALCOLA_QUOTE_LIQUIDAZIONE
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Calcola le quote per il pagamento degli esercenti in un periodo
--
-- INPUT:
--  p_data_inizio       Data di inizio del periodo
--  p_data_fine         Data di fine del periodo
--  p_cod_esercente     Codice dell'esercente
--  p_id_gruppo         Id del gruppo esercente
--  
--
-- OUTPUT: 
--        p_esito             Esito dell'operazione
--
-- OPERAZIONI: 
--             1) 
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------    
PROCEDURE PR_CALCOLA_QUOTE_LIQUIDAZIONE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                  p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                  p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                  p_esito OUT NUMBER) IS
--
v_esito NUMBER;  
v_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE;
v_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE;
v_stato_lavorazione CD_LIQUIDAZIONE.STATO_LAVORAZIONE%TYPE;
  
    BEGIN
    v_data_inizio := TRUNC(p_data_inizio);
    v_data_fine := TRUNC(p_data_fine);
    --
    BEGIN
        SELECT STATO_LAVORAZIONE
        INTO v_stato_lavorazione
        FROM CD_LIQUIDAZIONE
        WHERE DATA_INIZIO = v_data_inizio
        AND DATA_FINE = v_data_fine;
    EXCEPTION
        WHEN OTHERS THEN
        NULL;
    END;
    IF v_stato_lavorazione IS NULL OR v_stato_lavorazione = 'ANT' THEN
        --
        PR_CALCOLA_LIQUIDAZIONE(v_data_inizio, v_data_fine, v_esito);
        --
        PR_CALCOLA_QUOTA_TAB(v_data_inizio, v_data_fine, p_cod_esercente, p_id_gruppo, v_esito);
        --
        PR_CALCOLA_QUOTA_ISP(v_data_inizio, v_data_fine, p_cod_esercente, p_id_gruppo, v_esito);
        --
        PR_CALCOLA_QUOTA_ESERCENTE(v_data_inizio, v_data_fine, p_cod_esercente, p_id_gruppo, v_esito);
        --
        UPDATE CD_LIQUIDAZIONE L
        SET STATO_LAVORAZIONE = 'ANT'
        WHERE DATA_INIZIO = v_data_inizio
        AND DATA_FINE = v_data_fine
        AND EXISTS
        (SELECT * FROM CD_QUOTA_ESERCENTE
         WHERE ID_LIQUIDAZIONE = L.ID_LIQUIDAZIONE
         AND STATO_LAVORAZIONE != 'DAL'
         );
     END IF;
END PR_CALCOLA_QUOTE_LIQUIDAZIONE; 

                         
FUNCTION FU_CINEMA_CONTRATTO(p_id_contratto CD_CONTRATTO.ID_CONTRATTO%TYPE) RETURN C_CINEMA_CONTRATTO IS
v_cinema_contratto C_CINEMA_CONTRATTO;
    BEGIN
    OPEN v_cinema_contratto FOR
        SELECT 
                CC.ID_CINEMA_CONTRATTO, 
                CIN.ID_CINEMA, 
                CIN.NOME_CINEMA, 
                COM.COMUNE, 
                PA_CD_UTILITY.GET_DAY(CON.GIORNO_CHIUSURA) AS GIORNO_CHIUSURA, 
                CON.NUM_FERIE_ESTIVE--, CON.NUM_FERIE_EXTRA
        FROM 
                CD_COMUNE COM, 
                CD_CINEMA CIN, 
                CD_CONDIZIONE_CONTRATTO CON, 
                CD_CINEMA_CONTRATTO CC
        WHERE   CC.ID_CONTRATTO = p_id_contratto
        AND     CC.ID_CINEMA_CONTRATTO = CON.ID_CINEMA_CONTRATTO
        AND     CIN.ID_CINEMA = CC.ID_CINEMA
        AND     COM.ID_COMUNE = CIN.ID_COMUNE;
RETURN v_cinema_contratto;
END FU_CINEMA_CONTRATTO;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_PAGA_QUOTE_ESERCENTI
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Conferma le quote dovute agli esercenti per un periodo (generalmente un trimestre)
--
-- INPUT:
--  p_data_inizio       Data di inizio del periodo
--  p_data_fine         Data di fine del periodo
--  
--
-- OUTPUT: 
--        p_esito             Esito dell'operazione
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- MODIFICHE     Mauro Viel, Altran, Settembre 2011 Eliminato il ciclo a favore della update per il caricamento 
--                                                  degli spettatori su cd_liquidazione_sala 
-- --------------------------------------------------------------------------------------------    
PROCEDURE PR_PAGA_QUOTE_ESERCENTI(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                  p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                  p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                  p_esito OUT NUMBER) IS
--
v_esito NUMBER;    
v_liquidazione CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE;
v_stato_lav CD_LIQUIDAZIONE.STATO_LAVORAZIONE%TYPE;
    BEGIN
    SELECT ID_LIQUIDAZIONE, STATO_LAVORAZIONE
    INTO v_liquidazione, v_stato_lav
    FROM CD_LIQUIDAZIONE
    WHERE TRUNC(DATA_INIZIO) = TRUNC(p_data_inizio)
    AND TRUNC(DATA_FINE) = TRUNC(p_data_fine);
    --
    IF v_stato_lav = 'ANT' THEN
        PR_CALCOLA_QUOTE_LIQUIDAZIONE(p_data_inizio, p_data_fine, p_cod_esercente, p_id_gruppo, v_esito);
        
        PA_CD_UTILITY.PR_ABILITA_TRIGGER('N');
        
        update cd_liquidazione_sala ls
        set ls.num_spettatori_eff =
        (
            select sum(se.num_spettatori) num_spettatori
            from cd_spettatori_eff se
            where se.data_riferimento = ls.data_rif
            and se.id_sala=ls.id_sala
        )
        where ls.data_rif between p_data_inizio and p_data_fine;
        
        PA_CD_UTILITY.PR_ABILITA_TRIGGER('S');
        
        --
        UPDATE CD_QUOTA_ESERCENTE Q
        SET STATO_LAVORAZIONE = 'DAL'
        WHERE ID_LIQUIDAZIONE = v_liquidazione
        AND (p_cod_esercente IS NULL OR COD_ESERCENTE = p_cod_esercente)
        AND (p_id_gruppo IS NULL OR Q.COD_ESERCENTE IN 
            (SELECT COD_ESERCENTE FROM VI_CD_SOCIETA_GRUPPO SG
             WHERE SG.ID_GRUPPO_ESERCENTE = p_id_gruppo)
        );
        --
        UPDATE CD_LIQUIDAZIONE L
        SET STATO_LAVORAZIONE = 'DAL'
        WHERE ID_LIQUIDAZIONE = v_liquidazione
        AND NOT EXISTS 
        (SELECT * FROM CD_QUOTA_ESERCENTE
         WHERE ID_LIQUIDAZIONE = L.ID_LIQUIDAZIONE
         AND STATO_LAVORAZIONE != 'DAL'
         );
        --
        /*for c in (  
        select spet.id_sala,spet.num_spettatori,spet.data_riferimento
        from  cd_eser_contratto es_co,
              cd_contratto co,
              cd_cinema_contratto ci_co,
              cd_cinema ci,
              cd_sala sa,
              cd_spettatori_eff spet
        where cod_esercente = p_cod_esercente
        and   co.ID_CONTRATTO = es_co.ID_CONTRATTO
        and   co.data_fine >= p_data_fine 
        and   co.data_inizio <= p_data_inizio 
        and   ci_co.ID_CONTRATTO = co.ID_CONTRATTO
        and   ci_co.id_cinema = ci.id_cinema
        and   sa.id_cinema = ci.id_cinema 
        and   sa.id_sala = spet.id_sala
        and   spet.data_riferimento between p_data_inizio and p_data_fine
        order by spet.id_sala, spet.data_riferimento)
        loop
         update cd_liquidazione_sala 
         set    num_spettatori_eff = c.num_spettatori
         where  id_sala = c.id_sala
         and    data_rif = c.data_riferimento;
        end loop;*/
        
    END IF;
    
END PR_PAGA_QUOTE_ESERCENTI; 

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CALCOLA_LIQUIDAZIONE
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Effettua il calcolo della liquidazione degli esercenti per un periodo (generalmente un trimestre)
--
-- INPUT:
--  p_data_inizio       Data di inizio del periodo
--  p_data_fine         Data di fine del periodo
--  
--
-- OUTPUT: 
--        p_esito             Esito dell'operazione
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CALCOLA_LIQUIDAZIONE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                  p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                  p_esito OUT NUMBER) IS
--
v_netto CD_LIQUIDAZIONE.RICAVO_NETTO%TYPE;
v_spettatori CD_LIQUIDAZIONE.SPETTATORI_EFF%TYPE;
v_liquidazione NUMBER; 
v_netto_isp CD_LIQUIDAZIONE.RICAVO_NETTO%TYPE;  
v_data_fine_temp CD_LIQUIDAZIONE.DATA_FINE%TYPE;
    BEGIN
    --
    SELECT NVL(SUM(FAT.NETTO),0)
    INTO v_netto
    FROM CD_PIANIFICAZIONE PIA, CD_CIRCUITO C, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA, CD_IMPORTI_PRODOTTO IMPP, CD_IMPORTI_FATTURAZIONE IMPF, VI_FT_FATTURATO_CINEMA FAT
    WHERE FAT.DATA_DOCUMENTO BETWEEN p_data_inizio AND p_data_fine
    AND IMPF.ID_IMPORTI_FATTURAZIONE = FAT.ID_IMPORTI_FATTURAZIONE
    AND IMPF.FLG_ANNULLATO = 'N'
    AND IMPP.ID_IMPORTI_PRODOTTO = IMPF.ID_IMPORTI_PRODOTTO
    AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
    AND C.ID_CIRCUITO = PV.ID_CIRCUITO
    AND C.FLG_ARENA = 'N'
    AND PIA.ID_PIANO = PA.ID_PIANO
    AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
    AND PIA.COD_CATEGORIA_PRODOTTO = 'TAB';
    --
    SELECT NVL(SUM(FAT.NETTO),0)
    INTO v_netto_isp
    FROM CD_PIANIFICAZIONE PIA, CD_PRODOTTO_ACQUISTATO PA, CD_IMPORTI_PRODOTTO IMPP, CD_IMPORTI_FATTURAZIONE IMPF, VI_FT_FATTURATO_CINEMA FAT
    WHERE FAT.DATA_DOCUMENTO BETWEEN p_data_inizio AND p_data_fine
    AND IMPF.ID_IMPORTI_FATTURAZIONE = FAT.ID_IMPORTI_FATTURAZIONE
    AND IMPP.ID_IMPORTI_PRODOTTO = IMPF.ID_IMPORTI_PRODOTTO
    AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
    AND PIA.ID_PIANO = PA.ID_PIANO
    AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
    AND PIA.COD_CATEGORIA_PRODOTTO = 'ISP';
    
    SELECT NVL(SUM(S.NUM_SPETTATORI),0)
    INTO v_spettatori
    FROM CD_SPETTATORI_EFF S
    WHERE S.DATA_RIFERIMENTO BETWEEN p_data_inizio AND p_data_fine;
    --
    SELECT COUNT(1)
    INTO v_liquidazione
    FROM CD_LIQUIDAZIONE
    WHERE DATA_INIZIO = p_data_inizio
    AND DATA_FINE = p_data_fine;
    --
    IF v_liquidazione = 0 THEN
        INSERT INTO CD_LIQUIDAZIONE(DATA_INIZIO, DATA_FINE,RICAVO_NETTO, RICAVO_ISP, SPETTATORI_EFF, STATO_LAVORAZIONE)
        VALUES(p_data_inizio, p_data_fine,v_netto,v_netto_isp, v_spettatori,'ANT');
    ELSE
        UPDATE CD_LIQUIDAZIONE
        SET RICAVO_NETTO = v_netto,
            RICAVO_ISP = v_netto_isp,
            SPETTATORI_EFF = v_spettatori
        WHERE DATA_INIZIO = p_data_inizio
        AND DATA_FINE = p_data_fine;
    END IF;
END PR_CALCOLA_LIQUIDAZIONE;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CALCOLA_QUOTA_TAB
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Calcola per ogni sala la quota dovuta all'esercente per la trasmissione tabellare 
--
-- INPUT:
--  p_data_inizio       Data di inizio del periodo
--  p_data_fine         Data di fine del periodo
--  p_cod_esercente     Codice dell'esercente
--  p_id_gruppo         Id del gruppo esercente
--  
--
-- OUTPUT: 
--        p_esito             Esito dell'operazione
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
--  Modifiche :
--  Eliminata  Mauro Viel Altran Italia 04/10/2010  eliminata la condizione  FLG_PROGRAMMAZIONE = 'S' 
--                                                  per il conteggio dei giorni di decurtazione.
--- Inserita la gestione della colonna gg_sanatoria.

---Mauro Viel Altran Italia 21/10/2010 inserito il filtro per escludere le arene
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CALCOLA_QUOTA_TAB_OLD(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                p_esito OUT NUMBER) IS
v_spettatori_sala NUMBER;
v_giorni_decurtazione NUMBER := 0;
v_giorni_decurtazione_temp NUMBER;
v_giorni_sanatoria NUMBER := 0;
v_importo_sanatoria NUMBER := 0;
v_importo_sanatoria_temp NUMBER := 0;
v_ricavo_spettatore CD_QUOTA_TAB.RICAVO_TAB%TYPE;
v_liquidazione CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE;  
v_fatturato_sala CD_QUOTA_TAB.RICAVO_TAB%TYPE;
v_quota_decurtazione NUMBER := 90;
v_quota_sala_tab CD_QUOTA_TAB.RICAVO_TAB%TYPE := 0;
v_quota_sala_tab_temp CD_QUOTA_TAB.RICAVO_TAB%TYPE := 0;
v_quota_sala_ante_decurtazione CD_QUOTA_TAB.QTA_PRE_DECURTAZIONE%TYPE;
v_quota_decurtata CD_QUOTA_TAB.IMP_DECURTAZIONE%TYPE;
v_quota_sala_presente NUMBER;
v_durata_periodo NUMBER;
v_ricavo_giorno NUMBER;
--v_giorni_ferie NUMBER; --MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
--v_ferie_sala NUMBER;   --MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
v_giorni_mancata_proiezione NUMBER;
v_stato_lavorazione CD_QUOTA_ESERCENTE.STATO_LAVORAZIONE%TYPE;
BEGIN
    SELECT ID_LIQUIDAZIONE, DECODE(SPETTATORI_EFF,0,0,RICAVO_NETTO / SPETTATORI_EFF), DATA_FINE - DATA_INIZIO + 1
    INTO v_liquidazione, v_ricavo_spettatore, v_durata_periodo
    FROM CD_LIQUIDAZIONE
    WHERE DATA_INIZIO = p_data_inizio
    AND DATA_FINE = p_data_fine;
    
     
    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
    --PR_CALCOLA_FERIE_CINEMA(v_liquidazione, p_data_inizio, p_data_fine, p_esito);
    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
    
    FOR SALE IN (SELECT SPETT.ID_SALA, CIN.ID_CINEMA, CC.ID_CINEMA_CONTRATTO, 
                 SUM(SPETT.NUM_SPETTATORI)  AS SPETTATORI, COND.NUM_FERIE_ESTIVE, ES.COD_ESERCENTE
                FROM --CD_LIQUIDAZIONE_SALA LS,
                     CD_SPETTATORI_EFF SPETT, CD_CINEMA CIN, CD_CONDIZIONE_CONTRATTO COND, CD_CINEMA_CONTRATTO CC,
                     CD_CONTRATTO C, CD_ESER_CONTRATTO EC, VI_CD_SOCIETA_GRUPPO GR, 
                     VI_CD_SOCIETA_ESERCENTE ES, CD_SALA S
                WHERE SPETT.DATA_RIFERIMENTO BETWEEN p_data_inizio AND p_data_fine
                AND S.ID_SALA = SPETT.ID_SALA
                AND S.FLG_ARENA = 'N'
                AND CC.FLG_RIPARTIZIONE ='S'
                AND S.ID_CINEMA = CIN.ID_CINEMA
                AND CC.ID_CINEMA = CIN.ID_CINEMA
                AND COND.ID_CINEMA_CONTRATTO = CC.ID_CINEMA_CONTRATTO
                AND C.ID_CONTRATTO = CC.ID_CONTRATTO
                AND C.DATA_FINE >= p_data_inizio
                AND C.DATA_INIZIO <= p_data_fine
                AND EC.ID_CONTRATTO = C.ID_CONTRATTO
                AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
                AND ES.COD_ESERCENTE = EC.COD_ESERCENTE
                AND (p_cod_esercente IS NULL OR ES.COD_ESERCENTE = p_cod_esercente)
                AND GR.COD_ESERCENTE(+) = ES.COD_ESERCENTE
                AND GR.DATA_FINE_VAL >= p_data_inizio
                AND GR.DATA_INIZIO_VAL <= p_data_fine
                AND (p_id_gruppo IS NULL OR GR.ID_GRUPPO_ESERCENTE = p_id_gruppo)
                --
                GROUP BY SPETT.ID_SALA, CIN.ID_CINEMA, CC.ID_CINEMA_CONTRATTO, COND.NUM_FERIE_ESTIVE, ES.COD_ESERCENTE
                ) LOOP
                --
                BEGIN
                    SELECT STATO_LAVORAZIONE 
                    INTO v_stato_lavorazione
                    FROM CD_QUOTA_ESERCENTE
                    WHERE ID_LIQUIDAZIONE = v_liquidazione
                    AND COD_ESERCENTE = SALE.COD_ESERCENTE;
                EXCEPTION
                    WHEN OTHERS THEN
                    NULL;
                END;
    
                IF v_stato_lavorazione IS NULL OR v_stato_lavorazione = 'ANT' THEN
                    v_quota_sala_tab := 0;
                    v_giorni_decurtazione := 0;
                    v_fatturato_sala := ROUND(v_ricavo_spettatore * SALE.SPETTATORI,2);
                    v_quota_sala_ante_decurtazione := 0;
                    v_ricavo_giorno := v_fatturato_sala / v_durata_periodo;
                   
                    --
                    SELECT COUNT(1) 
                    INTO v_giorni_mancata_proiezione
                    FROM CD_LIQUIDAZIONE_SALA
                    WHERE ID_SALA = SALE.ID_SALA
                    AND FLG_PROIEZIONE_PUBB = 'N'
                    AND DATA_RIF BETWEEN p_data_inizio AND p_data_fine;
                    
                    FOR PERC IN 
                    (SELECT DISTINCT PER.ID_PERC_RIPARTIZIONE, PER.PERC_RIPARTIZIONE, PER.DATA_INIZIO, PER.DATA_FINE, LEAST(PER.DATA_FINE, p_data_fine) - GREATEST(PER.DATA_INIZIO, p_data_inizio) + 1 AS DURATA_PERC
                    FROM  CD_PERCENTUALE_RIPARTIZIONE PER
                    WHERE PER.ID_CINEMA_CONTRATTO = SALE.ID_CINEMA_CONTRATTO
                    AND NVL(PER.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                    AND NVL(PER.DATA_INIZIO,to_date('01012000','DDMMYYYY')) <= p_data_fine
                    AND PER.COD_CATEGORIA_PRODOTTO = 'TAB'
                    ) LOOP
                        --
                        --dbms_output.put_line('Recuperata percentuale '||CURRENT_TIMESTAMP);
                        --dbms_output.PUT_LINE('Id sala: '||SALE.ID_SALA);
                        --dbms_output.PUT_LINE('Spettatori: '||SALE.SPETTATORI);
                        --dbms_output.PUT_LINE('Ricavo sala: '||v_ricavo_sala);
                        --dbms_output.PUT_LINE('Ricavo giorno: '||v_ricavo_giorno);
                        --dbms_output.PUT_LINE('Durata percentuale'||PERC.DURATA_PERC);
                        --dbms_output.PUT_LINE('Durata periodo'||v_durata_periodo);--*/
                        SELECT COUNT(DISTINCT DATA_RIF)
                        INTO v_giorni_decurtazione_temp
                        FROM CD_LIQUIDAZIONE_SALA L, CD_CODICE_RESP COD
                        WHERE L.ID_SALA = SALE.ID_SALA
                        AND L.FLG_PROIEZIONE_PUBB = 'N'
                        AND L.ID_CODICE_RESP = COD.ID_CODICE_RESP
                        AND COD.AGGREGAZIONE = 'RE' 
                        --AND COD.ID_CODICE_RESP != 3 --MV 31/08/2010 eliminazione del calcolo di giorni di ferie
                        AND DATA_RIF BETWEEN GREATEST(PERC.DATA_INIZIO, p_data_inizio) AND LEAST(PERC.DATA_FINE, p_data_fine);
                        
                        select gg_sanatoria  into v_giorni_sanatoria
                        from   cd_quota_tab
                        where  id_sala = sale.id_sala
                        and    id_liquidazione =  v_liquidazione;
                        
                   
                     
                        v_quota_sala_tab_temp := ((v_ricavo_giorno * PERC.DURATA_PERC) *  (PERC.PERC_RIPARTIZIONE / 100));
                        v_quota_sala_ante_decurtazione := v_quota_sala_ante_decurtazione + v_quota_sala_tab_temp;
                        v_quota_sala_tab_temp := v_quota_sala_tab_temp - (v_quota_sala_tab_temp * (v_giorni_decurtazione_temp / v_quota_decurtazione));
                        v_quota_sala_tab := v_quota_sala_tab + v_quota_sala_tab_temp;
                        v_giorni_decurtazione := v_giorni_decurtazione + v_giorni_decurtazione_temp;
                    END LOOP;
                    --dbms_output.PUT_LINE('Id sala: '||SALE.ID_SALA||' '||CURRENT_TIMESTAMP);
                    v_quota_sala_ante_decurtazione := ROUND(v_quota_sala_ante_decurtazione,2);
                    v_quota_sala_tab := ROUND(v_quota_sala_tab,2);
                    v_quota_decurtata := v_quota_sala_ante_decurtazione - v_quota_sala_tab;
                    
                    
                    
                    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
                    
                   /* SELECT NVL(SUM(NUMERO_FERIE_FRUITE),0)
                    INTO v_ferie_sala
                    FROM CD_LIQUIDAZIONE_CINEMA
                    WHERE ID_CINEMA = SALE.ID_CINEMA
                    AND ID_LIQUIDAZIONE IN
                    (SELECT ID_LIQUIDAZIONE
                    FROM CD_LIQUIDAZIONE
                    WHERE to_char(DATA_INIZIO,'YYYY') = to_char(p_data_inizio,'YYYY'));
                    --
                    v_giorni_ferie := v_ferie_sala - SALE.NUM_FERIE_ESTIVE;
                    IF v_giorni_ferie > 0 THEN
                        v_giorni_decurtazione := v_giorni_decurtazione + v_giorni_ferie;
                    END IF;*/
                    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
                
                    SELECT COUNT(1)
                    INTO v_quota_sala_presente
                    FROM CD_QUOTA_TAB
                    WHERE ID_LIQUIDAZIONE = v_liquidazione
                    AND ID_SALA = SALE.ID_SALA;
                    IF v_quota_sala_presente = 0 THEN
                        INSERT INTO CD_QUOTA_TAB(ID_LIQUIDAZIONE, ID_SALA, NUM_SPETTATORI, RICAVO_TAB, NUM_GIORNI_DECUR, IMP_FATTURATO, QTA_PRE_DECURTAZIONE, IMP_DECURTAZIONE, GG_MANCATA_PROIEZIONE)
                        VALUES(v_liquidazione, SALE.ID_SALA, SALE.SPETTATORI,v_quota_sala_tab, v_giorni_decurtazione,v_fatturato_sala, v_quota_sala_ante_decurtazione, v_quota_decurtata, v_giorni_mancata_proiezione);
                    ELSE
                        UPDATE CD_QUOTA_TAB
                        SET NUM_SPETTATORI = SALE.SPETTATORI,
                        RICAVO_TAB = v_quota_sala_tab,
                        NUM_GIORNI_DECUR = v_giorni_decurtazione,
                        IMP_FATTURATO = v_fatturato_sala,
                        QTA_PRE_DECURTAZIONE = v_quota_sala_ante_decurtazione,
                        IMP_DECURTAZIONE = v_quota_decurtata,
                        GG_MANCATA_PROIEZIONE = v_giorni_mancata_proiezione
                        WHERE ID_LIQUIDAZIONE = v_liquidazione
                        AND ID_SALA = SALE.ID_SALA;
                    END IF;
            END IF;
     END LOOP;
END PR_CALCOLA_QUOTA_TAB_OLD;




-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CALCOLA_QUOTA_TAB
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Calcola per ogni sala la quota dovuta all'esercente per la trasmissione tabellare 
--
-- INPUT:
--  p_data_inizio       Data di inizio del periodo
--  p_data_fine         Data di fine del periodo
--  p_cod_esercente     Codice dell'esercente
--  p_id_gruppo         Id del gruppo esercente
--  
--
-- OUTPUT: 
--        p_esito             Esito dell'operazione
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
--  Modifiche :
--  Eliminata  Mauro Viel Altran Italia 04/10/2010  eliminata la condizione  FLG_PROGRAMMAZIONE = 'S' 
--                                                  per il conteggio dei giorni di decurtazione.
--- Inserita la gestione della colonna gg_sanatoria.

--Mauro Viel Altran Italia 21/10/2010 inserito il filtro per escludere le arene
--Mauro Viel Altran Italia 12/12/2011 inserito controllo per cui se: 
--                                    imp_decurtazione > qta_pre_decurtazione allora ricavo_tab = 0
--                                    e imp_decurtazione = qta_pre_decurtazione questa situazione  si 
--                                    puo verificare solo se la sala non programma mai nel trimeste e il 
--                                    trimestre ha piu di 90 giorni cioe uno o piu di un mese hanno piu di 
--                                    30 giorni.
--Mauro Viel Altran Italia 12/10/2011 Inserito controllo per eliminare i cinema non piu validi.(#MV01)




PROCEDURE PR_CALCOLA_QUOTA_TAB(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                p_esito OUT NUMBER) IS
v_spettatori_sala NUMBER;
v_giorni_decurtazione NUMBER := 0;
v_giorni_decurtazione_temp NUMBER;
v_giorni_sanatoria NUMBER := 0;
v_quota_sanatoria NUMBER := 0;
v_quota_sanatoria_temp NUMBER := 0;
v_quota_decurtazione_temp NUMBER := 0;
v_ricavo_spettatore CD_QUOTA_TAB.RICAVO_TAB%TYPE;
v_liquidazione CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE;  
v_fatturato_sala CD_QUOTA_TAB.RICAVO_TAB%TYPE;
v_denominatore_decurtazione NUMBER := 90;
v_quota_sala_tab CD_QUOTA_TAB.RICAVO_TAB%TYPE := 0;
v_quota_sala_tab_temp CD_QUOTA_TAB.RICAVO_TAB%TYPE := 0;
v_quota_sala_ante_decurtazione CD_QUOTA_TAB.QTA_PRE_DECURTAZIONE%TYPE;
v_quota_decurtazione CD_QUOTA_TAB.IMP_DECURTAZIONE%TYPE := 0;
v_quota_sala_presente NUMBER;
v_durata_periodo NUMBER ;
v_ricavo_giorno NUMBER;
--v_giorni_ferie NUMBER; --MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
--v_ferie_sala NUMBER;   --MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
v_giorni_mancata_proiezione NUMBER;
v_stato_lavorazione CD_QUOTA_ESERCENTE.STATO_LAVORAZIONE%TYPE;

v_imp_decurtazione NUMBER;
v_qta_pre_decurtazione NUMBER;

BEGIN
    SELECT ID_LIQUIDAZIONE, DECODE(SPETTATORI_EFF,0,0,RICAVO_NETTO / SPETTATORI_EFF), DATA_FINE - DATA_INIZIO + 1
    INTO v_liquidazione, v_ricavo_spettatore, v_durata_periodo
    FROM CD_LIQUIDAZIONE
    WHERE DATA_INIZIO = p_data_inizio
    AND DATA_FINE = p_data_fine;
    
     
    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
    --PR_CALCOLA_FERIE_CINEMA(v_liquidazione, p_data_inizio, p_data_fine, p_esito);
    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
    
    FOR SALE IN (SELECT SPETT.ID_SALA, CIN.ID_CINEMA, CC.ID_CINEMA_CONTRATTO, 
                 SUM(SPETT.NUM_SPETTATORI)  AS SPETTATORI, COND.NUM_FERIE_ESTIVE, ES.COD_ESERCENTE
                FROM --CD_LIQUIDAZIONE_SALA LS,
                     CD_SPETTATORI_EFF SPETT, CD_CINEMA CIN, CD_CONDIZIONE_CONTRATTO COND, CD_CINEMA_CONTRATTO CC,
                     CD_CONTRATTO C, CD_ESER_CONTRATTO EC, VI_CD_SOCIETA_GRUPPO GR, 
                     VI_CD_SOCIETA_ESERCENTE ES, CD_SALA S
                WHERE SPETT.DATA_RIFERIMENTO BETWEEN p_data_inizio AND p_data_fine
                AND S.ID_SALA = SPETT.ID_SALA
                AND S.FLG_ARENA = 'N'
                AND CC.FLG_RIPARTIZIONE ='S'
                AND S.ID_CINEMA = CIN.ID_CINEMA
                AND CC.ID_CINEMA = CIN.ID_CINEMA
                AND NVL(CIN.DATA_FINE_VALIDITA,SYSDATE) > = P_DATA_INIZIO -- #MV01
                AND COND.ID_CINEMA_CONTRATTO = CC.ID_CINEMA_CONTRATTO
                AND C.ID_CONTRATTO = CC.ID_CONTRATTO
                AND C.DATA_FINE >= p_data_inizio
                AND C.DATA_INIZIO <= p_data_fine
                AND EC.ID_CONTRATTO = C.ID_CONTRATTO
                AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
                AND ES.COD_ESERCENTE = EC.COD_ESERCENTE
                AND (p_cod_esercente IS NULL OR ES.COD_ESERCENTE = p_cod_esercente)
                AND GR.COD_ESERCENTE(+) = ES.COD_ESERCENTE
                AND GR.DATA_FINE_VAL >= p_data_inizio
                AND GR.DATA_INIZIO_VAL <= p_data_fine
                AND (p_id_gruppo IS NULL OR GR.ID_GRUPPO_ESERCENTE = p_id_gruppo)
                --
                GROUP BY SPETT.ID_SALA, CIN.ID_CINEMA, CC.ID_CINEMA_CONTRATTO, COND.NUM_FERIE_ESTIVE, ES.COD_ESERCENTE
                ) LOOP
                --
                BEGIN
                    SELECT STATO_LAVORAZIONE 
                    INTO v_stato_lavorazione
                    FROM CD_QUOTA_ESERCENTE
                    WHERE ID_LIQUIDAZIONE = v_liquidazione
                    AND COD_ESERCENTE = SALE.COD_ESERCENTE;
                EXCEPTION
                    WHEN OTHERS THEN
                    NULL;
                END;
    
                IF v_stato_lavorazione IS NULL OR v_stato_lavorazione = 'ANT' THEN
                    v_quota_sala_tab := 0;
                    v_giorni_decurtazione := 0;
                    v_fatturato_sala := ROUND(v_ricavo_spettatore * SALE.SPETTATORI,2);
                    v_quota_sala_ante_decurtazione := 0;
                    v_ricavo_giorno := v_fatturato_sala / v_durata_periodo;
                    v_quota_decurtazione := 0;
                    v_quota_sanatoria :=0;
                    
                 
                    --
                    SELECT COUNT(1) 
                    INTO v_giorni_mancata_proiezione
                    FROM CD_LIQUIDAZIONE_SALA
                    WHERE ID_SALA = SALE.ID_SALA
                    AND FLG_PROIEZIONE_PUBB = 'N'
                    AND DATA_RIF BETWEEN p_data_inizio AND p_data_fine;
                    
                    FOR PERC IN 
                    (SELECT DISTINCT PER.ID_PERC_RIPARTIZIONE, PER.PERC_RIPARTIZIONE, PER.DATA_INIZIO, PER.DATA_FINE, LEAST(PER.DATA_FINE, p_data_fine) - GREATEST(PER.DATA_INIZIO, p_data_inizio) + 1 AS DURATA_PERC
                    FROM  CD_PERCENTUALE_RIPARTIZIONE PER
                    WHERE PER.ID_CINEMA_CONTRATTO = SALE.ID_CINEMA_CONTRATTO
                    AND NVL(PER.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                    AND NVL(PER.DATA_INIZIO,to_date('01012000','DDMMYYYY')) <= p_data_fine
                    AND PER.COD_CATEGORIA_PRODOTTO = 'TAB'
                    ) LOOP
                        --
                        --dbms_output.put_line('Recuperata percentuale '||CURRENT_TIMESTAMP);
                        --dbms_output.PUT_LINE('Id sala: '||SALE.ID_SALA);
                        --dbms_output.PUT_LINE('Spettatori: '||SALE.SPETTATORI);
                        --dbms_output.PUT_LINE('Ricavo sala: '||v_ricavo_sala);
                        --dbms_output.PUT_LINE('Ricavo giorno: '||v_ricavo_giorno);
                        --dbms_output.PUT_LINE('Durata percentuale'||PERC.DURATA_PERC);
                        --dbms_output.PUT_LINE('Durata periodo'||v_durata_periodo);--*/
                        SELECT COUNT(DISTINCT DATA_RIF)
                        INTO v_giorni_decurtazione_temp
                        FROM CD_LIQUIDAZIONE_SALA L, CD_CODICE_RESP COD
                        WHERE L.ID_SALA = SALE.ID_SALA
                        AND L.FLG_PROIEZIONE_PUBB = 'N'
                        AND L.ID_CODICE_RESP = COD.ID_CODICE_RESP
                        AND COD.AGGREGAZIONE = 'RE'
                        --AND COD.ID_CODICE_RESP != 3 --MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
                        AND DATA_RIF BETWEEN GREATEST(PERC.DATA_INIZIO, p_data_inizio) AND LEAST(PERC.DATA_FINE, p_data_fine);
                        
                        SELECT COUNT(1)
                        INTO v_quota_sala_presente
                        FROM CD_QUOTA_TAB
                        WHERE ID_LIQUIDAZIONE = v_liquidazione
                        AND ID_SALA = SALE.ID_SALA;
                        
                        
                        IF v_quota_sala_presente = 0 THEN
                            v_giorni_sanatoria := 0;
                        ELSE
                            select gg_sanatoria  into v_giorni_sanatoria
                            from   cd_quota_tab
                            where  id_sala = sale.id_sala
                            and    id_liquidazione =  v_liquidazione;
                        END IF;
                        
                        v_quota_sala_tab_temp := ((v_ricavo_giorno * PERC.DURATA_PERC) *  (PERC.PERC_RIPARTIZIONE / 100));
                        v_quota_sala_ante_decurtazione := v_quota_sala_ante_decurtazione + v_quota_sala_tab_temp;
                        v_quota_sanatoria_temp:= v_quota_sala_tab_temp * (v_giorni_sanatoria/ v_denominatore_decurtazione);
                        v_quota_sanatoria := v_quota_sanatoria + v_quota_sanatoria_temp;
                        v_quota_decurtazione_temp:= (v_quota_sala_tab_temp * (v_giorni_decurtazione_temp / v_denominatore_decurtazione));
                        v_quota_decurtazione := v_quota_decurtazione + v_quota_decurtazione_temp;
                        v_quota_sala_tab := v_quota_sala_tab + v_quota_sala_tab_temp -  v_quota_decurtazione_temp + v_quota_sanatoria_temp ; 
                        v_giorni_decurtazione := v_giorni_decurtazione + v_giorni_decurtazione_temp;
                    END LOOP;
                    --dbms_output.PUT_LINE('Id sala: '||SALE.ID_SALA||' '||CURRENT_TIMESTAMP);
                    v_quota_sala_ante_decurtazione := ROUND(v_quota_sala_ante_decurtazione,2);
                    v_quota_sala_tab := ROUND(v_quota_sala_tab,2);
                    v_quota_decurtazione := ROUND( v_quota_decurtazione,2);
                    v_quota_sanatoria := ROUND( v_quota_sanatoria,2);
                    
                   
                    
                    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
                    
                   /* SELECT NVL(SUM(NUMERO_FERIE_FRUITE),0)
                    INTO v_ferie_sala
                    FROM CD_LIQUIDAZIONE_CINEMA
                    WHERE ID_CINEMA = SALE.ID_CINEMA
                    AND ID_LIQUIDAZIONE IN
                    (SELECT ID_LIQUIDAZIONE
                    FROM CD_LIQUIDAZIONE
                    WHERE to_char(DATA_INIZIO,'YYYY') = to_char(p_data_inizio,'YYYY'));
                    --
                    v_giorni_ferie := v_ferie_sala - SALE.NUM_FERIE_ESTIVE;
                    IF v_giorni_ferie > 0 THEN
                        v_giorni_decurtazione := v_giorni_decurtazione + v_giorni_ferie;
                    END IF;*/
                    ----MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
                
                    /*SELECT COUNT(1)
                    INTO v_quota_sala_presente
                    FROM CD_QUOTA_TAB
                    WHERE ID_LIQUIDAZIONE = v_liquidazione
                    AND ID_SALA = SALE.ID_SALA;*/
                    
                    IF v_quota_sala_presente = 0 THEN
                        INSERT INTO CD_QUOTA_TAB(ID_LIQUIDAZIONE, ID_SALA, NUM_SPETTATORI, RICAVO_TAB, NUM_GIORNI_DECUR, IMP_FATTURATO, QTA_PRE_DECURTAZIONE, IMP_DECURTAZIONE, GG_MANCATA_PROIEZIONE,IMP_SANATORIA)
                        VALUES(v_liquidazione, SALE.ID_SALA, SALE.SPETTATORI,v_quota_sala_tab, v_giorni_decurtazione,v_fatturato_sala, v_quota_sala_ante_decurtazione, v_quota_decurtazione, v_giorni_mancata_proiezione,v_quota_sanatoria);
                    ELSE
                        UPDATE CD_QUOTA_TAB
                        SET NUM_SPETTATORI = SALE.SPETTATORI,
                        RICAVO_TAB = v_quota_sala_tab,
                        NUM_GIORNI_DECUR = v_giorni_decurtazione,
                        IMP_FATTURATO = v_fatturato_sala,
                        QTA_PRE_DECURTAZIONE = v_quota_sala_ante_decurtazione,
                        IMP_DECURTAZIONE = v_quota_decurtazione,
                        GG_MANCATA_PROIEZIONE = v_giorni_mancata_proiezione,
                        IMP_SANATORIA = v_quota_sanatoria
                        WHERE ID_LIQUIDAZIONE = v_liquidazione
                        AND ID_SALA = SALE.ID_SALA;
                    END IF;
                    
                    select 
                    imp_decurtazione, 
                    qta_pre_decurtazione
                    into 
                    v_imp_decurtazione, 
                    v_qta_pre_decurtazione
                    from CD_QUOTA_TAB
                    WHERE ID_LIQUIDAZIONE = v_liquidazione
                    AND ID_SALA = SALE.ID_SALA;
                    
                    
                    --v_giorni_sanatoria
                    
                    if v_imp_decurtazione > v_qta_pre_decurtazione  then
                        UPDATE CD_QUOTA_TAB
                        SET RICAVO_TAB = 0,
                        imp_decurtazione = v_qta_pre_decurtazione
                        WHERE ID_LIQUIDAZIONE = v_liquidazione
                        AND ID_SALA = SALE.ID_SALA;
                    end if;
                    
                    
                    
            END IF;
     END LOOP;
END PR_CALCOLA_QUOTA_TAB;


-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CALCOLA_QUOTA_ESERCENTE
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Effettua il calcolo della quota dovuta ad ogni esercente per un periodo
--
-- INPUT:
--  p_data_inizio       Data di inizio del periodo
--  p_data_fine         Data di fine del periodo
--  p_cod_esercente     Codice dell'esercente
--  p_id_gruppo         Id del gruppo esercente
--  
--
-- OUTPUT: 
--        p_esito             Esito dell'operazione
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
--Modifiche Mauro Viel Altran Italia Ottobre 2010 Aggiunto il filtro per escludere le arene.
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CALCOLA_QUOTA_ESERCENTE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                     p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                     p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                     p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                     p_esito OUT NUMBER) IS
--
v_ricavo_tab CD_QUOTA_ESERCENTE.QUOTA_ESERCENTE%TYPE;
v_ricavo_isp CD_QUOTA_ESERCENTE.QUOTA_ESERCENTE%TYPE;
v_ricavo_tot CD_QUOTA_ESERCENTE.QUOTA_ESERCENTE%TYPE;
v_liquidazione CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE;
v_quota_esercente_pres NUMBER;
v_giorni_ritardo NUMBER;
--v_giorni_ferie NUMBER;
v_giorni_chiusura NUMBER;
v_stato_lavorazione CD_QUOTA_ESERCENTE.STATO_LAVORAZIONE%TYPE;
    BEGIN
    SELECT ID_LIQUIDAZIONE
    INTO v_liquidazione
    FROM CD_LIQUIDAZIONE
    WHERE DATA_INIZIO = p_data_inizio
    AND DATA_FINE = p_data_fine;
    FOR ESERC IN (SELECT DISTINCT ES.COD_ESERCENTE AS COD_ESERCENTE
                  FROM VI_CD_SOCIETA_GRUPPO GR,  VI_CD_SOCIETA_ESERCENTE ES, CD_ESER_CONTRATTO EC, CD_CONTRATTO C
                  WHERE (p_cod_esercente IS NULL OR ES.COD_ESERCENTE = p_cod_esercente)
                  AND GR.COD_ESERCENTE(+) = ES.COD_ESERCENTE
                  AND GR.DATA_FINE_VAL >= p_data_inizio
                  AND GR.DATA_INIZIO_VAL <= p_data_fine
                  AND (p_id_gruppo IS NULL OR GR.ID_GRUPPO_ESERCENTE = p_id_gruppo)
                  AND EC.COD_ESERCENTE = ES.COD_ESERCENTE
                  AND C.ID_CONTRATTO = EC.ID_CONTRATTO
                  AND NVL(ES.DATA_FINE_VALIDITA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                  AND NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) <= p_data_fine
                  AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                  AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
                  AND C.DATA_FINE >= p_data_inizio
                  AND C.DATA_INIZIO <= p_data_fine
                  AND C.FLG_ARENA ='N'
                  ) LOOP
        --dbms_output.PUT_LINE('Esercente: '||ESERC.COD_ESERCENTE);
                BEGIN
                    SELECT STATO_LAVORAZIONE 
                    INTO v_stato_lavorazione
                    FROM CD_QUOTA_ESERCENTE
                    WHERE ID_LIQUIDAZIONE = v_liquidazione
                    AND COD_ESERCENTE = ESERC.COD_ESERCENTE;
                EXCEPTION
                    WHEN OTHERS THEN
                    NULL;
                END;                
        IF v_stato_lavorazione IS NULL OR v_stato_lavorazione = 'ANT' THEN
            SELECT NVL(SUM(QS.RICAVO_TAB),0)
            INTO v_ricavo_tab
            FROM CD_QUOTA_TAB QS, CD_SALA S, CD_CINEMA CIN, 
                 CD_CINEMA_CONTRATTO CC, CD_CONTRATTO C, CD_ESER_CONTRATTO EC, 
                 VI_CD_SOCIETA_ESERCENTE ES
            WHERE ES.COD_ESERCENTE = ESERC.COD_ESERCENTE
            AND NVL(ES.DATA_FINE_VALIDITA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND EC.COD_ESERCENTE = ES.COD_ESERCENTE
            AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            AND C.DATA_FINE >= p_data_inizio
            AND C.DATA_INIZIO <= p_data_fine   
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO           
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND S.ID_CINEMA = CIN.ID_CINEMA
            AND QS.ID_SALA = S.ID_SALA
            AND QS.ID_LIQUIDAZIONE = v_liquidazione;
        
            SELECT NVL(SUM(QI.RICAVO_ISP),0)
            INTO v_ricavo_isp
            FROM CD_QUOTA_ISP QI, CD_CINEMA CIN, 
                 CD_CINEMA_CONTRATTO CC, CD_CONTRATTO C, CD_ESER_CONTRATTO EC, 
                 VI_CD_SOCIETA_ESERCENTE ES
            WHERE ES.COD_ESERCENTE = ESERC.COD_ESERCENTE
            AND NVL(ES.DATA_FINE_VALIDITA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND EC.COD_ESERCENTE = ES.COD_ESERCENTE
            AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            AND C.DATA_FINE >= p_data_inizio
            AND C.DATA_INIZIO <= p_data_fine   
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO           
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND QI.ID_CINEMA = CIN.ID_CINEMA
            AND QI.ID_LIQUIDAZIONE = v_liquidazione;
            --
            v_ricavo_tot := v_ricavo_tab + v_ricavo_isp;
            --
            SELECT count(1)
            INTO v_giorni_ritardo
            FROM CD_LIQUIDAZIONE_SALA LS, CD_SALA S, CD_CINEMA CIN, 
                 CD_CINEMA_CONTRATTO CC, CD_CONTRATTO C, CD_ESER_CONTRATTO EC, 
                 VI_CD_SOCIETA_ESERCENTE ES
            WHERE ES.COD_ESERCENTE = ESERC.COD_ESERCENTE
            and NVL(ES.DATA_FINE_VALIDITA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND EC.COD_ESERCENTE = ES.COD_ESERCENTE
            AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            AND C.DATA_FINE >= p_data_inizio
            AND C.DATA_INIZIO <= p_data_fine   
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO           
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND S.ID_CINEMA = CIN.ID_CINEMA
            AND LS.ID_SALA = S.ID_SALA
            AND LS.FLG_PROIEZIONE_PUBB = 'N'
            AND LS.ID_CODICE_RESP = 1
            AND LS.DATA_RIF BETWEEN p_data_inizio AND p_data_fine;
            --
            
            --MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
            
            /*SELECT nvl(sum(count(distinct ls.data_rif)),0)
            INTO v_giorni_ferie
            FROM CD_LIQUIDAZIONE_SALA LS, CD_SALA S, CD_CINEMA CIN, 
                 CD_CINEMA_CONTRATTO CC, CD_CONTRATTO C, CD_ESER_CONTRATTO EC, 
                 VI_CD_SOCIETA_ESERCENTE ES
            WHERE ES.COD_ESERCENTE = ESERC.COD_ESERCENTE
            AND NVL(ES.DATA_FINE_VALIDITA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND EC.COD_ESERCENTE = ES.COD_ESERCENTE
            AND NVL(EC.DATA_FINA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            AND C.DATA_FINE >= p_data_inizio
            AND C.DATA_INIZIO <= p_data_fine   
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO           
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND S.ID_CINEMA = CIN.ID_CINEMA
            AND LS.ID_SALA = S.ID_SALA
            AND LS.FLG_PROIEZIONE_PUBB = 'N'
            AND LS.ID_CODICE_RESP = 3
            AND LS.DATA_RIF BETWEEN p_data_inizio AND p_data_fine
            group by cin.id_cinema;*/
            
            --MV 31/08/2010 eliminazione  del calcolo di giorni di ferie
            --
            SELECT nvl(sum(count(distinct ls.data_rif)),0)
            INTO v_giorni_chiusura
            FROM CD_LIQUIDAZIONE_SALA LS, CD_SALA S, CD_CINEMA CIN, 
                 CD_CINEMA_CONTRATTO CC, CD_CONTRATTO C, CD_ESER_CONTRATTO EC, 
                 VI_CD_SOCIETA_ESERCENTE ES
            WHERE ES.COD_ESERCENTE = ESERC.COD_ESERCENTE
            AND NVL(ES.DATA_FINE_VALIDITA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND EC.COD_ESERCENTE = ES.COD_ESERCENTE
            AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
            AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
            AND C.ID_CONTRATTO = EC.ID_CONTRATTO
            AND C.DATA_FINE >= p_data_inizio
            AND C.DATA_INIZIO <= p_data_fine   
            AND CC.ID_CONTRATTO = C.ID_CONTRATTO           
            AND CIN.ID_CINEMA = CC.ID_CINEMA
            AND S.ID_CINEMA = CIN.ID_CINEMA
            AND LS.ID_SALA = S.ID_SALA
            AND LS.FLG_PROIEZIONE_PUBB = 'N'
            AND LS.ID_CODICE_RESP = 2
            AND LS.DATA_RIF BETWEEN p_data_inizio AND p_data_fine
            group by cin.id_cinema;
        
            --dbms_output.PUT_LINE('Ricavo esercente: '||v_ricavo_tab);
            IF v_ricavo_tot IS NOT NULL THEN
                SELECT COUNT(1)
                INTO v_quota_esercente_pres
                FROM CD_QUOTA_ESERCENTE 
                WHERE ID_LIQUIDAZIONE = v_liquidazione
                AND COD_ESERCENTE = ESERC.COD_ESERCENTE;
                --
                IF v_quota_esercente_pres = 0 THEN
                    INSERT INTO CD_QUOTA_ESERCENTE(ID_LIQUIDAZIONE, COD_ESERCENTE, QUOTA_ESERCENTE, GG_SAN_RIT_PART, GG_CHIUSURA_CONC)
                    VALUES(v_liquidazione, ESERC.COD_ESERCENTE,v_ricavo_tot, v_giorni_ritardo, v_giorni_chiusura);
                ELSE
                    UPDATE CD_QUOTA_ESERCENTE
                    SET QUOTA_ESERCENTE = v_ricavo_tot,
                    GG_SAN_RIT_PART = v_giorni_ritardo,
                    GG_CHIUSURA_CONC = v_giorni_chiusura
                    WHERE ID_LIQUIDAZIONE = v_liquidazione
                    AND COD_ESERCENTE = ESERC.COD_ESERCENTE;
                END IF;
            END IF;
        END IF;        
    END LOOP;            
END PR_CALCOLA_QUOTA_ESERCENTE;

/*************PR_GENERA_LIQUIDAZIONE_SALA************
AUTORE Mauro Viel Altran Italia Aprile 2010
Esegue l'inserimento nella tavola cd_liquidazione_sala
Parametri di input data di esecuzione
Modifica Mauro Viel Altran Italia Maggio 2010 escluse le arene
Modifica Mauro Viel Altran Italia Giugno 2010 esclusi i cinema virtuali
Modifica Mauro Viel Altran Italia Settembre 2010 eliminato l'inseriemto del campo id_codice_resp.
Modifica Mauro Viel Altran Italia Ottobre 2010 abbassata la soglia per la bonifica della proiezione 
pubblicitaria da almeno  4 (>3) ad almeno 2 (>=2) per richeista di Luigi Cipolla inquanto il vincolo 
contarttuale di almeno 2 proiuezioni (4 comunicati)  e decaduta
Modifica Mauro Viel Altran Italia 19/10/2010 eliminazione del codice responsabilita in modo da tenere sempre aggiornato il dato
Modifica Mauro Viel Altran Italia 11/04/2011 eliminata la gestione del FLG_PROIEZIONE_PUBB anche 
                                             nel caso di incongruenze per i vecchi comunicati.
Modifica Mauro Viel Altran Italia 03/05/2011 Inserito il controllo sulla validita della sala. #MV 03/05/2011
Modifica Tommaso D'Anna, Teoresi srl 13/07/2011  Rimosso flg_attivo e sostituito con data_inizio_validita                                            
*/

PROCEDURE PR_GENERA_LIQUIDAZIONE_SALA(P_DATA CD_LIQUIDAZIONE_SALA.DATA_RIF%TYPE) IS
v_data_inizio_liquidazione CD_LIQUIDAZIONE.DATA_INIZIO%TYPE;
BEGIN
insert into cd_liquidazione_sala (ID_SALA , DATA_RIF, FLG_PROGRAMMAZIONE )
(
--select PREV.id_sala, PREV.data, nvl(TRASM.FLG_PROIEZIONE_PUBB, 'N') FLG_PROIEZIONE_PUBB ,  FU_GET_CODICE_RESPONSABILITA(PREV.ID_SALA, P_DATA) ID_CODICE_RESP, flg_programmazione
/*select PREV.id_sala, PREV.data, nvl(TRASM.FLG_PROIEZIONE_PUBB, 'N') FLG_PROIEZIONE_PUBB ,   flg_programmazione
from
 (select id_sala, DATA, decode(num_spot,0,'N', 1, 'N', 2, 'N', 3, 'N', 'S') FLG_PROIEZIONE_PUBB
   from
   (select CO.id_sala, co.data_erogazione_prev DATA, count(*) num_spot, min(ADV.data_erogazione_eff) DA, max(ADV.data_erogazione_eff) A
    from
      cd_adv_comunicato ADV,
      cd_comunicato CO
    where trunc(ADV.data_erogazione_eff) between P_DATA and P_DATA                     -- !!! FILTRO GIORNO !!! --
      and ADV.id_comunicato = CO.id_comunicato
      and co.flg_annullato = 'N'
      and co.flg_sospeso = 'N'
      and ( ADV.HH_eff < 6 or ADV.HH_eff > 13)
    group by CO.id_sala, CO.data_erogazione_prev
   )
  ) TRASM,*/
 (select anag.id_sala, anag.data, nvl(prog.flg_programmazione, 'N') flg_programmazione
  from
   (select distinct co.id_sala, co.data_erogazione_prev DATA, 'S' flg_programmazione
    from cd_comunicato CO
    where CO.data_erogazione_prev between P_DATA and P_DATA                   -- !!! FILTRO GIORNO !!! --
     and COD_DISATTIVAZIONE is null
     and FLG_ANNULLATO = 'N'
     and FLG_SOSPESO = 'N'
   ) prog,
   (select id_sala, data
    from
     (
      select id_sala
      from cd_sala sa,cd_cinema ci
      where sa.id_cinema = ci.id_cinema
      and ci.flg_virtuale ='N'
      --and ci.flg_attivo = 'S'
      AND    CI.DATA_INIZIO_VALIDITA  <= trunc(P_DATA)
      AND    nvl(CI.DATA_FINE_VALIDITA, trunc(P_DATA)) >= trunc(P_DATA)      
      and sa.flg_arena = 'N'
      and nvl(sa.data_fine_validita, trunc(sysdate)) >= p_data --#MV 03/05/2011
     ) sala,
     (select distinct co.data_erogazione_prev DATA
      from cd_comunicato CO
      where CO.data_erogazione_prev between P_DATA and P_DATA                    -- !!! FILTRO GIORNO !!! --
     ) dt
   ) anag
  where prog.id_sala(+) = anag.id_sala
    and prog.DATA(+) = anag.DATA
 ) --PREV
--where TRASM.id_sala(+) = PREV.id_sala
 -- and TRASM.DATA(+) = PREV.DATA
);
--
/*--Verifico se ci sono incongruenze nei vecchi comunicati trasmessi
SELECT MAX(DATA_FINE) + 1
INTO v_data_inizio_liquidazione
FROM CD_LIQUIDAZIONE
WHERE STATO_LAVORAZIONE != 'ANT';
--
for c in (
select data_rif, id_sala  from cd_liquidazione_sala l--, cd_codice_resp cod
where data_rif BETWEEN v_data_inizio_liquidazione AND P_DATA
and flg_proiezione_pubb = 'N'
--and l.ID_CODICE_RESP = cod.ID_CODICE_RESP
--and cod.AGGREGAZIONE = 'RE' --MV 19/10/2010 eliminazione del codice responsabilita in modo da tenere sempre aggiornato il dato
and exists (select c.id_sala, c.DATA_EROGAZIONE_PREV, count(1)
from cd_adv_comunicato ac, cd_comunicato c
where c.ID_COMUNICATO = ac.ID_COMUNICATO
and c.DATA_EROGAZIONE_PREV BETWEEN v_data_inizio_liquidazione AND P_DATA
and c.DATA_EROGAZIONE_PREV = l.data_rif
and  c.ID_SALA = l.id_sala
group by c.DATA_EROGAZIONE_PREV, c.ID_SALA
having count(1) >= 2
)
) loop
    update cd_liquidazione_sala
    set flg_proiezione_pubb = 'S'
    where ID_SALA = c.ID_SALA
    and data_rif = c.data_rif;
end loop;*/
--
commit;
END PR_GENERA_LIQUIDAZIONE_SALA;

FUNCTION FU_LIQUIDAZIONE(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                         p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE) RETURN C_LIQUIDAZIONE IS
--
v_liquidazione C_LIQUIDAZIONE;
BEGIN
OPEN v_liquidazione FOR
    SELECT LIQ.ID_LIQUIDAZIONE, LIQ.RICAVO_NETTO, LIQ.SPETTATORI_EFF, ROUND(DECODE(LIQ.SPETTATORI_EFF,0,0,LIQ.RICAVO_NETTO / LIQ.SPETTATORI_EFF),5) AS FATT_SPETT,
    DECODE(LIQ.STATO_LAVORAZIONE,'ANT','Anteprima','DAL','Da liquidare','LIQ','Liquidato') AS STATO_LAVORAZIONE
    FROM CD_LIQUIDAZIONE LIQ
    WHERE DATA_INIZIO = TRUNC(p_data_inizio)
    AND DATA_FINE = TRUNC(p_data_fine);
RETURN v_liquidazione;
END FU_LIQUIDAZIONE;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETT_QUOTA_ESERCENTE_TAB
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente        codice esercente
--  p_data_inizio          data inizio liquidazione
--  p_data_fine            data fine liquidazione
-- OUTPUT: Restituisce le quote per ogni sala dell'esercente per una liquidazione
--
-- REALIZZATORE  Michele Borgogno, Altran, Aprile 2010
-- Modifiche: Mauro Viel, Altran, 19/04/2010 rinominata la funzione inserendo il suffisso "_TAB" la procedura si occupera del conteggio 
--della sola quota tabellare.
--            Mauro Viel Altran Italia Ottobre 2011 inserita la colonna nome_sala fra i criteri di ordinamento #MV01
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETT_QUOTA_ESERCENTE_TAB(P_COD_ESERCENTE     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            P_DATA_INIZIO       CD_LIQUIDAZIONE.DATA_INIZIO%TYPE,
                            P_DATA_FINE         CD_LIQUIDAZIONE.DATA_FINE%TYPE) RETURN C_DETT_QUOTA_ESERCENTE_TAB IS
c_quota_eserc C_DETT_QUOTA_ESERCENTE_TAB;

BEGIN
    OPEN c_quota_eserc 
    FOR
        SELECT SA.ID_SALA, SA.NOME_SALA, PA_CD_CINEMA.FU_GET_NOME_CINEMA(CI.ID_CINEMA, P_DATA_FINE) AS NOME_CINEMA, CO.COMUNE, QT.NUM_SPETTATORI, 
              QT.RICAVO_TAB, QT.NUM_GIORNI_DECUR, PR.PERC_RIPARTIZIONE,
              QT.IMP_FATTURATO, QT.QTA_PRE_DECURTAZIONE, QT.IMP_DECURTAZIONE, QT.GG_MANCATA_PROIEZIONE, QT.GG_SANATORIA,LI.ID_LIQUIDAZIONE,QT.IMP_SANATORIA
        FROM CD_LIQUIDAZIONE LI, VI_CD_SOCIETA_ESERCENTE ES, CD_ESER_CONTRATTO EC, 
             CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC,CD_COMUNE CO, CD_CINEMA CI, 
             CD_SALA SA,CD_QUOTA_TAB QT, CD_PERCENTUALE_RIPARTIZIONE PR
        WHERE LI.DATA_INIZIO = TRUNC(p_data_inizio)
        AND   LI.DATA_FINE = TRUNC(p_data_fine)
        AND   ES.COD_ESERCENTE = p_cod_esercente
        AND   ES.COD_ESERCENTE = EC.COD_ESERCENTE
        AND   C.ID_CONTRATTO = EC.ID_CONTRATTO
        AND   CC.ID_CONTRATTO = C.ID_CONTRATTO
        AND   CI.ID_CINEMA = CC.ID_CINEMA
        AND   SA.ID_CINEMA = CI.ID_CINEMA
        AND   CO.ID_COMUNE = CI.ID_COMUNE
        AND   QT.ID_SALA = SA.ID_SALA
        AND   QT.ID_LIQUIDAZIONE = LI.ID_LIQUIDAZIONE
        AND   PR.ID_CINEMA_CONTRATTO = CC.ID_CINEMA_CONTRATTO
        AND   PR.COD_CATEGORIA_PRODOTTO = 'TAB'
        AND NVL(ES.DATA_FINE_VALIDITA,TO_DATE('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(ES.DATA_INIZIO_VALIDITA,TO_DATE('01011900','DDMMYYYY')) <= p_data_fine
        AND NVL(EC.DATA_FINE,TO_DATE('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(EC.DATA_INIZIO,TO_DATE('01011900','DDMMYYYY')) <= p_data_fine
        ORDER BY CO.COMUNE, CI.NOME_CINEMA,SA.NOME_SALA;--#MV01
    RETURN c_quota_eserc;
    END FU_DETT_QUOTA_ESERCENTE_TAB;
    
    
    
    
    -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETT_QUOTA_ESERCENTE_ISP
-- --------------------------------------------------------------------------------------------
-- INPUT:
--  p_cod_esercente        codice esercente
--  p_data_inizio          data inizio liquidazione
--  p_data_fine            data fine liquidazione
-- OUTPUT: Restituisce le quote per ogni sala dell'esercente per una liquidazione
--
-- REALIZZATORE  Mauro Viel, Altran, Aprile 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETT_QUOTA_ESERCENTE_ISP(P_COD_ESERCENTE     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                            P_DATA_INIZIO       CD_LIQUIDAZIONE.DATA_INIZIO%TYPE,
                            P_DATA_FINE         CD_LIQUIDAZIONE.DATA_FINE%TYPE) RETURN C_DETT_QUOTA_ESERCENTE_ISP IS
c_quota_eserc C_DETT_QUOTA_ESERCENTE_ISP;

BEGIN
    OPEN c_quota_eserc 
    FOR
        SELECT CI.ID_CINEMA, PA_CD_CINEMA.FU_GET_NOME_CINEMA(CI.ID_CINEMA, P_DATA_FINE) AS NOME_CINEMA, CO.COMUNE,QT.RICAVO_ISP, PR.PERC_RIPARTIZIONE, QT.IMP_FATTURATO
        FROM CD_LIQUIDAZIONE LI, VI_CD_SOCIETA_ESERCENTE ES, CD_ESER_CONTRATTO EC, 
             CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC,CD_COMUNE CO, CD_CINEMA CI,
             CD_QUOTA_ISP QT, CD_PERCENTUALE_RIPARTIZIONE PR
        WHERE LI.DATA_INIZIO = TRUNC(p_data_inizio)
        AND   LI.DATA_FINE = TRUNC(p_data_fine)
        AND   ES.COD_ESERCENTE = p_cod_esercente
        AND   ES.COD_ESERCENTE = EC.COD_ESERCENTE
        AND   C.ID_CONTRATTO = EC.ID_CONTRATTO
        AND   CC.ID_CONTRATTO = C.ID_CONTRATTO
        AND   CI.ID_CINEMA = CC.ID_CINEMA
        AND   CO.ID_COMUNE = CI.ID_COMUNE
        AND   QT.ID_CINEMA = CI.ID_CINEMA
        AND   QT.ID_LIQUIDAZIONE = LI.ID_LIQUIDAZIONE
        AND   PR.ID_CINEMA_CONTRATTO = CC.ID_CINEMA_CONTRATTO
        AND   PR.COD_CATEGORIA_PRODOTTO = 'ISP'
        AND NVL(ES.DATA_FINE_VALIDITA,TO_DATE('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(ES.DATA_INIZIO_VALIDITA,TO_DATE('01011900','DDMMYYYY')) <= p_data_fine
        AND NVL(EC.DATA_FINE,TO_DATE('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(EC.DATA_INIZIO,TO_DATE('01011900','DDMMYYYY')) <= p_data_fine
        ORDER BY CO.COMUNE, CI.NOME_CINEMA;
    RETURN c_quota_eserc;
    END FU_DETT_QUOTA_ESERCENTE_ISP;
    
   FUNCTION FU_GET_CODICE_RESPONSABILITA(P_ID_SALA CD_SALA.ID_SALA%TYPE, P_DATA_RIF CD_LIQUIDAZIONE_SALA.DATA_RIF%TYPE) RETURN CD_CODICE_RESP.ID_CODICE_RESP%TYPE IS
   V_ID_CODICE_RESP CD_CODICE_RESP.ID_CODICE_RESP%TYPE := 5;
   V_GIORNO_CHIUSURA CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE;
   V_GIORNO_RIF CD_CONDIZIONE_CONTRATTO.GIORNO_CHIUSURA%TYPE;
   BEGIN 
        select giorno_chiusura
        INTO v_giorno_chiusura
        from cd_sala sa,cd_cinema ci,cd_cinema_contratto ci_con,cd_condizione_contratto cond_co
        where  sa.ID_SALA = P_ID_SALA
        and   sa.ID_CINEMA = ci.ID_CINEMA
        and   ci_con.ID_CINEMA = ci.ID_CINEMA
        and   cond_co.ID_CINEMA_CONTRATTO = ci_con.ID_CINEMA_CONTRATTO;
        --
        select TO_CHAR(p_data_rif,'D') 
        INTO v_giorno_rif
        from dual;
        -- 
        IF v_giorno_chiusura =  v_giorno_rif THEN
            select   decode(v_giorno_chiusura,1,4,2,4,3,4,5,4,6,4,7,4,5)
            INTO V_ID_CODICE_RESP
            from dual;
        END IF;
        RETURN V_ID_CODICE_RESP;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
       RETURN V_ID_CODICE_RESP;     
   END FU_GET_CODICE_RESPONSABILITA;

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_CALCOLA_QUOTA_ISP
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Effettua il calcolo della quota dovuta per le inziative speciali, divise per cinema
--
-- INPUT:
--  p_data_inizio       Data di inizio del periodo
--  p_data_fine         Data di fine del periodo
--  p_cod_esercente     Codice dell'esercente
--  p_id_gruppo         Id del gruppo esercente
--  
--
-- OUTPUT: 
--        p_esito             Esito dell'operazione
--
-- REALIZZATORE  Simone Bottani, Altran, Marzo 2010
-- MODIFICHE     --Mauro Viel Altran Italia 12/10/2011 Inserito controllo per eliminare i cinema non piu validi.(#MV01)
--               --Mauro Viel Altran Italia 17/11/2011 sostituita variabile v_cinema con CINEMA.ID_CINEMA. 
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CALCOLA_QUOTA_ISP(p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE,
                                p_id_gruppo VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                p_esito OUT NUMBER) IS
--
v_liquidazione CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE;
--v_cinema CD_CINEMA.ID_CINEMA%TYPE;
v_quota_isp CD_QUOTA_ISP.RICAVO_ISP%TYPE := 0;
v_num_quote_isp NUMBER;
perc_ripartizione CD_PERCENTUALE_RIPARTIZIONE.PERC_RIPARTIZIONE%TYPE;
v_stato_lavorazione CD_QUOTA_ESERCENTE.STATO_LAVORAZIONE%TYPE;
    BEGIN
    SELECT ID_LIQUIDAZIONE
    INTO v_liquidazione
    FROM CD_LIQUIDAZIONE
    WHERE DATA_INIZIO = p_data_inizio
    AND DATA_FINE = p_data_fine;
    --
    FOR CINEMA IN (SELECT CIN.ID_CINEMA,CC.ID_CINEMA_CONTRATTO, ES.COD_ESERCENTE,
                   SUM(((IMPF.IMPORTO_NETTO - (IMPF.IMPORTO_NETTO * IMPF.PERC_SCONTO_SOST_AGE / 100)) / PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(PA.ID_PRODOTTO_ACQUISTATO))) AS NETTO
                    FROM 
                     CD_CINEMA_CONTRATTO CC,
                     CD_CONTRATTO C, CD_ESER_CONTRATTO EC, VI_CD_SOCIETA_GRUPPO GR,
                     VI_CD_SOCIETA_ESERCENTE ES, 
                     CD_CINEMA CIN, 
                     CD_PIANIFICAZIONE PIA,
                     CD_PRODOTTO_ACQUISTATO PA, CD_IMPORTI_PRODOTTO IMPP, 
                     CD_IMPORTI_FATTURAZIONE IMPF,
                     (
                     SELECT DISTINCT A.ID_CINEMA, C.ID_PRODOTTO_ACQUISTATO
                     FROM CD_ATRIO A, CD_COMUNICATO C, CD_ATRIO_VENDITA AV, CD_CIRCUITO_ATRIO CA
                     WHERE C.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
                     AND C.FLG_ANNULLATO = 'N'
                     AND C.FLG_SOSPESO = 'N'
                     AND C.COD_DISATTIVAZIONE IS NULL
                     AND AV.ID_ATRIO_VENDITA = C.ID_ATRIO_VENDITA
                     AND AV.FLG_ANNULLATO = 'N'
                     AND CA.ID_CIRCUITO_ATRIO = AV.ID_CIRCUITO_ATRIO
                     AND CA.FLG_ANNULLATO = 'N'
                     AND A.ID_ATRIO = CA.ID_ATRIO
                     AND A.FLG_ANNULLATO = 'N'
                     UNION
                     SELECT DISTINCT S.ID_CINEMA, C.ID_PRODOTTO_ACQUISTATO
                     FROM CD_SALA S, CD_COMUNICATO C, CD_SALA_VENDITA AV, CD_CIRCUITO_SALA CA
                     WHERE C.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
                     AND C.FLG_ANNULLATO = 'N'
                     AND C.FLG_SOSPESO = 'N'
                     AND C.COD_DISATTIVAZIONE IS NULL
                     AND AV.ID_SALA_VENDITA = C.ID_SALA_VENDITA
                     AND AV.FLG_ANNULLATO = 'N'
                     AND CA.ID_CIRCUITO_SALA = AV.ID_CIRCUITO_SALA
                     AND CA.FLG_ANNULLATO = 'N'
                     AND S.ID_SALA = CA.ID_SALA
                     AND S.FLG_ANNULLATO = 'N'
                     UNION
                     SELECT DISTINCT CIN.ID_CINEMA, C.ID_PRODOTTO_ACQUISTATO
                     FROM CD_CINEMA CIN, CD_COMUNICATO C, CD_CINEMA_VENDITA AV, CD_CIRCUITO_CINEMA CA
                     WHERE C.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
                     AND C.FLG_ANNULLATO = 'N'
                     AND C.FLG_SOSPESO = 'N'
                     AND C.COD_DISATTIVAZIONE IS NULL
                     AND AV.ID_CINEMA_VENDITA = C.ID_CINEMA_VENDITA
                     AND AV.FLG_ANNULLATO = 'N'
                     AND CA.ID_CIRCUITO_CINEMA = AV.ID_CIRCUITO_CINEMA
                     AND CA.FLG_ANNULLATO = 'N'
                     AND CIN.ID_CINEMA = CA.ID_CINEMA
                     AND CIN.FLG_ANNULLATO = 'N'
                     ) ISP
                     WHERE IMPF.DATA_INIZIO >= p_data_inizio
                     AND IMPF.DATA_FINE <= p_data_fine
                     AND IMPF.IMPORTO_NETTO > 0
                     AND IMPF.STATO_FATTURAZIONE IN ('DAR','TRA')
                     AND IMPF.FLG_ANNULLATO = 'N'
                     AND IMPP.ID_IMPORTI_PRODOTTO = IMPF.ID_IMPORTI_PRODOTTO
                     AND PA.ID_PRODOTTO_ACQUISTATO = IMPP.ID_PRODOTTO_ACQUISTATO
                     AND PA.FLG_ANNULLATO = 'N'
                     AND PA.FLG_SOSPESO = 'N'
                     AND PA.COD_DISATTIVAZIONE IS NULL
                     AND PIA.ID_PIANO = PA.ID_PIANO
                     AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
                     AND PIA.COD_CATEGORIA_PRODOTTO = 'ISP'
                     AND PIA.FLG_ANNULLATO = 'N'
                     AND PIA.FLG_SOSPESO = 'N'
                     AND ISP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                     AND CIN.ID_CINEMA = ISP.ID_CINEMA
                     AND NVL(CIN.DATA_FINE_VALIDITA,SYSDATE) > = P_DATA_INIZIO -- #MV01
                     AND CC.ID_CINEMA = CIN.ID_CINEMA
                     AND C.ID_CONTRATTO = CC.ID_CONTRATTO
                     AND CC.FLG_RIPARTIZIONE ='S'
                     AND C.DATA_FINE >= p_data_inizio
                     AND C.DATA_INIZIO <= p_data_fine
                     AND EC.ID_CONTRATTO = C.ID_CONTRATTO
                     AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                     AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
                     AND ES.COD_ESERCENTE = EC.COD_ESERCENTE
                     AND (p_cod_esercente IS NULL OR ES.COD_ESERCENTE = p_cod_esercente)
                     AND GR.COD_ESERCENTE(+) = ES.COD_ESERCENTE
                     AND GR.DATA_FINE_VAL >= p_data_inizio
                     AND GR.DATA_INIZIO_VAL <= p_data_fine
                     AND (p_id_gruppo IS NULL OR GR.ID_GRUPPO_ESERCENTE = p_id_gruppo)
                     GROUP BY CIN.ID_CINEMA, ES.COD_ESERCENTE, CC.ID_CINEMA_CONTRATTO
                     ) LOOP
                     --
                     BEGIN
                        SELECT STATO_LAVORAZIONE 
                        INTO v_stato_lavorazione
                        FROM CD_QUOTA_ESERCENTE
                        WHERE ID_LIQUIDAZIONE = v_liquidazione
                        AND COD_ESERCENTE = CINEMA.COD_ESERCENTE;
                     EXCEPTION
                        WHEN OTHERS THEN
                        NULL;
                     END;
                     IF v_stato_lavorazione IS NULL OR v_stato_lavorazione = 'ANT' THEN    
                        SELECT DISTINCT PER.PERC_RIPARTIZIONE
                        INTO perc_ripartizione
                        FROM  CD_PERCENTUALE_RIPARTIZIONE PER
                        WHERE PER.ID_CINEMA_CONTRATTO = CINEMA.ID_CINEMA_CONTRATTO
                        AND NVL(PER.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
                        AND NVL(PER.DATA_INIZIO,to_date('01012000','DDMMYYYY')) <= p_data_fine
                        AND PER.COD_CATEGORIA_PRODOTTO = 'ISP';
                        --
                        --dbms_output.PUT_LINE('Cinema:'||CINEMA.ID_CINEMA);
                        --dbms_output.PUT_LINE('Netto:'||CINEMA.NETTO);
                        --dbms_output.PUT_LINE('Perc ripartizione: '||perc_ripartizione);
                        v_quota_isp := CINEMA.NETTO * perc_ripartizione / 100;
                        SELECT COUNT(1) 
                        INTO v_num_quote_isp
                        FROM CD_QUOTA_ISP
                        WHERE ID_LIQUIDAZIONE = v_liquidazione
                        AND ID_CINEMA = CINEMA.ID_CINEMA;
                        --
                        IF v_num_quote_isp = 0 THEN
                            INSERT INTO CD_QUOTA_ISP(ID_LIQUIDAZIONE, ID_CINEMA, RICAVO_ISP, IMP_FATTURATO)
                            VALUES(v_liquidazione, CINEMA.ID_CINEMA, ROUND(v_quota_isp,2), CINEMA.NETTO);
                        ELSE
                            UPDATE CD_QUOTA_ISP
                            SET RICAVO_ISP = ROUND(v_quota_isp,2),
                            IMP_FATTURATO = CINEMA.NETTO
                            WHERE ID_LIQUIDAZIONE = v_liquidazione
                            AND ID_CINEMA = CINEMA.ID_CINEMA;
                        END IF;
                    END IF;    
    END LOOP;
END PR_CALCOLA_QUOTA_ISP;     

-- --------------------------------------------------------------------------------------------
-- Procedura PR_CALCOLA_FERIE_CINEMA
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: calcola le ferie godute da ogni cinema per un trimestre di liquidazione
-- INPUT:
--  p_liquidazione         Id della liquidazione
--  p_data_inizio          data inizio liquidazione
--  p_data_fine            data fine liquidazione
-- OUTPUT: 
--
-- REALIZZATORE  Simone Bottani, Altran, Aprile 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_CALCOLA_FERIE_CINEMA(p_liquidazione CD_LIQUIDAZIONE.ID_LIQUIDAZIONE%TYPE,
                                p_data_inizio CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                p_esito OUT NUMBER) IS
--
v_giorni_ferie NUMBER;
v_cinema_liquidazione NUMBER;
    BEGIN
       FOR FERIE IN (SELECT DISTINCT S.ID_CINEMA FROM CD_SALA S, CD_LIQUIDAZIONE_SALA LS
                WHERE LS.DATA_RIF BETWEEN p_data_inizio AND p_data_fine
                AND LS.FLG_PROIEZIONE_PUBB = 'N'
                AND LS.ID_CODICE_RESP = 3
                AND S.ID_SALA = LS.ID_SALA) LOOP
        SELECT nvl(sum(count(distinct ls.data_rif)),0)
        INTO v_giorni_ferie
        FROM CD_LIQUIDAZIONE_SALA LS, CD_SALA S, CD_CINEMA CIN, 
             CD_CINEMA_CONTRATTO CC, CD_CONTRATTO C, CD_ESER_CONTRATTO EC, 
             VI_CD_SOCIETA_ESERCENTE ES
        WHERE NVL(ES.DATA_FINE_VALIDITA,to_date('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(ES.DATA_INIZIO_VALIDITA,to_date('01011900','DDMMYYYY')) <= p_data_fine
        AND EC.COD_ESERCENTE = ES.COD_ESERCENTE
        AND NVL(EC.DATA_FINE,to_date('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(EC.DATA_INIZIO,to_date('01011900','DDMMYYYY')) <= p_data_fine
        AND C.ID_CONTRATTO = EC.ID_CONTRATTO
        AND C.DATA_FINE >= p_data_inizio
        AND C.DATA_INIZIO <= p_data_fine   
        AND CC.ID_CONTRATTO = C.ID_CONTRATTO           
        AND CIN.ID_CINEMA = CC.ID_CINEMA
        AND CIN.ID_CINEMA = FERIE.ID_CINEMA
        AND S.ID_CINEMA = CIN.ID_CINEMA
        AND LS.ID_SALA = S.ID_SALA
        AND LS.FLG_PROIEZIONE_PUBB = 'N'
        AND LS.ID_CODICE_RESP = 3
        group by CIN.id_cinema;
        --
        SELECT COUNT(1)
        INTO v_cinema_liquidazione
        FROM CD_LIQUIDAZIONE_CINEMA
        WHERE ID_CINEMA = FERIE.ID_CINEMA
        AND ID_LIQUIDAZIONE = p_liquidazione;
        --
        IF v_cinema_liquidazione = 0 THEN
            INSERT INTO CD_LIQUIDAZIONE_CINEMA(ID_LIQUIDAZIONE, ID_CINEMA, NUMERO_FERIE_FRUITE)
            VALUES(p_liquidazione, FERIE.ID_CINEMA,v_giorni_ferie);
        ELSE 
            UPDATE CD_LIQUIDAZIONE_CINEMA  
            SET NUMERO_FERIE_FRUITE = v_giorni_ferie
            WHERE ID_LIQUIDAZIONE = p_liquidazione
            AND ID_CINEMA = FERIE.ID_CINEMA;
        END IF;
    END LOOP;
END PR_CALCOLA_FERIE_CINEMA;    

-- --------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_CINEMA_CONTRATTO
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE: Elimina l'associazione tra un cinema e un contratto
-- INPUT:
--  p_id_cinema_contratto         Id del cinema contratto
-- OUTPUT: 
-- p_esito 1 se l'eliminazione e avvenuta correttamente, -1 in caso contrario
-- REALIZZATORE  Simone Bottani, Altran, Maggio 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_CINEMA_CONTRATTO(p_id_cinema_contratto CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO%TYPE,
                                      p_esito OUT NUMBER) IS

    BEGIN
    p_esito := 1;
    DELETE FROM CD_PERCENTUALE_RIPARTIZIONE
    WHERE ID_CINEMA_CONTRATTO = p_id_cinema_contratto;
    --
    DELETE FROM CD_CONDIZIONE_CONTRATTO
    WHERE ID_CINEMA_CONTRATTO = p_id_cinema_contratto;
    --
    DELETE FROM CD_CINEMA_CONTRATTO
    WHERE ID_CINEMA_CONTRATTO = p_id_cinema_contratto;
    EXCEPTION
    WHEN OTHERS THEN
       p_esito := -1;
END PR_ELIMINA_CINEMA_CONTRATTO;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DISPONIBILITA_FERIE
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id della proiezione dove verificare disponibilita
-- OUTPUT: Restituisce l'esito del controllo sulla disponibilita delle ferie
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Settembre 2010
--
-- MODIFICHE     
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DISPONIBILITA_FERIE(P_ID_PROIEZIONE     CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                P_ID_CODICE_RESP    cd_codice_resp.ID_CODICE_RESP%TYPE)
                            RETURN NUMBER
IS
    V_DISPONIBILITA     NUMBER:=100;
    V_NUM_FERIE         NUMBER:=0;
    V_NUM_FERIE_GODUTE  NUMBER:=0;
BEGIN
    /*22 E IL CODICE RESP CHE RIPORTA LA DICITURA FERIE CONTRATTUALIZZATE*/
    IF(P_ID_CODICE_RESP = 22)THEN
        SELECT CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE 
               INTO V_NUM_FERIE
        FROM   CD_CONDIZIONE_CONTRATTO,
               CD_CINEMA_CONTRATTO,
               CD_CONTRATTO,
               CD_CINEMA,CD_SALA,CD_SCHERMO,CD_PROIEZIONE
        WHERE  CD_CONDIZIONE_CONTRATTO.ID_CINEMA_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO
        AND    CD_CINEMA_CONTRATTO.ID_CONTRATTO = CD_CONTRATTO.ID_CONTRATTO
        AND    SYSDATE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE
        AND    CD_PROIEZIONE.ID_PROIEZIONE = P_ID_PROIEZIONE
        AND    CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
        AND    CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
        AND    CD_CINEMA.ID_CINEMA = CD_SALA.ID_CINEMA
        AND    CD_CINEMA.ID_CINEMA = CD_CINEMA_CONTRATTO.ID_CINEMA
        AND    (CD_CONTRATTO.DATA_RISOLUZIONE IS NULL OR SYSDATE < CD_CONTRATTO.DATA_RISOLUZIONE);    
    
        SELECT MAX(NUM_FERIE)INTO V_NUM_FERIE_GODUTE
        FROM
        ( 
        SELECT COUNT(ID_CODICE_RESP) OVER (PARTITION BY ID_sala) NUM_FERIE
                FROM CD_SALA_INDISP 
                /*22 E IL CODICE RESP CHE RIPORTA LA DICITURA FERIE CONTRATTUALIZZATE*/
                WHERE ID_CODICE_RESP = 22
                AND ID_SALA = (
                    SELECT ID_SALA 
                    FROM CD_PROIEZIONE,CD_SCHERMO 
                    WHERE ID_PROIEZIONE = P_ID_PROIEZIONE
                    AND CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO)
                AND DATA_RIF BETWEEN TRUNC(SYSDATE, 'YEAR') AND TRUNC(SYSDATE, 'YEAR')+364
        UNION 
        SELECT 0 NUM_FERIE FROM DUAL
        );
    
        V_DISPONIBILITA:=V_NUM_FERIE-V_NUM_FERIE_GODUTE;
    END IF;
    
    RETURN V_DISPONIBILITA;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'FU_DISPONIBILITA_FERIE: si e'' verificato un errore inatteso '||SQLERRM);
        return 0;
END FU_DISPONIBILITA_FERIE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DISP_FERIE_CONSUNTIVO
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id della proiezione dove verificare disponibilita
-- OUTPUT: Restituisce l'esito del controllo sulla disponibilita delle ferie
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Settembre 2010
--
-- MODIFICHE     
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DISP_FERIE_CONSUNTIVO(  P_ID_sala           CD_sala.id_sala%TYPE,
                                    P_ID_CODICE_RESP    cd_codice_resp.ID_CODICE_RESP%TYPE)
                                  RETURN NUMBER
IS
    V_DISPONIBILITA     NUMBER:=100;
    V_NUM_FERIE         NUMBER:=0;
    V_NUM_FERIE_GODUTE  NUMBER:=0;
BEGIN
    /*22 E IL CODICE RESP CHE RIPORTA LA DICITURA FERIE CONTRATTUALIZZATE*/
    IF(P_ID_CODICE_RESP = 22)THEN
        SELECT CD_CONDIZIONE_CONTRATTO.NUM_FERIE_ESTIVE 
               INTO V_NUM_FERIE
        FROM   CD_CONDIZIONE_CONTRATTO,
               CD_CINEMA_CONTRATTO,
               CD_CONTRATTO,
               CD_CINEMA,CD_SALA
        WHERE  CD_CONDIZIONE_CONTRATTO.ID_CINEMA_CONTRATTO = CD_CINEMA_CONTRATTO.ID_CINEMA_CONTRATTO
        AND    CD_CINEMA_CONTRATTO.ID_CONTRATTO = CD_CONTRATTO.ID_CONTRATTO
        AND    SYSDATE BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE
        AND    CD_SALA.ID_SALA = p_ID_SALA
        AND    CD_CINEMA.ID_CINEMA = CD_SALA.ID_CINEMA
        AND    CD_CINEMA.ID_CINEMA = CD_CINEMA_CONTRATTO.ID_CINEMA
        AND    (CD_CONTRATTO.DATA_RISOLUZIONE IS NULL OR SYSDATE < CD_CONTRATTO.DATA_RISOLUZIONE);    
    
        SELECT MAX(NUM_FERIE)INTO V_NUM_FERIE_GODUTE
        FROM
        ( 
        SELECT COUNT(ID_CODICE_RESP) OVER (PARTITION BY ID_sala) NUM_FERIE
                FROM CD_LIQUIDAZIONE_SALA
                /*22 E IL CODICE RESP CHE RIPORTA LA DICITURA FERIE CONTRATTUALIZZATE*/
                WHERE ID_CODICE_RESP = 22
                AND ID_SALA = p_id_sala
                AND DATA_RIF BETWEEN TRUNC(SYSDATE, 'YEAR') AND TRUNC(SYSDATE, 'YEAR')+364
        UNION 
        SELECT 0 NUM_FERIE FROM DUAL
        );
    
        V_DISPONIBILITA:=V_NUM_FERIE-V_NUM_FERIE_GODUTE;
    END IF;
    
    RETURN V_DISPONIBILITA;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'FU_DISP_FERIE_CONSUNTIVO: si e'' verificato un errore inatteso '||SQLERRM);
        return 0;
END FU_DISP_FERIE_CONSUNTIVO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_IMPOSTA_GIORNO_CHIUSURA
--
-- DESCRIZIONE:  Esegue l'impostazione del giorno di chiusura per una specifica proiezione
--               Se il codice della causale impostata e di FERIE, prima di eseguire l'aggiornamento
--               viene eseguito un controllo sull'effettiva disponibilita di giorni della sala
--
-- OPERAZIONI:
-- INPUT:  Id della proiezione
--         id codice della causale da impostare
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Operazione non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Settembre 2010
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------                        
PROCEDURE PR_IMPOSTA_GIORNO_CHIUSURA(P_ID_PROIEZIONE    CD_PROIEZIONE.ID_PROIEZIONE%TYPE,
                                     P_ID_CODICE_RESP   cd_codice_resp.ID_CODICE_RESP%TYPE,
                                     P_ESITO OUT NUMBER)
IS
V_DISPONIBILITA     NUMBER:=100;
v_num_rec           number:=0;
v_id_sala           number:=0;
v_data_rif          date;
--
BEGIN -- PR_IMPOSTA_GIORNO_CHIUSURA
--
--
    P_ESITO     := 1;
--
    SAVEPOINT SP_PR_IMPOSTA_GIORNO_CHIUSURA;
    
    SELECT ID_SALA INTO V_ID_SALA FROM CD_PROIEZIONE,CD_SCHERMO
    WHERE CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
    AND   CD_PROIEZIONE.ID_PROIEZIONE =  P_ID_PROIEZIONE;
--    
    SELECT DATA_PROIEZIONE INTO V_DATA_RIF FROM CD_PROIEZIONE 
    WHERE ID_PROIEZIONE = P_ID_PROIEZIONE;
--    
    /*VERIFICO DISPONIBILITA DELLE FERIE*/
    V_DISPONIBILITA := FU_DISPONIBILITA_FERIE(P_ID_PROIEZIONE,P_ID_CODICE_RESP);
    IF(V_DISPONIBILITA >0 )THEN
        IF(P_ID_CODICE_RESP IS NULL)THEN
            DELETE CD_SALA_INDISP
            WHERE ID_SALA = V_ID_SALA
            AND   DATA_RIF = V_DATA_RIF;
        ELSE
            /*VERIFICO CHE CI SIANO GIA' DELLE CAUSALI PRESENTI*/
            SELECT COUNT(1) INTO V_NUM_REC
            FROM CD_SALA_INDISP
            WHERE ID_SALA = V_ID_SALA
            AND   DATA_RIF = V_DATA_RIF;
            IF(V_NUM_REC>0)THEN
                /*POSSO ESEGUIRE UPDATE*/
                UPDATE CD_SALA_INDISP
                SET ID_CODICE_RESP = P_ID_CODICE_RESP
                WHERE ID_SALA = V_ID_SALA
                AND   DATA_RIF = V_DATA_RIF;
            ELSE
                /*ESEGUO INSERT*/
                INSERT INTO CD_SALA_INDISP
                (ID_CODICE_RESP,ID_SALA,DATA_RIF)
                VALUES
                (P_ID_CODICE_RESP,V_ID_SALA,V_DATA_RIF);
            END IF;
        END IF;
    
    ELSE
        P_ESITO := -10;
    END IF;
--    
--
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_IMPOSTA_GIORNO_CHIUSURA: Si sono verificati dei problemi durante l''impostazione dei giorni di chiusura '||p_id_proiezione||' '||sqlerrm);
        P_ESITO := -100;
        ROLLBACK TO SP_PR_IMPOSTA_GIORNO_CHIUSURA;
  END;


PROCEDURE PR_SALVA_GIORNI_SANATORIA(p_id_sala cd_sala.id_sala%type,
                                     p_id_liquidazione cd_liquidazione.ID_LIQUIDAZIONE%type,
                                     p_gg_sanatoria cd_quota_tab.gg_SANATORIA%type,
                                     p_esito       OUT NUMBER
                                 ) IS
BEGIN
    p_esito := 1;
    SAVEPOINT PR_SALVA_GIORNI_SANATORIA;
    --
    update cd_quota_tab
    set    gg_sanatoria = p_gg_sanatoria
    where id_sala = p_id_sala
    and   id_liquidazione = p_id_liquidazione;
    
    --
    EXCEPTION
        WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20007, 'PR_SALVA_GIORNI_SANATORIA: UPDATE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
        ROLLBACK TO PR_SALVA_GIORNI_SANATORIA;
END PR_SALVA_GIORNI_SANATORIA;
--



FUNCTION FU_GET_QUOTA_TAB(p_data_inizio cd_liquidazione.DATA_INIZIO%type, p_data_fine cd_liquidazione.DATA_FINE%type, p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%type) RETURN NUMBER IS
v_quota_tab number; 
BEGIN
        SELECT sum(QT.RICAVO_TAB) 
        INTO   v_quota_tab
        FROM CD_LIQUIDAZIONE LI, VI_CD_SOCIETA_ESERCENTE ES, CD_ESER_CONTRATTO EC, 
             CD_CONTRATTO C, CD_CINEMA_CONTRATTO CC,CD_COMUNE CO, CD_CINEMA CI, 
             CD_SALA SA,CD_QUOTA_TAB QT--, CD_PERCENTUALE_RIPARTIZIONE PR
        WHERE LI.DATA_INIZIO = TRUNC(p_data_inizio)
        AND   LI.DATA_FINE = TRUNC(p_data_fine)
        AND   ES.COD_ESERCENTE = p_cod_esercente
        AND   ES.COD_ESERCENTE = EC.COD_ESERCENTE
        AND   C.ID_CONTRATTO = EC.ID_CONTRATTO
        AND   CC.ID_CONTRATTO = C.ID_CONTRATTO
        AND   CI.ID_CINEMA = CC.ID_CINEMA
        AND   SA.ID_CINEMA = CI.ID_CINEMA
        AND   CO.ID_COMUNE = CI.ID_COMUNE
        AND   QT.ID_SALA = SA.ID_SALA
        AND   QT.ID_LIQUIDAZIONE = LI.ID_LIQUIDAZIONE
        AND NVL(ES.DATA_FINE_VALIDITA,TO_DATE('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(ES.DATA_INIZIO_VALIDITA,TO_DATE('01011900','DDMMYYYY')) <= p_data_fine
        AND NVL(EC.DATA_FINE,TO_DATE('31122999','DDMMYYYY')) >= p_data_inizio
        AND NVL(EC.DATA_INIZIO,TO_DATE('01011900','DDMMYYYY')) <= p_data_fine;
      return  nvl(v_quota_tab,0);
END FU_GET_QUOTA_TAB;


FUNCTION FU_GET_QUOTA_ISP(p_data_inizio cd_liquidazione.DATA_INIZIO%type, p_data_fine cd_liquidazione.DATA_FINE%type, p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%type) RETURN NUMBER IS
v_quota_isp number; 
BEGIN

select sum(qta_isp.RICAVO_ISP)
into   v_quota_isp
from   cd_quota_isp qta_isp, 
       cd_liquidazione liq,
       cd_cinema cin,
       cd_cinema_contratto cico,
       cd_contratto co,
       cd_eser_contratto esco,
       vi_cd_societa_esercente es
where  LIQ.DATA_INIZIO = TRUNC(p_data_inizio)
and    LIQ.DATA_FINE = TRUNC(p_data_fine)
and    qta_isp.ID_LIQUIDAZIONE = liq.ID_LIQUIDAZIONE
and    qta_isp.ID_CINEMA = cin.ID_CINEMA
and    cico.ID_CINEMA = cin.ID_CINEMA
and    co.ID_CONTRATTO = cico.ID_CONTRATTO
and    esco.ID_CONTRATTO = co.ID_CONTRATTO
and    es.COD_ESERCENTE = esco.COD_ESERCENTE
and    es.COD_ESERCENTE =p_cod_esercente
and nvl(es.data_fine_validita,to_date('31122999','DDMMYYYY')) >= p_data_inizio
and nvl(es.data_inizio_validita,to_date('01011900','DDMMYYYY')) <= p_data_fine
and nvl(esco.data_fine,to_date('31122999','DDMMYYYY')) >= p_data_inizio
and nvl(esco.data_inizio,to_date('01011900','DDMMYYYY')) <= p_data_fine;
return  nvl(v_quota_isp,0);
END FU_GET_QUOTA_ISP;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RISOLUZIONE_CONTRATTO
--  Effettua l'update di CD_CONTRATTO in relazione alla fine validita di un cinema
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_fine_val     La data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--          4   - Data fine validita del cinema coincidente con la fine del contratto
--          5   - Effettuata risoluzione del contratto, data fine validita del 
--                  cinema minore della fine del contratto
--          -2  - Data fine validita non coerente; e' maggiore della data chiusura contratto
--          -3  - Nessun contratto di riferimento per la data inserita
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 2 Maggio 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RISOLUZIONE_CONTRATTO( p_id_cinema         CD_CINEMA_CONTRATTO.ID_CINEMA%TYPE,
                                    p_data_fine_val     CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER)
IS
    v_count                   NUMBER;
    v_id_contratto            CD_CONTRATTO.ID_CONTRATTO%TYPE;  
    v_data_chiusura_contratto CD_CONTRATTO.DATA_FINE%TYPE;  
BEGIN
    SAVEPOINT SP_PR_RISOLUZIONE_CONTRATTO;
    
    SELECT 
        COUNT(1)
    INTO
        v_count      
    FROM
        CD_CINEMA_CONTRATTO,
        CD_CONTRATTO
    WHERE   CD_CINEMA_CONTRATTO.ID_CINEMA = p_id_cinema
    AND     p_data_fine_val BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE
    AND     CD_CINEMA_CONTRATTO.ID_CONTRATTO = CD_CONTRATTO.ID_CONTRATTO;
    
    IF v_count = 1 THEN
        -- DATA DI CHIUSURA DEL CONTRATTO DI RIFERIMENTO
        SELECT 
            CD_CONTRATTO.ID_CONTRATTO,
            CD_CONTRATTO.DATA_FINE
        INTO
            v_id_contratto,
            v_data_chiusura_contratto
        FROM
            CD_CINEMA_CONTRATTO,
            CD_CONTRATTO
        WHERE   CD_CINEMA_CONTRATTO.ID_CINEMA = p_id_cinema
        AND     p_data_fine_val BETWEEN CD_CONTRATTO.DATA_INIZIO AND CD_CONTRATTO.DATA_FINE
        AND     CD_CINEMA_CONTRATTO.ID_CONTRATTO = CD_CONTRATTO.ID_CONTRATTO;
    
            IF p_data_fine_val = v_data_chiusura_contratto THEN
                --DATA FINE VALIDITA COINCIDENTE CON LA DATA DI CHIUSURA DEL CONTRATTO
                UPDATE
                    CD_CONTRATTO
                SET
                    DATA_RISOLUZIONE = null
                WHERE
                    ID_CONTRATTO = v_id_contratto;  
                                    
                p_esito := 4;
            ELSE 
                IF
                    p_data_fine_val < v_data_chiusura_contratto THEN
                    --DATA FINE VALIDITA PRECEDENTE ALLA DATA CHIUSURA DEL CONTRATTO
                    --Effettuo la risoluzione del contratto
                
                    UPDATE
                        CD_CONTRATTO
                    SET
                        DATA_RISOLUZIONE = p_data_fine_val
                    WHERE
                        ID_CONTRATTO = v_id_contratto;              
                
                    p_esito := 5;
                ELSE
                    --DATA FINE VALIDITA NON COERENTE; E' MAGGIORE DELLA DATA CHIUSURA CONTRATTO
                    --Non dovrei MAI trovarmi qui!
                    p_esito := -2;
                END IF;
            END IF;    
        ELSE
            --NESSUN CONTRATTO DI RIFERIMENTO
            p_esito := -3;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'Procedura PR_RISOLUZIONE_CONTRATTO: Update non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_RISOLUZIONE_CONTRATTO;
END;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_RISOL_CONTR
--  Effettua l'update di CD_CONTRATTO in relazione alla rivalidita di un cinema
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_risoluzione  La vecchia data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--          6   - Rivalidato il contratto
--          7   - Nessuna necessita di rivalidare contratto
--          -3  - Nessun contratto di riferimento per la data inserita
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 2 Maggio 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_RISOL_CONTR(   p_id_cinema         CD_CINEMA_CONTRATTO.ID_CINEMA%TYPE,
                                    p_data_risoluzione  CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER)
IS
    v_count                   NUMBER;
    v_id_contratto            CD_CONTRATTO.ID_CONTRATTO%TYPE;
    v_data_chiusura_contratto CD_CONTRATTO.DATA_FINE%TYPE; 
BEGIN
    SAVEPOINT SP_PR_ANNULLA_RISOL_CONTR;
    
    SELECT 
        COUNT(1)
    INTO
        v_count      
    FROM
        CD_CINEMA_CONTRATTO,
        CD_CONTRATTO
    WHERE   CD_CINEMA_CONTRATTO.ID_CINEMA = p_id_cinema
    AND     CD_CONTRATTO.DATA_RISOLUZIONE = p_data_risoluzione
    AND     CD_CINEMA_CONTRATTO.ID_CONTRATTO = CD_CONTRATTO.ID_CONTRATTO; 
    
    IF v_count = 1 THEN
    
        SELECT 
            CD_CONTRATTO.ID_CONTRATTO,
            CD_CONTRATTO.DATA_FINE
        INTO
            v_id_contratto,
            v_data_chiusura_contratto
        FROM
            CD_CINEMA_CONTRATTO,
            CD_CONTRATTO
        WHERE   CD_CINEMA_CONTRATTO.ID_CINEMA = p_id_cinema
        AND     CD_CONTRATTO.DATA_RISOLUZIONE = p_data_risoluzione
        AND     CD_CINEMA_CONTRATTO.ID_CONTRATTO = CD_CONTRATTO.ID_CONTRATTO;
        
        IF v_data_chiusura_contratto IS NOT NULL THEN
        
            --RIVALIDO IL CONTRATTO
            UPDATE
                CD_CONTRATTO
            SET
                DATA_RISOLUZIONE = null
            WHERE
                ID_CONTRATTO = v_id_contratto;
                           
            p_esito := 6;
            
        ELSE
            --NON C'E' BISOGNO DI RIVALIDARE NULLA, IL CONTRATTO NON ERA CHIUSO
            p_esito := 7;
        END IF;                          
    ELSE
        --NESSUN CONTRATTO DI RIFERIMENTO
        p_esito := -3;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'Procedura PR_ANNULLA_RISOL_CONTR: Update non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_ANNULLA_RISOL_CONTR;
END;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_RAGGR_QUOTE_ESER
-- Estrae le informazioni riguardanti le quote esercenti per un periodo
--
-- INPUT
--          p_cod_esercente     codice dell'esercente 
--          p_id_gruppo         codice gruppo
--          p_data_inizio       data inizio raggruppamento 
--          p_data_fine         data fine raggruppamento
--
-- OUTPUT
--          Cursore di R_QUOTA_ESERCENTE contenente le quote raggruppate
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 1 Dicembre 2011
-- --------------------------------------------------------------------------------------------                                      
FUNCTION FU_RAGGR_QUOTE_ESER(   p_cod_esercente     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE, 
                                p_id_gruppo         VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE%TYPE,
                                p_data_inizio       CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                p_data_fine         CD_LIQUIDAZIONE.DATA_FINE%TYPE
                            ) RETURN C_QUOTA_ESERCENTE 
IS
v_quote C_QUOTA_ESERCENTE;
v_esito NUMBER;
BEGIN
    OPEN v_quote FOR
        SELECT 
            DISTINCT VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE, 
            VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE, 
            SUM(CD_QUOTA_ESERCENTE.QUOTA_ESERCENTE)
                AS QUOTA_ESERCENTE,
            null,
            VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO, 
            SUM(CD_QUOTA_ESERCENTE.GG_SAN_RIT_PART)
                AS GG_SAN_RIT_PART,
            SUM(CD_QUOTA_ESERCENTE.GG_CHIUSURA_CONC)
                AS GG_CHIUSURA_CONC, 
            PA_CD_ESERCENTE.FU_GET_RAGGR_QUOTA_TAB(p_data_inizio, p_data_fine, VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE)
                AS QUOTA_TAB, 
            PA_CD_ESERCENTE.FU_GET_RAGGR_QUOTA_ISP(p_data_inizio, p_data_fine, VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE)
                AS QUOTA_ISP
        FROM 
            VI_CD_SOCIETA_GRUPPO,
            VI_CD_GRUPPO_ESERCENTE,
            VI_CD_SOCIETA_ESERCENTE,
            CD_LIQUIDAZIONE,
            CD_QUOTA_ESERCENTE
        WHERE   (
                    p_cod_esercente IS NULL 
                        OR 
                    CD_QUOTA_ESERCENTE.COD_ESERCENTE                                        =   p_cod_esercente
                )
        AND     VI_CD_SOCIETA_GRUPPO.COD_ESERCENTE(+)                                       =   VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE
        AND     VI_CD_GRUPPO_ESERCENTE.ID_GRUPPO_ESERCENTE                                  =   VI_CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE
        AND     (
                    p_id_gruppo IS NULL 
                    OR 
                    VI_CD_SOCIETA_GRUPPO.ID_GRUPPO_ESERCENTE                                =   p_id_gruppo
                )
        AND     nvl (VI_CD_SOCIETA_GRUPPO.DATA_FINE_VAL, to_date('31122999','DDMMYYYY'))    >=  p_data_inizio
        AND     VI_CD_SOCIETA_GRUPPO.DATA_INIZIO_VAL                                        <=  p_data_fine
        AND     CD_QUOTA_ESERCENTE.ID_LIQUIDAZIONE                                          =   CD_LIQUIDAZIONE.ID_LIQUIDAZIONE
        AND     CD_LIQUIDAZIONE.DATA_INIZIO                                                 >=  trunc(p_data_inizio)
        AND     CD_LIQUIDAZIONE.DATA_FINE                                                   <=  trunc(p_data_fine)
        AND     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE                                       =   CD_QUOTA_ESERCENTE.COD_ESERCENTE
        AND     CD_QUOTA_ESERCENTE.STATO_LAVORAZIONE                                        NOT LIKE 'ANT'
        AND     CD_LIQUIDAZIONE.STATO_LAVORAZIONE                                           NOT LIKE 'ANT'        
        GROUP BY 
            VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE,
            VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE,
            VI_CD_GRUPPO_ESERCENTE.NOME_GRUPPO
        ORDER BY 
                VI_CD_SOCIETA_ESERCENTE.RAGIONE_SOCIALE;
    RETURN v_quote;
END FU_RAGGR_QUOTE_ESER;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_GET_RAGGR_QUOTA_TAB
-- Estrae la quota tabellare raggruppata per periodo
--
-- INPUT
--          p_data_inizio       data inizio raggruppamento 
--          p_data_fine         data fine raggruppamento
--          p_cod_esercente     codice dell'esercente
-- OUTPUT
--          La quota cercata
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 1 Dicembre 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RAGGR_QUOTA_TAB(    p_data_inizio   CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                    p_data_fine     CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                    p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE
                               ) RETURN NUMBER
IS
v_quota_tab number; 
BEGIN
    SELECT 
        sum(CD_QUOTA_TAB.RICAVO_TAB) 
    INTO
        v_quota_tab
    FROM 
        CD_LIQUIDAZIONE, 
        VI_CD_SOCIETA_ESERCENTE, 
        CD_ESER_CONTRATTO, 
        CD_CONTRATTO,
        CD_CINEMA_CONTRATTO,
        CD_COMUNE, 
        CD_CINEMA, 
        CD_SALA,
        CD_QUOTA_TAB
    WHERE   CD_LIQUIDAZIONE.DATA_INIZIO           >=  trunc(p_data_inizio)
    AND     CD_LIQUIDAZIONE.DATA_FINE             <=  trunc(p_data_fine)
    AND     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE =   p_cod_esercente
    AND     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE =   CD_ESER_CONTRATTO.COD_ESERCENTE
    AND     CD_CONTRATTO.ID_CONTRATTO             =   CD_ESER_CONTRATTO.ID_CONTRATTO
    AND     CD_CINEMA_CONTRATTO.ID_CONTRATTO      =   CD_CONTRATTO.ID_CONTRATTO
    AND     CD_CINEMA.ID_CINEMA                   =   CD_CINEMA_CONTRATTO.ID_CINEMA
    AND     CD_SALA.ID_CINEMA                     =   CD_CINEMA.ID_CINEMA
    AND     CD_COMUNE.ID_COMUNE                   =   CD_CINEMA.ID_COMUNE
    AND     CD_QUOTA_TAB.ID_SALA                  =   CD_SALA.ID_SALA
    AND     CD_QUOTA_TAB.ID_LIQUIDAZIONE          =   CD_LIQUIDAZIONE.ID_LIQUIDAZIONE
    AND     nvl(VI_CD_SOCIETA_ESERCENTE.DATA_FINE_VALIDITA,TO_DATE('31122999','DDMMYYYY'))      >= p_data_inizio
    AND     nvl(VI_CD_SOCIETA_ESERCENTE.DATA_INIZIO_VALIDITA,TO_DATE('01011900','DDMMYYYY'))    <= p_data_fine
    AND     nvl(CD_ESER_CONTRATTO.DATA_FINE,TO_DATE('31122999','DDMMYYYY'))                     >= p_data_inizio
    AND     nvl(CD_ESER_CONTRATTO.DATA_INIZIO,TO_DATE('01011900','DDMMYYYY'))                   <= p_data_fine
    AND     CD_LIQUIDAZIONE.STATO_LAVORAZIONE                                                   NOT LIKE 'ANT'; 
    RETURN  nvl(v_quota_tab,0);
END FU_GET_RAGGR_QUOTA_TAB;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_GET_RAGGR_QUOTA_ISP
-- Estrae la quota iniziative speciali raggruppata per periodo
--
-- INPUT
--          p_data_inizio       data inizio raggruppamento 
--          p_data_fine         data fine raggruppamento
--          p_cod_esercente     codice dell'esercente
-- OUTPUT
--          La quota cercata
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 1 Dicembre 2011
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_RAGGR_QUOTA_ISP(    p_data_inizio   CD_LIQUIDAZIONE.DATA_INIZIO%TYPE, 
                                    p_data_fine     CD_LIQUIDAZIONE.DATA_FINE%TYPE, 
                                    p_cod_esercente VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE%TYPE
                               ) RETURN NUMBER
IS
v_quota_isp number; 
BEGIN
    SELECT 
        sum(CD_QUOTA_ISP.RICAVO_ISP)
    INTO
        v_quota_isp
    FROM   
        CD_QUOTA_ISP, 
        CD_LIQUIDAZIONE,
        CD_CINEMA,
        CD_CINEMA_CONTRATTO,
        CD_CONTRATTO,
        CD_ESER_CONTRATTO,
        VI_CD_SOCIETA_ESERCENTE
    WHERE   CD_LIQUIDAZIONE.DATA_INIZIO              >= trunc(p_data_inizio)
    AND     CD_LIQUIDAZIONE.DATA_FINE                <= trunc(p_data_fine)
    AND     CD_QUOTA_ISP.ID_LIQUIDAZIONE             = CD_LIQUIDAZIONE.ID_LIQUIDAZIONE
    AND     CD_QUOTA_ISP.ID_CINEMA                   = CD_CINEMA.ID_CINEMA
    AND     CD_CINEMA_CONTRATTO.ID_CINEMA            = CD_CINEMA.ID_CINEMA
    AND     CD_CONTRATTO.ID_CONTRATTO                = CD_CINEMA_CONTRATTO.ID_CONTRATTO
    AND     CD_ESER_CONTRATTO.ID_CONTRATTO           = CD_CONTRATTO.ID_CONTRATTO
    AND     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE    = CD_ESER_CONTRATTO.COD_ESERCENTE
    AND     VI_CD_SOCIETA_ESERCENTE.COD_ESERCENTE    = p_cod_esercente
    AND     nvl(VI_CD_SOCIETA_ESERCENTE.DATA_FINE_VALIDITA,TO_DATE('31122999','DDMMYYYY'))      >= p_data_inizio
    AND     nvl(VI_CD_SOCIETA_ESERCENTE.DATA_INIZIO_VALIDITA,TO_DATE('01011900','DDMMYYYY'))    <= p_data_fine
    AND     nvl(CD_ESER_CONTRATTO.DATA_FINE,TO_DATE('31122999','DDMMYYYY'))                     >= p_data_inizio
    AND     nvl(CD_ESER_CONTRATTO.DATA_INIZIO,TO_DATE('01011900','DDMMYYYY'))                   <= p_data_fine
    AND     CD_LIQUIDAZIONE.STATO_LAVORAZIONE                                                   NOT LIKE 'ANT';    
    RETURN  nvl(v_quota_isp,0);
END FU_GET_RAGGR_QUOTA_ISP;

END; 
/

