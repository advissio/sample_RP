CREATE OR REPLACE TRIGGER VENCD."CD_ADV_COMUNICATO" BEFORE INSERT ON "CD_ADV_COMUNICATO" FOR EACH ROW
DECLARE last_Sequence NUMBER; last_InsertID NUMBER; BEGIN IF (:NEW."ID" IS NULL) THEN SELECT "CD_ADV_COMUNICATO_0".NEXTVAL INTO :NEW."ID" FROM DUAL; ELSE SELECT Last_Number-1 INTO last_Sequence FROM User_Sequences WHERE UPPER(Sequence_Name) = UPPER('CD_ADV_COMUNICATO_0'); SELECT :NEW."ID" INTO last_InsertID FROM DUAL; WHILE (last_InsertID > last_Sequence) LOOP SELECT "CD_ADV_COMUNICATO_0".NEXTVAL INTO last_Sequence FROM DUAL; END LOOP; END IF; END;
/




