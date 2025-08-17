local TagManagerCore = {}

local TagManagerConfig = nil
local TagManagerUtils = nil
local original_get_current_pool = nil

function TagManagerCore.init(config, utils)
    TagManagerConfig = config
    TagManagerUtils = utils
    original_get_current_pool = get_current_pool
    get_current_pool = TagManagerCore.get_current_pool_override
end

function TagManagerCore.get_current_pool_override(pool_type, rarity, legendary, append)
    if pool_type ~= 'Tag' then 
        return original_get_current_pool(pool_type, rarity, legendary, append) 
    end
    
    if not TagManagerConfig.is_enabled() then
        return original_get_current_pool(pool_type, rarity, legendary, append)
    end

    local tag_pool, pool_key = original_get_current_pool('Tag', nil, nil, append)
    local current_ante = G.GAME.round_resets.ante
    
    -- Remove tags that don't meet ante requirements or are disabled
    for pool_index, tag_key in pairs(tag_pool) do
        local tag_ante_config = TagManagerConfig.get_tag_ante_config(tag_key)
        
        if tag_ante_config == nil then
            tag_pool[pool_index] = nil
        else
            local min_ante = tag_ante_config.min_ante or 1
            local max_ante = tag_ante_config.max_ante or 8
            local enabled = tag_ante_config.enabled
            
            local min_check = (min_ante == 1) and true or (current_ante >= min_ante)
            local max_check = (max_ante == 8) and true or (current_ante <= max_ante)
            
            if enabled == false or not (min_check and max_check) then
                tag_pool[pool_index] = nil
            end
        end
    end

    -- Add tags that are now available but not yet in the pool
    local config = TagManagerConfig.get_config()
    for tag_key, tag_ante_config in pairs(config) do
        if type(tag_ante_config) == "table" and tag_ante_config.min_ante then
            local is_tag_in_pool = TagManagerUtils.is_tag_in_current_pool(tag_pool, tag_key)
            local min_ante = tag_ante_config.min_ante or 1
            local max_ante = tag_ante_config.max_ante or 8
            local enabled = tag_ante_config.enabled ~= false
            
            local min_check = (min_ante == 1) and true or (current_ante >= min_ante)
            local max_check = (max_ante == 8) and true or (current_ante <= max_ante)
            
            if not is_tag_in_pool and enabled and min_check and max_check then
                tag_pool[#tag_pool + 1] = tag_key
            end
        end
    end

    return tag_pool, pool_key
end

return TagManagerCore