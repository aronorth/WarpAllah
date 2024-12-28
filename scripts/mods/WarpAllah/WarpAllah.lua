mod:echo("WarpAllah one loaded!")  -- or mod:info("...")
--[[ 
File: scripts/mods/WarpAllah/WarpAllah.lua
Ensure your folder name matches and get_mod("WarpAllah") references that folder!
--]]
local mod = get_mod("WarpAllah")

mod:echo("WarpAllah two loaded!")  -- or mod:info("...")

------------------------------------------------------------------------------
-- 1. Require warp_charge so we can hook it
------------------------------------------------------------------------------
local WarpCharge = require("scripts/utilities/warp_charge")

------------------------------------------------------------------------------
-- 2. Warp Charge Data Storage
------------------------------------------------------------------------------
mod._warp_charge_data = {}

local function set_warp_data_for_unit(unit, warp_charge_component)
    if not mod._warp_charge_data[unit] then
        mod._warp_charge_data[unit] = {}
    end

    local data = mod._warp_charge_data[unit]
    data.current_percentage = warp_charge_component.current_percentage
    data.state = warp_charge_component.state
end

------------------------------------------------------------------------------
-- 3. Hook the relevant WarpCharge functions
------------------------------------------------------------------------------
mod:hook_safe(WarpCharge, "increase_immediate", function(t, charge_level, warp_charge_component, charge_template, owner_unit, warp_charge_modifier, prevent_explosion)
    set_warp_data_for_unit(owner_unit, warp_charge_component)
    mod:debug("[WarpAllah] increase_immediate -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

mod:hook_safe(WarpCharge, "increase_over_time", function(dt, t, charge_level, warp_charge_component, charge_template, owner_unit, first_charge)
    set_warp_data_for_unit(owner_unit, warp_charge_component)
    mod:debug("[WarpAllah] increase_over_time -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

mod:hook_safe(WarpCharge, "decrease_immediate", function(remove_percentage, warp_charge_component, unit)
    set_warp_data_for_unit(unit, warp_charge_component)
    mod:debug("[WarpAllah] decrease_immediate -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

mod:hook_safe(WarpCharge, "update_venting", function(dt, t, player, warp_charge_component)
    local player_unit = player.player_unit
    set_warp_data_for_unit(player_unit, warp_charge_component)
    mod:debug("[WarpAllah] update_venting -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

------------------------------------------------------------------------------
-- 4. Buff Checks
------------------------------------------------------------------------------
-- 4a) Is Scrier's Gaze (psyker_overcharge_stance) active? 
--     We only start blocking if this stance is active.
local function is_scriers_gaze_active(player_unit)
    local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
    if buff_extension then
        for _, buff in pairs(buff_extension:buffs()) do
            local template = buff:template()
            if template and template.name == "psyker_overcharge_stance" then
                return true
            end
        end
    end

    return false
end

-- 4b) Is explosion immunity (psychic_fortress or warp_unbound) active?
--     We stop blocking once this buff is on.
local function has_explosion_immunity(unit)
    local buff_extension = ScriptUnit.has_extension(unit, "buff_system")
    if not buff_extension then
        return false
    end

    -- Common names could be "psychic_fortress", "warp_unbound",
    -- "psyker_overcharge_stance_infinite_casting", or some other buff keyword.
    -- Adjust as needed.
    return buff_extension:has_keyword("psychic_fortress") or
           buff_extension:has_keyword("warp_unbound") or
           buff_extension:has_keyword("psyker_overcharge_stance_infinite_casting")
end

------------------------------------------------------------------------------
-- 5. Utility: Are we at or above 100% peril, but not "exploding" yet?
------------------------------------------------------------------------------
local function is_in_explosion_risk(unit)
    local data = mod._warp_charge_data[unit]
    if data then
        local peril = data.current_percentage or 0
        local state = data.state or "idle"
        return (peril >= 1.0 and state ~= "exploding")
    end
    return false
end

------------------------------------------------------------------------------
-- 6. Is our weapon perilous?
------------------------------------------------------------------------------
local function is_perilous_weapon(unit)
    local weapon_extension = ScriptUnit.has_extension(unit, "weapon_system")
    if weapon_extension then
        local warp_charge_template = weapon_extension:warp_charge_template()
        return (warp_charge_template ~= nil)
    end
    return false
end

------------------------------------------------------------------------------
-- 7. Hook InputService to block *only* during Scrier’s Gaze & pre-explosion
------------------------------------------------------------------------------
mod:hook("InputService", "_get", function(func, self, action_name)
    -- Run original logic
    local result = func(self, action_name)

    -- Only watch for main attacks or special attacks
    if  action_name ~= "action_one_pressed" and
        action_name ~= "action_one_hold" and
        action_name ~= "action_one_release" and
        action_name ~= "weapon_extra_pressed" and
        action_name ~= "weapon_extra_hold" and
        action_name ~= "weapon_extra_release"
    then
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

    -- First, confirm scriers gaze is active
    if not is_scriers_gaze_active(player_unit) then
        -- We do NOT block if the stance isn't active
        return result
    end

    -- Next, check if we have explosion immunity
    if has_explosion_immunity(player_unit) then
        -- If we do, do NOT block 
        return result
    end

    -- Finally, see if our peril is at risk & the weapon is “perilous”
    if is_in_explosion_risk(player_unit) and is_perilous_weapon(player_unit) then
        mod:echo("[WarpAllah] Blocking input '%s' due to pre-explosion risk (peril=%.2f)",
            action_name,
            mod._warp_charge_data[player_unit].current_percentage
        )
        return false
    end

    -- Otherwise, let the input pass
    return result
end)

------------------------------------------------------------------------------
-- 8. (Optional) Lifecycle Functions
------------------------------------------------------------------------------

-- function mod.update(dt)
--     -- For advanced logic each frame, if needed
-- end

-- function mod.on_setting_changed(setting_id)
--     -- If you have mod settings, handle them here
-- end

return mod
