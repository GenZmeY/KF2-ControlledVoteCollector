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

class MapStats extends Object
	config(MapStats);

struct MapStatEntry
{
	var String Name;       // map
	var int Counter;       // play count
	var int PlayTimeTotal; // minutes total
	var int PlayTimeAvg;   // minutes per map
};
var config array<MapStatEntry> MapStat;

static delegate int CounterAsc        (MapStatEntry A, MapStatEntry B) { return B.Counter       < A.Counter       ? -1 : 0; }
static delegate int CounterDesc       (MapStatEntry A, MapStatEntry B) { return A.Counter       < B.Counter       ? -1 : 0; }
static delegate int NameAsc           (MapStatEntry A, MapStatEntry B) { return B.Name          < A.Name          ? -1 : 0; }
static delegate int NameDesc          (MapStatEntry A, MapStatEntry B) { return A.Name          < B.Name          ? -1 : 0; }
static delegate int PlayTimeTotalAsc  (MapStatEntry A, MapStatEntry B) { return B.PlayTimeTotal < A.PlayTimeTotal ? -1 : 0; }
static delegate int PlayTimeTotalDesc (MapStatEntry A, MapStatEntry B) { return A.PlayTimeTotal < B.PlayTimeTotal ? -1 : 0; }
static delegate int PlayTimeAvgAsc    (MapStatEntry A, MapStatEntry B) { return B.PlayTimeAvg   < A.PlayTimeAvg   ? -1 : 0; }
static delegate int PlayTimeAvgDesc   (MapStatEntry A, MapStatEntry B) { return A.PlayTimeAvg   < B.PlayTimeAvg   ? -1 : 0; }

static function SortMapStat(String SortPolicy, E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	switch (Locs(SortPolicy))
	{
		case "counterasc":        default.MapStat.Sort(CounterAsc);        break;
		case "counterdesc":       default.MapStat.Sort(CounterDesc);       break;
		case "nameasc":           default.MapStat.Sort(NameAsc);           break;
		case "namedesc":          default.MapStat.Sort(NameDesc);          break;
		case "playtimetotalasc":  default.MapStat.Sort(PlayTimeTotalAsc);  break;
		case "playtimetotaldesc": default.MapStat.Sort(PlayTimeTotalDesc); break;
		case "playtimeavgasc":    default.MapStat.Sort(PlayTimeAvgAsc);    break;
		case "playtimeavgdesc":   default.MapStat.Sort(PlayTimeAvgDesc);   break;
	}
}

static function IncMapStat(String Map, int PlayTime, String SortPolicy, E_LogLevel LogLevel)
{
	local int MapStatEntryIndex;
	local MapStatEntry NewEntry;

	`Log_TraceStatic();

	MapStatEntryIndex = default.MapStat.Find('Name', Map);
	if (MapStatEntryIndex == INDEX_NONE)
	{
		NewEntry.Name          = Map;
		NewEntry.Counter       = 1;
		NewEntry.PlayTimeTotal = PlayTime;
		NewEntry.PlayTimeAvg   = PlayTime;
		default.MapStat.AddItem(NewEntry);
	}
	else
	{
		default.MapStat[MapStatEntryIndex].Counter++;
		default.MapStat[MapStatEntryIndex].PlayTimeTotal += PlayTime;
		default.MapStat[MapStatEntryIndex].PlayTimeAvg = default.MapStat[MapStatEntryIndex].PlayTimeTotal / default.MapStat[MapStatEntryIndex].Counter;
	}

	SortMapStat(SortPolicy, LogLevel);

	StaticSaveConfig();
}

defaultproperties
{

}
