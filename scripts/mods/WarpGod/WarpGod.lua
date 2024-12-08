--[[
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Mod Name: Warp God                                                                                                               │
│ Mod Description: Warp Unbound talent hotfix, Peril of the Warp Explosion Prevention                                              │
│ Mod Author: Kevinna                                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
--]]

local mod = get_mod("WarpGod")

-- Launch bug hotfix: Reintroduce the initialization delay
local initialization_delay = 10 -- Wait for 10 seconds before attempting to access player data
local initialization_elapsed_time = 0

-- Variables for Prevent Psyker Explosion functionality
local prevent_explosion_active = false

-- Variables for Warp Unbound LMB disabling functionality
local warp_unbound_bugfix_active = false
local warp_unbound_disable_timer = 0
local ability_triggered = false -- Tracks if the ability key has been pressed
local warp_unbound_active = false -- Tracks if Warp Unbound is currently active
local warp_unbound_bugfix_interval1_triggered = false --Tracks if the first disabling-interval when warp unbound is active is triggered
local warp_unbound_bugfix_interval2_triggered = false --Tracks if the second disabling-interval when warp unbound is active is triggered

-- Variables for weapon identification
local is_perilous_weapon = false
local is_forcesword = false

-- Settings with default values
local interval1_duration = mod:get("interval1_duration")
local interval1_start_delay = mod:get("interval1_start_delay")
local peril_threshold = mod:get("peril_threshold")

-- Update settings when they change
mod.on_setting_changed = function(setting_id)
        interval1_duration = mod:get("interval1_duration")
        interval1_start_delay = mod:get("interval1_start_delay")
        peril_threshold = mod:get("peril_threshold")
end

-- Hook into InputService to disable certain actions when necessaryrr
mod:hook("InputService", "_get", function(func, self, action_name)
    local result = func(self, action_name)

    -- Prevent Psyker Explosion functionality
    if mod:get("prevent_psyker_explosion_enable") and prevent_explosion_active then
        -- Disable quell for perilous weapons
        if mod:get("macro_anti_detection_enable") and (action_name == "weapon_reload" or action_name == "weapon_reload_hold") then
            return false
        end
        
        -- Disable primary attack (LMB) for perilous weapons
        if not is_forcesword and (action_name == "action_one_pressed" or action_name == "action_one_hold" or action_name == "action_one_release") then
            return false
        end

        -- Disable special attack keys for force swords
        if is_forcesword and (action_name == "weapon_extra_pressed" or action_name == "weapon_extra_hold" or action_name == "weapon_extra_release") then
            return false
        end
    end

    -- Warp Unbound LMB disabling functionality
    if mod:get("warp_unbound_bug_fix_enable") then
        if action_name == "combat_ability_hold" then
            ability_triggered = result
        end

        if action_name == "combat_ability_release" and result == true and ability_triggered then
            warp_unbound_bugfix_interval1_triggered = false
            warp_unbound_bugfix_interval2_triggered = false
        end

        if warp_unbound_bugfix_active then
            -- Disable primary attack (LMB) for perilous weapons
            if not is_forcesword and (action_name == "action_one_pressed" or action_name == "action_one_hold" or action_name == "action_one_release") then
                return false
            end

            -- Disable special attack keys for force swords
            if is_forcesword and (action_name == "weapon_extra_pressed" or action_name == "weapon_extra_hold" or action_name == "weapon_extra_release") then
                return false
            end

            -- Disable Reload/Quell when Warp Unbound is active
            if warp_unbound_active and (action_name == "weapon_reload" or action_name == "weapon_reload_hold") then
                return false
            end
        end
    end

    return result
end)

-- Function to update weapon status
local function update_weapon_status(player_unit)
    is_perilous_weapon = false
    is_forcesword = false
    local weapon_extension = ScriptUnit.has_extension(player_unit, "weapon_system")
    if weapon_extension then
        local weapon_template = weapon_extension:weapon_template()
        if weapon_template and weapon_template.name then
            local weapon_name = weapon_template.name
            local perilous_weapons = {
                "forcestaff",
                "psyker_throwing_knives",
                "psyker_smite",
                "psyker_chain_lightning",
                "forcesword_p1_m3",
                "forcesword_p1_m2",
                "forcesword_p1_m1",
                "forcesword_2h_p1_m1",
                "forcesword_2h_p1_m2",
            }
            for _, name in ipairs(perilous_weapons) do
                if string.find(weapon_name, name) then
                    is_perilous_weapon = true
                end
            end
            local forceswords = {
                "forcesword_p1_m1",
                "forcesword_p1_m2",
                "forcesword_p1_m3",
                "forcesword_2h_p1_m1",
                "forcesword_2h_p1_m2",
            }
            for _, name in ipairs(forceswords) do
                if string.find(weapon_name, name) then
                    is_forcesword = true
                end
            end
        end
    end
end

-- Function for Prevent Psyker Explosion functionality
local function prevent_psyker_explosion(player_unit, peril_fraction)
    if mod:get("prevent_psyker_explosion_enable") and is_perilous_weapon then
        -- Disable actions if peril is at or above the threshold and Warp Unbound is not active
        if peril_fraction >= peril_threshold and not warp_unbound_active and not ability_triggered then
            prevent_explosion_active = true
        else
            prevent_explosion_active = false
        end
    else
        prevent_explosion_active = false
    end
end

-- Function for Warp Unbound LMB disabling functionality
local function warp_unbound_bugfix(player_unit, dt)
    if mod:get("warp_unbound_bug_fix_enable") and is_perilous_weapon then
        local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
        if buff_extension then
            for _, buff in pairs(buff_extension:buffs()) do
                local template = buff:template()
                if template.name == "psyker_overcharge_stance_infinite_casting" then
                    local remaining = buff:duration() * (buff:duration_progress() or 1)
                    if remaining >= 10 and remaining <= (11.5 - interval1_start_delay) and not warp_unbound_bugfix_interval1_triggered then
                        warp_unbound_bugfix_active = true
                        warp_unbound_disable_timer = interval1_duration
                        warp_unbound_bugfix_interval1_triggered = true
                    end
                    if remaining <= 0.3 and not warp_unbound_bugfix_interval2_triggered then
                        warp_unbound_bugfix_active = true
                        warp_unbound_disable_timer = 0.4
                        warp_unbound_bugfix_interval2_triggered = true
                    end
                end
            end
        end

        if warp_unbound_bugfix_active then
            warp_unbound_disable_timer = warp_unbound_disable_timer - dt
            if warp_unbound_disable_timer <= 0 then
                warp_unbound_bugfix_active = false
                warp_unbound_disable_timer = 0
            end
        end
    else
        warp_unbound_bugfix_active = false
    end
end

-- Update function to monitor peril and manage disabling of actions
function mod.update(dt)
    -- Wait until the initialization delay has passed
    initialization_elapsed_time = initialization_elapsed_time + dt
    if initialization_elapsed_time < initialization_delay then
        return
    end

    -- Check if Managers.player exists
    if not Managers.player then
        return
    end

    -- Get the local player
    local player = Managers.player:local_player(1)
    if not player or not player.player_unit or not Unit.alive(player.player_unit) then
        warp_unbound_bugfix_active = false
        prevent_explosion_active = false
        warp_unbound_active = false
        return
    end

    -- Check if the player is a Psyker
    local profile = player:profile()
    if not profile or not profile.archetype or profile.archetype.name ~= "psyker" then
        warp_unbound_bugfix_active = false
        prevent_explosion_active = false
        warp_unbound_active = false
        return
    end

    -- Get the player unit
    local player_unit = player.player_unit

    -- Update weapon status
    update_weapon_status(player_unit)

    -- Get the unit data extension
    local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
    if not unit_data_extension then
        warp_unbound_bugfix_active = false
        prevent_explosion_active = false
        warp_unbound_active = false
        return
    end

    -- Read the peril level
    local warp_charge_component = unit_data_extension:read_component("warp_charge")
    local peril_fraction = warp_charge_component and warp_charge_component.current_percentage or 0

    -- Check if the Warp Unbound ability is currently active
    local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
    warp_unbound_active = false
    if buff_extension then
        for _, buff in ipairs(buff_extension:buffs()) do
            local template = buff:template()
            if template.name == "psyker_overcharge_stance_infinite_casting" then
                warp_unbound_active = true
                break
            end
        end
    end

    -- Execute functionalities
    prevent_psyker_explosion(player_unit, peril_fraction)
    warp_unbound_bugfix(player_unit, dt)
end

return mod

