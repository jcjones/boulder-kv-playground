CREATE SCHEMA IF NOT EXISTS `ifn-boulder`;

USE `ifn-boulder`;

-- authz2
CREATE TABLE IF NOT EXISTS `authz2` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifierType` tinyint(4) NOT NULL,
  `identifierValue` varchar(255) NOT NULL,
  `registrationID` bigint(20) NOT NULL,
  `status` tinyint(4) NOT NULL,
  `expires` datetime NOT NULL,
  `challenges` tinyint(4) NOT NULL,
  `attempted` tinyint(4) DEFAULT NULL,
  `attemptedAt` datetime DEFAULT NULL,
  `token` binary(32) NOT NULL,
  `validationError` mediumblob DEFAULT NULL,
  `validationRecord` mediumblob DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `regID_expires_idx` (`registrationID`,`status`,`expires`),
  KEY `regID_identifier_status_expires_idx` (`registrationID`,`identifierType`,`identifierValue`,`status`,`expires`),
  KEY `expires_idx` (`expires`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8
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
-- orders
CREATE TABLE IF NOT EXISTS `orders` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `registrationID` bigint(20) NOT NULL,
  `expires` datetime NOT NULL,
  `error` mediumblob DEFAULT NULL,
  `certificateSerial` varchar(255) DEFAULT NULL,
  `beganProcessing` tinyint(1) NOT NULL DEFAULT 0,
  `created` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `reg_expires` (`registrationID`,`expires`),
  KEY `regID_created_idx` (`registrationID`,`created`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8
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
-- registrations
CREATE TABLE IF NOT EXISTS `registrations` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `jwk` mediumblob NOT NULL,
  `jwk_sha256` varchar(255) NOT NULL,
  `contact` varchar(191) CHARACTER SET utf8mb4 NOT NULL,
  `agreement` varchar(255) NOT NULL,
  `LockCol` bigint(20) NOT NULL,
  `initialIP` binary(16) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  `createdAt` datetime NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'valid',
  PRIMARY KEY (`id`),
  UNIQUE KEY `jwk_sha256` (`jwk_sha256`),
  KEY `initialIP_createdAt` (`initialIP`,`createdAt`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `paused` (
  `registrationID` bigint(20) UNSIGNED NOT NULL,
  `identifierType` tinyint(4) NOT NULL,
  `identifierValue` varchar(255) NOT NULL,
  `pausedAt` datetime NOT NULL,
  `unpausedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`registrationID`, `identifierValue`, `identifierType`)
);

