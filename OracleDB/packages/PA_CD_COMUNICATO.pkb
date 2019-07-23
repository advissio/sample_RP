CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_COMUNICATO  AS
/******************************************************************************
   NAME:       PA_CD_COMUNICATO
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/06/2009             1. Created this package body.
******************************************************************************/

/*Mauro Viel Altran Ottobre 2009 costante che indica il limite di messa in onda*/
v_limite_messa_in_onda number:=5;

/* VARIABILI DA SETTARE PER LA LISTA GRUPPI COMUNICATI DI PAOLO*/
V_ID_PRODOTTO_ACQUISTATO	 CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE;
V_DATA_EROGAZIONE_FROM 		 CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE;
V_DATA_EROGAZIONE_TO 			 CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE;
V_ID_REGIONE 							 CD_REGIONE.ID_REGIONE%TYPE;
V_ID_PROVINCIA 						 CD_PROVINCIA.ID_PROVINCIA%TYPE;
V_ID_COMUNE 							 CD_COMUNE.ID_COMUNE%TYPE;
V_ID_CINEMA 							 CD_CINEMA.ID_CINEMA%TYPE;
V_ID_SOGGETTO 						 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
------------------------------------------------------------------------------------

/*
 PROCEDURE PR_INSER_COMUNICATO_PRDACQ (
     p_id_prodotto_acquistato IN CD_PRODOTTO_ACQUISTATO.id_prodotto_acquistato%TYPE
 ) IS
 v_prodotto_acquistato CD_PRODOTTO_ACQUISTATO%ROWTYPE;
 v_prodotto_vendita CD_PRODOTTO_VENDITA%ROWTYPE;
 v_id_prodotto_vendita NUMBER;
 v_id_categoria_prodotto NUMBER;
 tmpVar NUMBER;
 BEGIN
 tmpVar := 0;
  SELECT CD_PRODOTTO_ACQUISTATO.id_prodotto_vendita
  ,CD_PIANIFICAZIONE.COD
  INTO v_id_prodotto_vendita, v_id_categoria_prodotto
  FROM CD_PRODOTTO_ACQUISTATO,
       CD_PIANIFICAZIONE
  WHERE  CD_PRODOTTO_ACQUISTATO.id_prodotto_acquistato = p_id_prodotto_acquistato
  AND    CD_PRODOTTO_ACQUISTATO.ID_PIANO=CD_PIANIFICAZIONE.ID_PIANO;

  SELECT *
  INTO v_prodotto_vendita
  FROM CD_PRODOTTO_VENDITA
  WHERE  CD_PRODOTTO_VENDITA.id_prodotto_vendita = v_id_prodotto_vendita;
  EXCEPTION
  WHEN  TOO_MANY_ROWS THEN RAISE;
  WHEN  NO_DATA_FOUND THEN RAISE;
  WHEN OTHERS THEN RAISE;

 END PR_INSER_COMUNICATO_PRDACQ;
 */

/*******************************************************************************
 ANNULLA COMUNICATO
 Author:  Francesco Abbundo, Teoresi Group, Settembre 2009
 DESCRIZIONE:   Annulla logicamente  il comunicato.
                Aggiunto un parametro discriminatorio sul chiamante.
				Se tutti i comunicati relativi al prodotto acquistato cui si riferisce questo comunicato
				sono stati annullati, allora annullo anche il prodotto acquistato.
 INPUT: p_id_comunicato  l'id del comunicato da annullare
        p_chiamante      discriminatore del chiamante
		                 i valori ammessi per p_chiamante sono MAG per magazzino e PAL per palinsesto
                         Se chiamante e' MAG allora annullo il comunicato
                         Se chiamante e' PAL devo fare dei controlli sulla data_erogazione_eff
						e sullo stato_vendita
OUTPUT: p_esito: -11    si e' verificato un problema, l'operazaione non e' stata eseguita
                  10    chiamante non riconosciuto, comunicato non annullato
                   2    comunicato annullato dal magazzino
				  12    comunicato annullato dal magazzino e prodotto_acquistato annullato
				  22    comunicato annullato dal magazzino e prodotto_acquistato NON annullato
				        a causa di un errore
				   3    comunicato NON annullato dal palinsesto perche' data_erogazione_prev < SYSDATE
				   4    comunicato NON annullato dal palinsesto e che deve essere saltato
				  14    comunicato NON annullato dal palinsesto e NON saltato a causa di un errore imprevisto
				   5    comunicato annullato dal palinsesto e che NON deve essere saltato
				  15    comunicato annullato dal palinsesto e che NON deve essere saltato  e prodotto_acquistato annullato
				  25    comunicato annullato dal palinsesto e che NON deve essere saltato  e prodotto_acquistato
				        NON annullato a causa di un errore
MODIFICHE: Abbundo Francesco, Teoresi srl, Febbraio 2010
           Abbundo Francesco, Teoresi srl, Marzo 2010 
		   Aggiunta la gestione del lordo saltato discriminato per quota direzionale e commerciale
           Mauro Viel Altran italia 16/06/2011 #MV01 Consentito l'annullamento retroattivo dei comunicati dal palinsesto.
                
*******************************************************************************/
PROCEDURE  PR_ANNULLA_COMUNICATO(p_id_comunicato IN CD_COMUNICATO.id_comunicato%TYPE,
                                 p_chiamante VARCHAR2,
                                 p_esito IN OUT NUMBER,
                                 p_piani_errati  OUT VARCHAR2)
IS
    v_data_erogazione        CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE;
	v_stato_vendita          CD_STATO_DI_VENDITA.DESCR_BREVE%TYPE;
	v_numero_comunicati      INTEGER;
	v_num_com_validi         INTEGER;
	v_comunicati_annullati   INTEGER;
	v_temp                   INTEGER:=0;
    v_num_ambienti_old        NUMBER;
    v_num_ambienti            NUMBER;
	v_importo_prima_c        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_dopo_c         CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_lordo_c        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
	v_importo_prima_d        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_dopo_d         CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_lordo_d        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
	v_numcom_saltati         INTEGER;
	v_numcom_totali          INTEGER;
	v_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
    v_esito_schermo          NUMBER;
    v_luogo CD_LUOGO.ID_LUOGO%TYPE;
BEGIN
    p_esito := 10;
	SAVEPOINT SP_PR_ANNULLA_COMUNICATO;
	--se chiama il magazzino effettuo comunque l'annullamento
    SELECT CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
	INTO   v_id_prodotto_acquistato
    FROM   CD_COMUNICATO
    WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato;
    --
    v_luogo := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_LUOGO_PROD_ACQ(v_id_prodotto_acquistato);
    --
    SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
	INTO   v_importo_prima_c	   
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
	    
    SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
	INTO   v_importo_prima_d	   
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
	    
	v_num_ambienti_old := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(v_id_prodotto_acquistato);

	IF(p_chiamante='MAG')THEN

        UPDATE CD_COMUNICATO
            SET    CD_COMUNICATO.FLG_ANNULLATO='S'
            WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato
    		AND    CD_COMUNICATO.FLG_ANNULLATO='N';
    		p_esito:=2;
	--altrimenti devo capire se bisogna effettuare il salto o meno
	ELSE
	    IF(p_chiamante='PAL')THEN
	        SELECT CD_COMUNICATO.DATA_EROGAZIONE_PREV
			INTO   v_data_erogazione
			FROM   CD_COMUNICATO
			WHERE  CD_COMUNICATO.ID_COMUNICATO=p_id_comunicato; --#MV01 inizio
			/*IF(v_data_erogazione<SYSDATE)THEN
			    p_esito:=3; --non devo saltare
			ELSE--*/-- #MV01
	            SELECT CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA
                INTO   v_stato_vendita
				FROM   CD_PRODOTTO_ACQUISTATO
                WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO =(
                        SELECT CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
                        FROM   CD_COMUNICATO
                        WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato) ;
	            --devo pero' verificare se il metodo chiamante
				IF(v_stato_vendita='PRE')THEN
				    p_esito:=4; --deve saltare
					PA_CD_COMUNICATO.PR_SALTA_COMUNICATO(p_id_comunicato,v_temp);

                    IF(v_temp<>1)THEN
					    p_esito:=p_esito+10;
					END IF;
				ELSE
	                p_esito:=5; --non deve saltare
					--annullo il comunicato a questo punto
    				UPDATE CD_COMUNICATO
                    SET    CD_COMUNICATO.FLG_ANNULLATO='S'
                    WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato
            		AND    CD_COMUNICATO.FLG_ANNULLATO='N';
	            END IF;
	        --END IF; #MV01
    	END IF;
	END IF;
    IF(v_stato_vendita='PRE' AND v_luogo = 1)THEN
        PA_CD_PRODOTTO_ACQUISTATO.PR_ELIMINA_BUCO_POSIZIONE_COM(p_id_comunicato);
    END IF;
    -- Mauro Viel Altran 13/01/2010
    -- deve essere sempre eseguita indipendentemente dal chiamante.
    v_num_ambienti := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(v_id_prodotto_acquistato);
    --
    IF(v_num_ambienti != v_num_ambienti_old) THEN
        PA_CD_PRODOTTO_ACQUISTATO.PR_ANNULLA_SCHERMO_PROD_ACQ(v_id_prodotto_acquistato, null,  v_esito_schermo,p_piani_errati);
		IF(p_esito=4)THEN
            SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
        	INTO   v_importo_dopo_c	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
	    
            SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
        	INTO   v_importo_dopo_d	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';		

        	--recupero precedente importo lordo saltato
			SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
        	INTO   v_importo_lordo_c	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
			
            SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
        	INTO   v_importo_lordo_d	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
			
            --aggiornamento dell'importo lordo saltato
			UPDATE CD_IMPORTI_PRODOTTO
        	SET    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO = (v_importo_lordo_c + v_importo_prima_c - v_importo_dopo_c)	   
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
			
			UPDATE CD_IMPORTI_PRODOTTO
        	SET    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO = (v_importo_lordo_d + v_importo_prima_d - v_importo_dopo_d)	   
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
		END IF;
    END IF;
--
    IF((p_esito=2) OR (p_esito=5))THEN
	    SELECT COUNT(*)
		INTO   v_num_com_validi
        FROM   CD_COMUNICATO
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_ANNULLATO='N'
		AND    CD_COMUNICATO.FLG_SOSPESO='N'
        AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL;

		IF(v_num_com_validi=0)THEN
			PA_CD_PRODOTTO_ACQUISTATO.PR_ANNULLA_PRODOTTO_ACQUIST(v_id_prodotto_acquistato,p_chiamante,v_temp);
			IF((v_temp=100) OR (v_temp<0))THEN
			    p_esito:=p_esito+20;
			ELSE
			    p_esito:=p_esito+10;
			END IF;
		END IF;
	END IF;
--
	IF(p_esito=4)THEN
        SELECT COUNT(*)
    	INTO   v_numcom_saltati
        FROM   CD_COMUNICATO
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
        AND    CD_COMUNICATO.FLG_SOSPESO='N'
        AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NOT NULL;
    --
        SELECT COUNT(*)
    	INTO   v_numcom_totali
        FROM   CD_COMUNICATO
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
        AND    CD_COMUNICATO.FLG_SOSPESO='N';
    --
    	IF((v_numcom_saltati=v_numcom_totali)AND(v_numcom_totali>0))THEN
    	    UPDATE CD_PRODOTTO_ACQUISTATO
            SET    CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE = 'S'
            WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato;
    	END IF;
	END IF;
EXCEPTION
    WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_ANNULLA_COMUNICATO: operazione non eseguita, si e'' verificato un errore  '||SQLERRM);
        ROLLBACK TO SP_PR_ANNULLA_COMUNICATO;
END PR_ANNULLA_COMUNICATO;
/*******************************************************************************
 RECUPERA COMUNICATO
 Author:  Francesco Abbundo, Teoresi, Settembre 2009
 Recupera un comunicato precedentemente annullato logicamente.
 Aggiunto un parametro discriminatorio sul chiamante.
 INPUT: p_id_comunicato  l'id del comunicato da recuperare
        p_chiamante      discriminatore del chiamante
		                 i valori ammessi per p_chiamante sono MAG per magazzino e PAL per palinsesto
                         Se chiamante e' MAG allora recupero il comunicato
                         Se chiamante e' PAL devo fare dei controlli ulteriori

 MODIFICHE
 Michele Borgogno, Altran, Ottobre 2009
*******************************************************************************/
PROCEDURE PR_RECUPERA_COMUNICATO(p_id_comunicato IN  CD_COMUNICATO.id_comunicato%TYPE,
                                 p_chiamante     IN  VARCHAR2,
                                 p_esito         OUT NUMBER)
IS
	v_numero_comunicati      INTEGER;
    v_comunicati_annullati   INTEGER;
	v_temp                   INTEGER:=0;
	v_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE;
    v_num_schermi_old        NUMBER;
    v_num_schermi            NUMBER;
    v_esito_schermo          NUMBER;
    v_piani_errati           VARCHAR2(32000);
    v_temp3                  VARCHAR2(3);
    v_importo_prima_c        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_dopo_c         CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_lordo_c        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
	v_importo_prima_d        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_dopo_d         CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
	v_importo_lordo_d        CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO%TYPE;
	v_numcom_saltati         INTEGER;
	v_numcom_totali          INTEGER;
	v_num_com_validi         INTEGER;
BEGIN
    p_esito:=1;
	SAVEPOINT SP_PR_RECUPERA_COMUNICATO;

    SELECT CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
    INTO   v_id_prodotto_acquistato
    FROM   CD_COMUNICATO
    WHERE  CD_COMUNICATO.ID_COMUNICATO=p_id_comunicato;
    SELECT COUNT(*)
    INTO   v_numero_comunicati
    FROM   CD_COMUNICATO
    WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
    AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL;
    SELECT COUNT(*)
    INTO   v_comunicati_annullati
    FROM   CD_COMUNICATO
    WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
    AND    CD_COMUNICATO.FLG_ANNULLATO='S'
    AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL;

    SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
	INTO   v_importo_prima_c	   
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
	    
    SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
	INTO   v_importo_prima_d	   
    FROM   CD_IMPORTI_PRODOTTO
    WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';

	v_num_schermi_old := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(v_id_prodotto_acquistato);

	--recupero con chiamata da magazzino
	IF(p_chiamante='MAG')THEN
	    p_esito:=2;
	    UPDATE CD_COMUNICATO
        SET    CD_COMUNICATO.FLG_ANNULLATO='N'
        WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato
		AND    CD_COMUNICATO.FLG_ANNULLATO='S';

        SELECT NVL(CD_COMUNICATO.COD_DISATTIVAZIONE,'-')
		INTO   v_temp3
        FROM   CD_COMUNICATO
        WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato;
		IF(v_temp3='S')THEN
		    p_esito:=4;
		END IF;
		UPDATE CD_COMUNICATO
        SET    CD_COMUNICATO.COD_DISATTIVAZIONE = NULL
        WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato;
	--altrimenti devo capire se bisogna effettuare il salto o meno
	ELSE
--	    IF(p_chiamante='PAL')THEN
--	        SELECT CD_COMUNICATO.DATA_EROGAZIONE_PREV
--			INTO   v_data_erogazione
--			FROM   CD_COMUNICATO
--			WHERE  CD_COMUNICATO.ID_COMUNICATO=p_id_comunicato;
--			IF(v_data_erogazione<SYSDATE)THEN
--			    p_esito:=3; --non devo saltare
--			ELSE
--	            SELECT CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA
--                INTO   v_stato_vendita
--				FROM   CD_PRODOTTO_ACQUISTATO
--                WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO =(
--                        SELECT CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO
--                        FROM   CD_COMUNICATO
--                        WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato) ;
--	            --devo pero' verificare se il metodo chiamante
--				IF(v_stato_vendita='PRE')THEN
--				    p_esito:=4; --deve saltare
--					PA_CD_COMUNICATO.PR_SALTA_COMUNICATO(p_id_comunicato,v_temp);
--					IF(v_temp<>1)THEN
--					    p_esito:=p_esito+10;
--					END IF;
--				ELSE
--	                p_esito:=5; --non deve saltare
--					--annullo il comunicato a questo punto
--    				UPDATE CD_COMUNICATO
--                    SET    CD_COMUNICATO.FLG_ANNULLATO='S'
--                    WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato
--            		AND    CD_COMUNICATO.FLG_ANNULLATO='N';
--	            END IF;
--	        END IF;
--    	END IF;
        p_esito:=1;
	END IF;
    v_num_schermi := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI(v_id_prodotto_acquistato);
--
    IF(v_num_schermi != v_num_schermi_old) THEN
        PA_CD_PRODOTTO_ACQUISTATO.PR_RIPRISTINA_SCHERMO_PROD_ACQ(v_id_prodotto_acquistato, null,  v_esito_schermo,v_piani_errati);
		IF(p_esito=4)THEN
		    SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
        	INTO   v_importo_dopo_c	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
	    
            SELECT PA_PC_IMPORTI.FU_LORDO_COMM(CD_IMPORTI_PRODOTTO.IMP_NETTO, CD_IMPORTI_PRODOTTO.IMP_SC_COMM)
        	INTO   v_importo_dopo_d	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';		

        	--recupero precedente importo lordo saltato
			SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
        	INTO   v_importo_lordo_c	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
			
            SELECT CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO
        	INTO   v_importo_lordo_d	   
            FROM   CD_IMPORTI_PRODOTTO
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
			
        	--aggiornamento dell'importo lordo saltato
			UPDATE CD_IMPORTI_PRODOTTO
        	SET    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO = (v_importo_lordo_c + v_importo_prima_c - v_importo_dopo_c)	   
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='C';
			
			UPDATE CD_IMPORTI_PRODOTTO
        	SET    CD_IMPORTI_PRODOTTO.IMP_LORDO_SALTATO = (v_importo_lordo_d + v_importo_prima_d - v_importo_dopo_d)	   
            WHERE  CD_IMPORTI_PRODOTTO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato
        	AND    CD_IMPORTI_PRODOTTO.TIPO_CONTRATTO='D';
		END IF;
    END IF;
--
    IF((p_esito=2) OR (p_esito=4))THEN
	    SELECT COUNT(*)
		INTO   v_num_com_validi
        FROM   CD_COMUNICATO
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_ANNULLATO='N'
		AND    CD_COMUNICATO.FLG_SOSPESO='N'
        AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL;

		IF(v_num_com_validi=1)THEN
			PA_CD_PRODOTTO_ACQUISTATO.PR_RECUPERA_PRODOTTO_ACQUIST(v_id_prodotto_acquistato,p_chiamante,v_temp);
			IF((v_temp=100) OR (v_temp<0))THEN
			    p_esito:=p_esito+20;
			ELSE
			    p_esito:=p_esito+10;
			END IF;
		END IF;
	END IF;
--
	IF(p_esito=4)THEN
        SELECT COUNT(*)
    	INTO   v_numcom_saltati
        FROM   CD_COMUNICATO
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
        AND    CD_COMUNICATO.FLG_SOSPESO='N'
        AND    CD_COMUNICATO.COD_DISATTIVAZIONE IS NOT NULL;
    --
        SELECT COUNT(*)
    	INTO   v_numcom_totali
        FROM   CD_COMUNICATO
        WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO=v_id_prodotto_acquistato
        AND    CD_COMUNICATO.FLG_ANNULLATO ='N'
        AND    CD_COMUNICATO.FLG_SOSPESO='N';
    --
    	IF(((v_numcom_totali-v_numcom_saltati)=1)AND(v_numcom_totali>0))THEN
    	    UPDATE CD_PRODOTTO_ACQUISTATO
            SET    CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE = NULL
            WHERE  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO = v_id_prodotto_acquistato;
    	END IF;
	END IF;
EXCEPTION
    WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_RECUPERA_COMUNICATO: operazione non eseguita, si e'' verificato un errore  '||SQLERRM);
        ROLLBACK TO SP_PR_RECUPERA_COMUNICATO;
END PR_RECUPERA_COMUNICATO;

/*******************************************************************************
 SALTA COMUNICATO
 Author:  Francesco Abbundo, Teoresi Group, Settembre 2009
 DESCRIZIONE:   Effettua il salto del comunicato
 INPUT: p_id_comunicato  l'id del comunicato da annullare
OUTPUT: p_esito: -11     si e' verificato un problema, l'operazaione non e' stata eseguita
                   1     informazione di salto impostata correttamente
MODIFICHE: Simone Bottani, Altran, Febbraio 2010 (aggiunta la chiamata a PR_ELIMINA_BUCO_POSIZIONE)
*******************************************************************************/
PROCEDURE PR_SALTA_COMUNICATO(p_id_comunicato  IN CD_COMUNICATO.id_comunicato%TYPE,
                                p_esito OUT NUMBER)
IS
BEGIN
    p_esito := 1;
	SAVEPOINT SP_PR_SALTA_COMUNICATO;
	UPDATE CD_COMUNICATO
    SET    CD_COMUNICATO.COD_DISATTIVAZIONE='S'
    WHERE  CD_COMUNICATO.ID_COMUNICATO = p_id_comunicato;
EXCEPTION
    WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20001, 'Procedura PR_SALTA_COMUNICATO: operazione non eseguita, si e'' verificato un errore  '||SQLERRM);
        ROLLBACK TO SP_PR_SALTA_COMUNICATO;
END PR_SALTA_COMUNICATO;

/*******************************************************************************
 VERIFICA MESSA IN ONDA
 Author:  Mauro Viel , Altran, Ottobre 2009

 Per mezzo di questa funzione si puo verificare la messa in onda di un
 particolare comunicato.
 Restituisce S nel caso incui il comunicato e prossimo lala messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION  FU_VERIFICA_MESSA_IN_ONDA(v_data_erogazione_prev  cd_comunicato.DATA_EROGAZIONE_PREV%type) RETURN char IS
--v_data_erogazione_prev  cd_comunicato.DATA_EROGAZIONE_PREV%type;

BEGIN
/*SELECT data_erogazione_prev
INTO   v_data_erogazione_prev
FROM   cd_comunicato
where  id_comunicato = p_id_comunicato;*/

IF ((v_data_erogazione_prev - TRUNC(SYSDATE) + 1 > v_limite_messa_in_onda)
    OR (TRUNC(SYSDATE) >= v_data_erogazione_prev)) THEN
    RETURN 'N';
ELSE
    RETURN 'S';
END IF;
EXCEPTION
    WHEN  no_data_found  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
END FU_VERIFICA_MESSA_IN_ONDA;

/*******************************************************************************
 VERIFICA MESSA IN ONDA
 Author:  Michele Borgogno , Altran, Febbraio 2010

 Per mezzo di questa funzione si puo verificare la messa in onda di un
 particolare comunicato.
 Restituisce S nel caso incui il comunicato e prossimo lala messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION  FU_VERIFICA_MESSA_IN_ONDA_COM(p_id_comunicato  cd_comunicato.ID_COMUNICATO%type) RETURN char IS
v_data_erogazione_prev  cd_comunicato.DATA_EROGAZIONE_PREV%type;

BEGIN
SELECT data_erogazione_prev
INTO   v_data_erogazione_prev
FROM   cd_comunicato
where  id_comunicato = p_id_comunicato;

IF ((v_data_erogazione_prev - TRUNC(SYSDATE) + 1 > v_limite_messa_in_onda)
    OR (TRUNC(SYSDATE) >= v_data_erogazione_prev)) THEN
    RETURN 'N';
ELSE
    RETURN 'S';
END IF;
EXCEPTION
    WHEN  no_data_found  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA_COM:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_MESSA_IN_ONDA_COM:. Errore: ' || SQLERRM);
END FU_VERIFICA_MESSA_IN_ONDA_COM;

/*******************************************************************************
 VERIFICA DOPO LA MESSA IN ONDA
 Author:  michele Borgogno , Altran, Gennaio 2010

 Per mezzo di questa funzione si puo verificare il periodo di dopo messa in onda di un
 particolare comunicato.
 Restituisce S nel caso incui il comunicato e nel periodo del dopo messa in onda
             N altrimenti.
*******************************************************************************/

FUNCTION  FU_VERIFICA_DOPO_MESSA_IN_ONDA(p_id_comunicato IN cd_comunicato.id_comunicato%type) RETURN char IS
v_data_erogazione_prev  cd_comunicato.DATA_EROGAZIONE_PREV%type;

BEGIN
SELECT data_erogazione_prev
INTO   v_data_erogazione_prev
FROM   cd_comunicato
where  id_comunicato = p_id_comunicato;

--IF v_data_erogazione_prev - TRUNC(SYSDATE) + 1 > v_limite_messa_in_onda THEN
    IF (TRUNC(SYSDATE) - v_data_erogazione_prev > 0) THEN
        RETURN 'S';
    ELSE
        RETURN 'N';
    END IF;
EXCEPTION
    WHEN  no_data_found  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_DOPO_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
    WHEN  others  THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedura FU_VERIFICA_DOPO_MESSA_IN_ONDA:. Errore: ' || SQLERRM);
END FU_VERIFICA_DOPO_MESSA_IN_ONDA;

/*******************************************************************************
 PR_CREA_COMUNICATI_MODULO
 Author:  Simone Bottani, Altran, Luglio 2009

 Inserisce tutti i comunicati partendo da un prodotto acquistato
 MODIFICHE:
 		Enrico Paolo, Altran It, 03 marzo 2010
 Tuning ed ottimizzazione query   [#EP#]
 Mauro Viel inserito il parametro p_flg_segui_il_film
*******************************************************************************/
    PROCEDURE PR_CREA_COMUNICATI_MODULO(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                 p_id_ambito NUMBER,
                                 p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_data_fine   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                 p_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                 p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
                                 p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
                                 p_flg_segui_il_film CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE
                                 ) IS
     v_rec_break PA_CD_ESTRAZIONE_PROD_VENDITA.C_BREAK;
     v_cur_break v_rec_break%ROWTYPE;
     v_rec_sala PA_CD_ESTRAZIONE_PROD_VENDITA.C_SALE;
     v_cur_sala v_rec_sala%ROWTYPE;
     v_rec_atrio PA_CD_ESTRAZIONE_PROD_VENDITA.C_ATRII;
     v_cur_atrio v_rec_atrio%ROWTYPE;
     v_rec_cinema PA_CD_ESTRAZIONE_PROD_VENDITA.C_CINEMA;
     v_cur_cinema v_rec_cinema%ROWTYPE;
     v_data_erogazione_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE;
     v_data_erogazione_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE;
     v_index INTEGER := 1;
     v_num_giorni NUMBER;
     v_list_id_ambito id_list_type;
     --v_dgc CD_COMUNICATO.DGC%TYPE;
     v_cod_tipo_pubb PA_CD_PRODOTTO_VENDITA.C_COD_TIPO_PUBB;
     v_rec_tipo_pubb v_cod_tipo_pubb%ROWTYPE;
     BEGIN
     v_data_erogazione_inizio := p_data_inizio;
     v_num_giorni := PA_CD_TARIFFA.FU_GET_GIORNI_TRASCORSI(p_data_inizio, p_unita_temp);
     v_data_erogazione_fine := v_data_erogazione_inizio + v_num_giorni -1;
     v_cod_tipo_pubb := PA_CD_PRODOTTO_VENDITA.FU_GET_COD_TIPO_PUBB(p_id_prodotto_vendita);
      LOOP
        FETCH v_cod_tipo_pubb INTO v_rec_tipo_pubb;
        EXIT WHEN v_cod_tipo_pubb%NOTFOUND;
        INSERT INTO CD_COMUNICATO (
              VERIFICATO,
              ID_PRODOTTO_ACQUISTATO,
              ID_BREAK_VENDITA,
              ID_CINEMA_VENDITA,
              ID_ATRIO_VENDITA,
              ID_SALA_VENDITA,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
              --DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE,
              ID_SALA,
              ID_BREAK)
              (
                SELECT
									'N',
									p_id_prodotto_acquistato,
									CD_BREAK_VENDITA.ID_BREAK_VENDITA,
									NULL,
									NULL,
									NULL,
									CD_BREAK_VENDITA.DATA_EROGAZIONE,
									'N',
									p_soggetto,
									p_id_posizione_rigore,
									CD_SALA.ID_SALA,
                                    CD_BREAK.ID_BREAK
									FROM     CD_CINEMA, CD_SALA,CD_SCHERMO, CD_FASCIA, CD_PROIEZIONE, CD_CIRCUITO_BREAK,CD_BREAK,CD_BREAK_VENDITA
                  --
									    WHERE   CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                        AND     CD_BREAK_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
									   	AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
									    AND CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
									    AND CD_BREAK_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb
									    AND CD_BREAK.FLG_ANNULLATO = 'N'
									    AND CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
										AND CD_CIRCUITO_BREAK.ID_CIRCUITO = p_id_circuito
										AND CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
									  	AND CD_CIRCUITO_BREAK.ID_BREAK = CD_BREAK.ID_BREAK
										AND CD_PROIEZIONE.ID_FASCIA = CD_FASCIA.ID_FASCIA
									    AND CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                                        AND CD_FASCIA.FLG_ANNULLATO = 'N'
									    AND CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
									    AND CD_SCHERMO.FLG_ANNULLATO = 'N'
									    AND CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
									    AND CD_SALA.FLG_ANNULLATO = 'N'
                                        AND CD_CINEMA.ID_CINEMA = CD_SALA.ID_CINEMA
                                        AND (p_id_target IS NULL OR CD_CINEMA.FLG_VIRTUALE = 'S')
                                        AND (p_flg_segui_il_film ='N' OR CD_CINEMA.FLG_VIRTUALE = 'S')
                                        
                );
        --
        INSERT INTO CD_COMUNICATO (
              VERIFICATO,
               ID_PRODOTTO_ACQUISTATO,
              ID_BREAK_VENDITA,
              ID_CINEMA_VENDITA,
              ID_ATRIO_VENDITA,
              ID_SALA_VENDITA,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
              --DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE)
              (
              SELECT 'N',
               --0,0,
               p_id_prodotto_acquistato,
               NULL,NULL,NULL,ID_SALA_VENDITA,
               CD_SALA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                FROM CD_SALA_VENDITA, CD_CIRCUITO_SALA
                WHERE CD_CIRCUITO_SALA.ID_CIRCUITO = p_id_circuito
                AND CD_CIRCUITO_SALA.FLG_ANNULLATO = 'N'
                AND CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND CD_SALA_VENDITA.FLG_ANNULLATO = 'N'
                AND CD_SALA_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
                AND CD_SALA_VENDITA.ID_CIRCUITO_SALA = CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
                AND CD_SALA_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb);
        --
        INSERT INTO CD_COMUNICATO (
              VERIFICATO,
              ID_PRODOTTO_ACQUISTATO,
              ID_BREAK_VENDITA,
              ID_CINEMA_VENDITA,
              ID_ATRIO_VENDITA,
              ID_SALA_VENDITA,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
              --DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE)
              (
              SELECT 'N',
               --0,0,
               p_id_prodotto_acquistato,
               NULL,NULL,ID_ATRIO_VENDITA,NULL,
               CD_ATRIO_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                FROM CD_ATRIO_VENDITA, CD_CIRCUITO_ATRIO
                WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO = p_id_circuito
                AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO = 'N'
                AND CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND CD_ATRIO_VENDITA.FLG_ANNULLATO = 'N'
                AND CD_ATRIO_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
                AND CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
                AND CD_ATRIO_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb);
        --
        --dbms_output.PUT_LINE('Sto per inserire i cinema');
        --dbms_output.put_line('Prodotto:'||v_rec_tipo_pubb.a_cod_tipo_pubb);
        INSERT INTO CD_COMUNICATO (
              VERIFICATO,
               ID_PRODOTTO_ACQUISTATO,
              ID_BREAK_VENDITA,
              ID_CINEMA_VENDITA,
              ID_ATRIO_VENDITA,
              ID_SALA_VENDITA,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
--              DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE)
              (
              SELECT 'N',
               p_id_prodotto_acquistato,
               NULL,ID_CINEMA_VENDITA,NULL,NULL,
               CD_CINEMA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                FROM CD_CINEMA_VENDITA, CD_CIRCUITO_CINEMA
                WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO = p_id_circuito
                AND CD_CIRCUITO_CINEMA.FLG_ANNULLATO = 'N'
                AND CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND CD_CINEMA_VENDITA.FLG_ANNULLATO = 'N'
                AND CD_CINEMA_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
                AND CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
                AND CD_CINEMA_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb);
     END LOOP;
     CLOSE v_cod_tipo_pubb;
      EXCEPTION
      WHEN OTHERS THEN
      	RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_CREA_COMUNICATI_MODULO: INSERT NON ESEGUITA'|| SQLERRM);
    END PR_CREA_COMUNICATI_MODULO;

/*******************************************************************************
 PR_CREA_COMUNICATI
 Author:  Simone Bottani, Altran, Luglio 2009

 Inserisce tutti i comunicati partendo da un prodotto acquistato
*******************************************************************************/
    PROCEDURE PR_CREA_COMUNICATI_LIBERA(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                 p_id_ambito NUMBER,
                                 p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_data_fine   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_list_id_ambito id_list_type,
                                 p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                 p_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                 p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE) IS
     v_num_giorni NUMBER;
     --v_dgc CD_COMUNICATO.DGC%TYPE;
     BEGIN
			--
     -- dbms_output.put_line('Id_ambito:'||p_id_ambito);
      SELECT PA_CD_TARIFFA.FU_GET_GIORNI_TRASCORSI(p_data_inizio, p_unita_temp) INTO v_num_giorni FROM DUAL;
      IF p_id_ambito = 1 THEN --Schermo in sala
        PR_INSERT_COMUNICATI_SCHERMO(p_list_id_ambito, p_id_prodotto_acquistato,p_id_prodotto_vendita,p_id_circuito,p_data_inizio, p_data_fine,p_id_formato,v_num_giorni,p_soggetto,p_id_posizione_rigore);
      ELSIF p_id_ambito = 2 THEN --Sala
        PA_CD_COMUNICATO.PR_INSERT_COMUNICATI_SALA(p_list_id_ambito, p_id_prodotto_acquistato,p_id_prodotto_vendita,p_id_circuito,p_data_inizio, p_data_fine,v_num_giorni,p_soggetto,p_id_posizione_rigore);
      ELSIF p_id_ambito = 3 THEN --Atrio
        PA_CD_COMUNICATO.PR_INSERT_COMUNICATI_ATRIO(p_list_id_ambito, p_id_prodotto_acquistato,p_id_prodotto_vendita,p_id_circuito,p_data_inizio, p_data_fine,v_num_giorni,p_soggetto,p_id_posizione_rigore);
      ELSIF p_id_ambito = 4 THEN --Cinema
        PA_CD_COMUNICATO.PR_INSERT_COMUNICATI_CINEMA(p_list_id_ambito, p_id_prodotto_acquistato,p_id_prodotto_vendita,p_id_circuito,p_data_inizio, p_data_fine,v_num_giorni,p_soggetto,p_id_posizione_rigore);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE;
    END PR_CREA_COMUNICATI_LIBERA;
/*******************************************************************************
 PR_CREA_COMUNICATI_NIELSEN
 Author:  Simone Bottani, Altran, Luglio 2009

 Inserisce tutti i comunicati partendo da un prodotto acquistato
 MODIFICHE:
 		Enrico Paolo, Altran IT, 03 marzo 2010
 		 Tuning ed ottimizzazione query   [#EP#]
*******************************************************************************/
    PROCEDURE PR_CREA_COMUNICATI_NIELSEN(p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                 p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                 p_id_ambito NUMBER,
                                 p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                 p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_data_fine   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                 p_id_formato CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE,
                                 p_unita_temp CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                 p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                 p_id_posizione_rigore   CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE,
                                 p_list_id_area id_list_type) IS
     v_rec_break PA_CD_ESTRAZIONE_PROD_VENDITA.C_BREAK;
     v_cur_break v_rec_break%ROWTYPE;
     v_rec_sala PA_CD_ESTRAZIONE_PROD_VENDITA.C_SALE;
     v_cur_sala v_rec_sala%ROWTYPE;
     v_rec_atrio PA_CD_ESTRAZIONE_PROD_VENDITA.C_ATRII;
     v_cur_atrio v_rec_atrio%ROWTYPE;
     v_rec_cinema PA_CD_ESTRAZIONE_PROD_VENDITA.C_CINEMA;
     v_cur_cinema v_rec_cinema%ROWTYPE;
     v_data_erogazione_inizio CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE;
     v_data_erogazione_fine CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE;
     v_index INTEGER := 1;
     v_num_giorni NUMBER;
     v_list_id_ambito id_list_type;
     --v_dgc CD_COMUNICATO.DGC%TYPE;
     v_cod_tipo_pubb PA_CD_PRODOTTO_VENDITA.C_COD_TIPO_PUBB;
     v_rec_tipo_pubb v_cod_tipo_pubb%ROWTYPE;
     BEGIN
     v_data_erogazione_inizio := p_data_inizio;
     v_num_giorni := PA_CD_TARIFFA.FU_GET_GIORNI_TRASCORSI(p_data_inizio, p_unita_temp);
     v_data_erogazione_fine := v_data_erogazione_inizio + v_num_giorni -1;
--
     -- dbms_output.put_line('Id_ambito:'||p_id_ambito);
     v_cod_tipo_pubb := PA_CD_PRODOTTO_VENDITA.FU_GET_COD_TIPO_PUBB(p_id_prodotto_vendita);
      LOOP
        FETCH v_cod_tipo_pubb INTO v_rec_tipo_pubb;
        EXIT WHEN v_cod_tipo_pubb%NOTFOUND;
      --IF p_id_ambito = 1 THEN --Schermo in sala
        IF p_list_id_area IS NOT NULL AND p_list_id_area.COUNT > 0 THEN
            FOR i IN 1..p_list_id_area.COUNT LOOP
                --FOR v_index IN 1 .. v_num_giorni LOOP
                INSERT INTO CD_COMUNICATO (
                      VERIFICATO,
                      --SS_PREV,
                      /*MM_INIZIO_PREV,
                      HH_INIZIO_PREV,
                      MM_FINE_PREV,
                      HH_FINE_PREV,*/
                      ID_PRODOTTO_ACQUISTATO,
                      ID_BREAK_VENDITA,
                      ID_CINEMA_VENDITA,
                      ID_ATRIO_VENDITA,
                      ID_SALA_VENDITA,
                      DATA_EROGAZIONE_PREV,
                      FLG_ANNULLATO,
                      --DGC,
                      ID_SOGGETTO_DI_PIANO,
                      POSIZIONE_DI_RIGORE,
                      ID_SALA,
                      ID_BREAK)
                      (
                      SELECT
                      			'N',
											   		/*CD_FASCIA.MM_INIZIO,
											   		CD_FASCIA.HH_INIZIO,
											   		CD_FASCIA.MM_FINE,
											   		CD_FASCIA.HH_FINE,*/
											   		p_id_prodotto_acquistato,
											   		ID_BREAK_VENDITA,
											   		NULL,
											   		NULL,
											   		NULL,
											   		CD_BREAK_VENDITA.DATA_EROGAZIONE,
											   		'N',
											   		p_soggetto,
											   		p_id_posizione_rigore,
											   		CD_SALA.ID_SALA,
                                                    CD_BREAK.ID_BREAK
											  	--
											  	--
											FROM  CD_FASCIA,CD_SALA,CD_SCHERMO,CD_PROIEZIONE,CD_CIRCUITO_BREAK, CD_BREAK, CD_BREAK_VENDITA
											  	WHERE CD_BREAK_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
													   AND CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA	= p_id_prodotto_vendita
													   AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK 	= CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
													   AND CD_BREAK_VENDITA.FLG_ANNULLATO 			= 'N'
													   AND CD_BREAK_VENDITA.COD_TIPO_PUBB 			=  v_rec_tipo_pubb.a_cod_tipo_pubb
														 AND CD_BREAK.FLG_ANNULLATO 							= 'N'
													   AND CD_BREAK.ID_PROIEZIONE 							= CD_PROIEZIONE.ID_PROIEZIONE
													   AND CD_CIRCUITO_BREAK.ID_CIRCUITO 				=  p_id_circuito
													   AND CD_CIRCUITO_BREAK.FLG_ANNULLATO 			= 'N'
													   AND CD_CIRCUITO_BREAK.ID_BREAK 					= CD_BREAK.ID_BREAK
													   AND CD_PROIEZIONE.ID_FASCIA 							= CD_FASCIA.ID_FASCIA
													   AND CD_SCHERMO.ID_SCHERMO 								= CD_PROIEZIONE.ID_SCHERMO
													   AND CD_SCHERMO.FLG_ANNULLATO 						= 'N'
													   AND CD_SALA.ID_SALA 											= CD_SCHERMO.ID_SALA
													   AND CD_SALA.FLG_ANNULLATO 								= 'N'
													   AND CD_SALA.ID_CINEMA
													   		IN
																(SELECT ID_CINEMA FROM CD_CINEMA WHERE ID_COMUNE IN
													         (SELECT ID_COMUNE FROM CD_COMUNE WHERE ID_PROVINCIA IN
													             (SELECT ID_PROVINCIA FROM CD_PROVINCIA WHERE ID_REGIONE IN
													                  (SELECT ID_REGIONE FROM CD_REGIONE WHERE ID_REGIONE IN
													                        (SELECT ID_REGIONE FROM CD_NIELSEN_REGIONE WHERE ID_AREA_NIELSEN = p_list_id_area(i))))))
											);
 --       v_data_erogazione := v_data_erogazione + 1;
  --      END LOOP;
    --  ELSIF p_id_ambito = 2 THEN --Sala
 --       FOR v_index IN 1 .. v_num_giorni LOOP
            INSERT INTO CD_COMUNICATO (
                  VERIFICATO,
                  --SS_PREV,
                  --MM_INIZIO_PREV,
                  --HH_INIZIO_PREV,
                   ID_PRODOTTO_ACQUISTATO,
                  ID_BREAK_VENDITA,
                  ID_CINEMA_VENDITA,
                  ID_ATRIO_VENDITA,
                  ID_SALA_VENDITA,
                  DATA_EROGAZIONE_PREV,
                  FLG_ANNULLATO,
                  --DGC,
                  ID_SOGGETTO_DI_PIANO,
                  POSIZIONE_DI_RIGORE)
                  (
                  SELECT 'N',
                   --0,0,
                   p_id_prodotto_acquistato,
                   NULL,NULL,NULL,ID_SALA_VENDITA,
                   CD_SALA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                    FROM CD_SALA_VENDITA, CD_CIRCUITO_SALA
                    WHERE CD_CIRCUITO_SALA.ID_CIRCUITO = p_id_circuito
                    AND CD_CIRCUITO_SALA.FLG_ANNULLATO = 'N'
                    AND CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                    AND CD_SALA_VENDITA.FLG_ANNULLATO = 'N'
                    AND CD_SALA_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
                    AND CD_SALA_VENDITA.ID_CIRCUITO_SALA = CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
                    AND CD_SALA_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb
                    AND CD_CIRCUITO_SALA.ID_SALA IN
                       (SELECT ID_SALA FROM CD_SALA WHERE ID_CINEMA IN
                           (SELECT ID_CINEMA FROM CD_CINEMA WHERE ID_COMUNE IN
                               (SELECT ID_COMUNE FROM CD_COMUNE WHERE ID_PROVINCIA IN
                                   (SELECT ID_PROVINCIA FROM CD_PROVINCIA WHERE ID_REGIONE IN
                                        (SELECT ID_REGIONE FROM CD_REGIONE WHERE ID_REGIONE IN
                                              (SELECT ID_REGIONE FROM CD_NIELSEN_REGIONE WHERE ID_AREA_NIELSEN = p_list_id_area(i))))))));
  --      v_data_erogazione := v_data_erogazione + 1;
   --     END LOOP;
    --  ELSIF p_id_ambito = 3 THEN --Atrio
    --    FOR v_index IN 1 .. v_num_giorni LOOP
            INSERT INTO CD_COMUNICATO (
                  VERIFICATO,
                  --SS_PREV,
                 -- MM_INIZIO_PREV,
                  --HH_INIZIO_PREV,
                   ID_PRODOTTO_ACQUISTATO,
                  ID_BREAK_VENDITA,
                  ID_CINEMA_VENDITA,
                  ID_ATRIO_VENDITA,
                  ID_SALA_VENDITA,
                  DATA_EROGAZIONE_PREV,
                  FLG_ANNULLATO,
                  --DGC,
                  ID_SOGGETTO_DI_PIANO,
                  POSIZIONE_DI_RIGORE)
                  (
                  SELECT 'N',
                  -- 0,0,
                   p_id_prodotto_acquistato,
                   NULL,NULL,ID_ATRIO_VENDITA,NULL,
                   CD_ATRIO_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                    FROM CD_ATRIO_VENDITA, CD_CIRCUITO_ATRIO
                    WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO = p_id_circuito
                    AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO = 'N'
                    AND CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                    AND CD_ATRIO_VENDITA.FLG_ANNULLATO = 'N'
                    AND CD_ATRIO_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
                    AND CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
                    AND CD_ATRIO_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb
                    AND CD_CIRCUITO_ATRIO.ID_ATRIO IN
                        (SELECT ID_ATRIO FROM CD_ATRIO WHERE ID_CINEMA IN
                           (SELECT ID_CINEMA FROM CD_CINEMA WHERE ID_COMUNE IN
                               (SELECT ID_COMUNE FROM CD_COMUNE WHERE ID_PROVINCIA IN
                                   (SELECT ID_PROVINCIA FROM CD_PROVINCIA WHERE ID_REGIONE IN
                                        (SELECT ID_REGIONE FROM CD_REGIONE WHERE ID_REGIONE IN
                                              (SELECT ID_REGIONE FROM CD_NIELSEN_REGIONE WHERE ID_AREA_NIELSEN = p_list_id_area(i))))))));
       --     v_data_erogazione := v_data_erogazione + 1;
       --     END LOOP;
       --     ELSIF p_id_ambito = 4 THEN --Cinema
       --             FOR v_index IN 1 .. v_num_giorni LOOP
            INSERT INTO CD_COMUNICATO (
                  VERIFICATO,
                  --SS_PREV,
                  --MM_INIZIO_PREV,
                  --HH_INIZIO_PREV,
                   ID_PRODOTTO_ACQUISTATO,
                  ID_BREAK_VENDITA,
                  ID_CINEMA_VENDITA,
                  ID_ATRIO_VENDITA,
                  ID_SALA_VENDITA,
                  DATA_EROGAZIONE_PREV,
                  FLG_ANNULLATO,
    --              DGC,
                  ID_SOGGETTO_DI_PIANO,
                  POSIZIONE_DI_RIGORE)
                  (
                  SELECT 'N',
                   --0,0,
                   p_id_prodotto_acquistato,
                   NULL,ID_CINEMA_VENDITA,NULL,NULL,
                   CD_CINEMA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                    FROM CD_CINEMA_VENDITA, CD_CIRCUITO_CINEMA
                    WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO = p_id_circuito
                    AND CD_CIRCUITO_CINEMA.FLG_ANNULLATO = 'N'
                    AND CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                    AND CD_CINEMA_VENDITA.FLG_ANNULLATO = 'N'
                    AND CD_CINEMA_VENDITA.DATA_EROGAZIONE BETWEEN v_data_erogazione_inizio AND v_data_erogazione_fine
                    AND CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
                    AND CD_CINEMA_VENDITA.COD_TIPO_PUBB = v_rec_tipo_pubb.a_cod_tipo_pubb
                    AND CD_CIRCUITO_CINEMA.ID_CINEMA IN
                       (SELECT ID_CINEMA FROM CD_CINEMA WHERE ID_COMUNE IN
                           (SELECT ID_COMUNE FROM CD_COMUNE WHERE ID_PROVINCIA IN
                               (SELECT ID_PROVINCIA FROM CD_PROVINCIA WHERE ID_REGIONE IN
                                    (SELECT ID_REGIONE FROM CD_REGIONE WHERE ID_REGIONE IN
                                          (SELECT ID_REGIONE FROM CD_NIELSEN_REGIONE WHERE ID_AREA_NIELSEN = p_list_id_area(i)))))));
            --    v_data_erogazione := v_data_erogazione + 1;
            --END LOOP;
            --v_data_erogazione := p_data_inizio;
        END LOOP;
      END IF;
     END LOOP;
     CLOSE v_cod_tipo_pubb;
 --     EXCEPTION
 --     WHEN OTHERS THEN
 --     	RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_COMUNICATI_MODULO: INSERT NON ESEGUITA'|| SQLERRM);
    END PR_CREA_COMUNICATI_NIELSEN;
--
/****************************************************************************
  Procedure: PR_INSERT_COMUNICATI_SCHERMO


  MODIFICHE:
 	Enrico Paolo, Altran IT, 09 marzo 2010     [#EP#]
	 	Tuning ed ottimizzazione query.
	  L'inserimento dei comunicati selezionati viene eseguito una volta sola, senza
	  dover eseguire il ciclo sul numero degli schermi.
	  La ricerca degli schermi da inserire viene fatta attravero l'elaborazione di una stringa:
	  in essa vengono concatenati i codici schermo contenuti nel vettore d'ingresso id_list_type.
	  Dato che la dimensione numerica del dato e'  un number(5), viene "paddato" con degli '0' a sinistra
	  per completarne la dimensione ed evitare cosi che la funzione INSTR utilizzata per
	  l'ottimizzazione dei tempi di elaborazione, duplichi lo stesso valore.
	  Vediamo un esempio: suppponiamo che i codici schermo siano rispettivamente 10, 100, 1000, 10000.
	  La stringa viene composta nel seguente modo : |00010|00100|01000|10000|.....
	  In tal modo la funzione ISTR estrarra solo la corrispondenza esatta.
  N.B.
  	LA dimensione massima della stringa pre-confezionata potra essere al massimo di 32000 byte (LIMITE ORACLE).
		L'eventuale superamento del limite verra segnalato dalla  	RAISE_APPLICATION_ERROR (-20028) -> VALUE_ERROR
*****************************************************************************/
--
    PROCEDURE PR_INSERT_COMUNICATI_SCHERMO(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         --p_cod_pubb CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_id_formato CD_FORMATO_ACQUISTABILE.ID_FORMATO%TYPE,
                                         p_num_giorni NUMBER,
                                         --p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE) IS
    --
    --
    v_data_erogazione_inizio 	CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE;
    v_data_erogazione_fine 		CD_BREAK_VENDITA.DATA_EROGAZIONE%TYPE;
    v_rec_break_vendita 			CD_BREAK_VENDITA%ROWTYPE;
    v_id_ambito 							NUMBER;
    --
    v_string_id_ambito   varchar(32000);    --[#EP#]
    --
    BEGIN
    --
      v_data_erogazione_inizio := p_data_inizio;
      v_data_erogazione_fine := p_data_inizio + p_num_giorni -1;
--
 	--		------------------------------------------------------------		--
  --		costruzione della stringa che contiene l'elenco delle sale.		--
 	--		------------------------------------------------------------ 	--
		FOR i IN p_list_id_ambito.FIRST..p_list_id_ambito.LAST LOOP
    --
  		v_string_id_ambito := v_string_id_ambito||LPAD(p_list_id_ambito(i),5,'0')||'|';
		--
		--   insert into rt_trace(prog,NUM1) values (69,p_list_id_ambito(i));
		--
    end LOOP;
    --		--------------------------------------		--
    --  	Gestione della Insert su CD_COMUNICATO 		--
    --		-------------------------------------- 		--
    	INSERT INTO CD_COMUNICATO (
              VERIFICATO,
              /*MM_INIZIO_PREV,
              HH_INIZIO_PREV,
              MM_FINE_PREV,
              HH_FINE_PREV,*/
              ID_PRODOTTO_ACQUISTATO,
              ID_BREAK_VENDITA,
              ID_CINEMA_VENDITA,
              ID_ATRIO_VENDITA,
              ID_SALA_VENDITA,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE,
              ID_SALA,
              ID_BREAK)
              (
              SELECT
							'N',
							/*CD_FASCIA.MM_INIZIO,
							CD_FASCIA.HH_INIZIO,
							CD_FASCIA.MM_FINE,
							CD_FASCIA.HH_FINE,*/
							p_id_prodotto_acquistato,
							ID_BREAK_VENDITA,
							NULL,
							NULL,
							NULL,
							CD_BREAK_VENDITA.DATA_EROGAZIONE,
							'N',
							p_soggetto,
							p_id_posizione_rigore,
							CD_SALA.ID_SALA,
                            CD_BREAK.ID_BREAK
       		FROM  CD_SCHERMO, CD_PROIEZIONE,CD_FASCIA,CD_SALA,CD_CIRCUITO_BREAK,CD_BREAK,CD_BREAK_VENDITA
                WHERE
                      CD_BREAK_VENDITA.DATA_EROGAZIONE between v_data_erogazione_inizio and v_data_erogazione_fine
                  AND CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                  AND CD_BREAK_VENDITA.FLG_ANNULLATO = 'N'
                  AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK = CD_CIRCUITO_BREAK.ID_CIRCUITO_BREAK
                  AND CD_BREAK.FLG_ANNULLATO = 'N'
                  AND CD_BREAK.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
                  AND CD_BREAK.ID_BREAK = CD_CIRCUITO_BREAK.ID_BREAK
                  AND CD_CIRCUITO_BREAK.ID_CIRCUITO = p_id_circuito
                  AND CD_CIRCUITO_BREAK.FLG_ANNULLATO = 'N'
                  AND CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
                  AND CD_SALA.FLG_ANNULLATO = 'N'
                  AND CD_SCHERMO.FLG_ANNULLATO = 'N'
                  AND CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
                  AND CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                  AND CD_FASCIA.ID_FASCIA = CD_PROIEZIONE.ID_FASCIA
                  AND CD_FASCIA.FLG_ANNULLATO = 'N'
                  AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(CD_SCHERMO.ID_SCHERMO,5,'0')||'|') >= 1
              );
 		--
 EXCEPTION
      WHEN VALUE_ERROR THEN        --> [#EP#]    FINE
      	RAISE_APPLICATION_ERROR(-20028,'PROCEDURA PR_INSERT_COMUNICATI_SCHERMO: INSERT NON ESEGUITA. ERRORE:'||SQLERRM||'VERIFICARE IL DIMENSIONAMENTO DEL PARAMENTRO v_string_id_ambito');
      WHEN OTHERS THEN
      	RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_INSERT_COMUNICATI_SCHERMO: INSERT NON ESEGUITA. ERRORE:'||SQLERRM||'VERIFICARE LA COERENZA DEI PARAMETRI; v_data_erogazione:'||v_data_erogazione_inizio||'p_id_circuito:'||p_id_circuito||'id_ambito:'||v_id_ambito);--'p_cod_pubb'||p_cod_pubb);
			--
    END PR_INSERT_COMUNICATI_SCHERMO;
		--
    --
    PROCEDURE PR_INSERT_COMUNICATI_CINEMA(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                        -- p_cod_pubb CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_num_giorni NUMBER,
                                        -- p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE) IS

    v_data_erogazione_inizio CD_CINEMA_VENDITA.DATA_EROGAZIONE%TYPE;
    v_data_erogazione_fine CD_CINEMA_VENDITA.DATA_EROGAZIONE%TYPE;
    v_rec_cinema_vendita CD_CINEMA_VENDITA%ROWTYPE;
    v_string_id_ambito   varchar(32000);
    BEGIN
      v_data_erogazione_inizio := p_data_inizio;
      v_data_erogazione_fine := p_data_inizio + p_num_giorni -1;
      FOR i IN p_list_id_ambito.FIRST..p_list_id_ambito.LAST LOOP
  		v_string_id_ambito := v_string_id_ambito||LPAD(p_list_id_ambito(i),5,'0')||'|';
      END LOOP;
      --
           INSERT INTO CD_COMUNICATO (
              VERIFICATO,
              ID_PRODOTTO_ACQUISTATO,
              ID_CINEMA_VENDITA,
              --MM_PREV,
              --HH_PREV,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
--              DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE)
              (SELECT 'N',
               p_id_prodotto_acquistato,
              ID_CINEMA_VENDITA,--0,0,
               CD_CINEMA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                FROM CD_CINEMA, CD_CINEMA_VENDITA, CD_CIRCUITO_CINEMA
                WHERE CD_CIRCUITO_CINEMA.ID_CIRCUITO = p_id_circuito
                AND CD_CIRCUITO_CINEMA.FLG_ANNULLATO = 'N'
                AND CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND CD_CINEMA_VENDITA.FLG_ANNULLATO = 'N'
                AND CD_CINEMA_VENDITA.DATA_EROGAZIONE between v_data_erogazione_inizio and v_data_erogazione_fine
                AND CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA = CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
                AND CD_CINEMA.ID_CINEMA = CD_CIRCUITO_CINEMA.ID_CINEMA
                AND CD_CINEMA.FLG_ANNULLATO = 'N'
                AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(CD_CINEMA.ID_CINEMA,5,'0')||'|') >= 1);
    END PR_INSERT_COMUNICATI_CINEMA;

    PROCEDURE PR_INSERT_COMUNICATI_ATRIO(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         --p_cod_pubb CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_num_giorni NUMBER,
                                         --p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE) IS

    v_data_erogazione_inizio CD_ATRIO_VENDITA.DATA_EROGAZIONE%TYPE;
    v_data_erogazione_fine CD_ATRIO_VENDITA.DATA_EROGAZIONE%TYPE;
    v_rec_atrio_vendita CD_ATRIO_VENDITA%ROWTYPE;
    v_string_id_ambito   varchar(32000);
    BEGIN
      v_data_erogazione_inizio := p_data_inizio;
      v_data_erogazione_fine := p_data_inizio + p_num_giorni -1;
      FOR i IN p_list_id_ambito.FIRST..p_list_id_ambito.LAST LOOP
  		v_string_id_ambito := v_string_id_ambito||LPAD(p_list_id_ambito(i),5,'0')||'|';
      END LOOP;
      --
      INSERT INTO CD_COMUNICATO (
              VERIFICATO,
              ID_PRODOTTO_ACQUISTATO,
              ID_ATRIO_VENDITA,
              --MM_PREV,
              --HH_PREV,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
--              DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE)
              (SELECT 'N',
               p_id_prodotto_acquistato,
              ID_ATRIO_VENDITA,--0,0,
               CD_ATRIO_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                FROM CD_ATRIO, CD_ATRIO_VENDITA, CD_CIRCUITO_ATRIO
                WHERE CD_CIRCUITO_ATRIO.ID_CIRCUITO = p_id_circuito
                AND CD_CIRCUITO_ATRIO.FLG_ANNULLATO = 'N'
                AND CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND CD_ATRIO_VENDITA.FLG_ANNULLATO = 'N'
                AND CD_ATRIO_VENDITA.DATA_EROGAZIONE between v_data_erogazione_inizio and v_data_erogazione_fine
                AND CD_ATRIO_VENDITA.ID_CIRCUITO_ATRIO = CD_CIRCUITO_ATRIO.ID_CIRCUITO_ATRIO
                AND CD_ATRIO.ID_ATRIO = CD_CIRCUITO_ATRIO.ID_ATRIO
                AND CD_ATRIO.FLG_ANNULLATO = 'N'
                AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(CD_ATRIO.ID_ATRIO,5,'0')||'|') >= 1);
    END PR_INSERT_COMUNICATI_ATRIO;

    PROCEDURE PR_INSERT_COMUNICATI_SALA(p_list_id_ambito id_list_type,
                                         p_id_prodotto_acquistato CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                         p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                         p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                         --p_cod_pubb CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE,
                                         p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_num_giorni NUMBER,
                                         --p_dgc CD_COMUNICATO.DGC%TYPE,
                                         p_soggetto   CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                         p_id_posizione_rigore CD_POSIZIONE_RIGORE.COD_POSIZIONE%TYPE) IS

    v_data_erogazione_inizio CD_SALA_VENDITA.DATA_EROGAZIONE%TYPE;
    v_data_erogazione_fine CD_SALA_VENDITA.DATA_EROGAZIONE%TYPE;
    v_rec_sala_vendita CD_SALA_VENDITA%ROWTYPE;
    v_string_id_ambito   varchar(32000);
    BEGIN
      v_data_erogazione_inizio := p_data_inizio;
      v_data_erogazione_fine := p_data_inizio + p_num_giorni -1;
      FOR i IN p_list_id_ambito.FIRST..p_list_id_ambito.LAST LOOP
  		v_string_id_ambito := v_string_id_ambito||LPAD(p_list_id_ambito(i),5,'0')||'|';
      END LOOP;
      --
                INSERT INTO CD_COMUNICATO (
              VERIFICATO,
              ID_PRODOTTO_ACQUISTATO,
              ID_SALA_VENDITA,
              --MM_PREV,
              --HH_PREV,
              DATA_EROGAZIONE_PREV,
              FLG_ANNULLATO,
--              DGC,
              ID_SOGGETTO_DI_PIANO,
              POSIZIONE_DI_RIGORE)
              (SELECT 'N',
                p_id_prodotto_acquistato,
                ID_SALA_VENDITA,--0,0,
                CD_SALA_VENDITA.DATA_EROGAZIONE,'N',p_soggetto,p_id_posizione_rigore
                FROM CD_SALA, CD_SALA_VENDITA, CD_CIRCUITO_SALA
                WHERE CD_CIRCUITO_SALA.ID_CIRCUITO = p_id_circuito
                AND CD_CIRCUITO_SALA.FLG_ANNULLATO = 'N'
                AND CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                AND CD_SALA_VENDITA.FLG_ANNULLATO = 'N'
                AND CD_SALA_VENDITA.DATA_EROGAZIONE between v_data_erogazione_inizio and v_data_erogazione_fine
                AND CD_SALA_VENDITA.ID_CIRCUITO_SALA = CD_CIRCUITO_SALA.ID_CIRCUITO_SALA
                AND CD_SALA.ID_SALA = CD_CIRCUITO_SALA.ID_SALA
                AND CD_SALA.FLG_ANNULLATO = 'N'
                AND instr ('|'||v_string_id_ambito||'|','|'||LPAD(CD_SALA.ID_SALA,5,'0')||'|') >= 1);
    END PR_INSERT_COMUNICATI_SALA;

    FUNCTION FU_GET_NUM_COMUNICATI(p_id_prd_acq CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER IS
    v_num_comunicati NUMBER;
    /*Aggiunto COD_DISATTIVAZIONE*/
    BEGIN
        SELECT COUNT(1) INTO v_num_comunicati FROM CD_COMUNICATO
       WHERE
       CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO = p_id_prd_acq
       AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL;
        RETURN v_num_comunicati;
    EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20010, 'Function FU_GET_NUM_COMUNICATI: Impossibile valutare la richiesta');
    END FU_GET_NUM_COMUNICATI;

    /*FUNCTION FU_GET_DGC_CD(p_cod_tipo_pubb CD_PRODOTTO_PUBB.COD_TIPO_PUBB%TYPE) RETURN VARCHAR2 IS
    BEGIN
            return PA_PC_DGC.FU_DETERMINA_DGC(p_cod_tipo_pubb,NULL,NULL,PA_CD_MEZZO.FU_GEST_COMM);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Function FU_GET_DGC_CD: Impossibile determinare il DGC');
    END  FU_GET_DGC_CD;*/

/*******************************************************************************
   ELENCO COMUNICATI PER ASSOCIAZIONE SOGGETTO
  Author:  Michele Borgogno, Altran, Ottobre 2009

   Elenco di comunicati appartenenti ad un prodotto acquistato, per l'associa
   zione di un soggetto
*******************************************************************************/
    FUNCTION  FU_COMUNICATI_SOGGETTO(p_id_prodotto_acquistato IN CD_COMUNICATO.id_prodotto_acquistato%TYPE,
                                     p_data_erogazione_from IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                     p_data_erogazione_to IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                     p_id_regione IN CD_REGIONE.ID_REGIONE%TYPE,
                                     p_id_provincia IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
                                     p_id_comune IN CD_COMUNE.ID_COMUNE%TYPE,
                                     p_id_cinema IN CD_CINEMA.id_cinema%TYPE,
                                     p_id_soggetto IN CD_SOGGETTO_DI_PIANO.id_soggetto_di_piano%TYPE
                                     ) RETURN C_LISTA_COMUNICATI_SOGGETTO IS
    v_lista_comunicati_soggetto C_LISTA_COMUNICATI_SOGGETTO;
    BEGIN
--
        OPEN v_lista_comunicati_soggetto FOR
        /*Aggiunto COD_DISATTIVAZIONE*/
       --select min(ID_SOGGETTO_DI_PIANO),  min(DESC_SOGG_DI_PIANO),  min(ID_COMUNICATO),  min(ID_CINEMA),  max(NOME_CINEMA),  max(COMUNE_CINEMA), max(NOME_AMBIENTE), DATA_EROGAZIONE,  min(luogo),  max(FLG_ANNULLATO)
        select ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, COD_SOGG_DI_PIANO, TITOLO_MAT, min(ID_COMUNICATO) ||'_'||max(id_comunicato) as id_comunicato, ID_CINEMA,NOME_CINEMA,  COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA, NOME_AMBIENTE,DATA_EROGAZIONE,  luogo,  FLG_ANNULLATO
        from (
            select
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as ID_SOGGETTO_DI_PIANO,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as DESC_SOGG_DI_PIANO,
                (select distinct sp.COD_SOGG from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as COD_SOGG_DI_PIANO,
                (select distinct MAT.TITOLO from CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
                    where MAT_PIA.ID_MATERIALE_DI_PIANO (+)= c.ID_MATERIALE_DI_PIANO
                    and MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) as TITOLO_MAT,
                c.id_comunicato as ID_COMUNICATO,
                cin.id_cinema as ID_CINEMA,
                cin.nome_cinema as NOME_CINEMA,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as COMUNE_CINEMA,
                provincia.provincia as PROVINCIA_CINEMA,
                regione.nome_regione as REGIONE_CINEMA,
                cin.nome_cinema as NOME_AMBIENTE,
                c.data_erogazione_prev as DATA_EROGAZIONE,
                'CI' as luogo,
                c.FLG_ANNULLATO as FLG_ANNULLATO
                from CD_PRODOTTO_ACQUISTATO pa, CD_COMUNICATO c,
                     CD_CINEMA_VENDITA cin_ven, CD_CIRCUITO_CINEMA cir_cin,
                     CD_CINEMA cin,
                     CD_COMUNE comune,
                     CD_PROVINCIA provincia,
                     CD_REGIONE regione
                where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
                  and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                  AND c.data_erogazione_prev BETWEEN p_data_erogazione_from AND p_data_erogazione_to
                  AND (p_id_cinema IS NULL OR cin.id_cinema = p_id_cinema)
                  AND (p_id_comune IS NULL OR comune.id_comune = p_id_comune)
                  AND (p_id_provincia IS NULL OR provincia.id_provincia = p_id_provincia)
                  AND (p_id_regione IS NULL OR regione.id_regione = p_id_regione)
                  AND (p_id_soggetto IS NULL OR c.id_soggetto_di_piano = p_id_soggetto)
                  and pa.flg_annullato = 'N'
                  and pa.FLG_SOSPESO = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and c.flg_annullato = 'N'
                  and c.FLG_SOSPESO = 'N'
                  AND c.COD_DISATTIVAZIONE IS NULL
                  and c.id_cinema_vendita = cin_ven.id_cinema_vendita
                  and cin_ven.id_circuito_cinema = cir_cin.id_circuito_cinema
                  and cir_cin.id_cinema = cin.id_cinema
                  and comune.id_comune = cin.id_comune
                  and provincia.id_provincia = comune.id_provincia
                  and regione.id_regione = provincia.id_regione
           union
          (select
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as ID_SOGGETTO_DI_PIANO,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as DESC_SOGG_DI_PIANO,
                (select distinct sp.COD_SOGG from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as COD_SOGG_DI_PIANO,
                (select distinct MAT.TITOLO from CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
                    where MAT_PIA.ID_MATERIALE_DI_PIANO (+)= c.ID_MATERIALE_DI_PIANO
                    and MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) as TITOLO_MAT,
                c.id_comunicato as ID_COMUNICATO,
                cin.id_cinema as ID_CINEMA,
                cin.nome_cinema as NOME_CINEMA,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as COMUNE_CINEMA,
                provincia.provincia as PROVINCIA_CINEMA,
                regione.nome_regione as REGIONE_CINEMA,
                atr.desc_atrio as NOME_AMBIENTE,
                c.data_erogazione_prev as DATA_EROGAZIONE,
                'AT' as luogo,
                c.FLG_ANNULLATO as FLG_ANNULLATO
                from CD_PRODOTTO_ACQUISTATO pa, CD_COMUNICATO c,
                     CD_ATRIO_VENDITA at_ven, CD_CIRCUITO_ATRIO ca,
                     CD_ATRIO atr, CD_CINEMA cin,
                     CD_COMUNE comune,
                     CD_PROVINCIA provincia,
                     CD_REGIONE regione
                where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
                  and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                  AND c.data_erogazione_prev BETWEEN p_data_erogazione_from AND p_data_erogazione_to
                  AND (p_id_cinema IS NULL OR cin.id_cinema = p_id_cinema)
                  AND (p_id_comune IS NULL OR comune.id_comune = p_id_comune)
                  AND (p_id_provincia IS NULL OR provincia.id_provincia = p_id_provincia)
                  AND (p_id_regione IS NULL OR regione.id_regione = p_id_regione)
                  AND (p_id_soggetto IS NULL OR c.id_soggetto_di_piano = p_id_soggetto)
                  and pa.flg_annullato = 'N'
                  and pa.FLG_SOSPESO = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and c.flg_annullato = 'N'
                  and c.FLG_SOSPESO = 'N'
                  AND c.COD_DISATTIVAZIONE IS NULL
                  and c.id_atrio_vendita = at_ven.id_atrio_vendita
                  and at_ven.id_circuito_atrio = ca.id_circuito_atrio
                  and ca.id_atrio = atr.id_atrio
                  and atr.id_cinema = cin.id_cinema
                  and comune.id_comune = cin.id_comune
                  and provincia.id_provincia = comune.id_provincia
                  and regione.id_regione = provincia.id_regione)
           union
          (select
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as ID_SOGGETTO_DI_PIANO,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as DESC_SOGG_DI_PIANO,
                (select distinct sp.COD_SOGG from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as COD_SOGG_DI_PIANO,
                (select distinct MAT.TITOLO from CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
                    where MAT_PIA.ID_MATERIALE_DI_PIANO (+)= c.ID_MATERIALE_DI_PIANO
                    and MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) as TITOLO_MAT,
                c.id_comunicato as ID_COMUNICATO,
                cin.id_cinema as ID_CINEMA,
                cin.nome_cinema as NOME_CINEMA,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as COMUNE_CINEMA,
                provincia.provincia as PROVINCIA_CINEMA,
                regione.nome_regione as REGIONE_CINEMA,
                sa.nome_sala as NOME_AMBIENTE,
                c.data_erogazione_prev as DATA_EROGAZIONE,
                'SA' as luogo,
                c.FLG_ANNULLATO as FLG_ANNULLATO
                from CD_PRODOTTO_ACQUISTATO pa, cd_comunicato c,
                     CD_SALA_VENDITA sal_ven, cd_circuito_sala cs,
                     CD_SALA sa, CD_CINEMA cin,
                     CD_COMUNE comune,
                     CD_PROVINCIA provincia,
                     CD_REGIONE regione
                where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
                  and c.ID_PRODOTTO_ACQUISTATO (+)= pa.ID_PRODOTTO_ACQUISTATO
                  AND c.data_erogazione_prev BETWEEN p_data_erogazione_from AND p_data_erogazione_to
                  AND (p_id_cinema IS NULL OR cin.id_cinema = p_id_cinema)
                  AND (p_id_comune IS NULL OR comune.id_comune = p_id_comune)
                  AND (p_id_provincia IS NULL OR provincia.id_provincia = p_id_provincia)
                  AND (p_id_regione IS NULL OR regione.id_regione = p_id_regione)
                  AND (p_id_soggetto IS NULL OR c.id_soggetto_di_piano = p_id_soggetto)
                  and pa.flg_annullato = 'N'
                  and pa.FLG_SOSPESO = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and c.flg_annullato = 'N'
                  and c.FLG_SOSPESO = 'N'
                  AND c.COD_DISATTIVAZIONE IS NULL
                  and c.id_sala_vendita = sal_ven.id_sala_vendita
                  and sal_ven.id_circuito_sala = cs.id_circuito_sala
                  and cs.id_sala = sa.id_sala
                  and sa.id_cinema = cin.id_cinema
                  and comune.id_comune = cin.id_comune
                  and provincia.id_provincia = comune.id_provincia
                  and regione.id_regione = provincia.id_regione)
           union
          (select
                (select distinct sp.id_soggetto_di_piano from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as ID_SOGGETTO_DI_PIANO,
                (select distinct sp.descrizione from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as DESC_SOGG_DI_PIANO,
                (select distinct sp.COD_SOGG from cd_soggetto_di_piano sp
                    where sp.ID_SOGGETTO_DI_PIANO (+)= c.ID_SOGGETTO_DI_PIANO) as COD_SOGG_DI_PIANO,
                (select distinct MAT.TITOLO from CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
                    where MAT_PIA.ID_MATERIALE_DI_PIANO (+)= c.ID_MATERIALE_DI_PIANO
                    and MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) as TITOLO_MAT,
                c.id_comunicato as ID_COMUNICATO,
                cin.id_cinema as ID_CINEMA,
                cin.nome_cinema as NOME_CINEMA,
                (select comune.comune from cd_comune comune
                        where comune.id_comune = cin.id_comune) as COMUNE_CINEMA,
                provincia.provincia as PROVINCIA_CINEMA,
                regione.nome_regione as REGIONE_CINEMA,
                sa.nome_sala as NOME_AMBIENTE,
                c.data_erogazione_prev as DATA_EROGAZIONE,
                'TA' as luogo,
                c.FLG_ANNULLATO as FLG_ANNULLATO
                from CD_PRODOTTO_ACQUISTATO pa,
                    cd_comunicato c,
                    cd_circuito_break cir_br,
                    cd_cinema cin,
                    cd_sala sa,
                    cd_break_vendita brv,
                    cd_break br,
                    cd_proiezione pr,
                    cd_schermo  sch,
                    CD_COMUNE comune,
                    CD_PROVINCIA provincia,
                    CD_REGIONE regione
                where pa.id_prodotto_acquistato = p_id_prodotto_acquistato
                  and c.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
                  AND c.data_erogazione_prev BETWEEN p_data_erogazione_from AND p_data_erogazione_to
                  AND (p_id_cinema IS NULL OR cin.id_cinema = p_id_cinema)
                  AND (p_id_comune IS NULL OR comune.id_comune = p_id_comune)
                  AND (p_id_provincia IS NULL OR provincia.id_provincia = p_id_provincia)
                  AND (p_id_regione IS NULL OR regione.id_regione = p_id_regione)
                  AND (p_id_soggetto IS NULL OR c.id_soggetto_di_piano = p_id_soggetto)
                  and pa.flg_annullato = 'N'
                  and pa.FLG_SOSPESO = 'N'
                  and pa.COD_DISATTIVAZIONE IS NULL
                  and c.flg_annullato = 'N'
                  and c.FLG_SOSPESO = 'N'
                  AND c.COD_DISATTIVAZIONE IS NULL
                  and c.id_break_vendita = brv.id_break_vendita
                  and brv.id_circuito_break = cir_br.id_circuito_break
                  and br.id_break = cir_br.id_break
                  and pr.id_proiezione = br.id_proiezione
                  and sch.id_schermo = pr.id_schermo
                  and sch.ID_SALA = sa.ID_SALA
                  and sa.ID_CINEMA = cin.ID_CINEMA
                  and comune.id_comune = cin.id_comune
                  and provincia.id_provincia = comune.id_provincia
                  and regione.id_regione = provincia.id_regione)
                  )
                 group by ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, COD_SOGG_DI_PIANO, TITOLO_MAT, ID_CINEMA, NOME_CINEMA,  COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA, NOME_AMBIENTE,DATA_EROGAZIONE,  luogo,  FLG_ANNULLATO;--group by DATA_EROGAZIONE;--, ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, ID_COMUNICATO, ID_CINEMA, NOME_CINEMA,COMUNE_CINEMA, NOME_AMBIENTE, luogo, FLG_ANNULLATO;
--                 order by ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, COD_SOGG_DI_PIANO, TITOLO_MAT, ID_CINEMA, NOME_CINEMA,  COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA, NOME_AMBIENTE,DATA_EROGAZIONE,  luogo,  FLG_ANNULLATO;

-- SELECT id_comunicato,
--               nome_circuito,
--               desc_prodotto,
--               data_erogazione_prev,
--               com.id_soggetto_di_piano,
--               sdp.descrizione,
--               com.flg_annullato
--        FROM cd_comunicato com,
--             cd_prodotto_vendita pv,
--             cd_prodotto_pubb prod_pubb,
--             cd_circuito cir,
--             cd_prodotto_acquistato pa,
--             cd_soggetto_di_piano sdp
--        WHERE pa.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
--        AND   pa.FLG_ANNULLATO = 'N'
--        AND   com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
--        AND   pv.ID_PRODOTTO_VENDITA   = pa.ID_PRODOTTO_VENDITA
--        AND   pv.ID_PRODOTTO_PUBB  = prod_pubb.ID_PRODOTTO_PUBB
--        AND   pv.ID_CIRCUITO       = cir.ID_CIRCUITO
--        AND   sdp.ID_SOGGETTO_DI_PIANO    = com.ID_SOGGETTO_DI_PIANO
--        AND   data_erogazione_prev
--        BETWEEN p_data_erogazione_from AND p_data_erogazione_to;
--
        RETURN v_lista_comunicati_soggetto;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_COMUNICATI_SOGGETTO;

-----------------------------------------------------------------------------------------------------
-- Function FU_GET_ELENCO_CINEMA
--
-- DESCRIZIONE:  Ritorna l'elenco di tutti i cinema
--
--
--
-- REALIZZATORE: Michele Borgogno, Altran, Novembre 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_ELENCO_CINEMA RETURN C_CINEMA IS
v_cinema_return C_CINEMA;
BEGIN
    OPEN v_cinema_return FOR
    SELECT CI.ID_CINEMA, CI.NOME_CINEMA || ' - ' || COM.COMUNE AS NOME_CINEMA
        FROM CD_COMUNE COM, CD_CINEMA CI
        WHERE CI.FLG_ANNULLATO = 'N'
        AND COM.ID_COMUNE = CI.ID_COMUNE
        ORDER BY NOME_CINEMA;

    RETURN v_cinema_return;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
END FU_GET_ELENCO_CINEMA;

-----------------------------------------------------------------------------------------------------
-- Procedure PR_CALCOLA_IMPORTI_SIAE
--
-- DESCRIZIONE:  Calcola gli importi siae per tutti i comunicati compresi nelle date indicate
--
-- INPUT:        data_inizio  Inizio del periodo ricercato OBBLIGATORIO
--               date_fine    Fine del periodo ricercato   OBBLIGATORIO
--               id_cliente    FACOLTATIVO
--               id_soggetto   FACOLTATIVO
--               id_materiale  FACOLTATIVO
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
--  MODIFICHE: Mauro Viel Altran Italia inserita clausola per estrarre le sole sale reali
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CONFERMA_PAGAMENTO_SIAE(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE, p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE, p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE) IS
BEGIN

for comunicati in (select c.id_comunicato, siae.importo_siae
             from vi_cd_pagamento_siae siae, cd_comunicato c
             where siae.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
             and c.id_comunicato = siae.id_comunicato
             and (c.importo_siae != siae.importo_siae)
             and id_cliente = nvl(p_id_cliente, id_cliente)
             and id_soggetto = nvl(p_id_soggetto,id_soggetto)
             and id_materiale = nvl(p_id_materiale, id_materiale)
             and siae.flg_siae = 'S'
             and siae.flg_virtuale = 'N')loop
    update cd_comunicato
    set importo_siae = comunicati.importo_siae,
    data_conferma_siae = trunc(sysdate)
    where id_comunicato = comunicati.id_comunicato;
end loop;
END PR_CONFERMA_PAGAMENTO_SIAE;
--
-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_MATERIALI_SIAE
--
-- DESCRIZIONE:  Restituisce gli importi siae divisi per materiale in un periodo specificato
--
-- INPUT:        data_inizio  Inizio del periodo ricercato OBBLIGATORIO
--               date_fine    Fine del periodo ricercato   OBBLIGATORIO
--               id_cliente    FACOLTATIVO
--               id_soggetto   FACOLTATIVO
--               id_materiale  FACOLTATIVO
--
-- REALIZZATORE: Simone Bottani, Altran, Gennaio 2010
--
-- MODIFICHE:
--   Luigi Cipolla - 01/03/2010
--     Modificato il calcolo del numero schermi.
--   Mauro Viel Altran Italia inserita clausola per estrarre le sole sale reali
-------------------------------------------------------------------------------------------------
FUNCTION FU_MATERIALI_SIAE(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE, p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE, p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE) RETURN C_MATERIALE_SIAE IS
v_materiali_siae C_MATERIALE_SIAE;
BEGIN
   
    OPEN v_materiali_siae FOR
        select pag.id_materiale,pag.cliente,pag.soggetto,pag.titolo_materiale, pag.durata,
        pag.autore,pag.titolo_colonna,pag.flg_siae, count(pag.id_comunicato) as num_passaggi,
        sum(pag.importo_siae_pagato) importo_siae_pagato,
        sum(pag.importo_siae) importo_siae_dovuto, pag.importo_siae,
        count( distinct pag.id_sala) num_schermi,
        mat.causale,
        pag.desc_area,
        mat.nazionalita,
        mat.agenzia_produz,
        mat.descrizione
        from  cd_materiale mat,
              vi_cd_pagamento_siae pag
        where pag.data_erogazione_prev between p_data_inizio and p_data_fine
        and pag.id_cliente = nvl(p_id_cliente, pag.id_cliente)
        and pag.id_soggetto = nvl(p_id_soggetto, pag.id_soggetto)
        and pag.id_materiale = nvl(p_id_materiale, pag.id_materiale)
        and mat.id_materiale = pag.id_materiale
        and pag.flg_virtuale = 'N'
        group by  pag.id_materiale, pag.cliente, pag.soggetto, pag.titolo_materiale, pag.durata,
             pag.autore, pag.titolo_colonna, pag.flg_siae, pag.importo_siae, mat.causale, pag.desc_area, mat.nazionalita, mat.agenzia_produz, mat.descrizione            
        order by pag.cliente;
RETURN v_materiali_siae;
END FU_MATERIALI_SIAE;

-----------------------------------------------------------------------------------------------------
-- FUNCTION FU_CENSURA_MATERIALI_SIAE
--
-- DESCRIZIONE:  Restituisce i materiali per il visto censura
--
-- REALIZZATORE: Michele Borgogno, Altran, Agosto 2010
--
-- MODIFICHE:
--   Tommaso D'Anna, Teoresi srl, 03/12/2010
--     Aggiunto tra i campi restituiti la traduzione del titolo del materiale
-------------------------------------------------------------------------------------------------
FUNCTION FU_CENSURA_MATERIALI_SIAE(p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_cliente CD_MATERIALE.ID_CLIENTE%TYPE, p_id_soggetto CD_MATERIALE_SOGGETTI.COD_SOGG%TYPE, p_id_materiale CD_MATERIALE.ID_MATERIALE%TYPE, p_stato varchar2) RETURN C_CENSURA_MATERIALE_SIAE IS
v_materiali_siae C_CENSURA_MATERIALE_SIAE;
BEGIN
   
    OPEN v_materiali_siae FOR
        select pag.id_materiale,pag.cliente,pag.soggetto,pag.titolo_materiale, pag.durata,
        pag.autore,pag.titolo_colonna,pag.flg_siae, count(pag.id_comunicato) as num_passaggi,
        sum(pag.importo_siae_pagato) importo_siae_pagato,
        sum(pag.importo_siae) importo_siae_dovuto, pag.importo_siae,
        count( distinct pag.id_sala) num_schermi,
        mat.causale,
        pag.desc_area,
        mat.nazionalita,
        mat.agenzia_produz,
        mat.descrizione,
        mat.DATA_AUT_INVIO_MINISTERO,
        mat.DATA_CONSEGNA_MINISTERO,
        mat.DATA_RIL_NULLAOSTA_MINISTERO,
        mat.NUMERO_PROTOCOLLO_MINISTERO,
        mat.TRADUZIONE_TITOLO
        from  cd_materiale mat,
              vi_cd_pagamento_siae pag
        where pag.data_erogazione_prev between p_data_inizio and p_data_fine
        and pag.id_cliente = nvl(p_id_cliente, pag.id_cliente)
        and pag.id_soggetto = nvl(p_id_soggetto, pag.id_soggetto)
        and pag.id_materiale = nvl(p_id_materiale, pag.id_materiale)
        and mat.id_materiale = pag.id_materiale
        and ((p_stato = 'DA' and mat.DATA_AUT_INVIO_MINISTERO is null) 
            or (p_stato = 'AU' and mat.DATA_AUT_INVIO_MINISTERO is not null and mat.DATA_CONSEGNA_MINISTERO is null)
            or (p_stato = 'CO' and mat.DATA_CONSEGNA_MINISTERO is not null and mat.DATA_RIL_NULLAOSTA_MINISTERO is null )
            or (p_stato = 'AP' and mat.DATA_RIL_NULLAOSTA_MINISTERO is not null)
            or (p_stato = 'SM' and mat.descrizione is null)
            or (p_stato is null))
        group by  pag.id_materiale, pag.cliente, pag.soggetto, pag.titolo_materiale, pag.durata,
             pag.autore, pag.titolo_colonna, pag.flg_siae, pag.importo_siae, mat.causale, pag.desc_area, mat.nazionalita, mat.agenzia_produz, mat.descrizione,
             mat.data_aut_invio_ministero, mat.data_consegna_ministero, mat.data_ril_nullaosta_ministero,mat.numero_protocollo_ministero, mat.TRADUZIONE_TITOLO
        order by pag.cliente;
RETURN v_materiali_siae;
END FU_CENSURA_MATERIALI_SIAE;

/*******************************************************************************
 PR_SETTA_VARIABILI
 Author:  Michele Borgogno, Altran, Maggio 2010
 Setta le variabili di package utilizzate dalla function FU_GRUPPI_COMUNICATI

 MODIFICHE
 
*******************************************************************************/

PROCEDURE PR_SETTA_VARIABILI_COM (P_ID_PRODOTTO_ACQUISTATO IN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
								P_DATA_EROGAZIONE_FROM IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                        P_DATA_EROGAZIONE_TO IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                        P_ID_REGIONE IN CD_REGIONE.ID_REGIONE%TYPE,
		                        P_ID_PROVINCIA IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
		                        P_ID_COMUNE IN CD_COMUNE.ID_COMUNE%TYPE,
		                        P_ID_CINEMA IN CD_CINEMA.ID_CINEMA%TYPE,
		                        P_ID_SOGGETTO IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE) is
begin

 	V_ID_PRODOTTO_ACQUISTATO := P_ID_PRODOTTO_ACQUISTATO;
 	V_DATA_EROGAZIONE_FROM   := P_DATA_EROGAZIONE_FROM;
 	V_DATA_EROGAZIONE_TO     := P_DATA_EROGAZIONE_TO;
 	V_ID_REGIONE             := P_ID_REGIONE;
 	V_ID_PROVINCIA           := P_ID_PROVINCIA;
	V_ID_COMUNE							 := P_ID_COMUNE;
	V_ID_CINEMA              := P_ID_CINEMA;
	V_ID_SOGGETTO            := P_ID_SOGGETTO;
end;
--
--
FUNCTION FU_RIT_PROD_ACQUISTATO RETURN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE IS
begin

	RETURN V_ID_PRODOTTO_ACQUISTATO;
END;
--
--
FUNCTION FU_DATA_DA   RETURN   DATE is
begin
	return V_DATA_EROGAZIONE_FROM;
end;
--
--
FUNCTION FU_DATA_A   RETURN   DATE is
begin
	return V_DATA_EROGAZIONE_TO;
end;
--
--
FUNCTION FU_REGIONE   RETURN   CD_REGIONE.ID_REGIONE%TYPE IS
BEGIN
	return V_ID_REGIONE;
END;
--
-- 
FUNCTION FU_PROVINCIA	RETURN   CD_PROVINCIA.ID_PROVINCIA%TYPE is
BEGIN
	return    V_ID_PROVINCIA;

END; 
--
-- 
FUNCTION FU_COMUNE    RETURN	  CD_COMUNE.ID_COMUNE%TYPE is
begin
	return V_ID_COMUNE;
end; 
-- 
-- 
FUNCTION FU_CINEMA    RETURN	  CD_CINEMA.ID_CINEMA%TYPE is
begin
	return V_ID_CINEMA;
end; 
-- 
-- 
FUNCTION FU_SOGGETTO    RETURN	  CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE is
begin
	return V_ID_SOGGETTO;
end; 

/*******************************************************************************
 FU_GRUPPI_COMUNICATI
 Author:  Michele Borgogno, Altran, Maggio 2010
 FUNZIONE CHE POPOLA LA VISTA VI_CD_GRUPPI_COMUNICATI

 MODIFICHE
 
*******************************************************************************/
FUNCTION  FU_GRUPPI_COMUNICATI ( P_ID_PRODOTTO_ACQUISTATO IN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
										P_DATA_EROGAZIONE_FROM IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                                P_DATA_EROGAZIONE_TO IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                                P_ID_REGIONE IN CD_REGIONE.ID_REGIONE%TYPE,
		                                P_ID_PROVINCIA IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
		                                P_ID_COMUNE IN CD_COMUNE.ID_COMUNE%TYPE,
		                                P_ID_CINEMA IN CD_CINEMA.ID_CINEMA%TYPE,
		                                P_ID_SOGGETTO IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE
		                                )
				RETURN TAB_GRUPPI_COM PIPELINED IS
    --
    IND_TAB NUMBER;
    STR_COMUNICATO VARCHAR2(3200);
    V_REC_GRUPPI_COM REC_GRUPPI_COM;

		CURSOR C_GRUPPI_COM IS
			SELECT ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, COD_SOGG_DI_PIANO, TITOLO_MAT,ID_COMUNICATO, ID_CINEMA,NOME_CINEMA,  COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA, NOME_AMBIENTE,DATA_EROGAZIONE,  LUOGO,  FLG_ANNULLATO
				FROM (
			            SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                CIN.NOME_CINEMA AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'CI' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO C,
			                     CD_CINEMA_VENDITA CIN_VEN, CD_CIRCUITO_CINEMA CIR_CIN,
			                     CD_CINEMA CIN,
			                     CD_COMUNE COMUNE,
			                     CD_PROVINCIA PROVINCIA,
			                     CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO (+)= PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_CINEMA_VENDITA = CIN_VEN.ID_CINEMA_VENDITA
			                  AND CIN_VEN.ID_CIRCUITO_CINEMA = CIR_CIN.ID_CIRCUITO_CINEMA
			                  AND CIR_CIN.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE
			           UNION
			          (SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                ATR.DESC_ATRIO AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'AT' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO C,
			                     CD_ATRIO_VENDITA AT_VEN, CD_CIRCUITO_ATRIO CA,
			                     CD_ATRIO ATR, CD_CINEMA CIN,
			                     CD_COMUNE COMUNE,
			                     CD_PROVINCIA PROVINCIA,
			                     CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO (+)= PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_ATRIO_VENDITA = AT_VEN.ID_ATRIO_VENDITA
			                  AND AT_VEN.ID_CIRCUITO_ATRIO = CA.ID_CIRCUITO_ATRIO
			                  AND CA.ID_ATRIO = ATR.ID_ATRIO
			                  AND ATR.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE)
			           UNION
			          (SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                SA.NOME_SALA AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'SA' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO C,
			                     CD_SALA_VENDITA SAL_VEN, CD_CIRCUITO_SALA CS,
			                     CD_SALA SA, CD_CINEMA CIN,
			                     CD_COMUNE COMUNE,
			                     CD_PROVINCIA PROVINCIA,
			                     CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO (+)= PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_SALA_VENDITA = SAL_VEN.ID_SALA_VENDITA
			                  AND SAL_VEN.ID_CIRCUITO_SALA = CS.ID_CIRCUITO_SALA
			                  AND CS.ID_SALA = SA.ID_SALA
			                  AND SA.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE)
			           UNION
			          (SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                SA.NOME_SALA AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'TA' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA,
			                    CD_COMUNICATO C,
			                    CD_CIRCUITO_BREAK CIR_BR,
			                    CD_CINEMA CIN,
			                    CD_SALA SA,
			                    CD_BREAK_VENDITA BRV,
			                    CD_BREAK BR,
			                    CD_PROIEZIONE PR,
			                    CD_SCHERMO  SCH,
			                    CD_COMUNE COMUNE,
			                    CD_PROVINCIA PROVINCIA,
			                    CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_BREAK_VENDITA = BRV.ID_BREAK_VENDITA
			                  AND BRV.ID_CIRCUITO_BREAK = CIR_BR.ID_CIRCUITO_BREAK
			                  AND BR.ID_BREAK = CIR_BR.ID_BREAK
			                  AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
			                  AND SCH.ID_SCHERMO = PR.ID_SCHERMO
			                  AND SCH.ID_SALA = SA.ID_SALA
			                  AND SA.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE)
			                  )
				order by        id_cinema,data_erogazione,nome_ambiente,cod_sogg_di_piano,titolo_mat,id_comunicato;
			--
BEGIN
			ind_tab := 0;
			--
			FOR r IN C_GRUPPI_COM	LOOP
			--
				tab_temp(ind_tab).ID_SOGGETTO_DI_PIANO := 	r.ID_SOGGETTO_DI_PIANO;
			  tab_temp(ind_tab).DESC_SOGG_DI_PIANO	 :=	r.DESC_SOGG_DI_PIANO;
			  tab_temp(ind_tab).COD_SOGG_DI_PIANO    :=	r.COD_SOGG_DI_PIANO;
			  tab_temp(ind_tab).TITOLO_MAT           :=	r.TITOLO_MAT;
			  tab_temp(ind_tab).ID_CINEMA            :=	r.ID_CINEMA;
			  tab_temp(ind_tab).NOME_CINEMA          :=	r.NOME_CINEMA;
			  tab_temp(ind_tab).COMUNE_CINEMA				 :=	r.COMUNE_CINEMA;
			  tab_temp(ind_tab).PROVINCIA_CINEMA     :=	r.PROVINCIA_CINEMA;
			  tab_temp(ind_tab).REGIONE_CINEMA       :=	r.REGIONE_CINEMA;
				tab_temp(ind_tab).NOME_AMBIENTE        :=	r.NOME_AMBIENTE;
				tab_temp(ind_tab).DATA_EROGAZIONE      :=	r.DATA_EROGAZIONE;
				tab_temp(ind_tab).LUOGO                :=	r.LUOGO;
				tab_temp(ind_tab).FLG_ANNULLATO        :=	r.FLG_ANNULLATO;
    		tab_temp(ind_tab).ID_COMUNICATO				 :=  r.ID_COMUNICATO;
    		--
  			if ind_tab >0 then
  				IF tab_temp(ind_tab).ID_SOGGETTO_DI_PIANO = tab_temp(ind_tab-1).ID_SOGGETTO_DI_PIANO 	AND
  				   tab_temp(ind_tab).COD_SOGG_DI_PIANO    = tab_temp(ind_tab-1).COD_SOGG_DI_PIANO     AND
  				   nvl(tab_temp(ind_tab).TITOLO_MAT, 'XXXX') = nvl(tab_temp(ind_tab-1).TITOLO_MAT, 'XXXX')	AND
  				   tab_temp(ind_tab).ID_CINEMA            = tab_temp(ind_tab-1).ID_CINEMA               AND
  				   tab_temp(ind_tab).DATA_EROGAZIONE      = tab_temp(ind_tab-1).DATA_EROGAZIONE         AND
  				   tab_temp(ind_tab).NOME_AMBIENTE        = tab_temp(ind_tab-1).NOME_AMBIENTE            AND
  				   tab_temp(ind_tab).LUOGO                = tab_temp(ind_tab-1).LUOGO
  			    THEN    --> se siamo sullo stesso raggruppamento devo concatenare id_comunicato
  			  	
  			  	 STR_COMUNICATO := STR_COMUNICATO||'_'||tab_temp(ind_tab).ID_COMUNICATO;
  				ELSE   -- scrivo il record sulla tavola pipelined (rottura di record)
  					V_REC_GRUPPI_COM.ID_SOGGETTO_DI_PIANO 	:=   	tab_temp(ind_tab-1).ID_SOGGETTO_DI_PIANO;
  					V_REC_GRUPPI_COM.DESC_SOGG_DI_PIANO		  :=	  tab_temp(ind_tab-1).DESC_SOGG_DI_PIANO;
  					V_REC_GRUPPI_COM.COD_SOGG_DI_PIANO      :=		tab_temp(ind_tab-1).COD_SOGG_DI_PIANO;
  					V_REC_GRUPPI_COM.TITOLO_MAT             :=   	tab_temp(ind_tab-1).TITOLO_MAT;
  					V_REC_GRUPPI_COM.ID_STR_COMUNICATO      :=   	ltrim(STR_COMUNICATO,'_');
  					V_REC_GRUPPI_COM.ID_CINEMA              :=  	tab_temp(ind_tab-1).ID_CINEMA;
  					V_REC_GRUPPI_COM.NOME_CINEMA            :=   	tab_temp(ind_tab-1).NOME_CINEMA;
  					V_REC_GRUPPI_COM.COMUNE_CINEMA          :=   	tab_temp(ind_tab-1).COMUNE_CINEMA;
  					V_REC_GRUPPI_COM.PROVINCIA_CINEMA       :=   	tab_temp(ind_tab-1).PROVINCIA_CINEMA;
  					V_REC_GRUPPI_COM.REGIONE_CINEMA         :=   	tab_temp(ind_tab-1).REGIONE_CINEMA;
  					V_REC_GRUPPI_COM.NOME_AMBIENTE          :=   	tab_temp(ind_tab-1).NOME_AMBIENTE;
  					V_REC_GRUPPI_COM.DATA_EROGAZIONE        :=   	tab_temp(ind_tab-1).DATA_EROGAZIONE;
  					V_REC_GRUPPI_COM.LUOGO                  :=   	tab_temp(ind_tab-1).LUOGO;
  					V_REC_GRUPPI_COM.FLG_ANNULLATO          :=   	tab_temp(ind_tab-1).FLG_ANNULLATO;
  				  --
  				  pipe ROW(V_REC_GRUPPI_COM);

  				  STR_COMUNICATO := to_char(null);
  				  STR_COMUNICATO := STR_COMUNICATO||'_'||tab_temp(ind_tab).ID_COMUNICATO;

  				END IF;
  			else
  				STR_COMUNICATO := STR_COMUNICATO||'_'||tab_temp(ind_tab).ID_COMUNICATO;   -- inizializzo la stringas
  			end if;
  			--
  			--
  			ind_tab := ind_tab + 1;
  		END LOOP;
      -- SONO ARRIVATO ALL'ULTIMA OCCORRRENZA RIPORTO INDIENTRO L'INDICE
      --
      V_REC_GRUPPI_COM.ID_SOGGETTO_DI_PIANO 	:=   	tab_temp(ind_tab-1).ID_SOGGETTO_DI_PIANO;
			V_REC_GRUPPI_COM.DESC_SOGG_DI_PIANO		  :=	  tab_temp(ind_tab-1).DESC_SOGG_DI_PIANO;
			V_REC_GRUPPI_COM.COD_SOGG_DI_PIANO      :=		tab_temp(ind_tab-1).COD_SOGG_DI_PIANO;
			V_REC_GRUPPI_COM.TITOLO_MAT             :=   	tab_temp(ind_tab-1).TITOLO_MAT;
			V_REC_GRUPPI_COM.ID_STR_COMUNICATO      :=  	ltrim(STR_COMUNICATO,'_');
			V_REC_GRUPPI_COM.ID_CINEMA              :=   	tab_temp(ind_tab-1).ID_CINEMA;
			V_REC_GRUPPI_COM.NOME_CINEMA            :=   	tab_temp(ind_tab-1).NOME_CINEMA;
			V_REC_GRUPPI_COM.COMUNE_CINEMA          :=   	tab_temp(ind_tab-1).COMUNE_CINEMA;
			V_REC_GRUPPI_COM.PROVINCIA_CINEMA       :=   	tab_temp(ind_tab-1).PROVINCIA_CINEMA;
			V_REC_GRUPPI_COM.REGIONE_CINEMA         :=   	tab_temp(ind_tab-1).REGIONE_CINEMA;
			V_REC_GRUPPI_COM.NOME_AMBIENTE          :=   	tab_temp(ind_tab-1).NOME_AMBIENTE;
			V_REC_GRUPPI_COM.DATA_EROGAZIONE        :=   	tab_temp(ind_tab-1).DATA_EROGAZIONE;
			V_REC_GRUPPI_COM.LUOGO                  :=   	tab_temp(ind_tab-1).LUOGO;
			V_REC_GRUPPI_COM.FLG_ANNULLATO          :=   	tab_temp(ind_tab-1).FLG_ANNULLATO;
  				  --
  				  pipe ROW(V_REC_GRUPPI_COM);

          --  open Result for select * from table(TAB_SOGG);

   return;
END FU_GRUPPI_COMUNICATI;
    
/*******************************************************************************
 FU_LISTA_GRUPPI_COMUNICATI
 Author:  Michele Borgogno, Altran, Maggio 2010
 FUNZIONE CHE RITORNA LA VISTA DEI GRUPPI DI COMUNICATI DA VI_CD_GRUPPI_COMUNICATI

 MODIFICHE
 
*******************************************************************************/
FUNCTION  FU_LISTA_GRUPPI_COMUNICATI(p_id_prodotto_acquistato IN CD_COMUNICATO.id_prodotto_acquistato%TYPE,
                                     p_data_erogazione_from IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                     p_data_erogazione_to IN CD_COMUNICATO.data_erogazione_prev%TYPE,
                                     p_id_regione IN CD_REGIONE.ID_REGIONE%TYPE,
                                     p_id_provincia IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
                                     p_id_comune IN CD_COMUNE.ID_COMUNE%TYPE,
                                     p_id_cinema IN CD_CINEMA.id_cinema%TYPE,
                                     p_id_soggetto IN CD_SOGGETTO_DI_PIANO.id_soggetto_di_piano%TYPE
                                     ) RETURN C_GRUPPI_COM IS
--   
    v_lista_gruppi_comunicati C_GRUPPI_COM;   
BEGIN    
    PR_SETTA_VARIABILI_COM(p_id_prodotto_acquistato,p_data_erogazione_from,p_data_erogazione_to,
		               p_id_regione,p_id_provincia,p_id_comune,p_id_cinema,p_id_soggetto);
--
    OPEN v_lista_gruppi_comunicati FOR
        select ID_SOGGETTO_DI_PIANO,DESC_SOGG_DI_PIANO,COD_SOGG_DI_PIANO,TITOLO_MAT,ID_STR_COMUNICATO,
               ID_CINEMA,NOME_CINEMA,COMUNE_CINEMA,PROVINCIA_CINEMA,REGIONE_CINEMA,NOME_AMBIENTE,
               DATA_EROGAZIONE,LUOGO,FLG_ANNULLATO
        from VI_CD_GRUPPI_COMUNICATI
        order by ID_SOGGETTO_DI_PIANO,DESC_SOGG_DI_PIANO,COD_SOGG_DI_PIANO,TITOLO_MAT,ID_CINEMA,NOME_CINEMA,COMUNE_CINEMA,PROVINCIA_CINEMA,REGIONE_CINEMA,NOME_AMBIENTE,DATA_EROGAZIONE,LUOGO,FLG_ANNULLATO;
        
        RETURN v_lista_gruppi_comunicati;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE;
      WHEN OTHERS THEN
      RAISE;
  END FU_LISTA_GRUPPI_COMUNICATI;

 END PA_CD_COMUNICATO; 
/

