local E, L, V, P, G, _ = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local MA = E:NewModule('MA', 'AceEvent-3.0', 'AceHook-3.0')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM
local EP = LibStub("LibElvUIPlugin-1.0")

local addonName, Engine = ...
local GetAddOnMetadata  = GetAddOnMetadata

function MA:Initialize()
	self:RawHook(UF, "SetAlpha_HealComm", MA.SetAlpha_HealComm, true)
	self:RawHook(UF, "SetTexture_HealComm", MA.SetTexture_HealComm, true)
	self:RawHook(UF, "SetFrameLevel_HealComm", MA.SetFrameLevel_HealComm, true)

	self:RawHook(UF, "Construct_HealComm", MA.Construct_HealComm, true)

	self:SecureHook(UF, "Configure_HealComm", MA.Configure_HealComm)
	self:RawHook(UF, "UpdateHealComm", MA.UpdateHealComm, true)

	EP:RegisterPlugin(addonName, nil)

	print(format("%sElvUI_MirrorAbsorb|r Version %s%s|r loaded.", E.media.hexvaluecolor, E.media.hexvaluecolor, GetAddOnMetadata("ElvUI_MirrorAbsorb", "Version")))
end

function MA:SetAlpha_HealComm(obj, alpha)
	obj.myBar:SetAlpha(alpha)
	obj.otherBar:SetAlpha(alpha)
	obj.absorbBar:SetAlpha(alpha)
	obj.healAbsorbBar:SetAlpha(alpha)
	obj.overAbsorbBar:SetAlpha(alpha)
	obj.overHealAbsorbBar:SetAlpha(alpha)
end

function MA:SetTexture_HealComm(obj, texture)
	obj.myBar:SetStatusBarTexture(texture)
	obj.otherBar:SetStatusBarTexture(texture)
	obj.absorbBar:SetStatusBarTexture(texture)
	obj.healAbsorbBar:SetStatusBarTexture(texture)
	obj.overAbsorbBar:SetStatusBarTexture(texture)
	obj.overHealAbsorbBar:SetStatusBarTexture(texture)
end

function MA:SetFrameLevel_HealComm(obj, level)
	obj.myBar:SetFrameLevel(level)
	obj.otherBar:SetFrameLevel(level)
	obj.absorbBar:SetFrameLevel(level)
	obj.healAbsorbBar:SetFrameLevel(level)
	obj.overAbsorbBar:SetFrameLevel(level)
	obj.overHealAbsorbBar:SetFrameLevel(level)
end

function MA:Construct_HealComm(frame)
	local health = frame.Health
	local parent = health.ClipFrame

	local prediction = {
		myBar = CreateFrame('StatusBar', '$parent_MyBar', parent),
		otherBar = CreateFrame('StatusBar', '$parent_OtherBar', parent),
		absorbBar = CreateFrame('StatusBar', '$parent_AbsorbBar', parent),
		overAbsorbBar = CreateFrame('StatusBar', '$parent_OverAbsorbBar', parent),
		healAbsorbBar = CreateFrame('StatusBar', '$parent_HealAbsorbBar', parent),
		overHealAbsorbBar = CreateFrame('StatusBar', '$parent_OverHealAbsorbBar', parent),
		PostUpdate = UF.UpdateHealComm,
		maxOverflow = 1,
		health = health,
		parent = parent,
		frame = frame
	}

	UF:SetAlpha_HealComm(prediction, 0)
	UF:SetFrameLevel_HealComm(prediction, 11)
	UF:SetTexture_HealComm(prediction, E.media.blankTex)

	return prediction
end

function MA:SetSize_HealComm(frame)
	local health = frame.Health
	local pred = frame.HealthPrediction
	local orientation = health:GetOrientation()

	local db = frame.db.healPrediction
	local width, height = health:GetSize()

	-- fallback just incase, can happen on profile switching
	if not width or width <= 0 then width = health.WIDTH end
	if not height or height <= 0 then height = health.HEIGHT end

	if orientation == 'HORIZONTAL' then
		local barHeight = db.height or height
		if barHeight == -1 or barHeight > height then barHeight = height end

		pred.myBar:SetSize(width, barHeight)
		pred.otherBar:SetSize(width, barHeight)
		pred.absorbBar:SetSize(width, barHeight)
		pred.overAbsorbBar:SetSize(width, barHeight)
		pred.healAbsorbBar:SetSize(width, barHeight)
		pred.overHealAbsorbBar:SetSize(width, barHeight)
		pred.parent:SetSize(width * (pred.maxOverflow or 0), height)
	else
		local barWidth = db.height or width -- this is really width now not height
		if barWidth == -1 or barWidth > width then barWidth = width end

		pred.myBar:SetSize(barWidth, height)
		pred.otherBar:SetSize(barWidth, height)
		pred.absorbBar:SetSize(barWidth, height)
		pred.overAbsorbBar:SetSize(barWidth, height)
		pred.healAbsorbBar:SetSize(barWidth, height)
		pred.overHealAbsorbBar:SetSize(barWidth, height)
		pred.parent:SetSize(width, height * (pred.maxOverflow or 0))
	end
end

function MA:Configure_HealComm(frame)
	local db = frame.db and frame.db.healPrediction
	if db and db.enable then
		local pred = frame.HealthPrediction
		local parent = pred.parent
		local myBar = pred.myBar
		local otherBar = pred.otherBar
		local absorbBar = pred.absorbBar
		local overAbsorbBar = pred.overAbsorbBar
		local healAbsorbBar = pred.healAbsorbBar
		local overHealAbsorbBar = pred.overHealAbsorbBar

		local colors = UF.db.colors.healPrediction

		if not frame:IsElementEnabled('HealthPrediction') then
			frame:EnableElement('HealthPrediction')
		end

		local health = frame.Health
		local orientation = health:GetOrientation()
		local reverseFill = health:GetReverseFill()
		local healthBarTexture = health:GetStatusBarTexture() -- :GetTexture() from here sometimes messes up? so use LSM

		pred.reverseFill = reverseFill
		pred.healthBarTexture = healthBarTexture
		pred.myBarTexture = myBar:GetStatusBarTexture()
		pred.otherBarTexture = otherBar:GetStatusBarTexture()

		UF:SetTexture_HealComm(pred, UF.db.colors.transparentHealth and E.media.blankTex or LSM:Fetch('statusbar', UF.db.statusbar))

		overHealAbsorbBar:SetReverseFill(not reverseFill)
		overAbsorbBar:SetReverseFill(reverseFill)

		overHealAbsorbBar:SetStatusBarColor(colors.overhealabsorbs.r, colors.overhealabsorbs.g, colors.overhealabsorbs.b, colors.overhealabsorbs.a)
		overAbsorbBar:SetStatusBarColor(colors.overabsorbs.r, colors.overabsorbs.g, colors.overabsorbs.b, colors.overabsorbs.a)

		overHealAbsorbBar:SetOrientation(orientation)
		overAbsorbBar:SetOrientation(orientation)

		if orientation == 'HORIZONTAL' then
			local p1 = reverseFill and 'RIGHT' or 'LEFT'
			local p2 = reverseFill and 'LEFT' or 'RIGHT'

			local anchor = db.anchorPoint
			pred.anchor, pred.anchor1, pred.anchor2 = anchor, p1, p2

			-- we're always letting the healabsorb bar backfill because overhealabsorbs will be displayed with another bar
			healAbsorbBar:ClearAllPoints()
			healAbsorbBar:Point(pred.anchor2, pred.healthBarTexture, pred.anchor2)

			overHealAbsorbBar:ClearAllPoints()
			overHealAbsorbBar:Point(anchor, health)

			overAbsorbBar:ClearAllPoints()
			overAbsorbBar:Point(anchor, health)

			parent:ClearAllPoints()
			parent:Point(p1, health, p1)
		else
			local p1 = reverseFill and 'TOP' or 'BOTTOM'
			local p2 = reverseFill and 'BOTTOM' or 'TOP'

			-- anchor converts while the health is in vertical orientation to be able to use a height
			-- (well in this case, width) other than -1 which positions the absorb on the left or right side
			local anchor = (db.anchorPoint == 'BOTTOM' and 'RIGHT') or (db.anchorPoint == 'TOP' and 'LEFT') or db.anchorPoint
			pred.anchor, pred.anchor1, pred.anchor2 = anchor, p1, p2

			-- we're always letting the healabsorb bar backfill because overhealabsorbs will be displayed with another bar
			healAbsorbBar:ClearAllPoints()
			healAbsorbBar:Point(pred.anchor2, pred.healthBarTexture, pred.anchor2)

			overHealAbsorbBar:ClearAllPoints()
			overHealAbsorbBar:Point(anchor, health)

			overAbsorbBar:ClearAllPoints()
			overAbsorbBar:Point(anchor, health)

			parent:ClearAllPoints()
			parent:Point(p1, health, p1)
		end
	elseif frame:IsElementEnabled('HealthPrediction') then
		frame:DisableElement('HealthPrediction')
	end
end

function MA:UpdateHealComm(_, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, _, _, health, maxHealth)
	local frame = self.frame
	local db = frame and frame.db and frame.db.healPrediction
	if not db or not db.absorbStyle then return end

	local pred = frame.HealthPrediction

	local myBar = pred.myBar
	local otherBar = pred.otherBar

	local healAbsorbBar = pred.healAbsorbBar
	local absorbBar = pred.absorbBar

	local overHealAbsorbBar = pred.overHealAbsorbBar
	local overAbsorbBar = pred.overAbsorbBar

	-- update min max values here as seen in ElvUI_Libraries/Core/oUF/elements/healthprediction.lua
	overHealAbsorbBar:SetMinMaxValues(0, maxHealth)
	overAbsorbBar:SetMinMaxValues(0, maxHealth)

	MA:SetSize_HealComm(frame)

	-- mirrored absorb bar mode
	if(absorb) then
		if (health == maxHealth) then -- full health, so show the whole absorb on the overabsorb bar only
			overAbsorbBar:SetValue(absorb) 
			absorbBar:Hide()
			overAbsorbBar:Show()
		else
			if(health + absorb > maxHealth) then -- absorbs and current health exceed the max health so both bars need to be shown
				local missingHealth = maxHealth - health
				absorbBar:SetValue(missingHealth) -- fill the healthbar to 100% with the absorb bar

				-- display the remaining amount on the overabsorb bar on the mirrored side but
				-- never draw over the absorbBar with the overAbsorbBar so it's still possible to see the health where both bars touch each other,
				-- this only makes sense if you have different colors for absorbs and overabsorbs configured
				-- so we're going to cap the overAbsorbBar here if the overabsorb is bigger than the current health
				if(absorb - missingHealth > health) then
					overAbsorbBar:SetValue(health)
				else
					overAbsorbBar:SetValue(absorb - missingHealth)
				end

				absorbBar:Show()
				overAbsorbBar:Show()
			else -- health and absorbs don't exceed max health, so only the absorb bar needs to be shown
				absorbBar:SetValue(absorb)
				absorbBar:Show()
				overAbsorbBar:Hide()
			end
		end
	else
		absorbBar:Hide()
		overAbsorbBar:Hide()
	end
 
	if(healAbsorb) then
		if(health - healAbsorb >= 0) then -- the unit still has some health left without healabsorbs, so only the healabsorb bar needs to be shown
			healAbsorbBar:SetValue(healAbsorb)
			healAbsorbBar:Show()
			overHealAbsorbBar:Hide()
		else -- the overhealabsorb is bigger than the unit's health, so both bars need to be shown
			local missingHealth = maxHealth - health
			healAbsorbBar:SetValue(health) -- backfill the healthbar to 0% with the healabsorb bar

			-- display the remaining amount on the overhealabsorb bar on the mirrored side but also
			-- never draw over the healAbsorbBar with the overHealAbsorbBar so it's still possible to see the health where both bars touch each other,
			-- this also only makes sense if you have different colors for healabsorbs and overhealabsorbs configured
			-- so we're going to cap the overHealAbsorbBar here if the overhealabsorb is bigger than the missing health
			if(healAbsorb - health > missingHealth) then
				overHealAbsorbBar:SetValue(missingHealth)
			else
				overHealAbsorbBar:SetValue(healAbsorb - health)
			end

			healAbsorbBar:Show()
			overHealAbsorbBar:Show()
		end
	else
		healAbsorbBar:Hide()
		overHealAbsorbBar:Hide()
	end
end

E.Libs.EP:HookInitialize(MA, MA.Initialize)