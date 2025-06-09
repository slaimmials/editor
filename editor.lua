require( "rocx" ) 

surface.CreateFont( "font-02", {
	font = "Arial",
	extended = true,
	size = 15,
	weight = 500,
	antialias = true,
    shadow = true,
})
surface.CreateFont( "font-03", {
	font = "Arial",
	extended = true,
	size = 13,
	weight = 2000,
	antialias = true,
    outline = false,
})
surface.CreateFont( "font-0.3", {
	font = "Arial",
	extended = true,
	size = 14,
	weight = 1000,
	antialias = true,
	shadow = true,
    --outline = true,
})
surface.CreateFont( "font-0.4", {
	font = "Arial",
	extended = true,
	size = 15,
	weight = 1000,
	antialias = true,
    outline = true,
})
surface.CreateFont( "font-04", {
    size = 15,
    weight = 500,
    antialias = true,
    outline = true,
    font = "Arial",
})
surface.CreateFont( "font-05", {
	font = "Arial",
	extended = true,
	size = 20,
	weight = 800,
	antialias = true,
    shadow = true,
})
surface.CreateFont( "font-06", {
    font = "Verdana",
    size = 15,
    antialias = true
})


local PANEL = {}

PANEL.URL = "https://slaimmials.github.io/editor/editor_Web"
PANEL.COMPILE = "C"

local javascript_escape_replacements =
{
	["\\"] = "\\\\",
	["\0"] = "\\0" ,
	["\b"] = "\\b" ,
	["\t"] = "\\t" ,
	["\n"] = "\\n" ,
	["\v"] = "\\v" ,
	["\f"] = "\\f" ,
	["\r"] = "\\r" ,
	["\""] = "\\\"",
	["\'"] = "\\\'",
}

function PANEL:Init()
	self.Code = ""
    self.Errors = {}
	self.ErrorPanel = self:Add("DButton")
	self.ErrorPanel:SetFont('font-03')
	self.ErrorPanel:SetTextColor(Color(255,255,255))
	self.ErrorPanel:SetText("")
	self.ErrorPanel:SetTall(0)
	self.ErrorPanel.DoClick = function()
		self:GotoErrorLine()
	end
	self.ErrorPanel.DoRightClick = function(self)
		SetClipboardText(self:GetText())
	end
	self.ErrorPanel.Paint = function(self,w,h)
		surface.SetDrawColor(255,50,50)
		surface.DrawRect(0,0,w,h)
	end

	self:StartHTML()
end

function PANEL:Think()
	if self.NextValidate and self.NextValidate < CurTime() then
		self:ValidateCode()
	end
end

function PANEL:StartHTML()
	self.HTML = self:Add("DHTML")

	self:AddJavascriptCallback("OnCode")
	self:AddJavascriptCallback("OnLog")
    self:AddJavascriptCallback("GetErrs")

	self.HTML:OpenURL(self.URL)
	
	self.HTML:RequestFocus()
end

function PANEL:ReloadHTML()
	self.HTML:OpenURL(self.URL)
end

function PANEL:JavascriptSafe(str)
	str = str:gsub(".",javascript_escape_replacements)
	str = str:gsub("\226\128\168","\\\226\128\168")
	str = str:gsub("\226\128\169","\\\226\128\169")
	return str
end

function PANEL:CallJS(JS)
	self.HTML:Call(JS)
end

function PANEL:AddJavascriptCallback(name)
	local func = self[name]

	self.HTML:AddFunction("gmodinterface",name,function(...)
		func(self,HTML,...)
	end)
end

function PANEL:OnCode(_,code)
	self.NextValidate = CurTime() + 0.2
	self.Code = code
end

function PANEL:OnLog(_,...)
	Msg("Editor: ")
	print(...)
end

function PANEL:SetCode(code)
	self.Code = code
	self:CallJS('SetContent("' .. self:JavascriptSafe(code) .. '");')
end
B_STR12 = [[
]]
function PANEL:GetCode()
	local ret = self.Code
	ret=B_STR12..ret
    return ret
end

function PANEL:SetGutterError(errline,errstr)
	self:CallJS("SetErr('" .. errline .. "','" .. self:JavascriptSafe(errstr) .. "')")
end

function PANEL:GotoLine(num, column)
	self:CallJS("GotoLine('" .. num .. "', '" .. column .. "')")
end

function PANEL:ClearGutter()
	self:CallJS("ClearErr()")
end

function PANEL:GotoErrorLine()
	self:GotoLine(self.ErrorLine or 1)
end

function PANEL:SetError(err)
	if !IsValid(self.HTML) then
		self.ErrorPanel:SetText("")
		self:ClearGutter()
		return
	end

	local tall = 0 

	if err then
		local line,err = string.match(err,self.COMPILE .. ":(%d*):(.+)")

		if line and err then
			tall = 20

			self.ErrorPanel:SetText((line and err) and ("Line " .. line .. ": " .. err) or err or "")
			self.ErrorLine = tonumber(string.match(err," at line (%d)%)") or line) or 1
			self:SetGutterError(self.ErrorLine,err)
		end
	else
		self.ErrorPanel:SetText("")
		self:ClearGutter()
	end

	local wide = self:GetWide()
	local tallm = self:GetTall()

	self.ErrorPanel:SetPos(0,tallm - tall)
	self.ErrorPanel:SetSize(wide,tall)
	self.HTML:SetSize(wide,tallm - tall)
end

function PANEL:GetErrs(_,errs)
    if errs then
		local annotations = util.JSONToTable(errs)
        self.Errors = annotations
    else
        self:CallJS("GetErrs()")
    end
end

function PANEL:ValidateCode()--gavno
end

function PANEL:PerformLayout(w,h)--gavno
end

vgui.Register( "CodeEditor", PANEL, "EditablePanel" )

-----------NOTIFICATIONS--------------
local notifications = {}

surface.CreateFont("NotifyFont", {
    font = "Roboto",
    size = 22,
    weight = 500,
    antialias = true
})

function Notify(text, color, duration)
    table.insert(notifications, {
        text = text,
        color = color or Color(240, 240, 240),
        duration = duration or 5,
        startTime = CurTime(),
        yOffset = 0,
        alpha = 0
    })
end

hook.Add("DrawOverlay", "DrawNotifications", function()
    local currentTime = CurTime()
    local screenWidth = ScrW()
    local startY = 40
    local spacing = 5
    
    for i = #notifications, 1, -1 do
        local notif = notifications[i]
        local elapsed = currentTime - notif.startTime
        local lifePercent = elapsed / notif.duration
        if lifePercent > 1 then
            table.remove(notifications, i)
            continue
        end
        notif.alpha = math.Clamp(notif.alpha + (FrameTime() * 8), 0, 1)
        local animAlpha = 255 * notif.alpha
        notif.yOffset = Lerp(FrameTime() * 10, notif.yOffset, (i - 1) * 30)
        
        local width = 300
        local height = 30
		local x = 20 + width
        local y = ScrH() - height - 20 - notif.yOffset
        surface.SetDrawColor(30, 30, 40, animAlpha * 0.9)
        surface.DrawRect(x - width, y, width, height)
        surface.SetDrawColor(notif.color.r, notif.color.g, notif.color.b, animAlpha)
        surface.DrawRect(x - width, y, 4, height)
        draw.SimpleText(
            notif.text,
            "NotifyFont",
            x - width + 10,
            y + 4,
            Color(255, 255, 255, animAlpha),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_BOTTOM
        )
    end
end)

---------------------------------------------


local surface = surface 

local surface_SetDrawColor 		= surface.SetDrawColor
local surface_DrawRect 			= surface.DrawRect
local surface_DrawOutlinedRect 	= surface.DrawOutlinedRect

--                  1                2               3                  4               5                 6                 7                  8                 9               10                  11                12                 13                14                    15               16                 17              18               19
local pal = { { 40, 40, 40 }, { 60, 56, 54 }, { 146, 131, 116 }, { 204, 36, 29 }, { 251, 73, 52 }, { 152, 151, 26 }, { 184, 187, 38 }, { 215, 153, 33 }, { 250, 189, 47 }, { 69, 133, 136 }, { 131, 165, 152 }, { 177, 98, 134 }, { 211, 134, 155 }, { 104, 157, 106 }, { 142, 192, 124 }, { 168, 153, 132 }, { 235, 219, 178 }, { 0, 2, 34 }, { 255, 255, 255 },	 }

local function SetPalColor( i ) 
	local use = pal[ i ]
	surface_SetDrawColor( use[1], use[2], use[3] )
end

local FileName = "EDITOR REWRITE []"
local StartupSource = "gamemodes/rust"

local blockRunString = false

file.CreateDir( "slua" )
file.CreateDir( "slua/stolen" )
file.CreateDir( "slua/saved" )
file.CreateDir( "slua/auto-saved" )

local frame = vgui.Create( "DFrame" )
frame.configSize = 300
frame:SetTitle( "" )
frame:SetSize( 500+frame.configSize, 400 )
frame:Center()
frame:SetX(frame:GetX()+frame.configSize)
frame:MakePopup()
frame:ShowCloseButton( false )

function frame:Paint( w, h )
	w=w-frame.configSize
    SetPalColor( 1 ) 
    surface_DrawRect( 0, 0, w, h )

    SetPalColor( 2 ) 
    surface_DrawOutlinedRect( 0, 0, w, h )
    surface_DrawRect( 0, 0, w, 24 )
    surface_DrawRect( 128, 0, 1, h )

    local hue = 60
    local saturation = 1 
    local value = 1
    local color = HSVToColor(hue, saturation, value)
    surface.SetTextColor(color.r, color.g, color.b) 
    surface.SetFont("font-03")
    surface.SetTextPos(8, 4)
    surface.DrawText(FileName)
end

local ePan = frame:Add( "CodeEditor" )
ePan:SetPos( 129, 24 )
ePan:SetSize( 500-129, 399 )
ePan:Init()
local fPan

local function UpdateFiles()
	if fPan then
		fPan:Remove()
		fPan = false 
	end

	fPan = frame:Add( "DPanel" )
	fPan:SetPos( 4, 28 )
	fPan:SetSize( 120, 399 )
	fPan.Paint = nil
	
	local files, dirs = file.Find( "slua/saved/*", "DATA" )
	
	for key, val in pairs( files ) do
		if val == "desktop.ini" then continue end
		local hButton = fPan:Add( "DButton" )
		hButton:Dock( TOP )
		hButton:SetText( val )
		hButton:SetFont( string.len( val ) > 16 and "font-03" or "font-04" )
		hButton:SetTextColor( Color( 235, 219, 178 ) )
		hButton:SizeToContents()
		hButton:SetHeight( 20 )
		hButton:DockMargin( 2, 0, 0, 0 )
	
		function hButton:Paint( w, h )
			SetPalColor( 15 ) 
			surface_DrawRect( 0, 19, w, 1 )
		end
	
		function hButton:DoClick()
			ePan:SetCode( file.Read( "slua/saved/" .. val, "DATA" ) )
			--FileName = val
		end
	
		function hButton:DoRightClick()
			if not IsInGame() then Notify("You are not in game", Color(153,0,0), 2) return end 
			--RunOnClient( file.Read( "slua/saved/" .. val, "DATA" ) )
			--Notify("Executed", Color(0,150,0), 10)
		end
	end
end

local configPanel = frame:Add( "DPanel" )
configPanel.Opened = false
configPanel:Hide()
configPanel:SetPos( 508, 0 )
configPanel:SetSize( frame.configSize-8, 400 )
function configPanel:Paint(w,h)
	surface.SetDrawColor(Color(60, 56, 54))
	surface.DrawRect(0,0,w,h)
end

local label = configPanel:Add("DLabel")
label:SetPos(12, 16)
label:SetText("StartupSource:")
label:SizeToContents()

local textEntry = configPanel:Add("DTextEntry")
textEntry:SetPos(90, 15)
textEntry:SetSize(frame.configSize-textEntry:GetX()-10, 18)
textEntry:SetFont("Default")
textEntry:SetTextColor(Color(255,255,255))
textEntry:SetText(StartupSource)
function textEntry:OnChange()
    StartupSource = self:GetValue() or ""
end
function textEntry:Paint(w,h)
	draw.DrawText(self:GetText(), "Default", 0, 2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local ErrorPanel = frame:Add("DButton")
ErrorPanel:SetTextColor(Color(255,255,255))
ErrorPanel:SetFont("DefaultFixedDropShadow")
ErrorPanel:SetSize(500-129, 0)
ErrorPanel:SetPos(129, 24+399)
ErrorPanel.DoClick = function()
	ePan:GotoErrorLine()
end
ErrorPanel.Paint = function(self,w,h)
	surface.SetDrawColor(255,50,50)
	surface.DrawRect(0,0,w,h)
end

UpdateFiles()

local CSTYLEPATCH = [[
local real_getinfo = debug.getinfo
print("[EDTIOR] OLD debug.getinfo: "..tostring(debug.getinfo))
debug.getinfo = function(func, ...)
	local info = real_getinfo(func, ...)
	local pt = ""
	local C = "=[C]"
	if func == render.Capture then info.source = C pt=C info.what = "C" end
	if func == jit.attach then info.source = C pt=C info.what = "C" end
	if func == util.TraceLine then info.source = C pt=C info.what = "C" end
	if func == net.SendToServer then info.source = C pt=C info.what = "C" end
	if func == net.Start then info.source = C pt=C info.what = "C" end

	if func == net.Receive then info.source = "@lua/includes/extensions/net.lua" pt=info.source info.what = "Lua" end
	if func == hook.Add then info.source = "@lua/includes/modules/hook.lua" pt=info.source info.what = "Lua" end
	print("[EDITOR] PATCHED ("..tostring(func)..")")
	return info
end
print("[EDTIOR] NEW debug.getinfo: "..tostring(debug.getinfo))
]]

local options = {
	[ "Execute" ] = { 
		function( self ) 
			if not IsInGame() then 
				return 
			end
			RunOnClient( ePan:GetCode()..CSTYLEPATCH, StartupSource) 
			surface.PlaySound("ambient/water/drip1.wav") 
		end, 
		Color( 0, 200, 0), 
		Color( 0, 100, 0),

	},
	[ "Config" ] = { 
		function( self ) 
			configPanel.Opened = not configPanel.Opened
			if configPanel.Opened then
				configPanel:Show()
			else
				configPanel:Hide()
			end
			surface.PlaySound("common/talk.wav") 
		end, 
		Color( 200, 200, 200), 
		Color( 100, 100, 100),
	},
}

local bPan = frame:Add( "DPanel" )
bPan:SetPos( 500-153, 2 )
bPan:SetSize( 150, 20 )
bPan.Paint = nil

for key, val in pairs( options ) do
	local data = options[ key ] 
	local hButton = bPan:Add( "DButton" )
	hButton:Dock( RIGHT )
	hButton:SetText( key )
	hButton:SetFont( "font-03" )
	hButton:SetTextColor( data[ 2 ] )
	hButton:SizeToContents()
	hButton:SetHeight( 10 )
	hButton:DockMargin( 2, 0, 0, 0 )

	function hButton:Paint( w, h )
		surface_SetDrawColor(data[3])
		surface_DrawRect( 0, 0, w, h )
	end

	hButton.DoClick = data[ 1 ]
	data["getButton"] = function()
		return hButton
	end
	options[ key ] = data
end

local hk = {}

function hk.GameContentChanged()
    frame:MakePopup()
end

local key, keyPressed = KEY_HOME, false
function hk.Think()
    if input.IsKeyDown( key ) and not keyPressed then
        frame:ToggleVisible()
    end

    keyPressed = input.IsKeyDown( key )
end

for key, val in pairs( hk ) do
    hook.Add( key, "H:" .. key, val )
end

timer.Create("ErrorHandler", 0.1, 0, function()
    ePan:GetErrs()
    if ePan.Errors then
        local tall = #ePan.Errors > 0 and 10 or 0

        if type(ePan.Errors) == "table" and #ePan.Errors > 0 then
            for _,err in pairs(ePan.Errors) do
                local line = err.row
                local column = err.column

				ErrorPanel.DoClick = function()
					ePan:GotoLine(line+1, column)
				end

                ErrorPanel:SetText(err.text)
                ePan:SetGutterError(tonumber(line), err.text)
            end
        else
            ErrorPanel:SetText("")
            ePan:ClearGutter()
        end

        local wide = ePan:GetWide()
		local tallm = ePan:GetTall()

		ErrorPanel:SetPos(129,tallm - tall)
		ErrorPanel:SetSize(wide,tall)
		ePan.HTML:SetSize(wide,tallm - tall)
    end
end)

hook.Add("Think", "Update", function()
	FileName = "EDITOR REWRITE ["..engine.ActiveGamemode().."]"
	local execBut = options["Execute"].getButton()
	execBut:SetVisible(IsInGame())
end)

print("ENTIRE V3 REWRITE BY 0xDEAD")
Notify("Successfully loaded executor", Color(0,150,0), 10)
