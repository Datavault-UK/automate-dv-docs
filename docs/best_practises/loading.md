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

As this always skips the first record (as the first record will not have a previous previous record) we handle this separately.

For a base load, we then insert all of these changed records, as well as the first record. 
The first record is always different from all of the rest due to ordering by the LDTS (earliest first), 
unless a true duplicate is present in which case we only take one instance. 

### Incremental load

For an incremental load, we follow the same process as a Base load except we treat the first record differently. In an incrmenetal load we
insert the first record of a batch only if it is different from the latest record in the existing Satellite. 

If the first record is the same as the latest Satellite record, then by definition the first record in our set of differing hashdiffs must be different.
The first record in the batch will not be inserted if it is the same as the latest in the existing Satellite.


## Load Date/Timestamp Value

The Load Date/Timestamp (universally in AutomateDV, the src_ldts parameter) is important for audit purposes and allows us to track what we knew when.

## Record source table code

We suggest you use a code for your record source. This can be anything that makes sense for your particular context,
though usually an integer or alpha-numeric value works well. The code often gets used to look up the full table name in
a reference table.

You may do this with AutomateDV by providing the code as a constant in the [staging](../tutorial/tut_staging.md) layer, using
the [stage](../macros/index.md#stage) macro. The [staging walk-through](../tutorial/tut_staging.md) presents this exact use-case in
the code examples.

If there is already a source in the raw staging layer, you may keep this or override it using
the [stage](../macros/index.md#stage) macro.
