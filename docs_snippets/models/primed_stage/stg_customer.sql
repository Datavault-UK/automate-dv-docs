{%- set yaml_metadata -%}
source_model: CUSTOMER
hashed_columns:
  CUSTOMER_HK: C_CUSTKEY
  CUST_CUSTOMER_HASHDIFF:
    is_hashdiff: true
    columns:
      - C_NAME
      - C_ADDRESS
      - C_PHONE
derived_columns:
  CUSTOMER_ID: C_CUSTKEY
  LOAD_DATETIME: "!1998-01-01"
  RECORD_SOURCE: "!TPCH_CUSTOMER"
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
