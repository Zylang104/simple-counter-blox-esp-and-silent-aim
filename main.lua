-- Thanks for using my script, i hope you like it and remember that this is a alpha so if you find a error feel free to tell me and if you want also change it yourself! :>
--btw i know the box is kinda laggy, i don't know what the fuck i did to it but it still works
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- Settings, you can change here a option if you want directly here
local settings = {
    MaxDistance = 100,
    ShowGlow = true,
    GlowColor = Color3.fromRGB(255, 0, 0), -- HERE YOU CAN CHANGE THE ENEMY GLOW COLOR, YES I SHOULD HAVE ADDED A OPTION ON THE UI IN THE FIRST PLACE BUT IM WORKING A COLOR SELECTOR BY MYSELF JUST FOR LEARNING
    ShowBoxes = true,
    ShowNames = true,
    ShowHealth = true,
    ShowMoney = true,
}

-- ESP cache
local espCache = {}

-- Create drawing object
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props) do
        obj[k] = v
    end
    return obj
end

-- Create ESP for player
local function createESP(player)
    local highlight = Instance.new("Highlight")
    highlight.Enabled = false
    highlight.FillColor = settings.GlowColor
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    highlight.Parent = player.Character or player.CharacterAdded:Wait()

    espCache[player] = {
        highlight = highlight,
        name = createDrawing("Text", {Size=14, Center=true, Outline=true, Color=Color3.fromRGB(255,255,255), Visible=false}),
        money = createDrawing("Text", {Size=13, Center=true, Outline=true, Color=Color3.fromRGB(0,255,0), Visible=false}),
        healthOutline = createDrawing("Line", {Thickness=3, Color=Color3.fromRGB(0,0,0), Visible=false}),
        health = createDrawing("Line", {Thickness=1, Color=Color3.fromRGB(0,255,0), Visible=false}),
        box = createDrawing("Square", {Thickness=1, Color=Color3.fromRGB(255,255,255), Filled=false, Visible=false}),
        boxOutline = createDrawing("Square", {Thickness=3, Color=Color3.fromRGB(0,0,0), Filled=false, Visible=false}),
    }

    player.CharacterAdded:Connect(function(char)
        highlight.Parent = char
    end)
end

-- Remove ESP funcion based on distance
local function removeESP(player)
    if espCache[player] then
        if espCache[player].highlight then
            espCache[player].highlight:Destroy()
        end
        for _,obj in pairs(espCache[player]) do
            if typeof(obj) == "table" and obj.Remove then
                obj:Remove()
            end
        end
        espCache[player] = nil
    end
end

-- Update ESP every frame
RunService.RenderStepped:Connect(function()
    for player, drawings in pairs(espCache) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChild("Humanoid")

        if player.Team == localPlayer.Team then
            drawings.highlight.Enabled = false
            for k,obj in pairs(drawings) do if k~="highlight" then obj.Visible=false end end
            continue
        end

        if root and humanoid then
            local localChar = localPlayer.Character
            if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
                drawings.highlight.Enabled = false
                for k,obj in pairs(drawings) do if k~="highlight" then obj.Visible=false end end
                continue
            end

            local distance = (root.Position - localChar.HumanoidRootPart.Position).Magnitude
            if distance <= settings.MaxDistance then
                local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    -- Box on player
                    if settings.ShowBoxes then
                        local sizeY = (camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0)).Y -
                                       camera:WorldToViewportPoint(root.Position + Vector3.new(0,2.6,0)).Y)
                        local boxSize = Vector2.new(math.abs(sizeY) * 0.6, math.abs(sizeY))
                        local boxPos = Vector2.new(rootPos.X - boxSize.X/2, rootPos.Y - boxSize.Y/2)

                        drawings.box.Size = boxSize
                        drawings.box.Position = boxPos
                        drawings.box.Visible = true
                        drawings.boxOutline.Size = boxSize
                        drawings.boxOutline.Position = boxPos
                        drawings.boxOutline.Visible = true
                    else
                        drawings.box.Visible = false
                        drawings.boxOutline.Visible = false
                    end

                    --  i don't know what the fuck i did here
                    if settings.ShowNames then
                        drawings.name.Text = player.Name
                        drawings.name.Position = Vector2.new(rootPos.X, rootPos.Y - 40)
                        drawings.name.Visible = true
                    else
                        drawings.name.Visible = false
                    end

                    -- Money
                    if settings.ShowMoney then
                        local moneyVal = 0
                        local status = player:FindFirstChild("Status") or player:FindFirstChild("leaderstats")
                        if status then
                            local cash = status:FindFirstChild("Cash") or status:FindFirstChild("Money")
                            if cash and tonumber(cash.Value) then
                                moneyVal = cash.Value
                            end
                        end
                        drawings.money.Text = "$"..tostring(moneyVal)
                        drawings.money.Position = Vector2.new(rootPos.X, rootPos.Y + 40)
                        drawings.money.Visible = true
                    else
                        drawings.money.Visible = false
                    end

                    -- Health (i fucking hate this shit)
                    if settings.ShowHealth then
                        local sizeY = (camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0)).Y -
                                       camera:WorldToViewportPoint(root.Position + Vector3.new(0,2.6,0)).Y)
                        local boxSize = Vector2.new(math.abs(sizeY) * 0.6, math.abs(sizeY))
                        local boxPos = Vector2.new(rootPos.X - boxSize.X/2, rootPos.Y - boxSize.Y/2)

                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        local barHeight = boxSize.Y * healthPercent

                        drawings.healthOutline.From = Vector2.new(boxPos.X - 6, boxPos.Y + boxSize.Y)
                        drawings.healthOutline.To = Vector2.new(boxPos.X - 6, boxPos.Y)
                        drawings.healthOutline.Visible = true

                        drawings.health.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y)
                        drawings.health.To = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y - barHeight)
                        drawings.health.Color = Color3.fromRGB(255 - (255*healthPercent), 255*healthPercent, 0)
                        drawings.health.Visible = true
                    else
                        drawings.health.Visible = false
                        drawings.healthOutline.Visible = false
                    end

                    -- Glow
                    if settings.ShowGlow then
                        drawings.highlight.Enabled = true
                        drawings.highlight.FillColor = settings.GlowColor
                    else
                        drawings.highlight.Enabled = false
                    end
                else
                    drawings.highlight.Enabled = false
                    for k,obj in pairs(drawings) do if k~="highlight" then obj.Visible=false end end
                end
            else
                drawings.highlight.Enabled = false
                for k,obj in pairs(drawings) do if k~="highlight" then obj.Visible=false end end
            end
        else
            drawings.highlight.Enabled = false
            for k,obj in pairs(drawings) do if k~="highlight" then obj.Visible=false end end
        end
    end
end)

-- Add ESP to existing players
for _,plr in ipairs(Players:GetPlayers()) do
    if plr ~= localPlayer then createESP(plr) end
end
Players.PlayerAdded:Connect(function(plr) if plr ~= localPlayer then createESP(plr) end end)
Players.PlayerRemoving:Connect(removeESP)

--// GUI (spoiler: the gui makes me vomit)
local function getGuiParent()
    if gethui then
        return gethui()
    elseif syn and syn.protect_gui then
        local gui = Instance.new("ScreenGui")
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
        return gui
    else
        return Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = getGuiParent()

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 320)
Frame.Position = UDim2.new(0.5, -125, 0.5, -160)
Frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Visible = true

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundTransparency = 1
Title.Text = "ESP Settings"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

-- Simple toggle button helper
local function createToggle(name, default, order, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1,-20,0,25)
    btn.Position = UDim2.new(0,10,0,30+(order*30))
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.Text = name..": "..tostring(default)
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = name..": "..tostring(default)
        callback(default)
    end)
end

-- Buttons
createToggle("Show Glow", settings.ShowGlow, 0, function(val) settings.ShowGlow = val end)
createToggle("Show Boxes", settings.ShowBoxes, 1, function(val) settings.ShowBoxes = val end)
createToggle("Show Names", settings.ShowNames, 2, function(val) settings.ShowNames = val end)
createToggle("Show Health", settings.ShowHealth, 3, function(val) settings.ShowHealth = val end)
createToggle("Show Money", settings.ShowMoney, 4, function(val) settings.ShowMoney = val end)

-- Distance adjust (im not good for graphics design)
local Plus = Instance.new("TextButton", Frame)
Plus.Size = UDim2.new(0.45,0,0,25)
Plus.Position = UDim2.new(0.05,0,0,200)
Plus.Text = "+10 Distance"
Plus.BackgroundColor3 = Color3.fromRGB(60,60,60)
Plus.TextColor3 = Color3.fromRGB(255,255,255)
Plus.MouseButton1Click:Connect(function()
    settings.MaxDistance = settings.MaxDistance + 10
    print("Distance:", settings.MaxDistance)
end)

local Minus = Instance.new("TextButton", Frame)
Minus.Size = UDim2.new(0.45,0,0,25)
Minus.Position = UDim2.new(0.5,0,0,200)
Minus.Text = "-10 Distance"
Minus.BackgroundColor3 = Color3.fromRGB(60,60,60)
Minus.TextColor3 = Color3.fromRGB(255,255,255)
Minus.MouseButton1Click:Connect(function()
    settings.MaxDistance = math.max(10, settings.MaxDistance - 10)
    print("Distance:", settings.MaxDistance)
end)

-- Loader button
local LoaderBtn = Instance.new("TextButton", Frame)
LoaderBtn.Size = UDim2.new(0.9,0,0,25)
LoaderBtn.Position = UDim2.new(0.05,0,0,240)
LoaderBtn.Text = "Silent Aim"
LoaderBtn.BackgroundColor3 = Color3.fromRGB(80,30,30)
LoaderBtn.TextColor3 = Color3.fromRGB(255,255,255)
LoaderBtn.MouseButton1Click:Connect(function()
    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Averiias/Universal-SilentAim/refs/heads/main/main.lua", true) -- THANKS TO Averiias :)
    end)
    if not success or not result or result:find("404") then
        warn("Failed to fetch Universal Silent Aim")
        return
    end
    local ok, err = pcall(function()
        loadstring(result)()
    end)
    if not ok then
        warn("Silent Aim Error:", err)
    end
end)

-- Keybind: END to toggle GUI, if for some reason you hate the end key you can change it how you want
UserInputService.InputBegan:Connect(function(input,gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.End then
        Frame.Visible = not Frame.Visible
    end
end)
