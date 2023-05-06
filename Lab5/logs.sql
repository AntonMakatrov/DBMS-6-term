drop table clients_history;
drop table products_history;
drop table orders_history;
drop table reports_history;

CREATE TABLE clients_history (
  action_id number,
  client_id NUMBER(10),
  first_name VARCHAR2(50),
  last_name VARCHAR2(50),
  email VARCHAR2(100),
  phone_number VARCHAR2(20),
  change_date DATE,
  change_type VARCHAR2(10)
);

CREATE TABLE products_history (
  action_id number,
  product_id NUMBER(10),
  product_name VARCHAR2(100),
  description VARCHAR2(500),
  price NUMBER,
  change_date DATE,
  change_type VARCHAR2(10)
);

CREATE TABLE orders_history (
  action_id number,
  order_id NUMBER(10),
  order_date DATE,
  client_id NUMBER(10),
  product_id NUMBER(10),
  quantity NUMBER(10),
  change_date DATE,
  change_type VARCHAR2(10)
);

create table reports_history
(
    id number GENERATED ALWAYS AS IDENTITY,
    report_date timestamp,
    CONSTRAINT PK_reports PRIMARY KEY (id)
);

CREATE OR REPLACE TRIGGER tr_clients_insert
AFTER INSERT ON clients
FOR EACH ROW
BEGIN
  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (history_seq.nextval, :NEW.client_id, :NEW.first_name, :NEW.last_name, :NEW.email, :NEW.phone_number, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_clients_update
AFTER UPDATE ON clients
FOR EACH ROW
DECLARE
  v_id number;
BEGIN
  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (HISTORY_SEQ.nextval, :OLD.client_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number, SYSDATE, 'DELETE');

  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (HISTORY_SEQ.nextval, :OLD.client_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number, SYSDATE, 'UPDATE');

  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (HISTORY_SEQ.nextval, :NEW.client_id, :NEW.first_name, :NEW.last_name, :NEW.email, :NEW.phone_number, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_clients_delete
AFTER DELETE ON clients
FOR EACH ROW
BEGIN
  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (history_seq.nextval, :OLD.client_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number, SYSDATE, 'DELETE');
END;

CREATE OR REPLACE TRIGGER tr_products_insert
AFTER INSERT ON products
FOR EACH ROW
BEGIN
  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (history_seq.nextval, :new.product_id, :new.product_name, :new.description, :new.price, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_products_update
AFTER UPDATE ON products
FOR EACH ROW
DECLARE
  v_id number;
BEGIN
  v_id := HISTORY_SEQ.nextval;
  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (v_id, :old.product_id, :old.product_name, :old.description, :old.price, SYSDATE, 'DELETE');

  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (v_id, :old.product_id, :old.product_name, :old.description, :old.price, SYSDATE, 'UPDATE');

  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (v_id, :new.product_id, :new.product_name, :new.description, :new.price, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_products_delete
AFTER DELETE ON products
FOR EACH ROW
BEGIN
  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (history_seq.nextval, :old.product_id, :old.product_name, :old.description, :old.price, SYSDATE, 'DELETE');
END;

CREATE OR REPLACE TRIGGER tr_orders_insert
AFTER INSERT ON orders
FOR EACH ROW
DECLARE
BEGIN
  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (history_seq.NEXTVAL, :NEW.order_id, :NEW.order_date, :NEW.client_id, :NEW.product_id, :NEW.quantity, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_orders_update
AFTER UPDATE ON orders
FOR EACH ROW
DECLARE
  v_id number;
BEGIN
  v_id := HISTORY_SEQ.nextval;
  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (v_id, :OLD.order_id, :OLD.order_date, :OLD.client_id, :OLD.product_id, :OLD.quantity, SYSDATE, 'DELETE');

  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (v_id, :OLD.order_id, :OLD.order_date, :OLD.client_id, :OLD.product_id, :OLD.quantity, SYSDATE, 'UPDATE');

  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (v_id, :NEW.order_id, :NEW.order_date, :NEW.client_id, :NEW.product_id, :NEW.quantity, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_orders_delete
AFTER DELETE ON orders
FOR EACH ROW
DECLARE
BEGIN
  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (history_seq.NEXTVAL, :OLD.order_id, :OLD.order_date, :OLD.client_id, :OLD.product_id, :OLD.quantity, SYSDATE, 'DELETE');
END;
