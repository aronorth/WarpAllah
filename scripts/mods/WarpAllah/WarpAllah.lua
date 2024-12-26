--[[
┌───────────────────────────────────────────────────────────────────────────┐
│ Mod Name: WarpAllah                                                       │
│ Description: A better approach to fixing the warp unbound bug.            │
│ Author: Aronorth                                                          │
└───────────────────────────────────────────────────────────────────────────┘
--]]

local mod = get_mod("WarpAllah") -- Make sure this matches the folder name

------------------------------------------------------------------------------
-- 1. Utility / Helper Functions
------------------------------------------------------------------------------

-- Placeholder: Adjust as needed
-- "Managers" is assumed to be globally available via Darktide’s environment.
local function get_local_player()
    -- Return the local human player (slot #1)
    if Managers and Managers.state and Managers.state.game_mode then
        local player_manager = Managers.player
        return player_manager and player_manager:local_player(1)
    end

    return nil
end

local function get_warp_charge_component(player_unit)
    -- Safely retrieve the warp_charge component
    local success, unit_data_extension = pcall(ScriptUnit.extension, player_unit, "unit_data_system")
    if success and unit_data_extension then
        return unit_data_extension:read_component("warp_charge")
    end
    return nil
end

-- The simplest check: see if weapon has a warp_charge_template
-- Placeholder: refine this logic if we want a different “perilous” definition
local function is_weapon_perilous(player_unit)
    local weapon_extension = ScriptUnit.has_extension(player_unit, "weapon_system")
    if not weapon_extension then
        return false
    end

    local warp_charge_template = weapon_extension:warp_charge_template()
    return (warp_charge_template ~= nil)
end

-- Check if Psychic Fortress or Warp Unbound buff is present
local function has_protection_buff(player_unit)
    local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")

    if buff_extension then
        -- Placeholder keywords/names: confirm these match your buff definition
        local has_psychic_fortress = buff_extension:has_keyword("psychic_fortress")
        return has_psychic_fortress

    end

    return false
end

------------------------------------------------------------------------------
-- 2. The Input Hook
------------------------------------------------------------------------------

-- We hook InputService:_get() to override the game’s interpretation of inputs
mod:hook("InputService", "_get", function(func, self, action_name)
    -- Let the original method run first, so we know the default result
    local result = func(self, action_name)

    -- Decide which actions we want to potentially block
    -- (e.g. main fire: "action_one_*"; alt fire: "action_two_*"; etc.)
    if action_name ~= "action_one_pressed"
       and action_name ~= "action_one_hold"
       and action_name ~= "action_one_release"
       and action_name ~= "weapon_extra_pressed"
       and action_name ~= "weapon_extra_hold"
       and action_name ~= "weapon_extra_release"
    then
        -- If it’s not one of these, we do nothing
        return result
    end

    -- Get local player info
    local player = get_local_player()
    if not player then
        return result
    end

    local player_unit = player.player_unit
    if not player_unit or not Unit.alive(player_unit) then
        return result
    end

    -- Get warp charge state
    local warp_charge_component = get_warp_charge_component(player_unit)
    if not warp_charge_component then
        mod:echo(string.format(
            "[Debug] Action=%s => No warp_charge_component found!",
            action_name
        ))
        return result
    end

    local current_percentage = warp_charge_component.current_percentage or 0
    local state = warp_charge_component.state or "idle"

    -- Check if we’re in the “pre-explosion” window (≥100%, but not yet exploding)
    local is_pre_explosion = (current_percentage >= 1) and (state ~= "exploding")

    -- Check if the weapon is perilous
    local perilous_weapon = is_weapon_perilous(player_unit)

    -- Check if the protective buff is active
    local protected_by_buff = has_protection_buff(player_unit)

    -- Debug info: Print out the relevant state every time we press/hold/release
mod:echo(string.format(
    "[Debug] Action=%s => Peril=%.2f, State=%s, InPreExplode=%s, PerilousWeapon=%s, Protected=%s",
    action_name,
    current_percentage,
    state,
    tostring(is_pre_explosion),
    tostring(perilous_weapon),
    tostring(protected_by_buff)
    ))

    -- If all conditions are met, block input
    if is_pre_explosion and perilous_weapon and not protected_by_buff then
        -- OPTIONAL: Provide feedback to the user, e.g. a beep
        -- WwiseWorld.trigger_event(wwise_world, "my_block_sound")

        -- Return false so the game does NOT register this input
        return false
    end

    -- Otherwise, let the normal input pass through
    return result
end)

------------------------------------------------------------------------------
-- 3. Lifecycle: Update / Other Hooks
------------------------------------------------------------------------------

-- If we want an update function to do housekeeping each frame, we can do so:
-- Note: This is entirely optional. If we only rely on the input hook, we may not need an update.
--function mod.update(dt)
    -- e.g. debug logs, or anything else we want done each frame
    -- Placeholder: 
    -- mod:echo("Update was called, dt="..tostring(dt))
--end

-- We can also handle user settings changes, if we have a mod option file
mod.on_setting_changed = function(setting_id)
    -- Placeholder: e.g. refresh local variables from mod:get("my_setting")
end

return mod

