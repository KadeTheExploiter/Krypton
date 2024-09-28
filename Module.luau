-- \\ Krypton Reanimate, Author: @xyzkade . https://github.com/KadeTheExploiter/Krypton/ // 
-- || Gelatek was there
-- // Defining Variables: Settings

local Global = getgenv()

if not game.Loaded then
	game.Loaded:Wait()
end 

local RigName = Configuration.RigName or "Evolution, it must've passed you by."

local WaitTime = Configuration.WaitTime or 0.25
local TeleportOffsetRadius = Configuration.TeleportOffsetRadius or 12

local Flinging = Configuration.Flinging or true
local PresetFling = Flinging and Configuration.PresetFling or nil

local Animations = Configuration.Animations or true
local AntiVoiding = Configuration.AntiVoiding or nil
local ReturnOnDeath = Configuration.ReturnOnDeath or nil
local ForceMobileMode = Configuration.ForceMobileMode or nil
local ForceDesktopMode = Configuration.ForceDesktopMode or nil
local NoCollisions = Configuration.NoCollisions or Flinging or nil
local SetSimulationRadius = Configuration.SetSimulationRadius or true
local OverlayFakeCharacter = Configuration.OverlayFakeCharacter or nil
local DisableCharacterScripts = Configuration.DisableCharacterScripts or true
local AccessoryFallbackDefaults = Configuration.AccessoryFallbackDefaults or true

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
local Hats = Configuration.Hats or DefaultHats

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

local CameraHandle = nil
local MouseDown = nil
local SpaceDown = nil
local AnimationHandlingFunction = nil

local KeyInputs = {[Enum.KeyCode.W] = {nil, 0, -1}, [Enum.KeyCode.A] = {nil, -1, 0}, [Enum.KeyCode.S] = {nil, 0, 1}, [Enum.KeyCode.D] = {nil, 1, 0}}
local HatsWithDifferentAligns = {}
local FlingableTargets = {}
local TempSignals = {}
local RBXSignals = {}
local HatsInUse = {}

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
		for Name, Data in DefaultHats do
			local HatsData = Hats[Name]
			local Flagged = nil

			if HatsData then
				if typeof(HatsData) == "table" then
					for _, Hat in ipairs(HatsData) do
						local Types = {Name = "string", Texture = "string", Mesh = "string", Offset = "CFrame"}

						for Key, Type in Types do
							if typeof(Hat[Key]) ~= Type then
								Flagged = true
							end
						end
					end
				else
					Flagged = true
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
			local CurrentAnim = ""

			local CurrentAnimInstance = nil
			local CurrentAnimTrack = nil
			local CurrentAnimKeyframeHandler = nil

			local Dances = {"dance1", "dance2", "dance3"}
			local EmoteNames = {wave = nil, point = nil, dance1 = true, dance2 = true, dance3 = true, laugh = nil, cheer = nil}

			local AnimationTable = {}
			local AnimData = {
				-- Movement Anims
				Idle = "http://www.roblox.com/asset/?id=180435571", Walk = "http://www.roblox.com/asset/?id=180426354", Run = "Run.xml", Jump = "http://www.roblox.com/asset/?id=125750702", Fall = "http://www.roblox.com/asset/?id=180436148", Climb = "http://www.roblox.com/asset/?id=180436334", Sit = "http://www.roblox.com/asset/?id=178130996",
				-- Animations
				dance1 = "http://www.roblox.com/asset/?id=182435998", dance2 = "http://www.roblox.com/asset/?id=182436842", dance3 = "http://www.roblox.com/asset/?id=182436935", wave = "http://www.roblox.com/asset/?id=128777973", point = "http://www.roblox.com/asset/?dan=128853357", laugh = "http://www.roblox.com/asset/?id=129423131", cheer = "http://www.roblox.com/asset/?id=129423030"
			}

			local CurrentAnimSpeed = 1.0
			local JumpAnimTime = 0
			local Time = 0

			for Name, Id in AnimData do
				local Animation = Instance.new("Animation")
				Animation.AnimationId = Id
				
				AnimationTable[Name] = Animation
			end

			local function SetAnimationSpeed(Speed)
				if Speed ~= CurrentAnimSpeed then
					CurrentAnimSpeed = Speed
					CurrentAnimTrack:AdjustSpeed(CurrentAnimSpeed)
				end
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
					CurrentAnim = AnimName
					CurrentAnimInstance = Anim

					if CurrentAnimKeyframeHandler then
						CurrentAnimKeyframeHandler:disconnect()
					end

					CurrentAnimKeyframeHandler = CurrentAnimTrack.KeyframeReached:Connect(function(FrameName)
						if FrameName == "End" then
							local RepeatAnim = CurrentAnim
							if EmoteNames[RepeatAnim] and not EmoteNames[RepeatAnim] then
								RepeatAnim = "Idle"
							end

							local AnimSpeed = CurrentAnimSpeed
							PlayAnimation(RepeatAnim, 0.0)
							SetAnimationSpeed(AnimSpeed)
						end
					end)
				end
			end

			local function OnDied() if AnimationsToggled then Pose = "Dead" end end
			local function OnGettingUp() if AnimationsToggled then Pose = "GettingUp" end end
			local function OnFallingDown() if AnimationsToggled then Pose = "FallingDown" end end
			local function OnSeated() if AnimationsToggled then Pose = "Seated" end end
			local function OnPlatformStanding() if AnimationsToggled then Pose = "PlatformStanding" end end
			local function OnRunning(Speed)
				if AnimationsToggled then
					if Speed > 0.01 then
						PlayAnimation("Walk", 0.1) Pose = "Running"
						if CurrentAnimInstance and CurrentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
							SetAnimationSpeed(Speed / 14.5)
						end
					elseif not EmoteNames[CurrentAnim] then 
						PlayAnimation("Idle", 0.1) Pose = "Standing"
					end
				end
			end

			local function OnJumping()
				if AnimationsToggled then 
					PlayAnimation("Jump", 0.1)
					JumpAnimTime = 0.3
					Pose = "Jumping"
				end
			end

			local function OnClimbing(Speed)
				if AnimationsToggled then
					PlayAnimation("Climb", 0.1) SetAnimationSpeed(Speed / 12.0) Pose = "Climbing"
				end
			end

			local function OnFreeFall()
				if AnimationsToggled then
					if JumpAnimTime <= 0 then PlayAnimation("Fall", 0.3) end
					Pose = "FreeFall"
				end
			end

			local function OnSwimming(Speed)
				if AnimationsToggled then Pose = Speed >= 0 and "Running" or "Standing" end
			end

			FakeHumanoid.Died:Connect(OnDied)
			FakeHumanoid.Running:Connect(OnRunning)
			FakeHumanoid.Jumping:Connect(OnJumping)
			FakeHumanoid.Climbing:Connect(OnClimbing)
			FakeHumanoid.GettingUp:Connect(OnGettingUp)
			FakeHumanoid.FreeFalling:Connect(OnFreeFall)
			FakeHumanoid.FallingDown:Connect(OnFallingDown)
			FakeHumanoid.Seated:Connect(OnSeated)
			FakeHumanoid.PlatformStanding:Connect(OnPlatformStanding)
			FakeHumanoid.Swimming:Connect(OnSwimming)

			AnimationHandlingFunction = function(Message)
				local Emote = ""

				if Message == "/e dance" then
					Emote = Dances[math.random(1, #Dances)]
				elseif string.sub(Message, 1, 3) == "/e " then
					Emote = string.sub(Message, 4)
				end

				if Pose == "Standing" and EmoteNames[Emote] then
					PlayAnimation(Emote, 0.1)
				end
			end

			table.insert(RBXSignals, RunService.PostSimulation:Connect(function(DeltaTime)
				AnimationsToggled = Animate and Animate.Parent and Animate.Enabled or nil

				local Amplitude = 1
				local SetAngles = nil

				if JumpAnimTime > 0 then
					JumpAnimTime = JumpAnimTime - DeltaTime
				end

				if Pose == "FreeFall" and JumpAnimTime <= 0 then
					PlayAnimation("Fall", 0.3)
				elseif Pose == "Seated" then
					PlayAnimation("Sit", 0.5)
				elseif Pose == "Running" then
					PlayAnimation("Walk", 0.1)
				elseif Pose == "Dead" or Pose == "GettingUp" or Pose == "FallingDown" or Pose == "Seated" or Pose == "PlatformStanding" then
					local OldAnim = CurrentAnim

					if not EmoteNames[OldAnim] then
						OldAnim = "Idle"
					end

					CurrentAnim, CurrentAnimInstance = "", nil

					if CurrentAnimKeyframeHandler  then
						CurrentAnimKeyframeHandler:Disconnect()
					end

					if CurrentAnimTrack then
						CurrentAnimTrack:Stop()
						CurrentAnimTrack:Destroy()
					end

					Amplitude = 0.1
					SetAngles = true

					if SetAngles then
						local DesiredAngle = Amplitude * math.sin(Time * 1)
						RightShoulder:SetDesiredAngle(DesiredAngle)
						LeftShoulder:SetDesiredAngle(DesiredAngle)
						RightHip:SetDesiredAngle(-DesiredAngle)
						LeftHip:SetDesiredAngle(-DesiredAngle)
					end
				end
			end))

			table.clear(AnimData)
		end)
	end
end

-- // RunTime: Functions

local function IsNetworkOwner(Part)  -- <BasePart> : Boolean
	return Part and Part.ReceiveAge == 0
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

local function ExtractNumbers(String) -- <String> : string
	return string.match(String, "%d+")
end

local function FindAccessory(FromWhere, Texture, Mesh, Name) -- <Instance> <string> <string> <string> : Accessory
	for _, x in GetChildren(FromWhere) do
		if IsA(x, "Accessory") and x.Name == Name then

			local HatData = ObtainMeshAndTextureOfAccessory(x)

			if HatData then
				local MeshNumber = ExtractNumbers(HatData.MeshId)
				local TextureNumber = ExtractNumbers(HatData.TextureId)

				local InputMeshNumber = ExtractNumbers(Mesh)
				local InputTextureNumber = ExtractNumbers(Texture)


				if MeshNumber == InputMeshNumber and TextureNumber == InputTextureNumber then
					return x
				end
			end
		end
	end
end

local function Decollide(Part) -- <Part> : nil
	Part.CanCollide = false
	Part.CanTouch = false
	Part.CanQuery = false
end

local function RecreateAccessory(Accessory) -- <Accessory> : Accessory
	local FakeAccessory = Accessory:Clone()
	local FakeHandle = GetFirstPart(FakeAccessory)

	FakeHandle.Transparency = 1

	local FakeAttachment = FindFirstChildOfClass(FakeHandle, "Attachment")
	local RigAttachment = FindFirstChild(FakeRig, FakeAttachment and FakeAttachment.Name or "", true)

	local FakeHandleWeld = Instance.new("Weld")

	FakeHandleWeld.Name = "AccessoryWeld"
	FakeHandleWeld.Part0 = FakeHandle
	FakeHandleWeld.C0 = FakeAttachment.CFrame

	DestroyWeld(FakeHandle)

	if RigAttachment then
		FakeHandleWeld.C1 = RigAttachment.CFrame
		FakeHandleWeld.Part1 = RigAttachment.Parent
	else
		FakeHandleWeld.Part1 = FindFirstChild(FakeRig, "Head")
	end

	FakeHandleWeld.Parent = FakeHandle
	FakeAccessory.Parent = FakeRig

	return FakeAccessory
end

local function SetUpHatConfig() -- : nil
	for _, Hat in GetDescendants(FakeRig) do
		if IsA(Hat, "Accessory") then
			Hat:Destroy()
		end
	end

	for _, Value in HatsWithDifferentAligns do
		local Accessory = FindAccessory(Character, Value[1], Value[2], Value[3]) 

		if Accessory then
			local Handle = GetFirstPart(Accessory)

			if HatsInUse then
				local Part1 = Value[4]

				if Part1 and Part1.Parent then
					HatsInUse[Handle] = {Part1, Value[5] or CFrame.identity}
				end
			end
		end
	end

	for Index, x in Hats do
		for _, Info in x do
			local Accessory = FindAccessory(Character, Info.Texture, Info.Mesh, Info.Name)

			if Accessory then
				local Handle = GetFirstPart(Accessory)

				if Handle and not HatsInUse[Handle] then
					HatsInUse[Handle] = {FindFirstChild(FakeRig, Index), Info.Offset}
				end
			end
		end
	end

	for _, v in GetChildren(Character) do
		if IsA(v, "Accessory") then
			local Handle = GetFirstPart(v)

			if Handle then				
				if not HatsInUse[Handle] then
					local FakeAccessory = RecreateAccessory(v)

					if FakeAccessory then
						HatsInUse[Handle] = {GetFirstPart(FakeAccessory), CFrame.identity}
					end
				end
			end
		end
	end
end

local function ConnectHats(Part0, Part1, Offset) -- : nil
	if Part0 and Part1 then
		if Part0.Parent and Part1.Parent then
			if IsNetworkOwner(Part0) then
				local Part1Magnitude = Part1.Size.Magnitude
				local Part1Velocity = Part1.AssemblyLinearVelocity * Part1Magnitude
				local CalculatedVel = Part1Velocity * 2.5

				local ClampedAxisY = math.clamp(Part1Velocity.Y, SafeYAxis, 512)
				local Velocity = Vector3.new(CalculatedVel.X, ClampedAxisY, CalculatedVel.Z)

				local CFrameOffset = Part1.CFrame * Offset

				Part0.AssemblyLinearVelocity = Velocity
				Part0.AssemblyAngularVelocity = Part1.AssemblyAngularVelocity
				Part0.CFrame = CFrameOffset + ReverseSleep
			end
		end
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
			if FindFirstChildOfClass(Model, "Humanoid") then
				if not (Model == Character and Model == FakeRig) then
					Output = true
				end
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

		Time += task.wait()
	end
end

-- // RunTime: Event functions

local function SetCameraTarget() -- Function | SIGNAL: Camera:GetPropertySignalChanged("CameraSubject")
	PreviousCameraCFrame = Camera.CFrame
	Camera.CameraSubject = FakeHumanoid

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
end

local function OnPreSimulation() -- SIGNAL: RunService.PreSimulation
	if CanCallSimRadius then
		Player.SimulationRadius = 1000
	end

	if AntiVoiding then
		if FakeRoot.Position.Y < FallenPartsDestroyHeight then
			FakeRoot.CFrame = CFrameBackup
			FakeRoot.AssemblyLinearVelocity = Vector3.zero
			FakeRoot.AssemblyAngularVelocity = Vector3.zero
		end
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
end

local function OnCharacterAdded() -- SIGNAL : Player.CharacterAdded
	table.clear(HatsInUse)
	table.clear(Descendants)
	table.clear(FakeRigChildren)

	SetCameraTarget()

	Character = Player.Character

	if Character and LastCharacter ~= Character then
		LastCharacter = Character

		Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
		RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)

		if Humanoid and RootPart then
			ForceSetProperty(FindFirstChild(FakeRoot, "Died"), "Volume", 0)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)

			Descendants = GetDescendants(Character)
			TeleportOffset = FakeRoot.Position + GetRandomRadius()

			while ArePlayersNearby() do
				TeleportOffset = FakeRoot.Position + GetRandomRadius()

				task.wait()
			end

			if DisableCharacterScripts then
				for _, Instance in Descendants do
					if IsA(Instance, "LocalScript") then
						Instance.Disabled = true
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

			BringCharacter()
			
			task.defer(SetUpHatConfig)

			FakeRigChildren = GetChildren(FakeRig)

			Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			Character:BreakJoints()
		end
	end
end

local function OnChatted(Message) -- SIGNAL: Player.Chatted
	if AnimationHandlingFunction then
		AnimationHandlingFunction(Message)
	end

	if Message == "/e stop" then
		CancelScript()
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
	CameraHandle = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(SetCameraTarget)
end

if IsMobile then
	local StartPosition = nil
	local IsActive = nil

	local MovementVector = Vector3.zero

	local function OnTouchBegan(Input)
		local TouchPos = Input.Position
		local ScreenSize = Camera.ViewportSize

		local X = TouchPos.X / ScreenSize.X
		local Y = TouchPos.Y / ScreenSize.Y

		if X < 0.4 and Y > 0.45 then
			StartPosition = TouchPos
			IsActive = true
		else
			MouseDown = true
		end
	end

	local function OnTouchMoved(Input)
		if IsActive then
			local Delta = Input.Position - StartPosition
			MovementVector = Vector3.new(Delta.X, 0, Delta.Y).Unit

			FakeHumanoid:Move(MovementVector, true)
		end
	end

	local function OnTouchEnded()
		MovementVector = Vector3.zero

		FakeHumanoid:Move(MovementVector, true)
		IsActive = nil
		MouseDown = nil
	end

	table.insert(RBXSignals, UserInputService.TouchStarted:Connect(OnTouchBegan))
	table.insert(RBXSignals, UserInputService.TouchMoved:Connect(OnTouchMoved))
	table.insert(RBXSignals, UserInputService.TouchEnded:Connect(OnTouchEnded))
	table.insert(RBXSignals, UserInputService.JumpRequest:Connect(function()
		FakeHumanoid.Jump = true
	end))
end

-- // Finalizing: Connecting Events

SetCameraTarget()
SetUpHatConfig()

ForceSetProperty(FindFirstChild(FakeRoot, "Died"), "Volume", 0)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

table.insert(RBXSignals, Player.CharacterAdded:Connect(OnCharacterAdded))
table.insert(RBXSignals, RunService.PostSimulation:Connect(OnPostSimulation))
table.insert(RBXSignals, RunService.PreSimulation:Connect(OnPreSimulation))
CameraHandle = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(SetCameraTarget)
table.insert(RBXSignals, FakeRoot:GetPropertyChangedSignal("Parent"):Connect(UponParentChange))
table.insert(RBXSignals, RespawnEvent.Event:Connect(CancelScript))
table.insert(RBXSignals, Player.Chatted:Connect(OnChatted))
table.insert(RBXSignals, UserInputService.InputBegan:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, true) end))
table.insert(RBXSignals, UserInputService.InputEnded:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, nil) end))

FakeRigChildren = GetChildren(FakeRig)

Global.KadeAPI = {
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
		loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Uncategorized-Scripts/main/LoadLib.lua"))()
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
