local NotificationLibrary = {}

do
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    function NotificationLibrary:Notify(title, text, duration)
        duration = duration or 4
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 250, 0, 60)
        frame.Position = UDim2.new(1, 30, 1, -75)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        frame.BackgroundTransparency = 0.25
        frame.BorderSizePixel = 0
        frame.ZIndex = 100
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.6
        stroke.Thickness = 1.5
        stroke.Parent = frame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -30, 0, 20)
        titleLabel.Position = UDim2.new(0, 12, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 13
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = frame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -24, 0, 6)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        closeBtn.TextSize = 14
        closeBtn.Parent = frame
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -24, 0, 24)
        textLabel.Position = UDim2.new(0, 12, 0, 28)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.Gotham
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        textLabel.TextSize = 11
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextWrapped = true
        textLabel.Parent = frame
        
        local startTime = tick()
        local isSlidingIn = true
        
        task.spawn(function()
            while isSlidingIn and tick() - startTime < 0.3 do
                local t = math.min((tick() - startTime) / 0.3, 1)
                frame.Position = UDim2.new(1, 30 + (1 - t) * -295, 1, -75)
                task.wait()
            end
            if isSlidingIn then
                frame.Position = UDim2.new(1, -265, 1, -75)
            end
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            isSlidingIn = false
            frame:Destroy()
        end)
        
        task.delay(duration, function()
            if not frame.Parent then return end
            local startTime2 = tick()
            local startX = frame.Position.X.Offset
            local slidingOut = true
            task.spawn(function()
                while slidingOut and tick() - startTime2 < 0.2 do
                    local t = math.min((tick() - startTime2) / 0.2, 1)
                    frame.Position = UDim2.new(1, startX + t * 295, 1, -75)
                    frame.BackgroundTransparency = 0.25 + t * 0.75
                    task.wait()
                end
                if slidingOut then
                    frame:Destroy()
                end
            end)
            task.delay(0.25, function()
                if frame.Parent then
                    frame:Destroy()
                end
            end)
        end)
    end
end

return NotificationLibrary