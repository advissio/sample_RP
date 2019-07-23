CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_CINEMA IS
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_PRESENZA_SALE_O_ATRII
-- DESCRIZIONE:  la funzione si occupa di verificare se sono presenti sale o atrii in un
--               cinema
--
-- INPUT:  id_cinema del cinema che si intende controllare
-- OUTPUT: esito della procedura. Valori possibili:
--				  1 = sono presenti sale o atrii
--				  0 = non sono presenti ne sale ne atrii
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PRESENZA_SALE_O_ATRII(	P_ID_CINEMA IN CD_CINEMA.ID_CINEMA%TYPE
                                 )
								  RETURN NUMBER
IS
-- DICHIARAZIONE DELLE VARIABILI DI COMODO
v_count_sale	 NUMBER(3);
v_count_atrii	 NUMBER(3);
BEGIN
	 --
     --[#GG1#] VERIFICA PRESENZA SALE NEL CINEMA
     --
     SELECT COUNT(*)
      INTO  v_count_sale
      FROM  CD_CINEMA,CD_SALA
      WHERE CD_CINEMA.id_cinema = CD_SALA.ID_CINEMA
      AND 	CD_CINEMA.ID_CINEMA = p_id_cinema
      AND   CD_CINEMA.FLG_ANNULLATO = 'N';
      --
     --[#GG1#] VERIFICA PRESENZA ATRII NEL CINEMA
     --
     SELECT COUNT(*)
      INTO  v_count_atrii
      FROM  CD_CINEMA,CD_ATRIO
      WHERE CD_CINEMA.ID_CINEMA = CD_ATRIO.ID_CINEMA
      AND 	CD_CINEMA.ID_CINEMA = p_id_cinema;
      IF((v_count_sale>0)OR(v_count_atrii>0))  -- SONO PRESENTI O SALE O ATRII
      	THEN
      		RETURN 1;
      	ELSE
      		RETURN 0;
      END IF;
      RETURN 0;
END  FU_PRESENZA_SALE_O_ATRII;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_CERCA_CINEMA
-- --------------------------------------------------------------------------------------------
-- INPUT:  Criteri di ricerca dei cinema
-- OUTPUT: Restituisce i cinema che rispondono ai criteri di ricerca
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
--              Antonio Colucci 22/09/09 Gestione colonna INDIRIZZO - LOCALE
--              Tommaso D'Anna  24/11/11 Aggiunto filtro di ricerca sulla validita del cinema
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_CINEMA(p_nome_cinema          CD_CINEMA.NOME_CINEMA%TYPE,
                           p_id_tipo_cinema       CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                           p_id_comune            CD_CINEMA.ID_COMUNE%TYPE,
                           p_flg_pubb_locale      CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                           p_id_area_nielsen      CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                           p_id_area_geografica   CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                           p_id_regione           CD_REGIONE.ID_REGIONE%TYPE,
                           p_flg_arena            CD_SALA.FLG_ARENA%TYPE,
                           p_flg_virtuale         CD_CINEMA.FLG_VIRTUALE%TYPE,
                           p_flg_valido           VARCHAR2)
                           RETURN C_CINEMA
IS
   c_cinema_return C_CINEMA;
BEGIN
   OPEN c_cinema_return  -- apre il cursore che contiene i cinema da selezionare
     FOR
        SELECT  
            CINEMA.ID_CINEMA, 
            CINEMA.NOME_CINEMA, 
            CINEMA.ID_TIPO_CINEMA,
            CINEMA.ID_COMUNE, 
            COMUNE.COMUNE,
            CINEMA.FLG_VENDITA_PUBB_LOCALE,
            CINEMA.INDIRIZZO,
            TIPO_CINEMA.DESC_TIPO_CINEMA,
            COUNT(DISTINCT SALA.ID_SALA) AS COUNT_SALE,
            COUNT(DISTINCT ARENA.ID_SALA) AS COUNT_ARENE,
            COUNT(DISTINCT ATRIO.ID_ATRIO) AS COUNT_ATRII
        FROM    CD_CINEMA CINEMA,
                (select distinct id_sala,id_cinema from CD_SALA where FLG_ARENA = 'N') sala,
                (select distinct id_sala,id_cinema from CD_SALA where FLG_ARENA = 'S') arena,
                CD_ATRIO ATRIO, CD_COMUNE COMUNE, CD_TIPO_CINEMA TIPO_CINEMA,
                CD_PROVINCIA PROVINCIA,
                CD_AREA_GEOGRAFICA AREA_GEOGRAFICA, CD_REGIONE REGIONE,
                CD_AREA_NIELSEN AREA_NIELSEN, CD_NIELSEN_REGIONE NIELSEN_REGIONE,CD_SALA
       WHERE    REGIONE.ID_AREA_GEOGRAFICA     =       AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA
        AND     REGIONE.ID_REGIONE             =       NIELSEN_REGIONE.ID_REGIONE
        AND     AREA_NIELSEN.ID_AREA_NIELSEN   =       NIELSEN_REGIONE.ID_AREA_NIELSEN
        AND     PROVINCIA.ID_REGIONE           =       REGIONE.ID_REGIONE
        AND     COMUNE.ID_PROVINCIA            =       PROVINCIA.ID_PROVINCIA
        AND     SALA.ID_CINEMA(+) = CINEMA.ID_CINEMA
        AND     ATRIO.ID_CINEMA(+) = CINEMA.ID_CINEMA
        AND     CINEMA.ID_COMUNE = COMUNE.ID_COMUNE
        AND     CINEMA.ID_TIPO_CINEMA = TIPO_CINEMA.ID_TIPO_CINEMA
        AND     ARENA.ID_CINEMA(+) = CINEMA.ID_CINEMA
        AND     (p_nome_cinema IS NULL OR upper(CINEMA.NOME_CINEMA)  LIKE    upper('%'||p_nome_cinema||'%'))
        AND     (p_id_tipo_cinema IS NULL OR CINEMA.ID_TIPO_CINEMA = p_id_tipo_cinema)
        AND     (p_id_comune IS NULL OR CINEMA.ID_COMUNE = p_id_comune)
        AND     (p_id_area_geografica IS NULL OR REGIONE.ID_AREA_GEOGRAFICA = p_id_area_geografica)
        AND     (p_id_regione IS NULL OR REGIONE.ID_REGIONE = p_id_regione)
        AND     (p_id_area_nielsen IS NULL OR AREA_NIELSEN.ID_AREA_NIELSEN = p_id_area_nielsen)
        AND     (p_flg_virtuale is null or CINEMA.FLG_VIRTUALE = p_flg_virtuale)
        AND     (CINEMA.FLG_ANNULLATO IS NULL OR CINEMA.FLG_ANNULLATO = 'N')
        AND     (p_flg_pubb_locale IS NULL OR CINEMA.FLG_VENDITA_PUBB_LOCALE = p_flg_pubb_locale)
        AND     (p_flg_arena is null or cd_sala.flg_arena = p_flg_arena)
         AND    1 = 
                (
                    CASE 
                        WHEN 
                            (    
                                ( p_flg_valido = 'S' ) 
                                AND 
                                (
                                    ( CINEMA.DATA_INIZIO_VALIDITA <= trunc(SYSDATE) )
                                    AND
                                    (
                                        ( CINEMA.DATA_FINE_VALIDITA >= trunc(SYSDATE) )
                                        OR
                                        ( CINEMA.DATA_FINE_VALIDITA IS NULL )
                                    )
                                )
                            )
                            THEN 1 
                        WHEN 
                            (    
                                ( p_flg_valido = 'N' ) 
                                AND 
                                (
                                    ( CINEMA.DATA_INIZIO_VALIDITA > trunc(SYSDATE) )
                                    OR
                                    ( CINEMA.DATA_FINE_VALIDITA < trunc(SYSDATE) )
                                )
                            )
                            THEN 1
                        WHEN 
                            ( p_flg_valido IS NULL ) 
                            THEN 1 
                    END
                )        
        and      cd_sala.id_cinema(+) = cinema.id_cinema
        GROUP BY CINEMA.ID_CINEMA,CINEMA.NOME_CINEMA, CINEMA.ID_TIPO_CINEMA,
                 CINEMA.ID_COMUNE, COMUNE.COMUNE,CINEMA.INDIRIZZO,CINEMA.FLG_VENDITA_PUBB_LOCALE,
                  TIPO_CINEMA.DESC_TIPO_CINEMA
        ORDER BY CINEMA.NOME_CINEMA;
RETURN c_cinema_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_CERCA_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_CINEMA(p_nome_cinema,
                                                                                                                                                        p_id_tipo_cinema,
                                                                                                                                                        p_id_comune,
                                                                                                                                                        'N'));
END FU_RICERCA_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_DETTAGLIO_CINEMA
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id del cinema
-- OUTPUT: Restituisce il dettaglio del cinema e i relativi atrii, sale ed arene associate
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
--      Antonio Colucci, Teoresi srl, 09/09/2009 - Eliminazione colonne
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
--      Antonio Colucci, Teoresi srl, 16/09/2009 - Ottimizzazione query di dettaglio
--      Antonio Colucci, Teoresi srl, 22/09/2009 - Gestione colonna INDIRIZZO - LOCALE
--      Antonio Colucci, Teoresi srl, 21/04/2011 - Gestione colonna DATA_FINE_VALIDITA
--      Tommaso D'Anna,  Teoresi srl, 07/07/2011 - Gestione colonna DATA_INIZIO_VALIDITA
--      Tommaso D'Anna,  Teoresi srl, 14/07/2011 - Rimozione FLG_ATTIVO
-- --------------------------------------------------------------------------------------------

FUNCTION FU_DETTAGLIO_CINEMA ( p_id_cinema      CD_CINEMA.ID_CINEMA%TYPE )
                               RETURN C_DETTAGLIO_CINEMA

IS
   c_cinema_dettaglio_return C_DETTAGLIO_CINEMA;
BEGIN
OPEN c_cinema_dettaglio_return  -- apre il cursore che conterra il dettaglio del cinema
     FOR
     SELECT  CINEMA.ID_CINEMA, CINEMA.NOME_CINEMA, CINEMA.ID_TIPO_CINEMA,
            CINEMA.ID_COMUNE, COMUNE.COMUNE, CINEMA.FLG_VENDITA_PUBB_LOCALE ,
            CINEMA.FLG_CONCESSIONE_PUBB_LOCALE,
            CINEMA.INDIRIZZO, CINEMA.CAP, REGIONE.NOME_REGIONE,
            AREA_GEOGRAFICA.POSIZIONE,
            AREA_NIELSEN.DESC_AREA,
            AREA_NIELSEN.ID_AREA_NIELSEN, REGIONE.ID_REGIONE, AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA,
            TIPO_CINEMA.DESC_TIPO_CINEMA,
            ID_ATRIO, DESC_ATRIO, NUM_DISTRIBUZIONI, NUM_ESPOSIZIONI, NUM_SCOOTER_MOTO, NUM_CORNER, NUM_LCD, NUM_AUTOMOBILI,
            ID_SALA, ID_TIPO_AUDIO, NOME_SALA, NUMERO_POLTRONE, NUMERO_PROIEZIONI, 
            FLG_ARENA
            --, CINEMA.FLG_ATTIVO
            , CINEMA.RECAPITO_POSTA RECAPITO, CINEMA.DATA_INIZIO_VALIDITA, CINEMA.DATA_FINE_VALIDITA, CINEMA.FLG_VIRTUALE
     FROM   CD_AREA_NIELSEN AREA_NIELSEN, CD_NIELSEN_REGIONE NIELSEN_REGIONE,
            CD_AREA_GEOGRAFICA AREA_GEOGRAFICA, CD_REGIONE REGIONE, CD_PROVINCIA PROVINCIA, CD_COMUNE COMUNE,
            CD_TIPO_CINEMA TIPO_CINEMA, CD_CINEMA CINEMA,
            (SELECT ATRIO.ID_CINEMA, ATRIO.ID_ATRIO, ATRIO.DESC_ATRIO, ATRIO.NUM_DISTRIBUZIONI, ATRIO.NUM_ESPOSIZIONI, ATRIO.NUM_SCOOTER_MOTO,
                    ATRIO.NUM_AUTOMOBILI, ATRIO.NUM_CORNER, ATRIO.NUM_LCD,
                    null ID_SALA, null ID_TIPO_AUDIO, null NOME_SALA, null NUMERO_POLTRONE, null NUMERO_PROIEZIONI, 
                    null FLG_ARENA
                    --, null FLG_ATTIVO
             FROM   CD_ATRIO ATRIO
             WHERE  ATRIO.ID_CINEMA      =    p_id_cinema
             UNION
             SELECT SALA.ID_CINEMA, null ID_ATRIO, null DESC_ATRIO, null NUM_DISTRIBUZIONI, null NUM_ESPOSIZIONI, null NUM_SCOOTER_MOTO,
                    null NUM_AUTOMOBILI, null NUM_CORNER, null NUM_LCD,
                    SALA.ID_SALA, SALA.ID_TIPO_AUDIO, SALA.NOME_SALA, SALA.NUMERO_POLTRONE,
                    SALA.NUMERO_PROIEZIONI, SALA.FLG_ARENA
                    --, null FLG_ATTIVO
             FROM   CD_SALA SALA
             WHERE  SALA.ID_CINEMA      =    p_id_cinema
             ) ATR_SAL
     WHERE  CINEMA.ID_CINEMA = p_id_cinema
     AND    CINEMA.ID_CINEMA                   =    ATR_SAL.ID_CINEMA(+)
     AND    TIPO_CINEMA.ID_TIPO_CINEMA         =    CINEMA.ID_TIPO_CINEMA
     AND    COMUNE.ID_COMUNE                   =    CINEMA.ID_COMUNE
     AND    PROVINCIA.ID_PROVINCIA             =    COMUNE.ID_PROVINCIA
     AND    REGIONE.ID_REGIONE                 =    PROVINCIA.ID_REGIONE
     AND    AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA =    REGIONE.ID_AREA_GEOGRAFICA
     AND    NIELSEN_REGIONE.ID_REGIONE         =    REGIONE.ID_REGIONE
     AND    AREA_NIELSEN.ID_AREA_NIELSEN       =    NIELSEN_REGIONE.ID_AREA_NIELSEN;
RETURN c_cinema_dettaglio_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_DETTAGLIO_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_DETTAGLIO_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_SALE_CINEMA
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id del cinema
-- OUTPUT: Restituisce le sale associate al cinema
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--      Antonio Colucci, Teoresi srl, 09/09/2009 
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
--      Antonio Colucci, Teoresi srl, 28/09/2009 
--                      Modifica REF_CUR di ritorno con
--                      inserimento informazione di ID_CINEMA
--      Tommaso D'Anna, Teoresi srl, 20/01/2011 
--                      Aggiunta ricerca per sale visibili
--      Tommaso D'Anna, Teoresi srl, 24/01/2011
--                      Aggiunto recupero nome comune
--      Tommaso D'Anna, Teoresi srl, 24/11/2011
--                      Aggiunto il filtro per sale virtuali e valide
-- --------------------------------------------------------------------------------------------

FUNCTION FU_SALE_CINEMA      ( p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                               p_id_area_nielsen    CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                               p_id_tipo_cinema     CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                               p_id_comune          CD_CINEMA.ID_COMUNE%TYPE,
                               p_visibile           CD_SALA.FLG_VISIBILE%TYPE,
                               p_flg_virtuale       CD_CINEMA.FLG_VIRTUALE%TYPE,
                               p_flg_valido         VARCHAR2)
                               RETURN C_SALE
IS
    c_sale_return C_SALE;
    v_nome_cinema CD_CINEMA.NOME_CINEMA%TYPE;
BEGIN
    --SELECT FU_DAMMI_NOME_CINEMA(p_id_cinema) INTO v_nome_cinema FROM DUAL;
    OPEN c_sale_return  -- apre il cursore che conterra il dettaglio del cinema
        FOR
            SELECT 
                SALA.ID_SALA, 
                SALA.ID_TIPO_AUDIO,
                PA_CD_SALA.FU_DAMMI_DESC_TIPO_AUDIO(SALA.ID_TIPO_AUDIO) AS DESC_TIPO_AUDIO,
                CINEMA.ID_CINEMA, 
                NOME_CINEMA, 
                COMUNE.COMUNE, 
                SALA.NOME_SALA,
                SALA.NUMERO_POLTRONE, 
                SALA.NUMERO_PROIEZIONI,
                SALA.FLG_ARENA, 
                SALA.FLG_VISIBILE
            FROM
                CD_CINEMA CINEMA, 
                CD_SALA SALA, 
                CD_COMUNE COMUNE,
                CD_TIPO_CINEMA TIPO_CINEMA, 
                CD_PROVINCIA PROVINCIA,
                CD_REGIONE REGIONE, 
                CD_AREA_NIELSEN AREA_NIELSEN,
                CD_NIELSEN_REGIONE NIELSEN_REGIONE
            WHERE   SALA.FLG_ARENA                      <>  'S'
            AND     REGIONE.ID_REGIONE                  =   NIELSEN_REGIONE.ID_REGIONE
            AND     AREA_NIELSEN.ID_AREA_NIELSEN        =   NIELSEN_REGIONE.ID_AREA_NIELSEN
            AND     PROVINCIA.ID_REGIONE                =   REGIONE.ID_REGIONE
            AND     COMUNE.ID_PROVINCIA                 =   PROVINCIA.ID_PROVINCIA
            AND     CINEMA.ID_COMUNE                    =   COMUNE.ID_COMUNE
            AND     CINEMA.ID_TIPO_CINEMA               =   TIPO_CINEMA.ID_TIPO_CINEMA
            AND     SALA.FLG_ANNULLATO                  =  'N'
            AND     SALA.ID_CINEMA                      =   CINEMA.ID_CINEMA            
            AND     ID_SALA                             >   -1                        
            AND     ( 
                        p_id_cinema IS NULL 
                        OR 
                        SALA.ID_CINEMA                  =   p_id_cinema
                    )
            AND     (
                        p_id_comune IS NULL 
                        OR 
                        CINEMA.ID_COMUNE                =   p_id_comune
                    )
            AND     (
                        p_id_area_nielsen IS NULL 
                        OR 
                        AREA_NIELSEN.ID_AREA_NIELSEN    =   p_id_area_nielsen
                    )
            AND     (
                        p_id_tipo_cinema IS NULL 
                        OR 
                        CINEMA.ID_TIPO_CINEMA           =   p_id_tipo_cinema
                    )
            AND     (
                        p_visibile IS NULL 
                        OR 
                        SALA.FLG_VISIBILE               =   p_visibile 
                    )
            AND     (
                        p_flg_virtuale IS NULL 
                        OR 
                        CINEMA.FLG_VIRTUALE             =   p_flg_virtuale
                    )
            AND    1 = 
                   (
                       CASE 
                           WHEN 
                               (    
                                   ( p_flg_valido = 'S' ) 
                                   AND 
                                   (
                                       ( SALA.DATA_INIZIO_VALIDITA <= trunc(SYSDATE) )
                                       AND
                                       (
                                           ( SALA.DATA_FINE_VALIDITA >= trunc(SYSDATE) )
                                           OR
                                           ( SALA.DATA_FINE_VALIDITA IS NULL )
                                       )
                                   )
                               )
                               THEN 1 
                           WHEN 
                               (    
                                   ( p_flg_valido = 'N' ) 
                                   AND 
                                   (
                                       ( SALA.DATA_INIZIO_VALIDITA > trunc(SYSDATE) )
                                       OR
                                       ( SALA.DATA_FINE_VALIDITA < trunc(SYSDATE) )
                                   )
                               )
                               THEN 1
                           WHEN 
                               ( p_flg_valido IS NULL ) 
                               THEN 1 
                       END
                   )             
            ORDER BY CINEMA.NOME_CINEMA, COMUNE.COMUNE, SALA.NOME_SALA;
RETURN c_sale_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SALE_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_SALE_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ARENE_CINEMA
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id del cinema
-- OUTPUT: Restituisce le arene associate al cinema
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--      Antonio Colucci, Teoresi srl, 09/09/2009 - Eliminazione colonne
--              Eliminazione colonne
--                      FLG_STATO
--                      DISTANZA_PROIETTORE
--                      FLG_PROIETTORE_DIGITALE
--                      FLG_PROIETTORE_ANALOGICO
--      Antonio Colucci, Teoresi srl, 28/09/2009 - Modifica REF_CUR di ritorno con
--                      inserimento informazione di ID_CINEMA
--      Tommaso D'Anna, Teoresi srl, 20/01/2011 
--                      Aggiunta ricerca per sale visibili
--      Tommaso D'Anna, Teoresi srl, 24/01/2011
--                      Aggiunto recupero nome comune
--      Tommaso D'Anna, Teoresi srl, 24/11/2011
--                      Aggiunto il filtro per sale virtuali e valide
-- --------------------------------------------------------------------------------------------

FUNCTION FU_ARENE_CINEMA      ( p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                                p_id_area_nielsen    CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                                p_id_tipo_cinema     CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                                p_id_comune          CD_CINEMA.ID_COMUNE%TYPE,
                                p_visibile           CD_SALA.FLG_VISIBILE%TYPE,
                                p_flg_virtuale       CD_CINEMA.FLG_VIRTUALE%TYPE,
                                p_flg_valido         VARCHAR2)                               
                               RETURN C_SALE
IS
   c_sale_return C_SALE;
   v_nome_cinema CD_CINEMA.NOME_CINEMA%TYPE;
BEGIN
--SELECT FU_DAMMI_NOME_CINEMA(p_id_cinema) INTO v_nome_cinema FROM DUAL;
OPEN c_sale_return  -- apre il cursore che conterra il dettaglio del cinema
    FOR
        SELECT 
            SALA.ID_SALA, 
            SALA.ID_TIPO_AUDIO,
            PA_CD_SALA.FU_DAMMI_DESC_TIPO_AUDIO(SALA.ID_TIPO_AUDIO) AS DESC_TIPO_AUDIO,
            CINEMA.ID_CINEMA, 
            NOME_CINEMA, 
            COMUNE.COMUNE, 
            SALA.NOME_SALA,
            SALA.NUMERO_POLTRONE, 
            SALA.NUMERO_PROIEZIONI,
            SALA.FLG_ARENA, 
            SALA.FLG_VISIBILE
        FROM
            CD_CINEMA CINEMA, 
            CD_SALA SALA, 
            CD_COMUNE COMUNE,
            CD_TIPO_CINEMA TIPO_CINEMA, 
            CD_PROVINCIA PROVINCIA,
            CD_REGIONE REGIONE, 
            CD_AREA_NIELSEN AREA_NIELSEN,
            CD_NIELSEN_REGIONE NIELSEN_REGIONE
        WHERE   SALA.FLG_ARENA                      =   'S'
        AND     REGIONE.ID_REGIONE                  =   NIELSEN_REGIONE.ID_REGIONE
        AND     AREA_NIELSEN.ID_AREA_NIELSEN        =   NIELSEN_REGIONE.ID_AREA_NIELSEN
        AND     PROVINCIA.ID_REGIONE                =   REGIONE.ID_REGIONE
        AND     COMUNE.ID_PROVINCIA                 =   PROVINCIA.ID_PROVINCIA
        AND     CINEMA.ID_COMUNE                    =   COMUNE.ID_COMUNE
        AND     CINEMA.ID_TIPO_CINEMA               =   TIPO_CINEMA.ID_TIPO_CINEMA
        AND     SALA.FLG_ANNULLATO                  =   'N'        
        AND     SALA.ID_CINEMA                      =   CINEMA.ID_CINEMA        
        AND     ID_SALA                             >   -1        
        AND     (
                    p_id_cinema IS NULL 
                    OR 
                    SALA.ID_CINEMA                  =    p_id_cinema
                )
        AND     (
                    p_id_comune IS NULL 
                    OR 
                    CINEMA.ID_COMUNE                =   p_id_comune
                )
        AND     (
                    p_id_area_nielsen IS NULL 
                    OR 
                    AREA_NIELSEN.ID_AREA_NIELSEN    =   p_id_area_nielsen
                )
        AND     (
                    p_id_tipo_cinema IS NULL 
                    OR 
                    CINEMA.ID_TIPO_CINEMA           =   p_id_tipo_cinema
                )
        AND     (
                    p_visibile IS NULL 
                    OR 
                    SALA.FLG_VISIBILE               =   p_visibile 
                )
        AND     (
                    p_flg_virtuale IS NULL 
                    OR 
                    CINEMA.FLG_VIRTUALE             =   p_flg_virtuale
                )
        AND    1 = 
               (
                   CASE 
                       WHEN 
                           (    
                               ( p_flg_valido = 'S' ) 
                               AND 
                               (
                                   ( SALA.DATA_INIZIO_VALIDITA <= trunc(SYSDATE) )
                                   AND
                                   (
                                       ( SALA.DATA_FINE_VALIDITA >= trunc(SYSDATE) )
                                       OR
                                       ( SALA.DATA_FINE_VALIDITA IS NULL )
                                   )
                               )
                           )
                           THEN 1 
                       WHEN 
                           (    
                               ( p_flg_valido = 'N' ) 
                               AND 
                               (
                                   ( SALA.DATA_INIZIO_VALIDITA > trunc(SYSDATE) )
                                   OR
                                   ( SALA.DATA_FINE_VALIDITA < trunc(SYSDATE) )
                               )
                           )
                           THEN 1
                       WHEN 
                           ( p_flg_valido IS NULL ) 
                           THEN 1 
                   END
               );
RETURN c_sale_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_ARENE_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_ARENE_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_ATRII_CINEMA
-- --------------------------------------------------------------------------------------------
-- INPUT:  Id del cinema
-- OUTPUT: Restituisce gli atrii associati al cinema
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
--      Antonio Colucci, Teoresi srl, 28/09/2009 - Modifica REF_CUR di ritorno con
--                      inserimento informazione di ID_CINEMA
-- --------------------------------------------------------------------------------------------

FUNCTION FU_ATRII_CINEMA      ( p_id_cinema          CD_CINEMA.ID_CINEMA%TYPE,
                               p_id_area_nielsen    CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                               p_id_tipo_cinema     CD_TIPO_CINEMA.ID_TIPO_CINEMA%TYPE,
                               p_id_comune          CD_CINEMA.ID_COMUNE%TYPE)
                               RETURN C_ATRII
IS
   c_atrii_return C_ATRII;
   v_nome_cinema CD_CINEMA.NOME_CINEMA%TYPE;
BEGIN
   --SELECT FU_DAMMI_NOME_CINEMA(p_id_cinema) INTO v_nome_cinema FROM DUAL;
   OPEN c_atrii_return  -- apre il cursore che conterra il dettaglio del cinema
     FOR
     SELECT ATRIO.ID_ATRIO, ATRIO.DESC_ATRIO, CINEMA.ID_CINEMA, NOME_CINEMA,
            ATRIO.NUM_DISTRIBUZIONI, ATRIO.NUM_ESPOSIZIONI,
            ATRIO.NUM_SCOOTER_MOTO, ATRIO.NUM_CORNER, ATRIO.NUM_LCD,
            ATRIO.NUM_AUTOMOBILI
     FROM   CD_CINEMA CINEMA, CD_ATRIO ATRIO, CD_COMUNE COMUNE,
            CD_TIPO_CINEMA TIPO_CINEMA, CD_PROVINCIA PROVINCIA,
            CD_REGIONE REGIONE, CD_AREA_NIELSEN AREA_NIELSEN,
            CD_NIELSEN_REGIONE NIELSEN_REGIONE
     WHERE  (p_id_cinema IS NULL OR ATRIO.ID_CINEMA       =    p_id_cinema)
     AND    REGIONE.ID_REGIONE             =       NIELSEN_REGIONE.ID_REGIONE
     AND    AREA_NIELSEN.ID_AREA_NIELSEN   =       NIELSEN_REGIONE.ID_AREA_NIELSEN
     AND    PROVINCIA.ID_REGIONE           =       REGIONE.ID_REGIONE
     AND    COMUNE.ID_PROVINCIA            =       PROVINCIA.ID_PROVINCIA
     AND    CINEMA.ID_COMUNE               =       COMUNE.ID_COMUNE
     AND    CINEMA.ID_TIPO_CINEMA          =       TIPO_CINEMA.ID_TIPO_CINEMA
     AND    (p_id_area_nielsen IS NULL OR AREA_NIELSEN.ID_AREA_NIELSEN = p_id_area_nielsen)
     AND    (p_id_tipo_cinema IS NULL OR CINEMA.ID_TIPO_CINEMA = p_id_tipo_cinema)
     AND    ID_ATRIO                 >   -1
     AND    ATRIO.FLG_ANNULLATO   =    'N'
     AND    (p_id_comune IS NULL OR CINEMA.ID_COMUNE = p_id_comune)
     AND    ATRIO.ID_CINEMA       = CINEMA.ID_CINEMA;
RETURN c_atrii_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_SALE_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_ATRII_CINEMA;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_INSERISCI_CINEMA
--
-- DESCRIZIONE:  Esegue l'inserimento di un nuovo cinema nel sistema
--
-- INPUT:
--      p_nome_cinema               nome del cinema
--      p_id_tipo_cinema            id del tipo cinema
--      p_id_comune                 id del comune
--      p_flag_virtuale             flag che indica lo stato del cinema
--      p_id_direttore_complesso    id del direttore del complesso
--
-- OPERAZIONI:
--   1) Memorizza il cinema (CD_CINEMA)
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -1  Inserimento non eseguito: errore nei parametri di Insert del cinema
--   -11 Inserimento non eseguito: errore nell'associazione del direttore del complesso
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--              Antonio Colucci     22 Settembre 2009       Gestione colonna INDIRIZZO - LOCALE
--              Tommaso D'Anna      22 Dicembre 2010        Inserimento della gestione nome cinema
--              Tommaso D'Anna      7 Luglio 2011           Inserimento della gestione inizio validita cinema       
--              Tommaso D'Anna,     14 Luglio 2011          Rimozione FLG_ATTIVO
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_CINEMA(p_nome_cinema             CD_CINEMA.NOME_CINEMA%TYPE,
                              p_id_tipo_cinema          CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                              p_id_comune               CD_CINEMA.ID_COMUNE%TYPE,
                              p_flg_pubb_locale         CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                              p_flg_concessione         CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE%TYPE,
                              p_indirizzo               CD_CINEMA.INDIRIZZO%TYPE,
                              p_flg_virtuale            CD_CINEMA.FLG_VIRTUALE%TYPE,
                              p_cap                     CD_CINEMA.CAP%TYPE,
                              p_id_direttore_complesso  CD_DIRETTORE.ID_DIRETTORE%TYPE,
                              --p_flg_attivo              CD_CINEMA.FLG_ATTIVO%TYPE,
                              p_recapito                CD_CINEMA.RECAPITO_POSTA%TYPE,
                              p_data_inizio_val         CD_NOME_CINEMA.DATA_INIZIO%TYPE,
							  p_esito			        OUT NUMBER)
IS
   id_cinema_val   CD_CINEMA.ID_CINEMA%TYPE;
   p_esito_dir     NUMBER(5);
BEGIN -- PR_INSERISCI_CINEMA
    p_esito 	:= 1;
    --P_ID_CINEMA := CINEMA_SEQ.NEXTVAL;
  		SAVEPOINT SP_PR_INSERISCI_CINEMA;
       -- effettuo l'INSERIMENTO
	   INSERT INTO CD_CINEMA
	     (NOME_CINEMA,
	      ID_TIPO_CINEMA,
	      ID_COMUNE,
          FLG_VENDITA_PUBB_LOCALE,
          FLG_CONCESSIONE_PUBB_LOCALE,
          INDIRIZZO,
	      FLG_VIRTUALE,
          CAP,
          --FLG_ATTIVO,
          RECAPITO_POSTA,
          DATA_INIZIO_VALIDITA,
          UTEMOD,
	      DATAMOD
	     )
	   VALUES
	     (p_nome_cinema,
		  p_id_tipo_cinema,
		  p_id_comune,
          p_flg_pubb_locale,
          p_flg_concessione,
          p_indirizzo,
		  nvl(p_flg_virtuale,'N'),
          p_cap,
          --p_flg_attivo,
          p_recapito,
          nvl( p_data_inizio_val, trunc(sysdate)),
          user,
		  FU_DATA_ORA
		  );
       SELECT CD_CINEMA_SEQ.CURRVAL
       INTO id_cinema_val
       FROM DUAL;
       PR_ASSOCIA_DIR_COMPLESSO(id_cinema_val, p_id_direttore_complesso,p_esito_dir);
       IF(p_esito_dir=-11) THEN
           p_esito := -11;
       END IF;
       INSERT INTO CD_NOME_CINEMA
	     (ID_CINEMA,
	      NOME_CINEMA,
          DATA_INIZIO,
          DATA_FINE,
          UTEMOD,
	      DATAMOD
	     )
	   VALUES
	     (id_cinema_val,
		  p_nome_cinema,
		  nvl( p_data_inizio_val, trunc(sysdate)),
          null,
          user,
		  FU_DATA_ORA
		 );
	EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
		WHEN OTHERS THEN
		p_esito := -1;
		RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_INSERISCI_CINEMA: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI :'||sqlerrm);
		ROLLBACK TO SP_PR_INSERISCI_CINEMA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ASSOCIA_DIR_COMPLESSO
--
-- DESCRIZIONE:  Esegue l'associazione di un direttore di complesso ad un cinema
--
-- OPERAZIONI:
--   3) Memorizza nell'entita associativa (CD_CINEMA_DIRETTORE) il direttore ed il cinema
--
-- INPUT:
--      p_id_cinema                 id del cinema
--      p_id_direttore_complesso    id del direttore del complesso
--
-- OUTPUT: esito:
--    n  numero di record inseriti con successo
--   -11 Inserimento non eseguito: i parametri per la Insert non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ASSOCIA_DIR_COMPLESSO  (p_id_cinema               CD_CINEMA.ID_CINEMA%TYPE,
                                     p_id_direttore_complesso  CD_DIRETTORE.ID_DIRETTORE%TYPE,
                                     p_esito			       OUT NUMBER)
IS
BEGIN -- PR_ASSOCIA_DIR_COMPLESSO
       p_esito:= 1;
  		SAVEPOINT SP_PR_ASSOCIA_DIR_COMPLESSO;
        IF (p_id_direttore_complesso IS NOT NULL) THEN
           -- effettuo l'INSERIMENTO
    	   INSERT INTO CD_CINEMA_DIRETTORE
    	     (ID_CINEMA,
              ID_DIRETTORE,
              DATA_INIZIO,
              DATA_FINE,
    	      UTEMOD,
    	      DATAMOD
    	     )
    	   VALUES
    	     (p_id_cinema,
    		  p_id_direttore_complesso,
    		  FU_DATA_ORA,
    		  null,
    		  user,
    		  FU_DATA_ORA
    		  );
        END IF;
	EXCEPTION  -- SE VIENE LANCIATA L'eccezione effettua una rollback fino al Savepoint indicato
		WHEN OTHERS THEN
		p_esito := -11;
		RAISE_APPLICATION_ERROR(-20002, 'PROCEDURA PR_ASSOCIA_DIR_COMPLESSO: INSERT NON ESEGUITA, VERIFICARE LA COERENZA DEI PARAMETRI');
		ROLLBACK TO SP_PR_ASSOCIA_DIR_COMPLESSO;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_ELIMINA_CINEMA
--
-- DESCRIZIONE:  Esegue l'eliminazione di un cinema dal sistema
--
--
-- OPERAZIONI:
--   1) Elimina il cinema
--
-- INPUT:
--      p_id_cinema                 id del cinema
--
-- OUTPUT: esito:
--    n  numero di record eliminati
--   -1  Eliminazione non eseguita: i parametri per la Delete non sono coerenti
--
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Ottobre 2009
--
--  MODIFICHE:
--              Tommaso D'Anna, Teoresi s.r.l., 4 Luglio 2011
-------------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_CINEMA(  p_id_cinema		IN CD_CINEMA.ID_CINEMA%TYPE,
							  p_esito			OUT NUMBER)
IS
BEGIN -- PR_ELIMINA_CINEMA
    p_esito 	:= 1;
     --
  	SAVEPOINT SP_PR_ELIMINA_CINEMA;
    DELETE FROM CD_CINEMA_DIRETTORE
    WHERE ID_CINEMA = p_id_cinema;

    -- elimino il circuito cinema
    DELETE FROM CD_CINEMA_VENDITA
    WHERE ID_CIRCUITO_CINEMA IN
        (SELECT ID_CIRCUITO_CINEMA FROM CD_CIRCUITO_CINEMA
         WHERE ID_CINEMA = p_id_cinema);

    DELETE FROM CD_CIRCUITO_CINEMA
    WHERE ID_CINEMA = p_id_cinema;

    -- elimino le sale ed i circuiti associati
    PA_CD_SALA.PR_ELIMINA_SALA_CINEMA(p_id_cinema,p_esito);

    -- elimino gli atrii ed i circuiti associati
    PA_CD_ATRIO.PR_ELIMINA_ATRIO_CINEMA(p_id_cinema,p_esito);

    -- elimino il nome cinema
    DELETE FROM CD_NOME_CINEMA
    WHERE ID_CINEMA = p_id_cinema;

    -- effettua l'ELIMINAZIONE
	DELETE FROM CD_CINEMA
	WHERE ID_CINEMA = p_id_cinema;
    p_esito := SQL%ROWCOUNT;
EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'Procedura PR_ELIMINA_CINEMA: Delete non eseguita, verificare la coerenza dei parametri '||sqlerrm);
		p_esito := -1;
        ROLLBACK TO SP_PR_ELIMINA_CINEMA;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_CINEMA
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di un cinema, delle sale associate,
--                  degli atrii, degli schermi, dei relativi circuiti
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- OPERAZIONI:
--   1) Cancella logicamente cinema, atrii, sale, schermi, break, proiezioni, circuiti_ambiti
--      ambiti_vendita, comunicati, prodotti
-- INPUT:  Id del cinema
-- OUTPUT: esito:
--    n  numero di record modificati >=0
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_CINEMA(p_id_cinema		IN CD_CINEMA.ID_CINEMA%TYPE,
							p_esito			OUT NUMBER,
                            p_piani_errati  OUT VARCHAR2)
IS
    v_esito     NUMBER:=0;
BEGIN
    p_esito 	:= 0;
    --SEZIONE SCHERMI E BREAK
    FOR TEMP IN(SELECT DISTINCT CD_SALA.ID_SALA
                FROM CD_SALA
                WHERE CD_SALA.ID_CINEMA=p_id_cinema
                AND CD_SALA.FLG_ANNULLATO<>'S')LOOP
		PA_CD_SALA.PR_ANNULLA_SALA(TEMP.ID_SALA, v_esito, p_piani_errati);
		p_esito:=p_esito+v_esito;
	END LOOP;
	FOR TEMP IN(SELECT DISTINCT CD_ATRIO.ID_ATRIO
                FROM CD_ATRIO
                WHERE CD_ATRIO.ID_CINEMA=p_id_cinema
                AND CD_ATRIO.FLG_ANNULLATO<>'S')LOOP
		PA_CD_ATRIO.PR_ANNULLA_ATRIO(TEMP.ID_ATRIO, v_esito, p_piani_errati);
		p_esito:=p_esito+v_esito;
	END LOOP;
    -- SELEZIONE DEL CINEMA P_ID_CINEMA
    FOR TEMP IN(SELECT ID_COMUNICATO
	            FROM   CD_COMUNICATO
                WHERE CD_COMUNICATO.ID_CINEMA_VENDITA IN(
                         SELECT DISTINCT CD_CINEMA_VENDITA.ID_CINEMA_VENDITA
                             FROM  CD_CINEMA_VENDITA
                         WHERE CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA IN(
                                SELECT DISTINCT CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
                            FROM   CD_CIRCUITO_CINEMA
                            WHERE  CD_CIRCUITO_CINEMA.ID_CINEMA=p_id_cinema
                            AND    CD_CIRCUITO_CINEMA.ID_LISTINO IN(
                                     SELECT DISTINCT CD_LISTINO.ID_LISTINO
                               FROM  CD_LISTINO
                               WHERE CD_LISTINO.DATA_FINE > SYSDATE)
                            AND CD_CIRCUITO_CINEMA.FLG_ANNULLATO<>'S'))
                AND CD_COMUNICATO.FLG_ANNULLATO<>'S') LOOP
		PA_CD_COMUNICATO.PR_ANNULLA_COMUNICATO(TEMP.ID_COMUNICATO, 'PAL',v_esito,p_piani_errati);
		IF((v_esito=5) OR (v_esito=15) OR (v_esito=25)) THEN
		    p_esito := p_esito + 1;
		END IF;
	END LOOP;
    --qui recupero tutti i cinema vendita
    UPDATE  CD_CINEMA_VENDITA
    SET FLG_ANNULLATO='S'
    WHERE   CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA IN(
               SELECT DISTINCT CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
               FROM   CD_CIRCUITO_CINEMA
               WHERE  CD_CIRCUITO_CINEMA.ID_CINEMA=p_id_cinema
               AND    CD_CIRCUITO_CINEMA.ID_LISTINO IN(
                      SELECT DISTINCT CD_LISTINO.ID_LISTINO
                  FROM  CD_LISTINO
                  WHERE CD_LISTINO.DATA_FINE > SYSDATE)
               AND CD_CIRCUITO_CINEMA.FLG_ANNULLATO<>'S')
    AND     CD_CINEMA_VENDITA.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti cinema
    UPDATE  CD_CIRCUITO_CINEMA
    SET FLG_ANNULLATO='S'
    WHERE  CD_CIRCUITO_CINEMA.ID_CINEMA=p_id_cinema
    AND    CD_CIRCUITO_CINEMA.ID_LISTINO IN(
              SELECT DISTINCT CD_LISTINO.ID_LISTINO
              FROM   CD_LISTINO
              WHERE  CD_LISTINO.DATA_FINE > SYSDATE)
    AND    CD_CIRCUITO_CINEMA.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --infine seleziono il cinema
    UPDATE CD_CINEMA
    SET FLG_ANNULLATO='S'
    WHERE  CD_CINEMA.ID_CINEMA=p_id_cinema
    AND    CD_CINEMA.FLG_ANNULLATO<>'S';
    p_esito := p_esito + SQL%ROWCOUNT;
 EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'Procedura PR_ANNULLA_CINEMA: Eliminazione logica non eseguita: si e'' verificato un errore inatteso '||SQLERRM);
		p_esito := -1;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ANNULLA_LISTA_CINEMA
--
-- DESCRIZIONE:  Esegue la cancellazione logioca di una lista cinema
--               Per maggiori dettagli guardare la documentaione di
--               PA_CD_CINEMA.PR_ANNULLA_CINEMA
-- INPUT: Lista di Id del cinema
-- OUTPUT: esito:
--    n  numero dei cinema annullati (che dovrebbe coincidere con p_lista_cinema.COUNT)
--   -1  Eliminazione logica non eseguita: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ANNULLA_LISTA_CINEMA(p_lista_cinema	IN id_cinema_type,
							      p_esito			OUT NUMBER,
                                  p_piani_errati  OUT VARCHAR2)
IS
    v_temp  INTEGER:=0;
BEGIN
    SAVEPOINT SP_PR_ANNULLA_LISTA_CINEMA;
    p_esito:=0;
    FOR i IN 1..p_lista_cinema.COUNT LOOP
	    PA_CD_CINEMA.PR_ANNULLA_CINEMA(p_lista_cinema(i),v_temp,p_piani_errati);
		IF(v_temp>=0)THEN
	        p_esito:=p_esito+1;
		ELSE
	        p_esito:=p_esito-1;
		END IF;
	END LOOP;
EXCEPTION
  	WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'Procedura PR_ANNULLA_LISTA_CINEMA: Eliminazione logica non eseguita: si e'' verificato un errore inatteso '||SQLERRM);
		p_esito := -1;
		ROLLBACK TO SP_PR_ANNULLA_LISTA_CINEMA;
END;
--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_RECUPERA_CINEMA
--
-- DESCRIZIONE:  Esegue il ripristino dalla cancellazione logioca di un cinema, delle sale associate,
--                  degli atrii, degli schermi, dei relativi circuiti, dei break, delle proiezioni
--                  degli ambiti vendita, dei comunicati e dei prodotti
--
-- INPUT:
--      p_id_cinema                 id del cinema
--
-- OPERAZIONI:
--   1) Recupera cinema, atrii, sale, schermi, break, proiezioni, circuiti_ambiti
--      ambiti_vendita, comunicati cancellati precedentemente logicamente
--
-- OUTPUT: esito:
--    n  numero di record modificati
--   -1  Recupero non eseguito: si e' verificato un errore inatteso
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
--  MODIFICHE:
--
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_RECUPERA_CINEMA(p_id_cinema		IN CD_CINEMA.ID_CINEMA%TYPE,
					 		 p_esito			OUT NUMBER)
IS
    v_data_recupero DATE;
	v_esito     NUMBER:=0;
BEGIN
    p_esito 	:= 0;
	SELECT CD_CINEMA.DATAMOD
	INTO v_data_recupero
	FROM CD_CINEMA
	WHERE CD_CINEMA.ID_CINEMA=p_id_cinema;
    SAVEPOINT SP_PR_RECUPERA_CINEMA;
    --SEZIONE SCHERMI E BREAK
    -- manca il recupero eventuale dei comunicati
    FOR TEMP IN(SELECT DISTINCT CD_SALA.ID_SALA
                FROM CD_SALA
                WHERE CD_SALA.ID_CINEMA=p_id_cinema
                AND CD_SALA.FLG_ANNULLATO<>'S')LOOP
		PA_CD_SALA.PR_RECUPERA_SALA(TEMP.ID_SALA, v_esito);
		p_esito:=p_esito+v_esito;
	END LOOP;
	FOR TEMP IN(SELECT DISTINCT CD_ATRIO.ID_ATRIO
                FROM CD_ATRIO
                WHERE CD_ATRIO.ID_CINEMA=p_id_cinema
                AND CD_ATRIO.FLG_ANNULLATO<>'S')LOOP
		PA_CD_ATRIO.PR_RECUPERA_ATRIO(TEMP.ID_ATRIO, v_esito);
		p_esito:=p_esito+v_esito;
	END LOOP;
    -- SELEZIONE DEL CINEMA P_ID_CINEMA
    -- manca il recupero eventuale dei comunicati
    --qui recupero tutti i cinema vendita
    UPDATE  CD_CINEMA_VENDITA
    SET FLG_ANNULLATO='N'
    WHERE   CD_CINEMA_VENDITA.ID_CIRCUITO_CINEMA IN(
               SELECT DISTINCT CD_CIRCUITO_CINEMA.ID_CIRCUITO_CINEMA
               FROM   CD_CIRCUITO_CINEMA
               WHERE  CD_CIRCUITO_CINEMA.ID_CINEMA=p_id_cinema
               AND    CD_CIRCUITO_CINEMA.ID_LISTINO IN(
                      SELECT DISTINCT CD_LISTINO.ID_LISTINO
                  FROM  CD_LISTINO
                  WHERE CD_LISTINO.DATA_FINE > v_data_recupero)
               AND CD_CIRCUITO_CINEMA.FLG_ANNULLATO='S')
    AND     CD_CINEMA_VENDITA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --qui recupero i circuiti cinema
    UPDATE  CD_CIRCUITO_CINEMA
    SET FLG_ANNULLATO='N'
    WHERE  CD_CIRCUITO_CINEMA.ID_CINEMA=p_id_cinema
    AND    CD_CIRCUITO_CINEMA.ID_LISTINO IN(
              SELECT DISTINCT CD_LISTINO.ID_LISTINO
              FROM   CD_LISTINO
              WHERE  CD_LISTINO.DATA_FINE > v_data_recupero)
    AND    CD_CIRCUITO_CINEMA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
    --in fine seleziono il cinema
    UPDATE CD_CINEMA
    SET FLG_ANNULLATO='N'
    WHERE  CD_CINEMA.ID_CINEMA=p_id_cinema
    AND    CD_CINEMA.FLG_ANNULLATO='S';
    p_esito := p_esito + SQL%ROWCOUNT;
 EXCEPTION
  		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'Procedura PR_RECUPERA_CINEMA: Recupero non eseguito: si e'' verificato un errore inatteso');
		p_esito := -1;
        ROLLBACK TO SP_PR_RECUPERA_CINEMA;
END;
-----------------------------------------------------------------------------------------------------
-- Procedura PR_MODIFICA_CINEMA
--
-- DESCRIZIONE:  Esegue l'eliminazione singola di un cinema dal sistema
--
-- OPERAZIONI:
--   1) Modifica il cinema
--
-- INPUT:
--      p_id_cinema                 id del cinema
--      p_nome_cinema               nome del cinema
--      p_id_tipo_cinema            id del tipo cinema
--      p_id_comune                 id del comune
--      p_flg_virtuale              flag che indica lo stato del cinema
--      p_flg_annullato             flag che indica la validita del cinema
--
-- OUTPUT: 
--   p_esito
--    n  numero di record modificati *DEPRECATO*
--   -1  update non eseguito: i parametri per la Delete non sono coerenti
--    se n > 100, p_esito contiene 100 + numero di sale modificate *DEPRECATO*
--    4   - Cinema invalidato; Data fine validita del cinema coincidente con la fine del contratto
--    5   - Cinema invalidato; Effettuata risoluzione del contratto, data fine validita del 
--          cinema minore della fine del contratto
--    6   - Cinema rivalidato, contratto riaperto
--    7   - Cinema rivalidato, ma contratto non chiuso
--    -2  - Data fine validita' non coerente (maggiore della data di chiusura del contratto)
--    -3  - Nessun contratto di riferimento per quella data di fine validita'
--    -4  - Esiste gia' un contratto e si sta cercando di modificare la data di inizio validita'
--
-- REALIZZATORE: Antonio Colucci, Teoresi srl, Giugno 2009
--
--  MODIFICHE:
--              Antonio Colucci 22/09/2009    Gestione colonna INDIRIZZO - LOCALE
--              Tommaso D'Anna  26/04/2011    Gestione della data di fine validita
--              Tommaso D'Anna  07/07/2011    Gestione della data di inizio validita
--              Tommaso D'Anna  14/07/2011    Rimozione FLG_ATTIVO
-------------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_CINEMA( p_id_cinema               CD_CINEMA.ID_CINEMA%TYPE,
                              p_nome_cinema             CD_CINEMA.NOME_CINEMA%TYPE,
                              p_id_comune               CD_CINEMA.ID_COMUNE%TYPE,
                              p_flg_pubb_locale         CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                              p_flg_concessione         CD_CINEMA.FLG_CONCESSIONE_PUBB_LOCALE%TYPE,
                              p_indirizzo               CD_CINEMA.INDIRIZZO%TYPE,
                              p_cap                     CD_CINEMA.CAP%TYPE,
                              p_id_tipo_cinema          CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                              p_flg_virtuale            CD_CINEMA.FLG_VIRTUALE%TYPE,
                              p_flg_annullato           CD_CINEMA.FLG_ANNULLATO%TYPE,
                              --p_flg_attivo              CD_CINEMA.FLG_ATTIVO%TYPE,
                              p_recapito                CD_CINEMA.RECAPITO_POSTA%TYPE,
                              p_data_inizio_validita    CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE,
                              p_data_fine_validita      CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                              p_esito					OUT NUMBER)
IS
    BEGIN
        SAVEPOINT SP_PR_MODIFICA_CINEMA;
        
        p_esito := 1;    

        IF (p_data_fine_validita IS NOT NULL ) THEN
            IF ( p_data_fine_validita < p_data_inizio_validita ) THEN
                p_esito := -5;
            END IF;
        END IF;
        
        IF ( p_esito > 0 )THEN
            UPDATE CD_CINEMA
            SET
               NOME_CINEMA = (nvl(p_nome_cinema,NOME_CINEMA)),
               ID_COMUNE = (nvl(p_id_comune,ID_COMUNE)),
               FLG_VENDITA_PUBB_LOCALE = (nvl(p_flg_pubb_locale,FLG_VENDITA_PUBB_LOCALE)),
               FLG_CONCESSIONE_PUBB_LOCALE = (nvl(p_flg_concessione,FLG_CONCESSIONE_PUBB_LOCALE)),
               INDIRIZZO = (nvl(p_indirizzo,INDIRIZZO)),
               CAP = (nvl(p_cap,CAP)),
               ID_TIPO_CINEMA = (nvl(p_id_tipo_cinema,ID_TIPO_CINEMA)),
               FLG_VIRTUALE = (nvl(p_flg_virtuale,FLG_VIRTUALE)),
               FLG_ANNULLATO = (nvl(p_flg_annullato,FLG_ANNULLATO)),
               --FLG_ATTIVO = (nvl(p_flg_attivo,FLG_ATTIVO)),
               RECAPITO_POSTA = (nvl(p_recapito,''))
            WHERE 
                ID_CINEMA = p_id_cinema;
            
            p_esito := SQL%ROWCOUNT;
        
            IF p_esito > 0 THEN
                PR_INIZIO_VALIDITA_CINEMA( p_id_cinema, p_data_inizio_validita, p_esito );   
            END IF;        
        
            IF p_esito > 0 THEN
                PR_FINE_VALIDITA_CINEMA( p_id_cinema, p_data_fine_validita, p_esito );                  
            END IF;
        
            IF ( p_esito < 0 AND p_esito != -2 AND p_esito != -3) THEN
                -- -3 e' quando non c'e' un contratto per quella data
                -- -4 quando la data di fine validita' e' superiore alla data fine del contratto 
                --    (impossibile, almeno in teoria... :D)
                -- In questi due casi le modifiche su cinema e sala devono permanere, quindi 
                -- anche se c'e' stato un "errore" non effettuo la rollback
                ROLLBACK TO SP_PR_MODIFICA_CINEMA;
            END IF; 
        END IF;
        --
        --INCOMPLETA MANCA GESTIONE DELLA MODIFICA DEL DIRETTORE DI SALA
        --
      EXCEPTION
              WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Procedura PR_MODIFICA_CINEMA: Update non eseguita, verificare la coerenza dei parametri' || SQLERRM );
            ROLLBACK TO SP_PR_MODIFICA_CINEMA;
    END;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_REGIONE
-- DESCRIZIONE:  la funzione si occupa di estrarre le regioni
--               che rispondono ai criteri di ricerca
--
-- INPUT:
--      p_id_area_geografica        id dell'area geografica
--      p_id_area_nielsen           id dell'area nielsen
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_REGIONE(p_id_area_geografica  CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                            p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE
                               )RETURN C_REGIONE
IS
   c_regione_return C_REGIONE;
BEGIN
   OPEN c_regione_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR
        SELECT  REGIONE.ID_REGIONE, REGIONE.NOME_REGIONE
        FROM    CD_REGIONE REGIONE, CD_AREA_GEOGRAFICA AREA_GEOGRAFICA,
                CD_AREA_NIELSEN AREA_NIELSEN, CD_NIELSEN_REGIONE NIELSEN_REGIONE
        WHERE   REGIONE.ID_AREA_GEOGRAFICA      =       AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA
        AND     REGIONE.ID_REGIONE              =       NIELSEN_REGIONE.ID_REGIONE
        AND     AREA_NIELSEN.ID_AREA_NIELSEN    =       NIELSEN_REGIONE.ID_AREA_NIELSEN
        AND (p_id_area_geografica IS NULL OR REGIONE.ID_AREA_GEOGRAFICA = p_id_area_geografica)
        AND (p_id_area_nielsen IS NULL OR AREA_NIELSEN.ID_AREA_NIELSEN = p_id_area_nielsen)
        ORDER BY REGIONE.NOME_REGIONE;
RETURN c_regione_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_REGIONE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_RICERCA_REGIONE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_AREA_NIELSEN
-- DESCRIZIONE:  la funzione si occupa di estrarre le aree nielsen
--               che rispondono ai criteri di ricerca
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_AREA_NIELSEN RETURN C_AREA_NIELSEN
IS
   c_area_nielsen_return C_AREA_NIELSEN;
BEGIN
   OPEN c_area_nielsen_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR
        SELECT  ID_AREA_NIELSEN, DESC_AREA
        FROM    CD_AREA_NIELSEN;
RETURN c_area_nielsen_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_AREA_NIELSEN: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI ');
END FU_RICERCA_AREA_NIELSEN;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_AREA_GEOGRAFICA
-- DESCRIZIONE:  la funzione si occupa di estrarre le aree geografiche
--               che rispondono ai criteri di ricerca
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_AREA_GEOGRAFICA RETURN C_AREA_GEOGRAFICA
IS
   c_area_geografica_return C_AREA_GEOGRAFICA;
BEGIN
   OPEN c_area_geografica_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR
        SELECT  ID_AREA_GEOGRAFICA, POSIZIONE
        FROM    CD_AREA_GEOGRAFICA
        WHERE   ID_AREA_GEOGRAFICA > -1;
RETURN c_area_geografica_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_AREA_GEOGRAFICA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_RICERCA_AREA_GEOGRAFICA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_COMUNE
-- DESCRIZIONE:  la funzione si occupa di estrarre i comuni
--               che rispondono ai criteri di ricerca
--
-- INPUT:
--      p_id_regione                id della regione
--      p_id_area_geografica        id dell'area geografica
--      p_id_area_nielsen           id dell'area nielsen
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_COMUNE( p_id_regione          CD_REGIONE.ID_REGIONE%TYPE,
                            p_id_area_geografica  CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                            p_id_area_nielsen     CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE
                               )RETURN C_COMUNE
IS
   c_comune_return C_COMUNE;
BEGIN
   OPEN c_comune_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR
        SELECT  COMUNE.ID_COMUNE, COMUNE.COMUNE
        FROM    CD_COMUNE COMUNE, CD_AREA_GEOGRAFICA AREA_GEOGRAFICA, CD_REGIONE REGIONE,
                CD_AREA_NIELSEN AREA_NIELSEN, CD_NIELSEN_REGIONE NIELSEN_REGIONE,
                CD_PROVINCIA PROVINCIA
        WHERE   REGIONE.ID_AREA_GEOGRAFICA     =       AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA
        AND     REGIONE.ID_REGIONE             =       NIELSEN_REGIONE.ID_REGIONE
        AND     AREA_NIELSEN.ID_AREA_NIELSEN   =       NIELSEN_REGIONE.ID_AREA_NIELSEN
        AND     COMUNE.ID_PROVINCIA            =       PROVINCIA.ID_PROVINCIA
        AND     PROVINCIA.ID_REGIONE           =       REGIONE.ID_REGIONE
        AND (p_id_area_geografica IS NULL OR REGIONE.ID_AREA_GEOGRAFICA = p_id_area_geografica)
        AND (p_id_regione IS NULL OR REGIONE.ID_REGIONE = p_id_regione)
        AND (p_id_area_nielsen IS NULL OR AREA_NIELSEN.ID_AREA_NIELSEN = p_id_area_nielsen)
        ORDER BY COMUNE.COMUNE;
RETURN c_comune_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_COMUNE: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_RICERCA_COMUNE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_TIPO_CINEMA
-- DESCRIZIONE:  la funzione si occupa di estrarre i tipi cinema
--               che rispondono ai criteri di ricerca
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE     Antonio Colucci, Teoresi srl, 6 Settembre 2010
--                  aggiunto filtro sul flg_annullato
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_TIPO_CINEMA RETURN C_TIPO_CINEMA
IS
   c_tipo_cinema_return C_TIPO_CINEMA;
BEGIN
   OPEN c_tipo_cinema_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR
        SELECT  ID_TIPO_CINEMA, DESC_TIPO_CINEMA
        FROM    CD_TIPO_CINEMA
        WHERE   ID_TIPO_CINEMA > -1
        and     flg_annullato = 'N';
RETURN c_tipo_cinema_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_TIPO_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI');
END FU_RICERCA_TIPO_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_DIRETTORE_COMPLESSO
-- DESCRIZIONE:  la funzione si occupa di estrarre i direttori di complesso
--               che rispondono ai criteri di ricerca
--
-- OUTPUT: cursore che contiene i records
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_DIRETTORE_COMPLESSO RETURN C_DIRETTORE
IS
   c_direttore_complesso_return C_DIRETTORE;
BEGIN
   OPEN c_direttore_complesso_return  -- apre il cursore che conterra i tipi cinema da selezionare
     FOR
        SELECT  ID_DIRETTORE, NOME, COGNOME,
                TELEFONO, E_MAIL
        FROM    CD_DIRETTORE;
RETURN c_direttore_complesso_return;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_RICERCA_DIRETTORE_COMPLESSO: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI ');
END FU_RICERCA_DIRETTORE_COMPLESSO;
-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_CINEMA
-- DESCRIZIONE:  la funzione si occupa di stampare le variabili di package
--
-- INPUT:
--      p_nome_cinema               nome del cinema
--      p_id_tipo_cinema            id del tipo cinema
--      p_id_comune                 id del comune
--      p_flag_virtuale             flag che indica lo stato del cinema
--
-- OUTPUT: varchar che contiene i paramtetri
--
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Giugno 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_CINEMA (   p_nome_cinema     CD_CINEMA.NOME_CINEMA%TYPE,
                              p_id_tipo_cinema  CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                              p_id_comune       CD_CINEMA.ID_COMUNE%TYPE,
                              p_flag_virtuale   CD_CINEMA.FLG_VIRTUALE%TYPE) RETURN VARCHAR2
IS
BEGIN
  IF v_stampa_cinema = 'ON'
  THEN
  RETURN 'NOME_CINEMA: '          || p_nome_cinema           || ', ' ||
            'ID_TIPO_CINEMA: '          || p_id_tipo_cinema            || ', ' ||
            'ID_COMUNE: '|| p_id_comune    || ', ' ||
            'FLG_VIRTUALE: ' || p_flag_virtuale;
END IF;
END  FU_STAMPA_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_CINEMA
-- INPUT:  ID del cinema di cui si vuole il nome
-- OUTPUT:  il nome del cinema
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_CINEMA(p_id_cinema   IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN CD_CINEMA.NOME_CINEMA%TYPE
IS
    v_return_value CD_CINEMA.NOME_CINEMA%TYPE:='--';
BEGIN
    IF (p_id_cinema IS NOT NULL) THEN
        SELECT CD_CINEMA.NOME_CINEMA
        INTO v_return_value
        FROM CD_CINEMA
        WHERE CD_CINEMA.ID_CINEMA=p_id_cinema;
    END IF;
    RETURN v_return_value;
EXCEPTION
        WHEN NO_DATA_FOUND THEN
		    RETURN '--';
		WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Function FU_DAMMI_NOME_CINEMA: Impossibile valutare la richiesta');
END  FU_DAMMI_NOME_CINEMA;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_NOME_CINEMA_AS
-- INPUT:  ID della Sala o dell'atrio ed un flag che indica se e' un atrio o una sala
--                                          1 atrio 2 (ovvero <>2) sala
-- OUTPUT:  il nome del cinema
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_NOME_CINEMA_AS(p_id_as    IN CD_ATRIO.ID_ATRIO%TYPE,
                                 p_flag_as  IN INTEGER)
            RETURN VARCHAR2
IS
    v_return_value CD_CINEMA.NOME_CINEMA%TYPE:='--';
	v_temp_1 INTEGER;
BEGIN
    IF (p_id_as IS NOT NULL) THEN
	    IF(p_flag_as =1)THEN
		    SELECT CD_ATRIO.ID_CINEMA
            INTO v_temp_1
            FROM CD_ATRIO
            WHERE CD_ATRIO.ID_ATRIO=p_id_as;
		ELSE
	        SELECT CD_SALA.ID_CINEMA
            INTO v_temp_1
            FROM CD_SALA
            WHERE CD_SALA.ID_SALA=p_id_as;
		END IF;
        v_return_value:= FU_DAMMI_NOME_CINEMA(v_temp_1);
    END IF;
    RETURN v_return_value;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Function FU_DAMMI_NOME_CINEMA: Impossibile valutare la richiesta');
		RETURN -1;
END  FU_DAMMI_NOME_CINEMA_AS;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_STATO_CINEMA
-- INPUT:  ID del Cinema del quale si vuole lo stato
-- OUTPUT:  0   il cinema NON appartiene a nessun circuito/lisitno
--          1   il cinema appartiene a qualche circuito/lisitno ma NON e' in un prodotto vendita
--          2   il cinema appartiene a qualche circuito/lisitno, e' in un prodotto vendita,
--              ma NON e' in un prodotto acquistato
--          3   il cinema appartiene a qualche circuito/lisitno e' in un prodotto vendita,
--              ed e' in un prodotto acquistato
--          -10 il cinema non esiste
--          -1  si e' verificato un errore
--
-- REALIZZATORE  Francesco Abbundo, Teoresi srl, Luglio 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_STATO_CINEMA (p_id_cinema   IN CD_CINEMA.ID_CINEMA%TYPE)
            RETURN INTEGER
IS
    v_return_value  INTEGER;
	v_stato         INTEGER;
	v_id_listino    INTEGER;
	v_id_circuito   INTEGER;
BEGIN
    v_return_value:=-10;
    IF(p_id_cinema>0)THEN
        v_id_listino:=-10;
  		v_id_circuito:=-10;
  		v_return_value:=-10; --valore di comodo per la ricerca del max
      	v_stato:=-10;
        FOR L1 in (select DISTINCT CD_LISTINO.ID_LISTINO FROM CD_LISTINO) LOOP
            FOR C1 in (select DISTINCT CD_CIRCUITO.ID_CIRCUITO FROM CD_CIRCUITO) LOOP
			    v_stato:=PA_CD_LISTINO.FU_CINEMA_IN_CIRCUITO_LISTINO(L1.ID_LISTINO, C1.ID_CIRCUITO, p_id_cinema);
                IF(v_stato>v_return_value)THEN
			        v_return_value:=v_stato;
				    v_id_listino:=L1.ID_LISTINO;
                    v_id_circuito:=C1.ID_CIRCUITO;
			    END IF;
	            EXIT WHEN(v_return_value=3);
            END LOOP;
		EXIT WHEN(v_return_value=3);
	    END LOOP;
    END IF;
	RETURN v_return_value;
EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Function FU_DAMMI_NOME_CINEMA: Impossibile valutare la richiesta');
		v_return_value:=-1;
		RETURN v_return_value;
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CINEMA_VENDUTO
--
--  La funzione restituisce il numero di comunicati associati al cinema
--
-- INPUT:  ID del cinema
-- OUTPUT:  n numero dei comunicati associati ai cinema
--          -1 si e' verificato un errore
--
-- REALIZZATORE  Roberto Barbaro, Teoresi srl, Ottobre 2009
--
-- MODIFICHE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CINEMA_VENDUTO(p_id_cinema  IN CD_CINEMA.ID_CINEMA%TYPE)
                             RETURN INTEGER
IS
    v_return_value_cinema           INTEGER:=0;
    v_return_value_atrio            INTEGER:=0;
    v_return_value_sala             INTEGER:=0;
    v_return_value_schermo_sala     INTEGER:=0;
    v_return_value_schermo_atrio    INTEGER:=0;
    v_return_value                  INTEGER:=0;

BEGIN

    -- qui controlla se ci sono circuiti cinema venduti
    FOR CIRC_CIN IN(
                    SELECT DISTINCT(ID_CIRCUITO) FROM CD_CIRCUITO_CINEMA
                    WHERE ID_CINEMA = p_id_cinema
                    )
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_cinema := PA_CD_CIRCUITO.FU_CIRCUITO_VENDUTO(CIRC_CIN.ID_CIRCUITO);
            v_return_value := v_return_value + v_return_value_cinema + v_return_value_atrio + v_return_value_sala + v_return_value_schermo_sala + v_return_value_schermo_atrio;
        END LOOP;

    -- qui controlla se ci sono circuiti atrii venduti
    FOR CIRC_ATRIO IN(
                    SELECT DISTINCT(ID_CIRCUITO) FROM CD_CIRCUITO_ATRIO
                    WHERE ID_ATRIO IN
                        (SELECT ID_ATRIO FROM CD_ATRIO
                         WHERE ID_CINEMA = p_id_cinema))
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_atrio := PA_CD_CIRCUITO.FU_CIRCUITO_VENDUTO(CIRC_ATRIO.ID_CIRCUITO);
            v_return_value := v_return_value + v_return_value_cinema + v_return_value_atrio + v_return_value_sala + v_return_value_schermo_sala + v_return_value_schermo_atrio;
        END LOOP;

     -- qui controlla se ci sono circuiti sala venduti
     FOR CIRC_SALA IN(
                    SELECT DISTINCT(ID_CIRCUITO) FROM CD_CIRCUITO_SALA
                    WHERE ID_SALA IN
                        (SELECT ID_SALA FROM CD_SALA
                         WHERE ID_CINEMA = p_id_cinema))
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_sala := PA_CD_CIRCUITO.FU_CIRCUITO_VENDUTO(CIRC_SALA.ID_CIRCUITO);
            v_return_value := v_return_value + v_return_value_cinema + v_return_value_atrio + v_return_value_sala + v_return_value_schermo_sala + v_return_value_schermo_atrio;
        END LOOP;

    -- qui controlla se ci sono circuiti schermo di sala venduti
    FOR CIRC_PROIEZIONE_SALA IN(
                    SELECT DISTINCT(ID_PROIEZIONE) FROM CD_PROIEZIONE
                    WHERE ID_SCHERMO IN
                        (SELECT ID_SCHERMO FROM CD_SCHERMO
                         WHERE ID_SALA IN
                            (SELECT ID_SALA FROM CD_SALA
                             WHERE ID_CINEMA = p_id_cinema)))
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_schermo_sala := PA_CD_PROIEZIONE.FU_PROIEZIONE_VENDUTA(CIRC_PROIEZIONE_SALA.ID_PROIEZIONE);
            v_return_value := v_return_value + v_return_value_cinema + v_return_value_atrio + v_return_value_sala + v_return_value_schermo_sala + v_return_value_schermo_atrio;
        END LOOP;

    -- qui controlla se ci sono circuiti schermo di atrio venduti
    FOR CIRC_PROIEZIONE_ATRIO IN(
                    SELECT DISTINCT(ID_PROIEZIONE) FROM CD_PROIEZIONE
                    WHERE ID_SCHERMO IN
                        (SELECT ID_SCHERMO FROM CD_SCHERMO
                         WHERE ID_ATRIO IN
                            (SELECT ID_ATRIO FROM CD_ATRIO
                             WHERE ID_CINEMA = p_id_cinema)))
        LOOP
            IF(v_return_value > 0)THEN
                exit;
            END IF;
            v_return_value_schermo_atrio := PA_CD_PROIEZIONE.FU_PROIEZIONE_VENDUTA(CIRC_PROIEZIONE_ATRIO.ID_PROIEZIONE);
            v_return_value := v_return_value + v_return_value_cinema + v_return_value_atrio + v_return_value_sala + v_return_value_schermo_sala + v_return_value_schermo_atrio;
        END LOOP;

    RETURN v_return_value;

    EXCEPTION
		WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Function FU_CINEMA_VENDUTO: Impossibile valutare la richiesta '||sqlerrm);
			v_return_value:=-1;
		    RETURN v_return_value;
END FU_CINEMA_VENDUTO;

FUNCTION FU_GET_NOME_CINEMA(P_ID_CINEMA CD_CINEMA.ID_CINEMA%TYPE,P_DATA DATE default sysdate) RETURN  CD_CINEMA.NOME_CINEMA%TYPE IS
V_NOME_CINEMA CD_CINEMA.NOME_CINEMA%TYPE;
/******************************************************************************
   NAME:       FU_GET_NOME_CINEMA
   PURPOSE:    Restituisce il nome del cinema alla data indicata in input.
               La funzione e necessaria per i cimena che variano il nome 
               ad una certa data.   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        21/12/2010   Mauro Viel Altran Italia   1. Created this function.

   NOTES:
*/
BEGIN
   SELECT NC.NOME_CINEMA 
   INTO   V_NOME_CINEMA
   FROM   CD_CINEMA CI, CD_NOME_CINEMA NC
   WHERE  CI.ID_CINEMA = P_ID_CINEMA
   AND    CI.ID_CINEMA = NC.ID_CINEMA 
   AND    NC.DATA_INIZIO  <= P_DATA
   AND    nvl(NC.DATA_FINE,P_DATA)  >= P_DATA;
   RETURN V_NOME_CINEMA;
   EXCEPTION
     WHEN OTHERS THEN
       RAISE;
END FU_GET_NOME_CINEMA;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STORIA_NOME_CINEMA
--
-- INPUT:  ID del cinema del quale si vuole lo storico dei nomi
--
-- OUTPUT:  lista di nomi con date inizio/fine
--
-- REALIZZATORE  
--          Tommaso D'Anna, Teoresi srl, 22 Dicembre 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STORIA_NOME_CINEMA( p_id_cinema   CD_CINEMA.ID_CINEMA%TYPE )
            RETURN C_STORIA_NOME_CINEMA
IS
   V_STORIA_NOME_CINEMA C_STORIA_NOME_CINEMA;
BEGIN
    OPEN V_STORIA_NOME_CINEMA
        FOR
            SELECT 
                ID_NOME_CINEMA,
                ID_CINEMA,
                NOME_CINEMA,
                DATA_INIZIO,
                DATA_FINE
            FROM 
                CD_NOME_CINEMA
            WHERE
                ID_CINEMA = p_id_cinema
            ORDER BY DATA_INIZIO DESC;
    RETURN V_STORIA_NOME_CINEMA;
EXCEPTION
		WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20047, 'ERRORE IN FUNCTION FU_STORIA_NOME_CINEMA');
END FU_STORIA_NOME_CINEMA;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_NUOVO_NOME_CINEMA
--
-- INPUT:   p_id_cinema         ID del cinema del quale si sta aggiungendo il nuovo nome
--          p_nome_cinema       Il nuovo nome del cinema
--          p_data_inizio_val   La data dal quale il cinema cambia nome
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--
-- REALIZZATORE  
--                  Tommaso D'Anna, Teoresi srl, 23 Dicembre 2010
-- MODIFICHE        
--                  Tommaso D'Anna, Teoresi srl, 7 Luglio 2011
--                  - Inserita gestione della data di inizio validita
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_NUOVO_NOME_CINEMA( p_id_cinema         CD_NOME_CINEMA.ID_CINEMA%TYPE,
                                p_nome_cinema       CD_NOME_CINEMA.NOME_CINEMA%TYPE,
                                p_data_inizio_val   CD_NOME_CINEMA.DATA_INIZIO%TYPE,
                                p_esito             OUT NUMBER
                              )
IS
v_data_inizio_val   CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE;
BEGIN
    p_esito 	:= 1;
    SAVEPOINT SP_PR_NUOVO_NOME_CINEMA;
    
    SELECT trunc(DATA_INIZIO_VALIDITA)
        INTO v_data_inizio_val
        FROM CD_CINEMA
        WHERE ID_CINEMA = p_id_cinema;
    
        IF p_data_inizio_val >= v_data_inizio_val THEN
        -- EFFETTUA L'UPDATE DEL VECCHIO NOME
        UPDATE CD_NOME_CINEMA
            SET
                DATA_FINE   = trunc( to_date ( p_data_inizio_val ) - 1 ),
                UTEMOD      = user,
                DATAMOD     = FU_DATA_ORA           
            WHERE   ID_CINEMA = p_id_cinema
            AND     DATA_FINE IS NULL;
        UPDATE CD_CINEMA
            SET
                NOME_CINEMA = p_nome_cinema,
                UTEMOD      = user,
                DATAMOD     = FU_DATA_ORA           
            WHERE   ID_CINEMA = p_id_cinema;      
        -- INSERISCE IL NUOVO NOME
        INSERT INTO CD_NOME_CINEMA
    	     (
                ID_CINEMA,
                NOME_CINEMA,
                DATA_INIZIO,
                DATA_FINE,
                UTEMOD,
                DATAMOD
    	     )
        VALUES
    	     (
                p_id_cinema,
                p_nome_cinema,
                nvl( p_data_inizio_val, trunc(sysdate)),
                null,
                user,
                FU_DATA_ORA
    		 );
        --
        p_esito := SQL%ROWCOUNT;
    ELSE
        p_esito := -1;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'Procedura PR_NUOVO_NOME_CINEMA: Update non eseguita, verificare la coerenza dei parametri');
        p_esito := -1;
        ROLLBACK TO SP_PR_NUOVO_NOME_CINEMA;
END;

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INIZIO_VALIDITA_CINEMA
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_inizio_val   La data di inizio validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--          -4   - Impossibile modificare; esiste un contratto e si sta cercando di modificare 
--                  la data di validita'!
--          -9   - Data inizio validita' null
--          -1   - Si e' verificato un errore
--           1   - Modifica effettuata correttamente
--
-- REALIZZATORE  
--                  Tommaso D'Anna, Teoresi srl, 7 Luglio 2011
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INIZIO_VALIDITA_CINEMA(    p_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
                                        p_data_inizio_val   CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE,
                                        p_esito             OUT NUMBER)
IS
v_num_contratti NUMBER;
v_data_validita CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE;
v_data_old      DATE;
v_data_new      DATE;
BEGIN
    p_esito := 1;
    SAVEPOINT SP_PR_INIZIO_VALIDITA_CINEMA;
    
    IF p_data_inizio_val IS NOT NULL THEN
        SELECT COUNT(1)
        INTO v_num_contratti
        FROM CD_CINEMA_CONTRATTO
        WHERE ID_CINEMA = p_id_cinema;
    
        IF v_num_contratti > 0 THEN
            -- Esiste almeno contratto
            SELECT DATA_INIZIO_VALIDITA
            INTO v_data_validita
            FROM CD_CINEMA
            WHERE ID_CINEMA = p_id_cinema;
        
            v_data_old := nvl( v_data_validita,     to_date('14/05/1984','DD/MM/YYYY'));
            v_data_new := nvl( p_data_inizio_val,   to_date('14/05/1984','DD/MM/YYYY'));        
            
            IF v_data_new <> v_data_old THEN
                -- Esiste un contratto e sto cercando di modificare la data di validita'!
                p_esito := -4;
            END IF;
        END IF;
    
        IF p_esito > 0 THEN
            -- Se sono qui sono sicuro di poter andare avanti...
            -- Non esiste alcun contratto per questo cinema o non sto modificando la data... 
    
            -- SPREADING SULLE SALE
            -- Modifico TUTTE QUELLE CON DATA MINORE DELLA NUOVA...
            UPDATE CD_SALA
            SET
               DATA_INIZIO_VALIDITA = trunc(p_data_inizio_val)
            WHERE ID_CINEMA = p_id_cinema
            AND   DATA_INIZIO_VALIDITA <= trunc(p_data_inizio_val);
         
            --UPDATE DEL CINEMA
            UPDATE CD_CINEMA
            SET
               DATA_INIZIO_VALIDITA = trunc(p_data_inizio_val)
            WHERE ID_CINEMA = p_id_cinema;                              
        END IF;    
    ELSE
        p_esito := -9;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'Procedura PR_INIZIO_VALIDITA_CINEMA: Update non eseguita, verificare la coerenza dei parametri' || SQLERRM);
        p_esito := -1;
        ROLLBACK TO SP_PR_INIZIO_VALIDITA_CINEMA;
END;                                        

--- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_FINE_VALIDITA_CINEMA
--
-- INPUT:   p_id_cinema         ID del cinema di riferimento
--          p_data_fine_val     La data di fine validita
--
-- OUTPUT:  p_esito             Variabile contenente l'esito dell'operazione
--          4   - Cinema invalidato; Data fine validita del cinema coincidente con la fine del contratto
--          5   - Cinema invalidato; Effettuata risoluzione del contratto, data fine validita del 
--                  cinema minore della fine del contratto
--          6   - Cinema rivalidato, contratto riaperto
--          7   - Cinema rivalidato, ma contratto non chiuso
--          1   - Cinema praticamente non modificato
--
-- REALIZZATORE     
--                  Tommaso D'Anna, Teoresi srl, 29 Aprile 2011
-- MODIFICHE        
--                  Tommaso D'Anna, Teoresi srl, 7 Luglio 2011
--                  - Inserita gestione della data di inizio validita
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_FINE_VALIDITA_CINEMA(  p_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
                                    p_data_fine_val     CD_CINEMA.DATA_FINE_VALIDITA%TYPE,
                                    p_esito             OUT NUMBER)
IS
v_data_validita     CD_CINEMA.DATA_FINE_VALIDITA%TYPE;
v_data_inizio_val   CD_CINEMA.DATA_INIZIO_VALIDITA%TYPE;
v_data_old      DATE;
v_data_new      DATE;
BEGIN
    SAVEPOINT SP_PR_FINE_VALIDITA_CINEMA;
    
    SELECT trunc(DATA_INIZIO_VALIDITA)
    INTO v_data_inizio_val
    FROM CD_CINEMA
    WHERE ID_CINEMA = p_id_cinema;
     
    IF ( ( p_data_fine_val IS NULL ) OR ( p_data_fine_val >= v_data_inizio_val ) ) THEN
        -- SPREADING SULLE SALE
        UPDATE CD_SALA
        SET
           DATA_FINE_VALIDITA = trunc(p_data_fine_val)
        WHERE ID_CINEMA = p_id_cinema
        AND  (   
                DATA_FINE_VALIDITA = (
                        SELECT 
                            DATA_FINE_VALIDITA
                        FROM 
                            CD_CINEMA
                        WHERE ID_CINEMA = p_id_cinema
                    )
                OR DATA_FINE_VALIDITA IS NULL
             );        
        
        SELECT DATA_FINE_VALIDITA
        INTO v_data_validita
        FROM CD_CINEMA
        WHERE ID_CINEMA = p_id_cinema;
       
        v_data_old := nvl( v_data_validita, to_date('14/05/1984','DD/MM/YYYY'));
        v_data_new := nvl( p_data_fine_val, to_date('14/05/1984','DD/MM/YYYY'));
    
        IF v_data_new <> v_data_old THEN
            IF p_data_fine_val IS NOT NULL THEN
                --CINEMA INVALIDATO
                --Dunque chiudo il contratto
                PA_CD_ESERCENTE.PR_RISOLUZIONE_CONTRATTO( p_id_cinema, p_data_fine_val, p_esito);     
            ELSE
                --CINEMA RIVALIDATO
                PA_CD_ESERCENTE.PR_ANNULLA_RISOL_CONTR( p_id_cinema, v_data_validita, p_esito);  
            END IF;
           --p_esito popolato dalla procedura
        ELSE
            --CINEMA NON CAMBIA IL SUO VALORE DI VALIDITA
            p_esito := 1;
        END IF;     
    
        --UPDATE DEL CINEMA
        UPDATE CD_CINEMA
        SET
           DATA_FINE_VALIDITA = trunc(p_data_fine_val)
        WHERE ID_CINEMA = p_id_cinema;
    ELSE
        p_esito := -5;
    END IF;   
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20047, 'Procedura PR_FINE_VALIDITA_CINEMA: Update non eseguita, verificare la coerenza dei parametri' || SQLERRM);
        p_esito := -1;
        ROLLBACK TO SP_PR_FINE_VALIDITA_CINEMA;
END;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_INFO_VALIDITA_CINEMA
--
-- INPUT:  ID del cinema del quale si vogliono le informazioni di inizio e fine 
--         validita'
--
-- OUTPUT:  C_STORIA_NOME_CINEMA con date inizio/fine; usa questo CURSOR perche'
--          contiene le stesse informazioni richieste
--
-- REALIZZATORE  Tommaso D'Anna, Teoresi srl, 8 Luglio 2010
-- --------------------------------------------------------------------------------------------
FUNCTION FU_INFO_VALIDITA_CINEMA( p_id_cinema   CD_CINEMA.ID_CINEMA%TYPE )
            RETURN C_STORIA_NOME_CINEMA
IS
   V_STORIA_NOME_CINEMA C_STORIA_NOME_CINEMA;
BEGIN
    OPEN V_STORIA_NOME_CINEMA
        FOR
            SELECT 
                null AS ID_NOME_CINEMA,
                ID_CINEMA,
                NOME_CINEMA,
                trunc(DATA_INIZIO_VALIDITA) AS DATA_INIZIO_VALIDITA,
                trunc(DATA_FINE_VALIDITA) AS DATA_FINE_VALIDITA
            FROM 
                CD_CINEMA
            WHERE
                ID_CINEMA = p_id_cinema;
    RETURN V_STORIA_NOME_CINEMA;
EXCEPTION
		WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20047, 'ERRORE IN FUNCTION FU_INFO_VALIDITA_CINEMA');
END FU_INFO_VALIDITA_CINEMA;

-- --------------------------------------------------------------------------------------------
-- FUNZIONE FU_STAMPA_ELENCO_CINEMA
--
-- INPUT:
--      Campi di ricerca per la stampa:
--      p_nome_cinema
--      p_id_tipo_cinema
--      p_id_comune
--      p_flg_pubb_locale
--      p_id_area_nielsen
--      p_id_area_geografica
--      p_id_regione
--      p_flg_arena
--      p_flg_virtuale
--      p_flg_valido
--
-- OUTPUT:  Cursore C_CINEMA_SALA_STAMPA contenente le informazioni richieste
--
-- REALIZZATORE  
--              Tommaso D'Anna, Teoresi srl, 2 Settembre 2011
-- MODIFICHE
--              Tommaso D'Anna, Teoresi srl, 3 Ottobre 2011
--                  Inserita HINT ALL_ROWS
--              Tommaso D'Anna, Teoresi srl, 24 Novembre 2011
--                  Inserito controllo sulla validita' del cinema
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_ELENCO_CINEMA(
                                    p_nome_cinema          CD_CINEMA.NOME_CINEMA%TYPE,
                                    p_id_tipo_cinema       CD_CINEMA.ID_TIPO_CINEMA%TYPE,
                                    p_id_comune            CD_CINEMA.ID_COMUNE%TYPE,
                                    p_flg_pubb_locale      CD_CINEMA.FLG_VENDITA_PUBB_LOCALE%TYPE,
                                    p_id_area_nielsen      CD_AREA_NIELSEN.ID_AREA_NIELSEN%TYPE,
                                    p_id_area_geografica   CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA%TYPE,
                                    p_id_regione           CD_REGIONE.ID_REGIONE%TYPE,
                                    p_flg_arena            CD_SALA.FLG_ARENA%TYPE,
                                    p_flg_virtuale         CD_CINEMA.FLG_VIRTUALE%TYPE,
                                    p_flg_valido           VARCHAR2)
                                RETURN C_CINEMA_SALA_STAMPA
IS
   C_RETURN C_CINEMA_SALA_STAMPA;
BEGIN
   OPEN C_RETURN
     FOR
        SELECT  /*+ ALL_ROWS*/
            CD_CINEMA.ID_CINEMA, 
            CD_CINEMA.NOME_CINEMA, 
            CD_CINEMA.ID_COMUNE, 
            CD_COMUNE.COMUNE,
            CD_PROVINCIA.ID_PROVINCIA,
            CD_PROVINCIA.PROVINCIA,
            CD_REGIONE.ID_REGIONE,
            CD_REGIONE.NOME_REGIONE,
            CD_CINEMA.ID_TIPO_CINEMA,            
            upper(CD_TIPO_CINEMA.DESC_TIPO_CINEMA)  AS TIPO_CINEMA,
            upper(CD_CINEMA.INDIRIZZO)              AS INDIRIZZO,
            CD_CINEMA.CAP,
            CD_CINEMA.DATA_INIZIO_VALIDITA          AS DATA_INIZIO_VALIDITA_CIN,
            CD_CINEMA.DATA_FINE_VALIDITA            AS DATA_FINE_VALIDITA_CIN,
            CD_AREA_NIELSEN.ID_AREA_NIELSEN,    
            CD_SALA.ID_SALA,          
            CD_SALA.NOME_SALA,            
            CD_SALA.DATA_INIZIO_VALIDITA            AS DATA_INIZIO_VALIDITA_SAL,
            CD_SALA.DATA_FINE_VALIDITA              AS DATA_FINE_VALIDITA_SAL,
            CD_SALA.FLG_ARENA,
            CD_CIRCUITO.ID_CIRCUITO,
            CD_CIRCUITO.NOME_CIRCUITO
        FROM    
            CD_CINEMA,
            (SELECT DISTINCT ID_SALA, ID_CINEMA FROM CD_SALA WHERE FLG_ARENA = 'N') 
                SALA,
            (SELECT DISTINCT ID_SALA, ID_CINEMA FROM CD_SALA WHERE FLG_ARENA = 'S') 
                ARENA,
            CD_ATRIO, 
            CD_COMUNE, 
            CD_TIPO_CINEMA,
            CD_PROVINCIA,
            CD_AREA_GEOGRAFICA, 
            CD_REGIONE,
            CD_AREA_NIELSEN, 
            CD_NIELSEN_REGIONE,
            CD_SALA,
            CD_SCHERMO,
            CD_CIRCUITO_SCHERMO,
            CD_CIRCUITO            
        WHERE  CD_REGIONE.ID_AREA_GEOGRAFICA       = CD_AREA_GEOGRAFICA.ID_AREA_GEOGRAFICA
        AND    CD_REGIONE.ID_REGIONE               = CD_NIELSEN_REGIONE.ID_REGIONE
        AND    CD_AREA_NIELSEN.ID_AREA_NIELSEN     = CD_NIELSEN_REGIONE.ID_AREA_NIELSEN
        AND    CD_PROVINCIA.ID_REGIONE             = CD_REGIONE.ID_REGIONE
        AND    CD_COMUNE.ID_PROVINCIA              = CD_PROVINCIA.ID_PROVINCIA
        AND    SALA.ID_CINEMA(+)                   = CD_CINEMA.ID_CINEMA
        AND    CD_ATRIO.ID_CINEMA(+)               = CD_CINEMA.ID_CINEMA
        AND    CD_CINEMA.ID_COMUNE                 = CD_COMUNE.ID_COMUNE
        AND    CD_CINEMA.ID_TIPO_CINEMA            = CD_TIPO_CINEMA.ID_TIPO_CINEMA
        AND    ARENA.ID_CINEMA(+)                  = CD_CINEMA.ID_CINEMA
        AND    CD_SALA.ID_CINEMA(+)                = CD_CINEMA.ID_CINEMA        
        AND    (p_nome_cinema                      IS NULL OR upper(CD_CINEMA.NOME_CINEMA)         LIKE upper('%'||p_nome_cinema||'%'))
        AND    (p_id_tipo_cinema                   IS NULL OR CD_CINEMA.ID_TIPO_CINEMA             = p_id_tipo_cinema)
        AND    (p_id_comune                        IS NULL OR CD_CINEMA.ID_COMUNE                  = p_id_comune)
        AND    (p_id_area_geografica               IS NULL OR CD_REGIONE.ID_AREA_GEOGRAFICA        = p_id_area_geografica)
        AND    (p_id_regione                       IS NULL OR CD_REGIONE.ID_REGIONE                = p_id_regione)
        AND    (p_id_area_nielsen                  IS NULL OR CD_AREA_NIELSEN.ID_AREA_NIELSEN      = p_id_area_nielsen)
        AND    (p_flg_virtuale                     IS NULL OR CD_CINEMA.FLG_VIRTUALE               = p_flg_virtuale)
        AND    (CD_CINEMA.FLG_ANNULLATO            IS NULL OR CD_CINEMA.FLG_ANNULLATO              = 'N')
        AND    (p_flg_pubb_locale                  IS NULL OR CD_CINEMA.FLG_VENDITA_PUBB_LOCALE    = p_flg_pubb_locale)
        AND    (p_flg_arena                        IS NULL OR CD_SALA.FLG_ARENA                    = p_flg_arena)
        AND    1 = 
               (
                   CASE 
                       WHEN 
                           (    
                               ( p_flg_valido = 'S' ) 
                               AND 
                               (
                                   ( CD_CINEMA.DATA_INIZIO_VALIDITA <= trunc(SYSDATE) )
                                   AND
                                   (
                                       ( CD_CINEMA.DATA_FINE_VALIDITA >= trunc(SYSDATE) )
                                       OR
                                       ( CD_CINEMA.DATA_FINE_VALIDITA IS NULL )
                                   )
                               )
                           )
                           THEN 1 
                       WHEN 
                           (    
                               ( p_flg_valido = 'N' ) 
                               AND 
                               (
                                   ( CD_CINEMA.DATA_INIZIO_VALIDITA > trunc(SYSDATE) )
                                   OR
                                   ( CD_CINEMA.DATA_FINE_VALIDITA < trunc(SYSDATE) )
                               )
                           )
                           THEN 1
                       WHEN 
                           ( p_flg_valido IS NULL ) 
                           THEN 1 
                   END
               )                
        -- Recupero le informazioni sul circuito al quale la sala appartiene
        AND    CD_SCHERMO.ID_SALA                  = CD_SALA.ID_SALA
        AND    CD_SCHERMO.ID_SCHERMO = CD_CIRCUITO_SCHERMO.ID_SCHERMO    
        AND    CD_CIRCUITO_SCHERMO.ID_LISTINO      =   (
                                                            SELECT 
                                                                ID_LISTINO 
                                                            FROM 
                                                                CD_LISTINO 
                                                            WHERE TRUNC(SYSDATE) BETWEEN DATA_INIZIO AND DATA_FINE 
                                                            AND COD_CATEGORIA_PRODOTTO = 'TAB'
                                                        )
        AND    CD_CIRCUITO_SCHERMO.ID_CIRCUITO     = CD_CIRCUITO.ID_CIRCUITO                                                    
        AND    CD_CIRCUITO_SCHERMO.FLG_ANNULLATO   = 'N'                                       
        AND    CD_CIRCUITO.FLG_DEFINITO_A_LISTINO  = 'S'
        AND    CD_CIRCUITO.LIVELLO                 = 1
        GROUP BY 
            CD_CINEMA.ID_CINEMA, 
            CD_CINEMA.NOME_CINEMA, 
            CD_CINEMA.ID_COMUNE, 
            CD_COMUNE.COMUNE,
            CD_PROVINCIA.ID_PROVINCIA,
            CD_PROVINCIA.PROVINCIA,
            CD_REGIONE.ID_REGIONE,
            CD_REGIONE.NOME_REGIONE,
            CD_CINEMA.ID_TIPO_CINEMA,            
            CD_TIPO_CINEMA.DESC_TIPO_CINEMA,
            CD_CINEMA.INDIRIZZO,
            CD_CINEMA.CAP,
            CD_CINEMA.DATA_INIZIO_VALIDITA,
            CD_CINEMA.DATA_FINE_VALIDITA,
            CD_AREA_NIELSEN.ID_AREA_NIELSEN,    
            CD_SALA.ID_SALA,          
            CD_SALA.NOME_SALA,            
            CD_SALA.DATA_INIZIO_VALIDITA,
            CD_SALA.DATA_FINE_VALIDITA,
            CD_SALA.FLG_ARENA,
            CD_CIRCUITO.ID_CIRCUITO,
            CD_CIRCUITO.NOME_CIRCUITO            
        ORDER BY 
            CD_CINEMA.NOME_CINEMA,
            CD_COMUNE.COMUNE,
            CD_SALA.NOME_SALA;
RETURN C_RETURN;
EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20002, 'FUNZIONE FU_STAMPA_ELENCO_CINEMA: SI E VERIFICATO UN ERRORE, CONTROLLARE LA COERENZA DEI PARAMETRI '||FU_STAMPA_CINEMA(p_nome_cinema, p_id_tipo_cinema, p_id_comune, 'N'));
END FU_STAMPA_ELENCO_CINEMA;

END PA_CD_CINEMA; 
/

