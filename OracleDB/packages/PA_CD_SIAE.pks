CREATE OR REPLACE PACKAGE VENCD.PA_CD_SIAE AS
/******************************************************************************
   NAME:       PA_CD_SIAE
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/02/2010             1. Created this package.
******************************************************************************/
TYPE R_PLAYLIST IS RECORD
(
    a_data_erogazione_prev       VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
    a_id_sala                    VI_CD_COMUNICATO_SALA.ID_SALA%TYPE,
    a_id_materiale               CD_MATERIALE.ID_MATERIALE%TYPE
);
TYPE C_PLAYLIST IS REF CURSOR RETURN R_PLAYLIST;

TYPE R_MATERIALE IS RECORD
(
    a_id_materiale       CD_MATERIALE.ID_MATERIALE%TYPE,
    a_titolo             CD_MATERIALE.TITOLO%TYPE,
    a_durata             CD_MATERIALE.DURATA%TYPE,
    a_rag_soc_cogn       VI_CD_CLIENTE.RAG_SOC_COGN%TYPE,
    a_autore             CD_COLONNA_SONORA.AUTORE%TYPE,
    a_titolo_colonna     CD_COLONNA_SONORA.TITOLO%TYPE,
    a_nota               CD_COLONNA_SONORA.NOTA%TYPE
);
TYPE C_MATERIALE IS REF CURSOR RETURN R_MATERIALE;


TYPE R_SALA IS RECORD
(
    a_id_sala           CD_SALA.ID_SALA%TYPE,
    a_id_cinema         CD_CINEMA.ID_CINEMA%TYPE,
    a_nome_cinema       CD_CINEMA.NOME_CINEMA%TYPE
);
TYPE C_SALA IS REF CURSOR RETURN R_SALA;

TYPE R_CINEMA_SALA IS RECORD
(
    a_id_cinema     CD_CINEMA.ID_CINEMA%TYPE,
    a_comune        CD_COMUNE.COMUNE%TYPE,
    a_indirizzo     CD_CINEMA.INDIRIZZO%TYPE,
    a_nome_cinema   CD_CINEMA.NOME_CINEMA%TYPE,
    a_id_sala       CD_SALA.ID_SALA%TYPE,
    a_nome_sala     CD_SALA.NOME_SALA%TYPE
);
TYPE C_CINEMA_SALA IS REF CURSOR RETURN R_CINEMA_SALA;

FUNCTION FU_GET_PLAYLIST_XML(p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                             p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE) RETURN C_PLAYLIST;
FUNCTION FU_GET_MATERIALI_XML(p_data_inizio cd_comunicato.DATA_EROGAZIONE_PREV%TYPE,
                              p_data_fine cd_comunicato.DATA_EROGAZIONE_PREV%TYPE) RETURN C_MATERIALE;
FUNCTION FU_GET_SALE_XML RETURN C_SALA;
FUNCTION FU_GET_CINEMA_SALA_XML RETURN C_CINEMA_SALA;
PROCEDURE PR_CREA_PLAYLIST_XML (p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                p_esito       IN OUT NUMBER);
PROCEDURE PR_CREA_MATERIALI_XML (p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                p_esito       IN OUT NUMBER);
PROCEDURE PR_CREA_SALE_XML (p_esito IN OUT NUMBER);
PROCEDURE PR_CREA_CINEMA_SALA_XML (p_esito IN OUT NUMBER);



PROCEDURE SET_XML_PATH(V_PATH VARCHAR2);

END PA_CD_SIAE; 
/

