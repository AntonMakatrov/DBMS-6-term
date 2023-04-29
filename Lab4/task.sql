create or replace FUNCTION json_orm(json_data IN VARCHAR2) RETURN SYS_REFCURSOR IS
   v_query_type VARCHAR2(10);
   v_columns VARCHAR2(4000);
   v_tables VARCHAR2(4000);
   v_join_conditions VARCHAR2(4000);
   v_filter_conditions VARCHAR2(4000);
   v_sql VARCHAR2(8000);
   v_cursor SYS_REFCURSOR;
 BEGIN
   -- Extract values from JSON data
   SELECT JSON_VALUE(json_data, '$.query_type') INTO v_query_type FROM DUAL;

   SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_name)
     INTO v_columns
     FROM JSON_TABLE(json_data, '$.columns[*]' COLUMNS (column_name VARCHAR2(1000) PATH '$')) j;

   SELECT LISTAGG(table_name, ', ') WITHIN GROUP (ORDER BY table_name)
     INTO v_tables
     FROM JSON_TABLE(json_data, '$.tables[*]' COLUMNS (table_name VARCHAR2(1000) PATH '$')) j;

   SELECT LISTAGG(table_name, ', ') WITHIN GROUP (ORDER BY table_name)
     INTO v_join_conditions
     FROM JSON_TABLE(json_data, '$.join_conditions[*]' COLUMNS (table_name VARCHAR2(1000) PATH '$')) j;

   SELECT LISTAGG(table_name, ', ') WITHIN GROUP (ORDER BY table_name)
     INTO v_filter_conditions
     FROM JSON_TABLE(json_data, '$.filter_conditions[*]' COLUMNS (table_name VARCHAR2(1000) PATH '$')) j;

   -- Build the dynamic SQL statement
   v_sql := 'SELECT ' || v_columns || ' FROM ' || v_tables;
   IF v_join_conditions IS NOT NULL THEN
     v_sql := v_sql || ' WHERE ' || v_join_conditions;
   END IF;
   IF v_filter_conditions IS NOT NULL THEN
     IF v_join_conditions IS NULL THEN
       v_sql := v_sql || ' WHERE ' || v_filter_conditions;
     ELSE
       v_sql := v_sql || ' AND ' || v_filter_conditions;
     END IF;
   END IF;

   -- Print the SQL statement to the console
 DBMS_OUTPUT.PUT_LINE('query_type: ' || v_query_type);
 DBMS_OUTPUT.PUT_LINE('columns: ' || v_columns);
 DBMS_OUTPUT.PUT_LINE('tables: ' || v_tables);
 DBMS_OUTPUT.PUT_LINE('join_conditions: ' || v_join_conditions);
 DBMS_OUTPUT.PUT_LINE('filter_conditions: ' || v_filter_conditions);
   DBMS_OUTPUT.PUT_LINE(v_sql);


   RETURN v_cursor;
