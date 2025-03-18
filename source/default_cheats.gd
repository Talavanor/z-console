class_name ZDefaultCheats extends Node



func _ready() -> void:
	Console.register_cheat("z.reload.scene", _reload_scene, "Reloads the current scene.")
	Console.register_cheat("z.style.linespace", _set_global_line_space, "Sets the global line spacing for console entries")
	#Console.register_cheat("z.reload.project", _reload_project, "Closes and restarts the project.")


func _reload_scene() -> void:
	get_tree().reload_current_scene()



func _set_global_line_space(value : float = 2) -> void:
	ZConsts.line_space = clampf(value, 0, value)
	Console.rebuild_ui()
# func _reload_project() -> void:
# 	if OS.has_feature("standalone"):
# 		get_tree().
# 		OS.set_restart_on_exit(true)
# 		get_tree().quit()
# 	else:
# 		EditorInterface.play_main_scene()
