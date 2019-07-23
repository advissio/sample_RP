CREATE OR REPLACE PACKAGE VENCD.PA_CD_SICUREZZA AS
/******************************************************************************
   NAME:       PA_CD_SICUREZZA
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        07/10/2009  Mauro Viel Altran          1. Created this package.
                                                     2. contiene tutte le funzioni nessarie per la verifica della sicurezza

******************************************************************************/

TYPE R_ABILITAZIONE IS RECORD
(
   A_NOME_FUNZIONE VARCHAR2(30),
   A_ABITATO CHAR(1)
);

TYPE C_ABILITAZIONE IS REF CURSOR RETURN R_ABILITAZIONE;

FUNCTION FU_VERIFICA_FUNZIONI(P_CODICI_FUNZIONI VARCHAR2,P_TIPO_FUNZIONE VARCHAR2) RETURN VARCHAR2;

FUNCTION FU_VERIFICA_FUNZIONE(P_CODICE_FUNZIONE VARCHAR2,P_TIPO_FUNZIONE VARCHAR2) RETURN VARCHAR2;

FUNCTION FU_VERIFICA_FUNZIONE(P_NOME_FUNZIONE VARCHAR2, P_CODICE_FUNZIONE VARCHAR2,P_TIPO_FUNZIONE VARCHAR2) RETURN VARCHAR2;

END PA_CD_SICUREZZA;
/

