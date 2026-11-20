# Metadata

AutomateDV is metadata driven. On this page, we provide an overview of how to provide and store the metadata for
**AutomateDV macros**, followed by example metadata for every structure.

For all other metadata and configurations, please refer to
the [dbt configurations reference](https://docs.getdbt.com/reference/dbt_project.yml).

For further details about how to use the macros on this page, see [table templates](macros/index.md#table-templates).

## Providing metadata

There are many ways to provide metadata to the macros, and it comes down to user and organisation preference.
The examples on this page provide the metadata for a given model in the model itself, using Jinja **variables** or
**YAML strings**.

!!! note
    The macros **do not care** how the metadata parameters get provided, as long as they are of the correct type.
    Parameter data types definitions are available on the [macros](macros/index.md) page. The techniques below are simply our
    recommendations, which we hope provide a good balance of manageability and readability.

Examples are shown on **Variables** and **YAML strings** tabs.
Switching tab on one example switches every example on the page.

- **Variables:** each piece of metadata is set as a separate Jinja variable using `set`, and the variables are then
  passed to the macro. This is concise for structures with a small amount of simple metadata.
- **YAML strings:** if you find the variables format hard to read for larger collections of metadata, or for certain
  data types (e.g. dict literals), then a YAML string inside a block `set` assignment is a good alternative to
  multiple individual `set` assignments. The string is parsed into a dictionary (`metadata_dict`) using dbt's
  [`fromyaml()`](https://docs.getdbt.com/reference/dbt-jinja-functions/fromyaml/) function, and each value is then
  passed to the macro.

!!! warning "YAML strings are not syntax checked"
    dbt does not yet provide any syntax checking in these YAML strings, often leading to confusing and
    misleading error messages. If you find that variables which are extracted from the YAML string are empty, it is an
    indicator that the YAML did not compile correctly, and you should check your formatting; including indentation.

=== "Variables"

    ```jinja
    {%- set source_model = "stg_customer_hashed" -%}
    {%- set src_pk = "CUSTOMER_HK" -%}
    {%- set src_nk = "CUSTOMER_ID" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                       src_source=src_source, source_model=source_model) }}
    ```

=== "YAML strings"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: stg_customer_hashed
    src_pk: CUSTOMER_HK
    src_nk: CUSTOMER_ID
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                       src_nk=metadata_dict["src_nk"],
                       src_ldts=metadata_dict["src_ldts"],
                       src_source=metadata_dict["src_source"],
                       source_model=metadata_dict["source_model"]) }}
    ```

## Example metadata

The examples below cover the metadata for each structure.

!!! note "Additional notes"
    - **Extra columns:** all table macros (except `lat_sat`) also accept an optional `src_extra_columns` parameter, 
      which selects additional columns from the source model. It is shown in the [Reference Tables](#reference-tables)
      examples and works the same way for every macro.
    - **Materialisation:** the examples do not include a `config()` block, unless a structure is recommended to use 
      a different materialisation to the rest of the vault (e.g. [Latest Satellites](#latest-satellites)). 
      See [Materialisations](materialisations.md) for more details.

## Staging

[stage macro parameters](macros/index.md#stage)

!!! tip "We recommend YAML strings for staging"
    Staging models typically have much more metadata than any other structure, with many hashed, derived, null and
    ranked columns. YAML strings keep this large amount of metadata easier to read and maintain, so this is our
    recommended approach for the `stage` macro.

The `source_model` for a stage can be provided in `ref` style or `source` style.
[Read more](macros/index.md#source_model-syntax)

!!! note
    '!' at the beginning of strings is syntactic sugar provided by AutomateDV for creating constant values.
    [Read More](macros/stage_macro_configurations.md#defining-constants)

=== "All components"

    === "Variables"

        ```jinja
        {%- set source_model = "raw_source" -%}
        {%- set hashed_columns = {
            "CUSTOMER_HK": "CUSTOMER_ID",
            "CUST_CUSTOMER_HASHDIFF": {
                "is_hashdiff": true,
                "columns": ["CUSTOMER_DOB", "CUSTOMER_ID", "CUSTOMER_NAME", "!9999-12-31"]
            },
            "CUSTOMER_HASHDIFF": {
                "is_hashdiff": true,
                "columns": ["CUSTOMER_ID", "NATIONALITY", "PHONE"]
            }
        } -%}
        {%- set derived_columns = {
            "RECORD_SOURCE": "!STG_BOOKING",
            "EFFECTIVE_FROM": "BOOKING_DATE"
        } -%}
        {%- set null_columns = {
            "required": ["CUSTOMER_ID"],
            "optional": ["CUSTOMER_REF", "NATIONALITY"]
        } -%}
        {%- set ranked_columns = {
            "AUTOMATE_DV_RANK": {
                "partition_by": "CUSTOMER_ID",
                "order_by": "BOOKING_DATE"
            }
        } -%}
        
        {{ automate_dv.stage(include_source_columns=true,
                             source_model=source_model,
                             derived_columns=derived_columns,
                             null_columns=null_columns,
                             hashed_columns=hashed_columns,
                             ranked_columns=ranked_columns) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
          CUST_CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - CUSTOMER_DOB
              - CUSTOMER_ID
              - CUSTOMER_NAME
              - "!9999-12-31"
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - CUSTOMER_ID
              - NATIONALITY
              - PHONE
        derived_columns:
          RECORD_SOURCE: "!STG_BOOKING"
          EFFECTIVE_FROM: BOOKING_DATE
        null_columns:
          required:
            - CUSTOMER_ID
          optional:
            - CUSTOMER_REF
            - NATIONALITY
        ranked_columns:
          AUTOMATE_DV_RANK:
            partition_by: CUSTOMER_ID
            order_by: BOOKING_DATE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=true,
                             source_model=metadata_dict["source_model"],
                             derived_columns=metadata_dict["derived_columns"],
                             null_columns=metadata_dict["null_columns"],
                             hashed_columns=metadata_dict["hashed_columns"],
                             ranked_columns=metadata_dict["ranked_columns"]) }}
        ```

=== "Only Source (ref style)"

    === "Variables"

        ```jinja
        {%- set source_model = "raw_source" -%}
        
        {{ automate_dv.stage(include_source_columns=true,
                             source_model=source_model,
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=true,
                             source_model=metadata_dict["source_model"],
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

=== "Only Source (source style)"

    === "Variables"

        ```jinja
        {%- set source_model = {"raw_source_name": "source_table_name"} -%}
        
        {{ automate_dv.stage(include_source_columns=true,
                             source_model=source_model,
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model:
          raw_source_name: source_table_name
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=true,
                             source_model=metadata_dict["source_model"],
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

=== "Only hashing"

    === "Variables"

        ```jinja
        {%- set source_model = "raw_source" -%}
        {%- set hashed_columns = {
            "CUSTOMER_HK": "CUSTOMER_ID",
            "CUST_CUSTOMER_HASHDIFF": {
                "is_hashdiff": true,
                "columns": ["CUSTOMER_DOB", "CUSTOMER_ID", "CUSTOMER_NAME", "!9999-12-31"]
            },
            "CUSTOMER_HASHDIFF": {
                "is_hashdiff": true,
                "columns": ["CUSTOMER_ID", "NATIONALITY", "PHONE"]
            }
        } -%}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=source_model,
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=hashed_columns,
                             ranked_columns=none) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
          CUST_CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - CUSTOMER_DOB
              - CUSTOMER_ID
              - CUSTOMER_NAME
              - "!9999-12-31"
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - CUSTOMER_ID
              - NATIONALITY
              - PHONE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=metadata_dict["source_model"],
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=metadata_dict["hashed_columns"],
                             ranked_columns=none) }}
        ```

=== "Only derived"

    === "Variables"

        ```jinja
        {%- set source_model = "raw_source" -%}
        {%- set derived_columns = {
            "RECORD_SOURCE": "!STG_BOOKING",
            "EFFECTIVE_FROM": "BOOKING_DATE"
        } -%}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=source_model,
                             derived_columns=derived_columns,
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        derived_columns:
          RECORD_SOURCE: "!STG_BOOKING"
          EFFECTIVE_FROM: BOOKING_DATE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=metadata_dict["source_model"],
                             derived_columns=metadata_dict["derived_columns"],
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

=== "Only null key columns"

    === "Variables"

        ```jinja
        {%- set source_model = "raw_source" -%}
        {%- set null_columns = {
            "required": ["CUSTOMER_ID"],
            "optional": ["CUSTOMER_REF", "NATIONALITY"]
        } -%}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=source_model,
                             derived_columns=none,
                             null_columns=null_columns,
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        null_columns:
          required:
            - CUSTOMER_ID
          optional:
            - CUSTOMER_REF
            - NATIONALITY
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=metadata_dict["source_model"],
                             derived_columns=none,
                             null_columns=metadata_dict["null_columns"],
                             hashed_columns=none,
                             ranked_columns=none) }}
        ```

=== "Only ranked"

    === "Variables"

        ```jinja
        {%- set source_model = "raw_source" -%}
        {%- set ranked_columns = {
            "AUTOMATE_DV_RANK": {
                "partition_by": "CUSTOMER_ID",
                "order_by": "BOOKING_DATE"
            }
        } -%}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=source_model,
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=ranked_columns) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        ranked_columns:
          AUTOMATE_DV_RANK:
            partition_by: CUSTOMER_ID
            order_by: BOOKING_DATE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=metadata_dict["source_model"],
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=none,
                             ranked_columns=metadata_dict["ranked_columns"]) }}
        ```

=== "Exclude Columns flag"

    === "Variables"

        ```jinja
        {%- set source_model = "raw_source" -%}
        {%- set hashed_columns = {
            "CUSTOMER_HK": "CUSTOMER_ID",
            "CUSTOMER_DETAILS_HASHDIFF": {
                "is_hashdiff": true,
                "exclude_columns": true,
                "columns": ["PRICE"]
            },
            "CUSTOMER_HASHDIFF": {
                "is_hashdiff": true,
                "columns": ["CUSTOMER_ID", "NATIONALITY", "PHONE"]
            }
        } -%}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=source_model,
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=hashed_columns,
                             ranked_columns=none) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
          CUSTOMER_DETAILS_HASHDIFF:
            is_hashdiff: true
            exclude_columns: true
            columns:
              - PRICE
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - CUSTOMER_ID
              - NATIONALITY
              - PHONE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.stage(include_source_columns=false,
                             source_model=metadata_dict["source_model"],
                             derived_columns=none,
                             null_columns=none,
                             hashed_columns=metadata_dict["hashed_columns"],
                             ranked_columns=none) }}
        ```

## Hubs

[hub macro parameters](macros/index.md#hub)

=== "Single Source"

    === "Variables"

        ```jinja
        {%- set source_model = "stg_customer_hashed" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_nk = "CUSTOMER_ID" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                           src_source=src_source, source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: stg_customer_hashed
        src_pk: CUSTOMER_HK
        src_nk: CUSTOMER_ID
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                           src_nk=metadata_dict["src_nk"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

=== "Multi Source"

    === "Variables"

        ```jinja
        {%- set source_model = ["stg_web_customer_hashed", "stg_crm_customer_hashed"] -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_nk = "CUSTOMER_ID" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                           src_source=src_source, source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model:
          - stg_web_customer_hashed
          - stg_crm_customer_hashed
        src_pk: CUSTOMER_HK
        src_nk: CUSTOMER_ID
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}

        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                           src_nk=metadata_dict["src_nk"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

=== "Composite NK"

    === "Variables"

        ```jinja
        {%- set source_model = "stg_customer_hashed" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_nk = ["CUSTOMER_ID", "CUSTOMER_DOB"] -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                           src_source=src_source, source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: stg_customer_hashed
        src_pk: CUSTOMER_HK
        src_nk:
          - CUSTOMER_ID
          - CUSTOMER_DOB
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}

        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                           src_nk=metadata_dict["src_nk"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

## Links

[link macro parameters](macros/index.md#link)

=== "Single Source"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "LINK_CUSTOMER_NATION_HK" -%}
        {%- set src_fk = ["CUSTOMER_HK", "NATION_HK"] -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                            src_source=src_source, source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_orders
        src_pk: LINK_CUSTOMER_NATION_HK
        src_fk:
          - CUSTOMER_HK
          - NATION_HK
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.link(src_pk=metadata_dict["src_pk"],
                            src_fk=metadata_dict["src_fk"],
                            src_ldts=metadata_dict["src_ldts"],
                            src_source=metadata_dict["src_source"],
                            source_model=metadata_dict["source_model"]) }}
        ```

=== "Multi Source"

    === "Variables"

        ```jinja
        {%- set source_model = ["v_stg_orders", "v_stg_transactions"] -%}
        {%- set src_pk = "LINK_CUSTOMER_NATION_HK" -%}
        {%- set src_fk = ["CUSTOMER_HK", "NATION_HK"] -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                            src_source=src_source, source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model:
          - v_stg_orders
          - v_stg_transactions
        src_pk: LINK_CUSTOMER_NATION_HK
        src_fk:
          - CUSTOMER_HK
          - NATION_HK
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.link(src_pk=metadata_dict["src_pk"],
                            src_fk=metadata_dict["src_fk"],
                            src_ldts=metadata_dict["src_ldts"],
                            src_source=metadata_dict["src_source"],
                            source_model=metadata_dict["source_model"]) }}
        ```

<a id="transactional-links"></a>

## Non-Historized Links

[nh_link macro parameters](macros/index.md#nh_link)

!!! note
    Non-Historized Links were previously known as Transactional Links, and the `nh_link()` macro replaces the
    `t_link()` macro. `t_link()` is deprecated, but still available for backwards compatibility and takes the same
    parameters.

=== "Variables"

    ```jinja
    {%- set source_model = "v_stg_transactions" -%}
    {%- set src_pk = "TRANSACTION_HK" -%}
    {%- set src_fk = ["CUSTOMER_HK", "ORDER_HK"] -%}
    {%- set src_payload = ["TRANSACTION_NUMBER", "TRANSACTION_DATE", "TYPE", "AMOUNT"] -%}
    {%- set src_eff = "EFFECTIVE_FROM" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ automate_dv.nh_link(src_pk=src_pk, src_fk=src_fk, src_payload=src_payload,
                           src_eff=src_eff, src_ldts=src_ldts,
                           src_source=src_source, source_model=source_model) }}
    ```

=== "YAML strings"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: v_stg_transactions
    src_pk: TRANSACTION_HK
    src_fk:
      - CUSTOMER_HK
      - ORDER_HK
    src_payload:
      - TRANSACTION_NUMBER
      - TRANSACTION_DATE
      - TYPE
      - AMOUNT
    src_eff: EFFECTIVE_FROM
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}

    {{ automate_dv.nh_link(src_pk=metadata_dict["src_pk"],
                           src_fk=metadata_dict["src_fk"],
                           src_payload=metadata_dict["src_payload"],
                           src_eff=metadata_dict["src_eff"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
    ```

## Satellites

[sat macro parameters](macros/index.md#sat)

The `src_hashdiff` and `src_payload` parameters accept additional formats:

- **Hashdiff aliasing:** provide `src_hashdiff` as a mapping of `source_column` and `alias` to set an alias for the 
  hashdiff column in the Satellite. [Read more](best_practises/hashing.md#hashdiff-aliasing)
- **Excluding payload columns:** provide `src_payload` as a mapping with `exclude_columns: true` and a list of 
  `columns`. The payload will then contain every column in the source model which is not listed, and not used in 
  any other parameter. [Read more](macros/index.md#excluding-columns-from-the-payload)

=== "Standard"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_hashdiff = "CUSTOMER_HASHDIFF" -%}
        {%- set src_payload = ["NAME", "ADDRESS", "PHONE", "ACCBAL", "MKTSEGMENT", "COMMENT"] -%}
        {%- set src_eff = "EFFECTIVE_FROM" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                           src_payload=src_payload, src_eff=src_eff,
                           src_ldts=src_ldts, src_source=src_source,
                           source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_orders
        src_pk: CUSTOMER_HK
        src_hashdiff: CUSTOMER_HASHDIFF
        src_payload:
          - NAME
          - ADDRESS
          - PHONE
          - ACCBAL
          - MKTSEGMENT
          - COMMENT
        src_eff: EFFECTIVE_FROM
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
    
        {{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                           src_hashdiff=metadata_dict["src_hashdiff"],
                           src_payload=metadata_dict["src_payload"],
                           src_eff=metadata_dict["src_eff"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

=== "Hashdiff Aliasing"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_hashdiff = {"source_column": "CUSTOMER_HASHDIFF", "alias": "HASHDIFF"} -%}
        {%- set src_payload = ["NAME", "ADDRESS", "PHONE", "ACCBAL", "MKTSEGMENT", "COMMENT"] -%}
        {%- set src_eff = "EFFECTIVE_FROM" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                           src_payload=src_payload, src_eff=src_eff,
                           src_ldts=src_ldts, src_source=src_source,
                           source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_orders
        src_pk: CUSTOMER_HK
        src_hashdiff:
          source_column: CUSTOMER_HASHDIFF
          alias: HASHDIFF
        src_payload:
          - NAME
          - ADDRESS
          - PHONE
          - ACCBAL
          - MKTSEGMENT
          - COMMENT
        src_eff: EFFECTIVE_FROM
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
    
        {{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                           src_hashdiff=metadata_dict["src_hashdiff"],
                           src_payload=metadata_dict["src_payload"],
                           src_eff=metadata_dict["src_eff"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

=== "Exclude Payload Columns"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_hashdiff = "CUSTOMER_HASHDIFF" -%}
        {%- set src_payload = {"exclude_columns": true, "columns": ["NAME", "PHONE"]} -%}
        {%- set src_eff = "EFFECTIVE_FROM" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                           src_payload=src_payload, src_eff=src_eff,
                           src_ldts=src_ldts, src_source=src_source,
                           source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_orders
        src_pk: CUSTOMER_HK
        src_hashdiff: CUSTOMER_HASHDIFF
        src_payload:
          exclude_columns: true
          columns:
            - NAME
            - PHONE
        src_eff: EFFECTIVE_FROM
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
    
        {{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                           src_hashdiff=metadata_dict["src_hashdiff"],
                           src_payload=metadata_dict["src_payload"],
                           src_eff=metadata_dict["src_eff"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

## Effectivity Satellites

[eff_sat macro parameters](macros/index.md#eff_sat)

=== "Variables"

    ```jinja
    {%- set source_model = "v_stg_order_customer" -%}
    {%- set src_pk = "ORDER_CUSTOMER_HK" -%}
    {%- set src_dfk = ["ORDER_HK"] -%}
    {%- set src_sfk = "CUSTOMER_HK" -%}
    {%- set src_start_date = "START_DATE" -%}
    {%- set src_end_date = "END_DATE" -%}
    {%- set src_eff = "EFFECTIVE_FROM" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ automate_dv.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                           src_start_date=src_start_date, src_end_date=src_end_date,
                           src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                           source_model=source_model) }}
    ```

=== "YAML strings"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: v_stg_order_customer
    src_pk: ORDER_CUSTOMER_HK
    src_dfk:
      - ORDER_HK
    src_sfk: CUSTOMER_HK
    src_start_date: START_DATE
    src_end_date: END_DATE
    src_eff: EFFECTIVE_FROM
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ automate_dv.eff_sat(src_pk=metadata_dict["src_pk"],
                           src_dfk=metadata_dict["src_dfk"],
                           src_sfk=metadata_dict["src_sfk"],
                           src_start_date=metadata_dict["src_start_date"],
                           src_end_date=metadata_dict["src_end_date"],
                           src_eff=metadata_dict["src_eff"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
    ```

## Multi-Active Satellites (MAS)

[ma_sat macro parameters](macros/index.md#ma_sat)

=== "Variables"

    ```jinja
    {%- set source_model = "v_stg_customer" -%}
    {%- set src_pk = "CUSTOMER_HK" -%}
    {%- set src_cdk = ["CUSTOMER_PHONE", "EXTENSION"] -%}
    {%- set src_hashdiff = "HASHDIFF" -%}
    {%- set src_payload = ["CUSTOMER_NAME"] -%}
    {%- set src_eff = "EFFECTIVE_FROM" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ automate_dv.ma_sat(src_pk=src_pk, src_cdk=src_cdk, src_hashdiff=src_hashdiff,
                          src_payload=src_payload, src_eff=src_eff, src_ldts=src_ldts,
                          src_source=src_source, source_model=source_model) }}
    ```

=== "YAML strings"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: v_stg_customer
    src_pk: CUSTOMER_HK
    src_cdk:
      - CUSTOMER_PHONE
      - EXTENSION
    src_hashdiff: HASHDIFF
    src_payload:
      - CUSTOMER_NAME
    src_eff: EFFECTIVE_FROM
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ automate_dv.ma_sat(src_pk=metadata_dict["src_pk"],
                          src_cdk=metadata_dict["src_cdk"],
                          src_hashdiff=metadata_dict["src_hashdiff"],
                          src_payload=metadata_dict["src_payload"],
                          src_eff=metadata_dict["src_eff"],
                          src_ldts=metadata_dict["src_ldts"],
                          src_source=metadata_dict["src_source"],
                          source_model=metadata_dict["source_model"]) }}
    ```

## Extended Tracking Satellites (XTS)

[xts macro parameters](macros/index.md#xts)

### Understanding the `src_satellite` parameter

The `src_satellite` parameter provides the means to define the satellites which the XTS tracks.

The mapping matches columns in the stage layer (using the `stage` macro) to the `SATELLITE_NAME` and `HASHDIFF` columns
in the XTS. Each key in `src_satellite` is the name of a tracked satellite, containing:

- `sat_name`: maps the XTS `SATELLITE_NAME` column to the stage column holding that satellite's name.
- `hashdiff`: maps the XTS `HASHDIFF` column to the stage column holding that satellite's hashdiff.

For example:

```yaml
sat_name:
  SATELLITE_NAME: SATELLITE_NAME_1
```

expects a `SATELLITE_NAME_1` column in the stage, which can be defined as a constant derived column:

```yaml
derived_columns:
  SATELLITE_NAME_1: "!SAT_CUSTOMER_DETAILS"
```

The `hashdiff` mapping works the same way:

```yaml
hashdiff:
  HASHDIFF: ORDER_HASHDIFF
```

expects an `ORDER_HASHDIFF` column in the stage.

Given the following derived columns, the 'Tracking multiple satellites' examples below produce the XTS in the table
that follows:

```yaml
derived_columns:
  SATELLITE_NAME_1: "!SAT_CUSTOMER_DETAILS"
  SATELLITE_NAME_2: "!SAT_ORDER_DETAILS"
```

| CUSTOMER_HK | HASHDIFF | SATELLITE_NAME       | LOAD_DATE  | SOURCE |
|-------------|----------|----------------------|------------|--------|
| B8C37E...   | 3C598... | SAT_CUSTOMER_DETAILS | 1993-01-01 | *      |
| .           | .        | .                    | .          | .      |
| .           | .        | .                    | .          | .      |
| FED333...   | 6C958... | SAT_ORDER_DETAILS    | 1993-01-01 | *      |

### XTS metadata

=== "Tracking a single satellite"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_customer" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_satellite = {
            "SATELLITE_CUSTOMER": {
                "sat_name": {"SATELLITE_NAME": "SATELLITE_NAME_1"},
                "hashdiff": {"HASHDIFF": "CUSTOMER_HASHDIFF"}
            }
        } -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                           src_source=src_source, source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_customer
        src_pk: CUSTOMER_HK
        src_satellite:
          SATELLITE_CUSTOMER:
            sat_name:
              SATELLITE_NAME: SATELLITE_NAME_1
            hashdiff:
              HASHDIFF: CUSTOMER_HASHDIFF
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
    
        {{ automate_dv.xts(src_pk=metadata_dict["src_pk"],
                           src_satellite=metadata_dict["src_satellite"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

=== "Tracking multiple satellites"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_customer" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_satellite = {
            "SAT_CUSTOMER_DETAILS": {
                "sat_name": {"SATELLITE_NAME": "SATELLITE_NAME_1"},
                "hashdiff": {"HASHDIFF": "CUSTOMER_HASHDIFF"}
            },
            "SAT_ORDER_DETAILS": {
                "sat_name": {"SATELLITE_NAME": "SATELLITE_NAME_2"},
                "hashdiff": {"HASHDIFF": "ORDER_HASHDIFF"}
            }
        } -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                           src_source=src_source, source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_customer
        src_pk: CUSTOMER_HK
        src_satellite:
          SAT_CUSTOMER_DETAILS:
            sat_name:
              SATELLITE_NAME: SATELLITE_NAME_1
            hashdiff:
              HASHDIFF: CUSTOMER_HASHDIFF
          SAT_ORDER_DETAILS:
            sat_name:
              SATELLITE_NAME: SATELLITE_NAME_2
            hashdiff:
              HASHDIFF: ORDER_HASHDIFF
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
    
        {{ automate_dv.xts(src_pk=metadata_dict["src_pk"],
                           src_satellite=metadata_dict["src_satellite"],
                           src_ldts=metadata_dict["src_ldts"],
                           src_source=metadata_dict["src_source"],
                           source_model=metadata_dict["source_model"]) }}
        ```

## Point-In-Time (PIT) Tables

[pit macro parameters](macros/index.md#pit)

Each key in the `satellites` parameter is the name of a Satellite model to include in the PIT, containing:

- `pk`: a single mapping of a column name suffix to the Satellite's primary key column.
- `ldts`: a single mapping of a column name suffix to the Satellite's load date/timestamp column.

The PIT columns are named by joining the Satellite name and the suffix, e.g. `SAT_CUSTOMER_DETAILS_PK` and 
`SAT_CUSTOMER_DETAILS_LDTS` in the examples below. [Read more](tutorial/tut_point_in_time.md#satellites-metadata)

=== "Variables"

    ```jinja
    {%- set source_model = "hub_customer" -%}
    {%- set src_pk = "CUSTOMER_HK" -%}
    {%- set as_of_dates_table = "AS_OF_DATE" -%}
    {%- set satellites = {
        "SAT_CUSTOMER_DETAILS": {
            "pk": {"PK": "CUSTOMER_HK"},
            "ldts": {"LDTS": "LOAD_DATETIME"}
        },
        "SAT_CUSTOMER_LOGIN": {
            "pk": {"PK": "CUSTOMER_HK"},
            "ldts": {"LDTS": "LOAD_DATETIME"}
        },
        "SAT_CUSTOMER_PROFILE": {
            "pk": {"PK": "CUSTOMER_HK"},
            "ldts": {"LDTS": "LOAD_DATETIME"}
        }
    } -%}
    {%- set stage_tables_ldts = {
        "STG_CUSTOMER_DETAILS": "LOAD_DATETIME",
        "STG_CUSTOMER_LOGIN": "LOAD_DATETIME",
        "STG_CUSTOMER_PROFILE": "LOAD_DATETIME"
    } -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}

    {{ automate_dv.pit(source_model=source_model, src_pk=src_pk,
                       as_of_dates_table=as_of_dates_table,
                       satellites=satellites,
                       stage_tables_ldts=stage_tables_ldts,
                       src_ldts=src_ldts) }}
    ```

=== "YAML strings"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: hub_customer
    src_pk: CUSTOMER_HK
    as_of_dates_table: AS_OF_DATE
    satellites:
      SAT_CUSTOMER_DETAILS:
        pk:
          PK: CUSTOMER_HK
        ldts:
          LDTS: LOAD_DATETIME
      SAT_CUSTOMER_LOGIN:
        pk:
          PK: CUSTOMER_HK
        ldts:
          LDTS: LOAD_DATETIME
      SAT_CUSTOMER_PROFILE:
        pk:
          PK: CUSTOMER_HK
        ldts:
          LDTS: LOAD_DATETIME
    stage_tables_ldts:
      STG_CUSTOMER_DETAILS: LOAD_DATETIME
      STG_CUSTOMER_LOGIN: LOAD_DATETIME
      STG_CUSTOMER_PROFILE: LOAD_DATETIME
    src_ldts: LOAD_DATETIME
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}

    {{ automate_dv.pit(source_model=metadata_dict["source_model"],
                       src_pk=metadata_dict["src_pk"],
                       as_of_dates_table=metadata_dict["as_of_dates_table"],
                       satellites=metadata_dict["satellites"],
                       stage_tables_ldts=metadata_dict["stage_tables_ldts"],
                       src_ldts=metadata_dict["src_ldts"]) }}
    ```

## Bridge tables

[bridge macro parameters](macros/index.md#bridge)

Each key in the `bridge_walk` parameter names one Link and Effectivity Satellite pair to walk, containing:

- `bridge_link_pk`, `bridge_end_date`, `bridge_load_date`: the names of the columns in the Bridge table which hold the
  Link primary key, and the Effectivity Satellite end date and load date/timestamp.
- `link_table`, `link_pk`, `link_fk1`, `link_fk2`: the Link model, its primary key and its two foreign keys.
- `eff_sat_table`, `eff_sat_pk`, `eff_sat_end_date`, `eff_sat_load_date`: the Effectivity Satellite model, its 
  primary key, end date and load date/timestamp.

[Read more](tutorial/tut_bridges.md#bridge-table-parameters-bridge_walk)

=== "Variables"

    ```jinja
    {%- set source_model = "hub_customer" -%}
    {%- set src_pk = "CUSTOMER_HK" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set as_of_dates_table = "AS_OF_DATE" -%}
    {%- set bridge_walk = {
        "CUSTOMER_ORDER": {
            "bridge_link_pk": "LINK_CUSTOMER_ORDER_HK",
            "bridge_end_date": "EFF_SAT_CUSTOMER_ORDER_ENDDATE",
            "bridge_load_date": "EFF_SAT_CUSTOMER_ORDER_LOADDATE",
            "link_table": "link_customer_order",
            "link_pk": "CUSTOMER_ORDER_HK",
            "link_fk1": "CUSTOMER_FK",
            "link_fk2": "ORDER_FK",
            "eff_sat_table": "eff_sat_customer_order",
            "eff_sat_pk": "CUSTOMER_ORDER_HK",
            "eff_sat_end_date": "END_DATE",
            "eff_sat_load_date": "LOAD_DATETIME"
        },
        "ORDER_PRODUCT": {
            "bridge_link_pk": "LINK_ORDER_PRODUCT_HK",
            "bridge_end_date": "EFF_SAT_ORDER_PRODUCT_ENDDATE",
            "bridge_load_date": "EFF_SAT_ORDER_PRODUCT_LOADDATE",
            "link_table": "link_order_product",
            "link_pk": "ORDER_PRODUCT_HK",
            "link_fk1": "ORDER_FK",
            "link_fk2": "PRODUCT_FK",
            "eff_sat_table": "eff_sat_order_product",
            "eff_sat_pk": "ORDER_PRODUCT_HK",
            "eff_sat_end_date": "END_DATE",
            "eff_sat_load_date": "LOAD_DATETIME"
        }
    } -%}
    {%- set stage_tables_ldts = {
        "STG_CUSTOMER_ORDER": "LOAD_DATETIME",
        "STG_ORDER_PRODUCT": "LOAD_DATETIME"
    } -%}

    {{ automate_dv.bridge(source_model=source_model, src_pk=src_pk,
                          src_ldts=src_ldts,
                          bridge_walk=bridge_walk,
                          as_of_dates_table=as_of_dates_table,
                          stage_tables_ldts=stage_tables_ldts) }}
    ```

=== "YAML strings"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: hub_customer
    src_pk: CUSTOMER_HK
    src_ldts: LOAD_DATETIME
    as_of_dates_table: AS_OF_DATE
    bridge_walk:
      CUSTOMER_ORDER:
        bridge_link_pk: LINK_CUSTOMER_ORDER_HK
        bridge_end_date: EFF_SAT_CUSTOMER_ORDER_ENDDATE
        bridge_load_date: EFF_SAT_CUSTOMER_ORDER_LOADDATE
        link_table: link_customer_order
        link_pk: CUSTOMER_ORDER_HK
        link_fk1: CUSTOMER_FK
        link_fk2: ORDER_FK
        eff_sat_table: eff_sat_customer_order
        eff_sat_pk: CUSTOMER_ORDER_HK
        eff_sat_end_date: END_DATE
        eff_sat_load_date: LOAD_DATETIME
      ORDER_PRODUCT:
        bridge_link_pk: LINK_ORDER_PRODUCT_HK
        bridge_end_date: EFF_SAT_ORDER_PRODUCT_ENDDATE
        bridge_load_date: EFF_SAT_ORDER_PRODUCT_LOADDATE
        link_table: link_order_product
        link_pk: ORDER_PRODUCT_HK
        link_fk1: ORDER_FK
        link_fk2: PRODUCT_FK
        eff_sat_table: eff_sat_order_product
        eff_sat_pk: ORDER_PRODUCT_HK
        eff_sat_end_date: END_DATE
        eff_sat_load_date: LOAD_DATETIME
    stage_tables_ldts:
      STG_CUSTOMER_ORDER: LOAD_DATETIME
      STG_ORDER_PRODUCT: LOAD_DATETIME
    {%- endset -%}

    {% set metadata_dict = fromyaml(yaml_metadata) %}

    {{ automate_dv.bridge(source_model=metadata_dict["source_model"],
                          src_pk=metadata_dict["src_pk"],
                          src_ldts=metadata_dict["src_ldts"],
                          bridge_walk=metadata_dict["bridge_walk"],
                          as_of_dates_table=metadata_dict["as_of_dates_table"],
                          stage_tables_ldts=metadata_dict["stage_tables_ldts"]) }}
    ```

## Reference Tables

[ref_table macro parameters](macros/index.md#ref_table)

=== "Without Record Source and Load Date/Timestamp"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_flights" -%}
        {%- set src_pk = "CODE" -%}
        {%- set src_extra_columns = ["NAME", "COMMENTS"] -%}
        
        {{ automate_dv.ref_table(src_pk=src_pk,
                                 src_extra_columns=src_extra_columns,
                                 source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_flights
        src_pk: CODE
        src_extra_columns:
          - NAME
          - COMMENTS
        {%- endset -%}

        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                                 src_extra_columns=metadata_dict["src_extra_columns"],
                                 source_model=metadata_dict["source_model"]) }}
        ```

=== "With Record Source and Load Date/Timestamp"

    === "Variables"

        ```jinja
        {%- set source_model = "v_stg_flights" -%}
        {%- set src_pk = "CODE" -%}
        {%- set src_extra_columns = ["NAME", "COMMENTS"] -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ automate_dv.ref_table(src_pk=src_pk,
                                 src_ldts=src_ldts, src_source=src_source,
                                 src_extra_columns=src_extra_columns,
                                 source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_flights
        src_pk: CODE
        src_extra_columns:
          - NAME
          - COMMENTS
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}

        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                                 src_ldts=metadata_dict["src_ldts"],
                                 src_source=metadata_dict["src_source"],
                                 src_extra_columns=metadata_dict["src_extra_columns"],
                                 source_model=metadata_dict["source_model"]) }}
        ```

## Latest Satellites

[lat_sat macro parameters](macros/index.md#lat_sat)

!!! note
    A Latest Satellite is built on top of a Satellite rather than a stage, so the `source_model` is the name of the 
    Satellite model. We recommend materialising Latest Satellites as a `view`, so the examples include a `config()` 
    block.

=== "Standard"

    === "Variables"

        ```jinja
        {{ config(materialized="view") }}

        {%- set source_model = "sat_customer_details" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_latest = "EFFECTIVE_FROM" -%}

        {{ automate_dv.lat_sat(src_pk=src_pk, src_latest=src_latest,
                               source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {{ config(materialized="view") }}

        {%- set yaml_metadata -%}
        source_model: sat_customer_details
        src_pk: CUSTOMER_HK
        src_latest: EFFECTIVE_FROM
        {%- endset -%}

        {% set metadata_dict = fromyaml(yaml_metadata) %}

        {{ automate_dv.lat_sat(src_pk=metadata_dict["src_pk"],
                               src_latest=metadata_dict["src_latest"],
                               source_model=metadata_dict["source_model"]) }}
        ```

=== "Using Load Datetime"

    === "Variables"

        ```jinja
        {{ config(materialized="view") }}

        {%- set source_model = "sat_customer_details" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_latest = "LOAD_DATETIME" -%}

        {{ automate_dv.lat_sat(src_pk=src_pk, src_latest=src_latest,
                               source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {{ config(materialized="view") }}

        {%- set yaml_metadata -%}
        source_model: sat_customer_details
        src_pk: CUSTOMER_HK
        src_latest: LOAD_DATETIME
        {%- endset -%}

        {% set metadata_dict = fromyaml(yaml_metadata) %}

        {{ automate_dv.lat_sat(src_pk=metadata_dict["src_pk"],
                               src_latest=metadata_dict["src_latest"],
                               source_model=metadata_dict["source_model"]) }}
        ```

=== "Composite Primary Key"

    === "Variables"

        ```jinja
        {{ config(materialized="view") }}

        {%- set source_model = "sat_customer_order_details" -%}
        {%- set src_pk = ["CUSTOMER_HK", "ORDER_HK"] -%}
        {%- set src_latest = "EFFECTIVE_FROM" -%}

        {{ automate_dv.lat_sat(src_pk=src_pk, src_latest=src_latest,
                               source_model=source_model) }}
        ```

    === "YAML strings"

        ```jinja
        {{ config(materialized="view") }}

        {%- set yaml_metadata -%}
        source_model: sat_customer_order_details
        src_pk:
          - CUSTOMER_HK
          - ORDER_HK
        src_latest: EFFECTIVE_FROM
        {%- endset -%}

        {% set metadata_dict = fromyaml(yaml_metadata) %}

        {{ automate_dv.lat_sat(src_pk=metadata_dict["src_pk"],
                               src_latest=metadata_dict["src_latest"],
                               source_model=metadata_dict["source_model"]) }}
        ```

--8<-- "includes/abbreviations.md"
