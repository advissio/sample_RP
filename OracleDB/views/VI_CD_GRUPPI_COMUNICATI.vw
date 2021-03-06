CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_GRUPPI_COMUNICATI
(ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, COD_SOGG_DI_PIANO, TITOLO_MAT, ID_STR_COMUNICATO, 
 ID_CINEMA, NOME_CINEMA, COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA, 
 NOME_AMBIENTE, DATA_EROGAZIONE, LUOGO, FLG_ANNULLATO)
AS 
SELECT
     ID_SOGGETTO_DI_PIANO,
     DESC_SOGG_DI_PIANO,
     COD_SOGG_DI_PIANO,
     TITOLO_MAT,
     ID_STR_COMUNICATO,
     ID_CINEMA,
     NOME_CINEMA,  
     COMUNE_CINEMA, 
     PROVINCIA_CINEMA, 
     REGIONE_CINEMA, 
     NOME_AMBIENTE,
     DATA_EROGAZIONE,  
     LUOGO,  
     FLG_ANNULLATO
--
FROM   TABLE(pa_cd_comunicato.FU_GRUPPI_COMUNICATI(pa_cd_comunicato.FU_RIT_PROD_ACQUISTATO,pa_cd_comunicato.FU_DATA_DA,pa_cd_comunicato.FU_DATA_A,
                                         pa_cd_comunicato.FU_REGIONE,pa_cd_comunicato.FU_PROVINCIA,pa_cd_comunicato.FU_COMUNE,
                                         pa_cd_comunicato.FU_CINEMA,pa_cd_comunicato.FU_SOGGETTO))
/



