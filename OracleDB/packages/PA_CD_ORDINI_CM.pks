CREATE OR REPLACE PACKAGE VENCD.PA_CD_ORDINI_CM IS
--
Procedure ESTRAI_DATI 
  (P_DATA_INIZIO   in date,
   P_DATA_FINE     in date,
   P_ESITO         out number,
   P_DES_ESITO     out varchar2 );
--
Function FU_COND_PAG
  (P_COD_PIANO in number,
   P_VERS_PIANO in number,
   P_PRG_ORDINE in number ) return varchar2;
--
END; 
/

