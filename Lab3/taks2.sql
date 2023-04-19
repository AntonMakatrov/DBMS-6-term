CREATE OR REPLACE PROCEDURE COMP_PROCEDURES(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    var_amount NUMBER;
    dev_procedure_text VARCHAR2(32767);
    prod_procedure_text VARCHAR2(32767);

    CURSOR dev_schema_procedures IS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = dev_schema_name
            AND TYPE = 'PROCEDURE';
BEGIN
    FOR dev_schema_procedure IN dev_schema_procedures
    LOOP
        SELECT COUNT(*) INTO var_amount FROM
        (
            (SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = dev_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME
            MINUS
            SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = prod_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME)
            UNION ALL
            (SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = prod_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME
            MINUS
            SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = dev_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME)
        );

        SELECT LISTAGG(TEXT, '\n ') INTO dev_procedure_text FROM ALL_SOURCE 
        WHERE OWNER = dev_schema_name
            AND TYPE = 'PROCEDURE'
            AND LINE <> 1
            AND NAME = dev_schema_procedure.NAME;

        SELECT LISTAGG(TEXT, '\n ') INTO prod_procedure_text FROM ALL_SOURCE 
        WHERE OWNER = prod_schema_name
            AND TYPE = 'PROCEDURE'
            AND LINE <> 1
            AND NAME = dev_schema_procedure.NAME;

        IF var_amount <> 0 OR dev_procedure_text <> prod_procedure_text OR prod_procedure_text IS NULL THEN
            dbms_output.put_line('PROCEDURE: ' || dev_schema_procedure.NAME);
        END IF;
    END LOOP;
END;


CREATE OR REPLACE PROCEDURE COMP_FUNCTIONS(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AS
    dev_procedure_text VARCHAR2(32767);
    prod_procedure_text VARCHAR2(32767);
    var_amount NUMBER;

    CURSOR dev_schema_procedures IS
        SELECT DISTINCT NAME FROM ALL_SOURCE
        WHERE OWNER = dev_schema_name
            AND TYPE = 'FUNCTION';
BEGIN
    FOR dev_schema_procedure IN dev_schema_procedures
    LOOP
        SELECT COUNT(*) INTO var_amount FROM
        (
            (SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = dev_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME
            MINUS
            SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = prod_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME)
            UNION ALL
            (SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = prod_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME
            MINUS
            SELECT ARGUMENT_NAME, DATA_TYPE
            FROM ALL_ARGUMENTS
            WHERE OWNER = dev_schema_name
                AND OBJECT_NAME = dev_schema_procedure.NAME)
        );

        SELECT LISTAGG(TEXT, '\n ') INTO dev_procedure_text FROM ALL_SOURCE 
        WHERE OWNER = dev_schema_name
            AND TYPE = 'FUNCTION'
            AND LINE <> 1
            AND NAME = dev_schema_procedure.NAME;

        SELECT LISTAGG(TEXT, '\n ') INTO prod_procedure_text FROM ALL_SOURCE 
        WHERE OWNER = prod_schema_name
            AND TYPE = 'FUNCTION'
            AND LINE <> 1
            AND NAME = dev_schema_procedure.NAME;

        IF var_amount <> 0 OR dev_procedure_text <> prod_procedure_text OR prod_procedure_text IS NULL THEN
            dbms_output.put_line('FUNCTION: ' || dev_schema_procedure.NAME);
        END IF;
    END LOOP;
END;