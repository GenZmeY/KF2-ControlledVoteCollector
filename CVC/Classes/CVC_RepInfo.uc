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

class CVC_RepInfo extends ReplicationInfo;

const CVCLMT = class'CVC_LocalMessage';

var public E_LogLevel LogLevel;
var public CVC CVC;
var public int StartWave;

var private KFPlayerController KFPC;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel;
}

public simulated function bool SafeDestroy()
{
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public reliable client function WriteToChatLocalized(E_CVC_LocalMessageType LMT, optional String HexColor, optional String String1, optional String String2, optional String String3)
{
	`Log_Trace();

	WriteToChat(CVCLMT.static.GetLocalizedString(LogLevel, LMT, String1, String2, String3), HexColor);
}

public reliable client function WriteToChat(String Message, optional String HexColor)
{
	local KFGFxHudWrapper HUD;

	`Log_Trace();

	if (GetKFPC() == None) return;

	if (KFPC.MyGFxManager.PartyWidget != None && KFPC.MyGFxManager.PartyWidget.PartyChatWidget != None)
	{
		KFPC.MyGFxManager.PartyWidget.PartyChatWidget.SetVisible(true);
		KFPC.MyGFxManager.PartyWidget.PartyChatWidget.AddChatMessage(Message, HexColor);
	}

	HUD = KFGFxHudWrapper(KFPC.myHUD);
	if (HUD != None && HUD.HUDMovie != None && HUD.HUDMovie.HudChatBox != None)
	{
		HUD.HUDMovie.HudChatBox.AddChatMessage(Message, HexColor);
	}
}

public reliable client function WriteToHUDLocalized(E_CVC_LocalMessageType LMT, optional String String1, optional String String2, optional String String3, optional float DisplayTime = 0.0f)
{
	`Log_Trace();

	WriteToHUD(CVCLMT.static.GetLocalizedString(LogLevel, LMT, String1, String2, String3), DisplayTime);
}

public reliable client function WriteToHUD(String Message, optional float DisplayTime = 0.0f)
{
	`Log_Trace();

	if (GetKFPC() == None) return;

	if (DisplayTime == 0.0f)
	{
		DisplayTime = CalcDisplayTime(Message);
	}

	if (KFPC.MyGFxHUD != None)
	{
		KFPC.MyGFxHUD.DisplayMapText(Message, DisplayTime, false);
	}
}

public reliable client function DefferedClearMessageHUD(optional float Time = 0.0f)
{
	`Log_Trace();

	SetTimer(Time, false, nameof(ClearMessageHUD));
}

public reliable client function ClearMessageHUD()
{
	`Log_Trace();

	if (GetKFPC() == None) return;

	if (KFPC.MyGFxHUD != None && KFPC.MyGFxHUD.MapTextWidget != None)
	{
		KFPC.MyGFxHUD.MapTextWidget.StoredMessageList.Length = 0;
		KFPC.MyGFxHUD.MapTextWidget.HideMessage();
	}
}

private function float CalcDisplayTime(String Message)
{
	`Log_Trace();

	return FClamp(Len(Message) / 20.0f, 3, 30);
}

public simulated function KFPlayerController GetKFPC()
{
	`Log_Trace();

	if (KFPC != None) return KFPC;

	KFPC = KFPlayerController(Owner);

	if (KFPC == None && ROLE < ROLE_Authority)
	{
		KFPC = KFPlayerController(GetALocalPlayerController());
	}

	return KFPC;
}

defaultproperties
{
	bAlwaysRelevant               = false
	bOnlyRelevantToOwner          = true
	bSkipActorPropertyReplication = false
}
