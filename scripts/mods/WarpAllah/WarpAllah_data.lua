local mod = get_mod("WarpAllah")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
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
                        setting_id      = "interval1_duration",
                        type            = "numeric",
                        default_value   = 0.8,
                        range           = { 0, 1.5 },
                        decimals_number = 1,
                        step_size_value = 0.1,
                        text            = mod:localize("interval1_duration"),
                        description     = mod:localize("interval1_duration_description"),
                    },
                    {
                        setting_id      = "interval1_start_delay",
                        type            = "numeric",
                        default_value   = 0.9,
                        range           = { 0, 1.5 },
                        decimals_number = 1,
                        step_size_value = 0.1,
                        text            = mod:localize("interval1_start_delay"),
                        description     = mod:localize("interval1_start_delay_description"),
                    },
                    {
                        setting_id      = "interval2_duration",
                        type            = "numeric",
                        default_value   = 0.6,
                        range           = { 0, 1 },
                        decimals_number = 1,
                        step_size_value = 0.1,
                        text            = mod:localize("interval2_duration"),
                        description     = mod:localize("interval2_duration_description"),
                    },
                    {
                        setting_id      = "interval2_end_delay",
                        type            = "numeric",
                        default_value   = 0.3,
                        range           = { 0, 0.5 },
                        decimals_number = 1,
                        step_size_value = 0.1,
                        text            = mod:localize("interval2_end_delay"),
                        description     = mod:localize("interval2_end_delay_description"),
                    },
                },
            },
        },
    },
}
