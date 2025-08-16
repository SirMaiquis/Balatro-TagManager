-- ============================================================================
-- TAG MANAGER MOD - INITIALIZATION
-- ============================================================================

-- Get the mod configuration containing tag minimum ante requirements
local tag_config = SMODS.current_mod.config
sendDebugMessage("Launching Tag Manager!")

-- Register the Tags settings tab in the mod configuration
SMODS.current_mod.config_tab = function() 
    return create_tags_settings_tab()
end

-- ============================================================================
-- TAG POOL MANAGEMENT
-- ============================================================================

-- Store reference to the original get_current_pool function
local original_get_current_pool = get_current_pool

-- Override the get_current_pool function to filter tags based on ante requirements
function get_current_pool(pool_type, rarity, legendary, append)
    -- If not requesting tags, use the original function
    if pool_type ~= 'Tag' then 
        return original_get_current_pool(pool_type, rarity, legendary, append) 
    end

    -- Get the base tag pool from the original function
    local tag_pool, pool_key = original_get_current_pool('Tag', nil, nil, append)
    local current_ante = G.GAME.round_resets.ante
    
    -- Remove tags from pool that haven't reached their minimum ante requirement
    for pool_index, tag_key in pairs(tag_pool) do
        local min_ante_required = get_tag_min_ante(tag_key)
        
        if min_ante_required == nil then
            -- Tag not found in config, remove it
            tag_pool[pool_index] = nil
        elseif min_ante_required > current_ante then
            -- Tag requires higher ante, remove it
            tag_pool[pool_index] = nil
        end
    end

    -- Add tags that are now available but not yet in the pool
    for tag_key, min_ante_required in pairs(tag_config) do
        local is_tag_in_pool = is_tag_in_current_pool(tag_pool, tag_key)
        
        if not is_tag_in_pool and min_ante_required <= current_ante then
            tag_pool[#tag_pool + 1] = tag_key
        end
    end

    return tag_pool, pool_key
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get the minimum ante requirement for a specific tag
function get_tag_min_ante(tag_key)
    return tag_config[tag_key]
end

-- Check if a tag is already present in the current pool
function is_tag_in_current_pool(pool, tag_key)
    for _, pool_tag_key in pairs(pool) do
        if pool_tag_key == tag_key then
            return true
        end
    end
    return false
end

-- ============================================================================
-- TAGS SETTINGS TAB UI
-- ============================================================================

-- Create the Tags settings tab UI
function create_tags_settings_tab()
    -- Get all available tags and sort them by display order
    local available_tags = {}
    for tag_key, tag_data in pairs(G.P_TAGS) do
        available_tags[#available_tags + 1] = tag_data
    end
    table.sort(available_tags, function(tag_a, tag_b) 
        return tag_a.order < tag_b.order 
    end)
    
    -- Create the main container with header message
    local ui_nodes = {
        simple_text_container('ml_tags_options_message', {
            colour = G.C.UI.TEXT_LIGHT, 
            scale = 0.55, 
            shadow = true
        })
    }
    
    -- Create tag option rows (6 tags per row)
    local current_row_nodes = {}
    local tags_in_current_row = 0
    local max_tags_per_row = 6
    
    for _, tag_data in pairs(available_tags) do
        local tag_option_node = create_tag_option_node(tag_data)
        table.insert(current_row_nodes, tag_option_node)
        tags_in_current_row = tags_in_current_row + 1
        
        -- When row is full, add it to main nodes and start a new row
        if tags_in_current_row == max_tags_per_row then
            table.insert(ui_nodes, {n = G.UIT.R, nodes = current_row_nodes})
            current_row_nodes = {}
            tags_in_current_row = 0
        end
    end
    
    -- Add any remaining tags in the last row
    if #current_row_nodes > 0 then
        table.insert(ui_nodes, {n = G.UIT.R, nodes = current_row_nodes})
    end
    
    return {
        n = G.UIT.ROOT,
        config = {align = "cm", padding = 0.05, colour = G.C.CLEAR},
        nodes = ui_nodes
    }
end

-- Create a single tag option node (tag visual + ante selector)
function create_tag_option_node(tag_data)
    local min_ante_required = tag_config[tag_data.key]
    
    -- Create temporary tag for UI display
    local temp_tag = Tag(tag_data.key, true)
    local tag_ui = temp_tag:generate_UI()
    
    -- Create the ante requirement selector (1-8)
    local ante_selector = create_option_cycle({
        w = 1,
        scale = 0.6,
        label = localize{type = 'name_text', key = tag_data.key, set = 'Tag'},
        options = {1, 2, 3, 4, 5, 6, 7, 8},
        opt_callback = 'change_tag_min_ante',
        current_option = min_ante_required,
        identifier = tag_data.key
    })
    ante_selector.n = G.UIT.C
    
    return {
        n = G.UIT.C, 
        nodes = {
            {
                n = G.UIT.C, 
                config = {align = "cm", padding = 0.1}, 
                nodes = {tag_ui, ante_selector}
            }
        }
    }
end

-- ============================================================================
-- CALLBACK FUNCTIONS
-- ============================================================================

-- Callback function for when a tag's minimum ante requirement is changed
G.FUNCS.change_tag_min_ante = function(args)
    tag_config[args.cycle_config.identifier] = args.to_val
end
