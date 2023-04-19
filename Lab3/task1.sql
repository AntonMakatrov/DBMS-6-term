CREATE OR REPLACE PROCEDURE GET_TABLES(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    tab_amount NUMBER;
    constr_amount NUMBER;

    CURSOR dev_schema_tables IS
        SELECT * FROM ALL_TABLES
        WHERE OWNER = dev_schema_name;
BEGIN
    FOR dev_schema_table IN dev_schema_tables
    LOOP
        SELECT COUNT(*) INTO tab_amount FROM
        (
            (SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = dev_schema_name AND TABLE_NAME = dev_schema_table.TABLE_NAME
            MINUS
            SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = prod_schema_name AND TABLE_NAME = dev_schema_table.TABLE_NAME)
            UNION
            (SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = prod_schema_name AND TABLE_NAME = dev_schema_table.TABLE_NAME
            MINUS
            SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = dev_schema_name AND TABLE_NAME = dev_schema_table.TABLE_NAME)
        );

        SELECT COUNT(*) INTO constr_amount FROM
        (
            (SELECT ALL_CONS_COLUMNS.COLUMN_NAME, ALL_CONS_COLUMNS.CONSTRAINT_NAME, 
                    ALL_CONSTRAINTS.CONSTRAINT_TYPE
            FROM ALL_CONS_COLUMNS
            JOIN ALL_CONSTRAINTS
            ON ALL_CONSTRAINTS.TABLE_NAME = ALL_CONS_COLUMNS.TABLE_NAME
            WHERE ALL_CONSTRAINTS.OWNER = dev_schema_name 
                AND NOT REGEXP_LIKE (ALL_CONS_COLUMNS.CONSTRAINT_NAME, '^SYS_|^BIN_')
                AND ALL_CONS_COLUMNS.TABLE_NAME = dev_schema_table.TABLE_NAME
            MINUS
            SELECT ALL_CONS_COLUMNS.COLUMN_NAME, ALL_CONS_COLUMNS.CONSTRAINT_NAME, 
                    ALL_CONSTRAINTS.CONSTRAINT_TYPE
            FROM ALL_CONS_COLUMNS
            JOIN ALL_CONSTRAINTS
            ON ALL_CONSTRAINTS.TABLE_NAME = ALL_CONS_COLUMNS.TABLE_NAME
            WHERE ALL_CONSTRAINTS.OWNER = prod_schema_name
                AND NOT REGEXP_LIKE (ALL_CONS_COLUMNS.CONSTRAINT_NAME, '^SYS_|^BIN_')
                AND ALL_CONS_COLUMNS.TABLE_NAME = dev_schema_table.TABLE_NAME)
            UNION ALL
            (SELECT ALL_CONS_COLUMNS.COLUMN_NAME, ALL_CONS_COLUMNS.CONSTRAINT_NAME, 
                    ALL_CONSTRAINTS.CONSTRAINT_TYPE
            FROM ALL_CONS_COLUMNS
            JOIN ALL_CONSTRAINTS
            ON ALL_CONSTRAINTS.TABLE_NAME = ALL_CONS_COLUMNS.TABLE_NAME
            WHERE ALL_CONSTRAINTS.OWNER = prod_schema_name
                AND NOT REGEXP_LIKE (ALL_CONS_COLUMNS.CONSTRAINT_NAME, '^SYS_|^BIN_')
                AND ALL_CONS_COLUMNS.TABLE_NAME = dev_schema_table.TABLE_NAME
            MINUS
            SELECT ALL_CONS_COLUMNS.COLUMN_NAME, ALL_CONS_COLUMNS.CONSTRAINT_NAME, 
                    ALL_CONSTRAINTS.CONSTRAINT_TYPE
            FROM ALL_CONS_COLUMNS
            JOIN ALL_CONSTRAINTS
            ON ALL_CONSTRAINTS.TABLE_NAME = ALL_CONS_COLUMNS.TABLE_NAME
            WHERE ALL_CONSTRAINTS.OWNER = dev_schema_name 
                AND NOT REGEXP_LIKE (ALL_CONS_COLUMNS.CONSTRAINT_NAME, '^SYS_|^BIN_')
                AND ALL_CONS_COLUMNS.TABLE_NAME = dev_schema_table.TABLE_NAME)
        );

        IF tab_amount <> 0 OR constr_amount <> 0 THEN
            dbms_output.put_line('TABLE: ' || dev_schema_table.TABLE_NAME);
            DDL_TABLES(dev_schema_table.TABLE_NAME, dev_schema_name, prod_schema_name);
        END IF;
    END LOOP;
END;
