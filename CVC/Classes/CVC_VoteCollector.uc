class CVC_VoteCollector extends KFVoteCollector;

const CfgKickProtected           = class'KickProtected';
const CfgKickVote                = class'KickVote';
const CfgStartWaveKickProtection = class'StartWaveKickProtection';
const CfgSkipTraderVote          = class'SkipTraderVote';
const CfgPauseVote               = class'PauseVote';
const CfgMapStat                 = class'MapStat';
const CfgMapStats                = class'MapStats';
const CfgMapVote                 = class'MapVote';

struct S_KickVote
{
	var String        Name;
	var String        SteamID;
	var String        UniqueID;
	var bool          VoteYes;
	var class<KFPerk> Perk;
	var byte          Level;
};
// KickVotes[0]:    Kickee
// KickVotes[1]:    Kicker
// KickVotes[2...]: Voters 
var private Array<S_KickVote> KickVotes;

var public CVC CVC;
var public E_LogLevel LogLevel;

var private KFPlayerController KFPC_Kicker;
var private KFPlayerController KFPC_Kickee;

var private String KickerName;
var private String KickeeName;

var private String YesVotesPlayers, NoVotesPlayers;

var private bool AllowHudNotification;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel;
}

public function ServerStartVoteKick(PlayerReplicationInfo PRI_Kickee, PlayerReplicationInfo PRI_Kicker)
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local KFGameInfo KFGI;
	
	`Log_Trace();
	
	KFGI = KFGameInfo(WorldInfo.Game);
	KFPC_Kicker = KFPlayerController(PRI_Kicker.Owner);
	KFPC_Kickee = KFPlayerController(PRI_Kickee.Owner);
	
	KickerName = PRI_Kicker.PlayerName;
	KickeeName = PRI_Kickee.PlayerName;

	if (KFGI.bDisableKickVote)
	{
		KFPC_Kicker.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteDisabled);
		return;
	}

	if (PRI_Kicker.bOnlySpectator)
	{
		KFPC_Kicker.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNoSpectators);
		return;
	}
	
	if (!CVC.PlayerCanKickVote(KFPC_Kicker, KFPC_Kickee))
	{
		CVC.WriteToChatLocalized(
			KFPC_Kicker,
			CVC_PlayerCantVote,
			CfgKickVote.default.WarningColorHex,
			String(CfgStartWaveKickProtection.default.Waves));
		return;
	}
	
	if (CVC.PlayerIsStartWaveKickProtected(KFPC_Kickee))
	{
		CVC.WriteToChatLocalized(
			KFPC_Kicker,
			CVC_PlayerIsStartWaveKickProtected,
			CfgKickVote.default.WarningColorHex,
			KickeeName,
			String(CfgStartWaveKickProtection.default.Waves));
		return;
	}
	
	if (VotingPlayers(PRI_Kickee) < CfgKickVote.default.MinVotingPlayersToStartKickVote)
	{
		if (CfgStartWaveKickProtection.default.Waves == 0)
		{
			KFPC_Kicker.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNotEnoughPlayers);
		}
		else
		{
			CVC.WriteToChatLocalized(
				KFPC_Kicker,
				CVC_KickVoteNotEnoughPlayers,
				CfgKickVote.default.WarningColorHex,
				String(CfgStartWaveKickProtection.default.Waves));
		}
		return;
	}

	if (KickedPlayers >= CfgKickVote.default.MaxKicks)
	{
		KFPC_Kicker.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteMaxKicksReached);
		return;
	}
	
	if (CVC.PlayerIsKickProtected(PRI_Kickee))
	{
		CVC.WriteToChatLocalized(
			KFPC_Kicker,
			CVC_PlayerIsKickProtected,
			CfgKickVote.default.WarningColorHex,
			KickeeName);
				
		if (CfgKickProtected.default.NotifyPlayerAboutKickAttempt)
		{
			CVC.WriteToChatLocalized(
				KFPC_Kickee,
				CVC_KickVoteNotStartedForPlayer,
				CfgKickVote.default.WarningColorHex,
				KickerName);
		}
		return;
	}

	if (KFGI.AccessControl != None && KFGI.AccessControl.IsAdmin(KFPC_Kickee))
	{
		KFPC_Kicker.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteAdmin);
		return;
	}

	if (bIsFailedVoteTimerActive)
	{
		KFPC_Kicker.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteRejected);
		return;
	}

	if (bIsSkipTraderVoteInProgress || bIsPauseGameVoteInProgress)
	{
		KFPC_Kicker.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_OtherVoteInProgress);
		return;
	}

	if (!bIsKickVoteInProgress)
	{
		PlayersThatHaveVoted.Length = 0;
		
		CurrentKickVote.PlayerID        = PRI_Kickee.UniqueId;
		CurrentKickVote.PlayerPRI       = PRI_Kickee;
		CurrentKickVote.PlayerIPAddress = KFPC_Kickee.GetPlayerNetworkAddress();

		bIsKickVoteInProgress = true;

		GetKFPRIArray(KFPRIs);
		foreach KFPRIs(KFPRI)
		{
			KFPRI.ShowKickVote(PRI_Kickee, VoteTime, !(KFPRI == PRI_Kicker || KFPRI == PRI_Kickee || !CVC.PlayerCanKickVote(KFPlayerController(KFPRI.Owner))));
		}
		
		if (CfgKickVote.default.bChatNotifications)
		{
			CVC.BroadcastChatLocalized(
				CVC_KickVoteStarted,
				CfgKickVote.default.PositiveColorHex,
				KFPC_Kickee,
				KickerName,
				KickeeName);
			
			CVC.WriteToChatLocalized(
				KFPC_Kickee,
				CVC_KickVoteStartedForPlayer,
				CfgKickVote.default.NegativeColorHex,
				KickerName,
				KickeeName);
				
			foreach KFPRIs(KFPRI)
			{
				if (KFPRI == PRI_Kickee)
				{
					continue;
				}
				KFPC = KFPlayerController(KFPRI.Owner);
				if (!CVC.PlayerCanKickVote(KFPC))
				{
					CVC.WriteToChatLocalized(
						KFPC,
						CVC_PlayerCantVote,
						CfgKickVote.default.WarningColorHex,
						String(CfgStartWaveKickProtection.default.Waves));
				}
			}
		}
		else
		{
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteStarted, CurrentKickVote.PlayerPRI);
		}
		
		if (CfgKickVote.default.bLogKickVote)
		{
			KickVotes.Length = 0;
			KickVotes.AddItem(PlayerKickVote(PRI_Kickee, false));
		}
		
		if (CfgKickVote.default.bHudNotificationsOnlyOnTraderTime)
		{
			AllowHudNotification = bTraderIsOpen;
		}
		
		SetTimer(VoteTime, false, nameof(ConcludeVoteKick), Self);
		
		RecieveVoteKick(PRI_Kicker, true);
	}
	else if (PRI_Kickee == CurrentKickVote.PlayerPRI)
	{
		RecieveVoteKick(PRI_Kicker, false); // WTF is that?!
		`Log_Debug("WTF happens:" @ KickeeName);
	}
	else
	{
		KFPlayerController(PRI_Kicker.Owner).ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteInProgress);
	}
}

private function int VotingPlayers(optional PlayerReplicationInfo KickeePRI, optional Array<KFPlayerReplicationInfo> KFPRIs)
{
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local int VotingPlayersNum;
	
	`Log_Trace();
	
	if (KFPRIs.Length == 0)
	{
		GetKFPRIArray(KFPRIs);
	}
	
	if (KFPC_Kickee == None)
	{
		if (KickeePRI == None)
		{
			KickeePRI = CurrentKickVote.PlayerPRI;
		}
		if (KickeePRI != None)
		{
			KFPC_Kickee = KFPlayerController(KickeePRI.Owner);
		}
	}
	
	VotingPlayersNum = 0;
	foreach KFPRIs(KFPRI)
	{
		KFPC = KFPlayerController(KFPRI.Owner);
		if (KFPC != None && CVC.PlayerCanKickVote(KFPC, KFPC_Kickee))
		{
			VotingPlayersNum++;
		}
	}
	
	return VotingPlayersNum;
}

private function String DidntVotedPlayers()
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;
	local String DidntVoted;
	
	`Log_Trace();
	
	GetKFPRIArray(KFPRIs);
	
	foreach KFPRIs(KFPRI)
	{
		if (PlayersThatHaveVoted.Find(KFPRI) == INDEX_None)
		{
			DidntVoted $= (DidntVoted == "" ? KFPRI.PlayerName : ("," @ KFPRI.PlayerName));
		}
	}
	
	return DidntVoted;
}

private function String VotedPlayers()
{
	local PlayerReplicationInfo PRI;
	local String Voted;
	
	`Log_Trace();
	
	foreach PlayersThatHaveVoted(PRI)
	{
		Voted $= (Voted == "" ? PRI.PlayerName : ("," @ PRI.PlayerName));
	}
	
	return Voted;
}

private function S_KickVote PlayerKickVote(PlayerReplicationInfo PRI, bool bKick)
{
	local KFPlayerReplicationInfo KFPRI;
	local PlayerController PC;
	local OnlineSubsystem OS;
	local S_KickVote KV;
	
	`Log_Trace();
	
	KV.Name     = PRI.PlayerName;
	KV.UniqueID = class'OnlineSubsystem'.static.UniqueNetIdToString(PRI.UniqueId);
	
	PC = PlayerController(PRI.Owner);
	if (PC != None && !PC.bIsEosPlayer)
	{
		OS = class'GameEngine'.static.GetOnlineSubsystem();
		if (OS != None)
		{
			KV.SteamID = OS.UniqueNetIdToInt64(PRI.UniqueId);
		}
	}
	
	KV.VoteYes = bKick;
	
	KFPRI = KFPlayerReplicationInfo(PRI);
	if (KFPRI != None)
	{
		KV.Perk  = KFPRI.CurrentPerkClass;
		KV.Level = KFPRI.GetActivePerkLevel();
	}
	
	return KV;
}

public reliable server function RecieveVoteKick(PlayerReplicationInfo PRI, bool bKick)
{
	`Log_Trace();
	
	// there is a bug somewhere in the TWI code:
	// sometimes votes for skipping a trader or pausing come to this function
	// this is an attempt to fix it without affecting other parts of the game
	// probably this part can be changed when I understand when this bug occurs
	if (bIsSkipTraderVoteInProgress)
	{
		`Log_Debug("Receive kick vote while skip trader vote is active");
		RecieveVoteSkipTrader(PRI, bKick);
		return;
	}
	if (bIsPauseGameVoteInProgress)
	{
		`Log_Debug("Receive kick vote while skip pause vote is active");
		ReceiveVotePauseGame(PRI, bKick);
		return;
	}
	if (!bIsKickVoteInProgress)
	{
		`Log_Debug("Receive kick vote while kick vote is not active");
		return;
	}
	
	if (PlayersThatHaveVoted.Find(PRI) == INDEX_NONE)
	{
		if (bKick)
		{
			YesVotesPlayers = (YesVotesPlayers == "") ? PRI.PlayerName : YesVotesPlayers $ "," @ PRI.PlayerName;
		}
		else
		{
			NoVotesPlayers = (NoVotesPlayers == "") ? PRI.PlayerName : NoVotesPlayers $ "," @ PRI.PlayerName;
		}
		
		if (CfgKickVote.default.bLogKickVote)
		{
			KickVotes.AddItem(PlayerKickVote(PRI, bKick));
		}

		if (CfgKickVote.default.bChatNotifications)
		{
			CVC.BroadcastChatLocalized(
				bKick ? CVC_KickVoteYesReceived : CVC_KickVoteNoReceived,
				bKick ? CfgKickVote.default.PositiveColorHex : CfgKickVote.default.NegativeColorHex,
				KFPC_Kickee,
				PRI.PlayerName);
			
			CVC.WriteToChatLocalized(
				KFPC_Kickee,
				bKick ? CVC_KickVoteYesReceived : CVC_KickVoteNoReceived,
				bKick ? CfgKickVote.default.NegativeColorHex : CfgKickVote.default.PositiveColorHex,
				PRI.PlayerName);
		}
		if (CfgKickVote.default.bHUDNotifications && AllowHudNotification)
		{
			if (NoVotesPlayers == "")
			{
				CVC.BroadcastHUDLocalized(
					CVC_KickVoteStartedHUD,
					float(VoteTime),
					KickerName,
					KickeeName,
					YesVotesPlayers);
			}
			else
			{
				CVC.BroadcastHUDLocalized(
					CVC_KickVoteReceivedHUD,
					float(VoteTime),
					YesVotesPlayers,
					NoVotesPlayers);
			}
		}
	}
	
	Super.RecieveVoteKick(PRI, bKick);
}

public function bool ShouldConcludeKickVote()
{
	local KFGameInfo KFGI;
	local int NumPRIs;
	local int KickVotesNeeded;
	
	`Log_Trace();
	
	if (CfgStartWaveKickProtection.default.Waves == 0)
	{
		return Super.ShouldConcludeKickVote();
	}

	KFGI = KFGameInfo(WorldInfo.Game);

	NumPRIs = VotingPlayers();

	if (YesVotes + NoVotes >= NumPRIs)
	{
		return true;
	}
	else if (KFGI != None)
	{
		KickVotesNeeded = FCeil(float(NumPRIs) * KFGI.KickVotePercentage);
		KickVotesNeeded = Clamp(KickVotesNeeded, 1, NumPRIs);
		
		if (YesVotes >= KickVotesNeeded)
		{
			return true;
		}
		else if (NoVotes > (NumPRIs - KickVotesNeeded))
		{
			return true;
		}
	}

	return false;
}

public reliable server function ConcludeVoteKick()
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;
	local PlayerReplicationInfo PRI;
	local int NumPRIs;
	local KFGameInfo KFGI;
	local KFPlayerController KickedPC;
	local int KickVotesNeeded;
	local int PrevKickedPlayers;
	
	`Log_Trace();
	
	`Log_Debug("ConcludeVoteKick()" @ bIsKickVoteInProgress);
	
	if (bIsKickVoteInProgress)
	{
		YesVotesPlayers = "";
		NoVotesPlayers  = "";
		
		if (CfgKickVote.default.bHUDNotifications)
		{
			CVC.BroadcastClearMessageHUD(CfgKickVote.default.DefferedClearHUD);
		}
	}
	
	PrevKickedPlayers = KickedPlayers;
	
	if (CfgStartWaveKickProtection.default.Waves == 0)
	{
		Super.ConcludeVoteKick();
	}
	else if (bIsKickVoteInProgress)
	{
		KFGI = KFGameInfo(WorldInfo.Game);

		GetKFPRIArray(KFPRIs);

		foreach KFPRIs(KFPRI) KFPRI.HideKickVote();

		NumPRIs = VotingPlayers(CurrentKickVote.PlayerPRI, KFPRIs);

		KickVotesNeeded = FCeil(float(NumPRIs) * KFGI.KickVotePercentage);
		KickVotesNeeded = Clamp(KickVotesNeeded, 1, NumPRIs);

		if (YesVotes >= KickVotesNeeded)
		{
			if (CurrentKickVote.PlayerPRI == None || CurrentKickVote.PlayerPRI.bPendingDelete)
			{
				foreach WorldInfo.Game.InactivePRIArray(PRI)
				{
					if (PRI.UniqueId == CurrentKickVote.PlayerID)
					{
						CurrentKickVote.PlayerPRI = PRI;
						break;
					}
				}
			}
			
			if (KFGI.AccessControl != None)
			{
				KickedPC = ((CurrentKickVote.PlayerPRI != None) && (CurrentKickVote.PlayerPRI.Owner != None)) ? KFPlayerController(CurrentKickVote.PlayerPRI.Owner) : None;
				KFAccessControl(KFGI.AccessControl).KickSessionBanPlayer(KickedPC, CurrentKickVote.PlayerID, KFGI.AccessControl.KickedMsg);
			}
			
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteSucceeded, CurrentKickVote.PlayerPRI);
			KickedPlayers++;
		}
		else
		{
			bIsFailedVoteTimerActive = true;
			SetTimer(KFGI.TimeBetweenFailedVotes, false, nameof(ClearFailedVoteFlag), Self);
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteFailed, CurrentKickVote.PlayerPRI);
		}

		bIsKickVoteInProgress     = false;
		CurrentKickVote.PlayerPRI = None;
		CurrentKickVote.PlayerID  = class'PlayerReplicationInfo'.default.UniqueId;
		YesVotes                  = 0;
		NoVotes                   = 0;
	}
	
	if (CfgKickVote.default.bLogKickVote && KickedPlayers > PrevKickedPlayers)
	{
		LogKickVotes();
	}
}

private function LogKickVotes()
{
	local S_KickVote KV;
	local S_KickVote Kicker;
	local S_KickVote Kickee;
	local Array<S_KickVote> Yes;
	local Array<S_KickVote> No;
	local int Index;
	
	`Log_Trace();
	
	foreach KickVotes(KV, Index)
	{
		switch (Index)
		{
			case 0:  Kickee = KV; break;
			case 1:  Kicker = KV; break;
			default: if (KV.VoteYes) Yes.AddItem(KV); else No.AddItem(KV); break;
		}
	}
	
	`Log_Kick("Kicker:" @ LogVotePlayer(Kicker));
	`Log_Kick("Kicked:" @ LogVotePlayer(Kickee) @ String(Kickee.Perk) @ String(Kickee.Level));
	
	`Log_Kick("Yes voters:");
	foreach Yes(KV) `Log_Kick(LogVotePlayer(KV));
	
	if (No.Length == 0) return;
	
	`Log_Kick("No voters:");
	foreach No(KV) `Log_Kick(LogVotePlayer(KV));
}

private function String LogVotePlayer(S_KickVote KV)
{
	`Log_Trace();
	
	return KV.Name @ "(UniqueID:" @ KV.UniqueID $ (KV.SteamID == "" ? "" : (", SteamID:" @ KV.SteamID $ ", Profile:" @ "https://steamcommunity.com/profiles/" $ KV.SteamID)) $ ")";
}

public reliable server function RecieveVoteSkipTrader(PlayerReplicationInfo PRI, bool bSkip)
{
	local bool MustNotify;
	
	`Log_Trace();
	
	MustNotify = (PlayersThatHaveVoted.Find(PRI) == INDEX_NONE);
	
	Super.RecieveVoteSkipTrader(PRI, bSkip);
	
	if (MustNotify)
	{
		if (CfgSkipTraderVote.default.bChatNotifications)
		{
			CVC.BroadcastChatLocalized(
				bSkip ? CVC_SkipVoteYesReceived : CVC_SkipVoteNoReceived,
				bSkip ? CfgSkipTraderVote.default.PositiveColorHex : CfgSkipTraderVote.default.NegativeColorHex,
				None,
				PRI.PlayerName);
		}
		if (CfgSkipTraderVote.default.bHUDNotifications)
		{
			CVC.BroadcastHUDLocalized(
				CVC_VoteProgressHUD,
				float(VoteTime),
				VotedPlayers(),
				DidntVotedPlayers());
		}
	}
}

public reliable server function ConcludeVoteSkipTrader()
{
	`Log_Trace();
	
	`Log_Debug("ConcludeVoteSkipTrader()" @ bIsSkipTraderVoteInProgress);
	
	if (bIsSkipTraderVoteInProgress)
	{
		YesVotesPlayers = "";
		NoVotesPlayers  = "";
		
		if (CfgSkipTraderVote.default.bHUDNotifications)
		{
			CVC.BroadcastClearMessageHUD(CfgSkipTraderVote.default.DefferedClearHUD);
		}
	}
	
	Super.ConcludeVoteSkipTrader();
}

public reliable server function ReceiveVotePauseGame(PlayerReplicationInfo PRI, bool bSkip)
{
	local bool MustNotify;
	
	`Log_Trace();
	
	MustNotify = (PlayersThatHaveVoted.Find(PRI) == INDEX_NONE);
	
	Super.ReceiveVotePauseGame(PRI, bSkip);
	
	if (MustNotify)
	{
		if (CfgPauseVote.default.bChatNotifications)
		{
			CVC.BroadcastChatLocalized(
				bSkip ? CVC_PauseVoteYesReceived : CVC_PauseVoteNoReceived,
				bSkip ? CfgPauseVote.default.PositiveColorHex : CfgPauseVote.default.NegativeColorHex,
				None,
				PRI.PlayerName);
		}
		if (CfgPauseVote.default.bHUDNotifications)
		{
			CVC.BroadcastHUDLocalized(
				CVC_VoteProgressHUD,
				float(VoteTime),
				VotedPlayers(),
				DidntVotedPlayers());
		}
	}
}

public reliable server function ConcludeVotePauseGame()
{
	`Log_Trace();
	
	`Log_Debug("ConcludeVotePauseGame()" @ bIsPauseGameVoteInProgress);
	
	if (bIsPauseGameVoteInProgress)
	{
		YesVotesPlayers = "";
		NoVotesPlayers  = "";
		
		if (CfgPauseVote.default.bHUDNotifications)
		{
			CVC.BroadcastClearMessageHUD(CfgPauseVote.default.DefferedClearHUD);
		}
	}
	
	Super.ConcludeVotePauseGame();
}

private function Array<String> ActiveMapCycle()
{
	local KFGameInfo KFGI;
	
	`Log_Trace();
	
	if (WorldInfo.NetMode == NM_Standalone)
	{
		return Maplist;
	}
	
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI != None)
	{
		return KFGI.GameMapCycles[KFGI.ActiveMapCycle].Maps;
	}
}

private function Array<String> GetAviableMaps()
{
	local String LowerDefaultNextMap;
	local Array<String> MapCycle;
	local Array<String> Maps;
	local KFGameInfo KFGI;
	local String Map;
	local int Index;
	
	`Log_Trace();
	
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI == None) return Maps;
	
	MapCycle = ActiveMapCycle();
	
	LowerDefaultNextMap = Locs(CfgMapVote.default.DefaultNextMap);
	`Log_Debug("LowerDefaultNextMap:" @ LowerDefaultNextMap);
	switch (LowerDefaultNextMap)
	{
		case "any":
			`Log_Debug("any");
			foreach MapCycle(Map)
			{
				if (KFGI.IsMapAllowedInCycle(Map))
				{
					Maps.AddItem(Map);
				}
			}
			break;
			
		case "official":
			`Log_Debug("official");
			foreach MapCycle(Map)
			{
				if (KFGI.IsMapAllowedInCycle(Map) && !IsCustomMap(Map))
				{
					Maps.AddItem(Map);
				}
			}
			break;
			
		case "custom":
			`Log_Debug("custom");
			foreach MapCycle(Map)
			{
				if (KFGI.IsMapAllowedInCycle(Map) && IsCustomMap(Map))
				{
					Maps.AddItem(Map);
				}
			}
			break;
			
		default:
			`Log_Debug("kf-");
			if (Left(LowerDefaultNextMap, 3) == "kf-")
			{
				Index = MapCycle.Find(LowerDefaultNextMap);
				if (Index != INDEX_NONE)
				{
					Maps.AddItem(MapCycle[Index]);
				}
			}
			break;
	}
	
	`Log_Debug("AviableMaps:"); foreach Maps(Map) `Log_Debug(Map);
	
	return Maps;
}

private function bool IsCustomMap(String MapName)
{
	local KFMapSummary MapData;
	
	`Log_Trace();
	
	MapData = class'KFUIDataStore_GameResource'.static.GetMapSummaryFromMapName(MapName);
	if (MapData == None)
	{
		return true;
	}
	else
	{
		return (MapData.MapAssociation == EAI_Custom);
	}
}

private function int DefaultNextMapIndex()
{
	local KFGameInfo KFGI;
	local Array<String> AviableMaps;
	local Array<String> MapCycle;
	local int CurrentMapIndex;
	
	`Log_Trace();
	
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI == None) return INDEX_NONE;

	MapCycle    = ActiveMapCycle();
	AviableMaps = GetAviableMaps();
	
	if (MapCycle.Length > 0 && AviableMaps.Length > 0)
	{
		if (CfgMapVote.default.bRandomizeNextMap)
		{
			return MapCycle.Find(AviableMaps[Rand(AviableMaps.Length)]);
		}
		else
		{
			// I don't use KFGameInfo.GetNextMap() because
			// it uses and changes global KFGameInfo.MapCycleIndex variable
			CurrentMapIndex = MapCycle.Find(WorldInfo.GetMapName(true));
			if (CurrentMapIndex != INDEX_NONE)
			{
				for (++CurrentMapIndex; CurrentMapIndex < MapCycle.Length; ++CurrentMapIndex)
				{
					if (AviableMaps.Find(MapCycle[CurrentMapIndex]) != INDEX_NONE)
					{
						return CurrentMapIndex;
					}
				}
			}
			for (CurrentMapIndex = 0; CurrentMapIndex < MapCycle.Length; ++CurrentMapIndex)
			{
				if (AviableMaps.Find(MapCycle[CurrentMapIndex]) != INDEX_NONE)
				{
					return CurrentMapIndex;
				}
			}
		}
	}
	
	return INDEX_NONE;
}

private function String MapNameByIndex(int MapIndex)
{
	local Array<String> MapCycle;
	
	`Log_Trace();
	
	if (MapIndex == INDEX_NONE) return "";
	
	MapCycle = ActiveMapCycle();
	
	if (MapIndex >= MapCycle.Length) return "";
	
	return MapCycle[MapIndex];
}

public function int GetNextMap()
{
	local int MapIndex;
	local String MapName;
	
	`Log_Trace();
	
	if (CfgMapStat.default.bEnable)
	{
		if (WorldInfo.GRI != None)
		{
			CfgMapStats.static.IncMapStat(
				WorldInfo.GetMapName(true),
				WorldInfo.GRI.ElapsedTime / 60,
				CfgMapStat.default.SortPolicy,
				LogLevel);
		}
		else
		{
			`Log_Warn("WorldInfo.GRI is None, can't write map stats");
		}
	}

	if (MapVoteList.Length > 0)
	{
		MapIndex = MapVoteList[0].MapIndex;
		MapName  = MapNameByIndex(MapIndex);
		if (MapName != "")
		{
			`Log_Info("Next map (vote):" @ MapName);
		}
		else
		{
			`Log_Warn("Can't find next map (vote)");
		}
	}
	else
	{
		MapIndex = DefaultNextMapIndex();
		MapName = MapNameByIndex(MapIndex);
		if (MapName != "")
		{
			`Log_Info("Next map (default):" @ MapName);
		}
		else
		{
			`Log_Warn("Can't find next map (default)");
		}
	}

	return MapIndex;
}

defaultproperties
{
	AllowHudNotification = true;
}
