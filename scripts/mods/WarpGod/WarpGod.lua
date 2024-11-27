--[[
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Mod Name: Warp God                                                                                                │
│ Mod Description: Warp Unbound talent hotfix, Warp Unbound talent QoL, Peril of the Warp Explosion Prevention      │
│ Mod Author: Kevinna                                                                                               │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
--]]

local mod = get_mod("WarpGod")

-- Launch bug hotfix
local initialization_delay = 10 -- Wait for 10 seconds before attempting to access player data
local elapsed_time = 0

-- Variables for Prevent Psyker Explosion functionality
local prevent_explosion_active = false

-- Variables for Warp Unbound LMB disabling functionality
local warp_unbound_primary_attack_disabled = false
local warp_unbound_disable_timer = 0
local warp_unbound_peril_triggered = false
local ability_active = false -- Variable for tracking ability activation
local warp_unbound_active = false -- Variable to track if Warp Unbound is active

-- Variables for weapon identification (Module-Level)
local is_perilous_weapon = false
local is_forcesword = false

-- Settings
local disable_duration = mod:get("disable_duration") or 0.5
local disable_start_delay = mod:get("disable_start_delay") or 1
local peril_threshold = mod:get("peril_threshold") or 1.0 -- New setting for peril threshold

-- Update settings when they change
mod.on_setting_changed = function(setting_id)
    if setting_id == "disable_duration" then
        disable_duration = mod:get("disable_duration") or 1
    elseif setting_id == "disable_start_delay" then
        disable_start_delay = mod:get("disable_start_delay") or 0
    elseif setting_id == "peril_threshold" then
        peril_threshold = mod:get("peril_threshold") or 1.0
    end
end

-- Hook into InputService to disable LMB and Reload/Quell when necessary
mod:hook("InputService", "_get", function(func, self, action_name)
    local result = func(self, action_name)

    -- Prevent Psyker Explosion functionality
    if mod:get("prevent_psyker_explosion_enable") then
        if prevent_explosion_active then
            -- Disable LMB for all perilous weapons
            if action_name == "action_one_pressed" or action_name == "action_one_hold" then
                return false
            end

            -- Additionally disable Special Attack keys for force swords
            if is_forcesword then
                if action_name == "weapon_extra_pressed" or action_name == "weapon_extra_hold" or action_name == "weapon_extra_release" then
                    return false
                end
            end
        end
    end

    -- Warp Unbound LMB disabling
    if mod:get("warp_unbound_bug_fix_enable") then
        if action_name == "combat_ability_hold" then
            ability_active = result
        end

        if action_name == "combat_ability_release" and result == true and ability_active then
            warp_unbound_peril_triggered = false
        end

        if warp_unbound_primary_attack_disabled then
            -- Disable LMB
            if action_name == "action_one_pressed" or action_name == "action_one_hold" then
                return false
            end

            -- Disable Reload/Quell only if Warp Unbound is active
            if warp_unbound_active and (action_name == "weapon_reload" or action_name == "weapon_reload_hold") then
                return false
            end
        end
    end

    return result
end)

-- Register HUD Element for displaying timer
mod:register_hud_element({
    class_name = "HudElementWarpGod",
    filename = "WarpGod/scripts/mods/WarpGod/HudElementWarpGod",
    use_hud_scale = true,
    visibility_groups = {
        "alive",
    },
})

-- Update function to monitor peril and manage LMB and Reload/Quell disabling
function mod.update(dt)
    -- Wait until the initialization delay has passed
    elapsed_time = elapsed_time + dt
    if elapsed_time < initialization_delay then
        return
    end

    -- Get the local player
    local player = Managers.player:local_player(1)
    if not player or not player.player_unit or not Unit.alive(player.player_unit) then
        warp_unbound_primary_attack_disabled = false
        prevent_explosion_active = false
        warp_unbound_active = false
        return
    end

    -- Check if the player is a Psyker
    local profile = player:profile()
    if not profile or not profile.archetype or profile.archetype.name ~= "psyker" then
        warp_unbound_primary_attack_disabled = false
        prevent_explosion_active = false
        warp_unbound_active = false
        return
    end

    -- Get the player unit
    local player_unit = player.player_unit

    -- Determine if the player is wielding a peril-generating weapon or ability
    is_perilous_weapon = false
    is_forcesword = false

    local weapon_extension = ScriptUnit.has_extension(player_unit, "weapon_system")
    if weapon_extension then
        local weapon_template = weapon_extension:weapon_template()
        if weapon_template then
            local weapon_name = weapon_template.name
            if weapon_name and (
                string.find(weapon_name, "forcestaff") or
                weapon_name == "psyker_throwing_knives" or
                weapon_name == "psyker_smite" or
                weapon_name == "psyker_chain_lightning" or
                weapon_name == "forcesword_p1_m3" or
                weapon_name == "forcesword_p1_m2" or
                weapon_name == "forcesword_p1_m1"
            ) then
                is_perilous_weapon = true
                if weapon_name == "forcesword_p1_m3" or
                   weapon_name == "forcesword_p1_m2" or
                   weapon_name == "forcesword_p1_m1" then
                    is_forcesword = true
                end
            end
        end
    end

    -- Get the unit data extension
    local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
    if not unit_data_extension then
        warp_unbound_primary_attack_disabled = false
        prevent_explosion_active = false
        warp_unbound_active = false
        return
    end

    -- Read the peril level
    local warp_charge_component = unit_data_extension:read_component("warp_charge")
    local peril_fraction = warp_charge_component and warp_charge_component.current_percentage or 0

    -- Check if the Warp Unbound ability is currently active
    warp_unbound_active = false -- Update the module-level variable
    local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
    if buff_extension then
        local buffs = buff_extension:buffs()
        for _, buff in ipairs(buffs) do
            local template = buff:template()
            if template.name == "psyker_overcharge_stance_infinite_casting" then
                warp_unbound_active = true
                break
            end
        end
    end

    -- Prevent Psyker Explosion functionality
    if mod:get("prevent_psyker_explosion_enable") and is_perilous_weapon then
        -- Disable LMB if peril is at or above the threshold, Warp Unbound is not active, and ability key is not pressed
        if peril_fraction >= peril_threshold and not warp_unbound_active and not ability_active then
            if not prevent_explosion_active then
                prevent_explosion_active = true
            end
        else
            if prevent_explosion_active then
                prevent_explosion_active = false
            end
        end
    else
        if prevent_explosion_active then
            prevent_explosion_active = false
        end
    end

    -- Warp Unbound LMB disabling functionality
    if mod:get("warp_unbound_bug_fix_enable") and is_perilous_weapon then
        -- Main logic
        if buff_extension then
            for _, buff in pairs(buff_extension:buffs()) do
                local template = buff:template()
                if template.name == "psyker_overcharge_stance_infinite_casting" then
                    local remaining = buff:duration() * (buff:duration_progress() or 1)
                    if remaining >= 10 and remaining <= (11.5 - disable_start_delay) and not warp_unbound_peril_triggered then
                        warp_unbound_primary_attack_disabled = true
                        warp_unbound_disable_timer = disable_duration
                        warp_unbound_peril_triggered = true
                    end
                    if remaining <= 0.2 and warp_unbound_peril_triggered then
                        warp_unbound_primary_attack_disabled = true
                        warp_unbound_disable_timer = 0.4
                    end
                end
            end
        end

        if warp_unbound_primary_attack_disabled then
            warp_unbound_disable_timer = warp_unbound_disable_timer - dt
            if warp_unbound_disable_timer <= 0 then
                warp_unbound_primary_attack_disabled = false
                warp_unbound_disable_timer = 0
            end
        end
    else
        warp_unbound_primary_attack_disabled = false
    end
end

return mod
