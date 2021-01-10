#include <ripext>

public Plugin myinfo = {
	name = "MConnectInfo",
	author = "Mozze",
	description = "",
	version = "1.1",
	url = "t.me/pMozze"
};

HTTPClient g_hHTTPClient;

public void OnPluginStart() {
	g_hHTTPClient = new HTTPClient("");

	LoadTranslations("mconnectinfo.phrases");
	HookEvent("player_connect_client", onPlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", onPlayerDisconnect, EventHookMode_Pre);
}

public Action onPlayerConnect(Event hEvent, const char[] szName, bool bDontBroadcast) {
	return Plugin_Handled;
}

public Action onPlayerDisconnect(Event hEvent, const char[] szName, bool bDontBroadcast) {
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int iClient) {
	if (IsFakeClient(iClient) || GetUserFlagBits(iClient))
		return;

	DataPack
		hDataPack = new DataPack();

	char
		szNickName[128],
		szAuth[32],
		szIP[16],
		szBuffer[64];

	GetClientName(iClient, szNickName, sizeof(szNickName));
	GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof(szAuth));
	GetClientIP(iClient, szIP, sizeof(szIP));

	hDataPack.WriteCell(iClient);
	hDataPack.WriteString(szAuth);
	hDataPack.WriteString(szIP);

	Format(szBuffer, sizeof(szBuffer), "api/mci.php?steamID=%s&ip=%s", szAuth, szIP);
	g_hHTTPClient.Get(szBuffer, onDataRecived, hDataPack);
}

public void OnClientDisconnect(int iClient) {
	if (IsFakeClient(iClient) || !IsClientInGame(iClient))
		return;

	PrintToChatAll("%t", "Disconnect", iClient);
}

public void onDataRecived(HTTPResponse hResponse, DataPack hDataPack) {
	int 
		iClient;

	char
		szStatus[2][8],
		szBuffer[3][256];

	hDataPack.Reset();
	iClient = hDataPack.ReadCell();
	hDataPack.ReadString(szBuffer[0], 256);
	hDataPack.ReadString(szBuffer[1], 256);
	delete hDataPack;

	if (!IsClientInGame(iClient))
		return;

	if (hResponse.Status != HTTPStatus_OK) {
		Format(szBuffer[0], 256, "%t", "Connected", iClient);
		Format(szBuffer[1], 256, "%t", "SteamID", szBuffer[1]);
		Format(szBuffer[2], 256, "%t", "IP", szBuffer[2]);

		PrintToChatAll("%t", "Top message");
		PrintToChatAll("%s", szBuffer[0]);
		PrintToChatAll("%s", szBuffer[1]);
		PrintToChatAll("%s", szBuffer[2]);
		PrintToChatAll("%t", "Bottom message");

		return;
	}

	JSONObject
		hData = view_as<JSONObject>(hResponse.Data),
		hGEO = hData.Get("geo"),
		hSteam = hData.Get("steam");

	hSteam.GetString("status", szStatus[0], 8);
	hGEO.GetString("status", szStatus[1], 8);

	PrintToChatAll("%t", "Top message");

	if (StrEqual(szStatus[0], "success")) {
		char szName[128];
		hSteam.GetString("name", szName, sizeof(szName));

		Format(szBuffer[2], 256, "%t %t", "NickName", iClient, "Licensed");
		PrintToChatAll(szBuffer[2]);

		if (szName[0]) {
			Format(szBuffer[2], 256, "%t", "Name", szName);
			PrintToChatAll(szBuffer[2]);
		} else {
			Format(szBuffer[2], 256, "%t", "SteamID", szBuffer[0]);
			PrintToChatAll(szBuffer[2]);
		}
		
		Format(szBuffer[2], 256, "%t", hSteam.GetBool("vac") ? "Vac ban is exist" : "Vac ban is not exist");
		PrintToChatAll(szBuffer[2]);
	} else {
		Format(szBuffer[2], 256, "%t %t", "NickName", iClient, "Not licensed");
		PrintToChatAll(szBuffer[2]);

		Format(szBuffer[2], 256, "%t", "SteamID", szBuffer[0]);
		PrintToChatAll(szBuffer[2]);
	}

	if (StrEqual(szStatus[1], "success")) {
		char
			szCountry[256],
			szCity[256],
			szRegion[256],
			szProvider[256];

		hGEO.GetString("country", szCountry, sizeof(szCountry));
		hGEO.GetString("city", szCity, sizeof(szCity));
		hGEO.GetString("regionName", szRegion, sizeof(szRegion));
		hGEO.GetString("isp", szProvider, sizeof(szProvider));
		
		Format(szBuffer[2], 256, "%t", "Location", szCountry, szCity, szRegion);
		PrintToChatAll(szBuffer[2]);

		Format(szBuffer[2], 256, "%t", "Provider", szProvider);
		PrintToChatAll(szBuffer[2]);
	} else {
		Format(szBuffer[2], 256, "%t", "IP", szBuffer[1]);
		PrintToChatAll(szBuffer[2]);
	}

	PrintToChatAll("%t", "Bottom message");

	delete hData;
	delete hSteam;
	delete hGEO;
}
