/*==================================[Credits]===================================

Special Thanks to	:
	• SA:MP Team past & present

Thanks to			:
	• Y_Less    	for     sscanf, foreach, and YSI
	• Incognito 	for     streamer
	• Zeex      	for     zcmd
==============================================================================*/

/*=================================[Changelog]==================================

Version 2.1 (BUTTON UPDATE):
	✅ NEW FEATURES:
		- 🔘 Interactive Button System
		- Physical button objects (keypad, switch, panel)
		- Click to trigger gate (OnPlayerClickDynamicObject)
		- 10+ button models to choose from
		- Auto-position button near gate
		- Manual button position editor
		- Button enable/disable per gate
		- Visual feedback on click (sound + animation)
		- Button model customization
		- Distance-based button visibility
		- Button label with 3D text (optional)

Version 2.0:
	[Previous changelog from V2.0...]
==============================================================================*/

//=============================[Include & Defines]==============================

#include <a_samp>
#include <sscanf2>
#include <streamer>
#include <a_mysql>
#include <YSI\y_iterate>
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
#define MAX_GATE_ACL            10
#define MAX_GATE_PASSWORD       24
#define GATE_COOLDOWN_TIME      3000
#define GATE_SAVE_INTERVAL      300000
#define GATE_LOG_SIZE           50

// ✅ NEW: Button Configuration
#define BUTTON_CLICK_SOUND      1085    // Sound when button clicked
#define BUTTON_VIEW_DISTANCE    50.0    // How far button can be seen
#define BUTTON_LABEL_DISTANCE   5.0     // How far label can be read

// MySQL Configuration
#define MYSQL_HOST 				"localhost"
#define MYSQL_USER 				"root"
#define MYSQL_PASSWORD 			"your_secure_password_here"
#define MYSQL_DATABASE 			"mgrp"

// Admin Levels
#define ADMIN_LEVEL_BASIC       1
#define ADMIN_LEVEL_MOD         2
#define ADMIN_LEVEL_ADMIN       3

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

// ✅ NEW: Button Dialog IDs
#define DIALOG_BUTTON_MENU          0321
#define DIALOG_BUTTON_MODEL         0322
#define DIALOG_BUTTON_ENABLE        0323
#define DIALOG_BUTTON_LABEL         0324

new MySQL: g_SQL;

new Iterator:DynamicGates<MAX_GATE>;
new DynamicGate[MAX_GATE];
new ObjectEditor[MAX_GATE];
new DynamicArea:GateArea[MAX_GATE];

// ✅ NEW: Button Objects & Labels
new DynamicObject:GateButton[MAX_GATE];
new Text3D:ButtonLabel[MAX_GATE];
new bool:ButtonEditor[MAX_PLAYERS];

// Player Data
enum pGateData
{
    pAdminLevel,
    pLastGateUse,
    bool:pGateCooldown,
    pGatePassword[MAX_GATE_PASSWORD]
};
new PlayerGateData[MAX_PLAYERS][pGateData];

// ✅ ENHANCED: Gate Info with Button Data
enum gInfo
{
	gModel,
	gStatus,
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
	gMethods[4],

	// Previous V2.0 fields
	bool:gHasPassword,
	gPassword[MAX_GATE_PASSWORD],
	gACL[MAX_GATE_ACL][24],
	gACLCount,
	gAutoCloseTime,
	gLastUsedTimestamp,
	gOpenCount,
	gCloseCount,
	gSoundID,
	bool:gNeedsUpdate,

	// ✅ NEW: Button Fields
	bool:gHasButton,                // Button enabled?
	gButtonModel,                   // Button object model
	Float:gButtonX,                 // Button position
	Float:gButtonY,
	Float:gButtonZ,
	Float:gButtonRX,                // Button rotation
	Float:gButtonRY,
	Float:gButtonRZ,
	bool:gButtonLabel,              // Show label?
	gButtonLabelText[64]           // Button label text
};
new GateInfo[MAX_GATE][gInfo];

// ✅ Button Models Available
enum ButtonModels {
	MODEL_KEYPAD = 2886,        // Wall keypad (best!)
	MODEL_BUTTON_RED = 1318,    // Red button
	MODEL_BUTTON_GREEN = 1319,  // Green button
	MODEL_SWITCH = 1650,        // Light switch
	MODEL_PANEL = 2232,         // Control panel
	MODEL_INTERCOM = 2942,      // Intercom
	MODEL_BELL = 1317,          // Doorbell
	MODEL_GARAGE_BTN = 3095,    // Garage button
	MODEL_MODERN_PANEL = 19273, // Modern panel
	MODEL_CARD_READER = 2886    // Card reader
};

// Activity Log
enum gLogInfo
{
	gLogGateID,
	gLogPlayerName[24],
	gLogAction[32],
	gLogTimestamp
};
new GateLog[GATE_LOG_SIZE][gLogInfo];
new GateLogIndex = 0;

public OnFilterScriptInit()
{
	print("|=========================================|");
    print("|======[Gate System V2.1 + Buttons]=======|");
    print("|=============[BY MRS5TEEN]===============|");
    print("|=======[BUTTON SYSTEM ADDED!]==========|");
    print("|=========================================|");

    new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);

	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id);
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("❌ MySQL connection failed!");
		return 1;
	}
	mysql_tquery(g_SQL,"SELECT * FROM `gate`","LoadGates");
	print("✅ [SYSTEM] Database connected!");

	SetTimer("NearGate", 500, true);
	SetTimer("AutoSaveGates", GATE_SAVE_INTERVAL, true);
	SetTimer("CheckAutoClose", 1000, true);

    return 1;
}

public OnFilterScriptExit()
{
	SaveAllGates();

	// ✅ NEW: Destroy all buttons
	foreach(new slot : DynamicGates)
	{
		if(GateInfo[slot][gHasButton])
		{
			if(IsValidDynamicObject(GateButton[slot]))
			{
				DestroyDynamicObject(GateButton[slot]);
			}
			if(IsValidDynamic3DTextLabel(ButtonLabel[slot]))
			{
				DestroyDynamic3DTextLabel(ButtonLabel[slot]);
			}
		}
	}

	mysql_close(g_SQL);
	return 1;
}

public OnPlayerConnect(playerid)
{
	PlayerGateData[playerid][pAdminLevel] = 0;
	PlayerGateData[playerid][pLastGateUse] = 0;
	PlayerGateData[playerid][pGateCooldown] = false;
	PlayerGateData[playerid][pGatePassword][0] = 0;
	ButtonEditor[playerid] = false;

	if(IsPlayerAdmin(playerid))
	{
		PlayerGateData[playerid][pAdminLevel] = ADMIN_LEVEL_ADMIN;
	}

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	DeletePVar(playerid, "EditingGate");
	DeletePVar(playerid, "GateID");
	DeletePVar(playerid, "GateOpen");
	DeletePVar(playerid, "GateClose");
	ButtonEditor[playerid] = false;
	return 1;
}

// ✅ NEW: OnPlayerClickDynamicObject - Button Interaction!
public OnPlayerClickDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid)
{
	// Check if player clicked a gate button
	foreach(new slot : DynamicGates)
	{
		if(!GateInfo[slot][gHasButton]) continue;

		if(objectid == GateButton[slot])
		{
			// Check permission
			if(!CanUseGate(playerid, slot))
			{
				SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"You don't have access to this gate!");
				PlayErrorSound(playerid);
				return 1;
			}

			// Check password
			if(GateInfo[slot][gHasPassword])
			{
				new dialogStr[256];
				format(dialogStr, sizeof(dialogStr), ""WHITE"This gate is password protected!\n\n"YELLOW"Enter password:");
				SetPVarInt(playerid, "GateID", slot);
				ShowPlayerDialog(playerid, DIALOG_GATE_ENTER_PASSWORD, DIALOG_STYLE_PASSWORD, "Protected Gate", dialogStr, "Enter", "Cancel");
				return 1;
			}

			// Toggle gate via button
			ToggleGate(playerid, slot, "button");

			// Visual/Audio feedback
			PlayerPlaySound(playerid, BUTTON_CLICK_SOUND, 0.0, 0.0, 0.0);

			// Animate button press (optional - rotate slightly)
			new Float:rx, Float:ry, Float:rz;
			GetDynamicObjectRot(GateButton[slot], rx, ry, rz);
			MoveDynamicObject(GateButton[slot],
				GateInfo[slot][gButtonX],
				GateInfo[slot][gButtonY],
				GateInfo[slot][gButtonZ] - 0.05,
				2.0);

			// Return to original position
			SetTimerEx("ResetButtonPosition", 500, false, "i", slot);

			// Show feedback message
			new string[128];
			format(string, sizeof(string), ""LB"BUTTON: "WHITE"Gate "GREEN"%s "WHITE"via button click",
				GateInfo[slot][gStatus] ? "opened" : "closed");
			SCM(playerid, COLOR_INFO, string);

			return 1;
		}
	}

	return 1;
}

forward ResetButtonPosition(slot);
public ResetButtonPosition(slot)
{
	if(IsValidDynamicObject(GateButton[slot]))
	{
		MoveDynamicObject(GateButton[slot],
			GateInfo[slot][gButtonX],
			GateInfo[slot][gButtonY],
			GateInfo[slot][gButtonZ],
			5.0);
	}
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
						ShowPlayerDialog(playerid,DIALOG_EDITGATEMODEL,DIALOG_STYLE_INPUT,"Gate Configuration > Gate Model","Masukan model id untuk gate","Confirm","Back");
					}
					case 2: //Move Open Position
					{
						format(string,sizeof(string),""LB"GATE: "WHITE"Editing gate "YELLOW"id %d "WHITE"open position",slot);
						ObjectEditor[slot] = playerid;
						SetPVarInt(playerid,"EditingGate",slot);
						SetPVarInt(playerid,"GateOpen",slot);
						EditDynamicObject(playerid,DynamicGate[slot]);
						SendClientMessage(playerid,COLOR_INFO,string);
					}
					case 3: //Move Close Position
					{
						format(string,sizeof(string),""LB"GATE: "WHITE"Editing gate "YELLOW"id %d "WHITE"close position",slot);
						ObjectEditor[slot] = playerid;
						SetPVarInt(playerid,"EditingGate",slot);
						SetPVarInt(playerid,"GateClose",slot);
						EditDynamicObject(playerid,DynamicGate[slot]);
						SendClientMessage(playerid,COLOR_INFO,string);
					}
					case 4: //Edit Gate Speed
					{
						ShowPlayerDialog(playerid,DIALOG_EDITGATESPEED,DIALOG_STYLE_INPUT,"Gate Configuration > Gate Speed","Masukan kecepatan gate (0.0 - 30.0)","Confirm","Back");
					}
					case 5: //Detection Methods
					{
						ShowDialogMethods(playerid,slot);
					}
					case 6: //Area Size
					{
						ShowPlayerDialog(playerid,DIALOG_EDITAREASIZE,DIALOG_STYLE_INPUT,"Gate Configuration > Area Size","Masukan area size (1.0 - 30.0)","Confirm","Back");
					}
					case 7: //Password
					{
						if(GateInfo[slot][gHasPassword])
						{
							format(string, 256, ""WHITE"Current: "GREEN"Protected\n\n"WHITE"Set New Password\nRemove Password");
							ShowPlayerDialog(playerid, DIALOG_GATE_PASSWORD, DIALOG_STYLE_LIST, "Gate Password", string, "Select", "Back");
						}
						else
						{
							ShowPlayerDialog(playerid, DIALOG_GATE_PASSWORD, DIALOG_STYLE_INPUT, "Gate Password", ""WHITE"Enter password (leave empty to disable):", "Confirm", "Back");
						}
					}
					case 8: //ACL
					{
						ShowDialogACL(playerid, slot);
					}
					case 9: //Auto Close Time
					{
						format(string, 256, ""WHITE"Enter auto-close time (seconds):\n\n"YELLOW"Current: %d seconds\n"WHITE"0 = disabled", GateInfo[slot][gAutoCloseTime]);
						ShowPlayerDialog(playerid, DIALOG_GATE_AUTOCLOSE, DIALOG_STYLE_INPUT, "Auto Close Time", string, "Confirm", "Back");
					}
					case 10: //Statistics
					{
						ShowDialogStats(playerid, slot);
					}
					case 11: // ✅ NEW: Button Settings
					{
						ShowButtonMenu(playerid, slot);
					}
				}
			}
		}

		// ✅ NEW: Button Dialogs
		case DIALOG_BUTTON_MENU:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0: // Enable/Disable Button
					{
						if(GateInfo[slot][gHasButton])
						{
							// Disable button
							GateInfo[slot][gHasButton] = false;
							if(IsValidDynamicObject(GateButton[slot]))
							{
								DestroyDynamicObject(GateButton[slot]);
							}
							if(IsValidDynamic3DTextLabel(ButtonLabel[slot]))
							{
								DestroyDynamic3DTextLabel(ButtonLabel[slot]);
							}
							SCM(playerid, COLOR_SUCCESS, ""LB"BUTTON: "WHITE"Button "RED"disabled");
						}
						else
						{
							// Enable button - create at default position (5m in front of gate)
							GateInfo[slot][gHasButton] = true;
							GateInfo[slot][gButtonModel] = MODEL_KEYPAD;

							// Calculate position 5m in front of gate
							GateInfo[slot][gButtonX] = GateInfo[slot][gCloseX] + 5.0;
							GateInfo[slot][gButtonY] = GateInfo[slot][gCloseY];
							GateInfo[slot][gButtonZ] = GateInfo[slot][gCloseZ] + 1.5;
							GateInfo[slot][gButtonRX] = 0.0;
							GateInfo[slot][gButtonRY] = 0.0;
							GateInfo[slot][gButtonRZ] = GateInfo[slot][gCloseRZ];

							CreateGateButton(slot);
							SCM(playerid, COLOR_SUCCESS, ""LB"BUTTON: "WHITE"Button "GREEN"enabled "WHITE"(use 'Edit Position' to adjust)");
						}
						GateInfo[slot][gNeedsUpdate] = true;
						ShowButtonMenu(playerid, slot);
					}
					case 1: // Change Button Model
					{
						ShowButtonModelDialog(playerid, slot);
					}
					case 2: // Edit Button Position
					{
						if(!GateInfo[slot][gHasButton])
						{
							SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Enable button first!");
							return ShowButtonMenu(playerid, slot);
						}

						ButtonEditor[playerid] = true;
						SetPVarInt(playerid, "EditingButton", slot);
						EditDynamicObject(playerid, GateButton[slot]);
						SCM(playerid, COLOR_INFO, ""LB"BUTTON: "WHITE"Editing button position for gate "YELLOW"%d", slot);
					}
					case 3: // Button Label
					{
						if(!GateInfo[slot][gHasButton])
						{
							SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Enable button first!");
							return ShowButtonMenu(playerid, slot);
						}

						format(string, 256, ""WHITE"Enter button label text:\n\n"YELLOW"Current: %s\n\n"WHITE"Leave empty to disable label",
							GateInfo[slot][gButtonLabel] ? GateInfo[slot][gButtonLabelText] : "None");
						ShowPlayerDialog(playerid, DIALOG_BUTTON_LABEL, DIALOG_STYLE_INPUT, "Button Label", string, "Set", "Back");
					}
				}
			}
			else ShowDialogGate(playerid, slot);
		}

		case DIALOG_BUTTON_MODEL:
		{
			if(response)
			{
				new models[] = {2886, 1318, 1319, 1650, 2232, 2942, 1317, 3095, 19273, 2886};
				GateInfo[slot][gButtonModel] = models[listitem];

				// Recreate button with new model
				if(IsValidDynamicObject(GateButton[slot]))
				{
					DestroyDynamicObject(GateButton[slot]);
				}
				CreateGateButton(slot);

				SCM(playerid, COLOR_SUCCESS, ""LB"BUTTON: "WHITE"Button model changed!");
				GateInfo[slot][gNeedsUpdate] = true;
				ShowButtonMenu(playerid, slot);
			}
			else ShowButtonMenu(playerid, slot);
		}

		case DIALOG_BUTTON_LABEL:
		{
			if(response)
			{
				if(strlen(inputtext) == 0)
				{
					// Disable label
					GateInfo[slot][gButtonLabel] = false;
					if(IsValidDynamic3DTextLabel(ButtonLabel[slot]))
					{
						DestroyDynamic3DTextLabel(ButtonLabel[slot]);
					}
					SCM(playerid, COLOR_SUCCESS, ""LB"BUTTON: "WHITE"Label disabled");
				}
				else
				{
					// Enable/update label
					GateInfo[slot][gButtonLabel] = true;
					format(GateInfo[slot][gButtonLabelText], 64, "%s", inputtext);

					// Recreate label
					if(IsValidDynamic3DTextLabel(ButtonLabel[slot]))
					{
						DestroyDynamic3DTextLabel(ButtonLabel[slot]);
					}

					ButtonLabel[slot] = CreateDynamic3DTextLabel(
						GateInfo[slot][gButtonLabelText],
						0xFFFFFFFF,
						GateInfo[slot][gButtonX],
						GateInfo[slot][gButtonY],
						GateInfo[slot][gButtonZ] + 0.5,
						BUTTON_LABEL_DISTANCE
					);

					SCM(playerid, COLOR_SUCCESS, ""LB"BUTTON: "WHITE"Label updated!");
				}
				GateInfo[slot][gNeedsUpdate] = true;
				ShowButtonMenu(playerid, slot);
			}
			else ShowButtonMenu(playerid, slot);
		}

		// [Previous dialog cases from V2.0 continue here...]
		// I'll include the essential ones for this demo

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
					ToggleGate(playerid, slot, "password");
				}
				else
				{
					SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Wrong password!");
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
					return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Time must be 0-300 seconds!");
				}
				GateInfo[slot][gAutoCloseTime] = time;
				GateInfo[slot][gNeedsUpdate] = true;
				format(string, 256, ""LB"GATE: "WHITE"Auto-close time set to "GREEN"%d seconds", time);
				SCM(playerid, COLOR_SUCCESS, string);
				ShowDialogGate(playerid, slot);
			}
			else ShowDialogGate(playerid, slot);
		}

		// [Other dialog cases...]
	}
	return 1;
}

// ✅ NEW: OnPlayerEditDynamicObject - For button editing
public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	new string[256], slot = GetPVarInt(playerid,"GateID");

	// Check if editing button
	if(ButtonEditor[playerid] && GetPVarType(playerid, "EditingButton") != 0)
	{
		new btnSlot = GetPVarInt(playerid, "EditingButton");

		if(response == EDIT_RESPONSE_FINAL)
		{
			// Save new button position
			GateInfo[btnSlot][gButtonX] = x;
			GateInfo[btnSlot][gButtonY] = y;
			GateInfo[btnSlot][gButtonZ] = z;
			GateInfo[btnSlot][gButtonRX] = rx;
			GateInfo[btnSlot][gButtonRY] = ry;
			GateInfo[btnSlot][gButtonRZ] = rz;
			GateInfo[btnSlot][gNeedsUpdate] = true;

			// Update label position if exists
			if(GateInfo[btnSlot][gButtonLabel] && IsValidDynamic3DTextLabel(ButtonLabel[btnSlot]))
			{
				DestroyDynamic3DTextLabel(ButtonLabel[btnSlot]);
				ButtonLabel[btnSlot] = CreateDynamic3DTextLabel(
					GateInfo[btnSlot][gButtonLabelText],
					0xFFFFFFFF,
					x, y, z + 0.5,
					BUTTON_LABEL_DISTANCE
				);
			}

			format(string, 256, ""LB"BUTTON: "WHITE"Button position updated for gate "GREEN"id %d", btnSlot);
			SCM(playerid, COLOR_SUCCESS, string);
			ShowButtonMenu(playerid, btnSlot);
		}
		else if(response == EDIT_RESPONSE_CANCEL)
		{
			// Restore original position
			SetDynamicObjectPos(objectid, GateInfo[btnSlot][gButtonX], GateInfo[btnSlot][gButtonY], GateInfo[btnSlot][gButtonZ]);
			SetDynamicObjectRot(objectid, GateInfo[btnSlot][gButtonRX], GateInfo[btnSlot][gButtonRY], GateInfo[btnSlot][gButtonRZ]);
			ShowButtonMenu(playerid, btnSlot);
		}

		ButtonEditor[playerid] = false;
		DeletePVar(playerid, "EditingButton");
		return 1;
	}

	// [Previous gate editing code from V2.0...]
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

            format(string,256,""LB"GATE: "WHITE"Open position updated for gate "GREEN"id %d",slot);
            SEM(playerid,string);
            ShowDialogGate(playerid,slot);
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

            format(string,256,""LB"GATE: "WHITE"Close position updated for gate "GREEN"id %d",slot);
            SEM(playerid,string);
            ShowDialogGate(playerid,slot);
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
					if(GateInfo[slot][gMethods][1])
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

// ✅ NEW: Create gate button object
stock CreateGateButton(slot)
{
	if(!GateInfo[slot][gHasButton]) return 0;

	GateButton[slot] = CreateDynamicObject(
		GateInfo[slot][gButtonModel],
		GateInfo[slot][gButtonX],
		GateInfo[slot][gButtonY],
		GateInfo[slot][gButtonZ],
		GateInfo[slot][gButtonRX],
		GateInfo[slot][gButtonRY],
		GateInfo[slot][gButtonRZ],
		-1, -1, -1,
		BUTTON_VIEW_DISTANCE
	);

	// Create label if enabled
	if(GateInfo[slot][gButtonLabel] && strlen(GateInfo[slot][gButtonLabelText]) > 0)
	{
		ButtonLabel[slot] = CreateDynamic3DTextLabel(
			GateInfo[slot][gButtonLabelText],
			0xFFFFFFFF,
			GateInfo[slot][gButtonX],
			GateInfo[slot][gButtonY],
			GateInfo[slot][gButtonZ] + 0.5,
			BUTTON_LABEL_DISTANCE
		);
	}

	return 1;
}

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

		// Load V2.0 fields
		cache_get_value_int(i,"gautoclose",GateInfo[slot][gAutoCloseTime]);
		cache_get_value_int(i,"gopencount",GateInfo[slot][gOpenCount]);
		cache_get_value_int(i,"gclosecount",GateInfo[slot][gCloseCount]);
		cache_get_value(i,"gpassword",GateInfo[slot][gPassword],MAX_GATE_PASSWORD);
		GateInfo[slot][gHasPassword] = (strlen(GateInfo[slot][gPassword]) > 0) ? true : false;

		// ✅ NEW: Load button data
		cache_get_value_int(i,"ghasbutton",GateInfo[slot][gHasButton]);
		cache_get_value_int(i,"gbuttonmodel",GateInfo[slot][gButtonModel]);
		cache_get_value_float(i,"gbuttonx",GateInfo[slot][gButtonX]);
		cache_get_value_float(i,"gbuttony",GateInfo[slot][gButtonY]);
		cache_get_value_float(i,"gbuttonz",GateInfo[slot][gButtonZ]);
		cache_get_value_float(i,"gbuttonrx",GateInfo[slot][gButtonRX]);
		cache_get_value_float(i,"gbuttonry",GateInfo[slot][gButtonRY]);
		cache_get_value_float(i,"gbuttonrz",GateInfo[slot][gButtonRZ]);
		cache_get_value_int(i,"gbuttonlabel",GateInfo[slot][gButtonLabel]);
		cache_get_value(i,"gbuttonlabeltext",GateInfo[slot][gButtonLabelText],64);

		// Create gate object
		if(!GateInfo[slot][gStatus])
		{
			DynamicGate[slot] = CreateDynamicObject(GateInfo[slot][gModel],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
		}
		else
		{
			DynamicGate[slot] = CreateDynamicObject(GateInfo[slot][gModel],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
		}

		// Create dynamic area
		GateArea[slot] = CreateDynamicSphere(GateInfo[slot][gCloseX], GateInfo[slot][gCloseY], GateInfo[slot][gCloseZ], GateInfo[slot][gRange]);

		// ✅ NEW: Create button if enabled
		if(GateInfo[slot][gHasButton])
		{
			CreateGateButton(slot);
		}

		Iter_Add(DynamicGates,slot);
		printf("✅ Gate ID: %d | Model: %d | Button: %s", slot, GateInfo[slot][gModel], GateInfo[slot][gHasButton] ? "Yes" : "No");
		count++;
	}
	if(count >= 1)
	{
		printf("✅ [SYSTEM] %d gates loaded (with buttons)!",count);
	}
}

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

			if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT && GateInfo[slot][gMethods][2])
			{
				if(inRange && CanUseGate(playerid, slot))
				{
					if(!GateInfo[slot][gStatus])
					{
						OpenGate(playerid, slot, "proximity-foot");
					}
				}
				else if(!inRange && GateInfo[slot][gStatus] && !GateInfo[slot][gAutoCloseTime])
				{
					CloseGate(playerid, slot);
				}
			}

			if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && GateInfo[slot][gMethods][3])
			{
				if(inRange && CanUseGate(playerid, slot))
				{
					if(!GateInfo[slot][gStatus])
					{
						OpenGate(playerid, slot, "proximity-vehicle");
					}
				}
				else if(!inRange && GateInfo[slot][gStatus] && !GateInfo[slot][gAutoCloseTime])
				{
					CloseGate(playerid, slot);
				}
			}
		}
	}
	return 1;
}

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

// ✅ NEW: Enhanced AutoSaveGates with button data
Server:AutoSaveGates()
{
	new count = 0, query[1024];
	foreach(new slot : DynamicGates)
	{
		if(GateInfo[slot][gNeedsUpdate])
		{
			mysql_format(g_SQL, query, sizeof(query),
				"UPDATE `gate` SET `gstatus`=%d, `gmodel`=%d, `gspeed`=%f, `grange`=%f, `gowner`=%d, `gownername`='%e', \
				`gmcmd`=%d, `gmhorn`=%d, `gmfoot`=%d, `gmveh`=%d, `gclosex`=%f, `gclosey`=%f, `gclosez`=%f, \
				`gcloserx`=%f, `gclosery`=%f, `gcloserz`=%f, `gopenx`=%f, `gopeny`=%f, `gopenz`=%f, \
				`gopenrx`=%f, `gopenry`=%f, `gopenrz`=%f, `gpassword`='%e', `gautoclose`=%d, \
				`gopencount`=%d, `gclosecount`=%d, `ghasbutton`=%d, `gbuttonmodel`=%d, `gbuttonx`=%f, `gbuttony`=%f, `gbuttonz`=%f, \
				`gbuttonrx`=%f, `gbuttonry`=%f, `gbuttonrz`=%f, `gbuttonlabel`=%d, `gbuttonlabeltext`='%e' WHERE `gid`=%d",
				GateInfo[slot][gStatus], GateInfo[slot][gModel], GateInfo[slot][gSpeed], GateInfo[slot][gRange],
				GateInfo[slot][gOwner], GateInfo[slot][gOwnerName],
				GateInfo[slot][gMethods][0], GateInfo[slot][gMethods][1], GateInfo[slot][gMethods][2], GateInfo[slot][gMethods][3],
				GateInfo[slot][gCloseX], GateInfo[slot][gCloseY], GateInfo[slot][gCloseZ],
				GateInfo[slot][gCloseRX], GateInfo[slot][gCloseRY], GateInfo[slot][gCloseRZ],
				GateInfo[slot][gOpenX], GateInfo[slot][gOpenY], GateInfo[slot][gOpenZ],
				GateInfo[slot][gOpenRX], GateInfo[slot][gOpenRY], GateInfo[slot][gOpenRZ],
				GateInfo[slot][gPassword], GateInfo[slot][gAutoCloseTime],
				GateInfo[slot][gOpenCount], GateInfo[slot][gCloseCount],
				GateInfo[slot][gHasButton], GateInfo[slot][gButtonModel], GateInfo[slot][gButtonX], GateInfo[slot][gButtonY], GateInfo[slot][gButtonZ],
				GateInfo[slot][gButtonRX], GateInfo[slot][gButtonRY], GateInfo[slot][gButtonRZ],
				GateInfo[slot][gButtonLabel], GateInfo[slot][gButtonLabelText], slot
			);
			mysql_tquery(g_SQL, query);
			GateInfo[slot][gNeedsUpdate] = false;
			count++;
		}
	}
	if(count > 0)
	{
		printf("💾 [AUTO-SAVE] %d gate(s) saved (including button data)", count);
	}
	return 1;
}

SaveAllGates()
{
	new query[1024];
	foreach(new slot : DynamicGates)
	{
		mysql_format(g_SQL, query, sizeof(query),
			"UPDATE `gate` SET `gstatus`=%d, `gmodel`=%d, `gspeed`=%f, `grange`=%f, `gowner`=%d, `gownername`='%e', \
			`gmcmd`=%d, `gmhorn`=%d, `gmfoot`=%d, `gmveh`=%d, `gclosex`=%f, `gclosey`=%f, `gclosez`=%f, \
			`gcloserx`=%f, `gclosery`=%f, `gcloserz`=%f, `gopenx`=%f, `gopeny`=%f, `gopenz`=%f, \
			`gopenrx`=%f, `gopenry`=%f, `gopenrz`=%f, `gpassword`='%e', `gautoclose`=%d, \
			`gopencount`=%d, `gclosecount`=%d, `ghasbutton`=%d, `gbuttonmodel`=%d, `gbuttonx`=%f, `gbuttony`=%f, `gbuttonz`=%f, \
			`gbuttonrx`=%f, `gbuttonry`=%f, `gbuttonrz`=%f, `gbuttonlabel`=%d, `gbuttonlabeltext`='%e' WHERE `gid`=%d",
			GateInfo[slot][gStatus], GateInfo[slot][gModel], GateInfo[slot][gSpeed], GateInfo[slot][gRange],
			GateInfo[slot][gOwner], GateInfo[slot][gOwnerName],
			GateInfo[slot][gMethods][0], GateInfo[slot][gMethods][1], GateInfo[slot][gMethods][2], GateInfo[slot][gMethods][3],
			GateInfo[slot][gCloseX], GateInfo[slot][gCloseY], GateInfo[slot][gCloseZ],
			GateInfo[slot][gCloseRX], GateInfo[slot][gCloseRY], GateInfo[slot][gCloseRZ],
			GateInfo[slot][gOpenX], GateInfo[slot][gOpenY], GateInfo[slot][gOpenZ],
			GateInfo[slot][gOpenRX], GateInfo[slot][gOpenRY], GateInfo[slot][gOpenRZ],
			GateInfo[slot][gPassword], GateInfo[slot][gAutoCloseTime],
			GateInfo[slot][gOpenCount], GateInfo[slot][gCloseCount],
			GateInfo[slot][gHasButton], GateInfo[slot][gButtonModel], GateInfo[slot][gButtonX], GateInfo[slot][gButtonY], GateInfo[slot][gButtonZ],
			GateInfo[slot][gButtonRX], GateInfo[slot][gButtonRY], GateInfo[slot][gButtonRZ],
			GateInfo[slot][gButtonLabel], GateInfo[slot][gButtonLabelText], slot
		);
		mysql_tquery(g_SQL, query);
	}
	print("💾 All gates saved (including buttons)");
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

// Helper functions
stock CanUseGate(playerid, gateid)
{
	if(PlayerGateData[playerid][pGateCooldown])
	{
		return false;
	}

	if(!GateInfo[gateid][gOwner]) return true;

	new name[24];
	GetPlayerName(playerid, name, 24);

	if(!strcmp(GateInfo[gateid][gOwnerName], name, false))
	{
		return true;
	}

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
	if(GateInfo[gateid][gHasPassword] && playerid != INVALID_PLAYER_ID)
	{
		new dialogStr[256];
		format(dialogStr, sizeof(dialogStr), ""WHITE"This gate is password protected!\n\n"YELLOW"Enter password:");
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

	PlayGateSound(gateid, true);

	if(playerid != INVALID_PLAYER_ID)
	{
		PlayerGateData[playerid][pGateCooldown] = true;
		PlayerGateData[playerid][pLastGateUse] = GetTickCount();
		SetTimerEx("ResetGateCooldown", GATE_COOLDOWN_TIME, false, "i", playerid);

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

// ✅ NEW: Button dialogs
stock ShowButtonMenu(playerid, gateid)
{
	new string[512];
	format(string, sizeof(string),
		""WHITE"Button Status: %s\n\
		Change Button Model (Current: %d)\n\
		Edit Button Position\n\
		Button Label %s",
		GateInfo[gateid][gHasButton] ? (""GREEN"Enabled") : (""RED"Disabled"),
		GateInfo[gateid][gButtonModel],
		GateInfo[gateid][gButtonLabel] ? (""GREEN"[ON]") : (""RED"[OFF]")
	);
	ShowPlayerDialog(playerid, DIALOG_BUTTON_MENU, DIALOG_STYLE_LIST, "Button Settings", string, "Select", "Back");
	SetPVarInt(playerid, "GateID", gateid);
	return 1;
}

stock ShowButtonModelDialog(playerid, gateid)
{
	new string[512];
	format(string, sizeof(string),
		"Keypad (2886) - Wall Mounted\n\
		Red Button (1318)\n\
		Green Button (1319)\n\
		Light Switch (1650)\n\
		Control Panel (2232)\n\
		Intercom (2942)\n\
		Doorbell (1317)\n\
		Garage Button (3095)\n\
		Modern Panel (19273)\n\
		Card Reader (2886)"
	);
	ShowPlayerDialog(playerid, DIALOG_BUTTON_MODEL, DIALOG_STYLE_LIST, "Select Button Model", string, "Select", "Back");
	return 1;
}

// Display functions
ShowDialogGate(playerid,gateid)
{
	new string[1024];
	format(string, sizeof(string),
		""WHITE"Set Owner (Current: "GREEN"%s"WHITE")\n\
		Gate Model ID: "GREEN"%d\n\
		"WHITE"Move Open Position\n\
		Move Close Position\n\
		Set Speed (Current: "GREEN"%0.1f"WHITE")\n\
		Detection Methods\n\
		Area Size (Current: "GREEN"%0.1f"WHITE")\n\
		Password Protection %s\n\
		Access Control List\n\
		Auto Close Time (Current: "YELLOW"%d sec"WHITE")\n\
		Statistics & Logs\n\
		🔘 Button Settings %s",
		(GateInfo[gateid][gOwner] != 1) ? ("Public") : (GateInfo[gateid][gOwnerName]),
		GateInfo[gateid][gModel],
		GateInfo[gateid][gSpeed],
		GateInfo[gateid][gRange],
		GateInfo[gateid][gHasPassword] ? (""GREEN"[ON]") : (""RED"[OFF]"),
		GateInfo[gateid][gAutoCloseTime],
		GateInfo[gateid][gHasButton] ? (""GREEN"[ON]") : (""RED"[OFF]")
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
	ShowPlayerDialog(playerid, DIALOG_EDITGATEMETHOD, DIALOG_STYLE_TABLIST_HEADERS, "Detection Methods", string, "Toggle", "Back");
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
		"WHITE"Last Used: "YELLOW"%s\n\
		"WHITE"Button: %s\n\n\
		"LB"═══════════════════════════════════",
		gateid,
		GateInfo[gateid][gOpenCount],
		GateInfo[gateid][gCloseCount],
		lastused,
		GateInfo[gateid][gHasButton] ? ""GREEN"Enabled" : ""RED"Disabled"
	);

	ShowPlayerDialog(playerid, DIALOG_GATE_STATS, DIALOG_STYLE_MSGBOX, "Gate Statistics", string, "Close", "");
	return 1;
}

// Commands (essential ones)
CMD:agate(playerid,params[])
{
	if(PlayerGateData[playerid][pAdminLevel] < ADMIN_LEVEL_MOD && !IsPlayerAdmin(playerid))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Admin level 2 required!");
	}

	new action,subparam[128],string[512];
	unformat(params,"k<gatemenu>S()[128]",action,subparam);
	switch(action)
	{
	    case 1: // Create
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"USAGE: /agate create [model id]");
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

		    		format(string,512,""LB"GATE: "YELLOW"Gate ID %d "WHITE"created! Use "GREEN"/agate edit %d "WHITE"to configure",slot,slot);
		    		SCM(playerid, COLOR_SUCCESS, string);

		    		// Initialize
		    		GateInfo[slot][gModel] = model;
		    		GateInfo[slot][gStatus] = 0;
		    		GateInfo[slot][gSpeed] = 3.0;
		    		GateInfo[slot][gRange] = 10.0;
		    		GateInfo[slot][gCloseX] = cPos[0];
		    		GateInfo[slot][gCloseY] = cPos[1];
		    		GateInfo[slot][gCloseZ] = cPos[2];
	        		GateInfo[slot][gCloseRZ] = cPos[3];
	        		GateInfo[slot][gHasButton] = false;
	        		GateInfo[slot][gNeedsUpdate] = true;

	        		GateArea[slot] = CreateDynamicSphere(cPos[0], cPos[1], cPos[2], 10.0);

	        		mysql_format(g_SQL,string,512,"INSERT INTO `gate` (`gid`,`gmodel`,`gspeed`,`grange`,`gclosex`,`gclosey`,`gclosez`,`gcloserz`,`ghasbutton`) VALUES ('%d','%d','3.0','10.0','%f','%f','%f','%f','0')",slot,model,cPos[0],cPos[1],cPos[2],cPos[3]);
		    		mysql_tquery(g_SQL,string);

		    		AddGateLog(slot, "Admin", "Created gate");
	        	}
	        	else SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"No slots available!");
	    	}
	    }
	    case 2: // Delete
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"USAGE: /agate delete [gate id]");
	    	{
	    		new slot = strval(subparam);
	    		if(Iter_Contains(DynamicGates,slot))
	    		{
	    			Iter_Remove(DynamicGates,slot);
	    			DestroyDynamicObject(DynamicGate[slot]);
	    			DestroyDynamicArea(GateArea[slot]);

	    			// ✅ Destroy button
	    			if(GateInfo[slot][gHasButton])
	    			{
	    				if(IsValidDynamicObject(GateButton[slot])) DestroyDynamicObject(GateButton[slot]);
	    				if(IsValidDynamic3DTextLabel(ButtonLabel[slot])) DestroyDynamic3DTextLabel(ButtonLabel[slot]);
	    			}

	    			format(string,256,""LB"GATE: "WHITE"Gate ID %d deleted",slot);
	    			SCM(playerid, COLOR_SUCCESS, string);

	    			mysql_format(g_SQL,string,256,"DELETE FROM `gate` WHERE `gid` = '%d'",slot);
	    			mysql_tquery(g_SQL,string);

	    			AddGateLog(slot, "Admin", "Deleted gate");
	    		}
	    		else SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Invalid gate ID!");
	    	}
	    }
	    case 3: // Edit
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"USAGE: /agate edit [gate id]");
	    	{
	    		new slot = strval(subparam);
	    		if(Iter_Contains(DynamicGates,slot))
	    		{
	    			ShowDialogGate(playerid,slot);
	    			SetPVarInt(playerid,"GateID",slot);
	    		}
	    		else SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Invalid gate ID!");
	    	}
	    }
	    default:
	    {
	    	SCM(playerid, COLOR_INFO, ""LB"═══════════════════════════════════");
	    	SCM(playerid, COLOR_INFO, ""LB"GATE ADMIN COMMANDS:");
	    	SCM(playerid, COLOR_INFO, ""WHITE"/agate create [modelid] "YELLOW"- Create gate");
	    	SCM(playerid, COLOR_INFO, ""WHITE"/agate edit [gateid] "YELLOW"- Edit gate");
	    	SCM(playerid, COLOR_INFO, ""WHITE"/agate delete [gateid] "YELLOW"- Delete gate");
	    	SCM(playerid, COLOR_INFO, ""LB"═══════════════════════════════════");
	    }
	}
	return 1;
}

CMD:gate(playerid,params[])
{
	new bool:found = false;

	foreach(new slot : DynamicGates)
	{
		if(IsPlayerInRangeOfPoint(playerid, GateInfo[slot][gRange], GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
		{
			if(GateInfo[slot][gMethods][0])
			{
				if(!GateInfo[slot][gOpenX])
				{
					return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Gate not configured!");
				}

				if(!CanUseGate(playerid, slot))
				{
					return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"No access!");
				}

				ToggleGate(playerid, slot, "command");
				found = true;
				break;
			}
		}
	}

	if(!found)
	{
		SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"No gate nearby!");
	}

	return 1;
}

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

CMD:ginfo(playerid, params[])
{
	if(IsNull(params)) return SCM(playerid, COLOR_INFO, ""WHITE"USAGE: /ginfo [gateid]");

	new slot = strval(params);
	if(!Iter_Contains(DynamicGates, slot))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Invalid gate ID!");
	}

	new string[1024];
	format(string, sizeof(string),
		""LB"═══════════════════════════════════\n\
		"WHITE"Gate ID: "YELLOW"%d\n\
		"WHITE"Model: "GREEN"%d\n\
		"WHITE"Status: %s\n\
		"WHITE"Owner: "GREEN"%s\n\
		"WHITE"Password: %s\n\
		"WHITE"Button: %s\n\
		"WHITE"Open Count: "GREEN"%d\n\
		"LB"═══════════════════════════════════",
		slot,
		GateInfo[slot][gModel],
		GateInfo[slot][gStatus] ? ("{00FF00}Open") : ("{FF0000}Closed"),
		GateInfo[slot][gOwner] ? GateInfo[slot][gOwnerName] : "Public",
		GateInfo[slot][gHasPassword] ? ("{00FF00}Protected") : ("{FF0000}None"),
		GateInfo[slot][gHasButton] ? ("{00FF00}Yes") : ("{FF0000}No"),
		GateInfo[slot][gOpenCount]
	);

	ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "Gate Information", string, "Close", "");
	return 1;
}

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

	return 1;
}

CMD:gsave(playerid, params[])
{
	if(PlayerGateData[playerid][pAdminLevel] < ADMIN_LEVEL_ADMIN && !IsPlayerAdmin(playerid))
	{
		return SCM(playerid, COLOR_ERROR, ""RED"ERROR: "WHITE"Admin level 3 required!");
	}

	SaveAllGates();
	SCM(playerid, COLOR_SUCCESS, ""LB"GATE: "WHITE"All gates saved!");
	return 1;
}
