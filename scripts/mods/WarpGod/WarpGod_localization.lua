local mod = get_mod("WarpGod")

local loc = {
    mod_name = {
        en = "Warp God",
    },
    mod_description = {
        en = "Warp Unbound talent hotfix, Warp Unbound talent QoL, Peril of the Warp Explosion Prevention",
    },
    hud_scale = {
		en = "Size Scale",
	},
    -- Prevent Psyker Explosion
    prevent_psyker_explosion = {
        en = "Prevent Psyker Explosion",
    },
    prevent_psyker_explosion_enable = {
        en = "Enable Prevent Psyker Explosion",
    },
    prevent_psyker_explosion_enable_description = {
        en = "Disables the Left Mouse Button when peril reaches the set threshold and Warp Unbound ability is not active, preventing accidental overcharge explosions.",
    },
    macro_anti_detection_enable = {
        en = "Enable Macro Anti-Detection",
    },
    macro_anti_detection_enable_description = {
        en = "Disables the quell button when Psyker explosion is prevented, used to hide usage of quell-cancel macro",
    },
    peril_threshold = {
        en = "Peril Threshold",
    },
    peril_threshold_description = {
        en = "Set the peril level at which the Left Mouse Button is disabled to prevent explosions. Default is 100%%.", -- Escaped %%
    },
    -- Warp Unbound Bug Fix
    warp_unbound_bug_fix = {
        en = "Warp Unbound Bug Fix",
    },
    warp_unbound_bug_fix_enable = {
        en = "Enable Warp Unbound Bug Fix",
    },
    warp_unbound_bug_fix_enable_description = {
        en = "Disables LMB for a certain duration when using the Warp Unbound ability to prevent accidental explosions.",
    },
    disable_duration = {
        en = "Disable Duration",
    },
    disable_duration_description = {
        en = "The duration (in seconds) for which the LMB is disabled when using the Warp Unbound ability.",
    },
    disable_start_delay = {
        en = "Disable Start Delay",
    },
    disable_start_delay_description = {
        en = "The delay (in seconds) before LMB is disabled when using the Warp Unbound ability.",
    },
}

return loc
