create or replace FUNCTION json_orm(json_data CLOB) RETURN SYS_REFCURSOR IS
  v_query_type VARCHAR2(100);
  v_columns VARCHAR2(8000);
  v_tables VARCHAR2(8000);
  v_join_conditions VARCHAR2(8000);
  v_filter_conditions VARCHAR2(8000);
  v_set_clause VARCHAR2(8000);
  v_values VARCHAR2(8000);
  v_pks VARCHAR2(8000);
  v_sql VARCHAR2(8000);
  f_q_type VARCHAR2(8000);
  f_cond VARCHAR2(8000);
  f_operator VARCHAR2(8000);
  v_cursor SYS_REFCURSOR;
  v_json_data JSON_OBJECT_T;
  v_temp_obj JSON_OBJECT_T;
  v_json_array JSON_ARRAY_T;

  FUNCTION process_select_condition(v_nest_json_data JSON_OBJECT_T) RETURN VARCHAR2
  IS
    v_type_check varchar2(100);
    v_col VARCHAR2(4000);
    v_tab VARCHAR2(4000);
    v_filter_cond VARCHAR2(4000);
    v_inclusion_operator VARCHAR2(4000);
    v_search_column VARCHAR2(4000);
    v_res_sql VARCHAR2(4000);
    v_n_temp_obj JSON_OBJECT_T;
    v_n_json_array JSON_ARRAY_T;
    f_n_q_type VARCHAR2(8000);
    f_n_cond VARCHAR2(8000);
    f_n_operator VARCHAR2(8000);
  BEGIN

      v_type_check := v_nest_json_data.get_string('query_type');

      if v_type_check = 'SELECT' then

          v_n_json_array := v_nest_json_data.get_array('tables');

          for j in 0..v_n_json_array.GET_SIZE()-1 loop
            if v_tab is null then
                v_tab := v_n_json_array.get_string(j);
            else
                v_tab := v_columns || ', ' || v_n_json_array.get_string(j);
            end if;
          end loop;

          v_col := v_nest_json_data.get_string('column');
          v_inclusion_operator := v_nest_json_data.get_string('operator');
          v_search_column := v_nest_json_data.get_string('search_col');

          v_n_json_array := v_nest_json_data.get_array('filter_conditions');

          for j in 0..v_n_json_array.GET_SIZE()-1 loop
              v_n_temp_obj := treat(v_n_json_array.get(j) as JSON_OBJECT_T);
              f_n_q_type := v_n_temp_obj.get_string('condition_type');
              f_n_operator :=  v_n_temp_obj.get_string('operator');

              if f_n_q_type = 'plain' then
                    f_n_cond :=v_n_temp_obj.get_string('condition');
                    if v_filter_cond is null then
                        v_filter_cond := f_n_cond;
                    else
                        v_filter_cond := v_filter_cond || ' ' || f_operator || ' ' || f_n_cond;
                    end if;

                elsif f_n_q_type = 'included' then
                    f_n_cond := process_select_condition(treat(v_n_temp_obj.get('condition') as JSON_OBJECT_T));
                    if v_filter_cond is null then
                        v_filter_cond := f_n_cond;
                    else
                        v_filter_cond := v_filter_cond || ' ' || f_operator || ' (' || f_n_cond || ')';
                    end if;

                end if;

          end loop;

        -- Build the dynamic SQL statement
        v_res_sql := 'SELECT ' || v_col || ' FROM ' || v_tab;
        v_res_sql := v_res_sql || ' WHERE ' || v_filter_cond;
        v_res_sql := v_search_column || ' ' || v_inclusion_operator || ' (' || v_res_sql || ')';

      end if;

      return v_res_sql;
  END;

BEGIN

  v_json_data := JSON_OBJECT_T.parse(json_data);

  -- Extract values from JSON data
  v_query_type := v_json_data.get_string('query_type');

  if v_query_type = 'SELECT' then

      v_json_array := v_json_data.get_array('columns');

      for i in 0..v_json_array.GET_SIZE()-1 loop
        if v_columns is null then
            v_columns := v_json_array.get_string(i);
        else
            v_columns := v_columns || ', ' || v_json_array.get_string(i);
        end if;
      end loop;

      v_json_array := v_json_data.get_array('tables');

      for i in 0..v_json_array.GET_SIZE()-1 loop
        if v_tables is null then
            v_tables := v_json_array.get_string(i);
        else
            v_tables := v_tables || ', ' || v_json_array.get_string(i);
        end if;
      end loop;

      v_json_array := v_json_data.get_array('join_conditions');

      for i in 0..v_json_array.GET_SIZE()-1 loop
        if v_join_conditions is null then
            v_join_conditions := v_json_array.get_string(i);
        else
            v_join_conditions := v_join_conditions || ' AND ' || v_json_array.get_string(i);
        end if;
      end loop;

      v_json_array := v_json_data.get_array('filter_conditions');

      for i in 0..v_json_array.GET_SIZE()-1 loop
          v_temp_obj := treat(v_json_array.get(i) as JSON_OBJECT_T);
          f_q_type := v_temp_obj.get_string('condition_type');
          f_operator :=  v_temp_obj.get_string('operator');

          if f_q_type = 'plain' then
                f_cond := v_temp_obj.get_string('condition');
                if v_filter_conditions is null then
                    v_filter_conditions := f_cond;
                else
                    v_filter_conditions := v_filter_conditions || ' ' || f_operator || ' ' || f_cond;
                end if;

            elsif f_q_type = 'included' then
                f_cond := process_select_condition(treat(v_temp_obj.get('condition') as JSON_OBJECT_T));
                if v_filter_conditions is null then
                    v_filter_conditions := f_cond;
                else
                    v_filter_conditions := v_filter_conditions || ' ' || f_operator || ' (' || f_cond || ')';
                end if;

            end if;

      end loop;

        -- Build the dynamic SQL statement
        v_sql := 'SELECT ' || v_columns || ' FROM ' || v_tables;
        if v_join_conditions is not null then
            v_sql := v_sql || ' WHERE ' || v_join_conditions;
        end if;
        if v_filter_conditions is not null then
            if v_join_conditions is null then
                v_sql := v_sql || ' WHERE ' || v_filter_conditions;
            else
                v_sql := v_sql || ' AND ' || v_filter_conditions;
            end if;
        end if;

        -- open v_cursor for v_sql;

    elsif v_query_type = 'INSERT' then

        select JSON_VALUE(json_data, '$.table') into v_tables from DUAL;

        select LISTAGG (column_name, ', ')
        into v_columns
        from JSON_TABLE (json_data,
                       '$.columns[*]' COLUMNS (column_name VARCHAR2 (1000) PATH '$')) j;

        select LISTAGG (val, ', ')
         into v_values
         from JSON_TABLE (json_data, '$.values[*]' COLUMNS (val VARCHAR2 (4000) PATH '$')) j;

      v_sql := 'INSERT INTO ' || v_tables || ' (' || v_columns || ') VALUES (' || v_values || ')';

    elsif v_query_type = 'DELETE' then

        select JSON_VALUE(json_data, '$.table') into v_tables from DUAL;

        select LISTAGG (condition, ' AND ')
          into v_filter_conditions
          from JSON_TABLE (json_data,
                           '$.filter_conditions[*]' COLUMNS (condition VARCHAR2 (4000) PATH '$')) j;

        v_sql := 'DELETE FROM ' || v_tables || ' WHERE ' || v_filter_conditions;

    elsif v_query_type = 'UPDATE' then

        select JSON_VALUE(json_data, '$.table') into v_tables from DUAL;

        select LISTAGG (column_name || ' = ' || val, ', ')
         into v_set_clause
         from JSON_TABLE (json_data,
                          '$.set[*]' COLUMNS (column_name VARCHAR2 (1000) PATH '$[0]',
                                              val VARCHAR2 (1000) PATH '$[1]')) j;

        select LISTAGG (condition, ' AND ') WITHIN GROUP (ORDER BY condition)
          into v_filter_conditions
          from JSON_TABLE (json_data,
                           '$.filter_conditions[*]' COLUMNS (condition VARCHAR2 (4000) PATH '$')) j;

        v_sql := 'UPDATE ' || v_tables || ' SET ' || v_set_clause || ' WHERE ' || v_filter_conditions;

    elsif v_query_type = 'CREATE TABLE' then

        SELECT JSON_VALUE(json_data, '$.table') INTO v_tables FROM DUAL;

        SELECT LISTAGG(column_name || ' ' || data_type, ', ')
          INTO v_columns
          FROM JSON_TABLE (json_data,
                           '$.columns[*]' COLUMNS (
                              column_name VARCHAR2(100) PATH '$.name',
                              data_type VARCHAR2(100) PATH '$.type')
                           ) j;

        SELECT LISTAGG ('constraint pk_' || v_tables || '_' || col_name || ' primary_key (' || col_name || ')', ', ')
          INTO v_pks
          FROM JSON_TABLE (json_data,
                           '$.primary_keys[*]' COLUMNS (col_name VARCHAR2 (4000) PATH '$')) j;

        v_sql := 'CREATE TABLE ' || v_tables || ' (' || v_columns || ', ' || v_pks || ');';

        SELECT JSON_VALUE(json_data, '$.primary_keys[0]') INTO v_pks FROM DUAL;

        v_sql := v_sql || ' ' || '

            create sequence ' || v_tables || '_seq start with 1;' ||
                 '
            CREATE OR REPLACE TRIGGER tr_' || v_tables || '_pk_autoincrement
            BEFORE INSERT ON ' || v_tables || '
            FOR EACH ROW
            BEGIN
            SELECT ' || v_tables || '_seq' || '.NEXTVAL
            INTO :NEW.' || v_pks || '
            FROM DUAL;
            END;';

    elsif v_query_type = 'DROP TABLE' then

        SELECT JSON_VALUE(json_data, '$.table') INTO v_tables FROM DUAL;
        v_sql := 'DROP TABLE ' || v_tables;

    else
        raise_application_error(-20005, 'Incorrect query type ');
        null;
    end if;

    DBMS_OUTPUT.PUT_LINE(v_sql);

    RETURN v_cursor;

END json_orm;