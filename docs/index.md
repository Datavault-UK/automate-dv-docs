# Welcome to AutomateDV!
AutomateDV is a dbt package that generates & executes the ETL you need to build a Data Vault 2.0 Data Warehouse.

!!! Note
    You need to be running dbt to use the package. If needed, you can find get more guidance 
    on how to get set up from the dbt [documentation](https://docs.getdbt.com/docs/introduction).
    
    [dbt](https://www.getdbt.com/) is a registered trademark of [dbt Labs](https://www.getdbt.com/dbt-labs/about-us/).
    
    Go check them out!

dbt is designed for ease of use in data engineering: for when you need to develop a data pipeline. 

dbt offers a command-line utility developed in Python that can run on your desktop or inside a VM in your network 
and is free to download and use. Alternatively, you can use their SaaS offering [dbt Cloud](https://docs.getdbt.com/docs/dbt-cloud/cloud-overview)
which functions as a dbt IDE.

Our package runs inside the dbt environment, so you can use dbt to run other parts of the Data Vault pipeline, combined with the 
AutomateDV package for the Data Vault 2.0 specific steps.

!!! tip "Join our Slack community!"
    [Join now](https://join.slack.com/t/dbtvault/shared_invite/enQtODY5MTY3OTIyMzg2LWJlZDMyNzM4YzAzYjgzYTY0MTMzNTNjN2EyZDRjOTljYjY0NDYyYzEwMTlhODMzNGY3MmU2ODNhYWUxYmM2NjA){ .md-button .md-button--primary }

## What is Data Vault 2.0?
Data Vault 2.0 is an Agile method that can be used to deliver a highly scalable enterprise Data Warehouse. 

The method covers the full approach for developing a Data Warehouse: architecture, data modelling, development, 
and includes a number of unique techniques. 

If you want to learn about Data Vault 2.0, your best starting point is the book Building a Scalable Data Warehouse with 
Data Vault 2.0 (see details [below](#pre-requisite)).

## Why do Data Vault 2.0 and dbt integrate well? 
The Data Vault 2.0 method uses a small set of standard building blocks to model your data warehouse 
(Hubs, Links and Satellites in the Raw Data Vault) and, because they are standardised, you can load these blocks with 
templated SQL. dbt allows for a template-driven implementation using Jinja. This leads to better quality code, 
fewer mistakes, and greatly improved productivity: i.e. Agility.

## Where does AutomateDV fit in?
The AutomateDV package generates and runs Data Vault ETL code from your metadata (table names and mapping details) which is 
then provided to your dbt models contains calls to AutomateDV macros.
The macro does the rest of the work: it processes the metadata, generates SQL and then dbt executes the load 
respecting any and all dependencies. 

dbt even runs the load in parallel. As Data Vault 2.0 is designed for parallel load and Snowflake is highly parallelised, 
your ETL load will finish in rapid time. Your experience may vary form platform to platform, however we aim to be as
consistent as possible.

AutomateDV reduces the need to write SQL by hand to load the Data Vault, which is a repetitive, time-consuming 
and potentially error-prone task.

## What are the advantages of AutomateDV?
dbt works with the AutomateDV package to:

- Generate SQL to process the staging layer and load the data vault.
- Ensure consistency and correctness in the generated SQL.
- Identify dependencies between SQL statements.
- Create Raw Data Vault tables when a release first identifies them.
- Execute all generated SQL statements as a complete set.
- Execute data load in parallel up to a user-defined number of parallel threads.
- Generate data flow diagrams showing data lineage.
- Automatically build a documentation website.

## Pre-requisite
If you are going to use the AutomateDV package for your Data Vault 2.0 project, then we expect you to have some prior 
knowledge about the Data Vault 2.0 method.

In the case you do need to get up to speed with Data Vault 2.0, we recommend the following resources for further 
information:

### Books (from Amazon)

- [Building a Scalable Data Warehouse with Data Vault 2.0, Dan Linstedt and Michael Olschimke](https://www.amazon.co.uk/Building-Scalable-Data-Warehouse-Vault-ebook/dp/B015KKYFGO/)
- [The Data Vault Guru: a pragmatic guide on building a data vault, Patrick Cuba](https://www.amazon.co.uk/Data-Vault-Guru-pragmatic-building/dp/B08KJLJW9Q)
- [Better Data Modelling: An Introduction to Agile Data Engineering Using Data Vault 2.0, Kent Graziano](https://www.amazon.co.uk/Better-Data-Modeling-Introduction-Engineering-ebook/dp/B018BREV1C)

### Blogs and Downloads

- [What is Data Vault?](https://www.data-vault.com/what-is-data-vault/)
- [Agile Modeling: Not an Option Anymore (via WayBackMachine)](https://web.archive.org/web/20230329184416/https://vertabelo.com/blog/data-vault-series-agile-modeling-not-an-option-anymore/)
    - Original article now unavailable, however it can be found on the WayBackMachine (linked above).
      It is important to note that the content and topic of this article is also compiled and extended in Kent's book, listed above.

## Roadmap and Changelog

We keep an up-to-date log of past and planned changes:

- [Changelog](changelog/index.md)
- [Roadmap](roadmap.md)

--8<-- "includes/abbreviations.md"