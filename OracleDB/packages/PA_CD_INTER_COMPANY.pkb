CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_INTER_COMPANY AS
/******************************************************************************
   NAME:       PA_CD_INTER_COMPANY
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/03/2010             1. Created this package body.
   
   Modifiche Mauro Viel Altran italia aggiunta la join su cd_sala e il filtro 
                        su flg_arena ='S' per esporre i soli dati delle Arene.
                                                    
******************************************************************************/



  
PROCEDURE PR_CREA_PLAYLIST_CSV(P_DATA_INIZIO CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, P_DATA_FINE CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE, P_ESITO OUT NUMBER) IS
  InterFile    utl_file.file_type;
  v_auto_flush boolean:= false;
  v_line varchar2(1000);
  BEGIN
  p_esito := 0; 
  InterFile := utl_file.fopen(V_PATH, 'PLAYLIST_'||to_char(P_DATA_INIZIO,'DDMMYYYY')||'_'||to_char(P_DATA_FINE,'DDMMYYYY')||'.CSV','a');
  PA_CD_ADV_CINEMA.IMPOSTA_PARAMETRI(P_DATA_INIZIO,P_DATA_FINE);
  for c in (/*select distinct  com.DATA_EROGAZIONE_PREV, id_sala,rag_soc_cogn,sogpia.descrizione,durata
            from cd_comunicato  com, 
            cd_prodotto_acquistato pa,
            cd_formato_acquistabile fa,
            cd_coeff_cinema coeff,
            cd_pianificazione pia, 
            interl_u inte,
            cd_soggetto_di_piano sogpia
            where com.DATA_EROGAZIONE_PREV between  p_data_inizio and p_data_fine
            and pa.ID_PRODOTTO_ACQUISTATO = com.ID_PRODOTTO_ACQUISTATO
            and pa.STATO_DI_VENDITA = 'PRE'
            and fa.ID_FORMATO = pa.ID_FORMATO
            and coeff.ID_COEFF = fa.ID_FORMATO
            and pia.id_piano = pa.ID_PIANO
            and pia.ID_VER_PIANO = pa.ID_VER_PIANO
            and pia.ID_CLIENTE = inte.COD_INTERL
            and sogpia.ID_PIANO =pia.ID_PIANO
            and sogpia.ID_VER_PIANO = pia.ID_VER_PIANO
            and com.flg_annullato ='N'
            and com.FLG_SOSPESO = 'N'
            and com.COD_DISATTIVAZIONE is null
            and pa.flg_annullato ='N'
            and pa.FLG_SOSPESO = 'N'
            and pa.COD_DISATTIVAZIONE is null
            and com.ID_SOGGETTO_DI_PIANO = sogpia.ID_SOGGETTO_DI_PIANO
            order by id_sala,com.DATA_EROGAZIONE_PREV,durata*/
            select co.DATA_EROGAZIONE_PREV, co.id_sala, co.tipo_break, co.id_comunicato, CLI.rag_soc_cogn, co.DES_SOGG, coeff.durata, co.posizione
            from
              interl_u CLI,
              cd_coeff_cinema coeff,
              cd_formato_acquistabile fa,
              cd_pianificazione pia,
              cd_prodotto_acquistato pa,
              -- estrae uno solo dei comunicati tipo per ciascun prodotto_acquistato/sala/giorno
              (select max(com.id_comunicato) id_comunicato,
                      com.ID_PRODOTTO_ACQUISTATO,
                      com.DATA_EROGAZIONE_PREV,
                      com.ID_SALA,
                      max(vibr.tipo_break) tipo_break,
                      max(vico.DES_SOGG) DES_SOGG,
                      max(com.posizione) posizione
               from cd_comunicato COM,
                    vi_cd_break vibr,
                    vi_cd_comunicato vico,
                    cd_sala sa
               where vibr.id = vico.id_break
                 and vico.id = com.id_comunicato
                 and sa.id_sala = com.ID_SALA
                 and sa.FLG_ARENA = 'S'
               group by com.DATA_EROGAZIONE_PREV, com.ID_SALA, com.ID_PRODOTTO_ACQUISTATO
              ) co
           where pa.ID_PRODOTTO_ACQUISTATO = co.ID_PRODOTTO_ACQUISTATO
              and pa.STATO_DI_VENDITA = 'PRE'
              and pa.flg_annullato ='N'
              and pa.FLG_SOSPESO = 'N'
              and pa.COD_DISATTIVAZIONE is null
              and pia.id_piano = pa.ID_PIANO
              and pia.ID_VER_PIANO = pa.ID_VER_PIANO
              and fa.ID_FORMATO = pa.ID_FORMATO
              and coeff.ID_COEFF = fa.ID_COEFF
              and CLI.COD_INTERL = pia.ID_CLIENTE
            order by co.DATA_EROGAZIONE_PREV, id_sala, co.tipo_break desc, co.posizione
            )
            loop
                v_line := to_char(c.DATA_EROGAZIONE_PREV,'DDMMYYYY') || ';' ||c.id_sala|| ';' || c.tipo_break || ';' || c.id_comunicato || ';' || c.rag_soc_cogn || ';' || c.des_sogg || ';' || c.durata || ';' || c.posizione; 
                --v_line := to_char(c.DATA_EROGAZIONE_PREV,'DDMMYYYY') || ';' ||c.id_sala|| ';' ||c.rag_soc_cogn|| ';' ||c.descrizione|| ';' ||c.durata;
                utl_file.PUT_LINE(InterFile,v_line,v_auto_flush);
                utl_file.FFLUSH(InterFile);
                P_ESITO := 1;
            end loop;
            P_ESITO := 1;
            utl_file.FCLOSE(InterFile);
            EXCEPTION 
            WHEN OTHERS THEN
                raise;
                utl_file.FCLOSE(InterFile);
                P_ESITO := -1;
            END;
  END ; 
/

