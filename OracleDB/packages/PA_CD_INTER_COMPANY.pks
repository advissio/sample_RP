CREATE OR REPLACE PACKAGE VENCD.PA_CD_INTER_COMPANY AS
/******************************************************************************
   NAME:       PA_CD_INTER_COMPANY
   PURPOSE:

   REVISIONS:
   Ver        Date        Author                    Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/03/2010    Mauro Viel Altran         1. Created this package.
******************************************************************************/
/*  Procedura PR_CREA_PLAYLIST_CSV Autore Mauro Viel Altran Italia Marzo 2010*/
/* Modifiche Luigi Cipolla  22 Marzo 2010 modificata query d'estrazione play list*/

V_PATH VARCHAR2(40) := 'CSV_INTER'; 
  
PROCEDURE PR_CREA_PLAYLIST_CSV(P_DATA_INIZIO CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, P_DATA_FINE CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, P_ESITO OUT NUMBER);


END PA_CD_INTER_COMPANY; 
/

