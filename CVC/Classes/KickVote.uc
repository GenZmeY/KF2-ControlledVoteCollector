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
