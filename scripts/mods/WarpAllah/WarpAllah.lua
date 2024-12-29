-- File: scripts/mods/WarpAllah/WarpAllah.lua
-- (Ensure your folder & get_mod("<name>") match up.)
local mod = get_mod("WarpAllah")

------------------------------------------------------------------------------
-- 1. Require the original warp_charge module so we can hook it
--    The path below must match the Darktide decompiled folder structure.
------------------------------------------------------------------------------
local WarpCharge = require("scripts/utilities/warp_charge")

------------------------------------------------------------------------------
-- 2. Some optional data structures to store each player's (or unit's) peril
------------------------------------------------------------------------------

-- We'll keep a table of warp charge states, keyed by a unit.
-- Example: mod._warp_charge_data[unit] = { current_percentage=0, state="idle", etc. }
mod._warp_charge_data = {}

-- Simple utility to store or update the warp charge data for a given unit.
local function set_warp_data_for_unit(unit, warp_charge_component)
    if not mod._warp_charge_data[unit] then
        mod._warp_charge_data[unit] = {}
    end

    local data = mod._warp_charge_data[unit]
    data.current_percentage = warp_charge_component.current_percentage
    data.state = warp_charge_component.state
    -- Add anything else you want to track
end

------------------------------------------------------------------------------
-- 3. Hook the relevant WarpCharge functions
------------------------------------------------------------------------------
-- NOTE: We use hook_safe so that our code runs AFTER the original function
--       has finished updating warp_charge_component.

-- 3a) Hook: increase_immediate
mod:hook_safe(WarpCharge, "increase_immediate", function(t, charge_level, warp_charge_component, charge_template, owner_unit, warp_charge_modifier, prevent_explosion)
    -- The game has just updated warp_charge_component.current_percentage
    -- to the final value after all multipliers.

    -- Store it
    set_warp_data_for_unit(owner_unit, warp_charge_component)

    -- Optionally, show some debug info:
    mod:echo("[increase_immediate] final peril = %.2f (state=%s)", 
        warp_charge_component.current_percentage, 
        warp_charge_component.state
    )
end)

-- 3b) Hook: increase_over_time
mod:hook_safe(WarpCharge, "increase_over_time", function(dt, t, charge_level, warp_charge_component, charge_template, owner_unit, first_charge)
    set_warp_data_for_unit(owner_unit, warp_charge_component)

    mod:echo("[increase_over_time] final peril = %.2f (state=%s)", 
        warp_charge_component.current_percentage, 
        warp_charge_component.state
    )
end)

-- 3c) Hook: decrease_immediate
mod:hook_safe(WarpCharge, "decrease_immediate", function(remove_percentage, warp_charge_component, unit)
    set_warp_data_for_unit(unit, warp_charge_component)

    mod:echo("[decrease_immediate] final peril = %.2f (state=%s)", 
        warp_charge_component.current_percentage, 
        warp_charge_component.state
    )
end)

-- 3d) Hook: update_venting
mod:hook_safe(WarpCharge, "update_venting", function(dt, t, player, warp_charge_component)
    local player_unit = player.player_unit
    set_warp_data_for_unit(player_unit, warp_charge_component)

    mod:echo("[update_venting] final peril = %.2f (state=%s)", 
        warp_charge_component.current_percentage, 
        warp_charge_component.state
    )
end)


local function get_local_player_unit()
    local player = Managers and Managers.player and Managers.player:local_player(1)
    if not player or not Managers.player:local_player(1) then
    -- The local player isn't ready yet. Bail out.
    return
end
    return player and player.player_unit
end

local function get_peril_for_unit(unit)
    local data = mod._warp_charge_data[unit]
    if data then
        return data.current_percentage or 0
    end
    return 0
end

local function get_state_for_unit(unit)
    local data = mod._warp_charge_data[unit]
    if data then
        return data.state or "idle"
    end
    return "idle"
end

-- Example logic to detect if we are in the “pre-explosion” risk zone
local function is_in_explosion_risk(unit)
    local peril = get_peril_for_unit(unit)
    local state = get_state_for_unit(unit)
    return (peril >= 1.0 and state ~= "exploding")
end

------------------------------------------------------------------------------
-- 4. Possibly hook or override "can_vent" or "check_new_state" if you want 
--    to detect transitions to “exploding.” But hooking the above 4 functions 
--    is usually enough to see final peril values.
------------------------------------------------------------------------------

-- Example hooking check_new_state, purely for demonstration:
mod:hook_safe(WarpCharge, "check_new_state", function(warp_charge_component, prevent_explosion)
    mod:debug("[check_new_state] called. current_percentage=%.2f, prevent_explosion=%s", 
        warp_charge_component.current_percentage, 
        tostring(prevent_explosion)
    )
end)

------------------------------------------------------------------------------
-- 5. Reacting to the stored data (e.g. blocking input) 
--    You can then use mod._warp_charge_data in your InputService hook, or 
--    your mod.update() function to decide if you should block certain actions.
------------------------------------------------------------------------------

-- Example: a simplified InputService hook that references our stored peril:
local function is_in_explosion_risk(unit)
    local data = mod._warp_charge_data[unit]
    if data then
        local peril = data.current_percentage or 0
        local state = data.state or "idle"
        -- Some logic to say if it's "pre-explosion"
        return (peril >= 1.0 and state ~= "exploding")
    end
    return false
end

mod:hook("InputService", "_get", function(func, self, action_name)
    -- Original behavior
    local result = func(self, action_name)

    -- 4b) Possibly auto-fire if our test harness says so
    -- We only “fake press” if we see the game is checking "action_one_pressed"
    -- and mod._fire_shot_next_frame is true:
    if mod._fire_shot_next_frame and action_name == "action_one_pressed" then
        mod._fire_shot_next_frame = false
        mod:echo("Auto-Firing M1 for test!")
        return true  -- Fake a user press
    end

    -- 4c) Now do our blocking check, but ONLY if enable_blocking == true
    local blocking_enabled = mod:get("enable_blocking")
    if blocking_enabled then
        -- Only block certain actions, e.g. M1 (action_one) or special attack
        if action_name == "action_one_pressed"
        or action_name == "action_one_hold"
        or action_name == "action_one_release"
        or action_name == "weapon_extra_pressed"
        or action_name == "weapon_extra_hold"
        or action_name == "weapon_extra_release"
        then
            local player_unit = get_local_player_unit()
            if player_unit and Unit.alive(player_unit) then
                if is_in_explosion_risk(player_unit) then
                    mod:echo("[WarpAllah] BLOCKING %s (current peril=%.2f)", 
                        action_name, get_peril_for_unit(player_unit))
                    return false
                end
            end
        end
    end

    -- If we haven't blocked or forced any input, return the original
    return result
end)

------------------------------------------------------------------------------
-- 5. The mod.update(dt) logic for test harness: countdown to auto-fire
------------------------------------------------------------------------------

function mod.update(dt)
    local player_unit = get_local_player_unit()
    if not player_unit or not Unit.alive(player_unit) then
        return
    end

    local peril = get_peril_for_unit(player_unit)
    local state = get_state_for_unit(player_unit)
    local threshold = mod:get("test_peril_threshold") or 0.9

    -- Start the shot timer if we cross threshold & not exploding
    if not mod._test_active then
        if peril >= threshold and state ~= "exploding" then
            mod._test_active = true
            mod._test_timer = mod:get("test_shot_delay") or 1.0
            mod:echo("Peril=%.2f >= threshold=%.2f; starting shot timer (%.1fs).",
                peril, threshold, mod._test_timer)
        end
    end

    -- Decrement timer if active
    if mod._test_active then
        mod._test_timer = mod._test_timer - dt
        if mod._test_timer <= 0 then
            mod._test_active = false
            mod._test_timer = 0
            -- Queue an artificial M1 press for the next InputService:_get call
            mod._fire_shot_next_frame = true
        end
    end
end

return mod
-- Done! In real usage, you’d refine, remove debug prints, etc.
