class_name SettingsManager
extends RefCounted
var path := "user://settings.cfg"
var volume := 0.8
var fullscreen := false
func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(path) == OK:
		var value = config.get_value("audio", "master_volume", 0.8)
		if value is float or value is int:
			volume = clampf(value, 0, 1)
		fullscreen = config.get_value("display", "fullscreen", false) == true
	apply_runtime()
func apply_runtime() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume == 0)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
func save() -> Error:
	apply_runtime()
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", volume)
	config.set_value("display", "fullscreen", fullscreen)
	return config.save(path)
