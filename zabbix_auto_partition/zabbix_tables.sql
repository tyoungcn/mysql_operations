/*
Author: Tyoung
Date: 20161125
Desc: Zabbix history and trends table structure that use TokuDB and partition.
    Zabbix version: 3.0.1
*/

USE `zabbix`;

-- Table: history
DROP TABLE IF EXISTS `history`;
CREATE TABLE `history` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` double(16,4) NOT NULL DEFAULT '0.0000',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_1` (`itemid`,`clock`)
) ENGINE=TokuDB DEFAULT CHARSET=utf8 `compression`='tokudb_zlib'
/*!50100 PARTITION BY RANGE (clock)
(PARTITION p201610 VALUES LESS THAN (1477929600) ENGINE = TokuDB,
 PARTITION p201611 VALUES LESS THAN (1480521600) ENGINE = TokuDB,
 PARTITION p201612 VALUES LESS THAN (1483200000) ENGINE = TokuDB,
 PARTITION pmore VALUES LESS THAN MAXVALUE ENGINE = TokuDB) */;

-- Table: history_log
DROP TABLE IF EXISTS `history_log`;
CREATE TABLE `history_log` (
  `id` bigint(20) unsigned NOT NULL,
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `timestamp` int(11) NOT NULL DEFAULT '0',
  `source` varchar(64) NOT NULL DEFAULT '',
  `severity` int(11) NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  `logeventid` int(11) NOT NULL DEFAULT '0',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  KEY `history_log_2` (`itemid`,`id`),
  KEY `history_log_1` (`itemid`,`clock`)
) ENGINE=TokuDB DEFAULT CHARSET=utf8 `compression`='tokudb_zlib'
/*!50100 PARTITION BY RANGE (clock)
(PARTITION p201610 VALUES LESS THAN (1477929600) ENGINE = TokuDB,
 PARTITION p201611 VALUES LESS THAN (1480521600) ENGINE = TokuDB,
 PARTITION p201612 VALUES LESS THAN (1483200000) ENGINE = TokuDB,
 PARTITION pmore VALUES LESS THAN MAXVALUE ENGINE = TokuDB) */;

-- Table: history_str
DROP TABLE IF EXISTS `history_str`;
CREATE TABLE `history_str` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` varchar(255) NOT NULL DEFAULT '',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_str_1` (`itemid`,`clock`)
) ENGINE=TokuDB DEFAULT CHARSET=utf8 `compression`='tokudb_zlib'
/*!50100 PARTITION BY RANGE (clock)
(PARTITION p201610 VALUES LESS THAN (1477929600) ENGINE = TokuDB,
 PARTITION p201611 VALUES LESS THAN (1480521600) ENGINE = TokuDB,
 PARTITION p201612 VALUES LESS THAN (1483200000) ENGINE = TokuDB,
 PARTITION pmore VALUES LESS THAN MAXVALUE ENGINE = TokuDB) */;

-- Table: history_text
DROP TABLE IF EXISTS `history_text`;
CREATE TABLE `history_text` (
  `id` bigint(20) unsigned NOT NULL,
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  KEY `history_text_2` (`itemid`,`id`),
  KEY `history_text_1` (`itemid`,`clock`)
) ENGINE=TokuDB DEFAULT CHARSET=utf8 `compression`='tokudb_zlib'
/*!50100 PARTITION BY RANGE (clock)
(PARTITION p201610 VALUES LESS THAN (1477929600) ENGINE = TokuDB,
 PARTITION p201611 VALUES LESS THAN (1480521600) ENGINE = TokuDB,
 PARTITION p201612 VALUES LESS THAN (1483200000) ENGINE = TokuDB,
 PARTITION pmore VALUES LESS THAN MAXVALUE ENGINE = TokuDB) */;

-- Table: history_uint
DROP TABLE IF EXISTS `history_uint`;
CREATE TABLE `history_uint` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` bigint(20) unsigned NOT NULL DEFAULT '0',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_uint_1` (`itemid`,`clock`)
) ENGINE=TokuDB DEFAULT CHARSET=utf8 `compression`='tokudb_zlib'
/*!50100 PARTITION BY RANGE (clock)
(PARTITION p201610 VALUES LESS THAN (1477929600) ENGINE = TokuDB,
 PARTITION p201611 VALUES LESS THAN (1480521600) ENGINE = TokuDB,
 PARTITION p201612 VALUES LESS THAN (1483200000) ENGINE = TokuDB,
 PARTITION pmore VALUES LESS THAN MAXVALUE ENGINE = TokuDB) */;

-- Table: trends
DROP TABLE IF EXISTS `trends`;
CREATE TABLE `trends` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `value_min` double(16,4) NOT NULL DEFAULT '0.0000',
  `value_avg` double(16,4) NOT NULL DEFAULT '0.0000',
  `value_max` double(16,4) NOT NULL DEFAULT '0.0000',
  PRIMARY KEY (`itemid`,`clock`)
) ENGINE=TokuDB DEFAULT CHARSET=utf8 `compression`='tokudb_zlib'
/*!50100 PARTITION BY RANGE (clock)
(PARTITION p201610 VALUES LESS THAN (1477929600) ENGINE = TokuDB,
 PARTITION p201611 VALUES LESS THAN (1480521600) ENGINE = TokuDB,
 PARTITION p201612 VALUES LESS THAN (1483200000) ENGINE = TokuDB,
 PARTITION pmore VALUES LESS THAN MAXVALUE ENGINE = TokuDB) */;

-- Table: trends_uint
DROP TABLE IF EXISTS `trends_uint`;
CREATE TABLE `trends_uint` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `value_min` bigint(20) unsigned NOT NULL DEFAULT '0',
  `value_avg` bigint(20) unsigned NOT NULL DEFAULT '0',
  `value_max` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`itemid`,`clock`)
) ENGINE=TokuDB DEFAULT CHARSET=utf8 `compression`='tokudb_zlib'
/*!50100 PARTITION BY RANGE (clock)
(PARTITION p201610 VALUES LESS THAN (1477929600) ENGINE = TokuDB,
 PARTITION p201611 VALUES LESS THAN (1480521600) ENGINE = TokuDB,
 PARTITION p201612 VALUES LESS THAN (1483200000) ENGINE = TokuDB,
 PARTITION pmore VALUES LESS THAN MAXVALUE ENGINE = TokuDB) */;
