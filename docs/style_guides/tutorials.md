> REMOVE ME
> OVERVIEW OF STRUCTURE HERE - REPLACE ME

### Structure

In general, Hubs consist of 4 columns, described below.

#### Column type (parameter name)

e.g. Primary key (src_pk)

### Creating <type of structure> models

Create a new dbt model as before. We'll call this one `<example structure name>`. 

> REMOVE ME
> Example structure name should be something fitting in with a CUSTOMER/ORDER model, 
> as the rest of the tutorials are.

=== "<example structure name>.sql"

    ```jinja
    {{ dbtvault.<macro name>(argument_1=argument_1, argument_2=argument_2, ...,
                             argument_n=argument_n) }}
    ```

To create a <type of structure> model, we simply copy and paste the above template into a model named after the <type of structure> we
are creating. dbtvault will generate a <type of structure> using parameters provided in the next steps.

#### Materialisation

The recommended materialisation for **<type of structure>s** is `<recommended materialisation>`, as we load and add new records to the existing data set.

> REMOVE ME
> Recommended materialisation type should be incremental, generally. 


### Adding the metadata

Let's look at the metadata we need to provide to the [<type of structure> macro](../macros.md#<name of macro>).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `<example structure name>` <type of structure>, we can identify columns in our
staging layer which map to them:

> REMOVE ME
> Below values are left as examples. CHANGE AS REQUIRED

| Parameter      | Value          | 
| -------------- | -------------- | 
| source_model   | v_stg_orders   | 
| src_pk         | CUSTOMER_HK    |
| src_nk         | CUSTOMER_ID    |
| src_ldts       | LOAD_DATETIME  | 
| src_source     | RECORD_SOURCE  |

When we provide the metadata above, our model should look like the following:

> REMOVE ME: CHANGE BELOW SNIPPET AS APPROPRIATE

```jinja
{{ config(materialized='<recommended materialisation>')    }}


{%- set source_model = "v_stg_orders"   -%}
{%- set src_pk = "CUSTOMER_HK"          -%}
{%- set src_nk = "CUSTOMER_ID"          -%}
{%- set src_ldts = "LOAD_DATETIME"      -%}
{%- set src_source = "RECORD_SOURCE"    -%}

{{ dbtvault.<type of structure>(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}
```

!!! Note
    See our [metadata reference](../metadata.md#<type of structure>s) for more detail on how to provide metadata to <type of structure>s.

### Running dbt

With our metadata provided and our model complete, we can run dbt to create our `<example structure name>` <type of structure>, as follows:

`dbt run -m +<example structure name>`

The resulting <type of structure> will look like this:

> REMOVE ME
> Below values are left as examples. CHANGE AS REQUIRED
> ENSURE TABLE FORMATTING IS KEPT NEAT, IT MAKES IT EASIER TO EDIT

| CUSTOMER_HK  | CUSTOMER_ID  | LOAD_DATETIME            | SOURCE |
| ------------ | ------------ | ------------------------ | ------ |
| B8C37E...    | 1001         | 1993-01-01 00:00:00.000  | 1      |
| .            | .            | .                        | 1      |
| .            | .            | .                        | 1      |
| FED333...    | 1004         | 1993-01-01 00:00:00.000  | 1      |

> REMOVE ME: OPTIONAL SECTIONS

### STRUCTURE SPECIFIC GUIDANCE

> REMOVE ME
> e.g. Hubs and Links have a section here about how to load 
> hubs and links from multiple sources, and how to use the macro to do so