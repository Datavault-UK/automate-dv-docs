An As of Date table contains a single column of dates used to construct the history in tables like PITs and Bridges. 

The date range and the date interval size is often informed by the current reporting period and can be changed on the fly.
An example of a usual date range could be all dates from the last 3 months.

Periodically, the As of Date table would be refreshed, to accommodate for the new reporting period.

### Structure

The As of Date table consists of a single date/datetime column, and is currently generated using the 
[dbt_utils.date_spine](https://github.com/dbt-labs/dbt-utils#date_spine-source) macro. 

!!! note
    dbt_utils is another package for dbt, provided by dbt Labs. The date_spine macro above is provided by this package.
    For more information, go read the date_spine docs [here](https://github.com/dbt-labs/dbt-utils#date_spine-source).
    dbtvault includes dbt_utils as a dependency, and is installed alongside the dbtvault package. 

It will require the following input:

#### Date interval (datepart)

This is the parameter that defines the granularity of the date intervals. It needs to be a unit of time 
(e.g. "hour", "day", "week").  

#### Start Date (start_date)

This parameter defines the earliest possible date for the date range. The value for `start_date` will be included in the
list of values for `AS_OF_DATE`, if it is aligned (i.e. of the same - or lower - granularity) with `datepart`.

#### End Date (end_date)

The `end_date` parameter defines the latest possible date for the date range. The value for `end_date` will **not** be 
included in the list of values for `AS_OF_DATE`.

### Setting up an As of Date model

Create a new dbt model as before. We'll call this one `as_of_date`.

=== "as_of_date.sql"

    ```jinja
    WITH as_of_date AS (
        {{ dbt_utils.date_spine(datepart, start_date, end_date) }}
    )

    SELECT DATE_{{datepart}} as AS_OF_DATE FROM as_of_date
    ```

To create an As of Date model, simply copy and paste the above template into a model named `as_of_date` (or similar).
With the help of dbt_utils `date_spine` function, the template will generate an As of Date table using the parameters 
provided in the next steps.

#### Materialisation

The recommended materialisation for an As of Date table is `table`.

To refresh the As of Dates to reflect the new reporting period, you need to change the values in the parameters and
run the dbt model again.

### Adding the metadata

Let's look at the metadata we need to provide to the As of Dates template.

| Parameter      | Value                               | 
| -------------- | ----------------------------------- | 
| datepart       | day                                 | 
| start_date     | to_date('2021/01/01', 'yyyy/mm/dd') |
| end_date       | to_date('2021/04/01', 'yyyy/mm/dd') |

When we provide the metadata above, our model should look like the following:

=== "as_of_date.sql"

    ```jinja
    {{ config(materialized='table') }}
    
    {%- set datepart = "day" -%}
    {%- set start_date="to_date('2021/01/01', 'yyyy/mm/dd')" -%}
    {%- set end_date="to_date('2021/04/01', 'yyyy/mm/dd')" -%}
    
    WITH as_of_date AS (
        {{ dbt_utils.date_spine(datepart=datepart, 
                                start_date=start_date,
                                end_date=end_date) }}
    )

    SELECT DATE_{{datepart}} as AS_OF_DATE FROM as_of_date
    ```

### Running dbt

With our metadata provided and our model complete, we can run dbt to create our As of Dates, as follows:

=== "< dbt v0.20.x"
    `dbt run -m as_of_date`

=== "> dbt v0.21.0"
    `dbt run --select as_of_date`

And the resulting As of Date table will look like this:

| AS_OF_DATE   |
| ------------ |
| 2021-01-01   |
| 2021-01-02   |
| .            |
| .            |
| 2021-03-30   |
| 2021-03-31   |
