CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_FATTURAZIONE Is
-----------------------------------------------------------------------------------------------------
-- DESCRIZIONE: package di procedure e funzioni utilizzate per la realizzazione dell'interfaccia
--              tra ambiente Cinema Digitale e Fatturazione.
--
-- REALIZZATORE: Luigi Cipolla, 05/01/2010
-----------------------------------------------------------------------------------------------------
--
--
-- Variabili di package
tipo_estrazione			varchar2(2);
data_inizio				date;
data_fine				date;
data_stato_cont_inizio	date;
id_piano	 			number;
id_ver_piano 			number;
cod_prg_ordine	 		number;
cod_categoria_prodotto  cd_pianificazione.cod_categoria_prodotto%type;
--
--
Function FU_TIPO_ESTRAZIONE     	 Return varchar2
is
BEGIN
  Return tipo_estrazione;
END;

Function FU_DATA_INIZIO      		 Return date
is
BEGIN
  Return data_inizio;
END;
--
Function FU_DATA_FINE		  		 Return date
is
BEGIN
  Return data_fine;
END;
--
Function FU_DATA_STATO_CONT_INIZIO Return date
is
BEGIN
  Return data_stato_cont_inizio;
END;
--
Function FU_ID_PIANO   	   		 Return number
is
BEGIN
  Return id_piano;
END;
--
Function FU_ID_VER_PIANO   		 Return number
is
BEGIN
  Return id_ver_piano;
END;
--
Function FU_COD_PRG_ORDINE   		 Return number
is
BEGIN
  Return cod_prg_ordine;
END;
--
Function FU_CATEGORIA_PRODOTTO      Return varchar2
is
BEGIN
  Return cod_categoria_prodotto;
END;
--
--
-----------------------------------------------------------------------------------------------------------
-- Procedura: PR_SET_PARAMETRI
--
-- Input: valori da assegnare alle variabili di package, utilizzati nella vista parametrica.
--		il parametro p_cod_categoria_prodotto	puo' assumere i valori NULL,'TAB','ISP'.
--
-- Realizzatore:
--	 luigi cipolla, 05/01/2010
--
-- Modifiche:
--   Luigi Cipolla - 18/10/2011 
--     Aggiunto il parametro cod_categoria_prodotto.
-----------------------------------------------------------------------------------------------------
Procedure PR_SET_PARAMETRI ( p_tipo_estrazione			in      varchar2,
                              p_data_inizio				in		date,
	                          p_data_fine				in		date,
							  p_data_stato_cont_inizio	in		date,
							  p_id_piano 				in		number,
							  p_id_ver_piano			in		number,
							  p_cod_prg_ordine			in		number,
							  p_cod_categoria_prodotto	in      varchar2 )
is
BEGIN
  tipo_estrazione		:= p_tipo_estrazione;
  data_inizio 			:= p_data_inizio;
  data_fine  			:= p_data_fine;
  data_stato_cont_inizio:= p_data_stato_cont_inizio;
  id_piano				:= p_id_piano;
  id_ver_piano			:= p_id_ver_piano;
  cod_prg_ordine		:= p_cod_prg_ordine;
  cod_categoria_prodotto:= p_cod_categoria_prodotto;
END;
-----------------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------------
-- Funzione FU_SET_STATO_CONT
--
-- Descrizione: Modifica stato contabile
--
-- Regole: Le transazioni consentite sono:
--		   DAT --> TRA
--		   TRA --> DAR
--		   DAR --> TRA
--
-- Input: 1)chiave dell'importo di fatturazione
--  	  2)nuovo stato contabile
--
-- Esito: 0  --> importo di fatturazione non trovato o transazione non consentita (nessuna modifica)
--	      1  --> modifica effettuata
--	     -1  --> errore generico
--
-- Modifiche:
--   Luigi Cipolla
--     Consentire la modifica di stato in caso di uguaglianza tra valore OLD e NEW.
--
-----------------------------------------------------------------------------------------------------
Function FU_SET_STATO_CONT ( p_id_importi_fatturazione in number,
   					          p_stato_fatt		        in varchar2 )
  return number
is
BEGIN
  if p_stato_fatt IN ('DAR', 'TRA') then
    BEGIN
      update cd_importi_fatturazione
      set STATO_FATTURAZIONE = p_stato_fatt
      where id_importi_fatturazione = p_id_importi_fatturazione
        and (   (STATO_FATTURAZIONE = 'DAT' and p_stato_fatt = 'TRA')
             or (STATO_FATTURAZIONE = 'TRA' and p_stato_fatt = 'DAR')
  	         or (STATO_FATTURAZIONE = 'DAR' and p_stato_fatt = 'TRA')
  	         or (STATO_FATTURAZIONE = p_stato_fatt)
  		     );
  	    if SQL%ROWCOUNT = 0 then
          return 0;
        else
          return 1;
        end if;
      EXCEPTION
        when others then
          return -1;
      END;
  else
  	return 0;
  end if;
END;
-----------------------------------------------------------------------------------------------------
--
End PA_CD_FATTURAZIONE;
/

