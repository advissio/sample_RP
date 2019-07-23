CREATE OR REPLACE PACKAGE VENCD.PA_CD_IMPORTI AS
/******************************************************************************
   NAME:       PA_CD_IMPORTI
   PURPOSE:    Gestione degli importi del cinema digitale

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22/10/2009  Mauro Viel Altran     1. Pacchetto contenenente le
                                                procedure per la gestione degli importi.
                                                Si rende necessaria l'implementazione di questo pacchetto
                                                perche il pacchetto pa_pc_importi non gestisce gli importi di
                                                di tipo direzionale e commerciale
******************************************************************************/

-- MODIFICA :  21/05/2010 inserita la procedura RIPARTIZIONE_LORDO. 
--
-- MODIFICA DI DANIELA SPEZIA, 11.01.2010: ho spostato a livello di package e non private
-- le eccezioni definite qui di seguito

ERR_VERIFICA            exception;
ERR_IMPORTO_VARIATO     exception;
ERRORE_GENERICO         exception;
NESSUNA_VARIAZIONE      exception;
VALORE_NEGATIVO         exception;
NETTO_ECCESSIVO         exception;
SC_COMM_ECCESSIVO       exception;
PERC_SCONTO_NON_VALIDA  exception;
IMP_SANATORIA_ECCESSIVO exception;
SCONTO_REC_ECCESSIVO    exception;
ERR_EQUAZIONE_LORDO     exception;
ERR_EQUAZIONE_SCONTO    exception;
ERR_EQUAZIONE_GENERALE  exception;
ERR_EQUAZIONE_TAR       exception;
ERR_EQUAZ_PERC_SC_COMM  exception;
--
--
-----------------------------------------------------------------------------------------------------------
--   Funzione FU_VERIFICA_IMPORTI
--
--   DESCRIZIONE:
--     Verifica le equazioni fondamentali che regolano gli importi
--
--   INPUT: Lordo commerciale
--          Netto
--          Sconto commerciale
--          % di Sconto commerciale
--
--   OUTPUT:
--     la funzione restituisce l'esito della verifica con i seguenti valori:
--       1 : OK
--
--   ECCEZIONI:
--     -20101, Importi iniziali non  validi
--     -20105, Presenza valori nulli o negativi non ammessi
--     -20112, Verifica dell equazione: "Sconto Commerciale = Omaggio + Sconto finanziario" non rispettata
--     -20113, Verifica dell equazione: "Lordo = Netto + Sc. Comm. + Sanatoria + Recupero" non rispettata
--     -20114, Verifica dell equazione: "Lordo = Tariffa + Maggiorazioni tariffarie" non rispettata
--     -20115, Verifica dell equazione: "% Sconto Commerciale = Sc. Comm. / Lordo Comm." non rispettata
--     -20103, Si e verificato un errore imprevisto. Messaggio derrore :sqlerrm
--
--   REALIZZATORE:
--     luigi cipolla, 22/10/2009
--
--   modifiche:
-----------------------------------------------------------------------------------------------------------
function FU_VERIFICA_IMPORTI(
  P_TARIFFA                 in  number default null, -- tariffa
  P_MAGG                    in  number default null, -- maggiorazione
  P_LORDO                   in  number,               -- lordo
  P_LORDO_COMM_COM          in  number,               -- lordo_commerciale quota commerciale
  P_LORDO_COMM_DIR          in  number,               -- lordo_commerciale quota direzionale
  P_NETTO_COM               in  number,               -- netto quota commerciale
  P_NETTO_DIR               in  number,               -- netto quota direzionale
  P_PERC_SC_COMM_COM        in  number,               -- percentuale di sconto commerciale quota commerciale
  P_PERC_SC_COMM_DIR        in  number,               -- percentuale di sconto commerciale quota direzionale
  P_SC_COMM_COM             in  number,               -- importo di sconto commerciale quota commerciale
  P_SC_COMM_DIR             in  number,               -- importo di sconto commerciale quota direzionale
  P_SANATORIA               in  number default null, -- sanatoria
  P_RECUPERO                in  number default null  -- recupero
  ) RETURN NUMBER;
-----------------------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------------------
--
--   Procedura MODIFICA_IMPORTI
--
--   DESCRIZIONE:
--     Determina il nuovo valore di tutti gli importi, a fronte della variazione
--     di un importo specificato, tra quelli per cui e' prevista la variazione,
--     indicati con relativo codice.
--
--   INPUT: - valore degli importi antecedenti la modifica;
--          - codice e valore (ammessi solo due decimali) dell'importo variato;
--            il codice dell'importo e' indicato nel commento a margine degli importi.
--
--     N.B. Il valore della tariffa e' necessario solo in caso di modifica della maggiorazione
--          o della tariffa stessa.
--          In caso di variazione di maggiorazione, il parametro P_TARIFFA dovra' essere
--          coerente con la nuova maggiorazione. Analogamente, in caso di variazione di tariffa,
--          il parametro P_MAGG dovra essere coerente con la nuova tariffa.
--
--   OUTPUT: - valore degli importi successivi alla modifica
--           - esito: 1 = OK
--
--   ECCEZIONI:
--     -20101, Importi iniziali non  validi
--     -20102, Importo modificato non valido
--     -20104, Non e stata applicata nessuna variazione
--     -20105, Presenza valori nulli o negativi non ammessi
--     -20106, Nuovo valore di Netto maggiore di quanto consentito
--     -20107, Nuovo valore di Sconto Commerciale maggiore di quanto consentito
--     -20108, Nuovo valore di % Sconto Commerciale non valido
--     -20109, Nuovo valore di Sanatoria maggiore del consentito
--     -20110, Nuovo valore di sconto recupero maggiore del consentito
--     -20111, Verifica dell equazione: "Lordo Comm. = Netto + Sc. Comm." non rispettata
--     -20115, Verifica dell equazione: "% Sconto Commerciale = Sc. Comm. / Lordo Comm." non rispettata
--     -20103, Si e verificato un errore imprevisto. Messaggio derrore :sqlerrm
--
--   AUTORE:
--     Luigi Cipolla, 22/10/2009
--
--   MODIFICHE:
--
-----------------------------------------------------------------------------------------------------------
PROCEDURE MODIFICA_IMPORTI (
  P_TARIFFA             in out number, -- codice 0  - tariffa
  P_MAGG                in out number, -- codice 1  - maggiorazione
  P_LORDO               in out number, -- codice 2  - lordo
  P_LORDO_COMM_COM      in out number, -- codice 21 - lordo_commerciale quota commerciale
  P_LORDO_COMM_DIR      in out number, -- codice 22 - lordo_commerciale quota direzionale
  P_NETTO_COM           in out number, -- codice 31 - netto quota commerciale
  P_NETTO_DIR           in out number, -- codice 32 - netto quota direzionale
  P_PERC_SC_COMM_COM    in out number, -- codice 41 - percentuale di sconto commerciale quota commerciale
  P_PERC_SC_COMM_DIR    in out number, -- codice 42 - percentuale di sconto commerciale quota direzionale
  P_SC_COMM_COM         in out number, -- codice 51 - importo di sconto commerciale quota comerciale
  P_SC_COMM_DIR         in out number, -- codice 52 - importo di sconto commerciale quota direzionale
  P_SANATORIA           in out number, -- codice 8  - sconto sanatoria
  P_RECUPERO            in out number, -- codice 9  - sconto recupero
  P_NEW_IMPORTO         in     number, --             importo variato
  P_COD_IMPORTO         in     number, --             codice importo variato
  P_ESITO               out    number  --             esito procedura
  );
  
  -----------------------------------------------------------------------------------------------------------
--   Procedura RIPARTIZIONE_LORDO
--
--   DESCRIZIONE:
--     Suddivide il Lordo Commerciale nella quota COMMERCIALE e quota DIREZIONALE in ragione dei valori in
--     input.
--
--   INPUT: Lordo commerciale
--          Netto - quota commerciale
--          Netto - quota direzionale
--          % di Sconto comm. - quota commerciale  o, in alternativa, % di Sconto comm. - quota direzionale
--
--   OUTPUT:
--          Lordo - quota commerciale
--          Lordo - quota direzionale
--          % di Sconto comm. - quota commerciale  
--          % di Sconto comm. - quota direzionale
--          % di Sconto comm. complessiva
--
--   ECCEZIONI:
--     -20101, Importi iniziali non  validi
--     -20105, Presenza valori nulli o negativi non ammessi
--     -20112, Verifica dell equazione: "Sconto Commerciale = Omaggio + Sconto finanziario" non rispettata
--     -20113, Verifica dell equazione: "Lordo = Netto + Sc. Comm. + Sanatoria + Recupero" non rispettata
--     -20114, Verifica dell equazione: "Lordo = Tariffa + Maggiorazioni tariffarie" non rispettata
--     -20115, Verifica dell equazione: "% Sconto Commerciale = Sc. Comm. / Lordo Comm." non rispettata
--     -20103, Si e verificato un errore imprevisto. Messaggio derrore :sqlerrm
--
--   REALIZZATORE:
--     luigi cipolla, 22/10/2009
--
--   modifiche: Simone Bottani 24/05/2010 Aggiunti in output gli importi di sconto
procedure RIPARTIZIONE_LORDO(
  p_lordo_comm   in number,
  p_netto_com    in number,
  p_netto_dir    in number,
  p_perc_sc_com  in out number,
  p_perc_sc_dir  in out number,
  p_lordo_com    out number,
  p_lordo_dir    out number,
  p_sconto_com   out number,
  p_sconto_dir   out number);
  
  
END;
----------------------------------------------------------------------------------------------------------- 
/

