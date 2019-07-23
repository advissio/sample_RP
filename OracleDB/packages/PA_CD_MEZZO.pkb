CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_MEZZO IS
--
-- ------------------------------------------------------------------------------------------
-- DESCRIZIONE: CONTENITORE PER VALORI DIPENDENTI DAL MEZZO
--
-- REALIZZATORE: Luigi Cipolla, Settembre 2009
--
-- Modifiche:
-- ------------------------------------------------------------------------------------------
--
-- ------------------------------------------------------------------------------------------
--
-- Restituisce il valore di gestione commerciale.
FUNCTION FU_GEST_COMM RETURN CHAR IS
BEGIN
  RETURN(GEST_COMM);
END;
--
-- Restituisce il valore di sottosistema.
FUNCTION FU_SOTTOSISTEMA RETURN CHAR IS
BEGIN
  RETURN(SOTTOSISTEMA);
END;
--
--  Restituisce il valore di mezzo.
FUNCTION FU_MEZZO RETURN CHAR IS
BEGIN
  RETURN(MEZZO);
END;
--
-- Restituisce il valore di arrotondamento, usato nel calcolo della tariffa.
FUNCTION FU_ARROTONDAMENTO RETURN NUMBER IS
BEGIN
  RETURN(ARROTONDAMENTO);
END;
--
-- Restituisce il valore di testata.
FUNCTION FU_TESTATA(P_ID_PRODOTTO_VENDITA CD_PRODOTTO_VENDITA.ID_PRODOTTO_VENDITA%TYPE) RETURN VARCHAR IS
v_flg_locale char(1):= 'S';
BEGIN

  SELECT flg_locale INTO  v_flg_locale
  FROM  cd_prodotto_vendita pv, cd_tipo_break tb
  WHERE pv.ID_TIPO_BREAK = tb.ID_TIPO_BREAK
  AND   pv.ID_PRODOTTO_VENDITA = P_ID_PRODOTTO_VENDITA;

  IF v_flg_locale = 'S' THEN
    RETURN TESTATA_LOCALE;
  ELSE
    RETURN TESTATA_NAZIONALE;
  END IF;
END FU_TESTATA;--*/
--
-- ------------------------------------------------------------------------------------------

FUNCTION FU_TESTATA_NAZIONALE RETURN VARCHAR IS
BEGIN
    return TESTATA_NAZIONALE;--
END  FU_TESTATA_NAZIONALE;

FUNCTION FU_TESTATA_LOCALE RETURN VARCHAR IS
BEGIN
    return TESTATA_LOCALE;--
END  FU_TESTATA_LOCALE;


FUNCTION FU_TESTATA_CINEMA_EVENTI RETURN VARCHAR IS
BEGIN
    return TESTATA_CINEMA_EVENTI;--
END  FU_TESTATA_CINEMA_EVENTI;


END; 
/

