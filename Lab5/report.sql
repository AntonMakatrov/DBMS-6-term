CREATE OR REPLACE PACKAGE func_package IS
  procedure roll_back(date_time timestamp);
  procedure roll_back(date_time number);
  procedure report(t_begin in timestamp, t_end in timestamp);
  procedure report;
END func_package;

CREATE OR REPLACE PACKAGE BODY func_package IS
  PROCEDURE roll_back(date_time timestamp) IS
  begin
      rollback_by_date(date_time);
  END roll_back;

  PROCEDURE roll_back(date_time number) IS
    BEGIN
      DECLARE
        current_time timestamp := systimestamp;
      BEGIN
        current_time := current_time - NUMTODSINTERVAL(date_time / 1000, 'SECOND');
        rollback_by_date(current_time);
      END;
  END roll_back;

  PROCEDURE report(t_begin in timestamp, t_end in timestamp) IS
      v_cur timestamp;
  begin

      SELECT CAST(SYSDATE AS TIMESTAMP) into v_cur FROM dual;

      if t_end > v_cur then
          create_report(t_begin, v_cur);
          insert into reports_history(report_date) values(v_cur);
      else
          create_report(t_begin, t_end);
          insert into reports_history(report_date) values(t_end);
      end if;
  END report;

  PROCEDURE report IS
    v_begin timestamp;
    v_cur timestamp;
  begin

      SELECT CAST(SYSDATE AS TIMESTAMP) into v_cur FROM dual;

      select REPORT_DATE
      into v_begin
      from REPORTS_HISTORY
      where id = (select MAX(id) from REPORTS_HISTORY);

      create_report(v_begin, v_cur);

      insert into reports_history(report_date) values(v_cur);
  END report;

END func_package;