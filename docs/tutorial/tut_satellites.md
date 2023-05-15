Satellites contain point-in-time payload data related to their parent Hub or Link records. Satellites are where the 
concrete data for our business entities in the Hubs and Links, reside.
Each Hub or Link record may have one or more child Satellite records, which form a history of changes to that Hubs 
or Link record as they happen. 

### Structure

Each component of a Satellite is described below.

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key.
For a Satellite, this should be the same as the corresponding Link or Hub PK, concatenated with the load timestamp. 

#### Hashdiff (src_hashdiff)
This is a concatenation of the payload (below) and the primary key. This allows us to 
detect changes in a record (much like a checksum). For example, if a customer changes their name, the hashdiff 
will change as a result of the payload changing. 

#### Payload (src_payload)
The payload consists of concrete data for an entity (e.g. A customer). This could be
a name, a date of birth, nationality, age, gender or more. The payload will contain some or all of the
concrete data for an entity, depending on the purpose of the satellite. 

#### Effective From (src_eff) - optional
An effectivity date. Usually called `EFFECTIVE_FROM`, this column is the business effective date of a 
Satellite record. It records that a record is valid from a specific point in time.
If a customer changes their name, then the record with their 'old' name should no longer be valid, and it will no 
longer have the most recent `EFFECTIVE_FROM` value.

!!! note
    This is an optional metadata column which can be useful later on, and is **not** part of the DataVault 2.0 standard. 

#### Load date (src_ldts)
A load date or load date timestamp. This identifies when the record was first loaded into the database.

#### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.

### Load date vs. Effective From Date
`LOAD_DATE` is the time the record is loaded into the database. `EFFECTIVE_FROM` is different, 
holding the business effectivity date of the record (i.e. when it actually happened in the real world) and will usually 
hold a different value, especially if there is a batch processing delay between when a business event happens and the 
record arriving in the database for load. Having both dates allows us to ask the questions 'what did we know when' 
and 'what happened when' using the `LOAD_DATE` and `EFFECTIVE_FROM` date accordingly. 

The `EFFECTIVE_FROM` field is **not** part of the Data Vault 2.0 standard, and as such it is an optional field, however,
in our experience we have found it useful for processing and applying business rules in downstream Business Vault, for 
use in presentation layers.

### Creating Satellite models

Create a new dbt model as before. We'll call this one `sat_customer_detail`. 

=== "sat_customer_detail.sql"

    ```jinja
    {{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                       src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                       source_model=source_model)                                        }}
    ```

To create a Satellite model, we simply copy and paste the above template into a model named after the Satellite we
are creating. AutomateDV will generate a Satellite using parameters provided in the next steps.

#### Materialisation

The recommended materialisation for **Satellites** is `incremental`, as we load and add new records to the existing data set.

### Adding the metadata

Let's look at the metadata we need to provide to the [satellite macro](../macros/index.md#sat).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `sat_customer_details` Satellite, we can identify columns in our
staging layer which map to them:

| Parameter    | Value                                                |
|--------------|------------------------------------------------------|
| source_model | v_stg_orders                                         |
| src_pk       | CUSTOMER_HK                                          |
| src_hashdiff | source_column: CUSTOMER_HASHDIFF<br/>alias: HASHDIFF |
| src_payload  | CUSTOMER_NAME, CUSTOMER_DOB, CUSTOMER_PHONE          |
| src_eff      | EFFECTIVE_FROM                                       |
| src_ldts     | LOAD_DATETIME                                        |
| src_source   | RECORD_SOURCE                                        |

!!! Note
    We're supplying a mapping (dictionary) to our `src_hashdiff` parameter, [Read More](../best_practises/hashing.md#hashdiff-aliasing)

When we provide the metadata above, our model should look like the following:

=== "sat_customer_detail.sql"

    ```jinja
    {{ config(materialized='incremental') }}
    
    {%- set yaml_metadata -%}
    source_model: "v_stg_orders"
    src_pk: "CUSTOMER_HK"
    src_hashdiff: 
      source_column: "CUSTOMER_HASHDIFF"
      alias: "HASHDIFF"
    src_payload:
      - "CUSTOMER_NAME"
      - "CUSTOMER_DOB"
      - "CUSTOMER_PHONE"
    src_eff: "EFFECTIVE_FROM"
    src_ldts: "LOAD_DATETIME"
    src_source: "RECORD_SOURCE"
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                       src_hashdiff=metadata_dict["src_hashdiff"],
                       src_payload=metadata_dict["src_payload"],
                       src_eff=metadata_dict["src_eff"],
                       src_ldts=metadata_dict["src_ldts"],
                       src_source=metadata_dict["src_source"],
                       source_model=metadata_dict["source_model"])   }}
    ```

!!! Note
    See our [metadata reference](../metadata.md#satellites) for more detail on how to provide metadata to Satellites.

### Running dbt

With our model complete and our YAML written, we can run dbt to create our `sat_customer_detail` Satellite.

=== "< dbt v0.20.x"
    `dbt run -m +sat_customer_detail`

=== "> dbt v0.21.0"
    `dbt run -s +sat_customer_detail`
    
The resulting Satellite table will look like this:

| CUSTOMER_HK | HASHDIFF  | CUSTOMER_NAME | CUSTOMER_DOB | CUSTOMER_PHONE  | EFFECTIVE_FROM | LOAD_DATETIME           | SOURCE |
|-------------|-----------|---------------|--------------|-----------------|----------------|-------------------------|--------|
| B8C37E...   | 3C5984... | Alice         | 1997-04-24   | 17-214-233-1214 | 1993-01-01     | 1993-01-01 00:00:00.000 | 1      |
| .           | .         | .             | .            | .               | .              | .                       | 1      |
| .           | .         | .             | .            | .               | .              | .                       | 1      |
| FED333...   | D8CB1F... | Dom           | 2018-04-13   | 17-214-233-1217 | 1993-01-01     | 1993-01-01 00:00:00.000 | 1      |

--8<-- "includes/abbreviations.md"