class MapStat extends Object
	config(CVC)
	abstract;

var public config bool   bEnable;
var public config String SortPolicy;

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

	switch (Locs(default.SortPolicy))
	{
		case "counterasc":        return;
		case "counterdesc":       return;
		case "nameasc":           return;
		case "namedesc":          return;
		case "playtimetotalasc":  return;
		case "playtimetotaldesc": return;
		case "playtimeavgasc":    return;
		case "playtimeavgdesc":   return;
	}

	`Log_Error("Can't load SortPolicy (" $ default.SortPolicy $ "), must be one of: CounterAsc CounterDesc NameAsc NameDesc PlaytimeTotalAsc PlaytimeTotalDesc PlaytimeAvgAsc PlaytimeAvgDesc");
	default.SortPolicy = "CounterDesc";
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	default.bEnable    = false;
	default.SortPolicy = "CounterDesc";
}

defaultproperties
{

}
