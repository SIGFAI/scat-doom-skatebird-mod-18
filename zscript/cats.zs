// The SuperIntelligent Cat's army: blocky cube cats (Kenney Cube Pets cat, rendered from 8 angles).
// They replace Doom's soldiers and imps, throw cube fish, flash red when hit and die the Minecraft way:
// they tip over, poof into grey smoke and drop experience orbs.
class CubeCat : Actor replaces DoomImp
{
	int xpDrop;
	Property XPDrop : xpDrop;

	Default
	{
		Health 60;
		Radius 18;
		Height 44;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		+NOBLOOD   // Minecraft mobs don't bleed: hits throw red sparks instead
		SeeSound "cat/sight";
		PainSound "cat/pain";
		DeathSound "cat/death";
		ActiveSound "cat/sight";
		Obituary "%o got slapped with a fish by a cube cat.";
		HitObituary "%o got scratched by a cube cat.";
		Tag "Cube Cat";
		Scale 0.3333; // sprites are stored 3x for crisp pixels
		CubeCat.XPDrop 3;
	}
	States
	{
	Spawn:
		CATG AB 10 A_Look;
		loop;
	See:
		CATG AABBCCDD 3 A_Chase;
		loop;
	Melee:
		CATG E 6 A_FaceTarget;
		CATG F 6 A_CustomMeleeAttack(random(2, 5) * 3, "cat/pain", "", 'Melee');
		goto See;
	Missile:
		CATG E 10 A_FaceTarget;
		CATG F 6 A_ThrowFish;
		CATG E 4;
		goto See;
	Pain:
		CATG G 3;
		CATG G 3 A_Pain;
		goto See;
	Death:
		CATG H 4 A_Scream;
		CATG I 4 A_NoBlocking;
		CATG J 14;
		TNT1 A 1 A_MCDeath;
		stop;
	}

	virtual void A_ThrowFish()
	{
		A_StartSound("cat/throw", CHAN_WEAPON);
		A_SpawnProjectile("CatFish", 28);
	}

	void A_MCDeath()
	{
		MCFx.Poof(self, 10, 0.85);
		MCFx.DropXP(self, xpDrop);
	}
}

// Replaces the Zombieman: a smaller, weaker ginger cat.
class KittenCat : CubeCat replaces ZombieMan
{
	Default
	{
		Health 35;
		Scale 0.2833;
		Radius 16;
		Height 38;
		CubeCat.XPDrop 2;
		Tag "Cube Kitten";
	}
	States
	{
	Spawn:
		CATG AB 10 A_Look;
		loop;
	See:
		CATG AABBCCDD 3 A_Chase;
		loop;
	Melee:
		CATG E 6 A_FaceTarget;
		CATG F 6 A_CustomMeleeAttack(random(2, 4) * 3, "cat/pain", "", 'Melee');
		goto See;
	Missile:
		CATG E 12 A_FaceTarget;
		CATG F 6 A_ThrowFish;
		CATG E 4;
		goto See;
	Pain:
		CATG G 3;
		CATG G 3 A_Pain;
		goto See;
	Death:
		CATG H 4 A_Scream;
		CATG I 4 A_NoBlocking;
		CATG J 14;
		TNT1 A 1 A_MCDeath;
		stop;
	}
}

// Replaces the Shotgun Guy: a black cat that throws three fish at once.
class BlackCat : CubeCat replaces ShotgunGuy
{
	Default
	{
		Health 50;
		CubeCat.XPDrop 3;
		Tag "Black Cat";
	}
	States
	{
	Spawn:
		CATT AB 10 A_Look;
		loop;
	See:
		CATT AABBCCDD 3 A_Chase;
		loop;
	Melee:
		CATT E 6 A_FaceTarget;
		CATT F 6 A_CustomMeleeAttack(random(2, 5) * 3, "cat/pain", "", 'Melee');
		goto See;
	Missile:
		CATT E 10 A_FaceTarget;
		CATT F 6 A_ThrowFish;
		CATT E 4;
		goto See;
	Pain:
		CATT G 3;
		CATT G 3 A_Pain;
		goto See;
	Death:
		CATT H 4 A_Scream;
		CATT I 4 A_NoBlocking;
		CATT J 14;
		TNT1 A 1 A_MCDeath;
		stop;
	}

	override void A_ThrowFish()
	{
		A_StartSound("cat/throw", CHAN_WEAPON);
		for (int i = -1; i <= 1; i++) A_SpawnProjectile("CatFish", 28, 0, i * 9);
	}
}

// Replaces the Chaingunner: a Siamese cat that throws a quick volley.
class SiameseCat : CubeCat replaces ChaingunGuy
{
	Default
	{
		Health 70;
		CubeCat.XPDrop 4;
		Tag "Siamese Cat";
	}
	States
	{
	Spawn:
		CATS AB 10 A_Look;
		loop;
	See:
		CATS AABBCCDD 3 A_Chase;
		loop;
	Melee:
		CATS E 6 A_FaceTarget;
		CATS F 6 A_CustomMeleeAttack(random(2, 5) * 3, "cat/pain", "", 'Melee');
		goto See;
	Missile:
		CATS E 8 A_FaceTarget;
		CATS F 4 A_ThrowFish;
		CATS E 3 A_FaceTarget;
		CATS F 4 A_ThrowFish;
		CATS E 3 A_FaceTarget;
		CATS F 4 A_ThrowFish;
		CATS E 4;
		goto See;
	Pain:
		CATS G 3;
		CATS G 3 A_Pain;
		goto See;
	Death:
		CATS H 4 A_Scream;
		CATS I 4 A_NoBlocking;
		CATS J 14;
		TNT1 A 1 A_MCDeath;
		stop;
	}
}

// A cube fish, thrown tumbling. Splats into orange bits.
class CatFish : Actor
{
	Default
	{
		Projectile;
		Radius 8;
		Height 10;
		Speed 13;
		FastSpeed 20;
		Scale 0.27;
		Damage 3;
		+RANDOMIZE
		DeathSound "fish/splat";
		Obituary "%o got slapped with a fish by a cube cat.";
	}
	States
	{
	Spawn:
		FSHB ABCD 3;
		loop;
	Death:
		FSHB A 0
		{
			// splat bits, except right in the player's face (they would fill the screen)
			let p = players[consoleplayer].mo;
			if (p && Distance3D(p) < 72) return ResolveState("Gone");
			MCFx.Chips(pos, 0xF08030, 6, 3);
			MCFx.Chips(pos, 0xF0F0F0, 3, 3);
			return ResolveState(null);
		}
		FSHB A 3 A_SetScale(0.33, 0.19);
		FSHB A 3 A_SetScale(0.38, 0.1);
	Gone:
		TNT1 A 1;
		stop;
	}
}
