{%- set yaml_metadata -%}
source_model: CUSTOMER
hashed_columns:
  CUSTOMER_HK: c_custkey
derived_columns:
  CUSTOMER_ID: c_custkey
  LOAD_DATETIME: "!1998-01-01"
  RECORD_SOURCE: "!TPCH_CUSTOMER"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(include_source_columns=true,
                  source_model=metadata_dict["source_model"],
                  derived_columns=metadata_dict["derived_columns"],
                  null_columns=metadata_dict["null_columns"],
                  hashed_columns=metadata_dict["hashed_columns"],
                  ranked_columns=metadata_dict["ranked_columns"]) }}
