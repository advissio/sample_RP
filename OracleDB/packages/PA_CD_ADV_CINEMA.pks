CREATE OR REPLACE PACKAGE VENCD.PA_CD_ADV_CINEMA AS
/******************************************************************************
   NAME:       PA_CD_ADV_CINEMA
   Descrizione: Package creato al fine 
                di ospitare le procedure utili al sistema ADV Cinema 
   
   REVISIONS:
   Ver        Date        Author           
   ---------  ----------  -------------------------------
   1.0        21/10/2009  Antonio Colucci Teoresi s.r.l.
    
******************************************************************************/
--
/******************************************************************************
   Nome: FU_CALCOLA_DATA_SOLARE
   
   Descrizione: Restituisce la data solare relativa ai parametri di input.
                Se l'orario di riferimento 
                Orario 
                 6:00 - 23:59 Data solare = DATA_COMMERCIALE
                24:01 - 29:59 Data solare = DATA_COMMERCIALE + 1
                
   INPUT:       data_commerciale
                ora Sipra
                minuti Sipra

   OUTPUT:      data solare

   REVISIONS:
   Ver        Date        Author           
   ---------  ----------  ----------------------------------------------------
   1.0        21/10/2009  Antonio Colucci Teoresi s.r.l. 
******************************************************************************/
FUNCTION FU_CALCOLA_DATA_SOLARE(p_data_commerciale DATE, 
                                 p_hh NUMBER,
                                 p_mm NUMBER)
RETURN DATE;
-----------------------------------------------------------------------------------------------------------
-- Procedura: IMPOSTA_PARAMETRI
--
-- input: valori DATA_INIZIO e DATA_FINE da assegnare alle variabili di package.
--
-- realizzatore:
--	 luigi cipolla, 26/10/2009
--
-- modifiche:
-----------------------------------------------------------------------------------------------------------
procedure IMPOSTA_PARAMETRI(p_data_inizio DATE, 
                             p_data_fine DATE);
-----------------------------------------------------------------------------------------------------------
-- Procedura: IMPOSTA_SALA
--
-- input: valore ID_SALA da assegnare alle variabili di package.
--
-- realizzatore:
--	 Angelo Marletta, 3/08/2010
--
-- modifiche:
-----------------------------------------------------------------------------------------------------------
procedure IMPOSTA_SALA(p_id_sala CD_SALA.ID_SALA%TYPE);
-----------------------------------------------------------------------------------------------------------
--
--  
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_DATA_INIZIO
--
-- output: variabile di package DATA_INIZIO
--
-- realizzatore:
--	 luigi cipolla, 26/10/2009
--
-- modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_DATA_INIZIO RETURN DATE;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_DATA_FINE
--
-- output: variabile di package DATA_FINE
--
-- realizzatore:
--	 luigi cipolla, 26/10/2009
--
-- modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_DATA_FINE RETURN DATE;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_ID_SALA
--
-- output: variabile di package ID_SALA
--
-- realizzatore:
--	 Angelo Marletta, 3/08/2010
--
-- modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_ID_SALA RETURN CD_SALA.ID_SALA%TYPE;
-----------------------------------------------------------------------------------------------------------
END PA_CD_ADV_CINEMA; 
/

