Problematic column names have been a nuisance in SQL since its inception. If we have a reserved word as a column name, 
for example a column named "COLUMN", or a column with spaces in, then we will get compilation issues.

Prior to dbtvault v0.8.0, we had no built-in solution for this and users would have to solve this their own way using
a variety of work-arounds including staging layers specifically for fixing these issues, which is incredibly awkward!

In dbtvault v0.8.0 we introduced column escaping, implementing it in a platform-agnostic (via multi-dispatch) way,
allowing the user to configure it and ultimately solving the problem.

Unfortunately, this introduced a whole load of [bugs](https://www.github.com/Datavault-UK/dbtvault/issues/168).

In dbtvault v0.9.1, we have dialed this escaping back to what it should have been: only in the staging and nowhere else.

Escaping works as follows:

When defining derived columns, the user must specify if the columns being used to compose the derived column, should be escaped:

```yaml hl_lines="2-6"
source_model: raw_source     
derived_columns:
  SOURCE: "!STG_BOOKING"
  EFFECTIVE_FROM:
    source_column: "BOOKING DATE"
    escape: true
```

Here, we escape the "BOOKING DATE" column, due to it having a space.

!!! note
    This feature is also described [here](../macros/stage_macro_configurations.md#escaping-column-names-that-are-not-sql-compliant)

## Inferred escaping

Columns may be escaped manually by the user in functions, for example:

```yaml hl_lines="4"
source_model: raw_source     
derived_columns:
  SOURCE: "!STG_BOOKING"
  BOOKING_FLAG: "NOT \"BOOKING COMPLETED\""
```

Because the user has escaped "BOOKING COMPLETED" dbtvault will use this information to ensure "BOOKING COMPLETED" 
is also escaped elsewhere in the stage, for example, in hashes and null column configurations which may have bene added
by the user.

!!! warning
    This functionality is new! If you find any bugs or have issues related to this feature, [please submit a bug report](https://www.github.com/Datavault-UK/dbtvault/issues).
