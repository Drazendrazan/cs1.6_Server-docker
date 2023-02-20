#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define OFFSET_PRIMARYWEAPON 116
#define OFFSET_C4_SLOT 372
#define m_iMapZone 235
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define fm_cs_set_user_nobuy(%1)    set_pdata_int(%1, 235, get_pdata_int(%1, 235) & ~(1<<0))

enum _:CHOICES
{
	OPTION_NONE, OPTION_NEW, OPTION_OLD, OPTION_SAVE
}

new const g_szOptions[CHOICES][] =
{
	"None", "New Guns", "Previous Guns", "Previous + Save"
}

new g_WeaponBPAmmo[] =
{
	0, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30,	120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100
};

new g_WeaponSlots[] =
{
	0, 2, 0, 1, 4, 1, 5, 1, 1, 4, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 4, 2, 1, 1, 3, 1
};

const m_iBuyingStatus = 34;
new g_szWepFile[256], g_FilePointer;
new g_pWeaponMenu, g_sWeaponMenu, g_SpawnMenu;
new g_bSave[33], g_ipPreviousWeapons[33], g_isPreviousWeapons[33];
new Array:g_PrimaryWeapons, Array:g_SecondaryWeapons;
new g_MainMenuTitle, g_PrimaryMenuTitle, g_SecondaryMenuTitle, g_PluginPrefix, g_iToggle, g_iBlockDrop, g_iHENade, g_iFlash, g_iSmoke, g_iArmorAmount, g_iNVG, g_iUnlimitedAmmo, g_iStripMode, g_iTeamMode, g_iFastSwitch, g_iCZBotSupport;
new g_szMainMenuTitle[32], g_szPriMenuTitle[32], g_szSecMenuTitle[32], g_szPrefixName[32];
new bool:g_bomb_targ, g_iEnt, iconstatus;
new CsTeams:g_MenuTeam, CsTeams:g_iPlayerTeam[33];

public plugin_init()
{
	register_plugin("Weapon Menu", "0.0.9", "SavSin");
	
	g_MainMenuTitle = register_cvar("wm_mainmenutitle", "Weapons Menu"); //Main Menu Title Cvar.
	g_PrimaryMenuTitle = register_cvar("wm_primenutitle", "Primary Weapons"); //Primary Weapons Menu Title Cvar.
	g_SecondaryMenuTitle = register_cvar("wm_secmenutitle", "Secondary Weapons"); //Secondary Weapons Menu Title Cvar.
	g_PluginPrefix = register_cvar("amx_prefix_name", "WM"); //Prefix Name Cvar.
	
	g_iToggle = register_cvar("wm_switch", "1"); //Turns plugin on and off.
	g_iBlockDrop = register_cvar("wm_blockdrop", "1"); //Blocks weapon drop.
	g_iHENade = register_cvar("wm_henade", "2"); // Amount of HE Nades given to each player.
	g_iFlash = register_cvar("wm_flash", "2"); //Amount of Flash Nades given to each player.
	g_iSmoke = register_cvar("wm_smoke", "2"); //Amount of Smoke Nades given to each player.
	g_iArmorAmount = register_cvar("wm_armor", "100"); //Amount of Armor Given to each player.
	g_iNVG = register_cvar("wm_nvg", "1"); //Give NVG's?
	g_iUnlimitedAmmo = register_cvar("wm_unlimitedammo", "1"); //Allow Unlimited ammo?
	g_iStripMode = register_cvar("wm_stripmode", "1"); //1 = Strip and keep bomb  2 = Strip All.
	g_iFastSwitch = register_cvar("wm_fastswitch", "1"); //1 = Switch to last used weapon 0 = dont
	
	g_iCZBotSupport = register_cvar("wm_czbotsupport", "0"); //1 = Rage method of CZ bot support 0 = no cz bot support.
	
	register_concmd ("amx_teammode", "cmdTeamMode", ADMIN_BAN, "0 = No teams buy. 1 = CT buy. 2 = T buy.");
	register_concmd("wmadminmenu", "cmdAdminMenu", ADMIN_RCON, "Opens the admin menu.");
	register_concmd("say wmadmin", "cmdAdminMenu", ADMIN_RCON, "Opens the admin menu.");
	
	
	register_event("CurWeapon", "eCurWeapon", "be", "1=1"); //Unlimited ammo
	
	get_pcvar_string(g_MainMenuTitle, g_szMainMenuTitle, charsmax(g_szMainMenuTitle)); //Main Menu Title Text
	get_pcvar_string(g_PrimaryMenuTitle, g_szPriMenuTitle, charsmax(g_szPriMenuTitle)); // Primary Menu Title Text
	get_pcvar_string(g_SecondaryMenuTitle, g_szSecMenuTitle, charsmax(g_szSecMenuTitle)); //Secondary Menu Title Text
	get_pcvar_string(g_PluginPrefix, g_szPrefixName, charsmax(g_szPrefixName)); //Prefix Name shows infront of plugin chat.
	
	RegisterHam(Ham_Spawn, "player", "fwdPlayerSpawn", 1); //Player Spawn Post
	
	if(get_pcvar_num(g_iCZBotSupport))
		RegisterHam(Ham_Spawn, "czbot", "fwdPlayerSpawn", 1); //Player Spawn Post
		
	RegisterHam(Ham_Touch, "func_buyzone", "fwdBuyZoneTouch", 1); //Player touches buyzone
	iconstatus = get_user_msgid("StatusIcon");
	register_event("HLTV", "Event_HLTV_NewRound", "a", "1=0", "2=0"); //New round start
	register_event("TeamInfo", "eTeamInfo", "a"); //Event Team Info.
	register_clcmd("say /guns", "cmdGuns"); //Re-Enables Gun menu
	register_clcmd("say guns", "cmdGuns"); //Re-Enables Gun menu
	register_clcmd("say_team /guns", "cmdGuns"); //Re-Enables Gun menu
	register_clcmd("say_team guns", "cmdGuns"); //Re-Enables Gun menu
	register_clcmd("drop", "blockDrop"); //Re-Enables Gun menu
	
	CreateWeaponsArray(); //Create the menus and arrays
	
	new szNum[3];
	g_SpawnMenu = menu_create(g_szMainMenuTitle, "HandleSpawnMenu"); //Create Main Menu
	
	for(new i = 1; i < sizeof(g_szOptions); i++) //Loop through all the options
	{
		num_to_str(i, szNum, charsmax(szNum));
		menu_additem(g_SpawnMenu, g_szOptions[i], szNum, 0); //Add the options to the menu
	}
	
	menu_setprop(g_SpawnMenu , MPROP_EXIT , MEXIT_NEVER); //Dont allow Menu to exit
	
	if (fm_find_ent_by_class(-1, "func_bomb_target") || fm_find_ent_by_class(-1, "info_bomb_target")) //Checks for bombsites
	{
		g_bomb_targ = true; //If there is a bomb site Set this to true
	}
}

public client_disconnect(id)
{
	g_ipPreviousWeapons[id] = 0;
	g_isPreviousWeapons[id] = 0;
	g_bSave[id] = false;
}

public client_connect(id)
{
	g_ipPreviousWeapons[id] = 0;
	g_isPreviousWeapons[id] = 0;
	g_bSave[id] = false;
}

public plugin_precache() 
{
	g_iTeamMode = register_cvar("wm_teammode", "0"); // 0 = both 1 = T only 2 = CT only.
	g_iEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_map_parameters"));
	dllfunc(DLLFunc_Spawn, g_iEnt);
	server_cmd("sv_restart 1");
}

public Event_HLTV_NewRound()
{
	
	if(!get_pcvar_num(g_iToggle))
		return PLUGIN_HANDLED;
		
	new iTeamMode;
	
	switch(clamp(get_pcvar_num(g_iTeamMode), 0, 2))
	{
		case 0: 
		{
			iTeamMode = 3;
		}
		case 1: 
		{
			g_MenuTeam = CS_TEAM_T;
			iTeamMode = 1;
		}
		case 2: 
		{
			g_MenuTeam = CS_TEAM_CT;
			iTeamMode = 2;
		}
	}
	
	set_pdata_int(g_iEnt, m_iBuyingStatus, iTeamMode, 4);
	return PLUGIN_HANDLED;
}

public fwdBuyZoneTouch(iEnt, id)
{
	if(!get_pcvar_num(g_iToggle))
		return HAM_IGNORED;
	if(is_user_connected(id) && g_iPlayerTeam[id] == g_MenuTeam)
	{
		message_begin(MSG_ONE, iconstatus, {0,0,0}, id);
		write_byte(0);
		write_string("buyzone");
		write_byte(0);
		write_byte(255);
		write_byte(0);
		message_end();
	}
	return PLUGIN_HANDLED;
}

public cmdTeamMode(id)
{
	if(!get_pcvar_num(g_iToggle))
		return PLUGIN_HANDLED;
	new arg[2];
	read_argv(1, arg, sizeof(arg));
	
	new iArg = str_to_num(arg);
	
	set_pcvar_num(g_iTeamMode, clamp(iArg, 0, 2));
	server_cmd("sv_restart 1");
	
	return PLUGIN_HANDLED;
}

public cmdGuns(id) //Renable Guns Menu
{
	if(get_pcvar_num(g_iToggle) && g_bSave[id])
	{
		g_bSave[id] = false;
		client_print(id, print_chat, "[%s] Gun menu will be re-enabled next spawn", g_szPrefixName);
	}
}

public fwdPlayerSpawn(id)
{
	if(is_user_alive(id) && get_pcvar_num(g_iToggle)) //Check if player alive and plugin is active
	{
		if(get_pcvar_num(g_iTeamMode))
		{
			if(g_iPlayerTeam[id] == g_MenuTeam)
			{
				switch(get_pcvar_num(g_iStripMode))
				{
					case 1:	//Strip and keep bomb
					{
						StripUserWeapons(id); //Calls the Strip Function
					}
					case 2: // Strip Everything
					{
						strip_user_weapons(id); //Fun native to strip ALL weapons
						give_item(id, "weapon_knife"); //Fun native to give the knife back
					}
				}
			}
		}
		else
		{
			switch(get_pcvar_num(g_iStripMode))
			{
				case 1:	//Strip and keep bomb
				{
					StripUserWeapons(id); //Calls the Strip Function
				}
				case 2: // Strip Everything
				{
					strip_user_weapons(id); //Fun native to strip ALL weapons
					give_item(id, "weapon_knife"); //Fun native to give the knife back
				}
			}
		}
		
		if(g_bomb_targ && get_pcvar_num(g_iStripMode) == 1 && g_iPlayerTeam[id] == CS_TEAM_CT)
		{
			cs_set_user_defuse(id, 1); //If there is a bomb site and your a CT give you a Defuse kit
		}
	
		if(get_pcvar_num(g_iHENade)) //Check if Grenades are enabled
		{
			//g_HeNadesLeft[id] = get_pcvar_num(g_iHENade);
			//Gives player the right amount of grenades
			give_item(id, "weapon_hegrenade");
			cs_set_user_bpammo(id, CSW_HEGRENADE, get_pcvar_num(g_iHENade));
		}
		
		if(get_pcvar_num(g_iFlash)) //Checks if Flashbangs are enabled
		{
			//Gives player the correct amount of flashbangs
			give_item(id, "weapon_flashbang");
			cs_set_user_bpammo(id, CSW_FLASHBANG, get_pcvar_num(g_iFlash));
		}
		
		if(get_pcvar_num(g_iSmoke)) //Checks if smoke is enabled
		{
			//Gives Player the correct amount of Smoke Grenades
			give_item(id, "weapon_smokegrenade");
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, get_pcvar_num(g_iSmoke));
		}
		
		//Gives the player the amount of armor based on the cvar above.
		cs_set_user_armor(id, get_pcvar_num(g_iArmorAmount), CS_ARMOR_VESTHELM);
		
		if(get_pcvar_num(g_iNVG)) //Night Vision enabled?
		{
			cs_set_user_nvg(id, 1); //Gives the user night vision
		}
		
		if(get_pcvar_num(g_iTeamMode))
		{
			if(g_iPlayerTeam[id] == g_MenuTeam)
			{
				if(!is_user_bot(id))
				{
					if(!g_bSave[id]) //Checks weather you have saved your previous weapons or not.
					{
						menu_display(id, g_SpawnMenu); //Shows the menu if you havn't saved your previous
					}
					else
					{
						PreviousWeapons(id); //Gives you the weapons you saved in from the menu
					}
				}
				else
				{
					new iPrimaryArraySize = ArraySize(g_PrimaryWeapons);
					new iSecondaryArraySize = ArraySize(g_SecondaryWeapons);					
					for(new i=0; i< 2; i++)
					{
						new WeaponName[32], szArrayData[32];
						if(i == 0)
						{
							ArrayGetString(g_PrimaryWeapons, iPrimaryArraySize, szArrayData, charsmax(szArrayData)); //Gets the weapon name from the array
						}
						else
						{
							ArrayGetString(g_SecondaryWeapons, iSecondaryArraySize, szArrayData, charsmax(szArrayData)); //Gets the weapon name from the array
						}
						
						replace_all(szArrayData, charsmax(szArrayData), " ", ""); //removes the spaces
						format(WeaponName, charsmax(WeaponName), "weapon_%s", szArrayData); //adds weapon_ to the weapon name
						strtolower(WeaponName);//Converts all to lower case
						GiveWeapons(id, WeaponName); //Gives secondary weapon
					}
				}
			}
		}
		else
		{
			if(!is_user_bot(id))
			{
				if(!g_bSave[id]) //Checks weather you have saved your previous weapons or not.
				{
					menu_display(id, g_SpawnMenu); //Shows the menu if you havn't saved your previous
				}
				else
				{
					PreviousWeapons(id); //Gives you the weapons you saved in from the menu
				}
			}
			else
			{
				new iPrimaryWeapon = random_num(0, ArraySize(g_PrimaryWeapons)-1);
				new iSecondaryWeapon = random_num(0, ArraySize(g_SecondaryWeapons)-1);				
				for(new i=0; i< 2; i++)
				{
					new WeaponName[32], szArrayData[32];
					if(i == 0)
					{
						ArrayGetString(g_PrimaryWeapons, iPrimaryWeapon, szArrayData, charsmax(szArrayData)); //Gets the weapon name from the array
					}
					else
					{
						ArrayGetString(g_SecondaryWeapons, iSecondaryWeapon, szArrayData, charsmax(szArrayData)); //Gets the weapon name from the array
					}
					
					replace_all(szArrayData, charsmax(szArrayData), " ", ""); //removes the spaces
					format(WeaponName, charsmax(WeaponName), "weapon_%s", szArrayData); //adds weapon_ to the weapon name
					strtolower(WeaponName);//Converts all to lower case
					GiveWeapons(id, WeaponName); //Gives secondary weapon
				}
			}
		}
	}
}

public eCurWeapon(id)
{
	if(!get_pcvar_num(g_iToggle) || !get_pcvar_num(g_iUnlimitedAmmo))
		return PLUGIN_HANDLED;
	
	new iWeapon = read_data(2); //Gets current Weapon ID CSW weapon constraints
	
	if(g_WeaponSlots[iWeapon] == 1 || g_WeaponSlots[iWeapon] == 2)
	{
		if(cs_get_user_bpammo(id, iWeapon) < g_WeaponBPAmmo[iWeapon])
		{
			cs_set_user_bpammo(id, iWeapon, g_WeaponBPAmmo[iWeapon]); //If your bp ammo is lower then the max then set it to the max
		}
	}
	return PLUGIN_CONTINUE;
}

public blockDrop(id) //Blocks weapon drop
{
	if(get_pcvar_num(g_iToggle) && get_pcvar_num(g_iBlockDrop) && get_user_weapon(id) != CSW_C4)
	{
		if(get_pcvar_num(g_iTeamMode))
		{
			if(g_iPlayerTeam[id] == g_MenuTeam)
			{
				client_print(id, print_center, "You are not allowed to drop your weapons.");
				return PLUGIN_HANDLED;
			}
		}
		else
		{
			client_print(id, print_center, "You are not allowed to drop your weapons.");
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public HandleSpawnMenu(id, iMenu, iItem)
{
	new szKey[3], Dummy;
	menu_item_getinfo(iMenu, iItem, Dummy, szKey, 2, "", 0, Dummy); //Gets the selection off the menu
	
	switch(str_to_num(szKey))
	{
		case OPTION_NEW:
		{
			menu_display(id, g_pWeaponMenu); //Displays primary weapons menu
		}
		case OPTION_OLD: 
		{
			PreviousWeapons(id); //Gives your previous weapons
		}
		case OPTION_SAVE:
		{
			PreviousWeapons(id); //Same as OPTION_OLD but saves it so you get these weapons each spawn.
			g_bSave[id] = true;
			client_print(id, print_chat, "[%s] say /guns to re-enable the gun menu.", g_szPrefixName);
		}
	}
	return PLUGIN_CONTINUE;
}

public PreviousWeapons(id) //Access the array to give you the previous weapons used by you.
{
	new szpData[32], szsData[32];
	ArrayGetString(g_PrimaryWeapons, g_ipPreviousWeapons[id], szpData, charsmax(szpData)); //Gets the array item of your previous primary weapon
	ArrayGetString(g_SecondaryWeapons, g_isPreviousWeapons[id], szsData, charsmax(szsData)); //Gets the array item of your previous secondary weapon
	strtolower(szpData); //Converts it all to lower case
	strtolower(szsData); //Converts it all to lower case
	replace_all(szpData, charsmax(szpData), " ", ""); //Removes spaces from the array text.
	replace_all(szsData, charsmax(szsData), " ", ""); //Removes spaces from the array text.
	format(szpData, charsmax(szpData), "weapon_%s", szpData); //adds weapon_ infront of the array text.
	format(szsData, charsmax(szsData), "weapon_%s", szsData);//adds weapon_ infront of the array text.
	GiveWeapons(id, szpData); //Gives player previous primary weapon
	GiveWeapons(id, szsData); //Gives player previous Secondary Weapon
}

public CreateWeaponsArray()
{
	get_configsdir(g_szWepFile, charsmax(g_szWepFile));  //gets addons/amxmodx/configs directory
	format(g_szWepFile, charsmax(g_szWepFile), "%s/DM_WeaponOrder.ini", g_szWepFile); //formats the file name for the Weapons order INI
	g_FilePointer = fopen(g_szWepFile, "r"); //Opens the file
	//Arrays
	g_PrimaryWeapons = ArrayCreate(15); //Creates the Primary Weapons Array
	g_SecondaryWeapons = ArrayCreate(15); //Creates the Secondary Weapons Array
	
	//Weapon Menus
	g_pWeaponMenu = menu_create(g_szPriMenuTitle, "HandlePrimaryWeapons"); //Creates the Primary Weapon Menu
	g_sWeaponMenu = menu_create(g_szSecMenuTitle, "HandleSecondaryWeapons"); //Creates the Secondary Weapon Menu
	
	new szData[32], szWeaponName[32], szpNum[3], szsNum[3];
	new pCounter, sCounter;
	if(g_FilePointer) //Makes sure the files open
	{
		while(!feof(g_FilePointer))
		{
			fgets(g_FilePointer, szData, charsmax(szData)); //Reads a line of the file
			trim(szData); //Removes '^n' new line character from the end of the line
			if(containi(szData, ";") != -1) //Checks to see if its a comment and then ignores it
				continue;
			//Check Weapon Slot for Menu Placement
			copy(szWeaponName, charsmax(szWeaponName), szData); //Copys the file data into a new variable to alter it
			replace_all(szWeaponName, charsmax(szWeaponName), " ", ""); //Removes Spaces from the Text
			format(szWeaponName, charsmax(szWeaponName), "weapon_%s", szWeaponName); //Adds Weapon_ to the text
			strtolower(szWeaponName); //converts the whole thing to lower case
			new iWeaponID = get_weaponid(szWeaponName); //Gets the CSW weapon constraint for that weapon
			
			switch(g_WeaponSlots[iWeaponID]) //Checks which slot the weapon is for
			{
				case 1: //Primary Slot
				{
					ArrayPushString(g_PrimaryWeapons, szData); //Adds the original text to the array
					num_to_str(pCounter, szpNum, charsmax(szpNum));
					menu_additem(g_pWeaponMenu, szData, szpNum, 0); //Adds item to the primary weapons menu
					++pCounter;
				}
				case 2: //Secondary Slot
				{
					ArrayPushString(g_SecondaryWeapons, szData); //Adds the original text to the array
					num_to_str(sCounter, szsNum, charsmax(szsNum));
					menu_additem(g_sWeaponMenu, szData, szsNum, 0);//Adds item to the Secondary Weapons Menu
					++sCounter;
				}
			}
		}
	}
	else
	{
		set_fail_state("Failed to Open Weapons List");
	}
	//Blocks exit for both primary and secondary menus
	menu_setprop(g_pWeaponMenu , MPROP_EXIT , MEXIT_NEVER);
	menu_setprop(g_sWeaponMenu , MPROP_EXIT , MEXIT_NEVER);
	
	fclose(g_FilePointer); //Closes the file
}

public HandlePrimaryWeapons(id, iMenu, iItem)
{
	new szKey[3], iSelectedWeapon, Dummy;
	menu_item_getinfo(iMenu, iItem, Dummy, szKey, 2, "", 0, Dummy); //Gets the primary weapon selected.
	
	iSelectedWeapon = str_to_num(szKey);
	g_ipPreviousWeapons[id] = iSelectedWeapon; //Stores the selected weapon for option 2 and 3 on the main menu
	
	new WeaponName[32], szArrayData[32];
	ArrayGetString(g_PrimaryWeapons, iSelectedWeapon, szArrayData, charsmax(szArrayData)); //Gets the weapon name from the array
	replace_all(szArrayData, charsmax(szArrayData), " ", ""); //removes the spaces
	format(WeaponName, charsmax(WeaponName), "weapon_%s", szArrayData); //adds weapon_ to the weapon name
	strtolower(WeaponName);//Converts all to lower case
	GiveWeapons(id, WeaponName); //Gives primary weapon
	
	menu_display(id, g_sWeaponMenu); //Displays secondary weapons menu
}

public HandleSecondaryWeapons(id, iMenu, iItem)
{
	new szKey[3], iSelectedWeapon, Dummy;
	menu_item_getinfo(iMenu, iItem, Dummy, szKey, 2, "", 0, Dummy); //Gets the secondary weapon selected
	
	iSelectedWeapon = str_to_num(szKey);
	g_isPreviousWeapons[id] = iSelectedWeapon; //Stores the selected weapon for option 2 and 3 on the main menu
	
	new WeaponName[32], szArrayData[32];
	ArrayGetString(g_SecondaryWeapons, iSelectedWeapon, szArrayData, charsmax(szArrayData)); //Gets the weapon name from the array
	replace_all(szArrayData, charsmax(szArrayData), " ", ""); //removes the spaces
	format(WeaponName, charsmax(WeaponName), "weapon_%s", szArrayData); //adds weapon_ to the weapon name
	strtolower(WeaponName);//Converts all to lower case
	GiveWeapons(id, WeaponName); //Gives secondary weapon
}

public grenade_throw(id , greindex , wId) //When a grenade is thrown switch to last inv automatically
{
	if(get_pcvar_num(g_iToggle) && get_pcvar_num(g_iFastSwitch))
	{
		client_cmd(id, "lastinv");
	}
}

stock GiveWeapons(id, szWeapon[])
{
	if(is_user_connected(id))
	{
		new iWeaponId = get_weaponid(szWeapon); //Get the weapon id of the weapon given
		give_item(id, szWeapon); //Give the weapon
		cs_set_user_bpammo(id, iWeaponId, g_WeaponBPAmmo[iWeaponId]); //Set the ammo to max ammo
	}
}

stock StripUserWeapons(id)
{
	new iC4Ent = get_pdata_cbase(id, OFFSET_C4_SLOT); //Gets the slot for C4
	
	if( iC4Ent > 0 ) //If you have the C4
	{
		set_pdata_cbase(id, OFFSET_C4_SLOT, FM_NULLENT); //Remove it
	}

	strip_user_weapons(id); //Strip User weapons
	give_item(id, "weapon_knife"); //Give the knife
	set_pdata_int(id, OFFSET_PRIMARYWEAPON, 0); //Set primary weapon offset to 0

	if( iC4Ent > 0 ) //if you had the c4
	{
		set_pev(id, pev_weapons, pev(id, pev_weapons) | (1<<CSW_C4)); //Give it back
		set_pdata_cbase(id, OFFSET_C4_SLOT, iC4Ent); //Set the offset back to normal
		cs_set_user_bpammo(id, CSW_C4, 1); //Give the backpack
		cs_set_user_plant(id, 1); //Allow user to plant it
	}
	return PLUGIN_HANDLED;
}

public eTeamInfo() 
{
	if(!get_pcvar_num(g_iToggle))
		return PLUGIN_HANDLED;
		
	new id = read_data(1);
	new szTeam[2];
	read_data(2, szTeam, charsmax(szTeam));
	switch(szTeam[0])
	{
		case 'T': 
		{
			g_iPlayerTeam[id] = CS_TEAM_T;
		}
		case 'C': 
		{
			g_iPlayerTeam[id] = CS_TEAM_CT;
		}
	}
	
	return PLUGIN_HANDLED;
}

public cmdAdminMenu(id)
{
	if(!get_pcvar_num(g_iToggle))
		return PLUGIN_HANDLED;
		
	new iAdminMenu = menu_create("WM Admin Menu", "HandleAdminMenu");
	
	switch(get_pcvar_num(g_iTeamMode))
	{
		case 1:
		{
			menu_additem(iAdminMenu, "TeamMode:\r T", "0", 0);
		}
		case 2:
		{
			menu_additem(iAdminMenu, "TeamMode:\r CT", "0", 0);
		}
		default:
		{
			menu_additem(iAdminMenu, "TeamMode:\r Both", "0", 0);
		}
	}
	
	menu_additem(iAdminMenu, "Save and Exit", "1", 0);
	
	menu_setprop(iAdminMenu , MPROP_EXIT , MEXIT_NEVER); //Dont allow Menu to exit
	
	menu_display(id, iAdminMenu);
	
	return PLUGIN_HANDLED;
}

public ChangeTeamMode(id, CsTeams:iTeam, iValue)
{
	set_pcvar_num(g_iTeamMode, iValue);
	g_MenuTeam = iTeam;
	switch(iTeam)
	{
		case CS_TEAM_T: client_print(id, print_center, "Team Mode changed to T");
		case CS_TEAM_CT: client_print(id, print_center, "Team Mode changed to CT");
		default: client_print(id, print_center, "Team Mode changed to Both");
	}
}

public HandleAdminMenu(id, iMenu, iItem)
{
	new szKey[3], bool:bUpdateMenu, Dummy;
	menu_item_getinfo(iMenu, iItem, Dummy, szKey, 2, "", 0, Dummy); //Gets the primary weapon selected.
	
	switch(str_to_num(szKey))
	{
		case 0:
		{
			switch(get_pcvar_num(g_iTeamMode))
			{
				case 1:
				{
					ChangeTeamMode(id, CS_TEAM_CT, 2);
					bUpdateMenu = true;
				}
				case 2:
				{
					ChangeTeamMode(id, CS_TEAM_UNASSIGNED, 0);
					bUpdateMenu = true;
				}
				default:
				{
					ChangeTeamMode(id, CS_TEAM_T, 1);
					bUpdateMenu = true;
				}
			}
		}
		case 1:
		{
			server_cmd("sv_restart 1");
		}
	}
	
	if(bUpdateMenu)
	{
		menu_destroy(iMenu);
		cmdAdminMenu(id);
	}
	else
	{
		menu_destroy(iMenu);
	}
}