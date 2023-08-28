# Changelog (Stable)

All stable and notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

!!! note
    To view documentation for a specific version, please click the 'docs' badges under the specific changelog entry.

[View Beta Releases](beta.md){ .md-button .md-button--primary }
[View Archived Releases](archived.md){ .md-button .md-button--primary }

___

# [v0.10.1] - 2023-08-28
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.10.1)](https://automate-dv.readthedocs.io/en/v0.10.0/?badge=v0.10.0)
[![dbt Versions](https://img.shields.io/badge/compatible%20dbt%20versions-%3E=1.3%20%3C=1.4.x-orange?logo=dbt)](https://dbtvault.readthedocs.io/en/latest/versions/)

## Fixes 

### All Platforms

- Fixed the case where repeating a load would cause duplicates when using the Satellites as released in 0.10.0 (#207)
  - Implemented as a new Behaviour Flag for Satellites `apply_source_filter` 
    - [Read more in loading best practises](../best_practises/loading.md#the-apply_source_filter-config-option)
    - [Read more on sat() macro Behaviour Flags](../best_practises/loading.md#the-apply_source_filter-config-option)

___

# [v0.10.0] - 2023-08-14
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.10.0)](https://automate-dv.readthedocs.io/en/v0.10.0/?badge=v0.10.0)
[![dbt Versions](https://img.shields.io/badge/compatible%20dbt%20versions-%3E=1.3%20%3C=1.4.x-orange?logo=dbt)](https://dbtvault.readthedocs.io/en/latest/versions/)

## New

### All Platforms

- Reference Tables ([ref_table macro](../macros/index.md#ref_table)) 

    - [Tutorial](../tutorial/tut_ref_tables.md)

## Improved 

### All Platforms

Satellite loading limitations resolved :tada::tada::tada:

- [Migration Guide](../migration_guides.md#migrating-from-097-to-0100) 
- Updated [Loading Guide](../best_practises/loading.md#satellites) 


___

# [v0.9.7] - 2023-07-19
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.7)](https://automate-dv.readthedocs.io/en/v0.9.7/?badge=v0.9.7)
[![dbt Versions](https://img.shields.io/badge/compatible%20dbt%20versions-%3E=1.3%20%3C=1.4.x-orange?logo=dbt)](https://dbtvault.readthedocs.io/en/latest/versions/)

## New

### Databricks and Postgres

**Databricks and Postgres are now fully supported in v0.9.7!**

- Transactional Links ([t_link macro](../macros/index.md#t_link))
- Effectivity Satellites ([eff_sat macro](../macros/index.md#eff_sat))
- Multi-active Satellites ([ma_sat macro](../macros/index.md#ma_sat))
- Extended Tracking Satellites ([xts macro](../macros/index.md#xts))
- Point in Time tables (PITs) ([pit macro](../macros/index.md#pit))
- Bridges ([bridge macro](../macros/index.md#bridge))

## Fixes

### All platforms

#### Error handling and error messages 

- Cases where escape characters are empty now correctly use the platform default instead.
- Cases where too many iterations (>100,000) would occur for custom vault_insert_by_x materialisations on SQLServer now raise an error.

### Postgres
- Fixed a hashing length bug (#176)

___

# [v0.9.6] - 2023-05-16
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.6)](https://automate-dv.readthedocs.io/en/v0.9.6/?badge=v0.9.6)
[![dbt Versions](https://img.shields.io/badge/compatible%20dbt%20versions-%3E=1.3%20%3C=1.4.x-orange?logo=dbt)](https://dbtvault.readthedocs.io/en/latest/versions/)

## The rebrand update! - dbtvault is now AutomateDV

## Changes

- Macros are now called using `automate_dv` instead of `dbtvault`. e.g. `automate_dv.hub(...)`
- The default `system_record_value` is now `AUTOMATE_DV_SYSTEM` instead of `DBTVAULT_SYSTEM`

___

# [v0.9.5] - 2023-03-22
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.5)](https://automate-dv.readthedocs.io/en/v0.9.5/?badge=v0.9.5)
[![dbt Versions](https://img.shields.io/badge/compatible%20dbt%20versions-%3E=1.3%20%3C=1.4.x-orange?logo=dbt)](https://automate-dv.readthedocs.io/en/latest/versions/)

## Fixes

### All platforms
- Added error handling for when the number of iterations in `vault_insert_by_x` exceeds 100,000 (#175)
- Fixed a regression in PITs where an incorrect join was causing a performance hit and in some cases, incorrect data
- Fixed an issue causing 'LOADING...' log messages to appear when running `dbt docs generate` or `dbt docs serve` 
- Fixed a bug in the `vault_insert_by_period` materialisation affecting executions with 'hour' as the period (#178)

### SQLServer
- Fixed a minor casing issue in the SQLServer `eff_sat` macro (#182)

### Databricks
- Fixed an issue related to #183 but for MD5 hashing in Databricks

___

# [v0.9.4] - 2023-02-16
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.4)](https://automate-dv.readthedocs.io/en/v0.9.4/?badge=v0.9.4)

This is a minor hotfix update. More bug fixes to come soon! :smile: 

## Fixes

- Binary type not defaulting correctly (Snowflake) (#183)

___

# [v0.9.3] - 2023-01-27
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.3)](https://automate-dv.readthedocs.io/en/v0.9.3/?badge=v0.9.3)

## Fixes

- Updated `packages.yml` for compatibility with dbt-utils 1.0.0

## Notes

- Fully tested (and passing) with dbt-utils 1.0.0 and dbt 1.3.2 

## Thank you to our community

Thank you to all those who were being patient for this release. The delay was due to us wanting to release this with a few other bug fixes and new features. This additional content is being released at a later date so that we could get this dbt-utils fix out to our community sooner.

___

# [v0.9.2] - 2022-12-22
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.2)](https://automate-dv.readthedocs.io/en/v0.9.2/?badge=v0.9.2)

## Fixes

- Hotfixes for issues with Ghost Record creation under certain circumstances ([#173](https://github.com/Datavault-UK/automate-dv/issues/173),[#174](https://github.com/Datavault-UK/automate-dv/issues/174))

In other news: Happy Holidays!

___

# [v0.9.1] - 2022-12-16
[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.1)](https://automate-dv.readthedocs.io/en/v0.9.1/?badge=v0.9.1)

## New 

### New Features: 

:star2: Ghost Records -> [docs](../macros#ghost-record-configuration)

:star2: Hashing Casing config (#123) -> [Docs](../macros#hash_content_casing)

### dbt Versions

:+1: dbt support updated to 1.3.x

:+1: dbt-utils support updated to 0.9.x (1.0.x will be officially supported shortly)

## Fixes

### Escaping

We have made significant changes to how escaping now works as per #168. We believe this will fix the bugs collected in this master issue.

**_Whilst we have tested this extensively, we cannot yet be 100% this has fixed every edge case. Please bear with us as we collect community feedback. We welcome your feedback on this!_**

Related issues:

- https://github.com/Datavault-UK/automate-dv/issues/168 
- https://github.com/Datavault-UK/automate-dv/issues/159 

### Casing

In addition to the above, we have also done an overhaul of casing in our templates. Users should now not experience any unwanted casing changes. As above, please provide feedback if any issues are found! 

Related issues:

- https://github.com/Datavault-UK/automate-dv/issues/166
- https://github.com/Datavault-UK/automate-dv/issues/163 
- https://github.com/Datavault-UK/automate-dv/issues/157 

### Other

- Fixed a few edge cases where excludes for payload and hashdiffs would not work as expected 

## Behind the scenes

- Major re-factor of Hashing to improve maintainability, readability and extensibility.  **_The functionality remains the same and should not affect users_**

## Docs

- Split best practises into separate pages for ease of navigation and to reduce clutter
- Moved old release notes to a new "archived" releases page

___

# [v0.9.0] - 2022-09-13

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.9.0)](https://automate-dv.readthedocs.io/en/v0.9.0/?badge=v0.9.0)

### New Platform Support

#### Databricks

:sparkles: Staging

:sparkles: Hubs

:sparkles: Links

:sparkles: Satellites

#### Postgres**

:sparkles: Staging

:sparkles: Hubs

:sparkles: Links

:sparkles: Satellites


!!! note
    There are currently limitations on Postgres. [Click here for more details](https://automate-dv.readthedocs.io/en/v0.9.0/macros/#limitations)


### New Features

Introducing:

:star2: Payload column exclusion: Satellite's payload can now be configured to select all columns, except a user-defined
list using an `exclude` configuration (https://github.com/Datavault-UK/automate-dv/issues/128)

:star2: Null Business Key Handling: Now users can provide a configuration in their staging tables to handle NULL keys
elegantly, according to business needs (https://github.com/Datavault-UK/automate-dv/issues/133)

:star2: Extra Columns Parameter: All table macros now provide a `src_extra_columns` parameter which allows users to add
extra columns outside the standard template for business needs.

:star2: More logging: Hubs and Links now provide additional logging about the number of sources they are loading from.
Minor but helpful! This is our first step towards giving our users more information.

### Fixes

:white_check_mark: Fixed an edge case for `vault_insert_by_period` when the staging table and the target table were in
different databases (https://github.com/Datavault-UK/automate-dv/issues/121)

:white_check_mark: Removed the uppercase conversion in the staging
macro (https://github.com/Datavault-UK/automate-dv/issues/122, https://github.com/Datavault-UK/automate-dv/issues/134)

:white_check_mark: Fixed an issue where duplicate records (same hashdiff) would sometimes be loaded into a
Satellite (https://github.com/Datavault-UK/automate-dv/issues/126)

:white_check_mark: Disabled automatic column name escaping in derived columns when using the `stage()` macro. Escaping
can now be configured on a case-by-case basis for each column to escape when they are reserved words
etc. (https://github.com/Datavault-UK/automate-dv/issues/114, https://github.com/Datavault-UK/automate-dv/issues/141)

### Breaking changes

- [Read our 0.83 to 0.9.0 migration guide](https://automate-dv.readthedocs.io/en/latest/migration_guides/#migrating-from-083-to-090)

### Behind the scenes

- Re-factor PIT and Bridge macros to ensure better maintainability and readability

### Docs

- Moved stage configuration details to
  a [new page](https://automate-dv.readthedocs.io/en/latest/macros/stage_macro_configurations)
- Updated packages behind the scenes for security and bug fixes
- Created landing pages for sections, which should make navigation easier, e.g. getting started is now the home page
  when clicking 'Tutorials' in the menu, instead of having to click twice.

### Thanks

[View on GitHub](https://github.com/Datavault-UK/automate-dv/releases/tag/v0.9.0])

___

# [v0.8.3] - 2022-05-10

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.8.3)](https://automate-dv.readthedocs.io/en/v0.8.3/?badge=v0.8.3)

All existing macros are now supported by all platforms!

### New

#### General

- dbt 1.1.x support

#### Google BigQuery and MS SQL Server

- PITs ([pit macro](../macros/index.md#pit))
- Bridges ([bridge macro](../macros/index.md#bridge))

### Fixed

##### Effectivity Satellites

- Fixed an issue affecting auto-end-dating in flip-flop
  situations [eff_sat](../macros/index.md#effsat) ([#115](https://github.com/Datavault-UK/automate-dv/issues/115))

##### Staging

- Fixed an issue where hashed columns with lower-case columns provided to an `exclude_columns` config, behaved
  incorrectly ([#110](https://github.com/Datavault-UK/automate-dv/issues/110))

___

# [v0.8.2] - 2022-03-14

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.8.2)](https://automate-dv.readthedocs.io/en/v0.8.2/?badge=v0.8.2)

More Google BigQuery and MS SQL Server support, plus fixes!

### New

#### Google BigQuery and MS SQL Server

- T-Links ([t_link macro](../macros/index.md#tlink))
- Effectivity Satellites ([eff_sat macro](../macros/index.md#effsat))
- Multi-Active Satellites ([ma_sat macro](../macros/index.md#masat))
- Extended Tracking Satellites ([xts macro](../macros/index.md#xts))

See our [Platform support matrix](../macros/index.md#platform-support) for more details.

### Fixed

- Fixed a bug where `vault_insert_by_period` would give an error during incremental
  loads ([#108](https://github.com/Datavault-UK/automate-dv/issues/108))
- Fixed `vault_insert_by_x` issues for MS SQL Server
- Fixed (increased) datetime precision in `max_datetime` for Google BigQuery

___

# [v0.8.1] - 2022-02-22

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.8.1)](https://automate-dv.readthedocs.io/en/v0.8.1/?badge=v0.8.1)

HOTFIX RELEASE

### Fixed

- Fixed a bug where `vault_insert_by_rank` unintentionally used logic from `vault_insert_by_period` when in full-refresh
  mode or replacing an existing view.

___

# [v0.8.0] - 2022-02-21

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.8.0)](https://automate-dv.readthedocs.io/en/v0.8.0/?badge=v0.8.0)

This is a big release for AutomateDV. It's the first time we are releasing support for new platforms!
Please welcome to the AutomateDV family, Google BigQuery and MS SQL Server!

This is just the start, and we're excited to bring even more platforms (and further support for existing platforms)
to you in the future!

### New

#### Google BigQuery and MS SQL Server

- Hubs (hub macro)
- Links (link macro)
- Satellites (sat macro)

!!! tip "New"
[Platform support matrix](../macros/index.md#platform-support)

#### All platforms

- Column Escaping ([#28](https://github.com/Datavault-UK/automate-dv/issues/28)
  , [#23](https://github.com/Datavault-UK/automate-dv/issues/23))
  - [Docs](../macros/index.md#escapecharleftescapecharright):
  AutomateDV now automatically surrounds all column names with quotes. This is to allow for columns with reserved words,
  spaces, and other oddities.
  The type of quotes is configurable, please refer to the docs linked above.

___

# [v0.7.9] - 2021-12-13

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.7.9)](https://automate-dv.readthedocs.io/en/v0.7.9/?badge=v0.7.9)

### Dependencies

#### Breaking

- dbt v1.0.0 Support
    - Support for earlier dbt versions (dbt <=0.21.0) removed. This is as a result of the upgrade to dbt v1.0.0.
      [How do I upgrade my project?](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0)
- Updated to dbt_utils v0.8.0 (for dbt 1.0.0 compatibility)

### New

#### Table structures

- Point in Time tables [Tutorial](../tutorial/tut_point_in_time.md) - [Macro docs](../macros/index.md#pit)
- Bridge tables [Tutorial](../tutorial/tut_bridges.md) - [Macro docs](../macros/index.md#bridge)
- Extended Tracking Satellites (XTS) [Tutorial](../tutorial/tut_xts.md) - [Macro docs](../macros/index.md#xts)

#### Materialisations

- Custom materialisation for PITs [Docs](../materialisations.md#pitincremental)
- Custom materialisation for Bridges [Docs](../materialisations.md#bridgeincremental)

#### Behind the Scenes

- More test coverage for incremental loading.
- Improved consistency and support for Composite PKs.
- Significantly simplified Multi-Active Satellite (MAS) logic.

### Bug Fixes

- Multi-Active Satellite record duplication under some
  circumstances [#50](https://github.com/Datavault-UK/automate-dv/issues/50)

___

# [v0.7.8] - 2021-10-25

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.7.8)](https://automate-dv.readthedocs.io/en/v0.7.8/?badge=v0.7.8)

### Dependencies

- dbt 0.21.0 support
- dbt utils package dependency now has a version range (sorry!)

### Fixes

- Effectivity Satellites **with auto-end-dating off** now handle the use case where records may already be end-dated in
  the staging layer,
  as a result of loading data 'manually' end-dated by business rules.

### Features

#### Rank column configurations in stage macro (ranked_columns):

- Provide ASC or DESC for an `order_by` column [Read More](../macros/stage_macro_configurations.md#order-by-direction)
- Configure the ranking to use `DENSE_RANK()`
  or `RANK()` [Read More](../macros/stage_macro_configurations.md#dense-rank)

#### Configuration for hash strings

[Read More](../best_practises/hashing.md#configuring-hash-strings)

- Concatenation string can now be user defined
- Null placeholder string can now be user defined

___

# [v0.7.7] - 2021-08-24

- Re-release of v0.7.6.1 to ensure deployment to dbt Hub

## [v0.7.6.1] - 2021-07-14

- Hotfix for 0.7.6 to remove unintentionally added macros from the beta
  branch. [#36](https://github.com/Datavault-UK/automate-dv/issues/36)

### Installing

**Note:** This version **cannot** be installed via dbt hub, please install as follows:

```
packages:
  - git: "https://github.com/Datavault-UK/automate-dv.git"
    revision: v0.7.6.1
```

___

# [v0.7.6] - 2021-07-13

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.7.6)](https://automate-dv.readthedocs.io/en/v0.7.6/?badge=v0.7.6)

- Updated to dbt 0.20.0 and incorporated `adapter.dispatch`
  changes [(#32)](https://github.com/Datavault-UK/automate-dv/issues/32)

___

# [v0.7.5] - 2021-06-10

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.7.5)](https://automate-dv.readthedocs.io/en/v0.7.5/?badge=v0.7.5)

### New structures

- Multi-Active Satellites [Read More](../tutorial/tut_multi_active_satellites.md)

### Bug Fixes

- Fixed a bug where an Effectivity Satellite with multiple DFKs or SDKs would incorrectly handle changes in the
  corresponding link records, meaning
  one-to-many relationships were not getting handled as intended.

### Improvements

- Added support for multiple `order_by` or `partition_by` columns when creating ranked columns in the `stage`
  or `ranked_columns` macros.
- Performance improvement for the Satellite macro, which aims to reduce the number of records handled in the
  initial selection of records from the source data.

___

# [v0.7.4] - 2021-03-27

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.7.4)](https://automate-dv.readthedocs.io/en/v0.7.4/?badge=v0.7.4)

### Bug Fixes

- Fixed NULL handling bugs in Hubs, Links and Satellites [(#26)](https://github.com/Datavault-UK/automate-dv/issues/26)
- Fixed a bug where Effectivity Satellites would incorrectly end-date (with auto-end-dating enabled) records other than
  the
  latest, resulting in duplicate end-date records for previously end-dated records.

### Improvements

- Added check for matching primary key when inserting new satellite records in the sat macro. This removes the
  requirement to
  add the natural key to the hashdiff, but it is still
  recommended. [Read More](../best_practises/hashing#hashdiff-components)

### Quality of Life

- Payload in Transactional (Non-Historised) Links now optional
- Effective From in Satellites now optional

___

# [v0.7.3] - 2021-01-28

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=v0.7.3)](https://automate-dv.readthedocs.io/en/v0.7.3/?badge=v0.7.3)

- Updated dbt to v0.19.0
- Updated dbt utils to 0.6.4