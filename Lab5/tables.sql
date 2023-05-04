drop table orders;
drop table clients;
drop table products;


CREATE TABLE clients (
  client_id NUMBER(10) CONSTRAINT PK_clients PRIMARY KEY,
  first_name VARCHAR2(50),
  last_name VARCHAR2(50),
  email VARCHAR2(100) UNIQUE,
  phone_number VARCHAR2(20)
);

CREATE TABLE products (
  product_id NUMBER(10) CONSTRAINT PK_products PRIMARY KEY,
  product_name VARCHAR2(100),
  description VARCHAR2(500),
  price NUMBER
);

CREATE TABLE orders (
  order_id NUMBER(10) CONSTRAINT PK_orders PRIMARY KEY,
  order_date DATE,
  client_id NUMBER(10),
  product_id NUMBER(10),
  quantity NUMBER(10),
  CONSTRAINT fk_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
  CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);
