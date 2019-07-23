CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SICUREZZA AS
/******************************************************************************
   NAME:       PA_CD_SICUREZZA
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        07/10/2009  Mauro Viel Altran          1. Created this package.
                                                     2. contiene tutte le funzioni nessarie per la verifica della sicurezza

******************************************************************************/


  FUNCTION FU_VERIFICA_FUNZIONI(P_CODICI_FUNZIONI VARCHAR2,P_TIPO_FUNZIONE VARCHAR2) RETURN VARCHAR2 IS
  v_codice char(3) ;
  v_temp   varchar2(32767):= P_CODICI_FUNZIONI;
  v_nome_funzione varchar2(120);
  v_nome_funzione_codice varchar2(140);
  v_return varchar2(32767) := '';
  BEGIN
  if instr(v_temp, '*') != 0 then
     while length(v_temp) >1
     loop
        v_nome_funzione_codice := substr(v_temp,0,instr(v_temp,'*')-1);
        v_temp:= substr(v_temp,instr(v_temp,'*')+1,length(v_temp));
        v_nome_funzione:=substr (v_nome_funzione_codice,0,instr(v_nome_funzione_codice,'=')-1);
        v_codice:=substr (v_nome_funzione_codice ,instr(v_nome_funzione_codice,'=')+1);
        v_return := v_return ||';'|| FU_VERIFICA_FUNZIONE(v_nome_funzione,v_codice,p_tipo_funzione);
     end loop;
     if  v_codice!= null then
         v_return := v_return ||';'|| FU_VERIFICA_FUNZIONE(v_nome_funzione,v_codice,p_tipo_funzione);
     end if;
  end if;
     --elimino il primo ;
     if length(v_return) >1 then
        v_return := substr(v_return,2);
     end if;
     return v_return;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
     raise;
     WHEN OTHERS THEN
     raise;
  END FU_VERIFICA_FUNZIONI;


FUNCTION FU_VERIFICA_FUNZIONE(P_CODICE_FUNZIONE VARCHAR2,P_TIPO_FUNZIONE VARCHAR2) RETURN VARCHAR2 IS
BEGIN
if PA_SICUREZZA.FU_ABILIT_FUNZIONE(user,p_tipo_funzione,p_codice_funzione) then
    return trim(p_codice_funzione)||'=S';
else
    return trim(p_codice_funzione)||'=N';
end if;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  raise;
  WHEN OTHERS THEN
  raise;
END FU_VERIFICA_FUNZIONE;

FUNCTION FU_VERIFICA_FUNZIONE(P_NOME_FUNZIONE VARCHAR2, P_CODICE_FUNZIONE VARCHAR2,P_TIPO_FUNZIONE VARCHAR2) RETURN VARCHAR2 IS
BEGIN
if PA_SICUREZZA.FU_ABILIT_FUNZIONE(user,p_tipo_funzione,p_codice_funzione) then
    return  trim(P_NOME_FUNZIONE)||'=S';
else
    return trim(P_NOME_FUNZIONE)||'=N';
end if;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  raise;
  WHEN OTHERS THEN
  raise;
END FU_VERIFICA_FUNZIONE;

END PA_CD_SICUREZZA;
/

