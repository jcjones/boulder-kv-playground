CREATE SCHEMA IF NOT EXISTS `ifn-boulder`;

USE `ifn-boulder`;


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

-- caaRecheckingAffectedSerials
CREATE TABLE IF NOT EXISTS `caaRecheckingAffectedSerials` (
  `serial` varchar(255) NOT NULL,
  PRIMARY KEY (`serial`)
) ENGINE=RocksDB DEFAULT CHARSET=utf8;


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
-- keyHashToSerial
CREATE TABLE IF NOT EXISTS `keyHashToSerial` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `keyHash` binary(32) NOT NULL,
  `certNotAfter` datetime NOT NULL,
  `certSerial` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_keyHash_certserial` (`keyHash`,`certSerial`),
  KEY `keyHash_certNotAfter` (`keyHash`,`certNotAfter`)
) ENGINE=RocksDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

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
) ENGINE=RocksDB DEFAULT CHARSET=utf8mb4
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
) ENGINE=RocksDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

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
) ENGINE=RocksDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4
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
