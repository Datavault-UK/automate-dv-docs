{%- set yaml_metadata -%}
source_model: CUSTOMER
derived_columns:
  CUSTOMER_ID: C_CUSTKEY
  LOAD_DATETIME: '!1998-01-01'
  RECORD_SOURCE: '!TPCH_CUSTOMER'
hashed_columns:
  CUSTOMER_HK: C_CUSTKEY
ranked_columns:
  AUTOMATE_DV_RANK:
    partition_by: CUSTOMER_HK
    order_by: LOAD_DATETIME
null_columns:
  required:
    - CUSTOMER_ID
  optional:
    - C_NATIONKEY
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     derived_columns=metadata_dict["derived_columns"],
                     hashed_columns=metadata_dict["hashed_columns"],
                     ranked_columns=metadata_dict["ranked_columns"],
                     null_columns=metadata_dict["null_columns"]) }}