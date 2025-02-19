# REPO IS GOING THROUGH CHANGES!
# UPDATED DOC: https://krypton-reanimate.gitbook.io (still unfinished)
![repository-open-graph-template(3)](https://github.com/user-attachments/assets/1324e775-2703-4744-861e-ea4ccae934ae)


> [!NOTE]
> Krypton Reanimate is a utility for Roblox- blablablabalblabalabl https://krypton-reanimate.gitbook.io/krypton-reanimate

### Purpose
  - Uses player hats and network ownership manipulation to take advance off the claimed player hats, thus creating a client sided rig to replicate a new character, which allows to run and replicate animation scripts such as Neptunian V or Krystal dance and so on.

### Examples
  - Moving your parts around, converting filtering disabled scripts to make them replicate, debugging some offsets or animations, and so on.

# Code Module
```lua
--[[
	Free Version:
	https://www.roblox.com/catalog/4645404679/International-Fedora-Thailand
	https://www.roblox.com/catalog/3662265036/International-Fedora-Indonesia
	https://www.roblox.com/catalog/4622081834/International-Fedora-China
	https://www.roblox.com/catalog/3992084515/International-Fedora-Vietnam
	https://www.roblox.com/catalog/4819740796/Robox

	Accurate Version:
	https://www.roblox.com/catalog/14255560646/Extra-Left-Tan-Arm
	https://www.roblox.com/catalog/14255562939/Extra-Right-Tan-Arm
	https://www.roblox.com/catalog/17374846953/Extra-Right-Black-Arm
	https://www.roblox.com/catalog/17374851733/Extra-Left-Black-Arm
	https://www.roblox.com/catalog/13421786478/Extra-Torso-Blocky
]]

Configuration = {
	ReturnOnDeath = true,
	Flinging = true,
	PresetFling = true, -- if set to false, KadeAPI.CallFling() won't do anything.
	Animations = true,
	WaitTime = 0.22,
	TeleportOffsetRadius = 20,
	NoCollisions = true,
	AntiVoiding = true,
	SetSimulationRadius = true,
	DisableCharacterScripts = true,
	AccessoryFallbackDefaults = true,
	OverlayFakeCharacter = false,
	
	Hats = nil, -- Set to nil if you want to use defaults.
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Krypton/main/Module.luau"))()
```

# Credits

### Lead Developer

#### @xyzkade 
  - Leader of the project, wrote the entire code

### Contributions:

#### @blukez
  - Genesis-Alike Flinging mechanism.

#### @deuces1961
  - Convinced me to stop relying on Lua optimizations, such as defining variables as they don't make any difference on LuaU VMs, some in general optimization tricks as well.

#### @myworldmain
  - Advice for shift lock fix, really appreciate it.

#### @ballsman3761
  - Critizating my code.

# Official Support
  - Frequently asked questions and documentation, [Click there](https://github.com/KadeTheExploiter/Krypton/blob/main/Documentation.md)
  - Discord server, [Click there](https://discord.gg/ArpG4kDvW2)
