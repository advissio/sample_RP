CREATE OR REPLACE FUNCTION VENCD.FU_CD_GET_DGC(
                        pp_id_prod_pubb CD_PRODOTTO_PUBB.ID_PRODOTTO_PUBB%TYPE,
                        pp_cod_testata_editoriale cd_pianificazione.COD_TESTATA_EDITORIALE%type,
                        pp_tipo_sala varchar2
                       ) RETURN DET_GEST_COM.ID%type
--
-- ---------------------------------------------------------------------------------------------
-- descrizione:
--	 individua il Dettaglio di Gestione Commerciale (DGC) corrispondente ai parametri in input.
--
-- input:
--	 1) ID del Tipo Pubblicita
--	 2) ID della Testata Editoriale
--
-- output:
--	ID del DGC
--
-- realizzatore
--	 luigi cipolla, 20/10/2009
--
-- modifiche:
--   mauro viel, 21/10/2009
--     modificata la firma della funzione il parametro pp_cod_testata_editoriale
--     e diventato di tipo  cd_pianificazione.COD_TESTATA_EDITORIALE
--     inserita la variabile v_msg per gestire l'eccezione.
--   Luigi Cipolla, 03/06/2010
--     Inserimanto parametro di input pp_tipo_sala, a seguito della modifica della funzione
--     PA_PC_DGC.fu_determina_DGC
-- ---------------------------------------------------------------------------------------------
--
IS
  v_temp_DGC DET_GEST_COM.ID%type :=null;
  v_ret_DGC DET_GEST_COM.ID%type :=null;
  v_msg varchar2(50):= null;
  --
  cursor c_tipi_pubb
  is
  ( select tp.cod_tipo_pubb
    from pc_tipi_pubblicita tp,
          cd_prodotto_pubb pp
    where pp.id_prodotto_pubb = pp_id_prod_pubb
      and tp.cod_tipo_pubb = pp.cod_tipo_pubb)
  union
  ( select tp.cod_tipo_pubb
    from pc_tipi_pubblicita tp,
         cd_tipo_pubb_gruppo tpg,
         cd_prodotto_pubb pp
    where pp.id_prodotto_pubb = pp_id_prod_pubb
      and tpg.id_gruppo_tipi_pubb = pp.id_gruppo_tipi_pubb
      and tp.cod_tipo_pubb = tpg.cod_tipo_pubb);
BEGIN
  for r_tipi_pubb in c_tipi_pubb
  loop
    --  Richiamo la funzione centralizzata di reperimento del DGC
    v_ret_DGC:= PA_PC_DGC.fu_determina_DGC(
                                     p_cod_gest_comm			=>	PA_CD_MEZZO.FU_GEST_COMM,
							         p_cod_tipo_pubb			=>	r_tipi_pubb.cod_tipo_pubb,
							         p_cod_testata_editoriale	=>	pp_cod_testata_editoriale,
							         p_cod_tipo_interattivita	=>	null,
							         p_cod_tipo_sala_cinema		=>	pp_tipo_sala
							         );
    if v_temp_DGC is null
    then v_temp_DGC:= v_ret_DGC;
    else
      if v_temp_DGC != v_ret_DGC
      then
       v_msg :=   'Function FU_CD_GET_DGC: Impossibile determinare il DGC';
      end if;
	end if;
  end loop;
  --
  if v_msg is not null then
    RAISE_APPLICATION_ERROR(-20010, v_msg);
  else
    return v_temp_DGC;
  end if;
  --
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20010, 'Function FU_CD_GET_DGC: Impossibile determinare il DGC');
END FU_CD_GET_DGC; 
/

