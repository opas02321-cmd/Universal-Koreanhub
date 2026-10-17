-- Korean Hub (Fly Fixed & All Features Included)
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    return
end

local Window = Rayfield:CreateWindow({
    Name = "KoreanHub · Aim Fix",
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
    Name = "FOV Circle",
    CurrentValue = false,
    Callback = function(state)
        _G.FOVCircle = state
        fovDrawing.Visible = state
    end,
})

CombatTab:CreateSlider({
    Name = "FOV Size",
    Range = {20, 500},
    Increment = 5,
    CurrentValue = 100,
    Callback = function(v)
        _G.FOVSize = v
        fovDrawing.Radius = v
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
    Name = "God Mode (Health Lock)",
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

do
    if type(_G.KoreanHubCombatCoreCleanup) == "function" then _G.KoreanHubCombatCoreCleanup() end
    if _G.KoreanHubAutoClickConnection then _G.KoreanHubAutoClickConnection:Disconnect() end
    local settings = {
        Reach = false, ReachDistance = 8, ToolHitbox = false, ToolScale = 2,
        AllBodyParts = false, TeamCheck = true,
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
        if activeTool then pcall(function() activeTool:Deactivate() end) end
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
                CanCollide = part.CanCollide, Massless = part.Massless, ToolPart = toolPart == true}
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
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid or humanoid.Health <= 0 or not tool
            or tool.Parent ~= character or not tool.Enabled then return false end
        local handle = tool:FindFirstChild("Handle")
        return not tool.RequiresHandle or (handle and handle:IsA("BasePart"))
    end
    local function activate(tool, interval, hold, owner)
        local now = os.clock()
        if not equippedReady(tool) or now - lastAttack < interval then return false end
        if activeTool and now < releaseAt then return false end
        release()
        local ok = pcall(function() tool:Activate() end)
        if not ok then return false end
        activeTool, activeOwner = tool, owner or "auto"
        lastAttack, releaseAt = now, now + hold
        return true
    end
    _G.KoreanHubCombatTryActivate = activate
    _G.KoreanHubCombatRelease = release
    CombatTab:CreateSlider({Name = "Auto Attack Nearby Range", Flag = "Combat_AutoClickPlayerRange", Range = {3, 50}, Increment = 1,
        CurrentValue = 12, Callback = function(v) settings.Radius = v end})
    CombatTab:CreateSlider({Name = "Auto Attack Interval", Flag = "Combat_NearAttackIntervalV3", Range = {0.05, 2}, Increment = 0.05,
        CurrentValue = 0.3, Callback = function(v) settings.Interval = v end})
    CombatTab:CreateSlider({Name = "Auto Attack Press Duration", Flag = "Combat_AttackPressV3", Range = {0.05, 1}, Increment = 0.05,
        CurrentValue = 0.15, Callback = function(v) settings.Hold = v end})
    CombatTab:CreateToggle({Name = "Combat Team Check", Flag = "Combat_NearTeamV2", CurrentValue = true,
        Callback = function(v) settings.TeamCheck = v end})
    CombatTab:CreateSection("Reach & Tool Hitbox")
    CombatTab:CreateToggle({Name = "Tool Reach (Existing Hit Parts)", Flag = "Combat_ToolReachV3", CurrentValue = false,
        Callback = function(v) settings.Reach = v end})
    CombatTab:CreateSlider({Name = "Tool Reach Size (studs)", Flag = "Combat_ToolReachSizeV2", Range = {2, 40}, Increment = 1,
        CurrentValue = 8, Callback = function(v) settings.ReachDistance = v end})
    CombatTab:CreateToggle({Name = "Tool Hitbox Expander", Flag = "Combat_ToolHitboxV3", CurrentValue = false,
        Callback = function(v) settings.ToolHitbox = v end})
    CombatTab:CreateSlider({Name = "Tool Hitbox Multiplier", Flag = "Combat_ToolHitboxScaleV2", Range = {1, 10}, Increment = 0.5,
        CurrentValue = 2, Callback = function(v) settings.ToolScale = v end})
    CombatTab:CreateDropdown({Name = "Player Hitbox Parts", Flag = "Combat_PlayerPartsV3",
        Options = {"Body Parts + Root", "Root Only"}, CurrentOption = {"Root Only"},
        Callback = function(v) settings.AllBodyParts = (type(v) == "table" and v[1] or v) == "Body Parts + Root" end})
    CombatTab:CreateParagraph({Title = "전용 판정 부품만 조절", Content = "일반 Handle·날·장식·Grip·질량·충돌 설정은 변경하지 않습니다. 전용 판정 파트가 없으면 Reach/툴 히트박스는 적용하지 않습니다. 서버/레이캐스트 판정은 게임별 분석이 필요합니다."})
    -- Snapshot diagnostics: property reads only; no activation or remote calls.
    local function toolDiagnostic()
        local lines={"KoreanHub tool diagnostic 1", "PlaceId="..tostring(game.PlaceId),
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
        local tool=char and char:FindFirstChildOfClass("Tool")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then props(hum,{"Health","MaxHealth","Sit","PlatformStand"}) end
        if not tool then add("장착한 Tool이 없습니다. Bat를 손에 든 뒤 다시 진단하세요.");return table.concat(lines,"\n") end
        add("TOOL "..path(tool))
        props(tool,{"Enabled","RequiresHandle","ManualActivationOnly","Grip"})
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
    CombatTab:CreateButton({Name="장착한 툴 진단 · 보고서 보기",Callback=function()
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
        for _,flag in ipairs({"Combat_AutoClicker","Combat_HitboxExpander","Combat_ToolReachV3","Combat_ToolHitboxV3","Combat_NPCKillAura","Combat_PlayerKillAura"}) do
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
        local tool = character and character:FindFirstChildOfClass("Tool")
        local touched, nearby, hitCount = {}, false, 0
        if alive then
            for _,other in ipairs(Players:GetPlayers()) do
                local model = other.Character
                if other ~= LocalPlayer and model and not sameTeam(other) then
                    local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
                    local targetRoot = model:FindFirstChild("HumanoidRootPart")
                    if targetHumanoid and targetHumanoid.Health > 0 and targetRoot then
                        if (targetRoot.Position - root.Position).Magnitude <= settings.Radius then nearby = true end
                        if _G.HitboxExpander then
                            for _,part in ipairs(model:GetChildren()) do
                                if part:IsA("BasePart") and (settings.AllBodyParts or part == targetRoot) then
                                    local saved = remember(part)
                                    local size = _G.HitboxSize
                                    part.Size = Vector3.new(math.max(saved.Size.X, size), math.max(saved.Size.Y, size), math.max(saved.Size.Z, size))
                                    part.Transparency = math.max(saved.Transparency, 0.7)
                                    part.CanCollide = false
                                    part.Massless = true
                                    touched[part] = true
                                end
                            end
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
            activate(tool, settings.Interval, settings.Hold, "auto")
        end
        -- Enabled=false commonly means the weapon is in its own cooldown.
        -- Do not cancel the current press just because its Activated handler disables it.
        local note=(settings.Reach or settings.ToolHitbox) and hitCount==0
            and " · 전용 판정 파트 없음: 게임별 연결 필요" or ""
        report("현재 툴: "..(tool and tool.Name or "없음").." · 전용 판정 파트: "..hitCount..note)
    end
    local heartbeat = RunService.Heartbeat:Connect(update)
    connections[#connections + 1] = heartbeat
    _G.KoreanHubAutoClickConnection = heartbeat
    connections[#connections + 1] = LocalPlayer.CharacterAdded:Connect(function()
        release();restoreAll();lastAttack = -math.huge
    end)
    _G.KoreanHubCombatCoreCleanup = function()
        for _,connection in ipairs(connections) do connection:Disconnect() end
        release();restoreAll()
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
    local radius=tonumber(_G.FOVSize) or 100
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
    if _G.FOVCircle then
        local inset=game:GetService("GuiService"):GetGuiInset()
        fovDrawing.Position=aimCenter(camera)+inset
        fovDrawing.Radius=tonumber(_G.FOVSize) or 100
        fovDrawing.Visible=true
    else fovDrawing.Visible=false end
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not _G.AimbotEnabled or not hum or hum.Health<=0 or UserInputService:GetFocusedTextBox()
        or camera.CameraType==Enum.CameraType.Scriptable then
        aimLockedPlayer=nil;return
    end
    local target=getClosestTarget()
    local part=target and aimTargetPart(target,camera,(tonumber(_G.FOVSize) or 100)*1.25)
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
        if activeTool then pcall(function() activeTool:Deactivate() end) end
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
    CombatTab:CreateParagraph({Title = "Equipped-tool mode", Content = "Aura activates an equipped tool when a target is within the selected radius. A larger radius does not extend a weapon’s server-validated hit range."})
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
        local tool = character:FindFirstChildOfClass("Tool")
        if not tool or not tool.Enabled or (tool.RequiresHandle and not tool:FindFirstChild("Handle")) then return end
        if type(_G.KoreanHubCombatTryActivate) == "function" then
            if _G.KoreanHubCombatTryActivate(tool, settings.Interval, 0.15, "aura") then lastAttack = now end
            return
        end
        lastAttack = now
        releaseTool()
        local ok = pcall(function() tool:Activate() end)
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

Rayfield:LoadConfiguration()
