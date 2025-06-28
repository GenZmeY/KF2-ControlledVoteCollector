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

class BaseVote extends Object
	config(CVC)
	abstract;

var public config String PositiveColorHex;
var public config String NegativeColorHex;
var public config bool   bChatNotifications;
var public config bool   bHudNotifications;
var public config float  DefferedClearHUD;
var public config int    VoteTime;

public static function InitConfig(int Version, int LatestVersion, E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	switch (Version)
	{
		case `NO_CONFIG:
			ApplyDefault(LogLevel);

		case 1:
			default.VoteTime = class'KFVoteCollector'.default.VoteTime;

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

	if (default.VoteTime <= 0 || default.VoteTime > 255)
	{
		`Log_Error("VoteTime" @ "(" $ default.VoteTime $ ")" @ "must be in range 1-255");
		default.VoteTime = class'KFVoteCollector'.default.VoteTime;
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
	default.VoteTime           = class'KFVoteCollector'.default.VoteTime;
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
