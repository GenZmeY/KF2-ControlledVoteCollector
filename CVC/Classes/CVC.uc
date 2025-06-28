// This file is part of Controlled Vote Collector.
// Controlled Vote Collector - a mutator for Killing Floor 2.
//
// Copyright (C) 2022-2024 GenZmeY (mailto: genzmey@gmail.com)
//
// Controlled Vote Collector is free software: you can redistribute it
// and/or modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Controlled Vote Collector is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with Controlled Vote Collector. If not, see <https://www.gnu.org/licenses/>.

class CVC extends Info
	dependson(CVC_LocalMessage)
	config(CVC);

const LatestVersion = 2;

const CfgKickProtected           = class'KickProtected';
const CfgKickVote                = class'KickVote';
const CfgStartWaveKickProtection = class'StartWaveKickProtection';
const CfgSkipTraderVote          = class'SkipTraderVote';
const CfgPauseVote               = class'PauseVote';
const CfgMapStat                 = class'MapStat';
const CfgMapVote                 = class'MapVote';

var private config int        Version;
var private config E_LogLevel LogLevel;

var private KFGameInfo            KFGI;
var private KFGameInfo_Survival   KFGIS;
var private KFGameReplicationInfo KFGRI;

var private Array<UniqueNetId> KickProtectedPlayers;
var private Array<CVC_RepInfo> RepInfos;

public simulated function bool SafeDestroy()
{
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
	`Log_Trace();

	if (WorldInfo.NetMode == NM_Client)
	{
		`Log_Fatal("NetMode == NM_Client, Destroy...");
		SafeDestroy();
		return;
	}

	Super.PreBeginPlay();

	PreInit();
}

public event PostBeginPlay()
{
	`Log_Trace();

	if (bPendingDelete || bDeleteMe) return;

	Super.PostBeginPlay();

	PostInit();
}

private function PreInit()
{
	`Log_Trace();

	if (Version == `NO_CONFIG)
	{
		LogLevel = LL_Info;
		SaveConfig();
	}

	CfgMapStat.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgMapVote.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgSkipTraderVote.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgPauseVote.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgKickVote.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgKickProtected.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgStartWaveKickProtection.static.InitConfig(Version, LatestVersion, LogLevel);

	switch (Version)
	{
		case `NO_CONFIG:
			`Log_Info("Config created");

		case 1:

		case MaxInt:
			`Log_Info("Config updated to version"@LatestVersion);
			break;

		case LatestVersion:
			`Log_Info("Config is up-to-date");
			break;

		default:
			`Log_Warn("The config version is higher than the current version (are you using an old mutator?)");
			`Log_Warn("Config version is" @ Version @ "but current version is" @ LatestVersion);
			`Log_Warn("The config version will be changed to" @ LatestVersion);
			break;
	}

	if (LatestVersion != Version)
	{
		Version = LatestVersion;
		SaveConfig();
	}

	if (LogLevel == LL_WrongLevel)
	{
		LogLevel = LL_Info;
		`Log_Warn("Wrong 'LogLevel', return to default value");
		SaveConfig();
	}
	`Log_Base("LogLevel:" @ LogLevel);

	CfgKickVote.static.Load(LogLevel);
	CfgSkipTraderVote.static.Load(LogLevel);
	CfgPauseVote.static.Load(LogLevel);
	CfgMapStat.static.Load(LogLevel);
	CfgMapVote.static.Load(LogLevel);
	CfgStartWaveKickProtection.static.Load(LogLevel);

	KickProtectedPlayers = CfgKickProtected.static.Load(LogLevel);
}

private function PostInit()
{
	`Log_Trace();

	if (WorldInfo == None || WorldInfo.Game == None)
	{
		SetTimer(1.0f, false, nameof(PostInit));
		return;
	}

	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI == None)
	{
		`Log_Fatal("Incompatible gamemode:" @ WorldInfo.Game);
		SafeDestroy();
		return;
	}

	KFGIS = KFGameInfo_Survival(KFGI);
	if (KFGIS == None)
	{
		`Log_Warn("Unknown gamemode (" $ KFGI $ "), KickProtectionStartWaves disabled");
		CfgStartWaveKickProtection.default.Waves = 0;
	}

	if (KFGI.GameReplicationInfo == None)
	{
		SetTimer(1.0f, false, nameof(PostInit));
		return;
	}

	KFGRI = KFGameReplicationInfo(KFGI.GameReplicationInfo);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ KFGI.GameReplicationInfo);
		SafeDestroy();
		return;
	}

	KFGRI.VoteCollectorClass = class'CVC_VoteCollector';
	KFGRI.VoteCollector = new(KFGRI) KFGRI.VoteCollectorClass;

	if (KFGRI.VoteCollector == None)
	{
		`Log_Fatal("Can't replace VoteCollector!");
		SafeDestroy();
		return;
	}
	else
	{
		CVC_VoteCollector(KFGRI.VoteCollector).CVC      = Self;
		CVC_VoteCollector(KFGRI.VoteCollector).LogLevel = LogLevel;
		`Log_Info("VoteCollector replaced");
	}
}

public function bool PlayerIsKickProtected(PlayerReplicationInfo PRI)
{
	`Log_Trace();

	return (KickProtectedPlayers.Find('Uid', PRI.UniqueId.Uid) != INDEX_NONE);
}

public function bool PlayerPerkLoaded(PlayerReplicationInfo PRI)
{
	`Log_Trace();

	return (KFPlayerReplicationInfo(PRI) != None && KFPlayerReplicationInfo(PRI).CurrentPerkClass != None);
}

public function bool PlayerIsStartWaveKickProtected(KFPlayerController KFPC)
{
	`Log_Trace();

	return (PlayerOnStartWave(KFPC) && PlayerHasRequiredLevel(KFPC));
}

private function bool PlayerOnStartWave(KFPlayerController KFPC)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	if (KFGIS != None && CfgStartWaveKickProtection.default.Waves != 0)
	{
		foreach RepInfos(RepInfo)
		{
			if (RepInfo.GetKFPC() == KFPC)
			{
				return (RepInfo.StartWave + CfgStartWaveKickProtection.default.Waves >= KFGIS.WaveNum);
			}
		}
	}

	return false;
}

private function bool PlayerHasRequiredLevel(KFPlayerController KFPC)
{
	local KFPlayerReplicationInfo KFPRI;

	`Log_Trace();

	KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);

	if (KFPRI == None)
	{
		return true;
	}

	return (KFPRI.GetActivePerkLevel() >= CfgStartWaveKickProtection.default.MinLevel);
}

public function bool PlayerCanStartKickVote(KFPlayerController KFPC, KFPlayerController KFPC_Kickee)
{
	`Log_Trace();

	if (KFPC_Kickee != None)
	{
		if (KFPC == KFPC_Kickee)
		{
			return false; // kickee cant vote
		}
		if (!PlayerHasRequiredLevel(KFPC_Kickee))
		{
			return true; // always can vote for players without req level
		}
	}

	return !PlayerOnStartWave(KFPC);
}

public function BroadcastChatLocalized(E_CVC_LocalMessageType LMT, optional String HexColor, optional KFPlayerController ExceptKFPC = None, optional String String1, optional String String2)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.GetKFPC() != ExceptKFPC)
		{
			RepInfo.WriteToChatLocalized(LMT, HexColor, String1, String2);
		}
	}
}

public function BroadcastHUDLocalized(E_CVC_LocalMessageType LMT, optional float DisplayTime = 0.0f, optional String String1, optional String String2, optional String String3)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.GetKFPC() != None)
		{
			RepInfo.WriteToHUDLocalized(LMT, String1, String2, String3, DisplayTime);
		}
	}
}

public function BroadcastClearMessageHUD(optional float DefferedTime = 0.0f)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.GetKFPC() != None)
		{
			RepInfo.DefferedClearMessageHUD(DefferedTime);
		}
	}
}

public function WriteToChatLocalized(KFPlayerController KFPC, E_CVC_LocalMessageType LMT, optional String HexColor, optional String String1, optional String String2)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.GetKFPC() == KFPC)
		{
			RepInfo.WriteToChatLocalized(LMT, HexColor, String1, String2);
			return;
		}
	}
}

public function WriteToHUDLocalized(KFPlayerController KFPC, E_CVC_LocalMessageType LMT, optional float DisplayTime = 0.0f, optional String String1, optional String String2, optional String String3)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.GetKFPC() == KFPC)
		{
			RepInfo.WriteToHUDLocalized(LMT, String1, String2, String3, DisplayTime);
			return;
		}
	}
}

public function NotifyLogin(Controller C)
{
	`Log_Trace();

	if (!CreateRepInfo(C))
	{
		`Log_Error("Can't create RepInfo for:" @ C);
	}
}

public function NotifyLogout(Controller C)
{
	`Log_Trace();

	if (!DestroyRepInfo(C))
	{
		`Log_Error("Can't destroy RepInfo of:" @ C);
	}
}

public function bool CreateRepInfo(Controller C)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	if (C == None) return false;

	RepInfo = Spawn(class'CVC_RepInfo', C);

	if (RepInfo == None) return false;

	RepInfo.CVC = Self;
	RepInfo.LogLevel = LogLevel;
	RepInfo.StartWave = ((KFGIS != None) ? KFGIS.WaveNum : 0);

	RepInfos.AddItem(RepInfo);

	return true;
}

public function bool DestroyRepInfo(Controller C)
{
	local CVC_RepInfo RepInfo;

	`Log_Trace();

	if (C == None) return false;

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner == C)
		{
			RepInfos.RemoveItem(RepInfo);
			RepInfo.SafeDestroy();
			return true;
		}
	}

	return false;
}

public simulated function vector GetTargetLocation(optional actor RequestedBy, optional bool bRequestAlternateLoc)
{
	local Controller C;
	C = Controller(RequestedBy);
	if (C != None) { bRequestAlternateLoc ? NotifyLogout(C) : NotifyLogin(C); }
	return Super.GetTargetLocation(RequestedBy, bRequestAlternateLoc);
}

defaultproperties
{

}