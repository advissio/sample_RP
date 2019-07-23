CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SUPPORTO_VENDITE IS
/* -----------------------------------------------------------------------------------------------------------

   Descrizione: Package di interfaccia con il Supporto Vendite

----------------------------------------------------------------------------------------------------------- */
--
--
-- Variabili di package
DATA_INIZIO DATE := null;
DATA_FINE   DATE := null;
--
--
-----------------------------------------------------------------------------------------------------------
-- Procedura: IMPOSTA_PARAMETRI
--
-- Input: valori DATA_INIZIO e DATA_FINE da assegnare alle variabili di package.
--
-- Realizzatore:
--	 luigi cipolla, 30/12/2009
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
procedure IMPOSTA_PARAMETRI(p_data_inizio DATE,
                             p_data_fine DATE)
is
begin
  DATA_INIZIO := p_data_inizio;
  DATA_FINE   := p_data_fine;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_DATA_INIZIO
--
-- Output: variabile di package DATA_INIZIO
--
-- Realizzatore:
--	 luigi cipolla, 30/12/2009
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_DATA_INIZIO RETURN DATE
is
begin
  return DATA_INIZIO;
end;
-----------------------------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------------------------
-- Funzione: FU_DATA_FINE
--
-- Output: variabile di package DATA_FINE
--
-- Realizzatore:
--	 luigi cipolla, 30/12/2009
--
-- Modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_DATA_FINE RETURN DATE
is
begin
  return DATA_FINE;
end;
-----------------------------------------------------------------------------------------------------------
--
END PA_CD_SUPPORTO_VENDITE;
/

