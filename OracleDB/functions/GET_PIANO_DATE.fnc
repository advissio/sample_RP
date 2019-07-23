CREATE OR REPLACE FUNCTION 
VENCD.get_piano_date(p_anno cd_importi_richiesti_piano.anno%type, 
               p_ciclo cd_importi_richiesti_piano.ciclo%type, 
               p_per cd_importi_richiesti_piano.per%type,
               p_id_periodo cd_importi_richiesti_piano.ID_PERIODO%type,
               p_id_periodo_speciale cd_importi_richiesti_piano.ID_PERIODO_SPECIALE%type,
               p_data_inizio_fine char) RETURN varchar2 IS

--I inizio
--F fine
v_data_inizio date;
v_data_fine date;

BEGIN
   if p_id_periodo is not null then 
       select data_inizio, data_fine
       into   v_data_inizio, v_data_fine
       from   cd_periodi_cinema 
       where  id_periodo = p_id_periodo;
   else
       if p_id_periodo_speciale is not null then
           select data_inizio, data_fine
           into   v_data_inizio, v_data_fine
           from   cd_periodo_speciale
           where  id_periodo_speciale = p_id_periodo_speciale;
       else
           select data_iniz, data_fine
           into   v_data_inizio, v_data_fine
           from   periodi
           where  anno  = p_anno
           and    ciclo = p_ciclo
           and    per   = p_per ; 
       end if;
       
   end if;
   
   if  p_data_inizio_fine = 'I' then
        return v_data_inizio;
   else
        return v_data_fine;
   end if;
   return to_char(v_data_inizio,'DD/MM/YYYY') ||','|| to_char(v_data_fine,'DD/MM/YYYY');
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE;
     WHEN OTHERS THEN
       RAISE;
END get_piano_date; 
/

