// Minecraft-style HUD: hotbar with the weapons, hearts, the green XP bar with its level number, score and quest
// at the top left, the skate combo above the hotbar, story banners and the boss bar.
class MCStatusBar : BaseStatusBar
{
	HUDFont fnt;

	override void Init()
	{
		Super.Init();
		SetSize(0, 480, 300);
		fnt = HUDFont.Create(Font.GetFont("mcfont"));
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);
		if (!CPlayer || !CPlayer.mo) return;
		BeginHUD(1., true, 480, 300);
		let s = SkateScore.Get();
		DrawHotbar();
		DrawHearts();
		if (s)
		{
			DrawXP(s);
			DrawTopLeft(s);
			DrawCombo(s);
			DrawBanner(s);
			DrawBossBar(s);
		}
	}

	void Text(String t, Vector2 pos, int flags, int col = Font.CR_WHITE, double scale = 1., double alpha = 1.)
	{
		DrawString(fnt, t, pos, flags, col, alpha, -1, 4, (scale, scale));
	}

	void DrawHotbar()
	{
		int f = DI_SCREEN_CENTER_BOTTOM;
		Fill(0xB0000000, -92, -24, 184, 22, f);
		let weap = CPlayer.ReadyWeapon;
		int slot = 0;
		for (int pass = 0; pass < 2; pass++)
		{
			for (let it = CPlayer.mo.Inv; it; it = it.Inv)
			{
				let w = Weapon(it);
				if (!w || (pass == 0) != (w is "KickflipDeck") || slot >= 9) continue;
				double x = -90 + slot * 20;
				if (w == weap)
				{
					Fill(0xFFE0E0E0, x - 1, -25, 22, 24, f);
					Fill(0xFF303030, x + 1, -23, 18, 20, f);
				}
				if (w is "KickflipDeck") DrawImage("DECKB0", (x + 10, -13), f | DI_ITEM_CENTER, 1., (18, 18));
				else DrawInventoryIcon(w, (x + 10, -13), f | DI_ITEM_CENTER, 1., (16, 16));
				slot++;
			}
		}
		for (int i = 0; i < 9; i++) Fill(0x60FFFFFF, -90 + i * 20 + 19, -22, 1, 18, f);
	}

	void DrawHearts()
	{
		int f = DI_SCREEN_CENTER_BOTTOM | DI_ITEM_LEFT_TOP;
		int hp = CPlayer.health;
		for (int i = 0; i < 10; i++)
		{
			int v = hp - i * 10;
			String img = v >= 10 ? "MCHRTF" : (v >= 5 ? "MCHRTH" : "MCHRTE");
			DrawImage(img, (-92 + i * 9, -44), f, 1., (-1, -1), (0.75, 0.75));
		}
	}

	void DrawXP(SkateScore s)
	{
		int f = DI_SCREEN_CENTER_BOTTOM;
		Fill(0xFF101010, -92, -31, 184, 5, f);
		Fill(0xFF2A4A10, -91, -30, 182, 3, f);
		double frac = s.xpNeed > 0 ? double(s.xp) / s.xpNeed : 0;
		Fill(0xFF80FF20, -91, -30, 182 * frac, 3, f);
		if (s.xpLevel > 0) Text(String.Format("%d", s.xpLevel), (0, -42), f | DI_TEXT_ALIGN_CENTER, Font.CR_GREEN);
		if (level.maptime < s.levelUpUntil) Text("LEVEL UP!", (0, -56), f | DI_TEXT_ALIGN_CENTER, Font.CR_GREEN, 1.3);
	}

	void DrawTopLeft(SkateScore s)
	{
		int f = DI_SCREEN_LEFT_TOP;
		Text("SCORE " .. SkateScore.Commas(s.score), (8, 8), f, Font.CR_GOLD, 1.4);
		String q;
		int col = Font.CR_WHITE;
		if (s.bossDown) { q = "BIG FRIEND IS SAVED!"; col = Font.CR_GREEN; }
		else if (s.bossOut) { q = "DEFEAT THE SUPERINTELLIGENT CAT!"; col = Font.CR_ORANGE; }
		else q = String.Format("CATS SHREDDED %d/%d", min(s.kills, s.quota), s.quota);
		Text(q, (8, 24), f, col);
	}

	void DrawCombo(SkateScore s)
	{
		int f = DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_CENTER;
		if (s.chain.Size())
		{
			String line = "";
			for (int i = 0; i < s.chain.Size(); i++) line = line .. (i ? " + " : "") .. s.chain[i];
			Text(line, (0, -86), f, Font.CR_YELLOW, 1.2);
			Text(String.Format("%s  x %d", SkateScore.Commas(s.chainPoints), s.Mult()), (0, -72), f, Font.CR_WHITE, 1.4);
		}
		else if (level.maptime < s.landedUntil && s.landed.Length())
		{
			double a = clamp((s.landedUntil - level.maptime) / 20., 0., 1.);
			Text(s.landed, (0, -80), f, s.landedColor, 1.8, a);
		}
	}

	void DrawBanner(SkateScore s)
	{
		if (level.maptime >= s.bannerUntil) return;
		double a = clamp((s.bannerUntil - level.maptime) / 25., 0., 1.);
		int f = DI_SCREEN_CENTER_TOP | DI_TEXT_ALIGN_CENTER;
		Text(s.banner1, (0, 46), f, s.bannerColor, 1.6, a);
		Text(s.banner2, (0, 66), f, Font.CR_WHITE, 1.0, a);
	}

	void DrawBossBar(SkateScore s)
	{
		if (!s.bossOut || s.bossDown || !s.boss || s.boss.health <= 0) return;
		int f = DI_SCREEN_CENTER_TOP;
		Text("The SuperIntelligent Cat", (0, 8), f | DI_TEXT_ALIGN_CENTER, Font.CR_WHITE);
		double frac = double(s.boss.health) / s.boss.SpawnHealth();
		Fill(0xFF200820, -92, 20, 184, 6, f);
		Fill(0xFFE040E0, -91, 21, 182 * frac, 4, f);
		for (int i = 1; i < 10; i++) Fill(0x80000000, -91 + i * 18.2, 21, 1, 4, f);
	}
}
