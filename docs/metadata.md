dbtvault is metadata driven. On this page, we provide an overview of how to provide and store that data.

For further detail about how to use the macros in this section, see [table templates](macros.md#table-templates).

### Approaches

This page will describe just *one* way of providing metadata to the macros. There are many different ways to do it, 
and it comes down to user and organisation preference.

!!! note
    The macros *do not care* how the metadata parameters are provided, as long as they are of the correct type.
    Parameter data types are defined on the [macros](macros.md) page.

It is worth noting that with larger projects, storing all of the metadata in the `dbt_project.yml` file can quickly 
become unwieldy. See [the problem with metadata](#the-problem-with-metadata) for a more detailed discussion.


#### dbt_project.yml

Variables can be provided to macros via the `dbt_project.yml` file instead of being specified in
the models themselves. This keeps the metadata all in one place and simplifies the use of dbtvault.

!!! warning "Using variables in dbt_project.yml"
    From dbtvault v0.6.1 onwards, if you are using dbt v0.17.0 you must use `config-version: 1`. 
    This is a temporary workaround due to removal of model-level variable scoping in dbt core functionality.
    We hope to have a permanent fix for this in future.
    
    Read more:
    
    - [Our suggestion to dbt](https://github.com/fishtown-analytics/dbt/issues/2377) (closed in favour of [2401](https://github.com/fishtown-analytics/dbt/issues/2401))
    - [dbt documentation on the change](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-0-17-0/#better-variable-scoping-semantics)

#### Per-model

You may also provide metadata on a per-model basis. 

!!! info "Coming Soon"
    Examples of this approach will be added soon
     

### Staging

#### Parameters

[stage macro parameters](macros.md#stage)

#### Metadata

=== "dbt_project.yml"
    === "All variables"
        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:
                  source_model: "raw_source"
                  hashed_columns:
                    CUSTOMER_PK: "CUSTOMER_ID"
                    CUST_CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_DOB"
                        - "CUSTOMER_ID"
                        - "CUSTOMER_NAME"
                        - "!9999-12-31"
                    CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_ID"
                        - "NATIONALITY"
                        - "PHONE"
                  derived_columns:
                    SOURCE: "!STG_BOOKING"
                    EFFECTIVE_FROM: "BOOKING_DATE"
        ```
    === "Only Source"
        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:
                  source_model: "raw_source"
        ```
    === "Only hashing"
        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:
                  include_source_columns: false
                  source_model: "raw_source"
                  hashed_columns:
                    CUSTOMER_PK: "CUSTOMER_ID"
                    CUST_CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_DOB"
                        - "CUSTOMER_ID"
                        - "CUSTOMER_NAME"
                        - "!9999-12-31"
                    CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_ID"
                        - "NATIONALITY"
                        - "PHONE"
        ```
    === "Only derived"
        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:   
                  include_source_columns: false
                  source_model: "raw_source"
                  derived_columns:
                    SOURCE: "!STG_BOOKING"
                    EFFECTIVE_FROM: "BOOKING_DATE"
        ```

#### Constants

In the above examples, there are strings prefixed with `!`. This is syntactical sugar provided in dbtvault which 
makes it easier and cleaner to specify constant values when creating a staging layer. 
These constants can be provided as values of columns specified under `derived_columns` 
and `hashed_columns` as showcased in the provided examples.


### Hubs

#### Parameters

[hub macro parameters](macros.md#hub)

#### Metadata

=== "Single Source - dbt_project.yml"
    ```yaml
    hub_customer:
      vars:
        source_model: 'stg_customer_hashed'
        src_pk: 'CUSTOMER_PK'
        src_nk: 'CUSTOMER_KEY'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```

=== "Multi Source - dbt_project.yml"
    ```yaml
    hub_customer:
      vars:
        source_model:
          - 'stg_web_customer_hashed'
          - 'stg_crm_customer_hashed'
        src_pk: 'CUSTOMER_PK'
        src_nk: 'CUSTOMER_KEY'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ``` 

=== "Composite NK - dbt_project.yml"
    ```yaml
    hub_customer:
      vars:
        source_model: 'stg_customer_hashed'
        src_pk: 'CUSTOMER_PK'
        src_nk:
          - 'CUSTOMER_KEY'
          - 'CUSTOMER_DOB'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```

### Links

#### Parameters

[link macro parameters](macros.md#link)

#### Metadata

=== "Single Source - dbt_project.yml"
    ```yaml
    link_customer_nation:
      vars:
        source_model: 'v_stg_orders'
        src_pk: 'LINK_CUSTOMER_NATION_PK'
        src_fk:
          - 'CUSTOMER_PK'
          - 'NATION_PK'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```

=== "Multi Source - dbt_project.yml"
    ```yaml
    link_customer_nation:
      vars:
        source_model:
          - 'v_stg_orders'
          - 'v_stg_transactions'
        src_pk: 'LINK_CUSTOMER_NATION_PK'
        src_fk:
          - 'CUSTOMER_PK'
          - 'NATION_PK'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```

### Transactional links
###### (also known as non-historised links)

#### Parameters

[t_link macro parameters](macros.md#t_link)

#### Metadata

=== "dbt_project.yml"
    ```yaml
    t_link_transactions:
      vars:
        source_model: 'v_stg_transactions'
        src_pk: 'TRANSACTION_PK'
        src_fk:
          - 'CUSTOMER_PK'
          - 'ORDER_PK'
        src_payload:
          - 'TRANSACTION_NUMBER'
          - 'TRANSACTION_DATE'
          - 'TYPE'
          - 'AMOUNT'
        src_eff: 'EFFECTIVE_FROM'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```

### Satellites

#### Parameters

[sat macro parameters](macros.md#sat)

#### Metadata
=== "dbt_project.yml"
    === "Standard"
        ```yaml
        sat_order_customer_details:
          vars:
            source_model: 'v_stg_orders'
            src_pk: 'CUSTOMER_PK'
            src_hashdiff: 'CUSTOMER_HASHDIFF'
            src_payload:
              - 'NAME'
              - 'ADDRESS'
              - 'PHONE'
              - 'ACCBAL'
              - 'MKTSEGMENT'
              - 'COMMENT'
            src_eff: 'EFFECTIVE_FROM'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```
    === "Hashdiff Aliasing"
        ```yaml
        sat_order_customer_details:
          vars:
            source_model: 'v_stg_orders'
            src_pk: 'CUSTOMER_PK'
            src_hashdiff: 
              source_column: "CUSTOMER_HASHDIFF"
              alias: "HASHDIFF"
            src_payload:
              - 'NAME'
              - 'ADDRESS'
              - 'PHONE'
              - 'ACCBAL'
              - 'MKTSEGMENT'
              - 'COMMENT'
            src_eff: 'EFFECTIVE_FROM'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

Hashdiff aliasing allows you to set an alias for the `HASHDIFF` column.
[Read more](best_practices.md#hashdiff-aliasing)

### Effectivity Satellites

#### Parameters

[eff_sat macro parameters](macros.md#eff_sat)

#### Metadata
=== "dbt_project.yml"
    ```yaml
    eff_sat_customer_nation:
      vars:
        source_model: 'v_stg_transactions'
        src_pk: 'TRANSACTION_PK'
        src_dfk: 'CUSTOMER_PK'
        src_sfk: 'NATION_PK'
        src_start_date: 'START_DATE'
        src_end_date: 'END_DATE'
        src_eff: 'EFFECTIVE_FROM'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```
___

### The problem with metadata

As metadata is stored in the `dbt_project.yml`, you can probably foresee the file getting very large for bigger 
projects. If your metadata is defined and stored in each model, it becomes harder to generate and develop with, 
but it can be easier to manage. Whichever approach is chosen, metadata storage and retrieval is difficult without a dedicated tool. 
To help manage large amounts of metadata, we recommend the use of external corporate tools such as WhereScape, 
Matillion, or Erwin Data Modeller. We have future plans to improve metadata handling but in the meantime 
any feedback or ideas are welcome.