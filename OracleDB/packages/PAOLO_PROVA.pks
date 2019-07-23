CREATE OR REPLACE PACKAGE VENCD.PAOLO_PROVA  IS
--
/*Paolo Enrico, Altran Italia, marzo 2010 
Esempio dell'uso delle TABLE FUNCTION in una sezione dell'applicazione.

*/
--
TYPE RESULT_SET iS RECORD
(
  id_piano NUMBER(7),
    ID_VER_PIANO NUMBER(2)
    );

type C_RESULT_SET is table of RESULT_SET;
--

FUNCTION fu_elenco_piani (p_data_inizio in date,P_DATA_FINE in date)  RETURN C_RESULT_SET pipelined;
--
--
function fu_data_da return date;
function fu_data_a return date;




END PAOLO_PROVA; 
/

