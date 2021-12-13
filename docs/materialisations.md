###### (macros/materialisations)

Materialisations dictate how a model is created in the database.

dbt comes with 4 standard materialisations:

- Table
- View
- Incremental
- Ephemeral

[Read more about materialisations here](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/materializations/)

For dbtvault, we have created some custom materialisations which support Data Vault 2.0 specific patterns which are 
documented below.

### vault_insert_by_period (Insert by Period)

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.9/macros/materialisations/vault_insert_by_period_materialization.sql))

This materialisation is based on
the [insert_by_period](https://github.com/dbt-labs/dbt-utils/blob/master/macros/materializations/insert_by_period_materialization.sql)
materialisation developed by dbt Labs for the [dbt-utils](https://github.com/dbt-labs/dbt-utils)
package.

We have re-purposed it and provided support for Snowflake, as well as added a number of convenience features.

Features include:

- Idempotent loading
- Inference of date range to load with
- Manually configurable date range to load with
- Configurable granularity (day, month, year etc.)

The purpose of the materialisation is to insert data into a table iteratively and periodically, using a configured date
range. More detail on how this works is below.

#### Usage

=== "Manual Load range #1"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    start_date='2020-01-30') }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

=== "Manual Load range #2"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    start_date='2020-01-30', stop_date='2020-04-30') }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

=== "Manual Load range #3"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    start_date='2020-01-30', stop_date='2020-04-30', date_source_models=var('source_model')) }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

=== "Inferred Load range"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    date_source_models=var('source_model')) }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

#### Initial/Base Load vs. Incremental Load

Due to the way materialisations currently work in dbt, the model which the `vault_insert_by_period` materialisation is
applied to, must be run twice to complete a full load.

The first time a model with the materialisation applied is run, a `BASE LOAD` is executed. This loads all data for the
first period in the load date range (e.g. The first day's data). All subsequent runs of the same model will execute
incremental loads for each consecutive period.

The first period load will be repeated but no duplicates should be inserted when using dbtvault macros.

##### Run Output

Examples of output for dbt runs using the [eff_sat](macros.md#eff_sat) macro and this materialisation.

=== "Initial/Base load"

    ```text
    15:24:08 | Concurrency: 4 threads (target='snowflake')
    15:24:08 | 15:24:08 | 1 of 1 START vault_insert_by_period model TEST.EFF_SAT..... [RUN]
    15:24:10 | 1 of 1 OK created vault_insert_by_period model TEST.EFF_SAT [BASE LOAD 1 in 1.78s]
    15:24:10 | 15:24:10 | Finished running 1 vault_insert_by_period model in 3.99s.
    ```

=== "Incremental load"

    ```text 
    15:24:16 | Concurrency: 4 threads (target='snowflake')
    15:24:16 | 15:24:16 | 1 of 1 START vault_insert_by_period model TEST.EFF_SAT..... [RUN]
    15:24:17 + Running for day 1 of 4 (2020-01-10) [model.dbtvault_test.EFF_SAT]
    15:24:18 + Ran for day 1 of 4 (2020-01-10); 0 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:18 + Running for day 2 of 4 (2020-01-11) [model.dbtvault_test.EFF_SAT]
    15:24:20 + Ran for day 2 of 4 (2020-01-11); 0 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:20 + Running for day 3 of 4 (2020-01-12) [model.dbtvault_test.EFF_SAT]
    15:24:21 + Ran for day 3 of 4 (2020-01-12); 2 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:22 + Running for day 4 of 4 (2020-01-13) [model.dbtvault_test.EFF_SAT]
    15:24:24 + Ran for day 4 of 4 (2020-01-13); 2 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:24 | 1 of 1 OK created vault_insert_by_period model TEST.EFF_SAT [INSERT 4 in 8.13s]
    15:24:25 | 15:24:25 | Finished running 1 vault_insert_by_period model in 10.24s.
    ```

#### Configuring the load date range

The start and finish date of the load can be configured in a number of different ways. Depending on how the
materialisation is configured, the start and end of the load will get defined differently, as shown in the table below.

| Configuration                | Outcome                                                                                                                 | Usage                | 
|------------------------------|-------------------------------------------------------------------------------------------------------------------------|----------------------|
| `start_date`                 | The load will start at `start_date`, and the `stop_date` will be set to the **current date**.                           | Manual Load range #1 |
| `start_date` and `stop_date` | The load will start at `start_date`, and stop at `stop_date`                                                            | Manual Load range #2 |                  
| `date_source_models`         | The models will be unioned together, and the minimum and maximum dates extracted from the data in the `timestamp_field` | Inferred Load range  |                 
| All three config options     | Manually provided configuration acts as an override. The load will start at `start_date`, and stop at `stop_date`       | Manual Load range #3 |    

Please refer to the _Usage_ section above to see examples.

#### Configuration Options

| Configuration      | Description                                     | Type                | Default | Required?                                         |
|--------------------|-------------------------------------------------|---------------------|---------|---------------------------------------------------|
| timestamp_field    | A list of column names                          | List[String]        | None    | :fontawesome-solid-check-circle:{ .required }     |
| period             | Time period to load over                        | String              | day     | :fontawesome-solid-minus-circle:{ .not-required } |
| start_date         | The date to start the load from                 | String (YYYY-MM-DD) | None    | See: Configuring the load date range (above)      |
| stop_date          | The date to stop the load on                    | String (YYYY-MM-DD) | None    | See: Configuring the load date range (above)      |
| date_source_models | A list of models containing the timestamp_field | List[String]/String | None    | See: Configuring the load date range (above)      |

#### Period

The period configuration option allows us to configure the granularity of the load.

The naming varies per platform, though some common examples are:

- hour
- day
- month
- year

See below for the platform-specific documentation.

- [Snowflake](https://docs.snowflake.com/en/sql-reference/functions-date-time.html#supported-date-and-time-parts)

#### Automatic load range inference

Providing a list of models with the `date_source_models` configuration option, will automatically load all data from the
source with date or date-times between the minimum and maximum values contained in the `timestamp_field` column.

When using the dbtvault table template macros, `date_source_models` should be the same as the `source_model` attribute
in the macro.

This does not necessarily have to be the case however, and it is possible to create a waterlevel-like table as follows:

=== "waterlevel.sql"

    | TYPE  | LOAD_DATE      | 
    | ----- | -------------- | 
    | Start | 2020-01-30     | 
    | Stop  | 2020-04-30     |

Where `LOAD_DATE` is provided to the materialisation as the `timestamp_field`, and `date_source_models` is provided
as `waterlevel` (the model name).

#### Using the materialisation with non-dbtvault SQL

Every [table template macro](macros.md#table-templates) includes a `__PERIOD_FILTER__` string in its SQL when used in
conjunction with this materialisation.

At runtime, this string is replaced with SQL which applies conditions to filter the dates contained in
the `timestamp_field` to those specified in the load date range. If you are only using dbtvault table template macros
with this materialisation, then there is no need for any additional work.

However, If you are writing your own models and wish to use this materialisation, then you must include
a `WHERE __PERIOD_FILTER__`
somewhere appropriate in your model. A CTE which selects from your source model and then includes the placeholder,
should provide best results.

See the [hub](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.9/macros/tables/hub.sql) source code for 
a demonstration of this.

#### Idempotent loads

This materialisation supports idempotent loads when used with dbtvault macros. When calculating the `start` and `stop`
dates of the load, a `COALESCE` function is applied. This `COALESCE` call compares the maximum timestamp contained in
the `timestamp_field`, and the provided or inferred `start_date` and sets the `start_date`
to whatever is larger (more recent). This means that any aborted loads will continue where they left off, and any
duplicate loads will not have any effect (if using dbtvault macros).

If you wish support idempotent loads in your own models using this materialisation, the best approach is to
use `LEFT OUTER JOINS` to ensure duplicate records do not get loaded.

### vault_insert_by_rank (Insert by Rank)

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.9/macros/materialisations/vault_insert_by_rank_materialization.sql))

The `vault_insert_by_rank` custom materialisation provides the means to iteratively load raw vault structures from an
arbitrary rank column, created in the staging layer.

The `RANK()` window function is used to rank (using an `ORDER BY` clause) a row within the current 'window' of the
function, which is defined by the
`PARTITION BY` clause.

The custom materialisation uses this value as the value to iterate over when loading; a row with rank 1 will be loaded
prior to a row with rank 2, and so on.

This materialisation can be used to correctly load temporal structures (such as satellites) where records may have
millisecond timings between them, by partitioning by the primary/hash key of a table, and ordering by the timestamp
column.

#### Usage

```jinja
{{ config(materialized='vault_insert_by_rank', rank_column='DBTVAULT_RANK', rank_source_models='MY_STAGE') }}

{{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                    src_start_date=src_start_date, src_end_date=src_end_date,
                    src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                    source_model=source_model) }}
```

#### Configuration Options

| Configuration      | Description                                        | Type         | Default | Required?                                     |
|--------------------|----------------------------------------------------|--------------|---------|-----------------------------------------------|
| rank_column        | The column name containing the rank values         | String       | None    | :fontawesome-solid-check-circle:{ .required } |
| rank_source_models | A list of model names containing the `rank_column` | List[String] | None    | :fontawesome-solid-check-circle:{ .required } |

#### Creating a rank column

A rank column can be created one of three ways:

1. Manually creating it in a model prior to the staging layer, and using this model as the stage's `source_model`.

2. Using the `ranked_columns` configuration of the [stage](macros.md#stage) macro

    ```yaml
    source_model: "MY_STAGE"
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: "CUSTOMER_HK"
        order_by: "LOAD_DATETIME"
    ```

3. Using the `derived_columns` configuration of the [stage](macros.md#stage) macro

    ```yaml
    source_model: "MY_STAGE"
    derived_columns:
      DBTVAULT_RANK: "RANK() OVER(PARTITION BY CUSTOMER_HK ORDER BY LOAD_DATETIME)"
    ```

!!! note
    [Read more](macros.md#defining-and-configuring-ranked-columns) about defining ranked columns.

#### Which option?

- Method #2 is recommended, as makes it easier for rank columns to use user-defined derived or hashed columns created in the
  same staging layer.
- Method #3 is similar, except it will not have hashed or derived column definitions available to it.

!!! warning "Check your rank"

    It is important that once a rank column is created, it should be sense checked for correct and expected ordering. If your ranking is incorrect according to
    the business, then loading will not be executed correctly.

### pit_incremental

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.9/macros/materialisations/incremental_pit_materialization.sql))

The `pit_incremental` custom materialisation is the required materialisation for the [PIT table](macros.md#pit) as it
allows for a continuous reconstruction of the PIT table. 

Since PITs are not historized, but query helper tables, they have to be reconstructed (at least) once every reporting 
cycle. 

This materialisation simply ensures that the old contents of the PIT table are removed before the new version 
populates the target table, for each run of the PIT model.

#### Usage

```jinja
{{ config(materialized='pit_incremental') }}

{{ dbtvault.pit(source_model=source_model, src_pk=src_pk,
                    as_of_dates_table=as_of_dates_table,
                    satellites=satellites,
                    stage_tables=stage_tables,
                    src_ldts=src_ldts) }}                    
```

### bridge_incremental

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.9/macros/materialisations/incremental_bridge_materialization.sql))

The `bridge_incremental` custom materialisation is the required materialisation for the [Bridge table](macros.md#bridge)
as it allows for a continuous reconstruction of the Bridge table. 

Since Bridges are not historized, but query helper tables, they have to be reconstructed (at least) once every reporting
cycle. 

This materialisation simply ensures that the old contents of the Bridge table are removed before the new version 
populates the target table, for each run of the Bridge model. 

#### Usage

```jinja
{{ config(materialized='bridge_incremental') }}

{{ dbtvault.bridge(source_model=source_model, src_pk=src_pk,
                       bridge_walk=bridge_walk,
                       as_of_dates_table=as_of_dates_table,
                       stage_tables_ldts=stage_tables_ldts,
                       src_ldts=src_ldts) }}
```
