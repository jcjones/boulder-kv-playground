CREATE SCHEMA IF NOT EXISTS `ifn-boulder`;

USE `ifn-boulder`;

--
-- blockedKeys
CREATE TABLE IF NOT EXISTS `blockedKeys` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `keyHash` binary(32) NOT NULL,
  `added` datetime NOT NULL,
  `source` tinyint(4) NOT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `revokedBy` bigint(20) DEFAULT 0,
  `extantCertificatesChecked` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `keyHash` (`keyHash`),
  KEY `extantCertificatesChecked_idx` (`extantCertificatesChecked`)
) ENGINE=RocksDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

--
-- crls
CREATE TABLE IF NOT EXISTS `crls` (
  `serial` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `crl` varchar(255) NOT NULL,
  PRIMARY KEY (`serial`)
) ENGINE=RocksDB DEFAULT CHARSET=utf8;
--
-- crlShards
CREATE TABLE IF NOT EXISTS `crlShards` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `issuerID` bigint(20) NOT NULL,
  `idx` int UNSIGNED NOT NULL,
  `thisUpdate` datetime,
  `nextUpdate` datetime,
  `leasedUntil` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shardID` (`issuerID`, `idx`)
) ENGINE=RocksDB DEFAULT CHARSET=utf8mb4;

--
-- orderToAuthz2
CREATE TABLE IF NOT EXISTS `orderToAuthz2` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `orderID` bigint(20) NOT NULL,
  `authzID` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orderID_idx` (`orderID`),
  KEY `authzID_idx` (`authzID`)
) ENGINE=RocksDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4
 PARTITION BY RANGE (`id`)
(PARTITION `p_1` VALUES LESS THAN (100),
 PARTITION `p_2` VALUES LESS THAN (200),
 PARTITION `p_3` VALUES LESS THAN (300),
 PARTITION `p_4` VALUES LESS THAN (400),
 PARTITION `p_5` VALUES LESS THAN (500),
 PARTITION `p_6` VALUES LESS THAN (600),
 PARTITION `p_7` VALUES LESS THAN (700),
 PARTITION `p_10` VALUES LESS THAN (1000),
 PARTITION `p_50` VALUES LESS THAN (5000),
 PARTITION `p_150` VALUES LESS THAN (15000),
 PARTITION `p_250` VALUES LESS THAN (25000),
 PARTITION `p_end` VALUES LESS THAN (MAXVALUE));

--
-- requestedNames
CREATE TABLE IF NOT EXISTS `requestedNames` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `orderID` bigint(20) NOT NULL,
  `reversedName` varchar(253) CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orderID_idx` (`orderID`),
  KEY `reversedName_idx` (`reversedName`)
) ENGINE=RocksDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8
 PARTITION BY RANGE (`id`)
(PARTITION `p_1` VALUES LESS THAN (100),
 PARTITION `p_2` VALUES LESS THAN (200),
 PARTITION `p_3` VALUES LESS THAN (300),
 PARTITION `p_4` VALUES LESS THAN (400),
 PARTITION `p_5` VALUES LESS THAN (500),
 PARTITION `p_6` VALUES LESS THAN (600),
 PARTITION `p_7` VALUES LESS THAN (700),
 PARTITION `p_10` VALUES LESS THAN (1000),
 PARTITION `p_50` VALUES LESS THAN (5000),
 PARTITION `p_150` VALUES LESS THAN (15000),
 PARTITION `p_250` VALUES LESS THAN (25000),
 PARTITION `p_end` VALUES LESS THAN MAXVALUE);

--
-- Temporary use of fqdnSets_old, 2021-09-28, see
-- https://github.com/letsencrypt/boulder/issues/5670
CREATE TABLE IF NOT EXISTS `fqdnSets_old` LIKE `fqdnSets`;
--
-- incidents
CREATE TABLE IF NOT EXISTS `incidents` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `serialTable` varchar(128) NOT NULL,
    `url` varchar(1024) NOT NULL,
    `renewBy` datetime NOT NULL,
    `enabled` boolean DEFAULT false,
    PRIMARY KEY (`id`)
) CHARSET=utf8mb4;
--
-- issuedNamesOffsets
CREATE TABLE IF NOT EXISTS `issuedNamesOffsets` (
  `datestamp` DATE,
  `id` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`datestamp`)
) DEFAULT CHARSET=utf8mb4;
--