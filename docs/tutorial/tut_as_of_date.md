An As of Dates table contains a single column of dates used to construct the history in tables like PITs and Bridges. 

The date range and the date interval size is often informed by the current reporting period and can be changed on the fly.
An example of a usual date range could be the _end of day_ timestamps for each day of the last 3 months.

Periodically, the As of Dates table would be refreshed, to accommodate for the new reporting period.

### Structure

The As of Dates table consists of a single datetime column, currently defaulted to `AS_OF_DATE`. 

The macro used here to generate the As of Dates table with its single column, (currently defaulted to) `AS_OF_DATE`,
is dbt_utils [date_spine](https://github.com/dbt-labs/dbt-utils#date_spine-source).

The macro will require the following input:

#### Date interval (datepart)

#### Start Date (start_date)

#### End Date (end_date)

### Creating the model

Create a new model as before. We'll call this one `as_of_dates`.

=== "as_of_dates.sql"

    ```jinja
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2019-01-01' as date)",
        end_date="cast('2020-01-01' as date)"
       )
    }}
    ```
To create an As of Dates model, simply copy and paste the above template into a model named `as_of_dates` (or similar).
dbt_utils will generate a As of Dates table using the parameters provided in the next steps.
