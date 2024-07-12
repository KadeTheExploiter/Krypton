```Documentation for the reanimation```
- Hats
- Arguments: Table `[ LimbName = {[1] = Texture <String> , [2] = Mesh <String>, [1] = Name <String>, [1] = Offset <CFrame>} ]`

` Warning: If one out of the four arguments is incorrect, the hat will be skipped automatically from checks (Subject to change.).

- Description: Uses the hats to replicate the client rigs limbs, example:

```lua
local Hats = {
  ['Right Arm'] = {
    {Texture = "rbxassetid://14255544465", Mesh = "rbxassetid://14255522247", Name = "RARM", Offset = CFrame.Angles(0, 0, math.rad(90))}
  },

  -- Rest of the table (ex. Left Arm...)
}
```

- ReturnOnDeath
- Arguments: Boolean `[ true / false ]`

- Warning: None.

- Returns you to the position you've been on with client rig after stopping the reanimate.

- Flinging
- Arguments: Boolean `[ true / false ]`

- Warning: Your Simulation Radius will lower drastically every moment it is triggered.

- Description: Uses your server rig to fling people, Left Mouse Click must be held down to enable flinging state upon respawn, the server rig will follow your mouse and attach to body parts until you let the button off.

- Animations
- Arguments: Boolean `[ true / false ]`

- Warning: None.

- Description: Adds an animation handler to the client rig, bringing back all the old animations.

- WaitTime
- Arguments: Number `[ int / double ]`

- Warning: Setting to early will make it faulty, while making it very late will cause significant issues, recommended values are either 0.251 for quick launching or 0.3 for stability.

- Description: Yields the `CharacterAdded` to make sure all the components are ready to use.

- TeleportOffsetRadius
- Arguments: Boolean `[ true / false ]`

- Warning: Setting it to low might cause additional yielding, and setting it on high will depend on your simulation radius.

- Description: Determinates the radius of teleporting the real rig close to fake rig to claim hats with ease, Setting to high values will depend on
