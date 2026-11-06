--==================================================
-- FART SPAM V2.8
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local _S = {}

local rgb = Color3.fromRGB

local player = Players.LocalPlayer

local fartRemote = game.ReplicatedStorage.Remotes.Misc.Fart

local enabled = false
local unloaded = false
local minimized = false
local settingsOpen = false

local fartCount = 0
local delayTime = 0.5
local uiScale = 1
local uiTransparency = 0

local spamToken = 0
local dragging = false
local sliderDragging = nil

-- Keybinds
local fartKey = Enum.KeyCode.F
local spamKey = Enum.KeyCode.E
local ninjaKey = Enum.KeyCode.Q
local patternKey = Enum.KeyCode.P
local orbitKey = Enum.KeyCode.R
local faceKey = Enum.KeyCode.G
local listeningFor = nil
local togglePatternPlayback

-- Gradient state
local currentGradient = nil
local gradientA = rgb(25, 27, 34)
local gradientB = rgb(85, 50, 150)
local gradientAngle = 35

local connections = {}
local function keep(connection)
    table.insert(connections, connection)
    return connection
end

--==================================================
-- THEME
--==================================================

local defaultTheme = {
    Background = rgb(25, 27, 34),
    Topbar = rgb(34, 37, 47),
    Accent = rgb(95, 140, 255),
    Text = rgb(245, 245, 250),
    Muted = rgb(155, 160, 175),
    Button = rgb(48, 52, 64),
    Track = rgb(65, 70, 85),
}

local theme = {}

local function resetTheme()
    for name, color in pairs(defaultTheme) do
        theme[name] = color
    end
end

resetTheme()

local bindings = {}

local function bind(object, prop, key)
    bindings[object] = bindings[object] or {}
    bindings[object][prop] = key
    object[prop] = theme[key]
end

local refreshTheme

--==================================================
-- GUI CREATION
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "FartSpamGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "FartSpamCrosshairGUI"
crosshairGui.ResetOnSpawn = false
crosshairGui.IgnoreGuiInset = true
crosshairGui.DisplayOrder = 10
crosshairGui.Parent = player:WaitForChild("PlayerGui")

local ninjaCrosshair = Instance.new("Frame")
ninjaCrosshair.Name = "FreecamCrosshair"
ninjaCrosshair.Size = UDim2.fromOffset(3, 3)
ninjaCrosshair.AnchorPoint = Vector2.new(0.5, 0.5)
ninjaCrosshair.Position = UDim2.fromScale(0.5, 0.5)
ninjaCrosshair.BorderSizePixel = 0
ninjaCrosshair.Active = false
ninjaCrosshair.Visible = false
ninjaCrosshair.ZIndex = 100
ninjaCrosshair.Parent = crosshairGui
bind(ninjaCrosshair, "BackgroundColor3", "Accent")

local frame = Instance.new("Frame")
frame.Name = "MainWindow"
frame.Size = UDim2.fromOffset(310, 260)
frame.Position = UDim2.new(0.5, -155, 0.5, -130)
frame.BackgroundColor3 = theme.Background
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Transparency = 0.55
stroke.Parent = frame
bind(stroke, "Color", "Accent")

local scaleObject = Instance.new("UIScale")
scaleObject.Parent = frame

local frameGradient = Instance.new("UIGradient")
frameGradient.Rotation = gradientAngle
frameGradient.Enabled = false
frameGradient.Parent = frame

local function applyBackground()
    frameGradient.Rotation = gradientAngle
    if currentGradient then
        frameGradient.Color = ColorSequence.new(gradientA, gradientB)
        frameGradient.Enabled = true
        frame.BackgroundColor3 = Color3.new(1, 1, 1)
    else
        frameGradient.Enabled = false
        frame.BackgroundColor3 = theme.Background
    end
end

--==================================================
-- DEFAULT UI SCALING
--==================================================

local camera = workspace.CurrentCamera
local scaleInitialized = false

local function updateScale()
    local viewport = camera.ViewportSize
    if not scaleInitialized then
        if UIS.TouchEnabled then
            uiScale = 0.8
        elseif viewport.Y >= 2000 then
            uiScale = 1.1
        elseif viewport.Y >= 1300 then
            uiScale = 1.0
        elseif viewport.Y >= 900 then
            uiScale = 0.9
        else
            uiScale = 0.8
        end
        scaleInitialized = true
    end
    scaleObject.Scale = math.clamp(uiScale, 0.5, 1.3)
end

updateScale()

keep(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

--==================================================
-- UI HELPERS
--==================================================

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 7)
    c.Parent = object
    return c
end

local function makeButton(parent, text, size, position, color, textColor)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundTransparency = uiTransparency
    button.Text = text
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = parent
    if typeof(color) == "string" then
        bind(button, "BackgroundColor3", color)
    else
        button.BackgroundColor3 = color
    end
    if textColor then
        button.TextColor3 = textColor
    else
        bind(button, "TextColor3", "Text")
    end
    corner(button, 7)
    return button
end

local function makeLabel(parent, text, size, position, textSize)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextSize = textSize or 13
    label.Font = Enum.Font.Gotham
    label.Parent = parent
    bind(label, "TextColor3", "Text")
    return label
end

local function makeTextBox(parent, text, placeholder, size, position)
    local box = Instance.new("TextBox")
    box.Size = size
    box.Position = position
    box.BackgroundTransparency = uiTransparency
    box.Text = text
    box.PlaceholderText = placeholder
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = parent
    bind(box, "BackgroundColor3", "Button")
    bind(box, "TextColor3", "Text")
    bind(box, "PlaceholderColor3", "Muted")
    corner(box, 6)
    return box
end

--==================================================
-- TOPBAR
--==================================================

local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 40)
topbar.BackgroundTransparency = uiTransparency
topbar.BorderSizePixel = 0
topbar.Active = true
topbar.Parent = frame
bind(topbar, "BackgroundColor3", "Topbar")
corner(topbar, 12)

local title = makeLabel(topbar, "FART SPAM V2.8", UDim2.new(1, -125, 1, 0), UDim2.fromOffset(14, 0), 17)
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local settingsToggleButton = makeButton(topbar, "⚙", UDim2.fromOffset(27, 27), UDim2.new(1, -98, 0, 6), "Button")
settingsToggleButton.TextSize = 19

local minimize = makeButton(topbar, "−", UDim2.fromOffset(27, 27), UDim2.new(1, -66, 0, 6), "Button")
minimize.TextSize = 20

local close = makeButton(topbar, "×", UDim2.fromOffset(27, 27), UDim2.new(1, -34, 0, 6), rgb(170, 55, 65))
close.TextSize = 20

--==================================================
-- MAIN PAGE
--==================================================

local main = Instance.new("Frame")
main.Size = UDim2.new(1, 0, 1, -40)
main.Position = UDim2.fromOffset(0, 40)
main.BackgroundTransparency = 1
main.Parent = frame

local counter = makeLabel(main, "Farts: 0", UDim2.new(1, 0, 0, 27), UDim2.fromOffset(0, 5), 15)
counter.Font = Enum.Font.GothamBold
bind(counter, "TextColor3", "Accent")

local single = makeButton(main, "FART ONCE", UDim2.new(0.86, 0, 0, 32), UDim2.new(0.07, 0, 0, 36), "Accent")

local spamButton = makeButton(main, "START SPAM", UDim2.new(0.86, 0, 0, 32), UDim2.new(0.07, 0, 0, 74), rgb(45, 155, 95))

local delayLabel = makeLabel(main, "DELAY: 0.500s", UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 110), 12)
delayLabel.Font = Enum.Font.GothamBold
bind(delayLabel, "TextColor3", "Muted")

local delayHint = makeLabel(main, "OR TYPE AN EXACT DELAY (SECONDS):", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 160), 10)
bind(delayHint, "TextColor3", "Muted")

local delayBox = makeTextBox(main, "0.5", "0.005 - 10", UDim2.new(0.86, 0, 0, 26), UDim2.new(0.07, 0, 0, 176))

local hideHint = makeLabel(main, "Hide - RShift", UDim2.new(1, -12, 0, 14), UDim2.new(0, 6, 1, -14), 10)
hideHint.TextXAlignment = Enum.TextXAlignment.Right
bind(hideHint, "TextColor3", "Muted")

--==================================================
-- REUSABLE SLIDER
--==================================================

local function makeSlider(parent, y, initialPercent, callback)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0.95, 0, 0, 6)
    track.Position = UDim2.new(0.025, 0, 0, y)
    track.BackgroundTransparency = uiTransparency
    track.BorderSizePixel = 0
    track.Parent = parent
    bind(track, "BackgroundColor3", "Track")
    corner(track, 10)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundTransparency = uiTransparency
    fill.BorderSizePixel = 0
    fill.Parent = track
    bind(fill, "BackgroundColor3", "Accent")
    corner(fill, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialPercent, 0, 0.5, 0)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    bind(knob, "BackgroundColor3", "Text")
    corner(knob, 20)

    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.new(1, 0, 0, 34)
    hitbox.Position = UDim2.new(0, 0, 0.5, -17)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.ZIndex = 5
    hitbox.Parent = track

    local function setPercent(percent)
        percent = math.clamp(percent, 0, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, 0, 0.5, 0)
    end

    local function update(x)
        local percent = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setPercent(percent)
        callback(percent)
    end

    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = update
            update(input.Position.X)
        end
    end)

    return {
        Track = track,
        Fill = fill,
        Knob = knob,
        Hitbox = hitbox,
        Update = update,
        SetPercent = setPercent
    }
end

keep(UIS.InputChanged:Connect(function(input)
    if sliderDragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging(input.Position.X)
        end
    end
end))

keep(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = nil
    end
end))

--==================================================
-- FART DELAY
--==================================================

local MIN_DELAY = 0.005
local MAX_SLIDER_DELAY = 2
local MAX_DELAY = 10

local delaySlider

local function delayToPercent(delay)
    return math.clamp((delay - MIN_DELAY) / (MAX_SLIDER_DELAY - MIN_DELAY), 0, 1)
end

local function percentToDelay(percent)
    local delay = MIN_DELAY + (MAX_SLIDER_DELAY - MIN_DELAY) * math.clamp(percent, 0, 1)
    return math.max(MIN_DELAY, math.floor(delay * 1000 + 0.000001) / 1000)
end

local function setDelay(value, moveSlider)
    value = math.floor(value * 1000 + 0.5) / 1000
    delayTime = math.clamp(value, MIN_DELAY, MAX_DELAY)
    delayLabel.Text = string.format("DELAY: %.3fs", delayTime)
    delayBox.Text = tostring(delayTime)
    if moveSlider and delaySlider then
        delaySlider.SetPercent(delayToPercent(delayTime))
    end
end

delaySlider = makeSlider(
    main,
    143,
    delayToPercent(delayTime),
    function(percent)
        setDelay(percentToDelay(percent), false)
    end
)

delayBox.FocusLost:Connect(function()
    local typed = tonumber(delayBox.Text)
    if typed and typed == typed then
        setDelay(typed, true)
    else
        setDelay(delayTime, true)
    end
end)

setDelay(delayTime, true)

--==================================================
-- FART ACTIONS
--==================================================

local statsSection
local stopPattern
local triggerNinja
local refreshSideMenu

local function fart()
    if unloaded then return end
    fartRemote:FireServer()
    fartCount += 1
    counter.Text = "Farts: " .. fartCount
    if statsSection then
        statsSection.Text = "FARTS: " .. fartCount
    end
end

single.MouseButton1Click:Connect(fart)

local MAX_BURST = 25

local function spamLoop(token)
    local nextFart = os.clock()
    while enabled and not unloaded and token == spamToken do
        local now = os.clock()
        local burst = 0
        while nextFart <= now and burst < MAX_BURST do
            fart()
            nextFart += delayTime
            burst += 1
        end
        if nextFart < now then
            nextFart = now
        end
        task.wait()
    end
end

local function setSpam(state)
    if unloaded then return end
    enabled = state
    spamToken += 1
    local currentToken = spamToken
    if enabled then
        if stopPattern then stopPattern() end
        spamButton.Text = "STOP SPAM"
        spamButton.BackgroundColor3 = rgb(190, 65, 65)
        task.spawn(spamLoop, currentToken)
    else
        spamButton.Text = "START SPAM"
        spamButton.BackgroundColor3 = rgb(45, 155, 95)
    end
end

spamButton.MouseButton1Click:Connect(function()
    setSpam(not enabled)
end)

--==================================================
-- SETTINGS PAGE
--==================================================

local settings = Instance.new("ScrollingFrame")
settings.Size = UDim2.new(1, -12, 1, -48)
settings.Position = UDim2.fromOffset(6, 44)
settings.BackgroundTransparency = 1
settings.BorderSizePixel = 0
settings.ScrollBarThickness = 4
settings.AutomaticCanvasSize = Enum.AutomaticSize.Y
settings.CanvasSize = UDim2.new(0, 0, 0, 0)
settings.ScrollingDirection = Enum.ScrollingDirection.Y
settings.Visible = false
settings.Parent = frame
bind(settings, "ScrollBarImageColor3", "Accent")

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 9)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = settings

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 7)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 9)
padding.PaddingRight = UDim.new(0, 9)
padding.Parent = settings

local function section(text, order)
    local label = makeLabel(settings, text, UDim2.new(1, 0, 0, 25), UDim2.new(), 13)
    label.Font = Enum.Font.GothamBold
    label.LayoutOrder = order
    label.TextColor3 = rgb(225, 225, 230)
    return label
end

local function settingsButton(text, order, color)
    local button = makeButton(settings, text, UDim2.new(1, 0, 0, 34), UDim2.new(), color or "Button")
    button.LayoutOrder = order
    return button
end

local function makeGrid(order, rows)
    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, 0, 0, rows * 30 + (rows - 1) * 6)
    grid.BackgroundTransparency = 1
    grid.LayoutOrder = order
    grid.Parent = settings
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.33, -4, 0, 30)
    gridLayout.CellPadding = UDim2.fromOffset(6, 6)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = grid
    return grid
end

local function makeRow(order, height, parent)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = parent or settings
    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 6)
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout.Parent = row
    return row
end

local function cellSize(count)
    return UDim2.new(1 / count, -(6 * (count - 1)) / count, 1, 0)
end

local function rowButton(row, text, count, order)
    local button = makeButton(row, text, cellSize(count), UDim2.new(), "Button")
    button.LayoutOrder = order
    return button
end

local function makeSliderRow(order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = settings
    return row
end

local back = settingsButton("←  BACK TO FART UI", 1)

section("APPEARANCE", 2)

local scaleOptions = {0.8, 0.9, 1.0, 1.1, 1.2}
local scaleIndex = 1
for i, value in ipairs(scaleOptions) do
    if math.abs(value - uiScale) < 0.001 then
        scaleIndex = i
        break
    end
end
local scaleButtons = {}

local scaleTitle = makeLabel(settings, "UI SIZE: " .. string.format("%.1fx", uiScale), UDim2.new(1, 0, 0, 22), UDim2.new(), 12)
scaleTitle.LayoutOrder = 3
scaleTitle.Font = Enum.Font.GothamBold

local scaleRow = Instance.new("Frame")
scaleRow.Size = UDim2.new(1, 0, 0, 30)
scaleRow.BackgroundTransparency = 1
scaleRow.LayoutOrder = 4
scaleRow.Parent = settings

local scaleRowLayout = Instance.new("UIListLayout")
scaleRowLayout.FillDirection = Enum.FillDirection.Horizontal
scaleRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
scaleRowLayout.Padding = UDim.new(0, 4)
scaleRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
scaleRowLayout.Parent = scaleRow

local function refreshScaleButtons()
    for i, button in ipairs(scaleButtons) do
        button.BackgroundColor3 = (i == scaleIndex) and theme.Accent or theme.Button
    end
end

for i, value in ipairs(scaleOptions) do
    local button = makeButton(scaleRow, string.format("%.1fx", value), UDim2.new(0.2, -4, 1, 0), UDim2.new(), theme.Button)
    button.TextSize = 13
    button.LayoutOrder = i
    button.MouseButton1Click:Connect(function()
        scaleIndex = i
        uiScale = value
        scaleTitle.Text = "UI SIZE: " .. string.format("%.1fx", uiScale)
        updateScale()
        refreshScaleButtons()
    end)
    scaleButtons[i] = button
end

refreshScaleButtons()

local transparencyTitle = makeLabel(settings, "UI TRANSPARENCY: 0%", UDim2.new(1, 0, 0, 22), UDim2.new(), 12)
transparencyTitle.LayoutOrder = 5
transparencyTitle.Font = Enum.Font.GothamBold

local originalBackgroundTransparency = {}
local originalStrokeTransparency = {}
local MAX_UI_TRANSPARENCY = 0.8

local function applyTransparency(value)
    uiTransparency = math.clamp(value, 0, MAX_UI_TRANSPARENCY)
    transparencyTitle.Text = "UI TRANSPARENCY: " .. tostring(math.floor(uiTransparency * 100 + 0.5)) .. "%"
    for _, object in ipairs(gui:GetDescendants()) do
        if object:IsA("GuiObject") then
            if originalBackgroundTransparency[object] == nil then
                originalBackgroundTransparency[object] = object.BackgroundTransparency
            end
            local base = originalBackgroundTransparency[object]
            object.BackgroundTransparency = base + (1 - base) * uiTransparency
        elseif object:IsA("UIStroke") then
            if originalStrokeTransparency[object] == nil then
                originalStrokeTransparency[object] = object.Transparency
            end
            local fade = uiTransparency / MAX_UI_TRANSPARENCY
            local base = originalStrokeTransparency[object]
            object.Transparency = base + (1 - base) * fade
        end
    end
end

local transparencyRow = makeSliderRow(6)

local transparencySlider = makeSlider(
    transparencyRow,
    9,
    0,
    function(percent)
        applyTransparency(math.floor(percent * 80) / 100)
    end
)

section("CONTROLS  (TAP A BOX TO REBIND)", 7)

local keyRow = makeRow(8, 38)

local fartKeyButton = rowButton(keyRow, "", 3, 1)
local spamKeyButton = rowButton(keyRow, "", 3, 2)
local patternKeyButton = rowButton(keyRow, "", 3, 3)
local orbitKeyButton

for _, button in ipairs({fartKeyButton, spamKeyButton, patternKeyButton}) do
    button.TextScaled = true
    local limit = Instance.new("UITextSizeConstraint")
    limit.MaxTextSize = 12
    limit.Parent = button
end

local ninjaKeyButton
local faceKeyButton

local keyConflictWarning = makeLabel(settings, "", UDim2.new(1, 0, 0, 16), UDim2.new(), 11)
keyConflictWarning.LayoutOrder = 9
keyConflictWarning.Visible = false
keyConflictWarning.TextWrapped = true
keyConflictWarning.Font = Enum.Font.GothamBold
keyConflictWarning.TextColor3 = rgb(230, 170, 60)
bindings[keyConflictWarning] = nil

local function refreshKeyConflicts()
    local binds = {
        {name = "FART", key = fartKey},
        {name = "SPAM", key = spamKey},
        {name = "PATTERN", key = patternKey},
        {name = "ORBIT", key = orbitKey},
        {name = "NINJA", key = ninjaKey},
        {name = "FACE", key = faceKey},
    }
    local seen = {}
    local clashes = {}
    for _, entry in ipairs(binds) do
        local existing = seen[entry.key]
        if existing then
            table.insert(clashes, existing .. " + " .. entry.name)
        else
            seen[entry.key] = entry.name
        end
    end
    if #clashes > 0 then
        keyConflictWarning.Text = "⚠ Keybind conflict: " .. table.concat(clashes, ", ") .. " share a key."
        keyConflictWarning.Visible = true
    else
        keyConflictWarning.Visible = false
    end
end

local function refreshKeyButtons()
    if ninjaKeyButton then
        if listeningFor == "ninja" then
            ninjaKeyButton.Text = "PRESS A KEY...\nESC = CANCEL"
        else
            ninjaKeyButton.Text = "NINJA KEY: " .. ninjaKey.Name .. "\nTAP TO CHANGE"
        end
    end
    if listeningFor == "fart" then
        fartKeyButton.Text = "PRESS A KEY...\nESC = CANCEL"
    else
        fartKeyButton.Text = "FART KEY: " .. fartKey.Name .. "\nTAP TO CHANGE"
    end
    if listeningFor == "spam" then
        spamKeyButton.Text = "PRESS A KEY...\nESC = CANCEL"
    else
        spamKeyButton.Text = "SPAM KEY: " .. spamKey.Name .. "\nTAP TO CHANGE"
    end
    if listeningFor == "pattern" then
        patternKeyButton.Text = "PRESS A KEY...\nESC = CANCEL"
    else
        patternKeyButton.Text = "PATTERN: " .. patternKey.Name .. "\nPLAY / PAUSE"
    end
    if orbitKeyButton then
        if listeningFor == "orbit" then
            orbitKeyButton.Text = "PRESS A KEY...\nESC = CANCEL"
        else
            orbitKeyButton.Text = "ORBIT KEY: " .. orbitKey.Name .. "\nTAP TO CHANGE"
        end
    end
    if faceKeyButton then
        if listeningFor == "face" then
            faceKeyButton.Text = "PRESS A KEY...\nESC = CANCEL"
        else
            faceKeyButton.Text = "FACE KEY: " .. faceKey.Name .. "\nTAP TO CHANGE"
        end
    end
    refreshKeyConflicts()
end

refreshKeyButtons()

fartKeyButton.MouseButton1Click:Connect(function()
    listeningFor = (listeningFor ~= "fart") and "fart" or nil
    refreshKeyButtons()
end)

spamKeyButton.MouseButton1Click:Connect(function()
    listeningFor = (listeningFor ~= "spam") and "spam" or nil
    refreshKeyButtons()
end)

patternKeyButton.MouseButton1Click:Connect(function()
    listeningFor = (listeningFor ~= "pattern") and "pattern" or nil
    refreshKeyButtons()
end)

keep(UIS.InputBegan:Connect(function(input, gameProcessed)
    if unloaded then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.Unknown then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        frame.Visible = not frame.Visible
        return
    end

    if listeningFor then
        local which = listeningFor
        listeningFor = nil
        if input.KeyCode ~= Enum.KeyCode.Escape then
            if which == "fart" then
                fartKey = input.KeyCode
            elseif which == "spam" then
                spamKey = input.KeyCode
            elseif which == "pattern" then
                patternKey = input.KeyCode
            elseif which == "orbit" then
                orbitKey = input.KeyCode
            elseif which == "ninja" then
                ninjaKey = input.KeyCode
            elseif which == "face" then
                faceKey = input.KeyCode
            end
        end
        refreshKeyButtons()
        return
    end

    if gameProcessed then return end

    if input.KeyCode == fartKey then fart() end
    if input.KeyCode == spamKey then setSpam(not enabled) end
    if input.KeyCode == ninjaKey then triggerNinja() end
    if input.KeyCode == patternKey and togglePatternPlayback then togglePatternPlayback() end
    if input.KeyCode == faceKey and _S.toggleFaceFart then _S.toggleFaceFart() end
end))

--==================================================
-- THEMES
--==================================================

local function newTheme(name, bg, topbarColor, accent, button, trackColor, text, muted, gradA, gradB)
    return {
        Name = name,
        Background = bg,
        Topbar = topbarColor,
        Accent = accent,
        Button = button,
        Track = trackColor,
        Text = text or rgb(245, 245, 250),
        Muted = muted or rgb(155, 160, 175),
        GradientA = gradA,
        GradientB = gradB
    }
end

local themePresets = {
    newTheme("Crimson", rgb(120, 20, 30), rgb(45, 10, 20), rgb(220, 50, 50), rgb(70, 20, 20), rgb(90, 40, 30), nil, nil, rgb(45, 10, 20), rgb(120, 20, 30)),
    newTheme("Charcoal", rgb(40, 45, 50), rgb(55, 60, 65), rgb(80, 90, 100), rgb(60, 65, 70), rgb(70, 75, 80), rgb(200, 200, 200), rgb(160, 165, 170), rgb(40, 45, 50), rgb(80, 90, 100)),
    newTheme("Midnight", rgb(28, 22, 38), rgb(40, 31, 54), rgb(170, 110, 255), rgb(58, 45, 78), rgb(78, 62, 102), nil, nil, rgb(25, 27, 34), rgb(85, 50, 150))
}

section("THEMES", 10)
local themeGrid = makeGrid(11, 1)
local themeButtons = {}
local activeTheme = nil

local function refreshThemeButtons()
    for i, button in ipairs(themeButtons) do
        local preset = themePresets[i]
        button.BackgroundColor3 = (activeTheme == preset) and preset.Accent or preset.Button
        button.TextColor3 = preset.Text
    end
end

refreshTheme = function()
    for object, props in pairs(bindings) do
        if object.Parent then
            for prop, key in pairs(props) do
                object[prop] = theme[key]
            end
        else
            bindings[object] = nil
        end
    end
    applyBackground()
    refreshScaleButtons()
    refreshThemeButtons()
end

local function applyThemePreset(preset)
    activeTheme = preset
    for key, value in pairs(preset) do
        if key ~= "Name" and key ~= "GradientA" and key ~= "GradientB" then
            theme[key] = value
        end
    end
    gradientA = preset.GradientA
    gradientB = preset.GradientB
    currentGradient = preset
    refreshTheme()
end

for i, preset in ipairs(themePresets) do
    local button = makeButton(themeGrid, preset.Name, UDim2.new(), UDim2.new(), preset.Button, preset.Text)
    button.TextSize = 12
    button.LayoutOrder = i
    themeButtons[i] = button
    button.MouseButton1Click:Connect(function()
        applyThemePreset(preset)
    end)
end

local gradientSpinSpeed = 90
keep(RunService.Heartbeat:Connect(function(dt)
    if unloaded or not currentGradient then return end
    gradientAngle = (gradientAngle + gradientSpinSpeed * dt) % 360
    frameGradient.Rotation = gradientAngle
end))

applyThemePreset(themePresets[3])

--==================================================
-- FART PATTERN
--==================================================

_S.pattern = {}
_S.patternLoop = false
_S.patternToken = 0
_S.patternPlaying = false
_S.patternPaused = false
_S.lastTapTime = nil

_S.MAX_PATTERN_STEPS = 200
_S.MIN_STEP = 0.001
_S.MAX_STEP = 60

function _S.roundMs(n)
    return math.floor(n * 1000 + 0.5) / 1000
end

function _S.patternToString(list)
    local parts = {}
    for i, step in ipairs(list) do
        parts[i] = (step == "F") and "F" or string.format("%g", step)
    end
    return table.concat(parts, ",")
end

function _S.parsePattern(text)
    local result = {}
    for token in string.gmatch(text, "[^%s,;]+") do
        if #result >= _S.MAX_PATTERN_STEPS then
            return nil, "Too many steps (max " .. _S.MAX_PATTERN_STEPS .. ")"
        end
        local upper = string.upper(token)
        if upper == "F" or upper == "FART" then
            table.insert(result, "F")
        else
            local n = tonumber(token)
            if not n or n ~= n or n == math.huge or n == -math.huge then
                return nil, "Unknown step: " .. token
            end
            table.insert(result, math.clamp(_S.roundMs(n), _S.MIN_STEP, _S.MAX_STEP))
        end
    end
    if #result == 0 then
        return nil, "Pattern is empty"
    end
    return result
end

_S.patternToolPanel = Instance.new("Frame")
_S.patternToolPanel.Name = "FartPatternTool"
_S.patternToolPanel.Size = UDim2.new(1, 0, 0, 0)
_S.patternToolPanel.AutomaticSize = Enum.AutomaticSize.Y
_S.patternToolPanel.BackgroundTransparency = 1

_S.patternPanelLayout = Instance.new("UIListLayout")
_S.patternPanelLayout.Padding = UDim.new(0, 6)
_S.patternPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
_S.patternPanelLayout.Parent = _S.patternToolPanel

_S.patternHeading = makeLabel(_S.patternToolPanel, "FART PATTERN", UDim2.new(1, 0, 0, 22), UDim2.new(), 13)
_S.patternHeading.Font = Enum.Font.GothamBold
_S.patternHeading.LayoutOrder = 1
_S.patternHeading.TextColor3 = rgb(225, 225, 230)

_S.patternBox = makeTextBox(_S.patternToolPanel, "", "paste a pattern here, e.g.  F,0.1,F,0.1,F,0.5", UDim2.new(1, 0, 0, 34), UDim2.new())
_S.patternBox.LayoutOrder = 2
_S.patternBox.ClipsDescendants = true
_S.patternBox.TextXAlignment = Enum.TextXAlignment.Left

_S.patternBoxPadding = Instance.new("UIPadding")
_S.patternBoxPadding.PaddingLeft = UDim.new(0, 8)
_S.patternBoxPadding.PaddingRight = UDim.new(0, 8)
_S.patternBoxPadding.Parent = _S.patternBox

_S.patternStatus = makeLabel(_S.patternToolPanel, "", UDim2.new(1, 0, 0, 44), UDim2.new(), 11)
_S.patternStatus.LayoutOrder = 3
_S.patternStatus.TextWrapped = true
bind(_S.patternStatus, "TextColor3", "Muted")

_S.tapButton = makeButton(_S.patternToolPanel, "TAP TO RECORD", UDim2.new(1, 0, 0, 44), UDim2.new(), "Accent")
_S.tapButton.LayoutOrder = 4
_S.tapButton.TextSize = 16

_S.addRow = makeRow(5, 32, _S.patternToolPanel)
_S.addFartButton = rowButton(_S.addRow, "+ FART", 3, 1)
_S.waitBox = makeTextBox(_S.addRow, "0.1", "wait (s)", cellSize(3), UDim2.new())
_S.waitBox.LayoutOrder = 2
_S.addWaitButton = rowButton(_S.addRow, "+ WAIT", 3, 3)
_S.addFartButton.TextSize = 10
_S.addWaitButton.TextSize = 10

_S.toolRow = makeRow(6, 32, _S.patternToolPanel)
_S.undoButton = rowButton(_S.toolRow, "UNDO", 3, 1)
_S.clearButton = rowButton(_S.toolRow, "CLEAR", 3, 2)
_S.randomButton = rowButton(_S.toolRow, "RANDOM", 3, 3)
_S.undoButton.TextSize = 10
_S.clearButton.TextSize = 10
_S.randomButton.TextSize = 10

_S.playRow = makeRow(7, 34, _S.patternToolPanel)
_S.playButton = rowButton(_S.playRow, "PLAY", 3, 1)
_S.stopButton = rowButton(_S.playRow, "STOP", 3, 2)
_S.loopButton = rowButton(_S.playRow, "LOOP: OFF", 3, 3)
_S.playButton.TextSize = 10
_S.stopButton.TextSize = 10
_S.loopButton.TextSize = 10

_S.pauseButton = makeButton(_S.patternToolPanel, "PAUSE", UDim2.new(1, 0, 0, 30), UDim2.new(), "Button")
_S.pauseButton.LayoutOrder = 8
_S.pauseButton.TextSize = 10

function _S.patternSummary()
    if #_S.pattern == 0 then
        return "Empty. Tap the button to record a beat, or paste a pattern into the bar."
    end
    local farts, waits, total = 0, 0, 0
    for _, step in ipairs(_S.pattern) do
        if step == "F" then
            farts += 1
        else
            waits += 1
            total += step
        end
    end
    local text = string.format("%d farts, %.2fs long", farts, total)
    if waits > 0 and total > 0 then
        text = text .. string.format(", ~%d BPM", math.floor(60 / (total / waits) + 0.5))
    end
    return text
end

function _S.refreshPattern(message)
    _S.patternBox.Text = _S.patternToString(_S.pattern)
    _S.patternStatus.Text = message or _S.patternSummary()
end

function _S.addStep(step)
    if #_S.pattern >= _S.MAX_PATTERN_STEPS then
        _S.patternStatus.Text = "Pattern is full (max " .. _S.MAX_PATTERN_STEPS .. " steps)."
        return
    end
    table.insert(_S.pattern, step)
    _S.refreshPattern()
end

stopPattern = function()
    _S.patternToken += 1
    _S.patternPlaying = false
    _S.patternPaused = false
end

function _S.pausePattern()
    if not _S.patternPlaying then
        _S.patternStatus.Text = "Nothing is playing to pause."
        return
    end
    _S.patternPaused = true
    _S.patternStatus.Text = "Paused. Press PLAY or the pattern key to resume."
end

function _S.playPattern()
    if unloaded then return end
    if _S.patternPlaying then
        if _S.patternPaused then
            _S.patternPaused = false
            _S.patternStatus.Text = "Resumed. " .. _S.patternSummary()
        else
            _S.patternStatus.Text = "Already playing. " .. _S.patternSummary()
        end
        return
    end
    if #_S.pattern == 0 then
        _S.patternStatus.Text = "Nothing to play - record or paste a pattern first."
        return
    end
    setSpam(false)
    _S.patternToken += 1
    local token = _S.patternToken
    _S.patternPlaying = true
    _S.patternPaused = false

    task.spawn(function()
        local due = os.clock()
        local function waitWhilePaused()
            while _S.patternPaused and not unloaded and token == _S.patternToken do
                local pauseStarted = os.clock()
                repeat
                    task.wait()
                until not _S.patternPaused or unloaded or token ~= _S.patternToken
                due += os.clock() - pauseStarted
            end
        end
        repeat
            local yielded = false
            for _, step in ipairs(_S.pattern) do
                waitWhilePaused()
                if unloaded or token ~= _S.patternToken then return end
                if step == "F" then
                    fart()
                else
                    due += step
                    while true do
                        waitWhilePaused()
                        if unloaded or token ~= _S.patternToken then return end
                        if os.clock() >= due then break end
                        task.wait()
                        yielded = true
                    end
                end
            end
            if not yielded then
                task.wait()
                due = os.clock()
            end
        until not _S.patternLoop or unloaded or token ~= _S.patternToken

        if token == _S.patternToken then
            _S.patternPlaying = false
            _S.patternPaused = false
            _S.patternStatus.Text = "Playback finished. " .. _S.patternSummary()
        end
    end)
end

togglePatternPlayback = function()
    if _S.patternPlaying and not _S.patternPaused then
        _S.pausePattern()
    else
        _S.playPattern()
    end
end

function _S.generateRandomPattern()
    local waits = {0.05, 0.1, 0.15, 0.25, 0.5}
    local result = {"F"}
    for _ = 1, math.random(3, 9) do
        table.insert(result, waits[math.random(#waits)])
        table.insert(result, "F")
    end
    return result
end

function _S.recordTap()
    if unloaded then return end
    local now = os.clock()
    fart()
    if #_S.pattern == 0 then
        table.insert(_S.pattern, "F")
        _S.lastTapTime = now
        _S.refreshPattern("Recording! Keep tapping the beat. " .. _S.patternSummary())
        return
    end
    if not _S.lastTapTime then
        _S.lastTapTime = now
        _S.patternStatus.Text = "Synced - your next taps are added to the end of the pattern."
        return
    end
    if #_S.pattern + 2 > _S.MAX_PATTERN_STEPS then
        _S.patternStatus.Text = "Pattern is full (max " .. _S.MAX_PATTERN_STEPS .. " steps)."
        return
    end
    local gap = math.clamp(_S.roundMs(now - _S.lastTapTime), _S.MIN_STEP, _S.MAX_STEP)
    _S.lastTapTime = now
    table.insert(_S.pattern, gap)
    table.insert(_S.pattern, "F")
    _S.refreshPattern(string.format("Tap recorded (gap %.3fs). %s", gap, _S.patternSummary()))
end

_S.tapButton.MouseButton1Down:Connect(_S.recordTap)

_S.addFartButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    _S.addStep("F")
end)

_S.addWaitButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    local n = tonumber(_S.waitBox.Text)
    if not n or n ~= n or n == math.huge or n == -math.huge then
        _S.patternStatus.Text = "Type a wait time in seconds first (0.001 - 60)."
        return
    end
    n = math.clamp(_S.roundMs(n), _S.MIN_STEP, _S.MAX_STEP)
    _S.waitBox.Text = tostring(n)
    _S.addStep(n)
end)

_S.undoButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    table.remove(_S.pattern)
    _S.lastTapTime = nil
    _S.refreshPattern()
end)

_S.clearButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    stopPattern()
    table.clear(_S.pattern)
    _S.lastTapTime = nil
    _S.refreshPattern()
end)

_S.randomButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    _S.pattern = _S.generateRandomPattern()
    _S.lastTapTime = nil
    _S.refreshPattern()
end)

_S.playButton.MouseButton1Click:Connect(_S.playPattern)

_S.stopButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    stopPattern()
    _S.patternStatus.Text = "Playback stopped. " .. _S.patternSummary()
end)

_S.pauseButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    _S.pausePattern()
end)

_S.loopButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    _S.patternLoop = not _S.patternLoop
    _S.loopButton.Text = "LOOP: " .. (_S.patternLoop and "ON" or "OFF")
end)

_S.patternBox.Focused:Connect(function()
    task.defer(function()
        if _S.patternBox:IsFocused() then
            _S.patternBox.CursorPosition = #_S.patternBox.Text + 1
            _S.patternBox.SelectionStart = 1
        end
    end)
end)

_S.patternBox.FocusLost:Connect(function()
    if unloaded then return end
    if string.match(_S.patternBox.Text, "^%s*$") then
        stopPattern()
        table.clear(_S.pattern)
        _S.lastTapTime = nil
        _S.refreshPattern()
        return
    end
    local parsed, err = _S.parsePattern(_S.patternBox.Text)
    if parsed then
        _S.pattern = parsed
        _S.lastTapTime = nil
        _S.refreshPattern("Loaded! " .. _S.patternSummary())
    else
        _S.patternStatus.Text = "Can't read that: " .. err .. ". Fix it and click away to load."
    end
end)

_S.refreshPattern()

--==================================================
-- STATS
--==================================================

statsSection = makeButton(settings, "FARTS: " .. fartCount, UDim2.new(1, 0, 0, 25), UDim2.new(), "Button")
statsSection.Font = Enum.Font.GothamBold
statsSection.LayoutOrder = 40

statsSection.MouseButton1Click:Connect(function()
    if unloaded then return end
    print("Current stats: " .. fartCount .. " farts")
end)

_S.resetStatsButton = settingsButton("RESET STATS", 41)

_S.resetStatsButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    fartCount = 0
    counter.Text = "Farts: 0"
    statsSection.Text = "FARTS: 0"
    print("Stats reset.")
end)

--==================================================
-- SIDE MENU
--==================================================

_S.SIDE_WIDTH = 176
_S.sideOpen = true

_S.sideTab = makeButton(frame, "‹", UDim2.fromOffset(22, 64), UDim2.new(1, 4, 0, 48), "Button")
_S.sideTab.TextSize = 18

_S.sidePanel = Instance.new("Frame")
_S.sidePanel.Name = "SidePanel"
_S.sidePanel.Size = UDim2.new(0, _S.SIDE_WIDTH, 1, 0)
_S.sidePanel.Position = UDim2.new(1, 32, 0, 0)
_S.sidePanel.BackgroundTransparency = uiTransparency
_S.sidePanel.BorderSizePixel = 0
_S.sidePanel.Parent = frame
bind(_S.sidePanel, "BackgroundColor3", "Background")
corner(_S.sidePanel, 12)

_S.sideStroke = Instance.new("UIStroke")
_S.sideStroke.Thickness = 1
_S.sideStroke.Transparency = 0.55
_S.sideStroke.Parent = _S.sidePanel
bind(_S.sideStroke, "Color", "Accent")

_S.sideTitle = makeLabel(_S.sidePanel, "TOOLS", UDim2.new(1, 0, 0, 34), UDim2.new(), 15)
_S.sideTitle.Font = Enum.Font.GothamBold
_S.sideTitle.TextColor3 = rgb(225, 225, 230)

_S.sideList = Instance.new("ScrollingFrame")
_S.sideList.Size = UDim2.new(1, -12, 1, -42)
_S.sideList.Position = UDim2.fromOffset(6, 38)
_S.sideList.BackgroundTransparency = 1
_S.sideList.BorderSizePixel = 0
_S.sideList.ScrollBarThickness = 4
_S.sideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
_S.sideList.CanvasSize = UDim2.new(0, 0, 0, 0)
_S.sideList.ScrollingDirection = Enum.ScrollingDirection.Y
_S.sideList.Parent = _S.sidePanel
bind(_S.sideList, "ScrollBarImageColor3", "Accent")

_S.sideLayout = Instance.new("UIListLayout")
_S.sideLayout.Padding = UDim.new(0, 4)
_S.sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
_S.sideLayout.Parent = _S.sideList

_S.sidePadding = Instance.new("UIPadding")
_S.sidePadding.PaddingLeft = UDim.new(0, 4)
_S.sidePadding.PaddingRight = UDim.new(0, 6)
_S.sidePadding.PaddingBottom = UDim.new(0, 8)
_S.sidePadding.Parent = _S.sideList

function _S.makeToolSection(title, order, description)
    local section = Instance.new("Frame")
    section.Name = title:gsub("%W", "") .. "Section"
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    section.Parent = _S.sideList

    local sectionLayout = Instance.new("UIListLayout")
    sectionLayout.Padding = UDim.new(0, 3)
    sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sectionLayout.Parent = section

    local header = makeButton(section, "+  " .. title, UDim2.new(1, 0, 0, 32), UDim2.new(), "Button")
    header.LayoutOrder = 1
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextSize = 12
    header.Font = Enum.Font.GothamBold

    local descriptionLabel
    if description and description ~= "" then
        descriptionLabel = makeLabel(section, description, UDim2.new(1, -4, 0, 24), UDim2.fromOffset(4, 0), 10)
        descriptionLabel.LayoutOrder = 2
        descriptionLabel.TextWrapped = true
        descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
        descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        bind(descriptionLabel, "TextColor3", "Muted")
    end

    local body = Instance.new("Frame")
    body.Name = "ToolContents"
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.Visible = false
    body.LayoutOrder = 3
    body.Parent = section

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 6)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    header.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        header.Text = (body.Visible and "−  " or "+  ") .. title
    end)

    return section, body
end

refreshSideMenu = function()
    local show = not minimized
    _S.sideTab.Visible = show
    _S.sidePanel.Visible = show and _S.sideOpen
    _S.sideTab.Text = _S.sideOpen and "‹" or "›"
end

_S.sideTab.MouseButton1Click:Connect(function()
    _S.sideOpen = not _S.sideOpen
    refreshSideMenu()
end)

--------------------------------------------------
-- TOOL: NINJA TELEPORT
--------------------------------------------------

_S.NINJA_DURATION = 2.0
_S.NINJA_POST_TP_DURATION = 1.0
_S.NINJA_POST_TP_TURNS = 1
_S.NINJA_FARTS = 150
_S.NINJA_FART_LEAD = 0.225
_S.NINJA_FART_SPAN = _S.NINJA_DURATION + _S.NINJA_FART_LEAD
_S.NINJA_TURNS = 4
_S.NINJA_TP_DROP_STUDS = 1000
_S.NINJA_ARM_TIMEOUT = 20
_S.NINJA_RAY_DISTANCE = 10000
_S.NINJA_FREECAM_SPEED = 110
_S.NINJA_FREECAM_BOOST = 3
_S.NINJA_FREECAM_SENSITIVITY = 0.005
_S.NINJA_LANDING_FARTS = 50
_S.NINJA_LANDING_TIME = 1.0
_S.ninjaLandingFart = true

_S.NINJA_MODES = {"CAMERA LOCK", "FREECAM"}
_S.ninjaModeIndex = 2
_S.ninjaMode = _S.NINJA_MODES[_S.ninjaModeIndex]
_S.ninjaCameraSession = nil
_S.ninjaHiddenReturnCFrame = nil
_S.ninjaLocalPlatform = nil

_S.ninjaState = "idle"
_S.ninjaToken = 0

_S.ninjaLabel = makeLabel(_S.sideList, "NINJA TELEPORT", UDim2.new(1, 0, 0, 22), UDim2.new(), 12)
_S.ninjaLabel.Font = Enum.Font.GothamBold
_S.ninjaLabel.LayoutOrder = 1
_S.ninjaLabel.TextColor3 = rgb(225, 225, 230)

_S.ninjaRow = Instance.new("Frame")
_S.ninjaRow.Size = UDim2.new(1, 0, 0, 44)
_S.ninjaRow.BackgroundTransparency = 1
_S.ninjaRow.LayoutOrder = 2
_S.ninjaRow.Parent = _S.sideList

_S.ninjaRowLayout = Instance.new("UIListLayout")
_S.ninjaRowLayout.FillDirection = Enum.FillDirection.Horizontal
_S.ninjaRowLayout.Padding = UDim.new(0, 6)
_S.ninjaRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
_S.ninjaRowLayout.Parent = _S.ninjaRow

_S.ninjaButton = makeButton(_S.ninjaRow, "NINJA TELEPORT", UDim2.new(0.62, -3, 1, 0), UDim2.new(), "Accent")
_S.ninjaButton.LayoutOrder = 1
_S.ninjaButton.TextScaled = true
_S.ninjaButtonLimit = Instance.new("UITextSizeConstraint")
_S.ninjaButtonLimit.MaxTextSize = 14
_S.ninjaButtonLimit.Parent = _S.ninjaButton

_S.ninjaFartButton = makeButton(_S.ninjaRow, "", UDim2.new(0.38, -3, 1, 0), UDim2.new(), "Button")
_S.ninjaFartButton.LayoutOrder = 2
_S.ninjaFartButton.TextScaled = true
_S.ninjaFartLimit = Instance.new("UITextSizeConstraint")
_S.ninjaFartLimit.MaxTextSize = 12
_S.ninjaFartLimit.Parent = _S.ninjaFartButton

function _S.refreshNinjaFartButton()
    _S.ninjaFartButton.Text = "TP FART\n" .. (_S.ninjaLandingFart and "ON" or "OFF")
end

_S.refreshNinjaFartButton()

ninjaKeyButton = makeButton(_S.sideList, "", UDim2.new(1, 0, 0, 38), UDim2.new(), "Button")
ninjaKeyButton.LayoutOrder = 3
ninjaKeyButton.TextScaled = true
_S.ninjaKeyLimit = Instance.new("UITextSizeConstraint")
_S.ninjaKeyLimit.MaxTextSize = 12
_S.ninjaKeyLimit.Parent = ninjaKeyButton

_S.ninjaModeButton = makeButton(_S.sideList, "", UDim2.new(1, 0, 0, 38), UDim2.new(), "Button")
_S.ninjaModeButton.LayoutOrder = 4
_S.ninjaModeButton.TextScaled = true
_S.ninjaModeLimit = Instance.new("UITextSizeConstraint")
_S.ninjaModeLimit.MaxTextSize = 12
_S.ninjaModeLimit.Parent = _S.ninjaModeButton

_S.NINJA_FART_PRESETS = {50, 150, 250}
_S.ninjaFartPresetIndex = 2
_S.ninjaFartsButton = makeButton(_S.sideList, "NINJA FARTS: " .. _S.NINJA_FARTS, UDim2.new(1, 0, 0, 36), UDim2.new(), "Button")
_S.ninjaFartsButton.LayoutOrder = 5
_S.ninjaFartsButton.TextScaled = true
_S.ninjaFartsLimit = Instance.new("UITextSizeConstraint")
_S.ninjaFartsLimit.MaxTextSize = 12
_S.ninjaFartsLimit.Parent = _S.ninjaFartsButton

_S.ninjaStatus = makeLabel(_S.sideList, "Spin + " .. _S.NINJA_FARTS .. " farts, then aim for up to " .. _S.NINJA_ARM_TIMEOUT .. "s.", UDim2.new(1, 0, 0, 42), UDim2.new(), 11)
_S.ninjaStatus.TextWrapped = true
_S.ninjaStatus.TextYAlignment = Enum.TextYAlignment.Top
bind(_S.ninjaStatus, "TextColor3", "Muted")

_S.NINJA_FARTS_SLIDER_MAX = 500
_S.ninjaFartsLabel = makeLabel(_S.sideList, "EXACT: " .. _S.NINJA_FARTS, UDim2.new(1, 0, 0, 16), UDim2.new(), 11)
_S.ninjaFartsLabel.LayoutOrder = 6
bind(_S.ninjaFartsLabel, "TextColor3", "Muted")

_S.ninjaFartsSliderRow = Instance.new("Frame")
_S.ninjaFartsSliderRow.Size = UDim2.new(1, 0, 0, 20)
_S.ninjaFartsSliderRow.BackgroundTransparency = 1
_S.ninjaFartsSliderRow.LayoutOrder = 7
_S.ninjaFartsSliderRow.Parent = _S.sideList

_S.ninjaFartsBox = makeTextBox(_S.sideList, tostring(_S.NINJA_FARTS), "TYPE AN EXACT AMOUNT", UDim2.new(1, 0, 0, 24), UDim2.new())
_S.ninjaFartsBox.LayoutOrder = 8

_S.ninjaFartsSlider = nil

function _S.setNinjaFarts(value, moveSlider, movePreset)
    value = math.max(0, math.floor(value + 0.5))
    _S.NINJA_FARTS = value
    _S.ninjaFartsLabel.Text = "EXACT: " .. _S.NINJA_FARTS
    _S.ninjaFartsBox.Text = tostring(_S.NINJA_FARTS)
    _S.ninjaFartsButton.Text = "NINJA FARTS: " .. _S.NINJA_FARTS
    if moveSlider and _S.ninjaFartsSlider then
        _S.ninjaFartsSlider.SetPercent(math.clamp(value / _S.NINJA_FARTS_SLIDER_MAX, 0, 1))
    end
    if movePreset then
        for i, preset in ipairs(_S.NINJA_FART_PRESETS) do
            if preset == value then
                _S.ninjaFartPresetIndex = i
                break
            end
        end
    end
    _S.ninjaStatus.Text = "Preparation burst set to " .. _S.NINJA_FARTS .. " farts."
end

_S.ninjaFartsSlider = makeSlider(
    _S.ninjaFartsSliderRow,
    7,
    math.clamp(_S.NINJA_FARTS / _S.NINJA_FARTS_SLIDER_MAX, 0, 1),
    function(percent)
        _S.setNinjaFarts(percent * _S.NINJA_FARTS_SLIDER_MAX, false, true)
    end
)

_S.ninjaFartsBox.FocusLost:Connect(function()
    local typed = tonumber(_S.ninjaFartsBox.Text)
    if typed and typed == typed and typed ~= math.huge and typed ~= -math.huge then
        _S.setNinjaFarts(typed, true, true)
    else
        _S.ninjaFartsBox.Text = tostring(_S.NINJA_FARTS)
    end
end)

_S.NINJA_LANDING_FARTS_SLIDER_MAX = 500
_S.landingFartsLabel = makeLabel(_S.sideList, "POST-TP FARTS: " .. _S.NINJA_LANDING_FARTS, UDim2.new(1, 0, 0, 18), UDim2.new(), 11)
_S.landingFartsLabel.LayoutOrder = 9
bind(_S.landingFartsLabel, "TextColor3", "Muted")

_S.landingFartsSliderRow = Instance.new("Frame")
_S.landingFartsSliderRow.Size = UDim2.new(1, 0, 0, 20)
_S.landingFartsSliderRow.BackgroundTransparency = 1
_S.landingFartsSliderRow.LayoutOrder = 10
_S.landingFartsSliderRow.Parent = _S.sideList

_S.landingFartsBox = makeTextBox(_S.sideList, tostring(_S.NINJA_LANDING_FARTS), "TYPE POST-TP FART AMOUNT", UDim2.new(1, 0, 0, 24), UDim2.new())
_S.landingFartsBox.LayoutOrder = 11

_S.landingFartsSlider = nil
function _S.setNinjaLandingFarts(value, moveSlider)
    value = math.max(0, math.floor(value + 0.5))
    _S.NINJA_LANDING_FARTS = value
    _S.landingFartsLabel.Text = "POST-TP FARTS: " .. _S.NINJA_LANDING_FARTS
    _S.landingFartsBox.Text = tostring(_S.NINJA_LANDING_FARTS)
    if moveSlider and _S.landingFartsSlider then
        _S.landingFartsSlider.SetPercent(math.clamp(value / _S.NINJA_LANDING_FARTS_SLIDER_MAX, 0, 1))
    end
    _S.ninjaStatus.Text = "Post-teleport burst set to " .. _S.NINJA_LANDING_FARTS .. " farts."
end

_S.landingFartsSlider = makeSlider(
    _S.landingFartsSliderRow,
    7,
    math.clamp(_S.NINJA_LANDING_FARTS / _S.NINJA_LANDING_FARTS_SLIDER_MAX, 0, 1),
    function(percent)
        _S.setNinjaLandingFarts(percent * _S.NINJA_LANDING_FARTS_SLIDER_MAX, false)
    end
)

_S.landingFartsBox.FocusLost:Connect(function()
    local typed = tonumber(_S.landingFartsBox.Text)
    if typed and typed == typed and typed ~= math.huge and typed ~= -math.huge then
        _S.setNinjaLandingFarts(typed, true)
    else
        _S.landingFartsBox.Text = tostring(_S.NINJA_LANDING_FARTS)
    end
end)

_S.ninjaSection, _S.ninjaContents = _S.makeToolSection("NINJA TELEPORT", 1, "Create a \"smoke\" cover and teleport.")
_S.ninjaLabel:Destroy()
for _, object in ipairs({
    _S.ninjaRow, ninjaKeyButton, _S.ninjaModeButton, _S.ninjaFartsButton,
    _S.ninjaFartsLabel, _S.ninjaFartsSliderRow, _S.ninjaFartsBox, _S.ninjaStatus,
    _S.landingFartsLabel, _S.landingFartsSliderRow, _S.landingFartsBox
}) do
    object.Parent = _S.ninjaContents
end
_S.ninjaRow.LayoutOrder = 1
ninjaKeyButton.LayoutOrder = 2
_S.ninjaModeButton.LayoutOrder = 3
_S.ninjaFartsButton.LayoutOrder = 4
_S.ninjaFartsLabel.LayoutOrder = 5
_S.ninjaFartsSliderRow.LayoutOrder = 6
_S.ninjaFartsBox.LayoutOrder = 7
_S.landingFartsLabel.LayoutOrder = 8
_S.landingFartsSliderRow.LayoutOrder = 9
_S.landingFartsBox.LayoutOrder = 10
_S.ninjaStatus.LayoutOrder = 11

_S.patternSection, _S.patternContents = _S.makeToolSection("FART PATTERN", 2, "Record or type a timed sequence of farts and waits.")
_S.patternToolPanel.LayoutOrder = 1
_S.patternToolPanel.Parent = _S.patternContents

_S.getCharacterParts = nil

_S.orbitSection, _S.orbitContents = _S.makeToolSection("FART ORBIT", 3, "Press R, then click a player to circle them.")
_S.orbitStatus = makeLabel(_S.orbitContents, "Ready.", UDim2.new(1, 0, 0, 42), UDim2.new(), 11)
_S.orbitStatus.LayoutOrder = 1
_S.orbitStatus.TextWrapped = true
_S.orbitStatus.TextYAlignment = Enum.TextYAlignment.Top
bind(_S.orbitStatus, "TextColor3", "Muted")

_S.orbitSpeedPresets = {
    {name = "SLOW", rotations = 0.5},
    {name = "NORMAL", rotations = 1.0},
    {name = "FAST", rotations = 2.0},
    {name = "VERY FAST", rotations = 3.0},
}
_S.orbitSpeedIndex = 2
_S.orbitSpeedButton = makeButton(_S.orbitContents, "SPEED: NORMAL", UDim2.new(1, 0, 0, 34), UDim2.new(), "Button")
_S.orbitSpeedButton.LayoutOrder = 2
_S.orbitSpeedButton.TextSize = 11

_S.ORBIT_FART_RATE_MIN = 1
_S.ORBIT_FART_RATE_MAX = 24
_S.orbitFartsPerSecond = 16
_S.orbitRatePanel = Instance.new("Frame")
_S.orbitRatePanel.Name = "OrbitFartRate"
_S.orbitRatePanel.Size = UDim2.new(1, 0, 0, 74)
_S.orbitRatePanel.BackgroundTransparency = 1
_S.orbitRatePanel.LayoutOrder = 3
_S.orbitRatePanel.Parent = _S.orbitContents
_S.orbitRateLabel = makeLabel(_S.orbitRatePanel, "FART RATE: 16.0 / SEC", UDim2.new(1, 0, 0, 16), UDim2.new(), 11)
_S.orbitRateLabel.Font = Enum.Font.GothamBold
bind(_S.orbitRateLabel, "TextColor3", "Muted")
_S.orbitRateSlider = makeSlider(
    _S.orbitRatePanel,
    27,
    (_S.orbitFartsPerSecond - _S.ORBIT_FART_RATE_MIN) / (_S.ORBIT_FART_RATE_MAX - _S.ORBIT_FART_RATE_MIN),
    function(percent)
        _S.orbitFartsPerSecond = math.floor((_S.ORBIT_FART_RATE_MIN + percent * (_S.ORBIT_FART_RATE_MAX - _S.ORBIT_FART_RATE_MIN)) * 2 + 0.5) / 2
        _S.orbitRateLabel.Text = string.format("FART RATE: %.1f / SEC", _S.orbitFartsPerSecond)
        _S.orbitRateBox.Text = tostring(_S.orbitFartsPerSecond)
    end
)
_S.orbitRateBox = makeTextBox(_S.orbitRatePanel, tostring(_S.orbitFartsPerSecond), "EXACT FARTS PER SECOND (1-24)", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 47))
_S.orbitRateBox.TextSize = 11
_S.orbitRateBox.FocusLost:Connect(function()
    local typed = tonumber(_S.orbitRateBox.Text)
    if typed and typed == typed and typed ~= math.huge and typed ~= -math.huge
        and typed >= _S.ORBIT_FART_RATE_MIN and typed <= _S.ORBIT_FART_RATE_MAX then
        _S.orbitFartsPerSecond = math.floor(typed * 2 + 0.5) / 2
        _S.orbitRateBox.Text = tostring(_S.orbitFartsPerSecond)
        _S.orbitRateLabel.Text = string.format("FART RATE: %.1f / SEC", _S.orbitFartsPerSecond)
        _S.orbitRateSlider.SetPercent((_S.orbitFartsPerSecond - _S.ORBIT_FART_RATE_MIN) / (_S.ORBIT_FART_RATE_MAX - _S.ORBIT_FART_RATE_MIN))
    else
        _S.orbitRateBox.Text = tostring(_S.orbitFartsPerSecond)
    end
end)

_S.orbitStopButton = makeButton(_S.orbitContents, "STOP ORBIT", UDim2.new(1, 0, 0, 34), UDim2.new(), "Button")
_S.orbitStopButton.LayoutOrder = 4
_S.orbitStopButton.TextSize = 11

orbitKeyButton = makeButton(_S.orbitContents, "", UDim2.new(1, 0, 0, 34), UDim2.new(), "Button")
orbitKeyButton.LayoutOrder = 5
orbitKeyButton.TextSize = 11
orbitKeyButton.MouseButton1Click:Connect(function()
    listeningFor = (listeningFor ~= "orbit") and "orbit" or nil
    refreshKeyButtons()
end)
refreshKeyButtons()

_S.orbitSelecting = false
_S.orbitTarget = nil
_S.orbitAngle = 0
_S.orbitFartClock = 0
_S.orbitReturnCFrame = nil
_S.orbitRadius = 5
_S.orbitHeight = 2.0
_S.orbitCenterY = nil
_S.orbitFloor = nil
_S.orbitHumanoid = nil
_S.orbitPreviousAutoRotate = nil
_S.orbitMouse = player:GetMouse()
_S.orbitHoverScanToken = 0
_S.orbitHoverTargetModel = nil

_S.orbitHoverBillboard = Instance.new("BillboardGui")
_S.orbitHoverBillboard.Name = "OrbitSelectionArrow"
_S.orbitHoverBillboard.Size = UDim2.fromOffset(34, 28)
_S.orbitHoverBillboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
_S.orbitHoverBillboard.AlwaysOnTop = true
_S.orbitHoverBillboard.LightInfluence = 0
_S.orbitHoverBillboard.MaxDistance = 250
_S.orbitHoverBillboard.Enabled = false
_S.orbitHoverBillboard.Parent = player:WaitForChild("PlayerGui")

_S.orbitHoverArrowLabel = Instance.new("TextLabel")
_S.orbitHoverArrowLabel.Name = "Arrow"
_S.orbitHoverArrowLabel.Size = UDim2.fromScale(1, 1)
_S.orbitHoverArrowLabel.BackgroundTransparency = 1
_S.orbitHoverArrowLabel.BorderSizePixel = 0
_S.orbitHoverArrowLabel.Text = "▼"
_S.orbitHoverArrowLabel.TextScaled = true
_S.orbitHoverArrowLabel.Font = Enum.Font.GothamBlack
_S.orbitHoverArrowLabel.TextStrokeTransparency = 0.25
_S.orbitHoverArrowLabel.TextStrokeColor3 = rgb(20, 20, 24)
_S.orbitHoverArrowLabel.Parent = _S.orbitHoverBillboard
bind(_S.orbitHoverArrowLabel, "TextColor3", "Accent")

function _S.clearOrbitHoverArrow()
    _S.orbitHoverTargetModel = nil
    _S.orbitHoverBillboard.Adornee = nil
    _S.orbitHoverBillboard.Enabled = false
end

function _S.updateOrbitHoverArrow()
    if not _S.orbitSelecting or unloaded then
        _S.clearOrbitHoverArrow()
        return
    end
    local targetPart = _S.orbitMouse.Target
    local model = targetPart and targetPart:FindFirstAncestorOfClass("Model")
    local targetPlayer = model and Players:GetPlayerFromCharacter(model)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local head = model and (model:FindFirstChild("Head") or root)
    if targetPlayer and targetPlayer ~= player and humanoid and humanoid.Health > 0 and root and head then
        if _S.orbitHoverTargetModel ~= model or _S.orbitHoverBillboard.Adornee ~= head then
            _S.orbitHoverTargetModel = model
            _S.orbitHoverBillboard.Adornee = head
            _S.orbitHoverBillboard.Enabled = true
        end
    else
        _S.clearOrbitHoverArrow()
    end
end

function _S.startOrbitHoverScan()
    _S.orbitHoverScanToken += 1
    local token = _S.orbitHoverScanToken
    task.spawn(function()
        while not unloaded and _S.orbitSelecting and token == _S.orbitHoverScanToken do
            _S.updateOrbitHoverArrow()
            task.wait(0.1)
        end
        if token == _S.orbitHoverScanToken then
            _S.clearOrbitHoverArrow()
        end
    end)
end

function _S.stopOrbitHoverScan()
    _S.orbitHoverScanToken += 1
    _S.clearOrbitHoverArrow()
end

function _S.updateOrbitFloor(orbitPosition, localRoot, localHumanoid)
    if not _S.orbitFloor or not _S.orbitFloor.Parent then
        local floor = Instance.new("Part")
        floor.Name = "FartOrbit_ClientFloor"
        floor.Size = Vector3.new(9, 1, 9)
        floor.Anchored = true
        floor.Transparency = 1
        floor.LocalTransparencyModifier = 1
        floor.CanCollide = true
        floor.CanTouch = false
        floor.CanQuery = false
        floor.CastShadow = false
        floor.Parent = workspace
        _S.orbitFloor = floor
    end
    local floorY = orbitPosition.Y - localHumanoid.HipHeight - (localRoot.Size.Y / 2) - 0.5
    _S.orbitFloor.CFrame = CFrame.new(orbitPosition.X, floorY, orbitPosition.Z)
end

function _S.destroyOrbitFloor()
    if _S.orbitFloor then
        _S.orbitFloor:Destroy()
        _S.orbitFloor = nil
    end
end

function _S.stopFartOrbit(message)
    _S.orbitSelecting = false
    _S.stopOrbitHoverScan()
    _S.orbitTarget = nil
    _S.orbitFartClock = 0
    _S.orbitCenterY = nil
    _S.destroyOrbitFloor()
    if _S.orbitHumanoid and _S.orbitHumanoid.Parent and _S.orbitPreviousAutoRotate ~= nil then
        _S.orbitHumanoid.AutoRotate = _S.orbitPreviousAutoRotate
    end
    _S.orbitHumanoid = nil
    _S.orbitPreviousAutoRotate = nil
    if _S.orbitReturnCFrame then
        local _, localRoot = _S.getCharacterParts()
        if localRoot then
            localRoot.CFrame = _S.orbitReturnCFrame
            localRoot.AssemblyLinearVelocity = Vector3.zero
            localRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end
    _S.orbitReturnCFrame = nil
    _S.orbitStatus.Text = message or ("Orbit stopped. Press " .. orbitKey.Name .. " to select another player.")
end

_S.orbitSpeedButton.MouseButton1Click:Connect(function()
    _S.orbitSpeedIndex = (_S.orbitSpeedIndex % #_S.orbitSpeedPresets) + 1
    local preset = _S.orbitSpeedPresets[_S.orbitSpeedIndex]
    _S.orbitSpeedButton.Text = "SPEED: " .. preset.name
    _S.orbitStatus.Text = string.format("%s — %.1f rotations/sec; %.1f farts/sec", preset.name, preset.rotations, _S.orbitFartsPerSecond)
end)

_S.orbitStopButton.MouseButton1Click:Connect(function()
    _S.stopFartOrbit()
end)

function _S.selectOrbitTarget()
    local targetPart = _S.orbitMouse.Target
    local model = targetPart and targetPart:FindFirstAncestorOfClass("Model")
    local targetPlayer = model and Players:GetPlayerFromCharacter(model)
    if not targetPlayer or targetPlayer == player then
        _S.orbitStatus.Text = "That isn't another player. Press " .. orbitKey.Name .. " and click a player's character."
        return
    end
    local targetRoot = model:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
        _S.orbitStatus.Text = "That player has no living character to orbit."
        return
    end
    _S.orbitSelecting = false
    _S.stopOrbitHoverScan()
    local _, localRoot, localHumanoid = _S.getCharacterParts()
    _S.orbitReturnCFrame = localRoot and localRoot.CFrame or nil
    _S.orbitTarget = targetPlayer
    _S.orbitAngle = 0
    _S.orbitFartClock = 0
    _S.orbitCenterY = targetRoot.Position.Y
    _S.orbitHumanoid = localHumanoid
    _S.orbitPreviousAutoRotate = localHumanoid and localHumanoid.AutoRotate or nil
    if localHumanoid then
        localHumanoid.AutoRotate = false
    end
    _S.orbitStatus.Text = "Orbiting " .. targetPlayer.DisplayName .. ". Press STOP ORBIT to end."
end

keep(UIS.InputBegan:Connect(function(input, gameProcessed)
    if unloaded or gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and _S.orbitSelecting then
        _S.selectOrbitTarget()
        return
    end
    if input.KeyCode == orbitKey then
        if _S.orbitTarget then
            _S.stopFartOrbit("Orbit stopped. Press " .. orbitKey.Name .. ", then click another player.")
        elseif _S.orbitSelecting then
            _S.orbitSelecting = false
            _S.stopOrbitHoverScan()
            _S.orbitStatus.Text = "Selection cancelled. Press " .. orbitKey.Name .. " to select a player."
        else
            _S.orbitSelecting = true
            _S.startOrbitHoverScan()
            _S.orbitStatus.Text = "SELECTING — click another player's character. Press " .. orbitKey.Name .. " again to cancel."
        end
    end
end))

keep(Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == _S.orbitTarget then
        _S.stopFartOrbit("Orbit ended — the selected player left the server.")
    end
end))

keep(RunService.Heartbeat:Connect(function(dt)
    if not _S.orbitTarget then return end
    local targetCharacter = _S.orbitTarget.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    local _, localRoot, localHumanoid = _S.getCharacterParts()
    if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 or not localRoot or not localHumanoid then
        _S.stopFartOrbit("Orbit ended — a character is unavailable.")
        return
    end
    local preset = _S.orbitSpeedPresets[_S.orbitSpeedIndex]
    _S.orbitAngle = (_S.orbitAngle + dt * preset.rotations * math.pi * 2) % (math.pi * 2)
    local targetY = targetRoot.Position.Y
    if _S.orbitCenterY == nil then
        _S.orbitCenterY = targetY
    else
        local smoothing = 1 - math.exp(-dt * 9)
        _S.orbitCenterY += (targetY - _S.orbitCenterY) * smoothing
    end
    local center = Vector3.new(targetRoot.Position.X, _S.orbitCenterY, targetRoot.Position.Z)
    local offset = Vector3.new(math.cos(_S.orbitAngle) * _S.orbitRadius, _S.orbitHeight, math.sin(_S.orbitAngle) * _S.orbitRadius)
    local orbitPosition = center + offset
    _S.updateOrbitFloor(orbitPosition, localRoot, localHumanoid)
    local facingAway = Vector3.new(math.cos(_S.orbitAngle), 0, math.sin(_S.orbitAngle))
    localRoot.CFrame = CFrame.lookAt(orbitPosition, orbitPosition + facingAway)
    localRoot.AssemblyLinearVelocity = Vector3.zero
    localRoot.AssemblyAngularVelocity = Vector3.zero
    local fartInterval = 1 / math.max(_S.orbitFartsPerSecond, 1)
    _S.orbitFartClock += dt
    local burstCount = 0
    while _S.orbitFartClock >= fartInterval and burstCount < 3 do
        _S.orbitFartClock -= fartInterval
        fart()
        burstCount += 1
    end
    if burstCount >= 3 and _S.orbitFartClock >= fartInterval then
        _S.orbitFartClock %= fartInterval
    end
end))

function _S.refreshNinjaModeButton()
    local modeLabel = (_S.ninjaMode == "CAMERA LOCK") and "CAM LOCK" or "FREECAM"
    _S.ninjaModeButton.Text = "TP MODE: " .. modeLabel
end

_S.refreshNinjaModeButton()

function _S.refreshNinjaButton()
    if _S.ninjaState == "spinning" then
        _S.ninjaButton.Text = "SPINNING..."
    elseif _S.ninjaState == "armed" then
        _S.ninjaButton.Text = "CLICK TO TP!"
    else
        _S.ninjaButton.Text = "NINJA TELEPORT"
    end
end

function _S.destroyNinjaPlatform()
    if _S.ninjaLocalPlatform then
        _S.ninjaLocalPlatform:Destroy()
        _S.ninjaLocalPlatform = nil
    end
end

function _S.restoreNinjaMovement(session)
    if not session or not session.humanoid or not session.humanoid.Parent then return end
    local humanoid = session.humanoid
    humanoid.WalkSpeed = session.walkSpeed
    humanoid.JumpPower = session.jumpPower
    humanoid.JumpHeight = session.jumpHeight
    humanoid.AutoRotate = session.autoRotate
end

function _S.restoreNinjaCamera()
    local session = _S.ninjaCameraSession
    if not session then return end
    local currentCamera = workspace.CurrentCamera or session.camera
    if currentCamera then
        currentCamera.CameraType = session.cameraType
        local subject = session.cameraSubject
        if not subject or not subject.Parent then
            local character = player.Character
            subject = character and character:FindFirstChildOfClass("Humanoid") or nil
        end
        if subject then
            currentCamera.CameraSubject = subject
        end
        currentCamera.FieldOfView = session.fieldOfView
        if session.cameraType == Enum.CameraType.Scriptable then
            currentCamera.CFrame = session.cameraCFrame
            currentCamera.Focus = session.cameraFocus
        end
    end
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = true
    _S.restoreNinjaMovement(session)
    _S.destroyNinjaPlatform()
    _S.ninjaCameraSession = nil
end

function _S.cancelNinja(message, restoreHiddenPosition)
    _S.ninjaToken += 1
    _S.ninjaState = "idle"
    if restoreHiddenPosition ~= false and _S.ninjaHiddenReturnCFrame then
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = _S.ninjaHiddenReturnCFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
    _S.ninjaHiddenReturnCFrame = nil
    _S.restoreNinjaCamera()
    _S.refreshNinjaButton()
    _S.ninjaStatus.Text = message or "Cancelled."
end

_S.getCharacterParts = function()
    local character = player.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return nil end
    return character, hrp, humanoid
end

function _S.beginNinjaAimMode(hrp, humanoid)
    local currentCamera = workspace.CurrentCamera
    if not currentCamera then return false end
    local cameraCFrame = currentCamera.CFrame
    local pitch, yaw = cameraCFrame:ToOrientation()
    _S.ninjaCameraSession = {
        camera = currentCamera,
        cameraType = currentCamera.CameraType,
        cameraSubject = currentCamera.CameraSubject,
        cameraCFrame = cameraCFrame,
        cameraFocus = currentCamera.Focus,
        fieldOfView = currentCamera.FieldOfView,
        mode = _S.ninjaMode,
        position = cameraCFrame.Position,
        pitch = pitch,
        yaw = yaw,
        looking = false,
        humanoid = humanoid,
        walkSpeed = humanoid.WalkSpeed,
        jumpPower = humanoid.JumpPower,
        jumpHeight = humanoid.JumpHeight,
        autoRotate = humanoid.AutoRotate,
    }
    _S.ninjaHiddenReturnCFrame = hrp.CFrame
    currentCamera.CameraType = Enum.CameraType.Scriptable
    currentCamera.CFrame = cameraCFrame
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = true
    local hiddenY = hrp.Position.Y - _S.NINJA_TP_DROP_STUDS
    local destroyHeight = nil
    pcall(function() destroyHeight = workspace.FallenPartsDestroyHeight end)
    if type(destroyHeight) == "number" then
        hiddenY = math.max(hiddenY, destroyHeight + 60)
    end
    local hiddenPosition = Vector3.new(hrp.Position.X, hiddenY, hrp.Position.Z)
    local platformTop = hiddenY - humanoid.HipHeight - (hrp.Size.Y / 2)
    local platform = Instance.new("Part")
    platform.Name = "FartSpam_NinjaLocalStand"
    platform.Anchored = true
    platform.Size = Vector3.new(14, 1, 14)
    platform.CFrame = CFrame.new(hrp.Position.X, platformTop - 0.5, hrp.Position.Z)
    platform.Transparency = 1
    platform.CanCollide = true
    platform.CanTouch = false
    platform.CanQuery = false
    platform.Parent = workspace
    _S.ninjaLocalPlatform = platform
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    humanoid.AutoRotate = false
    hrp.CFrame = CFrame.new(hiddenPosition) * (hrp.CFrame - hrp.Position)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    return true
end

keep(RunService.RenderStepped:Connect(function(deltaTime)
    local session = _S.ninjaCameraSession
    ninjaCrosshair.Visible = session ~= nil and session.mode == "FREECAM" and session.looking == true
    if not session or session.mode ~= "FREECAM" then return end
    local currentCamera = workspace.CurrentCamera
    if not currentCamera then return end
    if session.looking then
        local mouseDelta = UIS:GetMouseDelta()
        session.yaw -= mouseDelta.X * _S.NINJA_FREECAM_SENSITIVITY
        session.pitch = math.clamp(
            session.pitch - mouseDelta.Y * _S.NINJA_FREECAM_SENSITIVITY,
            math.rad(-85), math.rad(85)
        )
    else
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    end
    local rotation = CFrame.fromOrientation(session.pitch, session.yaw, 0)
    local moveX, moveY, moveZ = 0, 0, 0
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveX += 1 end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveX -= 1 end
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveZ -= 1 end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveZ += 1 end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then moveY += 1 end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveY -= 1 end
    local horizontal = rotation:VectorToWorldSpace(Vector3.new(moveX, 0, moveZ))
    local movement = horizontal + Vector3.new(0, moveY, 0)
    if movement.Magnitude > 0 then
        local speed = _S.NINJA_FREECAM_SPEED
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
            speed *= _S.NINJA_FREECAM_BOOST
        end
        session.position += movement.Unit * speed * deltaTime
    end
    currentCamera.CameraType = Enum.CameraType.Scriptable
    currentCamera.CFrame = CFrame.new(session.position) * rotation
    currentCamera.Focus = CFrame.new(session.position + currentCamera.CFrame.LookVector * 32)
end))

function _S.startNinja()
    local _, hrp, humanoid = _S.getCharacterParts()
    if not hrp then
        _S.ninjaStatus.Text = "No living character found."
        return
    end
    _S.ninjaToken += 1
    local token = _S.ninjaToken
    _S.ninjaState = "spinning"
    _S.refreshNinjaButton()
    _S.ninjaStatus.Text = "Spinning..."
    task.spawn(function()
        local previousAutoRotate = humanoid.AutoRotate
        humanoid.AutoRotate = false
        local startTime = os.clock()
        local fired = 0
        local lastAlpha = 0
        local completed = false
        while not unloaded and token == _S.ninjaToken do
            local elapsed = os.clock() - startTime
            local fartAlpha = math.min(elapsed / _S.NINJA_FART_SPAN, 1)
            local due = math.min(_S.NINJA_FARTS, math.floor(fartAlpha * _S.NINJA_FARTS) + 1)
            while fired < due do
                fart()
                fired += 1
            end
            local spinElapsed = math.max(elapsed - _S.NINJA_FART_LEAD, 0)
            local alpha = math.min(spinElapsed / _S.NINJA_DURATION, 1)
            if hrp.Parent and elapsed >= _S.NINJA_FART_LEAD then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, (alpha - lastAlpha) * _S.NINJA_TURNS * math.pi * 2, 0)
            end
            lastAlpha = alpha
            if alpha >= 1 then
                completed = true
                break
            end
            task.wait()
        end
        if humanoid.Parent then
            humanoid.AutoRotate = previousAutoRotate
        end
        if not completed or unloaded or token ~= _S.ninjaToken then return end
        if not hrp.Parent or not humanoid.Parent then
            _S.cancelNinja("Character changed before aiming.")
            return
        end
        if not _S.beginNinjaAimMode(hrp, humanoid) then
            _S.cancelNinja("Camera unavailable - teleport cancelled.")
            return
        end
        _S.ninjaState = "armed"
        _S.refreshNinjaButton()
        if _S.ninjaMode == "CAMERA LOCK" then
            _S.ninjaStatus.Text = "Hidden below your starting spot on a temporary local stand. Click a visible floor/wall to teleport there."
        elseif _S.ninjaMode == "FREECAM" then
            _S.ninjaStatus.Text = "Hidden on a temporary local stand. WASD move, Space/Ctrl up/down, Shift = faster, hold RMB to look, left-click to TP."
        end
        task.delay(_S.NINJA_ARM_TIMEOUT, function()
            if _S.ninjaState == "armed" and token == _S.ninjaToken then
                _S.cancelNinja("Aim timed out - returned to starting position.")
            end
        end)
    end)
end

function _S.fartBurst(count, duration, sharedStartTime)
    task.spawn(function()
        local startTime = sharedStartTime or os.clock()
        local fired = 0
        while fired < count and not unloaded do
            local alpha = math.min((os.clock() - startTime) / duration, 1)
            local due = math.min(count, math.floor(alpha * count) + 1)
            while fired < due do
                fart()
                fired += 1
            end
            if fired < count then
                task.wait()
            end
        end
    end)
end

function _S.teleportToScreenPoint(x, y)
    local character, hrp, humanoid = _S.getCharacterParts()
    if not hrp then
        _S.cancelNinja("No living character found.")
        return
    end
    local currentCamera = workspace.CurrentCamera
    if not currentCamera then
        _S.ninjaStatus.Text = "Camera unavailable - aim again."
        return
    end
    local ray
    local activeSession = _S.ninjaCameraSession
    if activeSession and activeSession.mode == "FREECAM" and activeSession.looking then
        local viewport = currentCamera.ViewportSize
        ray = currentCamera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
    else
        ray = currentCamera:ScreenPointToRay(x, y)
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignoredCharacters = {}
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer.Character then
            table.insert(ignoredCharacters, otherPlayer.Character)
        end
    end
    params.FilterDescendantsInstances = ignoredCharacters
    local result = workspace:Raycast(ray.Origin, ray.Direction * _S.NINJA_RAY_DISTANCE, params)
    if not result then
        _S.ninjaStatus.Text = "No surface there. Aim at a floor or wall and click again."
        return
    end
    local offset = Vector3.new(0, humanoid.HipHeight + hrp.Size.Y / 2, 0)
    if math.abs(result.Normal.Y) < 0.5 then
        offset += result.Normal.Unit * 2
    end
    local destination = result.Position + offset
    local rotation = hrp.CFrame - hrp.CFrame.Position
    hrp.CFrame = CFrame.new(destination) * rotation
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    _S.ninjaHiddenReturnCFrame = nil
    _S.cancelNinja("Teleported to the selected surface!", false)
    if _S.ninjaLandingFart then
        task.spawn(function()
            if unloaded or not hrp.Parent or not humanoid.Parent then return end
            local previousAutoRotate = humanoid.AutoRotate
            humanoid.AutoRotate = false
            local spinStart = os.clock()
            local startRotation = hrp.CFrame - hrp.CFrame.Position
            local fired = 0
            while not unloaded and hrp.Parent and humanoid.Parent do
                local alpha = math.min((os.clock() - spinStart) / _S.NINJA_POST_TP_DURATION, 1)
                local currentPosition = hrp.Position
                local fullTurn = alpha * _S.NINJA_POST_TP_TURNS * math.pi * 2
                hrp.CFrame = CFrame.new(currentPosition) * startRotation * CFrame.Angles(0, fullTurn, 0)
                local due = math.min(_S.NINJA_LANDING_FARTS, math.floor(alpha * _S.NINJA_LANDING_FARTS) + 1)
                while fired < due do
                    fart()
                    fired += 1
                end
                if alpha >= 1 then break end
                task.wait()
            end
            if humanoid.Parent then
                humanoid.AutoRotate = previousAutoRotate
            end
        end)
    end
end

triggerNinja = function()
    if unloaded then return end
    if _S.ninjaState == "idle" then
        _S.startNinja()
    elseif _S.ninjaState == "armed" then
        _S.cancelNinja("Cancelled - returned to starting position.")
    end
end

_S.ninjaButton.MouseButton1Click:Connect(triggerNinja)

_S.ninjaFartButton.MouseButton1Click:Connect(function()
    _S.ninjaLandingFart = not _S.ninjaLandingFart
    _S.refreshNinjaFartButton()
end)

_S.ninjaFartsButton.MouseButton1Click:Connect(function()
    _S.ninjaFartPresetIndex = (_S.ninjaFartPresetIndex % #_S.NINJA_FART_PRESETS) + 1
    _S.setNinjaFarts(_S.NINJA_FART_PRESETS[_S.ninjaFartPresetIndex], true, false)
end)

ninjaKeyButton.MouseButton1Click:Connect(function()
    listeningFor = (listeningFor ~= "ninja") and "ninja" or nil
    refreshKeyButtons()
end)

_S.ninjaModeButton.MouseButton1Click:Connect(function()
    if _S.ninjaState ~= "idle" then
        _S.ninjaStatus.Text = "Cancel/finish the current teleport before changing mode."
        return
    end
    _S.ninjaModeIndex = (_S.ninjaModeIndex % #_S.NINJA_MODES) + 1
    _S.ninjaMode = _S.NINJA_MODES[_S.ninjaModeIndex]
    _S.refreshNinjaModeButton()
end)

keep(UIS.InputBegan:Connect(function(input, gameProcessed)
    if _S.ninjaCameraSession and _S.ninjaCameraSession.mode == "FREECAM"
        and input.UserInputType == Enum.UserInputType.MouseButton2 then
        _S.ninjaCameraSession.looking = true
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled = false
    end
    if unloaded or _S.ninjaState ~= "armed" or gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        _S.teleportToScreenPoint(input.Position.X, input.Position.Y)
    end
end))

keep(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and _S.ninjaCameraSession then
        _S.ninjaCameraSession.looking = false
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    end
end))

refreshKeyButtons()
refreshSideMenu()

--==================================================
-- TOOL: FACE FART
--==================================================

_S.FACE_FARTS_RATE_PRESETS = {50, 150, 250}
_S.FACE_FARTS_RATE_INDEX = 1
_S.FACE_FARTS_RATE_SLIDER_MAX = 500
_S.FACE_FARTS_RATE_DEFAULT = 50
_S.FACE_DISTANCE = 1.8
_S.FACE_SEAT_TILT_DEGREES = -10
_S.FACE_INITIAL_DELAY = 0.3
_S.faceFartsPerSecond = _S.FACE_FARTS_RATE_DEFAULT
_S.faceDuration = 1.0
_S.faceState = "idle"
_S.faceTargetPlayer = nil
_S.faceToken = 0
_S.faceReturnCFrame = nil
_S.faceHumanoid = nil
_S.facePreviousAutoRotate = nil
_S.facePreviousPlatformStand = nil
_S.faceHeartbeatConn = nil
_S.faceSeat = nil
_S.faceFloor = nil
_S.faceHoverScanToken = 0
_S.faceHoverTargetModel = nil
_S.faceMouse = player:GetMouse()

_S.faceHoverBillboard = Instance.new("BillboardGui")
_S.faceHoverBillboard.Name = "FaceFartSelectionArrow"
_S.faceHoverBillboard.Size = UDim2.fromOffset(34, 28)
_S.faceHoverBillboard.StudsOffsetWorldSpace = Vector3.new(0, 4.1, 0)
_S.faceHoverBillboard.AlwaysOnTop = true
_S.faceHoverBillboard.LightInfluence = 0
_S.faceHoverBillboard.MaxDistance = 250
_S.faceHoverBillboard.Enabled = false
_S.faceHoverBillboard.Parent = player:WaitForChild("PlayerGui")

_S.faceHoverArrowLabel = Instance.new("TextLabel")
_S.faceHoverArrowLabel.Name = "Arrow"
_S.faceHoverArrowLabel.Size = UDim2.fromScale(1, 1)
_S.faceHoverArrowLabel.BackgroundTransparency = 1
_S.faceHoverArrowLabel.BorderSizePixel = 0
_S.faceHoverArrowLabel.Text = "▼"
_S.faceHoverArrowLabel.TextScaled = true
_S.faceHoverArrowLabel.Font = Enum.Font.GothamBlack
_S.faceHoverArrowLabel.TextStrokeTransparency = 0.25
_S.faceHoverArrowLabel.TextStrokeColor3 = rgb(20, 20, 24)
_S.faceHoverArrowLabel.Parent = _S.faceHoverBillboard
bind(_S.faceHoverArrowLabel, "TextColor3", "Accent")

function _S.clearFaceHoverArrow()
    _S.faceHoverTargetModel = nil
    _S.faceHoverBillboard.Adornee = nil
    _S.faceHoverBillboard.Enabled = false
end

function _S.updateFaceHoverArrow()
    if _S.faceState ~= "selecting" or unloaded then
        _S.clearFaceHoverArrow()
        return
    end
    local targetPart = _S.faceMouse.Target
    local model = targetPart and targetPart:FindFirstAncestorOfClass("Model")
    local targetPlayer = model and Players:GetPlayerFromCharacter(model)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local head = model and (model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart"))
    if targetPlayer and targetPlayer ~= player and humanoid and humanoid.Health > 0 and head then
        if _S.faceHoverTargetModel ~= model or _S.faceHoverBillboard.Adornee ~= head then
            _S.faceHoverTargetModel = model
            _S.faceHoverBillboard.Adornee = head
            _S.faceHoverBillboard.Enabled = true
        end
    else
        _S.clearFaceHoverArrow()
    end
end

function _S.startFaceHoverScan()
    _S.faceHoverScanToken += 1
    local token = _S.faceHoverScanToken
    task.spawn(function()
        while not unloaded and _S.faceState == "selecting" and token == _S.faceHoverScanToken do
            _S.updateFaceHoverArrow()
            task.wait(0.1)
        end
        if token == _S.faceHoverScanToken then
            _S.clearFaceHoverArrow()
        end
    end)
end

function _S.stopFaceHoverScan()
    _S.faceHoverScanToken += 1
    _S.clearFaceHoverArrow()
end

_S.faceSection, _S.faceContents = _S.makeToolSection(
    "FACE FART",
    4,
    "Press G, hover a player to see the arrow, click to sit on their face and fart."
)

_S.faceStatus = makeLabel(_S.faceContents, "STATUS: INACTIVE", UDim2.new(1, 0, 0, 18), UDim2.new(), 11)
_S.faceStatus.LayoutOrder = 1
_S.faceStatus.Font = Enum.Font.GothamBold
_S.faceStatus.TextXAlignment = Enum.TextXAlignment.Left
_S.faceStatus.TextColor3 = theme.Muted

_S.faceTargetLabel = makeLabel(_S.faceContents, "TARGET: (none)", UDim2.new(1, 0, 0, 16), UDim2.new(), 11)
_S.faceTargetLabel.LayoutOrder = 2
_S.faceTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
bind(_S.faceTargetLabel, "TextColor3", "Muted")

_S.faceNameBox = makeTextBox(_S.faceContents, "", "Type a username...", UDim2.new(1, 0, 0, 26), UDim2.new())
_S.faceNameBox.LayoutOrder = 3
_S.faceNameBox.TextSize = 11

_S.faceSuggestions = Instance.new("Frame")
_S.faceSuggestions.Name = "FaceSuggestions"
_S.faceSuggestions.Size = UDim2.new(1, 0, 0, 0)
_S.faceSuggestions.AutomaticSize = Enum.AutomaticSize.Y
_S.faceSuggestions.BackgroundTransparency = 1
_S.faceSuggestions.LayoutOrder = 4
_S.faceSuggestions.Visible = false
_S.faceSuggestions.Parent = _S.faceContents

_S.faceSuggestionLayout = Instance.new("UIListLayout")
_S.faceSuggestionLayout.Padding = UDim.new(0, 2)
_S.faceSuggestionLayout.SortOrder = Enum.SortOrder.LayoutOrder
_S.faceSuggestionLayout.Parent = _S.faceSuggestions

function _S.setFaceTarget(targetPlayer)
    _S.faceTargetPlayer = targetPlayer
    if targetPlayer then
        _S.faceTargetLabel.Text = "TARGET: " .. targetPlayer.Name
        _S.faceNameBox.Text = targetPlayer.Name
    else
        _S.faceTargetLabel.Text = "TARGET: (none)"
    end
    _S.faceSuggestions.Visible = false
    if _S.updateFaceButton then _S.updateFaceButton() end
end

function _S.refreshFaceSuggestions()
    for _, child in ipairs(_S.faceSuggestions:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    if _S.faceState ~= "idle" then
        _S.faceSuggestions.Visible = false
        return
    end
    local query = string.lower(_S.faceNameBox.Text)
    if query == "" then
        _S.faceSuggestions.Visible = false
        return
    end
    local count = 0
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local nameLower = string.lower(otherPlayer.Name)
            local displayLower = string.lower(otherPlayer.DisplayName)
            local matches = string.sub(nameLower, 1, #query) == query
                or string.find(displayLower, query, 1, true) ~= nil
            if matches then
                count += 1
                if count > 5 then break end
                local suggestion = makeButton(
                    _S.faceSuggestions,
                    otherPlayer.Name,
                    UDim2.new(1, 0, 0, 22),
                    UDim2.new(),
                    "Button"
                )
                suggestion.LayoutOrder = count
                suggestion.TextSize = 10
                suggestion.TextXAlignment = Enum.TextXAlignment.Left
                suggestion.MouseButton1Click:Connect(function()
                    if _S.faceState == "active" then return end
                    _S.stopFaceHoverScan()
                    _S.faceState = "idle"
                    _S.setFaceTarget(otherPlayer)
                    _S.beginFaceFart(otherPlayer)
                end)
            end
        end
    end
    _S.faceSuggestions.Visible = count > 0
end

_S.faceNameBox.Focused:Connect(function()
    _S.refreshFaceSuggestions()
end)

_S.faceNameBox:GetPropertyChangedSignal("Text"):Connect(function()
    if _S.faceTargetPlayer
        and _S.faceTargetPlayer.Name ~= _S.faceNameBox.Text
        and _S.faceTargetPlayer.DisplayName ~= _S.faceNameBox.Text then
        _S.faceTargetPlayer = nil
        _S.faceTargetLabel.Text = "TARGET: (none)"
        if _S.updateFaceButton then _S.updateFaceButton() end
    end
    _S.refreshFaceSuggestions()
end)

_S.faceRateButton = makeButton(
    _S.faceContents,
    "FART RATE: " .. _S.faceFartsPerSecond .. " / S",
    UDim2.new(1, 0, 0, 30),
    UDim2.new(),
    "Button"
)
_S.faceRateButton.LayoutOrder = 5
_S.faceRateButton.TextSize = 11

_S.faceRateButton.MouseButton1Click:Connect(function()
    _S.FACE_FARTS_RATE_INDEX = (_S.FACE_FARTS_RATE_INDEX % #_S.FACE_FARTS_RATE_PRESETS) + 1
    local value = _S.FACE_FARTS_RATE_PRESETS[_S.FACE_FARTS_RATE_INDEX]
    _S.setFaceFartsPerSecond(value, true, false)
end)

_S.faceRateLabel = makeLabel(
    _S.faceContents,
    "RATE: " .. _S.faceFartsPerSecond .. " / S",
    UDim2.new(1, 0, 0, 16),
    UDim2.new(),
    11
)
_S.faceRateLabel.LayoutOrder = 6
bind(_S.faceRateLabel, "TextColor3", "Muted")

_S.faceRateRow = Instance.new("Frame")
_S.faceRateRow.Name = "FaceRateRow"
_S.faceRateRow.Size = UDim2.new(1, 0, 0, 20)
_S.faceRateRow.BackgroundTransparency = 1
_S.faceRateRow.LayoutOrder = 7
_S.faceRateRow.Parent = _S.faceContents

function _S.setFaceFartsPerSecond(value, moveSlider, movePreset)
    value = math.max(1, math.floor(value + 0.5))
    _S.faceFartsPerSecond = value
    if _S.faceRateLabel then
        _S.faceRateLabel.Text = "RATE: " .. value .. " / S"
    end
    if _S.faceRateBox then
        _S.faceRateBox.Text = tostring(value)
    end
    if _S.faceRateButton then
        _S.faceRateButton.Text = "FART RATE: " .. value .. " / S"
    end
    if moveSlider and _S.faceRateSlider then
        _S.faceRateSlider.SetPercent(math.clamp(value / _S.FACE_FARTS_RATE_SLIDER_MAX, 0, 1))
    end
    if movePreset then
        for i, preset in ipairs(_S.FACE_FARTS_RATE_PRESETS) do
            if preset == value then
                _S.FACE_FARTS_RATE_INDEX = i
                break
            end
        end
    end
end

_S.faceRateSlider = makeSlider(
    _S.faceRateRow,
    7,
    math.clamp(_S.faceFartsPerSecond / _S.FACE_FARTS_RATE_SLIDER_MAX, 0, 1),
    function(percent)
        _S.setFaceFartsPerSecond(percent * _S.FACE_FARTS_RATE_SLIDER_MAX, false, true)
    end
)

_S.faceRateBox = makeTextBox(
    _S.faceContents,
    tostring(_S.faceFartsPerSecond),
    "EXACT FARTS/SEC",
    UDim2.new(1, 0, 0, 24),
    UDim2.new()
)
_S.faceRateBox.LayoutOrder = 8
_S.faceRateBox.TextSize = 11
_S.faceRateBox.FocusLost:Connect(function()
    local typed = tonumber(_S.faceRateBox.Text)
    if typed and typed == typed and typed ~= math.huge and typed ~= -math.huge and typed >= 1 then
        _S.setFaceFartsPerSecond(typed, true, true)
    else
        _S.faceRateBox.Text = tostring(_S.faceFartsPerSecond)
    end
end)

faceKeyButton = makeButton(_S.faceContents, "", UDim2.new(1, 0, 0, 34), UDim2.new(), "Button")
faceKeyButton.LayoutOrder = 11
faceKeyButton.TextScaled = true

local faceKeyLimit = Instance.new("UITextSizeConstraint")
faceKeyLimit.MaxTextSize = 12
faceKeyLimit.Parent = faceKeyButton

faceKeyButton.MouseButton1Click:Connect(function()
    listeningFor = (listeningFor ~= "face") and "face" or nil
    refreshKeyButtons()
end)

_S.faceActivateButton = makeButton(_S.faceContents, "SELECT TARGET", UDim2.new(1, 0, 0, 36), UDim2.new(), "Accent")
_S.faceActivateButton.LayoutOrder = 12
_S.faceActivateButton.TextScaled = true

function _S.setFaceStatus(active, message)
    _S.faceStatus.Text = "STATUS: " .. (message or (active and "ACTIVE" or "INACTIVE"))
    _S.faceStatus.TextColor3 = active and rgb(45, 155, 95) or theme.Muted
end

function _S.updateFaceButton()
    if _S.faceState == "active" then
        _S.faceActivateButton.Text = "STOP FACE FART"
        _S.faceActivateButton.BackgroundColor3 = rgb(190, 65, 65)
    elseif _S.faceState == "selecting" then
        _S.faceActivateButton.Text = "CANCEL SELECTION"
        _S.faceActivateButton.BackgroundColor3 = rgb(190, 130, 45)
    elseif _S.faceTargetPlayer and _S.faceTargetPlayer.Parent then
        _S.faceActivateButton.Text = "FART ON " .. _S.faceTargetPlayer.Name
        _S.faceActivateButton.BackgroundColor3 = theme.Accent
    else
        _S.faceActivateButton.Text = "SELECT TARGET"
        _S.faceActivateButton.BackgroundColor3 = theme.Accent
    end
end

-- targetHeadCFrame: the full CFrame of the target's Head (or HumanoidRootPart fallback).
-- We place the seat directly in front of wherever the target is facing,
-- regardless of where our own character is standing.
function _S.computeFaceSeatCFrame(targetHeadCFrame)
    -- LookVector IS forward in Roblox (the direction the character faces).
    local forward = targetHeadCFrame.LookVector
    forward = Vector3.new(forward.X, 0, forward.Z)
    if forward.Magnitude < 0.01 then
        forward = Vector3.new(0, 0, -1)
    else
        forward = forward.Unit
    end
    local headPos = targetHeadCFrame.Position
    -- Place seat in front of their face, at head height.
    -- Change _S.FACE_DISTANCE (line ~2361) to adjust how far in front. 2.5 = ~2-3 studs.
    local seatPos = headPos + forward * _S.FACE_DISTANCE
    -- Seat faces away from the target so the sitting pose has your back (and butt) to their face.
    local lookCFrame = CFrame.lookAt(seatPos, seatPos + forward)
    -- Slight forward tilt so the character leans in.
    local tiltCFrame = CFrame.Angles(math.rad(_S.FACE_SEAT_TILT_DEGREES), 0, 0)
    return lookCFrame * tiltCFrame
end

function _S.createFaceFartObjects(seatCFrame)
    if _S.faceSeat then _S.faceSeat:Destroy() end
    if _S.faceFloor then _S.faceFloor:Destroy() end

    local seat = Instance.new("Seat")
    seat.Name = "FartFace_ClientSeat"
    seat.Anchored = true
    seat.CanCollide = true
    seat.CanTouch = true
    seat.CanQuery = true
    seat.CastShadow = false
    seat.Transparency = 1
    seat.LocalTransparencyModifier = 1
    seat.Size = Vector3.new(2, 0.5, 2)
    seat.CFrame = seatCFrame
    seat.Parent = workspace
    _S.faceSeat = seat

    local floor = Instance.new("Part")
    floor.Name = "FartFace_ClientFloor"
    floor.Anchored = true
    floor.CanCollide = true
    floor.CanTouch = false
    floor.CanQuery = false
    floor.CastShadow = false
    floor.Transparency = 1
    floor.LocalTransparencyModifier = 1
    floor.Size = Vector3.new(30, 1, 30)
    floor.CFrame = CFrame.new(seatCFrame.Position.X, seatCFrame.Position.Y - 3, seatCFrame.Position.Z)
    floor.Parent = workspace
    _S.faceFloor = floor
end

function _S.destroyFaceFartObjects()
    if _S.faceSeat then _S.faceSeat:Destroy() _S.faceSeat = nil end
    if _S.faceFloor then _S.faceFloor:Destroy() _S.faceFloor = nil end
end

function _S.stopFaceFart(message)
    _S.faceToken += 1
    _S.faceState = "idle"
    _S.stopFaceHoverScan()

    if _S.faceHeartbeatConn then
        _S.faceHeartbeatConn:Disconnect()
        _S.faceHeartbeatConn = nil
    end

    -- Restore position first (before destroying seat, to avoid falling)
    if _S.faceReturnCFrame then
        local _, localRoot = _S.getCharacterParts()
        if localRoot then
            localRoot.CFrame = _S.faceReturnCFrame
            localRoot.AssemblyLinearVelocity = Vector3.zero
            localRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end

    if _S.faceHumanoid and _S.faceHumanoid.Parent then
        _S.faceHumanoid.Sit = false
        if _S.facePreviousPlatformStand ~= nil then
            _S.faceHumanoid.PlatformStand = _S.facePreviousPlatformStand
        end
    end

    if _S.faceHumanoid and _S.faceHumanoid.Parent and _S.facePreviousAutoRotate ~= nil then
        _S.faceHumanoid.AutoRotate = _S.facePreviousAutoRotate
    end
    _S.faceHumanoid = nil
    _S.facePreviousAutoRotate = nil
    _S.facePreviousPlatformStand = nil
    _S.faceReturnCFrame = nil

    _S.destroyFaceFartObjects()

    if _S.faceTargetPlayer then
        _S.faceTargetLabel.Text = "TARGET: " .. _S.faceTargetPlayer.Name
    else
        _S.faceTargetLabel.Text = "TARGET: (none)"
    end

    _S.setFaceStatus(false, message or "INACTIVE")
    _S.updateFaceButton()
end

function _S.beginFaceFart(targetPlayer)
    local targetChar = targetPlayer.Character
    local targetHead = targetChar and (targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart"))
    local targetHumanoid = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHead or not targetHumanoid or targetHumanoid.Health <= 0 then
        _S.setFaceStatus(false, "TARGET UNAVAILABLE")
        return
    end

    local _, localRoot, localHumanoid = _S.getCharacterParts()
    if not localRoot or not localHumanoid then
        _S.setFaceStatus(false, "NO LOCAL CHARACTER")
        return
    end

    _S.faceToken += 1
    local token = _S.faceToken
    _S.faceState = "active"

    _S.faceReturnCFrame = localRoot.CFrame
    _S.faceHumanoid = localHumanoid
    _S.facePreviousAutoRotate = localHumanoid.AutoRotate
    _S.facePreviousPlatformStand = localHumanoid.PlatformStand
    localHumanoid.AutoRotate = false
    -- PlatformStand hands full control of the body to us. Without this, the
    -- default character controller (WASD input + gravity) fights every CFrame
    -- we set and the player just falls back to the ground near their old spot
    -- instead of visibly moving to the target's face.
    localHumanoid.PlatformStand = true

    local seatCFrame = _S.computeFaceSeatCFrame(targetHead.CFrame)
    _S.createFaceFartObjects(seatCFrame)

    -- Snap straight into position immediately, no fall/land gap to miss.
    localRoot.CFrame = seatCFrame
    localRoot.AssemblyLinearVelocity = Vector3.zero
    localRoot.AssemblyAngularVelocity = Vector3.zero
    localHumanoid.Sit = true

    _S.setFaceStatus(true, "ACTIVE — on " .. targetPlayer.Name)
    _S.updateFaceButton()

    local activatedAt = os.clock()
    local startTime = activatedAt
    local nextFart = activatedAt
    local duration = _S.faceDuration
    local fartingStarted = false

    if _S.faceHeartbeatConn then
        _S.faceHeartbeatConn:Disconnect()
        _S.faceHeartbeatConn = nil
    end

    -- Re-lock position every single frame instead of once-and-hope. This is
    -- what actually keeps the player pinned on the target's face as they move.
    _S.faceHeartbeatConn = RunService.Heartbeat:Connect(function()
        if unloaded or token ~= _S.faceToken then
            if _S.faceHeartbeatConn then
                _S.faceHeartbeatConn:Disconnect()
                _S.faceHeartbeatConn = nil
            end
            return
        end

        if not localRoot.Parent or not localHumanoid.Parent then
            _S.stopFaceFart("CHARACTER LOST")
            return
        end

        local tChar = targetPlayer.Character
        local tHead = tChar and (tChar:FindFirstChild("Head") or tChar:FindFirstChild("HumanoidRootPart"))
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        if not tHead or not tHum or tHum.Health <= 0 then
            _S.stopFaceFart("TARGET LOST")
            return
        end

        local newSeatCFrame = _S.computeFaceSeatCFrame(tHead.CFrame)
        if _S.faceSeat and _S.faceSeat.Parent then
            _S.faceSeat.CFrame = newSeatCFrame
        end
        if _S.faceFloor and _S.faceFloor.Parent then
            _S.faceFloor.CFrame = CFrame.new(newSeatCFrame.Position.X, newSeatCFrame.Position.Y - 3, newSeatCFrame.Position.Z)
        end

        localRoot.CFrame = newSeatCFrame
        localRoot.AssemblyLinearVelocity = Vector3.zero
        localRoot.AssemblyAngularVelocity = Vector3.zero
        if not localHumanoid.Sit then
            localHumanoid.Sit = true
        end

        local now = os.clock()
        if now - activatedAt < _S.FACE_INITIAL_DELAY then
            return
        end

        if not fartingStarted then
            fartingStarted = true
            startTime = now
            nextFart = now
        end

        if now - startTime >= duration then
            _S.stopFaceFart("DONE")
            return
        end

        local interval = 1 / math.max(_S.faceFartsPerSecond, 1)
        local burst = 0
        while nextFart <= now and burst < 50 do
            fart()
            nextFart += interval
            burst += 1
        end
        if nextFart < now then
            nextFart = now
        end
    end)
end

function _S.selectFaceTarget()
    if _S.faceState ~= "selecting" then return end
    local targetPart = _S.faceMouse.Target
    local model = targetPart and targetPart:FindFirstAncestorOfClass("Model")
    local targetPlayer = model and Players:GetPlayerFromCharacter(model)
    if not targetPlayer or targetPlayer == player then
        _S.setFaceStatus(false, "NOT A PLAYER — try again")
        return
    end
    local tChar = targetPlayer.Character
    local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
    if not tHum or tHum.Health <= 0 then
        _S.setFaceStatus(false, "TARGET UNAVAILABLE")
        return
    end
    _S.stopFaceHoverScan()
    _S.faceState = "idle"
    _S.setFaceTarget(targetPlayer)
    _S.beginFaceFart(targetPlayer)
end

function _S.toggleFaceFart()
    if unloaded then return end

    if _S.faceState == "active" then
        _S.stopFaceFart("STOPPED")
        return
    end
    if _S.faceState == "selecting" then
        _S.faceState = "idle"
        _S.stopFaceHoverScan()
        _S.setFaceStatus(false, "SELECTION CANCELLED")
        _S.updateFaceButton()
        return
    end

    _S.faceState = "selecting"
    _S.startFaceHoverScan()
    _S.setFaceStatus(false, "SELECTING — click a player")
    _S.updateFaceButton()
end

_S.faceActivateButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    if _S.faceState == "active" then
        _S.stopFaceFart("STOPPED")
    elseif _S.faceState == "selecting" then
        _S.faceState = "idle"
        _S.stopFaceHoverScan()
        _S.setFaceStatus(false, "SELECTION CANCELLED")
        _S.updateFaceButton()
    elseif _S.faceTargetPlayer and _S.faceTargetPlayer.Parent then
        local tChar = _S.faceTargetPlayer.Character
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        if tHum and tHum.Health > 0 then
            _S.beginFaceFart(_S.faceTargetPlayer)
        else
            _S.setFaceStatus(false, "TARGET UNAVAILABLE")
        end
    else
        _S.faceState = "selecting"
        _S.startFaceHoverScan()
        _S.setFaceStatus(false, "SELECTING — click a player")
        _S.updateFaceButton()
    end
end)

keep(UIS.InputBegan:Connect(function(input, gameProcessed)
    if unloaded or gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and _S.faceState == "selecting" then
        _S.selectFaceTarget()
        return
    end
end))

keep(UIS.JumpRequest:Connect(function()
    if _S.faceState == "active" then
        _S.stopFaceFart("JUMPED")
    end
end))

keep(Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == _S.faceTargetPlayer then
        _S.faceTargetPlayer = nil
        _S.faceTargetLabel.Text = "TARGET: (none)"
        if _S.faceState == "active" then
            _S.stopFaceFart("TARGET LEFT")
        end
        if _S.updateFaceButton then _S.updateFaceButton() end
    end
end))

_S.updateFaceButton()
refreshKeyButtons()

--==================================================
-- RESET TO DEFAULTS
--==================================================

_S.resetDefaultsButton = settingsButton("RESET TO DEFAULTS", 42, rgb(170, 95, 55))

_S.resetDefaultsButton.MouseButton1Click:Connect(function()
    if unloaded then return end

    scaleInitialized = false
    updateScale()
    for i, value in ipairs(scaleOptions) do
        if math.abs(value - uiScale) < 0.001 then
            scaleIndex = i
            break
        end
    end
    scaleTitle.Text = "UI SIZE: " .. string.format("%.1fx", uiScale)
    refreshScaleButtons()
    applyTransparency(0)
    transparencySlider.SetPercent(0)
    applyThemePreset(themePresets[3])

    setDelay(0.5, true)
    stopPattern()
    _S.patternLoop = false
    _S.loopButton.Text = "LOOP: OFF"

    fartKey = Enum.KeyCode.F
    spamKey = Enum.KeyCode.E
    ninjaKey = Enum.KeyCode.Q
    patternKey = Enum.KeyCode.P
    orbitKey = Enum.KeyCode.R
    faceKey = Enum.KeyCode.G
    if _S.stopFaceFart then _S.stopFaceFart("Reset.") end
    _S.FACE_FARTS_RATE_INDEX = 1
    _S.setFaceFartsPerSecond(_S.FACE_FARTS_RATE_DEFAULT, true, true)
    _S.faceDuration = 1.0
    _S.faceDurationSlider.SetPercent((_S.faceDuration - _S.FACE_DURATION_MIN) / (_S.FACE_DURATION_MAX - _S.FACE_DURATION_MIN))
    _S.faceDurationLabel.Text = string.format("DURATION: %.2fs", _S.faceDuration)
    _S.setFaceTarget(nil)
    _S.faceNameBox.Text = ""
    _S.setFaceStatus(false, "INACTIVE")
    listeningFor = nil
    refreshKeyButtons()

    _S.ninjaModeIndex = 2
    _S.ninjaMode = _S.NINJA_MODES[_S.ninjaModeIndex]
    _S.refreshNinjaModeButton()
    _S.ninjaFartPresetIndex = 2
    _S.setNinjaFarts(150, true, false)
    _S.ninjaLandingFart = true
    _S.refreshNinjaFartButton()
    _S.setNinjaLandingFarts(50, true)

    patternKey = Enum.KeyCode.P
    orbitKey = Enum.KeyCode.R
    refreshKeyButtons()

    _S.orbitSpeedIndex = 2
    _S.orbitSpeedButton.Text = "SPEED: " .. _S.orbitSpeedPresets[_S.orbitSpeedIndex].name
    _S.orbitFartsPerSecond = 16
    _S.orbitRateLabel.Text = "FART RATE: 16.0 / SEC"
    _S.orbitRateBox.Text = "16"
    _S.orbitRateSlider.SetPercent((16 - _S.ORBIT_FART_RATE_MIN) / (_S.ORBIT_FART_RATE_MAX - _S.ORBIT_FART_RATE_MIN))

    print("Settings reset to defaults.")
end)

--==================================================
-- PAGE NAVIGATION
--==================================================

function _S.updateWindow()
    if minimized then
        frame.Size = UDim2.fromOffset(310, 40)
        main.Visible = false
        settings.Visible = false
    else
        if settingsOpen then
            frame.Size = UDim2.fromOffset(310, 380)
            main.Visible = false
            settings.Visible = true
        else
            frame.Size = UDim2.fromOffset(310, 260)
            main.Visible = true
            settings.Visible = false
        end
    end
    refreshSideMenu()
end

settingsToggleButton.MouseButton1Click:Connect(function()
    if unloaded then return end
    minimized = false
    settingsOpen = not settingsOpen
    _S.updateWindow()
end)

back.MouseButton1Click:Connect(function()
    settingsOpen = false
    _S.updateWindow()
end)

minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    _S.updateWindow()
end)

--==================================================
-- DRAG ONLY FROM TOPBAR
--==================================================

_S.dragStart = nil
_S.startPosition = nil

topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.X >= settingsToggleButton.AbsolutePosition.X then
            return
        end
        dragging = true
        _S.dragStart = input.Position
        _S.startPosition = frame.Position
    end
end)

keep(UIS.InputChanged:Connect(function(input)
    if dragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - _S.dragStart
            frame.Position = UDim2.new(
                _S.startPosition.X.Scale,
                _S.startPosition.X.Offset + delta.X,
                _S.startPosition.Y.Scale,
                _S.startPosition.Y.Offset + delta.Y
            )
        end
    end
end))

keep(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

--==================================================
-- UNLOAD
--==================================================

close.MouseButton1Click:Connect(function()
    _S.stopFartOrbit("Unloaded.")
    _S.stopOrbitHoverScan()
    _S.cancelNinja("Unloaded.")
    if _S.stopFaceFart then _S.stopFaceFart("Unloaded.") end
    unloaded = true
    enabled = false
    spamToken += 1
    _S.patternToken += 1
    dragging = false
    sliderDragging = nil
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
    if _S.orbitHoverBillboard then
        _S.orbitHoverBillboard:Destroy()
    end
    if _S.faceHoverBillboard then
        _S.faceHoverBillboard:Destroy()
    end
    crosshairGui:Destroy()
    gui:Destroy()
end)

--==================================================
-- V2.8 FEATURE / SOURCE DOCUMENTATION
--==================================================
--
-- HOW THE REMOTE WORKS
--   fartRemote = game.ReplicatedStorage.Remotes.Misc.Fart
--   Every fart is just fartRemote:FireServer(). The server handles the
--   sound/animation. The client only controls timing and positioning.
--
--==================================================
-- SINGLE FART  (default key: F)
--==================================================
--   Calls fart() once. fart() fires the remote, increments the local
--   counter, and updates the counter label + settings stats display.
--   Also wired to the FART button in the main panel.
--
--==================================================
-- SPAM  (default key: E)
--==================================================
--   Toggles continuous firing. Uses a token pattern to safely stop:
--   spamToken increments on every toggle; the loop checks its own token
--   each iteration and exits if it no longer matches.
--   Rate is set by delayTime (seconds between farts). A burst cap of 25
--   prevents spiral catch-up if the game freezes mid-loop.
--   Turning spam on stops any active pattern playback first.
--
--==================================================
-- SETTINGS PAGE
--==================================================
--   Opened with the ⚙ button in the topbar.
--
--   UI SIZE (0.8x – 1.2x)
--     Scales the whole GUI using a UIScale on the ScreenGui.
--     Five preset buttons; active one highlights in accent colour.
--
--   UI TRANSPARENCY (0% – 80%)
--     Fades all GuiObject backgrounds proportionally. Stored originals
--     so the slider is non-destructive — drag back to 0% to restore.
--     Capped at 80% so the GUI stays usable.
--
--   KEYBIND PANEL
--     Tap any key button to enter listening mode; next key pressed
--     becomes that action's binding (Escape cancels). Binds for:
--     FART, SPAM, PATTERN play/pause, ORBIT, NINJA, FACE FART.
--     A conflict warning appears if two actions share a key.
--     RightShift always hides/shows the GUI regardless of binds.
--
--   THEMES  (Crimson / Charcoal / Midnight)
--     Swaps Background, Topbar, Accent, Button, Track, Text, Muted and
--     both gradient colours in one go. The theme system uses a bindings
--     table so every bound object updates automatically with refreshTheme().
--     Active theme highlights in its own accent. Gradient spins at
--     90 deg/sec via a Heartbeat connection; stops when no theme is active.
--
--   STATS
--     Shows total fart count. Click to print to output. RESET STATS
--     zeroes the counter everywhere it appears.
--
--==================================================
-- FART PATTERN  (default key: P = play/pause)
--==================================================
--   Section in TOOLS panel, order 2.
--   A pattern is a list of steps: "F" = fire the remote once,
--   number = wait that many seconds (0.001 – 60s).
--   Max 200 steps. Stored as _S.pattern (table).
--
--   TAP TO RECORD
--     Each press fires a fart and records the gap since the last tap
--     as a wait step, then appends an F. First tap starts recording.
--     Gaps are rounded to 1 ms. Useful for tapping out a beat live.
--
--   + FART / + WAIT buttons
--     Append a single F or the value in the wait box directly.
--
--   UNDO / CLEAR / RANDOM
--     Undo removes the last step. Clear wipes everything and stops.
--     Random generates 4–10 farts with waits of 0.05/0.1/0.15/0.25/0.5s.
--
--   Text box
--     Accepts comma-separated patterns typed or pasted in.
--     Format: F,0.1,F,0.5,F  (F or FART = fire, number = wait in secs).
--     Parsed on FocusLost. Invalid tokens show an error; valid ones load.
--     Clears the pattern if left blank.
--
--   PLAY / PAUSE / STOP / LOOP
--     Playback runs in a task.spawn coroutine with a token for safe
--     cancellation. Pause stores a "paused" flag and the coroutine waits;
--     it also adds the paused duration back to the timing baseline so
--     gaps stay accurate after resuming. LOOP repeats until manually
--     stopped. The pattern key (P) toggles play ↔ pause.
--
--==================================================
-- FART ORBIT  (default key: R)
--==================================================
--   Section in TOOLS panel, order 3.
--   Press R to enter selection mode; the cursor shows a ▼ arrow above
--   any valid hoverable player (checked every 0.1s). Click to confirm.
--   Press R again to cancel or stop.
--
--   Once a target is selected, every Heartbeat frame:
--     1. orbitAngle advances by dt * rotations * 2π (radians).
--     2. Local character CFrame is set to a circle around the target:
--          X/Z = target.X + cos/sin(orbitAngle) * radius
--          Y   = target.Y + orbitHeight (smoothed with exp decay)
--     3. Character always faces the target (CFrame.lookAt).
--     4. AutoRotate is disabled for the duration.
--     5. A 9×1×9 invisible floor is maintained directly under the
--        character to prevent the fall animation.
--     6. Farts fire at orbitFartsPerSecond using an accumulator clock.
--
--   SPEED presets: SLOW (0.5 rot/s), NORMAL (1.0), FAST (2.0),
--     VERY FAST (3.0). Cycles with each button press.
--   FART RATE slider: 1 – 24/s, rounds to nearest 0.5. Exact box too.
--   Target leaving the server stops the orbit automatically.
--   STOP ORBIT button or pressing R while orbiting stops it and
--     restores the character's original CFrame.
--
--==================================================
-- NINJA TELEPORT  (default key: Q)
--==================================================
--   Section in TOOLS panel, order 1.
--   Two modes (toggled with the MODE button):
--
--   CAMERA LOCK
--     Character stays at its current position. Camera is locked in
--     place and the player can aim from there. When Q is pressed, the
--     character teleports to whatever the camera is pointing at
--     (raycast from camera origin, 10 000 studs, ignoring own character).
--
--   FREECAM
--     Character is hidden 1 000 studs below the map (saved to restore
--     later). Camera detaches and flies freely. WASD moves the camera
--     at NINJA_FREECAM_SPEED (110 studs/s); holding Shift boosts ×3.
--     Mouse drag rotates. Pitch is clamped ±88°.
--     Q teleports the character to the camera's aimed position.
--
--   Both modes:
--     - Fire a preparation burst of NINJA_FARTS (default 150) at a rate
--       that fills NINJA_DURATION (2s), starting NINJA_FART_LEAD (0.225s)
--       early so the sound cloud lands on the teleport frame.
--     - After teleport, the character spins NINJA_TURNS (4) times in
--       NINJA_POST_TP_DURATION (1s) if the TP fart toggle is on.
--     - POST-TP FARTS (default 50) fire over that 1s spin window.
--     - Arm timeout: if the player never fires Q after arming, the
--       mode cancels after NINJA_ARM_TIMEOUT (20s).
--     - Destination is found by raycasting from the camera; the hit
--       point is offset upward by the character's hip height + torso
--       so they land on the surface rather than inside it.
--
--==================================================
-- FACE FART  (default key: G)
--==================================================
--   Section in TOOLS panel, order 4.
--   Teleports you to sit directly in front of the target's face
--   (wherever they are facing) and fires farts for a set duration.
--
--   TARGET SELECTION
--     Username text box with player name suggestions (click = instant
--     start). Or press G / SELECT TARGET to enter hover mode: a ▼
--     arrow follows the nearest valid player under the cursor (checked
--     every 0.1s via a scan token loop). Click to confirm.
--     G key: active → stop; selecting → cancel; idle → enter selection.
--
--   POSITIONING  (computeFaceSeatCFrame)
--     Uses targetHead.CFrame.LookVector (the direction the target faces).
--     Seat placed at headPos + forward * FACE_DISTANCE (default 2.5 studs).
--     The seat's own CFrame.lookAt points away from the head, so the
--     sitting animation has your back (and butt) facing the target.
--     A 20° forward tilt (CFrame.Angles on X) makes the character lean in.
--     Change _S.FACE_DISTANCE (line ~2361) to adjust how far in front.
--     Change _S.FACE_SEAT_TILT_DEGREES for the lean angle.
--
--   LOCKING IN PLACE  (Heartbeat loop)
--     Humanoid.PlatformStand = true disables the default walk controller
--     so gravity/WASD can't fight the CFrame lock.
--     Every Heartbeat frame: recalculate seat from live tHead.CFrame,
--     move the invisible seat Part, snap localRoot.CFrame to it,
--     zero velocity, keep Humanoid.Sit = true for the pose.
--     This means the seat tracks the target if they turn around.
--
--   TIMING
--     FACE_INITIAL_DELAY (0.3s) before farts start (lets the sit anim land).
--     FART RATE presets 50/150/250, slider up to 500/s, exact box.
--     DURATION slider 0.1 – 1.0s.  Farts stop after duration seconds.
--
--   CLIENT OBJECTS
--     An anchored Seat (2×0.5×2, invisible) keeps Humanoid.Sit = true.
--     An anchored 30×1×30 invisible floor 3 studs below catches fall-through.
--     Both destroyed on any stop path.
--
--   STOP / CLEANUP
--     Triggered by: duration elapsed, manual stop button, G key press,
--     jump (UserInputService.JumpRequest), target leaving the server,
--     character lost, GUI close, character reset.
--     On stop: Heartbeat disconnected, floor + seat destroyed,
--     CFrame restored to pre-activation position, Humanoid.Sit = false,
--     PlatformStand restored, AutoRotate restored.
--
--==================================================

--==================================================
-- CREDITS
--==================================================

-- Made with help from:
-- Claude, Qwen, ChatGPT
-- And thanks to Mr. Skibidi for letting it happen!

--==================================================
-- END OF CUSTOM FEATURE DOCUMENTATION
--==================================================