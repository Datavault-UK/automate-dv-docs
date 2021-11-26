# Transactional Links

Also known as non-historized or no-history Links, Transactional Links record the transaction or 'event' components of 
their referenced Hub tables. They allow us to model the more granular relationships between entities. Some prime examples
are purchases, flights or emails; there is a record in the table for every event or transaction between the entities 
instead of just one record per relation.

### Structure

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key. 
For Transactional Links, we take the natural keys (prior to hashing) represented by the foreign key columns below 
and create a hash on a concatenation of them. 

#### Foreign Keys (src_fk)
Foreign keys referencing the primary key for each Hub referenced in the Transactional Link (2 or more depending on the number of hubs 
referenced) 

#### Payload (src_payload) - optional
A Transactional Link payload consists of concrete data for the transaction record. This could be
a transaction number, an amount paid, transaction type or more. The payload will contain all the
concrete data for a transaction. This field is optional because you may want to model your transactions as a Transactional Link, and multiple Satellites (off of the Transactional Link).
This modelling approach can be useful if there are many fields, and these fields comprise multiple rates of change or types of data.

#### Effective From (src_eff)
An effectivity date. Usually called `EFFECTIVE_FROM`, this column is the business effective date of a 
transaction record. It records that a record is valid from a specific point in time. For a Transactional Link, this
is usually the date on which the transaction occurred. 

#### Load date (src_ldts)
A load date or load date timestamp. this identifies when the record first gets loaded into the database.

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
in our experience we have found it useful for processing and applying business rules in downstream Business Vault, for 
use in presentation layers.

### Creating Transactional Link models

Create a new dbt model as before. We'll call this one `t_link_transaction`. 

=== "t_link_transaction.sql"

    ```jinja
    {{ dbtvault.t_link(src_pk=src_pk, src_fk=src_fk, src_payload=src_payload,
                       src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                       source_model=source_model)                                 }}
    ```

To create a Transactional Link model, we simply copy and paste the above template into a model named after the Transactional Link we
are creating. dbtvault will generate a Transactional Link using parameters provided in the next steps.

#### Materialisation

The recommended materialisation for **Transactional Links** is `incremental`, as we load and add new records to the existing data set.

### Adding the metadata

Let's look at the metadata we need to provide to the [t_link macro](../macros.md#t_link).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `t_link_transaction` table, we can identify columns in our
staging layer which map to them:

| Parameter      | Value                                              | 
| -------------- | -------------------------------------------------- | 
| source_model   | v_stg_transactions                                 |
| src_pk         | TRANSACTION_HK                                     |
| src_fk         | CUSTOMER_HK, ORDER_HK                              |
| src_payload    | TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT |
| src_eff        | EFFECTIVE_FROM                                     | 
| src_ldts       | LOAD_DATETIME                                      | 
| src_source     | RECORD_SOURCE                                      |

When we provide the metadata above, our model should look like the following:

=== "t_link_transaction.sql"

    ```jinja
    {{ config(materialized='incremental') }}
    
    {%- set yaml_metadata -%}
    source_model: 'v_stg_transactions'
    src_pk: 'TRANSACTION_HK'
    src_fk: 
        - 'CUSTOMER_HK'
        - 'ORDER_HK'
    src_payload:
        - 'TRANSACTION_NUMBER'
        - 'TRANSACTION_DATE'
        - 'TYPE'
        - 'AMOUNT'
    src_eff: 'EFFECTIVE_FROM'
    src_ldts: 'LOAD_DATETIME'
    src_source: 'RECORD_SOURCE'
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ dbtvault.t_link(src_pk=metadata_dict["src_pk"],
                       src_fk=metadata_dict["src_fk"],
                       src_payload=metadata_dict["src_payload"],
                       src_eff=metadata_dict["src_eff"],
                       src_ldts=metadata_dict["src_ldts"],
                       src_source=metadata_dict["src_source"],
                       source_model=metadata_dict["source_model"]) }}
    ```

!!! Note
    See our [metadata reference](../metadata.md#transactional-links) for more detail on how to provide metadata to 
    Transactional Links.

### Running dbt

With our model complete and our YAML written, we can run dbt to create our `t_link_transaction` Transactional Link.

=== "< dbt v0.20.x"
    `dbt run -m +t_link_transaction`

=== "> dbt v0.21.0"
    `dbt run --select +t_link_transaction`

And our Transactional Link table will look like this:

| TRANSACTION_HK  | CUSTOMER_HK | ORDER_HK  | TRANSACTION_NUMBER | TYPE | AMOUNT  | EFFECTIVE_FROM | LOAD_DATETIME            | SOURCE |
| --------------- | ----------- | --------- | ------------------ | ---- | ------- | -------------- | ------------------------ | ------ |
| BDEE76...       | CA02D6...   | CF97F1... | 123456789101       | CR   | 100.00  | 1993-01-28     | 1993-01-01 00:00:00.000  | 2      |
| .               | .           | .         | .                  | .    | .       | .              | .                        | 2      |
| .               | .           | .         | .                  | .    | .       | .              | .                        | 2      |
| E0E7A8...       | F67DF4...   | 2C95D4... | 123456789104       | CR   | 678.23  | 1993-01-28     | 1993-01-01 00:00:00.000  | 2      |