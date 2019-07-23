CREATE OR REPLACE PROCEDURE VENCD.PR_ESTRAZ_COMUNICATI(p_cod_sogg      CD_SOGGETTO_DI_PIANO.COD_SOGG%TYPE,
                                                 p_id_tipo_break CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                                 p_durata        CD_COEFF_CINEMA.DURATA%TYPE) IS
tmpVar NUMBER;

c_lista_comunicati PA_CD_COMPONI_SCHERMI.C_ID_COMUNICATI;

/******************************************************************************
   NAME:       PR_ESTRAZ_COMUNICATI
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/12/2009          1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     PR_ESTRAZ_COMUNICATI
      Sysdate:         11/12/2009
      Date and Time:   11/12/2009, 11:28:02, and 11/12/2009 11:28:02
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpVar := 0;
   OPEN c_lista_comunicati
     FOR 
        SELECT  COM.ID_COMUNICATO
        FROM    CD_COMUNICATO COM, CD_SOGGETTO_DI_PIANO SDP, CD_TIPO_BREAK TBK, CD_BREAK BRK,
                CD_CIRCUITO_BREAK CIR_BRK, CD_BREAK_VENDITA BRK_VEN, CD_COEFF_CINEMA COEFF,
                CD_FORMATO_ACQUISTABILE FORM_ACQ, CD_PRODOTTO_ACQUISTATO PROD               
        WHERE   COM.ID_SOGGETTO_DI_PIANO = SDP.ID_SOGGETTO_DI_PIANO
        AND     p_cod_sogg = SDP.COD_SOGG
        AND     p_id_tipo_break = TBK.ID_TIPO_BREAK
        AND     TBK.ID_TIPO_BREAK = BRK.ID_TIPO_BREAK
        AND     BRK.ID_BREAK = CIR_BRK.ID_BREAK
        AND     CIR_BRK.ID_CIRCUITO_BREAK = BRK_VEN.ID_CIRCUITO_BREAK
        AND     BRK_VEN.ID_BREAK_VENDITA = COM.ID_BREAK_VENDITA
        AND     p_durata = COEFF.DURATA
        AND     COEFF.ID_COEFF = FORM_ACQ.ID_COEFF
        AND     FORM_ACQ.ID_FORMATO = PROD.ID_FORMATO
        AND     PROD.ID_PRODOTTO_ACQUISTATO = COM.ID_PRODOTTO_ACQUISTATO
        AND     PROD.STATO_DI_VENDITA = 'PRE';
        
       IF c_lista_comunicati IS NOT NULL AND c_lista_comunicati.COUNT > 0 THEN
            FOR i IN 1..c_lista_comunicati.COUNT LOOP
                EXIT;
            END LOOP;
       END IF;
        
 --  RETURN c_lista_comunicati;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END PR_ESTRAZ_COMUNICATI; 
/

