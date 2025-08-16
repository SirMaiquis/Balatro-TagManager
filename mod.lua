-- ============================================================================
-- TAG MANAGER MOD - INITIALIZATION
-- ============================================================================

-- Get the mod configuration containing tag minimum ante requirements
local tag_config = SMODS.current_mod.config
sendDebugMessage("Launching Tag Manager!")

-- Global variable to track current page in tags settings
local current_tags_page = 1

-- Register the Tags settings tab in the mod configuration
SMODS.current_mod.config_tab = function() 
    return create_tags_settings_tab()
end

SMODS.current_mod.ui_config = {
  colour = {0.15, 0.35, 0.4, 1}, -- Soft teal-grey main UI box
  bg_colour = {G.C.GREY[1], G.C.GREY[2], G.C.GREY[3], 0.7}, -- Background
  back_colour = {0.7, 0.45, 0.25, 1}, -- Muted warm brown back button
  tab_button_colour = {0.25, 0.55, 0.5, 1}, -- Subdued teal tab buttons
  outline_colour = {0.6, 0.65, 0.4, 1}, -- Soft sage green outline
  author_colour = {0.95, 0.95, 0.95, 1}, -- Clean white author text
  author_bg_colour = {0.2, 0.4, 0.35, 0.85}, -- Muted teal author background
  author_outline_colour = {0.6, 0.65, 0.4, 1}, -- Matching sage outline
  collection_bg_colour = {0.18, 0.38, 0.38, 0.8}, -- Subtle teal collection background
  collection_back_colour = {0.65, 0.4, 0.22, 1}, -- Warm earth tone collection back
  collection_outline_colour = {0.55, 0.6, 0.35, 1}, -- Soft sage collection outline
  collection_option_cycle_colour = {0.4, 0.5, 0.45, 1}, -- Neutral grey-green cycle button
}

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
    
    -- Remove tags from pool that don't meet ante requirements
    for pool_index, tag_key in pairs(tag_pool) do
        local tag_ante_config = get_tag_ante_config(tag_key)
        
        if tag_ante_config == nil then
            -- Tag not found in config, remove it
            tag_pool[pool_index] = nil
        else
            local min_ante = tag_ante_config.min_ante or 1
            local max_ante = tag_ante_config.max_ante or 8
            
            if current_ante < min_ante or current_ante > max_ante then
                -- Tag is outside allowed ante range, remove it
                tag_pool[pool_index] = nil
            end
        end
    end

    -- Add tags that are now available but not yet in the pool
    for tag_key, tag_ante_config in pairs(tag_config) do
        local is_tag_in_pool = is_tag_in_current_pool(tag_pool, tag_key)
        local min_ante = tag_ante_config.min_ante or 1
        local max_ante = tag_ante_config.max_ante or 8
        
        if not is_tag_in_pool and current_ante >= min_ante and current_ante <= max_ante then
            tag_pool[#tag_pool + 1] = tag_key
        end
    end

    return tag_pool, pool_key
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get the ante configuration for a specific tag
function get_tag_ante_config(tag_key)
    return tag_config[tag_key]
end

-- Get the minimum ante requirement for a specific tag (legacy compatibility)
function get_tag_min_ante(tag_key)
    local config = tag_config[tag_key]
    return config and config.min_ante or nil
end

-- Get the maximum ante requirement for a specific tag
function get_tag_max_ante(tag_key)
    local config = tag_config[tag_key]
    return config and config.max_ante or 8
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

-- Create the Tags settings tab UI with pagination
function create_tags_settings_tab()
    -- Get all available tags and sort them by display order
    local available_tags = {}
    for tag_key, tag_data in pairs(G.P_TAGS) do
        available_tags[#available_tags + 1] = tag_data
    end
    table.sort(available_tags, function(tag_a, tag_b) 
        return tag_a.order < tag_b.order 
    end)
    
    -- Pagination settings: 2 rows × 3 tags = 6 tags per page
    local tags_per_row = 3
    local rows_per_page = 2
    local tags_per_page = tags_per_row * rows_per_page
    local total_pages = math.ceil(#available_tags / tags_per_page)
    
    -- Ensure current page is within valid range
    if current_tags_page > total_pages then
        current_tags_page = total_pages
    elseif current_tags_page < 1 then
        current_tags_page = 1
    end
    
    -- Calculate which tags to show on current page
    local start_index = (current_tags_page - 1) * tags_per_page + 1
    local end_index = math.min(start_index + tags_per_page - 1, #available_tags)
    
    -- Create the main container with header message
    local ui_nodes = {
      custom_text_container('ml_tags_options_message', {
            colour = G.C.UI.TEXT_LIGHT, 
            scale = 0.80, 
            shadow = true
        })
    }
    
    -- Create tag option rows for current page only
    local current_row_nodes = {}
    local tags_in_current_row = 0
    local current_tag_index = 0
    
    for i = start_index, end_index do
        local tag_data = available_tags[i]
        if tag_data then
            local tag_option_node = create_tag_option_node(tag_data)
            table.insert(current_row_nodes, tag_option_node)
            tags_in_current_row = tags_in_current_row + 1
            current_tag_index = current_tag_index + 1
            
            -- When row is full, add it to main nodes and start a new row
            if tags_in_current_row == tags_per_row then
                table.insert(ui_nodes, {n = G.UIT.R, nodes = current_row_nodes})
                current_row_nodes = {}
                tags_in_current_row = 0
            end
        end
    end
    
    -- Add any remaining tags in the last row
    if #current_row_nodes > 0 then
        table.insert(ui_nodes, {n = G.UIT.R, nodes = current_row_nodes})
    end
    
    -- Create pagination controls if there are multiple pages
    if total_pages > 1 then
        local page_options = {}
        for i = 1, total_pages do
            table.insert(page_options, localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(total_pages))
        end
        
        local pagination_control = {
            n = G.UIT.R, 
            config = {align = "cm"}, 
            nodes = {
                create_option_cycle({
                    options = page_options,
                    w = 4.5,
                    cycle_shoulders = true,
                    opt_callback = 'change_tags_page',
                    current_option = current_tags_page,
                    colour = {0.4, 0.5, 0.45, 1}, -- Neutral grey-green pagination
                    no_pips = true,
                    focus_args = {snap_to = true, nav = 'wide'}
                })
            }
        }
        
        table.insert(ui_nodes, pagination_control)
    end
    
    return {
        n = G.UIT.ROOT,
        config = {align = "cm", padding = 0.05, colour = G.C.CLEAR},
        nodes = ui_nodes
    }
end

-- Create a single tag option node (tag visual + min/max ante selectors)
function create_tag_option_node(tag_data)
    local min_ante_required = tag_config[tag_data.key].min_ante
    local max_ante_required = tag_config[tag_data.key].max_ante or 8 -- Default to 8 if not set
    
    -- Create temporary tag for UI display
    local temp_tag = Tag(tag_data.key, true)
    local tag_ui = temp_tag:generate_UI()
    
    -- Create the minimum ante requirement selector (1-8)
    local min_ante_selector = create_option_cycle({
        w = 1,
        scale = 0.55,
        label = "Min",
        options = {1, 2, 3, 4, 5, 6, 7, 8},
        opt_callback = 'change_tag_min_ante',
        current_option = min_ante_required,
        identifier = tag_data.key,
        colour = {0.4, 0.5, 0.45, 1} -- Neutral grey-green to match theme
    })
    min_ante_selector.n = G.UIT.C
    
    -- Create the maximum ante requirement selector (1-8)
    local max_ante_selector = create_option_cycle({
        w = 1,
        scale = 0.55,
        label = "Max",
        options = {1, 2, 3, 4, 5, 6, 7, 8},
        opt_callback = 'change_tag_max_ante',
        current_option = max_ante_required,
        identifier = tag_data.key,
        colour = {0.5, 0.4, 0.45, 1} -- Slightly different shade for distinction
    })
    max_ante_selector.n = G.UIT.C
    
    return {
        n = G.UIT.C, 
        config = {align = "cm", padding = 0.1},
        nodes = {
            -- Tag visual at the top
            {
                n = G.UIT.R,
                config = {align = "cm", padding = 0.05},
                nodes = {tag_ui}
            },
            -- Tag name below the visual
            {
                n = G.UIT.R,
                config = {align = "cm", padding = 0.02},
                nodes = {
                    {n = G.UIT.T, config = {text = localize{type = 'name_text', key = tag_data.key, set = 'Tag'}, scale = 0.4, colour = G.C.UI.TEXT_LIGHT}}
                }
            },
            -- Min and Max selectors in a row at the bottom
            {
                n = G.UIT.R,
                config = {align = "cm", padding = 0.02},
                nodes = {min_ante_selector, max_ante_selector}
            }
        }
    }
end

-- ============================================================================
-- CALLBACK FUNCTIONS
-- ============================================================================

-- Callback function for when a tag's minimum ante requirement is changed
G.FUNCS.change_tag_min_ante = function(args)
    tag_config[args.cycle_config.identifier].min_ante = args.to_val
end

-- Callback function for when a tag's maximum ante requirement is changed
G.FUNCS.change_tag_max_ante = function(args)
    tag_config[args.cycle_config.identifier].max_ante = args.to_val
end

-- Callback function for when the tags page is changed
G.FUNCS.change_tags_page = function(args)
    -- Extract the page number from the string "Page X/Y" -> X
    local page_string = args.to_val
    local page_number = tonumber(page_string:match("(%d+)"))
    
    if page_number then
        current_tags_page = page_number
    else
        current_tags_page = 1  -- Fallback to page 1 if parsing fails
    end
    
    -- Rebuild the Tags tab content similar to how jokers collection works
    G.FUNCS.overlay_menu({definition = create_tags_settings_tab(), config = {align="cm", offset = {x=0,y=0}, major = G.ROOM_ATTACH, bond = 'Weak'}})
end

function custom_text_container(_loc, args)
  if not _loc then return nil end
  args = args or {}
  local text = {}
  localize{type = 'quips', key = _loc or 'lq_1', vars = loc_vars or {}, nodes = text}
  local row = {}
  for k, v in ipairs(text) do
    row[#row+1] =  {n=G.UIT.R, config={align = "cl", shadow = true}, nodes=v}
  end
  local t = {n=G.UIT.R, config={align = "cm", minh = 1,r = 0.2, padding = 0.03, minw = 1, colour = G.C.WHITE}, nodes=row}
  return t
end
