CREATE OR REPLACE PROCEDURE VENCD.PR_CD_SP_EXPORT_DIAGNOSI 
(
  DATA_FROM IN DATE,
  DATA_TO IN DATE
) AS
 id_sala number;
 id_cinema number;
 stato_12 number;
 stato_13 number;
 stato_14 number;
 stato_15 number;
 stato_16 number;
 stato_17 number;
 stato_18 number;
 prev_stato_12 number;
 prev_stato_13 number;
 prev_stato_14 number;
 prev_stato_15 number;
 prev_stato_16 number;
 prev_stato_17 number;
 prev_stato_18 number;
 prev_date date;
 yesterday date;
 tmp_date date;
 cursor cinema_curs is
    select a.id_cinema, b.nome
    from CD_ADV_CINEMA a left join VI_CD_CINEMA b on a.id_cinema = b.id;
 cursor sala_curs is
    select a.id_sala, b.nome as nome_sala, c.id as id_cinema, c.nome as nome_cinema
    from CD_ADV_SALA a left join VI_CD_SALA b on a.id_sala = b.id
        left join VI_CD_CINEMA c on b.id_cinema = c.id;
        
 cursor eventi_sala_curs (curr_sala number, data_from date, data_to date) is
    select to_date(to_char(tempo, 'DD-MM-YYYY'), 'DD-MM-YYYY') as tempo, stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18
    from cd_nagios_diagnosi
    where id_sala = curr_sala and tempo >= data_from and tempo < data_to
    order by tempo;
 cursor eventi_cinema_curs (curr_cinema number, data_from date, data_to date) is
    select to_date(to_char(tempo, 'DD-MM-YYYY'), 'DD-MM-YYYY') as tempo, stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18
    from cd_nagios_diagnosi
    where id_sala is null and id_cinema = curr_cinema and tempo >= data_from and tempo < data_to
    order by tempo;
BEGIN


  --PULISCO LA TABELLA DI DESTINAZIONE
  begin execute Immediate 'TRUNCATE TABLE cd_nagios_diagnosi_report'; end;

  -- PER OGNI CINEMA / SALA / GIORNO RECUPERO LO STATO

 
  --CICLO SU TUTTE LE SALE
  for sala in sala_curs
  loop
    begin
      -- RECUPERO LO STATO INIZIALE   
    
      select stato_12, stato_13, stato_14, stato_15 
        into stato_12, stato_13, stato_14, stato_15 from cd_nagios_diagnosi
        where tempo = (select max(tempo) from cd_nagios_diagnosi where tempo < DATA_FROM
                      and id_sala = sala.id_sala) and id_sala = sala.id_sala;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- SE NON TROVO NIENTE ALLORA INIZIALIZZO LO STATO PULITO
      stato_12  := 0;
      stato_13  := 0;
      stato_14  := 0;
      stato_15  := 0;
    end;
    
    begin
      -- RECUPERO LO STATO INIZIALE DEL CINEMA
    
      select stato_16, stato_17, stato_18 
        into stato_16, stato_17, stato_18 from cd_nagios_diagnosi
        where tempo = (select max(tempo) from cd_nagios_diagnosi where tempo < DATA_FROM
                      and id_sala is null and id_cinema = sala.id_cinema) and id_sala is null and id_cinema = sala.id_cinema;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- SE NON TROVO NIENTE ALLORA INIZIALIZZO LO STATO PULITO
      stato_16  := 0;
      stato_17  := 0;
      stato_18  := 0;
    end; 
    
    prev_date := to_date(to_char(DATA_FROM, 'DD-MM-YYYY'), 'DD-MM-YYYY');
    
    for curr_stato in eventi_sala_curs(sala.id_sala, DATA_FROM, DATA_TO)
    loop
      if curr_stato.tempo > prev_date then
        -- ho cambiato giorno. Inserisco lo stato attuale per tutti i giorni compresi tra prev_date e curr_day - 1
        yesterday := curr_stato.tempo - 1;
              
        while prev_date <= yesterday
        loop
           insert into cd_nagios_diagnosi_report (id_sala, nome_sala, id_cinema, nome_cinema, giorno, LAMPADA_PROIETTORE, PROIETTORE, box_i_o, PC_PLAYER, PC_SERVER, ALTRO, RETE_FASTWEB) 
            values (sala.id_sala, sala.nome_sala, sala.id_cinema, sala.nome_cinema, prev_date, stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18);
            prev_date := prev_date +1;
        end loop;
        
        --INIZIALIZZO LO STATO DEL NUOVO GIORNO CON L'ULTIMO STATO TROVATO
        stato_12 := prev_stato_12;
        stato_13 := prev_stato_13;
        stato_14 := prev_stato_14;
        stato_15 := prev_stato_15;
        stato_16 := prev_stato_16;
        stato_17 := prev_stato_17;
        stato_18 := prev_stato_18;
        
      end if;
      
      if curr_stato.stato_12 = 1 then
        stato_12 := 1;
      end if;
      if curr_stato.stato_13 = 1 then
        stato_13 := 1;
      end if;
      if curr_stato.stato_14 = 1 then
        stato_14 := 1;
      end if;
      if curr_stato.stato_15 = 1 then
        stato_15 := 1;
      end if;
      if curr_stato.stato_16 = 1 then
        stato_16 := 1;
      end if;
      if curr_stato.stato_17 = 1 then
        stato_17 := 1;
      end if;
      if curr_stato.stato_18 = 1 then
        stato_18 := 1;
      end if;
      
      -- MI SALVO IL PREV STATO
      prev_stato_12 := curr_stato.stato_12;
      prev_stato_13 := curr_stato.stato_13;
      prev_stato_14 := curr_stato.stato_14;
      prev_stato_15 := curr_stato.stato_15;
      
      tmp_date := curr_stato.tempo + 1;
      
      begin
       
      
        select stato_16, stato_17, stato_18 
          into prev_stato_16, prev_stato_17, prev_stato_18 from cd_nagios_diagnosi
          where tempo = (select max(tempo) from cd_nagios_diagnosi where tempo < tmp_date
                        and id_sala is null and id_cinema = sala.id_cinema) and id_sala is null and id_cinema = sala.id_cinema;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- SE NON TROVO NIENTE ALLORA INIZIALIZZO LO STATO PULITO
        prev_stato_16  := 0;
        prev_stato_17  := 0;
        prev_stato_18  := 0;
      end;
      
      prev_date := curr_stato.tempo;
    end loop;
    
    --ESCO DAL CICLO QUANDO FINISCONO GLI EVENTI.
    --L'ULTIMA DATA ANALIZZATA LA TROVO DENTRO PREV_DATE
    --INSERISCO LO STATO CALCOLATO DA PREV_DATE A DATE_TO
    
    
    while prev_date <= DATA_TO
    loop
       insert into cd_nagios_diagnosi_report (id_sala, nome_sala, id_cinema, nome_cinema, giorno, LAMPADA_PROIETTORE, PROIETTORE, box_i_o, PC_PLAYER, PC_SERVER, ALTRO, RETE_FASTWEB) 
        values (sala.id_sala, sala.nome_sala, sala.id_cinema, sala.nome_cinema, prev_date, stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18);
        prev_date := prev_date +1;
    end loop;

  end loop;

  --CICLO SU TUTTI I CINEMA
  for cinema in cinema_curs
  loop
    begin
      -- RECUPERO LO STATO INIZIALE   
    
      select stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18 
        into stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18 from cd_nagios_diagnosi
        where tempo = (select max(tempo) from cd_nagios_diagnosi where tempo < DATA_FROM
                      and id_sala is null and id_cinema = cinema.id_cinema) and id_sala is null and id_cinema = cinema.id_cinema;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- SE NON TROVO NIENTE ALLORA INIZIALIZZO LO STATO PULITO
      stato_16  := 0;
      stato_17  := 0;
      stato_18  := 0;
    end; 
    
    prev_date := to_date(to_char(DATA_FROM, 'DD-MM-YYYY'), 'DD-MM-YYYY');
    
    for curr_stato in eventi_cinema_curs(cinema.id_cinema, DATA_FROM, DATA_TO)
    loop
      if curr_stato.tempo > prev_date then
        -- ho cambiato giorno. Inserisco lo stato attuale per tutti i giorni compresi tra prev_date e curr_day - 1
        yesterday := curr_stato.tempo - 1;
              
        while prev_date <= yesterday
        loop
           insert into cd_nagios_diagnosi_report (id_sala, nome_sala, id_cinema, nome_cinema, giorno, LAMPADA_PROIETTORE, PROIETTORE, box_i_o, PC_PLAYER, PC_SERVER, ALTRO, RETE_FASTWEB) 
            values (NULL, NULL, cinema.id_cinema, cinema.nome, prev_date, stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18);
            prev_date := prev_date +1;
        end loop;
        
        --INIZIALIZZO LO STATO DEL NUOVO GIORNO CON L'ULTIMO STATO TROVATO
        stato_16 := prev_stato_16;
        stato_17 := prev_stato_17;
        stato_18 := prev_stato_18;
        
      end if;
      
      if curr_stato.stato_16 = 1 then
        stato_16 := 1;
      end if;
      if curr_stato.stato_17 = 1 then
        stato_17 := 1;
      end if;
      if curr_stato.stato_18 = 1 then
        stato_18 := 1;
      end if;
      
      -- MI SALVO IL PREV STATO
      prev_stato_16 := curr_stato.stato_16;
      prev_stato_17 := curr_stato.stato_17;
      prev_stato_18 := curr_stato.stato_18;
      prev_date := curr_stato.tempo;
    end loop;
    
    --ESCO DAL CICLO QUANDO FINISCONO GLI EVENTI.
    --L'ULTIMA DATA ANALIZZATA LA TROVO DENTRO PREV_DATE
    --INSERISCO LO STATO CALCOLATO DA PREV_DATE A DATE_TO   
    
    while prev_date <= DATA_TO
    loop
       insert into cd_nagios_diagnosi_report (id_sala, nome_sala, id_cinema, nome_cinema, giorno, LAMPADA_PROIETTORE, PROIETTORE, box_i_o, PC_PLAYER, PC_SERVER, ALTRO, RETE_FASTWEB) 
        values (NULL, NULL, cinema.id_cinema, cinema.nome, prev_date, stato_12, stato_13, stato_14, stato_15, stato_16, stato_17, stato_18);
        prev_date := prev_date +1;
    end loop;
       
  end loop;

END PR_CD_SP_EXPORT_DIAGNOSI; 
/

