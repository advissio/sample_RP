CREATE OR REPLACE PACKAGE VENCD.PA_CD_SALTO_SALE_PARZIALI AS
/******************************************************************************
   NAME:       PA_CD_RECUPERO_SALE_PARZIALI
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27/05/2011             1. Created this package.
******************************************************************************/

  
TYPE R_SALA IS RECORD
(
   a_num_volte_settimana NUMBER,
   a_numero_prodotti     NUMBER,
   a_id_cinema           CD_CINEMA.ID_CINEMA%TYPE,
   a_nome_cinema         CD_CINEMA.NOME_CINEMA%TYPE,
   a_id_sala             CD_SALA.ID_SALA%TYPE,
   a_nome_sala           CD_SALA.NOME_SALA%TYPE,
   a_comune              CD_COMUNE.COMUNE%TYPE
);
TYPE C_SALA IS REF CURSOR RETURN R_SALA;


TYPE  R_PRODOTTO IS RECORD
(
   a_id_prodotto_acquistato  CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
   a_cliente                 INTERL_U.RAG_SOC_COGN%TYPE,
   a_piano                   varchar2(100),
   a_circuito                CD_CIRCUITO.NOME_CIRCUITO%TYPE,
   a_modalita_vendita        CD_MODALITA_VENDITA.DESC_MOD_VENDITA%TYPE,
   a_tipo_break              CD_TIPO_BREAK.DESC_TIPO_BREAK%TYPE,
   a_data_erogazione         CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
   a_disattivata             CD_COMUNICATO.COD_DISATTIVAZIONE%TYPE,
   a_break_vendita_annullato CD_BREAK_VENDITA.FLG_ANNULLATO%TYPE, 
   a_durata                  CD_COEFF_CINEMA.DURATA%TYPE
);

TYPE C_PRODOTTO IS REF CURSOR RETURN R_PRODOTTO;

FUNCTION FU_CERCA_SALE(p_id_cinema cd_cinema.id_cinema%type, p_id_sala cd_sala.id_sala%type, p_data_inizio date, p_data_fine date ) RETURN C_SALA;
FUNCTION FU_ELENCO_PRODOTTI(p_data_inizio date, p_data_fine date, p_id_sala cd_sala.id_sala%type) return c_prodotto;
PROCEDURE PR_SALTA_SALA_PRODDOTTO(p_id_sala cd_sala.id_sala%type, 
                                  p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type
                                 );
PROCEDURE PR_RECUPERA_SALA_PRODOTTO(p_id_sala cd_sala.id_sala%type, 
                                     p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type
                                 );                                 
END PA_CD_SALTO_SALE_PARZIALI; 
/

