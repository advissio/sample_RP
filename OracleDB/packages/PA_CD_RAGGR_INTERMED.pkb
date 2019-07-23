CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_RAGGR_INTERMED
IS

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_PRODOTTO_VENDITA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo raggruppamento intermediari nel sistema
--
-- OPERAZIONI:
--   1) Memorizza il raggruppamento intermediari (CD_RAGGRUPPAMENTO_INTERMEDIARI)
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
PROCEDURE PR_INSERISCI_RAGGR_INTERMED(  p_id_ver_piano                          CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
                                        p_id_agenzia                            CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
                                        p_id_centro_media                       CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
                                        --p_id_venditore_prodotto                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_PRODOTTO%TYPE,
                                        p_id_venditore_cliente                  CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
                                        p_id_piano                              CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
                                        p_data_decorrenza                       CD_RAGGRUPPAMENTO_INTERMEDIARI.DATA_DECORRENZA%TYPE,
							   			--p_aliquota_agenzia                      CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_AGENZIA%TYPE,
                                        --p_aliquota_venditore_cliente_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_COM%TYPE,
							   			--p_aliquota_venditore_cliente_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_DIR%TYPE,
							   			--p_aliquota_venditore_prodott_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_COM%TYPE,
							   			--p_aliquota_venditore_prodott_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_DIR%TYPE,
                                        --p_ind_sconto_sost_age                   CD_RAGGRUPPAMENTO_INTERMEDIARI.IND_SCONTO_SOST_AGE%TYPE,
                                        --p_perc_sconto_sost_age                  CD_RAGGRUPPAMENTO_INTERMEDIARI.PERC_SCONTO_SOST_AGE%TYPE,
                                        p_esito							OUT NUMBER)
IS

BEGIN -- PR_INSERISCI_RAGGR_INTERMED
--

p_esito 	:= 1;
--P_RAGGR_INTERMED := RAGGR_INTERMED_SEQ.NEXTVAL;

	 --
  		SAVEPOINT ann_ins;
  	--
       -- effettuo l'INSERIMENTO
	   INSERT INTO CD_RAGGRUPPAMENTO_INTERMEDIARI
	     ( ID_VER_PIANO,
           ID_AGENZIA,
           ID_CENTRO_MEDIA,
--           ID_VENDITORE_PRODOTTO,
           ID_VENDITORE_CLIENTE,
           ID_PIANO,
           DATA_DECORRENZA--,
		  -- ALIQUOTA_AGENZIA,
           --ALIQUOTA_VENDITORE_CLIENTE_COM,
		   --ALIQUOTA_VENDITORE_CLIENTE_DIR,
		   --ALIQUOTA_VENDITORE_PRODOTT_COM,
		   --ALIQUOTA_VENDITORE_PRODOTT_DIR,
           --IND_SCONTO_SOST_AGE,
           --PERC_SCONTO_SOST_AGE--,
	      --UTEMOD,
	      --DATAMOD
	     )
	   VALUES
	     ( p_id_ver_piano,
           p_id_agenzia,
           p_id_centro_media,
--           p_id_venditore_prodotto,
           p_id_venditore_cliente,
           p_id_piano,
           p_data_decorrenza
		   --p_aliquota_agenzia,
           --p_aliquota_venditore_cliente_c,
		   --p_aliquota_venditore_cliente_d,
		   --p_aliquota_venditore_prodott_c,
		   --p_aliquota_venditore_prodott_d,
           --p_ind_sconto_sost_age,
           --p_perc_sconto_sost_age--,
		   --user,
		   --FU_DATA_ORA
		  );
	   --

	EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
		WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20023, 'PROCEDURA PR_INSERISCI_RAGGR_INTERMED: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_RAGGR_INTERMED( p_id_ver_piano,
                                                                                                                                                                       p_id_agenzia,
                                                                                                                                                                       p_id_centro_media,
                                                                                                                                                                      -- p_id_venditore_prodotto,
                                                                                                                                                                       p_id_venditore_cliente,
                                                                                                                                                                       p_id_piano,
                                                                                                                                                                       p_data_decorrenza--,
                                                                                                                                                            		   --p_aliquota_agenzia,
                                                                                                                                                                       --p_aliquota_venditore_cliente_c,
                                                                                                                                                            		   --p_aliquota_venditore_cliente_d,
                                                                                                                                                            		   --p_aliquota_venditore_prodott_c,
                                                                                                                                                            		   --p_aliquota_venditore_prodott_d,
                                                                                                                                                                       --p_ind_sconto_sost_age,
                                                                                                                                                                       --p_perc_sconto_sost_age
                                                                                                                                                                       )
                                                                                                                                                                       );
		ROLLBACK TO ann_ins;


END;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_RAGGR_INTERMED
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un raggruppamento intermediari dal sistema
--
-- OPERAZIONI:
--   3) Elimina il raggruppamento intermediari
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
PROCEDURE PR_ELIMINA_RAGGR_INTERMED(  p_id_raggruppamento       		IN CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_RAGGRUPPAMENTO%TYPE,
									  p_esito		            	    OUT NUMBER)
IS


--
BEGIN -- PR_ELIMINA_RAGGR_INTERMED
--

p_esito 	:= 1;

	 --
  		SAVEPOINT ann_del;

	   -- EFFETTUA L'eliminazione
	   DELETE FROM CD_RAGGRUPPAMENTO_INTERMEDIARI
	   WHERE ID_RAGGRUPPAMENTO= p_id_raggruppamento;
	   --

	p_esito := SQL%ROWCOUNT;

  EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20023, 'PROCEDURA PR_ELIMINA_RAGGR_INTERMED: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI');
		ROLLBACK TO ann_del;

END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_RAGGR_INTERMED
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_STAMPA_RAGGR_INTERMED(  p_id_ver_piano                          CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
                                    p_id_agenzia                            CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
                                    p_id_centro_media                       CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
--                                    p_id_venditore_prodotto                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_PRODOTTO%TYPE,
                                    p_id_venditore_cliente                  CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
                                    p_id_piano                              CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
                                    p_data_decorrenza                       CD_RAGGRUPPAMENTO_INTERMEDIARI.DATA_DECORRENZA%TYPE--,
			   			            --p_aliquota_agenzia                      CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_AGENZIA%TYPE,
			   			            --p_aliquota_venditore_cliente_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_COM%TYPE,
			   		            	--p_aliquota_venditore_cliente_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_CLIENTE_DIR%TYPE,
			   			            --p_aliquota_venditore_prodott_c          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_COM%TYPE,
			   			            --p_aliquota_venditore_prodott_d          CD_RAGGRUPPAMENTO_INTERMEDIARI.ALIQUOTA_VENDITORE_PRODOTT_DIR%TYPE,
                                    --p_ind_sconto_sost_age                   CD_RAGGRUPPAMENTO_INTERMEDIARI.IND_SCONTO_SOST_AGE%TYPE,
                                    --p_perc_sconto_sost_age                  CD_RAGGRUPPAMENTO_INTERMEDIARI.PERC_SCONTO_SOST_AGE%TYPE
                                    ) RETURN VARCHAR2
IS

BEGIN

IF v_stampa_raggr_intermed = 'ON'

    THEN

     RETURN 'ID_VER_PIANO: '          || p_id_ver_piano          || ', ' ||
            'ID_AGENZIA: '          || p_id_agenzia            || ', ' ||
            'ID_CENTRO_MEDIA: '|| p_id_centro_media   || ', ' ||
        --    'ID_VENDITORE_PRODOTTO: '  || p_id_venditore_prodotto       || ', ' ||
            'ID_VENDITORE_CLIENTE: ' || p_id_venditore_cliente       || ', ' ||
            'ID_PIANO: '          || p_id_piano               || ', ' ||
            'DATA_DECORRENZA: '          || p_data_decorrenza;--                   || ', ' ||
          --  'ALIQUOTA_AGENZIA: '      || p_aliquota_agenzia         || ', '||
            --'ALIQUOTA_VENDITORE_CLIENTE_C: '      || p_aliquota_venditore_cliente_c        || ', '||
            --'ALIQUOTA_VENDITORE_CLIENTE_D: '          || p_aliquota_venditore_cliente_d               || ', ' ||
            --'ALIQUOTA_VENDITORE_PRODOTT_C: '          || p_aliquota_venditore_prodott_c                   || ', ' ||
            --'ALIQUOTA_VENDITORE_PRODOTT_D: '      || p_aliquota_venditore_prodott_d         || ', '||
            --'IND_SCONTO_SOST_AGE: '      || p_ind_sconto_sost_age        || ', '||
            --'PERC_SCONTO_SOST_AGE: '      || p_perc_sconto_sost_age ;

END IF;

END  FU_STAMPA_RAGGR_INTERMED;


END PA_CD_RAGGR_INTERMED;
/

