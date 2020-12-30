pcall(require,'__debugadapter__/debugadapter.lua')

-- How many Tick between each Chunk Update --
chunkUpdateTime = 300

-- The max Chunks checked per tick --
maxTileCheck = 100

-- The max Chunks updated per tick --
maxChunkUpdate = 15

-- The size of a Chunk --
chunkSize = 4

-- The initial temperature --
initialTemperature = 20 -- °C --

-- The maximum natural temperature --
maxNaturalTemperature = 20 -- °C --

-- The minimal temperature --
minTemperature = -273 -- °C --

-- How many degrees is added per Update --
addedTemperature = 0.25

-- At under which Temperature du frost spread --
spreadTemperature = -10

-- Number of check before a valid Tile was found --
validTileCheck = 1


-- Erya Structures that freeze the environment --
frozenStructures = {
                        "EryaLamp",
                        "EryaChest1",
                        "EryaTank1",
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
waterTiles = {}
waterTiles["deepwater"] = true
waterTiles["deepwater-green"] = true
waterTiles["water"] = true
waterTiles["water-green"] = true
waterTiles["water-shallow"] = true
waterTiles["water-mud"] = true
waterTiles["MFIceTile1"] = true

-- The amount of temperature that a Erya structure decrease (in °C) --
heatCost = {}
heatCost["EryaLamp"] = 5
heatCost["EryaChest1"] = 3
heatCost["EryaTank1"] = 5
heatCost["EryaBelt1"] = 1
heatCost["EryaItemMover"] = 2
heatCost["EryaUndergroundBelt1"] = 1.5
heatCost["EryaUndergroundBelt2"] = 1.5
heatCost["EryaSplitter1"] = 2
heatCost["EryaSplitter2"] = 3
heatCost["EryaLoader1"] = 2
heatCost["EryaLoader2"] = 3
heatCost["EryaInserter1"] = 5
heatCost["EryaMiningDrill1"] = 10
heatCost["EryaPumpjack1"] = 10
heatCost["EryaAssemblingMachine1"] = 10
heatCost["EryaPipe1"] = 1
heatCost["EryaPipeToGround1"] = 1.5
heatCost["EryaPump1"] = 3
heatCost["EryaWall1"] = 1
heatCost["EryaGate1"] = 3
heatCost["EryaRadar1"] = 15
heatCost["EryaFurnace1"] = 12
heatCost["EryaRefinery1"] = 15
heatCost["EryaChemicalPlant1"] = 15

-- When the Mod load for the first time --
function onInit()
    
    -- Create the Chunk Table --
    global.chunksTable = {}
    global.chunksTable3D = {}

    -- The Update Index to know where the Chunk Table have to be updated --
    global.chunkTableIndex = 0

end

-- Called every Tick --
function onTick()

    -- Check the Chunk Table Index --
    local size = table_size(global.chunksTable)
    global.chunkTableIndex = global.chunkTableIndex or 1
    if global.chunkTableIndex >= size then global.chunkTableIndex = 0 end

    -- game.print(table_size(global.chunksTable))

    -- Update the Chunk Table --
    local chunkUpdated = 0
    for _=1, math.min(maxTileCheck, size) do

        -- Get the Chunk --
        local _, chunk = next(global.chunksTable, global.chunkTableIndex ~= 0 and global.chunkTableIndex or nil)

        -- Check the Chunk --
        if chunk == nil then break end

        -- Check if the Chunk has to be updated --
        if (game.tick - (chunk.lastCheck or 0)) > chunkUpdateTime then

            -- Save the Last Update --
            chunk.lastCheck = game.tick

            -- Check the Surface --
            local surface = game.get_surface(chunk.surfaceIndex)
            if surface == nil or surface.valid == false then
                removeChunk(chunk, global.chunkTableIndex+1)
            else
                -- Update the Chunk --
                updateChunk(chunk, global.chunkTableIndex+1)
                chunkUpdated = chunkUpdated + 1
                if chunkUpdated > maxChunkUpdate then break end
            end
            
        end

        -- Increase the Index --
        global.chunkTableIndex = global.chunkTableIndex + 1

    end

end

function updateChunk(chunk, key)

    -- Decrease the Temperature for every Erya Tech present --
    local eryaEnts = game.get_surface(chunk.surfaceIndex).find_entities_filtered{area=chunk.area, name=frozenStructures}
    if table_size(eryaEnts) > 0 then
        for _, ent in pairs(eryaEnts) do
            chunk.temp = math.max(chunk.temp - (heatCost[ent.name] or 0), minTemperature)
        end
    end

    -- Draw the Temperature Rectangle --
    rendering.draw_rectangle{color={255,0,0}, width=5, left_top=chunk.area.left_top, right_bottom=chunk.area.right_bottom, surface=game.get_surface(chunk.surfaceIndex), time_to_live=30}
    if chunk.temp > 15 then
        rendering.draw_rectangle{color={42,255,0,0.1}, filled=true, left_top=chunk.area.left_top, right_bottom=chunk.area.right_bottom, surface=game.get_surface(chunk.surfaceIndex), time_to_live=chunkUpdateTime+1}
    elseif chunk.temp > 5 then
        rendering.draw_rectangle{color={31,174,3,0.1}, filled=true, left_top=chunk.area.left_top, right_bottom=chunk.area.right_bottom, surface=game.get_surface(chunk.surfaceIndex), time_to_live=chunkUpdateTime+1}
    elseif chunk.temp > 0 then
        rendering.draw_rectangle{color={0,205,205,0.1}, filled=true, left_top=chunk.area.left_top, right_bottom=chunk.area.right_bottom, surface=game.get_surface(chunk.surfaceIndex), time_to_live=chunkUpdateTime+1}
    elseif chunk.temp > -15 then
        rendering.draw_rectangle{color={0,162,205,0.1}, filled=true, left_top=chunk.area.left_top, right_bottom=chunk.area.right_bottom, surface=game.get_surface(chunk.surfaceIndex), time_to_live=chunkUpdateTime+1}
    elseif chunk.temp > -100 then
        rendering.draw_rectangle{color={87,140,255,0.1}, filled=true, left_top=chunk.area.left_top, right_bottom=chunk.area.right_bottom, surface=game.get_surface(chunk.surfaceIndex), time_to_live=chunkUpdateTime+1}
    else
        rendering.draw_rectangle{color={0,12,255,0.1}, filled=true, left_top=chunk.area.left_top, right_bottom=chunk.area.right_bottom, surface=game.get_surface(chunk.surfaceIndex), time_to_live=chunkUpdateTime+1}
    end

    -- Increase the Temperature --
    chunk.temp = chunk.temp + addedTemperature

    -- Check if the Chunk has to be removed --
    if chunk.temp >= maxNaturalTemperature then
        -- Check if there are no Frozen Tiles left --
        if table_size(game.get_surface(chunk.surfaceIndex).find_tiles_filtered{area=chunk.area, name = "MFSnowTile1"} or {}) <= 0 then
            if table_size(game.get_surface(chunk.surfaceIndex).find_tiles_filtered{area=chunk.area, name = "MFIceTile1"} or {}) <= 0 then
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

    -- Get a random X and Y to spread --
    local rX = math.random(-1, 1)
    local rY = math.random(-1, 1)

    -- Get the random Chunk --
    local iChunk = {x=chunk.x + rX, y=chunk.y + rY}

    -- Check if the Chunk already exist inside the Chunk Table --
    local table1 = global.chunksTable3D[chunk.surfaceIndex]
    if table1 ~= nil then
        local table2 = table1[iChunk.x]
        if table2 ~= nil then
            local table3 = table2[iChunk.y]
            if table3 ~= nil and table3.temp > (minTemperature+(chunk.temp/10)) then
                -- Update the Temperature --
                table3.temp = math.max(table3.temp + chunk.temp/10, minTemperature)
                chunk.temp = chunk.temp - chunk.temp/10
                return
            end
        end
    end

    -- Create the Area --
    local x1 = iChunk.x * chunkSize
    local y1 = iChunk.y * chunkSize
    local x2 = x1 + chunkSize
    local y2 = y1 + chunkSize
    local area = {left_top = {x=x1, y=y1}, right_bottom = {x=x2, y=y2}}

    -- Save the Chunk inside the Chunks Tables --
    local savedChunk = saveChunk(iChunk.x, iChunk.y, area, chunk.surfaceIndex)
    savedChunk.temp = math.max(initialTemperature + chunk.temp/10)

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
        local tile = game.get_surface(chunkObj.surfaceIndex).get_tile(x,y)
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
        saveChunk(cx, cy, area, ent.surface.index)
    end

end

-- Save a Chunk inside the Chunks Tables --
function saveChunk(posX, posY, area, surfaceIndex)
    -- Create the Chunk Table --
    local chunkTable = {surfaceIndex=surfaceIndex, x=posX, y=posY, area=area, temp=initialTemperature, lastCheck=nil}
    -- Save the Chunk inside the 3D Chunk Table --
    global.chunksTable3D[surfaceIndex] = global.chunksTable3D[surfaceIndex] or {}
    global.chunksTable3D[surfaceIndex][posX] = global.chunksTable3D[surfaceIndex][posX] or {}
    global.chunksTable3D[surfaceIndex][posX][posY] = global.chunksTable3D[surfaceIndex][posX][posY] or chunkTable
    -- Save the Chunk inside the Chunk Table --
    table.insert(global.chunksTable, global.chunksTable3D[surfaceIndex][posX][posY])
    -- Return the chunk --
    return global.chunksTable3D[surfaceIndex][posX][posY]
end

-- Remove a Chunk from the Chunks Tables --
function removeChunk(chunk, key)

    -- Try to Remove the Chunk from the 3D Table --
    if global.chunksTable3D[chunk.surfaceIndex] ~= nil and global.chunksTable3D[chunk.surfaceIndex][chunk.x] ~= nil and global.chunksTable3D[chunk.surfaceIndex][chunk.x][chunk.y] ~= nil then
        global.chunksTable3D[chunk.surfaceIndex][chunk.x][chunk.y] = nil
        if table_size(global.chunksTable3D[chunk.surfaceIndex][chunk.x]) <= 0 then global.chunksTable3D[chunk.surfaceIndex][chunk.x] = nil end
        if table_size(global.chunksTable3D[chunk.surfaceIndex]) <= 0 then global.chunksTable3D[chunk.surfaceIndex] = nil end
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