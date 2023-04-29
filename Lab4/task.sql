create or replace FUNCTION json_orm(json_data IN VARCHAR2) RETURN SYS_REFCURSOR IS
   v_query_type VARCHAR2(10);
   v_columns VARCHAR2(4000);
   v_tables VARCHAR2(4000);
   v_join_conditions VARCHAR2(4000);
   v_filter_conditions VARCHAR2(4000);
   v_set_clause VARCHAR2(4000);
   v_values VARCHAR2(4000);
   v_sql VARCHAR2(8000);
   v_column_count number;
   v_cursor SYS_REFCURSOR;
   v_path VARCHAR2(4000);
 BEGIN
   -- Extract values from JSON data
   SELECT JSON_VALUE(json_data, '$.query_type') INTO v_query_type FROM DUAL;

  if v_query_type = 'SELECT' then

       SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_name)
         INTO v_columns
         FROM JSON_TABLE(json_data, '$.columns[*]' COLUMNS (column_name VARCHAR2(1000) PATH '$')) j;

       SELECT LISTAGG(table_name, ', ') WITHIN GROUP (ORDER BY table_name)
         INTO v_tables
         FROM JSON_TABLE(json_data, '$.tables[*]' COLUMNS (table_name VARCHAR2(1000) PATH '$')) j;

       SELECT LISTAGG(table_name, ' AND ') WITHIN GROUP (ORDER BY table_name)
         INTO v_join_conditions
         FROM JSON_TABLE(json_data, '$.join_conditions[*]' COLUMNS (table_name VARCHAR2(1000) PATH '$')) j;

       SELECT LISTAGG(table_name, ' AND ') WITHIN GROUP (ORDER BY table_name)
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

        OPEN v_cursor FOR v_sql;

     elsif v_query_type = 'INSERT' then

         SELECT JSON_VALUE(json_data, '$.table') INTO v_tables FROM DUAL;

         SELECT LISTAGG (column_name, ', ')
         INTO v_columns
         FROM JSON_TABLE (json_data,
                        '$.columns[*]' COLUMNS (column_name VARCHAR2 (1000) PATH '$')) j;

          SELECT LISTAGG (val, ', ')
          INTO v_values
          FROM JSON_TABLE (json_data, '$.values[*]' COLUMNS (val VARCHAR2 (4000) PATH '$')) j;

           v_sql := 'INSERT INTO ' || v_tables || ' (' || v_columns || ') VALUES (' || v_values || ')';

     elsif v_query_type = 'DELETE' then
         SELECT JSON_VALUE(json_data, '$.table') INTO v_tables FROM DUAL;

         SELECT LISTAGG (condition, ' AND ') WITHIN GROUP (ORDER BY condition)
           INTO v_filter_conditions
           FROM JSON_TABLE (json_data,
                            '$.filter_conditions[*]' COLUMNS (condition VARCHAR2 (4000) PATH '$')) j;

         v_sql := 'DELETE FROM ' || v_tables || ' WHERE ' || v_filter_conditions;

     elsif v_query_type = 'UPDATE' then
        SELECT JSON_VALUE(json_data, '$.table') INTO v_tables FROM DUAL;

        SELECT LISTAGG (column_name || ' = ' || val, ', ') WITHIN GROUP (ORDER BY column_name)
          INTO v_set_clause
          FROM JSON_TABLE (json_data,
                           '$.set[*]' COLUMNS (column_name VARCHAR2 (1000) PATH '$[0]',
                                               val VARCHAR2 (1000) PATH '$[1]')) j;

         SELECT LISTAGG (condition, ' AND ') WITHIN GROUP (ORDER BY condition)
           INTO v_filter_conditions
           FROM JSON_TABLE (json_data,
                            '$.filter_conditions[*]' COLUMNS (condition VARCHAR2 (4000) PATH '$')) j;

         v_sql := 'UPDATE ' || v_tables || ' SET ' || v_set_clause || ' WHERE ' || v_filter_conditions;

     else
         raise_application_error(-20005, 'Incorrect query type ');
         null;
     end if;

     DBMS_OUTPUT.PUT_LINE(v_sql);
     
     RETURN v_cursor;

 END json_orm; 