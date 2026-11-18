{{ config(
    full_refresh=true
) }}

{%- set source_model = "stg_customer" -%}
{%- set src_pk = "CUSTOMER_HK" -%}
{%- set src_fk = "CUSTOMER_ID" -%}
{%- set src_ldts = "LOAD_DATETIME" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.link(source_model=source_model,
                    src_pk=src_pk,
                    src_fk=src_fk,
                    src_ldts=src_ldts,
                    src_source=src_source) }}