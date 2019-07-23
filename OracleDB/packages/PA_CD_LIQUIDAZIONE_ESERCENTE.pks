CREATE OR REPLACE PACKAGE VENCD.pa_cd_liquidazione_esercente AS
/******************************************************************************
   NAME:       pa_cd_liquidazione_esercente
   PURPOSE:    package contenenete la procedura PR_MODIFICA_STATO_LIQUIDAZIONE 
               che consente la modifica dello stato di lavorazioen di una quota esercente.
               
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22/04/2010  Mauro Viel Aprile  Altran 2010           
******************************************************************************/

 
PROCEDURE PR_MODIFICA_STATO_LIQUIDAZIONE(P_ID_QUOTA_ESERCENTE IN CD_QUOTA_ESERCENTE.ID_QUOTA_ESERCENTE%TYPE,  P_ESITO OUT NUMBER);

END pa_cd_liquidazione_esercente; 
/

