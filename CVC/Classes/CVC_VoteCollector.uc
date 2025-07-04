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

var private KFGameInfo KFGI;

var private KFPlayerController KFPC_Kicker;
var private KFPlayerController KFPC_Kickee;

var private String KickerName;
var private String KickeeName;

var private String YesVotesPlayers, NoVotesPlayers;

var private bool AllowHudNotification;
var private bool AllowSTPNotification; // SkipTrader and Pause

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel;
}

private function KFGameInfo GetKFGI()
{
	`Log_Trace();

	if (KFGI != None) return KFGI;

	KFGI = KFGameInfo(WorldInfo.Game);

	return KFGI;
}

public function ServerStartVoteKick(PlayerReplicationInfo PRI_Kickee, PlayerReplicationInfo PRI_Kicker)
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;

	`Log_Trace();

	if (GetKFGI() == None) return;

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

	if (!CVC.PlayerCanStartKickVote(KFPC_Kicker, KFPC_Kickee))
	{
		CVC.WriteToChatLocalized(
			KFPC_Kicker,
			CVC_PlayerCantStartKickVote,
			CfgKickVote.default.WarningColorHex,
			String(CfgStartWaveKickProtection.default.Waves));
		return;
	}

	if (!CVC.PlayerPerkLoaded(PRI_Kickee))
	{
		CVC.WriteToChatLocalized(
			KFPC_Kicker,
			CVC_PlayerPerkIsNotLoaded,
			CfgKickVote.default.WarningColorHex,
			KickeeName);
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
			KFPRI.ShowKickVote(PRI_Kickee, CfgKickVote.default.VoteTime, !(KFPRI == PRI_Kicker || KFPRI == PRI_Kickee));
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
				KickerName);
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

		SetTimer(CfgKickVote.default.VoteTime, false, nameof(ConcludeVoteKick), Self);

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
		if (KFPC != None && KFPC != KFPC_Kickee)
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
					float(CfgKickVote.default.VoteTime),
					KickerName,
					KickeeName,
					YesVotesPlayers);
			}
			else
			{
				CVC.BroadcastHUDLocalized(
					CVC_KickVoteReceivedHUD,
					float(CfgKickVote.default.VoteTime),
					YesVotesPlayers,
					NoVotesPlayers);
			}
		}
	}

	Super.RecieveVoteKick(PRI, bKick);
}

public function bool ShouldConcludeKickVote()
{
	local int NumPRIs;
	local int KickVotesNeeded;

	`Log_Trace();

	if (CfgStartWaveKickProtection.default.Waves == 0)
	{
		return Super.ShouldConcludeKickVote();
	}

	NumPRIs = VotingPlayers();

	if (YesVotes + NoVotes >= NumPRIs)
	{
		return true;
	}
	else if (GetKFGI() != None)
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
	else if (bIsKickVoteInProgress && GetKFGI() != None)
	{
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
	`Log_Kick("Kicked:" @ LogVotePlayer(Kickee));

	`Log_Kick("Yes voters:");
	foreach Yes(KV) `Log_Kick(LogVotePlayer(KV));

	if (No.Length == 0) return;

	`Log_Kick("No voters:");
	foreach No(KV) `Log_Kick(LogVotePlayer(KV));
}

private function String LogVotePlayer(S_KickVote KV)
{
	`Log_Trace();

	return KV.Name @ "(UniqueID:" @ KV.UniqueID $ (KV.SteamID == "" ? "" : (", SteamID:" @ KV.SteamID $ ", Profile:" @ "https://steamcommunity.com/profiles/" $ KV.SteamID)) $ ")" @ "Perk:" @ Repl(String(KV.Perk), "KFPerk_", "", false) @ "Level:" @ String(KV.Level);
}

public function ServerStartVoteSkipTrader(PlayerReplicationInfo PRI)
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local byte TraderTimeRemaining;

	KFPC = KFPlayerController(PRI.Owner);

	if (GetKFGI() == None) return;

	if (PRI.bOnlySpectator)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_SkipTraderVoteNoSpectators);
		return;
	}

	if (!bTraderIsOpen && !bForceShowSkipTrader)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_SkipTraderIsNotOpen);
		return;
	}

	if (bIsKickVoteInProgress || bIsPauseGameVoteInProgress)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_OtherVoteInProgress);
		return;
	}

	TraderTimeRemaining = GetTraderTimeRemaining();
	if(TraderTimeRemaining <= SkipTraderVoteLimit)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_SkipTraderNoEnoughTime);
		return;
	}

	if (!bIsSkipTraderVoteInProgress)
	{
		PlayersThatHaveVoted.Length = 0;

		CurrentSkipTraderVote.PlayerID = PRI.UniqueId;
		CurrentSkipTraderVote.PlayerPRI = PRI;
		CurrentSkipTraderVote.PlayerIPAddress = KFPC.GetPlayerNetworkAddress();

		bIsSkipTraderVoteInProgress = true;

		if (bStopCountDown)
		{
			CurrentVoteTime = CfgSkipTraderVote.default.VoteTime;
		}
		else
		{
			CurrentVoteTime = Min(CfgSkipTraderVote.default.VoteTime, TraderTimeRemaining - SkipTraderVoteLimit);
		}

		GetKFPRIArray(KFPRIs, , false);
		foreach KFPRIs(KFPRI)
		{
			KFPRI.ShowSkipTraderVote(PRI, CurrentVoteTime, !(KFPRI == PRI) && PRI.GetTeamNum() != 255);
		}

		AllowSTPNotification = KFPRIs.Length > 1;

		KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_SkipTraderVoteStarted, CurrentSkipTraderVote.PlayerPRI);
		SetTimer(CurrentVoteTime, false, nameof(ConcludeVoteSkipTrader), Self);
		SetTimer(1, true, nameof(UpdateTimer), Self);

		RecieveVoteSkipTrader(PRI, true);

		KFPlayerReplicationInfo(PRI).bAlreadyStartedASkipTraderVote = true;
	}
	else
	{
		KFPlayerController(PRI.Owner).ReceiveLocalizedMessage(class'KFLocalMessage', LMT_SkipTraderVoteInProgress);
	}
}

public reliable server function UpdateTimer()
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;
	local int VoteTimeLimit;

	CurrentVoteTime--;

	VoteTimeLimit = GetTraderTimeRemaining() - SkipTraderVoteLimit;
	if (!bStopCountDown && CurrentVoteTime > VoteTimeLimit)
	{
		CurrentVoteTime = VoteTimeLimit;
	}

	GetKFPRIArray(KFPRIs, , false);
	foreach KFPRIs(KFPRI)
	{
		KFPRI.UpdateSkipTraderTime(CurrentVoteTime);
	}

	if (CurrentVoteTime <= 0)
	{
		ConcludeVoteSkipTrader();
	}
}

public reliable server function RecieveVoteSkipTrader(PlayerReplicationInfo PRI, bool bSkip)
{
	local bool MustNotify;

	`Log_Trace();

	MustNotify = (PlayersThatHaveVoted.Find(PRI) == INDEX_NONE && AllowSTPNotification);

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
				float(CfgSkipTraderVote.default.VoteTime),
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

		ClearTimer(nameof(ConcludeVoteSkipTrader), Self);
		ClearTimer(nameof(UpdateTimer), Self);
	}

	Super.ConcludeVoteSkipTrader();
}

public function ServerStartVotePauseGame(PlayerReplicationInfo PRI)
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local byte WaveTimeRemaining;

	if (GetKFGI() == None) return;

	KFPC  = KFPlayerController(PRI.Owner);

	if (PRI.bOnlySpectator)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', bIsEndlessPaused ? LMT_ResumeVoteNoSpectators : LMT_PauseVoteNoSpectators);
		return;
	}

	if (bWaveIsActive)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', bIsEndlessPaused ? LMT_ResumeVoteWaveActive : LMT_PauseVoteWaveActive);
		return;
	}

	if (!bEndlessMode)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_PauseVoteWrongMode);
		return;
	}

	if (bIsKickVoteInProgress || bIsSkipTraderVoteInProgress)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_OtherVoteInProgress);
		return;
	}

	WaveTimeRemaining = GetTraderTimeRemaining();
	if (WaveTimeRemaining <= PauseGameVoteLimit)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', bIsEndlessPaused ? LMT_ResumeVoteNoEnoughTime : LMT_PauseVoteNoEnoughTime);
		return;
	}

	if (!bIsPauseGameVoteInProgress)
	{
		PlayersThatHaveVoted.Length = 0;

		CurrentPauseGameVote.PlayerID = PRI.UniqueId;
		CurrentPauseGameVote.PlayerPRI = PRI;
		CurrentPauseGameVote.PlayerIPAddress = KFPC.GetPlayerNetworkAddress();

		bIsPauseGameVoteInProgress = true;

		if (bStopCountDown)
		{
			CurrentVoteTime = CfgPauseVote.default.VoteTime;
		}
		else
		{
			CurrentVoteTime = Min(CfgPauseVote.default.VoteTime, WaveTimeRemaining - PauseGameVoteLimit);
		}

		GetKFPRIArray(KFPRIs);
		foreach KFPRIs(KFPRI)
		{
			KFPRI.ShowPauseGameVote(PRI, CurrentVoteTime, !(KFPRI == PRI));
		}

		AllowSTPNotification = KFPRIs.Length > 1;

		KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', bIsEndlessPaused ? LMT_ResumeVoteStarted : LMT_PauseVoteStarted, CurrentPauseGameVote.PlayerPRI);
		SetTimer(CurrentVoteTime, false, nameof(ConcludeVotePauseGame), Self);
		SetTimer(1, true, nameof(UpdatePauseGameTimer), Self);

		ReceiveVotePauseGame(PRI, true);

		KFPlayerReplicationInfo(PRI).bAlreadyStartedAPauseGameVote = true;
	}
	else
	{
		KFPlayerController(PRI.Owner).ReceiveLocalizedMessage(class'KFLocalMessage', bIsEndlessPaused ? LMT_ResumeVoteInProgress : LMT_PauseVoteInProgress);
	}
}

public reliable server function UpdatePauseGameTimer() // TODO:
{
	local Array<KFPlayerReplicationInfo> KFPRIs;
	local KFPlayerReplicationInfo KFPRI;
	local int VoteTimeLimit;

	CurrentVoteTime--;

	VoteTimeLimit = GetTraderTimeRemaining() - PauseGameVoteLimit;
	if (!bStopCountDown && CurrentVoteTime > VoteTimeLimit)
	{
		CurrentVoteTime = VoteTimeLimit;
	}

	GetKFPRIArray(KFPRIs);
	foreach KFPRIs(KFPRI)
	{
		KFPRI.UpdatePauseGameTime(CurrentVoteTime);
	}

	if (CurrentVoteTime <= 0)
	{
		ConcludeVotePauseGame();
	}
}

public reliable server function ReceiveVotePauseGame(PlayerReplicationInfo PRI, bool bSkip)
{
	local bool MustNotify;

	`Log_Trace();

	MustNotify = (PlayersThatHaveVoted.Find(PRI) == INDEX_NONE && AllowSTPNotification);

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
				float(CfgPauseVote.default.VoteTime),
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

		ClearTimer(nameof(ConcludeVotePauseGame), Self);
		ClearTimer(nameof(UpdatePauseGameTimer), Self);
	}

	Super.ConcludeVotePauseGame();
}

private function Array<String> ActiveMapCycle()
{
	`Log_Trace();

	if (WorldInfo.NetMode == NM_Standalone)
	{
		return Maplist;
	}

	if (GetKFGI() != None)
	{
		return KFGI.GameMapCycles[KFGI.ActiveMapCycle].Maps;
	}
}

private function Array<String> GetAviableMaps()
{
	local String LowerDefaultNextMap;
	local Array<String> MapCycle;
	local Array<String> Maps;
	local String Map;
	local int Index;

	`Log_Trace();

	if (GetKFGI() == None) return Maps;

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
	local Array<String> AviableMaps;
	local Array<String> MapCycle;
	local int CurrentMapIndex;

	`Log_Trace();

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
	AllowSTPNotification = true;
}
