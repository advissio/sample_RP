CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_CINEMA
(ID, INDIRIZZO, NOME, ID_COMUNE)
AS 
SELECT 
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_CINEMA
--
-- Estrae la lista dei cinema disponibili a sistema
--
-- REALIZZATORE: Antonio Colucci, Teoresi s.r.l. 26/10/2009
--
-- MODIFICHE:
--    27/04/2010    Angelo Marletta
--                      Esclusione arene
--    28/06/2010    Angelo Marletta
--                      Esclusione cinema virtuali
--    03/01/2011    Mauro Viel, Altran
--                      Inserita gestione del nome cinema
--    09/06/2011    Mauro Viel, Altran 
--                      Inserita clausola sul flg_attivo
--    13/07/2011    Tommaso D'Anna, Teoresi srl
--                      Rimosso flg_attivo e sostituito con data_inizio_validita
-----------------------------------------------------------------------------------------------------
CI.ID_CINEMA as ID, INDIRIZZO, pa_cd_cinema.FU_GET_NOME_CINEMA(ci.id_cinema,sysdate) AS NOME, --NOME_CINEMA AS NOME, 
ID_COMUNE
FROM CD_CINEMA CI WHERE ID_CINEMA IN (
    SELECT DISTINCT id_cinema FROM CD_SALA SA where SA.flg_arena = 'N')
    AND FLG_VIRTUALE = 'N'
    --AND FLG_ATTIVO='S'
    AND    CI.DATA_INIZIO_VALIDITA  <= trunc(SYSDATE)
    AND    nvl(CI.DATA_FINE_VALIDITA, trunc(SYSDATE)) >= trunc(SYSDATE)
/



