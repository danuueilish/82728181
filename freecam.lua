if _G.__IY_FREECAM_LOADED then
    return
end
_G.__IY_FREECAM_LOADED = true
local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local newCamera = workspace.CurrentCamera
    if newCamera then
        Camera = newCamera
    end
end)

local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local fcRunning = false
local cameraFov = 70
local Spring = {}
Spring.__index = Spring
function Spring.new(freq, pos)
    local self = setmetatable({}, Spring)
    self.f = freq
    self.p = pos
    self.v = pos * 0
    return self
end

function Spring:Update(dt, goal)
    local f = self.f * 2 * math.pi
    local p0 = self.p
    local v0 = self.v
    local offset = goal - p0
    local decay = math.exp(-f * dt)
    local p1 = goal + (v0 * dt - offset * (f * dt + 1)) * decay
    local v1 = (f * dt * (offset * f - v0) + v0) * decay
    self.p = p1
    self.v = v1
    return p1
end
function Spring:Reset(pos)
    self.p = pos
    self.v = pos * 0
end
local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local velSpring = Spring.new(5, Vector3.new())
local panSpring = Spring.new(5, Vector2.new())
local Input = {}
local keyboard = {
    W = 0,
    A = 0,
    S = 0,
    D = 0,
    E = 0,
    Q = 0,
    Up = 0,
    Down = 0,
    LeftShift = 0,
}
local mouse = {
    Delta = Vector2.new(),
}
local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
local PAN_MOUSE_SPEED    = Vector2.new(1, 1) * (math.pi / 64)
local NAV_ADJ_SPEED      = 0.75
local NAV_SHIFT_MUL      = 0.25
local navSpeed = 1
local mobileGui
local function makeMobileButton(name, label, keyName, pos)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.35
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = pos
    btn.Parent = mobileGui
    local function setDown()
        keyboard[keyName] = 1
    end
    local function setUp()
        keyboard[keyName] = 0
    end
    btn.MouseButton1Down:Connect(setDown)
    btn.MouseButton1Up:Connect(setUp)
    btn.MouseLeave:Connect(setUp)
end

local function createMobileControls()
    if not UserInputService.TouchEnabled then
        return
    end
    if mobileGui and mobileGui.Parent then
        mobileGui.Enabled = true
        return
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return
    end

    mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "IY_Freecam_Mobile"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent = pg
    makeMobileButton("Forward", "↑", "W", UDim2.new(0.08, 0, 0.72, 0))
    makeMobileButton("Back",    "↓", "S", UDim2.new(0.08, 0, 0.82, 0))
    makeMobileButton("Left",    "←", "A", UDim2.new(0.02, 0, 0.77, 0))
    makeMobileButton("Right",   "→", "D", UDim2.new(0.14, 0, 0.77, 0))
    makeMobileButton("Up",   "U", "E", UDim2.new(0.88, 0, 0.72, 0))
    makeMobileButton("Down", "D", "Q", UDim2.new(0.88, 0, 0.82, 0))
end

local function hideMobileControls()
    if mobileGui then
        mobileGui.Enabled = false
    end
end

function Input.Vel(dt)
    navSpeed = math.clamp(
        navSpeed + dt * (keyboard.Up - keyboard.Down) * NAV_ADJ_SPEED,
        0.01,
        4
    )
    local kKeyboard = Vector3.new(
        keyboard.D - keyboard.A,
        keyboard.E - keyboard.Q,
        keyboard.S - keyboard.W
    ) * NAV_KEYBOARD_SPEED
    local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    return kKeyboard * (navSpeed * (shift and NAV_SHIFT_MUL or 1))
end

function Input.Pan(dt)
    local kMouse = mouse.Delta * PAN_MOUSE_SPEED
    mouse.Delta  = Vector2.new()
    return kMouse
end

local function Keypress(_, state, input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return Enum.ContextActionResult.Pass
    end
    local name = input.KeyCode.Name
    if keyboard[name] ~= nil then
        keyboard[name] = (state == Enum.UserInputState.Begin) and 1 or 0
        return Enum.ContextActionResult.Sink
    end
    return Enum.ContextActionResult.Pass
end

local function MousePan(_, state, input)
    if state == Enum.UserInputState.Change then
        local delta = input.Delta
        mouse.Delta = Vector2.new(-delta.y, -delta.x)
    end
    return Enum.ContextActionResult.Sink
end

local function ZeroTable(t)
    for k, v in pairs(t) do
        t[k] = v * 0
    end
end

function Input.StartCapture()
    ContextActionService:BindActionAtPriority(
        "FreecamKeyboard",
        Keypress,
        false,
        INPUT_PRIORITY,
        Enum.KeyCode.W,
        Enum.KeyCode.A,
        Enum.KeyCode.S,
        Enum.KeyCode.D,
        Enum.KeyCode.E,
        Enum.KeyCode.Q,
        Enum.KeyCode.Up,
        Enum.KeyCode.Down
    )
    ContextActionService:BindActionAtPriority(
        "FreecamMousePan",
        MousePan,
        false,
        INPUT_PRIORITY,
        Enum.UserInputType.MouseMovement,
        Enum.UserInputType.Touch
    )
    createMobileControls()
end

function Input.StopCapture()
    navSpeed = 1
    ZeroTable(keyboard)
    ZeroTable(mouse)
    ContextActionService:UnbindAction("FreecamKeyboard")
    ContextActionService:UnbindAction("FreecamMousePan")
    hideMobileControls()
end

local function GetFocusDistance(cameraFrame)
    local znear   = 0.1
    local viewport = Camera.ViewportSize
    local projy   = 2 * math.tan(cameraFov / 2)
    local projx   = viewport.x / viewport.y * projy
    local fx      = cameraFrame.RightVector
    local fy      = cameraFrame.UpVector
    local fz      = cameraFrame.LookVector
    local minVect = Vector3.new()
    local minDist = 512
    for x = 0, 1, 0.5 do
        for y = 0, 1, 0.5 do
            local cx = (x - 0.5) * projx
            local cy = (y - 0.5) * projy
            local offset = fx * cx - fy * cy + fz
            local origin = cameraFrame.Position + offset * znear
            local _, hit = workspace:FindPartOnRay(
                Ray.new(origin, offset.Unit * minDist)
            )
            local dist = (hit - origin).Magnitude
            if minDist > dist then
                minDist = dist
                minVect = offset.Unit
            end
        end
    end
    return fz:Dot(minVect) * minDist
end

local PlayerState = {}
local mouseBehavior
local mouseIconEnabled
local cameraType
local cameraFocus
local cameraCFrame

function PlayerState.Push()
    cameraFov = Camera.FieldOfView
    cameraType   = Camera.CameraType
    cameraCFrame = Camera.CFrame
    cameraFocus  = Camera.Focus
    Camera.CameraType   = Enum.CameraType.Custom
    Camera.FieldOfView  = 70
    mouseIconEnabled    = UserInputService.MouseIconEnabled
    UserInputService.MouseIconEnabled = true
    mouseBehavior       = UserInputService.MouseBehavior
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function PlayerState.Pop()
    Camera.FieldOfView = 70
    if cameraType then
        Camera.CameraType = cameraType
    end
    if cameraCFrame then
        Camera.CFrame = cameraCFrame
    end
    if cameraFocus then
        Camera.Focus = cameraFocus
    end
    if mouseIconEnabled ~= nil then
        UserInputService.MouseIconEnabled = mouseIconEnabled
    end
    if mouseBehavior then
        UserInputService.MouseBehavior = mouseBehavior
    end
    cameraType        = nil
    cameraCFrame      = nil
    cameraFocus       = nil
    mouseBehavior     = nil
    mouseIconEnabled  = nil
end

local function StepFreecam(dt)
    local vel = velSpring:Update(dt, Input.Vel(dt))
    local pan = panSpring:Update(dt, Input.Pan(dt))

    local zoomFactor = math.sqrt(
        math.tan(math.rad(70 / 2)) / math.tan(math.rad(cameraFov / 2))
    )
    cameraRot = cameraRot
        + pan * Vector2.new(0.75, 1) * 8 * (dt / zoomFactor)
    cameraRot = Vector2.new(
        math.clamp(cameraRot.x, -math.rad(90), math.rad(90)),
        cameraRot.y % (2 * math.pi)
    )
    local cameraCFrame =
        CFrame.new(cameraPos)
        * CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)
        * CFrame.new(vel * Vector3.new(1, 1, 1) * 64 * dt)
    cameraPos = cameraCFrame.Position
    Camera.CFrame = cameraCFrame
    Camera.Focus = cameraCFrame * CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
    Camera.FieldOfView = cameraFov
end

local function StartFreecam(pos)
    if fcRunning then
        return
    end
    local cameraCFrame = Camera.CFrame
    if pos then
        cameraCFrame = pos
    end
    cameraRot = Vector2.new()
    cameraPos = cameraCFrame.Position
    cameraFov = Camera.FieldOfView
    velSpring:Reset(Vector3.new())
    panSpring:Reset(Vector2.new())
    PlayerState.Push()
    Input.StartCapture()
    RunService:BindToRenderStep(
        "IY_Freecam",
        Enum.RenderPriority.Camera.Value,
        StepFreecam
    )
    fcRunning = true
end
local function StopFreecam()
    if not fcRunning then
        return
    end
    Input.StopCapture()
    RunService:UnbindFromRenderStep("IY_Freecam")
    PlayerState.Pop()
    workspace.CurrentCamera.FieldOfView = 70
    fcRunning = false
end
_G.EnableFreecam = StartFreecam
_G.DisableFreecam = StopFreecam
