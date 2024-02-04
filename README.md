# Krypton Reanimator
- Krypton, is a Roblox Reanimation script, The purpose of reanimations is to replicate client's animations to server.

# Loadstring Module, for easier execution.
```lua
local Global = (getgenv and getgenv()) or getfenv(0) or _G
local MathRad = math.rad
local CFrameNew = CFrame.new
local CFAngles = CFrame.Angles
local CFZero = CFrame.identity

Global.KryptonReanimateConfig = {
    R15 = false,
    DebugPrints = false,
    DebugTransparency = 1,
    Animations = false,
    HideRealChar = true,
    WaitTime = 0.07, -- 0.05 min.
    AntiVoid = true,
    StopMethod = "Reset", -- "Reset", "Chat", "Both"
    StopMessage = "/e stop",
    Hats = {
        ["Right Arm"] = { -- Right Arm
            Texture = "rbxassetid://12344206675",
            Mesh = "rbxassetid://12344206657",
            Offset = CFrameNew(0,0.09,0) * CFAngles(MathRad(-125),0,0)
        }, -- Right Arm

        ["Left Arm"] = { -- Left Arm
            Texture = "rbxassetid://12344207341", 
            Mesh = "rbxassetid://12344207333",
            Offset = CFrameNew(0,0,0) * CFAngles(MathRad(-125),0,0)
        }, -- Left Arm

        ["Right Leg"] = { -- Right Leg
            Texture = "http://www.roblox.com/asset/?id=11263219250", 
            Mesh = "rbxassetid://11263221350",
            Offset = CFrameNew(0,0,0) * CFAngles(0,MathRad(-90), MathRad(90))
        }, -- Right Leg

        ["Left Leg"] = { -- Left Leg
            Texture = "http://www.roblox.com/asset/?id=11159284657", 
            Mesh = "rbxassetid://11159370334",
            Offset = CFrameNew(0,0,0) * CFAngles(0,MathRad(-90), MathRad(90))
        }, -- Left Leg

        ["Torso"] = { -- Left Leg
            Texture = "", 
            Mesh = "",
            Offset = CFZero
        }, -- Left Leg
    }
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Krypton/main/Main.lua"))()
```

# Documentation:
  - `R15` <boolean>              | Changes Rig Type of the reanimaton to R15 (True) or R6 (False).
  - `DebugPrints` <boolean>      | Printing Testing Information.
  - `DebugTransparency` <number> | Changes Transparency of FakeRig.
  - `Animations ` <boolean>      | 🛑 Not Finished / Plays basic rig animations.
  - `HideRealChar` <boolean>     | Hides your real rig from client
  - `WaitTime` <number>          | Changes Respawning Speed. Default is 0.075.
  - `AntiVoid` <boolean>         | Will automatically bring you back to spawn when under the map
  - `StopMethod` <string>        | Methods to turn off the reanimate. ("Reset", "Chat", "Both")
  - `StopMessage` <string>       | Customized Chat StopMethod Message (example: /e stop)

# Discord Server:
  - https://discord.gg/A7VexVaZDA
