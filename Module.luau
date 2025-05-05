-- \\ Krypton Reanimate, Author: @xyzkade/@gelatekforever. https://github.com/KadeTheExploiter/Krypton/ //
-- || 1.8, Let's experiment!
-- // Eyelashes, Lipstick, Facemask, Crystal Gel, Deluxe Spa Package!~...

local game = game
local TableClear = table.clear
local TaskWait = task.wait
local TableInsert = table.insert
local CFrameNew = CFrame.new
local Vector3New = Vector3.new
local Sine = math.sin
local Cosine = math.cos
local ClockTPOT = os.clock

local Hats = {} 
local KryptonConf = KryptonConfiguration or {}
local FlingTable, ReturnOnDeath, RigName, WaitTime, RigScale, DestroyHeightOffset, RadiusOffset, FlingMethod, FlingVelocity, RefitCount
local Flinging, OverlayFakeCharacter, NoBodyNearby, PermanentDeath, Reclaim, Refit, AntiVoiding, NoCollisions, SetPlayerChar, ToolFlinging, LimitHatsPerLimb, DisableCharacterScripts
DontStartYet = KryptonConf.DontStartYet -- Patchfix for private testing

local GetPropertyChangedSignal = game.GetPropertyChangedSignal
local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA
local FindFirstChildOfClass = game.FindFirstChildOfClass
local GetDescendants = game.GetDescendants
local FindFirstChild = game.FindFirstChild
local IsDescendantOf = game.IsDescendantOf
local WaitForChild = game.WaitForChild
local GetChildren = game.GetChildren
local Destroy = game.Destroy
local Clone = game.Clone
local Close = game.Close
local IsA = game.IsA

local ReverseSleep = Vector3.zero
local FailsafeOffset = CFrame.new(1, 6, 1) 
local FailsafeVelocity = Vector3New(0,120,30)
local FlingVelocity = Vector3New(16000, 16000, 16000)
local PreSimulationEvent = nil
local ReclaimInstance = nil
local LargestInstance = nil
local FlingInstance = nil
local PlayTrack = nil
local StopTrack = nil
local AdjustSpeed = nil
local CurrentAnimation = nil
local AnimationThread = nil

local MaxInteger = 2147483646
local SinedClock = 1
local TotalHats = 0

local BindableEvent = Instance.new("BindableEvent")
local FallAnimation = Instance.new("Animation")

local CamCustomType = Enum.CameraType.Custom
local CameraLockType = Enum.MouseBehavior.LockCenter

local Tables = {}
local function CreateTable(Content: {any} | nil): {any}
	local NewTable = Content or {}

	table.insert(Tables, NewTable)

	return NewTable
end

local replicatesignal = replicatesignal
local setscriptable = setscriptable 

local HatsWithDifferentAligns = CreateTable()
local FlingableTargets = CreateTable()
local TempSignals = CreateTable()
local RBXSignals = CreateTable()
local Blacklist = CreateTable()
local HatsInUse = CreateTable()
local JointsOffsets  = CreateTable()
local Joints = CreateTable()

local FrameTimes = {}
local FrameData = {}

local InsertService: InsertService = FindFirstChildOfClass(game, "InsertService")
local Workspace: Workspace = FindFirstChildOfClass(game, "Workspace")
local Players: Players = FindFirstChildOfClass(game, "Players")
local RunService: RunService = FindFirstChildOfClass(game, "RunService")
local StarterGui: StarterGui = FindFirstChildOfClass(game, "StarterGui")
local UserInputService: UserInputService = FindFirstChildOfClass(game, "UserInputService")

local SignalConnect = Close['Connect']
local SignalWait = Close['Wait']
local SignalOnce = Close['Once']
local Disconnect = SignalOnce(Close, function() end)['Disconnect']

local CanChangeSimRadius, _ = pcall(GetPropertyChangedSignal, Players.LocalPlayer, "SimulationRadius")
local FallenPartsDestroyHeight = Workspace['FallenPartsDestroyHeight'] 
local FallenPartsDestroyHeightOffset
local Terrain = FindFirstChildOfClass(Workspace, "Terrain")

local Camera = Workspace['CurrentCamera']
local PreviousCameraCFrame = Camera['CFrame']
local Player = Players['LocalPlayer']
local GetNetworkPing = Player['GetNetworkPing']
local Humanoid, Animator, RootPart, CFrameBackup

-- // RunTime: Creating FakeRig

local Character = Player['Character'] or SignalWait(Player['CharacterAdded'])

if Character.Name ~= Player.Name then 
	return 
end

local Descendants = CreateTable(GetDescendants(Character))

local FakeRig, FakeHumanoid, FakeAnimator, FakeRoot, FakeRigChildren

local QuickHumanoid = Instance.new("Humanoid")
local QuickAnimator = Instance.new("Animator", QuickHumanoid)

local SetStateEnabled = QuickHumanoid['SetStateEnabled']
local ChangeState = QuickHumanoid['ChangeState']
local LoadAnimation = QuickAnimator['LoadAnimation']
local GetPlayingAnimationTracks = QuickAnimator['GetPlayingAnimationTracks']

local Move = QuickHumanoid['Move']

local SetCoreGuiEnabled = StarterGui['SetCoreGuiEnabled']
local IsGrounded = Character.PrimaryPart['IsGrounded']
local BreakJoints = Character['BreakJoints']
local SetCore = StarterGui['SetCore']

Destroy(QuickHumanoid)

-- // RunTime: Functions

-- // Instances

local function SetDescendantProperties(Table: {}, Class: string, Property: string, Value: any, Check: boolean)
	if not Check then
		return
	end

	for _, Any in Table do
		if IsA(Any, Class) then
			Any[Property] = Value
		end
	end
end

local function WaitForInstance(Parent: Instance, Class: string, Name: string | nil, Cooldown: number | nil)
	local CurTime = Cooldown or 0

	while 1 > CurTime do
		for _, Any in GetChildren(Parent) do
			if IsA(Any, Class) and (not Name or Any.Name == Name) then
				return Any
			end
		end

		CurTime += TaskWait()
	end
end

local function ExtractNumbers(String: string | number)
	local ToString = tostring(String)
	return string.match(ToString, "%d+")
end

local function GetFirstPart(Parent: Instance) : Part
	return FindFirstChildOfClass(Parent, "Part") or WaitForChild(Parent, "Handle", 1)
end

local function GetFirstWeld(Parent: Instance) : Weld
	return FindFirstChild(Parent, "AccessoryWeld") or FindFirstChildOfClass(Parent, "Weld")
end

local function DestroyWeld(Parent: Instance)
	local Weld = GetFirstWeld(Parent)

	if Weld then
		Weld:Destroy()
	end
end

-- // Accessories

local function GetAccoutrementData(Accoutrement: Accoutrement)
	local Handle = FindFirstChild(Accoutrement, "Handle")

	if IsA(Handle, "MeshPart") then
		return {Handle.MeshId, Handle.TextureID}
	else
		local Mesh = FindFirstChildOfClass(Handle, "SpecialMesh")

		if Mesh then
			return {Mesh.MeshId, Mesh.TextureId}
		end
	end
end

local function FindAccoutrement(Parent: Instance, Texture: string | number, Mesh: string | number, Name: string)
	local InputMeshNumber = ExtractNumbers(Mesh)
	local InputTextureNumber = ExtractNumbers(Texture)

	for _, Accoutrement in GetChildren(Parent) do
		if not (IsA(Accoutrement, "Accoutrement") and Accoutrement.Name == Name) then
			continue
		end

		local AccounteremtData = GetAccoutrementData(Accoutrement)

		if not AccounteremtData then
			continue
		end

		local MeshNumber = ExtractNumbers(AccounteremtData[1])
		local TextureNumber = ExtractNumbers(AccounteremtData[2])

		if MeshNumber == InputMeshNumber and TextureNumber == InputTextureNumber then
			return Accoutrement
		end
	end
end

local function RecreateAccoutrement(Accoutrement)
	local FakeAccoutrement = Clone(Accoutrement)
	local FakeHandle = GetFirstPart(FakeAccoutrement)
	DestroyWeld(FakeHandle)

	FakeHandle.Transparency = 1

	local FakeAttachment = FindFirstChildOfClass(FakeHandle, "Attachment")
	local RigAttachmentName = FakeAttachment and FakeAttachment.Name or ""
	local RigAttachment = FindFirstChild(FakeRig, RigAttachmentName, true)

	local FakeHandleWeld = Instance.new("Weld")

	FakeHandleWeld.Name = "AccessoryWeld"
	FakeHandleWeld.Part0 = FakeHandle
	FakeHandleWeld.C0 = FakeAttachment.CFrame

	if RigAttachment then
		FakeHandleWeld.C1 = RigAttachment.CFrame
		FakeHandleWeld.Part1 = RigAttachment.Parent
	else
		FakeHandleWeld.Part1 = FindFirstChild(FakeRig, "Head")
	end

	FakeHandleWeld.Parent = FakeHandle
	FakeAccoutrement.Parent = FakeRig

	return FakeAccoutrement
end

local function ProcessAccoutrement(Accoutrement: Accoutrement, Function)
	if not Accoutrement or table.find(Blacklist, Accoutrement) then
		return
	end

	TableInsert(Blacklist, Accoutrement)
	TotalHats += 1

	local Handle = GetFirstPart(Accoutrement)

	if Handle and not HatsInUse[Handle] then
		Function(Handle)
	end
end

-- unused until celery fixes shp or setscriptable
local function SetAccoutrementsState(Table: {Accoutrement}, State: any)
	for _, Accoutrement in Table do
		if IsA(Accoutrement, "Accoutrement") then
			setscriptable(Accoutrement, "BackendAccoutrementState", true)
			Accoutrement.BackendAccoutrementState = State
		end		
	end
end

local function FinalizeAccoutrements()
	for _, Value in HatsWithDifferentAligns do
		local AlignedAccessory = FindAccoutrement(Character, Value[1], Value[2], Value[3])

		ProcessAccoutrement(AlignedAccessory, function(Handle)
			local Part1 = Value[4]

			if Part1 and Part1.Parent then
				HatsInUse[Handle] = { Part1, Value[5] or CFrame.identity }
			end
		end)
	end

	for _, Any in GetChildren(FakeRig) do
		if IsA(Any, "Accessory") then
			Destroy(Any)
		end

		local Name = Any.Name
		local Data = Hats[Name]

		if Data then
			for Index = 1, #Data do
				local HatInfo = Data[Index]
				
				if not HatInfo then
					return
				end

				local FoundAccoutrement = FindAccoutrement(
					Character, HatInfo['Texture'], HatInfo['Mesh'], HatInfo['Name']
				)
				
				ProcessAccoutrement(FoundAccoutrement, function(Handle)
					HatsInUse[Handle] = {Any, HatInfo['Offset'] or CFrame.identity}
				end)
			end
				
			if LimitHatsPerLimb then
				continue
			end
		end
	end

	for _, Accoutrement in GetChildren(Character) do
		if IsA(Accoutrement, "Accoutrement") then
			ProcessAccoutrement(Accoutrement, function(Handle)
				local FakeAccessory = RecreateAccoutrement(Accoutrement)

				HatsInUse[Handle] = { GetFirstPart(FakeAccessory), CFrame.identity }
			end)
		end
	end
end

local function RefitRig()
	TotalHats = 0
	SetDescendantProperties(FakeRigChildren, "BasePart", "Transparency", 0.5, true)
	SetDescendantProperties(FakeRigChildren, "BasePart", "BrickColor", BrickColor.new("Forest green"), true)
	ReplicateSignal(Player, "ConnectDiedSignalBackend")
end

-- // Camera

local function UpdateCameraCFrame()
	PreviousCameraCFrame = Camera['CFrame']

	SignalWait(RunService['PreRender'])
	Camera.CFrame = PreviousCameraCFrame
end

local function ChangeCameraSubject()
	Camera.CameraSubject = FakeHumanoid
	UpdateCameraCFrame()
end

local function ShiftlockRootOffset()
	if UserInputService.MouseBehavior == CameraLockType then	
		local Position = FakeRoot['Position']
		local CamLookVector = Camera.CFrame['LookVector'] --* 1

		FakeRoot.CFrame = CFrame.lookAt(Position, Position + Vector3New(CamLookVector.X, 0, CamLookVector.Z))
	end
end

-- // Flinging

local function FlingModels()
	for _, Model in FlingableTargets do
		local PrimaryPart = Model['PrimaryPart']

		if not PrimaryPart or not FlingInstance then
			continue
		end

		for Tick = 1, 16 do
			local LinearVelocity = PrimaryPart['AssemblyLinearVelocity']

			FlingInstance.CFrame = CFrameNew(
				PrimaryPart.Position + LinearVelocity * GetNetworkPing(Player) * 30
			)

			FlingInstance.AssemblyLinearVelocity = FlingVelocity

			if LinearVelocity.Magnitude > 125 then
				break
			end
		end
	end

	TableClear(FlingableTargets)
end

-- // Teleport

local function ReplicateSignal(Any: Instance | RBXScriptSignal, Signal: string)
	if not replicatesignal then
		return
	end

	if identifyexecutor and identifyexecutor() == "Celery" then
		return replicatesignal(Any, Signal)
	else
		return replicatesignal(Any[Signal])
	end
end

local function GetRandomRadius() : Vector3
	return Vector3New(
		math.random(-RadiusOffset, RadiusOffset), 0.5, math.random(-RadiusOffset, RadiusOffset)
	)
end

local function GetRightOffset() : CFrame
	local Offset = FakeRoot['Position'] + GetRandomRadius()
	local AxisY = NoBodyNearby and FallenPartsDestroyHeightOffset - 0.25 or Offset.Y
	return CFrameNew(Offset.X, AxisY, Offset.Z)
end

local function ArePlayersNearby(Offset: CFrame) : boolean
	local Position = Offset.Position
	local IsChecked -- Checks for multiple cases, duh?

	for _, Part in Workspace:GetPartBoundsInRadius(Position, 10) do
		local Model = Part.Parent

		if FindFirstChildOfClass(Model, "Humanoid") then
			if not (Model == Character and Model == FakeRig) then
				IsChecked = true
			end
		end
	end

	return IsChecked
end

local function BringCharacter()
	local ExtraOffset = CFrame.identity
	local TeleportCFrame = GetRightOffset()
	local Time = 0

	if Flinging then
		FlingModels()
	end

	while ArePlayersNearby(TeleportCFrame) do
		TeleportCFrame = GetRightOffset() * ExtraOffset
	end

	if Animator and NoBodyNearby then
		Workspace.FallenPartsDestroyHeight = 0/0
		local Animate = WaitForInstance(Character, "LocalScript", "Animate", 0.16)
		local IsR15 = Humanoid.RigType.Name == "R15"

		if Animate then
			Animate.Disabled = true
		end

		for _, Track in next, GetPlayingAnimationTracks(Animator) do
			StopTrack(Track)
		end

		local AnimationId = IsR15 and "507767968" or "180436148" 
		FallAnimation.AnimationId = "rbxassetid://"..AnimationId

		if IsR15 then
			ExtraOffset = CFrame.Angles(1145.92,0,0)
			ChangeState(Humanoid, Enum.HumanoidStateType.Physics)
		end

		local Animation = LoadAnimation(Animator, FallAnimation)
		Animation.Priority = 5

		task.spawn(PlayTrack, Animation, 0, 1, 1)
	end

	while WaitTime > Time do
		RootPart.AssemblyLinearVelocity = Vector3.zero
		RootPart.CFrame = TeleportCFrame
		Time += TaskWait()
	end
end

local function SetHumanoidStates()
	FakeRoot.AssemblyLinearVelocity = Vector3.zero
	FakeRoot.AssemblyAngularVelocity = Vector3.zero

	SetCore(StarterGui, "ResetButtonCallback", BindableEvent)
	SetCoreGuiEnabled(StarterGui, Enum.CoreGuiType.Health, false)
	SetStateEnabled(Humanoid, Enum.HumanoidStateType.Seated, false)
	SetStateEnabled(Humanoid, Enum.HumanoidStateType.Dead, true)
	BreakJoints(Character)
	
	if replicatesignal then
		ReplicateSignal(Humanoid, "ServerBreakJoints")
	else
		ChangeState(Humanoid, Enum.HumanoidStateType.Dead)
	end

	Workspace.FallenPartsDestroyHeight = FallenPartsDestroyHeight
end

local function ApplyCharacter()
	if not SetPlayerChar then
		return
	end

	if NoBodyNearby then
		repeat task.wait() until not FindFirstChild(Character, "HumanoidRootPart")
	end

	task.wait(WaitTime * 2)
	Player.Character = FakeRig
end

-- // Ownership

local function SetSimulationRadius(Value: number)
	if CanChangeSimRadius then
		Player.SimulationRadius = Value
	end
end

local function CheckAge(Part: Instance): boolean
	return Part and not IsGrounded(Part) and Part.ReceiveAge == 0
end

local function GetAdjustedAxis(Y: number): number
	if Y > 27 then
		return Y
	end

	return 27
end

local function GetCurrentPrimaryPart()
	return Character.PrimaryPart or FindFirstChildWhichIsA(Character, "BasePart", true)
end

local function CreateSelectionBox(BasePart: BasePart): SelectionBox
	local Selection = FindFirstChild(BasePart, "SelectionBox")
	
	return Selection or Instance.new("SelectionBox", BasePart)
end

local function ReclaimHandle(Handle)
	if not Handle or not Reclaim then 
		return 
	end
	
	ReclaimInstance = Handle

	local Selection = CreateSelectionBox(ReclaimInstance)
	local Timeout = 0
	local WaitTime = 0.5
	
	LargestInstance = GetCurrentPrimaryPart()

	while WaitTime > Timeout do
		Selection.Adornee = not CheckAge(ReclaimInstance) and ReclaimInstance or nil
		
		if not LargestInstance or not LargestInstance.Parent then
			LargestInstance = GetCurrentPrimaryPart()
		end

		if CheckAge(ReclaimInstance) then
			ReclaimInstance.AssemblyLinearVelocity = FailsafeVelocity
			ReclaimInstance = nil
			break
		end

		Timeout = TaskWait()
	end
end

local function CalculateVelocity(Part1: BasePart): Vector3
	local BaseVelocity = Part1['AssemblyLinearVelocity']
	local ScaledVelocity = BaseVelocity * Part1.Size['Magnitude']

	local LookVector = Part1.CFrame['LookVector'] * BaseVelocity['Unit']
	local LookVectorYAxis = GetAdjustedAxis(LookVector.Y + BaseVelocity.Y) + SinedClock

	return Vector3New(
		ScaledVelocity.X + LookVector.X,
		LookVectorYAxis,
		ScaledVelocity.Z + LookVector.Z
	)
end

local function SetPhysicalProperties(Table: {[BasePart]: {BasePart | CFrame}}, ApplyVelocity: boolean)
	for Handle, Data in Table do
		local Part1, Offset = Data[1], Data[2]

		if not Part1 then
			return
		end
		
		Handle.Massless = true

		if ApplyVelocity then
			Handle.AssemblyLinearVelocity = CalculateVelocity(Part1)
			Handle.AssemblyAngularVelocity = Part1.AssemblyAngularVelocity
		end

		if not CheckAge(Handle) then
			ReclaimHandle(Handle)
		else
			local ReclaimInstanceOffset = ReclaimInstance and ReclaimInstance.CFrame
			local BaseCFrame

			if not ReclaimInstance then
				BaseCFrame = Part1.CFrame * Offset
			elseif ReclaimInstance and Handle ~= LargestInstance then
				BaseCFrame = LargestInstance.CFrame * FailsafeOffset 
			elseif LargestInstance == Handle and ReclaimInstance and ReclaimInstanceOffset.Y > FallenPartsDestroyHeightOffset + 200 then
				BaseCFrame = ReclaimInstanceOffset
			end

			Handle.CFrame = BaseCFrame + ReverseSleep
		end
	end
end

-- // Cancel

local function CancelScript()
	if not IsDescendantOf(FakeRig, Workspace) then
		return
	end

	local RootCFrame = FakeRoot.CFrame

	ReplicateSignal(Player, "ConnectDiedSignalBackend")
	ChangeState(FakeHumanoid, Enum.HumanoidStateType.Dead)
	Disconnect(PreSimulationEvent)
	SignalWait(Player.CharacterAdded)
	Character = Player.Character

 	-- memory free up real fe bypass

	for Key, Signal in RBXSignals do
		Disconnect(Signal)
		RBXSignals[Key] = nil
	end

	for _, Table in Tables do
		TableClear(Table)
	end
	
	Camera.CameraSubject = Character

	SetCore(StarterGui, "ResetButtonCallback", true)
	Destroy(FakeRig)

	if ReturnOnDeath then
		local Root = WaitForInstance(Character, "Part", "HumanoidRootPart")

		if Root then
			Root.CFrame = RootCFrame
		end
	end
end

-- // Runit

local function OnParentChange()
	if not IsDescendantOf(FakeRig, Workspace) then
		CancelScript()
	end
end

local function OnPreRender() 
	ShiftlockRootOffset()
	SetPhysicalProperties(HatsInUse, false)

	if Camera then
		if Camera.CameraSubject ~= FakeHumanoid then
			ChangeCameraSubject()
		end

		if Camera.CameraType ~= CamCustomType then
			Camera.CameraType = CamCustomType
		end
	end

	if AntiVoiding and FakeRoot.Position.Y < FallenPartsDestroyHeightOffset then
		FakeRoot.CFrame = CFrameBackup
		FakeRoot.AssemblyLinearVelocity = Vector3.zero
		FakeRoot.AssemblyAngularVelocity = Vector3.zero
	end
end

local function OnPostSimulation()
	SetPhysicalProperties(HatsInUse, true)
	ShiftlockRootOffset()
	
	if FakeHumanoid and Humanoid then
		FakeHumanoid.Jump = Humanoid.Jump
		Move(FakeHumanoid, Humanoid.MoveDirection)
	end

	if Refit then
		for Index, Accessory in Blacklist do
			if not Accessory or Accessory and not Accessory.Parent then
				table.remove(Blacklist, Index)
			end
		end
	
		if TotalHats > RefitCount and #Blacklist < TotalHats - RefitCount then
			RefitRig()
		end
	end
end

local function OnPreSimulation()
	SetDescendantProperties(Descendants, "BasePart", "CanCollide", false, true)
	SetDescendantProperties(FakeRigChildren, "BasePart", "CanCollide", false, NoCollisions)
	SetSimulationRadius(MaxInteger)

	SinedClock = Sine(ClockTPOT())
	ReverseSleep = Vector3New(0.005 * Sine(ClockTPOT() * 100), 0, 0.005 * Cosine(ClockTPOT() * 100))
end

local function OnCharacterAdded(NewCharacter: Model)
	UpdateCameraCFrame()

	if NewCharacter == FakeRig then
		return
	end
	
	-- Clear few, not every.
	TableClear(HatsInUse)
	TableClear(Descendants)
	TableClear(FakeRigChildren)
	TableClear(Blacklist)

	TotalHats = 0

	Character = NewCharacter
	Humanoid = WaitForInstance(Character, "Humanoid", nil)
	RootPart = WaitForInstance(Character, "Part", "HumanoidRootPart")
	Animator = WaitForInstance(Humanoid, "Animator", nil)
	SetDescendantProperties(Descendants, "LocalScript", "Disabled", true, DisableCharacterScripts)

	if not Humanoid and not RootPart then
		error(not Humanoid and "Humanoid" or "HumanoidRootPart", "Not found inside Character.")
	end

	if PermanentDeath then
		RootPart.CFrame = FakeRoot.CFrame * CFrameNew(0, 2 * RigScale, 0)
		ReplicateSignal(Player, "ConnectDiedSignalBackend")
		TaskWait(Players.RespawnTime + 0.15)
	end

	BringCharacter()
	SetHumanoidStates()
	UpdateCameraCFrame()
	FinalizeAccoutrements()
	ApplyCharacter()

	FakeRigChildren = GetChildren(FakeRig)

	SetDescendantProperties(FakeRigChildren, "BasePart", "Transparency", OverlayFakeCharacter and 0.5 or 1, true)
	SetDescendantProperties(FakeRigChildren, "BasePart", "BrickColor", BrickColor.new("Black"), true)
end

local DefaultHats = {
	["Right Arm"] = {
		{Texture = "14255544465", Mesh = "14255522247", Name = "RARM", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "4645402630", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.new(0.25,0,0) * CFrame.Angles(math.rad(-90), 0, math.rad(-90))},
	},

	["Left Arm"] = {
		{Texture = "14255544465", Mesh = "14255522247", Name = "LARM", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "3650139425", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.new(-0.25,0,0) * CFrame.Angles(math.rad(-90), 0, math.rad(90))}
	},

	["Right Leg"] = {
		{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (RARM)", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "4622077774", Mesh = "3030546036", Name = "International Fedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(90))},
		{Texture = "3360978739", Mesh = "3030546036", Name = "InternationalFedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(90))},
	},

	["Left Leg"] = {
		{Texture = "17374768001", Mesh = "17374767929", Name = "Accessory (LARM)", Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Texture = "3860099469", Mesh = "3030546036", Name = "InternationalFedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(-90))},
		{Texture = "3409604993", Mesh = "3030546036", Name = "InternationalFedora", Offset = CFrame.Angles(math.rad(-90), 0, math.rad(-90))}
	},

	["Torso"] = {
		{Texture = "13415110780", Mesh = "13421774668", Name = "MeshPartAccessory", Offset = CFrame.identity},
		{Texture = "4819722776", Mesh = "4819720316", Name = "MeshPartAccessory", Offset = CFrame.Angles(0, 0, math.rad(-15))}
	},
}

local function ValidateSetting(Name, Default, OtherTable)
	local Table = OtherTable or ReanimateConfig
	local Original = Table[Name]
	return Original ~= nil and Original or Default
end

local function StartReanimate()
	ReanimateConfig = KryptonConfiguration or Configuration or {}
	FlingTable = ReanimateConfig.Flinging or {}

	RigName = ValidateSetting("RigName", "Evolution, it must've passed you by.")

	WaitTime = ValidateSetting("WaitTime", 0.251)
	RigScale = ValidateSetting("FakeRigScale", 1)
	RefitCount = ValidateSetting("RefitHatCount", 2)
	RadiusOffset = ValidateSetting("TeleportOffsetRadius", 21)
	DestroyHeightOffset = ValidateSetting("DestroyHeightOffset", 100)

	Refit = ValidateSetting("Refit", false)
	AntiVoiding = ValidateSetting("AntiVoiding", false)
	DontStartYet = ValidateSetting("DontStartYet", false)
	NoBodyNearby = ValidateSetting("NoBodyNearby", false)
	NoCollisions = ValidateSetting("NoCollisions", false) or Flinging
	ToolFlinging = ValidateSetting("ToolFlinging", false)
	SetPlayerChar = ValidateSetting("SetCharacter", false)
	OverlayFakeCharacter = ValidateSetting("OverlayFakeCharacter", false)
	ReturnOnDeath = ValidateSetting("ReturnOnDeath", false)
	Flinging = ValidateSetting("Flinging", "false", FlingTable) 
	FlingVelocity = ValidateSetting("Velocity", 8000, FlingTable)
	LimitHatsPerLimb = ValidateSetting("LimitHatsPerLimb", false)
	FlingMethod = ValidateSetting("MethodUsed", "Hat", FlingTable) 
	DisableCharacterScripts = ValidateSetting("DisableCharacterScripts", false)
	PermanentDeath = replicatesignal and ValidateSetting("PermanentDeath", false)
	Reclaim = NoBodyNearby and PermanentDeath and ValidateSetting("Reclaim", false)

	Hats = ValidateSetting("Hats", {})
	
	FallenPartsDestroyHeightOffset = FallenPartsDestroyHeight + DestroyHeightOffset or 100
	Character = Player['Character'] or SignalWait(Player['CharacterAdded'])

	if not PermanentDeath and ReanimateConfig.Refit then
		Refit = nil
	end
	
	if not NoBodyNearby and FlingMethod == ("Hat" or "HatTouch") then
		Flinging = nil
	end
	
	if Character.Name ~= Player.Name then 
		return 
	end

	if not Hats[1] or ReanimateConfig.AccessoryFallbackDefaults then
		local Types = { Name = "string", Texture = "string", Mesh = "string", Offset = "CFrame" }

		for Name, Data in DefaultHats do
			local HatsData = Hats[Name]
			local Flagged = nil

			if HatsData and typeof(HatsData) == "table" then
				for _, Hat in HatsData do
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

	Descendants = CreateTable(GetDescendants(Character))
	FakeRig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)

	FakeHumanoid = FindFirstChildOfClass(FakeRig, "Humanoid")
	FakeAnimator = FindFirstChildOfClass(FakeHumanoid, "Animator")
	FakeRoot = FindFirstChild(FakeRig, "HumanoidRootPart")
	FakeRigChildren = CreateTable(GetChildren(FakeRig))

	Humanoid = WaitForInstance(Character, "Humanoid", nil)
	RootPart = WaitForInstance(Character, "Part", "HumanoidRootPart")
	Animator = WaitForInstance(Humanoid, "Animator", nil)

	CFrameBackup = RootPart.CFrame
	FakeRig.Parent = Terrain
	FakeRoot.CFrame = CFrameBackup
	Player.ReplicationFocus = FakeRoot

	FakeRigChildren = GetChildren(FakeRig)
	PreSimulationEvent = SignalConnect(RunService["PreSimulation"], OnPreSimulation) -- need to define ts
	TableInsert(RBXSignals, SignalConnect(GetPropertyChangedSignal(FakeRig, "Parent"), OnParentChange))
	TableInsert(RBXSignals, SignalConnect(GetPropertyChangedSignal(Camera, "CameraSubject"), ChangeCameraSubject))
	TableInsert(RBXSignals, SignalConnect(Player["CharacterAdded"], OnCharacterAdded))
	TableInsert(RBXSignals, SignalConnect(RunService["PostSimulation"], OnPostSimulation))
	TableInsert(RBXSignals, SignalConnect(RunService["PreRender"], OnPreRender))
	TableInsert(RBXSignals, SignalConnect(BindableEvent["Event"], CancelScript))
	TableInsert(RBXSignals, PreSimulationEvent)

	for _, Track in next, GetPlayingAnimationTracks(Animator) do
		StopTrack = Track['Stop']
		PlayTrack = Track['Play']
		AdjustSpeed = Track['AdjustSpeed']
		break
	end

	if WaitTime < 0.16 then
		WaitTime = 0
	end

	if RigName then
		FakeRig.Name = RigName	
	end

	if RigScale then
		FakeRoot.CFrame = FakeRoot.CFrame * CFrameNew(0, 2 * RigScale, 0)
		FakeRig:ScaleTo(RigScale)
	end

	for _, Any in GetDescendants(FakeRig) do
		if IsA(Any, "Motor6D") then
			local Name = Any.Part1.Name

			JointsOffsets[Name] = Any.Transform
			Joints[Name] = Any
		end
	end

	if PermanentDeath then
		SetDescendantProperties(FakeRigChildren, "BasePart", "Transparency", 0.5, true)
		ReplicateSignal(Player, "ConnectDiedSignalBackend")
		TaskWait(Players.RespawnTime + 0.15)

		BringCharacter()
	end

	if ReanimateConfig.Animations then
		local Animate = Instance.new("LocalScript")
		Animate.Name = "Animate"
		Animate.Parent = FakeRig

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
			KeyframeHandler = nil,
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
			cheer = AddAnimation("http://www.roblox.com/asset/?id=129423030"),
		}

		local function PlayAnimation(AnimName, TransitionTime, Looped)
			local Anim = AnimationTable[AnimName]

			if Anim == Current.Instance then
				return
			end

			if Current.AnimTrack then
				StopTrack(Current.AnimTrack, TransitionTime)
				Destroy(Current.AnimTrack)
			end

			if Current.KeyframeHandler then
				Disconnect(Current.KeyframeHandler)
			end

			Current.Speed = 1.0
			Current.AnimTrack = LoadAnimation(FakeAnimator, Anim)
			Current.AnimTrack.Priority = Enum.AnimationPriority.Core
			PlayTrack(Current.AnimTrack, TransitionTime)

			Current.Animation = AnimName
			Current.Instance = Anim

			Current.KeyframeHandler = SignalConnect(Current.AnimTrack.KeyframeReached, function(FrameName)
				if Looped then
					PlayAnimation(AnimName, 0.1, true)

				elseif FrameName == "End" and AnimationTable[Current.Animation] then
					PlayAnimation("Idle", 0.1)
				end
			end)
		end

		local function SetAnimationSpeed(Speed)
			Current.Speed = Speed
			AdjustSpeed(Current.AnimTrack, Speed)
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
			end,
		}

		for EventName, Handler in EventHandlers do
			SignalConnect(FakeHumanoid[EventName], function(...)
				if AnimationsToggled then
					Handler(...)
				end
			end)
		end

		table.insert(RBXSignals, SignalConnect(Player.Chatted, function(Message)
			local Context = Message and string.gsub(Message, "/e ", "")

			if AnimationsToggled and AnimationTable[Context] then
				PlayAnimation(Context, 0.1, true)
			end
		end))

		table.insert(RBXSignals, SignalConnect(RunService.PostSimulation, function(DeltaTime)
			AnimationsToggled = Animate and Animate.Parent and Animate.Enabled
			JumpAnimTime = math.max(0, JumpAnimTime - DeltaTime)
		end))
	end

	SetDescendantProperties(FakeRigChildren, "Decal", "Transparency", OverlayFakeCharacter and 0.5 or 1, true)
	SetDescendantProperties(FakeRigChildren, "BasePart", "Transparency", OverlayFakeCharacter and 0.5 or 1, true)
	SetHumanoidStates()
	FinalizeAccoutrements()
	ApplyCharacter()
end

if not DontStartYet then
	StartReanimate()
end 

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

	GetJoints = function()
		return Joints
	end,

	GetHatInformation = function(Hat) -- Returns HumanoidRootPart
		local HatInfo = GetAccoutrementData(Hat)
		HatInfo.Name = Hat.Name

		return HatInfo
	end,

	GetRealCharacter = function() -- Returns RealRig Model, needed for scripts.
		repeat
			task.wait()
		until Player.Character

		return Player.Character
	end,

	SetHatAlign = function(HatInformation, Part1, Offset) -- Aligns Hat.
		assert(typeof(HatInformation) == "table", "HatInformation is not an table.")
		assert(Part1 and Part1:IsA("BasePart"), "Part1 is not a part.")
		assert(typeof(Offset) == "CFrame", "Offset is not a part.")

		local TextureId = HatInformation.TextureId
		local MeshId = HatInformation.MeshId
		local Name = HatInformation.Name

		local Accessory = nil
		local Timeout = 3
		local Current = 0

		while not Accessory and Timeout > Current do
			Accessory = FindAccoutrement(Player.Character, TextureId, MeshId, Name)

			Current += task.wait()
		end

		if not Accessory then
			error("Accessory has not been found in Character.")
		end

		local Handle = GetFirstPart(Accessory)

		if Handle then
			local Dictionary = table.find(HatsInUse, Handle)
			table.remove(HatsInUse, Dictionary)

			table.insert(HatsWithDifferentAligns, { TextureId, MeshId, Name, Part1, Offset })
			HatsInUse[Handle] = { Part1, Offset }
		end
	end,

	DisconnectHatAlign = function(HatInformation) -- Disconnects hat
		assert(typeof(HatInformation) == "table", "HatInformation is not an table.")

		local Accessory = nil
		local Timeout = 3
		local Current = 0

		local TextureId = HatInformation.TextureId
		local MeshId = HatInformation.MeshId
		local Name = HatInformation.Name

		while not Accessory and Timeout > Current do
			Accessory = FindAccoutrement(Player.Character, TextureId, MeshId, Name)

			Current += task.wait()
		end		

		if not Accessory then
			error("Accessory has not been found in Character.")
		end

		for Table, Value in HatsWithDifferentAligns do
			local UsedAccessory = FindAccoutrement(Character, Value[1], Value[2], Value[3])

			if UsedAccessory and UsedAccessory == Accessory then
				local UsedHandle = GetFirstPart(UsedAccessory)

				local Dictionary = table.find(HatsInUse, UsedHandle)
				table.remove(HatsInUse, Dictionary)

				local Dictionary2 = table.find(HatsWithDifferentAligns, Table) -- seems ugly but idc
				table.remove(HatsWithDifferentAligns, Dictionary2)

				if UsedHandle then
					local FakeAccessory = RecreateAccoutrement(UsedAccessory)

					if FakeAccessory then
						HatsInUse[UsedHandle] = { GetFirstPart(FakeAccessory), CFrame.identity }
					end
				end
			end
		end
	end,

	SWait = task.wait, -- Stepped Wait

	SetAnimationState = function(Status) -- Stops Animations
		local Animate = FindFirstChild(FakeRig, "Animate")

		if Animate then
			Animate.Enabled = Status
		end

		if Status and FakeAnimator then
			for _, Track in GetPlayingAnimationTracks(FakeAnimator) do
				Track:Stop()
			end
		end
	end,

	GetLoadLibrary = function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Uncategorized-Scripts/main/LoadLib.lua"))()
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
	end,

	GetWeld = function(Object)
		assert(typeof(Object) == "Instance", "Argument is not an instance.")

		if IsA(Object, "Accessory") then
			local Part = GetFirstPart(Object)

			if Part then
				return GetFirstWeld(Part)
			end
		elseif IsA(Object, "BasePart") then
			return GetFirstWeld(Object)
		end
	end,

	AnimationPlayer = {
		Start = function(AnimationID: number)
			if not FakeRig then return end

			if AnimationThread then
				task.cancel(AnimationThread)
			end

			local Animate = FindFirstChild(FakeRig, "Animate")

			if Animate then
				Animate.Disabled = true
			end
	
			if FakeAnimator then
				for _, Track in GetPlayingAnimationTracks(FakeAnimator) do
					Track:Stop()
				end
			end

			local Success, AnimationModel =  pcall(InsertService.LoadLocalAsset, InsertService, "rbxassetid://" .. tostring(AnimationID))

			if not Success then
				warn("Failed to load animation.")
				return
			end

			CurrentAnimation = AnimationModel
			CurrentAnimation.Name = "Animation"
			CurrentAnimation.Parent = FakeRig

			for _, Frame in GetChildren(CurrentAnimation) do
				table.insert(FrameTimes, Frame.Time)
				FrameData[Frame.Time] = {}

				for _, Part in Frame:GetDescendants() do
					table.insert(FrameData[Frame.Time], Part)
				end
			end

			AnimationThread = task.spawn(function()
				while true do
					for i, Time in FrameTimes do
						if not IsDescendantOf(FakeRig, Workspace) then
							table.clear(FrameTimes)
							table.clear(FrameData)

							break 
						end

						local FrameParts = FrameData[Time]

						for _, KeyFramePart in FrameParts do
							local Joint = Joints[KeyFramePart.Name]
							if Joint then
								Joint.Transform = KeyFramePart.CFrame
							end
						end

						local Next = FrameTimes[i + 1]
						if Next then
							local Delay = Next - Time
							task.wait(Delay / 1.75)
						end
					end

					task.wait()
				end
			end)
		end,

		Stop = function()
			if AnimationThread then
				task.cancel(AnimationThread)
			end
			if CurrentAnimation then
				Destroy(CurrentAnimation)
			end
			for Name, Joint in Joints do
				Joint.Transform = JointsOffsets[Name]
			end

			table.clear(FrameTimes)
			table.clear(FrameData)

			local Animate = FindFirstChild(FakeRig, "Animate")

			if Animate then
				Animate.Enabled = ReanimateConfig.Animations
			end
		end
	},

	StartReanimate = StartReanimate,
	InstantRefit = RefitRig,
	StopReanimate = CancelScript
}
