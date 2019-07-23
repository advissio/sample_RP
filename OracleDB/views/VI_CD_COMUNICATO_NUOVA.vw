CREATE OR REPLACE FORCE VIEW VENCD.VI_CD_COMUNICATO_NUOVA
(ID, ID_BREAK, ID_MATERIALE, POSIZIONE, DES_SOGG)
AS 
select 
            --br.ID_PROIEZIONE,
            spot.ID_COMUNICATO ID,
            trailer.id_break,
            mat_pi.ID_MATERIALE,
            -1 posizione--,sogg.DES_SOGG
            ,sogg.DES_SOGG
            --,br.nome_break suo,trailer.nome_break contenuto_in
           from 
           CD_BREAK br,CD_CIRCUITO_BREAK cir_br,CD_BREAK_VENDITA br_ven,
           CD_PRODOTTO_ACQUISTATO prod_acq,CD_MATERIALE_DI_PIANO mat_pi,
           CD_COMUNICATO spot, CD_TIPO_BREAK tipo
           ,(
             select id_break,id_proiezione,nome_break 
                from cd_break,cd_tipo_break 
                where 
                cd_break.flg_annullato = 'N'
                and cd_break.id_tipo_break = cd_tipo_break.id_tipo_break
                and cd_tipo_break.desc_tipo_break = 'Trailer' 
            )trailer
            ,CD_SOGGETTO_DI_PIANO sogg_pi,SOGGETTI sogg
           where 1=1
              and spot.DATA_EROGAZIONE_PREV between '31-jan-2010' and '06-feb-2010'
              and spot.FLG_ANNULLATO='N'
              and spot.FLG_SOSPESO='N'
              and spot.COD_DISATTIVAZIONE IS NULL
              and mat_pi.id_materiale_di_piano = spot.id_materiale_di_piano
              and prod_acq.ID_PRODOTTO_ACQUISTATO = spot.ID_PRODOTTO_ACQUISTATO
              and prod_acq.STATO_DI_VENDITA='PRE'
              and br_ven.ID_BREAK_VENDITA = spot.ID_BREAK_VENDITA
              and cir_br.ID_CIRCUITO_BREAK = br_ven.ID_CIRCUITO_BREAK
              and br.ID_BREAK = cir_br.ID_BREAK
              and br.ID_TIPO_BREAK = tipo.ID_TIPO_BREAK
              and tipo.DESC_TIPO_BREAK = 'Frame Screen'
              and br.id_proiezione = trailer.id_proiezione
              /*Filtri per descrizione soggetto*/
              and spot.ID_SOGGETTO_DI_PIANO = sogg_pi.ID_SOGGETTO_DI_PIANO
              and sogg_pi.COD_SOGG = sogg.COD_SOGG
     union
        /*Comunicati Trailer*/
        select 
            --br.ID_PROIEZIONE,
            spot.ID_COMUNICATO ID,
            br.id_break,
            mat_pi.ID_MATERIALE,
            spot.POSIZIONE posizione--,sogg.DES_SOGG
            ,sogg.DES_SOGG
            --,br.nome_break suo,br.nome_break contenuto_in
        from 
           CD_BREAK br,CD_CIRCUITO_BREAK cir_br,CD_BREAK_VENDITA br_ven,
           CD_PRODOTTO_ACQUISTATO prod_acq,CD_MATERIALE_DI_PIANO mat_pi,
           CD_COMUNICATO spot, CD_TIPO_BREAK tipo
           ,CD_SOGGETTO_DI_PIANO sogg_pi,SOGGETTI sogg
        where 1=1
          and spot.DATA_EROGAZIONE_PREV between '31-jan-2010' and '06-feb-2010'
          and spot.FLG_ANNULLATO='N'
          and spot.FLG_SOSPESO='N'
          and spot.COD_DISATTIVAZIONE IS NULL
          and mat_pi.id_materiale_di_piano = spot.id_materiale_di_piano
          and prod_acq.ID_PRODOTTO_ACQUISTATO = spot.ID_PRODOTTO_ACQUISTATO
          and prod_acq.STATO_DI_VENDITA='PRE'
          and br_ven.ID_BREAK_VENDITA = spot.ID_BREAK_VENDITA
          and cir_br.ID_CIRCUITO_BREAK = br_ven.ID_CIRCUITO_BREAK
          and br.ID_BREAK = cir_br.ID_BREAK
          and br.ID_TIPO_BREAK = tipo.ID_TIPO_BREAK
          and tipo.DESC_TIPO_BREAK = 'Trailer'
          /*Filtri per descrizione soggetto*/
          and spot.ID_SOGGETTO_DI_PIANO = sogg_pi.ID_SOGGETTO_DI_PIANO
          and sogg_pi.COD_SOGG = sogg.COD_SOGG
    union
    /*COMUNICATI PER INIZIO FILM*/
        select 
            --br.ID_PROIEZIONE,
            spot.ID_COMUNICATO ID,
            br.id_break,
            mat_pi.ID_MATERIALE,
            spot.POSIZIONE posizione--,sogg.DES_SOGG
            ,sogg.DES_SOGG
            --,br.nome_break suo,br.nome_break contenuto_in
        from 
            CD_BREAK br,CD_CIRCUITO_BREAK cir_br,CD_BREAK_VENDITA br_ven,
            CD_PRODOTTO_ACQUISTATO prod_acq,CD_MATERIALE_DI_PIANO mat_pi,
            CD_COMUNICATO spot, CD_TIPO_BREAK tipo
            ,CD_SOGGETTO_DI_PIANO sogg_pi,SOGGETTI sogg
        where 1=1
          and spot.DATA_EROGAZIONE_PREV between '31-jan-2010' and '06-feb-2010'
          and spot.FLG_ANNULLATO='N'
          and spot.FLG_SOSPESO='N'
          and spot.COD_DISATTIVAZIONE IS NULL
          and mat_pi.id_materiale_di_piano = spot.id_materiale_di_piano
          and prod_acq.ID_PRODOTTO_ACQUISTATO = spot.ID_PRODOTTO_ACQUISTATO
          and prod_acq.STATO_DI_VENDITA='PRE'
          and br_ven.ID_BREAK_VENDITA = spot.ID_BREAK_VENDITA
          and cir_br.ID_CIRCUITO_BREAK = br_ven.ID_CIRCUITO_BREAK
          and br.ID_BREAK = cir_br.ID_BREAK
          and br.ID_TIPO_BREAK = tipo.ID_TIPO_BREAK
          and tipo.DESC_TIPO_BREAK = 'Inizio Film'
          /*Filtri per descrizione soggetto*/
          and spot.ID_SOGGETTO_DI_PIANO = sogg_pi.ID_SOGGETTO_DI_PIANO
          and sogg_pi.COD_SOGG = sogg.COD_SOGG
     union
        /*COMUNICATI PER BREAK TOP SPOT*/ 
        select 
            --br.ID_PROIEZIONE,
            spot.ID_COMUNICATO ID,
            inizio_film.id_break,
            mat_pi.ID_MATERIALE,
        /*Poisizione 92 e la posizione FISSA del TopSpot*/
       92 posizione
       ,sogg.DES_SOGG
       --,br.nome_break suo,inizio_film.nome_break contenuto_in
           from 
           CD_BREAK br,CD_CIRCUITO_BREAK cir_br,CD_BREAK_VENDITA br_ven,
           CD_PRODOTTO_ACQUISTATO prod_acq,CD_MATERIALE_DI_PIANO mat_pi,
           CD_COMUNICATO spot, CD_TIPO_BREAK tipo
           ,(
             select id_break,id_proiezione,nome_break 
                from cd_break,cd_tipo_break 
                where 
                cd_break.flg_annullato = 'N'
                and cd_break.id_tipo_break = cd_tipo_break.id_tipo_break
                and cd_tipo_break.desc_tipo_break = 'Inizio Film' 
            )inizio_film
           ,CD_SOGGETTO_DI_PIANO sogg_pi,SOGGETTI sogg
           where 1=1
              and spot.DATA_EROGAZIONE_PREV between '31-jan-2010' and '06-feb-2010'
              and spot.FLG_ANNULLATO='N'
              and spot.FLG_SOSPESO='N'
              and spot.COD_DISATTIVAZIONE IS NULL
              and mat_pi.id_materiale_di_piano = spot.id_materiale_di_piano
              and prod_acq.ID_PRODOTTO_ACQUISTATO = spot.ID_PRODOTTO_ACQUISTATO
              and prod_acq.STATO_DI_VENDITA='PRE'
              and br_ven.ID_BREAK_VENDITA = spot.ID_BREAK_VENDITA
              and cir_br.ID_CIRCUITO_BREAK = br_ven.ID_CIRCUITO_BREAK
              and br.ID_BREAK = cir_br.ID_BREAK
              and br.ID_TIPO_BREAK = tipo.ID_TIPO_BREAK
              and tipo.DESC_TIPO_BREAK = 'Top Spot'
              and br.id_proiezione = inizio_film.id_proiezione
              /*Filtri per descrizione soggetto*/
              and spot.ID_SOGGETTO_DI_PIANO = sogg_pi.ID_SOGGETTO_DI_PIANO
              and sogg_pi.COD_SOGG = sogg.COD_SOGG
    union
/*GINGLE NEL CASO SIANO PRESENTI TOP SPOT*/
    select --br.ID_PROIEZIONE,
       000000 ID,
       inizio_film.id_break,
       /*Materilae 82 e il Gingle*/
       82,
       /*Poisizione 91 e la posizione FISSA del Gingle*/
       91 posizione--,sogg.DES_SOGG
       ,'GINGLE TOP SPOT' DES_SOGG
       --,br.nome_break suo,inizio_film.nome_break contenuto_in
       from 
           CD_BREAK br,CD_CIRCUITO_BREAK cir_br,CD_BREAK_VENDITA br_ven,
           CD_PRODOTTO_ACQUISTATO prod_acq,CD_MATERIALE_DI_PIANO mat_pi,
           CD_COMUNICATO spot, CD_TIPO_BREAK tipo
           ,(
             select id_break,id_proiezione,nome_break 
                from cd_break,cd_tipo_break 
                where 
                cd_break.flg_annullato = 'N'
                and cd_break.id_tipo_break = cd_tipo_break.id_tipo_break
                and cd_tipo_break.desc_tipo_break = 'Inizio Film' 
            )inizio_film
           where 1=1
              and spot.DATA_EROGAZIONE_PREV between '31-jan-2010' and '06-feb-2010'
              and spot.FLG_ANNULLATO='N'
              and spot.FLG_SOSPESO='N'
              and spot.COD_DISATTIVAZIONE IS NULL
              and mat_pi.id_materiale_di_piano = spot.id_materiale_di_piano
              and prod_acq.ID_PRODOTTO_ACQUISTATO = spot.ID_PRODOTTO_ACQUISTATO
              and prod_acq.STATO_DI_VENDITA='PRE'
              and br_ven.ID_BREAK_VENDITA = spot.ID_BREAK_VENDITA
              and cir_br.ID_CIRCUITO_BREAK = br_ven.ID_CIRCUITO_BREAK
              and br.ID_BREAK = cir_br.ID_BREAK
              and br.ID_TIPO_BREAK = tipo.ID_TIPO_BREAK
              and tipo.DESC_TIPO_BREAK = 'Top Spot'
              and br.id_proiezione = inizio_film.id_proiezione
     --order by posizione asc
/



