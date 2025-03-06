@tool
class_name ConsoleLine extends LineEdit

const PROXY_TEMP : String = "%s[color=%s]%s[/color] \t [color=%s]%s[/color] \t [color=%s][i]%s[/i][/color]"
const CHEAT_TEMP : String = "[font top=%s bt=%s]%s[font_size=%s] -> %s[/font_size][/font]"

@export var c_auto := Color.LIGHT_BLUE
@export var c_tip := Color.YELLOW
@export var c_focus := Color.INDIAN_RED

@export var tip_size : int = 13
var line_spacing : float = 4

@onready var automenu_panel := %AutoMenuPanel as PanelContainer
@onready var automenu_label := %AutoMenuLabel as RichTextLabel
@onready var proxy := %ProxyLabel as RichTextLabel

var cmd_string : String = "" : set = _set_cmd_string
var auto_string : String = ""
var arg_string : String = ""
var tip_string : String = ""


var matches : Array[String] = []
var arg_data : Array[Dictionary] = []
var selection_index : int = 0
var line_storage : String = ""

var in_arg_edit : bool = false
var arg_storage : Array = []

# region Formatting debug in-editor
func _process(delta: float) -> void:
	if not Engine.is_editor_hint(): return
	cmd_string = "z.com"
	auto_string = "mand.preview"
	arg_string = "arg1 : bool = value \t arg2 : float = 0.2"
	tip_string = "tip"

	var spacing : float = line_spacing / 2.0
	automenu_label.text = ""
	automenu_panel.visible = true
	add_automenu_entry("z.command.preview", "selected cheat")
	for i in range(4):
		add_automenu_entry("demo.cheat.%02d" % i, "cheat tip")
		#automenu_label.text += CHEAT_TEMP % [spacing, spacing, "demo.cheat.%02d" % i, tip_size, "cheat tip"]
	#populate_automenu(["One, Two, Three"])
	_redraw_proxy()
	#proxy.text = PROXY_TEMP % ["leading.com",c_auto.to_html() ,"mand.autocomplete"]

# endregion Formatting debug in-editor


func _ready() -> void:
	assert(proxy)
	assert(automenu_panel)
	assert(automenu_label)

	if not Engine.is_editor_hint():
		cmd_string = ""
		auto_string = ""
		arg_string = ""
		tip_string = ""

	text_changed.connect(on_text_changed)
	text = ""
	proxy.text = ""
	automenu_label.text = ""
	automenu_panel.visible = false


func on_text_changed(new_text: String) -> void:
	#get_viewport().set_input_as_handled.call_deferred()
	proxy.text = text
	var len := text.length()
	if caret_column < len:
		delete_text(caret_column, len)

	find_matches()
	get_args()
	autocomplete()
	populate_automenu(matches)
	_redraw_proxy()


func _redraw_proxy() -> void:
	var tab_01 := cmd_string.length() + auto_string.length()
	var tab_02 := arg_string.length()
	var tab_string : String = "'%.2f, %.2f'" % [tab_01, tab_02]
	proxy.text = PROXY_TEMP % [
			cmd_string,
			c_auto.to_html(), auto_string,
			c_auto.to_html(), arg_string,
			c_tip.to_html(), tip_string,
		]
	proxy.text += str(arg_storage)


func sim_typing(new_string : String, replace : bool = true) -> void:
	if replace: text = new_string
	else: text += new_string
	caret_column = text.length()
	text_changed.emit.call_deferred(text)


func set_auto_string(value : String) -> void:
	auto_string = value
	_redraw_proxy()


func accept_autocomplete() -> void:
	sim_typing(text + auto_string)


func get_args() -> void:
	arg_string = ""
	arg_data.clear()
	if matches.has(text):
		arg_data = Console.get_args(text)
		print(arg_data)
		if arg_data.is_empty(): return
		print("%s args:" % [text])
		for a in arg_data:
			if a is Dictionary:
				var name := a.get("name", "") as String
				var type := a.get("type", -1) as int
				arg_string += "%s : %s, " % [name, type_string(type)]

		arg_string.trim_suffix(", ")
		print(arg_string)


func handle_key_input(key : Key) -> void:
	match key:
		KEY_UP: set_selection_index(1)
		KEY_DOWN: set_selection_index(-1)
		KEY_RIGHT: accept_autocomplete()
		KEY_TAB: handle_tab()
		KEY_ENTER: handle_enter()
		KEY_SPACE: pass
	accept_event()


func handle_tab() -> void:
	if in_arg_edit:
		sim_typing("\t", false)
	else:
		accept_autocomplete()


func handle_enter() -> void:
	if in_arg_edit:
		text_submitted.emit.call_deferred(cmd_string)
		arg_storage.clear.call_deferred()
	else:
		accept_autocomplete()


func set_selection_index(value : int) -> void:
	selection_index = wrapi(selection_index + value, 0, matches.size())
	if not matches.is_empty():
		auto_string = matches[selection_index].trim_prefix(text)
	populate_automenu(matches)
	_redraw_proxy()


func find_matches() -> void:
	matches.clear()
	var category : String = text
	if not text: return

	for key : String in Console.cheats.keys():
		var suffix_idx := text.rfindn(".")
		if suffix_idx != -1: category = text.left(suffix_idx)
		if key.begins_with(category) and key.containsn(text): matches.append(key)
	matches.sort()
	print("Matches: %s %s" % [matches, category])


func autocomplete() -> void:
	# Whenever we autocomplete/type we reset any active selection since that list will change size
	selection_index = 0
	auto_string = ""
	if not matches.is_empty():
		auto_string = matches[0].trim_prefix(text)
	cmd_string = text
	print(cmd_string)


func populate_automenu(matches : Array[String]) -> void:
	# If there's no text or the current text is an exact copy of a cheat we hide the automenu
	if matches.has(text):
		automenu_panel.visible = false
		in_arg_edit = true
		return

	if text == cmd_string:
		in_arg_edit = false

	if matches.is_empty():
		automenu_panel.visible = false
		return


	# Otherwise, we show the panel and clear the label in preparation for building a list of matching cheats
	automenu_panel.visible = true
	automenu_label.text = ""

	for i in range(matches.size()-1, -1, -1):
		var entry : String = matches[i]
		add_automenu_entry(entry, Console.get_tip(entry))



func add_automenu_entry(key : String, tip : String) -> void:
		var wrapper : String = "  %s"
		var spacing : float = line_spacing * 0.5
		var txt : String = CHEAT_TEMP % [
				spacing, spacing,
				key,
				tip_size, tip
			]

		if cmd_string + auto_string == key:
			wrapper = "[i][color=" + c_tip.to_html() + "]> %s[/color][/i]"

		automenu_label.text += wrapper % txt + "\n"

	# var spacing : float = line_spacing / 2.0
	# automenu_label.text = ""
	# automenu_panel.visible = true
	# for i in range(4):
	# 	automenu_label.text += CHEAT_TEMP % [spacing, spacing, "demo.cheat.%02d" % i, tip_size, "cheat tip"]

func _set_cmd_string(value : String) -> void:

	var split_val : Array[String ]= []
	split_val.assign(value.split("\t", false))
	if split_val.is_empty():
		cmd_string = ""
		return

	cmd_string = split_val.pop_front()
	arg_storage = split_val
	if not Engine.is_editor_hint():
		print("Args: %s" % [split_val])
