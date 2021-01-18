# Point In Time (PITs)

A Point-In-Time table is not needed for actually loading the data vault but is instead built with accordance to business needs.
The PIT table will the bolster the query performance of the raw vault when the satellites are not loaded with cadence of each other.
As it will act as a pointer reference for the valid data entry's of the satellites for a given history described in an 
as of dates table. A PIT tables benefits become more apparent the greater the number of satellites its reference's, although 
two is technically the minimum amount it needs even if it will not be utilised to its full effect.

#### Structure

Our point-in-time structures will contain:

##### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key. This will be the primary key used
by the Hub.

##### as_of_dates_table 
The as_of_dates_table describes the history needed to construct the PIT table as a list of dates. This is where you would 
supply the name of your as of date table.

##### Satellites
This is a dictionary of the satellites that is used to define their metadata. Each satellite entry will be its name exatly and will contain
two nested dictionaries pk and ldts. which will define the satellite key and the date column used to compare to the as of table. 
These will contain a key pair described below.

The satellite_key is the hashed key in the satellite that directly corresponds to the Hub_PK. These should be the exact same.
The only difference being the key may not be defined as the primary_key in the satellite it could be defined as a foreign key
or a hashed key. It will be defined by 'the suffix desired for this key (eg:PK, FK, HK)' : 'name of the key in the satellite'

The satellite_date_column. This is the column used to compare to the as of dates column when deciding what is the valid entry.
Typically, the Load_date is used, but the effective_from can also be used. You must keep in mind however when using effective from
although the entry may be the most valid for that date it may not have been a representation of the data vault on that day as the load date could be
further in the future. The key pair will be defined by 'the suffix for date type column used (eg: LDTS, EF)' : 'name of the date column you want to use'

##### source_model
This is the name of the Hub that contains the primary key (src_pk) and that the satellites are connected to. 


### Setting up PIT models

Create a new dbt model as before. We'll call this one `example_name_pit`. 

`example_name_pit.sql`
```jinja
{{ {{ dbtvault.pit({src_pk}, {as_of_dates_table}, {satellites}, 
    {source_model})                                       }} }}
```

To create a PIT model, we simply copy and paste the above template into a model named after the PIT we
are creating. dbtvault will generate a PIT using parameters provided in the next steps.

PITS should use the table materialization, as the pit is remade with every new as of dates table. 

We recommend setting the `table` materialization on all of your pits using the `dbt_project.yml` file:


### Adding the metadata

Let's look at the metadata we need to provide to the [pit](../macros.md#pit) macro.

#### Source table


#### Source columns


### Running dbt


### Next steps

That is all for now. More table types will be coming in future! See our [roadmap](../roadmap.md) for more details.

If you want a more realistic real-world example, with real data to work with, take a look at our [worked example](../worked_example/we_worked_example.md).