pcall(require,'__debugadapter__/debugadapter.lua')

-- The initial temperature --
local initialTemperature = 20 -- °C --

-- The maximum natural temperature --
local maxNaturalTemperature = 25 -- °C --

-- The minimal temperature --
local minTemperature = -100 -- °C --

-- Number of Tick between each warming wave --
local warmingTime = 25000 -- A Factorio day --

-- How many degrees is added to all chunks during a warming wawe --
local warningWaveHeat = 0.1

-- Number of Tick between each Heat spread --
local spreadTime = 10800 -- Three minutes --

-- Number of Tick between each Erya check --
local eryaCheck = 3600 -- One minute --

-- Erya Tech freeze multiplier --
local freezeMultiplier = 5

-- Number of Tick between each Tile check --
local tileCheck = 3600 -- One minutes --

-- Number of check before a valid Tile was found --
local validTileCheck = 10

-- The max Chunk updates per tick --
local maxChunkUpdate = 30


-------------------------------- THIS TABLE IS USELESS --------------------------------
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

    -- Create the tableIndex --
    global.tableIndex = nil

    -- Create the Chunks update per Tick variable --
    global.chunksUpdatePerTick = maxChunkUpdate

    -- Get all surfaces --
    for k, surface in pairs(game.surfaces) do
        -- Add the Surface to the 3D Table --
        global.chunksTable3D[surface.index] = global.chunksTable3D[surface] or {}
        -- Get all Chunks --
        for chunk in surface.get_chunks() do

            -- Check if the Chunk is generated --
            if surface.is_chunk_generated(chunk) == true then

                -- Create the Chunk Table --
                local chunkTable = {surface=surface, x=chunk.x, y=chunk.y, area=chunk.area, temp=initialTemperature, lastWarmingTick=0, lastHeatSpread=0, lastEryaCheck = 0, lastTileCheck = 0}
                
                -- Add the x position inside the 3D Table --
                global.chunksTable3D[surface.index][chunk.x] = global.chunksTable3D[surface.index][chunk.x] or {}
                -- Add the y position inside the 3D Table --
                global.chunksTable3D[surface.index][chunk.x][chunk.y] = global.chunksTable3D[surface.index][chunk.x][chunk.y] or chunkTable

                -- Save the Chunk inside the Chunk Table --
                table.insert(global.chunksTable, global.chunksTable3D[surface.index][chunk.x][chunk.y])

            end

        end
    end

end

-- Called every Tick --
function onTick()

    -- Check the Index --
    if global.chunksTable[global.tableIndex] == nil or global.tableIndex == nil then
        -- Calcule how many Chunk must be updated per Tick --
        global.chunksUpdatePerTick = math.min(maxChunkUpdate, math.ceil( table_size(global.chunksTable)/60/60 ))
        -- Strat to the beginning of the Table --
        global.tableIndex = nil
    end

    -- game.print(global.chunksTable3D[game.players.mugiwaxar.surface.index][math.floor(game.players.mugiwaxar.position.x/32)][math.floor(game.players.mugiwaxar.position.y/32)].temp)

    -- Itinerate the Chunk Table --
    for i=1, global.chunksUpdatePerTick do

        -- Get the next non-nil Item --
        local k, chunkObj = next(global.chunksTable, global.tableIndex)

        -- Save the current Key --
        global.tableIndex = k

        -- Check the Chunk --
        if chunkObj ~= nil and chunkObj.surface ~= nil and chunkObj.surface.valid == true and chunkObj.surface.is_chunk_generated({chunkObj.x,chunkObj.y}) == true then
            -- Update the Temperature --
            updateTemperature(chunkObj)
            -- Update the Erya Frozen Effect --
            if game.tick - chunkObj.lastEryaCheck > eryaCheck then
                updateErya(chunkObj)
                chunkObj.lastEryaCheck = game.tick
            end
            -- Update all Tiles --
            if game.tick - chunkObj.lastTileCheck > tileCheck then
                updateTiles(chunkObj)
                chunkObj.lastTileCheck = game.tick
            end
        elseif k ~= nil and chunkObj.surface ~= nil and chunkObj.surface.valid == true then
            -- If the Chunk doesn't exist anymore --
            global.tableIndex = next(global.chunksTable, global.tableIndex)
            global.chunksTable3D[chunkObj.surface.index][chunkObj.x][chunkObj.y] = nil
            global.chunksTable[k] = nil
        elseif k ~= nil then
            -- If the Surface doesn't exist anymore --
            global.tableIndex = next(global.chunksTable, global.tableIndex)
            global.chunksTable[k] = nil
            -- Check all Surfaces --
            for k2, _ in pairs(global.chunksTable3D) do
                if game.get_surface(k2) == nil or game.get_surface(k2).valid == false then global.chunksTable3D[k2] = nil end
            end
        end

    end

end

-- Update a Chunk Temperature --
function updateTemperature(chunkObj)
    
    -- Up the temperature by 1°C if needed --
    if game.tick - chunkObj.lastWarmingTick > warmingTime and chunkObj.temp < maxNaturalTemperature then
        chunkObj.temp = math.min(maxNaturalTemperature, chunkObj.temp + warningWaveHeat)
        chunkObj.lastWarmingTick = game.tick
    end

    -- Equalize the temperature with neighbour Chunks --
    if game.tick - chunkObj.lastHeatSpread > spreadTime then
        -- North Chunk --
        if global.chunksTable3D[chunkObj.surface.index][chunkObj.x][chunkObj.y-1] ~= nil then
            local chunk = global.chunksTable3D[chunkObj.surface.index][chunkObj.x][chunkObj.y-1]
            if chunkObj.temp > chunk.temp then
                chunkObj.temp = chunkObj.temp - ( (chunkObj.temp-chunk.temp)/10 )
                chunk.temp = chunk.temp + ( (chunkObj.temp-chunk.temp)/10 )
            else
                chunkObj.temp = chunkObj.temp + ( (chunk.temp-chunkObj.temp)/10 )
                chunk.temp = chunk.temp - ( (chunk.temp-chunkObj.temp)/10 )
            end
        end
        -- East Chunk --
        if global.chunksTable3D[chunkObj.surface.index][chunkObj.x+1] ~= nil and global.chunksTable3D[chunkObj.surface.index][chunkObj.x+1][chunkObj.y] ~= nil then
            local chunk = global.chunksTable3D[chunkObj.surface.index][chunkObj.x+1][chunkObj.y]
            if chunkObj.temp > chunk.temp then
                chunkObj.temp = chunkObj.temp - ( (chunkObj.temp-chunk.temp)/10 )
                chunk.temp = chunk.temp + ( (chunkObj.temp-chunk.temp)/10 )
            else
                chunkObj.temp = chunkObj.temp + ( (chunk.temp-chunkObj.temp)/10 )
                chunk.temp = chunk.temp - ( (chunk.temp-chunkObj.temp)/10 )
            end
        end
        -- South Chunk --
        if global.chunksTable3D[chunkObj.surface.index][chunkObj.x][chunkObj.y+1] ~= nil then
            local chunk = global.chunksTable3D[chunkObj.surface.index][chunkObj.x][chunkObj.y+1]
            if chunkObj.temp > chunk.temp then
                chunkObj.temp = chunkObj.temp - ( (chunkObj.temp-chunk.temp)/10 )
                chunk.temp = chunk.temp + ( (chunkObj.temp-chunk.temp)/10 )
            else
                chunkObj.temp = chunkObj.temp + ( (chunk.temp-chunkObj.temp)/10 )
                chunk.temp = chunk.temp - ( (chunk.temp-chunkObj.temp)/10 )
            end
        end
        -- West Chunk --
        if global.chunksTable3D[chunkObj.surface.index][chunkObj.x-1] ~= nil and global.chunksTable3D[chunkObj.surface.index][chunkObj.x-1][chunkObj.y] ~= nil then
            local chunk = global.chunksTable3D[chunkObj.surface.index][chunkObj.x-1][chunkObj.y]
            if chunkObj.temp > chunk.temp then
                chunkObj.temp = chunkObj.temp - ( (chunkObj.temp-chunk.temp)/10 )
                chunk.temp = chunk.temp + ( (chunkObj.temp-chunk.temp)/10 )
            else
                chunkObj.temp = chunkObj.temp + ( (chunk.temp-chunkObj.temp)/10 )
                chunk.temp = chunk.temp - ( (chunk.temp-chunkObj.temp)/10 )
            end
        end
        chunkObj.lastHeatSpread = game.tick
    end

end

-- Update the Chunk Erya Tech --
function updateErya(chunkObj)
    -- Find all Erya Tech --
    local eryaEnts = chunkObj.surface.find_entities_filtered{area=chunkObj.area, name=frozenStructures}
    if table_size(eryaEnts) <= 0 then return end
    -- Decrease the Temperature of the Chunk --
    for k, ent in pairs(eryaEnts) do
        chunkObj.temp = chunkObj.temp - ((heatCost[ent.name] or 0) * freezeMultiplier)
    end
    -- Check if the temperature is not too low --
    chunkObj.temp = math.max(minTemperature, chunkObj.temp)
    -- log(chunkObj.temp)
end

-- Update the Chunk Tiles --
function updateTiles(chunkObj)
    -- Create the Loop --
    for i=1, validTileCheck do
        -- Get random Locations --
        local x = math.random(1,32)
        local y = math.random(1,32)
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
                        -- game.print("Set normal tile")
                        -- break
                    end
                end
            elseif tile.name ~= "MFSnowTile1" and chunkObj.temp <= 0 then
                -- Create Snow Tiles --
                local xPos = -2
                local yPos = -2
                while xPos < 4 do
                    while yPos < 4 do
                        local position = {tile.position.x + xPos, tile.position.y + yPos}
                        local oldTile = chunkObj.surface.get_tile(position)
                        tile.surface.set_hidden_tile(position, oldTile.name)
                        local tileName = waterTiles[oldTile.name] == nil and "MFSnowTile1" or "MFIceTile1"
                        tile.surface.set_tiles({{name=tileName, position=position}})
                        yPos = yPos + 1
                    end
                    yPos = -2
                    xPos = xPos + 1
                end
                break
            end
        end
    end
end

-- Called when a new Chunk is generated --
function onNewChunk(event)
    -- Get Values --
    local area = event.area
    local position = event.position
    local surface = event.surface
    -- Create the Chunk Table --
    local chunkTable = {surface=surface, x=position.x, y=position.y, area=area, temp=initialTemperature, lastWarmingTick=0, lastHeatSpread=0, lastEryaCheck = 0, lastTileCheck = 0}
    -- Save the Chunk inside the 3D Chunk Table --
    global.chunksTable3D[surface.index] = global.chunksTable3D[surface.index] or {}
    global.chunksTable3D[surface.index][position.x] = global.chunksTable3D[surface.index][position.x] or {}
    global.chunksTable3D[surface.index][position.x][position.y] = global.chunksTable3D[surface.index][position.x][position.y] or chunkTable
    -- Save the Chunk inside the Chunk Table --
    table.insert(global.chunksTable, global.chunksTable3D[surface.index][position.x][position.y])
end

-- Event --
script.on_init(onInit)
script.on_event(defines.events.on_tick, onTick)
script.on_event(defines.events.on_chunk_generated, onNewChunk)


--------------------------- Interface ---------------------------

-- Return the Chunk Temperature --
function getChunkTemp(surfaceIndex, x, y)
    if global.chunksTable3D == nil or global.chunksTable3D[surfaceIndex] == nil or global.chunksTable3D[surfaceIndex][x] == nil or global.chunksTable3D[surfaceIndex][x][y] == nil or global.chunksTable3D[surfaceIndex][x][y].temp == nil then
        return 20
    end
    return global.chunksTable3D[surfaceIndex][x][y].temp
end

-- Create the Interface --
remote.add_interface("EryaCom", {
    getChunkTemp=getChunkTemp,
})