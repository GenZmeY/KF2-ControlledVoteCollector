class BaseVote extends Object
	config(CVC)
	abstract;

var public config String PositiveColorHex;
var public config String NegativeColorHex;
var public config bool   bChatNotifications;
var public config bool   bHudNotifications;
var public config float  DefferedClearHUD;

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

public static function Load(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	if (!IsValidHexColor(default.PositiveColorHex, LogLevel))
	{
		`Log_Error("PositiveColorHex" @ "(" $ default.PositiveColorHex $ ")" @ "is not valid hex color");
		default.PositiveColorHex = class'KFLocalMessage'.default.EventColor;
	}
	
	if (!IsValidHexColor(default.NegativeColorHex, LogLevel))
	{
		`Log_Error("NegativeColorHex" @ "(" $ default.NegativeColorHex $ ")" @ "is not valid hex color");
		default.NegativeColorHex = class'KFLocalMessage'.default.InteractionColor;
	}
	
	if (default.DefferedClearHUD < 0)
	{
		`Log_Error("DefferedClearHUD" @ "(" $ default.DefferedClearHUD $ ")" @ "must be greater than 0");
		default.DefferedClearHUD = 0.0f;
	}
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.bChatNotifications = true;
	default.bHudNotifications  = true;
	default.PositiveColorHex   = class'KFLocalMessage'.default.EventColor;
	default.NegativeColorHex   = class'KFLocalMessage'.default.InteractionColor;
	default.DefferedClearHUD   = 1.0f;
}

protected static function bool IsValidHexColor(String HexColor, E_LogLevel LogLevel)
{
	local byte Index;
	
	`Log_TraceStatic();
	
	if (len(HexColor) != 6) return false;
	
	HexColor = Locs(HexColor);
	
	for (Index = 0; Index < 6; ++Index)
	{
		switch (Mid(HexColor, Index, 1))
		{
			case "0": break;
			case "1": break;
			case "2": break;
			case "3": break;
			case "4": break;
			case "5": break;
			case "6": break;
			case "7": break;
			case "8": break;
			case "9": break;
			case "a": break;
			case "b": break;
			case "c": break;
			case "d": break;
			case "e": break;
			case "f": break;
			default: return false;
		}
	}

	return true;
}

defaultproperties
{

}
