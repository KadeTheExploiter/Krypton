
> [!NOTE]
> A reanimate is a technique uses that manipulates a player's character for custom animations or full-body control. This is typically achieved by creating a client-sided rig and welding unanchored parts that exist on server to the rig’s limbs.

# Official Support
  - Frequently asked questions and documentation, [Click there](https://krypton-reanimate.gitbook.io)
  - Discord server
  
  [![Discord Banner 2](https://discord.com/api/guilds/1131676375363879113/widget.png?style=banner2)](https://discord.gg/4YSWVMKRxb)

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


KryptonConfiguration = {
	WaitTime = 0.251,
	FakeRigScale = 1,
	DestroyHeightOffset = 50,
	TeleportOffsetRadius = 20,
	RefitHatCount = 2,

	RigName = "Tetris",

	ReturnOnDeath = true,

	Flinging = { -- UNFINISHED
		Enabled = true,
		MethodUsed = "Tool", -- Tool, Hat, HatTouch
		FlingMagnitude = 8000,
	},

	Reclaim = false,
	Refit = true,
	SetCharacter = true,
	Animations = true,

	NoCollisions = true,
	AntiVoiding = false,
	SetSimulationRadius = false,
	DisableCharacterScripts = true,
	AccessoryFallbackDefaults = true,
	OverlayFakeCharacter = false,
	LimitHatsPerLimb = false,
	NoBodyNearby = true,
	PermanentDeath = true,

	Hats = {
		["Right Arm"] = {
			{Texture = "14255544465", Mesh = "14255522247", Name = "RARM", Offset = CFrame.Angles(0, 0, math.rad(90))},
			{Texture = "4645402630", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.new(0.25,0,0) * CFrame.Angles(math.rad(-90), 0, math.rad(-90))},
		},

		["Left Arm"] = {
			{Texture = "14255544465", Mesh = "14255522247", Name = "LARM", Offset = CFrame.Angles(0, 0, math.rad(90))},
			{Texture = "3650139425", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.new(-0.25,0,0) * CFrame.Angles(math.rad(-90), 0, math.rad(90))}
		},

		["Right Leg"] = {
			{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (RARM)", Offset = CFrame.Angles(0, 0, math.rad(90))},
			{Texture = "4622077774", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(90))},
			{Texture = "3360978739", Mesh = "3030546036", Name = "InternationalFedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(90))},
		},

		["Left Leg"] = {
			{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (LARM)", Offset = CFrame.Angles(0, 0, math.rad(90))},
			{Texture = "3860099469", Mesh = "3030546036", Name = "InternationalFedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(-90))},
			{Texture = "3409604993", Mesh = "3030546036", Name = "InternationalFedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(-90))}
		},

		["Torso"] = {
			{Texture = "13415110780", Mesh = "13421774668", Name = "MeshPartAccessory", Offset = CFrame.identity},
			{Texture = "4819722776", Mesh = "4819720316", Name = "MeshPartAccessory", Offset = CFrame.Angles(0, 0, math.rad(-15))}
		},
	},
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Krypton/main/Module.luau"))()
```

# Credits

### Lead Developer

#### [@xyzkade](https://github.com/KadeTheExploiter) 
  > Leader of the project, wrote the entire code

### Contributions:

#### [@blukez](https://github.com/Blukezz/)
  > Genesis-Alike Flinging mechanism.

#### @deuces1961
  > Convinced me to stop relying on Lua optimizations, such as defining variables as they don't make any difference on LuaU VMs, some in general optimization tricks as well.

#### @myworldmain
  > Advice for shift lock fix, really appreciate it.

#### [@empereans](https://github.com/Empereans)
  > Some fundamental tips.
