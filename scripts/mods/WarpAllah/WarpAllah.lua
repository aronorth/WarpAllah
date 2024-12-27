--[[ 
File: scripts/mods/WarpAllah/WarpAllah.lua
(Ensure your folder name & get_mod("<name>") match!)
--]]

local mod = get_mod("WarpAllah")

--------------------------------------------------------------------------------
-- 1. Require the warp_charge module so we can hook it
--    (Adjust this path based on your decompiled folder structure!)
--------------------------------------------------------------------------------
local WarpCharge = require("scripts/utilities/warp_charge")

--------------------------------------------------------------------------------
-- 2. We store the warp charge data for each unit after each update
--------------------------------------------------------------------------------
mod._warp_charge_data = {}

local function set_warp_data_for_unit(unit, warp_charge_component)
    if not mod._warp_charge_data[unit] then
        mod._warp_charge_data[unit] = {}
    end

    local data = mod._warp_charge_data[unit]
    data.current_percentage = warp_charge_component.current_percentage
    data.state = warp_charge_component.state
end

--------------------------------------------------------------------------------
-- 3. Hook relevant WarpCharge functions to capture final peril values
--------------------------------------------------------------------------------

-- Increase immediate
mod:hook_safe(WarpCharge, "increase_immediate", function(t, charge_level, warp_charge_component, charge_template, owner_unit, warp_charge_modifier, prevent_explosion)
    set_warp_data_for_unit(owner_unit, warp_charge_component)
    mod:debug("[WarpAllah] increase_immediate -> peril=%.2f, state=%s", 
        warp_charge_component.current_percentage, warp_charge_component.state
    )
end)

-- Increase over time
mod:hook_safe(WarpCharge, "increase_over_time", function(dt, t, charge_level, warp_charge_component, charge_template, owner_unit, first_charge)
    set_warp_data_for_unit(owner_unit, warp_charge_component)
    mod:debug("[WarpAllah] increase_over_time -> peril=%.2f, state=%s", 
        warp_charge_component.current_percentage, warp_charge_component.state
    )
end)

-- Decrease immediate
mod:hook_safe(WarpCharge, "decrease_immediate", function(remove_percentage, warp_charge_component, unit)
    set_warp_data_for_unit(unit, warp_charge_component)
    mod:debug("[WarpAllah] decrease_immediate -> peril=%.2f, state=%s", 
        warp_charge_component.current_percentage, warp_charge_component.state
    )
end)

-- Update venting
mod:hook_safe(WarpCharge, "update_venting", function(dt, t, player, warp_charge_component)
    local player_unit = player.player_unit
    set_warp_data_for_unit(player_unit, warp_charge_component)
    mod:debug("[WarpAllah] update_venting -> peril=%.2f, state=%s", 
        warp_charge_component.current_percentage, warp_charge_component.state
    )
end)

--------------------------------------------------------------------------------
-- 4. Utilities
--------------------------------------------------------------------------------

-- Check if a buff is currently active on the unit.
-- Adjust the buff keyword if your target buff uses a different name
local function has_protection_buff(unit)
    local buff_extension = ScriptUnit.has_extension(unit, "buff_system")
    if buff_extension and buff_extension:has_keyword("psychic_fortress") then
        return true
    end
    return false
end

-- Check if a weapon is “perilous” by seeing if it has a warp_charge_template
local function is_perilous_weapon(unit)
    local weapon_extension = ScriptUnit.has_extension(unit, "weapon_system")
    if weapon_extension then
        local warp_charge_template = weapon_extension:warp_charge_template()
        return warp_charge_template ~= nil
    end
    return false
end

-- Decide if we’re in the “pre-explosion risk” state:
-- i.e., peril >= 100% but not yet actually “exploding”
local function is_in_explosion_risk(unit)
    local data = mod._warp_charge_data[unit]
    if data then
        local peril = data.current_percentage or 0
        local state = data.state or "idle"
        return (peril >= 1.0 and state ~= "exploding")
    end
    return false
end

--------------------------------------------------------------------------------
-- 5. Hook InputService to block attacks if in “pre-explosion” with no buff
--------------------------------------------------------------------------------
mod:hook("InputService", "_get", function(func, self, action_name)
    -- Let the original call happen first
    local result = func(self, action_name)

    -- We only care about certain input actions, e.g. primary / special attacks
    -- Tweak this list as needed
    if  action_name ~= "action_one_pressed" and
        action_name ~= "action_one_hold" and
        action_name ~= "action_one_release" and
        action_name ~= "weapon_extra_pressed" and
        action_name ~= "weapon_extra_hold" and
        action_name ~= "weapon_extra_release"
    then
        -- Not relevant to us, return original result
        return result
    end

    -- Identify local player
    local player = Managers and Managers.player and Managers.player:local_player(1)
    if not player then
        return result
    end

    local player_unit = player.player_unit
    if not player_unit or not Unit.alive(player_unit) then
        return result
    end

    -- Check our stored peril data
    local should_block = false

    -- Are we at or above 100% peril but not exploding yet?
    if is_in_explosion_risk(player_unit) then
        -- Also check if the weapon is perilous 
        if is_perilous_weapon(player_unit) then
            -- Also check if we have a protective buff 
            if not has_protection_buff(player_unit) then
                -- If the buff is NOT active, we want to block
                should_block = true
            end
        end
    end

    if should_block then
        mod:echo("[WarpAllah] Blocking input '%s' at peril=%.2f (no buff)",
            action_name,
            mod._warp_charge_data[player_unit].current_percentage
        )
        return false
    end

    -- Otherwise, allow the input
    return result
end)

--------------------------------------------------------------------------------
-- 6. (Optional) Lifecycle functions if needed
--------------------------------------------------------------------------------

-- If you want a per-frame update:
-- function mod.update(dt)
--     -- Potentially do more logic, if you want
-- end

-- If you want to handle mod settings:
-- function mod.on_setting_changed(setting_id)
--     -- refresh config, etc.
-- end

return mod
