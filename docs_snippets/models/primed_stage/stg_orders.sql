{%- set yaml_metadata -%}
source_model: ORDERS
derived_columns:
  CUSTOMER_ID: O_CUSTKEY
  LOAD_DATETIME: '!1998-01-01'
  RECORD_SOURCE: '!TPCH_ORDERS'
hashed_columns:
  CUSTOMER_HK: O_CUSTKEY
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     derived_columns=metadata_dict["derived_columns"],
                     hashed_columns=metadata_dict["hashed_columns"]) }}