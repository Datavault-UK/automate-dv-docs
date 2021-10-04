# Extended Tracking Satellites (XTS)

XTS tables are an integral part of incorporating out of sequence loads. An XTS will link to numerous satellites and keep track of all records loaded to the satellite. This is particularly useful for correcting the timeline of an out of sequence satellite.
For example, when an unexpected record gets loaded late it can cause an inaccuracy in the satellite's history. By tracking all record updates for that satellite, we can discern the correct timeline to reconstruct to incorporate the unexpected record.

### Structure

Our extended tracking satellites structures will contain:

#### Primary Key ( src_pk )
A primary key (or surrogate key) which is usually a hashed representation of the natural key. For an XTS we would expect this to be the same as the corresponding link or hub PK.

#### Hashdiff ( src_satellite.hashdiff)
A hashed representation of the record's payload. An XTS only needs to identify differences in payload it is more suitable to store the hash rather than the full payload.

#### Satellite name ( src_satellite.sat_name )
The name of the satellite that the payload is being staged to. This allows us to use one XTS table to track records for many satellites and accurately maintain their timelines.

#### Load date ( src_ldts )
A load date or load date timestamp. this identifies when the record first gets loaded into the database.

#### Record Source ( src_source )
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.
(i.e. `1` from the [staging tutorial](tut_staging.md#adding-the-metadata), 
which is the code for `stg_customer`)
    
### Creating XTS models

Create a new dbt model as before. We'll call this one `xts_customer.sql`. 

=== "xts_customer.sql"

    ```jinja
    {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model)              }}
    ```

To create an XTS model, we will simply copy and paste the above template into a model named after the XTS we are creating. 
dbtvault will generate the XTS using parameters provided in the next steps.

ADD METADATA SECTION

### Adding the metadata

Let's look at the metadata we need to provide to the [xts](../macros.md#xts) macro.

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