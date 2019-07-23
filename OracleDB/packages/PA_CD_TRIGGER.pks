CREATE OR REPLACE PACKAGE VENCD.PA_CD_TRIGGER AS
/******************************************************************************
   NAME:       PA_CD_TRIGGER
   PURPOSE: Consente la abilitazione/disabiltazione della procedura che modifica i parametri utemod datamod

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        16/09/2010  Mauro Viel       1. Created this package.
******************************************************************************/


PROCEDURE  PR_ABILITA_TRIGGER;
PROCEDURE  PR_DISABILITA_TRIGGER;
FUNCTION FU_GET_STATO_TRIGGER RETURN BOOLEAN; --TRUE ABILITATO


END PA_CD_TRIGGER; 
/

