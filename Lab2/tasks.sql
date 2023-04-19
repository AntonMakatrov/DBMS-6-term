--Task 1
CREATE TABLE STUDENTS(
    ID NUMBER,
    NAME VARCHAR2(40),
    GROUP_ID NUMBER
);

CREATE TABLE GROUPS(
    ID NUMBER,
    NAME VARCHAR2(40),
    C_VAL NUMBER DEFAULT 0 NOT NULL
);

--Task 2 

CREATE OR REPLACE TRIGGER STUDENTS_CHECK_TRIGGER
BEFORE INSERT ON students
FOR EACH ROW
FOLLOWS stud_auto_increment
DECLARE
    check_id NUMBER default 0;
BEGIN
    SELECT id INTO check_id
    FROM students
    WHERE students.id = :new.id;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('You a good at this!');
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
BEFORE DELETE ON Groups FOR EACH ROW 
BEGIN
    DELETE FROM Students WHERE group_id = :OLD.id;
END;

--Task 4
CREATE TABLE LOGS(
    id NUMBER,
    act_date TIMESTAMP NOT NULL,
    action VARCHAR2(10) NOT NULL,
    old_id NUMBER,
    new_id NUMBER,
    group_old NUMBER,
    group_new NUMBER,
    name_old VARCHAR2(100),
    name_new VARCHAR2(100),
    CONSTRAINT stud_journal_pk PRIMARY KEY (id)
);
CREATE SEQUENCE logs_seq
START WITH 1;

CREATE OR REPLACE TRIGGER STUDENTS_LOGS_TRIGGER
    AFTER INSERT OR UPDATE OR DELETE ON students
    FOR EACH ROW
DECLARE
    ssDate TIMESTAMP;
BEGIN
    IF INSERTING THEN
        SELECT CURRENT_TIMESTAMP INTO ssDate FROM DUAL;
        INSERT INTO LOGS VALUES (logs_seq.NEXTVAL, ssDate, 'INSERT', NULL, :NEW.id, NULL, :NEW.group_id, NULL, :NEW.name);
    ELSIF UPDATING THEN
        SELECT CURRENT_TIMESTAMP INTO ssDate FROM DUAL;
        INSERT INTO LOGS VALUES (logs_seq.NEXTVAL,
                                            ssDate,
                                            'UPDATE', :OLD.id,
                                            :NEW.id, :OLD.group_id, :NEW.group_id, :OLD.name, :NEW.name);
    ELSIF DELETING THEN
        SELECT CURRENT_TIMESTAMP INTO ssDate FROM DUAL;
        INSERT INTO LOGS VALUES (logs_seq.NEXTVAL,
                                            ssDate,
                                            'DELETE', :OLD.id,
                                            NULL, :OLD.group_id, NULL, :OLD.name, NULL);
    END IF;
END;

--Task 5

CREATE OR REPLACE PROCEDURE BACKUP_INFO(time in VARCHAR2)
IS
     PRAGMA AUTONOMOUS_TRANSACTION;
    converted_time TIMESTAMP := TO_TIMESTAMP(time, 'yyyy-mm-dd hh24:mi:ss.ff6');
    CURSOR rest IS
    SELECT *
    FROM logs
    WHERE act_date >= converted_time
    ORDER BY id DESC;
BEGIN
    FOR act in rest
    LOOP
        IF act.action = 'INSERT' THEN
            DELETE FROM students
            WHERE students.id = act.new_id;
        ELSIF act.action = 'UPDATE' THEN
            UPDATE students
            SET students.name = act.name_old, students.group_id = act.group_old
            WHERE students.id = act.old_id;
        ELSIF act.action = 'DELETE' THEN
            INSERT INTO students VALUES (act.old_id, act.name_old, act.group_old);
        END IF;

         DELETE FROM LOGS
         WHERE id = act.id;
    END LOOP;
     COMMIT;
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

CREATE SEQUENCE id_auto_increment_for_groups 
    START WITH 1 
    INCREMENT BY 1 
    NOMAXVALUE;

CREATE SEQUENCE id_auto_increment_for_students 
    START WITH 1 
    INCREMENT BY 1 
    NOMAXVALUE;

CREATE OR REPLACE TRIGGER GEN_STUDENTS_ID
    BEFORE INSERT ON STUDENTS FOR EACH ROW
BEGIN
    SELECT  id_auto_increment_for_students.NEXTVAL 
        INTO :NEW.id FROM DUAL;
END;

CREATE OR REPLACE TRIGGER GEN_GROUPS_ID
    BEFORE INSERT ON GROUPS FOR EACH ROW
BEGIN
    SELECT id_auto_increment_for_groups.NEXTVAL 
        INTO :NEW.id FROM DUAL;
END;


CREATE SEQUENCE stud_seq START WITH 1;
CREATE SEQUENCE group_seq START WITH 1;

CREATE OR REPLACE TRIGGER stud_auto_increment
BEFORE INSERT ON students
FOR EACH ROW
BEGIN
    IF :new.id = 0 THEN
        SELECT stud_seq.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;

CREATE OR REPLACE TRIGGER group_auto_increment
BEFORE INSERT ON groups
FOR EACH ROW
BEGIN
    SELECT group_seq.nextval
    INTO :new.id
    FROM DUAL;
END;
