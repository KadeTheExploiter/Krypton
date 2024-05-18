-- [[ Kade's Reanimate | @xyzkade | https://discord.gg/g2Txp9VRAJvc/ | V: 1.1.0 ]] --
local str_sub     = string.sub
local mt_rad      = math.rad
local tb_insert   = table.insert
local tb_clear    = table.clear
local ts_spawn    = task.spawn
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

-- if your first title in brawl stars was "CEO of brawl Stars" please kill yourself immediately
local rig_name      = config.rig_name or "FakeRig" -- sets name for the rig
local animations    = config.animations or true -- enables base rig animations
local no_scripts    = config.no_scripts or false -- disables localscripts in your character every respawn
local set_sim_rad   = config.set_sim_rad or false  -- sets simulationradius to maximum on load
local no_collisions = config.no_collisions or false  -- basically noclip for the fakerig
local flinging      = config.flinging or true -- uses your real char as a fling, will delay slightly autorespawning
local preset_fling  = config.preset_fling or true  -- uses built in fling system (needs fling enabled)
local sex           = config.sex or false  -- buttfucks target for fling (needs preset_fling enabled)
local tpless        = config.tpless or false  -- wont tp your character. resets instantly. might be unstable.
local anti_void     = config.anti_void or false  -- avoid being kicked into void
local wait_time     = config.wait_time or 0.26   -- waits until killing the character again on respawn
local radius_val    = config.radius_val or 10    -- radius to keep real rig's away from players 
local deathpoint    = config.deathpoint or true    -- tps you back to the same place when you stopped the reanimate
local tp_radius     = config.tp_radius or 25    -- teleport radius around rootpart| rig_root_part * cframe.new(math.random(-tp_radius, tp_radius), 0, math.random(-tp_radius, tp_radius))
local limbs         = config.limbs or {       -- hats used for limbs replacement for the rig  (default hats below)
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
local state_getup   = enum_humstate.GettingUp
local state_landed  = enum_humstate.Landed

local clonereference       = cloneref or function(x) return x end -- security
local return_network_owner = isnetworkowner or function(part) return part.ReceiveAge == 0 end -- get parts owner

-- :: Begin

-- ; Script Variables

local radiuscheck    =  v3_new(radius_val, radius_val, radius_val) -- radius to keep real rig's away from players 
local no_sleep_cf    =  cf_zero -- makes parts always in move so they will never sleep.
local high_vel       =  v3_new(8096,8096,8096) -- flinging velocity
local sin_value      =  0  -- random value, needed for dynamical velocity
local rbx_signals    =  {} -- roblox signals stored in table for easy removal                                                      {event, event, ...}
local hats           =  {} -- Hats that need for the rig to work, such as extra limb accessory.                                    {handle, part1, cframe}
local reset_bind     =  in_new("BindableEvent") -- bindable event for disabling the script.
local mousebutton1   =  enum_userinput.MouseButton1

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
	if no_scripts then
		for i=1,#descendants_table do
			local localscript = descendants_table[i]
	
			if localscript:IsA("LocalScript") then
				localscript.Disabled = true
			end
		end
	end
end

local function call_move_part(humanoid, positions)        -- calls moving on a humanoid
	local x, z = positions[1], positions[2]
	move_part.CFrame = move_part.CFrame * cf_new(-x, 0,-z)

	humanoid.WalkToPoint = move_part.Position
end

local function ffcoc_and_name(parent, classname, name)     -- findfirstchildofclass with name check
	local list = parent:GetDescendants()
	for i=1,#list do
		local x = list[i]
		
		if x.Name == name and x:IsA(classname) then
			return x
		end
	end

	return nil
end

local function wait_for_child_of_class(parent, classname, timeout, name)     -- waitforchildofclass, nothing else to add, 4th arg is name check
	local check        = name and true
	local time         = timeout or 1
	local timed_out    = false
	local return_value = nil

	ts_delay(time, function()
		if not ffcoc_and_name(parent, classname, name) then
			timed_out = true
		end
	end)

	repeat ts_wait() until timed_out or check and ffcoc_and_name(parent, classname, name) or parent:FindFirstChildOfClass(classname)
	return_value = check and ffcoc_and_name(parent, classname, name) or parent:FindFirstChildOfClass(classname)

	return return_value
end

local function check_matching_hatdata(handle, v_name, v_mesh_id, v_texture_id) -- checks if provided values match the handle's values.
	local texture_id  = nil
	local mesh_id     = nil
	local name        = nil
	local parent      = handle.Parent

	if handle:IsA("MeshPart") then -- i geniuelly hope the roblox staff fucking dies
		texture_id  = handle.TextureID 
		mesh_id     = handle.MeshId
	elseif handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh") then
		local mesh = handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh")

		texture_id  = mesh.TextureId
		mesh_id     = mesh.MeshId
	end

	name = parent and parent.Name or ""
	if v_name == name and v_mesh_id == mesh_id and v_texture_id == texture_id then
		return true
	end

	return false
end

local function find_accessory(descendants_table, name, mesh_id, texture_id)  -- returns a handle if found in the descendant of a model.
	for i = 1,#descendants_table do
		local handle = descendants_table[i]
		if handle.Name == "Handle" and check_matching_hatdata(handle, name, mesh_id, texture_id) then
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
			local handle = wait_for_child_of_class(accessory, "BasePart", 1, "Handle")
			local handle_weld = wait_for_child_of_class(handle, "Weld", 1)
			local previous_weld_data = {handle_weld.C0 or cf_zero, handle_weld.C1 or cf_zero, handle_weld.Part1}
			
			handle_weld:Destroy()

			local fake_accessory = accessory:Clone()
			local fake_handle = wait_for_child_of_class(fake_accessory, "BasePart", 1, "Handle")

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
		

			local fake_handle = find_accessory(fake_descendants_table, handle.Parent.Name, mesh_id, texture_id)

			for name, values in next, limbs do
				local found_part = fake_model:WaitForChild(name)
				local found_part_name = found_part.Name

				if fake_model:FindFirstChild(name) and check_matching_hatdata(handle, values.name, values.mesh, values.texture) then
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

local hrp        = wait_for_child_of_class(character, "BasePart", 5, "HumanoidRootPart")
local humanoid   = wait_for_child_of_class(character, "Humanoid", 5)

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

		return joint
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

	local nk = makejoint('Neck',           torso,    head,       cf_new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),    cf_new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	local rj = makejoint('RootJoint',      rig_hrp,  torso,      cf_new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),    cf_new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	local rs = makejoint('Right Shoulder', torso,    right_arm,  cf_new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),  cf_new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	local ls = makejoint('Left Shoulder',  torso,    left_arm,   cf_new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),  cf_new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	local rh = makejoint('Right Hip',      torso,    right_leg,  cf_new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),   cf_new(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	local lh = makejoint('Left Hip',       torso,    left_leg,   cf_new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),   cf_new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

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
		fling_part.Size    = v3_zero
		fling_part.Parent  = rig

		if not preset_fling then
			fling_part.Anchored = true
		end
	end

	rig_descendants = rig:GetDescendants()
	rig_hrp.CFrame  = hrp.CFrame * cf_new(0, 0, 2)
	rig.Name        = rig_name
	rig.Parent      = workspace

	if animations then
		ts_spawn(function()
			local anim_script = in_new("LocalScript")
			anim_script.Name = "Animate"
			anim_script.Parent = rig
			local anims_toggled = (anim_script and anim_script.Parent) and anim_script.Enabled or false
			local anim_priority = Enum.AnimationPriority
			local playAnimation = function() end
			local toolKeyFrameReachedFunc = function() end
	
			local pose = "Standing"
			local currentAnim = ""
			local currentAnimInstance = nil
			local currentAnimTrack = nil
			local currentAnimKeyframeHandler = nil
			local currentAnimSpeed = 1.0
			local toolAnimName = ""
			local toolAnimTrack = nil
			local toolAnimInstance = nil
			local currentToolAnimKeyframeHandler = nil
			local lastTick = 0
			local toolAnim = "None"
			local toolAnimTime = 0
			local jumpAnimTime = 0
			local jumpAnimDuration = 0.3
			local toolTransitionTime = 0.1
			local fallTransitionTime = 0.3
			local time = 0
			local animTable = {}
			local dances = {"dance1", "dance2", "dance3"}
			local emoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}
			local animNames = { 
				idle = 	{ { id = "http://www.roblox.com/asset/?id=180435571", weight = 9 }, { id = "http://www.roblox.com/asset/?id=180435792", weight = 1 } },
				walk = 	{ { id = "http://www.roblox.com/asset/?id=180426354", weight = 10 } }, 
				run = 	{ { id = "run.xml", weight = 10 } }, 
				jump = 	{ { id = "http://www.roblox.com/asset/?id=125750702", weight = 10 } }, 
				fall = 	{ { id = "http://www.roblox.com/asset/?id=180436148", weight = 10 } }, 
				climb = { { id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } }, 
				sit = 	{ { id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } },	
				toolnone = { { id = "http://www.roblox.com/asset/?id=182393478", weight = 10 } },
				toolslash = { { id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } },
				toollunge = { { id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } },
				wave = { { id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } },
				point = { { id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } },
				dance1 = { { id = "http://www.roblox.com/asset/?id=182435998", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491037", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491065", weight = 10 } },
				dance2 = { { id = "http://www.roblox.com/asset/?id=182436842", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491248", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491277", weight = 10 } },
				dance3 = { { id = "http://www.roblox.com/asset/?id=182436935", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491368", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491423", weight = 10 } },
				laugh = { { id = "http://www.roblox.com/asset/?id=129423131", weight = 10 } },
				cheer = { { id = "http://www.roblox.com/asset/?id=129423030", weight = 10 } },
			}
		
			local function conFakeRigAnimationSet(name, fileList)
				if (animTable[name] ~= nil) then
					for _, connection in pairs(animTable[name].connections) do
						connection:disconnect()
					end
				end
				animTable[name] = {}
				animTable[name].count = 0
				animTable[name].totalWeight = 0	
				animTable[name].connections = {}
				local config = script:FindFirstChild(name)
				if (config ~= nil) then
					tb_insert(animTable[name].connections, config.ChildAdded:connect(function(child) conFakeRigAnimationSet(name, fileList) end))
					tb_insert(animTable[name].connections, config.ChildRemoved:connect(function(child) conFakeRigAnimationSet(name, fileList) end))
					local idx = 1
					for _, childPart in next, config:GetChildren() do
						if (childPart:IsA("Animation")) then
							tb_insert(animTable[name].connections, childPart.Changed:Connect(function(property) conFakeRigAnimationSet(name, fileList) end))
							animTable[name][idx] = {}
							animTable[name][idx].anim = childPart
							local weightObject = childPart:FindFirstChild("Weight")
							if (weightObject == nil) then
								animTable[name][idx].weight = 1
							else
								animTable[name][idx].weight = weightObject.Value
							end
							animTable[name].count = animTable[name].count + 1
							animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
							idx = idx + 1
						end
					end
				end
				if (animTable[name].count <= 0) then
					for idx, anim in pairs(fileList) do
						animTable[name][idx] = {}
						animTable[name][idx].anim = Instance.new("Animation")
						animTable[name][idx].anim.Name = name
						animTable[name][idx].anim.AnimationId = anim.id
						animTable[name][idx].weight = anim.weight
						animTable[name].count = animTable[name].count + 1
						animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
					end
				end
			end
		
			if animator then
				local animTracks = animator:GetPlayingAnimationTracks()
				for i, track in next, animTracks do
					track:Stop(0); track:Destroy()
				end
			end
		
			for name, fileList in next, animNames do 
				conFakeRigAnimationSet(name, fileList)
			end	
		
			local function stopAllAnimations()
				local oldAnim = currentAnim
				if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
					oldAnim = "idle"
				end
				currentAnim, currentAnimInstance = "", nil
				if (currentAnimKeyframeHandler ~= nil) then
					currentAnimKeyframeHandler:disconnect()
				end
		
				if (currentAnimTrack ~= nil) then
					currentAnimTrack:Stop()
					currentAnimTrack:Destroy()
					currentAnimTrack = nil
				end
				return oldAnim
			end
		
			local function setAnimationSpeed(speed)
				if speed ~= currentAnimSpeed then
					currentAnimSpeed = speed
					currentAnimTrack:AdjustSpeed(currentAnimSpeed)
				end
			end
		
			local function keyFrameReachedFunc(frameName)
				if (frameName == "End") then
					local repeatAnim = currentAnim
					if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
						repeatAnim = "idle"
					end
		
					local animSpeed = currentAnimSpeed
					playAnimation(repeatAnim, 0.0, rig_hum)
					setAnimationSpeed(animSpeed)
				end
			end
		
			playAnimation = function(animName, transitionTime, humanoid) 
				local roll = mt_random(1, animTable[animName].totalWeight) 
				local idx = 1
				while (roll > animTable[animName][idx].weight) do
					roll = roll - animTable[animName][idx].weight
					idx = idx + 1
				end
				local anim = animTable[animName][idx].anim
				if (anim ~= currentAnimInstance) then
					if (currentAnimTrack ~= nil) then
						currentAnimTrack:Stop(transitionTime)
						currentAnimTrack:Destroy()
					end
					currentAnimSpeed = 1.0
					currentAnimTrack = humanoid:LoadAnimation(anim)
					currentAnimTrack.Priority = anim_priority.Core
		
					currentAnimTrack:Play(transitionTime)
					currentAnim = animName
					currentAnimInstance = anim
		
					if (currentAnimKeyframeHandler ~= nil) then
						currentAnimKeyframeHandler:disconnect()
					end
					currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
				end
			end
		
			local function playToolAnimation(animName, transitionTime, humanoid, priority)	 
				local roll = mt_random(1, animTable[animName].totalWeight) 
				local idx = 1
				while (roll > animTable[animName][idx].weight) do
					roll = roll - animTable[animName][idx].weight
					idx = idx + 1
				end
				local anim = animTable[animName][idx].anim
				if (toolAnimInstance ~= anim) then
					if (toolAnimTrack ~= nil) then
						toolAnimTrack:Stop()
						toolAnimTrack:Destroy()
						transitionTime = 0
					end
		
					toolAnimTrack = humanoid:LoadAnimation(anim)
					if priority then
						toolAnimTrack.Priority = priority
					end
		
					toolAnimTrack:Play(transitionTime)
					toolAnimName = animName
					toolAnimInstance = anim
		
					currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
				end
			end
		
			toolKeyFrameReachedFunc = function(frameName)
				pcall(function() 
					if (frameName == "End") then playToolAnimation(toolAnimName, 0.0, rig_hum) end 
				end)
			end
		
			local function stopToolAnimations()
				local oldAnim = toolAnimName
				if (currentToolAnimKeyframeHandler ~= nil) then
					currentToolAnimKeyframeHandler:disconnect()
				end
				toolAnimName = ""
				toolAnimInstance = nil
				if (toolAnimTrack ~= nil) then
					toolAnimTrack:Stop()
					toolAnimTrack:Destroy()
					toolAnimTrack = nil
				end
				return oldAnim
			end
		
			local function onDied() if anims_toggled then pose = "Dead" end end
			local function onGettingUp() if anims_toggled then pose = "GettingUp" end end
			local function onFallingDown() if anims_toggled then	pose = "FallingDown" end end
			local function onSeated() if anims_toggled then pose = "Seated" end end
			local function onPlatformStanding() if anims_toggled then pose = "PlatformStanding" end end
			local function onRunning(speed)
				if anims_toggled  then
					if speed > 0.01 then
						playAnimation("walk", 0.1, rig_hum) pose = "Running"
						if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
							setAnimationSpeed(speed / 14.5)
						end
					else
						if emoteNames[currentAnim] == nil then playAnimation("idle", 0.1, rig_hum) pose = "Standing" end
					end
				end
			end
		
			local function onJumping()
				if anims_toggled then 
					playAnimation("jump", 0.1, rig_hum)
					jumpAnimTime = jumpAnimDuration
					pose = "Jumping"
				end
			end
		
			local function onClimbing(speed)
				if anims_toggled then
					playAnimation("climb", 0.1, rig_hum) setAnimationSpeed(speed / 12.0) pose = "Climbing"
				end
			end
		
			local function onFreeFall()
				if anims_toggled then
					if (jumpAnimTime <= 0) then playAnimation("fall", fallTransitionTime, rig_hum) end
					pose = "FreeFall"
				end
			end
		
			local function onSwimming(speed)
				if anims_toggled then pose = speed >= 0 and "Running" or "Standing" end
			end
		
			local function getTool()
				return nil
			end
		
			local function getToolAnim(tool)
				for _, c in next, tool:GetChildren() do
					if c.Name == "toolanim" and c.ClassName == "StringValue" then
						return c
					end
				end
				return nil
			end
		
			local function animateTool()
				if anims_toggled then
					if (toolAnim == "None") then
						playToolAnimation("toolnone", toolTransitionTime, rig_hum, anim_priority.Idle) return
					end
					if (toolAnim == "Slash") then
						playToolAnimation("toolslash", 0, rig_hum, anim_priority.Action) return
					end
					if (toolAnim == "Lunge") then
						playToolAnimation("toollunge", 0, rig_hum, anim_priority.Action) return
					end
				end
			end
		
			local function move(time)
				local amplitude = 1
				local frequency = 1
				local deltaTime = time - lastTick
				lastTick = time
		
				local climbFudge = 0
				local setAngles = false
		
				if (jumpAnimTime > 0) then
					jumpAnimTime = jumpAnimTime - deltaTime
				end
		
				if (pose == "FreeFall" and jumpAnimTime <= 0) then
					playAnimation("fall", fallTransitionTime, rig_hum)
				elseif (pose == "Seated") then
					playAnimation("sit", 0.5, rig_hum)
					return
				elseif (pose == "Running") then
					playAnimation("walk", 0.1, rig_hum)
				elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
					stopAllAnimations()
					amplitude = 0.1
					frequency = 1
					setAngles = true
				end
		
				if (setAngles) then
					local desiredAngle = amplitude * mt_sin(time * frequency)
					rs:SetDesiredAngle(desiredAngle + climbFudge)
					ls:SetDesiredAngle(desiredAngle - climbFudge)
					rh:SetDesiredAngle(-desiredAngle)
					lh:SetDesiredAngle(-desiredAngle)
				end
				local tool = getTool()
				if tool and tool:FindFirstChild("Handle") then
					local animStringValueObject = getToolAnim(tool)
					if animStringValueObject then
						toolAnim = animStringValueObject.Value
						animStringValueObject.Parent = nil
						toolAnimTime = time + .3
					end
					if time > toolAnimTime then
						toolAnimTime = 0
						toolAnim = "None"
					end
					animateTool()		
				else
					stopToolAnimations()
					toolAnim = "None"
					toolAnimInstance = nil
					toolAnimTime = 0
				end
			end
		
			rig_hum.Died:Connect(onDied)
			rig_hum.Running:Connect(onRunning)
			rig_hum.Jumping:Connect(onJumping)
			rig_hum.Climbing:Connect(onClimbing)
			rig_hum.GettingUp:Connect(onGettingUp)
			rig_hum.FreeFalling:Connect(onFreeFall)
			rig_hum.FallingDown:Connect(onFallingDown)
			rig_hum.Seated:Connect(onSeated)
			rig_hum.PlatformStanding:Connect(onPlatformStanding)
			rig_hum.Swimming:Connect(onSwimming)
			rbx_signals[#rbx_signals+1] = player.Chatted:Connect(function(msg)
				local emote = ""
				if msg == "/e dance" then
					emote = dances[mt_random(1, #dances)]
				elseif (str_sub(msg, 1, 3) == "/e ") then
					emote = str_sub(msg, 4)
				elseif (str_sub(msg, 1, 7) == "/emote ") then
					emote = str_sub(msg, 8)
				end
				if (pose == "Standing" and emoteNames[emote] ~= nil) then
					playAnimation(emote, 0.1, rig_hum)
				end
			end)
	
			playAnimation("idle", 0.1, rig_hum)
			pose = "Standing"
		
			while rig:IsDescendantOf(game) do
				anims_toggled = (anim_script and anim_script.Parent) and anim_script.Enabled or false
				time = ts_wait(0.1)
				move(time)
			end
		end)
	end
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

	temp = post_sim:Connect(function()
		hrp.AssemblyLinearVelocity = velocity
		hrp.AssemblyAngularVelocity = v3_zero
		hrp.CFrame = fling_part.CFrame * offset
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
	hrp        = wait_for_child_of_class(character, "BasePart", 5, "HumanoidRootPart")
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

	if not tpless then
		hrp.CFrame = tp_offset
		ts_wait(wait_time)	
	end

	descendants = character:GetDescendants()
	disable_localscripts(descendants)

	tb_clear(hats)
	recreate_accessory_and_joints(rig, descendants)

	rig_descendants = rig:GetDescendants()

	humanoid:ChangeState(state_dead)
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
		fling_part.AssemblyLinearVelocity = v3_zero

		if is_mouse_down then
			target = mouse.Target.Parent and mouse.Target.Parent:FindFirstChildOfClass("Part") or mouse.Target.Parent.Parent and mouse.Target.Parent.Parent:FindFirstChildOfClass("Part")
			if target and target.Name == "HumanoidRootPart" or target.Name == "Head" or target.Name == "Handle" then
				targethum = target.Parent:FindFirstChildOfClass("Humanoid") or target.Parent.Parent:FindFirstChildOfClass("Humanoid")

				if targethum and targethum.MoveDirection.Magnitude > 0.25 then
					fling_part.CFrame = target.CFrame * cf_new(targethum.MoveDirection * targethum.WalkSpeed/2)
				else
					fling_part.CFrame = target.CFrame
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
	local rigcf = rig_hrp.CFrame

	disconnect_all_events(rbx_signals)

	rig:Destroy()
	reset_bind:Destroy()

	player.Character = character
	camera.CameraSubject = humanoid
	global.Rig = nil

	startgui:SetCore("ResetButtonCallback", true)
	camera:GetPropertyChangedSignal("CFrame"):Wait()
	camera.CameraSubject = player.Character

	if deathpoint then
		player.CharacterAdded:Wait()
		ts_wait()

		hrp        = wait_for_child_of_class(player.Character, "BasePart", 5, "HumanoidRootPart")
		hrp.CFrame = rigcf
	end
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
