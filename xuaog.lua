local LiquidGlassUI = {}
LiquidGlassUI.__index = LiquidGlassUI
LiquidGlassUI.Version = "1.0.0"
LiquidGlassUI.Windows = {}

local TweenService      = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local HttpService        = game:GetService("HttpService")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Env = {}
Env.writefile     = writefile or (syn and syn.write_file)
Env.readfile      = readfile  or (syn and syn.read_file)
Env.isfile        = isfile    or (syn and syn.is_file)
Env.isfolder      = isfolder  or (syn and syn.is_folder)
Env.makefolder    = makefolder or (syn and syn.create_folder)
Env.getcustomasset = getcustomasset or getsynasset or (syn and syn.request and nil)
Env.httpget       = (game.HttpGet and function(url)
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if ok then return res end
	return nil
end) or nil

Env.Supported = (Env.writefile ~= nil) and (Env.isfile ~= nil) and (Env.getcustomasset ~= nil)

local ROOT_FOLDER = "LiquidGlassUI"
local ICON_FOLDER = ROOT_FOLDER .. "/Icons"
local CFG_FOLDER  = ROOT_FOLDER .. "/Configs"

local function EnsureFolders()
	if not Env.Supported then return end
	local ok = pcall(function()
		if not Env.isfolder(ROOT_FOLDER) then Env.makefolder(ROOT_FOLDER) end
		if not Env.isfolder(ICON_FOLDER) then Env.makefolder(ICON_FOLDER) end
		if not Env.isfolder(CFG_FOLDER) then Env.makefolder(CFG_FOLDER) end
	end)
	return ok
end
EnsureFolders()

local function Create(className, props, children)
	local inst = Instance.new(className)
	if props then
		for prop, value in pairs(props) do
			if prop ~= "Parent" then
				inst[prop] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function Tween(obj, duration, props, style, direction, callback)
	style = style or Enum.EasingStyle.Quint
	direction = direction or Enum.EasingDirection.Out
	local info = TweenInfo.new(duration, style, direction)
	local tw = TweenService:Create(obj, info, props)
	if callback then
		tw.Completed:Once(function()
			callback()
		end)
	end
	tw:Play()
	return tw
end

local function Corner(parent, radius)
	return Create("UICorner", {
		CornerRadius = UDim.new(0, radius or 12),
		Parent = parent,
	})
end

local function Stroke(parent, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Thickness = thickness or 1,
		Transparency = transparency or 0.7,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Padding(parent, top, bottom, left, right)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or top or 0),
		PaddingLeft = UDim.new(0, left or top or 0),
		PaddingRight = UDim.new(0, right or left or top or 0),
		Parent = parent,
	})
end

local function ListLayout(parent, direction, padding, alignX, alignY)
	return Create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 6),
		HorizontalAlignment = alignX or Enum.HorizontalAlignment.Left,
		VerticalAlignment = alignY or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function MakeDraggable(frame, dragHandle)
	dragHandle = dragHandle or frame
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		local goal = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		Tween(frame, 0.06, {Position = goal}, Enum.EasingStyle.Linear)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)

	return function() dragging = false end
end

local function Ripple(button, rippleColor)
	button.ClipsDescendants = true
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		local abs = button.AbsolutePosition
		local size = button.AbsoluteSize
		local circle = Create("Frame", {
			BackgroundColor3 = rippleColor or Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(pos.X - abs.X, pos.Y - abs.Y),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = button.ZIndex + 5,
			Parent = button,
		})
		Corner(circle, 999)
		local maxDim = math.max(size.X, size.Y) * 2
		Tween(circle, 0.5, {
			Size = UDim2.fromOffset(maxDim, maxDim),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
			circle:Destroy()
		end)
	end)
end

local IconCache = {}
local function GetCachedIcon(name, url, fallbackId)
	if IconCache[name] then
		return IconCache[name]
	end
	if not url then
		IconCache[name] = fallbackId or "rbxassetid://0"
		return IconCache[name]
	end
	if Env.Supported then
		EnsureFolders()
		local ext = url:match("%.(%a+)$") or "png"
		local path = ICON_FOLDER .. "/" .. name .. "." .. ext
		local ok = pcall(function()
			if not Env.isfile(path) then
				local data = Env.httpget and Env.httpget(url)
				if data then
					Env.writefile(path, data)
				end
			end
		end)
		if ok and Env.isfile(path) then
			local ok2, asset = pcall(Env.getcustomasset, path)
			if ok2 and asset then
				IconCache[name] = asset
				return asset
			end
		end
	end
	IconCache[name] = fallbackId or "rbxassetid://0"
	return IconCache[name]
end
LiquidGlassUI.GetCachedIcon = GetCachedIcon

local Themes = {
	Purple = {
		Name        = "液态紫玻璃",
		Background  = Color3.fromRGB(18, 16, 26),
		Glass       = Color3.fromRGB(28, 25, 38),
		GlassLight  = Color3.fromRGB(38, 34, 52),
		Accent      = Color3.fromRGB(150, 110, 255),
		AccentDark  = Color3.fromRGB(108, 74, 200),
		Glow        = Color3.fromRGB(139, 92, 246),
		Text        = Color3.fromRGB(240, 238, 245),
		SubText     = Color3.fromRGB(160, 155, 175),
		Stroke      = Color3.fromRGB(255, 255, 255),
		Success     = Color3.fromRGB(96, 210, 150),
		Danger      = Color3.fromRGB(235, 100, 110),
		Warning     = Color3.fromRGB(240, 185, 90),
	},
	Blue = {
		Name        = "液态蓝玻璃",
		Background  = Color3.fromRGB(12, 18, 28),
		Glass       = Color3.fromRGB(20, 30, 44),
		GlassLight  = Color3.fromRGB(28, 42, 60),
		Accent      = Color3.fromRGB(90, 170, 255),
		AccentDark  = Color3.fromRGB(60, 130, 210),
		Glow        = Color3.fromRGB(80, 160, 250),
		Text        = Color3.fromRGB(235, 242, 250),
		SubText     = Color3.fromRGB(150, 165, 185),
		Stroke      = Color3.fromRGB(255, 255, 255),
		Success     = Color3.fromRGB(96, 210, 150),
		Danger      = Color3.fromRGB(235, 100, 110),
		Warning     = Color3.fromRGB(240, 185, 90),
	},
	Rose = {
		Name        = "液态玫瑰玻璃",
		Background  = Color3.fromRGB(24, 14, 20),
		Glass       = Color3.fromRGB(36, 22, 30),
		GlassLight  = Color3.fromRGB(48, 30, 40),
		Accent      = Color3.fromRGB(255, 110, 150),
		AccentDark  = Color3.fromRGB(210, 80, 115),
		Glow        = Color3.fromRGB(245, 100, 140),
		Text        = Color3.fromRGB(250, 238, 242),
		SubText     = Color3.fromRGB(180, 155, 165),
		Stroke      = Color3.fromRGB(255, 255, 255),
		Success     = Color3.fromRGB(96, 210, 150),
		Danger      = Color3.fromRGB(235, 100, 110),
		Warning     = Color3.fromRGB(240, 185, 90),
	},
	Emerald = {
		Name        = "液态翡翠玻璃",
		Background  = Color3.fromRGB(10, 20, 18),
		Glass       = Color3.fromRGB(18, 32, 28),
		GlassLight  = Color3.fromRGB(26, 44, 38),
		Accent      = Color3.fromRGB(80, 220, 160),
		AccentDark  = Color3.fromRGB(50, 175, 120),
		Glow        = Color3.fromRGB(70, 210, 150),
		Text        = Color3.fromRGB(235, 248, 242),
		SubText     = Color3.fromRGB(150, 180, 168),
		Stroke      = Color3.fromRGB(255, 255, 255),
		Success     = Color3.fromRGB(96, 210, 150),
		Danger      = Color3.fromRGB(235, 100, 110),
		Warning     = Color3.fromRGB(240, 185, 90),
	},
	Amber = {
		Name        = "液态琥珀玻璃",
		Background  = Color3.fromRGB(22, 17, 10),
		Glass       = Color3.fromRGB(34, 27, 18),
		GlassLight  = Color3.fromRGB(46, 37, 24),
		Accent      = Color3.fromRGB(255, 180, 80),
		AccentDark  = Color3.fromRGB(210, 140, 55),
		Glow        = Color3.fromRGB(250, 170, 70),
		Text        = Color3.fromRGB(250, 244, 235),
		SubText     = Color3.fromRGB(185, 170, 150),
		Stroke      = Color3.fromRGB(255, 255, 255),
		Success     = Color3.fromRGB(96, 210, 150),
		Danger      = Color3.fromRGB(235, 100, 110),
		Warning     = Color3.fromRGB(240, 185, 90),
	},
}
LiquidGlassUI.Themes = Themes

local Metrics = {
	Font          = Enum.Font.GothamMedium,
	FontBold      = Enum.Font.GothamBold,
	FontSemibold  = Enum.Font.GothamSemibold,
	CornerLarge   = 18,
	CornerMedium  = 12,
	CornerSmall   = 8,
	CornerPill    = 999,
	AnimFast      = 0.18,
	AnimNormal    = 0.28,
	AnimSlow      = 0.45,
}
LiquidGlassUI.Metrics = Metrics

local function ApplyGlass(frame, theme, opts)
	opts = opts or {}
	frame.BackgroundColor3 = opts.Color or theme.Glass
	frame.BackgroundTransparency = opts.Transparency or 0.08
	frame.BorderSizePixel = 0

	Corner(frame, opts.Radius or Metrics.CornerLarge)
	local stroke = Stroke(frame, theme.Stroke, 1, 0.85)

	local gradient = Create("UIGradient", {
		Rotation = 115,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, theme.Glass),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.88),
			NumberSequenceKeypoint.new(0.45, 1),
			NumberSequenceKeypoint.new(0.55, 1),
			NumberSequenceKeypoint.new(1, 0.9),
		}),
		Parent = frame,
	})

	if opts.Animated ~= false then
		task.spawn(function()
			while frame.Parent do
				Tween(gradient, 6, {Rotation = gradient.Rotation + 360}, Enum.EasingStyle.Linear)
				task.wait(6)
			end
		end)
	end

	local shadow = Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Size = UDim2.new(1, 60, 1, 60),
		Position = UDim2.new(0.5, 0, 0.5, 8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = frame.ZIndex - 1,
		Parent = frame.Parent,
	})
	shadow:SetAttribute("__glassShadowFor", frame:GetDebugId())

	return stroke, gradient
end
LiquidGlassUI._ApplyGlass = ApplyGlass

local function AddTooltip(target, text, theme)
	local tip
	target.MouseEnter:Connect(function()
		if tip then tip:Destroy() end
		tip = Create("TextLabel", {
			BackgroundColor3 = theme.Glass,
			BackgroundTransparency = 0.1,
			Text = "  " .. text .. "  ",
			Font = Metrics.Font,
			TextSize = 11,
			TextColor3 = theme.Text,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 20),
			ZIndex = 999,
			Parent = target,
		})
		Corner(tip, 6)
		Stroke(tip, theme.Stroke, 1, 0.8)
		tip.Position = UDim2.new(0.5, 0, 0, -22)
		tip.AnchorPoint = Vector2.new(0.5, 1)
		tip.BackgroundTransparency = 1
		tip.TextTransparency = 1
		Tween(tip, Metrics.AnimFast, {BackgroundTransparency = 0.1, TextTransparency = 0})
	end)
	target.MouseLeave:Connect(function()
		if tip then
			local t = tip
			tip = nil
			Tween(t, Metrics.AnimFast, {BackgroundTransparency = 1, TextTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
				t:Destroy()
			end)
		end
	end)
end
LiquidGlassUI._AddTooltip = AddTooltip

local function CreateNotificationHolder(screenGui)
	return Create("Frame", {
		Name = "NotificationHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.new(0, 300, 1, -40),
		ZIndex = 500,
		Parent = screenGui,
	}, {
		ListLayout(nil, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top),
	})
end

local function PushNotification(holder, theme, title, text, duration, kind)
	duration = duration or 4
	local accentByKind = {
		info = theme.Accent,
		success = theme.Success,
		warning = theme.Warning,
		error = theme.Danger,
	}
	local accent = accentByKind[kind] or theme.Accent

	local card = Create("Frame", {
		BackgroundColor3 = theme.Glass,
		BackgroundTransparency = 0.08,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		LayoutOrder = -os.clock() * 1000,
		Parent = holder,
	})
	Corner(card, Metrics.CornerMedium)
	Stroke(card, theme.Stroke, 1, 0.85)

	Create("Frame", {
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 3, 1, 0),
		BorderSizePixel = 0,
		Parent = card,
	})

	local inner = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 12, 0, 0),
		Parent = card,
	})
	Padding(inner, 10, 10, 0, 8)
	ListLayout(inner, Enum.FillDirection.Vertical, 3)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Metrics.FontBold,
		Text = title or "通知",
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = inner,
	})
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Metrics.Font,
		Text = text or "",
		TextColor3 = theme.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = inner,
	})

	card.Position = UDim2.new(1.3, 0, 0, 0)
	Tween(card, Metrics.AnimNormal, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)

	task.delay(duration, function()
		if not card.Parent then return end
		Tween(card, Metrics.AnimNormal, {Position = UDim2.new(1.3, 0, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
			card:Destroy()
		end)
	end)
end

local function CreateToggleButton(screenGui, theme, iconUrl, onClick)
	local btn = Create("TextButton", {
		Name = "LiquidGlassToggle",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Glass,
		BackgroundTransparency = 0.05,
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.new(0, 24, 0.5, -26),
		ZIndex = 1000,
		Parent = screenGui,
	})
	Corner(btn, 16)
	Stroke(btn, theme.Accent, 1.2, 0.4)

	local glow = Create("UIStroke", {
		Color = theme.Glow,
		Thickness = 2,
		Transparency = 0.6,
		Parent = btn,
	})
	task.spawn(function()
		while btn.Parent do
			Tween(glow, 1.4, {Transparency = 0.15}, Enum.EasingStyle.Sine)
			task.wait(1.4)
			if not btn.Parent then break end
			Tween(glow, 1.4, {Transparency = 0.75}, Enum.EasingStyle.Sine)
			task.wait(1.4)
		end
	end)

	local icon = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = GetCachedIcon("toggle_button", iconUrl, "rbxassetid://10734950309"),
		Size = UDim2.new(0.56, 0, 0.56, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = theme.Text,
		Parent = btn,
	})

	Ripple(btn, theme.Accent)
	MakeDraggable(btn)

	local pressPos
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressPos = input.Position
		end
	end)
	btn.InputEnded:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and pressPos then
			local delta = (input.Position - pressPos).Magnitude
			if delta < 6 then

				Tween(btn, 0.08, {Size = UDim2.fromOffset(46, 46)}, Enum.EasingStyle.Quad)
				task.delay(0.08, function()
					Tween(btn, 0.15, {Size = UDim2.fromOffset(52, 52)}, Enum.EasingStyle.Back)
				end)
				onClick()
			end
			pressPos = nil
		end
	end)

	return btn
end

function LiquidGlassUI:CreateWindow(config)
	config = config or {}
	local theme = type(config.Theme) == "table" and config.Theme or (Themes[config.Theme] or Themes.Purple)

	local screenGui = Create("ScreenGui", {
		Name = "LiquidGlassUI_" .. HttpService:GenerateGUID(false):sub(1, 8),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})
	local ok = pcall(function() screenGui.Parent = CoreGui end)
	if not ok then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

	local blur
	if config.BlurBackground ~= false then
		local Lighting = game:GetService("Lighting")
		blur = Lighting:FindFirstChild("__LiquidGlassBlur")
		if not blur then
			blur = Create("BlurEffect", {
				Name = "__LiquidGlassBlur",
				Size = 0,
				Parent = Lighting,
			})
		end
	end

	local winSize = config.Size or UDim2.fromOffset(760, 480)
	local main = Create("Frame", {
		Name = "MainWindow",
		Size = winSize,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Glass,
		ClipsDescendants = true,
		ZIndex = 100,
		Parent = screenGui,
		Visible = false,
	})
	ApplyGlass(main, theme, {Radius = Metrics.CornerLarge})

	local topBar = Create("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 46),
		ZIndex = 101,
		Parent = main,
	})

	local titleWrap = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Parent = topBar,
	})
	Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 6),
		Font = Metrics.FontBold,
		Text = config.Title or "Liquid Glass",
		TextColor3 = theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleWrap,
	})
	Create("TextLabel", {
		Name = "SubTitle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 25),
		Font = Metrics.Font,
		Text = config.SubTitle or ("v" .. LiquidGlassUI.Version),
		TextColor3 = theme.SubText,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleWrap,
	})

	local controlsWrap = Create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, 23),
		Size = UDim2.new(0, 70, 0, 28),
		Parent = topBar,
	}, {
		ListLayout(nil, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
	})

	local function MakeTopBtn(glyph)
		local b = Create("TextButton", {
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = theme.GlassLight,
			BackgroundTransparency = 0.15,
			Text = glyph,
			TextColor3 = theme.SubText,
			Font = Metrics.FontBold,
			TextSize = 14,
			AutoButtonColor = false,
			Parent = controlsWrap,
		})
		Corner(b, Metrics.CornerSmall)
		Ripple(b, theme.Accent)
		return b
	end
	local minimizeBtn = MakeTopBtn("–")
	local closeBtn = MakeTopBtn("×")

	MakeDraggable(main, topBar)

	Create("Frame", {
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 0, 46),
		Parent = main,
	})

	local topTabStrip = Create("Frame", {
		Name = "TopTabStrip",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 50),
		Size = UDim2.new(1, -24, 0, 30),
		ZIndex = 101,
		Parent = main,
	})
	local topTabList = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -30, 1, 0),
		Parent = topTabStrip,
	}, {
		ListLayout(nil, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
	})
	local addTopTabBtn = Create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = theme.GlassLight,
		BackgroundTransparency = 0.2,
		Text = "+",
		TextColor3 = theme.SubText,
		Font = Metrics.FontBold,
		TextSize = 16,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		Parent = topTabStrip,
	})
	Corner(addTopTabBtn, Metrics.CornerSmall)
	Ripple(addTopTabBtn, theme.Accent)
	addTopTabBtn.MouseButton1Click:Connect(function()
		if config.OnNewTopTab then task.spawn(config.OnNewTopTab) end
	end)

	local topTabs = {}
	local function CreateTopTab(name, icon, onSelect)
		local tb = Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.GlassLight,
			BackgroundTransparency = 0.3,
			Text = "",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = topTabList,
		})
		Corner(tb, Metrics.CornerSmall)
		local pad = Padding(tb, 0, 0, 10, 10)
		local row = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = tb,
		}, {
			ListLayout(nil, Enum.FillDirection.Horizontal, 5, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
		})
		if icon then
			Create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(14, 14),
				Image = GetCachedIcon("toptab_" .. name, icon, "rbxassetid://10734950309"),
				ImageColor3 = theme.SubText,
				ScaleType = Enum.ScaleType.Fit,
				Parent = row,
			})
		end
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Font = Metrics.FontSemibold,
			Text = name,
			TextColor3 = theme.Text,
			TextSize = 12,
			Parent = row,
		})
		Ripple(tb, theme.Accent)

		local entry = {Button = tb}
		local function SelectTopTab()
			for _, t in ipairs(topTabs) do
				Tween(t.Button, Metrics.AnimFast, {
					BackgroundTransparency = (t == entry) and 0.05 or 0.3,
				})
			end
			if onSelect then task.spawn(onSelect) end
		end
		entry.Select = SelectTopTab
		tb.MouseButton1Click:Connect(SelectTopTab)
		topTabs[#topTabs + 1] = entry
		if #topTabs == 1 then SelectTopTab() end
		return entry
	end

	Create("Frame", {
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 0, 80),
		Parent = main,
	})

	local searchBox = Create("TextBox", {
		Name = "SidebarSearch",
		BackgroundColor3 = theme.GlassLight,
		BackgroundTransparency = 0.3,
		Position = UDim2.new(0, 12, 0, 90),
		Size = UDim2.new(0, 168, 0, 26),
		Text = "",
		PlaceholderText = "搜索…",
		PlaceholderColor3 = theme.SubText,
		TextColor3 = theme.Text,
		Font = Metrics.Font,
		TextSize = 12,
		ClearTextOnFocus = false,
		ZIndex = 101,
		Parent = main,
	})
	Corner(searchBox, Metrics.CornerSmall)
	Stroke(searchBox, theme.Stroke, 1, 0.85)
	Padding(searchBox, 0, 0, 8, 8)

	local sidebar = Create("ScrollingFrame", {
		Name = "Sidebar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 122),
		Size = UDim2.new(0, 168, 1, -134),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarImageTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 101,
		Parent = main,
	})
	ListLayout(sidebar, Enum.FillDirection.Vertical, 4)

	Create("Frame", {
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 1, 1, -102),
		Position = UDim2.new(0, 188, 0, 90),
		Parent = main,
	})

	local pageContainer = Create("Frame", {
		Name = "PageContainer",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 200, 0, 90),
		Size = UDim2.new(1, -212, 1, -102),
		ZIndex = 101,
		Parent = main,
	})

	local bottomBar = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 1, -14),
		Size = UDim2.new(1, -24, 0, 10),
		ZIndex = 101,
		Parent = main,
	})
	Create("Frame", {
		BackgroundColor3 = theme.SubText,
		BackgroundTransparency = 0.6,
		Size = UDim2.new(0.4, 0, 0, 3),
		Position = UDim2.new(0.3, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		Parent = bottomBar,
	}, {Corner(nil, 2)})

	local notifHolder = CreateNotificationHolder(screenGui)

	local isOpen = false
	local function SetOpen(open, animate)
		isOpen = open
		if open then
			main.Visible = true
			main.Size = UDim2.new(winSize.X.Scale, 0, winSize.Y.Scale, 0)
			main.BackgroundTransparency = 1
			if animate == false then
				main.Size = winSize
				main.BackgroundTransparency = 0.08
			else
				Tween(main, Metrics.AnimSlow, {
					Size = winSize,
					BackgroundTransparency = 0.08,
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
			if blur then Tween(blur, Metrics.AnimSlow, {Size = 14}) end
		else
			if blur then Tween(blur, Metrics.AnimFast, {Size = 0}) end
			Tween(main, Metrics.AnimNormal, {
				Size = UDim2.new(winSize.X.Scale, 0, winSize.Y.Scale, 0),
				BackgroundTransparency = 1,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
				main.Visible = false
			end)
		end
	end

	local toggleBtn = CreateToggleButton(screenGui, theme, config.ToggleIcon, function()
		SetOpen(not isOpen)
	end)
	closeBtn.MouseButton1Click:Connect(function() SetOpen(false) end)
	minimizeBtn.MouseButton1Click:Connect(function() SetOpen(false) end)

	local toggleKey = config.ToggleKeybind or Enum.KeyCode.RightControl
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then
			SetOpen(not isOpen)
		end
	end)

	local Window = setmetatable({
		_screenGui = screenGui,
		_main = main,
		_sidebar = sidebar,
		_pageContainer = pageContainer,
		_theme = theme,
		_tabs = {},
		_firstTab = nil,
		_notifHolder = notifHolder,
		Open = function(self) SetOpen(true) end,
		Close = function(self) SetOpen(false) end,
		CreateTopTab = function(self, name, icon, onSelect) return CreateTopTab(name, icon, onSelect) end,
	}, LiquidGlassUI)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchBox.Text:lower()
		for _, t in ipairs(Window._tabs) do
			if query == "" then
				t._button.Visible = true
			else
				t._button.Visible = t._button.Name:lower():find(query, 1, true) ~= nil
					or t._text.Text:lower():find(query, 1, true) ~= nil
			end
		end
	end)

	LiquidGlassUI.Windows[#LiquidGlassUI.Windows + 1] = Window

	if not config.NoBuiltinSettings then
		Window:_InstallBuiltinSettingsTab(config)
	end

	SetOpen(true)
	return Window
end

function LiquidGlassUI:Notify(title, text, duration, kind)
	PushNotification(self._notifHolder, self._theme, title, text, duration, kind)
end

function LiquidGlassUI:Destroy()
	if self._screenGui then self._screenGui:Destroy() end
end

function LiquidGlassUI:CreateTab(name, icon)
	local theme = self._theme

	local tabBtn = Create("TextButton", {
		Name = "Tab_" .. name,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = theme.GlassLight,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = self._sidebar,
	})
	Corner(tabBtn, Metrics.CornerSmall)

	local iconLabel = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(16, 16),
		Image = GetCachedIcon("tab_" .. name, icon, "rbxassetid://10734953487"),
		ImageColor3 = theme.SubText,
		ScaleType = Enum.ScaleType.Fit,
		Parent = tabBtn,
	})
	local textLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 34, 0, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Font = Metrics.FontSemibold,
		Text = name,
		TextColor3 = theme.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tabBtn,
	})

	local page = Create("ScrollingFrame", {
		Name = "Page_" .. name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		BorderSizePixel = 0,
		Visible = false,
		Parent = self._pageContainer,
	})
	Padding(page, 4, 16, 4, 10)
	ListLayout(page, Enum.FillDirection.Vertical, 10)

	local tabObj = {
		_button = tabBtn,
		_icon = iconLabel,
		_text = textLabel,
		_page = page,
		_window = self,
		_theme = theme,
	}
	self._tabs[#self._tabs + 1] = tabObj

	local function SelectTab()
		for _, t in ipairs(self._tabs) do
			local selected = (t == tabObj)
			t._page.Visible = selected
			Tween(t._button, Metrics.AnimFast, {
				BackgroundTransparency = selected and 0.1 or 1,
			})
			Tween(t._icon, Metrics.AnimFast, {
				ImageColor3 = selected and theme.Accent or theme.SubText,
			})
			Tween(t._text, Metrics.AnimFast, {
				TextColor3 = selected and theme.Text or theme.SubText,
			})
		end

		page.Position = UDim2.new(0, 8, 0, 0)
		local goalPos = UDim2.new(0, 0, 0, 0)
		page.Position = UDim2.new(0, 8, 0, 0)
		for _, child in ipairs(page:GetChildren()) do
			if child:IsA("GuiObject") then
				child.BackgroundTransparency = 1
			end
		end
		Tween(page, Metrics.AnimNormal, {Position = goalPos})
	end

	tabBtn.MouseButton1Click:Connect(SelectTab)
	Ripple(tabBtn, theme.Accent)

	if not self._firstTab then
		self._firstTab = tabObj
		SelectTab()
	end

	function tabObj:CreateSection(text)
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			Font = Metrics.FontBold,
			Text = text,
			TextColor3 = theme.SubText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = page,
		})
	end

	function tabObj:CreateLabel(text)
		local lbl = Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Metrics.Font,
			Text = text,
			TextColor3 = theme.SubText,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = page,
		})
		return lbl
	end

	local function BaseCard(title, desc, controlWidth)
		local card = Create("Frame", {
			BackgroundColor3 = theme.GlassLight,
			BackgroundTransparency = 0.35,
			Size = UDim2.new(1, 0, 0, desc and 52 or 40),
			Parent = page,
		})
		Corner(card, Metrics.CornerMedium)
		Stroke(card, theme.Stroke, 1, 0.9)

		local textWrap = Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -(controlWidth + 32), 1, 0),
			Parent = card,
		})
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, desc and 0.55 or 1, 0),
			Font = Metrics.FontSemibold,
			Text = title,
			TextColor3 = theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = textWrap,
		})
		if desc then
			Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0.45, 0),
				Position = UDim2.new(0, 0, 0.55, 0),
				Font = Metrics.Font,
				Text = desc,
				TextColor3 = theme.SubText,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Parent = textWrap,
			})
		end

		local controlWrap = Create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, controlWidth, 0, controlWidth == 40 and 22 or 30),
			Parent = card,
		})
		return card, controlWrap
	end
	tabObj._BaseCard = BaseCard

	function tabObj:CreateToggle(text, desc, default, callback)
		local card, wrap = BaseCard(text, desc, 40)
		default = default and true or false

		local track = Create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = default and theme.Accent or theme.GlassLight,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = wrap,
		})
		Corner(track, Metrics.CornerPill)
		local trackStroke = Stroke(track, theme.Stroke, 1, 0.85)

		local knob = Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromOffset(16, 16),
			Position = default and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = track,
		})
		Corner(knob, Metrics.CornerPill)

		local state = default
		local function Render(animated)
			local goalPos = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			local goalColor = state and theme.Accent or theme.GlassLight
			if animated == false then
				knob.Position = goalPos
				track.BackgroundColor3 = goalColor
			else
				Tween(knob, Metrics.AnimFast, {Position = goalPos}, Enum.EasingStyle.Back)
				Tween(track, Metrics.AnimFast, {BackgroundColor3 = goalColor})
			end
		end

		track.MouseButton1Click:Connect(function()
			state = not state
			Render(true)
			task.spawn(callback, state)
		end)

		if default then task.spawn(callback, true) end

		return {
			Set = function(_, v) state = v and true or false; Render(true) end,
			Get = function() return state end,
			Instance = card,
		}
	end

	function tabObj:CreateButton(text, desc, iconUrl, callback)
		local card, wrap = BaseCard(text, desc, 72)

		local btn = Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.Accent,
			Text = "",
			Size = UDim2.new(1, 0, 1, 0),
			Parent = wrap,
		})
		Corner(btn, Metrics.CornerSmall)

		local hasIcon = iconUrl ~= nil
		local iconImg
		if hasIcon then
			iconImg = Create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Image = "",
				Parent = btn,
			})

			task.spawn(function()
				local asset = GetCachedIcon("btn_" .. text, iconUrl, "rbxassetid://10747384394")
				iconImg.Image = asset
			end)
		end

		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, hasIcon and -30 or -10, 1, 0),
			Position = UDim2.new(0, hasIcon and 30 or 10, 0, 0),
			Font = Metrics.FontSemibold,
			Text = "执行",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextXAlignment = hasIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
			Parent = btn,
		})

		Ripple(btn, Color3.fromRGB(255, 255, 255))
		btn.MouseButton1Click:Connect(function()
			task.spawn(callback)
		end)

		return {Instance = card}
	end

	function tabObj:CreateDropdown(text, desc, options, default, callback)
		local card, wrap = BaseCard(text, desc, 130)
		card.ClipsDescendants = false

		local selected = default or options[1]

		local head = Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.GlassLight,
			Text = "",
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 5,
			Parent = wrap,
		})
		Corner(head, Metrics.CornerSmall)
		Stroke(head, theme.Stroke, 1, 0.85)

		local headLabel = Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -28, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),
			Font = Metrics.Font,
			Text = selected,
			TextColor3 = theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 5,
			Parent = head,
		})
		local chevron = Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.new(1, -22, 0.5, -9),
			Font = Metrics.FontBold,
			Text = "⌄",
			TextColor3 = theme.SubText,
			TextSize = 14,
			ZIndex = 5,
			Parent = head,
		})

		local panel = Create("Frame", {
			BackgroundColor3 = theme.Glass,
			Position = UDim2.new(0, 0, 1, 6),
			Size = UDim2.new(1, 0, 0, 0),
			ClipsDescendants = true,
			Visible = false,
			ZIndex = 50,
			Parent = wrap,
		})
		Corner(panel, Metrics.CornerSmall)
		Stroke(panel, theme.Stroke, 1, 0.8)
		local panelList = ListLayout(panel, Enum.FillDirection.Vertical, 2)
		Padding(panel, 4, 4, 4, 4)

		local optionButtons = {}
		local function RefreshOptions(newOptions)
			for _, b in ipairs(optionButtons) do b:Destroy() end
			table.clear(optionButtons)
			for _, opt in ipairs(newOptions) do
				local ob = Create("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = theme.Accent,
					BackgroundTransparency = (opt == selected) and 0.55 or 1,
					Size = UDim2.new(1, 0, 0, 26),
					Text = "",
					ZIndex = 51,
					Parent = panel,
				})
				Corner(ob, Metrics.CornerSmall - 2)
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -10, 1, 0),
					Position = UDim2.new(0, 8, 0, 0),
					Font = Metrics.Font,
					Text = opt,
					TextColor3 = theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 51,
					Parent = ob,
				})
				ob.MouseButton1Click:Connect(function()
					selected = opt
					headLabel.Text = selected
					for _, other in ipairs(optionButtons) do
						other.BackgroundTransparency = 1
					end
					ob.BackgroundTransparency = 0.55
					task.spawn(callback, selected)
				end)
				optionButtons[#optionButtons + 1] = ob
			end
		end
		RefreshOptions(options)

		local expanded = false
		local function SetExpanded(v)
			expanded = v
			if v then
				panel.Visible = true
				local goalHeight = math.min(#options, 5) * 28 + 8
				Tween(panel, Metrics.AnimFast, {Size = UDim2.new(1, 0, 0, goalHeight)})
				Tween(chevron, Metrics.AnimFast, {Rotation = 180})
			else
				Tween(panel, Metrics.AnimFast, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
					panel.Visible = false
				end)
				Tween(chevron, Metrics.AnimFast, {Rotation = 0})
			end
		end
		head.MouseButton1Click:Connect(function() SetExpanded(not expanded) end)

		return {
			Set = function(_, v) selected = v; headLabel.Text = v end,
			Get = function() return selected end,
			Refresh = function(_, newOptions) RefreshOptions(newOptions) end,
			Instance = card,
		}
	end

	function tabObj:CreateSlider(text, desc, min, max, default, callback)
		local card, wrap = BaseCard(text, desc, 150)
		local value = math.clamp(default or min, min, max)

		local valueLabel = Create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, -18),
			Size = UDim2.fromOffset(50, 14),
			Font = Metrics.FontSemibold,
			Text = tostring(value),
			TextColor3 = theme.Accent,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = wrap,
		})

		local track = Create("Frame", {
			BackgroundColor3 = theme.GlassLight,
			Size = UDim2.new(1, 0, 0, 6),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = wrap,
		})
		Corner(track, Metrics.CornerPill)

		local fill = Create("Frame", {
			BackgroundColor3 = theme.Accent,
			Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
			Parent = track,
		})
		Corner(fill, Metrics.CornerPill)

		local knob = Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromOffset(14, 14),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
			ZIndex = 6,
			Parent = track,
		})
		Corner(knob, Metrics.CornerPill)
		Stroke(knob, theme.Accent, 2, 0.2)

		local dragging = false
		local function SetFromAlpha(alpha)
			alpha = math.clamp(alpha, 0, 1)
			value = math.floor(min + (max - min) * alpha + 0.5)
			local a = (value - min) / (max - min)
			fill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
			valueLabel.Text = tostring(value)
			task.spawn(callback, value)
		end

		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
				SetFromAlpha(rel)
			end
		end)
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
				SetFromAlpha(rel)
			end
		end)

		return {
			Set = function(_, v) SetFromAlpha((v - min) / (max - min)) end,
			Get = function() return value end,
			Instance = card,
		}
	end

	function tabObj:CreateColorPicker(text, desc, default, callback)
		local card, wrap = BaseCard(text, desc, 40)
		default = default or Color3.fromRGB(150, 110, 255)

		local swatch = Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = default,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			Parent = wrap,
		})
		Corner(swatch, Metrics.CornerSmall)
		Stroke(swatch, theme.Stroke, 1, 0.7)

		local popup = Create("Frame", {
			BackgroundColor3 = theme.Glass,
			Size = UDim2.fromOffset(200, 190),
			Position = UDim2.new(1, -200, 1, 8),
			Visible = false,
			ZIndex = 200,
			Parent = card,
		})
		Corner(popup, Metrics.CornerMedium)
		Stroke(popup, theme.Stroke, 1, 0.75)
		Padding(popup, 10, 10, 10, 10)

		local h, s, v = default:ToHSV()

		local svBox = Create("Frame", {
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			Size = UDim2.new(1, 0, 0, 110),
			ZIndex = 201,
			Parent = popup,
		})
		Corner(svBox, Metrics.CornerSmall)
		Create("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
			Transparency = NumberSequence.new(0, 1),
			Parent = svBox,
		})
		local blackOverlay = Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 202,
			Parent = svBox,
		})
		Corner(blackOverlay, Metrics.CornerSmall)
		Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
			Transparency = NumberSequence.new(1, 0),
			Parent = blackOverlay,
		})

		local svCursor = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(10, 10),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(s, 0, 1 - v, 0),
			ZIndex = 203,
			Parent = svBox,
		})
		Corner(svCursor, Metrics.CornerPill)
		Stroke(svCursor, Color3.fromRGB(255, 255, 255), 2, 0)

		local hueBar = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0, 120),
			ZIndex = 201,
			Parent = popup,
		})
		Corner(hueBar, Metrics.CornerPill)
		Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0/6, 1, 1)),
				ColorSequenceKeypoint.new(0.166, Color3.fromHSV(1/6, 1, 1)),
				ColorSequenceKeypoint.new(0.333, Color3.fromHSV(2/6, 1, 1)),
				ColorSequenceKeypoint.new(0.500, Color3.fromHSV(3/6, 1, 1)),
				ColorSequenceKeypoint.new(0.666, Color3.fromHSV(4/6, 1, 1)),
				ColorSequenceKeypoint.new(0.833, Color3.fromHSV(5/6, 1, 1)),
				ColorSequenceKeypoint.new(1.000, Color3.fromHSV(6/6, 1, 1)),
			}),
			Parent = hueBar,
		})
		local hueCursor = Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromOffset(4, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(h, 0, 0.5, 0),
			ZIndex = 202,
			Parent = hueBar,
		})
		Corner(hueCursor, 2)

		local hexLabel = Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0, 145),
			Font = Metrics.Font,
			Text = default:ToHex():upper(),
			TextColor3 = theme.SubText,
			TextSize = 11,
			ZIndex = 201,
			Parent = popup,
		})

		local function Refresh()
			local color = Color3.fromHSV(h, s, v)
			swatch.BackgroundColor3 = color
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			hexLabel.Text = "#" .. color:ToHex():upper()
			task.spawn(callback, color)
		end

		local draggingSV, draggingHue = false, false
		svBox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingSV = true
			end
		end)
		hueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingHue = true
			end
		end)
		UserInputService.InputEnded:Connect(function()
			draggingSV = false
			draggingHue = false
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if draggingSV then
				local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
				local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
				s, v = rx, 1 - ry
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				Refresh()
			elseif draggingHue then
				local rx = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
				h = rx
				hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
				Refresh()
			end
		end)

		local popupOpen = false
		swatch.MouseButton1Click:Connect(function()
			popupOpen = not popupOpen
			popup.Visible = popupOpen
			if popupOpen then
				popup.Size = UDim2.fromOffset(200, 0)
				Tween(popup, Metrics.AnimFast, {Size = UDim2.fromOffset(200, 190)})
			end
		end)

		return {
			Set = function(_, color)
				h, s, v = color:ToHSV()
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
				Refresh()
			end,
			Get = function() return Color3.fromHSV(h, s, v) end,
			Instance = card,
		}
	end

	function tabObj:CreateKeybind(text, desc, default, callback)
		local card, wrap = BaseCard(text, desc, 90)
		local currentKey = default

		local btn = Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.GlassLight,
			Text = currentKey and currentKey.Name or "...",
			TextColor3 = theme.Text,
			Font = Metrics.FontSemibold,
			TextSize = 12,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = wrap,
		})
		Corner(btn, Metrics.CornerSmall)
		Stroke(btn, theme.Stroke, 1, 0.85)

		local listening = false
		btn.MouseButton1Click:Connect(function()
			listening = true
			btn.Text = "..."
			Tween(btn, Metrics.AnimFast, {BackgroundColor3 = theme.Accent})
		end)

		UserInputService.InputBegan:Connect(function(input, gpe)
			if not listening then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = input.KeyCode
				btn.Text = currentKey.Name
				listening = false
				Tween(btn, Metrics.AnimFast, {BackgroundColor3 = theme.GlassLight})
			end
		end)

		UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe or listening then return end
			if currentKey and input.KeyCode == currentKey then
				task.spawn(callback, true)
			end
		end)

		return {
			Set = function(_, key) currentKey = key; btn.Text = key.Name end,
			Get = function() return currentKey end,
			Instance = card,
		}
	end

	function tabObj:CreateTextbox(text, desc, placeholder, callback)
		local card, wrap = BaseCard(text, desc, 140)

		local box = Create("TextBox", {
			BackgroundColor3 = theme.GlassLight,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			PlaceholderText = placeholder or "",
			PlaceholderColor3 = theme.SubText,
			TextColor3 = theme.Text,
			Font = Metrics.Font,
			TextSize = 12,
			ClearTextOnFocus = false,
			Parent = wrap,
		})
		Corner(box, Metrics.CornerSmall)
		local boxStroke = Stroke(box, theme.Stroke, 1, 0.85)
		Padding(box, 0, 0, 8, 8)

		box.Focused:Connect(function()
			Tween(boxStroke, Metrics.AnimFast, {Color = theme.Accent, Transparency = 0.2})
		end)
		box.FocusLost:Connect(function(enterPressed)
			Tween(boxStroke, Metrics.AnimFast, {Color = theme.Stroke, Transparency = 0.85})
			task.spawn(callback, box.Text, enterPressed)
		end)

		return {
			Set = function(_, v) box.Text = v end,
			Get = function() return box.Text end,
			Instance = card,
		}
	end

	function tabObj:CreateDivider()
		Create("Frame", {
			BackgroundColor3 = theme.Stroke,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			Parent = page,
		})
	end

	function tabObj:CreateParagraph(title, content)
		local card = Create("Frame", {
			BackgroundColor3 = theme.GlassLight,
			BackgroundTransparency = 0.4,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = page,
		})
		Corner(card, Metrics.CornerMedium)
		Stroke(card, theme.Stroke, 1, 0.9)
		local inner = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -24, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.new(0, 12, 0, 0),
			Parent = card,
		})
		Padding(inner, 10, 10, 0, 0)
		ListLayout(inner, Enum.FillDirection.Vertical, 4)
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = Metrics.FontBold,
			Text = title,
			TextColor3 = theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = inner,
		})
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Metrics.Font,
			Text = content,
			TextColor3 = theme.SubText,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = inner,
		})
		return card
	end

	function tabObj:CreateAccordion(title)
		local header = Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.GlassLight,
			BackgroundTransparency = 0.35,
			Text = "",
			Size = UDim2.new(1, 0, 0, 34),
			Parent = page,
		})
		Corner(header, Metrics.CornerMedium)
		Stroke(header, theme.Stroke, 1, 0.9)
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -34, 1, 0),
			Font = Metrics.FontSemibold,
			Text = title,
			TextColor3 = theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = header,
		})
		local chevron = Create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Font = Metrics.FontBold,
			Text = "⌄",
			TextColor3 = theme.SubText,
			TextSize = 14,
			Parent = header,
		})
		Ripple(header, theme.Accent)

		local body = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			ClipsDescendants = true,
			Visible = false,
			Parent = page,
		})
		local bodyInner = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = body,
		})
		Padding(bodyInner, 8, 0, 10, 0)
		ListLayout(bodyInner, Enum.FillDirection.Vertical, 8)

		local subTab = setmetatable({}, {__index = tabObj})
		local originalPage = page

		local function ChildBaseCard(title2, desc2, controlWidth)
			local card = Create("Frame", {
				BackgroundColor3 = theme.Glass,
				BackgroundTransparency = 0.2,
				Size = UDim2.new(1, 0, 0, desc2 and 52 or 40),
				Parent = bodyInner,
			})
			Corner(card, Metrics.CornerMedium)
			Stroke(card, theme.Stroke, 1, 0.9)
			local textWrap = Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -(controlWidth + 32), 1, 0),
				Parent = card,
			})
			Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, desc2 and 0.55 or 1, 0),
				Font = Metrics.FontSemibold,
				Text = title2,
				TextColor3 = theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = textWrap,
			})
			if desc2 then
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0.45, 0),
					Position = UDim2.new(0, 0, 0.55, 0),
					Font = Metrics.Font,
					Text = desc2,
					TextColor3 = theme.SubText,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Parent = textWrap,
				})
			end
			local controlWrap = Create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, controlWidth, 0, controlWidth == 40 and 22 or 30),
				Parent = card,
			})
			return card, controlWrap
		end

		function subTab:CreateToggle(t, d, default, callback)
			local card, wrap = ChildBaseCard(t, d, 40)
			local state = default and true or false
			local track = Create("TextButton", {
				Text = "", AutoButtonColor = false,
				BackgroundColor3 = state and theme.Accent or theme.GlassLight,
				Size = UDim2.new(1, 0, 1, 0), Parent = wrap,
			})
			Corner(track, Metrics.CornerPill)
			Stroke(track, theme.Stroke, 1, 0.85)
			local knob = Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.fromOffset(16, 16),
				Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5), Parent = track,
			})
			Corner(knob, Metrics.CornerPill)
			track.MouseButton1Click:Connect(function()
				state = not state
				Tween(knob, Metrics.AnimFast, {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, Enum.EasingStyle.Back)
				Tween(track, Metrics.AnimFast, {BackgroundColor3 = state and theme.Accent or theme.GlassLight})
				task.spawn(callback, state)
			end)
			return {Get = function() return state end, Instance = card}
		end

		function subTab:CreateButton(t, d, iconUrl, callback)
			local card, wrap = ChildBaseCard(t, d, 60)
			local btn = Create("TextButton", {
				AutoButtonColor = false, BackgroundColor3 = theme.Accent,
				Text = "执行", TextColor3 = Color3.fromRGB(255,255,255),
				Font = Metrics.FontSemibold, TextSize = 12,
				Size = UDim2.new(1, 0, 1, 0), Parent = wrap,
			})
			Corner(btn, Metrics.CornerSmall)
			Ripple(btn, Color3.fromRGB(255, 255, 255))
			btn.MouseButton1Click:Connect(function() task.spawn(callback) end)
			return {Instance = card}
		end

		local expanded = false
		header.MouseButton1Click:Connect(function()
			expanded = not expanded
			if expanded then
				body.Visible = true
				bodyInner:GetPropertyChangedSignal("AbsoluteSize")
				task.defer(function()
					Tween(body, Metrics.AnimNormal, {Size = UDim2.new(1, 0, 0, bodyInner.AbsoluteSize.Y)})
				end)
				Tween(chevron, Metrics.AnimFast, {Rotation = 180})
			else
				Tween(body, Metrics.AnimFast, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
					body.Visible = false
				end)
				Tween(chevron, Metrics.AnimFast, {Rotation = 0})
			end
		end)

		return subTab
	end

	function tabObj:CreateTable(headers, rows)
		local card = Create("Frame", {
			BackgroundColor3 = theme.GlassLight,
			BackgroundTransparency = 0.3,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = page,
		})
		Corner(card, Metrics.CornerMedium)
		Stroke(card, theme.Stroke, 1, 0.9)
		Padding(card, 8, 8, 8, 8)
		local vlist = ListLayout(card, Enum.FillDirection.Vertical, 2)

		local colCount = #headers
		local function MakeRow(cells, isHeader)
			local row = Create("Frame", {
				BackgroundColor3 = theme.Accent,
				BackgroundTransparency = isHeader and 0.75 or 1,
				Size = UDim2.new(1, 0, 0, 24),
				Parent = card,
			})
			if isHeader then Corner(row, 6) end
			local rlist = Create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = row,
			})
			ListLayout(rlist, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
			for i = 1, colCount do
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1 / colCount, -4, 1, 0),
					Font = isHeader and Metrics.FontBold or Metrics.Font,
					Text = tostring(cells[i] or ""),
					TextColor3 = isHeader and theme.Accent or theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = rlist,
				})
			end
			return row
		end

		MakeRow(headers, true)
		local rowInstances = {}
		for _, r in ipairs(rows or {}) do
			rowInstances[#rowInstances + 1] = MakeRow(r, false)
		end

		return {
			Instance = card,
			AddRow = function(_, cells) rowInstances[#rowInstances + 1] = MakeRow(cells, false) end,
			Clear = function(_)
				for _, r in ipairs(rowInstances) do r:Destroy() end
				table.clear(rowInstances)
			end,
		}
	end

	return tabObj
end

function LiquidGlassUI:_InstallBuiltinSettingsTab(config)
	local theme = self._theme
	local SettingsTab = self:CreateTab("设置", "settings")

	SettingsTab:CreateSection("外观")
	SettingsTab:CreateParagraph(
		"液态玻璃主题",
		"点击下方色板切换整体配色。"
	)

	local grid = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 46),
		Parent = SettingsTab._page,
	})
	local order = {"Purple", "Blue", "Rose", "Emerald", "Amber"}
	ListLayout(grid, Enum.FillDirection.Horizontal, 10)
	for _, key in ipairs(order) do
		local t = Themes[key]
		local swatch = Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = t.Accent,
			Text = "",
			Size = UDim2.fromOffset(40, 40),
			Parent = grid,
		})
		Corner(swatch, Metrics.CornerMedium)
		Stroke(swatch, Color3.fromRGB(255, 255, 255), 2, (t == theme) and 0.2 or 0.85)
		Ripple(swatch, Color3.fromRGB(255, 255, 255))
		swatch.MouseButton1Click:Connect(function()
			self:SetTheme(key)
			self:Notify("主题已切换", t.Name, 2, "success")
		end)
	end

	SettingsTab:CreateSection("窗口")
	SettingsTab:CreateToggle("背景模糊", "打开面板时是否模糊游戏背景画面", config.BlurBackground ~= false, function(state)
		local Lighting = game:GetService("Lighting")
		local blur = Lighting:FindFirstChild("__LiquidGlassBlur")
		if blur then blur.Size = state and 14 or 0 end
	end)

	local rainbowRunning = false
	SettingsTab:CreateToggle("彩虹流光边框", "让主窗口边框颜色循环变化（液态流光效果）", false, function(state)
		rainbowRunning = state
		if state then
			task.spawn(function()
				local hue = 0
				while rainbowRunning and self._main.Parent do
					hue = (hue + 0.004) % 1
					local c = Color3.fromHSV(hue, 0.65, 1)
					for _, child in ipairs(self._main:GetChildren()) do
						if child:IsA("UIStroke") then
							child.Color = c
						end
					end
					RunService.RenderStepped:Wait()
				end
			end)
		end
	end)
	SettingsTab:CreateLabel("提示：按下 " .. (tostring(config.ToggleKeybind or Enum.KeyCode.RightControl).Name) .. " 键可快速开关本面板，悬浮按钮也可拖拽到任意位置。")

	SettingsTab:CreateSection("配置管理")
	local cfgNameBox = SettingsTab:CreateTextbox("配置名称", "保存/读取时使用的文件名", "default", function() end)
	SettingsTab:CreateButton("保存当前配置", "写入到执行器目录 LiquidGlassUI/Configs/", nil, function()
		self:SaveConfig(cfgNameBox:Get() ~= "" and cfgNameBox:Get() or "default", {savedAt = os.time()})
	end)
	SettingsTab:CreateButton("读取配置", "从执行器目录读取并打印到控制台", nil, function()
		local data = self:LoadConfig(cfgNameBox:Get() ~= "" and cfgNameBox:Get() or "default")
		if data then
			self:Notify("读取成功", "配置已读取，详情见控制台", 3, "success")
			print("[LiquidGlassUI] LoadConfig ->", HttpService:JSONEncode(data))
		else
			self:Notify("读取失败", "未找到对应配置文件", 3, "error")
		end
	end)

	SettingsTab:CreateSection("关于")
	SettingsTab:CreateParagraph("LiquidGlassUI", "版本 " .. LiquidGlassUI.Version .. "  ·  1")

	return SettingsTab
end

function LiquidGlassUI:SetTheme(themeNameOrTable)
	local theme = type(themeNameOrTable) == "table" and themeNameOrTable or Themes[themeNameOrTable]
	if not theme then return end
	self._theme = theme
	self._main.BackgroundColor3 = theme.Glass
end

function LiquidGlassUI:SaveConfig(name, dataTable)
	if not Env.Supported then
		self:Notify("保存失败", "当前环境不支持文件写入", 3, "error")
		return false
	end
	EnsureFolders()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, dataTable)
	if not ok then return false end
	local ok2 = pcall(Env.writefile, CFG_FOLDER .. "/" .. name .. ".json", encoded)
	if ok2 then
		self:Notify("已保存", "配置 \"" .. name .. "\" 已保存", 2, "success")
	end
	return ok2
end

function LiquidGlassUI:LoadConfig(name)
	if not Env.Supported then return nil end
	local path = CFG_FOLDER .. "/" .. name .. ".json"
	if not Env.isfile(path) then return nil end
	local ok, raw = pcall(Env.readfile, path)
	if not ok then return nil end
	local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok2 then return decoded end
	return nil
end

return LiquidGlassUI