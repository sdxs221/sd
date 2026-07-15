local NotificationLibrary = {}

do
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SmoothNotifications"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local active = {}
    local PADDING = 8
    local X_HIDDEN = 30
    local X_SHOW = -265
    local SLIDE_TIME = 0.3
    local FADE_TIME = 0.2

    local function refreshPositions()
        local totalHeight = 10
        for i = #active, 1, -1 do
            local n = active[i]
            if n and n.frame and n.frame.Parent then
                n.targetY = -totalHeight - n.frame.Size.Y.Offset
                totalHeight = totalHeight + n.frame.Size.Y.Offset + PADDING
            end
        end

        for _, n in ipairs(active) do
            if n.frame.Parent and not n.dismissed then
                local startY = n.frame.Position.Y.Offset
                local endY = n.targetY
                if startY ~= endY then
                    n.moving = true
                    local t0 = tick()
                    task.spawn(function()
                        while n.moving and tick() - t0 < 0.25 do
                            local alpha = math.min((tick() - t0) / 0.25, 1)
                            n.frame.Position = UDim2.new(1, X_SHOW, 1, startY + (endY - startY) * alpha)
                            task.wait()
                        end
                        if n.frame.Parent then
                            n.frame.Position = UDim2.new(1, X_SHOW, 1, endY)
                        end
                        n.moving = false
                    end)
                end
            end
        end
    end

    function NotificationLibrary:Notify(title, text, duration)
        duration = duration or 4

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 250, 0, 60)
        frame.Position = UDim2.new(1, X_HIDDEN, 1, -75)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.ZIndex = 100
        frame.Parent = screenGui

        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.5
        stroke.Thickness = 1.5

        local titleLabel = Instance.new("TextLabel", frame)
        titleLabel.Size = UDim2.new(1, -30, 0, 20)
        titleLabel.Position = UDim2.new(0, 12, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 13
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left

        local closeBtn = Instance.new("TextButton", frame)
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -24, 0, 6)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        closeBtn.TextSize = 14

        local textLabel = Instance.new("TextLabel", frame)
        textLabel.Size = UDim2.new(1, -24, 0, 24)
        textLabel.Position = UDim2.new(0, 12, 0, 28)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.Gotham
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        textLabel.TextSize = 11
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextWrapped = true

        local notif = {
            frame = frame,
            targetY = 0,
            dismissed = false,
            moving = false
        }

        table.insert(active, notif)
        refreshPositions()
        notif.targetY = active[#active] and active[#active].targetY or -75
        local endY = notif.targetY

        local startTime = tick()
        task.spawn(function()
            while not notif.dismissed and tick() - startTime < SLIDE_TIME do
                local alpha = math.min((tick() - startTime) / SLIDE_TIME, 1)
                frame.Position = UDim2.new(1, X_HIDDEN + alpha * (X_SHOW - X_HIDDEN), 1, endY)
                task.wait()
            end
            if not notif.dismissed and frame.Parent then
                frame.Position = UDim2.new(1, X_SHOW, 1, endY)
            end
        end)

        local function dismiss()
            if notif.dismissed then return end
            notif.dismissed = true
            notif.moving = false

            for i, v in ipairs(active) do
                if v == notif then
                    table.remove(active, i)
                    break
                end
            end

            local startX = frame.Position.X.Offset
            local startY = frame.Position.Y.Offset
            local t0 = tick()
            task.spawn(function()
                while tick() - t0 < FADE_TIME do
                    local alpha = math.min((tick() - t0) / FADE_TIME, 1)
                    frame.Position = UDim2.new(1, startX + alpha * (X_HIDDEN - startX), 1, startY)
                    frame.BackgroundTransparency = 0.2 + alpha * 0.8
                    task.wait()
                end
                frame:Destroy()
                refreshPositions()
            end)
        end

        closeBtn.MouseButton1Click:Connect(dismiss)
        task.delay(duration, dismiss)
    end
end

return NotificationLibrary
