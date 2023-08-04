{%- set yaml_metadata -%}
source_model: CUSTOMER
hashed_columns:
  CUSTOMER_HK: C_CUSTKEY
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     hashed_columns=metadata_dict["hashed_columns"]) }}