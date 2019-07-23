CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_ORDINI_CM IS
--
------------------------------------------------------------------------------------------
-- Procedura ESTRAI_DATI
--   Popola la tavola CM_ORD_ATT_CM con gli ordini in condizione di pagamento "CAMBIO MERCE"
--   relativi al periodo indicato:
--
-- INPUT: 
--        data inizio e data fine periodo
--
-- OUTPUT: esito   1 OK
--                -1 Errore
--
-- REALIZZATORE: Luigi Cipolla, 02/05/2010
--
-- MODIFICHE: 
------------------------------------------------------------------------------------------
Procedure ESTRAI_DATI 
  (P_DATA_INIZIO   in date,
   P_DATA_FINE     in date,
   P_ESITO         out number,
   P_DES_ESITO     out varchar2 )
is
begin
  --
  insert into CM_ORD_ATT_CM(
              GEST_COMM,
              COD_PIANO,
              VERS_PIANO,
              PROGR_ORD,
              COD_CLIENTE,
              DATA_ORD,
              DATA_INIZ,
              DATA_FINE,
              IMP_LORDO,
              IMP_LORDO_EURO,
              IMP_NETTO,
              IMP_NETTO_EURO,
              IMP_SSDA,
              IMP_SSDA_EURO,
              FLAG_ANN )
  ( select PA_CD_MEZZO.FU_GEST_COMM GEST_COMM, O.ID_PIANO, O.ID_VER_PIANO, O.COD_PRG_ORDINE, pi.id_cliente, null
          , min(O.DATA_INIZIO) DATA_INIZIO, max(O.DATA_FINE) DATA_FINE,0,0 LORDO_E,0, 0 NETTO_E,0, 0 SSDA_E, O.FLG_ANNULLATO
    from cond_pagamento CP,
         cd_pianificazione PI,
         cd_ordine O
    where O.FLG_ANNULLATO = 'S'
      and ( DATA_INIZIO between P_DATA_INIZIO and P_DATA_FINE
          or
            DATA_FINE between P_DATA_INIZIO and P_DATA_FINE)
      and PI.ID_PIANO = O.ID_PIANO
      and PI.ID_VER_PIANO = O.ID_VER_PIANO
      and CP.cod_cpag = O.id_cond_pagamento
      and FU_PC_CAMBIO_MERCE (CP.nat_cpag, O.id_cond_pagamento) = 'S'
      group by O.ID_PIANO, O.ID_VER_PIANO, O.COD_PRG_ORDINE, O.FLG_ANNULLATO, O.id_cond_pagamento, pi.id_cliente
    union
    select GEST_COMM, ID_PIANO, ID_VER_PIANO, COD_PRG_ORDINE, id_cliente, null
          , DATA_INIZIO, DATA_FINE, 0
          , PA_PC_IMPORTI.FU_LORDO_COMM_2(IMPORTO_NETTO, PERC_SC_COMM) LORDO_E
          ,0 , NETTO_E, 0
          , SSDA_E, FLG_ANNULLATO
   from
   (
   select PA_CD_MEZZO.FU_GEST_COMM GEST_COMM, O.ID_PIANO, O.ID_VER_PIANO, O.COD_PRG_ORDINE, pi.id_cliente
          , min(IFA.DATA_INIZIO) DATA_INIZIO, max(IFA.DATA_FINE) DATA_FINE
          , sum(IFA.IMPORTO_NETTO) IMPORTO_NETTO, PA_PC_IMPORTI.FU_PERC_SC_COMM(sum(IP.IMP_NETTO), sum(IP.IMP_SC_COMM)) PERC_SC_COMM
          , sum(IFA.IMPORTO_NETTO) NETTO_E
          , sum(IFA.IMPORTO_NETTO/100*IFA.PERC_SCONTO_SOST_AGE) SSDA_E, O.FLG_ANNULLATO
    from cond_pagamento CP,
         cd_pianificazione PI,
         cd_ordine O,
         cd_importi_prodotto IP,
         cd_importi_fatturazione IFA
    where ( IFA.DATA_INIZIO between P_DATA_INIZIO and P_DATA_FINE
           or
            IFA.DATA_FINE between P_DATA_INIZIO and P_DATA_FINE)
      and IFA.FLG_SOSPESO = 'N'
      and IFA.FLG_INCLUSO_IN_ORDINE = 'S'
      and IFA.FLG_ANNULLATO = 'N'
      and IP.id_importi_prodotto = IFA.id_importi_prodotto
      and O.id_ordine = IFA.id_ordine
      and PI.ID_PIANO = O.ID_PIANO
      and PI.ID_VER_PIANO = O.ID_VER_PIANO
      and CP.cod_cpag = O.id_cond_pagamento
      and FU_PC_CAMBIO_MERCE (CP.nat_cpag, O.id_cond_pagamento) = 'S'
    group by O.ID_PIANO, O.ID_VER_PIANO, O.COD_PRG_ORDINE, O.FLG_ANNULLATO, O.id_cond_pagamento, pi.id_cliente
    )
    where PERC_SC_COMM <100
  );
  --
  P_ESITO := 1;
EXCEPTION
  WHEN others THEN
    P_ESITO := -1 ;
    P_DES_ESITO := to_char(sqlcode) ||' - '|| sqlerrm;
end;
--
--
------------------------------------------------------------------------------------------
-- Funzione FU_COND_PAG
--   Restituisce la condizione di pagamento dell'ordine in input.
--   In caso di ordine inesistente, restituisce 'XX'.
--
-- INPUT: 
--        chiave di ordine
--
-- REALIZZATORE: Luigi Cipolla, 02/05/2010
--
-- MODIFICHE: 
------------------------------------------------------------------------------------------
Function FU_COND_PAG
  (P_COD_PIANO in number,
   P_VERS_PIANO in number,
   P_PRG_ORDINE in number ) return varchar2
IS
  CAMBIO_MERCE varchar2(2) := 'XX';
begin
  select id_cond_pagamento
  into CAMBIO_MERCE
  from cd_ordine
  where ID_PIANO = P_COD_PIANO
    and ID_VER_PIANO = P_VERS_PIANO
    and COD_PRG_ORDINE = P_PRG_ORDINE;
  --
  return CAMBIO_MERCE;
exception
  when others then 
    return CAMBIO_MERCE;
end;
--
END; 
/

