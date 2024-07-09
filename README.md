# Krypton Reanimator
- Krypton, is a Roblox Reanimation script, The purpose of reanimations is to replicate client's animations to server with use of network ownership

# Basic Script Info.

```lua
--[[ 
    [ Kade's Reanimate ]

    Another Krypton's Rewrite.
    Custom Movement Inspired by Mizt.

    Default hats: [ 17374846953, 14255560646, 14255562939, 13421786478, 17374851733]
    - https://www.roblox.com/catalog/17374846953/Extra-Right-Black-Arm
    - https://www.roblox.com/catalog/14255560646/Extra-Left-Tan-Arm
    - https://www.roblox.com/catalog/14255562939/Extra-Right-Tan-Arm
    - https://www.roblox.com/catalog/13421786478/Extra-Torso-Blocky
    - https://www.roblox.com/catalog/17374851733/Extra-Left-Black-Arm

    Settings are likes few lines below.

    Returns a table, {Rig, FlingPart}
    Also sets a global.Rig to the fake character.
]]
```

# Loadstring Module, for easier execution.

```lua
local r_settings  = {}
local global      = getfenv(0)
local mt_rad      = math.rad
local cf_angle    = CFrame.Angles
local cf_zero     = CFrame.identity

r_settings.rig_name      = "FakeRig"
r_settings.no_scripts    = false
r_settings.set_sim_rad   = false
r_settings.no_collisions = true
r_settings.flinging      = false
r_settings.preset_fling  = false
r_settings.anti_void     = true
r_settings.tpless        = false
r_settings.deathpoint    = true
r_settings.animations    = false
r_settings.wait_time     = 0.2
r_settings.radius_val    = 10
r_settings.tp_radius     = 25
r_settings.limbs         = {       -- hats used for limbs replacement for the rig  (default hats below)
    ["Right Arm"] = { -- Right Arm
        name = "RARM",
        texture = "rbxassetid://14255544465",
        mesh = "rbxassetid://14255522247",
        offset = cf_angle(0, 0, mt_rad(90))
    }, -- Right Arm

    ["Left Arm"] = { -- Left Arm
        name = "LARM",
        texture = "rbxassetid://14255544465", 
        mesh = "rbxassetid://14255522247",
        offset = cf_angle(0, 0, mt_rad(90))
    }, -- Left Arm

    ["Right Leg"] = { -- Right Leg
        name = "Accessory (RARM)",
        texture = "rbxassetid://17374768001", 
        mesh = "rbxassetid://17374767929",
        offset = cf_angle(0, 0, mt_rad(90))
    }, -- Right Leg

    ["Left Leg"] = { -- Left Leg
        name = "Accessory (LARM)",
        texture = "rbxassetid://17374768001", 
        mesh = "rbxassetid://17374767929",
        offset = cf_angle(0, 0, mt_rad(90))
    }, -- Left Leg

    ["Torso"] = { -- Torso
        name = "MeshPartAccessory",
        texture = "rbxassetid://13415110780", 
        mesh = "rbxassetid://13421774668",
        offset = cf_zero
    }, -- Torso
}

global.Kade_Config = r_settings
loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Krypton/main/Source.lua"))()
```

# Documentation:

```lua
r_settings.rig_name      = "FakeRig" -- sets name for the rig
r_settings.no_scripts    = false -- disables localscripts in your character every respawn
r_settings.set_sim_rad   = false  -- sets simulationradius to maximum on load -- not sethiddenproperty way so if you arent using incognito or simillar exploits keep that off 
r_settings.no_collisions = true  -- basically noclip for the fakerig
r_settings.flinging      = false -- uses your real char as a fling, will delay slightly autorespawning
r_settings.preset_fling  = false  -- uses built in fling system
r_settings.anti_void     = true  -- avoid being kicked into void
r_settings.wait_time     = 0.2   -- waits until killing the character again on respawn
r_settings.radius_val    = 10    -- radius to keep real rig's away from players 
r_settings.tp_radius     = 25    -- teleport radius around rootpart| rig_root_part * cframe.new(math.random(-tp_radius, tp_radius), 0, math.random(-tp_radius, tp_radius))
r_settings.tpless        = false  -- wont tp your character. resets instantly. might be unstable.
r_settings.animation     = false -- enables base rig animations
r_settings.limbs         = {}     -- hats used for limbs replacement for the rig
r_settings.deathpoint    = true  -- tps your character back where you died

-- to add the sex option... simply put this in one of the lines of code
r_settings.sex = false -- buttfucks target for fling (needs preset_fling enabled)
```


# Discord Server:
  - [https://discord.gg/A7VexVaZDA](https://discord.gg/ArpG4kDvW2 )
