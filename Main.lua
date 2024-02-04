	--[[ 
	Krypton's Rework Release.
  Release: 1.0.0
	Author: @xyzkade / https://discord.gg/A7VexVaZDA
]]
local Global = (getgenv and getgenv()) or getfenv(0) or _G
local Tick = tick()
local Settings = Global.KryptonReanimateConfig
local Wait = task.wait
local Delay = task.delay
local Defer = task.defer

local Clock = os.clock
local MathCos = math.cos
local MathSin = math.sin
local MathRad = math.rad
local MathRand = math.random
local NewInstance = Instance.new

local TClear = table.clear

local Vector3New = Vector3.new
local CFrameNew = CFrame.new
local CFAngles = CFrame.Angles
local CFZero = CFrame.identity
local CFAnti = CFZero

local Vector3zero = Vector3.zero
local LimbSize = Vector3New(1, 2, 1)
local TorsoSize = Vector3New(2, 2, 1)
local RotVelocityOffset = Vector3New(0, MathSin(Clock())*5, 0)

local FakeRig = NewInstance("Model")
local FakeHumanoid = nil

local CheckAntiVoid = Settings.AntiVoid or false
local Hats = Settings.Hats
local UsedHats = {}
local Descendants = {}
local Children = {}
local FakeRigDescendants = {}

local StarterGui = game:FindFirstChildOfClass("StarterGui")
local RunService = game:FindFirstChildOfClass("RunService")
local Workspace = game:FindFirstChildOfClass("Workspace")
local Players = game:FindFirstChildOfClass("Players")

local SpawnPoint = Workspace:FindFirstChildOfClass("SpawnLocation") and Workspace:FindFirstChildOfClass("SpawnLocation").CFrame * CFrameNew(0,20,0) or CFrameNew(0,20,0)
local FPDH = Workspace.FallenPartsDestroyHeight
local PreSimulation = RunService.PreSimulation
local PostSimulation = RunService.PostSimulation
local PreRender = RunService.PreRender
local Camera = Workspace.CurrentCamera
Workspace.Retargeting = "Disabled"

local AutoRespawn, CameraFix, Main, Noclip
local CreatePart, CreateJoint, CreateAttachment, WFCOC, AlignCFrame, GetTextureID, RecreateHats, AlwaysGetHats; do
	CreatePart = function(Name, Size, Parent)
		local Part = NewInstance("Part")
		Part.Size = Size
		Part.Name = Name
		Part.Transparency = Settings.DebugTransparency
		Part.CanCollide = false
		Part.Parent = Parent; return Part
	end

	CreateJoint = function(Name,Part0,Part1,C0,C1)
		local Joint = NewInstance("Motor6D")
		Joint.Name = Name
		Joint.Part0 = Part0
		Joint.Part1 = Part1
		Joint.C0 = C0
		Joint.C1 = C1
		Joint.Parent = Part0
	end

	CreateAttachment = function(Name, CFrame, Parent)
		local Attachment = NewInstance("Attachment")
		Attachment.Name = Name
		Attachment.CFrame = CFrame
		Attachment.Parent = Parent
	end

	WFCOC = function(Parent, Classname) -- WaitForChildOfClass
		repeat Wait() until Parent:FindFirstChildOfClass(Classname)	
		return Parent:FindFirstChildOfClass(Classname)
	end

	AlignCFrame = function(Part0, Part1, Offset)
		Part0.AssemblyLinearVelocity = Vector3New(Part1.AssemblyLinearVelocity.X * (Part1.Mass * 8), 35 + MathRand(20, 60) / MathRand(8, 15), Part1.AssemblyLinearVelocity.Z * (Part1.Mass * 8))
		Part0.AssemblyAngularVelocity = Part1.AssemblyAngularVelocity

		if Part0.ReceiveAge == 0 then
			Part0.CFrame = Part1.CFrame * CFAnti * Offset
		end
	end

	GetTextureID = function(Mesh)
		local Texture = "TextureId"
		if Mesh:IsA("MeshPart") then
			Texture = "TextureID"
		end; Texture = Mesh[Texture]

		return Texture
	end

	FindAccessory = function(Table, MeshID, TextureID)
		for _,v in pairs(Table) do
			if v:IsA("Accessory") then
				local Handle = v:FindFirstChild("Handle")
				local Mesh = Handle:FindFirstChildOfClass("SpecialMesh") or Handle
				local Texture = GetTextureID(Mesh)

				if Mesh.MeshId == MeshID and Texture == TextureID then
					return Handle
				end
			end
		end
	end

	RecreateHats = function(Table, Table2, Rig)
		for _,v in pairs(Table2) do
			if v:IsA("Accessory") then
				v:Destroy()
			end	
		end

		for _, Accessory in pairs(Table) do
			if Accessory:IsA("Accessory") then
				local Head = Rig:WaitForChild("Head")
				local FakeAccessory = Accessory:Clone()
				local Handle = FakeAccessory:WaitForChild("Handle")
				local OldWeld = Handle:FindFirstChildOfClass("Weld")
				local OldWeldData = {OldWeld.C0, OldWeld.C1, OldWeld.Part1}
				local Attachment = WFCOC(Handle, "Attachment")
				local Weld = NewInstance("Weld")
				OldWeld:Destroy()

				if (not OldWeldData[3]) or (OldWeldData[3] and OldWeldData[3].Name ~= "Head") then 
					if Attachment then
						Weld.C0 = Attachment.CFrame
						Weld.C1 = FakeRig:FindFirstChild(tostring(Attachment), true).CFrame
						Weld.Part1 = FakeRig:FindFirstChild(tostring(Attachment), true).Parent
					else
						Weld.Part1 = Head
						Weld.C1 = CFrameNew(0, Head.Size.Y / 2, 0) * FakeAccessory.AttachmentPoint:Inverse()
					end
				elseif OldWeldData[3] and OldWeldData[3].Name == "Head" then
					Weld.C0 = OldWeldData[1]
					Weld.C1 = OldWeldData[2]
					Weld.Part1 = Head
				end

				Handle.Transparency = Settings.DebugTransparency
				Handle.CFrame = Weld.Part1.CFrame * Weld.C1 * Weld.C0:Inverse()

				Weld.Name = "AccessoryWeld"
				Weld.Part0 = Handle
				Weld.Parent = Handle
				FakeAccessory.Parent = Rig
			end
		end
	end

	StartTheHats = function()	
		for i = 1,#Descendants do
			local Details = nil
			local Handle = Descendants[i]

			if Handle.Name == "Handle" then
				local Mesh = Handle:FindFirstChildOfClass("SpecialMesh") or Handle
				local MeshId = Mesh['MeshId']
				local Texture = GetTextureID(Mesh)

				for Index, Table in pairs(Hats) do
					if (FakeRig:FindFirstChild(Index) and Table.Texture == Texture and Table.Mesh == MeshId) then
						Details = {Index, Table.Offset}
					end
				end

				if Details then
					UsedHats[MeshId] = {Handle, FakeRig[Details[1]], Details[2]}
				else
					local OtherHandle = FindAccessory(FakeRigDescendants, MeshId, Texture)
					UsedHats[MeshId] = {Handle, OtherHandle, CFZero}
				end
			end
		end
	end
	HideChildren = function()
		for _,v in pairs(Children) do
			if v:IsA("BasePart") then
				v.Transparency = 1
			end
		end
	end
end

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

local Humanoid = WFCOC(Character, "Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
Descendants = Character:GetDescendants()
Children = Character:GetChildren()
local FRoot = CreatePart("HumanoidRootPart", TorsoSize, FakeRig)
FakeHumanoid = NewInstance("Humanoid"); FakeHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; FakeHumanoid.Parent = FakeRig

do -- [[ Rig Creation ]] --
	local FHead;
	NewInstance("HumanoidDescription", FakeHumanoid)
	NewInstance("Animator", FakeHumanoid)
	NewInstance("ShirtGraphic", FakeRig)
	NewInstance("Pants", FakeRig)
	NewInstance("Shirt", FakeRig)

	if Settings.R15 == false then
		FakeHumanoid.RigType = Enum.HumanoidRigType.R6
		FakeHumanoid.HipHeight = 2
		local FRightArm = CreatePart("Right Arm", LimbSize, FakeRig)
		local FLeftArm = CreatePart("Left Arm", LimbSize, FakeRig)
		local FRightLeg = CreatePart("Right Leg", LimbSize, FakeRig)
		local FLeftLeg = CreatePart("Left Leg", LimbSize, FakeRig)
		local FTorso = CreatePart("Torso", TorsoSize, FakeRig)
		FHead = CreatePart("Head", Vector3New(2, 1, 1), FakeRig)
		CreateJoint("Neck", FTorso, FHead, CFrameNew(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0), CFrameNew(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
		CreateJoint("RootJoint", FRoot, FTorso, CFrameNew(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0), CFrameNew(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
		CreateJoint("Right Shoulder", FTorso, FRightArm, CFrameNew(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CFrameNew(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
		CreateJoint("Left Shoulder", FTorso, FLeftArm, CFrameNew(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrameNew(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
		CreateJoint("Right Hip", FTorso, FRightLeg, CFrameNew(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0), CFrameNew(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
		CreateJoint("Left Hip", FTorso, FLeftLeg, CFrameNew(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrameNew(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
		CreateAttachment("HairAttachment", CFrameNew(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("HatAttachment", CFrameNew(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("FaceFrontAttachment", CFrameNew(0, 0, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("FaceCenterAttachment", CFrameNew(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("RootAttachment", CFrameNew(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRoot)
		CreateAttachment("LeftShoulderAttachment", CFrameNew(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftArm)
		CreateAttachment("LeftGripAttachment", CFrameNew(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftArm)
		CreateAttachment("RightShoulderAttachment", CFrameNew(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightArm)
		CreateAttachment("RightGripAttachment", CFrameNew(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightArm)
		CreateAttachment("LeftFootAttachment", CFrameNew(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftLeg)
		CreateAttachment("RightFootAttachment", CFrameNew(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightLeg)
		CreateAttachment("NeckAttachment", CFrameNew(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso)
		CreateAttachment("BodyFrontAttachment", CFrameNew(0, 0, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso)
		CreateAttachment("BodyBackAttachment", CFrameNew(0, 0, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso)
		CreateAttachment("LeftCollarAttachment", CFrameNew(-1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso)
		CreateAttachment("RightCollarAttachment", CFrameNew(1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso)
		CreateAttachment("WaistFrontAttachment", CFrameNew(0, -1, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso)
		CreateAttachment("WaistCenterAttachment", CFrameNew(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso)
		CreateAttachment("WaistBackAttachment", CFrameNew(0, -1, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FTorso);
	else
		FakeHumanoid.RigType = Enum.HumanoidRigType.R15
		FakeHumanoid.HipHeight = 2
		FHead = CreatePart("Head", Vector3New(2, 1, 1), FakeRig)
		local FLeftHand = CreatePart("LeftHand", Vector3New(1, 0.3, 1), FakeRig)
		local FRightFoot = CreatePart("RightFoot", Vector3New(1, 0.3, 1), FakeRig)
		local FRightUpperArm = CreatePart("RightUpperArm", Vector3New(1, 1.169, 1), FakeRig)
		local FRightUpperLeg = CreatePart("RightUpperLeg", Vector3New(1, 1.217, 1), FakeRig)
		local FRightHand = CreatePart("RightHand", Vector3New(1, 0.3, 1), FakeRig)
		local FLeftLowerLeg = CreatePart("LeftLowerLeg", Vector3New(1, 1.193, 1), FakeRig)
		local FUpperTorso = CreatePart("UpperTorso", Vector3New(2, 1.6, 1), FakeRig)
		local FLowerTorso = CreatePart("LowerTorso", Vector3New(2, 0.4, 1), FakeRig)
		local FLeftUpperArm = CreatePart("LeftUpperArm", Vector3New(1, 1.169, 1), FakeRig)
		local FLeftUpperLeg = CreatePart("LeftUpperLeg", Vector3New(1, 1.217, 1), FakeRig)
		local FLeftFoot = CreatePart("LeftFoot", Vector3New(1, 0.3, 1), FakeRig)
		local FLeftLowerArm = CreatePart("LeftLowerArm", Vector3New(1, 1.052, 1), FakeRig)
		local FRightLowerArm = CreatePart("RightLowerArm", Vector3New(1, 1.052, 1), FakeRig)
		local FRightLowerLeg = CreatePart("RightLowerLeg", Vector3New(1, 1.193, 1), FakeRig)
		CreateJoint("RightAnkle", FRightLowerLeg, FRightFoot, CFrameNew(0, -0.546999991, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.101999998, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightFoot)
		CreateJoint("RightHip", FLowerTorso, FRightUpperLeg, CFrameNew(0.5, -0.200000003, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.421000004, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightUpperLeg)
		CreateJoint("Waist", FLowerTorso, FUpperTorso, CFrameNew(-0, 0.200000003, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(-0, -0.800000012, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateJoint("LeftElbow", FLeftUpperArm, FLeftLowerArm, CFrameNew(0, -0.333999991, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.259000003, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftLowerArm)
		CreateJoint("Root", FRoot, FLowerTorso, CFrameNew(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(-0, -0.200000003, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateJoint("RightWrist", FRightLowerArm, FRightHand, CFrameNew(0, -0.500999987, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightHand)
		CreateJoint("RightElbow", FRightUpperArm, FRightLowerArm, CFrameNew(-0, -0.333999991, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.259000003, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightLowerArm)
		CreateJoint("LeftHip", FLowerTorso, FLeftUpperLeg, CFrameNew(-0.5, -0.200000003, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.421000004, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftUpperLeg)
		CreateJoint("LeftWrist", FLeftLowerArm, FLeftHand, CFrameNew(0, -0.500999987, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftHand)
		CreateJoint("Neck", FUpperTorso, FHead, CFrameNew(-0, 0.800000012, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, -0.490999997, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateJoint("RightShoulder", FUpperTorso, FRightUpperArm, CFrameNew(1, 0.563000023, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(-0.5, 0.393999994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightUpperArm)
		CreateJoint("RightKnee", FRightUpperLeg, FRightLowerLeg, CFrameNew(0, -0.400999993, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.379000008, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightLowerLeg)
		CreateJoint("LeftKnee", FLeftUpperLeg, FLeftLowerLeg, CFrameNew(0, -0.400999993, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0, 0.379000008, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftLowerLeg)
		CreateJoint("LeftShoulder", FUpperTorso, FLeftUpperArm, CFrameNew(-1, 0.563000023, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(0.5, 0.393999994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftUpperArm)
		CreateJoint("LeftAnkle", FLeftLowerLeg, FLeftFoot, CFrameNew(-0, -0.546999991, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrameNew(-0, 0.101999998, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftFoot)
		CreateAttachment("RightHipRigAttachment", CFrameNew(0, 0.421, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightUpperLeg)
		CreateAttachment("RightKneeRigAttachment", CFrameNew(0, -0.400, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightUpperLeg)
		CreateAttachment("LeftElbowRigAttachment", CFrameNew(0, 0.259, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftLowerArm)
		CreateAttachment("LeftWristRigAttachment", CFrameNew(0, -0.500, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftLowerArm)
		CreateAttachment("LeftAnkleRigAttachment", CFrameNew(-0, 0.101, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftFoot)
		CreateAttachment("FaceCenterAttachment", CFrameNew(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("FaceFrontAttachment", CFrameNew(0, 0, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("HairAttachment", CFrameNew(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("HatAttachment", CFrameNew(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("NeckRigAttachment", CFrameNew(0, -0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FHead)
		CreateAttachment("LeftShoulderRigAttachment", CFrameNew(0.5, 0.393, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftUpperArm)
		CreateAttachment("LeftElbowRigAttachment", CFrameNew(0, -0.333, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftUpperArm)
		CreateAttachment("LeftShoulderAttachment", CFrameNew(0, 0.583, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftUpperArm)
		CreateAttachment("RootRigAttachment", CFrameNew(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRoot)
		CreateAttachment("RightAnkleRigAttachment", CFrameNew(0, 0.101, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightFoot)
		CreateAttachment("RightElbowRigAttachment", CFrameNew(0, 0.259, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightLowerArm)
		CreateAttachment("RightWristRigAttachment", CFrameNew(0, -0.5, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightLowerArm)
		CreateAttachment("LeftWristRigAttachment", CFrameNew(0, 0.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftHand)
		CreateAttachment("LeftGripAttachment", CFrameNew(0, -0.15, -0, 1, 0, 0, 0, 0, 1, 0, -1, 0), FLeftHand)
		CreateAttachment("RightShoulderRigAttachment", CFrameNew(-0.5, 0.393, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightUpperArm)
		CreateAttachment("RightElbowRigAttachment", CFrameNew(-0, -0.333, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightUpperArm)
		CreateAttachment("RightShoulderAttachment", CFrameNew(-0, 0.583, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightUpperArm)
		CreateAttachment("WaistRigAttachment", CFrameNew(-0, -0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("NeckRigAttachment", CFrameNew(-0, 0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("LeftShoulderRigAttachment", CFrameNew(-1, 0.563, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("RightShoulderRigAttachment", CFrameNew(1, 0.563, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("BodyFrontAttachment", CFrameNew(-0, -0.200, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("BodyBackAttachment", CFrameNew(-0, -0.200, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("LeftCollarAttachment", CFrameNew(-1, 0.800, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("RightCollarAttachment", CFrameNew(1, 0.800, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("NeckAttachment", CFrameNew(-0, 0.800, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FUpperTorso)
		CreateAttachment("RightKneeRigAttachment", CFrameNew(0, 0.379, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightLowerLeg)
		CreateAttachment("RightAnkleRigAttachment", CFrameNew(0, -0.547, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightLowerLeg)
		CreateAttachment("RootRigAttachment", CFrameNew(-0, -0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateAttachment("WaistRigAttachment", CFrameNew(-0, 0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateAttachment("LeftHipRigAttachment", CFrameNew(-0.5, -0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateAttachment("RightHipRigAttachment", CFrameNew(0.5, -0.2, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateAttachment("WaistCenterAttachment", CFrameNew(-0, -0.2, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateAttachment("WaistFrontAttachment", CFrameNew(-0, -0.2, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateAttachment("WaistBackAttachment", CFrameNew(-0, -0.2, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLowerTorso)
		CreateAttachment("LeftKneeRigAttachment", CFrameNew(0, 0.379, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftLowerLeg)
		CreateAttachment("LeftAnkleRigAttachment", CFrameNew(-0, -0.546, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftLowerLeg)
		CreateAttachment("LeftHipRigAttachment", CFrameNew(0, 0.421, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftUpperLeg)
		CreateAttachment("LeftKneeRigAttachment", CFrameNew(0, -0.4, -0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FLeftUpperLeg)
		CreateAttachment("RightWristRigAttachment", CFrameNew(0, 0.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), FRightHand)
		CreateAttachment("RightGripAttachment", CFrameNew(0, -0.15, -0, 1, 0, 0, 0, 0, 1, 0, -1, 0), FRightHand)

		local function ReplaceTableName(OldName, Name)
			if Hats[OldName] then
				Hats[Name] = Hats[OldName]
				Hats[OldName] = nil
			end
		end

		ReplaceTableName("Right Arm", "RightLowerArm")
		ReplaceTableName("Left Arm", "LeftLowerArm")
		ReplaceTableName("Right Leg", "RightLowerLeg")
		ReplaceTableName("Left Leg", "LeftLowerLeg")
		ReplaceTableName("Torso", "LowerTorso")
	end

	local Face = NewInstance("Decal"); Face.Name = "face"; Face.Texture = "rbxasset://textures/face.png"; Face.Transparency = 1; Face.Parent = FHead
	local HeadMesh = NewInstance("SpecialMesh"); HeadMesh.Scale = Vector3New(1.25, 1.25, 1.25); HeadMesh.Parent = FHead
	local Animate = NewInstance("LocalScript"); Animate.Name = "Animate"; Animate.Parent = FakeRig
	local Health = NewInstance("Script"); Health.Name = "Health"; Health.Parent = FakeRig

	RecreateHats(Descendants, {}, FakeRig)
	FakeRigDescendants = FakeRig:GetDescendants()
	Character.Archivable = true
	FakeRig.Name = "FakeRig"
	FakeRig.PrimaryPart = FHead
	FakeRig.Parent = Workspace
end

do -- [[ Events ]]
	local HideChar = Settings.HideRealChar
	if HideChar then
		HideChildren()
	end

	AutoRespawn = LocalPlayer.CharacterAdded:Connect(function()
		TClear(UsedHats)
		Character = LocalPlayer.Character
		RootPart = Character:WaitForChild("HumanoidRootPart")
		RootPart.CFrame = FRoot.CFrame * CFrameNew(MathRand(-20, 20), 0, MathRand(-20, 20))	
		Humanoid = WFCOC(Character, "Humanoid")
		WFCOC(Character, "Accessory")
		Wait(Settings.WaitTime); PostSimulation:Wait()

		FakeRigDescendants = FakeRig:GetDescendants()
		Children = Character:GetChildren()
		Descendants = Character:GetDescendants()
		RecreateHats(Descendants, FakeRigDescendants, FakeRig)
		FakeRigDescendants = FakeRig:GetDescendants()

		if HideChar then
			HideChildren()
		end

		RootPart.Velocity = Vector3zero
		Character.Parent = FakeRig -- Make the first person mode better
		Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		StartTheHats()
	end)

	CameraFix = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(function() -- [[ Camera Fix]]
		local CFrameCF = Camera.CFrame
		Camera.CameraSubject = FakeHumanoid
		PreRender:Once(function()
			Camera.CFrame = CFrameCF	
		end)
	end)

	Noclip = PreSimulation:Connect(function()
		for i=1,#Descendants do
			local x = Descendants[i]

			if x and x.Parent and x:IsA("BasePart") then
				x.CanCollide = false
				x.CanQuery = false
				x.CanTouch = false
			end
		end

		if CheckAntiVoid and FRoot and FRoot.Position.Y <= (FPDH + 75)  then
			FRoot.CFrame = SpawnPoint
			FRoot.Velocity = Vector3zero
		end
	end)

	Main = PostSimulation:Connect(function()
		for _, Data in pairs(UsedHats) do
			local Handle = Data[1]
			local HandleTo = Data[2]
			local Offset = Data[3]

			if Handle and Handle.Parent and HandleTo and HandleTo.Parent and Offset then
				AlignCFrame(Handle, HandleTo, Offset)
			end
		end

		FakeHumanoid:Move(Humanoid.MoveDirection, false)
		FakeHumanoid.Jump = Humanoid.Jump

		RotVelocityOffset = Vector3New(0, MathSin(Clock())*5, 0)
		CFAnti = CFrameNew(0.0065 * MathSin(Clock()*32), 0, 0.0065 * MathCos(Clock()*32))
	end)
end

do -- [[ Stop Events ]] --
	local Method = Settings.StopMethod or "Reset"
	local StopMSG = Settings.StopMessage or "/e stop"

	local function EndItAll()
		CameraFix:Disconnect()
		Main:Disconnect()
		AutoRespawn:Disconnect()
		Noclip:Disconnect()

		Camera.CameraSubject = Humanoid
		LocalPlayer.Character = Character
		FakeRig:Destroy()
		StarterGui:SetCore("ResetButtonCallback", true)

		pcall(function()
			script.Disabled = true
		end)
	end

	if Method == "Reset" or Method == "Both" then
		local BindableEvent = NewInstance("BindableEvent")
		BindableEvent.Event:Connect(EndItAll)
		StarterGui:SetCore("ResetButtonCallback", BindableEvent)
	end

	if Method == "Chat" or Method == "Both" then
		local Chatted; Chatted = LocalPlayer.Chatted:Connect(function(Message)
			if Message == StopMSG then
				EndItAll()
				Chatted:Disconnected()
			end
		end)		
	end

	FakeHumanoid.Died:Connect(EndItAll)
	Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	Camera.CameraSubject = FakeHumanoid
	Character.Parent = FakeRig
end

if Settings.DebugPrints then
	warn("Time Elapsed:", tick()-Tick)
end

StartTheHats()

return FakeRig
