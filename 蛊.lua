local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "蛊API翻译",
    Icon = "language",
    Author = "蛊API翻译",
    Folder = "GuAPITranslation",
    Size = UDim2.fromOffset(680, 520),
    Theme = "Dark",
    User = {
        Enabled = true,
        Callback = function() end,
        Anonymous = false,
        Username = game.Players.LocalPlayer.Name
    },
})

local OpenButton = Window:EditOpenButton({
    Title = "蛊API翻译",
    Icon = "language",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 3,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("FF4444")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("CC0000"))
    }),
    Draggable = true,
})

-- ==================== 核心引擎数据+逻辑 ====================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local MY_NAMESPACE = "EnhancedTranslator_" .. tostring(math.random(10000, 99999))
if not _G[MY_NAMESPACE] then
    _G[MY_NAMESPACE] = {
        textData = {},
        scannedElements = {},
        translatedElements = {},
        monitorConnections = {},
        translateQueue = {},
        queuedSet = {},
        isProcessingQueue = false,
        isRunning = false,
        extractCount = 0,
        translateCount = 0,
        localizeCount = 0,
        pendingCount = 0,
        totalScan = 0,
        cache = {},
    }
end
local Engine = _G[MY_NAMESPACE]

-- 运行时配置
local RUNTIME = {
    translationAPI = "Google",
    customAPIUrl = "",
    translationsPerSecond = 25,
    batchSize = 8,
    scanInterval = 3,
    minTextLength = 1,
    maxTextLength = 150,
    CACHE_ENABLED = false,
    excludeChinese = true
}

-- 缓存函数
local function loadCacheFromFile() end
local function saveCacheToFile() end
local function clearCache()
    Engine.cache = {}
    Window:Notify({
        Title = "缓存已清空", 
        Content = "翻译缓存已被清空", 
        Duration = 2
    })
end

-- 文本过滤
local function shouldFilterText(text)
    if not text or text:gsub("%s+", "") == "" then return true end
    if #text < RUNTIME.minTextLength or #text > RUNTIME.maxTextLength then return true end
    if RUNTIME.excludeChinese and text:find("[一-龥㗊𠀀-𪛟]") then return true end
    return false
end

-- 翻译函数
local function translateWithGoogle(orig)
    local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=" .. HttpService:UrlEncode(orig)
    local ok, body = pcall(function() return game:HttpGet(url, true, {["User-Agent"] = "Mozilla/5.0"}) end)
    if not ok or not body then return orig end
    local parsedOk, parsed = pcall(function() return HttpService:JSONDecode(body) end)
    if not parsedOk or not parsed[1] then return orig end
    local parts = {}
    for _, seg in ipairs(parsed[1]) do if seg[1] then table.insert(parts, seg[1]) end end
    return table.concat(parts)
end

local function translateText(orig)
    if shouldFilterText(orig) then return orig end
    if Engine.cache[orig] then return Engine.cache[orig] end
    local translation = translateWithGoogle(orig)
    if translation ~= orig then
        Engine.cache[orig] = translation
        Engine.translateCount = Engine.translateCount + 1
    end
    return translation
end

-- 扫描+应用函数
local function scanAllGuiElements()
    Engine.totalScan = Engine.totalScan + 1
    local guis = {CoreGui, LocalPlayer.PlayerGui}
    for _, gui in ipairs(guis) do
        if gui then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local ok, text = pcall(function() return desc.Text end)
                    if ok and text then
                        Engine.extractCount = Engine.extractCount + 1
                        local translation = translateText(text)
                        if translation ~= text then
                            pcall(function() desc.Text = translation end)
                            Engine.localizeCount = Engine.localizeCount + 1
                        end
                    end
                end
            end
        end
    end
    Window:Notify({
        Title = "扫描完成", 
        Content = "已扫描所有界面元素", 
        Duration = 2
    })
end

local function applyLocalizations()
    local localizedCount = 0
    local guis = {CoreGui, LocalPlayer.PlayerGui}
    for _, gui in ipairs(guis) do
        if gui then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local ok, text = pcall(function() return desc.Text end)
                    if ok and text then
                        local translation = translateText(text)
                        if translation ~= text then
                            pcall(function() desc.Text = translation end)
                            localizedCount = localizedCount + 1
                        end
                    end
                end
            end
        end
    end
    if localizedCount > 0 then
        Window:Notify({
            Title = "汉化应用", 
            Content = "应用了 "..localizedCount.." 个翻译", 
            Duration = 2
        })
    end
end

-- 启动/停止函数
local function startService()
    if Engine.isRunning then return end
    Engine.isRunning = true
    Window:Notify({
        Title = "服务启动", 
        Content = "开始扫描和翻译文本", 
        Duration = 2
    })
    spawn(function()
        while Engine.isRunning do
            scanAllGuiElements()
            applyLocalizations()
            task.wait(RUNTIME.scanInterval)
        end
    end)
end

local function stopService()
    if not Engine.isRunning then return end
    Engine.isRunning = false
    Window:Notify({
        Title = "服务停止", 
        Content = "翻译服务已关闭", 
        Duration = 2
    })
end

-- ==================== Wind UI界面 ====================

-- 1. 翻译控制Tab
local TranslateControlTab = Window:Tab({
    Title = "翻译控制",
    Icon = "play-circle",
    LayoutOrder = 1
})

TranslateControlTab:Paragraph({
    Title = "支持实时界面汉化和智能文本检测",
    Content = "自动扫描游戏界面并翻译为中文"
})

-- 启动翻译服务开关
local serviceToggle = TranslateControlTab:Toggle({
    Title = "启动翻译服务",
    Value = false,
    Callback = function(enabled)
        if enabled then 
            startService() 
        else 
            stopService() 
        end
    end
})

TranslateControlTab:Divider()

-- 立即扫描+强制应用按钮
TranslateControlTab:Button({
    Title = "立即扫描界面",
    Callback = scanAllGuiElements
})

TranslateControlTab:Button({
    Title = "强制应用翻译",
    Callback = applyLocalizations
})

TranslateControlTab:Divider()

-- 实时状态显示
TranslateControlTab:Paragraph({
    Title = "实时状态",
    Content = string.format(
        "服务状态: %s\n当前API: %s\n提取文本: %d\n已翻译: %d\n已应用: %d\n待翻译: %d\n总扫描: %d",
        Engine.isRunning and "✅ 运行中" or "❌ 已停止",
        RUNTIME.translationAPI,
        Engine.extractCount,
        Engine.translateCount,
        Engine.localizeCount,
        Engine.pendingCount,
        Engine.totalScan
    )
})

-- 2. API设置Tab
local APISettingTab = Window:Tab({
    Title = "API设置",
    Icon = "settings",
    LayoutOrder = 2
})

-- 翻译API选择
local apiDropdown = APISettingTab:Dropdown({
    Title = "翻译API",
    Options = {"Google", "Baidu", "Tencent", "Custom"},
    Default = "Google",
    Callback = function(selected)
        RUNTIME.translationAPI = selected
    end
})

-- 自定义API URL
local customAPIInput = APISettingTab:TextBox({
    Title = "自定义API URL",
    Placeholder = "输入自定义API URL",
    Callback = function(value)
        RUNTIME.customAPIUrl = value
    end
})

APISettingTab:Divider()

-- 文本过滤设置
APISettingTab:Slider({
    Title = "最小文本长度",
    Step = 1,
    Value = {Min = 1, Max = 20, Default = RUNTIME.minTextLength},
    Callback = function(value)
        RUNTIME.minTextLength = value
    end
})

APISettingTab:Slider({
    Title = "最大文本长度",
    Step = 1,
    Value = {Min = 50, Max = 300, Default = RUNTIME.maxTextLength},
    Callback = function(value)
        RUNTIME.maxTextLength = value
    end
})

APISettingTab:Toggle({
    Title = "排除中文文本",
    Value = RUNTIME.excludeChinese,
    Callback = function(enabled)
        RUNTIME.excludeChinese = enabled
    end
})

-- 3. 高级功能Tab
local AdvancedFuncTab = Window:Tab({
    Title = "高级功能",
    Icon = "zap",
    LayoutOrder = 3
})

-- 性能设置
AdvancedFuncTab:Slider({
    Title = "每秒翻译数",
    Step = 1,
    Value = {Min = 5, Max = 50, Default = RUNTIME.translationsPerSecond},
    Callback = function(value)
        RUNTIME.translationsPerSecond = value
    end
})

AdvancedFuncTab:Slider({
    Title = "批处理大小",
    Step = 1,
    Value = {Min = 1, Max = 20, Default = RUNTIME.batchSize},
    Callback = function(value)
        RUNTIME.batchSize = value
    end
})

AdvancedFuncTab:Slider({
    Title = "扫描间隔(秒)",
    Step = 1,
    Value = {Min = 1, Max = 10, Default = RUNTIME.scanInterval},
    Callback = function(value)
        RUNTIME.scanInterval = value
    end
})

AdvancedFuncTab:Divider()

-- 缓存管理
AdvancedFuncTab:Toggle({
    Title = "启用翻译缓存",
    Value = RUNTIME.CACHE_ENABLED,
    Callback = function(enabled)
        RUNTIME.CACHE_ENABLED = enabled
    end
})

AdvancedFuncTab:Button({
    Title = "清空翻译缓存",
    Callback = clearCache
})

AdvancedFuncTab:Button({
    Title = "重置翻译状态",
    Callback = function()
        Engine.extractCount = 0
        Engine.translateCount = 0
        Engine.localizeCount = 0
        Engine.totalScan = 0
        Window:Notify({
            Title = "状态重置",
            Content = "所有计数器已重置",
            Duration = 2
        })
    end
})

-- 实时更新状态
spawn(function()
    while true do
        task.wait(1)
        -- 更新状态显示
        local statusContent = string.format(
            "服务状态: %s\n当前API: %s\n提取文本: %d\n已翻译: %d\n已应用: %d\n待翻译: %d\n总扫描: %d",
            Engine.isRunning and "✅ 运行中" or "❌ 已停止",
            RUNTIME.translationAPI,
            Engine.extractCount,
            Engine.translateCount,
            Engine.localizeCount,
            Engine.pendingCount,
            Engine.totalScan
        )
        
        -- 这里需要找到Paragraph元素并更新内容
        -- 由于WindUI API限制，可能需要其他方式更新状态
    end
end)

print("蛊API翻译界面已加载完成！")