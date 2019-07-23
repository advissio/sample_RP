CREATE OR REPLACE function VENCD.fu_rit_st_comunicati (p_data_erogazione 			 	in date,
                               p_id_prodotto_acquistato	in number,
                               p_id_soggetto_di_piano 	in number,
                               p_cd_titolo 							in varchar2,
                               p_nome_sala   						in varchar2,
                               p_id_cinema							in number

                               ) return varchar2
IS
--
--
	str_com varchar2(1200);
--
cursor c_comunicati is
	SELECT 	SP.ID_COMUNICATO
		FROM  CD_COMUNICATO SP,
				CD_SOGGETTO_DI_PIANO CS,
				CD_MATERIALE_DI_PIANO CMD,
				CD_MATERIALE CM,
--				CD_BREAK_VENDITA CV,
--				CD_CIRCUITO_BREAK CC,
--				CD_BREAK CB,
--				CD_PROIEZIONE CP,
--				CD_SCHERMO CH,
				CD_SALA  CA,
				CD_CINEMA CDC

	WHERE
					SP.DATA_EROGAZIONE_PREV = p_data_erogazione
  	AND 	SP.FLG_ANNULLATO = 'N'
  	AND 	SP.ID_PRODOTTO_ACQUISTATO = p_id_prodotto_acquistato
  	AND 	SP.ID_SOGGETTO_DI_PIANO   = p_id_soggetto_di_piano
  	AND 	SP.ID_SOGGETTO_DI_PIANO   = cs.ID_SOGGETTO_DI_PIANO
  	AND 	SP.ID_MATERIALE_DI_PIANO  = CMD.ID_MATERIALE_DI_PIANO
  	AND 	CMD.ID_MATERIALE          =	CM.ID_MATERIALE
  	AND 	CM.TITOLO 								= p_cd_titolo
		AND 	SP.ID_SALA   		          = CA.ID_SALA
--		AND   CV.ID_CIRCUITO_BREAK			=	CC.ID_CIRCUITO_BREAK
--		AND   CB.ID_BREAK								= CC.ID_BREAK
--		AND   CP.ID_PROIEZIONE					= CB.ID_PROIEZIONE
--		AND   CH.ID_SCHERMO							= CP.ID_SCHERMO
--		AND   CA.ID_SALA                = CH.ID_SALA
		AND   CA.NOME_SALA							= p_nome_sala
		and		CDC.ID_CINEMA							= CA.ID_CINEMA
		AND   CA.ID_CINEMA							= p_id_cinema
		order by sp.id_comunicato desc ;

BEGIN
  --
  str_com := to_char(NULL);
  --
  FOR C_C IN c_comunicati Loop
  	str_com := c_c.id_comunicato||'_'||str_com;
  end loop;

	return    rtrim(str_com,'_');

END fu_rit_st_comunicati;
--
/

