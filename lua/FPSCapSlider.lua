local menu_item_name = "choose_fps_cap"
local menu_item_name_new = menu_item_name
--local fps_menu_item_name_new = "choose_fps_cap_slider"
local menu_item_index = 15

FPSCapSlider = FPSCapSlider or {}
FPSCapSlider.mod_id = "FPSCapSlider"
FPSCapSlider.mod_path = ModPath
FPSCapSlider.save_path = SavePath .. FPSCapSlider.mod_id .. ".json"
FPSCapSlider.saved_data = {
	custom_fps_cap = nil
}
FPSCapSlider.session_data = {
	vanilla_fps_cap = nil
}
FPSCapSlider._saved_data_defaults = {
	custom_fps_cap = 60
}
FPSCapSlider._session_data_defaults = {
	vanilla_fps_cap = 60
}

-- Save mod settings
function FPSCapSlider:save_settings()
	local file = io.open(self.save_path, "w+")
	if not file then
		return
	end

	file:write(json.encode(self.saved_data))
	file:close()
end

-- Load mod settings
function FPSCapSlider:load_settings()
	local file = io.open(self.save_path, "r")
	if not file then
		return
	end

	local data_from_save = json.decode(file:read("*all")) or {}
	file:close()

	for k, v in pairs(data_from_save) do
		self.saved_data[k] = v or self.saved_data[k] or self._saved_data_defaults[k]
	end
end

-- Custom menu option callback
function MenuCallbackHandler:choice_fps_cap_slider(item)
	item:set_value(math.round_with_precision(item:value()))
	MenuCallbackHandler:choice_fps_cap(item)
	FPSCapSlider.saved_data.custom_fps_cap = item:value()
	FPSCapSlider:save_settings()
end

-- Initialise variables sourced from managers
Hooks:PostHook(Setup, "init_managers", "FPSCap.Init", function(self)
	FPSCapSlider:load_settings()
	FPSCapSlider.session_data.vanilla_fps_cap = managers.user:get_setting("fps_cap") or FPSCapSlider._session_data_defaults.vanilla_fps_cap
end)

-- Replace vanilla option with custom
Hooks:PostHook(MenuOptionInitiator, "modify_adv_video", "FPSCap", function(self, node)
	-- Get original item
	local orignial_item = node:item(menu_item_name)
	if orignial_item and orignial_item.__is_custom then
		return
	end
	node:delete_item(menu_item_name)
	orignial_item = nil

	-- Get maximum display framerate
	local max_display_fps = nil
	for _, res in ipairs(RenderSettings.modes) do
		max_display_fps = (not max_display_fps or res.z > max_display_fps) and res.z or max_display_fps
	end
	max_display_fps = max_display_fps or 1000

	-- Initialise custom menu item
	local node_params = {
		name = menu_item_name_new,
		text_id = "menu_fps_limit",
		help_id = "menu_fps_limit_help",
		callback = "choice_fps_cap_slider"
	}
	local node_data = {
		type = "CoreMenuItemSlider.ItemSlider",
		min = max_display_fps > 30 and 30 or max_display_fps,
		max = max_display_fps,
		step = 1,
		show_value = true,
		decimal_count = 0
	}
	local new_item = node:create_item(node_data, node_params)
	new_item:set_value(FPSCapSlider.saved_data.custom_fps_cap or FPSCapSlider.session_data.vanilla_fps_cap)
	new_item.__is_custom = true
	node:insert_item(new_item, menu_item_index)
end)

-- Restore game fps setting to vanilla value
-- Avoids the vanilla option dissapearing if mod is disabled while using a non-vanilla FPS cap
Hooks:AddHook("SetupOnQuit", "FPSCap.OnQuit", function(self)
	MenuCallbackHandler:choice_fps_cap({
		value = function() return FPSCapSlider.session_data.vanilla_fps_cap end
	})
end)
