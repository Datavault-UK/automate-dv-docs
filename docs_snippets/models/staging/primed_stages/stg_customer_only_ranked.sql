{%- set yaml_metadata -%}
source_model: CUSTOMER
ranked_columns:
  AUTOMATE_DV_RANK:
    partition_by: C_CUSTKEY
    order_by: C_NATIONKEY
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     ranked_columns=metadata_dict["ranked_columns"]) }}