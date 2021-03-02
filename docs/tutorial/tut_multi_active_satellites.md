# Multi Active Satellites (MAS)

< DESCRIPTION HERE >

#### Structure

Our multi active satellite structures will contain:

##### English-readable name of column/metadata attribute (attribute name)
< DESCRIPTION >

##### source_model

< SEE OTHER tut_x pages >

### Setting up MAS models

Create a new dbt model as before. We'll call this one `CHANGE_ME.sql`. 

`CHANGE_ME.sql`
```jinja
{{ dbtvault.ma_sat(<attributes here>) }}
```

### Adding the metadata

Let's look at the metadata we need to provide to the [ma_sat](../macros.md#ma_sat) macro.

#### Source table

< SEE OTHER tut_x pages >

#### Source columns

< SEE OTHER tut_x pages >

### Running dbt

`dbt run -m +pit_customer`

### Next steps

That is all for now. More table types will be coming in future! See our [roadmap](../roadmap.md) for more details.

If you want a more realistic real-world example, with real data to work with, take a look at our [worked example](../worked_example/we_worked_example.md).