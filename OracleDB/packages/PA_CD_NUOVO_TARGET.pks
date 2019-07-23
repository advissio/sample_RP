CREATE OR REPLACE PACKAGE VENCD.PA_CD_NUOVO_TARGET AS
--
OPERATION_NOT_PERMITTED EXCEPTION;
--
TYPE R_NUM_SALE_DATA IS RECORD
(
    num_sale_idoneee   NUMBER,
    a_data_proiezione  CD_PROIEZIONE.DATA_PROIEZIONE%TYPE
);
TYPE C_NUM_SALE_DATA IS REF CURSOR RETURN R_NUM_SALE_DATA;

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
PROCEDURE PR_AGGIORNA_PRODOTTO(  p_giorno                    date
);
------------------------------------------------------------------------------------------------------
PROCEDURE PR_POPOLA_TAVOLA(  p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                             p_data_inizio                date,
                             p_data_fine                  date,
                             p_soglia                     number,
                             p_esito                      out number
                             );
PROCEDURE PR_ASSOCIA_SALE( p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                             p_id_target               cd_target.id_target%type,
                             p_giorno                    date,
                             p_soglia_new                number,
                             p_esito                     out number
                           );
PROCEDURE PR_IMPOSTA_SALA(p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                            p_sala_virtuale              number,
                            p_sala_disponibile           number,
                            p_giorno                     date,
                            p_sale_non_idonee            varchar2,
                            p_esito                      out number
                           );
PROCEDURE PR_RIPRISTINA_SALA(  p_id_prodotto_acquistato     cd_prodotto_acquistato.id_prodotto_acquistato%type,
                               p_sala_reale                 number,
                               p_giorno                     date,
                               p_esito                      out number
                             );                          
FUNCTION FU_GET_SALE_GIORNO_IDONEE( p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                    p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                    p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                    p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                    p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                    p_data_soglia            date default trunc(sysdate)
                                )
                                RETURN C_NUM_SALE_DATA;
------------------------------------------------------------------------------------------------------                                
PROCEDURE PR_DISASSOCIA_SALE_NON_IDONEE( p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                         p_id_target                 cd_target.id_target%type,
                                         p_giorno                    date,
                                         p_esito                     out number
                                       );
------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------
PROCEDURE PR_DISASSOCIA_FINO_A_SOGLIA(   p_id_prodotto_acquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                         p_giorno                    date,
                                         p_soglia                    number,
                                         p_esito                     out number
                                       );                                       
------------------------------------------------------------------------------------------------------
function fu_get_sale_giorno_idonee_disp (p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                         p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                         p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                         p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                         p_data_soglia            date default trunc(sysdate)
                                         ) return c_num_sale_data;
------------------------------------------------------------------------------------------------------ 

PROCEDURE PR_ASSOCIA_SALE_WEB(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, 
                       p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, 
                       p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, 
                       p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, 
                       p_soglia id_list_type); 
                       
FUNCTION FU_SOGLIE_PERIODO(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, 
                           p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, 
                           p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, 
                           p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                           P_ID_PRODOTTO_ACQUISTATO CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN C_NUM_SALE_DATA;
                           
                           
                           
                           
procedure pr_agg_numero_sale_idonee_disp(   p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                            p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                            p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                            p_data_soglia            date default trunc(sysdate));
                                            
                                            
                                            
procedure pr_aggiorna_numero_sale_idonee(
                                            p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type default null,
                                            p_data_inizio            CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_data_fine              CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                                            p_id_target              CD_TARGET.ID_TARGET%TYPE,
                                            p_esclusivo              CD_PRODOTTO_ACQUISTATO.FLG_ESCLUSIVO%TYPE default 'S',
                                            p_data_soglia            date default trunc(sysdate));                                                                                          
                                                                                                                                                                   
END PA_CD_NUOVO_TARGET; 
/

