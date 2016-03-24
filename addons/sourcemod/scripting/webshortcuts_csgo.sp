#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION				"2.5"

public Plugin myinfo = 
{
	name = "Web Shortcuts CS:GO version",
	author = "Franc1sco franug and James \"sslice\" Gray",
	description = "Provides chat-triggered web shortcuts",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug/"
};

Handle g_Shortcuts;
Handle g_Titles;
Handle g_Links;

char g_ServerIp [32];
char g_ServerPort [16];

public void OnPluginStart()
{
	CreateConVar( "sm_webshortcutscsgo_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED );
	
	RegConsoleCmd( "say", OnSay );
	RegConsoleCmd( "say_team", OnSay );
	
	RegAdminCmd("sm_web", Command_Web, ADMFLAG_GENERIC,"Open URL for target");
	
	g_Shortcuts = CreateArray( 32 );
	g_Titles = CreateArray( 64 );
	g_Links = CreateArray( 512 );
	
	Handle cvar = FindConVar( "hostip" );
	int hostip = GetConVarInt( cvar );
	FormatEx( g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
		(hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF );
	
	cvar = FindConVar( "hostport" );
	GetConVarString( cvar, g_ServerPort, sizeof(g_ServerPort) );
	
	LoadWebshortcuts();
}
 
public void OnMapStart()
{
	LoadWebshortcuts();
}
 
public Action OnSay( int client, int args )
{
	if(!client)
	{
		return Plugin_Continue;	
	}
	
	char text[512]; 
	char shortcut[512];
	GetCmdArgString( text, sizeof(text) );
	
	StripQuotes(text);
	TrimString(text);
	
	int size = GetArraySize( g_Shortcuts );
	for (int i; i != size; ++i)
	{
		GetArrayString( g_Shortcuts, i, shortcut, sizeof(shortcut) );
		
		if ( StrEqual( text, shortcut, false ))
		{
			QueryClientConVar(client, "cl_disablehtmlmotd", ClientConVar, client);
			
			char title [256];
			char steamId [64];
			char userId [16];
			char name [64];
			char clientIp [32];
			
			GetArrayString( g_Titles, i, title, sizeof(title) );
			GetArrayString( g_Links, i, text, sizeof(text) );
			
			GetClientAuthId(client, AuthId_Steam2,  steamId, sizeof(steamId) );
			FormatEx( userId, sizeof(userId), "%u", GetClientUserId( client ) );
			GetClientName( client, name, sizeof(name) );
			GetClientIP( client, clientIp, sizeof(clientIp) );
			
		
			ReplaceString( text, sizeof(text), "{SERVER_IP}", g_ServerIp);
			ReplaceString( text, sizeof(text), "{SERVER_PORT}", g_ServerPort);
			ReplaceString( text, sizeof(text), "{STEAM_ID}", steamId);
			ReplaceString( text, sizeof(text), "{USER_ID}", userId);
			ReplaceString( text, sizeof(text), "{NAME}", name);
			ReplaceString( text, sizeof(text), "{IP}", clientIp);
			
			if(StrEqual(title, "none", false))
			{
				StreamPanel("Webshortcuts", text, client);
			}
			else if(StrEqual(title, "full", false))
			{
				FixMotdCSGO_fullsize(text);
				ShowMOTDPanel( client, "Script by Franc1sco franug", text, MOTDPANEL_TYPE_URL );
			}
			else
			{
				FixMotdCSGO(text, title);
				ShowMOTDPanel( client, "Script by Franc1sco franug", text, MOTDPANEL_TYPE_URL );
			}
		}
	}
	
	return Plugin_Continue;	
}
 
void LoadWebshortcuts()
{
	char buffer [1024];
	BuildPath( Path_SM, buffer, sizeof(buffer), "configs/webshortcuts.txt" );
	
	if ( !FileExists( buffer ) )
	{
		return;
	}
 
	Handle f = OpenFile( buffer, "r" );
	if ( f == INVALID_HANDLE )
	{
		LogError( "[SM] Could not open file: %s", buffer );
		return;
	}
	
	ClearArray( g_Shortcuts );
	ClearArray( g_Titles );
	ClearArray( g_Links );
	
	char shortcut [32];
	char title [256];
	char link [512];
	while ( !IsEndOfFile( f ) && ReadFileLine( f, buffer, sizeof(buffer) ) )
	{
		TrimString( buffer );
		if ( buffer[0] == '\0' || buffer[0] == ';' || ( buffer[0] == '/' && buffer[1] == '/' ) )
		{
			continue;
		}
		
		int pos = BreakString( buffer, shortcut, sizeof(shortcut) );
		if ( pos == -1 )
		{
			continue;
		}
		
		int linkPos = BreakString( buffer[pos], title, sizeof(title) );
		if ( linkPos == -1 )
		{
			continue;
		}
		
		strcopy( link, sizeof(link), buffer[linkPos+pos] );
		TrimString( link );
		
		PushArrayString( g_Shortcuts, shortcut );
		PushArrayString( g_Titles, title );
		PushArrayString( g_Links, link );
	}
	
	CloseHandle(f);
}

public Action Command_Web(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_web <target> <url>");
		return Plugin_Handled;
	}
	char pattern[96]; 
	char buffer[64]; 
	char url[512];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, url, sizeof(url));
	int targets[129];
	bool ml = false;

	int count = ProcessTargetString(pattern, client, targets, sizeof(targets), 0, buffer, sizeof(buffer), ml);

	if(StrContains(url, "http://", false) != 0) Format(url, sizeof(url), "http://%s", url);
	FixMotdCSGO(url,"height=720,width=1280");
	
	if (count <= 0) ReplyToCommand(client, "Bad target");
	else for (int i = 0; i < count; i++)
	{
		ShowMOTDPanel(targets[i], "Web Shortcuts", url, MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}

public void StreamPanel(char[] title, char[] url, int client) 
{
	Handle Radio = CreateKeyValues("data");
	KvSetString(Radio, "title", title);
	KvSetString(Radio, "type", "2");
	KvSetString(Radio, "msg", url);
	ShowVGUIPanel(client, "info", Radio, false);
	CloseHandle(Radio);
}

stock void FixMotdCSGO(char web[512], char[] title)
{
	Format(web, sizeof(web), "https://go-free.info/webshortcuts2.php?web=%s;franug_is_pro;%s", title,web);
}

stock void FixMotdCSGO_fullsize(char web[512])
{
	Format(web, sizeof(web), "https://go-free.info/webshortcuts_f.html?web=%s", web);
}

public void ClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (StringToInt(cvarValue) > 0)
	{
		PrintToChat(client, "---------------------------------------------------------------");
		PrintToChat(client, "You have cl_disablehtmlmotd set to 1 and for that reason this command will not work for you");
		PrintToChat(client, "Please, input this in your console: cl_disablehtmlmotd 0");
		PrintToChat(client, "---------------------------------------------------------------");
	}
}
