CREATE OR REPLACE PACKAGE VENCD.PA_CD_PRODOTTO_PUBB AS

-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la visualizzazione 
--              dei prodotti pubblicitari
-- --------------------------------------------------------------------------------------------
-- FUNCTION  
--    FU_CERCA_PRODOTTO_PUBB        Function per la ricerca dei prodotti pubblicitari   
-- --------------------------------------------------------------------------------------------
-- FUNCTION  
--    FUNCTION FU_RISOLVI_CAT_PROD_PUBB    Function per il recupero di categoria prodotto pubb   
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009 
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: 
-- --------------------------------------------------------------------------------------------

TYPE R_PRODOTTO_PUBB IS RECORD 
(
    a_id_prodotto_pubb          CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
    a_desc_prodotto               CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    a_categoria_prodotto        VENPC.PC_CATEGORIA_PRODOTTO.DESCRIZIONE%TYPE,
    a_tipo_pubb                 VENPC.PC_TIPI_PUBBLICITA.DES_TIPO_PUBB%TYPE,
    a_ubicazione_ambito         CD_LUOGO.DESC_LUOGO%TYPE,
	a_periodo_vendita           CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
	a_flg_singolo               VARCHAR2(2) 
);
TYPE C_PRODOTTO_PUBB IS REF CURSOR RETURN R_PRODOTTO_PUBB;

TYPE R_CATEGORIA_PRODOTTO IS RECORD 
(
    a_cod           VENPC.PC_CATEGORIA_PRODOTTO.COD%TYPE,
	a_descrizione   VENPC.PC_CATEGORIA_PRODOTTO.DESCRIZIONE%TYPE
);
TYPE C_CATEGORIA_PRODOTTO IS REF CURSOR RETURN R_CATEGORIA_PRODOTTO;

TYPE R_GRUPPO_TIPI_PUBB IS RECORD 
(
    a_id_gruppo_tipi_pubb       CD_GRUPPO_TIPI_PUBB.ID_GRUPPO_TIPI_PUBB%TYPE,
	a_desc_gruppo               CD_GRUPPO_TIPI_PUBB.DESC_GRUPPO%TYPE
);
TYPE C_GRUPPO_TIPI_PUBB IS REF CURSOR RETURN R_GRUPPO_TIPI_PUBB;

TYPE R_UNITA_MISURA_TEMP IS RECORD 
(
    a_id_unita      CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
	a_desc_unita    CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE
);
TYPE C_UNITA_MISURA_TEMP IS REF CURSOR RETURN R_UNITA_MISURA_TEMP;

TYPE R_TIPI_PUBBLICITA IS RECORD 
(
    a_cod_tipo_pubb     VENPC.PC_TIPI_PUBBLICITA.COD_TIPO_PUBB%TYPE,
	a_cod_prodotto      VENPC.PC_TIPI_PUBBLICITA.COD_PRODOTTO%TYPE,
	a_des_tipo_pubb     VENPC.PC_TIPI_PUBBLICITA.DES_TIPO_PUBB%TYPE
);
TYPE C_TIPI_PUBBLICITA IS REF CURSOR RETURN R_TIPI_PUBBLICITA;

TYPE R_LUOGO IS RECORD 
(
    a_id_luogo      CD_LUOGO.ID_LUOGO%TYPE,
	a_desc_luogo    CD_LUOGO.DESC_LUOGO%TYPE
);
TYPE C_LUOGO IS REF CURSOR RETURN R_LUOGO;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_PRODOTTO_PUBB      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PRODOTTO_PUBB(p_desc_prodotto                 CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
                                p_id_luogo                      CD_LUOGO.ID_LUOGO%TYPE,
								p_id_unita                      CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
								p_cod_categoria_prodotto        CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE,
                                p_cod_tipo_pubb                 CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE,
                                p_gruppo_tipi_pubb              CD_PRODOTTO_PUBB.ID_GRUPPO_TIPI_PUBB%TYPE,
								p_singolo                       VARCHAR2)
                                RETURN C_PRODOTTO_PUBB; 

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RISOLVI_CAT_PROD_PUBB      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RISOLVI_CAT_PROD_PUBB(p_cod_categoria IN CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%TYPE)
            RETURN VARCHAR2; 

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RISOLVI_TIPO_PUBB      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RISOLVI_TIPO_PUBB(p_cod_tipo_pubb IN CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE)
            RETURN VARCHAR2; 
			
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_MISURA_PRD_VENDITA      
-- --------------------------------------------------------------------------------------------
--FUNCTION FU_CERCA_MISURA_PRD_VENDITA(a_misura_prd_vendita   CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE, 
--                                        CD_UNITA_MISURA_TEMP.DESC_UNITA, 
--                                        CD_PRODOTTO_PUBB.DESC_PRODOTTO)
--                                RETURN C_PRODOTTO_PUBB; 

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GRUPPO_TIPI_PUBB      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GRUPPO_TIPI_PUBB 
            RETURN C_GRUPPO_TIPI_PUBB;
			
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CATEGORIA_PRODOTTO      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CATEGORIA_PRODOTTO 
            RETURN C_CATEGORIA_PRODOTTO;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_UNITA_MISURA_TEMP      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_UNITA_MISURA_TEMP 
            RETURN C_UNITA_MISURA_TEMP;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_TIPI_PUBBLICITA      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_TIPI_PUBBLICITA 
            RETURN C_TIPI_PUBBLICITA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_LUOGO      
-- --------------------------------------------------------------------------------------------
FUNCTION FU_LUOGO 
            RETURN C_LUOGO;

END PA_CD_PRODOTTO_PUBB; 
/

