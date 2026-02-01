data:extend(
  {
    {
      name               = "greeble",
      type               = "selection-tool",
      order              = "c[automated-construction]-s[tile]",
      select             = {
        border_color    = { 255, 127, 0 },
        cursor_box_type = "copy",
        mode            = { "any-tile", "tile-ghost" },
      },
      alt_select         = {
        border_color    = { 127, 255, 0 },
        cursor_box_type = "copy",
        mode            = { "any-tile", "tile-ghost" },
      },
      reverse_select     = {
        border_color    = { 0, 127, 255 },
        cursor_box_type = "copy",
        mode            = { "any-tile", "avoid-vehicle", "entity-with-owner" },
      },
      alt_reverse_select = {
        border_color    = { 0, 255, 127 },
        cursor_box_type = "copy",
        mode            = { "nothing" },
      },
      icon               = "__greeble__/graphics/icons/planner.png",
      icon_size          = 64,
      stack_size         = 1,
      subgroup           = "tool",
      show_in_library    = false,
      flags              = { "not-stackable", "spawnable", "mod-openable" },
      can_be_mod_opened  = true,
    },
    {
      name                     = "give-greeble",
      type                     = "shortcut",
      order                    = "b[blueprints]-s[tile--planner]",
      action                   = "spawn-item",
      item_to_spawn            = "greeble",
      icon                     = "__greeble__/graphics/icons/shortcut.png",
      icon_size                = 32,
      small_icon               = "__greeble__/graphics/icons/shortcut.png",
      small_icon_size          = 32,
      associated_control_input = "give-greeble",
    },
    {
      name          = "give-greeble",
      type          = "custom-input",
      key_sequence  = "ALT + P",
      action        = "spawn-item",
      item_to_spawn = "greeble",
      consuming     = "game-only",
      order         = "b"
    },
    {
      name         = "greeble-open-menu",
      type         = "custom-input",
      key_sequence = "SHIFT + P",
      consuming    = "game-only",
      action       = "lua",
      order        = "a"
    },
    { -- These two are there because on_mod_item_opened and on_gui_closed fire both on right click. We are keeping track of the closed state of the menu when E and Escape are pressed
      name                = "greeble-close-menu-escape",
      type                = "custom-input",
      key_sequence        = "",
      linked_game_control = "toggle-menu"
    },
    {
      name                = "greeble-close-menu-e",
      type                = "custom-input",
      key_sequence        = "",
      linked_game_control = "confirm-gui"
    }
  }
)

data:extend(
  {
    {
      type = "item",
      name = "greeble-non-buildable-tile",
      icon = "__greeble__/graphics/icons/64x64.png",
      subgroup = "terrain",
      order = "c",
      stack_size = 1,
      place_as_tile =
      {
        result = "greeble-non-buildable-tile",
        condition_size = 1,
        condition = { layers = { ground_tile = true } }
      },
    },
    {
      type = "tile",
      name = "greeble-non-buildable-tile",
      needs_correction = false,
      collision_mask = { layers = { item = true, meltable = true, object = true, player = true, water_tile = true, is_object = true, is_lower_object = true } },
      walking_speed_modifier = 1.4,
      layer = 62,
      variants =
      {
        main = {
          {
            picture = "__greeble__/graphics/icons/32x32.png",
            count = 1,
            size = 1
          },
        },
        empty_transitions = true
      },
      map_color = { r = 200, g = 200, b = 200 },
      ageing = 0,
    },

  })
