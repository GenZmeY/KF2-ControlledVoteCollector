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
