CREATE OR REPLACE PACKAGE VENCD.PA_CD_FATTURAZIONE Is
-----------------------------------------------------------------------------------------------------
-- DESCRIZIONE: package di procedure e funzioni utilizzate per la realizzazione dell'interfaccia
--              tra ambiente Cinema Digitale e Fatturazione.
--
-- REALIZZATORE: Luigi Cipolla, 05/01/2010
-----------------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------------
Procedure PR_SET_PARAMETRI ( p_tipo_estrazione			in      varchar2,
                              p_data_inizio				in		date,
	                          p_data_fine				in		date,
							  p_data_stato_cont_inizio	in		date,
							  p_id_piano 				in		number,
							  p_id_ver_piano			in		number,
							  p_cod_prg_ordine			in		number,
							  p_cod_categoria_prodotto	in      varchar2 default null );
--
Function FU_SET_STATO_CONT ( p_id_importi_fatturazione in number,
   					          p_stato_fatt		        in varchar2 )
  return number;
--
Function FU_TIPO_ESTRAZIONE     	 Return varchar2;
Function FU_DATA_INIZIO      		 Return date;
Function FU_DATA_FINE		  		 Return date;
Function FU_DATA_STATO_CONT_INIZIO  Return date;
Function FU_ID_PIANO   	   		 Return number;
Function FU_ID_VER_PIANO   		 Return number;
Function FU_COD_PRG_ORDINE   		 Return number;
Function FU_CATEGORIA_PRODOTTO      Return varchar2;
-----------------------------------------------------------------------------------------------------
End;
/

