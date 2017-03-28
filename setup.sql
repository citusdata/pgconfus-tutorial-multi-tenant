CREATE SCHEMA tutorial;

CREATE TABLE tutorial.users (
  user_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  encrypted_password text NOT NULL ,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id)
);

SELECT create_reference_table('tutorial.users');

CREATE TABLE tutorial.stores (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  category text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id)
);

SELECT create_distributed_table('tutorial.stores', 'store_id');

CREATE TABLE tutorial.products (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  product_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text NOT NULL,
  product_details jsonb NOT NULL,
  price numeric(20,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id, product_id),
  FOREIGN KEY (store_id) REFERENCES tutorial.stores (store_id)
);

SELECT create_distributed_table('tutorial.products', 'store_id');

CREATE TABLE tutorial.orders (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  status text NOT NULL,
  total_amount numeric(20,2) NOT NULL,
  shipping_address text NOT NULL,
  billing_address text NOT NULL,
  shipping_info jsonb NOT NULL,
  ordered_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id, order_id),
  FOREIGN KEY (store_id) REFERENCES tutorial.stores (store_id)
);

SELECT create_distributed_table('tutorial.orders', 'store_id');

CREATE TABLE tutorial.line_items (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  line_item_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  product_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  quantity integer NOT NULL,
  line_amount numeric(20,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id, line_item_id),
  FOREIGN KEY (store_id) REFERENCES tutorial.stores (store_id),
  FOREIGN KEY (store_id, order_id) REFERENCES tutorial.orders (store_id, order_id),
  FOREIGN KEY (store_id, product_id) REFERENCES tutorial.products (store_id, product_id)
);

SELECT create_distributed_table('tutorial.line_items', 'store_id');

\copy tutorial.users (user_id, email, encrypted_password) FROM 'data/users.csv' WITH (format CSV)
\copy tutorial.stores (store_id, user_id, name, category) FROM 'data/stores.csv' WITH (format CSV)
\copy tutorial.products (store_id, product_id, name, description, product_details, price) FROM 'data/products.csv' WITH (format CSV)
\copy tutorial.orders (store_id, order_id, status, total_amount, shipping_address, billing_address, shipping_info, ordered_at) FROM 'data/orders.csv' WITH (format CSV)
\copy tutorial.line_items (store_id, order_id, product_id, quantity, line_amount) FROM 'data/line_items.csv' WITH (format CSV)
