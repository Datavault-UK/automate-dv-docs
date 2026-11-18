{%- set yaml_metadata -%}
source_model: CUSTOMER
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"]) }}