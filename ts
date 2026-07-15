local NotificationLibrary = {}

do
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local activeNotifications = {}
    local baseBottomOffset = 10
    local spacing = 8
    local slideInDuration = 0.3
    local slideOutDuration = 0.2

    local function rearrangeAll()
        local totalHeight = baseBottomOffset
        for i = #activeNotifications, 1, -1 do
            local notif = activeNotifications[i]
            if notif and notif.frame and notif.frame.Parent then
                local targetY = -totalHeight - notif.frame.Size.Y.Offset
                notif.targetY = targetY
                notif.isAnimating = true
                task.spawn(function()
                    local startTime = tick()
                    local startY = notif.frame.Position.Y.Offset
                    while notif.isAnimating and tick() - startTime < 0.25 do
                        local t = math.min((tick() - startTime) / 0.25, 1)
                        local y = startY + (targetY - startY) * t
                        notif.frame.Position = UDim2.new(1, -265, 1, y)
                        task.wait()
                    end
                    if notif.frame and notif.frame.Parent then
                        notif.frame.Position = UDim2.new(1, -265, 1, targetY)
                    end
                    notif.isAnimating = false
                end)
                totalHeight = totalHeight + notif.frame.Size.Y.Offset + spacing
            end
        end
    end

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

        local notifData = {
            frame = frame,
            targetY = 0,
            isAnimating = false,
            dismissed = false
        }

        local function dismiss()
            if notifData.dismissed then return end
            notifData.dismissed = true
            notifData.isAnimating = false

            for i, v in ipairs(activeNotifications) do
                if v == notifData then
                    table.remove(activeNotifications, i)
                    break
                end
            end

            local startTime = tick()
            local startX = frame.Position.X.Offset
            local startY = frame.Position.Y.Offset
            task.spawn(function()
                while tick() - startTime < slideOutDuration do
                    local t = math.min((tick() - startTime) / slideOutDuration, 1)
                    frame.Position = UDim2.new(1, startX + t * 295, 1, startY)
                    frame.BackgroundTransparency = 0.25 + t * 0.75
                    task.wait()
                end
                frame:Destroy()
                rearrangeAll()
            end)
        end

        closeBtn.MouseButton1Click:Connect(dismiss)
        task.delay(duration, dismiss)

        table.insert(activeNotifications, notifData)

        rearrangeAll()

        local startTime = tick()
        task.spawn(function()
            while not notifData.dismissed and tick() - startTime < slideInDuration do
                local t = math.min((tick() - startTime) / slideInDuration, 1)
                frame.Position = UDim2.new(1, 30 + (1 - t) * -295, 1, notifData.targetY)
                task.wait()
            end
            if not notifData.dismissed and frame.Parent then
                frame.Position = UDim2.new(1, -265, 1, notifData.targetY)
            end
        end)
    end
end

return NotificationLibrary
