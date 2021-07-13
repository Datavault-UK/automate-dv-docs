### Extending dbtvault

This page describes how write your own macros to replace existing macros provided in dbtvault.


### adapter.dispatch

Every macro in dbtvault first calls [adapter.dispatch](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#dispatch) to find platform specific implementations of the macro to execute.

Here is an example:

=== "hub.sql"

    ```jinja
    {%- macro hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}

    {{- adapter.dispatch('hub', 'dbtvault')(src_pk=src_pk, src_nk=src_nk,
                                            src_ldts=src_ldts, src_source=src_source,
                                            source_model=source_model) -}}

    {%- endmacro -%}
    ```

This snippet defines the macro namespace as `'dbtvault'`, ensuring that this macro gets found in the list of macros implemented in the dbtvault package namespace.

To override the hub macro and ensure dbt uses your own implementation of it, you simply need to provide a configuration in your `dbt_project.yml` as follows:

=== "dbt_project.yml"

    ```yaml
    name: my_dbt_project
    version: 1.0.0
    
    config-version: 2
    
    dispatch:
      - macro_namespace: dbtvault
        search_order: ['my_project', 'dbtvault']  # enable override
    ```

With this configuration change, an implementation of the `hub` macro could be defined in your own project as follows:


=== "my_hub_macro.sql"

    ```jinja
    {%- macro default__hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}
        
        {%- do log("My super amazing implementation of a hub macro will be coming soon!", true) -%}

    {%- endmacro -%}
    ```

...and that's it! Yay!

Please ensure you read the [adapter.dispatch](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#dispatch) and
[dispatch config](https://next.docs.getdbt.com/reference/project-configs/dispatch-config) docs for more details.