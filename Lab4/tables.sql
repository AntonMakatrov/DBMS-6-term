drop table table2;
drop table table1;

CREATE TABLE table1 (
  id NUMBER,
  name VARCHAR2(100),
  age NUMBER
);

CREATE TABLE table2 (
  id NUMBER,
  address VARCHAR2(100),
  phone VARCHAR2(100)
);

INSERT INTO table1 (id, name, age)
VALUES (1, 'Alice', 25);

INSERT INTO table1 (id, name, age)
VALUES (2, 'Bob', 30);

INSERT INTO table1 (id, name, age)
VALUES (3, 'Charlie', 35);

INSERT INTO table2 (id, address, phone)
VALUES (1, '123 Main St', '555-1234');

INSERT INTO table2 (id, address, phone)
VALUES (2, '456 Oak St', '555-5678');

INSERT INTO table2 (id, address, phone)
VALUES (3, '789 Elm St', '555-9012');

CREATE TABLE table1 (id NUMBER, val NUMBER, constraint pk_table1_id primary key (id));
create sequence table1_seq start with 1;
CREATE OR REPLACE TRIGGER tr_table1_pk_autoincrement
BEFORE INSERT ON table1
FOR EACH ROW
BEGIN
SELECT table1_seq.NEXTVAL
INTO :NEW.id
FROM DUAL;
END;

CREATE TABLE table2 (id NUMBER, val NUMBER, constraint pk_table2_id primary key (id));
create sequence table2_seq start with 1;
CREATE OR REPLACE TRIGGER tr_table2_pk_autoincrement
BEFORE INSERT ON table2
FOR EACH ROW
BEGIN
SELECT table2_seq.NEXTVAL
INTO :NEW.id
FROM DUAL;
END;

select * from table1;
select * from table2;