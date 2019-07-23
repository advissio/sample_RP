CREATE OR REPLACE procedure VENCD.print_clob( p_clob in clob )
  as
        l_offset number default 1;
   begin
     loop
      exit when l_offset > dbms_lob.getlength(p_clob);
       dbms_output.put_line( dbms_lob.substr( p_clob, 255, l_offset ) );
      l_offset := l_offset + 255;
     end loop;
  end; 
/

