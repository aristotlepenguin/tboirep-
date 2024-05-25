local mod = RepMMod
local game = Game()
local sfx = SFXManager()
local rng = RNG()

mod.HEART_ICE = 1022

local HeartKey = {
    [mod.HEART_ICE] = "HEART_ICE"
}

local HeartPickupSound = {
    [mod.HEART_ICE] = SoundEffect.SOUND_FREEZE
}

local HeartNumFlies = {
    [mod.HEART_ICE] = 4
}

local iceHeartEntity = 1022



--------------------
-- HEART REPLACEMENT
--------------------
--------------------------------------------------------
-- PREVENT MORPHING HEARTS TO THEIR TAINTED COUNTERPARTS
-- WHEN USING SPECIFIC CARDS AND ITEMS
-- OR WHEN IN SPECIFIC ROOMS

local SusCards = {
    Card.CARD_LOVERS,
    Card.CARD_HIEROPHANT,
    Card.CARD_REVERSE_HIEROPHANT,
    Card.CARD_QUEEN_OF_HEARTS,
    Card.CARD_REVERSE_FOOL
}

local function isSusCard(thisCard)
    for _, card in pairs(SusCards) do
        if card == thisCard then
            return true
        end
    end

    return false
end

local function cancelTaintedMorph()
    local h = Isaac.FindByType(5, 10)

    for _, heart in pairs(h) do
        if heart.FrameCount == 0 then
            heart:GetData().noTaintedMorph = true
        end
    end
end

mod:AddCallback(ModCallbacks.MC_USE_CARD, function(_, card, _, _)
    if isSusCard(card) then
        cancelTaintedMorph()
    end
end)

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, _, _, _)
    cancelTaintedMorph()
end, CollectibleType.COLLECTIBLE_THE_JAR)

mod:AddCallback(ModCallbacks.MC_USE_PILL, function(_, _)
    cancelTaintedMorph()
end, PillEffect.PILLEFFECT_HEMATEMESIS)



------------------------------------------------
-- HANDLE DUPLICATING HEARTS WITH JERA, DIPLOPIA
-- OR CROOKED PENNY, TO MAKE SURE THAT ALL 
-- ORIGINAL HEARTS ARE COPIED 1:1

local function handleHeartsDupe()
    -- iterate through all pickups that have FrameCount of 0 (they've just spawned)
    -- find an older pickup with the same InitSeed
    -- assign its subtype to the newer pickup's subtype
    local h = Isaac.FindByType(5, 10)

    for _, newHeart in pairs(h) do
        if newHeart.FrameCount == 0 then
           for _, oldHeart in pairs(h) do
                if oldHeart.FrameCount > 0
                and newHeart.InitSeed == oldHeart.InitSeed then
                    newHeart:GetData().noTaintedMorph = true
                end
           end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, _, _, _)
    handleHeartsDupe()
end, CollectibleType.COLLECTIBLE_DIPLOPIA)

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, _, _, _)
    handleHeartsDupe()
end, CollectibleType.COLLECTIBLE_CROOKED_PENNY)

mod:AddCallback(ModCallbacks.MC_USE_CARD, function(_, _, _)
    handleHeartsDupe()
end, Card.RUNE_JERA)

-------
-- CORE

local function taintedMorph(heartPickup, taintedSubtype)
	heartPickup:Morph(5, 10, taintedSubtype, true, true, true)
end



local FrozenHeartsAchId = Isaac.GetAchievementIdByName("FrozenHearts")
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function(_, pickup)
    if not pickup:GetData().noTaintedMorph
        and pickup.Price == 0 and game:GetRoom():GetType() ~= RoomType.ROOM_SUPERSECRET
        and (pickup:GetSprite():IsPlaying("Appear") or pickup:GetSprite():IsPlaying("AppearFast"))
        -- BE WARNED THAT FRAMECOUNT == 1 IS NOT SPRITE:GETFRAME() == 1, SPRITE FRAME IS ACTUALLY 1 HIGHER THAN THE NORMAL FRAME
        -- and I don't even know whom to blame for that
        and pickup.FrameCount == 1
    then
        local isTaintFrost = false
        mod:AnyPlayerDo(function(player)
            if player:GetPlayerType() == mod.RepmTypes.CHARACTER_FROSTY_B then
                isTaintFrost = true
            end
        end)
        rng:SetSeed(pickup.InitSeed + Random(), 1)
        local roll = rng:RandomFloat() * 1000
        local subtype = pickup.SubType
        local baseChance
        if subtype == HeartSubType.HEART_SOUL and Isaac.GetPersistentGameData():Unlocked(FrozenHeartsAchId) then
            baseChance = 200
            if roll < baseChance then
                taintedMorph(pickup, mod.HEART_ICE)
            end
        elseif (subtype == HeartSubType.HEART_SOUL or subtype == HeartSubType.HEART_FULL or subtype == HeartSubType.HEART_DOUBLEPACK or subtype == HeartSubType.HEART_SCARED or subtype == HeartSubType.HEART_HALF) and Isaac.GetPersistentGameData():Unlocked(FrozenHeartsAchId) and isTaintFrost then
            baseChance = 200
            if roll < baseChance or subtype == HeartSubType.HEART_SOUL then
                taintedMorph(pickup, mod.HEART_ICE)
            end
        end
    end
end, PickupVariant.PICKUP_HEART)



--------------------
-- REGISTERING HEARTS
---------------------

CustomHealthAPI.Library.RegisterSoulHealth(
    "HEART_ICE",
    {
        AnimationFilename = "gfx/ui/CustomHealthAPI/ui_icehearts.anm2",
        AnimationName = {"IceHeartHalf", "IceHeartFull"},

        SortOrder = 200,
        AddPriority = 225,
        HealFlashRO = 50/255,
        HealFlashGO = 70/255,
        HealFlashBO = 90/255,
        MaxHP = 2,
        PrioritizeHealing = true,
        PickupEntities = {
            {ID = EntityType.ENTITY_PICKUP, Var = PickupVariant.PICKUP_HEART, Sub = iceHeartEntity}
        },
        SumptoriumSubType = 210,
        SumptoriumSplatColor = Color(1.00, 1.00, 1.00, 1.00, 0.00, 0.00, 0.00),
        SumptoriumTrailColor = Color(1.00, 1.00, 1.00, 1.00, 0.00, 0.00, 0.00),
        SumptoriumCollectSoundSettings = {
            ID = SoundEffect.SOUND_ROTTEN_HEART,
            Volume = 1.0,
            FrameDelay = 0,
            Loop = false,
            Pitch = 1.0,
            Pan = 0
        }
    }
)
local dupesOff = false
CustomHealthAPI.Library.AddCallback("RepentanceMinus", CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED, 0, function(player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
    if key == "HEART_ICE" then
        local pdata = mod:repmGetPData(player)
        pdata.isIceheartCrept = true
        for i=0, 360, 45 do
            local angle = Vector.FromAngle(i) * 8
            local tear = player:FireTear(player.Position, angle, false, true, false, player, 1)
            --tear:ClearTearFlags()
            tear.TearFlags = BitSet128(0,0)
            tear:AddTearFlags(TearFlags.TEAR_ICE)
            tear:ChangeVariant(41)
        end
    end
end)


--------------------------------------------------------------------

-------------
-- SUMPTORIUM
-------------
mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(_, Tear)
	if Tear.SpawnerEntity and Tear.SpawnerEntity.Type == EntityType.ENTITY_PLAYER then
		local familiars = Isaac.FindInRadius(Tear.Position - Tear.Velocity, 0.0001, EntityPartition.FAMILIAR)

		for _, familiar in ipairs(familiars) do
			if familiar.Variant == FamiliarVariant.BLOOD_BABY then
				--if familiar.SubType == mod.CustomFamiliars.ClotSubtype.DAUNTLESS then
               --     Tear:GetData().isDauntlessClot = true
                --end
			end
		end
	elseif Tear.SpawnerEntity and Tear.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR then
		local familiar = Tear.SpawnerEntity:ToFamiliar()
		if familiar.Variant == FamiliarVariant.BLOOD_BABY then
			--if familiar.SubType == mod.CustomFamiliars.ClotSubtype.DAUNTLESS then
            --    Tear:GetData().isDauntlessClot = true
            --end
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, Tear)
    if Tear.FrameCount ~= 1 then return end


end)

--------------------
-- PICKING HEARTS UP
-- HEARTS UPDATE
--------------------
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function(_, pickup)
    if pickup.SubType < 84 or pickup.SubType > 100 then return end

	local sprite = pickup:GetSprite()
	if sprite:IsFinished("Appear") then
		sprite:Play("Idle", false)
	end
	if sprite:IsPlaying("Collect") and sprite:GetFrame() > 5 then
		pickup:Remove()
	end
end, PickupVariant.PICKUP_HEART)

---@param pickup EntityPickup
---@param collider EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, function(_, pickup, collider)
    --print(pickup.SubType)
    if (pickup.SubType ~= iceHeartEntity) and pickup.SubType ~= HeartSubType.HEART_GOLDEN then return end
    if collider.Type ~= EntityType.ENTITY_PLAYER then return end
    local collider = collider:ToPlayer()
    local bowMultiplier = collider:HasCollectible(CollectibleType.COLLECTIBLE_MAGGYS_BOW) and 2 or 1
	local hasApple = collider:HasTrinket(TrinketType.TRINKET_APPLE_OF_SODOM)
    local sprite = pickup:GetSprite()

    if pickup:IsShopItem() and (pickup.Price > collider:GetNumCoins() or not collider:IsExtraAnimationFinished()) then
        return true
    elseif sprite:IsPlaying("Collect") then
        return true
    elseif pickup.Wait > 0 then
        return not sprite:IsPlaying("Idle")
    elseif sprite:WasEventTriggered("DropSound") or sprite:IsPlaying("Idle") then
        if pickup.Price == PickupPrice.PRICE_SPIKES then
            local tookDamage = collider:TakeDamage(2.0, 268435584, EntityRef(nil), 30)
            if not tookDamage then
                return pickup:IsShopItem()
            end
        end

        -- SOUL HEALTH
        if CustomHealthAPI.Library.CanPickKey(collider, HeartKey[pickup.SubType]) then
            CustomHealthAPI.Library.AddHealth(collider, HeartKey[pickup.SubType], 2, true)
            sfx:Play(HeartPickupSound[pickup.SubType], 1, 0, false, 1.0)
            if collider:ToPlayer():HasCollectible(mod.RepmTypes.Collectible_HOLY_LIGHTER) then
                collider:ToPlayer():SetActiveCharge(math.min(12, collider:ToPlayer():GetActiveCharge(ActiveSlot.SLOT_POCKET)+2), ActiveSlot.SLOT_POCKET)
                sfx:Play(SoundEffect.SOUND_BATTERYCHARGE)
            end
        else
            return pickup:IsShopItem()
        end

        if pickup.OptionsPickupIndex ~= 0 then
            for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP)) do
                if entity:ToPickup().OptionsPickupIndex == pickup.OptionsPickupIndex and
                (entity.Index ~= pickup.Index or entity.InitSeed ~= pickup.InitSeed) then
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil)
                    entity:Remove()
                end
            end
        end

        if pickup:IsShopItem() then
            local pickupSprite = pickup:GetSprite()
            local holdSprite = Sprite()

            holdSprite:Load(pickupSprite:GetFilename(), true)
            holdSprite:Play(pickupSprite:GetAnimation(), true)
            holdSprite:SetFrame(pickupSprite:GetFrame())
            collider:AnimatePickup(holdSprite)

            if pickup.Price > 0 then
                collider:AddCoins(-1 * pickup.Price)
            end

            CustomHealthAPI.Library.TriggerRestock(pickup)
            CustomHealthAPI.Helper.TryRemoveStoreCredit(collider)

            pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            pickup:Remove()
        else
            sprite:Play("Collect", true)
            pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            pickup:Die()
        end

        game:GetLevel():SetHeartPicked()
        game:ClearStagesWithoutHeartsPicked()
        game:SetStateFlag(GameStateFlag.STATE_HEART_BOMB_COIN_PICKED, true)

        return true
    else
        return false
    end
end, PickupVariant.PICKUP_HEART)


local frostType = Isaac.GetPlayerTypeByName("Frosty", false)

local DeathCardAchId = Isaac.GetAchievementIdByName("FrostySatan")

function mod:onFrostyInit(player)
    if player:GetPlayerType() == frostType then
        player:AddSoulHearts(-1)
        CustomHealthAPI.Library.AddHealth(player, HeartKey[mod.HEART_ICE], 6, true)
        if Isaac.GetPersistentGameData():Unlocked(DeathCardAchId) then
            player:AddCard(Card.CARD_DEATH)
        end
    end
    if player:GetPlayerType() == mod.RepmTypes.CHARACTER_FROSTY_B then
        player:AddSoulHearts(-1)
        CustomHealthAPI.Library.AddHealth(player, HeartKey[mod.HEART_ICE], 8, true)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.onFrostyInit)

local numbHeartItem = Isaac.GetItemIdByName("Numb Heart")
function mod:onUseNumbHeart(collectible, thisRng, player, useflags, activeslot, customvardata)
    CustomHealthAPI.Library.AddHealth(player, HeartKey[mod.HEART_ICE], 2, true)
    sfx:Play(SoundEffect.SOUND_FREEZE, 1, 0, false, 1.0)
    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.onUseNumbHeart, numbHeartItem)



local frozenFood = Isaac.GetItemIdByName("Frozen Food")
function mod:OnGainFrozenFood(_, _, _, _, _, player)
    CustomHealthAPI.Library.AddHealth(player, HeartKey[mod.HEART_ICE], 2, true)
end
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, mod.OnGainFrozenFood, frozenFood)

