CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SALTO_SALE_PARZIALI  AS
/******************************************************************************
   NAME:       PA_CD_RECUPERO_SALE_PARZIALI 
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27/05/2011             1. Created this package body.
******************************************************************************/

 FUNCTION FU_CERCA_SALE(p_id_cinema cd_cinema.id_cinema%type, p_id_sala cd_sala.id_sala%type, p_data_inizio date, p_data_fine date ) RETURN C_SALA IS
 V_SALA C_SALA;
 BEGIN
    /*OPEN V_SALA FOR
    SELECT  count(cd_sala.id_sala) AS NUM_VOLTE_SETTIMANA, 
                    CD_CINEMA.ID_CINEMA, 
                    CD_CINEMA.NOME_CINEMA,
                    CD_COMUNE.COMUNE, 
                    CD_SALA.ID_SALA, 
                    CD_SALA.NOME_SALA
           FROM     CD_PROIEZIONE, 
                    CD_CINEMA, 
                    CD_SALA,
                    CD_SCHERMO,
                    CD_COMUNE
            WHERE   CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
            and     CD_CINEMA.ID_COMUNE = CD_COMUNE.ID_COMUNE
            AND     CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
            AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
            AND     (p_id_cinema IS NULL OR CD_CINEMA.ID_CINEMA = p_id_cinema)
            AND     (p_id_sala IS NULL OR CD_SALA.ID_SALA = p_id_sala)
            AND     (CD_PROIEZIONE.DATA_PROIEZIONE between p_data_inizio and p_data_fine)
            AND      CD_PROIEZIONE.FLG_ANNULLATO='N'
            AND      CD_CINEMA.FLG_VIRTUALE ='N'
            AND      CD_SALA.FLG_ARENA ='N'
            group by CD_CINEMA.ID_CINEMA, 
                    CD_CINEMA.NOME_CINEMA,
                    CD_COMUNE.COMUNE, 
                    CD_SALA.ID_SALA, 
                    CD_SALA.NOME_SALA
            having count(cd_sala.id_sala) < (p_data_fine - p_data_inizio) * 2;      
    RETURN V_SALA;*/
OPEN V_SALA FOR    
    select count(cd_sala.id_sala) AS NUM_VOLTE_SETTIMANA,
           NVL(NUM_PRODOTTI.NUMERO,0) NUMERO_PRODOTTI,
           CD_CINEMA.ID_CINEMA, 
           CD_CINEMA.NOME_CINEMA,
           CD_COMUNE.COMUNE, 
           CD_SALA.ID_SALA, 
           CD_SALA.NOME_SALA
           FROM     CD_PROIEZIONE, 
                    CD_CINEMA, 
                    CD_SALA,
                    (
                        select count(distinct(pa.id_prodotto_acquistato)) numero,id_sala
                        from  cd_comunicato co,
                        cd_prodotto_acquistato pa
                        where pa.data_inizio = p_data_inizio
                        and   pa.data_fine = p_data_fine
                        and   pa.flg_annullato ='N'
                        and   pa.flg_sospeso ='N'
                        and   pa.stato_di_vendita ='PRE'
                        and   co.id_prodotto_acquistato = pa.id_prodotto_acquistato
                        and   co.flg_annullato ='N'
                        and   co.flg_sospeso ='N'
                        GROUP BY ID_SALA
                    )NUM_PRODOTTI,
                    CD_SCHERMO,
                    CD_COMUNE
            WHERE   CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
            and     CD_CINEMA.ID_COMUNE = CD_COMUNE.ID_COMUNE
            AND     CD_SALA.ID_SALA = CD_SCHERMO.ID_SALA
            AND     CD_SCHERMO.ID_SCHERMO = CD_PROIEZIONE.ID_SCHERMO
            AND     (p_id_cinema IS NULL OR CD_CINEMA.ID_CINEMA = p_id_cinema)
            AND     (p_id_sala IS NULL OR CD_SALA.ID_SALA = p_id_sala)
            AND     (CD_PROIEZIONE.DATA_PROIEZIONE between p_data_inizio and p_data_fine)
            AND      CD_PROIEZIONE.FLG_ANNULLATO='N'
            AND      CD_CINEMA.FLG_VIRTUALE ='N'
            AND      CD_SALA.FLG_ARENA ='N'
            AND      NUM_PRODOTTI.ID_SALA (+) = CD_SALA.ID_SALA
            group by CD_CINEMA.ID_CINEMA, 
                    CD_CINEMA.NOME_CINEMA,
                    CD_COMUNE.COMUNE, 
                    CD_SALA.ID_SALA, 
                    CD_SALA.NOME_SALA,
                    NUM_PRODOTTI.NUMERO
            having count(cd_sala.id_sala) < (p_data_fine - p_data_inizio) * 2;
            RETURN V_SALA;    
END FU_CERCA_SALE;
 
 
FUNCTION FU_ELENCO_PRODOTTI(p_data_inizio date, p_data_fine date, p_id_sala cd_sala.id_sala%type) return c_prodotto is
 v_prodotto c_prodotto;
 begin
 open v_prodotto for
 select co.id_prodotto_acquistato,
       cliente.rag_soc_cogn as cliente,
       pia.id_piano||'/'||pia.id_ver_piano as piano,  
       cir.nome_circuito as circuito, 
       modven.desc_mod_vendita as modalita_vendita,
       tb.desc_tipo_break  as tipo_break,
       data_erogazione_prev as data_erogazione,
       co.cod_disattivazione as disattivata,
       bv.flg_annullato as break_vendita_annullato,
       coef.durata
from cd_prodotto_acquistato pa, 
     cd_pianificazione pia,
     interl_u cliente,
     cd_comunicato co, 
     cd_formato_acquistabile fa, 
     cd_coeff_cinema coef, 
     cd_prodotto_vendita pv,
     cd_tipo_break tb,
     cd_modalita_vendita modven,
     cd_break_vendita bv, 
     cd_circuito cir 
where pa.data_inizio = p_data_inizio
and   pa.data_fine = p_data_fine
and   pa.flg_annullato ='N'
and   pa.flg_sospeso ='N'
and   pa.stato_di_vendita ='PRE'
and   pa.id_piano = pia.id_piano
and   pa.id_ver_piano = pia.id_ver_piano
and   pia.id_cliente = cliente.cod_interl
and   pa.id_prodotto_vendita = pv.id_prodotto_vendita
and   pv.id_circuito = cir.id_circuito
and   pv.id_tipo_break = tb.ID_TIPO_BREAK
and   pv.id_mod_vendita = modven.id_mod_vendita
and   co.id_prodotto_acquistato = pa.id_prodotto_acquistato
and   co.id_sala = p_id_sala
and   co.flg_annullato ='N'
and   co.flg_sospeso ='N'
and   co.id_break_vendita = bv.id_break_vendita -- x avere lo stato del break
and   fa.id_formato = pa.id_formato
and   fa.id_coeff = coef.id_coeff
--and   co.cod_disattivazione is null 
group by co.id_prodotto_acquistato,
         cliente.rag_soc_cogn,
         pia.id_piano,
          pia.id_ver_piano,
         cir.nome_circuito, 
         co.data_erogazione_prev,
         modven.desc_mod_vendita,
         tb.desc_tipo_break, 
         co.cod_disattivazione,
         bv.flg_annullato,
         coef.durata;
 return v_prodotto;
 END FU_ELENCO_PRODOTTI;
 
 
PROCEDURE PR_SALTA_SALA_PRODDOTTO(p_id_sala cd_sala.id_sala%type, 
                                  p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type
                                 ) is
                                 
p_esito  NUMBER;
p_piani_errati  VARCHAR2(100);                                 
                                 
cursor c_comunicati is
select id_comunicato
from  cd_comunicato
where id_prodotto_acquistato = p_id_prodotto_acquistato 
and   id_sala = p_id_sala
and   flg_annullato ='N'
and   flg_sospeso ='N'
and   cod_disattivazione is null;
--and   data_erogazione_prev >  trunc(sysdate);--chiedere se devo metterla. 16/06/2011 Abbiamo consentito l'annullamento retroattivo dei comunicati
begin
for v_comunicati in c_comunicati 
loop
    pa_cd_comunicato.pr_annulla_comunicato(v_comunicati.id_comunicato,
                                 'PAL',
                                 p_esito,
                                 p_piani_errati);
end loop;
end  PR_SALTA_SALA_PRODDOTTO; 






PROCEDURE PR_RECUPERA_SALA_PRODOTTO(p_id_sala cd_sala.id_sala%type, 
                                     p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type
                                 ) is                 
p_esito  NUMBER;
                                                
cursor c_comunicati is
select id_comunicato
from  cd_comunicato com, cd_break_vendita bv  
where com.id_prodotto_acquistato = p_id_prodotto_acquistato 
and   com.id_sala = p_id_sala
and   bv.id_break_vendita = com.id_break_vendita
and   bv.flg_annullato = 'N';
--and  com.data_erogazione_prev >  trunc(sysdate);--chiedere se devo metterla 16/06/2011 Abbiamo consentito l'annullamento retroattivo dei comunicati.
begin
for v_comunicati in c_comunicati 
loop
    --dbms_output.put_line('id_coumunicato : '||v_comunicati.id_comunicato);
    pa_cd_comunicato.pr_recupera_comunicato(v_comunicati.id_comunicato,
                                 'MAG',
                                 p_esito);
end loop;
end  PR_RECUPERA_SALA_PRODOTTO; 

END PA_CD_SALTO_SALE_PARZIALI ; 
/

