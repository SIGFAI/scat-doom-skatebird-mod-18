// The SuperIntelligent Cat: Big Friend's cat after it got too smart. A big violet cube cat wearing its own giant
// voxel brain. It fires its laser pointer, swats lit TNT at you (knocking things off tables, as cats do)
// and calls its minions. 650 health (between a Hell Knight and a Baron): bank shots and explosions (TNT, creepers) hurt it most.
class BrainCat : CubeCat
{
	int nextMinions;

	static const String TAUNTS[] = {
		"\"Your board is a mere vector. I am the calculus.\"",
		"\"I knocked physics off the table. Then I knocked YOU off.\"",
		"\"Meow. That means checkmate.\"",
		"\"I solved Minecraft. It was easy. It's just cubes.\"",
		"\"Big Friend never let me on the counter. Now I OWN the counter.\""
	};

	Default
	{
		Health 650;
		Radius 34;
		Height 110;
		Mass 1500;
		Speed 7;
		PainChance 30;
		MinMissileChance 100;
		Scale 0.56;
		+BOSS
		+DONTMORPH
		+MISSILEMORE
		SeeSound "boss/sight";
		PainSound "cat/pain";
		DeathSound "boss/sight";
		ActiveSound "boss/laugh";
		Tag "The SuperIntelligent Cat";
		Obituary "%o was outsmarted by the SuperIntelligent Cat.";
		CubeCat.XPDrop 30;
	}
	States
	{
	Spawn:
		BOSC AB 10 A_Look;
		loop;
	See:
		BOSC AABBCCDD 4 A_Chase;
		loop;
	Missile:
		BOSC A 0 A_PickAttack;
	Laser:
		BOSC E 10 A_FaceTarget;
		BOSC F 4 A_BossLaser;
		BOSC E 4 A_FaceTarget;
		BOSC F 4 A_BossLaser;
		BOSC E 4 A_FaceTarget;
		BOSC F 4 A_BossLaser;
		BOSC E 10;
		goto See;
	Swat:
		BOSC K 10 A_FaceTarget;
		BOSC L 6 A_SwatTNT;
		BOSC K 12;
		goto See;
	Minions:
		BOSC K 8 A_StartSound("boss/laugh", CHAN_VOICE, attenuation: ATTN_NONE);
		BOSC L 8;
		BOSC K 8 A_Minions;
		BOSC L 12;
		goto See;
	Pain:
		BOSC G 4;
		BOSC G 4 A_BossPain;
		goto See;
	Death:
		BOSC H 6 A_Scream;
		BOSC I 6 A_BossBurst;
		BOSC J 6 A_NoBlocking;
		BOSC J 24 A_BossBurst;
		TNT1 A 1 A_BossEnd;
		stop;
	}

	// Explosions hurt it double: lure it next to TNT and creepers.
	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		if (inflictor is "MCTnt" || inflictor is "CreeperCat" || inflictor is "SwattedTNT") damage *= 2;
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		nextMinions = level.maptime + 35 * 9;
	}

	void A_PickAttack()
	{
		if (level.maptime >= nextMinions && health < SpawnHealth() * 0.85)
		{
			nextMinions = level.maptime + 35 * 14;
			SetStateLabel("Minions");
			return;
		}
		if (random(0, 2)) SetStateLabel("Laser");
		else SetStateLabel("Swat");
	}

	void A_BossLaser()
	{
		A_StartSound("boss/laser", CHAN_WEAPON, CHANF_OVERLAP);
		A_SpawnProjectile("LaserDot", 48, 0, frandom(-3, 3));
	}

	void A_SwatTNT()
	{
		A_StartSound("boss/swat", CHAN_WEAPON);
		let t = A_SpawnProjectile("SwattedTNT", 50);
		if (t && target)
		{
			// lob it: flight time from the distance, then the upward speed that lands it there
			double d = Distance2D(target), tics = max(d / t.speed, 8);
			t.vel.z = (target.pos.z - t.pos.z) / tics + 0.5 * t.GetGravity() * tics;
		}
	}

	void A_Minions()
	{
		for (int i = -1; i <= 1; i += 2)
		{
			Vector2 xy = Vec2Angle(radius + 50, angle + 90 * i);
			let c = Actor.Spawn("CubeCat", (xy, pos.z), ALLOW_REPLACE);
			if (!c) continue;
			if (!c.TestMobjLocation()) { c.Destroy(); continue; }
			MCFx.Poof(c, 5, 0.7);
			c.target = target;
			c.angle = angle;
			c.SetState(c.SeeState);
		}
		let s = SkateScore.Get();
		if (s) s.Banner("", "\"Minions! FETCH!\"", 35 * 2, Font.CR_PURPLE);
	}

	void A_BossPain()
	{
		A_Pain();
		let s = SkateScore.Get();
		if (s && !random(0, 2) && level.maptime > s.bannerUntil)
			s.Banner("", TAUNTS[random(0, TAUNTS.Size() - 1)], 35 * 3, Font.CR_PURPLE);
	}

	void A_BossBurst()
	{
		MCFx.Poof(self, 16);
		MCFx.Chips(pos + (0, 0, 60), 0xE060A0, 14, 6); // bits of brain
	}

	void A_BossEnd()
	{
		MCFx.Poof(self, 30);
		MCFx.DropXP(self, xpDrop);
		MCFx.Boom(self, 1.2);
	}
}


// Laser pointer dot: fast, bright red, leaves a red trail.
class LaserDot : Actor
{
	Default
	{
		Projectile;
		Radius 6;
		Height 6;
		Speed 42;
		FastSpeed 50;
		Damage 2;
		Scale 0.2;
		RenderStyle "Stencil";
		StencilColor "FF1010";
		+BRIGHT
		+RANDOMIZE
		DeathSound "board/hit";
		Obituary "%o chased the SuperIntelligent Cat's laser pointer.";
	}
	States
	{
	Spawn:
		CHIP A 1 A_SpawnParticle(0xFF3030, SPF_FULLBRIGHT, 10, 2.5, 0, 0, 0, 0, frandom(-0.3, 0.3), frandom(-0.3, 0.3), frandom(-0.3, 0.3));
		loop;
	Death:
		CHIP A 0
		{
			let p = players[consoleplayer].mo;
			if (p && Distance3D(p) < 80) return ResolveState("Gone");
			MCFx.Chips(pos, 0xFF2020, 5, 2.5);
			return ResolveState(null);
		}
		CHIP A 4 A_SetScale(0.5);
		CHIP A 4 A_SetScale(0.3);
	Gone:
		TNT1 A 1;
		stop;
	}
}

// A lit TNT block knocked off the table at you: it tumbles in an arc and blows up where it lands.
class SwattedTNT : Actor
{
	Default
	{
		Projectile;
		-NOGRAVITY
		Gravity 0.6;
		Radius 12;
		Height 20;
		Speed 14;
		Damage 4;
		Scale 0.3333;
		Obituary "%o got a TNT block knocked onto them by the SuperIntelligent Cat.";
	}
	States
	{
	Spawn:
		TNTB A 3 A_StartSound("mc/fuse", CHAN_BODY, CHANF_LOOPING, 0.6);
		TNTB B 3;
		TNTB A 3;
		TNTB B 3;
		loop;
	Death:
		TNT1 A 0
		{
			A_StopSound(CHAN_BODY);
			MCFx.Boom(self, 1.2);
			A_Explode(60, 140);
		}
		TNT1 A 20;
		stop;
	}
}
