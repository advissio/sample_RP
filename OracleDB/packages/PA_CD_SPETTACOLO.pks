CREATE OR REPLACE PACKAGE VENCD.PA_CD_SPETTACOLO IS
--
v_stampa_spettacolo      VARCHAR2(3):='ON';
v_stampa_genere          VARCHAR2(3):='ON';
--
--
TYPE R_SPETTACOLO IS RECORD
(
    a_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
    a_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
    a_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
    a_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
    a_desc_genere       CD_GENERE.DESC_GENERE%TYPE,
    a_provenienza       CD_SPETTACOLO.PROVENIENZA%TYPE
);
--
TYPE C_SPETTACOLO IS REF CURSOR RETURN R_SPETTACOLO;
TYPE R_DETTAGLIO_SPETTACOLO IS RECORD
(
    a_id_spettacolo         CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
    a_nome_spettacolo       CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_durata_spettacolo     CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
    a_data_inizio           CD_SPETTACOLO.DATA_INIZIO%TYPE,
    a_data_fine             CD_SPETTACOLO.DATA_FINE%TYPE,
    a_desc_genere           CD_GENERE.DESC_GENERE%TYPE,
    a_flg_protetto          CD_SPETTACOLO.FLG_PROTETTO%TYPE,
    a_id_distributore       CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE,
    a_casa_distribuzione    CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
    a_id_genere             CD_GENERE.ID_GENERE%TYPE,
    a_provenienza           CD_SPETTACOLO.PROVENIENZA%TYPE
);
--
TYPE C_DETTAGLIO_SPETTACOLO IS REF CURSOR RETURN R_DETTAGLIO_SPETTACOLO;
--
TYPE R_SPETTACOLO_PROIEZIONE IS RECORD
(
    a_data_proiezione       CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
    a_id_spettacolo         CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
    a_nome_spettacolo       CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_ora_inizio            VARCHAR2(6),
    a_ora_fine              VARCHAR2(6),
    a_desc_genere           CD_GENERE.DESC_GENERE%TYPE,
    a_casa_distribuzione    CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE
);
--
TYPE C_SPETTACOLO_PROIEZIONE IS REF CURSOR RETURN R_SPETTACOLO_PROIEZIONE;

TYPE R_GENERE IS RECORD
(
    a_id_genere         CD_GENERE.ID_GENERE%TYPE,
    a_desc_genere       CD_GENERE.DESC_GENERE%TYPE,
    a_desc_genere_padre CD_GENERE.DESC_GENERE%TYPE
);
--
TYPE C_GENERE IS REF CURSOR RETURN R_GENERE;
--
TYPE R_DISTRIBUTORE IS RECORD
(
    a_id_distributore       CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE,
    a_casa_distribuzione    CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE
);
--
TYPE C_DISTRIBUTORE IS REF CURSOR RETURN R_DISTRIBUTORE;
--
TYPE R_SPETT_PROIEZ IS RECORD
(
    a_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
    a_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
    a_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
    a_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
    a_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
    a_id_genere         CD_SPETTACOLO.ID_GENERE%TYPE,
    a_desc_genere       CD_GENERE.DESC_GENERE%TYPE,
    a_provenienza       CD_SPETTACOLO.PROVENIENZA%TYPE,
    a_distributore      CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
    a_flg_protetto      CD_SPETTACOLO.FLG_PROTETTO%TYPE,
    a_flg_descr_target  CD_TARGET.DESCR_TARGET%TYPE
);
--
TYPE C_SPETT_PROIEZ IS REF CURSOR RETURN R_SPETT_PROIEZ;
--
TYPE R_GENERE_BASE IS RECORD
(
    a_id_genere         CD_GENERE.DESC_GENERE%TYPE,
    a_desc_genere       CD_GENERE.DESC_GENERE%TYPE,
    a_id_genere_padre   CD_GENERE.ID_GENERE_PADRE%TYPE,
    a_desc_genere_padre CD_GENERE.DESC_GENERE%TYPE,
    a_flg_protetto      CD_GENERE.FLG_PROTETTO%TYPE
);
--
TYPE C_GENERE_BASE IS REF CURSOR RETURN R_GENERE_BASE;
--
TYPE R_GENERE_SPETT IS RECORD
(
    a_id_genere         CD_GENERE.DESC_GENERE%TYPE,
    a_desc_genere       CD_GENERE.DESC_GENERE%TYPE,
    a_id_genere_padre   CD_GENERE.ID_GENERE_PADRE%TYPE,
    a_desc_genere_padre CD_GENERE.DESC_GENERE%TYPE,
    a_id_genere_spett   CD_SPETTACOLO.ID_GENERE%TYPE
);
--
TYPE C_GENERE_SPETT IS REF CURSOR RETURN R_GENERE_SPETT;
--
TYPE R_PROGRAMMAZIONE_SPETTACOLARE IS RECORD
(
    a_data_proiezione       cd_proiezione.data_proiezione%type,
    a_id_cinema             cd_cinema.id_cinema%type,
    a_nome_cinema           cd_cinema.NOME_CINEMA%type,
    a_comune                cd_comune.comune%type,
    a_id_sala               cd_sala.id_sala%type,
    a_nome_sala             cd_sala.nome_sala%type,
    a_nome_spettacolo       cd_spettacolo.nome_spettacolo%type,
    a_orario                varchar2(15),
    a_genere                cd_genere.desc_genere%type,
    a_target                cd_target.descr_target%type,
    a_flg_protetto          cd_spettacolo.flg_protetto%type
);
--
TYPE C_PROGRAMMAZIONE_SPETTACOLARE IS REF CURSOR RETURN R_PROGRAMMAZIONE_SPETTACOLARE;

TYPE R_PROGR_SPETT_SALA IS RECORD
(
    a_data_proiezione       cd_proiezione.data_proiezione%type,
    a_nome_spettacolo       cd_spettacolo.nome_spettacolo%type,
    num_sale                 number,
    a_genere                cd_genere.desc_genere%type,
    a_target                cd_target.descr_target%type,
    a_flg_protetto          cd_spettacolo.flg_protetto%type
);
--
TYPE C_PROGR_SPETT_SALA IS REF CURSOR RETURN R_PROGR_SPETT_SALA;

--
-- --------------------------------------------------------------------------------------------
-- DESCRIZIONE  Questo package contiene procedure/funzioni necessarie per la gestione degli
--              spettacoli
-- --------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_SPETTACOLO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_SPETTACOLO( p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                   p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                                   p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                                   p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
								   p_id_genere         CD_SPETTACOLO.ID_GENERE%TYPE,
                                   p_id_distributore   CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE,
                                   p_flg_protetto      CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                   p_id_gestore        CD_SPETTACOLO.ID_GESTORE%TYPE,
                                   p_target            id_list_type,
                                   p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA FU_DETTAGLIO_SPETTACOLO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DETTAGLIO_SPETTACOLO( p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE) RETURN C_DETTAGLIO_SPETTACOLO;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MOD_SPETT_CON_NULL
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_SPETTACOLO( p_id_spettacolo     CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                  p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                  p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                                  p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                                  p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
								  p_id_genere         CD_SPETTACOLO.ID_GENERE%TYPE,
                                  p_id_distributore   CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE,
                                  p_flg_protetto      CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                  p_target            id_list_type,
                                  p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_SPETTACOLO
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_SPETTACOLO(   p_id_spettacolo           IN CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                   p_esito                   OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_RIMPIAZZA
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_RIMPIAZZA(   p_id_elimina          IN CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                  p_id_rimpiazza        IN CD_SPETTACOLO.ID_SPETTACOLO%TYPE,
                                  p_esito               OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_SPETTACOLO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_SPETTACOLO(p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                              p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                              p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                              p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
							  p_desc_genere       CD_GENERE.DESC_GENERE%TYPE)
							  RETURN VARCHAR2;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_SPETTACOLO
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_SPETTACOLO(p_nome_spettacolo   CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                              p_durata_spettacolo CD_SPETTACOLO.DURATA_SPETTACOLO%TYPE,
                              p_data_inizio       CD_SPETTACOLO.DATA_INIZIO%TYPE,
                              p_data_fine         CD_SPETTACOLO.DATA_FINE%TYPE,
							  p_desc_genere       CD_GENERE.DESC_GENERE%TYPE)
							  RETURN C_SPETTACOLO;


-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_GENERE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_GENERE(p_desc_genere     CD_GENERE.DESC_GENERE%TYPE,
                              p_id_genere_padre CD_GENERE.ID_GENERE_PADRE%TYPE,
                              p_flg_protetto    CD_GENERE.FLG_PROTETTO%TYPE,
                              p_esito             OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_GENERE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_GENERE(p_id_genere       CD_GENERE.ID_GENERE%TYPE,
                             p_desc_genere     CD_GENERE.DESC_GENERE%TYPE,
                             p_id_genere_padre CD_GENERE.ID_GENERE_PADRE%TYPE,
                             p_flg_protetto    CD_GENERE.FLG_PROTETTO%TYPE,
                             p_esito             OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_ELIMINA_GENERE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_GENERE(p_id_genere       CD_GENERE.ID_GENERE%TYPE,
                            p_esito                   OUT NUMBER);

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_STAMPA_GENERE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_STAMPA_GENERE(p_desc_genere     CD_GENERE.DESC_GENERE%TYPE,
                          p_id_genere_padre CD_GENERE.ID_GENERE_PADRE%TYPE)
						  RETURN VARCHAR2;

-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_GENERE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_GENERE(p_desc_genere     CD_GENERE.DESC_GENERE%TYPE)
						 RETURN C_GENERE;
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_INSERISCI_DISTRIBUTORE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_INSERISCI_DISTRIBUTORE(p_casa_distribuzione   CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
                                    p_esito                OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_DISTRIBUTORE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_MODIFICA_DISTRIBUTORE(p_id_distributore     CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE,
                                   p_casa_distribuzione  CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
                                   p_esito             OUT NUMBER);
-- --------------------------------------------------------------------------------------------
-- PROCEDURA PR_MODIFICA_DISTRIBUTORE
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_ELIMINA_DISTRIBUTORE(p_id_distributore      CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE,
                                  p_id_distributore_new  CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE,
                                  p_esito                OUT NUMBER);
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_LISTA_DISTRIBUTORI
-- --------------------------------------------------------------------------------------------
FUNCTION FU_LISTA_DISTRIBUTORI RETURN C_DISTRIBUTORE;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_CERCA_DISTRIBUTORE
-- --------------------------------------------------------------------------------------------
FUNCTION FU_CERCA_DISTRIBUTORE(p_id_distributore CD_DISTRIBUTORE.ID_DISTRIBUTORE%TYPE)
        RETURN C_DISTRIBUTORE;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_TUTTI_GENERI  la funzione si occupa di reperire l'elenco dei generi memorizzati in tabella
-- --------------------------------------------------------------------------------------------
  FUNCTION FU_ELENCO_TUTTI_GENERI RETURN C_GENERE_BASE;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_LISTA_SPETT_DATI_PROIEZ   la funzione si occupa di reperire l'elenco degli spettacoli memorizzati in tabella
-- --------------------------------------------------------------------------------------------
  FUNCTION FU_LISTA_SPETT_DATI_PROIEZ(p_id_genere           CD_SPETTACOLO.ID_GENERE%TYPE,
                                     p_nome_spettacolo      CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                     p_provenienza          CD_SPETTACOLO.PROVENIENZA%TYPE,
                                     p_id_distributore      CD_SPETTACOLO.ID_DISTRIBUTORE%TYPE,
                                     p_flg_protetto         CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                     p_id_target            CD_TARGET.ID_TARGET%TYPE,
                                     p_data_inizio          CD_SPETTACOLO.DATA_INIZIO%TYPE,
                                     p_data_fine            CD_SPETTACOLO.DATA_FINE%TYPE)
						             RETURN C_SPETT_PROIEZ;
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_GENERI_SPETT  la funzione si occupa di reperire l'elenco di tutti i generi memorizzati in tabella
-- con anche l'informazione sull'esistenza di spettacoli associati a quel genere
-- --------------------------------------------------------------------------------------------
  FUNCTION FU_ELENCO_GENERI_SPETT RETURN C_GENERE_SPETT;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_ELENCO_GENERI_PADRE  la funzione si occupa di reperire l'elenco dei generi padre memorizzati in tabella
-- --------------------------------------------------------------------------------------------
  FUNCTION FU_ELENCO_GENERI_PADRE(p_id_genere         CD_GENERE.ID_GENERE%TYPE)
                                     RETURN C_GENERE_BASE;
--
--
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_SPETT_GIORNO_SALA  la funzione si occupa di reperire gli spettacoli associati alla specifica sala in un giorno
-- --------------------------------------------------------------------------------------------
  FUNCTION FU_SPETT_GIORNO_SALA(p_id_sala         CD_SALA.ID_SALA%TYPE,
                                p_data            CD_PROIEZIONE.DATA_PROIEZIONE%TYPE,
                                p_flg_protetta    CD_FASCIA.FLG_PROTETTA%TYPE)
                                RETURN C_SPETTACOLO_PROIEZIONE;
--
-- --------------------------------------------------------------------------------------------
-- PROCEDURE PR_IMPORTA_SPETTACOLO  la funzione si occupa di importare le informazioni su uno 
--                                 spettacolo nel db. Se lo spettacolo esiste gia non viene inserito
-- --------------------------------------------------------------------------------------------
PROCEDURE PR_IMPORTA_SPETTACOLO(   p_titolo         CD_SPETTACOLO.NOME_SPETTACOLO%TYPE,
                                   p_genere         CD_GENERE.DESC_GENERE%TYPE,
                                   p_distributore   CD_DISTRIBUTORE.CASA_DISTRIBUZIONE%TYPE,
                                   p_flg_protetto   CD_SPETTACOLO.FLG_PROTETTO%TYPE,
                                   p_esito          OUT NUMBER
                                   );
-- --------------------------------------------------------------------------------------------
-- FUNCTION  FU_PROGRAMMAZIONE_SPETTACOLARE La funzione si occupa di restituire l'elenco delle programmazioni spettacolari
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PROGRAMMAZIONE_SPETTACOLARE( p_id_cinema       cd_cinema.id_cinema%TYPE,
                                          p_id_sala         cd_sala.id_sala%TYPE,
                                          p_data_inizio     date,
                                          p_data_fine       date,
                                          p_id_circuito     cd_circuito.id_circuito%type,
                                          p_flg_protetto    cd_spettacolo.flg_protetto%type,
                                          p_id_genere       cd_genere.id_genere%type,
                                          p_id_target       cd_target.id_target%type,
                                          p_id_spettacolo   cd_spettacolo.id_spettacolo%type,
                                          p_esclusivo       number,
                                          p_id_comune       cd_comune.id_comune%type,
                                          p_id_provincia    cd_provincia.id_provincia%type,
                                          p_id_regione      cd_regione.id_regione%type                                          
                                        )RETURN C_PROGRAMMAZIONE_SPETTACOLARE;
FUNCTION FU_PROGR_SPETT_PER_SALA( p_id_cinema       cd_cinema.id_cinema%TYPE,
                                  p_id_sala         cd_sala.id_sala%TYPE,
                                  p_data_inizio     date,
                                  p_data_fine       date,
                                  p_id_circuito     cd_circuito.id_circuito%type,
                                  p_flg_protetto    cd_spettacolo.flg_protetto%type,
                                  p_id_genere       cd_genere.id_genere%type,
                                  p_id_target       cd_target.id_target%type,
                                  p_id_spettacolo   cd_spettacolo.id_spettacolo%type,
                                  p_id_comune       cd_comune.id_comune%type,
                                  p_id_provincia    cd_provincia.id_provincia%type,
                                  p_id_regione      cd_regione.id_regione%type                                                                       
                                )RETURN C_PROGR_SPETT_SALA;
-----------------------------------------------------------------------------------------
FUNCTION FU_SALE_SENZA_PROGR( p_id_cinema       cd_cinema.id_cinema%TYPE,
                              p_id_sala         cd_sala.id_sala%TYPE,
                              p_data_inizio     date,
                              p_data_fine       date,
                              p_id_circuito     cd_circuito.id_circuito%type,
                              p_id_comune       cd_comune.id_comune%type,
                              p_id_provincia    cd_provincia.id_provincia%type,
                              p_id_regione      cd_regione.id_regione%type                                                          
                             )RETURN C_PROGRAMMAZIONE_SPETTACOLARE;
-- --------------------------------------------------------------------------------------------
-- FUNCTION FU_DAMMI_PROIEZIONE_GEMELLA
-- --------------------------------------------------------------------------------------------
FUNCTION FU_DAMMI_PROIEZIONE_GEMELLA(p_id_proiezione     CD_PROIEZIONE.ID_PROIEZIONE%TYPE)
						                RETURN CD_PROIEZIONE.ID_PROIEZIONE%TYPE;                                   
--
END PA_CD_SPETTACOLO; 
/

