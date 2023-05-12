class StartWaveKickProtection extends Object
	config(CVC)
	abstract;

var public config int Waves;
var public config int MinLevel;

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

	if (default.Waves < 0)
	{
		`Log_Error("Waves" @ "(" $ default.Waves $ ")" @ "must be greater than or equal 0");
		default.Waves = 0;
	}

	if (default.MinLevel < 0 || default.MinLevel > 25)
	{
		`Log_Error("MinLevel" @ "(" $ default.MinLevel $ ")" @ "must be in range 0-25");
		default.MinLevel = 0;
	}
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	default.Waves    = 0;
	default.MinLevel = 0;
}

defaultproperties
{

}
