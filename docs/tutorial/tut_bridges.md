# Bridge Tables

Bridge tables are query assistant tables that form part of the Business Vault.
Similar to PIT tables, their purpose is to improve performance of queries on the
Raw Data Vault by reducing the number of required joins for such queries to simple
equi-joins. A bridge table spans across a hub and one or more associated links.
This means that it is essentially a specialised form of link table, containing
hash keys from the hub and the links its spans. It does not contain information
from satellites, however, it may contain computations and aggregations (according to
grain) to increase query performance upstream when creating virtualised data marts. 