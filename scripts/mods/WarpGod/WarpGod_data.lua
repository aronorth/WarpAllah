local mod = get_mod("WarpGod")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            -- Prevent Psyker Explosion Group
            {
                setting_id = "prevent_psyker_explosion",
                type = "group",
                sub_widgets = {
                    {
                        setting_id    = "prevent_psyker_explosion_enable",
                        type          = "checkbox",
                        default_value = true,
                        text          = mod:localize("prevent_psyker_explosion_enable"),
                        description   = mod:localize("prevent_psyker_explosion_enable_description"),
                    },
                    {
                        setting_id    = "macro_anti_detection_enable",
                        type          = "checkbox",
                        default_value = false,
                        text          = mod:localize("macro_anti_detection_enable"),
                        description   = mod:localize("macro_anti_detection_enable_description"),
                    },
                    {
                        setting_id      = "peril_threshold",
                        type            = "numeric",
                        range           = { 0.5, 1.0 }, -- Allowing thresholds between 50% and 100%
                        default_value   = 1.0,          -- Default to 100%
                        decimals_number = 2,
                        step_size_value = 0.01,
                        text            = mod:localize("peril_threshold"),
                        description     = mod:localize("peril_threshold_description"),
                    },
                },
            },
            -- Warp Unbound Bug Fix Group
            {
                setting_id = "warp_unbound_bug_fix",
                type = "group",
                sub_widgets = {
                    {
                        setting_id    = "warp_unbound_bug_fix_enable",
                        type          = "checkbox",
                        default_value = true,
                        text          = mod:localize("warp_unbound_bug_fix_enable"),
                        description   = mod:localize("warp_unbound_bug_fix_enable_description"),
                    },
                    {
                        setting_id      = "disable_duration",
                        type            = "numeric",
                        default_value   = 0.7,
                        range           = { 0, 1.5 },
                        decimals_number = 1,
                        step_size_value = 0.1,
                        text            = mod:localize("disable_duration"),
                        description     = mod:localize("disable_duration_description"),
                    },
                    {
                        setting_id      = "disable_start_delay",
                        type            = "numeric",
                        default_value   = 0.9,
                        range           = { 0, 1.5 },
                        decimals_number = 1,
                        step_size_value = 0.1,
                        text            = mod:localize("disable_start_delay"),
                        description     = mod:localize("disable_start_delay_description"),
                    },
                },
            },
        },
    },
}
