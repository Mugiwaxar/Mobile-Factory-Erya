-- Recreate the Chunks Table and the 3D Chunk Table --
global.chunksTable = {}
global.chunksTable3D = {}
-- Scan all surfaces to find all Erya Entities --
for _, surface in pairs(game.surfaces) do
    -- Get all Erya Entity of the Surface --
    local ents = surface.find_entities_filtered{name=frozenStructures}
    -- Save all Entities --
    for _, ent in pairs(ents) do
        -- Check the Entity --
        if ent ~= nil and ent.valid == true then
            -- Get the Chunk Position --
            local cx = math.floor(ent.position.x / chunkSize)
            local cy = math.floor(ent.position.y / chunkSize)
            -- Create the Area --
            local x1 = cx * chunkSize
            local y1 = cy * chunkSize
            local x2 = x1 + chunkSize
            local y2 = y1 + chunkSize
            local area = {left_top = {x=x1, y=y1}, right_bottom = {x=x2, y=y2}}
            -- Save the Entity --
            saveChunk(cx, cy, area, ent.surface.index)
        end
    end
end