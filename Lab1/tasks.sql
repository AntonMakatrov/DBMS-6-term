CREATE DATABASE test_db;

select username, password from dba_users;
-- Task 1
CREATE TABLE MyTable(id number, val number);
DROP TABLE MyTable;

-- Task 2
BEGIN
FOR mytab_counter in 1..10
LOOP
    INSERT INTO MyTable VALUES (mytab_counter, ROUND(DBMS_RANDOM.VALUE(1, 10000), 0));
END LOOP;
END;
select * from MyTable;
delete from MYTABLE;

-- Task 3
CREATE OR REPLACE FUNCTION task3
RETURN VARCHAR2
IS
    even_num number := 0;
    n_even_num number := 0;
    result varchar2(5);


    CURSOR even_cursor
    IS
    SELECT COUNT(*) FROM MyTable
    WHERE MOD(MyTable.val, 2) = 0;

    CURSOR n_even_cursor
    IS
    SELECT COUNT(*) FROM MyTable
    WHERE MOD(MyTable.val, 2) <> 0;

BEGIN
    OPEN even_cursor;
    OPEN n_even_cursor;

    FETCH even_cursor INTO even_num;
    FETCH n_even_cursor INTO n_even_num;

    IF even_cursor%NOTFOUND THEN
        result := 'FALSE';
    end if;

    IF n_even_cursor%NOTFOUND THEN
        result := 'TRUE';
    end if;

    IF even_num > n_even_num THEN
        result := 'TRUE';
    ELSIF even_num < n_even_num THEN
        result := 'FALSE';
    ELSE
        result := 'EQUAL';
    END IF;

    CLOSE even_cursor;
    CLOSE n_even_cursor;

    DBMS_OUTPUT.PUT_LINE(result);
    RETURN result;
END;

-- Task3 Test
DECLARE
    result VARCHAR2(5);
begin
    
    result := task3();
    DBMS_OUTPUT.PUT_LINE('New result of task3 is: ' || result);
end;

-- Task 4
CREATE OR REPLACE FUNCTION task4
(id IN NUMBER)
RETURN VARCHAR2
IS
    tab_val NUMBER;
    result varchar2(100);
BEGIN
    SELECT val INTO tab_val FROM MyTable
    WHERE id = task4.id;

    result := 'INSERT INTO MyTable VALUES (' || id || ', '|| tab_val ||')';

    DBMS_OUTPUT.PUT_LINE(result);
    RETURN result;

    EXCEPTION
        WHEN no_data_found THEN
            result := 'this id does not exist.';
            DBMS_OUTPUT.PUT_LINE(result);
            return result;
END;
delete from MYTABLE;
-- Task 4 test
DECLARE
    result VARCHAR2(100);
BEGIN
    result:= task4(9);
end;
select id, val from MYTABLE
where id = 9;

-- Task-5 
CREATE OR REPLACE PROCEDURE MyTableInsert
(id IN NUMBER, val IN NUMBER)
IS
    BEGIN
        INSERT INTO MyTable
            VALUES (MyTableInsert.id, MyTableInsert.val);
    END;
-- Insert test
BEGIN
    MyTableInsert(1, 2);
end;
SELECT id, val FROM MyTable
    ORDER BY id;
--

CREATE OR REPLACE PROCEDURE MyTableUpdate
(id IN NUMBER, new_val IN NUMBER)
IS
BEGIN
    UPDATE MyTable
    SET val = new_val
    WHERE id = MyTableUpdate.id;
END;

-- Update test
BEGIN
    MyTableUpdate(1, 3);
end;
SELECT id, val FROM MyTable
    ORDER BY id;
--

CREATE OR REPLACE PROCEDURE MyTableDelete
(id IN NUMBER DEFAULT NULL, val IN NUMBER DEFAULT NULL)
IS
BEGIN
    IF MyTableDelete.id is NOT NULL AND MyTableDelete.val is NULL THEN
        DBMS_OUTPUT.PUT_LINE('value is NULL!');
        DELETE FROM MyTable
        WHERE id = MyTableDelete.id;
    ELSIF MyTableDelete.id is NULL AND MyTableDelete.val is NOT NULL THEN
        DELETE FROM MyTable
        WHERE val = MyTableDelete.val;
    ELSE
        DBMS_OUTPUT.PUT_LINE('You put a wrong number!');
    end if;
END;
-- Delete test
begin
    MyTableDelete(id => 1);
end;
select id, val from MyTable
order by id;

-- Task 6

CREATE OR REPLACE FUNCTION task6
(salary IN FLOAT DEFAULT 0.0, percent IN NUMBER DEFAULT 0)
RETURN FLOAT
IS
    all_cash FLOAT := 0;
    fl_percent FLOAT := 0.0;
    invalid_input EXCEPTION;
BEGIN
    IF salary < 0.0 OR percent < 0 THEN
        RAISE invalid_input;
    end if;
    fl_percent := percent / 100;
    all_cash := (1 + fl_percent) * 12 * salary;

    return all_cash;

    EXCEPTION
        WHEN invalid_input THEN
        DBMS_OUTPUT.PUT_LINE('Wrong input, please enter correct data.');
        RETURN 0.0;
        WHEN others THEN
        DBMS_OUTPUT.PUT_LINE('Internal error.');
        RETURN -1;
end;

-- Task 6 test
DECLARE
    salary NUMBER;
    percent NUMBER;
    result FLOAT;
BEGIN
    salary := 100;
    percent := 15;

    result := task6(salary, percent);

    IF result = 0.0 THEN
        DBMS_OUTPUT.PUT_LINE('You have not any bonus!!!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Your year-bonus is: ' || result);
    end if;
end;
