CREATE OR REPLACE PROCEDURE VENCD.PR_RICALCOLA_TARIFFA_PRODOTTO(p_id_prodotto_acquistato cd_prodotto_acquistato.id_prodotto_acquistato%TYPE) IS
v_piani_errati VARCHAR2(1024);
v_importo CD_TARIFFA.IMPORTO%TYPE;
v_cod_attivazione cd_prodotto_acquistato.cod_attivazione%type;
v_numero_ambienti number;
v_numero_ambienti_iniziale number;
v_id_prodotto_saltato cd_recupero_prodotto.id_prodotto_saltato%type;
v_importo_a_recupero cd_prodotto_acquistato.imp_recupero%type;
v_importo_lordo_saltato cd_prodotto_acquistato.imp_lordo_saltato%type;
v_imp_lordo_saltato_orig cd_prodotto_acquistato.imp_lordo_saltato%type;
/*v_lordo_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto_com_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_netto_dir_prodotto        CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;*/


------------
v_lordo                     CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_netto                     CD_PRODOTTO_ACQUISTATO.IMP_NETTO%TYPE;
v_maggiorazione             CD_PRODOTTO_ACQUISTATO.IMP_MAGGIORAZIONE%TYPE;
v_recupero                  CD_PRODOTTO_ACQUISTATO.IMP_RECUPERO%TYPE;
v_sanatoria                 CD_PRODOTTO_ACQUISTATO.IMP_SANATORIA%TYPE;
v_tariffa                   CD_TARIFFA.IMPORTO%TYPE;
v_lordo_saltato             CD_PRODOTTO_ACQUISTATO.IMP_LORDO_SALTATO%TYPE;
v_id_formato                CD_PRODOTTO_ACQUISTATO.ID_FORMATO%TYPE;
v_tariffa_variabile         CD_PRODOTTO_ACQUISTATO.FLG_TARIFFA_VARIABILE%TYPE;
v_esito                     number;
v_lordo_comm                CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_lordo_dir                 CD_PRODOTTO_ACQUISTATO.IMP_LORDO%TYPE;
v_perc_sc_comm              CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_perc_sc_dir               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_netto_comm                CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_comm               CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_netto_dir                 CD_IMPORTI_PRODOTTO.IMP_NETTO%TYPE;
v_imp_sc_dir                CD_IMPORTI_PRODOTTO.IMP_SC_COMM%TYPE;
v_list_maggiorazioni id_list_type;
v_ind_maggiorazioni NUMBER;
v_posizione_rigore cd_posizione_rigore.COD_POSIZIONE%type;
------------

BEGIN
        v_importo := PA_CD_PRODOTTO_ACQUISTATO.FU_GET_TARIFFA_PRODOTTO(P_ID_PRODOTTO_ACQUISTATO);
        PA_CD_PRODOTTO_ACQUISTATO.PR_RICALCOLA_TARIFFA_PROD_ACQ(P_ID_PRODOTTO_ACQUISTATO,
                                        v_importo,
                                        v_importo,
                                        'S',
                                        v_piani_errati);
      select cod_attivazione  
      into   v_cod_attivazione
      from   cd_prodotto_acquistato
      where id_prodotto_acquistato = p_id_prodotto_acquistato;                                      

      if  v_cod_attivazione ='R' then
            
           
          
      
            select id_prodotto_saltato,quota_parte
            into   v_id_prodotto_saltato,v_imp_lordo_saltato_orig
            from  cd_recupero_prodotto
            where id_prodotto_recupero = p_id_prodotto_acquistato
            and tipo_contratto = 'C';  
             
            --correggo l'importo lordo saltato del prodotto saltato con l'effettivo numero di schsrmi saltati.
            v_numero_ambienti:=PA_CD_PRODOTTO_ACQUISTATO.fu_get_num_ambienti(v_id_prodotto_saltato);
      
            select nvl(numero_massimo_schermi,80) 
            into   v_numero_ambienti_iniziale 
            from   cd_prodotto_acquistato
            where id_prodotto_acquistato = v_id_prodotto_saltato; 
            
            
            v_importo_lordo_saltato := (v_numero_ambienti_iniziale - v_numero_ambienti)* v_importo;
            v_importo_a_recupero  := v_imp_lordo_saltato_orig - v_importo_lordo_saltato  ;
            

            update cd_recupero_prodotto
            set  quota_parte  = v_importo_lordo_saltato
            where id_prodotto_saltato = v_id_prodotto_saltato
            and tipo_contratto = 'C'; 
            
            update cd_importi_prodotto
            set imp_lordo_saltato  = v_importo_lordo_saltato
            where id_prodotto_acquistato = v_id_prodotto_saltato
            and tipo_contratto = 'C'; 
            
            
            dbms_output.PUT_LINE(' v_importo_lordo_saltato:'|| v_importo_lordo_saltato);
            dbms_output.PUT_LINE(' v_importo_a_recupero:'|| v_importo_a_recupero);
            
         if v_importo_a_recupero >0 then
                --imposto la differenza  d'importo (importo_lordo saltato preventivato con importo lordo saltato effettivo) sull'importo a recupero.
            
            
                SELECT IMP_LORDO, IMP_NETTO, IMP_MAGGIORAZIONE, IMP_SANATORIA, IMP_RECUPERO, IMP_TARIFFA, IMP_LORDO_SALTATO, ID_FORMATO, FLG_TARIFFA_VARIABILE
                INTO    v_lordo,  v_netto,   v_maggiorazione,   v_sanatoria, v_recupero, v_tariffa, v_lordo_saltato, v_id_formato, v_tariffa_variabile
                FROM CD_PRODOTTO_ACQUISTATO
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato;
            
            
            
            
                SELECT  IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
                INTO  v_netto_comm, v_imp_sc_comm, v_lordo_comm
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND TIPO_CONTRATTO = 'C';
        --
                SELECT  IMP_NETTO, IMP_SC_COMM, IMP_NETTO + IMP_SC_COMM
                INTO  v_netto_dir, v_imp_sc_dir, v_lordo_dir
                FROM CD_IMPORTI_PRODOTTO
                WHERE ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
                AND TIPO_CONTRATTO = 'D';
            
            
              PA_CD_IMPORTI.MODIFICA_IMPORTI(v_tariffa,v_maggiorazione,
              v_lordo,v_lordo_comm,v_lordo_dir,v_netto_comm,
              v_netto_dir,v_perc_sc_comm,v_perc_sc_dir,v_imp_sc_comm,
              v_imp_sc_dir,v_sanatoria,v_recupero,v_importo_a_recupero,'9',v_esito);
          
              FOR MAG IN (SELECT * FROM CD_MAGG_PRODOTTO
                            WHERE ID_PRODOTTO_ACQUISTATO =p_id_prodotto_acquistato) LOOP
                    v_list_maggiorazioni.EXTEND;
                    v_list_maggiorazioni(v_ind_maggiorazioni) := MAG.ID_MAGGIORAZIONE;
                    v_ind_maggiorazioni := v_ind_maggiorazioni +1;
                END LOOP;
          
          
          
               select distinct posizione_di_rigore
                into v_posizione_rigore
                from cd_comunicato
                where id_prodotto_acquistato = p_id_prodotto_acquistato
                and   flg_annullato ='N'
                and   flg_sospeso ='N'
                and   cod_disattivazione is null;
          
               pa_cd_prodotto_Acquistato.MODIFICA_PRODOTTO_ACQUISTATO(p_id_prodotto_acquistato,
                    'PRE',
                    v_tariffa,
                    v_lordo,
                    v_sanatoria,
                    v_recupero,
                    v_maggiorazione,
                    v_netto_comm,
                    v_imp_sc_comm,
                    v_netto_dir,
                    v_imp_sc_dir,
                    v_posizione_rigore,
                    v_id_formato,
                    v_tariffa_variabile,
                    v_lordo_saltato,
                    v_list_maggiorazioni);
         end if;      
            
      end if;                                         
                                        
END PR_RICALCOLA_TARIFFA_PRODOTTO; 
/

