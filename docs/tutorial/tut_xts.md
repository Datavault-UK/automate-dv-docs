# Extended Tracking Satellites (XTS)

XTS tables are an integral part of incorporating out of sequence loads. An XTS will link to numerous satellites and keep track of all records loaded to the satellite. This is particularly useful for correcting the timeline of an out of sequence satellite.
For example, 

#### Structure

Our extended tracking satellites structures will contain:

##### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key.

##### Hashdiff (src_satellite['HASHDIFF'])
A hashed representation of the record's payload.

##### Satellite name (src_satellite['SATELLITE_NAME'])
The name of the satellite that the payload is being staged to.

##### Load date (src_ldts)
A load date or load date timestamp. this identifies when the record was first loaded into the database.

##### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.
(i.e. `1` from the [staging tutorial](tut_staging.md#adding-calculated-and-derived-columns), 
which is the code for `stg_customer`)
    
### Setting up XTS models

Create a new dbt model as before. We'll call this one `example_name_xts`. 

`example_name_xts.sql`
```jinja
{{ dbtvault.xts(var('src_pk'), var('src_satellite'), var('src_ldts'), 
                var('src_source'), var('source_model'))                 }}
```

To create an XTS model, we will simply copy and paste the above template into a model named after the xts we are creating. dbtvault will generate an xts using parameters provided in the next steps.

`dbt_project.yml`
```yaml
models:
  my_dbtvault_project:
   xts:
    materialized: incremental
    tags:
      - xts
    xts_customer:
      vars:
        ...
```
!!! tip "New in dbtvault v0.7.0"
    You may also use the [vault_insert_by_period](../macros.md#vault_insert_by_period) materialisation, a custom materialisation 
    included with dbtvault which enables you to iteratively load a table using a configurable period of time (e.g. by day). 

[Read more about incremental models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)

### Adding the metadata

Let's look at the metadata we need to provide to the [xts](../macros.md#xts) macro.

#### Source table

The first piece of metadata we need is the source model. This step is simple,
all we need to do is provide the name of the model for the stage table as a string in our metadata as follows:

`dbt_project.yml`
```yaml
xts_customer:
  vars:
    source_model: 'stg_customer'
    ...
```

#### Source columns

Next we need to define the column heading that the XTS shall use from the source table.
Here we set columns from the `stg_customer` table to variables using in the xts macro:

1. A primary key,
2. The satellite dictionary, containing the satellite name and the hashdiff of the satellite's payload.
3. A load ate timestamp, which is present in the staging layer as `LOAD_DATE`.
4. A column to contain the `SOURCE`.

Adding this to the metadata we should find something that resembles this:
`dbt_project.yml`
```yaml hl_lines="4 5 6 7 8 9"

xts_customer:
    vars:
        source_model: 'stg_customer'
        src_pk: 'CUSTOMER_PK'
        src_satellite: 
            'SATELLITE_NAME': ['SAT_SAP_CUSTOMER']
            'HASHDIFF': ['CUSTOMER_HASHDIFF']
        src_ldts: 'LOAD_DATE'
        src_source: 'SOURCE'
```

### Running dbt

With our model complete, and our metadata stored in our YAML. We can run dbt to create our `xts_customer` table.

`dbt run -m +xts_customer`

!!! tip
    Using the '+' in the command above will get dbt to compile and run all parent dependencies for the model we are 
    running, in this case, it will compile and run the staging layer as well as the hub if they don't already exist. 
    
And our table will look like this:

| CUSTOMER_PK  | HASHDIFF     | SATELLITE_NAME   | LOAD_DATE  | SOURCE       |
| ------------ | ------------ | ---------------- | ---------- | ------------ |
| B8C37E...    | 3C598...     | SAT_SAP_CUSTOMER | 1993-01-01 | *            |
| .            | .            | .                | .          | .            |
| .            | .            | .                | .          | .            |
| FED333...    | 6C958...     | SAT_SAP_CUSTOMER | 1993-01-01 | *            |

### Next steps

We have now created:

- A staging layer 
- A Hub 
- A Link
- A Transactional Link
- A Satellite
- An Effectivity Satellite
- An Extended Tracking Satellite

Next we will look at [point in time structures](tut_point_in_time.md).