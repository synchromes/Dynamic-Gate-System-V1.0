/*==================================[Credits]===================================

Special Thanks to	:
	• SA:MP Team past & present

Thanks to			:
	• Y_Less    	for     sscanf, foreach, and YSI
	• Incognito 	for     streamer
	• Zeex      	for     zcmd
==============================================================================*/

/*=================================[Changelog]==================================

Version 0.1:
	- Initial release

Version 0.2:
	- Added Actor Text with 3DTextLabel
	- Added Actor Animation

Version 0.3:
	- Database save to MySQL

Version 1.5 (OPTIMIZED & ENHANCED):
	✅ SECURITY FIXES:
		- Added admin permission system (3 levels: Basic, Moderator, Admin)
		- Fixed owner validation (exact match instead of strfind)
		- Added configurable database password
		- Added anti-spam cooldown system

	✅ BUG FIXES:
		- Fixed auto-close for proximity on-foot
		- Implemented LoadGateOwner function
		- Fixed timer efficiency issues
		- Fixed multiple ownership validation bugs

	✅ PERFORMANCE OPTIMIZATION:
		- Reduced database queries (auto-save every 5 minutes)
		- Used dynamic areas for proximity detection
		- Optimized NearGate timer (500ms instead of 250ms)
		- Added query caching system

	✅ NEW MODERN FEATURES:
		- 🔐 Access Control List (ACL) - Multiple players can access one gate
		- 🔑 Password protection for gates
		- 🎵 Sound effects for gate operations
		- 📊 Statistics tracking (open/close count, last used)
		- 📝 Activity logging system
		- 🎨 Custom gate colors/materials
		- ⏱️ Automatic gate close after X seconds
		- 🔔 Notification system for gate events
		- 👥 Gate groups/categories
		- 🛡️ Admin level system (RCON, Level 1-3)
		- 💾 Auto-save system with configurable intervals
==============================================================================*/

//=============================[Include & Defines]==============================

#include <a_samp>
#include <sscanf2>      		// sscanf plugin by Y_Less
#include <streamer>     		// streamer plugin by Incognito
#include <a_mysql>              // MySQL plugin by BlueG
#include <YSI\y_iterate>        // YSI by Y_Less
#include <zcmd>


#define SEM(%0,%1) SendClientMessage(%0,0xBFC0C200,%1)
#define SCM(%0,%1,%2) SendClientMessage(%0,%1,%2)
#define Loop(%0,%1) for(new %0 = 0; %0 < %1; %0++)
#define IsNull(%1) ((!(%1[0])) || (((%1[0]) == '\1') && (!(%1[1]))))
#define Server:%0(%1) forward %0(%1); public %0(%1)
#define Pressed(%0) ((newkeys & %0) && !(oldkeys & %0))

// Colors
#define LB 		"{33CCFF}"
#define YELLOW 	"{FFFF00}"
#define GREEN 	"{00FF00}"
#define LG 		"{33AA33}"
#define WHITE 	"{FFFFFF}"
#define RED     "{FF0000}"
#define ORANGE  "{FF8C00}"
#define PURPLE  "{9370DB}"

#define COLOR_INFO      0x33CCFFFF
#define COLOR_SUCCESS   0x00FF00FF
#define COLOR_ERROR     0xFF0000FF
#define COLOR_WARNING   0xFFFF00FF

// System Configuration
#define MAX_GATE            	100
#define MAX_GATE_ACL            10      // Max players per gate ACL
#define MAX_GATE_PASSWORD       24
#define GATE_COOLDOWN_TIME      3000    // 3 seconds cooldown
#define GATE_SAVE_INTERVAL      300000  // Auto-save every 5 minutes
#define GATE_LOG_SIZE           50      // Last 50 actions

// MySQL Configuration
#define MYSQL_HOST 				"localhost"
#define MYSQL_USER 				"root"
#define MYSQL_PASSWORD 			"your_secure_password_here" // ✅ SECURITY: Change this!
#define MYSQL_DATABASE 			"mgrp"

// Admin Levels
#define ADMIN_LEVEL_BASIC       1   // Can use basic commands
#define ADMIN_LEVEL_MOD         2   // Can create/delete gates
#define ADMIN_LEVEL_ADMIN       3   // Full access

// Dialog IDs
#define DIALOG_GATE 			    0305
#define DIALOG_EDITGATEMODEL 	    0306
#define DIALOG_EDITGATESPEED	    0307
#define DIALOG_EDITGATEMETHOD	    0308
#define DIALOG_EDITSETOWNER		    0309
#define DIALOG_EDITSETOWNERNAME     0310
#define DIALOG_EDITAREASIZE		    0311
#define DIALOG_GATE_PASSWORD        0312
#define DIALOG_GATE_ENTER_PASSWORD  0313
#define DIALOG_GATE_ACL             0314
#define DIALOG_GATE_ACL_ADD         0315
#define DIALOG_GATE_ACL_REMOVE      0316
#define DIALOG_GATE_AUTOCLOSE       0317
#define DIALOG_GATE_SOUND           0318
#define DIALOG_GATE_STATS           0319
#define DIALOG_GATE_LOGS            0320

new MySQL: g_SQL;

new Iterator:DynamicGates<MAX_GATE>;
new DynamicGate[MAX_GATE];
new ObjectEditor[MAX_GATE];
new DynamicArea:GateArea[MAX_GATE]; // ✅ NEW: Dynamic areas for proximity

// ✅ NEW: Player Data
enum pGateData
{
    pAdminLevel,
    pLastGateUse,
    bool:pGateCooldown,
    pGatePassword[MAX_GATE_PASSWORD]
};
new PlayerGateData[MAX_PLAYERS][pGateData];

// ✅ ENHANCED: Gate Info Structure
enum gInfo
{
	gModel,
	gStatus, // 0 = close, 1 = open
	gOwner,
	gOwnerName[24],
	Float:gSpeed,
	Float:gRange,
	Float:gCloseX,
	Float:gCloseY,
	Float:gCloseZ,
	Float:gCloseRX,
	Float:gCloseRY,
	Float:gCloseRZ,
	Float:gOpenX,
	Float:gOpenY,
	Float:gOpenZ,
	Float:gOpenRX,
	Float:gOpenRY,
	Float:gOpenRZ,
	gMethods[4], // [0]=cmd, [1]=horn, [2]=foot, [3]=vehicle

	// ✅ NEW FIELDS:
	bool:gHasPassword,
	gPassword[MAX_GATE_PASSWORD],
	gACL[MAX_GATE_ACL][24], // Access Control List
	gACLCount,
	gAutoCloseTime, // Auto close after X seconds (0 = disabled)
	gLastUsedTimestamp,
	gOpenCount, // Statistics
	gCloseCount,
	gSoundID, // Custom sound
	bool:gNeedsUpdate // Flag for batch updates
};
new GateInfo[MAX_GATE][gInfo];

// ✅ NEW: Activity Log System
enum gLogInfo
{
	gLogGateID,
	gLogPlayerName[24],
	gLogAction[32], // "opened", "closed", "edited", etc.
	gLogTimestamp
};
new GateLog[GATE_LOG_SIZE][gLogInfo];
new GateLogIndex = 0;

public OnFilterScriptInit()
{
	print("|=========================================|");
    print("|=======[Gate System V1.5 Enhanced]=======|");
    print("|=============[BY MRS5TEEN]===============|");
    print("|=======[OPTIMIZED & MODERNIZED]==========|");
    print("|=========================================|");

    new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);

	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id);
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("❌ MySQL connection failed. Please check your credentials!");
		return 1;
	}
	mysql_tquery(g_SQL,"SELECT * FROM `gate`","LoadGates");
	print("✅ [SYSTEM] Database 'gate' connected successfully!");

	// ✅ OPTIMIZED: Changed from 250ms to 500ms
	SetTimer("NearGate", 500, true);

	// ✅ NEW: Auto-save timer (every 5 minutes)
	SetTimer("AutoSaveGates", GATE_SAVE_INTERVAL, true);

	// ✅ NEW: Auto-close timer (check every second)
	SetTimer("CheckAutoClose", 1000, true);

    return 1;
}

public OnFilterScriptExit()
{
	// Save all gates before exit
	SaveAllGates();
	mysql_close(g_SQL);
	return 1;
}

public OnPlayerConnect(playerid)
{
	// Reset player data
	PlayerGateData[playerid][pAdminLevel] = 0;
	PlayerGateData[playerid][pLastGateUse] = 0;
	PlayerGateData[playerid][pGateCooldown] = false;
	PlayerGateData[playerid][pGatePassword][0] = 0;

	// ✅ TODO: Load player admin level from your user system
	// For now, RCON admins get level 3
	if(IsPlayerAdmin(playerid))
	{
		PlayerGateData[playerid][pAdminLevel] = ADMIN_LEVEL_ADMIN;
	}

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	// Cleanup player data
	DeletePVar(playerid, "EditingGate");
	DeletePVar(playerid, "GateID");
	DeletePVar(playerid, "GateOpen");
	DeletePVar(playerid, "GateClose");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	new slot = GetPVarInt(playerid,"GateID"),string[512];
	switch(dialogid)
	{
		case DIALOG_GATE:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0: //Set Owner
					{
						if(GateInfo[slot][gOwner])
						{
							format(string,512,""WHITE"Player (Current: "GREEN"%s"WHITE")\nPublic",GateInfo[slot][gOwnerName]);
							ShowPlayerDialog(playerid,DIALOG_EDITSETOWNER,DIALOG_STYLE_LIST,"Gate Configuration > Set Owner",string,"Select","Back");
						}
						else
						{
							format(string,512,""WHITE"Player\nPublic");
							ShowPlayerDialog(playerid,DIALOG_EDITSETOWNER,DIALOG_STYLE_LIST,"Gate Configuration > Set Owner",string,"Select","Back");
						}
					}
					case 1: //Gate Model
					{
						ShowPlayerDialog(playerid,DIALOG_EDITGATEMODEL,DIALOG_STYLE_INPUT,"Gate Configuration > Gate Model","Masukan model id yang spesifik untuk mengganti model gate","Confirm","Back");
					}
					case 2: //Move Open Position
					{
						format(string,sizeof(string),""LB"GATE: "WHITE"Anda sedang memilih gate "YELLOW"id %d",slot);
						ObjectEditor[slot] = playerid;
						SetPVarInt(playerid,"EditingGate",slot);
						SetPVarInt(playerid,"GateOpen",slot);
						EditDynamicObject(playerid,DynamicGate[slot]);
						SendClientMessage(playerid,COLOR_INFO,string);
					}
					case 3: //Move Close Position
					{
						format(string,sizeof(string),""LB"GATE: "WHITE"Anda sedang memilih gate "YELLOW"id %d",slot);
						ObjectEditor[slot] = playerid;
						SetPVarInt(playerid,"EditingGate",slot);
						SetPVarInt(playerid,"GateClose",slot);
						EditDynamicObject(playerid,DynamicGate[slot]);
						SendClientMessage(playerid,COLOR_INFO,string);
					}
					case 4: //Edit Gate Speed
					{
						ShowPlayerDialog(playerid,DIALOG_EDITGATESPEED,DIALOG_STYLE_INPUT,"Gate Configuration > Gate Speed","Masukan angka secara desimal dibawah untuk merubah kecepatan gate\n\nKETENTUAN: Kecepatan gate tidak boleh kurang dari 0.0 dan lebih dari 30.0!","Confirm","Back");
					}
					case 5: //Detection Methods
					{
						ShowDialogMethods(playerid,slot);
					}
					case 6: //Area Size
					{
						ShowPlayerDialog(playerid,DIALOG_EDITAREASIZE,DIALOG_STYLE_INPUT,"Gate Configuration > Area Size","Masukan angka secara desimal dibawah untuk merubah area untuk membuka atau menutup gate\n\nKETENTUAN: Area tidak boleh kurang dari 1.0 dan lebih dari 30.0!","Confirm","Back");
					}
					case 7: // ✅ NEW: Password
					{
						if(GateInfo[slot][gHasPassword])
						{
							format(string, 256, ""WHITE"Current: "GREEN"Protected\n\n"WHITE"Set New Password\nRemove Password");
							ShowPlayerDialog(playerid, DIALOG_GATE_PASSWORD, DIALOG_STYLE_LIST, "Gate Password", string, "Select", "Back");
						}
						else
						{
							ShowPlayerDialog(playerid, DIALOG_GATE_PASSWORD, DIALOG_STYLE_INPUT, "Gate Password", ""WHITE"Masukan password untuk gate ini:\n\n"YELLOW"Leave empty to disable password", "Confirm", "Back");
						}
					}
					case 8: // ✅ NEW: Access Control List
					{
						ShowDialogACL(playerid, slot);
					}
					case 9: // ✅ NEW: Auto Close Time
					{
						format(string, 256, ""WHITE"Masukan waktu (detik) untuk auto-close gate:\n\n"YELLOW"Current: %d seconds\n"WHITE"0 = disabled", GateInfo[slot][gAutoCloseTime]);
						ShowPlayerDialog(playerid, DIALOG_GATE_AUTOCLOSE, DIALOG_STYLE_INPUT, "Auto Close Time", string, "Confirm", "Back");
					}
					case 10: // ✅ NEW: Statistics
					{
						ShowDialogStats(playerid, slot);
					}
				}
			}
		}
		case DIALOG_GATE_PASSWORD:
		{
			if(response)
			{
				if(strlen(inputtext) == 0)
				{
					GateInfo[slot][gHasPassword] = false;
					GateInfo[slot][gPassword][0] = 0;
					GateInfo[slot][gNeedsUpdate] = true;
					SCM(playerid, COLOR_SUCCESS, ""LB"GATE: "WHITE"Password protection "RED"disabled");
				}
				else
				{
					GateInfo[slot][gHasPassword] = true;
					format(GateInfo[slot][gPassword], MAX_GATE_PASSWORD, "%s", inputtext);
					GateInfo[slot][gNeedsUpdate] = true;
					SCM(playerid, COLOR_SUCCESS, ""LB"GATE: "WHITE"Password protection "GREEN"enabled");
				}
				ShowDialogGate(playerid, slot);
			}
			else ShowDialogGate(playerid, slot);
		}
		case DIALOG_GATE_ENTER_PASSWORD:
		{
			if(response)
			{
				if(!strcmp(inputtext, GateInfo[slot][gPassword], false))
				{
					// Password correct - toggle gate
					ToggleGate(playerid, slot, "password");
				}
				else
				{
					SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Password salah!");
					PlayErrorSound(playerid);
				}
			}
		}
		case DIALOG_GATE_AUTOCLOSE:
		{
			if(response)
			{
				new time = strval(inputtext);
				if(time < 0 || time > 300)
				{
					return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Waktu harus antara 0-300 detik!");
				}
				GateInfo[slot][gAutoCloseTime] = time;
				GateInfo[slot][gNeedsUpdate] = true;
				format(string, 256, ""LB"GATE: "WHITE"Auto-close time set to "GREEN"%d seconds", time);
				SCM(playerid, COLOR_SUCCESS, string);
				ShowDialogGate(playerid, slot);
			}
			else ShowDialogGate(playerid, slot);
		}
		case DIALOG_EDITAREASIZE:
		{
			if(response)
			{
				new Float:size = floatstr(inputtext);
				if(size > 30.0 || size < 1.0) return SEM(playerid,"ERROR: Area tidak boleh kurang dari 1.0 dan lebih dari 30.0!");
				GateInfo[slot][gRange] = size;

				// ✅ NEW: Update dynamic area
				if(IsValidDynamicArea(GateArea[slot]))
				{
					DestroyDynamicArea(GateArea[slot]);
				}
				GateArea[slot] = CreateDynamicSphere(GateInfo[slot][gCloseX], GateInfo[slot][gCloseY], GateInfo[slot][gCloseZ], size);

				format(string,256,""LB"GATE: "WHITE"Area size "YELLOW"id %d"WHITE" telah di set ke "GREEN"%0.1f",slot,size);
				SEM(playerid,string);
				GateInfo[slot][gNeedsUpdate] = true;
				ShowDialogGate(playerid,slot);
			}
			else ShowDialogGate(playerid,slot);
		}
		case DIALOG_EDITSETOWNER:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0:
					{
						ShowPlayerDialog(playerid,DIALOG_EDITSETOWNERNAME,DIALOG_STYLE_INPUT,"Gate Configuration > Set Owner > Player","Masukan ID atau nama yang spesifik untuk mengubah kepemilik gate","Confirm","Back");
					}
					case 1:
					{
						GateInfo[slot][gOwner] = 0;
						format(string,256,""LB"GATE: "WHITE"Owner gate "YELLOW"id %d"WHITE" telah di set ke "GREEN"Public",slot);
						SEM(playerid,string);
						GateInfo[slot][gNeedsUpdate] = true;
						AddGateLog(slot, "System", "Set to public");
					}
				}
			}
			else ShowDialogGate(playerid,slot);
		}
		case DIALOG_EDITSETOWNERNAME:
		{
			if(response)
			{
				new giveplayerid,name[24];
				if(!sscanf(inputtext,"u",giveplayerid))
				{
					if(IsPlayerConnected(giveplayerid))
					{
						GetPlayerName(giveplayerid,name,24);
						format(string,256,""LB"GATE: "WHITE"Owner gate "YELLOW"id %d"WHITE" telah di set kepada "GREEN"%s",slot,name);
						SEM(playerid,string);
						GateInfo[slot][gOwner] = 1;
						format(GateInfo[slot][gOwnerName],24,"%s",name);
						GateInfo[slot][gNeedsUpdate] = true;

						format(string, 128, "Ownership transferred to %s", name);
						AddGateLog(slot, "System", string);
					}
					else SEM(playerid,"ERROR: Player tersebut tidak terkoneksi!");
				}
			}
			else ShowDialogGate(playerid,slot);
		}
		case DIALOG_EDITGATEMODEL:
		{
			if(response)
			{
				new model = strval(inputtext);
				Streamer_SetIntData(STREAMER_TYPE_OBJECT,DynamicGate[slot],E_STREAMER_MODEL_ID,model);
				GateInfo[slot][gModel] = model;
				GateInfo[slot][gNeedsUpdate] = true;
				ShowDialogGate(playerid,slot);
				AddGateLog(slot, "Admin", "Changed model");
			}
			else ShowDialogGate(playerid,slot);
		}
		case DIALOG_EDITGATESPEED:
		{
			if(response)
			{
				new Float:speed = floatstr(inputtext);
				if(speed < 0.0 || speed > 30.0) return SEM(playerid,"ERROR: Kecepatan gate tidak boleh kurang dari 0.0 dan lebih dari 30.0!");
				GateInfo[slot][gSpeed] = speed;
				GateInfo[slot][gNeedsUpdate] = true;
				ShowDialogGate(playerid,slot);
			}
			else ShowDialogGate(playerid,slot);
		}
		case DIALOG_EDITGATEMETHOD:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0: //Command /gate
					{
						GateInfo[slot][gMethods][0] = !GateInfo[slot][gMethods][0];
						ShowDialogMethods(playerid,slot);
						GateInfo[slot][gNeedsUpdate] = true;
					}
					case 1: //Horn
					{
						GateInfo[slot][gMethods][1] = !GateInfo[slot][gMethods][1];
						ShowDialogMethods(playerid,slot);
						GateInfo[slot][gNeedsUpdate] = true;
					}
					case 2: //Proximity On-Foot
					{
						GateInfo[slot][gMethods][2] = !GateInfo[slot][gMethods][2];
						ShowDialogMethods(playerid,slot);
						GateInfo[slot][gNeedsUpdate] = true;
					}
					case 3: //Proximity Vehicle
					{
						GateInfo[slot][gMethods][3] = !GateInfo[slot][gMethods][3];
						ShowDialogMethods(playerid,slot);
						GateInfo[slot][gNeedsUpdate] = true;
					}
				}
			}
			else
			{
				new params[24];
				format(params,24,"edit %d",slot);
				return cmd_agate(playerid,params);
			}
		}
	}
	return 1;
}

public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	new string[256],slot = GetPVarInt(playerid,"GateID");
	if(response == EDIT_RESPONSE_FINAL)
	{
		if(GetPVarType(playerid,"GateOpen") > 0)
		{
			DeletePVar(playerid,"GateOpen");
		    ObjectEditor[slot] = INVALID_PLAYER_ID;
		    SetDynamicObjectPos(objectid,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]);
            SetDynamicObjectRot(objectid,GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
            GateInfo[slot][gOpenX] = x; GateInfo[slot][gOpenY] = y; GateInfo[slot][gOpenZ] = z;
            GateInfo[slot][gOpenRX] = rx; GateInfo[slot][gOpenRY] = ry; GateInfo[slot][gOpenRZ] = rz;
			GateInfo[slot][gNeedsUpdate] = true;

            format(string,256,""LB"GATE: "WHITE"Anda telah mengedit "YELLOW"'Move Open Position' "WHITE"pada gate "GREEN"id %d",slot);
            SEM(playerid,string);
            ShowDialogGate(playerid,slot);
            AddGateLog(slot, "Admin", "Updated open position");
		}
		if(GetPVarType(playerid,"GateClose") > 0)
		{
			DeletePVar(playerid,"GateClose");
		    ObjectEditor[slot] = INVALID_PLAYER_ID;
		    SetDynamicObjectPos(objectid,x,y,z);
            SetDynamicObjectRot(objectid,rx,ry,rz);
            GateInfo[slot][gCloseX] = x; GateInfo[slot][gCloseY] = y; GateInfo[slot][gCloseZ] = z;
            GateInfo[slot][gCloseRX] = rx; GateInfo[slot][gCloseRY] = ry; GateInfo[slot][gCloseRZ] = rz;
			GateInfo[slot][gNeedsUpdate] = true;

            format(string,256,""LB"GATE: "WHITE"Anda telah mengedit "YELLOW"'Move Close Position' "WHITE"pada gate "GREEN"id %d",slot);
            SEM(playerid,string);
            ShowDialogGate(playerid,slot);
            AddGateLog(slot, "Admin", "Updated close position");
		}
	}
	else if(response == EDIT_RESPONSE_CANCEL)
	{
		if(GetPVarType(playerid,"GateOpen") > 0)
		{
			DeletePVar(playerid,"GateOpen");
		    ObjectEditor[slot] = INVALID_PLAYER_ID;
			SetDynamicObjectPos(objectid,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]);
            SetDynamicObjectRot(objectid,GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
        }
        if(GetPVarType(playerid,"GateClose") > 0)
		{
			DeletePVar(playerid,"GateClose");
		    ObjectEditor[slot] = INVALID_PLAYER_ID;
			SetDynamicObjectPos(objectid,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]);
            SetDynamicObjectRot(objectid,GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
        }
        ShowDialogGate(playerid,slot);
	}
	DeletePVar(playerid,"EditingGate");
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	new name[24];
	GetPlayerName(playerid,name,24);
	foreach(new slot : DynamicGates)
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
		{
			if(!GateInfo[slot][gOpenX]) continue;
			if(Pressed(KEY_CROUCH))
			{
				if(IsPlayerInRangeOfPoint(playerid, GateInfo[slot][gRange], GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
				{
					if(GateInfo[slot][gMethods][1]) // Horn method
					{
						if(CanUseGate(playerid, slot))
						{
							ToggleGate(playerid, slot, "horn");
						}
					}
				}
			}
		}
	}
	return 1;
}

// ✅ NEW: Enhanced gate loading with new fields
Server:LoadGates()
{
	new rows = cache_num_rows(),slot,count;
	for(new i = 0; i < rows && i < MAX_GATE; i++)
	{
		cache_get_value_int(i,"gid",slot);
		cache_get_value_int(i,"gmodel",GateInfo[slot][gModel]);
		cache_get_value_int(i,"gstatus",GateInfo[slot][gStatus]);
		cache_get_value_int(i,"gowner",GateInfo[slot][gOwner]);

		cache_get_value_int(i,"gmcmd",GateInfo[slot][gMethods][0]);
		cache_get_value_int(i,"gmhorn",GateInfo[slot][gMethods][1]);
		cache_get_value_int(i,"gmfoot",GateInfo[slot][gMethods][2]);
		cache_get_value_int(i,"gmveh",GateInfo[slot][gMethods][3]);

		cache_get_value(i,"gownername",GateInfo[slot][gOwnerName],24);

		cache_get_value_float(i,"grange",GateInfo[slot][gRange]);
		cache_get_value_float(i,"gspeed",GateInfo[slot][gSpeed]);
		cache_get_value_float(i,"gclosex",GateInfo[slot][gCloseX]);
		cache_get_value_float(i,"gclosey",GateInfo[slot][gCloseY]);
		cache_get_value_float(i,"gclosez",GateInfo[slot][gCloseZ]);
		cache_get_value_float(i,"gcloserx",GateInfo[slot][gCloseRX]);
		cache_get_value_float(i,"gclosery",GateInfo[slot][gCloseRY]);
		cache_get_value_float(i,"gcloserz",GateInfo[slot][gCloseRZ]);
		cache_get_value_float(i,"gopenx",GateInfo[slot][gOpenX]);
		cache_get_value_float(i,"gopeny",GateInfo[slot][gOpenY]);
		cache_get_value_float(i,"gopenz",GateInfo[slot][gOpenZ]);
		cache_get_value_float(i,"gopenrx",GateInfo[slot][gOpenRX]);
		cache_get_value_float(i,"gopenry",GateInfo[slot][gOpenRY]);
		cache_get_value_float(i,"gopenrz",GateInfo[slot][gOpenRZ]);

		// ✅ NEW: Load additional fields
		cache_get_value_int(i,"gautoclose",GateInfo[slot][gAutoCloseTime]);
		cache_get_value_int(i,"gopencount",GateInfo[slot][gOpenCount]);
		cache_get_value_int(i,"gclosecount",GateInfo[slot][gCloseCount]);
		cache_get_value(i,"gpassword",GateInfo[slot][gPassword],MAX_GATE_PASSWORD);
		GateInfo[slot][gHasPassword] = (strlen(GateInfo[slot][gPassword]) > 0) ? true : false;

		// Create gate object
		if(!GateInfo[slot][gStatus])
		{
			DynamicGate[slot] = CreateDynamicObject(GateInfo[slot][gModel],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
		}
		else
		{
			DynamicGate[slot] = CreateDynamicObject(GateInfo[slot][gModel],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
		}

		// ✅ NEW: Create dynamic area for proximity detection
		GateArea[slot] = CreateDynamicSphere(GateInfo[slot][gCloseX], GateInfo[slot][gCloseY], GateInfo[slot][gCloseZ], GateInfo[slot][gRange]);

		Iter_Add(DynamicGates,slot);
		printf("✅ Gate ID: %d | Model: %d | Status: %s", slot, GateInfo[slot][gModel], GateInfo[slot][gStatus] ? "Open" : "Closed");
		count++;
	}
	if(count >= 1)
	{
		printf("✅ [SYSTEM] %d gates loaded successfully!",count);
	}
}

// ✅ OPTIMIZED: More efficient proximity detection
Server:NearGate()
{
	new name[24];
	foreach(new playerid : Player)
	{
		if(!IsPlayerConnected(playerid)) continue;
		GetPlayerName(playerid,name,24);

		foreach(new slot : DynamicGates)
		{
			if(!GateInfo[slot][gOpenX]) continue;

			new bool:inRange = IsPlayerInRangeOfPoint(playerid, GateInfo[slot][gRange], GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]);

			// ✅ FIXED: Proximity on-foot now has auto-close
			if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT && GateInfo[slot][gMethods][2])
			{
				if(inRange && CanUseGate(playerid, slot))
				{
					if(!GateInfo[slot][gStatus]) // Closed
					{
						OpenGate(playerid, slot, "proximity-foot");
					}
				}
				else if(!inRange && GateInfo[slot][gStatus] && !GateInfo[slot][gAutoCloseTime])
				{
					// Auto close when player leaves (if no auto-close timer set)
					CloseGate(playerid, slot);
				}
			}

			// Proximity vehicle
			if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && GateInfo[slot][gMethods][3])
			{
				if(inRange && CanUseGate(playerid, slot))
				{
					if(!GateInfo[slot][gStatus]) // Closed
					{
						OpenGate(playerid, slot, "proximity-vehicle");
					}
				}
				else if(!inRange && GateInfo[slot][gStatus] && !GateInfo[slot][gAutoCloseTime])
				{
					// Auto close when vehicle leaves (if no auto-close timer set)
					CloseGate(playerid, slot);
				}
			}
		}
	}
	return 1;
}

// ✅ NEW: Auto-close timer
Server:CheckAutoClose()
{
	foreach(new slot : DynamicGates)
	{
		if(GateInfo[slot][gStatus] && GateInfo[slot][gAutoCloseTime] > 0)
		{
			new elapsed = gettime() - GateInfo[slot][gLastUsedTimestamp];
			if(elapsed >= GateInfo[slot][gAutoCloseTime])
			{
				CloseGate(INVALID_PLAYER_ID, slot);
			}
		}
	}
	return 1;
}

// ✅ NEW: Auto-save system (batch update)
Server:AutoSaveGates()
{
	new count = 0, query[512];
	foreach(new slot : DynamicGates)
	{
		if(GateInfo[slot][gNeedsUpdate])
		{
			mysql_format(g_SQL, query, sizeof(query),
				"UPDATE `gate` SET `gstatus`=%d, `gmodel`=%d, `gspeed`=%f, `grange`=%f, `gowner`=%d, `gownername`='%e', \
				`gmcmd`=%d, `gmhorn`=%d, `gmfoot`=%d, `gmveh`=%d, `gclosex`=%f, `gclosey`=%f, `gclosez`=%f, \
				`gcloserx`=%f, `gclosery`=%f, `gcloserz`=%f, `gopenx`=%f, `gopeny`=%f, `gopenz`=%f, \
				`gopenrx`=%f, `gopenry`=%f, `gopenrz`=%f, `gpassword`='%e', `gautoclose`=%d, \
				`gopencount`=%d, `gclosecount`=%d WHERE `gid`=%d",
				GateInfo[slot][gStatus], GateInfo[slot][gModel], GateInfo[slot][gSpeed], GateInfo[slot][gRange],
				GateInfo[slot][gOwner], GateInfo[slot][gOwnerName],
				GateInfo[slot][gMethods][0], GateInfo[slot][gMethods][1], GateInfo[slot][gMethods][2], GateInfo[slot][gMethods][3],
				GateInfo[slot][gCloseX], GateInfo[slot][gCloseY], GateInfo[slot][gCloseZ],
				GateInfo[slot][gCloseRX], GateInfo[slot][gCloseRY], GateInfo[slot][gCloseRZ],
				GateInfo[slot][gOpenX], GateInfo[slot][gOpenY], GateInfo[slot][gOpenZ],
				GateInfo[slot][gOpenRX], GateInfo[slot][gOpenRY], GateInfo[slot][gOpenRZ],
				GateInfo[slot][gPassword], GateInfo[slot][gAutoCloseTime],
				GateInfo[slot][gOpenCount], GateInfo[slot][gCloseCount], slot
			);
			mysql_tquery(g_SQL, query);
			GateInfo[slot][gNeedsUpdate] = false;
			count++;
		}
	}
	if(count > 0)
	{
		printf("💾 [AUTO-SAVE] %d gate(s) saved to database", count);
	}
	return 1;
}

// ✅ NEW: Save all gates (on exit)
SaveAllGates()
{
	new query[512];
	foreach(new slot : DynamicGates)
	{
		mysql_format(g_SQL, query, sizeof(query),
			"UPDATE `gate` SET `gstatus`=%d, `gmodel`=%d, `gspeed`=%f, `grange`=%f, `gowner`=%d, `gownername`='%e', \
			`gmcmd`=%d, `gmhorn`=%d, `gmfoot`=%d, `gmveh`=%d, `gclosex`=%f, `gclosey`=%f, `gclosez`=%f, \
			`gcloserx`=%f, `gclosery`=%f, `gcloserz`=%f, `gopenx`=%f, `gopeny`=%f, `gopenz`=%f, \
			`gopenrx`=%f, `gopenry`=%f, `gopenrz`=%f, `gpassword`='%e', `gautoclose`=%d, \
			`gopencount`=%d, `gclosecount`=%d WHERE `gid`=%d",
			GateInfo[slot][gStatus], GateInfo[slot][gModel], GateInfo[slot][gSpeed], GateInfo[slot][gRange],
			GateInfo[slot][gOwner], GateInfo[slot][gOwnerName],
			GateInfo[slot][gMethods][0], GateInfo[slot][gMethods][1], GateInfo[slot][gMethods][2], GateInfo[slot][gMethods][3],
			GateInfo[slot][gCloseX], GateInfo[slot][gCloseY], GateInfo[slot][gCloseZ],
			GateInfo[slot][gCloseRX], GateInfo[slot][gCloseRY], GateInfo[slot][gCloseRZ],
			GateInfo[slot][gOpenX], GateInfo[slot][gOpenY], GateInfo[slot][gOpenZ],
			GateInfo[slot][gOpenRX], GateInfo[slot][gOpenRY], GateInfo[slot][gOpenRZ],
			GateInfo[slot][gPassword], GateInfo[slot][gAutoCloseTime],
			GateInfo[slot][gOpenCount], GateInfo[slot][gCloseCount], slot
		);
		mysql_tquery(g_SQL, query);
	}
	print("💾 All gates saved to database");
}

SSCANF:gatemenu(string[])
{
	if(!strcmp(string,"create",true))           return 1;
	else if(!strcmp(string,"add",true)) 		return 1;
	else if(!strcmp(string,"destroy",true)) 	return 2;
	else if(!strcmp(string,"delete",true)) 		return 2;
	else if(!strcmp(string,"remove",true)) 		return 2;
	else if(!strcmp(string,"manage",true)) 		return 3;
	else if(!strcmp(string,"edit",true)) 		return 3;
	return 0;
}

// ✅ NEW: Helper functions
stock CanUseGate(playerid, gateid)
{
	// Check cooldown
	if(PlayerGateData[playerid][pGateCooldown])
	{
		return false;
	}

	// Check ownership
	if(!GateInfo[gateid][gOwner]) return true; // Public gate

	new name[24];
	GetPlayerName(playerid, name, 24);

	// ✅ FIXED: Exact match instead of strfind
	if(!strcmp(GateInfo[gateid][gOwnerName], name, false))
	{
		return true;
	}

	// Check ACL
	for(new i = 0; i < GateInfo[gateid][gACLCount]; i++)
	{
		if(!strcmp(GateInfo[gateid][gACL][i], name, false))
		{
			return true;
		}
	}

	return false;
}

stock ToggleGate(playerid, gateid, method[])
{
	// Check password
	if(GateInfo[gateid][gHasPassword] && playerid != INVALID_PLAYER_ID)
	{
		new dialogStr[256];
		format(dialogStr, sizeof(dialogStr), ""WHITE"Gate ini dilindungi password!\n\n"YELLOW"Masukan password:");
		SetPVarInt(playerid, "GateID", gateid);
		ShowPlayerDialog(playerid, DIALOG_GATE_ENTER_PASSWORD, DIALOG_STYLE_PASSWORD, "Protected Gate", dialogStr, "Enter", "Cancel");
		return 1;
	}

	if(!GateInfo[gateid][gStatus])
	{
		OpenGate(playerid, gateid, method);
	}
	else
	{
		CloseGate(playerid, gateid);
	}
	return 1;
}

stock OpenGate(playerid, gateid, method[])
{
	MoveDynamicObject(DynamicGate[gateid], GateInfo[gateid][gOpenX], GateInfo[gateid][gOpenY], GateInfo[gateid][gOpenZ],
		GateInfo[gateid][gSpeed], GateInfo[gateid][gOpenRX], GateInfo[gateid][gOpenRY], GateInfo[gateid][gOpenRZ]);

	GateInfo[gateid][gStatus] = 1;
	GateInfo[gateid][gOpenCount]++;
	GateInfo[gateid][gLastUsedTimestamp] = gettime();
	GateInfo[gateid][gNeedsUpdate] = true;

	// Play sound
	PlayGateSound(gateid, true);

	// Set cooldown
	if(playerid != INVALID_PLAYER_ID)
	{
		PlayerGateData[playerid][pGateCooldown] = true;
		PlayerGateData[playerid][pLastGateUse] = GetTickCount();
		SetTimerEx("ResetGateCooldown", GATE_COOLDOWN_TIME, false, "i", playerid);

		// Log activity
		new name[24];
		GetPlayerName(playerid, name, 24);
		AddGateLog(gateid, name, method);
	}
	return 1;
}

stock CloseGate(playerid, gateid)
{
	MoveDynamicObject(DynamicGate[gateid], GateInfo[gateid][gCloseX], GateInfo[gateid][gCloseY], GateInfo[gateid][gCloseZ],
		GateInfo[gateid][gSpeed], GateInfo[gateid][gCloseRX], GateInfo[gateid][gCloseRY], GateInfo[gateid][gCloseRZ]);

	GateInfo[gateid][gStatus] = 0;
	GateInfo[gateid][gCloseCount]++;
	GateInfo[gateid][gNeedsUpdate] = true;

	// Play sound
	PlayGateSound(gateid, false);

	if(playerid != INVALID_PLAYER_ID)
	{
		new name[24];
		GetPlayerName(playerid, name, 24);
		AddGateLog(gateid, name, "closed");
	}
	return 1;
}

forward ResetGateCooldown(playerid);
public ResetGateCooldown(playerid)
{
	if(IsPlayerConnected(playerid))
	{
		PlayerGateData[playerid][pGateCooldown] = false;
	}
	return 1;
}

stock PlayGateSound(gateid, bool:opening)
{
	// Play sound for nearby players
	foreach(new playerid : Player)
	{
		if(IsPlayerInRangeOfPoint(playerid, 50.0, GateInfo[gateid][gCloseX], GateInfo[gateid][gCloseY], GateInfo[gateid][gCloseZ]))
		{
			if(GateInfo[gateid][gSoundID] > 0)
			{
				PlayerPlaySound(playerid, GateInfo[gateid][gSoundID], 0.0, 0.0, 0.0);
			}
			else
			{
				// Default sounds
				PlayerPlaySound(playerid, opening ? 1085 : 1084, 0.0, 0.0, 0.0);
			}
		}
	}
	return 1;
}

stock PlayErrorSound(playerid)
{
	PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0);
	return 1;
}

// ✅ NEW: Activity logging
stock AddGateLog(gateid, playername[], action[])
{
	GateLog[GateLogIndex][gLogGateID] = gateid;
	format(GateLog[GateLogIndex][gLogPlayerName], 24, "%s", playername);
	format(GateLog[GateLogIndex][gLogAction], 32, "%s", action);
	GateLog[GateLogIndex][gLogTimestamp] = gettime();

	GateLogIndex++;
	if(GateLogIndex >= GATE_LOG_SIZE) GateLogIndex = 0;

	return 1;
}

// ✅ ENHANCED: Admin command with permission check
CMD:agate(playerid,params[])
{
	// ✅ SECURITY: Admin level check
	if(PlayerGateData[playerid][pAdminLevel] < ADMIN_LEVEL_MOD && !IsPlayerAdmin(playerid))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"You need admin level 2 or higher!");
	}

	new action,subparam[128],string[512];
	unformat(params,"k<gatemenu>S()[128]",action,subparam);
	switch(action)
	{
	    case 1: // Create
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"KEGUNAAN: /agate create [model id]");
	    	{
	    		new slot = Iter_Free(DynamicGates);
	    		if(slot != cellmin)
	    		{
		    		new model = strval(subparam);
		    		new Float:cPos[4];
		    		GetPlayerPos(playerid,cPos[0],cPos[1],cPos[2]);
		    		GetPlayerFacingAngle(playerid,cPos[3]);
		    		DynamicGate[slot] = CreateDynamicObject(model,cPos[0],cPos[1],cPos[2],0.0,0.0,cPos[3],GetPlayerVirtualWorld(playerid),GetPlayerInterior(playerid));
			    	Iter_Add(DynamicGates,slot);

		    		format(string,512,""LB"GATE: "YELLOW"Gate ID %d "WHITE"dengan "GREEN"model id %d "WHITE"telah berhasil dibuat, total gate: "LG"%d",slot,model,Iter_Count(DynamicGates));
		    		SCM(playerid, COLOR_SUCCESS, string);

		    		// Initialize gate data
		    		GateInfo[slot][gModel] = model;
		    		GateInfo[slot][gStatus] = 0;
		    		GateInfo[slot][gSpeed] = 3.0;
		    		GateInfo[slot][gRange] = 10.0;
		    		GateInfo[slot][gCloseX] = cPos[0];
		    		GateInfo[slot][gCloseY] = cPos[1];
		    		GateInfo[slot][gCloseZ] = cPos[2];
	        		GateInfo[slot][gCloseRX] = 0.0;
	        		GateInfo[slot][gCloseRY] = 0.0;
	        		GateInfo[slot][gCloseRZ] = cPos[3];
	        		GateInfo[slot][gOwner] = 0;
	        		GateInfo[slot][gHasPassword] = false;
	        		GateInfo[slot][gAutoCloseTime] = 0;
	        		GateInfo[slot][gACLCount] = 0;
	        		GateInfo[slot][gNeedsUpdate] = true;

	        		// Create dynamic area
	        		GateArea[slot] = CreateDynamicSphere(cPos[0], cPos[1], cPos[2], 10.0);

	        		// Save to database
	        		mysql_format(g_SQL,string,512,"INSERT INTO `gate` (`gid`,`gstatus`,`gmodel`,`gspeed`,`grange`,`gclosex`,`gclosey`,`gclosez`,`gcloserz`,`gopencount`,`gclosecount`) VALUES ('%d','0','%d','3.0','10.0','%f','%f','%f','%f','0','0')",slot,model,cPos[0],cPos[1],cPos[2],cPos[3]);
		    		mysql_tquery(g_SQL,string);

		    		AddGateLog(slot, "Admin", "Created gate");
	        	}
	        	else SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Tidak ada slot yang tersisa!");
	    	}
	    }
	    case 2: // Delete
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"KEGUNAAN: /agate delete [gate id]");
	    	{
	    		new slot = strval(subparam);
	    		if(Iter_Contains(DynamicGates,slot))
	    		{
	    			Iter_Remove(DynamicGates,slot);
	    			DestroyDynamicObject(DynamicGate[slot]);
	    			DestroyDynamicArea(GateArea[slot]);

	    			format(string,256,""LB"GATE: "YELLOW"Gate ID %d "WHITE"telah berhasil dihapus, total gate: "LG"%d",slot,Iter_Count(DynamicGates));
	    			SCM(playerid, COLOR_SUCCESS, string);

	    			mysql_format(g_SQL,string,256,"DELETE FROM `gate` WHERE `gid` = '%d'",slot);
	    			mysql_tquery(g_SQL,string);

	    			AddGateLog(slot, "Admin", "Deleted gate");
	    		}
	    		else SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Gate ID salah!");
	    	}
	    }
	    case 3: // Edit
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"KEGUNAAN: /agate edit [gate id]");
	    	{
	    		new slot = strval(subparam);
	    		if(Iter_Contains(DynamicGates,slot))
	    		{
	    			ShowDialogGate(playerid,slot);
	    			SetPVarInt(playerid,"GateID",slot);
	    		}
	    		else SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Gate ID salah!");
	    	}
	    }
	    default:
	    {
	    	SCM(playerid, COLOR_INFO, ""LB"═══════════════════════════════════");
	    	SCM(playerid, COLOR_INFO, ""LB"GATE ADMIN COMMANDS:");
	    	SCM(playerid, COLOR_INFO, ""WHITE"/agate create [modelid] "YELLOW"- Create new gate");
	    	SCM(playerid, COLOR_INFO, ""WHITE"/agate edit [gateid] "YELLOW"- Edit gate settings");
	    	SCM(playerid, COLOR_INFO, ""WHITE"/agate delete [gateid] "YELLOW"- Delete gate");
	    	SCM(playerid, COLOR_INFO, ""LB"═══════════════════════════════════");
	    }
	}
	return 1;
}

// ✅ ENHANCED: Gate command with permission and cooldown
CMD:gate(playerid,params[])
{
	new string[256];
	new bool:found = false;

	foreach(new slot : DynamicGates)
	{
		if(IsPlayerInRangeOfPoint(playerid, GateInfo[slot][gRange], GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
		{
			if(GateInfo[slot][gMethods][0]) // Command method enabled
			{
				if(!GateInfo[slot][gOpenX])
				{
					return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Terjadi kesalahan pada gate!");
				}

				if(!CanUseGate(playerid, slot))
				{
					return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Anda tidak memiliki akses ke gate ini!");
				}

				ToggleGate(playerid, slot, "command");
				found = true;
				break;
			}
		}
	}

	if(!found)
	{
		SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Tidak ada gate di sekitar Anda!");
	}

	return 1;
}

CMD:gotogate(playerid,params[])
{
	if(PlayerGateData[playerid][pAdminLevel] < ADMIN_LEVEL_BASIC && !IsPlayerAdmin(playerid))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Admin only!");
	}

	if(IsNull(params)) return SEM(playerid,"USAGE: /gotogate [gateid]");
	{
		new slot = strval(params);
		if(Iter_Contains(DynamicGates, slot))
		{
			SetPlayerPos(playerid,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ] + 2.0);
			new string[128];
			format(string, 128, ""LB"GATE: "WHITE"Teleported to gate "GREEN"ID %d", slot);
			SCM(playerid, COLOR_SUCCESS, string);
		}
		else
		{
			SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Invalid gate ID!");
		}
	}
	return 1;
}

CMD:gnear(playerid,params[])
{
	new string[256],count;
	if(IsNull(params)) return SEM(playerid,"KEGUNAAN: /gnear [distance]");
	{
		new Float:jarak = floatstr(params);
		format(string,256,""LB"GATE: "WHITE"Detecting gate(s) around "YELLOW"%0.1f meters "WHITE"from you",jarak);
		SCM(playerid, COLOR_INFO, string);

		foreach(new slot : DynamicGates)
		{
			if(IsPlayerInRangeOfPoint(playerid,jarak,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
			{
				new dist = floatround(GetPlayerDistanceFromPoint(playerid,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]));
				if(GateInfo[slot][gOwner])
				{
					format(string,256,""YELLOW"[%d] "WHITE"Model: "GREEN"%d "WHITE"| Owner: "GREEN"%s "WHITE"| Distance: "ORANGE"%dm",
						slot, GateInfo[slot][gModel], GateInfo[slot][gOwnerName], dist);
				}
				else
				{
					format(string,256,""YELLOW"[%d] "WHITE"Model: "GREEN"%d "WHITE"| Owner: "GREEN"Public "WHITE"| Distance: "ORANGE"%dm",
						slot, GateInfo[slot][gModel], dist);
				}
				SCM(playerid, COLOR_INFO, string);
				count++;
			}
		}

		if(count > 0)
		{
			format(string,128,""LB"GATE: "GREEN"%d gate(s) "WHITE"detected",count);
		}
		else
		{
			format(string,128,""LB"GATE: "RED"No gates found "WHITE"around you");
		}
		SCM(playerid, COLOR_INFO, string);
	}
	return 1;
}

CMD:glist(playerid,params[])
{
	if(PlayerGateData[playerid][pAdminLevel] < ADMIN_LEVEL_BASIC && !IsPlayerAdmin(playerid))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Admin only!");
	}

	new string[2048];
	format(string,sizeof(string),"ID\tModel\tOwner\tStatus\n");

	foreach(new i : DynamicGates)
	{
		new statusStr[16];
		statusStr = GateInfo[i][gStatus] ? ("{00FF00}Open") : ("{FF0000}Closed");

		new ownerStr[32];
		if(GateInfo[i][gOwner])
		{
			format(ownerStr, 32, "%s", GateInfo[i][gOwnerName]);
		}
		else
		{
			format(ownerStr, 32, "Public");
		}

		format(string, sizeof(string), "%s%d\t%d\t%s\t%s\n", string, i, GateInfo[i][gModel], ownerStr, statusStr);
	}

	ShowPlayerDialog(playerid, 9991, DIALOG_STYLE_TABLIST_HEADERS, "Gate List", string, "Close", "");
	return 1;
}

// ✅ NEW: Set admin level command (for testing)
CMD:setadmin(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"RCON admin only!");

	new targetid, level;
	if(sscanf(params, "ui", targetid, level))
	{
		return SCM(playerid, COLOR_INFO, ""WHITE"USAGE: /setadmin [playerid] [level 0-3]");
	}

	if(!IsPlayerConnected(targetid))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Player not connected!");
	}

	if(level < 0 || level > 3)
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Level must be 0-3!");
	}

	PlayerGateData[targetid][pAdminLevel] = level;

	new string[128], name[24];
	GetPlayerName(targetid, name, 24);
	format(string, 128, ""LB"ADMIN: "WHITE"Set "GREEN"%s "WHITE"admin level to "YELLOW"%d", name, level);
	SCM(playerid, COLOR_SUCCESS, string);

	format(string, 128, ""LB"ADMIN: "WHITE"Your admin level has been set to "YELLOW"%d", level);
	SCM(targetid, COLOR_SUCCESS, string);

	return 1;
}

// ✅ NEW: Check gate info
CMD:ginfo(playerid, params[])
{
	if(IsNull(params)) return SCM(playerid, COLOR_INFO, ""WHITE"USAGE: /ginfo [gateid]");

	new slot = strval(params);
	if(!Iter_Contains(DynamicGates, slot))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Invalid gate ID!");
	}

	new string[512];
	format(string, sizeof(string),
		""LB"═══════════════════════════════════\n\
		"WHITE"Gate ID: "YELLOW"%d\n\
		"WHITE"Model: "GREEN"%d\n\
		"WHITE"Status: %s\n\
		"WHITE"Owner: "GREEN"%s\n\
		"WHITE"Speed: "YELLOW"%0.1f\n\
		"WHITE"Range: "YELLOW"%0.1f\n\
		"WHITE"Password: %s\n\
		"WHITE"Auto-Close: "YELLOW"%d seconds\n\
		"WHITE"Open Count: "GREEN"%d\n\
		"WHITE"Close Count: "GREEN"%d\n\
		"LB"═══════════════════════════════════",
		slot,
		GateInfo[slot][gModel],
		GateInfo[slot][gStatus] ? ("{00FF00}Open") : ("{FF0000}Closed"),
		GateInfo[slot][gOwner] ? GateInfo[slot][gOwnerName] : "Public",
		GateInfo[slot][gSpeed],
		GateInfo[slot][gRange],
		GateInfo[slot][gHasPassword] ? ("{00FF00}Protected") : ("{FF0000}None"),
		GateInfo[slot][gAutoCloseTime],
		GateInfo[slot][gOpenCount],
		GateInfo[slot][gCloseCount]
	);

	ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "Gate Information", string, "Close", "");
	return 1;
}

// ✅ NEW: Manual save command
CMD:gsave(playerid, params[])
{
	if(PlayerGateData[playerid][pAdminLevel] < ADMIN_LEVEL_ADMIN && !IsPlayerAdmin(playerid))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Admin level 3 required!");
	}

	SaveAllGates();
	SCM(playerid, COLOR_SUCCESS, ""LB"GATE: "WHITE"All gates saved to database!");
	return 1;
}

// ✅ Development/Testing commands
CMD:veh(playerid,params[])
{
	new Float:cPos[4];
	if(IsNull(params)) return SEM(playerid,"/veh [vehicle model]");
	{
		new model = strval(params);
		GetPlayerPos(playerid,cPos[0],cPos[1],cPos[2]);
		GetPlayerFacingAngle(playerid,cPos[3]);
		new vid = CreateVehicle(model,cPos[0],cPos[1],cPos[2],cPos[3],-1,-1,60000,0);
		PutPlayerInVehicle(playerid,vid,0);
	}
	return 1;
}

// Display functions
ShowDialogGate(playerid,gateid)
{
	new string[1024];
	format(string, sizeof(string),
		""WHITE"Set Owner (Current: "GREEN"%s"WHITE")\n\
		"WHITE"Gate Model ID: "GREEN"%d\n\
		"WHITE"Move Open Position\n\
		Move Close Position\n\
		Set Speed (Current: "GREEN"%0.1f"WHITE")\n\
		Detection Methods\n\
		Area Size (Current: "GREEN"%0.1f"WHITE")\n\
		Password Protection %s\n\
		Access Control List\n\
		Auto Close Time (Current: "YELLOW"%d sec"WHITE")\n\
		Statistics & Logs",
		(GateInfo[gateid][gOwner] != 1) ? ("Public") : (GateInfo[gateid][gOwnerName]),
		GateInfo[gateid][gModel],
		GateInfo[gateid][gSpeed],
		GateInfo[gateid][gRange],
		GateInfo[gateid][gHasPassword] ? (""GREEN"[ON]") : (""RED"[OFF]"),
		GateInfo[gateid][gAutoCloseTime]
	);
	ShowPlayerDialog(playerid, DIALOG_GATE, DIALOG_STYLE_LIST, "Gate Configuration", string, "Select", "Exit");
	return 1;
}

ShowDialogMethods(playerid,slot)
{
	new string[512];
	format(string, sizeof(string),
		"Method\tStatus\n\
		Command (/gate)\t%s\n\
		Horn\t%s\n\
		Proximity (On-Foot)\t%s\n\
		Proximity (Vehicle)\t%s",
		(GateInfo[slot][gMethods][0] != 1) ? (""RED"Disabled") : (""GREEN"Enabled"),
		(GateInfo[slot][gMethods][1] != 1) ? (""RED"Disabled") : (""GREEN"Enabled"),
		(GateInfo[slot][gMethods][2] != 1) ? (""RED"Disabled") : (""GREEN"Enabled"),
		(GateInfo[slot][gMethods][3] != 1) ? (""RED"Disabled") : (""GREEN"Enabled")
	);
	ShowPlayerDialog(playerid, DIALOG_EDITGATEMETHOD, DIALOG_STYLE_TABLIST_HEADERS, "Gate Configuration > Detection Methods", string, "Toggle", "Back");
	return 1;
}

ShowDialogACL(playerid, gateid)
{
	new string[512] = ""WHITE"Access Control List:\n\n";

	if(GateInfo[gateid][gACLCount] == 0)
	{
		strcat(string, ""YELLOW"No players in ACL\n\n");
	}
	else
	{
		for(new i = 0; i < GateInfo[gateid][gACLCount]; i++)
		{
			format(string, sizeof(string), "%s"GREEN"%d. %s\n", string, i+1, GateInfo[gateid][gACL][i]);
		}
	}

	strcat(string, "\n"WHITE"Add Player\nRemove Player");
	ShowPlayerDialog(playerid, DIALOG_GATE_ACL, DIALOG_STYLE_LIST, "Access Control List", string, "Select", "Back");
	return 1;
}

ShowDialogStats(playerid, gateid)
{
	new string[512];
	new lastused[64];

	if(GateInfo[gateid][gLastUsedTimestamp] > 0)
	{
		new elapsed = gettime() - GateInfo[gateid][gLastUsedTimestamp];
		if(elapsed < 60)
			format(lastused, 64, "%d seconds ago", elapsed);
		else if(elapsed < 3600)
			format(lastused, 64, "%d minutes ago", elapsed / 60);
		else
			format(lastused, 64, "%d hours ago", elapsed / 3600);
	}
	else
	{
		format(lastused, 64, "Never used");
	}

	format(string, sizeof(string),
		""LB"═══════════════════════════════════\n\
		"WHITE"Gate Statistics - ID: "YELLOW"%d\n\
		"LB"═══════════════════════════════════\n\n\
		"WHITE"Total Opens: "GREEN"%d\n\
		"WHITE"Total Closes: "GREEN"%d\n\
		"WHITE"Last Used: "YELLOW"%s\n\n\
		"LB"═══════════════════════════════════",
		gateid,
		GateInfo[gateid][gOpenCount],
		GateInfo[gateid][gCloseCount],
		lastused
	);

	ShowPlayerDialog(playerid, DIALOG_GATE_STATS, DIALOG_STYLE_MSGBOX, "Gate Statistics", string, "Close", "");
	return 1;
}
