return function(mod)

local DSSModName = "Dead Sea Scrolls (Repentance-)"
    
local DSSCoreVersion = 6
    
local MenuProvider = {}
    
function MenuProvider.SaveSaveData()
    mod.StoreSaveData()
end
    
function MenuProvider.GetPaletteSetting()
    return mod.GetMenuSaveData().MenuPalette
end
    
function MenuProvider.SavePaletteSetting(var)
    mod.GetMenuSaveData().MenuPalette = var
end
    
function MenuProvider.GetGamepadToggleSetting()
    return mod.GetMenuSaveData().GamepadToggle
end
    
function MenuProvider.SaveGamepadToggleSetting(var)
    mod.GetMenuSaveData().GamepadToggle = var
end
    
function MenuProvider.GetMenuKeybindSetting()
    return mod.GetMenuSaveData().MenuKeybind
end
    
function MenuProvider.SaveMenuKeybindSetting(var)
    mod.GetMenuSaveData().MenuKeybind = var
end
    
function MenuProvider.GetMenuHintSetting()
    return mod.GetMenuSaveData().MenuHint
end
    
function MenuProvider.SaveMenuHintSetting(var)
    mod.GetMenuSaveData().MenuHint = var
end
    
function MenuProvider.GetMenuBuzzerSetting()
    return mod.GetMenuSaveData().MenuBuzzer
end
    
function MenuProvider.SaveMenuBuzzerSetting(var)
    mod.GetMenuSaveData().MenuBuzzer = var
end
    
function MenuProvider.GetMenusNotified()
    return mod.GetMenuSaveData().MenusNotified
end
    
function MenuProvider.SaveMenusNotified(var)
    mod.GetMenuSaveData().MenusNotified = var
end
    
function MenuProvider.GetMenusPoppedUp()
    return mod.GetMenuSaveData().MenusPoppedUp
end
    
function MenuProvider.SaveMenusPoppedUp(var)
    mod.GetMenuSaveData().MenusPoppedUp = var
end
    
local DSSInitializerFunction = include("lua.lib.dssmenucore")
local dssmod = DSSInitializerFunction(DSSModName, DSSCoreVersion, MenuProvider)
    
local strings = {
    Title = {
        en = "rep-",
        es = "rep-",
    },
    resume_game = {
        en = "resume game",
        ru = "вернуться в игру",
    },
    settings = {
        en = "settings",
        ru = "настройки",
    },
    yes = {
        en = "yes",
        ru = "да",
    },
    no = {
        en = "no",
        ru = "нет",
    },
    enable = {
        en = "enable",
        ru = "включен",
    },
    disable = {
        en = "disabled",
        ru = "выключен",
    },
    startTooltip = {
        en = dssmod.menuOpenToolTip,
        ru = { strset = { 'переключение', 'меню', '', 'клавиатура:', '[c] или [f1]', '', 'контроллер:', 'нажатие', 'на стик' }, fsize = 2 }
    },
    thumbs_up = {
        en = "thumbs up",
        --ru = "режим рюкзака",
    },
    tu_var1 = {
		en = "on",
		--ru = "взрывать особые",
	},
	tu_var2 = {
		en = "off",
		--ru = "бомбы в руки",
	},
}
local function GetStr(str)
    return strings[str] and (strings[str][Options.Language] or strings[str].en) or str
end


RepMMod.DSSdirectory = {
    main = {
        title = GetStr("Title"),
        format = {
        Panels = {
            {
                Panel = dssmod.panels.main,
                Offset = Vector(-42, 10),
                Color = 1
            },
            {
                Panel = dssmod.panels.tooltip,
                Offset = Vector(130, -2),
                Color = 1
            }
        }
        },
            
        buttons = {
            {str = GetStr('resume_game'), action = 'resume'},
                {str = '', nosel = true, fsize = 3},
                {
                    str = GetStr('happy_start'),
                    choices = {GetStr('tu_var1'),GetStr('tu_var2')}, 
                    variable = 'StartThumbsUp',
                    setting = 1,
                    load = function()
                        return RepMMod.MenuData.StartThumbsUp or 1
                    end,
                    store = function(var)
                        RepMMod.MenuData.StartThumbsUp = var
                        RepMMod.SpelunkersPackEffectType = var
                    end,
                },
                {str = '', nosel = true, fsize = 3},
                
            },
            tooltip = GetStr("startTooltip")  
        },
        warpzone = {
            title = GetStr('settings'),
            buttons = {
                dssmod.gamepadToggleButton,
                dssmod.menuKeybindButton,
            }
        }
    }
        
    local RepMdirectorykey = {
        Item = RepMMod.DSSdirectory.main,
        Main = 'main',
        Idle = false,
        MaskAlpha = 1,
        Settings = {},
        SettingsChanged = false,
        Path = {},
    }
    
    DeadSeaScrollsMenu.AddMenu("rep-", {
        Run = dssmod.runMenu, Open = dssmod.openMenu, 
        Close = dssmod.closeMenu, Directory = RepMMod.DSSdirectory, 
        DirectoryKey = RepMdirectorykey,
        UseSubMenu = true,
    })
    end