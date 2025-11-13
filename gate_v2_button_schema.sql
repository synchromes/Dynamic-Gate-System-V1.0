-- ============================================================================
-- Dynamic Gate System V2.1 - Button System Database Schema
-- ============================================================================
-- This adds button support to existing V2.0 installation
-- ============================================================================

USE mgrp;

-- Add button columns to existing gate table
ALTER TABLE `gate`
  ADD COLUMN IF NOT EXISTS `ghasbutton` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Button enabled?' AFTER `gupdatedat`,
  ADD COLUMN IF NOT EXISTS `gbuttonmodel` int(11) NOT NULL DEFAULT 2886 COMMENT 'Button object model ID' AFTER `ghasbutton`,
  ADD COLUMN IF NOT EXISTS `gbuttonx` float NOT NULL DEFAULT 0.0 COMMENT 'Button X position' AFTER `gbuttonmodel`,
  ADD COLUMN IF NOT EXISTS `gbuttony` float NOT NULL DEFAULT 0.0 COMMENT 'Button Y position' AFTER `gbuttonx`,
  ADD COLUMN IF NOT EXISTS `gbuttonz` float NOT NULL DEFAULT 0.0 COMMENT 'Button Z position' AFTER `gbuttony`,
  ADD COLUMN IF NOT EXISTS `gbuttonrx` float NOT NULL DEFAULT 0.0 COMMENT 'Button RX rotation' AFTER `gbuttonz`,
  ADD COLUMN IF NOT EXISTS `gbuttonry` float NOT NULL DEFAULT 0.0 COMMENT 'Button RY rotation' AFTER `gbuttonrx`,
  ADD COLUMN IF NOT EXISTS `gbuttonrz` float NOT NULL DEFAULT 0.0 COMMENT 'Button RZ rotation' AFTER `gbuttonry`,
  ADD COLUMN IF NOT EXISTS `gbuttonlabel` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Show label?' AFTER `gbuttonrz`,
  ADD COLUMN IF NOT EXISTS `gbuttonlabeltext` varchar(64) NOT NULL DEFAULT '' COMMENT 'Button label text' AFTER `gbuttonlabel`;

-- Add index for button queries
ALTER TABLE `gate`
  ADD KEY IF NOT EXISTS `idx_hasbutton` (`ghasbutton`);

-- Sample data - Enable button for gate ID 0 (if exists)
-- UPDATE `gate` SET
--   `ghasbutton` = 1,
--   `gbuttonmodel` = 2886,
--   `gbuttonx` = 0.0,
--   `gbuttony` = 0.0,
--   `gbuttonz` = 0.0,
--   `gbuttonlabel` = 1,
--   `gbuttonlabeltext` = 'Press to open'
-- WHERE `gid` = 0;

-- ============================================================================
-- Installation Complete!
-- ============================================================================
-- Button models available:
--   2886 - Keypad (wall mounted) - RECOMMENDED
--   1318 - Red button
--   1319 - Green button
--   1650 - Light switch
--   2232 - Control panel
--   2942 - Intercom
--   1317 - Doorbell
--   3095 - Garage button
--   19273 - Modern panel
-- ============================================================================
