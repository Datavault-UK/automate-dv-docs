The table below indicates which macros and templates are officially available for each platform.

AutomateDV is primarily developed on Snowflake, and we release support for other platforms as and when possible.
Most of the time this will be at the same time as the Snowflake release unless it is snowflake-only functionality
with no equivalent in another platform.

Thanks for your patience and continued support!

| Macro/Template | Snowflake                                     | Google BigQuery                               | MS SQL Server                                 | Databricks                                    | Postgres                                      | Redshift**                                        |
|----------------|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|---------------------------------------------------|
| ref_table      | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| hash           | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| stage          | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| hub            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| link           | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| sat            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| t_link         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| eff_sat        | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| ma_sat         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| xts            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| pit            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| bridge         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |

!!! note "**"
    These platforms are either planned or actively being worked on by the community and/or internal AutomateDV team.
    See the issues below for more information:

    - [Redshift](https://github.com/Datavault-UK/automate-dv/issues/86)