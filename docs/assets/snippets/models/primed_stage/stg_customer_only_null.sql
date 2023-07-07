{%- set yaml_metadata -%}
source_model: CUSTOMER
null_columns:
  required:
    - C_CUSTKEY
  optional:
    - C_NATIONKEY
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     null_columns=metadata_dict["null_columns"]) }}