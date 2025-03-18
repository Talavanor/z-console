@tool
extends EditorPlugin

const CONSOLE_NAME : String = "Console"
const SCRIPT_NAME : String = "z_console.gd"

func _enter_tree() -> void:
	var console_location : String = get_script().get_path().get_base_dir()
	add_autoload_singleton(CONSOLE_NAME, "%s/source/%s" % [console_location, SCRIPT_NAME])


func _exit_tree() -> void:
	remove_autoload_singleton(CONSOLE_NAME)
