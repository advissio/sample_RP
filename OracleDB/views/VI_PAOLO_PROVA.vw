CREATE OR REPLACE FORCE VIEW VENCD.VI_PAOLO_PROVA
(ID_PIANO, ID_VER_PIANO)
AS 
SELECT

/*Paolo Enrico, Altran Italia, marzo 2010 

Esempio dell'uso delle TABLE FUNCTION in una sezione dell'applicazione.

*/

 

ID_PIANO,

id_ver_piano

FROM TABLE  (PAOLO_PROVA.FU_ELENCO_PIANI(PAOLO_PROVA.FU_DATA_DA,PAOLO_PROVA.FU_DATA_A))
/



