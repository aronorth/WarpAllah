--[[
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Mod Name: Warp God                                                                                                               │
│ Mod Description: Warp Unbound bug hotfix, Peril of the Warp Explosion Prevention                                                 │
│ Mod Author: Kevinna                                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
--]]

local mod = get_mod("WarpGod")

local initialization_delay = 10 -- Wait for 10 seconds before attempting to access player data
local initialization_elapsed_time = 0

local attempted_ability_usage = false -- Tracks if the player has attempted to use the ability
local ability_triggered = false -- Tracks if the ability was actually triggered

local warp_unbound_bugfix_interval1_triggered = false --Tracks if the first disabling-interval when warp unbound is active is triggered
local warp_unbound_bugfix_interval2_triggered = false --Tracks if the second disabling-interval when warp unbound is active is triggered

-- Variables for Warp Unbound LMB disabling functionality
local warp_unbound_bugfix_active = false
local warp_unbound_disable_timer = 0

-- Variables for weapon identification
local is_perilous_weapon = false
local is_forcesword = false

-- Settings with default values
local peril_threshold = mod:get("peril_threshold")
local interval1_duration = mod:get("interval1_duration")
local interval1_start_delay = mod:get("interval1_start_delay")
local interval2_duration = mod:get("interval2_duration")

-- Update settings when they change
mod.on_setting_changed = function(setting_id)
    peril_threshold = mod:get("peril_threshold")
    interval1_duration = mod:get("interval1_duration")
    interval1_start_delay = mod:get("interval1_start_delay")
    interval2_duration = mod:get("interval2_duration")
end

-- Function to get the local player
local function _get_player()
    if not Managers or not Managers.player then return nil end
    local player = Managers.player:local_player(1)
    if not player or not player.peer_id then return nil end
    return player
end

-- Function to update weapon status
local function update_weapon_status()
    is_perilous_weapon = false
    is_forcesword = false

    local player = _get_player()
    if not player then return false end
    local player_unit = player.player_unit
    if not player_unit or not Unit.alive(player_unit) then return false end

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

-- Function to get the current peril level
local function get_peril_level()
    local player = _get_player()
    if not player then return 0 end
    local player_unit = player.player_unit
    if not player_unit or not Unit.alive(player_unit) then return 0 end

    local success, unit_data_extension = pcall(ScriptUnit.extension, player_unit, "unit_data_system")
    if not success or not unit_data_extension then return 0 end
    local warp_charge_component = unit_data_extension:read_component("warp_charge")
    if not warp_charge_component then return 0 end
    return warp_charge_component.current_percentage or 0
end

-- Function for Warp Unbound LMB disabling functionality
local function warp_unbound_bugfix(dt)
    local player = _get_player()
    if not player then return end
    local player_unit = player.player_unit
    if not player_unit or not Unit.alive(player_unit) then return end
    
    if mod:get("warp_unbound_bug_fix_enable") and is_perilous_weapon then
        local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
        if buff_extension then
            for _, buff in pairs(buff_extension:buffs()) do
                local template = buff:template()
                if template.name == "psyker_overcharge_stance_infinite_casting" then
                    local remaining_time = buff:duration() * (buff:duration_progress() or 1)

                    if remaining_time <= (11.5 - interval1_start_delay) and not warp_unbound_bugfix_interval1_triggered then
                        warp_unbound_bugfix_active = true
                        warp_unbound_disable_timer = interval1_duration
                        warp_unbound_bugfix_interval1_triggered = true
                    end

                    if remaining_time <= interval2_duration and not warp_unbound_bugfix_interval2_triggered then
                        warp_unbound_bugfix_active = true
                        warp_unbound_disable_timer = interval2_duration
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

local function is_warp_unbound_buff_active()
    local player = _get_player()
    if not player then return false end
    local player_unit = player.player_unit
    if not player_unit or not Unit.alive(player_unit) then return false end
    
    local success, buff_extension = pcall(ScriptUnit.extension, player_unit, "buff_system")
    if not success or not buff_extension then return false end

    for _, buff in pairs(buff_extension._buffs_by_index) do
        local template = buff:template()
        if template and template.name == "psyker_overcharge_stance_infinite_casting" then
            return true
        end
    end

    return false
end

-- Hook into PlayerUnitAbilityExtension to confirm ability is actually used
mod:hook_safe("PlayerUnitAbilityExtension", "use_ability_charge", function(self, ability_type, optional_num_charges)
    if ability_type == "combat_ability" and attempted_ability_usage then
        ability_triggered = true
        attempted_ability_usage = false
    end
end)

-- Hook into InputService to disable certain actions when necessary
mod:hook("InputService", "_get", function(func, self, action_name)
    if action_name ~= "action_one_pressed" and
        action_name ~= "action_one_hold" and
        action_name ~= "action_one_release" and
        action_name ~= "action_two_pressed" and
        action_name ~= "action_two_hold" and
        action_name ~= "action_two_release" and
        action_name ~= "weapon_extra_pressed" and
        action_name ~= "weapon_extra_hold" and
        action_name ~= "weapon_extra_release" and
        action_name ~= "weapon_reload" and
        action_name ~= "weapon_reload_hold" and
        action_name ~= "pressed" and
        action_name ~= "combat_ability_hold" and
        action_name ~= "combat_ability_release"
    then
        return func(self, action_name)
    end
    update_weapon_status()

    -- Prevent Psyker Explosion functionality
    if mod:get("prevent_psyker_explosion_enable") and (get_peril_level() >= peril_threshold) and not is_warp_unbound_buff_active() then
        -- Disable quell for perilous weapons
        if mod:get("macro_anti_detection_enable") and (action_name == "weapon_reload" or action_name == "weapon_reload_hold") then
            return false
        end
        -- Disable primary attack (LMB) for perilous weapons
        if not is_forcesword and (action_name == "action_one_pressed" or action_name == "action_one_hold" or action_name == "action_one_release") or (action_name == "action_two_pressed" or action_name == "action_two_hold" or action_name == "action_two_release") then
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
            -- Player attempts to use the ability. Mark the attempt but do not set ability_triggered yet.
            if func(self, action_name) then
                attempted_ability_usage = true
            end
        end
        -- Only reset intervals if the ability was actually triggered
        if action_name == "combat_ability_release" and func(self, action_name) and ability_triggered then
            warp_unbound_bugfix_interval1_triggered = false
            warp_unbound_bugfix_interval2_triggered = false
            ability_triggered = false
            attempted_ability_usage = false
        end
        if warp_unbound_bugfix_active and is_warp_unbound_buff_active() then
            -- Disable primary attack (LMB) for perilous weapons
            if not is_forcesword and (action_name == "action_one_pressed" or action_name == "action_one_hold" or action_name == "action_one_release") or (action_name == "action_two_pressed" or action_name == "action_two_hold" or action_name == "action_two_release") then
                return false
            end
            -- Disable special attack keys for force swords
            if is_forcesword and (action_name == "weapon_extra_pressed" or action_name == "weapon_extra_hold" or action_name == "weapon_extra_release") then
                return false
            end
            -- Disable Reload/Quell when Warp Unbound is active
            if is_warp_unbound_buff_active() and (action_name == "weapon_reload" or action_name == "weapon_reload_hold") then
                return false
            end
        end
    end

    return func(self, action_name)
end)

-- Update function to monitor peril and manage disabling of actions
function mod.update(dt)
    initialization_elapsed_time = initialization_elapsed_time + dt
    if initialization_elapsed_time < initialization_delay then
        return
    end
    warp_unbound_bugfix(dt)
end

return mod

