local NotificationLibrary = {}

do
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local active = {}
    local BOTTOM = 10
    local GAP = 8
    local X_HIDE = 30
    local X_SHOW = -265

    local function calcTargets()
        local total = BOTTOM
        for i = #active, 1, -1 do
            local n = active[i]
            n.targetY = -total - n.frame.Size.Y.Offset
            total = total + n.frame.Size.Y.Offset + GAP
        end
    end

    local function moveOld()
        for _, n in ipairs(active) do
            if n.frame.Parent and n.targetY ~= n.frame.Position.Y.Offset then
                n.movingY = true
                local startY = n.frame.Position.Y.Offset
                local endY = n.targetY
                local t0 = tick()
                task.spawn(function()
                    while n.movingY and tick() - t0 < 0.25 do
                        local t = math.min((tick() - t0) / 0.25, 1)
                        n.frame.Position = UDim2.new(1, X_SHOW, 1, startY + (endY - startY) * t)
                        task.wait()
                    end
                    if n.frame.Parent then
                        n.frame.Position = UDim2.new(1, X_SHOW, 1, endY)
                    end
                    n.movingY = false
                end)
            end
        end
    end

    function NotificationLibrary:Notify(title, text, duration)
        duration = duration or 4

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 250, 0, 60)
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

        local notif = {
            frame = frame,
            targetY = 0,
            dismissed = false,
            movingY = false
        }

        table.insert(active, notif)
        calcTargets()

        frame.Position = UDim2.new(1, X_HIDE, 1, notif.targetY)

        local function dismiss()
            if notif.dismissed then return end
            notif.dismissed = true
            notif.movingY = false

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
                while tick() - t0 < 0.2 do
                    local t = math.min((tick() - t0) / 0.2, 1)
                    frame.Position = UDim2.new(1, startX + t * 295, 1, startY)
                    frame.BackgroundTransparency = 0.25 + t * 0.75
                    task.wait()
                end
                frame:Destroy()
                calcTargets()
                moveOld()
            end)
        end

        closeBtn.MouseButton1Click:Connect(dismiss)
        task.delay(duration, dismiss)

        moveOld()

        local t0 = tick()
        task.spawn(function()
            while not notif.dismissed and tick() - t0 < 0.3 do
                local t = math.min((tick() - t0) / 0.3, 1)
                frame.Position = UDim2.new(1, X_HIDE + (1 - t) * -295, 1, notif.targetY)
                task.wait()
            end
            if not notif.dismissed and frame.Parent then
                frame.Position = UDim2.new(1, X_SHOW, 1, notif.targetY)
            end
        end)
    end
end

return NotificationLibrary