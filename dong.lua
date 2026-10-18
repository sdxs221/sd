local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ZakaUI = {}
ZakaUI.Version = "1.1.0"

local Theme = {
	Accent = Color3.fromRGB(138, 120, 255),
	Accent2 = Color3.fromRGB(90, 200, 255),
	Accent3 = Color3.fromRGB(255, 128, 196),
	Text = Color3.fromRGB(246, 247, 252),
	Sub = Color3.fromRGB(148, 152, 170),
	Base = Color3.fromRGB(10, 10, 16),
	BaseTransparency = 0.08,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0.94,
	HoverTransparency = 0.875,
	Radius = 12,
	WindowRadius = 20,
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	BlurSize = 20,
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
		ZIndex = (parent.ZIndex or 1) + 2,
	})
	circle(dot)
	tween(dot, { Size = UDim2.fromOffset(biggest * 1.7, biggest * 1.7), BackgroundTransparency = 1 }, 0.5)
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
			tween(strokeObj, { Transparency = 0.62, Color = Theme.Accent }, 0.16)
		end
	end)
	frame.MouseLeave:Connect(function()
		tween(frame, { BackgroundTransparency = base }, 0.22)
		if strokeObj then
			tween(strokeObj, { Transparency = 0.93, Color = Color3.fromRGB(255, 255, 255) }, 0.22)
		end
	end)
end

local function dragify(handle, target, onTap, onState)
	local dragging = false
	local moved = false
	local startMouse = Vector2.zero
	local startPos = UDim2.new()
	local conn1 = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			startMouse = input.Position
			startPos = target.Position
		end
	end)
	local conn2 = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - startMouse
			if not moved and (math.abs(delta.X) > 3 or math.abs(delta.Y) > 3) then
				moved = true
				if onState then
					onState(true)
				end
			end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end
	end)
	local conn3 = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local was = dragging
			dragging = false
			if was then
				if moved then
					if onState then
						onState(false)
					end
				elseif onTap then
					onTap()
				end
			end
		end
	end)
	return function()
		conn1:Disconnect()
		conn2:Disconnect()
		conn3:Disconnect()
	end
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
		base = 0.94
	end
	if scale then
		scale.Scale = 0.92
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

local function markIcon(inst)
	inst:SetAttribute("IconPart", true)
	return inst
end

local function tintIcon(holder, color)
	for _, d in ipairs(holder:GetDescendants()) do
		if d:GetAttribute("IconPart") then
			if d:IsA("UIStroke") then
				d.Color = color
			elseif d:IsA("TextLabel") then
				d.TextColor3 = color
			elseif d:IsA("ImageLabel") then
				d.ImageColor3 = color
			else
				d.BackgroundColor3 = color
			end
		end
	end
end

local function makeIcon(parent, icon, size, color, zindex)
	zindex = zindex or 9
	local holder = create("Frame", {
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = zindex,
	})
	local key = string.lower(tostring(icon or ""))
	local function part(props)
		local f = create("Frame", props)
		markIcon(f)
		return f
	end
	if string.find(key, "rbxasset") then
		local img = create("ImageLabel", {
			Parent = holder,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = tostring(icon),
			ImageColor3 = color,
			ZIndex = zindex + 1,
		})
		markIcon(img)
		return holder
	end
	if key == "star" or key == "★" then
		local a = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(size * 0.6, size), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(a, size * 0.18)
		local b = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(size, size * 0.6), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(b, size * 0.18)
	elseif key == "spark" or key == "✦" or key == "diamond" then
		local a = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.64, size * 0.64), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(a, size * 0.15)
	elseif key == "gear" or key == "⚙" or key == "settings" then
		local ring = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.66, size * 0.66), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(ring)
		markIcon(stroke(ring, color, 0, math.max(2, size * 0.14)))
		for _, rot in ipairs({ 0, 45, 90, 135 }) do
			local bar = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.92, math.max(2, size * 0.12)), Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex })
			corner(bar, math.max(2, size * 0.12))
		end
		local dot = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.22, size * 0.22), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(dot)
	elseif key == "info" or key == "i" or key == "about" then
		local dot = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(size * 0.2, size * 0.2), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(dot)
		local stem = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.68), Size = UDim2.fromOffset(math.max(2, size * 0.16), size * 0.44), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(stem, math.max(2, size * 0.16))
	elseif key == "home" then
		holder.ClipsDescendants = true
		local roof = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.16), Size = UDim2.fromOffset(size * 0.76, size * 0.76), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(roof, size * 0.1)
		local body = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromOffset(size * 0.6, size * 0.5), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(body, size * 0.1)
	elseif key == "user" or key == "player" then
		holder.ClipsDescendants = true
		local head = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34), Size = UDim2.fromOffset(size * 0.42, size * 0.42), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(head)
		local body = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1.05), Size = UDim2.fromOffset(size * 0.95, size * 0.95), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(body)
	elseif key == "eye" or key == "visual" then
		local ring = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.92, size * 0.92), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(ring)
		markIcon(stroke(ring, color, 0, math.max(2, size * 0.12)))
		local dot = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.3, size * 0.3), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(dot)
	elseif key == "search" or key == "find" then
		local ring = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.42, 0.42), Size = UDim2.fromOffset(size * 0.58, size * 0.58), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = zindex + 1 })
		circle(ring)
		markIcon(stroke(ring, color, 0, math.max(2, size * 0.12)))
		local handle = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.72, 0.72), Size = UDim2.fromOffset(size * 0.42, math.max(2, size * 0.12)), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(handle, math.max(2, size * 0.12))
	elseif key == "cross" or key == "x" or key == "close" then
		local t = math.max(2, size * 0.14)
		local l1 = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.78, t), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(l1, t)
		local l2 = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.78, t), Rotation = -45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
		corner(l2, t)
	else
		local ch = tostring(icon or "?")
		if #ch == 1 and string.match(ch, "[%w%p]") then
			local lbl = create("TextLabel", { Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = ch, Font = Enum.Font.GothamBold, TextSize = math.floor(size * 0.95), TextColor3 = color, ZIndex = zindex + 1 })
			markIcon(lbl)
		else
			local a = part({ Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.58, size * 0.58), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = zindex + 1 })
			corner(a, size * 0.13)
		end
	end
	return holder
end

local function drawX(parent, size, color, zindex, anchor, position)
	local btn = create("TextButton", {
		Parent = parent,
		AnchorPoint = anchor or Vector2.new(0.5, 0.5),
		Position = position or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = zindex or 10,
	})
	circle(btn)
	local t = math.max(2, size * 0.12)
	local l1 = create("Frame", { Parent = btn, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.52, t), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = (zindex or 10) + 1 })
	corner(l1, t)
	local l2 = create("Frame", { Parent = btn, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size * 0.52, t), Rotation = -45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = (zindex or 10) + 1 })
	corner(l2, t)
	return btn
end

local function drawChevron(parent, size, color, zindex)
	local holder = create("Frame", { Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = zindex or 10 })
	local t = math.max(2, size * 0.2)
	local l1 = create("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.38, 0.44), Size = UDim2.fromOffset(size * 0.56, t), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = (zindex or 10) + 1 })
	corner(l1, t)
	local l2 = create("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.62, 0.44), Size = UDim2.fromOffset(size * 0.56, t), Rotation = -45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = (zindex or 10) + 1 })
	corner(l2, t)
	return holder
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

	local connections = {}

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
	local blurTarget = cfg.BlurSize or theme.BlurSize
	if cfg.Blur ~= false then
		blur = create("BlurEffect", {
			Name = "ZakaUIBlur",
			Size = 0,
			Enabled = false,
			Parent = Lighting,
		})
	end

	local toggleBtn = create("TextButton", {
		Parent = gui,
		Name = "ToggleButton",
		Size = UDim2.fromOffset(50, 50),
		Position = cfg.TogglePosition or UDim2.new(0, 24, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 20,
	})
	circle(toggleBtn)
	create("UIStroke", { Thickness = 1.2, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.85, Parent = toggleBtn })
	local toggleIcon = makeIcon(toggleBtn, cfg.Logo or "star", 18, Color3.fromRGB(255, 255, 255), 22)

	local main = create("Frame", {
		Parent = gui,
		Name = "Window",
		Size = cfg.Size or UDim2.fromOffset(600, 392),
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

	local shadow = create("Frame", {
		Parent = gui,
		Name = "Shadow",
		Size = UDim2.new(0, main.Size.X.Offset + 18, 0, main.Size.Y.Offset + 18),
		Position = main.Position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1,
	})
	corner(shadow, theme.WindowRadius + 8)
	table.insert(connections, RunService.RenderStepped:Connect(function()
		if shadow.Parent then
			shadow.Position = main.Position
		end
	end))
	main:GetPropertyChangedSignal("Visible"):Connect(function()
		shadow.Visible = main.Visible
	end)

	local mainStroke = create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 0.8,
		Parent = main,
	})
	gradient(mainStroke, ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.Accent),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, theme.Accent2),
	}), NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.5, 0.92),
		NumberSequenceKeypoint.new(1, 0.45),
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
		NumberSequenceKeypoint.new(0, 0.84),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(1, 0.92),
	}), 115)

	create("Frame", {
		Parent = main,
		Size = UDim2.new(1, -36, 0, 1),
		Position = UDim2.new(0.5, 0, 0, 1),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 3,
	})

	local topbar = create("Frame", {
		Parent = main,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	topbar.Active = true

	local titleLabel = create("TextLabel", {
		Parent = topbar,
		Position = UDim2.fromOffset(20, 13),
		Size = UDim2.new(1, -80, 0, 20),
		BackgroundTransparency = 1,
		Text = cfg.Title or "Zaka UI",
		Font = theme.FontBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})
	gradient(titleLabel, AccentGradient, NumberSequence.new(0.02), 0)

	create("TextLabel", {
		Parent = topbar,
		Position = UDim2.fromOffset(20, 34),
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
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 8,
	})
	circle(closeBtn)
	local closeStroke = stroke(closeBtn, Color3.fromRGB(255, 255, 255), 0.88, 1)
	drawX(closeBtn, 13, theme.Sub, 9)
	hoverable(closeBtn, 1, 0.9, closeStroke)
	closeBtn.Activated:Connect(function()
		win:Close()
	end)

	table.insert(connections, dragify(topbar, main))

	local sidebar = create("Frame", {
		Parent = main,
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(0, 72, 1, -56),
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
		Position = UDim2.new(0, 72, 0, 56),
		Size = UDim2.new(0, 1, 1, -56),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 5,
	})

	local content = create("Frame", {
		Parent = main,
		Position = UDim2.fromOffset(73, 56),
		Size = UDim2.new(1, -73, 1, -56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	padding(content, 10, 10, 4, 8)
	win.Content = content

	table.insert(connections, dragify(toggleBtn, toggleBtn, function()
		win:Toggle()
	end))

	local function openPopup(anchor, width, height, popupCfg)
		popupCfg = popupCfg or {}
		local overlay = create("TextButton", {
			Parent = main,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 60,
		})
		local headerH = 30
		local totalH = height + headerH
		local abs = anchor.AbsolutePosition - main.AbsolutePosition
		local px = abs.X + anchor.AbsoluteSize.X - width
		px = math.clamp(px, 8, math.max(8, main.AbsoluteSize.X - width - 8))
		local py = abs.Y + anchor.AbsoluteSize.Y + 6
		if py + totalH > main.AbsoluteSize.Y - 8 then
			py = math.max(8, abs.Y - totalH - 6)
		end
		local pop = create("Frame", {
			Parent = main,
			Position = UDim2.fromOffset(px, py),
			Size = UDim2.fromOffset(width, totalH),
			BackgroundColor3 = Color3.fromRGB(17, 17, 24),
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 61,
		})
		corner(pop, 12)
		stroke(pop, Color3.fromRGB(255, 255, 255), 0.84, 1)
		local popScale = create("UIScale", { Scale = 0.88, Parent = pop })
		tween(popScale, { Scale = 1 }, 0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		local header = create("Frame", { Parent = pop, Size = UDim2.new(1, 0, 0, headerH), BackgroundTransparency = 1, ZIndex = 62 })
		create("TextLabel", {
			Parent = header,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -50, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(popupCfg.Title or ""),
			Font = theme.FontBold,
			TextSize = 11,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 63,
		})
		local xBtn = drawX(header, 22, theme.Sub, 63, Vector2.new(1, 0.5), UDim2.new(1, -15, 0.5, 0))
		local xStroke = stroke(xBtn, Color3.fromRGB(255, 255, 255), 1, 1)
		hoverable(xBtn, 1, 0.9, xStroke)

		create("Frame", {
			Parent = pop,
			Position = UDim2.fromOffset(10, headerH - 1),
			Size = UDim2.new(1, -20, 0, 1),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			ZIndex = 62,
		})

		local body = create("Frame", {
			Parent = pop,
			Position = UDim2.fromOffset(0, headerH),
			Size = UDim2.new(1, 0, 1, -headerH),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 61,
		})

		local closed = false
		local function close()
			if closed then
				return
			end
			closed = true
			xBtn.Active = false
			tween(popScale, { Scale = 0.94 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tween(pop, { BackgroundTransparency = 1 }, 0.16)
			task.delay(0.17, function()
				pop:Destroy()
				overlay:Destroy()
			end)
		end
		xBtn.Activated:Connect(close)
		return body, overlay, close
	end

	win.OpenPopup = openPopup

	function win:CreateTab(tabCfg)
		tabCfg = tabCfg or {}
		local tab = setmetatable({
			Window = win,
			Theme = theme,
			Name = tabCfg.Name or ("Tab " .. (#win.Tabs + 1)),
			Order = 0,
			Elements = {},
			Index = #win.Tabs + 1,
		}, Tab)

		local btn = create("TextButton", {
			Parent = sidebar,
			Size = UDim2.fromOffset(54, 52),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			LayoutOrder = tab.Index,
			ZIndex = 7,
		})
		corner(btn, 13)

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
			Position = UDim2.fromOffset(0, 7),
			Size = UDim2.new(1, 0, 0, 21),
			BackgroundTransparency = 1,
			ZIndex = 8,
		})

		local iconObj = makeIcon(holder, tabCfg.Icon or string.sub(tab.Name, 1, 1), 17, theme.Sub, 9)
		local iconScale = create("UIScale", { Scale = 1, Parent = iconObj })

		local nameLabel = create("TextLabel", {
			Parent = btn,
			Position = UDim2.fromOffset(0, 32),
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
		tab.IconScale = iconScale
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
		btn.Activated:Connect(function()
			win:SelectTab(tab)
			ripple(btn, 27, 26)
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
			tween(t.Indicator, { Size = active and UDim2.new(0, 3, 0, 24) or UDim2.new(0, 3, 0, 0) }, 0.28, Enum.EasingStyle.Back)
			tintIcon(t.Icon, active and Color3.fromRGB(255, 255, 255) or theme.Sub)
			tween(t.NameLabel, { TextColor3 = active and Color3.fromRGB(255, 255, 255) or theme.Sub }, 0.2)
		end
		if tab.IconScale then
			tab.IconScale.Scale = 0.7
			tween(tab.IconScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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

	local function staggerCurrent()
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

	function win:Open()
		if win.IsOpen then
			return
		end
		win.IsOpen = true
		main.Visible = true
		mainScale.Scale = 0.9
		tween(mainScale, { Scale = 1 }, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(toggleIcon, { Rotation = 180 }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		if blur then
			blur.Enabled = true
			blur.Size = 0
			tween(blur, { Size = blurTarget }, 0.35)
		end
		staggerCurrent()
	end

	function win:Close()
		if not win.IsOpen then
			return
		end
		win.IsOpen = false
		tween(mainScale, { Scale = 0.9 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(toggleIcon, { Rotation = 0 }, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if blur then
			tween(blur, { Size = 0 }, 0.2)
			task.delay(0.21, function()
				if not win.IsOpen and blur then
					blur.Enabled = false
				end
			end)
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
				Size = UDim2.fromOffset(268, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ZIndex = 300,
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
			Size = UDim2.fromOffset(268, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(15, 15, 22),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = win.NotifyCount,
			ZIndex = 301,
		})
		corner(toast, 12)
		stroke(toast, Color3.fromRGB(255, 255, 255), 0.85, 1)

		local accentBar = create("Frame", {
			Parent = toast,
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = notifyCfg.Color or theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 303,
		})
		gradient(accentBar, AccentGradient, NumberSequence.new(0), 90)

		local inner = create("Frame", {
			Parent = toast,
			Size = UDim2.fromScale(1, 1),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(38, 0),
			ZIndex = 302,
		})
		padding(inner, 16, 12, 11, 13)

		local titleRow = create("Frame", { Parent = inner, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, ZIndex = 303 })
		create("TextLabel", {
			Parent = titleRow,
			Size = UDim2.new(1, -24, 1, 0),
			BackgroundTransparency = 1,
			Text = notifyCfg.Title or "提示",
			Font = theme.FontBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 304,
		})
		local nx = drawX(titleRow, 16, theme.Sub, 304, Vector2.new(1, 0.5), UDim2.new(1, -8, 0.5, 0))

		create("TextLabel", {
			Parent = inner,
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = notifyCfg.Content or "",
			Font = theme.Font,
			TextSize = 11,
			TextColor3 = theme.Sub,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 304,
		})

		local progressBg = create("Frame", { Parent = toast, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92, BorderSizePixel = 0, ZIndex = 303 })
		local progress = create("Frame", { Parent = progressBg, Size = UDim2.fromScale(1, 1), BackgroundColor3 = notifyCfg.Color or theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 304 })
		gradient(progress, AccentGradient, NumberSequence.new(0), 0)

		local duration = notifyCfg.Duration or 4
		local progressTween
		local dead = false
		local function dismiss()
			if dead then
				return
			end
			dead = true
			if progressTween then
				progressTween:Cancel()
			end
			tween(progress, { Size = UDim2.fromScale(0, 1) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tween(inner, { Position = UDim2.fromOffset(38, 0) }, 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tween(toast, { BackgroundTransparency = 1 }, 0.24)
			task.delay(0.25, function()
				if toast then
					toast:Destroy()
				end
			end)
		end

		nx.Activated:Connect(dismiss)
		toast.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dismiss()
			end
		end)

		task.delay(0.02, function()
			if not toast.Parent then
				return
			end
			tween(toast, { BackgroundTransparency = 0.03 }, 0.3)
			tween(accentBar, { BackgroundTransparency = 0 }, 0.3)
			tween(progress, { BackgroundTransparency = 0 }, 0.3)
			tween(inner, { Position = UDim2.fromOffset(0, 0) }, 0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			progressTween = tween(progress, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)
		end)
		task.delay(duration, dismiss)
		return dismiss
	end

	function win:Destroy()
		for _, conn in ipairs(connections) do
			pcall(function()
				conn:Disconnect()
			end)
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
		Size = UDim2.new(1, -6, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = self.Order,
		ZIndex = 8,
	})
	local bar = create("Frame", {
		Parent = row,
		Position = UDim2.fromOffset(4, 10),
		Size = UDim2.fromOffset(3, 11),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	corner(bar, 3)
	gradient(bar, AccentGradient, NumberSequence.new(0), 90)
	create("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -8, 0, 14),
		BackgroundTransparency = 1,
		Text = string.upper(tostring(titleText or "SECTION")),
		Font = self.Theme.FontBold,
		TextSize = 10,
		TextColor3 = self.Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})
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

	create("TextLabel", {
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
		local titleLbl = row:FindFirstChildOfClass("TextLabel")
		titleLbl.Position = UDim2.fromOffset(14, 7)
		titleLbl.Size = UDim2.new(1, -80, 0, 14)
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

	local glow = create("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -7, 0.5, 0),
		Size = UDim2.fromOffset(52, 34),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	circle(glow)
	gradient(glow, AccentGradient, NumberSequence.new(0.2), 0)

	local track = create("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = Color3.fromRGB(52, 54, 66),
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	circle(track)
	stroke(track, Color3.fromRGB(255, 255, 255), 0.86, 1)

	local trackGrad = create("Frame", {
		Parent = track,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	circle(trackGrad)
	gradient(trackGrad, AccentGradient, NumberSequence.new(0.05), 0)

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
	stroke(knob, Color3.fromRGB(230, 232, 245), 0.4, 1)

	local function apply(value, silent)
		state = value and true or false
		tween(track, { BackgroundColor3 = state and theme.Accent or Color3.fromRGB(52, 54, 66) }, 0.2)
		tween(trackGrad, { BackgroundTransparency = state and 0.15 or 1 }, 0.2)
		tween(glow, { BackgroundTransparency = state and 0.62 or 1 }, 0.25)
		tween(knob, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, 0.26, Enum.EasingStyle.Back)
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = state
		end
		if not silent and cfg.Callback then
			task.spawn(cfg.Callback, state)
		end
	end

	row.Activated:Connect(function()
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
		Size = UDim2.new(1, -120, 0, 14),
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
		Size = UDim2.new(0, 100, 0, 14),
		BackgroundTransparency = 1,
		Text = "",
		Font = theme.FontBold,
		TextSize = 11,
		TextColor3 = theme.Text,
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
		BackgroundColor3 = Color3.fromRGB(55, 57, 70),
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

	local halo = create("Frame", {
		Parent = holder,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
	})
	circle(halo)

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
		tween(halo, { Position = UDim2.new(percent, 0, 0.5, 0) }, 0.1)
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
			tween(halo, { BackgroundTransparency = 0.7 }, 0.15)
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
			tween(halo, { BackgroundTransparency = 0.85 }, 0.25)
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
	local scale = row:FindFirstChildOfClass("UIScale")
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
	gradient(lbl, ColorSequence.new(Color3.fromRGB(255, 255, 255)), NumberSequence.new(0.05), 0)
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if scale then
				tween(scale, { Scale = 0.98 }, 0.1)
			end
		end
	end)
	row.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if scale then
				tween(scale, { Scale = 1 }, 0.18, Enum.EasingStyle.Back)
			end
		end
	end)
	row.Activated:Connect(function()
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
		width = 600
	end
	local bodyHeight = measureText(text, width - 170, theme.Font, 12)
	local hasImage = cfg.Image and cfg.Image ~= ""
	local imageHeight = cfg.ImageHeight or 120
	local headHeight = 0
	if cfg.Title and cfg.Title ~= "" then
		headHeight = 20
	end
	local total = headHeight + bodyHeight + 24 + (hasImage and (imageHeight + 10) or 0)

	local row = self.Window.Element(self, total)

	if cfg.Title and cfg.Title ~= "" then
		local bar = create("Frame", { Parent = row, Position = UDim2.fromOffset(14, 13), Size = UDim2.fromOffset(3, 11), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 9 })
		corner(bar, 3)
		gradient(bar, AccentGradient, NumberSequence.new(0), 90)
		create("TextLabel", {
			Parent = row,
			Position = UDim2.fromOffset(23, 10),
			Size = UDim2.new(1, -37, 0, 15),
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
		tween(boxStroke, { Transparency = 0.1, Color = theme.Accent }, 0.18)
		tween(box, { BackgroundTransparency = 0.87 }, 0.18)
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
	local btnStroke = stroke(btn, Color3.fromRGB(255, 255, 255), 0.9, 1)
	padding(btn, 10, 24, 0, 0)

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

	local chev = drawChevron(btn, 11, theme.Sub, 11)

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
	btn.Activated:Connect(function()
		if closeCurrent then
			closeCurrent()
			closeCurrent = nil
			tween(chev, { Rotation = 0 }, 0.2)
			return
		end
		local listHeight = math.min(#options * 26 + 12, 160)
		local body, _, closeFn = self.Window.OpenPopup(btn, 190, listHeight, { Title = cfg.Title or "选择" })
		closeCurrent = function()
			closeFn()
			closeCurrent = nil
			tween(chev, { Rotation = 0 }, 0.2)
		end
		tween(chev, { Rotation = 180 }, 0.2)

		local scroll = create("ScrollingFrame", {
			Parent = body,
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
		padding(scroll, 6, 6, 6, 6)

		for index, option in ipairs(options) do
			local optBtn = create("TextButton", {
				Parent = scroll,
				Size = UDim2.new(1, 0, 0, 25),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				ZIndex = 63,
			})
			corner(optBtn, 7)

			local optLbl = create("TextLabel", {
				Parent = optBtn,
				Position = UDim2.fromOffset(9, 0),
				Size = UDim2.new(1, -14, 1, 0),
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
				optBtn.BackgroundTransparency = 0.85
				optLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				optLbl.Font = theme.FontBold
			end

			optBtn.MouseEnter:Connect(function()
				tween(optBtn, { BackgroundTransparency = 0.92 }, 0.14)
			end)
			optBtn.MouseLeave:Connect(function()
				local nowActive = multi and selected[tostring(option)] or (not multi and single == option)
				tween(optBtn, { BackgroundTransparency = nowActive and 0.85 or 1 }, 0.16)
			end)

			optBtn.Activated:Connect(function()
				if multi then
					if selected[tostring(option)] then
						selected[tostring(option)] = nil
					else
						selected[tostring(option)] = true
					end
					local nowActive = selected[tostring(option)] == true
					tween(optBtn, { BackgroundTransparency = nowActive and 0.85 or 1 }, 0.15)
					optLbl.TextColor3 = nowActive and Color3.fromRGB(255, 255, 255) or theme.Text
					optLbl.Font = nowActive and theme.FontBold or theme.Font
					refreshText()
					fire()
				else
					single = option
					refreshText()
					fire()
					if closeCurrent then
						closeCurrent()
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
	stroke(swatch, Color3.fromRGB(255, 255, 255), 0.65, 1)

	local function fire()
		if cfg.Flag then
			self.Window.Flags[cfg.Flag] = color
		end
		if cfg.Callback then
			task.spawn(cfg.Callback, color)
		end
	end

	local closeCurrent
	swatch.Activated:Connect(function()
		if closeCurrent then
			closeCurrent()
			return
		end
		local body, _, closeFn = self.Window.OpenPopup(swatch, 224, 172, { Title = cfg.Title or "颜色" })
		closeCurrent = function()
			closeCurrent = nil
			closeFn()
		end

		local sv = create("Frame", {
			Parent = body,
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.fromOffset(204, 100),
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
			Parent = body,
			Position = UDim2.fromOffset(10, 116),
			Size = UDim2.fromOffset(204, 12),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 62,
		})
		corner(hueBar, 6)
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
			Size = UDim2.fromOffset(10, 16),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 65,
		})
		corner(hueCursor, 4)

		local preview = create("Frame", {
			Parent = body,
			Position = UDim2.fromOffset(10, 138),
			Size = UDim2.fromOffset(46, 26),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 62,
		})
		corner(preview, 7)
		stroke(preview, Color3.fromRGB(255, 255, 255), 0.65, 1)

		local hexBox = create("TextBox", {
			Parent = body,
			Position = UDim2.fromOffset(64, 138),
			Size = UDim2.fromOffset(150, 26),
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
		local hexStroke = stroke(hexBox, Color3.fromRGB(255, 255, 255), 0.9, 1)
		hexBox.Focused:Connect(function()
			tween(hexStroke, { Transparency = 0.1, Color = theme.Accent }, 0.15)
		end)
		hexBox.FocusLost:Connect(function()
			tween(hexStroke, { Transparency = 0.9, Color = Color3.fromRGB(255, 255, 255) }, 0.2)
		end)

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
		btn.Activated:Connect(function()
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
