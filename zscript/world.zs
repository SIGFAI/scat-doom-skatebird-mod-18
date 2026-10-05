// The cubed world: when a map loads, every wall, floor and ceiling becomes a Minecraft-like block and the sky
// becomes a blue blocky-cloud sky. Works on any map: known Doom 2 / Freedoom textures follow the table
// (blockmap.zs, picked from each texture's colours), unknown ones get a stable block from their name.
class MCWorld : EventHandler
{
	Dictionary walls, flats;
	Array<String> floorBlock;

	static const String FALLBACK[] = { "MCSTONE", "MCCOBBLE", "MCSTBRK", "MCPLANK", "MCBRICK", "MCSBLK" };

	static TextureID Tex(String b) { return TexMan.CheckForTexture(b, TexMan.Type_Any); }

	String Block(Dictionary d, String nm)
	{
		nm = nm.MakeUpper();
		String b = d.At(nm);
		if (b.Length()) return b;
		int h = 0;
		for (int i = 0; i < int(nm.Length()); i++) h = (h * 31 + nm.ByteAt(i)) & 0xFFFFFF;
		return FALLBACK[h % int(FALLBACK.Size())];
	}

	// Doom's other monsters join the cube cats: bosses become the SuperIntelligent Cat, spectres Creeper Cats.
	override void CheckReplacement(ReplaceEvent e)
	{
		Name n = e.Replacee.GetClassName();
		if (n == 'BaronOfHell' || n == 'Cyberdemon' || n == 'SpiderMastermind') e.Replacement = "BrainCat";
		else if (n == 'Spectre') e.Replacement = "CreeperCat";
	}

	override void WorldLoaded(WorldEvent e)
	{
		walls = Dictionary.Create();
		flats = Dictionary.Create();
		for (int i = 0; i < MCBlockTable.WALL_SRC.Size(); i++) walls.Insert(MCBlockTable.WALL_SRC[i], MCBlockTable.WALL_DST[i]);
		for (int i = 0; i < MCBlockTable.FLAT_SRC.Size(); i++) flats.Insert(MCBlockTable.FLAT_SRC[i], MCBlockTable.FLAT_DST[i]);

		TextureID sky = Tex("MCSKY");
		level.ChangeSky(sky, sky);

		floorBlock.Resize(level.Sectors.Size());
		for (int i = 0; i < level.Sectors.Size(); i++)
		{
			Sector s = level.Sectors[i];
			bool outdoor = s.GetTexture(Sector.ceiling) == skyflatnum;
			TextureID ft = s.GetTexture(Sector.floor);
			if (ft != skyflatnum)
			{
				String b = Block(flats, TexMan.GetName(ft));
				// open sky above: a grass field, unless it's water or lava
				if (outdoor && b != "MCWATER" && b != "MCLAVA") b = "MCGRASS";
				floorBlock[i] = b;
				s.SetTexture(Sector.floor, Tex(b));
			}
			TextureID ct = s.GetTexture(Sector.ceiling);
			if (ct != skyflatnum) s.SetTexture(Sector.ceiling, Tex(Block(flats, TexMan.GetName(ct))));
			// Minecraft daylight: dark rooms get brighter, light still varies from room to room
			s.SetLightLevel(clamp(110 + s.lightlevel * 6 / 10, 0, 255));
		}

		for (int i = 0; i < level.Lines.Size(); i++)
		{
			Line l = level.Lines[i];
			for (int sd = 0; sd < 2; sd++)
			{
				Side s = l.sidedef[sd];
				if (!s) continue;
				for (int part = Side.top; part <= Side.bottom; part++)
				{
					TextureID t = s.GetTexture(part);
					if (!t.IsValid() || t.IsNull() || t == skyflatnum) continue;
					String nm = TexMan.GetName(t);
					if (nm.Left(3) ~== "SKY") continue;
					if (part == Side.mid && l.sidedef[1]) continue; // two-sided middles: bars and grates stay see-through
					String b = Block(walls, nm);
					if (part == Side.bottom && l.sidedef[1 - sd])
					{
						// a step up onto grass: grass-topped dirt, like the side of a grass block
						Sector up = l.sidedef[1 - sd].sector;
						if (floorBlock[up.Index()] == "MCGRASS")
						{
							double rise = up.floorplane.ZatPoint(l.v1.p) - s.sector.floorplane.ZatPoint(l.v1.p);
							b = rise <= 33 ? "MCGRSIDE" : "MCDIRT";
						}
					}
					s.SetTexture(part, Tex(b));
					Align(l, sd, part);
				}
			}
		}
	}

	// Blocks on one world grid (32 units): the seams meet at corners and line up from wall to wall,
	// rows sit at the same heights everywhere, like stacked Minecraft blocks.
	void Align(Line l, int sd, int part)
	{
		Side s = l.sidedef[sd];
		Vector2 a = sd ? l.v2.p : l.v1.p, b = sd ? l.v1.p : l.v2.p;
		Vector2 d = b - a;
		double u = abs(d.x) >= abs(d.y) ? (d.x >= 0 ? a.x : -a.x) : (d.y >= 0 ? a.y : -a.y);
		s.SetTextureXOffset(part, u % 32);
		Sector front = s.sector, back = l.sidedef[1 - sd] ? l.sidedef[1 - sd].sector : null;
		double anchor;
		bool lowerUnpeg = l.flags & Line.ML_DONTPEGBOTTOM, upperUnpeg = l.flags & Line.ML_DONTPEGTOP;
		if (part == Side.mid) anchor = lowerUnpeg ? front.floorplane.ZatPoint(a) + 32 : front.ceilingplane.ZatPoint(a);
		else if (part == Side.top) anchor = (upperUnpeg || !back) ? front.ceilingplane.ZatPoint(a) : back.ceilingplane.ZatPoint(a) + 32;
		else anchor = (lowerUnpeg || !back) ? front.ceilingplane.ZatPoint(a) : back.floorplane.ZatPoint(a);
		s.SetTextureYOffset(part, -(anchor % 32));
	}
}
