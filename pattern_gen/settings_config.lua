-- #tag settings_config
return {
    -- import settings
    IMPORT_AS_TILES = {
        type = "bool-setting",
        name = "import-as-tiles",
        setting_type = "runtime-global",
        default_value = false,
    },
    IMPORT_INCLUDE_ROTATED = {
        type = "bool-setting",
        name = "import-include-rotated-tiles",
        setting_type = "runtime-global",
        default_value = true,

    },
    IMPORT_INCLUDE_REFLECTED = {
        type = "bool-setting",
        name = "import-include-reflected-tiles",
        setting_type = "runtime-global",
        default_value = true,

    },
    IMPORT_SKIP_INTERMEDIATE = {
        type = "bool-setting",
        name = "import-skip-intermediate-tiles",
        setting_type = "runtime-global",
        default_value = false,
        -- value = false
    },
    IMPORT_TILE_SIZE = {
        type = "int-setting",
        name = "import-tile-size",
        setting_type = "runtime-global",
        minimum_value = 2,
        maximum_value = 10,
        default_value = 3,
        -- value = false
    },

    -- render settings
    RENDER_PRESERVE_EXISTING_TILES = {
        type = "bool-setting",
        name = "render-preserve-existing-tiles",
        setting_type = "runtime-global",
        default_value = true,
    },
    RENDER_AVOID_BUILDINGS = {
        type = "bool-setting",
        name = "render-avoid-buildings",
        setting_type = "runtime-global",
        default_value = false,
    },
    RENDER_OUTLINE_BUILDINGS = {
        type = "bool-setting",
        name = "render-outline-buildings",
        setting_type = "runtime-global",
        default_value = false,
        -- value = false
    },
    RENDER_SPREAD_TILES = {
        type = "bool-setting",
        name = "render-spread-tiles",
        setting_type = "runtime-global",
        default_value = false,
        -- value = false
    },
    RENDER_OVERLAP_TILES = {
        type = "bool-setting",
        name = "render-overlap-tiles",
        setting_type = "runtime-global",
        default_value = true,

    },

    WFC_SYMMETRY_HORIZONTAL = {
        type = "bool-setting",
        name = "wfc-symmetry-horizontal",
        setting_type = "runtime-global",
        default_value = true,
    },
    WFC_SYMMETRY_VERTICAL = {
        type = "bool-setting",
        name = "wfc-symmetry-vertical",
        setting_type = "runtime-global",
        default_value = false,
    },

    -- wfc settings
    WFC_CHUNK_SIZE = {
        type = "int-setting",
        name = "wfc-chunk-size",
        setting_type = "runtime-global",
        minimum_value = 2,
        maximum_value = 10,
        default_value = 3,
        -- value = false
    },

    -- wfc solving settings
    WFC_SOLVE_ATTEMPTS_LIMIT = {
        type = "int-setting",
        name = "wfc-solve-attempts-limit",
        setting_type = "runtime-global",
        minimum_value = 100,
        maximum_value = 10000,
        default_value = 100,
        -- value = false
    },
    WFC_SOLVE_ATTEMPTS_PER_TICK = {
        type = "int-setting",
        name = "wfc-solve-attempts-per-tick",
        setting_type = "runtime-global",
        minimum_value = 1,
        maximum_value = 100,
        default_value = 10,
    }
}
