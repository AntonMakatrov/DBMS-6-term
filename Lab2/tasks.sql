--Task 1
CREATE TABLE STUDENTS(
    ID NUMBER,
    NAME VARCHAR2(40),
    GROUP_ID NUMBER
);

CREATE TABLE GROUPS(
    ID NUMBER,
    NAME VARCHAR2(40),
    C_VAL NUMBER
);

--Task 2 

CREATE OR REPLACE TRIGGER STUDENTS_CHECK_TRIGGER
BEFORE INSERT ON STUDENTS
FOR EACH ROW
DECLARE
    EX_ID NUMBER;
    NEW_ID NUMBER;

    CURSOR ct1 
    IS
    SELECT ID
    FROM STUDENTS
    WHERE ID = :NEW.ID;

    CURSOR ct2 
    IS
    SELECT ID
    FROM STUDENTS
    ORDER BY ID DESC
    FETCH NEXT 1 ROWS ONLY;
BEGIN
    OPEN ct1;
    FETCH ct1 INTO EX_ID;
    IF NOT ct1%NOTFOUND
     THEN
        RAISE_APPLICATION_ERROR(-20001, 'There`s such id already exists');
    END IF;
    CLOSE ct1;

    IF :NEW.ID IS NULL
    THEN
       OPEN ct2;
        FETCH ct2 INTO NEW_ID; 
        IF ct2%NOTFOUND
        THEN
            :NEW.ID := 1;
        ELSE
            :NEW.ID := NEW_ID + 1;
        END IF;
        CLOSE ct2;
    END IF;

END;

CREATE OR REPLACE TRIGGER GROUPS_CHECK_TRIGGER
BEFORE INSERT ON GROUPS
FOR EACH ROW
DECLARE
    EX_ID NUMBER;
    EX_NAME VARCHAR2(40);
    NEW_ID NUMBER;

    CURSOR ct1 IS
    SELECT ID
    FROM GROUPS
    WHERE ID = :NEW.ID;

    CURSOR ct2 IS
    SELECT NAME
    FROM GROUPS
    WHERE NAME = :NEW.NAME;

    CURSOR ct3 IS
    SELECT ID
    FROM GROUPS
    ORDER BY ID DESC
    FETCH NEXT 1 ROWS ONLY;
BEGIN
    OPEN ct1;
    FETCH ct1 INTO EX_ID;
    IF NOT ct1%NOTFOUND
     THEN
        RAISE_APPLICATION_ERROR(-20001, 'There`s such id already exists');
    END IF;
    CLOSE ct1;

    OPEN ct2;
    FETCH ct2 INTO EX_NAME;
    IF NOT ct2%NOTFOUND
     THEN
        RAISE_APPLICATION_ERROR(-20001, 'There`s such name already exists');
    END IF;
    CLOSE ct2;

    IF :NEW.ID IS NULL
    THEN
       OPEN ct3;
        FETCH ct3 INTO NEW_ID; 
        IF ct3%NOTFOUND
        THEN
            :NEW.ID := 1;
        ELSE
            :NEW.ID := NEW_ID + 1;
        END IF;
        CLOSE ct3;
    END IF;
END;

--Task 3
CREATE OR REPLACE TRIGGER FK_STUDENTS_GROUPS_TRIGGER
BEFORE DELETE ON GROUPS
FOR EACH ROW
BEGIN
    DELETE FROM STUDENTS WHERE STUDENTS.GROUP_ID = :OLD.ID;
END;

--Task 4
CREATE TABLE LOGS(
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY,
    ACTION VARCHAR2(255) NOT NULL,
    TIME TIMESTAMP NOT NULL,
    STUDENT_ID NUMBER NOT NULL,
    OLD_STUDENT_NAME VARCHAR(40),
    OLD_STUDENT_GROUP_ID NUMBER,
    NEW_STUDENT_NAME VARCHAR(40),
    NEW_STUDENT_GROUP_ID NUMBER,
    PRIMARY KEY(ID)
);

CREATE OR REPLACE TRIGGER STUDENTS_LOGS_TRIGGER
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO LOGS(ACTION, TIME, STUDENT_ID, NEW_STUDENT_NAME, NEW_STUDENT_GROUP_ID)
            VALUES ('INSERT', SYSTIMESTAMP, :NEW.ID, :NEW.NAME, :NEW.GROUP_ID);
    ELSIF UPDATING THEN
        INSERT INTO LOGS(ACTION, TIME, STUDENT_ID, NEW_STUDENT_NAME, NEW_STUDENT_GROUP_ID, OLD_STUDENT_NAME, OLD_STUDENT_GROUP_ID)
            VALUES ('UPDATE', SYSTIMESTAMP, :NEW.ID, :NEW.NAME, :NEW.GROUP_ID, :OLD.NAME, :OLD.GROUP_ID);
    ELSIF DELETING THEN
        INSERT INTO LOGS(ACTION, TIME, STUDENT_ID, OLD_STUDENT_NAME, OLD_STUDENT_GROUP_ID)
            VALUES ('DELETE', SYSTIMESTAMP, :OLD.ID, :OLD.NAME, :OLD.GROUP_ID);
    END IF;
END;

--Task 5

CREATE OR REPLACE PROCEDURE BACKUP_INFO(BACKUP_TIME TIMESTAMP) AS
    CURSOR ct1 IS
    SELECT *
    FROM LOGS
    WHERE TIME >= BACKUP_TIME
    ORDER BY TIME;
BEGIN
    EXECUTE IMMEDIATE 'ALTER TRIGGER STUDENTS_LOGS_TRIGGER DISABLE';
    FOR record IN ct1
    LOOP
        IF record.ACTION = 'INSERT' THEN
            DELETE FROM STUDENTS WHERE ID = record.STUDENT_ID;
        ELSIF record.ACTION = 'UPDATE' THEN
            UPDATE STUDENTS
            SET NAME = record.OLD_STUDENT_NAME, GROUP_ID = record.OLD_STUDENT_GROUP_ID
            WHERE ID = record.STUDENT_ID;
        ELSE
            INSERT INTO STUDENTS(ID, NAME, GROUP_ID)
            VALUES (record.STUDENT_ID, record.OLD_STUDENT_NAME, record.OLD_STUDENT_GROUP_ID);
        END IF;
    END LOOP;
    EXECUTE IMMEDIATE 'ALTER TRIGGER STUDENTS_LOGS_TRIGGER ENABLE';
END;

--Task 6

CREATE OR REPLACE TRIGGER GROUPS_C_VAL_UPDATE_TRIGGER
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE GROUPS 
        SET C_VAL = C_VAL + 1 
        WHERE ID = :NEW.GROUP_ID;
    ELSIF UPDATING THEN
        UPDATE GROUPS 
        SET C_VAL = C_VAL + 1 
        WHERE ID = :NEW.GROUP_ID;

        UPDATE GROUPS 
        SET C_VAL = C_VAL - 1 
        WHERE ID = :OLD.GROUP_ID;
    ELSIF DELETING THEN
        UPDATE GROUPS 
        SET C_VAL = C_VAL - 1 
        WHERE ID = :OLD.GROUP_ID;
    END IF;
END;