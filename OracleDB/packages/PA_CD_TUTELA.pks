CREATE OR REPLACE PACKAGE VENCD.PA_CD_TUTELA AS
                         
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione della
--              tutela ai minori
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Simone Bottani, Altran, Giugno 2010
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: 
-- --------------------------------------------------------------------------------------------

TYPE R_SETTORE_NIELSEN IS RECORD
(
    a_cod_settore                NIELSETT.COD_SETT_MERC%TYPE,
    a_des_settore                NIELSETT.DES_SETT_MERC%TYPE
);
TYPE C_SETTORE_NIELSEN IS REF CURSOR RETURN R_SETTORE_NIELSEN;

TYPE R_CAT_NIELSEN IS RECORD
(
    a_cod_categoria              NIELSCAT.COD_CAT_MERC%TYPE,
    a_des_categoria              NIELSCAT.DES_CAT_MERC%TYPE
);
TYPE C_CAT_NIELSEN IS REF CURSOR RETURN R_CAT_NIELSEN;

TYPE R_CLASSE_NIELSEN IS RECORD
(
    a_cod_classe                NIELSCAT.COD_CAT_MERC%TYPE,
    a_des_classe                NIELSCAT.DES_CAT_MERC%TYPE
);
TYPE C_CLASSE_NIELSEN IS REF CURSOR RETURN R_CLASSE_NIELSEN;

TYPE R_MERCEOLOGIE IS RECORD
(
    a_id_merceologia             CD_MERCEOLOGIE_SPECIALI.ID_MERCEOLOGIE_SPECIALI%TYPE,
    a_cod_settore                NIELSETT.COD_SETT_MERC%TYPE,
    a_des_settore                NIELSETT.DES_SETT_MERC%TYPE,
    a_cod_categoria              NIELSCAT.COD_CAT_MERC%TYPE,
    a_des_categoria              NIELSCAT.DES_CAT_MERC%TYPE,
    a_cod_classe                 NIELSCAT.COD_CAT_MERC%TYPE,
    a_des_classe                 NIELSCAT.DES_CAT_MERC%TYPE,
    a_id_limitazione             CD_LIMITAZIONI_TUTELA.ID_LIMITAZIONI_TUTELA%TYPE,
    a_des_limitazione            CD_LIMITAZIONI_TUTELA.DESCRIZIONE%TYPE
);
TYPE C_MERCEOLOGIE IS REF CURSOR RETURN R_MERCEOLOGIE;

TYPE R_CLIENTE IS RECORD
(
    a_id_cliente                 CLICOMM.COD_INTERL%TYPE,
    a_rag_soc_cogn               CLICOMM.RAGSOC%TYPE
);
TYPE C_CLIENTE IS REF CURSOR RETURN R_CLIENTE;

TYPE R_CLIENTE_SPECIALE IS RECORD
(
    a_id_cliente                 CD_CLIENTI_SPECIALI.ID_CLIENTE%TYPE,
    a_id_cliente_speciale        CD_CLIENTI_SPECIALI.ID_CLIENTI_SPECIALI%TYPE,
    a_rag_soc_cogn               VI_CD_CLIENTE.RAG_SOC_COGN%TYPE,
    a_id_limitazione_tutela      CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE,
    a_cod_limitazione_tutela     CD_LIMITAZIONI_TUTELA.CODICE%TYPE,
    a_des_limitazione_tutela     CD_LIMITAZIONI_TUTELA.DESCRIZIONE%TYPE
);
TYPE C_CLIENTE_SPECIALE IS REF CURSOR RETURN R_CLIENTE_SPECIALE;

TYPE R_LIMITAZIONE_TUTELA IS RECORD
(
    a_id_limitazione_tutela      CD_LIMITAZIONI_TUTELA.ID_LIMITAZIONI_TUTELA%TYPE,
    a_cod_limitazione_tutela     CD_LIMITAZIONI_TUTELA.CODICE%TYPE,
    a_descrizione     CD_LIMITAZIONI_TUTELA.DESCRIZIONE%TYPE
);
TYPE C_LIMITAZIONE_TUTELA IS REF CURSOR RETURN R_LIMITAZIONE_TUTELA;

FUNCTION FU_SETTORI_NIELSEN RETURN C_SETTORE_NIELSEN;

FUNCTION FU_CAT_NIELSEN(p_cod_settore NIELSCAT.NS_COD_SETT_MERC%TYPE) RETURN C_CAT_NIELSEN;

FUNCTION FU_CLASSI_NIELSEN(p_categoria NIELSCL.NT_COD_CAT_MERC%TYPE) RETURN C_CLASSE_NIELSEN;

PROCEDURE PR_AGGIUNGI_MERC_SPECIALE(p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE,
                                           p_cod_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                                           p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE,
                                           p_limitazione_tutela CD_MERCEOLOGIE_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE);

FUNCTION FU_MERCEOLOGIE_TUTELA(p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE, 
                           p_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                           p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE,
                           p_id_limitazione CD_MERCEOLOGIE_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE
                           ) RETURN C_MERCEOLOGIE;
                           
FUNCTION FU_CLIENTI_NO_TUTELA RETURN C_CLIENTE;
                           
FUNCTION FU_CLIENTI_SPECIALI(p_id_cliente CD_CLIENTI_SPECIALI.ID_CLIENTE%TYPE,
                             p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE) RETURN C_CLIENTE;
                             
FUNCTION FU_LIMITAZIONI_CLIENTI_SPEC(p_id_cliente CD_CLIENTI_SPECIALI.ID_CLIENTE%TYPE,
                             p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE) RETURN C_CLIENTE_SPECIALE;
                             
FUNCTION FU_LIMITAZIONI_TUTELA RETURN C_LIMITAZIONE_TUTELA;

PROCEDURE PR_MODIFICA_MERC_SPECIALE(p_id_merceologia CD_MERCEOLOGIE_SPECIALI.ID_MERCEOLOGIE_SPECIALI%TYPE,
                                    p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE,
                                    p_cod_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                                    p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE,
                                    p_limitazione_tutela CD_MERCEOLOGIE_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE);

PROCEDURE PR_ELIMINA_MERC_SPECIALE(p_id_merceologia CD_MERCEOLOGIE_SPECIALI.ID_MERCEOLOGIE_SPECIALI%TYPE);

PROCEDURE PR_INSERISCI_CLIENTE_SPECIALE(p_id_cliente CD_CLIENTI_SPECIALI.ID_CLIENTE%TYPE,
                                        p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE);
                      
PROCEDURE PR_MODIFICA_CLIENTE_SPECIALE(p_id_cliente_speciale CD_CLIENTI_SPECIALI.ID_CLIENTI_SPECIALI%TYPE,
                                       p_id_limitazione CD_CLIENTI_SPECIALI.ID_LIMITAZIONI_TUTELA%TYPE,
                                       p_esito OUT NUMBER);
                                       
PROCEDURE PR_ANNULLA_CLIENTE_SPECIALE(p_id_cliente_speciale CD_CLIENTI_SPECIALI.ID_CLIENTI_SPECIALI%TYPE);      


PROCEDURE PR_TUTELA_CLIENTE(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_tipo_modifica INTEGER);

PROCEDURE PR_TUTELA_MERCEOLOGIA( p_cod_settore CD_MERCEOLOGIE_SPECIALI.COD_SETTORE%TYPE,
                                 p_cod_categoria CD_MERCEOLOGIE_SPECIALI.COD_CATEGORIA%TYPE,
                                 p_cod_classe CD_MERCEOLOGIE_SPECIALI.COD_CLASSE%TYPE);

PROCEDURE PR_ANNULLA_PER_TUTELA(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                p_id_ver_piano CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE,
                                p_id_soggetto CD_COMUNICATO.ID_SOGGETTO_DI_PIANO%TYPE,
                                p_id_materiale CD_COMUNICATO.ID_MATERIALE_DI_PIANO%TYPE);
                                
FUNCTION FU_VERIFICA_TUTELA(P_ID_CLIENTE_COMM VI_CD_CLIENTE.ID_CLIENTE%TYPE, 
                       P_ID_SOGGETTO_DI_PIANO CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE, 
                       P_ID_MATERIALE_DI_PIANO CD_MATERIALE_DI_PIANO.ID_MATERIALE_DI_PIANO%TYPE) RETURN CHAR;                                

END PA_CD_TUTELA; 
/

