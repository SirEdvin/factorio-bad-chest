local parameterize = require("__rec-blue-plus__/lualib/parameterization")

local function check_recipe(blueprint, replacement, expected, quality)
  blueprint.set_blueprint_entities{{
    entity_number = 1, name = "assembling-machine-1", position = {0, 0}, recipe = "parameter-0"
  }}
  parameterize({
    {signal = {type = "virtual", name = "signal-0"}, count = 23},
    {signal = {type = "recipe", name = replacement, quality = quality}, count = 23}
  }, blueprint)
  local entity = blueprint.get_blueprint_entities()[1]
  assert(entity.recipe == expected, replacement .. ": unexpected recipe " .. tostring(entity.recipe))
  assert((entity.recipe_quality or "normal") == (quality or "normal"), "recipe quality changed")
  storage.checks = storage.checks + 1
end

script.on_init(function()
  storage.checks = 0
  local inventory = game.create_inventory(1)
  local blueprint = inventory[1]
  blueprint.set_stack{name = "blueprint"}
  check_recipe(blueprint, "copper-cable", "copper-cable")
  local categories = prototypes.recipe["rbp-test-multiple-categories"].categories
  assert(categories[1] == "rbp-test-unsupported" and categories[2] == "crafting")
  check_recipe(blueprint, "rbp-test-multiple-categories", "rbp-test-multiple-categories")
  check_recipe(blueprint, "iron-plate", "parameter-0")
  check_recipe(blueprint, "rbp-test-missing-recipe", "parameter-0")
  if script.active_mods["quality"] then
    check_recipe(blueprint, "copper-cable", "copper-cable", "uncommon")
  end
  inventory.destroy()

  local space_age = script.active_mods["space-age"]
  local surface = space_age and game.planets.vulcanus.create_surface() or game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-32, -32}, {32, 32}}}) do
    entity.destroy()
  end
  local tiles = {}
  for x = -32, 31 do
    for y = -32, 31 do tiles[#tiles + 1] = {name = "stone-path", position = {x, y}} end
  end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.chart(surface, {{-32, -32}, {32, 32}})
  local recipes = space_age and {"casting-copper-cable", "molten-copper-from-lava"}
    or {"copper-cable", "iron-gear-wheel"}
  local machine = space_age and "foundry" or "assembling-machine-1"
  for _, name in pairs(recipes) do force.recipes[name].enabled = true end
  local chest = surface.create_entity{
    name = "blueprint-deployer2", position = {-12, -12}, force = force, raise_built = true
  }
  local source = chest.get_inventory(defines.inventory.chest)[1]
  source.set_stack{name = "blueprint"}
  source.set_blueprint_entities{
    {entity_number = 1, name = machine, position = {0, 0}, recipe = "parameter-0"},
    {entity_number = 2, name = machine, position = {8, 0}, recipe = "parameter-1"}
  }
  local combinator = surface.create_entity{
    name = "constant-combinator", position = {-10, -12}, force = force
  }
  combinator.get_or_create_control_behavior().get_section(1).filters = {
    {value = {type = "virtual", name = "rbp-command", quality = "normal"}, min = 2},
    {value = {type = "virtual", name = "rbp-wait", quality = "normal"}, min = 1000},
    {value = {type = "virtual", name = "signal-X", quality = "normal"}, min = 20},
    {value = {type = "virtual", name = "signal-Y", quality = "normal"}, min = 20},
    {value = {type = "virtual", name = "signal-0", quality = "normal"}, min = 23},
    {value = {type = "virtual", name = "signal-1", quality = "normal"}, min = 24},
    {value = {type = "recipe", name = recipes[1], quality = "normal"}, min = 23},
    {value = {type = "recipe", name = recipes[2], quality = "normal"}, min = 24}
  }
  local wire = defines.wire_connector_id.circuit_red
  assert(combinator.get_wire_connector(wire, true).connect_to(chest.get_wire_connector(wire, true)))
  storage.chest = chest
  storage.recipes = recipes
  storage.machine = machine
  log("RBP recipe checks passed: " .. storage.checks)
end)

script.on_event(defines.events.on_tick, function(event)
  if event.tick < 10 or storage.verified then return end
  local chest = storage.chest
  local wire = defines.wire_connector_id.circuit_red
  for i, name in ipairs(storage.recipes) do
    assert(chest.get_signal({type = "recipe", name = name}, wire) == 22 + i, "missing recipe signal")
  end
  local ghosts = chest.surface.find_entities_filtered{type = "entity-ghost", ghost_name = storage.machine}
  assert(#ghosts == 2, "expected two deployed machines, got " .. #ghosts)
  local recipes = {}
  for _, ghost in pairs(ghosts) do
    local recipe = ghost.get_recipe()
    assert(recipe, "deployed machine has no recipe")
    recipes[recipe.name] = true
  end
  for _, name in ipairs(storage.recipes) do assert(recipes[name], "missing deployed recipe: " .. name) end
  local original = chest.get_inventory(defines.inventory.chest)[1].get_blueprint_entities()
  assert(original[1].recipe == "parameter-0" and original[2].recipe == "parameter-1", "source blueprint mutated")
  storage.verified = true
  helpers.write_file("recipe-regression.json", helpers.table_to_json{
    passed = true, checks = storage.checks, deployed_recipes = storage.recipes,
    source_blueprint_unchanged = true, mod_version = script.active_mods["rec-blue-plus"],
    space_age = script.active_mods["space-age"] ~= nil
  }, false)
  log("RBP command 2 deployment passed")
end)
