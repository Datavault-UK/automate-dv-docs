dbtvault is metadata driven. On this page, we provide an overview of how to provide and store the data for **dbtvault
macros**.

For all other metadata and configurations, please refer to
the [dbt configurations reference](https://docs.getdbt.com/reference/dbt_project.yml).

For further details about how to use the macros in this section, see [table templates](macros.md#table-templates).

### Approaches

This page will describe just *one* way of providing metadata to the macros. There are many ways to do it, and it comes
down to user and organisation preference.

!!! note
    The macros **do not care** how the metadata parameters get provided, as long as they are of the correct type.
    Parameter data types definitions are available on the [macros](macros.md) page. The approaches below are simply our
    recommendations, which we hope provide a good balance of manageability and readability.

**All approaches for the same structure will produce the same structure, the only difference is how the metadata is provided.**

It is worth noting that with larger projects, metadata management gets increasingly harder and can become unwieldy.
See [the problem with metadata](#the-problem-with-metadata) for a more detailed discussion.

We can reduce the impact of this problem by providing the metadata for a given model, in the model itself. This approach
does have the drawback that the creation of models is significantly less copy-and-paste, but the metadata management
improvements are usually worth it.

#### Per-model - Variables

You may also provide metadata on a per-model basis. This is useful if you have a large amount of metadata.

##### Example

=== "hub_customer.sql"

    ```jinja
    {%- set source_model = "stg_web_customer_hashed" -%}
    {%- set src_pk = "CUSTOMER_HK" -%}
    {%- set src_nk = "CUSTOMER_ID" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

#### Per-Model - YAML strings

If you want to provide metadata inside the model itself, but find yourself disliking the format for larger collections
of metadata or certain data types (e.g. dict literals), then providing a YAML String inside a block
`set` assignment is a good alternative to using multiple individual `set` assignments. This approach takes advantage of
the `fromyaml()` built-in jinja function provided by dbt, which is
documented [here](https://docs.getdbt.com/reference/dbt-jinja-functions/fromyaml/).

The below example for a Hub is a little excessive for the small amount of metadata provided, so there is also a stage
example provided to help better convey the difference.

!!! warning 

    dbt does not yet provide any syntax checking in these YAML strings, often leading to confusing and
    misleading error messages. If you find that variables which are extracted from the YAML string are empty, it is an
    indicator that the YAML did not compile correctly, and you should check your formatting; including indentation.

##### Examples

=== "hub_customer.sql"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: stg_web_customer_hashed
    src_pk: CUSTOMER_HK
    src_nk: CUSTOMER_ID
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
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
      DBTVAULT_RANK:
        partition_by: CUSTOMER_ID
        order_by: BOOKING_DATE
    {% endset %}
       
    {% set metadata_dict = fromyaml(yaml_metadata) %}

    {% set source_model = metadata_dict["source_model"] %}
    {% set derived_columns = metadata_dict["derived_columns"] %}
    {% set null_columns = metadata_dict["null_columns"] %}
    {% set hashed_columns = metadata_dict["hashed_columns"] %}
    {% set ranked_columns = metadata_dict["ranked_columns"] %}
    
    {{ dbtvault.stage(include_source_columns=true,
                      source_model=source_model,
                      derived_columns=derived_columns,
                      null_columns=null_columns,
                      hashed_columns=hashed_columns,
                      ranked_columns=ranked_columns) }}
    ```

    !!! note
        '!' at the beginning of strings is syntactic sugar provided by dbtvault for creating constant values. 
        [Read More](macros.md#constants-derived-columns)

### Staging

#### Parameters

[stage macro parameters](macros.md#stage)

#### Metadata

=== "Per-model - YAML strings"
    === "All components"
    
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
          DBTVAULT_RANK:
            partition_by: CUSTOMER_ID
            order_by: BOOKING_DATE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
    
        {% set source_model = metadata_dict["source_model"] %}
        {% set derived_columns = metadata_dict["derived_columns"] %}
        {% set null_columns = metadata_dict["null_columns"] %}
        {% set hashed_columns = metadata_dict["hashed_columns"] %}
        {% set ranked_columns = metadata_dict["ranked_columns"] %}
        
        {{ dbtvault.stage(include_source_columns=true,
                          source_model=source_model,
                          derived_columns=derived_columns,
                          null_columns=null_columns,
                          hashed_columns=hashed_columns,
                          ranked_columns=ranked_columns) }}
        ```

    === "Only Source (ref style)"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict["source_model"] %}
        
        {{ dbtvault.stage(include_source_columns=true,
                          source_model=source_model,
                          derived_columns=none,
                          null_columns=none,
                          hashed_columns=none,
                          ranked_columns=none) }}
        ```
    
    === "Only Source (source style)"

        ```jinja
        {%- set yaml_metadata -%}
        source_model:
          raw_source_name: source_table_name
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict["source_model"] %}
        
        {{ dbtvault.stage(include_source_columns=true,
                          source_model=source_model,
                          derived_columns=none,
                          null_columns=none,
                          hashed_columns=none,
                          ranked_columns=none) }}
        ```

    === "Only hashing"

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
        
        {% set source_model = metadata_dict["source_model"] %}
        {% set hashed_columns = metadata_dict["hashed_columns"] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=none,
                          null_columns=none,
                          hashed_columns=hashed_columns,
                          ranked_columns=none) }}
        ```

    === "Only derived"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        derived_columns:
            RECORD_SOURCE: "!STG_BOOKING"
            EFFECTIVE_FROM: BOOKING_DATE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict["source_model"] %}
        {% set derived_columns = metadata_dict["derived_columns"] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=derived_columns,
                          null_columns=none,
                          hashed_columns=none,
                          ranked_columns=none) }}
        ```

    === "Only null key columns"

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
        
        {% set source_model = metadata_dict["source_model"] %}
        {% set null_columns = metadata_dict["null_columns"] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=none,
                          null_columns=null_columns,
                          hashed_columns=none,
                          ranked_columns=none) }}
        ```

    === "Only ranked"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: raw_source
        ranked_columns:
          DBTVAULT_RANK:
            partition_by: CUSTOMER_ID
            order_by: BOOKING_DATE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {% set source_model = metadata_dict["source_model"] %}
        {% set ranked_columns = metadata_dict["ranked_columns"] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=none,
                          null_columns=none,
                          hashed_columns=none,
                          ranked_columns=ranked_columns) }}
        ```

    === "Exclude Columns flag"

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
        
        {% set source_model = metadata_dict["source_model"] %}
        {% set hashed_columns = metadata_dict["hashed_columns"] %}
        
        {{ dbtvault.stage(include_source_columns=false,
                          source_model=source_model,
                          derived_columns=none,
                          null_columns=none,
                          hashed_columns=hashed_columns,
                          ranked_columns=none) }}
        ```

### Hubs

#### Parameters

[hub macro parameters](macros.md#hub)

#### Metadata

=== "Per-model - YAML strings"

    === "Single Source"

        ```jinja
        {%- set yaml_metadata -%}
        source_model: stg_web_customer_hashed
        src_pk: CUSTOMER_HK
        src_nk: CUSTOMER_ID
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ dbtvault.hub(src_pk=metadata_dict["src_pk"],
                        src_nk=metadata_dict["src_nk"], 
                        src_ldts=metadata_dict["src_ldts"],
                        src_source=metadata_dict["src_source"],
                        source_model=metadata_dict["source_model"]) }}
        ```
    
    === "Multi Source"

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
        
        {{ dbtvault.hub(src_pk=metadata_dict["src_pk"],
                        src_nk=metadata_dict["src_nk"], 
                        src_ldts=metadata_dict["src_ldts"],
                        src_source=metadata_dict["src_source"],
                        source_model=metadata_dict["source_model"]) }}
        ```

    === "Composite NK"

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
        
        {{ dbtvault.hub(src_pk=metadata_dict["src_pk"],
                        src_nk=metadata_dict["src_nk"], 
                        src_ldts=metadata_dict["src_ldts"],
                        src_source=metadata_dict["src_source"],
                        source_model=metadata_dict["source_model"]) }}
        ```

=== "Per-Model - Variables"

    === "Single Source"

        ```jinja
        {%- set source_model = "stg_customer_hashed" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_nk = "CUSTOMER_ID" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

    === "Multi Source"

        ```jinja
        {%- set source_model = ["stg_web_customer_hashed", "stg_crm_customer_hashed"] -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_nk = "CUSTOMER_ID" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

    === "Composite NK"

        ```jinja
        {%- set source_model = "stg_customer_hashed" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_nk = ["CUSTOMER_ID", "CUSTOMER_DOB"] -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

### Links

#### Parameters

[link macro parameters](macros.md#link)

#### Metadata

=== "Per-model - YAML strings"

    === "Single Source"
        ```jinja
        {%- set yaml_metadata -%}
        source_model: v_stg_orders
        src_pk: LINK_CUSTOMER_NATION_HK
        src_fk: 
          - CUSTOMER_ID
          - NATION_HK
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ dbtvault.link(src_pk=metadata_dict["src_pk"],
                         src_fk=metadata_dict["src_fk"], 
                         src_ldts=metadata_dict["src_ldts"],
                         src_source=metadata_dict["src_source"], 
                         source_model=metadata_dict["source_model"]) }}
        ```

    === "Multi Source"
        ```jinja
        {%- set yaml_metadata -%}
        source_model: 
          - v_stg_orders
          - v_stg_transactions
        src_pk: LINK_CUSTOMER_NATION_HK
        src_fk: 
          - CUSTOMER_ID
          - NATION_HK
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
        
        {{ dbtvault.link(src_pk=metadata_dict["src_pk"],
                         src_fk=metadata_dict["src_fk"], 
                         src_ldts=metadata_dict["src_ldts"],
                         src_source=metadata_dict["src_source"], 
                         source_model=metadata_dict["source_model"]) }}
        ```

=== "Per-Model - Variables"

    === "Single Source"
        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "LINK_CUSTOMER_NATION_HK" -%}
        {%- set src_fk = ["CUSTOMER_HK", "NATION_HK"] -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                         src_source=src_source, source_model=source_model) }}
        ```

    === "Multi Source"
        ```jinja
        {%- set source_model = ["v_stg_orders", "v_stg_transactions"] -%}
        {%- set src_pk = "LINK_CUSTOMER_NATION_HK" -%}
        {%- set src_fk = ["CUSTOMER_HK", "NATION_HK"] -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                         src_source=src_source, source_model=source_model) }}
        ```

### Transactional links

###### (also known as non-historised links)

#### Parameters

[t_link macro parameters](macros.md#t_link)

#### Metadata

=== "Per-model - YAML strings"

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

    {{ dbtvault.t_link(src_pk=metadata_dict["src_pk"],
                       src_fk=metadata_dict["src_fk"],
                       src_payload=metadata_dict["src_payload"],
                       src_eff=metadata_dict["src_eff"],
                       src_ldts=metadata_dict["src_ldts"],
                       src_source=metadata_dict["src_source"],
                       source_model=metadata_dict["source_model"]) }}
    ```

=== "Per-Model - Variables"

    ```jinja
    {%- set source_model = "v_stg_transactions" -%}
    {%- set src_pk = "TRANSACTION_HK" -%}
    {%- set src_fk = ["CUSTOMER_HK", "ORDER_HK"] -%}
    {%- set src_payload = ["TRANSACTION_NUMBER", "TRANSACTION_DATE", "TYPE", "AMOUNT"] -%}
    {%- set src_eff = "EFFECTIVE_FROM" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ dbtvault.t_link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                       src_payload=src_payload, src_eff=src_eff,
                       src_source=src_source, source_model=source_model) }}
    ```

### Satellites

#### Parameters

[sat macro parameters](macros.md#sat)

#### Metadata

=== "Per-model - YAML strings"

    === "Standard"

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
    
        {{ dbtvault.sat(src_pk=metadata_dict["src_pk"],
                        src_hashdiff=metadata_dict["src_hashdiff"],
                        src_payload=metadata_dict["src_payload"],
                        src_eff=metadata_dict["src_eff"],
                        src_ldts=metadata_dict["src_ldts"],
                        src_source=metadata_dict["src_source"],
                        source_model=metadata_dict["source_model"]) }}
        ```

    === "Hashdiff Aliasing"

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
    
        {{ dbtvault.sat(src_pk=metadata_dict["src_pk"],
                        src_hashdiff=metadata_dict["src_hashdiff"],
                        src_payload=metadata_dict["src_payload"],
                        src_eff=metadata_dict["src_eff"],
                        src_ldts=metadata_dict["src_ldts"],
                        src_source=metadata_dict["src_source"],
                        source_model=metadata_dict["source_model"]) }}
        ```

=== "Per-Model - Variables"

    === "Standard"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_hashdiff = "CUSTOMER_HASHDIFF" -%}
        {%- set src_payload = ["NAME", "ADDRESS", "PHONE", "ACCBAL", "MKTSEGMENT", "COMMENT"] -%}
        {%- set src_eff = "EFFECTIVE_FROM" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                        src_payload=src_payload, src_eff=src_eff,
                        src_ldts=src_ldts, src_source=src_source, 
                        source_model=source_model) }}
        ```

    === "Hashdiff Aliasing"

        ```jinja
        {%- set source_model = "v_stg_orders" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_hashdiff = {"source_column": "CUSTOMER_HASHDIFF", "alias": "HASHDIFF"} -%}
        {%- set src_payload = ["NAME", "ADDRESS", "PHONE", "ACCBAL", "MKTSEGMENT", "COMMENT"] -%}
        {%- set src_eff = "EFFECTIVE_FROM" -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                        src_payload=src_payload, src_eff=src_eff,
                        src_ldts=src_ldts, src_source=src_source, 
                        source_model=source_model) }}
        ```

Hashdiff aliasing allows you to set an alias for the `HASHDIFF` column.
[Read more](best_practices.md#hashdiff-aliasing)

### Effectivity Satellites

#### Parameters

[eff_sat macro parameters](macros.md#eff_sat)

#### Metadata

=== "Per-model - YAML strings"

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
    
    {{ dbtvault.eff_sat(src_pk=metadata_dict["src_pk"],
                        src_dfk=metadata_dict["src_dfk"],
                        src_sfk=metadata_dict["src_sfk"],
                        src_start_date=metadata_dict["src_start_date"],
                        src_end_date=metadata_dict["src_end_date"],
                        src_eff=metadata_dict["src_eff"],
                        src_ldts=metadata_dict["src_ldts"],
                        src_source=metadata_dict["src_source"],
                        source_model=metadata_dict["source_model"]) }}
    ```

=== "Per-Model - Variables"

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
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date, 
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source, 
                        source_model=source_model) }}
    ```

### Multi-Active Satellites (MAS)

#### Parameters

[ma_sat macro parameters](macros.md#ma_sat)

#### Metadata

=== "Per-model - YAML strings"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: v_stg_orders
    src_pk: CUSTOMER_HK
    src_cdk: 
      - CUSTOMER_PHONE
    src_payload:
      - CUSTOMER_NAME
    src_hashdiff: HASHDIFF
    src_eff: EFFECTIVE_FROM
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ dbtvault.ma_sat(src_pk=metadata_dict["src_pk"],
                       src_cdk=metadata_dict["src_cdk"],
                       src_payload=metadata_dict["src_payload"],
                       src_hashdiff=metadata_dict["src_hashdiff"],
                       src_eff=metadata_dict["src_eff"],
                       src_ldts=metadata_dict["src_ldts"],
                       src_source=metadata_dict["src_source"],
                       source_model=metadata_dict["source_model"]) }}
    ```

=== "Per-Model - Variables"

    ```jinja
    {%- set source_model = "v_stg_customer" -%}
    {%- set src_pk = "CUSTOMER_HK" -%}
    {%- set src_cdk = ["CUSTOMER_PHONE", "EXTENSION"] -%}
    {%- set src_hashdiff = "HASHDIFF" -%}
    {%- set src_payload = ["CUSTOMER_NAME"] -%}
    {%- set src_eff = "EFFECTIVE_FROM" -%}
    {%- set src_ldts = "LOAD_DATETIME" -%}
    {%- set src_source = "RECORD_SOURCE" -%}
    
    {{ dbtvault.ma_sat(src_pk=src_pk, src_cdk=src_cdk, src_hashdiff=src_hashdiff, 
                       src_payload=src_payload, src_eff=src_eff, src_ldts=src_ldts, 
                       src_source=src_source, source_model=source_model) }}
    ```

___

### Extended Tracking Satellites (XTS)

#### Parameters

[xts macro parameters](macros.md#xts)

#### Metadata

=== "Per-model - YAML strings"

    === "Tracking a single satellite"

        ```sql
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
    
        {% set source_model = metadata_dict["source_model"] %}
        {% set src_pk = metadata_dict["src_pk"] %}
        {% set src_ldts = metadata_dict["src_ldts"] %}
        {% set src_satellite = metadata_dict["src_satellite"] %}
        {% set src_source = metadata_dict["src_source"] %}
    
        {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

    === "Tracking multiple satellites"

        ```sql
        {%- set yaml_metadata -%}
        source_model: v_stg_customer
        src_pk: CUSTOMER_HK
        src_satellite:
          SAT_CUSTOMER_DETAILS: 
            sat_name:
              SATELLITE_NAME: SATELLITE_NAME_1
            hashdiff:
              HASHDIFF: CUSTOMER_HASHDIFF
          SAT_CUSTOMER_DETAILS: 
            sat_name:
              SATELLITE_NAME: SATELLITE_NAME_2
            hashdiff:
              HASHDIFF: ORDER_HASHDIFF
        src_ldts: LOAD_DATETIME
        src_source: RECORD_SOURCE
        {%- endset -%}
        
        {% set metadata_dict = fromyaml(yaml_metadata) %}
    
        {% set source_model = metadata_dict["source_model"] %}
        {% set src_pk = metadata_dict["src_pk"] %}
        {% set src_ldts = metadata_dict["src_ldts"] %}
        {% set src_satellite = metadata_dict["src_satellite"] %}
        {% set src_source = metadata_dict["src_source"] %}
    
        {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

=== "Per-Model - Variables"

    === "Tracking a single satellite"

        ```sql
        {%- set source_model = "v_stg_customer" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_satellite = {"SATELLITE_CUSTOMER": {"sat_name": {"SATELLITE_NAME": "SATELLITE_NAME_1"}, "hashdiff": {"HASHDIFF": "CUSTOMER_HASHDIFF"}}}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

    === "Tracking multiple satellites"

        ```sql
        {%- set source_model = "v_stg_customer" -%}
        {%- set src_pk = "CUSTOMER_HK" -%}
        {%- set src_satellite = "SAT_CUSTOMER_DETAILS": {
                                  "sat_name": {"SATELLITE_NAME": "SATELLITE_NAME_1"}, 
                                  "hashdiff": {"HASHDIFF": "CUSTOMER_HASHDIFF"}
                                }, "SAT_ORDER_DETAILS": {
                                  "sat_name": {"SATELLITE_NAME": "SATELLITE_NAME_2"},
                                  "hashdiff": {"HASHDIFF": "ORDER_HASHDIFF"}
                                }} -%}
        {%- set src_ldts = "LOAD_DATETIME" -%}
        {%- set src_source = "RECORD_SOURCE" -%}
        
        {{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                        src_source=src_source, source_model=source_model) }}
        ```

#### Understanding the `src_satellite` parameter

The `src_satellite` parameter provides the means to define the satellites which the XTS tracks.

The mapping matches columns in the stage layer (using the `stage` macro) to the `SATELLITE_NAME` and `HASHDIFF` columns in the XTS.

```
...
"sat_name": {"SATELLITE_NAME": "SATELLITE_NAME_1"}
...
```

In the above example we expect a `SATELLITE_NAME_1` column in the Stage, defined as follows:

```
...
derived_columns:
    SATELLITE_NAME_1: "!SAT_CUSTOMER_DETAILS"
...
```

This works exactly the same way for the `HASHDIFF` column, as defined by:

```
...
"hashdiff": {"HASHDIFF": "ORDER_HASHDIFF"}
...
```

For example, the 'Tracking multiple satellites' metadata examples above would produce the XTS in the table below, given
the following derived columns:

```
...
derived_columns:
    SATELLITE_NAME_1: "!SAT_CUSTOMER_DETAILS"
    SATELLITE_NAME_2: "!SAT_ORDER_DETAILS"
...
```

| CUSTOMER_HK | HASHDIFF | SATELLITE_NAME       | LOAD_DATE  | SOURCE |
|-------------|----------|----------------------|------------|--------|
| B8C37E...   | 3C598... | SAT_CUSTOMER_DETAILS | 1993-01-01 | *      |
| .           | .        | .                    | .          | .      |
| .           | .        | .                    | .          | .      |
| FED333...   | 6C958... | SAT_ORDER_DETAILS    | 1993-01-01 | *      |

___

### Point-In-Time (PIT) Tables

#### Parameters

[pit macro parameters](macros.md#pit)

#### Metadata

=== "Per-model - YAML strings"

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
    stage_tables:
      STG_CUSTOMER_DETAILS: LOAD_DATETIME
      STG_CUSTOMER_LOGIN: LOAD_DATETIME
      STG_CUSTOMER_PROFILE: LOAD_DATETIME
    src_ldts: LOAD_DATETIME
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}

    {{ dbtvault.pit(source_model=metadata_dict['source_model'], 
                    src_pk=metadata_dict['src_pk'],
                    as_of_dates_table=metadata_dict['as_of_dates_table'],
                    satellites=metadata_dict['satellites'],
                    stage_tables=metadata_dict['stage_tables'],
                    src_ldts=metadata_dict['src_ldts']) }}
    ```

___

### Bridge tables

#### Parameters

[bridge macro parameters](macros.md#bridge)

#### Metadata

=== "Per-Model - YAML String"

    ```jinja
    {%- set yaml_metadata -%}
    source_model: hub_customer
    src_pk: CUSTOMER_HK
    src_ldts: LOAD_DATETIME
    as_of_dates_table: as_of_date
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

    {{ dbtvault.bridge(source_model=metadata_dict['source_model'], 
                       src_pk=metadata_dict['src_pk'],
                       src_ldts=metadata_dict['src_ldts'],
                       bridge_walk=metadata_dict['bridge_walk'],
                       as_of_dates_table=metadata_dict['as_of_dates_table'],
                       stage_tables_ldts=metadata_dict['stage_tables_ldts']) }}
    ```

___

### The problem with metadata

When metadata gets stored in the `dbt_project.yml`, you can probably foresee the file getting very large for bigger
projects. If your metadata gets defined and stored in each model, it becomes harder to generate and develop with, but it
can be easier to manage. Model-level metadata alleviates the issue, but will not completely solve it.

Whichever approach gets chosen, metadata storage and retrieval is difficult without a dedicated tool. To help manage
large amounts of metadata, we recommend the use of third-party enterprise tools such as WhereScape, Matillion, or Erwin
Data Modeller.

In the future, dbt will likely support better ways to manage metadata at this level, to put off the need for a tool a
little longer. Discussions are [already ongoing](https://github.com/dbt-labs/dbt/issues/2401), and we hope to be able to
advise on better ways to manage metadata in the future. 

--8<-- "includes/abbreviations.md"