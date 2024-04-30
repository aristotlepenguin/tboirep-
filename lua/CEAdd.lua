local chestmod = RepMMod
EEE_CHEST = Isaac.GetEntityVariantByName("EEE Chest")
PersistentGameData = Isaac.GetPersistentGameData()
local game = Game()

RepMMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(a)
    local playerCount = game:GetNumPlayers()
    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)
    	if player:GetPlayerType() == Isaac.GetPlayerTypeByName("Frosty", false) and PersistentGameData:Unlocked(Isaac.GetAchievementIdByName("Frosty")) == false then
        	game:Fadeout(1, 1)
    	end
	end
end)

local function optionsCheck(pickup)
	if pickup.OptionsPickupIndex and pickup.OptionsPickupIndex > 0 then
		for _, entity in pairs(Isaac.FindByType(5, -1, -1)) do
			if entity:ToPickup().OptionsPickupIndex and entity:ToPickup().OptionsPickupIndex == pickup.OptionsPickupIndex and GetPtrHash(entity:ToPickup()) ~= GetPtrHash(pickup) then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil)
			entity:Remove()
			end
		end
	end
end
function chestmod.openEEEChest(pickup, player)
	optionsCheck(pickup)
	pickup.SubType = 1
	pickup:GetData()["IsInRoom"] = true
	pickup:GetSprite():Play("Open")
	SFXManager():Play(SoundEffect.SOUND_CHEST_OPEN, 1, 2, false, 1, 0)
	if math.random(10) <= 1 then
		local pedestal = Isaac.Spawn(5, 100, Game():GetItemPool():GetCollectible(24), pickup.Position, Vector.Zero, pickup)
		pedestal:GetSprite():ReplaceSpritesheet(5,"gfx/items/pick ups/EEE_pedestal.png") 
		pedestal:GetSprite():LoadGraphics()
		pickup:Remove()
	else
		local rolls = 1
		for i = 1, 2 do if math.random(3) > rolls then rolls = rolls + 1 end end
		if player:HasTrinket(42) then rolls = rolls + 1 end
		local mod = 1
		if player:HasCollectible(199) then mod = mod + 1 end
		local overpaid = 0
		for i = 1, rolls do
			local payout = math.random(5)
			if payout <= 1 then for i = 1, mod do Isaac.Spawn(5, 10, 1, pickup.Position, Vector.FromAngle(math.random(360)) * 3, nil) end
            elseif payout <= 2 then for i = 1, mod do Isaac.Spawn(5, 10, 2, pickup.Position, Vector.FromAngle(math.random(360)) * 3, nil) end
            elseif payout <= 3 then for i = 1, mod do Isaac.Spawn(5, 10, 5, pickup.Position, Vector.FromAngle(math.random(360)) * 3, nil) end
			elseif payout <= 4 then Isaac.Spawn(5, 300, math.random(56,77), pickup.Position, Vector.FromAngle(math.random(360)) * 3, nil) overpaid = overpaid + 1
            elseif payout <= 5 then Isaac.Spawn(5, 300, Isaac.GetCardIdByName("MinusShard"), pickup.Position, Vector.FromAngle(math.random(360)) * 3, nil) overpaid = overpaid + 1
			if i + overpaid >= rolls then break end
		end
	end
end
end
function chestmod:chestCollision(pickup, collider, _)	
	if not collider:ToPlayer() then return end
	local player = collider:ToPlayer()
	local sprite = pickup:GetSprite()
	if pickup.Variant == EEE_CHEST and pickup.SubType == 0 then
		if sprite:IsPlaying("Appear") then return false end	
		if pickup.Variant == EEE_CHEST then chestmod.openEEEChest(pickup, player) end
	end
end
chestmod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, chestmod.chestCollision)
function chestmod:chestInit(pickup)
	if pickup.Variant == EEE_CHEST and pickup.SubType == 1 and not pickup:GetData()["IsInRoom"] then
		pickup:Remove()
	end
end
chestmod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, chestmod.chestInit)
function chestmod:chestUpdate(pickup)
	if (pickup:GetSprite():IsPlaying("Appear") or pickup:GetSprite():IsPlaying("AppearFast")) and pickup:GetSprite():GetFrame() == 1 and Game():GetRoom():GetType() ~= 11 and Game():GetLevel():GetStage() ~= 11 and not pickup:GetData().nomorph then
		if pickup.Variant == PickupVariant.PICKUP_LOCKEDCHEST and math.random(100) <= 1 then
			pickup:Morph(5, EEE_CHEST, 0, true, true, false) 
			SFXManager():Play(21, 1, 2, false, 1, 0)
		elseif pickup.Variant == PickupVariant.PICKUP_REDCHEST and math.random(100) <= 25 then
			pickup:Morph(5, EEE_CHEST, 0, true, true, false) 
			SFXManager():Play(21, 1, 2, false, 1, 0)
		end
	end
end
chestmod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, chestmod.chestUpdate)

local SimMarks = {
    [CompletionType.MOMS_HEART] = nil,
    [CompletionType.ISAAC] = nil,
    [CompletionType.SATAN] = nil,
    [CompletionType.BOSS_RUSH] = nil,
    [CompletionType.BLUE_BABY] = nil,
    [CompletionType.LAMB] = Isaac.GetAchievementIdByName("RubyChest"),
    [CompletionType.MEGA_SATAN] = nil,
    [CompletionType.ULTRA_GREED] = nil,
    [CompletionType.ULTRA_GREEDIER] = nil,
    [CompletionType.DELIRIUM] = nil,
    [CompletionType.MOTHER] = nil,
    [CompletionType.BEAST] = nil,
    [CompletionType.HUSH] = nil}

RepMMod:AddCallback(ModCallbacks.MC_PRE_COMPLETION_EVENT, function(_, mark)
    local playerCount = game:GetNumPlayers()
    
    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)
        if player:GetPlayerType() == Isaac.GetPlayerTypeByName("Sim", false) and not player.Parent then
            if SimMarks[mark] then
                PersistentGameData:TryUnlock(SimMarks[mark])
			end
        end
	end
end)

RepMMod:AddCallback(ModCallbacks.MC_PRE_COMPLETION_EVENT, function(_, mark)
    local playerCount = game:GetNumPlayers()
    
    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)
        if player:GetPlayerType() == Isaac.GetPlayerTypeByName("Sim", false) and not player.Parent then
            if SimMarks[mark] then
                PersistentGameData:TryUnlock(SimMarks[mark])
			end
        end
	end
end)

RepMMod:AddCallback(ModCallbacks.MC_USE_CARD, function(_, _, player, flags)
	local CRI = game:GetLevel():GetCurrentRoomIndex()
	local Dirt = player:GetMovementDirection()
	local NewDirt
	if Dirt == 0 then
		NewDirt = CRI - 2
		if game:GetLevel():GetRoomByIdx(NewDirt, -1).Data == nil then
			NewDirt = CRI - 1
		end
	elseif Dirt == 1 then
		NewDirt = CRI - 26
		if game:GetLevel():GetRoomByIdx(NewDirt, -1).Data == nil then
			NewDirt = CRI - 13
		end
	elseif Dirt == 2 then
		NewDirt = CRI + 2
		if game:GetLevel():GetRoomByIdx(NewDirt, -1).Data == nil then
			NewDirt = CRI + 1
		end
	elseif Dirt == 3 then
		NewDirt = CRI + 26
		if game:GetLevel():GetRoomByIdx(NewDirt, -1).Data == nil then
			NewDirt = CRI + 13
		end
	end
	if Dirt == -1 then
		player:AddCard(Isaac.GetCardIdByName("HammerCard"))
	else
		print(Dirt)
		if game:GetLevel():GetRoomByIdx(NewDirt, -1).Data ~= nil then
			
			game:StartRoomTransition(NewDirt, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player, -1)
			if player:HasCollectible(451) then
				if math.random(1,10) <= 2 then
					player:AddCard(Isaac.GetCardIdByName("HammerCard"))
				end
			else
				if math.random(1,10) == 1 then
					player:AddCard(Isaac.GetCardIdByName("HammerCard"))
				end
			end
		else
			player:AddCard(Isaac.GetCardIdByName("HammerCard"))
		end
	end
	
end, Isaac.GetCardIdByName("HammerCard"))

local Immune = false
local Heal = false
RepMMod:AddCallback(ModCallbacks.MC_USE_PILL, function(_, _, player, flags)
	Immune = true
	if player:HasFullHearts() then
		Isaac.Spawn(5, 10, 1, player.Position, Vector.FromAngle(math.random(360)) * 3, nil)
		Isaac.Spawn(5, 10, 1, player.Position, Vector.FromAngle(math.random(360)) * 3, nil)
		Isaac.Spawn(5, 10, 1, player.Position, Vector.FromAngle(math.random(360)) * 3, nil)
	end
	player:AddHearts(3)
	player:AnimateHappy()
end, Isaac.GetPillEffectByName("Groovy"))
RepMMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, player, amount, DamageFlag)
	player = player:ToPlayer()
	if Immune == true then
		return false
	end
	if player:GetHearts() + player:ToPlayer():GetBlackHearts() + player:GetBoneHearts() + player:GetSoulHearts() + player:GetRottenHearts() <= amount and player:HasCollectible(Isaac.GetItemIdByName("Angel Spirit"), true) then
		game:ShakeScreen(50)
		Heal = true
		player:UseActiveItem(58, false, false, true, false, -1, 0)
		local PD = player.Damage
		player.Damage = player.Damage + 3
		Isaac.CreateTimer(function() player.Damage = player.Damage - 0.5 end, 30, 6, true)
		Isaac.CreateTimer(function() player.Damage = PD end, 180, 1, true)
		player:RemoveCollectible(Isaac.GetItemIdByName("Angel Spirit"))
		return false
	end
end, EntityType.ENTITY_PLAYER)
RepMMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	Immune = false
end)
RepMMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	if Heal == true then
		Heal = false
		print(game:GetPlayer(0):GetMaxHearts() )
		if game:GetPlayer(0):GetMaxHearts() >= 1 then
			game:GetPlayer(0):AddHearts(20)
		else
			game:GetPlayer(0):AddBlackHearts(10)
		end
		
	end
end)



--Лечит персонажа на 1,5 сердца и даёт неуязвимость до конца комнаты можешь отсебячины сделать, по типу добавления звуков или поменя тьцвет персонажа на белый к примеру 


if CEMod then
end