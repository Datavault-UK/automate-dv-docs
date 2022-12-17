!!! info
    This walk-through intends to give you a detailed understanding of the Data Vault 2.0 
    concepts which dbtvault supports, and how to use dbtvault to create a Data Vault 2.0 Data Warehouse.
    If you're looking get started quickly with sample data in the cloud, take a look at 
    our [worked example](../worked_example/index.md).

In this section we teach you how to use dbtvault, by example, explaining the use of macros and the
different components of the Data Vault in detail.

We will:

- process a raw staging layer.
- create a raw vault

## Pre-requisites 

1. Some prior knowledge of Data Vault 2.0 architecture. 
Read more: [dbtvault pre-requisite knowledge](../index.md#pre-requisite)

2. We assume you already have a raw staging layer, PSA or Data Lake.

3. You should read our [best practices](../best_practises/index.md) guidance.

## Installation 

- [Install dbt](https://docs.getdbt.com/dbt-cli/installation) and [set up dbt on your preferred platform](https://docs.getdbt.com/dbt-cli/configure-your-profile)

- [Install dbtvault](https://hub.getdbt.com/datavault-uk/dbtvault/latest/)

--8<-- "includes/abbreviations.md"