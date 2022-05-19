> OVERVIEW OF STRUCTURE HERE - REPLACE ME
Status Tracking Satellite theory
A Status Tracking Satellite (STS) ... 
### Structure

A Status Tracking Satellite contains:

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key.
For a Status Tracking Satellite, this should be the same as the corresponding link's PK.

#### Load date (src_ldts)
A load date or load date timestamp. This identifies when the record was first loaded into the database.

#### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.

#### Status (src_status)
Status of the record, can have value Insert(I), Update(U), Delete(D)
Insert:
Update:
Delete:

### Creating Status Tracking Satellite models

Create a new dbt model as before. We'll call this one `sts_customer`.

=== "sts_customer.sql"

    ```jinja
    {{ dbtvault.sts(src_pk=src_pk, src_ldts=src_ldts, src_source=src_source,
                    src_status=src_status, source_model=source_model }}
    ```

To create an STS model, we simply copy and paste the above template into a model named after the STS we
are creating. dbtvault will generate an STS using parameters provided in the next steps.

#### Materialisation

The recommended materialisation for **Status Tracking Satellites** is `incremental`, as we load and add new records to the existing data set.

### Adding the metadata

Let's look at the metadata we need to provide to the [sts macro](../macros.md#sts).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `sts_customer` STS, we can identify columns in our
staging layer which map to them:

| Parameter    | Value          |
|--------------|----------------|
| source_model | v_stg_customer |
| src_pk       | CUSTOMER_PK    |
| src_ldts     | LOAD_DATE      |
| src_source   | SOURCE         |
| src_status   | STATUS         |

When we provide the metadata above, our model should look like the following:

=== "sts_customer.sql"

    ```jinja
    {{ config(materialized='incremental')    }}

    {%- set source_model = "v_stg_customer" -%}
    {%- set src_pk = "CUSTOMER_PK" -%}
    {%- set src_ldts = "LOAD_DATE" -%}
    {%- set src_source = "SOURCE" -%}
    {%- set src_status = "STATUS" -%}

    {{ dbtvault.sts(src_pk=src_pk, src_ldts=src_ldts, src_source=src_source,
                    src_status=src_status, 
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

| CUSTOMER_PK | LOAD_DATE   | SOURCE | STATUS |
|-------------|-------------|--------|--------|
| B8C37E...   | 1993-01-01  | *      | I      |
| .           | .           | .      | .      |
| .           | .           | .      | .      |
| FED333...   | 1993-01-01  | *      | U      |

--8<-- "includes/abbreviations.md"