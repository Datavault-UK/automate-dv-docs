# Extended Tracking Satellites (XTS)

DESCRIPTION/PURPOSE

#### Structure

Our extended tracking satellites structures will contain:

##### Header describing each piece of metadata in detail
    
### Setting up XTS models

Create a new dbt model as before. We'll call this one `example_name_xts`. 

`example_name_xts.sql`
```jinja
{{ dbtvault.xts() }}
```

[Read more about incremental models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)

### Adding the metadata

Let's look at the metadata we need to provide to the [xts](../macros.md#xts) macro.

#### Source table


#### Source columns


### Running dbt


### Next steps

We have now created:

- A staging layer 
- A Hub 
- A Link
- A Transactional Link
- A Satellite
- An Effectivity Satellite
- An Extended Tracking Satellite

Next we will look at [point in time structures](tut_point_in_time.md).