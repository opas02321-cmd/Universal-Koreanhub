-- Korean Hub (Fly Fixed & All Features Included)
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    return
end

local Window = Rayfield:CreateWindow({
    Name = "KoreanHub · Recorder Forward Fix",
    Theme = "Default",
    LoadingTitle = "Loading Korean Hub...",
    LoadingSubtitle = "by delta",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KoreanHubConfigs",
        FileName = "KoreanHubConfig"
    },
    KeySystem = true,
    KeySettings = {
        Title = "Korean Hub Key System",
        Subtitle = "Enter Key to Access",
        Note = "Key is: DeltaOnTop",
        FileName = "KoreanHubKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"DeltaOnTop"}
    }
})

-- Tabs Creation
local MovementTab = Window:CreateTab("Movement", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local PerfTab = Window:CreateTab("Performance", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- Auto Flags: every element gets a Flag so configs can save it
local function autoFlag(tab, prefix)
    for _, method in ipairs({"CreateToggle", "CreateSlider", "CreateDropdown", "CreateInput"}) do
        local original = tab[method]
        tab[method] = function(self, opts)
            if not opts.Flag then
                opts.Flag = prefix .. "_" .. (opts.Name:gsub("[^%w]", ""))
            end
            return original(self, opts)
        end
    end
end

autoFlag(MovementTab, "Move")
autoFlag(CombatTab, "Combat")
autoFlag(VisualsTab, "Visual")
autoFlag(ESPTab, "ESP")
autoFlag(PerfTab, "Perf")
autoFlag(MiscTab, "Misc")

local function notify(title, content)
    Rayfield:Notify({ Title = title, Content = content, Duration = 4 })
end

-- Services & Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global Feature States
_G.WalkSpeedVal = 16
_G.JumpPowerVal = 50
_G.LoopSpeed = false
_G.LoopJumpPower = false
_G.InfJump = false
_G.Noclip = false
_G.FlyEnabled = false
_G.FlySpeed = 50
_G.FlyTilt = 0
_G.NoFallDamage = true

_G.AimbotEnabled = false
_G.AimPart = "Head"
_G.AimbotSmoothness = 1
_G.FOVCircle = false
_G.FOVSize = 100
_G.AimbotTeamCheck = true
_G.PlayerLock = false
_G.Spinbot = false
_G.SpinSpeed = 50
_G.GodMode = false
_G.TouchFling = false
_G.AutoClicker = false
_G.HitboxExpander = false
_G.HitboxSize = 5

_G.Invisibility = false
_G.Fullbright = false
_G.FullbrightIntensity = 2
_G.Freecam = false

_G.ESPEnabled = false
_G.ESPTeamCheck = true
_G.BoxESP = false
_G.TracerESP = false
_G.SkeletonESP = false

-- FOV Circle Drawing object
local fovDrawing = Drawing.new("Circle")
fovDrawing.Visible = false
fovDrawing.Filled = false
fovDrawing.Thickness = 1
fovDrawing.Color = Color3.fromRGB(255, 255, 255)
fovDrawing.Transparency = 0.7

------------------------------------------------------------------
-- 1. Movement Tab
------------------------------------------------------------------
local walkSpeedSlider = MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 350},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        _G.WalkSpeedVal = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end,
})

MovementTab:CreateInput({
    Name = "Type WalkSpeed",
    CurrentValue = "",
    PlaceholderText = "16-350 (press Enter)",
    RemoveTextAfterFocusLost = false,
    Flag = "Move_TypeWalkSpeed",
    Callback = function(text)
        local number = tonumber(text)
        if not number or number ~= number then return end
        local speed = math.clamp(math.floor(number + 0.5), 16, 350)
        walkSpeedSlider:Set(speed)
    end,
})

local jumpPowerSlider = MovementTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        _G.JumpPowerVal = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = true
            LocalPlayer.Character.Humanoid.JumpPower = v
        end
    end,
})

MovementTab:CreateInput({
    Name = "Type JumpPower",
    CurrentValue = "",
    PlaceholderText = "50-300 (press Enter)",
    RemoveTextAfterFocusLost = false,
    Flag = "Move_TypeJumpPower",
    Callback = function(text)
        local number = tonumber(text)
        if not number or number ~= number or number == math.huge or number == -math.huge then return end
        jumpPowerSlider:Set(math.clamp(math.floor(number + 0.5), 50, 300))
    end,
})

-- Visual desync: show a local-only copy offset from the actual character.
do
    if type(_G.KoreanHubVisualDesyncCleanup) == "function" then
        _G.KoreanHubVisualDesyncCleanup()
    end
    local enabled, distance, ghost, source = false, 8, nil, nil
    local mode, frozen, freezeUntil = "Fake Position", nil, 0
    local hidden = {}
    local connection

    local function restore()
        for part, previous in pairs(hidden) do
            if part.Parent then part.LocalTransparencyModifier = previous end
            hidden[part] = nil
        end
        if ghost then ghost:Destroy(); ghost = nil end
        source, frozen, freezeUntil = nil, nil, 0
    end

    local function build(character)
        restore()
        if not character then return end
        local oldArchivable = character.Archivable
        character.Archivable = true
        local ok, copy = pcall(function() return character:Clone() end)
        character.Archivable = oldArchivable
        if not ok or not copy then return end
        copy.Name = "KoreanHubVisualDesync"
        for _, object in ipairs(copy:GetDescendants()) do
            if object:IsA("LuaSourceContainer") or object:IsA("Tool") then
                object:Destroy()
            elseif object:IsA("BasePart") then
                object.Anchored = true
                object.CanCollide = false
                object.CanTouch = false
                object.CanQuery = false
            end
        end
        copy.Parent = workspace
        ghost, source = copy, character
    end

    local function update()
        if not enabled then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then restore(); return end
        if character ~= source or not ghost or not ghost.Parent then build(character) end
        if not ghost then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and hidden[part] == nil then
                hidden[part] = part.LocalTransparencyModifier
                part.LocalTransparencyModifier = 1
            end
        end
        local actual = character:GetPivot()
        if mode == "Rotation Jitter" then
            ghost:PivotTo(actual * CFrame.Angles(0, math.sin(os.clock() * 18) * math.rad(100), 0))
        elseif mode == "Brief Freeze" then
            local now = os.clock()
            if not frozen then
                frozen, freezeUntil = actual, now + 0.45
            elseif now >= freezeUntil then
                frozen, freezeUntil = actual, now + 1.2
            end
            ghost:PivotTo(frozen)
        else
            ghost:PivotTo(actual * CFrame.new(distance, 0, 0))
        end
    end

    MovementTab:CreateToggle({
        Name = "Visual Desync (Local Copy)",
        CurrentValue = false,
        Flag = "Move_VisualDesync",
        Callback = function(state)
            enabled = state
            if state then update() else restore() end
        end,
    })
    MovementTab:CreateDropdown({
        Name = "Desync Mode",
        Options = {"Fake Position", "Rotation Jitter", "Brief Freeze"},
        CurrentOption = {"Fake Position"},
        MultipleOptions = false,
        Flag = "Move_DesyncMode",
        Callback = function(option)
            mode = type(option) == "table" and option[1] or option
            frozen, freezeUntil = nil, 0
        end,
    })
    MovementTab:CreateSlider({
        Name = "Desync Visual Offset",
        Range = {2, 30},
        Increment = 1,
        CurrentValue = 8,
        Callback = function(value) distance = value end,
    })
    connection = RunService.RenderStepped:Connect(update)
    _G.KoreanHubVisualDesyncCleanup = function()
        enabled = false
        connection:Disconnect()
        restore()
    end
end

-- Keep the selected movement values applied, including after respawn.
do
    local function applyLoopMovement()
        if not (_G.LoopSpeed or _G.LoopJumpPower) then return end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        if _G.LoopSpeed and humanoid.WalkSpeed ~= _G.WalkSpeedVal then
            humanoid.WalkSpeed = _G.WalkSpeedVal
        end
        if _G.LoopJumpPower then
            if not humanoid.UseJumpPower then humanoid.UseJumpPower = true end
            if humanoid.JumpPower ~= _G.JumpPowerVal then
                humanoid.JumpPower = _G.JumpPowerVal
            end
        end
    end

    MovementTab:CreateToggle({
        Name = "Loop Speed",
        CurrentValue = false,
        Flag = "Move_LoopSpeed",
        Callback = function(state)
            _G.LoopSpeed = state
            if state then applyLoopMovement() end
        end,
    })

    MovementTab:CreateToggle({
        Name = "Loop Jump Power",
        CurrentValue = false,
        Flag = "Move_LoopJumpPower",
        Callback = function(state)
            _G.LoopJumpPower = state
            if state then applyLoopMovement() end
        end,
    })

    if _G.KoreanHubMovementLoopConnection then
        _G.KoreanHubMovementLoopConnection:Disconnect()
    end
    _G.KoreanHubMovementLoopConnection = RunService.Heartbeat:Connect(applyLoopMovement)
end

-- Move the actual character during local movement stuns.
do
    if type(_G.KoreanHubStunAssistCleanup) == "function" then
        _G.KoreanHubStunAssistCleanup()
    elseif _G.KoreanHubStunAssistConnection then
        _G.KoreanHubStunAssistConnection:Disconnect()
    end
    local stunAssist, elapsed, recoverUntil = false, 0, 0
    local touchConnections = {}
    local joystickTouch, joystickStart, joystickVector = nil, nil, Vector2.zero
    local controls
    local function getControls()
        if controls then return controls end
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local module = scripts and scripts:FindFirstChild("PlayerModule")
        if module then
            local ok, playerModule = pcall(require, module)
            if ok and playerModule then
                local worked, value = pcall(function() return playerModule:GetControls() end)
                if worked then controls = value end
            end
        end
        return controls
    end
    if UserInputService.TouchEnabled then
        -- Read movement from the same lower-left touch used by Roblox's joystick.
        table.insert(touchConnections, UserInputService.TouchStarted:Connect(function(input)
            local camera = workspace.CurrentCamera
            local view = camera and camera.ViewportSize
            if stunAssist and view and not joystickTouch
                and input.Position.X < view.X * 0.45 and input.Position.Y > view.Y * 0.4 then
                joystickTouch, joystickStart = input, input.Position
                joystickVector = Vector2.zero
            end
        end))
        table.insert(touchConnections, UserInputService.TouchMoved:Connect(function(input)
            if input == joystickTouch then
                local delta = (input.Position - joystickStart) / 65
                joystickVector = delta.Magnitude > 1 and delta.Unit or delta
            end
        end))
        table.insert(touchConnections, UserInputService.TouchEnded:Connect(function(input)
            if input == joystickTouch then
                joystickTouch, joystickStart, joystickVector = nil, nil, Vector2.zero
            end
        end))
    end
    MovementTab:CreateToggle({
        Name = "Move While Stunned (Body)",
        CurrentValue = false,
        Flag = "Move_StunMovementAssist",
        Callback = function(value)
            stunAssist = value
            if not value then
                recoverUntil = 0
                joystickTouch, joystickStart, joystickVector = nil, nil, Vector2.zero
            end
        end,
    })
    local connection = RunService.Heartbeat:Connect(function(dt)
        if not stunAssist or _G.FlyEnabled then elapsed = 0; return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return end
        local now = os.clock()
        local state = humanoid:GetState()
        local blocked = root.Anchored or humanoid.PlatformStand or humanoid.WalkSpeed < 1
            or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.PlatformStanding
        if blocked then recoverUntil = now + 0.5 end
        elapsed = elapsed + dt
        if elapsed >= 0.1 then
            elapsed = 0
            if root.Anchored then root.Anchored = false end
            if humanoid.PlatformStand then humanoid.PlatformStand = false end
            if humanoid.Sit then humanoid.Sit = false end
            if humanoid.WalkSpeed < _G.WalkSpeedVal then humanoid.WalkSpeed = _G.WalkSpeedVal end
            if not humanoid.UseJumpPower then humanoid.UseJumpPower = true end
            if humanoid.JumpPower < _G.JumpPowerVal then humanoid.JumpPower = _G.JumpPowerVal end
            if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.PlatformStanding then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
        if now > recoverUntil then return end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
        if forward.Magnitude < 0.01 then return end
        forward = forward.Unit
        local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit
        local f, r = 0, 0
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then f = f + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then f = f - 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then r = r + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then r = r - 1 end
        local direction = forward * f + right * r
        if direction.Magnitude < 0.01 then
            local control = getControls()
            if control then
                local ok, vector = pcall(function() return control:GetMoveVector() end)
                if ok and vector and vector.Magnitude > 0.01 then
                    direction = right * vector.X - forward * vector.Z
                end
            end
        end
        if direction.Magnitude < 0.01 and joystickVector.Magnitude > 0.05 then
            direction = right * joystickVector.X - forward * joystickVector.Y
        end
        if direction.Magnitude < 0.01 then direction = humanoid.MoveDirection end
        if direction.Magnitude < 0.01 then return end
        local delta = direction.Unit * math.min(_G.WalkSpeedVal, 50) * math.min(dt, 0.05)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        local hit = workspace:Raycast(root.Position, delta.Unit * (delta.Magnitude + 1.5), params)
        if not hit then character:PivotTo(character:GetPivot() + delta) end
    end)
    _G.KoreanHubStunAssistConnection = connection
    _G.KoreanHubStunAssistCleanup = function()
        connection:Disconnect()
        for _, item in ipairs(touchConnections) do item:Disconnect() end
    end
end

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(state)
        _G.InfJump = state
    end,
})

UserInputService.JumpRequest:Connect(function()
    if _G.InfJump and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(state)
        _G.Noclip = state
    end,
})

RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Fly variables and logic
local flyConnection = nil
local flyBV = nil
local flyBG = nil

-- Fly animations: an idle pose while hovering, a movement animation while moving
local FLY_POSES = {
    ["Float"] = { R15 = 507785072,  R6 = 180435571 },
    ["Swim"]  = { R15 = 507784897,  R6 = 180436148 },
    ["Run"]   = { R15 = 507767714,  R6 = 180426354 },
    ["Walk"]  = { R15 = 507777826,  R6 = 180426354 },
    ["Fall"]  = { R15 = 507767968,  R6 = 180436148 },
    ["Jump"]  = { R15 = 507765000,  R6 = 125750702 },
    ["Sit"]   = { R15 = 2506281703, R6 = 178130996 },
    ["Climb"] = { R15 = 507765644,  R6 = 180436334 },
    ["Dance 1"] = { R15 = 507771019, R6 = 182435998 },
    ["Dance 2"] = { R15 = 507776043, R6 = 182491037 },
    ["Dance 3"] = { R15 = 507777268, R6 = 182491065 },
}
local flyPoseName = "Float"
local flyCustomPoseId = ""
local flyMoveName = "Swim"
local flyCustomMoveId = ""
local flyPoseTrack = nil
local flyMoveTrack = nil
local flyIsMoving = false

local function destroyTrack(track)
    if track then
        pcall(function()
            track:Stop()
            track:Destroy()
        end)
    end
end

local function loadFlyTrack(hum, name, customId)
    local id
    if name == "Custom ID" then
        id = tonumber(customId)
    elseif FLY_POSES[name] then
        local isR15 = hum.RigType == Enum.HumanoidRigType.R15
        id = isR15 and FLY_POSES[name].R15 or FLY_POSES[name].R6
    end
    if not id then return nil end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(id)

    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then return nil end

    track.Priority = Enum.AnimationPriority.Action
    track.Looped = true
    return track
end

-- Moving plays the move animation (if one is set), standing still plays the idle pose
local function updateFlyAnim()
    local wantMove = flyIsMoving and flyMoveTrack ~= nil
    if wantMove then
        if flyPoseTrack and flyPoseTrack.IsPlaying then flyPoseTrack:Stop(0.2) end
        if not flyMoveTrack.IsPlaying then flyMoveTrack:Play(0.2) end
    else
        if flyMoveTrack and flyMoveTrack.IsPlaying then flyMoveTrack:Stop(0.2) end
        if flyPoseTrack and not flyPoseTrack.IsPlaying then flyPoseTrack:Play(0.2) end
    end
end

local function setFlyMoving(moving)
    if moving ~= flyIsMoving then
        flyIsMoving = moving
        updateFlyAnim()
    end
end

local function stopFlyPose()
    destroyTrack(flyPoseTrack)
    destroyTrack(flyMoveTrack)
    flyPoseTrack = nil
    flyMoveTrack = nil
    flyIsMoving = false
end

local function playFlyPose()
    destroyTrack(flyPoseTrack)
    destroyTrack(flyMoveTrack)
    flyPoseTrack = nil
    flyMoveTrack = nil
    if not _G.FlyEnabled then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if flyPoseName ~= "None (T-Pose)" then
        flyPoseTrack = loadFlyTrack(hum, flyPoseName, flyCustomPoseId)
    end
    if flyMoveName ~= "None" then
        flyMoveTrack = loadFlyTrack(hum, flyMoveName, flyCustomMoveId)
    end
    updateFlyAnim()
end

local function stopFly()
    stopFlyPose()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyBV then
        flyBV:Destroy()
        flyBV = nil
    end
    if flyBG then
        flyBG:Destroy()
        flyBG = nil
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then hum.PlatformStand = false end
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

local function startFly()
    stopFly()

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "HubFlyVelocity"
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "HubFlyGyro"
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 30000
    flyBG.D = 1000
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp

    local flyTilt = 0

    flyConnection = RunService.RenderStepped:Connect(function(dt)
        if not _G.FlyEnabled or not hrp.Parent or not hum.Parent then return end

        local camCF = Camera.CFrame
        local look = camCF.LookVector

        -- Horizontal camera axes, used to read the joystick / WASD input
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.01 then
            flatLook = Vector3.new(camCF.UpVector.X, 0, camCF.UpVector.Z)
        end
        if flatLook.Magnitude < 0.01 then return end
        flatLook = flatLook.Unit
        local flatRight = Vector3.new(-flatLook.Z, 0, flatLook.X)

        -- MoveDirection is already in world space, so split it along the camera axes
        local input = hum.MoveDirection
        local fwd = input:Dot(flatLook)
        local rgt = input:Dot(flatRight)

        if input.Magnitude < 0.01 then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then fwd = fwd + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then fwd = fwd - 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then rgt = rgt + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then rgt = rgt - 1 end
            local mag = math.sqrt(fwd * fwd + rgt * rgt)
            if mag > 1 then
                fwd = fwd / mag
                rgt = rgt / mag
            end
        end

        -- Forward follows the full camera direction, so looking up or down climbs or dives
        local targetVel = (look * fwd + camCF.RightVector * rgt) * _G.FlySpeed

        -- Jump button / Space = up, Left Ctrl = down
        local vertical = 0
        if hum.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = vertical + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = vertical - 1 end
        targetVel = targetVel + Vector3.new(0, vertical * _G.FlySpeed, 0)

        setFlyMoving(math.abs(fwd) > 0.05 or math.abs(rgt) > 0.05 or vertical ~= 0)

        -- Smooth acceleration and braking
        flyBV.Velocity = flyBV.Velocity:Lerp(targetVel, math.clamp(dt * 12, 0, 1))

        -- Face where the camera looks, lean forward while moving forward (Fly Tilt)
        local tiltTarget = math.rad(_G.FlyTilt) * math.clamp(fwd, 0, 1)
        flyTilt = flyTilt + (tiltTarget - flyTilt) * math.clamp(dt * 8, 0, 1)
        flyBG.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook) * CFrame.Angles(-flyTilt, 0, 0)
    end)

    playFlyPose()
end

MovementTab:CreateToggle({
    Name = "Fly Hack",
    CurrentValue = false,
    Callback = function(state)
        _G.FlyEnabled = state
        if state then
            startFly()
        else
            stopFly()
        end
    end,
})

-- Keep flying after a respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if not _G.FlyEnabled then return end
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    if _G.FlyEnabled then startFly() end
end)

local flySpeedSlider = MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        _G.FlySpeed = v
    end,
})

MovementTab:CreateInput({
    Name = "Type Fly Speed",
    CurrentValue = "",
    PlaceholderText = "1-300 (press Enter)",
    RemoveTextAfterFocusLost = false,
    Flag = "Move_TypeFlySpeed",
    Callback = function(text)
        local number = tonumber(text)
        if not number or number ~= number or number == math.huge or number == -math.huge then return end
        flySpeedSlider:Set(math.clamp(math.floor(number + 0.5), 1, 300))
    end,
})

MovementTab:CreateDropdown({
    Name = "Fly Pose",
    Options = {"None (T-Pose)", "Float", "Swim", "Run", "Walk", "Fall", "Jump", "Sit", "Custom ID"},
    CurrentOption = {"Float"},
    MultipleOptions = false,
    Callback = function(option)
        flyPoseName = type(option) == "table" and option[1] or option
        if _G.FlyEnabled then playFlyPose() end
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Tilt",
    Range = {0, 90},
    Increment = 5,
    CurrentValue = 0,
    Callback = function(v)
        _G.FlyTilt = v
    end,
})

MovementTab:CreateInput({
    Name = "Custom Pose ID",
    PlaceholderText = "Animation asset ID",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        flyCustomPoseId = text:match("%d+") or ""
        if _G.FlyEnabled and flyPoseName == "Custom ID" then playFlyPose() end
    end,
})

MovementTab:CreateDropdown({
    Name = "Fly Move Animation",
    Options = {"None", "Swim", "Run", "Walk", "Fall", "Jump", "Float", "Sit", "Custom ID"},
    CurrentOption = {"Swim"},
    MultipleOptions = false,
    Callback = function(option)
        flyMoveName = type(option) == "table" and option[1] or option
        if _G.FlyEnabled then playFlyPose() end
    end,
})

MovementTab:CreateInput({
    Name = "Custom Move ID",
    PlaceholderText = "Animation asset ID",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        flyCustomMoveId = text:match("%d+") or ""
        if _G.FlyEnabled and flyMoveName == "Custom ID" then playFlyPose() end
    end,
})

-- Walk Animation: replaces the default walk/run animation while walking on the ground
local walkAnimName = "None"
local walkCustomId = ""
local walkAnimSpeed = 1
local walkTrack = nil

local function refreshWalkTrack()
    destroyTrack(walkTrack)
    walkTrack = nil
    if walkAnimName == "None" then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    walkTrack = loadFlyTrack(hum, walkAnimName, walkCustomId)
end

RunService.Heartbeat:Connect(function()
    if not walkTrack then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Only on the ground, not flying, not sitting; the default jump and fall animations stay untouched
    local walking = not _G.FlyEnabled
        and hum.Health > 0
        and not hum.Sit
        and hum.FloorMaterial ~= Enum.Material.Air
        and hum.MoveDirection.Magnitude > 0.1

    if walking then
        walkTrack:AdjustSpeed(walkAnimSpeed * math.clamp(hum.WalkSpeed / 16, 0.5, 3))
        if not walkTrack.IsPlaying then walkTrack:Play(0.15) end
    elseif walkTrack.IsPlaying then
        walkTrack:Stop(0.15)
    end
end)

-- The old track belonged to the previous character, so load a fresh one after respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    walkTrack = nil
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    refreshWalkTrack()
end)

MovementTab:CreateDropdown({
    Name = "Walk Animation",
    Options = {"None", "Walk", "Run", "Swim", "Float", "Fall", "Jump", "Sit", "Climb", "Dance 1", "Dance 2", "Dance 3", "Custom ID"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Callback = function(option)
        walkAnimName = type(option) == "table" and option[1] or option
        refreshWalkTrack()
    end,
})

MovementTab:CreateSlider({
    Name = "Walk Animation Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(v)
        walkAnimSpeed = v
    end,
})

MovementTab:CreateInput({
    Name = "Custom Walk ID",
    PlaceholderText = "Animation asset ID",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        walkCustomId = text:match("%d+") or ""
        if walkAnimName == "Custom ID" then refreshWalkTrack() end
    end,
})

-- Click TP: mouse click on PC, quick tap on mobile
local clickTpOn = false
local touchStarts = {}

local function clickTeleport(screenPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ray = Camera:ScreenPointToRay(screenPos.X, screenPos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}

    local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
    if result then
        hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) * hrp.CFrame.Rotation
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not clickTpOn or processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        clickTeleport(input.Position)
    elseif input.UserInputType == Enum.UserInputType.Touch then
        touchStarts[input] = { pos = input.Position, time = os.clock() }
    end
end)

-- A touch only counts as a tap when it barely moved and was short, so camera drags do not teleport you
UserInputService.InputEnded:Connect(function(input)
    local start = touchStarts[input]
    if not start then return end
    touchStarts[input] = nil
    if not clickTpOn then return end
    if (input.Position - start.pos).Magnitude < 12 and os.clock() - start.time < 0.35 then
        clickTeleport(input.Position)
    end
end)

MovementTab:CreateToggle({
    Name = "Click TP",
    CurrentValue = false,
    Callback = function(state)
        clickTpOn = state
        if not state then touchStarts = {} end
    end,
})

------------------------------------------------------------------
-- 2. Combat Tab
------------------------------------------------------------------
CombatTab:CreateToggle({
    Name = "Aimbot (Camera Lock)",
    CurrentValue = false,
    Callback = function(state)
        _G.AimbotEnabled = state
    end,
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Body"},
    CurrentOption = "Head",
    Callback = function(option)
        _G.AimPart = type(option) == "table" and option[1] or option
    end,
})

CombatTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(v)
        _G.AimbotSmoothness = v
    end,
})

CombatTab:CreateToggle({
    Name = "Aimbot Team Check",
    CurrentValue = true,
    Callback = function(state)
        _G.AimbotTeamCheck = state
    end,
})

CombatTab:CreateToggle({
    Name = "Player Lock (Body Rotate)",
    CurrentValue = false,
    Callback = function(state)
        _G.PlayerLock = state
    end,
})

CombatTab:CreateToggle({
    Name = "Spinbot",
    CurrentValue = false,
    Callback = function(state)
        _G.Spinbot = state
    end,
})

CombatTab:CreateSlider({
    Name = "Spin Speed",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        _G.SpinSpeed = v
    end,
})

CombatTab:CreateToggle({
    Name = "God Mode · 로컬 체력 고정 (서버 무적 아님)",
    CurrentValue = false,
    Callback = function(state)
        _G.GodMode = state
    end,
})

CombatTab:CreateToggle({
    Name = "Touch Fling",
    CurrentValue = false,
    Callback = function(state)
        _G.TouchFling = state
    end,
})

CombatTab:CreateToggle({
    Name = "Auto Attack (Nearby Player + Tool)",
    Flag = "Combat_AutoClicker",
    CurrentValue = false,
    Callback = function(state)
        _G.AutoClicker = state
    end,
})

-- One controller owns player hitboxes, equipped-tool geometry and nearby-player attacks.
-- Local part sizes cannot override a game's server-owned range/damage validation.
-- Optional Handle resizing, independent of dedicated hit-part controls.
do
    if type(_G.KoreanHubHandleCleanup)=="function" then pcall(_G.KoreanHubHandleCleanup) end
    local enabled,size=false,30
    local current,snapshot,box=nil,nil,nil
    local colors={Color3.fromRGB(255,0,0),Color3.fromRGB(0,255,0),Color3.fromRGB(0,0,255),Color3.fromRGB(255,255,0)}
    local function restore()
        if box then box:Destroy();box=nil end
        if current and snapshot then
            pcall(function()
                current.Size=snapshot.Size
                current.Transparency=snapshot.Transparency
                current.Massless=snapshot.Massless
            end)
        end
        current,snapshot=nil,nil
    end
    local function apply()
        local char=LocalPlayer.Character
        local tool=char and char:FindFirstChildOfClass("Tool")
        local handle=tool and tool:FindFirstChild("Handle")
        if not enabled or not handle or not handle:IsA("BasePart") then restore();return end
        if current~=handle then
            restore()
            current=handle
            snapshot={Size=handle.Size,Transparency=handle.Transparency,Massless=handle.Massless}
            box=Instance.new("SelectionBox")
            box.Name="KoreanHubHandleOutline";box.Adornee=handle;box.LineThickness=0.025;box.Parent=handle
        end
        handle.Massless=true;handle.Transparency=1;handle.Size=Vector3.new(size,size,size)
        if box then box.Color3=colors[math.floor(os.clock()*2)%#colors+1] end
    end
    CombatTab:CreateSection("툴 Handle 크기 조절")
    CombatTab:CreateParagraph({Title="Handle 확대 · 실험 기능",Content="보내준 스크립트의 Handle 크기 조절입니다. 실제 타격 거리 증가는 보장되지 않습니다. 끄거나 장착을 해제하면 원래 크기·투명도·질량 설정으로 복구합니다."})
    local function setEnabled(v) enabled=v;apply() end
    CombatTab:CreateToggle({Name="툴 Handle 확대",Flag="Combat_HandleResizeEnabled",CurrentValue=false,Callback=setEnabled})
    CombatTab:CreateSlider({Name="Handle 크기",Flag="Combat_HandleResizeSize",Range={1,100},Increment=1,CurrentValue=30,
        Callback=function(v) size=v;apply() end})
    local function change(delta)
        size=math.clamp(size+delta,1,100)
        local slider=Rayfield.Flags and Rayfield.Flags.Combat_HandleResizeSize
        if slider then slider:Set(size) end
        enabled=true
        local toggle=Rayfield.Flags and Rayfield.Flags.Combat_HandleResizeEnabled
        if toggle then toggle:Set(true) end
        apply()
        notify("툴 Handle 크기 조절","크기: "..size.." · 장착한 툴에 적용")
    end
    CombatTab:CreateButton({Name="Handle 크기 +5",Callback=function() change(5) end})
    CombatTab:CreateButton({Name="Handle 크기 -5",Callback=function() change(-5) end})
    CombatTab:CreateButton({Name="Handle 원래대로 복구",Callback=function()
        enabled=false;restore()
        local toggle=Rayfield.Flags and Rayfield.Flags.Combat_HandleResizeEnabled
        if toggle then toggle:Set(false) end
    end})
    local elapsed=0
    local connection=RunService.Heartbeat:Connect(function(dt)
        elapsed=elapsed+dt
        if elapsed<0.1 then return end
        elapsed=0
        local ok,err=pcall(apply)
        if not ok then enabled=false;restore();warn("KoreanHub Handle: "..tostring(err)) end
    end)
    _G.KoreanHubHandleReset=function()
        enabled=false;restore()
        local toggle=Rayfield.Flags and Rayfield.Flags.Combat_HandleResizeEnabled
        if toggle then toggle:Set(false) end
    end
    _G.KoreanHubHandleCleanup=function() connection:Disconnect();enabled=false;restore() end
end

-- Shared enemy and weapon lookup used by Kill Aura, Triggerbot, Reach and Hitbox Expander.
-- Targets include Player characters AND plain enemy Models with no owning Player (NPCs),
-- for games such as "해적전투" where enemies are Models rather than Players.
do
    function _G.KoreanHubFindEnemies(teamCheck)
        local list = {}
        local seen = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local model = p.Character
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            local root = model and model:FindFirstChild("HumanoidRootPart")
            if p ~= LocalPlayer and model and humanoid and humanoid.Health > 0 and root then
                seen[model] = true
                local teammate = not p.Neutral and not LocalPlayer.Neutral and p.Team ~= nil and p.Team == LocalPlayer.Team
                if not (teamCheck and teammate) then
                    table.insert(list, {model = model, humanoid = humanoid, root = root, owner = p, isPlayer = true, teammate = teammate})
                end
            end
        end
        pcall(function()
            local myCharacter = LocalPlayer.Character
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and not seen[model] and model ~= myCharacter then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local root = model:FindFirstChild("HumanoidRootPart")
                        if root and root:IsA("BasePart") and Players:GetPlayerFromCharacter(model) == nil then
                            table.insert(list, {model = model, humanoid = humanoid, root = root, owner = nil, isPlayer = false, teammate = false})
                        end
                    end
                end
            end
        end)
        return list
    end
    -- A normal Tool, or a Model-based weapon using the ToolSlot + Handle + Activate(RemoteEvent)
    -- pattern some games use instead of Tool.
    function _G.KoreanHubFindWeapon(character)
        if not character then return nil end
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then return tool end
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChild("Handle") then
                local remote = item:FindFirstChild("Activate")
                if remote and (remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent")) then
                    return item
                end
            end
        end
        return nil
    end
    function _G.KoreanHubWeaponReady(tool)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid or humanoid.Health <= 0 or not tool or tool.Parent ~= character then return false end
        if tool:IsA("Tool") then
            if not tool.Enabled then return false end
            local handle = tool:FindFirstChild("Handle")
            return not tool.RequiresHandle or (handle ~= nil and handle:IsA("BasePart"))
        end
        -- Model-type weapon: an optional Enabled BoolValue child stands in for Tool.Enabled.
        local flag = tool:FindFirstChild("Enabled")
        if flag and flag:IsA("BoolValue") and not flag.Value then return false end
        local handle = tool:FindFirstChild("Handle")
        return handle ~= nil and handle:IsA("BasePart")
    end
    -- Swings a Tool normally, or fires a Model weapon's Activate remote with no arguments. Games
    -- whose Model weapon expects specific arguments (coordinates, a target) are not covered here;
    -- those need a recorded protocol, the same approach used for the bat fix.
    function _G.KoreanHubFireWeapon(tool)
        if not tool then return false end
        if tool:IsA("Tool") then return (pcall(function() tool:Activate() end)) end
        local remote = tool:FindFirstChild("Activate")
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent")) then
            return (pcall(function() remote:FireServer() end))
        end
        return false
    end
end

do
    if type(_G.KoreanHubCombatCoreCleanup) == "function" then _G.KoreanHubCombatCoreCleanup() end
    if _G.KoreanHubAutoClickConnection then _G.KoreanHubAutoClickConnection:Disconnect() end
    local settings = {
        Reach = false, ReachDistance = 8, ToolHitbox = false, ToolScale = 2, Touch = true, TouchRange = 8,
        Replay = true, ReplayInterval = 0.3, TpHit = false,
        AllBodyParts = false, TeamCheck = true, QuerySafe = false,
        Radius = 12, Interval = 0.3, Hold = 0.15,
    }
    local backups, connections = {}, {}
    local stateLabel, lastState
    local function report(text)
        if text==lastState then return end
        lastState=text
        if stateLabel then pcall(function() stateLabel:Set(text) end) end
    end
    local activeTool, activeOwner, releaseAt, lastAttack = nil, nil, 0, -math.huge
    local function release(owner)
        if owner and activeOwner ~= owner then return end
        if activeTool and activeTool:IsA("Tool") then pcall(function() activeTool:Deactivate() end) end
        activeTool, activeOwner, releaseAt = nil, nil, 0
    end
    local function restore(part)
        local saved = backups[part]
        if not saved then return end
        if part.Parent then pcall(function()
            part.Size = saved.Size
            if not saved.ToolPart then
                part.Transparency = saved.Transparency
                part.CanCollide = saved.CanCollide
                part.CanQuery = saved.CanQuery
                part.Massless = saved.Massless
            end
        end) end
        backups[part] = nil
    end
    local function restoreAll()
        for part in pairs(backups) do restore(part) end
    end
    local function remember(part, toolPart)
        if not backups[part] then
            backups[part] = {Size = part.Size, Transparency = part.Transparency,
                CanCollide = part.CanCollide, CanQuery = part.CanQuery, Massless = part.Massless, ToolPart = toolPart == true}
        end
        return backups[part]
    end
    local function sameTeam(other)
        return settings.TeamCheck and other.Team ~= nil and other.Team == LocalPlayer.Team
            and not other.Neutral and not LocalPlayer.Neutral
    end
    local function weaponPart(part)
        if not part:IsA("BasePart") or part.Name:lower()=="handle" then return false end
        -- A visual weapon/Handle is not a generic hitbox. Never resize ordinary
        -- welded weapon geometry or change a tool's mass/collision/grip settings.
        if part.CanCollide or part.Anchored then return false end
        local name=part.Name:lower():gsub("[%s_]", "")
        for _,hint in ipairs({"hitbox", "hurtbox", "damagebox", "attackbox", "damagepart", "타격판정", "판정부품"}) do
            if name:find(hint,1,true) then return true end
        end
        return false
    end
    local function equippedReady(tool)
        return _G.KoreanHubWeaponReady(tool)
    end
    -- Touch assist. A bat normally deals damage through Handle.Touched, and the game only counts a hit
    -- when the Handle touches a body part. Reach, hitbox and aura therefore send touches between the
    -- equipped Handle and every enemy inside the chosen range while a swing is active.
    local touchStats = {touches = 0, bursts = 0, failures=0, reason="장착 후 휘두르기 대기", lastError=nil}
    local TOUCH_PARTS = {"HumanoidRootPart", "Head"}
    local burst = {running = false, untilAt = 0, tool = nil, range = 0}
    local lastSelfActivate, watchedTool, watchedConnection = -math.huge, nil, nil
    local function toolHandle(tool)
        return tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true))
    end
    local function sendTouch(handle, part)
        if type(firetouchinterest)~="function" then
            touchStats.reason="firetouchinterest 미지원 · Handle 이동 대체 제거"
            return false
        end
        local ok,err=pcall(function()
            firetouchinterest(handle,part,0)
            firetouchinterest(handle,part,1)
        end)
        if not ok then touchStats.failures=touchStats.failures+1;touchStats.lastError=tostring(err):sub(1,100) end
        return ok
    end
    -- Recorded hit. "Touch sent" only proves the call went out. When the server does not accept it, the
    -- bat reports its hits some other way (usually a RemoteEvent). The recorder watches what the game
    -- itself sends while you really hit an enemy, then repeats that call for every enemy in range.
    local hitRecord = {recording = false, calls = {}, template = nil, replays = 0, replayFailures = 0,
        lastReplay = {}, report = "기록 없음", label = nil, generation=0}
    if _G.KoreanHubHitActive then _G.KoreanHubHitActive.recording=false end
    _G.KoreanHubHitActiveV2 = hitRecord
    local function describeValue(value, depth)
        local kind = typeof(value)
        if kind == "string" then return '"'..value:sub(1, 24)..'"' end
        if kind == "Instance" then return value.ClassName..":"..value.Name end
        if kind == "Vector3" then return string.format("V3(%.0f,%.0f,%.0f)", value.X, value.Y, value.Z) end
        if kind == "table" then
            if depth >= 2 then return "{..}" end
            local parts, count = {}, 0
            for key, item in pairs(value) do
                count = count + 1
                if count > 5 then table.insert(parts, "..");break end
                table.insert(parts, tostring(key).."="..describeValue(item, depth + 1))
            end
            return "{"..table.concat(parts, ",").."}"
        end
        return tostring(value):sub(1, 24)
    end
    local function describeCall(call)
        local parts = {}
        for position = 1, math.min(call.args.n, 5) do parts[position] = describeValue(call.args[position], 0) end
        return call.remote.Name.."("..table.concat(parts, ", ")..")"
    end
    local function copyValue(value, depth)
        if type(value) ~= "table" or depth > 4 then return value end
        local result = {}
        for key, item in pairs(value) do result[key] = copyValue(item, depth + 1) end
        return result
    end
    local function installHitHook()
        if _G.KoreanHubHitHookInstalledV2 then return true end
        if type(hookmetamethod)~="function" or type(getnamecallmethod)~="function" then return false end
        local wrap=newcclosure or function(fn) return fn end
        local original
        original=hookmetamethod(game,"__namecall",wrap(function(self,...)
            local active=_G.KoreanHubHitActiveV2
            local method=getnamecallmethod()
            if not active or not active.recording or (method~="FireServer" and method~="InvokeServer") then
                return original(self,...)
            end
            local args=table.pack(...)
            -- Deliver first. A recorder error must never prevent the real attack.
            local results=table.pack(original(self,...))
            pcall(function()
                local generation=active.generation
                task.defer(function()
                    pcall(function()
                        if _G.KoreanHubHitActiveV2~=active or not active.recording or generation~=active.generation then return end
                        if typeof(self)~="Instance" or not (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then return end
                        local snap={}
                        for _,other in ipairs(Players:GetPlayers()) do
                            local model=other.Character
                            local root=model and model:FindFirstChild("HumanoidRootPart")
                            if root then snap[other]=root.CFrame end
                        end
                        table.insert(active.calls,{remote=self,method=method,args=args,snap=snap,time=os.clock()})
                        if #active.calls>40 then table.remove(active.calls,1) end
                    end)
                end)
            end)
            return table.unpack(results,1,results.n)
        end))
        _G.KoreanHubHitHookInstalledV2=true
        return true
    end
    local function ownerOf(instance)
        for _, other in ipairs(Players:GetPlayers()) do
            local model = other.Character
            if other ~= LocalPlayer and model and (instance == model or instance:IsDescendantOf(model)) then return other end
        end
    end
    local function findVictim(value, depth)
        if typeof(value) == "Instance" then
            if value:IsA("Player") then return value ~= LocalPlayer and value or nil end
            return ownerOf(value)
        elseif type(value) == "table" and depth < 3 then
            for _, item in pairs(value) do
                local found = findVictim(item, depth + 1)
                if found then return found end
            end
        end
    end
    local function pathBetween(model, instance)
        local path, node = {}, instance
        while node and node ~= model do table.insert(path, 1, node.Name);node = node.Parent end
        return path
    end
    local function buildSlots(value, path, victim, rootCF, slots, depth)
        local kind = typeof(value)
        local model = victim.Character
        if kind == "Instance" then
            if value == victim then table.insert(slots, {path = path, kind = "player"})
            elseif model and value == model then table.insert(slots, {path = path, kind = "model"})
            elseif model and value:IsDescendantOf(model) then
                table.insert(slots, {path = path, kind = "part", rel = pathBetween(model, value)})
            end
        elseif kind == "string" then
            if value == victim.Name then table.insert(slots, {path = path, kind = "name"})
            elseif value == victim.DisplayName then table.insert(slots, {path = path, kind = "display"}) end
        elseif kind == "number" then
            if value == victim.UserId then table.insert(slots, {path = path, kind = "userid"}) end
        elseif kind == "Vector3" and rootCF then
            if (value - rootCF.Position).Magnitude <= 10 then
                table.insert(slots, {path = path, kind = "vector", offset = value - rootCF.Position})
            end
        elseif kind == "CFrame" and rootCF then
            if (value.Position - rootCF.Position).Magnitude <= 10 then
                table.insert(slots, {path = path, kind = "cframe", offset = rootCF:ToObjectSpace(value)})
            end
        elseif kind == "table" and depth < 3 then
            for key, item in pairs(value) do
                local nextPath = {table.unpack(path)}
                table.insert(nextPath, key)
                buildSlots(item, nextPath, victim, rootCF, slots, depth + 1)
            end
        end
    end
    local function callVictim(call)
        for position = 1, call.args.n do
            local victim = findVictim(call.args[position], 0)
            if victim then return victim end
        end
    end
    local function setHitLabel(text)
        hitRecord.report = text
        if hitRecord.label then pcall(function() hitRecord.label:Set(text:sub(1, 200)) end) end
    end
    local function finishHitRecording()
        hitRecord.recording = false
        local lines, pick = {}, nil
        for position = #hitRecord.calls, 1, -1 do
            local call = hitRecord.calls[position]
            local victim = callVictim(call)
            if victim and not pick then
                local slots = {}
                for argPosition = 1, call.args.n do
                    buildSlots(call.args[argPosition], {argPosition}, victim, call.snap[victim], slots, 0)
                end
                if #slots > 0 then pick = {call = call, victim = victim, slots = slots} end
            end
        end
        for position, call in ipairs(hitRecord.calls) do
            table.insert(lines, string.format("%d. %s %s%s", position, call.method, describeCall(call),
                (pick and pick.call == call) and "   <- 사용" or ""))
        end
        if not pick then
            hitRecord.calls = {}
            hitRecord.template=nil
            local primary=false
            for _,line in ipairs(lines) do if line:find('"Primary"',1,true) then primary=true;break end end
            setHitLabel(primary and "공격 요청 Primary 관측 · 상대 정보 없음: 대상 교체 재생 불가"
                or ("원격 호출 "..#lines.."건 관측 · 상대 정보가 든 호출 미확인"))
            hitRecord.fullReport = "기록된 원격 호출 "..#lines.."건\n"..table.concat(lines, "\n")
            return false
        end
        hitRecord.template = {remote = pick.call.remote, method = pick.call.method,
            args = copyValue(pick.call.args, 0), slots = pick.slots}
        hitRecord.template.args.n = pick.call.args.n
        hitRecord.fullReport = "사용한 호출: "..describeCall(pick.call).."\n슬롯 "..#pick.slots.."개\n"..table.concat(lines, "\n")
        hitRecord.calls = {}
        setHitLabel("히트 기록 완료 · "..hitRecord.template.remote.Name.." · 슬롯 "..#pick.slots.."개")
        return true
    end
    local function replayHit(target)
        local template = hitRecord.template
        if not template or not template.remote.Parent then return false end
        local model = target.Character
        local root = model and model:FindFirstChild("HumanoidRootPart")
        if not model or not root then return false end
        local args = copyValue(template.args, 0)
        for _, slot in ipairs(template.slots) do
            local replacement
            if slot.kind == "player" then replacement = target
            elseif slot.kind == "model" then replacement = model
            elseif slot.kind == "part" then
                local node = model
                for _, name in ipairs(slot.rel) do node = node and node:FindFirstChild(name) end
                replacement = node
            elseif slot.kind == "name" then replacement = target.Name
            elseif slot.kind == "display" then replacement = target.DisplayName
            elseif slot.kind == "userid" then replacement = target.UserId
            elseif slot.kind == "vector" then replacement = root.Position + slot.offset
            elseif slot.kind == "cframe" then replacement = root.CFrame * slot.offset
            end
            if replacement == nil then return false end
            local node = args
            for position = 1, #slot.path - 1 do node = node[slot.path[position]] end
            node[slot.path[#slot.path]] = replacement
        end
        local ok = pcall(function()
            if template.method == "InvokeServer" then
                task.spawn(function() template.remote:InvokeServer(table.unpack(args, 1, args.n)) end)
            else
                template.remote:FireServer(table.unpack(args, 1, args.n))
            end
        end)
        if ok then hitRecord.replays = hitRecord.replays + 1 else hitRecord.replayFailures = hitRecord.replayFailures + 1 end
        return ok
    end
    local function startBurst(tool, range, duration)
        local canTouch = settings.Touch and type(firetouchinterest) == "function"
        local canReplay = settings.Replay and hitRecord.template ~= nil
        if not range or range <= 0 then touchStats.reason = "보조 범위 없음";return end
        if not canTouch and not canReplay and not settings.TpHit then
            touchStats.reason = settings.Touch and "firetouchinterest 미지원" or "터치·히트 재생 모두 꺼짐"
            return
        end
        burst.tool = tool
        burst.range = math.max(range, burst.running and burst.range or 0)
        burst.untilAt = os.clock() + duration
        touchStats.bursts = touchStats.bursts + 1
        if burst.running then return end
        burst.running = true
        task.spawn(function()
            local origin
            while os.clock() < burst.untilAt do
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local handle = toolHandle(burst.tool)
                if not root or not handle or not handle.Parent or burst.tool.Parent ~= character then break end
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances = {character}
                local from = origin and origin.Position or root.Position
                local nearest, nearestDistance = nil, math.huge
                touchStats.reason = "범위 안의 살아 있는 적 대기"
                for _, enemy in ipairs(_G.KoreanHubFindEnemies(settings.TeamCheck)) do
                    local model, targetRoot = enemy.model, enemy.root
                    local distance = (targetRoot.Position - from).Magnitude
                    if distance <= burst.range then
                        if distance < nearestDistance then nearest, nearestDistance = enemy, distance end
                        if canTouch then
                            local obstruction = workspace:Raycast(root.Position, targetRoot.Position - root.Position, params)
                            if obstruction and not obstruction.Instance:IsDescendantOf(model) then
                                touchStats.reason = "벽에 가려진 상대는 터치 제외"
                            else
                                for _, name in ipairs(TOUCH_PARTS) do
                                    local part = model:FindFirstChild(name)
                                    if part and part:IsA("BasePart") and sendTouch(handle, part) then
                                        touchStats.touches = touchStats.touches + 1
                                        touchStats.reason = "터치 호출 완료 · 서버 명중 미확인"
                                    end
                                end
                            end
                        end
                        -- The hit recorder replays a RemoteEvent call that named a Player; it has no
                        -- equivalent for NPCs, so replay only applies to player targets.
                        if canReplay and enemy.isPlayer and os.clock() - (hitRecord.lastReplay[enemy.owner] or -math.huge) >= settings.ReplayInterval then
                            if replayHit(enemy.owner) then
                                hitRecord.lastReplay[enemy.owner] = os.clock()
                                touchStats.reason = "기록한 히트 재생 · 서버 명중 미확인"
                            end
                        end
                    end
                end
                if settings.TpHit and nearest then
                    origin = origin or root.CFrame
                    pcall(function() root.CFrame = nearest.root.CFrame * CFrame.new(0, 0, 3) end)
                end
                task.wait(0.05)
            end
            if origin then
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root then pcall(function() root.CFrame = origin end) end
            end
            burst.running = false
        end)
    end
    -- Range for the player's own swings: the biggest of Tool Reach, Tool Hitbox and Player Hitbox.
    local function assistRange()
        local range=settings.TouchRange
        if settings.Reach then range = settings.ReachDistance end
        if settings.ToolHitbox then range = math.max(range or 0, 6 * settings.ToolScale) end
        if _G.HitboxExpander then range = math.max(range or 0, tonumber(_G.HitboxSize) or 0) end
        return range
    end
    local function watchTool(tool)
        if tool == watchedTool then return end
        if watchedConnection then watchedConnection:Disconnect(); watchedConnection = nil end
        watchedTool = tool
        -- Only a real Tool fires .Activated. A Model weapon has no equivalent generic signal here;
        -- Kill Aura / Auto Attack / Triggerbot still fire it fine through activate(), just without
        -- this manual-swing touch-assist bonus.
        if tool and tool:IsA("Tool") then
            watchedConnection = tool.Activated:Connect(function()
                if os.clock() - lastSelfActivate < 0.15 then return end
                startBurst(tool, assistRange(), 0.35)
            end)
        end
    end
    local function activate(tool, interval, hold, owner, range)
        local now = os.clock()
        if not equippedReady(tool) or now - lastAttack < interval then return false end
        if activeTool and now < releaseAt then return false end
        release()
        lastSelfActivate = now
        local ok = _G.KoreanHubFireWeapon(tool)
        if not ok then return false end
        activeTool, activeOwner = tool, owner or "auto"
        lastAttack, releaseAt = now, now + hold
        startBurst(tool,range or assistRange(),math.max(hold,0.2))
        return true
    end
    _G.KoreanHubCombatTryActivate = activate
    _G.KoreanHubCombatRelease = release
    -- Server-side melee. The recorder shows the bat only sends "Primary" with no target, so the server
    -- decides the hit from the real positions of both characters. Sizes changed on this screen are not seen
    -- by the server. The one thing that does reach it is the position of the player's own character:
    -- step behind the enemy, face it, swing, then go back.
    local tpAura = {enabled = false, alive = true, range = 40, interval = 0.6, lead = 0.08, stay = 0.25,
        strikes = 0, reason = "꺼짐"}
    local function nearestEnemy(from, range)
        local best, bestDistance = nil, math.huge
        for _, enemy in ipairs(_G.KoreanHubFindEnemies(settings.TeamCheck)) do
            local distance = (enemy.root.Position - from).Magnitude
            if distance <= range and distance < bestDistance then best, bestDistance = enemy, distance end
        end
        return best
    end
    local function standBehind(root, targetRoot)
        local look = targetRoot.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
        local position = targetRoot.Position - flat.Unit * 3
        root.CFrame = CFrame.lookAt(position, Vector3.new(targetRoot.Position.X, position.Y, targetRoot.Position.Z))
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    local function tpStrikeOnce()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local tool = character and _G.KoreanHubFindWeapon(character)
        if not root or not humanoid or humanoid.Health <= 0 then tpAura.reason = "캐릭터 대기";return end
        if not tool or not equippedReady(tool) then tpAura.reason = "툴 장착·재사용 대기";return end
        local target = nearestEnemy(root.Position, tpAura.range)
        if not target then tpAura.reason = "범위 안 적 없음";return end
        local origin = root.CFrame
        local function glue()
            local model = target.model
            local targetRoot = model and model.Parent and model:FindFirstChild("HumanoidRootPart")
            if not targetRoot or not root.Parent then return false end
            standBehind(root, targetRoot)
            return true
        end
        local function goBack()
            if root.Parent then pcall(function() root.CFrame = origin;root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end) end
        end
        if not glue() then return end
        task.wait(tpAura.lead)
        if not glue() then goBack();return end
        if not activate(tool, 0, 0.15, "tpaura") then
            goBack();tpAura.reason = "휘두르기 거부 · 툴 재사용 대기";return
        end
        local stayUntil = os.clock() + tpAura.stay
        while os.clock() < stayUntil do
            if not glue() then break end
            task.wait(0.05)
        end
        goBack()
        tpAura.strikes = tpAura.strikes + 1
        tpAura.reason = "타격 시도 · "..target.model.Name.." · 서버 명중 미확인"
    end
    task.spawn(function()
        while tpAura.alive do
            if tpAura.enabled then
                local ok, err = pcall(tpStrikeOnce)
                if not ok then tpAura.reason = "오류: "..tostring(err):sub(1, 80) end
                task.wait(math.max(tpAura.interval, 0.1))
            else
                task.wait(0.2)
            end
        end
    end)
    CombatTab:CreateSlider({Name = "Auto Attack Nearby Range", Flag = "Combat_AutoClickPlayerRange", Range = {3, 50}, Increment = 1,
        CurrentValue = 12, Callback = function(v) settings.Radius = v end})
    CombatTab:CreateSlider({Name = "Auto Attack Interval", Flag = "Combat_NearAttackIntervalV3", Range = {0.05, 2}, Increment = 0.05,
        CurrentValue = 0.3, Callback = function(v) settings.Interval = v end})
    CombatTab:CreateSlider({Name = "Auto Attack Press Duration", Flag = "Combat_AttackPressV3", Range = {0.05, 1}, Increment = 0.05,
        CurrentValue = 0.15, Callback = function(v) settings.Hold = v end})
    CombatTab:CreateToggle({Name = "Combat Team Check", Flag = "Combat_NearTeamV2", CurrentValue = true,
        Callback = function(v) settings.TeamCheck = v end})
    CombatTab:CreateSection("Reach & Tool Hitbox")
    CombatTab:CreateToggle({Name = "Tool Reach (터치 범위 · 직접 휘두를 때)", Flag = "Combat_ToolReachV3", CurrentValue = false,
        Callback = function(v) settings.Reach = v end})
    CombatTab:CreateSlider({Name = "Tool Reach Size (studs)", Flag = "Combat_ToolReachSizeV2", Range = {2, 40}, Increment = 1,
        CurrentValue = 8, Callback = function(v) settings.ReachDistance = v end})
    CombatTab:CreateToggle({Name = "Tool Hitbox Expander (터치 범위 ×배율)", Flag = "Combat_ToolHitboxV3", CurrentValue = false,
        Callback = function(v) settings.ToolHitbox = v end})
    CombatTab:CreateSlider({Name = "Tool Hitbox Multiplier", Flag = "Combat_ToolHitboxScaleV2", Range = {1, 10}, Increment = 0.5,
        CurrentValue = 2, Callback = function(v) settings.ToolScale = v end})
    CombatTab:CreateToggle({Name = "터치 판정 보조 (Reach·Hitbox·Aura 공통)", Flag = "Combat_TouchAssistV1", CurrentValue = true,
        Callback = function(v) settings.Touch = v end})
    CombatTab:CreateSlider({Name="터치 보조 기본 범위",Flag="Combat_TouchBaseRangeV2",Range={2,30},Increment=1,CurrentValue=8,
        Callback=function(v) settings.TouchRange=v end})
    CombatTab:CreateToggle({Name="플레이어 히트박스 · 클릭 간섭 방지 (레이캐스트 총기는 끄세요)",Flag="Combat_HitboxQuerySafeV1",CurrentValue=false,
        Callback=function(v) settings.QuerySafe=v end})
    CombatTab:CreateParagraph({Title="클릭 간섭 방지와 총기", Content="켜면 확대한 히트박스가 내 카메라 클릭을 막지 않지만, 동시에 총알 레이캐스트도 그 부위를 통과합니다. MM2·MVSD 같은 레이캐스트 총기 게임에서 히트박스가 안 맞으면 이 옵션을 꺼 두세요. 기본값은 꺼짐입니다."})
    CombatTab:CreateParagraph({Title="히트박스 호환성",Content="확대한 플레이어 파트의 로컬 CanQuery를 끄고 질량은 유지합니다. 클릭·카메라 레이 간섭을 줄이기 위한 옵션입니다. 레이캐스트 무기는 확대 효과가 줄거나 없어질 수 있습니다. 서버 타격 범위 확대를 보장하지 않습니다."})
    CombatTab:CreateDropdown({Name = "Player Hitbox Parts", Flag = "Combat_PlayerPartsV3",
        Options = {"Body Parts + Root", "Root Only"}, CurrentOption = {"Root Only"},
        Callback = function(v) settings.AllBodyParts = (type(v) == "table" and v[1] or v) == "Body Parts + Root" end})
    CombatTab:CreateParagraph({Title = "배트 터치 판정", Content = "이 Bat가 Handle.Touched로 피해를 처리하는지는 아직 미확인입니다. 터치 보조는 호출을 시도할 뿐 서버 피해를 보장하지 않습니다. Reach·Tool Hitbox·Player Hitbox는 직접 휘두를 때, Auto Attack·Kill Aura는 자동으로 휘두를 때 범위 안의 상대에게 Handle 터치를 보냅니다. 상태 줄의 터치 전송 횟수가 늘어나는지 확인하세요. 서버가 거리나 레이캐스트로 따로 검사하는 무기에서는 효과가 없을 수 있습니다."})

    CombatTab:CreateSection("실제 히트 기록 · 재생")
    CombatTab:CreateParagraph({Title = "히트 기록", Content = "30초는 직접 공격한 호출을 관찰하는 시간이며, 무적·사거리 효과가 아닙니다. Action(Primary)처럼 상대 정보 없이 공격만 요청하는 게임은 대상 교체 재생을 만들 수 없습니다. 호출에 상대 정보가 있더라도 피해 판정이라는 증거는 별도로 필요합니다."})
    CombatTab:CreateButton({Name = "수동 공격 기록 시작 · 30초 관찰", Callback = function()
        if hitRecord.recording then notify("공격 기록","이미 기록 중입니다. 종료 또는 취소 후 다시 시작하세요.");return end
        local ok,result=pcall(installHitHook)
        if not ok or not result then notify("공격 기록","기록 연결 실패: "..tostring(result));return end
        hitRecord.generation=hitRecord.generation+1
        local ticket=hitRecord.generation
        hitRecord.calls={};hitRecord.template=nil;hitRecord.fullReport=nil;hitRecord.recording=true
        notify("공격 기록","자동 공격·AI를 끄고, 가까운 적을 직접 공격하세요. 기록기는 공격을 막거나 대신 하지 않습니다.")
        task.spawn(function()
            local started=os.clock()
            while hitRecord.recording and ticket==hitRecord.generation and os.clock()-started<30 do
                setHitLabel("수동 공격 관찰 · 남은 "..math.ceil(30-(os.clock()-started)).."초 · 호출 "..#hitRecord.calls.."건")
                task.wait(0.25)
            end
            if not hitRecord.recording or ticket~=hitRecord.generation then return end
            local success=finishHitRecording()
            notify("공격 기록",success and "호출 후보 관측 · 실제 타격 프로토콜인지는 미확인"
                or hitRecord.report)
        end)
    end})
    CombatTab:CreateButton({Name="공격 기록 취소",Callback=function()
        hitRecord.generation=hitRecord.generation+1;hitRecord.recording=false
        setHitLabel("기록 취소됨 · 직접 공격은 그대로 사용 가능")
    end})
    hitRecord.label = CombatTab:CreateLabel("히트 기록: 없음")
    CombatTab:CreateToggle({Name = "기록한 히트 재생 (Aura·Reach 공통)", Flag = "Combat_ReplayHitV1", CurrentValue = true,
        Callback = function(v) settings.Replay = v end})
    CombatTab:CreateSlider({Name = "히트 재생 간격 (초)", Flag = "Combat_ReplayIntervalV1", Range = {0.05, 2}, Increment = 0.05,
        CurrentValue = 0.3, Callback = function(v) settings.ReplayInterval = v end})
    CombatTab:CreateToggle({Name = "TP 타격 오라 (서버가 위치로 판정하는 배트용)", Flag = "Combat_TpAuraV1", CurrentValue = false,
        Callback = function(v) tpAura.enabled = v;tpAura.reason = v and "대기" or "꺼짐" end})
    CombatTab:CreateSlider({Name = "TP 타격 범위 (studs)", Flag = "Combat_TpAuraRangeV1", Range = {5, 150}, Increment = 5,
        CurrentValue = 40, Callback = function(v) tpAura.range = v end})
    CombatTab:CreateSlider({Name = "TP 타격 간격 (초)", Flag = "Combat_TpAuraIntervalV1", Range = {0.2, 3}, Increment = 0.1,
        CurrentValue = 0.6, Callback = function(v) tpAura.interval = v end})
    CombatTab:CreateSlider({Name = "이동 후 휘두르기까지 대기 (초)", Flag = "Combat_TpAuraLeadV1", Range = {0.02, 0.4}, Increment = 0.02,
        CurrentValue = 0.08, Callback = function(v) tpAura.lead = v end})
    CombatTab:CreateSlider({Name = "휘두른 뒤 머무는 시간 (초)", Flag = "Combat_TpAuraStayV1", Range = {0.05, 1}, Increment = 0.05,
        CurrentValue = 0.25, Callback = function(v) tpAura.stay = v end})
    CombatTab:CreateParagraph({Title = "TP 타격 오라", Content = "기록에서 공격 요청이 Primary뿐이고 상대 정보가 없다면, 서버는 두 캐릭터의 실제 위치로 맞았는지 판정합니다. 이 화면에서 키운 히트박스·Reach·Handle 크기는 서버가 보지 못합니다. 이 스위치는 범위 안의 가장 가까운 적 바로 뒤로 이동해 상대를 바라보고 휘두른 뒤 원래 자리로 돌아옵니다. 다른 플레이어 화면에서는 순간이동하는 것으로 보입니다."})
    CombatTab:CreateButton({Name = "히트 기록 지우기", Callback = function()
        hitRecord.generation=hitRecord.generation+1;hitRecord.template = nil;hitRecord.calls = {};hitRecord.recording = false;hitRecord.fullReport = nil
        setHitLabel("히트 기록: 없음")
    end})
    CombatTab:CreateButton({Name = "히트 기록 보고서 복사", Callback = function()
        local text = hitRecord.fullReport or hitRecord.report
        if type(setclipboard) == "function" then pcall(setclipboard, text);notify("히트 기록", "보고서를 클립보드에 복사했습니다")
        else print(text);notify("히트 기록", "클립보드를 지원하지 않아 콘솔에 출력했습니다") end
    end})
    -- Snapshot diagnostics: property reads only; no activation or remote calls.
    local function toolDiagnostic()
        local lines={"KoreanHub equipment diagnostic 2", "PlaceId="..tostring(game.PlaceId),
            "AutoAttack="..tostring(_G.AutoClicker).." Reach="..tostring(settings.Reach).." ToolHitbox="..tostring(settings.ToolHitbox),
            "구조 진단입니다. 서버의 실제 타격 범위는 이 보고서만으로 확정할 수 없습니다."}
        local function add(v) lines[#lines+1]=v end
        local function read(o,k)
            local ok,v=pcall(function() return o[k] end)
            if not ok then return "<unavailable>" end
            return tostring(v):gsub("[\r\n]"," "):sub(1,180)
        end
        local function path(o)
            local ok,v=pcall(function() return o:GetFullName() end)
            return ok and v or tostring(o)
        end
        local function props(o,keys)
            local out={}
            for _,k in ipairs(keys) do out[#out+1]=k.."="..read(o,k) end
            add(table.concat(out," | "))
        end
        local char=LocalPlayer.Character
        local tool=char and _G.KoreanHubFindWeapon(char)
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then props(hum,{"Health","MaxHealth","Sit","PlatformStand"}) end
        add("--- Extended equipment structure diagnostic 2 ---")
        local function inspectRoot(root,title,limit)
            add("ROOT "..title.."="..(root and path(root) or "<missing>"))
            if not root then return end
            local items=root:GetDescendants()
            table.sort(items,function(a,b) return path(a)<path(b) end)
            add("descendants="..#items.."; scan limit="..limit)
            for i,o in ipairs(items) do
                if i>limit then add("... scan limit reached");break end
                if o:IsA("Model") or o:IsA("Tool") or o:IsA("Folder") or o:IsA("BasePart")
                    or o:IsA("JointInstance") or o:IsA("WeldConstraint") or o:IsA("Attachment")
                    or o:IsA("LuaSourceContainer") or o:IsA("RemoteEvent") or o:IsA("RemoteFunction")
                    or o:IsA("ValueBase") then
                    add("["..o.ClassName.."] "..path(o))
                    if o:IsA("BasePart") then props(o,{"Size","Transparency","CanTouch","CanQuery"}) end
                    if o:IsA("JointInstance") or o:IsA("WeldConstraint") then
                        local function linked(k)
                            local ok,v=pcall(function() return o[k] end)
                            return ok and v and path(v) or "<none>"
                        end
                        add("Part0="..linked("Part0").." | Part1="..linked("Part1"))
                    end
                    if o:IsA("Tool") then props(o,{"Enabled","RequiresHandle","ManualActivationOnly"}) end
                    if o:IsA("ValueBase") then props(o,{"Value"}) end
                    local good,attrs=pcall(function() return o:GetAttributes() end)
                    if good then
                        local keys={};for k in pairs(attrs) do keys[#keys+1]=k end;table.sort(keys)
                        for n,k in ipairs(keys) do
                            if n>12 then break end
                            add("attribute "..k.."="..tostring(attrs[k]):gsub("[\r\n]"," "):sub(1,120))
                        end
                    end
                end
            end
        end
        inspectRoot(char,"LocalPlayer.Character",350)
        inspectRoot(LocalPlayer:FindFirstChildOfClass("Backpack"),"Backpack",250)
        inspectRoot(workspace.CurrentCamera,"CurrentCamera",200)
        -- Some games render a separate avatar under Workspace. List shallow model
        -- names and ownership attributes only, without scanning other players' inventories.
        add("--- Workspace direct models (maximum 80) ---")
        local models={}
        for _,o in ipairs(workspace:GetChildren()) do if o:IsA("Model") or o:IsA("Folder") then models[#models+1]=o end end
        table.sort(models,function(a,b) return a.Name<b.Name end)
        for i,o in ipairs(models) do
            if i>80 then add("... model limit reached");break end
            add("["..o.ClassName.."] "..path(o).." | isLocalCharacter="..tostring(o==char))
        end
        if not tool then
            add("Tool·Model 무기 없음. 위 구조와 손의 Part0·Part1 연결을 확인해야 합니다.")
            add("구조만 읽었습니다. 공격·원격 호출·스크립트 소스 읽기는 하지 않았습니다.")
            return table.concat(lines,"\n")
        end
        add((tool:IsA("Tool") and "TOOL " or "MODEL WEAPON ")..path(tool))
        if tool:IsA("Tool") then props(tool,{"Enabled","RequiresHandle","ManualActivationOnly","Grip"}) end
        local objects={tool}
        for _,o in ipairs(tool:GetDescendants()) do objects[#objects+1]=o end
        table.sort(objects,function(a,b) return path(a)<path(b) end)
        add("Objects="..#objects.." (maximum 300 listed)")
        local count=0
        for i,o in ipairs(objects) do
            if i>300 then add("... object limit reached");break end
            add("["..o.ClassName.."] "..path(o))
            if o:IsA("BasePart") then
                props(o,{"Size","Anchored","CanCollide","CanTouch","CanQuery","Massless","Transparency"})
                local reason="name filter did not match"
                if o.Name:lower()=="handle" then reason="Handle excluded"
                elseif o.Anchored then reason="Anchored excluded"
                elseif o.CanCollide then reason="CanCollide excluded"
                elseif weaponPart(o) then reason="eligible dedicated hit part";count=count+1 end
                add("filter="..reason)
                local saved=backups[o]
                if saved then add("Saved original Size="..tostring(saved.Size)) end
            elseif o:IsA("JointInstance") or o:IsA("WeldConstraint") then
                props(o,{"Part0","Part1"})
            elseif o:IsA("Attachment") then props(o,{"Position","Orientation"})
            elseif o:IsA("LuaSourceContainer") then
                props(o,{"Enabled","RunContext"})
            elseif o:IsA("ValueBase") then props(o,{"Value"}) end
            local ok,attrs=pcall(function() return o:GetAttributes() end)
            if ok then
                local keys={};for k in pairs(attrs) do keys[#keys+1]=k end;table.sort(keys)
                for n,k in ipairs(keys) do
                    if n>20 then add("... attribute limit reached");break end
                    add("attribute "..k.."="..tostring(attrs[k]):gsub("[\r\n]"," "):sub(1,180))
                end
            end
        end
        add("Dedicated hit parts="..count)
        add("Remote/script names are listed only. No source access, remote invocation or attack is performed by diagnostics.")
        return table.concat(lines,"\n")
    end
    CombatTab:CreateButton({Name="무기 확장 진단 · 보고서 보기",Callback=function()
        local ok,body=pcall(toolDiagnostic)
        if not ok then body="진단 실패: "..tostring(body) end
        print(body)
        local parent=LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent then notify("툴 진단","PlayerGui를 찾지 못했습니다. 콘솔을 확인하세요.");return end
        local old=parent:FindFirstChild("KoreanHubToolDiagnostic")
        if old then old:Destroy() end
        local gui=Instance.new("ScreenGui")
        gui.Name="KoreanHubToolDiagnostic";gui.ResetOnSpawn=false;gui.DisplayOrder=10000;gui.Parent=parent
        local frame=Instance.new("Frame")
        frame.Size=UDim2.fromScale(0.88,0.84);frame.Position=UDim2.fromScale(0.06,0.08)
        frame.BackgroundColor3=Color3.fromRGB(25,28,32);frame.Parent=gui
        local function button(text,x,callback)
            local b=Instance.new("TextButton");b.Size=UDim2.new(0.31,0,0,38);b.Position=UDim2.new(x,0,0,4)
            b.Text=text;b.TextSize=16;b.BackgroundColor3=Color3.fromRGB(60,67,76);b.TextColor3=Color3.new(1,1,1);b.Parent=frame
            b.Activated:Connect(callback)
        end
        button("복사",0.015,function()
            local copy=setclipboard or toclipboard
            local copied=type(copy)=="function" and pcall(copy,body)
            notify("툴 진단",copied and "보고서를 복사했습니다." or "복사 기능이 없습니다. 화면이나 저장 파일을 보내주세요.")
        end)
        button("파일 저장",0.345,function()
            local saved=type(writefile)=="function" and pcall(writefile,"KoreanHub_ToolDiagnostic.txt",body)
            notify("툴 진단",saved and "KoreanHub_ToolDiagnostic.txt 저장 완료" or "파일 저장 기능을 사용할 수 없습니다.")
        end)
        button("닫기",0.675,function() gui:Destroy() end)
        local scroll=Instance.new("ScrollingFrame")
        scroll.Position=UDim2.new(0,8,0,50);scroll.Size=UDim2.new(1,-16,1,-58)
        scroll.BackgroundTransparency=1;scroll.ScrollBarThickness=10;scroll.Parent=frame
        local label=Instance.new("TextLabel")
        label.Size=UDim2.new(1,-14,0,0);label.AutomaticSize=Enum.AutomaticSize.Y
        label.BackgroundTransparency=1;label.TextColor3=Color3.new(1,1,1);label.TextSize=14
        label.Font=Enum.Font.Code;label.TextXAlignment=Enum.TextXAlignment.Left;label.TextYAlignment=Enum.TextYAlignment.Top
        label.TextWrapped=true;label.Text=body;label.Parent=scroll
        scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new()
    end})
    stateLabel=CombatTab:CreateLabel("현재 툴: 없음 · 전용 판정 파트: 0")
    CombatTab:CreateButton({Name = "툴 원복 + 자동 공격 모두 중지", Callback = function()
        _G.AutoClicker=false;_G.HitboxExpander=false;settings.Reach=false;settings.ToolHitbox=false
        for _,flag in ipairs({"Combat_MobileTrigger","Combat_AutoClicker","Combat_HitboxExpander","Combat_ToolReachV3","Combat_ToolHitboxV3","Combat_NPCKillAura","Combat_PlayerKillAura"}) do
            local control=Rayfield.Flags and Rayfield.Flags[flag]
            if control then pcall(function() control:Set(false) end) end
        end
        if type(_G.KoreanHubHandleReset)=="function" then _G.KoreanHubHandleReset() end
        release();restoreAll();report("모든 자동 공격 중지 · 변경한 크기 원복 완료")
    end})

    local elapsed = 0
    local function update(dt)
        local now = os.clock()
        local character = LocalPlayer.Character
        if activeTool and (now >= releaseAt or activeTool.Parent ~= character) then release() end
        elapsed = elapsed + dt
        if elapsed < 0.05 then return end
        elapsed = 0
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local alive = root and humanoid and humanoid.Health > 0
        local tool = character and _G.KoreanHubFindWeapon(character)
        watchTool(tool)
        local touched, nearby, hitCount = {}, false, 0
        if alive then
            for _,enemy in ipairs(_G.KoreanHubFindEnemies(settings.TeamCheck)) do
                local model, targetRoot = enemy.model, enemy.root
                if (targetRoot.Position - root.Position).Magnitude <= settings.Radius then nearby = true end
                if _G.HitboxExpander then
                    for _,part in ipairs(model:GetChildren()) do
                        if part:IsA("BasePart") and (settings.AllBodyParts or part == targetRoot) then
                            local saved = remember(part)
                            local size = _G.HitboxSize
                            part.Size = Vector3.new(math.max(saved.Size.X, size), math.max(saved.Size.Y, size), math.max(saved.Size.Z, size))
                            part.Transparency = math.max(saved.Transparency, 0.7)
                            part.CanCollide = false
                            -- Preserve character assembly mass; enlarged roots should not
                            -- intercept local screen rays while compatibility mode is on.
                            if settings.QuerySafe then part.CanQuery=false else part.CanQuery=saved.CanQuery end
                            touched[part] = true
                        end
                    end
                end
            end
            if tool then
                for _,part in ipairs(tool:GetDescendants()) do
                    if weaponPart(part) then
                        hitCount=hitCount+1
                        if settings.Reach or settings.ToolHitbox then
                        local saved = remember(part,true)
                        local scale = settings.ToolHitbox and settings.ToolScale or 1
                        local diameter = settings.Reach and settings.ReachDistance * 2 or 0
                        part.Size = Vector3.new(math.max(saved.Size.X * scale, diameter),
                            math.max(saved.Size.Y * scale, diameter), math.max(saved.Size.Z * scale, diameter))
                        touched[part] = true
                        end
                    end
                end
            end
        end
        for part in pairs(backups) do if not touched[part] then restore(part) end end
        local equipped=tool and tool.Parent==character
        if not _G.AutoClicker or not alive or not nearby or not equipped then
            release("auto")
        elseif equippedReady(tool) then
            activate(tool, settings.Interval, settings.Hold, "auto", settings.Radius)
        end
        -- Enabled=false commonly means the weapon is in its own cooldown.
        -- Do not cancel the current press just because its Activated handler disables it.
        local note=(settings.Reach or settings.ToolHitbox) and hitCount==0 and not settings.Touch
            and " · 전용 판정 파트 없음: 게임별 연결 필요" or ""
        local touchNote=" · 터치 호출 "..touchStats.touches.."회 · 실패 "..touchStats.failures.."회"
            .." · "..(settings.Touch and touchStats.reason or "터치 보조 꺼짐")
            ..(hitRecord.template and (" · 히트 재생 "..hitRecord.replays.."회 ("..hitRecord.template.remote.Name..")") or " · 히트 기록 없음")
        if tpAura.enabled then touchNote=touchNote.." · TP 타격 "..tpAura.strikes.."회 · "..tpAura.reason end
        if not tool then touchNote=touchNote.." · 일반 Tool 미장착" end
        if tool then
            local handle=toolHandle(tool)
            if handle and handle:IsA("BasePart") then touchNote=touchNote.." · Handle.CanTouch="..tostring(handle.CanTouch) end
        end
        if touchStats.lastError then touchNote=touchNote.." · "..touchStats.lastError end
        report("현재 툴: "..(tool and tool.Name or "없음").." · 이름으로 찾은 전용 파트: "..hitCount..note..touchNote)

    end
    local heartbeat = RunService.Heartbeat:Connect(update)
    connections[#connections + 1] = heartbeat
    _G.KoreanHubAutoClickConnection = heartbeat
    connections[#connections + 1] = LocalPlayer.CharacterAdded:Connect(function()
        burst.untilAt=0;release();restoreAll();lastAttack = -math.huge
    end)
    _G.KoreanHubCombatCoreCleanup = function()
        for _,connection in ipairs(connections) do connection:Disconnect() end
        if watchedConnection then watchedConnection:Disconnect();watchedConnection=nil end
        burst.untilAt=0;hitRecord.recording=false;tpAura.alive=false;tpAura.enabled=false;release();restoreAll()
        if _G.KoreanHubHitActiveV2 == hitRecord then _G.KoreanHubHitActiveV2 = nil end
        if _G.KoreanHubCombatTryActivate == activate then _G.KoreanHubCombatTryActivate = nil end
        if _G.KoreanHubCombatRelease == release then _G.KoreanHubCombatRelease = nil end
    end
end


CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Callback = function(state)
        _G.HitboxExpander = state
    end,
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 25},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v)
        _G.HitboxSize = v
    end,
})

local aimLockedPlayer=nil
local function aimCenter(camera)
    if UserInputService.TouchEnabled then return camera.ViewportSize/2 end
    local inset=game:GetService("GuiService"):GetGuiInset()
    return UserInputService:GetMouseLocation()-inset
end
local function aimTargetPart(p,camera,radius)
    if p==LocalPlayer or not p.Character then return nil end
    if _G.AimbotTeamCheck and not p.Neutral and not LocalPlayer.Neutral and p.Team and p.Team==LocalPlayer.Team then return nil end
    local hum=p.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return nil end
    local char=p.Character
    local part=char:FindFirstChild(_G.AimPart=="Head" and "Head" or "HumanoidRootPart")
        or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    if not part or not part:IsA("BasePart") then return nil end
    local pos,visible=camera:WorldToViewportPoint(part.Position)
    if not visible or pos.Z<=0 then return nil end
    local distance=(Vector2.new(pos.X,pos.Y)-aimCenter(camera)).Magnitude
    if distance>radius then return nil end
    return part,distance
end
local function getClosestTarget()
    local camera=workspace.CurrentCamera
    if not camera then return nil end
    local radius=math.huge
    if aimLockedPlayer and aimTargetPart(aimLockedPlayer,camera,radius*1.25) then return aimLockedPlayer end
    aimLockedPlayer=nil
    local best=radius
    for _,p in ipairs(Players:GetPlayers()) do
        local part,distance=aimTargetPart(p,camera,radius)
        if part and distance<best then best=distance;aimLockedPlayer=p end
    end
    return aimLockedPlayer
end
-- Run after Roblox's camera controller, with frame-rate independent smoothing.
RunService:UnbindFromRenderStep("KoreanHubAimCameraV2")
RunService:BindToRenderStep("KoreanHubAimCameraV2",Enum.RenderPriority.Camera.Value+1,function(dt)
    local camera=workspace.CurrentCamera
    if not camera then return end
    Camera=camera
    _G.FOVCircle=false;fovDrawing.Visible=false
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not _G.AimbotEnabled or not hum or hum.Health<=0 or UserInputService:GetFocusedTextBox()
        or camera.CameraType==Enum.CameraType.Scriptable then
        aimLockedPlayer=nil;return
    end
    local target=getClosestTarget()
    local part=target and aimTargetPart(target,camera,math.huge)
    if not part then return end
    local cf=camera.CFrame
    if (part.Position-cf.Position).Magnitude<0.01 then return end
    local smooth=math.max(tonumber(_G.AimbotSmoothness) or 1,1)
    local alpha=1-(1-math.clamp(1/smooth,0.01,1))^(math.max(dt,0)*60)
    camera.CFrame=cf:Lerp(CFrame.lookAt(cf.Position,part.Position),alpha)
end)

RunService.RenderStepped:Connect(function()
    if _G.PlayerLock and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local tHrp = target.Character.HumanoidRootPart
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z))
        end
    end

    if _G.Spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(_G.SpinSpeed * 0.2), 0)
    end

    if _G.GodMode and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
    end

    if _G.TouchFling and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local v = hrp.Velocity
        hrp.Velocity = v * 10000 + Vector3.new(0, 10000, 0)
        RunService.RenderStepped:Wait()
        hrp.Velocity = v
    end

    -- Player hitboxes are owned by the restorable combat controller above.

end)

------------------------------------------------------------------
-- 3. Visuals Tab
------------------------------------------------------------------
VisualsTab:CreateSlider({
    Name = "FOV Changer",
    Range = {10, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(v)
        Camera.FieldOfView = v
    end,
})

VisualsTab:CreateToggle({
    Name = "Invisibility",
    CurrentValue = false,
    Callback = function(state)
        _G.Invisibility = state
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = state and 1 or 0
                end
            end
        end
    end,
})

VisualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(state)
        _G.Fullbright = state
    end,
})

VisualsTab:CreateSlider({
    Name = "Fullbright Intensity",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(v)
        _G.FullbrightIntensity = v
    end,
})

RunService.RenderStepped:Connect(function()
    if _G.Fullbright then
        Lighting.Brightness = _G.FullbrightIntensity
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

VisualsTab:CreateToggle({
    Name = "Freecam",
    CurrentValue = false,
    Callback = function(state)
        _G.Freecam = state
        Camera.CameraType = state and Enum.CameraType.Scriptable or Enum.CameraType.Custom
    end,
})

local freecamCF = Camera.CFrame
RunService.RenderStepped:Connect(function()
    if _G.Freecam then
        local move = Vector3.new()
        local cf = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
        freecamCF = freecamCF + (move * 1)
        Camera.CFrame = freecamCF
    else
        freecamCF = Camera.CFrame
    end
end)

------------------------------------------------------------------
-- 4. ESP Tab - outlined, pooled R6 / R15 renderer
------------------------------------------------------------------
do
local style = {
    BoxColor = Color3.fromRGB(90, 190, 255),
    TracerColor = Color3.fromRGB(170, 210, 255),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    OutlineColor = Color3.fromRGB(12, 16, 24),
    Thickness = 1.5, Opacity = 0.9, MaxDistance = 1500,
    Outline = true, TracerOrigin = "Bottom",
}
local entries = {}
local function hide(entry)
    for _, object in ipairs(entry.objects) do object.Visible = false end
end
local function clear(player)
    local entry = entries[player]
    if not entry then return end
    for _, object in ipairs(entry.objects) do object:Remove() end
    entries[player] = nil
end
local function toggle(name, key, default)
    ESPTab:CreateToggle({Name = name, CurrentValue = default, Callback = function(value)
        _G[key] = value
        for _, entry in pairs(entries) do hide(entry) end
    end})
end
toggle("Enable ESP", "ESPEnabled", false)
toggle("ESP Team Check", "ESPTeamCheck", true)
toggle("Box ESP", "BoxESP", false)
toggle("Tracer ESP", "TracerESP", false)
toggle("Skeleton ESP", "SkeletonESP", false)
ESPTab:CreateSection("Colors & Quality")
for _, definition in ipairs({
    {"Box Color", "BoxColor"}, {"Tracer Color", "TracerColor"},
    {"Skeleton Color", "SkeletonColor"}, {"Outline Color", "OutlineColor"},
}) do
    local key = definition[2]
    ESPTab:CreateColorPicker({Name = definition[1], Color = style[key],
        Flag = "ESP_" .. key, Callback = function(color) style[key] = color end})
end
ESPTab:CreateToggle({Name = "Dark Outline", CurrentValue = true,
    Callback = function(value) style.Outline = value end})
for _, definition in ipairs({
    {"Line Thickness", "Thickness", 1, 4, 0.5},
    {"ESP Opacity", "Opacity", 0.1, 1, 0.05},
    {"Max Distance (studs)", "MaxDistance", 100, 5000, 50},
}) do
    local key = definition[2]
    ESPTab:CreateSlider({Name = definition[1], Range = {definition[3], definition[4]},
        Increment = definition[5], CurrentValue = style[key],
        Callback = function(value) style[key] = value end})
end
ESPTab:CreateDropdown({Name = "Tracer Origin", Options = {"Bottom", "Center", "Top"},
    CurrentOption = {"Bottom"}, MultipleOptions = false,
    Callback = function(value) style.TracerOrigin = type(value) == "table" and value[1] or value end})

local r6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local r15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local corners = {}
for x = -1, 1, 2 do
    for y = -1, 1, 2 do
        for z = -1, 1, 2 do table.insert(corners, Vector3.new(x, y, z) * 0.5) end
    end
end
local function pair(entry, kind, layer)
    local result = {}
    for i = 1, 2 do
        local object = Drawing.new(kind)
        object.Visible = false
        object.Transparency = 1
        object.ZIndex = layer + i - 1
        if kind == "Square" then object.Filled = false end
        result[i] = object
        table.insert(entry.objects, object)
    end
    return result
end
local function create(player, character)
    local entry = {objects = {}, character = character, bones = {}}
    entries[player] = entry
    entry.box = pair(entry, "Square", 4)
    entry.tracer = pair(entry, "Line", 0)
    for i = 1, #r15 do entry.bones[i] = pair(entry, "Line", 2) end
    return entry
end
local function paint(objects, color, opacity)
    for i, object in ipairs(objects) do
        object.Color = i == 1 and style.OutlineColor or color
        object.Thickness = style.Thickness + (i == 1 and 2 or 0)
        object.Transparency = opacity
        object.Visible = i == 2 or style.Outline
    end
end
local function line(objects, a, b, color, opacity)
    for _, object in ipairs(objects) do object.From = a; object.To = b end
    paint(objects, color, opacity)
end
local function project(camera, position)
    local point = camera:WorldToViewportPoint(position)
    if point.Z <= 0.1 then return nil end
    return Vector2.new(point.X, point.Y)
end
-- Project body part corners; accessories and tools cannot inflate the box.
local function bounds(camera, character)
    local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            for _, corner in ipairs(corners) do
                local point = project(camera, part.CFrame:PointToWorldSpace(part.Size * corner))
                -- Hide near-plane intersections instead of drawing giant boxes.
                if not point then return nil end
                left, top = math.min(left, point.X), math.min(top, point.Y)
                right, bottom = math.max(right, point.X), math.max(bottom, point.Y)
            end
        end
    end
    local viewport = camera.ViewportSize
    if right < 0 or bottom < 0 or left > viewport.X or top > viewport.Y or left == math.huge then return nil end
    left, top = math.max(0, left - 2), math.max(0, top - 2)
    right, bottom = math.min(viewport.X, right + 2), math.min(viewport.Y, bottom + 2)
    return Vector2.new(math.floor(left), math.floor(top)), Vector2.new(math.max(1, math.ceil(right - left)), math.max(1, math.ceil(bottom - top)))
end
-- Clip skeleton segments to the viewport, including partially visible limbs.
local function clip(a, b, viewport)
    local delta, first, last = b - a, 0, 1
    local p = {-delta.X, delta.X, -delta.Y, delta.Y}
    local q = {a.X, viewport.X - a.X, a.Y, viewport.Y - a.Y}
    for i = 1, 4 do
        if math.abs(p[i]) < 0.00001 then
            if q[i] < 0 then return nil end
        else
            local t = q[i] / p[i]
            if p[i] < 0 then first = math.max(first, t) else last = math.min(last, t) end
            if first > last then return nil end
        end
    end
    return a + delta * first, a + delta * last
end
local bindName = "KoreanHub_ESP_Quality"
-- Clean up the previous enhanced ESP renderer if this script is re-executed.
if type(_G.KoreanHubESPCleanup) == "function" then _G.KoreanHubESPCleanup() end
local removing = Players.PlayerRemoving:Connect(clear)
_G.KoreanHubESPCleanup = function()
    RunService:UnbindFromRenderStep(bindName)
    removing:Disconnect()
    for player in pairs(entries) do clear(player) end
end
RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 1, function()
    local camera = workspace.CurrentCamera
    local active = camera and _G.ESPEnabled and (_G.BoxESP or _G.TracerESP or _G.SkeletonESP)
    for _, entry in pairs(entries) do hide(entry) end
    if not active then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local origin = myRoot and myRoot.Position or camera.CFrame.Position
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local entry = entries[player]
        if entry and entry.character ~= character then clear(player); entry = nil end
        local teammate = not player.Neutral and not LocalPlayer.Neutral and player.Team ~= nil and player.Team == LocalPlayer.Team
        if player ~= LocalPlayer and root and humanoid and humanoid.Health > 0
            and not (_G.ESPTeamCheck and teammate) and (origin - root.Position).Magnitude <= style.MaxDistance then
            local position, size = bounds(camera, character)
            if position then
                entry = entry or create(player, character)
                if _G.BoxESP then
                    for _, object in ipairs(entry.box) do object.Position = position; object.Size = size end
                    paint(entry.box, style.BoxColor, style.Opacity)
                end
                if _G.TracerESP then
                    local viewport = camera.ViewportSize
                    local y = style.TracerOrigin == "Top" and 2 or (style.TracerOrigin == "Center" and viewport.Y / 2 or viewport.Y - 2)
                    -- Stop at the box edge so the tracer does not cross the skeleton.
                    local targetY = style.TracerOrigin == "Top" and position.Y or position.Y + size.Y
                    line(entry.tracer, Vector2.new(viewport.X / 2, y), Vector2.new(position.X + size.X / 2, targetY), style.TracerColor, style.Opacity * 0.65)
                end
                if _G.SkeletonESP then
                    local bones = humanoid.RigType == Enum.HumanoidRigType.R15 and r15 or r6
                    for i, names in ipairs(bones) do
                        local a, b = character:FindFirstChild(names[1]), character:FindFirstChild(names[2])
                        if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                            local pa, pb = project(camera, a.Position), project(camera, b.Position)
                            if pa and pb then
                                local ca, cb = clip(pa, pb, camera.ViewportSize)
                                if ca then line(entry.bones[i], ca, cb, style.SkeletonColor, style.Opacity) end
                            end
                        end
                    end
                end
            end
        end
    end
end)
end

------------------------------------------------------------------
-- 5. Performance Tab
------------------------------------------------------------------
PerfTab:CreateButton({
    Name = "Unlock FPS (Max)",
    Callback = function()
        if setfpscap then setfpscap(9999) end
    end,
})

-- FPS Booster: three cumulative levels plus a full restore
local boosterBackup = setmetatable({}, { __mode = "k" })
local qualityBackup = nil
local boosterBusy = false

-- Remember the original value the first time a property is touched, then apply the new one
local function setProp(inst, prop, value)
    local ok, current = pcall(function() return inst[prop] end)
    if not ok then return end
    boosterBackup[inst] = boosterBackup[inst] or {}
    if boosterBackup[inst][prop] == nil then
        boosterBackup[inst][prop] = current
    end
    pcall(function() inst[prop] = value end)
end

local function setQuality(level)
    pcall(function()
        local rendering = settings().Rendering
        if qualityBackup == nil then qualityBackup = rendering.QualityLevel end
        rendering.QualityLevel = level
    end)
end

-- Walk descendants and yield every 500 items so big maps do not freeze the game
local function eachDescendant(root, fn)
    local count = 0
    for _, d in ipairs(root:GetDescendants()) do
        fn(d)
        count = count + 1
        if count % 500 == 0 then task.wait() end
    end
end

local EFFECT_CLASSES = { "ParticleEmitter", "Trail", "Beam", "Smoke", "Fire", "Sparkles" }

local function isEffect(d)
    for _, className in ipairs(EFFECT_CLASSES) do
        if d:IsA(className) then return true end
    end
    return false
end

-- Level 1 (Light): shadows and post-processing off
local function boostLevel1()
    setProp(Lighting, "GlobalShadows", false)
    eachDescendant(Lighting, function(d)
        if d:IsA("PostEffect") then setProp(d, "Enabled", false) end
    end)
end

-- Level 2 (Medium): particles, trails, beams off, terrain water and decoration off, lower render quality
local function boostLevel2()
    eachDescendant(workspace, function(d)
        if isEffect(d) then setProp(d, "Enabled", false) end
    end)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        setProp(terrain, "Decoration", false)
        setProp(terrain, "WaterWaveSize", 0)
        setProp(terrain, "WaterWaveSpeed", 0)
        setProp(terrain, "WaterReflectance", 0)
    end
    setQuality(Enum.QualityLevel.Level05)
end

-- Level 3 (Max): flat plastic materials, no textures or decals, no shadows on parts, no atmosphere, lowest quality
local function boostLevel3()
    eachDescendant(workspace, function(d)
        if d:IsA("BasePart") and not d:IsA("Terrain") then
            setProp(d, "Material", Enum.Material.SmoothPlastic)
            setProp(d, "Reflectance", 0)
            setProp(d, "CastShadow", false)
        elseif d:IsA("Decal") or d:IsA("Texture") then
            setProp(d, "Transparency", 1)
        end
    end)
    eachDescendant(Lighting, function(d)
        if d:IsA("Atmosphere") then
            setProp(d, "Density", 0)
            setProp(d, "Haze", 0)
        end
    end)
    setQuality(Enum.QualityLevel.Level01)
end

local function applyBooster(level)
    if boosterBusy then return notify("FPS Booster", "Still applying, wait a moment.") end
    boosterBusy = true
    notify("FPS Booster", "Applying level " .. level .. "...")
    task.spawn(function()
        local ok, err = pcall(function()
            boostLevel1()
            if level >= 2 then boostLevel2() end
            if level >= 3 then boostLevel3() end
        end)
        boosterBusy = false
        if ok then
            notify("FPS Booster", "Level " .. level .. " applied.")
        else
            notify("FPS Booster", "Error: " .. tostring(err))
        end
    end)
end

local function restoreGraphics()
    if boosterBusy then return notify("FPS Booster", "Still applying, wait a moment.") end
    for inst, props in pairs(boosterBackup) do
        for prop, value in pairs(props) do
            pcall(function() inst[prop] = value end)
        end
    end
    boosterBackup = setmetatable({}, { __mode = "k" })
    if qualityBackup ~= nil then
        pcall(function() settings().Rendering.QualityLevel = qualityBackup end)
        qualityBackup = nil
    end
    notify("FPS Booster", "Graphics restored.")
end

PerfTab:CreateButton({
    Name = "FPS Booster - Level 1 (Light)",
    Callback = function() applyBooster(1) end,
})

PerfTab:CreateButton({
    Name = "FPS Booster - Level 2 (Medium)",
    Callback = function() applyBooster(2) end,
})

PerfTab:CreateButton({
    Name = "FPS Booster - Level 3 (Max)",
    Callback = function() applyBooster(3) end,
})

PerfTab:CreateButton({
    Name = "Restore Graphics",
    Callback = restoreGraphics,
})

------------------------------------------------------------------
-- 6. Misc Tab
------------------------------------------------------------------
local targetName = ""
MiscTab:CreateInput({
    Name = "Target Player Name",
    PlaceholderText = "Username",
    Callback = function(text)
        targetName = text
    end,
})

MiscTab:CreateButton({
    Name = "Join Player's Server",
    Callback = function()
        local target = Players:FindFirstChild(targetName)
        if target then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target.JobId, LocalPlayer)
        end
    end,
})

------------------------------------------------------------------
-- 7. Server Tab
------------------------------------------------------------------
local ServerTab = Window:CreateTab("Server", 4483362458)
local HttpService = game:GetService("HttpService")

-- order: "Asc" = fewest players first, "Desc" = most players first
local function findServer(order)
    local cursor = ""
    for _ = 1, 5 do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100%s")
            :format(game.PlaceId, order, cursor ~= "" and ("&cursor=" .. cursor) or "")

        local okGet, body = pcall(function() return game:HttpGet(url) end)
        if not okGet then return nil end

        local okJson, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not okJson or not data or not data.data then return nil end

        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId
                and s.playing and s.maxPlayers
                and s.playing >= 1
                and s.playing < s.maxPlayers - 1 then
                return s
            end
        end

        if not data.nextPageCursor then break end
        cursor = data.nextPageCursor
    end
    return nil
end

local function hop(order, label)
    notify(label, "Searching...")
    task.spawn(function()
        local server = findServer(order)
        if server then
            notify(label, ("Joining server (%d/%d)"):format(server.playing, server.maxPlayers))
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
        else
            notify(label, "No server found.")
        end
    end)
end

ServerTab:CreateButton({
    Name = "Join Low Population Server",
    Callback = function() hop("Asc", "Low Pop Hop") end,
})

ServerTab:CreateButton({
    Name = "Join High Population Server",
    Callback = function() hop("Desc", "High Pop Hop") end,
})

------------------------------------------------------------------
-- 9. Utility Tab
------------------------------------------------------------------
local UtilityTab = Window:CreateTab("Utility", 4483362458)
autoFlag(UtilityTab, "Util")

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local DEFAULT_GRAVITY = 196.2

-- Set a Rayfield element by flag so the UI and the feature stay in sync
local function setFlag(flag, value)
    local el = Rayfield.Flags[flag]
    if el then
        pcall(function() el:Set(value) end)
    end
end

-- Gravity slider (feeds Reset Movement)
local gravitySlider = UtilityTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 400},
    Increment = 0.1,
    CurrentValue = DEFAULT_GRAVITY,
    Callback = function(v)
        workspace.Gravity = v
    end,
})

UtilityTab:CreateInput({
    Name = "Type Gravity",
    CurrentValue = "",
    PlaceholderText = "0-400 (press Enter)",
    RemoveTextAfterFocusLost = false,
    Flag = "Util_TypeGravity",
    Callback = function(text)
        local number = tonumber(text)
        if not number or number ~= number or number == math.huge or number == -math.huge then return end
        gravitySlider:Set(math.clamp(math.floor(number * 10 + 0.5) / 10, 0, 400))
    end,
})

-- Reset Movement: speed, jump power, gravity back to defaults, movement hacks off
UtilityTab:CreateButton({
    Name = "Reset Movement",
    Callback = function()
        setFlag("Move_FlyHack", false)
        setFlag("Move_Noclip", false)
        setFlag("Move_InfiniteJump", false)
        setFlag("Move_ClickTP", false)
        setFlag("Move_StunMovementAssist", false)
        _G.LoopSpeed = false
        _G.LoopJumpPower = false
        setFlag("Move_LoopSpeed", false)
        setFlag("Move_LoopJumpPower", false)
        setFlag("Move_WalkSpeed", DEFAULT_WALKSPEED)
        setFlag("Move_JumpPower", DEFAULT_JUMPPOWER)
        setFlag("Util_Gravity", DEFAULT_GRAVITY)

        workspace.Gravity = DEFAULT_GRAVITY
        _G.WalkSpeedVal = DEFAULT_WALKSPEED
        _G.JumpPowerVal = DEFAULT_JUMPPOWER

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = DEFAULT_WALKSPEED
            hum.UseJumpPower = true
            hum.JumpPower = DEFAULT_JUMPPOWER
            hum.PlatformStand = false
        end
        notify("Reset Movement", "Speed, jump power and gravity restored.")
    end,
})

-- Fog Removal: toggle, keeps fog off even if the game re-applies it, restores on disable
local fogOn = false
local fogBackup = nil

local function backupFog()
    fogBackup = {
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Atmospheres = {},
    }
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then
            fogBackup.Atmospheres[v] = { Density = v.Density, Haze = v.Haze }
        end
    end
end

local function applyFogRemoval()
    Lighting.FogStart = 9e9
    Lighting.FogEnd = 9e9
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then
            v.Density = 0
            v.Haze = 0
        end
    end
end

local function restoreFog()
    if not fogBackup then return end
    Lighting.FogStart = fogBackup.FogStart
    Lighting.FogEnd = fogBackup.FogEnd
    for atmos, values in pairs(fogBackup.Atmospheres) do
        if atmos.Parent then
            atmos.Density = values.Density
            atmos.Haze = values.Haze
        end
    end
    fogBackup = nil
end

RunService.RenderStepped:Connect(function()
    if fogOn then applyFogRemoval() end
end)

UtilityTab:CreateToggle({
    Name = "Fog Removal",
    CurrentValue = false,
    Callback = function(state)
        fogOn = state
        if state then
            backupFog()
            applyFogRemoval()
        else
            restoreFog()
        end
    end,
})

-- Reset Character: instant respawn
UtilityTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        -- God Mode locks health and Fly holds the body, so release both first
        _G.GodMode = false
        setFlag("Combat_GodModeHealthLock", false)
        setFlag("Move_FlyHack", false)

        local char = LocalPlayer.Character
        if not char then return notify("Reset Character", "No character found.") end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
        pcall(function() char:BreakJoints() end)
    end,
})

-- Rejoin Server: same server when others are in it, fresh server when you are alone
local function rejoinServer()
    notify("Rejoin Server", "Rejoining...")
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = rejoinServer,
})

------------------------------------------------------------------
-- 10. Players Tab
------------------------------------------------------------------
local PlayersTab = Window:CreateTab("Players", 4483362458)

local selectedTarget = nil
local loopTpOn = false
local followDistance = 3
local LoopToggle

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    table.sort(names)
    return names
end

local function getRoot(player)
    local char = player and player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportToTarget()
    local myRoot = getRoot(LocalPlayer)
    local targetRoot = getRoot(selectedTarget and Players:FindFirstChild(selectedTarget))
    if not myRoot or not targetRoot then return false end
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, followDistance)
    myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    return true
end

local PlayerDropdown = PlayersTab:CreateDropdown({
    Name = "Select Player",
    Options = getPlayerNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(option)
        selectedTarget = type(option) == "table" and option[1] or option
    end,
})

local function refreshPlayerList()
    pcall(function() PlayerDropdown:Refresh(getPlayerNames()) end)
end

PlayersTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        refreshPlayerList()
        notify("Players", "Player list refreshed.")
    end,
})

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function()
    task.delay(0.5, refreshPlayerList)
end)

PlayersTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if not selectedTarget then return notify("Teleport", "Select a player first.") end
        if not teleportToTarget() then notify("Teleport", "Target has no character.") end
    end,
})

PlayersTab:CreateSlider({
    Name = "Follow Distance",
    Range = {0, 20},
    Increment = 1,
    CurrentValue = 3,
    Callback = function(v)
        followDistance = v
    end,
})

LoopToggle = PlayersTab:CreateToggle({
    Name = "Loop Teleport (Follow)",
    CurrentValue = false,
    Callback = function(state)
        if state and not selectedTarget then
            notify("Loop Teleport", "Select a player first.")
            if LoopToggle then LoopToggle:Set(false) end
            return
        end
        loopTpOn = state
    end,
})

RunService.Heartbeat:Connect(function()
    if loopTpOn then teleportToTarget() end
end)

------------------------------------------------------------------
-- 11. X-Ray Mode (Visuals Tab)
------------------------------------------------------------------
local xrayOn = false
local xrayParts = {}
local xrayConn = nil
local XRAY_AMOUNT = 0.6

local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function xrayPart(part)
    if part:IsA("BasePart") and not isCharacterPart(part) then
        part.LocalTransparencyModifier = XRAY_AMOUNT
        xrayParts[part] = true
    end
end

VisualsTab:CreateToggle({
    Name = "X-Ray Mode",
    CurrentValue = false,
    Callback = function(state)
        xrayOn = state
        if state then
            if xrayConn then xrayConn:Disconnect() end
            xrayConn = workspace.DescendantAdded:Connect(function(d)
                if xrayOn then xrayPart(d) end
            end)
            task.spawn(function()
                local count = 0
                for _, d in ipairs(workspace:GetDescendants()) do
                    if not xrayOn then break end
                    xrayPart(d)
                    count = count + 1
                    if count % 300 == 0 then task.wait() end
                end
            end)
        else
            if xrayConn then
                xrayConn:Disconnect()
                xrayConn = nil
            end
            for part in pairs(xrayParts) do
                if part.Parent then part.LocalTransparencyModifier = 0 end
            end
            xrayParts = {}
        end
    end,
})

------------------------------------------------------------------
-- 12. Anti AFK and Anti Dev (Misc Tab)
------------------------------------------------------------------
local antiAfkOn = true

LocalPlayer.Idled:Connect(function()
    if antiAfkOn then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

MiscTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Callback = function(state)
        antiAfkOn = state
    end,
})

local antiDevOn = false
local staffRankThreshold = 100
local ROBLOX_STAFF_GROUP_ID = 1200769

-- Game owner, high rank in the owner group, or Roblox staff group member
local function isStaff(p)
    if p == LocalPlayer then return false end
    local ok, result = pcall(function()
        if game.CreatorType == Enum.CreatorType.User then
            if p.UserId == game.CreatorId then return true end
        else
            if p:GetRankInGroup(game.CreatorId) >= staffRankThreshold then return true end
        end
        return p:GetRankInGroup(ROBLOX_STAFF_GROUP_ID) > 0
    end)
    return ok and result == true
end

local function checkStaff(p)
    if not antiDevOn then return end
    task.spawn(function()
        if antiDevOn and isStaff(p) then
            LocalPlayer:Kick("Anti Dev: staff detected (" .. p.Name .. ")")
        end
    end)
end

Players.PlayerAdded:Connect(checkStaff)

MiscTab:CreateToggle({
    Name = "Anti Dev",
    CurrentValue = false,
    Callback = function(state)
        antiDevOn = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do
                checkStaff(p)
            end
        end
    end,
})

MiscTab:CreateSlider({
    Name = "Staff Rank Threshold",
    Range = {1, 255},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(v)
        staffRankThreshold = v
    end,
})

------------------------------------------------------------------
-- 13. Animations Tab
------------------------------------------------------------------
local AnimTab = Window:CreateTab("Animations", 4483362458)
autoFlag(AnimTab, "Anim")

-- Official Roblox emote animation IDs, one per rig type
local ANIMATIONS = {
    ["Dance 1"] = { R15 = 507771019, R6 = 182435998 },
    ["Dance 2"] = { R15 = 507776043, R6 = 182491037 },
    ["Dance 3"] = { R15 = 507777268, R6 = 182491065 },
    ["Wave"]    = { R15 = 507770239, R6 = 128777973 },
    ["Point"]   = { R15 = 507770453, R6 = 128853357 },
    ["Cheer"]   = { R15 = 507770677, R6 = 129423030 },
    ["Laugh"]   = { R15 = 507770818, R6 = 129423131 },
}
local animNames = { "Dance 1", "Dance 2", "Dance 3", "Wave", "Point", "Cheer", "Laugh" }

local selectedAnim = "Dance 1"
local customAnimId = ""
local animLoop = true
local animSpeed = 1
local currentTrack = nil

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function stopAnimation()
    if currentTrack then
        pcall(function()
            currentTrack:Stop()
            currentTrack:Destroy()
        end)
        currentTrack = nil
    end
end

local function playAnimation(id)
    local hum = getHumanoid()
    if not hum then return notify("Animations", "No character found.") end

    stopAnimation()

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(id)

    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then return notify("Animations", "Failed to load animation.") end

    track.Priority = Enum.AnimationPriority.Action
    track.Looped = animLoop
    track:Play()
    track:AdjustSpeed(animSpeed)
    currentTrack = track
end

local function playNamedAnimation(name)
    local hum = getHumanoid()
    local ids = ANIMATIONS[name]
    if not hum or not ids then return notify("Animations", "No character or animation found.") end
    local rig = hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
    playAnimation(ids[rig])
end

LocalPlayer.CharacterAdded:Connect(function()
    currentTrack = nil
end)

AnimTab:CreateDropdown({
    Name = "Select Animation",
    Options = animNames,
    CurrentOption = {"Dance 1"},
    MultipleOptions = false,
    Callback = function(option)
        selectedAnim = type(option) == "table" and option[1] or option
    end,
})

AnimTab:CreateButton({
    Name = "Play Animation",
    Callback = function()
        playNamedAnimation(selectedAnim)
    end,
})

AnimTab:CreateButton({
    Name = "Stop Animation",
    Callback = function()
        stopAnimation()
    end,
})

AnimTab:CreateToggle({
    Name = "Loop Animation",
    CurrentValue = true,
    Callback = function(state)
        animLoop = state
        if currentTrack then
            pcall(function() currentTrack.Looped = state end)
        end
    end,
})

AnimTab:CreateSlider({
    Name = "Animation Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(v)
        animSpeed = v
        if currentTrack then
            pcall(function() currentTrack:AdjustSpeed(v) end)
        end
    end,
})

AnimTab:CreateInput({
    Name = "Custom Animation ID",
    PlaceholderText = "Animation asset ID",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        customAnimId = text:match("%d+") or ""
    end,
})

AnimTab:CreateButton({
    Name = "Play Custom ID",
    Callback = function()
        if customAnimId == "" then return notify("Animations", "Enter an animation ID first.") end
        playAnimation(customAnimId)
    end,
})

------------------------------------------------------------------
-- 14. Config Tab (kept last)
------------------------------------------------------------------
local ConfigTab = Window:CreateTab("Config", 4483362458)

local ROOT_DIR = "KoreanHubConfigs"
local PROFILE_DIR = ROOT_DIR .. "/Profiles"
local fsReady = writefile and readfile and listfiles and isfolder and makefolder and delfile and isfile

local function ensureFolders()
    if not isfolder(ROOT_DIR) then makefolder(ROOT_DIR) end
    if not isfolder(PROFILE_DIR) then makefolder(PROFILE_DIR) end
end

local function listProfiles()
    if not fsReady then return {} end
    ensureFolders()
    local names = {}
    for _, path in ipairs(listfiles(PROFILE_DIR)) do
        local name = path:match("([^/\\]+)%.json$")
        if name then table.insert(names, name) end
    end
    table.sort(names)
    return names
end

local function serializeFlags()
    local data = {}
    for flag, el in pairs(Rayfield.Flags) do
        if el.Type == "ColorPicker" then
            local c = el.Color
            if typeof(c) == "Color3" then
                data[flag] = {R = c.R, G = c.G, B = c.B}
            end
        elseif el.Type == "Dropdown" then
            data[flag] = el.CurrentOption
        elseif el.CurrentValue ~= nil then
            data[flag] = el.CurrentValue
        end
    end
    return HttpService:JSONEncode(data)
end

local function applyFlags(data)
    local applied = 0
    for flag, value in pairs(data) do
        local el = Rayfield.Flags[flag]
        if el then
            local ok = pcall(function()
                if el.Type == "ColorPicker" and type(value) == "table" then
                    el:Set(Color3.new(value.R, value.G, value.B))
                else
                    el:Set(value)
                end
            end)
            if ok then applied = applied + 1 end
        end
    end
    return applied
end

local profileName = ""
local selectedProfile = nil

ConfigTab:CreateInput({
    Name = "Profile Name",
    PlaceholderText = "e.g. legit, rage, pvp",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        profileName = (text:gsub("[^%w_%-]", ""))
    end,
})

local ProfileDropdown = ConfigTab:CreateDropdown({
    Name = "Saved Profiles",
    Options = listProfiles(),
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(option)
        selectedProfile = type(option) == "table" and option[1] or option
    end,
})

ConfigTab:CreateButton({
    Name = "Save Profile",
    Callback = function()
        if not fsReady then return notify("Config", "Executor has no file functions.") end
        if profileName == "" then return notify("Config", "Enter a profile name.") end
        ensureFolders()
        writefile(PROFILE_DIR .. "/" .. profileName .. ".json", serializeFlags())
        ProfileDropdown:Refresh(listProfiles())
        notify("Config", "Saved: " .. profileName)
    end,
})

ConfigTab:CreateButton({
    Name = "Load Profile",
    Callback = function()
        if not fsReady then return notify("Config", "Executor has no file functions.") end
        if not selectedProfile or selectedProfile == "" then return notify("Config", "Select a profile.") end
        local path = PROFILE_DIR .. "/" .. selectedProfile .. ".json"
        if not isfile(path) then return notify("Config", "Profile file missing.") end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not ok then return notify("Config", "Profile is corrupted.") end
        notify("Config", ("Loaded %s (%d settings)"):format(selectedProfile, applyFlags(data)))
    end,
})

ConfigTab:CreateButton({
    Name = "Delete Profile",
    Callback = function()
        if not fsReady then return notify("Config", "Executor has no file functions.") end
        if not selectedProfile or selectedProfile == "" then return notify("Config", "Select a profile.") end
        local path = PROFILE_DIR .. "/" .. selectedProfile .. ".json"
        if isfile(path) then delfile(path) end
        notify("Config", "Deleted: " .. selectedProfile)
        selectedProfile = nil
        ProfileDropdown:Refresh(listProfiles())
    end,
})

ConfigTab:CreateButton({
    Name = "Refresh Profile List",
    Callback = function()
        ProfileDropdown:Refresh(listProfiles())
    end,
})

ConfigTab:CreateButton({
    Name = "Save Default Config (Auto-Load)",
    Callback = function()
        Rayfield:SaveConfiguration()
        notify("Config", "Default config saved. It loads on next execute.")
    end,
})

-- NPC hitboxes and proximity-triggered equipped-tool activation.
do
    if type(_G.KoreanHubCombatExtrasCleanup) == "function" then _G.KoreanHubCombatExtrasCleanup() end
    local settings = {Hitbox = false, Size = 8, NPC = false, Player = false, Radius = 30, Interval = 0.25, TeamCheck = true}
    local humanoids, backups, connections = {}, {}, {}
    local activeTool, releaseAt = nil, 0
    local function releaseTool()
        if type(_G.KoreanHubCombatRelease) == "function" then _G.KoreanHubCombatRelease("aura") end
        if activeTool and activeTool:IsA("Tool") then pcall(function() activeTool:Deactivate() end) end
        activeTool = nil
    end
    local function restore(part)
        local original = backups[part]
        if original then
            if part.Parent then
                pcall(function()
                    part.Size = original.Size
                    part.Transparency = original.Transparency
                    part.CanCollide = original.CanCollide
                end)
            end
            backups[part] = nil
        end
    end
    local function restoreAll()
        for part in pairs(backups) do restore(part) end
    end
    local function track(instance)
        if instance:IsA("Humanoid") then humanoids[instance] = true end
    end
    table.insert(connections, workspace.DescendantAdded:Connect(track))
    table.insert(connections, workspace.DescendantRemoving:Connect(function(instance)
        humanoids[instance] = nil
        if backups[instance] then restore(instance) end
    end))
    for _, instance in ipairs(workspace:GetDescendants()) do track(instance) end
    CombatTab:CreateSection("NPC Hitbox & Kill Aura")
    CombatTab:CreateParagraph({Title = "Equipped-tool mode", Content = "Aura activates an equipped tool (Tool or Model-type weapon) when a target is within the selected radius. Targets now include plain enemy Models with no owning Player (NPCs), not just other Players. A larger radius does not extend a weapon’s server-validated hit range."})
    CombatTab:CreateToggle({Name = "NPC Hitbox", CurrentValue = false, Callback = function(value)
        settings.Hitbox = value
        if not value then restoreAll() end
    end})
    CombatTab:CreateSlider({Name = "NPC Hitbox Size", Range = {2, 30}, Increment = 1, CurrentValue = 8,
        Callback = function(value) settings.Size = value end})
    CombatTab:CreateToggle({Name = "NPC Kill Aura (Tool)", Flag = "Combat_NPCKillAura", CurrentValue = false,
        Callback = function(value) settings.NPC = value; releaseTool() end})
    CombatTab:CreateToggle({Name = "Player Kill Aura (Tool)", Flag = "Combat_PlayerKillAura", CurrentValue = false,
        Callback = function(value) settings.Player = value; releaseTool() end})
    CombatTab:CreateSlider({Name = "Aura Radius (studs)", Range = {3, 100}, Increment = 1, CurrentValue = 30,
        Callback = function(value) settings.Radius = value end})
    CombatTab:CreateSlider({Name = "Aura Attack Interval", Range = {0.15, 2}, Increment = 0.05, CurrentValue = 0.25,
        Callback = function(value) settings.Interval = value end})
    CombatTab:CreateToggle({Name = "Aura Team Check", CurrentValue = true,
        Callback = function(value) settings.TeamCheck = value end})
    local elapsed, lastAttack = 0, -math.huge
    table.insert(connections, RunService.Heartbeat:Connect(function(dt)
        local now = os.clock()
        if activeTool and now >= releaseAt then releaseTool() end
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        if not (settings.Hitbox or settings.NPC or settings.Player) then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        local alive = root and ownHumanoid and ownHumanoid.Health > 0
        local touched, targetNearby = {}, false
        for humanoid in pairs(humanoids) do
            local model = humanoid.Parent
            if model and model:IsA("Model") and model:IsDescendantOf(workspace) then
                local owner = Players:GetPlayerFromCharacter(model)
                local targetRoot = model:FindFirstChild("HumanoidRootPart")
                if targetRoot and targetRoot:IsA("BasePart") and model ~= character and humanoid.Health > 0 then
                    local npc = owner == nil
                    if settings.Hitbox and npc then
                        if not backups[targetRoot] then
                            backups[targetRoot] = {Size = targetRoot.Size, Transparency = targetRoot.Transparency, CanCollide = targetRoot.CanCollide}
                        end
                        touched[targetRoot] = true
                        targetRoot.Size = Vector3.new(settings.Size, settings.Size, settings.Size)
                        targetRoot.Transparency = 0.75
                        targetRoot.CanCollide = false
                    end
                    local teammate = owner and not owner.Neutral and not LocalPlayer.Neutral and owner.Team ~= nil and owner.Team == LocalPlayer.Team
                    local eligible = (npc and settings.NPC) or (owner and owner ~= LocalPlayer and settings.Player and not (settings.TeamCheck and teammate))
                    if alive and eligible and (targetRoot.Position - root.Position).Magnitude <= settings.Radius then
                        targetNearby = true
                    end
                end
            end
        end
        for part in pairs(backups) do if not touched[part] then restore(part) end end
        if not alive or not targetNearby then releaseTool(); return end
        if now - lastAttack < settings.Interval then return end
        local tool = _G.KoreanHubFindWeapon(character)
        if not tool or not _G.KoreanHubWeaponReady(tool) then return end
        if type(_G.KoreanHubCombatTryActivate) == "function" then
            if _G.KoreanHubCombatTryActivate(tool, settings.Interval, 0.15, "aura", settings.Radius) then lastAttack = now end
            return
        end
        lastAttack = now
        releaseTool()
        local ok = _G.KoreanHubFireWeapon(tool)
        if ok then activeTool = tool; releaseAt = now + 0.05 end
    end))
    _G.KoreanHubCombatExtrasCleanup = function()
        for _, connection in ipairs(connections) do connection:Disconnect() end
        releaseTool()
        restoreAll()
    end
end

-- Automatically hold visible Roblox proximity prompts for their required duration.
do
    if type(_G.KoreanHubAutoHoldCleanup) == "function" then
        _G.KoreanHubAutoHoldCleanup()
    end
    local promptService = game:GetService("ProximityPromptService")
    local enabled, current, generation = false, nil, 0
    local connections = {}
    local function stop()
        generation = generation + 1
        if current and current.Parent then
            pcall(function() current:InputHoldEnd() end)
        end
        current = nil
    end
    local function begin(prompt)
        if not enabled or current or not prompt.Enabled or not prompt:IsDescendantOf(workspace) then return end
        current = prompt
        generation = generation + 1
        local ticket = generation
        local ok = pcall(function() prompt:InputHoldBegin() end)
        if not ok then current = nil; return end
        task.delay(math.max(0, prompt.HoldDuration) + 0.15, function()
            if ticket == generation and current == prompt then stop() end
        end)
    end
    table.insert(connections, promptService.PromptShown:Connect(begin))
    table.insert(connections, promptService.PromptHidden:Connect(function(prompt)
        if current == prompt then stop() end
    end))
    MiscTab:CreateToggle({Name = "Auto Hold Prompts", CurrentValue = false,
        Flag = "Misc_AutoHoldPrompts", Callback = function(state)
            enabled = state
            if not state then stop() end
        end})
    _G.KoreanHubAutoHoldCleanup = function()
        enabled = false
        stop()
        for _, connection in ipairs(connections) do connection:Disconnect() end
    end
end

-- Hitbox outlines and optional local prompt duration override.
do
    if type(_G.KoreanHubUniversalExtrasCleanup)=="function" then _G.KoreanHubUniversalExtrasCleanup() end
    local show,instant=false,false
    local boxes,holds,connections={},{},{}
    local color=Color3.fromRGB(255,95,75)
    local function clearBoxes()
        for part,box in pairs(boxes) do box:Destroy();boxes[part]=nil end
    end
    local function restoreHolds()
        for prompt,value in pairs(holds) do
            pcall(function() prompt.HoldDuration=value end)
            holds[prompt]=nil
        end
    end
    local function shorten(prompt)
        if not instant or not prompt:IsA("ProximityPrompt") then return end
        if holds[prompt]==nil then holds[prompt]=prompt.HoldDuration end
        prompt.HoldDuration=0
    end
    CombatTab:CreateSection("플레이어 히트박스 표시")
    CombatTab:CreateToggle({Name="히트박스 테두리 (플레이어+NPC)",Flag="Combat_HitboxOutline",CurrentValue=false,Callback=function(v)
        show=v;if not v then clearBoxes() end
    end})
    CombatTab:CreateColorPicker({Name="히트박스 표시 색상",Flag="Combat_HitboxOutlineColor",Color=color,Callback=function(v) color=v end})
    MiscTab:CreateSection("길게 누르는 상호작용")
    MiscTab:CreateToggle({Name="길게 누르기 → 즉시 누르기",Flag="Misc_InstantPrompt",CurrentValue=false,Callback=function(v)
        instant=v
        if v then for _,o in ipairs(workspace:GetDescendants()) do shorten(o) end
        else restoreHolds() end
    end})
    MiscTab:CreateParagraph({Title="적용 범위",Content="Roblox ProximityPrompt의 로컬 대기시간을 0으로 조절합니다. 직접 만든 버튼이나 서버에서 확인하는 대기시간에는 적용되지 않을 수 있습니다. 끄면 원래 시간으로 복구합니다."})
    table.insert(connections,workspace.DescendantAdded:Connect(shorten))
    table.insert(connections,game:GetService("ProximityPromptService").PromptShown:Connect(shorten))
    local elapsed=0
    table.insert(connections,RunService.Heartbeat:Connect(function(dt)
        elapsed=elapsed+dt;if elapsed<0.15 then return end;elapsed=0
        if not show then return end
        local keep={}
        for _,enemy in ipairs(_G.KoreanHubFindEnemies(false)) do
            local char=enemy.model
            for _,part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and (part.Name=="HumanoidRootPart" or (_G.HitboxExpander and part.Transparency>=0.5 and part.Name~="Handle")) then
                    keep[part]=true
                    local box=boxes[part]
                    if not box then
                        box=Instance.new("SelectionBox");box.Name="KoreanHubHitboxOutline"
                        box.Adornee=part;box.LineThickness=0.025;box.SurfaceTransparency=1;box.Parent=part;boxes[part]=box
                    end
                    box.Color3=color
                end
            end
        end
        for part,box in pairs(boxes) do if not keep[part] then box:Destroy();boxes[part]=nil end end
    end))
    _G.KoreanHubUniversalExtrasCleanup=function()
        show=false;instant=false
        for _,c in ipairs(connections) do c:Disconnect() end
        clearBoxes();restoreHolds()
    end
end

-- Mobile trigger: first world ray hit must belong to a living other player.
do
    if type(_G.KoreanHubTriggerCleanup)=="function" then _G.KoreanHubTriggerCleanup() end
    local enabled,teamCheck=false,true
    local interval,distance,hold=0.25,500,0.08
    local lastLauncherAttempt=-math.huge
    local elapsed,lastMessage=0,nil
    local modelDown=false
    local function equipped(char)
        return char and _G.KoreanHubFindWeapon(char)
    end
    local function modelReady(model)
        local flag=model:FindFirstChild("Enabled")
        return not flag or not flag:IsA("BoolValue") or flag.Value
    end
    local tapAim=false
    local aimPart,aimUntil=nil,0
    local function chooseFOV(camera,char)
        local center=camera.ViewportSize/2
        local best=math.huge
        local selected,selectedPart=nil,nil
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
        for _,enemy in ipairs(_G.KoreanHubFindEnemies(teamCheck)) do
            local c=enemy.model
            local part=c:FindFirstChild(_G.AimPart=="Body" and "HumanoidRootPart" or "Head") or enemy.root
            if part and part:IsA("BasePart") then
                local delta=part.Position-camera.CFrame.Position
                local pos,visible=camera:WorldToViewportPoint(part.Position)
                local gap=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                if visible and pos.Z>0 and gap<=best and delta.Magnitude<=distance then
                    local hit=workspace:Raycast(camera.CFrame.Position,delta,params)
                    if not hit or hit.Instance:IsDescendantOf(c) then
                        best=gap
                        selected={Name=c.Name,Character=c,Player=enemy.owner}
                        selectedPart=part
                    end
                end
            end
        end
        return selected,selectedPart
    end
    local function face(camera,part)
        if part and part.Parent and (part.Position-camera.CFrame.Position).Magnitude>0.01 then
            camera.CFrame=CFrame.lookAt(camera.CFrame.Position,part.Position)
        end
    end
    CombatTab:CreateToggle({Name="터치/클릭 시 화면 상대 조준",Flag="Combat_TapFOVAim",CurrentValue=false,Callback=function(v)
        tapAim=v;if not v then aimPart=nil;aimUntil=0 end
    end})
    CombatTab:CreateParagraph({Title="화면 전체 기준",Content="원 없이 화면 전체에서 중심에 가장 가까운 보이는 상대를 선택합니다. 카메라 조준이며 서버의 탄환 방향을 변경하지 않습니다."})
    local function onTap(processed)
        if processed or not tapAim or modelDown then return end
        local camera=workspace.CurrentCamera
        local char=LocalPlayer.Character
        local h=char and char:FindFirstChildOfClass("Humanoid")
        if not camera or not h or h.Health<=0 or not equipped(char) or UserInputService:GetFocusedTextBox() then return end
        if camera.CameraType==Enum.CameraType.Scriptable then return end
        local _,part=chooseFOV(camera,char)
        if part then aimPart=part;aimUntil=os.clock()+0.2;face(camera,part) end
    end
    local mouseConnection=UserInputService.InputBegan:Connect(function(input,processed)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then onTap(processed) end
    end)
    local touchConnection=UserInputService.TouchTapInWorld:Connect(function(_,processed) onTap(processed) end)
    RunService:UnbindFromRenderStep("KoreanHubTapAimV1")
    RunService:BindToRenderStep("KoreanHubTapAimV1",Enum.RenderPriority.Camera.Value+2,function()
        local camera=workspace.CurrentCamera
        if camera and aimPart and os.clock()<aimUntil and not UserInputService:GetFocusedTextBox()
            and camera.CameraType~=Enum.CameraType.Scriptable then face(camera,aimPart) end
    end)
    local label
    local function status(text)
        if text~=lastMessage then
            if label then
                local ok=pcall(function() label:Set(text) end)
                if ok then lastMessage=text end
            end
        end
    end
    local function stop()
        local release=_G.KoreanHubCombatRelease
        if type(release)=="function" then release("trigger") end
    end
    CombatTab:CreateSection("모바일 Triggerbot")
    local triggerControl
    triggerControl=CombatTab:CreateToggle({Name="Triggerbot · 화면 안의 상대 자동 조준·사용",Flag="Combat_MobileTrigger",CurrentValue=false,Callback=function(v)
        enabled=v==true;lastMessage=nil
        if not enabled then stop() end
        status(enabled and "Triggerbot 켜짐 · 화면 대상 대기" or "Triggerbot 꺼짐")
    end})
    CombatTab:CreateToggle({Name="Triggerbot 아군 제외",Flag="Combat_TriggerTeam",CurrentValue=true,Callback=function(v) teamCheck=v end})
    CombatTab:CreateSlider({Name="Triggerbot 발사 간격",Flag="Combat_TriggerInterval",Range={0.05,2},Increment=0.05,CurrentValue=0.25,Callback=function(v) interval=v end})
    CombatTab:CreateSlider({Name="Triggerbot 최대 거리",Flag="Combat_TriggerDistance",Range={10,2000},Increment=10,CurrentValue=500,Callback=function(v) distance=v end})
    CombatTab:CreateSlider({Name="Triggerbot 누르는 시간",Flag="Combat_TriggerHold",Range={0.05,1},Increment=0.05,CurrentValue=0.08,Callback=function(v) hold=v end})
    CombatTab:CreateParagraph({Title="화면 전체 자동 조준·발사 시도",Content="화면 전체에서 Player와 NPC Model 상대를 모두 찾아 카메라를 조준합니다. 일반 Tool은 자동 사용을 시도합니다. Model 무기는 기록된 게임의 Launcher는 전용 Vector3 발사 형식을 쓰고, 그 외 Model 무기는 Activate 원격을 인자 없이 호출해 시도합니다 · 이 발사 형식이 맞지 않는 게임에서는 명중이 보장되지 않습니다. 가상 마우스를 사용하지 않습니다."})
    label=CombatTab:CreateLabel(enabled and "Triggerbot 켜짐 · 화면 대상 대기" or "Triggerbot 꺼짐")
    CombatTab:CreateButton({Name="Triggerbot 상태 동기화",Callback=function()
        if triggerControl and type(triggerControl.CurrentValue)=="boolean" then enabled=triggerControl.CurrentValue end
        lastMessage=nil
        status(enabled and "Triggerbot 켜짐 · 화면 대상 대기" or "Triggerbot 꺼짐")
    end})
    local function updateTrigger(dt)
        if not enabled then return end
        elapsed=elapsed+dt;if elapsed<0.04 then return end;elapsed=0
        local camera=workspace.CurrentCamera
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local tool=equipped(char)
        local function waitFor(text) stop();status(text) end
        if not camera or not hum or hum.Health<=0 then waitFor("Triggerbot · 캐릭터 대기");return end
        if UserInputService:GetFocusedTextBox() or camera.CameraType==Enum.CameraType.Scriptable then waitFor("Triggerbot · 입력/연출 중 대기");return end
        if not tool then waitFor("Triggerbot · 총/툴을 장착하세요");return end
        local target,part=chooseFOV(camera,char)
        if not target then waitFor("Triggerbot · "..tool.Name.." 감지 · 화면 안의 상대 대기");return end
        aimPart=part;aimUntil=os.clock()+0.12
        face(camera,part)
        if tool:IsA("Model") then
            if not (game.PlaceId==86437684815842 and tool.Name=="Launcher") then
                -- Unverified Model weapon: attempt a plain Activate:FireServer() with no arguments.
                -- This matches most ToolSlot-style weapons but not ones that expect a target or position.
                if not modelReady(tool) then waitFor(tool.Name.." · 게임 재사용 대기");return end
                if os.clock()-lastLauncherAttempt<math.max(interval,0.1) then return end
                lastLauncherAttempt=os.clock()
                local ok=_G.KoreanHubFireWeapon(tool)
                status((ok and "자동 조준+발사 시도: " or "자동 조준 · 발사 실패: ")..tool.Name.." · "..target.Name.." · 발사 형식 미확인이라 명중은 보장 못함")
                return
            end
            if not modelReady(tool) then waitFor("Launcher · 게임 재사용 대기");return end
            if os.clock()-lastLauncherAttempt<math.max(interval,0.1) then return end
            local remote=tool:FindFirstChild("Activate")
            if not remote or not remote:IsA("RemoteEvent") or tool.Parent~=LocalPlayer.Character then
                waitFor("Launcher · 장착/Activate 확인 필요");return
            end
            if not part or not part:IsDescendantOf(target.Character) then return end
            lastLauncherAttempt=os.clock()
            -- Observed manual protocol in this place: Activate(Vector3).
            -- Coordinate semantics are inferred; do not apply to other models.
            local ok,err=pcall(function() remote:FireServer(part.Position) end)
            if not ok then status("Launcher 요청 실패: "..tostring(err):sub(1,140));return end
            status("Launcher · "..target.Name.." 위치로 발사 요청 · 명중 미확인")
            return
        end
        local activate=_G.KoreanHubCombatTryActivate
        if type(activate)~="function" then waitFor("Triggerbot · 툴 제어기 없음");return end
        local ok,result=pcall(activate,tool,interval,hold,"trigger")
        if not ok then waitFor("Triggerbot · 툴 실행 실패");return end
        status("Triggerbot · "..target.Name..(result and " · 툴 사용 시도" or " · 발사 간격/툴 준비 대기"))
    end
    local connection=RunService.Heartbeat:Connect(function(dt)
        local ok,err=pcall(updateTrigger,dt)
        if not ok then
            stop()
            status("Triggerbot 오류: "..tostring(err):sub(1,220))
        end
    end)
    _G.KoreanHubTriggerCleanup=function()
        enabled=false;tapAim=false;aimPart=nil
        connection:Disconnect();mouseConnection:Disconnect();touchConnection:Disconnect()
        RunService:UnbindFromRenderStep("KoreanHubTapAimV1");stop()
    end
end

-- Lightweight FPS display; updates twice per second and survives respawn.
do
    if type(_G.KoreanHubFPSCleanup) == "function" then _G.KoreanHubFPSCleanup() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "KoreanHubFPS"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.Enabled = false
    local label = Instance.new("TextLabel")
    label.Name = "Counter"
    label.AnchorPoint = Vector2.new(1, 0)
    label.Position = UDim2.new(1, -14, 0, 12)
    label.Size = UDim2.fromOffset(126, 34)
    label.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    label.BackgroundTransparency = 0.15
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(125, 240, 180)
    label.Text = "FPS: --"
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local elapsed, frames, connection = 0, 0, nil
    local function setVisible(value)
        gui.Enabled = value
        if connection then connection:Disconnect(); connection = nil end
        elapsed, frames = 0, 0
        label.Text = "FPS: --"
        if value then
            connection = RunService.RenderStepped:Connect(function(dt)
                elapsed, frames = elapsed + dt, frames + 1
                if elapsed >= 0.5 then
                    local fps = math.floor(frames / elapsed + 0.5)
                    label.Text = "FPS: " .. tostring(fps)
                    label.TextColor3 = fps >= 55 and Color3.fromRGB(125, 240, 180) or (fps >= 30 and Color3.fromRGB(255, 212, 110) or Color3.fromRGB(255, 120, 120))
                    elapsed, frames = 0, 0
                end
            end)
        end
    end
    PerfTab:CreateToggle({Name = "Show FPS", CurrentValue = false, Flag = "Perf_ShowFPS", Callback = setVisible})
    _G.KoreanHubFPSCleanup = function()
        if connection then connection:Disconnect() end
        gui:Destroy()
    end
end

-- Theme selection is registered before loading saved configuration.
do
    local ThemeTab = Window:CreateTab("Theme", 4483362458)
    local themes = {"Serenity", "Amethyst", "AmberGlow", "Default", "DarkBlue", "Ocean", "Green", "Bloom", "Light"}
    local allowed = {}
    for _, name in ipairs(themes) do allowed[name] = true end
    local themeDropdown = ThemeTab:CreateDropdown({
        Name = "Select Theme",
        Options = themes,
        CurrentOption = {"Default"},
        MultipleOptions = false,
        Flag = "Theme_SelectedTheme",
        Callback = function(option)
            local name = type(option) == "table" and option[1] or option
            if not allowed[name] then return end
            Window.ModifyTheme(name)
        end,
    })
    ThemeTab:CreateButton({
        Name = "Reset Theme to Default",
        Callback = function()
            themeDropdown:Set({"Default"})
        end,
    })
end

-- User-supplied Aether V2 Sword Fighting AI, scoped lifecycle integration.
do
    if type(_G.KoreanHubSwordAICleanup)=="function" then pcall(_G.KoreanHubSwordAICleanup) end
    local function mount(onChanged)
        local active=true
        local teamCheck,strictTeam=true,true
        local function teamRelation(a,b)
            -- Prefer matching explicit game fields; never infer from clothes or arena floor.
            for _,field in ipairs({"Team","TeamName","TeamId","TeamID","Faction","Side"}) do
                local function get(p)
                    for _,owner in ipairs({p,p.Character or p}) do
                        local value=owner:GetAttribute(field)
                        if value==nil then
                            local obj=owner:FindFirstChild(field)
                            if obj and obj:IsA("ValueBase") then value=obj.Value end
                        end
                        if value~=nil and tostring(value)~="" then return tostring(value):lower():gsub("%s+","") end
                    end
                end
                local x,y=get(a),get(b)
                if x and y then return x==y and "ally" or "enemy" end
            end
            if a.Team and b.Team then return a.Team==b.Team and "ally" or "enemy" end
            return "unknown"
        end
        local function eligiblePlayer(p)
            if not p or p==game:GetService("Players").LocalPlayer then return false end
            if not teamCheck then return true end
            local relation=teamRelation(game:GetService("Players").LocalPlayer,p)
            return relation=="enemy" or (relation=="unknown" and not strictTeam)
        end
        local connections={}
        local function track(signal,fn)
            local connection=signal:Connect(function(...) if active then return fn(...) end end)
            connections[#connections+1]=connection
            return connection
        end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "KoreanHubSwordAI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(150, 44)
button.Position = UDim2.new(0.5, -75, 0.72, 0)
button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamSemibold
button.Text = "AI: OFF"
button.AutoButtonColor = true
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(90, 90, 90)
stroke.Parent = button

local enabled = false
local function alive() return active and enabled end
local dragging = false
local dragStart
local startPos
local activeTouch
local dragInput

local currentCharacter
local currentHumanoid
local currentRoot

local targetState = {}
local lastAutoEquip = 0
local lastAttack = 0
local lastJump = 0
local sideSign = 1

local function f_up(val, min, max)
	return math.clamp((val - min) / (max - min), 0, 1)
end

local function f_down(val, min, max)
	return math.clamp(1 - ((val - min) / (max - min)), 0, 1)
end

local function f_tri(val, min, mid, max)
	if val <= min or val >= max then return 0 end
	if val <= mid then return (val - min) / (mid - min) end
	return 1 - ((val - mid) / (max - mid))
end

local function setButtonState()
	button.Text = enabled and "AI: ON" or "AI: OFF"
	button.BackgroundColor3 = enabled and Color3.fromRGB(35, 85, 45) or Color3.fromRGB(35, 35, 35)
end

local function getCharacter()
	currentCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid") or currentCharacter:WaitForChild("Humanoid")
	currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart") or currentCharacter:WaitForChild("HumanoidRootPart")
end

local function getCharHumRoot(plr)
	local char = plr.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return end
	return char, hum, root
end

local function getEquippedTool(char)
	if not char then return nil end
	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("Tool") then
			return obj
		end
	end
	return nil
end

local function getPreferredTool()
	local charTool = getEquippedTool(currentCharacter)
	if charTool then return charTool end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, obj in ipairs(backpack:GetChildren()) do
			if obj:IsA("Tool") then
				return obj
			end
		end
	end
end

local function getAdvancedToolMetrics(tool, char)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local fallbackPos = root and root.Position or Vector3.zero
	local defaultMetrics = {
		size = Vector3.new(1, 1, 1),
		thickness = 1,
		length = 1,
		com = fallbackPos,
		tip = root and (root.CFrame * CFrame.new(0, 0, -2)).Position or Vector3.zero,
		effectiveReach = 3.0,
		swingRadius = 4.5,
		max = 5.0,
		handlePos = fallbackPos
	}

	if not tool then return defaultMetrics end

	local parts = {}
	for _, obj in ipairs(tool:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
		end
	end

	local handle = tool:FindFirstChild("Handle")
	if not handle and #parts > 0 then
		handle = parts[1]
	end

	if #parts == 0 or not handle then
		return defaultMetrics
	end

	local totalMass = 0
	local comWeighted = Vector3.zero
	local handleCF = handle.CFrame

	local minExtents = Vector3.new(math.huge, math.huge, math.huge)
	local maxExtents = Vector3.new(-math.huge, -math.huge, -math.huge)

	for _, part in ipairs(parts) do
		totalMass = totalMass + part.Mass
		comWeighted = comWeighted + part.Position * part.Mass

		local partCF = part.CFrame
		local size = part.Size
		local hs = size / 2

		local corners = {
			partCF * Vector3.new(hs.X, hs.Y, hs.Z),
			partCF * Vector3.new(-hs.X, hs.Y, hs.Z),
			partCF * Vector3.new(hs.X, -hs.Y, hs.Z),
			partCF * Vector3.new(-hs.X, -hs.Y, hs.Z),
			partCF * Vector3.new(hs.X, hs.Y, -hs.Z),
			partCF * Vector3.new(-hs.X, hs.Y, -hs.Z),
			partCF * Vector3.new(hs.X, -hs.Y, -hs.Z),
			partCF * Vector3.new(-hs.X, -hs.Y, -hs.Z),
		}

		for _, corner in ipairs(corners) do
			local localPos = handleCF:PointToObjectSpace(corner)
			minExtents = Vector3.new(
				math.min(minExtents.X, localPos.X),
				math.min(minExtents.Y, localPos.Y),
				math.min(minExtents.Z, localPos.Z)
			)
			maxExtents = Vector3.new(
				math.max(maxExtents.X, localPos.X),
				math.max(maxExtents.Y, localPos.Y),
				math.max(maxExtents.Z, localPos.Z)
			)
		end
	end

	local com = totalMass > 0 and (comWeighted / totalMass) or handle.Position
	local dimensions = maxExtents - minExtents
	local length = math.max(dimensions.X, dimensions.Y, dimensions.Z)
	local thickness = math.min(dimensions.X, dimensions.Y, dimensions.Z)
	
	local tipLocalPos = Vector3.zero
	if length == dimensions.X then
		tipLocalPos = Vector3.new(math.abs(maxExtents.X) > math.abs(minExtents.X) and maxExtents.X or minExtents.X, 0, 0)
	elseif length == dimensions.Y then
		tipLocalPos = Vector3.new(0, math.abs(maxExtents.Y) > math.abs(minExtents.Y) and maxExtents.Y or minExtents.Y, 0)
	else
		tipLocalPos = Vector3.new(0, 0, math.abs(maxExtents.Z) > math.abs(minExtents.Z) and maxExtents.Z or minExtents.Z)
	end

	local tipWorld = handleCF:PointToWorldSpace(tipLocalPos)
	local effectiveReach = (tipWorld - handle.Position).Magnitude
	local gripOffset = root and (handle.Position - root.Position).Magnitude or 1.5
	local swingRadius = effectiveReach + gripOffset

	return {
		size = dimensions,
		thickness = thickness,
		length = length,
		com = com,
		tip = tipWorld,
		effectiveReach = effectiveReach,
		swingRadius = swingRadius,
		max = length + gripOffset,
		handlePos = handle.Position
	}
end

local function equipToolDelayed()
	if tick() - lastAutoEquip < 0.8 then return end
	lastAutoEquip = tick()
	task.delay(0.2, function()
        if not alive() then return end
		getCharacter()
		if not currentHumanoid or currentHumanoid.Health <= 0 then return end
		local tool = getPreferredTool()
		if tool and tool.Parent ~= currentCharacter then
			pcall(function() currentHumanoid:EquipTool(tool) end)
		end
	end)
end

local function scanTargetParts(targetChar)
	local root = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if not root then return {} end

	local probe = Instance.new("Part")
	probe.Name = "TargetProbe"
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanTouch = false
	probe.CanQuery = true
	probe.Transparency = 1
	probe.Size = Vector3.new(7, 8, 7)
	probe.CFrame = root.CFrame
	probe.Parent = Workspace

	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { currentCharacter, probe }
	overlap.RespectCanCollide = false

	local hits = {}
	local ok, parts = pcall(function() return Workspace:GetPartsInPart(probe, overlap) end)
	if ok and parts then
		for _, part in ipairs(parts) do
			local model = part:FindFirstAncestorOfClass("Model")
			if model == targetChar or part:IsDescendantOf(targetChar) then
				hits[#hits + 1] = part
			end
		end
	end
	probe:Destroy()
	return hits
end

local function targetStats(targetHum, targetRoot, dt)
	local state = targetState[targetHum]
	local pos = targetRoot.Position
	local vel = targetRoot.AssemblyLinearVelocity
	local aVel = targetRoot.AssemblyAngularVelocity
	local now = tick()

	if not state then
		state = {
			pos = pos, vel = vel, acc = Vector3.zero, jerk = Vector3.zero, aVel = aVel,
			lastPos = pos, lastVel = vel, lastUpdate = now, lastStopT = now,
			lastDir = Vector3.zero, rhythm = 0, mirrorBias = 0,
		}
		targetState[targetHum] = state
	end

	local a = dt > 0 and ((vel - state.lastVel) / math.max(dt, 1 / 240)) or Vector3.zero
	local j = dt > 0 and ((a - state.acc) / math.max(dt, 1 / 240)) or Vector3.zero

	state.pos = state.pos:Lerp(pos, 0.45)
	state.vel = state.vel:Lerp(vel, 0.45)
	state.acc = state.acc:Lerp(a, 0.35)
	state.jerk = state.jerk:Lerp(j, 0.25)
	state.aVel = state.aVel:Lerp(aVel, 0.45)

	local flatVel = Vector3.new(vel.X, 0, vel.Z)
	local speed = flatVel.Magnitude
	
	local speedLow = f_down(speed, 0.1, currentHumanoid and currentHumanoid.WalkSpeed * 0.3 or 5)
	if speedLow > 0.5 then
		if now - state.lastStopT > 0.15 then
			state.rhythm = math.clamp(state.rhythm + 0.08, 0, 1)
			state.lastStopT = now
		end
	else
		state.rhythm = math.clamp(state.rhythm - 0.02, 0, 1)
	end

	local moveDir = speed > 0.1 and flatVel.Unit or Vector3.zero
	if moveDir.Magnitude > 0 then
		local lateral = (state.lastDir.Magnitude > 0 and moveDir:Dot(state.lastDir) or 1)
		local mirrorFactor = f_down(lateral, 0, 0.6)
		if mirrorFactor > 0.3 then
			state.mirrorBias = math.clamp(state.mirrorBias + (mirrorFactor * 0.1), -1, 1)
		else
			state.mirrorBias = state.mirrorBias * 0.92
		end
	end

	state.lastDir = moveDir
	state.lastVel = vel
	state.lastPos = pos
	state.lastUpdate = now

	local momentumFuzzy = f_up(speed, currentHumanoid and currentHumanoid.WalkSpeed * 0.5 or 8, currentHumanoid and currentHumanoid.WalkSpeed * 2.5 or 40)
	local rhythmFuzzy = f_up(state.rhythm, 0, 1)
	local ping = 0.15 + (momentumFuzzy * 0.1) + (rhythmFuzzy * 0.1)
	local predicted = state.pos + state.vel * ping + state.acc * (ping * ping * 0.5) + state.jerk * (ping * ping * ping / 6)

	return state, predicted, speed, ping
end

local function chooseTarget()
	local bestPlr, bestChar, bestHum, bestRoot
	local bestScore = math.huge

	for _, plr in ipairs(Players:GetPlayers()) do
		if eligiblePlayer(plr) then
			local char, hum, root = getCharHumRoot(plr)
			if char and hum and root then
				local dist = (root.Position - currentRoot.Position).Magnitude
				local healthFactor = hum.Health > 0 and (hum.Health / math.max(hum.MaxHealth, 1)) or 0
				local score = dist * (1 + (1 - healthFactor) * 0.18)

				if score < bestScore then
					bestScore = score
					bestPlr, bestChar, bestHum, bestRoot = plr, char, hum, root
				end
			end
		end
	end
	return bestPlr, bestChar, bestHum, bestRoot
end

local function predictedLookAt(targetChar, targetHum, targetRoot, dt, myMetrics)
	local state, predictedRoot, speed, ping = targetStats(targetHum, targetRoot, dt)
	local angularOffset = state.aVel * ping
	local rotationDelta = CFrame.Angles(angularOffset.X, angularOffset.Y, angularOffset.Z)

	local handlePos = myMetrics.handlePos
	local bestAttackPoint = predictedRoot
	local bestScore = math.huge

	for _, part in ipairs(targetChar:GetChildren()) do
		if part:IsA("BasePart") then
			local rootToPart = part.Position - targetRoot.Position
			local rotatedRootToPart = rotationDelta * rootToPart
			local predictedPartPos = predictedRoot + rotatedRootToPart
			
			local toTarget = predictedPartPos - handlePos
			local distToHandle = toTarget.Magnitude
			
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {currentCharacter, targetChar}
			rayParams.IgnoreWater = true

			local ray = Workspace:Raycast(handlePos, toTarget.Unit * distToHandle, rayParams)
			local obstructionScore = ray and 1 or 0
			local score = distToHandle + (obstructionScore * 40)
			
			if score < bestScore then
				bestScore = score
				bestAttackPoint = predictedPartPos
			end
		end
	end

	local myPos = currentRoot.Position
	local flatTargetPos = Vector3.new(bestAttackPoint.X, myPos.Y, bestAttackPoint.Z)
	local desiredVector = flatTargetPos - myPos
	if desiredVector.Magnitude > 0.001 then desiredVector = desiredVector.Unit else desiredVector = currentRoot.CFrame.LookVector end

	local currentLook = currentRoot.CFrame.LookVector
	local currentFlatLook = Vector3.new(currentLook.X, 0, currentLook.Z)
	if currentFlatLook.Magnitude > 0.001 then currentFlatLook = currentFlatLook.Unit else currentFlatLook = desiredVector end

	local turnSpeed = 12 + (speed * 0.25)
	local t = math.clamp(dt * turnSpeed, 0, 1)
	local dotProduct = math.clamp(currentFlatLook:Dot(desiredVector), -1, 1)
	local theta = math.acos(dotProduct)
	
	local slerpedVector
	if theta > 0.001 then
		local sinTheta = math.sin(theta)
		local weight1 = math.sin((1 - t) * theta) / sinTheta
		local weight2 = math.sin(t * theta) / sinTheta
		slerpedVector = (currentFlatLook * weight1) + (desiredVector * weight2)
	else
		slerpedVector = desiredVector
	end

	slerpedVector = slerpedVector.Unit
	local upVector = Vector3.yAxis
	local rightVector = slerpedVector:Cross(upVector).Unit
	local backVector = -slerpedVector
	
	return CFrame.fromMatrix(myPos, rightVector, upVector, backVector), state, predictedRoot, speed, bestAttackPoint
end

local evade={Enabled=true,Strength=0.85,MinSwitch=0.35,MaxSwitch=0.8,NextSwitch=0,Sign=1}
local nav={target=nil,points=nil,index=2,busy=false,last=-math.huge,epoch=0,owned=false}
local controls
pcall(function()
    local scripts=LocalPlayer:FindFirstChild("PlayerScripts")
    local module=scripts and scripts:FindFirstChild("PlayerModule")
    if module then controls=require(module):GetControls() end
end)
local function releaseMovement()
    if nav.owned and currentHumanoid then currentHumanoid:Move(Vector3.zero,false) end
    nav.owned=false
end
local function sightClear(targetChar,targetRoot)
    if not currentRoot or not targetRoot then return false end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={currentCharacter}
    local head=currentCharacter:FindFirstChild("Head")
    local origin=head and head.Position or currentRoot.Position
    local delta=targetRoot.Position-origin
    local hit=Workspace:Raycast(origin,delta,params)
    return not hit or hit.Instance:IsDescendantOf(targetChar)
end
local function movementClear(direction,targetChar)
    if direction.Magnitude<0.01 then return true end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={currentCharacter,targetChar}
    params.RespectCanCollide=true
    local length=math.max(3,currentHumanoid.WalkSpeed*0.18)
    return Workspace:Blockcast(CFrame.new(currentRoot.Position),Vector3.new(2,3,2),direction.Unit*length,params)==nil
end
local function groundAhead(direction,targetChar)
    if direction.Magnitude<0.01 then return true end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={currentCharacter,targetChar}
    params.RespectCanCollide=true
    local step=math.max(3,currentHumanoid.WalkSpeed*0.2)
    for _,fraction in ipairs({0.5,1}) do
        local origin=currentRoot.Position+direction.Unit*step*fraction+Vector3.new(0,2,0)
        local hit=Workspace:Raycast(origin,Vector3.new(0,-9,0),params)
        if not hit or hit.Normal.Y<0.5 then return false end
    end
    return true
end
local function evadeDirection(base,forward,right,dist,spacing,targetChar,targetRoot)
    if not evade.Enabled or dist>math.max(18,spacing*2.5) then return base end
    local now=os.clock()
    if now>=evade.NextSwitch then
        evade.Sign=-evade.Sign
        evade.NextSwitch=now+evade.MinSwitch+math.random()*(evade.MaxSwitch-evade.MinSwitch)
    end
    local facing=targetRoot.CFrame.LookVector:Dot(-forward)
    local retreat=dist<spacing*0.8 and 0.9 or (facing>0.65 and 0.35 or 0.05)
    local candidates={
        base*(1-evade.Strength)+right*evade.Sign*evade.Strength-forward*retreat,
        -right*evade.Sign-forward*retreat,
        -forward,
    }
    for i,direction in ipairs(candidates) do
        if direction.Magnitude>0.01 then
            direction=direction.Unit
            if movementClear(direction,targetChar) and groundAhead(direction,targetChar) then
                if i==2 then evade.Sign=-evade.Sign;evade.NextSwitch=now+0.35 end
                return direction
            end
        end
    end
    return Vector3.zero
end
local function requestPath(targetRoot)
    if nav.target~=targetRoot then
        nav.target=targetRoot;nav.points=nil;nav.epoch=nav.epoch+1
    end
    if nav.busy or os.clock()-nav.last<0.8 then return end
    nav.busy=true;nav.last=os.clock()
    local epoch,root,start=nav.epoch,currentRoot,currentRoot.Position
    local destination=targetRoot.Position
    task.spawn(function()
        local ok,path=pcall(function()
            local p=game:GetService("PathfindingService"):CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=3})
            p:ComputeAsync(start,destination)
            return p
        end)
        nav.busy=false
        if not active or not enabled or epoch~=nav.epoch or root~=currentRoot then return end
        if ok and path.Status==Enum.PathStatus.Success then nav.points=path:GetWaypoints();nav.index=2
        else nav.points=nil end
    end)
end
local function steer(direction,targetChar,targetRoot)
    local routeBlocked=not sightClear(targetChar,targetRoot) or not movementClear(direction,targetChar)
    if routeBlocked then
        requestPath(targetRoot)
        local points=nav.points
        local waypoint=points and points[nav.index]
        while waypoint and (Vector3.new(waypoint.Position.X,currentRoot.Position.Y,waypoint.Position.Z)-currentRoot.Position).Magnitude<2 do
            nav.index=nav.index+1;waypoint=points[nav.index]
        end
        if not waypoint then releaseMovement();return end
        local delta=waypoint.Position-currentRoot.Position
        direction=Vector3.new(delta.X,0,delta.Z)
        if direction.Magnitude<0.01 then releaseMovement();return end
        direction=direction.Unit
        if waypoint.Action==Enum.PathWaypointAction.Jump then currentHumanoid.Jump=true end
        if not movementClear(direction,targetChar) then releaseMovement();return end
    else
        nav.points=nil
    end
    if not groundAhead(direction,targetChar) then releaseMovement();return end
    nav.owned=true
    currentHumanoid:Move(direction,false)
end

local function controlMovement(targetChar, targetHum, targetRoot, state, predicted, speed, myMetrics, targetMetrics)
	local myPos = currentRoot.Position
	local toTarget = predicted - myPos
	local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
	local dist = flat.Magnitude
	
	if dist < 0.001 then
		currentHumanoid:Move(Vector3.zero, false)
		return dist
	end

	local healthRatio = currentHumanoid.Health / math.max(1, currentHumanoid.MaxHealth)
	local enemyHealthRatio = targetHum.Health / math.max(1, targetHum.MaxHealth)
	local aggroFuzzy = f_up(healthRatio - enemyHealthRatio + 0.2, 0, 1)

	local baseSpacing = myMetrics.effectiveReach
	local safeSpacing = math.max(myMetrics.effectiveReach, targetMetrics.swingRadius + targetMetrics.length * 0.5)
	local desiredSpacing = (baseSpacing * aggroFuzzy) + (safeSpacing * (1 - aggroFuzzy))

	local forward = flat.Unit
	local right = Vector3.new(-forward.Z, 0, forward.X)
	
	local distClose = f_down(dist, desiredSpacing * 0.6, desiredSpacing)
	local distMed = f_tri(dist, desiredSpacing * 0.7, desiredSpacing, desiredSpacing * 1.4)
	local distFar = f_up(dist, desiredSpacing * 1.1, desiredSpacing * 2.5)
	
	local fwdWeight = (distFar * 1.0) + (distMed * (aggroFuzzy * 0.6 - 0.2)) + (distClose * -0.85)
	local strafeWeight = (distFar * 0.1) + (distMed * 0.95) + (distClose * 0.8)
	
	local mirrorForce = f_up(math.abs(state.mirrorBias), 0.3, 1)
	if mirrorForce > 0.5 then
		sideSign = state.mirrorBias > 0 and -1 or 1
	else
		if (tick() % 1.5) < 0.05 then
			sideSign = math.random() > 0.5 and 1 or -1
		end
	end

	local desiredDir = (forward * fwdWeight) + (right * sideSign * strafeWeight)
	if desiredDir.Magnitude > 0.01 then
		desiredDir = desiredDir.Unit
	end

    desiredDir=evadeDirection(desiredDir,forward,right,dist,desiredSpacing,targetChar,targetRoot)
	if currentHumanoid then
		steer(desiredDir,targetChar,targetRoot)
	end
	
	local jumpUrgency = (distClose * 0.8) + (f_up(state.rhythm, 0.4, 1) * 0.4)
	if jumpUrgency > 0.75 and currentHumanoid and currentHumanoid.FloorMaterial ~= Enum.Material.Air then
		if tick() - lastJump > 0.8 then
			lastJump = tick()
			currentHumanoid.Jump = true
		end
	end

	return dist
end

local function attackTarget(targetChar, targetHum, targetRoot, dist, myMetrics, targetMetrics)
    if not eligiblePlayer(Players:GetPlayerFromCharacter(targetChar)) or not sightClear(targetChar,targetRoot) then return end
	local tool = getPreferredTool()
	if not tool then return end
	if tool.Parent ~= currentCharacter then
		equipToolDelayed()
		return
	end

	if tick() - lastAttack < 0.18 then return end
	local attackDesire = f_down(dist, myMetrics.effectiveReach * 0.8, myMetrics.swingRadius * 1.2)

	local scanHits = scanTargetParts(targetChar)
	if #scanHits > 0 then attackDesire = 1 end

	local toolDist = (targetMetrics.com - currentRoot.Position).Magnitude
	local toolThreat = f_down(toolDist, targetMetrics.effectiveReach * 0.5, targetMetrics.swingRadius * 1.1)
	attackDesire = math.max(attackDesire, toolThreat * 0.8)

	if attackDesire > 0.6 then
		lastAttack = tick()
		pcall(function() tool:Activate() end)
		task.delay(0.05, function()
            if not alive() or not eligiblePlayer(Players:GetPlayerFromCharacter(targetChar)) or not sightClear(targetChar,targetRoot) then return end
			local currentTool = getPreferredTool()
			if currentTool and currentTool.Parent == currentCharacter then
				pcall(function() currentTool:Activate() end)
			end
		end)
	end
end

local recovery={Enabled=true,MissingAt=nil,ResumeAt=0,RetryAt=0,Attempts=0,Character=nil,Tool=nil}
local function resetRecovery()
    recovery.MissingAt=nil;recovery.ResumeAt=0;recovery.RetryAt=0
    recovery.Attempts=0;recovery.Character=currentCharacter;recovery.Tool=nil
end
local function equipmentReady()
    if recovery.Character~=currentCharacter then resetRecovery() end
    local equipped=getEquippedTool(currentCharacter)
    if equipped then
        -- Tool.Enabled=false can be a normal cooldown, not an equip failure.
        if recovery.MissingAt then resetRecovery() end
        if button.Text~="AI: ON" then setButtonState() end
        return true
    end
    releaseMovement()
    local candidate=getPreferredTool()
    if not candidate then button.Text="AI: ON · 무기 대기";return false end
    if not recovery.Enabled then button.Text="AI: ON · 직접 무기를 장착하세요";return false end
    local now=os.clock()
    if recovery.Tool~=candidate then resetRecovery();recovery.Tool=candidate end
    if not recovery.MissingAt then recovery.MissingAt=now end
    if now<recovery.ResumeAt then button.Text="AI: 복구 대기";return false end
    if now<recovery.RetryAt then button.Text="AI: 장착 확인 중";return false end
    if now-recovery.MissingAt<1.2 then
        equipToolDelayed();button.Text="AI: 무기 장착 중";return false
    end
    if recovery.Attempts>=3 then
        recovery.Attempts=0;recovery.ResumeAt=now+5;recovery.MissingAt=now+5
        button.Text="AI: 장착 제한 · 5초 뒤 재시도";return false
    end
    recovery.Attempts=recovery.Attempts+1
    recovery.ResumeAt=now+0.6;recovery.RetryAt=now+1.8
    nav.epoch=nav.epoch+1;nav.points=nil
    pcall(function() candidate:Deactivate() end)
    pcall(function() currentHumanoid:UnequipTools() end)
    local character,humanoid=currentCharacter,currentHumanoid
    task.delay(0.6,function()
        if not active or not enabled or not recovery.Enabled or currentCharacter~=character
            or not humanoid.Parent or humanoid.Health<=0 or humanoid.Sit or currentRoot.Anchored then return end
        if candidate.Parent==LocalPlayer:FindFirstChildOfClass("Backpack") then
            pcall(function() humanoid:EquipTool(candidate) end)
        end
    end)
    button.Text="AI: 장착 복구 중"
    return false
end

local function updateAI(dt)
	if not enabled then return end
	if not currentCharacter or not currentCharacter.Parent or not currentHumanoid or currentHumanoid.Health <= 0 or not currentRoot then
		getCharacter()
		return
	end

    if controls then
        local ok,move=pcall(function() return controls:GetMoveVector() end)
        if ok and move.Magnitude>0.15 then releaseMovement();return end
    end
    if currentHumanoid.Sit or currentRoot.Anchored then releaseMovement();return end
    if not equipmentReady() then return end
	local _, targetChar, targetHum, targetRoot = chooseTarget()
    if not targetChar then
        nav.epoch=nav.epoch+1;nav.points=nil;releaseMovement();return
    end

	local myTool = getPreferredTool()
	local targetTool = getEquippedTool(targetChar)
	
	local myMetrics = getAdvancedToolMetrics(myTool, currentCharacter)
	local targetMetrics = getAdvancedToolMetrics(targetTool, targetChar)

	local lookMatrix, state, predicted, speed, _ = predictedLookAt(targetChar, targetHum, targetRoot, dt, myMetrics)
	
	if currentRoot and currentHumanoid then
		currentRoot.CFrame = lookMatrix
	end

	local dist = controlMovement(targetChar, targetHum, targetRoot, state, predicted, speed, myMetrics, targetMetrics)
	attackTarget(targetChar, targetHum, targetRoot, dist, myMetrics, targetMetrics)
end

local function setEnabled(value)
    if not active then return end
    enabled=value==true
    resetRecovery()
    if not enabled then nav.epoch=nav.epoch+1;nav.points=nil;releaseMovement() end
    setButtonState()
    if enabled then getCharacter();equipToolDelayed()
    else
        if currentHumanoid then pcall(function() currentHumanoid:Move(Vector3.zero,false) end) end
        local tool=getEquippedTool(currentCharacter)
        if tool then pcall(function() tool:Deactivate() end) end
    end
end
track(button.Activated,function()
    setEnabled(not enabled)
    if onChanged then onChanged(enabled) end
end)

track(button.InputBegan,function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = button.Position
		activeTouch = input
	end
end)

track(button.InputChanged,function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

track(UserInputService.InputChanged,function(input)
	if not dragging then return end
	if input ~= dragInput and input ~= activeTouch then return end
	local delta = input.Position - dragStart
	button.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end)

track(UserInputService.InputEnded,function(input)
	if input == activeTouch or input == dragInput then
		dragging = false
	end
end)

track(LocalPlayer.CharacterAdded,function()
	task.wait(0.15)
    if not active then return end
	getCharacter()
	equipToolDelayed()
end)

track(LocalPlayer.CharacterRemoving,function()
	currentCharacter = nil
	currentHumanoid = nil
	currentRoot = nil
end)

getCharacter()
setButtonState()

track(RunService.RenderStepped,function(dt)
	if active and enabled then
        local ok,err=pcall(updateAI,dt)
        if not ok then setEnabled(false);if onChanged then onChanged(false) end;warn("KoreanHub Sword AI: "..tostring(err)) end
    end
end)

track(LocalPlayer.Backpack.ChildAdded,function(child)
	if child:IsA("Tool") and enabled then task.defer(equipToolDelayed) end
end)

track(LocalPlayer.CharacterAdded,function(char)
	track(char.ChildAdded,function(child)
		if child:IsA("Tool") and enabled then task.defer(equipToolDelayed) end
	end)
end)
        return {
            SetRecovery=function(v) recovery.Enabled=v;resetRecovery() end,
            SetEvasion=function(v) evade.Enabled=v end,
            SetEvasionStrength=function(v) evade.Strength=v end,
            SetTeamCheck=function(v) teamCheck=v end,
            SetStrictTeam=function(v) strictTeam=v end,
            SetEnabled=setEnabled,
            SetVisible=function(value) gui.Enabled=value==true end,
            Cleanup=function()
                setEnabled(false);active=false
                for _,connection in ipairs(connections) do connection:Disconnect() end
                gui:Destroy()
            end,
        }
    end
    local aiController,aiToggle
    local syncing=false
    local ok,result=pcall(mount,function(value)
        if aiToggle and not syncing then
            syncing=true;pcall(function() aiToggle:Set(value) end);syncing=false
        end
    end)
    if ok then aiController=result else notify("Sword AI 초기화 실패",tostring(result)) end
    CombatTab:CreateSection("Aether V2 · Sword Fighting AI")
    CombatTab:CreateParagraph({Title="첨부한 검 전투 AI",Content="자동 이동·회전·점프·툴 장착·공격을 수행합니다. 일반 Tool 전용이며 Model 검은 지원하지 않습니다. Fly·Player Lock·다른 자동 공격과 함께 켜면 조작이 충돌할 수 있습니다."})
    CombatTab:CreateToggle({Name="Sword AI 아군 제외",Flag="Combat_AetherTeamCheck",CurrentValue=true,Callback=function(v)
        if aiController then aiController.SetTeamCheck(v) end
    end})
    CombatTab:CreateToggle({Name="Sword AI 팀 불명확 시 공격 보류",Flag="Combat_AetherStrictTeam",CurrentValue=true,Callback=function(v)
        if aiController then aiController.SetStrictTeam(v) end
    end})
    CombatTab:CreateParagraph({Title="벽 회피·수동 이동",Content="벽이 막으면 경로 탐색을 시도하고, 공격 직전 시야를 확인합니다. 경로가 없거나 대상이 없으면 이동 제어를 놓습니다. 기본 Roblox 조이스틱 입력을 감지하면 수동 조작을 우선합니다. 커스텀 이동 시스템은 별도 확인이 필요합니다."})
    CombatTab:CreateParagraph({Title="팀 판정",Content="Player.Team과 플레이어·캐릭터의 명시적 팀 속성/값을 확인합니다. 순위표 표시 여부와 무관합니다. 팀 정보를 찾지 못하면 기본적으로 AI 이동·공격을 보류합니다. 옷이나 바닥 색으로 팀을 추측하지 않습니다."})
    CombatTab:CreateToggle({Name="Sword AI 회피 이동",Flag="Combat_SwordEvasion",CurrentValue=true,Callback=function(v)
        if aiController then aiController.SetEvasion(v) end
    end})
    CombatTab:CreateSlider({Name="Sword AI 회피 강도",Flag="Combat_SwordEvasionStrength",Range={0.3,1},Increment=0.05,CurrentValue=0.85,Callback=function(v)
        if aiController then aiController.SetEvasionStrength(v) end
    end})
    CombatTab:CreateParagraph({Title="회피 이동",Content="근거리에서 좌우 전환과 후퇴를 섞습니다. 이동할 방향의 장애물과 앞쪽 바닥을 확인합니다. 스킬 감지 기능은 포함되지 않으며, 모든 공격을 피하는 것을 보장하지 않습니다."})
    CombatTab:CreateToggle({Name="Sword AI 장착 실패 자동 복구",Flag="Combat_SwordEquipRecovery",CurrentValue=true,Callback=function(v)
        if aiController then aiController.SetRecovery(v) end
    end})
    CombatTab:CreateParagraph({Title="자동 일시 중지·재장착",Content="AI 실행 중 무기가 가방에만 남으면 이동을 놓고 잠시 대기한 뒤 재장착합니다. 연속 실패 시 5초 쉬고 다시 시도합니다. AI를 직접 끄면 재시도도 중지됩니다. 서버의 스턴·수감·장착 제한을 해제하는 기능은 아닙니다."})
    aiToggle=CombatTab:CreateToggle({Name="Sword Fighting AI 실행",Flag="Combat_AetherSwordAI",CurrentValue=false,Callback=function(value)
        if aiController and not syncing then aiController.SetEnabled(value) end
    end})
    CombatTab:CreateToggle({Name="Sword AI 화면 버튼 표시",Flag="Combat_AetherSwordUI",CurrentValue=true,Callback=function(value)
        if aiController then aiController.SetVisible(value) end
    end})
    CombatTab:CreateButton({Name="Sword AI 즉시 중지",Callback=function()
        if aiController then aiController.SetEnabled(false) end
        if aiToggle then aiToggle:Set(false) end
    end})
    _G.KoreanHubSwordAICleanup=function() if aiController then aiController.Cleanup() end end
end

-- Scoped adaptation of the supplied wait-hook script. Global clocks are untouched.
do
    local env=type(getgenv)=='function' and getgenv() or _G
    local state=env.KoreanHubScopedWaitState
    if not state then state={Enabled=false,Installed=false,InstallError=nil};env.KoreanHubScopedWaitState=state end
    state.Enabled=false
    local function weaponCaller()
        if not state.Enabled or type(getcallingscript)~="function" then return false end
        local ok,scriptObject=pcall(getcallingscript)
        if not ok or typeof(scriptObject)~="Instance" then return false end
        local char=LocalPlayer.Character
        if not char or not scriptObject:IsDescendantOf(char) then return false end
        local node=scriptObject.Parent
        while node and node~=char do
            if node:IsA("Tool") then return true end
            if node:IsA("Model") and node:FindFirstChild("ToolSlot") and node:FindFirstChild("Activate") then return true end
            node=node.Parent
        end
        return false
    end
    -- Refresh the predicate on rerun without stacking hooks.
    state.ShouldShorten=weaponCaller
    local function install()
        if state.Installed then return true end
        if type(hookfunction)~="function" or type(getcallingscript)~="function" then return false,"hookfunction / getcallingscript 미지원" end
        if state.InstallError then return false,state.InstallError end
        local originalWait,originalTaskWait
        local function shortened(seconds)
            if type(seconds)~="number" or seconds<=0 then return false end
            local ok,result=pcall(state.ShouldShorten)
            return ok and result
        end
        local ok,err=pcall(function()
            originalWait=hookfunction(wait,function(seconds,...)
                if shortened(seconds) then return originalWait(0,...) end
                return originalWait(seconds,...)
            end)
            originalTaskWait=hookfunction(task.wait,function(seconds,...)
                if shortened(seconds) then return originalTaskWait(0,...) end
                return originalTaskWait(seconds,...)
            end)
        end)
        if not ok then state.Enabled=false;state.InstallError=tostring(err);return false,tostring(err) end
        state.Installed=true;return true
    end
    CombatTab:CreateSection("무기 로컬 대기 단축 · 시험")
    CombatTab:CreateParagraph({Title="첨부 No Cooldown의 제한 적용본",Content="장착한 무기 내부 스크립트가 호출한 wait/task.wait만 단축을 시도합니다. 전역 tick/os.clock은 바꾸지 않습니다. 서버 쿨타임·시간차 비교 방식에는 적용되지 않을 수 있으며, 무기 애니메이션·재장전에 영향을 줄 수 있습니다."})
    local toggle,changing
    toggle=CombatTab:CreateToggle({Name="무기 로컬 대기 단축",Flag="Combat_ScopedNoCooldown",CurrentValue=false,Callback=function(v)
        if changing then return end
        if not v then state.Enabled=false;return end
        local ok,err=install()
        if ok then state.Enabled=true;notify("로컬 대기 단축","장착 무기 내부 스크립트에만 단축을 시도합니다. 실제 쿨타임 해제는 미확인입니다.")
        else
            state.Enabled=false;notify("지원 확인 필요",tostring(err))
            if toggle then changing=true;toggle:Set(false);changing=false end
        end
    end})
    CombatTab:CreateButton({Name="로컬 대기 단축 중지",Callback=function()
        state.Enabled=false;if toggle then toggle:Set(false) end
    end})
end

Rayfield:LoadConfiguration()
