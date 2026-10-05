// SkateBIRD side: you are a little blue bird with a skateboard. The Kickflip Deck throws boards that 360-flip,
// bank off walls (chipping the blocks) and bounce from cat to cat. Every bounce and every hit is a trick
// in the running combo (SkateScore); bank shots hit harder.
class KickflipDeck : Weapon replaces Pistol
{
	Default
	{
		Weapon.SelectionOrder 100;
		Weapon.SlotNumber 2;
		Weapon.Kickback 120;
		Weapon.BobStyle "InverseSmooth";
		Weapon.BobRangeX 0.7;
		Weapon.BobRangeY 0.5;
		Weapon.BobSpeed 1.6;
		Weapon.UpSound "board/pop";
		Inventory.PickupMessage "You picked up a Kickflip Deck!";
		Obituary "%o got kickflipped by %k.";
		Tag "Kickflip Deck";
		+WEAPON.AMMO_OPTIONAL
	}
	States
	{
	Spawn:
		DECK A -1;
		stop;
	Ready:
		DKHD A 1 A_WeaponReady;
		loop;
	Select:
		DKHD A 1 A_Raise(12);
		loop;
	Deselect:
		DKHD A 1 A_Lower(12);
		loop;
	Fire:
		DKHD B 3;
		DKHD C 2 A_ThrowDeck;
		DKHD D 4;
		DKHD A 1 Offset(0, 120);
		DKHD A 1 Offset(0, 96);
		DKHD A 1 Offset(0, 74);
		DKHD A 1 Offset(0, 56);
		DKHD A 1 Offset(0, 42);
		DKHD A 1 Offset(0, 34);
		DKHD A 1 Offset(0, 32) A_ReFire;
		goto Ready;
	}

	action void A_ThrowDeck()
	{
		A_StartSound("board/pop", CHAN_WEAPON);
		A_FireProjectile("ThrownDeck", frandom(-1, 1), false, 0, -4);
	}
}

class ThrownDeck : Actor
{
	int bounces, hits;
	Vector3 lastVel, lastPos;
	bool hitThisTic;
	Array<Actor> struck;

	static const String FLIPS[] = { "KICKFLIP", "HEELFLIP", "POP SHOVE-IT", "VARIAL FLIP" };
	static const String BANKS[] = { "WALLRIDE", "BANK SHOT", "WALLIE" };
	static const String BIG[] = { "360 FLIP", "HARDFLIP", "IMPOSSIBLE" };

	Default
	{
		Projectile;
		-NOGRAVITY
		Gravity 0.16;
		Speed 24;
		Radius 7;
		Height 8;
		Damage 0;
		Scale 0.36;
		BounceType "Hexen";
		BounceCount 10;
		BounceFactor 0.6;
		WallBounceFactor 0.9;
		BounceSound "board/bounce";
		+CANBOUNCEWATER
		+DONTBOUNCEONSKY
		Obituary "%o got kickflipped by %k.";
	}
	States
	{
	Spawn:
		DECK ABCDEFGH 2;
		loop;
	Death:
		DECK A 0 { MCFx.Chips(pos, 0xB03030, 5, 3); A_StartSound("board/bounce", CHAN_BODY); }
		DECK AC 3;
		DECK A 1 A_FadeOut(0.08);
		wait;
	}

	override void Tick()
	{
		lastVel = vel;
		lastPos = pos;
		hitThisTic = false;
		Super.Tick();
		if (bDestroyed || InStateSequence(CurState, FindState("Death"))) return;
		// a sharp turn in the air without hitting a cat: it banked off a wall
		double before = lastVel.xy.Length(), now = vel.xy.Length();
		if (!hitThisTic && before > 4 && now > 1 && (lastVel.xy dot vel.xy) < before * now * 0.6)
		{
			bounces++;
			WallChips();
			if (bounces <= 2) SkateScore.Trick(BANKS[random(0, BANKS.Size() - 1)], 50);
		}
		if (GetAge() > 35 * 3 || (vel.Length() < 3 && GetAge() > 10)) SetStateLabel("Death");
	}

	// Chips of the block it banked off, in that block's colour.
	void WallChips()
	{
		FLineTraceData d;
		double a = atan2(lastVel.y, lastVel.x);
		Color c = 0x808080;
		if (LineTrace(a, 64, 0, TRF_THRUACTORS, 4, data: d) && d.HitType == TRACE_HitWall)
			c = MCFx.BlockColor(TexMan.GetName(d.HitTexture));
		MCFx.Chips(pos, c, 7, 3.5);
		A_StartSound("mc/dig", CHAN_AUTO, CHANF_OVERLAP, 0.8);
	}

	override int SpecialMissileHit(Actor victim)
	{
		if (!victim.bShootable || victim == target || victim.health <= 0 || victim.player) return 1;
		if (struck.Find(victim) != struck.Size()) return 1;
		struck.Push(victim);
		hits++;
		hitThisTic = true;
		int b = min(bounces, 3);
		int dmg = 22 + 12 * b;
		String trick = b == 0 ? FLIPS[random(0, FLIPS.Size() - 1)] : (b == 1 ? "BANK " .. FLIPS[random(0, FLIPS.Size() - 1)] : (b == 2 ? BIG[random(0, BIG.Size() - 1)] : "THE 900"));
		bool wasAlive = victim.health > 0;
		victim.DamageMobj(self, target, dmg, 'Skate');
		// Minecraft knockback: the cat gets bumped back and hops
		if (victim.bIsMonster && !victim.bBoss && victim.health > 0)
		{
			Vector2 push = vel.xy.Length() > 0.1 ? vel.xy.Unit() : (0, 0);
			victim.vel += (push * 7, 4);
		}
		SkateScore.Trick(trick, 100 * (b + 1), true);
		if (wasAlive && victim.health <= 0 && victim.bIsMonster) SkateScore.Trick("SHREDDED", 250, true);
		A_StartSound("board/hit", CHAN_BODY, CHANF_OVERLAP);
		MCFx.Chips(victim.pos + (0, 0, victim.height * 0.6), 0xD02020, 4, 3); // a red hit spark, Minecraft style
		// knock the board off the cat like off a ledge: reflect it and pop it up
		Vector2 n = pos.xy - victim.pos.xy;
		n = n.Length() > 0.1 ? n.Unit() : -vel.xy.Unit();
		double vn = vel.xy dot n;
		if (vn < 0) vel.xy -= 2 * vn * n;
		vel.xy *= 0.85;
		vel.z = max(vel.z, 0) + 3;
		angle = atan2(vel.y, vel.x);
		if (hits >= 3) SetStateLabel("Death");
		return 1;
	}
}

// The player: a small bird (eyes lower than a marine's), bird squawks, and an ollie when jumping.
class SkateBird : DoomPlayer
{
	Default
	{
		Player.ViewHeight 32;
		Player.AttackZOffset 0;
		Player.DisplayName "SkateBird";
		Player.SoundClass "skatebird";
		Player.StartItem "KickflipDeck";
		Player.StartItem "Fist";
		Player.StartItem "Clip", 50;
	}

	override void CheckJump()
	{
		double vz = vel.z;
		Super.CheckJump();
		if (vel.z > vz + 1) SkateScore.Trick("OLLIE", 50);
	}
}

// Big Friend's other birds: cube birds on fingerboards that skate around the cubed world, pop ollies and
// cheer (ollie + squawk) when you land a combo. They stay close to the action and can't be hit by your boards.
class SkateBuddy : Actor
{
	int nextCheck;

	Default
	{
		Radius 14;
		Height 36;
		Speed 6;
		Scale 0.28;
		Gravity 0.8;
		+DROPOFF
		+NOTELEPORT
		+FLOORCLIP
		+NOTARGET
		+THRUACTORS
		Tag "Skate Bird";
	}
	States
	{
	Spawn:
		BRDP AAAABBBB 1 A_SkateAbout;
		loop;
	Ollie:
		BRDP C 9;
		BRDP D 9;
		goto Spawn;
	}

	void A_SkateAbout()
	{
		let pl = players[consoleplayer].mo;
		// give the player room: never skate into the camera
		if (pl && Distance2D(pl) < 200)
		{
			Vector2 away = (pos.xy - pl.pos.xy).Unit();
			angle = atan2(away.y, away.x);
			if (!TryMove(pos.xy + away * speed, true)) A_Wander();
		}
		else A_Wander();
		if (pos.z <= floorz && !random(0, 90)) Ollie(false);
		if (level.maptime < nextCheck) return;
		nextCheck = level.maptime + 35 * 3;
		let p = players[consoleplayer].mo;
		// wandered off: skate back into the shot
		if (p && Distance2D(p) > 700)
		{
			Vector2 xy = p.Vec2Angle(frandom(180, 320), p.angle + frandom(-50, 50));
			double z = level.PointInSector(xy).floorplane.ZatPoint(xy);
			Vector3 old = pos;
			SetOrigin((xy, z), false);
			if (abs(z - p.pos.z) > 40 || !TestMobjLocation() || !CheckSight(p)) SetOrigin(old, false);
			else MCFx.Poof(self, 4, 0.6);
		}
	}

	void Ollie(bool cheer)
	{
		if (pos.z > floorz + 1) return;
		vel.z = cheer ? 7 : 5;
		A_StartSound("board/pop", CHAN_BODY, CHANF_OVERLAP, 0.6);
		if (cheer) A_StartSound("bird/hurt", CHAN_VOICE, CHANF_OVERLAP, 0.8, pitch: frandom(1.1, 1.4));
		SetStateLabel("Ollie");
	}

	static void CheerAll()
	{
		let it = ThinkerIterator.Create("SkateBuddy");
		SkateBuddy b;
		while (b = SkateBuddy(it.Next())) b.Ollie(true);
	}
}

class ParrotBuddy : SkateBuddy {}

class ChickBuddy : SkateBuddy
{
	States
	{
	Spawn:
		BRDC AAAABBBB 1 A_SkateAbout;
		loop;
	Ollie:
		BRDC C 9;
		BRDC D 9;
		goto Spawn;
	}
}
