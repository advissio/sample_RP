CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_PERIODO_SPECIALE IS

settimana_sipra_exist exception;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_PERIODO_SPECIALE
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo periodo speciale nel sistema
--
-- OPERAZIONI:
--   1) Memorizza il periodo speciale (CD_PERIODO_SPECIALE)
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--            
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_PERIODO_SPECIALE(p_data_inizio                       CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
                                        p_data_fine                         CD_PERIODO_SPECIALE.DATA_FINE%TYPE,
                                        p_esito                             OUT NUMBER)
IS
v_esiste_settimana number;
BEGIN -- PR_INSERISCI_PERIODO_SPECIALE
--

p_esito     := 1;
 
--P_ID_PERIODO_SPECIALE := PERIODO_SPECIALE_SEQ.NEXTVAL;

 select count(1)
 into  v_esiste_settimana
 from periodi
 where data_iniz = p_data_inizio
 and   data_fine = p_data_fine;
 
 if v_esiste_settimana >0 then
    raise settimana_sipra_exist;
 end if;
     --
          SAVEPOINT ann_ins;
      --

    -- effettuo l'INSERIMENTO
       INSERT INTO CD_PERIODO_SPECIALE
         (DATA_INIZIO,
          DATA_FINE--,
          --UTEMOD,
          --DATAMOD
         )
       VALUES
         (p_data_inizio,
          p_data_fine--,
          --user,
          --FU_DATA_ORA
          );
          
          
          
          

EXCEPTION
        when settimana_sipra_exist then
        RAISE_APPLICATION_ERROR(-20021, 'Periodo non inserito perche esiste una settimana standard');
         ROLLBACK TO ann_ins;
  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
        WHEN OTHERS THEN
        p_esito := -11;
        RAISE_APPLICATION_ERROR(-20022, 'PROCEDURA PR_INSERISCI_PERIODO_SPECIALE: Insert non eseguita, verificare la coerenza dei parametri '||FU_STAMPA_PERIODO_SPECIALE(p_data_inizio,
                                                                                                                                                                          p_data_fine) || '   ' || sqlerrm);
        ROLLBACK TO ann_ins;

END;



FUNCTION  FU_INSERISCI_PERIODO_SPECIALE(p_data_inizio                       CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
                                        p_data_fine                         CD_PERIODO_SPECIALE.DATA_FINE%TYPE) 
                                        return cd_periodo_speciale.ID_PERIODO_SPECIALE%type
IS
V_ID_PERIODO_SPECIALE cd_periodo_speciale.ID_PERIODO_SPECIALE%TYPE;
V_ESITO  Number;
BEGIN 
    PR_INSERISCI_PERIODO_SPECIALE(p_data_inizio,p_data_fine,v_esito);
    /*select CD_PERIODO_SPECIALE_SEQ.CURRVAL
    into   V_ID_PERIODO_SPECIALE
    from dual;*/
    return V_ID_PERIODO_SPECIALE; 
EXCEPTION  
        WHEN OTHERS THEN
            raise;
END FU_INSERISCI_PERIODO_SPECIALE;



-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_PERIODO_SPECIALE
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un periodo speciale dal sistema
--
-- OPERAZIONI:
--   3) Elimina il periodo speciale
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
PROCEDURE PR_ELIMINA_PERIODO_SPECIALE( p_id_periodo_speciale   IN CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE,
                                        p_esito                  OUT NUMBER)
IS

--
BEGIN -- PR_ELIMINA_PERIODO_SPECIALE
--

p_esito     := 1;

     --
          SAVEPOINT ann_del;


       -- effettua l'ELIMINAZIONE
       DELETE FROM CD_PERIODO_SPECIALE
       WHERE ID_PERIODO_SPECIALE = p_id_periodo_speciale;
       --
    p_esito := SQL%ROWCOUNT;

  EXCEPTION
          WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20022, 'Procedura PR_ELIMINA_PERIODO_SPECIALE: Delete non eseguita, verificare la coerenza dei parametri');
        ROLLBACK TO ann_del;


END;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CERCA_PERIODO_SPEC
-- DESCRIZIONE:  restituisce i periodi speciali che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_PERIODO_SPEC(p_id_periodo_speciale        CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE,
                               p_data_inizio                CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
                               p_data_fine                  CD_PERIODO_SPECIALE.DATA_FINE%TYPE)
                               RETURN C_PER_SPECIALE
IS
c_per_spec_return   C_PER_SPECIALE;
BEGIN
    OPEN c_per_spec_return FOR
        SELECT      ID_PERIODO_SPECIALE, DATA_INIZIO, DATA_FINE
        FROM        CD_PERIODO_SPECIALE
        WHERE       (p_id_periodo_speciale IS NULL OR  CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE = p_id_periodo_speciale)
        AND         (p_data_inizio IS NULL OR CD_PERIODO_SPECIALE.DATA_INIZIO = p_data_inizio)
        AND         (p_data_fine IS NULL OR CD_PERIODO_SPECIALE.DATA_FINE = p_data_fine)
        ORDER BY    DATA_INIZIO DESC;
RETURN c_per_spec_return;
END FU_CERCA_PERIODO_SPEC;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_DATA_INIZIO_PERIODO_SPEC
-- DESCRIZIONE:  restituisce le date inizio dei periodi speciali
--
-- REALIZZATORE  Michele Borgogno, Altran, Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATA_INIZIO_P_SPEC RETURN C_DATA_INIZIO_P_SPEC IS
v_data_inizio  C_DATA_INIZIO_P_SPEC;
BEGIN
    OPEN v_data_inizio FOR
        SELECT DISTINCT(DATA_INIZIO)
        FROM CD_PERIODO_SPECIALE
        --WHERE DATA_FINE > sysdate
        ORDER BY DATA_INIZIO DESC;
RETURN v_data_inizio;
END FU_GET_DATA_INIZIO_P_SPEC;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_DATA_FINE_P_SPEC
-- DESCRIZIONE:  restituisce le date fine per una data inizio dei periodi speciali

-- REALIZZATORE  Michele Borgogno, Altran, Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_DATA_FINE_P_SPEC(p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE) RETURN C_DATA_FINE_P_SPEC IS
v_data_fine C_DATA_FINE_P_SPEC;
BEGIN
    OPEN v_data_fine FOR
     SELECT DISTINCT(CD_PERIODO_SPECIALE.DATA_FINE)
        FROM CD_PERIODO_SPECIALE
        WHERE CD_PERIODO_SPECIALE.DATA_INIZIO = p_data_inizio;
RETURN v_data_fine;
END FU_GET_DATA_FINE_P_SPEC;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_GET_ID_PERIODO_SPEC
-- DESCRIZIONE:  restituisce l'id del periodo speciale
--
-- INPUT: data inizio periodo, data fine periodo
--
-- REALIZZATORE  Michele Borgogno, Altran, Novembre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_GET_ID_PERIODO_SPEC(p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE, p_data_fine CD_PERIODO_SPECIALE.DATA_FINE%TYPE) RETURN CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE IS
id_periodo_spec  CD_PERIODO_SPECIALE.ID_PERIODO_SPECIALE%TYPE;
BEGIN
        SELECT ID_PERIODO_SPECIALE INTO id_periodo_spec
        FROM CD_PERIODO_SPECIALE
        WHERE DATA_INIZIO = p_data_inizio
        AND DATA_FINE = p_data_fine;
RETURN id_periodo_spec;
END FU_GET_ID_PERIODO_SPEC;

 -- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_PERIODO_SPECIALE
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- OUTPUT: varchar che contiene i parametri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


FUNCTION FU_STAMPA_PERIODO_SPECIALE(p_data_inizio                       CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE,
                                    p_data_fine                         CD_PERIODO_SPECIALE.DATA_FINE%TYPE
                                    )  RETURN VARCHAR2
IS

BEGIN

IF v_stampa_periodo_speciale = 'ON'

    THEN

     RETURN 'DATA_INIZIO: '      || p_data_inizio         || ', '||
            'DATA_FINE: '           || p_data_fine;

END IF;

END  FU_STAMPA_PERIODO_SPECIALE;

 -- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_INSERISCI_PERIODO_ISP
-- DESCRIZIONE:  Inserisce un periodo cinema se non e gia presente in tabella 
--               e ritorna l'id_periodo
--
-- INPUT: data inizio periodo
--        data fine periodo
-- OUTPUT: id periodo
--
-- REALIZZATORE  Michele Borgogno, Altran, Maggio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------


PROCEDURE PR_INSERISCI_PERIODO_ISP(p_data_inizio    CD_PERIODI_CINEMA.DATA_INIZIO%TYPE,
                                   p_data_fine      CD_PERIODI_CINEMA.DATA_FINE%TYPE,
                                   p_id_periodo     OUT NUMBER) IS

v_count NUMBER;

BEGIN

    SAVEPOINT SV_INSERISCI_PERIODO_ISP;

    SELECT count(ID_PERIODO) INTO v_count
        FROM CD_PERIODI_CINEMA
        WHERE DATA_INIZIO = p_data_inizio
        AND DATA_FINE = p_data_fine;
    
    IF v_count > 0 THEN
        SELECT ID_PERIODO INTO p_id_periodo
            FROM CD_PERIODI_CINEMA
            WHERE DATA_INIZIO = p_data_inizio
            AND DATA_FINE = p_data_fine; 
    ELSE
        INSERT INTO CD_PERIODI_CINEMA (DATA_INIZIO, DATA_FINE)
            VALUES (p_data_inizio, p_data_fine);
        
        SELECT CD_PERIODI_CINEMA_SEQ.CURRVAL INTO p_id_periodo FROM DUAL;      
    END IF;
    
EXCEPTION
WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20019, 'PROCEDURA PR_INSERISCI_PERIODO_ISP: ERRORE INATTESO INSERENDO IL PERIODO CINEMA '||SQLERRM);
    ROLLBACK TO SV_INSERISCI_PERIODO_ISP;
END PR_INSERISCI_PERIODO_ISP;

 -- --------------------------------------------------------------------------------------------
-- PROCEDURE FU_COMPATIB_UNITA_TEMP
-- DESCRIZIONE:  Controlla che il numero di giorni del periodo sia compatibile (uguale o multiplo)
--               con un'unita temporale
--
-- INPUT: data inizio periodo
--        data fine periodo
-- OUTPUT: 0 se non e compatibile con nessuna unita temporale.
--         1 se compatibile
--
-- REALIZZATORE  Michele Borgogno, Altran, Maggio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_COMPATIB_UNITA_TEMP(p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE, p_data_fine CD_PERIODO_SPECIALE.DATA_FINE%TYPE) RETURN NUMBER IS
v_num_giorni number;
v_num_giorni_umt number;
v_resto number;
v_compatib number;
v_data_temp        cd_prodotto_acquistato.data_inizio%type;
v_numero_di_giorni cd_unita_misura_temp.numero_di_giorni%type;
v_numero_di_mesi   cd_unita_misura_temp.numero_di_mesi%type;
BEGIN
    v_compatib := 0;
    v_num_giorni := (p_data_fine - p_data_inizio)+1;
    
    FOR UMT IN (select distinct mst.numero_di_giorni,mst.numero_di_mesi 
                --into   v_numero_di_giorni,v_numero_di_mesi
                from  cd_prodotto_pubb pb, 
                cd_misura_prd_vendita mp,
                cd_unita_misura_temp mst
                where pb.cod_categoria_prodotto='ISP'
                and  mp.ID_PRODOTTO_PUBB = pb.ID_PRODOTTO_PUBB
                and mst.ID_UNITA = mp.ID_UNITA) LOOP
        
        if(UMT.numero_di_giorni = 0 and UMT.numero_di_mesi = 0) then
            RAISE_APPLICATION_ERROR(-20013,'Numero di giorni e numero di mesi a 0 per la misura temporale (id_unita) ');
        else
            if(UMT.numero_di_mesi != 0) then
                SELECT add_months(p_data_inizio -1, UMT.numero_di_mesi) INTO v_data_temp FROM dual;
                v_num_giorni_umt := v_data_temp - p_data_inizio + 1;
            else
                v_num_giorni_umt := UMT.numero_di_giorni;      
            end if;
            
            if (v_num_giorni_umt = 3 and v_num_giorni != 3) then
                v_resto := 1;
            else
                SELECT MOD(v_num_giorni, v_num_giorni_umt) into v_resto from dual; 
            end if;
            
            if (v_resto = 0) then
                v_compatib := 1;
            end if;

        end if;                                
    END LOOP;  
    
    RETURN v_compatib;
EXCEPTION
WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20013, 'FU_COMPATIB_UNITA_TEMP: SI E'' VERIFICATO UN ERRORE , ERRORE :'||SQLERRM);

END FU_COMPATIB_UNITA_TEMP;




 -- --------------------------------------------------------------------------------------------
-- PROCEDURE FU_COMPATIB_UNITA_TEMP_TAB
-- DESCRIZIONE:  Controlla che il numero di giorni del periodo sia compatibile (uguale o multiplo)
--               con un'unita temporale
--
-- INPUT: data inizio periodo
--        data fine periodo
-- OUTPUT: 0 se non e compatibile con nessuna unita temporale.
--         1 se compatibile
--
-- REALIZZATORE  MAuro Viel, Altran, Febbraio 2010
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------

FUNCTION FU_COMPATIB_UNITA_TEMP_TAB(p_data_inizio CD_PERIODO_SPECIALE.DATA_INIZIO%TYPE, p_data_fine CD_PERIODO_SPECIALE.DATA_FINE%TYPE) RETURN NUMBER IS
v_num_giorni number;
v_num_giorni_umt number;
v_resto number;
v_compatib number;
v_data_temp        cd_prodotto_acquistato.data_inizio%type;
v_numero_di_giorni cd_unita_misura_temp.numero_di_giorni%type;
v_numero_di_mesi   cd_unita_misura_temp.numero_di_mesi%type;
BEGIN
    v_compatib := 0;
    v_num_giorni := (p_data_fine - p_data_inizio)+1;
    
    FOR UMT IN (select distinct mst.numero_di_giorni,mst.numero_di_mesi 
                --into   v_numero_di_giorni,v_numero_di_mesi
                from  cd_prodotto_pubb pb, 
                cd_misura_prd_vendita mp,
                cd_unita_misura_temp mst
                where pb.cod_categoria_prodotto='TAB'
                and  mp.ID_PRODOTTO_PUBB = pb.ID_PRODOTTO_PUBB
                and mst.ID_UNITA = mp.ID_UNITA) LOOP
        
        if(UMT.numero_di_giorni = 0 and UMT.numero_di_mesi = 0) then
            RAISE_APPLICATION_ERROR(-20013,'Numero di giorni e numero di mesi a 0 per la misura temporale (id_unita) ');
        else
            if(UMT.numero_di_mesi != 0) then
                SELECT add_months(p_data_inizio -1, UMT.numero_di_mesi) INTO v_data_temp FROM dual;
                v_num_giorni_umt := v_data_temp - p_data_inizio + 1;
            else
                v_num_giorni_umt := UMT.numero_di_giorni;      
            end if;
            
            if (v_num_giorni_umt = 3 and v_num_giorni != 3) then
                v_resto := 1;
            else
                v_resto := MOD(v_num_giorni, v_num_giorni_umt);
            end if;
            
            if (v_resto = 0) then
                v_compatib := 1;
            end if;

        end if;                                
    END LOOP;  
    
    RETURN v_compatib;
EXCEPTION
WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20013, 'FU_COMPATIB_UNITA_TEMP_TAB: SI E'' VERIFICATO UN ERRORE , ERRORE :'||SQLERRM);

END FU_COMPATIB_UNITA_TEMP_TAB;


END PA_CD_PERIODO_SPECIALE; 
/

