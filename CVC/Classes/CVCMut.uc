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