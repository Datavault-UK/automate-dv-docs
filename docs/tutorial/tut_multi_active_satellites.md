# Multi Active Satellites (MAS)

Multi Active Satellites (MAS) contain point-in-time payload data related to their parent hub or link records that
allow for multiple records to be valid at the same time. Some example use cases could be when customers have multiple active 
phone numbers or addresses. 

In order to accommodate for multiple records of the same entity at a point-in-time, one or more Child Dependent Keys 
will be included in the Primary Key. 

#### Structure

Our multi active satellite structures will contain:

##### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key.
For a multi active satellite, this should be the same as the corresponding link or hub PK, concatenated with the load timestamp.

##### Child Dependent Key(s) (src_cdk)
The child dependent keys are a subset of the payload (below) that helps with identifying the different valid records 
for each entity inside the multi active satellite. For example, a customer will have different valid phone number valid
at the same time, the phone number attribute will be selected as a child dependent key that helps the natural key keep 
records unique and identifiable. If the customer has only one phone number, but multiple extensions associated with that 
phone number, then both the phone number, and the extension attribute will be considered a child dependent key. 

##### Hashdiff (src_hashdiff)
This is a concatenation of the payload (below) and the primary key. This allows us to 
detect changes in a record (much like a checksum). For example, if a customer changes their name, the hashdiff 
will change as a result of the payload changing. 

##### Payload (src_payload)
The payload consists of concrete data for an entity (e.g. A customer). This could be
a name, a phone number, a date of birth, nationality, age, gender or more. The payload will contain some or all of the
concrete data for an entity, depending on the purpose of the satellite. 

##### Effective From (src_eff)
An effectivity date. Usually called `EFFECTIVE_FROM`, this column is the business effective date of a multi active
satellite record. It records that a record is valid from a specific point in time.
If a customer changes their name, then the record with their 'old' name should no longer be valid, and it will no 
longer have the most recent `EFFECTIVE_FROM` value. 

##### Load date (src_ldts)
A load date or load date timestamp. This identifies when the record was first loaded into the database.

##### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.

!!! note
    `LOAD_DATE` is the time the record is loaded into the database. `EFFECTIVE_FROM` is different, 
    holding the business effectivity date of the record (i.e. When it actually happened in the real world) and will usually 
    hold a different value, especially if there is a batch processing delay between when a business event happens and the 
    record arriving in the database for load. Having both dates allows us to ask the questions 'what did we know when' 
    and 'what happened when' using the `LOAD_DATE` and `EFFECTIVE_FROM` date accordingly. 

### Setting up MAS models

Create a new dbt model as before. We'll call this one `ma_sat_customer_details`.

=== "ma_sat_customer_details.sql"

    ```jinja
    {{ dbtvault.ma_sat(var('src_pk'), var('src_cdk'), var('src_hashdiff'), var('src_payload'),
                    var('src_eff'), var('src_ldts'), var('src_source'),
                    var('source_model'))                                   }}
    ```

To create a MAS model, we simply copy and paste the above template into a model named after the MAS we
are creating. dbtvault will generate a MAS using parameters provided in the next steps.

MAS should use the incremental materialization, as we load and add new records to the existing data set. 

We recommend setting the `incremental` materialization on all of your MAS using the `dbt_project.yml` file:

=== "dbt_project.yml"

    ```yaml
    models:
      my_dbtvault_project:
       multi_active_satellites:
        materialized: incremental # See tip below
        tags:
          - ma_sat
        ma_sat_customer_details:
          vars:
            ...
            ...
    ```

!!! tip "Loading Multi Active Satellites correctly"
    dbtvault provides custom materialisations, designed to load structures which contain deltas (such as multi active satellites, among other structures) 
    in the correct way:
    
    - [vault_insert_by_period](../macros.md#vault_insert_by_period)
    - [vault_insert_by_rank](../macros.md#vault_insert_by_rank)

[Read more about incremental models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)

### Adding the metadata

Let's look at the metadata we need to provide to the [ma_sat](../macros.md#ma_sat) macro.

#### Source model

The first piece of metadata we need is the source model. This step is easy, as in this example we created the 
staging layer ourselves.  All we need to do is provide the name of stage table as a string in our metadata 
as follows.

=== "dbt_project.yml"

    ```yaml
    ma_sat_customer_details:
      vars:
        source_model: 'stg_customer_hashed'
    ```

!!! tip
    See our [metadata reference](../metadata.md#multi-active-satellites-mas) for more ways to provide metadata

#### Source columns

Next, we define the columns which we would like to bring from the source.
Using our knowledge of what columns we need in our ```ma_sat_customer_details``` table, we can identify columns in our
staging layer which map to them:

1. The primary key of the parent hub or link table,  which is a hashed natural key. 
The `CUSTOMER_PK` we created earlier in the [staging](tut_staging.md) section will be used for `sat_customer_details`.

2. The child dependent key, `CUSTOMER_PHONE`, that is part of the payload inside the raw [staging](../macros.md#stage) layer.  
3. A hashdiff. We created `HASHDIFF` in [staging](tut_staging.md) earlier, which we will use here.
4. Some payload columns: `CUSTOMER_NAME`, `CUSTOMER_PHONE` which should be present in the 
raw staging layer via an [stage](../macros.md#stage) macro call.
5. An `EFFECTIVE_FROM` column, also added in staging. 
6. A load date timestamp, which is present in the staging layer as `LOAD_DATE`. 
7. A `SOURCE` column.

We can now add this metadata to the `dbt_project`:

=== "dbt_project.yml"

    ```yaml hl_lines="4 5 6 7 8 9 10 11 12"
    ma_sat_customer_details:
      vars:
        source_model: 'stg_customer_hashed'
        src_pk: 'CUSTOMER_PK'
        src_cdk: 
          - 'CUSTOMER_PHONE'
        src_payload:
          - 'CUSTOMER_NAME'
        src_hashdiff: 'HASHDIFF'
        src_eff: 'EFFECTIVE_FROM'
        src_ldts: 'LOAD_DATE'
        src_source: 'SOURCE'
    ```

### Running dbt

With our model complete and our YAML written, we can run dbt to create our `ma_sat_customer_details` multi active satellite.

`dbt run -m +ma_sat_customer_details`

And our table will look like this:

| CUSTOMER_PK  | HASHDIFF     | CUSTOMER_NAME | CUSTOMER_PHONE  | EFFECTIVE_FROM | LOAD_DATE   | SOURCE |
| ------------ | ------------ | ----------    | --------------- | -------------- | ----------- | ------ |
| B8C37E...    | 3C5984...    | Alice         | 17-214-233-1214 | 1993-01-01     | 1993-01-01  | 1      |
| B8C37E...    | A11VT9...    | Alice         | 17-214-233-1224 | 1993-01-01     | 1993-01-01  | 1      |
| .            | .            | .             | .               | .              | .           | 1      |
| .            | .            | .             | .               | .              | .           | 1      |
| FED333...    | 7YT890...    | Dom           | 17-214-233-1217 | 1993-01-01     | 1993-01-01  | 1      |
| FED333...    | D8CB1F...    | Dom           | 17-214-233-1227 | 1993-01-01     | 1993-01-01  | 1      |

### Next steps

That is all for now. More table types will be coming in future! See our [roadmap](../roadmap.md) for more details.

If you want a more realistic real-world example, with real data to work with, take a look at our [worked example](../worked_example/we_worked_example.md).