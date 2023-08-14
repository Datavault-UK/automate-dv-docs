## Migrating from 0.9.7 to 0.10.0

### Changes

The `sat()` macro has finally had its limitations removed and should be more performance and robust against 
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