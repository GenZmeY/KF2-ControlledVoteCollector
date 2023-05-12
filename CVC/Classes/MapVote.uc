class MapVote extends Object
	config(CVC)
	abstract;

var public config String DefaultNextMap; // Any, Official, Custom, KF-<MapName>
var public config bool   bRandomizeNextMap;

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
	local String LowerDefaultNextMap;

	`Log_TraceStatic();

	LowerDefaultNextMap = Locs(default.DefaultNextMap);

	switch (LowerDefaultNextMap)
	{
		case "any":      return;
		case "official": return;
		case "custom":   return;
		default: if (Left(LowerDefaultNextMap, 3) == "kf-") return;
	}

	`Log_Error("Can't load DefaultNextMap (" $ default.DefaultNextMap $ "), must be one of: Any Official Custom KF-<MapName>");
	default.DefaultNextMap = "Any";
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	default.bRandomizeNextMap = true;
	default.DefaultNextMap    = "Any";
}

defaultproperties
{

}
