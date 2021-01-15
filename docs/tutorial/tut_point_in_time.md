# Point In Time (PITs)

DESCRIPTION/PURPOSE

#### Structure

Our point-in-time structures will contain:

##### Header describing each piece of metadata in detail
    
### Setting up PIT models

Create a new dbt model as before. We'll call this one `example_name_pit`. 

`example_name_pit.sql`
```jinja
{{ dbtvault.pit() }}
```

[Read more about incremental models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)

### Adding the metadata

Let's look at the metadata we need to provide to the [pit](../macros.md#pit) macro.

#### Source table


#### Source columns


### Running dbt


### Next steps

That is all for now. More table types will be coming in future! See our [roadmap](../roadmap.md) for more details.

If you want a more realistic real-world example, with real data to work with, take a look at our [worked example](../worked_example/we_worked_example.md).