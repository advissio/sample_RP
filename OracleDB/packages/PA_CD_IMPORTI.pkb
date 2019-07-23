CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_IMPORTI AS
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
-- Variabili di package
--
-- MODIFICA DI DANIELA SPEZIA, 11.01.2010: ho spostato a livello di package e non private
-- le eccezioni che erano definite qui di seguito
--
--
-----------------------------------------------------------------------------------------------------------
--   Funzione privata FU_VERIFICA_IMPORTI_CINEMA
--
--   DESCRIZIONE:
--     Verifica le equazioni fondamentali che regolano gli importi:
--     1. Lordo Commerciale = Netto + Sc. Comm.
--     2. % Sconto Commerciale = Sc. Comm. / Lordo Comm.
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
--     -20105, Presenza valori nulli o negativi non ammessi
--     -20111, Verifica dell equazione: "Lordo Comm. = Netto + Sc. Comm." non rispettata
--     -20115, Verifica dell equazione: "% Sconto Commerciale = Sc. Comm. / Lordo Comm." non rispettata
--
--   REALIZZATORE:
--     luigi cipolla, 22/10/2009
--
--   modifiche:
-----------------------------------------------------------------------------------------------------------



function FU_VERIFICA_IMPORTI_CINEMA(
  P_LORDO_COMM          in  number,               -- lordo_commerciale
  P_NETTO               in  number,               -- netto
  P_SC_COMM             in  number,               -- sconto commerciale
  P_PERC_SC_COMM        in  number                -- percentuale di sconto commerciale
  ) RETURN NUMBER
is
BEGIN
  --
  -- Verifica presenza di importi nulli o negativi.
  if nvl(P_LORDO_COMM   , -1) <0 or
     nvl(P_NETTO        , -1) <0 or
     nvl(P_SC_COMM      , -1) <0 or
     nvl(P_PERC_SC_COMM , -1) <0
  then
    raise VALORE_NEGATIVO;
  end if;
  --
  -- Verifica equazione: Lordo Comm. = Netto + Sc. Comm.
  if P_LORDO_COMM != PA_PC_IMPORTI.FU_LORDO_COMM(P_NETTO, P_SC_COMM) then
    raise ERR_EQUAZIONE_LORDO;
  end if;
  --
  -- Verifica equazione: % Sc. Comm. = Sc. Comm. / Lordo Comm
  if round(P_PERC_SC_COMM,2) != PA_PC_IMPORTI.FU_PERC_SC_COMM(P_NETTO, P_SC_COMM) then
    raise ERR_EQUAZ_PERC_SC_COMM;
  end if;
  --
  return 1;
exception
when VALORE_NEGATIVO         then
     RAISE_APPLICATION_ERROR(-20105, 'Presenza valori nulli o negativi non ammessi');
when ERR_EQUAZIONE_LORDO     then
     RAISE_APPLICATION_ERROR(-20111, 'Verifica dell'' equazione: "Lordo Comm. = Netto + Sc. Comm." non rispettata');
when ERR_EQUAZ_PERC_SC_COMM  then
     RAISE_APPLICATION_ERROR(-20115, 'Verifica dell'' equazione: "% Sconto Commerciale = Sc. Comm. / Lordo Comm." non rispettata');
end FU_VERIFICA_IMPORTI_CINEMA;
-----------------------------------------------------------------------------------------------------------
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
  P_LORDO_COMM_COM          in  number,               -- lordo_commerciale
  P_LORDO_COMM_DIR          in  number,               -- lordo_direzionale
  P_NETTO_COM               in  number,               -- netto_commerciale
  P_NETTO_DIR               in  number,               -- netto_direzionale
  P_PERC_SC_COMM_COM        in  number,               -- percentuale di sconto commerciale commerciale
  P_PERC_SC_COMM_DIR        in  number,               -- percentuale di sconto commerciale direzionale
  P_SC_COMM_COM             in  number,               -- importo di sconto commerciale quota commerciale
  P_SC_COMM_DIR             in  number,               -- importo di sconto commerciale quota direzionale
  P_SANATORIA               in  number default null, -- sanatoria
  P_RECUPERO                in  number default null  -- recupero
  ) RETURN NUMBER
is
  V_NETTO          number := P_NETTO_COM + P_NETTO_DIR;
  V_SC_COMM        number := P_SC_COMM_COM + P_SC_COMM_DIR;
  V_PERC_SC_COMM   number := PA_PC_IMPORTI.FU_PERC_SC_COMM(V_NETTO, V_SC_COMM);
  V_OMAGGIO        number := V_SC_COMM;
  V_SC_FIN         number := 0;
  V_ESITO          number := null;
begin
  --
  V_ESITO:= FU_VERIFICA_IMPORTI_CINEMA(
              P_LORDO_COMM_COM,
              P_NETTO_COM,
              P_SC_COMM_COM,
              P_PERC_SC_COMM_COM);
  --
  V_ESITO:= FU_VERIFICA_IMPORTI_CINEMA(
              P_LORDO_COMM_DIR,
              P_NETTO_DIR,
              P_SC_COMM_DIR,
              P_PERC_SC_COMM_DIR);
  --
  V_ESITO := PA_PC_IMPORTI.FU_VERIFICA_IMPORTI_MAGAZZINO(
               P_TARIFFA,
               P_MAGG,
               P_LORDO,
               V_NETTO,
               V_PERC_SC_COMM,
               V_SC_COMM,
               V_OMAGGIO,
               V_SC_FIN,
               P_SANATORIA,
               P_RECUPERO);
  if V_ESITO = -1 then raise ERR_VERIFICA;
  elsif V_ESITO = -52 then raise VALORE_NEGATIVO;
  elsif V_ESITO = -61 then raise ERR_EQUAZIONE_SCONTO;
  elsif V_ESITO = -62 then raise ERR_EQUAZIONE_GENERALE;
  elsif V_ESITO = -53 then raise ERR_EQUAZIONE_TAR;
  elsif V_ESITO = -58 then raise ERR_EQUAZ_PERC_SC_COMM;
  elsif V_ESITO<0 then raise ERRORE_GENERICO;
  end if;
  --
  return 1;
  --
exception
when ERR_VERIFICA  then
     RAISE_APPLICATION_ERROR(-20101, 'Importi iniziali non  validi');
when VALORE_NEGATIVO         then
     RAISE_APPLICATION_ERROR(-20105, 'Presenza valori nulli o negativi non ammessi');
when ERR_EQUAZIONE_SCONTO    then
     RAISE_APPLICATION_ERROR(-20112, 'Verifica dell'' equazione: "Sconto Commerciale = Omaggio + Sconto finanziario" non rispettata');
when ERR_EQUAZIONE_GENERALE  then
     RAISE_APPLICATION_ERROR(-20113, 'Verifica dell'' equazione: "Lordo = Netto + Sc. Comm. + Sanatoria + Recupero" non rispettata');
when ERR_EQUAZIONE_TAR       then
     RAISE_APPLICATION_ERROR(-20114, 'Verifica dell'' equazione: "Lordo = Tariffa + Maggiorazioni tariffarie" non rispettata');
when ERR_EQUAZ_PERC_SC_COMM  then
     RAISE_APPLICATION_ERROR(-20115, 'Verifica dell'' equazione: "% Sconto Commerciale = Sc. Comm. / Lordo Comm." non rispettata');
when ERRORE_GENERICO         then
     RAISE_APPLICATION_ERROR(-20103, 'Si e verificato un errore imprevisto. Messaggio d''errore :'||sqlerrm);
end FU_VERIFICA_IMPORTI;
-----------------------------------------------------------------------------------------------------------
--
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
--
--     A T T E N Z I O N E:
--
--     In caso di variazione di maggiorazione, il parametro P_TARIFFA dovra' essere
--     coerente con la nuova maggiorazione. Analogamente, in caso di variazione di tariffa,
--     il parametro P_MAGG dovra essere coerente con la nuova tariffa.
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
--
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
  P_SC_COMM_COM         in out number, -- codice 51 - importo di sconto commerciale quota commerciale
  P_SC_COMM_DIR         in out number, -- codice 52 - importo di sconto commerciale quota direzionale
  P_SANATORIA           in out number, -- codice 8  - sconto sanatoria
  P_RECUPERO            in out number, -- codice 9  - sconto recupero
  P_NEW_IMPORTO         in     number, --             importo variato
  P_COD_IMPORTO         in     number, --             codice importo variato
  P_ESITO               out    number  --             esito procedura
  )
is
  V_TARIFFA        number := P_TARIFFA;
  V_MAGG           number := P_MAGG;
  V_LORDO          number := P_LORDO;
  V_LORDO_COMM_COM number := P_LORDO_COMM_COM;
  V_LORDO_COMM_DIR number := P_LORDO_COMM_DIR;
  V_NETTO_COM      number := P_NETTO_COM;
  V_NETTO_DIR      number := P_NETTO_DIR;
  V_NETTO          number := P_NETTO_COM + P_NETTO_DIR;
  V_SC_COMM_COM    number := P_SC_COMM_COM;
  V_SC_COMM_DIR    number := P_SC_COMM_DIR;
  V_SC_COMM        number := P_SC_COMM_COM + P_SC_COMM_DIR;
  V_PERC_SC_COMM_COM   number := P_PERC_SC_COMM_COM;
  V_PERC_SC_COMM_DIR   number := P_PERC_SC_COMM_DIR;
  V_PERC_SC_COMM   number;
  V_OMAGGIO        number;
  V_SC_FIN         number ;
  V_SANATORIA      number := P_SANATORIA;
  V_RECUPERO       number := P_RECUPERO;
  V_NEW_IMPORTO    number := round(P_NEW_IMPORTO,2);
  V_NEW_IMP_TEMP   number := V_NEW_IMPORTO;
  V_COD_IMPORTO    number := P_COD_IMPORTO;
  V_ESITO          number;
  --
  V_NUOVO_NETTO          number := V_NETTO;
  V_NUOVO_SC_COMM        number := V_SC_COMM;
  V_LORDO_COMM           number;
  V_NUOVO_LORDO_COMM     number;
  --
  delta_importo    number(15,2);
  --
begin
  P_ESITO := 0;
  --
  if V_COD_IMPORTO in (0,1,2,21,22,8,9) then
    --
    if V_COD_IMPORTO = 21 then
      -- modifica lordo_commerciale quota commerciale
      delta_importo    := V_NEW_IMPORTO - V_LORDO_COMM_COM;
      if delta_importo = 0 then raise NESSUNA_VARIAZIONE;
      end if;
      V_LORDO_COMM_COM := V_NEW_IMPORTO;
      V_LORDO_COMM_DIR := V_LORDO_COMM_DIR - delta_importo;
      --
    elsif V_COD_IMPORTO = 22 then
      -- modifica lordo_commerciale quota direzionale
      delta_importo    := V_NEW_IMPORTO - V_LORDO_COMM_DIR;
      if delta_importo = 0 then raise NESSUNA_VARIAZIONE;
      end if;
      V_LORDO_COMM_DIR := V_NEW_IMPORTO;
      V_LORDO_COMM_COM := V_LORDO_COMM_COM - delta_importo;
      --
    elsif V_COD_IMPORTO in (0,1,2,8,9) then
      --
      V_PERC_SC_COMM := PA_PC_IMPORTI.FU_PERC_SC_COMM(V_NETTO, V_SC_COMM);
      V_OMAGGIO := V_SC_COMM;
      V_SC_FIN  := 0;
      PA_PC_IMPORTI.MODIFICA_IMPORTI_MAGAZZINO(
        V_TARIFFA       , -- codice 0 - tariffa
        V_MAGG          , -- codice 1 - maggiorazione
        V_LORDO         , -- codice 2 - lordo
        V_NUOVO_NETTO   , -- codice 3 - netto
        V_PERC_SC_COMM  , -- codice 4 - percentuale di sconto commerciale
        V_NUOVO_SC_COMM , -- codice 5 - importo di sconto commerciale
        V_OMAGGIO       , -- codice 6 - sconto omaggio
        V_SC_FIN        , -- codice 7 - sconto finanziario
        V_SANATORIA     , -- codice 8 - sconto sanatoria
        V_RECUPERO      , -- codice 9 - sconto recupero
        V_NEW_IMP_TEMP  , --            importo variato
        V_COD_IMPORTO   , --            codice importo variato
        V_ESITO           --            esito procedura
      );
      if V_ESITO = 0 then raise NESSUNA_VARIAZIONE;
      elsif V_ESITO = -1 then raise ERR_VERIFICA;
      elsif V_ESITO = -2 then raise ERR_IMPORTO_VARIATO;
      elsif V_ESITO = -52 then raise VALORE_NEGATIVO;
      elsif V_ESITO = -54 then raise NETTO_ECCESSIVO;
      elsif V_ESITO = -55 then raise PERC_SCONTO_NON_VALIDA;
      elsif V_ESITO = -56 then raise SC_COMM_ECCESSIVO;
      elsif V_ESITO = -59 then raise IMP_SANATORIA_ECCESSIVO;
      elsif V_ESITO = -60 then raise SCONTO_REC_ECCESSIVO;
      elsif V_ESITO<0 then raise ERRORE_GENERICO;
      end if;
      --
      -- calcolo i nuovi valori di lordo_commerciale quota commerciale e direzionale
      -- Per quanto possibile, una variazione di lordo commerciale viene ribaltata sulla quota commerciale;
      -- se questa non e sufficiente a contenere la variazione, allora viene toccata la quota direzionale.
      --
      V_LORDO_COMM := PA_PC_IMPORTI.FU_LORDO_COMM( V_NETTO, V_SC_COMM);
      V_NUOVO_LORDO_COMM := PA_PC_IMPORTI.FU_LORDO_COMM( V_NUOVO_NETTO, V_NUOVO_SC_COMM);
      delta_importo    := V_NUOVO_LORDO_COMM - V_LORDO_COMM;
      if V_LORDO_COMM_COM > - delta_importo then
        V_LORDO_COMM_COM := V_LORDO_COMM_COM + delta_importo;
      else
        V_LORDO_COMM_COM := 0;
        V_LORDO_COMM_DIR := V_NUOVO_LORDO_COMM;
      end if;
    end if;
    V_OMAGGIO := V_SC_COMM_COM;
    V_SC_FIN  := 0;
    /*dbms_output.PUT_LINE('-------------Valori vecchi-----------');
    dbms_output.PUT_LINE('V_LORDO_COMM_COM: '||V_LORDO_COMM_COM);
    dbms_output.PUT_LINE('P_LORDO_COMM_COM: '||P_LORDO_COMM_COM);
    dbms_output.PUT_LINE('V_NETTO_COM: '||V_NETTO_COM);
    dbms_output.PUT_LINE('V_PERC_SC_COMM_COM: '||V_PERC_SC_COMM_COM);
    dbms_output.PUT_LINE('V_SC_COMM_COM: '||V_SC_COMM_COM);*/
  
    PA_PC_IMPORTI.MODIFICA_LORDO_COMM(
      V_LORDO_COMM_COM  ,   -- importo lordo variato
      P_LORDO_COMM_COM  ,   -- importo lordo originale
      V_NETTO_COM       ,   -- importo netto originale
      V_PERC_SC_COMM_COM,   -- percentuale di sconto originale
      V_SC_COMM_COM     ,   -- importo sconto commerciale originale
      V_OMAGGIO         ,   -- importo sconto omaggio originale
      V_SC_FIN          ,   -- importo sconto finanziario originale
      V_ESITO               -- esito procedura
     );
     
    V_PERC_SC_COMM_COM := PA_PC_IMPORTI.FU_PERC_SC_COMM(V_NETTO_COM, V_SC_COMM_COM);
    if V_ESITO =-52 then raise VALORE_NEGATIVO;
    elsif v_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    V_OMAGGIO := V_SC_COMM_DIR;
    V_SC_FIN  := 0;
    PA_PC_IMPORTI.MODIFICA_LORDO_COMM(
      V_LORDO_COMM_DIR  ,   -- importo lordo variato
      P_LORDO_COMM_DIR  ,   -- importo lordo originale
      V_NETTO_DIR       ,   -- importo netto originale
      V_PERC_SC_COMM_DIR,   -- percentuale di sconto originale
      V_SC_COMM_DIR     ,   -- importo sconto commerciale originale
      V_OMAGGIO         ,   -- importo sconto omaggio originale
      V_SC_FIN          ,   -- importo sconto finanziario originale
      V_ESITO               -- esito procedura
     );
    V_PERC_SC_COMM_DIR := PA_PC_IMPORTI.FU_PERC_SC_COMM(V_NETTO_DIR, V_SC_COMM_DIR);
    if V_ESITO =-52 then raise VALORE_NEGATIVO;
    elsif V_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    --
  elsif V_COD_IMPORTO = 31 then
    V_NETTO_COM := V_NEW_IMPORTO;
    if V_NETTO_COM = P_NETTO_COM then raise NESSUNA_VARIAZIONE;
    end if;
    V_OMAGGIO := V_SC_COMM_COM;
    PA_PC_IMPORTI.MODIFICA_NETTO(
      V_NETTO_COM       ,  -- importo netto variato
      P_NETTO_COM       ,  -- importo netto originale
      V_PERC_SC_COMM_COM,  -- percentuale di sconto originale
      V_SC_COMM_COM     ,  -- importo sconto commerciale originale
      V_OMAGGIO         ,  -- importo sconto omaggio originale
      V_SC_FIN          ,  -- importo sconto finanziario originale
      V_ESITO              -- esito procedura
     );
    if V_ESITO =-52 then raise VALORE_NEGATIVO;
    elsif V_ESITO =-54 then raise NETTO_ECCESSIVO;
    elsif V_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    --
  elsif V_COD_IMPORTO = 32 then
    V_NETTO_DIR := V_NEW_IMPORTO;
    if V_NETTO_DIR = P_NETTO_DIR then raise NESSUNA_VARIAZIONE;
    end if;
    V_OMAGGIO := V_SC_COMM_DIR;
    PA_PC_IMPORTI.MODIFICA_NETTO(
      V_NETTO_DIR       ,  -- importo netto variato
      P_NETTO_DIR       ,  -- importo netto originale
      V_PERC_SC_COMM_DIR,  -- percentuale di sconto originale
      V_SC_COMM_DIR     ,  -- importo sconto commerciale originale
      V_OMAGGIO         ,  -- importo sconto omaggio originale
      V_SC_FIN          ,  -- importo sconto finanziario originale
      V_ESITO              -- esito procedura
     );
    if V_ESITO =-52 then raise VALORE_NEGATIVO;
    elsif V_ESITO =-54 then raise NETTO_ECCESSIVO;
    elsif V_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    --
  elsif V_COD_IMPORTO = 41 then
    V_PERC_SC_COMM_COM := V_NEW_IMPORTO;
    if V_PERC_SC_COMM_COM = P_PERC_SC_COMM_COM then raise NESSUNA_VARIAZIONE;
    end if;
    V_OMAGGIO := V_SC_COMM_COM;
    PA_PC_IMPORTI.MODIFICA_PERC_SC_COMM(
      V_PERC_SC_COMM_COM,  -- percentuale di sconto variata
      P_PERC_SC_COMM_COM,  -- percentuale di sconto originale
      V_NETTO_COM       ,  -- importo netto originale
      V_SC_COMM_COM     ,  -- importo sconto commerciale originale
      V_OMAGGIO         ,  -- importo sconto omaggio originale
      V_SC_FIN          ,  -- importo sconto finanziario originale
      V_ESITO              -- esito procedura
     );
    if V_ESITO =-55 then raise PERC_SCONTO_NON_VALIDA;
    elsif V_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    --
  elsif V_COD_IMPORTO = 42 then
    V_PERC_SC_COMM_DIR := V_NEW_IMPORTO;
    if V_PERC_SC_COMM_DIR = P_PERC_SC_COMM_DIR then raise NESSUNA_VARIAZIONE;
    end if;
    V_OMAGGIO := V_SC_COMM_DIR;
    PA_PC_IMPORTI.MODIFICA_PERC_SC_COMM(
      V_PERC_SC_COMM_DIR,  -- percentuale di sconto variata
      P_PERC_SC_COMM_DIR,  -- percentuale di sconto originale
      V_NETTO_DIR       ,  -- importo netto originale
      V_SC_COMM_DIR     ,  -- importo sconto commerciale originale
      V_OMAGGIO         ,  -- importo sconto omaggio originale
      V_SC_FIN          ,  -- importo sconto finanziario originale
      V_ESITO              -- esito procedura
     );
    if V_ESITO =-55 then raise PERC_SCONTO_NON_VALIDA;
    elsif V_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    --
  elsif V_COD_IMPORTO = 51 then
    V_SC_COMM_COM := V_NEW_IMPORTO;
    if V_SC_COMM_COM = P_SC_COMM_COM then raise NESSUNA_VARIAZIONE;
    end if;
    V_OMAGGIO := P_SC_COMM_COM;
    PA_PC_IMPORTI.MODIFICA_SCONTO_COMM(
      V_SC_COMM_COM     ,  -- SCONTO COMMERCIALE variato
      P_SC_COMM_COM     ,  -- importo sconto commerciale originale
      V_NETTO_COM       ,  -- importo netto originale
      V_PERC_SC_COMM_COM,  -- percentuale di sconto originale
      V_OMAGGIO         ,  -- importo sconto omaggio originale
      V_SC_FIN          ,  -- importo sconto finanziario originale
      'N'               ,  -- flag P_RIPARTIZIONE
      V_ESITO              -- esito procedura
     );
    if V_ESITO =-52 then raise VALORE_NEGATIVO;
    elsif V_ESITO =-56 then raise SC_COMM_ECCESSIVO;
    elsif V_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    --
  elsif V_COD_IMPORTO = 52 then
    V_SC_COMM_DIR := V_NEW_IMPORTO;
    if V_SC_COMM_DIR = P_SC_COMM_DIR then raise NESSUNA_VARIAZIONE;
    end if;
    V_OMAGGIO := P_SC_COMM_DIR;
    PA_PC_IMPORTI.MODIFICA_SCONTO_COMM(
      V_SC_COMM_DIR     ,  -- SCONTO COMMERCIALE variato
      P_SC_COMM_DIR     ,  -- importo sconto commerciale originale
      V_NETTO_DIR       ,  -- importo netto originale
      V_PERC_SC_COMM_DIR,  -- percentuale di sconto originale
      V_OMAGGIO         ,  -- importo sconto omaggio originale
      V_SC_FIN          ,  -- importo sconto finanziario originale
      'N'               ,  -- flag P_RIPARTIZIONE
      V_ESITO              -- esito procedura
     );
    if V_ESITO =-52 then raise VALORE_NEGATIVO;
    elsif V_ESITO =-56 then raise SC_COMM_ECCESSIVO;
    elsif V_ESITO<0 then raise ERRORE_GENERICO;
    end if;
    --
  end if;
  --
  -- eseguo la verifica finale degli importi, limitatamente a quelli ripartiti in quota commerciale e direzionale,
  -- poiche' gli altri sono gia' controllati all'interno della PA_PC_IMPORTI.MODIFICA_IMPORTI_MAGAZZINO.
  --
  V_ESITO:= FU_VERIFICA_IMPORTI_CINEMA(
              V_LORDO_COMM_COM,
              V_NETTO_COM,
              V_SC_COMM_COM,
              V_PERC_SC_COMM_COM);
  --
  V_ESITO:= FU_VERIFICA_IMPORTI_CINEMA(
              V_LORDO_COMM_DIR,
              V_NETTO_DIR,
              V_SC_COMM_DIR,
              V_PERC_SC_COMM_DIR);
  --
  P_TARIFFA          := V_TARIFFA;
  P_MAGG             := V_MAGG;
  P_LORDO            := V_LORDO;
  P_LORDO_COMM_COM   := V_LORDO_COMM_COM;
  P_LORDO_COMM_DIR   := V_LORDO_COMM_DIR;
  P_NETTO_COM        := V_NETTO_COM;
  P_NETTO_DIR        := V_NETTO_DIR;
  P_PERC_SC_COMM_COM := V_PERC_SC_COMM_COM;
  P_PERC_SC_COMM_DIR := V_PERC_SC_COMM_DIR;
  P_SC_COMM_COM      := V_SC_COMM_COM;
  P_SC_COMM_DIR      := V_SC_COMM_DIR;
  P_SANATORIA        := V_SANATORIA;
  P_RECUPERO         := V_RECUPERO;
  P_ESITO:= 1;
exception
when ERR_VERIFICA  then
     RAISE_APPLICATION_ERROR(-20101, 'Importi iniziali non  validi');
when ERR_IMPORTO_VARIATO     then
     RAISE_APPLICATION_ERROR(-20102, 'Importo modificato non valido');
when NESSUNA_VARIAZIONE      then
     RAISE_APPLICATION_ERROR(-20104, 'Non e stata applicata nessuna variazione');
when VALORE_NEGATIVO         then
     RAISE_APPLICATION_ERROR(-20105, 'Presenza valori nulli o negativi non ammessi');
when NETTO_ECCESSIVO         then
     RAISE_APPLICATION_ERROR(-20106, 'Nuovo valore di Netto maggiore di quanto consentito');
when SC_COMM_ECCESSIVO       then
     RAISE_APPLICATION_ERROR(-20107, 'Nuovo valore di Sconto Commerciale maggiore di quanto consentito');
when PERC_SCONTO_NON_VALIDA  then
     RAISE_APPLICATION_ERROR(-20108, 'Nuovo valore di % Sconto Commerciale non valido');
when IMP_SANATORIA_ECCESSIVO then
     RAISE_APPLICATION_ERROR(-20109, 'Nuovo valore di Sanatoria maggiore del consentito');
when SCONTO_REC_ECCESSIVO    then
     RAISE_APPLICATION_ERROR(-20110, 'Nuovo valore di sconto recupero maggiore del consentito');
when ERRORE_GENERICO         then
     RAISE_APPLICATION_ERROR(-20103, 'Si e verificato un errore imprevisto. Messaggio d''errore :'||sqlerrm);
end MODIFICA_IMPORTI;
--
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
--   modifiche:
procedure RIPARTIZIONE_LORDO(
  p_lordo_comm   in number,
  p_netto_com    in number,
  p_netto_dir    in number,
  p_perc_sc_com  in out number,
  p_perc_sc_dir  in out number,
  p_lordo_com    out number,
  p_lordo_dir    out number,
  p_sconto_com   out number,
  p_sconto_dir   out number)
is
  v_lordo_com    number;
  v_lordo_dir    number;
  v_sconto_com   number;
  v_sconto_dir   number;
  v_esito        number;
begin
  if    p_lordo_comm <0
     or p_netto_com <0
     or p_netto_dir <0
   --  or p_perc_sc_com <0
    -- or p_perc_sc_dir <0
     or (p_netto_com + p_netto_dir) > p_lordo_comm
     or (p_perc_sc_com < 0 and p_perc_sc_dir < 0)
  then
    raise ERR_VERIFICA;
  end if;
  --
  if p_perc_sc_com >= 0
  then
    v_lordo_com := PA_PC_IMPORTI.FU_LORDO_COMM_2(p_netto_com, p_perc_sc_com);
    v_lordo_dir := p_lordo_comm - v_lordo_com;
    v_sconto_com := PA_PC_IMPORTI.FU_SCONTO_COMM_2(v_lordo_com, p_netto_com);
    v_sconto_dir := PA_PC_IMPORTI.FU_SCONTO_COMM_2(v_lordo_dir, p_netto_dir);
    p_perc_sc_dir := PA_PC_IMPORTI.FU_PERC_SC_COMM(p_netto_dir , v_sconto_dir);
  else
    v_lordo_dir := PA_PC_IMPORTI.FU_LORDO_COMM_2(p_netto_dir, p_perc_sc_dir);
    v_lordo_com := p_lordo_comm - v_lordo_dir;
    v_sconto_dir := PA_PC_IMPORTI.FU_SCONTO_COMM_2(v_lordo_dir, p_netto_dir);
    v_sconto_com := PA_PC_IMPORTI.FU_SCONTO_COMM_2(v_lordo_com, p_netto_com);
    p_perc_sc_com := PA_PC_IMPORTI.FU_PERC_SC_COMM(p_netto_com, v_sconto_com);
  end if;
  v_esito := FU_VERIFICA_IMPORTI(
    null, -- tariffa
    null, -- maggiorazione
    p_lordo_comm,               -- lordo
    v_lordo_com,               -- lordo_commerciale
    v_lordo_dir,               -- lordo_direzionale
    p_netto_com,               -- netto_commerciale
    p_netto_dir,               -- netto_direzionale
    p_perc_sc_com,               -- percentuale di sconto commerciale commerciale
    p_perc_sc_dir,               -- percentuale di sconto commerciale direzionale
    v_sconto_com,               -- importo di sconto commerciale quota commerciale
    v_sconto_dir,               -- importo di sconto commerciale quota direzionale
    null, -- sanatoria
    null  -- recupero
  );
  p_lordo_com    := v_lordo_com;
  p_lordo_dir    := v_lordo_dir;
  p_sconto_com := v_sconto_com;
  p_sconto_dir := v_sconto_dir;
  --p_perc_sc_comm := PA_PC_IMPORTI.FU_PERC_SC_COMM(p_netto_com + p_netto_dir, PA_PC_IMPORTI.FU_SCONTO_COMM_2(p_lordo_comm, p_netto_com + p_netto_dir) );
exception
when ERR_VERIFICA  then
     RAISE_APPLICATION_ERROR(-20101, 'Importi iniziali non  validi');
when ERR_IMPORTO_VARIATO     then
     RAISE_APPLICATION_ERROR(-20102, 'Importo modificato non valido');
when NESSUNA_VARIAZIONE      then
     RAISE_APPLICATION_ERROR(-20104, 'Non e stata applicata nessuna variazione');
when VALORE_NEGATIVO         then
     RAISE_APPLICATION_ERROR(-20105, 'La percentuale di sconto e maggiore del consentito. Per modificare l''importo utilizzare la funzione ''Determina netto'' ');
when NETTO_ECCESSIVO         then
     RAISE_APPLICATION_ERROR(-20106, 'Nuovo valore di Netto maggiore di quanto consentito');
when SC_COMM_ECCESSIVO       then
     RAISE_APPLICATION_ERROR(-20107, 'Nuovo valore di Sconto Commerciale maggiore di quanto consentito');
when PERC_SCONTO_NON_VALIDA  then
     RAISE_APPLICATION_ERROR(-20108, 'Nuovo valore di % Sconto Commerciale non valido');
when IMP_SANATORIA_ECCESSIVO then
     RAISE_APPLICATION_ERROR(-20109, 'Nuovo valore di Sanatoria maggiore del consentito');
when SCONTO_REC_ECCESSIVO    then
     RAISE_APPLICATION_ERROR(-20110, 'Nuovo valore di sconto recupero maggiore del consentito');
when ERRORE_GENERICO         then
     RAISE_APPLICATION_ERROR(-20103, 'Si e verificato un errore imprevisto. Messaggio d''errore :'||sqlerrm);
when OTHERS then
    IF SQLCODE = -20105 THEN
        RAISE_APPLICATION_ERROR(-20105, 'La percentuale di sconto e'' maggiore del consentito. ');
    ELSE
        RAISE;
    END IF;
end;

END PA_CD_IMPORTI; 
/

