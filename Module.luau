-- Version: 1.3
-- Beta release, known bugs: You can fling yourself, that's it.
-- // Defining Variables: Settings

local Configuration = Configuration or {}
local ReturnOnDeath = Configuration.ReturnOnDeath or true
local Flinging = Configuration.Flinging or true
local Animations = Configuration.Animations or true
local WaitTime = Configuration.WaitTime or 0.2509
local RigName = Configuration.RigName or "FakeRig" -- sets name for the rig
local TeleportOffsetRadius = Configuration.TeleportOffsetRadius or 25

local Hats =  Configuration.Hats or {
	["Right Arm"] = {
		{Texture = "rbxassetid://14255544465", Mesh = "rbxassetid://14255522247", Name = "RARM", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Left Arm"] = {
		{Texture = "rbxassetid://14255544465", Mesh = "rbxassetid://14255522247", Name = "LARM", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Right Leg"] = {
		{Texture = "rbxassetid://17374768001", Mesh = "rbxassetid://17374767929", Name = "Accessory (RARM)", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Left Leg"] = {
		{Texture = "rbxassetid://17374768001", Mesh = "rbxassetid://17374767929", Name = "Accessory (LARM)", Offset = CFrame.Angles(0, 0, math.rad(90))}
	},

	["Torso"] = {
		{Texture = "rbxassetid://13415110780", Mesh = "rbxassetid://13421774668", Name = "MeshPartAccessory", Offset = CFrame.identity}
	},
}

-- // Defining Variables: Game Related

local function GetInstanceWithTime(Parent, Class, Name, Timeout)
	local CurTime = 0

	while Timeout > CurTime do
		for _, v in next, Parent:GetChildren() do
			if v:IsA(Class) and v.Name == (Name or v.Name) then
				return v
			end
		end

		CurTime = CurTime + task.wait()
	end
end

local Workspace = workspace
local Players = game:FindFirstChildOfClass("Players")
local RunService = game:FindFirstChildOfClass("RunService")
local UserInputService = game:FindFirstChildOfClass("UserInputService")
local StarterGui = game:FindFirstChildOfClass("StarterGui")
local Camera = Workspace.CurrentCamera
local PreviousCameraCFrame = Camera.CFrame

local WalkOffset = CFrame.identity
local TeleportOffset = CFrame.identity

local ReverseSleep = Vector3.zero
local SafeVector = Vector3.new(0,30,0)

local MouseDown = nil
local Shiftlock = nil
local ReadyToClaim = nil
local AnimationHandlingFunction = nil

local MovementMulitply = 9e9
local PlayerPing = 50
local SafeYAxis = 27

local RespawnEvent = Instance.new("BindableEvent")
local DefaultMovementValues = {0,0}
local CurrentMovement = {0,0}
local RBXSignals = {}
local HatsInUse = {}
local KeyInputs = {
	['W'] = {Enum.KeyCode.W, {0, 1e4}, false},
	['A'] = {Enum.KeyCode.A, {1e4, 0}, false},
	['S'] = {Enum.KeyCode.S, {0, -1e4}, false},
	['D'] = {Enum.KeyCode.D, {-1e4, 0}, false},
	['Space'] = {Enum.KeyCode.Space, nil, false},
}


local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Character = Player.Character
local PrimaryPart = Character.PrimaryPart
local Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
local RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)

-- // RunTime: Creating FakeRig

local FakeRig = Instance.new("Model")
local FakeHumanoid = Instance.new("Humanoid")
local FakeRoot = nil

local function CancelScript()
	for _, v in next, RBXSignals do
		v:Disconnect()
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

	MakeAttachment("HairAttachment", CFrame.new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head)
	MakeAttachment("HatAttachment", CFrame.new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head)
	MakeAttachment("FaceFrontAttachment", CFrame.new(0, 0, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), Head)
	MakeAttachment("RootAttachment", CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FakeRoot)
	MakeAttachment("LeftShoulderAttachment", CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftArm)
	MakeAttachment("LeftGripAttachment", CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftArm)
	MakeAttachment("RightShoulderAttachment", CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightArm)
	MakeAttachment("RightGripAttachment", CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightArm)
	MakeAttachment("LeftFootAttachment", CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), LeftLeg)	
	MakeAttachment("RightFootAttachment", CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), RightLeg)
	MakeAttachment("NeckAttachment", CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)
	MakeAttachment("BodyFrontAttachment", CFrame.new(0, 0, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)
	MakeAttachment("BodyBackAttachment", CFrame.new(0, 0, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)
	MakeAttachment("LeftCollarAttachment", CFrame.new(-1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)
	MakeAttachment("RightCollarAttachment", CFrame.new(1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)
	MakeAttachment("WaistFrontAttachment", CFrame.new(0, -1, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)
	MakeAttachment("WaistCenterAttachment", CFrame.new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)
	MakeAttachment("WaistBackAttachment", CFrame.new(0, -1, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), Torso)

	Animate.Name = "Animate"
	Animate.Parent = FakeRig

	FakeRigDescendants = FakeRig:GetDescendants()
	FakeRoot.CFrame = PrimaryPart.CFrame * CFrame.new(0, 0.1, 0)
	FakeRig.Name = RigName
	FakeRig.Parent = workspace

	FakeHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	FakeHumanoid:ChangeState(Enum.HumanoidStateType.Landed)

	if Animations then
		task.delay(1, function()
			local AnimationsToggled = (Animate and Animate.Parent) and Animate.Enabled or false
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
		
			local function PlayAnimation(AnimName, TransitionTime, humanoid)
				local Roll = math.random(1, 10)
				local Idx = 1
				while Roll > 10 do
					Roll = Roll - 10
					Idx = Idx + 1
				end

				local Anim = AnimationTable[AnimName].Anim

				if Anim ~= CurrentAnimInstance then
					if CurrentAnimTrack ~= nil then
						CurrentAnimTrack:Stop(TransitionTime)
						CurrentAnimTrack:Destroy()
					end

					CurrentAnimSpeed = 1.0
					CurrentAnimTrack = humanoid:LoadAnimation(Anim)
					CurrentAnimTrack.Priority = Enum.AnimationPriority.Core
		
					CurrentAnimTrack:Play(TransitionTime)
					CurrentAnim = AnimName
					CurrentAnimInstance = Anim
		
					if (CurrentAnimKeyframeHandler ~= nil) then
						CurrentAnimKeyframeHandler:disconnect()
					end

					CurrentAnimKeyframeHandler = CurrentAnimTrack.KeyframeReached:Connect(function(FrameName)
						if FrameName == "End" then
							local RepeatAnim = CurrentAnim
							if EmoteNames[RepeatAnim] ~= nil and EmoteNames[RepeatAnim] == false then
								RepeatAnim = "Idle"
							end
					
							local AnimSpeed = CurrentAnimSpeed
							PlayAnimation(RepeatAnim, 0.0, FakeHumanoid)
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
						PlayAnimation("Walk", 0.1, FakeHumanoid) Pose = "Running"
						if CurrentAnimInstance and CurrentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
							SetAnimationSpeed(Speed / 14.5)
						end
					elseif EmoteNames[CurrentAnim] == nil then 
						PlayAnimation("Idle", 0.1, FakeHumanoid) Pose = "Standing"
					end
				end
			end
		
			local function OnJumping()
				if AnimationsToggled then 
					PlayAnimation("Jump", 0.1, FakeHumanoid)
					JumpAnimTime = 0.3
					Pose = "Jumping"
				end
			end
		
			local function OnClimbing(Speed)
				if AnimationsToggled then
					PlayAnimation("Climb", 0.1, FakeHumanoid) SetAnimationSpeed(Speed / 12.0) Pose = "Climbing"
				end
			end
		
			local function OnFreeFall()
				if AnimationsToggled then
					if JumpAnimTime <= 0 then PlayAnimation("Fall", 0.3, FakeHumanoid) end
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
					PlayAnimation(Emote, 0.1, FakeHumanoid)
				end
			end
		
			RBXSignals[#RBXSignals+1] = RunService.PostSimulation:Connect(function(DeltaTime)
				AnimationsToggled = (Animate and Animate.Parent) and Animate.Enabled or false
				local Amplitude = 1
				local SetAngles = false
		
				if JumpAnimTime > 0 then
					JumpAnimTime = JumpAnimTime - DeltaTime
				end
		
				if Pose == "FreeFall" and JumpAnimTime <= 0 then
					PlayAnimation("Fall", 0.3, FakeHumanoid)
				elseif Pose == "Seated" then
					PlayAnimation("Sit", 0.5, FakeHumanoid)
				elseif Pose == "Running" then
					PlayAnimation("Walk", 0.1, FakeHumanoid)
				elseif Pose == "Dead" or Pose == "GettingUp" or Pose == "FallingDown" or Pose == "Seated" or Pose == "PlatformStanding" then
					local OldAnim = CurrentAnim

					if EmoteNames[OldAnim] == false then
						OldAnim = "Idle"
					end
	
					CurrentAnim, CurrentAnimInstance = "", nil
	
					if CurrentAnimKeyframeHandler ~= nil then
						CurrentAnimKeyframeHandler:Disconnect()
					end
			
					if CurrentAnimTrack ~= nil then
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
	return Parent:FindFirstChild("Handle") or Parent:FindFirstChildOfClass("Part")
end

local function GetFirstWeld(Parent) -- <Any> :  Weld | ManualWeld
	return Parent:FindFirstChild("AccessoryWeld") or Parent:FindFirstChildOfClass("Weld") or Parent:FindFirstChildOfClass("ManualWeld")
end

local function DestroyWeld(Parent) -- <Instance>
	local Weld = GetFirstWeld(Parent)

	if Weld then
		Weld:Destroy()
	end
end

local function ObtainMeshAndTextureOfAccessory(Accessory) -- <Accessory> : {MeshId: string, TextureId: string}
	local Handle = Accessory:FindFirstChild("Handle")
	local IfMesh = Handle:FindFirstChildOfClass("SpecialMesh")

	if Handle:IsA("MeshPart") then
		return {MeshId = Handle.MeshId, TextureId = Handle.TextureID}
	elseif IfMesh then
		return {MeshId = IfMesh.MeshId, TextureId = IfMesh.TextureId}
	end

	return {MeshId = "" ,TextureId = ""}
end

local function FindAccessory(FromWhere, Texture, Mesh, Name) -- <Instance> <string> <string> <string> : Accessory
	for _, x in next, FromWhere:GetChildren() do
		if x:IsA("Accessory") and x.Name == Name then
			local HatData = ObtainMeshAndTextureOfAccessory(x)

			if string.match(HatData.MeshId, Mesh) and string.match(HatData.TextureId, Texture) then
				return x
			end
		end
	end

	return
end

local function RecreateAccessory(Accessory) -- <Accessory> : Accessory
	local Head = FakeRig:FindFirstChild("Head")

	local Handle = GetFirstPart(Accessory)
	local Weld = GetFirstWeld(Handle)
	local IsPart1Existant = Weld.Part1 or nil

	local FakeAccessory = Accessory:Clone()
	local FakeHandle = GetFirstPart(FakeAccessory)

	local FakeAttachment = FakeHandle:FindFirstChildOfClass("Attachment")
	local FakeHandleWeld = Instance.new("Weld")

	DestroyWeld(FakeHandle)

	if not IsPart1Existant or IsPart1Existant and IsPart1Existant.Name ~= "Head" then
		if FakeAttachment then
			FakeHandleWeld.C0 = FakeAttachment.CFrame
			FakeHandleWeld.C1 = FakeRig:FindFirstChild(tostring(FakeAttachment), true).CFrame -- SHUT UP ROBLOX.
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

	FakeHandleWeld.Part0 = FakeHandle
	FakeHandle.Transparency = 1
	FakeHandleWeld.Name = "AccessoryWeld"

	FakeHandleWeld.Parent = FakeHandle
	FakeAccessory.Parent = FakeRig

	return FakeAccessory
end

local function SetUpHatConfig()
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
		if v:IsA("Accessory") then
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

local function ArePlayersNearby()
	local PartsOnTheWay = workspace:GetPartBoundsInRadius(TeleportOffset.Position, 15)

	for _, v in next, PartsOnTheWay do
		local Model = v.Parent

		if Model:IsA("Model") and Model.Name ~= Player.Name and Model.PrimaryPart ~= nil then
			return true
		end
	end

	return false
end

-- // RunTime: Event functions

local function SetCameraTarget() -- Function | SIGNAL: Camera:GetPropertySignalChanged("CameraSubject")
	Camera.CameraSubject = FakeHumanoid
end

local function OnInputChange(Input, GameProcessed, Bool) -- SIGNAL: UIS.InputBegan | UIS.InputEnded
	if GameProcessed and Input.UserInputType == Enum.UserInputType.MouseButton1 then
		MouseDown = Bool
	end

	for _, v in next, KeyInputs do
		if GameProcessed and Input.KeyCode == v[1] then
			v[3] = Bool
		end
	end
end

local function OnPostSimulation() -- SIGNAL: RunService.PostSimulation
	PrimaryPart = Character and Character.PrimaryPart or nil
	
	for Handle, Data in next, HatsInUse do
		local OtherLimb = Data[1]		
		local HandleMass = OtherLimb.Size.Magnitude * 4
		local Velocity = OtherLimb.AssemblyLinearVelocity * HandleMass
		
		local YValue = math.clamp(Velocity.Y, SafeYAxis, 1024)

		if IsNetworkOwner(Handle) then
			local CFrameOffset = ReadyToClaim and OtherLimb.CFrame * Data[2] or PrimaryPart and PrimaryPart.CFrame

			Handle.AssemblyLinearVelocity = ReadyToClaim and Vector3.new(Velocity.X, YValue, Velocity.Z) or SafeVector 
			Handle.AssemblyAngularVelocity = ReadyToClaim and OtherLimb.AssemblyAngularVelocity or SafeVector -- claim
			Handle.CFrame = Handle.CFrame:Lerp(CFrameOffset + ReverseSleep, 1)
		end 
	end
	
	ReverseSleep = Vector3.new(0.0075 * math.sin(os.clock() * 8), 0, 0.0075 * math.cos(os.clock() * 16))
	SafeYAxis = 40 - 3 * math.sin(os.clock() * 10)
	
	--Player.SimulationRadius = 1000
end

local function OnPreSimulation() -- SIGNAL: RunService.PreSimulation
	Shiftlock = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
	FakeHumanoid.AutoRotate = not Shiftlock
	PlayerPing = Player:GetNetworkPing() * math.random(20,35)

	local LookVector = Camera.CFrame.LookVector
	local X, Z = CurrentMovement[1], CurrentMovement[2]

	for _, Value in next, KeyInputs do
		if Value[2] and Value[3] then
			CurrentMovement[1] = CurrentMovement[1] + Value[2][1]
			CurrentMovement[2] = CurrentMovement[2] + Value[2][2]
		end
	end

	local Magnitude = math.sqrt(CurrentMovement[1]^2 + CurrentMovement[2]^2)

	if Magnitude > 1e4 then
		CurrentMovement[1] = CurrentMovement[1] / Magnitude * 1e4
		CurrentMovement[2] = CurrentMovement[2] / Magnitude * 1e4
	end

	FakeHumanoid.Jump = KeyInputs["Space"][3]

	local ShiftlockCalc = CFrame.new(FakeRoot.Position) * CFrame.Angles(0, math.atan2(-LookVector.X, -LookVector.Z), 0) -- after searching, seems like i need to calc the yaw angle
	local IsMovementKeyPressed = KeyInputs["W"][3] or KeyInputs["A"][3] or KeyInputs["S"][3] or KeyInputs["D"][3]
	WalkOffset = WalkOffset * CFrame.new(-X, 0,-Z)

	if Shiftlock then
		FakeRoot.CFrame = ShiftlockCalc
	end

	FakeHumanoid.WalkToPoint = IsMovementKeyPressed and WalkOffset.Position or FakeRoot.Position

	CurrentMovement = DefaultMovementValues
	WalkOffset = CFrame.new(FakeRoot.Position, Vector3.new(LookVector.X * MovementMulitply, LookVector.Y, LookVector.Z * MovementMulitply))
end

local function OnCharacterAdded() -- SIGNAL : Player.CharacterAdded
	PreviousCameraCFrame = Camera.CFrame
	Camera.CameraSubject = FakeHumanoid

	Camera:GetPropertyChangedSignal("CFrame"):Wait()
	Camera.CFrame = PreviousCameraCFrame

	SetCameraTarget()
	ReadyToClaim = false

	table.clear(HatsInUse)
	Character = Player.Character
	Character:FindFirstChildOfClass("Accessory")

	Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
	RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)

	if not RootPart or not Humanoid then
		warn("Script Cancelled, Lack of needed Instances.")

		CancelScript(); return
	end

	if Flinging then
		Instance.new("SelectionBox", RootPart).Adornee = RootPart
		local Children = Character:GetChildren()
		local TemporarySignal = nil
		TemporarySignal = RunService.PostSimulation:Connect(function()
			for _, Part in next, Children do
				if Part:IsA("Part") then
					Part.CanCollide = false
					Part.CanQuery = false
					Part.CanTouch = false
				end
			end

			if MouseDown then
				local Target = Mouse.Target
					-- prob unoptimized but doesnt matter honestly its better to not get any error
					
				local Target_P = Target and Target.Parent and Target.Parent:IsDescendantOf(workspace) and Target.Parent
				local Target_PP = Target_P and Target_P.Parent and Target_P.Parent:IsDescendantOf(workspace) and Target_P.Parent
				local NewTarget = Target_P and Target_P:FindFirstChildOfClass("Humanoid") or Target_PP and Target_PP:FindFirstChildOfClass("Humanoid") or nil

				if NewTarget then
					local Part = GetFirstPart(NewTarget.Parent)

					if Part then
						RootPart.CFrame = CFrame.new(Part.Position + Part.AssemblyLinearVelocity * PlayerPing)
					else
						RootPart.CFrame = CFrame.new(Mouse.Hit.Position)
					end
				else
					RootPart.CFrame = CFrame.new(Mouse.Hit.Position)
				end
			else
				TemporarySignal:Disconnect()
				TemporarySignal = nil
			end

			RootPart.AssemblyLinearVelocity = Vector3.new(4096, 4096, 4096)
		end)

		repeat task.wait() until TemporarySignal == nil
	end

	local Number = TeleportOffsetRadius -- i dont like mess...
	TeleportOffset = FakeRoot.CFrame * CFrame.new(math.random(-Number, Number), 0.25, math.random(-Number, Number))

	while ArePlayersNearby() do
		TeleportOffset = FakeRoot.CFrame * CFrame.new(math.random(-Number, Number), 0.25, math.random(-Number, Number))
		task.wait()
	end

	RootPart.AssemblyLinearVelocity = Vector3.zero
	RootPart.AssemblyAngularVelocity = Vector3.zero
	RootPart.CFrame = TeleportOffset
	task.wait(WaitTime)

	Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

	for _, v in next, FakeRig:GetDescendants() do
		if v:IsA("Accessory") then
			v:Destroy()
		end
	end

	SetUpHatConfig()

	task.wait(WaitTime/2)

	ReadyToClaim = true
end

local function OnChatted(Message)
	if AnimationHandlingFunction then
		AnimationHandlingFunction(Message)
	end
	
	if Message == "/e stop" then
		CancelScript()
	end
end

local function UponParentChange()
	if not FakeRig:IsDescendantOf(workspace) then
		CancelScript()
	end
end

-- // RunTime: Connecting Events

SetCameraTarget()
SetUpHatConfig()

StarterGui:SetCore("ResetButtonCallback", RespawnEvent)
Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
RBXSignals[#RBXSignals+1] = Player.CharacterAdded:Connect(OnCharacterAdded)
RBXSignals[#RBXSignals+1] = RunService.PostSimulation:Connect(OnPostSimulation)
RBXSignals[#RBXSignals+1] = RunService.PreAnimation:Connect(OnPreSimulation)
RBXSignals[#RBXSignals+1] = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(SetCameraTarget)
RBXSignals[#RBXSignals+1] = FakeRig:GetPropertyChangedSignal("Parent"):Connect(UponParentChange)
RBXSignals[#RBXSignals+1] = RespawnEvent.Event:Connect(CancelScript)
RBXSignals[#RBXSignals+1] = Player.Chatted:Connect(OnChatted)

RBXSignals[#RBXSignals+1] = UserInputService.InputBegan:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, true) end)
RBXSignals[#RBXSignals+1] = UserInputService.InputEnded:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, false) end)


-- // End: Finalizing

task.wait(WaitTime)
ReadyToClaim = true
