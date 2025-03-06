@tool
class_name ConsoleInterface extends Control


const C_UTS := Color(Color.GRAY, 0.5)
const C_CMD	:= Color.WHITE
const C_RES := Color.SPRING_GREEN
const T_LOG  : String = "[font top=2 bt=2][color=%s]%s: [/color][color=%s]%s[/color][color=%s] -> [/color]%s\n"

@onready var console_line := %LineEdit as ConsoleLine
@onready var history_label := %HistoryLabel as RichTextLabel
@onready var history_panel := %HistoryPanel as PanelContainer

var history_index : int = 0 : set = _set_history_index
var entry_storage : String = ""


func _process(delta: float) -> void:
	if not Engine.is_editor_hint(): return
	var ts := Time.get_time_string_from_unix_time(Time.get_unix_time_from_system())
	var result := Vector2()
	var results : Array = [
		true,
		false,
		int(4),
		float(12.54),
		Vector2(230, -001),
		Vector2i(230, -001),
		Vector3(232, -32, 64),
		Vector3i(232, -32, 64),
		Color.WHITE,
		Color.CRIMSON,
		Color(Color.CRIMSON, 0.25),
		Color(Color.CRIMSON, 0.5),
	]
	history_label.text = ""
	for r in results:

		var log : Dictionary = {
			"timestamp" : 0,
			"cmd": "key.value.cmd",
			"result": r
		}
		history_label.append_text(ZConsts.build_log_entry(log))
	_update_history_height()


func _update_history_height() -> void:
	var max_height := history_label.get_content_height() as float
	if history_label.get_line_count() > ZConsts.max_history_lines:
		max_height = history_label.get_line_offset(ZConsts.max_history_lines)
	history_label.custom_minimum_size = Vector2(history_label.get_content_width() + 16, max_height)

		#print(font.get_height() * )


func _make_history_entry(ts : String, key : String, result : Variant) -> String:
	var type := typeof(result)
	return (T_LOG % [
		C_UTS.to_html(), ts,
		C_CMD.to_html(), key,
		C_UTS.to_html(),
		ZConsts.get_smart_type_string(result)]
	)

func _ready() -> void:
	if Engine.is_editor_hint(): return
	# Just ensure we have these at the start to prevent checking constantly
	assert(console_line)
	assert(history_panel)
	assert(history_label)


	# Connect to events
	Console.history_changed.connect(_on_history_changed)
	Console.history_purged.connect(_rebuild_history, CONNECT_DEFERRED)
	console_line.text_submitted.connect(_on_submitted)
	console_line.text_changed.connect(_on_text_changed)

	# Visual and functional setup
	history_label.visible = false
	history_label.text = ""
	console_line.text = ""
	console_line.keep_editing_on_text_submit = true


	_rebuild_history.call_deferred()
	console_line.grab_focus.call_deferred()


## Input needs to be brokered through the main console interface due to an issue where
## handling it in the console line can lead to key input not being accepted by that object.
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	var just_pressed := event.is_pressed()
	if just_pressed:
		if Input.is_key_pressed(KEY_ESCAPE):
			Console.close()
			accept_event()
		if Input.is_key_pressed(KEY_UP):
			if console_line.text.is_empty(): history_index += 1
			else: console_line.handle_key_input(KEY_UP)
			accept_event()
		if Input.is_key_pressed(KEY_DOWN):
			if console_line.text.is_empty(): history_index -= 1
			else: console_line.handle_key_input(KEY_DOWN)
			accept_event()
		if Input.is_key_pressed(KEY_RIGHT):
			console_line.handle_key_input(KEY_RIGHT)
			accept_event()
		if Input.is_key_pressed(KEY_TAB):
			console_line.handle_key_input(KEY_TAB)
			accept_event()
		if Input.is_key_pressed(KEY_SPACE):
			console_line.handle_key_input(KEY_SPACE)
			accept_event()
		if Input.is_key_pressed(KEY_ENTER):
			console_line.handle_key_input(KEY_ENTER)
			accept_event()



func _set_history_index(value : int) -> void:
	var h := Console.history
	print(h)
	if not h: return

	var max := h.size()
	history_index = clampi(value, 0, max)

	var index := max - history_index
	if index == h.size():
		console_line.set_auto_string(entry_storage)
	else:
		var entry : Dictionary = Console.history[max - history_index]
		console_line.set_auto_string(entry.get("cmd"))
	#print("HI: %s, L: %s" % [history_index, max - history_index])


func _on_text_changed(new_text: String) -> void:
	if history_index == 0:
		entry_storage = console_line.text


#todo move to line?
func _on_submitted(new_text: String) -> void:
	print("Submitting: %s" % new_text)
	var result := Console.run(new_text)

	if result is Expression:
		print(result.get_error_text())
		# if not result.has_execute_failed():
		# 	Console.close()
	console_line.clear()


func _on_history_changed(history : Array[Dictionary]) -> void:
	history_label.append_text(ZConsts.build_log_entry(history.back()))
	show_or_hide_history()


func _on_history_purged() -> void:
	_rebuild_history.call_deferred()


func _rebuild_history() -> void:
	history_label.text = ""
	for entry in Console.history:
		history_label.append_text(ZConsts.build_log_entry(entry))

	show_or_hide_history()
	history_index = 0


func show_or_hide_history() -> void:
	if not Console.history or Console.history.is_empty(): history_label.visible = false
	else: history_label.visible = true


func populate_automenu() -> void:
	if not Console.history or Console.history.is_empty(): history_label.visible = false
	else: history_label.visible = true
