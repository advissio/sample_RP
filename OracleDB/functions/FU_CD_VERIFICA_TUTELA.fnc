CREATE OR REPLACE FUNCTION VENCD.FU_CD_VERIFICA_TUTELA(P_ID_CLIENTE_COMM VI_CD_CLIENTE.ID_CLIENTE%TYPE, P_COD_SOGG SOGGETTI.COD_SOGG%TYPE, P_ID_MATERIALE CD_MATERIALE.ID_MATERIALE%TYPE) RETURN CHAR IS
/******************************************************************************
   NAME:       FU_VERIFICA_TUTELA
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/06/2010          1. Created this function.
   NOTES:
   Automatically available Auto Replace Keywords:
      Object Name:     FU_VERIFICA_TUTELA
      Sysdate:         11/06/2010
      Date and Time:   11/06/2010, 11.06.05, and 11/06/2010 11.06.05
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)
   Modifiche Mauro Viel Altran Italia Maggio 2011. Modificata la firma della procedura:  
                    --Sostituito  P_ID_SOGGETTO_DI_PIANO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO  con SOGGETTI.COD_SOGG
                    --Sostituito  P_ID_MATERIALE_DI_PIANO CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE con CD_MATERIALE.ID_MATERIALE

******************************************************************************/
V_FLAG_TUTELA CHAR(1) := 'N';
BEGIN
    IF P_ID_CLIENTE_COMM IS NOT NULL  THEN
       SELECT DECODE (COUNT(1),0,'N','S') INTO V_FLAG_TUTELA
       FROM CD_CLIENTI_SPECIALI
       WHERE ID_CLIENTE = P_ID_CLIENTE_COMM
       AND FLG_ANNULLATO = 'N'; 
    END IF;   
    IF  V_FLAG_TUTELA = 'N' AND  P_COD_SOGG IS NOT NULL THEN
        SELECT DECODE (COUNT(1),0,'N','S') INTO V_FLAG_TUTELA
        FROM SOGGETTI SO,NIELSCAT CAT,NIELSCL CL ,NIELSETT SETT,CD_MERCEOLOGIE_SPECIALI M
        WHERE SO.COD_SOGG = P_COD_SOGG
        AND SO.FLAG_ANN ='N'
        AND CAT.COD_CAT_MERC= SO.NL_NT_COD_CAT_MERC
        AND CL.COD_CL_MERC = SO.NL_COD_CL_MERC
        AND SETT.COD_SETT_MERC = CAT.NS_COD_SETT_MERC
        AND CL.NT_COD_CAT_MERC = CAT.COD_CAT_MERC
        AND DECODE(M.COD_CLASSE,-1,CL.COD_CL_MERC,M.COD_CLASSE) = CL.COD_CL_MERC
        AND DECODE(M.COD_CATEGORIA,-1,CAT.COD_CAT_MERC,M.COD_CATEGORIA) = CAT.COD_CAT_MERC
        AND SETT.COD_SETT_MERC = M.COD_SETTORE
        AND M.FLG_ANNULLATO = 'N';
    END IF;    
    IF   V_FLAG_TUTELA = 'N' AND P_ID_MATERIALE IS NOT NULL THEN
        SELECT MA.FLG_PROTETTO INTO V_FLAG_TUTELA
        FROM  CD_MATERIALE MA
        WHERE MA.ID_MATERIALE = P_ID_MATERIALE;
    END IF;
    RETURN V_FLAG_TUTELA;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
      RAISE;
     WHEN OTHERS THEN
      RAISE;
END FU_CD_VERIFICA_TUTELA; 
/

