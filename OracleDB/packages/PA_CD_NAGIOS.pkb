CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_NAGIOS AS

    ---------------------------------------------------------------------------------------------------
    -- FUNCTION FU_GET_NAGIOS_DIAGNOSI
    --
    -- DESCRIZIONE:  
    --              Funzione che permette di recuperare le informazioni contenute all'interno
    --              della tabella CD_NAGIOS_DIAGNOSI
    --
    -- INPUT:
    --              p_data_inizio               data inizio ricerca
    --              p_data_fine                 data fine ricerca
    --              p_id_cinema                 ID cinema per la ricerca
    --              p_id_sala                   ID sala per la ricerca
    --              p_results_num               numero di risultati richiesti (null avere l'elenco di tutti i risultati)
    --
    --              Per la ricerca ottimale utilizzare soltanto p_id_cinema OPPURE p_id_sala
    -- OUTPUT:
    --              lista di
    --                  R_NAGIOS_DIAGNOSI
    --
    -- REALIZZATORE:
    --              Tommaso D'Anna, Teoresi srl, 19 Settembre 2011
    -- MODIFICHE:
    --              Tommaso D'Anna, Teoresi srl, 28 Settembre 2011
    --                  Modificata la query in modo che se p_id_sala e' valorizzato estragga anche
    --                  le informazioni relative al cinema di appartenenza e se p_id_cinema e' valorizzato
    --                  estragga anche le informazioni relative alle sale
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_DIAGNOSI (
                                        p_data_inizio   CD_NAGIOS_DIAGNOSI.TEMPO%TYPE,
                                        p_data_fine     CD_NAGIOS_DIAGNOSI.TEMPO%TYPE,
                                        p_id_cinema     CD_NAGIOS_DIAGNOSI.ID_CINEMA%TYPE,
                                        p_id_sala       CD_NAGIOS_DIAGNOSI.ID_SALA%TYPE,
                                        p_results_num   NUMBER
                                    )
                                        RETURN C_NAGIOS_DIAGNOSI 
    IS
    C_RETURN C_NAGIOS_DIAGNOSI;
    BEGIN
        OPEN C_RETURN FOR 
            SELECT /*+ ALL_ROWS */
                *
            FROM
                (
                SELECT 
                    CD_NAGIOS_DIAGNOSI.ID_CINEMA,                
                    CD_NAGIOS_DIAGNOSI.ID_SALA,
                    CD_CINEMA.NOME_CINEMA,
                    CD_COMUNE.COMUNE,        
                    CD_SALA.NOME_SALA,
                    CD_NAGIOS_DIAGNOSI.TEMPO,
                    CD_NAGIOS_DIAGNOSI.STATO_12,
                    CD_NAGIOS_DIAGNOSI.STATO_13,
                    CD_NAGIOS_DIAGNOSI.STATO_14,
                    CD_NAGIOS_DIAGNOSI.STATO_15,
                    CD_NAGIOS_DIAGNOSI.STATO_16,
                    CD_NAGIOS_DIAGNOSI.STATO_17,
                    CD_NAGIOS_DIAGNOSI.STATO_18
                FROM 
                    CD_NAGIOS_DIAGNOSI,
                    CD_CINEMA,
                    CD_COMUNE,
                    CD_SALA
                WHERE   CD_NAGIOS_DIAGNOSI.TEMPO        >=  nvl( CAST( p_data_inizio AS TIMESTAMP ), CD_NAGIOS_DIAGNOSI.TEMPO ) 
                AND     CD_NAGIOS_DIAGNOSI.TEMPO        <=  nvl( CAST( p_data_fine AS TIMESTAMP ),   CD_NAGIOS_DIAGNOSI.TEMPO )
                AND     CD_NAGIOS_DIAGNOSI.ID_CINEMA    =   nvl( p_id_cinema,   CD_NAGIOS_DIAGNOSI.ID_CINEMA )
                AND ( 
                        CD_NAGIOS_DIAGNOSI.ID_SALA      =   nvl( p_id_sala,     CD_NAGIOS_DIAGNOSI.ID_SALA )
                        OR  ( 
                            CD_NAGIOS_DIAGNOSI.ID_SALA IS NULL  
                            AND CD_NAGIOS_DIAGNOSI.ID_CINEMA = 
                                (
                                    SELECT 
                                        DISTINCT ID_CINEMA 
                                    FROM 
                                        CD_SALA 
                                    WHERE ID_SALA = p_id_sala
                                    OR ID_CINEMA  = p_id_cinema
                                 )
                             ) 
                     )
                AND     CD_NAGIOS_DIAGNOSI.ID_CINEMA    =   CD_CINEMA.ID_CINEMA
                AND     CD_CINEMA.ID_COMUNE             =   CD_COMUNE.ID_COMUNE
                AND     CD_NAGIOS_DIAGNOSI.ID_SALA      =   CD_SALA.ID_SALA (+) 
                ORDER BY
                    CD_NAGIOS_DIAGNOSI.TEMPO DESC,
                    CD_CINEMA.NOME_CINEMA,
                    CD_COMUNE.COMUNE,
                    CD_SALA.NOME_SALA
                )
            WHERE ROWNUM <= nvl( p_results_num, ROWNUM );                             
        RETURN C_RETURN;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_NAGIOS_DIAGNOSI: SI E VERIFICATO UN ERRORE!');
    END FU_GET_NAGIOS_DIAGNOSI;    
    
                                        
    ---------------------------------------------------------------------------------------------------
    -- FUNCTION FU_GET_NAGIOS_DIAGNOSI_REPORT
    --
    -- DESCRIZIONE:  
    --              Funzione che permette di recuperare le informazioni contenute all'interno
    --              della tabella CD_NAGIOS_DIAGNOSI_REPORT
    --
    -- INPUT:
    --              p_data_inizio               data inizio ricerca
    --              p_data_fine                 data fine ricerca
    --              p_id_cinema                 ID cinema per la ricerca
    --              p_id_sala                   ID sala per la ricerca
    --
    --              Per una ricerca ottimale utilizzare soltanto p_id_cinema OPPURE p_id_sala    
    -- OUTPUT:
    --              lista di
    --                  R_NAGIOS_DIAGNOSI_REPORT
    --
    -- REALIZZATORE:
    --              Tommaso D'Anna, Teoresi srl, 19 Settembre 2011
    -- MODIFICHE:
    --              Tommaso D'Anna, Teoresi srl, 28 Settembre 2011
    --                  Modificata la query in modo che se p_id_sala e' valorizzato estragga anche
    --                  le informazioni relative al cinema di appartenenza e se p_id_cinema e' valorizzato
    --                  estragga anche le informazioni relative alle sale   
    --              Tommaso D'Anna, Teoresi srl, 30 Settembre 2011
    --                  Rimossa la modifica del 28 Settembre unicamente per CD_NAGIOS_DIAGNOSI_REPORT
    --                  Non per le altre query!
    --              Tommaso D'Anna, Teoresi srl, 3 Ottobre 2011
    --                  Inserita la distinct per evitare di ripetere le righe quando il dato e' del
    --                  cinema e non della sala    
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_DIAGNOSI_REPORT  (
                                                p_data_inizio   CD_NAGIOS_DIAGNOSI_REPORT.GIORNO%TYPE,
                                                p_data_fine     CD_NAGIOS_DIAGNOSI_REPORT.GIORNO%TYPE,
                                                p_id_cinema     CD_NAGIOS_DIAGNOSI_REPORT.ID_CINEMA%TYPE,
                                                p_id_sala       CD_NAGIOS_DIAGNOSI_REPORT.ID_SALA%TYPE,
                                                p_results_num   NUMBER
                                            )
                                                RETURN C_NAGIOS_DIAGNOSI_REPORT
    IS
    C_RETURN C_NAGIOS_DIAGNOSI_REPORT;
    BEGIN
        OPEN C_RETURN FOR 
            SELECT /*+ ALL_ROWS */
                *
            FROM (
                SELECT
                    CD_NAGIOS_DIAGNOSI_REPORT.ID_CINEMA,    
                    CD_NAGIOS_DIAGNOSI_REPORT.ID_SALA,
                    CD_NAGIOS_DIAGNOSI_REPORT.NOME_CINEMA,
                    CD_COMUNE.COMUNE,        
                    CD_NAGIOS_DIAGNOSI_REPORT.NOME_SALA,                
                    CD_NAGIOS_DIAGNOSI_REPORT.GIORNO,
                    CD_NAGIOS_DIAGNOSI_REPORT.LAMPADA_PROIETTORE,
                    CD_NAGIOS_DIAGNOSI_REPORT.PROIETTORE,
                    CD_NAGIOS_DIAGNOSI_REPORT.BOX_I_O,
                    CD_NAGIOS_DIAGNOSI_REPORT.PC_PLAYER,
                    CD_NAGIOS_DIAGNOSI_REPORT.PC_SERVER,
                    CD_NAGIOS_DIAGNOSI_REPORT.ALTRO,
                    CD_NAGIOS_DIAGNOSI_REPORT.RETE_FASTWEB 
                FROM
                    CD_NAGIOS_DIAGNOSI_REPORT,
                    CD_CINEMA,
                    CD_COMUNE
                WHERE   CD_NAGIOS_DIAGNOSI_REPORT.GIORNO        >=  nvl( p_data_inizio,    CD_NAGIOS_DIAGNOSI_REPORT.GIORNO ) 
                AND     CD_NAGIOS_DIAGNOSI_REPORT.GIORNO        <=  nvl( p_data_fine,      CD_NAGIOS_DIAGNOSI_REPORT.GIORNO )
                AND     CD_NAGIOS_DIAGNOSI_REPORT.ID_CINEMA     =   nvl( p_id_cinema,      CD_NAGIOS_DIAGNOSI_REPORT.ID_CINEMA )
                AND     CD_NAGIOS_DIAGNOSI_REPORT.ID_SALA       =   nvl( p_id_sala,        CD_NAGIOS_DIAGNOSI_REPORT.ID_SALA )
                AND     CD_NAGIOS_DIAGNOSI_REPORT.ID_CINEMA     =   CD_CINEMA.ID_CINEMA
                AND     CD_CINEMA.ID_COMUNE                     =   CD_COMUNE.ID_COMUNE              
                ORDER BY
                    CD_NAGIOS_DIAGNOSI_REPORT.GIORNO DESC,
                    CD_NAGIOS_DIAGNOSI_REPORT.NOME_CINEMA,
                    CD_NAGIOS_DIAGNOSI_REPORT.NOME_SALA
                )
            WHERE ROWNUM <= nvl( p_results_num, ROWNUM );
        RETURN C_RETURN;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_NAGIOS_DIAGNOSI_REPORT: SI E VERIFICATO UN ERRORE!');
    END FU_GET_NAGIOS_DIAGNOSI_REPORT;                                                 
                                                
    ---------------------------------------------------------------------------------------------------
    -- FUNCTION FU_GET_NAGIOS_SERVIZI
    --
    -- DESCRIZIONE:  
    --              Funzione che permette di recuperare le informazioni contenute all'interno
    --              della tabella CD_NAGIOS_SERVIZI
    --
    -- INPUT:
    --              p_id_servizio               ID del servizio
    --
    -- OUTPUT:
    --              lista di
    --                  R_NAGIOS_DIAGNOSI_SERVIZI
    --
    -- REALIZZATORE:
    --              Tommaso D'Anna, Teoresi srl, 19 Settembre 2011
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_SERVIZI  (
                                        p_id_servizio   CD_NAGIOS_SERVIZI.SERVIZIO_ID%TYPE
                                    )
                                        RETURN C_NAGIOS_SERVIZI
    IS
    C_RETURN C_NAGIOS_SERVIZI;
    BEGIN
        OPEN C_RETURN FOR 
            SELECT
               *
            FROM
                CD_NAGIOS_SERVIZI
            WHERE   CD_NAGIOS_SERVIZI.SERVIZIO_ID = p_id_servizio;
        RETURN C_RETURN;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_NAGIOS_SERVIZI: SI E VERIFICATO UN ERRORE!');
    END FU_GET_NAGIOS_SERVIZI;                                           
    ---------------------------------------------------------------------------------------------------
    -- FUNCTION FU_GET_NAGIOS_STORICO_STATI
    --
    -- DESCRIZIONE:  
    --              Funzione che permette di recuperare le informazioni contenute all'interno
    --              della tabella CD_NAGIOS_STORICO_STATI
    --
    -- INPUT:
    --              p_data_inizio               data inizio ricerca
    --              p_data_fine                 data fine ricerca
    --              p_id_cinema                 ID cinema per la ricerca
    --              p_id_sala                   ID sala per la ricerca
    --              p_results_num               numero di risultati richiesti (null avere l'elenco di tutti i risultati)
    --
    --              Per la ricerca ottimale utilizzare soltanto p_id_cinema OPPURE p_id_sala    
    -- OUTPUT:
    --              lista di
    --                  R_NAGIOS_DIAGNOSI_STORICO_STATI
    --
    -- REALIZZATORE:
    --              Tommaso D'Anna, Teoresi srl, 19 Settembre 2011
    -- MODIFICHE:
    --              Tommaso D'Anna, Teoresi srl, 28 Settembre 2011
    --                  Modificata la query in modo che se p_id_sala e' valorizzato estragga anche
    --                  le informazioni relative al cinema di appartenenza e se p_id_cinema e' valorizzato
    --                  estragga anche le informazioni relative alle sale
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_STORICO_STATI    (
                                                p_data_inizio   CD_NAGIOS_STORICO_STATI.STATO_TEMPO%TYPE,
                                                p_data_fine     CD_NAGIOS_STORICO_STATI.STATO_TEMPO%TYPE,
                                                p_id_cinema     CD_NAGIOS_STORICO_STATI.ID_CINEMA%TYPE,
                                                p_id_sala       CD_NAGIOS_STORICO_STATI.ID_SALA%TYPE,
                                                p_results_num   NUMBER
                                            )
                                                RETURN C_NAGIOS_STORICO_STATI
    IS
    C_RETURN C_NAGIOS_STORICO_STATI;
    BEGIN
        OPEN C_RETURN FOR 
            SELECT /*+ ALL_ROWS */ 
                *
            FROM
                (
                SELECT 
                    CD_NAGIOS_STORICO_STATI.ID_SALA,
                    CD_NAGIOS_STORICO_STATI.ID_CINEMA,
                    CD_CINEMA.NOME_CINEMA,
                    CD_COMUNE.COMUNE,        
                    CD_SALA.NOME_SALA,        
                    CD_NAGIOS_STORICO_STATI.STATO_TEMPO,
                    CD_NAGIOS_STORICO_STATI.STATO_PRECEDENTE,
                    CD_NAGIOS_STORICO_STATI.STATO_CORRENTE,
                    CD_NAGIOS_STORICO_STATI.ID_SERVIZIO,
                    CD_NAGIOS_SERVIZI.DESCRIZIONE_NAGIOS,
                    CD_NAGIOS_SERVIZI.DESCRIZIOE_SIPRA,
                    CD_NAGIOS_SERVIZI.LIMITE_FLIP,                    
                    CD_NAGIOS_STORICO_STATI.HOST,
                    CD_NAGIOS_STORICO_STATI.STATO_DESCRIZIONE
                FROM 
                    CD_NAGIOS_STORICO_STATI,
                    CD_NAGIOS_SERVIZI,
                    CD_CINEMA,
                    CD_COMUNE,
                    CD_SALA
                WHERE   CD_NAGIOS_STORICO_STATI.STATO_TEMPO >=  nvl( CAST( p_data_inizio AS TIMESTAMP ), CD_NAGIOS_STORICO_STATI.STATO_TEMPO ) 
                AND     CD_NAGIOS_STORICO_STATI.STATO_TEMPO <=  nvl( CAST( p_data_fine AS TIMESTAMP ),   CD_NAGIOS_STORICO_STATI.STATO_TEMPO )
                AND     CD_NAGIOS_STORICO_STATI.ID_CINEMA   =   nvl( p_id_cinema,   CD_NAGIOS_STORICO_STATI.ID_CINEMA )
                AND ( 
                        CD_NAGIOS_STORICO_STATI.ID_SALA     =   nvl( p_id_sala,     CD_NAGIOS_STORICO_STATI.ID_SALA )
                        OR  ( 
                            CD_NAGIOS_STORICO_STATI.ID_SALA IS NULL  
                            AND CD_NAGIOS_STORICO_STATI.ID_CINEMA = 
                                (
                                    SELECT 
                                        DISTINCT ID_CINEMA 
                                    FROM 
                                        CD_SALA 
                                    WHERE ID_SALA = p_id_sala
                                    OR ID_CINEMA  = p_id_cinema
                                 )
                             ) 
                     )
                AND     CD_NAGIOS_STORICO_STATI.ID_SERVIZIO = CD_NAGIOS_SERVIZI.SERVIZIO_ID
                AND     CD_NAGIOS_STORICO_STATI.ID_CINEMA   = CD_CINEMA.ID_CINEMA
                AND     CD_CINEMA.ID_COMUNE                 = CD_COMUNE.ID_COMUNE
                AND     CD_NAGIOS_STORICO_STATI.ID_SALA     = CD_SALA.ID_SALA (+) 
                ORDER BY
                    CD_NAGIOS_STORICO_STATI.STATO_TEMPO DESC,
                    CD_CINEMA.NOME_CINEMA,
                    CD_COMUNE.COMUNE,
                    CD_SALA.NOME_SALA
                )
            WHERE ROWNUM <= nvl( p_results_num, ROWNUM ); 
        RETURN C_RETURN;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_NAGIOS_STORICO_STATI: SI E VERIFICATO UN ERRORE!');
    END FU_GET_NAGIOS_STORICO_STATI;                                                
                                            
    ---------------------------------------------------------------------------------------------------
    -- FUNCTION FU_GET_NAGIOS_SYNCH_LOG
    --
    -- DESCRIZIONE:  
    --              Funzione che permette di recuperare le informazioni contenute all'interno
    --              della tabella CD_NAGIOS_SYNCH_LOG
    --
    -- INPUT:
    --              p_data_inizio               data inizio ricerca
    --              p_data_fine                 data fine ricerca
    --              p_flg_esito                 l'esito da ricercare
    --              p_results_num               numero di risultati richiesti (null avere l'elenco di tutti i risultati)
    --
    -- OUTPUT:
    --              lista di
    --                  R_NAGIOS_DIAGNOSI_SYNCH_LOG
    --
    -- REALIZZATORE:
    --              Tommaso D'Anna, Teoresi srl, 19 Settembre 2011
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_SYNCH_LOG    (
                                            p_data_inizio   CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO%TYPE,
                                            p_data_fine     CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO%TYPE,
                                            p_flg_esito     CD_NAGIOS_SYNCH_LOG.FLG_ESITO%TYPE,
                                            p_results_num   NUMBER
                                        )
                                            RETURN C_NAGIOS_SYNCH_LOG
    IS
    C_RETURN C_NAGIOS_SYNCH_LOG;
    BEGIN
        OPEN C_RETURN FOR 
            SELECT
                *
            FROM
                (
                SELECT 
                    CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO,
                    CD_NAGIOS_SYNCH_LOG.FLG_ESITO,
                    CD_NAGIOS_SYNCH_LOG.NOTE,
                    CD_NAGIOS_SYNCH_LOG.STEP_TYPE
                FROM 
                    CD_NAGIOS_SYNCH_LOG
                WHERE   CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO >= nvl( CAST( p_data_inizio AS TIMESTAMP ), CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO ) 
                AND     CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO <= nvl( CAST( p_data_fine AS TIMESTAMP ),   CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO )
                AND     CD_NAGIOS_SYNCH_LOG.FLG_ESITO        =  nvl( p_flg_esito,   CD_NAGIOS_SYNCH_LOG.FLG_ESITO )
                ORDER BY
                    CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO DESC
                )
            WHERE ROWNUM <= nvl( p_results_num, ROWNUM ); 
        RETURN C_RETURN;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20047, 'FUNZIONE FU_GET_NAGIOS_SYNCH_LOG: SI E VERIFICATO UN ERRORE!');
    END FU_GET_NAGIOS_SYNCH_LOG;                                               

END PA_CD_NAGIOS; 
/

