local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ZakaUI = {}
ZakaUI.Version = "1.0.0"

local Theme = {
	Accent = Color3.fromRGB(140, 122, 255),
	Accent2 = Color3.fromRGB(96, 208, 255),
	Accent3 = Color3.fromRGB(255, 130, 200),
	Text = Color3.fromRGB(246, 247, 252),
	Sub = Color3.fromRGB(150, 154, 172),
	Base = Color3.fromRGB(15, 15, 21),
	BaseTransparency = 0.14,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0.945,
	HoverTransparency = 0.885,
	Radius = 11,
	WindowRadius = 18,
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	BlurSize = 18,
}
ZakaUI.Theme = Theme

local AccentGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.Accent),
	ColorSequenceKeypoint.new(0.5, Theme.Accent2),
	ColorSequenceKeypoint.new(1, Theme.Accent3),
})

local Tab = {}
Tab.__index = Tab

local function create(class, props)
	local inst = Instance.new(class)
	if props then
		for k, v in next, props do
			if k ~= "Parent" then
				pcall(function()
					inst[k] = v
				end)
			end
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function circle(parent)
	return create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = parent })
end

local function stroke(parent, color, transparency, thickness)
	return create("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Transparency = transparency or 0.88,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(parent, l, r, t, b)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r == nil and (l or 0) or r),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
		Parent = parent,
	})
end

local function gradient(parent, colors, transparency, rotation)
	return create("UIGradient", {
		Color = colors,
		Transparency = transparency,
		Rotation = rotation or 0,
		Parent = parent,
	})
end

local function tween(inst, props, time, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(time or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function ripple(parent, x, y, color)
	local biggest = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
	local dot = create("Frame", {
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x or parent.AbsoluteSize.X / 2, y or parent.AbsoluteSize.Y / 2),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		ZIndex = (parent.ZIndex or 1) + 1,
	})
	circle(dot)
	tween(dot, { Size = UDim2.fromOffset(biggest * 1.6, biggest * 1.6), BackgroundTransparency = 1 }, 0.5)
	task.delay(0.55, function()
		if dot then
			dot:Destroy()
		end
	end)
end

local function hoverable(frame, base, target, strokeObj)
	frame.MouseEnter:Connect(function()
		tween(frame, { BackgroundTransparency = target }, 0.16)
		if strokeObj then
			tween(strokeObj, { Transparency = 0.72 }, 0.16)
		end
	end)
	frame.MouseLeave:Connect(function()
		tween(frame, { BackgroundTransparency = base }, 0.22)
		if strokeObj then
			tween(strokeObj, { Transparency = 0.93 }, 0.22)
		end
	end)
end

local function dragify(handle, target, onTap)
	local dragging = false
	local moved = false
	local startMouse = Vector2.new()
	local startPos = UDim2.new()
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			startMouse = input.Position
			startPos = target.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - startMouse
			if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
				moved = true
			end
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local wasDragging = dragging
			local tapped = not moved
			dragging = false
			if wasDragging and tapped and onTap then
				onTap()
			end
		end
	end)
end

local function getParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local ok2, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and core then
		local probe = Instance.new("Folder")
		local ok3 = pcall(function()
			probe.Parent = core
		end)
		probe:Destroy()
		if ok3 then
			return core
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function measureText(text, width, font, size)
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(math.max(width, 60), 100000))
	end)
	if ok and bounds then
		return math.ceil(bounds.Y)
	end
	return math.ceil(#text / 38) * (size + 4)
end

local function animateElement(frame, delay)
	local scale = frame:FindFirstChildOfClass("UIScale")
	local base = frame:GetAttribute("BaseTransparency")
	if base == nil then
		base = 0.945
	end
	if scale then
		scale.Scale = 0.93
	end
	frame.BackgroundTransparency = 1
	task.delay(delay or 0, function()
		if not frame.Parent then
			return
		end
		if scale then
			tween(scale, { Scale = 1 }, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
		tween(frame, { BackgroundTransparency = base }, 0.3)
	end)
end

function ZakaUI.CreateWindow(a, b)
	local cfg
	if a == ZakaUI then
		cfg = b or {}
	else
		cfg = a or b or {}
	end

	local theme = {}
	for k, v in next, Theme do
		theme[k] = v
	end
	for k, v in next, (cfg.Theme or {}) do
		theme[k] = v
	end

	local gui = create("ScreenGui", {
		Name = "ZakaUI_" .. HttpService:GenerateGUID(false),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	gui.Parent = cfg.Parent or getParent()

	local win = {}
	win.Gui = gui
	win.Theme = theme
	win.Tabs = {}
	win.Flags = {}
	win.IsOpen = false
	win.Title = cfg.Title or "Zaka UI"

	local blur
	if cfg.Blur ~= false then
		blur = create("BlurEffect", {
			Name = "ZakaUIBlur",
			Size = cfg.BlurSize or theme.BlurSize,
			Enabled = false,
			Parent = Lighting,
		})
	end

	local toggleBtn = create("TextButton", {
		Parent = gui,
		Name = "ToggleButton",
		Size = UDim2.fromOffset(52, 52),
		Position = cfg.TogglePosition or UDim2.new(0, 24, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(9, 9, 13),
		BackgroundTransparency = 0.02,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = false,
		ZIndex = 20,
	})
	circle(toggleBtn)
	local toggleStroke = create("UIStroke", {
		Thickness = 1.4,
		Color = theme.Accent,
		Transparency = 0.3,
		Parent = toggleBtn,
	})
	gradient(toggleStroke, AccentGradient, NumberSequence.new(0.25))

	local toggleLogo = create("TextLabel", {
		Parent = toggleBtn,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = cfg.Logo or "Z",
		Font = theme.FontBold,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 22,
	})
	gradient(toggleLogo, AccentGradient, NumberSequence.new(0.05), 90)

	local pulseConn = RunService.Heartbeat:Connect(function()
		if not toggleStroke or not toggleStroke.Parent then
			return
		end
		toggleStroke.Transparency = 0.5 + math.sin(os.clock() * 1.7) * 0.18
	end)

	local main = create("Frame", {
		Parent = gui,
		Name = "Window",
		Size = cfg.Size or UDim2.fromOffset(596, 384),
		Position = cfg.Position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Base,
		BackgroundTransparency = theme.BaseTransparency,
		Visible = false,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 2,
	})
	corner(main, theme.WindowRadius)
	local mainScale = create("UIScale", { Scale = 0.92, Parent = main })
	win.Main = main

	local mainStroke = create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 0.82,
		Parent = main,
	})
	gradient(mainStroke, ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.Accent),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, theme.Accent2),
	}), NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.94),
		NumberSequenceKeypoint.new(1, 0.5),
	}), 35)

	if cfg.BackgroundImage and cfg.BackgroundImage ~= "" then
		local img = create("ImageLabel", {
			Parent = main,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = cfg.BackgroundImage,
			ImageTransparency = cfg.ImageTransparency or 0.45,
			ScaleType = Enum.ScaleType.Crop,
			BorderSizePixel = 0,
			ZIndex = 1,
		})
		corner(img, theme.WindowRadius)
		gradient(img, ColorSequence.new(Color3.fromRGB(255, 255, 255)), NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.55, 0.45),
			NumberSequenceKeypoint.new(1, 0.9),
		}), 90)
	end

	local tint = create("Frame", {
		Parent = main,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.965,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	corner(tint, theme.WindowRadius)
	gradient(tint, ColorSequence.new(Color3.fromRGB(255, 255, 255)), NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.86),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(1, 0.93),
	}), 115)

	create("Frame", {
		Parent = main,
		Size = UDim2.new(1, -36, 0, 1),
		Position = UDim2.new(0.5, 0, 0, 1),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 3,
	})

	local topbar = create("Frame", {
		Parent = main,
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	topbar.Active = true

	local titleLabel = create("TextLabel", {
		Parent = topbar,
		Position = UDim2.fromOffset(20, 14),
		Size = UDim2.new(1, -80, 0, 18),
		BackgroundTransparency = 1,
		Text = cfg.Title or "Zaka UI",
		Font = theme.FontBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})
	gradient(titleLabel, AccentGradient, NumberSequence.new(0.05), 0)

	create("TextLabel", {
		Parent = topbar,
		Position = UDim2.fromOffset(20, 32),
		Size = UDim2.new(1, -80, 0, 12),
		BackgroundTransparency = 1,
		Text = cfg.Subtitle or ("v" .. ZakaUI.Version),
		Font = theme.Font,
		TextSize = 10,
		TextColor3 = theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})

	local closeBtn = create("TextButton", {
		Parent = topbar,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.93,
		AutoButtonColor = false,
		Text = "✕",
		Font = theme.FontBold,
		TextSize = 12,
		TextColor3 = theme.Sub,
		ZIndex = 8,
	})
	circle(closeBtn)
	local closeStroke = stroke(closeBtn, Color3.fromRGB(255, 255, 255), 0.9, 1)
	hoverable(closeBtn, 0.93, 0.86, closeStroke)
	closeBtn.MouseButton1Click:Connect(function()
		win:Close()
	end)

	dragify(topbar, main)

	local sidebar = create("Frame", {
		Parent = main,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(0, 70, 1, -54),
		BackgroundTransparency = 1,
		ZIndex = 6,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = sidebar,
	})
	padding(sidebar, 0, 0, 8, 0)

	create("Frame", {
		Parent = main,
		Position = UDim2.new(0, 70, 0, 54),
		Size = UDim2.new(0, 1, 1, -54),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 5,
	})

	local content = create("Frame", {
		Parent = main,
		Position = UDim2.fromOffset(71, 54),
		Size = UDim2.new(1, -71, 1, -54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	padding(content, 10, 10, 4, 8)
	win.Content = content

	local function openPopup(anchor, width, height)
		local overlay = create("TextButton", {
			Parent = main,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 60,
		})
		local abs = anchor.AbsolutePosition - main.AbsolutePosition
		local px = abs.X + anchor.AbsoluteSize.X - width
		px = math.clamp(px, 8, math.max(8, main.AbsoluteSize.X - width - 8))
		local py = abs.Y + anchor.AbsoluteSize.Y + 6
		if py + height > main.AbsoluteSize.Y - 8 then
			py = math.max(8, abs.Y - height - 6)
		end
		local pop = create("Frame", {
			Parent = main,
			Position = UDim2.fromOffset(px, py),
			Size = UDim2.fromOffset(width, height),
			BackgroundColor3 = Color3.fromRGB(20, 20, 27),
			BackgroundTransparency = 0.03,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 61,
		})
		corner(pop, 10)
		stroke(pop, Color3.fromRGB(255, 255, 255), 0.85, 1)
		local popScale = create("UIScale", { Scale = 0.92, Parent = pop })
		tween(popScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		local closed = false
		local function close()
			if closed then
				return
			end
			closed = true
			pop:Destroy()
			overlay:Destroy()
		end
		overlay.MouseButton1Click:Connect(close)
		return pop, overlay, close
	end

	win.OpenPopup = openPopup

	function win:CreateTab(tabCfg)
		tabCfg = tabCfg or {}
		local tab = setmetatable({
			Window = win,
			Theme = theme,
			Name = tabCfg.Name or ("Tab " .. (#win.Tabs + 1)),
			IconSource = tabCfg.Icon,
			Order = 0,
			Elements = {},
			Index = #win.Tabs + 1,
		}, Tab)

		local btn = create("TextButton", {
			Parent = sidebar,
			Size = UDim2.fromOffset(52, 50),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			LayoutOrder = tab.Index,
			ZIndex = 7,
		})
		corner(btn, 12)

		local indicator = create("Frame", {
			Parent = btn,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 3, 0, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 9,
		})
		corner(indicator, 4)
		gradient(indicator, AccentGradient, NumberSequence.new(0), 90)

		local holder = create("Frame", {
			Parent = btn,
			Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			ZIndex = 8,
		})

		local iconObj
		local iconText = tabCfg.Icon or string.sub(tab.Name, 1, 1)
		if string.find(tostring(iconText), "rbxasset") then
			iconObj = create("ImageLabel", {
				Parent = holder,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				Image = iconText,
				ImageColor3 = theme.Sub,
				ZIndex = 9,
			})
		else
			iconObj = create("TextLabel", {
				Parent = holder,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = iconText,
				Font = theme.FontBold,
				TextSize = 16,
				TextColor3 = theme.Sub,
				ZIndex = 9,
			})
		end

		local nameLabel = create("TextLabel", {
			Parent = btn,
			Position = UDim2.fromOffset(0, 31),
			Size = UDim2.new(1, -6, 0, 11),
			BackgroundTransparency = 1,
			Text = tab.Name,
			Font = theme.Font,
			TextSize = 9,
			TextColor3 = theme.Sub,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 9,
		})

		local page = create("ScrollingFrame", {
			Parent = content,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = theme.Accent,
			ScrollBarImageTransparency = 0.35,
			Visible = false,
			ClipsDescendants = true,
			ZIndex = 7,
		})
		create("UIListLayout", {
			Padding = UDim.new(0, 7),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})
		padding(page, 0, 8, 0, 14)

		tab.Page = page
		tab.Button = btn
		tab.Indicator = indicator
		tab.Icon = iconObj
		tab.NameLabel = nameLabel

		btn.MouseEnter:Connect(function()
			if win.Current ~= tab then
				tween(btn, { BackgroundTransparency = 0.93 }, 0.16)
			end
		end)
		btn.MouseLeave:Connect(function()
			if win.Current ~= tab then
				tween(btn, { BackgroundTransparency = 1 }, 0.2)
			end
		end)
		btn.MouseButton1Click:Connect(function()
			win:SelectTab(tab)
			ripple(btn, 26, 25)
		end)

		table.insert(win.Tabs, tab)
		if #win.Tabs == 1 then
			win:SelectTab(tab)
		end
		return tab
	end

	win.Tab = win.CreateTab

	function win:SelectTab(tab)
		if win.Current == tab then
			return
		end
		win.Current = tab
		for _, t in ipairs(win.Tabs) do
			local active = t == tab
			t.Page.Visible = active
			tween(t.Button, { BackgroundTransparency = active and 0.9 or 1 }, 0.2)
			tween(t.Indicator, { Size = active and UDim2.new(0, 3, 0, 22) or UDim2.new(0, 3, 0, 0) }, 0.26, Enum.EasingStyle.Back)
			if t.Icon:IsA("ImageLabel") then
				tween(t.Icon, { ImageColor3 = active and Color3.fromRGB(255, 255, 255) or theme.Sub }, 0.2)
			else
				tween(t.Icon, { TextColor3 = active and Color3.fromRGB(255, 255, 255) or theme.Sub }, 0.2)
			end
			tween(t.NameLabel, { TextColor3 = active and Color3.fromRGB(255, 255, 255) or theme.Sub }, 0.2)
		end
		tab.Page.CanvasPosition = Vector2.new()
		local i = 0
		for _, child in ipairs(tab.Page:GetChildren()) do
			if child:IsA("GuiObject") then
				i = i + 1
				animateElement(child, math.min(i * 0.025, 0.35))
			end
		end
	end

	function win:Open()
		if win.IsOpen then
			return
		end
		win.IsOpen = true
		main.Visible = true
		mainScale.Scale = 0.9
		tween(mainScale, { Scale = 1 }, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(toggleLogo, { Rotation = 135 }, 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		if blur then
			blur.Enabled = true
		end
		if win.Current then
			local i = 0
			for _, child in ipairs(win.Current.Page:GetChildren()) do
				if child:IsA("GuiObject") then
					i = i + 1
					animateElement(child, math.min(i * 0.02, 0.3))
				end
			end
		end
	end

	function win:Close()
		if not win.IsOpen then
			return
		end
		win.IsOpen = false
		tween(mainScale, { Scale = 0.9 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(toggleLogo, { Rotation = 0 }, 0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if blur then
			blur.Enabled = false
		end
		task.delay(0.19, function()
			if not win.IsOpen then
				main.Visible = false
			end
		end)
	end

	function win:Toggle()
		if win.IsOpen then
			win:Close()
		else
			win:Open()
		end
	end

	function win:SetToggleVisible(state)
		toggleBtn.Visible = state ~= false
	end

	function win:GetFlag(name)
		return win.Flags[name]
	end

	function win:Notify(notifyCfg)
		notifyCfg = notifyCfg or {}
		local holder = win.NotifyHolder
		if not holder then
			holder = create("Frame", {
				Parent = gui,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -18, 0, 18),
				Size = UDim2.fromOffset(258, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ZIndex = 200,
			})
			create("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Parent = holder,
			})
			win.NotifyHolder = holder
		end
		win.NotifyCount = (win.NotifyCount or 0) + 1

		local toast = create("Frame", {
			Parent = holder,
			Size = UDim2.fromOffset(258, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(18, 18, 25),
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = win.NotifyCount,
			ZIndex = 201,
		})
		corner(toast, 10)
		stroke(toast, Color3.fromRGB(255, 255, 255), 0.86, 1)
		create("UIScale", { Scale = 0.92, Parent = toast })
		padding(toast, 12, 12, 11, 11)

		create("Frame", {
			Parent = toast,
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = notifyCfg.Color or theme.Accent,
			BorderSizePixel = 0,
			ZIndex = 202,
		})

		create("TextLabel", {
			Parent = toast,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -10, 0, 14),
			BackgroundTransparency = 1,
			Text = notifyCfg.Title or "提示",
			Font = theme.FontBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 202,
		})

		create("TextLabel", {
			Parent = toast,
			Position = UDim2.fromOffset(10, 17),
			Size = UDim2.new(1, -10, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = notifyCfg.Content or "",
			Font = theme.Font,
			TextSize = 11,
			TextColor3 = theme.Sub,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 202,
		})

		local function dismiss()
			if not toast or not toast.Parent then
				return
			end
			local sc = toast:FindFirstChildOfClass("UIScale")
			if sc then
				tween(sc, { Scale = 0.9 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			tween(toast, { BackgroundTransparency = 1 }, 0.18)
			task.delay(0.2, function()
				if toast then
					toast:Destroy()
				end
			end)
		end

		toast.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dismiss()
			end
		end)

		task.delay(notifyCfg.Duration or 4, dismiss)
		return dismiss
	end

	function win:Destroy()
		if pulseConn then
			pulseConn:Disconnect()
		end
		if blur then
			blur:Destroy()
		end
		gui:Destroy()
	end

	local function element(tab, height)
		tab.Order = tab.Order + 1
		local frame = create("TextButton", {
			Parent = tab.Page,
			Size = UDim2.new(1, -6, 0, height),
			BackgroundColor3 = theme.Surface,
			BackgroundTransparency = theme.SurfaceTransparency,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			LayoutOrder = tab.Order,
			ZIndex = 8,
		})
		corner(frame, theme.Radius)
		local st = stroke(frame, Color3.fromRGB(255, 255, 255), 0.93, 1)
		frame:SetAttribute("BaseTransparency", theme.SurfaceTransparency)
		create("UIScale", { Scale = 1, Parent = frame })
		hoverable(frame, theme.SurfaceTransparency, theme.HoverTransparency, st)
		table.insert(tab.Elements, frame)
		return frame, st
	end

	win.Element = element

	return win
end

function Tab:AddSection(titleText)
	self.Order = self.Order + 1
	local row = create("Frame", {
		Parent = self.Page,
		Size = UDim2.new(1, -6, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = self.Order,
		ZIndex = 8,
	})
	local lbl = create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(4, 8),
		Size = UDim2.new(1, -8, 0, 14),
		BackgroundTransparency = 1,
		Text = string.upper(tostring(titleText or "SECTION")),
		Font = self.Theme.FontBold,
		TextSize = 10,
		TextColor3 = self.Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})
	gradient(lbl, AccentGradient, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.85),
	}), 0)
	table.insert(self.Elements, row)
	return row
end

function Tab:AddDivider()
	self.Order = self.Order + 1
	local holder = create("Frame", {
		Parent = self.Page,
		Size = UDim2.new(1, -6, 0, 8),
		BackgroundTransparency = 1,
		LayoutOrder = self.Order,
		ZIndex = 8,
	})
	local line = create("Frame", {
		Parent = holder,
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.new(1, -12, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	gradient(line, AccentGradient, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	}), 0)
	return holder
end

function Tab:AddToggle(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local row = self.Window.Element(self, 46)
	local state = cfg.Default == true

	local lbl = create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Title or "Toggle"),
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})

	if cfg.Description then
		lbl.Position = UDim2.fromOffset(14, 7)
		lbl.Size = UDim2.new(1, -80, 0, 14)
		create("TextLabel", {
			Parent = row,
			Position = UDim2.fromOffset(14, 24),
			Size = UDim2.new(1, -80, 0, 11),
			BackgroundTransparency = 1,
			Text = tostring(cfg.Description),
			Font = theme.Font,
			TextSize = 9,
			TextColor3 = theme.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 9,
		})
	end

	local track = create("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = Color3.fromRGB(56, 58, 70),
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	circle(track)

	local knob = create("Frame", {
		Parent = track,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 10,
	})
	circle(knob)

	local function apply(value, silent)
		state = value and true or false
		tween(track, { BackgroundColor3 = state and theme.Accent or Color3.fromRGB(56, 58, 70) }, 0.2)
		tween(knob, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, 0.24, Enum.EasingStyle.Back)
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = state
		end
		if not silent and cfg.Callback then
			task.spawn(cfg.Callback, state)
		end
	end

	row.MouseButton1Click:Connect(function()
		apply(not state)
		ripple(row, row.AbsoluteSize.X - 33, 23, theme.Accent)
	end)

	apply(state, true)

	return {
		Set = function(_, v)
			apply(v)
		end,
		Get = function()
			return state
		end,
	}
end

function Tab:AddSlider(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local row = self.Window.Element(self, 52)
	local minValue = cfg.Min or 0
	local maxValue = cfg.Max or 100
	local decimals = math.clamp(cfg.Decimals or 0, 0, 4)
	local step = 1 / (10 ^ decimals)
	local suffix = cfg.Suffix or ""
	local value = math.clamp(cfg.Default or minValue, minValue, maxValue)

	create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -90, 0, 14),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Title or "Slider"),
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})

	local valueLbl = create("TextLabel", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.new(0, 80, 0, 14),
		BackgroundTransparency = 1,
		Text = "",
		Font = theme.FontBold,
		TextSize = 11,
		TextColor3 = theme.Accent2,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 9,
	})

	local holder = create("Frame", {
		Parent = row,
		Position = UDim2.fromOffset(14, 30),
		Size = UDim2.new(1, -28, 0, 12),
		BackgroundTransparency = 1,
		ZIndex = 9,
	})

	local track = create("Frame", {
		Parent = holder,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Color3.fromRGB(58, 60, 72),
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	circle(track)

	local fill = create("Frame", {
		Parent = track,
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 10,
	})
	circle(fill)
	gradient(fill, AccentGradient, NumberSequence.new(0.02), 0)

	local knob = create("Frame", {
		Parent = holder,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 11,
	})
	circle(knob)
	stroke(knob, theme.Accent, 0, 2)

	local function setValue(nextValue, silent)
		nextValue = math.clamp(nextValue, minValue, maxValue)
		nextValue = minValue + math.floor((nextValue - minValue) / step + 0.5) * step
		nextValue = math.clamp(nextValue, minValue, maxValue)
		value = nextValue
		local percent = 0
		if maxValue > minValue then
			percent = (value - minValue) / (maxValue - minValue)
		end
		tween(fill, { Size = UDim2.fromScale(percent, 1) }, 0.1)
		tween(knob, { Position = UDim2.new(percent, 0, 0.5, 0) }, 0.1)
		valueLbl.Text = string.format("%." .. decimals .. "f", value) .. suffix
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = value
		end
		if not silent and cfg.Callback then
			task.spawn(cfg.Callback, value)
		end
	end

	local dragging = false
	local function pointerToValue(positionX)
		local percent = (positionX - holder.AbsolutePosition.X) / math.max(holder.AbsoluteSize.X, 1)
		percent = math.clamp(percent, 0, 1)
		setValue(minValue + (maxValue - minValue) * percent)
	end

	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			pointerToValue(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			pointerToValue(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	setValue(value, true)

	return {
		Set = function(_, v)
			setValue(v)
		end,
		Get = function()
			return value
		end,
	}
end

function Tab:AddButton(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local row = self.Window.Element(self, 44)
	local lbl = create("TextLabel", {
		Parent = row,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Title or "Button"),
		Font = theme.FontBold,
		TextSize = 12,
		TextColor3 = theme.Text,
		ZIndex = 9,
	})
	gradient(lbl, ColorSequence.new(Color3.fromRGB(255, 255, 255)), NumberSequence.new(0.1), 0)
	row.MouseButton1Click:Connect(function()
		ripple(row, row.AbsoluteSize.X / 2, row.AbsoluteSize.Y / 2, theme.Accent)
		if cfg.Callback then
			task.spawn(cfg.Callback)
		end
	end)
	return row
end

function Tab:AddParagraph(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local text = tostring(cfg.Content or cfg.Text or "")
	local width = self.Window.Main.AbsoluteSize.X
	if width <= 1 then
		width = 596
	end
	local bodyHeight = measureText(text, width - 170, theme.Font, 12)
	local hasImage = cfg.Image and cfg.Image ~= ""
	local imageHeight = cfg.ImageHeight or 120
	local headHeight = 0
	if cfg.Title and cfg.Title ~= "" then
		headHeight = 18
	end
	local total = headHeight + bodyHeight + 24 + (hasImage and (imageHeight + 10) or 0)

	local row = self.Window.Element(self, total)

	if cfg.Title and cfg.Title ~= "" then
		create("TextLabel", {
			Parent = row,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 14),
			BackgroundTransparency = 1,
			Text = tostring(cfg.Title),
			Font = theme.FontBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 9,
		})
	end

	create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 10 + headHeight),
		Size = UDim2.new(1, -28, 0, bodyHeight + 4),
		BackgroundTransparency = 1,
		Text = text,
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.Sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.15,
		ZIndex = 9,
	})

	if hasImage then
		local pic = create("ImageLabel", {
			Parent = row,
			Position = UDim2.fromOffset(14, 10 + headHeight + bodyHeight + 10),
			Size = UDim2.new(1, -28, 0, imageHeight),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.95,
			Image = cfg.Image,
			ScaleType = Enum.ScaleType.Crop,
			BorderSizePixel = 0,
			ZIndex = 9,
		})
		corner(pic, 8)
		stroke(pic, Color3.fromRGB(255, 255, 255), 0.9, 1)
	end
	return row
end

function Tab:AddImage(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local height = cfg.Height or 130
	local row = self.Window.Element(self, height + 16)
	local pic = create("ImageLabel", {
		Parent = row,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, height),
		BackgroundTransparency = 1,
		Image = cfg.Image or "",
		ScaleType = Enum.ScaleType.Crop,
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	corner(pic, 8)
	stroke(pic, Color3.fromRGB(255, 255, 255), 0.9, 1)
	return pic
end

function Tab:AddInput(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local row = self.Window.Element(self, 50)

	create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -230, 1, 0),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Title or "Input"),
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})

	local box = create("TextBox", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(196, 30),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Text = tostring(cfg.Default or ""),
		PlaceholderText = tostring(cfg.Placeholder or "输入内容"),
		PlaceholderColor3 = Color3.fromRGB(118, 122, 140),
		TextColor3 = theme.Text,
		Font = theme.Font,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 10,
	})
	corner(box, 8)
	padding(box, 10, 8, 0, 0)
	local boxStroke = stroke(box, Color3.fromRGB(255, 255, 255), 0.9, 1)

	box.Focused:Connect(function()
		tween(boxStroke, { Transparency = 0.15, Color = theme.Accent }, 0.18)
		tween(box, { BackgroundTransparency = 0.88 }, 0.18)
	end)
	box.FocusLost:Connect(function(enterPressed)
		tween(boxStroke, { Transparency = 0.9, Color = Color3.fromRGB(255, 255, 255) }, 0.2)
		tween(box, { BackgroundTransparency = 0.93 }, 0.2)
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = box.Text
		end
		if cfg.Callback then
			task.spawn(cfg.Callback, box.Text, enterPressed)
		end
	end)

	return {
		Set = function(_, v)
			box.Text = tostring(v)
		end,
		Get = function()
			return box.Text
		end,
	}
end

function Tab:AddDropdown(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local options = cfg.Options or cfg.List or {}
	local multi = cfg.Multi == true
	local selected = {}
	local single = cfg.Default or options[1]
	if multi and type(cfg.Default) == "table" then
		for _, v in ipairs(cfg.Default) do
			selected[tostring(v)] = true
		end
	end

	local row = self.Window.Element(self, 46)

	create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -215, 1, 0),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Title or "Dropdown"),
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})

	local btn = create("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(180, 28),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 10,
	})
	corner(btn, 8)
	stroke(btn, Color3.fromRGB(255, 255, 255), 0.9, 1)
	padding(btn, 10, 22, 0, 0)

	local valueLbl = create("TextLabel", {
		Parent = btn,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Font = theme.Font,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 11,
	})

	local chev = create("TextLabel", {
		Parent = btn,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text = "▾",
		Font = theme.FontBold,
		TextSize = 10,
		TextColor3 = theme.Sub,
		ZIndex = 11,
	})

	local function values()
		local list = {}
		for _, opt in ipairs(options) do
			if selected[tostring(opt)] then
				table.insert(list, opt)
			end
		end
		return list
	end

	local function refreshText()
		if multi then
			local list = values()
			if #list == 0 then
				valueLbl.Text = "未选择"
			elseif #list > 2 then
				valueLbl.Text = tostring(#list) .. " 项已选"
			else
				local parts = {}
				for _, item in ipairs(list) do
					table.insert(parts, tostring(item))
				end
				valueLbl.Text = table.concat(parts, ", ")
			end
		else
			valueLbl.Text = tostring(single or "未选择")
		end
	end
	refreshText()

	local function fire()
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = multi and values() or single
		end
		if cfg.Callback then
			task.spawn(cfg.Callback, multi and values() or single)
		end
	end

	local closeCurrent
	btn.MouseButton1Click:Connect(function()
		if closeCurrent then
			closeCurrent()
			closeCurrent = nil
			tween(chev, { Rotation = 0 }, 0.2)
			return
		end
		local listHeight = math.min(#options * 26 + 10, 168)
		local pop, _, closeFn = self.Window.OpenPopup(btn, 190, listHeight)
		closeCurrent = closeFn
		tween(chev, { Rotation = 180 }, 0.2)

		local scroll = create("ScrollingFrame", {
			Parent = pop,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = theme.Accent,
			ScrollBarImageTransparency = 0.4,
			ZIndex = 62,
		})
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
		padding(scroll, 5, 5, 5, 5)

		for index, option in ipairs(options) do
			local optBtn = create("TextButton", {
				Parent = scroll,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				ZIndex = 63,
			})
			corner(optBtn, 6)

			local optLbl = create("TextLabel", {
				Parent = optBtn,
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -12, 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(option),
				Font = theme.Font,
				TextSize = 11,
				TextColor3 = theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 64,
			})

			local active = multi and selected[tostring(option)] or (not multi and single == option)
			if active then
				optBtn.BackgroundTransparency = 0.86
				optLbl.TextColor3 = theme.Accent2
			end

			optBtn.MouseEnter:Connect(function()
				tween(optBtn, { BackgroundTransparency = 0.92 }, 0.14)
			end)
			optBtn.MouseLeave:Connect(function()
				local nowActive = multi and selected[tostring(option)] or (not multi and single == option)
				tween(optBtn, { BackgroundTransparency = nowActive and 0.86 or 1 }, 0.16)
			end)

			optBtn.MouseButton1Click:Connect(function()
				if multi then
					if selected[tostring(option)] then
						selected[tostring(option)] = nil
					else
						selected[tostring(option)] = true
					end
					local nowActive = selected[tostring(option)] == true
					tween(optBtn, { BackgroundTransparency = nowActive and 0.86 or 1 }, 0.15)
					optLbl.TextColor3 = nowActive and theme.Accent2 or theme.Text
					refreshText()
					fire()
				else
					single = option
					refreshText()
					fire()
					if closeCurrent then
						closeCurrent()
						closeCurrent = nil
						tween(chev, { Rotation = 0 }, 0.2)
					end
				end
			end)
		end
	end)

	return {
		Set = function(_, value)
			if multi and type(value) == "table" then
				selected = {}
				for _, v in ipairs(value) do
					selected[tostring(v)] = true
				end
			elseif not multi then
				single = value
			end
			refreshText()
		end,
		Get = function()
			if multi then
				return values()
			end
			return single
		end,
	}
end

function Tab:AddColorpicker(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local row = self.Window.Element(self, 46)
	local color = cfg.Default or Color3.fromRGB(140, 122, 255)
	local hue, sat, val = Color3.toHSV(color)

	create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Title or "Colorpicker"),
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})

	local swatch = create("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(48, 24),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 10,
	})
	corner(swatch, 7)
	stroke(swatch, Color3.fromRGB(255, 255, 255), 0.7, 1)

	local function fire()
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = color
		end
		if cfg.Callback then
			task.spawn(cfg.Callback, color)
		end
	end

	local closeCurrent
	swatch.MouseButton1Click:Connect(function()
		if closeCurrent then
			closeCurrent()
			closeCurrent = nil
			return
		end
		local pop, _, closeFn = self.Window.OpenPopup(swatch, 224, 214)
		closeCurrent = closeFn

		local sv = create("Frame", {
			Parent = pop,
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(204, 108),
			BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 62,
		})
		corner(sv, 8)

		local whiteOverlay = create("Frame", {
			Parent = sv,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 63,
		})
		gradient(whiteOverlay, ColorSequence.new(Color3.fromRGB(255, 255, 255)), NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}), 0)

		local blackOverlay = create("Frame", {
			Parent = sv,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 64,
		})
		gradient(blackOverlay, ColorSequence.new(Color3.fromRGB(0, 0, 0)), NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}), 90)

		local svCursor = create("Frame", {
			Parent = sv,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(sat, 0, 1 - val, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 66,
		})
		circle(svCursor)
		stroke(svCursor, Color3.fromRGB(255, 255, 255), 0.05, 2)

		local hueBar = create("Frame", {
			Parent = pop,
			Position = UDim2.fromOffset(10, 128),
			Size = UDim2.fromOffset(204, 14),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 62,
		})
		corner(hueBar, 7)
		gradient(hueBar, ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}), NumberSequence.new(0), 0)

		local hueCursor = create("Frame", {
			Parent = hueBar,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(hue, 0, 0.5, 0),
			Size = UDim2.fromOffset(10, 18),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 65,
		})
		corner(hueCursor, 4)

		local preview = create("Frame", {
			Parent = pop,
			Position = UDim2.fromOffset(10, 152),
			Size = UDim2.fromOffset(46, 24),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 62,
		})
		corner(preview, 7)
		stroke(preview, Color3.fromRGB(255, 255, 255), 0.7, 1)

		local hexBox = create("TextBox", {
			Parent = pop,
			Position = UDim2.fromOffset(64, 152),
			Size = UDim2.fromOffset(150, 24),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			Text = "",
			Font = theme.Font,
			TextSize = 11,
			TextColor3 = theme.Text,
			ClearTextOnFocus = false,
			ZIndex = 62,
		})
		corner(hexBox, 7)
		padding(hexBox, 8, 8, 0, 0)

		local function sync(silent)
			sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
			hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
			color = Color3.fromHSV(hue, sat, val)
			preview.BackgroundColor3 = color
			swatch.BackgroundColor3 = color
			hexBox.Text = string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
			if not silent then
				fire()
			end
		end

		local draggingSV = false
		local draggingHue = false

		local function updateSV(px, py)
			sat = math.clamp((px - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			val = 1 - math.clamp((py - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
			sync()
		end

		local function updateHue(px)
			hue = math.clamp((px - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
			sync()
		end

		sv.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingSV = true
				updateSV(input.Position.X, input.Position.Y)
			end
		end)
		hueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingHue = true
				updateHue(input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if draggingSV then
					updateSV(input.Position.X, input.Position.Y)
				elseif draggingHue then
					updateHue(input.Position.X)
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingSV = false
				draggingHue = false
			end
		end)

		hexBox.FocusLost:Connect(function()
			local raw = string.gsub(hexBox.Text, "#", "")
			raw = string.upper(raw)
			if #raw == 6 then
				local r = tonumber(string.sub(raw, 1, 2), 16)
				local g = tonumber(string.sub(raw, 3, 4), 16)
				local b = tonumber(string.sub(raw, 5, 6), 16)
				if r and g and b then
					hue, sat, val = Color3.toHSV(Color3.fromRGB(r, g, b))
					sync()
					return
				end
			end
			sync(true)
		end)

		sync(true)
	end)

	return {
		Set = function(_, value)
			color = value
			hue, sat, val = Color3.toHSV(color)
			swatch.BackgroundColor3 = color
			fire()
		end,
		Get = function()
			return color
		end,
	}
end

function Tab:AddTabbox(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	local options = cfg.Options or {}
	local current = cfg.Default or options[1]
	local row = self.Window.Element(self, 52)

	create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 0, 13),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Title or "Tabs"),
		Font = theme.Font,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})

	local bar = create("Frame", {
		Parent = row,
		Position = UDim2.fromOffset(14, 23),
		Size = UDim2.new(1, -28, 0, 22),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 9,
	})
	corner(bar, 11)
	stroke(bar, Color3.fromRGB(255, 255, 255), 0.92, 1)
	padding(bar, 3, 3, 0, 0)

	local pill = create("Frame", {
		Parent = bar,
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.fromOffset(0, 16),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 10,
	})
	corner(pill, 8)
	gradient(pill, AccentGradient, NumberSequence.new(0.05), 0)

	local holder = create("Frame", {
		Parent = bar,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 11,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = holder,
	})

	local buttons = {}
	local function selectTab(option, silent)
		current = option
		for key, data in pairs(buttons) do
			local active = key == option
			tween(data.Label, { TextColor3 = active and Color3.fromRGB(255, 255, 255) or theme.Sub }, 0.18)
		end
		local target = buttons[option]
		if target then
			tween(pill, {
				Position = UDim2.fromOffset(target.Btn.AbsolutePosition.X - bar.AbsolutePosition.X - 3, 3),
				Size = UDim2.fromOffset(target.Btn.AbsoluteSize.X, 16),
			}, 0.24)
		end
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = current
		end
		if not silent and cfg.Callback then
			task.spawn(cfg.Callback, current)
		end
	end

	local count = math.max(#options, 1)
	for index, option in ipairs(options) do
		local btn = create("TextButton", {
			Parent = holder,
			Size = UDim2.new(1 / count, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			ZIndex = 12,
		})
		local label = create("TextLabel", {
			Parent = btn,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = tostring(option),
			Font = theme.Font,
			TextSize = 10,
			TextColor3 = theme.Sub,
			ZIndex = 13,
		})
		buttons[option] = { Btn = btn, Label = label }
		btn.MouseButton1Click:Connect(function()
			selectTab(option)
		end)
	end

	task.defer(function()
		task.wait(0.1)
		selectTab(current, true)
	end)

	return {
		Set = function(_, v)
			selectTab(v)
		end,
		Get = function()
			return current
		end,
	}
end

function Tab:AddTag(cfg)
	cfg = cfg or {}
	local theme = self.Theme
	self.Order = self.Order + 1
	local row = create("Frame", {
		Parent = self.Page,
		Size = UDim2.new(1, -6, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = self.Order,
		ZIndex = 8,
	})
	local pill = create("Frame", {
		Parent = row,
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = cfg.Color or theme.Accent,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	corner(pill, 11)
	stroke(pill, cfg.Color or theme.Accent, 0.5, 1)
	padding(pill, 10, 10, 0, 0)
	create("TextLabel", {
		Parent = pill,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = tostring(cfg.Text or "标签"),
		Font = theme.FontBold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 10,
	})
	return row
end

return ZakaUI