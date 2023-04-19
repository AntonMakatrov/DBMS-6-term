CREATE OR REPLACE PROCEDURE DDL_PROCEDURES(procedure_name VARCHAR2, dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    dev_procedure_text VARCHAR2(32767);
    arg_procedure VARCHAR2(32767);
    whole_text VARCHAR2(32767);
BEGIN
    whole_text := 'CREATE OR REPLACE PROCEDURE ' || prod_schema_name || '.' || procedure_name || '(';

    SELECT LISTAGG(CONCAT(CONCAT(ARGUMENT_NAME, ' '), DATA_TYPE), ', ')
    INTO arg_procedure
    FROM ALL_ARGUMENTS
    WHERE OWNER = dev_schema_name
        AND OBJECT_NAME = procedure_name
        AND POSITION <> 0;

    whole_text := CONCAT(whole_text, arg_procedure || ') AS' || chr(10));
    IF arg_procedure IS NULL THEN
        whole_text := REPLACE(whole_text, '()', '');
    END IF;

    SELECT LISTAGG(TEXT) INTO dev_procedure_text FROM ALL_SOURCE 
    WHERE OWNER = dev_schema_name
        AND TYPE = 'PROCEDURE'
        AND NAME = procedure_name
        AND line <> 1;

    dev_procedure_text := CONCAT(whole_text, dev_procedure_text);
    -- dbms_output.PUT_LINE(dev_procedure_text);
    EXECUTE IMMEDIATE dev_procedure_text;
END;

/

CREATE OR REPLACE PROCEDURE DDL_FUNCTIONS(function_name VARCHAR2, dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    dev_function_text VARCHAR2(32767);
    type_return VARCHAR(50);
    arg_function VARCHAR2(32767);
    whole_text VARCHAR2(32767);
BEGIN
    whole_text := 'CREATE OR REPLACE FUNCTION ' || prod_schema_name || '.' || function_name || '(';

    SELECT LISTAGG(CONCAT(CONCAT(ARGUMENT_NAME, ' '), DATA_TYPE), ', ')
    INTO arg_function
    FROM ALL_ARGUMENTS
    WHERE OWNER = dev_schema_name
        AND OBJECT_NAME = function_name
        AND POSITION <> 0;

    SELECT DATA_TYPE
    INTO type_return
    FROM ALL_ARGUMENTS
    WHERE OWNER = dev_schema_name
        AND OBJECT_NAME = function_name
        AND POSITION = 0;
    
    whole_text := CONCAT(whole_text, arg_function || ') RETURN ' || type_return || ' AS' || chr(10));
    IF arg_function IS NULL THEN
        whole_text := REPLACE(whole_text, '()', '');
    END IF;

    SELECT LISTAGG(TEXT) INTO dev_function_text FROM ALL_SOURCE 
    WHERE OWNER = dev_schema_name
        AND TYPE = 'FUNCTION'
        AND NAME = function_name
        AND line <> 1;

    dev_function_text := CONCAT(whole_text, dev_function_text);
    -- dbms_output.PUT_LINE(dev_function_text);
    EXECUTE IMMEDIATE dev_function_text;
END;
/

CREATE OR REPLACE PROCEDURE DDL_PACKAGES(package_name VARCHAR2, dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    dev_package_text VARCHAR2(32767);
    whole_text VARCHAR2(32767);
BEGIN
    whole_text := 'CREATE OR REPLACE PACKAGE ' || prod_schema_name || '.' || package_name || ' AS' || chr(10);

    SELECT LISTAGG(TEXT) INTO dev_package_text FROM ALL_SOURCE 
    WHERE OWNER = dev_schema_name
        AND TYPE = 'PACKAGE'
        AND NAME = package_name
        AND line <> 1;

    dev_package_text := CONCAT(whole_text, dev_package_text);
    -- dbms_output.PUT_LINE(dev_package_text);
    EXECUTE IMMEDIATE dev_package_text;
END;
/

CREATE OR REPLACE PROCEDURE DDL_INDEXES(ind_name VARCHAR2, dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    dev_index_columns VARCHAR2(32767);
    tab_name VARCHAR2(40);
    whole_text VARCHAR2(32767);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'DROP INDEX ' || prod_schema_name || '.' || ind_name;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -1418 THEN
                RAISE;
            END IF;
    END;
    SELECT LISTAGG(TABLE_NAME) INTO tab_name
    FROM ALL_INDEXES
    WHERE OWNER = dev_schema_name 
        AND INDEX_NAME = ind_name;
    whole_text := 'CREATE INDEX ' || prod_schema_name || '.' || ind_name || ' ON ' || prod_schema_name || '.' || tab_name || '(';

    SELECT LISTAGG(COLUMN_NAME, ', ') INTO dev_index_columns FROM ALL_IND_COLUMNS
    WHERE INDEX_OWNER = dev_schema_name
        AND INDEX_NAME = ind_name;

    whole_text := CONCAT(whole_text, dev_index_columns || ')');
    -- dbms_output.PUT_LINE(whole_text);
    EXECUTE IMMEDIATE whole_text;
END;
/

CREATE OR REPLACE PROCEDURE DDL_TABLES(tab_name VARCHAR2, dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    whole_text VARCHAR2(32767);
    CURSOR table_columns IS
        SELECT column_name, data_type, data_length, nullable
        FROM ALL_TAB_COLUMNS
        WHERE OWNER = dev_schema_name
            AND TABLE_NAME = tab_name;
    CURSOR table_constraints IS
        SELECT DISTINCT ALL_CONS_COLUMNS.COLUMN_NAME, ALL_CONS_COLUMNS.CONSTRAINT_NAME, ALL_IND_COLUMNS.INDEX_NAME,
                    ALL_CONSTRAINTS.CONSTRAINT_TYPE, ALL_IND_COLUMNS.TABLE_NAME, ALL_IND_COLUMNS.COLUMN_NAME ref_column
            FROM ALL_CONS_COLUMNS
            JOIN ALL_CONSTRAINTS
            ON ALL_CONSTRAINTS.TABLE_NAME = ALL_CONS_COLUMNS.TABLE_NAME
            LEFT JOIN ALL_IND_COLUMNS
            ON ALL_CONSTRAINTS.R_CONSTRAINT_NAME = ALL_IND_COLUMNS.INDEX_NAME
            WHERE ALL_CONSTRAINTS.OWNER = dev_schema_name 
                AND NOT REGEXP_LIKE (ALL_CONS_COLUMNS.CONSTRAINT_NAME, '^SYS_|^BIN%')
                AND ALL_CONSTRAINTS.CONSTRAINT_TYPE <> 'C'
                AND ALL_CONS_COLUMNS.TABLE_NAME = tab_name;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE ' || prod_schema_name || '.' || tab_name;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    whole_text := CONCAT('CREATE TABLE ', prod_schema_name || '.' || tab_name || '(' || CHR(10));
    FOR table_column IN table_columns
    LOOP
        whole_text := CONCAT(whole_text, CHR(9) || table_column.COLUMN_NAME || ' ' || table_column.DATA_TYPE || '(' || table_column.DATA_LENGTH || ')');
        IF table_column.NULLABLE = 'N' THEN
            whole_text := CONCAT(whole_text, ' NOT NULL');
        END IF;
        whole_text := CONCAT(whole_text, ',' || CHR(10));
    END LOOP;
    FOR table_constraint IN table_constraints
    LOOP
        IF table_constraint.CONSTRAINT_TYPE = 'U' THEN
            whole_text := CONCAT(whole_text, CHR(9) || 'CONSTRAINT ' || table_constraint.CONSTRAINT_NAME || ' ');
            whole_text := CONCAT(whole_text, 'UNIQUE ');
            whole_text := CONCAT(whole_text, '(' || table_constraint.COLUMN_NAME || '),' || CHR(10));
        END IF;
        IF table_constraint.CONSTRAINT_TYPE = 'P' AND SUBSTR(table_constraint.CONSTRAINT_NAME, 1, 1) = 'P' THEN
            whole_text := CONCAT(whole_text, CHR(9) || 'CONSTRAINT ' || table_constraint.CONSTRAINT_NAME || ' ');
            whole_text := CONCAT(whole_text, 'PRIMARY KEY ');
            whole_text := CONCAT(whole_text, '(' || table_constraint.COLUMN_NAME || '),' || CHR(10));
        END IF;
        IF table_constraint.CONSTRAINT_TYPE = 'R' AND SUBSTR(table_constraint.CONSTRAINT_NAME, 1, 1) = 'F' THEN
            whole_text := CONCAT(whole_text, CHR(9) || 'CONSTRAINT ' || table_constraint.CONSTRAINT_NAME || ' ');
            whole_text := CONCAT(whole_text, 'FOREIGN KEY ');
            whole_text := CONCAT(whole_text, '(' || table_constraint.COLUMN_NAME || ')' || CHR(10));
            whole_text := CONCAT(whole_text, 'REFERENCES ' || prod_schema_name || '.' || table_constraint.TABLE_NAME);
            whole_text := CONCAT(whole_text, '(' || table_constraint.ref_column || '),' || CHR(10));
        END IF;
    END LOOP;

    whole_text := CONCAT(whole_text, ')');
    whole_text := REPLACE(whole_text, ',' || chr(10) || ')', chr(10) || ')');
    whole_text := REPLACE(whole_text, ', )', ')');
    -- dbms_output.PUT_LINE(whole_text);
    EXECUTE IMMEDIATE whole_text;
END;
/

CREATE OR REPLACE PROCEDURE REMOVE_PROD_OBJ(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    CURSOR dev_schema_tables IS
        SELECT TABLE_NAME FROM ALL_TABLES
        WHERE OWNER = prod_schema_name
        MINUS
        SELECT TABLE_NAME FROM ALL_TABLES
        WHERE OWNER = dev_schema_name;
    
    CURSOR dev_schema_procedures IS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = prod_schema_name
            AND TYPE = 'PROCEDURE'
        MINUS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = dev_schema_name
            AND TYPE = 'PROCEDURE';
    
    CURSOR dev_schema_functions IS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = prod_schema_name
            AND TYPE = 'FUNCTION'
        MINUS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = dev_schema_name
            AND TYPE = 'FUNCTION';
    
    CURSOR dev_schema_packages IS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = prod_schema_name
            AND TYPE = 'PACKAGE'
        MINUS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = dev_schema_name
            AND TYPE = 'PACKAGE';
    
    CURSOR dev_schema_indexes IS
        SELECT INDEX_NAME FROM ALL_INDEXES
        WHERE OWNER = prod_schema_name 
            AND NOT REGEXP_LIKE (ALL_INDEXES.INDEX_NAME, '^SYS_|^BIN_')
        MINUS
        SELECT INDEX_NAME FROM ALL_INDEXES
        WHERE OWNER = dev_schema_name 
            AND NOT REGEXP_LIKE (ALL_INDEXES.INDEX_NAME, '^SYS_|^BIN_');
BEGIN
    FOR dev_schema_table IN dev_schema_tables
    LOOP
        -- dbms_output.put_line('DROP TABLE ' || prod_schema_name || '.' || dev_schema_table.TABLE_NAME || ';');
        EXECUTE IMMEDIATE 'DROP TABLE ' || prod_schema_name || '.' || dev_schema_table.TABLE_NAME;
    END LOOP;
    FOR dev_schema_procedure IN dev_schema_procedures
    LOOP
        -- dbms_output.put_line('DROP PROCEDURE ' || prod_schema_name || '.' || dev_schema_procedure.NAME || ';');
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || prod_schema_name || '.' || dev_schema_procedure.NAME;
    END LOOP;
    FOR dev_schema_function IN dev_schema_functions
    LOOP
        -- dbms_output.put_line('DROP FUNCTION ' || prod_schema_name || '.' || dev_schema_function.NAME || ';');
        EXECUTE IMMEDIATE 'DROP FUNCTION ' || prod_schema_name || '.' || dev_schema_function.NAME;
    END LOOP;
    FOR dev_schema_package IN dev_schema_packages
    LOOP
        -- dbms_output.put_line('DROP PACKAGE ' || prod_schema_name || '.' || dev_schema_package.NAME || ';');
        EXECUTE IMMEDIATE 'DROP PACKAGE ' || prod_schema_name || '.' || dev_schema_package.NAME;
    END LOOP;
    FOR dev_schema_index IN dev_schema_indexes
    LOOP
        -- dbms_output.put_line('DROP INDEX ' || prod_schema_name || '.' || dev_schema_index.INDEX_NAME || ';');
        EXECUTE IMMEDIATE 'DROP INDEX ' || prod_schema_name || '.' || dev_schema_index.INDEX_NAME;
    END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE CHECK_CYCLE(dev_schema_name VARCHAR2) AS
    amount NUMBER;
    CURSOR tab_all IS
    SELECT DISTINCT ALL_CONS_COLUMNS.COLUMN_NAME, ALL_CONS_COLUMNS.CONSTRAINT_NAME,
        ALL_CONSTRAINTS.CONSTRAINT_TYPE, ALL_IND_COLUMNS.TABLE_NAME tab1, ALL_CONSTRAINTS.TABLE_NAME tab2
            FROM ALL_CONS_COLUMNS
            JOIN ALL_CONSTRAINTS
            ON ALL_CONSTRAINTS.TABLE_NAME = ALL_CONS_COLUMNS.TABLE_NAME
            LEFT JOIN ALL_IND_COLUMNS
            ON ALL_CONSTRAINTS.R_CONSTRAINT_NAME = ALL_IND_COLUMNS.INDEX_NAME
            WHERE ALL_CONSTRAINTS.OWNER = 'DEV_SCHEMA2'
                AND NOT REGEXP_LIKE (ALL_CONS_COLUMNS.CONSTRAINT_NAME, '^SYS_|^BIN%')
                AND ALL_CONSTRAINTS.CONSTRAINT_TYPE = 'R'
                AND SUBSTR(ALL_CONS_COLUMNS.CONSTRAINT_NAME, 1, 1) = 'F';
BEGIN
    EXECUTE IMMEDIATE 'DELETE FROM cycle_check';
    FOR tab IN tab_all
    LOOP
        EXECUTE IMMEDIATE 'INSERT INTO CYCLE_CHECK VALUES(''' || tab.tab1 || ''', ' || '1)';
        EXECUTE IMMEDIATE 'INSERT INTO CYCLE_CHECK VALUES(''' || tab.tab2 || ''', ' || '-1)';
        SELECT COUNT(*) INTO amount FROM
            (SELECT name, sum(num) sum FROM cycle_check
                GROUP BY name)
            WHERE sum <> 0;
        IF amount = 0 THEN 
            RAISE_APPLICATION_ERROR(-20343,'CYCLE IN TABLES');
        END IF;
    END LOOP;
END;
/