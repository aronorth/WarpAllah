local mod = get_mod("WarpGod")
local Audio = get_mod("Audio")  -- This will be nil if Audio mod is not installed
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local definitions = {
    scenegraph_definition = {
        screen = UIWorkspaceSettings.screen,
        timer_area = {
            parent = "screen",
            size = { 200, 100 },
            vertical_alignment = "center",
            horizontal_alignment = "center",
            position = { 0, -190, 5 },
        },
    },
    widget_definitions = {
        timer_text = UIWidget.create_definition({
            {
                pass_type = "text",
                value = "",
                value_id = "timer",
                style_id = "timer",
                style = {
                    font_type = "machine_medium",
                    font_size = 30,
                    drop_shadow = true,
                    text_vertical_alignment = "center",
                    text_horizontal_alignment = "center",
                    text_color = Color.ui_hud_overcharge_high(255, true),
                    offset = { 0, 0, 100 },
                },
            },
        }, "timer_area"),
    },
}

local HudElementWarpGod = class("HudElementWarpGod", "HudElementBase")

function HudElementWarpGod:init(parent, draw_layer, start_scale)
    HudElementWarpGod.super.init(self, parent, draw_layer, start_scale, definitions)
    self.alert_played = false -- Variable to track if alert has been played
end

function HudElementWarpGod:update(dt, t, ui_renderer, render_settings, input_service)
    HudElementWarpGod.super.update(self, dt, t, ui_renderer, render_settings, input_service)

    -- Check if the timer functionality is enabled
    if not mod:get("warp_unbound_timer_enable") then
        self._widgets_by_name.timer_text.content.timer = ""
        self._widgets_by_name.timer_text.style.timer.font_size = 30
        return
    end

    -- Check if Managers.player is available
    if not Managers.player then
        self._widgets_by_name.timer_text.content.timer = ""
        self._widgets_by_name.timer_text.style.timer.font_size = 30
        return
    end

    local player = Managers.player:local_player(1)
    if not player or not player.player_unit or not Unit.alive(player.player_unit) then
        self._widgets_by_name.timer_text.content.timer = ""
        self._widgets_by_name.timer_text.style.timer.font_size = 30
        return
    end

    local profile = player:profile()
    if not profile or not profile.archetype or profile.archetype.name ~= "psyker" then
        self._widgets_by_name.timer_text.content.timer = ""
        self._widgets_by_name.timer_text.style.timer.font_size = 30
        return
    end

    -- Check if the player has the Warp Unbound talent
    if not profile.talents or not profile.talents.psyker_overcharge_stance_infinite_casting then
        self._widgets_by_name.timer_text.content.timer = ""
        self._widgets_by_name.timer_text.style.timer.font_size = 30
        return
    end

    -- Get the buff extension
    local buff_extension = ScriptUnit.has_extension(player.player_unit, "buff_system")
    if not buff_extension then
        self._widgets_by_name.timer_text.content.timer = ""
        self._widgets_by_name.timer_text.style.timer.font_size = 30
        return
    end

    -- Iterate through buffs to find the Warp Unbound buff
    for _, buff in pairs(buff_extension._buffs_by_index) do
        local template = buff:template()
        if template.name == "psyker_overcharge_stance_infinite_casting" then
            local remaining = buff:duration() * (buff:duration_progress() or 1)
            self._widgets_by_name.timer_text.content.timer = string.format("%.1f", remaining)
            self._widgets_by_name.timer_text.style.timer.font_size = 30 + (1 - remaining / buff:duration()) * 20

            -- Play alert sound at 2 seconds remaining
            if mod:get("play_notification") then
                if remaining <= 2 and not self.alert_played then
                    if Audio and Audio.play_file then
                        Audio.play_file("WarpGod/audio/timer_alert.mp3", { audio_type = "sfx" })
                    end
                    self.alert_played = true
                elseif remaining > 2 then
                    self.alert_played = false
                end
            else
                self.alert_played = false
            end

            return
        end
    end

    -- If the buff is not active, reset the timer display
    self._widgets_by_name.timer_text.content.timer = ""
    self._widgets_by_name.timer_text.style.timer.font_size = 30
end

return HudElementWarpGod
