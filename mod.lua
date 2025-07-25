local config = SMODS.current_mod.config
sendDebugMessage("Launching Tag Manager!")

SMODS.current_mod.config_tab = function() 
  return G.UIDEF.settings_tab('Tags');
end

local get_current_pool_ref = get_current_pool
function get_current_pool(_type, _rarity, _legendary, _append)
    if _type ~= 'Tag' then return get_current_pool_ref(_type, _rarity, _legendary, _append) end

    local _pool, _pool_key = get_current_pool_ref('Tag', nil, nil, _append)
    local currentAnte = G.GAME.round_resets.ante
    for k, v in pairs(_pool) do
      local tagInConfig = get_tag_from_config(v)
      if(tagInConfig == nil) then
        _pool[k] = nil
      else
        if(tagInConfig >= currentAnte) then
          _pool[k] = nil
        end
      end
    end

    for k, v in pairs(config) do
      local tagInPool = get_tag_from_pool(_pool, k)
      if(tagInPool ~= nil) then
        break
      end
      if(v <= currentAnte) then
        _pool[#_pool+1] = k
      end
    end


    return _pool, _pool_key

end

function get_tag_from_config(key)
  return config[key]
end

function get_tag_from_pool(pool, key)
  for k, v in pairs(pool) do
    if(v == key) then
      return k
    end
  end
  return nil;
end

function create_UIBox_settings()
  local tabs = {}
  tabs[#tabs+1] = {
    label = localize('b_set_game'),
    chosen = true,
    tab_definition_function = G.UIDEF.settings_tab,
    tab_definition_function_args = 'Game'
  }
  if G.F_VIDEO_SETTINGS then   tabs[#tabs+1] = {
      label = localize('b_set_video'),
      tab_definition_function = G.UIDEF.settings_tab,
      tab_definition_function_args = 'Video'
    }
  end
  tabs[#tabs+1] = {
    label = localize('b_set_graphics'),
    tab_definition_function = G.UIDEF.settings_tab,
    tab_definition_function_args = 'Graphics'
  }
  tabs[#tabs+1] = {
    label = localize('b_set_audio'),
    tab_definition_function = G.UIDEF.settings_tab,
    tab_definition_function_args = 'Audio'
  }
  tabs[#tabs+1] = {
    label = localize('b_tags'),
    tab_definition_function = G.UIDEF.settings_tab,
    tab_definition_function_args = 'Tags'
  }

  local t = create_UIBox_generic_options({back_func = 'options',contents = {create_tabs(
    {tabs = tabs,
    tab_h = 7.05,
    tab_alignment = 'tm',
    snap_to_nav = true}
    )}})
return t
end

local settings_tabRef = G.UIDEF.settings_tab
function G.UIDEF.settings_tab(tab)
  if tab == 'Tags' then
        local tag_tab = {}
        for k, v in pairs(G.P_TAGS) do
          tag_tab[#tag_tab+1] = v
        end

        table.sort(tag_tab, function (a, b) return a.order < b.order end)
        local finalNodes = {simple_text_container('ml_tags_options_message',{colour = G.C.UI.TEXT_LIGHT, scale = 0.55, shadow = true})}

        local rowNodes = {}
        local count = 0
        local matrixCount = 0;
        for tag, v in pairs(tag_tab) do
            local min_ante = config[v.key];
            local temp_tag = Tag(v.key, true)
            local temp_tag_ui = temp_tag:generate_UI()
            local optionCycle = create_option_cycle({
                w = 1,
                scale = 0.6,
                label = localize{type = 'name_text', key = v.key, set = 'Tag'},
                options = {1, 2, 3, 4, 5, 6, 7, 8},
                opt_callback = 'change_tag_min_ante',
                current_option = min_ante,
                identifier = v.key
            })
            optionCycle.n = G.UIT.C
            local finalOption = {n = G.UIT.C, nodes = {
              {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
                temp_tag_ui,
                optionCycle
              }}
            }}
            table.insert(rowNodes, finalOption)
            count = count + 1

            if count == 6 then
                matrixCount = matrixCount + 1;
                table.insert(finalNodes, {n = G.UIT.R, nodes = rowNodes})
                rowNodes = {}
                count = 0
            end
        end
        
        if #rowNodes > 0 then
            table.insert(finalNodes, {n = G.UIT.R, nodes = rowNodes})
        end

        return {
            n = G.UIT.ROOT,
            config = {align = "cm", padding = 0.05, colour = G.C.CLEAR},
            nodes = finalNodes
        }
    end

    local t = settings_tabRef(tab)
    return t
end

G.FUNCS.change_tag_min_ante = function(args)
  config[args.cycle_config.identifier] = args.to_val
end
