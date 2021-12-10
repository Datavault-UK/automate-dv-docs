# Extended Tracking Satellites (XTS)

XTS tables are an integral part of incorporating out of sequence loads. An XTS will link to numerous Satellites and keep track of all records loaded to the Satellite. This is particularly useful for correcting the timeline of an Out Of Sequence Satellite.
For example, when an unexpected record gets loaded late it can cause an inaccuracy in the Satellite's history. By tracking all record updates for that Satellite, we can discern the correct timeline to reconstruct to incorporate the unexpected record.

#### Structure

Our Extended Tracking Satellite structures will contain:

##### Primary Key ( src_pk )
A primary key (or surrogate key) which is usually a hashed representation of the natural key. For an XTS we would expect this to be the same as the corresponding Hub or Link PK.

##### Satellite name ( src_satellite.sat_name )
The name of the Satellite that the payload is being staged to. This allows us to use one XTS table to track records for many Satellites and accurately maintain their timelines.

##### Hashdiff ( src_satellite.hashdiff)
A hashed representation of the record's payload. An XTS only needs to identify differences in payload it is more suitable to store the hash rather than the full payload.

##### Load date ( src_ldts )
A load date or load date timestamp. this identifies when the record first gets loaded into the database.

##### Record Source ( src_source )
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.
(i.e. `1` from the [staging tutorial](tut_staging.md#adding-the-metadata), 
which is the code for `stg_customer`)
    
### Setting up XTS models

Create a new dbt model as before. We'll call this one `xts_customer.sql`. 

=== "xts_customer.sql"

    ```jinja
    {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

To create an XTS model, we will simply copy and paste the above template into a model named after the XTS we are creating. dbtvault will generate the XTS using parameters provided in the next steps.

We recommend setting the `incremental` materialization on all of your Extended Tracking Satellites using the `dbt_project.yml` file:

=== "dbt_project.yml"

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

[Read more about incremental models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)

### Adding the metadata

Let's look at the metadata we need to provide to the [xts](../macros.md#xts) macro.

#### Source table

The first piece of metadata we need is the source model. This step is simple,
all we need to do is provide the name of the model for the stage table as a string in our metadata as follows:

=== "xts_customer.sql"

    ```jinja
    {{ config(materialized='incremental') }}
    
    {%- set yaml_metadata -%}
    source_model: 'STG_CUSTOMER'
    ...
    ```

#### Source columns

Next we need to define the column heading that the XTS shall use from the source table.
Here we set columns from the `stg_customer` table to variables using in the `xts` macro:

1. A primary key,
2. The Satellite dictionary, containing the Satellite name and the hashdiff of the Satellite's payload.
3. A load date timestamp, which is present in the staging layer as `LOAD_DATE`.
4. A column to contain the `SOURCE`.

Adding this to the metadata we should find something that resembles this:

=== "xts_customer.sql"

    ```jinja
    {{ config(materialized='incremental') }}
    
    {%- set yaml_metadata -%}
    source_model: 'STG_CUSTOMER'
    src_pk: 'CUSTOMER_PK'
    src_ldts: 'LOAD_DATE'
    src_satellite:
      SATELLITE_CUSTOMER
        sat_name:
          'SATELLITE_NAME': 'SAT_SAP_CUSTOMER'
        hashdiff:                
          'HASHDIFF': 'CUSTOMER_HASHDIFF'
    src_source: 'SOURCE'
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
 
    {% set source_model = metadata_dict['source_model'] %}
    
    {% set src_pk = metadata_dict['src_pk'] %}
    
    {% set src_ldts = metadata_dict['src_ldts'] %}
    
    {% set src_satellite = metadata_dict['src_satellite'] %}

    {% set src_source = metadata_dict['src_source'] %}

    {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

### Running dbt

With our model complete, and our metadata stored in our YAML. We can run dbt to create our `xts_customer` table.

=== "< dbt v0.20.x"
    `dbt run -m +xts_customer`

=== "> dbt v0.21.0"
    `dbt run -s +xts_customer`

!!! tip
    Using the '+' in front of `xts_customer` in the command above will get dbt to compile and run all its parent dependencies.  
    In this case, it will compile and run the staging and the hub models.
    
The resulting Extended Tracking Satellite table will look like this:

| CUSTOMER_PK | HASHDIFF | SATELLITE_NAME   | LOAD_DATE  | SOURCE |
|-------------|----------|------------------|------------|--------|
| B8C37E...   | 3C598... | SAT_SAP_CUSTOMER | 1993-01-01 | *      |
| .           | .        | .                | .          | .      |
| .           | .        | .                | .          | .      |
| FED333...   | 6C958... | SAT_SAP_CUSTOMER | 1993-01-01 | *      |