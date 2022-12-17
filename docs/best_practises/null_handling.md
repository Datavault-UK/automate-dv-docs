# NULL Handling

The handling of nulls is important in Data Vault 2.0 because - as a general rule - nulls represent a lack of something,
and therefore do not mean anything to the business. This means we do not want records or keys containing nulls ending up
in our raw vault. dbtvault, without any configuration from the user, will ignore all NULLs being loaded into 
Hubs and Links, with slightly different handling for other table types. This is documented in the sections below.

Sometimes though, columns might have a null value in the source data and there is a requirement to import the associated 
records anyway, because they still carry business meaning. For this case, we provide users the option to configure
how NULLs in business keys are handled, using the Data Vault standard of replacing them with 'tokens' (i.e. placeholders).

dbtvault's [business-key Null handling feature](../macros/stage_macro_configurations.md#null-columns) provides this option; 
the null key can be replaced by a default value and the original null value stored in an additional column. 
The key might be required, for instance where it is the basis for a hashed primary key, or it might be optional. 

The default replacement value for a required key is -1 and for an optional key is -2. The replacement process is enabled 
by a configuration setting in [staging](../macros/stage_macro_configurations.md#null-columns).

!!! tip
    The null keys default values can be configured, [Read more](../macros/index.md#global-variables)

If not configured by the user, NULLs get handled in the built-in hashing processes in dbtvault:

- Nulls get replaced with a placeholder; by default this is `^^`.
- If all components of a non-hashdiff (PK/HK) hashed column are NULL, then the whole key will evaluate as NULL and the record will not be loaded.
- If all components of a hashdiff hashed column are NULL, then the hashdiff will be a hash of `^^` multiplied by how
  many columns the hashdiff is composed of and separated by the concat string, which is `||` by default. e.g.
  ```text
    ^^||^^||^^ = 3C92E664B39D90428DBC94975B5DDA58
  ```

!!! tip
    The concat (`||`) and null (`^^`) strings can be configured, [Read more](../macros/index.md#global-variables)

This is described in more depth below (with code examples).

dbtvault has built-in support for ensuring nulls do not get loaded into the raw vault. Null handling has been described
below for each structure:

### Staging

All records get loaded and hashes evaluated as null according to the descriptions above and details in the hashing
sections below.

Keys containing null values are replaced according to configuration settings [stage](../macros/index.md#stage). 

### Hubs

If the primary key is NULL, then the record does not get loaded.

### Links

If the primary or ANY of the foreign keys are null, then the record does not get loaded.

### Satellites

If the primary key is NULL, then the record does not get loaded.

### Transactional Links

If the primary or ANY of the foreign keys are null, then the record does not get loaded.

### Effectivity Satellites

If the driving key column(s) or secondary foreign key (sfk) column(s) are null then the record does not get loaded.

!!! note 
    There is no logic to exclude records with null PKs because the PK of an Effectivity Satellite should be all the
    SFK and DFK columns (so the PK will evaluate as null if they are all null).