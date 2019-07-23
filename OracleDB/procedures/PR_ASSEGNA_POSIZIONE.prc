CREATE OR REPLACE PROCEDURE VENCD.pr_assegna_posizione(p_id_comunicato cd_comunicato.id_comunicato%type) IS
v_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type;
/******************************************************************************
   NAME:       pr_assegna_posizione
   PURPOSE:    assegna la posizione a un comunicato. Viene richiamato quando il comunicato passa
               allo stato prenotato. Assegna all'ultimo comunicato la prima posizione nel break
               questo perche e la posizione meno importante essendo la piu distante dall'inizio
               del film. Prima di asseggnare la posizione verifica l'affollamento verificadolo per:
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


BEGIN
select id_prodotto_acquistato
into   v_id_prodotto_acquistato
from   cd_comunicato
where  id_comunicato = p_id_comunicato;

-- Non sono cicuro che deve operare solo sullo stato PRE.
pr_verifica_affollamento(v_id_prodotto_acquistato, 'PRE');

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END pr_assegna_posizione; 
/

