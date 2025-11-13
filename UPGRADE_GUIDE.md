# 📦 Upgrade Guide: V1.0 → V2.0

Panduan lengkap untuk upgrade Dynamic Gate System dari versi 1.0 ke 2.0 dengan aman.

---

## ⚠️ Sebelum Memulai

### 1. Backup Data Anda!
```bash
# Backup database
mysqldump -u root -p mgrp gate > gate_backup_v1.sql

# Backup filterscript
cp filterscripts/gate.amx filterscripts/gate.amx.backup
```

### 2. Cek Versi Anda
Jika Anda menggunakan Dynamic Gate System V1.0 (gate.pwn original), ikuti panduan ini.

---

## 🔄 Metode Upgrade

Ada 2 metode upgrade:

### Metode 1: Fresh Install (Recommended)
**Pros**: Bersih, tidak ada konflik
**Cons**: Harus recreate semua gate

### Metode 2: In-Place Upgrade
**Pros**: Keep existing gates
**Cons**: Butuh manual migration

---

## 📝 Metode 1: Fresh Install

### Step 1: Unload Old Filterscript
Edit `server.cfg`:
```
# OLD
filterscripts gate

# NEW
filterscripts gate_v2
```

### Step 2: Backup & Drop Old Table
```sql
-- Backup old gates
CREATE TABLE gate_backup_v1 AS SELECT * FROM gate;

-- Drop old table (ONLY if you backed up!)
DROP TABLE gate;
```

### Step 3: Install V2.0
```sql
-- Import new schema
mysql -u root -p mgrp < gate_v2.sql
```

### Step 4: Install Filterscript
1. Copy `gate_v2.amx` to `filterscripts/`
2. Configure MySQL credentials in `gate_v2.pwn`
3. Compile: `pawncc gate_v2.pwn`
4. Restart server

### Step 5: Recreate Gates
Use `/agate create` to recreate your gates with new features!

---

## 🔧 Metode 2: In-Place Upgrade (Keep Existing Gates)

### Step 1: Backup
```sql
-- Full backup
mysqldump -u root -p mgrp gate > gate_backup.sql
```

### Step 2: Add New Columns
```sql
-- Run this SQL to add new columns to existing table
USE mgrp;

ALTER TABLE `gate`
  ADD COLUMN `gpassword` varchar(24) NOT NULL DEFAULT '' AFTER `gopenrz`,
  ADD COLUMN `gautoclose` int(11) NOT NULL DEFAULT 0 AFTER `gpassword`,
  ADD COLUMN `gopencount` int(11) NOT NULL DEFAULT 0 AFTER `gautoclose`,
  ADD COLUMN `gclosecount` int(11) NOT NULL DEFAULT 0 AFTER `gopencount`,
  ADD COLUMN `glastusedat` int(11) NOT NULL DEFAULT 0 AFTER `gclosecount`,
  ADD COLUMN `gsoundid` int(11) NOT NULL DEFAULT 0 AFTER `glastusedat`,
  ADD COLUMN `gcreatedat` timestamp NOT NULL DEFAULT current_timestamp() AFTER `gsoundid`,
  ADD COLUMN `gupdatedat` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `gcreatedat`;

-- Add indexes for performance
ALTER TABLE `gate`
  ADD KEY `idx_owner` (`gowner`,`gownername`),
  ADD KEY `idx_status` (`gstatus`);
```

### Step 3: Create New Tables
```sql
-- Create ACL table
CREATE TABLE IF NOT EXISTS `gate_acl` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gid` int(11) NOT NULL,
  `playername` varchar(24) NOT NULL,
  `addedat` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_gid` (`gid`),
  KEY `idx_playername` (`playername`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create logs table
CREATE TABLE IF NOT EXISTS `gate_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gid` int(11) NOT NULL,
  `playername` varchar(24) NOT NULL,
  `action` varchar(64) NOT NULL,
  `details` text DEFAULT NULL,
  `createdat` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_gid` (`gid`),
  KEY `idx_createdat` (`createdat`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create admins table (optional)
CREATE TABLE IF NOT EXISTS `gate_admins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playername` varchar(24) NOT NULL,
  `adminlevel` int(11) NOT NULL DEFAULT 0,
  `grantedat` timestamp NOT NULL DEFAULT current_timestamp(),
  `grantedby` varchar(24) NOT NULL DEFAULT 'System',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_playername` (`playername`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Step 4: Verify Migration
```sql
-- Check if new columns exist
DESCRIBE gate;

-- Check if new tables exist
SHOW TABLES LIKE 'gate_%';

-- Verify existing data
SELECT gid, gmodel, gowner, gownername FROM gate LIMIT 10;
```

### Step 5: Update Filterscript
1. Remove `gate.amx` from filterscripts
2. Copy `gate_v2.amx` to filterscripts
3. Edit `server.cfg`:
   ```
   filterscripts gate_v2
   ```
4. Configure MySQL password in `gate_v2.pwn`
5. Restart server

### Step 6: Test
```
/rcon gmx  # Restart gamemode
/agate     # Check if command works
/glist     # Verify all gates loaded
/ginfo 0   # Check first gate info
```

---

## 🔍 Verification Checklist

After upgrade, verify:

- [ ] All existing gates loaded correctly (`/glist`)
- [ ] Gate positions are correct (`/gotogate [id]`)
- [ ] Gate open/close works
- [ ] Owner validation works (exact match)
- [ ] Admin commands require permission
- [ ] New features accessible (password, ACL, etc.)
- [ ] No errors in `server_log.txt`
- [ ] No errors in MySQL logs

---

## 🐛 Common Upgrade Issues

### Issue 1: "Column already exists" error
**Cause**: You're running ALTER TABLE on already upgraded database

**Solution**:
```sql
-- Check if column exists first
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'gate' AND COLUMN_NAME = 'gpassword';

-- If exists, skip that column
```

### Issue 2: Gates not loading
**Cause**: MySQL connection failed or schema mismatch

**Solution**:
1. Check `server_log.txt`
2. Verify MySQL credentials
3. Run `DESCRIBE gate;` to check schema
4. Check if all required columns exist

### Issue 3: Admin commands not working
**Cause**: No admin level set

**Solution**:
```
# In-game as RCON admin:
/setadmin [your_id] 3
```

### Issue 4: Duplicate gates after upgrade
**Cause**: Both old and new filterscript loaded

**Solution**:
```
# In server.cfg, remove duplicate:
filterscripts gate_v2  # NOT: gate gate_v2
```

---

## 📊 Feature Comparison

| Feature | V1.0 | V2.0 |
|---------|------|------|
| Basic Gate Management | ✅ | ✅ |
| MySQL Integration | ✅ | ✅ |
| Multiple Detection Methods | ✅ | ✅ |
| Admin Permission System | ❌ | ✅ |
| Owner Validation Security | ❌ | ✅ |
| Password Protection | ❌ | ✅ |
| Access Control List | ❌ | ✅ |
| Auto-Close Timer | ❌ | ✅ |
| Statistics Tracking | ❌ | ✅ |
| Activity Logging | ❌ | ✅ |
| Sound Effects | ❌ | ✅ |
| Anti-Spam Cooldown | ❌ | ✅ |
| Auto-Save System | ❌ | ✅ |
| Dynamic Areas | ❌ | ✅ |
| Performance Optimized | ❌ | ✅ |

---

## 💡 Post-Upgrade Tips

### 1. Configure Important Settings
Edit `gate_v2.pwn`:
```pawn
#define MYSQL_PASSWORD "your_strong_password"  // Change this!
#define GATE_COOLDOWN_TIME 3000                // Adjust if needed
#define GATE_SAVE_INTERVAL 300000              // 5 minutes default
```

### 2. Set Up Admin Levels
```
/setadmin [mod_id] 2    # Moderator
/setadmin [admin_id] 3  # Admin
```

### 3. Review Existing Gates
```
/glist              # List all gates
/ginfo [id]         # Check each gate
/agate edit [id]    # Update configurations
```

### 4. Add New Features
For important gates, consider:
- Adding password protection
- Setting up ACL for authorized players
- Configuring auto-close timer
- Adjusting detection methods

### 5. Monitor Performance
```
# Check server logs regularly
tail -f server_log.txt

# Monitor MySQL slow queries
# Enable MySQL slow query log
```

---

## 🔙 Rollback Plan

If something goes wrong, you can rollback:

### Step 1: Stop Server
```bash
./samp03svr stop
```

### Step 2: Restore Database
```bash
# Restore from backup
mysql -u root -p mgrp < gate_backup_v1.sql
```

### Step 3: Restore Filterscript
```bash
# Restore old filterscript
cp filterscripts/gate.amx.backup filterscripts/gate.amx
```

### Step 4: Update server.cfg
```
filterscripts gate
```

### Step 5: Restart Server
```bash
./samp03svr start
```

---

## 📞 Need Help?

If you encounter issues during upgrade:

1. **Check Logs**:
   - `server_log.txt`
   - `mysql_log.txt`
   - MySQL error logs

2. **Common Solutions**:
   - Verify MySQL credentials
   - Check plugin versions
   - Ensure all includes are present
   - Verify file permissions

3. **Still Stuck?**:
   - Create an issue on GitHub
   - Provide logs and error messages
   - Describe what you've tried

---

## ✅ Upgrade Complete!

If all checks passed, congratulations! You're now running Dynamic Gate System V2.0 with:

- 🔒 Enhanced security
- 🐛 Bug fixes
- ⚡ Better performance
- 🎨 10+ new features
- 📝 Activity logging
- 🛡️ Admin system
- 📊 Statistics tracking

**Enjoy the new features!** 🎉

---

## 📋 Quick Migration Script

For advanced users, here's a complete migration script:

```sql
-- ========================================
-- Dynamic Gate System V1.0 → V2.0
-- Complete Migration Script
-- ========================================

USE mgrp;

-- Backup existing data
CREATE TABLE IF NOT EXISTS gate_backup_v1 AS SELECT * FROM gate;

-- Add new columns
ALTER TABLE `gate`
  ADD COLUMN IF NOT EXISTS `gpassword` varchar(24) NOT NULL DEFAULT '' AFTER `gopenrz`,
  ADD COLUMN IF NOT EXISTS `gautoclose` int(11) NOT NULL DEFAULT 0 AFTER `gpassword`,
  ADD COLUMN IF NOT EXISTS `gopencount` int(11) NOT NULL DEFAULT 0 AFTER `gautoclose`,
  ADD COLUMN IF NOT EXISTS `gclosecount` int(11) NOT NULL DEFAULT 0 AFTER `gopencount`,
  ADD COLUMN IF NOT EXISTS `glastusedat` int(11) NOT NULL DEFAULT 0 AFTER `gclosecount`,
  ADD COLUMN IF NOT EXISTS `gsoundid` int(11) NOT NULL DEFAULT 0 AFTER `glastusedat`,
  ADD COLUMN IF NOT EXISTS `gcreatedat` timestamp NOT NULL DEFAULT current_timestamp() AFTER `gsoundid`,
  ADD COLUMN IF NOT EXISTS `gupdatedat` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `gcreatedat`;

-- Add indexes
ALTER TABLE `gate`
  ADD KEY IF NOT EXISTS `idx_owner` (`gowner`,`gownername`),
  ADD KEY IF NOT EXISTS `idx_status` (`gstatus`);

-- Create new tables
CREATE TABLE IF NOT EXISTS `gate_acl` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gid` int(11) NOT NULL,
  `playername` varchar(24) NOT NULL,
  `addedat` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_gid` (`gid`),
  KEY `idx_playername` (`playername`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gate_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gid` int(11) NOT NULL,
  `playername` varchar(24) NOT NULL,
  `action` varchar(64) NOT NULL,
  `details` text DEFAULT NULL,
  `createdat` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_gid` (`gid`),
  KEY `idx_createdat` (`createdat`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gate_admins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playername` varchar(24) NOT NULL,
  `adminlevel` int(11) NOT NULL DEFAULT 0,
  `grantedat` timestamp NOT NULL DEFAULT current_timestamp(),
  `grantedby` varchar(24) NOT NULL DEFAULT 'System',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_playername` (`playername`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verify
SELECT 'Migration Complete!' as Status;
SELECT COUNT(*) as TotalGates FROM gate;
SELECT 'Check new columns:' as Info;
DESCRIBE gate;
```

Save as `migrate_v1_to_v2.sql` and run:
```bash
mysql -u root -p mgrp < migrate_v1_to_v2.sql
```

---

**Happy Upgrading! 🚀**
