CREATE OR REPLACE PACKAGE BODY VENCD.PAOLO_PROVA IS
--
/*Paolo Enrico, Altran Italia, marzo 2010 
Esempio dell'uso delle TABLE FUNCTION in una sezione dell'applicazione.
*/
--
function fu_data_da return date is
begin

    return to_date('01/01/2010','dd/mm/yyyy');

end;
--
function fu_data_a return date is
begin

    return to_date('28/02/2010','dd/mm/yyyy');

end;
--

FUNCTION fu_elenco_piani (P_DATA_INIZIO in date,P_DATA_FINE in date) RETURN C_RESULT_SET PIPELINED IS
    --
    C_set RESULT_SET;    
    --
     cursor elenco_record is
     SELECT
         id_piano,
         id_ver_piano,
           desc_area,
           desc_sede,
           responsabile_contatto,
           desc_cliente,
           cod_categoria_prodotto,
           ID_FRUITORI_DI_PIANO,
           DESC_FRUITORE,
           pa_cd_ordine.FU_INTERM_ERRATO(id_piano, id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,ID_FRUITORI_DI_PIANO) as INTERM_ERRATO,
           pa_cd_ordine.FU_SOGGETTO_ERRATO(id_piano, id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,ID_FRUITORI_DI_PIANO) as SOGGETTO_ERRATO,
           pa_cd_ordine.FU_CLIENTE_ERRATO(id_piano, id_ver_piano, id_cliente, P_DATA_INIZIO, P_DATA_FINE) as CLIENTE_ERRATO,
           pa_cd_ordine.FU_FRUITORE_ERRATO(id_piano, id_ver_piano, P_DATA_INIZIO, P_DATA_FINE,ID_FRUITORI_DI_PIANO) as FRUITORE_ERRATO
FROM

(SELECT distinct PA.ID_FRUITORI_DI_PIANO  AS ID_FRUITORI_DI_PIANO,
           PIA.id_piano id_piano,
           PIA.id_ver_piano id_ver_piano,
           aree.DESCRIZIONE_ESTESA as desc_area,
           sedi.DESCRIZIONE_ESTESA as desc_sede,
           resp.RAG_SOC_COGN as responsabile_contatto,
           cliente.RAG_SOC_COGN as desc_cliente,
           cliente.ID_CLIENTE,
           PIA.cod_categoria_prodotto,
           pa_cd_ordine.FU_GET_DESC_FRUITORE(PA.ID_FRUITORI_DI_PIANO) as DESC_FRUITORE
    FROM
            CD_PIANIFICAZIONE PIA,
                VI_CD_CLIENTE cliente,
            interl_u resp,
          VI_CD_AREE_SEDI_COMPET ARSE,
         aree,
         sedi,
         CD_PRODOTTO_ACQUISTATO PA,
         CD_IMPORTI_PRODOTTO IMPP
    where   PIA.DATA_INVIO_MAGAZZINO IS NOT  NULL

    AND   PIA.DATA_TRASFORMAZIONE_IN_PIANO IS NOT NULL
    AND   PIA.FLG_SOSPESO ='N'
    AND   PIA.FLG_ANNULLATO = 'N'
    AND cliente.ID_CLIENTE = PIA.ID_CLIENTE
    AND resp.COD_INTERL = PIA.ID_RESPONSABILE_CONTATTO
    AND ARSE.COD_AREA = PIA.COD_AREA
    AND ARSE.COD_SEDE =PIA.COD_SEDE
    AND PIA.COD_AREA = AREE.COD_AREA
    AND PIA.COD_SEDE = SEDI.COD_SEDE
    AND DECODE( FU_UTENTE_PRODUTTORE , 'S' , pa_sessione.FU_VISIBILITA_INTERLOCUTORE(PIA.ID_CLIENTE),'S') = 'S'
    AND PA.ID_PIANO = PIA.ID_PIANO
    AND PA.ID_VER_PIANO = PIA.ID_VER_PIANO
    AND PA.FLG_ANNULLATO = 'N'
    AND PA.FLG_SOSPESO = 'N'
    AND PA.COD_DISATTIVAZIONE IS NULL
    AND PA.STATO_DI_VENDITA = 'PRE'
    AND P_DATA_INIZIO <= PA.DATA_FINE
    AND P_DATA_FINE >= PA.DATA_INIZIO
    AND IMPP.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
    AND (LEAST(PA.DATA_FINE,P_DATA_FINE) - GREATEST(PA.DATA_INIZIO,P_DATA_INIZIO) + 1) >
     (SELECT NVL(SUM(LEAST(IMPF.DATA_FINE,P_DATA_FINE) - GREATEST(IMPF.DATA_INIZIO,P_DATA_INIZIO) + 1),0) FROM CD_IMPORTI_FATTURAZIONE IMPF, CD_ORDINE ORD
       WHERE IMPF.ID_IMPORTI_PRODOTTO = IMPP.ID_IMPORTI_PRODOTTO
       AND IMPF.ID_ORDINE = ORD.ID_ORDINE
       AND ORD.FLG_ANNULLATO = 'N'
       AND ORD.FLG_SOSPESO = 'N'
       AND (IMPF.DATA_INIZIO BETWEEN P_DATA_INIZIO AND P_DATA_FINE
            OR IMPF.DATA_FINE BETWEEN P_DATA_INIZIO AND P_DATA_FINE
           )
       )
);
--
--
begin
 --
    -- dbms_output.put_line (sysdate);
     --
     for e_r in elenco_record loop
  --
      if      (e_r.INTERM_ERRATO = 'N' AND e_r.SOGGETTO_ERRATO = 'N' AND e_r.CLIENTE_ERRATO = 'N' AND e_r.FRUITORE_ERRATO = 'N')
      then
          -- dbms_output.put_line('record '||e_r.id_piano||'-'||e_r.id_ver_piano);
           C_set.id_piano := e_r.id_piano;
           C_set.id_ver_piano := e_r.id_ver_piano;

           pipe ROW(C_set);
         end if;
     --
     end loop;
     --
      -- dbms_output.put_line (sysdate);
return;

END;
    

END PAOLO_PROVA;
/

