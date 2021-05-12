Point in time (PIT) tables are query assistant tables that form part of the
Business Vault. Their purpose is to improve performance of queries on the
Raw Data Vault by reducing the number of required joins for the query to simple
equi-joins. 

A PIT table spans across multiple satellites of a hub or link,
so it is essentially a specialised form of satellite table. It contains
snapshots of hash keys and load date timestamps from the satellites it spans
for dates specified by business requirements upstream.