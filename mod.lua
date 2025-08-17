-- TAG MANAGER MOD - Main initialization file

-- Load all modules
local config_loader = assert(SMODS.load_file('src/config.lua'))
local TagManagerConfig = config_loader()

local utils_loader = assert(SMODS.load_file('src/utils.lua'))
local TagManagerUtils = utils_loader()

local core_loader = assert(SMODS.load_file('src/core.lua'))
local TagManagerCore = core_loader()

local ui_loader = assert(SMODS.load_file('src/ui.lua'))
local TagManagerUI = ui_loader()

-- Initialize all modules
TagManagerConfig.init()
TagManagerCore.init(TagManagerConfig, TagManagerUtils)
TagManagerUI.init(TagManagerConfig, TagManagerUtils)

-- Register settings tab
SMODS.current_mod.config_tab = function() 
    return TagManagerUI.create_tags_settings_tab()
end

SMODS.current_mod.extra_tabs = function()
   return TagManagerUI.create_credits_tab()
end

-- UI configuration
SMODS.current_mod.ui_config = {
    colour = {0.15, 0.35, 0.4, 1},
    bg_colour = {G.C.GREY[1], G.C.GREY[2], G.C.GREY[3], 0.7},
    back_colour = {0.7, 0.45, 0.25, 1},
    tab_button_colour = {0.25, 0.55, 0.5, 1},
    outline_colour = {0.6, 0.65, 0.4, 1},
    author_colour = {0.95, 0.95, 0.95, 1},
    author_bg_colour = {0.2, 0.4, 0.35, 0.85},
    author_outline_colour = {0.6, 0.65, 0.4, 1},
    collection_bg_colour = {0.18, 0.38, 0.38, 0.8},
    collection_back_colour = {0.65, 0.4, 0.22, 1},
    collection_outline_colour = {0.55, 0.6, 0.35, 1},
    collection_option_cycle_colour = {0.4, 0.5, 0.45, 1},
}

sendDebugMessage("Tag Manager mod loaded successfully!")