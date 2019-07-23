CREATE OR REPLACE FUNCTION VENCD.FU_CD_GET_DGC_TC(P_DGC cd_prodotto_acquistato.dgc%type, p_tipo_contratto cd_importi_prodotto.tipo_contratto%type) RETURN varchar2 IS
/******************************************************************************
   NAME:       FU_GET_DGC_TC
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        07/01/2010   Mauro Viel       1. Created this function.

   NOTES:

   Funzione che determina il DGC_TC per mezzo di una chimata al portafoglio.

******************************************************************************/
V_RET NUMBER := 0;
V_DGC_TC_ID CD_IMPORTI_PRODOTTO.DGC_TC_ID%TYPE;
BEGIN
		V_RET:=PA_PC_PORTAFOGLIO.fu_get_det_gest_com_tp_cntr(P_DGC,p_tipo_contratto ,V_DGC_TC_ID);
        --V_RET:=PA_PC_PORTAFOGLIO.fu_get_det_gest_com_tp_cntr('C01','C' ,V_DGC_TC_ID);
		RETURN V_DGC_TC_ID;
	END;
/

