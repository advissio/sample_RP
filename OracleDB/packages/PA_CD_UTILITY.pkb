CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_UTILITY IS

V_TRIGGER_ON CHAR :='S';
--
-- ----------------------------------------------------------------------------------------------
-- DESCRIZIONE:
--    Il package contiene procedure e/o funzioni invocate dai DBTriggers
--    per l'implementazione di business rules.
--
-- BUSINESS RULES:
--    Vedi Package Spec
--
-- ----------------------------------------------------------------------------------------------
-- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
-- ----------------------------------------------------------------------------------------------
  /*PROCEDURE PR_TIMESTAMP_MODIFICA(
    P_NEW_UTEMOD  IN OUT VARCHAR2,
    P_NEW_DATAMOD IN OUT DATE)
     IS

  BEGIN
    -- Sezione di compilazione del timestamp di record.

    P_NEW_UTEMOD  := USER;
    P_NEW_DATAMOD := FU_DATA_ORA;
  END;*/
  --




   PROCEDURE PR_TIMESTAMP_MODIFICA(
    P_NEW_UTEMOD  IN OUT VARCHAR2,
    P_NEW_DATAMOD IN OUT DATE,
    P_ABILITATO BOOLEAN )
     IS

  BEGIN
    -- Sezione di compilazione del timestamp di record.
    IF P_ABILITATO THEN
        P_NEW_UTEMOD  := USER;
        P_NEW_DATAMOD := FU_DATA_ORA;
    END IF;
  END PR_TIMESTAMP_MODIFICA;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_CINEMA
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSCINEMA" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_CINEMA(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSCINEMA := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_CINEMA
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSCINEMA"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_CINEMA RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSCINEMA);

  END;

   -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_ATRIO
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSATRIO" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_ATRIO(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSATRIO := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_ATRIO
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSATRIO"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_ATRIO RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSATRIO);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_BREAK
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSBREAK" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_BREAK(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSBREAK := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_BREAK
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSBREAK"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_BREAK RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSBREAK);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_CIRCUITO
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSCIRCUITO" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_CIRCUITO(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSCIRCUITO := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_CIRCUITO
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSCIRCUITO"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_CIRCUITO RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSCIRCUITO);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_FASCIA
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSFASCIA" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_FASCIA(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSFASCIA := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_FASCIA
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSCIRCUITO"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_FASCIA RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSFASCIA);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_GENERE
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSGENERE" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_GENERE(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSGENERE := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_GENERE
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSGENERE"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_GENERE RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSGENERE);

  END;

-----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_LISTINO
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSLISTINO" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_LISTINO(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSLISTINO := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_LISTINO
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSLISTINO"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_LISTINO RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSLISTINO);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_PROD_VEND
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSPRODOTTOVENDITA" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_PROD_VEND(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSPRODOTTOVENDITA := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_PROD_VEND
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSPRODOTTOVENDITA"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_PROD_VEND RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSPRODOTTOVENDITA);

  END;

-----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_PROIEZIONE
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSPROIEZIONE" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_PROIEZIONE(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSPROIEZIONE := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_PROIEZIONE
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSPROIEZIONE"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_PROIEZIONE RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSPROIEZIONE);

  END;

-----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_SALA
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSSALA" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_SALA(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSSALA := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_SALA
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSSALA"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_SALA RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSSALA);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_SCHERMO
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSSCHERMO" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_SCHERMO(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSSCHERMO := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_SCHERMO
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSSCHERMO"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_SCHERMO RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSSCHERMO);

  END;

-----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_SCON_STAG
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSSCONTOSTAGIONALE" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_SCON_STAG(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSSCONTOSTAGIONALE := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_SCON_STAG
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSSCONTOSTAGIONALE"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_SCON_STAG RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSSCONTOSTAGIONALE);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_SPETTACOLO
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSSPETTACOLO" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_SPETTACOLO(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSSPETTACOLO := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_SPETTACOLO
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSSPETTACOLO"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_SPETTACOLO RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSSPETTACOLO);

  END;

-----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_TARIFFA
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSTARIFFA" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_TARIFFA(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSTARIFFA := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_TARIFFA
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSTARIFFA"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_TARIFFA RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSTARIFFA);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_TIPO_AUDIO
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSTIPOAUDIO" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_TIPO_AUDIO(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSTIPOAUDIO := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_TIPO_AUDIO
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSTIPOAUDIO"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_TIPO_AUDIO RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSTIPOAUDIO);

  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: PR_SET_DISATTIVA_TR_INS_TIPO_BREAK
  -- DESCRIZIONE:    Imposta il valore della variabile "GL_TRIGGERINSTIPOBREAK" che condiziona il comportamento dei trigger (simula la disattivazione dei trigger)
  -- INPUT:
  --    1.    VAL     Valore da assegnare 'OFF': Trigger NON attivi,
  --                                 'ON': Trigger ATTIVI (comportamento standard)
  -- OUTPUT:
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PR_SET_STATO_TR_INS_TIPO_BREAK(P_VAL VARCHAR2 DEFAULT 'ON') IS
  BEGIN
    GL_TRIGGERINSTIPOBREAK := P_VAL;
  END;

  -----------------------------------------------------------------------------------------------
  -- NOME: FU_DISATTIVA_TR_INS_TIPO_BREAK
  -- DESCRIZIONE:    Restituisce il valore della variabile "GL_TRIGGERINSTIPOBREAK"
  -- INPUT:
  -- OUTPUT:
  --    1.    Return Valore da assegnare 'OFF': Trigger DISATTIVATI,
  --                                   'ON': Trigger Attivi (Funzionalita normale),
  -- OPERAZIONI:
  -- REALIZZATORE: Roberto Barbaro, Teoresi srl, Giugno 2009
  -- MODIFICHE:
  --
  ------------------------------------------------------------------------------------------------------
  FUNCTION FU_STATO_TR_INS_TIPO_BREAK RETURN VARCHAR2 IS

  BEGIN

    RETURN(GL_TRIGGERINSTIPOBREAK);

  END;

  FUNCTION FU_CALCOLA_IMPORTO(p_lordo NUMBER, p_sconto NUMBER) RETURN NUMBER IS
  v_netto NUMBER;
  BEGIN
    v_netto := p_lordo;
    v_netto := p_lordo - (p_lordo * p_sconto / 100);
    RETURN round(v_netto,2);
  END FU_CALCOLA_IMPORTO;

PROCEDURE lock_package(p_package_name varchar2) IS
v_name varchar(30);
BEGIN
select u.name into v_name
from sys.obj$ o, sys.source$ s, sys.user$ u
where o.obj# = s.obj#
  and o.owner# = u.user#
  and o.type# in (7, 8, 9, 11, 12, 13, 14)
  and o.name =p_package_name
  and u.name ='VENCD'
  and rownum =1
  for update nowait;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       raise;
     WHEN OTHERS THEN
       RAISE;
END lock_package;

PROCEDURE PR_CORREGGI_TARIFFE_PROD_ACQ(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) IS

v_tariffa_prodotto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_tariffa_corretta CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_num_ambienti NUMBER;
v_piani_errati  VARCHAR2(3276);
v_vecchio_importo CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
v_num_schermi_virt NUMBER := -1;
BEGIN

FOR PRODOTTO_ACQ IN(SELECT ID_PRODOTTO_ACQUISTATO, ID_FORMATO, ID_TARGET 
                FROM CD_PRODOTTO_VENDITA PV, CD_PRODOTTO_ACQUISTATO PA
                where PA.FLG_ANNULLATO = 'N'
                and PA.flg_sospeso = 'N'
                and PA.cod_disattivazione is null
                and (p_id_prodotto_acquistato is null or PA.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato)
                and PV.ID_PRODOTTO_VENDITA = PA.ID_PRODOTTO_VENDITA) LOOP
                --
IF PRODOTTO_ACQ.ID_TARGET IS NOT NULL THEN
    SELECT COUNT(1)
    INTO v_num_schermi_virt
    FROM CD_SCHERMO_VIRTUALE_PRODOTTO
    WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
END IF;
IF v_num_schermi_virt = 0 THEN
    SELECT COUNT(DISTINCT S.ID_SALA)
    INTO v_num_ambienti
    FROM CD_SALA S, CD_COMUNICATO COM
    WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    AND COM.FLG_ANNULLATO = 'N'
    AND COM.FLG_SOSPESO = 'N'
    AND COM.COD_DISATTIVAZIONE IS NULL
    AND S.ID_SALA = COM.ID_SALA
    AND S.FLG_VISIBILE = 'S';
ELSE 
    v_num_ambienti := pa_cd_prodotto_acquistato.FU_GET_NUM_AMBIENTI(PRODOTTO_ACQ.id_prodotto_acquistato);
END IF;


IF v_num_ambienti = 0 THEN
    --dbms_output.put_line('Attenzione il prodotto  id_prodotto_acquistato ='||  PRODOTTO_ACQ.id_prodotto_acquistato  ||' non ha schermi. I suoi importi verranno azzerati');

    update cd_prodotto_acquistato
    set   IMP_NETTO = 0,
          IMP_RECUPERO =0,
          IMP_LORDO =0,
          IMP_MAGGIORAZIONE = 0,
          IMP_SANATORIA = 0,
          IMP_TARIFFA  = 0
    where id_prodotto_acquistato = PRODOTTO_ACQ.id_prodotto_acquistato;

    update cd_importi_prodotto
    set   IMP_NETTO = 0,
          IMP_SC_COMM =0
    where id_prodotto_acquistato = PRODOTTO_ACQ.id_prodotto_acquistato;

    ---14/01/2010 Mauro Viel
    --Verificare se bisogna gestire anche  bisogna gestire anche gli importi di fatturazione. Ad oggi non e ancora chiaro.

ELSE
        select round(imp_tariffa / numAmbienti,2) as tariffa_prodotto, imp_tariffa--, numAmbienti
        into v_tariffa_prodotto, v_vecchio_importo
        from
        (
        select id_prodotto_acquistato, v_num_ambienti as numAmbienti, imp_tariffa
        from (
        select id_prodotto_acquistato, imp_tariffa
         from
         cd_prodotto_acquistato
          where cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO = PRODOTTO_ACQ .id_prodotto_acquistato)
          )
          where numAmbienti > 0;

         select PA_CD_UTILITY.FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(ID_TARIFFA, id_formato),SCONTO_STAGIONALE) AS TARIFFA
         into v_tariffa_corretta
         from
        ( select id_tariffa, id_formato, sconto_stagionale from(
          select id_tariffa, id_formato, pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(id_prodotto_vendita, data_inizio, data_fine, id_formato, id_misura_prd_ve) AS SCONTO_STAGIONALE from
          (
           select cd_prodotto_vendita.id_prodotto_vendita, cd_tariffa.importo, cd_tariffa.id_tariffa, cd_prodotto_acquistato.data_inizio, cd_prodotto_acquistato.data_fine, cd_prodotto_acquistato.id_formato, cd_prodotto_acquistato.id_misura_prd_ve
           from cd_prodotto_acquistato, cd_prodotto_vendita, cd_tariffa
           where cd_prodotto_acquistato.ID_PRODOTTO_ACQUISTATO = PRODOTTO_ACQ .id_prodotto_acquistato
           and cd_prodotto_acquistato.ID_PRODOTTO_VENDITA = cd_prodotto_vendita.id_prodotto_vendita
           and cd_tariffa.ID_PRODOTTO_VENDITA = cd_prodotto_vendita.id_prodotto_vendita
           and cd_tariffa.ID_MISURA_PRD_VE = cd_prodotto_acquistato.ID_MISURA_PRD_VE
           AND   (CD_TARIFFA.ID_TIPO_TARIFFA = 1 OR CD_TARIFFA.ID_FORMATO = cd_prodotto_acquistato.id_formato)
           AND (cd_prodotto_acquistato.ID_TIPO_CINEMA is null or cd_prodotto_acquistato.ID_TIPO_CINEMA = cd_tariffa.ID_TIPO_CINEMA)
           and cd_prodotto_acquistato.DATA_INIZIO between cd_tariffa.DATA_INIZIO and cd_tariffa.data_fine
          )
         )
         );

         IF v_tariffa_prodotto <> v_tariffa_corretta THEN
            --dbms_output.put_line('Id prodotto acquistato: '||PRODOTTO_ACQ .id_prodotto_acquistato);
            --dbms_output.put_line('Tariffa del prodotto acquistato: '||v_tariffa_prodotto);
            --dbms_output.put_line('Tariffa corretta: '||v_tariffa_corretta);


            PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_TARIFFA_PROD_ACQ(PRODOTTO_ACQ.id_prodotto_acquistato,
                                          v_vecchio_importo,
                                          v_tariffa_corretta,
                                          'S',v_piani_errati);
        END IF;
 END IF;
 END LOOP;

END PR_CORREGGI_TARIFFE_PROD_ACQ;

PROCEDURE PR_CORREGGI_TARIFFE_PROD_RIC(p_id_prodotto_richiesto CD_PRODOTTI_RICHIESTI.ID_PRODOTTI_RICHIESTI%TYPE) IS

v_tariffa_prodotto CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_tariffa_corretta CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_num_schermi NUMBER;
v_num_sc number;
v_piani_errati  VARCHAR2(3276);
v_vecchio_importo CD_PRODOTTO_ACQUISTATO.IMP_TARIFFA%TYPE;
BEGIN

    FOR PRODOTTO_RIC IN(SELECT id_prodotti_richiesti, id_formato FROM cd_prodotti_richiesti
                    where cd_prodotti_richiesti.FLG_ANNULLATO = 'N'
                    and cd_prodotti_richiesti.flg_sospeso = 'N'
                    and cd_prodotti_richiesti.flg_acquistato = 'N'
                    and (p_id_prodotto_richiesto is null or cd_prodotti_richiesti.ID_PRODOTTI_RICHIESTI = p_id_prodotto_richiesto)
                    ) LOOP

    select round(imp_tariffa / numSchermi,2) as tariffa_prodotto, numSchermi
    into v_tariffa_prodotto, v_num_schermi
    from
    (
    select id_prodotti_richiesti, pa_cd_prodotto_richiesto.fu_get_num_ambienti(id_prodotti_richiesti) AS numSchermi, imp_tariffa
    from (
    select cd_prodotti_richiesti.id_prodotto_vendita,
     cd_prodotti_richiesti.data_inizio,
     cd_prodotti_richiesti.data_fine,
     id_prodotti_richiesti, imp_tariffa
     from
     cd_prodotti_richiesti
      where cd_prodotti_richiesti.id_prodotti_richiesti = PRODOTTO_RIC.id_prodotti_richiesti)
      )
      where numSchermi > 0;

     select PA_CD_UTILITY.FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(ID_TARIFFA, id_formato),SCONTO_STAGIONALE) AS TARIFFA
     into v_tariffa_corretta
     from
    ( select id_tariffa, id_formato, sconto_stagionale from(
      select id_tariffa, id_formato, pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(id_prodotto_vendita, data_inizio, data_fine, id_formato, id_misura_prd_ve) AS SCONTO_STAGIONALE from
      (
       select cd_prodotto_vendita.id_prodotto_vendita, cd_tariffa.importo, cd_tariffa.id_tariffa, cd_prodotti_richiesti.data_inizio, cd_prodotti_richiesti.data_fine, cd_prodotti_richiesti.id_formato, cd_prodotti_richiesti.id_misura_prd_ve
       from cd_prodotti_richiesti, cd_prodotto_vendita, cd_tariffa
       where cd_prodotti_richiesti.id_prodotti_richiesti = PRODOTTO_RIC.id_prodotti_richiesti
       and cd_prodotti_richiesti.ID_PRODOTTO_VENDITA = cd_prodotto_vendita.id_prodotto_vendita
       and cd_prodotti_richiesti.ID_MISURA_PRD_VE = cd_tariffa.ID_MISURA_PRD_VE
       and cd_tariffa.ID_PRODOTTO_VENDITA = cd_prodotto_vendita.id_prodotto_vendita
       and cd_prodotti_richiesti.DATA_INIZIO between cd_tariffa.DATA_INIZIO and cd_tariffa.data_fine
      )
     )
     );

     IF v_tariffa_prodotto <> v_tariffa_corretta THEN
        --dbms_output.put_line('Id prodotto richiesto: '||PRODOTTO_RIC.id_prodotti_richiesti);
        --dbms_output.put_line('Tariffa del prodotto richiesto: '||v_tariffa_prodotto);
        --dbms_output.put_line('Tariffa corretta: '||v_tariffa_corretta);
        UPDATE cd_prodotti_richiesti
        SET IMP_TARIFFA = round(IMP_TARIFFA / v_tariffa_prodotto * v_tariffa_corretta, 2),
            IMP_LORDO = round(IMP_LORDO / v_tariffa_prodotto * v_tariffa_corretta, 2),
            IMP_NETTO = round(IMP_NETTO / v_tariffa_prodotto * v_tariffa_corretta, 2),
            IMP_MAGGIORAZIONE = round(IMP_MAGGIORAZIONE / v_tariffa_prodotto * v_tariffa_corretta, 2)
        WHERE id_prodotti_richiesti = PRODOTTO_RIC.id_prodotti_richiesti;
        --
        UPDATE CD_IMPORTI_PRODOTTO
        SET IMP_NETTO = round(IMP_NETTO / v_tariffa_prodotto * v_tariffa_corretta, 2),
        IMP_SC_COMM = round(IMP_SC_COMM / v_tariffa_prodotto * v_tariffa_corretta, 2)
        WHERE id_prodotti_richiesti = PRODOTTO_RIC.id_prodotti_richiesti;
     END IF;
END LOOP;
END PR_CORREGGI_TARIFFE_PROD_RIC;

FUNCTION FU_DETTAGLIO_PRODOTTO(p_id_prodotto_acquistato CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO%TYPE) RETURN VARCHAR2 IS
v_dettaglio VARCHAR2(1024);
BEGIN
    select 'Id Prodotto: '||id_prodotto_acquistato||' Id Piano: '||id_piano||
    'Data Inizio: '||data_inizio||' Data Fine: '||data_fine||' Nome circuito: '||nome_circuito||
    'Formato: '||formato||' Misura: '||misura||' Mod vendita: '||DESC_MOD_VENDITA||' Tipo break: '||DESC_TIPO_BREAK
    ||' Tariffa originale: '||IMPORTO||' Tariffa riparametrata: '||tariffa_riparametrata
    into v_dettaglio
    from
    (select pa.id_prodotto_acquistato, pa.id_piano, pa.data_inizio, pa.data_fine, cir.nome_circuito, pa_cd_prodotto_acquistato.FU_GET_FORMATO_PROD_ACQ(pa.id_prodotto_acquistato) as formato,
    un.desc_unita as misura, mv.DESC_MOD_VENDITA, tar.IMPORTO, tb.DESC_TIPO_BREAK,
    FU_CALCOLA_IMPORTO(PA_CD_TARIFFA.FU_GET_TARIFFA_RIPARAMETRATA(tar.id_tariffa, pa.id_formato),pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(pv.ID_PRODOTTO_VENDITA, pa.data_inizio, pa.data_fine, pa.id_formato,pa.id_misura_prd_ve)) AS tariffa_riparametrata,
    pa_cd_estrazione_prod_vendita.FU_GET_SCONTO_STAGIONALE(pv.ID_PRODOTTO_VENDITA, pa.data_inizio, pa.data_fine, pa.id_formato, pa.id_misura_prd_ve) AS SCONTO_STAGIONALE
    from cd_prodotto_acquistato pa, cd_prodotto_vendita pv, cd_circuito cir, cd_misura_prd_vendita mis, cd_unita_misura_temp un,
    cd_modalita_vendita mv, cd_tipo_break tb, cd_tariffa tar
    where pa.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
    and pa.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA
    and pv.ID_CIRCUITO = cir.ID_CIRCUITO
    and pa.ID_MISURA_PRD_VE = mis.id_misura_prd_ve
    and un.id_unita = mis.id_unita
    and pv.id_mod_vendita = mv.id_mod_vendita
    and pv.ID_TIPO_BREAK = tb.ID_TIPO_BREAK
    and TAR.ID_PRODOTTO_VENDITA = pv.ID_PRODOTTO_VENDITA
    and pa.DATA_INIZIO BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
    and pa.DATA_FINE BETWEEN TAR.DATA_INIZIO AND TAR.DATA_FINE
    and pa.ID_MISURA_PRD_VE = TAR.ID_MISURA_PRD_VE);
RETURN v_dettaglio;
END FU_DETTAGLIO_PRODOTTO;

function fu_verifica_date_prodotti return c_prodotto_data is
v_prodotti c_prodotto_data;
BEGIN
open v_prodotti for
select id_prodotto, min_data_comunicato, max_data_comunicato,data_inizio, data_fine from (
    select min(data_erogazione_prev) as min_data_comunicato, max(data_erogazione_prev) as max_data_comunicato,data_inizio, data_fine, id_prodotto, com.id_prodotto_acquistato from cd_comunicato com,
    (select data_inizio, data_fine, id_prodotto_acquistato as id_prodotto from cd_prodotto_acquistato pa
    where flg_annullato = 'N'
    and flg_sospeso = 'N'
    and cod_disattivazione is null)
    group by data_inizio, data_fine, id_prodotto, id_prodotto_acquistato)
    where id_prodotto = id_prodotto_acquistato
    and (min_data_comunicato != data_inizio or max_data_comunicato != data_fine);
return v_prodotti;
end fu_verifica_date_prodotti;

PROCEDURE PR_CORREGGI_DGC IS
v_id_tipo_pubb CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB%TYPE;
v_dgc DET_GEST_COM.ID%type;
v_id_prodotto_vendita CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE;
v_arena varchar2(10);
BEGIN

    FOR PRODOTTO_ACQ IN(SELECT ID_PRODOTTO_ACQUISTATO FROM CD_PRODOTTO_ACQUISTATO
                where cd_prodotto_acquistato.FLG_ANNULLATO = 'N'
                and cd_prodotto_acquistato.flg_sospeso = 'N'
                and cd_prodotto_acquistato.cod_disattivazione is null) LOOP

     dbms_output.put_line('Id prodotto acquistato: '||PRODOTTO_ACQ .id_prodotto_acquistato);

      SELECT CD_PRODOTTO_VENDITA.ID_PRODOTTO_PUBB, CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA,decode(CD_CIRCUITO.FLG_ARENA,'S', 'ARENA','SALA')
       INTO v_id_tipo_pubb, v_id_prodotto_vendita,v_arena
       FROM CD_PRODOTTO_VENDITA, CD_PRODOTTO_ACQUISTATO, CD_CIRCUITO
       WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO =  PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO
       AND CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA = CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_VENDITA
       AND CD_PRODOTTO_VENDITA.ID_CIRCUITO = CD_CIRCUITO.ID_CIRCUITO;
--
 dbms_output.put_line('id PRODOTTO VENDITA: '||v_id_prodotto_vendita);
 dbms_output.put_line('id prodotto pubblicitario: '||v_id_tipo_pubb);
 dbms_output.put_line('v_arena: '||v_arena);


        BEGIN
            v_dgc := FU_CD_GET_DGC(v_id_tipo_pubb, pa_cd_mezzo.FU_TESTATA(v_id_prodotto_vendita),v_arena);
            dbms_output.put_line('dgc: '||v_dgc);
            UPDATE CD_PRODOTTO_ACQUISTATO
            SET DGC = v_dgc
            WHERE CD_PRODOTTO_ACQUISTATO.ID_PRODOTTO_ACQUISTATO =  PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO;
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
             v_dgc := '';
           raise;
        END;
    END LOOP;
END PR_CORREGGI_DGC;

PROCEDURE PR_ASSEGNA_FRUITORI IS
v_num_fruitori NUMBER := 0;
v_id_fruitore varchar2(8);
v_fruitori_piano CD_PRODOTTO_ACQUISTATO.ID_FRUITORI_DI_PIANO%TYPE;
BEGIN

FOR PIANO IN (SELECT * FROM CD_PIANIFICAZIONE WHERE ID_PIANO NOT IN (SELECT ID_PIANO FROM CD_FRUITORI_DI_PIANO)) LOOP
SELECT COUNT (1)
  INTO v_num_fruitori
        FROM
        VI_CD_CLIENTE_FRUITORE FR,
        RAGGRUPPAMENTO_U RAG
        WHERE RAG.tipo_raggrupp='CCCL'
        AND RAG.COD_INTERL_P = PIANO.ID_CLIENTE
        AND RAG.COD_INTERL_F = FR.ID_FRUITORE
        AND PIANO.DATA_TRASFORMAZIONE_IN_PIANO BETWEEN RAG.DT_INIZ_VAL AND RAG.DT_FINE_VAL;
  --

  dbms_output.put_line('Numero di fruitori:'||v_num_fruitori);
  IF v_num_fruitori = 1 THEN
      SELECT FR.ID_FRUITORE
  INTO v_id_fruitore
        FROM
        VI_CD_CLIENTE_FRUITORE FR,
        RAGGRUPPAMENTO_U RAG
        WHERE RAG.tipo_raggrupp='CCCL'
        AND RAG.COD_INTERL_P = PIANO.ID_CLIENTE
        AND RAG.COD_INTERL_F = FR.ID_FRUITORE
        AND PIANO.DATA_TRASFORMAZIONE_IN_PIANO BETWEEN RAG.DT_INIZ_VAL AND RAG.DT_FINE_VAL;

      insert into cd_fruitori_di_piano(id_piano, id_ver_piano, id_cliente_fruitore)
      values(PIANO.ID_PIANO, PIANO.ID_VER_PIANO, v_id_fruitore);
   End if;
END LOOP;

FOR PA IN (SELECT * FROM CD_PRODOTTO_ACQUISTATO WHERE ID_FRUITORI_DI_PIANO IS NULL) LOOP
    SELECT COUNT(1)
    INTO v_num_fruitori
    FROM CD_FRUITORI_DI_PIANO
    WHERE ID_PIANO = PA.ID_PIANO
    AND ID_VER_PIANO = PA.ID_VER_PIANO;

    IF v_num_fruitori = 1 THEN

        SELECT ID_FRUITORI_DI_PIANO
        INTO v_fruitori_piano
        FROM CD_FRUITORI_DI_PIANO
        WHERE ID_PIANO = PA.ID_PIANO
        AND ID_VER_PIANO = PA.ID_VER_PIANO;

        UPDATE CD_PRODOTTO_ACQUISTATO
        SET ID_FRUITORI_DI_PIANO = v_fruitori_piano
        WHERE ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO;
    END IF;

END LOOP;

END PR_ASSEGNA_FRUITORI;

PROCEDURE PR_RIPRISTINA_PROIEZIONE_PIANO(p_id_piano cd_pianificazione.id_piano%type, p_id_ver_piano cd_pianificazione.id_ver_piano%type, p_data_inizio CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, p_data_fine CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE) IS
v_esito NUMBER;
v_piani_errati  VARCHAR2(3276);
BEGIN

FOR PACQ IN (SELECT * FROM CD_PRODOTTO_ACQUISTATO
             WHERE ID_PIANO = p_id_piano
             AND ID_VER_PIANO = p_id_ver_piano
             AND FLG_ANNULLATO = 'N'
             AND FLG_SOSPESO = 'N'
             AND COD_DISATTIVAZIONE IS NULL) LOOP
    UPDATE CD_COMUNICATO
    SET FLG_ANNULLATO = 'N'
    WHERE
    FLG_ANNULLATO = 'S' AND
    ID_COMUNICATO IN
    (SELECT COM.ID_COMUNICATO FROM
     CD_COMUNICATO COM, CD_PRODOTTO_ACQUISTATO PA
     WHERE PA.ID_PRODOTTO_ACQUISTATO = PACQ.ID_PRODOTTO_ACQUISTATO
     AND COM.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
     AND COM.FLG_ANNULLATO = 'S'
     AND COM.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
     );

 PA_CD_PRODOTTO_ACQUISTATO.PR_RIPRISTINA_SCHERMO_PROD_ACQ(PACQ.ID_PRODOTTO_ACQUISTATO,null,v_esito,v_piani_errati);
 END LOOP;

END PR_RIPRISTINA_PROIEZIONE_PIANO;

PROCEDURE PR_VERIFICA_IMPORTI IS
v_netto_importi NUMBER;
v_lordo_importi NUMBER;
v_num_fat NUMBER := 1;
v_netto_comm CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_netto_dir CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_sconto_comm CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_sconto_dir CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_id_importi_prodotto CD_IMPORTI_PRODOTTO.ID_IMPORTI_PRODOTTO%TYPE;
v_netto_fatturazione CD_IMPORTI_FATTURAZIONE.IMPORTO_NETTO%TYPE;
begin
FOR PRODOTTO_ACQ IN(SELECT * FROM CD_PRODOTTO_ACQUISTATO
                where cd_prodotto_acquistato.FLG_ANNULLATO = 'N'
                and cd_prodotto_acquistato.flg_sospeso = 'N'
                and cd_prodotto_acquistato.cod_disattivazione is null
             --  and stato_di_vendita = 'PRE'
                order by datamod) LOOP


        --v_num_fat := pa_cd_prodotto_acquistato.FU_GET_NUM_IMPORTI_FAT(PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO);

        SELECT IMP_NETTO, IMP_SC_COMM, ID_IMPORTI_PRODOTTO
        INTO v_netto_comm, v_sconto_comm, v_id_importi_prodotto
        FROM CD_IMPORTI_PRODOTTO
        WHERE id_PRODOTTO_ACQUISTATO = PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO
        AND TIPO_CONTRATTO = 'C';

        SELECT IMP_NETTO, IMP_SC_COMM, ID_IMPORTI_PRODOTTO
        INTO v_netto_dir, v_sconto_dir, v_id_importi_prodotto
        FROM CD_IMPORTI_PRODOTTO
        WHERE id_PRODOTTO_ACQUISTATO = PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO
        AND TIPO_CONTRATTO = 'D';

        v_netto_importi :=  v_netto_comm + v_netto_dir;
        v_lordo_importi :=  v_netto_importi + v_sconto_comm + v_sconto_dir + PRODOTTO_ACQ.IMP_RECUPERO;
        IF v_netto_importi != PRODOTTO_ACQ.IMP_NETTO OR v_lordo_importi != PRODOTTO_ACQ.IMP_LORDO THEN
        --    dbms_output.put_line('Data inizio:'||PRODOTTO_ACQ.DATA_INIZIO);
            dbms_output.put_line('Prodotto:'||PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO);
       --     dbms_output.put_line('Data modifica:'||PRODOTTO_ACQ.DATAMOD);
        --    dbms_output.put_line('Tariffa variabile:'||PRODOTTO_ACQ.FLG_TARIFFA_VARIABILE);
        --    dbms_output.put_line(pa_cd_utility.fu_dettaglio_prodotto(PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO));
            dbms_output.put_line('Netto prodotto:'||PRODOTTO_ACQ.IMP_NETTO);
            dbms_output.put_line('Lordo prodotto:'||PRODOTTO_ACQ.IMP_LORDO);
            dbms_output.put_line('Netto comm:'||v_netto_comm);
            dbms_output.put_line('Netto dir:'||v_netto_dir);
    --    UPDATE CD_PRODOTTO_ACQUISTATO
    --    SET IMP_NETTO = v_netto_importi
    --    WHERE id_PRODOTTO_ACQUISTATO = PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO;

        END IF;

        SELECT SUM(IMPORTO_NETTO)
        INTO v_netto_fatturazione
        FROM CD_IMPORTI_FATTURAZIONE
        WHERE ID_IMPORTI_FATTURAZIONE IN
        (SELECT ID_IMPORTI_PRODOTTO FROM CD_IMPORTI_PRODOTTO
         WHERE ID_PRODOTTO_ACQUISTATO = PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO)
        AND FLG_ANNULLATO = 'N' ;

        IF v_netto_fatturazione !=  v_netto_importi then
            dbms_output.put_line('Prodotto:'||PRODOTTO_ACQ.ID_PRODOTTO_ACQUISTATO);
        END IF;

 END LOOP;

END  PR_VERIFICA_IMPORTI;


FUNCTION GET_DAY(P_DAY_NUM CHAR) RETURN VARCHAR2 IS
v_giorno VARCHAR2(20);
BEGIN
    SELECT DECODE(P_DAY_NUM,'1','Domenica','2','Lunedi''','3','Martedi''','4','Mercoledi''','5','Giovedi''','6','Venerdi''','7','Sabato',' ')
    INTO v_giorno
    FROM DUAL;
    RETURN v_giorno;
END GET_DAY;


FUNCTION GET_DAY_NUM(P_DAY VARCHAR2) RETURN CHAR IS
v_num_giorno CHAR(1);
BEGIN
    SELECT DECODE(P_DAY,'Domenica','1','Lunedi''','2','Martedi''','3','Mercoledi''','4','Giovedi''','5','Venerdi''','6','Sabato','7')
    INTO v_num_giorno
    FROM DUAL;
    RETURN v_num_giorno;
END GET_DAY_NUM;


PROCEDURE PR_VERIFICA_SALTO_RECUPERO IS
v_importo_saltato_orig number;
v_quote_parte number;
BEGIN
    for c in
        (select count(distinct(id_sala)) num_sale_saltate ,com.id_prodotto_acquistato,nvl(imp.IMP_LORDO_SALTATO,0), imp.tipo_contratto,pa.IMP_TARIFFA,rec.ID_PRODOTTO_RECUPERO
        from cd_comunicato com,cd_recupero_prodotto rec, cd_prodotto_acquistato pa, cd_importi_prodotto imp
        where com.id_prodotto_acquistato = rec.ID_PRODOTTO_SALTATO
        and com.COD_DISATTIVAZIONE is not null
        and com.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
        and imp.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
        group by com.id_prodotto_acquistato,imp.IMP_LORDO_SALTATO,imp.tipo_contratto,pa.IMP_TARIFFA,rec.ID_PRODOTTO_RECUPERO)
        loop
        v_importo_saltato_orig := (c.imp_tariffa/pa_cd_prodotto_acquistato.FU_GET_NUM_AMBIENTI(c.id_prodotto_acquistato)) *  c.num_sale_saltate;
        select sum(quota_parte)
        into v_quote_parte
        from  cd_recupero_prodotto
        where c.ID_PRODOTTO_RECUPERO = ID_PRODOTTO_RECUPERO
        and id_prodotto_saltato = c.id_prodotto_acquistato
        and tipo_contratto=c.tipo_contratto;

        if (v_importo_saltato_orig - v_quote_parte != 0) then

            dbms_output.PUT_LINE('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            dbms_output.PUT_LINE('id_prodotto_acquistato'||c.id_prodotto_acquistato);
            dbms_output.PUT_LINE('tipo_contratto'||c.tipo_contratto);
            dbms_output.PUT_LINE(' Importo_saltato_orignario = '|| v_importo_saltato_orig);
            dbms_output.PUT_LINE(' Importo tariffa = '|| c.imp_tariffa);
            dbms_output.PUT_LINE(' Numero sale saltate = '||  c.num_sale_saltate);
            dbms_output.PUT_LINE(' Numero ambienti attuali = '||  pa_cd_prodotto_acquistato.FU_GET_NUM_AMBIENTI(c.id_prodotto_acquistato));
            dbms_output.PUT_LINE(' Quota parte = '||  v_quote_parte);
            dbms_output.PUT_LINE(' Residuo = '|| (v_importo_saltato_orig - v_quote_parte) );
            dbms_output.PUT_LINE('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');

        end if;
end loop;
END PR_VERIFICA_SALTO_RECUPERO;

PROCEDURE PR_ELIMINA_PIANO(p_id_piano CD_PIANIFICAZIONE.ID_PIANO%TYPE) IS
v_id_piano cd_pianificazione.ID_PIANO%type :=p_id_piano;
begin
delete cd_comunicato where id_prodotto_acquistato in (select id_prodotto_acquistato from cd_prodotto_acquistato where id_piano = v_id_piano);
delete cd_importi_fatturazione
where id_importi_prodotto
in (
     select id_importi_prodotto
     from cd_importi_prodotto
     where id_prodotto_acquistato
     in (select id_prodotto_acquistato
     from cd_prodotto_acquistato where id_piano = v_id_piano)
    );
delete cd_magg_prodotto where id_prodotto_acquistato in (select id_prodotto_acquistato from cd_prodotto_acquistato where id_piano = v_id_piano);
delete cd_magg_prodotto where id_prodotti_richiesti in (select id_prodotti_richiesti  from cd_prodotti_richiesti where id_piano   = v_id_piano);
delete cd_aree_prodotto_acquistato where id_prodotto_acquistato in (select id_prodotto_acquistato from cd_prodotto_acquistato where id_piano = v_id_piano);
delete cd_aree_prodotti_richiesti where id_prodotti_richiesti in (select id_prodotti_richiesti  from cd_prodotti_richiesti where id_piano   = v_id_piano);
delete cd_importi_prodotto where id_prodotto_acquistato in (select id_prodotto_acquistato from cd_prodotto_acquistato where id_piano = v_id_piano);
delete cd_stampe_ordine where id_ordine in (select id_ordine from cd_ordine where id_piano = v_id_piano);
delete cd_ordine where id_piano =  v_id_piano;
delete from cd_fruitori_di_piano where id_piano = v_id_piano;

delete cd_prodotto_acquistato where id_piano   = v_id_piano;
delete from cd_raggruppamento_intermediari where id_piano = v_id_piano;
delete cd_ambienti_prodotti_richiesti where id_prodotti_richiesti in (select id_prodotti_richiesti  from cd_prodotti_richiesti where id_piano   = v_id_piano);
delete cd_importi_prodotto where  id_prodotti_richiesti in (select id_prodotti_richiesti  from cd_prodotti_richiesti where id_piano   = v_id_piano);
delete cd_prodotti_richiesti where id_piano   = v_id_piano;
delete cd_importi_richiesti_piano where id_piano = v_id_piano;
delete cd_importi_richiesta where id_piano = v_id_piano;
delete cd_formati_piano where id_piano = v_id_piano;
delete cd_soggetto_di_piano where id_piano = v_id_piano;
delete cd_materiale_di_piano where id_piano = v_id_piano;
delete cd_pianificazione where id_piano = v_id_piano;
END PR_ELIMINA_PIANO;

FUNCTION SPLIT (p_in_string VARCHAR2, p_delim VARCHAR2) RETURN id_list_type
   IS
   i       number :=0;
   pos     number :=0;
   lv_str  varchar2(50) := p_in_string;
   vett id_list_type := id_list_type();
   BEGIN
      -- determine first chuck of string
      pos := instr(lv_str,p_delim,1,1);
      -- while there are chunks left, loop
      IF pos = 0 AND LENGTH(p_in_string) > 0 THEN
        vett.EXTEND;
        vett(1) := p_in_string;
      ELSE
          WHILE ( pos != 0) LOOP
             -- increment counter
             i := i + 1;
             -- create array element for chuck of string
             vett.EXTEND;
             vett(i) := to_number(substr(lv_str,1,pos-1));
             -- remove chunk from string
             lv_str := substr(lv_str,pos+1,length(lv_str));
             -- determine next chunk
             pos := instr(lv_str,p_delim,1,1);
             -- no last chunk, add to array
             IF pos = 0 THEN
                vett.EXTEND;
                vett(i+1) := lv_str;
             END IF;
          END LOOP;
      END IF;
      RETURN vett;
   END SPLIT;


PROCEDURE PR_ABILITA_TRIGGER(P_ABILITA CHAR) IS
BEGIN
    V_TRIGGER_ON := P_ABILITA;
END PR_ABILITA_TRIGGER;


FUNCTION FU_TRIGGER_ON RETURN CHAR IS
BEGIN
    RETURN V_TRIGGER_ON;
END FU_TRIGGER_ON;

PROCEDURE scrivi_trace(p_prog NUMBER, p_testo VARCHAR2) IS
BEGIN
insert into rt_trace(PROG,DATA1,TESTO4)
values (p_prog,sysdate,p_testo);
--commit;
END scrivi_trace;

PROCEDURE PR_RECUPERA_SALA(p_id_sala CD_COMUNICATO.ID_SALA%TYPE, p_data_inizio DATE, p_data_fine DATE) IS
p_esito number;
BEGIN
    /*select distinct pa.id_prodotto_acquistato, pa.*, pv.id_mod_vendita
    from cd_prodotto_vendita pv, cd_comunicato c, cd_prodotto_acquistato pa
    where c.id_sala = p_id_sala
    and c.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
    and pa.ID_PRODOTTO_ACQUISTATO = c.ID_PRODOTTO_ACQUISTATO
    and pa.flg_annullato = 'N'
    and pa.FLG_SOSPESO = 'N'
    and pa.COD_DISATTIVAZIONE is null
    and pv.ID_PRODOTTO_VENDITA = pa.ID_PRODOTTO_VENDITA;
    */

    --Recupero le proiezioni
    for pr in
    (select * from cd_proiezione
    where data_proiezione between p_data_inizio and p_data_fine
    and id_schermo = (select id_schermo from cd_schermo where id_sala = p_id_sala)
    ) loop
        pa_cd_proiezione.PR_RECUPERA_PROIEZIONE(pr.id_proiezione, p_esito);
    end loop;

    --Recupero i comunicati
    update cd_comunicato
    set flg_annullato = 'N',
    cod_disattivazione = NULL
    where id_prodotto_acquistato in
    (select distinct pa.id_prodotto_acquistato
    from cd_prodotto_vendita pv, cd_comunicato c, cd_prodotto_acquistato pa
    where c.id_sala = p_id_sala
    and c.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
    and pa.ID_PRODOTTO_ACQUISTATO = c.ID_PRODOTTO_ACQUISTATO
    and pa.flg_annullato = 'N'
    and pa.FLG_SOSPESO = 'N'
    and pa.COD_DISATTIVAZIONE is null
    and pv.ID_PRODOTTO_VENDITA = pa.ID_PRODOTTO_VENDITA)
    and id_sala = p_id_sala;

    --Aggiorno la tariffa e
    for pa in
    (
    select distinct pa.id_prodotto_acquistato
    from cd_prodotto_vendita pv, cd_comunicato c, cd_prodotto_acquistato pa
    where c.id_sala = p_id_sala
    and c.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
    and pa.ID_PRODOTTO_ACQUISTATO = c.ID_PRODOTTO_ACQUISTATO
    and pa.flg_annullato = 'N'
    and pa.FLG_SOSPESO = 'N'
    and pa.COD_DISATTIVAZIONE is null
    and pv.ID_PRODOTTO_VENDITA = pa.ID_PRODOTTO_VENDITA
    ) loop
    pa_cd_utility.PR_CORREGGI_TARIFFE_PROD_ACQ(pa.id_prodotto_acquistato);
    end loop;

    --  sistemo le posizioni
        for pa in
    (
        select distinct pa.id_prodotto_acquistato from vi_cD_comunicato_sala c1, cd_prodotto_acquistato pa, vi_cd_comunicato_sala c2
        where c1.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine--to_date('01082010','DDMMYYYY') and to_date('21082010','DDMMYYYY')
        and c2.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine --to_date('01082010','DDMMYYYY') and to_date('21082010','DDMMYYYY')
        and c1.ID_PRODOTTO_ACQUISTATO = pa.ID_PRODOTTO_ACQUISTATO
        and pa.STATO_DI_VENDITA = 'PRE'
        and pa.FLG_ANNULLATO = 'N'
        and pa.FLG_SOSPESO = 'N'
        and pa.COD_DISATTIVAZIONE is null
        and c1.ID_BREAK = c2.ID_BREAK
        and c1.ID_PRODOTTO_ACQUISTATO != c2.ID_PRODOTTO_ACQUISTATO
        and c1.POSIZIONE = c2.POSIZIONE
    ) loop
        pa_cd_prodotto_acquistato.PR_IMPOSTA_POSIZIONE(pa.id_prodotto_acquistato, null);
    end loop;

    END PR_RECUPERA_SALA;

    PROCEDURE PR_ELIMINA_VALORE_VETT(p_vett IN OUT id_list_type, p_valore INTEGER) IS
    i number;
    BEGIN
    /*    
        FOR i IN p_vett.FIRST..p_vett.LAST LOOP
            IF p_vett(i) = p_valore THEN
                p_vett.DELETE(i);
                EXIT;
            END IF;
        END LOOP;
     */   
   i := p_vett.FIRST;
   WHILE i IS NOT NULL
   LOOP
      --dbms_output.put_line(p_vett(counter));
      IF p_vett(i) = p_valore THEN
        p_vett.DELETE(i);
        EXIT;
      END IF;
      i := p_vett.NEXT(i);
   END LOOP;
    END PR_ELIMINA_VALORE_VETT;
    
    
procedure  pr_disassocia_sale_reali(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%type,p_numero_sale number, p_giorno date) is
v_stato_vendita cd_prodotto_acquistato.STATO_DI_VENDITA%Type:= 'PRE';
v_num_comunicati  number:=0;
v_id_sala_virtuale cd_sala.id_sala%type;
v_id_circuito number := null;--98;
v_id_prodotto_vendita number := null;--278;
v_id_break_vendita number;
v_id_break number;
i number := 0;
begin


select pv.id_circuito, pv.id_prodotto_vendita
into   v_id_circuito, v_id_prodotto_vendita
from   cd_prodotto_vendita pv, cd_prodotto_acquistato pa
where  pa.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
and    pv.ID_PRODOTTO_VENDITA = pa.ID_PRODOTTO_VENDITA;



for c in (select co.id_comunicato, co.id_sala
from cd_comunicato co, cd_sala sa,cd_cinema ci  
where co.id_prodotto_acquistato =p_id_prodotto_acquistato --9647
and   co.data_erogazione_prev = p_giorno--to_date('09122010','DDMMYYYY')
and   sa.ID_SALA = co.ID_SALA
and   sa.ID_CINEMA = ci.id_cinema
and  ci.FLG_VIRTUALE ='N'
and  co.flg_annullato ='N'
and rownum <=(p_numero_sale*2)
order by co.id_sala)
loop
    update cd_comunicato set flg_annullato ='S' where id_comunicato = c.id_comunicato;
end loop;


FOR COM IN
        (
            SELECT ID_COMUNICATO, ID_FASCIA, id_sala
            FROM CD_PROIEZIONE PR, CD_BREAK BR, CD_COMUNICATO COM
            WHERE COM.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
            AND COM.DATA_EROGAZIONE_PREV = P_GIORNO
            --AND COM.ID_SALA = SALA.ID_SALA
            AND COM.FLG_ANNULLATO = 'S'
            AND COM.FLG_SOSPESO = 'N'
            AND COM.COD_DISATTIVAZIONE IS NULL
            AND BR.ID_BREAK = COM.ID_BREAK
            AND BR.FLG_ANNULLATO = 'N'
            AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
        ) LOOP
        
        
        
            if i = 0 then
                select distinct id_sala
                INTO v_id_sala_virtuale
                from
                (        
                SELECT DISTINCT S.ID_SALA
                FROM CD_CINEMA CIN, CD_SALA S, CD_SCHERMO SC, CD_CIRCUITO_SCHERMO CS
                WHERE CS.ID_CIRCUITO = v_id_circuito
                AND CS.FLG_ANNULLATO = 'N'
                AND SC.ID_SCHERMO = CS.ID_SCHERMO
                AND SC.FLG_ANNULLATO = 'N'
                AND S.ID_SALA = SC.ID_SALA
                AND S.FLG_ANNULLATO = 'N'
                AND CIN.ID_CINEMA = S.ID_CINEMA
                AND CIN.FLG_VIRTUALE = 'S'
                minus
                select distinct co.id_sala 
                from 
                cd_comunicato  co, cd_sala sa, cd_cinema ci
                where co.id_prodotto_acquistato =p_id_prodotto_acquistato 
                and   co.id_sala = sa.id_sala
                and   ci.id_cinema = sa.id_cinema 
                and   ci.FLG_VIRTUALE ='S'
                and   co.FLG_ANNULLATO = 'N'
                and   co.FLG_SOSPESO ='N'
                and   co.DATA_EROGAZIONE_PREV = P_GIORNO
                and   co.COD_DISATTIVAZIONE is null
                )
                where rownum = 1;
            i := 1; 
                else
                i := 0;    
            end if;        
        
            v_num_comunicati := v_num_comunicati +1;
            SELECT DISTINCT BV.ID_BREAK_VENDITA, br.ID_BREAK
            INTO v_id_break_vendita,v_id_break
            FROM CD_BREAK_VENDITA BV, CD_CIRCUITO_BREAK CB, CD_BREAK BR, CD_PROIEZIONE PR, CD_SCHERMO SC
            WHERE SC.ID_SALA = v_id_sala_virtuale
            AND PR.ID_SCHERMO = SC.ID_SCHERMO
            AND PR.FLG_ANNULLATO = 'N'
            AND PR.DATA_PROIEZIONE = P_GIORNO
            AND BR.ID_PROIEZIONE = PR.ID_PROIEZIONE
            AND BR.FLG_ANNULLATO = 'N'
            AND CB.ID_BREAK = BR.ID_BREAK
            AND CB.ID_CIRCUITO = v_id_circuito
            AND BV.ID_CIRCUITO_BREAK = CB.ID_CIRCUITO_BREAK
            AND BV.ID_PRODOTTO_VENDITA = v_id_prodotto_vendita
            AND PR.ID_FASCIA = COM.ID_FASCIA;
            IF v_stato_vendita = 'PRE' THEN
                PA_CD_PRODOTTO_ACQUISTATO.PR_ELIMINA_BUCO_POSIZIONE_COM(COM.ID_COMUNICATO);
            END IF;
            
            
           
            --
            UPDATE CD_COMUNICATO
            SET ID_SALA = v_id_sala_virtuale,
            ID_BREAK_VENDITA = v_id_break_vendita,
            FLG_ANNULLATO = 'N', 
            ID_BREAK = v_id_break
            WHERE ID_COMUNICATO = COM.ID_COMUNICATO;
            
           UPDATE CD_SCHERMO_VIRTUALE_PRODOTTO
           SET ID_SALA = v_id_sala_virtuale
           WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
           AND ID_SALA = com.ID_SALA
           AND GIORNO = P_GIORNO;
            
            
        END LOOP;
        IF v_num_comunicati = 0 THEN
            RAISE_APPLICATION_ERROR(-20025, 'PROCEDURA pr_disassocia_sale_reali: ERRORE NELLA MODIFICA DEI COMUNICATI');
        END IF;  

end  pr_disassocia_sale_reali;    

    
END PA_CD_UTILITY; 
/

