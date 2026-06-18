local RunService = game:GetService('RunService')
local Stats = game:GetService('Stats')

local repo = 'https://raw.githubusercontent.com/Ethereoushook/sdk.cc-lib/main/'
local Compile = loadstring or load
assert(Compile, 'Your injector does not support loadstring/load')

local function MakeUrl(path)
    return repo .. path .. '?cache=' .. tostring(math.random(1, 999999999))
end

local function HttpGet(url)
    if game.HttpGet then
        return game:HttpGet(url)
    end

    if game.HttpGetAsync then
        return game:HttpGetAsync(url)
    end

    if httpget then
        return httpget(url)
    end

    if syn and syn.request then
        local res = syn.request({ Url = url, Method = 'GET' })
        return res and res.Body
    end

    if http_request then
        local res = http_request({ Url = url, Method = 'GET' })
        return res and res.Body
    end

    if request then
        local res = request({ Url = url, Method = 'GET' })
        return res and res.Body
    end

    error('No supported HTTP request function found')
end

local function LoadModule(path, expectedField)
    local source = HttpGet(MakeUrl(path))

    assert(type(source) == 'string', 'Invalid response for ' .. path)
    assert(source:match('%S'), 'Empty response for ' .. path)

    local chunk, err = Compile(source)
    assert(chunk, 'Failed to compile: ' .. path .. '\n' .. tostring(err))

    local ok, result = pcall(chunk)
    assert(ok, 'Runtime error in ' .. path .. '\n' .. tostring(result))
    assert(result ~= nil, 'Module returned nil: ' .. path)

    if expectedField then
        assert(type(result) == 'table' and result[expectedField] ~= nil, 'Invalid module result: ' .. path)
    end

    return result
end

local Library = LoadModule('Library.lua', 'CreateWindow')
local ThemeManager = LoadModule('ThemeManager.lua')
local SaveManager = LoadModule('SaveManager.lua')

local WINDOW_TITLE = 'sdk.cc'
local WINDOW_SUBTITLE = game.Name

local Window = Library:CreateWindow({
    Title = WINDOW_TITLE,
    SubTitle = WINDOW_SUBTITLE,
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local function ApplyRuntimeUiFixes()
    local Holder = Window.Holder
    if not Holder then
        return
    end

    local Inner
    for _, Child in ipairs(Holder:GetChildren()) do
        if Child:IsA('Frame') and Child.Size.X.Scale == 1 and Child.Position.Y.Offset == 25 then
            Inner = Child
            break
        end
    end

    if Inner then
        local TitleLabel
        local SeparatorLabel
        local SubLabel

        for _, Desc in ipairs(Inner:GetDescendants()) do
            if Desc:IsA('TextLabel') then
                if Desc.Text == WINDOW_TITLE then
                    TitleLabel = Desc
                elseif Desc.Text == '\\' then
                    SeparatorLabel = Desc
                elseif Desc.Text == WINDOW_SUBTITLE then
                    SubLabel = Desc
                end
            end
        end

        if TitleLabel and SeparatorLabel and SubLabel then
            local LogoFrame = Inner:FindFirstChild('RuntimeLogoHolder')
            if not LogoFrame then
                LogoFrame = Instance.new('Frame')
                LogoFrame.Name = 'RuntimeLogoHolder'
                LogoFrame.BackgroundTransparency = 1
                LogoFrame.BorderSizePixel = 0
                LogoFrame.Parent = Inner
            end

            LogoFrame.Position = UDim2.new(0, 0, 0, -20)
            LogoFrame.Size = UDim2.new(1, 0, 0, 25)
            LogoFrame.ZIndex = 50

            TitleLabel.Parent = LogoFrame
            SeparatorLabel.Parent = LogoFrame
            SubLabel.Parent = LogoFrame

            TitleLabel.Position = UDim2.new(0, 0, 0, 0)
            TitleLabel.Size = UDim2.new(0, 55, 0, 25)
            TitleLabel.ZIndex = 51
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

            SeparatorLabel.Position = UDim2.new(0, 55, 0, 0)
            SeparatorLabel.Size = UDim2.new(0, 9, 0, 25)
            SeparatorLabel.ZIndex = 51
            SeparatorLabel.TextXAlignment = Enum.TextXAlignment.Left

            SubLabel.Position = UDim2.new(0, 70, 0, 0)
            SubLabel.Size = UDim2.new(0, 87, 0, 25)
            SubLabel.ZIndex = 51
            SubLabel.TextXAlignment = Enum.TextXAlignment.Left
        end
    end

    local PreviewButtonsParent
    for _, Desc in ipairs(Holder:GetDescendants()) do
        if Desc:IsA('TextLabel') and (Desc.Text == 'Preview 1' or Desc.Text == 'Preview 2') then
            local Button = Desc.Parent
            if Button and Button:IsA('Frame') then
                PreviewButtonsParent = Button.Parent
                break
            end
        end
    end

    if PreviewButtonsParent and PreviewButtonsParent:IsA('Frame') then
        PreviewButtonsParent.Position = UDim2.new(0, 6, 0, 14)
        PreviewButtonsParent.Size = UDim2.new(1, -12, 0, 20)

        local Buttons = {}
        for _, Child in ipairs(PreviewButtonsParent:GetChildren()) do
            if Child:IsA('Frame') then
                table.insert(Buttons, Child)
            end
        end

        table.sort(Buttons, function(a, b)
            return a.AbsolutePosition.X < b.AbsolutePosition.X
        end)

        for Index, Button in ipairs(Buttons) do
            Button.Size = UDim2.new(0.5, -4, 1, 0)
            Button.Position = UDim2.new(Index == 1 and 0 or 0.5, Index == 1 and 0 or 4, 0, 0)
        end
    end
end

local Tabs = {
    Main = Window:AddTab('Main'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

local MainLeft = Tabs.Main:AddLeftGroupbox('Aiming')
MainLeft:AddToggle('SilentAim', {
    Text = 'Silent Aim',
    Default = false
}):AddKeyPicker('SilentAimKey', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Silent Aim',
    NoUI = false
})

MainLeft:AddToggle('TpBullet', {
    Text = 'TpBullet',
    Default = true
}):AddKeyPicker('TpBulletKey', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'TpBullet',
    NoUI = false
})

MainLeft:AddSlider('HitChance', {
    Text = 'Hit Chance',
    Default = 75,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = '%'
})

MainLeft:AddDropdown('AimPart', {
    Text = 'Aim Part',
    Values = { 'Head', 'HumanoidRootPart', 'UpperTorso' },
    Default = 1,
    Multi = false
})

local MainRight = Tabs.Main:AddRightGroupbox('Visual style preview')
MainRight:AddButton('Notify test', function()
    Library:Notify('Test notification', 3)
end)

MainRight:AddButton('Notify long text', function()
    Library:Notify('This is a longer notification so you can see the new style better.', 4)
end)

MainRight:AddToggle('WatermarkToggle', {
    Text = 'Show Watermark',
    Default = true,
    Callback = function(Value)
        Library:SetWatermarkVisibility(Value)
    end
})

MainRight:AddToggle('KeybindListToggle', {
    Text = 'Show Keybinds',
    Default = true,
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

local MiscLeft = Tabs.Misc:AddLeftGroupbox('Player')
MiscLeft:AddToggle('SpeedEnabled', {
    Text = 'Speed',
    Default = false
}):AddKeyPicker('SpeedKey', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Speed',
    NoUI = false
})

MiscLeft:AddSlider('WalkSpeed', {
    Text = 'Walk Speed',
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0
})

MiscLeft:AddInput('CustomText', {
    Text = 'Custom watermark text',
    Default = 'sdk.cc',
    Finished = true
})

local MiscRight = Tabs.Misc:AddRightTabbox('Tabbox preview')
local PreviewTab1 = MiscRight:AddTab('Preview 1')
PreviewTab1:AddToggle('PreviewToggle1', { Text = 'Example Toggle' })
PreviewTab1:AddSlider('PreviewSlider1', {
    Text = 'Example Slider',
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0
})

local PreviewTab2 = MiscRight:AddTab('Preview 2')
PreviewTab2:AddDropdown('PreviewDropdown2', {
    Text = 'Example Dropdown',
    Values = { 'One', 'Two', 'Three' },
    Default = 1,
    Multi = false
})
PreviewTab2:AddToggle('PreviewToggle2', { Text = 'Second Toggle' })

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function()
    Library:Unload()
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI = true,
    Text = 'Menu keybind'
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('sdk.cc-lib')
SaveManager:SetFolder('sdk.cc-lib/demo')

ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:BuildConfigSection(Tabs['UI Settings'])

Library.KeybindFrame.Visible = true
Library:SetWatermarkVisibility(true)

Toggles.WatermarkToggle:OnChanged(function()
    Library:SetWatermarkVisibility(Toggles.WatermarkToggle.Value)
end)

Toggles.KeybindListToggle:OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.KeybindListToggle.Value
end)

task.spawn(function()
    local FrameTimer = tick()
    local FrameCounter = 0
    local FPS = 0

    while true do
        FrameCounter = FrameCounter + 1

        if (tick() - FrameTimer) >= 1 then
            FPS = FrameCounter
            FrameTimer = tick()
            FrameCounter = 0
        end

        local Prefix = Options.CustomText.Value ~= '' and Options.CustomText.Value or 'sdk.cc'

        local Ping = 0
        pcall(function()
            Ping = math.floor(Stats.Network.ServerStatsItem['Data Ping']:GetValue())
        end)

        Library:SetWatermark(('%s | %s fps | %s ms'):format(
            Prefix,
            math.floor(FPS),
            Ping
        ))

        ApplyRuntimeUiFixes()
        RunService.RenderStepped:Wait()
    end
end)
