CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_TRIGGER AS
/******************************************************************************
   NAME:       PA_CD_TRIGGER
   PURPOSE: Consente la abilitazione/disabiltazione della procedura che modifica i parametri utemod datamod

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        16/09/2010  Mauro Viel           1. Created this package body.
******************************************************************************/




V_STATO BOOLEAN :=  TRUE;


PROCEDURE  PR_ABILITA_TRIGGER IS
BEGIN
    V_STATO := TRUE;
END PR_ABILITA_TRIGGER;

PROCEDURE  PR_DISABILITA_TRIGGER IS
BEGIN
    V_STATO := FALSE;
END PR_DISABILITA_TRIGGER;

FUNCTION FU_GET_STATO_TRIGGER RETURN BOOLEAN IS -- TRUE ABILITATO
BEGIN
     RETURN V_STATO;
END FU_GET_STATO_TRIGGER;

END  PA_CD_TRIGGER; 
/

