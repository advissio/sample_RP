CREATE OR REPLACE PROCEDURE VENCD.pr_verifica_affollamento(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, p_stato_di_vendita cd_prodotto_acquistato.stato_di_vendita%type ) IS
/******************************************************************************
   NAME:       pr_verifica_affollamento
   PURPOSE:     Verifica l'affollamento verificandolo per:
                proiezione
                break
                prodotto di vendita
                se e stato sforato l'affollamento di proiezione termina i controlli e solleva un eccezioene con il messaggio opportuno
                altrimenti verifica l'affollamento per  i break
                se sfora il diponibile per break termina i controlli e solleva un eccezione con il messaggio opportuno
               altrimenti verifica l'affollamento per i prodotti di vendita
               se sfora il diponibile allora i controlli e solleva un eccezioene con il messaggio opportuno



   REVISIONS:
   Ver        Date        Author            Description
   ---------  ----------  ---------------   ---------------
   1.0        25/09/2009  Mauro Viel Altran  Settembre 2009


******************************************************************************/

v_id_break_vendita   cd_break_vendita.id_break_vendita%type;
v_ss_prev            cd_break_vendita.SECONDI_VENDIBILI%type;
v_secondi_vendibili  cd_break_vendita.SECONDI_VENDIBILI%type;
v_secondi_assegnati  cd_break.secondi_assegnati%type;
v_id_proiezione      cd_proiezione.ID_PROIEZIONE%type;
v_secondi_proiezione cd_break.secondi_assegnati%type;

BEGIN


select  fv_breakv.secondi_vendibili - count(com.id_comunicato)*fv_breakv.durata as as diponibilita_break_vendita--,fv_breakv.id_break_vendita
--select  count(com.id_comunicato)*fv_breakv.durata as secondi_venduti,fv_breakv.secondi_vendibili--,fv_breakv.id_break_vendita
from cd_comunicato com,
(       select id_break_vendita,secondi_vendibili,id_prodotto_acquistato,stato_di_vendita,durata
        from  cd_break_vendita brkv ,
        cd_prodotto_acquistato pa,
        cd_prodotto_vendita pv,
        cd_formato_acquistabile fa,
        cd_coeff_cinema coef
        where id_prodotto_acquistato =p_id_prodotto_acquistato
        and   brkv.id_prodotto_vendita =pv.id_prodotto_vendita
        and   pa.id_prodotto_vendita   =brkv.id_prodotto_vendita
        and   pa.id_formato=fa.id_formato
        and   fa.ID_COEFF = coef.id_coeff
)fv_breakv
where com.id_break_vendita = fv_breakv.id_break_vendita
group by fv_breakv.secondi_vendibili,fv_breakv.id_break_vendita,fv_breakv.durata

    select sum(mm_prev)*60 as SS_PREV into v_ss_prev
    from cd_comunicato com, cd_prodotto_acquistato pa, cd_prodotto_vendita pv, break_vendita
    where com.id_prodotto_acquistato = p_id_prodotto_acquistato
    and id_break_vendita = v_id_break_vendita
    and com.id_prodotto_acquistato = pa.id_prodotto_acquistato
    and pa.STATO_DI_VENDITA = p_stato_di_vendita;

    select secondi_vendibili into v_secondi_vendibili
    from cd_break_vendita
    where id_break_vendita = v_id_break_vendita;

    if v_secondi_vendibili < v_ss_prev then
        --verifico l'assegnato per break
         select secondi_assegnati,v_id_proiezione  into v_secondi_assegnati,v_id_proiezione
          from  cd_break br,cd_circuito_break cir_br,cd_break_vendita br_ve
          where br_ve.id_break_vendita = v_id_break_vendita
          and   cir_br.id_circuito_break =  br_ve.id_circuito_break
          and   br.ID_BREAK = cir_br.ID_BREAK;

          if v_secondi_assegnati < v_ss_prev then
            --verifico l'assegnato per proiezione
            select sum(secondi_assegnati) into v_secondi_proiezione
            from cd_break
            where id_proiezione = v_id_proiezione;

            if v_secondi_proiezione < v_ss_prev then
                 RAISE_APPLICATION_ERROR(-20019, 'E'' stato superato la disponibilita sulla proiezione');
            else
                RAISE_APPLICATION_ERROR(-20020, 'E'' stato superato la disponibilita sul break');
            end if;
          else
                RAISE_APPLICATION_ERROR(-20021, 'E'' stato superato la disponibilita sul break di vendita');
          end if;
    end if;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       RAISE;
     WHEN OTHERS THEN
        raise;
       -- Consider logging the error and then re-raise
       RAISE;
END pr_verifica_affollamento; 
/

