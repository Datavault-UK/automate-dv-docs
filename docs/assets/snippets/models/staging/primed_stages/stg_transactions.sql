{%- set yaml_metadata -%}
source_model: ORDERS
derived_columns:
  CUSTOMER_ID: o_custkey
  ORDER_ID: o_orderkey
  LOAD_DATETIME: CAST('1998-07-01' AS TIMESTAMP)
  EFFECTIVE_FROM: CAST('1998-01-01' AS TIMESTAMP)
  START_DATE: CAST('1998-01-01' AS TIMESTAMP)
  END_DATE: CAST('1998-01-01' AS TIMESTAMP)
  RECORD_SOURCE: '!TPCH_ORDERS'
hashed_columns:
  TRANSACTION_HK:
    - CUSTOMER_ID
    - ORDER_ID
  CUSTOMER_HK: CUSTOMER_ID
  ORDER_HK: ORDER_ID
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     derived_columns=metadata_dict["derived_columns"],
                     hashed_columns=metadata_dict["hashed_columns"]) }}