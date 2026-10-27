data:extend{{type = "recipe-category", name = "rbp-test-unsupported"}}
local recipe = table.deepcopy(data.raw.recipe["copper-cable"])
recipe.name = "rbp-test-multiple-categories"
recipe.categories = {"rbp-test-unsupported", "crafting"}
recipe.hidden = true
recipe.auto_recycle = false
data:extend{recipe}
