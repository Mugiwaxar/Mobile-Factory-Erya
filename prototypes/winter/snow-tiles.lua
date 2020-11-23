-- Snow Tile 1 --
local st1E = table.deepcopy(data.raw.tile["grass-1"])
st1E.name = "MFSnowTile1"
st1E.autoplace = nil
st1E.map_color = {1,1,1}
st1E.walking_speed_modifier = 0.85
st1E.variants = tile_variations_template(
	"__Mobile_Factory-Erya__/graphics/winter/snow-tile-1.png", "__base__/graphics/terrain/masks/transition-3.png",
	"__Mobile_Factory-Erya__/graphics/winter/hr-snow-tile-1.png", "__base__/graphics/terrain/masks/hr-transition-3.png",
	{
	  max_size = 4,
	  [1] = { weights = {0.085, 0.085, 0.085, 0.085, 0.087, 0.085, 0.065, 0.085, 0.045, 0.045, 0.045, 0.045, 0.005, 0.025, 0.045, 0.045 } },
	  [2] = { probability = 0.91, weights = {0.150, 0.150, 0.150, 0.150, 0.018, 0.020, 0.015, 0.025, 0.015, 0.020, 0.025, 0.015, 0.025, 0.025, 0.010, 0.025 }, },
	  [4] = { probability = 0.91, weights = {0.100, 0.80, 0.80, 0.100, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01 }, },
	  --[8] = { probability = 1.00, weights = {0.090, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.025, 0.125, 0.005, 0.010, 0.100, 0.100, 0.010, 0.020, 0.020} }
	}
  )
data:extend{st1E}

-- Ice Tile 1 --
local it1E = {} -- table.deepcopy(data.raw.tile.water)
it1E.name = "MFIceTile1"
it1E.type = "tile"
it1E.autoplace = nil
it1E.draw_in_water_layer = true
it1E.layer = 3
it1E.map_color={r=0.0941, g=0.149, b=0.066}
it1E.pollution_absorption_per_second = 0
it1E.transitions = data.raw.tile.water.transitions
it1E.walking_speed_modifier = 0.8
it1E.collision_mask =
{
  "water-tile",
  "item-layer",
  "resource-layer",
  -- "player-layer",
  "doodad-layer"
}
it1E.variants =
    {
      main =
      {
        {
			picture = "__Mobile_Factory-Erya__/graphics/winter/hr-ice1.png",
            count = 1,
            scale = 0.5,
            size = 1
        },
        {
			picture = "__Mobile_Factory-Erya__/graphics/winter/hr-ice2.png",
            count = 1,
            scale = 0.5,
            size = 2
        },
        {
			picture = "__Mobile_Factory-Erya__/graphics/winter/hr-ice3.png",
            count = 1,
            scale = 0.5,
            size = 4
        }
      },
      empty_transitions = true,
	}
data:extend{it1E}