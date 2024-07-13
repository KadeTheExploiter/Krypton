# About
### What is this?
  - Krypton Reanimate is a utility for Roblox that revolves around network manipulation and player accessories to intimidate a clientsided rig as a way to bring back pre-rcd exploiting (in a wacky way.)

### Purpose
  - Uses player hats and network ownership manipulation to take advance off the claimed player hats, thus creating a client sided rig to replicate a new character, which allows to run and replicate animation scripts such as Neptunian V or Krystal dance and so on.

### Examples
  - Moving your parts around, converting filtering disabled scripts to make them replicate, debugging some offsets or animations, and so on.

# Code Module
```lua
Configuration = {}
Configuration.ReturnOnDeath = true
Configuration.Flinging = true
Configuration.Animations = true
Configuration.WaitTime = 0.2509
Configuration.RigName = "FakeRig"
Configuration.TeleportOffsetRadius = 25
Configuration.NoCollisions = true
Configuration.AntiVoiding = true
Configuration.SetSimulationRadius = true
Configuration.DisableCharacterScripts = true
Configuration.Hats = nil -- use the default ones for now pls (they are on discord server)
local Module = game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Krypton/main/Module.luau")
loadstring(Module)()
```

# Credits

### Lead Developer

#### @xyzkade 
  - Leader of the project, wrote the entire code

### Contributions:

#### @deuces1961
  - Convinced me to stop relying on Lua optimizations, such as defining variables as they don't make any difference on LuaU VMs, some in general optimization tricks as well.

#### @myworldmain
  - Advice for shift lock fix, really appreciate it.

#### @ballsman3761
  - Critizating my code.

# Official Support
- Discord: https://discord.gg/ArpG4kDvW2
