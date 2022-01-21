state("Pcdogs", "EN") {
	byte state : 0x9D288;
	int levelEnd : 0x168A760;
	int levelID : 0x168ADB0;
	int bossStage : 0x0168ADA0, 0x18, 0x70;
}

state("Pcdogs", "SC") {
	byte state : 0x9F840;
	int levelEnd : 0x168D120;
	int levelID : 0x168D770;
	int bossStage : 0x168D760, 0x1C, 0x70;
}

startup {
	vars.levelNames = new string[] {
		"Regent's Park",
		"Toy Store", 
		"Piccadilly", 
		"Big Ben",
		"Cruella I",
		"Royal Museum",
		"The Underground",
		"Carnival",
		"Lumber Mill",
		"Cruella II",
		"Countryside",
		"Barnyard",
		"Ice Festival",
		"Ancient Castle",
		"Cruella III",
		"Spooky Forest",
		"Hedge Maze",
		"De Vil Manor",
		"Toy Factory"  
	};

	vars.bossStages = new int[] {4, 9, 14}; 
	
	settings.Add("game_version", true, "Game Version (requires LiveSplit restart)");
	settings.Add("game_version_en", true, "English", "game_version");
	settings.Add("game_version_sc", false, "Scandinavian", "game_version");
	
	settings.Add("reset_levelselect", false, "Auto-Reset in Level Select Menu"); 

	foreach (string level in vars.levelNames)
		settings.Add("reset_" + level, false, level, "reset_levelselect");
}

init {  

	// TODO: Replace with a mapping
	if (settings["game_version_en"]) {
		version = "EN";
		vars.firstEntityOffset = 0x234A5C;
	} else if (settings["game_version_sc"]) {
		version = "SC";
		vars.firstEntityOffset = 0x23741C;
	}
	
	vars.shouldPortalSplit = false;
	vars.lastLevel = -1;
}

update {
	if (current.state == 0) 
		vars.shouldPortalSplit = false;
 
	if (current.levelID > -1 && current.levelID < vars.levelNames.Length) 
		vars.lastLevel = current.levelID;
}

start {
	return current.state == 2 && old.state == 18 && current.levelID == 0; 
}

split { 
	if (old.levelID == 19 && current.levelID == 19)
		return current.bossStage == 3 && old.bossStage < 3;
	
	if (Array.IndexOf(vars.bossStages, current.levelID) > -1)
		return old.levelID == current.levelID && old.levelEnd == 0 && current.levelEnd == 1;

	var ent = memory.ReadValue<int>(modules.First().BaseAddress + (int)vars.firstEntityOffset);
	while (ent > 0) {
		if (memory.ReadValue<int>(new IntPtr(ent + 0x68)) == 94) { 
			var animating = memory.ReadValue<int>(new IntPtr(ent + 0x174));
			
			if (vars.shouldPortalSplit == false) { 
				vars.shouldPortalSplit = animating == 1;
				return animating == 1;
			}
		}

		ent = memory.ReadValue<int>(new IntPtr(ent));
	}
}

reset { 
	// This is just a... big ouchie
	return settings["reset_levelselect"] &&
	vars.lastLevel >= 0 && vars.lastLevel < vars.levelNames.Length &&
	settings["reset_" + vars.levelNames[vars.lastLevel]] && current.levelID == -1;
}  
 
