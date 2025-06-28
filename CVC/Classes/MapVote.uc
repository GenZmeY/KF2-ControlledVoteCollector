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
