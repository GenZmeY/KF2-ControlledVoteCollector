class CVC_LocalMessage extends Object
	abstract;

var const             String PlayerIsKickProtectedDefault;
var private localized String PlayerIsKickProtected;

var const             String PlayerIsStartWaveKickProtectedDefault;
var private localized String PlayerIsStartWaveKickProtected;

var const             String PlayerCantVoteDefault;
var private localized String PlayerCantVote;

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

// TODO:
/*
Kick vote hud:
start vote + only yes votes:
header: <player vote for player>
second line: yes votes

pause and skip:
first line: voted players
second line: dont voted players
*/

enum E_CVC_LocalMessageType
{
	CVC_PlayerIsKickProtected,
	CVC_PlayerIsStartWaveKickProtected,
	CVC_PlayerCantVote,
	
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
			
		case CVC_PlayerCantVote:
			return ReplWaves(default.PlayerCantVote != "" ? default.PlayerCantVote : default.PlayerCantVoteDefault, String1);
			
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
			return (default.VotedPlayers != "" ? default.VotedPlayers : default.VotedPlayersDefault) @ String1 $ (String2 != "" ? ("\n" $ (default.DidntVotePlayers != "" ? default.DidntVotePlayers : default.DidntVotePlayersDefault) @ String2) : "");
	}
	
	return "";
}

defaultproperties
{
	PlayerIsKickProtectedDefault          = "<kickee> is protected from kick"
	PlayerIsStartWaveKickProtectedDefault = "You can't kick <kickee> right now. He can be kicked when he plays at least <waves> wave(s)"
	PlayerCantVoteDefault                 = "You can't vote for kick now. You can vote when you play at least <waves> wave(s)"
	KickVoteNotEnoughPlayersDefault       = "Not enough players to start vote (only players who have played at least <waves> wave(s) can vote)"
	KickVoteStartedDefault                = "<kicker> has started a vote to kick <kickee>"
	KickVoteStartedForPlayerDefault       = "<kicker> started voting to kick you"
	KickVoteNotStartedForPlayerDefault    = "<kicker> tried to kick you"
	VotedPlayersDefault                   = "Voted:"
	DidntVotePlayersDefault               = "Didn't vote:"
}