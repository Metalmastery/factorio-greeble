-- #tag settings_config
return {
    -- import settings
    IMPORT_REMOVE_DUPLICATES = {
        type = "bool-setting",
        name = "import-remove-duplicates",
        setting_type = "runtime-global",
        default_value = true,
        order = 'aaa'
    },
    IMPORT_INCLUDE_ROTATED = {
        type = "bool-setting",
        name = "import-include-rotated-tiles",
        setting_type = "runtime-global",
        default_value = true,
        order = 'aaa'
    },
    IMPORT_INCLUDE_REFLECTED = {
        type = "bool-setting",
        name = "import-include-reflected-tiles",
        setting_type = "runtime-global",
        default_value = true,
        order = 'aaa'
    },
    IMPORT_SKIP_INTERMEDIATE = {
        type = "bool-setting",
        name = "import-skip-intermediate-tiles",
        setting_type = "runtime-global",
        default_value = false,
        order = 'aaa'
    },
    IMPORT_TILE_SIZE = {
        type = "int-setting",
        name = "import-tile-size",
        setting_type = "runtime-global",
        minimum_value = 2,
        maximum_value = 10,
        default_value = 3,
        order = 'aaa'
    },

    -- render settings
    RENDER_PRESERVE_EXISTING_TILES = {
        type = "bool-setting",
        name = "render-preserve-existing-tiles",
        setting_type = "runtime-global",
        default_value = true,
        order = 'aab'
    },
    RENDER_AVOID_BUILDINGS = {
        type = "bool-setting",
        name = "render-avoid-buildings",
        setting_type = "runtime-global",
        default_value = false,
        order = 'aab'
    },
    RENDER_OUTLINE_BUILDINGS = {
        type = "bool-setting",
        name = "render-outline-buildings",
        setting_type = "runtime-global",
        default_value = false,
        order = 'aab'
    },
    RENDER_SPREAD_TILES = {
        type = "bool-setting",
        name = "render-spread-tiles",
        setting_type = "runtime-global",
        default_value = false,
        order = 'aab'
    },
    RENDER_OVERLAP_TILES = {
        type = "bool-setting",
        name = "render-overlap-tiles",
        setting_type = "runtime-global",
        default_value = true,
        order = 'aab'
    },

    WFC_SYMMETRY_HORIZONTAL = {
        type = "bool-setting",
        name = "wfc-symmetry-horizontal",
        setting_type = "runtime-global",
        default_value = false,
        order = 'aac'
    },
    WFC_SYMMETRY_VERTICAL = {
        type = "bool-setting",
        name = "wfc-symmetry-vertical",
        setting_type = "runtime-global",
        default_value = false,
        order = 'aac'
    },

    -- wfc settings
    WFC_CHUNK_SIZE = {
        type = "int-setting",
        name = "wfc-chunk-size",
        setting_type = "runtime-global",
        minimum_value = 2,
        maximum_value = 10,
        default_value = 3,
        order = 'aad'
    },

    -- wfc solving settings
    WFC_SOLVE_ATTEMPTS_LIMIT = {
        type = "int-setting",
        name = "wfc-solve-attempts-limit",
        setting_type = "runtime-global",
        minimum_value = 100,
        maximum_value = 10000,
        default_value = 100,
        order = 'aad'
    },
    WFC_SOLVE_ATTEMPTS_PER_TICK = {
        type = "int-setting",
        name = "wfc-solve-attempts-per-tick",
        setting_type = "runtime-global",
        minimum_value = 1,
        maximum_value = 100,
        default_value = 10,
        order = 'aad'
    },

    -- visible simplified settings
    WFC_SYMMETRY = {
        type = "string-setting",
        name = "wfc-symmetry",
        setting_type = "runtime-global",
        allowed_values = { "none", "horizontal", "vertical", "both" },
        default_value = "none",
        hidden = true,
    },

    TILE_IMPORT = {
        type = "string-setting",
        name = "tile-import",
        setting_type = "runtime-global",
        allowed_values = { "full cover", "tiles with overlap", "premade tileset" },
        default_value = "full cover",
        hidden = true
    },

    TILE_VARIATION = {
        type = "string-setting",
        name = "tile-variation",
        setting_type = "runtime-global",
        allowed_values = { "everything", "rotations only", "reflections only" },
        default_value = "everything",
        hidden = true
    },

    FLOOR_TREATMENT = {
        type = "string-setting",
        name = "floor-treatment",
        setting_type = "runtime-global",
        allowed_values = { "override", "preserve", "use as mask" },
        default_value = "preserve",
        hidden = true
    },

    ENTITY_TREATMENT = {
        type = "string-setting",
        name = "entity-treatment",
        setting_type = "runtime-global",
        allowed_values = { "ignore", "avoid", "outline" },
        default_value = "ignore",
        hidden = true
    },

}
