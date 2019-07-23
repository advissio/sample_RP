CREATE OR REPLACE PACKAGE VENCD.PA_CD_UTILITY IS

GL_TRIGGERINSCINEMA             VARCHAR2(3):='ON';
GL_TRIGGERINSATRIO              VARCHAR2(3):='ON';
GL_TRIGGERINSBREAK              VARCHAR2(3):='ON';
GL_TRIGGERINSCIRCUITO           VARCHAR2(3):='ON';
GL_TRIGGERINSFASCIA             VARCHAR2(3):='ON';
GL_TRIGGERINSGENERE             VARCHAR2(3):='ON';
GL_TRIGGERINSLISTINO            VARCHAR2(3):='ON';
GL_TRIGGERINSPRODOTTOVENDITA    VARCHAR2(3):='ON';
GL_TRIGGERINSPROIEZIONE         VARCHAR2(3):='ON';
GL_TRIGGERINSSALA               VARCHAR2(3):='ON';
GL_TRIGGERINSSCHERMO            VARCHAR2(3):='ON';
GL_TRIGGERINSSCONTOSTAGIONALE   VARCHAR2(3):='ON';
GL_TRIGGERINSSPETTACOLO         VARCHAR2(3):='ON';
GL_TRIGGERINSTARIFFA            VARCHAR2(3):='ON';
GL_TRIGGERINSTIPOAUDIO          VARCHAR2(3):='ON';
GL_TRIGGERINSTIPOBREAK          VARCHAR2(3):='ON';

--
-- ----------------------------------------------------------------------------------------------
-- DESCRIZIONE:
--    Il package contiene procedure e/o funzioni invocate dai DBTriggers
--    per l'implementazione di business rules.
--
-- BUSINESS RULES:
--    1) Tutte le operazioni di modifica registrano le loro caratteristiche (ovvero
--       utente, data e ora) in appositi campi della tabella.
--
--
-- PROCEDURE/FUNZIONI:
--
--    1) PR_TIMESTAMP_MODIFICA: implementa la business rule 1)
-- ----------------------------------------------------------------------------------------------
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
-- ----------------------------------------------------------------------------------------------
-- AGGIUNTE:
-- ----------------------------------------------------------------------------------------------
-- MODIFICHE:
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
TYPE R_PRODOTTO_DATA IS RECORD
(
    a_id_prodotto             cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%type,
    a_data_min_comunicato     cd_comunicato.data_erogazione_prev%type,
    a_data_max_comunicato     cd_comunicato.data_erogazione_prev%type,
    a_data_inizio             cd_prodotto_acquistato.data_inizio%type,
    a_data_fine               cd_prodotto_acquistato.data_fine%type
);

TYPE C_PRODOTTO_DATA IS REF CURSOR RETURN R_PRODOTTO_DATA;

/*PROCEDURE PR_TIMESTAMP_MODIFICA(
   P_NEW_UTEMOD  IN OUT VARCHAR2,
   P_NEW_DATAMOD IN OUT DATE );*/
   
   
PROCEDURE PR_TIMESTAMP_MODIFICA(
    P_NEW_UTEMOD  IN OUT VARCHAR2,
    P_NEW_DATAMOD IN OUT DATE,
    P_ABILITATO BOOLEAN );   


PROCEDURE PR_SET_STATO_TR_INS_CINEMA(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_CINEMA RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_ATRIO(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_ATRIO RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_BREAK(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_BREAK RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_CIRCUITO(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_CIRCUITO RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_FASCIA(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_FASCIA RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_GENERE(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_GENERE RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_LISTINO(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_LISTINO RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_PROD_VEND(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_PROD_VEND RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_PROIEZIONE(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_PROIEZIONE RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_SALA(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_SALA RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_SCHERMO(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_SCHERMO RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_SCON_STAG(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_SCON_STAG RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_SPETTACOLO(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_SPETTACOLO RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_TARIFFA(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_TARIFFA RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_TIPO_AUDIO(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_TIPO_AUDIO RETURN VARCHAR2;
--
PROCEDURE PR_SET_STATO_TR_INS_TIPO_BREAK(P_VAL VARCHAR2 DEFAULT 'ON');
--
FUNCTION FU_STATO_TR_INS_TIPO_BREAK RETURN VARCHAR2;

FUNCTION FU_CALCOLA_IMPORTO(p_lordo NUMBER, p_sconto NUMBER) RETURN NUMBER;
PROCEDURE lock_package(p_package_name varchar2);
--PROCEDURE unlock_package(p_package_name varchar2);
PROCEDURE PR_CORREGGI_TARIFFE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE);

PROCEDURE PR_CORREGGI_TARIFFE_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE);

FUNCTION FU_DETTAGLIO_PRODOTTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2;

function fu_verifica_date_prodotti return c_prodotto_data;

PROCEDURE PR_CORREGGI_DGC;

PROCEDURE PR_RIPRISTINA_PROIEZIONE_PIANO(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type, p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE);

FUNCTION GET_DAY(P_DAY_NUM CHAR) RETURN VARCHAR2;

FUNCTION GET_DAY_NUM(P_DAY VARCHAR2) RETURN CHAR;

PROCEDURE PR_VERIFICA_IMPORTI;

PROCEDURE PR_VERIFICA_SALTO_RECUPERO;

PROCEDURE PR_ELIMINA_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE);

FUNCTION SPLIT (p_in_string VARCHAR2, p_delim VARCHAR2) RETURN id_list_type;

PROCEDURE PR_ABILITA_TRIGGER(P_ABILITA CHAR);

FUNCTION FU_TRIGGER_ON RETURN CHAR;

PROCEDURE scrivi_trace(p_prog NUMBER, p_testo VARCHAR2);

PROCEDURE PR_RECUPERA_SALA(p_id_sala CD_COMUNICATO.ID_SALA%TYPE, p_data_inizio DATE, p_data_fine DATE);

PROCEDURE PR_ELIMINA_VALORE_VETT(p_vett IN OUT id_list_type, p_valore INTEGER);

procedure  pr_disassocia_sale_reali(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,p_numero_sale number, p_giorno date);
END; 
/

