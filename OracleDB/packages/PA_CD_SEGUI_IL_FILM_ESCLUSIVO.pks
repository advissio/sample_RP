CREATE OR REPLACE PACKAGE VENCD.PA_CD_SEGUI_IL_FILM_ESCLUSIVO AS
--
OPERATION_NOT_PERMITTED EXCEPTION;
--

TYPE R_PRODOTTO_SEGUI_IL_FILM IS RECORD
(
    a_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_data_inizio_pr_acq        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    a_data_fine_pr_acq          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    a_num_max_schermi           CD_PRODOTTO_ACQUISTATO.NUMERO_MASSIMO_SCHERMI%TYPE,
    a_stato_vendita             CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
    a_id_piano                  CD_PIANIFICAZIONE.ID_PIANO%TYPE,
    a_id_ver_piano              CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
    a_id_cliente                INTERL_U.COD_INTERL%TYPE,
    a_nome_cliente              INTERL_U.RAG_SOC_COGN%TYPE,
    a_id_spettacolo             CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
    a_nome_spettacolo           CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_data_inizio_spettacolo    CD_SPETTACOLO.DATA_INIZIO%TYPE,
    a_data_fine_spettacolo      CD_SPETTACOLO.DATA_FINE%TYPE,
    a_flg_protetto_spettacolo   CD_SPETTACOLO.FLG_PROTETTO%TYPE,
    a_giorno                    CD_SALA_SEGUI_FILM.GIORNO%TYPE,
    a_soglia                    CD_SALA_SEGUI_FILM.SOGLIA%TYPE,
    a_assegnato                 NUMBER 
);
TYPE C_PRODOTTO_SEGUI_IL_FILM IS REF CURSOR RETURN R_PRODOTTO_SEGUI_IL_FILM ;

TYPE R_DATE_PRODOTTI IS RECORD
(
    a_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    a_data_fine   CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
);

TYPE C_DATE_PRODOTTI IS REF CURSOR RETURN R_DATE_PRODOTTI;

TYPE R_NUM_SALE_DATA IS RECORD
(
    a_data       CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
    a_num_sale   NUMBER
);

TYPE C_NUM_SALE_DATA IS REF CURSOR RETURN R_NUM_SALE_DATA;

TYPE R_CLIENTE IS RECORD
(
    a_id_cliente        INTERL_U.COD_INTERL%TYPE,
    a_rag_soc_br_nome   INTERL_U.RAG_SOC_BR_NOME%TYPE,
    a_rag_soc_cogn      INTERL_U.RAG_SOC_COGN%TYPE,
    a_indirizzo         INTERL_U.INDIRIZZO%TYPE,
    a_localita          INTERL_U.LOCALITA%TYPE,
    a_cap               INTERL_U.CAP%TYPE,
    a_nazione           INTERL_U.NAZIONE%TYPE,
    a_cod_fisc          INTERL_U.COD_FISC%TYPE,
    a_num_civico        INTERL_U.NUM_CIVICO%TYPE,
    a_provincia         INTERL_U.PROVINCIA%TYPE,
    a_sesso             INTERL_U.SESSO%TYPE,
    a_area              INTERL_U.AREA%TYPE,
    a_sede              INTERL_U.SEDE%TYPE,
    a_nome              INTERL_U.NOME%TYPE,
    a_cognome           INTERL_U.COGNOME%TYPE
);

TYPE C_CLIENTE IS REF CURSOR RETURN R_CLIENTE;

TYPE R_SPETTACOLO IS RECORD
(
    a_id_spettacolo         CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
    a_nome_spettacolo       CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_data_inizio           CD_SPETTACOLO.DATA_INIZIO%TYPE,
    a_data_fine             CD_SPETTACOLO.DATA_FINE%TYPE,    
    a_durata_spettacolo     CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
    a_flg_protetto          CD_SPETTACOLO.FLG_PROTETTO%TYPE,
    a_id_distributore       CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE  
);

TYPE C_SPETTACOLO IS REF CURSOR RETURN R_SPETTACOLO;

TYPE R_SALA IS RECORD
(
    a_id_cinema                     CD_CINEMA.ID_CINEMA%TYPE,
    a_id_sala                       CD_SALA.ID_SALA%TYPE,    
    a_nome_cinema                   CD_CINEMA.NOME_CINEMA%TYPE,
    a_nome_sala                     CD_SALA.NOME_SALA%TYPE
);
TYPE C_SALA IS REF CURSOR RETURN R_SALA;
--
FUNCTION FU_VERIFICA_DISPONIBILITA( p_id_prodotto_acquistato   cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                      p_id_sala                  cd_sala.id_sala%type,
                                      p_giorno                   date,
                                      p_sale_non_idonee          varchar2
                                     ) RETURN NUMBER;
--
PROCEDURE PR_GESTISCI_PRODOTTO(  p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                 p_giorno                    date,
                                 p_soglia                    number,
                                 p_esito                     out number
                               );
--
PROCEDURE PR_AGGIORNA_PRODOTTO(  p_giorno                    date
                               );
--
PROCEDURE PR_ASSOCIA_SALE( p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                             p_id_spettacolo             cd_spettacolo.id_spettacolo%type,
                             p_giorno                    date,
                             p_soglia_new                number,
                             p_esito                     out number
                           );
------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------
PROCEDURE PR_DISASSOCIA_SALE_NON_IDONEE( p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                         p_id_spettacolo             cd_spettacolo.id_spettacolo%type,
                                         p_giorno                    date,
                                         p_esito                     out number
                                       );
------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------
PROCEDURE PR_DISASSOCIA_FINO_A_SOGLIA(   p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                         p_id_spettacolo             cd_spettacolo.id_spettacolo%type,
                                         p_giorno                    date,
                                         p_soglia                    number,
                                         p_esito                     out number
                                       );                                       
------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------
PROCEDURE PR_IMPOSTA_SALA(p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                            p_sala_virtuale              number,
                            p_sala_disponibile           number,
                            p_giorno                     date,
                            p_sale_non_idonee            varchar2,
                            p_esito                      out number
                           );
------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------
PROCEDURE PR_RIPRISTINA_SALA(  p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                               p_sala_reale                 number,
                               p_giorno                     date,
                               p_esito                      out number
                             );
------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------
PROCEDURE PR_POPOLA_TAVOLA(  p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                             p_data_inizio                date,
                             p_data_fine                  date,
                             p_soglia                     number,
                             p_esito                      out number
                             );
                             

PROCEDURE PR_RICALCOLA_TARIFFA(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE);                             
PROCEDURE PR_RICALCOLA_TARIFFA_PRODOTTO(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE);

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_RICERCA_PROD_SEGUI_IL_FILM
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista di prodotti "Segui
--              il Film" che corrisponde ai criteri di ricerca inseriti
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--              p_stato_vendita         stato di vendita
--              p_id_spettacolo         id dello spettacolo
--              p_id_cliente            id del cliente
--
-- OUTPUT:
--              lista di
--                  R_PRODOTTO_SEGUI_IL_FILM
--              elenco dei prodotti "Segui il Film" corrispondenti ai criteri
--              di ricerca
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 4 Marzo 2011
-------------------------------------------------------------------------------------------------
FUNCTION FU_RICERCA_PROD_SEGUI_IL_FILM  (
                                            p_data_inizio       CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                            p_data_fine         CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
                                            p_stato_vendita     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                            p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                            p_id_cliente        INTERL_U.COD_INTERL%TYPE
                                        )
                                 RETURN C_PRODOTTO_SEGUI_IL_FILM;
                                 
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_DATE_PRODOTTI
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista delle date inizio/fine
--              relative a tutti i prodotti di tipo "Segui il Film"
--
-- INPUT:
--              NOTHING
--
-- OUTPUT:
--              lista di
--                  R_DATE_PRODOTTI
--              elenco delle coppie di date inizio/fine relative a tutti i 
--              prodotti di tipo "Segui il Film"
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 4 Marzo 2011
-------------------------------------------------------------------------------------------------
FUNCTION FU_GET_DATE_PRODOTTI RETURN C_DATE_PRODOTTI;

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SALE_GIORNO_IDONEE
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              dei singoli giorni con le sale idonee 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--              p_stato_vendita         lo stato di vendita del prodotto acquistato
--              p_id_spettacolo         id dello spettacolo
--
-- OUTPUT:
--              lista di
--                  R_NUM_SALE_DATA
--              elenco delle coppie di date / numero sale
--
-- REALIZZATORE:
--              Antonio Colucci, Teoresi srl, 9 Marzo 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_SALE_GIORNO_IDONEE(
                                       p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                       p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                       p_id_spettacolo CD_PROIEZIONE_SPETT.ID_SPETTACOLO%TYPE
                                  )
                                RETURN C_NUM_SALE_DATA; 

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SALE_GIORNO_DISPONIBILI
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              dei singoli giorni con le sale disponibili 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--              p_stato_vendita         lo stato di vendita del prodotto acquistato
--              p_id_spettacolo         id dello spettacolo
--
-- OUTPUT:
--              lista di
--                  R_NUM_SALE_DATA
--              elenco delle coppie di date / numero sale
--
-- REALIZZATORE:
--              Antonio Colucci, Teoresi srl, 9 Marzo 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_SALE_GIORNO_DISPONIBILI(
                                            p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_id_spettacolo CD_PROIEZIONE_SPETT.ID_SPETTACOLO%TYPE,                                            
                                            p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE
                                       )
                                RETURN C_NUM_SALE_DATA;
                                
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_SPETT_SEGUI_IL_FILM
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              degli spettacoli relativi a prodotti di tipo "Segui il Film" 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--
-- OUTPUT:
--              lista di
--                  R_SPETTACOLO
--              elenco degli spettacoli 
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 11 Marzo 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_SPETT_SEGUI_IL_FILM(
                                        p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                        p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE
                                   )
                                RETURN C_SPETTACOLO;
                                
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CLIENTI_SEGUI_IL_FILM
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalle date inserite in input)
--              dei clienti relativi a prodotti di tipo "Segui il Film" 
--
-- INPUT:
--              p_data_inizio           data di inizio ricerca
--              p_data_fine             data di fine ricerca
--
-- OUTPUT:
--              lista di
--                  R_CLIENTE
--              elenco dei clienti
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 11 Marzo 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_GET_CLIENTI_SEGUI_IL_FILM(
                                        p_data_inizio   CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                        p_data_fine     CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE
                                   )
                                RETURN C_CLIENTE;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_SALE_GIORNO_ASSOCIATE
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalla data inserita in input)
--              delle sale associate per il prodotto acquistato selezionato
--
-- INPUT:
--              p_data_proiezione           data di ricerca
--              p_id_prodotto_acquistato    l'id del prodotto acquistato
--
-- OUTPUT:
--              lista di
--                  R_SALA
--              elenco delle sale
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 25 Luglio 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_DETT_SALE_GIORNO_ASSOCIATE(
                                        p_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                        p_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE
                                   )
                                RETURN C_SALA;
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_SALE_GIORNO_DISPONIB
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalla data inserita in input)
--              delle sale disponibili per lo spettacolo selezionato
--
-- INPUT:
--              p_data_proiezione           data di ricerca
--              p_id_spettacolo             l'id dello spettacolo
--              p_stato_vendita             lo stato di vendita del prodotto acquistato
--
-- OUTPUT:
--              lista di
--                  R_SALA
--              elenco delle sale
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 26 Luglio 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_DETT_SALE_GIORNO_DISPONIB(
                                        p_data_proiezione   CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                        p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                        p_stato_vendita     CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE
                                     )
                                    RETURN C_SALA;        
---------------------------------------------------------------------------------------------------
-- FUNCTION FU_DETT_SALE_GIORNO_IDONEE
--
-- DESCRIZIONE:  
--              Funzione che permette di recuperare la lista (dalla data inserita in input)
--              delle sale disponibili per lo spettacolo selezionato
--
-- INPUT:
--              p_data_proiezione           data di ricerca
--              p_id_spettacolo             l'id dello spettacolo
--              p_stato_vendita             lo stato di vendita del prodotto acquistato
--
-- OUTPUT:
--              lista di
--                  R_SALA
--              elenco delle sale
--
-- REALIZZATORE:
--              Tommaso D'Anna, Teoresi srl, 26 Luglio 2011
-------------------------------------------------------------------------------------------------

FUNCTION FU_DETT_SALE_GIORNO_IDONEE(
                                        p_data_proiezione   CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                        p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE
                                     )
                                    RETURN C_SALA;   
                                                                                                                                                                              
                           
END PA_CD_SEGUI_IL_FILM_ESCLUSIVO; 
/

