class_name ZConsole extends CanvasLayer

signal cvars_changed(key : String, value : Variant)
signal history_changed(history : Array[String])
signal history_purged()


const CVAR_SECTION : String = "CVARS"
const HISTORY_KEY : String = "HISTORY"
const SAVE_PATH : String = "user://console_data.cfg"
const CONSOLE_SCENE : String = "z_console_interface.tscn"

var config := ConfigFile.new()# : get = _get_config
var console_layer := CanvasLayer.new()
var console_ui : ConsoleInterface = null
var history : Array[Dictionary] = []
var cheats : Dictionary[String, Dictionary] = {}



func _input(event: InputEvent) -> void:
	var just_pressed := event.is_pressed() and not event.is_echo()
	if just_pressed:
		if Input.is_physical_key_pressed(KEY_QUOTELEFT):
			open()
			#Input.flush_buffered_events()
		if Input.is_physical_key_pressed(KEY_ESCAPE):
			close()


func _ready() -> void:
	print("ZConsole %s is READY" % Console)
	load_config()
	register_defaults()


func _process(delta: float) -> void:
	pass


func load_config() -> ConfigFile:
	# Ensure that we always load from disk if possible
	var error := config.load(SAVE_PATH)
	if error != OK:
		# If we didn't find an existing config then initialize it
		config.save(SAVE_PATH)
	retrieve_history()
	return config


func open() -> void:
	if not console_ui:
		build_terminal()


func close() -> void:
	print("trying close")
	if console_ui:
		print("closing")
		console_ui.queue_free()


func _emit_cvar(key : String, value : Variant) -> void:
	print_debug("Cvar changed: %s = %s" % [key, value])
	cvars_changed.emit(key, value)


func build_terminal() -> void:
	var scene_path : String = "%s/%s" % [get_script().get_path().get_base_dir(), CONSOLE_SCENE]
	var ui_scene := ResourceLoader.load(scene_path) as PackedScene
	if ui_scene:
		console_ui = ui_scene.instantiate() as ConsoleInterface
		add_child.call_deferred(console_ui)


func register_cvar(key : String, value : Variant) -> bool:
	if config.get_value(CVAR_SECTION, key, value):
		return false

	config.set_value(CVAR_SECTION, key, value)
	config.save(SAVE_PATH)
	return true


func set_cvar(key : String, value : Variant) -> void:
	if not config.has_section_key(CVAR_SECTION, key):
		print("No such variable")
		return

	#TODO: reimplement safe checking
	# if typeof(current) != typeof(value):
	# 	print("Var types don't match")
	# 	return

	# # Don't do anything if it's the exact same value
	# var current := config.get_value(CVAR_SECTION, key, null)
	# if current == value:
	# 	print("Same as current value %s %s" % [current, value])
	# 	return

	# If it has changed then we set it, save the config, and emit a signal with the altered value
	config.set_value(CVAR_SECTION, key, value)
	config.save(SAVE_PATH)
	_emit_cvar(key, value)


func get_cvar(key : String, default : Variant = null) -> Variant:
	#TODO: maybe this should this have an optional default value like a dictionary.get()?
	if not config.has_section_key(CVAR_SECTION, key): return default
	return config.get_value(CVAR_SECTION, key)


func register_cheat(key : String, callable : Callable, tip : String = "") -> Error:
	# Return an error if we're trying to use an already registered cheat key.
	if cheats.has(key): return ERR_ALREADY_EXISTS

	# If the cheat doesn't already exist then compose a new one
	var entry : Dictionary = {}
	var signature := _get_signature_internal(callable)
	var args : Array[Dictionary] = signature.get("args", [{}])
	entry["callable"] = callable
	entry["tip"] = tip
	entry["args"] = args
	# Store the newly composed dictionary as an entry in our cheats dictionary
	cheats[key] = entry
	return OK


func run_cheat(key : String, args : Array = []) -> Variant:
	if not cheats.has(key): return ERR_DOES_NOT_EXIST
	var callable := cheats.get(key)["callable"] as Callable
	print("Found callable %s, running..." % callable)
	return callable.callv(args)


func get_tip(key : String) -> String:
	if not cheats.has(key): return ""
	return cheats.get(key)["tip"] as String


func get_args(key : String) -> Array[Dictionary]:
	if not cheats.has(key):
		print("no cheat %s" % key)
		return [{}]

	# Return the located args as a duplicate to prevent the source data being altered
	var args := cheats.get(key).get("args", [{}]) as Array[Dictionary]
	return args.duplicate()


func _get_signature_internal(callable : Callable) -> Dictionary:
	var methods : Array[Dictionary] = callable.get_object().get_method_list()
	var signature : Dictionary = {}
	for m in methods:
		if m.get("name", "") == callable.get_method():
			signature = m
			break
	return signature


func run(cmd : String = "") -> Variant:
	var result : Variant = run_cheat(cmd)
	if result is int and result == ERR_DOES_NOT_EXIST: return null
	add_to_history(cmd, result)
	return result


func subscribe_to_cvars(callable : Callable) -> Error:
	if cvars_changed.is_connected(callable):
		return ERR_ALREADY_EXISTS
	cvars_changed.connect(callable)
	return OK


func add_to_history(cmd : String, result : Variant) -> void:

	var new_entry : Dictionary = {}
	new_entry["timestamp"] = Time.get_unix_time_from_system()
	new_entry["cmd"] = cmd
	new_entry["result"] = result

	history.append(new_entry)
	save_history()

	history_changed.emit(history)


func purge_history() -> void:
	history.clear()
	save_history()
	history_purged.emit()


func save_history() -> void:
	config.set_value(HISTORY_KEY, "log", history)
	config.save(SAVE_PATH)


func retrieve_history() -> void:
	history = config.get_value(HISTORY_KEY, "log", history)


func test_run() -> void:
	print("Test Run")


func test_cheat(str : String = "", i : int = 16) -> float:
	print("Executing test cheat")
	return float(i/2)



func register_defaults() -> void:
	add_child.call_deferred(ZDefaultCheats.new())
	register_cheat("tcheat", test_cheat, "A test cheat")
	register_cheat("tc", test_cheat, "An abbreviated test cheat")
	register_cheat("z.purge.console", purge_history, "Purges all console history.")
	register_cheat("z.print.args", print_all_args, "Prints all arguments for registered cheats.")


func print_all_args() -> void:
	for key in cheats:
		var entry := cheats.get(key)
		var args : Array[Dictionary] = entry.get("args")
		var str : String = key + "("
		for a in args:
			var name : String = a.get("name", "")
			var type : int = a.get("type", 0)
			str += "[%s : %s]" % [name, type_string(type)]
		print(str + ")")


#TODO add check to ensure that a cheat's owning object still exists before calling it
func validate_cheat() -> void:
	pass


func rebuild_ui() -> void:
	close()
	await get_tree().process_frame
	open()
