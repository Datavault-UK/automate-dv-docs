{{ config(
    full_refresh=true
) }}

{%- set source_model = "stg_customer" -%}
{%- set src_pk = "CUSTOMER_ORDER_HK" -%}
{%- set src_dfk = "CUSTOMER_HK" -%}
{%- set src_sfk = "ORDER_HK" -%}
{%- set src_start_date = "START_DATE" -%}
{%- set src_end_date = "END_DATE" -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATETIME" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.eff_sat(source_model=source_model,
                       src_pk=src_pk,
                       src_dfk=src_dfk,
                       src_sfk=src_sfk,
                       src_start_date=src_start_date,
                       src_end_date=src_end_date,
                       src_eff=src_eff,
                       src_ldts=src_ldts,
                       src_source=src_source) }}