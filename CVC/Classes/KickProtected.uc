class KickProtected extends Object
	config(CVC)
	abstract;

var public  config bool          NotifyPlayerAboutKickAttempt;
var private config Array<String> PlayerID;

public static function InitConfig(int Version, int LatestVersion, E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	switch (Version)
	{
		case `NO_CONFIG:
			ApplyDefault(LogLevel);
			
		default: break;
	}
	
	if (LatestVersion != Version)
	{
		StaticSaveConfig();
	}
}

public static function Array<UniqueNetId> Load(E_LogLevel LogLevel)
{
	local Array<UniqueNetId> UIDs;
	local UniqueNetId UID;
	local String ID;
	
	`Log_TraceStatic();
	
	foreach default.PlayerID(ID)
	{
		if (AnyToUID(ID, UID, LogLevel))
		{
			UIDs.AddItem(UID);
		}
		else
		{
			`Log_Warn("Can't load PlayerID:" @ ID);
		}
	}
	
	return UIDs;
}

private static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.NotifyPlayerAboutKickAttempt = true;
	default.PlayerID.Length = 0;
	default.PlayerID.AddItem("76561190000000000");
	default.PlayerID.AddItem("0x0000000000000000");
}

private static function bool IsUID(String ID, E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	return (Left(ID, 2) ~= "0x");
}

private static function bool AnyToUID(String ID, out UniqueNetId UID, E_LogLevel LogLevel)
{
	local OnlineSubsystem OS;
	
	`Log_TraceStatic();
	
	OS = class'GameEngine'.static.GetOnlineSubsystem();
	
	if (OS == None) return false;
	
	return IsUID(ID, LogLevel) ? OS.StringToUniqueNetId(ID, UID) : OS.Int64ToUniqueNetId(ID, UID);
}

defaultproperties
{

}
