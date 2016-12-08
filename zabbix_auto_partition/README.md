# Description

Auto create new partitions and drop old partitions for Zabbix database.

# Steps

Execute the following sql scripts to create tables, procedures, event, and insert initialization data.
+ zabbix_tables.sql
+ maintenance_tables_and_data.sql
+ procedures.sql
+ event.sql

**If you don't modify the sql scripts above, the event will start at 20:00:00 on the 28th day every month.**  
**And these tables will be auto partitioned:** `history`, `history_log`, `history_str`, `history_text`, `history_uint`, `trends`, `trends_uint`.  
The maintenance history will be logged in table `partition_logs`.

If you want to add other tables that be auto partitioned, you can add these tables in table `partition_management`.  
You can also modify the event's(`event_partition_maintenance`) execute time by yourself.