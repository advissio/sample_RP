
CREATE OR REPLACE TYPE VENCD."INTERMEDIARIO"                                                                                                                                                         AS OBJECT
(
  ID_VENDITORE_CLIENTE      CHAR(8 BYTE),
  ID_AGENZIA                CHAR(8 BYTE),
  ID_CENTRO_MEDIA           CHAR(8 BYTE),
  DATA_VALIDITA             DATE,
  ID_RAGGRUPPAMENTO        INTEGER
)
/



