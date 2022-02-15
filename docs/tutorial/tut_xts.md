XTS tables are an integral part of incorporating out of sequence loads. An XTS will link to numerous Satellites and keep track of all records loaded to the Satellite.
This is useful for reconstructing loads, auditing, change data capture and more. 

### Structure

Our Extended Tracking Satellite structures will contain:

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key. For an XTS we would expect this to be the same as the corresponding Hub or Link PK.

#### Satellite name (src_satellite.sat_name)
The name of the Satellite that the payload is being staged to. This allows us to use one XTS table to track records for many Satellites and accurately maintain their timelines.


!!! note "Understanding the src_satellite parameter"
    [Read More](../metadata.md#understanding-the-src_satellite-parameter)


#### Hashdiff (src_satellite.hashdiff)
A hashed representation of the record's payload. An XTS only needs to identify differences in payload it is more suitable to store the hash rather than the full payload.

#### Load date (src_ldts)
A load date or load date timestamp. this identifies when the record first gets loaded into the database.

#### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.
(i.e. `1` from the [staging tutorial](tut_staging.md#adding-the-metadata), 
which is the code for `stg_customer`)
    
### Creating Extended Tracking Satellite models

Create a new dbt model as before. We'll call this one `xts_customer`. 

=== "xts_customer.sql"

    ```jinja
    {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

To create a XTS model, we simply copy and paste the above template into a model named after the XTS we
are creating. dbtvault will generate an XTS using parameters provided in the next steps.

#### Materialisation

The recommended materialisation for **Extended Tracking Satellites** is `incremental`, as we load and add new records to the existing data set.

### Adding the metadata

Let's look at the metadata we need to provide to the [xts macro](../macros.md#xts).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `xts_customer` XTS, we can identify columns in our
staging layer which map to them:

| Parameter     | Value                                                             |
|---------------|-------------------------------------------------------------------|
| source_model  | v_stg_customer                                                    |
| src_pk        | CUSTOMER_HK                                                       |
| src_satellite | {"SATELLITE_CUSTOMER":                                            |
|               | &emsp;&emsp;{"sat_name": {"SATELLITE_NAME": "SAT_SAP_CUSTOMER"}}, |
|               | &emsp;&emsp;{"hashdiff": {"HASHDIFF": "CUSTOMER_HASHDIFF"}}       |
|               | }                                                                 |
| src_ldts      | LOAD_DATETIME                                                     |
| src_source    | RECORD_SOURCE                                                     |

When we provide the metadata above, our model should now look like the following:

=== "xts_customer.sql"

    ```jinja
    {{ config(materialized='incremental') }}
    
    {%- set yaml_metadata -%}
    source_model: v_stg_customer
    src_pk: CUSTOMER_HK
    src_satellite:
      SATELLITE_CUSTOMER:
        sat_name:
          SATELLITE_NAME: SAT_SAP_CUSTOMER
        hashdiff:                
          HASHDIFF: CUSTOMER_HASHDIFF
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}

    {% set source_model = metadata_dict["source_model"] %}
    {% set src_pk = metadata_dict["src_pk"] %}
    {% set src_satellite = metadata_dict["src_satellite"] %}
    {% set src_ldts = metadata_dict["src_ldts"] %}
    {% set src_source = metadata_dict["src_source"] %}

    {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

!!! Note
    See our [metadata reference](../metadata.md#extended-tracking-satellites-xts) for more detail on how to provide metadata to XTS structures.

### Running dbt

With our model complete, and our metadata stored in our YAML. We can run dbt to create our `xts_customer` table.

=== "< dbt v0.20.x"
    `dbt run -m +xts_customer`

=== "> dbt v0.21.0"
    `dbt run -s +xts_customer`
    
The resulting Extended Tracking Satellite table will look like this:

| CUSTOMER_HK | HASHDIFF | SATELLITE_NAME   | LOAD_DATE  | SOURCE |
|-------------|----------|------------------|------------|--------|
| B8C37E...   | 3C598... | SAT_SAP_CUSTOMER | 1993-01-01 | *      |
| .           | .        | .                | .          | .      |
| .           | .        | .                | .          | .      |
| FED333...   | 6C958... | SAT_SAP_CUSTOMER | 1993-01-01 | *      |

--8<-- "includes/abbreviations.md"