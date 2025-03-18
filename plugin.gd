@tool
extends EditorPlugin

const CONSOLE_NAME : String = "Console"
const SCRIPT_NAME : String = "z_console.gd"


func _enter_tree() -> void:
	var console_location : String = get_script().get_path().get_base_dir()
	add_autoload_singleton(CONSOLE_NAME, "%s/source/%s" % [console_location, SCRIPT_NAME])

	var custom_settings : Array[Dictionary] = [
		{"name": ZConsts.SETTING_PATH % "show_demo_cheats", "type": TYPE_BOOL}
	]

	for setting in custom_settings:
		var name := setting.get("name") as String
		if not ProjectSettings.has_setting(name):
			print("Adding %s to project settings" % name)
			ProjectSettings.set_setting(name, true)
			ProjectSettings.add_property_info(setting)


func _exit_tree() -> void:
	remove_autoload_singleton(CONSOLE_NAME)
