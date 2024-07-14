-- // Defining Variables: Settings

local Configuration = Configuration or {}
local ReturnOnDeath = Configuration.ReturnOnDeath or false
local Flinging = Configuration.Flinging or true
local Animations = Configuration.Animations or false
local WaitTime = Configuration.WaitTime or 0.2509
local RigName = Configuration.RigName or "Evolution, it must've passed you by."
local NoCollisions = Configuration.NoCollisions or Flinging or false
local AntiVoiding = Configuration.AntiVoiding or false
local SetSimulationRadius = Configuration.SetSimulationRadius or false
local DisableCharacterScripts = Configuration.DisableCharacterScripts or false
local TeleportOffsetRadius = Configuration.TeleportOffsetRadius or 22
local Hats = Configuration.Hats or {
	["Right Arm"] = {
		{Texture = "14255544465", Mesh = "14255522247", Name = "RARM", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Left Arm"] = {
		{Texture = "14255544465", Mesh = "14255522247", Name = "LARM", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Right Leg"] = {
		{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (RARM)", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Left Leg"] = {
		{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (LARM)", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Torso"] = {
		{Texture = "13415110780", Mesh = "13421774668", Name = "MeshPartAccessory", Offset = CFrame.identity}
	},
}

-- // Defining Variables: Game Related

local function BetterFindFirstChildOfClass(Parent, ClassName) -- <Any> <String> : Instance
	if Parent then
		local Value = Parent:FindFirstChildOfClass(ClassName)
		if Value then
			return Value
		end
	end
end

local function BetterIsA(Instance, ClassName) -- <Any> <String> : Instance
	if Instance then
		local Parent = Instance.Parent

		if Parent then
			return Instance:IsA(ClassName)
		end
	end
end

local function GetInstanceWithTime(Parent, Class, Name, Timeout)  -- <Any> <String> <String> <Number> : Instance
	local CurTime = 0

	while Timeout > CurTime do
		for _, v in next, Parent:GetChildren() do
			if BetterIsA(v, Class) and v.Name == (Name or v.Name) then
				return v
			end
		end

		CurTime = CurTime + task.wait()
	end
end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera
local PreviousCameraCFrame = Camera.CFrame

local Terrain = BetterFindFirstChildOfClass(workspace, "Terrain")

if Terrain:FindFirstChild(RigName) then
	return
end

local TeleportOffset = CFrame.identity

local MouseDown = nil
local SpaceDown = nil
local SafeToLoad = nil
local AnimationHandlingFunction = nil

local RecoverTime = WaitTime/1.75

local RespawnEvent = Instance.new("BindableEvent")

local RBXSignals = {}
local HatsInUse = {}
local KeyInputs = {[Enum.KeyCode.W] = {false, 0, -1}, [Enum.KeyCode.A] = {false, -1, 0}, [Enum.KeyCode.S] = {false, 0, 1}, [Enum.KeyCode.D] = {false, 1, 0}}

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Character = Player.Character
local Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
local RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)

local CFrameBackup = AntiVoiding and RootPart.CFrame or nil
local FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight + 75
local CanCallSimRadius = SetSimulationRadius and pcall(function() Player.SimulationRadius = 1000 end) or nil

-- // RunTime: Creating FakeRig

local FakeRig = Instance.new("Model")
local FakeHumanoid = Instance.new("Humanoid")
local FakeRigChildren = {}
local FakeRoot = nil

local function CancelScript()  -- : nil
	for _, v in next, RBXSignals do
		v:Disconnect()
		v = nil
	end

	if ReturnOnDeath then
		local CamCFrame = Camera.CFrame
		local Offset = FakeRoot.CFrame
		
		Player.CharacterAdded:Wait()
		workspace.CurrentCamera.CFrame = CamCFrame
		RootPart = GetInstanceWithTime(Player.Character, "Part", "HumanoidRootPart", 3)

		if RootPart then
			RootPart.CFrame = Offset
		end
	end

	FakeRig:Destroy()

	-- Free the memory after use.

	table.clear(Hats)
	table.clear(HatsInUse)
	table.clear(RBXSignals)
	table.clear(FakeRigChildren)
	table.clear(KeyInputs)
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

	local Head = Instance.new("Part")
	local Torso = Instance.new("Part")
	local RightArm = Instance.new("Part")

	Head.Size = Vector3.new(2,1,1)
	Torso.Size = Vector3.new(2,2,1)
	RightArm.Size = Vector3.new(1,2,1)

	Head.Transparency = 1
	Torso.Transparency = 1
	RightArm.Transparency = 1

	FakeRoot = Torso:Clone()
	FakeRoot.CanCollide = false

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

	local Attachments = {
		["HairAttachment"] = { CFrame.new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head },
		["HatAttachment"] = { CFrame.new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head },
		["FaceFrontAttachment"] = { CFrame.new(0, 0, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head },
		["RootAttachment"] = { CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FakeRoot },
		["LeftShoulderAttachment"] = { CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftArm },
		["LeftGripAttachment"] = { CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftArm },
		["RightShoulderAttachment"] = { CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightArm },
		["RightGripAttachment"] = { CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightArm },
		["LeftFootAttachment"] = { CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftLeg },
		["RightFootAttachment"] = { CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightLeg },
		["NeckAttachment"] = { CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso },
		["BodyFrontAttachment"] = { CFrame.new(0, 0, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso },
		["BodyBackAttachment"] = { CFrame.new(0, 0, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso },
		["LeftCollarAttachment"] = { CFrame.new(-1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso },
		["RightCollarAttachment"] = { CFrame.new(1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso },
		["WaistFrontAttachment"] = { CFrame.new(0, -1, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso },
		["WaistCenterAttachment"] = { CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso },
		["WaistBackAttachment"] = { CFrame.new(0, -1, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso }
	}

	for Name, Table in next, Attachments do
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
			local CurrentAnimSpeed = 1.0
			local JumpAnimTime = 0
			local Time = 0
			local AnimationTable = {}
			local Dances = {"dance1", "dance2", "dance3"}
			local EmoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

			local AnimLinks = {
				-- Movement Anims
				Idle = "http://www.roblox.com/asset/?id=180435571", Walk = "http://www.roblox.com/asset/?id=180426354", Run = "Run.xml", Jump = "http://www.roblox.com/asset/?id=125750702", Fall = "http://www.roblox.com/asset/?id=180436148", Climb = "http://www.roblox.com/asset/?id=180436334", Sit = "http://www.roblox.com/asset/?id=178130996",
				-- Animations
				dance1 = "http://www.roblox.com/asset/?id=182435998", dance2 = "http://www.roblox.com/asset/?id=182436842", dance3 = "http://www.roblox.com/asset/?id=182436935", wave = "http://www.roblox.com/asset/?id=128777973", point = "http://www.roblox.com/asset/?dan=128853357", laugh = "http://www.roblox.com/asset/?id=129423131", cheer = "http://www.roblox.com/asset/?id=129423030"
			}
		

			for name, v in next, AnimLinks do
				AnimationTable[name] = {}
				AnimationTable[name].Anim = Instance.new("Animation")
				AnimationTable[name].Anim.AnimationId = v
			end	

			local function SetAnimationSpeed(Speed)
				if Speed ~= CurrentAnimSpeed then
					CurrentAnimSpeed = Speed
					CurrentAnimTrack:AdjustSpeed(CurrentAnimSpeed)
				end
			end
		
			local function PlayAnimation(AnimName, TransitionTime)
				local Anim = AnimationTable[AnimName].Anim

				if Anim ~= CurrentAnimInstance then
					if CurrentAnimTrack ~= nil then
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
							if EmoteNames[RepeatAnim] and EmoteNames[RepeatAnim] == false then
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
				elseif string.sub(Message, 1, 7) == "/Emote " then
					Emote = string.sub(Message, 8)
				end

				if Pose == "Standing" and EmoteNames[Emote] ~= nil then
					PlayAnimation(Emote, 0.1)
				end
			end
		
			RBXSignals[1] = RunService.PostSimulation:Connect(function(DeltaTime)
				AnimationsToggled = Animate and Animate.Parent and Animate.Enabled or false
				local Amplitude = 1
				local SetAngles = false
		
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
			end)
		end)
	end
end

-- // RunTime: Functions
local function IsNetworkOwner(Part)  -- <BasePart> : Boolean
	return Part and Part.ReceiveAge == 0
end

local function GetFirstPart(Parent) -- <Any> : Part | BasePart
	return Parent:FindFirstChild("Handle") or BetterFindFirstChildOfClass(Parent, "Part")
end

local function GetFirstWeld(Parent) -- <Any> :  Weld | ManualWeld
	return Parent:FindFirstChild("AccessoryWeld") or BetterFindFirstChildOfClass(Parent, "Weld") or BetterFindFirstChildOfClass(Parent, "ManualWeld")
end

local function DestroyWeld(Parent) -- <Instance>
	local Weld = GetFirstWeld(Parent)

	if Weld then
		Weld:Destroy()
	end
end

local function ObtainMeshAndTextureOfAccessory(Accessory) -- <Accessory> : {MeshId: string, TextureId: string}
	local Handle = Accessory:FindFirstChild("Handle")
	local IfMesh = BetterFindFirstChildOfClass(Handle, "SpecialMesh")

	if BetterIsA(Handle, "MeshPart") then
		return {MeshId = Handle.MeshId, TextureId = Handle.TextureID}
	elseif IfMesh then
		return {MeshId = IfMesh.MeshId, TextureId = IfMesh.TextureId}
	end
end

local function FindAccessory(FromWhere, Texture, Mesh, Name) -- <Instance> <string> <string> <string> : Accessory
	for _, x in next, FromWhere:GetChildren() do
		if BetterIsA(x, "Accessory") and x.Name == Name then
			local HatData = ObtainMeshAndTextureOfAccessory(x)

			if string.find(HatData.MeshId, Mesh) and string.find(HatData.TextureId, Texture) then
				return x
			end
		end
	end
end

local function RecreateAccessory(Accessory) -- <Accessory> : Accessory
	local Head = FakeRig:FindFirstChild("Head")

	local Handle = GetFirstPart(Accessory)
	local Weld = GetFirstWeld(Handle)
	local IsPart1Existant = Weld.Part1 or nil

	local FakeAccessory = Accessory:Clone()
	local FakeHandle = GetFirstPart(FakeAccessory)

	local FakeAttachment = BetterFindFirstChildOfClass(FakeHandle, "Attachment")
	local FakeHandleWeld = Instance.new("Weld")

	DestroyWeld(FakeHandle)

	if not IsPart1Existant or IsPart1Existant and IsPart1Existant.Name ~= "Head" then
		if FakeAttachment then
			FakeHandleWeld.C0 = FakeAttachment.CFrame
			FakeHandleWeld.C1 = FakeRig:FindFirstChild(tostring(FakeAttachment), true).CFrame
			FakeHandleWeld.Part1 = FakeRig:FindFirstChild(tostring(FakeAttachment), true).Parent
		else
			FakeHandleWeld.Part1 = Head
			FakeHandleWeld.C1 = CFrame.new(0, Head.Size.Y / 2, 0) * FakeAccessory.AttachmentPoint:Inverse()
		end
	elseif IsPart1Existant and IsPart1Existant.Name == "Head" then
		FakeHandleWeld.C0 = Weld.C0 or CFrame.identity
		FakeHandleWeld.C1 = Weld.C1 or CFrame.identity
		FakeHandleWeld.Part1 = Head
	end

	FakeHandle.Transparency = 1
	FakeHandleWeld.Part0 = FakeHandle
	FakeHandleWeld.Name = "AccessoryWeld"

	FakeHandleWeld.Parent = FakeHandle
	FakeAccessory.Parent = FakeRig

	return FakeAccessory
end

local function SetUpHatConfig() -- : nil
	for _, Hat in next, FakeRig:GetDescendants() do
		if BetterIsA(Hat, "Accessory") then
			Hat:Destroy()
		end
	end

	for Index, x in next, Hats do
		for _, Info in next, x do
			local Accessory = FindAccessory(Character, Info.Texture, Info.Mesh, Info.Name)

			if Accessory then
				local Handle = GetFirstPart(Accessory)

				if Handle then
					HatsInUse[Handle] = {FakeRig:FindFirstChild(Index), Info.Offset}
				end
			end
		end
	end

	for _, v in next, Character:GetChildren() do
		if BetterIsA(v, "Accessory") then
			local Handle = GetFirstPart(v)

			if not HatsInUse[Handle] then
				local FakeAccessory = RecreateAccessory(v)
			
				if FakeAccessory and Handle then
					HatsInUse[Handle] = {GetFirstPart(FakeAccessory), CFrame.identity}
				end
			end
		end
	end
end

local function ArePlayersNearby() -- : Boolean
	local PartsOnTheWay = workspace:GetPartBoundsInRadius(TeleportOffset.Position, 15)

	for _, Part in next, PartsOnTheWay do
		local Model = Part.Parent

		return BetterIsA(Part, "Model") and Model.Name ~= Player.Name and Model.PrimaryPart
	end
end

local function GetRandomRadius() -- : CFrame
	return CFrame.new(math.random(-TeleportOffsetRadius, TeleportOffsetRadius), 0.5, math.random(-TeleportOffsetRadius, TeleportOffsetRadius))
end

-- // RunTime: Event functions

local function SetCameraTarget() -- Function | SIGNAL: Camera:GetPropertySignalChanged("CameraSubject")
	PreviousCameraCFrame = Camera.CFrame
	Camera.CameraSubject = FakeHumanoid
	Camera:GetPropertyChangedSignal("CFrame"):Wait()
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

		for MyInput, Table in next, KeyInputs do
			if Input.KeyCode == MyInput then
				Table[1] = Bool
			end
		end
	end
end

local function OnPostSimulation() -- SIGNAL: RunService.PostSimulation
	StarterGui:SetCore("ResetButtonCallback", RespawnEvent)
	local Multiply = SafeToLoad and 4 or 1
	local ReverseSleep = Vector3.new(0.0075 * math.sin(os.clock() * 7), 0, 0.0085 * math.cos(os.clock() * 16))
	local SafeYAxis = 35 - 3 * math.sin(os.clock() * 10)
		
	if CanCallSimRadius then
		Player.MaximumSimulationRadius = 16384
		Player.SimulationRadius = 16384
	end

	for Handle, Data in next, HatsInUse do
		local OtherLimb = Data[1]

		if OtherLimb and IsNetworkOwner(Handle) then
			local Part1Offset = Data[2]
			local Part1Magnitude = OtherLimb.Size.Magnitude
			local Part1Velocity = OtherLimb.AssemblyLinearVelocity * Part1Magnitude
			local CalculatedVel = Part1Velocity * Multiply

			local ClampedAxisY = math.clamp(Part1Velocity.Y, SafeYAxis, 1024)
			local Velocity = Vector3.new(CalculatedVel.X, ClampedAxisY, CalculatedVel.Z)

			local CFrameOffset = OtherLimb.CFrame * Part1Offset

			Handle.AssemblyLinearVelocity = Velocity
			Handle.AssemblyAngularVelocity = OtherLimb.AssemblyAngularVelocity
			Handle.CFrame = SafeToLoad and Handle.CFrame:Lerp(CFrameOffset + ReverseSleep, 1) or RootPart.CFrame
		end
	end
end

local function OnPreSimulation() -- SIGNAL: RunService.PreSimulation
	local MovementVector = Vector3.zero
	local Shiftlock = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter

	if NoCollisions then
		for _, Part in next, FakeRigChildren do
			if BetterIsA(Part, "Part") then
				Part.CanCollide = false
				Part.CanTouch = false
				Part.CanQuery = false
			end
		end
	end

	if AntiVoiding and FakeRoot.Position.Y < FallenPartsDestroyHeight then
		FakeRoot.CFrame = CFrameBackup
		FakeRoot.AssemblyLinearVelocity = MovementVector
		FakeRoot.AssemblyAngularVelocity = MovementVector
	end

	FakeHumanoid.AutoRotate = not Shiftlock
	FakeHumanoid.Jump = SpaceDown

	for _, Table in next, KeyInputs do
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
 
local function OnCharacterAdded() -- SIGNAL : Player.CharacterAdded
	table.clear(HatsInUse)
	SafeToLoad = false

	SetCameraTarget()
	Character = Player.Character
	Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
	RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)
	
	if DisableCharacterScripts then
		for _, Instance in next, Character:GetDescendants() do
			if BetterIsA(Instance, "LocalScript") then
				Instance.Disabled = true
			end
		end	
	end

	if Flinging then
		local Children = Character:GetChildren()

		local TemporaryNoclip = RunService.PostSimulation:Connect(function()
			for _, Part in next, Children do
				if BetterIsA(Part, "Part") then
					Part.CanCollide = false
					Part.CanTouch = false
					Part.CanQuery = false
				end
			end
		end)

		local TemporarySignal = RunService.PostSimulation:Connect(function()
			if not MouseDown then return end

			local Target = Mouse.Target
			local TargetParent = Target and Target.Parent
			local TargetDescendant = TargetParent and TargetParent.Parent
			local NewTarget = BetterFindFirstChildOfClass(TargetParent, "Humanoid") or BetterFindFirstChildOfClass(TargetDescendant, "Humanoid")

			RootPart.AssemblyLinearVelocity = Vector3.new(4096, 4096, 4096)
			local HitCalciulation = CFrame.new(Mouse.Hit.Position)
				
			if NewTarget then
				local Part = GetFirstPart(NewTarget.Parent)

				if Part then
					RootPart.CFrame = CFrame.new(Part.Position + Part.AssemblyLinearVelocity * Player:GetNetworkPing())
				else
					RootPart.CFrame = HitCalciulation
				end
			else
				RootPart.CFrame = HitCalciulation
			end
		end)

		repeat task.wait() until not MouseDown

		TemporaryNoclip:Disconnect()
		TemporarySignal:Disconnect()
		TemporaryNoclip = nil
		TemporarySignal = nil
	end

	TeleportOffset = FakeRoot.CFrame * GetRandomRadius()
	while ArePlayersNearby() do
		TeleportOffset = FakeRoot.CFrame * GetRandomRadius()
		task.wait()
	end

	RootPart.AssemblyLinearVelocity = Vector3.zero
	RootPart.AssemblyAngularVelocity = Vector3.zero
	RootPart.CFrame = TeleportOffset
	task.wait(WaitTime)

	SetUpHatConfig()
	FakeRigChildren = FakeRig:GetChildren()
	Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

	task.wait(RecoverTime)
	
	SafeToLoad = true
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
	if not FakeRig:IsDescendantOf(workspace) then
		CancelScript()
	end
end

-- // Finalizing: Connecting Events

SetCameraTarget()
SetUpHatConfig()

Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

RBXSignals[2] = Player.CharacterAdded:Connect(OnCharacterAdded)
RBXSignals[3] = RunService.PostSimulation:Connect(OnPostSimulation)
RBXSignals[4] = RunService.PreAnimation:Connect(OnPreSimulation) 
RBXSignals[5] = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(SetCameraTarget)
RBXSignals[6] = FakeRig:GetPropertyChangedSignal("Parent"):Connect(UponParentChange)
RBXSignals[7] = RespawnEvent.Event:Connect(CancelScript)
RBXSignals[8] = Player.Chatted:Connect(OnChatted)
RBXSignals[9] = UserInputService.InputBegan:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, true) end)
RBXSignals[10] = UserInputService.InputEnded:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, false) end)

task.wait(WaitTime)

FakeRigChildren = FakeRig:GetChildren()
SafeToLoad = true
