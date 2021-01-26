### Extending dbtvault

This page describes how write your own macros to replace existing macros provided in dbtvault.


### adapter.dispatch

Every macro in dbtvault first calls [adapter.dispatch](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#dispatch) to find platform specific implementations of the macro to execute.

Here is an example:

=== "hub.sql"

    ```jinja
    {%- macro hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}

    {{- adapter.dispatch('hub', packages = dbtvault.get_dbtvault_namespaces())(src_pk=src_pk, src_nk=src_nk,
                                                                               src_ldts=src_ldts, src_source=src_source,
                                                                               source_model=source_model) -}}

    {%- endmacro -%}
    ```

This snippet contains the magic, the `get_dbtvault_namespaces()` which is defined as follows:


=== "get_package_namespaces.sql"

    ```jinja
    {%- macro get_dbtvault_namespaces() -%}
        {%- set override_namespaces = var('adapter_packages', []) -%}
        {%- do return(override_namespaces + ['dbtvault']) -%}
    {%- endmacro -%}
    ```

To override the hub macro and ensure dbt uses your own implementation of it, you simply need to provide your project's name to the `adapter_packages` variable.

For example:

=== "dbt_project.yml"

    ```yaml
    name: my_dbt_project
    version: 1.0.0
    
    config-version: 2
    
    vars:
      adapter_packages:
        - "my_dbt_project"
    ```

With this variable, an implementation of the `hub` macro could be defined in your own project as follows:


=== "my_hub_macro.sql"

    ```jinja
    {%- macro default__hub(src_pk, src_nk, src_ldts, src_source, source_model) -%}
        
        {%- do log("My super amazing implementation of a hub macro will be coming soon!", true) -%}

    {%- endmacro -%}
    ```

...and that's it! Yay!

Please ensure you read the [adapter.dispatch](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#dispatch) docs for more details.