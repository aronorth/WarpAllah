return {
    run = function()
        fassert(rawget(_G, "new_mod"), "`WarpAllah` encountered an error loading the Darktide Mod Framework.")

        new_mod("WarpAllah", {
            mod_script       = "WarpAllah/scripts/mods/WarpAllah/WarpAllah",
            mod_data         = "WarpAllah/scripts/mods/WarpAllah/WarpAllah_data",
            mod_localization = "WarpAllah/scripts/mods/WarpAllah/WarpAllah_localization",
        })
    end,
    packages = {},
}
