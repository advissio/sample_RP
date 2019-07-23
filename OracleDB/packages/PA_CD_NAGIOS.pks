CREATE OR REPLACE PACKAGE VENCD.PA_CD_NAGIOS AS

    ---------------------------------------------------------------------------------------------------
    -- PACKAGE VENCD.PA_CD_NAGIOS
    --
    -- DESCRIZIONE:  
    --              Package contenente le funzioni necessarie per leggere le tavole contenenti le
    --              informazioni provenienti da Nagios e popolate dall'applicativo DOFWARE.
    --
    -- REALIZZATORE:
    --              Tommaso D'Anna, Teoresi srl, 19 Settembre 2011
    -------------------------------------------------------------------------------------------------

    TYPE R_NAGIOS_DIAGNOSI IS RECORD
    (
        a_id_cinema             CD_NAGIOS_DIAGNOSI.ID_CINEMA%TYPE,     
        a_id_sala               CD_NAGIOS_DIAGNOSI.ID_SALA%TYPE,       
        a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
        a_comune                CD_COMUNE.COMUNE%TYPE,        
        a_nome_sala             CD_SALA.NOME_SALA%TYPE,
        a_tempo                 CD_NAGIOS_DIAGNOSI.TEMPO%TYPE,
        a_stato_12              CD_NAGIOS_DIAGNOSI.STATO_12%TYPE,
        a_stato_13              CD_NAGIOS_DIAGNOSI.STATO_13%TYPE,
        a_stato_14              CD_NAGIOS_DIAGNOSI.STATO_14%TYPE,
        a_stato_15              CD_NAGIOS_DIAGNOSI.STATO_15%TYPE,
        a_stato_16              CD_NAGIOS_DIAGNOSI.STATO_16%TYPE,
        a_stato_17              CD_NAGIOS_DIAGNOSI.STATO_17%TYPE,
        a_stato_18              CD_NAGIOS_DIAGNOSI.STATO_18%TYPE
    );
    TYPE C_NAGIOS_DIAGNOSI IS REF CURSOR RETURN R_NAGIOS_DIAGNOSI; 
    
    TYPE R_NAGIOS_DIAGNOSI_REPORT IS RECORD
    (
        a_id_cinema             CD_NAGIOS_DIAGNOSI_REPORT.ID_CINEMA%TYPE,    
        a_id_sala               CD_NAGIOS_DIAGNOSI_REPORT.ID_SALA%TYPE,
        a_nome_cinema           CD_NAGIOS_DIAGNOSI_REPORT.NOME_CINEMA%TYPE,
        a_comune                CD_COMUNE.COMUNE%TYPE,        
        a_nome_sala             CD_NAGIOS_DIAGNOSI_REPORT.NOME_SALA%TYPE,                
        a_giorno                CD_NAGIOS_DIAGNOSI_REPORT.GIORNO%TYPE,
        a_lampada_proiettore    CD_NAGIOS_DIAGNOSI_REPORT.LAMPADA_PROIETTORE%TYPE,
        a_proiettore            CD_NAGIOS_DIAGNOSI_REPORT.PROIETTORE%TYPE,
        a_box_i_o               CD_NAGIOS_DIAGNOSI_REPORT.BOX_I_O%TYPE,
        a_pc_player             CD_NAGIOS_DIAGNOSI_REPORT.PC_PLAYER%TYPE,
        a_pc_server             CD_NAGIOS_DIAGNOSI_REPORT.PC_SERVER%TYPE,
        a_altro                 CD_NAGIOS_DIAGNOSI_REPORT.ALTRO%TYPE,
        a_rete_fastweb          CD_NAGIOS_DIAGNOSI_REPORT.RETE_FASTWEB%TYPE
    );
    TYPE C_NAGIOS_DIAGNOSI_REPORT IS REF CURSOR RETURN R_NAGIOS_DIAGNOSI_REPORT;
    
    TYPE R_NAGIOS_SERVIZI IS RECORD
    (
        a_id_servizio           CD_NAGIOS_SERVIZI.SERVIZIO_ID%TYPE,
        a_descrizione_nagios    CD_NAGIOS_SERVIZI.DESCRIZIONE_NAGIOS%TYPE,
        a_descrizione_sipra     CD_NAGIOS_SERVIZI.DESCRIZIOE_SIPRA%TYPE,
        a_limite_flip           CD_NAGIOS_SERVIZI.LIMITE_FLIP%TYPE
    );
    TYPE C_NAGIOS_SERVIZI IS REF CURSOR RETURN R_NAGIOS_SERVIZI;
    
    TYPE R_NAGIOS_STORICO_STATI IS RECORD
    (
        a_id_sala               CD_NAGIOS_STORICO_STATI.ID_SALA%TYPE,
        a_id_cinema             CD_NAGIOS_STORICO_STATI.ID_CINEMA%TYPE,
        a_nome_cinema           CD_CINEMA.NOME_CINEMA%TYPE,
        a_comune                CD_COMUNE.COMUNE%TYPE,        
        a_nome_sala             CD_SALA.NOME_SALA%TYPE,        
        a_stato_tempo           CD_NAGIOS_STORICO_STATI.STATO_TEMPO%TYPE,
        a_stato_precedente      CD_NAGIOS_STORICO_STATI.STATO_PRECEDENTE%TYPE,
        a_stato_corrente        CD_NAGIOS_STORICO_STATI.STATO_CORRENTE%TYPE,
        a_id_servizio           CD_NAGIOS_STORICO_STATI.ID_SERVIZIO%TYPE,
        a_descrizione_nagios    CD_NAGIOS_SERVIZI.DESCRIZIONE_NAGIOS%TYPE,
        a_descrizione_sipra     CD_NAGIOS_SERVIZI.DESCRIZIOE_SIPRA%TYPE,
        a_limite_flip           CD_NAGIOS_SERVIZI.LIMITE_FLIP%TYPE,
        a_host                  CD_NAGIOS_STORICO_STATI.HOST%TYPE,
        a_stato_descrizione     CD_NAGIOS_STORICO_STATI.STATO_DESCRIZIONE%TYPE                
    );
    TYPE C_NAGIOS_STORICO_STATI IS REF CURSOR RETURN R_NAGIOS_STORICO_STATI;
    
    TYPE R_NAGIOS_SYNCH_LOG IS RECORD
    (
        a_timestap_evento       CD_NAGIOS_SYNCH_LOG.TIMESTAMP_EVENTO%TYPE,
        a_flg_esito             CD_NAGIOS_SYNCH_LOG.FLG_ESITO%TYPE,
        a_note                  CD_NAGIOS_SYNCH_LOG.NOTE%TYPE,
        a_step_type             CD_NAGIOS_SYNCH_LOG.STEP_TYPE%TYPE
    );
    TYPE C_NAGIOS_SYNCH_LOG IS REF CURSOR RETURN R_NAGIOS_SYNCH_LOG;
    
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
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_DIAGNOSI (
                                        p_data_inizio   CD_NAGIOS_DIAGNOSI.TEMPO%TYPE,
                                        p_data_fine     CD_NAGIOS_DIAGNOSI.TEMPO%TYPE,
                                        p_id_cinema     CD_NAGIOS_DIAGNOSI.ID_CINEMA%TYPE,
                                        p_id_sala       CD_NAGIOS_DIAGNOSI.ID_SALA%TYPE,
                                        p_results_num   NUMBER
                                    )
                                        RETURN C_NAGIOS_DIAGNOSI;
                                        
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
    --              p_results_num               numero di risultati richiesti (null avere l'elenco di tutti i risultati)    
    --
    --              Per una ricerca ottimale utilizzare soltanto p_id_cinema OPPURE p_id_sala    
    -- OUTPUT:
    --              lista di
    --                  R_NAGIOS_DIAGNOSI_REPORT
    --
    -- REALIZZATORE:
    --              Tommaso D'Anna, Teoresi srl, 19 Settembre 2011
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_DIAGNOSI_REPORT  (
                                                p_data_inizio   CD_NAGIOS_DIAGNOSI_REPORT.GIORNO%TYPE,
                                                p_data_fine     CD_NAGIOS_DIAGNOSI_REPORT.GIORNO%TYPE,
                                                p_id_cinema     CD_NAGIOS_DIAGNOSI_REPORT.ID_CINEMA%TYPE,
                                                p_id_sala       CD_NAGIOS_DIAGNOSI_REPORT.ID_SALA%TYPE,
                                                p_results_num   NUMBER
                                            )
                                                RETURN C_NAGIOS_DIAGNOSI_REPORT;
                                                
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
                                        RETURN C_NAGIOS_SERVIZI;
                                        
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
    -------------------------------------------------------------------------------------------------
    FUNCTION FU_GET_NAGIOS_STORICO_STATI    (
                                                p_data_inizio   CD_NAGIOS_STORICO_STATI.STATO_TEMPO%TYPE,
                                                p_data_fine     CD_NAGIOS_STORICO_STATI.STATO_TEMPO%TYPE,
                                                p_id_cinema     CD_NAGIOS_STORICO_STATI.ID_CINEMA%TYPE,
                                                p_id_sala       CD_NAGIOS_STORICO_STATI.ID_SALA%TYPE,
                                                p_results_num   NUMBER
                                            )
                                                RETURN C_NAGIOS_STORICO_STATI;
                                            
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
                                            RETURN C_NAGIOS_SYNCH_LOG;                                                                                                                                                                                   
END PA_CD_NAGIOS; 
/

