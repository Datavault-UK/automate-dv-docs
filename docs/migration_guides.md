## Migrating from 0.11.5 to 0.12.0

This only affects ghost records (`enable_ghost_records: true`) on **Postgres**, and on **Databricks with `enable_native_hashes: true`**.

### Changes

A ghost record's hash key and hashdiff are meant to be all zero bytes, as on the other platforms: 16 bytes for MD5, 20 for SHA-1 and 32 for SHA-256.
On these two platforms they were instead the text `0000...` stored as binary (for MD5, 32 bytes of the character `0`), which is twice the length of a real hash.
From v0.12.0 they are zero bytes.

#### What does this mean for me?

The first time each satellite loads after upgrading, it gets a second ghost record with the new key, because the old one no longer matches.
Delete the old ghost record from each satellite. For example, with MD5 hashes:

=== "Postgres"

    ```sql
    DELETE FROM <satellite> WHERE <src_pk> = CAST('00000000000000000000000000000000' AS BYTEA);
    ```

=== "Databricks (native hashes)"

    ```sql
    DELETE FROM <satellite> WHERE <src_pk> = CAST('00000000000000000000000000000000' AS BINARY);
    ```

Use 40 zeros for SHA-1 and 64 for SHA-256.

On Postgres, PITs now use the same zero key for satellites that have no record at a point in time, so it still matches the satellite's ghost record.
Rebuild incremental PITs with `--full-refresh` so older rows use the new key.

## Migrating from 0.9.7 to 0.10.0

### Changes

The `sat()` macro has finally had its limitations removed and should be more performant and robust against 
loading intraday/multi-batch data. See the updated [loading docs](./best_practises/loading.md#satellites) for more details on how this works.

#### What does this mean for me?

TLDR; Nothing much! Read below for more information.

We have extensively tested the new loading approach and in the vast majority of cases it should work exactly as it did 
before without any changes to your processes.

That said, users who are using the AutomateDV custom materialisations for loading satellites, may now switch this off and use 
the standard `incremental` materialisation. The `sat()` macro still supports these materialisations, however, so no rush to migrate. 

We strongly recommend switching off the custom materialisations for Satellites, however, as you will gain huge performance improvements.

It is also worth noting that the custom materialsiations provided by AutomateDV were never intended for production purposes, and to make this
clear, we have added a new warning message when using them. 

A big thank you to our community for your patience whilst we worked on removing this limitation. 

Happy satellite loading!

## Migrating from 0.8.3 to 0.9.0

This will only affect users using the `pit()` macro. 

### Changes

- The `stage_tables` parameter has been changed to `stage_table_ldts` to match with the equivalent parameter in the `bridge()` macro.

    === "Before (v0.8.3)"
    
        ```jinja hl_lines="4"
        {{ automate_dv.pit(source_model=source_model, src_pk=src_pk,
                           as_of_dates_table=as_of_dates_table,
                           satellites=satellites,
                           stage_tables=stage_tables,
                           src_ldts=src_ldts) }}
        ```
    
    === "After (v0.9.0)"
    
        ```jinja hl_lines="4"
        {{ automate_dv.pit(source_model=source_model, src_pk=src_pk,
                           as_of_dates_table=as_of_dates_table,
                           satellites=satellites,
                           stage_tables_ldts=stage_tables_ldts,
                           src_ldts=src_ldts) }}
        ```