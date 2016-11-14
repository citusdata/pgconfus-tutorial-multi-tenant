-- Needs to be run by the postgres user:
--
-- CREATE OR REPLACE FUNCTION master_run_on_worker(worker_name text[], port integer[],
--                         command text[], parallel boolean,
--                         OUT node_name text, OUT node_port integer,
--                         OUT success boolean, OUT result text )
--   RETURNS SETOF record
--   LANGUAGE C STABLE STRICT
--   AS 'citus.so', $$master_run_on_worker$$;

CREATE OR REPLACE FUNCTION citus_run_on_all_workers(command text,
													parallel bool default true,
													OUT nodename text,
													OUT nodeport int,
													OUT success bool,
													OUT result text)
	RETURNS SETOF record
	LANGUAGE plpgsql
	AS $function$
DECLARE
	workers text[];
	ports int[];
	commands text[];
BEGIN
	WITH citus_workers AS (
		SELECT * FROM master_get_active_worker_nodes() ORDER BY node_name, node_port)
	SELECT array_agg(node_name), array_agg(node_port), array_agg(command)
	INTO workers, ports, commands
	FROM citus_workers;

	RETURN QUERY SELECT * FROM master_run_on_worker(workers, ports, commands, parallel);
END;
$function$;

CREATE TYPE category AS ENUM ('Art', 'Electronics', 'Entertainment', 'Fashion', 'Home & Garden', 'Sporting Goods', 'Other');
CREATE TYPE status AS ENUM ('open', 'processing', 'fulfilled');

SELECT citus_run_on_all_workers($$CREATE TYPE category AS ENUM ('Art', 'Electronics', 'Entertainment', 'Fashion', 'Home & Garden', 'Sporting Goods', 'Other')$$);
SELECT citus_run_on_all_workers($$CREATE TYPE status AS ENUM ('open', 'processing', 'fulfilled')$$);

CREATE TABLE users (
  user_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  encrypted_password text NOT NULL ,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id)
);

CREATE TABLE stores (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  category category NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id)
);

SELECT create_distributed_table('stores', 'store_id');

CREATE TABLE products (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  product_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text NOT NULL,
  product_details jsonb NOT NULL,
  price numeric(20,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id, product_id),
  FOREIGN KEY (store_id) REFERENCES stores (store_id)
);

SELECT create_distributed_table('products', 'store_id');

CREATE TABLE orders (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  status status NOT NULL,
  total_amount numeric(20,2) NOT NULL,
  shipping_address text NOT NULL,
  billing_address text NOT NULL,
  shipping_info jsonb NOT NULL,
  ordered_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id, order_id),
  FOREIGN KEY (store_id) REFERENCES stores (store_id)
);

SELECT create_distributed_table('orders', 'store_id');

CREATE TABLE line_items (
  store_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  line_item_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  product_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  quantity integer NOT NULL,
  line_amount numeric(20,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id, line_item_id),
  FOREIGN KEY (store_id) REFERENCES stores (store_id),
  FOREIGN KEY (store_id, order_id) REFERENCES orders (store_id, order_id),
  FOREIGN KEY (store_id, product_id) REFERENCES products (store_id, product_id)
);

SELECT create_distributed_table('line_items', 'store_id');
