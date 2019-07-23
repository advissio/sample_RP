
CREATE OR REPLACE TYPE VENCD."CLIENTE_COMM"                                                                                                                                                                                                                                                                                                             AS OBJECT
 (ID_CLIENTE  CHAR
 ,RAG_SOC_BR_NOME VARCHAR2(240)
 ,RAG_SOC_COGN VARCHAR2(240)
 ,INDIRIZZO VARCHAR2(240)
 ,LOCALITA VARCHAR2(240)
 ,CAP CHAR
 ,NAZIONE VARCHAR2(240)
 ,COD_FISC VARCHAR2(240)
 ,NUM_CIVICO CHAR
 ,PROVINCIA VARCHAR2(240)
 ,SESSO CHAR
 ,AREA CHAR
 ,SEDE CHAR
 ,NOME VARCHAR2(240)
 ,COGNOME VARCHAR2(240)
 ,DATA_INIZIO_VALIDITA DATE
  ,DATA_FINE_VALIDITA DATE    
)
/



