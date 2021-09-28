# Migrating from v0.5 to v0.6

The release of dbtvault v0.6 has brought in a number of major changes:

- Staging has been significantly improved, as we have introduced the new 
[stage](../macros.md#stage) macro. 

- [hub](../macros.md#hub) and [link](../macros.md#link) macros have been refactored to 
allow for multi-date and intra-day loading. 
    
- The  `source` variable used by table macros in the  
`dbt_project.yml` file has previously caused some confusion. 
This variable has been renamed to `source_model` and must be used in all models. 
See below for more details. A big thank you to @balmasi for this suggestion.

## Staging 

With this update we've finally completed our move from writing metadata in-model, to writing metadata in-YAML 
instead. The new [stage](../macros.md#stage) macro entirely replaces the functionality of the [old staging macros](https://dbtvault.readthedocs.io/en/v0.5/macros/#staging-macros).
It is no longer necessary to call a combination of `multi-hash`, `add_columns` and `from` in a staging model.

Previously, your staging model looked like this:

```sql    
{{- config(materialized='view', schema='my_schema', enabled=true, tags=['staging']) -}}
                                                                                    
{%- set source_table = source('raw_sources', 'customer_bookings')                   -%}
                                                                                    
{{ dbtvault.multi_hash([('CUSTOMER_ID', 'CUSTOMER_HK'),                             
                         (['CUSTOMER_ID', 'CUSTOMER_NAME', 'CUSTOMER_DOB'],         
                         'CUST_CUSTOMER_HASHDIFF', true),                           
                         (['CUSTOMER_ID', 'NATIONALITY', 'PHONE'],                  
                         'CUSTOMER_DETAILS_HASHDIFF', true)])                       -}},
                                                                                    
{{ dbtvault.add_columns(source_table,                                               
                        [('!STG_CUSTOMER', 'SOURCE'),                               
                         ('BOOKING_DATE', 'EFFECTIVE_FROM')])                        }}
                                                                                    
{{ dbtvault.from(source_table)                                                       }}

```

In v0.6, the equivalent is now this:

=== "dbt_project.yml"
    ```yaml
    ...
    models:
      my_dbtvault_project:
        staging:         
          materialized: view      
          schema: 'my_schema'
          tags:
            - 'staging'
          my_staging_model:
            vars:
              source_model: 
                raw_sources: 'customer_bookings'
              hashed_columns:
                CUSTOMER_HK: "CUSTOMER_ID"
                CUST_CUSTOMER_HASHDIFF:
                  is_hashdiff: true
                  columns:
                    - "CUSTOMER_DOB"
                    - "CUSTOMER_ID"
                    - "CUSTOMER_NAME"
                CUSTOMER_DETAILS_HASHDIFF:
                  is_hashdiff: true
                  columns:
                    - "CUSTOMER_ID"
                    - "NATIONALITY"
                    - "PHONE"
              derived_columns:
                SOURCE: "!STG_CUSTOMER"
                EFFECTIVE_FROM: "BOOKING_DATE"
    ```

=== "my_staging_model.sql"
    ```sql
    {{ dbtvault.stage(include_source_columns=var('include_source_columns', none), 
                      source_model=var('source_model', none), 
                      hashed_columns=var('hashed_columns', none), 
                      derived_columns=var('derived_columns', none)) }}
    ```

No more unnecessary `from` macro, no more hard to read nested lists and no more awkward comma.
With this new approach, staging is also more modular; if you do not need to derive or hash columns then you can simply 
skip writing the configuration in the YAML.

Staging has been messy for a little while, and we appreciate your patience whilst we worked on improving it!
We hope that this makes life easier.

For more details, specific use case examples and full documentation of functionality see below:

!!! seealso "See Also"
    - [stage](../macros.md#stage)
    - [staging tutorial](../tutorial/tut_staging.md)
    
### derive_columns and hash_columns

The old macros `add_columns` and `multi_hash` have been re-worked and re-named to `hash_columns` and `derive_columns` respectively. 
We believe these names make much more sense. Generally, you won't need to use these macros individually (the new [stage](../macros.md#stage) macro uses these macros internally), 
but you may need to if you have specific staging needs and prefer to write your own staging layer macros with these macros as helpers.

## Table Macros

### source is now source_model

The variable `source` has been refactored to `source_model` which
refers to the model which is the source of data for the current model being used e.g. a hub or link. This change was 
made after receiving feedback that the `source` variable may cause confusion. Previously the `vars` section of the YAML for each model in
the `dbt_project.yml` file looked like:

```yaml
hub_customer:
  vars:
    source: 'v_stg_orders'
    src_pk: 'CUSTOMER_HK'
    src_nk: 'CUSTOMER_KEY'
    src_ldts: 'LOADDATE'
    src_source: 'SOURCE'
```

The `dbt_project.yml` file will now look like:

```yaml hl_lines="3"
hub_customer:
  vars:
    source_model: 'v_stg_orders'
    src_pk: 'CUSTOMER_HK'
    src_nk: 'CUSTOMER_KEY'
    src_ldts: 'LOADDATE'
    src_source: 'SOURCE'
```

!!! note
    This variable change applies to all models in the v0.6 release (not just hubs and links), please adjust all 
    variables and variable invocations in the `dbt_project.yml` and models to these changes.

## Hubs and Links 

The functionality of the hubs and links have been updated to allow for loading multiple load dates in bulk. 
The hub and link SQL has also been refactored to use common table expressions (CTEs) as suggested in the [dbt Labs SQL style guide](https://github.com/dbt-labs/corp/blob/master/dbt_style_guide.md),
to improve code readability. 

The invocation of the hub and link macros have not changed aside from the variable change stated above. 
The old invocations of the macros were:

=== "Old hub invocation"

    ```sql
    {{ dbtvault.hub(var('src_pk'), var('src_nk'), var('src_ldts'),
                    var('src_source'), var('source'))               }}
    ```                                                             
    
=== "Old link invocation"         
                                                       
    ```sql                          
    {{ dbtvault.link(var('src_pk'), var('src_fk'), var('src_ldts'), 
                     var('src_source'), var('source'))              }}
    ```

The new invocation of the macros is now:

=== "New hub invocation"

    ```sql
    {{ dbtvault.hub(var('src_pk'), var('src_nk'), var('src_ldts'),
                    var('src_source'), var('source_model'))         }}
    ```                                                             
    
=== "New link invocation"         
                                                       
    ```sql                          
    {{ dbtvault.link(var('src_pk'), var('src_fk'), var('src_ldts'),
                     var('src_source'), var('source_model'))        }}
    ```

!!! tip "Note"
    Hubs and Links are the only tables that can be loaded in bulk. Other table types
    (e.g. Satellites) require iteration due to the temporal attributes, and must be loaded in order.
    As of dbtvault v0.7.0 We now have a [new materialisation](../macros.md#vault_insert_by_period) to make this easier. 

## T-Links

The t-links have not changed, other than their invocation.

=== "Old t-link invocation"   

    ```sql
    {{ dbtvault.t_link(var('src_pk'), var('src_fk'), var('src_payload'),
                       var('src_eff'), var('src_ldts'), var('src_source'),
                       var('source'))                                      }}
    ```

=== "New t-link invocation"   

    ```sql
    {{ dbtvault.t_link(var('src_pk'), var('src_fk'), var('src_payload'),
                       var('src_eff'), var('src_ldts'), var('src_source'),
                       var('source_model'))                                }}
    ```


## Satellites

Satellites have gone through a minor change in v0.6.

### Invocation

As with other table macros, the invocation of the macro has changed as follows:

=== "Old satellite invocation"   

    ```sql
    {{ dbtvault.sat(var('src_pk'), var('src_hashdiff'), var('src_payload'),
                    var('src_eff'), var('src_ldts'), var('src_source'),
                    var('source'))                                          }}
    ```

=== "New satellite invocation"   

    ```sql
    {{ dbtvault.sat(var('src_pk'), var('src_hashdiff'), var('src_payload'),
                    var('src_eff'), var('src_ldts'), var('src_source'),
                    var('source_model'))                                    }}
    ```

### Hashdiff aliasing

Satellites have been updated to allow hashdiff columns to be aliased. This is a feature which will be part of
more versatile global aliasing functionality which will allow users to set constant values for naming convention
purposes.

`HASHDIFF` columns should be called `HASHDIFF`, as per Data Vault 2.0 standards. Due to the fact we have a shared 
staging layer for the raw vault, we cannot have multiple columns sharing the same name. This means we have to name each 
of our `HASHDIFF` columns differently. dbtvault aims to align as closely as possible with Data Vault 2.0 standards, 
and the following new feature is one of many steps we will be making towards that goal.

Below is an example satellite YAML config from a `dbt_project.yml` file:

```yaml hl_lines="9 10 11"
sat_customer_details:
  materialized: incremental
  schema: "vlt"
  tags:
    - sat
  vars:
    source_model: "stg_customer_details_hashed"
    src_pk: "CUSTOMER_HK"
    src_hashdiff: 
      source_column: "CUSTOMER_HASHDIFF"
      alias: "HASHDIFF"
    src_payload:
      - "CUSTOMER_NAME"
      - "CUSTOMER_DOB"
      - "CUSTOMER_PHONE"
    src_eff: "EFFECTIVE_FROM"
    src_ldts: "LOADDATE"
    src_source: "SOURCE"
```

The highlighted lines show the syntax required to alias a column named `CUSTOMER_HASHDIFF` (present in the
`stg_customer_details_hashed` staging layer) as `HASHDIFF`.
