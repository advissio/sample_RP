CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_COMUNICATI_TRASMESSI
(DATA_COMMERCIALE, ID_SALA, PROGRAMMATA, ID_PROIEZIONE, ID_COMUNICATO, 
 ID_TIPO_BREAK, DURATA_BREAK_PREV, PROGRESSIVO, DATA_INIZIO_PROIEZIONE, DATA_INIZIO_BREAK, 
 DATA_EROGAZIONE_EFF, DURATA_BREAK_EFF, ID_MATERIALE, DURATA_PREV, DURATA_EFF, 
 DURATA_OK, FASCIA_OK, PROIEZIONE_OK, BREAK_OK, COM_TEST)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA parametrica VI_CD_COMUNICATI_TRASMESSI
--
-- DESCRIZIONE:
--   Estrae e verifica i comunicati andati in onda
--   Per ogni comunicato trasmesso verifica che:
--      - la durata sia maggiore o uguale a quella del relativo materiale (flag durata_ok)
--      - l'inizio della proiezione rientri nella fascia di proiezione prevista (flag fascia_ok)
--      - la sequenza di trasmissione dei comunicati del break corrispondente sia quella previsto (flag break_ok)
--      - la sequenza di trasmissione dei comunicati della proiezione corrispondente sia quella previsto (flag proiezione_ok)
--   l'hash di break e proiezioni viene calcolato come la somma dei prodotti tra id comunicato e posizione
--   Per le sale non programmate verifica se sono stati proiettati dei comunicati di test (contatore com_test)
--   Necessita obbligatoriamente della parametrizzazione mediante PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI.
--   Usata dalla sezione di verifica del trasmesso
--
-- REALIZZATORE: Angelo Marletta, 14/04/2010
-- MODIFICHE:
--    Angelo Marletta, 25/06/2010
--       Modificato il calcolo di fascia_ok, le fasce della proiezione vengono lette da cd_adv_snapshot_fascia
--    Angelo Marletta, 06/10/2010
--       Bugfix calcolo fascia_ok, le proiezioni dopo mezzanotte non sono piu segnalate come errore
--       Aggiunto filtro globale su id_sala
-----------------------------------------------------------------------------------------------------
       all_data.data_commerciale, all_data.id_sala,
       nvl(ven.venduta,0) programmata,
       prev.id_proiezione, prev.id_comunicato, prev.id_tipo_break,
       prev.durata_break durata_break_prev,
       eff.progressivo, eff.data_inizio_proiezione, eff.data_inizio_break, 
       eff.data_erogazione_eff, eff.durata_break durata_break_eff,
       eff.id_materiale, durata_prev, durata_eff,
       CASE
          WHEN durata_eff IS NULL
             THEN NULL
          WHEN durata_eff > durata_prev
             THEN 1
          ELSE 0
       END durata_ok,
       --verifica fascia
       (select decode(count(*), 0, 0, 1) from
            cd_adv_snapshot_fascia sfa, cd_adv_snapshot_playlist play
        where play.id=sfa.id_playlist and sfa.id_proiezione=prev.id_proiezione
            and (data_inizio_break-data_commerciale)*1440 between hh_inizio*60+mm_inizio-1 and hh_fine*60+mm_fine+1
            and play.data_modifica<eff.data_erogazione_eff) fascia_ok,
       CASE WHEN
            count(distinct data_inizio_break) OVER(PARTITION BY eff.id_sala,data_inizio_proiezione) = 2
            AND sum(distinct prev.hash_break) OVER(PARTITION BY eff.id_sala,data_inizio_proiezione) =
                sum(distinct eff.hash_break)  OVER(PARTITION BY eff.id_sala,data_inizio_proiezione)
            THEN 1
       ELSE 0
       END proiezione_ok,
       CASE
          WHEN prev.hash_break IS NULL
             THEN NULL
          WHEN prev.hash_break = eff.hash_break
             THEN 1
          ELSE 0
       END break_ok,
       TEST.com_test
  FROM 
       -- Comunicati effettivi
       vi_cd_comunicato_effettivo eff,
       -- Comunicati previsti
       vi_cd_comunicato_previsto prev,
       -- Log di test
       (SELECT data_commerciale, id_sala, COUNT (id_sala) com_test
            FROM cd_adv_comunicato_test
        GROUP BY data_commerciale, id_sala) TEST,
       -- Prodotto cartesiano tra id_sala e le date commerciali nell'intervallo specificato
       (SELECT distinct
            sa.id id_sala,
            dat.data_commerciale
        FROM
            vi_cd_sala sa,
            (SELECT (pa_cd_adv_cinema.fu_data_inizio + ROWNUM - 1) data_commerciale
             FROM all_objects
             WHERE ROWNUM <= pa_cd_adv_cinema.fu_data_fine - pa_cd_adv_cinema.fu_data_inizio + 1) dat
        order by data_commerciale,id_sala
        ) all_data,
        (select distinct data_commerciale,id_sala,1 venduta
        from vi_cd_comunicato_previsto) ven
WHERE
       /* provvisorio*/
       all_data.id_sala NOT IN (388)
   -- outer join per ottenere tutte le sale
   AND all_data.id_sala = eff.id_sala(+) 
   AND all_data.data_commerciale = eff.data_commerciale(+) 
   AND eff.id_sala = prev.id_sala(+)
   AND eff.id_proiezione = prev.id_proiezione(+)
   AND eff.id_break = prev.id_break(+)
   AND eff.id_comunicato = prev.id_comunicato(+)
   AND all_data.id_sala = TEST.id_sala(+) 
   AND all_data.data_commerciale = TEST.data_commerciale(+)
   and all_data.id_sala=nvl(pa_cd_adv_cinema.fu_id_sala, all_data.id_sala)
   and all_data.id_sala=ven.id_sala(+)
   and all_data.data_commerciale=ven.data_commerciale(+)
/



