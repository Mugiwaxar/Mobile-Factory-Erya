-- Add the Erya Sample to all Labs --
if data.raw.lab.DimensionalLab.inputs.EryaSample == nil then
    table.insert(data.raw.lab.DimensionalLab.inputs, "EryaSample")
end

-- Add the Ice as a water type --
table.insert(water_tile_type_names, "MFIceTile1")