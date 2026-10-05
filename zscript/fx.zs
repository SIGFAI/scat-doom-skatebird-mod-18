// Minecraft-style effects: the grey death poof, block chips in the colour of what was hit,
// experience orbs that fly into the player, and the blocky TNT explosion.
class MCFx play
{
	static Color BlockColor(String b)
	{
		b = b.MakeUpper();
		for (int i = 0; i < MCBlockColors.NAMES.Size(); i++)
			if (MCBlockColors.NAMES[i] == b) return MCBlockColors.COLORS[i];
		return 0x707070;
	}

	static Color FloorColor(Actor a)
	{
		return BlockColor(TexMan.GetName(a.floorsector.GetTexture(Sector.floor)));
	}

	static void Chips(Vector3 pos, Color c, int n, double speed = 4.)
	{
		for (int i = 0; i < n; i++)
		{
			let chip = Actor.Spawn("MCChip", pos);
			if (!chip) continue;
			chip.vel = (frandom(-speed, speed), frandom(-speed, speed), frandom(1., speed * 1.3));
			chip.SetShade(c);
			chip.scale *= frandom(0.7, 1.4);
		}
	}

	// The Minecraft death: a burst of grey smoke where the mob was.
	static void Poof(Actor m, int n = 12, double size = 1.)
	{
		for (int i = 0; i < n; i++)
		{
			Vector3 p = m.pos + (frandom(-m.radius, m.radius), frandom(-m.radius, m.radius), frandom(4., m.height * 0.8));
			let s = Actor.Spawn("MCPoof", p);
			if (!s) continue;
			s.vel = (frandom(-0.8, 0.8), frandom(-0.8, 0.8), frandom(0.4, 1.4));
			s.scale *= size * frandom(0.7, 1.1);
		}
		m.A_StartSound("mc/poof", CHAN_AUTO);
	}

	static void DropXP(Actor m, int n)
	{
		for (int i = 0; i < n; i++)
		{
			let o = XPOrb(Actor.Spawn("XPOrb", m.pos + (0, 0, m.height * 0.5)));
			if (o) o.vel = (frandom(-3, 3), frandom(-3, 3), frandom(3, 7));
		}
	}

	static void Boom(Actor at, double size = 1.)
	{
		let b = Actor.Spawn("MCBoom", at.pos + (0, 0, 8));
		if (b) b.scale *= size;
		for (int i = 0; i < 6 * size; i++)
		{
			let s = Actor.Spawn("MCBoomSmoke", at.pos + (frandom(-40, 40) * size, frandom(-40, 40) * size, frandom(4, 50) * size));
			if (s) s.vel = (frandom(-2, 2), frandom(-2, 2), frandom(0.5, 2.5));
		}
		Chips(at.pos + (0, 0, 6), FloorColor(at), int(14 * size), 7);
		Chips(at.pos + (0, 0, 6), 0xC83020, int(5 * size), 6); // bits of TNT wrapper
		at.A_StartSound("mc/explode", CHAN_AUTO, attenuation: 0.6);
	}
}

class MCChip : Actor
{
	Default
	{
		Radius 2;
		Height 2;
		Gravity 0.9;
		BounceType "Doom";
		BounceFactor 0.35;
		BounceCount 3;
		RenderStyle "Stencil";
		Scale 0.2;
		+NOBLOCKMAP
		+NOTELEPORT
		+DROPOFF
		+THRUACTORS
		+DONTSPLASH
		+MISSILE
		-ACTIVATEIMPACT
		-ACTIVATEPCROSS
	}
	States
	{
	Spawn:
		CHIP A 50;
	Fade:
		CHIP A 1 A_FadeOut(0.06);
		wait;
	Death:
		CHIP A 30;
		goto Fade;
	}
}

class MCPoof : Actor
{
	Default
	{
		RenderStyle "Translucent";
		Alpha 0.9;
		Scale 0.3;
		+NOINTERACTION
		+NOBLOCKMAP
	}
	States
	{
	Spawn:
		MPUF A 2 { A_SetScale(scale.x + 0.017); A_FadeOut(0.045); }
		loop;
	}
}

class MCBoom : Actor
{
	Default
	{
		RenderStyle "Add";
		Scale 0.73;
		+NOINTERACTION
		+NOBLOCKMAP
		+BRIGHT
	}
	States
	{
	Spawn:
		MBOM A 2 { A_SetScale(scale.x + 0.083); A_FadeOut(0.09); }
		loop;
	}
}

class MCBoomSmoke : MCPoof
{
	Default
	{
		Scale 0.4;
		Alpha 0.55;
	}
	States
	{
	Spawn:
		MBOM B 2 { A_SetScale(scale.x + 0.012); A_FadeOut(0.05); }
		loop;
	}
}

// Experience orb: pops out of a defeated cat, then homes in on the player and pays out XP (SkateScore.AddXP).
class XPOrb : Actor
{
	int value;

	Default
	{
		Radius 4;
		Height 6;
		Gravity 0.6;
		BounceType "Doom";
		BounceFactor 0.5;
		Scale 0.38;
		+NOBLOCKMAP
		+NOTELEPORT
		+DROPOFF
		+BRIGHT
		+DONTSPLASH
	}
	States
	{
	Spawn:
		XPRB AB 4;
		loop;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		value = random(2, 4);
	}

	override void Tick()
	{
		Super.Tick();
		if (bDestroyed || GetAge() < 20) return;
		Actor p = players[consoleplayer].mo;
		if (!p) return;
		Vector3 to = p.pos + (0, 0, p.height * 0.5) - pos;
		double d = to.Length();
		if (d < 44 || GetAge() > 35 * 6)
		{
			SkateScore.AddXP(value);
			p.A_StartSound("xp/orb", CHAN_AUTO, CHANF_OVERLAP, 0.7, pitch: frandom(0.85, 1.25));
			Destroy();
			return;
		}
		bNoGravity = true;
		bNoClip = true;
		vel = to / d * min(3 + (GetAge() - 20) * 0.5, 20);
	}
}
