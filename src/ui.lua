local TagManagerUI = {}

local TagManagerConfig = nil
local TagManagerUtils = nil

local current_tags_page = 1
local tags_tab_content_box = nil
local tags_tab_parent_node = nil

function TagManagerUI.init(config, utils)
    TagManagerConfig = config
    TagManagerUtils = utils
    
    G.FUNCS.change_tag_min_ante = TagManagerUI.change_tag_min_ante
    G.FUNCS.change_tag_max_ante = TagManagerUI.change_tag_max_ante
    G.FUNCS.change_tags_page = TagManagerUI.change_tags_page
end

function TagManagerUI.create_tags_settings_tab()
    tags_tab_content_box = UIBox({
        definition = TagManagerUI.create_tags_content_definition(),
        config = {offset = {x=0,y=0}, type = 'cm'}
    })
    
    tags_tab_parent_node = {n = G.UIT.O, config = {object = tags_tab_content_box}}
    
    return {
        n = G.UIT.ROOT,
        config = {align = "cm", padding = 0.05, colour = G.C.CLEAR},
        nodes = {tags_tab_parent_node}
    }
end

function TagManagerUI.create_tags_content_definition()
    local available_tags = {}
    for tag_key, tag_data in pairs(G.P_TAGS) do
        available_tags[#available_tags + 1] = tag_data
    end
    table.sort(available_tags, function(tag_a, tag_b) 
        return tag_a.order < tag_b.order 
    end)
    
    local tags_per_row = 3
    local rows_per_page = 2
    local tags_per_page = tags_per_row * rows_per_page
    local total_pages = math.ceil(#available_tags / tags_per_page)
    
    if current_tags_page > total_pages then
        current_tags_page = total_pages
    elseif current_tags_page < 1 then
        current_tags_page = 1
    end
    
    local start_index = (current_tags_page - 1) * tags_per_page + 1
    local end_index = math.min(start_index + tags_per_page - 1, #available_tags)
    
    local ui_nodes = {
        TagManagerUtils.custom_text_container('ml_tags_options_message', {
            colour = G.C.UI.TEXT_LIGHT, 
            scale = 0.80, 
            shadow = true
        }),
        {
            n = G.UIT.R,
            config = {align = "cm", padding = 0.1},
            nodes = {
                create_toggle({
                    label = "Enable Tag Manager", 
                    ref_table = TagManagerConfig.get_config(), 
                    ref_value = 'global_enabled'
                })
            }
        }
    }
    
    local current_row_nodes = {}
    local tags_in_current_row = 0
    
    for i = start_index, end_index do
        local tag_data = available_tags[i]
        if tag_data then
            local tag_option_node = TagManagerUI.create_tag_option_node(tag_data)
            table.insert(current_row_nodes, tag_option_node)
            tags_in_current_row = tags_in_current_row + 1
            
            if tags_in_current_row == tags_per_row then
                table.insert(ui_nodes, {n = G.UIT.R, nodes = current_row_nodes})
                current_row_nodes = {}
                tags_in_current_row = 0
            end
        end
    end
    
    if #current_row_nodes > 0 then
        table.insert(ui_nodes, {n = G.UIT.R, nodes = current_row_nodes})
    end
    
    local pagination_control = TagManagerUI.create_pagination_control(total_pages, current_tags_page)
    if pagination_control then
        table.insert(ui_nodes, pagination_control)
    end
    
    return {
        n = G.UIT.ROOT,
        config = {align = "cm", padding = 0.05, colour = G.C.CLEAR},
        nodes = ui_nodes
    }
end

function TagManagerUI.create_pagination_control(total_pages, current_page)
    if total_pages <= 1 then
        return nil
    end
    
    local page_options = {}
    for i = 1, total_pages do
        table.insert(page_options, localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(total_pages))
    end
    
    return {
        n = G.UIT.R, 
        config = {align = "cm"}, 
        nodes = {
            create_option_cycle({
                options = page_options,
                w = 4.5,
                cycle_shoulders = true,
                opt_callback = 'change_tags_page',
                current_option = current_page,
                colour = {0.4, 0.5, 0.45, 1},
                no_pips = true,
                focus_args = {snap_to = true, nav = 'wide'}
            })
        }
    }
end

function TagManagerUI.create_tag_option_node(tag_data)
    local config = TagManagerConfig.get_config()
    local tag_ante_config = config[tag_data.key] or {}
    local min_ante_required = tag_ante_config.min_ante or 1
    local max_ante_required = tag_ante_config.max_ante or 8
    
    if tag_ante_config.enabled == nil then
        tag_ante_config.enabled = true
        config[tag_data.key] = tag_ante_config
    end
    
    local temp_tag = Tag(tag_data.key, true)
    local tag_ui = temp_tag:generate_UI()
    
    local min_ante_selector = create_option_cycle({
        w = 1,
        scale = 0.55,
        label = "Min",
        options = {1, 2, 3, 4, 5, 6, 7, 8},
        opt_callback = 'change_tag_min_ante',
        current_option = min_ante_required,
        identifier = tag_data.key,
        colour = {0.4, 0.5, 0.45, 1}
    })
    min_ante_selector.n = G.UIT.C
    
    local max_ante_selector = create_option_cycle({
        w = 1,
        scale = 0.55,
        label = "Max",
        options = {1, 2, 3, 4, 5, 6, 7, 8},
        opt_callback = 'change_tag_max_ante',
        current_option = max_ante_required,
        identifier = tag_data.key,
        colour = {0.5, 0.4, 0.45, 1}
    })
    max_ante_selector.n = G.UIT.C
    
    local tag_name = localize{type = 'name_text', key = tag_data.key, set = 'Tag'}
    if #tag_name < 12 then
        local padding = math.floor((12 - #tag_name) / 2)
        tag_name = string.rep(" ", padding) .. tag_name .. string.rep(" ", padding)
        if #tag_name < 12 then
            tag_name = tag_name .. " "
        end
    end
    
    local enabled_toggle = create_toggle({
        label = tag_name, 
        ref_table = config[tag_data.key], 
        ref_value = 'enabled',
        scale = 0.6,
        align = "cm"
    })
    
    return {
        n = G.UIT.C, 
        config = {align = "cm", padding = 0.1},
        nodes = {
            {
                n = G.UIT.R,
                config = {align = "cm", padding = 0.05},
                nodes = {tag_ui}
            },
            {
                n = G.UIT.R,
                config = {align = "cm", padding = 0.02, minw = 1},
                nodes = {enabled_toggle}
            },
            {
                n = G.UIT.R,
                config = {align = "cm", padding = 0.02},
                nodes = {min_ante_selector, max_ante_selector}
            }
        }
    }
end

function TagManagerUI.change_tag_min_ante(args)
    local config = TagManagerConfig.get_config()
    config[args.cycle_config.identifier].min_ante = args.to_val
end

function TagManagerUI.change_tag_max_ante(args)
    local config = TagManagerConfig.get_config()
    config[args.cycle_config.identifier].max_ante = args.to_val
end

function TagManagerUI.change_tags_page(args)
    local page_string = args.to_val
    local page_number = tonumber(page_string:match("(%d+)"))
    
    if page_number then
        current_tags_page = page_number
    else
        current_tags_page = 1
    end
    
    if tags_tab_content_box and tags_tab_parent_node then
        local menu_wrap = tags_tab_content_box.parent
        menu_wrap.config.object:remove()
        menu_wrap.config.object = UIBox({
            definition = TagManagerUI.create_tags_content_definition(),
            config = {parent = menu_wrap, type = 'cm'}
        })
        tags_tab_content_box = menu_wrap.config.object
        menu_wrap.UIBox:recalculate()
    end
end

return TagManagerUI