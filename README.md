[![Anurag's GitHub stats](https://github-readme-stats.vercel.app/api?username=KadeTheExploiter&theme=catppuccin_latte)](https://github.com/anuraghazra/github-readme-stats)

> [!NOTE]
> A reanimate is a technique uses that manipulates a player's character for custom animations or full-body control. This is typically achieved by creating a client-sided rig and welding unanchored parts that exist on server to the rig’s limbs.

# Official Support
  - Frequently asked questions and documentation, [Click there](https://krypton-reanimate.gitbook.io)
  - Discord server
  
    ![Discord Banner 2](https://discord.com/api/guilds/1131676375363879113/widget.png?style=banner2)

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
    ReturnOnDeath = true,
    Flinging = true,
    FakeRigScale = 1,
    SetCharacter = true,
    Animations = true,
    WaitTime = 0.2501,
    TeleportOffsetRadius = 20,
    NoCollisions = true,
    AntiVoiding = true,
    SetSimulationRadius = true,
    DisableCharacterScripts = true,
    AccessoryFallbackDefaults = true,
    OverlayFakeCharacter = true,
    NoBodyNearby = true,
    LimitHatsPerLimb = true,
    ShowClientHats = true,
    RigName = "Tetris",
    Hats = nil,
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

#### [@empereans](https://discordlookup.com/user/1330293219153416242)
  > Some fundamental tips.
