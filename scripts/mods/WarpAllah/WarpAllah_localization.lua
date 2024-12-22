local mod = get_mod("WarpAllah")

local loc = {
    mod_name = {
        en = "Warp Allah",
    },
    mod_description = {
        en = "Warp Unbound talent bug hotfix",
    },
    -- Warp Unbound Bug Fix
    warp_unbound_bug_fix = {
        en = "Warp Unbound Bug Fix",
    },
    warp_unbound_bug_fix_enable = {
        en = "Enable Warp Unbound Bug Fix",
    },
    warp_unbound_bug_fix_enable_description = {
        en = "Warp Unbound last 11.5s, at sometime around 10.5s there is a probability to explode with Smite, Surge & Trauma staffs. Bugfix disables attacks that generate peril during a interval.",
    },
    interval1_duration = {
        en = "Start-interval duration",
    },
    interval1_duration_description = {
        en = "For the bugfix interval. Default is 0.7",
    },
    interval1_start_delay = {
        en = "Start-interval offset",
    },
    interval1_start_delay_description = {
        en = "For the Bugfix interval interval to offset interval to start later. Default is 0.9",
    },
    interval2_duration = {
        en = "End-interval duration",
    },
    interval2_duration_description = {
        en = "For the end of Warp Unbound buff. Default is 0.5",
    },
    interval2_end_delay = {
        en = "End-interval offset",
    },
    interval2_end_delay_description = {
        en = "For the end of Warp Unbound buff to offset interval to end later. Default is 0.2",
    },
}

return loc
