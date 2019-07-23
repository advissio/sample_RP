CREATE OR REPLACE PROCEDURE VENCD.Determina_Venditore_Cliente
  ( P_COD_VEND_CLI IN varchar2,
    decorrenza in date,
    cliente in VARCHAR2,
    cod_agz        in VARCHAR2, --FB10g
    cod_cacq    in VARCHAR2, --FB10g
    DGC                in VARCHAR2, --FB10g
    modalita  in varchar2, --FB10g
    cod_vend in out VARCHAR2,
    des_vend in out varchar2 )
IS
  -- Determina il venditore del cliente in base alla data di decorrenza.

  cod_vend_cli                 VARCHAR2(8);
  des_vend_cli                 varchar2(70);
  vend_tmp                         VARCHAR2(8);--FB10g
  v_stringa_vend_cli     varchar2(500);--FB10g
  ok                        number;            --FB10g
BEGIN
  -- Verifica che i parametri data e cliente siano valorizzati.
  --if ( decorrenza is null or cliente is null ) then
    --Pa_Template.Pr_Show_Malfunzionamento( 'Determina_Venditore_Cliente: parametri obbligatori non valorizzati' );
    --Raise Form_Trigger_Failure;
  --end if;

  -- Determina il venditore del cliente da portafoglio.
--FB10g inizio
  vend_tmp := ventv.PA_rt_intermediari.VEND_CLI( cliente, decorrenza,
                                                                                          cod_agz,
                                                                                          cod_cacq,
                                                                                          DGC,
                                                                                          v_stringa_vend_cli
                                                                                          );
/*pa_template.pr_show_nota('cod_vend ='||cod_vend);
pa_template.pr_show_nota('modo_operativo ='||modo_operativo);
pa_template.pr_show_nota('vend_tmp ='||vend_tmp);
pa_template.pr_show_nota('v_stringa_vend_cli ='||v_stringa_vend_cli);
pa_template.pr_show_nota('parameter.P_COD_VEND_CLI ='||:parameter.P_COD_VEND_CLI);*/
   if vend_tmp is not null and
       vend_tmp<>'********' then
      --if ( vend_tmp = cod_vend ) then
        cod_vend_cli := vend_tmp;
    -- caso 2: + di un venditore
    elsif vend_tmp is not null and
          vend_tmp='********' then
      if modalita ='VERIFICA' then
        select max(venditore),
               count(*)
          into cod_vend_cli,
               ok
          from VI_PC_PORTAFOGLIO_VENDITORI;
        if ok=0 then
          cod_vend_cli:=null;
        end if;
      else
        --if show_lov('lov_vend_cliente') then
--pa_template.pr_show_nota('parameter.P_COD_VEND_CLI ='||:parameter.P_COD_VEND_CLI);
            cod_vend_cli := P_COD_VEND_CLI;
       -- end if;
      end if;
    -- caso 3: nessun venditore
    else
      cod_vend_cli :=null;
    end if;
--FB10g fine


  if ( cod_vend_cli is null ) AND (modo_operativo = 'INSERIMENTO' ) then
    -- Segnala che non e stato possibile reperire il dato da portafoglio.
    Pa_Template.Pr_Show_Nota( 'Attenzione: venditore del cliente non reperibile da portafoglio' );
  elsif ( cod_vend_cli is not null ) then
    -- Legge la descrizione del venditore del cliente.
    select ragsoc into des_vend_cli from venditori where cod_interl = cod_vend_cli;
  end if;

  -- Imposta i valori di output di codice e descrizione del cliente.
  cod_vend := cod_vend_cli;
  des_vend := des_vend_cli;
--pa_template.pr_show_nota('cod_vend ='||cod_vend);
END; 
/

