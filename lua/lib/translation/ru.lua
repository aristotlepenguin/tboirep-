return function(mod)

    local function GI(i) return Isaac.GetItemIdByName(i)>0 and Isaac.GetItemIdByName(i) or Isaac.GetTrinketIdByName(i) end

	local Collectible = {
		[GI("Friendly Rocks")]={ru={"Translated Rocks","Проклятые богатства"},},
        [GI("Like")]={ru={"Золотой Идол","Subtext goes here"},}
		--[GI('')]={ru={"",""},},	
	}
	local Trinket={
                [GI("Frozen Polaroid")]={ru={"Slammer","Стартовая рука +2"},},
                [GI('Hammer')]={ru={"Горячие Парни","Jammer"},}
	}
	local Cards={
                ['Minus Shard']={ru={"ddf","Верни свои деньги"},},
                ['Icicle']={ru={"ffd","Просто уже используй ее!"},}
        --['']={ru={"",""},},
        }

	local ModTranslate = {
		['Collectibles'] = Collectible,
		['Trinkets'] = Trinket,
		['Cards'] = Cards,
		--['Pills'] = Pills,
	}
	ItemTranslate.AddModTranslation("RepMinus", ModTranslate, {ru = true})
end