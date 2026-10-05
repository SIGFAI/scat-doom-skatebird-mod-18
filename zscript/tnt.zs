// Creeper Cat: the cat that learned from Minecraft. It runs at you, hisses, swells, flashes white and blows up,
// hurting every cat around it too. Killed first, it just poofs (like a real creeper).
class CreeperCat : CubeCat replaces Demon
{
	Default
	{
		Health 90;
		Speed 11;
		PainChance 150;
		MeleeRange 80;
		CubeCat.XPDrop 4;
		Tag "Creeper Cat";
		Obituary "%o met a Creeper Cat. Sssss... BOOM.";
	}
	States
	{
	Spawn:
		CRPC AB 10 A_Look;
		loop;
	See:
		CRPC AABBCCDD 2 A_Chase("Melee", null);
		loop;
	Melee:
		CRPC A 0 A_StartSound("creeper/fuse", CHAN_VOICE);
		CRPC E 5 A_FaceTarget;
		CRPC F 4;
		CRPC E 5;
		CRPC F 4;
		CRPC E 4;
		CRPC F 3;
		CRPC E 3;
		CRPC F 3;
		CRPC F 0 A_CreeperBlast;
		stop;
	Pain:
		CRPC G 3;
		CRPC G 3 A_Pain;
		goto See;
	Death:
		CRPC H 4 A_Scream;
		CRPC I 4 A_NoBlocking;
		CRPC I 12;
		TNT1 A 1 A_MCDeath;
		stop;
	}

	void A_CreeperBlast()
	{
		A_StopSound(CHAN_VOICE);
		Console.PrintfEx(PRINT_NONOTIFY, "SIC_CREEPER_BOOM");
		MCFx.Boom(self, 1.3);
		bShootable = false;
		A_Explode(70, 160, XF_NOTMISSILE);
		A_NoBlocking();
	}
}


// TNT block (replaces the exploding barrel). Shot, it hops, blinks white with a fizzing fuse, then blows up
// and takes every cat nearby with it.
class MCTnt : Actor replaces ExplosiveBarrel
{
	Default
	{
		Health 20;
		Radius 15;
		Height 32;
		Mass 1000;
		Scale 0.3333;
		+SOLID
		+SHOOTABLE
		+NOBLOOD
		+DONTGIB
		+NOICEDEATH
		+ACTIVATEMCROSS
		+OLDRADIUSDMG
		Obituary "%o was blown up by TNT.";
		Tag "TNT";
	}
	States
	{
	Spawn:
		TNTB A -1;
		stop;
	Death:
		TNTB B 4 { A_StartSound("mc/fuse", CHAN_VOICE); vel.z = 5; }
		TNTB A 4;
		TNTB B 4;
		TNTB A 4;
		TNTB B 3;
		TNTB A 3;
		TNTB B 2;
		TNTB A 2;
		TNTB B 2;
		TNT1 A 0
		{
			A_StopSound(CHAN_VOICE);
			MCFx.Boom(self, 1.6);
			A_Explode(128, 170);
			A_NoBlocking();
		}
		TNT1 A 20;
		stop;
	}
}
