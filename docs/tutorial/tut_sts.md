Status tracking satellites
optional Data Vault 2.0 entity
can be maintained where there is no change data capture (CDC) system operating on the source
to track the status of the source business entity
for instance data with deleted status can be excluded from downstream business reporting

!!! Note
    Unlike other raw vault loads the source data provided must be a full snapshot of the source entity's business keys
    that has been staged in the normal manner to add the primary key, load date and record source


### Structure

In general, Status Tracking Satellites consist of 5 columns, described below.

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key.
For a Status Tracking Satellite, this should be the same as the corresponding Hub's PK.

#### Load date (src_ldts)
A load date or load date timestamp. This identifies when the record was first loaded into the database.

#### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.

#### Status (src_status)
The status of the record calculated during processing, can be one of the values Insert(I), Update(U), or Delete(D).

#### Hashdiff (src_hashdiff)
This is the name of the column that will store the hash of the record status value calculated during processing.

### Creating Status Tracking Satellite models

Create a new dbt model as before. We'll call this one `sts_customer`.

=== "sts_customer.sql"

    ```jinja
    {{ dbtvault.sts(src_pk=src_pk, src_ldts=src_ldts, src_source=src_source,
                    src_status=src_status, src_hashdiff=src_hashdiff, source_model=source_model }}
    ```

To create an STS model, we simply copy and paste the above template into a model named after the STS we
are creating. dbtvault will generate an STS using parameters provided in the next steps.

#### Materialisation

The materialisation for **Status Tracking Satellites** must be `incremental`, as we only load and add new records
to the existing data set for a single point in time.

### Adding the metadata

Let's look at the metadata we need to provide to the [sts macro](../macros.md#sts).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `sts_customer` STS, we can identify columns in our
staging layer which map to them:

| Parameter    | Value           |
|--------------|-----------------|
| source_model | v_stg_customer  |
| src_pk       | CUSTOMER_HK     |
| src_ldts     | LOAD_DATE       |
| src_source   | RECORD_SOURCE   |
| src_status   | STATUS          |
| src_hashdiff | STATUS_HASDHIFF |

When we provide the metadata above, our model should look like the following:

=== "sts_customer.sql"

    ```jinja
    {{ config(materialized='incremental')    }}

    {%- set source_model = "v_stg_customer" -%}
    {%- set src_pk = "CUSTOMER_HK" -%}
    {%- set src_ldts = "LOAD_DATE" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    {%- set src_status = "STATUS" -%}
    {%- set src_hashdiff = "STATUS_HASHDIFF" -%}

    {{ dbtvault.sts(src_pk=src_pk, src_ldts=src_ldts, src_source=src_source,
                    src_status=src_status, src_hashdiff=src_hashdiff,  
                    source_model=source_model }}
    ```

!!! Note
    See our [metadata reference](../metadata.md#status-tracking-satellites) for more detail on how to provide metadata to Status Tracking Satellites.

### Running dbt

With our metadata provided and our model complete, we can run dbt to create our `sts_customer` Status Tracking Satellite, as follows:

=== "< dbt v0.20.x"
    `dbt run -m +sts_customer`
=== "> dbt v0.21.0"
    `dbt run -s +sts_customer`

The resulting Status Tracking Satellite will look like this:

| CUSTOMER_PK | LOAD_DATE   | SOURCE | STATUS | STATUS_HASHDIFF |
|-------------|-------------|--------|--------|-----------------|
| B8C37E...   | 1993-01-01  | *      | I      | DD7536...       |
| .           | .           | .      | .      | .               |
| .           | .           | .      | .      | .               |
| FED333...   | 1993-01-01  | *      | U      | 4C6143...       |

--8<-- "includes/abbreviations.md"