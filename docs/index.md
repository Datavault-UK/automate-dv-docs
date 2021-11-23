# Welcome to dbtvault!
dbtvault is a dbt package that generates & executes the ETL you need to run a Data Vault 2.0 Data Warehouse
on a Snowflake database.

!!! Note
    You need to be running dbt to use the package.
    
    [dbt](https://www.getdbt.com/) is a registered trademark of [dbt Labs](https://www.getdbt.com/dbt-labs/about-us/).
    
    Go check them out!

dbt is designed for ease of use in data engineering: for when you need to develop a data pipeline. 
They offer a command-line utility developed in Python that can run on your desktop or inside a VM in your network 
and is free to download and use. Alternatively, you can use their web-based [dbt Cloud](https://docs.getdbt.com/docs/dbt-cloud/cloud-overview)
service for an even smoother experience.

Our package runs inside the dbt environment, so you can use dbt to run other parts of the Data Vault pipeline, combined with the 
dbtvault package for the Data Vault specific steps.

!!! tip
    #### Sign up for early-bird announcements or join our Slack 

    [![Sign up](https://img.shields.io/badge/Email-Sign--up-blue)](https://www.data-vault.co.uk/dbtvault/)
    [![Join our Slack](https://img.shields.io/badge/Slack-Join-yellow?style=flat&logo=slack)](https://join.slack.com/t/dbtvault/shared_invite/enQtODY5MTY3OTIyMzg2LWJlZDMyNzM4YzAzYjgzYTY0MTMzNTNjN2EyZDRjOTljYjY0NDYyYzEwMTlhODMzNGY3MmU2ODNhYWUxYmM2NjA)

## What is Data Vault 2.0?
Data Vault 2.0 is an Agile method that can be used to deliver a highly scalable enterprise Data Warehouse. 

The method covers the full approach for developing a Data Warehouse: architecture, data modelling, development, 
and includes a number of unique techniques. 

If you want to learn about Data Vault 2.0, your best starting point is the book "Building a Scalable Data Warehouse with 
Data Vault 2.0" (see details [below](#books-from-amazon)).

## Data Vault 2.0 supports code automation 
Essentially, the method uses a small set of standard building blocks to model your data warehouse (Hubs,
Links and Satellites in the Raw Data Vault) and, because they are standardised, you can load these blocks with 
templated SQL. The result is a template-driven implementation, populated by metadata. 
You provide the metadata (table names and mapping details) and SQL is generated automatically. 
This leads to better quality code, fewer mistakes, and greatly improved productivity: i.e. Agility.

## What does dbtvault do?
The dbtvault package generates and runs Data Vault ETL code from your metadata. 

Just like other dbt projects, you write a model for each ETL step. You provide the metadata for each model as declared 
variables and include code to invoke a macro from the dbtvault package. 
The macro does the rest of the work: it processes the metadata, generates Snowflake SQL and then dbt executes the load 
respecting any and all dependencies. 

dbt even runs the load in parallel. As Data Vault 2.0 is designed for parallel load and Snowflake is highly performant, 
your ETL load will finish in rapid time. 

dbtvault reduces the need to write Snowflake SQL by hand to load the Data Vault, which is a repetitive, time-consuming 
and potentially error-prone task.


## What features does dbt running the dbtvault package offer?
dbt works with the dbtvault package to:

- Generate SQL to process the staging layer and load the data vault
- Ensures consistency and correctness in the generated SQL
- Identify dependencies between SQL statements
- Create Raw Data Vault tables when a release first identifies them
- Execute all generated SQL statements as a complete set
- Execute data load in parallel up to a user-defined number of parallel threads
- Generate data flow diagrams showing data lineage
- Automatically build a documentation website

!!! warning "Expected prior knowledge of the Data Vault 2.0 method"
    
    If you are going to use the dbtvault package for your Data Vault 2.0 project, then we expect you to have some prior 
    knowledge about the Data Vault 2.0 method.

## How can I get up to speed on Data Vault 2.0?
You can get further information about the Data Vault 2.0 method from the following resources:

### Books (from Amazon)

- [Building a Scalable Data Warehouse with Data Vault 2.0, Dan Linstedt and Michael Olschimke](https://www.amazon.co.uk/Building-Scalable-Data-Warehouse-Vault-ebook/dp/B015KKYFGO/)
- [The Data Vault Guru: a pragmatic guide on building a data vault, Patrick Cuba](https://www.amazon.co.uk/Data-Vault-Guru-pragmatic-building/dp/B08KJLJW9Q)
- [Better Data Modelling: An Introduction to Agile Data Engineering Using Data Vault 2.0, Kent Graziano](https://www.amazon.co.uk/Better-Data-Modeling-Introduction-Engineering-ebook/dp/B018BREV1C)

### Blogs and Downloads

- [What is Data Vault?](https://www.data-vault.co.uk/what-is-data-vault/)
- [Agile Modeling: Not an Option Anymore](https://www.vertabelo.com/blog/data-vault-series-agile-modeling-not-an-option-anymore/)

## Roadmap and Changelog

We keep an up-to-date log of past and planned changes:

- [Changelog](changelog/stable.md)
- [Roadmap](roadmap.md)