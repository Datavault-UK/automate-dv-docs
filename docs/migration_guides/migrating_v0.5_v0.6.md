# Migrating from v0.5 to v0.6

With the release of v0.6, the [hub](../macros.md#hub) and [link](../macros.md#link) macros have been refactored to 
included the functionality of multi date loading. How you stage the your data has also changed, we introduce the new 
[stage](../macros.md#stage) macro. There has also been a change to the variable ```source``` in the  
```dbt_project.yml``` file for the models as this previously may have caused some confusion. 
This variable has been renamed to ```source_model``` and must be used in all models. See below for more details.

## Table Macros

### Source is now Source_models

The variable ```source``` has been refactored to ```source_model``` which
refers to the model which is the source of data for the current model being used e.g. a hub or link. This change was 
made after receiving feedback that the ```source``` variable may cause confusion. Previously the ```vars``` section of the 
```dbt_project.yml``` files looked like:

```yaml
hub_customer:
          vars:
            source: 'v_stg_orders'
            src_pk: 'CUSTOMER_PK'
            src_nk: 'CUSTOMER_KEY'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
```

The ```dbt_project.yml``` file will now look like:

```yaml hl_lines="3"
hub_customer:
          vars:
            source_model: 'v_stg_orders'
            src_pk: 'CUSTOMER_PK'
            src_nk: 'CUSTOMER_KEY'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
```

!!! note
    This variable change applies to all models in the v0.6 release (not just hubs and links), please adjust all 
    variables and variable calls in the ```dbt_project.yml``` and models to these changes. 

## Hubs and Links 

The functionality of the hubs and links have been refactored to include multi date loads into these tables. The hub and
link sql has been refactored into using common table expressions (CTEs) which the the recommended sql style by Fishtown, 
the creators of dbt, to improve code readability. 

!!! info
    For more information on CTEs in dbt, please refer to this 
    [discussion](https://discourse.getdbt.com/t/why-the-fishtown-sql-style-guide-uses-so-many-ctes/1091).

The calling of the hub and link macro has not changed apart from the variable change stated above. 
The old calling of the macro was:

```sql
{{- config(materialized='incremental', schema='MYSCHEMA', tags='hub') -}}

{{ dbtvault.hub(var('src_pk'), var('src_nk'), var('src_ldts'),
                var('src_source'), var('source'))                      }}
```

The new calling of the hub macro is now:

```sql hl_lines="4"
{{- config(materialized='incremental', schema='MYSCHEMA', tags='hub') -}}

{{ dbtvault.hub(var('src_pk'), var('src_nk'), var('src_ldts'),
                var('src_source'), var('source_model'))                }}
```

The majority of changes for the links, like the hubs, have been functional. The usage of the link macro has changed 
slightly, the old link macro was called as:

```sql
{{- config(materialized='incremental', schema='MYSCHEMA', tags='link') -}}

{{ dbtvault.link(var('src_pk'), var('src_nk'), var('src_ldts'),
                var('src_source'), var('source'))                      }}
```

The new link macro should be called using the ```var('source_model)``` var instead of the ```var('source')``` var:

```sql hl_lines="4"
{{- config(materialized='incremental', schema='MYSCHEMA', tags='link') -}}

{{ dbtvault.link(var('src_pk'), var('src_nk'), var('src_ldts'),
                var('src_source'), var('source_model'))                 }}
```
