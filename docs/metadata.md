dbtvault is metadata driven. On this page, we provide an overview of how to provide and store that data.

For further detail about how to use the macros in this section, see [table templates](macros.md#table-templates).

### Approaches

This page will describe just *one* way of providing metadata to the macros. There are many ways to do it, 
and it comes down to user and organisation preference.


!!! note
    The macros **do not care** how the metadata parameters are provided, as long as they are of the correct type.
    Parameter data types are defined on the [macros](macros.md) page.
    
    **All examples in the following sections will produce the same hub structure, the only difference is how the metadata is provided.**
    

It is worth noting that with larger projects, storing all the metadata in the `dbt_project.yml` file can quickly 
become unwieldy. See [the problem with metadata](#the-problem-with-metadata) for a more detailed discussion.

#### dbt_project.yml

Variables can be provided to macros via the `dbt_project.yml` file instead of being specified in
the models themselves. This keeps the metadata all in one place and simplifies the use of dbtvault by reducing model
creation to a copy and paste process of the model file, and just providing different metadata in the `dbt_project.yml`
file.

!!! warning "Using variables in dbt_project.yml"
    Prior to dbt v0.19.0, you must add `config-version: 1` to your `dbt_project.yml`. 
    From dbt v0.19.0 onwards, this feature is now **permanently removed**.
    
    Read more:
    
    - [Permanent removal](https://github.com/fishtown-analytics/dbt/releases/tag/v0.19.0)
    - [Our suggestion to dbt](https://github.com/fishtown-analytics/dbt/issues/2377) (closed in favour of [2401](https://github.com/fishtown-analytics/dbt/issues/2401))
    - [dbt documentation on the change](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-0-17-0/#better-variable-scoping-semantics)


##### Example

=== "dbt_project.yml"

    ```yaml
    models:
      hubs:
        hub_customer:
          vars:
            source_model: 'stg_web_customer_hashed'
            src_pk: 'CUSTOMER_PK'
            src_nk: 'CUSTOMER_KEY'
            src_ldts: 'LOAD_DATETIME'
            src_source: 'RECORD_SOURCE'
    ``` 

#### Per-model - Variables 

You may also provide metadata on a per-model basis. This is useful if you have a large amount of structures, and you
are quickly filling up your `dbt_project.yml` file, or for a specific model you have a large amount of metadata
and would like to reduce the clutter in the `dbt_project.yml` file.

##### Example

=== "hub_customer.sql"

    ```jinja
    {%- set source_model = "stg_web_customer_hashed" -%}
    {%- set src_pk = "CUSTOMER_PK" -%}
    {%- set src_nk = "CUSTOMER_KEY" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

#### Per-Model - YAML strings 

If you want to provide metadata inside the model itself, but find yourself disliking the format for 
larger collections of metadata or certain data types (e.g. dict literals), then providing a YAML String is a good 
alternative to using `set`. This method takes advantage of the `fromyml()` built-in jinja function provided by dbt, 
which is documented [here](https://docs.getdbt.com/reference/dbt-jinja-functions/fromyaml/). 

The below example for a hub is a little excessive for the small amount of metadata provided, so there is also a stage 
example provided to help better convey the difference.

##### Example

=== "hub_customer.sql"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: 'stg_web_customer_hashed'
    src_pk: 'CUSTOMER_PK'
    src_nk: 'CUSTOMER_KEY'
    src_ldts: 'LOAD_DATETIME'
    src_source: 'RECORD_SOURCE'
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ dbtvault.hub(src_pk=metadata_dict["src_pk"],
                    src_nk=metadata_dict["src_nk"], 
                    src_ldts=metadata_dict["src_ldts"],
                    src_source=metadata_dict["src_ldts"],
                    source_model=metadata_dict["source_model"]) }}
    ```

=== "stg_customer.sql"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: "raw_source"
    hashed_columns:
      CUSTOMER_PK: "CUSTOMER_ID"
      CUST_CUSTOMER_HASHDIFF:
        is_hashdiff: true
        columns:
          - "CUSTOMER_DOB"
          - "CUSTOMER_ID"
          - "CUSTOMER_NAME"
          - "!9999-12-31"
      CUSTOMER_HASHDIFF:
        is_hashdiff: true
        columns:
          - "CUSTOMER_ID"
          - "NATIONALITY"
          - "PHONE"
    derived_columns:
      SOURCE: "!STG_BOOKING"
      EFFECTIVE_FROM: "BOOKING_DATE"
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: "CUSTOMER_ID"
        order_by: "BOOKING_DATE"
    {% endset %}
       
    {% set metadata_dict = fromyaml(yaml_metadata) %}
       
    {% set source_model = metadata_dict['source_model'] %}
       
    {% set derived_columns = metadata_dict['derived_columns'] %}
       
    {% set hashed_columns = metadata_dict['hashed_columns'] %}
       
    {% set ranked_columns = metadata_dict['ranked_columns'] %}
    
    {{ dbtvault.stage(include_source_columns=true,
                      source_model=source_model,
                      derived_columns=derived_columns,
                      hashed_columns=hashed_columns,
                      ranked_columns=ranked_columns) }}
    ```

### Staging

#### Parameters

[stage macro parameters](macros.md#stage)

#### Metadata

=== "Per-model - YAML strings"
    === "All components"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: "raw_source"
        hashed_columns:
        CUSTOMER_PK: "CUSTOMER_ID"
        CUST_CUSTOMER_HASHDIFF:
          is_hashdiff: true
          columns:
            - "CUSTOMER_DOB"
            - "CUSTOMER_ID"
            - "CUSTOMER_NAME"
            - "!9999-12-31"
        CUSTOMER_HASHDIFF:
          is_hashdiff: true
          columns:
            - "CUSTOMER_ID"
            - "NATIONALITY"
            - "PHONE"
        derived_columns:
          SOURCE: "!STG_BOOKING"
          EFFECTIVE_FROM: "BOOKING_DATE"
        ranked_columns:
          DBTVAULT_RANK:
            partition_by: "CUSTOMER_ID"
            order_by: "BOOKING_DATE"
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict['source_model'] %}
        
        {% set derived_columns = metadata_dict['derived_columns'] %}
        
        {% set hashed_columns = metadata_dict['hashed_columns'] %}

        {% set ranked_columns = metadata_dict['ranked_columns'] %}
        
        {{ dbtvault.stage(include_source_columns=true,
                          source_model=source_model,
                          derived_columns=derived_columns,
                          hashed_columns=hashed_columns,
                          ranked_columns=ranked_columns) }}
        ```

    === "Only Source (ref style)"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: "raw_source"
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict['source_model'] %}
        
        {{ dbtvault.stage(include_source_columns=true,
                          source_model=source_model,
                          derived_columns=none,
                          hashed_columns=none,
                          ranked_columns=none) }}
        ```
    
    === "Only Source (source style)"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: 
            raw_source_name: "source_table_name"
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict['source_model'] %}
        
        {{ dbtvault.stage(include_source_columns=true,
                          source_model=source_model,
                          derived_columns=none,
                          hashed_columns=none,
                          ranked_columns=none) }}
        ```

    === "Only hashing"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: "raw_source"
        hashed_columns:
        CUSTOMER_PK: "CUSTOMER_ID"
        CUST_CUSTOMER_HASHDIFF:
          is_hashdiff: true
          columns:
            - "CUSTOMER_DOB"
            - "CUSTOMER_ID"
            - "CUSTOMER_NAME"
            - "!9999-12-31"
        CUSTOMER_HASHDIFF:
          is_hashdiff: true
          columns:
            - "CUSTOMER_ID"
            - "NATIONALITY"
            - "PHONE"
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict['source_model'] %}
        
        {% set hashed_columns = metadata_dict['hashed_columns'] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=none,
                          hashed_columns=hashed_columns,
                          ranked_columns=none) }}
        ```

    === "Only derived"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: "raw_source"
        derived_columns:
            SOURCE: "!STG_BOOKING"
            EFFECTIVE_FROM: "BOOKING_DATE"
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict['source_model'] %}
        
        {% set derived_columns = metadata_dict['derived_columns'] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=derived_columns,
                          hashed_columns=none,
                          ranked_columns=none) }}
        ```

    === "Only ranked"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: "raw_source"
        ranked_columns:
          DBTVAULT_RANK:
            partition_by: "CUSTOMER_ID"
            order_by: "BOOKING_DATE"
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict['source_model'] %}
        
        {% set derived_columns = metadata_dict['derived_columns'] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=none,
                          hashed_columns=none,
                          ranked_columns=ranked_columns) }}
        ```

    === "Exclude Columns flag"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: "raw_source"
        hashed_columns:
          CUSTOMER_PK: "CUSTOMER_ID"
          CUSTOMER_DETAILS_HASHDIFF:
            is_hashdiff: true
            exclude_columns: true
            columns:
              - "PRICE"
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - "CUSTOMER_ID"
              - "NATIONALITY"
              - "PHONE"
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict['source_model'] %}
        
        {% set hashed_columns = metadata_dict['hashed_columns'] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=none,
                          hashed_columns=hashed_columns,
                          ranked_columns=none) }}
        ```

=== "dbt_project.yml"

    !!! warning "Only available with dbt config-version: 1"

    === "All components"

        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:
                  source_model: "raw_source"
                  hashed_columns:
                    CUSTOMER_PK: "CUSTOMER_ID"
                    CUST_CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_DOB"
                        - "CUSTOMER_ID"
                        - "CUSTOMER_NAME"
                        - "!9999-12-31"
                    CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_ID"
                        - "NATIONALITY"
                        - "PHONE"
                  derived_columns:
                    SOURCE: "!STG_BOOKING"
                    EFFECTIVE_FROM: "BOOKING_DATE"
                  ranked_columns:
                    DBTVAULT_RANK:
                      partition_by: "CUSTOMER_ID"
                      order_by: "BOOKING_DATE"
        ```

    === "Only Source"

        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:
                  source_model: "raw_source"
        ```

    === "Only hashing"

        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:
                  include_source_columns: false
                  source_model: "raw_source"
                  hashed_columns:
                    CUSTOMER_PK: "CUSTOMER_ID"
                    CUST_CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_DOB"
                        - "CUSTOMER_ID"
                        - "CUSTOMER_NAME"
                        - "!9999-12-31"
                    CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_ID"
                        - "NATIONALITY"
                        - "PHONE"
        ```

    === "Only derived"

        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:   
                  include_source_columns: false
                  source_model: "raw_source"
                  derived_columns:
                    SOURCE: "!STG_BOOKING"
                    EFFECTIVE_FROM: "BOOKING_DATE"
        ```

    === "Only ranked"

        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:   
                  source_model: "raw_source"
                  ranked_columns:
                    DBTVAULT_RANK:
                      partition_by: "CUSTOMER_ID"
                      order_by: "BOOKING_DATE"
        ```

    === "Exclude Columns flag"

        ```yaml
        models:
          my_dbtvault_project:
            staging:
              my_staging_model:
                vars:
                  include_source_columns: false
                  source_model: "raw_source"
                  hashed_columns:
                    CUSTOMER_PK: "CUSTOMER_ID"
                    CUSTOMER_DETAILS_HASHDIFF:
                      is_hashdiff: true
                      exclude_columns: true
                      columns:
                        - "PRICE"
                    CUSTOMER_HASHDIFF:
                      is_hashdiff: true
                      columns:
                        - "CUSTOMER_ID"
                        - "NATIONALITY"
                        - "PHONE"
        ```

### Hubs

#### Parameters

[hub macro parameters](macros.md#hub)

#### Metadata

=== "Per-Model - Variables"

    === "Single Source"

        ```jinja
        {%- set source_model = "stg_customer_hashed" -%}
        {%- set src_pk = "CUSTOMER_PK" -%}
        {%- set src_nk = "CUSTOMER_KEY" -%}
        {%- set src_ldts = "LOADDATE" -%}
        {%- set src_source = "SOURCE" -%}
        
        {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

    === "Multi Source"

        ```jinja
        {%- set source_model = ["stg_web_customer_hashed", "stg_crm_customer_hashed"] -%}
        {%- set src_pk = "CUSTOMER_PK" -%}
        {%- set src_nk = "CUSTOMER_KEY" -%}
        {%- set src_ldts = "LOADDATE" -%}
        {%- set src_source = "SOURCE" -%}
        
        {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

    === "Composite NK"

        ```jinja
        {%- set source_model = "stg_customer_hashed" -%}
        {%- set src_pk = "CUSTOMER_PK" -%}
        {%- set src_nk = ["CUSTOMER_KEY", "CUSTOMER_DOB"] -%}
        {%- set src_ldts = "LOADDATE" -%}
        {%- set src_source = "SOURCE" -%}
        
        {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

=== "dbt_project.yml"

    !!! warning "Only available with dbt config-version: 1"

    === "Single Source"

        ```yaml
        hub_customer:
          vars:
            source_model: 'stg_customer_hashed'
            src_pk: 'CUSTOMER_PK'
            src_nk: 'CUSTOMER_KEY'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

    === "Multi Source"

        ```yaml
        hub_customer:
          vars:
            source_model:
              - 'stg_web_customer_hashed'
              - 'stg_crm_customer_hashed'
            src_pk: 'CUSTOMER_PK'
            src_nk: 'CUSTOMER_KEY'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

    === "Composite NK"

        ```yaml
        hub_customer:
          vars:
            source_model: 'stg_customer_hashed'
            src_pk: 'CUSTOMER_PK'
            src_nk:
              - 'CUSTOMER_KEY'
              - 'CUSTOMER_DOB'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

### Links

#### Parameters

[link macro parameters](macros.md#link)

#### Metadata

=== "Per-Model - Variables"

    === "Single Source"
        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "LINK_CUSTOMER_NATION_PK" -%}
        {%- set src_fk = ["CUSTOMER_PK", "NATION_PK"] -%}
        {%- set src_ldts = "LOADDATE" -%}
        {%- set src_source = "SOURCE" -%}
        
        {{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                         src_source=src_source, source_model=source_model) }}
        ```

    === "Multi Source"
        ```jinja
        {%- set source_model = ["v_stg_orders", "v_stg_transactions"] -%}
        {%- set src_pk = "LINK_CUSTOMER_NATION_PK" -%}
        {%- set src_fk = ["CUSTOMER_PK", "NATION_PK"] -%}
        {%- set src_ldts = "LOADDATE" -%}
        {%- set src_source = "SOURCE" -%}
        
        {{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                         src_source=src_source, source_model=source_model) }}
        ```

=== "dbt_project.yml"

    !!! warning "Only available with dbt config-version: 1"

    === "Single Source"

        ```yaml
        link_customer_nation:
          vars:
            source_model: 'v_stg_orders'
            src_pk: 'LINK_CUSTOMER_NATION_PK'
            src_fk:
              - 'CUSTOMER_PK'
              - 'NATION_PK'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

    === "Multi Source"

        ```yaml
        link_customer_nation:
          vars:
            source_model:
              - 'v_stg_orders'
              - 'v_stg_transactions'
            src_pk: 'LINK_CUSTOMER_NATION_PK'
            src_fk:
              - 'CUSTOMER_PK'
              - 'NATION_PK'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

### Transactional links
###### (also known as non-historised links)

#### Parameters

[t_link macro parameters](macros.md#t_link)

#### Metadata


=== "Per-Model - Variables"

    ```jinja
    {%- set source_model = "v_stg_transactions" -%}
    {%- set src_pk = "TRANSACTION_PK" -%}
    {%- set src_fk = ["CUSTOMER_PK", "ORDER_PK"] -%}
    {%- set src_payload = ["TRANSACTION_NUMBER", "TRANSACTION_DATE", "TYPE", "AMOUNT"] -%}
    {%- set src_eff = "EFFECTIVE_FROM" -%}
    {%- set src_ldts = "LOADDATE" -%}
    {%- set src_source = "SOURCE" -%}
    
    {{ dbtvault.t_link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                       src_payload=src_payload, src_eff=src_eff,
                       src_source=src_source, source_model=source_model) }}
    ```

=== "dbt_project.yml"

    !!! warning "Only available with dbt config-version: 1"

    ```yaml
    t_link_transactions:
      vars:
        source_model: 'v_stg_transactions'
        src_pk: 'TRANSACTION_PK'
        src_fk:
          - 'CUSTOMER_PK'
          - 'ORDER_PK'
        src_payload:
          - 'TRANSACTION_NUMBER'
          - 'TRANSACTION_DATE'
          - 'TYPE'
          - 'AMOUNT'
        src_eff: 'EFFECTIVE_FROM'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```

### Satellites

#### Parameters

[sat macro parameters](macros.md#sat)

#### Metadata

=== "Per-Model - Variables"

    === "Standard"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "CUSTOMER_PK" -%}
        {%- set src_hashdiff = "CUSTOMER_HASHDIFF" -%}
        {%- set src_payload = ["NAME", "ADDRESS", "PHONE", "ACCBAL", "MKTSEGMENT", "COMMENT"] -%}
        {%- set src_eff = "EFFECTIVE_FROM" -%}
        {%- set src_ldts = "LOADDATE" -%}
        {%- set src_source = "SOURCE" -%}
        
        {{ dbtvault.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                        src_payload=src_payload, src_eff=src_eff,
                        src_ldts=src_ldts, src_source=src_source, 
                        source_model=source_model) }}
        ```

    === "Hashdiff Aliasing"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "CUSTOMER_PK" -%}
        {%- set src_hashdiff = {'source_column': "CUSTOMER_HASHDIFF", 'alias': "HASHDIFF"} -%}
        {%- set src_payload = ["NAME", "ADDRESS", "PHONE", "ACCBAL", "MKTSEGMENT", "COMMENT"] -%}
        {%- set src_eff = "EFFECTIVE_FROM" -%}
        {%- set src_ldts = "LOADDATE" -%}
        {%- set src_source = "SOURCE" -%}
        
        {{ dbtvault.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                        src_payload=src_payload, src_eff=src_eff,
                        src_ldts=src_ldts, src_source=src_source, 
                        source_model=source_model) }}
        ```

=== "dbt_project.yml"

    !!! warning "Only available with dbt config-version: 1"

    === "Standard"

        ```yaml
        sat_order_customer_details:
          vars:
            source_model: 'v_stg_orders'
            src_pk: 'CUSTOMER_PK'
            src_hashdiff: 'CUSTOMER_HASHDIFF'
            src_payload:
              - 'NAME'
              - 'ADDRESS'
              - 'PHONE'
              - 'ACCBAL'
              - 'MKTSEGMENT'
              - 'COMMENT'
            src_eff: 'EFFECTIVE_FROM'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

    === "Hashdiff Aliasing"

        ```yaml
        sat_order_customer_details:
          vars:
            source_model: 'v_stg_orders'
            src_pk: 'CUSTOMER_PK'
            src_hashdiff: 
              source_column: "CUSTOMER_HASHDIFF"
              alias: "HASHDIFF"
            src_payload:
              - 'NAME'
              - 'ADDRESS'
              - 'PHONE'
              - 'ACCBAL'
              - 'MKTSEGMENT'
              - 'COMMENT'
            src_eff: 'EFFECTIVE_FROM'
            src_ldts: 'LOADDATE'
            src_source: 'SOURCE'
        ```

Hashdiff aliasing allows you to set an alias for the `HASHDIFF` column.
[Read more](best_practices.md#hashdiff-aliasing)

### Effectivity Satellites

#### Parameters

[eff_sat macro parameters](macros.md#eff_sat)

#### Metadata

=== "Per-Model - Variables"

    ```jinja
    {%- set source_model = "v_stg_orders" -%}
    {%- set src_pk = "TRANSACTION_PK" -%}
    {%- set src_dfk = "CUSTOMER_PK" -%}
    {%- set src_sfk = "NATION_PK" -%}
    {%- set src_start_date = "START_DATE" -%}
    {%- set src_end_date = "END_DATE" -%}

    {%- set src_eff = "EFFECTIVE_FROM" -%}
    {%- set src_ldts = "LOADDATE" -%}
    {%- set src_source = "SOURCE" -%}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date, 
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source, 
                        source_model=source_model) }}
    ```

=== "dbt_project.yml"

    !!! warning "Only available with dbt config-version: 1"

    ```yaml
    eff_sat_customer_nation:
      vars:
        source_model: 'v_stg_transactions'
        src_pk: 'TRANSACTION_PK'
        src_dfk: 'CUSTOMER_PK'
        src_sfk: 'NATION_PK'
        src_start_date: 'START_DATE'
        src_end_date: 'END_DATE'
        src_eff: 'EFFECTIVE_FROM'
        src_ldts: 'LOADDATE'
        src_source: 'SOURCE'
    ```
___

### The problem with metadata

If metadata is stored in the `dbt_project.yml`, you can probably foresee the file getting very large for bigger 
projects. If your metadata is defined and stored in each model, it becomes harder to generate and develop with, 
but it can be easier to manage. Model-level metadata alleviates the issue, but will not completely solve it.

Whichever approach is chosen, metadata storage and retrieval is difficult without a dedicated tool. 
To help manage large amounts of metadata, we recommend the use of external corporate tools such as WhereScape, 
Matillion, or Erwin Data Modeller. 

In the future, dbt will likely support better ways to manage metadata at this level, to put off the need for a tool a 
little longer. Discussions are [already ongoing](https://github.com/fishtown-analytics/dbt/issues/2401), and we hope
to be able to advise on better ways to manage metadata in future. 