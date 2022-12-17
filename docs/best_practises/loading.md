!!! example "Work in Progress"
    This article is a work in progress! We understand there needs to be clarity on how to load effectively in dbtvault.
    More information (and helpful features!) about loading is coming soon!

## Single record per key, per load (incremental)

At the current time, dbtvault will load discrete records with the same primary key (hash key) simultaneously. This means
that any deltas formed by loading these records in individual cycles get lost. For Hubs and Links this is not a problem,
as there are no temporal attributes, but for structures such as Satellites this will produce erroneous loads.

Until a future release solves this limitation for structures configured with the built-in **incremental
materialisation**, we advise that you use one of our provided [custom materialisations](../materialisations.md).

These materialisations are fully configurable and automatically iterate over records, to load each batch/iteration
separately.

We are working on removing this limitation and implementing 'intra-period' loading. If you have any questions, please
get in touch.

## Record source table code

We suggest you use a code for your record source. This can be anything that makes sense for your particular context,
though usually an integer or alpha-numeric value works well. The code often gets used to look up the full table name in
a reference table.

You may do this with dbtvault by providing the code as a constant in the [staging](../tutorial/tut_staging.md) layer, using
the [stage](../macros/index.md#stage) macro. The [staging walk-through](../tutorial/tut_staging.md) presents this exact use-case in
the code examples.

If there is already a source in the raw staging layer, you may keep this or override it using
the [stage](../macros/index.md#stage) macro.





