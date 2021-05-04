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
==============================================================================*/

//=============================[Include & Defines]==============================

#include <a_samp>
#include <sscanf2>      		// sscanf plugin by Y_Less
#include <streamer>     		// streamer plugin by Incognito
#include <a_mysql>              // MySQL plugin by BlueG
#include <YSI\y_iterate>        // YSI by Y_Less
#include <zcmd>


#define SEM(%0,%1) SendClientMessage(%0,0xBFC0C200,%1) 					// SEM = Send Error Message by 	Myself
#define Loop(%0,%1) for(new %0 = 0; %0 < %1; %0++)                      // Loop                     by 	Myself
#define IsNull(%1) ((!(%1[0])) || (((%1[0]) == '\1') && (!(%1[1]))))    // IsNull macro 			by 	Y_Less				by 	RyDeR`
#define Server:%0(%1) forward %0(%1); public %0(%1)
#define Pressed(%0) ((newkeys & %0) && !(oldkeys & %0))

#define LB 		"{33CCFF}"
#define YELLOW 	"{FFFF00}"
#define GREEN 	"{00FF00}"
#define LG 		"{33AA33}"
#define WHITE 	"{FFFFFF}"

#define MAX_GATE            	100

#define MYSQL_HOST 				"localhost"
#define MYSQL_USER 				"root"
#define MYSQL_PASSWORD 			""
#define MYSQL_DATABASE 			"mgrp"

#define DIALOG_GATE 			0305
#define DIALOG_EDITGATEMODEL 	0306
#define DIALOG_EDITGATESPEED	0307
#define DIALOG_EDITGATEMETHOD	0308
#define DIALOG_EDITSETOWNER		0309
#define DIALOG_EDITSETOWNERNAME 0310
#define DIALOG_EDITAREASIZE		0311

new MySQL: g_SQL;

new Iterator:DynamicGates<MAX_GATE>;
new DynamicGate[MAX_GATE];
new ObjectEditor[MAX_GATE];

enum gInfo
{
	gModel,
	gStatus, //0 = close, 1 = open
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
	gMethods[4]
};
new GateInfo[MAX_GATE][gInfo];

public OnFilterScriptInit()
{
	print("|======================================|");
    print("|==========[Gate System V1.0]==========|");
    print("|=============[BY MRS5TEEN]============|");
    print("|====[TERIMAKSIH TELAH MENGGUNAKAN]====|");
    print("|======================================|");
    
    new MySQLOpt: option_id = mysql_init_options();

	mysql_set_option(option_id, AUTO_RECONNECT, true); // it automatically reconnects when loosing connection to mysql server

	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id); // AUTO_RECONNECT is enabled for this connection handle only
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("MySQL connection failed.");
		return 1;
	}
	mysql_tquery(g_SQL,"SELECT * FROM `gate`","LoadGates");
	print("[SYSTEM] Database 'gate' telah sukses terkoneksi!");

	SetTimer("NearGate",250,true);
    return 1;
}

public OnPlayerConnect(playerid)
{
	mysql_tquery(g_SQL,"SELECT * FROM `gateowner`","LoadGateOwner");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	new slot = GetPVarInt(playerid,"GateID"),string[256];
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
							format(string,256,""WHITE"Player (Current: "GREEN"%s"WHITE")\nPublic",GateInfo[slot][gOwnerName]);
							ShowPlayerDialog(playerid,DIALOG_EDITSETOWNER,DIALOG_STYLE_LIST,"Gate Configuration > Set Owner",string,"Select","Back");
						}
						else
						{
							format(string,256,""WHITE"Player\nPublic");
							ShowPlayerDialog(playerid,DIALOG_EDITSETOWNER,DIALOG_STYLE_LIST,"Gate Configuration > Set Owner",string,"Select","Back");
						}
					}
					case 1: //Gate Model
					{
						ShowPlayerDialog(playerid,DIALOG_EDITGATEMODEL,DIALOG_STYLE_INPUT,"Gate Configuration > Gate Model","Masukan model id yang spesifik untuk mengganti model gate","Confirm","Back");
					}
					case 2: //Move Open Position
					{/*
						new playername[MAX_PLAYER_NAME];
						if(ObjectEditor[slot] != INVALID_PLAYER_ID)
						{
							new editor = ObjectEditor[slot];
							GetPlayerName(editor,playername,sizeof(playername));
							if(GetPVarType(editor,"EditingGate") == slot)
							{
								format(string,sizeof(string),"ERROR: %s sedang mengedit gate id tersebut!",playername);
								return SEM(playerid,string);
							}
						}*/
						format(string,sizeof(string),"GATE: "WHITE"Anda sedang memilih gate "YELLOW"id %d",slot);
						ObjectEditor[slot] = playerid;
						SetPVarInt(playerid,"EditingGate",slot);
						SetPVarInt(playerid,"GateOpen",slot);
						EditDynamicObject(playerid,DynamicGate[slot]);
						SendClientMessage(playerid,0x33CCFFFF,string);
					}
					case 3: //Move Close Position
					{/*
						new playername[MAX_PLAYER_NAME];
						if(ObjectEditor[slot] != INVALID_PLAYER_ID)
						{
							new editor = ObjectEditor[slot];
							GetPlayerName(editor,playername,sizeof(playername));
							if(GetPVarType(editor,"EditingGate") == slot)
							{
								format(string,sizeof(string),"ERROR: %s sedang mengedit gate id tersebut!",playername);
								return SEM(playerid,string);
							}
						}*/
						format(string,sizeof(string),"GATE: "WHITE"Anda sedang memilih gate "YELLOW"id %d",slot);
						ObjectEditor[slot] = playerid;
						SetPVarInt(playerid,"EditingGate",slot);
						SetPVarInt(playerid,"GateClose",slot);
						EditDynamicObject(playerid,DynamicGate[slot]);
						SendClientMessage(playerid,0x33CCFFFF,string);
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
				}
			}
		}
		case DIALOG_EDITAREASIZE:
		{
			if(response)
			{
				new Float:size = floatstr(inputtext);
				if(size > 30.0 || size < 1.0) return SEM(playerid,"ERROR: Area tidak boleh kurang dari 1.0 dan lebih dari 30.0!");
				GateInfo[slot][gRange] = size;
				format(string,256,""LB"GATE: "WHITE"Area size "YELLOW"id %d"WHITE" telah di set ke "GREEN"%0.1f",slot,size);
				SEM(playerid,string);
				mysql_format(g_SQL,string,256,"UPDATE `gate` SET `grange` = %f WHERE `gid` = '%d'",size,slot);
				mysql_tquery(g_SQL,string);
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
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gowner` = 0, `gownername` = '' WHERE `gid` = '%d'",slot);
						mysql_tquery(g_SQL,string);
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
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gowner` = 1, `gownername` = '%e' WHERE `gid` = '%d'",name,slot);
						mysql_tquery(g_SQL,string);
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
				ShowDialogGate(playerid,slot);
				mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gmodel` = '%d' WHERE `gid` = '%d'",model,slot);
				mysql_tquery(g_SQL,string);
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
				ShowDialogGate(playerid,slot);
				mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gspeed` = '%f' WHERE `gid` = '%d'",speed,slot);
				mysql_tquery(g_SQL,string);
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
						if(!GateInfo[slot][gMethods][0])
						{
							GateInfo[slot][gMethods][0] = 1;
						}
						else
						{
							GateInfo[slot][gMethods][0] = 0;
						}
						ShowDialogMethods(playerid,slot);
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gmcmd` = '%d' WHERE `gid` = '%d'",GateInfo[slot][gMethods][0],slot);
						mysql_tquery(g_SQL,string);
					}
					case 1: //Horn
					{
						if(!GateInfo[slot][gMethods][1])
						{
							GateInfo[slot][gMethods][1] = 1;
						}
						else
						{
							GateInfo[slot][gMethods][1] = 0;
						}
						ShowDialogMethods(playerid,slot);
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gmhorn` = '%d' WHERE `gid` = '%d'",GateInfo[slot][gMethods][1],slot);
						mysql_tquery(g_SQL,string);
					}
					case 2: //Proximity On-Foot
					{
						if(!GateInfo[slot][gMethods][2])
						{
							GateInfo[slot][gMethods][2] = 1;
						}
						else
						{
							GateInfo[slot][gMethods][2] = 0;
						}
						ShowDialogMethods(playerid,slot);
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gmfoot` = '%d' WHERE `gid` = '%d'",GateInfo[slot][gMethods][2],slot);
						mysql_tquery(g_SQL,string);
					}
					case 3: //Proximity Vehicle
					{
						if(!GateInfo[slot][gMethods][3])
						{
							GateInfo[slot][gMethods][3] = 1;
						}
						else
						{
							GateInfo[slot][gMethods][3] = 0;
						}
						ShowDialogMethods(playerid,slot);
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gmveh` = '%d' WHERE `gid` = '%d'",GateInfo[slot][gMethods][3],slot);
						mysql_tquery(g_SQL,string);
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

            mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gopenx` = '%f',`gopeny` = '%f',`gopenz` = '%f',`gopenrx` = '%f',`gopenry` = '%f',`gopenrz` = '%f' WHERE `gid` = '%d'",x,y,z,rx,ry,rz,slot);
            mysql_tquery(g_SQL,string);

            format(string,256,""LB"GATE: "WHITE"Anda telah mengedit "YELLOW"'Move Open Position' "WHITE"pada gate "GREEN"id %d",slot);
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

            mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gclosex` = '%f',`gclosey` = '%f',`gclosez` = '%f',`gcloserx` = '%f',`gclosery` = '%f',`gcloserz` = '%f' WHERE `gid` = '%d'",x,y,z,rx,ry,rz,slot);
            mysql_tquery(g_SQL,string);

            format(string,256,""LB"GATE: "WHITE"Anda telah mengedit "YELLOW"'Move Close Position' "WHITE"pada gate "GREEN"id %d",slot);
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
	new string[256],name[24];
	GetPlayerName(playerid,name,24);
	foreach(new slot : DynamicGates)
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
		{
			if(!GateInfo[slot][gOpenX]) return 1;
			if(Pressed(KEY_CROUCH))
			{
				if(IsPlayerInRangeOfPoint(playerid, GateInfo[slot][gRange], GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
				{
					if(GateInfo[slot][gMethods][1])
					{
						if(!GateInfo[slot][gOwner])
						{
							if(!GateInfo[slot][gStatus]) //Tutup
							{
								MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
								GateInfo[slot][gStatus] = 1;
								mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
								mysql_tquery(g_SQL,string);
							}
							else
							{
								MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gSpeed],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
								GateInfo[slot][gStatus] = 0;
								mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 0 WHERE `gid` = '%d'",slot);
								mysql_tquery(g_SQL,string);
							}
						}
						else
						{
							if(strfind(GateInfo[slot][gOwnerName],name) != -1)
							{
								if(!GateInfo[slot][gStatus]) //Tutup
								{
									MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
									GateInfo[slot][gStatus] = 1;
									mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
									mysql_tquery(g_SQL,string);
								}
								else
								{
									MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gSpeed],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
									GateInfo[slot][gStatus] = 0;
									mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 0 WHERE `gid` = '%d'",slot);
									mysql_tquery(g_SQL,string);
								}
							}
						}	
					}	
				}
			}
		}
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
		if(!GateInfo[slot][gStatus])
		{
			DynamicGate[slot] = CreateDynamicObject(GateInfo[slot][gModel],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
		}
		else
		{
			DynamicGate[slot] = CreateDynamicObject(GateInfo[slot][gModel],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
		}
		Iter_Add(DynamicGates,slot);
		printf("Gate ID: %d Gate Model: %d",slot,GateInfo[slot][gModel]);
		count++;
	}
	if(count >= 1)
	{
		printf("[SYSTEM] %d gates telah berhasil dimuat",count);
	}	
}

Server:NearGate(playerid)
{
	new string[256],name[24];
	GetPlayerName(playerid,name,24);
	foreach(new slot : DynamicGates)
	{
		if(IsPlayerInRangeOfPoint(playerid, GateInfo[slot][gRange], GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
		{
			if(!GateInfo[slot][gOpenX]) return 1;
			if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
			{
				if(GateInfo[slot][gMethods][2])
				{
					if(!GateInfo[slot][gOwner])
					{
						if(!GateInfo[slot][gStatus]) //Tutup
						{
							MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
							GateInfo[slot][gStatus] = 1;
							mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
							mysql_tquery(g_SQL,string);
						}
					}
					else
					{
						if(strfind(GateInfo[slot][gOwnerName],name) != -1)
						{
							if(!GateInfo[slot][gStatus]) //Tutup
							{
								MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
								GateInfo[slot][gStatus] = 1;
								mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
								mysql_tquery(g_SQL,string);
							}
						}
					}
				}	
			}
			if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
			{
				if(GateInfo[slot][gMethods][3])
				{
					if(!GateInfo[slot][gOwner])
					{
						if(!GateInfo[slot][gStatus]) //Tutup
						{
							MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
							GateInfo[slot][gStatus] = 1;
							mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
							mysql_tquery(g_SQL,string);
						}
					}
					else
					{
						if(strfind(GateInfo[slot][gOwnerName],name) != -1)
						{
							if(!GateInfo[slot][gStatus]) //Tutup
							{
								MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
								GateInfo[slot][gStatus] = 1;
								mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
								mysql_tquery(g_SQL,string);
							}
						}
					}	
				}
			}
		}
		else
		{
			if(GateInfo[slot][gMethods][3])
			{
				if(!GateInfo[slot][gOwner])
				{
					MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gSpeed],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
					GateInfo[slot][gStatus] = 0;
					mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 0 WHERE `gid` = '%d'",slot);
					mysql_tquery(g_SQL,string);
				}
				else
				{
					if(strfind(GateInfo[slot][gOwnerName],name) != -1)
					{
						MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gSpeed],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
						GateInfo[slot][gStatus] = 0;
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 0 WHERE `gid` = '%d'",slot);
						mysql_tquery(g_SQL,string);
					}
				}	
			}	
		}
	}
	return 1;
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
CMD:agate(playerid,params[])
{
	new action,subparam[128],string[256];
	unformat(params,"k<gatemenu>S()[128]",action,subparam);
	switch(action)
	{
	    case 1:
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"KEGUNAAN: /agate create [model id]");
	    	{
	    		new slot = Iter_Free(DynamicGates);
	    		if(slot != cellmin)
	    		{
		    		new model = strval(subparam); new Float:cPos[4];
		    		GetPlayerPos(playerid,cPos[0],cPos[1],cPos[2]);
		    		GetPlayerFacingAngle(playerid,cPos[3]);
		    		DynamicGate[slot] = CreateDynamicObject(model,cPos[0],cPos[1],cPos[2],0.0,0.0,cPos[3],GetPlayerVirtualWorld(playerid),GetPlayerInterior(playerid)); //slot = DynamicGate[slot];
			    	Iter_Add(DynamicGates,slot);

		    		format(string,256,""LB"GATE: "YELLOW"Gate ID %d "WHITE"dengan "GREEN"model id %d "WHITE"telah berhasil dibuat, total gate: "LG"%d",slot,model,Iter_Count(DynamicGates));
		    		SEM(playerid,string);

		    		mysql_format(g_SQL,string,256,"INSERT INTO `gate` (`gid`,`gstatus`,`gmodel`,`gspeed`,`grange`,`gclosex`,`gclosey`,`gclosez`,`gcloserz`) VALUES ('%d','0','%d','3.0','10.0','%f','%f','%f','%f')",slot,model,cPos[0],cPos[1],cPos[2],cPos[3]);
		    		mysql_tquery(g_SQL,string);
		    		GateInfo[slot][gModel] = model; GateInfo[slot][gStatus] = 0;
		    		GateInfo[slot][gSpeed] = 3.0;
		    		GateInfo[slot][gRange] = 10.0;
		    		GateInfo[slot][gCloseX] = cPos[0]; GateInfo[slot][gCloseY] = cPos[1]; GateInfo[slot][gCloseZ] = cPos[2];
	        		GateInfo[slot][gCloseRX] = 0.0; GateInfo[slot][gCloseRY] = 0.0; GateInfo[slot][gCloseRZ] = cPos[3];
	        	}
	        	else SEM(playerid,"ERROR: Tidak ada slot yang tersisa!");
	    	}
	    }
	    case 2:
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"KEGUNAAN: /agate delete [gate id]");
	    	{
	    		new slot = strval(subparam);
	    		if(Iter_Contains(DynamicGates,slot))
	    		{
	    			Iter_Remove(DynamicGates,slot);
	    			DestroyDynamicObject(DynamicGate[slot]);
	    			format(string,256,""LB"GATE: "YELLOW"Gate ID %d "WHITE"telah berhasil dihapus, total gate: "LG"%d",slot,Iter_Count(DynamicGates));
	    			SEM(playerid,string);
	    			mysql_format(g_SQL,string,256,"DELETE FROM `gate` WHERE `gid` = '%d'",slot);
	    			mysql_tquery(g_SQL,string);
	    		}
	    		else SEM(playerid,"ERROR: Gate ID salah!");
	    	}
	    }
	    case 3:
	    {
	    	if(IsNull(subparam)) return SEM(playerid,"KEGUNAAN: /agate edit [gate id]");
	    	{
	    		new slot = strval(subparam);
	    		if(Iter_Contains(DynamicGates,slot))
	    		{
	    			ShowDialogGate(playerid,slot);
	    			SetPVarInt(playerid,"GateID",slot);
	    		}
	    		else SEM(playerid,"ERROR: Gate ID salah!");
	    	}
	    }
	    default:
	    {
	    	SEM(playerid,"KEGUNAAN: /agate [OPSI]");
	    	SEM(playerid,"OPSI: create,delete,edit");
	    }
	}
	return 1;
}

CMD:gate(playerid,params[])
{
	new string[256];
	foreach(new slot : DynamicGates)
	{
		if(IsPlayerInRangeOfPoint(playerid, GateInfo[slot][gRange], GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
		{
			if(GateInfo[slot][gMethods][0])
			{
				if(!GateInfo[slot][gOpenX]) return SEM(playerid,"ERROR: Terjadi kesalahan pada gate!");
				if(!GateInfo[slot][gOwner])
				{
					if(!GateInfo[slot][gStatus]) //Tutup
					{
						MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
						GateInfo[slot][gStatus] = 1;
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
						mysql_tquery(g_SQL,string);
					}
					else
					{
						MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gSpeed],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
						GateInfo[slot][gStatus] = 0;
						mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 0 WHERE `gid` = '%d'",slot);
						mysql_tquery(g_SQL,string);
					}
				}
				else
				{
					new name[24];
					GetPlayerName(playerid,name,24);
					if(strfind(GateInfo[slot][gOwnerName],name) != -1)
					{
						if(!GateInfo[slot][gStatus]) //Tutup
						{
							MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ],GateInfo[slot][gSpeed],GateInfo[slot][gOpenRX],GateInfo[slot][gOpenRY],GateInfo[slot][gOpenRZ]);
							GateInfo[slot][gStatus] = 1;
							mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 1 WHERE `gid` = '%d'",slot);
							mysql_tquery(g_SQL,string);
						}
						else
						{
							MoveDynamicObject(DynamicGate[slot],GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ],GateInfo[slot][gSpeed],GateInfo[slot][gCloseRX],GateInfo[slot][gCloseRY],GateInfo[slot][gCloseRZ]);
							GateInfo[slot][gStatus] = 0;
							mysql_format(g_SQL,string,256,"UPDATE `gate` SET `gstatus` = 0 WHERE `gid` = '%d'",slot);
							mysql_tquery(g_SQL,string);
						}
					}
				}
			}	
		}
	}
	return 1;
}

CMD:gotogate(playerid,params[])
{
	if(IsNull(params)) return SEM(playerid,"/gotogate [gateid]");
	{
		new slot = strval(params);
		SetPlayerPos(playerid,GateInfo[slot][gOpenX],GateInfo[slot][gOpenY],GateInfo[slot][gOpenZ]);
	}
	return 1;
}

CMD:gnear(playerid,params[])
{
	new string[256],count;
	if(IsNull(params)) return SEM(playerid,"KEGUNAAN: /gnear [distance]");
	{
		new Float:jarak = floatstr(params);
		format(string,256,"GATE: Detecting gate(s) around %0.1f meters from you",jarak);
		SEM(playerid,string);
		foreach(new slot : DynamicGates)
		{
			if(IsPlayerInRangeOfPoint(playerid,jarak,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]))
			{
				if(GateInfo[slot][gOwner])
				{
					format(string,256,"Gate ID: [%d] Gate Model: [%d] Gate Owner: [%s (%s)] Range from you: [%0.2f meters]",slot,GateInfo[slot][gModel],(GateInfo[slot][gOwner] != 1) ? ("Public") : ("Player"),GateInfo[slot][gOwnerName],GetPlayerDistanceFromPoint(playerid,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]));
					SEM(playerid,string);
				}
				else
				{
					format(string,256,"Gate ID: [%d] Gate Model: [%d] Gate Owner: [%s] Range from you: [%0.2f meters]",slot,GateInfo[slot][gModel],(GateInfo[slot][gOwner] != 1) ? ("Public") : ("Player"),GetPlayerDistanceFromPoint(playerid,GateInfo[slot][gCloseX],GateInfo[slot][gCloseY],GateInfo[slot][gCloseZ]));
					SEM(playerid,string);
				}
				count++;
			}
		}
		if(count > 0)
		{
			format(string,128,"GATE: %d gate(s) has been detected",count);
		}
		else
		{
			format(string,128,"GATE: There are no gates around you");
		}
		SEM(playerid,string);
	}	
	return 1;
}

CMD:check(playerid,params[])
{
	new string[128];
	if(IsNull(params)) return SEM(playerid,"/check [gateid]");
	{
		new gid = strval(params);
		format(string,128,"Gate ID: %d Gate Status: %d",gid,GateInfo[gid][gStatus]);
		SEM(playerid,string);
	}
	return 1;
}

CMD:glist(playerid,params[])
{
	new string[256];
	format(string,256,"gid\tmodel\n");
	foreach(new i : DynamicGates)
	{
		format(string,256,"%s%d\t%d\n",string,i,GateInfo[i][gModel]);
	}	
	//strcat(string,"Add\tNew");
	format(string,256,"%sAdd\tNew",string);
	ShowPlayerDialog(playerid,9991,DIALOG_STYLE_TABLIST_HEADERS,"List Gates:",string,"Select","Exit");
	return 1;
}

CMD:dpvar(playerid,params[])
{
	DeletePVar(playerid,"EditingGate");
	SEM(playerid,"deleted");
	return 1;
}

ShowDialogGate(playerid,gateid)
{
	new string[256];
	format(string,256,""WHITE"Set Owner (Current: "GREEN"%s"WHITE")\n"WHITE"Gate Model ID: "GREEN"%d\n"WHITE"Move Open Position\nMove Close Position\nSet Speed (Current: "GREEN"%0.1f"WHITE")\nDetection Methods\nArea Size (Current: "GREEN"%0.1f"WHITE")",(GateInfo[gateid][gOwner] != 1) ? ("Public") : ("Player"),GateInfo[gateid][gModel],GateInfo[gateid][gSpeed],GateInfo[gateid][gRange]);
	ShowPlayerDialog(playerid,DIALOG_GATE,DIALOG_STYLE_LIST,"Gate Configuration",string,"Select","Exit");
	return 1;
}

ShowDialogMethods(playerid,slot)
{
	new string[256];
	format(string,256,"Method\tStatus\nCommand (/gate)\t%s\nHorn\t%s\nProximity (On-Foot)\t%s\nProximity (Vehicle)\t%s",(GateInfo[slot][gMethods][0] != 1) ? ("{ff0000}Disabled") : (""GREEN"Enabled"),(GateInfo[slot][gMethods][1] != 1) ? ("{ff0000}Disabled") : (""GREEN"Enabled"),(GateInfo[slot][gMethods][2] != 1) ? ("{ff0000}Disabled") : (""GREEN"Enabled"),(GateInfo[slot][gMethods][3] != 1) ? ("{ff0000}Disabled") : (""GREEN"Enabled"));
	ShowPlayerDialog(playerid,DIALOG_EDITGATEMETHOD,DIALOG_STYLE_TABLIST_HEADERS,"Gate Configuration > Detection Methods",string,"Select","Back");
	return 1;
}