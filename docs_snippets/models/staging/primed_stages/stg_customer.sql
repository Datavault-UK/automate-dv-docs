{%- set yaml_metadata -%}
source_model: CUSTOMER
derived_columns:
  CUSTOMER_ID: c_custkey
  LOAD_DATETIME: '!1998-01-01'
  RECORD_SOURCE: '!TPCH_CUSTOMER'
hashed_columns:
  CUSTOMER_HK: c_custkey
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     derived_columns=metadata_dict["derived_columns"],
                     hashed_columns=metadata_dict["hashed_columns"]) }}