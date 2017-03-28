# PGConf US Tutorial

You will require a Citus Cloud formation for this tutorial, with the tutorial data pre-loaded.

In case you want to follow this at home, contact us in Slack or on the website,
and we'd be happy to set you up with a tutorial formation.

## 1. Create the schema and load data

Follow each section in `schema_and_data.md`

## 2. Follow the tutorial

Follow each section in `tutorial.md`

## How to access worker nodes

Run `SELECT nodename, nodeport FROM pg_dist_node` and copy one of the hostnames starting with `ec2-` and ending in `.com`.

Take the connection string you get from the Citus Cloud dashboard, and replace the coordinator hostname (starting with `c.` and ending in `.com`) with the worker hostname. Then simply use psql to connect to the worker (username, password, port and database name are the same).
