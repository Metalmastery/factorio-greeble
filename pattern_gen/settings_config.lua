-- #tag settings_config
return {
    -- import settings
    IMPORT_AS_TILES = {
        type = "bool-setting",
        name = "import-as-tiles",
        setting_type = "runtime-global",
        default_value = false,
    },
    INCLUDE_ROTATED = {
        type = "bool-setting",
        name = "include-rotated-tiles",
        setting_type = "runtime-global",
        default_value = true,
        -- value = true
    },
    INCLUDE_MIRRORED = {
        type = "bool-setting",
        name = "include-mirrored-tiles",
        setting_type = "runtime-global",
        default_value = true,
        -- value = true
    },
    SKIP_INTERMEDIATE = {
        type = "bool-setting",
        name = "skip-intermediate-tiles",
        setting_type = "runtime-global",
        default_value = false,
        -- value = false
    },
    TILE_SIZE = {
        type = "int-setting",
        name = "tile-size",
        setting_type = "runtime-global",
        minimum_value = 2,
        maximum_value = 10,
        default_value = 3,
        -- value = false
    },

    -- render settings
    PRESERVE_EXISTING_TILES = {
        type = "bool-setting",
        name = "preserve-existing-tiles",
        setting_type = "runtime-global",
        default_value = true,
    },
    AVOID_BUILDINGS = {
        type = "bool-setting",
        name = "avoid-buildings",
        setting_type = "runtime-global",
        default_value = false,
    },
    OUTLINE_BUILDINGS = {
        type = "bool-setting",
        name = "outline-buildings",
        setting_type = "runtime-global",
        default_value = false,
        -- value = false
    },
    SPREAD = {
        type = "bool-setting",
        name = "spread-tiles",
        setting_type = "runtime-global",
        default_value = false,
        -- value = false
    },
    OVERLAP = {
        type = "bool-setting",
        name = "overlap-tiles",
        setting_type = "runtime-global",
        default_value = true,
        -- value = true
    },

    -- wfc settings
    CHUNK_SIZE = {
        type = "int-setting",
        name = "chunk-size",
        setting_type = "runtime-global",
        minimum_value = 2,
        maximum_value = 10,
        default_value = 3,
        -- value = false
    },
    GRID_SIZE = {
        type = "int-setting",
        name = "grid-size",
        setting_type = "runtime-global",
        minimum_value = 5,
        maximum_value = 50,
        default_value = 10,
        -- value = false
    },

    -- wfc solving settings
    ATTEMPTS_LIMIT = {
        type = "int-setting",
        name = "attempts-limit",
        setting_type = "runtime-global",
        minimum_value = 100,
        maximum_value = 10000,
        default_value = 100,
        -- value = false
    },
    ATTEMPTS_PER_TICK = {
        type = "int-setting",
        name = "attempts-per-tick",
        setting_type = "runtime-global",
        minimum_value = 1,
        maximum_value = 100,
        default_value = 10,
    }
}
