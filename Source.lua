-- [[ Kade's Reanimate | @xyzkade | https://discord.gg/g2Txp9VRAJvc/ ]] --
local mt_rad      = math.rad
local tb_clear    = table.clear
local ts_delay    = task.delay
local ts_wait     = task.wait
local os_clock    = os.clock
local mt_cos      = math.cos
local mt_sin      = math.sin
local mt_random   = math.random
local cf_new      = CFrame.new
local cf_angle    = CFrame.Angles
local cf_zero     = CFrame.identity
local v3_new      = Vector3.new
local v3_zero     = Vector3.zero
local r3_new      = Region3.new
local in_new      = Instance.new
local global      = getfenv(0)
local config      = global.Kade_Config or {}
global.Rig        = nil

local rig_name      = config.rig_name or "FakeRig" -- sets name for the rig
local no_scripts    = config.no_scripts or false -- disables localscripts in your character every respawn
local set_sim_rad   = config.set_sim_rad or true  -- sets simulationradius to maximum on load
local no_collisions = config.no_collisions or true  -- basically noclip for the fakerig
local flinging      = config.flinging or false -- uses your real char as a fling, will delay slightly autorespawning
local preset_fling  = config.preset_fling or false  -- uses built in fling system (needs fling enabled)
local sex           = config.sex or false  -- buttfucks target for fling (needs preset_fling enabled)
local anti_void     = config.anti_void or true  -- avoid being kicked into void
local wait_time     = config.wait_time or 0.2   -- waits until killing the character again on respawn
local radius_val    = config.radius_val or 10    -- radius to keep real rig's away from players 
local tp_radius     = config.tp_radius or 25    -- teleport radius around rootpart| rig_root_part * cframe.new(math.random(-tp_radius, tp_radius), 0, math.random(-tp_radius, tp_radius))
local limbs         = config.limbs or {       -- hats used for limbs replacement for the rig  (default hats below)
    ["Right Arm"] = { -- Right Arm
        texture = "rbxassetid://12344206675",
        mesh = "rbxassetid://12344206657",
        offset = cf_angle(mt_rad(-125),0,0)
    }, -- Right Arm
    
    ["Left Arm"] = { -- Left Arm
        texture = "rbxassetid://12344207341", 
        mesh = "rbxassetid://12344207333",
        offset = cf_angle(mt_rad(-125),0,0)
    }, -- Left Arm

    ["Right Leg"] = { -- Right Leg
        texture = "http://www.roblox.com/asset/?id=11263219250", 
        mesh = "rbxassetid://11263221350",
        offset = cf_angle(0,mt_rad(-90), mt_rad(90))
    }, -- Right Leg

    ["Left Leg"] = { -- Left Leg
        texture = "http://www.roblox.com/asset/?id=11159284657", 
        mesh = "rbxassetid://11159370334",
        offset = cf_angle(0, mt_rad(-90), mt_rad(90))
    }, -- Left Leg

    ["Torso"] = { -- Torso
        texture = "rbxassetid://13415110780", 
        mesh = "rbxassetid://13421774668",
        offset = cf_zero
    }, -- Torso
}

local enum_keycode   = Enum.KeyCode
local enum_humstate  = Enum.HumanoidStateType
local enum_userinput = Enum.UserInputType

local move_part     = in_new("Part")
local is_mouse_down = false
local fling_part    = nil -- will be added later in the code
local targethum     = nil
local target        = nil
local wasd          = {"w", "a", "s", "d"}
local keys_list     = {w = enum_keycode.W, a = enum_keycode.A, s = enum_keycode.S, d = enum_keycode.D, space = enum_keycode.Space}
local key_values    = {w = {0, 1e4}, a = {1e4,0}, s = {0,-1e4}, d = {-1e4,0}}
local key_pressed   = {w = false, a = false, s = false, d = false, space = false}

local state_dead    = enum_humstate.Dead
local state_physics = enum_humstate.Physics
local state_getup   = enum_humstate.GettingUp
local state_landed  = enum_humstate.Landed

local clonereference       = cloneref or function(x) return x end -- security
local return_network_owner = isnetworkowner or function(part) return part.ReceiveAge == 0 end -- get parts owner

-- ; Settings

-- :: Begin

-- ; Script Variables

local radiuscheck    =  v3_new(radius_val, radius_val, radius_val) -- radius to keep real rig's away from players 
local no_sleep_cf    =  cf_zero -- makes parts always in move so they will never sleep.
local high_vel       =  v3_new(4096,4096,4096) -- flinging velocity
local sin_value      =  0  -- random value, needed for dynamical velocity
local rbx_signals    =  {} -- roblox signals stored in table for easy removal                                                      {event, event, ...}
local hats           =  {} -- Hats that need for the rig to work, such as extra limb accessory.                                    {handle, part1, cframe}
local reset_bind     =  in_new("BindableEvent") -- bindable event for disabling the script.
local mousebutton1   = enum_userinput.MouseButton1

-- ; Datamodel Variables

local workspace  = clonereference(game:FindFirstChildOfClass("Workspace"))
local players    = clonereference(game:FindFirstChildOfClass("Players"))
local runservice = clonereference(game:FindFirstChildOfClass("RunService"))
local startgui   = clonereference(game:FindFirstChildOfClass("StarterGui"))
local inputserv  = clonereference(game:FindFirstChildOfClass("UserInputService"))

rbx_signals[#rbx_signals+1] = inputserv.InputBegan:Connect(function(input, out_of_focus)
	for i, v in next, keys_list do
		if not out_of_focus and input.KeyCode == v then
			key_pressed[i] = true
		end
	end

	if input.UserInputType == mousebutton1 then
		is_mouse_down = true
	end
end)

rbx_signals[#rbx_signals+1] = inputserv.InputEnded:Connect(function(input) -- not needed
	for i, v in next, keys_list do
		if input.KeyCode == v then
			key_pressed[i] = false
		end
	end

	if input.UserInputType == mousebutton1 then
		is_mouse_down = false
	end
end)

-- ; Starting Functions

local function disable_localscripts(descendants_table)
	if not no_scripts then
		return
	end
	
	for i=1,#descendants_table do
		local localscript = descendants_table[i]

		if localscript:IsA("LocalScript") then
			localscript.Disabled = true
		end
	end
end

local function call_move_part(humanoid, positions)        -- calls moving on a humanoid
	local x, z = positions[1], positions[2]
	move_part.CFrame = move_part.CFrame * cf_new(-x, 0,-z)

	humanoid.WalkToPoint = move_part.Position
end

local function wait_for_child_of_class(parent, classname, timeout)              -- waitforchildofclass, nothing else to add
	local time = timeout or 1
	local timed_out = false

	ts_delay(time, function()
		if not parent:FindFirstChildOfClass(classname)  then
			timed_out = true
		end
	end)

	repeat ts_wait() until timed_out or parent:FindFirstChildOfClass(classname) 

	return parent:FindFirstChildOfClass(classname)
end

local function check_matching_hatdata(handle, v_mesh_id, v_texture_id) -- checks if provided values match the handle's values.
	local texture_id  = nil
	local mesh_id     = nil

	if handle:IsA("MeshPart") then -- i geniuelly hope the roblox staff fucking dies
		texture_id  = handle.TextureID 
		mesh_id     = handle.MeshId
	elseif handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh") then
		local mesh = handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh")

		texture_id  = mesh.TextureId
		mesh_id     = mesh.MeshId
	end

	if v_mesh_id == mesh_id and v_texture_id == texture_id then
		return true
	end

	return false
end

local function find_accessory(descendants_table, mesh_id, texture_id)  -- returns a handle if found in the descendant of a model.
	for i = 1,#descendants_table do
		local handle = descendants_table[i]
		if handle.Name == "Handle" and check_matching_hatdata(handle, mesh_id, texture_id) then
			return handle
		end
	end
end

local function disconnect_all_events(table)                            -- disconnects all the events from the weld
	for _,v in next, table do
		v:Disconnect()
	end
end

local function recreate_accessory_and_joints(model, descendants_table) -- Recreates hats to the rig and reconfigures their weld.
	local model_descendants = model:GetDescendants()
	local head = model:WaitForChild("Head")

	for i = 1,#model_descendants do
		local Accessory = model_descendants[i]

		if Accessory:IsA("Accessory") then
			Accessory:Destroy()
		end
	end

	for i = 1,#descendants_table do
		local accessory   = descendants_table[i]

		if accessory:IsA("Accessory") then
			local handle = accessory:WaitForChild("Handle")
			local handle_weld = wait_for_child_of_class(handle, "Weld")
			local previous_weld_data = {handle_weld.C0, handle_weld.C1, handle_weld.Part1}
			
			handle_weld:Destroy()

			local fake_accessory = accessory:Clone()
			local fake_handle = fake_accessory:WaitForChild("Handle", 1)

			if not fake_handle then return end

			local attachment = wait_for_child_of_class(fake_handle, "Attachment")

			local weld = in_new("Weld")

			if (not previous_weld_data[3]) or (previous_weld_data[3] and previous_weld_data[3].Name ~= "Head") then
				if attachment then
					weld.C0    = attachment.CFrame
					weld.C1    = model:FindFirstChild(tostring(attachment), true).CFrame
					weld.Part1 = model:FindFirstChild(tostring(attachment), true).Parent
				else
					weld.Part1 = head
					weld.C1    = cf_new(0, head.Size.Y / 2, 0) * fake_accessory.AttachmentPoint:Inverse()
				end
			elseif previous_weld_data[3] and previous_weld_data[3].Name == "Head" then
				weld.C0    = previous_weld_data[1]
				weld.C1    = previous_weld_data[2]
				weld.Part1 = head
			end

			fake_handle.Transparency = 1
			fake_handle.CFrame = weld.Part1.CFrame * weld.C1 * weld.C0:Inverse()

			weld.Name     = "AccessoryWeld"
			weld.Part0    = fake_handle
			weld.Parent   = fake_handle

			fake_accessory.Parent = model
		end
	end
end

local function write_hats_to_table(descendants_table, fake_descendants_table, fake_model)       -- adds hats for alignment, and tweaks them ( hats )
	for i = 1,#descendants_table do
		local handle = descendants_table[i]

		if handle.Name == "Handle" then
			handle.Massless = false

			local texture_id  = nil
			local mesh_id     = nil --mesh.MeshId

			if handle:IsA("MeshPart") then
				texture_id  = handle.TextureID --or mesh.TextureId
				mesh_id     = handle.MeshId
			elseif handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh") then
				local mesh = handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh")
		
				texture_id  = mesh.TextureId
				mesh_id     = mesh.MeshId
			end
		

			local fake_handle = find_accessory(fake_descendants_table, mesh_id, texture_id)

			for name, values in next, limbs do
				local found_part = fake_model:WaitForChild(name)
				local found_part_name = found_part.Name

				if fake_model:FindFirstChild(name) and check_matching_hatdata(handle, values.mesh, values.texture) then
					hats[#hats+1] = {handle, fake_model:FindFirstChild(found_part_name), values.offset}
					if fake_handle then
						fake_handle:Destroy()
					end
				end
			end

			
			if fake_handle then
				hats[#hats+1] = {handle, fake_handle}
			end
		end
	end
end

local function cframe_link_parts(part0, part1, offset)                  -- connects part0 to part1
	if part0 and part0.Parent and part1 and part1.Parent then
		local part0_mass               = part1.Mass * 5
		part0.AssemblyLinearVelocity   = v3_new(part1.AssemblyLinearVelocity.X * part0_mass, sin_value, part1.AssemblyLinearVelocity.Z * part0_mass)
		part0.AssemblyAngularVelocity  = part1.AssemblyAngularVelocity

		if return_network_owner(part0) then
			part0.CFrame = part1.CFrame * offset
		end
	end
end

local function are_players_near(cframe)                                 -- checks if players are near the tp location.
	local position = cframe.Position
	local radius = radiuscheck / 2

	local check_region = r3_new(position - radius, position + radius)
	local parts_in_way = workspace:FindPartsInRegion3(check_region, nil, math.huge)

	for i=1,#parts_in_way do
		local model = parts_in_way[i].Parent

		if model:IsA("Model") and model.PrimaryPart ~= nil then
			return true
		end
	end

	return false
end

-- ; Variables

local pre_sim     = runservice.PreSimulation
local post_sim    = runservice.PostSimulation
local is_mobile   = inputserv.TouchEnabled
local camera      = workspace.CurrentCamera
local destroy_h   = workspace.FallenPartsDestroyHeight
local spawnpoint  = wait_for_child_of_class(workspace, "SpawnLocation", 1)

local player      = players.LocalPlayer
local mouse       = player:GetMouse()
local character   = player.Character
local descendants = character:GetDescendants()

-- ; Character Variables

local humanoid   = character:FindFirstChildOfClass("Humanoid")
local hrp        = character:WaitForChild("HumanoidRootPart", 5)

if not humanoid and hrp then
	return nil -- No Humanoid and HumanoidRootPart
end

-- ; Rig

local return_cf  = spawnpoint and spawnpoint.CFrame * cf_new(0,20,0) or hrp.CFrame
local rig_hrp, rig_hum, rig_descendants

local rig = in_new("Model"); do -- Scoping to make it look nice.
	rig_hum  = in_new("Humanoid")
	local hum_desc = in_new("HumanoidDescription")
	local animator = in_new("Animator")

	local function makejoint(name, part0, part1, c0, c1)
		local joint  = in_new("Motor6D")

		joint.Name   = name
		joint.Part0  = part0
		joint.Part1  = part1
		joint.C0     = c0
		joint.C1     = c1

		joint.Parent = part0
	end
	
	local function makeattachment(name, cframe, parent)
		local attachment  = in_new("Attachment")

		attachment.Name   = name
		attachment.CFrame = cframe

		attachment.Parent = parent
	end

	local head      = in_new("Part")
	local torso     = in_new("Part")
	local right_arm = in_new("Part")

	head.Size       = v3_new(2,1,1)
	torso.Size      = v3_new(2,2,1)
	right_arm.Size  = v3_new(1,2,1)

	head.Transparency      = 1
	torso.Transparency     = 1
	right_arm.Transparency = 1

	rig_hrp  = torso:Clone()
	rig_hrp.CanCollide = false

	local left_arm  = right_arm:Clone()
	local right_leg = right_arm:Clone()
	local left_leg  = right_arm:Clone()

	rig_hrp.Name   = "HumanoidRootPart"
	torso.Name     = "Torso"
	head.Name      = "Head"
	right_arm.Name = "Right Arm"
	left_arm.Name  = "Left Arm"
	right_leg.Name = "Right Leg"
	left_leg.Name  = "Left Leg"

	animator.Parent  = rig_hum
	hum_desc.Parent  = rig_hum

	rig_hum.Parent   = rig
	rig_hrp.Parent   = rig
	head.Parent      = rig
	torso.Parent     = rig
	right_arm.Parent = rig
	left_arm.Parent  = rig
	right_leg.Parent = rig
	left_leg.Parent  = rig
	rig_hum.Parent   = rig

	makejoint('Neck',           torso,    head,       cf_new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),    cf_new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	makejoint('RootJoint',      rig_hrp,  torso,      cf_new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),    cf_new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	makejoint('Right Shoulder', torso,    right_arm,  cf_new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),  cf_new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	makejoint('Left Shoulder',  torso,    left_arm,   cf_new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),  cf_new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	makejoint('Right Hip',      torso,    right_leg,  cf_new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),   cf_new(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	makejoint('Left Hip',       torso,    left_leg,   cf_new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),   cf_new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	makeattachment("HairAttachment",          cf_new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      head)
	makeattachment("HatAttachment",           cf_new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      head)
	makeattachment("FaceFrontAttachment",     cf_new(0, 0, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1),     head)
	makeattachment("RootAttachment",          cf_new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),     rig_hrp)
	makeattachment("LeftShoulderAttachment",  cf_new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),    left_arm)
	makeattachment("LeftGripAttachment",      cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),   left_arm)
	makeattachment("RightShoulderAttachment", cf_new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),   right_arm)
	makeattachment("RightGripAttachment",     cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),  right_arm)
	makeattachment("LeftFootAttachment",      cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),   left_leg)	
	makeattachment("RightFootAttachment",     cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),  right_leg)
	makeattachment("NeckAttachment",          cf_new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),       torso)
	makeattachment("BodyFrontAttachment",     cf_new(0, 0, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),    torso)
	makeattachment("BodyBackAttachment",      cf_new(0, 0, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),     torso)
	makeattachment("LeftCollarAttachment",    cf_new(-1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      torso)
	makeattachment("RightCollarAttachment",   cf_new(1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),       torso)
	makeattachment("WaistFrontAttachment",    cf_new(0, -1, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),   torso)
	makeattachment("WaistCenterAttachment",   cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      torso)
	makeattachment("WaistBackAttachment",     cf_new(0, -1, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),    torso)
	
	recreate_accessory_and_joints(rig, descendants)

	-- Clientsided parts

	move_part.Transparency = 1
	move_part.CanCollide   = false
	move_part.Parent       = rig

	if flinging then
		fling_part         = move_part:Clone()
		fling_part.Parent  = rig
		
		fling_part.Destroying:Once(function()
			print('gg fling broken')	
		end)

		if not preset_fling then
			fling_part.Anchored = true
		end
	end

	move_part.Destroying:Once(function()
		print('gg movement broken')	
	end)

	rig_descendants = rig:GetDescendants()
	rig_hrp.CFrame  = hrp.CFrame * cf_new(0, 0, 2)
	rig.Name        = rig_name
	rig.Parent      = workspace
end

-- :: Functions

local function get_flingy()  -- system brrrrrrrr flinging
	if not preset_fling or not fling_part and not fling_part.Parent then
		return
	end
	
	local temp              = nil
	local temp2             = nil
	local offset            = cf_zero
	local velocity          = high_vel

	if sex and humanoid.Parent then -- had to look at iy because idk the anims so uh sorry if it seems skiddy anyway credit to inf yield for the anim n shit
		local bang_anim = Instance.new("Animation")
		bang_anim.AnimationId = humanoid.RigType.Name == "R15" and "rbxassetid://5918726674" or "rbxassetid://148840371"

		local bang = humanoid:LoadAnimation(bang_anim)
		bang:Play(0.1, 1, 1)
		bang:AdjustSpeed(10)
		humanoid.Died:Once(function()
			bang:Stop()
			bang_anim:Destroy()
		end)
	end

	local children = character:GetChildren()
	temp2 = pre_sim:Connect(function()
		for i=1,#children do
			local child = children[i]

			if child:IsA("BasePart") then
				child.CanCollide = false
				child.CanTouch = false
				child.CanQuery = false
			end
		end
		
		offset = cf_new(0, 0, 1 + 0.5 * mt_sin(os_clock()*50))
	end)

	temp = post_sim:Connect(function() -- better cframe first for hrp.
		hrp.CFrame = fling_part.CFrame * offset
		hrp.AssemblyLinearVelocity = velocity
		hrp.AssemblyAngularVelocity = v3_zero
	end)
		
	repeat ts_wait() until not is_mouse_down

	velocity = v3_zero

	ts_wait(wait_time)

	temp2:Disconnect()
	temp:Disconnect()
end

local function set_camera_target()  -- Fixes cameras.
	local old_cam_cf = camera.CFrame
	camera.CameraSubject = rig_hum
	camera:GetPropertyChangedSignal("CFrame"):Once(function()
		camera.CFrame = old_cam_cf
	end)
end

local function characteradded_event() -- Automatically respawns the player.
	local old_cam_cf = camera.CFrame
	camera.CameraSubject = rig_hum

	camera:GetPropertyChangedSignal("CFrame"):Wait()
	camera.CFrame = old_cam_cf

	character  = player.Character
	hrp        = character:WaitForChild("HumanoidRootPart", 5)
	humanoid   = wait_for_child_of_class(character, "Humanoid")

	set_camera_target()

	local tp_offset = rig_hrp.CFrame * cf_new(mt_random(-tp_radius, tp_radius), 0.25, mt_random(-tp_radius, tp_radius))
	
	while are_players_near(tp_offset) do
		tp_offset = rig_hrp.CFrame * cf_new(mt_random(-tp_radius, tp_radius), 0, mt_random(-tp_radius, tp_radius))
		ts_wait()
	end
	
	if fling_part and fling_part.Parent then
		get_flingy()
	end

	hrp.CFrame = tp_offset
	
	ts_wait(wait_time)

	descendants = character:GetDescendants()
	disable_localscripts(descendants)
	recreate_accessory_and_joints(rig, descendants)

	tb_clear(hats)

	rig_descendants = rig:GetDescendants()
	humanoid:ChangeState(state_physics)
	character:BreakJoints()
	write_hats_to_table(descendants, rig_descendants, rig)
end

local function postsimulation_event() -- Hat System.
	if set_sim_rad then
		player.MaximumSimulationRadius = 32768
		player.SimulationRadius        = 32768	
	end

	for _, data in next, hats do
		local handle = data[1]
		local part1  = data[2]
		local offset = data[3] or cf_zero
		
		cframe_link_parts(handle, part1, offset * no_sleep_cf)
	end

	if preset_fling and fling_part and fling_part.Parent then
		if is_mouse_down then
			fling_part.AssemblyLinearVelocity = v3_zero

			target = mouse.Target.Parent and mouse.Target.Parent:FindFirstChildOfClass("Part") or mouse.Target.Parent.Parent and mouse.Target.Parent.Parent:FindFirstChildOfClass("Part")
			if target and target.Name == "HumanoidRootPart" or target.Name == "Head" or target.Name == "Handle" then
				targethum = target.Parent:FindFirstChildOfClass("Humanoid") or target.Parent.Parent:FindFirstChildOfClass("Humanoid") 
				if targethum and targethum.MoveDirection.Magnitude >= 0.1 then
					fling_part.CFrame = target.CFrame * cf_new(targethum.MoveDirection*7.5)
				else
					fling_part.CFrame = target.CFrame * (target.Velocity.Magnitude > 6 and cf_new(target.CFrame.LookVector*mt_random(-4, 5)) or cf_zero)
				end
			else
				fling_part.CFrame = is_mouse_down and mouse.hit or cf_zero
			end
		else
			fling_part.CFrame = cf_zero
		end
	end
end

local function presimulation_event() -- Movement temporary.
	if no_collisions then
		for i=1,#rig_descendants do
			local part = rig_descendants[i]
			
			if part and part.Parent and part:IsA("BasePart") then
				part.CanCollide = false
				part.CanTouch   = false
				part.CanQuery   = false
			end
		end
	end

	if anti_void and rig_hrp.Position.Y <= (destroy_h + 75)  then
		rig_hrp.CFrame = return_cf
		rig_hrp.AssemblyLinearVelocity = v3_zero
		rig_hrp.AssemblyAngularVelocity = v3_zero
	end

	no_sleep_cf = cf_new(0.01 * mt_sin(os_clock()*16), 0, 0.01 * mt_cos(os_clock()*16))
	sin_value = 40 - 3 * mt_sin(os_clock()*10)
end

local function disable_script() -- Disables the script.
	disconnect_all_events(rbx_signals)

	rig:Destroy()
	reset_bind:Destroy()

	player.Character = character
	camera.CameraSubject = humanoid
	global.Rig = nil

	startgui:SetCore("ResetButtonCallback", true)
end

local function move_rig_humanoid()  -- Makes the rig move.
    local look_vector = camera.CFrame.lookVector

    for _, key in next, wasd do
        if key_pressed[key] then
            call_move_part(rig_hum, key_values[key])
        end
    end

    move_part.Position = rig_hrp.Position
    move_part.CFrame = cf_new(move_part.Position, v3_new(look_vector.X * 9999, look_vector.Y, look_vector.Z * 9999))

    if key_pressed["space"] then rig_hum.Jump = true end

    local movement_keys_pressed = key_pressed["w"] or key_pressed["a"] or key_pressed["s"] or key_pressed["d"]
    if not movement_keys_pressed then
        rig_hum.WalkToPoint = rig_hrp.Position
    end

	if is_mobile then -- temporary solution.
		rig_hum.Jump = humanoid.Jump
		rig_hum:Move(humanoid.MoveDirection, false)
	end
end

-- :: Finishing

-- Binding Functions To Signals

humanoid:ChangeState(state_dead)
character:BreakJoints()

rbx_signals[#rbx_signals+1] = player.CharacterAdded:Connect(characteradded_event)
rbx_signals[#rbx_signals+1] = reset_bind.Event:Connect(disable_script)
rbx_signals[#rbx_signals+1] = rig:GetPropertyChangedSignal("Parent"):Once(disable_script)
rbx_signals[#rbx_signals+1] = rig_hrp:GetPropertyChangedSignal("Parent"):Once(disable_script)
rbx_signals[#rbx_signals+1] = camera:GetPropertyChangedSignal("CameraSubject"):Connect(set_camera_target)
rbx_signals[#rbx_signals+1] = pre_sim:Connect(presimulation_event)
rbx_signals[#rbx_signals+1] = post_sim:Connect(postsimulation_event)
rbx_signals[#rbx_signals+1] = post_sim:Connect(move_rig_humanoid)

startgui:SetCore("ResetButtonCallback", reset_bind)

-- Starting.

set_camera_target()
write_hats_to_table(descendants, rig_descendants, rig)

rig_hum:ChangeState(state_getup)
rig_hum:ChangeState(state_landed)

return {rig, fling_part} -- unanchor fling_part to use.
