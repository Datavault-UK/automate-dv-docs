{%- set yaml_metadata -%}
source_model: CUSTOMER
derived_columns:
  ORDER_ID: '!1'
  CUSTOMER_ID: c_custkey
  CUSTOMER_PHONE_LOCATOR_ID: '1'
  LOAD_DATETIME: '!1998-07-01'
  EFFECTIVE_FROM: '!1998-01-01'
  START_DATE: '!1998-01-01'
  END_DATE: '!1998-01-01'
  RECORD_SOURCE: '!TPCH_ORDERS'
hashed_columns:
  CUSTOMER_HK: c_custkey
  ORDER_HK: ORDER_ID
  CUSTOMER_ORDER_HK:
    - c_custkey
    - '!1'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     derived_columns=metadata_dict["derived_columns"],
                     hashed_columns=metadata_dict["hashed_columns"]) }}