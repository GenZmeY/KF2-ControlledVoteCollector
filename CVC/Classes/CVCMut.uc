class CVCMut extends KFMutator;
	
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
		`Log_Base("Found 'CVC'");
		break;
	}
	
	if (CVC == None)
	{
		`Log_Base("Spawn 'CVC'");
		CVC = WorldInfo.Spawn(class'CVC');
	}
	
	if (CVC == None)
	{
		`Log_Base("Can't Spawn 'CVC', Destroy...");
		SafeDestroy();
	}
}

public function AddMutator(Mutator Mut)
{
	if (Mut == Self) return;
	
	if (Mut.Class == Class)
		Mut.Destroy();
	else
		Super.AddMutator(Mut);
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

DefaultProperties
{

}