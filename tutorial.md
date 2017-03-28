## Show meta data tables

```sql
--List of distributed tables.
SELECT logicalrelid,partkey,colocationid FROM pg_dist_partition;

--Shards for the stores table
SELECT logicalrelid,shardid,shardminvalue,shardmaxvalue from pg_dist_shard where logicalrelid='stores'::regclass;

--Shard placements
SELECT shardid,nodename FROM pg_dist_shard_placement;

--Check colocation
SELECT s.logicalrelid,s.shardid,p.nodename from pg_dist_shard s, pg_dist_shard_placement p where s.shardid=p.shardid and s.shardminvalue::integer=-2147483648 and s.shardmaxvalue::integer=-2013265921;
```

## Basic queries

```sql
-- Total number of stores
SELECT count(*) from stores;

--Explain the above query
EXPLAIN SELECT count(*) from stores;

--List the products for a particular store
SELECT name,
       price
FROM products
WHERE store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e';

--Explain Analyze the above query
EXPLAIN ANALYZE SELECT store_id,
       name,
       price
FROM products
WHERE store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e';

--Reference tables
SELECT users.email, stores.name FROM stores JOIN users USING (user_id);

EXPLAIN ANALYZE SELECT users.email, stores.name FROM stores JOIN users USING (user_id);

-- Create a new order for a particular store.
INSERT INTO orders VALUES('ba581249-d824-45cf-aace-2ca30b7b3b0e',uuid_generate_v4(),'processing',12.50,'Magic_1St','Magic_1st','{"carrier": "UPS"}',now(),now(),now());

-- Explain the above insert query
EXPLAIN INSERT INTO orders VALUES('ba581249-d824-45cf-aace-2ca30b7b3b0e',uuid_generate_v4(),'processing',12.50,'Magic_1St','Magic_1st','{"carrier": "UPS"}',now(),now(),now());

-- Update the shipping address for a particular order of a store.
UPDATE orders SET shipping_address='599 3rd Street, SF, CA, 94107', updated_at=now() WHERE order_id='d7ca5088-cec7-42a1-aa8e-a68c9961fa3e' AND store_id='ba581249-d824-45cf-aace-2ca30b7b3b0e';

--Explain the above UPDATE query
EXPLAIN UPDATE orders SET shipping_address='599 3rd Street, SF, CA, 94107', updated_at=now() WHERE order_id='d7ca5088-cec7-42a1-aa8e-a68c9961fa3e' AND store_id='ba581249-d824-45cf-aace-2ca30b7b3b0e';
```

## Transactions

```sql
--- we have orders
SELECT COUNT(*) FROM line_items WHERE store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e' AND order_id='d7ca5088-cec7-42a1-aa8e-a68c9961fa3e';

BEGIN;
DELETE FROM line_items WHERE store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e' AND order_id='d7ca5088-cec7-42a1-aa8e-a68c9961fa3e';
SELECT COUNT(*) FROM line_items WHERE store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e' AND order_id='d7ca5088-cec7-42a1-aa8e-a68c9961fa3e';
--- we have no orders!
ROLLBACK;

--- we have orders again!
SELECT COUNT(*) FROM line_items WHERE store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e' AND order_id='d7ca5088-cec7-42a1-aa8e-a68c9961fa3e';
```

## JOIN queries

```sql
--Join Query
--Total number of 'Awesome Wool Pants' ordered in the month of march for a particular store
--Approach #1 - join on product_id, store_id and place a filter for store_id on only one of the table.
SELECT sum(l.quantity) from
line_items l INNER JOIN products p ON l.product_id=p.product_id AND l.store_id=p.store_id
WHERE p.name='Small Bronze Computer' AND l.created_at>='2017-03-01 00:00:00' AND L.created_at<='2017-03-30 23:59:59'
AND l.store_id='ba581249-d824-45cf-aace-2ca30b7b3b0e';

--Approach #2 - join on just the product_id and place filters for store_id on both the  tables.

SELECT sum(l.quantity) from
line_items l INNER JOIN products p ON l.product_id=p.product_id
WHERE p.name='Small Bronze Computer' AND l.created_at>='2017-03-01 00:00:00' AND L.created_at<='2017-03-30 23:59:59'
AND l.store_id='ba581249-d824-45cf-aace-2ca30b7b3b0e' AND p.store_id='ba581249-d824-45cf-aace-2ca30b7b3b0e';

--Explain the above query
EXPLAIN SELECT sum(l.quantity) from
line_items l INNER JOIN products p ON l.product_id=p.product_id
WHERE p.name='Small Bronze Computer' AND l.created_at>='2017-03-01 00:00:00' AND L.created_at<='2017-03-30 23:59:59'
AND l.store_id='ba581249-d824-45cf-aace-2ca30b7b3b0e' AND p.store_id='ba581249-d824-45cf-aace-2ca30b7b3b0e';

--Three table join
--Top 10 revenue generating products shipped to CA code for a particular store.
SELECT p.name, SUM(l.line_amount) revenue
FROM line_items l, products p, orders o
WHERE l.product_id = p.product_id AND l.order_id=o.order_id
AND o.shipping_address LIKE '%CA%' AND o.status = 'fulfilled'
AND l.store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e' and p.store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e' and o.store_id = 'ba581249-d824-45cf-aace-2ca30b7b3b0e'
GROUP BY p.name
ORDER BY revenue DESC LIMIT 10;
```

## Shard Rebalancer

(not available for the tutorial formations - we'll demo this using a production formation)

```sql
-- Newly added node
SELECT * from master_get_active_worker_nodes();

-- The newly added noded doesn't have any data yet!
\d pg_dist_shard_placement
SELECT COUNT(*), nodename, nodeport from pg_dist_shard_placement GROUP BY 2, 3;

--psql to the new worker and see the node empty.

--Run the shard_rebalancer on the stores table
select rebalance_table_shards('stores',0.0);
-- Rebalances all the tables which are colocated with the stores table - Colocation is maintained!
--So the following tables are rebalanced across the new node:
	--Stores
	--Products
	--Orders
	--Line_items

\d pg_dist_shard_placement
SELECT COUNT(*), nodename, nodeport from pg_dist_shard_placement GROUP BY 2, 3;

--psql to the new worker and see the node with data in there.
```

## Tenant Isolation

```sql
SELECT isolate_tenant_to_new_shard('stores', 'ba581249-d824-45cf-aace-2ca30b7b3b0e');
SELECT isolate_tenant_to_new_shard('stores', 'ba581249-d824-45cf-aace-2ca30b7b3b0e', 'CASCADE');

--- take the shardid from isolate_tenant_to_new_shard
SELECT nodename, nodeport from pg_dist_shard_placement WHERE shardid = 102147;

--- shardid, source_nodename, source_nodeport, target_nodename, target_nodeport
SELECT master_move_shard_placement(102147, 'ec2-54-80-197-88.compute-1.amazonaws.com', 5432, 'ec2-34-197-159-158.compute-1.amazonaws.com', 5432);
```

## Changing the schema

```sql
ALTER TABLE products ADD short_id text NULL;
SELECT master_modify_multiple_shards('UPDATE products SET short_id = substring(product_id::text from 0 for 14)');
ALTER TABLE products ALTER COLUMN short_id SET NOT NULL;
CREATE UNIQUE INDEX products_short_id ON products(store_id, short_id);
```
