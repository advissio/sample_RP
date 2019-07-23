CREATE OR REPLACE package BODY VENCD.pa_cd_paolo is
--
--
V_ID_PRODOTTO_ACQUISTATO	 CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE;
V_DATA_EROGAZIONE_FROM 		 CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE;
V_DATA_EROGAZIONE_TO 			 CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE;
V_ID_REGIONE 							 CD_REGIONE.ID_REGIONE%TYPE;
V_ID_PROVINCIA 						 CD_PROVINCIA.ID_PROVINCIA%TYPE;
V_ID_COMUNE 							 CD_COMUNE.ID_COMUNE%TYPE;
V_ID_CINEMA 							 CD_CINEMA.ID_CINEMA%TYPE;
V_ID_SOGGETTO 						 CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE;
--
--
PROCEDURE PR_SETTA_VARIABILI (P_ID_PRODOTTO_ACQUISTATO IN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
																		P_DATA_EROGAZIONE_FROM IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                                P_DATA_EROGAZIONE_TO IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                                P_ID_REGIONE IN CD_REGIONE.ID_REGIONE%TYPE,
		                                P_ID_PROVINCIA IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
		                                P_ID_COMUNE IN CD_COMUNE.ID_COMUNE%TYPE,
		                                P_ID_CINEMA IN CD_CINEMA.ID_CINEMA%TYPE,
		                                P_ID_SOGGETTO IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE) is
begin

 	V_ID_PRODOTTO_ACQUISTATO := P_ID_PRODOTTO_ACQUISTATO;
 	V_DATA_EROGAZIONE_FROM   := P_DATA_EROGAZIONE_FROM;
 	V_DATA_EROGAZIONE_TO     := P_DATA_EROGAZIONE_TO;
 	V_ID_REGIONE             := P_ID_REGIONE;
 	V_ID_PROVINCIA           := P_ID_PROVINCIA;
	V_ID_COMUNE							 := P_ID_COMUNE;
	V_ID_CINEMA              := P_ID_CINEMA;
	V_ID_SOGGETTO            := P_ID_SOGGETTO;
end;
--
--
FUNCTION FU_RIT_PROD_ACQUISTATO RETURN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE IS
begin

	RETURN V_ID_PRODOTTO_ACQUISTATO;
END;
--
--
FUNCTION FU_DATA_DA   RETURN   DATE is
begin
	return V_DATA_EROGAZIONE_FROM;
end;
--
--
FUNCTION FU_DATA_A   RETURN   DATE is
begin
	return V_DATA_EROGAZIONE_TO;
end;
--
--
FUNCTION FU_REGIONE   RETURN   CD_REGIONE.ID_REGIONE%TYPE IS
BEGIN
	return V_ID_REGIONE;
END;
--
-- 
FUNCTION FU_PROVINCIA	RETURN   CD_PROVINCIA.ID_PROVINCIA%TYPE is
BEGIN
	return    V_ID_PROVINCIA;

END; 
--
-- 
FUNCTION FU_COMUNE    RETURN	  CD_COMUNE.ID_COMUNE%TYPE is
begin
	return V_ID_COMUNE;
end; 
-- 
-- 
FUNCTION FU_CINEMA    RETURN	  CD_CINEMA.ID_CINEMA%TYPE is
begin
	return V_ID_CINEMA;
end; 
-- 
-- 
FUNCTION FU_SOGGETTO    RETURN	  CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE is
begin
	return V_ID_SOGGETTO;
end; 
-- 
FUNCTION  FU_COMUN_PAOLO_SOGG ( P_ID_PRODOTTO_ACQUISTATO IN CD_COMUNICATO.ID_PRODOTTO_ACQUISTATO%TYPE,
																		P_DATA_EROGAZIONE_FROM IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                                P_DATA_EROGAZIONE_TO IN CD_COMUNICATO.DATA_EROGAZIONE_PREV%TYPE,
		                                P_ID_REGIONE IN CD_REGIONE.ID_REGIONE%TYPE,
		                                P_ID_PROVINCIA IN CD_PROVINCIA.ID_PROVINCIA%TYPE,
		                                P_ID_COMUNE IN CD_COMUNE.ID_COMUNE%TYPE,
		                                P_ID_CINEMA IN CD_CINEMA.ID_CINEMA%TYPE,
		                                P_ID_SOGGETTO IN CD_SOGGETTO_DI_PIANO.ID_SOGGETTO_DI_PIANO%TYPE
		                                )
				RETURN TAB_SOGG PIPELINED IS
    --
    IND_TAB NUMBER;
    STR_COMUNICATO VARCHAR2(3200);
		--

		CURSOR C_COM_SOGG IS
			--
			SELECT ID_SOGGETTO_DI_PIANO, DESC_SOGG_DI_PIANO, COD_SOGG_DI_PIANO, TITOLO_MAT,ID_COMUNICATO, ID_CINEMA,NOME_CINEMA,  COMUNE_CINEMA, PROVINCIA_CINEMA, REGIONE_CINEMA, NOME_AMBIENTE,DATA_EROGAZIONE,  LUOGO,  FLG_ANNULLATO
				FROM (
			            SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                CIN.NOME_CINEMA AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'CI' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO C,
			                     CD_CINEMA_VENDITA CIN_VEN, CD_CIRCUITO_CINEMA CIR_CIN,
			                     CD_CINEMA CIN,
			                     CD_COMUNE COMUNE,
			                     CD_PROVINCIA PROVINCIA,
			                     CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO (+)= PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_CINEMA_VENDITA = CIN_VEN.ID_CINEMA_VENDITA
			                  AND CIN_VEN.ID_CIRCUITO_CINEMA = CIR_CIN.ID_CIRCUITO_CINEMA
			                  AND CIR_CIN.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE
			           UNION
			          (SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                ATR.DESC_ATRIO AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'AT' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO C,
			                     CD_ATRIO_VENDITA AT_VEN, CD_CIRCUITO_ATRIO CA,
			                     CD_ATRIO ATR, CD_CINEMA CIN,
			                     CD_COMUNE COMUNE,
			                     CD_PROVINCIA PROVINCIA,
			                     CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO (+)= PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_ATRIO_VENDITA = AT_VEN.ID_ATRIO_VENDITA
			                  AND AT_VEN.ID_CIRCUITO_ATRIO = CA.ID_CIRCUITO_ATRIO
			                  AND CA.ID_ATRIO = ATR.ID_ATRIO
			                  AND ATR.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE)
			           UNION
			          (SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                SA.NOME_SALA AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'SA' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA, CD_COMUNICATO C,
			                     CD_SALA_VENDITA SAL_VEN, CD_CIRCUITO_SALA CS,
			                     CD_SALA SA, CD_CINEMA CIN,
			                     CD_COMUNE COMUNE,
			                     CD_PROVINCIA PROVINCIA,
			                     CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO (+)= PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_SALA_VENDITA = SAL_VEN.ID_SALA_VENDITA
			                  AND SAL_VEN.ID_CIRCUITO_SALA = CS.ID_CIRCUITO_SALA
			                  AND CS.ID_SALA = SA.ID_SALA
			                  AND SA.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE)
			           UNION
			          (SELECT
			                (SELECT DISTINCT SP.ID_SOGGETTO_DI_PIANO FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS ID_SOGGETTO_DI_PIANO,
			                (SELECT DISTINCT SP.DESCRIZIONE FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS DESC_SOGG_DI_PIANO,
			                (SELECT DISTINCT SP.COD_SOGG FROM CD_SOGGETTO_DI_PIANO SP
			                    WHERE SP.ID_SOGGETTO_DI_PIANO (+)= C.ID_SOGGETTO_DI_PIANO) AS COD_SOGG_DI_PIANO,
			                (SELECT DISTINCT MAT.TITOLO FROM CD_MATERIALE_DI_PIANO MAT_PIA, CD_MATERIALE MAT
			                    WHERE MAT_PIA.ID_MATERIALE_DI_PIANO (+)= C.ID_MATERIALE_DI_PIANO
			                    AND MAT.ID_MATERIALE = MAT_PIA.ID_MATERIALE) AS TITOLO_MAT,
			                C.ID_COMUNICATO AS ID_COMUNICATO,
			                CIN.ID_CINEMA AS ID_CINEMA,
			                CIN.NOME_CINEMA AS NOME_CINEMA,
			                (SELECT COMUNE.COMUNE FROM CD_COMUNE COMUNE
			                        WHERE COMUNE.ID_COMUNE = CIN.ID_COMUNE) AS COMUNE_CINEMA,
			                PROVINCIA.PROVINCIA AS PROVINCIA_CINEMA,
			                REGIONE.NOME_REGIONE AS REGIONE_CINEMA,
			                SA.NOME_SALA AS NOME_AMBIENTE,
			                C.DATA_EROGAZIONE_PREV AS DATA_EROGAZIONE,
			                'TA' AS LUOGO,
			                C.FLG_ANNULLATO AS FLG_ANNULLATO
			                FROM CD_PRODOTTO_ACQUISTATO PA,
			                    CD_COMUNICATO C,
			                    CD_CIRCUITO_BREAK CIR_BR,
			                    CD_CINEMA CIN,
			                    CD_SALA SA,
			                    CD_BREAK_VENDITA BRV,
			                    CD_BREAK BR,
			                    CD_PROIEZIONE PR,
			                    CD_SCHERMO  SCH,
			                    CD_COMUNE COMUNE,
			                    CD_PROVINCIA PROVINCIA,
			                    CD_REGIONE REGIONE
			                WHERE PA.ID_PRODOTTO_ACQUISTATO = P_ID_PRODOTTO_ACQUISTATO
			                  AND C.ID_PRODOTTO_ACQUISTATO = PA.ID_PRODOTTO_ACQUISTATO
			                  AND C.DATA_EROGAZIONE_PREV BETWEEN P_DATA_EROGAZIONE_FROM AND P_DATA_EROGAZIONE_TO
			                  AND (P_ID_CINEMA IS NULL OR CIN.ID_CINEMA = P_ID_CINEMA)
			                  AND (P_ID_COMUNE IS NULL OR COMUNE.ID_COMUNE = P_ID_COMUNE)
			                  AND (P_ID_PROVINCIA IS NULL OR PROVINCIA.ID_PROVINCIA = P_ID_PROVINCIA)
			                  AND (P_ID_REGIONE IS NULL OR REGIONE.ID_REGIONE = P_ID_REGIONE)
			                  AND (P_ID_SOGGETTO IS NULL OR C.ID_SOGGETTO_DI_PIANO = P_ID_SOGGETTO)
			                  AND PA.FLG_ANNULLATO = 'N'
			                  AND PA.FLG_SOSPESO = 'N'
			                  AND PA.COD_DISATTIVAZIONE IS NULL
			                  AND C.FLG_ANNULLATO = 'N'
			                  AND C.FLG_SOSPESO = 'N'
			                  AND C.COD_DISATTIVAZIONE IS NULL
			                  AND C.ID_BREAK_VENDITA = BRV.ID_BREAK_VENDITA
			                  AND BRV.ID_CIRCUITO_BREAK = CIR_BR.ID_CIRCUITO_BREAK
			                  AND BR.ID_BREAK = CIR_BR.ID_BREAK
			                  AND PR.ID_PROIEZIONE = BR.ID_PROIEZIONE
			                  AND SCH.ID_SCHERMO = PR.ID_SCHERMO
			                  AND SCH.ID_SALA = SA.ID_SALA
			                  AND SA.ID_CINEMA = CIN.ID_CINEMA
			                  AND COMUNE.ID_COMUNE = CIN.ID_COMUNE
			                  AND PROVINCIA.ID_PROVINCIA = COMUNE.ID_PROVINCIA
			                  AND REGIONE.ID_REGIONE = PROVINCIA.ID_REGIONE)
			                  )
				order by        id_cinema,data_erogazione,nome_ambiente,cod_sogg_di_piano,titolo_mat,id_comunicato;
			--
BEGIN

			ind_tab := 0;
			--
			FOR r IN C_COM_SOGG	LOOP
			--
				tab_temp(ind_tab).ID_SOGGETTO_DI_PIANO := 	r.ID_SOGGETTO_DI_PIANO;
			  tab_temp(ind_tab).DESC_SOGG_DI_PIANO	 :=	r.DESC_SOGG_DI_PIANO;
			  tab_temp(ind_tab).COD_SOGG_DI_PIANO    :=	r.COD_SOGG_DI_PIANO;
			  tab_temp(ind_tab).TITOLO_MAT           :=	r.TITOLO_MAT;
			  tab_temp(ind_tab).ID_CINEMA            :=	r.ID_CINEMA;
			  tab_temp(ind_tab).NOME_CINEMA          :=	r.NOME_CINEMA;
			  tab_temp(ind_tab).COMUNE_CINEMA				 :=	r.COMUNE_CINEMA;
			  tab_temp(ind_tab).PROVINCIA_CINEMA     :=	r.PROVINCIA_CINEMA;
			  tab_temp(ind_tab).REGIONE_CINEMA       :=	r.REGIONE_CINEMA;
				tab_temp(ind_tab).NOME_AMBIENTE        :=	r.NOME_AMBIENTE;
				tab_temp(ind_tab).DATA_EROGAZIONE      :=	r.DATA_EROGAZIONE;
				tab_temp(ind_tab).LUOGO                :=	r.LUOGO;
				tab_temp(ind_tab).FLG_ANNULLATO        :=	r.FLG_ANNULLATO;
    		tab_temp(ind_tab).ID_COMUNICATO				 :=  r.ID_COMUNICATO;
    		--
  			if ind_tab >0 then
  			--
  				IF tab_temp(ind_tab).ID_SOGGETTO_DI_PIANO = tab_temp(ind_tab-1).ID_SOGGETTO_DI_PIANO 	  AND
  				   tab_temp(ind_tab).COD_SOGG_DI_PIANO   	= tab_temp(ind_tab-1).COD_SOGG_DI_PIANO     	AND
  				   tab_temp(ind_tab).TITOLO_MAT						= tab_temp(ind_tab-1).TITOLO_MAT							AND
  				   tab_temp(ind_tab).ID_CINEMA            = tab_temp(ind_tab-1).ID_CINEMA               AND
  				   tab_temp(ind_tab).DATA_EROGAZIONE      = tab_temp(ind_tab-1).DATA_EROGAZIONE         AND
  				    tab_temp(ind_tab).NOME_AMBIENTE       = tab_temp(ind_tab-1).NOME_AMBIENTE             AND
  				   tab_temp(ind_tab).LUOGO                = tab_temp(ind_tab-1).LUOGO
  			  THEN    --> se siamo sullo stesso raggruppamento devo concatenare id_comunicato
  			  	 --
  			  	 STR_COMUNICATO := STR_COMUNICATO||'_'||tab_temp(ind_tab).ID_COMUNICATO;
  				ELSE   -- scrivo il record sulla tavola pipelined (rottura di record)
  					V_REC_COM_SOGG.ID_SOGGETTO_DI_PIANO 	:=   	tab_temp(ind_tab-1).ID_SOGGETTO_DI_PIANO;
  					V_REC_COM_SOGG.DESC_SOGG_DI_PIANO		  :=	  tab_temp(ind_tab-1).DESC_SOGG_DI_PIANO;
  					V_REC_COM_SOGG.COD_SOGG_DI_PIANO      :=		tab_temp(ind_tab-1).COD_SOGG_DI_PIANO;
  					V_REC_COM_SOGG.TITOLO_MAT             :=   	tab_temp(ind_tab-1).TITOLO_MAT;
  					V_REC_COM_SOGG.ID_STR_COMUNICATO      :=   	ltrim(STR_COMUNICATO,'_');
  					V_REC_COM_SOGG.ID_CINEMA              :=  	tab_temp(ind_tab-1).ID_CINEMA;
  					V_REC_COM_SOGG.NOME_CINEMA            :=   	tab_temp(ind_tab-1).NOME_CINEMA;
  					V_REC_COM_SOGG.COMUNE_CINEMA          :=   	tab_temp(ind_tab-1).COMUNE_CINEMA;
  					V_REC_COM_SOGG.PROVINCIA_CINEMA       :=   	tab_temp(ind_tab-1).PROVINCIA_CINEMA;
  					V_REC_COM_SOGG.REGIONE_CINEMA         :=   	tab_temp(ind_tab-1).REGIONE_CINEMA;
  					V_REC_COM_SOGG.NOME_AMBIENTE          :=   	tab_temp(ind_tab-1).NOME_AMBIENTE;
  					V_REC_COM_SOGG.DATA_EROGAZIONE        :=   	tab_temp(ind_tab-1).DATA_EROGAZIONE;
  					V_REC_COM_SOGG.LUOGO                  :=   	tab_temp(ind_tab-1).LUOGO;
  					V_REC_COM_SOGG.FLG_ANNULLATO          :=   	tab_temp(ind_tab-1).FLG_ANNULLATO;
  				  --
  				  pipe ROW(V_REC_COM_SOGG);
  				  STR_COMUNICATO := to_char(null);
  				  STR_COMUNICATO := STR_COMUNICATO||'_'||tab_temp(ind_tab).ID_COMUNICATO;

  				END IF;
  			else
  				STR_COMUNICATO := STR_COMUNICATO||'_'||tab_temp(ind_tab).ID_COMUNICATO;   -- inizializzo la stringas
  			end if;
  			--
  			--
  			ind_tab := ind_tab + 1;
  		END LOOP;
      -- SONO ARRIVATO ALL'ULTIMA OCCORRRENZA RIPORTO INDIENTRO L'INDICE
      --
      V_REC_COM_SOGG.ID_SOGGETTO_DI_PIANO 	:=   	tab_temp(ind_tab-1).ID_SOGGETTO_DI_PIANO;
			V_REC_COM_SOGG.DESC_SOGG_DI_PIANO		  :=	  tab_temp(ind_tab-1).DESC_SOGG_DI_PIANO;
			V_REC_COM_SOGG.COD_SOGG_DI_PIANO      :=		tab_temp(ind_tab-1).COD_SOGG_DI_PIANO;
			V_REC_COM_SOGG.TITOLO_MAT             :=   	tab_temp(ind_tab-1).TITOLO_MAT;
			V_REC_COM_SOGG.ID_STR_COMUNICATO      :=  	ltrim(STR_COMUNICATO,'_');
			V_REC_COM_SOGG.ID_CINEMA              :=   	tab_temp(ind_tab-1).ID_CINEMA;
			V_REC_COM_SOGG.NOME_CINEMA            :=   	tab_temp(ind_tab-1).NOME_CINEMA;
			V_REC_COM_SOGG.COMUNE_CINEMA          :=   	tab_temp(ind_tab-1).COMUNE_CINEMA;
			V_REC_COM_SOGG.PROVINCIA_CINEMA       :=   	tab_temp(ind_tab-1).PROVINCIA_CINEMA;
			V_REC_COM_SOGG.REGIONE_CINEMA         :=   	tab_temp(ind_tab-1).REGIONE_CINEMA;
			V_REC_COM_SOGG.NOME_AMBIENTE          :=   	tab_temp(ind_tab-1).NOME_AMBIENTE;
			V_REC_COM_SOGG.DATA_EROGAZIONE        :=   	tab_temp(ind_tab-1).DATA_EROGAZIONE;
			V_REC_COM_SOGG.LUOGO                  :=   	tab_temp(ind_tab-1).LUOGO;
			V_REC_COM_SOGG.FLG_ANNULLATO          :=   	tab_temp(ind_tab-1).FLG_ANNULLATO;
  				  --
  				  pipe ROW(V_REC_COM_SOGG);
   return;

	END FU_COMUN_PAOLO_SOGG;



end pa_cd_paolo;
/

