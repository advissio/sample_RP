CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_MAGGIORAZIONE IS

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_MAGGIORAZIONE
--
-- DESCRIZIONE:  Esegue l'inserimento di una nuova maggiorazione nel sistema
--
-- OPERAZIONI:
--   1) Memorizza la maggiorazione (CD_MAGGIORAZIONE)
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_MAGGIORAZIONE(   p_descrizione                  CD_MAGGIORAZIONE.DESCRIZIONE%TYPE,
                                        p_id_tipo_magg                 CD_MAGGIORAZIONE.ID_TIPO_MAGG%TYPE,
                                        p_percentuale_variazione       CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE%TYPE,
                                        p_esito				           OUT NUMBER)
IS

BEGIN -- PR_INSERISCI_MAGGIORAZIONE
--

p_esito 	:= 1;
--P_ID_MAGGIORAZIONE := MAGGIORAZIONE_SEQ.NEXTVAL;

	 --
  		SAVEPOINT ann_ins;
  	--
    	   -- EFFETTUO L'INSERIMENTO

       INSERT INTO CD_MAGGIORAZIONE
	     (DESCRIZIONE,
          ID_TIPO_MAGG,
          PERCENTUALE_VARIAZIONE--,
	      --utemod,
	      --datamod
	     )
	   VALUES
	     (p_descrizione,
          p_id_tipo_magg,
          p_percentuale_variazione--,
		  --user,
		  --FU_DATA_ORA
		  );
	   --


	EXCEPTION  -- SE VIENE LANCIATA L'ECCEZIONE EFFETTUA UNA ROLLBACK FINO AL SAVEPOINT INDICATO
		WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20004, 'Procedura PR_INSERISCI_MAGGIORAZIONE: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_MAGGIORAZIONE(  p_descrizione,
                                                                                                                                                                      p_id_tipo_magg,
                                                                                                                                                                      p_percentuale_variazione));
		ROLLBACK TO ann_ins;

END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_MAGGIORAZIONE
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di una maggiorazione dal sistema
--
-- OPERAZIONI:
--   3) Elimina la maggiorazione
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_MAGGIORAZIONE(  p_id_maggiorazione		IN CD_MAGGIORAZIONE.ID_MAGGIORAZIONE%TYPE,
							         p_esito			    OUT NUMBER)
IS

--
BEGIN -- PR_ELIMINA_MAGGIORAZIONE
--

p_esito 	:= 1;

	 --
  		SAVEPOINT ann_del;

	   -- EFFETTUA L'ELIMINAZIONE
	   DELETE FROM CD_MAGGIORAZIONE
	   WHERE ID_MAGGIORAZIONE = p_id_maggiorazione;
	   --

	p_esito := SQL%ROWCOUNT;

  EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20004, 'Procedura PR_ELIMINA_MAGGIORAZIONE: Delete non eseguita, verificare la coerenza dei parametri');
		ROLLBACK TO ann_del;

END;

 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_MAGGIORAZIONE
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_STAMPA_MAGGIORAZIONE(  p_descrizione                  CD_MAGGIORAZIONE.DESCRIZIONE%TYPE,
                                   p_id_tipo_magg                 CD_MAGGIORAZIONE.ID_TIPO_MAGG%TYPE,
                                   p_percentuale_variazione       CD_MAGGIORAZIONE.PERCENTUALE_VARIAZIONE%TYPE
                                   )  RETURN VARCHAR2
IS

BEGIN

IF v_stampa_maggiorazione = 'ON'

    THEN

     RETURN 'DESCRIZIONE: '          || p_descrizione           || ', ' ||
            'ID_TIPO_MAGG: '          || p_id_tipo_magg            || ', ' ||
            'PERCENTUALE_VARIAZIONE: '|| p_percentuale_variazione;

END IF;

END  FU_STAMPA_MAGGIORAZIONE;


END PA_CD_MAGGIORAZIONE;
/

