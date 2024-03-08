class Mut extends KFMutator;

var private CVC CVC;

public simulated function bool SafeDestroy()
{
	return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
	Super.PreBeginPlay();

	if (WorldInfo.NetMode == NM_Client) return;

	foreach WorldInfo.DynamicActors(class'CVC', CVC)
	{
		break;
	}

	if (CVC == None)
	{
		CVC = WorldInfo.Spawn(class'CVC');
	}

	if (CVC == None)
	{
		`Log_Base("FATAL: Can't Spawn 'CVC'");
		SafeDestroy();
	}
}

public function AddMutator(Mutator M)
{
	if (M == Self) return;

	if (M.Class == Class)
		Mut(M).SafeDestroy();
	else
		Super.AddMutator(M);
}

public function NotifyLogin(Controller C)
{
	Super.NotifyLogin(C);

	CVC.NotifyLogin(C);
}

public function NotifyLogout(Controller C)
{
	Super.NotifyLogout(C);

	CVC.NotifyLogout(C);
}

defaultproperties
{
	GroupNames.Add("VoteCollector")
}