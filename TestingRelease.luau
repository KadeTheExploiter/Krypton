-- TESTING RELEASE, ANY BUG REPORTS ARE APPRECIATED
-- CURRENT RELEASE: 1.7-debug_3


-- \\ Krypton Reanimate, Author: @xyzkade . https://github.com/KadeTheExploiter/Krypton/ // 
-- || Gelatek was there
-- // Defining Variables: Settings

local Global = getgenv and getgenv() or getfenv(0)

if not game.Loaded then
	game.Loaded:Wait()
end 

Config = Global.Configuration or {
	ReturnOnDeath = true,
	Flinging = true,
	SetCharacter = false,
	PresetFling = true, -- if set to false, KadeAPI.CallFling() won't do anything.
	Animations = true,
	WaitTime = -0.251,
	TeleportOffsetRadius = 20,
	NoCollisions = true,
	AntiVoiding = true,
	SetSimulationRadius = true,
	DisableCharacterScripts = true,
	AccessoryFallbackDefaults = true,
	OverlayFakeCharacter = false,
	NoBodyNearby = true,
	LimitHatsPerLimb = true,
	ShowClientHats = true,
	IgnoreKadeAPI = false,
	
	Hats = nil, -- Set to nil if you want to use defaults.
}

local RigName = Config.RigName or "Evolution, it must've passed you by."

local WaitTime = Config.WaitTime or 0.25
local TeleportOffsetRadius = Config.TeleportOffsetRadius or 12

local Flinging = Config.Flinging or nil
local PresetFling = Flinging and Config.PresetFling or nil

local Animations = Config.Animations or nil
local AntiVoiding = Config.AntiVoiding or nil
local SetCharacter = Config.SetCharacter or nil
local NoBodyNearby = Config.NoBodyNearby or nil -- Recommended to have setsimulationradius enabled!
local IgnoreKadeAPI = Config.IgnoreKadeAPI or nil
local ReturnOnDeath = Config.ReturnOnDeath or nil
local ShowClientHats = Config.ShowClientHats or nil
local ForceMobileMode = Config.ForceMobileMode or nil
local ForceDesktopMode = Config.ForceDesktopMode or nil
local LimitHatsPerLimb = Config.LimitHatsPerLimb or nil
local NoCollisions = Config.NoCollisions or Flinging or nil
local SetSimulationRadius = Config.SetSimulationRadius or nil
local OverlayFakeCharacter = Config.OverlayFakeCharacter or nil
local DisableCharacterScripts = Config.DisableCharacterScripts or nil
local AccessoryFallbackDefaults = Config.AccessoryFallbackDefaults or nil

local DefaultHats = {
	["Right Arm"] = {
		{Texture = "14255544465", Mesh = "14255522247", Name = "RARM", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "4645402630", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(90))}
	},

	["Left Arm"] = {
		{Texture = "14255544465", Mesh = "14255522247", Name = "LARM", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "3650139425", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(-90))}
	},

	["Right Leg"] = {
		{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (RARM)", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "4622077774", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(90))}
	},

	["Left Leg"] = {
		{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (LARM)", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "3860099469", Mesh = "3030546036", Name = "InternationalFedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(-90))}
	},	

	["Torso"] = {
		{Texture = "13415110780", Mesh = "13421774668", Name = "MeshPartAccessory", Offset = CFrame.identity},
		{Texture = "4819722776", Mesh = "4819720316", Name = "MeshPartAccessory", Offset = CFrame.Angles(0, 0, math.rad(-15))}
	},
}

-- namecalls sucks
local Hats = Config.Hats or DefaultHats

local IsA = game.IsA
local FindFirstChildOfClass = game.FindFirstChildOfClass
local FindFirstChild = game.FindFirstChild
local WaitForChild = game.WaitForChild
local GetChildren = game.GetChildren
local GetDescendants = game.GetDescendants

local function ForceSetProperty(Instance, Property, Value) -- <Instance | Table> <String>, <Any> : nil
	if Instance and Instance.Parent then
		return pcall(function()
			Instance[Property] = Value
		end)
	end
end

local function GetInstanceWithTime(Parent, Class, Name, Timeout)  -- <Any> <String> <String> <Number> : Instance
	local CurTime = 0

	while Timeout > CurTime do
		for _, v in GetChildren(Parent) do
			if IsA(v, Class) and (not Name or v.Name == Name) then
				return v
			end
		end

		CurTime += task.wait()
	end
end

local Workspace = FindFirstChildOfClass(game, "Workspace") -- getservice not needed as they are preloaded servies
local Players = FindFirstChildOfClass(game, "Players")
local RunService = FindFirstChildOfClass(game, "RunService")
local StarterGui = FindFirstChildOfClass(game, "StarterGui")
local UserInputService = FindFirstChildOfClass(game, "UserInputService")

local Camera = Workspace.CurrentCamera
local PreviousCameraCFrame = Camera.CFrame

local HSWait = RunService.PostSimulation.Wait
local PSWait = RunService.PreSimulation.Wait
local CamCustomType = Enum.CameraType.Custom

local IsMobile = ForceMobileMode or UserInputService.TouchEnabled
local IsKeyboard = ForceDesktopMode or UserInputService.KeyboardEnabled

local Terrain = GetInstanceWithTime(Workspace, "Terrain", "Terrain", 3)

if FindFirstChild(Terrain, RigName) then
	return
end

local RespawnEvent = Instance.new("BindableEvent")

local TeleportOffset = Vector3.zero
local ReverseSleep = TeleportOffset
local SafeYAxis = 35

local DefaultAccessoryPart1 = nil
local CameraHandle = nil
local MouseDown = nil
local SpaceDown = nil

local KeyInputs = {[Enum.KeyCode.W] = {nil, 0, -1}, [Enum.KeyCode.A] = {nil, -1, 0}, [Enum.KeyCode.S] = {nil, 0, 1}, [Enum.KeyCode.D] = {nil, 1, 0}}
local HatsWithDifferentAligns = {}
local FlingableTargets = {}
local TempSignals = {}
local RBXSignals = {}
local HatsInUse = {}
local Blacklist = {}

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Character = Player.Character or Player.CharacterAdded:Wait() and Player.Character
local LastCharacter = Character

local Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
local RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)
local Descendants = GetDescendants(Character)

local CFrameBackup = AntiVoiding and RootPart.CFrame
local FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight + 75
local CanCallSimRadius = SetSimulationRadius and ForceSetProperty(Player, "SimulationRadius", 1000)

ForceSetProperty(Workspace, "StreamingEnabled", false)

-- // RunTime: Creating FakeRig

local FakeRig = Instance.new("Model")
local FakeHumanoid = Instance.new("Humanoid")
local FakeRigChildren = {}
local FakeRoot = nil

local function CancelScript()  -- : nil
	local Pos = FakeRoot.CFrame

	CameraHandle:Disconnect()

	for _, Signal in RBXSignals do
		Signal:Disconnect()
	end

	StarterGui:SetCore("ResetButtonCallback", true)
	Camera.CameraSubject = Character
	FakeRig:Destroy()

	-- Free the memory after use.

	table.clear(Hats)
	table.clear(HatsInUse)
	table.clear(RBXSignals)
	table.clear(FakeRigChildren)
	table.clear(KeyInputs)
	table.clear(HatsWithDifferentAligns)
	table.clear(FlingableTargets)
	table.clear(TempSignals)
	table.clear(DefaultHats)
	table.clear(Descendants)

	if typeof(Global.KadeAPI) == "table" then
		table.clear(Global.KadeAPI)
		Global.KadeAPI = nil
	end

	if ReturnOnDeath then
		local Target = Player.CharacterAdded:Wait()
		local Root = GetInstanceWithTime(Target, "Part", "HumanoidRootPart", 3)

		if Root then
			Root.CFrame = Pos
		end
	end
end

do -- [[ Scoped Rig Creating. ]]
	local HumanoidDesc = Instance.new("HumanoidDescription")
	local Animator = Instance.new("Animator")
	local Animate = Instance.new("LocalScript")

	local function MakeMotor6D(Name, Part0, Part1, C0, C1)
		local Joint = Instance.new("Motor6D")

		Joint.Name = Name
		Joint.Part0 = Part0
		Joint.Part1 = Part1
		Joint.C0 = C0
		Joint.C1 = C1

		Joint.Parent = Part0

		return Joint
	end

	local function MakeAttachment(Name, CFrame, Parent)
		local Attachment = Instance.new("Attachment")

		Attachment.Name = Name
		Attachment.CFrame = CFrame
		Attachment.Parent = Parent
	end

	local Torso = Instance.new("Part")
	local RightArm = Instance.new("Part")
	local Head = Instance.new("Part")
	DefaultAccessoryPart1 = Head
	
	Head.Size = Vector3.new(2,1,1)
	Torso.Size = Vector3.new(2,2,1)
	RightArm.Size = Vector3.new(1,2,1)

	local Transparency = OverlayFakeCharacter and 0.5 or 1
	Head.Transparency = Transparency
	Torso.Transparency = Transparency
	RightArm.Transparency = Transparency

	FakeRoot = Torso:Clone()
	FakeRoot.CanCollide = nil

	local LeftArm = RightArm:Clone()
	local RightLeg = RightArm:Clone()
	local LeftLeg = RightArm:Clone()

	FakeRoot.Name = "HumanoidRootPart"
	Torso.Name = "Torso"
	Head.Name = "Head"
	RightArm.Name = "Right Arm"
	LeftArm.Name = "Left Arm"
	RightLeg.Name = "Right Leg"
	LeftLeg.Name = "Left Leg"

	Animator.Parent = FakeHumanoid
	HumanoidDesc.Parent = FakeHumanoid

	FakeHumanoid.Parent = FakeRig
	FakeRoot.Parent = FakeRig
	Head.Parent = FakeRig

	Torso.Parent = FakeRig
	RightArm.Parent = FakeRig
	LeftArm.Parent = FakeRig
	RightLeg.Parent = FakeRig
	LeftLeg.Parent = FakeRig
	FakeHumanoid.Parent = FakeRig

	MakeMotor6D('Neck', Torso, Head, CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	MakeMotor6D('RootJoint', FakeRoot, Torso, CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0), CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
	local RightShoulder = MakeMotor6D('Right Shoulder', Torso, RightArm, CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	local LeftShoulder = MakeMotor6D('Left Shoulder', Torso, LeftArm, CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	local RightHip = MakeMotor6D('Right Hip', Torso, RightLeg, CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
	local LeftHip = MakeMotor6D('Left Hip', Torso, LeftLeg, CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	Animate.Name = "Animate"
	Animate.Parent = FakeRig

	FakeRoot.CFrame = RootPart.CFrame * CFrame.new(0, 0.1, 0)
	FakeRig.Name = RigName
	FakeRig.PrimaryPart = Head

	FakeRig.Parent = Terrain

	FakeHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	FakeHumanoid:ChangeState(Enum.HumanoidStateType.Landed)

	if AccessoryFallbackDefaults then
		local Types = {Name = "string", Texture = "string", Mesh = "string", Offset = "CFrame"}

		for Name, Data in DefaultHats do
			local HatsData = Hats[Name]
			local Flagged = nil

			if HatsData and typeof(HatsData) == "table"  then
				for _, Hat in ipairs(HatsData) do
					for Key, Type in Types do
						if typeof(Hat[Key]) ~= Type then
							Flagged = true
							break
						end
					end
				end
			else
				Flagged = true
			end

			if Flagged then
				Hats[Name] = table.clone(Data)
			end
		end
	end

	local Attachments = {
		HairAttachment = {CFrame.new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head},
		HatAttachment = {CFrame.new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head},
		FaceFrontAttachment = {CFrame.new(0, 0, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head},
		RootAttachment = {CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FakeRoot},
		LeftShoulderAttachment = {CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftArm},
		LeftGripAttachment = {CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftArm},
		RightShoulderAttachment = {CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightArm},
		RightGripAttachment = {CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightArm},
		LeftFootAttachment = {CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftLeg},
		RightFootAttachment = {CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightLeg},
		NeckAttachment = {CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso},
		BodyFrontAttachment = {CFrame.new(0, 0, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso},
		BodyBackAttachment = {CFrame.new(0, 0, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso},
		LeftCollarAttachment = {CFrame.new(-1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso},
		RightCollarAttachment = {CFrame.new(1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso},
		WaistFrontAttachment = {CFrame.new(0, -1, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso},
		WaistCenterAttachment = {CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso},
		WaistBackAttachment = {CFrame.new(0, -1, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso}
	}

	for Name, Table in Attachments do
		MakeAttachment(Name, Table[1], Table[2])
	end

	table.clear(Attachments)

	if Animations then
		task.delay(1, function()
			local AnimationsToggled = true

			local Pose = "Standing"
			local CurrentAnim, CurrentAnimInstance, CurrentAnimTrack, CurrentAnimKeyframeHandler = "", nil, nil, nil
			local CurrentAnimSpeed, JumpAnimTime = 0, 0

			local Dances = {"dance1", "dance2", "dance3"}
			local EmoteNames = {wave = nil, point = nil, dance1 = true, dance2 = true, dance3 = true, laugh = nil, cheer = nil}

			local AnimationTable = {}
			local AnimData = {
				-- Movement Anims
				Idle = "http://www.roblox.com/asset/?id=180435571", Walk = "http://www.roblox.com/asset/?id=180426354", Run = "Run.xml", Jump = "http://www.roblox.com/asset/?id=125750702", Fall = "http://www.roblox.com/asset/?id=180436148", Climb = "http://www.roblox.com/asset/?id=180436334", Sit = "http://www.roblox.com/asset/?id=178130996",
				-- Animations
				dance1 = "http://www.roblox.com/asset/?id=182435998", dance2 = "http://www.roblox.com/asset/?id=182436842", dance3 = "http://www.roblox.com/asset/?id=182436935", wave = "http://www.roblox.com/asset/?id=128777973", point = "http://www.roblox.com/asset/?dan=128853357", laugh = "http://www.roblox.com/asset/?id=129423131", cheer = "http://www.roblox.com/asset/?id=129423030"
			}

			for Name, Id in AnimData do
				local Animation = Instance.new("Animation")
				Animation.AnimationId = Id
				AnimationTable[Name] = Animation
			end

			local function PlayAnimation(AnimName, TransitionTime)
				local Anim = AnimationTable[AnimName]

				if Anim ~= CurrentAnimInstance then
					if CurrentAnimTrack then
						CurrentAnimTrack:Stop(TransitionTime)
						CurrentAnimTrack:Destroy()
					end

					CurrentAnimSpeed = 1.0
					CurrentAnimTrack = FakeHumanoid:LoadAnimation(Anim)
					CurrentAnimTrack.Priority = Enum.AnimationPriority.Core
					CurrentAnimTrack:Play(TransitionTime)

					CurrentAnim, CurrentAnimInstance = AnimName, Anim

					if CurrentAnimKeyframeHandler then
						CurrentAnimKeyframeHandler:Disconnect()
					end

					CurrentAnimKeyframeHandler = CurrentAnimTrack.KeyframeReached:Connect(function(FrameName)
						if FrameName == "End" and EmoteNames[CurrentAnim] then
							PlayAnimation("Idle", 0.1)
						end
					end)
				end
			end

			local function SetAnimationSpeed(Speed)
				if Speed ~= CurrentAnimSpeed then
					CurrentAnimSpeed = Speed
					if CurrentAnimTrack then
						CurrentAnimTrack:AdjustSpeed(Speed)
					end
				end
			end

			local EventHandlers = {
				Died = function() 
					Pose = "Dead" 
				end,

				Seated = function() 
					Pose = "Seated" 
				end,

				PlatformStanding = function() 
					Pose = "PlatformStanding" 
				end,

				Running = function(Speed)
					if Speed > 0.01 then
						PlayAnimation("Walk", 0.1)
						SetAnimationSpeed(Speed / 14.5)
						Pose = "Running"
					else
						PlayAnimation("Idle", 0.1)
						Pose = "Standing"
					end
				end,

				Jumping = function()
					PlayAnimation("Jump", 0.1)
					JumpAnimTime = 0.3
					Pose = "Jumping"
				end,

				Climbing = function(Speed)
					PlayAnimation("Climb", 0.1)
					SetAnimationSpeed(Speed / 12.0)
					Pose = "Climbing"
				end,

				FreeFalling = function()
					if JumpAnimTime <= 0 then
						PlayAnimation("Fall", 0.3)
					end

					Pose = "FreeFall"
				end
			}

			for EventName, Handler in EventHandlers do
				FakeHumanoid[EventName]:Connect(function(...)
					if AnimationsToggled then 
						Handler(...) 
					end
				end)
			end

			table.insert(RBXSignals, RunService.PostSimulation:Connect(function(DeltaTime)
				AnimationsToggled = Animate and Animate.Parent and Animate.Enabled
				JumpAnimTime = math.max(0, JumpAnimTime - DeltaTime)
			end))
			
			table.insert(RBXSignals, Player.Chatted:Connect(function(Message)
				local Context = Message and string.lower(Message)
				if AnimationsToggled and Context then
					PlayAnimation(Context, 0.1)
				end
			end))
			
			table.clear(AnimData)
		end)
	end
end


-- // RunTime: Functions


local function ExtractNumbers(String) -- <String> : string
	return string.match(String, "%d+")
end

local function Decollide(Part) -- <Part> : nil
	Part.CanCollide = false
	Part.CanTouch = false
	Part.CanQuery = false
end

local function GetFirstPart(Parent) -- <Any> : Part | BasePart
	return FindFirstChildOfClass(Parent, "Part") or WaitForChild(Parent, "Handle", 1)
end

local function GetFirstWeld(Parent) -- <Any> :  Weld | ManualWeld
	return FindFirstChild(Parent, "AccessoryWeld") or FindFirstChildOfClass(Parent, "Weld")
end

local function DestroyWeld(Parent) -- <Instance>
	local Weld = GetFirstWeld(Parent)

	if Weld then
		Weld:Destroy()
	end
end

local function ObtainMeshAndTextureOfAccessory(Accessory) -- <Accessory> : {MeshId: string, TextureId: string}
	local Handle = FindFirstChild(Accessory, "Handle")
	local IfMesh = FindFirstChildOfClass(Handle, "SpecialMesh")

	if IsA(Handle, "MeshPart") then
		return {MeshId = Handle.MeshId, TextureId = Handle.TextureID}

	elseif IfMesh then
		return {MeshId = IfMesh.MeshId, TextureId = IfMesh.TextureId}
	end
end

local function FindAccessory(FromWhere, Texture, Mesh, Name) -- <Instance> <string> <string> <string> : Accessory
	local InputMeshNumber = ExtractNumbers(Mesh)
	local InputTextureNumber = ExtractNumbers(Texture)
	
	for _, Accessory in GetChildren(FromWhere) do
		if IsA(Accessory, "Accessory") and Accessory.Name == Name then
			local HatData = ObtainMeshAndTextureOfAccessory(Accessory)

			if HatData then
				local MeshNumber = ExtractNumbers(HatData.MeshId)
				local TextureNumber = ExtractNumbers(HatData.TextureId)

				if MeshNumber == InputMeshNumber and TextureNumber == InputTextureNumber then
					return Accessory
				end
			end
		end
	end
end

local function RecreateAccessory(Accessory) -- <Accessory> : Accessory
	local FakeAccessory = Accessory:Clone()
	local FakeHandle = GetFirstPart(FakeAccessory)

	FakeHandle.Transparency = 1

	local FakeAttachment = FindFirstChildOfClass(FakeHandle, "Attachment")
	local RigAttachment = FakeAttachment and FindFirstChild(FakeRig, FakeAttachment.Name or "", true)

	local Weld = Instance.new("Weld")

	Weld.Name = "AccessoryWeld"
	Weld.Part0 = FakeHandle
	Weld.C0 = FakeAttachment and FakeAttachment.CFrame or CFrame.identity

	DestroyWeld(FakeHandle)

	if RigAttachment then
		Weld.C1 = RigAttachment.CFrame
		Weld.Part1 = RigAttachment.Parent
	else
		Weld.Part1 = DefaultAccessoryPart1
	end

	Weld.Parent = FakeHandle
	FakeAccessory.Parent = FakeRig

	return FakeAccessory
end

local function ProcessAccessory(Accessory, Function) -- <Accessory> <function> : BasePart 
	if not Accessory or table.find(Blacklist, Accessory) then
		return
	end
	
	table.insert(Blacklist, Accessory)

	local Handle = GetFirstPart(Accessory)

	if Handle and not HatsInUse[Handle] then
		Function(Handle)
	end
end

local function SetUpHatConfig() -- : nil
	for _, Hat in GetDescendants(FakeRig) do
		if IsA(Hat, "Accessory") then
			Hat:Destroy()
		end
	end

	for _, Value in HatsWithDifferentAligns do
		local Accessory = FindAccessory(Character, Value[1], Value[2], Value[3]) 

		ProcessAccessory(Accessory, function(Handle)
			local Part1 = Value[4]

			if Part1 and Part1.Parent then
				HatsInUse[Handle] = {Part1, Value[5] or CFrame.identity}
			end
		end)
	end

	for Index, Data in Hats do
		for _, Info in Data do
			local Accessory = FindAccessory(Character, Info.Texture, Info.Mesh, Info.Name)
			
			ProcessAccessory(Accessory, function(Handle)
				HatsInUse[Handle] = {FindFirstChild(FakeRig, Index), Info.Offset}
			end)
			
			if LimitHatsPerLimb then
				continue
			end
		end
	end

	for _, Accessory in GetChildren(Character) do
		if IsA(Accessory, "Accessory") then
			ProcessAccessory(Accessory, function(Handle)			
				local FakeAccessory = RecreateAccessory(Accessory)
				HatsInUse[Handle] = {GetFirstPart(FakeAccessory), CFrame.identity}
			end)
		end
	end
end

local function ConnectHats(Part0, Part1, Offset) -- : nil
	if Part0 and Part1 and Part0.Parent and Part1.Parent and Part0.ReceiveAge == 0 then
		if ShowClientHats then
			Part1.Transparency = 1
		end
		
		local Part1Magnitude = Part1.Size.Magnitude
		local Part1Velocity = Part1.AssemblyLinearVelocity * Part1Magnitude
		local CalculatedVel = Part1Velocity * 2.5

		local ClampedAxisY = math.clamp(Part1Velocity.Y, SafeYAxis, 512)
		local Velocity = Vector3.new(CalculatedVel.X, ClampedAxisY, CalculatedVel.Z)

		local CFrameOffset = Part1.CFrame * Offset
		
		Part0.AssemblyLinearVelocity = Velocity
		Part0.AssemblyAngularVelocity = Part1.AssemblyAngularVelocity
		Part0.CFrame = CFrameOffset + ReverseSleep
		
	elseif ShowClientHats then
		Part1.Transparency = 0.5
	end
end

local function GetRandomRadius() -- : Vector3
	return Vector3.new(math.random(-TeleportOffsetRadius, TeleportOffsetRadius), 0.5, math.random(-TeleportOffsetRadius, TeleportOffsetRadius))
end

local function ArePlayersNearby() -- : Boolean
	local Output = nil

	for _, Part in Workspace:GetPartBoundsInRadius(TeleportOffset, 10) do
		local Model = Part.Parent

		if IsA(Model, "Model") then
			if FindFirstChildOfClass(Model, "Humanoid") and not (Model == Character and Model == FakeRig) then
				Output = true 
			end
		end
	end

	return Output
end

local function FlingModels() -- : nil
	for _, Model in FlingableTargets do
		local PrimaryPart = Model.PrimaryPart

		if PrimaryPart then
			for _ = 1, 16 do
				RootPart.CFrame = CFrame.new(PrimaryPart.Position + PrimaryPart.AssemblyLinearVelocity * Player:GetNetworkPing()*30)
				RootPart.AssemblyLinearVelocity = Vector3.new(16000, 16000, 16000)

				if PrimaryPart.AssemblyAngularVelocity.Magnitude > 75 then
					break
				end

				HSWait()
			end
		end
	end

	table.clear(FlingableTargets)
end

local function BringCharacter() -- : nil
	local Time = 0

	while WaitTime > Time do
		if RootPart then
			RootPart.AssemblyLinearVelocity = Vector3.zero
			RootPart.AssemblyAngularVelocity = Vector3.zero
			RootPart.CFrame = CFrame.new(TeleportOffset)
		end

		Time += RunService.PostSimulation:Wait()
	end
end

-- // RunTime: Event functions

local function UpdateCameraCFrame() -- Function | SIGNAL: Camera:GetPropertySignalChanged("CameraSubject")
	PreviousCameraCFrame = Camera.CFrame
		
	RunService.PreRender:Wait()
	Camera.CFrame = PreviousCameraCFrame
end

local function OnInputChange(Input, GameProcessed, Bool) -- SIGNAL: UIS.InputBegan | UIS.InputEnded
	if GameProcessed then
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			MouseDown = Bool
		end

		if Input.KeyCode == Enum.KeyCode.Space then
			SpaceDown = Bool
		end

		for MyInput, Table in KeyInputs do
			if Input.KeyCode == MyInput then
				Table[1] = Bool
			end
		end
	end
end

local function OnPresetFlingEnabled() -- SIGNAL: RunService.PostSimulation [Required: Flinging = true]
	if not MouseDown then return end

	local Target = Mouse.Target
	local TargetParent = Target and Target.Parent
	local TargetDescendant = TargetParent and TargetParent.Parent
	local NewTarget = FindFirstChildOfClass(TargetParent, "Humanoid") or FindFirstChildOfClass(TargetDescendant, "Humanoid")

	local HitCalciulation = CFrame.new(Mouse.Hit.Position)

	if NewTarget then
		local Part = GetFirstPart(NewTarget.Parent)

		if Part then
			RootPart.CFrame = CFrame.new(Part.Position + Part.AssemblyLinearVelocity * Player:GetNetworkPing())
		else
			RootPart.CFrame = HitCalciulation
		end

		RootPart.AssemblyLinearVelocity = Vector3.new(4096, 4096, 4096)
	else
		RootPart.CFrame = HitCalciulation
		RootPart.AssemblyLinearVelocity = Vector3.zero
	end
end

local function OnPostSimulation() -- SIGNAL: RunService.PostSimulation
	StarterGui:SetCore("ResetButtonCallback", RespawnEvent)

	ReverseSleep = Vector3.new(0.0075 * math.sin(os.clock() * 7), 0, 0.0065 * math.cos(os.clock() * 3))
	SafeYAxis = 35 - 3 * math.sin(os.clock() * 10)

	for Handle, Data in HatsInUse do
		ConnectHats(Handle, Data[1], Data[2])
	end

	if AntiVoiding and FakeRoot.Position.Y < FallenPartsDestroyHeight then
		FakeRoot.CFrame = CFrameBackup
		FakeRoot.AssemblyLinearVelocity = Vector3.zero
		FakeRoot.AssemblyAngularVelocity = Vector3.zero
	end
end


local function OnPreRender() -- SIGNAL: RunService.PreSimulation
	if Camera then
		if Camera.CameraSubject ~= FakeHumanoid then
			Camera.CameraSubject = FakeHumanoid	
		end

		if Camera.CameraType ~= CamCustomType then
			Camera.CameraSubject = CamCustomType	
		end
	end
end

local function OnPreSimulation() -- SIGNAL: RunService.PreSimulation
	if CanCallSimRadius then
		Player.SimulationRadius = 1000
	end

	for _, Part in Descendants do
		if IsA(Part, "BasePart") then
			Decollide(Part)
		end
	end

	if NoCollisions then
		for _, Part in FakeRigChildren do
			if IsA(Part, "BasePart") then
				Decollide(Part)
			end
		end
	end

	if IsKeyboard then
		local Shiftlock = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
		local MovementVector = Vector3.zero

		FakeHumanoid.AutoRotate = not Shiftlock
		FakeHumanoid.Jump = SpaceDown

		for _, Table in KeyInputs do
			if Table[1] then
				local X, Z = MovementVector.X, MovementVector.Z

				MovementVector = Vector3.new(X + Table[2], 0, Z + Table[3])
			end
		end

		if Shiftlock then
			local LookVector = Camera.CFrame.LookVector

			FakeRoot.CFrame = CFrame.new(FakeRoot.Position) * CFrame.Angles(0, math.atan2(-LookVector.X, -LookVector.Z), 0)
		end

		FakeHumanoid:Move(MovementVector, true)
	end
	-- Not doing an elseif check due to compatibility issues.
	if IsMobile then
		-- For some reason the movement does not seem to work well as expected, we are returning to more ancient methods.
		FakeHumanoid.Jump = Humanoid.Jump
		FakeHumanoid:Move(Humanoid.MoveDirection)
	end
end

local function OnCharacterAdded(NewCharacter) -- SIGNAL : Player.CharacterAdded
	UpdateCameraCFrame()
	
	if NewCharacter ~= FakeRig then
		Character = NewCharacter
		
		table.clear(HatsInUse)
		table.clear(Descendants)
		table.clear(FakeRigChildren)
		table.clear(Blacklist)
		
		print(Character.Name); warn(LastCharacter.Name)
		LastCharacter = Character

		Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
		RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)
		
		if Humanoid and RootPart then
			ForceSetProperty(FindFirstChild(FakeRoot, "Died"), "Volume", 0)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			
			TeleportOffset = FakeRoot.Position + GetRandomRadius() + Vector3.new(0, NoBodyNearby and FallenPartsDestroyHeight + 15 or 0, 0)
			
			while ArePlayersNearby() do
				TeleportOffset = FakeRoot.Position + GetRandomRadius() + Vector3.new(0, NoBodyNearby and FallenPartsDestroyHeight + 15 or 0, 0)
				task.wait()
			end

			if DisableCharacterScripts then
				for _, Script in Descendants do
					if IsA(Script, "LocalScript") then
						Script.Disabled = true
					end
				end
			end

			if Flinging then
				if PresetFling then
					local TemporarySignal = RunService.PostSimulation:Connect(OnPresetFlingEnabled)

					repeat task.wait() until not MouseDown

					TemporarySignal:Disconnect()
					TemporarySignal = nil
				else
					FlingModels()
				end
			end

			task.defer(function()
				BringCharacter()

				Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				Character:BreakJoints()
				
				task.wait(0.125)
				
				Descendants = GetDescendants(Character)
				SetUpHatConfig()
				
				if SetCharacter then
					PSWait()
					Player.Character = FakeRig
				end
			end)
			
			FakeRigChildren = GetChildren(FakeRig)
		end
	end
end


local function UponParentChange() -- SIGNAL: FakeRig:GetPropertyChangedSignal("Parent")
	if not FakeRig:IsDescendantOf(Workspace) then
		CancelScript()
	end
end

local function UponCameraChange(NewCamera) -- SIGNAL: Workspace:GetPropertyChangedSignal("CurrentCamera")
	CameraHandle:Disconnect()	

	Camera = NewCamera
	CameraHandle = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(UpdateCameraCFrame)
end

-- // Finalizing: Connecting Events

UpdateCameraCFrame()
SetUpHatConfig()

ForceSetProperty(FindFirstChild(FakeRoot, "Died"), "Volume", 0)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

table.insert(RBXSignals, Player.CharacterAdded:Connect(OnCharacterAdded))
table.insert(RBXSignals, RunService.PostSimulation:Connect(OnPostSimulation))
table.insert(RBXSignals, RunService.PreSimulation:Connect(OnPreSimulation))
table.insert(RBXSignals, RunService.PreRender:Connect(OnPreRender))
table.insert(RBXSignals, FakeRoot:GetPropertyChangedSignal("Parent"):Connect(UponParentChange))
table.insert(RBXSignals, RespawnEvent.Event:Connect(CancelScript))
table.insert(RBXSignals, UserInputService.InputBegan:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, true) end))
table.insert(RBXSignals, UserInputService.InputEnded:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, nil) end))
CameraHandle = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(UpdateCameraCFrame)

if SetCharacter then
	Player.Character = FakeRig
end

FakeRigChildren = GetChildren(FakeRig)

local function KadeAPI_Init()
	return {
		GetCharacter = function() -- Returns FakeRig Model, needed for scripts.
			return FakeRig
		end,

		GetHumanoid = function() -- Returns GetHumanoid
			return FakeHumanoid
		end,

		GetRootPart = function() -- Returns HumanoidRootPart
			return FakeRoot
		end,

		GetHatInformation = function(Hat) -- Returns HumanoidRootPart
			local HatInfo = ObtainMeshAndTextureOfAccessory(Hat)
			HatInfo.Name = Hat.Name

			return HatInfo
		end,

		GetRealCharacter = function(Name) -- Returns RealRig Model, needed for scripts.
			repeat task.wait() until Player.Character

			return Player.Character
		end,

		SetHatAlign = function(HatInformation, Part1, Offset) -- Aligns Hat.
			assert(typeof(HatInformation) == "table",  "HatInformation is not an table.")
			assert(Part1 and Part1:IsA("BasePart"), "Part1 is not a part.")
			assert(typeof(Offset) == "CFrame", "Offset is not a part.")

			local TextureId = HatInformation.TextureId
			local MeshId = HatInformation.MeshId
			local Name = HatInformation.Name

			local Accessory = nil
			local Timeout = 3
			local Current = 0

			while not Accessory and Timeout > Current do
				Accessory = FindAccessory(Player.Character, TextureId, MeshId, Name)

				Current += task.wait()
			end

			if not Accessory then
				error("Accessory has not been found in Character.")
			end

			local Handle = GetFirstPart(Accessory)

			if Handle then
				local Dictionary = table.find(HatsInUse, Handle)
				table.remove(HatsInUse, Dictionary)

				table.insert(HatsWithDifferentAligns, {TextureId, MeshId, Name, Part1, Offset})
				HatsInUse[Handle] = {Part1, Offset}
			end
		end,

		DisconnectHatAlign = function(HatInformation) -- Disconnects hat
			assert(typeof(HatInformation) == "table",  "HatInformation is not an table.")

			local Accessory = nil
			local Timeout = 3
			local Current = 0

			while not Accessory and Timeout > Current do
				Accessory = FindAccessory(Character, HatInformation.TextureId, HatInformation.MeshId, HatInformation.Name)

				Current += task.wait()
			end

			if not Accessory then
				error("Accessory has not been found in Character.")
			end

			local Handle = GetFirstPart(Accessory)

			for Table, Value in HatsWithDifferentAligns do
				local UsedAccessory = FindAccessory(Character, Value[1], Value[2], Value[3]) 

				if UsedAccessory and UsedAccessory == Accessory then
					local UsedHandle = GetFirstPart(UsedAccessory)

					local Dictionary = table.find(HatsInUse, UsedHandle)
					table.remove(HatsInUse, Dictionary)

					local Dictionary2 = table.find(HatsWithDifferentAligns, Table) -- seems ugly but idc
					table.remove(HatsWithDifferentAligns, Dictionary)

					if UsedHandle then
						local FakeAccessory = RecreateAccessory(UsedAccessory)

						if FakeAccessory then
							HatsInUse[UsedHandle] = {GetFirstPart(FakeAccessory), CFrame.identity}
						end
					end
				end
			end
		end,

		SWait = PSWait, -- Stepped Wait

		SetAnimationState = function(Status) -- Stops Animations
			local Animator = FindFirstChildOfClass(FakeHumanoid, "Animator")
			local Animate = FindFirstChild(FakeRig, "Animate")

			if Animate then
				Animate.Disabled = not Status
			end

			if not Status and Animator then
				for _, Track in Animator:GetPlayingAnimationTracks() do
					Track:Stop()
				end
			end
		end,

		GetLoadLibrary = function()
			-- loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Uncategorized-Scripts/main/LoadLib.lua"))()
		end,

		CallFling = function(Model)
			assert(IsA(Model, "Model"), "Not a Model.")

			if Model ~= Character and Model ~= FakeRig then
				table.insert(FlingableTargets, Model)
			end
		end,

		CreateTempSignal = function(Signal)
			table.insert(TempSignals, Signal)
		end,

		DisconnectTempSignals = function()
			for _, Signal in TempSignals do
				Signal:Disconnect()
			end
		end
	}
end

if not IgnoreKadeAPI then
	Global.KadeAPI = KadeAPI_Init()
end

-- Start

local MainModule = KadeAPI_Init()
local Character = MainModule.GetCharacter()
