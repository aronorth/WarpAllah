local mod = get_mod("WarpAllah")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id    = "enable_blocking",
                type          = "checkbox",
                default_value = true,
                title         = "Enable Peril Blocking?",
                tooltip       = "If ON, the mod will block M1 actions when in the risk zone."
            },
            {
                setting_id    = "test_peril_threshold",
                type          = "numeric",
                default_value = 0.90,
                range         = {0, 1.0},
                decimals_number = 2,
                title         = "Peril Threshold to Trigger Timer",
                tooltip       = "If peril >= this value, start countdown to auto-fire."
            },
            {
                setting_id    = "test_shot_delay",
                type          = "numeric",
                default_value = 1.0,
                range         = {0, 3.0},
                decimals_number = 1,
                title         = "Auto-Fire Delay (seconds)",
                tooltip       = "Time from crossing peril threshold to auto-firing a shot."
            }
        }
    }
}
