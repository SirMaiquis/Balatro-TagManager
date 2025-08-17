local TagManagerUtils = {}

function TagManagerUtils.is_tag_in_current_pool(pool, tag_key)
    for _, pool_tag_key in pairs(pool) do
        if pool_tag_key == tag_key then
            return true
        end
    end
    return false
end

function TagManagerUtils.custom_text_container(_loc, args)
    if not _loc then return nil end
    args = args or {}
    local text = {}
    localize{type = 'quips', key = _loc or 'lq_1', vars = args or {}, nodes = text}
    local row = {}
    for k, v in ipairs(text) do
        row[#row+1] = {n=G.UIT.R, config={align = "cl", shadow = true}, nodes=v}
    end
    local t = {n=G.UIT.R, config={align = "cm", minh = 1, r = 0.2, padding = 0.03, minw = 1, colour = G.C.WHITE}, nodes=row}
    return t
end

return TagManagerUtils