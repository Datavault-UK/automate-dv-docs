{%- set source_model = "stg_transactions" -%}
{%- set src_pk = "TRANSACTION_HK" -%}
{%- set src_fk = ["CUSTOMER_HK", "ORDER_HK"] -%}
{%- set src_payload = ["o_orderdate", "o_orderpriority", "o_clerk",
                       "o_shippriority", "o_comment", "o_totalprice",
                       "o_orderstatus"] -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATETIME" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.t_link(source_model=source_model,
                      src_pk=src_pk,
                      src_fk=src_fk,
                      src_payload=src_payload,
                      src_eff=src_eff,
                      src_ldts=src_ldts,
                      src_source=src_source) }}