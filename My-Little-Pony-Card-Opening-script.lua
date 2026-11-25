--[[ Made by Stizzyyy · https://rscripts.net/@Stizzyyy
     My scripts are ALWAYS free and keyless.
     If you find my features or code behind a key system, it's a stolen re-upload, not mine. ]]
--[[ Pony Cards Hub · My Little Pony Card Opening · built for Solara (no hooks)
     RightShift (PC) or the floating "Pony" button (mobile) = show/hide menu
     Pony Pairs solver, auto postcards, auto open / buy / sell, golden pack sniper, smart pack picker,
     auto claim (notes, calendar, collection), collection tracker, pull log, trade value checker,
     stats overlay, anti-AFK, full auto loop. ]]

--[[ CHANGELOG
  24 Nov 2026 · game update (Card Market, 4 new packs)
    FIXED   your cards now arrive in a new packed format; auto sell, collection, smart pick and trade checker read them again
    FIXED   selling sends the new "keep copies" setting
    FIXED   the game's own coin counter, binder and pack piles now update live
    NEW     Fantasy Wonderland, Nightmare Night, Moon 12, Moon 13 and Star I in Picked sets
    NEW     "Auto rejoin when flagged": joins a new server when the game stops paying
    CHANGED Pony Pairs and postcards are off by default and left out of Full auto; turn them on yourself.
            Pony Pairs plays at a human pace; postcards send a good (not perfect) score about every 45 s
    BROKEN  Pony Pairs and postcard coins: the game added an anti-cheat that stops paying an account
            that farms too fast. It sticks to the account (also hits normal players), a new server gives
            about one paid round. Not fixable from a script; wait for it to wear off or for a game fix.
    WORKS   opening, buying, golden sniper, selling, notes, calendar, collection rewards, trade checker
  22 Nov 2026 · first release
    Pony Pairs solver (~75 coins a board), perfect postcards (~47 each), auto open / buy / sell,
    golden pack sniper, smart pack picker, auto claim, collection tracker, pull log, trade checker ]]

if game.GameId ~= 10775160561 then return end -- My Little Pony Card Opening only
if not game:IsLoaded() then game.Loaded:Wait() end
local G = getgenv()
if G.MLPH and G.MLPH.Unload then pcall(G.MLPH.Unload) end
local H = {conns = {}, draws = {}, insts = {}, alive = true}
G.MLPH = H

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
while not Players.LocalPlayer do task.wait() end
local LP = Players.LocalPlayer
local HUI = (gethui and gethui()) or game:GetService("CoreGui")

local function conn(sig, f) local c = sig:Connect(f) H.conns[#H.conns + 1] = c return c end
local function inst(cls, p, parent) local i = Instance.new(cls) for k, v in pairs(p or {}) do i[k] = v end if parent then i.Parent = parent end return i end

----------------------------------------------------------------- settings (auto-saved)
local S = {
	Full = false,
	Pairs = false, Post = false, PostGap = 40,
	AutoNotes = true, AutoDaily = true, AutoCollect = true,
	AutoOpen = false, OpenGolden = true, AutoSell = false, Keep = 2, SellMax = "SSR",
	AutoBuy = false, BuySet = "Smart", Reserve = 300, Sniper = true,
	LogMin = "LSR", NotifyMin = "UR",
	TradeCheck = true, Overlay = true, AntiAFK = true, Notify = true, ReloadOnRejoin = true, AutoRejoin = true, Off1124 = false,
}
local CFG = "PonyCardsHub.json"
pcall(function() local t = Http:JSONDecode(readfile(CFG)) for k, v in pairs(t) do if (S[k] ~= nil and type(v) == type(S[k])) or (k:match("^Buy_") and type(v) == "boolean") then S[k] = v end end end)
H.S = S
local function save() pcall(function() writefile(CFG, Http:JSONEncode(S)) end) end
-- 24 Nov 2026: the game's anti-cheat stopped paying Pairs / postcards, so switch them off once for everyone
if not S.Off1124 then S.Pairs, S.Post, S.Off1124 = false, false, true save() end
----------------------------------------------------------------- UI library (glass) · themes are shared by every Stizzyyy hub
-- dark glassmorphism window + soft glass cards + liquid glass pills
-- C keeps the same keys the hubs already use (clay = primary accent); C.accent2 = secondary accent
local C = {}
local PRESETS = {
	{name = "Claude Glass",   bg = "141311", side = "1E1C1A", card = "2A2724", stroke = "4A453F", text = "F2EEE6", muted = "9A948A", primary = "D97757", secondary = "F2B880"},
	{name = "ChatGPT / Codex", bg = "0D0D0D", side = "171717", card = "212121", stroke = "3A3A3A", text = "ECECEC", muted = "8E8EA0", primary = "10A37F", secondary = "74AA9C"},
	{name = "Solara",         bg = "0E0B16", side = "161224", card = "201A33", stroke = "3B3157", text = "F1EEFA", muted = "A39BBF", primary = "9D5CFF", secondary = "5B8CFF"},
	{name = "Discord",        bg = "1E1F22", side = "2B2D31", card = "313338", stroke = "45474E", text = "F2F3F5", muted = "B5BAC1", primary = "5865F2", secondary = "EB459E"},
	{name = "Netflix",        bg = "0B0B0B", side = "141414", card = "1F1F1F", stroke = "363636", text = "FFFFFF", muted = "B3B3B3", primary = "E50914", secondary = "B81D24"},
	{name = "Grok",           bg = "000000", side = "0A0A0A", card = "151515", stroke = "2F2F2F", text = "FFFFFF", muted = "8B8B8B", primary = "E7E9EA", secondary = "6E6E6E"},
}
local THEME_FILE = "StizzyyyUI.json"
local TH = {preset = "Claude Glass", glass = 20}
pcall(function() local t = Http:JSONDecode(readfile(THEME_FILE)) for k, v in pairs(t) do TH[k] = v end end)
TH.glass = math.clamp(tonumber(TH.glass) or 20, 20, 45) -- below 20% the glass loses its depth
local function presetOf(n) for _, p in ipairs(PRESETS) do if p.name == n then return p end end return PRESETS[1] end
local function hex(h) local ok, c = pcall(Color3.fromHex, tostring(h or "")) return ok and c or nil end
local function loadTheme()
	local p = presetOf(TH.preset)
	for _, k in ipairs({"bg", "side", "card", "stroke", "text", "muted"}) do C[k] = hex(p[k]) end
	C.clay = hex(TH.primary) or hex(p.primary)
	C.accent2 = hex(TH.secondary) or hex(p.secondary)
	C.primary, C.secondary = C.clay, C.accent2
end
loadTheme()
local WHITE = Color3.new(1, 1, 1)
local function face(w) return Font.new("rbxasset://fonts/families/Montserrat.json", w or Enum.FontWeight.Regular) end
local MED, SEMI, BOLD = Enum.FontWeight.Medium, Enum.FontWeight.SemiBold, Enum.FontWeight.Bold

-- every themed property is registered, so switching theme recolours the whole menu live
local themed, painters = {}, {}
local function th(i, prop, role) themed[#themed + 1] = {i, prop, role} i[prop] = C[role] return i end
local function painter(f) painters[#painters + 1] = f f() return f end
local grads = {}
local function accentGrad(parent, rot)
	local g = inst("UIGradient", {Rotation = rot or 0, Color = ColorSequence.new(C.clay, C.accent2)}, parent)
	grads[#grads + 1] = g
	return g
end
local glassParts = {} -- {instance, extra transparency}
local function glassy(i, extra) glassParts[#glassParts + 1] = {i, extra or 0} i.BackgroundTransparency = math.clamp(TH.glass / 100 + (extra or 0), 0, 0.95) return i end

local Gui = inst("ScreenGui", {Name = "MLPH" .. math.random(1e5, 1e6), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50}, HUI)
H.insts[#H.insts + 1] = Gui
local function corner(p, r) inst("UICorner", {CornerRadius = r == "pill" and UDim.new(1, 0) or UDim.new(0, r or 8)}, p) end
local function stroke(p, c)
	local s = inst("UIStroke", {Color = c or C.stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.25}, p)
	if not c then themed[#themed + 1] = {s, "Color", "stroke"} end
	return s
end
-- dark glass edge: one thin, even, light outline
local function rim(p, t)
	return inst("UIStroke", {Color = WHITE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = t or 0.8}, p)
end
-- liquid glass: clear pill, light gathering at both rounded ends, and a crisp highlight line along the inside top edge
local function liquid(p, strong)
	p.BackgroundColor3 = WHITE
	glassy(p, strong and 0.74 or 0.82)
	local s = inst("UIStroke", {Color = WHITE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0}, p)
	inst("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.2, 0.72), NumberSequenceKeypoint.new(0.5, 0.86),
		NumberSequenceKeypoint.new(0.8, 0.72), NumberSequenceKeypoint.new(1, 0.3)})}, s)
	-- a soft vertical sheen: the top of the glass catches more light than the bottom
	local sheen = inst("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.45)})}, p)
	local shine = inst("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 1), Size = UDim2.new(1, -18, 0, 1), BackgroundTransparency = 0.45, ZIndex = p.ZIndex}, p)
	inst("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.3), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1)})}, shine)
	return s, shine, sheen
end
-- motion helpers
local function tween(i, t, props, style, dir) local tw = TS:Create(i, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props) tw:Play() return tw end
local function pressable(b)
	local sc = inst("UIScale", {}, b)
	b.MouseButton1Down:Connect(function() tween(sc, 0.08, {Scale = 0.96}) end)
	b.MouseButton1Up:Connect(function() tween(sc, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end)
	b.MouseLeave:Connect(function() tween(sc, 0.2, {Scale = 1}) end)
end
-- thin line that fades out at both ends (the dividers in the dark glass panel)
local function divider(parent, pos, size, vertical)
	local d = inst("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = pos, Size = size, BackgroundTransparency = 0.55}, parent)
	inst("UIGradient", {Rotation = vertical and 90 or 0, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1)})}, d)
	return d
end
local function dragify(handle, frame)
	local drag, start, pos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag, start, pos = true, i.Position, frame.Position end
	end)
	conn(UIS.InputChanged, function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y)
		end
	end)
	conn(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

----------------------------------------------------------------- window (dark glassmorphism)
local Win = inst("Frame", {Size = UDim2.fromOffset(620, 430), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, Active = true, BackgroundColor3 = WHITE}, Gui)
glassy(Win)
corner(Win, 12) rim(Win, 0.72)
-- smoked glass: a lighter grey at the top fading to near black at the bottom
local winGrad = inst("UIGradient", {Rotation = 90}, Win)
painter(function() winGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.bg:Lerp(WHITE, 0.2)), ColorSequenceKeypoint.new(0.45, C.bg:Lerp(WHITE, 0.07)), ColorSequenceKeypoint.new(1, C.bg)}) end)
-- soft drop shadow so the panel floats (a sibling behind the window that follows it)
local Shadow = inst("ImageLabel", {Image = "rbxassetid://6015897843", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.78, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0}, Gui)
do
local function syncShadow()
	Shadow.Visible = Win.Visible
	Shadow.Position = UDim2.fromOffset(Win.AbsolutePosition.X - 22, Win.AbsolutePosition.Y - 14)
	Shadow.Size = UDim2.fromOffset(Win.AbsoluteSize.X + 44, Win.AbsoluteSize.Y + 44)
end
for _, p in ipairs({"AbsolutePosition", "AbsoluteSize", "Visible"}) do conn(Win:GetPropertyChangedSignal(p), syncShadow) end
task.defer(syncShadow)
end

local Top = inst("Frame", {Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1}, Win)
th(inst("TextLabel", {Text = "Pony Cards Hub", FontFace = face(BOLD), TextSize = 19, BackgroundTransparency = 1,
	Position = UDim2.fromOffset(20, 30), Size = UDim2.new(0, 360, 0, 26), TextXAlignment = Enum.TextXAlignment.Left}, Top), "TextColor3", "text")
th(inst("TextLabel", {Text = UIS.KeyboardEnabled and "RightShift to hide · F6 pauses" or "", FontFace = face(MED), TextSize = 11, BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 30), Size = UDim2.new(0, 240, 0, 26), TextXAlignment = Enum.TextXAlignment.Right}, Top), "TextColor3", "muted")
-- window state: body parts (hidden while minimised), sizes, mode, scale target
local WS = {parts = {}, sizes = {normal = Vector2.new(620, 430), big = Vector2.new(780, 540)}, mode = "normal", min = false, fit = 1, anim = false}
WS.parts[1] = divider(Win, UDim2.fromOffset(20, 66), UDim2.new(1, -40, 0, 1))
-- shrink to fit small windows
local fit = inst("UIScale", {}, Win)
local function refit()
	local v = workspace.CurrentCamera.ViewportSize
	local sz = WS.sizes[WS.mode]
	WS.fit = math.clamp(math.min((v.Y - 80) / sz.Y, (v.X - 20) / sz.X), 0.45, 1)
	if not WS.anim then fit.Scale = WS.fit end
end
refit() conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), refit)
dragify(Top, Win)
-- window buttons, like a Mac window: red hides the menu, yellow folds it down to the title bar, green makes it bigger
do
	-- short legend for the three buttons, on the same row as them
	th(inst("TextLabel", {RichText = true, FontFace = face(MED), TextSize = 11, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
		Text = '<font color="#FF5F57">●</font> hide   <font color="#FEBC2E">●</font> fold   <font color="#28C840">●</font> bigger',
		Position = UDim2.new(1, -20, 0, 8), Size = UDim2.new(0, 240, 0, 22), TextXAlignment = Enum.TextXAlignment.Right}, Top), "TextColor3", "muted")
	local dots, marks = {}, {}
	for i, col in ipairs({Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64)}) do
		local d = inst("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = col, BorderSizePixel = 0, Position = UDim2.fromOffset(16 + (i - 1) * 18, 14), Size = UDim2.fromOffset(12, 12)}, Top)
		corner(d, "pill")
		marks[i] = inst("TextLabel", {Text = ({"×", "–", "+"})[i], FontFace = face(BOLD), TextSize = 11, TextColor3 = Color3.new(0, 0, 0), TextTransparency = 1,
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, -1)}, d)
		pressable(d)
		dots[i] = d
	end
	-- the symbols show while the mouse is over the buttons
	local over = 0
	local function showMarks(on) for _, m in ipairs(marks) do tween(m, 0.15, {TextTransparency = on and 0.45 or 1}) end end
	for _, d in ipairs(dots) do
		d.MouseEnter:Connect(function() over += 1 showMarks(true) end)
		d.MouseLeave:Connect(function() over = math.max(0, over - 1) task.delay(0.05, function() if over == 0 then showMarks(false) end end) end)
	end
	local function setParts(on) for _, o in ipairs(WS.parts) do o.Visible = on end end
	-- resize around the top edge, so the title bar stays where it is
	local function resizeTo(size, keepTop)
		local old = Win.AbsoluteSize / math.max(fit.Scale, 0.01)
		local shift = keepTop and (size.Y - old.Y) / 2 * fit.Scale or 0
		tween(Win, 0.35, {Size = UDim2.fromOffset(size.X, size.Y), Position = Win.Position + UDim2.fromOffset(0, shift)})
	end
	dots[1].Activated:Connect(function() Win.Visible = false end)
	dots[2].Activated:Connect(function()
		WS.min = not WS.min
		local full = WS.sizes[WS.mode]
		if WS.min then
			setParts(false)
			resizeTo(Vector2.new(full.X, 64), true)
		else
			resizeTo(full, true)
			task.delay(0.22, function() if not WS.min then setParts(true) end end)
		end
	end)
	dots[3].Activated:Connect(function()
		WS.mode = WS.mode == "normal" and "big" or "normal"
		refit()
		if WS.min then WS.min = false task.delay(0.22, function() if not WS.min then setParts(true) end end) end
		resizeTo(WS.sizes[WS.mode], false)
		tween(fit, 0.35, {Scale = WS.fit})
	end)
end
-- open / close motion: the panel eases in from slightly smaller and lower, and eases out the same way
-- (hubs just set Win.Visible, so this watches that property)
do
local function openAnim()
	local pos = Win.Position
	WS.anim = true
	fit.Scale = WS.fit * 0.92
	Win.Position = pos + UDim2.fromOffset(0, 14)
	tween(fit, 0.32, {Scale = WS.fit}, Enum.EasingStyle.Back)
	tween(Win, 0.32, {Position = pos}).Completed:Connect(function() WS.anim = false end)
end
-- our own Visible changes are skipped (signals can arrive late, so count them instead of using a flag)
local ignoreVis = 0
local function setVis(v) if Win.Visible ~= v then ignoreVis += 1 Win.Visible = v end end
conn(Win:GetPropertyChangedSignal("Visible"), function()
	if ignoreVis > 0 then ignoreVis -= 1 return end
	if WS.anim then return end
	if Win.Visible then openAnim() return end
	WS.anim = true
	setVis(true)
	local pos = Win.Position
	tween(fit, 0.16, {Scale = WS.fit * 0.92}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(Win, 0.16, {Position = pos + UDim2.fromOffset(0, 14)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
		setVis(false)
		Win.Position, fit.Scale = pos, WS.fit
		WS.anim = false
	end)
end)
task.defer(openAnim)end


-- floating liquid glass button to bring the menu back on phones (no RightShift there)
-- phones/tablets only: a round glass button with a menu icon; tap = show/hide, drag = move it
local Tog = th(inst("TextButton", {Text = "≡", FontFace = face(SEMI), TextSize = 28, AutoButtonColor = false,
	Position = UDim2.new(0, 14, 0.5, -26), Size = UDim2.fromOffset(52, 52), Visible = UIS.TouchEnabled and not UIS.KeyboardEnabled}, Gui), "TextColor3", "text")
corner(Tog, "pill") liquid(Tog, true) pressable(Tog)
-- it glows in the theme colour while the menu is hidden, so it's easy to spot
local togGlow = inst("UIStroke", {Color = C.clay, Thickness = 2, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, Tog)
themed[#themed + 1] = {togGlow, "Color", "clay"}
conn(Win:GetPropertyChangedSignal("Visible"), function() tween(togGlow, 0.3, {Transparency = Win.Visible and 1 or 0.3}) end)
dragify(Tog, Tog)
local togAt
Tog.InputBegan:Connect(function() togAt = Tog.AbsolutePosition end)
Tog.Activated:Connect(function() if togAt and (Tog.AbsolutePosition - togAt).Magnitude > 6 then return end Win.Visible = not Win.Visible end)
H.Tog = Tog

-- sidebar: "MENU" list straight on the glass, active item marked by an accent bar on the window edge
-- it scrolls (clipped above the account card) once a hub has more tabs than fit
local Side = inst("ScrollingFrame", {Position = UDim2.fromOffset(0, 76), Size = UDim2.new(0, 164, 1, -150), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, Win)
th(Side, "ScrollBarImageColor3", "stroke")
inst("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, Side)
inst("UIPadding", {PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, Side)
th(inst("TextLabel", {Text = "MENU", FontFace = face(MED), TextSize = 11, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = -1,
	TextXAlignment = Enum.TextXAlignment.Left}, Side), "TextColor3", "muted").TextTransparency = 0.1
WS.parts[#WS.parts + 1] = Side
WS.parts[#WS.parts + 1] = divider(Win, UDim2.fromOffset(170, 80), UDim2.new(0, 1, 1, -96), true)
WS.parts[#WS.parts + 1] = divider(Win, UDim2.new(0, 20, 1, -70), UDim2.fromOffset(130, 1))
-- account card at the bottom, like the profile row in the glass sidebar
do
local Acc = inst("Frame", {Position = UDim2.new(0, 16, 1, -62), Size = UDim2.fromOffset(150, 48), BackgroundTransparency = 1}, Win)
WS.parts[#WS.parts + 1] = Acc
local av = inst("ImageLabel", {BackgroundColor3 = WHITE, BackgroundTransparency = 0.92, Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(0, 5),
	Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(game:GetService("Players").LocalPlayer.UserId) .. "&w=48&h=48"}, Acc)
corner(av, "pill") rim(av, 0.35)
th(inst("TextLabel", {Text = game:GetService("Players").LocalPlayer.DisplayName, FontFace = face(SEMI), TextSize = 13, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
	Position = UDim2.fromOffset(48, 7), Size = UDim2.new(1, -50, 0, 18), TextXAlignment = Enum.TextXAlignment.Left}, Acc), "TextColor3", "text")
th(inst("TextLabel", {Text = "@" .. game:GetService("Players").LocalPlayer.Name, FontFace = face(), TextSize = 10, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
	Position = UDim2.fromOffset(48, 25), Size = UDim2.new(1, -50, 0, 14), TextXAlignment = Enum.TextXAlignment.Left}, Acc), "TextColor3", "muted")
end
local Pages = inst("Frame", {Position = UDim2.fromOffset(184, 80), Size = UDim2.new(1, -198, 1, -94), BackgroundTransparency = 1}, Win)
WS.parts[#WS.parts + 1] = Pages

local UI = {refresh = {}, el = {}, repaint = {}}
local tabs = {}
local function paintTabs()
	for _, o in ipairs(tabs) do
		local on = o.page.Visible
		o.btn.TextColor3 = on and C.text or C.muted
		o.btn.FontFace = face(on and SEMI or MED)
		o.bar.Visible = on
		o.chev.Visible = on
	end
end
function UI.tab(name, order)
	local btn = inst("TextButton", {Text = name, FontFace = face(MED), TextSize = 13, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34),
		AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order or #tabs + 1}, Side)
	inst("UIPadding", {PaddingLeft = UDim.new(0, 8)}, btn)
	-- the accent bar sits on the window's left edge (inside the scroll area so it isn't clipped)
	local bar = inst("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -14, 0.5, 0), Size = UDim2.fromOffset(3, 22), Visible = false}, btn)
	accentGrad(bar, 90)
	local chev = th(inst("TextLabel", {Text = "›", FontFace = face(SEMI), TextSize = 18, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, -1),
		Size = UDim2.fromOffset(16, 20), Visible = false}, btn), "TextColor3", "text")
	local page = inst("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, Pages)
	th(page, "ScrollBarImageColor3", "stroke")
	inst("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
	-- a little room on every side so the cards' outlines are never clipped by the scroll area
	inst("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 9), PaddingBottom = UDim.new(0, 8), PaddingTop = UDim.new(0, 3)}, page)
	local t = setmetatable({page = page, btn = btn, bar = bar, chev = chev, n = 0}, {__index = UI.el})
	local function select()
		if page.Visible then return end
		for _, o in ipairs(tabs) do o.page.Visible = false end
		page.Visible = true
		paintTabs()
		-- the new page glides up into place and the accent bar grows in
		page.Position = UDim2.fromOffset(0, 12)
		tween(page, 0.35, {Position = UDim2.new()})
		bar.Size = UDim2.fromOffset(3, 0)
		tween(bar, 0.3, {Size = UDim2.fromOffset(3, 22)}, Enum.EasingStyle.Back)
		chev.Position = UDim2.new(1, -8, 0.5, -1)
		tween(chev, 0.3, {Position = UDim2.new(1, 0, 0.5, -1)})
	end
	btn.MouseButton1Click:Connect(select)
	btn.MouseEnter:Connect(function() if not page.Visible then tween(btn, 0.15, {TextColor3 = C.text}) end end)
	btn.MouseLeave:Connect(function() if not page.Visible then tween(btn, 0.2, {TextColor3 = C.muted}) end end)
	tabs[#tabs + 1] = t
	if #tabs == 1 then select() else paintTabs() end
	return t
end

----------------------------------------------------------------- content (soft glassmorphism cards)
-- rounded translucent card with a soft tonal gradient, tinted by the ambient theme colour on the left
local function card(f)
	f.BackgroundColor3 = WHITE
	glassy(f, 0.22)
	corner(f, 14)
	rim(f, 0.9)
	local g = inst("UIGradient", {Rotation = 0}, f)
	painter(function() g.Color = ColorSequence.new(C.card:Lerp(C.clay, 0.16), C.card) end)
	-- the card brightens a touch under the mouse
	f.MouseEnter:Connect(function() tween(f, 0.18, {BackgroundTransparency = math.clamp(TH.glass / 100 + 0.14, 0, 0.95)}) end)
	f.MouseLeave:Connect(function() tween(f, 0.25, {BackgroundTransparency = math.clamp(TH.glass / 100 + 0.22, 0, 0.95)}) end)
	return f
end
local function row(t, h)
	t.n += 1
	return card(inst("Frame", {Size = UDim2.new(1, 0, 0, h or 40), BorderSizePixel = 0, LayoutOrder = t.n}, t.page))
end
local function lbl(parent, text)
	return th(inst("TextLabel", {Text = text, FontFace = face(MED), TextSize = 13, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, parent), "TextColor3", "text")
end
function UI.el:section(text)
	self.n += 1
	local l = th(inst("TextLabel", {Text = string.upper(text), FontFace = face(MED), TextSize = 11, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = self.n}, self.page), "TextColor3", "muted")
	inst("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 8)}, l)
end
-- grey second line under a control's name; the card grows with the text
local function desc(f, l, text, rightPad)
	if not text then return end
	l.Position, l.Size = UDim2.fromOffset(16, 7), UDim2.new(1, -rightPad, 0, 18)
	th(inst("TextLabel", {Text = text, FontFace = face(), TextSize = 11, BackgroundTransparency = 1, TextWrapped = true,
		Position = UDim2.fromOffset(16, 26), Size = UDim2.new(1, -rightPad, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, f), "TextColor3", "muted")
	f.AutomaticSize = Enum.AutomaticSize.Y
	inst("UIPadding", {PaddingBottom = UDim.new(0, 10)}, f)
end
-- liquid glass switch; when on it fills with the accent and glows
function UI.el:toggle(text, key, cb, d)
	local f = row(self, d and 58) desc(f, lbl(f, text), d, 78)
	local sw = inst("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(42, 24), BorderSizePixel = 0}, f)
	if d then sw.AnchorPoint, sw.Position = Vector2.new(1, 0), UDim2.new(1, -16, 0, 9) end
	corner(sw, "pill")
	local edge, shine, sheen = liquid(sw)
	local g = accentGrad(sw, 0)
	local glow = inst("UIStroke", {Color = C.clay, Thickness = 3, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, sw)
	themed[#themed + 1] = {glow, "Color", "clay"}
	local knob = inst("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, sw)
	corner(knob, "pill")
	local first = true
	local function paint()
		local on = S[key]
		sheen.Enabled, g.Enabled, edge.Enabled, shine.Visible = not on, on, not on, not on
		local t = first and 0 or 0.22
		tween(sw, t, {BackgroundTransparency = on and 0 or math.clamp(TH.glass / 100 + 0.82, 0, 0.95)})
		tween(glow, t + 0.1, {Transparency = on and 0.6 or 1})
		-- the knob stretches a little while it slides, like a drop of liquid
		if not first then
			tween(knob, 0.1, {Size = UDim2.fromOffset(24, 18)}).Completed:Connect(function() tween(knob, 0.18, {Size = UDim2.fromOffset(18, 18)}) end)
		end
		tween(knob, t + 0.06, {Position = on and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
		first = false
	end
	inst("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, f).MouseButton1Click:Connect(function()
		S[key] = not S[key] paint() if cb then cb(S[key]) end
	end)
	paint()
	UI.refresh[#UI.refresh + 1] = function() paint() if cb then cb(S[key]) end end
	UI.repaint[#UI.repaint + 1] = paint
end
-- slim track with a glowing accent fill (like the progress ring in the soft glass widget)
function UI.el:slider(text, key, min, max, step, cb, d, store)
	store = store or S
	local dy = d and 26 or 0
	local f = row(self, 56 + dy)
	local l = lbl(f, text) l.Size = UDim2.new(1, -32, 0, 32)
	desc(f, l, d, 100)
	local val = th(inst("TextLabel", {FontFace = face(SEMI), TextSize = 13, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 0), Size = UDim2.fromOffset(80, 32), TextXAlignment = Enum.TextXAlignment.Right}, f), "TextColor3", "text")
	local bar = inst("Frame", {Position = UDim2.new(0, 16, 0, 38 + dy), Size = UDim2.new(1, -32, 0, 4), BackgroundColor3 = WHITE, BackgroundTransparency = 0.86, BorderSizePixel = 0}, f)
	corner(bar, "pill")
	local fill = inst("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, bar)
	corner(fill, "pill") accentGrad(fill, 0)
	local knob = inst("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0}, fill)
	corner(knob, "pill")
	themed[#themed + 1] = {inst("UIStroke", {Color = C.clay, Thickness = 3, Transparency = 0.55}, knob), "Color", "clay"}
	local hit = inst("TextButton", {Text = "", BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 28 + dy), Size = UDim2.new(1, -16, 0, 22)}, f)
	local function paint() fill.Size = UDim2.fromScale(math.clamp((store[key] - min) / (max - min), 0, 1), 1) val.Text = tostring(store[key]) end
	local dragging = false
	local function set(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local v = math.floor((min + (max - min) * a) / step + 0.5) * step
		if step < 1 then v = tonumber(string.format("%.2f", v)) end
		store[key] = v paint() if cb then cb(v) end
	end
	hit.MouseButton1Down:Connect(function(x) dragging = true set(x) end)
	conn(UIS.InputChanged, function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then set(i.Position.X) end end)
	conn(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	paint()
	UI.refresh[#UI.refresh + 1] = paint
	return paint
end
-- liquid glass pill that cycles through the options
function UI.el:choice(text, key, opts, cb, d, store)
	store = store or S
	local f = row(self, d and 58) desc(f, lbl(f, text), d, 156)
	local b = th(inst("TextButton", {FontFace = face(MED), TextSize = 12, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(132, 26), AutoButtonColor = false}, f), "TextColor3", "text")
	if d then b.AnchorPoint, b.Position = Vector2.new(1, 0), UDim2.new(1, -14, 0, 8) end
	corner(b, "pill") liquid(b) pressable(b)
	local function paint() b.Text = tostring(store[key]) .. "  ›" end
	b.MouseButton1Click:Connect(function()
		local i = table.find(opts, store[key]) or 0
		store[key] = opts[i % #opts + 1] paint() if cb then cb(store[key]) end
	end)
	paint()
	UI.refresh[#UI.refresh + 1] = paint
	return paint
end
-- full-width liquid glass pill button
function UI.el:button(text, fn, d)
	self.n += 1
	local b = th(inst("TextButton", {Text = d and (text .. "\n<font size=\"11\" transparency=\"0.4\">" .. d .. "</font>") or text, RichText = true, FontFace = face(SEMI),
		TextSize = 13, Size = UDim2.new(1, 0, 0, d and 50 or 38), AutoButtonColor = false, LayoutOrder = self.n}, self.page), "TextColor3", "text")
	corner(b, "pill")
	liquid(b, true) pressable(b)
	b.MouseEnter:Connect(function() tween(b, 0.18, {BackgroundTransparency = math.clamp(TH.glass / 100 + 0.62, 0, 0.95)}) end)
	b.MouseLeave:Connect(function() tween(b, 0.25, {BackgroundTransparency = math.clamp(TH.glass / 100 + 0.74, 0, 0.95)}) end)
	b.MouseButton1Click:Connect(function() task.spawn(fn) end)
	return b
end
function UI.el:input(text, placeholder, cb)
	local f = row(self) lbl(f, text)
	local box = th(th(inst("TextBox", {PlaceholderText = placeholder, Text = "", FontFace = face(MED), TextSize = 12,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(170, 26), ClearTextOnFocus = false}, f), "TextColor3", "text"), "PlaceholderColor3", "muted")
	corner(box, "pill") liquid(box)
	box.FocusLost:Connect(function(enter) if cb then cb(box.Text, enter) end end)
	return box
end
function UI.el:label(text)
	self.n += 1
	local f = card(inst("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = self.n}, self.page))
	inst("UIPadding", {PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)}, f)
	local l = th(inst("TextLabel", {Text = text, RichText = true, FontFace = face(), TextSize = 13, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LineHeight = 1.2}, f), "TextColor3", "text")
	return function(s) l.Text = s end
end
function UI.el:list(h)
	local f = row(self, h)
	local sc = th(inst("ScrollingFrame", {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, f), "ScrollBarImageColor3", "stroke")
	inst("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, sc)
	return sc
end
local function listItem(sc, text, btnText, fn, order)
	local f = inst("Frame", {Size = UDim2.new(1, -6, 0, 32), BorderSizePixel = 0, LayoutOrder = order or 0, BackgroundColor3 = WHITE, BackgroundTransparency = 0.94}, sc)
	corner(f, 12)
	th(inst("TextLabel", {Text = text, FontFace = face(), TextSize = 12, BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -100, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, f), "TextColor3", "text")
	if btnText then
		local b = th(inst("TextButton", {Text = btnText, FontFace = face(SEMI), TextSize = 12, BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(80, 24), AutoButtonColor = true}, f), "TextColor3", "bg")
		corner(b, "pill") accentGrad(b, 0)
		b.MouseButton1Click:Connect(function() task.spawn(fn) end)
	end
	return f
end

----------------------------------------------------------------- notifications (soft glass cards)
local Toasts = inst("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(420, 500), BackgroundTransparency = 1}, Gui)
inst("UIListLayout", {Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, Toasts)
local toastN = 0
-- one card for every notification: top centre, newest on top, colours + glass from the chosen preset
local function toastCard(title, text, col)
	toastN += 1
	local holder = inst("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = -toastN}, Toasts)
	local f = inst("Frame", {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, -20), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, holder)
	corner(f, 18) local st = rim(f, 0.82)
	inst("UIGradient", {Rotation = 90, Color = ColorSequence.new(C.bg:Lerp(WHITE, 0.14), C.bg)}, f)
	inst("UIPadding", {PaddingTop = UDim.new(0, 13), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 44), PaddingRight = UDim.new(0, 18)}, f)
	-- the padding moves children too, so the dot sits at a negative x to land in the left margin, level with the title
	local dot = inst("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(-26, 5), BackgroundColor3 = col or C.clay, BorderSizePixel = 0}, f)
	corner(dot, "pill")
	inst("UIStroke", {Color = col or C.clay, Thickness = 3, Transparency = 0.6}, dot)
	local lbl = inst("TextLabel", {Text = "<b>" .. title .. "</b>\n" .. text, RichText = true, FontFace = face(), TextSize = 17, LineHeight = 1.1, TextColor3 = C.text, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left}, f)
	tween(f, 0.4, {Position = UDim2.new(), BackgroundTransparency = math.clamp(TH.glass / 100, 0, 0.6)}, Enum.EasingStyle.Back)
	local closed = false
	local function close()
		if closed then return end closed = true
		tween(f, 0.3, {Position = UDim2.fromOffset(0, -20), BackgroundTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, x in ipairs(f:GetDescendants()) do
			if x:IsA("TextLabel") then tween(x, 0.25, {TextTransparency = 1}) elseif x:IsA("UIStroke") then tween(x, 0.25, {Transparency = 1}) elseif x:IsA("Frame") then tween(x, 0.25, {BackgroundTransparency = 1}) end
		end
		task.delay(0.35, function() if holder.Parent then holder:Destroy() end end)
	end
	return lbl, close, st
end
local function notify(title, text, col)
	if not S.Notify then return end
	local _, close = toastCard(title, text, col)
	task.delay(5, close)
end

----------------------------------------------------------------- trackers / panels the hub adds itself
-- anything a hub puts in the GUI (stat panels, timers, warnings) gets the same glass, outline, corners and font
do
local libOwn = {[Win] = true, [Shadow] = true, [Tog] = true, [Toasts] = true}
local MONT = "rbxasset://fonts/families/Montserrat.json"
local function glassify(o)
	if libOwn[o] or not o:IsA("GuiObject") or o:GetAttribute("NoGlass") or o:GetAttribute("Glassed") then return end
	o:SetAttribute("Glassed", true)
	local function refont(d)
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then pcall(function() d.FontFace = Font.new(MONT, d.FontFace.Weight, d.FontFace.Style) end) end
	end
	refont(o)
	for _, d in ipairs(o:GetDescendants()) do refont(d) end
	o.DescendantAdded:Connect(function(d) task.defer(refont, d) end)
	if o.BackgroundTransparency >= 0.95 then return end
	o.BackgroundColor3 = WHITE
	glassy(o, 0.04)
	if o:IsA("Frame") then
		-- smoked glass, lighter at the top
		local g = inst("UIGradient", {Rotation = 90}, o)
		painter(function() g.Color = ColorSequence.new(C.bg:Lerp(WHITE, 0.16), C.bg) end)
	else
		-- text panels: a gradient would also tint the text, so these get the flat glass tone
		painter(function() o.BackgroundColor3 = C.bg:Lerp(WHITE, 0.1) end)
	end
	local c = o:FindFirstChildOfClass("UICorner")
	if c then c.CornerRadius = UDim.new(0, 14) else corner(o, 14) end
	for _, s in ipairs(o:GetChildren()) do if s:IsA("UIStroke") then s:Destroy() end end
	rim(o, 0.8)
end
conn(Gui.ChildAdded, function(c) task.defer(glassify, c) end)
task.defer(function() for _, c in ipairs(Gui:GetChildren()) do glassify(c) end end)
end

----------------------------------------------------------------- theme tab (always the last tab)
local function applyTheme()
	loadTheme()
	for _, t in ipairs(themed) do pcall(function() t[1][t[2]] = C[t[3]] end) end
	for _, g in ipairs(grads) do g.Color = ColorSequence.new(C.clay, C.accent2) end
	for _, gp in ipairs(glassParts) do gp[1].BackgroundTransparency = math.clamp(TH.glass / 100 + gp[2], 0, 0.95) end
	for _, f in ipairs(painters) do pcall(f) end
	paintTabs()
	for _, f in ipairs(UI.repaint) do pcall(f) end
	pcall(function() writefile(THEME_FILE, Http:JSONEncode(TH)) end)
end
H.applyTheme = applyTheme
task.defer(function()
	local T = UI.tab("Theme", 999)
	T:section("Preset")
	local names = {} for _, p in ipairs(PRESETS) do names[#names + 1] = p.name end
	local repaintPickers = {}
	T:choice("Theme", "preset", names, function()
		TH.primary, TH.secondary = nil, nil -- a new preset brings its own accents
		applyTheme()
		for _, f in ipairs(repaintPickers) do f() end
	end, "Shared by all my hubs: pick it once and every hub uses it.", TH)
	T:slider("Glass (transparency %)", "glass", 20, 45, 1, function() applyTheme() end, nil, TH)
	-- colour pickers: hue / saturation / brightness sliders plus a hex box
	local function picker(label, key)
		T:section(label)
		local hsv = {}
		local function cur() return key == "primary" and C.clay or C.accent2 end
		local function readHSV() local h, s, v = cur():ToHSV() hsv.h, hsv.s, hsv.v = math.floor(h * 360 + 0.5), math.floor(s * 100 + 0.5), math.floor(v * 100 + 0.5) end
		readHSV()
		local f = row(T, 40)
		lbl(f, "Colour")
		local sw = inst("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(48, 24), BorderSizePixel = 0, BackgroundColor3 = cur()}, f)
		corner(sw, "pill") rim(sw, 0.55)
		local box = th(inst("TextBox", {Text = "", FontFace = face(MED), TextSize = 12, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -70, 0.5, 0),
			Size = UDim2.fromOffset(88, 24), ClearTextOnFocus = false}, f), "TextColor3", "text")
		corner(box, "pill") liquid(box)
		local paints = {}
		local function push(c)
			TH[key] = c:ToHex()
			applyTheme()
			sw.BackgroundColor3 = c
			box.Text = "#" .. c:ToHex():upper()
		end
		local function fromHSV() push(Color3.fromHSV(hsv.h / 360, hsv.s / 100, hsv.v / 100)) end
		paints[#paints + 1] = T:slider("Hue", "h", 0, 360, 1, fromHSV, nil, hsv)
		paints[#paints + 1] = T:slider("Saturation", "s", 0, 100, 1, fromHSV, nil, hsv)
		paints[#paints + 1] = T:slider("Brightness", "v", 0, 100, 1, fromHSV, nil, hsv)
		box.FocusLost:Connect(function() local c = hex((box.Text:gsub("#", ""))) if c then push(c) readHSV() for _, p in ipairs(paints) do p() end end end)
		local function repaint() readHSV() for _, p in ipairs(paints) do p() end sw.BackgroundColor3 = cur() box.Text = "#" .. cur():ToHex():upper() end
		repaint()
		repaintPickers[#repaintPickers + 1] = repaint
	end
	picker("Primary colour", "primary")
	picker("Secondary colour", "secondary")
	T:button("Reset to preset colours", function() TH.primary, TH.secondary = nil, nil applyTheme() for _, f in ipairs(repaintPickers) do f() end end)
	paintTabs()
end)
-- end of UI library

----------------------------------------------------------------- game data
local R = RS:WaitForChild("Remotes")
local okCD, CD = pcall(require, RS:WaitForChild("Shared"):WaitForChild("CardData")) -- pure data module, safe to re-run
if not okCD or type(CD) ~= "table" then
	local why = "Your executor (" .. tostring(identifyexecutor and identifyexecutor() or "?") .. ") couldn't load the game's card list: " .. tostring(CD)
	warn("[MLPH] " .. why) notify("Pony Cards Hub", why .. ". Send this to the script owner.")
	return
end
local RAR = CD.Rarities
local function tierOf(r) return RAR[r] and RAR[r].tier or 0 end
local function sellOf(r) return RAR[r] and RAR[r].sell or 0 end
local SETS, SET_TOTAL = {}, {}
for id, s in pairs(CD.Sets) do SETS[#SETS + 1] = s SET_TOTAL[id] = 0 end
table.sort(SETS, function(a, b) return (a.order or 0) < (b.order or 0) end)
for _, c in ipairs(CD.Cards) do if SET_TOTAL[c.set] then SET_TOTAL[c.set] += 1 end end
local SET_IDS = {"Smart"}
for _, s in ipairs(SETS) do SET_IDS[#SET_IDS + 1] = s.id end

local function fmt(n) return tostring(math.floor(n or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") end
local function call(name, ...)
	local ok, a, b, c = pcall(R[name].InvokeServer, R[name], ...)
	if not ok then return false, tostring(a) end
	return a, b, c
end

-- our own copy of the profile; every remote that changes it hands back a fresh one.
-- Cards now arrive packed (cardsWire); the game's ProfileWire turns them back into owned/first/last.
-- Each profile also goes to the game's Store, so its coin counter, binder and piles stay live.
local okPW, PW = pcall(require, RS.Shared:WaitForChild("ProfileWire", 10))
local Store
pcall(function()
	for _, m in ipairs(LP:WaitForChild("PlayerScripts"):GetDescendants()) do
		if m:IsA("ModuleScript") and m.Name == "Store" then Store = require(m) break end
	end
end)
local function fix(p)
	if okPW and type(PW) == "table" then pcall(PW.unpack, p) end
	if type(Store) == "table" and type(Store.applySnapshot) == "function" then pcall(Store.applySnapshot, p) end
	return p
end
local P
repeat local ok = call("GetProfile") if type(ok) == "table" then P = fix(ok) end if not P then task.wait(1) end until P or not H.alive
local function take(r)
	if type(r) ~= "table" then return end
	if type(r.profile) == "table" then P = fix(r.profile) elseif r.money and r.packs then P = fix(r) end
end
local function refresh() local r = call("GetProfile") if type(r) == "table" and r.money then P = fix(r) end end
local function on(k) if k == "Pairs" or k == "Post" then return S[k] end return S.Full or S[k] end

local ST = {start = os.clock(), earned = 0, boards = 0, posts = 0, opened = 0, sold = 0, hits = 0, golden = 0, pairSlow = 0, pairWait = 0, postBack = 0, postWait = 0, postFails = 0}
-- going too fast flags you in the game's anti-cheat: no more coins in that server. Hop to a new one by itself (max once per 2 min).
local function flagged(what)
	if not (S.AutoRejoin and H.hop) then return false end
	local last = 0 pcall(function() last = tonumber(readfile("PonyCardsHub_rejoin.txt")) or 0 end)
	if os.time() - last < 120 then return false end
	pcall(writefile, "PonyCardsHub_rejoin.txt", tostring(os.time()))
	notify("Flagged by the game", what .. " stopped paying, joining a new server to clear it")
	task.wait(1.5) H.hop(false) -- the flag sticks to the server, rejoining the same one keeps it
	return true
end
H.ST = ST H.P = function() return P end
local function earn(n) if type(n) == "number" and n > 0 then ST.earned += n end end

----------------------------------------------------------------- Pony Pairs solver
-- the server deals 12 face-down cards and reveals a face on each flip; remember faces, match known pairs first
local function playBoard()
	local okd, d = call("Memory", "deal")
	if not okd or type(d) ~= "table" then return false end
	local n, seen, done, last = d.n or 12, {}, {}, nil
	local function flip(i)
		task.wait(0.55 + math.random() * 0.5) -- the update flags matches made too fast
		local ok, r = call("Memory", "flip", i)
		if ok and type(r) == "table" then
			if r.id then seen[i] = r.id end
			if r.match then done[i] = true if r.slow then ST.pairSlow += 1 elseif (r.pay or 0) > 0 then ST.pairSlow = 0 end end
			earn(r.pay) earn(r.bonus) take(r)
		end
		return r
	end
	local function knownPair() local by = {} for i, id in pairs(seen) do if not done[i] then if by[id] then return by[id], i end by[id] = i end end end
	local function partner(i) for j, id in pairs(seen) do if j ~= i and not done[j] and id == seen[i] then return j end end end
	local function unknown(skip) for i = 1, n do if not seen[i] and i ~= skip then return i end end end
	for _ = 1, 40 do
		if not (H.alive and on("Pairs")) then return false end
		local a, b = knownPair()
		if a then flip(a) last = flip(b)
		else
			local u = unknown() if not u then break end
			flip(u)
			local p = partner(u)
			if p then last = flip(p) else local v = unknown(u) if not v then break end last = flip(v) end
		end
		if type(last) == "table" and last.finished then ST.boards += 1 return true end
	end
	return false
end
task.spawn(function()
	while H.alive do
		if on("Pairs") then
				if not playBoard() then task.wait(1.5) end
				-- a whole board of "too fast" = the game's coin limit for Pairs: rest instead of feeding it more boards
				if ST.pairSlow >= 2 then ST.pairSlow = 0 if not flagged("Pony Pairs") then ST.pairWait = os.clock() + 180 end end
				while H.alive and os.clock() < ST.pairWait do task.wait(1) end
				task.wait(2.5 + math.random() * 2.5) -- a person needs a moment to start the next board
		else task.wait(0.5) end
	end
end)

----------------------------------------------------------------- perfect postcards
-- the game trusts the client's accuracy; server only rate-limits (~1 per 3s, "Too fast")
task.spawn(function()
	while H.alive do
		if on("Post") then
			local k = (P.postK == 4 or P.postK == 5) and P.postK or 5
			local pf = math.random(2, 3) -- since the update a perfect card pays nothing; a good human score still does
			local ok, r = call("SubmitPostcard", math.floor((0.82 + math.random() * 0.09) * 100) / 100, pf, k, pf)
			if ok and type(r) == "table" then earn(r.reward) ST.posts += 1 ST.postBack = 0 ST.postFails = 0 take(r) task.wait(S.PostGap + math.random() * 10)
			elseif r == "Too fast" then
				-- each refused try may restart the game's timer, so wait longer every time (up to 5 min)
				ST.postFails += 1
				if ST.postFails >= 3 and flagged("Postcards") then ST.postFails = 0 end
				ST.postBack = math.min(math.max(ST.postBack * 2, S.PostGap + 20), 600)
				ST.postWait = os.clock() + ST.postBack
				while H.alive and os.clock() < ST.postWait do task.wait(1) end
			else task.wait(5) end
		else task.wait(0.5) end
	end
end)

----------------------------------------------------------------- auto claim: daily notes, calendar, collection
local function claimAll(loud)
	if on("AutoNotes") or loud then
		for i, n in ipairs(P.notes and P.notes.list or {}) do
			if not n.got and n.have >= n.n then
				local ok, r = call("Notes", "claim", i)
				if ok and type(r) == "table" then take(r) earn(r.coins) earn(r.bonus) notify("Daily note", "+" .. fmt((r.coins or 0) + (r.bonus or 0)) .. " coins") end
			end
		end
	end
	if on("AutoDaily") or loud then
		local ok, st = call("Daily", "status")
		if ok and type(st) == "table" and st.canClaim then
			local ok2, r = call("Daily", "claim")
			if ok2 and type(r) == "table" then
				take(r)
				local g = st.rewards and st.rewards[r.day or st.day] or {}
				earn(g.coins)
				notify("Calendar gift", g.coins and ("+" .. fmt(g.coins) .. " coins") or ((g.count or 1) .. "x golden " .. tostring(g.pack)))
			end
		end
	end
	if on("AutoCollect") or loud then
		local ok, prof, tot = call("Collection", "*")
		if ok then take(prof) local c = type(tot) == "table" and tot.coins or 0 earn(c) notify("Collection reward", "+" .. fmt(c) .. " coins") end
	end
end
task.spawn(function() while H.alive do pcall(claimAll, false) task.wait(15) end end)

----------------------------------------------------------------- packs: picker, sniper, buy, open, sell
local function ownedBySet()
	local t = {}
	for id, cnt in pairs(P.owned or {}) do local c = CD.ById[id] if c and cnt > 0 then t[c.set] = (t[c.set] or 0) + 1 end end
	return t
end
-- smart picker: most new cards per coin (missing share × cards per pack ÷ price)
local function pickSet()
	local have, best, bestScore = ownedBySet(), nil, -1
	for _, s in ipairs(SETS) do
		local total = SET_TOTAL[s.id]
		if total > 0 and s.price and (P.packs[s.id] or 0) < 40 then
			local score = (total - (have[s.id] or 0)) / total * (s.perPack or 5) / s.price
			if score > bestScore then best, bestScore = s.id, score end
		end
	end
	return best
end
-- the desk holds 40 packs in total
local function deskCount() local n = 0 for _, c in pairs(P.packs or {}) do n += c end return n end
-- "Picked sets": the ticked sets, buying whichever has the fewest packs on the desk so they fill evenly
if S.BuySet ~= "Smart" and S.BuySet ~= "Picked sets" then S["Buy_" .. S.BuySet] = true S.BuySet = "Picked sets" end -- old single-set setting
local function chooseSet()
	if S.BuySet == "Smart" then return pickSet() end
	local best, bn
	for _, st in ipairs(SETS) do
		if S["Buy_" .. st.id] and st.price and P.money - st.price >= S.Reserve then
			local n = P.packs[st.id] or 0
			if not bn or n < bn then best, bn = st.id, n end
		end
	end
	return best
end
local function buy(set, col)
	local s = CD.Sets[set]
	if not s then return false end
	local ok, r = call("BuyPack", set, col or (P.shopGold and P.shopGold[set]) or 1)
	if ok then take(r) end
	return ok, r
end

-- pull log
local pullList, pullN = nil, 0
local function logCards(cards, set)
	for _, c in ipairs(cards or {}) do
		local d = CD.ById[c.id]
		if d and tierOf(d.rarity) >= tierOf(S.LogMin) then
			ST.hits += 1
			local text = (c.new and "[NEW] " or "") .. d.name .. "  ·  " .. (RAR[d.rarity] and RAR[d.rarity].label or d.rarity) .. "  ·  " .. (CD.Sets[d.set] and CD.Sets[d.set].short or d.set)
			if pullList then
				pullN += 1
				listItem(pullList, os.date("%H:%M") .. "  " .. text, nil, nil, -pullN)
				local items = {}
				for _, f in ipairs(pullList:GetChildren()) do if f:IsA("Frame") then items[#items + 1] = f end end
				if #items > 200 then table.sort(items, function(a, b) return a.LayoutOrder < b.LayoutOrder end) items[#items]:Destroy() end
			end
			if tierOf(d.rarity) >= tierOf(S.NotifyMin) then notify("Big pull!", text, Color3.fromRGB(255, 205, 70)) end
		end
	end
end

-- the game only allows about 2 pack openings every 3 seconds ("Slow down a little"),
-- and refused tries seem to count too, so space them out and back off when told to
local nextOpen = 0
local function openOne()
	if os.clock() < nextOpen then return false, "wait" end
	for set, n in pairs(P.packs or {}) do
		if n > 0 and CD.Sets[set] then
			local gold = P.gold and P.gold[set] or 0
			local golden = gold > 0
			if golden and not S.OpenGolden then golden = false if n - gold <= 0 then continue end end
			local ok, res = call("OpenPack", set, golden, 1, {})
			nextOpen = os.clock() + 1.6
			if ok == false and tostring(res):lower():find("slow") then nextOpen = os.clock() + 3 return false, "wait" end
			if ok and type(res) == "table" then
				take(res.profile)
				ST.opened += 1
				pcall(function() R.PackProgress:InvokeServer("done") end) -- so the game doesn't replay a pending pack
				logCards(res.cards, set)
				return true
			end
			return false
		end
	end
	return false
end

local function protectedCards()
	local p = {}
	for k, v in pairs(P.fav or {}) do if type(k) == "string" then p[k] = true elseif type(v) == "string" then p[v] = true end end
	for _, id in ipairs(P.shelf or {}) do if id ~= "" then p[id] = true end end
	for _, rowT in ipairs(P.display and P.display.rows or {}) do
		for _, s in ipairs(rowT.s or {}) do if s ~= "" then p[(s:gsub("^%a:", ""))] = true end end
	end
	return p
end
-- what auto-sell would sell: copies above Keep, rarity ≤ SellMax, never favourites / shelf / display
local function sellPlan()
	local prot, plan, n, val = protectedCards(), {}, 0, 0
	for id, cnt in pairs(P.owned or {}) do
		local c = CD.ById[id]
		if c and cnt > S.Keep and not prot[id] and tierOf(c.rarity) <= tierOf(S.SellMax) then
			plan[id] = cnt - S.Keep n += cnt - S.Keep val += (cnt - S.Keep) * sellOf(c.rarity)
		end
	end
	return plan, n, val
end
local function sellDupes(loud)
	local plan, n, val = sellPlan()
	if n == 0 then if loud then notify("Sell", "Nothing to sell with these settings") end return end
	local ok, r = call("SellCards", plan, {keep = S.Keep})
	if ok then take(r) earn(val) ST.sold += n if loud then notify("Sold duplicates", n .. " cards · +" .. fmt(val) .. " coins") end
	elseif loud then notify("Sell failed", tostring(r)) end
end

local snipeCd = {}
task.spawn(function()
	local lastSell, lastRefresh = 0, 0
	while H.alive do
		if os.clock() - lastRefresh > (on("Sniper") and 2 or 5) then refresh() lastRefresh = os.clock() end
		-- golden pack sniper: the server marks one shop slot as golden (guaranteed hit, same price)
		if on("Sniper") then
			for set, col in pairs(P.shopGold or {}) do
				local s = CD.Sets[set]
				if s and P.money >= s.price and os.clock() - (snipeCd[set] or 0) > 5 then
					snipeCd[set] = os.clock()
					if buy(set, col) then ST.golden += 1 notify("Golden pack sniped", s.name .. " · guaranteed hit", Color3.fromRGB(255, 205, 70)) end
				end
			end
		end
		if on("AutoBuy") then
			local set = chooseSet()
			local s = set and CD.Sets[set]
			if s and P.money - s.price >= S.Reserve and deskCount() < 40 then buy(set) end
		end
		local opened = on("AutoOpen") and openOne()
		if on("AutoSell") and os.clock() - lastSell > 6 then lastSell = os.clock() pcall(sellDupes, false) end
		task.wait(opened and 0.35 or 0.6)
	end
end)

----------------------------------------------------------------- anti-AFK
conn(LP.Idled, function()
	if not S.AntiAFK then return end
	pcall(function() local vu = game:GetService("VirtualUser") vu:CaptureController() vu:ClickButton2(Vector2.new()) end)
end)

----------------------------------------------------------------- stats overlay + trade checker panel
local function panel(pos, anchor)
	local f = inst("Frame", {AnchorPoint = anchor, Position = pos, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = C.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false}, Gui)
	corner(f, 8) stroke(f)
	inst("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, f)
	local l = inst("TextLabel", {RichText = true, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.text, BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
	return f, l
end
local ovF, ovL = panel(UDim2.fromOffset(12, 60), Vector2.new(0, 0))
local trF, trL = panel(UDim2.new(0.5, 0, 0, 60), Vector2.new(0.5, 0))

local function offerValue(o, mine)
	local cards, sell, special = 0, 0, 0
	for id, cnt in pairs(o.cards or {}) do
		local c = CD.ById[id]
		if c then
			cards += cnt sell += cnt * sellOf(c.rarity)
			local have = P.owned and P.owned[id] or 0
			if mine and have - cnt <= 0 then special += 1 end -- giving away your last copy
			if not mine and have == 0 then special += 1 end -- a card you don't have yet
		end
	end
	return cards, sell, o.coins or 0, special
end
local lastTrade = "No trade seen yet."
conn(R.TradeEvent.OnClientEvent, function(p)
	if type(p) ~= "table" then return end
	if p.kind == "state" and type(p.mine) == "table" and type(p.theirs) == "table" then
		local gc, gs, gco, last = offerValue(p.mine, true)
		local tc, ts, tco, new = offerValue(p.theirs, false)
		local diff = (ts + tco) - (gs + gco)
		local col = diff >= 0 and "#7ee0a0" or "#ff8a7a"
		lastTrade = string.format("<b>TRADE CHECK</b>\nYou give: %d cards · sell value %s · %s coins%s\nYou get: %d cards · sell value %s · %s coins%s\n<font color=\"%s\"><b>%s%s value for you</b></font>",
			gc, fmt(gs), fmt(gco), last > 0 and (" · <font color=\"#ff8a7a\">" .. last .. " last cop" .. (last == 1 and "y" or "ies") .. "</font>") or "",
			tc, fmt(ts), fmt(tco), new > 0 and (" · <font color=\"#7ee0a0\">" .. new .. " new for your binder</font>") or "",
			col, diff >= 0 and "+" or "-", fmt(math.abs(diff)))
		trL.Text = lastTrade
		trF.Visible = S.TradeCheck
	elseif p.kind == "closed" then trF.Visible = false end
end)

----------------------------------------------------------------- menu
local T = UI.tab("Main")
T:label("Made by Stizzyyy · always free & keyless.\nFound this behind a key system? It's a stolen copy.")
T:section("Full auto")
T:toggle("Full auto​​", "Full", save, "Turns on every feature in this menu, including auto buy and auto sell. Not Pony Pairs and postcards: the game stopped paying for those (see Changelog).")
local status = T:label("…")
T:section("Rejoin")
T:toggle("Reload the hub after rejoining​​", "ReloadOnRejoin", save, "Starts this hub again by itself after you use a rejoin button.")
T:toggle("Auto rejoin when flagged​​", "AutoRejoin", save, "The game stops paying coins once it thinks you go too fast, until you rejoin. This joins a new server by itself (at most every 2 minutes) and reloads the hub.")
-- a different public server with room (a plain Teleport often drops you back in the same one)
local function newServer()
	local ok, body = pcall(game.HttpGet, game, "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
	local ok2, t = pcall(Http.JSONDecode, Http, ok and body or "")
	local list = {}
	for _, sv in ipairs(ok2 and type(t) == "table" and t.data or {}) do
		if sv.id ~= game.JobId and (sv.playing or 0) < (sv.maxPlayers or 0) - 1 then list[#list + 1] = sv.id end
	end
	return #list > 0 and list[math.random(#list)] or nil
end
local function hop(sameServer)
	local TP = game:GetService("TeleportService")
	if S.ReloadOnRejoin or S.AutoRejoin then
		pcall(queue_on_teleport, 'task.wait(3) if isfile("PonyCardsHub.lua") then loadstring(readfile("PonyCardsHub.lua"))() end')
	end
	notify(sameServer and "Rejoin" or "New server", sameServer and "Rejoining this server…" or "Leaving and joining a new server…")
	local target = sameServer and game.JobId or newServer()
	local ok = target and pcall(TP.TeleportToPlaceInstance, TP, game.PlaceId, target, LP)
	if not ok then pcall(TP.Teleport, TP, game.PlaceId, LP) end
end
H.hop = hop
T:button("Rejoin this server", function() hop(true) end, "Redraws your binder, daily notes and pack piles")
T:button("Leave and join a new server", function() hop(false) end, "Same refresh, in a different server")
T:section("Extras")
T:toggle("Stats overlay​​", "Overlay", save, "Small bar at the top left: coins, earned this session, coins per minute.")
T:toggle("Anti-AFK​​", "AntiAFK", save, "Stops Roblox kicking you after 20 minutes idle.")
T:toggle("Notifications​​", "Notify", save, "Pop-ups for claims, big pulls and sniped golden packs.")
T:button("Unload", function() H.Unload() end, "Stops everything and removes the menu")

T = UI.tab("Farm")
T:section("Coins")
T:label("<font color=\"#ff8a7a\">Not paying since the 24 Nov update (game anti-cheat). Off by default, see Changelog.</font>")
T:toggle("Pony Pairs solver​​", "Pairs", save, "Plays the memory game for you, remembering every card. About 70 coins a board, at a human pace (the game pays nothing for fast matches now).")
T:toggle("Auto postcards​​", "Post", save, "Sends a good (not perfect) postcard score about every 45 s. About 35 coins each. The game refuses perfect cards and fast ones now.")
if S.PostGap < 30 then S.PostGap = 40 end -- old 3 s setting from before the update
T:slider("Postcard gap (seconds)", "PostGap", 30, 120, 1, save, "Time between postcards. Every refused one makes the game wait longer, so going faster earns less.")
T:section("Auto claim")
T:toggle("Daily notes​​", "AutoNotes", save, "Claims the three sticky-note quests on the window once they're done.")
T:toggle("Calendar gift​​", "AutoDaily", save, "Claims the daily calendar gift (coins or golden packs) when it's ready.")
T:toggle("Collection rewards​​", "AutoCollect", save, "Claims coins for reaching 25 / 50 / 75 / 100% of each rarity in a set.")
T:button("Claim everything now", function() claimAll(true) end, "Checks notes, calendar and collection right away")

T = UI.tab("Packs")
T:section("Open")
T:toggle("Auto open packs​​", "AutoOpen", save, "Opens every pack you own, no swiping or animation. About one every 1.6 s, as fast as the game allows.")
T:toggle("Open golden packs too​​", "OpenGolden", save, "Off keeps golden packs unopened so you can open them yourself.")
T:button("Open all packs now", function()
	local n = 0
	while H.alive do
		local ok, why = openOne()
		if ok then n += 1 elseif why == "wait" then task.wait(0.25) else break end
	end
	notify("Packs", "Opened " .. n)
end, "Opens every pack you have (about one every 1.6 s, the game's limit)")
T:section("Buy")
T:toggle("Golden pack sniper​​", "Sniper", save, "Buys a golden shop pack (guaranteed hit, same price) the moment one shows up.")
T:toggle("Auto buy packs​​", "AutoBuy", save, "Keeps buying while you have more coins than the reserve and room on your desk (40 packs). Auto open opens them as they arrive.")
T:choice("What to buy", "BuySet", {"Smart", "Picked sets"}, save, "Smart = the set with the most new cards per coin. Picked sets = only the sets you tick below, filled evenly.")
T:slider("Keep at least (coins)", "Reserve", 0, 5000, 50, save, "Auto buy never spends below this amount.")
T:button("Buy 1 pack now", function()
	local set = chooseSet()
	if not set then notify("Buy", "Tick at least one set, or switch to Smart") return end
	local ok, r = buy(set)
	notify("Buy", ok and ("Bought " .. CD.Sets[set].name) or tostring(r))
end, "Buys one pack the same way auto buy would")
local pickLbl = T:label("…")
T:section("Picked sets")
for _, st in ipairs(SETS) do
	if S["Buy_" .. st.id] == nil then S["Buy_" .. st.id] = false end
	T:toggle(tostring(st.name) .. "​​", "Buy_" .. st.id, save, st.price and ("Price " .. st.price .. " coins") or nil)
end

T = UI.tab("Sell")
T:toggle("Auto sell duplicates​​", "AutoSell", save, "Sells extra copies every few seconds. Never sells favourites or shelf / display cards.")
T:slider("Copies to keep", "Keep", 1, 5, 1, save, "How many of each card to keep before selling the rest.")
T:choice("Sell up to rarity", "SellMax", {"R", "SR", "HR", "SSR", "LSR", "UR"}, save, "Cards rarer than this are never sold.")
local sellLbl = T:label("…")
T:button("Sell duplicates now", function() sellDupes(true) end, "Sells once, with the settings above")

T = UI.tab("Collection")
T:label("<font color=\"#968f88\">How much of each set you own, what's missing and how many packs of it you have.</font>")
local colLbl = T:label("…")
local function renderCollection()
	local have, lines, tot, totHave = ownedBySet(), {}, 0, 0
	for _, s in ipairs(SETS) do
		local t, h = SET_TOTAL[s.id], have[s.id] or 0
		if t > 0 then
			tot += t totHave += h
			lines[#lines + 1] = string.format("<b>%s</b>   %d / %d  <font color=\"#968f88\">(%d%%, %d missing · %d packs)</font>", s.name, h, t, math.floor(h / t * 100), t - h, P.packs[s.id] or 0)
		end
	end
	table.insert(lines, 1, string.format("<b>Total</b>   %s / %s cards  (%d%%)\n", fmt(totHave), fmt(tot), tot > 0 and math.floor(totHave / tot * 100) or 0))
	colLbl(table.concat(lines, "\n"))
end
T:button("Refresh", function() refresh() renderCollection() end, "Updates the numbers now (they also update by themselves)")

T = UI.tab("Pulls")
T:choice("Log rarity from", "LogMin", {"SR", "SSR", "LSR", "UR", "SGR", "ZR"}, save, "Cards this rare or rarer from your openings go in the list below.")
T:choice("Notify rarity from", "NotifyMin", {"SSR", "LSR", "UR", "SGR", "ZR"}, save, "Cards this rare or rarer also get a pop-up.")
pullList = T:list(250)

T = UI.tab("Trade")
T:toggle("Trade value checker​​", "TradeCheck", save, "During a trade, shows what each side is worth, new cards for you and last copies you'd give. Never accepts.")
local tradeLbl = T:label(lastTrade)

T = UI.tab("Changelog")
T:label("<b>24 Nov 2026 · game update</b> (Card Market, 4 new packs)")
T:label("<font color=\"#7ee0a0\">Fixed</font>: auto sell, collection, smart pick and trade checker read your cards again (new card format). Selling sends the new keep-copies setting. The game's coin counter and pack piles update live.")
T:label("<font color=\"#7ee0a0\">New</font>: Fantasy Wonderland, Nightmare Night, Moon 12, Moon 13 and Star I packs. Auto rejoin when flagged.")
T:label("<font color=\"#ff8a7a\">Not working</font>: Pony Pairs and postcard coins. The game's new anti-cheat stops paying an account that farmed fast (normal players get it too). A new server pays about one round. A script can't fix this, it wears off over time or the game fixes it. Both are off by default and not part of Full auto.")
T:label("<font color=\"#968f88\">Still works</font>: opening, buying, golden sniper, selling, daily notes, calendar, collection rewards, trade checker.")
T:label("<b>22 Nov 2026 · first release</b>\nPony Pairs solver, perfect postcards, auto open / buy / sell, golden sniper, smart pack picker, auto claim, collection tracker, pull log, trade checker.")

conn(UIS.InputBegan, function(i, gp) if i.KeyCode == Enum.KeyCode.RightShift then Win.Visible = not Win.Visible end end)

-- refresh labels / overlay
task.spawn(function()
	local tick, hudCoin = 0, nil
	while H.alive do
		tick += 1
		local mins = math.max((os.clock() - ST.start) / 60, 1 / 60)
		local total = 0 for _, n in pairs(P.packs or {}) do total += n end
		local notes = {}
		for _, n in ipairs(P.notes and P.notes.list or {}) do notes[#notes + 1] = n.k .. " " .. math.min(n.have, n.n) .. "/" .. n.n .. (n.got and " ✓" or "") end
		local held = {}
		if os.clock() < ST.pairWait then held[#held + 1] = "Pairs " .. math.ceil(ST.pairWait - os.clock()) .. "s" end
		if os.clock() < ST.postWait then held[#held + 1] = "postcards " .. math.ceil(ST.postWait - os.clock()) .. "s" end
		status((#held > 0 and ("<font color=\"#ff8a7a\">Game says too fast, resting: " .. table.concat(held, " · ") .. "</font>\n") or "") .. string.format("<b>%s coins</b>   ·   %d packs\n+%s this session  (%s / min)\nBoards %d · postcards %d · opened %d · sold %d · hits %d · golden sniped %d\n<font color=\"#968f88\">Notes: %s</font>",
			fmt(P.money), total, fmt(ST.earned), fmt(ST.earned / mins), ST.boards, ST.posts, ST.opened, ST.sold, ST.hits, ST.golden, table.concat(notes, " · ")))
		-- keep the game's own coin counter live (it only redraws when the game itself changes coins)
		if not (hudCoin and hudCoin.Parent) then
			hudCoin = nil
			local hud = LP.PlayerGui:FindFirstChild("HUD")
			for _, d in ipairs(hud and hud:GetDescendants() or {}) do if d:IsA("TextLabel") and d.Text:find("^◆") then hudCoin = d break end end
		end
		local want = "◆  " .. fmt(P.money)
		if hudCoin and hudCoin.Text ~= want then hudCoin.Text = want end
		ovF.Visible = S.Overlay
		if S.Overlay then
			local t = os.clock() - ST.start
			ovL.Text = string.format("<b>Pony Cards Hub</b>   %s coins   ·   <font color=\"#d97757\">+%s</font>   ·   %s/min   ·   %02d:%02d",
				fmt(P.money), fmt(ST.earned), fmt(ST.earned / mins), t // 3600, (t // 60) % 60)
		end
		if tick % 3 == 1 then
			local ps = pickSet()
			pickLbl("Smart pick right now: <b>" .. (ps and CD.Sets[ps].name or "none") .. "</b>  (most new cards per coin)")
			local _, n, val = sellPlan()
			sellLbl(string.format("Would sell now: <b>%d cards</b> for <b>%s coins</b>", n, fmt(val)))
			tradeLbl(lastTrade)
			renderCollection()
		end
		task.wait(1)
	end
end)

function H.Unload()
	H.alive = false
	for _, c in ipairs(H.conns) do pcall(c.Disconnect, c) end
	for _, i in ipairs(H.insts) do pcall(i.Destroy, i) end
	if G.MLPH == H then G.MLPH = nil end
end
notify("Pony Cards Hub", UIS.KeyboardEnabled and "Ready · RightShift toggles the menu" or "Ready · tap the Pony button to show/hide", C.clay)
print("[Pony Cards Hub] by Stizzyyy · always free & keyless · rscripts.net/@Stizzyyy")
print("[MLPH] loaded on " .. tostring(identifyexecutor and identifyexecutor() or "?"))
