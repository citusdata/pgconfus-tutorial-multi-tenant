# PGConf SV Tutorial

## Create the schema

```
\i schema.sql
```

## Load sample data using COPY

```
\copy users (user_id, email, encrypted_password) FROM 'data/users.csv' WITH (format CSV)
\copy stores (store_id, user_id, name, category) FROM 'data/stores.csv' WITH (format CSV)
\copy products (store_id, product_id, name, description, product_details, price) FROM 'data/products.csv' WITH (format CSV)
\copy orders (store_id, order_id, status, total_amount, shipping_address, billing_address, shipping_info, ordered_at) FROM 'data/orders.csv' WITH (format CSV)
\copy line_items (store_id, order_id, product_id, quantity, line_amount) FROM 'data/line_items.csv' WITH (format CSV)
```

## INSERT INTO SELECT to load additional data

```
INSERT INTO users SELECT * FROM tutorial.users;
INSERT INTO stores SELECT * FROM tutorial.stores;
INSERT INTO products SELECT * FROM tutorial.products;
INSERT INTO orders SELECT * FROM tutorial.orders;
INSERT INTO line_items SELECT * FROM tutorial.line_items;
```
