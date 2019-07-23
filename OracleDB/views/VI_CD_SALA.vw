CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_SALA
(ID, ID_CINEMA, NOME)
AS 
SELECT 
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_SALA
--
-- Estrae la lista delle sale disponibili a sistema
--
-- REALIZZATORE: Antonio Colucci, Teoresi s.r.l. 26/10/2009
--
-- MODIFICHE:
--    27/04/2010    Angelo Marletta
--                      Esclusione arene
--    28/06/2010    Angelo Marletta
--                      Esclusione sale virtuali
--    03/01/2011    Mauro Viel, Altran 
--                      Inserita gestione del nome cinema
--    09/06/2011    Mauro Viel, Altran 
--                      Inserita clausola sul flg_attivo del cinema
--    13/07/2011    Tommaso D'Anna, Teoresi srl
--                      Rimosso flg_attivo e sostituito con data_inizio_validita
-----------------------------------------------------------------------------------------------------
    CD_SALA.ID_SALA as ID, CD_SALA.ID_CINEMA, CD_SALA.NOME_SALA AS NOME 
FROM CD_SALA, CD_CINEMA
    where CD_SALA.ID_CINEMA = CD_CINEMA.ID_CINEMA
    and CD_SALA.flg_annullato = 'N' and CD_SALA.flg_arena = 'N' and CD_CINEMA.flg_virtuale = 'N'
    --AND CD_CINEMA.FLG_ATTIVO='S'
    AND    CD_SALA.DATA_INIZIO_VALIDITA  <= trunc(SYSDATE)
    AND    nvl(CD_SALA.DATA_FINE_VALIDITA, trunc(SYSDATE)) >= trunc(SYSDATE)
/



