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

class CVC_LocalMessage extends Object
	abstract;

var const             String PlayerIsKickProtectedDefault;
var private localized String PlayerIsKickProtected;

var const             String PlayerIsStartWaveKickProtectedDefault;
var private localized String PlayerIsStartWaveKickProtected;

var const             String PlayerCantStartKickVoteDefault;
var private localized String PlayerCantStartKickVote;

var const             String PlayerPerkIsNotLoadedDefault;
var private localized String PlayerPerkIsNotLoaded;

var const             String KickVoteNotEnoughPlayersDefault;
var private localized String KickVoteNotEnoughPlayers;

var const             String KickVoteStartedDefault;
var private localized String KickVoteStarted;

var const             String KickVoteStartedForPlayerDefault;
var private localized String KickVoteStartedForPlayer;

var const             String KickVoteNotStartedForPlayerDefault;
var private localized String KickVoteNotStartedForPlayer;

var const             String VotedPlayersDefault;
var private localized String VotedPlayers;

var const             String DidntVotePlayersDefault;
var private localized String DidntVotePlayers;

enum E_CVC_LocalMessageType
{
	CVC_PlayerIsKickProtected,
	CVC_PlayerIsStartWaveKickProtected,
	CVC_PlayerCantStartKickVote,
	CVC_PlayerPerkIsNotLoaded,

	CVC_KickVoteNotEnoughPlayers,
	CVC_KickVoteStarted,
	CVC_KickVoteStartedForPlayer,
	CVC_KickVoteNotStartedForPlayer,

	CVC_KickVoteYesReceived,
	CVC_KickVoteNoReceived,
	CVC_KickVoteStartedHUD,
	CVC_KickVoteReceivedHUD,

	CVC_SkipVoteYesReceived,
	CVC_SkipVoteNoReceived,

	CVC_PauseVoteYesReceived,
	CVC_PauseVoteNoReceived,

	CVC_VoteProgressHUD,
};

private static function String ReplKicker(String Str, String Kicker)
{
	return Repl(Str, "<kicker>", Kicker, false);
}

private static function String ReplKickee(String Str, String Kickee)
{
	return Repl(Str, "<kickee>", Kickee, false);
}

private static function String ReplWaves(String Str, String Waves)
{
	return Repl(Str, "<waves>", Waves, false);
}

public static function String GetLocalizedString(
	E_LogLevel LogLevel,
	E_CVC_LocalMessageType LMT,
	optional String String1,
	optional String String2,
	optional String String3)
{
	`Log_TraceStatic();

	switch (LMT)
	{
		case CVC_PlayerIsKickProtected:
			return ReplKickee(default.PlayerIsKickProtected != "" ? default.PlayerIsKickProtected : default.PlayerIsKickProtectedDefault, String1);

		case CVC_PlayerIsStartWaveKickProtected:
			return ReplWaves(ReplKickee(default.PlayerIsStartWaveKickProtected != "" ? default.PlayerIsStartWaveKickProtected : default.PlayerIsStartWaveKickProtectedDefault, String1), String2);

		case CVC_PlayerCantStartKickVote:
			return ReplWaves(default.PlayerCantStartKickVote != "" ? default.PlayerCantStartKickVote : default.PlayerCantStartKickVoteDefault, String1);

		case CVC_PlayerPerkIsNotLoaded:
			return ReplKickee(default.PlayerPerkIsNotLoaded != "" ? default.PlayerPerkIsNotLoaded : default.PlayerPerkIsNotLoadedDefault, String1);

		case CVC_KickVoteNotEnoughPlayers:
			return ReplWaves(default.KickVoteNotEnoughPlayers != "" ? default.KickVoteNotEnoughPlayers : default.KickVoteNotEnoughPlayersDefault, String1);

		case CVC_KickVoteYesReceived:
			return (String1 $ ":" @ class'KFCommon_LocalizedStrings'.default.YesString);

		case CVC_KickVoteNoReceived:
			return (String1 $ ":" @ class'KFCommon_LocalizedStrings'.default.NoString);

		case CVC_KickVoteStartedHUD:
			return ReplKickee(ReplKicker((default.KickVoteStarted != "" ? default.KickVoteStarted : default.KickVoteStartedDefault), String1), String2) $ "\n" $ class'KFCommon_LocalizedStrings'.default.YesString $ ":" @ String3;

		case CVC_KickVoteReceivedHUD:
			return class'KFCommon_LocalizedStrings'.default.YesString $ ":" @ String1 $ "\n" $ class'KFCommon_LocalizedStrings'.default.NoString $ ":" @ String2;

		case CVC_KickVoteStarted:
			return ReplKickee(ReplKicker((default.KickVoteStarted != "" ? default.KickVoteStarted : default.KickVoteStartedDefault), String1), String2);

		case CVC_KickVoteStartedForPlayer:
			return ReplKicker((default.KickVoteStartedForPlayer != "" ? default.KickVoteStartedForPlayer : default.KickVoteStartedForPlayerDefault), String1);

		case CVC_KickVoteNotStartedForPlayer:
			return ReplKicker((default.KickVoteNotStartedForPlayer != "" ? default.KickVoteNotStartedForPlayer : default.KickVoteNotStartedForPlayerDefault), String1);

		case CVC_SkipVoteYesReceived:
			return (String1 $ ":" @ class'KFCommon_LocalizedStrings'.default.YesString);

		case CVC_SkipVoteNoReceived:
			return (String1 $ ":" @ class'KFCommon_LocalizedStrings'.default.NoString);

		case CVC_PauseVoteYesReceived:
			return (String1 $ ":" @ class'KFCommon_LocalizedStrings'.default.YesString);

		case CVC_PauseVoteNoReceived:
			return (String1 $ ":" @ class'KFCommon_LocalizedStrings'.default.NoString);

		case CVC_VoteProgressHUD:
			return (default.DidntVotePlayers != "" ? default.DidntVotePlayers : default.DidntVotePlayersDefault) @ String2 $ (String1 != "" ? ("\n" $ (default.VotedPlayers != "" ? default.VotedPlayers : default.VotedPlayersDefault) @ String1) : "");
	}

	return "";
}

defaultproperties
{
	PlayerIsKickProtectedDefault          = "<kickee> is protected from kick"
	PlayerIsStartWaveKickProtectedDefault = "You can't kick <kickee> right now. He can be kicked when he plays at least <waves> wave(s)"
	PlayerCantStartKickVoteDefault        = "You can't start kick vote now. You can start kick vote when you play at least <waves> wave(s)"
	PlayerPerkIsNotLoadedDefault          = "You can't kick a player who hasn't loaded yet (<kickee>)"
	KickVoteNotEnoughPlayersDefault       = "Not enough players to start vote (only players who have played at least <waves> wave(s) can vote)"
	KickVoteStartedDefault                = "<kicker> has started a vote to kick <kickee>"
	KickVoteStartedForPlayerDefault       = "<kicker> started voting to kick you"
	KickVoteNotStartedForPlayerDefault    = "<kicker> tried to kick you"
	VotedPlayersDefault                   = "Voted:"
	DidntVotePlayersDefault               = "Didn't vote:"
}