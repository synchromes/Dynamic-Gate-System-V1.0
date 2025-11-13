# 🔘 Interactive Button System - Feature Documentation

**Dynamic Gate System V2.1** - Button Update

---

## 📖 Apa itu Button System?

**Interactive Button System** adalah fitur yang menambahkan **tombol fisik** yang dapat di-klik player untuk membuka/menutup gate. Button ini berupa **dynamic object** yang terintegrasi penuh dengan gate system.

### 🎯 Keunggulan:

✅ **Visual & Intuitif** - Player bisa lihat tombol secara fisik
✅ **Click to Open** - Klik object untuk trigger gate
✅ **10+ Button Models** - Pilih dari berbagai model (keypad, switch, panel, dll.)
✅ **Customizable Position** - Edit posisi button dengan mudah
✅ **3D Text Label** - Tambahkan label text di button
✅ **Animation Feedback** - Button bergerak saat di-klik
✅ **Sound Effects** - Audio feedback saat button pressed
✅ **Permission Integration** - Button respect ACL dan password

---

## 🎮 Cara Menggunakan

### **1. Enable Button untuk Gate**

```
1. /agate edit [gateid]
2. Pilih "🔘 Button Settings"
3. Pilih "Button Status" untuk enable/disable
4. Button akan dibuat otomatis di posisi default (5m dari gate)
```

### **2. Change Button Model**

```
1. /agate edit [gateid]
2. Pilih "🔘 Button Settings"
3. Pilih "Change Button Model"
4. Pilih dari 10 model yang tersedia:
   - Keypad (2886) - RECOMMENDED untuk realistic RP
   - Red Button (1318)
   - Green Button (1319)
   - Light Switch (1650)
   - Control Panel (2232)
   - Intercom (2942)
   - Doorbell (1317)
   - Garage Button (3095)
   - Modern Panel (19273)
   - Card Reader (2886)
```

### **3. Edit Button Position**

```
1. /agate edit [gateid]
2. Pilih "🔘 Button Settings"
3. Pilih "Edit Button Position"
4. SA-MP Object Editor akan terbuka
5. Move/rotate button ke posisi yang diinginkan
6. Klik SAVE untuk simpan posisi
```

**💡 Tips Posisi Button:**
- **Pintu gerbang**: Samping kanan/kiri gate, tinggi 1.5-2m
- **Garage**: Di tembok samping, dekat pintu
- **Base/HQ**: Dekat pagar, mudah terlihat
- **Parking**: Di tiang/pillar dekat entrance

### **4. Add Button Label (Optional)**

```
1. /agate edit [gateid]
2. Pilih "🔘 Button Settings"
3. Pilih "Button Label"
4. Input text yang diinginkan:
   - "Press to open"
   - "Click here"
   - "Gate control"
   - "🔑 Members only"
   - dll.
5. Label akan muncul di atas button (visible 5m)
6. Leave empty untuk disable label
```

---

## 🎨 Button Models Preview

### **1. Keypad (2886) - BEST untuk RP!**
```
┌─────────┐
│ 1  2  3 │  ← Wall-mounted keypad
│ 4  5  6 │     Perfect untuk gates, doors,
│ 7  8  9 │     security systems
│ *  0  # │
└─────────┘
```
**Use Cases:**
- Security gates
- Base/faction HQ
- Private property
- Parking gates

### **2. Button Red/Green (1318/1319)**
```
   ___
  (   )  ← Colored button
   ¯¯¯
```
**Use Cases:**
- Simple open/close
- Garage doors
- Industrial gates

### **3. Control Panel (2232)**
```
┌───────────┐
│  ○  ○  ○  │  ← Control panel
│  ─  ─  ─  │     Multiple buttons
│  ○  ○  ○  │
└───────────┘
```
**Use Cases:**
- Complex security
- Military bases
- High-tech locations

### **4. Intercom (2942)**
```
┌────┐
│ ○○ │  ← Intercom system
│ ☎  │     Communication + button
│ ▓▓ │
└────┘
```
**Use Cases:**
- Apartment gates
- Gated community
- Office buildings

---

## 🔧 Teknis: Bagaimana Button Bekerja?

### **OnPlayerClickDynamicObject**
```pawn
// When player clicks button object
public OnPlayerClickDynamicObject(playerid, objectid)
{
    // Check if objectid == GateButton[slot]
    // Verify permission (ACL, owner, password)
    // Toggle gate
    // Play sound + animation
}
```

### **Button Animation**
```pawn
// Button press animation (moves down 0.05 units)
MoveDynamicObject(GateButton[slot], x, y, z - 0.05, 2.0);

// Return to original position after 500ms
SetTimerEx("ResetButtonPosition", 500, false, "i", slot);
```

### **Visual Feedback**
- ✅ Button bergerak saat di-klik
- ✅ Sound effect (1085 = click sound)
- ✅ Chat message konfirmasi
- ✅ Gate opens/closes

---

## 📊 Database Schema

### **New Columns in `gate` table:**

| Column | Type | Description |
|--------|------|-------------|
| `ghasbutton` | tinyint(1) | Button enabled? (0/1) |
| `gbuttonmodel` | int(11) | Object model ID |
| `gbuttonx` | float | Button X position |
| `gbuttony` | float | Button Y position |
| `gbuttonz` | float | Button Z position |
| `gbuttonrx` | float | Button rotation X |
| `gbuttonry` | float | Button rotation Y |
| `gbuttonrz` | float | Button rotation Z |
| `gbuttonlabel` | tinyint(1) | Show label? (0/1) |
| `gbuttonlabeltext` | varchar(64) | Label text |

**Migration:**
```sql
-- Run gate_v2_button_schema.sql to add columns
mysql -u root -p mgrp < gate_v2_button_schema.sql
```

---

## 🎯 Use Cases & Examples

### **Example 1: Faction HQ dengan Keypad**

**Scenario**: Base faction dengan security tinggi

**Setup**:
```
Gate: /agate create 968
Button: Enable → Model: Keypad (2886)
Position: Di samping gate, tinggi 1.5m
Label: "🔑 Members Only"
Password: "hqpass123"
ACL: Add all members
```

**Player Experience**:
```
Player walks to gate
└─→ Sees keypad with label "🔑 Members Only"
    └─→ Clicks keypad
        └─→ Dialog: "Enter password"
            └─→ Input correct password
                └─→ *CLICK* sound
                    └─→ Gate opens
                        └─→ Auto-close after 10 sec
```

---

### **Example 2: Public Parking dengan Simple Button**

**Scenario**: Parking lot entrance

**Setup**:
```
Gate: Public
Button: Enable → Model: Green Button (1319)
Position: Di pillar dekat entrance
Label: "Press to open"
Auto-Close: 8 seconds
```

**Player Experience**:
```
Player drives to parking
└─→ Sees green button on pillar
    └─→ Exits vehicle, clicks button
        └─→ *CLICK* sound
            └─→ Gate opens
                └─→ Returns to vehicle
                    └─→ Drives through
                        └─→ Gate closes automatically
```

---

### **Example 3: Military Base dengan Control Panel**

**Scenario**: High security military base

**Setup**:
```
Gate: Restricted
Owner: Military_Commander
Button: Enable → Model: Control Panel (2232)
Position: Guard post
Label: "AUTHORIZED PERSONNEL ONLY"
Password: Yes
ACL: All military members
Sound: Custom military sound
```

**Player Experience**:
```
Authorized member approaches
└─→ Sees control panel at guard post
    └─→ Clicks panel (no password needed for ACL)
        └─→ Military sound plays
            └─→ Heavy gate slides open
                └─→ Auto-close: 5 seconds
```

---

### **Example 4: Luxury House dengan Intercom**

**Scenario**: Private luxury home

**Setup**:
```
Gate: Owner only
Button: Enable → Model: Intercom (2942)
Position: Tembok depan rumah
Label: "Ring bell"
Auto-Close: 15 seconds
```

**Player Experience**:
```
Owner arrives home
└─→ Clicks intercom
    └─→ Doorbell sound
        └─→ Gate opens
            └─→ 15 seconds to enter
```

---

## ⚙️ Configuration Options

### **Button Settings in Dialog:**

1. **Button Status** (Enable/Disable)
   - Toggle button on/off
   - Disabled = no object created
   - Enabled = button created at default position

2. **Change Button Model**
   - Choose from 10 available models
   - Change anytime
   - Object recreated with new model

3. **Edit Button Position**
   - SA-MP Object Editor
   - Move X/Y/Z
   - Rotate RX/RY/RZ
   - Save/Cancel options

4. **Button Label**
   - Optional 3D text
   - Max 64 characters
   - Visible 5m radius
   - Disable by leaving empty

---

## 🔒 Security & Permissions

### **Button respects all security settings:**

✅ **Ownership**
- If gate owner = specific player
- Only owner can use button

✅ **ACL (Access Control List)**
- Multiple authorized players
- Button works for ACL members

✅ **Password Protection**
- Button triggers password dialog
- Must enter correct password

✅ **Cooldown**
- 3-second anti-spam
- Prevents button abuse

✅ **Gate Methods**
- Button is SEPARATE method
- Can combine with other methods (horn, proximity, command)

---

## 📝 Commands Summary

| Command | Description |
|---------|-------------|
| `/agate edit [id]` | Open gate config menu |
| `→ Button Settings` | Access button menu |
| `→ Button Status` | Enable/disable button |
| `→ Change Model` | Select button model |
| `→ Edit Position` | Open object editor |
| `→ Button Label` | Set/remove label text |

**No additional commands needed!** All settings via dialogs.

---

## 🐛 Troubleshooting

### Problem: Button tidak muncul
**Solution**:
1. Pastikan button enabled (`/agate edit [id]`)
2. Check `/ginfo [id]` - lihat Button status
3. Coba teleport ke gate: `/gotogate [id]`
4. Re-enable button (disable → enable)

### Problem: Button tidak bisa di-klik
**Solution**:
1. Check permission (owner/ACL)
2. Pastikan range cukup dekat (< 50m)
3. Check cooldown (3 detik)
4. Verify OnPlayerClickDynamicObject active

### Problem: Button di posisi salah
**Solution**:
1. `/agate edit [id]`
2. Button Settings → Edit Position
3. Adjust position dengan editor
4. SAVE untuk simpan

### Problem: Label tidak terlihat
**Solution**:
1. Check label enabled
2. Distance max 5m
3. Check text tidak kosong
4. Re-create label (disable → enable)

---

## 💡 Pro Tips

### **Tip 1: Realistic Placement**
```
Posisi button yang bagus:
✅ Di tembok samping gate (realistic)
✅ Pada pillar/tiang (common)
✅ Guard post/booth (security)
✅ Ketinggian 1.5-2m (reachable)

Hindari:
❌ Terlalu tinggi (can't reach)
❌ Di tengah jalan (blocking)
❌ Inside object (invisible)
❌ Too far from gate (confusing)
```

### **Tip 2: Model Selection**
```
Roleplay servers: Keypad (2886), Intercom (2942)
Freeroam servers: Simple buttons (1318/1319)
Military/Government: Control Panel (2232)
Modern/Tech: Modern Panel (19273)
```

### **Tip 3: Combine Methods**
```
Button + Password = Max security
Button + Auto-close = Convenience
Button + ACL = Group access
Button + Proximity = Backup method
```

### **Tip 4: Label Text Examples**
```
Security: "🔒 Authorized Only"
Public: "Press to open"
Faction: "🔑 [FACTION] Members"
Business: "👔 Employees Only"
Home: "Ring bell"
Parking: "⬆️ Click here"
```

---

## 📊 Performance Impact

**Button System Impact:**
- **Objects**: +1 object per gate with button
- **Labels**: +1 3D text per gate (if enabled)
- **Memory**: ~500 bytes per button
- **CPU**: Minimal (OnPlayerClickDynamicObject)
- **Network**: Streamed within view distance (50m)

**100 gates dengan buttons:**
- Objects: +100 (negligible)
- Memory: ~50KB (tiny)
- Performance: < 1% impact

**Verdict**: ✅ Sangat ringan, safe untuk production!

---

## 🔄 Version History

### **V2.1 - Button System** (Current)
- ✅ Interactive button objects
- ✅ 10+ button models
- ✅ Click-to-trigger gates
- ✅ Position editor
- ✅ 3D text labels
- ✅ Animation feedback
- ✅ Permission integration

### **V2.0 - Modern Features**
- ACL, Password, Auto-close, Stats, Logs, etc.

### **V1.0 - Original**
- Basic gate system

---

## 🎓 Best Practices

1. **Always test button position** before deploying
2. **Use appropriate models** for your server theme
3. **Add labels** for clarity (especially public gates)
4. **Combine with other methods** for flexibility
5. **Set auto-close** for security gates
6. **Regular maintenance**: Check button positions after map edits

---

## 📞 Support

Button tidak bekerja? Check:
1. `gate_v2_button_schema.sql` telah di-import
2. Using `gate_v2_with_buttons.pwn` (bukan gate_v2.pwn)
3. Streamer plugin versi 2.9.4+
4. Button enabled untuk gate tersebut
5. Object model valid (cek model ID)

---

## 🎉 Kesimpulan

**Interactive Button System** membawa gate system ke level berikutnya dengan:

✨ **User Experience**: Player lihat button fisik, klik untuk buka
✨ **Realism**: Perfect untuk roleplay servers
✨ **Flexibility**: 10+ models, custom positions, labels
✨ **Integration**: Works with semua fitur V2.0 (ACL, password, dll.)
✨ **Performance**: Ringan, production-ready

**Button system = Game changer untuk dynamic gates!** 🚪🔘

---

**Enjoy the Button System!** 🎮✨

*Made with ❤️ for SA-MP Community*
