CREATE TABLE IF NOT EXISTS `admin_jail` (
  `citizenid` varchar(50) NOT NULL,
  `time` int(11) DEFAULT 0,
  `reason` text DEFAULT NULL,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;