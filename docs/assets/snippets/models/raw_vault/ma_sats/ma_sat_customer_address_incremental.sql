{%- set source_model = "stg_customer" -%}
{%- set src_pk = "CUSTOMER_HK" -%}
{%- set src_cdk = "CUSTOMER_PHONE" -%}
{%- set src_payload = ["CUSTOMER_NAME"] -%}
{%- set src_hashdiff = "HASHDIFF" -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATETIME" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.ma_sat(source_model=source_model,
                      src_pk=src_pk,
                      src_cdk=src_cdk,
                      src_payload=src_payload,
                      src_hashdiff=src_hashdiff,
                      src_eff=src_eff,
                      src_ldts=src_ldts,
                      src_source=src_source) }}