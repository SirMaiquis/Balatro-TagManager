local TagManagerConfig = {}

function TagManagerConfig.init()
    TagManagerConfig.config = SMODS.current_mod.config
    if TagManagerConfig.config.global_enabled == nil then
        TagManagerConfig.config.global_enabled = true
    end
end

function TagManagerConfig.get_tag_ante_config(tag_key)
    return TagManagerConfig.config[tag_key]
end

function TagManagerConfig.get_tag_min_ante(tag_key)
    local config = TagManagerConfig.config[tag_key]
    return config and config.min_ante or nil
end

function TagManagerConfig.get_tag_max_ante(tag_key)
    local config = TagManagerConfig.config[tag_key]
    return config and config.max_ante or 8
end

function TagManagerConfig.is_enabled()
    return TagManagerConfig.config.global_enabled
end

function TagManagerConfig.get_config()
    return TagManagerConfig.config
end

return TagManagerConfig