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