 --[[Итак мамкины программисты, кто решил залесть в код мода, то не удивляйтесь его странному оформлению и как он странно написан. 
    Если кто-то шарит за код, то это мой первый опыт]] 
--[[So mom’s programmers, who decided to get into the mod’s code, don’t be surprised at its strange design and how strangely it is written.
    If anyone is looking for code, this is my first experience]]

local mod = RegisterMod("tboirep-", 1.0)
RepMMod = mod
local json = require("json")
local game = Game()
local version = ": 0.7a" --added by me (pedro), for making updating version number easier
print("Thanks for playing the TBOI REP NEGATIVE [Community Mod] - Currently running version"..tostring(version))
local saveTable = {}
local globalRng = RNG()

include("lua/lib/customhealthapi/core.lua")
include("lua/lib/customhealth.lua")

local hiddenItemManager = require("lua.lib.hidden_item_manager")
hiddenItemManager:Init(mod)


function mod.GetMenuSaveData()
    if not mod.MenuData then
        if mod:HasData() then
            mod.MenuData = json.decode(mod:LoadData()).MenuData or {}
        else
            mod.MenuData = {}
        end
    end
    return mod.MenuData
end

function mod.StoreSaveData()
    saveTable.MenuData = mod.MenuData
end

function mod:getPlayerFromKnifeLaser(entity)
	if entity.SpawnerEntity and entity.SpawnerEntity:ToPlayer() then
		return entity.SpawnerEntity:ToPlayer()
	elseif entity.SpawnerEntity and entity.SpawnerEntity:ToFamiliar() and entity.SpawnerEntity:ToFamiliar().Player then
		local familiar = entity.SpawnerEntity:ToFamiliar()

		if familiar.Variant == FamiliarVariant.INCUBUS or familiar.Variant == FamiliarVariant.SPRINKLER or
		   familiar.Variant == FamiliarVariant.TWISTED_BABY or familiar.Variant == FamiliarVariant.BLOOD_BABY or
		   familiar.Variant == FamiliarVariant.UMBILICAL_BABY or familiar.Variant == FamiliarVariant.CAINS_OTHER_EYE
		then
			return familiar.Player
		else
			return nil
		end
	else
		return nil
	end
end

local DSSInitializerFunction = include("lua.lib.DSSMenu")
DSSInitializerFunction(mod)

local activeItems = {}

Items = {
ID_Anm = Isaac.GetItemIdByName("book of tails"),
ID_ALLStatsItem = Isaac.GetItemIdByName("Salami"),
COLLECTIBLE_DONKEY_JAWBONE = Isaac.GetItemIdByName("Sim axe")
}

mod.COLLECTIBLE_TECHL = Isaac.GetItemIdByName("PRObackstabber")


mod.LIGHTNING_EFFECT = Isaac.GetEntityTypeByName("Lightning")


mod.LIGHTNING_VARIANT = Isaac.GetEntityVariantByName("2643")


mod.SFX_LIGHTNING = Isaac.GetSoundIdByName("Thunder")





--When run begins
function mod:onGameStart(fromSave)
	if not fromSave then
		if SpawnAtStart == true then
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
			mod.COLLECTIBLE_TECHL, Vector(320,280), Vector(0,0), nil
			)
		end
		
	end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)

--When enemy gets hit by a tear
function mod:entityTakeDMG(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownframes)
	local player = Isaac.GetPlayer(0)
	local entity = tookDamage
		if player:HasCollectible(mod.COLLECTIBLE_TECHL)
		and damageSource.Type == EntityType.ENTITY_TEAR and entity:IsVulnerableEnemy() then
		--Process begins
			local data = entity:GetData()	
				if data.TechLHits == nil then
					data.TechLHits = 0
				else
					data.TechLHits = data.TechLHits + 1
					if data.TechLHits == 5  then --At 5 shots
					--local NearPosition = Isaac.GetFreeNearPosition(entity.Position, 50)
					
						Isaac.Spawn(EntityType.ENTITY_EFFECT, 2643, mod.LIGHTNING_EFFECT,
						entity.Position, Vector(0,0), player) --Lightning spawns
						
						local FireEff = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0,
						entity.Position, Vector(0,0), player) --Spawns fire
						FireEff.CollisionDamage = 0.35
						
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_CRATER, 0,
						entity.Position, Vector(0,0), player) --Create bomb crater effect
						
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CROSS_POOF, 0,
						entity.Position, Vector(0,0), player) --Blue circle effect
						
						sound:Play(mod.SFX_LIGHTNING, 1, 0, false, 0.6) --Lightning Sound
						--Reset Hits counter
						data.TechLHits = 0
			
						--Deals damage
						entity:TakeDamage(player.Damage * 4, 1, damageSource, 0)
						entity:AddBurn(damageSource, 120, player.Damage / 5)
						
						
					end		
				end
		end	
		
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.entityTakeDMG, EntityPartition.ENTITY_ENEMY)


function mod:removeLightning(EntityNPC) --Remove the lightning
	local Lightning = EntityNPC
	if Lightning:GetSprite():IsEventTriggered("End") then
		Lightning:GetSprite():Remove()
		Lightning:Remove()
	end
end

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.removeLightning, EntityType.ENTITY_EFFECT, 2643, mod.LIGHTNING_EFFECT)

function mod:fireNoCollide(EntityEffect)
	local player = Isaac.GetPlayer(0)
	if player:HasCollectible(mod.COLLECTIBLE_TECHL) then
		Isaac.DebugString("BOMBfire")
		--Don't collide fire with tears (probably does nothing)
		EntityEffect.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.fireNoCollide, EffectVariant.HOT_BOMB_FIRE)

--Add glowing tears
function mod:glowingTears()
	local player = Isaac.GetPlayer(0)
	if player:HasCollectible(mod.COLLECTIBLE_TECHL) then
		game:GetSeeds():AddSeedEffect(SeedEffect.SEED_GLOWING_TEARS)
	end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.glowingTears)


local bigRedButton = Isaac.GetItemIdByName("PROkamikadze")

function mod:RedButtonUse(item)
    local roomEntities = Isaac.GetRoomEntities()
    for _, entity in ipairs(roomEntities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            local p = Isaac.GetPlayer(0)
    
    for i=1, math.random(3,5) do
      local flame = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RED_CANDLE_FLAME, 0, p.Position, Vector(math.random(-10, 10), math.random(-10, 10)), p)
      flame.CollisionDamage = 5
    end
        end
    end

    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, bigRedButton)



mod.COLLECTIBLE_LOST_SHROOM = Isaac.GetItemIdByName("Lost shroom")
  
function mod:onUpdate_LostShroom()
    --begin run
    if game:GetFrameCount() == 1 then
        mod.HasLostShroom = false
	end
 	
    -- shroom     
	for playerNum = 1,  game:GetNumPlayers() do 
        local player = game:GetPlayer(playerNum)
		if player:HasCollectible(mod.COLLECTIBLE_LOST_SHROOM) then
		    if not mod.HasLostShroom then -- pickup
			    player:AddSoulHearts(2)
				mod.HasLostShroom = true 
		    end
		
            for i, entity in pairs(Isaac.GetRoomEntities()) do
                if entity:IsVulnerableEnemy() and math.random(80) == 1 then 
				    entity:AddPoison(EntityRef(player), 10, 2.1)
				end 
            end 			
		end 
    end 	

end 

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.onUpdate_LostShroom)

function mod:updateCache_AllStats(_player, cacheFlag)
    local player = Isaac.GetPlayer(0)
	
	if cacheFlag == CacheFlag.CACHE_DAMAGE then
	    if player:HasCollectible(Items.ID_ALLStatsItem) then 
		    player.Damage = player.Damage +0.5
		end
	end	
    if cacheFlag == CacheFlag.CACHE_LUCK then
	    if player:HasCollectible(Items.ID_ALLStatsItem) then 
		    player.Luck = player.Luck +0.5
		end
	end	
	if cacheFlag == CacheFlag.CACHE_SPEED then
	    if player:HasCollectible(Items.ID_ALLStatsItem) then 
		    player.MoveSpeed = player.MoveSpeed +0.5
		end
	end
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
	    if player:HasCollectible(Items.ID_ALLStatsItem) then 
		    player.MaxFireDelay = player.MaxFireDelay -1;
		end
	end
    if cacheFlag == CacheFlag.CACHE_RANGE then
	    if player:HasCollectible(Items.ID_ALLStatsItem) then 
		    player.TearRange = player.TearRange + 40 * 0.5;
		end
	end	
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_AllStats)



mod.COLLECTIBLE_DONKEY_JAWBONE = Isaac.GetItemIdByName("Sim axe")

local DJdesc = "Upon taking damage, this item causes you do a spin attack, dealing damage to nearby enemies and blocking projectiles for a short while"
local Wiki = {
  DonkeyJawbone = {
    { -- Effect
      {str = "Effect", fsize = 2, clr = 3, halign = 0},
      {str = "When Isaac takes damage, a spin attack will damage enemies around him, doing his current damage with a multiplier."},
      {str = " - The spin attack blocks projectiles."},
      {str = " - When an enemy is killed with the spin attack, it has a chance to drop a red heart on the floor."},
    },
	{ -- Notes
      {str = "Interactions", fsize = 2, clr = 3, halign = 0},
      {str = "20/20: Grants 1 additional spin."},
	  {str = "Ipecac: Spin attack poisons enemies."},
	  {str = "Mutant Spider: Grants 3 additional spins."},
	  {str = "The Inner Eye: Grants 2 additional spins."},
	  {str = "Head of the Keeper: Enemies killed by the spin attack drop coins"},
	  {str = "Holy Light: Spin attack summons holy light upon enemies hit"},
	  {str = "Uranus: Enemies killed by the spin attack are frozen."},
    },
    { -- Trivia
      {str = "Trivia", fsize = 2, clr = 3, halign = 0},
	  {str = "This item is a reference to a passage from the Book of Judges in which Samson kills one thousand Philistines using only the jawbone of a donkey."},
      {str = "This item originated from the Binding of Isaac: Community Remix mod, being known as 'the sword' before release."},
      {str = " - In the Binding of Isaac: Community Remix, this item was similar to Mom's Pocket Techology. It was changed to the way it is now due to Samson's changes in Rebirth."},    
      {str = "Donkey Jawbone was one of the few items not imported into Repentance, alongside Book Of Despair, Bowl of Tears, Pocket Techology Piece 3, Menorah, Stone Bombs, and Voodoo Pin. It was replaced by Bloody Gust. However, its sprite was implemented as the weapon used by Tainted Samson."},	
	},
  }
}



if Encyclopedia then
	Encyclopedia.AddItem({
	  ID = CollectibleType.COLLECTIBLE_DONKEY_JAWBONE,
	  WikiDesc = Wiki.DonkeyJawbone,
	  Pools = {
		Encyclopedia.ItemPools.POOL_TREASURE,
		Encyclopedia.ItemPools.POOL_GREED_TREASURE,
	  },
	})
end

local function TEARFLAG(x)
	return x >= 64 and BitSet128(0,1<<(x - 64)) or BitSet128(1<<x,0)
end

ExtraSpins = 0

function mod:PostNewRoom()
	ExtraSpins = 0 -- just in case it gets interrupted
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.PostNewRoom)

function mod:PlayerHurt(TookDamage, DamageAmount, DamageFlags, DamageSource, DamageCountdownFrames)
	local player = TookDamage:ToPlayer()
	if player:HasCollectible(mod.COLLECTIBLE_DONKEY_JAWBONE) then
		if player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then
			ExtraSpins = ExtraSpins + 1
		end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) then
			ExtraSpins = ExtraSpins + 2
		end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then
			ExtraSpins = ExtraSpins + 3
		end
		
		mod:SpawnJawbone(player)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.PlayerHurt, EntityType.ENTITY_PLAYER)


function mod:JawboneUpdate(jawbone)
	local player = jawbone.Parent:ToPlayer()
	local sprite = jawbone:GetSprite()
	if sprite:IsPlaying("SpinLeft") or sprite:IsPlaying("SpinUp") or sprite:IsPlaying("SpinRight") or sprite:IsPlaying("SpinDown") then
		jawbone.Position = player.Position
		SFXManager():Stop(SoundEffect.SOUND_TEARS_FIRE)
	else
		jawbone:Remove()
		if ExtraSpins > 0 then
			mod:SpawnJawbone(player)
			ExtraSpins = ExtraSpins - 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.JawboneUpdate, 1001)

function mod:MeatySound(entityTear, collider, low)
	if collider:IsActiveEnemy(true) then
		SFXManager():Play(SoundEffect.SOUND_MEATY_DEATHS)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, mod.MeatySound, 1001)

function mod:SpawnJawbone(player)
	local jawbone = Isaac.Spawn(2, 1001, 0, player.Position, Vector.Zero, player):ToTear()
	
	jawbone.Parent = player
	jawbone.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
	jawbone.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
	jawbone.CollisionDamage = (player.Damage * 3) + 10
	jawbone:AddTearFlags(TEARFLAG(1) | TEARFLAG(2) | TEARFLAG(34)) --piercing, spectral, shielding, and hp drop
	if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then
		jawbone:AddTearFlags(TEARFLAG(4)) -- poison
	end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_URANUS) then
		jawbone:AddTearFlags(TEARFLAG(65)) -- ice
	end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT) then
		jawbone:AddTearFlags(TEARFLAG(39)) -- holy light
	end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER) then
		jawbone:AddTearFlags(TEARFLAG(74)) -- coin drop
	end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_BAG) then
		if math.random(1, 7) == 6 then
		jawbone:AddTearFlags(TEARFLAG(15))
	end	
end 
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BLOODY_LUST) then
		if math.random(1, 8) == 8 then
		jawbone:AddTearFlags(TEARFLAG(15))
	end	
end 	
    if player:HasCollectible(CollectibleType.COLLECTIBLE_IMMACULATE_HEART) then
		if math.random(1, 4) == 2 then
		jawbone:AddTearFlags(TEARFLAG(15))
	end	
end 	
    
	local sprite = jawbone:GetSprite()
	local headDirection = player:GetHeadDirection()
	if player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) or player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) or player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then
		sprite.PlaybackSpeed = 2
	end
	
	if headDirection == Direction.LEFT then
		sprite:Play("SpinLeft", true)
	elseif headDirection == Direction.UP then
		sprite:Play("SpinUp", true)
	elseif headDirection == Direction.RIGHT then
		sprite:Play("SpinRight", true)
	elseif headDirection == Direction.DOWN then
		sprite:Play("SpinDown", true)
	end
	
	SFXManager():Play(SoundEffect.SOUND_SWORD_SPIN)
end


local SimType = Isaac.GetPlayerTypeByName("Sim", false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/sim_hair.anm2") -- Exact path, with the "resources" folder as the root

function mod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= SimType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    player:AddNullCostume(hairCostume)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.GiveCostumesOnInit)
local Sim = { -- Change Sim everywhere to match your character. No spaces!
    DAMAGE = 1, -- These are all relative to Isaac's base stats.
    SPEED = 0.3,
    SHOTSPEED = -1,
    TEARHEIGHT = 2,
    TEARFALLINGSPEED = 0,
    LUCK = 4,
    FLYING = false,                                  
    TEARFLAG = 0, -- 0 is default
    TEARCOLOR = Color(1.0, 1.0, 1.0, 1.0, 0, 0, 0)  -- Color(1.0, 1.0, 1.0, 1.0, 0, 0, 0) is default
}
 
function Sim:onCache(player, cacheFlag) -- I do mean everywhere!
    if player:GetName() == "Sim" then -- Especially here!
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + Sim.DAMAGE
        end
        if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + Sim.SHOTSPEED
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            player.TearHeight = player.TearHeight - Sim.TEARHEIGHT
            player.TearFallingSpeed = player.TearFallingSpeed + Sim.TEARFALLINGSPEED
        end
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + Sim.SPEED
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + Sim.LUCK
        end
        if cacheFlag == CacheFlag.CACHE_FLYING and Sim.FLYING then
            player.CanFly = true
        end
        if cacheFlag == CacheFlag.CACHE_TEARFLAG then
            player.TearFlags = player.TearFlags | Sim.TEARFLAG
        end
        --if cacheFlag == CacheFlag.CACHE_TEARCOLOR then
            --player.TearColor = Sim.TEARCOLOR
        --end
    end
end
 
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Sim.onCache)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
  if player:GetPlayerType() == SimType then 
    player:SetPocketActiveItem(32, 2, true)
    player:AddCollectible(Items.COLLECTIBLE_DONKEY_JAWBONE)
  end
end)


CollectibleType.BOOK_OF_TAILS = Isaac.GetItemIdByName("book of tails")

function mod:onBookOfTails(_, rng)           -- сбив сделки при получении урона
	local room = game:GetRoom()
	local player = Isaac.GetPlayer(0)

	for i = 1, 8 do
		local door = room:GetDoor(i)
		if door and
		   (door.TargetRoomType == RoomType.ROOM_DEVIL or
			door.TargetRoomType == RoomType.ROOM_ANGEL)
		then
			room:RemoveDoor(i)
		end
	end

	game:GetLevel():SetRedHeartDamage()                               
	room:SetRedHeartDamage()
	local gridIndex = room:GetGridIndex(player.Position)
	room:SpawnGridEntity(gridIndex, GridEntityType.GRID_STAIRS, 0, 0, 0)

end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.onBookOfTails, CollectibleType.BOOK_OF_TAILS)

function mod:onRoom()                                                         -- спавн ретро-сокровещницы 
	local player = Isaac.GetPlayer(0)
	if player:GetActiveItem() == CollectibleType.BOOK_OF_TAILS then
		local room = game:GetRoom()
		if room:GetType() == RoomType.ROOM_DUNGEON then
			for i = 1, room:GetGridSize() do
				local gridEntity = room:GetGridEntity(i)
				if 	gridEntity and
					gridEntity.Desc.Type == GridEntityType.GRID_WALL and
					(i == 58 or
					 i == 59 or
					 i == 73 or
					 i == 74)
				then
					gridEntity:SetType(GridEntityType.GRID_GRAVITY)
				end
			end
			if room:IsFirstVisit() then
				local level = game:GetLevel()
				level:ChangeRoom(level:GetCurrentRoomIndex())
			end
		elseif room:GetType() == RoomType.ROOM_DEVIL or
			room:GetType() == RoomType.ROOM_ANGEL
		then
			player:DischargeActiveItem()
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onRoom)




local BeastConsts = {
    COLLECTIBLE = Isaac.GetItemIdByName("Big Brim"),
    VARIANT = Isaac.GetEntityVariantByName("Little Beast"),
    FIRE_DELAY = 20, -- Delay between fire spawns
    CHARGE_NEEDED = 10, -- Fires eaten until laser blast
    LASER_DAMAGE = 120,
    SHOT_SPEED = 10, -- Fire movement speed
    MOVE_SPEED = 4, -- Movement to center room speed
    SHOT_DISTANCE = 250, -- How far behind an enemy the fire will spawn
    CENTER_GRACE = 2, -- The radius of which the beast considers room center
}

local familiarRNG = RNG()
local level
local sfx = SFXManager()


if AltarFix and not AltarFix.AllowedVariants then
    AltarFix.AllowedVariants = {}
    AltarFix.AllowedVariants[BeastConsts.VARIANT] = BeastConsts.COLLECTIBLE
end

-- Get proper count of Beasts, spawn depending on amount of Beasts held and Box of Friends uses
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local boxOfFriendsTimesUsed = p:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS)
        local validUse = p:HasCollectible(BeastConsts.COLLECTIBLE) and 1 or 0 -- failsafe to only spawn beast from BoF if player has beast
        local count = p:GetCollectibleNum(BeastConsts.COLLECTIBLE) + (boxOfFriendsTimesUsed * validUse)-- calculate beasts to spawn based on amount held and box of friends uses
        local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, BeastConsts.VARIANT, -1, false, false)
        local myFamiliars = {}

        for _, fam in ipairs(familiars) do -- gets all room familiars, filter out ones that don't belong to evaluated player
            if fam.SpawnerEntity.InitSeed == p.InitSeed then -- check if the familiar belongs to the player being evaluated
                myFamiliars[#myFamiliars+1] = fam            -- this has to be done via playerseed because entity userdata is inconsistent and shitty
            end
        end

        if #myFamiliars < count then -- spawn familiars until theres enough
            for i = 1, count - #myFamiliars do
                Isaac.Spawn(EntityType.ENTITY_FAMILIAR, BeastConsts.VARIANT, 0, p.Position, Vector.Zero, p)
            end

        elseif #myFamiliars > count then -- remove familiars until theres enough
            local numRemoved = #myFamiliars - count
            for _, fam in ipairs(myFamiliars) do
                fam:Remove()
                numRemoved = numRemoved - 1
                if numRemoved <= 0 then
                    break
                end
            end
        end
    end
end)

-- Causes Beast to follow
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
    fam:AddToFollowers()
    fam:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
end, BeastConsts.VARIANT)

-- function for finding target enemy, then calculating the angle/position the fire will spawn
function findTargetDirectionAndPosition(pos)
    local entities = Isaac.FindInRadius(pos, 875, EntityPartition.ENEMY)
    local enemies = {}
    local key = 1;
    for i, entity in pairs(entities) do
        if entity:IsVulnerableEnemy() then
            enemies[key] = entities[i]
            key = key + 1;
        end
    end
    local chosenEnt = enemies[familiarRNG:RandomInt(#enemies)+1]
    if chosenEnt ~= nil then
        if chosenEnt.Position ~= nil then
            local targetDir = (pos - chosenEnt.Position):Normalized()
            local targetPos = chosenEnt.Position - (targetDir:Resized(BeastConsts.SHOT_DISTANCE))
            return targetDir, targetPos
        end
    else
        return Vector.Zero, Vector.Zero
    end
end

function isThereEnemies(room) -- function for checking if lil beast should activate or not, since the logic got so damn complicated
    if room:GetAliveEnemiesCount() ~= 0 or room:IsAmbushActive() then
        if not game:IsGreedMode() or not room:IsClear() then
            return "t"
        end
    elseif room:GetAliveEnemiesCount() == 0 and not room:IsAmbushActive() then
        if not game:IsGreedMode() or room:IsClear() then
            return "f"
        end
    end
    return nil
end

-- Beast's familiar update
-- STATES:
-- - STATE_IDLE - following player
-- - STATE_ACTIVE - moving to room center
-- - STATE_SUCK - sucking fires
-- - STATE_FIRE - blasting the big beamo
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
    local data = fam:GetData()
    local sprite = fam:GetSprite()
    local currentRoom = game:GetRoom()
    if fam.FrameCount <= 1 then
        --i dont know how much of this actualyl gets initialzed i dont understand getdata at all ahhhh
        familiarRNG:SetSeed(game:GetSeeds():GetStartSeed(), 35)
        data.State = "STATE_IDLE"
        data.FireDelay = 0 -- tracks time until shoot
        data.FlamesConsumed = 0
        data.TargetPos = Vector.Zero -- Default vectors for flame spawning
        data.TargetDir = Vector.Zero
        data.Flame = nil -- flame projectile spawned by fam
        data.Laser = nil -- laser entity spawned by fam
        data.Bffs = false -- checks if player has certain synergy-causing items
        data.Lullaby = false
        data.Bender = false
    end
    if not data.FlamesConsumed then
        data.FlamesConsumed = 0
    end
    sprite.Color = Color.Lerp(Color(1,1,1,1,0,0,0), Color(1,1,1,1,1,0,0), (2^data.FlamesConsumed)/1500) -- Color changes depending on flames consumed
    if not data.State then
        data.State = "STATE_IDLE"
    end
    if data.State == "STATE_IDLE" then
        fam:FollowParent()
        sprite.FlipX = fam.Velocity.X > 0
        data.FlamesConsumed = 0
        sprite:Play("Idle", false)
        if isThereEnemies(currentRoom) == "t" then
            local dir = (currentRoom:GetCenterPos() - fam.Position):Normalized()
            fam.Velocity = dir * BeastConsts.MOVE_SPEED
            sfx:Play(SoundEffect.SOUND_BEAST_INTRO_SCREAM, 1, 0, false, 1.5)
            data.State = "STATE_ACTIVE"
        end
    end
    if data.State == "STATE_ACTIVE" then
        fam:RemoveFromFollowers()
        sprite.FlipX = fam.Velocity.X > 0
        if math.abs(fam.Position.X - currentRoom:GetCenterPos().X) < BeastConsts.CENTER_GRACE
        and math.abs(fam.Position.Y - currentRoom:GetCenterPos().Y) < BeastConsts.CENTER_GRACE then
            sprite:Play("BeginSuck", false)
            sfx:Play(SoundEffect.SOUND_BEAST_SUCTION_START, 1, 0, false, 1.5)
            data.State = "STATE_SUCK"
        end
        if isThereEnemies(currentRoom) == "f" then
            data.FlamesConsumed = 0
            data.Laser = nil
            data.State = "STATE_SUCK"
        end
    end
    if data.State == "STATE_SUCK" then
        fam.Velocity = Vector.Zero
        if sprite:IsFinished("Shoot_Down") then
            sprite:Play("EndCharge_Down", false)
        end
        if sprite:IsFinished("BeginSuck") or sprite:IsFinished("EndCharge_Down") then
            sprite:Play("Suck", true)
        end
        if isThereEnemies(currentRoom) == "f" then
            fam:AddToFollowers()
            data.State = "STATE_IDLE"
            data.Flame = nil
        end
        if not data.FireDelay then
            data.FireDelay = 0
        end
        data.FireDelay = data.FireDelay - 1
        if data.FireDelay <= 0 and isThereEnemies(currentRoom) == "t" then
            if fam.Player:HasTrinket(TrinketType.TRINKET_FORGOTTEN_LULLABY) then
                data.FireDelay = BeastConsts.FIRE_DELAY / 2
            else
                data.FireDelay = BeastConsts.FIRE_DELAY
            end
            data.TargetDir, data.TargetPos = findTargetDirectionAndPosition(fam.Position)
            data.Flame = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_FIRE, 0, data.TargetPos, data.TargetDir*BeastConsts.SHOT_SPEED, fam)
            data.Flame:ToProjectile():AddProjectileFlags(ProjectileFlags.HIT_ENEMIES | ProjectileFlags.CANT_HIT_PLAYER | ProjectileFlags.NO_WALL_COLLIDE)
            data.Flame:ToProjectile().FallingSpeed = 0
            data.Flame:ToProjectile().FallingAccel = -0.1
        end
        if not data.FlamesConsumed then
            data.FlamesConsumed = 0
        end
        if data.FlamesConsumed >= BeastConsts.CHARGE_NEEDED then
            data.FlamesConsumed = 0
            data.State = "STATE_FIRE"
        end
    end
    if data.State == "STATE_FIRE" then
        if sprite:IsFinished("Charge_Down") then
            sprite:Play("Shoot_Down", true)
        end
        if not sprite:IsPlaying("Charge_Down") and not sprite:IsPlaying("Shoot_Down") then
            sprite:Play("Charge_Down", false)
        end
        if sprite:IsPlaying("Shoot_Down") and sprite:IsEventTriggered("Fire") then
            local laserDir = findTargetDirectionAndPosition(fam.Position)
            sfx:Stop(SoundEffect.SOUND_BLOOD_LASER)
            sfx:Play(SoundEffect.SOUND_BEAST_LASER, 1, 0, false, 1.5)
            game:ShakeScreen(10)
            data.Laser = EntityLaser.ShootAngle(3, fam.Position, (-laserDir):GetAngleDegrees(), 10, Vector(0,-25), fam)
            data.Laser:SetOneHit(true)
            data.Laser.DepthOffset = 9
            if fam.Player:HasTrinket(TrinketType.TRINKET_BABY_BENDER) then
                data.Laser:AddTearFlags(TearFlags.TEAR_HOMING)
            end
            local laserSprite = data.Laser:GetSprite()
            laserSprite:ReplaceSpritesheet(0, "gfx/effects/lilbeast.png")
            laserSprite:LoadGraphics()
            if fam.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
                data.Laser.CollisionDamage = BeastConsts.LASER_DAMAGE * 2
            else
                data.Laser.CollisionDamage = BeastConsts.LASER_DAMAGE
            end
        end
        if (data.Laser) then
            if (data.Laser.FrameCount > 1) then
                local child = data.Laser.Child
                local childSprite = child:GetSprite()
                childSprite:ReplaceSpritesheet(0, "gfx/effects/lilbeastimpact.png")
                childSprite:LoadGraphics()
            end
            if data.Laser.Timeout <= 0 then
                data.FlamesConsumed = 0
                data.Laser = nil
                data.State = "STATE_SUCK"
            end
        end
        if isThereEnemies(currentRoom) == "f" then
            data.FlamesConsumed = 0
            data.Laser = nil
            data.State = "STATE_SUCK"
        end
    end
end, BeastConsts.VARIANT)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if not game:IsGreedMode() then
        local beasts = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, BeastConsts.VARIANT)
        for i, beast in pairs(beasts) do
            local data = beast:GetData()
            data.State = "STATE_IDLE"
            data.FireDelay = 0
            data.FlamesConsumed = 0
            data.TargetPos = Vector.Zero
            data.TargetPos = Vector.Zero
            data.Flame = nil
            data.Laser = nil
        end
    end
end)

mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, function(_, fam, col)
    local data = fam:GetData()
    if col.SpawnerVariant == BeastConsts.VARIANT then
        col:Remove()
        if data.State == "STATE_SUCK" then
            data.FlamesConsumed = data.FlamesConsumed + 1
        end
    end
end, BeastConsts.VARIANT)



RNGTest = {}
CollectibleType.COLLECTIBLE_CURIOUS_HEART = Isaac.GetItemIdByName("Curious Heart")

function RNGTest:onCuriousHeart(_)
    local player = Isaac.GetPlayer(0)
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_CURIOUS_HEART)
	local roll = rng:RandomInt(100)
	local Nearby = Isaac.GetFreeNearPosition(player.Position, 10)
	if roll < 25 then    
		player:AnimateSad()
	elseif roll < 45 then 
	    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_HALF, Nearby,
		Vector(0,0), nil)
    elseif roll < 55 then
	    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_FULL, Nearby,
		Vector(0,0), nil)
	elseif roll < 60 then
	    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_DOUBLEPACK, Nearby,
		Vector(0,0), nil)
	elseif roll < 75 then
	    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL, Nearby,
		Vector(0,0), nil)
	elseif roll < 90 then
	    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, Nearby,
		Vector(0,0), nil)
	else
    	Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, Nearby,
		Vector(0,0), nil)
	end
	return true 
end 
     
mod:AddCallback(ModCallbacks.MC_USE_ITEM, RNGTest.onCuriousHeart, CollectibleType.COLLECTIBLE_CURIOUS_HEART) -- , mod.Anm, Items.ID_Anm


local PinkColor = Color(1,1,1,1)
PinkColor:SetColorize(5,0.5,2,1)

local Items = {
    StrawMilk = {
        ID = Isaac.GetItemIdByName("strawberry milk"),
        TEARCOLOR = PinkColor --Color(5.0, 1.0, 5.0, 1.0, 0, 0, 0)
    }
}

function mod:tearFire_StrawMilk(t) 
    local d = t:GetData()
    local player = t.SpawnerEntity and (t.SpawnerEntity:ToPlayer()
        or t.SpawnerEntity:ToFamiliar() and t.SpawnerEntity.Player)
    if player:HasCollectible(Items.StrawMilk.ID) then 
        d.IsStrawMilk = true
	
		   if math.random(1, 8) == 8 then
		   t:AddTearFlags(TearFlags.TEAR_FREEZE) 
		end	
    end 
end 
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.tearFire_StrawMilk)

function mod:TearDed_StrawMilk(t)
    if t:GetData().IsStrawMilk then
        local p = Isaac.Spawn(1000,53,0,t.Position,Vector.Zero,t)
        local player = t.SpawnerEntity and t.SpawnerEntity:ToPlayer()
        or t.SpawnerEntity:ToFamiliar() and t.SpawnerEntity.Player
        if player then
            p:ToEffect().Scale = math.max(0.5, math.min(3,player.Damage/15) )
            p:Update()
            p:Update()
            p.Color = Color(5.0, 1.0, 5.0, 1.0, 2, 0, 2)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.TearDed_StrawMilk, EntityType.ENTITY_TEAR)

function mod:TearColor_StrawMilk(player, cache)
    if player:HasCollectible(Items.StrawMilk.ID) then
        player.TearColor = Items.StrawMilk.TEARCOLOR
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.TearColor_StrawMilk, CacheFlag.CACHE_TEARCOLOR)


Holyshell = {}
CollectibleType.COLLECTIBLE_HOLY_SHELL = Isaac.GetItemIdByName("Holy shell")
CollectibleType.COLLECTIBLE_UNHOLY_SHELL = Isaac.GetItemIdByName("Holy shell")
LaserType = { LASER_HOLY = 5 }
LASER_DURATION = 15 

function Holyshell:onUpdate(player)

    local PlayerData = player:GetData()
	if PlayerData.HolyshellFrame == nil then PlayerData.HolyshellFrame = 0 end 
	if PlayerData.HolyshellCool == nil then PlayerData.HolyshellCool = 0 end
	
	--заряд
	if player:GetActiveItem() == CollectibleType.COLLECTIBLE_HOLY_SHELL or
	player:GetActiveItem() == CollectibleType.COLLECTIBLE_UNHOLY_SHELL then 
	    player.FireDelay = player.MaxFireDelay -- стопает стрельбу 
		if player:GetFireDirection() > -1 and
		PlayerData.HolyshellCool == 0 then 
		 -- заряд 
		    PlayerData.HolyshellFrame = math.min(player.MaxFireDelay * 2, PlayerData.HolyshellFrame + 1)
			BOff = math.ceil(255 * PlayerData.HolyshellFrame / player.MaxFireDelay / 2)
			player:SetColor(Color(1,1,1,1,BOff, BOff, BOff), 1, 0, false, false)
		elseif game:GetRoom():GetFrameCount() > 1 then 
		--стрельба 
		    if PlayerData.HolyshellFrame == player.MaxFireDelay * 2 then
			    Isaac.DebugString("FIRE!")
				--уже стреляет
			    if player:GetActiveItem() == CollectibleType.COLLECTIBLE_HOLY_SHELL then 
				    BaseAngle = 0
				else
				    BaseAngle = 45 
				end 
				for Angle = BaseAngle, BaseAngle + 270, 90 do 
				    local HolyLaser = EntityLaser.ShootAngle(LaserType.LASER_HOLY, player.Position, Angle,
					LASER_DURATION, Vector(0,0), player)
					HolyLaser.TearFlags = player.TearFlags
					HolyLaser.CollisionDamage = player.Damage
				end 
			    PlayerData.HolyshellCool = LASER_DURATION * 2
			else 
		    
			end 
			PlayerData.HolyshellFrame = 0
		end 
        PlayerData.HolyshellCool = math.max(0,PlayerData.HolyshellCool - 1)
	end 
end 

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Holyshell.onUpdate)

function Holyshell:onHolyshell1(_)
    local player = Isaac.GetPlayer(0)
	player:RemoveCollectible(CollectibleType.COLLECTIBLE_HOLY_SHELL)
	player:AddCollectible(CollectibleType.COLLECTIBLE_UNHOLY_SHELL, 0, false)
end 

mod:AddCallback(ModCallbacks.MC_USE_ITEM, Holyshell.onHolyshell1, CollectibleType.COLLECTIBLE_HOLY_SHELL)

function Holyshell:onHolyshell2(_)
    local player = Isaac.GetPlayer(0)
	player:RemoveCollectible(CollectibleType.COLLECTIBLE_UNHOLY_SHELL)
	player:AddCollectible(CollectibleType.COLLECTIBLE_UNHOLY_SHELL, 0, false)
end 

mod:AddCallback(ModCallbacks.MC_USE_ITEM, Holyshell.onHolyshell2, CollectibleType.COLLECTIBLE_UNHOLY_SHELL)


local TrinketID = Isaac.GetTrinketIdByName("micro amplifier")

local function tearsUp(firedelay, val)  --Скорострельность вычисляется через эту формулу
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
    return math.max((30 / newTears) - 1, -0.99)
end

function mod:TrinketNewRoom() --Эта функция вызывается после смены комнаты
    for i=0, game:GetNumPlayers()-1 do --Цикл, в котором проходимся по всем игрокам
        local player = Isaac.GetPlayer(i)
        if player:HasTrinket(TrinketID) then
            local data = player:GetData()
            --local TrinkRNG = player:GetTrinketRNG(1)
            local TrinkRNG = RNG()  --RNG отвечает за неслучайную случайность
            TrinkRNG:SetSeed(game:GetLevel():GetCurrentRoomDesc().SpawnSeed+player.InitSeed, 35) --Сид, который отвечает за рандом
            data.PeremenuyEto = 1 << TrinkRNG:RandomInt(6)
            player:AddCacheFlags(CacheFlag.CACHE_ALL)  --Добавляются флаги, чтобы указать какие статы перевычислятся
            player:EvaluateItems() --Эта функция вызывает перевычисление статов
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.TrinketNewRoom)
local statUp = 0.6
function mod:TrinketBonus(player, cache) --Эта функция вызывается при перевычисление статов
    local data = player:GetData()
    if data and data.PeremenuyEto and player:HasTrinket(TrinketID) then
        if cache == data.PeremenuyEto or cache == CacheFlag.CACHE_LUCK then
            local multi = player:GetTrinketMultiplier(TrinketID)
            if cache == CacheFlag.CACHE_SPEED then --SPEED
                player.MoveSpeed = player.MoveSpeed + statUp*multi
            elseif cache == CacheFlag.CACHE_DAMAGE  then --DAMAGE
                player.Damage = player.Damage + statUp*multi
            elseif cache == CacheFlag.CACHE_FIREDELAY then --FIREDELAY
                player.MaxFireDelay = tearsUp(player.MaxFireDelay, statUp*multi)
            elseif cache == CacheFlag.CACHE_RANGE then --RANGE
                player.TearRange = player.TearRange + statUp*40*multi
            elseif cache == CacheFlag.CACHE_SHOTSPEED then --SHOTSPEED
                player.ShotSpeed = player.ShotSpeed + statUp*multi
            elseif cache == CacheFlag.CACHE_LUCK and data.PeremenuyEto == CacheFlag.CACHE_TEARFLAG then --LUCK
                player.Luck = player.Luck + statUp*multi
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.TrinketBonus)

function mod:CheckTrinketHold(player) --Эта функция вызывается каждый кадр для каждого игрока
    local data = player:GetData()
    if player:HasTrinket(TrinketID) then
        if not data.PeremenuyEto then --Если есть брелок, но нет статов, то есть поднятие брелока
            local TrinkRNG = RNG()
            TrinkRNG:SetSeed(game:GetLevel():GetCurrentRoomDesc().SpawnSeed+player.InitSeed, 35)
            data.PeremenuyEto = 1 << TrinkRNG:RandomInt(6)
            player:AddCacheFlags(data.PeremenuyEto)
            player:EvaluateItems()
        end
    elseif not player:HasTrinket(TrinketID) and data.PeremenuyEto then --Если нету есть брелока, но есть статы, то есть потеря брелока
        player:AddCacheFlags(data.PeremenuyEto)
        data.PeremenuyEto = nil
        player:EvaluateItems()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.CheckTrinketHold)


local LeakyBucket = Isaac.GetItemIdByName("Leaky Bucket")
local player = Isaac.GetPlayer(0)

-- Checks whether or not you have the item and deals w/ initialization
local function UpdateFaucet(player)
	HasLeakyFaucet = player:HasCollectible(LeakyBucket)
end

-- Checks whether or not you have the item and deals w/ initialization
local function UpdateFaucet(player)
	HasLeakyFaucet = player:HasCollectible(LeakyBucket)
end

function mod:onPlayerInit(player)
	UpdateFaucet(player)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,  mod.onPlayerInit)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,  mod.onPlayerInit)

-- Gives the Tears buff
function mod:cacheUpdate(player, cacheFlag)
	if cacheFlag == CacheFlag.CACHE_DAMAGE then
		if player:HasCollectible(LeakyBucket) then
			if player.MaxFireDelay >= 7 then
				player.MaxFireDelay = player.MaxFireDelay - 2
			elseif player.MaxFireDelay >= 5 then
				player.MaxFireDelay = 5
			end
		end
	end
end

-- Randomly spawns Holy Water creep
 function  mod:onUpdate_LeakyFaucet(player)
	local player = Isaac.GetPlayer(0)
	local pos = player.Position
	-- Beginning of run initialization
	-- if game:GetFrameCount() == 1 then 
		-- Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, Isaac.GetItemIdByName("Leaky Faucet"), Vector(320,300), Vector(0,0), nil)
		-- That super long line is how to spawn the item in the starting room. Comment it if you don't want it.
	-- end
	if not HasLeakyFaucet and player:HasCollectible(LeakyBucket) then
		HasLeakyFaucet = true
	end
	if HasLeakyFaucet and math.random(100) == 1 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER, 0, pos, Vector(0, 0), player)
	end
 end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.cacheUpdate)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate_LeakyFaucet)

local config = Isaac.GetItemConfig()

local burnedcloverID = Isaac.GetTrinketIdByName("burned clover")

local function GetByQuality(min, max, pool, rnd)
  local Itempool = game:GetItemPool()
  for i=1,100 do
    local seed = rnd:RandomInt(1000000)+1
    local new = Itempool:GetCollectible(pool, true, seed)
    local data = config:GetCollectible(new)
    if data.Quality and data.Quality >= min and data.Quality <= max then
      return new
    end
  end
end


mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
  local room = game:GetRoom()
  if room:IsFirstVisit() and room:GetType() == RoomType.ROOM_TREASURE and room:GetFrameCount()<5 then
    local hasTrink = false
    for i=0, game:GetNumPlayers()-1 do
      hasTrink = hasTrink or (Isaac.GetPlayer(i):HasTrinket(burnedcloverID) and Isaac.GetPlayer(i))
    end
    if hasTrink then
      local destroy
      local items = Isaac.FindByType(5,100,-1)
      for i=1,#items do
        local item = items[i] --and items[i].SubType
        if item then
          local data = config:GetCollectible(items[i].SubType)
          if data.Quality and data.Quality ~= 4 then
            local rng = RNG()
            rng:SetSeed(item.DropSeed, 35)
            local result = GetByQuality(4, 4, ItemPoolType.POOL_TREASURE, rng)
            if result then
              item:ToPickup():Morph(5,100,result,true,true)
              destroy = true
            end
          end
        end
      end
      if destroy then
        local golden
        for i=0,hasTrink:GetMaxTrinkets()-1 do
          golden = golden or (hasTrink:GetTrinket(i) == burnedcloverID+TrinketType.TRINKET_GOLDEN_FLAG)
        end
        hasTrink:TryRemoveTrinket(burnedcloverID)
        if golden then
          hasTrink:AddTrinket(burnedcloverID)
        end
      end
    end
  end
end)


-- get ids and stats
local Trinket = {
	PocketTechology = Isaac.GetTrinketIdByName("Pocket Techology"),
	DAMAGE = 0.5,
}


-- main functionality
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flag, source, countdown)
	for p = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(p);
		local multiplier = player:GetTrinketMultiplier(Trinket.PocketTechology);
	
		if player:HasTrinket(Trinket.PocketTechology) then
			if entity:IsEnemy() and entity:IsActiveEnemy(true) and entity:IsVulnerableEnemy() then
				local npc = entity:ToNPC();
				
				if npc:IsChampion() or (npc:IsBoss() and npc:GetBossColorIdx() >= 0) then
					if (flag & DamageFlag.DAMAGE_CLONES) ~= DamageFlag.DAMAGE_CLONES then
						npc:TakeDamage( -- take the same damage, but reduced by half
							amount * math.min(1, Trinket.DAMAGE * multiplier), 
							DamageFlag.DAMAGE_CLONES, -- don't create infinite loop, prevents bugs
							EntityRef(player), 
							0
						);
					if destroy then
        local golden
        for i=0,hasTrink:GetMaxTrinkets()-1 do
          golden = golden or (hasTrink:GetTrinket(i) == PocketTechology+TrinketType.TRINKET_GOLDEN_FLAG)
        end
        hasTrink:TryRemoveTrinket(PocketTechology)
        if golden then
          hasTrink:AddTrinket(PocketTechology)
        end
      end
					end
				end
			end
		end
	end
end);


local CokaColaItem = Isaac.GetItemIdByName("Cokacola") --Проверь имя предмета
TearVariant.COKACOLA = Isaac.GetEntityVariantByName("Cokacola")
local Cokafart = {
  RADIUS = 50,
    SCALE = 1,
    SUBTYPE = 0,
  FARTDELAY = 5,
}

function mod:TearUpdate(tear)
  local data = tear:GetData()
  if data.IsCocaColaTear12 then
    data.IsCocaColaTear12.FartDelay = data.IsCocaColaTear12.FartDelay - 1
  end
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.TearUpdate)

function mod:TearFire(tear)
  local data = tear:GetData()
  local player = tear.SpawnerEntity and (tear.SpawnerEntity:ToPlayer()
    or tear.SpawnerEntity:ToFamiliar() and tear.SpawnerEntity.Player)
  if player:HasCollectible(CokaColaItem) then 
    tear:ChangeVariant(TearVariant.COKACOLA)
    data.IsCocaColaTear12 = {
      player = player,
      FartDelay = Cokafart.FARTDELAY,
    }
   end
end 
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.TearFire)

function mod:TearCollision(tear)
  local data = tear:GetData()
  if data.IsCocaColaTear12 and data.IsCocaColaTear12.player:Exists() then
    local Gram = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BROWN, 0,
        tear.Position, Vector(0,0), data.IsCocaColaTear12.player):ToEffect()
        Gram.CollisionDamage = (data.IsCocaColaTear12.player.Damage or 0.10) / 0.20
        Gram:SetColor(Color(0.5,0.05,0,0,0,0,0),0,0,false,false)
        Gram:GetData().Cokacola = true 
    Gram:Update()
    Gram:Update()
    Gram.Color = Color(0.5,0.05,0,1,0,0,0)
  end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.TearCollision,2)

function mod:onDamage(entity, collider)
  local data = entity:GetData()
  if data.IsCocaColaTear12 or  entity.Type == EntityType.ENTITY_TEAR
    and entity.Variant == TearVariant.COKACOLA then
    if data.IsCocaColaTear12.FartDelay <= 0 then
        game:Fart(entity.Position, Cokafart.RADIUS, nil, Cokafart.SCALE, Cokafart.SUBTYPE )
      data.IsCocaColaTear12.FartDelay = Cokafart.FARTDELAY
    end
    end
end

mod:AddPriorityCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, 100, mod.onDamage)

function mod:onCache_Coka(player, flag)
  if flag == CacheFlag.CACHE_RANGE then
    if player:HasCollectible(CokaColaItem) then
          player.TearFallingSpeed = player.TearFallingSpeed - 3
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.onCache_Coka)


local Cigarette = Isaac.GetItemIdByName("cigarette")
local player = Isaac.GetPlayer(0)

function mod:updateCache_Cig(_player, cacheFlag)
    local player = Isaac.GetPlayer(0)
	
	if cacheFlag == CacheFlag.CACHE_DAMAGE then
	    if player:HasCollectible(Cigarette) then 
		    player.Damage = player.Damage +1
		end
	end	
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_Cig)

local MOREOPTIONS = Isaac.GetTrinketIdByName("MORE OPTIONS")
local spawnPos = Vector(500,140)
function mod:options_Wow_Room()
  local room = game:GetRoom()
  local hasTrink
  local HasSale
  for i=0, game:GetNumPlayers()-1 do
    local player = Isaac.GetPlayer(i)
    if player:HasTrinket(MOREOPTIONS) then
      hasTrink = true
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_STEAM_SALE) then
      HasSale = true
    end
  end

  if hasTrink and room:IsFirstVisit() and room:GetType() == RoomType.ROOM_SHOP then
    local Itempool = game:GetItemPool()
    local pos = Isaac.GetFreeNearPosition(spawnPos, 40)
    local rng = RNG()
    local seed = game:GetLevel():GetCurrentRoomDesc().AwardSeed
    rng:SetSeed(seed, 35)
    local ItemId = GetByQuality(3, 4, Itempool:GetPoolForRoom(RoomType.ROOM_SHOP, seed), rng)
    if ItemId then
      local obj = Isaac.Spawn(5,100,ItemId,pos,Vector.Zero,nil):ToPickup()
      obj:Update()

      obj.Price = 30
      obj.ShopItemId = -2
      obj.AutoUpdatePrice = false
      obj:Update()
      if HasSale then
        obj.Price = 15
      end
      local poof = Isaac.Spawn(1000, 16, 1, pos, Vector.Zero, nil):ToEffect()
      poof:GetSprite().Scale = Vector(0.6, 0.6)
      poof.Color = Color(0.5, 0.5, 0.5, 1)
      SFXManager():Play(SoundEffect.SOUND_BLACK_POOF, 1, 2, false, 1, 0)
    end
  end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.options_Wow_Room)


local Bananamilk = Isaac.GetItemIdByName("banana milk")

function mod:updateCache_Banana(_player, cacheFlag)
    local player = Isaac.GetPlayer(0)
	
	if cacheFlag == CacheFlag.CACHE_FIREDELAY then
	    if player:HasCollectible(Bananamilk) then 
		    player.MaxFireDelay = player.MaxFireDelay +100;
		end
	end
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
	    if player:HasCollectible(Bananamilk) then 
		    player.Damage = player.Damage +100
		end
	end	
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_Banana)


local YellowColor = Color(1,1,1,1)
YellowColor:SetColorize(0.9,0.9,0,2)

local Items = {
    BananaMilk = {
        ID = Isaac.GetItemIdByName("banana milk"),
        TEARCOLOR = YellowColor --Color(5.0, 1.0, 5.0, 1.0, 0, 0, 0)
    }
}

function mod:TearDed_Banana(t)
    if t:GetData().IsBananaMilk then
        local p = Isaac.Spawn(1000,53,0,t.Position,Vector.Zero,t)
        local player = t.SpawnerEntity and t.SpawnerEntity:ToPlayer()
        or t.SpawnerEntity:ToFamiliar() and t.SpawnerEntity.Player
        if player then
            p:ToEffect().Scale = math.max(0, math.min(3,player.Damage/0) )
            p:Update()
            p:Update()
            p.Color = Color(5.0, 1.0, 5.0, 1.0, 2, 0, 2)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.TearDed_Banana, EntityType.ENTITY_TEAR)

function mod:TearColor(player, cache)
    if player:HasCollectible(Items.BananaMilk.ID) then
        player.TearColor = Items.BananaMilk.TEARCOLOR
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.TearColor, CacheFlag.CACHE_TEARCOLOR)



EntityType.ENTITY_DICEGARPER = Isaac.GetEntityTypeByName("Dice Garper")
DiceGarper = {
    SPEED = 0.5,
	RANGE = 200
}
function mod:onDiceGarper(entity)
    local sprite = entity:GetSprite()
	sprite:PlayOverlay("Head", false)
	entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
	
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	if data.GridCountdown == nil then data.GridCountdown = 0 end
	
	if entity.State == 0 then
	    if entity:IsFrame(8/DiceGarper.SPEED, 0) then
		    entity.Pathfinder:MoveRandomly(false)
        end
		if (entity.Position - target.Position):Length() < DiceGarper.RANGE then
            entity.State = 2
        end
    elseif entity.State == 2 then
        if entity:CollidesWithGrid() or data.GridCountdown > 0 then
            entity.Pathfinder:FindGridPath(target.Position, DiceGarper.SPEED, 1, false)
			if data.GridCountdown <= 0 then
			    data.GridCountdown = 30
            else
                data.GridCountdown = data.GridCountdown - 1
		    end
	    else
		    entity.Velocity = (target.Position - entity.Position):Normalized() * DiceGarper.SPEED * 6
		end 
    end 
end 

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.onDiceGarper, EntityType.ENTITY_DICEGARPER)

EntityType.ENTITY_BROKEDICEGARPER = Isaac.GetEntityTypeByName("Broken Dice Garper")
BrokDiceGarper = {
    SPEED = 1.0,
	RANGE = 200
}
function mod:onBrokDiceGarper(entity)
    local sprite = entity:GetSprite()
	sprite:PlayOverlay("Head", false)
	entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
	
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	if data.GridCountdown == nil then data.GridCountdown = 0 end
	
	if entity.State == 0 then
	    if entity:IsFrame(8/BrokDiceGarper.SPEED, 0) then
		    entity.Pathfinder:MoveRandomly(false)
        end
		if (entity.Position - target.Position):Length() < BrokDiceGarper.RANGE then
            entity.State = 2
        end
    elseif entity.State == 2 then
        if entity:CollidesWithGrid() or data.GridCountdown > 0 then
            entity.Pathfinder:FindGridPath(target.Position, BrokDiceGarper.SPEED, 1.4, false)
			if data.GridCountdown <= 0 then
			    data.GridCountdown = 30
            else
                data.GridCountdown = data.GridCountdown - 1
		    end
	    else
		    entity.Velocity = (target.Position - entity.Position):Normalized() * BrokDiceGarper.SPEED * 6
		end 
    end 
end 

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.onBrokDiceGarper, EntityType.ENTITY_BROKEDICEGARPER)


local Items = {
    DilTeh = {
        ID = Isaac.GetItemIdByName("Delirious tech")
    }
}

function mod:LazerColor(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_TEARCOLOR then
        if player:HasCollectible(Items.DilTeh.ID) then 
           player.LaserColor = Color(0,0,0,1,215,95,25) 
        end
    end 
end

local tech1Flags = {TearFlags.TEAR_SLOW,
TearFlags.TEAR_HOMING,
TearFlags.TEAR_POISON,
TearFlags.TEAR_SPLIT,
TearFlags.TEAR_FREEZE,
TearFlags.TEAR_GROW,
TearFlags.TEAR_BOOMERANG,
TearFlags.TEAR_PERSISTENT,
TearFlags.TEAR_WIGGLE,
TearFlags.TEAR_MULLIGAN,
TearFlags.TEAR_EXPLOSIVE,
TearFlags.TEAR_CONFUSION,
TearFlags.TEAR_CHARM,
TearFlags.TEAR_ORBIT,
TearFlags.TEAR_WAIT,
TearFlags.TEAR_QUADSPLIT,
TearFlags.TEAR_BOUNCE,
TearFlags.TEAR_FEAR,
TearFlags.TEAR_SHRINK,
TearFlags.TEAR_BURN,
TearFlags.TEAR_KNOCKBACK,
TearFlags.TEAR_SPIRAL,
TearFlags.TEAR_SQUARE,
TearFlags.TEAR_GLOW,
TearFlags.TEAR_GISH,
TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP,
TearFlags.TEAR_STICKY,
TearFlags.TEAR_CONTINUUM,
TearFlags.TEAR_LIGHT_FROM_HEAVEN,
TearFlags.TEAR_TRACTOR_BEAM,
TearFlags.TEAR_BIG_SPIRAL,
TearFlags.TEAR_BOOGER,
TearFlags.TEAR_ACID,
TearFlags.TEAR_BONE,
TearFlags.TEAR_JACOBS,
TearFlags.TEAR_LASER,
TearFlags.TEAR_POP,
TearFlags.TEAR_ABSORB,
TearFlags.TEAR_HYDROBOUNCE,
TearFlags.TEAR_BURSTSPLIT,
TearFlags.TEAR_PUNCH,
TearFlags.TEAR_ORBIT_ADVANCED,
TearFlags.TEAR_TURN_HORIZONTAL,
TearFlags.TEAR_ECOLI,
TearFlags.TEAR_RIFT,
TearFlags.TEAR_TELEPORT}

function mod:tearFire_Diltech(t) 
    local d = t:GetData()
    local player = t.SpawnerEntity and (t.SpawnerEntity:ToPlayer()
        or t.SpawnerEntity:ToFamiliar() and t.SpawnerEntity.Player)
        if player:HasCollectible(Items.DilTeh.ID) then
            local rng = player:GetCollectibleRNG(Items.DilTeh.ID)
            local chance = rng:RandomInt(50)
        if chance >=25 then
            local lazer = player:FireTechLaser(t.Position, 0, t.Velocity, false, true, player)
        else
            local lazer = player:FireTechXLaser(t.Position, t.Velocity, 50, player)
        end

        t:Remove()
	
	end	
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.LazerColor, CacheFlag.CACHE_TEARCOLOR)
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.tearFire_Diltech)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
  for i=0, game:GetNumPlayers() do
    local p = Isaac.GetPlayer(i)
    p:GetData().TBOIREP_Minus_DilliriumTech = p:GetCollectibleRNG(Items.DilTeh.ID):RandomInt(2)+1
  end
end)

local laserTypes = {
    [0] = CollectibleType.COLLECTIBLE_TECH_X,
    [1] = CollectibleType.COLLECTIBLE_BRIMSTONE,
    [2] = CollectibleType.COLLECTIBLE_TECHNOLOGY,
    [3] = CollectibleType.COLLECTIBLE_TECHNOLOGY_2,
    [4] = CollectibleType.COLLECTIBLE_TECHNOLOGY_ZERO,
    [5] = CollectibleType.COLLECTIBLE_TECH_5
}


function mod:deliriousTechLaserSwitch(player)
    if player:HasCollectible(Items.DilTeh.ID) and game:GetFrameCount() % 30 == 0 then
        local rng = player:GetCollectibleRNG(Items.DilTeh.ID)
        local data = mod:repmGetPData(player)
        if rng:RandomInt(100) > 94 or data.DelirousTechState == nil then
            if data.DelirousTechState ~= nil then
                hiddenItemManager:Remove(player, data.DelirousTechState, hiddenItemManager.kDefaultGroup)
            end
            local num = rng:RandomInt(6)
            local selectedNum = laserTypes[num]
            data.DelirousTechState = selectedNum
            hiddenItemManager:Add(player, selectedNum)
            if not player:HasCollectible(selectedNum, true) then
                local costConfig = config:GetCollectible(selectedNum)
                player:RemoveCostume(costConfig)
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.deliriousTechLaserSwitch)

function mod:checkLaser_DelTech(laser)
    local player = mod:getPlayerFromKnifeLaser(laser)
    local pdata = player and mod:repmGetPData(player)
    local data = laser:GetData()
    local var = laser.Variant
    local subt = laser.SubType
    local ignoreLaserVar = ((var == 1 and subt == 3) or var == 5 or var == 12)
    if laser.Type == EntityType.ENTITY_EFFECT then
        ignoreLaserVar = false
    end

    if player and not ignoreLaserVar then
        if player:HasCollectible(Items.DilTeh.ID) then
            --local rng = player:GetCollectibleRNG(Items.DilTeh.ID)
            --if laser.Type == EntityType.ENTITY_EFFECT and laser.Variant == EffectVariant.BRIMSTONE_SWIRL then
            --end
            data.RandomizeDelLaserEffect = true
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, mod.checkLaser_DelTech)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.checkLaser_DelTech, EffectVariant.BRIMSTONE_BALL)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.checkLaser_DelTech, EffectVariant.BRIMSTONE_SWIRL)

function mod:updateLasersPlayer_DelTech(player)
    local lasers = Isaac.FindByType(EntityType.ENTITY_LASER)
    local rng = player:GetCollectibleRNG(Items.DilTeh.ID)
    for i=1, #lasers do
        local laser = lasers[i]
        if laser:GetData().RandomizeDelLaserEffect == true then
            laser:GetData().RandomizeDelLaserEffect = false
            laser:ToLaser():AddTearFlags(tech1Flags[rng:RandomInt(#tech1Flags)+1])
        end
    end

    --local brimballs = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BRIMSTONE_BALL)
    --for i=1, #brimballs do
        --local brimball = brimballs[i]
        --if brimball:GetData().RandomizeDelLaserEffect == true then
            --brimball:GetData().RandomizeDelLaserEffect = false
            --brimball:AddTearFlags(tech1Flags[rng:RandomInt(#tech1Flags)+1])
        --end
    --end

    --local brimswirls = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BRIMSTONE_SWIRL)
    --for i=1, #brimswirls do
        --local brimswirl = brimswirls[i]
        --if brimswirl:GetData().RandomizeDelLaserEffect == true then
            --brimswirl:GetData().RandomizeDelLaserEffect = false
            --brimswirl:AddTearFlags(tech1Flags[rng:RandomInt(#tech1Flags)+1])
        --end
    --end

end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.updateLasersPlayer_DelTech)
    
    


local Items = {
    Vacum = {
        ID = Isaac.GetItemIdByName("vacuum"),
    }
}

function mod:tearUpdate(tear)
    if tear:GetData().IsVacum and tear:HasTearFlags(TearFlags.TEAR_BOOMERANG) and tear.SpawnerEntity then
        local pow = tear.SpawnerEntity.Position:Distance(tear.Position)/10
        local newvel = (tear.SpawnerEntity.Position-tear.Position):Resized(pow)
        tear.Velocity = tear.Velocity * 0.9 + newvel * 0.1
    end
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.tearUpdate)

function mod:tearFire(t) 
    local d = t:GetData()
    local player = t.SpawnerEntity and (t.SpawnerEntity:ToPlayer()
        or t.SpawnerEntity:ToFamiliar() and t.SpawnerEntity.Player)
    if player:HasCollectible(Items.Vacum.ID) then 
        d.IsVacum = true
    
           if math.random(1, 5) == 4 then
           t:AddTearFlags(TearFlags.TEAR_BOOMERANG)
		   t:ChangeVariant(TearVariant.DARK_MATTER)
        end    
    end 
end 
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.tearFire)

function mod:updateCache_Vacuum(_player, cacheFlag)
    local player = Isaac.GetPlayer(0) 
    
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
        if player:HasCollectible(Items.Vacum.ID) then 
            player.MaxFireDelay = player.MaxFireDelay -0.50;
        end
    end
    if cacheFlag == CacheFlag.CACHE_RANGE then
        if player:HasCollectible(Items.Vacum.ID) then
            player.TearRange = player.TearRange + 70 * 3;
        end        
    end
end    
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_Vacuum)



mod.COLLECTIBLE_BEEG_MINUS = Isaac.GetItemIdByName("Minus")
mod.COLLECTIBLE_PINK_STRAW = Isaac.GetItemIdByName("Pink straw")
mod.COLLECTIBLE_PIXELATED_CUBE = Isaac.GetItemIdByName("Pixelated cube")
mod.COLLECTIBLE_110V = Isaac.GetItemIdByName("110V")
mod.COLLECTIBLE_DILIRIUM_EYE = Isaac.GetItemIdByName("Dilirium eye")
mod.COLLECTIBLE_THE_ROCK = Isaac.GetItemIdByName("The rock")
local DiliriumEyeLastActivateFrame = 0

local player = Isaac.GetPlayer(0)
local PixelatedCubeBabiesList = {}
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	-- babies list for pixelated cube
  local config = Isaac.GetItemConfig()
  if #PixelatedCubeBabiesList == 0 then
    for id=1, config:GetCollectibles().Size do
      local item = config:GetCollectible(id)
      if item and item:HasTags(ItemConfig.TAG_MONSTER_MANUAL) then
        PixelatedCubeBabiesList[#PixelatedCubeBabiesList+1] = id
      end
    end
  end
end) 

function mod:onUpdate_Rock()
	--The rock
	for playerNum = 1, game:GetNumPlayers() do
		local player = game:GetPlayer(playerNum)
		if player:HasCollectible(mod.COLLECTIBLE_THE_ROCK) then
			for i, entity in pairs(Isaac.GetRoomEntities()) do
				if entity:IsVulnerableEnemy() then
					if player:GetFireDirection() == 0 then
						if entity.Position.X < player.Position.X and math.abs(entity.Position.Y - player.Position.Y) < 30 then
							entity:AddFear(EntityRef(player), 60)
						end					
					elseif player:GetFireDirection() == 1 then
						if entity.Position.Y < player.Position.Y and math.abs(entity.Position.X - player.Position.X) < 30 then
							entity:AddFear(EntityRef(player), 60)
						end						
					elseif player:GetFireDirection() == 2 then
						if entity.Position.X > player.Position.X and math.abs(entity.Position.Y - player.Position.Y) < 30 then
							entity:AddFear(EntityRef(player), 60)
						end						
					elseif player:GetFireDirection() == 3 then
						if entity.Position.Y > player.Position.Y and math.abs(entity.Position.X - player.Position.X) < 30 then
							entity:AddFear(EntityRef(player), 60)
						end						
					else
						if player:GetMovementDirection() == 0 then
							if entity.Position.X < player.Position.X and math.abs(entity.Position.Y - player.Position.Y) < 30 then
								entity:AddFear(EntityRef(player), 60)
							end						
						elseif player:GetMovementDirection() == 1 then
							if entity.Position.Y < player.Position.Y and math.abs(entity.Position.X - player.Position.X) < 30 then
								entity:AddFear(EntityRef(player), 60)
							end							
						elseif player:GetMovementDirection() == 2 then
							if entity.Position.X > player.Position.X and math.abs(entity.Position.Y - player.Position.Y) < 30 then
								entity:AddFear(EntityRef(player), 60)
							end							
						elseif player:GetMovementDirection() == 3 then
							if entity.Position.Y > player.Position.Y and math.abs(entity.Position.X - player.Position.X) < 30 then
								entity:AddFear(EntityRef(player), 60)
							end							
						else
							if player:GetLastDirection() == 0 then
								if entity.Position.X < player.Position.X and math.abs(entity.Position.Y - player.Position.Y) < 30 then
									entity:AddFear(EntityRef(player), 60)
								end							
							elseif player:GetLastDirection() == 1 then
								if entity.Position.Y < player.Position.Y and math.abs(entity.Position.X - player.Position.X) < 30 then
									entity:AddFear(EntityRef(player), 60)
								end								
							elseif player:GetLastDirection() == 2 then
								if entity.Position.X > player.Position.X and math.abs(entity.Position.Y - player.Position.Y) < 30 then
									entity:AddFear(EntityRef(player), 60)
								end								
							elseif player:GetLastDirection() == 3 then
								if entity.Position.Y > player.Position.Y and math.abs(entity.Position.X - player.Position.X) < 30 then
									entity:AddFear(EntityRef(player), 60)
								end						
							end
						end
					end
				end
			end
		end
	end
	-- Minus
	for playerNum = 1, game:GetNumPlayers() do
		local player = game:GetPlayer(playerNum)
		if player:HasCollectible(mod.COLLECTIBLE_BEEG_MINUS) then
			player:Kill()
		end
	end
	
	
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate_Rock)

function mod:PurpleStrawUse(itemID, rng, player)
	-- purple straw
	for i, entity in ipairs(Isaac.GetRoomEntities()) do
		local Number = math.random(1,5)
		if entity:IsActiveEnemy(false) and entity:IsVulnerableEnemy() and entity:IsEnemy() then
			if Number == 1 then
				entity:AddPoison(EntityRef(player), 60, 3.5)
			end
			if Number == 2 then
				entity:AddConfusion(EntityRef(player), 60, false)
			end
			if Number == 3 then
				entity:AddCharmed(EntityRef(player), 60)
			end
			if Number == 4 then
				entity:AddFear(EntityRef(player), 60, 3.5)
			end
			if Number == 5 then
				entity:AddSlowing(EntityRef(player), 60, 3, Color.Default)
			end
		end
	end
	return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.PurpleStrawUse, mod.COLLECTIBLE_PINK_STRAW)

function mod:PixelatedCubeUse(itemID, rng, player)
	-- pixelated cube
	local BabyNumber = PixelatedCubeBabiesList[math.random(1, 30)]
	player:GetEffects():AddCollectibleEffect(BabyNumber, false)
	local BabyNumber = PixelatedCubeBabiesList[math.random(1, 30)]
	player:GetEffects():AddCollectibleEffect(BabyNumber, false)
	local BabyNumber = PixelatedCubeBabiesList[math.random(1, 30)]
	player:GetEffects():AddCollectibleEffect(BabyNumber, false)
	return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.PixelatedCubeUse, mod.COLLECTIBLE_PIXELATED_CUBE)

function mod:OnRoomClear(player)
	--110V double charge part
	for playerNum = 1, game:GetNumPlayers() do
		local player = game:GetPlayer(playerNum)
		if player:HasCollectible(mod.COLLECTIBLE_110V) then
			local maxCharge = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(0)).MaxCharges
			if player:GetActiveCharge(SLOT_PRIMARY) ~= maxCharge then
				player:SetActiveCharge(player:GetActiveCharge(SLOT_PRIMARY) + 1, SLOT_PRIMARY)
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.OnRoomClear)

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function()
	--110V damage on using active part
	for playerNum = 1, game:GetNumPlayers() do
		local player = game:GetPlayer(playerNum)
		if player:HasCollectible(mod.COLLECTIBLE_110V) then
			local maxCharge = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(0)).MaxCharges
			if maxCharge == 2 or maxCharge == 3 then
				player:TakeDamage(1, DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS, EntityRef(player), 0)
			end
			if maxCharge == 4 then
				player:TakeDamage(2, DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS, EntityRef(player), 0)
			end
			if maxCharge == 6 then
				player:TakeDamage(3, DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS, EntityRef(player), 0)
			end
			if maxCharge == 12 then
				player:TakeDamage(5, DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS, EntityRef(player), 0)
			end
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function()
	if game:GetFrameCount() > DiliriumEyeLastActivateFrame + 1 then
		for playerNum = 1, game:GetNumPlayers() do
			local player = game:GetPlayer(playerNum)
			if player:HasCollectible(mod.COLLECTIBLE_DILIRIUM_EYE) then
				if math.random(1,5) == 3 then
				DiliriumEyeLastActivateFrame = game:GetFrameCount()
					if player:GetFireDirection() == 0 then
						for i = -2, 2 do
							if i ~= 0 then								
								local ShootDirection = Vector(-math.cos(math.rad(15 * math.abs(i))) * player.ShotSpeed * 10, -math.sin(math.rad(15 * math.abs(i))) * player.ShotSpeed * 10 * i / math.abs(i))					
								player:FireTear(player.Position, ShootDirection, true, true, false, player, 1)								
							end
						end
					elseif 	player:GetFireDirection() == 1 then
						for i = -2, 2 do
							if i ~= 0 then 
								local ShootDirection = Vector(math.sin(math.rad(15 * math.abs(i))) * player.ShotSpeed * 10 * i / math.abs(i), -math.cos(math.rad(15 * math.abs(i))) * player.ShotSpeed* 10)
								player:FireTear(player.Position, ShootDirection, true, true, false, player, 1)
							end
						end			
					elseif 	player:GetFireDirection() == 2 then
						for i = -2, 2 do
							if i ~= 0 then						
								local ShootDirection =  Vector(math.cos(math.rad(15 * math.abs(i))) * player.ShotSpeed * 10, -math.sin(math.rad(15 * math.abs(i))) * player.ShotSpeed * 10 * i / math.abs(i)) 
								player:FireTear(player.Position, ShootDirection, true, true, false, player, 1)								
							end
						end
					elseif player:GetFireDirection() == 3 then
						for i = -2, 2 do
							if i ~= 0 then 
								local ShootDirection = Vector(math.sin(math.rad(15 * math.abs(i))) * player.ShotSpeed * 10 * i / math.abs(i), math.cos(math.rad(15 * math.abs(i))) * player.ShotSpeed* 10)
								player:FireTear(player.Position, ShootDirection, true, true, false, player, 1)								
							end
						end
					end	
				end
			end
		end
	end
end)



local Items = {
    FlowTea = {
        ID = Isaac.GetItemIdByName("Flower tea")
    }
}

function mod:updateCache_FlowTea(_player, cacheFlag)
    local player = Isaac.GetPlayer(0)
	
if cacheFlag == CacheFlag.CACHE_DAMAGE then
	    if player:HasCollectible(Items.FlowTea.ID) then 
		    player.Damage = player.Damage +0.60
		end 
	end
if cacheFlag == CacheFlag.CACHE_RANGE then
		if player:HasCollectible(Items.FlowTea.ID) then
			player.TearRange = player.TearRange + 40 * 0.5;
			end		
		end
if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
        if player:HasCollectible(Items.FlowTea.ID) then 
            player.ShotSpeed = player.ShotSpeed -0.20
		end
	end		
end 
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_FlowTea)



function mod:onUpdate_Otmichka()	
	for playerNum = 1, game:GetNumPlayers() do
local player = game:GetPlayer(playerNum)
local spawnpos = game:GetRoom():FindFreeTilePosition(game:GetRoom():GetCenterPos(), 400)
mod.Collectible_HOLY_OTMICHKA = Isaac.GetItemIdByName("Holy master key") 

if player:HasCollectible(mod.Collectible_HOLY_OTMICHKA) then
		if math.random(1,7) == 5 then
	Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_ETERNALCHEST, 0 , Vector(320,320), Vector(0,0), nil)
			end
		end
	end
end  
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.onUpdate_Otmichka)



local Dead = Isaac.GetItemIdByName("I want to live")
local Alive = Isaac.GetItemIdByName("I am alive")
local Player = Isaac.GetPlayer(0)


function mod:PassiveDead()
		local Player = Isaac.GetPlayer(0)
    if Player:HasCollectible(Dead) then
         if Player:IsDead() then
				 	 Player:AnimateLightTravel()
           Player:Revive()
					 Player:ChangePlayerType(PlayerType.PLAYER_THELOST)
					 Player:RemoveCollectible(Dead)
					 Player:AddCollectible(Alive)
					 Player:AddCacheFlags(CacheFlag.CACHE_ALL)
					 Player:EvaluateItems()


					 local level = game:GetLevel()
		 			 local room = game:GetRoom()

		 			 local enterDoorIndex = level.EnterDoor
		 			 		if enterDoorIndex == -1 or room:GetDoor(enterDoorIndex) == nil or level:GetCurrentRoomIndex() == level:GetPreviousRoomIndex() then
		 					game:StartRoomTransition(level:GetCurrentRoomIndex(), Direction.NO_DIRECTION, RoomTransitionAnim.ANKH)
		 			 		else
		 					local enterDoor = room:GetDoor(enterDoorIndex)
		 					local targetRoomIndex = enterDoor.TargetRoomIndex
		 					local targetRoomDirection = enterDoor.Direction

		 					level.LeaveDoor = -1
		 					game:StartRoomTransition(targetRoomIndex, targetRoomDirection, RoomTransitionAnim.ANKH)
							end
				 end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.PassiveDead)

function mod:updateCache_Alive(_Player, cacheFlags)
		local Player = Isaac.GetPlayer(0)

		if cacheFlags == CacheFlag.CACHE_FIREDELAY then
				if Player:HasCollectible(Alive) then
								Player.MaxFireDelay = Player.MaxFireDelay -4.7
				end
		end
		if cacheFlags == CacheFlag.CACHE_DAMAGE then
				if Player:HasCollectible(Alive) then
								Player.Damage = Player.Damage +2
				end
		end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_Alive)


local Items = {
    Kozol = {
        ID = Isaac.GetItemIdByName("Deal of the death")
    }
}

function mod:updateCache_Kozol(_player, cacheFlag)
    local player = Isaac.GetPlayer(0)
	
if cacheFlag == CacheFlag.CACHE_DAMAGE then
	    if player:HasCollectible(Items.Kozol.ID) then 
		    player.Damage = player.Damage +1
		end 
	end
if cacheFlag == CacheFlag.CACHE_FLYING  then
        if player:HasCollectible(Items.Kozol.ID) then    
			player.CanFly = true
			end		
		end
if cacheFlag == CacheFlag.CACHE_FIREDELAY then
		if player:HasCollectible(Items.Kozol.ID) then
			player.MaxFireDelay = player.MaxFireDelay -2
		end
	end		
if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
        if player:HasCollectible(Items.Kozol.ID) then 
            player.ShotSpeed = player.ShotSpeed -0.1
		end
	end	
if cacheFlag == CacheFlag.CACHE_LUCK then
        if player:HasCollectible(Items.Kozol.ID) then    
			player.Luck = player.Luck +5
        end
    end
if cacheFlag == CacheFlag.CACHE_SPEED then
        if player:HasCollectible(Items.Kozol.ID) then     
			player.MoveSpeed = player.MoveSpeed +0.30
        end
    end
if cacheFlag == CacheFlag.CACHE_TEARFLAG then
        if player:HasCollectible(Items.Kozol.ID) then    
		    player.TearFlags = player.TearFlags | TearFlags.TEAR_SPECTRAL
        end
	end 
end 
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_Kozol)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flag)
    if ent:ToPlayer() and ent:ToPlayer():HasCollectible(Items.Kozol.ID) and flag & DamageFlag.DAMAGE_NO_PENALTIES == 0 then
        ent:Kill()
    end
end, 1)

local Items = {
    Buter = {
		ID = Isaac.GetItemIdByName("sandwich")
    }
}

function mod:updateCache_Buter(_player, cacheFlag)
    local player = Isaac.GetPlayer(0)
	
if cacheFlag == CacheFlag.CACHE_DAMAGE then
	    if player:HasCollectible(Items.Buter.ID) then 
		    player.Damage = player.Damage +0.5
		end 
	end
if cacheFlag == CacheFlag.CACHE_FIREDELAY then
		if player:HasCollectible(Items.Buter.ID) then
			player.MaxFireDelay = player.MaxFireDelay -0.35
		end
	end		
if cacheFlag == CacheFlag.CACHE_TEARFLAG then
        if player:HasCollectible(Items.Buter.ID) then    
		if math.random(1, 5) == 4 then
		    player.TearFlags = player.TearFlags | TearFlags.TEAR_BAIT
		if math.random(1, 5) == 3 then
		    player.TearFlags = player.TearFlags | TearFlags.TEAR_POISON
				end 
			end
		end
	end 
end 
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_Buter)

 
local Minusaac = { -- Change Minusaac everywhere to match your character. No spaces!
    DAMAGE = 0.7, -- These are all relative to Isaac's base stats.
    SPEED = 0.2,
    SHOTSPEED = -2.90,
    TEARHEIGHT = -1,
    TEARFALLINGSPEED = 3,
    LUCK = 1,
    FLYING = false,                                  
    TEARFLAG = 0, -- 0 is default
    TEARCOLOR = Color(1.0, 1.0, 1.0, 1.0, 0, 0, 0)  -- Color(1.0, 1.0, 1.0, 1.0, 0, 0, 0) is default
}
 
function mod:onCache_Minus(player, cacheFlag) -- I do mean everywhere!
    if player:GetName() == "Minusaac" then -- Especially here!
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + Minusaac.DAMAGE
        end
        if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + Minusaac.SHOTSPEED
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            player.TearHeight = player.TearHeight - Minusaac.TEARHEIGHT
            player.TearFallingSpeed = player.TearFallingSpeed + Minusaac.TEARFALLINGSPEED
        end
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + Minusaac.SPEED
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + Minusaac.LUCK
        end
        if cacheFlag == CacheFlag.CACHE_FLYING and Minusaac.FLYING then
            player.CanFly = true
        end
        if cacheFlag == CacheFlag.CACHE_TEARFLAG then
            player.TearFlags = player.TearFlags | Minusaac.TEARFLAG
        end
    end
end
 
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.onCache_Minus)



function AddFlag(...)
    local ToReturn = 0
    for _,a in pairs({...}) do
        ToReturn = ToReturn + (1 << a)
    end
    return ToReturn
end
local StatsUpItem = Isaac.GetItemIdByName("Bloddy negative")
local Minusaac = Isaac.GetPlayerTypeByName("Minusaac")
---@param Player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,function (_,Player)
    if Player:GetPlayerType() ~= Minusaac then
        return
    end
    Player:GetData().RepMinus = {
        StatsDowns = {
            Damage = 0,
            MoveSpeed = 0,
            MaxFireDelay = 0,
            TearRange = 0,
        }
    }
end)

--if player:GetName() == "Minusaac" then
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    if player:GetName() == "Minusaac" then 
      player:AddCollectible(StatsUpItem)
    end
  end)


---@param Player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM,function (_,_,_,Player)
    if Player:GetPlayerType() ~= Minusaac then
        return
    end
    --print(Player:GetEffectiveMaxHearts())
    if Player:GetEffectiveMaxHearts() > 2 or (Player:GetEffectiveMaxHearts() > 0 and Player:GetSoulHearts() > 0) then
        Player:AddMaxHearts(-2)
    elseif Player:GetSoulHearts() > 4 or (Player:GetEffectiveMaxHearts() > 0 and Player:GetSoulHearts() >= 4) then
        Player:AddSoulHearts(-4)
    elseif Player:GetBlackHearts() > 4 or (Player:GetEffectiveMaxHearts() > 0 and Player:GetBlackHearts() >= 4) then
        Player:AddBlackHearts(-4)
    else
        return
    end
    for i=1,8 do
        Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.BLOOD_PARTICLE,0,Player.Position,Vector(0,math.random(0,5)):Rotated(math.random(360)),nil)
        Player:SetMinDamageCooldown(90)
    end
    local Data = Player:GetData().RepMinus.StatsDowns
    Data.MoveSpeed = Data.MoveSpeed + 0.15
    Data.Damage = Data.Damage + 0.2
    Data.MaxFireDelay = math.min(Data.MaxFireDelay + 0.75,5)
    Data.TearRange = Data.TearRange + 8
    Player:AddCacheFlags(CacheFlag.CACHE_ALL,true)
    return true
end,StatsUpItem)

---@param Player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,function (_,Player,Cache)
    if Player:GetPlayerType() ~= Minusaac then
        return
    end
    local Data = Player:GetData().RepMinus.StatsDowns
    if Cache == CacheFlag.CACHE_SPEED then
        Player.MoveSpeed = Player.MoveSpeed + Data.MoveSpeed
    end
    if Cache == CacheFlag.CACHE_DAMAGE then
        Player.Damage = Player.Damage + Data.Damage
    end
    if Cache == CacheFlag.CACHE_FIREDELAY then
        Player.MaxFireDelay = Player.MaxFireDelay - Data.MaxFireDelay
    end
    if Cache == CacheFlag.CACHE_RANGE then
        Player.TearRange = Player.TearRange + Data.TearRange
    end
end)

---@type ModReference
---@param Entity Entity
---@param DamageFlags DamageFlag
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,function (_,Entity,_,DamageFlags)
    ---@type EntityPlayer
    local Player = Entity:ToPlayer()
    if DamageFlags == AddFlag(7,28) or 
        DamageFlags == AddFlag(16,28) or 
        DamageFlags == AddFlag(5,13) or 
        DamageFlags == AddFlag(5,21) or 
        DamageFlags == AddFlag(5,13,18) or 
        DamageFlags == AddFlag(2,28,30) or 
        DamageFlags == AddFlag(2,28,30) or 
        DamageFlags == AddFlag(5) or 
        Player:GetPlayerType() ~= Minusaac then
        return
    end
    local Data = Player:GetData().RepMinus.StatsDowns
    Data.MoveSpeed = Data.MoveSpeed - 0.1
    Data.Damage = Data.Damage - 0.15
    Data.MaxFireDelay = Data.MaxFireDelay - 0.65
    Data.TearRange = Data.TearRange - 6
    Player:AddCacheFlags(CacheFlag.CACHE_ALL,true)
end,EntityType.ENTITY_PLAYER)

local Test2Item = Isaac.GetItemIdByName("Book of necromancer")
---@param Player EntityPlayer
---@param RNG RNG
mod:AddCallback(ModCallbacks.MC_USE_ITEM,function (_,_,RNG,Player)
    local Flags = (1<<29) + (1<<8) + (1<<37) + (1<<59) + (1<<19)
    if RNG:RandomInt(2) == 1 then
        for _=1,2 do
            Isaac.Spawn(EntityType.ENTITY_BONY,0,0,Player.Position + Vector(0,5):Rotated(math.random(360)),Vector(0,0),Player):ToNPC():AddEntityFlags(Flags)
        end
    else
        for _=1,2 do
            Isaac.Spawn(EntityType.ENTITY_BOOMFLY,4,0,Player.Position + Vector(0,5):Rotated(math.random(360)),Vector(0,0),Player):ToNPC():AddEntityFlags(Flags)
        end
    end
    return true
end,Test2Item)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,function ()
    ---@type EntityPlayer Player
    local Player = Isaac.GetPlayer(0)
    ---@type Entity Entity
    for _,Entity in pairs(Isaac.GetRoomEntities()) do
        if Entity:HasEntityFlags((1<<29) + (1<<8) + (1<<37) + (1<<59) + (1<<19)) then
            Entity.Position = Player.Position
        end
    end
end)


local Items = {
    Mama = {
        ID = Isaac.GetItemIdByName("VHS cassette")
    }
}
local Amount = 0
function mod:onShaderParams(shaderName)
if shaderName == 'RandomColors' then
for i = 0, game:GetNumPlayers() - 1 do
        Amount = Amount * 0.9 + (Isaac.GetPlayer(i):HasCollectible(Items.Mama.ID) and 0 or 0.1)
end
        local params = { 
                    Amount = Amount 
            }
        return params;
	end
end 

function mod:updateCache(_player, cacheFlag)
    local player = Isaac.GetPlayer(0)
	if cacheFlag == CacheFlag.CACHE_SPEED then
	    if player:HasCollectible(Items.Mama.ID) then 
		    player.MoveSpeed = player.MoveSpeed +0.4
		end
	end
end 
mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.onShaderParams) 
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache)
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
 if tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer() then
    if tear.SpawnerEntity:ToPlayer():HasCollectible(Items.Mama.ID) then
      tear.CollisionDamage = tear.CollisionDamage + tear:GetDropRNG():RandomInt(4)
    end
  end
end)



local music = MusicManager()

CollectibleType.COLLECTIBLE_EXECUTIONER_HELMET = Isaac.GetItemIdByName("Executioner helmet")
Music.MUSIC_MAESTRO = Isaac.GetMusicIdByName("BFG")

function mod:onUpdate_ExHelmet(player)

	if music:GetCurrentMusicID() ~= Music.MUSIC_MAESTRO
	and player:GetActiveItem() == CollectibleType.COLLECTIBLE_EXECUTIONER_HELMET
	then
		music:Play(Music.MUSIC_MAESTRO, 0.5)
	end 
end 

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.onUpdate_ExHelmet)


TrinketType.TRINKET_HAM = Isaac.GetTrinketIdByName("Hammer")

function mod:onCache(player, flag)
	if flag == CacheFlag.CACHE_TEARFLAG and player:HasTrinket(TrinketType.TRINKET_HAM) then
		player.TearFlags = player.TearFlags | TearFlags.TEAR_ACID
	end 
end 

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.onCache)

local Thumper = {}
Thumper.type = Isaac.GetEntityTypeByName("Thumper")
Thumper.variant = Isaac.GetEntityVariantByName("Thumper")
Thumper.regularProjectileVelocity = 9
Thumper.regularProjectileSpread = 15
Thumper.shotSpread = 45
Thumper.shotSpeed = 1 --6.5
Thumper.shotDistance = -10

function Thumper.OnShooting (_,shot)
  if shot.SpawnerType == Thumper.type and shot.SpawnerVariant == Thumper.variant then
    shot.ProjectileFlags = ProjectileFlags.SMART 
  end
end

mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT ,Thumper.OnShooting)

local ROt = Isaac.GetItemIdByName("Rot")
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,function ()
    for i = 1, game:GetNumPlayers() do
        ---@type EntityPlayer
        local Player = Isaac.GetPlayer(i-1)
        ---@type {GasesCountDown: number}
        local Data = Player:GetData()
        if Player:HasCollectible(ROt) then
            Data.GasesCountDown = 240
        end
    end
end)
---@param Player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE,function (_,Player)
    ---@type {GasesCountDown: number}
    local Data = Player:GetData()
    if Data.GasesCountDown ~= nil and Data.GasesCountDown > 0 and not game:GetLevel():GetCurrentRoom():IsClear() then
        if Data.GasesCountDown % 30 == 0 then
            ---@type EntityEffect
            local Effect = Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.SMOKE_CLOUD,0,Player.Position,Vector(0,0),Player):ToEffect()
            Effect:SetDamageSource(EntityType.ENTITY_PLAYER)
            Effect:SetTimeout(300)
        end
        Data.GasesCountDown = Data.GasesCountDown - 1
    end
end)



function AddFlag(...)
    local ToReturn = 0
    for _,a in pairs({...}) do
        ToReturn = ToReturn + (1 << a)
    end
    return ToReturn
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,function (_,Player,Cache)
    local Data = Player:GetData().RepMinus
    if Data == nil or (Player:GetData().RepMinus ~= nil and Player:GetData().RepMinus.MinusShard == nil) then
        return
    end
    Data = Player:GetData().RepMinus.MinusShard
    if Cache == CacheFlag.CACHE_SPEED then
        Player.MoveSpeed = Player.MoveSpeed + Data.MoveSpeed
    end
    if Cache == CacheFlag.CACHE_DAMAGE then
        Player.Damage = Player.Damage + Data.Damage
    end
    if Cache == CacheFlag.CACHE_FIREDELAY then
        Player.MaxFireDelay = Player.MaxFireDelay - Data.MaxFireDelay
    end
    if Cache == CacheFlag.CACHE_RANGE then
        Player.TearRange = Player.TearRange + Data.TearRange
    end
end)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,function (_,Entity,_,DamageFlags)
    if DamageFlags & DamageFlag.DAMAGE_NO_PENALTIES == DamageFlag.DAMAGE_NO_PENALTIES or 
        DamageFlags & DamageFlag.DAMAGE_FAKE == DamageFlag.DAMAGE_FAKE or 
        DamageFlags & DamageFlag.DAMAGE_RED_HEARTS == DamageFlag.DAMAGE_RED_HEARTS then
        return
    end
    local Player = Entity:ToPlayer()
    local Data = Player:GetData().RepMinus
    if Data == nil or (Data ~= nil and Data.MinusShard == nil) or (Data ~= nil and Data.MinusShard ~= nil and Data.MinusShard.Rooms <= 0) then 
        return
    end
    Player:SetColor(Color(1,1,1,1,1,0,0),15,0,true,true)
    Data.MinusShard.Sprite:Play("Damaged",true)
    Data.MinusShard.Rooms = Data.MinusShard.Rooms - 1
    local Effect = Isaac.Spawn(EntityType.ENTITY_EFFECT,97,0,Player.Position,Vector(0,0),Player)
    Effect.Color = Color(0.75,0,0,1)
    Effect.SpriteScale = Vector(2,2)
    SFXManager():Play(175,1.25,0,false,math.random(155,175)/100)
end,EntityType.ENTITY_PLAYER)

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,function ()
    for i=1,game:GetNumPlayers() do
        local Player = Isaac.GetPlayer(i-1)
        local Data = Player:GetData().RepMinus
        if (Data ~= nil and Data.MinusShard ~= nil and Data.MinusShard.Rooms > 0) then 
            SFXManager():Play(268,1,0,false,1.5)
            Player:SetColor(Color(1,1,1,1,0,1,0),15,0,true,true)
            Data = Data.MinusShard
            Data.Rooms = Data.Rooms - 1
            Data.MoveSpeed = Data.MoveSpeed + 0.1
            Data.Damage = Data.Damage + 0.85
            Data.MaxFireDelay = math.min(Data.MaxFireDelay + 1.1,4)
            Data.TearRange = Data.TearRange + 25
            Player:AddCacheFlags(CacheFlag.CACHE_ALL,true)
        end
    end
end)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER,function ()
    for i=1,game:GetNumPlayers() do
        local Player = Isaac.GetPlayer(i-1)
        local Data = Player:GetData().RepMinus
        if Data ~= nil and (Data ~= nil and Data.MinusShard ~= nil) and Data.MinusShard.Sprite ~= nil then
            Data.MinusShard.Sprite:Render(Isaac.WorldToScreen(Player.Position))
            Data.MinusShard.Sprite:Update()
            if Data.MinusShard.Sprite:IsFinished("Fade") then
                Data.MinusShard.Sprite = nil
            end 
            if Data.MinusShard.Sprite ~= nil then
                if Data.MinusShard.Sprite:IsFinished("Damaged") then
                    Data.MinusShard.Sprite:Play("Idle",true)
                end 
                if not Data.MinusShard.Sprite:IsPlaying("Fade") and Data.MinusShard.Rooms <= 0 then
                    Data.MinusShard.Sprite:Play("Fade",true)
                end
            end
        end
    end
end)
---@param Player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_CARD,function (_,_,Player)
    local Data = Player:GetData()
    if Data.RepMinus == nil then 
        Data.RepMinus = {}
    end
    if Data.RepMinus.MinusShard == nil then
        Data.RepMinus.MinusShard = {
            Rooms = 0,
            Damage = 0,
            MoveSpeed = 0,
            MaxFireDelay = 0,
            TearRange = 0,
            Sprite = Sprite()
        }
    end
    Data.RepMinus.MinusShard.Sprite = Sprite()
    Data.RepMinus.MinusShard.Sprite:Load("gfx/MinusStatus.anm2",true)
    Data.RepMinus.MinusShard.Sprite:Play("Idle",true)

    Data.RepMinus.MinusShard.Rooms = Data.RepMinus.MinusShard.Rooms + 2
    local Effect = Isaac.Spawn(EntityType.ENTITY_EFFECT,16,1,Player.Position,Vector(0,0),Player)
    Effect.Color = Color(0.75,0,0,0.5)
    for _=1,12 do
        local Effect = Isaac.Spawn(EntityType.ENTITY_EFFECT,35,1,Player.Position,Vector(0,math.random(3,9)):Rotated(math.random(360)),Player)
        Effect.Color = Color(0.75,0,0,1)
        Effect.SpriteScale = Vector(0.75,0.75)
    end
    Player:SetColor(Color(1,1,1,1,1,0,0),60,0,true,true)
    SFXManager():Play(33,1,0,false,1.5)
    local Data = Player:GetData().RepMinus.MinusShard
    Data.MoveSpeed = Data.MoveSpeed - 0.1
    Data.Damage = Data.Damage - 0.75
    Data.MaxFireDelay = Data.MaxFireDelay - 1
    Data.TearRange = Data.TearRange - 25
    Player:AddCacheFlags(CacheFlag.CACHE_ALL,true)
end,Isaac.GetCardIdByName("MinusShard"))

--------------------------------------------------------------
--Frozen Flies
--------------------------------------------------------------
CollectibleType.COLLECTIBLE_TSUNDERE_FLY = Isaac.GetItemIdByName("Frozen Flies")

local tsunFlyVar = Isaac.GetEntityVariantByName("Tsun_Fly")
local tsunOrbitDistance = Vector(30.0, 30.0)
local tsunOrbitLayer = 127
local tsunOrbitSpeed = 0.02
local tsunCenterOffset = Vector(0.0, 0.0)
local whiteColor = Color(1, 1, 1, 1, 0, 0, 0)
whiteColor:SetColorize(1, 1, 1, 1)
whiteColor:SetTint(20, 20, 20, 2)

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cache_flag)
    if cache_flag == CacheFlag.CACHE_FAMILIARS then
        local familiar_count = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_TSUNDERE_FLY) * 2
        --print(familiar_count)
        player:CheckFamiliar(tsunFlyVar, familiar_count, player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TSUNDERE_FLY))
    end
end
)

mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, orbital)
    orbital.OrbitDistance = tsunOrbitDistance
    orbital.OrbitSpeed = tsunOrbitSpeed
    orbital:AddToOrbit(tsunOrbitLayer)
end, tsunFlyVar)


mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, function(_, familiar, collider, low)
    if collider:IsVulnerableEnemy() then
        local player = familiar.Player
        if player and player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
            collider:TakeDamage(2, 0, EntityRef(familiar), 1)
        else
            collider:TakeDamage(1, 0, EntityRef(familiar), 1)
        end
    elseif collider:ToProjectile() ~= nil then
        local loopInt = 1
        local player = familiar.Player
        if player and player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
            loopInt = 2
        end
        for i=1, loopInt, 1 do
            local tear = familiar:FireProjectile(collider.Velocity * Vector(-1, -1))
            tear.Velocity = collider.Velocity * Vector(-1, -1)
            tear.Position = collider.Position
            tear.CollisionDamage = collider.CollisionDamage
            --tear:AddTearFlags(TearFlags.TEAR_ICE)
            tear:AddTearFlags(TearFlags.TEAR_HOMING)
            tear:GetData().RepMinusWillFreeze = true
            collider:Remove()
        end
    end
end, tsunFlyVar)


mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, orbital)
    orbital.OrbitDistance = tsunOrbitDistance
    orbital.OrbitSpeed = tsunOrbitSpeed
    local center_pos = (orbital.Player.Position + orbital.Player.Velocity) + tsunCenterOffset
    local orbit_pos = orbital:GetOrbitPosition(center_pos)
    orbital.Velocity = orbit_pos - orbital.Position
end, tsunFlyVar)


mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, tear, collider, low)
    if tear:GetData().RepMinusWillFreeze == true and collider:IsVulnerableEnemy() and not collider:IsBoss() then
        collider:AddEntityFlags(EntityFlag.FLAG_ICE)
        tear.CollisionDamage = 9999
    elseif tear:GetData().RepMinusWillFreeze == true and collider:IsVulnerableEnemy() and collider:IsBoss() then
        collider:AddSlowing(EntityRef(tear), 30, 0.5, collider.Color)
    end
end)

----------------------------------------------------
--SAVE MANAGER
----------------------------------------------------

function mod:AnyPlayerDo(foo)
	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		foo(player)
	end
end


function mod:saveData()
    local numPlayers = game:GetNumPlayers()
    saveTable.PlayerData = {}

    saveTable.MenuData = mod.MenuData

    for i=0, numPlayers-1, 1 do
        local player = Isaac.GetPlayer(i)

        if not player:GetData().repmSaveData then
            player:GetData().repmSaveData = {}
        end

        saveTable.PlayerData[tostring(player:GetCollectibleRNG(1):GetSeed())] = player:GetData().repmSaveData
    end
    local jsonString = json.encode(saveTable)
    mod:SaveData(jsonString)
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.saveData)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.saveData)

function mod:loadData(isSave)
    if mod:HasData() then
        local perData = json.decode(mod:LoadData())
        mod.MenuData = perData.MenuData
    end
    if mod:HasData() and isSave then
        local numPlayers = game:GetNumPlayers()
        saveTable = json.decode(mod:LoadData())
        for i=0, numPlayers-1, 1 do
            local player = Isaac.GetPlayer(i)
            if saveTable.PlayerData[tostring(player:GetCollectibleRNG(1):GetSeed())] then
                player:GetData().repmSaveData = saveTable.PlayerData[tostring(player:GetCollectibleRNG(1):GetSeed())]
            end
            player:AddCacheFlags(CacheFlag.CACHE_ALL)
            player:EvaluateItems()
        end
    else
        saveTable = {}
        mod:AnyPlayerDo(function(player)
        player:AddCacheFlags(CacheFlag.CACHE_ALL)
        player:EvaluateItems()
        end)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.loadData)

function mod:repmGetPData(player)
    local data = player:GetData()
    if data.repmSaveData == nil then
        data.repmSaveData = {}
    end
    return data.repmSaveData
end

--------------------------------------------------------------
--FROSTY
--------------------------------------------------------------

local frostType = Isaac.GetPlayerTypeByName("Frosty", false)
local polaroidTrinket = Isaac.GetTrinketIdByName("Frozen Polaroid")

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    mod:AnyPlayerDo(function(player)
        if player:GetPlayerType() == frostType then
            local pdata = mod:repmGetPData(player)
            pdata.FrostDamageDebuff = 0
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end
    end)
end)

local percentFreezePerSecond = 42 --chance to freeze every second
local frostRNG = RNG()
local frameBetweenDebuffs = 150 -- 30 frames per second
local damageDownPerDebuff = 0.40
local lastFrame = 0
local minFrameFreeze = 30 -- 1 second
local maxFrameFreeze = 900 -- 30 seconds

local blueColor = Color(0.67, 1, 1, 1, 0, 0, 0)
blueColor:SetColorize(1, 1, 3, 1)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    local pdata = mod:repmGetPData(player)
    if player:GetPlayerType() == frostType then
        local frame = game:GetFrameCount()
        if frame % 30 == 0  and frame ~= lastFrame then
            lastFrame = frame
            local room = game:GetRoom()
            if frame % frameBetweenDebuffs == 0 and not game:IsGreedMode() then
                if not room:IsClear() and game:GetRoom():GetType() ~= RoomType.ROOM_BOSS and game:GetRoom():GetType() ~= RoomType.ROOM_MINIBOSS then
                    pdata.FrostDamageDebuff = (pdata.FrostDamageDebuff or 0) + 1
                elseif room:IsClear() then
                    pdata.FrostDamageDebuff = 0
                end
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                player:EvaluateItems()
            end
        end
    end
    if pdata.HoldingFrozenPolaroid ~= player:HasTrinket(polaroidTrinket) then
        
        if player:HasTrinket(polaroidTrinket) then
            hiddenItemManager:Add(player, CollectibleType.COLLECTIBLE_MORE_OPTIONS)
            hiddenItemManager:Add(player, CollectibleType.COLLECTIBLE_STEAM_SALE)
            local optionsConfig = config:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS)
            local steamConfig = config:GetCollectible(CollectibleType.COLLECTIBLE_STEAM_SALE)
            player:RemoveCostume(optionsConfig)
            player:RemoveCostume(steamConfig)
        elseif pdata.HoldingFrozenPolaroid == nil and player:HasTrinket(polaroidTrinket) == false then
            pdata.HoldingFrozenPolaroid = false -- redundant, i know
        else

            hiddenItemManager:Remove(player, CollectibleType.COLLECTIBLE_MORE_OPTIONS, hiddenItemManager.kDefaultGroup)
            hiddenItemManager:Remove(player, CollectibleType.COLLECTIBLE_STEAM_SALE, hiddenItemManager.kDefaultGroup)
        end
        pdata.HoldingFrozenPolaroid = player:HasTrinket(polaroidTrinket)
    end

end)


mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function(_) 
    local hasIt = false
    local frame = game:GetFrameCount()

    if not startingFrame then
        startingFrame = game:GetFrameCount()
    end

    mod:AnyPlayerDo(function(player)
        if player:GetPlayerType() == frostType or saveTable.Repm_Iced then
            hasIt = true
        end
    end)
    if hasIt and game:GetRoom():GetAliveEnemiesCount() >= 1 then
        local entities = Isaac.GetRoomEntities()
        for i=1, #entities do
            local entity = entities[i]
            if entity:IsVulnerableEnemy() and not entity:IsBoss() and (entity:GetEntityFlags() & EntityFlag.FLAG_CHARM ~= EntityFlag.FLAG_CHARM) and (entity:GetEntityFlags() & EntityFlag.FLAG_FRIENDLY ~= EntityFlag.FLAG_FRIENDLY) then
                if not entity:GetData().RepM_Frosty_FreezePoint then
                    local num = frostRNG:RandomInt(maxFrameFreeze-minFrameFreeze)
                    num = num + minFrameFreeze
                    entity:GetData().RepM_Frosty_FreezePoint = game:GetFrameCount() + num
                    entity:GetData().RepM_Frosty_StartPoint = game:GetFrameCount()
                end
                local freezepoint = entity:GetData().RepM_Frosty_FreezePoint
                local startingFrame = entity:GetData().RepM_Frosty_StartPoint
                if game:GetFrameCount() >= freezepoint then
                    entity:AddEntityFlags(EntityFlag.FLAG_ICE)
                    entity:TakeDamage(9999, 0, EntityRef(player), 1)
                else
                    local framesToFreeze = freezepoint - startingFrame --how long the enemy survives before freezing
                    local progress = game:GetFrameCount() - startingFrame
                    local progressAmt = progress/framesToFreeze
                    local color = Color.Lerp(Color.Default, blueColor, progressAmt)
                    entity:AddSlowing(EntityRef(player), 20, 0.8, color)
                end
            end
        end
    end
end)

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheflag)
    local pdata = mod:repmGetPData(player)
    if cacheflag == CacheFlag.CACHE_DAMAGE then
        local damageDebuff = (pdata.FrostDamageDebuff or 0)
        if game:IsGreedMode() then
            damageDebuff = damageDebuff / 2
        end
        player.Damage = player.Damage - (damageDebuff * damageDownPerDebuff)
    end
end)

mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, function(_, shaderName)
    if REPENTOGON and shaderName == "REPMEmptyShader" then
        local entities = Isaac.GetRoomEntities()
        for i, npc in ipairs(entities) do
            if npc:GetData().RepM_Frosty_FreezePoint ~= nil and npc:IsVulnerableEnemy() and not game:IsPaused() then
                if not npc:GetData().RepM_Frosty_Sprite then
                    npc:GetData().RepM_Frosty_Sprite = Sprite()
                    npc:GetData().RepM_Frosty_Sprite:Load("gfx/chill_status.anm2",true)
                    npc:GetData().RepM_Frosty_Sprite:Play("Idle")
                end
                local position = Isaac.WorldToScreen(npc.Position+npc:GetNullOffset("OverlayEffect"))--
                --print(tostring(position.X) .. " " .. tostring(position.Y))
                npc:GetData().RepM_Frosty_Sprite:Render(position)
                npc:GetData().RepM_Frosty_Sprite:Update()
                --print("ding!")
            end
        end
    end
end)

if REPENTOGON then
    local FrostyAchId = Isaac.GetAchievementIdByName("Frosty")
    local DeathCardAchId = Isaac.GetAchievementIdByName("FrostySatan")
    local FrozenHeartsAchId = Isaac.GetAchievementIdByName("FrozenHearts")
    local ImprovedCardsAchId = Isaac.GetAchievementIdByName("improved_cards")
    local NumbHeartAchId = Isaac.GetAchievementIdByName("NumbHeart")
    --Isaac.GetPersistentGameData():TryUnlock(FrostyAchId)
end

function mod:Anm()
    if game:GetFrameCount() == 1 and mod.MenuData.StartThumbsUp ~= 2 then
        local player = Isaac.GetPlayer(0)
        player:AnimateHappy()
    end 
end 

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.Anm)

--------------------------------------------------------------------------
--FROZEN POLAROID
--------------------------------------------------------------------------



function mod:stickyTrinket(pickup, collider, low)
    if not collider:ToPlayer() or not collider:ToPlayer():HasTrinket(polaroidTrinket) then
        return nil
    end
    local player = collider:ToPlayer()
    if player:GetTrinket(0) ~= polaroidTrinket and player:GetTrinket(1) ~= polaroidTrinket then
        return nil
    end

    if player:GetMaxTrinkets() > 1 then
        if player:GetTrinket(0) == polaroidTrinket and player:GetTrinket(1) ~= 0 then
            local trinketDrop = player:GetTrinket(1)
            player:TryRemoveTrinket(trinketDrop)
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinketDrop, player.Position, Vector(0, 0), nil)
            return nil
        elseif player:GetTrinket(1) == polaroidTrinket and player:GetTrinket(0) ~= 0 then
            local trinketDrop = player:GetTrinket(0)
            player:TryRemoveTrinket(trinketDrop)
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinketDrop, player.Position, Vector(0, 0), nil)
            return nil
        else
            return nil
        end
    else
        return false
    end
    
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.stickyTrinket, PickupVariant.PICKUP_TRINKET)

function mod:tryOpenDoor_Fro_Polaroid(player)
    --and player:CollidesWithGrid() 
    if game:GetLevel():GetStage() == 6 and game:GetLevel():GetStageType() <= 2 
    and player.Position.Y < 151 and player.Position:Distance(Vector(320, 150)) <=26
    and game:GetLevel():GetCurrentRoomIndex() == 84 and player:HasTrinket(polaroidTrinket) then
        local door = game:GetRoom():GetDoor(1)
        if not door:IsOpen() then
            door:TryUnlock(player, true)
            player:TryRemoveTrinket(polaroidTrinket)
            saveTable.repM_FrostyUnlock = true
        end
    end
    if player:HasTrinket(polaroidTrinket) and player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_ITEMSDROPPED == ActionTriggers.ACTIONTRIGGER_ITEMSDROPPED then
        player:AddTrinket(polaroidTrinket)
        local trinkets = Isaac.FindByType(5, 350, 195)
        for i, trinket in ipairs(trinkets) do
            trinket:Remove()
            break
        end -- not a great solution but let's see
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.tryOpenDoor_Fro_Polaroid)
--5 350 195
function mod:DebugText()
    local player = Isaac.GetPlayer(0) --this one is OK
    local coords = (player.Position):Distance(Vector(320, 150))
    --local coords = player.Position
    local debug_str = tostring(player.Position)
    --26
    Isaac.RenderText(debug_str, 100, 60, 1, 1, 1, 255)

end
--mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.DebugText)


function mod:OnEntitySpawn_Polar(npc)
    local chosenPlayer
    mod:AnyPlayerDo(function(player)
        if player:HasTrinket(polaroidTrinket) then
            chosenPlayer = player
        end
    end)
    if chosenPlayer ~= nil then
        if not npc:IsChampion() and not npc:IsBoss() and globalRng:RandomInt(8) == 1 then
            npc:MakeChampion(globalRng:GetSeed())
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.OnEntitySpawn_Polar)


function mod:OnTakeHit_Polar(entity, amount, damageflags, source, countdownframes)
    local player = entity:ToPlayer()
    if player == nil then
        return
    end
    local data = mod:repmGetPData(player)
    if amount == 1 and player:HasTrinket(polaroidTrinket) and not data.inPolaroidDamage then
        data.inPolaroidDamage = true
        player:TakeDamage(amount, damageflags, source, countdownframes)
    end
    data.inPolaroidDamage = nil
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnTakeHit_Polar, EntityType.ENTITY_PLAYER)


-----------------------------------------------------------------
--frosty unlock
------------------------------------------------------------------
local iceCard = Isaac.GetCardIdByName("Icicle")


function mod:OnBossDefeat_Frosty(rng, spawn)
    if REPENTOGON then
        FrostyAchId = Isaac.GetAchievementIdByName("Frosty")
        if not Isaac.GetPersistentGameData():Unlocked(FrostyAchId) and
        game:GetRoom():GetType() == RoomType.ROOM_BOSS and
        game:GetLevel():GetStage() == 1 and
        game:GetLevel():GetStageType() <= 2 and saveTable.repm_picSpawned ~= true then
            local spawnPos = game:GetRoom():FindFreePickupSpawnPosition(game:GetRoom():GetCenterPos())
            Isaac.Spawn(5, 350, polaroidTrinket, spawnPos, Vector.Zero, nil)
            saveTable.repm_picSpawned = true
        end
    end
    saveTable.Repm_Iced = false
end
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.OnBossDefeat_Frosty)

function mod:OnEnterSecretExit()
    saveTable.Repm_Iced = false
    local room = game:GetRoom()
    if room:GetType() == RoomType.ROOM_SECRET_EXIT and game:GetLevel():GetStage() == 6 
    and game:GetLevel():GetStageType() <= 2 and REPENTOGON and saveTable.repM_FrostyUnlock then
        --room:SetBackdropType(BackdropType.BLUE_WOMB_PASS, 3)
        for i=1, room:GetGridSize() do
            local ge = room:GetGridEntity(i)
            if ge and ge.Desc.Type ~= 16 then
                room:RemoveGridEntity(i, 0)
            end
        end
        if room:IsFirstVisit() then
            local items = Isaac.FindByType(5, 100)
            for i, item in ipairs(items) do
                item:Remove()
            end
            Isaac.Spawn(6, 14, 0, room:GetCenterPos(), Vector.Zero, nil)
        end

        local frosties = Isaac.FindByType(6, 14)
        for i, dude in ipairs(frosties) do
            dude:GetSprite():ReplaceSpritesheet(0, "gfx/characters/costumes/character_frosty.png")
            dude:GetSprite():LoadGraphics()
        end
    --elseif game:GetRoom():GetType() == RoomType.ROOM_BOSS and game:GetLevel():GetStage() == 6 and saveTable.repM_FrostyUnlock then
        --room:TrySpawnBossRushDoor()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnEnterSecretExit)


function mod:UseIcicle(card, player, useflags)
    if game:GetRoom():GetType() == RoomType.ROOM_BOSS and
    game:GetLevel():GetStage() == 6 and REPENTOGON and not room:IsClear() then
        saveTable.repM_FrostyUnlock = true
        local entities = Isaac.GetRoomEntities()
        for i, npc in ipairs(entities) do
            if npc:IsVulnerableEnemy() and npc:IsBoss() then
                npc:TakeDamage(9999, 0, EntityRef(player), 1)
            elseif npc:IsVulnerableEnemy() then
                npc:AddEntityFlags(EntityFlag.FLAG_ICE)
                npc:TakeDamage(9999, 0, EntityRef(player), 1)
            end
        end
        game:GetRoom():TrySpawnBossRushDoor()
    elseif not room:IsClear() then
        saveTable.Repm_Iced = true
    end
end
--mod:AddCallback(ModCallbacks.MC_USE_CARD, mod.UseIcicle, iceCard)

--MC_PRE_PLAYER_COLLISION

function mod:onCollisionSecret(player, collider, low)
    if collider.Type == 6 and collider.Variant == 14 and game:GetRoom():GetType() == RoomType.ROOM_SECRET_EXIT then
        FrostyAchId = Isaac.GetAchievementIdByName("Frosty")
        Isaac.GetPersistentGameData():TryUnlock(FrostyAchId)
        Isaac.GetPersistentGameData():TryUnlock(FrozenHeartsAchId)
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, mod.onCollisionSecret)



----------------------------------------------------------
function mod:whenSpawningCreep_IceHeart(player)
    local pdata = mod:repmGetPData(player)
    if pdata.isIceheartCrept and game:GetFrameCount() % 3 == 0 then
        local creep = Isaac.Spawn(1000, 54, 0, player.Position, Vector.Zero, player):ToEffect()
        creep.Scale = 0.65
        --creep:SetTimeout(15)
        creep:Update()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.whenSpawningCreep_IceHeart)

function mod:disableCreepRoom()
    mod:AnyPlayerDo(function(player)
        local pdata = mod:repmGetPData(player)
        pdata.isIceheartCrept = nil
    end)
    
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.disableCreepRoom)


----------------------------------------------------------

function mod:onGreedUpdate_RepM()
    if game:IsGreedMode() and saveTable.REPM_GreedWave ~= game:GetLevel().GreedModeWave then
        mod:AnyPlayerDo(function(player)
            if player:GetPlayerType() == frostType then
                local pdata = repmGetPData(player)
                pdata.FrostDamageDebuff = (pdata.FrostDamageDebuff or 0) + 1
            end
        end)
        saveTable.REPM_GreedWave = game:GetLevel().GreedModeWave
    end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onGreedUpdate_RepM)

----------------------------------------------------------
--FOUNTAIN
----------------------------------------------------------
local fountainType = Isaac.GetEntityVariantByName("Fountain of Confession")
local fountainSound = Isaac.GetSoundIdByName("fountain")

local function playerToNum(player)
	for num = 0, game:GetNumPlayers()-1 do
		if GetPtrHash(player) == GetPtrHash(Isaac.GetPlayer(num)) then return num end
	end
end

local function killFount(fount)
    fount:GetSprite():Play("Death")
end

function mod:numToPlayer(num)
	for i = 0, game:GetNumPlayers()-1 do
        local player = Isaac.GetPlayer(i)
		if GetPtrHash(player) == GetPtrHash(Isaac.GetPlayer(num)) then return player end
	end
end

local isFountPlaying = false

function mod:fountUpdate()
	local founts = Isaac.FindByType(EntityType.ENTITY_SLOT, fountainType)
    local anyInRadius = false
	for _,fount in pairs(founts) do
		if fount:GetSprite():IsFinished("Initiate") then fount:GetSprite():Play("Wiggle")	end
		if fount:GetSprite():IsFinished("Wiggle") then fount:GetSprite():Play("Prize") end
        if fount:GetSprite():IsFinished("Death") then 
            fount:GetSprite():Play("Broken") 
            fount:Die()
        end
		if fount:GetSprite():IsFinished("Prize") then
            local dropRNG = fount:GetDropRNG()
            local breakOutcome = dropRNG:RandomInt(100)
            if breakOutcome <= 15 then
                fount:GetSprite():Play("Death")
            else
                fount:GetSprite():Play("Idle")
            end
			fount:GetData()["Playing Player"] = nil
		end

        if fount:GetSprite():IsEventTriggered("Explosion") then
            local exp = Isaac.Spawn(1000, 1, 0, fount.Position, Vector.Zero, fount)
            exp:GetData().FountCaused_REPM = true
        end 

        if fount:GetSprite():IsEventTriggered("Prize") then
            local outcome = fount:GetData().Slot_Outcome or 99
            if outcome <= 5 then
                sfx:Play(SoundEffect.SOUND_LUCKYPICKUP, 1.0, 0, false, 1.0)
                Isaac.Spawn(5, 300, 20, fount.Position, Vector(0, 1), fount)
            elseif outcome <= 15 then
                local player = mod:numToPlayer(fount:GetData()["Playing Player"])
                --player:AddSoulHearts(2)
                --SfxManager:Play(SoundEffect.SOUND_THUMBSUP, 2)
                --player:AnimateHappy()
                local pdata = mod:repmGetPData(player)
                pdata.repMBonusDamage = (pdata.repMBonusDamage or 0) + 0.5
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)  
                player:EvaluateItems() 
                player:AnimateHappy()
                sfx:Play(SoundEffect.SOUND_THUMBSUP, 2)
            else
                local player = mod:numToPlayer(fount:GetData()["Playing Player"])
                local pdata = mod:repmGetPData(player)
                pdata.repMBonusLuck = (pdata.repMBonusLuck or 0) + 0.5
                player:AddCacheFlags(CacheFlag.CACHE_LUCK)  
                player:EvaluateItems() 
                player:AnimateHappy()
                sfx:Play(SoundEffect.SOUND_THUMBSUP, 2)
            end
			
		end
		if fount:GetSprite():IsEventTriggered("Disappear") then
			fount.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end

        local players = Isaac.FindInRadius(fount.Position, 100)
        for i, player in ipairs(players) do
            if player:ToPlayer() ~= nil and fount:GetSprite():GetAnimation() ~= "Broken" then
                anyInRadius = true
                if not isFountPlaying then
                    isFountPlaying = true
                    sfx:Play(fountainSound, 1, 30, true)
                end
            end
        end
	end
    if anyInRadius == false and isFountPlaying then
        isFountPlaying = false
        sfx:Stop(fountainSound)
    end
	local explosions = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION)
	for _,plosion in pairs(explosions) do
		local frame = plosion:GetSprite():GetFrame()
		if frame < 3 then -- I'm afraid of 60 vs 30 breaking an exact check
			local size = plosion.SpriteScale.X -- default is 1, can be increased
			local nearby = Isaac.FindInRadius(plosion.Position, 75*size)
			for _,v in pairs(nearby) do
                if v.Type == EntityType.ENTITY_SLOT and 
                    v.Variant == fountainType and 
                    v:GetSprite():GetAnimation() ~= "Broken" and
                    v:GetSprite():GetAnimation() ~= "Death" and
                    plosion:GetData().FountCaused_REPM ~= true then
                        killFount(v)
                end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.fountUpdate)


function mod:donationFount(player, fount, low)
	if fount.Type == EntityType.ENTITY_SLOT and fount.Variant == fountainType then
		if fount:GetSprite():IsPlaying("Idle") and player:GetNumCoins() > 4 and (not REPENTOGON or fount:ToSlot():GetState() ~= -1) then
			player:AddCoins(-5)
			SFXManager():Play(SoundEffect.SOUND_SCAMPER, 1.0, 0, false, 1.0)
			fount:GetSprite():Play("Initiate")
			fount:GetData()["Playing Player"] = playerToNum(player)
			if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
				fount:GetData()["Playing Player"] = playerToNum(player:GetMainTwin())
			end
            local droprng = fount:GetDropRNG()
            fount:GetData().Slot_Outcome = droprng:RandomInt(100)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, mod.donationFount)

function mod:updateCache_Fountain(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        local pdata = mod:repmGetPData(player)
        player.Damage = player.Damage + (pdata.repMBonusDamage or 0)
    elseif cacheFlag == CacheFlag.CACHE_LUCK then
        local pdata = mod:repmGetPData(player)
        player.Luck = player.Luck + (pdata.repMBonusLuck or 0)
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.updateCache_Fountain)

----------------------------------------------------------
--RED LIGHT GREEN LIGHT
----------------------------------------------------------
local redLightChallenge = Isaac.GetChallengeIdByName("Traffic Light")

function mod:trafficRender()
    if Isaac.GetChallenge() == redLightChallenge then
        if not saveTable.RedLightSprite then
            saveTable.RedLightSprite = Sprite()
            saveTable.RedLightSprite:Load("gfx/trafficlight.anm2", true)
            saveTable.RedLightSprite:LoadGraphics()
        end
        if not saveTable.RedLightSign then
            return
        end
        if saveTable.RedLightSprite:GetAnimation() ~= mod.RedLightSign then
            saveTable.RedLightSprite:Play(saveTable.RedLightSign)
        end
        local horiz, vert
        if REPENTOGON then -- probably a useless split but maybe we'll make this work with the map size later
            horiz = 115
            vert = 45
        else
            horiz = 115
            vert = 45
        end
        
        saveTable.RedLightSprite:Render(Vector(horiz, vert))
    end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.trafficRender)

local saveTimer

local function IsMoving(player)
    local index = player.ControllerIndex
    return Input.IsActionPressed(ButtonAction.ACTION_LEFT, index) or Input.IsActionPressed(ButtonAction.ACTION_RIGHT, index) or Input.IsActionPressed(ButtonAction.ACTION_UP, index) or Input.IsActionPressed(ButtonAction.ACTION_DOWN, index)
end

function mod:changeLights()
    local frame = game:GetFrameCount()
    if Isaac.GetChallenge() == redLightChallenge  then
        if not saveTimer then
            saveTimer = 0
            if not saveTable.RedLightSign or saveTable.RedLightSign == "GreenLight" then
                saveTable.RedLightSign = "RedLight"
            elseif saveTable.RedLightSign == "YellowLight" then
                saveTable.RedLightSign = "GreenLight"
            else
                saveTable.RedLightSign = "YellowLight"
            end
        end
        if frame > saveTimer then
            if saveTable.RedLightSign == "RedLight" then
                saveTimer = frame + globalRng:RandomInt(1350) + 300
                saveTable.RedLightSign = "GreenLight"
            elseif saveTable.RedLightSign == "YellowLight" then
                saveTimer = frame + globalRng:RandomInt(300) + 30
                saveTable.RedLightSign = "RedLight"
            else
                saveTimer = frame + 30
                saveTable.RedLightSign = "YellowLight"    
            end
        end
        mod:AnyPlayerDo(function(player)
            if saveTable.RedLightSign == "RedLight" and IsMoving(player) then
               local pdata = mod:repmGetPData(player)
               if not pdata.redLightFrame or pdata.redLightFrame < frame then
                    pdata.redLightFrame = frame + 30
                    player:TakeDamage(1, 0, EntityRef(player), 2)
               end
            end
            if frame == 0 then
                pdata.redLightFrame = nil
            end
        end)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.changeLights)

----------------------------------------------------------
--FRIENDLY ROCKS
----------------------------------------------------------
local rockType = Isaac.GetItemIdByName("Friendly Rocks")

function mod:onRockBreak(rockSubtype, position) --probably could make a callback but nah
    local hasIt = false
    local rockRNG = nil
    mod:AnyPlayerDo(function(player)
        if player:HasCollectible(rockType) then
            hasIt = true
            rockRNG = player:GetCollectibleRNG(rockType)
        end
    end)
    if hasIt and rockRNG:RandomInt(5) == 1 then
        Isaac.Spawn(3, 201, 12, position, Vector.Zero, nil)
    end
end
  
  local function rockIsBroken(position)
    local room = game:GetRoom()
    local rock = room:GetGridEntity(position)
    if not rock then
      return true
    elseif rock:ToRock() and rock.State == 2 then
      return true
    --elseif rock:ToPoop() and rock.State == 1000 then
      --return true
    else
      return false
    end
  end
  
  
  function mod:CheckRocksBreak()
    local room = game:GetRoom()
    local level = game:GetLevel()
    local newRoom = false
    if saveTable.scanRockRoom ~= level:GetCurrentRoomIndex() then
      newRoom = true
      saveTable.scanRockRoom = level:GetCurrentRoomIndex()
    end
    if not saveTable.scanRockMap then
        saveTable.scanRockMap = {}
    end
  
    for i=1, room:GetGridSize(), 1 do
      local rock = room:GetGridEntity(i)
      if newRoom then
        if rock and not rockIsBroken(i) then
            saveTable.scanRockMap[i] = rock:GetType()
        else
            saveTable.scanRockMap[i] = nil
        end
      else
        if rock and saveTable.scanRockMap[i] ~= nil and rockIsBroken(i) then
          mod:onRockBreak(saveTable.scanRockMap[i], rock.Position)
          saveTable.scanRockMap[i] = nil
        end
      end
    end
  end
  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.CheckRocksBreak)

  local numbHeartItem = Isaac.GetItemIdByName("Numb Heart")

----------------------------------------------------------
--LIKE (Item)
----------------------------------------------------------
local likeFrame = -5
local likeType = Isaac.GetItemIdByName("Like")
function mod:onPlayerUpdate_Like(player)
    if player:HasCollectible(likeType) and player:GetSprite():GetAnimation() == "Happy" and player:GetSprite():GetFrame() == 6 then
        local pdata = mod:repmGetPData(player) 
        pdata.Like_AllBonus = (pdata.Like_AllBonus or 0) + 0.5
        player:AddCacheFlags(CacheFlag.CACHE_ALL)
        player:EvaluateItems()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.onPlayerUpdate_Like)


function mod:likeCache(player, cacheFlag)
    local pdata = mod:repmGetPData(player) 
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + (0.4 * (pdata.Like_AllBonus or 0))
    elseif cacheFlag == CacheFlag.CACHE_FIREDELAY then
        local tearstoadd = (0.4 * (pdata.Like_AllBonus or 0))
        player.MaxFireDelay = tearsUp(player.MaxFireDelay, tearstoadd)
    elseif cacheFlag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + (0.4 * (pdata.Like_AllBonus or 0))
    elseif cacheFlag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + (0.4 * (pdata.Like_AllBonus or 0))
    elseif cacheFlag == CacheFlag.CACHE_RANGE then
        player.TearRange = player.TearRange + (40 * (pdata.Like_AllBonus or 0))
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.likeCache)

----------------------------------------------------------
--LOCUST KING 
----------------------------------------------------------
local locustChallenge = Isaac.GetChallengeIdByName("Locust King")

function mod:collideItemPedestalAbs(pickup, collider, low)
    local player = collider:ToPlayer()
    if player and Isaac.GetChallenge() == locustChallenge and 
    pickup.SubType ~= 0 and
    not Isaac.GetItemConfig():GetCollectible(pickup.SubType):HasTags(ItemConfig.TAG_QUEST) and
    not pickup.SubType == CollectibleType.COLLECTIBLE_MORE_OPTIONS
    then
        sfx:Play(SoundEffect.SOUND_FART, 2)
        local items = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)
        local pickupindex = pickup:ToPickup().OptionsPickupIndex
        for i, item in ipairs(items) do
            if item:ToPickup().OptionsPickupIndex == pickupindex and pickupindex ~= 0 then
                item:Remove()
            end
        end
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pickup.Position, Vector(0,0), nil)
        pickup:Remove()
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.collideItemPedestalAbs, PickupVariant.PICKUP_COLLECTIBLE)

local function doesAnyoneHave(trinket)
    local hasIt = false
    mod:AnyPlayerDo(function(player)
        if player:HasTrinket(trinket) then
            hasIt = true
        end
    end)
    return hasIt
end

function mod:onLevelStart_Locust()
    local hasIt = false
    mod:AnyPlayerDo(function(player)
        if player:HasCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) then
            hasIt = true
        end
    end)
    if Isaac.GetChallenge() == locustChallenge then
        if not hasIt then
            local itemHere = Isaac.Spawn(5, 100, CollectibleType.COLLECTIBLE_MORE_OPTIONS, Vector(160, 225), Vector.Zero, nil)
            itemHere:ToPickup().ShopItemId = -1
            itemHere:ToPickup().AutoUpdatePrice = false
            itemHere:ToPickup().Price = 20
        end

        if not doesAnyoneHave(186) then
            Isaac.Spawn(5, 350, 186, Vector(480, 225), Vector.Zero, nil)
        elseif not doesAnyoneHave(115) then
            Isaac.Spawn(5, 350, 115, Vector(480, 225), Vector.Zero, nil)
        elseif not doesAnyoneHave(114) then
            Isaac.Spawn(5, 350, 114, Vector(480, 225), Vector.Zero, nil)
        elseif not doesAnyoneHave(113) then
            Isaac.Spawn(5, 350, 113, Vector(480, 225), Vector.Zero, nil)
        elseif not doesAnyoneHave(116) then
            Isaac.Spawn(5, 350, 116, Vector(480, 225), Vector.Zero, nil)
        elseif not doesAnyoneHave(117) then
            Isaac.Spawn(5, 350, 117, Vector(480, 225), Vector.Zero, nil)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.onLevelStart_Locust)

function mod:ChallengeMarblesInit(player)
    if player and Isaac.GetChallenge() == locustChallenge then
        player:AddCollectible(CollectibleType.COLLECTIBLE_MARBLES, 0, false)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.ChallengeMarblesInit)


----------------------------------------------------------
--ACHIEVEMENT
----------------------------------------------------------
function mod:onSatanFrostyKill()
    local isFrosty = false
    mod:AnyPlayerDo(function(player)
        if player:GetPlayerType() == frostType then
            isFrosty = true
        end
    end)
    if isFrosty then
        Isaac.GetPersistentGameData():TryUnlock(DeathCardAchId)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.onSatanFrostyKill, EntityType.ENTITY_SATAN)

function mod:onBlueBabyFrostyKill(entity)
    local isFrosty = false
    mod:AnyPlayerDo(function(player)
        if player:GetPlayerType() == frostType then
            isFrosty = true
        end
    end)
    if isFrosty and entity.Variant == 1 then 
        Isaac.GetPersistentGameData():TryUnlock(NumbHeartAchId)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.onSatanFrostyKill, EntityType.ENTITY_ISAAC)


--mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.onShaderParams) 
----------------------------------------------------------
--EID, keep this at the bottom!!
----------------------------------------------------------

if EID then
    EID:addCollectible(mod.COLLECTIBLE_DONKEY_JAWBONE, DJdesc, "Donkey Jawbone", "en_us")
    EID:addCollectible(CollectibleType.COLLECTIBLE_TSUNDERE_FLY, "Spawns two fly orbitals that deflect projectiles#Deflected shots become homing, and freeze any non-boss enemy they touch.", "Frozen Flies", "en_us")
    EID:addCollectible(rockType, "Friendly Stone Dips will have a 20% chance to spawn out of rocks when they are broken.", "Friendly Rocks", "en_us")
    EID:addCollectible(numbHeartItem, "On use, adds 1 frozen heart.", "Numb Heart", "en_us")

    EID:addTrinket(Trinket.PocketTechology, "Deal 1.5x more damage to champion enemies and champion bosses", "Pocket Techology", "en_us");
    
    EID:addCard(iceCard, "Using it in most rooms slowly begins to freeze all enemies. #Non-boss enemies in the room gradually turn blue before freezing completely#Use this item in the Mom fight for a different effect...", "Icicle", "en_us")
    local iceHud = Sprite()
    iceHud:Load("gfx/cards_2_icicle.anm2", true)
    EID:addIcon("Card" .. tostring(iceCard), "HUDSmall", 0, 16, 16, 6, 6, iceHud)

end


--example: 
--EID:addCollectible(id of the item, "description of the item", "item name", "en_us(language)")