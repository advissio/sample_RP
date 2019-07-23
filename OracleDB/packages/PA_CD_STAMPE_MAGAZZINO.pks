CREATE OR REPLACE PACKAGE VENCD.PA_CD_STAMPE_MAGAZZINO AS

function prod_sogg(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return varchar2;
/******************************************************************************
   NAME:       PA_CD_STAMPE_MAGAZZINO
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        09/09/2009   Mauro Viel Altran   1. Created this package body.
******************************************************************************/

TYPE R_STAMPA_DECURTAZIONE IS RECORD
(
  r_id_cinema           cd_cinema.id_cinema%type,
  r_id_sala             cd_sala.id_sala%type, 
  r_nome_cinema         cd_cinema.nome_cinema%type, 
  r_nome_sala           cd_sala.nome_sala%type, 
  r_comune              cd_comune.comune%type, 
  r_data_rif            cd_liquidazione_sala.data_rif%type, 
  r_descrizione_estesa  cd_codice_resp.descrizione_estesa%type
) ;

TYPE C_STAMPA_DECURTAZIONE IS REF CURSOR RETURN R_STAMPA_DECURTAZIONE;

--
--
--Tipo di test per l'integrazione jasper Report
--Autore Mauro Viel settembre 2009
--
TYPE R_RICHIESTA_STAMPA_TEST IS RECORD
(
  idPiano                        CD_PIANIFICAZIONE.ID_PIANO%TYPE,
  idProg                         CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
  periodo                        VARCHAR2(40) ,
  lordo                          CD_IMPORTI_RICHIESTA.lordo%type,
  netto                          CD_IMPORTI_RICHIESTA.netto%type,
  perSc                          CD_IMPORTI_RICHIESTA.perc_sc%type

) ;
--
TYPE C_RICHIESTA_TEST IS REF CURSOR RETURN R_RICHIESTA_STAMPA_TEST;


type r_previsione_fattura is record
(
 data_inizio    cd_prodotto_acquistato.DATA_INIZIO%type,
 data_fine      cd_prodotto_acquistato.DATA_FINE%type,
 imp_netto      cd_prodotto_acquistato.imp_netto%type,
 tipo_contratto cd_importi_prodotto.tipo_contratto%type

);

type c_previsione_fattura IS REF CURSOR RETURN r_previsione_fattura;



--
--
--Record contenente i dati di base e gli importi relativi alla richiesta
--Autore Daniela Spezia settembre 2009
--
TYPE R_RICHIESTA_STAMPA_IMPORTI IS RECORD
(
    idPiano                 CD_PIANIFICAZIONE.ID_PIANO%TYPE,
    idVersionePiano         CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
    nomeCliente             INTERL_U.RAG_SOC_COGN%TYPE,
    nomeRespContatto        INTERL_U.RAG_SOC_COGN%TYPE,
    codArea                 CD_PIANIFICAZIONE.COD_AREA%TYPE,
    descArea                AREE.DESCRIZIONE_ESTESA%TYPE,
    codSede                 CD_PIANIFICAZIONE.COD_SEDE%TYPE,
    descSede                SEDI.DESCRIZIONE_ESTESA%TYPE,
    descStatoVendita        CD_STATO_DI_VENDITA.DESCRIZIONE%TYPE,
    nomeTarget              CD_TARGET.NOME_TARGET%TYPE,
    dataCreaz               CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
    dataInvioMagazzino      CD_PIANIFICAZIONE.DATA_INVIO_MAGAZZINO%TYPE,
    periodo                 VARCHAR2(40) ,
    dataInizio              PERIODI.DATA_INIZ%TYPE,
    dataFine                PERIODI.DATA_FINE%TYPE,
    netto                   CD_IMPORTI_RICHIESTA.NETTO%TYPE,
    lordo                   CD_IMPORTI_RICHIESTA.LORDO%TYPE,
    sconto                  CD_IMPORTI_RICHIESTA.PERC_SC%TYPE,
    nota                    CD_IMPORTI_RICHIESTA.NOTA%TYPE
) ;
--
TYPE C_RICHIESTA_STAMPA_IMPORTI IS REF CURSOR RETURN R_RICHIESTA_STAMPA_IMPORTI;
--
--Record contenente i dati di base e gli importi relativi alla richiesta
--Autore Daniela Spezia settembre 2009
--
TYPE R_RICHIESTA_TOT_IMPORTI IS RECORD
(
    totNetto                   CD_IMPORTI_RICHIESTA.NETTO%TYPE,
    totLordo                   CD_IMPORTI_RICHIESTA.LORDO%TYPE,
    totSconto                  CD_IMPORTI_RICHIESTA.PERC_SC%TYPE
) ;
--
TYPE C_RICHIESTA_TOT_IMPORTI IS REF CURSOR RETURN R_RICHIESTA_TOT_IMPORTI;
--
--Record contenente i dati relativi al raggruppamento intermediari di una richiesta
--Autore Daniela Spezia settembre 2009
--
TYPE R_RAGGRUPP_INTERMEDIARI IS RECORD
(
    idPiano                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
    idVersionePiano         CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
    idAgenzia               CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
    agenzia                 VI_CD_AGENZIA.RAG_SOC_COGN%TYPE,
    idCentroMedia           CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_CENTRO_MEDIA%TYPE,
    centroMedia             VI_CD_CENTRO_MEDIA.RAG_SOC_COGN%TYPE,
    idVendCliente           CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
    vendCli                 INTERL_U.RAG_SOC_COGN%TYPE
) ;
--
TYPE C_RAGGRUPP_INTERMEDIARI IS REF CURSOR RETURN R_RAGGRUPP_INTERMEDIARI;
--
--Record contenente i dati relativi al raggruppamento intermediari di una richiesta;
-- sono esclusi i dati relativi al centro media (non visualizzato nella stampa calendario)
--Autore Daniela Spezia settembre 2009
--
TYPE R_RAGG_INT_NO_CM IS RECORD
(
    idPiano                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
    idVersionePiano         CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
    idAgenzia               CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
    agenzia                 VI_CD_AGENZIA.RAG_SOC_COGN%TYPE,
    idVendCliente           CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
    vendCli                 INTERL_U.RAG_SOC_COGN%TYPE
) ;
--
TYPE C_RAGG_INT_NO_CM IS REF CURSOR RETURN R_RAGG_INT_NO_CM;
--
--Record contenente i dati di testata visualizzati nella stampa proposta
--Autore Daniela Spezia settembre 2009
--
TYPE R_TESTATA_PROPOSTA IS RECORD
(
    idPiano                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
    idVersionePiano         CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
    dataCreaz               CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
    codArea                 CD_PIANIFICAZIONE.COD_AREA%TYPE,
    descArea                AREE.DESCRIZIONE_ESTESA%TYPE,
    nomeCliente             INTERL_U.RAG_SOC_COGN%TYPE,
    nomeRespContatto        INTERL_U.RAG_SOC_COGN%TYPE,
    idAgenzia               CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
    agenzia                 VI_CD_AGENZIA.RAG_SOC_COGN%TYPE,
    idVendCliente           CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VENDITORE_CLIENTE%TYPE,
    vendCli                 INTERL_U.RAG_SOC_COGN%TYPE,
    statoLavorazione        CD_STATO_LAVORAZIONE.DESCRIZIONE%TYPE,
    descSoggettoPiano       cd_soggetto_di_piano.DESCRIZIONE%TYPE
) ;
--
TYPE C_TESTATA_PROPOSTA IS REF CURSOR RETURN R_TESTATA_PROPOSTA;
--
--Record contenente i dati relativi al dettaglio per la stampa proposta
--Autore Daniela Spezia settembre 2009
-- MODIFICHE: il 10.12.2009 si aggiunge il campo numProiezioni
--
TYPE R_DETTAGLIO_PROPOSTA IS RECORD
(
    idSoggettoPiano         cd_soggetto_di_piano.ID_SOGGETTO_DI_PIANO%TYPE,
    descSoggettoPiano       cd_soggetto_di_piano.DESCRIZIONE%TYPE,
    idProdAcquistato        CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE,
    descProdotto            cd_prodotto_pubb.DESC_PRODOTTO%TYPE,
    numSchermi              NUMBER(10),
    numProiezioni           NUMBER(10),
    famigliaPubblicitaria   pc_categoria_prodotto.DESCRIZIONE%TYPE,
    codFamigliaPubb         cd_prodotto_pubb.cod_categoria_prodotto%TYPE,
    periodoVenditaDal       CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    periodoVenditaAl        CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    estensioneTemporale     cd_unita_misura_temp.desc_unita%TYPE,
    circuito                cd_circuito.NOME_CIRCUITO%TYPE,
    tipoFilmato             cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    modalitaVendita         cd_modalita_vendita.DESC_MOD_VENDITA%TYPE,
    statoVendita            cd_stato_di_vendita.DESCRIZIONE%TYPE,
    formato                 VARCHAR2(10),
    tariffaVariabile        CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE,
    tariffa                 CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    maggiorazione           CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    lordo                   CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    nettoComm               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    nettoDir                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    scontoComm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    scontoDir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    percScontoComm          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    percScontoDir           cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    sanatoria               CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE,
    recupero                CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE
) ;
--
TYPE C_DETTAGLIO_PROPOSTA IS REF CURSOR RETURN R_DETTAGLIO_PROPOSTA;
--
--Record contenente i dati relativi ai totali di dettaglio per la stampa proposta
-- i totali sono calcolati al variare del soggetto (dati idPiano e idVerPiano)
--Autore Daniela Spezia settembre 2009
--
TYPE R_TOTALI_SOGG IS RECORD
(
    idSoggettoPiano         cd_soggetto_di_piano.ID_SOGGETTO_DI_PIANO%TYPE,
    periodoVenditaDal       CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    periodoVenditaAl        CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    totTariffa              CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    totMaggiorazione        CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    totLordo                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    totNettoC               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totNettoD               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totScontoC              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totScontoD              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totPercScontoC          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    totPercScontoD          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    totSanatoria            CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE,
    totRecupero             CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE
) ;
--
TYPE C_TOTALI_SOGG IS REF CURSOR RETURN R_TOTALI_SOGG;
--
--Record contenente i dati relativi ai totali di dettaglio per la stampa proposta
-- i totali sono calcolati globalmente per il piano (dati idPiano e idVerPiano)
--Autore Daniela Spezia novembre 2009
--
TYPE R_TOTALI_PIANO IS RECORD
(
    totTariffa              CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE,
    totMaggiorazione        CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE,
    totLordo                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE,
    totNettoC               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totNettoD               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totScontoC              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totScontoD              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totPercScontoC          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    totPercScontoD          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    totSanatoria            CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE,
    totRecupero             CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE
) ;
--
TYPE C_TOTALI_PIANO IS REF CURSOR RETURN R_TOTALI_PIANO;
--
--Record contenente i dati relativi alla famiglia pubblicitaria
--Autore Daniela Spezia settembre 2009
--
TYPE R_FAMIGLIA_PUBB IS RECORD
(
    codCategoriaProdotto         cd_prodotto_pubb.COD_CATEGORIA_PRODOTTO%TYPE
) ;
--
TYPE C_FAMIGLIA_PUBB IS REF CURSOR RETURN R_FAMIGLIA_PUBB;
--
--Record contenente i dati del piano visualizzati nella testata della stampa calendario
--Autore Daniela Spezia settembre 2009
--
TYPE R_DATI_PIANO IS RECORD
(
    idPiano                 CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_PIANO%TYPE,
    idVersionePiano         CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_VER_PIANO%TYPE,
    dataCreaz               CD_PIANIFICAZIONE.DATA_CREAZIONE_RICHIESTA%TYPE,
    codArea                 CD_PIANIFICAZIONE.COD_AREA%TYPE,
    descArea                AREE.DESCRIZIONE_ESTESA%TYPE,
    nomeCliente             INTERL_U.RAG_SOC_COGN%TYPE,
    nomeRespContatto        INTERL_U.RAG_SOC_COGN%TYPE,
    statoLavorazione        CD_STATO_LAVORAZIONE.DESCRIZIONE%TYPE
) ;
--
TYPE C_DATI_PIANO IS REF CURSOR RETURN R_DATI_PIANO;
--
--Record contenente i dati relativi al dettaglio per la stampa calendario
--Autore Daniela Spezia settembre 2009
--
TYPE R_DETTAGLIO_CALENDARIO IS RECORD
(
    idSoggettoPiano         cd_soggetto_di_piano.ID_SOGGETTO_DI_PIANO%TYPE,
    descSoggettoPiano       cd_soggetto_di_piano.DESCRIZIONE%TYPE,
    idCircuito                cd_circuito.ID_CIRCUITO%TYPE,
    nomeCircuito                cd_circuito.NOME_CIRCUITO%TYPE,
    codStato        cd_stato_di_vendita.DESCR_BREVE%TYPE,
    descStato       cd_stato_di_vendita.DESCRIZIONE%TYPE,
    tipoPubb                cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    modalitaVendita         cd_modalita_vendita.DESC_MOD_VENDITA%TYPE,
    idCinema                cd_cinema.ID_CINEMA%TYPE,
    nomeCinema              cd_cinema.NOME_CINEMA%TYPE,
    comuneCinema            cd_comune.COMUNE%TYPE,
    provinciaCinema         cd_provincia.ABBR%TYPE,
    nomeSala                cd_sala.NOME_SALA%TYPE,
    periodoProiezDal        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    periodoProiezAl         CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    numProiezioni           NUMBER(10),
    formato                 cd_formato_acquistabile.DESCRIZIONE%TYPE,
    posizione               NUMBER(10)
) ;
--
TYPE C_DETTAGLIO_CALENDARIO IS REF CURSOR RETURN R_DETTAGLIO_CALENDARIO;



-------------------------



TYPE R_DETTAGLIO_CALENDARIO_XLS IS RECORD
(
    idSoggettoPiano         cd_soggetto_di_piano.ID_SOGGETTO_DI_PIANO%TYPE,
    descSoggettoPiano       cd_soggetto_di_piano.DESCRIZIONE%TYPE,
    idCircuito                cd_circuito.ID_CIRCUITO%TYPE,
    nomeCircuito                cd_circuito.NOME_CIRCUITO%TYPE,
    codStato        cd_stato_di_vendita.DESCR_BREVE%TYPE,
    descStato       cd_stato_di_vendita.DESCRIZIONE%TYPE,
    tipoPubb                cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    modalitaVendita         cd_modalita_vendita.DESC_MOD_VENDITA%TYPE,
    idCinema                cd_cinema.ID_CINEMA%TYPE,
    nomeCinema              cd_cinema.NOME_CINEMA%TYPE,
    comuneCinema            cd_comune.COMUNE%TYPE,
    provinciaCinema         cd_provincia.provincia%TYPE,
    regioneCinema           cd_regione.nome_regione%TYPE,
    nomeSala                cd_sala.NOME_SALA%TYPE,
    periodoProiezDal        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    periodoProiezAl         CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    numProiezioni           NUMBER(10),
    formato                 cd_formato_acquistabile.DESCRIZIONE%TYPE,
    posizione               NUMBER(10)
) ;
--
TYPE C_DETTAGLIO_CALENDARIO_XLS IS REF CURSOR RETURN R_DETTAGLIO_CALENDARIO_XLS;

------------------------

--
--Record contenente (per un piano) i dati relativi ai circuiti collegati, ciascuno
-- associato alle date di inizio e fine proiezione ricavabili dalla data inizio e
-- fine del prodotto acquistato; questo record viene usato per costruire la stampa
-- calendario nel caso di pubblicita tabellare
--Autore Daniela Spezia ottobre 2009
--
TYPE R_CIRCUITO_E_DATE IS RECORD
(
    idProdottoAcquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
    idCircuito           CD_PRODOTTO_VENDITA.ID_CIRCUITO%TYPE,
    dataInizio           CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    dataFine             CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
) ;
--
TYPE C_CIRCUITO_E_DATE IS REF CURSOR RETURN R_CIRCUITO_E_DATE;
--
-- Record contenente, nell'ambito dei dati relativi al dettaglio per la stampa calendario di
-- pubblicita tabellare, i dati relativi al soggetto - prodotto acquistato - prodotto di vendita
-- Autore Daniela Spezia ottobre 2009
--
TYPE R_DETTAGLIO_CAL_PA_PV IS RECORD
(
    id_prodotto_acquistato  cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
    idSoggettoPiano         cd_soggetto_di_piano.ID_SOGGETTO_DI_PIANO%TYPE,
    descSoggettoPiano       cd_soggetto_di_piano.DESCRIZIONE%TYPE,
    idCircuito               cd_circuito.ID_CIRCUITO%TYPE,
    codStato        cd_stato_di_vendita.DESCR_BREVE%TYPE,
    descStato       cd_stato_di_vendita.DESCRIZIONE%TYPE,
    tipoPubb                cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    modalitaVendita         cd_modalita_vendita.DESC_MOD_VENDITA%TYPE,
    periodoProiezDal        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    periodoProiezAl         CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE,
    formato                 cd_formato_acquistabile.DESCRIZIONE%TYPE,
    posizione               NUMBER(10)
) ;
--
TYPE C_DETTAGLIO_CAL_PA_PV IS REF CURSOR RETURN R_DETTAGLIO_CAL_PA_PV;
--
-- Record contenente, nell'ambito dei dati relativi al dettaglio per la stampa calendario di
-- pubblicita tabellare, i dati relativi al cinema - sala - numero di proiezioni
-- Autore Daniela Spezia ottobre 2009
--
TYPE R_DETTAGLIO_CAL_CINEMA IS RECORD
(
    idProdottoAcquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
    idCircuito              cd_circuito.ID_CIRCUITO%TYPE,
    nomeCircuito            cd_circuito.NOME_CIRCUITO%TYPE,
    idCinema                cd_cinema.ID_CINEMA%TYPE,
    nomeCinema              cd_cinema.NOME_CINEMA%TYPE,
    comuneCinema            cd_comune.COMUNE%TYPE,
    provinciaCinema         cd_provincia.ABBR%TYPE,
    idSala                  cd_sala.ID_SALA%TYPE,
    nomeSala                cd_sala.NOME_SALA%TYPE,
    numProiezioni           NUMBER(10)
) ;
--
TYPE C_DETTAGLIO_CAL_CINEMA IS REF CURSOR RETURN R_DETTAGLIO_CAL_CINEMA;




----------------------------------

TYPE R_DETTAGLIO_CAL_CINEMA_XLS IS RECORD
(
    idProdottoAcquistato    cd_prodotto_acquistato.id_prodotto_acquistato%type,
    idCircuito              cd_circuito.ID_CIRCUITO%TYPE,
    nomeCircuito            cd_circuito.NOME_CIRCUITO%TYPE,
    idCinema                cd_cinema.ID_CINEMA%TYPE,
    nomeCinema              cd_cinema.NOME_CINEMA%TYPE,
    comuneCinema            cd_comune.COMUNE%TYPE,
    provinciaCinema         cd_provincia.provincia%TYPE,
    regione                 cd_regione.NOME_REGIONE%type,
    idSala                  cd_sala.ID_SALA%TYPE,
    nomeSala                cd_sala.NOME_SALA%TYPE,
    numProiezioni           NUMBER(10)
) ;
--
TYPE C_DETTAGLIO_CAL_CINEMA_XLS IS REF CURSOR RETURN R_DETTAGLIO_CAL_CINEMA_XLS;

----------------------------------


--
--Record contenente i dati di base e gli importi relativi alla stampa prodotti richiesti
--Autore Daniela Spezia novembre 2009
-- MODIFICHE: il 10.12.2009 si aggiunge il campo numProiezioni
--
TYPE R_PROD_RICHIESTI_IMPORTI IS RECORD
(
    idPiano                 CD_PIANIFICAZIONE.ID_PIANO%TYPE,
    idVersionePiano         CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
    prodottoRichiestoId     cd_prodotti_richiesti.ID_PRODOTTI_RICHIESTI%TYPE,
    formatoTab              varchar2(100),
    formatoIsp              cd_formato_acquistabile.DESCRIZIONE%TYPE,
    circuito                cd_circuito.NOME_CIRCUITO%TYPE,
    tipoFilmato             cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    modalitaVendita         cd_modalita_vendita.DESC_MOD_VENDITA%TYPE,
    descProdotto            CD_PRODOTTO_PUBB.DESC_PRODOTTO%TYPE,
    dataInizio              cd_prodotti_richiesti.DATA_INIZIO%TYPE,
    dataFine                cd_prodotti_richiesti.DATA_FINE%TYPE,
    estensioneTemporale     cd_unita_misura_temp.DESC_UNITA%TYPE,
    numSchermi              NUMBER(10),
    numProiezioni           NUMBER(10),
    tariffaVariabile        cd_prodotti_richiesti.FLG_TARIFFA_VARIABILE%TYPE,
    tariffa                 cd_prodotti_richiesti.IMP_TARIFFA%TYPE,
    maggiorazione           cd_prodotti_richiesti.IMP_MAGGIORAZIONE%TYPE,
    lordo                   cd_prodotti_richiesti.IMP_LORDO%TYPE,
    netto                   cd_prodotti_richiesti.IMP_NETTO%TYPE,
    nettoComm               cd_importi_prodotto.IMP_NETTO%TYPE,
    nettoDir                cd_importi_prodotto.IMP_NETTO%TYPE,
    scontoComm              cd_importi_prodotto.IMP_SC_COMM%TYPE,
    scontoDir               cd_importi_prodotto.IMP_SC_COMM%TYPE,
    percScontoComm          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    percScontoDir           cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE
) ;
--
TYPE C_PROD_RICHIESTI_IMPORTI IS REF CURSOR RETURN R_PROD_RICHIESTI_IMPORTI;
--
--Record contenente i dati relativi ai totali per la stampa prodotti richiesti
--Autore Daniela Spezia novembre 2009
--
TYPE R_TOTALI_PROD_RICH IS RECORD
(
    dataInizio              cd_prodotti_richiesti.DATA_INIZIO%TYPE,
    dataFine                cd_prodotti_richiesti.DATA_FINE%TYPE,
    totTariffa              cd_prodotti_richiesti.IMP_TARIFFA%TYPE,
    totMaggiorazione        cd_prodotti_richiesti.IMP_MAGGIORAZIONE%TYPE,
    totLordo                cd_prodotti_richiesti.IMP_LORDO%TYPE,
    totNetto                cd_prodotti_richiesti.IMP_NETTO%TYPE,
    totNettoC               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totNettoD               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totScontoC              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totScontoD              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totPercScontoC          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    totPercScontoD          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE
) ;
--
TYPE C_TOTALI_PROD_RICH IS REF CURSOR RETURN R_TOTALI_PROD_RICH;
--
--Record contenente i dati relativi ai totali per la stampa prodotti richiesti
--Autore Daniela Spezia novembre 2009
--
TYPE R_TOTALI_PROD_RICH_PIANO IS RECORD
(
    totTariffa              cd_prodotti_richiesti.IMP_TARIFFA%TYPE,
    totMaggiorazione        cd_prodotti_richiesti.IMP_MAGGIORAZIONE%TYPE,
    totLordo                cd_prodotti_richiesti.IMP_LORDO%TYPE,
    totNetto                cd_prodotti_richiesti.IMP_NETTO%TYPE,
    totNettoC               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totNettoD               CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE,
    totScontoC              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totScontoD              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE,
    totPercScontoC          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    totPercScontoD          cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE
) ;
--
TYPE C_TOTALI_PROD_RICH_PIANO IS REF CURSOR RETURN R_TOTALI_PROD_RICH_PIANO;
--
--Record contenente i dati relativi ai soggetti (reperiti tramite i comunicati
-- di un dato prodotto acquistato), utili per la stampa richiesta
--Autore Daniela Spezia novembre 2009
--
TYPE R_SOGG_PROD_ACQ IS RECORD
(
    idSoggettoPiano         cd_soggetto_di_piano.ID_SOGGETTO_DI_PIANO%TYPE,
    descSoggettoPiano       cd_soggetto_di_piano.DESCRIZIONE%TYPE,
    idProdAcquistato        CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE
) ;
--
TYPE C_SOGG_PROD_ACQ IS REF CURSOR RETURN R_SOGG_PROD_ACQ;
--
--Record contenente il numero di soggetti differenti relativi ad ogni prodotto
-- acquistato del piano in esame, utili per la stampa richiesta
--Autore Daniela Spezia novembre 2009
--
TYPE R_NUM_SOGG_PROD_ACQ IS RECORD
(
    numSoggetti             NUMBER(10),
    idProdAcquistato        CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE
) ;
--
TYPE C_NUM_SOGG_PROD_ACQ IS REF CURSOR RETURN R_NUM_SOGG_PROD_ACQ;
--
-- Record contenente i dati dell'elenco schermi
-- Autore Daniela Spezia dicembre 2009
--
TYPE R_DETTAGLIO_ELENCO_SCHERMI IS RECORD
(
    idCinema                cd_cinema.ID_CINEMA%TYPE,
    nomeCinema              cd_cinema.NOME_CINEMA%TYPE,
    comuneCinema            cd_comune.COMUNE%TYPE,
    provinciaCinema         cd_provincia.ABBR%TYPE,
    regioneCinema           cd_regione.NOME_REGIONE%TYPE,
    idSala                  cd_sala.ID_SALA%TYPE,
    nomeSala                cd_sala.NOME_SALA%TYPE
) ;
--
TYPE C_DETTAGLIO_ELENCO_SCHERMI IS REF CURSOR RETURN R_DETTAGLIO_ELENCO_SCHERMI;
--
-- Record contenente, nell'ambito dei dati relativi al dettaglio per la stampa elenco schermi della
-- pubblicita tabellare, l'inizio e fine del periodo di proiezione
-- Autore Daniela Spezia ottobre 2009
--
TYPE R_ESTREMI_PERIODO IS RECORD
(
    periodoProiezDal        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
    periodoProiezAl         CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
) ;
--
TYPE C_ESTREMI_PERIODO IS REF CURSOR RETURN R_ESTREMI_PERIODO;
--
--Record contenente i dati di testata visualizzati nella stampa ordine
--Autore Daniela Spezia settembre 2009
--
TYPE R_TESTATA_ORDINE IS RECORD
(
    pianoId                 CD_ORDINE.ID_PIANO%TYPE,
    versionePianoId         CD_ORDINE.ID_VER_PIANO%TYPE,
    progressivoOrdine       CD_ORDINE.COD_PRG_ORDINE%TYPE,
    codArea                 CD_PIANIFICAZIONE.COD_AREA%TYPE,
    descArea                AREE.DESCRIZIONE_ESTESA%TYPE,
    nomeRespContatto        INTERL_U.RAG_SOC_COGN%TYPE,
    idAgenzia               CD_RAGGRUPPAMENTO_INTERMEDIARI.ID_AGENZIA%TYPE,
    agenzia                 VI_CD_AGENZIA.RAG_SOC_COGN%TYPE,
    condPagamento           cond_pagamento.DES_CPAG%TYPE,
    dataInizioOrdine        cd_ordine.DATA_INIZIO%TYPE,
    dataFineOrdine          cd_ordine.DATA_FINE%TYPE
) ;
--
TYPE C_TESTATA_ORDINE IS REF CURSOR RETURN R_TESTATA_ORDINE;
--
--Record contenente i dati del cliente fruitore visualizzati nella stampa ordine
--Autore Daniela Spezia dicembre 2009
--
TYPE R_CLI_FRUITORE_ORDINE IS RECORD
(
    idCliente       vi_cd_cliente_fruitore.ID_FRUITORE%TYPE,
    nome            vi_cd_cliente_fruitore.rag_soc_br_nome%TYPE,
    cognome         vi_cd_cliente_fruitore.rag_soc_cogn%TYPE,
    indirizzo       vi_cd_cliente_fruitore.indirizzo%TYPE,
    cap             vi_cd_cliente_fruitore.cap%TYPE,
    localita        vi_cd_cliente_fruitore.localita%TYPE,
    provincia       vi_cd_cliente_fruitore.provincia%TYPE,
    nazione         vi_cd_cliente_fruitore.nazione%TYPE,
    sesso           vi_cd_cliente_fruitore.sesso%TYPE,
    codiceFiscale   vi_cd_cliente_fruitore.cod_fisc%TYPE,
    partitaIva      interl_u.PART_IVA%TYPE
) ;
--
TYPE C_CLI_FRUITORE_ORDINE IS REF CURSOR RETURN R_CLI_FRUITORE_ORDINE;
--
--Record contenente i dati del prodotto visualizzati nella stampa ordine
--Autore Daniela Spezia dicembre 2009
--
TYPE R_PRODOTTO_ORDINE IS RECORD
(
    descProdotto    cd_importi_fatturazione.desc_prodotto%TYPE,
    dataInizio      cd_importi_fatturazione.data_inizio%TYPE,
    dataFine        cd_importi_fatturazione.data_fine%TYPE,
    numSale         NUMBER(10),
    numAmbienti     NUMBER(10),
    durataTab       VARCHAR2(10),
    formatoIsp      VARCHAR2(10),
    tariffa         cd_prodotto_acquistato.imp_tariffa%TYPE,
    netto           cd_importi_fatturazione.importo_netto%TYPE,
    percSconto      cd_importi_fatturazione.PERC_SCONTO_SOST_AGE%TYPE,
    totaleNetto     cd_importi_fatturazione.importo_netto%TYPE,
    statoFatturaz   cd_importi_fatturazione.STATO_FATTURAZIONE%TYPE,
    tipoContratto   cd_importi_prodotto.TIPO_CONTRATTO%TYPE,
    idProdAcq       cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
    nettoProdAcq    cd_prodotto_acquistato.IMP_NETTO%TYPE
) ;
--
TYPE C_PRODOTTO_ORDINE IS REF CURSOR RETURN R_PRODOTTO_ORDINE;
--
--Record contenente i dati delle copie conformi relatve alla stampa ordine
--Autore Daniela Spezia Gennaio 2010
--
TYPE R_COPIE_CONF_ORDINE IS RECORD
(
    stampaOrdineId      cd_stampe_ordine.id_stampe_ordine%TYPE,
    ordineId            cd_stampe_ordine.id_ordine%TYPE,
    dataStampa          cd_stampe_ordine.data_stampa%TYPE,
    flgOrdineModificato cd_stampe_ordine.flg_ordine_modificato%TYPE
) ;
--
TYPE C_COPIE_CONF_ORDINE IS REF CURSOR RETURN R_COPIE_CONF_ORDINE;
--
--Record contenente il dettaglio della copia conforme specificata
--Autore Daniela Spezia Gennaio 2010
--
TYPE R_DATI_COPIA_CONF_ORDINE IS RECORD
(
    datiPdf          cd_stampe_ordine.pdf%TYPE
) ;
--
TYPE C_DATI_COPIA_CONF_ORDINE IS REF CURSOR RETURN R_DATI_COPIA_CONF_ORDINE;
--
TYPE R_FILM IS RECORD
(
    a_id_prodotto_acquistato    cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_data_inizio   cd_prodotto_acquistato.DATA_INIZIO%TYPE,
    a_data_fine cd_prodotto_acquistato.DATA_FINE%TYPE,
    a_stato_di_vendita cd_stato_di_vendita.DESCRIZIONE%TYPE,
    a_durata    cd_coeff_cinema.DURATA%TYPE,
    a_media_sale_settimana    NUMBER,
    a_desc_circuito cd_circuito.DESC_CIRCUITO%TYPE,
    a_desc_tipo_break   cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    a_nome_spettacolo   cd_spettacolo.NOME_SPETTACOLO%TYPE,
    a_media_sale_spettacolo    NUMBER,
    a_desc_soggetto cd_soggetto_di_piano.DESCRIZIONE%TYPE
) ;
--
TYPE C_FILM IS REF CURSOR RETURN R_FILM;
--



TYPE r_certificazione_breve IS RECORD
(

    a_id_prodotto_acquistato    cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_data_inizio   cd_prodotto_acquistato.DATA_INIZIO%TYPE,
    a_data_fine cd_prodotto_acquistato.DATA_FINE%TYPE,
    a_cod_area  aree.COD_AREA%type,
    a_descrizione_area aree.DESCRIZIONE_ESTESA%type,
    a_reponsabile_contatto interl_u.RAG_SOC_COGN%type,
    a_cliente interl_u.RAG_SOC_COGN%type,
    a_nome_agenzia interl_u.RAG_SOC_COGN%type,
    a_venditore_cliente interl_u.RAG_SOC_COGN%type,
    a_durata    cd_coeff_cinema.DURATA%TYPE,
    a_circuito cd_circuito.DESC_CIRCUITO%TYPE,
    a_tipo_break   cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    a_soggetto cd_soggetto_di_piano.DESCRIZIONE%TYPE,
    a_giorno  date,
    a_numero_proiezioni number

);

TYPE c_certificazione_breve IS REF CURSOR RETURN r_certificazione_breve;




TYPE r_certificazione IS RECORD
(
    a_id_prodotto_acquistato    cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_data_inizio   cd_prodotto_acquistato.DATA_INIZIO%TYPE,
    a_data_fine cd_prodotto_acquistato.DATA_FINE%TYPE,
    a_cod_area  aree.COD_AREA%type,
    a_descrizione_area aree.DESCRIZIONE_ESTESA%type,
    a_reponsabile_contatto interl_u.RAG_SOC_COGN%type,
    a_cliente interl_u.RAG_SOC_COGN%type,
    a_nome_agenzia interl_u.RAG_SOC_COGN%type,
    a_venditore_cliente interl_u.RAG_SOC_COGN%type,
    a_durata    cd_coeff_cinema.DURATA%TYPE,
    a_circuito cd_circuito.NOME_CIRCUITO%TYPE,
    a_nome_cinema cd_cinema.NOME_CINEMA%type,
    a_comune cd_comune.COMUNE%type,
    a_provincia cd_provincia.ABBR%type,
    a_id_sala   cd_comunicato.id_sala%type,                      
    a_nome_sala   cd_sala.nome_sala%type,                      
    a_tipo_break   cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    a_proiettato number,
    a_causale cd_liquidazione_sala.ID_CODICE_RESP%TYPE,
    a_data_proiezione  date,
    a_soggetto cd_soggetto_di_piano.DESCRIZIONE%TYPE
       
);


TYPE c_certificazione IS REF CURSOR RETURN r_certificazione;



TYPE r_certificazione_estesa IS RECORD
(
    a_id_prodotto_acquistato    cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_data_inizio   cd_prodotto_acquistato.DATA_INIZIO%TYPE,
    a_data_fine cd_prodotto_acquistato.DATA_FINE%TYPE,
    a_cod_area  aree.COD_AREA%type,
    a_descrizione_area aree.DESCRIZIONE_ESTESA%type,
    a_reponsabile_contatto interl_u.RAG_SOC_COGN%type,
    a_cliente interl_u.RAG_SOC_COGN%type,
    a_nome_agenzia interl_u.RAG_SOC_COGN%type,
    a_venditore_cliente interl_u.RAG_SOC_COGN%type,
    a_durata    cd_coeff_cinema.DURATA%TYPE,
    a_circuito cd_circuito.NOME_CIRCUITO%TYPE,
    a_nome_cinema cd_cinema.NOME_CINEMA%type,
    a_comune cd_comune.COMUNE%type,
    a_provincia cd_provincia.ABBR%type,
    a_id_sala   cd_comunicato.id_sala%type,                      
    a_nome_sala   cd_sala.nome_sala%type,                      
    a_tipo_break   cd_tipo_break.DESC_TIPO_BREAK%TYPE,
    a_numero_proiezioni varchar2(60),
    a_data_proiezione  date,
    a_soggetto cd_soggetto_di_piano.DESCRIZIONE%TYPE
       
);


TYPE c_certificazione_estesa IS REF CURSOR RETURN r_certificazione_estesa;


TYPE r_prodotto IS RECORD
(
    a_id_prodotto_acquistato    cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO%TYPE,
    a_data_inizio               cd_prodotto_acquistato.data_inizio%TYPE,
    a_data_fine                 cd_prodotto_acquistato.data_fine%TYPE
);

TYPE c_prodotto IS REF CURSOR RETURN r_prodotto;



TYPE r_sale_prodotto IS RECORD
(
    a_id_sala    cd_sala.ID_SALA%type
);

TYPE c_sale_prodotto IS REF CURSOR RETURN r_sale_prodotto;
--
TYPE R_POST_VALUT_PIANO IS RECORD
(
 a_data_erogazione      DATE,
 a_posizione            NUMBER,
 a_num_sale             NUMBER,
 a_tot_spettatori       NUMBER,
 a_durata               NUMBER,
 a_durata_break         NUMBER,
 a_desc_break           cd_tipo_break.DESC_TIPO_BREAK%TYPE
);

TYPE C_POST_VALUT_PIANO IS REF CURSOR RETURN R_POST_VALUT_PIANO;
--
TYPE R_POST_VALUT_FILM IS RECORD
(
 a_data_inizio          DATE,
 a_data_fine            DATE,
 a_nome_spettacolo      cd_spettacolo.nome_spettacolo%TYPE,
 a_genere               cd_genere.DESC_GENERE%type,
 a_target               cd_target.NOME_TARGET%TYPE,
 a_num_sale             NUMBER,
 a_tot_spettatori       NUMBER
);

TYPE C_POST_VALUT_FILM IS REF CURSOR RETURN R_POST_VALUT_FILM;
--
TYPE R_POST_VALUT_SPETT IS RECORD
(
 a_data_erogazione      DATE,
 a_tot_spettatori       NUMBER,
 a_num_sale             NUMBER,
 a_ciclo_chiuso         varchar(4),
 a_data_inizio          date,
 a_data_fine            date,
 a_media_spett_giorno   number,
 a_num_sale_periodo     number,
 a_sum_spett            number
);

TYPE C_POST_VALUT_SPETT IS REF CURSOR RETURN R_POST_VALUT_SPETT;


FUNCTION fu_importi_test(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_RICHIESTA_TEST ;
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_importi_e_dati_base Estrae gli importi del piano e i dati basi del piano stesso
-- --------------------------------------------------------------------------------------------
FUNCTION fu_importi_e_dati_base(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_RICHIESTA_STAMPA_IMPORTI ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_tot_importi_richiesta Estrae gli importi totali del piano
-- --------------------------------------------------------------------------------------------
FUNCTION fu_tot_importi_rich(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_RICHIESTA_TOT_IMPORTI ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_raggrupp_intermed   Estrae le informazioni riguardanti gli intermediari del piano
-- --------------------------------------------------------------------------------------------
FUNCTION fu_raggrupp_intermed(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_RAGGRUPP_INTERMEDIARI ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dati_proposta   Estrae le informazioni "di testata" di una proposta
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dati_proposta(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_TESTATA_PROPOSTA ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dettaglio_proposta_tab   Estrae le informazioni "di dettaglio" di una proposta
--                                      nel caso si tratti di un piano TABELLARE
--
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dettaglio_proposta_tab(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_PROPOSTA ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dettaglio_proposta_isp   Estrae le informazioni "di dettaglio" di una proposta
--                                      nel caso si tratti di un piano INIZIATIVA SPECIALE
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dettaglio_proposta_isp(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_PROPOSTA ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_soggetto_tab   Estrae le informazioni complessive sugli importi, sommate per soggetto
--                              nel caso di pubblicita' TABELLARE
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_soggetto_tab(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_SOGG ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_soggetto_isp   Estrae le informazioni complessive sugli importi, sommate per soggetto
--                              nel caso di INIZIATIVE SPECIALI
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_soggetto_isp(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_SOGG ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_piano_tab   Estrae le informazioni complessive sugli importi, sommate per piano
--                              nel caso di pubblicita' TABELLARE
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_piano_tab(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_PIANO ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_piano_isp   Estrae le informazioni complessive sugli importi, sommate per piano
--                              nel caso di INIZIATIVE SPECIALI
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_piano_isp(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_PIANO ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_famiglia_pubb   Estrae il codice categoria prodotto che, dato piano e versione, indica
--                            quale famiglia pubblicitaria si sta trattando
-- --------------------------------------------------------------------------------------------
FUNCTION fu_famiglia_pubb(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type)
                                RETURN C_FAMIGLIA_PUBB ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dati_piano   Estrae i dati caratteristici del piano in esame (per la testata di stampa calendario)
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dati_piano(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type)
                                RETURN C_DATI_PIANO ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_ragg_int_no_cm   Estrae le informazioni riguardanti gli intermediari del piano
--                              Sono esclusi i dati relativi al centro media (non visualizzato nella stampa calendario)
-- --------------------------------------------------------------------------------------------
FUNCTION fu_ragg_int_no_cm(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type)
                            RETURN C_RAGG_INT_NO_CM ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dettaglio_calendario_tab   NON ESISTE una function  che estrae le informazioni
--                                      "di dettaglio" di una stampa calendario nel caso si tratti di un
--                                      piano TABELLARE in analogia con le INIZ. SPECIALI
--                                      In questo caso si usa una combinazione delle function:
--                                      fu_get_circuiti_e_date - fu_get_cal_dett_pa_pv -
--                                      fu_get_cal_dett_cine
-- --------------------------------------------------------------------------------------------
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dettaglio_calendario_isp   Estrae le informazioni "di dettaglio" di una stampa calendario
--                                      nel caso si tratti di un piano INIZIATIVE SPECIALI
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dettaglio_calendario_isp(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_CALENDARIO ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_get_circuiti_e_date   Estrae le informazioni relative ai circuiti (con le date di proiezione
--                               associate) collegati a un determinato piano; si usa per la stampa calendario
--                               nel caso si tratti di un piano tabellare
-- --------------------------------------------------------------------------------------------
FUNCTION fu_get_circuiti_e_date(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_CIRCUITO_E_DATE ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_get_cal_dett_pa_pv   Estrae le informazioni relative al prodotto acquistato e al prodotto di
--                               vendita collegati a un determinato piano; si usa per la stampa calendario
--                               nel caso si tratti di un piano tabellare
-- --------------------------------------------------------------------------------------------
FUNCTION fu_get_cal_dett_pa_pv(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_CAL_PA_PV ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_get_cal_dett_cine   Estrae le informazioni relative al cinema e alla sala (con numero di
--                               proeizioni) collegati a un determinato piano; si usa per la stampa calendario
--                               nel caso si tratti di un piano tabellare
-- --------------------------------------------------------------------------------------------
FUNCTION fu_get_cal_dett_cine(--p_id_circuito cd_circuito.id_circuito%type,
                                p_id_prototto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                p_id_piano           CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                p_id_ver_piano       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
                                p_id_raggruppamento  CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
                                p_stato_di_vendita      CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
                                p_data_inizio        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_CAL_CINEMA ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dati_prod_rich Estrae gli importi del piano e i dati basi del piano stesso utili per la
--                              stampa prodotti richiesti
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dati_prod_rich(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_PROD_RICHIESTI_IMPORTI ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_tot_prod_rich Estrae gli importi totali (sulle stesse date inizio-fine) dei prodotti richiesti
-- --------------------------------------------------------------------------------------------
FUNCTION fu_tot_prod_rich(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_TOTALI_PROD_RICH ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_tot_prod_rich_piano Estrae gli importi totali (per piano) dei prodotti richiesti
-- --------------------------------------------------------------------------------------------
FUNCTION fu_tot_prod_rich_piano(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN C_TOTALI_PROD_RICH_PIANO ;
--
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dettaglio_proposta_tab_old   Estrae le informazioni "di dettaglio" di una proposta
--                                      nel caso si tratti di un piano TABELLARE
--
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dettaglio_proposta_tab_old(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_PROPOSTA ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dettaglio_proposta_isp_old   Estrae le informazioni "di dettaglio" di una proposta
--                                      nel caso si tratti di un piano INIZIATIVA SPECIALE
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dettaglio_proposta_isp_old(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_PROPOSTA ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_soggetto_tab_old   Estrae le informazioni complessive sugli importi, sommate per soggetto
--                              nel caso di pubblicita' TABELLARE
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_soggetto_tab_old(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_SOGG ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_soggetto_isp_old   Estrae le informazioni complessive sugli importi, sommate per soggetto
--                              nel caso di INIZIATIVE SPECIALI
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_soggetto_isp_old(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_SOGG ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_piano_tab_old   Estrae le informazioni complessive sugli importi, sommate per piano
--                              nel caso di pubblicita' TABELLARE
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_piano_tab_old(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_PIANO ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_totali_piano_isp_old   Estrae le informazioni complessive sugli importi, sommate per piano
--                              nel caso di INIZIATIVE SPECIALI
-- --------------------------------------------------------------------------------------------
FUNCTION fu_totali_piano_isp_old(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_TOTALI_PIANO ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_num_sogg_prod_acq   Estrae le informazioni relative al numero di soggetti differenti per
--                                  tutti i prodotti acquistati del piano in esame
-- --------------------------------------------------------------------------------------------
FUNCTION fu_num_sogg_prod_acq(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_NUM_SOGG_PROD_ACQ ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_desc_sogg_prod_acq   Estrae le descrizioni dei soggetti per
--                                  tutti i prodotti acquistati del piano in esame
-- --------------------------------------------------------------------------------------------
FUNCTION fu_desc_sogg_prod_acq(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_SOGG_PROD_ACQ ;


--
--
--Creata da Mauro Viel Altran italia il 3/12/2009
--Dato un id_prodotto richiesto restituisce la sua durata in secondi.
--per le iniziative speciali la stringa e' vuota
FUNCTION FU_GET_FORMATO_PROD_RIC(P_ID_PRODOTTI_RICHIESTI cd_prodotti_richiesti.ID_PRODOTTI_RICHIESTI%type) RETURN varchar2;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_num_prod_acq_dir_si Fornisce il numero di prodotti acquistati (per il piano in esame) che
-- hanno almeno un valore del netto direzionale maggiore di zero
-- --------------------------------------------------------------------------------------------
FUNCTION fu_num_prod_acq_dir_si(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN NUMBER ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_num_prod_rich_dir_si Fornisce il numero di prodotti richiesti (per il piano in esame) che
-- hanno almeno un valore del netto direzionale maggiore di zero
-- --------------------------------------------------------------------------------------------
FUNCTION fu_num_prod_rich_dir_si(p_id_piano cd_pianificazione.id_piano%type,
                                p_id_ver_piano cd_pianificazione.id_ver_piano%type) RETURN NUMBER ;
--
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_elenco_schermi_tab   Estrae l'elenco degli schermi di proiezione del piano in esame
--                                  per il caso tabellare
-- --------------------------------------------------------------------------------------------
FUNCTION fu_elenco_schermi_tab(p_id_piano CD_PRODOTTO_ACQUISTATO.id_piano%type,
                                p_id_ver_piano CD_PRODOTTO_ACQUISTATO.id_ver_piano%type,
                                p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                p_id_raggruppamento CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
                                p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_DETTAGLIO_ELENCO_SCHERMI ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_estremi_periodo_proiez   Estrae la minima e massima data di proiezione di un piano
--                                      nel caso si tratti di un piano TABELLARE
--
-- --------------------------------------------------------------------------------------------
FUNCTION fu_estremi_periodo_proiez(p_id_piano           CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
                                    p_id_ver_piano       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
                                    p_id_stato_vendita   cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                    p_id_raggruppamento  CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
                                    p_data_inizio        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                    p_data_fine          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE) RETURN C_ESTREMI_PERIODO ;
--
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_testata_ordine Fornisce i dati di testata dell'ordine
-- --------------------------------------------------------------------------------------------
FUNCTION fu_testata_ordine(p_id_ordine cd_ordine.id_ordine%type) RETURN C_TESTATA_ORDINE ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_cliente_fruitore Fornisce i dati del cliente fruitore dell'ordine in esame
-- --------------------------------------------------------------------------------------------
FUNCTION fu_cliente_fruitore(p_id_ordine cd_ordine.id_ordine%type) RETURN C_CLI_FRUITORE_ORDINE ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_cliente_committ Fornisce i dati del cliente committente dell'ordine in esame
-- --------------------------------------------------------------------------------------------
FUNCTION fu_cliente_committ(p_id_ordine cd_ordine.id_ordine%type) RETURN C_CLI_FRUITORE_ORDINE ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_dettaglio_ordine Fornisce i dati di dettaglio dell'ordine
-- --------------------------------------------------------------------------------------------
FUNCTION fu_dettaglio_ordine(p_id_ordine cd_ordine.id_ordine%type) RETURN C_PRODOTTO_ORDINE ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_desc_sogg_ordine   Estrae le descrizioni dei soggetti per l'ordine in esame
-- --------------------------------------------------------------------------------------------
FUNCTION fu_desc_sogg_ordine(p_id_ordine cd_ordine.id_ordine%type) RETURN C_SOGG_PROD_ACQ ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_lista_copie_conf_ordine   Estrae l'elenco delle copie conformi per l'ordine in esame
-- --------------------------------------------------------------------------------------------
FUNCTION fu_lista_copie_conf_ordine(p_id_ordine cd_ordine.id_ordine%type) RETURN C_COPIE_CONF_ORDINE ;
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_copia_conf_ordine   Estrae il contenuto del pdf per la copia conforme specificata
-- --------------------------------------------------------------------------------------------
FUNCTION fu_copia_conf_ordine(p_id_stampa cd_stampe_ordine.id_stampe_ordine%type) RETURN C_DATI_COPIA_CONF_ORDINE ;
--
--- --------------------------------------------------------------------------------------------
-- PROCEDURE pr_ins_copia_conf_ordine   Inserisce una copia conforme per l'ordine specificato
-- --------------------------------------------------------------------------------------------
PROCEDURE pr_ins_copia_conf_ordine( p_id_ordine cd_stampe_ordine.ID_ORDINE%type,
                                    p_data_stampa cd_stampe_ordine.DATA_STAMPA%type,
                                    p_pdf cd_stampe_ordine.pdf%type,
                                    p_esito out number);
--
--
--- --------------------------------------------------------------------------------------------
-- PROCEDURE pr_ins_copia_conf_null   Inserisce una copia conforme null per l'ordine specificato
-- --------------------------------------------------------------------------------------------
PROCEDURE pr_ins_copia_conf_null( p_id_ordine cd_stampe_ordine.ID_ORDINE%type,
                                    p_data_stampa cd_stampe_ordine.DATA_STAMPA%type,
                                    p_id_stampa_ordine out cd_stampe_ordine.ID_STAMPE_ORDINE%type);
--
--- --------------------------------------------------------------------------------------------
-- FUNCTION fu_lungh_copia_ordine   Estrae la dimensione del contenuto del pdf per la copia conforme specificata
-- --------------------------------------------------------------------------------------------
FUNCTION fu_lungh_copia_ordine(p_id_stampa cd_stampe_ordine.id_stampe_ordine%type) RETURN INTEGER ;
--
--- --------------------------------------------------------------------------------------------
-- PROCEDURE pr_upd_copia_conf   Modifica la copia conforme specificata
-- --------------------------------------------------------------------------------------------
PROCEDURE pr_upd_copia_conf( p_id_stampa cd_stampe_ordine.ID_STAMPE_ORDINE%type,
                                    p_num_byte INTEGER,
                                    p_buffer RAW,
                                    p_esito out number);
--
FUNCTION FU_ELENCO_FILM(p_id_piano cd_prodotto_acquistato.ID_PIANO%TYPE, p_id_ver_piano cd_prodotto_acquistato.ID_VER_PIANO%TYPE, p_data_inizio cd_prodotto_acquistato.data_inizio%TYPE, p_data_fine cd_prodotto_acquistato.data_fine%TYPE, p_target char) RETURN C_FILM;


function fu_dett_previsione_fattura(p_id_piano cd_pianificazione.id_piano%type,p_id_ver_piano cd_pianificazione.id_ver_piano%type, p_data_inizio date, p_data_fine date)  return c_previsione_fattura;

function fu_elenco_decurtazioni(p_data_inizio date,p_data_fine date,p_cod_esercente vi_cd_societa_esercente.COD_ESERCENTE%type) return C_STAMPA_DECURTAZIONE;

function fu_get_sala_isp(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) return varchar2;

FUNCTION fu_num_prod_acq_dir_lordo_si(p_id_piano       cd_pianificazione.id_piano%TYPE,
                                  p_id_ver_piano   cd_pianificazione.id_ver_piano%TYPE,
                                  p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
                                  p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
                                  p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                  p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE)
RETURN NUMBER;

--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_PROIEZIONE_ESEGUITA   Ritorna 1 se la proiezione e' andata in onda, 0 altrimenti
-- --------------------------------------------------------------------------------------------
FUNCTION FU_PROIEZIONE_ESEGUITA(    p_id_prodotto_acquistato    CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
                                    p_id_sala                   CD_COMUNICATO.ID_SALA%TYPE,
                                    p_data_rif                  CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE
                               )
                               RETURN NUMBER;
                               
--- --------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_CAUSALE   Ritorna la chiave di CD_CODICE_RESP per la causale
-- --------------------------------------------------------------------------------------------
FUNCTION FU_GET_CAUSALE(            p_id_sala   CD_LIQUIDAZIONE_SALA.ID_SALA%TYPE,
                                    p_data_rif  CD_LIQUIDAZIONE_SALA.DATA_RIF%TYPE
                               )
                               RETURN NUMBER;                               
                               
                               
  FUNCTION fu_get_cal_dett_cine_xls (
   --     p_id_circuito       cd_circuito.id_circuito%TYPE,
        p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
        p_id_piano           CD_PRODOTTO_ACQUISTATO.ID_PIANO%TYPE,
        p_id_ver_piano       CD_PRODOTTO_ACQUISTATO.ID_VER_PIANO%TYPE,
        p_id_circuito        CD_CIRCUITO.ID_CIRCUITO%TYPE,
        p_id_raggruppamento  CD_PRODOTTO_ACQUISTATO.ID_RAGGRUPPAMENTO%TYPE,
        p_stato_di_vendita   CD_PRODOTTO_ACQUISTATO.STATO_DI_VENDITA%TYPE,
        p_data_inizio        CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine          CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_CAL_CINEMA_XLS; 
      
      
   FUNCTION fu_dettaglio_cal_isp_xls (
        p_id_piano       cd_pianificazione.id_piano%TYPE,
        p_id_ver_piano cd_pianificazione.id_ver_piano%type,
        p_id_stato_vendita cd_stato_di_vendita.DESCR_BREVE%TYPE,
        p_id_raggruppamento cd_raggruppamento_intermediari.ID_RAGGRUPPAMENTO%TYPE,
        p_data_inizio CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
        p_data_fine CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE
   )
      RETURN C_DETTAGLIO_CALENDARIO_XLS; 
     
   
      function fu_dett_certificazione_breve(p_id_piano               cd_pianificazione.id_piano%type,
                                           p_id_ver_piano            cd_pianificazione.id_ver_piano%type,
                                           p_id_prodotto_acquistato  cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                           p_data_inizio             cd_prodotto_acquistato.data_inizio%type,
                                           p_data_fine               cd_prodotto_acquistato.data_fine%type 
     ) return c_certificazione_breve;
     
 function fu_get_prodotti(             p_id_piano               cd_pianificazione.id_piano%type,
                                       p_id_ver_piano            cd_pianificazione.id_ver_piano%type,
                                       p_data_inizio             cd_prodotto_acquistato.data_inizio%type,
                                       p_data_fine               cd_prodotto_acquistato.data_fine%type 
     ) return c_prodotto;
      


function fu_dett_certificazione             (p_id_piano              cd_pianificazione.id_piano%type,
                                            p_id_ver_piano           cd_pianificazione.id_ver_piano%type,
                                            p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                            p_data_proiezione        cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                            p_id_sala                cd_sala.ID_SALA%type,
                                            p_data_inizio            cd_prodotto_acquistato.data_inizio%type,
                                            p_data_fine              cd_prodotto_acquistato.data_fine%type 
     ) return c_certificazione; 
     
     
function fu_get_sale_prodotto(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type
) return c_sale_prodotto;  


FUNCTION FU_NUMERO_PROIEZIONI(p_id_sala   CD_COMUNICATO.ID_SALA%TYPE,
                              p_data_erogazione_prev  CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
                              p_id_materiale  CD_MATERIALE.ID_MATERIALE%TYPE
                              )
    RETURN   varchar2;    
    
    
 function fu_dett_certificazione_estesa    (p_id_piano               cd_pianificazione.id_piano%type,
                                            p_id_ver_piano           cd_pianificazione.id_ver_piano%type,
                                            p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,
                                            p_data_proiezione        cd_comunicato.DATA_EROGAZIONE_PREV%type,
                                            p_id_sala                cd_sala.ID_SALA%type,
                                            p_data_inizio            cd_prodotto_acquistato.data_inizio%type,
                                            p_data_fine              cd_prodotto_acquistato.data_fine%type 
     ) return c_certificazione_estesa;    
--
FUNCTION FU_POST_VALUT_SPETT    ( P_ID_PIANO               CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                  P_ID_VER_PIANO           CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE
                                ) RETURN C_POST_VALUT_SPETT;
--
FUNCTION FU_POST_VALUT_PIANO    ( P_ID_PIANO               CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                  P_ID_VER_PIANO           CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                  P_ORDINAMENTO            number
                                 ) RETURN C_POST_VALUT_PIANO;
--
FUNCTION FU_POST_VALUT_FILM    (P_ID_PIANO               CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                P_ID_VER_PIANO           CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE
                               ) RETURN C_POST_VALUT_FILM; 
                               
FUNCTION fu_asterisco_sala_variabile(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type) RETURN varchar2;
FUNCTION fu_nome_cliente(p_id_piano cd_pianificazione.id_piano%type) RETURN varchar2;  

---------------------------------------------------------------------------------------------------
-- FUNCTION FU_GET_PROD_CERTIFICAZIONE
--
-- DESCRIZIONE:  Ritorna l'elenco dei prodotti acquistati necessari per la certificazione piani
--
--
-- INPUT:
--      p_id_piano
--      p_id_ver_piano
--      p_data_inizio
--      p_data_fine
--
-- OUTPUT: lista di c_prodotto
--          
--
-- REALIZZATORE: Tommaso D'Anna, 26 Maggio 2011
--
--  MODIFICHE: 
--             
-------------------------------------------------------------------------------------------------
 FUNCTION FU_GET_PROD_CERTIFICAZIONE(  p_id_piano       CD_PIANIFICAZIONE.ID_PIANO%TYPE,
                                       p_id_ver_piano   CD_PIANIFICAZIONE.ID_VER_PIANO%TYPE,
                                       p_data_inizio    CD_PRODOTTO_ACQUISTATO.DATA_INIZIO%TYPE,
                                       p_data_fine      CD_PRODOTTO_ACQUISTATO.DATA_FINE%TYPE 
     ) RETURN C_PRODOTTO; 
     
     

/*
Restituisce il numero di proiezioni ottenuto come numero di giorni di un prodotto moltiplicato per il numero di schermi moltipilicato 
per 4 nel caso di sala e moltiplicato per 1 nel caso di arena
*/

function fu_get_numero_proiezioni(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type, p_id_prodotti_richiesti cd_prodotti_richiesti.id_prodotti_richiesti%type) return number;

                                     
END PA_CD_STAMPE_MAGAZZINO; 
/

