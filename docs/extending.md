### Extending AutomateDV

This page describes how write your own macros to replace existing macros provided in AutomateDV.


### adapter.dispatch

Every macro in AutomateDV first calls [adapter.dispatch](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#dispatch) to find platform specific implementations of the macro to execute.

Here is an example:

=== "hub.sql"

    ```jinja
    {%- macro hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}

    {{- adapter.dispatch('hub', 'automatedv')(src_pk=src_pk, src_nk=src_nk,
                                            src_ldts=src_ldts, src_source=src_source,
                                            source_model=source_model) -}}

    {%- endmacro -%}
    ```

This snippet defines the macro namespace as `'automatedv'`, ensuring that this macro gets found in the list of macros implemented in the AutomateDV package namespace.

To override the `hub` macro and ensure dbt uses your own implementation of it, you simply need to provide a configuration in your `dbt_project.yml` as follows:

=== "dbt_project.yml"

    ```yaml
    name: my_dbt_project
    version: 1.0.0
    
    config-version: 2
    
    dispatch:
      - macro_namespace: automatedv
        search_order: ['my_project', 'automatedv']  # enable override
    ```

With this configuration change, an implementation of the `hub` macro could be defined in your own project as follows:


=== "my_hub_macro.sql"

    ```jinja
    {%- macro default__hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}
        
        {%- do log("My super amazing implementation of a hub macro will be coming soon!", true) -%}

    {%- endmacro -%}
    ```

Here are some further examples, showing how to override a platform-specific implementation:

=== "my_hub_macro.sql"

    === "Snowflake"

        ```jinja
        {%- macro default__hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}
            
            {%- do log("My super amazing implementation of a hub macro for Snowflake will be coming soon!", true) -%}
    
        {%- endmacro -%}
        ```

    === "Google BigQuery"

        ```jinja
        {%- macro bigquery__hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}
            
            {%- do log("My super amazing implementation of a hub macro for BigQuery will be coming soon!", true) -%}
    
        {%- endmacro -%}
        ```

    === "MS SQL Server"

        ```jinja
        {%- macro sqlserver__hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}
            
            {%- do log("My super amazing implementation of a hub macro for MS SQL Server will be coming soon!", true) -%}
    
        {%- endmacro -%}
        ```


...and that's it! Yay!

!!! note "Further reading"
    Please ensure you read the dbt [adapter.dispatch](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#dispatch) and
    [dispatch config](https://next.docs.getdbt.com/reference/project-configs/dispatch-config) docs for more details.