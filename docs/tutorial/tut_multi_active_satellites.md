# Multi Active Satellites (MAS)

Multi Active Satellites (MAS) contain point-in-time payload data related to their parent hub or link records that
allow for multiple records to be valid at the same time. Some example use cases could be when customers have multiple active 
phone numbers or addresses. 

In order to accommodate for multiple records of the same entity at a point-in-time, one or more Child Dependent Keys 
will be included in the Primary Key alongside the Hash Key and the Load Date/Timestamp. 

### Structure

Our multi active satellite structures will contain:

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key.
For a multi active satellite, this should be the same as the corresponding link or hub PK, concatenated with the load timestamp.

#### Child Dependent Key(s) (src_cdk)
The child dependent keys are a subset of the payload (below) that helps with identifying the different valid records 
for each entity inside the multi active satellite. For example, a customer could have different valid phone number valid
at the same time. The phone number attribute will be selected as a child dependent key that helps the natural key keep 
records unique and identifiable. If the customer has only one phone number, but multiple extensions associated with that 
phone number, then both the phone number, and the extension attribute will be considered a child dependent key. 

#### Hashdiff (src_hashdiff)
This is a concatenation of the payload (below) and the primary key. This allows us to 
detect changes in a record (much like a checksum). For example, if a customer changes their name, the hashdiff 
will change as a result of the payload changing. 

#### Payload (src_payload)
The payload consists of concrete data for an entity (e.g. A customer). This could be
a name, a phone number, a date of birth, nationality, age, gender or more. The payload will contain some or all of the
concrete data for an entity, depending on the purpose of the satellite. 

#### Effective From (src_eff)
An effectivity date. Usually called `EFFECTIVE_FROM`, this column is the business effective date of a multi active
satellite record. It records that a record is valid from a specific point in time.
If a customer changes their name, then the record with their 'old' name should no longer be valid, and it will no 
longer have the most recent `EFFECTIVE_FROM` value. 

#### Load date (src_ldts)
A load date or load date timestamp. This identifies when the record first gets loaded into the database.

#### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.

### Load date vs. Effective From Date
`LOAD_DATE` is the time the record is loaded into the database. `EFFECTIVE_FROM` is different, 
holding the business effectivity date of the record (i.e. When it actually happened in the real world) and will usually 
hold a different value, especially if there is a batch processing delay between when a business event happens and the 
record arriving in the database for load. Having both dates allows us to ask the questions 'what did we know when' 
and 'what happened when' using the `LOAD_DATE` and `EFFECTIVE_FROM` date accordingly. 

The `EFFECTIVE_FROM` field is **not** part of the Data Vault 2.0 standard, and as such it is an optional field, however,
in our experience we have found it useful for processing and applying business rules in downstream business vault, for 
use in presentation layers.

### Creating MAS models

Create a new dbt model as before. We'll call this one `ma_sat_customer_details`.

=== "ma_sat_customer_details.sql"

    ```jinja
    {{ dbtvault.ma_sat(src_pk=src_pk, src_cdk=src_cdk, src_hashdiff=src_hashdiff, 
                       src_payload=src_payload, src_eff=src_eff, src_ldts=src_ldts, 
                       src_source=src_source, source_model=source_model) }}
    ```

### Adding the metadata

Let's look at the metadata we need to provide to the [ma_sat](../macros.md#ma_sat) macro.

#### Materialisation

The recommended materialisation for **satellites** is `incremental`, as we load and add new records to the existing data set.

### Adding the metadata

Let's look at the metadata we need to provide to the [multi-active satellite macro](../macros.md#ma_sat).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `ma_sat_customer_details` multi-active satellite, we can identify columns in our
staging layer which map to them:

| Parameter      | Value                                                | 
| -------------- | ---------------------------------------------------- | 
| source_model   | v_stg_orders                                         | 
| src_pk         | CUSTOMER_HK                                          |
| src_cdk        | CUSTOMER_PHONE                                       |
| src_payload    | CUSTOMER_NAME                                        |
| src_hashdiff   | source_column: CUSTOMER_HASHDIFF, alias: HASHDIFF    |
| src_eff        | EFFECTIVE_FROM                                       |
| src_ldts       | LOAD_DATETIME                                        | 
| src_source     | RECORD_SOURCE                                        |

When we provide the metadata above, our model should look like the following:

```jinja
{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
source_model: 'v_stg_orders'
src_pk: 'CUSTOMER_HK'
src_cdk: 
  - 'CUSTOMER_PHONE'
src_payload:
  - 'CUSTOMER_NAME'
src_hashdiff: 'HASHDIFF'
src_eff: 'EFFECTIVE_FROM'
src_ldts: 'LOAD_DATETIME'
src_source: 'RECORD_SOURCE'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.ma_sat(src_pk=metadata_dict['src_pk'],
                   src_cdk=metadata_dict['src_cdk'],
                   src_payload=metadata_dict['src_payload'],
                   src_hashdiff=metadata_dict['src_hashdiff'],
                   src_eff=metadata_dict['src_eff'],
                   src_ldts=metadata_dict['src_ldts'],
                   src_source=metadata_dict['src_source'],
                   source_model=metadata_dict['source_model']) }}
```

!!! Note
    See our [metadata reference](../metadata.md#multi-active-satellites-mas) for more detail on how to provide metadata to multi-active satellites.

### Running dbt

With our model complete and our YAML written, we can run dbt to create our `ma_sat_customer_details` multi active satellite.

`dbt run -m +ma_sat_customer_details`

And our table will look like this:

| CUSTOMER_HK  | HASHDIFF     | CUSTOMER_NAME | CUSTOMER_PHONE  | EFFECTIVE_FROM | LOAD_DATETIME            | SOURCE | 
| ------------ | ------------ | ----------    | --------------- | -------------- | ------------------------ | ------ | 
| B8C37E...    | 3C5984...    | Alice         | 17-214-233-1214 | 1993-01-01     | 1993-01-01 00:00:00.000  | 1      | 
| B8C37E...    | A11VT9...    | Alice         | 17-214-233-1224 | 1993-01-01     | 1993-01-01 00:00:00.000  | 1      | 
| .            | .            | .             | .               | .              | .                        | 1      | 
| .            | .            | .             | .               | .              | .                        | 1      | 
| FED333...    | 7YT890...    | Dom           | 17-214-233-1217 | 1993-01-01     | 1993-01-01 00:00:00.000  | 1      |
| FED333...    | D8CB1F...    | Dom           | 17-214-233-1227 | 1993-01-01     | 1993-01-01 00:00:00.000  | 1      |