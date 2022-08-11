class KickVote extends BaseVote
	config(CVC)
	abstract;

var public config bool   bHudNotificationsOnlyOnTraderTime;
var public config int    MinVotingPlayersToStartKickVote;
var public config int    MaxKicks;
var public config bool   bLogKickVote;
var public config String WarningColorHex;

public static function Load(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	if (default.MinVotingPlayersToStartKickVote < 2)
	{
		`Log_Error("MinVotingPlayersToStartKickVote" @ "(" $ default.MinVotingPlayersToStartKickVote $ ")" @ "must be greater than 1");
		default.MinVotingPlayersToStartKickVote = 2;
	}
	
	if (default.MaxKicks < 1)
	{
		`Log_Error("MaxKicks" @ "(" $ default.MaxKicks $ ")" @ "must be greater than 0");
		default.MaxKicks = 2;
	}
	
	if (!IsValidHexColor(default.WarningColorHex, LogLevel))
	{
		`Log_Error("WarningColorHex" @ "(" $ default.WarningColorHex $ ")" @ "is not valid hex color");
		default.WarningColorHex = class'KFLocalMessage'.default.PriorityColor;
	}
	
	Super.Load(LogLevel);
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	Super.ApplyDefault(LogLevel);
	
	default.bHudNotificationsOnlyOnTraderTime = true;
	default.MinVotingPlayersToStartKickVote   = 2;
	default.MaxKicks                          = 2;
	default.DefferedClearHUD                  = 2.0f;
	default.WarningColorHex                   = class'KFLocalMessage'.default.PriorityColor;
}

defaultproperties
{

}
