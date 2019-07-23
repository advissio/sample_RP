CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SPETTACOLO IS
--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_SPETTACOLO
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo spettacolo nel sistema
--               Usata nell'anagrafica spettacoli e nell'applicazione gestori cinema
--
-- OPERAZIONI:
-- 1) Memorizza lo spettacolo (CD_SPETTACOLO)
--
-- INPUT: parametri di inserimento di un nuovo spettacolo
--
-- OUTPUT: esito:
--    n  id_spettacolo del record inserito
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
--            Aggiunto inserimento dei target associati allo spettacolo.
--            Simone Bottani, Altran, Giugno 2010
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SPETTACOLO( p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                   p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                                   p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                                   p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
								   p_id_genere         CD_SPETTACOLO.ID_GENERE%TYPE,
                                   p_id_distributore   CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE,
                                   p_flg_protetto      CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                   p_id_gestore        CD_SPETTACOLO.ID_GESTORE%TYPE,
                                   p_target            id_list_type,
                                   p_esito             OUT NUMBER)
IS
BEGIN -- PR_INSERISCI_SPETTACOLO
    p_esito     := 1;
    SAVEPOINT ann_ins;
    INSERT INTO CD_SPETTACOLO
        (NOME_SPETTACOLO,
         DURATA_SPETTACOLO,
         DATA_INIZIO,
         DATA_FINE,
         ID_GENERE,
         ID_DISTRIBUTORE,
         FLG_PROTETTO,
         ID_GESTORE,
         PROVENIENZA
		)
       VALUES
         (UPPER(p_nome_spettacolo),
          p_durata_spettacolo,
          trunc(p_data_inizio),
          p_data_fine,
          p_id_genere,
          p_id_distributore,
          p_flg_protetto,
          p_id_gestore,
          CASE
            WHEN p_id_gestore IS NULL THEN 'SIPRA'
            ELSE 'GESTORE'
          END
         );
    SELECT CD_SPETTACOLO_SEQ.CURRVAL INTO p_esito FROM DUAL;
    PA_CD_TARGET.PR_ASSOCIA_TARGET_SPET_MASS(p_esito, p_target);
--
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_INSERISCI_SPETTACOLO: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_SPETTACOLO(p_nome_spettacolo,
                                                                                                                                                              p_durata_spettacolo,
                                                                                                                                                              p_data_inizio,
                                                                                                                                                              p_data_fine,
																																							  'ID_GENERE: '  || to_char(p_id_genere)));
        ROLLBACK TO ann_ins;
--
END;
--
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_SPETTACOLO
--
-- DESCRIZIONE:  Esegue l'aggiornamento di uno spettacolo; se vengono passati alcuni dei
--  parametri di input con valore Null tale valore sara' inserito su db al posto di quello
--  eventualmente gia' presente
--
-- OPERAZIONI:
--   Update
--
-- INPUT: parametri dello spettacolo
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Update non eseguita: i parametri per l'Update non sono coerenti
--
-- REALIZZATORE: Daniela Spezia, Altran, Gennaio 2010
--
--  MODIFICHE:
--            Aggiunta la modifica dei target associati allo spettacolo.
--            Simone Bottani, Altran, Giugno 2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_SPETTACOLO( p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                  p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                  p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                                  p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                                  p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
								  p_id_genere         CD_SPETTACOLO.ID_GENERE%TYPE,
                                  p_id_distributore   CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE,
                                  p_flg_protetto      CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                  p_target            id_list_type,
                                  p_esito             OUT NUMBER)
IS
v_flg_protetto_old CD_SPETTACOLO.FLG_PROTETTO%TYPE;
--
BEGIN
    p_esito := 1;
    SAVEPOINT ann_upd;
    SELECT FLG_PROTETTO INTO v_flg_protetto_old FROM CD_SPETTACOLO
    WHERE ID_SPETTACOLO = P_ID_SPETTACOLO;
    IF(V_FLG_PROTETTO_OLD<>P_FLG_PROTETTO)THEN
       for elenco_proiezioni in (select distinct id_proiezione 
                                    from cd_proiezione_spett 
                                    where id_spettacolo = p_id_spettacolo
                                )loop
       update cd_proiezione_spett
       set id_proiezione = fu_dammi_proiezione_gemella(elenco_proiezioni.id_proiezione)
       where id_proiezione = elenco_proiezioni.id_proiezione
       and   id_spettacolo = p_id_spettacolo;
        end loop;                                
    END IF;
    UPDATE CD_SPETTACOLO
        SET
		    NOME_SPETTACOLO = p_nome_spettacolo,
            DURATA_SPETTACOLO = p_durata_spettacolo,
            DATA_INIZIO = p_data_inizio,
            DATA_FINE = p_data_fine,
            ID_GENERE = p_id_genere,
            ID_DISTRIBUTORE = p_id_distributore,
            FLG_PROTETTO = p_flg_protetto
        WHERE ID_SPETTACOLO = p_id_spettacolo;
    PA_CD_TARGET.PR_ASSOCIA_TARGET_SPET_MASS(p_id_spettacolo, p_target);
    p_esito := SQL%ROWCOUNT;
--
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'Procedura PR_MOD_SPETT_CON_NULL: Update non eseguita, '|| SQLERRM || ' - parametri di input: '||FU_STAMPA_SPETTACOLO(p_nome_spettacolo,
                                                                                                                                                              p_durata_spettacolo,
                                                                                                                                                              p_data_inizio,
                                                                                                                                                              p_data_fine,
																																							  p_id_genere));
        ROLLBACK TO ann_upd;
END;
--
------------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_SPETTACOLO
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di uno spettacolo dal sistema
--
-- OPERAZIONI:
--   1) Elimina lo spettacolo
--
-- INPUT:
--      p_id_spettacolo     id dello spettacolo
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: 
--            Aggiunta l'eliminazione dei target associati allo spettacolo.
--            Simone Bottani, Altran, Giugno 2010
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SPETTACOLO(p_id_spettacolo     IN CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                p_esito             OUT NUMBER)
IS
--
--
BEGIN -- PR_ELIMINA_SPETTACOLO
--
--
p_esito     := 1;
     --
          SAVEPOINT ann_del;
--
       -- effettua l'ELIMINAZIONE
       DELETE FROM CD_SPETT_TARGET
       WHERE ID_SPETTACOLO = p_id_spettacolo;
       --
       DELETE FROM CD_SPETTACOLO
       WHERE ID_SPETTACOLO = p_id_spettacolo;
       --
    p_esito := SQL%ROWCOUNT;
--
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20012, 'Procedura PR_ELIMINA_SPETTACOLO: Delete non eseguita, verificare la coerenza dei parametri:'||sqlerrm);
        ROLLBACK TO ann_del;
--
END;
--
------------------------------------------------------------------------------------------------------
-- Procedura  PR_ELIMINA_RIMPIAZZA
--
-- DESCRIZIONE: Esegue l'eliminazione dello spettacolo identificato da idElimina
--              ed eventualmente rimpiazza lo stesso con idRimpiazza laddove 
--              compare idElimina nelle associaziative o chiavi esterne  
--
-- OPERAZIONI:
--   1)Controlla presenza di idElimina in CD_SPETTATORI_EFF ed eventualmente lo 
--     rimpiazza con idRimpiazza  
--   2)Controlla presenza di idElimina in GESTORI_PROGRAMMAZIONE ed eventualmente lo
--      rimpiazza cin idRimpiazza
--   3)Controlla presenza di idElimina in CD_PROIEZIONE_SPETT ed eventualmente lo
--      rimpiazza con idRimpiazza
--   4)Elimina lo spettacolo identificato da idElimina da CD_SPETTACOLO
--
-- INPUT:
--      p_id_elimina     id dello spettacolo da eliminare
--      p_id_rimpiazza   id dello spettacolo con il quale rimpiazzare
--
-- OUTPUT: esito:
--    >0 operazione eseguita con successo
--   <0  eliminazione non eseguita. si sono verificati degli errori
--
-- REALIZZATORE: Abntonio Colucci, Teoresi srl, 24 Maggio 2010
--
--  MODIFICHE: Mauro  Viel , Altran, Luglio  2010 inserita gestione del target MV01
--             Antonio Colucci, TeoresiGroup srl, Febbraio 2011
--                  Inserita gestione dello spettacolo nel prodotto_acquistato per il prodotto SEGUI IL FILM
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_RIMPIAZZA(   p_id_elimina          IN CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                  p_id_rimpiazza        IN CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                  p_esito               OUT NUMBER)
IS
v_flg_protetto_new cd_spettacolo.FLG_PROTETTO%type;
v_flg_protetto_old cd_spettacolo.FLG_PROTETTO%type;
v_spet_target number := 0;
--
--
BEGIN -- PR_ELIMINA_SPETTACOLO
--
--
p_esito     := 1;
--
    
     SAVEPOINT ann_del_rimp;
     /*Adatto le proiezioni associate allo spettacolo
     da eliminare prima di rimpiazzare 
     nel caso ci siano differenze nel flg_protetto*/
    select flg_protetto into v_flg_protetto_new
    from cd_spettacolo where id_spettacolo = p_id_rimpiazza;
    select flg_protetto into v_flg_protetto_old
    from cd_spettacolo where id_spettacolo = p_id_elimina;
    if(v_flg_protetto_new<>v_flg_protetto_old)then
        for elenco_proiezioni in (select distinct id_proiezione 
                                    from cd_proiezione_spett 
                                    where id_spettacolo = p_id_elimina
                                )loop
       update cd_proiezione_spett
       set id_proiezione = fu_dammi_proiezione_gemella(elenco_proiezioni.id_proiezione)
       where id_proiezione = elenco_proiezioni.id_proiezione
       and   id_spettacolo = p_id_elimina;
        end loop;      
    end if;
    
--
     /*Modifico tutte le rilevazioni di cinetel per il numero degli spettatori
     associate all'p_id_elimina con il n uovo p_id_rimpiazza */
     UPDATE CD_SPETTATORI_EFF
     SET ID_SPETTACOLO = p_id_rimpiazza
     WHERE ID_SPETTACOLO = p_id_elimina;
--     
     /*Modifico tutte le programmazioni filmiche insertie dai gestori
     rimpiazzando il p_id_elimina con p_id_rimpiazza*/
     UPDATE GESTORI_PROGRAMMAZIONE
     SET ID_SPETTACOLO = p_id_rimpiazza
     WHERE ID_SPETTACOLO = p_id_elimina;
     
     /*Modifico tutte le associazioni proiezioni-spettacoli 
     rimpiazzando il p_id_elimina con p_id_rimpiazza*/
     update CD_PROIEZIONE_SPETT
     SET ID_SPETTACOLO = p_id_rimpiazza
     WHERE ID_SPETTACOLO = p_id_elimina;
     /*procedo con l'aggiornamento dello spettacolo anche sulla
     tavola cd_prodotto_acquistato*/
     update cd_prodotto_acquistato
     set ID_SPETTACOLO = p_id_rimpiazza
     WHERE ID_SPETTACOLO = p_id_elimina;
     /*Dopo aver eliminato/rimpiazzato tutte le associazioni di p_id_elimina
     procedo con eliminazione fisica del film selezionato 
     con anche tutti target associati*/
     delete from cd_spett_target 
     where id_spettacolo = p_id_elimina;
     
     DELETE FROM CD_SPETTACOLO
     WHERE ID_SPETTACOLO = p_id_elimina;
--
  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20012, 'Procedura PR_ELIMINA_RIMPIAZZA: Sostituzione non eseguita:'||sqlerrm);
        p_esito := -1;
        ROLLBACK TO ann_del_rimp;
--
END;
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_SPETTACOLO
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- INPUT: parametri dello spettacolo
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SPETTACOLO(p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                              p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                              p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                              p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
							  p_desc_genere       CD_GENERE.DESC_GENERE%TYPE)
							  RETURN VARCHAR2
IS
--
BEGIN
--
    IF v_stampa_spettacolo = 'ON'
        THEN
          RETURN 'NOME_SPETTACOLO: '   || p_nome_spettacolo   || ', ' ||
                'DURATA_SPETTACOLO: ' || p_durata_spettacolo || ', ' ||
                'DATA_INIZIO: '       || p_data_inizio       || ', ' ||
                'DATA_FINE: '         || p_data_fine         || ', ' || p_desc_genere;
         END IF;
--
END  FU_STAMPA_SPETTACOLO;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_SPETTACOLO
-- --------------------------------------------------------------------------------------------
-- INPUT:  Criteri di ricerca degli spettacoli
-- OUTPUT: Restituisce gli spettacoli che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_SPETTACOLO(p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                             p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                             p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                             p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
							 p_desc_genere       CD_GENERE.DESC_GENERE%TYPE)
							 RETURN C_SPETTACOLO
IS
    c_spettacolo_return C_SPETTACOLO;
BEGIN
    OPEN c_spettacolo_return
        FOR
            SELECT  SPETT.ID_SPETTACOLO, SPETT.NOME_SPETTACOLO, SPETT.DURATA_SPETTACOLO,
			        SPETT.DATA_INIZIO, SPETT.DATA_FINE, GEN.DESC_GENERE, 
                    SPETT.PROVENIENZA as PROVENIENZA
            FROM    CD_SPETTACOLO SPETT, CD_GENERE GEN
			WHERE   (p_nome_spettacolo IS NULL OR SPETT.NOME_SPETTACOLO LIKE '%'||p_nome_spettacolo||'%')
                AND (p_durata_spettacolo IS NULL OR SPETT.DURATA_SPETTACOLO = p_durata_spettacolo)
                AND (p_data_inizio IS NULL OR SPETT.DATA_INIZIO >= p_data_inizio)
                AND (p_data_fine IS NULL OR SPETT.DATA_FINE  <= p_data_fine OR SPETT.DATA_FINE IS NULL)
				AND (p_desc_genere IS NULL OR GEN.DESC_GENERE  LIKE '%'|| p_desc_genere ||'%')
				AND (SPETT.ID_GENERE = GEN.ID_GENERE(+))
                ORDER BY SPETT.NOME_SPETTACOLO;
--
    RETURN c_spettacolo_return;
    EXCEPTION
		WHEN OTHERS THEN
		    RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_CERCA_SPETTACOLO: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_SPETTACOLO(p_nome_spettacolo,
                                                                                                                                                              p_durata_spettacolo,
                                                                                                                                                              p_data_inizio,
                                                                                                                                                              p_data_fine,
																																							  'DESC_GENERE: '  || p_desc_genere));
--
END FU_CERCA_SPETTACOLO;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DETTAGLIO_SPETTACOLO
-- --------------------------------------------------------------------------------------------
-- INPUT:  identificativo dello spettacolo
-- OUTPUT: Restituisce il dettaglio dello spettacolo specificato in input
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Maggio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_SPETTACOLO(p_id_spettacolo   CD_SPETTACOLO.ID_SPETTACOLO%TYPE)
							 RETURN C_DETTAGLIO_SPETTACOLO
IS
    c_dettaglio_return C_DETTAGLIO_SPETTACOLO;
BEGIN
    OPEN c_dettaglio_return
        FOR 
            select 
                CD_SPETTACOLO.ID_SPETTACOLO, CD_SPETTACOLO.NOME_SPETTACOLO,
                CD_SPETTACOLO.DURATA_SPETTACOLO,CD_SPETTACOLO.DATA_INIZIO,
                CD_SPETTACOLO.DATA_FINE, CD_GENERE.DESC_GENERE,
                CD_SPETTACOLO.FLG_PROTETTO, CD_DISTRIBUTORE.ID_DISTRIBUTORE,
                CD_DISTRIBUTORE.CASA_DISTRIBUZIONE, CD_GENERE.ID_GENERE, CD_SPETTACOLO.PROVENIENZA
            from
                cd_spettacolo, cd_genere, cd_distributore
            where
                    cd_spettacolo.id_spettacolo = p_id_spettacolo
                and cd_spettacolo.id_genere = cd_genere.id_genere (+)
                and cd_spettacolo.id_distributore = cd_distributore.id_distributore (+);
--
    RETURN c_dettaglio_return;
    EXCEPTION
		WHEN OTHERS THEN
		    RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_DETTAGLIO_SPETTACOLO: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI :'||sqlerrm);
--
END FU_DETTAGLIO_SPETTACOLO;
--
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_GENERE
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo genere nel sistema
--
-- OPERAZIONI:
-- 1) Memorizza il genere in CD_GENERE
--
-- INPUT: parametri di inserimento di un nuovo genere
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_GENERE(p_desc_genere     CD_GENERE.DESC_GENERE%TYPE,
                              p_id_genere_padre CD_GENERE.ID_GENERE_PADRE%TYPE,
                              p_flg_protetto    CD_GENERE.FLG_PROTETTO%TYPE,
                              p_esito             OUT NUMBER)
IS
BEGIN
    p_esito     := 1;
    SAVEPOINT SP_PR_INSERISCI_GENERE;
    INSERT INTO CD_GENERE
        (DESC_GENERE,
         ID_GENERE_PADRE,
         FLG_PROTETTO
		)
       VALUES
         (UPPER(p_desc_genere),
          p_id_genere_padre,
          p_flg_protetto
         );
--
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_INSERISCI_GENERE: Insert non eseguita, SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
        ROLLBACK TO SP_PR_INSERISCI_GENERE;
END;
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_GENERE
--
-- DESCRIZIONE:  Esegue l'aggiornamento di un genere
--
-- OPERAZIONI:
--   Update
--
-- INPUT: parametri del genere
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Update non eseguita: i parametri per l'Update non sono coerenti
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_GENERE(p_id_genere       CD_GENERE.ID_GENERE%TYPE,
                             p_desc_genere     CD_GENERE.DESC_GENERE%TYPE,
                             p_id_genere_padre CD_GENERE.ID_GENERE_PADRE%TYPE,
                             p_flg_protetto    CD_GENERE.FLG_PROTETTO%TYPE,
                             p_esito             OUT NUMBER)
IS
--
BEGIN
    p_esito := 1;
    SAVEPOINT ann_upd;
    UPDATE CD_GENERE
        SET
		    DESC_GENERE = (nvl(UPPER(p_desc_genere), DESC_GENERE)),
            ID_GENERE_PADRE = (nvl(p_id_genere_padre, ID_GENERE_PADRE)),
            FLG_PROTETTO = (nvl(p_flg_protetto, FLG_PROTETTO))
        WHERE ID_GENERE = p_id_genere;
    p_esito := SQL%ROWCOUNT;
--
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'Procedura PR_MODIFICA_GENERE: Update non eseguita, SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
        ROLLBACK TO ann_upd;
END;
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_GENERE
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un genere dal sistema
--
-- OPERAZIONI:
--   1) Elimina il genere
--
-- INPUT:
--      p_id_genere     id del genere
--
-- OUTPUT: esito:
--    n  numero di records eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_GENERE(p_id_genere  CD_GENERE.ID_GENERE%TYPE,
                            p_esito      OUT NUMBER)
IS
--
BEGIN
    p_esito     := 1;
    SAVEPOINT ann_del;
    DELETE FROM CD_GENERE
       WHERE ID_GENERE = p_id_genere;
 --
	p_esito := SQL%ROWCOUNT;
--
    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20012, 'Procedura PR_ELIMINA_GENERE: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
        ROLLBACK TO ann_del;
END;
 --
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_GENERE
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- INPUT: parametri del genere
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_GENERE(p_desc_genere     CD_GENERE.DESC_GENERE%TYPE,
                          p_id_genere_padre CD_GENERE.ID_GENERE_PADRE%TYPE)
						  RETURN VARCHAR2
IS
--
BEGIN
    IF v_stampa_genere = 'ON'
        THEN
         RETURN 'DESC_GENERE: '     || p_desc_genere   || ', ' ||
                'ID_GENERE_PADRE: ' || p_id_genere_padre;
    END IF;
END  FU_STAMPA_GENERE;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_GENERE
-- --------------------------------------------------------------------------------------------
-- INPUT:  Criteri di ricerca dei generi
-- OUTPUT: Restituisce i generi che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_GENERE(p_desc_genere  CD_GENERE.DESC_GENERE%TYPE)
                        RETURN C_GENERE
IS
    c_genere_return C_GENERE;
BEGIN
    OPEN c_genere_return
        FOR
            SELECT  IDGEN, DGEN, DGP
            FROM
            (
			    SELECT IDGEN, DGEN, (SELECT CD_GENERE.DESC_GENERE FROM CD_GENERE WHERE CD_GENERE.ID_GENERE = IDP) DGP
    			FROM
                    (
        				SELECT DISTINCT GEN.ID_GENERE IDGEN, GEN.DESC_GENERE DGEN, GEN.ID_GENERE_PADRE IDP
                        FROM  CD_GENERE GEN
                        CONNECT BY PRIOR GEN.ID_GENERE=GEN.ID_GENERE_PADRE
    				)
	        )
            WHERE   (p_desc_genere IS NULL OR DGEN LIKE '%'||p_desc_genere||'%')
                ORDER BY IDGEN;
--
    RETURN c_genere_return;
    EXCEPTION
		WHEN OTHERS THEN
		    RAISE_APPLICATION_ERROR(-200012, 'FUNZIONE FU_CERCA_GENERE: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_GENERE(p_desc_genere,null));
--
END FU_CERCA_GENERE;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_DISTRIBUTORE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_DISTRIBUTORE(p_casa_distribuzione   CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
                                    p_esito                OUT NUMBER)
IS
BEGIN
    p_esito     := 1;
    SAVEPOINT ins;
    INSERT INTO CD_DISTRIBUTORE
        (CASA_DISTRIBUZIONE)
    VALUES
        (UPPER(p_casa_distribuzione));
--
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_INSERISCI_DISTRIBUTORE: Insert non eseguita, verificare la coerenza dei parametri '||sqlerrm);
        ROLLBACK TO ins;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_DISTRIBUTORE
-- DESCRIZIONE: Torna l'elenco di tutti i distributori
-- AUTORE: Angelo Marletta, Teoresi s.r.l., 28/5/2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_DISTRIBUTORE(p_id_distributore     CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE,
                                   p_casa_distribuzione  CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
                                   p_esito             OUT NUMBER)
IS
BEGIN
    p_esito     := 1;
    SAVEPOINT ins;
    UPDATE CD_DISTRIBUTORE SET CASA_DISTRIBUZIONE = p_casa_distribuzione
    WHERE ID_DISTRIBUTORE = p_id_distributore; 
--
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_MODIFICA_DISTRIBUTORE: Update non eseguita, verificare la coerenza dei parametri '||sqlerrm);
        ROLLBACK TO ins;
END;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_DISTRIBUTORE
-- DESCRIZIONE: Effettua la cancellazione di un distributore, e se richiesto lo sostituisce
--              con un altro
-- INPUT:
--        p_id_distributore: id del distributore da eliminare
--        p_id_distributore_new: id del distributore sostituto (se null non effettua la sostituzione)
-- AUTORE: Angelo Marletta, Teoresi s.r.l., 28/5/2010
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_DISTRIBUTORE(p_id_distributore      CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE,
                                  p_id_distributore_new  CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE,
                                  p_esito                OUT NUMBER)
IS
BEGIN
    p_esito     := 1;
    SAVEPOINT ins;
    IF (p_id_distributore = p_id_distributore_new) THEN
        --errore, gli id devono essere diversi
        p_esito := -10;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_MODIFICA_DISTRIBUTORE: Update non eseguita, verificare la coerenza dei parametri '||sqlerrm);
        ROLLBACK TO ins;
    ELSIF (p_id_distributore_new IS NULL) THEN
        --cancellazione distributore
        DELETE FROM CD_DISTRIBUTORE WHERE ID_DISTRIBUTORE=p_id_distributore;
    ELSE
        --sostituzione
        UPDATE CD_SPETTACOLO SET ID_DISTRIBUTORE=p_id_distributore_new
        WHERE ID_DISTRIBUTORE=p_id_distributore;
        DELETE FROM CD_DISTRIBUTORE WHERE ID_DISTRIBUTORE=p_id_distributore;
    END IF; 
    EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_MODIFICA_DISTRIBUTORE: Update non eseguita, verificare la coerenza dei parametri '||sqlerrm);
        ROLLBACK TO ins;
END;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_LISTA_DISTRIBUTORI
-- DESCRIZIONE: Torna l'elenco di tutti i distributori
-- AUTORE: Angelo Marletta, Teoresi s.r.l., 28/5/2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_LISTA_DISTRIBUTORI RETURN C_DISTRIBUTORE
IS
    c_distributore_return C_DISTRIBUTORE;
BEGIN
    OPEN c_distributore_return
        FOR
            SELECT 
                ID_DISTRIBUTORE, CASA_DISTRIBUZIONE
            FROM CD_DISTRIBUTORE
            ORDER BY CASA_DISTRIBUZIONE;
--
    RETURN c_distributore_return;
    EXCEPTION
		WHEN OTHERS THEN
		    RAISE_APPLICATION_ERROR(-200012, 'FUNZIONE FU_LISTA_DISTRIBUTORI: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI :'||SQLERRM);
--
END FU_LISTA_DISTRIBUTORI;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_DISTRIBUTORE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_DISTRIBUTORE (p_id_distributore CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE) RETURN C_DISTRIBUTORE
IS
    c_distributore_return C_DISTRIBUTORE;
BEGIN
OPEN c_distributore_return
        FOR
            SELECT 
                ID_DISTRIBUTORE, CASA_DISTRIBUZIONE
            FROM CD_DISTRIBUTORE
            WHERE ID_DISTRIBUTORE = p_id_distributore;
--
    RETURN c_distributore_return;
    EXCEPTION
		WHEN OTHERS THEN
		    RAISE_APPLICATION_ERROR(-200012, 'FUNZIONE FU_LISTA_DISTRIBUTORI: SI E'' VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI :'||SQLERRM);

END;
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ELENCO_TUTTI_GENERI
-- DESCRIZIONE:  la funzione si occupa di reperire l'elenco dei generi memorizzati in tabella
--
-- INPUT:  Nessuno
-- OUTPUT: Restituisce tutti i generi presenti in tabella
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009
-- MODIFICHE
--               Antonio Colucci, Teoresi s.r.l. 21/01/2010
--               Aggiunta nell'estrazione informazione sul flag protetto
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_TUTTI_GENERI RETURN C_GENERE_BASE
IS
    c_genereb_return C_GENERE_BASE;
BEGIN
    OPEN c_genereb_return
        FOR
            SELECT   GP.ID_GENERE, GP.DESC_GENERE, GP.ID_GENERE_PADRE,
                     GEN.DESC_GENERE DESC_GENERE_PADRE,GP.FLG_PROTETTO
                FROM CD_GENERE GP
                LEFT JOIN CD_GENERE GEN ON GP.ID_GENERE_PADRE = GEN.ID_GENERE
                ORDER BY GP.DESC_GENERE;
    RETURN c_genereb_return;
--
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_ELENCO_TUTTI_GENERI: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
END FU_ELENCO_TUTTI_GENERI;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_LISTA_SPETT_DATI_PROIEZ
-- DESCRIZIONE:  la funzione si occupa di reperire l'elenco degli spettacoli memorizzati in tabella
--
-- INPUT:  Criteri di ricerca degli spettacoli (ID_GENERE e DESC_SPETTACOLO, opzionali)
-- OUTPUT: Restituisce gli spettacoli che rispondono ai criteri di ricerca immessi
-- fornendo per ciascuno spettacolo anche un'indicazione sull'esistenza di proiezioni ad esso associate
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009
-- MODIFICHE     Angelo Marletta, Teoresi srl, Ottobre 2010
--               Target multipli aggregati nella stessa riga
--              Antonio Clucci, Teoresi srl, Ottobre 2010
--                  inserite anche le date tra i criteri di ricerca
-- --------------------------------------------------------------------------------------------
FUNCTION FU_LISTA_SPETT_DATI_PROIEZ(p_id_genere            CD_SPETTACOLO.ID_GENERE%TYPE,
                                    p_nome_spettacolo      CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                    p_provenienza          CD_SPETTACOLO.PROVENIENZA%TYPE,
                                    p_id_distributore      CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE,
                                    p_flg_protetto         CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                    p_id_target            CD_TARGET.ID_TARGET%TYPE,
                                    p_data_inizio          CD_SPETTACOLO.DATA_INIZIO%TYPE,
                                    p_data_fine            CD_SPETTACOLO.DATA_FINE%TYPE)
						            RETURN C_SPETT_PROIEZ
IS
    c_spett_return C_SPETT_PROIEZ;
BEGIN
    OPEN c_spett_return
        FOR
            SELECT DISTINCT SP.ID_SPETTACOLO, SP.NOME_SPETTACOLO,
                SP.DATA_INIZIO, SP.DATA_FINE, SP.DURATA_SPETTACOLO, SP.ID_GENERE,
                CD_GENERE.DESC_GENERE DESC_GENERE,
                SP.PROVENIENZA,CD_DISTRIBUTORE.CASA_DISTRIBUZIONE,SP.FLG_PROTETTO,
                vencd.fu_cd_string_agg(cd_target.NOME_TARGET) over (partition by SP.ID_SPETTACOLO) nome_target
            FROM CD_GENERE, CD_SPETTACOLO SP, 
                 CD_DISTRIBUTORE,cd_spett_target,CD_TARGET
            WHERE NULLIF(p_id_genere, SP.ID_GENERE) is null
            --AND (SP.DATA_FINE IS NULL OR SP.DATA_FINE > SYSDATE)
            and (p_data_inizio is null or sp.data_inizio>=p_data_inizio)
            and (p_data_fine is null or sp.data_fine>=p_data_fine)
            AND upper(SP.NOME_SPETTACOLO) LIKE '%'||upper(p_nome_spettacolo)||'%'
            AND CD_GENERE.ID_GENERE (+)= SP.ID_GENERE
            AND (p_PROVENIENZA IS NULL OR PROVENIENZA = p_PROVENIENZA)
            AND (p_id_distributore is null or SP.id_distributore = p_id_distributore)
            AND CD_DISTRIBUTORE.ID_DISTRIBUTORE(+) = SP.ID_DISTRIBUTORE
            AND SP.FLG_PROTETTO = NVL(p_FLG_PROTETTO,SP.FLG_PROTETTO)
            AND (p_id_target is null 
                or 
                (   cd_spett_target.id_target = p_id_target)
                )
            and cd_spett_target.id_target = cd_target.id_target (+)
            and cd_target.flg_annullato(+) = 'N' 
            and SP.id_spettacolo = cd_spett_target.id_spettacolo (+)
            ORDER BY SP.NOME_SPETTACOLO;
    RETURN c_spett_return;
--
EXCEPTION
		WHEN OTHERS THEN
		    RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_LISTA_SPETT_DATI_PROIEZ: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
END FU_LISTA_SPETT_DATI_PROIEZ;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ELENCO_GENERI_SPETT
-- DESCRIZIONE:  la funzione si occupa di reperire l'elenco dei generi memorizzati in tabella
-- fornendo informazioni anche sull'esistenza di almeno uno spettacolo associato al genere stesso
--
-- INPUT:  Nessuno
-- OUTPUT: Restituisce tutti i generi presenti in tabella
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_GENERI_SPETT RETURN C_GENERE_SPETT
IS
    c_gen_spett_ret C_GENERE_SPETT;
BEGIN
    OPEN c_gen_spett_ret
        FOR
            SELECT DISTINCT GP.ID_GENERE, GP.DESC_GENERE, GP.ID_GENERE_PADRE,
                            GEN.DESC_GENERE DESC_GENERE_PADRE, SPETT.ID_GENERE ID_GENERE_SPETT
                FROM CD_GENERE GP
                LEFT JOIN CD_GENERE GEN ON GP.ID_GENERE_PADRE = GEN.ID_GENERE
                LEFT JOIN CD_SPETTACOLO SPETT ON GP.ID_GENERE = SPETT.ID_GENERE
                ORDER BY GP.DESC_GENERE;
    RETURN c_gen_spett_ret;
--
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FU_ELENCO_GENERI_SPETT: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
END FU_ELENCO_GENERI_SPETT;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ELENCO_GENERI_PADRE
-- DESCRIZIONE:  la funzione si occupa di reperire l'elenco dei generi padre memorizzati in tabella
-- con genere Padre si intende un genere con ID_PADRE null o -1
--
-- INPUT:  Nessuno
-- OUTPUT: Restituisce tutti i generi padre presenti in tabella
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009
-- MODIFICHE
--               Antonio Colucci, Teoresi s.r.l. 21/01/2010
--               Aggiunta nell'estrazione informazione sul flag protetto
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_GENERI_PADRE (p_id_genere         CD_GENERE.ID_GENERE%TYPE)
                                     RETURN C_GENERE_BASE
IS
    c_generep_return C_GENERE_BASE;
BEGIN
    OPEN c_generep_return
        FOR
            SELECT   GP.ID_GENERE, GP.DESC_GENERE, GP.ID_GENERE_PADRE,
                     NULL DESC_GENERE_PADRE,GP.FLG_PROTETTO
                FROM CD_GENERE GP
                WHERE (GP.ID_GENERE_PADRE IS NULL OR GP.ID_GENERE_PADRE = -1)
                AND GP.ID_GENERE <> p_id_genere
                ORDER BY GP.DESC_GENERE;
    RETURN c_generep_return;
--
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_ELENCO_GENERI_PADRE: SI E'' VERIFICATO UN ERRORE  '||SQLERRM);
END FU_ELENCO_GENERI_PADRE;
--
--
	--

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_GIORNO_SALA
-- DESCRIZIONE: la funzione si occupa di reperire gli spettacoli associati
--              alla specifica sala in un giorno
--
-- INPUT:  p_id_sala    l'id della sala
--         p_data       il giorno in questione
-- OUTPUT: Restituisce tutti gli id ed i nomi degli spettacoli rispondenti ai vincoli impostati
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Gennaio 2010
-- MODIFICHE     Antonio Colucci, Teoresi srl, Giugno 2010
--              Modificata la query di estrazione in modo da reperire le informazioni 
--              relative alla programmazione filmica non dalla FK ID_SPETTACOLO in proiezione (rimossa)
--              ma dalla nuova tavola associativa CD_PROIEZIONE_SPETT. Modificato anche il tipo di 
--              REF_CURSOR restituito 
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SPETT_GIORNO_SALA(p_id_sala         CD_SALA.ID_SALA%TYPE,
                              p_data            CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                              p_flg_protetta    CD_FASCIA.FLG_PROTETTA%TYPE)
                              RETURN C_SPETTACOLO_PROIEZIONE
IS
   c_spett_return C_SPETTACOLO_PROIEZIONE;
BEGIN
    OPEN c_spett_return
        FOR
            SELECT   CD_PROIEZIONE.DATA_PROIEZIONE,
                     CD_SPETTACOLO.ID_SPETTACOLO, CD_SPETTACOLO.NOME_SPETTACOLO,
                     LPAD(CD_PROIEZIONE_SPETT.HH_INI,2,0)||':'||LPAD(CD_PROIEZIONE_SPETT.MM_INI,2,0)ORA_INIZIO,
                     LPAD(CD_PROIEZIONE_SPETT.HH_FINE,2,0)||':'||LPAD(CD_PROIEZIONE_SPETT.MM_FINE,2,0) ORA_FINE,
                     CD_GENERE.DESC_GENERE, CD_DISTRIBUTORE.CASA_DISTRIBUZIONE
            FROM     CD_SPETTACOLO, CD_PROIEZIONE_SPETT,
                     CD_SCHERMO, CD_FASCIA, CD_GENERE, 
                     CD_DISTRIBUTORE,CD_PROIEZIONE
            WHERE    CD_PROIEZIONE_SPETT.ID_PROIEZIONE = CD_PROIEZIONE.ID_PROIEZIONE
            AND      CD_PROIEZIONE_SPETT.ID_SPETTACOLO = CD_SPETTACOLO.ID_SPETTACOLO
            AND      CD_SCHERMO.ID_SALA = p_id_sala
            AND      CD_PROIEZIONE.DATA_PROIEZIONE = p_data
            AND      CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
            AND      CD_PROIEZIONE.ID_FASCIA = CD_FASCIA.ID_FASCIA
            AND      CD_FASCIA.FLG_PROTETTA = p_flg_protetta
            AND      CD_SPETTACOLO.ID_GENERE = CD_GENERE.ID_GENERE(+)
            AND      CD_SPETTACOLO.ID_DISTRIBUTORE = CD_DISTRIBUTORE.ID_DISTRIBUTORE (+)
            order by ora_inizio;
    RETURN c_spett_return;
--
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_SPETT_GIORNO_SALA: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
END FU_SPETT_GIORNO_SALA;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION PR_IMPORTA_SPETTACOLO  la funzione si occupa di importare le informazioni su uno 
--                                 spettacolo nel db. Se lo spettacolo esiste gia non viene inserito
--         Se il distributore non esiste viene inserito
--         Se il genere non esiste viene inserito
--         Se lo spettacolo non esiste viene inserito e gli vengono associati distributore e genere
--         Valori ritornati:
--              1: nuovo spettacolo inserito
--              0: spettacolo gia esistente
--              -1: errore nell'importazione
-- REALIZZATORE  Angelo Marletta, Teoresi srl, 03 Maggio 2010
-- MODIFICHE:    Antonio Colucci, Teoresi srl, 06 Maggio 2010
--               l'eventuale assenza di un genere in anagrafica non deve comportarne il suo inserimento 
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_IMPORTA_SPETTACOLO(   p_titolo         CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                   p_genere         CD_GENERE.DESC_GENERE%TYPE,
                                   p_distributore   CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
                                   p_flg_protetto   CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                   p_esito          OUT NUMBER
                                   )
IS
    distExists number;
    genExists number;
    spettExists number;
    id_dist number;
    id_gen number;
BEGIN
    SAVEPOINT inizio;
    SELECT COUNT(*) INTO distExists FROM CD_DISTRIBUTORE WHERE UPPER(CASA_DISTRIBUZIONE)=UPPER(p_distributore);
    SELECT COUNT(*) INTO genExists FROM CD_GENERE WHERE UPPER(DESC_GENERE)=UPPER(p_genere);
    IF distExists=0 THEN
        INSERT INTO CD_DISTRIBUTORE(CASA_DISTRIBUZIONE)
        VALUES(p_distributore);
    END IF;
    /*
    IF genExists=0 THEN
        INSERT INTO CD_GENERE(DESC_GENERE)
        VALUES(p_genere);
    END IF;
    */
    IF genExists<>0 THEN
        SELECT id_genere INTO id_gen FROM CD_GENERE WHERE UPPER(DESC_GENERE)=UPPER(p_genere);
    END IF;
   -- 
    SELECT id_distributore INTO id_dist FROM CD_DISTRIBUTORE WHERE UPPER(CASA_DISTRIBUZIONE)=UPPER(p_distributore);
   -- 
    SELECT COUNT(*) INTO spettExists FROM CD_SPETTACOLO WHERE UPPER(NOME_SPETTACOLO)=UPPER(p_titolo);
    IF spettExists=0 THEN
        INSERT INTO CD_SPETTACOLO(NOME_SPETTACOLO,ID_DISTRIBUTORE,ID_GENERE,FLG_PROTETTO,DATA_INIZIO)
        VALUES(upper(p_titolo),id_dist,id_gen,p_flg_protetto,TRUNC(sysdate));
        p_esito:=1;
    ELSE
        p_esito:=0;
    END IF;
EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO inizio;
            p_esito:=-1;
            RAISE_APPLICATION_ERROR(-20012, 'PROCEDURA PR_IMPORTA_SPETTACOLO: SI E'' VERIFICATO UN ERRORE - titolo: '||p_titolo||' errore: '||SQLERRM);
END;   
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_PROGRAMMAZIONE_SPETTACOLARE
-- DESCRIZIONE: la funzione si occupa di reperire gli spettacoli associati
--              alla specifica sala in un giorno
--
-- INPUT:  p_id_cinema       identificativo del cinema
--         p_id_sala         identificativo della sala
--         p_data_inizio     data inizio ricerca
--         p_data_fine       data fine ricerca
--         p_id_circuito     identificativo del circuito (al momento non usato = a null)
--         p_flg_protetto    impostazione di ricerca per soli film protetti
--         p_id_genere       identificativo del genere
--         p_id_target       identificativo del target
--         p_id_spettacolo   identificativo dello spettacolo
--         p_esclusivo       parametro per distinguere una ricerca con target esclusivo oppure no
--         
-- OUTPUT: Restituisce tutti gli id ed i nomi degli spettacoli rispondenti ai vincoli impostati
--
-- REALIZZATORE  Antonio Colucci TEORESI SRL, GIUGNO 2010
-- MODIFICHE     Antonio Colucci, Teoresi srl, Ottobre 2010
--                  Inserito filtro target esclusivo(e non) nella ricerca.
--               Tommaso D'Anna, Teoresi srl, 8 Novembre 2010
--                  Inserito filtro per comune, provincia o regione.
--               Tommaso D'Anna, Teoresi srl, 9 Novembre 2010
--                  Inserito filtro per circuito.
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PROGRAMMAZIONE_SPETTACOLARE( p_id_cinema       cd_cinema.id_cinema%TYPE,
                                         p_id_sala         cd_sala.id_sala%TYPE,
                                         p_data_inizio     date,
                                         p_data_fine       date,
                                         p_id_circuito     cd_circuito.id_circuito%type,
                                         p_flg_protetto    cd_spettacolo.flg_protetto%type,
                                         p_id_genere       cd_genere.id_genere%type,
                                         p_id_target       cd_target.id_target%type,
                                         p_id_spettacolo   cd_spettacolo.id_spettacolo%type,
                                         p_esclusivo       number,
                                         p_id_comune       cd_comune.id_comune%type,
                                         p_id_provincia    cd_provincia.id_provincia%type,
                                         p_id_regione      cd_regione.id_regione%type
                                        )RETURN C_PROGRAMMAZIONE_SPETTACOLARE
IS
c_spett_return C_PROGRAMMAZIONE_SPETTACOLARE;
BEGIN
    
    OPEN c_spett_return
        FOR
             /*Le sale con in programmazione un solo film nella giornata rientrano nella ricerca per target esclusivo
            a meno dell'impostazione di un target specifico*/
             with situazione_target as
               (
                select distinct data_proiezione,id_sala from 
                (
                    select t2.*,
                        case
                            when num_spettacoli_con_target=num_spettacoli then 1
                            else 0
                        end flg_esclusivo
                    from (            
                            select t1.*, 
                                   count(id_target) over (partition by data_proiezione,id_sala,id_target) num_spettacoli_con_target,
                                   count(distinct id_target) over (partition by data_proiezione,id_sala,id_spettacolo) num_target,
                                   count(distinct id_spettacolo) over (partition by data_proiezione,id_sala) num_spettacoli
                                 from (
                                    select distinct cd_proiezione.data_proiezione,
                                           id_sala,cd_spett_target.id_target,
                                           cd_proiezione_spett.id_spettacolo
                                    from cd_proiezione_spett,
                                         cd_spettacolo,
                                         cd_target,
                                         cd_proiezione,
                                         cd_schermo,
                                         cd_spett_target
                                    where cd_proiezione.data_proiezione between p_data_inizio and p_data_fine
                                    and cd_proiezione.id_proiezione = cd_proiezione_spett.id_proiezione
                                    and cd_proiezione.flg_annullato = 'N'
                                    and cd_proiezione.id_schermo = cd_schermo.id_schermo
                                    and (p_id_sala is null or cd_schermo.id_sala = p_id_sala)
                                    and cd_proiezione_spett.id_spettacolo = cd_spettacolo.id_spettacolo
                                    and cd_spettacolo.id_spettacolo = cd_spett_target.id_spettacolo(+)
                                    and cd_spett_target.id_target = cd_target.id_target(+)
                                    order by id_sala,id_spettacolo,id_target
                                    ) t1
                                    order by id_sala,id_spettacolo,id_target
                        ) t2
                )
                where 
                ((p_esclusivo = 1 and  flg_esclusivo = 1) or  (p_esclusivo = 0))
                and (p_id_target is null or id_target = p_id_target)
               )
             select distinct 
                    cd_proiezione.data_proiezione,
                    cd_cinema.id_cinema,CD_CINEMA.NOME_CINEMA, 
                    CD_COMUNE.COMUNE,
                    cd_sala.id_sala,CD_SALA.NOME_SALA,
                    CD_SPETTACOLO.NOME_SPETTACOLO,
                    LPAD(CD_PROIEZIONE_SPETT.HH_INI,2,0)
                    ||':'||
                    LPAD(CD_PROIEZIONE_SPETT.MM_INI,2,0)
                    ||'-'||
                    LPAD(CD_PROIEZIONE_SPETT.HH_FINE,2,0)
                    ||':'||
                    LPAD(CD_PROIEZIONE_SPETT.MM_FINE,2,0) ORARIO,
                    CD_GENERE.DESC_GENERE,
                    VENCD.fu_cd_string_agg(CD_TARGET.DESCR_TARGET) over (partition by CD_PROIEZIONE.data_proiezione,CD_SALA.id_sala,id_proiezione_spett) DESCR_TARGET,
                    CD_SPETTACOLO.FLG_PROTETTO
              from
                   CD_CINEMA, CD_COMUNE, CD_SALA,
                   CD_SPETTACOLO, CD_PROIEZIONE_SPETT,
                   CD_GENERE, CD_TARGET, CD_SCHERMO,
                   CD_SPETT_TARGET ,CD_PROIEZIONE,
                   CD_PROVINCIA, CD_REGIONE,                   
                   situazione_target 
              where
                   cd_proiezione.data_proiezione between p_data_inizio and p_data_fine
                   /*Filtri di ricerca*/
              and  cd_cinema.id_cinema = nvl(p_id_cinema,cd_cinema.id_cinema)
              and  cd_sala.id_sala = nvl(p_id_sala,cd_sala.id_sala)
              and  cd_spettacolo.flg_protetto = nvl(p_flg_protetto,cd_spettacolo.flg_protetto)
              and  (p_id_genere is null or cd_genere.id_genere = p_id_genere)
              and  cd_spettacolo.id_spettacolo = nvl(p_id_spettacolo,cd_spettacolo.id_spettacolo)
              and  cd_comune.id_comune = nvl(p_id_comune,cd_comune.id_comune)
              and  cd_provincia.id_provincia = nvl (p_id_provincia,cd_provincia.id_provincia)
              and  cd_regione.id_regione = nvl(p_id_regione,cd_regione.id_regione)
              and  (p_id_circuito is null or cd_proiezione.id_schermo in
                        (
                        select distinct cd_circuito_schermo.ID_SCHERMO
                            from cd_circuito_schermo,cd_listino
                            where cd_circuito_schermo.ID_LISTINO = cd_listino.ID_LISTINO
                            and cd_circuito_schermo.FLG_ANNULLATO = 'N'
                            and cd_circuito_schermo.ID_CIRCUITO = p_id_circuito
                           and 
                                (
                                    ( p_data_inizio between cd_listino.data_inizio and cd_listino.data_fine )
                                or
                                    ( p_data_fine between cd_listino.data_inizio and cd_listino.data_fine )
                                )
                        ) 
                    )                            
                   /*Join tra tabelle*/
              and  cd_proiezione.id_schermo = cd_schermo.id_schermo
              and  cd_schermo.id_sala = cd_sala.id_sala
              and  cd_sala.id_cinema = cd_cinema.id_cinema
              and  cd_cinema.id_comune = cd_comune.id_comune
              and  cd_proiezione_spett.id_proiezione = cd_proiezione.id_proiezione
              and  cd_proiezione_spett.id_spettacolo = cd_spettacolo.id_spettacolo
              and  cd_spett_target.id_spettacolo (+) = cd_spettacolo.id_spettacolo
              --and  (p_id_target is null or cd_spett_target.id_target = p_id_target)
              and  cd_spett_target.id_target = cd_target.id_target (+)
              and  cd_spettacolo.ID_GENERE = cd_genere.ID_GENERE(+)
              and  cd_sala.id_sala = situazione_target.id_sala
              and  cd_proiezione.data_proiezione = situazione_target.data_proiezione
              and  cd_comune.id_provincia=cd_provincia.id_provincia
              and  cd_provincia.id_regione=cd_regione.id_regione              
              order by nome_cinema,nome_sala,orario;
      
    RETURN c_spett_return;
--
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_PROGRAMMAZIONE_SPETTACOLARE: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
END  FU_PROGRAMMAZIONE_SPETTACOLARE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_PROGR_SPETT_PER_SALA
-- DESCRIZIONE: la funzione si occupa di reperire gli spettacoli associati
--              ad uno specifico periodo di tempo riportando anche il numero 
--              di sale dove lo stesso sara programmato 
--
-- INPUT:  p_id_sala    l'id della sala
--         p_data       il giorno in questione
-- OUTPUT: Restituisce tutti gli id ed i nomi degli spettacoli rispondenti ai vincoli impostati
--
-- REALIZZATORE  Antonio Colucci TEORESI SRL, GIUGNO 2010
-- MODIFICHE
--               Tommaso D'Anna, Teoresi srl, 8 Novembre 2010
--                  Inserito filtro per comune, provincia o regione.
--               Tommaso D'Anna, Teoresi srl, 9 Novembre 2010
--                  Inserito filtro per circuito.
--               Antonio Colucci, Teoresi srl, 9 Novembre 2010
--                  Modificato conteggio sale.
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PROGR_SPETT_PER_SALA( p_id_cinema       cd_cinema.id_cinema%TYPE,
                                  p_id_sala         cd_sala.id_sala%TYPE,
                                  p_data_inizio     date,
                                  p_data_fine       date,
                                  p_id_circuito     cd_circuito.id_circuito%type,
                                  p_flg_protetto    cd_spettacolo.flg_protetto%type,
                                  p_id_genere       cd_genere.id_genere%type,
                                  p_id_target       cd_target.id_target%type,
                                  p_id_spettacolo   cd_spettacolo.id_spettacolo%type,
                                  p_id_comune       cd_comune.id_comune%type,
                                  p_id_provincia    cd_provincia.id_provincia%type,
                                  p_id_regione      cd_regione.id_regione%type                                  
                                 )RETURN C_PROGR_SPETT_SALA
IS
c_spett_return C_PROGR_SPETT_SALA;
BEGIN
    
    OPEN c_spett_return
        FOR
           select distinct cd_proiezione.data_proiezione,
                  CD_SPETTACOLO.NOME_SPETTACOLO,
                  count(distinct cd_proiezione.id_schermo) over (partition by cd_proiezione.data_proiezione,cd_proiezione_spett.id_spettacolo)num_sale, 
                  CD_GENERE.DESC_GENERE,CD_TARGET.DESCR_TARGET,
                  CD_SPETTACOLO.FLG_PROTETTO
            from
                  CD_CINEMA, CD_SALA,
                  CD_SPETTACOLO, CD_PROIEZIONE_SPETT,
                  CD_GENERE, CD_TARGET, CD_SCHERMO,
                  CD_SPETT_TARGET ,CD_PROIEZIONE,
                  CD_PROVINCIA, CD_REGIONE, CD_COMUNE     
            where
               cd_proiezione.data_proiezione between p_data_inizio and p_data_fine
               /*Filtri di ricerca*/
            and  cd_cinema.id_cinema = nvl(p_id_cinema,cd_cinema.id_cinema)
            and  cd_sala.id_sala = nvl(p_id_sala,cd_sala.id_sala)
            and  cd_spettacolo.flg_protetto = nvl(p_flg_protetto,cd_spettacolo.flg_protetto)
            and  (p_id_genere is null or cd_genere.id_genere = p_id_genere)
            and  (p_id_target is null or cd_target.id_target = p_id_target)
            and  cd_spettacolo.id_spettacolo = nvl(p_id_spettacolo,cd_spettacolo.id_spettacolo)
            and  cd_comune.id_comune = nvl(p_id_comune,cd_comune.id_comune)
            and  cd_provincia.id_provincia = nvl (p_id_provincia,cd_provincia.id_provincia)
            and  cd_regione.id_regione = nvl(p_id_regione,cd_regione.id_regione)
            and  (p_id_circuito is null or cd_proiezione.id_schermo in
                      (
                      select distinct cd_circuito_schermo.ID_SCHERMO
                          from cd_circuito_schermo,cd_listino
                          where cd_circuito_schermo.ID_LISTINO = cd_listino.ID_LISTINO
                          and cd_circuito_schermo.FLG_ANNULLATO = 'N'
                          and cd_circuito_schermo.ID_CIRCUITO = p_id_circuito
                         and 
                              (
                                  ( p_data_inizio between cd_listino.data_inizio and cd_listino.data_fine )
                              or
                                  ( p_data_fine between cd_listino.data_inizio and cd_listino.data_fine )
                              )
                      ) 
                  )                           
               /*Join tra tabelle*/
            and  cd_proiezione.id_schermo = cd_schermo.id_schermo
            and  cd_schermo.id_sala = cd_sala.id_sala
            and  cd_sala.id_cinema = cd_cinema.id_cinema
            and  cd_comune.id_provincia=cd_provincia.id_provincia
            and  cd_provincia.id_regione=cd_regione.id_regione   
            --and  cd_sala.id_sala = 22
            and  cd_proiezione_spett.id_proiezione = cd_proiezione.id_proiezione
            and  cd_proiezione_spett.id_spettacolo = cd_spettacolo.id_spettacolo
            and  cd_spett_target.id_spettacolo (+)= cd_spettacolo.id_spettacolo
            and  cd_spett_target.id_target = cd_target.id_target (+)
            and  cd_spettacolo.ID_GENERE = cd_genere.ID_GENERE(+)
            order by data_proiezione;
           
    RETURN c_spett_return;
--
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_PROGR_SPETT_PER_SALA: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
END  FU_PROGR_SPETT_PER_SALA;      
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SALE_SENZA_PROGR
-- DESCRIZIONE: la funzione si occupa di reperire gli spettacoli associati
--              ad uno specifico periodo di tempo riportando anche il numero 
--              di sale dove lo stesso sara programmato 
--
-- INPUT:  p_id_sala    l'id della sala
--         p_data       il giorno in questione
-- OUTPUT: Restituisce tutti gli id ed i nomi degli spettacoli rispondenti ai vincoli impostati
--
-- REALIZZATORE  Antonio Colucci TEORESI SRL, GIUGNO 2010
-- MODIFICHE
--               Tommaso D'Anna, Teoresi srl, 8 Novembre 2010
--                  Inserito filtro per comune, provincia o regione.
--               Tommaso D'Anna, Teoresi srl, 9 Novembre 2010
--                  Inserito filtro per circuito.
--               Tommaso D'Anna, Teoresi srl, 27 Aprile 2011
--                  Modificato il core della query poiche non tirava fuori alcune sale.
-- --------------------------------------------------------------------------------------------
FUNCTION FU_SALE_SENZA_PROGR( p_id_cinema       cd_cinema.id_cinema%TYPE,
                              p_id_sala         cd_sala.id_sala%TYPE,
                              p_data_inizio     date,
                              p_data_fine       date,
                              p_id_circuito     cd_circuito.id_circuito%type,
                              p_id_comune       cd_comune.id_comune%type,
                              p_id_provincia    cd_provincia.id_provincia%type,
                              p_id_regione      cd_regione.id_regione%type                              
                            )RETURN C_PROGRAMMAZIONE_SPETTACOLARE
IS
c_spett_return C_PROGRAMMAZIONE_SPETTACOLARE;
BEGIN   
    OPEN c_spett_return    
        FOR
            WITH
                DATA_SCHERMO_NO_PROGR AS 
                (
                    ( 
                    SELECT DISTINCT
                         CD_PROIEZIONE.DATA_PROIEZIONE,
                         CD_PROIEZIONE.ID_SCHERMO
                     FROM 
                         CD_PROIEZIONE
                     WHERE 
                         CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                         AND CD_PROIEZIONE.ID_SCHERMO <> 388
                         AND CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                    )
                                            MINUS
                    (
                    SELECT DISTINCT 
                       CD_PROIEZIONE.DATA_PROIEZIONE,
                       CD_PROIEZIONE.ID_SCHERMO
                    FROM 
                       CD_PROIEZIONE, 
                       CD_PROIEZIONE_SPETT
                    WHERE CD_PROIEZIONE.ID_PROIEZIONE = CD_PROIEZIONE_SPETT.ID_PROIEZIONE
                    AND CD_PROIEZIONE.DATA_PROIEZIONE BETWEEN p_data_inizio AND p_data_fine
                    AND CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                    ) 
                )        
            SELECT DISTINCT
                 CD_PROIEZIONE.DATA_PROIEZIONE,
                 CD_CINEMA.ID_CINEMA,
                 CD_CINEMA.NOME_CINEMA,CD_COMUNE.COMUNE,
                 CD_SALA.ID_SALA,CD_SALA.NOME_SALA,
                 null,null,null,null,null
            FROM
                CD_SCHERMO,
                CD_SALA,
                CD_CINEMA,
                CD_COMUNE,
                CD_PROVINCIA, 
                CD_REGIONE,
                CD_PROIEZIONE,
                DATA_SCHERMO_NO_PROGR
            WHERE
                (p_id_sala IS NULL OR CD_SALA.ID_SALA = p_id_sala)
                AND (p_id_cinema IS NULL OR CD_CINEMA.ID_CINEMA = p_id_cinema)
                AND  CD_COMUNE.ID_COMUNE = NVL(p_id_comune,CD_COMUNE.ID_COMUNE)
                AND  CD_PROVINCIA.ID_PROVINCIA = NVL (p_id_provincia,CD_PROVINCIA.ID_PROVINCIA)
                AND  CD_REGIONE.ID_REGIONE = NVL(p_id_regione,CD_REGIONE.ID_REGIONE)
                AND  (p_id_circuito IS NULL OR CD_PROIEZIONE.ID_SCHERMO IN
                          (
                          SELECT DISTINCT CD_CIRCUITO_SCHERMO.ID_SCHERMO
                              FROM CD_CIRCUITO_SCHERMO,CD_LISTINO
                              WHERE CD_CIRCUITO_SCHERMO.ID_LISTINO = CD_LISTINO.ID_LISTINO
                              AND CD_CIRCUITO_SCHERMO.FLG_ANNULLATO = 'N'
                              AND CD_CIRCUITO_SCHERMO.ID_CIRCUITO = p_id_circuito
                             AND 
                                  (
                                      ( p_data_inizio BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE )
                                  OR
                                      ( p_data_fine BETWEEN CD_LISTINO.DATA_INIZIO AND CD_LISTINO.DATA_FINE )
                                  )
                          ) 
                      ) 
                AND CD_SCHERMO.ID_SCHERMO = DATA_SCHERMO_NO_PROGR.ID_SCHERMO
                AND CD_PROIEZIONE.DATA_PROIEZIONE = DATA_SCHERMO_NO_PROGR.DATA_PROIEZIONE
                AND CD_SCHERMO.ID_SALA = CD_SALA.ID_SALA
                AND CD_SALA.FLG_VISIBILE = 'S'
                AND CD_SALA.FLG_ARENA = 'N'
                AND CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                AND CD_CINEMA.FLG_VIRTUALE = 'N'
                AND CD_SCHERMO.ID_SCHERMO <> 388
                AND CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
                AND CD_CINEMA.ID_COMUNE = CD_COMUNE.ID_COMUNE
                AND CD_PROIEZIONE.FLG_ANNULLATO = 'N'
                /*JOIN TRA LE TABELLE*/
                AND CD_PROIEZIONE.ID_SCHERMO = CD_SCHERMO.ID_SCHERMO
                AND CD_COMUNE.ID_PROVINCIA = CD_PROVINCIA.ID_PROVINCIA
                AND CD_PROVINCIA.ID_REGIONE = CD_REGIONE.ID_REGIONE
                ORDER BY NOME_CINEMA,NOME_SALA;
           
    RETURN c_spett_return;
--
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_SALE_SENZA_PROGR: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
END  FU_SALE_SENZA_PROGR;                                       
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_PROIEZIONE_GEMELLA
-- DESCRIZIONE: la funzione si occupa di reperire gli spettacoli associati
--              alla specifica sala in un giorno
--
-- INPUT:  p_id_proiezione IDENTIFICATIVO DELLA PROIEZIONE DI PARTENZA
--
-- OUTPUT: Restituisce l'identificativo della proiezione gemella (l'altra proiezione tipo)
--         dato  l'identificativo di partenza 
--
-- REALIZZATORE  Antonio Colucci TEORESI SRL , GIUGNO 2010
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_PROIEZIONE_GEMELLA(p_id_proiezione     CD_PROIEZIONE.ID_PROIEZIONE%TYPE)
						             RETURN CD_PROIEZIONE.ID_PROIEZIONE%TYPE
IS
v_id_proiezione cd_proiezione.id_proiezione%type;
begin
       select id_proiezione into v_id_proiezione from cd_proiezione where
        data_proiezione=(select data_proiezione from cd_proiezione where id_proiezione=p_id_proiezione)
        and id_schermo=(select id_schermo from cd_proiezione where id_proiezione=p_id_proiezione)
        and id_proiezione!=p_id_proiezione;
    return v_id_proiezione;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'FUNZIONE FU_DAMMI_PROIEZIONE_GEMELLA: SI E'' VERIFICATO UN ERRORE: '||SQLERRM);
END FU_DAMMI_PROIEZIONE_GEMELLA;
                                      
END PA_CD_SPETTACOLO; 
/

