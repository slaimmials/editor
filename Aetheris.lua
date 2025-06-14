local DEBUG = false
local DEBUG_SUB = {hooks = {}}
function DEBUG_SUB:Connect(Name, Desc, Func)
    DEBUG_SUB.hooks[Desc] = {Name,Func}
end
concommand.Add("AE_DEBUG", function()
    DEBUG = not DEBUG
    if DEBUG then
        for desc,data in pairs(DEBUG_SUB.hooks) do
            hook.Add(data[1], desc, data[2])
        end
    else
        for desc,data in pairs(DEBUG_SUB.hooks) do
            hook.Remove(data[1], desc)
        end
    end
    print("[Aetheris] Debug "..(DEBUG and "Enabled" or "Disabled"))
end)

local floor = math.floor
local abs = math.abs
local GetPlayers = player.GetAll
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local ScrW = ScrW
local ScrH = ScrH
local Color = Color
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_SetTextColor = surface.SetTextColor
local surface_SetFont = surface.SetFont
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local Vector = Vector

local moduleInstalled = pcall(function()
    require("zxcmodule")
end)
if not moduleInstalled then
    error("[Aetheris] Please install module")
    return;
end

function math.Lerp(value, fraction, valueTo)
    local diff = value-valueTo
    local lerpValue = diff*fraction
    if diff < 0 then 
        value = value + lerpValue
    elseif diff > 0 then
        value = value - lerpValue
    end
    return value
end

local function distanceSqr(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return dx*dx + dy*dy
end

local LibUI = {
	Frames = {},
	CurrentFrame = nil,
	ElementMargin = 1,
}
surface.CreateFont("ESP_SemiBig", {
	font = "Arial",
	size = 16,
	weight = 5000,
	antialias = true,
})
surface.CreateFont("ESP_Medium", {
	font = "Arial",
	size = 10,
	weight = 5000,
	antialias = true,
})
surface.CreateFont("ESP_Small", {
	font = "Arial",
	size = 8,
	weight = 5000,
	antialias = true,
})
surface.CreateFont("ESP_SmallS", {
	font = "Arial",
	size = 8,
	weight = 5000,
	antialias = true,
    shadow = true
})
surface.CreateFont("ESP_Big", {
	font = "Arial",
	size = 20,
	weight = 5000,
	antialias = true,
})
local lastFrameX = 10
function LibUI:NewFrame(name, title, sameLine)
    title = title or name
    sameLine = sameLine or false
	local frame = {
		Name = name,
		VGUI = {
			Frame = vgui.Create("DFrame"),
			Elements = {},
			YOffset = 30,
			AutoPosition = { x = 5, y = 30 },
		},
	}

    local yLine = 10
    if sameLine then
        local xSize, ySize = self.CurrentFrame.VGUI.Frame:GetSize()
        lastFrameX = lastFrameX-xSize-10
        yLine = 10 + ySize + 10
    end

	frame.VGUI.Frame:SetTitle("")
    frame.VGUI.Frame:ShowCloseButton(false)
	frame.VGUI.Frame:SetDraggable(true)
	frame.VGUI.Frame:SetSize(150, 0)
	frame.VGUI.Frame:Center()
	frame.VGUI.Frame:SetVisible(false)
    frame.VGUI.Frame:SetPos(lastFrameX, yLine)
    --if popup then
        frame.VGUI.Frame:MakePopup()
    --end
    local sizeX, sizeY = frame.VGUI.Frame:GetSize()
    lastFrameX = lastFrameX+sizeX+10
    function frame.VGUI.Frame:Paint(w, h)
        surface_SetDrawColor(60,60,60,255)
        surface_DrawRect(0,0,w,h)
        surface_SetDrawColor(96, 180, 100, 255)
        surface_DrawRect(0,0,w,25)
        surface_SetTextColor(255,255,255,255)
        draw.SimpleText(title, "ESP_Big", 150/2, 25/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

	function frame.VGUI:AddElement(element, height)
		element:SetPos(self.AutoPosition.x, self.AutoPosition.y)
		element:SetWidth(self.Frame:GetWide() - 10)
		if height then
			element:SetHeight(height)
		end
		self.AutoPosition.y = self.AutoPosition.y + (height or 20) + LibUI.ElementMargin

		if self.AutoPosition.y + 30 > self.Frame:GetTall() then
			self.Frame:SetTall(self.AutoPosition.y + 30)
            frame.VGUI.Frame:SetSize(sizeX, self.AutoPosition.y)
		end
	end

	self.CurrentFrame = frame
	self.Frames[name] = frame
	return frame
end

function LibUI:ShowFrame(name)
	if self.Frames[name] and self.Frames[name].VGUI.Frame then
		self.Frames[name].VGUI.Frame:SetVisible(true)
		self.Frames[name].VGUI.Frame:MoveToFront()
	end
end

function LibUI:HideFrame(name)
	if self.Frames[name] and self.Frames[name].VGUI.Frame then
		self.Frames[name].VGUI.Frame:SetVisible(false)
	end
end

function LibUI:Button(text, onClick)
	if not self.CurrentFrame then
		return
	end
	local btn = vgui.Create("DButton", self.CurrentFrame.VGUI.Frame)
	btn:SetText("")
    local BGColor = Color(40,40,40)
    function btn:Paint(w,h)
        BGColor = BGColor:Lerp(Color(40,40,40), 0.05)
        surface.SetDrawColor(BGColor.r, BGColor.g, BGColor.b)
        surface.DrawRect(0,0,w,h)
        draw.SimpleText(text, "ESP_SemiBig", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
	btn.DoClick = function()
        BGColor = Color(96,180,100)
        onClick()
    end
	self.CurrentFrame.VGUI:AddElement(btn, 25)
	return btn
end

function LibUI:Label(text)
	if not self.CurrentFrame then
		return
	end
	local lbl = vgui.Create("DLabel", self.CurrentFrame.VGUI.Frame)
    lbl:SetFont("ESP_SemiBig")
	lbl:SetText(text)
	lbl:SetTextColor(Color(255, 255, 255))
	lbl:SizeToContents()
	self.CurrentFrame.VGUI:AddElement(lbl)
	return lbl
end

function LibUI:CheckBox(text, onChange, bindable)
    if not self.CurrentFrame then return end

    local panel = vgui.Create("DPanel", self.CurrentFrame.VGUI.Frame)
    panel:SetBackgroundColor(Color(0,0,0,0))

    local chk = vgui.Create("DCheckBox", panel)
    chk:SetPos(0, 2)
    function chk:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40))
        if chk:GetChecked() then
            surface_SetDrawColor(96, 180, 100)
        else
            surface_SetDrawColor(60, 60, 60)
        end
        surface_DrawRect(2, 2, w - 4, h - 4)
    end

    local lbl = vgui.Create("DLabel", panel)
    lbl:SetFont("ESP_SemiBig")
    lbl:SetText(text)
    lbl:SetTextColor(Color(255,255,255))
    lbl:SizeToContents()
    lbl:SetPos(20, 0)

    local bindInfo = { key = nil, mode = "Toggle" }
    local gear

    if bindable then
        local gearMat = Material("icon16/cog.png")
        gear = vgui.Create("DButton", panel)
        gear:SetText("")
        gear:SetSize(20, 20)
        gear:SetPos(lbl.x + lbl:GetWide() + 5, 0)
        gear.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(60, 60, 60))
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(gearMat)
            surface.DrawTexturedRect(2, 2, w-4, h-4)
        end

        local function closePopup()
            if IsValid(panel._bindPopup) then
                panel._bindPopup:Remove()
                panel._bindPopup = nil
            end
            if panel._popupCatcher then
                panel._popupCatcher:Remove()
                panel._popupCatcher = nil
            end
        end

        local function openBindPopup()
            if IsValid(panel._bindPopup) then
                closePopup()
                return
            end

            local btnW, btnH = 140, 28
            local comboH = 20
            local popupW = btnW + 20
            local popupH = btnH + comboH + 25

            local popupCatcher = vgui.Create("DPanel")
            popupCatcher:SetDrawOnTop(true)
            popupCatcher:SetPos(0, 0)
            popupCatcher:SetSize(ScrW(), ScrH())
            popupCatcher:SetAlpha(0)
            popupCatcher:SetMouseInputEnabled(true)
            function popupCatcher:Paint() end
            function popupCatcher:OnMousePressed()
                closePopup()
            end
            panel._popupCatcher = popupCatcher

            local popup = vgui.Create("DFrame")
            popup:SetTitle("")
            popup:SetSize(popupW, popupH)
            popup:ShowCloseButton(false)
            popup:SetDraggable(false)
            popup:SetDrawOnTop(true)
            popup.Paint = function(_, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50, 240))
            end

            local gx, gy = gear:LocalToScreen(0, gear:GetTall())
            popup:SetPos(gx - 10, gy + 5)
            popup:MakePopup()
            panel._bindPopup = popup

            local BGColor = Color(40,40,40)
            local btnText = bindInfo.key and string.upper(bindInfo.key) or "click to bind"

            local binderBtn = vgui.Create("DButton", popup)
            binderBtn:SetText("")
            binderBtn:SetSize(btnW, btnH)
            binderBtn:SetPos(10, 10)
            binderBtn.Paint = function(self, w, h)
                BGColor = BGColor:Lerp(Color(40,40,40), 0.05)
                if self:IsHovered() then
                    BGColor = BGColor:Lerp(Color(60,60,60), 0.2)
                end
                surface.SetDrawColor(BGColor.r, BGColor.g, BGColor.b)
                surface.DrawRect(0,0,w,h)
                draw.SimpleText(btnText, "ESP_SemiBig", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            local isBinding = false
            binderBtn.DoClick = function()
                isBinding = true
                btnText = "press any key"
                binderBtn:InvalidateLayout()
            end

            local combo = vgui.Create("DComboBox", popup)
            combo:SetPos(10, 10 + btnH + 4)
            combo:SetSize(btnW, comboH)
            combo:SetText("")
            local ComboBGColor = Color(40,40,40)
            function combo:Paint(w,h)
                combo:SetText("")
                ComboBGColor = ComboBGColor:Lerp(Color(40,40,40), 0.05)
                surface.SetDrawColor(ComboBGColor.r, ComboBGColor.g, ComboBGColor.b)
                surface.DrawRect(0,0,w,h)
                local ctext = combo:GetSelected()
                ctext = ctext or bindInfo.mode or "tf did you bind"
                draw.SimpleText(ctext, "ESP_SemiBig", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            combo.OnMenuOpened = function(self, menu)
                menu.Paint = function(panel, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
                end
                for _, child in pairs(menu:GetCanvas():GetChildren()) do
                    if child:GetName() == "DMenuOption" then
                        child.Paint = function(option, w, h)
                            option:SetTextColor({255,255,255,0})
                            if option.Hovered then
                                draw.RoundedBox(0, 0, 0, w, h, Color(96, 180, 100, 255))
                            else
                                draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
                            end
                            draw.SimpleText(option:GetText(), "ESP_SemiBig", 10, h/2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end
                    end
                end
            end

            combo:AddChoice("Toggle")
            combo:AddChoice("Hold")
            combo:SetValue(bindInfo.mode or "Toggle")
            combo.OnSelect = function(_, idx, value, data)
                bindInfo.mode = value
            end

            local isBinding = false
            local pressedKeys = {}

            binderBtn.DoClick = function()
                isBinding = true
                btnText = "press any key"
                binderBtn:InvalidateLayout()
                pressedKeys = {}
                for i = 1, 159 do
                    if input.IsKeyDown(i) then
                        pressedKeys[i] = true
                    end
                end
                for i = MOUSE_LEFT, MOUSE_LAST do
                    if input.IsMouseDown(i) then
                        pressedKeys[i] = true
                    end
                end
            end

            popup.Think = function()
                if isBinding then
                    for i = 1, 159 do
                        if input.IsKeyDown(i) and not pressedKeys[i] then
                            local name = input.GetKeyName(i)
                            if name then
                                bindInfo.key = name
                                isBinding = false
                                btnText = string.upper(name)
                                binderBtn:InvalidateLayout()
                                surface.PlaySound("buttons/button15.wav")
                                return
                            end
                        end
                    end
                    for i = MOUSE_LEFT, MOUSE_LAST do
                        if input.IsMouseDown(i) and not pressedKeys[i] then
                            local name = input.GetKeyName(i)
                            if name then
                                bindInfo.key = name
                                isBinding = false
                                btnText = string.upper(name)
                                binderBtn:InvalidateLayout()
                                surface.PlaySound("buttons/button15.wav")
                                return
                            end
                        end
                    end
                end
            end

            function popup:OnRemove()
                closePopup()
            end
        end

        gear.DoClick = openBindPopup
    end

    hook.Add("Think", panel, function()
        if not bindInfo.key then return end
        local code = input.GetKeyCode(bindInfo.key)
        local mouseCode
        for i = MOUSE_LEFT, MOUSE_LAST do
            if bindInfo.key == input.GetKeyName(i) then
                code = nil
                mouseCode = i
                break
            end
        end

        if bindInfo.mode == "Toggle" then
            local pressed = code and input.IsKeyDown(code) or (mouseCode and input.IsMouseDown(mouseCode))
            if pressed then
                if not panel._bindPressed then
                    chk:SetChecked(not chk:GetChecked())
                    chk.OnChange(chk, not held)
                    panel._bindPressed = true
                end
            else
                panel._bindPressed = false
            end
        elseif bindInfo.mode == "Hold" then
            local held = code and input.IsKeyDown(code) or (mouseCode and input.IsMouseDown(mouseCode))
            chk:SetChecked(held)
            chk.OnChange(chk, held)
        end
    end)

    local totalWidth = lbl.x + lbl:GetWide()
    if gear then
        totalWidth = gear.x + gear:GetWide()
    end
    panel:SetSize(totalWidth + 10, 20)

    if onChange then
        chk.OnChange = function(_, val)
            onChange(val)
        end
    end

    self.CurrentFrame.VGUI:AddElement(panel, 20)
    return chk, function() return bindInfo.key, bindInfo.mode end
end

function LibUI:Slider(text, min, max, defaultValue, onChange)
    if not self.CurrentFrame then
        return
    end
    
    local panel = vgui.Create("DPanel", self.CurrentFrame.VGUI.Frame)
    panel:SetBackgroundColor(Color(0, 0, 0, 0))
    panel:SetTall(40)

    local lbl = vgui.Create("DLabel", panel)
    lbl:SetFont("ESP_SemiBig")
    lbl:SetText(text)
    lbl:SizeToContents()
    lbl:SetPos(0, 0)

    local sliderPanel = vgui.Create("DPanel", panel)
    sliderPanel:SetSize(140, 20)
    sliderPanel:SetPos(0, 20)
    sliderPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40))
        draw.RoundedBox(0, 3, 3, w - 6, h - 6, Color(60,60,60))

        local fillWidth = (w - 6) * math.Clamp((self.Value - min) / (max - min), 0, 1)
        draw.RoundedBox(0, 3, 3, fillWidth, h - 6, Color(96, 180, 100))
        surface.SetFont("ESP_SemiBig")
        local textW, textH = surface.GetTextSize(tostring(math.Round(self.Value or defaultValue, 1)))
        local align = TEXT_ALIGN_LEFT
        local margin = 5
        if w-(fillWidth+margin) < textW then
            align = TEXT_ALIGN_RIGHT
            margin = 0
        end
        draw.SimpleText(tostring(math.Round(self.Value or defaultValue, 1)), "ESP_SemiBig", fillWidth + margin, h/2, Color(255, 255, 255), align, TEXT_ALIGN_CENTER)
    end

    local slider = vgui.Create("DNumSlider", sliderPanel)
    slider:SetPos(0, 0)
    slider:SetSize(140, 20)
    slider:SetMin(min)
    slider:SetMax(max)
    slider:SetValue(defaultValue)
    slider:SetText("")
    slider:SetDark(true)
    slider.Slider:SetNotches(0)

    slider.Scratch:SetVisible(false)
    slider.Label:SetVisible(false)
    slider.TextArea:SetVisible(false)
    slider.Slider.Knob:SetVisible(false)

    function slider.Slider:Paint()
    end

    slider.OnValueChanged = function(_, val)
        sliderPanel.Value = val
        sliderPanel:InvalidateLayout()
        
        if onChange then
            onChange(val)
        end
    end
    
    sliderPanel.Value = defaultValue

    self.CurrentFrame.VGUI:AddElement(panel, 43)
    return slider
end

function LibUI:DropDown(text, options, defaultValue, onChange)
    if not self.CurrentFrame then return end
    
    local panel = vgui.Create("DPanel", self.CurrentFrame.VGUI.Frame)
    panel:SetBackgroundColor(Color(0,0,0,0))
    
    local lbl = vgui.Create("DLabel", panel)
    lbl:SetFont("ESP_SemiBig")
    lbl:SetText(text)
    lbl:SetTextColor(Color(255,255,255))
    lbl:SizeToContents()
    lbl:SetPos(0, 0)
    
    local combo = vgui.Create("DComboBox", panel)
    combo:SetPos(0, 20)
    combo:SetSize(140, 20)
    combo:SetText("")
    local BGColor = Color(40,40,40)
    function combo:Paint(w,h)
        combo:SetText("")
        BGColor = BGColor:Lerp(Color(40,40,40), 0.05)
        surface.SetDrawColor(BGColor.r, BGColor.g, BGColor.b)
        surface.DrawRect(0,0,w,h)
        local text = combo:GetSelected()
        text = text or defaultValue or "Nothing"
        draw.SimpleText(text, "ESP_SemiBig", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    combo.OnMenuOpened = function(self, menu)
        menu.Paint = function(panel, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
        end

        for _, child in pairs(menu:GetCanvas():GetChildren()) do
            if child:GetName() == "DMenuOption" then
                child.Paint = function(option, w, h)
                    option:SetTextColor({255,255,255,0})
                    if option.Hovered then
                        draw.RoundedBox(0, 0, 0, w, h, Color(96, 180, 100, 255))
                    else
                        draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
                    end
                    draw.SimpleText(option:GetText(), "ESP_SemiBig", 10, h/2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end
    end

    for key, value in pairs(options) do
        if type(value) == "table" then
            combo:AddChoice(value["text"], nil, false, value["icon"])
        else
            combo:AddChoice(value)
        end
    end
    
    if defaultValue then
        combo:SetValue(defaultValue)
    end
    
    if onChange then
        combo.OnSelect = function(_, index, value, data)
            onChange(data or value)
        end
    end
    
    self.CurrentFrame.VGUI:AddElement(panel, 45)
    return combo
end

function LibUI:MultiDropDown(text, options, defaultSelected, onChange)
    if not self.CurrentFrame then return end

    local panel = vgui.Create("DPanel", self.CurrentFrame.VGUI.Frame)
    panel:SetBackgroundColor(Color(0,0,0,0))

    local lbl = vgui.Create("DLabel", panel)
    lbl:SetFont("ESP_SemiBig")
    lbl:SetText(text)
    lbl:SetTextColor(Color(255,255,255))
    lbl:SizeToContents()
    lbl:SetPos(0, 0)

    local btn = vgui.Create("DButton", panel)
    btn:SetPos(0, 20)
    btn:SetSize(140, 20)
    btn:SetText("")
    local BGColor = Color(40,40,40)
    local selected = {}
    for key,_ in pairs(options) do selected[key] = false end
    if defaultSelected then for _,k in ipairs(defaultSelected) do selected[k] = true end end

    local function getDisplayText()
        local sel = {}
        for k,v in pairs(selected) do if v then table.insert(sel, options[k]) end end
        if #sel == 0 then return "Nothing"
        elseif #sel <= 2 then return table.concat(sel, ", ")
        else return "Выбрано: " .. #sel end
    end

    function btn:Paint(w,h)
        BGColor = BGColor:Lerp(Color(40,40,40), 0.05)
        surface.SetDrawColor(BGColor.r, BGColor.g, BGColor.b)
        surface.DrawRect(0,0,w,h)
        draw.SimpleText(getDisplayText(), "ESP_SemiBig", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local menuOpened = false
    function btn:DoClick()
        local menu = DermaMenu()
        menu:SetMinimumWidth(btn:GetWide())
        menu.Paint = function(panel, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
        end
        for key, value in pairs(options) do
            local opt = menu:AddOption("", function() end)
            opt:SetText("")
            opt.Paint = function(option, w, h)
                if selected[key] then
                    draw.RoundedBox(0, 0, 0, w, h, Color(96, 180, 100, 255))
                elseif option.Hovered then
                    draw.RoundedBox(0, 0, 0, w, h, Color(70, 70, 70, 255))
                else
                    draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
                end
                draw.SimpleText(value, "ESP_SemiBig", 10, h/2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            opt.OnMousePressed = function(option, mcode)
                if mcode == MOUSE_LEFT then
                    selected[key] = not selected[key]
                    btn:InvalidateLayout()
                    menu:InvalidateLayout()
                    if onChange then
                        local arr = {}
                        for k,v in pairs(selected) do if v then table.insert(arr, k) end end
                        onChange(arr)
                    end
                end
            end
        end
        if menuOpened then
            menu:Hide()
            menuOpened = false
        else
            menu:Open()
            menuOpened = true
        end
        
        menu:SetPos(btn:LocalToScreen(0, btn:GetTall()))
    end
    menu.OnRemove = function(self)
        menuOpened = false
    end
    self.CurrentFrame.VGUI:AddElement(panel, 45)

    function btn:GetSelectedKeys()
        local arr = {}
        for k,v in pairs(selected) do if v then table.insert(arr, k) end end
        return arr
    end
    function btn:SetSelectedKeys(tab)
        for k,_ in pairs(selected) do selected[k]=false end
        for _,k in ipairs(tab) do selected[k]=true end
        btn:InvalidateLayout()
    end

    return btn
end
----------MAIN CODE-----------

local Aimbot = {
	Enabled = false,
    Silent = false,
    TeamCheck = false,
    WallCheck = false,
    VRecoil = false,
    AutoFire = false,
	FOV = 6,
    Smoothness = 0,

    Shooting = false,
	Target = nil,
	PredictTypes = {},
    Angle = Angle(0,0,0),
}

local Visuals = {
	Wallhack = false,
    Nametags = false,
    Dormant = false,
	Health = false,
    Weapon = false,
    Chams = false,
    Ammo = false,
    Box = false,

    NametagArea = ScrH()/6,
    Radar = { 
        Enabled = false,
        Viewangles = false,
        NearInfo = false,
        Size = 200,
    },
}

local BHopSettings = {
    Enabled = false,
    AutoStrafe = false,
    State = false,
    StrafeSpeed = 400,
    LastJumpTime = 0,
    LastYaw = 0
}

local Misc = {
    Thirdperson = {
        Enabled = false,
        Distance = 100,
    },
    Observer = {
        Enabled = false,
        Target = nil,
        Mode = 1,
        Distance = 100,
        CameraAngle = Angle(0, 0, 0),
        OriginalViewAngles = Angle(0, 0, 0),
        MouseSensitivity = 1,
        Plrs = {}
    },
    Viewmodel = { 
        X = 50, 
        Y = 50, 
        Z = 50 
    },
    FOV = GetConVar("fov_desired"):GetFloat(),
    Taunts = false,
}

local HvH = {
    LagOnPeek = false,
    OverLOP = false,
    AntiAim = {
        Enabled = false,
        Yaw = "Forward",
        Pitch = "Viewangles",
        RealAngles = Angle(0,0,0),
        YawDrop = nil,

    },
    Resolver = {
        Enabled = false,
        Yaw = 0,
        Pitch = 90
    },
}

--------UI STRUCTING----------

LibUI:NewFrame("AIMBOT")
LibUI:CheckBox("Enable", function(val)Aimbot.Enabled = val end, true)
--LibUI:CheckBox("Auto penetration", function(val)Aimbot.AutoPenetration = val end) --TODO
LibUI:CheckBox("Team check", function(val)Aimbot.TeamCheck = val end)
LibUI:CheckBox("Wall check", function(val)Aimbot.WallCheck = val end)
LibUI:CheckBox("Auto fire", function(val)Aimbot.AutoFire = val end)
LibUI:CheckBox("Silent", function(val)Aimbot.Silent = val end)
LibUI:MultiDropDown("Predict", {
    ["Velocity"] = "Velocity",
    ["Ping"] = "Ping",
	["Ballistics"] = "Ballistics",
}, {}, function(selected)
    Aimbot.PredictTypes = selected
end)
LibUI:Slider("FOV", 1, 180, Aimbot.FOV, function(val)Aimbot.FOV = val end)
LibUI:Slider("Smoothness", 0, 1, Aimbot.Smoothness, function(val)Aimbot.Smoothness = val end)
LibUI:CheckBox("No vrecoil", function(val)Aimbot.VRecoil = val end)
--LibUI:CheckBox("No recoil", function(val)Aimbot.Recoil = val end) --TODO
--LibUI:CheckBox("No spread", function(val)Aimbot.Spread = val end) --TODO
----
LibUI:NewFrame("VISUALS")
LibUI:CheckBox("Wallhack", function(val) Visuals.Wallhack = val end)
LibUI:CheckBox("Nametags", function(val) Visuals.Nametags = val end)
LibUI:CheckBox("Dormant", function(val) Visuals.Dormant = val end)
LibUI:CheckBox("Weapon", function(val) Visuals.Weapon = val end)
LibUI:CheckBox("Chams",  function(val)  Visuals.Chams = val end)
LibUI:CheckBox("Health",function(val) Visuals.Health = val end)
LibUI:CheckBox("Ammo", function(val) Visuals.Ammo = val end)
LibUI:CheckBox("Box", function(val)Visuals.Box = val end)
LibUI:Slider("Nametag area", 0, ScrW(), ScrH()/6, function(val) Visuals.NametagArea = val end)
----
LibUI:NewFrame("RADAR", nil, true)
LibUI:CheckBox("Enabled", function(val) Visuals.Radar.Enabled = val end)
LibUI:CheckBox("Nearest info", function(val) Visuals.Radar.NearInfo = val end)
LibUI:CheckBox("Viewangles", function(val) Visuals.Radar.Viewangles = val end)
LibUI:Slider("Size", 160, 400, Visuals.Radar.Size, function(val) Visuals.Radar.Size = val end)
----
LibUI:NewFrame("MISCELLANEOUS") 
LibUI:Button("Hide menu", function()
    for name in pairs(LibUI.Frames) do
        LibUI:HideFrame(name)
    end
end)
LibUI:CheckBox("Disable taunts", function(val) Misc.Taunts = val end)
LibUI:CheckBox("Enable BHop",function(val) BHopSettings.Enabled = val end)
LibUI:CheckBox("Autostrafe", function(val) BHopSettings.AutoStrafe = val end)
--LibUI:CheckBox("Free camera", function(val) Misc.FreeCamera = val end) --TODO
----
LibUI:NewFrame("OBSERVER",nil,true) 
LibUI:CheckBox("Enabled", function(val) Misc.Observer.Enabled = val end)
local observerTargetList = LibUI:DropDown("Target", {
}, "", function(val)
    for i, ply in ipairs( player.GetAll() ) do
        if ply:Name() == val then
            Misc.Observer.Target = ply
            break
        end
    end
end)
LibUI:DropDown("Mode", {
    "Firstperson",
    "Thirdperson"
}, "Thirdperson", function(val)
    if val == "Firstperson" then
        Misc.Observer.Mode = 2
    elseif val == "Thirdperson" then
        Misc.Observer.Mode = 1
    end
end)
LibUI:Slider("Distance ", 0, 250, Misc.Observer.Distance, function(val) Misc.Observer.Distance = val end)
----
LibUI:NewFrame("HVH") 
LibUI:CheckBox("Lag on peek", function(val)HvH.LagOnPeek = val end,true)
LibUI:Slider("lag factor", 30, 90, 70, function(val)HvH.LagFactor = val end)
LibUI:CheckBox("Overlag", function(val)HvH.OverLOP = val end)
LibUI:CheckBox("Anti aim", function(val)HvH.AntiAim.Enabled = val end)
HvH.AntiAim.YawDrop = LibUI:DropDown("Yaw", {
    "Left",
    "Right",
    "Sideways",
    "Forward",
    "Backward",
}, HvH.AntiAim.Yaw, function(val)
    HvH.AntiAim.Yaw = val
end)
LibUI:DropDown("Pitch", {
    "Viewangles",
    "Forward",
    "Up",
    "Down",
}, HvH.AntiAim.Pitch, function(val)
    HvH.AntiAim.Pitch = val
end)
LibUI:CheckBox("Resolver", function(val) HvH.Resolver.Enabled = val end)
LibUI:Slider("Yaw", 0, 360, HvH.Resolver.Yaw, function(val) HvH.Resolver.Yaw = val end)
--LibUI:Slider("Pitch", 0, 180, HvH.Resolver.Pitch, function(val) HvH.Resolver.Pitch = val end) --TODO
----
LibUI:NewFrame("VIEW")
LibUI:CheckBox("Thirdperson", function(val) Misc.Thirdperson.Enabled = val end)
LibUI:Slider("Distance", 0, 250, Misc.Thirdperson.Distance, function(val) Misc.Thirdperson.Distance = val end)
LibUI:Slider("FOV", 0, 360, Misc.FOV, function(val) Misc.FOV = val end)
LibUI:Slider("Viewmodel X", 0, 100, Misc.Viewmodel.X, function(val) Misc.Viewmodel.X = val end)
LibUI:Slider("Viewmodel Y", 0, 100, Misc.Viewmodel.Y, function(val) Misc.Viewmodel.Y = val end)
LibUI:Slider("Viewmodel Z", 0, 100, Misc.Viewmodel.Z, function(val) Misc.Viewmodel.Z = val end)
--[[--
LibUI:NewFrame("CONFIG")
Config.Drop = LibUI:DropDown("Yaw", {
    "Left",
    "Right",
    "Sideways",
    "Forward",
    "Backward",
}, HvH.AntiAim.Yaw, function(val)
    HvH.AntiAim.Yaw = val
end)
--]]--
----------FUNCTIONS-----------

function distance(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt(dx * dx + dy * dy)
end

function rand_str(len)
	len = tonumber(len) or 1

	local function rand_char()
		return math.random() > 0.5 and string.char(math.random(65, 90)) or string.char(math.random(97, 122))
	end
	local function rand_num()
		return string.char(math.random(48, 57))
	end

	local str = ""
	for i = 1, len do
		str = str .. (math.random() > 0.5 and rand_char() or rand_num())
	end
	return str
end

function GetLoadedAmmo(ply)
    if not IsValid(ply) then return -1 end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return -1 end
    
    return wep:Clip1() or 0
end

function IsReloading(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return false end
    
    local act = wep:GetActivity()
    return act == ACT_VM_RELOAD or 
           act == ACT_VM_RELOAD_EMPTY or
           act == ACT_VM_RELOAD_SILENCED
end

local timeout = 0
hook.Add("Think", "BM_Clients_Key", function()
	if (timeout or 0) < CurTime() and input.IsKeyDown(KEY_DELETE) then
		timeout = CurTime() + 0.3
		if LibUI.CurrentFrame.VGUI.Frame:IsVisible() then
            for name in pairs(LibUI.Frames) do
                LibUI:HideFrame(name)
            end
		else
            for name in pairs(LibUI.Frames) do
                LibUI:ShowFrame(name)
            end
		end
	end
end)

local resetView = false
hook.Add("CreateMove", "Aimbot", function(cmd)
    if Aimbot.Enabled and not resetView and not HvH.AntiAim.Enabled then
        resetView = true
        local view = cmd:GetViewAngles()
        cmd:SetViewAngles(view - Aimbot.Angle)
        Aimbot.Angle = Angle(0,0,0)
        return
    end
    if (not Aimbot.Shooting or not Aimbot.Enabled) and HvH.AntiAim.Enabled and not resetView then 
        resetView = true
        local view = cmd:GetViewAngles()
        cmd:SetViewAngles(view - Aimbot.Angle)
        Aimbot.Angle = Angle(0,0,0)
        return
    end
    resetView = false

    local lplr = LocalPlayer()
    local cameraPos = lplr:GetShootPos()
    local cameraAng = cmd:GetViewAngles() - Aimbot.Angle
    local cameraForward = cameraAng:Forward()
    
    local bestDelta = Aimbot.FOV
    local bestTarget = nil

    for _, ply in ipairs(player.GetAll()) do
        if ply == lplr then continue end
        if not ply:Alive() then continue end
        if ply:Team() == lplr:Team() and Aimbot.TeamCheck then continue end
        if ply:IsDormant() then continue end

        local targetPos = ply:GetShootPos()
        local direction = (targetPos - cameraPos):GetNormalized()
        local angleDelta = math.deg(math.acos(cameraForward:Dot(direction)))
        
        if angleDelta < bestDelta then
            local trace = util.TraceLine({
                start = lplr:GetShootPos(),
                endpos = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1")),
                filter = function(ent) 
                    return ent ~= lplr
                end
            })

            if Aimbot.WallCheck then
                if not trace.Hit or trace.Entity ~= ply then
                    continue
                end
            end

            bestDelta = angleDelta
            bestTarget = ply
        end
    end

	Aimbot.Target = bestTarget

	if IsValid(Aimbot.Target) and not Aimbot.Target:IsDormant() and Aimbot.Enabled then
        local boneIndex = Aimbot.Target:LookupBone("ValveBiped.Bip01_Head1")
        local targetPos = (boneIndex and Aimbot.Target:GetBonePosition(boneIndex)) or Aimbot.Target:EyePos()
        if targetPos then
            targetPos = targetPos + Vector(0, 0, 1)
        end

        local predictionTime = 0
        if Aimbot.PredictTypes.Ping then
            predictionTime = predictionTime + (lplr:Ping() / 1000)
        end
        if Aimbot.PredictTypes.Ballistics then
            local weapon = lplr:GetActiveWeapon()
            if IsValid(weapon) and weapon.Primary and weapon.Primary.Speed then
                local distance = cameraPos:Distance(targetPos)
                local bulletSpeed = weapon.Primary.Speed
                predictionTime = predictionTime + (distance / bulletSpeed)
            end
        end

        local predictedPos = targetPos
        if Aimbot.PredictTypes.Velocity and predictionTime > 0 then
            local targetVel = Aimbot.Target:GetVelocity()
            predictedPos = predictedPos + targetVel * predictionTime
        end

        local targetAng = (predictedPos - cameraPos):Angle()
        local newAng = targetAng
        if Aimbot.Smoothness > 0 then
            newAng = LerpAngle((1 - Aimbot.Smoothness) * FrameTime() * 50, cameraAng, targetAng)
        end
        local function doAim()
            if Aimbot.Silent then
                Aimbot.Angle = Aimbot.Angle + newAng - LocalPlayer():EyeAngles()
            else
                Aimbot.Angle = Angle(0,0,0)
            end
            cmd:SetViewAngles(Angle(
                math.NormalizeAngle(newAng.p),
                math.NormalizeAngle(newAng.y),
                0
            ))
        end
        if cmd:KeyDown(IN_ATTACK) or not Aimbot.Silent then
            doAim()
        end

        if Aimbot.AutoFire and IsValid(Aimbot.Target) then
            local boneIndex = Aimbot.Target:LookupBone("ValveBiped.Bip01_Head1")
            if not boneIndex then return end
            local targetPos = Aimbot.Target:GetBonePosition(boneIndex)
            if not targetPos then return end

            local trace = util.TraceLine({
                start = lplr:GetShootPos(),
                endpos = targetPos,
                filter = function(ent) 
                    return ent ~= lplr
                end
            })
            
            if trace.Hit and trace.Entity == Aimbot.Target then
                Aimbot.Shooting = true
                doAim()
                cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK))
            else
                Aimbot.Shooting = false
            end
        end
    end
end)

local hudDrawingFake = {
	fakeRT = GetRenderTarget("fakeRT"..rand_str(math.random(10,20)), ScrW(), ScrH()),
	ENames = {
		Wallhack = rand_str(7),
        Radar = rand_str(7)
	},
}

function DrawText(text, x, y, r, g, b, a)
	surface.SetFont("ESP_Medium")
	surface.SetTextColor(0, 0, 0, 255)
	surface.SetTextPos(x, y - 2)
	surface.DrawText(text)

	surface.SetTextColor(r or 255, g or 255, b or 255, a or 255)
	surface.SetFont("ESP_Small")            
	surface.SetTextPos(x, y - 1)            
	surface.DrawText(text)          
end
local a_debug = ""
local screengrabWarn = 0

------Wallhack-----
hook.Add(hudDrawingFake.ENames.Wallhack .."HUDPaint", "Wallhack", function()
    surface_SetTextPos(ScrW()/2,ScrH()/2-100)
    surface_SetFont("ESP_Big")
    surface_SetTextColor(255,255,255,255)
	surface_DrawText(a_debug) --debug text output
    surface_SetFont("ESP_SmallS")
    surface_SetTextPos(4,ScrH()-10)
    surface_SetTextColor(255,255,255,255)
    surface_DrawText("Aetheris - v1.0") -- от cлова эфир - невидимая среда, символ легкости и всепроникновения

    if screengrabWarn > CurTime() then
        surface_SetFont("ESP_Big")
        surface_SetTextPos(ScrW()/2+40,ScrH()/2)
        surface_SetTextColor(255,0,0)
        surface_DrawText("You've been screengrabbed")
    end

	surface.SetTextPos(ScrW()/2,ScrH()/2)
    local lplr = LocalPlayer()
    local scrW, scrH = ScrW(), ScrH()
    local scrCenterX, scrCenterY = scrW/2, scrH/2
    
    if Aimbot.Enabled and Aimbot.FOV > 0 then
        local degree = scrW / lplr:GetFOV()
        surface_SetDrawColor(255, 255, 255, 255)
        surface.DrawCircle(scrCenterX, scrCenterY, (degree * Aimbot.FOV)/2, 255, 255, 255, 255)
    end

    if not Visuals.Wallhack then return end
    
    local players = GetPlayers()
    local showDormant = Visuals.Dormant
    
    for i = 1, #players do
        local ply = players[i]
        if not IsValid(ply) or ply == lplr or not ply:Alive() then continue end
        
        local isDormant = ply:IsDormant()
        if not showDormant and isDormant then continue end
        
        local pos = ply:GetPos()
        local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
        local headPos = headBone and (ply:GetBonePosition(headBone) + Vector(0, 0, 10)) or (pos + Vector(0, 0, 70))
        local bodyPos = pos + Vector(0, 0, 50)
        local feetPos = pos
        
        local headScreen = headPos:ToScreen()
        local bodyScreen = bodyPos:ToScreen()
        local feetScreen = feetPos:ToScreen()
        
        if not headScreen.visible and not feetScreen.visible then continue end
        
        local height = abs(headScreen.y - feetScreen.y)
        local width = height / 2
        local boxX = headScreen.x - width / 2
        local boxY = headScreen.y
        
        if Visuals.Box then
            local boxColor = isDormant and Color(90, 90, 90) or Color(0, 0, 255)
            local outlineColor = isDormant and Color(39, 39, 39) or Color(0, 0, 100)
            
            surface_SetDrawColor(boxColor)
            surface_DrawOutlinedRect(boxX, boxY, width, height)
            
            surface_SetDrawColor(outlineColor)
            surface_DrawOutlinedRect(boxX - 1, boxY - 1, width + 2, height + 2)
            surface_DrawOutlinedRect(boxX + 1, boxY + 1, width - 2, height - 2)
        end
        
        local health = ply:Health()
        local maxHealth = ply:GetMaxHealth()
        local healthPercentage = health / maxHealth
        
        if Visuals.Health then
            local healthX = boxX
            local healthY = boxY + height + 2
            local healthWidth = width * math.Clamp(healthPercentage, 0, 100)
            
            local healthColor = isDormant and 
                Color(100 * healthPercentage, 100 * healthPercentage, 100 * healthPercentage) or 
                Color(255 - 255 * healthPercentage, 255 * healthPercentage, 0)
            if healthPercentage*100 > 100 then
                healthColor = Color(190,0,255)
            end
            surface_SetDrawColor(healthColor)
            surface_DrawRect(healthX, healthY, healthWidth, 3)
            
            local healthText = floor(healthPercentage * 100) .. "%"
            surface_SetTextColor(255, 255, 255, 255)
            surface_SetFont("ESP_Small")
            surface_SetTextPos(healthX + healthWidth + 2, healthY - 4)
            surface_DrawText(healthText)
        end
        
        if Visuals.Nametags then
            local nameX = boxX
            local nameY = boxY - 20
            
            local drawName = true
            if Visuals.NametagArea then
                local distSqr = distanceSqr(nameX, nameY, scrCenterX, scrCenterY)
                drawName = distSqr <= (Visuals.NametagArea * Visuals.NametagArea)
            end
            
            if drawName then
                surface_SetTextColor(255, 255, 255, 255)
                surface_SetFont("ESP_Big")
                surface_SetTextPos(nameX, nameY)
                surface_DrawText(ply:GetName())
            end
        end
        
        if Visuals.Ammo then
            local ammoX = boxX + width + 2
            local ammoY = boxY - 2
            
            local ammoText = "0"
            if IsReloading(ply) then
                ammoText = "R"
            else
                local ammoCount = GetLoadedAmmo(ply)
                if ammoCount > 0 then
                    ammoText = tostring(ammoCount)
                end
            end
            
            local ammoColor = isDormant and Color(90, 90, 90) or Color(100, 100, 255)
            surface_SetTextColor(ammoColor)
            surface_SetFont("ESP_Big")
            surface_SetTextPos(ammoX, ammoY)
            surface_DrawText(ammoText)
        end

        if Visuals.Weapon then
            local weapon = ply:GetActiveWeapon()

            if IsValid(weapon) then
                draw.SimpleText(weapon:GetClass(), "ESP_Big", boxX+width/2, boxY+height+8, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    end

    if not surface.DrawFilledCircle then
        function surface.DrawFilledCircle( x, y, radius )
            local segments = 32
            local verts = {}
            table.insert(verts, {x = x, y = y})
            for i = 0, segments do
                local ang = math.rad((i / segments) * 360)
                table.insert(verts, { x = x + math.cos(ang) * radius, y = y + math.sin(ang) * radius })
            end
            draw.NoTexture()
            surface.DrawPoly(verts)
        end
    end
end)

------Chams-----
hook.Add("RenderScreenspaceEffects", "PostProcessingExample", function()
    if not Visuals.Wallhack then return end
	cam.Start3D()
        for _,ply in ipairs(player.GetAll()) do	
            if IsValid(ply) and ply:Alive() and ply ~= LocalPlayer() then
                if Visuals.Chams then
                    cam.IgnoreZ(true)
                    render.MaterialOverride(Material("models/wireframe"))
                    render.SetColorModulation(0.302,0.267,0.941)
                    ply:SetRenderMode(RENDERMODE_NORMAL)
                    --v:SetColor(Color(0,0,0,0))
                    ply:DrawModel()
                end
            end
        end
    cam.End3D()
end )

------Radar------
hook.Add(hudDrawingFake.ENames.Radar .."HUDPaint", "Radar", function()
    if Visuals.Radar.Enabled then
        local screenW, screenH = ScrW(), ScrH()
        local radarSize = Visuals.Radar.Size
        local margin = 20
        local radarX = screenW - radarSize - margin 
        local radarY = margin
        local maxDist = 2000

        local colorRadar = Color(96, 180, 100, 220) -- основной цвет (поле зрения, игрок, обводка)
        local colorRadarBG = Color(24, 30, 36, 200) -- фон радара
        local colorFov = Color(96, 180, 100, 60)    -- полупрозрачный сектор
        local colorEnemy = Color(255, 60, 60, 230)  -- цвет игроков

        local ply = LocalPlayer()
        local plyPos = ply:GetPos()
        local plyAng = ply:EyeAngles().y

        surface.SetDrawColor(colorRadarBG)
        surface.DrawRect(radarX, radarY, radarSize, radarSize)
        surface.SetDrawColor(colorRadar)
        surface.DrawOutlinedRect(radarX, radarY, radarSize, radarSize, 2)

        local centerX = radarX + radarSize * 0.5
        local centerY = radarY + radarSize * 0.5
        local radarRadius = radarSize * 0.5
        do
            local fov = 90
            local segments = 32
            local startAng = math.rad(-fov / 2)
            local endAng = math.rad(fov / 2)
            surface.SetDrawColor(colorFov)
            local verts = {}
            table.insert(verts, { x = centerX, y = centerY })
            for i = 0, segments do
                local ang = math.rad(plyAng) + startAng + (endAng - startAng) * (i / segments)
                local x = centerX + math.cos(ang) * radarRadius
                local y = centerY + math.sin(ang) * radarRadius
                table.insert(verts, { x = x, y = y })
            end
            draw.NoTexture()
            surface.DrawPoly(verts)
        end

        local myRadius = 9
        surface.SetDrawColor(colorRadar)
        surface.DrawCircle(centerX, centerY, myRadius, colorRadar.r, colorRadar.g, colorRadar.b, colorRadar.a)

        local enemyRadius = math.floor(myRadius / 3)
        local best = {dist = math.huge, ply = nil}
        for _, plr in ipairs(player.GetAll()) do
            if plr == ply or not plr:Alive() then continue end

            local plrAng = plr:EyeAngles().y
            local relPos = plr:GetPos() - plyPos
            local rx = relPos.x
            local ry = relPos.y
            local dist = math.sqrt(rx^2 + ry^2)
            if dist > maxDist then continue end
            local scale = radarRadius / maxDist
            local px = centerX + rx * scale
            local py = centerY + ry * scale

            if px < radarX + enemyRadius then px = radarX + enemyRadius end
            if px > radarX + radarSize - enemyRadius then px = radarX + radarSize - enemyRadius end
            if py < radarY + enemyRadius then py = radarY + enemyRadius end
            if py > radarY + radarSize - enemyRadius then py = radarY + radarSize - enemyRadius end
            surface.SetDrawColor(colorEnemy)
            draw.NoTexture()
            surface.DrawFilledCircle(px, py, enemyRadius)
            if Visuals.Radar.Viewangles then
                local rad = math.rad(plrAng)
                surface.DrawLine(px, py, px + (radarSize / 5) * math.cos(rad), py + (radarSize / 5) * math.sin(rad))
            end
            draw.DrawText(plr:GetName(), "ESP_Medium", px+enemyRadius+2, py-2, colorEnemy, TEXT_ALIGN_LEFT)
            if dist < best["dist"] then
                best["dist"] = dist
                best["x"] = px
                best["y"] = py
                best["ply"] = plr
            end 
        end
        if IsValid(best["ply"]) and Visuals.Radar.NearInfo then
            draw.DrawText(tostring(best["ply"]:Health()).." HP\n", "ESP_Medium", best["x"]+enemyRadius+2, best["y"]+enemyRadius+2, colorEnemy, TEXT_ALIGN_LEFT)
        end
    end
end)

------Anti screengrab------
if not _G._old_render_Capture then
    _G._old_render_Capture = render.Capture

    function render.Capture(tbl)
        screengrabWarn = CurTime() + 5
        return _G._old_render_Capture(tbl)
    end
end

hook.Add("RenderScene", "AntiScreenGrab", function(vOrigin, vAngle, vFOV)
    local view = {
        x = 0,
        y = 0,
        w = ScrW(),
        h = ScrH(),
        dopostprocess = true,
        origin = vOrigin,
        angles = vAngle,
        fov = vFOV,
        drawhud = true,
        drawmonitors = true,
        drawviewmodel = true,
    }

    render.RenderView(view)
    render.CopyRenderTargetToTexture(hudDrawingFake.fakeRT)

    cam.Start2D()
    for _, rName in pairs(hudDrawingFake.ENames) do
        hook.Run(rName .. "HUDPaint")
    end
    cam.End2D()

    render.SetRenderTarget(hudDrawingFake.fakeRT)

    return true
end)

hook.Add("ShutDown", "RemoveAntiScreenGrab", function()
	render.SetRenderTarget()
end)

--------BHOP---------
hook.Add("CreateMove", "BHopHandler", function(cmd)
    if not BHopSettings.Enabled then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local buttons = cmd:GetButtons()
    local current_time = CurTime()
    local current_angles = cmd:GetViewAngles()
    
    local want_jump = bit.band(buttons, IN_JUMP) ~= 0
    local on_ground = ply:OnGround()
    
    if want_jump then
        if on_ground then
            buttons = bit.bor(buttons, IN_JUMP)
            BHopSettings.LastJumpTime = current_time
            BHopSettings.State = true
        else
            buttons = bit.band(buttons, bit.bnot(IN_JUMP))
        end
    end
    
    if not on_ground and BHopSettings.AutoStrafe then
        local yaw_delta = math.AngleDifference(current_angles.y, BHopSettings.LastYaw)
        if yaw_delta > 0.1 then
            cmd:SetSideMove(-BHopSettings.StrafeSpeed)
        elseif yaw_delta < -0.1 then
            cmd:SetSideMove(BHopSettings.StrafeSpeed)
        else
            cmd:SetSideMove(0)
        end
    end
    
    BHopSettings.LastYaw = current_angles.y
    
    cmd:SetButtons(buttons)
end)

local RealAngles = Angle(0,0,0)

------------------------
hook.Add("CalcView", "ViewanglesFix", function(ply, pos, angles, fov)
    local drawviewer = false
    
    if Misc.FOV and Misc.FOV ~= 0 then
        fov = Misc.FOV
    end

    ----Thirdperson----
    if Misc.Thirdperson.Enabled then
        pos = pos - ( (angles - Aimbot.Angle):Forward() * Misc.Thirdperson.Distance )
        drawviewer = true
    end
    -------------------

    ----AIMBOT---
    if not Aimbot.Angle then
        Aimbot.Angle = Angle(0,0,0)
    else
        Aimbot.Angle.y = Aimbot.Angle.y % 360
        Aimbot.Angle.p = Aimbot.Angle.p % 360
    end
    if Aimbot.VRecoil then
        angles = angles - LocalPlayer():GetViewPunchAngles()
    end
    -------------

    ----OBSERVER----
    if Misc.Observer.Enabled and Misc.Observer.Target then
        local view = {
            fov = fov,
            drawviewer = Misc.Observer.Mode == 1
        }
        if Misc.Observer.Mode == 2 then
            view.origin = Misc.Observer.Target:EyePos()
            view.angles = Misc.Observer.CameraAngle
        else
            local targetPos = Misc.Observer.Target:EyePos()
            local camForward = Misc.Observer.CameraAngle:Forward()
            local camPos = targetPos - camForward * Misc.Observer.Distance

            local trace = util.TraceLine({
                start = targetPos,
                endpos = camPos,
                filter = {Misc.Observer.Target}
            })
            if trace.Hit then
                camPos = trace.HitPos + trace.HitNormal * 5
            end

            view.origin = camPos
            view.angles = Misc.Observer.CameraAngle
        end

        return view
    end
    ----------------
    HvH.AntiAim.RealAngles = angles - Aimbot.Angle
    local view = {
        origin = pos,
        angles = angles - Aimbot.Angle,
        fov = fov,
        drawviewer = drawviewer,
    }
    return view
end)
----------Fix movement----------
hook.Add("CreateMove", "Fix movement", function(cmd)
    local ply = LocalPlayer()
    if Aimbot.Angle and not ( ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetMoveType() == MOVETYPE_LADDER) then
        local realAng = cmd:GetViewAngles()
        local silentAng = realAng + Aimbot.Angle
        local deltaYaw = math.NormalizeAngle(silentAng.y - realAng.y)
        local rad = math.rad(deltaYaw)
        local forward = cmd:GetForwardMove()
        local side = cmd:GetSideMove()

        local newForward = math.cos(rad) * forward - math.sin(rad) * side
        local newSide = math.sin(rad) * forward + math.cos(rad) * side
        cmd:SetForwardMove(newForward)
        cmd:SetSideMove(newSide)
    end
end)

hook.Add("PrePlayerDraw", "preplayerdraw", function(ply)
    if ply == LocalPlayer() then return end
    if HvH.Resolver.Enabled then
        local ang = ply:EyeAngles()
        ang.y = ang.y + HvH.Resolver.Yaw
        ply:SetRenderAngles(ang)
        ply:SetNetworkAngles(ang)
        ply:SetAngles(ang)
        ply:InvalidateBoneCache()
    end

    if Misc.Taunts then
        ply.ChatGestureWeight = 0
        for i = 0, 13 do
            if ply:IsValidLayer(i) then
                local seqname = ply:GetSequenceName(ply:GetLayerSequence(i))
                if seqname:StartWith("taunt_") or seqname:StartWith("act_") or seqname:StartWith("gesture_") then
                    ply:SetLayerDuration(i, 0.001)
                    break
                end
            end
        end
    end
end)
--------OBSERVER---------
for i, ply in ipairs( player.GetAll() ) do
    local id = observerTargetList:AddChoice(ply:Name())
    Misc.Observer.Plrs[id] = ply:Name()
end

gameevent.Listen( "player_disconnect" )
hook.Add( "player_disconnect", "observerUpdate", function( data )
	local name = data.name
	local id
    for i, v in ipairs(Misc.Observer.Plrs) do
        if name == v then
            id = i
            break
        end
    end
    if id then
        observerTargetList:RemoveChoice(id)
    end
end)

gameevent.Listen( "player_connect" )
hook.Add("player_connect", "AnnounceConnection", function( data )
	local id = observerTargetList:AddChoice(data.name)
    Misc.Observer.Plrs[id] = data.name
end)

hook.Add("InputMouseApply", "ObserverMouseControl", function(cmd, x, y, ang)
    if not Misc.Observer.Enabled then return end
    
    Misc.Observer.CameraAngle.p = math.Clamp(Misc.Observer.CameraAngle.p + y * Misc.Observer.MouseSensitivity * 0.02, -89, 89)
    Misc.Observer.CameraAngle.y = Misc.Observer.CameraAngle.y - x * Misc.Observer.MouseSensitivity * 0.02
    Misc.Observer.CameraAngle.r = 0
    
    return true
end)

hook.Add("PlayerBindPress", "ObserverZoomControl", function(_, bind)
    if not Misc.Observer.Enabled or Misc.Observer.Mode ~= 1 then return end
    
    if bind == "invnext" then
        Misc.Observer.Distance = math.Clamp(Misc.Observer.Distance - 10, 50, 500)
        return true
    elseif bind == "invprev" then
        Misc.Observer.Distance = math.Clamp(Misc.Observer.Distance + 10, 50, 500)
        return true
    end
end)
--[[]]
hook.Add("CreateMove", "ObserverBlockMovement", function(cmd)
    if Misc.Observer.Enabled then 
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        cmd:SetUpMove(0)
        cmd:SetButtons(0)
        
        cmd:SetViewAngles(Misc.Observer.CameraAngle)
        
        return true
    end
end)
--]]------------------------------
hook.Add("CalcViewModelView", "MiscViewmodelOffset", function(wep, vm, oldPos, oldAng, pos, ang)
    if not Misc.Viewmodel then return end
    local offset = Vector(
        Misc.Viewmodel.X - 50,
        Misc.Viewmodel.Y - 50,
        Misc.Viewmodel.Z - 50
    )
    pos = pos + ang:Forward() * offset.x + ang:Right() * offset.y + ang:Up() * offset.z
    return pos, ang - Aimbot.Angle
end)
---------------HvH---------------
local lagTicks = 0
local lastMoving = false
local predPos = {Vector(), Vector()}
local realPos = {Vector(), Vector()}
DEBUG_SUB:Connect("PostDrawTranslucentRenderables", "DrawRedBeamFromBotView", function()
    render.SetMaterial(Material("cable/redlaser"))
    render.DrawBeam(realPos[1], realPos[2], 5, 0, 1, Color(255, 0, 0))
    render.SetMaterial(Material("cable/blue_elec"))
    render.DrawBeam(predPos[1], predPos[2], 5, 0, 1, Color(0, 255, 0))
end)

hook.Add("CreateMove", "HvH", function(cmd)
    local ply = LocalPlayer()
    if not HvH.OverLOP and lagTicks > 0 then
        ded.SetBSendPacket(false)
        lagTicks = lagTicks - 1
        if lagTicks == 0 then ded.SetBSendPacket(true) end
        return
    end
    if HvH.LagOnPeek and IsValid(ply) and ply:Alive() and IsValid(Aimbot.Target) then 
        local vel = ply:GetVelocity()
        local isMoving = vel:Length2D() > 10

        if lagTicks > 0 and HvH.OverLOP then
            --if cmd:KeyDown(IN_ATTACK) then
                --ded.SetOutSequenceNr(ded.GetOutSequenceNr() + lagTicks/12)
            --end
            ded.SetBSendPacket(false)
            lagTicks = lagTicks - 1
            if lagTicks == 0 then ded.SetBSendPacket(true) end
            return
        end

        if isMoving then
            local shootPos = ply:GetShootPos()
            local targetPos = Aimbot.Target:EyePos()

            local tr = util.TraceLine({
                start = shootPos,
                endpos = targetPos,
                filter = {ply}
            })

            local predTime = 0.05
            local predictedShootPos = shootPos + vel * predTime

            local tr_pred = util.TraceLine({
                start = predictedShootPos,
                endpos = targetPos,
                filter = function(ent)
                    return ent ~= ply
                end
            })
            if DEBUG then
                realPos[1] = targetPos
                realPos[2] = targetPos + Aimbot.Target:EyeAngles():Forward() * predictedShootPos:Distance(targetPos)
                predPos[1] = predictedShootPos
                predPos[2] = targetPos
            end
            if tr.Entity ~= Aimbot.Target and tr_pred.Entity == Aimbot.Target then
                lagTicks = HvH.LagFactor
                ded.SetBSendPacket(false)
            else
                ded.SetBSendPacket(true)
            end
        else
            ded.SetBSendPacket(true)
        end
    end
end)

local resetAngle = false
hook.Add("CreateMove", "HvH_AA", function(cmd)
    local ply = LocalPlayer()
    if HvH.AntiAim.Enabled and IsValid(ply) and ply:Alive() and 
    not (cmd:KeyDown(IN_ATTACK) 
    or cmd:KeyDown(IN_USE) 
    or ply:GetMoveType() == MOVETYPE_NOCLIP 
    or ply:GetMoveType() == MOVETYPE_LADDER) then
        if resetAngle and Aimbot.Angle ~= Angle(0,0,0) then
            return
        end
        resetAngle = false
        
        local diffAngle = Angle(0,0,0)
        local aaAng = cmd:GetViewAngles()
        local realAng = HvH.AntiAim.RealAngles
        local fakeAng = cmd:GetViewAngles()
        local yDiff = math.AngleDifference(realAng.y, fakeAng.y)
        local pDiff = fakeAng.p-realAng.p

        if HvH.AntiAim.Yaw == "Backward" then
            aaAng.y = fakeAng.y + 179-math.abs(yDiff)
            diffAngle.y = aaAng.y - fakeAng.y
        end
        if HvH.AntiAim.Yaw == "Sideways" then
            local ply = LocalPlayer()
            local pos = ply:GetPos() + Vector(0, 0, 64)
            local ang = realAng
            ang.p = 0
            ang.r = 0
            local maxDist = 2000

            local left_dir = (ang + Angle(0, 45, 0)):Forward()
            local right_dir = (ang + Angle(0, -45, 0)):Forward()

            local trace_left = util.TraceLine({
                start = pos,
                endpos = pos + left_dir * maxDist,
                filter = ply
            })
            local trace_right = util.TraceLine({
                start = pos,
                endpos = pos + right_dir * maxDist,
                filter = ply
            })

            -- шобы строго сбоку стены не детектило
            local function isWallInSector(trace, dir, ang, maxAngle)
                if not trace.Hit then return false end
                local toWall = (trace.HitPos - pos):GetNormalized()
                local forward = ang:Forward()
                local dot = forward:Dot(toWall)
                local angle = math.deg(math.acos(dot))
                return angle <= maxAngle
            end

            local maxSector = 75
            local leftValid = isWallInSector(trace_left, left_dir, ang, maxSector)
            local rightValid = isWallInSector(trace_right, right_dir, ang, maxSector)

            local leftDist = leftValid and trace_left.Fraction * maxDist or math.huge
            local rightDist = rightValid and trace_right.Fraction * maxDist or math.huge

            if leftDist < rightDist then--слева
                aaAng.y = fakeAng.y + 90-math.abs(yDiff)
                diffAngle.y = aaAng.y - fakeAng.y
            elseif rightDist < leftDist then--справа
                aaAng.y = fakeAng.y + math.abs(yDiff)-90
                diffAngle.y = aaAng.y - fakeAng.y
            else--huy
                aaAng.y = fakeAng.y + math.abs(yDiff)-90
                diffAngle.y = aaAng.y - fakeAng.y
            end
        end
        if HvH.AntiAim.Yaw == "Left" then
            aaAng.y = fakeAng.y + 90-math.abs(yDiff)
            diffAngle.y = aaAng.y - fakeAng.y
        end
        if HvH.AntiAim.Yaw == "Right" then
            aaAng.y = fakeAng.y + math.abs(yDiff)-90
            diffAngle.y = aaAng.y - fakeAng.y
        end
        if HvH.AntiAim.Yaw == "Forward" then
            aaAng.y = fakeAng.y
            diffAngle.y = aaAng.y - fakeAng.y
        end
        --Pitch
        if HvH.AntiAim.Pitch == "Down" then
            aaAng.p = 87
            diffAngle.p = math.AngleDifference(aaAng.p, fakeAng.p)
        end
        if HvH.AntiAim.Pitch == "Up" then
            aaAng.p = -87
            diffAngle.p = math.AngleDifference(aaAng.p, fakeAng.p)
        end
        if HvH.AntiAim.Pitch == "Forward" then
            aaAng.p = 0
            diffAngle.p = math.AngleDifference(aaAng.p, fakeAng.p)
        end
        if HvH.AntiAim.Pitch == "Viewangles" then
            aaAng.p = fakeAng.p
            diffAngle.p = math.AngleDifference(aaAng.p, fakeAng.p)
        end
        ----
        aaAng.r = 0
        diffAngle.r = 0
        Aimbot.Angle = Aimbot.Angle + diffAngle
        cmd:SetViewAngles(aaAng)
    elseif not resetAngle then
        resetAngle = true
        local ang = cmd:GetViewAngles()
        cmd:SetViewAngles(ang - Aimbot.Angle)
        Aimbot.Angle = Angle(0,0,0)
    end
end)
