CREATE OR REPLACE PACKAGE BODY VENCD.pa_cd_liquidazione_esercente AS
/******************************************************************************
   NAME:       pa_cd_liquidazione_esercente
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22/04/2010             1. Created this package body.
******************************************************************************/


PROCEDURE PR_MODIFICA_STATO_LIQUIDAZIONE( P_ID_QUOTA_ESERCENTE  CD_QUOTA_ESERCENTE.ID_QUOTA_ESERCENTE%TYPE, 
                                          P_STATO_LAVORAZIONE CD_QUOTA_ESERCENTE.STATO_LAVORAZIONE%TYPE) IS                                         
v_num_stati      number;
v_stato_corrente  cd_quota_esercente.stato_lavorazione%type;
v_id_liquidazione cd_liquidazione.id_liquidazione%type;
not_valid_state exception;
                                          
BEGIN

     select stato_lavorazione
     into v_stato_corrente
     from cd_quota_esercente
     where id_quota_esercente = p_id_quota_esercente;
     
     if   (v_stato_corrente = 'ANT' and p_stato_lavorazione = 'DAL')
       or (v_stato_corrente = 'DAL' and p_stato_lavorazione = 'LIQ')
       or (v_stato_corrente = 'LIQ' and p_stato_lavorazione = 'DAL')
       or (v_stato_corrente = 'DAL' and p_stato_lavorazione = 'ANT')
     then
       
        update cd_quota_esercente 
        set   stato_lavorazione = p_stato_lavorazione
        where id_quota_esercente = p_id_quota_esercente;
        
        select id_liquidazione 
        into v_id_liquidazione
        from cd_quota_esercente  
        where id_quota_esercente = p_id_quota_esercente;
        
        
        select  count(distinct (stato_lavorazione))  
        into    v_num_stati
        from    cd_quota_esercente 
        where   id_liquidazione = v_id_liquidazione;
             
    
        if v_num_stati = 1 and p_stato_lavorazione != 'ANT' then
            update cd_liquidazione 
            set   stato_lavorazione = p_stato_lavorazione
            where   id_liquidazione = v_id_liquidazione;
        end if;
     else
        raise not_valid_state;
     end if;
     
EXCEPTION 
WHEN not_valid_state then
     raise; 
WHEN others then
     raise; 
END PR_MODIFICA_STATO_LIQUIDAZIONE;


PROCEDURE PR_MODIFICA_STATO_LIQUIDAZIONE(P_ID_QUOTA_ESERCENTE IN CD_QUOTA_ESERCENTE.ID_QUOTA_ESERCENTE%TYPE,  P_ESITO OUT NUMBER) is
BEGIN
   PR_MODIFICA_STATO_LIQUIDAZIONE(P_ID_QUOTA_ESERCENTE,'LIQ');
   p_esito := 1;
EXCEPTION   
WHEN others THEN
     p_esito := -1; 
END PR_MODIFICA_STATO_LIQUIDAZIONE;  

END pa_cd_liquidazione_esercente; 
/

