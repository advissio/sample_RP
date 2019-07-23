CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PRODOTTO_PUBB AS
-----------------------------------------------------------------------------------------------------
-- Function FU_CERCA_PRODOTTO_PUBB
-- INPUT:  Criteri di ricerca dei prodotti pubblicitari
-- OUTPUT: Restituisce i prodotti pubblicitari che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE  
-------------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PRODOTTO_PUBB(p_desc_prodotto             CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
                                p_id_luogo                  CD_LUOGO.ID_LUOGO%TYPE,
								p_id_unita                  CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
								p_cod_categoria_prodotto    CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE,
                                p_cod_tipo_pubb             CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE,
                                p_gruppo_tipi_pubb          CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB%TYPE,
								p_singolo                   VARCHAR2)
                                RETURN C_PRODOTTO_PUBB
IS
    c_prodotto_pubb_return C_PRODOTTO_PUBB;
	v_si_singolo VARCHAR2(2):='S';
	v_no_singolo VARCHAR2(2):='N';
BEGIN
    OPEN c_prodotto_pubb_return
        FOR 
--PRIMA I TIPI SINGOLI
            SELECT DISTINCT CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB,
                   CD_PRODOTTO_PUBB.DESC_PRODOTTO DESC_PRODOTTO,
                   (SELECT DISTINCT VENPC.PC_CATEGORIA_PRODOTTO.DESCRIZIONE
                               FROM VENPC.PC_CATEGORIA_PRODOTTO
                              WHERE VENPC.PC_CATEGORIA_PRODOTTO.COD = CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO) CATEGORIA_PRODOTTO,
                   (SELECT DISTINCT VENPC.PC_TIPI_PUBBLICITA.DES_TIPO_PUBB
                               FROM VENPC.PC_TIPI_PUBBLICITA
                              WHERE VENPC.PC_TIPI_PUBBLICITA.COD_TIPO_PUBB = CD_PRODOTTO_PUBB.COD_TIPO_PUBB) TIPO_PUBB,
                   (SELECT CD_LUOGO.DESC_LUOGO
                      FROM CD_LUOGO
                     WHERE CD_LUOGO.ID_LUOGO = CD_LUOGO_TIPO_PUBB.ID_LUOGO) UBICAZIONE_AMBITO,
                   (SELECT CD_UNITA_MISURA_TEMP.DESC_UNITA
                      FROM CD_UNITA_MISURA_TEMP
                     WHERE CD_UNITA_MISURA_TEMP.ID_UNITA = CD_MISURA_PRD_VENDITA.ID_UNITA) PERIODO_VENDITA,
                   v_si_singolo SINGOLO
            FROM   CD_MISURA_PRD_VENDITA, CD_PRODOTTO_PUBB, CD_LUOGO_TIPO_PUBB
            WHERE  CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB = CD_MISURA_PRD_VENDITA.ID_PRODOTTO_PUBB
            AND    CD_LUOGO_TIPO_PUBB.COD_TIPO_PUBB = CD_PRODOTTO_PUBB.COD_TIPO_PUBB
            AND    CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB IS NULL
			AND    p_gruppo_tipi_pubb IS NULL
			AND    CD_LUOGO_TIPO_PUBB.ID_LUOGO= NVL(p_id_luogo,CD_LUOGO_TIPO_PUBB.ID_LUOGO)
			AND    CD_MISURA_PRD_VENDITA.ID_UNITA= NVL(p_id_unita,CD_MISURA_PRD_VENDITA.ID_UNITA)
			AND    CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO=NVL(p_cod_categoria_prodotto,CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO)
            AND    CD_PRODOTTO_PUBB.COD_TIPO_PUBB = NVL(p_cod_tipo_pubb,CD_PRODOTTO_PUBB.COD_TIPO_PUBB) 
            AND    UPPER(CD_PRODOTTO_PUBB.DESC_PRODOTTO) LIKE UPPER('%'||NVL(p_desc_prodotto,CD_PRODOTTO_PUBB.DESC_PRODOTTO)||'%')
			AND    v_si_singolo = NVL(p_singolo, v_si_singolo)  
            UNION
            --TUTTI I GRUPPI
            SELECT DISTINCT CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB,
                   CD_PRODOTTO_PUBB.DESC_PRODOTTO DESC_PRODOTTO,
            	   (SELECT DISTINCT VENPC.PC_CATEGORIA_PRODOTTO.DESCRIZIONE
                               FROM VENPC.PC_CATEGORIA_PRODOTTO
                              WHERE VENPC.PC_CATEGORIA_PRODOTTO.COD = CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO) CATEGORIA_PRODOTTO, 
            	   (SELECT DISTINCT VENPC.PC_TIPI_PUBBLICITA.DES_TIPO_PUBB
                               FROM VENPC.PC_TIPI_PUBBLICITA
                              WHERE VENPC.PC_TIPI_PUBBLICITA.COD_TIPO_PUBB = CD_TIPO_PUBB_GRUPPO.COD_TIPO_PUBB) TIPO_PUBB, 
                   (SELECT CD_LUOGO.DESC_LUOGO
                      FROM CD_LUOGO
                     WHERE CD_LUOGO.ID_LUOGO = CD_LUOGO_TIPO_PUBB.ID_LUOGO) UBICAZIONE_AMBITO,
                   (SELECT CD_UNITA_MISURA_TEMP.DESC_UNITA
                      FROM CD_UNITA_MISURA_TEMP
                     WHERE CD_UNITA_MISURA_TEMP.ID_UNITA = CD_MISURA_PRD_VENDITA.ID_UNITA) PERIODO_VENDITA,
                   v_no_singolo SINGOLO	
            FROM   CD_PRODOTTO_PUBB,CD_TIPO_PUBB_GRUPPO, CD_MISURA_PRD_VENDITA, CD_LUOGO_TIPO_PUBB
            WHERE  CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB = CD_MISURA_PRD_VENDITA.ID_PRODOTTO_PUBB
            AND    CD_LUOGO_TIPO_PUBB.COD_TIPO_PUBB = CD_TIPO_PUBB_GRUPPO.COD_TIPO_PUBB
            --AND    CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB IS NOT NULL
            AND    CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB=CD_TIPO_PUBB_GRUPPO.ID_GRUPPO_TIPI_PUBB
            AND    CD_LUOGO_TIPO_PUBB.ID_LUOGO= NVL(p_id_luogo,CD_LUOGO_TIPO_PUBB.ID_LUOGO)
			AND    CD_MISURA_PRD_VENDITA.ID_UNITA= NVL(p_id_unita,CD_MISURA_PRD_VENDITA.ID_UNITA)
			AND    CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO=NVL(p_cod_categoria_prodotto,CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO)
            AND    CD_TIPO_PUBB_GRUPPO.COD_TIPO_PUBB = NVL(p_cod_tipo_pubb,CD_TIPO_PUBB_GRUPPO.COD_TIPO_PUBB) 
            AND    CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB = NVL(p_gruppo_tipi_pubb,CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB)
			AND    upper(CD_PRODOTTO_PUBB.DESC_PRODOTTO) LIKE upper('%'||NVL(p_desc_prodotto,CD_PRODOTTO_PUBB.DESC_PRODOTTO)||'%')
			AND    v_no_singolo = NVL(p_singolo, v_no_singolo)
            ORDER BY ID_PRODOTTO_PUBB, SINGOLO, CATEGORIA_PRODOTTO, DESC_PRODOTTO, TIPO_PUBB, UBICAZIONE_AMBITO, PERIODO_VENDITA;
    RETURN c_prodotto_pubb_return;    
    EXCEPTION  
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20017, 'FUNZIONE FU_CERCA_PRODOTTO_PUBB: SI E'' VERIFICATO UN ERRORE');
END FU_CERCA_PRODOTTO_PUBB;   
-----------------------------------------------------------------------------------------------------
-- Function FU_RISOLVI_CAT_PROD_PUBB
-- INPUT:  Codice della categoria prodotto da recuperare nella tabella comune PC_CATEGOIRA_PRODOTTO
-- OUTPUT: la descrizione relativa al codice categoria prodotto passato come parametro 
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE  
-------------------------------------------------------------------------------------------------
FUNCTION FU_RISOLVI_CAT_PROD_PUBB(p_cod_categoria IN CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE)
            RETURN VARCHAR2
IS                 
    v_return_value VENPC.PC_CATEGORIA_PRODOTTO.DESCRIZIONE%TYPE;
BEGIN 
    IF(p_cod_categoria IS NOT NULL)THEN
        SELECT VENPC.PC_CATEGORIA_PRODOTTO.DESCRIZIONE
    	INTO   v_return_value 
        FROM   VENPC.PC_CATEGORIA_PRODOTTO
        WHERE  VENPC.PC_CATEGORIA_PRODOTTO.COD = p_cod_categoria;
	ELSE
	    v_return_value:=' ';
	END IF;	
	RETURN v_return_value;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20017, 'Function FU_RISOLVI_CAT_PROD_PUBB: Impossibile recuperare la descrizione prodotto pubblicitario');
		RETURN ' ';
END; 			
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RISOLVI_TIPO_PUBB      
-- INPUT:  Codice del tipo di pubblicita' da recuperare nella tabella comune PC_TIPI_PUBBLICITA'
-- OUTPUT: la descrizione relativa al tipo di pubblicita' passato come parametro 
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE  
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RISOLVI_TIPO_PUBB(p_cod_tipo_pubb IN CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE)
            RETURN VARCHAR2 
IS
    v_return_value VENPC.PC_TIPI_PUBBLICITA.DES_TIPO_PUBB%TYPE;
BEGIN
    IF(p_cod_tipo_pubb IS NOT NULL)THEN
        SELECT VENPC.PC_TIPI_PUBBLICITA.DES_TIPO_PUBB
    	INTO   v_return_value
    	FROM   VENPC.PC_TIPI_PUBBLICITA
    	WHERE  VENPC.PC_TIPI_PUBBLICITA.COD_TIPO_PUBB = p_cod_tipo_pubb;
	ELSE
	    v_return_value:=' ';
	END IF;
	RETURN v_return_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20017, 'Function FU_RISOLVI_TIPO_PUBB: Impossibile recuperare la descrizione del tipo di pubblicita''');
	RETURN ' ';
END;			
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GRUPPO_TIPI_PUBB   
-- DESCRIZIONE:  la funzione si occupa di estrarre i tipi di pubbicita' di gruppo
-- INPUT:  
-- OUTPUT: cursore che contiene i records 
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE  
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GRUPPO_TIPI_PUBB 
            RETURN C_GRUPPO_TIPI_PUBB
IS
    c_v_return_value C_GRUPPO_TIPI_PUBB;
BEGIN
    OPEN c_v_return_value
      FOR 
        SELECT ID_GRUPPO_TIPI_PUBB, DESC_GRUPPO
        FROM   CD_GRUPPO_TIPI_PUBB;
	RETURN c_v_return_value;    
EXCEPTION  
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20017, 'FUNZIONE FU_GRUPPO_TIPI_PUBB: SI E'' VERIFICATO UN ERRORE');
END ;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CATEGORIA_PRODOTTO      
-- DESCRIZIONE:  la funzione si occupa di estrarre le categorie di prodotto
-- INPUT:  
-- OUTPUT: cursore che contiene i records 
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE  
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CATEGORIA_PRODOTTO 
            RETURN C_CATEGORIA_PRODOTTO
IS
    c_v_return_value C_CATEGORIA_PRODOTTO;
BEGIN
OPEN c_v_return_value
    FOR 
       SELECT VENPC.PC_CATEGORIA_PRODOTTO.COD, VENPC.PC_CATEGORIA_PRODOTTO.DESCRIZIONE
       FROM   VENPC.PC_CATEGORIA_PRODOTTO
       WHERE  COD = 'ISP' Or COD='TAB';
	RETURN c_v_return_value;    
EXCEPTION  
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20017, 'FUNZIONE FU_CATEGORIA_PRODOTTO: SI E'' VERIFICATO UN ERRORE');
END ;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_UNITA_MISURA_TEMP      
-- DESCRIZIONE:  la funzione si occupa di estrarre le misure temporali (i tagli)
-- INPUT:  
-- OUTPUT: cursore che contiene i records 
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_UNITA_MISURA_TEMP 
            RETURN C_UNITA_MISURA_TEMP
IS
    c_v_return_value C_UNITA_MISURA_TEMP;
BEGIN
OPEN c_v_return_value
     FOR 
        SELECT CD_UNITA_MISURA_TEMP.ID_UNITA, CD_UNITA_MISURA_TEMP.DESC_UNITA
        FROM   CD_UNITA_MISURA_TEMP;
	RETURN c_v_return_value;    
EXCEPTION  
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20017, 'FUNZIONE FU_UNITA_MISURA_TEMP: SI E'' VERIFICATO UN ERRORE');
END ;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_TIPI_PUBBLICITA      
-- DESCRIZIONE:  la funzione si occupa di estrarre i tipi di pubblicita'
-- INPUT:  
-- OUTPUT: cursore che contiene i records 
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_TIPI_PUBBLICITA 
            RETURN C_TIPI_PUBBLICITA
IS
    c_v_return_value C_TIPI_PUBBLICITA;
BEGIN
    OPEN c_v_return_value
      FOR 
         SELECT VENPC.PC_TIPI_PUBBLICITA.COD_TIPO_PUBB, VENPC.PC_TIPI_PUBBLICITA.COD_PRODOTTO, 
		        VENPC.PC_TIPI_PUBBLICITA.DES_TIPO_PUBB
          FROM  VENPC.PC_TIPI_PUBBLICITA;
	RETURN c_v_return_value;    
EXCEPTION  
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20017, 'FUNZIONE FU_TIPI_PUBBLICITA: SI E'' VERIFICATO UN ERRORE');
END ;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_LUOGO      
-- DESCRIZIONE:  la funzione si occupa di estrarre i tipi ambiti in cui si puo' vendere pubblicita'
-- INPUT:  
-- OUTPUT: cursore che contiene i records 
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
--
-- MODIFICHE 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_LUOGO 
            RETURN C_LUOGO
IS
    c_v_return_value C_LUOGO;
BEGIN
    OPEN c_v_return_value
      FOR 
         SELECT  CD_LUOGO.ID_LUOGO, CD_LUOGO.DESC_LUOGO
         FROM    CD_LUOGO;
	RETURN c_v_return_value;    
EXCEPTION  
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20017, 'FUNZIONE FU_LUOGO: SI E'' VERIFICATO UN ERRORE');
END ;
END PA_CD_PRODOTTO_PUBB; 
/

