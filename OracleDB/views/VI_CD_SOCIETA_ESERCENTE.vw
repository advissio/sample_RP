CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SOCIETA_ESERCENTE
(COD_ESERCENTE, RAGIONE_SOCIALE, INDIRIZZO, CAP, COMUNE, 
 PROVINCIA, PART_IVA, DATA_INIZIO_VALIDITA, DATA_FINE_VALIDITA, DATAMOD)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_SOCIETA_ESERCENTE
--
-- ESTRAE LA LISTA DEGLI ESERCENTI DEFINITI ALL'INTERNO DELL'ANAGRAFICA SIPRA
--
-- REALIZZATORE: ANTONIO COLUCCI, TEORESI S.R.L. 12/02/2010
--
-- MODIFICHE:
--   Antonio Colucci, Teoresi s.r.l. 03/03/2010
--     Aggiunto filtro sulla data di fine validit? dell'esercente
--
--   Mauro Viel Altran Italia s.p.a 31/03/2010
--     Aggiunta colonna rappresentante_legale
--     Nota : alcuni esercenti hanno 2 rappresentanti legali. Probabilmente si creera una nuova vista.
--   Luigi Cipolla, 14/04/2010
--     Revisione
-----------------------------------------------------------------------------------------------------
	INT_LC.COD_INTERL AS COD_ESERCENTE,
	INT_LC.RAG_SOC_COGN AS RAGIONE_SOCIALE,
	INT_LC.INDIRIZZO||' '||INT_LC.NUM_CIVICO AS INDIRIZZO,
	INT_LC.CAP,
	INT_LC.LOCALITA AS COMUNE,
	INT_LC.PROVINCIA,INT_LC.PART_IVA,
	INT_LC.DT_INIZ_VAL DATA_INIZIO_VALIDITA,
	INT_LC.DT_FINE_VAL DATA_FINE_VALIDITA,
	INT_LC.DATAMOD--,
	--null RESPONSABILE_LEGALE
FROM 
     INTERL_U INT_LC
WHERE INT_LC.COD_INTERL_TIPO = 'LC'
/



