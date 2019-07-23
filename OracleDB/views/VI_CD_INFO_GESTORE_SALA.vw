CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_INFO_GESTORE_SALA
(ID_GESTORE, EMAIL, ID_CINEMA, NOME_CINEMA, ID_SALA, 
 NOME_SALA)
AS 
SELECT
-----------------------------------------------------------------------------------------------------
-- VISTA VI_CD_INFO_GESTORE_SALA
--
-- Estrae l'indirizzo e-mail relativo al gestore insieme a nome di cinema e sale
-- a lui associate
--
-- REALIZZATORE: Tommaso D'Anna, Teoresi s.r.l. 30/11/2010
-----------------------------------------------------------------------------------------------------
        GESTORI_UTENTE.ID AS ID_GESTORE,
        GESTORI_UTENTE.EMAIL,
        CD_CINEMA.ID_CINEMA,
        CD_CINEMA.NOME_CINEMA,
        CD_SALA.ID_SALA,
        CD_SALA.NOME_SALA
FROM    GESTORI_UTENTE,
        GESTORI_UTENTE_CINEMA,
        CD_CINEMA,
        CD_SALA
WHERE   GESTORI_UTENTE.ID = GESTORI_UTENTE_CINEMA.ID_UTENTE
AND     GESTORI_UTENTE_CINEMA.ID_CINEMA = CD_CINEMA.ID_CINEMA
AND     CD_CINEMA.ID_CINEMA = CD_SALA.ID_CINEMA
/



