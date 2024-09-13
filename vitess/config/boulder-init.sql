-- Primary, unsharded, 2014-2024 Boulder DB
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
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
--
-- caaRecheckingAffectedSerials
CREATE TABLE IF NOT EXISTS `caaRecheckingAffectedSerials` (
  `serial` varchar(255) NOT NULL,
  PRIMARY KEY (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
--
-- certificateStatus
CREATE TABLE IF NOT EXISTS `certificateStatus` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `serial` varchar(255) NOT NULL,
  `subscriberApproved` tinyint(1) DEFAULT 0,
  `status` varchar(255) NOT NULL,
  `ocspLastUpdated` datetime NOT NULL,
  `revokedDate` datetime NOT NULL,
  `revokedReason` int(11) NOT NULL,
  `lastExpirationNagSent` datetime NOT NULL,
  `LockCol` bigint(20) DEFAULT 0,
  `ocspResponse` blob DEFAULT NULL,
  `notAfter` datetime DEFAULT NULL,
  `isExpired` tinyint(1) DEFAULT 0,
  `issuerID` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `isExpired_ocspLastUpdated_idx` (`isExpired`,`ocspLastUpdated`),
  KEY `notAfter_idx` (`notAfter`),
  KEY `serial` (`serial`)
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
-- certificates
CREATE TABLE IF NOT EXISTS `certificates` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `registrationID` bigint(20) NOT NULL,
  `serial` varchar(255) NOT NULL,
  `digest` varchar(255) NOT NULL,
  `der` mediumblob NOT NULL,
  `issued` datetime NOT NULL,
  `expires` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `regId_certificates_idx` (`registrationID`) COMMENT 'Common lookup',
  KEY `issued_idx` (`issued`),
  KEY `serial` (`serial`)
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
-- certificatesPerName
CREATE TABLE IF NOT EXISTS `certificatesPerName` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `eTLDPlusOne` varchar(255) NOT NULL,
  `time` datetime NOT NULL,
  `count` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `eTLDPlusOne_time_idx` (`eTLDPlusOne`,`time`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
--
-- crls
CREATE TABLE IF NOT EXISTS `crls` (
  `serial` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `crl` varchar(255) NOT NULL,
  PRIMARY KEY (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
--
-- fqdnSets
CREATE TABLE IF NOT EXISTS `fqdnSets` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `setHash` binary(32) NOT NULL,
  `serial` varchar(255) NOT NULL,
  `issued` datetime NOT NULL,
  `expires` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `setHash_issued_idx` (`setHash`,`issued`),
  KEY `serial` (`serial`)
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
-- issuedNames
CREATE TABLE IF NOT EXISTS `issuedNames` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `reversedName` varchar(640) CHARACTER SET ascii NOT NULL,
  `notBefore` datetime NOT NULL,
  `serial` varchar(255) NOT NULL,
  `renewal` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `reversedName_notBefore_Idx` (`reversedName`,`notBefore`),
  KEY `reversedName_renewal_notBefore_Idx` (`reversedName`,`renewal`,`notBefore`)
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
-- issuedNamesOld
CREATE TABLE IF NOT EXISTS `issuedNamesOld` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reversedName` varchar(640) CHARACTER SET ascii NOT NULL,
  `notBefore` datetime NOT NULL,
  `serial` varchar(255) NOT NULL,
  `renewal` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `reversedName_notBefore_Idx` (`reversedName`,`notBefore`),
  KEY `reversedName_renewal_notBefore_Idx` (`reversedName`,`renewal`,`notBefore`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
--
-- keyHashToSerial
CREATE TABLE IF NOT EXISTS `keyHashToSerial` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `keyHash` binary(32) NOT NULL,
  `certNotAfter` datetime NOT NULL,
  `certSerial` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_keyHash_certserial` (`keyHash`,`certSerial`),
  KEY `keyHash_certNotAfter` (`keyHash`,`certNotAfter`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
--
-- newOrdersRL
CREATE TABLE IF NOT EXISTS `newOrdersRL` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `regID` bigint(20) NOT NULL,
  `time` datetime NOT NULL,
  `count` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `regID_time_idx` (`regID`,`time`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
--
-- orderFqdnSets
CREATE TABLE IF NOT EXISTS `orderFqdnSets` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `setHash` binary(32) NOT NULL,
  `orderID` bigint(20) NOT NULL,
  `registrationID` bigint(20) NOT NULL,
  `expires` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `setHash_expires_idx` (`setHash`,`expires`),
  KEY `orderID_idx` (`orderID`),
  KEY `orderFqdnSets_registrationID_registrations` (`registrationID`)
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
-- orderToAuthz2
CREATE TABLE IF NOT EXISTS `orderToAuthz2` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `orderID` bigint(20) NOT NULL,
  `authzID` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orderID_idx` (`orderID`),
  KEY `authzID_idx` (`authzID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4
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
-- precertificates
CREATE TABLE IF NOT EXISTS `precertificates` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `registrationID` bigint(20) NOT NULL,
  `serial` varchar(255) NOT NULL,
  `der` mediumblob NOT NULL,
  `issued` datetime NOT NULL,
  `expires` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `regId_precertificates_idx` (`registrationID`),
  KEY `issued_precertificates_idx` (`issued`),
  KEY `serial` (`serial`)
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
--
-- replacementOrders
CREATE TABLE IF NOT EXISTS `replacementOrders` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `serial` varchar(255) NOT NULL,
  `orderID` bigint(20) NOT NULL,
  `orderExpires` datetime NOT NULL,
  `replaced` boolean DEFAULT false,
  PRIMARY KEY (`id`),
  KEY `serial_idx` (`serial`),
  KEY `orderID_idx` (`orderID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4
 PARTITION BY RANGE(id)
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
-- requestedNames
CREATE TABLE IF NOT EXISTS `requestedNames` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `orderID` bigint(20) NOT NULL,
  `reversedName` varchar(253) CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orderID_idx` (`orderID`),
  KEY `reversedName_idx` (`reversedName`)
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
-- revokedCertificates
CREATE TABLE IF NOT EXISTS `revokedCertificates` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `issuerID` bigint(20) NOT NULL,
  `serial` varchar(255) NOT NULL,
  `notAfterHour` datetime NOT NULL,
  `shardIdx` bigint(20) NOT NULL,
  `revokedDate` datetime NOT NULL,
  `revokedReason` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `issuerID_shardIdx_notAfterHour_idx` (`issuerID`, `shardIdx`, `notAfterHour`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
 PARTITION BY RANGE(id)
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
-- serials
CREATE TABLE IF NOT EXISTS `serials` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `registrationID` bigint(20) NOT NULL,
  `serial` varchar(255) NOT NULL,
  `created` datetime NOT NULL,
  `expires` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial` (`serial`),
  KEY `regId_serials_idx` (`registrationID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
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
-- paused
CREATE TABLE IF NOT EXISTS `paused` (
  `registrationID` bigint(20) UNSIGNED NOT NULL,
  `identifierType` tinyint(4) NOT NULL,
  `identifierValue` varchar(255) NOT NULL,
  `pausedAt` datetime NOT NULL,
  `unpausedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`registrationID`, `identifierValue`, `identifierType`)
);
-- Used for incidents tables

CREATE SCHEMA IF NOT EXISTS `boulder_incidents`;

USE `boulder_incidents`;
CREATE USER IF NOT EXISTS 'sa'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'sa-ro'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'ssa'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'ssa-ro'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'ocsp-responder'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'bad-key-revoker'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'notify-mailer'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'mailer'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'orchestrator'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'cert-checker'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'sa-incidents'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED WITH mysql_native_password BY 'youshallnotpass';


GRANT ALL ON `ifn-boulder`.* TO 'sa'@'%';
GRANT SELECT ON `ifn-boulder`.* TO 'sa-ro'@'%';
GRANT ALL ON `ifn-boulder`.* TO 'ssa'@'%';
GRANT SELECT ON `ifn-boulder`.* TO 'ssa-ro'@'%';

GRANT SELECT ON `ifn-boulder`.* TO 'ocsp-responder'@'%';
GRANT ALL ON `ifn-boulder`.* TO 'bad-key-revoker'@'%';
GRANT ALL ON `ifn-boulder`.* TO 'notify-mailer'@'%';
GRANT ALL ON `ifn-boulder`.* TO 'mailer'@'%';
GRANT ALL ON `ifn-boulder`.* TO 'cert-checker'@'%';
GRANT ALL ON `ifn-boulder`.* TO 'orchestrator'@'%';

GRANT SELECT ON `ifn-boulder`.* TO 'sa-incidents'@'%';
GRANT SELECT ON `boulder_incidents`.* TO 'sa-incidents'@'%';

GRANT SELECT ON `ifn-boulder`.* TO 'monitor'@'%';
