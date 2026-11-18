local source = game:HttpGet(
    "https://raw.githubusercontent.com/tuckerjase2-bot/fork-of-osmium/main/source.lua"
)

local chunk, err = loadstring(source)
assert(chunk, err)

local library = chunk()
local window = library:CreateWindow("UCDR manu")
library.OpenCloseKeybind = Enum.KeyCode.RightControl
local kromertab = window:CreateTab("Kromer")
local generaltab = window:CreateTab("General")
local cred = window:CreateTab("Credits and config")

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer
local pshop = game:GetService("Players").LocalPlayer.PlayerGui.Main.MainFrame.CharacterSpecificUI.Spamton_PlacableShopUI
local cshop = pshop.MainOptionsIL.ConfirmPurchase

pshop.AnchorPoint = Vector2.new(0, 1)
pshop.Size = UDim2.new(0.5, 0, 0.5, 0)
pshop.Position = UDim2.new(0, 0, 0.7, 0)
cshop.ConfirmButton.Position = UDim2.new(0, 0, 0.45, 0)
cshop.BackButton.Position = UDim2.new(0, 0, 0.6, 0)
cshop.ConfirmButton.Size = UDim2.new(0.5, 0, 0.2, 0)
cshop.BackButton.Size = UDim2.new(0.5, 0, 0.2, 0)


local desiredprice = 1
local septillion = -100000000000000000000
local desireddeal = nil
local editorenabled = false
local overridep = false
local qteassist = false
local qteDelay = 0.1
local qteRunning = false

local childAddedConn = nil

local function letterKey(ch)
	return Enum.KeyCode[string.upper(ch)]
end

local function word(str)
	local keys = {}
	for i = 1, #str do
		table.insert(keys, { key = letterKey(str:sub(i, i)) })
	end
	return keys
end

local function concat(...)
	local out = {}
	for _, list in ipairs({ ... }) do
		for _, step in ipairs(list) do
			table.insert(out, step)
		end
	end
	return out
end

local SHRINE_SEQUENCES = {
	[Enum.KeyCode.One] = {
		name = "Shrine 1 (Ground)",
		air = false,
		steps = concat({ { wait = 0.1 } }, word("grab"), { { wait = 1.5 } }, word("kick")),
	},
	[Enum.KeyCode.Two] = {
		name = "Shrine Air2",
		air = true,
		steps = word("kai"),
	},
	[Enum.KeyCode.Three] = {
		name = "Shrine 5",
		air = false,
		steps = word("cleave"),
	},
	[Enum.KeyCode.Four] = {
		name = "Shrine 6",
		air = false,
		steps = word("dismantle"),
	},
}

local aliases = {
	maho = "A SACRED TREASURE",
	heaven = "H E A V E N",
	heal = "Heal",
	extrahp = "ExtraHP",
	poison = "S.Poison",
	safetravel = "Safe Travel",
	keygen = "KEYGEN",
	wisp = "WISP JAR",
	wispjar = "WISP JAR",
	cooldown = "Remove Current Cooldowns",
	cd = "Remove Current Cooldowns"
}

local function getDealsFrame()
	local ok, frame = pcall(function()
		local gui = lp:FindFirstChild("PlayerGui")
		if not gui then return nil end
		local main = gui:FindFirstChild("Main")
		if not main then return nil end
		local mf = main:FindFirstChild("MainFrame")
		if not mf then return nil end
		local cs = mf:FindFirstChild("CharacterSpecificUI")
		if not cs then return nil end
		local sp = cs:FindFirstChild("Spamton_PlacableShopUI")
		if not sp then return nil end
		local mil = sp:FindFirstChild("MainIL")
		if not mil then return nil end
		return mil:FindFirstChild("DealsFrame")
	end)
	if ok then return frame end
	return nil
end

local function getPrice()
	if overridep then
		return septillion
	end
	return desiredprice
end

local function fixButton(btn)
	local priceV = btn:FindFirstChild("PriceV")
	local randomize = btn:FindFirstChild("RandomizePrices")
	local price = getPrice()

	if priceV then
		priceV.Value = price
		local maxVal = priceV:FindFirstChild("Max")
		if maxVal then maxVal.Value = price end
	end
	if randomize then randomize.Value = false end
end

local function fixAll()
	local df = getDealsFrame()
	if not df then return end
	for _, child in ipairs(df:GetChildren()) do
		if child:IsA("TextButton") and child.Name == "DealButton" then
			fixButton(child)
		end
	end
end

local function applyDeal(dealType)
	local df = getDealsFrame()
	if not df then
		warn("Spamton UI not found (respawned?).")
		return false
	end
	for _, child in ipairs(df:GetChildren()) do
		if child:IsA("TextButton") and child.Name == "DealButton" then
			local dealTypeV = child:FindFirstChild("DealTypeV")
			if dealTypeV then
				dealTypeV.Value = dealType
			end
			child.Text = dealType
			fixButton(child)
			print("Set first DealButton to: " .. dealType)
			return true
		end
	end
	warn("No DealButton found to edit!")
	return false
end

local function disconnectHook()
	if childAddedConn then
		childAddedConn:Disconnect()
		childAddedConn = nil
	end
end

local function hookDealsFrame()
	disconnectHook()
	local df = getDealsFrame()
	if df then
		childAddedConn = df.ChildAdded:Connect(function(child)
			if not editorenabled then return end
			if child:IsA("TextButton") and child.Name == "DealButton" then
				task.wait(0.05)
				fixButton(child)
			end
		end)
	end
end

local function setEditorEnabled(on)
	editorenabled = on
	if editorenabled then
		fixAll()
		hookDealsFrame()
	else
		disconnectHook()
	end
end

local function isSukuna()
	local c = lp.Character
	if not c then return false end
	local v = c:FindFirstChild("ClassTypeV")
	if v then
		return v.Value == "Sukuna"
	end
	return c:GetAttribute("ClassTypeV") == "Sukuna"
end

local function getModeText()
	local ok, text = pcall(function()
		return lp.PlayerGui.Main.MainFrame.BarsCanvasGroup.ModeTL.Text
	end)
	if ok and text then return text end
	return ""
end

local function isAirborne()
	local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.FloorMaterial == Enum.Material.Air
end

local function tap(key)
	VIM:SendKeyEvent(true, key, false, game)
	task.wait(0.03)
	VIM:SendKeyEvent(false, key, false, game)
end

local function runSequence(seq)
	for _, step in ipairs(seq.steps) do
		if step.key then
			tap(step.key)
			task.wait(qteDelay)
		elseif step.wait then
			task.wait(step.wait)
		end
	end
end

UIS.InputBegan:Connect(function(input, gameProcessed)
	local seq = SHRINE_SEQUENCES[input.KeyCode]
	if not seq then return end

	local function fail(reason)
		print("[QTE] " .. seq.name .. " skipped: " .. reason)
	end

	if gameProcessed then return fail("gameProcessed (game sank the input)") end
	if not qteassist then return fail("assist toggle is off") end
	if qteRunning then return fail("a sequence is already running") end
	if not isSukuna() then return fail("character is not Sukuna") end

	local rawMode = getModeText()
	local mode = string.upper(string.gsub(string.gsub(rawMode, "^%s+", ""), "%s+$", ""))
	if mode ~= "SHRINE" then return fail("mode text is '" .. rawMode .. "'") end

	if seq.air ~= isAirborne() then
		return fail(seq.air and "needs to be airborne" or "needs to be grounded")
	end

	print("[QTE] running " .. seq.name)
	qteRunning = true
	task.spawn(function()
		runSequence(seq)
		qteRunning = false
	end)
end)

local label = kromertab:CreateLabel("Mess with spamtons shop here", "like setting the prices and stuff.")

local dropdown = kromertab:CreateDropdown("Choose Deal (to set them to)",
	{"A SACRED TREASURE", "H E A V E N", "Heal", "ExtraHP", "S.Poison", "Safe Travel", "KEYGEN", "WISP JAR", "Remove Current Cooldowns"},
	function(val)
		desireddeal = val
		if editorenabled then
			applyDeal(val)
		end
	end)

local sld = kromertab:CreateSlider("Price of all deals", 1, 1000, function(arg)
	desiredprice = arg
	if editorenabled then
		fixAll()
	end
end)

local toggle = kromertab:CreateToggle("Enable Price change", false, function(arg)
	setEditorEnabled(arg)
end)

local toggle2 = kromertab:CreateToggle("Override price change with -1 septillion (above must be on)", false, function(arg)
	overridep = arg
	if editorenabled then
		fixAll()
	end
end)

local batp = generaltab:CreateButton("Reset and drop a soul (no kills gain)", function()
	lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
end)

local toggleqte = generaltab:CreateToggle("Toggle Sukuna QTE Assist", false, function(arg)
	qteassist = arg
end)

local qteDelayBox = generaltab:CreateTextbox("QTE key delay (ms)", function(value)
	local n = tonumber(value)
	if n then
		qteDelay = math.clamp(n, 0, 500) / 1000
	end
end, "100")

local ockeybind = cred:CreateOpenCloseKeybind("Open/Close Keybind")
local label2 = cred:CreateLabel("ui lib made by Trix#2794 and JulMan#1234")
local label3 = cred:CreateLabel("menu made by 505")

TextChatService.SendingMessage:Connect(function(tcm)
	local msg = string.lower(tcm.Text):gsub("%s+", "")

	if msg == "unfreestuff" then
		setEditorEnabled(false)
		print("Spamton shop editor disabled.")
		return
	end

	if not editorenabled then return end

	local dealType = aliases[msg]
	if dealType then
		applyDeal(dealType)
	end
end)

-- ===== Respawn handling =====
lp.CharacterAdded:Connect(function()
	task.wait(1.5)
	if editorenabled then
		fixAll()
		hookDealsFrame()
	end
end)


