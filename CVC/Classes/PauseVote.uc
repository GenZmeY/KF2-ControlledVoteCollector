class PauseVote extends BaseVote
	config(CVC)
	abstract;

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	Super.ApplyDefault(LogLevel);
	
	default.PositiveColorHex   = class'KFLocalMessage'.default.GameColor;
	default.bChatNotifications = false;
	default.bHudNotifications  = false;
}

defaultproperties
{

}
