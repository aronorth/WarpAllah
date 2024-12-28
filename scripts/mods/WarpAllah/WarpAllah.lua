-- File: scripts/mods/WarpAllah/WarpAllah.lua
-- Make sure your folder is named WarpAllah, and your get_mod() call matches.

local mod = get_mod("WarpAllah")

------------------------------------------------------------------------------
-- 1. Require the warp_charge module so we can hook it
--    The path must match the official internal path. Typically:
--    "scripts/utilities/warp_charge"
------------------------------------------------------------------------------

local WarpCharge = require("scripts/utilities/warp_charge")

-- If this returns nil or errors, your path might be different or the game
-- environment might not expose it the same way. Adjust as needed.

------------------------------------------------------------------------------
-- 2. We store the warp charge data for each unit after each update
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
-- 3. Hook relevant WarpCharge functions to capture final peril values
------------------------------------------------------------------------------

-- Called every time warp charge increases immediately
mod:hook_safe(WarpCharge, "increase_immediate", function(
    t, charge_level, warp_charge_component, charge_template,
    owner_unit, warp_charge_modifier, prevent_explosion
)
    set_warp_data_for_unit(owner_unit, warp_charge_component)
    mod:debug("[WarpAllah] increase_immediate -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

-- Called every time warp charge increases over time (e.g. channeling)
mod:hook_safe(WarpCharge, "increase_over_time", function(
    dt, t, charge_level, warp_charge_component,
    charge_template, owner_unit, first_charge
)
    set_warp_data_for_unit(owner_unit, warp_charge_component)
    mod:debug("[WarpAllah] increase_over_time -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

-- Called every time warp charge decreases immediately (e.g. quell, some talents)
mod:hook_safe(WarpCharge, "decrease_immediate", function(
    remove_percentage, warp_charge_component, unit
)
    set_warp_data_for_unit(unit, warp_charge_component)
    mod:debug("[WarpAllah] decrease_immediate -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

-- Called every time warp charge updates venting (i.e. “venting mode”)
mod:hook_safe(WarpCharge, "update_venting", function(dt, t, player, warp_charge_component)
    local player_unit = player.player_unit
    set_warp_data_for_unit(player_unit, warp_charge_component)
    mod:debug("[WarpAllah] update_venting -> peril=%.2f, state=%s",
        warp_charge_component.current_percentage,
        warp_charge_component.state
    )
end)

------------------------------------------------------------------------------
-- 4. Optional: Hook check_new_state to see transitions (exploding, etc.)
------------------------------------------------------------------------------

mod:hook_safe(WarpCharge, "check_new_state", function(warp_charge_component, prevent_explosion)
    mod:debug("[WarpAllah] check_new_state -> current=%.2f, prevent_explosion=%s, final_state=%s",
        warp_charge_component.current_percentage,
        tostring(prevent_explosion),
        warp_charge_component.state
    )
end)

------------------------------------------------------------------------------
-- 5. Buff Checking: “Psychic Fortress” or “Warp Unbound”
------------------------------------------------------------------------------

-- Example function to see if we have the protective buff
-- Adjust the keyword(s) to match the real buff name. 
local function has_protection_buff(unit)
    local buff_extension = ScriptUnit.has_extension(unit, "buff_system")
    if buff_extension and buff_extension:has_keyword("psychic_fortress") then
        -- Or: buff_extension:has_buff_id("psyker_overcharge_stance_infinite_casting")
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- 6. Checking Weapon “Perilous”
------------------------------------------------------------------------------

-- In some builds, we want to see if the weapon itself uses warp_charge
-- so we only block if the weapon is generating peril
local function is_perilous_weapon(unit)
    local weapon_extension = ScriptUnit.has_extension(unit, "weapon_system")
    if weapon_extension then
        local warp_charge_template = weapon_extension:warp_charge_template()
        return warp_charge_template ~= nil
    end
    return false
end

------------------------------------------------------------------------------
-- 7. Helper: Are we in “pre-explosion” state?
------------------------------------------------------------------------------

local function is_in_explosion_risk(unit)
    local data = mod._warp_charge_data[unit]
    if data then
        local peril = data.current_percentage or 0
        local state = data.state or "idle"
        -- We consider “pre-explosion” if peril >= 100% but state ~= "exploding"
        return (peril >= 1.0 and state ~= "exploding")
    end
    return false
end

------------------------------------------------------------------------------
-- 8. Hook InputService to block risky actions
------------------------------------------------------------------------------

mod:hook("InputService", "_get", function(func, self, action_name)
    local result = func(self, action_name)

    -- Quick filter: if we’re not dealing with M1 or alt-fire or special-attack,
    -- skip any checks. Adjust these action_name checks as you see fit.
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
    local player = Managers.player:local_player(1)
    if not player then
        return result
    end

    local player_unit = player.player_unit
    if not player_unit or not Unit.alive(player_unit) then
        return result
    end

    -- Check our stored peril data
    local data = mod._warp_charge_data[player_unit]
    if not data then
        -- If we have no data, we can't be certain. If you want to “overblock”
        -- when uncertain, you could do so here. But let's skip for now:
        return result
    end

    local should_block = false

    -- 1) Are we in pre-explosion risk? (≥100% peril but not exploding)
    if is_in_explosion_risk(player_unit) then
        -- 2) Is the current weapon perilous?
        if is_perilous_weapon(player_unit) then
            -- 3) Are we missing a protective buff?
            if not has_protection_buff(player_unit) then
                should_block = true
            end
        end
    end

    -- If blocking, output debug and return false
    if should_block then
        mod:echo("[WarpAllah] Blocking '%s' at peril=%.2f (no protection buff)",
            action_name, data.current_percentage
        )
        return false
    end

    return result
end)

------------------------------------------------------------------------------
-- 9. Optional Lifecycle: update / on_setting_changed, etc.
------------------------------------------------------------------------------

function mod.update(dt)
    -- You can do housekeeping here if needed
    -- e.g., remove data for old units that no longer exist, etc.
    -- For basic usage, it might remain empty
end

function mod.on_setting_changed(setting_id)
    -- If you have in-game mod settings, you can refresh local variables
    -- e.g., some threshold, a toggle, etc.
end

------------------------------------------------------------------------------
-- 10. Return the mod object
------------------------------------------------------------------------------

return mod

