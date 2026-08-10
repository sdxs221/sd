local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Library = {}

function Library.Create(config)
    local uiTitle = config.Title or ""
    local searchPlaceholder = config.SearchPlaceholder or ""
    local items = config.Items or {}

    if playerGui:FindFirstChild("ModernSelectUI") then
        playerGui.ModernSelectUI:Destroy()
    end

    if Lighting:FindFirstChild("UIBlur") then
        Lighting.UIBlur:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernSelectUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local blur = Instance.new("BlurEffect")
    blur.Name = "UIBlur"
    blur.Size = 0
    blur.Parent = Lighting
    TweenService:Create(blur, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {Size = 22}):Play()

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 270, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -135, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.ClipsDescendants = true 
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(60, 100, 220)
    mainStroke.Transparency = 0.3
    mainStroke.Thickness = 1.5
    mainStroke.Parent = mainFrame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 25, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 12, 20))
    })
    gradient.Rotation = 45
    gradient.Parent = mainFrame

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 45)
    topBar.BackgroundTransparency = 1
    topBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 22)
    titleLabel.Position = UDim2.new(0, 15, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = uiTitle
    titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    local subTitle = Instance.new("TextLabel")
    subTitle.Size = UDim2.new(1, -20, 0, 15)
    subTitle.Position = UDim2.new(0, 15, 0, 26)
    subTitle.BackgroundTransparency = 1
    subTitle.Text = "- 选择游戏 -"
    subTitle.TextColor3 = Color3.fromRGB(130, 140, 170)
    subTitle.TextSize = 11
    subTitle.Font = Enum.Font.Gotham
    subTitle.TextXAlignment = Enum.TextXAlignment.Left
    subTitle.Parent = topBar

    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.9, 0, 0, 34)
    searchBox.Position = UDim2.new(0.05, 0, 0, 52)
    searchBox.BackgroundColor3 = Color3.fromRGB(18, 21, 35)
    searchBox.PlaceholderText = searchPlaceholder
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
    searchBox.TextSize = 12
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = mainFrame

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchBox

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(0.9, 0, 0, 240)
    scrollingFrame.Position = UDim2.new(0.05, 0, 0, 96)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.ScrollBarThickness = 3
    scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 140, 255)
    scrollingFrame.Parent = mainFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 6)
    uiListLayout.Parent = scrollingFrame

    uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y + 10)
    end)

    local particleContainer = Instance.new("Folder")
    particleContainer.Name = "Particles"
    particleContainer.Parent = mainFrame

    task.spawn(function()
        while mainFrame and mainFrame.Parent do
            task.wait(0.5)
            if not mainFrame.Visible then continue end
            local particle = Instance.new("Frame")
            local size = math.random(3, 5)
            particle.Size = UDim2.new(0, size, 0, size)
            particle.Position = UDim2.new(math.random(10, 90)/100, 0, 1, 0)
            particle.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
            particle.BackgroundTransparency = 0.4
            particle.Parent = particleContainer
            
            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(1, 0)
            pCorner.Parent = particle
            
            local tw = TweenService:Create(particle, TweenInfo.new(2.5, Enum.EasingStyle.Sine), {
                Position = UDim2.new(particle.Position.X.Scale + (math.random(-15,15)/100), 0, -0.1, 0),
                BackgroundTransparency = 1
            })
            tw:Play()
            tw.Completed:Connect(function()
                particle:Destroy()
            end)
        end
    end)

    local buttonTable = {}

    local function createButton(data)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
        btn.BackgroundTransparency = 0.6
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = scrollingFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(50, 90, 160)
        btnStroke.Transparency = 0.6
        btnStroke.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.1, Color = Color3.fromRGB(0, 162, 255)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.6, Color = Color3.fromRGB(50, 90, 160)}):Play()
        end)

        local leftDot = Instance.new("Frame")
        leftDot.Size = UDim2.new(0, 7, 0, 7)
        leftDot.Position = UDim2.new(0, 12, 0.5, -3.5)
        leftDot.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
        leftDot.Parent = btn
        local ldCorner = Instance.new("UICorner")
        ldCorner.CornerRadius = UDim.new(1, 0)
        ldCorner.Parent = leftDot

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0.6, 0, 1, 0)
        textLabel.Position = UDim2.new(0, 30, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = data.Name
        textLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.GothamMedium
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = btn

        local rightDot = Instance.new("Frame")
        rightDot.Size = UDim2.new(0, 7, 0, 7)
        rightDot.Position = UDim2.new(1, -18, 0.5, -3.5)
        rightDot.BackgroundColor3 = Color3.fromRGB(50, 255, 120)
        rightDot.Parent = btn
        local rdCorner = Instance.new("UICorner")
        rdCorner.CornerRadius = UDim.new(1, 0)
        rdCorner.Parent = rightDot

        btn.MouseButton1Click:Connect(function()
            if data.Callback then
                data.Callback()
            end

            scrollingFrame.Visible = false
            topBar.Visible = false
            searchBox.Visible = false

            local currentPos = mainFrame.Position
            local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 270, 0, 0),
                Position = currentPos + UDim2.new(0, 0, 0, 175)
            })

            if blur then
                local blurTween = TweenService:Create(blur, TweenInfo.new(0.6), {Size = 0})
                blurTween:Play()
                blurTween.Completed:Connect(function()
                    blur:Destroy()
                end)
            end

            closeTween:Play()
            closeTween.Completed:Wait()
            screenGui:Destroy()
        end)

        table.insert(buttonTable, {instance = btn, name = data.Name})
    end

    for _, info in ipairs(items) do
        createButton(info)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for _, item in ipairs(buttonTable) do
            if query == "" or string.find(item.name:lower(), query) then
                item.instance.Visible = true
            else
                item.instance.Visible = false
            end
        end
    end)

    mainFrame.Size = UDim2.new(0, 270, 0, 0)
    mainFrame.Position = UDim2.new(0.5, -135, 0.5, 0)

    TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 270, 0, 350),
        Position = UDim2.new(0.5, -135, 0.5, -175)
    }):Play()
end

return Library
