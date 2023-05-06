create or replace procedure rollback_by_date (date_time in timestamp)
as
begin
    disable_all_constraints('ORDERS');
    disable_all_constraints('CLIENTS');
    disable_all_constraints('PRODUCTS');

    delete from clients;
    delete from products;
    delete from orders;

    for i in (select * from clients_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID) LOOP
        if i.CHANGE_TYPE = 'INSERT' then
          insert into clients values (i.CLIENT_ID, i.FIRST_NAME, i.LAST_NAME, i.EMAIL, i.PHONE_NUMBER);
        elsif i.CHANGE_TYPE = 'DELETE' then
          delete from clients where CLIENT_ID = i.CLIENT_ID;
        end if;
    end loop;

    for i in (select * from products_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID) LOOP
        if i.CHANGE_TYPE = 'INSERT' then
          insert into products values (i.PRODUCT_ID, i.PRODUCT_NAME, i.DESCRIPTION, i.PRICE);
        elsif i.CHANGE_TYPE = 'DELETE' then
          delete from products where PRODUCT_ID = i.PRODUCT_ID;
        end if;
    end loop;

    for i in (select * from orders_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID) LOOP
        if i.CHANGE_TYPE = 'INSERT' then
          insert into orders values (i.ORDER_ID, i.ORDER_DATE, i.CLIENT_ID, i.PRODUCT_ID, i.QUANTITY);
        elsif i.CHANGE_TYPE = 'DELETE' then
          delete from orders where orders.ORDER_ID = i.ORDER_ID;
        end if;
        commit;
    end loop;

    delete from clients_history
    where CHANGE_DATE > date_time;

    delete from products_history
    where CHANGE_DATE > date_time;

    delete from orders_history
    where CHANGE_DATE > date_time;

    enable_all_constraints('CLIENTS');
    enable_all_constraints('PRODUCTS');
    enable_all_constraints('ORDERS');
end;

CREATE OR REPLACE PROCEDURE disable_all_constraints(p_table_name IN VARCHAR2) IS
BEGIN
  FOR c IN (SELECT constraint_name
            FROM user_constraints
            WHERE table_name = p_table_name) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' DISABLE CONSTRAINT ' || c.constraint_name;
    DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || p_table_name || ' DISABLE CONSTRAINT ' || c.constraint_name);
  END LOOP;

  EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' DISABLE ALL TRIGGERS';
END;

CREATE OR REPLACE PROCEDURE enable_all_constraints(p_table_name IN VARCHAR2) IS
BEGIN
  FOR c IN (SELECT constraint_name
            FROM user_constraints
            WHERE table_name = p_table_name) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' ENABLE CONSTRAINT ' || c.constraint_name;
    DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || p_table_name || ' ENABLE CONSTRAINT ' || c.constraint_name);
  END LOOP;

  EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' ENABLE ALL TRIGGERS';
END;



create or replace procedure create_report(t_begin in timestamp, t_end in timestamp)
as
    v_result varchar2(4000);
    i_count number;
    u_count number;
    d_count number;
begin

    v_result :=    '<table>
                      <tr>
                        <th>Table</th>
                        <th>INSERT</th>
                        <th>UPDATE</th>
                        <th>DELETE</th>
                      </tr>
                      ';

    select count(*) into u_count
    from CLIENTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'UPDATE';

    select count(*) into i_count
    from CLIENTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'INSERT';

    select count(*) into d_count
    from CLIENTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<tr>
                               <td>Clients</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count ||'</td>
                             </tr>
                              ';

    select count(*) into u_count
    from PRODUCTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'UPDATE';

    select count(*) into i_count
    from PRODUCTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'INSERT';

    select count(*) into d_count
    from PRODUCTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<tr>
                               <td>Products</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count ||'</td>
                             </tr>
                              ';

    select count(*) into u_count
    from ORDERS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'UPDATE';

    select count(*) into i_count
    from ORDERS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'INSERT';

    select count(*) into d_count
    from ORDERS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<tr>
                               <td>Orders</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count ||'</td>
                             </tr>
                              ';

    v_result := v_result || '</table>';
    DBMS_OUTPUT.PUT_LINE(v_result);

end;