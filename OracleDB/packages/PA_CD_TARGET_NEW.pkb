CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_TARGET_NEW AS
/***************************************************************************************
   NAME:      PA_CD_TARGET
   AUTHOR:    Simone Bottani (Altran)
   PURPOSE:   Questo package contiene procedure/funzioni necessarie per la gestione dei target
              e dell'associazione agli spettacoli


   REVISIONS:
   Ver        Date        Author                    Description
   ---------  ----------  ---------------           ------------------------------------
   1.0        22/06/2010  Simone Bottani (Altran)   Created this package.
****************************************************************************************/

/*******************************************************************************
 Funzione FU_GET_TARGET
 Author:  Simone Bottani , Altran, Giugno 2010

 La funzione restituisce tutti i target che contengono le stringhe cercate
*******************************************************************************/
FUNCTION FU_GET_TARGET(p_nome_target CD_TARGET.NOME_TARGET%TYPE, p_descrizione CD_TARGET.DESCR_TARGET%TYPE) RETURN C_TARGET IS
v_target C_TARGET;
BEGIN
    OPEN v_target FOR
    SELECT ID_TARGET, NOME_TARGET, DESCR_TARGET
    FROM CD_TARGET
    WHERE (p_nome_target IS NULL OR UPPER(NOME_TARGET) LIKE UPPER('%'||p_nome_target||'%'))
    AND (p_descrizione IS NULL OR UPPER(DESCR_TARGET) LIKE UPPER('%'||p_descrizione||'%'))
    AND FLG_ANNULLATO = 'N'
    ORDER BY NOME_TARGET;
    RETURN v_target;
END FU_GET_TARGET;
--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_AGGIUNGI_TARGET
--
-- DESCRIZIONE:  Inserisce un nuovo target nel sistema
--
-- INPUT:
--      p_nome_target          Nome del target
--      p_descrizione          Descrizione del target
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_AGGIUNGI_TARGET(p_nome_target CD_TARGET.NOME_TARGET%TYPE,p_descrizione CD_TARGET.DESCR_TARGET%TYPE) IS
BEGIN
    INSERT INTO CD_TARGET(NOME_TARGET, DESCR_TARGET)
    VALUES(p_nome_target, p_descrizione);
END PR_AGGIUNGI_TARGET;    
--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_TARGET
--
-- DESCRIZIONE:  Elimina un target dal sistema
--
-- INPUT:
--      p_id_target            Id del target da eliminare
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_TARGET(p_id_target CD_TARGET.ID_TARGET%TYPE) IS
v_num_piani NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_num_piani
    FROM CD_PIANIFICAZIONE
    WHERE ID_TARGET = p_id_target
    AND FLG_ANNULLATO = 'N'
    AND FLG_SOSPESO = 'N';
    --
    UPDATE CD_TARGET
    SET FLG_ANNULLATO = 'S'
    WHERE ID_TARGET =  p_id_target
    AND FLG_ANNULLATO = 'N';   
END PR_ELIMINA_TARGET; 
--
-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_TARGET
--
-- DESCRIZIONE:  Modifica un target presente nel sistema
--
-- INPUT:
--      p_id_target            Id del target da modificare
--      p_nome_target          Nome del target
--      p_descrizione          Descrizione del target
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_TARGET(p_id_target CD_TARGET.ID_TARGET%TYPE, p_nome_target CD_TARGET.NOME_TARGET%TYPE,p_descrizione CD_TARGET.DESCR_TARGET%TYPE) IS
BEGIN
    UPDATE CD_TARGET
    SET NOME_TARGET = p_nome_target,
        DESCR_TARGET = p_descrizione
    WHERE ID_TARGET =  p_id_target
    AND FLG_ANNULLATO = 'N';   
END PR_MODIFICA_TARGET; 
--
/*******************************************************************************
 Funzione FU_GET_TARGET_SPETTACOLO
 Author:  Simone Bottani , Altran, Giugno 2010

 La funzione restituisce tutti i target associati ad uno spettacolo
*******************************************************************************/
FUNCTION FU_GET_TARGET_SPETTACOLO(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE) RETURN C_TARGET IS
v_target C_TARGET;
BEGIN
    OPEN v_target FOR
    SELECT T.ID_TARGET, T.NOME_TARGET, T.DESCR_TARGET
    FROM CD_TARGET T, CD_SPETT_TARGET ST
    WHERE ST.ID_SPETTACOLO = p_id_spettacolo
    AND T.ID_TARGET = ST.ID_TARGET
    AND FLG_ANNULLATO = 'N'
    ORDER BY NOME_TARGET;
    RETURN v_target;
END FU_GET_TARGET_SPETTACOLO;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ASSOCIA_SPETTACOLO_TARGET
--
-- DESCRIZIONE:  Associa ad uno spettacolo un target di riferimento
--
-- INPUT:
--      p_id_spettacolo        Id dello spettacolo
--      p_id_target            Id del target da modificare
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_SPETTACOLO_TARGET(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE) IS
BEGIN
    INSERT INTO CD_SPETT_TARGET(ID_SPETTACOLO, ID_TARGET)
    VALUES(p_id_spettacolo, p_id_target);
END PR_ASSOCIA_SPETTACOLO_TARGET;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_DISSOCIA_SPETTACOLO_TARGET
--
-- DESCRIZIONE:  Elimina l'associazione tra uno spettacolo ed un target
--
-- INPUT:
--      p_id_spettacolo        Id dello spettacolo
--      p_id_target            Id del target da modificare
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_DISSOCIA_SPETTACOLO_TARGET(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE) IS
BEGIN
    DELETE FROM CD_SPETT_TARGET
    WHERE ID_SPETTACOLO = p_id_spettacolo
    AND ID_TARGET = p_id_target;
END PR_DISSOCIA_SPETTACOLO_TARGET;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ASSOCIA_TARGET_SPET_MASS
--
-- DESCRIZIONE:  Associa ad uno spettacolo una lista di target
--
-- INPUT:
--      p_id_spettacolo        Id dello spettacolo
--      p_target               Lista di id di target da associare
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Giugno 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_TARGET_SPET_MASS(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE, p_target id_list_type) IS
v_nuovi_target   varchar2(32000);
v_target_associati varchar2(32000);
BEGIN
    IF p_target.COUNT = 0 THEN
        DELETE FROM CD_SPETT_TARGET S
        WHERE S.ID_SPETTACOLO = p_id_spettacolo;
    ELSE
        FOR i IN p_target.FIRST..p_target.LAST LOOP     
              v_nuovi_target := v_nuovi_target||LPAD(p_target(i),5,'0')||'|';
        END LOOP;
        --dbms_output.PUT_LINE('Nuovi target: '||v_nuovi_target);
        FOR TARGET IN (SELECT T.ID_TARGET
        FROM CD_TARGET T, CD_SPETT_TARGET ST
        WHERE ST.ID_SPETTACOLO = p_id_spettacolo
        AND T.ID_TARGET = ST.ID_TARGET
        AND FLG_ANNULLATO = 'N') LOOP
            v_target_associati := v_target_associati||LPAD(TARGET.ID_TARGET,5,'0')||'|';
        END LOOP;
        --dbms_output.PUT_LINE('Vecchi target: '||v_target_associati);
        --
        INSERT INTO CD_SPETT_TARGET(ID_SPETTACOLO, ID_TARGET)
        SELECT p_id_spettacolo, T.ID_TARGET
        FROM DUAL, CD_TARGET T
        WHERE T.ID_TARGET IN
        (SELECT ID_TARGET FROM CD_TARGET TAR
        WHERE instr ('|'||v_target_associati||'|','|'||LPAD(TAR.ID_TARGET,5,'0')||'|') < 1
        AND instr ('|'||v_nuovi_target||'|','|'||LPAD(TAR.ID_TARGET,5,'0')||'|') >= 1);
        --
        DELETE FROM CD_SPETT_TARGET S
        WHERE S.ID_SPETTACOLO = p_id_spettacolo
        AND S.ID_TARGET IN
        (SELECT ID_TARGET FROM CD_TARGET TAR
        WHERE instr ('|'||v_nuovi_target||'|','|'||LPAD(TAR.ID_TARGET,5,'0')||'|') < 1
        AND instr ('|'||v_target_associati||'|','|'||LPAD(TAR.ID_TARGET,5,'0')||'|') >= 1);
    END IF;
END PR_ASSOCIA_TARGET_SPET_MASS;

/*******************************************************************************
 Funzione FU_GET_SALE_ASSOCIATE
 Author:  Michele Borgogno , Altran, Luglio 2010

 La funzione restituisce tutti le sale associate a prodotti di vendita con target valorizzato
*******************************************************************************/
FUNCTION FU_GET_SALE_ASSOCIATE(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_mostra_sale_non_visibili BOOLEAN) RETURN C_SALE_ASSOCIATE IS
v_sale_associate C_SALE_ASSOCIATE;
BEGIN
    OPEN v_sale_associate FOR
        select distinct(com.id_sala), sa.NOME_SALA, cir.NOME_CIRCUITO, ci.NOME_CINEMA, co.COMUNE, pr.ABBR, pa.DATA_INIZIO, pa.DATA_FINE, ci.FLG_VIRTUALE
        from cd_comunicato com, 
            cd_prodotto_acquistato pa, 
            cd_prodotto_vendita pv, 
            cd_pianificazione pia,
            cd_sala sa,
            cd_cinema ci,
            cd_comune co,
            cd_provincia pr,
            cd_circuito cir
        where com.FLG_ANNULLATO = 'N'
        and com.FLG_SOSPESO = 'N'
        and com.COD_DISATTIVAZIONE is null
        --and com.DATA_EROGAZIONE_PREV between to_date('27062010','DDMMYYYY') and to_date('03072010','DDMMYYYY')
        --and com.DATA_EROGAZIONE_PREV between to_date('30052010','DDMMYYYY') and to_date('05062010','DDMMYYYY')
        --and com.DATA_EROGAZIONE_PREV between to_date('20062010','DDMMYYYY') and to_date('26062010','DDMMYYYY')
        and com.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine       
        and com.ID_SALA = sa.ID_SALA
        and sa.ID_CINEMA = ci.ID_CINEMA
        and sa.FLG_ANNULLATO = 'N'
        and co.ID_COMUNE = ci.ID_COMUNE
        and pr.ID_PROVINCIA = co.ID_PROVINCIA
        and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
        and pa.FLG_ANNULLATO = 'N'
        and pa.FLG_SOSPESO = 'N'
        and pa.COD_DISATTIVAZIONE is null
        and pa.ID_PIANO = pia.ID_PIANO
        and pa.ID_VER_PIANO = pia.ID_VER_PIANO
        and pa.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA
        and pv.FLG_ANNULLATO = 'N'
        and pv.ID_TARGET is not null
        and pv.ID_CIRCUITO = cir.ID_CIRCUITO
        and cir.FLG_ANNULLATO = 'N'
        and (p_id_cliente is null or pia.ID_CLIENTE = p_id_cliente) 
        and (p_id_circuito is null or cir.ID_CIRCUITO = p_id_circuito) 
        and (p_id_target is null or pv.id_target = p_id_target) 
        order by id_sala;
    RETURN v_sale_associate;
END FU_GET_SALE_ASSOCIATE;

/*******************************************************************************
 Funzione FU_GET_SALE_ASSOCIABILI
 Author:  Michele Borgogno , Altran, Luglio 2010
 
 --  MODIFICHE 
--    13/07/2011    Tommaso D'Anna, Teoresi srl
--                      Rimosso flg_attivo e sostituito con data_inizio_validita

 La funzione restituisce tutte le sale con disponibilita, compatibili con il target specificato
*******************************************************************************/
FUNCTION FU_GET_SALE_ASSOCIABILI(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_durata CD_COEFF_CINEMA.DURATA%TYPE) RETURN C_SALE_ASSOCIABILI IS
v_sale_associabili C_SALE_ASSOCIABILI;
BEGIN
    OPEN v_sale_associabili FOR
SELECT NOME_CINEMA, COMUNE, ID_SALA, NOME_SALA,
       GIORNI_TARGET,
       AFFOLLAMENTO
FROM
(
SELECT NOME_CINEMA, COMUNE, ID_SALA, NOME_SALA,
       GIORNI_TARGET,
       --PA_CD_ESTRAZIONE_PROD_VENDITA.FU_AFFOLLAMENTO_SALA_STATO(p_data_inizio,p_data_fine,id_sala,null,'PRE', giorni_target) as affollamento
       1 as affollamento
FROM
(
SELECT 
       c.NOME_CINEMA, com.COMUNE,
       num_sala as id_sala, s.NOME_SALA,
       LTRIM(MAX(SYS_CONNECT_BY_PATH(to_char(data_proiezione,'D'),','))
       KEEP (DENSE_RANK LAST ORDER BY curr),',') AS giorni_target
       --0 as affollamento
FROM  cd_comune com, cd_cinema c, cd_sala s, 
(SELECT id_sala as num_sala,
               data_proiezione,
               --PA_CD_ESTRAZIONE_PROD_VENDITA.FU_AFFOLLAMENTO_SALA_STATO(p_data_inizio,p_data_fine,id_sala,null,'PRE', null, data_proiezione) as affollamento,
               ROW_NUMBER() OVER (PARTITION BY id_sala ORDER BY data_proiezione) AS curr,
               ROW_NUMBER() OVER (PARTITION BY id_sala ORDER BY data_proiezione) -1 AS prev
        FROM
        (
        --
         select ID_SALA, DATA_PROIEZIONE, 
         PA_CD_ESTRAZIONE_PROD_VENDITA.FU_AFFOLLAMENTO_SALA_STATO(p_data_inizio,p_data_fine,id_sala,null,'PRE') as affollamento
         from 
         (
         select 
         sa.ID_SALA, pro.DATA_PROIEZIONE
         from cd_sala sa,cd_schermo sch, cd_proiezione pro, 
            cd_proiezione_spett ps, cd_spettacolo spe,
            cd_spett_target spt, cd_target tar
        where sch.ID_SALA = sa.ID_SALA
        and sa.FLG_ANNULLATO = 'N'
        and sa.FLG_VISIBILE = 'S'
        and pro.ID_SCHERMO = sch.ID_SCHERMO
        and pro.FLG_ANNULLATO = 'N'
        and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
        and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
        and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
        and tar.ID_TARGET = spt.id_target
        and pro.DATA_PROIEZIONE between p_data_inizio and p_data_fine
        and TRUNC(pro.DATA_PROIEZIONE) >= TRUNC(sysdate)
     --   and (p_id_circuito is null or cir.ID_CIRCUITO = p_id_circuito) 
        and tar.id_target = NVL(p_id_target,tar.id_target)
        and (p_id_prodotto_acquistato IS NULL OR sa.ID_SALA NOT IN
        (
            SELECT ID_SALA FROM CD_SCHERMO_VIRTUALE_PRODOTTO
            WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND ID_SALA = sa.ID_SALA
            AND GIORNO = pro.DATA_PROIEZIONE
        ))
        /*MINUS
         select sa.ID_SALA, pro.DATA_PROIEZIONE
         from cd_sala sa, 
            cd_schermo sch, cd_proiezione pro, cd_proiezione_spett ps, cd_spettacolo spe--,
        --    cd_spett_target spt
        where  sch.ID_SALA = sa.ID_SALA
        and sa.FLG_ANNULLATO = 'N'
        and sa.FLG_VISIBILE = 'S'
        and pro.ID_SCHERMO = sch.ID_SCHERMO
        and pro.DATA_PROIEZIONE between p_data_inizio and p_data_fine
        and TRUNC(pro.DATA_PROIEZIONE) >= TRUNC(sysdate)
        and pro.FLG_ANNULLATO = 'N'
        and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
        and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
        and spe.ID_SPETTACOLO NOT IN
        (
            select id_spettacolo
            from cd_spett_target
            where id_target = NVL(p_id_target,id_target)
        )*/
        ) 
        ) sale 
        where affollamento > p_durata
        )
        where s.id_sala = num_sala
        and c.ID_CINEMA = s.ID_CINEMA
        and c.FLG_ANNULLATO = 'N'
        and c.FLG_VIRTUALE = 'N'
        --and c.FLG_ATTIVO = 'S'
        AND    c.DATA_INIZIO_VALIDITA  <= trunc(DATA_PROIEZIONE)
        AND    nvl(c.DATA_FINE_VALIDITA, trunc(DATA_PROIEZIONE)) >= trunc(DATA_PROIEZIONE) 
        and com.ID_COMUNE = c.ID_COMUNE
GROUP BY num_sala,s.NOME_SALA, c.ID_CINEMA, c.NOME_CINEMA, com.COMUNE
CONNECT BY prev = PRIOR curr AND num_sala = PRIOR num_sala
START WITH curr = 1)
)
--WHERE AFFOLLAMENTO > 0
ORDER BY NOME_SALA;
    RETURN v_sale_associabili;
END FU_GET_SALE_ASSOCIABILI;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ASSOCIA_SALE_VIRTUALI
--
-- DESCRIZIONE:  Associa le sale virtuali alle sale reali delezionate
--
-- INPUT:        p_id_target            Id del target  
--               p_data_inizio          Data di inizio del periodo
--               p_data_fine            Data di fine del periodo
--
-- OUTPUT: 
--
-- OPERAZIONI:
--             1) Creo gli schermi virtuali per mantenere traccia delle settimane associate
--             2) Per ogni settimana 
--
-- REALIZZATORE: michele Borgogno, Altran, luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_SALE_VIRTUALI(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_soglia id_list_type) IS--p_soglia cd_schermo_virtuale_prodotto.SOGLIA%type) IS
--v_sale_associabili C_SALE_ASSOCIABILI;
--v_sala_associabile_rec R_SALE_ASSOCIABILI;
--v_prodotti_target C_PRODOTTI_TARGET;
--v_prodotti_target_rec R_PRODOTTI_TARGET;
v_prodotti_target_rec R_PROD_TEMP;
v_esito NUMBER;
v_continua BOOLEAN := TRUE;
v_esiti v_hash_type;
v_num_sale_rimaste NUMBER;
v_prog number := 109422;
v_num_schermi NUMBER := 0;
--v_soglia cd_schermo_virtuale_prodotto.SOGLIA%type;
v_soglia id_list_type;
i number;
j number;
BEGIN

    v_soglia := p_soglia;

    SAVEPOINT PR_ASSOCIA_TARGET;
    --dbms_output.PUT_LINE('Inizio operazioni preliminari; '||CURRENT_TIMESTAMP);
    --dbms_output.PUT_LINE('>>P_soglia :'||P_soglia);
    FOR PR_TARGET IN(
                     SELECT ID_PRODOTTO_ACQUISTATO, COEF.DURATA
                     FROM CD_COEFF_CINEMA COEF, CD_FORMATO_ACQUISTABILE F, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA, CD_PIANIFICAZIONE PIA
                     WHERE PA.DATA_INIZIO = p_data_inizio
                     AND PA.DATA_FINE = p_data_fine
                     AND PA.FLG_ANNULLATO = 'N'
                     AND PA.FLG_SOSPESO = 'N'
                     AND PA.COD_DISATTIVAZIONE IS NULL
                     AND PA.STATO_DI_VENDITA = 'PRE'
                     AND PIA.ID_PIANO = PA.ID_PIANO
                     AND PIA.ID_VER_PIANO = PIA.ID_VER_PIANO
                     AND PIA.FLG_ANNULLATO = 'N'
                     AND PIA.FLG_SOSPESO = 'N'
                     AND PIA.ID_CLIENTE = NVL(p_id_cliente,PIA.ID_CLIENTE)
                     AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
                     AND PV.ID_TARGET IS NOT NULL
                     AND PV.ID_TARGET = NVL(p_id_target, PV.ID_TARGET)
                     AND F.ID_FORMATO = PA.ID_FORMATO
                     AND COEF.ID_COEFF = F.ID_COEFF
                     ) LOOP
        --pa_cd_utility.scrivi_trace(v_prog,'Id Prodotto: '||PR_TARGET.ID_PRODOTTO_ACQUISTATO);
        PR_CREA_SCHERMI_VIRTUALI(PR_TARGET.ID_PRODOTTO_ACQUISTATO, p_soglia);
        v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_id_prodotto_acquistato := PR_TARGET.ID_PRODOTTO_ACQUISTATO;
        v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_esito := 1;
        v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_num_sale := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(PR_TARGET.ID_PRODOTTO_ACQUISTATO);
        v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_giorni_disponibili := id_list_type();
        i := 1;
        FOR gg IN (select to_char(greatest(p_data_inizio, trunc(sysdate)) -1 + rownum,'D') as giorno
            from all_objects
            where rownum <= (p_data_fine - greatest(p_data_inizio, trunc(sysdate)) +1))
        LOOP
            v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_giorni_disponibili.EXTEND;
            v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_giorni_disponibili(i) := gg.giorno;
            i := i + 1;
        END LOOP;    
        --    
        IF v_soglia IS NULL THEN
            v_soglia := id_list_type();
            j := 1;
            FOR c_soglia IN(select distinct(giorno), soglia 
                            from cd_schermo_virtuale_prodotto 
                            where id_prodotto_acquistato = PR_TARGET.ID_PRODOTTO_ACQUISTATO
                            order by giorno)
            LOOP   
                v_soglia.extend;
                v_soglia(j) := c_soglia.soglia;
                j := j + 1;
            END LOOP;  
        END IF;
        --
        v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_durata := PR_TARGET.DURATA;
        PR_AGGIUNGI_SALE_VIRTUALI_VETT(PR_TARGET.ID_PRODOTTO_ACQUISTATO, v_esiti(PR_TARGET.ID_PRODOTTO_ACQUISTATO).a_prodotti_sala);
    END LOOP;
    --dbms_output.PUT_LINE('Fine operazioni preliminari; '||CURRENT_TIMESTAMP);
    WHILE v_continua = TRUE --AND v_num_schermi <= p_soglia 
    LOOP
        --dbms_output.PUT_LINE('Inizio FU_PRODOTTI_TARGET; '||CURRENT_TIMESTAMP);
        --v_prodotti_target := FU_PRODOTTI_TARGET(NULL, p_id_target, p_data_inizio, p_data_fine, 'PRE');
        --dbms_output.PUT_LINE('Fine FU_PRODOTTI_TARGET; '||CURRENT_TIMESTAMP);
        v_continua := FALSE;
        --
        i := v_esiti.FIRST;
        WHILE i IS NOT NULL
        LOOP
        --
        v_prodotti_target_rec := v_esiti(i);
        --LOOP
        --    FETCH v_prodotti_target INTO v_prodotti_target_rec;
        --    EXIT WHEN v_prodotti_target%NOTFOUND;
           
           --dbms_output.PUT_LINE('v_soglia ='||v_soglia);
          
           /*if p_soglia is null then
            select soglia 
            into v_soglia
            from cd_schermo_virtuale_prodotto
            where id_prodotto_acquistato = v_prodotti_target_rec.a_id_prodotto_acquistato
            and rownum =1;
           end if;*/
           --v_num_schermi := v_esiti(v_prodotti_target_rec.a_id_prodotto_acquistato).a_num_sale;
           --dbms_output.PUT_LINE('v_soglia ='||v_soglia);
           --dbms_output.PUT_LINE('v_num_schermi ='||v_num_schermi); 
           /*if v_num_schermi > v_soglia then   
            exit;
           end if;*/
            --pa_cd_utility.scrivi_trace(v_prog,'Nel loop per '||v_prodotti_target_rec.a_id_prodotto_acquistato);
            v_esito := v_esiti(v_prodotti_target_rec.a_id_prodotto_acquistato).a_esito;
            --pa_cd_utility.scrivi_trace(v_prog,'Esito 1: '||v_esito);
            v_num_sale_rimaste := v_esiti(v_prodotti_target_rec.a_id_prodotto_acquistato).a_prodotti_sala.COUNT;
            --dbms_output.PUT_LINE('v_num_sale_rimaste: '||v_num_sale_rimaste);
            IF v_esito != 2 AND v_num_sale_rimaste > 0 THEN
                --dbms_output.PUT_LINE('Inizio PR_ASSOCIA_SETTIMANA_TARGET; '||CURRENT_TIMESTAMP);
                PR_ASSOCIA_SETTIMANA_TARGET(v_prodotti_target_rec.a_id_prodotto_acquistato, v_prodotti_target_rec.a_durata, v_esiti(v_prodotti_target_rec.a_id_prodotto_acquistato).a_prodotti_sala, v_esiti(v_prodotti_target_rec.a_id_prodotto_acquistato).a_giorni_disponibili, v_soglia, v_esito);
                --dbms_output.PUT_LINE('Fine PR_ASSOCIA_SETTIMANA_TARGET; '||CURRENT_TIMESTAMP);
                --pa_cd_utility.scrivi_trace(v_prog,'Esito 2: '||v_esito);
                v_esiti(v_prodotti_target_rec.a_id_prodotto_acquistato).a_esito := v_esito;
            END IF;
            IF v_esito = 2 THEN
                v_esiti.DELETE(v_prodotti_target_rec.a_id_prodotto_acquistato);
                IF v_esiti.COUNT = 0 THEN
                    EXIT;
                END IF;
            END IF;
            IF v_continua = FALSE AND v_num_sale_rimaste > 0 THEN
                v_continua := TRUE;
            END IF;
            i := v_esiti.NEXT(i);
        END LOOP;
    
    v_num_schermi := v_num_schermi +1;
--    CLOSE v_prodotti_target;
    END LOOP;
    --dbms_output.PUT_LINE('Inizio operazioni conclusive; '||CURRENT_TIMESTAMP);
    --Ciclo prodotti
    FOR PR_TARGET IN(
                     SELECT ID_PRODOTTO_ACQUISTATO, PA.STATO_DI_VENDITA, PV.ID_PRODOTTO_VENDITA, PV.ID_CIRCUITO, PV.ID_TARGET
                     FROM CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA, CD_PIANIFICAZIONE PIA
                     WHERE PA.DATA_INIZIO = p_data_inizio
                     AND PA.DATA_FINE = p_data_fine
                     AND PA.FLG_ANNULLATO = 'N'
                     AND PA.FLG_SOSPESO = 'N'
                     AND PA.COD_DISATTIVAZIONE IS NULL
                     AND PA.STATO_DI_VENDITA = 'PRE'
                     AND PIA.ID_PIANO = PA.ID_PIANO
                     AND PIA.ID_VER_PIANO = PIA.ID_VER_PIANO
                     AND PIA.FLG_ANNULLATO = 'N'
                     AND PIA.FLG_SOSPESO = 'N'
                     AND PIA.ID_CLIENTE = NVL(p_id_cliente,PIA.ID_CLIENTE)
                     AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
                     AND PV.ID_TARGET IS NOT NULL
                     AND PV.ID_TARGET = NVL(p_id_target, PV.ID_TARGET)
                     ) LOOP
        PA_CD_TARGET.PR_ANNULLA_SALE_NON_ASSEGNATE(PR_TARGET.ID_PRODOTTO_ACQUISTATO, PR_TARGET.STATO_DI_VENDITA, PR_TARGET.ID_PRODOTTO_VENDITA, PR_TARGET.ID_CIRCUITO, PR_TARGET.ID_TARGET);
        PA_CD_PRODOTTO_ACQUISTATO.PR_IMPOSTA_POSIZIONE(PR_TARGET.ID_PRODOTTO_ACQUISTATO, null);
    END LOOP;
    --dbms_output.PUT_LINE('Fine operazioni conclusive; '||CURRENT_TIMESTAMP);
/*    EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PROCEDURA PR_ASSOCIA_SALE_VIRTUALI: IMPOSSIBILE EFFETTUARE L''ASSOCIAZIONE: '||SQLERRM);
        ROLLBACK TO PR_ASSOCIA_TARGET;//*/
        
END PR_ASSOCIA_SALE_VIRTUALI;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_PRODOTTI_TARGET
--
-- DESCRIZIONE:  Restituisce tutti i prodotti di tipo target
--
-- INPUT:
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_PRODOTTI_TARGET(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_PRODOTTI_TARGET IS
v_prodotti_target C_PRODOTTI_TARGET;
BEGIN
    OPEN v_prodotti_target
    FOR 
    SELECT ID_PRODOTTO_ACQUISTATO, ID_TARGET, DESCR_TARGET, NOME_CIRCUITO, DESC_TIPO_BREAK, 
    DURATA, ID_PIANO, ID_VER_PIANO, RAG_SOC_COGN, NUM_SALE_ASSOCIATE,NUM_SALE_PRODOTTO, STATO_DI_VENDITA
    FROM
    (
    SELECT PA.ID_PRODOTTO_ACQUISTATO, TARGET.ID_TARGET, TARGET.DESCR_TARGET, CIR.NOME_CIRCUITO, TB.DESC_TIPO_BREAK, 
    COEF.DURATA, PIA.ID_PIANO, PIA.ID_VER_PIANO, CLIENTE.RAG_SOC_COGN, PA.STATO_DI_VENDITA,
    PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_SCHERMI_TARGET(PA.ID_PRODOTTO_ACQUISTATO, TARGET.ID_TARGET, 'S') AS NUM_SALE_ASSOCIATE,
    FU_GET_SALE_VIRTUALI_CIRCUITO(cir.id_circuito) AS NUM_SALE_PRODOTTO
    --FU_NUM_SCHERMI_REALI(PA.ID_PRODOTTO_ACQUISTATO) AS NUM_SALE_ASSOCIATE
    FROM CD_COEFF_CINEMA COEF, CD_FORMATO_ACQUISTABILE F, CD_TIPO_BREAK TB, CD_CIRCUITO CIR, CD_TARGET TARGET, CD_PRODOTTO_VENDITA PV, INTERL_U CLIENTE, CD_PIANIFICAZIONE PIA, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.DATA_INIZIO = p_data_inizio
    AND PA.DATA_FINE = p_data_fine
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.COD_DISATTIVAZIONE IS NULL
    AND PA.STATO_DI_VENDITA = NVL(p_stato_vendita, PA.STATO_DI_VENDITA)
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
    AND TARGET.ID_TARGET = PV.ID_TARGET
    AND TARGET.ID_TARGET = NVL(p_id_target,TARGET.ID_TARGET)
    AND PIA.ID_PIANO = PA.ID_PIANO
    AND PIA.ID_VER_PIANO = PIA.ID_VER_PIANO
    AND PIA.FLG_ANNULLATO = 'N'
    AND PIA.FLG_SOSPESO = 'N'
    AND PIA.ID_CLIENTE = NVL(p_id_cliente,PIA.ID_CLIENTE)
    AND CLIENTE.COD_INTERL = PIA.ID_CLIENTE
    AND CIR.ID_CIRCUITO = PV.ID_CIRCUITO
    AND TB.ID_TIPO_BREAK = PV.ID_TIPO_BREAK
    AND F.ID_FORMATO = PA.ID_FORMATO
    AND COEF.ID_COEFF = F.ID_COEFF)
    ORDER BY NUM_SALE_ASSOCIATE, ID_PRODOTTO_ACQUISTATO;
    RETURN v_prodotti_target;
END FU_PRODOTTI_TARGET;

FUNCTION FU_NUM_SCHERMI_REALI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER IS
v_num_schermi NUMBER;
v_num_giorni_prodotto NUMBER;
v_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE;
BEGIN
    SELECT PA.DATA_FINE - PA.DATA_INIZIO +1, PV.ID_TARGET
    INTO v_num_giorni_prodotto, v_id_target
    FROM CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA;
    --
    SELECT COUNT(DISTINCT ID_SCHERMO_VIRTUALE)
    INTO v_num_schermi
    FROM
    (
    SELECT SV.ID_SCHERMO_VIRTUALE
    FROM CD_SPETT_TARGET ST, CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,CD_PROIEZIONE PRO, 
    CD_CINEMA CIN, CD_SCHERMO SC, CD_SALA SA, CD_SCHERMO_VIRTUALE_PRODOTTO SV
    WHERE SV.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND SA.ID_SALA = SV.ID_SALA
    AND CIN.ID_CINEMA = SA.ID_CINEMA
    AND CIN.FLG_VIRTUALE = 'N'
    AND SC.ID_SALA = SA.ID_SALA
    AND PRO.ID_SCHERMO = SC.ID_SCHERMO
    AND PRO.DATA_PROIEZIONE = SV.GIORNO
    AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
    AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
    AND ST.ID_SPETTACOLO = SPE.ID_SPETTACOLO
    AND ST.ID_TARGET = v_id_target
    /*MINUS
    SELECT SV.ID_SCHERMO_VIRTUALE
    FROM CD_CINEMA CIN, CD_SALA SA, CD_SCHERMO_VIRTUALE_PRODOTTO SV
    WHERE SV.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND SA.ID_SALA = SV.ID_SALA
    AND CIN.ID_CINEMA = SA.ID_CINEMA
    AND (CIN.FLG_VIRTUALE = 'S'
        OR SA.ID_SALA IN
        (
            SELECT SC.ID_SALA
            FROM CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
            CD_PROIEZIONE PRO, CD_SCHERMO SC
            WHERE SC.ID_SALA = SA.ID_SALA
            AND PRO.ID_SCHERMO = SC.ID_SCHERMO
            AND PRO.DATA_PROIEZIONE = SV.GIORNO
            AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
            AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
            AND SPE.ID_SPETTACOLO NOT IN
            (
                SELECT ID_SPETTACOLO
                FROM CD_SPETT_TARGET
            )
            AND SPE.ID_SPETTACOLO NOT IN
            (
                SELECT ID_SPETTACOLO
                FROM CD_SPETT_TARGET
                WHERE ID_TARGET = v_id_target
            )
        )
    )*/
    --GROUP BY SV.ID_SCHERMO_VIRTUALE
    )
    --WHERE GIORNI_TARGET = v_num_giorni_prodotto
    ;
    RETURN v_num_schermi;
END FU_NUM_SCHERMI_REALI;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ASSOCIA_SETTIMANA_TARGET
--
-- DESCRIZIONE: Associa una settimana di un prodotto a schermi su cui sono trasmessi
--              spettacoli compatibili con il target richiesto
--
-- INPUT:  p_id_prodotto_acquistato: Id del prodotto acquistato
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_SETTIMANA_TARGET(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_durata CD_COEFF_CINEMA.DURATA%TYPE, p_prodotti_sala IN OUT id_list_type, p_giorni_disponibili IN OUT id_list_type, p_soglia id_list_type, p_esito OUT NUMBER) IS
v_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE;
--v_id_sala CD_SCHERMO_VIRTUALE_PRODOTTO.ID_SALA%TYPE;
v_id_circuito CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE;
v_giorni_da_associare VARCHAR2(100);
v_id_schermo_virtuale CD_SCHERMO_VIRTUALE_PRODOTTO.ID_SCHERMO_VIRTUALE%TYPE;
--v_sale_associabili C_SALE_ASSOCIABILI;
--v_sala_associabile_rec R_SALE_ASSOCIABILI;
v_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE;
v_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE;
v_list_giorni_da_associare id_list_type;
--v_giorni_rimanenti NUMBER;
--v_ind_sale NUMBER := 1;
v_id_vecchia_sala CD_SCHERMO_VIRTUALE_PRODOTTO.ID_SALA%TYPE;
v_id_schermo_virtuale_prodotto CD_SCHERMO_VIRTUALE_PRODOTTO.ID_SCHERMO_VIRTUALE_PRODOTTO%TYPE;
v_giorno DATE;
--v_disponibilita NUMBER;
--v_num_sale_trovate NUMBER :=0;
--v_num_sale_associabili NUMBER := 0;
--v_giorno_da_associare NUMBER;
v_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE;
v_id_comunicato CD_COMUNICATO.ID_COMUNICATO%TYPE;
v_sala_virtuale CD_CINEMA.FLG_VIRTUALE%TYPE;
v_id_break_vendita CD_COMUNICATO.ID_BREAK_VENDITA%TYPE;
v_id_prodotto_vendita CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA%TYPE;
v_num_comunicati NUMBER := 0;
v_id_nuova_sala CD_COMUNICATO.ID_SALA%TYPE;
v_trovato BOOLEAN;
v_id_break CD_BREAK.ID_BREAK%TYPE;
v_num_giorno INTEGER;
v_sale_giorno C_SALE_SETTIMANA;
v_sale_giorno_rec R_SALE_SETTIMANA;
BEGIN
    p_esito := 0;
    --dbms_output.put_line('Id prodotto: '||p_id_prodotto_acquistato);
    SELECT PA.DATA_INIZIO, PA.DATA_FINE, PA.STATO_DI_VENDITA,  PV.ID_TARGET, PV.ID_CIRCUITO, PV.ID_PRODOTTO_VENDITA
    INTO v_data_inizio, v_data_fine, v_stato_vendita, v_id_target, v_id_circuito, v_id_prodotto_vendita
    FROM CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA;
    --
    BEGIN
    --
    --dbms_output.PUT_LINE('Inizio query per schermo virtuale da associare; '||CURRENT_TIMESTAMP);
    SELECT ID_SCHERMO_VIRTUALE,GIORNI
    INTO v_id_schermo_virtuale, v_giorni_da_associare
    FROM
    (
        SELECT ID_SCHERMO_VIRTUALE,GIORNI
        FROM
        (
            SELECT ID_SCHERMO_VIRTUALE,
            LTRIM(MAX(SYS_CONNECT_BY_PATH(to_char(GIORNO,'D'),','))
            KEEP (DENSE_RANK LAST ORDER BY curr),',') AS GIORNI
            FROM
            (
                SELECT ID_SCHERMO_VIRTUALE, GIORNO,
                ROW_NUMBER() OVER (PARTITION BY ID_SCHERMO_VIRTUALE ORDER BY GIORNO) AS curr,
                ROW_NUMBER() OVER (PARTITION BY ID_SCHERMO_VIRTUALE ORDER BY GIORNO) -1 AS prev
                FROM CD_CINEMA CIN, CD_SALA SA, CD_SCHERMO_VIRTUALE_PRODOTTO SV
                WHERE SV.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND SV.ID_SCHERMO_VIRTUALE IN
                (
                   SELECT * FROM TABLE(p_prodotti_sala)
                   -- SELECT * FROM TABLE(cast (p_prodotti_sala as num_array))
                   --(SELECT * FROM TABLE (p_prodotti_sala))
                )
                AND SA.ID_SALA = SV.ID_SALA
                AND CIN.ID_CINEMA = SA.ID_CINEMA
                AND CIN.FLG_VIRTUALE = 'S'
                AND SA.ID_SALA NOT IN
                (
                    SELECT SC.ID_SALA
                    FROM CD_SPETT_TARGET ST, CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                    CD_PROIEZIONE PRO, CD_SCHERMO SC
                    WHERE SC.ID_SALA = SA.ID_SALA
                    AND SC.FLG_ANNULLATO = 'N'
                    AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                    AND PRO.DATA_PROIEZIONE = SV.GIORNO
                    AND PRO.FLG_ANNULLATO = 'N'
                    AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                    AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
                    AND ST.ID_SPETTACOLO = SPE.ID_SPETTACOLO
                    AND ST.ID_TARGET = v_id_target
                )
                /*OR SA.ID_SALA IN
                    (
                        SELECT SC.ID_SALA
                        FROM CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                        CD_PROIEZIONE PRO, CD_SCHERMO SC
                        WHERE SC.ID_SALA = SA.ID_SALA
                        AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                        AND PRO.DATA_PROIEZIONE = SV.GIORNO
                        AND TRUNC(PRO.DATA_PROIEZIONE) >= TRUNC(SYSDATE)
                        AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                        AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
                        AND SPE.ID_SPETTACOLO NOT IN
                        (
                            SELECT ID_SPETTACOLO
                            FROM CD_SPETT_TARGET
                        )
                        AND SPE.ID_SPETTACOLO NOT IN
                        (
                            SELECT ID_SPETTACOLO
                            FROM CD_SPETT_TARGET
                            WHERE ID_TARGET = v_id_target
                        )
                    )*/
                --)
            )
            GROUP BY ID_SCHERMO_VIRTUALE
            CONNECT BY prev = PRIOR curr AND ID_SCHERMO_VIRTUALE = PRIOR ID_SCHERMO_VIRTUALE
            START WITH curr = 1
        )
        ORDER BY LENGTH(GIORNI), ID_SCHERMO_VIRTUALE
    )
    WHERE ROWNUM <= 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_esito := 2;
    END;
    --dbms_output.PUT_LINE('Fine query per schermo virtuale da associare; '||CURRENT_TIMESTAMP);
    --
    --dbms_output.put_line('v_id_schermo_virtuale_prodotto: '||v_id_schermo_virtuale);
    --dbms_output.put_line('giorni da associare: '||v_giorni_da_associare);
    --pa_cd_utility.scrivi_trace(109422,'v_id_schermo_virtuale_prodotto: '||v_id_schermo_virtuale);
    --pa_cd_utility.scrivi_trace(109422,'giorni da associare: '||v_giorni_da_associare);
    IF p_esito = 0 THEN
        v_list_giorni_da_associare := PA_CD_UTILITY.SPLIT(v_giorni_da_associare,',');
        v_trovato := FALSE;
        --dbms_output.PUT_LINE('Inizio associazione settimana; '||CURRENT_TIMESTAMP);
        FOR i IN v_list_giorni_da_associare.FIRST..v_list_giorni_da_associare.LAST LOOP
            BEGIN
            select giorno
            into v_giorno
            from
            (
            select v_data_inizio -1 + rownum as giorno
            from all_objects
            where rownum <=7
            )
            where to_char(giorno,'D') = v_list_giorni_da_associare(i) 
            AND to_char(giorno,'D') IN
            (
                SELECT * FROM TABLE(p_giorni_disponibili)
            );
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_giorno := null;
            END;    
            --
            IF v_giorno IS NOT NULL THEN
            v_sale_giorno := FU_SALE_GIORNO(p_id_prodotto_acquistato, v_giorno);
                LOOP
                    FETCH v_sale_giorno INTO v_sale_giorno_rec;
                    EXIT WHEN v_sale_giorno%NOTFOUND;
                    /*dbms_output.PUT_LINE('v_giorno = '||v_giorno);
                    dbms_output.PUT_LINE('p_id_prodotto_acquistato = '||p_id_prodotto_acquistato);
                    dbms_output.PUT_LINE('indice = '||i);
                    dbms_output.PUT_LINE('v_sale_giorno = '||v_sale_giorno_rec.a_num_schermi);
                    dbms_output.PUT_LINE('v_list_giorni_da_associare = '||v_list_giorni_da_associare(i));
                    dbms_output.PUT_LINE('p_soglia = '||p_soglia(v_list_giorni_da_associare(i)));
                    dbms_output.PUT_LINE('v_sale_giorno_rec.a_num_schermi = '||v_sale_giorno_rec.a_num_schermi);
                    */
                    IF v_sale_giorno_rec.a_num_schermi < p_soglia(v_list_giorni_da_associare(i)) THEN     
                    --
                        --dbms_output.PUT_LINE('Inizio FU_GET_SALA_TARGET_GIORNO; '||CURRENT_TIMESTAMP);
                        v_id_nuova_sala := FU_GET_SALA_TARGET_GIORNO(v_id_target, v_giorno, p_id_prodotto_acquistato, p_durata);
                        --dbms_output.PUT_LINE('Fine FU_GET_SALA_TARGET_GIORNO; '||CURRENT_TIMESTAMP);
                        --
                        --dbms_output.PUT_LINE('v_id_nuova_sala; '||v_id_nuova_sala);
                        IF v_id_nuova_sala != -1 THEN
                            --dbms_output.PUT_LINE('Inizio associazione comunicati; '||CURRENT_TIMESTAMP);
                            v_trovato := TRUE;
                            SELECT ID_SCHERMO_VIRTUALE_PRODOTTO, S.ID_SALA, CIN.FLG_VIRTUALE
                            INTO v_id_schermo_virtuale_prodotto, v_id_vecchia_sala, v_sala_virtuale
                            FROM CD_CINEMA CIN, CD_SALA S, CD_SCHERMO_VIRTUALE_PRODOTTO SV
                            WHERE SV.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                            AND SV.ID_SCHERMO_VIRTUALE = v_id_schermo_virtuale
                            AND SV.GIORNO = v_giorno
                            AND S.ID_SALA = SV.ID_SALA
                            AND CIN.ID_CINEMA = S.ID_CINEMA;
                            --
                            UPDATE CD_SCHERMO_VIRTUALE_PRODOTTO
                            SET ID_SALA = v_id_nuova_sala
                            WHERE ID_SCHERMO_VIRTUALE_PRODOTTO = v_id_schermo_virtuale_prodotto;
                        --
                            --dbms_output.PUT_LINE('v_id_vecchia_sala: '||v_id_schermo_virtuale);
                            --dbms_output.PUT_LINE('v_id_schermo_virtuale: '||v_id_schermo_virtuale);
                            --dbms_output.PUT_LINE('v_giorno: '||v_giorno);
                            FOR COM IN
                            (
                                SELECT ID_COMUNICATO, ID_FASCIA
                               -- INTO v_id_comunicato
                                FROM CD_PROIEZIONE PR, CD_BREAK BR, CD_COMUNICATO COM
                                WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                                AND COM.DATA_EROGAZIONE_PREV = v_giorno
                                AND COM.ID_SALA = v_id_vecchia_sala
                                AND COM.FLG_ANNULLATO = 'N'
                                AND COM.FLG_SOSPESO = 'N'
                                AND COM.COD_DISATTIVAZIONE IS NULL
                                AND BR.ID_BREAK = COM.ID_BREAK
                                AND BR.FLG_ANNULLATO = 'N'
                                AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
                                AND PR.FLG_ANNULLATO = 'N'
                            ) LOOP
                               --dbms_output.PUT_LINE('COM.ID_COMUNICATO: '||COM.ID_COMUNICATO);
                               --dbms_output.PUT_LINE('v_id_vecchia_sala: '||v_id_vecchia_sala);
                               --dbms_output.PUT_LINE('v_id_nuova_sala: '||v_id_nuova_sala);
                               --dbms_output.PUT_LINE('v_id_circuito: '||v_id_circuito);
                               --dbms_output.PUT_LINE('v_id_prodotto_vendita: '||v_id_prodotto_vendita);
                               --dbms_output.PUT_LINE('v_giorno: '||v_giorno);
                               --dbms_output.PUT_LINE('COM.ID_FASCIA: '||COM.ID_FASCIA);
                    
                                v_num_comunicati := v_num_comunicati +1;
                                SELECT DISTINCT BV.ID_BREAK_VENDITA , BR.ID_BREAK
                                INTO v_id_break_vendita, v_id_break
                                FROM CD_BREAK_VENDITA BV, CD_CIRCUITO_BREAK CB, CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SC
                                WHERE SC.ID_SALA = v_id_nuova_sala
                                AND PR.ID_SCHERMO = SC.ID_SCHERMO
                                AND PR.FLG_ANNULLATO = 'N'
                                AND PR.DATA_PROIEZIONE = v_giorno
                                AND BR.ID_PROIEZIONE = PR.ID_PROIEZIONE
                                AND BR.FLG_ANNULLATO = 'N'
                                AND CB.ID_BREAK = BR.ID_BREAK
                                AND CB.ID_CIRCUITO = v_id_circuito
                                AND BV.ID_CIRCUITO_BREAK = CB.ID_CIRCUITO_BREAK
                                AND BV.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
                                AND PR.ID_FASCIA = COM.ID_FASCIA;
                                --dbms_output.PUT_LINE('v_id_break_vendita: '||v_id_break_vendita);
                                IF v_sala_virtuale = 'N' THEN
                                    PA_CD_PRODOTTO_ACQUISTATO.PR_ELIMINA_BUCO_POSIZIONE_COM(COM.ID_COMUNICATO);
                                END IF;
                                --
                                UPDATE CD_COMUNICATO
                                SET ID_SALA = v_id_nuova_sala,
                                ID_BREAK_VENDITA = v_id_break_vendita,
                                ID_BREAK = v_id_break
                                WHERE ID_COMUNICATO = COM.ID_COMUNICATO;
                            END LOOP;
                            --dbms_output.PUT_LINE('Fine associazione comunicati; '||CURRENT_TIMESTAMP);
                        ELSE
                            PA_CD_UTILITY.PR_ELIMINA_VALORE_VETT(p_giorni_disponibili, v_list_giorni_da_associare(i));
                        END IF;
                    ELSE
                        PA_CD_UTILITY.PR_ELIMINA_VALORE_VETT(p_giorni_disponibili, v_list_giorni_da_associare(i));
                    END IF;  
                END LOOP;
                CLOSE v_sale_giorno;
            END IF;
        END LOOP;
        PA_CD_UTILITY.PR_ELIMINA_VALORE_VETT(p_prodotti_sala, v_id_schermo_virtuale);
        IF v_trovato = FALSE THEN
            --ottimizzare la condizione di uscita quando non ci sono piu sale disponibili
            
            IF p_giorni_disponibili.COUNT = 0 THEN
                p_esito := 2;
            END IF;
        END IF;
        --dbms_output.PUT_LINE('Fine associazione settimana; '||CURRENT_TIMESTAMP);
    END IF;
END PR_ASSOCIA_SETTIMANA_TARGET;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_CREA_SCHERMI_VIRTUALI
--
-- DESCRIZIONE:  Crea gli schermi virtuali associati ad un prodotto di tipo target
--
-- INPUT:  p_id_prodotto_acquistato: Id del prodotto acquistato
--
-- OUTPUT: 
--
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_CREA_SCHERMI_VIRTUALI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_soglia id_list_type) IS -- CD_SCHERMO_VIRTUALE_PRODOTTO.SOGLIA%TYPE) IS
v_prodotto_presente NUMBER;
v_id_schermo_virtuale NUMBER := 1;
v_giorno DATE;
v_giorno_settimana NUMBER := 0;
v_data_inizio DATE;
v_data_fine DATE;
BEGIN   
    SELECT COUNT(1) 
    INTO v_prodotto_presente
    FROM CD_SCHERMO_VIRTUALE_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND ROWNUM <= 1;
    --
    IF v_prodotto_presente = 0 THEN
        --
        SELECT DATA_INIZIO, DATA_FINE 
        INTO v_data_inizio, v_data_fine
        FROM CD_PRODOTTO_ACQUISTATO
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
        v_giorno := v_data_inizio;
        v_giorno_settimana := 1;
        WHILE v_giorno <= v_data_fine LOOP
            INSERT INTO CD_SCHERMO_VIRTUALE_PRODOTTO(ID_PRODOTTO_ACQUISTATO, ID_SCHERMO_VIRTUALE, ID_SALA, GIORNO, SOGLIA)
            (SELECT p_id_prodotto_acquistato, ID_SCHERMO_VIRTUALE, ID_SALA, v_giorno, p_soglia(v_giorno_settimana)
             FROM
             (
                SELECT ID_SALA, ROWNUM AS ID_SCHERMO_VIRTUALE
                 FROM
                 (
                 SELECT DISTINCT ID_SALA AS ID_SALA
                 FROM CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO PA
                 WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                 AND   COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
                 AND COM.FLG_ANNULLATO = 'N'
                 AND COM.FLG_SOSPESO = 'N'
                 AND COM.COD_DISATTIVAZIONE IS NULL
                 AND COM.DATA_EROGAZIONE_PREV = v_giorno
                 )
                 ORDER BY ROWNUM
             ), DUAL);
            v_giorno_settimana := v_giorno_settimana +1;
            v_giorno := v_giorno + 1;
        END LOOP;
        
        /*
        FOR SALE_VIRTUALI IN (SELECT DISTINCT ID_SALA, MIN(COM.DATA_EROGAZIONE_PREV) AS MIN_DATA, MAX(DATA_EROGAZIONE_PREV) AS MAX_DATA 
             FROM CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO PA
             WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
             AND   COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
             AND COM.FLG_ANNULLATO = 'N'
             AND COM.FLG_SOSPESO = 'N'
             AND COM.COD_DISATTIVAZIONE IS NULL
             GROUP BY ID_SALA) LOOP
                v_giorno := SALE_VIRTUALI.MIN_DATA;
                v_giorno_settimana := 1;
                --dbms_output.PUT_LINE('min: '||SALE_VIRTUALI.MIN_DATA);
                --dbms_output.PUT_LINE('max: '||SALE_VIRTUALI.MAX_DATA);
                WHILE v_giorno <= SALE_VIRTUALI.MAX_DATA LOOP
                    INSERT INTO CD_SCHERMO_VIRTUALE_PRODOTTO(ID_PRODOTTO_ACQUISTATO, ID_SCHERMO_VIRTUALE, ID_SALA, GIORNO, SOGLIA)
                    (SELECT p_id_prodotto_acquistato, v_id_schermo_virtuale, SALE_VIRTUALI.ID_SALA, v_giorno, p_soglia(v_giorno_settimana) FROM DUAL);
                    --dbms_output.PUT_LINE('v_giorno: '||v_giorno);
                    --dbms_output.PUT_LINE('p_soglia(v_giorno_settimana): '||p_soglia(v_giorno_settimana));
                    v_giorno := v_giorno +1;
                    v_giorno_settimana := v_giorno_settimana +1;
                END LOOP;
            v_id_schermo_virtuale := v_id_schermo_virtuale +1;
        END LOOP;*/
    ELSE
        IF p_soglia IS NOT NULL THEN
            FOR i IN p_soglia.FIRST..p_soglia.LAST LOOP
                UPDATE CD_SCHERMO_VIRTUALE_PRODOTTO SVP
                SET SOGLIA = p_soglia(i)
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND GIORNO >= TRUNC(SYSDATE)
                AND i = to_char(GIORNO,'D');
             END LOOP;
        END IF;
    END IF;
    --
END PR_CREA_SCHERMI_VIRTUALI;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_AGGIUNGI_SALE_VIRTUALI_VETT
--
-- DESCRIZIONE:  Aggiunge gli schermi virtuali di un prodotto ad una struttura temporanea
--
-- INPUT:  p_id_prodotto_acquistato: Id del prodotto acquistato
--
-- OUTPUT: 
--        p_prodotti_sala          : Vettore che contiene le informazioni sugli schermi virtuali del prodotto
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_AGGIUNGI_SALE_VIRTUALI_VETT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,p_prodotti_sala OUT id_list_type) IS

v_ind NUMBER := 1;    
    BEGIN
    p_prodotti_sala := id_list_type();
    FOR SV IN (
                SELECT DISTINCT ID_SCHERMO_VIRTUALE
                FROM CD_CINEMA CIN, CD_SALA SA, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA, CD_SCHERMO_VIRTUALE_PRODOTTO SV
                WHERE SV.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND PA.ID_PRODOTTO_ACQUISTATO = SV.ID_PRODOTTO_ACQUISTATO
                AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
                AND SA.ID_SALA = SV.ID_SALA
                AND CIN.ID_CINEMA = SA.ID_CINEMA
                AND (CIN.FLG_VIRTUALE = 'S'
                    OR SA.ID_SALA NOT IN
                    (
                        SELECT SC.ID_SALA
                        FROM CD_SPETT_TARGET ST, CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                        CD_PROIEZIONE PRO, CD_SCHERMO SC
                        WHERE SC.ID_SALA = SA.ID_SALA
                        AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                        AND PRO.DATA_PROIEZIONE = SV.GIORNO
                        AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                        AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
                        AND ST.ID_SPETTACOLO = SPE.ID_SPETTACOLO
                        AND ST.ID_TARGET = PV.ID_TARGET
                    )
                )
               ) LOOP
       --p_prodotti_sala(SV.ID_SCHERMO_VIRTUALE).a_id_prodotto_acquistato := p_id_prodotto_acquistato;
       --p_prodotti_sala(SV.ID_SCHERMO_VIRTUALE).a_id_sala := SV.ID_SCHERMO_VIRTUALE;
       p_prodotti_sala.EXTEND;
       p_prodotti_sala(v_ind) := SV.ID_SCHERMO_VIRTUALE;
       v_ind := v_ind +1;
    END LOOP;
END PR_AGGIUNGI_SALE_VIRTUALI_VETT;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_SALE_IDONEE
--
-- DESCRIZIONE:  Restituisce il numero di sale, divise per giorno, in cui e presente
--               una programmazione esclusivamente con spettacoli del target richeisto
--
-- INPUT:  p_id_cliente:  codice del cliente; parametro opzionale
--         p_id_target:   id del target cercato
--         p_data_inizio: data di inizio del periodo cercato
--         p_data_fine:   data di fine del periodo cercato
--
-- OUTPUT: 
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_SALE_IDONEE(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) RETURN C_SALE_SETTIMANA IS
v_sale_idonee C_SALE_SETTIMANA;
BEGIN
    
    OPEN v_sale_idonee FOR
       select distinct (data_proiezione) as data_proiezione, max(NUM_SALE) AS NUM_SALE
       from
       (
       select data_proiezione, count(1) AS NUM_SALE
       from
       (
       select 
         sa.ID_SALA, 
         pro.DATA_PROIEZIONE
         from 
         cd_condizione_contratto cond, cd_contratto con, 
         cd_cinema_contratto cc, cd_cinema cin,
         cd_sala sa,cd_schermo sch, cd_proiezione pro, 
         cd_proiezione_spett ps, cd_spettacolo spe,
         cd_spett_target spt, cd_target tar
        where sch.ID_SALA = sa.ID_SALA
        and sa.FLG_ANNULLATO = 'N'
        and sa.FLG_VISIBILE = 'S'
        and pro.ID_SCHERMO = sch.ID_SCHERMO
        and pro.FLG_ANNULLATO = 'N'
        and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
        and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
        and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
        and tar.ID_TARGET = spt.id_target
        and pro.DATA_PROIEZIONE between TRUNC(p_data_inizio) and TRUNC(p_data_fine)
     --   and TRUNC(pro.DATA_PROIEZIONE) >= TRUNC(sysdate)
     --   and (p_id_circuito is null or cir.ID_CIRCUITO = p_id_circuito) 
        and tar.id_target = NVL(p_id_target,tar.id_target)
        and cin.ID_CINEMA = sa.ID_CINEMA
        and cc.ID_CINEMA = cin.ID_CINEMA
        and con.ID_CONTRATTO = cc.ID_CONTRATTO
        and pro.DATA_PROIEZIONE BETWEEN con.DATA_INIZIO AND con.DATA_FINE
        and cond.ID_CINEMA_CONTRATTO = cc.ID_CINEMA_CONTRATTO
        and (cond.GIORNO_CHIUSURA IS NULL OR cond.GIORNO_CHIUSURA != to_char(pro.DATA_PROIEZIONE, 'D'))
        /*MINUS
         select sa.ID_SALA, pro.DATA_PROIEZIONE
         from cd_sala sa, 
            cd_schermo sch, cd_proiezione pro, cd_proiezione_spett ps, cd_spettacolo spe--,
        --    cd_spett_target spt
        where  sch.ID_SALA = sa.ID_SALA
        and sa.FLG_ANNULLATO = 'N'
        and sa.FLG_VISIBILE = 'S'
        and pro.ID_SCHERMO = sch.ID_SCHERMO
        and pro.DATA_PROIEZIONE between TRUNC(p_data_inizio) and TRUNC(p_data_fine)
      --  and TRUNC(pro.DATA_PROIEZIONE) >= TRUNC(sysdate)
        and pro.FLG_ANNULLATO = 'N'
        and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
        and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
        and spe.ID_SPETTACOLO NOT IN
        (
            select id_spettacolo
            from cd_spett_target
            where id_target = NVL(p_id_target,id_target)
        )*/
        )
        group by DATA_PROIEZIONE
        UNION
        SELECT DISTINCT pro.DATA_PROIEZIONE, 0
        from cd_sala sa, 
            cd_schermo sch, cd_proiezione pro
        where  sch.ID_SALA = sa.ID_SALA
        and sa.FLG_ANNULLATO = 'N'
        and sa.FLG_VISIBILE = 'S'
        and pro.ID_SCHERMO = sch.ID_SCHERMO
        and pro.DATA_PROIEZIONE between TRUNC(p_data_inizio) and TRUNC(p_data_fine)
        )
        group by DATA_PROIEZIONE
        order by DATA_PROIEZIONE;
    RETURN v_sale_idonee;
END FU_SALE_IDONEE;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_SALE_IDONEE_DISPONIBILI
--
-- DESCRIZIONE:  Restituisce il numero di sale, divise per giorno, in cui e presente
--               una programmazione esclusivamente con spettacoli del target richeisto
--               e che hanno ancora della disponibilita residua
--
-- INPUT:  p_id_cliente:  codice del cliente; parametro opzionale
--         p_id_target:   id del target cercato
--         p_data_inizio: data di inizio del periodo cercato
--         p_data_fine:   data di fine del periodo cercato
--
-- OUTPUT: 
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
FUNCTION FU_SALE_IDONEE_DISPONIBILI(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) RETURN C_SALE_SETTIMANA IS
v_sale_idonee C_SALE_SETTIMANA;
BEGIN
    OPEN v_sale_idonee FOR
       select distinct (data_proiezione), max(NUM_SALE) AS NUM_SALE
       from
       (
       select data_proiezione, count(1) as NUM_SALE
       from
       (
       select data_proiezione, disponibilita
       from
       (
       select id_sala, data_proiezione, disponibilita
       from
       (
           select id_sala, data_proiezione,
           PA_CD_ESTRAZIONE_PROD_VENDITA.FU_AFFOLLAMENTO_SALA_STATO(DATA_PROIEZIONE, DATA_PROIEZIONE, ID_SALA, NULL, 'PRE') AS DISPONIBILITA
           from
           (
               select 
                 sa.ID_SALA, 
                 pro.DATA_PROIEZIONE
                 from 
                cd_condizione_contratto cond, cd_contratto con, 
                cd_cinema_contratto cc, cd_cinema cin,
                cd_sala sa,cd_schermo sch, cd_proiezione pro, 
                cd_proiezione_spett ps, cd_spettacolo spe,
                cd_spett_target spt, cd_target tar
                where sch.ID_SALA = sa.ID_SALA
                and sa.FLG_ANNULLATO = 'N'
                and sa.FLG_VISIBILE = 'S'
                and pro.ID_SCHERMO = sch.ID_SCHERMO
                and pro.FLG_ANNULLATO = 'N'
                and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
                and tar.ID_TARGET = spt.id_target
                and pro.DATA_PROIEZIONE between p_data_inizio and p_data_fine
              --  and TRUNC(pro.DATA_PROIEZIONE) >= TRUNC(sysdate)
             --   and (p_id_circuito is null or cir.ID_CIRCUITO = p_id_circuito) 
                and tar.id_target = NVL(p_id_target,tar.id_target)
                and cin.ID_CINEMA = sa.ID_CINEMA
                and cc.ID_CINEMA = cin.ID_CINEMA
                and con.ID_CONTRATTO = cc.ID_CONTRATTO
                and pro.DATA_PROIEZIONE BETWEEN con.DATA_INIZIO AND con.DATA_FINE
                and cond.ID_CINEMA_CONTRATTO = cc.ID_CINEMA_CONTRATTO
                and (cond.GIORNO_CHIUSURA IS NULL OR cond.GIORNO_CHIUSURA != to_char(pro.DATA_PROIEZIONE, 'D'))
                /*MINUS
                 select sa.ID_SALA, pro.DATA_PROIEZIONE
                 from cd_sala sa, 
                    cd_schermo sch, cd_proiezione pro, cd_proiezione_spett ps, cd_spettacolo spe--,
                --    cd_spett_target spt
                where  sch.ID_SALA = sa.ID_SALA
                and sa.FLG_ANNULLATO = 'N'
                and sa.FLG_VISIBILE = 'S'
                and pro.ID_SCHERMO = sch.ID_SCHERMO
                and pro.DATA_PROIEZIONE between p_data_inizio and p_data_fine
               -- and TRUNC(pro.DATA_PROIEZIONE) >= TRUNC(sysdate)
                and pro.FLG_ANNULLATO = 'N'
                and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                and spe.ID_SPETTACOLO NOT IN
                (
                    select id_spettacolo
                    from cd_spett_target
                    where id_target = NVL(p_id_target,id_target)
                )*/
            )
        )
        )
   --     WHERE DISPONIBILITA > 0
        group by DATA_PROIEZIONE, id_sala
        having disponibilita > 0
        order by DATA_PROIEZIONE
        )
        group by DATA_PROIEZIONE
        UNION
        SELECT DISTINCT pro.DATA_PROIEZIONE, 0
        from cd_sala sa, 
            cd_schermo sch, cd_proiezione pro
        where  sch.ID_SALA = sa.ID_SALA
        and sa.FLG_ANNULLATO = 'N'
        and sa.FLG_VISIBILE = 'S'
        and pro.ID_SCHERMO = sch.ID_SCHERMO
        and pro.DATA_PROIEZIONE between p_data_inizio and p_data_fine
        )
        group by DATA_PROIEZIONE
        order by DATA_PROIEZIONE;
    RETURN v_sale_idonee;
END FU_SALE_IDONEE_DISPONIBILI;

-----------------------------------------------------------------------------------------------------
-- Funzione FU_SALE_GIORNO
--
-- DESCRIZIONE:  Dato un prodotto acquistato restituisce il numero di sale, divise per giorno, in cui e presente
--               una programmazione esclusivamente con spettacoli del target richiesto
--
-- INPUT:  p_id_cliente:  codice del cliente; parametro opzionale
--         p_id_target:   id del target cercato
--         p_data_inizio: data di inizio del periodo cercato
--         p_data_fine:   data di fine del periodo cercato
--
-- OUTPUT: 
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--  Aggiunto giorno come parametro di input (Michele Borgogno, Altran, settembre 2010)
-------------------------------------------------------------------------------------------------
FUNCTION FU_SALE_GIORNO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_giorno CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE) RETURN C_SALE_SETTIMANA IS
v_sale_giorno C_SALE_SETTIMANA;
v_id_target CD_TARGET.ID_TARGET%TYPE;
BEGIN    
    SELECT PV.ID_TARGET
    INTO v_id_target
    FROM CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
    WHERE PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA;
    --
    OPEN v_sale_giorno FOR
    SELECT DISTINCT DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE_PREV, MAX(NUM_SALE) AS NUM_SALE
    FROM
    (
    SELECT DATA_EROGAZIONE_PREV, COUNT(1) AS NUM_SALE
    FROM
    (
    SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
    FROM CD_SPETT_TARGET ST, CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,CD_PROIEZIONE PRO, 
    CD_CINEMA CIN, CD_SCHERMO SC, CD_SALA SA, CD_COMUNICATO COM
    WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND COM.FLG_ANNULLATO = 'N'
    AND COM.FLG_SOSPESO = 'N'
    AND COM.COD_DISATTIVAZIONE IS NULL
    AND SA.ID_SALA = COM.ID_SALA
    AND CIN.ID_CINEMA = SA.ID_CINEMA
    AND CIN.FLG_VIRTUALE = 'N'
    AND SC.ID_SALA = SA.ID_SALA
    AND PRO.ID_SCHERMO = SC.ID_SCHERMO
    AND PRO.DATA_PROIEZIONE = COM.DATA_EROGAZIONE_PREV
    AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
    AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
    AND ST.ID_SPETTACOLO = SPE.ID_SPETTACOLO
    AND ST.ID_TARGET = v_id_target
    AND TRUNC(COM.DATA_EROGAZIONE_PREV) = nvl(p_giorno, COM.DATA_EROGAZIONE_PREV)
    /*MINUS
    SELECT DISTINCT COM.ID_SALA, COM.DATA_EROGAZIONE_PREV
    FROM CD_CINEMA CIN, CD_SALA SA, CD_COMUNICATO COM
    WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND COM.FLG_ANNULLATO = 'N'
    AND COM.FLG_SOSPESO = 'N'
    AND COM.COD_DISATTIVAZIONE IS NULL
    AND SA.ID_SALA = COM.ID_SALA
    AND CIN.ID_CINEMA = SA.ID_CINEMA
    AND TRUNC(COM.DATA_EROGAZIONE_PREV) = nvl(p_giorno, COM.DATA_EROGAZIONE_PREV)
    AND (CIN.FLG_VIRTUALE = 'S'
        OR SA.ID_SALA IN
        (
            SELECT SC.ID_SALA
            FROM CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
            CD_PROIEZIONE PRO, CD_SCHERMO SC
            WHERE SC.ID_SALA = SA.ID_SALA
            AND PRO.ID_SCHERMO = SC.ID_SCHERMO
            AND PRO.DATA_PROIEZIONE = COM.DATA_EROGAZIONE_PREV
            AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
            AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
            AND 
                (SPE.ID_SPETTACOLO NOT IN
                (
                    SELECT ID_SPETTACOLO
                    FROM CD_SPETT_TARGET
                    WHERE ID_TARGET = v_id_target
                )
                OR SPE.ID_SPETTACOLO NOT IN
                (
                    SELECT ID_SPETTACOLO
                    FROM CD_SPETT_TARGET
                )
            )
        )
    )*/
    )
    GROUP BY DATA_EROGAZIONE_PREV
    UNION
    SELECT DISTINCT COM.DATA_EROGAZIONE_PREV, 0 AS NUM_SALE
    FROM CD_COMUNICATO COM
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND COM.FLG_ANNULLATO = 'N'
    AND COM.FLG_SOSPESO = 'N'
    AND COM.COD_DISATTIVAZIONE IS NULL
    AND COM.DATA_EROGAZIONE_PREV = NVL(p_giorno, COM.DATA_EROGAZIONE_PREV)
   )
    GROUP BY DATA_EROGAZIONE_PREV
    ORDER BY DATA_EROGAZIONE_PREV;
    RETURN v_sale_giorno;
END FU_SALE_GIORNO;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_ANNULLA_SALE_NON_ASSEGNATE
--
-- DESCRIZIONE:  Annulla tutte le sale in cui non e presente una programmazione totalmente con il target richiesto,
--               e le sostituisce con una sala virtuale
--
-- INPUT:  p_id_prodotto_acquistato:  id del prodotto
--         p_stato_vendita:           stato di vendita del prodotto
--         p_id_prodotto_vendita:     id del prodotto di vendita
--         p_id_circuito:             id del circuito
--         p_id_target:               id del target
--
-- OUTPUT: 
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_SALE_NON_ASSEGNATE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE, p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE) IS
--
v_id_sala_virtuale CD_SALA.ID_SALA%TYPE;
v_id_break_vendita CD_COMUNICATO.ID_BREAK_VENDITA%TYPE;
v_num_comunicati NUMBER := 0;
BEGIN
--dbms_output.PUT_LINE('p_id_prodotto_acquistato: '||p_id_prodotto_acquistato);
--dbms_output.PUT_LINE('p_id_prodotto_vendita : '||p_id_prodotto_vendita);
--dbms_output.PUT_LINE('p_id_circuito: '||p_id_circuito);
--dbms_output.PUT_LINE('p_id_target: '||p_id_target);        
    SELECT DISTINCT S.ID_SALA
    INTO v_id_sala_virtuale
    FROM CD_CINEMA CIN, CD_SALA S, CD_SCHERMO SC, CD_CIRCUITO_SCHERMO CS
    WHERE CS.ID_CIRCUITO = p_id_circuito
    AND CS.FLG_ANNULLATO = 'N'
    AND SC.ID_SCHERMO = CS.ID_SCHERMO
    AND SC.FLG_ANNULLATO = 'N'
    AND S.ID_SALA = SC.ID_SALA
    AND S.FLG_ANNULLATO = 'N'
    AND CIN.ID_CINEMA = S.ID_CINEMA
    AND CIN.FLG_VIRTUALE = 'S'
    AND ROWNUM <= 1;
    --
    FOR SALA IN (
        SELECT DISTINCT SA.ID_SALA, SV.GIORNO 
        FROM CD_CINEMA CIN, CD_SALA SA, CD_SCHERMO_VIRTUALE_PRODOTTO SV
        WHERE SV.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND TRUNC(SV.GIORNO) >= TRUNC(SYSDATE)
        AND SA.ID_SALA = SV.ID_SALA
        AND CIN.ID_CINEMA = SA.ID_CINEMA
        AND CIN.FLG_VIRTUALE = 'N'
        AND SA.ID_SALA NOT IN
        (
            SELECT SC.ID_SALA
                FROM CD_SPETT_TARGET ST, CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                CD_PROIEZIONE PRO, CD_SCHERMO SC
                WHERE SC.ID_SALA = SA.ID_SALA
                AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                AND PRO.DATA_PROIEZIONE = SV.GIORNO
                AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
                AND ST.ID_SPETTACOLO = SPE.ID_SPETTACOLO
                AND ST.ID_TARGET = p_id_target
        )
        
       /* AND (SA.ID_SALA NOT IN
        (
            SELECT SC.ID_SALA
            FROM CD_PROIEZIONE_SPETT PS,
            CD_PROIEZIONE PRO, CD_SCHERMO SC
            WHERE SC.ID_SALA = SA.ID_SALA
            AND PRO.ID_SCHERMO = SC.ID_SCHERMO
            AND PRO.DATA_PROIEZIONE = SV.GIORNO
            AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
        )
        OR 
        SA.ID_SALA IN
            (
                SELECT SC.ID_SALA
                FROM CD_SPETTACOLO SPE,CD_PROIEZIONE_SPETT PS,
                CD_PROIEZIONE PRO, CD_SCHERMO SC
                WHERE SC.ID_SALA = SA.ID_SALA
                AND PRO.ID_SCHERMO = SC.ID_SCHERMO
                AND PRO.DATA_PROIEZIONE = SV.GIORNO
                AND PS.ID_PROIEZIONE = PRO.ID_PROIEZIONE
                AND SPE.ID_SPETTACOLO = PS.ID_SPETTACOLO
                AND SPE.ID_SPETTACOLO NOT IN
                (
                    SELECT ID_SPETTACOLO
                    FROM CD_SPETT_TARGET
                )
                AND SPE.ID_SPETTACOLO NOT IN
                (
                    SELECT ID_SPETTACOLO
                    FROM CD_SPETT_TARGET
                    WHERE ID_TARGET = p_id_target
                )
            )
        )*/
    ) LOOP
        v_num_comunicati := 0;
        UPDATE CD_SCHERMO_VIRTUALE_PRODOTTO
        SET ID_SALA = v_id_sala_virtuale
        WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
        AND ID_SALA = SALA.ID_SALA
        AND GIORNO = SALA.GIORNO;
        --
        FOR COM IN
        (
            SELECT ID_COMUNICATO, ID_FASCIA
            FROM CD_PROIEZIONE PR, CD_BREAK BR, CD_COMUNICATO COM
            WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND COM.DATA_EROGAZIONE_PREV = SALA.GIORNO
            AND COM.ID_SALA = SALA.ID_SALA
            AND COM.FLG_ANNULLATO = 'N'
            AND COM.FLG_SOSPESO = 'N'
            AND COM.COD_DISATTIVAZIONE IS NULL
            AND BR.ID_BREAK = COM.ID_BREAK
            AND BR.FLG_ANNULLATO = 'N'
            AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
        ) LOOP
            v_num_comunicati := v_num_comunicati +1;
            SELECT DISTINCT BV.ID_BREAK_VENDITA 
            INTO v_id_break_vendita
            FROM CD_BREAK_VENDITA BV, CD_CIRCUITO_BREAK CB, CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SC
            WHERE SC.ID_SALA = v_id_sala_virtuale
            AND PR.ID_SCHERMO = SC.ID_SCHERMO
            AND PR.FLG_ANNULLATO = 'N'
            AND PR.DATA_PROIEZIONE = SALA.GIORNO
            AND BR.ID_PROIEZIONE = PR.ID_PROIEZIONE
            AND BR.FLG_ANNULLATO = 'N'
            AND CB.ID_BREAK = BR.ID_BREAK
            AND CB.ID_CIRCUITO = p_id_circuito
            AND BV.ID_CIRCUITO_BREAK = CB.ID_CIRCUITO_BREAK
            AND BV.ID_PRODOTTO_VENDITA = p_id_prodotto_vendita
            AND PR.ID_FASCIA = COM.ID_FASCIA;
            IF p_stato_vendita = 'PRE' THEN
                PA_CD_PRODOTTO_ACQUISTATO.PR_ELIMINA_BUCO_POSIZIONE_COM(COM.ID_COMUNICATO);
            END IF;
            --
            UPDATE CD_COMUNICATO
            SET ID_SALA = v_id_sala_virtuale,
            ID_BREAK_VENDITA = v_id_break_vendita
            WHERE ID_COMUNICATO = COM.ID_COMUNICATO;
        END LOOP;
        IF v_num_comunicati = 0 THEN
            RAISE_APPLICATION_ERROR(-20025, 'PROCEDURA PR_ANNULLA_SALE_NON_ASSEGNATE: ERRORE NELLA MODIFICA DEI COMUNICATI');
        END IF;
    END LOOP;    
     
END PR_ANNULLA_SALE_NON_ASSEGNATE;

-----------------------------------------------------------------------------------------------------
-- Procedura PR_RICALCOLA_TARIFFA
--
-- DESCRIZIONE:  Effettua il ricalcolo della tariffa dei prodotti a target presenti in un periodo
--
-- INPUT:  p_id_cliente:  codice del cliente; parametro opzionale
--         p_id_target:   id del target cercato
--         p_data_inizio: data di inizio del periodo cercato
--         p_data_fine:   data di fine del periodo cercato
--
-- OUTPUT: 
-- REALIZZATORE: Simone Bottani, Altran, Luglio 2010
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_RICALCOLA_TARIFFA(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) IS
--
v_num_schermi NUMBER;
v_piani_errati VARCHAR2(1024);
v_importo CD_TARIFFA.IMPORTO%TYPE;
BEGIN
    FOR PACQ IN
    (
         SELECT ID_PRODOTTO_ACQUISTATO, PA.STATO_DI_VENDITA, PV.ID_PRODOTTO_VENDITA, PV.ID_CIRCUITO, PV.ID_TARGET, TAR.IMPORTO
         FROM CD_TARIFFA TAR, CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA, CD_PIANIFICAZIONE PIA
         WHERE PA.DATA_INIZIO = p_data_inizio
         AND PA.DATA_FINE = p_data_fine
         AND PA.FLG_ANNULLATO = 'N'
         AND PA.FLG_SOSPESO = 'N'
         AND PA.COD_DISATTIVAZIONE IS NULL
         AND PA.STATO_DI_VENDITA = 'PRE'
         AND PIA.ID_PIANO = PA.ID_PIANO
         AND PIA.ID_VER_PIANO = PIA.ID_VER_PIANO
         AND PIA.FLG_ANNULLATO = 'N'
         AND PIA.FLG_SOSPESO = 'N'
         AND PIA.ID_CLIENTE = NVL(p_id_cliente,PIA.ID_CLIENTE)
         AND PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA
         AND PV.ID_TARGET IS NOT NULL
         AND PV.ID_TARGET = NVL(p_id_target, PV.ID_TARGET)
         AND TAR.ID_PRODOTTO_VENDITA = PV.ID_PRODOTTO_VENDITA
         AND TAR.ID_FORMATO = PA.ID_FORMATO
         AND TAR.ID_MISURA_PRD_VE = PA.ID_MISURA_PRD_VE
    ) LOOP
        v_num_schermi := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_NUM_AMBIENTI(PACQ.ID_PRODOTTO_ACQUISTATO);
        v_importo := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_TARIFFA_PRODOTTO(PACQ.ID_PRODOTTO_ACQUISTATO);
        PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_TARIFFA_PROD_ACQ(PACQ.ID_PRODOTTO_ACQUISTATO,
                                        v_importo,
                                        v_importo,
                                        'S',
                                        v_piani_errati);
    END LOOP;
END PR_RICALCOLA_TARIFFA;


--MV 24/08/2010 aggiunta la group by x disponibilita perche utilizata nella having
FUNCTION FU_GET_SALA_TARGET_GIORNO(p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_giorno CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_durata CD_COEFF_CINEMA.DURATA%TYPE) RETURN CD_COMUNICATO.ID_SALA%TYPE IS
v_id_sala CD_COMUNICATO.ID_SALA%TYPE := -1;
v_disponibilita number;
BEGIN
       BEGIN
       select id_sala,disponibilita--, data_proiezione, disponibilita
       into v_id_sala,v_disponibilita
       from
       (
       select id_sala,disponibilita
       from
       (
           select id_sala,
           PA_CD_ESTRAZIONE_PROD_VENDITA.FU_AFFOLLAMENTO_SALA_STATO(p_giorno, p_giorno, ID_SALA, NULL, 'PRE') AS DISPONIBILITA
           from
           (
               select 
                 sa.ID_SALA, sa.NOME_SALA
                 from 
                    cd_condizione_contratto cond, cd_contratto con, 
                    cd_cinema_contratto cc, cd_cinema cin,
                    cd_proiezione_spett ps, cd_spettacolo spe,
                    cd_spett_target spt, cd_target tar,
                    cd_sala sa,cd_schermo sch, cd_proiezione pro
                where pro.DATA_PROIEZIONE = p_giorno
                and pro.FLG_ANNULLATO = 'N'
                and sch.ID_SCHERMO = pro.ID_SCHERMO
                and sch.ID_SALA = sa.ID_SALA
                and sa.FLG_ANNULLATO = 'N'
                and sa.FLG_VISIBILE = 'S'
                and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                and spt.ID_SPETTACOLO = spe.ID_SPETTACOLO
                and tar.ID_TARGET = spt.id_target
                and tar.id_target = NVL(p_id_target,tar.id_target)
                and (p_id_prodotto_acquistato IS NULL OR sa.ID_SALA NOT IN
                (
                    SELECT ID_SALA FROM CD_SCHERMO_VIRTUALE_PRODOTTO
                    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                    AND ID_SALA = sa.ID_SALA
                    AND GIORNO = pro.DATA_PROIEZIONE
                ))
                and cin.ID_CINEMA = sa.ID_CINEMA
                and cc.ID_CINEMA = cin.ID_CINEMA
                and con.ID_CONTRATTO = cc.ID_CONTRATTO
                and p_giorno BETWEEN con.DATA_INIZIO AND con.DATA_FINE
                and cond.ID_CINEMA_CONTRATTO = cc.ID_CINEMA_CONTRATTO
                and (cond.GIORNO_CHIUSURA IS NULL OR cond.GIORNO_CHIUSURA != to_char(p_giorno, 'D'))
                /*MINUS
                 select sa.ID_SALA, sa.NOME_SALA
                 from  cd_proiezione_spett ps, cd_spettacolo spe,
                 cd_sala sa,  cd_schermo sch, cd_proiezione pro
                where pro.DATA_PROIEZIONE = p_giorno
                and pro.FLG_ANNULLATO = 'N'
                and sch.ID_SCHERMO = pro.ID_SCHERMO
                and sa.ID_SALA = sch.ID_SALA
                and sa.FLG_ANNULLATO = 'N'
                and sa.FLG_VISIBILE = 'S'
                and ps.ID_PROIEZIONE = pro.ID_PROIEZIONE
                and spe.ID_SPETTACOLO = ps.ID_SPETTACOLO
                and spe.ID_SPETTACOLO NOT IN
                (
                    select id_spettacolo
                    from cd_spett_target
                    where id_target = NVL(p_id_target,id_target)
                )*/
            ) order by nome_sala
        )
   --     WHERE DISPONIBILITA > 0
        group by id_sala,disponibilita -- MV 24/08/2010 aggiunta la group by x disponibilita perche utilizata nella having
        having disponibilita >= p_durata
        --order by disponibilita desc
        )
        where rownum <= 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        NULL;
    END; 
    --dbms_output.PUT_LINE('v_id_sala= '||v_id_sala || ' ,p_durata= '||p_durata||', v_disponibilita= '||v_disponibilita);
    RETURN v_id_sala;
END FU_GET_SALA_TARGET_GIORNO;

FUNCTION FU_GET_SALE_VIRTUALI_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER IS
--
v_num_sale NUMBER;
    BEGIN
    SELECT COUNT(DISTINCT SA.ID_SALA)
    INTO v_num_sale
    FROM CD_CINEMA CIN, CD_SALA SA, CD_SCHERMO SC, CD_CIRCUITO_SCHERMO CS
    WHERE CS.ID_CIRCUITO = p_id_circuito
    AND CS.FLG_ANNULLATO = 'N'
    AND SC.ID_SCHERMO = CS.ID_SCHERMO
    AND SC.FLG_ANNULLATO = 'N'
    AND SA.ID_SALA = SC.ID_SALA
    AND SA.FLG_ANNULLATO = 'N'
    AND SA.FLG_VISIBILE = 'S'
    AND CIN.ID_CINEMA = SA.ID_CINEMA
    AND CIN.FLG_VIRTUALE = 'S'
    AND CIN.FLG_ANNULLATO = 'N';
    return v_num_sale;
END FU_GET_SALE_VIRTUALI_CIRCUITO;

FUNCTION FU_SOGLIE_PERIODO(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) RETURN C_SALE_SETTIMANA IS
v_soglie_settimana C_SALE_SETTIMANA;	
BEGIN
     OPEN v_soglie_settimana FOR
     SELECT GIORNO, SOGLIA
     FROM
     (
         SELECT DISTINCT SOGLIA, GIORNO
         FROM CD_PRODOTTO_ACQUISTATO PA, CD_SCHERMO_VIRTUALE_PRODOTTO SVP
         WHERE PA.ID_PRODOTTO_ACQUISTATO = SVP.ID_PRODOTTO_ACQUISTATO
         AND PA.FLG_ANNULLATO = 'N'
         AND PA.FLG_SOSPESO = 'N'
         AND PA.COD_DISATTIVAZIONE IS NULL
         AND GIORNO BETWEEN p_data_inizio AND p_data_fine
         GROUP BY GIORNO, SOGLIA
         ORDER BY GIORNO
     );
RETURN v_soglie_settimana;
END FU_SOGLIE_PERIODO;

END PA_CD_TARGET_NEW; 
/

