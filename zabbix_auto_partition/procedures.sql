/*
Author: Tyoung
Date: 20161125
Desc: Relevant procedures of Zabbix MySQL partition.
*/

-- Procedure: prc_partition_create
DELIMITER $$

USE zabbix$$

DROP PROCEDURE IF EXISTS prc_partition_create$$
CREATE DEFINER = 'root'@'localhost' PROCEDURE prc_partition_create(
    IN i_schema_name VARCHAR(64)    -- 分区表所在的库名
    ,IN i_table_name VARCHAR(64)    -- 分区表名
    ,IN i_partition_name VARCHAR(64)    -- 当前分区名称
    ,IN i_partition_value VARCHAR(50)    -- 当前分区值范围
)
    COMMENT '新建表分区'
BEGIN
    DECLARE v_partition_count INT DEFAULT 0;
    DECLARE v_is_maxvalue INT DEFAULT 0;
    
    SET @maintenance_type = 'ADD';    -- 进行表分区操作的类型
    
    /*
      校验是否存在大于当前分区范围值的分区，
      如果存在，则不创建该分区。
    */
    SELECT COUNT(1) INTO v_partition_count
    FROM information_schema.partitions
    WHERE table_schema = i_schema_name
    AND table_name = i_table_name
    AND partition_description <> 'MAXVALUE'
    AND partition_description >= i_partition_value;
    
    
    -- 创建分区，并将相关信息记录到日志表
    IF v_partition_count = 0 THEN
        SET @message = '';
        
        -- 判断是否存在MAXVALUE分区，并使用相应的SQL添加分区
        SELECT COUNT(1) INTO v_is_maxvalue
        FROM information_schema.partitions
        WHERE table_schema = i_schema_name
        AND table_name = i_table_name
        AND partition_description = 'MAXVALUE';
        
        IF v_is_maxvalue = 1 THEN
            SET @execute_sql = CONCAT('ALTER TABLE ', i_schema_name, '.', i_table_name
                ,' REORGANIZE PARTITION pmore INTO (PARTITION ', i_partition_name, ' VALUES LESS THAN (', i_partition_value, ')'
                ,', PARTITION pmore VALUES LESS THAN MAXVALUE);');
        ELSE
            SET @execute_sql = CONCAT('ALTER TABLE ', i_schema_name, '.', i_table_name
                ,' ADD PARTITION (PARTITION ', i_partition_name, ' VALUES LESS THAN (', i_partition_value, '));');
        END IF;
        
        INSERT INTO partition_logs(schema_name, table_name, partition_name, maintenance_type, execute_sql, message)
            VALUES(i_schema_name, i_table_name, i_partition_name, @maintenance_type, @execute_sql, @message);
        
        PREPARE execute_sql FROM @execute_sql;
        EXECUTE execute_sql;
        DEALLOCATE PREPARE execute_sql;
        
    ELSE
        SET @message = CONCAT('Partition value greater than or equal to the given value(', IFNULL(i_partition_value, 'NULL'), ') already exists.');
        SET @execute_sql = '';
        
        INSERT INTO partition_logs(schema_name, table_name, partition_name, maintenance_type, execute_sql, message)
            VALUES(i_schema_name, i_table_name, i_partition_name, @maintenance_type, @execute_sql, @message);
    END IF;
    
END$$

DELIMITER ;


-- Procedure: prc_partition_drop
DELIMITER $$

USE zabbix$$

DROP PROCEDURE IF EXISTS prc_partition_drop$$
CREATE DEFINER = 'root'@'localhost' PROCEDURE prc_partition_drop(
    IN i_schema_name VARCHAR(64)    -- 分区表所在的库名
    ,IN i_table_name VARCHAR(64)    -- 分区表名
    ,IN i_del_below_part_value VARCHAR(50)    -- 删除小于此分区值的分区(不包含此分区值)
)
    COMMENT '删除历史表分区'
BEGIN
    DECLARE v_drop_part_name VARCHAR(64);
    DECLARE v_done INT DEFAULT FALSE;
    
    -- 获取小于给定分区值的所有分区名称
    DECLARE cur_get_partition_names CURSOR FOR
        SELECT partition_name
        FROM information_schema.partitions
        WHERE table_schema = i_schema_name
        AND table_name = i_table_name
        AND partition_description <> 'MAXVALUE'
        AND partition_description < i_del_below_part_value;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    SET @maintenance_type = 'DROP';    -- 进行表分区操作的类型
    SET @alter_header = CONCAT('ALTER TABLE ', i_schema_name, '.', i_table_name, ' DROP PARTITION ');
    SET @drop_partitions = '';
    SET @message = '';
    SET @execute_sql = '';
    
    
    -- 将所有需要删除的分区拼接起来
    OPEN cur_get_partition_names;
    loop_1: LOOP
        FETCH cur_get_partition_names INTO v_drop_part_name;
        
        IF v_done THEN
            LEAVE loop_1;
        END IF;
        
        SET @drop_partitions = IF(@drop_partitions = '', v_drop_part_name, CONCAT(@drop_partitions, ',', v_drop_part_name));
    END LOOP loop_1;
    
    
    -- 删除小于给定分区值的所有分区，并将相关信息记录到日志表
    IF @drop_partitions != '' THEN
        SET @execute_sql = CONCAT(@alter_header, @drop_partitions, ';');
        
        INSERT INTO partition_logs(schema_name, table_name, partition_name, maintenance_type, execute_sql, message)
            VALUES(i_schema_name, i_table_name, @drop_partitions, @maintenance_type, @execute_sql, @message);
        
        PREPARE execute_sql FROM @execute_sql;
        EXECUTE execute_sql;
        DEALLOCATE PREPARE execute_sql;
        
    ELSE
        SET @message = CONCAT('No partition less than the given value(', IFNULL(i_del_below_part_value, 'NULL'), ') exists.');
        
        INSERT INTO partition_logs(schema_name, table_name, partition_name, maintenance_type, execute_sql, message)
            VALUES(i_schema_name, i_table_name, @drop_partitions, @maintenance_type, @execute_sql, @message);
    END IF;
    
END$$

DELIMITER ;


-- Procedure: prc_partition_maintenance
DELIMITER $$

USE zabbix$$

DROP PROCEDURE IF EXISTS prc_partition_maintenance$$
CREATE DEFINER = 'root'@'localhost' PROCEDURE prc_partition_maintenance(
    IN i_current_year_month VARCHAR(10)    -- 执行添加、删除分区的年月，如：'201611'
)
  -- DETERMINISTIC
  COMMENT '管理表分区（新建分区及删除历史分区）'
BEGIN
    DECLARE v_schema_name VARCHAR(64);    -- 分区表所在的库名
    DECLARE v_table_name VARCHAR(64);    -- 分区表名
    DECLARE v_partition_type VARCHAR(18);    -- 分区类型
    DECLARE v_keep_period INT;    -- 分区表需要保留的历史数据时长（月）
    DECLARE v_del_partition TINYINT;    -- 是否删除历史分区
    DECLARE v_done INT DEFAULT FALSE;
    
    -- 获取所有的表名，对应的库名，及相应的分区详情
    DECLARE cur_get_partition_details CURSOR FOR
        SELECT DISTINCT schema_name
            ,table_name
            ,keep_period
            ,is_del_partition
        FROM partition_management
        ORDER BY schema_name, table_name;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    -- 如果没有指定执行添加、删除分区的年月，则默认为当前年月
    IF i_current_year_month IS NULL OR i_current_year_month = '' THEN
        SET i_current_year_month = DATE_FORMAT(CURRENT_DATE(), '%Y%m');
    END IF;
    
    SET @current_part_name = CONCAT('p', i_current_year_month);
    SET @less_than_date = CONCAT(PERIOD_ADD(i_current_year_month, 1), '01');    -- 当前分区的值范围对应的日期（1号）
    
    
    -- 读取分区管理表数据，并进行新分区创建和历史分区删除
    OPEN cur_get_partition_details;
    
    loop_1: LOOP
        FETCH cur_get_partition_details INTO v_schema_name, v_table_name, v_keep_period, v_del_partition;
        
        IF v_done THEN
            LEAVE loop_1;
        END IF;
        
        
        -- 获取当前表的分区类型，如果为RANGE，则需要将日期转换为整数（UNIX_TIMESTAMP）。Zabbix表使用的此种分区类型。
        -- 如果分区类型为RANGE COLUMNS，则不需要转换日期格式。日志库的表使用的此种分区类型。
        SELECT DISTINCT partition_method INTO v_partition_type
        FROM information_schema.partitions
        WHERE table_schema = v_schema_name
        AND table_name = v_table_name;
        
        SET @del_below_part_date = DATE_ADD(@less_than_date, INTERVAL -v_keep_period MONTH);    -- 需要删除的分区的值对应的日期（删除小于此值的分区）
        
        IF v_partition_type = 'RANGE' THEN
            SET @less_than_value = UNIX_TIMESTAMP(@less_than_date);    -- 当前分区的值范围
            SET @del_below_part_value = UNIX_TIMESTAMP(@del_below_part_date);    -- 删除小于此分区值的分区
        ELSEIF v_partition_type = 'RANGE COLUMNS' THEN
            SET @less_than_value = CONCAT("'", DATE_FORMAT(@less_than_date, '%Y-%m-%d %H:%i:%s'), "'");
            SET @del_below_part_value = CONCAT("'", DATE_FORMAT(@del_below_part_date, '%Y-%m-%d %H:%i:%s'), "'");
        END IF;
        
        
        -- 新建分区。如果需要删除历史分区，则进行删除
        CALL prc_partition_create(v_schema_name, v_table_name, @current_part_name, @less_than_value);
        
        IF v_del_partition = 1 THEN
            CALL prc_partition_drop(v_schema_name, v_table_name, @del_below_part_value);
        END IF;
        
    END LOOP loop_1;
    CLOSE cur_get_partition_details;
END$$

DELIMITER ;