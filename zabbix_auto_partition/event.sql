/*
Author: Tyoung
Date: 20161125
Desc: Relevant event of Zabbix MySQL partition.
*/

-- Event: event_partition_maintenance
DELIMITER $$

USE zabbix$$

DROP EVENT IF EXISTS event_partition_maintenance$$
CREATE DEFINER='root'@'localhost' EVENT event_partition_maintenance
    ON SCHEDULE EVERY 1 MONTH STARTS '2016-12-28 20:00:00'
    ON COMPLETION PRESERVE
    ENABLE
    COMMENT '定期执行Procedure(prc_partition_maintenance)，管理表分区'
DO
BEGIN
    -- 每月执行该任务，创建下一个月的分区表
    DECLARE v_current_year_month VARCHAR(10);
    DECLARE v_next_year_month VARCHAR(10);
    
    SET v_current_year_month = DATE_FORMAT(CURRENT_DATE(), '%Y%m');
    SET v_next_year_month = PERIOD_ADD(v_current_year_month, 1);
    
    CALL prc_partition_maintenance(v_next_year_month);
END$$

DELIMITER ;