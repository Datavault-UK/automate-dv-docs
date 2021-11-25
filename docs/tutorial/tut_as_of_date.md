An As of Dates table contains a single column of dates used to construct the history in tables like PITs and Bridges. 

The date range and the date interval size is often informed by the current reporting period and can be changed on the fly.
An example of a usual date range could be all dates from the last 3 months.

Periodically, the As of Dates table would be refreshed, to accommodate for the new reporting period.

### Structure

The As of Dates table consists of a single date column, currently defaulted to `AS_OF_DATE`. 

The macro used here to generate the As of Dates table is [dbt_utils date_spine](https://github.com/dbt-labs/dbt-utils#date_spine-source).

It will require the following input:

#### Date interval (datepart)

This is the parameter that defines the granularity of the date intervals. It needs to be a unit of time 
(e.g. "hour", "day", "week").  

#### Start Date (start_date)

This parameter defines the earliest possible date for the date range. If `datepart` is _day_ or greater, then the value 
for `start_date` will be included in the list of values for `AS_OF_DATE`.

#### End Date (end_date)

The `end_date` parameter defines the latest possible date for the date range. The value for `end_date` will **not** be 
included in the list of values for `AS_OF_DATE`.

### Setting up an As of Dates model

Create a new dbt model as before. We'll call this one `as_of_dates`.

=== "as_of_dates.sql"

    ```jinja
    WITH as_of_dates AS (
        {{ dbt_utils.date_spine(datepart, start_date, end_date) }}
    )

    SELECT DATE_{{datepart}} as AS_OF_DATE FROM as_of_dates
    ```

To create an As of Dates model, simply copy and paste the above template into a model named `as_of_dates` (or similar).
With the help of dbt_utils `date_spine` function, the template will generate an As of Dates table using the parameters 
provided in the next steps.

#### Materialisation

The recommended materialisation for an As of Dates table is `table`.

To refresh the As of Dates table to reflect the new reporting period, you need to change the values in the parameters and
run the dbt model again.

### Adding the metadata

Let's look at the metadata we need to provide to the as_of_dates template.

| Parameter      | Value                               | 
| -------------- | ----------------------------------- | 
| datepart       | day                                 | 
| start_date     | to_date('2021/01/01', 'yyyy/mm/dd') |
| end_date       | to_date('2021/04/01', 'yyyy/mm/dd') |

When we provide the metadata above, our model should look like the following:

=== "as_of_dates.sql"

    ```jinja
    {%- set datepart = "day" -%}
    {%- set start_date="to_date('2021/01/01', 'yyyy/mm/dd')" -%}
    {%- set end_date="to_date('2021/04/01', 'yyyy/mm/dd')" -%}
    
    WITH as_of_dates AS (
        {{ dbt_utils.date_spine(datepart=datepart, 
                                start_date=start_date,
                                end_date=end_date) }}
    )

    SELECT DATE_{{datepart}} as AS_OF_DATE FROM as_of_dates 
    ```

### Running dbt

With our metadata provided and our model complete, we can run dbt to create our As of Dates table, as follows:

=== "< dbt v0.20.x"
    `dbt run -m as_of_dates`

=== "> dbt v0.21.0"
    `dbt run --select as_of_dates`

And the resulting As of Dates table will look like this:

| AS_OF_DATE   |
| ------------ |
| 2021-01-01   |
| 2021-01-02   |
| .            |
| .            |
| 2021-03-30   |
| 2021-03-31   |
