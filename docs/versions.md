This page shows which versions of AutomateDV and dbt which have been tested together.

Other versions of dbt may be compatible with the specified AutomateDV version, however there may be unpredictable
results. Please take care!

Only the last 10 versions of AutomateDV will be shown below.

### Version matrix

| AutomateDV version                                                 | dbt version(s)  | Advice                                                                     |
|--------------------------------------------------------------------|-----------------|----------------------------------------------------------------------------|
| [v0.11.4](https://hub.getdbt.com/Datavault-UK/automate_dv/0.11.4/) | >=1.9.x, <3.0.0 | Use latest dbt 1.10.x version. Now dbt Fusion compatible! ***              |
| [v0.11.3](https://hub.getdbt.com/Datavault-UK/automate_dv/0.11.3/) | >=1.4.0, <2.0.0 | Use latest dbt 1.9.x version.***                                           |
| [v0.11.2](https://hub.getdbt.com/Datavault-UK/automate_dv/0.11.2/) | >=1.4.0, <2.0.0 | Use latest dbt 1.9.x version.***                                           |
| [v0.11.1](https://hub.getdbt.com/Datavault-UK/automate_dv/0.11.1/) | >=1.4.0, <2.0.0 | AVOID THIS VERSION - A Hotfix for this version is provided in v0.11.2      |
| [v0.11.0](https://hub.getdbt.com/Datavault-UK/automate_dv/0.11.0/) | >=1.4.0, <2.0.0 | Use latest dbt 1.8.x version.***                                           |
| [v0.10.2](https://hub.getdbt.com/Datavault-UK/automate_dv/0.10.2/) | >=1.4.0, <2.0.0 | Use latest dbt 1.7.x version.                                              |
| [v0.10.1](https://hub.getdbt.com/Datavault-UK/automate_dv/0.10.1/) | >=1.4.0, <2.0.0 | Use latest dbt 1.4.x version.                                              |
| [v0.10.0](https://hub.getdbt.com/Datavault-UK/automate_dv/0.10.0/) | >=1.4.0, <2.0.0 | Use latest dbt 1.4.x version.                                              |
| [v0.9.7](https://hub.getdbt.com/Datavault-UK/automate_dv/0.9.7/)   | >=1.4.0, <2.0.0 | Use latest dbt 1.4.x version.                                              |
| [v0.9.6](https://hub.getdbt.com/Datavault-UK/automate_dv/0.9.6/)   | >=1.4.0, <2.0.0 | Use latest dbt 1.4.x version.                                              |

### A note on dbt Fusion Support

dbt Fusion is a new offering from dbt which rebuilds dbt from the ground up with Rust, adding performance enhancements 
and opening up opportunities for new capabilities. 

AutomateDV now supports dbt fusion officially as of v0.11.4, though v0.11.3 had some initial changes to pave the way 
for full support. dbt Fusion is continually changing, and we will endeavour to support it moving forward.

If you have any issues with dbt Fusion compatibility, or indeed any AutomateDV functionality, please feel free to [open 
an issue on GitHub](https://github.com/Datavault-UK/automate-dv/issues). Thank you!


### Notes

\*\*\*For MSSQL Server, dbt 1.10.x is currently not supported officially.
Please use dbt 1.9.x versions instead.
    
