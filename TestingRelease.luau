-- TESTING RELEASE, ANY BUG REPORTS ARE APPRECIATED
-- CURRENT RELEASE: 1.7-debug_4

-- \\ Krypton Reanimate, Author: @xyzkade . https://github.com/KadeTheExploiter/Krypton/ // 
-- || Gelatek was there | 1.7 After 5 months..
-- // Defining Variables: Settings

KryptonConfiguration = {
	ReturnOnDeath = true,
	Flinging = true,
	SetCharacter = false, -- Could be Buggy!
	PresetFling = true, -- if set to false, KadeAPI.CallFling() won't do anything.
	Animations = true,
	WaitTime = 0.25,
	TeleportOffsetRadius = 20,
	NoCollisions = true,
	AntiVoiding = true,
	SetSimulationRadius = true,
	DisableCharacterScripts = true,
	AccessoryFallbackDefaults = true,
	OverlayFakeCharacter = true,
	NoBodyNearby = true,
	LimitHatsPerLimb = true,
	ShowClientHats = true,
	RigName = "Tetris",
	Hats = nil, -- Set to nil if you want to use defaults.
}

local function KryptonInit() -- [ Setup, following the emper's way because people prefer to have it like that from what I've seen. ]
	if not game.Loaded then
		game.Loaded:Wait()
	end 

	local Config = KryptonConfiguration or Configuration or {}

	local WaitTime = Config.WaitTime or 0.25; 
	local Flinging = Config.Flinging
	local Animations = Config.Animations
	local AntiVoiding = Config.AntiVoiding 
	local SetCharacter = Config.SetCharacter 
	local NoBodyNearby = Config.NoBodyNearby
	local ReturnOnDeath = Config.ReturnOnDeath 
	local ShowClientHats = Config.ShowClientHats 
	local ForceMobileMode = Config.ForceMobileMode
	local ForceDesktopMode = Config.ForceDesktopMode
	local LimitHatsPerLimb = Config.LimitHatsPerLimb
	local PresetFling = Flinging and Config.PresetFling 
	local NoCollisions = Config.NoCollisions or Flinging
	local SetSimulationRadius = Config.SetSimulationRadius
	local OverlayFakeCharacter = Config.OverlayFakeCharacter
	local DisableCharacterScripts = Config.DisableCharacterScripts 
	local TeleportOffsetRadius = Config.TeleportOffsetRadius or 12
	local AccessoryFallbackDefaults = Config.AccessoryFallbackDefaults
	local RigName = Config.RigName or "Evolution, it must've passed you by."

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

	if WaitTime < 0.16 then WaitTime = 0/1 end

	local Hats = Config.Hats or DefaultHats

	local IsA = game.IsA
	local FindFirstChildOfClass = game.FindFirstChildOfClass
	local FindFirstChild = game.FindFirstChild
	local WaitForChild = game.WaitForChild
	local GetChildren = game.GetChildren
	local GetDescendants = game.GetDescendants
	
	local TeleportOffset = Vector3.zero
	local ReverseSleep = TeleportOffset
	local SafeYAxis = 35

	local DefaultAccessoryPart1 = nil
	local CameraHandle = nil
	local MouseDown = nil
	local SpaceDown = nil

	local HatsWithDifferentAligns = {}
	local FlingableTargets = {}
	local TempSignals = {}
	local RBXSignals = {}
	local HatsInUse = {}
	local Blacklist = {}
	local KeyInputs = {
		[Enum.KeyCode.W] = {nil, 0, -1}, 
		[Enum.KeyCode.A] = {nil, -1, 0},
		[Enum.KeyCode.S] = {nil, 0, 1},
		[Enum.KeyCode.D] = {nil, 1, 0}
	}
	
	local function GetInstanceWithTime(Parent, Class, Name, Timeout)  -- <Any> <String> <String> <Number> : Instance
		local CurTime = 0

		while Timeout > CurTime do
			for _, v in GetChildren(Parent) do
				if IsA(v, Class) and (not Name or v.Name == Name) then
					return v
				end
			end

			CurTime += task.wait(0/1)
		end
	end
	
	local Workspace = FindFirstChildOfClass(game, "Workspace") -- getservice not needed as they are preloaded servies
	local Players = FindFirstChildOfClass(game, "Players")
	local RunService = FindFirstChildOfClass(game, "RunService")
	local StarterGui = FindFirstChildOfClass(game, "StarterGui")
	local UserInputService = FindFirstChildOfClass(game, "UserInputService")

	local Camera = Workspace.CurrentCamera
	local PreviousCameraCFrame = Camera.CFrame
	local KBMLookVector = Camera.CFrame.LookVector
	local CamCustomType = Enum.CameraType.Custom

	local IsMobile = ForceMobileMode or UserInputService.TouchEnabled
	local IsKeyboard = ForceDesktopMode or UserInputService.KeyboardEnabled

	local Terrain = FindFirstChildOfClass(Workspace, "Terrain") -- Always present.
	local RespawnEvent = Instance.new("BindableEvent")

	local Player = Players.LocalPlayer
	local Mouse = Player:GetMouse()

	local Character = Player.Character or Player.CharacterAdded:Wait() and Player.Character

	local Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
	local RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)
	local Descendants = GetDescendants(Character)

	local CFrameBackup = AntiVoiding and RootPart.CFrame or CFrame.identity
	local FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight + 75
	local CanCallSimRadius = SetSimulationRadius and pcall(function() Player.SimulationRadius = 1000 end)

	local FakeRig = Instance.new("Model")
	local FakeHumanoid = Instance.new("Humanoid")
	local FakeRigChildren = {}
	local FakeRoot = nil

	local Move = FakeHumanoid.Move

	if FindFirstChild(Terrain, RigName) then
		return
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
		MakeMotor6D('Right Shoulder', Torso, RightArm, CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
		MakeMotor6D('Left Shoulder', Torso, LeftArm, CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
		MakeMotor6D('Right Hip', Torso, RightLeg, CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
		MakeMotor6D('Left Hip', Torso, LeftLeg, CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

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
			local function AddAnimation(ID)
				local Animation = Instance.new("Animation")
				Animation.AnimationId = ID
				return Animation
			end
			
			local AnimationsToggled = true
			local JumpAnimTime = 0

			local Current = {
				Speed = 0,
				Animation = "",
				Instance = nil,
				AnimTrack = nil,
				KeyframeHandler = nil
			}

			local AnimationTable = {
				Idle = AddAnimation("http://www.roblox.com/asset/?id=180435571"), 
				Walk = AddAnimation("http://www.roblox.com/asset/?id=180426354"), 
				Run = AddAnimation("Run.xml"), 
				Jump = AddAnimation("http://www.roblox.com/asset/?id=125750702"), 
				Fall = AddAnimation("http://www.roblox.com/asset/?id=180436148"), 
				Climb = AddAnimation("http://www.roblox.com/asset/?id=180436334"), 
				Sit = AddAnimation("http://www.roblox.com/asset/?id=178130996"),

				dance1 = AddAnimation("http://www.roblox.com/asset/?id=182435998"),
				dance2 = AddAnimation("http://www.roblox.com/asset/?id=182436842"), 
				dance3 = AddAnimation("http://www.roblox.com/asset/?id=182436935"), 
				wave = AddAnimation("http://www.roblox.com/asset/?id=128777973"),
				point = AddAnimation("http://www.roblox.com/asset/?dan=128853357"), 
				laugh = AddAnimation("http://www.roblox.com/asset/?id=129423131"),
				cheer = AddAnimation("http://www.roblox.com/asset/?id=129423030")
			}

			local function PlayAnimation(AnimName, TransitionTime)
				local Anim = AnimationTable[AnimName]

				if Anim ~= Current.Instance then
					if Current.AnimTrack then
						Current.AnimTrack:Stop(TransitionTime)
						Current.AnimTrack:Destroy()
					end

					Current.Speed = 1.0
					Current.AnimTrack = FakeHumanoid:LoadAnimation(Anim)
					Current.AnimTrack.Priority = Enum.AnimationPriority.Core
					Current.AnimTrack:Play(TransitionTime)

					Current.Animation = AnimName
					Current.Instance = Anim

					if Current.KeyframeHandler then
						Current.KeyframeHandler:Disconnect()
					end

					Current.KeyframeHandler = Current.AnimTrack.KeyframeReached:Connect(function(FrameName)
						if FrameName == "End" and AnimationTable[Current.Animation] then
							PlayAnimation("Idle", 0.1)
						end
					end)
				end
			end

			local function SetAnimationSpeed(Speed)
				Current.Speed = Speed
				Current.AnimTrack:AdjustSpeed(Speed)
			end

			local EventHandlers = {
				Running = function(Speed)
					if Speed > 0.01 then
						PlayAnimation("Walk", 0.1)
						SetAnimationSpeed(Speed / 14.5)
					else
						PlayAnimation("Idle", 0.1)
					end
				end,

				Jumping = function()
					PlayAnimation("Jump", 0.1)
					JumpAnimTime = 0.3
				end,

				Climbing = function(Speed)
					PlayAnimation("Climb", 0.1)
					SetAnimationSpeed(Speed / 12.0)
				end,

				FreeFalling = function()
					if JumpAnimTime <= 0 then
						PlayAnimation("Fall", 0.3)
					end
				end
			}

			for EventName, Handler in EventHandlers do
				FakeHumanoid[EventName]:Connect(function(...)
					if AnimationsToggled then
						Handler(...)
					end
				end)
			end

			table.insert(RBXSignals, Player.Chatted:Connect(function(Message)
				local Context = Message and string.gsub(Message, "/e ", "")

				if AnimationsToggled and AnimationTable[Context] then
					PlayAnimation(Context, 0.1)
				end
			end))
			
			table.insert(RBXSignals, RunService.PostSimulation:Connect(function(DeltaTime)
				AnimationsToggled = Animate and Animate.Parent and Animate.Enabled
				JumpAnimTime = math.max(0, JumpAnimTime - DeltaTime)
			end))
		end
	end

	-- // RunTime: Functions
	local function ForceSetProperty(Instance, Property, Value) -- <Instance | Table> <String>, <Any> : nil
		return pcall(function()
			Instance[Property] = Value
		end)
	end

	local function ExtractNumbers(String) -- <String> : string
		return string.match(String, "%d+")
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

	local function FindAccessory(Parent, Texture, Mesh, Name) -- <Instance> <string> <string> <string> : Accessory
		local InputMeshNumber = ExtractNumbers(Mesh)
		local InputTextureNumber = ExtractNumbers(Texture)

		for _, Accessory in GetChildren(Parent) do
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

		local FakeAttachment = FindFirstChildOfClass(FakeHandle, "Attachment")
		local RigAttachment = FakeAttachment and FindFirstChild(FakeRig, FakeAttachment.Name or "", true)

		local Weld = Instance.new("Weld")

		FakeHandle.Transparency = 1
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

	local function BringCharacter() -- : nil
		local Time = 0

		while WaitTime > Time do
			if RootPart then
				RootPart.AssemblyLinearVelocity = Vector3.new(0,-1200,0) -- Can sometimes remove the root instantly, providing faster claim time!!!
				RootPart.AssemblyAngularVelocity = Vector3.zero
				RootPart.CFrame = CFrame.new(TeleportOffset)
			end

			Time += RunService.PostSimulation:Wait()
		end
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

					task.wait()
				end
			end
		end

		table.clear(FlingableTargets)
	end
	
	local function RespawnBring() -- : nil
		TeleportOffset = FakeRoot.Position + GetRandomRadius() + Vector3.new(0, NoBodyNearby and FallenPartsDestroyHeight + 15 or 0, 0)

		while ArePlayersNearby() do
			TeleportOffset = FakeRoot.Position + GetRandomRadius() + Vector3.new(0, NoBodyNearby and FallenPartsDestroyHeight + 15 or 0, 0)
			task.wait(0/1)
		end
		
		BringCharacter()

		Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		Character:BreakJoints()

		task.wait(0.125)

		Descendants = GetDescendants(Character)
		SetUpHatConfig()

		if SetCharacter then
			task.wait()
			Player.Character = FakeRig
		end
	end
	
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

		if ReturnOnDeath then
			local Target = Player.CharacterAdded:Wait()
			local Root = GetInstanceWithTime(Target, "Part", "HumanoidRootPart", 3)

			if Root then
				Root.CFrame = Pos
			end
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
		for Handle, Data in HatsInUse do
			ConnectHats(Handle, Data[1], Data[2])
		end

		if AntiVoiding and FakeRoot.Position.Y < FallenPartsDestroyHeight then
			FakeRoot.CFrame = CFrameBackup
			FakeRoot.AssemblyLinearVelocity = Vector3.zero
			FakeRoot.AssemblyAngularVelocity = Vector3.zero
		end

		if not SetCharacter and IsKeyboard then
			local KBMMovementVector = Vector3.zero
			FakeHumanoid.Jump = SpaceDown

			for _, Table in KeyInputs do
				if Table[1] then
					local X, Z = KBMMovementVector.X, KBMMovementVector.Z

					KBMMovementVector = Vector3.new(X + Table[2], 0, Z + Table[3])
				end
			end

			if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				KBMLookVector = Camera.CFrame.LookVector
				FakeHumanoid.AutoRotate = false

				FakeRoot.CFrame = CFrame.new(FakeRoot.Position) * CFrame.Angles(0, math.atan2(-KBMLookVector.X, -KBMLookVector.Z), 0)
			else
				FakeHumanoid.AutoRotate = true
			end

			Move(FakeHumanoid, KBMMovementVector, true)
		end
		-- Not doing an elseif check due to compatibility issues.
		if SetCharacter or IsMobile then
			-- For some reason the movement does not seem to work well as expected, we are returning to more ancient methods.
			FakeHumanoid.Jump = Humanoid.Jump
			Move(FakeHumanoid, Humanoid.MoveDirection)
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
		StarterGui:SetCore("ResetButtonCallback", RespawnEvent)
		ReverseSleep = Vector3.new(0.0075 * math.sin(os.clock() * 7), 0, 0.0065 * math.cos(os.clock() * 3))
		SafeYAxis = 35 - 3 * math.sin(os.clock() * 10)

		if CanCallSimRadius then
			Player.SimulationRadius = 1000
		end

		for _, Part in Descendants do
			if IsA(Part, "BasePart") then
				Part.CanCollide = false
				Part.CanTouch = false
				Part.CanQuery = false
			end
		end

		if NoCollisions then
			for _, Part in FakeRigChildren do
				if IsA(Part, "BasePart") then
					Part.CanCollide = false
					Part.CanTouch = false
					Part.CanQuery = false
				end
			end
		end
	end

	local function OnCharacterAdded(NewCharacter) -- SIGNAL : Player.CharacterAdded
		UpdateCameraCFrame()

		if NewCharacter ~= FakeRig then
			table.clear(HatsInUse)
			table.clear(Descendants)
			table.clear(FakeRigChildren)
			table.clear(Blacklist)

			Character = NewCharacter
			Humanoid = GetInstanceWithTime(Character, "Humanoid", nil, 3)
			RootPart = GetInstanceWithTime(Character, "Part", "HumanoidRootPart", 3)

			if Humanoid and RootPart then
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
				
				RootPart.Transparency = 0.5

				ForceSetProperty(FindFirstChild(FakeRoot, "Died"), "Volume", 0)
				Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
				Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				
				FakeRigChildren = GetChildren(FakeRig)
				task.defer(RespawnBring)
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

        spawn(function()
	UpdateCameraCFrame()
	SetUpHatConfig()
        end)

	ForceSetProperty(FindFirstChild(FakeRoot, "Died"), "Volume", 0)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)

	table.insert(RBXSignals, Player.CharacterAdded:Connect(OnCharacterAdded))
	table.insert(RBXSignals, RunService.PostSimulation:Connect(OnPostSimulation))
	table.insert(RBXSignals, RunService.PreSimulation:Connect(OnPreSimulation))
	table.insert(RBXSignals, RunService.PreRender:Connect(OnPreRender))
	table.insert(RBXSignals, FakeRoot:GetPropertyChangedSignal("Parent"):Connect(UponParentChange))
	table.insert(RBXSignals, RespawnEvent.Event:Connect(CancelScript))
	table.insert(RBXSignals, UserInputService.InputBegan:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, true) end))
	table.insert(RBXSignals, UserInputService.InputEnded:Connect(function(Input, GameProcessed) OnInputChange(Input, not GameProcessed, nil) end))
	table.insert(RBXSignals, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(UponCameraChange))
	CameraHandle = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(UpdateCameraCFrame)
	
	if SetCharacter then
		Player.Character = FakeRig
	end

	RespawnBring()
	FakeRigChildren = GetChildren(FakeRig)
end

-- Start

local MainModule = KryptonInit()
