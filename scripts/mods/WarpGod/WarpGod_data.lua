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
                        setting_id = "prevent_psyker_explosion_enable",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            -- Show Warp Unbound Timer Group
            {
                setting_id = "warp_unbound_timer",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "warp_unbound_timer_enable",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "play_notification",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            -- Warp Unbound Bug Fix Group
            {
                setting_id = "warp_unbound_bug_fix",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "warp_unbound_bug_fix_enable",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "disable_duration",
                        type = "numeric",
                        default_value = 0.7,
                        range = { 0, 1.5 },
                        decimals_number = 1,
                    },
                    {
                        setting_id = "disable_start_delay",
                        type = "numeric",
                        default_value = 0.9,
                        range = { 0, 1.5 },
                        decimals_number = 1,
                    },
                },
            },
        },
    },
}
