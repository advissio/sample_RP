CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PRODOTTO_VENDITA IS

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_PRODOTTO_VENDITA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo prodotto di vendita nel sistema
--
-- OPERAZIONI:
--  1) Memorizza il prodotto di vendita (CD_PRODOTTO_VENDITA)
--
--  INPUT:
--  p_id_circuito       identificativo del circuito
--  p_id_mod_vendita    identificativo della modalita di vendita
--  p_id_prodotto_pubb  identificativo del prodotto pubblicitario
--  p_id_fascia         identificativo della fascia oraria
--  p_id_tipo_break     identificativo della tipologia di break
--  p_cod_man           codice della manifestazione
--  p_flg_annullato     flag annullato
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--   -2  Prodotto di vendita gia presente
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE: Francesco Abbundo, Teoresi srl, Luglio 2009
--             Roberto Barbaro, Teoresi srl, Ottobre 2009
--             Antonio Colucci, Teoresi srl, Aprile 2010
--                              Inserita gestione del flg definito a listino
--             Antonio Colucci, Teoresi srl, Agosto 2010
--                              Inserita gestione dell'id target e del flg abbinato
--             Tommaso D'Anna, Teoresi srl, 13 Maggio 2011
--                              Inserita gestione del flag Segui il Film
--              Antonio Colucci, Teoresi srl, 17 Maggio 2011
--                          Inserito controllo di unicita per l'inserimento di nuovi prodotti
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_PRODOTTO_VENDITA(p_id_circuito               CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
                                        p_id_mod_vendita            CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE,
                                        p_id_prodotto_pubb          CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE,
                                        p_id_tipo_break             CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE,
                                        p_cod_man                   CD_PRODOTTO_VENDITA.COD_MAN%TYPE,
                                        p_flg_definito_a_listino    CD_PRODOTTO_VENDITA.FLG_DEFINITO_A_LISTINO%TYPE,
                                        p_id_target                 CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
                                        p_flg_abbinato              CD_PRODOTTO_VENDITA.FLG_ABBINATO%TYPE,
                                        p_flg_segui_il_film         CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE,
										p_esito				        OUT NUMBER)
IS

v_count_prod        NUMBER(1);

BEGIN -- PR_INSERISCI_PRODOTTO_VENDITA
    p_esito 	:= 1;
    SAVEPOINT SP_PR_INSERISCI_PRODOTTO_VEND;
--    
    select  count(1)
    into    v_count_prod 
    from    cd_prodotto_vendita
    where   id_circuito = p_id_circuito
    and     id_mod_vendita = p_id_mod_vendita
    and     id_prodotto_pubb = p_id_prodotto_pubb
    and     id_tipo_break = p_id_tipo_break
    and     (p_cod_man is null or cod_man = p_cod_man)
    and     (p_id_target is null or id_target = p_id_target);
    if(v_count_prod = 0)then
        INSERT INTO CD_PRODOTTO_VENDITA
    	(
            id_circuito,
    		id_mod_vendita,
    		id_prodotto_pubb,
    		id_tipo_break,
            flg_definito_a_listino,
    		cod_man,
            id_target,
            flg_abbinato,
            FLG_SEGUI_IL_FILM)
    	VALUES
        (
    	    p_id_circuito,
    		p_id_mod_vendita,
    		p_id_prodotto_pubb,
    		p_id_tipo_break,
            p_flg_definito_a_listino,
    		p_cod_man,
            p_id_target,
            p_flg_abbinato,
            p_flg_segui_il_film);
    else
        /*Prodotto gia presente*/
        p_esito := -2;
    end if;
--    

	EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
		WHEN OTHERS THEN
		p_esito := -11;
        ROLLBACK TO SP_PR_INSERISCI_PRODOTTO_VEND;
		RAISE_APPLICATION_ERROR(-20007, 'PROCEDURA PR_INSERISCI_PRODOTTO_VENDITA: INSERT NON ESEGUITA: '||sqlerrm);

END;


-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_PRODOTTO_VENDITA
--
-- DESCRIZIONE:  Esegue l'aggiornamento di un prodotto vendita
--
-- OPERAZIONI:
--   Update
--
--  INPUT:
--  p_id_prodotto_vendita   identificativo del prodotto di vendita
--  p_id_circuito           identificativo del circuito
--  p_id_mod_vendita        identificativo della modalita di vendita
--  p_id_prodotto_pubb      identificativo del prodotto pubblicitario
--  p_id_tipo_break         identificativo della tipologia di break
--  p_cod_man               codice della manifestazione
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Update non eseguita: i parametri per l'Update non sono coerenti
--
-- REALIZZATORE: Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:   Antonio Colucci, Teoresi srl, Agosto 2010
--                              Inserita gestione dell'id target e del flg abbinato
--               Tommaso D'Anna, Teoresi srl, 13 Maggio 2011
--                              Inserita gestione del flag Segui il Film
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_PRODOTTO_VENDITA( p_id_prodotto_vendita       CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
                                        p_id_circuito               CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
                                        p_id_mod_vendita            CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE,
                                        p_id_prodotto_pubb          CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE,
                                        p_id_tipo_break             CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE,
                                        p_cod_man                   CD_PRODOTTO_VENDITA.COD_MAN%TYPE,
                                        p_flg_definito_a_listino    CD_PRODOTTO_VENDITA.FLG_DEFINITO_A_LISTINO%TYPE,
                                        p_id_target                 CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
                                        p_flg_abbinato              CD_PRODOTTO_VENDITA.FLG_ABBINATO%TYPE,
                                        p_flg_segui_il_film         CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM%TYPE,
                                        p_esito				  OUT NUMBER)
IS
--
BEGIN -- PR_MODIFICA_PRODOTTO_VENDITA
    p_esito := 1;
    SAVEPOINT ann_upd;
    UPDATE CD_PRODOTTO_VENDITA
        SET
		    ID_CIRCUITO = (nvl(p_id_circuito, ID_CIRCUITO)),
            ID_MOD_VENDITA = (nvl(p_id_mod_vendita, ID_MOD_VENDITA)),
            ID_PRODOTTO_PUBB = (nvl(p_id_prodotto_pubb, ID_PRODOTTO_PUBB)),
            ID_TIPO_BREAK = (nvl(p_id_tipo_break, ID_TIPO_BREAK)),
            COD_MAN = (nvl(p_cod_man, COD_MAN)),
            flg_definito_a_listino = (nvl(p_flg_definito_a_listino,flg_definito_a_listino)),
            ID_TARGET = (nvl(p_id_target, ID_TARGET)),
            FLG_ABBINATO = (nvl(p_flg_abbinato, FLG_ABBINATO)),
            FLG_SEGUI_IL_FILM = (nvl(p_flg_segui_il_film, FLG_SEGUI_IL_FILM))
        WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;
    p_esito := SQL%ROWCOUNT;
--
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20007, 'Procedura PR_MODIFICA_PRODOTTO_VENDITA: Update non eseguita, verificare la coerenza dei parametri '||sqlerrm);
        ROLLBACK TO ann_upd;
END;
--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_PRODOTTO_VENDITA
--
-- DESCRIZIONE:  Esegue l'eliminazione o l'annullamento di un prodotto di vendita dal sistema
--
-- OPERAZIONI:
--   1) Controllo se il prodotto di vendita in oggetto e stato venduto
--   2) Se e stato venduto annullo i comunicati associati se sono futuri
--   3) Annullo gli ambiti di vendita se sono futuri
--   4) Annullo il prodotto di vendita
--   5) Se non e stato venduto elimino gli ambiti di vendita
--   6) Elimino le tariffe associate
--   7) Elimino il prodotto di vendita
--
--  INPUT:
--      p_id_prodotto_vendita   id del prodotto di vendita
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
PROCEDURE PR_ELIMINA_PRODOTTO_VENDITA(  p_id_prodotto_vendita		IN CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
										p_esito		            	OUT NUMBER)
IS
--
v_count_prodvendita     INTEGER:=0;
v_esito                 INTEGER;
--
BEGIN -- PR_ELIMINA_PRODOTTO_VENDITA
--
--
p_esito 	:= 1;

SAVEPOINT SP_PR_ELIMINA_PRODOTTO_VENDITA;

    --qui elimina i break di vendita
    DELETE FROM  CD_BREAK_VENDITA
    WHERE CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui elimina le sale di vendita
    DELETE FROM CD_SALA_VENDITA
    WHERE CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui elimino gli atrii di vendita
    DELETE FROM CD_ATRIO_VENDITA
    WHERE CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui elimino i cinema di vendita
    DELETE FROM CD_CINEMA_VENDITA
    WHERE CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui elimino le tariffe
    DELETE FROM CD_TARIFFA
    WHERE CD_TARIFFA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

    p_esito := p_esito + SQL%ROWCOUNT;

    --qui elimino i prodotti di vendita
    DELETE FROM CD_PRODOTTO_VENDITA
	WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

    p_esito := p_esito + SQL%ROWCOUNT;

	p_esito := SQL%ROWCOUNT;

  EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20007, 'PROCEDURA PR_ELIMINA_PRODOTTO_VENDITA: DELETE NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI '||sqlerrm);
		ROLLBACK TO SP_PR_ELIMINA_PRODOTTO_VENDITA;
--
END;
--
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_PRODOTTO_VENDITA
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
--  INPUT:
--  p_id_circuito           identificativo del circuito
--  p_id_mod_vendita        identificativo della modalita di vendita
--  p_id_prodotto_pubb      identificativo del prodotto pubblicitario
--  p_id_fascia             identificativo della fascia oraria
--  p_id_tipo_break         identificativo della tipologia di break
--  p_cod_man               codice della manifestazione
--  p_flg_annullato         flag annullato
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE:  Francesco Abbundo, Teoresi srl, Luglio 2009
-- --------------------------------------------------------------------------------------------
--
--
FUNCTION FU_STAMPA_PRODOTTO_VENDITA(p_id_circuito       CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
                                    p_id_mod_vendita    CD_PRODOTTO_VENDITA.ID_MOD_VENDITA%TYPE,
                                    p_id_prodotto_pubb  CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE,
                                    p_id_fascia         CD_PRODOTTO_VENDITA.ID_FASCIA%TYPE,
                                    p_id_tipo_break     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK%TYPE,
                                    p_cod_man           CD_PRODOTTO_VENDITA.COD_MAN%TYPE,
									p_flg_annullato     CD_PRODOTTO_VENDITA.FLG_ANNULLATO%TYPE)
									RETURN VARCHAR2
IS
--
BEGIN
--
IF v_stampa_prodotto_vendita = 'ON'

    THEN

     RETURN 'ID_CIRCUITO: '     || p_id_circuito      || ', ' ||
            'ID_MOD_VENDITA: '  || p_id_mod_vendita   || ', ' ||
            'ID_PRODOTTO_PUBB: '|| p_id_prodotto_pubb || ', ' ||
            'ID_FASCIA: '       || p_id_fascia        || ', ' ||
            'ID_TIPO_BREAK: '   || p_id_tipo_break    || ', ' ||
            'COD_MAN: '         || p_cod_man          || ', ' ||
			'FLG_ANNULLATO: '   || p_flg_annullato;

END IF;

END  FU_STAMPA_PRODOTTO_VENDITA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_PRODOTTO_VENDITA
-- DESCRIZIONE: la funzione si occupa di estrarre informazioni relative ai
--              prodotti di vendita che rispondono ai parametri di input
--
--  INPUT:
--  p_id_mod_vendita    id della modalita di vendita
--  p_id_prd_pubb       id del prodotto pubblicitario
--  p_id_mis_temp       id della unita di misura temporale
--  p_id_circuito       id del circuito
--  p_id_tipo_break     id del tipo break
--  p_cod_man           codice della manifestazione
--
-- OUTPUT: lista dei prodotti di vendita con le informazioni
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE:   Antonio Colucci, Teoresei srl, Ottobre 2010
--                  Aggiunta concatenazione dei tagli temporali in modo da evitare duplicazione delle righe
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PRODOTTO_VENDITA (p_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
                                    p_id_prd_pubb           CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
                                    p_id_mis_temp           CD_UNITA_MISURA_TEMP.ID_UNITA%TYPE,
                                    p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_cod_man               PC_MANIF.COD_MAN%TYPE,
                                    p_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
                                    p_categoria_prod        CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%type,
                                    p_flg_annullato         CD_PRODOTTO_VENDITA.FLG_ANNULLATO%TYPE,
                                    p_id_target             CD_PRODOTTO_VENDITA.ID_TARGET%TYPE)
                                    RETURN C_LISTA_PRD_VND
IS

v_dett_prod_vend    C_LISTA_PRD_VND;

BEGIN

OPEN v_dett_prod_vend
    FOR
        SELECT DISTINCT(CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA), CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB,
                CD_PRODOTTO_PUBB.DESC_PRODOTTO, CD_TIPO_BREAK.ID_TIPO_BREAK,
	            CD_TIPO_BREAK.DESC_TIPO_BREAK, CD_MODALITA_VENDITA.ID_MOD_VENDITA,
                CD_MODALITA_VENDITA.DESC_MOD_VENDITA, CD_CIRCUITO.ID_CIRCUITO,
                CD_CIRCUITO.NOME_CIRCUITO,
                CD_FASCIA.ID_FASCIA,
                CD_FASCIA.DESC_FASCIA,
                vencd.fu_cd_string_agg(CD_UNITA_MISURA_TEMP.ID_UNITA) over (partition by CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA) ID_UNITA, 
                vencd.fu_cd_string_agg(CD_UNITA_MISURA_TEMP.DESC_UNITA)over (partition by CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA) DESC_UNITA,cd_target.nome_target
        FROM    CD_CIRCUITO, CD_MODALITA_VENDITA, CD_TIPO_BREAK, CD_PRODOTTO_PUBB,
                CD_PRODOTTO_VENDITA, CD_MISURA_PRD_VENDITA, CD_UNITA_MISURA_TEMP, CD_FASCIA,
                cd_target
        WHERE   CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
        AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK(+)
        AND     CD_PRODOTTO_VENDITA.ID_FASCIA = CD_FASCIA.ID_FASCIA(+)
        AND     CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = CD_MODALITA_VENDITA.ID_MOD_VENDITA
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
        AND     CD_MISURA_PRD_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
        AND     CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND     CD_PRODOTTO_VENDITA.ID_TARGET = CD_TARGET.ID_TARGET(+)
        AND     (p_id_mod_vendita is null or (CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = p_id_mod_vendita ))
        AND     (p_id_prd_pubb is null or (CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = p_id_prd_pubb ))
        AND     (p_id_mis_temp is null or (CD_UNITA_MISURA_TEMP.ID_UNITA = p_id_mis_temp ))
        AND     (p_id_circuito is null or (CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito ))
        AND     (p_id_tipo_break is null or (CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = p_id_tipo_break ))
        AND     (p_cod_man is null or (CD_PRODOTTO_VENDITA.COD_MAN = p_cod_man ))
        AND     (p_id_fascia is null or (CD_PRODOTTO_VENDITA.ID_FASCIA = p_id_fascia ))
        AND     (p_categoria_prod is null or (CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO = p_categoria_prod))
        AND     (p_flg_annullato is null or (CD_PRODOTTO_VENDITA.FLG_ANNULLATO = p_flg_annullato ))
        AND     (p_id_target is null or (CD_PRODOTTO_VENDITA.ID_TARGET = p_id_target ))
		ORDER BY CD_CIRCUITO.NOME_CIRCUITO;

RETURN v_dett_prod_vend;

END FU_CERCA_PRODOTTO_VENDITA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_ELENCO_PRODOTTO_VENDITA
-- DESCRIZIONE: la funzione si occupa di estrarre informazioni relative ai
--              prodotti di vendita che rispondono ai parametri di input
--              Tale funzione NON restituisce le info relative ai diversi tagli tempoarali associati
--              ed e utilizzata nel popup della tariffa per ottenere l'elenco dei prodotti di vendita 
--
--  INPUT:
--  p_id_mod_vendita    id della modalita di vendita
--  p_id_prd_pubb       id del prodotto pubblicitario
--  p_id_circuito       id del circuito
--  p_id_tipo_break     id del tipo break
--  p_cod_man           codice della manifestazione
--  p_categoria_prod    categoria prodotto pubblicitario
--
-- OUTPUT: lista dei prodotti di vendita con le informazioni
--
--
-- REALIZZATORE  Antonio Colucci, Teoresi srl, Maggio 2010
--
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_ELENCO_PRODOTTO_VENDITA (p_id_mod_vendita        CD_MODALITA_VENDITA.ID_MOD_VENDITA%TYPE,
                                    p_id_prd_pubb           CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
                                    p_id_circuito           CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                    p_id_tipo_break         CD_TIPO_BREAK.ID_TIPO_BREAK%TYPE,
                                    p_cod_man               PC_MANIF.COD_MAN%TYPE,
                                    p_id_fascia             CD_FASCIA.ID_FASCIA%TYPE,
                                    p_categoria_prod        CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO%type)
                                    RETURN C_ELENCO_PRODOTTO_VEND
IS

v_prod_vend    C_ELENCO_PRODOTTO_VEND;

BEGIN

OPEN v_prod_vend
    FOR
        SELECT DISTINCT(CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA), CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB,
                CD_PRODOTTO_PUBB.DESC_PRODOTTO, CD_TIPO_BREAK.ID_TIPO_BREAK,
	            CD_TIPO_BREAK.DESC_TIPO_BREAK, CD_MODALITA_VENDITA.ID_MOD_VENDITA,
                CD_MODALITA_VENDITA.DESC_MOD_VENDITA, CD_CIRCUITO.ID_CIRCUITO,
                CD_CIRCUITO.NOME_CIRCUITO,
                CD_FASCIA.ID_FASCIA,
                CD_FASCIA.DESC_FASCIA
        FROM    CD_CIRCUITO, CD_MODALITA_VENDITA, CD_TIPO_BREAK, CD_PRODOTTO_PUBB,
                CD_PRODOTTO_VENDITA, CD_FASCIA
        WHERE   CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
        AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK(+)
        AND     CD_PRODOTTO_VENDITA.ID_FASCIA = CD_FASCIA.ID_FASCIA(+)
        AND     CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = CD_MODALITA_VENDITA.ID_MOD_VENDITA
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
        AND     (p_id_mod_vendita is null or (CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = p_id_mod_vendita ))
        AND     (p_id_prd_pubb is null or (CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = p_id_prd_pubb ))
        AND     (p_id_circuito is null or (CD_PRODOTTO_VENDITA.ID_CIRCUITO = p_id_circuito ))
        AND     (p_id_tipo_break is null or (CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = p_id_tipo_break ))
        AND     (p_cod_man is null or (CD_PRODOTTO_VENDITA.COD_MAN = p_cod_man ))
        AND     (p_id_fascia is null or (CD_PRODOTTO_VENDITA.ID_FASCIA = p_id_fascia ))
        AND     (p_categoria_prod is null or (CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO = p_categoria_prod))
        AND     CD_PRODOTTO_VENDITA.FLG_ANNULLATO = 'N' 
        ORDER BY CD_CIRCUITO.NOME_CIRCUITO;

RETURN v_prod_vend;

END FU_ELENCO_PRODOTTO_VENDITA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_DETTAGLIO_PRODOTTO_VENDITA
-- DESCRIZIONE: la funzione si occupa di estrarre informazioni relative ad un singolo
--              prodotto di vendita
--
--  INPUT:
--  p_id_prodotto_vendita
--
-- OUTPUT: lista dei prodotti di vendita con le informazioni
--
--
-- REALIZZATORE Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE:   Antonio Colucci, Teoresi srl, Agosto 2010
--                  Inserita gestione dell'id target e del flg abbinato
--              Tommaso D'Anna, Teoresi srl, 13 Maggio 2011
--                  Inserita gestione del flag Segui il Film
--              Tommaso D'Anna, Teoresi srl, 20 Luglio 2011
--                  Inserita gestione della data inizio/fine validita tariffa
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_PRODOTTO_VENDITA (p_id_prodotto_vendita     CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE)
                                        RETURN C_DETTAGLIO_PRODOTTO_VENDITA
IS

v_dett_prod_vend    C_DETTAGLIO_PRODOTTO_VENDITA;

BEGIN

OPEN v_dett_prod_vend
    FOR
        SELECT  CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA, CD_PRODOTTO_VENDITA.FLG_ANNULLATO,
                CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB, CD_PRODOTTO_PUBB.DESC_PRODOTTO, CD_TIPO_BREAK.ID_TIPO_BREAK,
	            CD_TIPO_BREAK.DESC_TIPO_BREAK, CD_MODALITA_VENDITA.ID_MOD_VENDITA,
                CD_MODALITA_VENDITA.DESC_MOD_VENDITA, CD_CIRCUITO.ID_CIRCUITO,
                CD_CIRCUITO.NOME_CIRCUITO, NULL,NULL,NULL,NULL,
                PC_MANIF.COD_MAN, PC_MANIF.DES_MAN,CD_PRODOTTO_VENDITA.FLG_DEFINITO_A_LISTINO,
                CD_PRODOTTO_VENDITA.ID_TARGET,CD_TARGET.NOME_TARGET,CD_PRODOTTO_VENDITA.FLG_ABBINATO,
                CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM,NULL,NULL,NULL
        FROM    CD_CIRCUITO, CD_MODALITA_VENDITA, CD_TIPO_BREAK, CD_PRODOTTO_PUBB,
                CD_PRODOTTO_VENDITA, PC_MANIF, CD_TARGET
        WHERE   CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
        AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK(+)
        AND     CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = CD_MODALITA_VENDITA.ID_MOD_VENDITA
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
        AND     CD_PRODOTTO_VENDITA.COD_MAN = PC_MANIF.COD_MAN(+)
        AND     CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
        AND     CD_PRODOTTO_VENDITA.ID_TARGET = CD_TARGET.ID_TARGET(+);

RETURN v_dett_prod_vend;

END FU_DETTAGLIO_PRODOTTO_VENDITA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_DETTAGLIO_PRODOTTO_VENDITA_LISTINO
-- DESCRIZIONE: la funzione si occupa di estrarre informazioni relative ai
--              prodotti di vendita relative ad un determinato listino
--
--  INPUT:
--  p_id_listino    id del listino
--  p_cat_prodotto  categoria del prodotto
--
-- OUTPUT: lista dei prodotti di vendita con le informazioni
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Agosto 2009
--
-- MODIFICHE:
--              Tommaso D'Anna, Teoresi srl, 13 Maggio 2011
--                  Inserita gestione del flag Segui il Film
--              Tommaso D'Anna, Teoresi srl, 20 Luglio 2011
--                  Inserita gestione delle date inizio/fine validita tariffa
--              Tommaso D'Anna, Teoresi srl, 6 Settembre 2011
--                  Modificata l'ORDER BY
--              Tommaso D'Anna, Teoresi srl, 29 Settembre 2011
--                  Inserito recupero informazioni relative al taglio temporale
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETT_PROD_VEND_LISTINO (p_id_listino     CD_LISTINO.DESC_LISTINO%TYPE,
                                    p_cat_prodotto   PC_CATEGORIA_PRODOTTO.COD%TYPE)
                                    RETURN C_DETTAGLIO_PRODOTTO_VENDITA
IS

v_dett_prod_vend    C_DETTAGLIO_PRODOTTO_VENDITA;

BEGIN

OPEN v_dett_prod_vend
    FOR
        SELECT  
            CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA, 
            CD_PRODOTTO_VENDITA.FLG_ANNULLATO,
            CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB, 
            CD_PRODOTTO_PUBB.DESC_PRODOTTO, 
            CD_TIPO_BREAK.ID_TIPO_BREAK,
            CD_TIPO_BREAK.DESC_TIPO_BREAK, 
            CD_MODALITA_VENDITA.ID_MOD_VENDITA,
            CD_MODALITA_VENDITA.DESC_MOD_VENDITA, 
            CD_CIRCUITO.ID_CIRCUITO,
            CD_CIRCUITO.NOME_CIRCUITO, 
            CD_TARIFFA.ID_TARIFFA, 
            CD_TARIFFA.IMPORTO, 
            CD_TARIFFA.DATA_INIZIO, 
            CD_TARIFFA.DATA_FINE,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL, 
            CD_PRODOTTO_VENDITA.FLG_SEGUI_IL_FILM,
            CD_TARIFFA.ID_MISURA_PRD_VE,
            CD_MISURA_PRD_VENDITA.ID_UNITA,
            CD_UNITA_MISURA_TEMP.DESC_UNITA         
        FROM    
            CD_TARIFFA, 
            CD_CIRCUITO, 
            CD_MODALITA_VENDITA, 
            CD_TIPO_BREAK,
            CD_PRODOTTO_PUBB, 
            CD_PRODOTTO_VENDITA,
            CD_MISURA_PRD_VENDITA,
            CD_UNITA_MISURA_TEMP
        WHERE   CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
        AND     (p_cat_prodotto is null or (CD_PRODOTTO_PUBB.COD_CATEGORIA_PRODOTTO = p_cat_prodotto ))
        AND     CD_PRODOTTO_VENDITA.ID_TIPO_BREAK = CD_TIPO_BREAK.ID_TIPO_BREAK(+)
        AND     CD_PRODOTTO_VENDITA.ID_MOD_VENDITA = CD_MODALITA_VENDITA.ID_MOD_VENDITA
        AND     CD_PRODOTTO_VENDITA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO
        AND     CD_TARIFFA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA
        AND     CD_TARIFFA.ID_LISTINO = p_id_listino
        AND     CD_TARIFFA.ID_MISURA_PRD_VE = CD_MISURA_PRD_VENDITA.ID_MISURA_PRD_VE
        AND     CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        --ORDER BY CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA, CD_TARIFFA.DATA_INIZIO, CD_TARIFFA.DATA_FINE;
        ORDER BY
                CD_CIRCUITO.NOME_CIRCUITO,
                CD_MODALITA_VENDITA.DESC_MOD_VENDITA,
                CD_PRODOTTO_PUBB.DESC_PRODOTTO,
                CD_TIPO_BREAK.DESC_TIPO_BREAK,
                CD_TARIFFA.DATA_INIZIO,
                CD_TARIFFA.DATA_FINE;
RETURN v_dett_prod_vend;

END FU_DETT_PROD_VEND_LISTINO;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_MODALITA_VENDITA
-- DESCRIZIONE: la funzione si occupa di estrarre informazioni relative alle
--              modalita di vendita che rispondono ai parametri di input
--
--  INPUT:
--  p_desc_mod_vendita  descrizione della modalita di vendita
--
-- OUTPUT: lista delle modalita di vendita
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_MODALITA_VENDITA (p_desc_mod_vendita      CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE)
                                    RETURN C_MODALITA_VENDITA
IS

v_mod_vend    C_MODALITA_VENDITA;

BEGIN

OPEN v_mod_vend
    FOR
        SELECT  ID_MOD_VENDITA, DESC_MOD_VENDITA
        FROM    CD_MODALITA_VENDITA
        WHERE   (p_desc_mod_vendita IS NULL OR (DESC_MOD_VENDITA LIKE '%'||p_desc_mod_vendita||'%'));

RETURN v_mod_vend;

END FU_CERCA_MODALITA_VENDITA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_UNITA_MIS_TEMP
-- DESCRIZIONE: la funzione si occupa di estrarre informazioni relative alle
--              unita temporali che rispondono ai parametri di input
--
--  INPUT:
--  p_desc_unita    descrizione dell'unita temporale
--
-- OUTPUT: lista delle unita temporali
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_UNITA_MIS_TEMP (p_desc_unita      CD_UNITA_MISURA_TEMP.DESC_UNITA%TYPE,
                                  p_id_prod_pubb    CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE)
                                  RETURN C_UNITA_MIS_TEMP
IS

v_unita_temp    C_UNITA_MIS_TEMP;

BEGIN

OPEN v_unita_temp
    FOR
        SELECT  DISTINCT(CD_UNITA_MISURA_TEMP.ID_UNITA), DESC_UNITA
        FROM    CD_UNITA_MISURA_TEMP, CD_PRODOTTO_PUBB, CD_MISURA_PRD_VENDITA
        WHERE   (p_desc_unita IS NULL OR (DESC_UNITA LIKE '%'||p_desc_unita||'%'))
        AND     CD_MISURA_PRD_VENDITA.ID_PRODOTTO_PUBB = CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB
        AND     CD_MISURA_PRD_VENDITA.ID_UNITA = CD_UNITA_MISURA_TEMP.ID_UNITA
        AND     (p_id_prod_pubb IS NULL OR (CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB = p_id_prod_pubb));

RETURN v_unita_temp;

END FU_CERCA_UNITA_MIS_TEMP;

-- --------------------------------------------------------------------------------------------
-- FUNCTION
--    FU_CERCA_MANIF
-- DESCRIZIONE: la funzione si occupa di estrarre informazioni relative alle
--              manifestazioni che rispondono ai parametri di input
--
--  INPUT:
--  p_desc_unita    descrizione della manifestazione
--
-- OUTPUT: lista delle manifestazioni
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
-- MODIFICHE:
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_MANIF (p_des_man      PC_MANIF.DES_MAN%TYPE)
                         RETURN C_MANIF
IS

v_manif    C_MANIF;

BEGIN

OPEN v_manif
    FOR
        SELECT  COD_MAN, DES_MAN
        FROM    PC_MANIF
        WHERE   (p_des_man IS NULL OR (DES_MAN LIKE '%'||p_des_man||'%'))
        ORDER BY DES_MAN;

RETURN v_manif;

END FU_CERCA_MANIF;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione FU_MOD_SEC_CERCA_PROD_DATO
--
-- DESCRIZIONE:  Fornendo id prodotto di vendita e id listino fornisce l'estrazione dei dati relativi
-- ai break vendita raggruppati in modo da dare indicazioni sui secondi assegnati; vengono lette le
-- date di erogazione e in questo modo si raggrupano (per date consecutive) i record aventi lo stesso
-- valore dei secondi assegnati
--
-- INPUT:
--      p_id_listino
--      p_id_prodotto_vendita
--      p_anno_inizio
--      p_ciclo_inizio
--      p_periodo_inizio
--      p_anno_fine
--      p_ciclo_fine
--      p_periodo_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , ottobre 2009
--
--  MODIFICHE:  Francesco Abbundo, Teoresi srl, novembre 2009
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION FU_MOD_SEC_CERCA_PROD_DATO (
       p_id_listino            cd_circuito_break.ID_LISTINO%TYPE,
       p_id_prodotto_vendita   cd_prodotto_vendita.ID_PRODOTTO_VENDITA%TYPE,
       p_anno_inizio           periodi.ANNO%TYPE,
       p_ciclo_inizio          periodi.CICLO%TYPE,
       p_periodo_inizio        periodi.PER%TYPE,
       p_anno_fine             periodi.ANNO%TYPE,
       p_ciclo_fine            periodi.CICLO%TYPE,
       p_periodo_fine          periodi.PER%TYPE
   )
      RETURN C_MOD_SEC_ASSE_PROD_SCELTO
   IS
--
      c_ric   C_MOD_SEC_ASSE_PROD_SCELTO;
--
   BEGIN
   -- spezzo il caso con periodo indicato da quello senza periodo per abbreviare (molto) i tempi di esecuzione
   IF (p_anno_inizio IS NULL OR p_anno_inizio = -1)THEN
       OPEN c_ric FOR
            select cb.id_listino, bv.id_prodotto_vendita, count(bv.id_prodotto_vendita)as numBreak,
                bv.secondi_assegnati, tipo_break.durata_secondi,
                periodi.data_iniz,periodi.data_fine
                from periodi, cd_break_vendita bv, cd_circuito_break cb, cd_tipo_break tipo_break, cd_prodotto_vendita prd_vnd
                where cb.id_listino = p_id_listino
                and prd_vnd.id_prodotto_vendita = p_id_prodotto_vendita
                and prd_vnd.ID_TIPO_BREAK = tipo_break.ID_TIPO_BREAK
                and bv.id_prodotto_vendita = prd_vnd.id_prodotto_vendita
                and bv.id_circuito_break = cb.id_circuito_break
				and bv.DATA_EROGAZIONE between periodi.DATA_INIZ and periodi.DATA_FINE
                group by cb.id_listino, bv.id_prodotto_vendita, secondi_assegnati,
                    tipo_break.durata_secondi,periodi.data_iniz,periodi.data_fine
                order by periodi.data_iniz,periodi.data_fine;
   ELSE
        OPEN c_ric FOR
            select cb.id_listino, bv.id_prodotto_vendita, count(bv.id_prodotto_vendita)as numBreak,
                bv.secondi_assegnati, tipo_break.durata_secondi,
                periodi.data_iniz,periodi.data_fine
                from periodi, cd_break_vendita bv, cd_circuito_break cb, cd_tipo_break tipo_break, cd_prodotto_vendita prd_vnd,
                (select DATA_INIZ from periodi
                        where anno = p_anno_inizio
                        and ciclo = p_ciclo_inizio
                        and per = p_periodo_inizio)periodo_inizio,
                (select DATA_FINE from periodi
                        where anno = p_anno_fine
                        and ciclo = p_ciclo_fine
                        and per = p_periodo_fine)periodo_fine
                where cb.id_listino = p_id_listino
                and prd_vnd.id_prodotto_vendita = p_id_prodotto_vendita
                and prd_vnd.ID_TIPO_BREAK = tipo_break.ID_TIPO_BREAK
                and bv.DATA_EROGAZIONE between periodo_inizio.DATA_INIZ and periodo_fine.DATA_FINE
				and bv.DATA_EROGAZIONE between periodi.DATA_INIZ and periodi.DATA_FINE
                and bv.id_prodotto_vendita = prd_vnd.id_prodotto_vendita
                and bv.id_circuito_break = cb.id_circuito_break
                group by cb.id_listino, bv.id_prodotto_vendita, secondi_assegnati,
                    tipo_break.durata_secondi, periodi.data_iniz,periodi.data_fine
                order by periodi.data_iniz,periodi.data_fine;
   END IF;
--
      RETURN c_ric;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20007,
                                'Funzione FU_MOD_SEC_CERCA_PROD_DATO in errore: '
                             || SQLERRM
                            );
   END FU_MOD_SEC_CERCA_PROD_DATO;
--
--
-----------------------------------------------------------------------------------------------------
-- Funzione FU_MOD_SEC_CERCA_PROD_COMPL
--
-- DESCRIZIONE:  Fornendo id prodotto di vendita e id listino fornisce l'estrazione dei dati da
-- break vendita raggruppati in modo da dare indicazioni (per la modifica dei secondi assegnati)
-- relative ai prodotti di vendita diversi da quello indicato ma che insistono sui medesimi break
-- di vendita
--
-- INPUT:
--      p_id_listino
--      p_id_prodotto_vendita
--      p_anno_inizio
--      p_ciclo_inizio
--      p_periodo_inizio
--      p_anno_fine
--      p_ciclo_fine
--      p_periodo_fine
--
-- OUTPUT: esito:Resulset contenente i dati richiesti
--
-- REALIZZATORE: Daniela Spezia, Altran , ottobre 2009
--
--  MODIFICHE:  Francesco Abbundo, Teoresi srl, novembre 2009
--
-------------------------------------------------------------------------------------------------
--
   FUNCTION FU_MOD_SEC_CERCA_PROD_COMPL (
       p_id_listino              cd_circuito_break.ID_LISTINO%TYPE,
       p_id_prodotto_vendita     cd_prodotto_vendita.ID_PRODOTTO_VENDITA%TYPE,
       p_anno_inizio             periodi.ANNO%TYPE,
       p_ciclo_inizio            periodi.CICLO%TYPE,
       p_periodo_inizio          periodi.PER%TYPE,
       p_anno_fine               periodi.ANNO%TYPE,
       p_ciclo_fine              periodi.CICLO%TYPE,
       p_periodo_fine            periodi.PER%TYPE
   )
      RETURN C_MOD_SEC_ASSE_PROD_COMPL
   AS
--
      c_ric   C_MOD_SEC_ASSE_PROD_COMPL;
--
   BEGIN
   -- spezzo il caso con periodo indicato da quello senza periodo per abbreviare (molto) i tempi di esecuzione
   IF (p_anno_inizio IS NULL OR p_anno_inizio = -1)THEN
       OPEN c_ric FOR
            select cb.id_listino, bv.id_prodotto_vendita, count(bv.id_prodotto_vendita)as numBreak,
                bv.secondi_assegnati, prd_vnd.desc_prodotto, prd_vnd.nome_circuito,
                prd_vnd.DESC_MOD_VENDITA, prd_vnd.DESC_TIPO_BREAK, periodi.data_iniz,periodi.data_fine
                from cd_break_vendita bv, periodi,
                cd_circuito_break cb,
                (
                select prodotto_vendita.id_prodotto_vendita, prodotto.desc_prodotto, circuito.nome_circuito,
                modalita.DESC_MOD_VENDITA, tipo.DESC_TIPO_BREAK
                from cd_prodotto_vendita prodotto_vendita, cd_prodotto_pubb prodotto,
                cd_circuito circuito, cd_modalita_vendita modalita, cd_tipo_break tipo
                where prodotto_vendita.ID_CIRCUITO = circuito.id_circuito
                and prodotto_vendita.ID_MOD_VENDITA = modalita.ID_MOD_VENDITA
                and prodotto_vendita.ID_PRODOTTO_PUBB = prodotto.ID_PRODOTTO_PUBB
                and prodotto_vendita.ID_TIPO_BREAK = tipo.ID_TIPO_BREAK
                )prd_vnd,
                (
                select cb1.id_break from cd_break_vendita bv1, cd_circuito_break cb1
                where cb1.id_listino = p_id_listino
                and bv1.id_prodotto_vendita = p_id_prodotto_vendita
                and bv1.id_circuito_break = cb1.id_circuito_break
				and bv1.FLG_ANNULLATO='N'
				and cb1.FLG_ANNULLATO='N'
                )break_confronto
                where cb.id_listino = p_id_listino
				and bv.DATA_EROGAZIONE between periodi.DATA_INIZ and periodi.DATA_FINE
                and cb.id_break = break_confronto.id_break
                and bv.id_prodotto_vendita <> p_id_prodotto_vendita
                and bv.id_circuito_break = cb.id_circuito_break
                and bv.id_prodotto_vendita = prd_vnd.id_prodotto_vendita
				and bv.FLG_ANNULLATO='N'
				and cb.FLG_ANNULLATO='N'
                group by cb.id_listino, bv.id_prodotto_vendita, bv.secondi_assegnati,
                prd_vnd.desc_prodotto, prd_vnd.nome_circuito,
                prd_vnd.DESC_MOD_VENDITA, prd_vnd.DESC_TIPO_BREAK,periodi.data_iniz,periodi.data_fine
                order by prd_vnd.nome_circuito,periodi.data_iniz,periodi.data_fine,  prd_vnd.DESC_TIPO_BREAK;
   ELSE
        OPEN c_ric FOR
            select cb.id_listino, bv.id_prodotto_vendita, count(bv.id_prodotto_vendita)as numBreak,
                bv.secondi_assegnati, prd_vnd.desc_prodotto, prd_vnd.nome_circuito,
                prd_vnd.DESC_MOD_VENDITA, prd_vnd.DESC_TIPO_BREAK,  periodi.data_iniz,periodi.data_fine
                from cd_break_vendita bv, periodi,
                cd_circuito_break cb,
                (
                select prodotto_vendita.id_prodotto_vendita, prodotto.desc_prodotto, circuito.nome_circuito,
                modalita.DESC_MOD_VENDITA, tipo.DESC_TIPO_BREAK
                from cd_prodotto_vendita prodotto_vendita, cd_prodotto_pubb prodotto,
                cd_circuito circuito, cd_modalita_vendita modalita, cd_tipo_break tipo
                where prodotto_vendita.ID_CIRCUITO = circuito.id_circuito
                and prodotto_vendita.ID_MOD_VENDITA = modalita.ID_MOD_VENDITA
                and prodotto_vendita.ID_PRODOTTO_PUBB = prodotto.ID_PRODOTTO_PUBB
                and prodotto_vendita.ID_TIPO_BREAK = tipo.ID_TIPO_BREAK
                )prd_vnd,
                (
                select cb1.id_break from cd_break_vendita bv1, cd_circuito_break cb1,
                (select DATA_INIZ from periodi
                        where anno = p_anno_inizio
                        and ciclo = p_ciclo_inizio
                        and per = p_periodo_inizio)periodo_inizio,
                (select DATA_FINE from periodi
                        where anno = p_anno_fine
                        and ciclo = p_ciclo_fine
                        and per = p_periodo_fine)periodo_fine
                where cb1.id_listino = p_id_listino
                and bv1.id_prodotto_vendita = p_id_prodotto_vendita
                and bv1.DATA_EROGAZIONE between periodo_inizio.DATA_INIZ and periodo_fine.DATA_FINE
				and bv1.id_circuito_break = cb1.id_circuito_break
				and bv1.FLG_ANNULLATO='N'
				and cb1.FLG_ANNULLATO='N'
                )break_confronto
                where cb.id_listino = p_id_listino
                and cb.id_break = break_confronto.id_break
                and bv.id_prodotto_vendita <> p_id_prodotto_vendita
                and bv.id_circuito_break = cb.id_circuito_break
				and bv.DATA_EROGAZIONE between periodi.DATA_INIZ and periodi.DATA_FINE
                and bv.FLG_ANNULLATO='N'
				and cb.FLG_ANNULLATO='N'
                and bv.id_prodotto_vendita = prd_vnd.id_prodotto_vendita
                group by cb.id_listino, bv.id_prodotto_vendita, bv.secondi_assegnati,
                prd_vnd.desc_prodotto, prd_vnd.nome_circuito,
                prd_vnd.DESC_MOD_VENDITA, prd_vnd.DESC_TIPO_BREAK, periodi.data_iniz,periodi.data_fine
                order by prd_vnd.nome_circuito,periodi.data_iniz,periodi.data_fine,  prd_vnd.DESC_TIPO_BREAK;
   END IF;
--
      RETURN c_ric;
--
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20007,
                                'Funzione FU_MOD_SEC_CERCA_PROD_COMPL in errore: '
                             || SQLERRM
                            );
   END FU_MOD_SEC_CERCA_PROD_COMPL;
--
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_SECONDI
--
-- DESCRIZIONE:  Esegue l'aggiornamento dei record esistenti
--
-- INPUT:
--  p_id_listino            identificativo del listino (permette di idividuare tutti i break_vendita
--                          ad esso collegati tramite id_circuito_break)
--  p_id_prodotto_vendita   identificativo del prodotto di vendita
--      p_anno_inizio
--      p_ciclo_inizio
--      p_periodo_inizio
--      p_anno_fine
--      p_ciclo_fine
--      p_periodo_fine
--  p_secondi_vendibili     il numero dei secondi assegnati
--
-- OUTPUT: esito:
--    n  il numero di record aggiornati
--   -1  Modifica non eseguita: si e' verificato un errore
--
-- REALIZZATORE  Daniela Spezia, Altran Italia, Agosto 2009
--
--  MODIFICHE:
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_SECONDI(    p_id_listino             cd_circuito_break.ID_LISTINO%TYPE,
                                   p_id_prodotto_vendita     cd_break_vendita.ID_PRODOTTO_VENDITA%TYPE,
                                   p_secondi_vendibili       cd_break_vendita.SECONDI_ASSEGNATI%TYPE,
                                   p_anno_inizio             periodi.ANNO%TYPE,
                                   p_ciclo_inizio            periodi.CICLO%TYPE,
                                   p_periodo_inizio          periodi.PER%TYPE,
                                   p_anno_fine               periodi.ANNO%TYPE,
                                   p_ciclo_fine              periodi.CICLO%TYPE,
                                   p_periodo_fine            periodi.PER%TYPE,
                                   p_esito                   OUT NUMBER)
IS
BEGIN
    SAVEPOINT SP_PR_MODIFICA_SECONDI;
--
    p_esito := 0;
    -- spezzo il caso con periodo indicato da quello senza periodo per abbreviare (molto) i tempi di esecuzione
    IF (p_anno_inizio IS NULL OR p_anno_inizio = -1)THEN
        UPDATE CD_BREAK_VENDITA
             SET CD_BREAK_VENDITA.SECONDI_ASSEGNATI = p_secondi_vendibili
             WHERE CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
             AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK IN
                (SELECT ID_CIRCUITO_BREAK FROM CD_CIRCUITO_BREAK CB
                WHERE CB.ID_LISTINO = p_id_listino);
        p_esito := SQL%ROWCOUNT;
    ELSE
        UPDATE CD_BREAK_VENDITA
             SET CD_BREAK_VENDITA.SECONDI_ASSEGNATI= p_secondi_vendibili
             WHERE CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
             AND CD_BREAK_VENDITA.ID_CIRCUITO_BREAK IN
                (SELECT ID_CIRCUITO_BREAK FROM CD_CIRCUITO_BREAK CB
                WHERE CB.ID_LISTINO = p_id_listino)
             AND
             ( CD_BREAK_VENDITA.DATA_EROGAZIONE between
                    (select DATA_INIZ from periodi
                        where anno = p_anno_inizio
                        and ciclo = p_ciclo_inizio
                        and per = p_periodo_inizio)
               and (select DATA_FINE from periodi
                        where anno = p_anno_fine
                        and ciclo = p_ciclo_fine
                        and per = p_periodo_fine));
        p_esito := SQL%ROWCOUNT;
    END IF;
--
EXCEPTION
    WHEN OTHERS THEN
        p_esito := -1;
        RAISE_APPLICATION_ERROR(-20007, 'Procedura PR_MODIFICA_SECONDI: Update non eseguito '||SQLERRM);
    ROLLBACK TO SP_PR_MODIFICA_SECONDI;
END;
--

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_PRODOTTO_VENDITA_VENDUTO
-- DESCRIZIONE:  la funzione controlla l'esistenza un prodotto di vendita venduto nel sistema
--
-- INPUT:
--      p_id_prodotto_vendita     id del prodotto di vendita
--
-- OUTPUT: number - numero dei prodotti di vendita venduti
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_PRODOTTO_VENDITA_VENDUTO(p_id_prodotto_vendita      CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE
                                    ) RETURN INTEGER
IS

v_count_prodotto_vendita     INTEGER:=0;

BEGIN

SELECT      COUNT(1)
    INTO        v_count_prodotto_vendita
    FROM        CD_PRODOTTO_ACQUISTATO
    WHERE       ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

RETURN v_count_prodotto_vendita;

EXCEPTION
WHEN NO_DATA_FOUND THEN
RETURN 0;

END FU_PRODOTTO_VENDITA_VENDUTO;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_PRODOTTO_VENDITA
--
-- DESCRIZIONE:  Esegue la cancellazione logica di una proiezione,
--                  dei relativi circuiti, degli ambiti vendita e dei comunicati
--
-- OPERAZIONI:
--   1) Cancella logicamente proiezioni, circuiti_ambiti
--      ambiti_vendita, comunicati
-- INPUT:  Id del prodotto di vendita
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Settembre 2009
--
--  MODIFICHE: Antonio Colucci, Teoresi srl, 10/11/2010
--                  E' stato richesto di cambiare le operazioni effettuate 
--                  a fronte di un annullamento di un prodotto di vendita 
--                  con dei comunicati associati. Non verranno piu annullati i comunicati con  
--                  tutta la struttura a seguito, ma sara annullato solo il prodotto di vendita
--                  attraverso l'impostazione del fgl_annullato a S  
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_PRODOTTO_VENDITA(p_id_prodotto_vendita	    IN CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
						              p_esito		            OUT NUMBER)
IS
    v_esito     NUMBER:=0;
    v_piani_errati NUMBER;
BEGIN
    p_esito := 0;
	
    --qui annullo il prodotto di vendita
    UPDATE  CD_PRODOTTO_VENDITA
    SET FLG_ANNULLATO='S'
    WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
    AND FLG_ANNULLATO<>'S';

    p_esito := p_esito + SQL%ROWCOUNT;

     EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Procedura PR_ANNULLA_PRODOTTO_VENDITA: Eliminazione logica non eseguita: si e'' verificato un errore inatteso:'||sqlerrm);
        p_esito := -1;
END;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_PRODOTTO_VENDITA
--
-- DESCRIZIONE:  Esegue il recupero dalla cancellazione logica di una proiezione,
--                  dei relativi circuiti, degli ambiti vendita e dei comunicati
--
-- OPERAZIONI:
--   1) Recupera proiezioni, circuiti_ambiti, ambiti_vendita, comunicati
--      cancellati logicamente
-- INPUT:  Id del prodotto di vendita
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_PRODOTTO_VENDITA(p_id_prodotto_vendita    IN CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE,
						               p_esito		            OUT NUMBER)
IS
    v_esito     NUMBER:=0;
BEGIN

        -- qui seleziono i comunicati
	FOR TEMP IN(SELECT ID_COMUNICATO
	            FROM   CD_COMUNICATO
                WHERE  CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO IN(
                   SELECT DISTINCT CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO
                   FROM CD_PRODOTTO_ACQUISTATO
                   WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA IN(
                      SELECT ID_PRODOTTO_VENDITA
                        FROM CD_PRODOTTO_VENDITA
                            WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                            AND   FLG_ANNULLATO<>'N')
                   AND CD_PRODOTTO_ACQUISTATO.FLG_ANNULLATO<>'S'
                   AND CD_PRODOTTO_ACQUISTATO.FLG_SOSPESO = 'N'
                   AND CD_PRODOTTO_ACQUISTATO.COD_DISATTIVAZIONE IS NULL)
                AND CD_COMUNICATO.FLG_ANNULLATO<>'S'
                AND CD_COMUNICATO.FLG_SOSPESO = 'N'
                AND CD_COMUNICATO.COD_DISATTIVAZIONE IS NULL) LOOP
		PA_CD_COMUNICATO.PR_RECUPERA_COMUNICATO(TEMP.ID_COMUNICATO, 'PAL',v_esito);
		IF((v_esito=5) OR (v_esito=15) OR (v_esito=25)) THEN
		    p_esito := p_esito + 1;
		END IF;
	END LOOP;
    --qui annullo i break di vendita
    UPDATE  CD_BREAK_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_BREAK_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
    AND DATA_EROGAZIONE > SYSDATE;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui annullo le sale di vendita
    UPDATE  CD_SALA_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_SALA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
    AND DATA_EROGAZIONE > SYSDATE;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui annullo gli atrii di vendita
    UPDATE  CD_ATRIO_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_ATRIO_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
    AND DATA_EROGAZIONE > SYSDATE;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui annullo i cinema di vendita
    UPDATE  CD_CINEMA_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE CD_CINEMA_VENDITA.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
    AND DATA_EROGAZIONE > SYSDATE;

    p_esito := p_esito + SQL%ROWCOUNT;
    --qui annullo il prodotto di vendita
    UPDATE  CD_PRODOTTO_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE ID_PRODOTTO_VENDITA = p_id_prodotto_vendita;

    p_esito := p_esito + SQL%ROWCOUNT;

     EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-2008, 'Procedura PR_RECUPERA_PRODOTTO_VENDITA: Eliminazione logica non eseguita: si e'' verificato un errore inatteso');
        p_esito := -1;
END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DATA_PERIODO
-- DESCRIZIONE:  la funzione restituisce la data corrispondente all'anno - ciclo - periodo richiesto
--
-- INPUT:
--      anno - ciclo - periodo
--
-- OUTPUT: data corrispondente
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_DATA_PERIODO (p_anno             periodi.ANNO%TYPE,
                          p_ciclo            periodi.CICLO%TYPE,
                          p_periodo          periodi.PER%TYPE
                          )
                          RETURN PA_CD_PIANIFICAZIONE.C_SETTIMANA
IS

cur_settimana       PA_CD_PIANIFICAZIONE.C_SETTIMANA;

BEGIN

    OPEN cur_settimana FOR
        SELECT  PER, CICLO, ANNO, DATA_INIZ, DATA_FINE
        FROM    PERIODI
        WHERE   PER     = p_periodo
        AND     CICLO   = p_ciclo
        AND     ANNO    = p_anno;

    RETURN cur_settimana;

END FU_DATA_PERIODO;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_VERIFICA_ASSEGNATO
-- DESCRIZIONE:  la funzione, fissati i cinema le sale e i periodi di partenza e arrivo,
--               restituisce i secondi vendibili e nominali relativi a quel periodo
--
-- INPUT:
--      id cinema, id sala e periodi di partenza e fine
--
-- OUTPUT: secondi risultanti
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_VERIFICA_ASSEGNATO  (p_cinema                  CD_CINEMA.ID_CINEMA%TYPE,
                                 p_sala                    CD_SALA.ID_SALA%TYPE,
                                 p_anno_inizio             periodi.ANNO%TYPE,
                                 p_ciclo_inizio            periodi.CICLO%TYPE,
                                 p_periodo_inizio          periodi.PER%TYPE,
                                 p_anno_fine               periodi.ANNO%TYPE,
                                 p_ciclo_fine              periodi.CICLO%TYPE,
                                 p_periodo_fine            periodi.PER%TYPE
                                 )
                                 RETURN C_VER_ASSEGNATO
IS

cur_ver_assegnato       C_VER_ASSEGNATO;

BEGIN

OPEN cur_ver_assegnato FOR
    SELECT  CINEMA.NOME_CINEMA,CINEMA.PUBB_LOCALE,SALA.ID_SALA, SALA.NOME_SALA,
            periodi.data_iniz,periodi.data_fine, periodi.anno, periodi.ciclo,
            periodi.per, CALCOLO_ASSEGNATO.SEC_VENDIBILI,
            CALCOLO_NOMINALE.SEC_ASSEGNATI
            FROM
            (SELECT BRK.ID_PROIEZIONE,SUM(SECONDI_NOMINALI)SEC_ASSEGNATI FROM CD_BREAK BRK, CD_TIPO_BREAK T_BRK,
                (SELECT DATA_INIZ FROM PERIODI
                WHERE ANNO = p_anno_inizio
                AND CICLO = p_ciclo_inizio
                AND PER = p_periodo_inizio
                )PERIODO_INIZIO,
                (SELECT DATA_FINE FROM PERIODI
                WHERE ANNO = p_anno_fine
                AND CICLO = p_ciclo_fine
                AND PER = p_periodo_fine
                )PERIODO_FINE,CD_PROIEZIONE PROIEZIONE
            WHERE PROIEZIONE.DATA_PROIEZIONE BETWEEN PERIODO_INIZIO.DATA_INIZ AND PERIODO_FINE.DATA_FINE
            AND BRK.ID_PROIEZIONE = PROIEZIONE.ID_PROIEZIONE
            AND BRK.ID_TIPO_BREAK = T_BRK.ID_TIPO_BREAK
            AND (T_BRK.DESC_TIPO_BREAK = 'Trailer' OR T_BRK.DESC_TIPO_BREAK = 'Inizio Film')
            AND PROIEZIONE.FLG_ANNULLATO='N'
            GROUP BY BRK.ID_PROIEZIONE
            )CALCOLO_NOMINALE,
            (SELECT BRK.ID_PROIEZIONE, SUM(BV.SECONDI_ASSEGNATI) SEC_VENDIBILI FROM
            CD_BREAK BRK,CD_CIRCUITO_BREAK CB,CD_BREAK_VENDITA BV,
                (SELECT DATA_INIZ FROM PERIODI
                WHERE ANNO = p_anno_inizio
                AND CICLO = p_ciclo_inizio
                AND PER = p_periodo_inizio
                )PERIODO_INIZIO,
                (SELECT DATA_FINE FROM PERIODI
                WHERE ANNO = p_anno_fine
                AND CICLO = p_ciclo_fine
                AND PER = p_periodo_fine
                )PERIODO_FINE
            WHERE BV.DATA_EROGAZIONE BETWEEN PERIODO_INIZIO.DATA_INIZ AND PERIODO_FINE.DATA_FINE
            AND BV.ID_CIRCUITO_BREAK = CB.ID_CIRCUITO_BREAK
            AND CB.ID_BREAK = BRK.ID_BREAK
			AND BV.FLG_ANNULLATO='N'
			AND CB.FLG_ANNULLATO='N'
            AND BRK.FLG_ANNULLATO='N'
            GROUP BY BRK.ID_PROIEZIONE
            )CALCOLO_ASSEGNATO,
            (SELECT ID_CINEMA,NOME_CINEMA,FLG_VENDITA_PUBB_LOCALE AS PUBB_LOCALE FROM CD_CINEMA CINEMA
            )CINEMA,
            (SELECT ID_CINEMA,ID_SALA,NOME_SALA FROM CD_SALA
            )SALA, CD_SCHERMO SCHERMO,
            (SELECT PROIEZIONE.ID_SCHERMO,PROIEZIONE.DATA_PROIEZIONE,MIN(PROIEZIONE.ID_PROIEZIONE) ID_PROIEZIONE
            FROM CD_PROIEZIONE PROIEZIONE,
                (SELECT DATA_INIZ FROM PERIODI
                WHERE ANNO = p_anno_inizio
                AND CICLO = p_ciclo_inizio
                AND PER = p_periodo_inizio
                )PERIODO_INIZIO,
                (SELECT DATA_FINE FROM PERIODI
                WHERE ANNO = p_anno_fine
                AND CICLO = p_ciclo_fine
                AND PER = p_periodo_fine
                )PERIODO_FINE
            WHERE PROIEZIONE.DATA_PROIEZIONE BETWEEN PERIODO_INIZIO.DATA_INIZ AND PERIODO_FINE.DATA_FINE
            AND PROIEZIONE.FLG_ANNULLATO='N'
            GROUP BY PROIEZIONE.DATA_PROIEZIONE ,PROIEZIONE.ID_SCHERMO
            ORDER BY PROIEZIONE.DATA_PROIEZIONE
            )PROIEZIONI,periodi
            WHERE PROIEZIONI.ID_PROIEZIONE = CALCOLO_ASSEGNATO.ID_PROIEZIONE
            AND PROIEZIONI.ID_PROIEZIONE = CALCOLO_NOMINALE.ID_PROIEZIONE
            AND PROIEZIONI.ID_SCHERMO = SCHERMO.ID_SCHERMO
            AND PROIEZIONI.DATA_PROIEZIONE BETWEEN data_iniz and data_fine
            AND SCHERMO.ID_SALA = SALA.ID_SALA
            AND (p_sala IS NULL OR SALA.ID_SALA = p_sala)
            AND SALA.ID_CINEMA = CINEMA.ID_CINEMA
            AND (p_cinema IS NULL OR CINEMA.ID_CINEMA = p_cinema)
            group by CINEMA.NOME_CINEMA,CINEMA.PUBB_LOCALE, SALA.NOME_SALA,
            periodi.DATA_iniz,periodi.data_fine, periodi.anno, periodi.ciclo,
            periodi.per, CALCOLO_ASSEGNATO.SEC_VENDIBILI,
            CALCOLO_NOMINALE.SEC_ASSEGNATI,SALA.ID_SALA
            ORDER BY periodi.DATA_iniz,periodi.data_fine,CINEMA.NOME_CINEMA;

RETURN cur_ver_assegnato;

END FU_VERIFICA_ASSEGNATO;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_ASSEGNATO
-- DESCRIZIONE:  la funzione, fissate le sale e il periodo,
--               restituisce i secondi vendibili e nominali
--               con i prodotti di vendita relativi a quel periodo
--
-- INPUT:
--      id sala e periodo
--
-- OUTPUT: secondi e prodotti di vendita risultanti
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_DETTAGLIO_ASSEGNATO (p_sala                    CD_SALA.ID_SALA%TYPE,
                                 p_anno                    periodi.ANNO%TYPE,
                                 p_ciclo                   periodi.CICLO%TYPE,
                                 p_periodo                 periodi.PER%TYPE
                                 )
                                 RETURN C_DETT_ASSEGNATO
IS

cur_dett_assegnato       C_DETT_ASSEGNATO;

BEGIN

OPEN cur_dett_assegnato FOR
    SELECT      CALCOLO_ASSEGNATO.SEC_ASSEGNATI, T_BRK.DURATA_SECONDI AS SEC_NOMINALI, CALCOLO_ASSEGNATO.ID_PRODOTTO_VENDITA
            FROM
             CD_TIPO_BREAK T_BRK, CD_PRODOTTO_VENDITA PRD_VEN,
            (SELECT BRK.ID_PROIEZIONE, BV.ID_PRODOTTO_VENDITA, SUM(BV.SECONDI_ASSEGNATI) SEC_ASSEGNATI FROM
            CD_BREAK BRK,CD_CIRCUITO_BREAK CB,CD_BREAK_VENDITA BV,
                (SELECT DATA_INIZ FROM PERIODI
                WHERE ANNO = p_anno
                AND CICLO = p_ciclo
                AND PER = p_periodo
                )PERIODO_INIZIO,
                (SELECT DATA_FINE FROM PERIODI
                WHERE ANNO = p_anno
                AND CICLO = p_ciclo
                AND PER = p_periodo
                )PERIODO_FINE
            WHERE BV.DATA_EROGAZIONE BETWEEN PERIODO_INIZIO.DATA_INIZ AND PERIODO_FINE.DATA_FINE
            AND BV.ID_CIRCUITO_BREAK = CB.ID_CIRCUITO_BREAK
            AND CB.ID_BREAK = BRK.ID_BREAK
            AND BV.FLG_ANNULLATO='N'
            AND CB.FLG_ANNULLATO='N'
            AND BRK.FLG_ANNULLATO='N'
            GROUP BY BRK.ID_PROIEZIONE, BV.ID_PRODOTTO_VENDITA
            )CALCOLO_ASSEGNATO,
            (SELECT ID_CINEMA,ID_SALA,NOME_SALA FROM CD_SALA
            )SALA, CD_SCHERMO SCHERMO,
            (SELECT PROIEZIONE.ID_SCHERMO,PROIEZIONE.DATA_PROIEZIONE,MIN(PROIEZIONE.ID_PROIEZIONE) ID_PROIEZIONE
            FROM CD_PROIEZIONE PROIEZIONE,
                (SELECT DATA_INIZ FROM PERIODI
                WHERE ANNO = p_anno
                AND CICLO = p_ciclo
                AND PER = p_periodo
                )PERIODO_INIZIO,
                (SELECT DATA_FINE FROM PERIODI
                WHERE ANNO = p_anno
                AND CICLO = p_ciclo
                AND PER = p_periodo
                )PERIODO_FINE
            WHERE PROIEZIONE.DATA_PROIEZIONE BETWEEN PERIODO_INIZIO.DATA_INIZ AND PERIODO_FINE.DATA_FINE
            AND PROIEZIONE.FLG_ANNULLATO='N'
            GROUP BY PROIEZIONE.DATA_PROIEZIONE ,PROIEZIONE.ID_SCHERMO
            ORDER BY PROIEZIONE.DATA_PROIEZIONE
            )PROIEZIONI,periodi
            WHERE PROIEZIONI.ID_PROIEZIONE = CALCOLO_ASSEGNATO.ID_PROIEZIONE
            AND PROIEZIONI.ID_SCHERMO = SCHERMO.ID_SCHERMO
            AND PROIEZIONI.DATA_PROIEZIONE BETWEEN periodi.data_iniz and periodi.data_fine
            AND SCHERMO.ID_SALA = SALA.ID_SALA
            AND SALA.ID_SALA = p_sala
            AND T_BRK.ID_TIPO_BREAK = PRD_VEN.ID_TIPO_BREAK
            AND PRD_VEN.ID_PRODOTTO_VENDITA = CALCOLO_ASSEGNATO.ID_PRODOTTO_VENDITA
            group by CALCOLO_ASSEGNATO.SEC_ASSEGNATI, T_BRK.DURATA_SECONDI,
            CALCOLO_ASSEGNATO.ID_PRODOTTO_VENDITA;

RETURN cur_dett_assegnato;

END FU_DETTAGLIO_ASSEGNATO;

FUNCTION FU_GET_COD_TIPO_PUBB(p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN C_COD_TIPO_PUBB IS

v_cod_tipo_pubb  C_COD_TIPO_PUBB;
BEGIN
    OPEN v_cod_tipo_pubb FOR
      SELECT ID_PRODOTTO_PUBB, COD_TIPO_PUBB
        FROM   CD_PRODOTTO_PUBB
                       WHERE  COD_TIPO_PUBB IN (
                                 SELECT COD_TIPO_PUBB
                                 FROM   CD_TIPO_PUBB_GRUPPO
                                 WHERE  ID_GRUPPO_TIPI_PUBB IN (
                                           SELECT ID_GRUPPO_TIPI_PUBB
                                           FROM   CD_GRUPPO_TIPI_PUBB
                                           WHERE  ID_GRUPPO_TIPI_PUBB IN (
                                                     SELECT ID_GRUPPO_TIPI_PUBB
                                                     FROM   CD_PRODOTTO_PUBB
                                                     WHERE  ID_PRODOTTO_PUBB IN (
                                                                SELECT ID_PRODOTTO_PUBB
                                                                FROM   CD_PRODOTTO_VENDITA
                                                                WHERE  ID_PRODOTTO_VENDITA = p_id_prodotto_vendita))))
                       OR     	ID_PRODOTTO_PUBB IN (
                                       SELECT ID_PRODOTTO_PUBB
                                       FROM   CD_PRODOTTO_VENDITA
                                       WHERE  ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
                                       AND COD_TIPO_PUBB IS NOT NULL);
RETURN v_cod_tipo_pubb;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                            (-20009,
                                'Funzione FU_GET_COD_TIPO_PUBB in errore: '|| SQLERRM
                            );
END FU_GET_COD_TIPO_PUBB;

END PA_CD_PRODOTTO_VENDITA; 
/

