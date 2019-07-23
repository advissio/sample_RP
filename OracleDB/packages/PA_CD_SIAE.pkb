CREATE OR REPLACE PACKAGE BODY VENCD.PA_CD_SIAE AS
-- FUNZIONE FU_GET_PLAYLIST_XML
--
-- DESCRIZIONE:  restituisce la playlist per la generazione del corrispondente file xml

-- INPUT:
--       p_data_inizio
--       p_data_fine
-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE: 
-- Mauro Viel Altran Italia, Settembre 2011: Con il passaggio a Oracle 10g non e piu richiesto 
--                                          il nome del file  ma il nome logico  (Alias Directory) perche
--                                          non viene piu utilizzato il compilato java ma il pacchetto
--                                          SYS.UTL_FILE

--V_PATH_SIAE VARCHAR2(30):= '/svil270/cd/siae/';
--V_PATH_SIAE VARCHAR2(30):= '/prodK200/cd/siae/';
V_PATH_SIAE VARCHAR2(30):= 'XML_SIAE/';

PROCEDURE SET_XML_PATH(V_PATH VARCHAR2) IS
BEGIN
V_PATH_SIAE := V_PATH;
END;

FUNCTION FU_GET_PLAYLIST_XML(p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                             p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE) RETURN C_PLAYLIST IS
v_playlist C_PLAYLIST;
BEGIN
OPEN v_playlist FOR
    SELECT  com_sa.DATA_EROGAZIONE_PREV, com_sa.ID_SALA id_sala ,mat.ID_MATERIALE id_materiale--pro.DATA_proiezione,com_sa.id_sala, mat.ID_MATERIALE
    FROM    VI_CD_COMUNICATO_SALA com_sa , CD_MATERIALE_DI_PIANO mat_pia, CD_MATERIALE mat--, cd_schermo sch, cd_proiezione pro
    WHERE   com_sa.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
    AND     mat_pia.ID_MATERIALE_DI_PIANO = com_sa.ID_MATERIALE_DI_PIANO
    AND     mat_pia.ID_MATERIALE = mat.ID_MATERIALE--and  rownum <10
    GROUP BY com_sa.DATA_EROGAZIONE_PREV, com_sa.ID_SALA,mat.ID_MATERIALE
    --ORDER BY id_sala DESC;
    ORDER BY data_erogazione_prev, id_sala DESC, id_materiale;

    RETURN v_playlist;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_GET_PLAYLIST_XML;

-- FUNZIONE FU_GET_MATERIALI_XML
--
-- DESCRIZIONE:  restituisce i materiali per la generazione del corrispondente file xml

-- INPUT:
-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE:

FUNCTION FU_GET_MATERIALI_XML(p_data_inizio cd_comunicato.DATA_EROGAZIONE_PREV%TYPE,
                              p_data_fine cd_comunicato.DATA_EROGAZIONE_PREV%TYPE) RETURN C_MATERIALE IS
v_materiali C_MATERIALE;
BEGIN
OPEN v_materiali FOR
    select distinct mat.ID_MATERIALE, mat.TITOLO,
        mat.DURATA,cli.RAG_SOC_COGN,colonna.AUTORE,colonna.TITOLO as titolo_colonna,
        colonna.NOTA
    from cd_materiale mat,vi_cd_cliente cli,cd_colonna_sonora colonna,cd_comunicato com,cd_materiale_di_piano mat_pia
    where mat.id_cliente= cli.ID_CLIENTE
    and   mat.ID_COLONNA_SONORA =  colonna.ID_COLONNA_SONORA (+)
    and   com.ID_MATERIALE_DI_PIANO = mat_pia.ID_MATERIALE_DI_PIANO
    and   mat.ID_MATERIALE = mat_pia.ID_MATERIALE
    and   com.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine;

--    SELECT mat.ID_MATERIALE, mat.TITOLO,mat.DURATA, cli.RAG_SOC_COGN,colonna.AUTORE,
--        colonna.TITOLO as titolo_colonna,colonna.NOTA
--    FROM CD_MATERIALE mat,VI_CD_CLIENTE cli,CD_COLONNA_SONORA colonna
--    WHERE mat.ID_CLIENTE= cli.ID_CLIENTE
--    AND   mat.ID_COLONNA_SONORA =  colonna.ID_COLONNA_SONORA (+);

    RETURN v_materiali;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_GET_MATERIALI_XML;

-- FUNZIONE FU_GET_SALE_XML
--
-- DESCRIZIONE:  restituisce le sale per la generazione del corrispondente file xml

-- INPUT:
-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE:
FUNCTION FU_GET_SALE_XML RETURN C_SALA IS
v_sale C_SALA;
BEGIN
OPEN v_sale FOR
    SELECT A.ID_SALA   AS  ID_SALA, B.ID_CINEMA   AS  ID_CINEMA,
         B.NOME_CINEMA AS  NOME_CINEMA
    FROM CD_SALA A,CD_CINEMA B
    WHERE A.id_cinema=b.ID_CINEMA;

    RETURN v_sale;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_GET_SALE_XML;

-- FUNZIONE FU_GET_CINEMA_SALA_XML
--
-- DESCRIZIONE:  restituisce le informazioni per la generazione del file cinema_sala xml

-- INPUT:
-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE:
FUNCTION FU_GET_CINEMA_SALA_XML RETURN C_CINEMA_SALA IS
v_cinema_sala C_CINEMA_SALA;
BEGIN
OPEN v_cinema_sala FOR
    SELECT B.ID_CINEMA as id_cinema, D.COMUNE citta, B.INDIRIZZO,
        B.NOME_CINEMA, A.ID_SALA AS id_sala, A.NOME_SALA AS nome_sala
    FROM CD_SALA A, CD_CINEMA B, CD_COMUNE D
    WHERE A.ID_CINEMA=B.ID_CINEMA
    and   D.ID_COMUNE = b.ID_COMUNE;

    RETURN v_cinema_sala;
EXCEPTION
    WHEN OTHERS THEN
    RAISE;
END FU_GET_CINEMA_SALA_XML;

-- FUNZIONE PR_CREA_PLAYLIST_XML
--
-- DESCRIZIONE:  Crea il file XML della Playlist sulla directory XML_SIAE del server
--               utilizzando xmlDom
-- INPUT:
--       p_data_inizio
--       p_data_fine
-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE:

PROCEDURE PR_CREA_PLAYLIST_XML (p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                p_esito       IN OUT NUMBER) IS
v_id_sala cd_sala.ID_SALA%TYPE := null;
v_data VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE := null;

doc xmldom.DOMDocument;
main_node xmldom.DOMNode;
root_node xmldom.DOMNode;
row_node xmldom.DOMNode;
data_node xmldom.DOMNode;
data_item_node xmldom.DOMNode;
id_sala_node xmldom.DOMNode;
sala_item_node xmldom.DOMNode;
materiali_node xmldom.DOMNode;
id_materiale_node xmldom.DOMNode;
materiale_item_node xmldom.DOMNode;

root_elmt xmldom.DOMElement;
row_elmt xmldom.DOMElement;
data_elmt xmldom.DOMElement;
id_sala_elmt xmldom.DOMElement;
materiali_elmt xmldom.DOMElement;
id_materiale_elmt xmldom.DOMElement;

data_item_text xmldom.DOMText;
sala_item_text xmldom.DOMText;
materiale_item_text xmldom.DOMText;
v_data_found boolean := false;

BEGIN
    p_esito := 0;
    v_id_sala := null;
    v_data := null;
    FOR c IN
    (
        SELECT  com_sa.DATA_EROGAZIONE_PREV, com_sa.ID_SALA id_sala ,mat.ID_MATERIALE id_materiale--pro.DATA_proiezione,com_sa.id_sala, mat.ID_MATERIALE
        FROM    VI_CD_COMUNICATO_SALA com_sa , CD_MATERIALE_DI_PIANO mat_pia, CD_MATERIALE mat--, cd_schermo sch, cd_proiezione pro
        WHERE   com_sa.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
        AND     mat_pia.ID_MATERIALE_DI_PIANO = com_sa.ID_MATERIALE_DI_PIANO
        AND     mat_pia.ID_MATERIALE = mat.ID_MATERIALE--and  rownum <10
        GROUP BY com_sa.DATA_EROGAZIONE_PREV, com_sa.ID_SALA,mat.ID_MATERIALE
        ORDER BY data_erogazione_prev, id_sala DESC, id_materiale
    )
    LOOP

        v_data_found := true;
        IF (v_data is null OR v_data <> c.data_erogazione_prev) THEN
            IF (v_data is not null) THEN
                xmldom.writeToFile(doc, V_PATH_SIAE||'play_list_'||to_char(v_data,'DDMMYYYY')||'.xml', 'UTF-8');
                -- free resources
                xmldom.freeDocument(doc);
            END IF;
            -- get document
            doc := xmldom.newDOMDocument;
            xmldom.setVersion (doc, '1.0');
            xmldom.setCharset (doc, 'UTF-8');
            -- create root element
            main_node := xmldom.makeNode(doc);
            root_elmt := xmldom.createElement(doc, 'rowset');
            root_node := xmldom.appendChild(main_node, xmldom.makeNode(root_elmt));

        END IF;
        IF (v_id_sala is null OR v_id_sala <> c.id_sala) THEN

            row_elmt := xmldom.createElement(doc, 'row');
            row_node := xmldom.appendChild(root_node, xmldom.makeNode(row_elmt));

            data_elmt := xmldom.createElement(doc, 'data_proiezione');
            data_node := xmldom.appendChild(row_node, xmldom.makeNode(data_elmt));
            data_item_text := xmldom.createTextNode(doc, to_char(c.data_erogazione_prev,'DD/MM/YYYY'));
            data_item_node := xmldom.appendChild(data_node, xmldom.makeNode(data_item_text));

            id_sala_elmt := xmldom.createElement(doc, 'id_sala');
            id_sala_node := xmldom.appendChild(row_node, xmldom.makeNode(id_sala_elmt));
            sala_item_text := xmldom.createTextNode(doc, c.id_sala);
            sala_item_node := xmldom.appendChild(id_sala_node, xmldom.makeNode(sala_item_text));
            materiali_elmt := xmldom.createElement(doc, 'materiali');
            materiali_node := xmldom.appendChild(row_node, xmldom.makeNode(materiali_elmt));
        END IF;
        id_materiale_elmt := xmldom.createElement(doc, 'id_materiale');
        id_materiale_node := xmldom.appendChild(materiali_node, xmldom.makeNode(id_materiale_elmt));
        materiale_item_text := xmldom.createTextNode(doc, c.id_materiale);
        materiale_item_node := xmldom.appendChild(id_materiale_node, xmldom.makeNode(materiale_item_text));

        v_id_sala := c.id_sala;
        v_data := c.data_erogazione_prev;

    END LOOP;
    if(v_data_found) then
       xmldom.writeToFile(doc, V_PATH_SIAE||'play_list_'||to_char(v_data,'DDMMYYYY')||'.xml', 'UTF-8');
        -- free resources
        xmldom.freeDocument(doc);
        p_esito := 1;
    end if;

EXCEPTION
    WHEN xmldom.INDEX_SIZE_ERR THEN
      raise_application_error(-20120, 'Index Size error');
    WHEN xmldom.DOMSTRING_SIZE_ERR THEN
      raise_application_error(-20120, 'String Size error');
    WHEN xmldom.HIERARCHY_REQUEST_ERR THEN
      raise_application_error(-20120, 'Hierarchy request error');
    WHEN xmldom.WRONG_DOCUMENT_ERR THEN
      raise_application_error(-20120, 'Wrong doc error');
    WHEN xmldom.INVALID_CHARACTER_ERR THEN
      raise_application_error(-20120, 'Invalid Char error');
    WHEN xmldom.NO_DATA_ALLOWED_ERR THEN
      raise_application_error(-20120, 'Nod data allowed error');
    WHEN xmldom.NO_MODIFICATION_ALLOWED_ERR THEN
      raise_application_error(-20120, 'No mod allowed error');
    WHEN xmldom.NOT_FOUND_ERR THEN
      raise_application_error(-20120, 'Not found error');
    WHEN xmldom.NOT_SUPPORTED_ERR THEN
      raise_application_error(-20120, 'Not supported error');
    WHEN xmldom.INUSE_ATTRIBUTE_ERR THEN
    raise_application_error(-20120, 'In use attr error');

    WHEN OTHERS THEN
    p_esito:=-1;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PLAYLIST_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
END PR_CREA_PLAYLIST_XML;

-- FUNZIONE PR_CREA_MATERIALI_XML
--
-- DESCRIZIONE:  Crea il file XML dei materiali sulla directory XML_SIAE del server
--               utilizzando xmlDom
-- INPUT:
--       p_data_inizio
--       p_data_fine
-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE:

PROCEDURE PR_CREA_MATERIALI_XML (p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                 p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
                                 p_esito       IN OUT NUMBER) IS

--vFileHandler UTL_FILE.FILE_TYPE;
doc xmldom.DOMDocument;
main_node xmldom.DOMNode;
root_node xmldom.DOMNode;
row_node xmldom.DOMNode;
id_mat_node xmldom.DOMNode;
titolo_mat_node xmldom.DOMNode;
durata_mat_node xmldom.DOMNode;
cliente_node xmldom.DOMNode;
autore_node xmldom.DOMNode;
titolo_node xmldom.DOMNode;
nota_node xmldom.DOMNode;

id_mat_item_node xmldom.DOMNode;
titolo_mat_item_node xmldom.DOMNode;
durata_mat_item_node xmldom.DOMNode;
cliente_item_node xmldom.DOMNode;
autore_item_node xmldom.DOMNode;
titolo_item_node xmldom.DOMNode;
nota_item_node xmldom.DOMNode;

root_elmt xmldom.DOMElement;
row_elmt xmldom.DOMElement;
id_mat_elmt xmldom.DOMElement;
titolo_mat_elmt xmldom.DOMElement;
durata_mat_elmt xmldom.DOMElement;
cliente_elmt xmldom.DOMElement;
autore_elmt xmldom.DOMElement;
titolo_elmt xmldom.DOMElement;
nota_elmt xmldom.DOMElement;

id_mat_item_text xmldom.DOMText;
titolo_mat_item_text xmldom.DOMText;
durata_mat_item_text xmldom.DOMText;
cliente_item_text xmldom.DOMText;
autore_item_text xmldom.DOMText;
titolo_item_text xmldom.DOMText;
nota_item_text xmldom.DOMText;
v_data_found boolean := false;

BEGIN
    p_esito := 0;
    -- get document
    doc := xmldom.newDOMDocument;
    xmldom.setVersion (doc, '1.0');
    xmldom.setCharset (doc, 'UTF-8');

    -- create root element
    main_node := xmldom.makeNode(doc);
    root_elmt := xmldom.createElement(doc, 'rowset');
    root_node := xmldom.appendChild(main_node, xmldom.makeNode(root_elmt));

    FOR c IN
    (
        select distinct mat.ID_MATERIALE, mat.TITOLO,
            mat.DURATA,cli.RAG_SOC_COGN,colonna.AUTORE,colonna.TITOLO as titolo_colonna,
            colonna.NOTA
        from cd_materiale mat,vi_cd_cliente cli,cd_colonna_sonora colonna,cd_comunicato com,cd_materiale_di_piano mat_pia
        where mat.id_cliente= cli.ID_CLIENTE
        and   mat.ID_COLONNA_SONORA =  colonna.ID_COLONNA_SONORA (+)
        and   com.ID_MATERIALE_DI_PIANO = mat_pia.ID_MATERIALE_DI_PIANO
        and   mat.ID_MATERIALE = mat_pia.ID_MATERIALE
        and   com.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
    )
    LOOP
        v_data_found := true;
        row_elmt := xmldom.createElement(doc, 'row');
        row_node := xmldom.appendChild(root_node, xmldom.makeNode(row_elmt));

        id_mat_elmt := xmldom.createElement(doc, 'id_materiale');
        id_mat_node := xmldom.appendChild(row_node, xmldom.makeNode(id_mat_elmt));
        id_mat_item_text := xmldom.createTextNode(doc, c.id_materiale);
        id_mat_item_node := xmldom.appendChild(id_mat_node, xmldom.makeNode(id_mat_item_text));

        titolo_mat_elmt := xmldom.createElement(doc, 'titolo_materiale');
        titolo_mat_node := xmldom.appendChild(row_node, xmldom.makeNode(titolo_mat_elmt));
        titolo_mat_item_text := xmldom.createTextNode(doc, c.titolo);
        titolo_mat_item_node := xmldom.appendChild(titolo_mat_node, xmldom.makeNode(titolo_mat_item_text));

        durata_mat_elmt := xmldom.createElement(doc, 'durata_materiale');
        durata_mat_node := xmldom.appendChild(row_node, xmldom.makeNode(durata_mat_elmt));
        durata_mat_item_text := xmldom.createTextNode(doc, c.durata);
        durata_mat_item_node := xmldom.appendChild(durata_mat_node, xmldom.makeNode(durata_mat_item_text));

        cliente_elmt := xmldom.createElement(doc, 'descrizione_cliente');
        cliente_node := xmldom.appendChild(row_node, xmldom.makeNode(cliente_elmt));
        cliente_item_text := xmldom.createTextNode(doc, c.rag_soc_cogn);
        cliente_item_node := xmldom.appendChild(cliente_node, xmldom.makeNode(cliente_item_text));

        autore_elmt := xmldom.createElement(doc, 'autore_brano');
        autore_node := xmldom.appendChild(row_node, xmldom.makeNode(autore_elmt));
        autore_item_text := xmldom.createTextNode(doc, c.autore);
        autore_item_node := xmldom.appendChild(autore_node, xmldom.makeNode(autore_item_text));

        titolo_elmt := xmldom.createElement(doc, 'titolo_brano');
        titolo_node := xmldom.appendChild(row_node, xmldom.makeNode(titolo_elmt));
        titolo_item_text := xmldom.createTextNode(doc, c.titolo_colonna);
        titolo_item_node := xmldom.appendChild(titolo_node, xmldom.makeNode(titolo_item_text));

        nota_elmt := xmldom.createElement(doc, 'nota_brano');
        nota_node := xmldom.appendChild(row_node, xmldom.makeNode(nota_elmt));
        nota_item_text := xmldom.createTextNode(doc, c.nota);
        nota_item_node := xmldom.appendChild(nota_node, xmldom.makeNode(nota_item_text));

    END LOOP;
    if(v_data_found) then
        xmldom.writeToFile(doc, V_PATH_SIAE||'anagrafica_materiali_'||to_char(p_data_inizio,'DDMMYYYY')||'_'||to_char(p_data_fine,'DDMMYYYY')||'.xml', 'UTF-8');
        -- free resources
        xmldom.freeDocument(doc);
        p_esito := 1;
    end if;

EXCEPTION
    WHEN xmldom.INDEX_SIZE_ERR THEN
      raise_application_error(-20120, 'Index Size error');
    WHEN xmldom.DOMSTRING_SIZE_ERR THEN
      raise_application_error(-20120, 'String Size error');
    WHEN xmldom.HIERARCHY_REQUEST_ERR THEN
      raise_application_error(-20120, 'Hierarchy request error');
    WHEN xmldom.WRONG_DOCUMENT_ERR THEN
      raise_application_error(-20120, 'Wrong doc error');
    WHEN xmldom.INVALID_CHARACTER_ERR THEN
      raise_application_error(-20120, 'Invalid Char error');
    WHEN xmldom.NO_DATA_ALLOWED_ERR THEN
      raise_application_error(-20120, 'Nod data allowed error');
    WHEN xmldom.NO_MODIFICATION_ALLOWED_ERR THEN
      raise_application_error(-20120, 'No mod allowed error');
    WHEN xmldom.NOT_FOUND_ERR THEN
      raise_application_error(-20120, 'Not found error');
    WHEN xmldom.NOT_SUPPORTED_ERR THEN
      raise_application_error(-20120, 'Not supported error');
    WHEN xmldom.INUSE_ATTRIBUTE_ERR THEN
      raise_application_error(-20120, 'In use attr error');
    WHEN OTHERS THEN
    p_esito:=-1;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_MATERIALI_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
END PR_CREA_MATERIALI_XML;

-- FUNZIONE PR_CREA_PLAYLIST_XML
--
-- DESCRIZIONE:  Crea il file XML delle sale sulla directory XML_SIAE del server
--               utilizzando xmlDom
-- INPUT:

-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE:

PROCEDURE PR_CREA_SALE_XML (p_esito IN OUT NUMBER) IS

doc xmldom.DOMDocument;
main_node xmldom.DOMNode;
root_node xmldom.DOMNode;
row_node xmldom.DOMNode;
id_sala_node xmldom.DOMNode;
id_cinema_node xmldom.DOMNode;
nome_sala_node xmldom.DOMNode;

id_sala_item_node xmldom.DOMNode;
id_cinema_item_node xmldom.DOMNode;
nome_sala_item_node xmldom.DOMNode;

root_elmt xmldom.DOMElement;
row_elmt xmldom.DOMElement;
id_sala_elmt xmldom.DOMElement;
id_cinema_elmt xmldom.DOMElement;
nome_sala_elmt xmldom.DOMElement;

id_sala_item_text xmldom.DOMText;
id_cinema_item_text xmldom.DOMText;
nome_sala_item_text xmldom.DOMText;
v_data_found boolean := false;

BEGIN
    p_esito := 0;
    -- get document
    doc := xmldom.newDOMDocument;
    xmldom.setVersion (doc, '1.0');
    xmldom.setCharset (doc, 'UTF-8');

    -- create root element
    main_node := xmldom.makeNode(doc);
    root_elmt := xmldom.createElement(doc, 'rowset');
    root_node := xmldom.appendChild(main_node, xmldom.makeNode(root_elmt));

    FOR c IN
    (
        SELECT A.ID_SALA   AS  ID_SALA, A.NOME_SALA AS NOME_SALA, B.ID_CINEMA   AS  ID_CINEMA
        FROM CD_SALA A,CD_CINEMA B
        WHERE A.id_cinema=b.ID_CINEMA
    )
    LOOP
        v_data_found := true;
        row_elmt := xmldom.createElement(doc, 'row');
        row_node := xmldom.appendChild(root_node, xmldom.makeNode(row_elmt));

        id_sala_elmt := xmldom.createElement(doc, 'id_sala');
        id_sala_node := xmldom.appendChild(row_node, xmldom.makeNode(id_sala_elmt));
        id_sala_item_text := xmldom.createTextNode(doc, c.id_sala);
        id_sala_item_node := xmldom.appendChild(id_sala_node, xmldom.makeNode(id_sala_item_text));

        id_cinema_elmt := xmldom.createElement(doc, 'id_cinema');
        id_cinema_node := xmldom.appendChild(row_node, xmldom.makeNode(id_cinema_elmt));
        id_cinema_item_text := xmldom.createTextNode(doc, c.id_cinema);
        id_cinema_item_node := xmldom.appendChild(id_cinema_node, xmldom.makeNode(id_cinema_item_text));

        nome_sala_elmt := xmldom.createElement(doc, 'nome_sala');
        nome_sala_node := xmldom.appendChild(row_node, xmldom.makeNode(nome_sala_elmt));
        nome_sala_item_text := xmldom.createTextNode(doc, c.nome_sala);
        nome_sala_item_node := xmldom.appendChild(nome_sala_node, xmldom.makeNode(nome_sala_item_text));

    END LOOP;
    if(v_data_found) then
        xmldom.writeToFile(doc, V_PATH_SIAE||'anagrafica_sale_'||to_char(sysdate,'DDMMYYYY')||'.xml', 'UTF-8');
        -- free resources
        xmldom.freeDocument(doc);
        p_esito := 1;
    end if;

EXCEPTION
    WHEN xmldom.INDEX_SIZE_ERR THEN
      raise_application_error(-20120, 'Index Size error');
    WHEN xmldom.DOMSTRING_SIZE_ERR THEN
      raise_application_error(-20120, 'String Size error');
    WHEN xmldom.HIERARCHY_REQUEST_ERR THEN
      raise_application_error(-20120, 'Hierarchy request error');
    WHEN xmldom.WRONG_DOCUMENT_ERR THEN
      raise_application_error(-20120, 'Wrong doc error');
    WHEN xmldom.INVALID_CHARACTER_ERR THEN
      raise_application_error(-20120, 'Invalid Char error');
    WHEN xmldom.NO_DATA_ALLOWED_ERR THEN
      raise_application_error(-20120, 'Nod data allowed error');
    WHEN xmldom.NO_MODIFICATION_ALLOWED_ERR THEN
      raise_application_error(-20120, 'No mod allowed error');
    WHEN xmldom.NOT_FOUND_ERR THEN
      raise_application_error(-20120, 'Not found error');
    WHEN xmldom.NOT_SUPPORTED_ERR THEN
      raise_application_error(-20120, 'Not supported error');
    WHEN xmldom.INUSE_ATTRIBUTE_ERR THEN
      raise_application_error(-20120, 'In use attr error');
    WHEN OTHERS THEN
    p_esito:=-1;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_SALE_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
END PR_CREA_SALE_XML;

-- FUNZIONE PR_CREA_PLAYLIST_XML
--
-- DESCRIZIONE:  Crea il file XML dell'anagrafica cinema-sala sulla directory XML_SIAE del server
--               utilizzando xmlDom
-- INPUT:
--       p_data_inizio
--       p_data_fine
-- OUTPUT:
--
-- REALIZZATORE: Michele Borgogno, Altran, Febbraio 2010
--
--  MODIFICHE:

PROCEDURE PR_CREA_CINEMA_SALA_XML (p_esito  IN OUT NUMBER) IS

doc xmldom.DOMDocument;
main_node xmldom.DOMNode;
root_node xmldom.DOMNode;
row_node xmldom.DOMNode;
id_cinema_node xmldom.DOMNode;
nome_cinema_node xmldom.DOMNode;
nome_sala_node xmldom.DOMNode;
indirizzo_node xmldom.DOMNode;
citta_node xmldom.DOMNode;

id_cinema_item_node xmldom.DOMNode;
nome_cinema_item_node xmldom.DOMNode;
nome_sala_item_node xmldom.DOMNode;
indirizzo_item_node xmldom.DOMNode;
citta_item_node xmldom.DOMNode;

root_elmt xmldom.DOMElement;
row_elmt xmldom.DOMElement;
id_cinema_elmt xmldom.DOMElement;
nome_cinema_elmt xmldom.DOMElement;
nome_sala_elmt xmldom.DOMElement;
indirizzo_elmt xmldom.DOMElement;
citta_elmt xmldom.DOMElement;

id_cinema_item_text xmldom.DOMText;
nome_cinema_item_text xmldom.DOMText;
nome_sala_item_text xmldom.DOMText;
indirizzo_item_text xmldom.DOMText;
citta_item_text xmldom.DOMText;
v_data_found boolean := false;

BEGIN
    p_esito := 0;
    -- get document
    doc := xmldom.newDOMDocument;
    xmldom.setVersion (doc, '1.0');
    xmldom.setCharset (doc, 'UTF-8');

    -- create root element
    main_node := xmldom.makeNode(doc);
    root_elmt := xmldom.createElement(doc, 'rowset');
    root_node := xmldom.appendChild(main_node, xmldom.makeNode(root_elmt));

    FOR c IN
    (
        SELECT B.ID_CINEMA as id_cinema, D.COMUNE citta, B.INDIRIZZO,
            B.NOME_CINEMA
        FROM CD_CINEMA B, CD_COMUNE D
        WHERE D.ID_COMUNE = b.ID_COMUNE
    )
    LOOP
        v_data_found := true;
        row_elmt := xmldom.createElement(doc, 'row');
        row_node := xmldom.appendChild(root_node, xmldom.makeNode(row_elmt));

        id_cinema_elmt := xmldom.createElement(doc, 'id_cinema');
        id_cinema_node := xmldom.appendChild(row_node, xmldom.makeNode(id_cinema_elmt));
        id_cinema_item_text := xmldom.createTextNode(doc, c.id_cinema);
        id_cinema_item_node := xmldom.appendChild(id_cinema_node, xmldom.makeNode(id_cinema_item_text));

        nome_cinema_elmt := xmldom.createElement(doc, 'nome_cinema');
        nome_cinema_node := xmldom.appendChild(row_node, xmldom.makeNode(nome_cinema_elmt));
        nome_cinema_item_text := xmldom.createTextNode(doc, c.nome_cinema);
        nome_cinema_item_node := xmldom.appendChild(nome_cinema_node, xmldom.makeNode(nome_cinema_item_text));

--        nome_sala_elmt := xmldom.createElement(doc, 'nome_sala');
--        nome_sala_node := xmldom.appendChild(row_node, xmldom.makeNode(nome_sala_elmt));
--        nome_sala_item_text := xmldom.createTextNode(doc, c.nome_sala);
--        nome_sala_item_node := xmldom.appendChild(nome_sala_node, xmldom.makeNode(nome_sala_item_text));

        indirizzo_elmt := xmldom.createElement(doc, 'indirizzo');
        indirizzo_node := xmldom.appendChild(row_node, xmldom.makeNode(indirizzo_elmt));
        indirizzo_item_text := xmldom.createTextNode(doc, c.indirizzo);
        indirizzo_item_node := xmldom.appendChild(indirizzo_node, xmldom.makeNode(indirizzo_item_text));

        citta_elmt := xmldom.createElement(doc, 'citta');
        citta_node := xmldom.appendChild(row_node, xmldom.makeNode(citta_elmt));
        citta_item_text := xmldom.createTextNode(doc, c.citta);
        citta_item_node := xmldom.appendChild(citta_node, xmldom.makeNode(citta_item_text));

    END LOOP;
    if(v_data_found) then
        xmldom.writeToFile(doc, V_PATH_SIAE||'anagrafica_cinema_'||to_char(sysdate,'DDMMYYYY')||'.xml', 'UTF-8');
        -- free resources
        xmldom.freeDocument(doc);
        p_esito := 1;
    end if;


EXCEPTION
    WHEN xmldom.INDEX_SIZE_ERR THEN
      raise_application_error(-20120, 'Index Size error');
    WHEN xmldom.DOMSTRING_SIZE_ERR THEN
      raise_application_error(-20120, 'String Size error');
    WHEN xmldom.HIERARCHY_REQUEST_ERR THEN
      raise_application_error(-20120, 'Hierarchy request error');
    WHEN xmldom.WRONG_DOCUMENT_ERR THEN
      raise_application_error(-20120, 'Wrong doc error');
    WHEN xmldom.INVALID_CHARACTER_ERR THEN
      raise_application_error(-20120, 'Invalid Char error');
    WHEN xmldom.NO_DATA_ALLOWED_ERR THEN
      raise_application_error(-20120, 'Nod data allowed error');
    WHEN xmldom.NO_MODIFICATION_ALLOWED_ERR THEN
      raise_application_error(-20120, 'No mod allowed error');
    WHEN xmldom.NOT_FOUND_ERR THEN
      raise_application_error(-20120, 'Not found error');
    WHEN xmldom.NOT_SUPPORTED_ERR THEN
      raise_application_error(-20120, 'Not supported error');
    WHEN xmldom.INUSE_ATTRIBUTE_ERR THEN
      raise_application_error(-20120, 'In use attr error');
    WHEN OTHERS THEN
    p_esito:=-1;
    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_CINEMA_SALA_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
END PR_CREA_CINEMA_SALA_XML;

--PROCEDURE PR_CREA_PLAYLIST_XML (p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
--                                p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
--                                p_esito       IN OUT NUMBER) IS
--vFileHandler UTL_FILE.FILE_TYPE;
--v_id_sala cd_sala.ID_SALA%TYPE := null;
--v_data VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE := null;

--BEGIN
--    p_esito := 0;
--    v_id_sala := null;
--    v_data := null;
--    FOR c IN
--    (
--        SELECT  com_sa.DATA_EROGAZIONE_PREV, com_sa.ID_SALA id_sala ,mat.ID_MATERIALE id_materiale--pro.DATA_proiezione,com_sa.id_sala, mat.ID_MATERIALE
--        FROM    VI_CD_COMUNICATO_SALA com_sa , CD_MATERIALE_DI_PIANO mat_pia, CD_MATERIALE mat--, cd_schermo sch, cd_proiezione pro
--        WHERE   com_sa.DATA_EROGAZIONE_PREV BETWEEN p_data_inizio AND p_data_fine
--        AND     mat_pia.ID_MATERIALE_DI_PIANO = com_sa.ID_MATERIALE_DI_PIANO
--        AND     mat_pia.ID_MATERIALE = mat.ID_MATERIALE--and  rownum <10
--        GROUP BY com_sa.DATA_EROGAZIONE_PREV, com_sa.ID_SALA,mat.ID_MATERIALE
--        ORDER BY data_erogazione_prev, id_sala DESC, id_materiale
--    )
--    LOOP
--
--        IF (v_data is null) THEN
--            vFileHandler := UTL_FILE.FOPEN('XML_SIAE', 'play_list'||to_char(c.data_erogazione_prev,'DDMMYYYY')||'.xml', 'a');
--            UTL_FILE.PUT_LINE(vFileHandler, '<?xml version="1.0"?>');
--            UTL_FILE.PUT_LINE(vFileHandler, '<ROWSET>');
--            dbms_output.PUT_LINE('<?xml version="1.0"?>');
--            dbms_output.PUT_LINE('<ROWSET>');
--        END IF;
--        IF (v_data is not null AND v_data <> c.data_erogazione_prev) THEN
--            UTL_FILE.PUT_LINE(vFileHandler, '</MATERIALI>');
--            UTL_FILE.PUT_LINE(vFileHandler, '</ROW>');
--            UTL_FILE.PUT_LINE(vFileHandler, '</ROWSET>');
--            dbms_output.PUT_LINE('</MATERIALI>');
--            dbms_output.PUT_LINE('</ROW>');
--            dbms_output.PUT_LINE('</ROWSET>');
--            UTL_FILE.FCLOSE(vFileHandler);
--            vFileHandler := UTL_FILE.FOPEN('XML_SIAE', 'play_list'||to_char(c.data_erogazione_prev,'DDMMYYYY')||'.xml', 'a');
--            UTL_FILE.PUT_LINE(vFileHandler, '<?xml version="1.0"?>');
--            UTL_FILE.PUT_LINE(vFileHandler, '<ROWSET>');
--            dbms_output.PUT_LINE('<?xml version="1.0"?>');
--            dbms_output.PUT_LINE('<ROWSET>');
--            v_id_sala := null;
--        END IF;
--        IF (v_id_sala is null OR v_id_sala <> c.id_sala) THEN
--            IF (v_id_sala is not null AND v_id_sala <> c.id_sala) THEN
--                UTL_FILE.PUT_LINE(vFileHandler, '</MATERIALI>');
--                UTL_FILE.PUT_LINE(vFileHandler, '</ROW>');
--                dbms_output.PUT_LINE('</MATERIALI>');
--                dbms_output.PUT_LINE('</ROW>');
--            END IF;
--            UTL_FILE.PUT_LINE(vFileHandler, '<ROW>');
--            UTL_FILE.PUT_LINE(vFileHandler, '<DATA_PROIEZIONE>');
--            dbms_output.PUT_LINE('<ROW>');
--            dbms_output.PUT_LINE('<DATA_PROIEZIONE>');
--                UTL_FILE.PUT_LINE(vFileHandler, to_char(c.data_erogazione_prev,'DDMMYYYY'));
--                dbms_output.PUT_LINE(c.data_erogazione_prev);
--            UTL_FILE.PUT_LINE(vFileHandler, '</DATA_PROIEZIONE>');
--            UTL_FILE.PUT_LINE(vFileHandler, '<ID_SALA>');
--            dbms_output.PUT_LINE('</DATA_PROIEZIONE>');
--            dbms_output.PUT_LINE('<ID_SALA>');
--                UTL_FILE.PUT_LINE(vFileHandler, nvl(c.id_sala, ''));
--                dbms_output.PUT_LINE(c.id_sala);
--            UTL_FILE.PUT_LINE(vFileHandler, '</ID_SALA>');
--            UTL_FILE.PUT_LINE(vFileHandler, '<MATERIALI>');
--            dbms_output.PUT_LINE('</ID_SALA>');
--            dbms_output.PUT_LINE('<MATERIALI>');
--        END IF;
--        UTL_FILE.PUT_LINE(vFileHandler, '<ID_MATERIALE>');
--        dbms_output.PUT_LINE('<ID_MATERIALE>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.id_materiale, ''));
--            dbms_output.PUT_LINE(c.id_materiale);
--        UTL_FILE.PUT_LINE(vFileHandler, '</ID_MATERIALE>');
--        dbms_output.PUT_LINE('</ID_MATERIALE>');
--
--        v_id_sala := c.id_sala;
--        v_data := c.data_erogazione_prev;

--    END LOOP;
--    UTL_FILE.PUT_LINE(vFileHandler, '</MATERIALI>');
--    UTL_FILE.PUT_LINE(vFileHandler, '</ROW>');
--    UTL_FILE.PUT_LINE(vFileHandler, '</ROWSET>');
--    dbms_output.PUT_LINE('</MATERIALI>');
--    dbms_output.PUT_LINE('</ROW>');
--    dbms_output.PUT_LINE('</ROWSET>');
--    UTL_FILE.FCLOSE(vFileHandler);

--EXCEPTION
--      WHEN OTHERS THEN
--    p_esito:=-1;
--    UTL_FILE.FCLOSE(vFileHandler);
--    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_PLAYLIST_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
--END PR_CREA_PLAYLIST_XML;

--PROCEDURE PR_CREA_MATERIALI_XML (p_data_inizio VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
--                                 p_data_fine   VI_CD_COMUNICATO_SALA.DATA_EROGAZIONE_PREV%TYPE,
--                                 p_esito       IN OUT NUMBER) IS
--
--vFileHandler UTL_FILE.FILE_TYPE;
--BEGIN
--    p_esito := 0;
--    vFileHandler := UTL_FILE.FOPEN('XML_SIAE', 'anagrafica_materiali.xml', 'a');
--    UTL_FILE.PUT_LINE(vFileHandler, '<?xml version="1.0"?>');
--    UTL_FILE.PUT_LINE(vFileHandler, '<ROWSET>');
----    dbms_output.PUT_LINE('<?xml version="1.0"?>');
----    dbms_output.PUT_LINE('<ROWSET>');
--    FOR c IN
--    (
--        select distinct mat.ID_MATERIALE, mat.TITOLO,
--            mat.DURATA,cli.RAG_SOC_COGN,colonna.AUTORE,colonna.TITOLO as titolo_colonna,
--            colonna.NOTA
--        from cd_materiale mat,vi_cd_cliente cli,cd_colonna_sonora colonna,cd_comunicato com,cd_materiale_di_piano mat_pia
--        where mat.id_cliente= cli.ID_CLIENTE
--        and   mat.ID_COLONNA_SONORA =  colonna.ID_COLONNA_SONORA (+)
--        and   com.ID_MATERIALE_DI_PIANO = mat_pia.ID_MATERIALE_DI_PIANO
--        and   mat.ID_MATERIALE = mat_pia.ID_MATERIALE
--        and   com.DATA_EROGAZIONE_PREV between p_data_inizio and p_data_fine
--    )
--    LOOP
--        UTL_FILE.PUT_LINE(vFileHandler, '<ROW>');
--        UTL_FILE.PUT_LINE(vFileHandler, '<ID_MATERIALE>');
--        dbms_output.PUT_LINE('<ROW>');
--        dbms_output.PUT_LINE('<ID_MATERIALE>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.id_materiale,''));
--            dbms_output.PUT_LINE(c.id_materiale);
--        UTL_FILE.PUT_LINE(vFileHandler, '</ID_MATERIALE>');
--        UTL_FILE.PUT_LINE(vFileHandler, '<TITOLO_MATERIALE>');
--        dbms_output.PUT_LINE('</ID_MATERIALE>');
--        dbms_output.PUT_LINE('<TITOLO_MATERIALE>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.titolo, ''));
--            dbms_output.PUT_LINE(c.titolo);
--        UTL_FILE.PUT_LINE(vFileHandler, '</TITOLO_MATERIALE>');
--        UTL_FILE.PUT_LINE(vFileHandler, '<DURATA_MATERIALE>');
--        dbms_output.PUT_LINE('</TITOLO_MATERIALE>');
--        dbms_output.PUT_LINE('<DURATA_MATERIALE>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.durata, ''));
--            dbms_output.PUT_LINE(c.durata);
--        UTL_FILE.PUT_LINE(vFileHandler, '</DURATA_MATERIALE>');
--        UTL_FILE.PUT_LINE(vFileHandler, '<DESCRIZIONE_CLIENTE>');
--        dbms_output.PUT_LINE('</DURATA_MATERIALE>');
--        dbms_output.PUT_LINE('<DESCRIZIONE_CLIENTE>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.rag_soc_cogn,''));
--            dbms_output.PUT_LINE(c.rag_soc_cogn);
--        UTL_FILE.PUT_LINE(vFileHandler, '</DESCRIZIONE_CLIENTE>');
--        UTL_FILE.PUT_LINE(vFileHandler, '<AUTORE_BRANO>');
--        dbms_output.PUT_LINE('</DESCRIZIONE_CLIENTE>');
--        dbms_output.PUT_LINE('<AUTORE_BRANO>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.autore,''));
--            dbms_output.PUT_LINE(c.autore);
--        UTL_FILE.PUT_LINE(vFileHandler, '</AUTORE_BRANO>');
--        UTL_FILE.PUT_LINE(vFileHandler, '<TITOLO_BRANO>');
--        dbms_output.PUT_LINE('</AUTORE_BRANO>');
--        dbms_output.PUT_LINE('<TITOLO_BRANO>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.titolo_colonna,''));
--            dbms_output.PUT_LINE(c.titolo_colonna);
--        UTL_FILE.PUT_LINE(vFileHandler, '</TITOLO_BRANO>');
--        UTL_FILE.PUT_LINE(vFileHandler, '<NOTA_BRANO>');
--        dbms_output.PUT_LINE('</TITOLO_BRANO>');
--        dbms_output.PUT_LINE('<NOTA_BRANO>');
--            UTL_FILE.PUT_LINE(vFileHandler, nvl(c.nota,''));
--            dbms_output.PUT_LINE(c.titolo_colonna);
--        UTL_FILE.PUT_LINE(vFileHandler, '</NOTA_BRANO>');
--        UTL_FILE.PUT_LINE(vFileHandler, '</ROW>');
--        dbms_output.PUT_LINE('</NOTA_BRANO>');
--        dbms_output.PUT_LINE('</ROW>');
--    END LOOP;
--    UTL_FILE.PUT_LINE(vFileHandler, '</ROWSET>');
----    dbms_output.PUT_LINE('</ROWSET>');
--    UTL_FILE.FCLOSE(vFileHandler);

--EXCEPTION
--    WHEN OTHERS THEN
--    p_esito:=-1;
--    UTL_FILE.FCLOSE(vFileHandler);
--    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_MATERIALI_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
--END PR_CREA_MATERIALI_XML;

--PROCEDURE PR_CREA_SALE_XML (p_esito    IN OUT NUMBER) IS
--
--vFileHandler UTL_FILE.FILE_TYPE;
--BEGIN
--    p_esito := 0;

----    vFileHandler := UTL_FILE.FOPEN('XML_SIAE', 'anagrafica_materiali.xml', 'a');
----    UTL_FILE.PUT_LINE(vFileHandler, '<?xml version="1.0"?>');
----    UTL_FILE.PUT_LINE(vFileHandler, '<ROWSET>');
--    dbms_output.PUT_LINE('<?xml version="1.0"?>');
--    dbms_output.PUT_LINE('<ROWSET>');
--    FOR c IN
--    (
--        SELECT A.ID_SALA   AS  ID_SALA, B.ID_CINEMA   AS  ID_CINEMA,
--             B.NOME_CINEMA AS  NOME_CINEMA
--        FROM CD_SALA A,CD_CINEMA B
--        WHERE A.id_cinema=b.ID_CINEMA
--    )
--    LOOP
----        UTL_FILE.PUT_LINE(vFileHandler, '<ROW>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<ID_SALA>');
--        dbms_output.PUT_LINE('<ROW>');
--        dbms_output.PUT_LINE('<ID_SALA>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.id_sala);
--            dbms_output.PUT_LINE(c.id_sala);
----        UTL_FILE.PUT_LINE(vFileHandler, '</ID_SALA>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<ID_CINEMA>');
--        dbms_output.PUT_LINE('</ID_SALA>');
--        dbms_output.PUT_LINE('<ID_CINEMA>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.id_cinema);
--            dbms_output.PUT_LINE(c.id_cinema);
----        UTL_FILE.PUT_LINE(vFileHandler, '</ID_CINEMA>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<NOME_CINEMA>');
--        dbms_output.PUT_LINE('</ID_CINEMA>');
--        dbms_output.PUT_LINE('<NOME_CINEMA>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.nome_cinema);
--            dbms_output.PUT_LINE(c.nome_cinema);
----        UTL_FILE.PUT_LINE(vFileHandler, '</NOME_CINEMA>');
--        dbms_output.PUT_LINE('</NOME_CINEMA>');
--        dbms_output.PUT_LINE('</ROW>');
--    END LOOP;
----    UTL_FILE.PUT_LINE(vFileHandler, '</ROWSET>');;
--    dbms_output.PUT_LINE('</ROWSET>');
----    UTL_FILE.FCLOSE(vFileHandler);

--EXCEPTION
--    WHEN OTHERS THEN
--    p_esito:=-1;
----    UTL_FILE.FCLOSE(vFileHandler);
--    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_SALE_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
--END PR_CREA_SALE_XML;

--PROCEDURE PR_CREA_CINEMA_SALA_XML (p_esito    IN OUT NUMBER) IS
--
--vFileHandler UTL_FILE.FILE_TYPE;
--BEGIN
--    p_esito := 0;

----    vFileHandler := UTL_FILE.FOPEN('XML_SIAE', 'anagrafica_materiali.xml', 'a');
----    UTL_FILE.PUT_LINE(vFileHandler, '<?xml version="1.0"?>');
----    UTL_FILE.PUT_LINE(vFileHandler, '<ROWSET>');
--    dbms_output.PUT_LINE('<?xml version="1.0"?>');
--    dbms_output.PUT_LINE('<ROWSET>');
--    FOR c IN
--    (
--        SELECT B.ID_CINEMA as id_cinema, D.COMUNE citta, B.INDIRIZZO,
--            B.NOME_CINEMA, A.ID_SALA AS id_sala, A.NOME_SALA AS nome_sala
--        FROM CD_SALA A, CD_CINEMA B, CD_COMUNE D
--        WHERE A.ID_CINEMA=B.ID_CINEMA
--        and   D.ID_COMUNE = b.ID_COMUNE
--    )
--    LOOP
----        UTL_FILE.PUT_LINE(vFileHandler, '<ROW>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<ID_SALA>');
--        dbms_output.PUT_LINE('<ROW>');
--        dbms_output.PUT_LINE('<ID_SALA>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.id_sala);
--            dbms_output.PUT_LINE(c.id_sala);
----        UTL_FILE.PUT_LINE(vFileHandler, '</ID_SALA>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<NOME_CINEMA>');
--        dbms_output.PUT_LINE('</ID_SALA>');
--        dbms_output.PUT_LINE('<NOME_CINEMA>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.nome_cinema);
--            dbms_output.PUT_LINE(c.nome_cinema);
----        UTL_FILE.PUT_LINE(vFileHandler, '</NOME_CINEMA>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<NOME_SALA>');
--        dbms_output.PUT_LINE('</NOME_CINEMA>');
--        dbms_output.PUT_LINE('<NOME_SALA>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.nome_sala);
--            dbms_output.PUT_LINE(c.nome_sala);
----        UTL_FILE.PUT_LINE(vFileHandler, '</NOME_SALA>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<INDIRIZZO>');
--        dbms_output.PUT_LINE('</NOME_SALA>');
--        dbms_output.PUT_LINE('<INDIRIZZO>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.indirizzo);
--            dbms_output.PUT_LINE(c.indirizzo);
----        UTL_FILE.PUT_LINE(vFileHandler, '</INDIRIZZO>');
----        UTL_FILE.PUT_LINE(vFileHandler, '<CITTA>');
--        dbms_output.PUT_LINE('</INDIRIZZO>');
--        dbms_output.PUT_LINE('<CITTA>');
----            UTL_FILE.PUT_LINE(vFileHandler, c.citta);
--            dbms_output.PUT_LINE(c.citta);
----        UTL_FILE.PUT_LINE(vFileHandler, '</CITTA>');
----        UTL_FILE.PUT_LINE(vFileHandler, '</ROW>');
--        dbms_output.PUT_LINE('</CITTA>');
--        dbms_output.PUT_LINE('</ROW>');
--    END LOOP;
----    UTL_FILE.PUT_LINE(vFileHandler, '</ROWSET>');;
--    dbms_output.PUT_LINE('</ROWSET>');
----    UTL_FILE.FCLOSE(vFileHandler);

--EXCEPTION
--    WHEN OTHERS THEN
--    p_esito:=-1;
----    UTL_FILE.FCLOSE(vFileHandler);
--    RAISE_APPLICATION_ERROR(-20026, 'PROCEDURA PR_CREA_CINEMA_SALA_XML: non eseguita, si e'' verificato un errore '||SQLERRM);
--END PR_CREA_CINEMA_SALA_XML;

END PA_CD_SIAE; 
/

