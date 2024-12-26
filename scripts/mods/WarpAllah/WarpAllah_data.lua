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
                },
            },
        },
    },
}
