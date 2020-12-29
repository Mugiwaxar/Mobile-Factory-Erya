pcall(require,'__debugadapter__/debugadapter.lua')

-- How many Tick between each Chunk Update --
local chunkUpdateTime = 180

-- The max Chunks updated per tick --
local maxChunkUpdate = 15

-- The size of a Chunk --
local chunkSize = 4

-- The initial temperature --
local initialTemperature = 20 -- °C --

-- The maximum natural temperature --
local maxNaturalTemperature = 20 -- °C --

-- The minimal temperature --
local minTemperature = -50 -- °C --

-- How many degrees is added per Update --
local addedTemperature = 0.01

-- At under which Temperature du frost spread --
local spreadTemperature = -5

-- Number of check before a valid Tile was found --
local validTileCheck = 10


-- Erya Structures that freeze the environment --
local frozenStructures = {
                        "EryaLamp",
                        "EryaChest1",
                        "EryaBelt1",
                        "EryaItemMover",
                        "EryaUndergroundBelt1",
                        "EryaUndergroundBelt2",
                        "EryaSplitter1",
                        "EryaSplitter2",
                        "EryaLoader1",
                        "EryaLoader2",
                        "EryaInserter1",
                        "EryaMiningDrill1",
                        "EryaPumpjack1",
                        "EryaAssemblingMachine1",
                        "EryaPipe1",
                        "EryaPipeToGround1",
                        "EryaPump1",
                        "EryaWall1",
                        "EryaGate1",
                        "EryaRadar1",
                        "EryaFurnace1",
                        "EryaRefinery1",
                        "EryaChemicalPlant1"
                    }

-- List of Tiles that must be replaced by Ice --
local waterTiles = {}
waterTiles["deepwater"] = true
waterTiles["deepwater-green"] = true
waterTiles["water"] = true
waterTiles["water-green"] = true
waterTiles["water-shallow"] = true
waterTiles["water-mud"] = true
waterTiles["MFIceTile1"] = true

-- The amount of temperature that a Erya structure decrease (in °C) --
local heatCost = {}
heatCost["EryaLamp"] = 0.05
heatCost["EryaChest1"] = 0.03
heatCost["EryaBelt1"] = 0.01
heatCost["EryaItemMover"] = 0.02
heatCost["EryaUndergroundBelt1"] = 0.015
heatCost["EryaUndergroundBelt2"] = 0.015
heatCost["EryaSplitter1"] = 0.02
heatCost["EryaSplitter2"] = 0.03
heatCost["EryaLoader1"] = 0.02
heatCost["EryaLoader2"] = 0.03
heatCost["EryaInserter1"] = 0.05
heatCost["EryaMiningDrill1"] = 0.1
heatCost["EryaPumpjack1"] = 0.1
heatCost["EryaAssemblingMachine1"] = 0.1
heatCost["EryaPipe1"] = 0.01
heatCost["EryaPipeToGround1"] = 0.015
heatCost["EryaPump1"] = 0.03
heatCost["EryaWall1"] = 0.01
heatCost["EryaGate1"] = 0.03
heatCost["EryaRadar1"] = 0.15
heatCost["EryaFurnace1"] = 0.12
heatCost["EryaRefinery1"] = 0.15
heatCost["EryaChemicalPlant1"] = 0.15

-- When the Mod load for the first time --
function onInit()
    
    -- Create the Chunk Table --
    global.chunksTable = {}
    global.chunksTable3D = {}

    -- The Update Index to know where the Chunk Table have to be updated --
    global.chunkTableIndex = 1

end

-- Called every Tick --
function onTick()

    -- Check the Chunk Table Index --
    global.chunkTableIndex = global.chunkTableIndex or 1
    if global.chunkTableIndex > table_size(global.chunksTable) then global.chunkTableIndex = 1 end
    if table_size(global.chunksTable) <= 0 then return end

    -- game.print(table_size(global.chunksTable))

    -- Update the Chunk Table --
    for i=1, maxChunkUpdate do

        -- Get the Chunk --
        local chunk = global.chunksTable[global.chunkTableIndex]

        -- Check the Chunk --
        if chunk == nil then goto continue end
        if chunk.surface == nil then removeChunk(chunk, global.chunkTableIndex) goto continue end
        if chunk.surface.valid == false then removeChunk(chunk, global.chunkTableIndex) goto continue end

        -- Check if the Chunk has to be updated --
        if (game.tick - (chunk.lastCheck or 0)) < chunkUpdateTime then goto continue end

        -- Save the Last Update --
        chunk.lastCheck = game.tick

        -- Update the Chunk --
        updateChunk(chunk, global.chunkTableIndex)

        -- End of the Loop --
        ::continue::

        -- Increase the Index --
        global.chunkTableIndex = global.chunkTableIndex + 1

    end

end

function updateChunk(chunk, key)

    -- Decrease the Temperature for every Erya Tech present --
    local eryaEnts = chunk.surface.find_entities_filtered{area=chunk.area, name=frozenStructures}
    if table_size(eryaEnts) > 0 then
        for _, ent in pairs(eryaEnts) do
            chunk.temp = math.max(chunk.temp - (heatCost[ent.name] or 0), minTemperature)
        end
    end

    -- Increase the Temperature --
    chunk.temp = chunk.temp + addedTemperature

    -- Check if the Chunk has to be removed --
    if chunk.temp >= maxNaturalTemperature then
        -- Check if there are no Frozen Tiles left --
        if table_size(chunk.surface.find_tiles_filtered{area=chunk.area, name = "MFSnowTile1"} or {}) <= 0 then
            if table_size(chunk.surface.find_tiles_filtered{area=chunk.area, name = "MFIceTile1"} or {}) <= 0 then
                removeChunk(chunk, key)
            end

        end
    end

    -- Spread the Temperature if Needed --
    if chunk.temp < spreadTemperature then
        spreadFrost(chunk)
    end

    -- Update the Tiles --
    updateTiles(chunk)

end

-- Spread the Frost to the 8 surrounding Chunks --
function spreadFrost(chunk)

    -- Create the Chunks List --
    local chunkList = {
        {x=chunk.x-1, y=chunk.y-1},
        {x=chunk.x,   y=chunk.y-1},
        {x=chunk.x+1, y=chunk.y-1},
        {x=chunk.x-1, y=chunk.y},
        {x=chunk.x+1, y=chunk.y},
        {x=chunk.x-1, y=chunk.y+1},
        {x=chunk.x,   y=chunk.y+1},
        {x=chunk.x+1, y=chunk.y+1}
    }

    -- Update all Chunk of the List --
    for _, iChunk in pairs(chunkList) do

        -- Check if the Chunk already exist inside the Chunk Table --
        if global.chunksTable3D[chunk.surface.index] ~= nil and global.chunksTable3D[chunk.surface.index][iChunk.x] ~= nil and global.chunksTable3D[chunk.surface.index][iChunk.x][iChunk.y] ~= nil then
            -- Check if the Temperature can Spread --
            if global.chunksTable3D[chunk.surface.index][iChunk.x][iChunk.y].temp > (minTemperature+(chunk.temp/10)) then
                -- Update the Temperature --
                global.chunksTable3D[chunk.surface.index][iChunk.x][iChunk.y].temp = math.max(global.chunksTable3D[chunk.surface.index][iChunk.x][iChunk.y].temp + chunk.temp/10, minTemperature)
                chunk.temp = chunk.temp - chunk.temp/10
            end
        else
            -- Create the Area --
            local x1 = iChunk.x * chunkSize
            local y1 = iChunk.y * chunkSize
            local x2 = x1 + chunkSize
            local y2 = y1 + chunkSize
            local area = {left_top = {x=x1, y=y1}, right_bottom = {x=x2, y=y2}}
            -- Save the Chunk inside the Chunks Tables --
            local savedChunk = saveChunk(iChunk.x, iChunk.y, area, chunk.surface)
            savedChunk.temp = math.max(initialTemperature + chunk.temp/10)
        end
        ::continue::
    end

end

-- Update the Chunk Tiles --
function updateTiles(chunkObj)
    -- Create the Loop --
    for i=1, validTileCheck do
        -- Get random Locations --
        local x = math.random(1,chunkSize)
        local y = math.random(1,chunkSize)
        x = x + chunkObj.area.left_top.x - 1
        y = y + chunkObj.area.left_top.y - 1
        -- Get the Tile --
        local tile = chunkObj.surface.get_tile(x,y)
        -- Check the Tile --
        if tile ~= nil and tile.valid == true then
            -- Check if the Tile is a Snow Tile --
            if tile.name == "MFSnowTile1" or tile.name == "MFIceTile1" then
                -- Check if the snow have to melt or be created --
                if chunkObj.temp > 0 then
                    -- Check if there are an Hiden_Tile --
                    if tile.hidden_tile ~= nil and game.tile_prototypes[tile.hidden_tile] ~= nil then
                        tile.surface.set_tiles({{name=tile.hidden_tile, position=tile.position}})
                        break
                    else
                        tile.surface.set_tiles({{name="dirt-7", position=tile.position}})
                        break
                    end
                end
            elseif tile.name ~= "MFSnowTile1" and chunkObj.temp <= 0 then
                -- Save the Old Tile --
                tile.surface.set_hidden_tile(tile.position, tile.name)
                -- Create Snow Tiles --
                local tileName = waterTiles[tile.name] == nil and "MFSnowTile1" or "MFIceTile1"
                tile.surface.set_tiles({{name=tileName, position=tile.position}})
                break
            end
        end
    end
end

-- Called when Something was placed --
function somethingWasPlaced(event)

    -- Get the Entity --
    local ent = event.created_entity or event.entity or event.destination

    -- Check the Entity --
    if ent == nil or ent.valid == false then return end

    -- Check if this is a Erya Tech --
    if heatCost[ent.name] == nil then return end

    -- Get the Chunk Position --
    local cx = math.floor(ent.position.x / chunkSize)
    local cy = math.floor(ent.position.y / chunkSize)

    -- Create the Area --
    local x1 = cx * chunkSize
    local y1 = cy * chunkSize
    local x2 = x1 + chunkSize
    local y2 = y1 + chunkSize
    local area = {left_top = {x=x1, y=y1}, right_bottom = {x=x2, y=y2}}

    -- Check if the Chunk does not already exist --
    if global.chunksTable3D[ent.surface.index] ~= nil and global.chunksTable3D[ent.surface.index][cx] ~= nil and global.chunksTable3D[ent.surface.index][cx][cy] ~= nil then
        -- The chunk exist, do nothing --
    else
        -- Save the Chunk inside the Chunks Tables --
        saveChunk(cx, cy, area, ent.surface)
    end

end

-- Save a Chunk inside the Chunks Tables --
function saveChunk(posX, posY, area, surface)
    -- Create the Chunk Table --
    local chunkTable = {surface=surface, x=posX, y=posY, area=area, temp=initialTemperature, lastCheck=nil}
    -- Save the Chunk inside the 3D Chunk Table --
    global.chunksTable3D[surface.index] = global.chunksTable3D[surface.index] or {}
    global.chunksTable3D[surface.index][posX] = global.chunksTable3D[surface.index][posX] or {}
    global.chunksTable3D[surface.index][posX][posY] = global.chunksTable3D[surface.index][posX][posY] or chunkTable
    -- Save the Chunk inside the Chunk Table --
    table.insert(global.chunksTable, global.chunksTable3D[surface.index][posX][posY])
    -- Return the chunk --
    return global.chunksTable3D[surface.index][posX][posY]
end

-- Remove a Chunk from the Chunks Tables --
function removeChunk(chunk, key)

    -- Try to Remove the Chunk from the 3D Table --
    if chunk.surface ~= nil and chunk.surface.valid == true then
        if global.chunksTable3D[chunk.surface.index] ~= nil and global.chunksTable3D[chunk.surface.index][chunk.x] ~= nil and global.chunksTable3D[chunk.surface.index][chunk.x][chunk.y] ~= nil then
            global.chunksTable3D[chunk.surface.index][chunk.x][chunk.y] = nil
            if table_size(global.chunksTable3D[chunk.surface.index][chunk.x]) <= 0 then global.chunksTable3D[chunk.surface.index][chunk.x] = nil end
            if table_size(global.chunksTable3D[chunk.surface.index]) <= 0 then global.chunksTable3D[chunk.surface.index] = nil end
        end
    else
        for _, surfaceTable in pairs(global.chunksTable3D) do
            if surfaceTable[chunk.x] ~= nil and surfaceTable[chunk.x][chunk.y] ~= nil and surfaceTable[chunk.x][chunk.y] == chunk then
                surfaceTable[chunk.x][chunk.y] = nil
                if table_size(global.chunksTable3D[chunk.surface.index][chunk.x]) <= 0 then global.chunksTable3D[chunk.surface.index][chunk.x] = nil end
                if table_size(global.chunksTable3D[chunk.surface.index]) <= 0 then global.chunksTable3D[chunk.surface.index] = nil end
            end
        end
    end

    -- Remove the Chunk from Chunk Table --
    table.remove(global.chunksTable, key)

end

-- Event --
script.on_init(onInit)
script.on_event(defines.events.on_tick, onTick)
script.on_event(defines.events.on_built_entity, somethingWasPlaced)
script.on_event(defines.events.script_raised_built, somethingWasPlaced)
script.on_event(defines.events.script_raised_revive, somethingWasPlaced)
script.on_event(defines.events.on_robot_built_entity, somethingWasPlaced)
script.on_event(defines.events.on_entity_cloned, somethingWasPlaced)


--------------------------- Interface ---------------------------

-- Return the Chunk Temperature --
function getChunkTemp(surfaceIndex, posX, posY)
    local x = math.floor(posX / chunkSize)
    local y = math.floor(posY / chunkSize)
    if global.chunksTable3D == nil or global.chunksTable3D[surfaceIndex] == nil or global.chunksTable3D[surfaceIndex][x] == nil or global.chunksTable3D[surfaceIndex][x][y] == nil or global.chunksTable3D[surfaceIndex][x][y].temp == nil then
        return 20
    end
    return global.chunksTable3D[surfaceIndex][x][y].temp
end

-- Create the Interface --
remote.add_interface("EryaCom", {
    getChunkTemp=getChunkTemp,
})