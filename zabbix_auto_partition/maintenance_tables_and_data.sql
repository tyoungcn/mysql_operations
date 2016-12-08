/*
Author: Tyoung
Date: 20161125
Desc: Relevant maintenance table structure and initialization data of Zabbix MySQL partition.
*/

USE `zabbix`;

-- Table: partition_management
DROP TABLE IF EXISTS `partition_management`;
CREATE TABLE `partition_management` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `schema_name` VARCHAR(64) NOT NULL COMMENT '库名',
  `table_name` VARCHAR(64) NOT NULL COMMENT '表名',
  `keep_period` INT(10) UNSIGNED NOT NULL COMMENT '历史数据保留时长(单位:月)',
  `is_del_partition` TINYINT(4) NOT NULL DEFAULT '0' COMMENT '是否删除历史分区(0:不删除, 1:删除)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `un_partition_management_1` (`schema_name`,`table_name`)
) ENGINE=INNODB DEFAULT CHARSET=utf8 COMMENT='分区管理表';

-- Table: partition_logs
DROP TABLE IF EXISTS `partition_logs`;
CREATE TABLE `partition_logs` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `schema_name` VARCHAR(64) NOT NULL COMMENT '库名',
  `table_name` VARCHAR(64) NOT NULL COMMENT '表名',
  `maintenance_type` ENUM('ADD','DROP') NOT NULL COMMENT '分区维护类型',
  `partition_name` VARCHAR(200) NOT NULL COMMENT '分区名称',
  `execute_sql` VARCHAR(200) NOT NULL COMMENT '执行的SQL',
  `message` VARCHAR(100) NOT NULL COMMENT '备注信息',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `ix_partition_logs_1` (`schema_name`,`table_name`,`partition_name`),
  KEY `ix_partition_logs_2` (`create_time`)
) ENGINE=INNODB DEFAULT CHARSET=utf8 COMMENT='表分区定时任务执行记录';

-- Initialization data
INSERT  INTO `partition_management`(`schema_name`,`table_name`,`keep_period`,`is_del_partition`) VALUES ('zabbix','history',6,1);
INSERT  INTO `partition_management`(`schema_name`,`table_name`,`keep_period`,`is_del_partition`) VALUES ('zabbix','history_log',6,1);
INSERT  INTO `partition_management`(`schema_name`,`table_name`,`keep_period`,`is_del_partition`) VALUES ('zabbix','history_str',6,1);
INSERT  INTO `partition_management`(`schema_name`,`table_name`,`keep_period`,`is_del_partition`) VALUES ('zabbix','history_text',6,1);
INSERT  INTO `partition_management`(`schema_name`,`table_name`,`keep_period`,`is_del_partition`) VALUES ('zabbix','history_uint',6,1);
INSERT  INTO `partition_management`(`schema_name`,`table_name`,`keep_period`,`is_del_partition`) VALUES ('zabbix','trends',24,1);
INSERT  INTO `partition_management`(`schema_name`,`table_name`,`keep_period`,`is_del_partition`) VALUES ('zabbix','trends_uint',24,1);