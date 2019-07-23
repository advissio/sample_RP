CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_TUTELA AS
/***************************************************************************************
   NAME:      PA_CD_TUTELA
   AUTHOR:    Simone Bottani (Altran)
   PURPOSE:   Questo package contiene procedure/funzioni necessarie per la gestione
              della tutela ai minori


   REVISIONS:
   Ver        Date        Author                    Description
   ---------  ----------  ---------------           ------------------------------------
   1.0        15/06/2010  Simone Bottani (Altran)   Created this package.
****************************************************************************************/


FUNCTION FU_VERIFICA_TUTELA(P_ID_CLIENTE_COMM VI_CD_CLIENTE.ID_CLIENTE%TYPE, P_ID_SOGGETTO_DI_PIANO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE, P_ID_MATERIALE_DI_PIANO CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE) RETURN CHAR IS
V_ID_MATERIALE CD_MATERIALE.ID_MATERIALE%TYPE := null;
V_COD_SOGG SOGGETTI.COD_SOGG%TYPE:= null;
BEGIN
   IF P_ID_SOGGETTO_DI_PIANO IS NOT NULL THEN
      
       SELECT COD_SOGG
       INTO   V_COD_SOGG
       FROM   CD_SOGGETTO_DI_PIANO
       WHERE  ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO_DI_PIANO;

   END IF;
    IF P_ID_MATERIALE_DI_PIANO IS NOT NULL THEN
       SELECT ID_MATERIALE
       INTO   V_ID_MATERIALE
       FROM   CD_MATERIALE_DI_PIANO
       WHERE  ID_MATERIALE_DI_PIANO = P_ID_MATERIALE_DI_PIANO;
   END IF;
   RETURN FU_CD_VERIFICA_TUTELA(P_ID_CLIENTE_COMM,V_COD_SOGG,V_ID_MATERIALE);
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
      RAISE;
     WHEN OTHERS THEN
      RAISE;
END FU_VERIFICA_TUTELA; 



/*******************************************************************************
 Funzione FU_SETTORI_NIELSEN
 Author:  Simone Bottani , Altran, Giugno 2010

 La funzione restituisce tutti i settori merceologici Nielsen presenti nel sistema
*******************************************************************************/
FUNCTION FU_SETTORI_NIELSEN RETURN C_SETTORE_NIELSEN IS
v_settori C_SETTORE_NIELSEN;
BEGIN
    OPEN v_settori FOR
    SELECT SETT.COD_SETT_MERC, SETT.DES_SETT_MERC
    FROM NIELSETT SETT
    WHERE FLAG_VALD = 'A'
    ORDER BY SETT.DES_SETT_MERC;
    RETURN v_settori;
END FU_SETTORI_NIELSEN;
/*******************************************************************************
 Funzione FU_CAT_NIELSEN
 Author:  Simone Bottani , Altran, Giugno 2010

 La funzione restituisce le categorie merceologiche Nielsen presenti nel sistema
 che fanno parte di un settore merceologico
*******************************************************************************/
FUNCTION FU_CAT_NIELSEN(p_cod_settore NIELSCAT.NS_COD_SETT_MERC%TYPE) RETURN C_CAT_NIELSEN IS
v_categorie C_CAT_NIELSEN;
BEGIN
    OPEN v_categorie FOR
    SELECT CAT.COD_CAT_MERC, CAT.DES_CAT_MERC
    FROM NIELSCAT CAT
    WHERE CAT.NS_COD_SETT_MERC = NVL(p_cod_settore,CAT.NS_COD_SETT_MERC)
    AND FLAG_VALD = 'A'
    ORDER BY CAT.DES_CAT_MERC;
    RETURN v_categorie;
END FU_CAT_NIELSEN;
/*******************************************************************************
 Funzione FU_CLASSE_NIELSEN
 Author:  Simone Bottani , Altran, Giugno 2010

 La funzione restituisce le classi merceologiche Nielsen presenti nel sistema
 che fanno parte di una categoria merceologica
*******************************************************************************/
FUNCTION FU_CLASSI_NIELSEN(p_categoria NIELSCL.NT_COD_CAT_MERC%TYPE) RETURN C_CLASSE_NIELSEN IS
v_classi C_CLASSE_NIELSEN;
BEGIN
    OPEN v_classi FOR
    SELECT CL.COD_CL_MERC, CL.DES_CL_MERC
    FROM NIELSCL CL
    WHERE CL.NT_COD_CAT_MERC = NVL(p_categoria,CL.NT_COD_CAT_MERC)
    AND FLAG_VALD = 'A'
    ORDER BY CL.DES_CL_MERC;
    RETURN v_classi;
END FU_CLASSI_NIELSEN;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_AGGIUNGI_MERC_SPECIALE
--
-- DESCRIZIONE:  Aggiunge una nuova merceologia alla lista di categorie merceologiche soggette a tutela
--
-- OPERAZIONI:
--   1) Inserisce la merceologia alla lista di categorie merceologiche soggette a tutela
--
-- INPUT:
--      p_cod_settore         id del settore merceologico
--      p_cod_categoria       id della categoria merceologica
--      p_cod_classe          id della classe merceologica
--      p_limitazione_tutela  id del tipo di tutela imposto (es. alcoolici)
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_AGGIUNGI_MERC_SPECIALE(p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE,
                                    p_cod_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                                    p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE,
                                    p_limitazione_tutela CD_MERCEOLOGIE_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE) IS
--
v_merceologie NUMBER;
BEGIN
    SELECT COUNT(1) 
    INTO v_merceologie
    FROM CD_MERCEOLOGIE_SPECIALI
    WHERE COD_SETTORE = p_cod_settore
    AND COD_CATEGORIA = p_cod_categoria
    AND COD_CLASSE = p_cod_classe
    AND p_limitazione_tutela = p_limitazione_tutela
    AND FLG_ANNULLATO = 'S';
    --
    IF v_merceologie > 0 THEN
        UPDATE CD_MERCEOLOGIE_SPECIALI
        SET FLG_ANNULLATO = 'N'
        WHERE COD_SETTORE = p_cod_settore
        AND COD_CATEGORIA = p_cod_categoria
        AND COD_CLASSE = p_cod_classe
        AND p_limitazione_tutela = p_limitazione_tutela
        AND FLG_ANNULLATO = 'S';        
    ELSE
        INSERT INTO CD_MERCEOLOGIE_SPECIALI(COD_SETTORE, COD_CATEGORIA, COD_CLASSE, ID_LIMITAZIONI_TUTELA)
        VALUES (p_cod_settore, p_cod_categoria, p_cod_classe, p_limitazione_tutela);
    END IF;
    

    PR_TUTELA_MERCEOLOGIA(p_cod_settore,p_cod_categoria,p_cod_classe);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_AGGIUNGI_MERC_SPECIALE: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_AGGIUNGI_MERC_SPECIALE;

FUNCTION FU_MERCEOLOGIE_TUTELA(p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE, 
                           p_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                           p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE,
                           p_id_limitazione CD_MERCEOLOGIE_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE
                           ) RETURN C_MERCEOLOGIE IS
--
v_merceologie C_MERCEOLOGIE;
BEGIN
    OPEN v_merceologie FOR
    SELECT M.ID_MERCEOLOGIE_SPECIALI, M.COD_SETTORE, SETT.DES_SETT_MERC, 
    M.COD_CATEGORIA, CAT.DES_CAT_MERC, M.COD_CLASSE, CL.DES_CL_MERC,
    L.ID_LIMITAZIONI_TUTELA, L.DESCRIZIONE
    FROM NIELSETT SETT, NIELSCAT CAT, NIELSCL CL, CD_LIMITAZIONI_TUTELA L, CD_MERCEOLOGIE_SPECIALI M
    WHERE M.COD_SETTORE = NVL(p_cod_settore, M.COD_SETTORE)
    AND M.COD_CATEGORIA = NVL(p_categoria, M.COD_CATEGORIA)
    AND M.COD_CLASSE = NVL(p_cod_classe, M.COD_CLASSE)
    AND M.FLG_ANNULLATO = 'N'
    AND L.ID_LIMITAZIONI_TUTELA = NVL(p_id_limitazione,L.ID_LIMITAZIONI_TUTELA)
    AND L.ID_LIMITAZIONI_TUTELA = M.ID_LIMITAZIONI_TUTELA
    AND SETT.COD_SETT_MERC = M.COD_SETTORE
    AND CAT.COD_CAT_MERC(+) = M.COD_CATEGORIA
    AND CAT.NS_COD_SETT_MERC(+) = M.COD_SETTORE
    AND CL.COD_CL_MERC(+) = M.COD_CLASSE
    AND CL.NT_COD_CAT_MERC(+) = M.COD_CATEGORIA;
    RETURN v_merceologie;
END FU_MERCEOLOGIE_TUTELA;  

/*******************************************************************************
 Funzione FU_CLIENTI_SPECIALI
 Author: Michele Borgogno , Altran, Giugno 2010

 La funzione restituisce i clienti speciali soggetti a tutela
*******************************************************************************/
----------------------
FUNCTION FU_CLIENTI_SPECIALI(p_id_cliente CD_CLIENTI_SPECIALI.ID_CLIENTE%TYPE,
                             p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE) RETURN C_CLIENTE IS
v_clienti C_CLIENTE;
BEGIN
    OPEN v_clienti FOR
        SELECT DISTINCT(CS.ID_CLIENTE), CL.RAG_SOC_COGN
            FROM CD_CLIENTI_SPECIALI CS, VI_CD_CLIENTE CL
            WHERE  CS.ID_CLIENTE = NVL(p_id_cliente,CS.ID_CLIENTE)
            AND CS.ID_LIMITAZIONI_TUTELA = NVL(p_id_limitazione,CS.ID_LIMITAZIONI_TUTELA)
            AND CS.ID_CLIENTE = CL.ID_CLIENTE
            AND CS.FLG_ANNULLATO = 'N'
            ORDER BY CL.RAG_SOC_COGN;
    RETURN v_clienti;
END FU_CLIENTI_SPECIALI;  

/*******************************************************************************
 Funzione FU_LIMITAZIONI_CLIENTI_SPEC
 Author: Michele Borgogno , Altran, Giugno 2010

 La funzione restituisce i clienti speciali soggetti a tutela
*******************************************************************************/
----------------------
FUNCTION FU_LIMITAZIONI_CLIENTI_SPEC(p_id_cliente CD_CLIENTI_SPECIALI.ID_CLIENTE%TYPE,
                             p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE) RETURN C_CLIENTE_SPECIALE IS
v_clienti C_CLIENTE_SPECIALE;
BEGIN
    OPEN v_clienti FOR
        SELECT CS.ID_CLIENTI_SPECIALI, CS.ID_CLIENTE, CL.RAG_SOC_COGN, 
               CS.ID_LIMITAZIONI_TUTELA, LT.CODICE, LT.DESCRIZIONE
            FROM CD_CLIENTI_SPECIALI CS, CD_LIMITAZIONI_TUTELA LT, VI_CD_CLIENTE CL
            WHERE  CS.ID_CLIENTE = NVL(p_id_cliente,CS.ID_CLIENTE)
            AND CS.ID_LIMITAZIONI_TUTELA = NVL(p_id_limitazione,CS.ID_LIMITAZIONI_TUTELA)
            AND CS.ID_CLIENTE = CL.ID_CLIENTE
            AND CS.ID_LIMITAZIONI_TUTELA = LT.ID_LIMITAZIONI_TUTELA
            AND CS.FLG_ANNULLATO = 'N'
            ORDER BY CL.RAG_SOC_COGN;
    RETURN v_clienti;
END FU_LIMITAZIONI_CLIENTI_SPEC;  

/*******************************************************************************
 Funzione FU_CLIENTI_NO_TUTELA
 Author: Michele Borgogno , Altran, Giugno 2010

 La funzione restituisce i clienti non soggetti a tutela
*******************************************************************************/
----------------------
FUNCTION FU_CLIENTI_NO_TUTELA RETURN C_CLIENTE IS
v_clienti C_CLIENTE;
BEGIN
    OPEN v_clienti FOR
        SELECT CC.COD_INTERL AS ID_CLIENTE, CC.RAGSOC AS RAG_SOC_COGN
            FROM CLICOMM CC, CD_CLIENTI_SPECIALI CS
            WHERE CC.COD_INTERL != CS.ID_CLIENTE 
            ORDER BY CC.RAGSOC;
    
    RETURN v_clienti;
END FU_CLIENTI_NO_TUTELA;  

/*******************************************************************************
 Funzione FU_LIMITAZIONI_TUTELA
 Author: Michele Borgogno , Altran, Giugno 2010

 La funzione restituisce l'elenco delle limitazioni per tutela
*******************************************************************************/
FUNCTION FU_LIMITAZIONI_TUTELA RETURN C_LIMITAZIONE_TUTELA IS
v_limitazioni C_LIMITAZIONE_TUTELA;
BEGIN
    OPEN v_limitazioni FOR
        SELECT LT.ID_LIMITAZIONI_TUTELA, LT.CODICE, LT.DESCRIZIONE
            FROM CD_LIMITAZIONI_TUTELA LT
            ORDER BY LT.DESCRIZIONE;
    RETURN v_limitazioni;
END FU_LIMITAZIONI_TUTELA;    
-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_MERC_SPECIALE
--
-- DESCRIZIONE:  Modifica una merceologia sottoposta a tutela
--
-- OPERAZIONI:
--   1) Modifica la merceologia
--
-- INPUT:
--      p_id_merceologia      id della merceologia
--      p_cod_settore         id del settore merceologico
--      p_cod_categoria       id della categoria merceologica
--      p_cod_classe          id della classe merceologica
--      p_limitazione_tutela  id del tipo di tutela imposto (es. alcoolici)
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_MERC_SPECIALE(p_id_merceologia CD_MERCEOLOGIE_SPECIALI.ID_MERCEOLOGIE_SPECIALI%TYPE,
                                    p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE,
                                    p_cod_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                                    p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE,
                                    p_limitazione_tutela CD_MERCEOLOGIE_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE) IS
--
BEGIN
    UPDATE CD_MERCEOLOGIE_SPECIALI
    SET COD_SETTORE = p_cod_settore,
        COD_CATEGORIA = p_cod_categoria,
        COD_CLASSE = p_cod_classe,
        ID_LIMITAZIONI_TUTELA = p_limitazione_tutela
    WHERE ID_MERCEOLOGIE_SPECIALI = p_id_merceologia;
    PR_TUTELA_MERCEOLOGIA(p_cod_settore,p_cod_categoria,p_cod_classe);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_MODIFICA_MERC_SPECIALE: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_MODIFICA_MERC_SPECIALE;                   

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_MERC_SPECIALE
--
-- DESCRIZIONE:  Elimina una merceologia sottoposta a tutela
--
-- OPERAZIONI:
--   1) Elimina la merceologia
--
-- INPUT:
--      p_id_merceologia      id della merceologia
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_MERC_SPECIALE(p_id_merceologia CD_MERCEOLOGIE_SPECIALI.ID_MERCEOLOGIE_SPECIALI%TYPE) IS
--
v_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE;
v_cod_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE;
v_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE;
BEGIN
    SELECT COD_SETTORE, COD_CATEGORIA, COD_CLASSE
    INTO v_cod_settore, v_cod_categoria, v_cod_classe
    FROM CD_MERCEOLOGIE_SPECIALI
    WHERE ID_MERCEOLOGIE_SPECIALI = p_id_merceologia;
    --
    UPDATE CD_MERCEOLOGIE_SPECIALI
    SET FLG_ANNULLATO = 'S'
    WHERE ID_MERCEOLOGIE_SPECIALI = p_id_merceologia;

    
    PR_TUTELA_MERCEOLOGIA(v_cod_settore,v_cod_categoria,v_cod_classe);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_ELIMINA_MERC_SPECIALE: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_ELIMINA_MERC_SPECIALE;   

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_CLIENTE_SPECIALE
--
-- DESCRIZIONE:  Aggiunge un nuovo cliente alla lista di clienti soggetti a tutela
--
-- INPUT:
--      p_id_cliente          id del cliente
--      p_id_limitazione      id del tipo di tutela imposto (es. alcoolici)
--
-- OUTPUT: 
--
-- REALIZZATORE: Michele Borgogno, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_CLIENTE_SPECIALE(p_id_cliente CD_CLIENTI_SPECIALI.ID_CLIENTE%TYPE,
                                        p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE) IS
--
v_count NUMBER := 0;
--
BEGIN
    SELECT COUNT(DISTINCT ID_CLIENTE) INTO v_count 
    FROM CD_CLIENTI_SPECIALI WHERE ID_CLIENTE = p_id_cliente
    AND ID_LIMITAZIONI_TUTELA = p_id_limitazione;
    
    IF(v_count=0)THEN
        INSERT INTO CD_CLIENTI_SPECIALI(ID_CLIENTE, ID_LIMITAZIONI_TUTELA)
        VALUES (p_id_cliente, p_id_limitazione);
    ELSE
        UPDATE CD_CLIENTI_SPECIALI SET FLG_ANNULLATO = 'N'         
        WHERE ID_CLIENTE = p_id_cliente
        AND ID_LIMITAZIONI_TUTELA = p_id_limitazione;
    END IF;   
    
    PR_TUTELA_CLIENTE(p_id_cliente,1); 
        
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_INSERISCI_CLIENTE_SPECIALE: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_INSERISCI_CLIENTE_SPECIALE;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_CLIENTE_SPECIALE
--
-- DESCRIZIONE:  Modifica il cliente speciale
--
-- INPUT:
--      p_id_cliente_speciale          id del cliente speciale
--      p_id_limitazione      id del tipo di tutela imposto (es. alcoolici)
--
-- OUTPUT: 
--
-- REALIZZATORE: Michele Borgogno, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_CLIENTE_SPECIALE(p_id_cliente_speciale CD_CLIENTI_SPECIALI.ID_CLIENTI_SPECIALI%TYPE,
                                       p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE,
                                       p_esito OUT NUMBER) IS
--
v_count NUMBER := 0;
v_id_cliente varchar(8);
--
BEGIN
    
    p_esito := 0;

    SELECT ID_CLIENTE INTO v_id_cliente FROM CD_CLIENTI_SPECIALI 
    WHERE ID_CLIENTI_SPECIALI = p_id_cliente_speciale;

    SELECT COUNT(1) INTO v_count FROM CD_CLIENTI_SPECIALI 
    WHERE ID_CLIENTE = v_id_cliente
    AND ID_LIMITAZIONI_TUTELA = p_id_limitazione;
    
    IF (v_count = 0) THEN
        UPDATE CD_CLIENTI_SPECIALI SET ID_LIMITAZIONI_TUTELA = p_id_limitazione         
        WHERE ID_CLIENTI_SPECIALI = p_id_cliente_speciale; 
    ELSE
        p_esito := 2;        
    END IF;  
        
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_MODIFICA_CLIENTE_SPECIALE: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_MODIFICA_CLIENTE_SPECIALE;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ANNULLA_CLIENTE_SPECIALE
--
-- DESCRIZIONE:  Annulla il cliente speciale
--
-- INPUT:
--      p_id_cliente_speciale          id del cliente speciale
--
-- OUTPUT: 
--
-- REALIZZATORE: Michele Borgogno, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CLIENTE_SPECIALE(p_id_cliente_speciale CD_CLIENTI_SPECIALI.ID_CLIENTI_SPECIALI%TYPE) IS
--
v_id_cliente VARCHAR(8);
--
BEGIN

    UPDATE CD_CLIENTI_SPECIALI SET FLG_ANNULLATO = 'S'         
    WHERE ID_CLIENTI_SPECIALI = p_id_cliente_speciale;  
    
    SELECT ID_CLIENTE INTO v_id_cliente 
    FROM CD_CLIENTI_SPECIALI WHERE ID_CLIENTI_SPECIALI = p_id_cliente_speciale;
    
    PR_TUTELA_CLIENTE(v_id_cliente,2);
        
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_ANNULLA_CLIENTE_SPECIALE: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI'||SQLERRM);
END PR_ANNULLA_CLIENTE_SPECIALE;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_TUTELA_MERCEOLOGIA
--
-- DESCRIZIONE:  A fronte di una variazione di una categoria merceologica sottoposta a tutela
--               vengono verificati tutti i comunicati che andranno in onda con il soggetto
--               appartenente alla categoria merceologica, e viene alzata o abbassato il flag tutela
--
-- INPUT:
--      p_cod_settore          Codice del settore merceologico
--      p_cod_categoria        Codice della categoria merceologica
--      p_cod_classe           Classe della categoria merceologica
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_TUTELA_MERCEOLOGIA( p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE,
                                 p_cod_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                                 p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE) IS
BEGIN
        UPDATE CD_COMUNICATO COM
        SET FLG_TUTELA = 'S'
        WHERE ID_SOGGETTO_DI_PIANO IN
        (
            select distinct sp.id_soggetto_di_piano
            from cd_soggetto_di_piano sp, soggetti so,nielscat cat,NIELSCL CL ,NIELSETT SETT,cd_merceologie_speciali m
            where sp.COD_SOGG = so.COD_SOGG
            and cat.COD_CAT_MERC= so.NL_NT_COD_CAT_MERC
            and  cl.COD_CL_MERC = so.NL_COD_CL_MERC
            and sett.COD_SETT_MERC = cat.NS_COD_SETT_MERC
            and cl.NT_COD_CAT_MERC = cat.COD_CAT_MERC
            AND decode(M.COD_CLASSE,-1,CL.COD_CL_MERC,M.COD_CLASSE) = CL.COD_CL_MERC
            AND decode(M.COD_CATEGORIA,-1,CAT.COD_CAT_MERC,M.COD_CATEGORIA) = CAT.COD_CAT_MERC
            and SETT.COD_SETT_MERC = M.COD_SETTORE 
            AND m.FLG_ANNULLATO = 'N'
        )
        AND DATA_EROGAZIONE_PREV > TRUNC(SYSDATE)
        AND FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL
        and FLG_TUTELA = 'N'
        AND ID_COMUNICATO IN
        (
            SELECT CS.ID_COMUNICATO
            FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO CS
            WHERE CS.ID_COMUNICATO = COM.ID_COMUNICATO
            AND BR.ID_BREAK = COM.ID_BREAK
            AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
            AND F.ID_FASCIA = P.ID_FASCIA
            AND F.FLG_PROTETTA = 'S'
        );
    
        UPDATE CD_COMUNICATO
        SET FLG_TUTELA = 'N'
        WHERE ID_COMUNICATO IN
        (
            SELECT ID_COMUNICATO 
            FROM CD_PIANIFICAZIONE PIA,
                 CD_PRODOTTO_ACQUISTATO PA,
                 CD_COMUNICATO COM
            WHERE ID_SOGGETTO_DI_PIANO NOT IN
            (
                select distinct sp.id_soggetto_di_piano
                from cd_soggetto_di_piano sp, soggetti so,nielscat cat,NIELSCL CL ,NIELSETT SETT,cd_merceologie_speciali m
                where sp.COD_SOGG = so.COD_SOGG
                and cat.COD_CAT_MERC= so.NL_NT_COD_CAT_MERC
                and  cl.COD_CL_MERC = so.NL_COD_CL_MERC
                and sett.COD_SETT_MERC = cat.NS_COD_SETT_MERC
                and cl.NT_COD_CAT_MERC = cat.COD_CAT_MERC
                AND decode(M.COD_CLASSE,-1,CL.COD_CL_MERC,M.COD_CLASSE) = CL.COD_CL_MERC
                AND decode(M.COD_CATEGORIA,-1,CAT.COD_CAT_MERC,M.COD_CATEGORIA) = CAT.COD_CAT_MERC
                and SETT.COD_SETT_MERC = M.COD_SETTORE
                AND m.FLG_ANNULLATO = 'N'
            )
            AND COM.DATA_EROGAZIONE_PREV > TRUNC(SYSDATE)
            AND COM.FLG_ANNULLATO = 'N'
            AND COM.FLG_SOSPESO = 'N'
            AND COM.COD_DISATTIVAZIONE IS NULL
            AND COM.FLG_TUTELA = 'S'
            AND ID_COMUNICATO IN
            (
                SELECT CS.ID_COMUNICATO
                FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO CS
                WHERE CS.ID_COMUNICATO = COM.ID_COMUNICATO
                AND BR.ID_BREAK = CS.ID_BREAK
                AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
                AND F.ID_FASCIA = P.ID_FASCIA
                AND F.FLG_PROTETTA = 'S'
            )
            AND PA.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
            AND PA.FLG_ANNULLATO = 'N'
            AND PA.FLG_SOSPESO = 'N'
            AND PA.COD_DISATTIVAZIONE IS NULL
            AND PIA.ID_PIANO = PA.ID_PIANO
            AND PIA.ID_VER_PIANO = PA.ID_VER_PIANO
            AND PIA.FLG_ANNULLATO = 'N'
            AND PIA.FLG_SOSPESO = 'N'
            AND PA_CD_TUTELA.FU_VERIFICA_TUTELA(PIA.ID_CLIENTE,NULL,COM.ID_MATERIALE_DI_PIANO) = 'N'
        );
 END PR_TUTELA_MERCEOLOGIA;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_TUTELA_CLIENTE
--
-- DESCRIZIONE:  Verifica se e un cliente e sottoposto a tutela, in questo caso alza il flag di tutela sui
--               comunicati del cliente in input
--
-- INPUT:
--      p_id_cliente         Codice del cliente
--      p_tipo_modifica       Tipo di modifica: 
--                                              1 Nuovo cliente speciale
--                                              2 Annullamento cliente speciale
--      p_cod_classe           Classe della categoria merceologica
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
------------------------------------------------------------------------------------------------- 
PROCEDURE PR_TUTELA_CLIENTE(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_tipo_modifica INTEGER) IS
BEGIN ----richiemata sull'annnullamento e l'inserimento del cliente speciale

IF p_tipo_modifica = 1 THEN
    UPDATE CD_COMUNICATO COM
    SET FLG_TUTELA = 'S'
    WHERE ID_PRODOTTO_ACQUISTATO IN
    (
        SELECT PA.ID_PRODOTTO_ACQUISTATO
        FROM CD_CLIENTI_SPECIALI CS, CD_PIANIFICAZIONE PIA,CD_PRODOTTO_ACQUISTATO PA
        WHERE PIA.ID_CLIENTE = P_ID_CLIENTE
        AND   PIA.FLG_ANNULLATO = 'N'
        AND   PIA.ID_PIANO  =  PA.ID_PIANO
        AND   PIA.ID_VER_PIANO =  PA.ID_VER_PIANO
        AND   PA.FLG_ANNULLATO = 'N'
        AND   PA.COD_DISATTIVAZIONE IS NULL
        AND   PA.FLG_SOSPESO = 'N'
        AND   CS.ID_CLIENTE = PIA.ID_CLIENTE
        AND   CS.FLG_ANNULLATO = 'N'
    )
    AND ID_COMUNICATO IN
    (
        SELECT CS.ID_COMUNICATO
        FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO CS
        WHERE CS.ID_COMUNICATO = COM.ID_COMUNICATO
        AND BR.ID_BREAK = CS.ID_BREAK
        AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
        AND F.ID_FASCIA = P.ID_FASCIA
        AND F.FLG_PROTETTA = 'S'
    )
    AND   COM.FLG_ANNULLATO = 'N'
    AND   COM.FLG_SOSPESO = 'N'
    AND   COM.COD_DISATTIVAZIONE IS NULL
    AND   COM.DATA_EROGAZIONE_PREV > TRUNC(SYSDATE)
    AND   COM.FLG_TUTELA = 'N';
ELSIF p_tipo_modifica = 2 THEN
    UPDATE CD_COMUNICATO COM
    SET FLG_TUTELA = 'N'
    WHERE ID_PRODOTTO_ACQUISTATO IN
    (
        SELECT PA.ID_PRODOTTO_ACQUISTATO
        FROM CD_CLIENTI_SPECIALI CS, CD_PIANIFICAZIONE PIA,CD_PRODOTTO_ACQUISTATO PA
        WHERE PIA.ID_CLIENTE = P_ID_CLIENTE
        AND   PIA.FLG_ANNULLATO = 'N'
        AND   PIA.ID_PIANO  =  PA.ID_PIANO
        AND   PIA.ID_VER_PIANO =  PA.ID_VER_PIANO
        AND   PA.FLG_ANNULLATO = 'N'
        AND   PA.COD_DISATTIVAZIONE IS NULL
        AND   PA.FLG_SOSPESO = 'N'
        AND   CS.ID_CLIENTE = PIA.ID_CLIENTE
        AND   CS.FLG_ANNULLATO = 'N'
    )
    AND ID_COMUNICATO IN
    (
        SELECT C.ID_COMUNICATO
        FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO C
        WHERE C.ID_COMUNICATO = COM.ID_COMUNICATO
        AND BR.ID_BREAK = C.ID_BREAK
        AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
        AND F.ID_FASCIA = P.ID_FASCIA
        AND F.FLG_PROTETTA = 'S'
    )
    AND   COM.FLG_ANNULLATO = 'N'
    AND   COM.FLG_SOSPESO = 'N'
    AND   COM.COD_DISATTIVAZIONE IS NULL
    AND   COM.DATA_EROGAZIONE_PREV > TRUNC(SYSDATE)
    AND   COM.FLG_TUTELA = 'S'
    AND   PA_CD_TUTELA.FU_VERIFICA_TUTELA(NULL,COM.ID_SOGGETTO_DI_PIANO,COM.ID_MATERIALE_DI_PIANO) = 'N';
END IF;
END PR_TUTELA_CLIENTE;
---------------------------------------------------------------------------------
/*******************************************************************************
 PR_ANNULLA_PER_TUTELA
 Author:  Simone Bottani, Altran, Giugno 2010
 DESCRIZIONE:   Controlla se un cliente, un soggetto o un materiale sono soggetti a tutela.
                In questo caso imposta su tutti i comunicati appartenenti alla fascia protetta
                il flag FLG_TUTELA
               
 INPUT: p_id_piano              Id del piano
        p_id_ver_piano          Versione del piano
        p_id_cliente            Cliente da verificare
        p_id_soggetto           Soggetto da verificare
        p_id_materiale          Materiale da verificare
OUTPUT: 
*******************************************************************************/
PROCEDURE PR_ANNULLA_PER_TUTELA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                p_id_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                p_id_materiale CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE) IS
--
v_flag CHAR(1);
    BEGIN
    --IF p_id_cliente IS NULL AND  p_id_soggetto IS NULL AND p_id_materiale IS NULL THEN
    --    RAISE NO_DATA_FOUND;
    --END IF;    
    v_flag := PA_CD_TUTELA.FU_VERIFICA_TUTELA(p_id_cliente,p_id_soggetto,p_id_materiale);
    IF p_id_cliente IS NOT NULL THEN
        UPDATE CD_COMUNICATO COM
        SET FLG_TUTELA = v_flag
        WHERE FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL
        AND FLG_TUTELA != v_flag
        AND ID_PRODOTTO_ACQUISTATO IN
        (
            SELECT ID_PRODOTTO_ACQUISTATO
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE FLG_ANNULLATO = 'N'
            AND FLG_SOSPESO = 'N'
            AND COD_DISATTIVAZIONE IS NULL
            AND ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano
        )
        AND ID_COMUNICATO IN
        (
            SELECT C.ID_COMUNICATO
            FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO C
            WHERE C.ID_COMUNICATO = COM.ID_COMUNICATO
            AND BR.ID_BREAK = C.ID_BREAK
            AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
            AND F.ID_FASCIA = P.ID_FASCIA
            AND F.FLG_PROTETTA = 'S'
        );
    ELSIF p_id_soggetto IS NOT NULL THEN
        UPDATE CD_COMUNICATO COM
        SET FLG_TUTELA = v_flag
        WHERE FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL
        AND FLG_TUTELA != v_flag
        AND ID_SOGGETTO_DI_PIANO = p_id_soggetto
        AND ID_PRODOTTO_ACQUISTATO IN
        (
            SELECT ID_PRODOTTO_ACQUISTATO
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE FLG_ANNULLATO = 'N'
            AND FLG_SOSPESO = 'N'
            AND COD_DISATTIVAZIONE IS NULL
            AND ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano
        )
        AND ID_COMUNICATO IN
        (
            SELECT C.ID_COMUNICATO
            FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO C
            WHERE C.ID_COMUNICATO = COM.ID_COMUNICATO
            AND BR.ID_BREAK = C.ID_BREAK
            AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
            AND F.ID_FASCIA = P.ID_FASCIA
            AND F.FLG_PROTETTA = 'S'
        );
    ELSIF p_id_materiale IS NOT NULL THEN
        UPDATE CD_COMUNICATO COM
        SET FLG_TUTELA = v_flag
        WHERE FLG_ANNULLATO = 'N'
        AND FLG_SOSPESO = 'N'
        AND COD_DISATTIVAZIONE IS NULL
        AND FLG_TUTELA != v_flag
        AND ID_MATERIALE_DI_PIANO = p_id_materiale
        AND ID_PRODOTTO_ACQUISTATO IN
        (
            SELECT ID_PRODOTTO_ACQUISTATO
            FROM CD_PRODOTTO_ACQUISTATO
            WHERE FLG_ANNULLATO = 'N'
            AND FLG_SOSPESO = 'N'
            AND COD_DISATTIVAZIONE IS NULL
            AND ID_PIANO = p_id_piano
            AND ID_VER_PIANO = p_id_ver_piano
        )
        AND ID_COMUNICATO IN
        (
            SELECT C.ID_COMUNICATO
            FROM CD_FASCIA F, CD_PROIEZIONE P, CD_BREAK BR, CD_COMUNICATO C
            WHERE C.ID_COMUNICATO = COM.ID_COMUNICATO
            AND BR.ID_BREAK = C.ID_BREAK
            AND P.ID_PROIEZIONE = BR.ID_PROIEZIONE
            AND F.ID_FASCIA = P.ID_FASCIA
            AND F.FLG_PROTETTA = 'S'
        );
    END IF;
 END PR_ANNULLA_PER_TUTELA;

END PA_CD_TUTELA; 
/

