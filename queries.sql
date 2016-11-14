--Show Meta data tables

--List of distributed tables.
SELECT logicalrelid,partkey,colocationid FROM pg_dist_partition;

--Shards for the stores table
SELECT logicalrelid,shardid,shardminvalue,shardmaxvalue from pg_dist_shard where logicalrelid='stores'::regclass;

--Shard placements
SELECT shardid,nodename FROM pg_dist_shard_placement;

--Check colocation
SELECT s.logicalrelid,s.shardid,p.nodename from pg_dist_shard s, pg_dist_shard_placement p where s.shardid=p.shardid and s.shardminvalue::integer=-2147483648 and s.shardmaxvalue::integer=-2013265921;


--Break


-- Total number of stores
SELECT count(*) from stores;

--Explain the above query
EXPLAIN SELECT count(*) from stores;

--List the products for a particular store
SELECT name,
       price
FROM products
WHERE store_id = '8c69aa0d-3f13-4440-86ca-443566c1fc75';

--Explain Analyze the above query
EXPLAIN ANALYZE SELECT store_id,
       name,
       price
FROM products
WHERE store_id = '8c69aa0d-3f13-4440-86ca-443566c1fc75';

-- Create a new order for a particular store.
INSERT INTO orders VALUES('8c69aa0d-3f13-4440-86ca-443566c1fc75',uuid_generate_v4(),'processing',12.50,'Magic_1St','Magic_1st','{"carrier": "UPS"}',now(),now(),now());

-- Explain the above insert query
EXPLAIN INSERT INTO orders VALUES('8c69aa0d-3f13-4440-86ca-443566c1fc75',uuid_generate_v4(),'processing',12.50,'Magic_1St','Magic_1st','{"carrier": "UPS"}',now(),now(),now());

-- Update the shipping address for a particular order of a store.
UPDATE orders SET shipping_address='450 Townsend St, SF, CA, 94011', updated_at=now() WHERE order_id='59c58726-f746-4f00-b071-74bf83a07497' AND store_id='8c69aa0d-3f13-4440-86ca-443566c1fc75';

--Explain the above UPDATE query
EXPLAIN UPDATE orders SET shipping_address='450 Townsend St, SF, CA, 94011', updated_at=now() WHERE order_id='59c58726-f746-4f00-b071-74bf83a07497' AND store_id='8c69aa0d-3f13-4440-86ca-443566c1fc75';
-- Break


--Join Query
--Total number of 'Awesome Wool Pants' ordered in the month of november for a particular store
--Approach #1 - join on product_id, store_id and place a filter for store_id on only one of the table.
SELECT sum(l.quantity) from
line_items l INNER JOIN products p ON l.product_id=p.product_id AND l.store_id=p.store_id
WHERE p.name='Awesome Wool Pants' AND l.created_at>='2016-11-01 00:00:00' AND L.created_at<='2016-11-30 23:59:59'
AND l.store_id='8c69aa0d-3f13-4440-86ca-443566c1fc75';

--Approach #2 - join on just the product_id and place filters for store_id on both the  tables.

SELECT sum(l.quantity) from
line_items l INNER JOIN products p ON l.product_id=p.product_id
WHERE p.name='Awesome Wool Pants' AND l.created_at>='2016-11-01 00:00:00' AND L.created_at<='2016-11-30 23:59:59'
AND l.store_id='8c69aa0d-3f13-4440-86ca-443566c1fc75' AND p.store_id='8c69aa0d-3f13-4440-86ca-443566c1fc75';

--Explain the above query
EXPLAIN SELECT sum(l.quantity) from
line_items l INNER JOIN products p ON l.product_id=p.product_id
WHERE p.name='Awesome Wool Pants' AND l.created_at>='2016-11-01 00:00:00' AND L.created_at<='2016-11-30 23:59:59'
AND l.store_id='8c69aa0d-3f13-4440-86ca-443566c1fc75' AND p.store_id='8c69aa0d-3f13-4440-86ca-443566c1fc75';

--Three table join
--Top 10 revenue generating products shipped to CA code for a particular store.
SELECT p.name, SUM(l.line_amount) revenue
FROM line_items l, products p, orders o
where l.product_id=p.product_id and l.order_id=o.order_id
and o.shipping_address LIKE '%CA%' and o.status='fulfilled'
and l.store_id='11b8166e-ed3d-4bf1-b372-40fea90081f9' and p.store_id='11b8166e-ed3d-4bf1-b372-40fea90081f9' and  o.store_id='11b8166e-ed3d-4bf1-b372-40fea90081f9'
GROUP BY p.name
ORDER BY revenue DESC LIMIT 10;
