CREATE OR REPLACE PACKAGE VENCD.PA_CD_TARGET_NEW AS
                         
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione dei target
--              e dell'associazione agli spettacoli
-- --------------------------------------------------------------------------------------------
-- REALIZZATORE  Simone Bottani, Altran, Giugno 2010
-- --------------------------------------------------------------------------------------------
-- MODIFICHE: 
-- --------------------------------------------------------------------------------------------

TYPE R_TARGET IS RECORD
(
    a_id_target                  CD_TARGET.ID_TARGET%TYPE,
    a_nome_target                CD_TARGET.NOME_TARGET%TYPE,
    a_desc_target                CD_TARGET.DESCR_TARGET%TYPE
);
TYPE C_TARGET IS REF CURSOR RETURN R_TARGET;

TYPE R_SALE_ASSOCIATE IS RECORD
(
    a_id_sala                   CD_SALA.ID_SALA%TYPE,
    a_nome_sala                 CD_SALA.NOME_SALA%TYPE,
    a_nome_circuito             CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_nome_cinema               CD_CINEMA.NOME_CINEMA%TYPE,
    a_comune                    CD_COMUNE.COMUNE%TYPE,
    a_provincia_abbr            CD_PROVINCIA.ABBR%TYPE,
    a_data_inizio               CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    a_data_fine                 CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    a_flg_virtuale              CD_CINEMA.FLG_VIRTUALE%TYPE
);
TYPE C_SALE_ASSOCIATE IS REF CURSOR RETURN R_SALE_ASSOCIATE;

TYPE R_SALE_ASSOCIABILI IS RECORD
(
   -- a_nome_circuito             CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_nome_cinema               CD_CINEMA.NOME_CINEMA%TYPE,
    a_comune                    CD_COMUNE.COMUNE%TYPE,
    a_id_sala                   CD_SALA.ID_SALA%TYPE,
    a_nome_sala                 CD_SALA.NOME_SALA%TYPE,
    a_giorni_disponibili        VARCHAR2(100),
    --a_provincia_abbr            CD_PROVINCIA.ABBR%TYPE,
--    a_data_proiezione           CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
    a_affollamento              NUMBER
);
TYPE C_SALE_ASSOCIABILI IS REF CURSOR RETURN R_SALE_ASSOCIABILI;

TYPE R_PRODOTTI_TARGET IS RECORD
(
   -- a_nome_circuito             CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_id_target                 CD_PRODOTTO_VENDITA.ID_TARGET%TYPE,
    a_desc_target               CD_TARGET.DESCR_TARGET%TYPE,
    a_nome_circuito             CD_CIRCUITO.NOME_CIRCUITO%TYPE,
    a_desc_tipo_break           CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
    a_durata                    CD_COEFF_CINEMA.DURATA%TYPE,
    a_id_piano                  CD_PIANIFICAZIONE.ID_PIANO%TYPE,
    a_id_ver_piano              CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
    a_cliente                   INTERL_U.RAG_SOC_COGN%TYPE,
    a_num_sale_associate        NUMBER,
    a_num_sale_prodotto         NUMBER,
    a_stato_vendita             CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE
);
TYPE C_PRODOTTI_TARGET IS REF CURSOR RETURN R_PRODOTTI_TARGET;


/*TYPE R_PRODOTTO_SALA IS RECORD
(
    --a_id_prodotto_acquistato    CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_id_sala                   CD_SCHERMO_VIRTUALE_PRODOTTO.ID_SCHERMO_VIRTUALE%TYPE
);

TYPE vett_prodotti_sala IS TABLE OF R_PRODOTTO_SALA INDEX BY PLS_INTEGER;
*/

TYPE R_PROD_TEMP IS RECORD
(
    a_id_prodotto_acquistato  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_prodotti_sala           id_list_type,
    a_esito                   NUMBER,
    a_num_sale                NUMBER,
    a_giorni_disponibili      id_list_type,
    a_durata                  NUMBER
);

TYPE v_hash_type IS TABLE OF R_PROD_TEMP INDEX BY PLS_INTEGER;

TYPE R_SALE_SETTIMANA IS RECORD
(
    a_data DATE,
    a_num_schermi NUMBER
);
TYPE C_SALE_SETTIMANA IS REF CURSOR RETURN R_SALE_SETTIMANA;


FUNCTION FU_GET_TARGET(p_nome_target CD_TARGET.NOME_TARGET%TYPE, p_descrizione CD_TARGET.DESCR_TARGET%TYPE) RETURN C_TARGET;
--
PROCEDURE PR_AGGIUNGI_TARGET(p_nome_target CD_TARGET.NOME_TARGET%TYPE,p_descrizione CD_TARGET.DESCR_TARGET%TYPE);
--
PROCEDURE PR_ELIMINA_TARGET(p_id_target CD_TARGET.ID_TARGET%TYPE);
--
PROCEDURE PR_MODIFICA_TARGET(p_id_target CD_TARGET.ID_TARGET%TYPE, p_nome_target CD_TARGET.NOME_TARGET%TYPE,p_descrizione CD_TARGET.DESCR_TARGET%TYPE);
--
PROCEDURE PR_ASSOCIA_TARGET_SPET_MASS(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE, p_target id_list_type);
--
PROCEDURE PR_ASSOCIA_SPETTACOLO_TARGET(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE);
--
PROCEDURE PR_DISSOCIA_SPETTACOLO_TARGET(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE);
--
FUNCTION FU_GET_TARGET_SPETTACOLO(p_id_spettacolo CD_SPETTACOLO.ID_SPETTACOLO%TYPE) RETURN C_TARGET;

FUNCTION FU_GET_SALE_ASSOCIATE(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_mostra_sale_non_visibili BOOLEAN) RETURN C_SALE_ASSOCIATE;

FUNCTION FU_GET_SALE_ASSOCIABILI(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_durata CD_COEFF_CINEMA.DURATA%TYPE) RETURN C_SALE_ASSOCIABILI;

PROCEDURE PR_ASSOCIA_SALE_VIRTUALI(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_soglia id_list_type);

FUNCTION FU_PRODOTTI_TARGET(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE) RETURN C_PRODOTTI_TARGET;

FUNCTION FU_NUM_SCHERMI_REALI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN NUMBER;

PROCEDURE PR_ASSOCIA_SETTIMANA_TARGET(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_durata CD_COEFF_CINEMA.DURATA%TYPE, p_prodotti_sala IN OUT id_list_type, p_giorni_disponibili IN OUT id_list_type, p_soglia id_list_type, p_esito OUT NUMBER);

PROCEDURE PR_CREA_SCHERMI_VIRTUALI(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_soglia id_list_type);

PROCEDURE PR_AGGIUNGI_SALE_VIRTUALI_VETT(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_prodotti_sala OUT id_list_type);

FUNCTION FU_SALE_IDONEE(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) RETURN C_SALE_SETTIMANA;

FUNCTION FU_SALE_IDONEE_DISPONIBILI(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) RETURN C_SALE_SETTIMANA;

FUNCTION FU_SALE_GIORNO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_giorno CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE) RETURN C_SALE_SETTIMANA;

PROCEDURE PR_ANNULLA_SALE_NON_ASSEGNATE(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_stato_vendita CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,  p_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE, p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE, p_id_target CD_TARGET.ID_TARGET%TYPE);

PROCEDURE PR_RICALCOLA_TARIFFA(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE);

FUNCTION FU_GET_SALA_TARGET_GIORNO(p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_giorno CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE, p_durata CD_COEFF_CINEMA.DURATA%TYPE) RETURN CD_COMUNICATO.ID_SALA%TYPE;

FUNCTION FU_GET_SALE_VIRTUALI_CIRCUITO(p_id_circuito CD_CIRCUITO.ID_CIRCUITO%TYPE) RETURN NUMBER;

FUNCTION FU_SOGLIE_PERIODO(p_id_cliente CD_PIANIFICAZIONE.ID_CLIENTE%TYPE, p_id_target CD_PRODOTTO_VENDITA.ID_TARGET%TYPE, p_data_inizio CD_PROIEZIONE.DATA_PROIEZIONE%TYPE, p_data_fine CD_PROIEZIONE.DATA_PROIEZIONE%TYPE) RETURN C_SALE_SETTIMANA;

END PA_CD_TARGET_NEW; 
/

