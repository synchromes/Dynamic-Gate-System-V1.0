-- ============================================================================
-- Dynamic Gate System V2.0 - Enhanced Database Schema
-- ============================================================================
-- This schema includes all new features:
-- - Password protection
-- - Auto-close timers
-- - Statistics tracking (open/close counts)
-- - Access Control List support (via separate table)
-- - Activity logging
-- ============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mgrp`
--

-- --------------------------------------------------------

--
-- Table structure for table `gate`
-- ✅ ENHANCED: Added new columns for modern features
--

CREATE TABLE IF NOT EXISTS `gate` (
  `gid` int(11) NOT NULL,
  `gstatus` int(11) NOT NULL DEFAULT 0,
  `gmodel` int(11) NOT NULL,
  `gspeed` float NOT NULL DEFAULT 3.0,
  `grange` float NOT NULL DEFAULT 10.0,
  `gowner` int(11) NOT NULL DEFAULT 0,
  `gownername` varchar(24) NOT NULL DEFAULT '',

  -- Detection methods
  `gmcmd` int(11) NOT NULL DEFAULT 0,
  `gmhorn` int(11) NOT NULL DEFAULT 0,
  `gmfoot` int(11) NOT NULL DEFAULT 0,
  `gmveh` int(11) NOT NULL DEFAULT 0,

  -- Position data (closed)
  `gclosex` float NOT NULL,
  `gclosey` float NOT NULL,
  `gclosez` float NOT NULL,
  `gcloserx` float NOT NULL DEFAULT 0.0,
  `gclosery` float NOT NULL DEFAULT 0.0,
  `gcloserz` float NOT NULL DEFAULT 0.0,

  -- Position data (open)
  `gopenx` float NOT NULL DEFAULT 0.0,
  `gopeny` float NOT NULL DEFAULT 0.0,
  `gopenz` float NOT NULL DEFAULT 0.0,
  `gopenrx` float NOT NULL DEFAULT 0.0,
  `gopenry` float NOT NULL DEFAULT 0.0,
  `gopenrz` float NOT NULL DEFAULT 0.0,

  -- ✅ NEW FEATURES
  `gpassword` varchar(24) NOT NULL DEFAULT '' COMMENT 'Gate password for protection',
  `gautoclose` int(11) NOT NULL DEFAULT 0 COMMENT 'Auto-close time in seconds (0=disabled)',
  `gopencount` int(11) NOT NULL DEFAULT 0 COMMENT 'Statistics: Total times gate opened',
  `gclosecount` int(11) NOT NULL DEFAULT 0 COMMENT 'Statistics: Total times gate closed',
  `glastusedat` int(11) NOT NULL DEFAULT 0 COMMENT 'Unix timestamp of last use',
  `gsoundid` int(11) NOT NULL DEFAULT 0 COMMENT 'Custom sound ID (0=default)',
  `gcreatedat` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Gate creation timestamp',
  `gupdatedat` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Main gate data table';

-- --------------------------------------------------------

--
-- ✅ NEW TABLE: Access Control List (ACL)
-- Allows multiple players to access a single gate
--

CREATE TABLE IF NOT EXISTS `gate_acl` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gid` int(11) NOT NULL COMMENT 'Gate ID reference',
  `playername` varchar(24) NOT NULL COMMENT 'Player name with access',
  `addedat` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When access was granted',
  PRIMARY KEY (`id`),
  KEY `idx_gid` (`gid`),
  KEY `idx_playername` (`playername`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Gate Access Control List';

-- --------------------------------------------------------

--
-- ✅ NEW TABLE: Activity Logs
-- Track all gate activities (opens, closes, edits)
--

CREATE TABLE IF NOT EXISTS `gate_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gid` int(11) NOT NULL COMMENT 'Gate ID reference',
  `playername` varchar(24) NOT NULL COMMENT 'Player who performed action',
  `action` varchar(64) NOT NULL COMMENT 'Action type (opened, closed, edited, etc)',
  `details` text DEFAULT NULL COMMENT 'Additional details (JSON format)',
  `createdat` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When action occurred',
  PRIMARY KEY (`id`),
  KEY `idx_gid` (`gid`),
  KEY `idx_createdat` (`createdat`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Gate activity logs';

-- --------------------------------------------------------

--
-- ✅ NEW TABLE: Player Admin Levels (Optional)
-- Store player admin levels for gate management
-- Note: You can integrate this with your existing user system
--

CREATE TABLE IF NOT EXISTS `gate_admins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playername` varchar(24) NOT NULL COMMENT 'Player name',
  `adminlevel` int(11) NOT NULL DEFAULT 0 COMMENT 'Admin level (0-3)',
  `grantedat` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When admin was granted',
  `grantedby` varchar(24) NOT NULL DEFAULT 'System' COMMENT 'Who granted the admin',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_playername` (`playername`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Gate admin permissions';

-- --------------------------------------------------------

--
-- Indexes for table `gate`
--

ALTER TABLE `gate`
  ADD PRIMARY KEY (`gid`),
  ADD KEY `idx_owner` (`gowner`,`gownername`),
  ADD KEY `idx_status` (`gstatus`);

-- --------------------------------------------------------

--
-- ✅ MIGRATION GUIDE for existing installations:
-- If you're upgrading from V1.0, run these ALTER TABLE commands:
--

/*
-- Add new columns to existing gate table
ALTER TABLE `gate`
  ADD COLUMN `gpassword` varchar(24) NOT NULL DEFAULT '' AFTER `gopenrz`,
  ADD COLUMN `gautoclose` int(11) NOT NULL DEFAULT 0 AFTER `gpassword`,
  ADD COLUMN `gopencount` int(11) NOT NULL DEFAULT 0 AFTER `gautoclose`,
  ADD COLUMN `gclosecount` int(11) NOT NULL DEFAULT 0 AFTER `gopencount`,
  ADD COLUMN `glastusedat` int(11) NOT NULL DEFAULT 0 AFTER `gclosecount`,
  ADD COLUMN `gsoundid` int(11) NOT NULL DEFAULT 0 AFTER `glastusedat`,
  ADD COLUMN `gcreatedat` timestamp NOT NULL DEFAULT current_timestamp() AFTER `gsoundid`,
  ADD COLUMN `gupdatedat` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `gcreatedat`;

-- Add indexes for better performance
ALTER TABLE `gate`
  ADD KEY `idx_owner` (`gowner`,`gownername`),
  ADD KEY `idx_status` (`gstatus`);
*/

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- ============================================================================
-- Installation Complete!
-- ============================================================================
-- Next steps:
-- 1. Import this SQL file to your MySQL database
-- 2. Update MySQL credentials in gate_v2.pwn (lines 105-108)
-- 3. Compile gate_v2.pwn
-- 4. Add "gate_v2" to filterscripts in server.cfg
-- 5. Restart your server
-- ============================================================================
