!!! info
    This walk-through intends to give you a detailed understanding of how to use 
    dbtvault and the provided macros to develop a Data Vault Data Warehouse from the ground up. 
    If you're looking to quickly experiment and learn using pre-written models, 
    take a look at our [worked example](../worked_example/we_worked_example.md).

In this section we teach you how to use dbtvault, by example, explaining the use of macros and the
different components of the Data Vault in detail.

We will:

- process a raw staging layer.
- create a raw vault

## Pre-requisites 

1. Some prior knowledge of Data Vault 2.0 architecture. 
Read more: [How can I get up to speed on Data Vault 2.0?](../index.md#how-can-i-get-up-to-speed-on-data-vault-20)

2. We assume you already have a raw staging layer, PSA (Persistent Staging Area) or Data Lake.

3. You should read our [best practices](../best_practices.md) guidance.

## Setting up sources (in dbt)

We will be using the `source` feature of dbt extensively throughout the documentation to make access to source
data much easier, cleaner and more modular.

We have provided an example below which shows a configuration similar to that used for the examples in our documentation, 
however this feature is documented extensively in [the documentation for dbt](https://docs.getdbt.com/docs/building-a-dbt-project/using-sources/).

We recommend that you place the `schema.yml` file you create for your sources, 
in the root of your `models` folder, however you can place it wherever needed for your specific project and models.

`schema.yml`

```yaml
version: 2

sources:
  - name: my_source
    database: MY_DATABASE
    schema: MY_SCHEMA
    tables:
      - name: raw_orders
      - name: ...
```

## Installation 

Read the installation instructions on [dbt hub](https://hub.getdbt.com/datavault-uk/dbtvault/latest/)