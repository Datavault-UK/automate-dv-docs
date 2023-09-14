## Hubs and Links

Hubs and Links by definition are not temporal (do not track records over time) and therefore they are very simple to load.

Each structure holds unique sets, when loading, they will simply add records to the set that have not been loaded before.

For a Hub and a Link, this uniqueness is based on the value of the Primary Key (src_pk).

## Satellites

!!! success "New in AutomateDV v0.10.0"

    As of AutomateDV v0.10.0 there is no longer a limitation on Satellite loading. 
    Previously AutomateDV required a single record per key, per load. 
    This meant that data loading processes needed to be more robust and limited to delta loads, not allowing for much error.
    Now, though it is is a bit more relaxed, we still recommended ensuring data loads are as robust and atomic as possible. 

    See the migration guide below for more details
    
    - [Migration Guide](../migration_guides.md#migrating-from-097-to-0100)

!!! warning "Standard Satellites Only"

    At the current time this is only supported on the standard satellite macro `sat()` We **_do_** plan to extend this to the other satellite types. 

!!! example "Report issues"

    Whilst we have tested this new functioanlity **_extensively_** please let us know if you find any issues! Thank you.

    - [GitHub](https://github.com/Datavault-UK/automate-dv/issues)
    - [Slack](https://join.slack.com/t/dbtvault/shared_invite/enQtODY5MTY3OTIyMzg2LWJlZDMyNzM4YzAzYjgzYTY0MTMzNTNjN2EyZDRjOTljYjY0NDYyYzEwMTlhODMzNGY3MmU2ODNhYWUxYmM2NjA)

The `HASHDIFF` in a Satellite is used as a kind of checksum to detect changes in records it is tracking the history for, 
without comparing every column individually. The logic for loading is therefore heavily based on comparing HASHDIFFs. This is described
in more detail below.

### Base loads

If you have multiple records for a primary key in a single load (batch) we first compare all hashdiff values aside 
from the first in date order (src_ldts) and take every record which has a different hashdiff from the previous record's hashdiff in that batch. 

As this always skips the first record (as the first record will not have a previous record) we handle this separately.

For a base load, we then insert all of these changed records, as well as the first record. 
The first record is always different from all the rest due to ordering by the LDTS (earliest first), 
unless a true duplicate is present in which case we only take one instance. 

### Incremental load

For an incremental load, we follow the same process as a Base load except we treat the first record differently. In an incremental load we
insert the first record of a batch only if it is different from the latest record in the existing Satellite. 

If the first record is the same as the latest Satellite record, then by definition the first record in our set of differing hashdiffs must be different.
The first record in the batch will not be inserted if it is the same as the latest in the existing Satellite.


### Assumptions made by AutomateDV

!!! note 
    These assumptions really only affect Satellites, or any other structures which rely on tracking changes over time (history).

The AutomateDV macros are intended for use alongside the Data Vault standard loading approach which assumes a batch contains delta feeds only.

A load may contain multiple 'batches', i.e. multiple days of data (groups of records with the same LDTS) and even intra-day feeds where
you may get multiple days of data, where each day contains multiple changes to each record for a given PK/HK.

Since AutomateDV v0.10.0 the above scenarios are accounted for, and we have added further guardrails and loading versatility to Satellites (no inta-day prior to v0.10.0).

THis said, it is still highly recommended to still ensure delta/atomic feeds of data from your stage. Apart from causing unpredictable results, it will also incur a hit to performance 
to load all data in every load. 

#### The `apply_source_filter` config option

!!! tip "New in v0.10.1"

If it cannot be guaranteed that a load contains **_new_** deltas (i.e. data which has not been loaded before) then we recommend enabling the
`apply_source_filter` config in your Satellites. This is done on a per-satellite basis if using config blocks, or can be applied to all Satellites
using YAML configs (see the [dbt docs](https://docs.getdbt.com/reference/model-configs#configuring-models)).

This will add an additional guardrail (to those added in v0.10.0) which will filter the data coming from the `source_model` during **_incremental loads_**.

Please note, that though convenient, this is not a substitution for designing your loading and staging approach correctly and using this
config option **_may_** incur performance penalties due to the additional JOIN logic.

```sql
-- Code simplified for brevity
-- All PK checks will have multiple checks for each PK if src_pk is a list (composite PK)
...,

valid_stg AS (
    SELECT s.*
    FROM source_data AS s
    LEFT JOIN latest_records AS sat
    ON s.pk = sat.pk 
    WHERE sat.CUSTOMER_PK IS NULL
    OR s.LOAD_DATE > (
        SELECT MAX(LOAD_DATE) FROM latest_records AS sat
        WHERE sat.pk = s.pk 
    )
),

...
```

It is important to note that this ensures **_new and unseen_** records are always loaded, whilst ignoring records already loaded 
(i.e. records prior to the MAX LDTS of the existing Satellite records).

##### Incremental predicates

You may have noticed this is similar to dbt's built-in [incremental predicates](https://docs.getdbt.com/docs/build/incremental-models#about-incremental_predicates)
and you would be correct. We've added this as a convenience option for our users. 

Though enabling `apply_source_filter` is more convenient, you may see better performance using incremental predicates instead, as dbt filters the data in the DML (MERGE statement) 
prior to the model accessing the data from its SELECT.


## Load Date/Timestamp Value

The Load Date/Timestamp (universally in AutomateDV, the `src_ldts` parameter) is important for audit purposes and allows us to track what we knew when.

This audit column records when the record was first loaded into the database. 

The Load Date/Timestamp should be the same for every record loaded in a batch, for every table loaded - this means that if 5 tables are being loaded in parallel, 
they should all have the same value for ldts. It is not correct to have the time that the model (sql file) itself gets executed as it will cause problems for audit. 

The above information explains why using something like `CURRENT_TIMESTAMP` - though seemingly a good idea at first - does not make sense for the LDTS value. 

Ideally, you should set it to a record generated from your ingestion tool of choice. For example when using Fivetran, it is often sensible to use `_FIVETRAN_SYNCED`.

Otherwise, we recommend using the [dbt's `run_started_at` variable](https://docs.getdbt.com/reference/dbt-jinja-functions/run_started_at) as 
the value for your derived column. This variable provides the time when a dbt run started.



Please see an example below.

```yaml
source_model: MY_STAGE
derived_columns:
  LOAD_DATETIME: TO_TIMESTAMP('{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S.%f") }}')
```

## Applied Date (Effectivity Date / Effective From)

This column (`src_eff` in macros where this applies) is the business-effective date of a record. 

This is different from the Load Date. The Applied Date is when the real-world event represented by a record took place, 
examples include ORDER_DATE, FLIGHT_DATETIME and more. Including this in Satellites, for example, is optional and is not
used in any of the loading logic; it is for processing in business rules and the presentation layer downstream where 
Bi-temporarily (having two timelines; when it happened src_eff - and when we knew it - src_ldts) is important to the 
business.

It is important to not 'invent' the Applied Date. Only include an applied date in relevant objects where data already 
exists in the source system feeding that object.

## Record source table code

We suggest you use a code for your record source. This can be anything that makes sense for your particular context,
though usually an integer or alphanumeric value works well. The code often gets used to look up the full table name in
a reference table.

You may do this with AutomateDV by providing the code as a constant in the [staging](../tutorial/tut_staging.md) layer, using
the [stage](../macros/index.md#stage) macro. The [staging walk-through](../tutorial/tut_staging.md) presents this exact use-case in
the code examples.

If there is already a source in the raw staging layer, you may keep this or override it using
the [stage](../macros/index.md#stage) macro.
