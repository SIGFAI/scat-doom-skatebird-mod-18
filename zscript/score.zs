// Score, tricks, experience and the short story: Big Friend's cat got superintelligent and cubed the world.
// Shred the quota of cats (sic_quota) and the SuperIntelligent Cat itself shows up; beat it to win.
class SkateScore : EventHandler
{
	int score, xp, xpLevel, xpNeed, kills, quota;
	Array<String> chain;
	int chainPoints, chainHits, chainUntil;
	String landed;
	int landedUntil, landedColor;
	String banner1, banner2;
	int bannerUntil, bannerColor;
	int levelUpUntil;
	Actor boss;
	bool bossOut, bossDown;
	int bossRetry;

	clearscope static SkateScore Get() { return SkateScore(EventHandler.Find("SkateScore")); }

	override void WorldLoaded(WorldEvent e)
	{
		xpNeed = 7;
		quota = max(1, sic_quota);
		S_ChangeMusic("MCSKATE");
	}

	override void PlayerEntered(PlayerEvent e)
	{
		Banner("BIG FRIEND'S CAT GOT SUPERINTELLIGENT", "and cubed the whole world. Grab your board, little bird!", 35 * 6, Font.CR_GOLD);
		buddiesAt = level.maptime + 10;
	}

	int buddiesAt;

	// Big Friend's other birds skate along with you.
	void SpawnBuddies()
	{
		static const Name BUDDIES[] = { 'ParrotBuddy', 'ChickBuddy', 'ParrotBuddy' };
		for (int i = 0; i < BUDDIES.Size(); i++) SpawnInView((Class<Actor>)(BUDDIES[i]), 220, 380, 60);
	}

	void Banner(String a, String b, int tics, int col = Font.CR_WHITE)
	{
		banner1 = a;
		banner2 = b;
		bannerUntil = level.maptime + tics;
		bannerColor = col;
	}

	static void AddXP(int n)
	{
		let s = Get();
		if (!s) return;
		s.xp += n;
		s.score += n * 10;
		while (s.xp >= s.xpNeed)
		{
			s.xp -= s.xpNeed;
			s.xpLevel++;
			s.xpNeed = 7 + s.xpLevel * 2;
			s.levelUpUntil = level.maptime + 60;
			let p = players[consoleplayer].mo;
			if (p) p.A_StartSound("xp/levelup", CHAN_AUTO, CHANF_OVERLAP);
		}
	}

	// A trick joins the running combo; hits multiply it. The combo lands 2.3 s after the last trick.
	static void Trick(String name, int points, bool hit = false)
	{
		let s = Get();
		if (!s) return;
		if (s.chain.Size() >= 5) s.chain.Delete(0);
		s.chain.Push(name);
		s.chainPoints += points;
		// hits keep the combo alive; wall bounces only add to it
		if (hit) { s.chainHits++; s.chainUntil = level.maptime + 56; }
		else if (s.chain.Size() == 1) s.chainUntil = level.maptime + 56;
	}

	clearscope int Mult() { return clamp(chainHits, 1, 10); }

	void Land()
	{
		if (chainHits)
		{
			int total = chainPoints * Mult();
			score += total;
			landed = String.Format("LANDED!  +%s", Commas(total));
			landedColor = Font.CR_GREEN;
			if (chainHits >= 2) SkateBuddy.CheerAll();
			if (chainHits >= 3)
			{
				let p = players[consoleplayer].mo;
				if (p) p.A_StartSound("skate/cheer", CHAN_AUTO, CHANF_OVERLAP, 0.8);
			}
		}
		else if (chain.Size() >= 2)
		{
			landed = "BAILED!";
			landedColor = Font.CR_RED;
		}
		else landed = "";
		landedUntil = level.maptime + 60;
		chain.Clear();
		chainPoints = 0;
		chainHits = 0;
	}

	clearscope static String Commas(int n)
	{
		String s = String.Format("%d", n), o = "";
		int len = s.Length();
		for (int i = 0; i < len; i++)
		{
			if (i && (len - i) % 3 == 0) o = o .. ",";
			o.AppendCharacter(s.ByteAt(i));
		}
		return o;
	}

	override void WorldTick()
	{
		if (chain.Size() && level.maptime >= chainUntil) Land();
		if (buddiesAt && level.maptime >= buddiesAt) { buddiesAt = 0; SpawnBuddies(); }
		if (sic_demo) DemoTick();
		if (bossRetry && level.maptime >= bossRetry && !bossOut) SpawnBoss();
	}

	// Showcase run (sic_demo 1, set by demo.cfg): waves in front of the player, every kind of cat,
	// a TNT ambush, then the SuperIntelligent Cat. Seconds from map start, kind (sic_spawn kinds, 7 = boss), count.
	static const int DEMO[] = {
		1, 0, 2,
		5, 4, 1,
		9, 6, 3,
		13, 1, 1,
		14, 2, 1,
		17, 7, 1,
		23, 8, 1,
		29, 8, 1,
		35, 8, 1,
		41, 8, 1,
		47, 0, 2,
		54, 4, 1,
		60, 6, 3,
		67, 1, 1,
		68, 2, 1
	};

	// A TNT block in the line of fire, just in front of the boss: the next boards set it off next to the cat.
	void TntBy(Actor b)
	{
		let p = players[consoleplayer].mo;
		if (!p) return;
		for (int i = 0; i < 12; i++)
		{
			Vector2 xy = b.Vec2Angle(b.radius + 30 + i * 6, b.AngleTo(p) + frandom(-15, 15));
			double z = level.PointInSector(xy).floorplane.ZatPoint(xy);
			let t = Actor.Spawn("MCTnt", (xy, z));
			if (t && t.TestMobjLocation()) { MCFx.Poof(t, 4, 0.7); return; }
			if (t) t.Destroy();
		}
	}

	void DemoTick()
	{
		int t = level.maptime;
		if (t % 35) return;
		for (int i = 0; i < DEMO.Size(); i += 3)
		{
			if (DEMO[i] * 35 != t) continue;
			int k = DEMO[i + 1];
			if (k == 7) { if (!bossOut) SpawnBoss(); }
			else if (k == 8) { if (bossOut && !bossDown && boss) TntBy(boss); else if (!bossDown) SpawnKind(0, DEMO[i + 2]); } // during the boss: TNT to use on it
			else SpawnKind(k, DEMO[i + 2]);
		}
	}

	override void WorldThingDied(WorldEvent e)
	{
		let m = e.Thing;
		if (!m || !m.bIsMonster) return;
		if (m is "BrainCat")
		{
			bossDown = true;
			Console.PrintfEx(PRINT_NONOTIFY, "SIC_BOSS_DOWN %d s", level.maptime / 35);
			score += 10000;
			Banner("YOU OUT-SKATED THE SUPERINTELLIGENT CAT!", "The world is still blocks, but Big Friend is proud of you.", 35 * 8, Font.CR_GREEN);
			let p = players[consoleplayer].mo;
			if (p) p.A_StartSound("skate/cheer", CHAN_AUTO, CHANF_OVERLAP);
			return;
		}
		kills++;
		score += 100;
		if (kills >= quota && !bossOut && !bossDown) SpawnBoss();
	}

	// Something appears in front of the player, on the same floor, in view, minD..maxD away.
	static Actor SpawnInView(Class<Actor> cls, double minD, double maxD, double cone = 45, bool fog = true)
	{
		let p = players[consoleplayer].mo;
		if (!p || !cls) return null;
		for (int i = 0; i < 240; i++)
		{
			// tight rooms: after a while, look closer and wider (still in sight, on this floor)
			double k = i < 80 ? 1. : (i < 160 ? 0.6 : 0.35);
			double c = i < 80 ? cone : (i < 160 ? cone * 2 : 150);
			Vector2 xy = p.Vec2Angle(frandom(max(minD * k, 96), maxD * k), p.angle + frandom(-c, c));
			double z = level.PointInSector(xy).floorplane.ZatPoint(xy);
			if (abs(z - p.pos.z) > 48) continue;
			let b = Actor.Spawn(cls, (xy, z), ALLOW_REPLACE);
			if (!b) continue;
			if (!b.TestMobjLocation() || !b.CheckSight(p)) { b.Destroy(); continue; }
			b.angle = b.AngleTo(p);
			if (fog) MCFx.Poof(b, 5, 0.7);
			if (b.bIsMonster) { b.target = p; if (b.SeeState) b.SetState(b.SeeState); }
			Console.PrintfEx(PRINT_NONOTIFY, "SIC_SPAWN %s at %d", b.GetClassName(), int(p.Distance2D(b)));
			return b;
		}
		Console.PrintfEx(PRINT_NONOTIFY, "SIC_SPAWN %s failed", cls.GetClassName());
		return null;
	}

	// The boss arrives in front of the player, on the same floor, in view.
	void SpawnBoss()
	{
		Class<Actor> cls = (Class<Actor>)("BrainCat");
		let b = SpawnInView(cls, 300, 520, 35);
		if (!b) { bossRetry = level.maptime + 35; return; }
		bossRetry = 0;
		b.A_StartSound("boss/sight", CHAN_VOICE, attenuation: ATTN_NONE);
		boss = b;
		bossOut = true;
		Banner("THE SUPERINTELLIGENT CAT HAS ENTERED THE CHAT", "\"I have calculated 9 lives of probability. You have zero.\"", 35 * 5, Font.CR_PURPLE);
	}

	// Console / demo: "netevent sic_spawn <kind> [count]"  0 ginger, 1 black, 2 siamese, 3 kitten, 4 creeper,
	// 5 TNT block, 6 a TNT block with cats around it;  "netevent sic_boss" calls the SuperIntelligent Cat.
	static const Name KINDS[] = { 'CubeCat', 'BlackCat', 'SiameseCat', 'KittenCat', 'CreeperCat', 'MCTnt' };

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "sic_boss") { if (!bossOut) SpawnBoss(); return; }
		if (e.Name ~== "sic_spawn") SpawnKind(e.Args[0], max(1, e.Args[1]));
	}

	void SpawnKind(int kind, int n)
	{
		if (kind == 6)
		{
			let t = SpawnInView((Class<Actor>)("MCTnt"), 300, 420, 20, false);
			if (!t) return;
			for (int i = 0; i < n; i++)
			{
				Vector2 xy = t.Vec2Angle(frandom(50, 90), i * 360. / n + frandom(-20, 20));
				let c = Actor.Spawn("CubeCat", (xy, t.pos.z), ALLOW_REPLACE);
				if (c && !c.TestMobjLocation()) { c.Destroy(); continue; }
				if (c) { MCFx.Poof(c, 5, 0.7); c.target = players[consoleplayer].mo; c.angle = c.AngleTo(c.target); }
			}
			return;
		}
		if (kind < 0 || kind >= KINDS.Size()) return;
		for (int i = 0; i < n; i++) SpawnInView((Class<Actor>)(KINDS[kind]), 280, 560, 40, kind != 5);
	}
}
