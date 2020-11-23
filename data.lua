require("prototypes/erya/erya-intermediates.lua")
require("prototypes/erya/erya-collector.lua")
require("prototypes/erya/erya-structures.lua")
require("prototypes/winter/snow-tiles.lua")

data:extend{
	{
		type="item-group",
		name="Erya",
		icon="__Mobile_Factory-Erya__/graphics/Erya/EryaPowder.png",
		icon_size="256",
		order="y"
	}
}

data:extend{
	{
		type="item-subgroup",
		name="EryaRessources",
		group="Erya",
		order="a"
	}
}

data:extend{
	{
		type="item-subgroup",
		name="EryaIntermediates",
		group="Erya",
		order="b"
	}
}

data:extend{
	{
		type="item-subgroup",
		name="EryaLogistic",
		group="Erya",
		order="c"
	}
}

data:extend{
	{
		type="item-subgroup",
		name="EryaProduction",
		group="Erya",
		order="d"
	}
}

data:extend{
	{
		type="item-subgroup",
		name="EryaWar",
		group="Erya",
		order="e"
	}
}

data:extend{
	{
		type="recipe-category",
		name="EryaPowder",
		order="d"
	}
}