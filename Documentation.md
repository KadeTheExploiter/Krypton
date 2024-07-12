# FAQ / Information.

## Humanoid.AutoRotate Cannot be changed.
  - Information: The issue for that is because it is being constantly overwritten so the shift lock issue can be fixed without having to do 300 lines of code.

## Lack of mobile support
  - Information: This won't happen for now due to me having not enough information about mobile movement system (Where is the joystick, how does it work, and so on, I am aware this sounds like a silly excuse but I do not play Roblox on mobile.), Roblox on a emulator should be fine.

## Constantly Respawning the rig
  - Information: Due to the patches Roblox threw on us, We have very limited choice of methods, and this one is the most reliable one, out of tools or random unanchored parts to take ownership of, the only way to get around weld destroying is by calling death on your character

## Why not limbs?
  - Information: Somewhere early 2023 Roblox threw a patch for the limbs by taking away ownership of it, which makes parts basically unclaimable, the only workaround is to call `SetNetworkOwner()` on the parts, which again requires serversided execution.

# Configuration

## Hats
- Arguments: Table `[ LimbName = {[1] = Texture <String> , [2] = Mesh <String>, [1] = Name <String>, [1] = Offset <CFrame>} ]`
- Warning: If one out of the four arguments is incorrect, the hat will be skipped automatically from checks (Subject to change.).
- Description: Uses the hats to replicate the client rigs limbs, example:

```lua
local Hats = {
  ['Right Arm'] = {
    {Texture = "rbxassetid://14255544465", Mesh = "rbxassetid://14255522247", Name = "RARM", Offset = CFrame.Angles(0, 0, math.rad(90))}
  },

  -- Rest of the table (ex. Left Arm...)
}
```


## ReturnOnDeath
- Arguments: Boolean `[ true / false ]`
- Warning: None.
- Returns you to the position you've been on with client rig after stopping the reanimate.

## Flinging
- Arguments: Boolean `[ true / false ]`
- Warning: Your Simulation Radius will lower drastically every moment it is triggered.
- Description: Uses your server rig to fling people, Left Mouse Click must be held down to enable flinging state upon respawn, the server rig will follow your mouse and attach to body parts until you let the button off.

## Animations
- Arguments: Boolean `[ true / false ]`
- Warning: None.
- Description: Adds an animation handler to the client rig, bringing back all the old animations.

## WaitTime
- Arguments: Number `[ int / double ]`
- Warning: Setting to early will make it faulty, while making it very late will cause significant issues, recommended values are either 0.251 for quick launching or 0.3 for stability.
- Description: Yields the `CharacterAdded` to make sure all the components are ready to use.

## TeleportOffsetRadius
- Arguments: Boolean `[ true / false ]`
- Warning: Setting it to low might cause additional yielding, and setting it on high will depend on your simulation radius.
- Description: Determinates the radius of teleporting the real rig close to fake rig to claim hats.

## NoCollisions
- Arguments: Boolean `[ true / false ]`
- Warning: In some cases you might get automatically under the map due to your collisions being barely there
- Description: Disables your client rig collisions, letting you clip through walls

## AntiVoiding
- Arguments: Boolean `[ true / false ]`
- Warning: In some cases, you might automatically get stuck under the game if most of the walkable area in your game is close to the `FallenPartsDestroyHeight` property.
- Description: Avoid falling into the void, If you fall into the void you will be sent back to either SpawnLocation or the offset when you reanimated at.

## SetSimulationRadius
- Arguments: Boolean `[ true / false ]`
- Warning: Cannot be enabled on basic local scripts, in-game executors (like @MyWorlds, testing place executor), or in any low identity executor with identity reaching 2.
- Description: Changes your simulation radius so it will always be on the maximum, providing better stability.

## DisableCharacterScripts
- Arguments: Boolean `[ true / false ]`
- Warning: In very special cases, disabling this may break some parts of the experience 
- Description: Disables any local scripts from the server rig to avoid any tampering with client rig.

## RigName
- Arguments: String `[ string ]`
- Warnings: Changing the name to something commonly used in experiences such as `Camera` or `Baseplate` might cause the user some trouble when attempting to index the client rig (ex. for scripts.).
- Description: Renames the client rig to your liking, In some cases it will help with compatibility along other scripts.
