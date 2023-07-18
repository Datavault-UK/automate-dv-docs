{%- set yaml_metadata -%}
source_model: CUSTOMER
derived_columns:
  ORDER_ID: '!1'
  CUSTOMER_ID: c_custkey
  CUSTOMER_NAME: c_name
  CUSTOMER_PHONE: c_phone
  CUSTOMER_ADDRESS: c_address
  ACCBAL: c_acctbal
  MKTSEGMENT: c_mktsegment
  COMMENT: c_comment
  CUSTOMER_PHONE_LOCATOR_ID: '1'
  LOAD_DATETIME: CAST('1998-07-01' AS TIMESTAMP)
  EFFECTIVE_FROM: CAST('1998-01-01' AS TIMESTAMP)
  START_DATE: CAST('1998-01-01' AS TIMESTAMP)
  END_DATE: CAST('1998-01-01' AS TIMESTAMP)
  RECORD_SOURCE: '!TPCH_ORDERS'
hashed_columns:
  CUSTOMER_HK: c_custkey
  ORDER_HK: ORDER_ID
  CUSTOMER_ORDER_HK:
    - c_custkey
    - '!1'
  HASHDIFF:
    - c_custkey
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(source_model=metadata_dict["source_model"],
                     derived_columns=metadata_dict["derived_columns"],
                     hashed_columns=metadata_dict["hashed_columns"]) }}