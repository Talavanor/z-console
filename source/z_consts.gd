@tool
class_name ZConsts extends RefCounted
## A collection of constant values and static retriever functions for use by ZConsole


const T_LOG : String = '[font size={font_size} top={line_space} bt={line_space}][font_size={md_size}][color={c_dim}]{ts_val}[/color][/font_size] [i][font size={font_size} otv="wght={b_weight}"]{key}[/font][/i][font_size={md_size}]{entry}[/font_size]\n'
const T_BASIC : String = '[color={c_dim}] > [font_size={val_size}]{val_type} [/font_size][/color][color={c_val}]{val}[/color]'
const T_VEC2 : String = '[color={c_dim}] > [font_size={val_size}]{val_type} [/font_size]([/color][color={c_x}]X:{x_val}[/color][color={c_dim}],[/color] [color={c_y}]Y:{y_val}[/color][color={c_dim}])[/color]'
const T_VEC3 : String = '[color={c_dim}] > [font_size={val_size}]{val_type} [/font_size]([/color][color={c_x}]X:{x_val}[/color][color={c_dim}],[/color] [color={c_y}]Y:{y_val}[/color][color={c_dim}],[/color] [color={c_z}]Z:{z_val}[/color][color={c_dim}])[/color]'

const T_VAL_COLOR : String = "[color={c_hex}]#{hex}[/color][color={c_dim}] | [/color][color={c_red}]r:{red}[/color] [color={c_green}]g:{green}[/color] [color={c_blue}]b:{blue}[/color] [color={c_alpha}]a:{alpha}[/color]"

const SETTING_PATH : String = "addons/z-console/%s"

static var f_precision : int = 2
static var font_size : float = 14.0
static var line_space : float = 4.0
static var max_history_lines : int = 8
static var global_scale : float = 1.0
static var b_weight : int = 600


const COLORS : Dictionary = {
	TYPE_BOOL:			Color.ORANGE_RED,
	TYPE_INT:			Color.PALE_GREEN,
	TYPE_FLOAT:			Color.PALE_GREEN,
	TYPE_VECTOR2:		Color.LIGHT_BLUE,
	TYPE_VECTOR2I:		Color.LIGHT_BLUE,
	TYPE_VECTOR3:		Color.PALE_VIOLET_RED,
	TYPE_VECTOR3I:		Color.PALE_VIOLET_RED,
}

static var c_dim_text : String = Color.WEB_GRAY.to_html()
static var c_false : String = Color.PALE_VIOLET_RED.to_html()
static var c_true : String = Color.PALE_GREEN.to_html()
static var c_red : String = Color.RED.lightened(0.2).to_html()
static var c_green : String = Color.GREEN.lightened(0.35).to_html()
static var c_blue : String = Color.BLUE.lightened(0.45).to_html()


## Returns the basic color value assigned to the provided TYPE value
static func get_type_color(type : int) -> String:
	return COLORS.get(type, Color.WHITE).to_html()


## Returns a "smart" string for the value with type specific handling of certain value types.
## For example, bool values will return as green (true) or red (false), and vectors will return as color coded.
static func get_smart_type_string(value : Variant) -> String:
	var str : String = ""
	var type := typeof(value)
	var f_size : float = get_scaled_font_size(0.9)
	var prefix_size : float = get_scaled_font_size(0.65)

	# Based on the type of value we've passed in we can do type-specific formatting
	match type:
		TYPE_NIL:
			str = ""
		TYPE_COLOR:
			if value is Color:
				var hex : String = Color(value).to_html()
				#var name : String =
				str = T_BASIC.format({
					"val" : T_VAL_COLOR.format({
						"c_hex" : hex,
						"hex" : hex,
						"red" : f_string(value.a),
						"green" : f_string(value.g),
						"blue" : f_string(value.b),
						"c_alpha" : Color(Color.WHITE, value.a).to_html(),
						"alpha" : f_string(value.a)
					})
				})

		TYPE_BOOL:
			str = T_BASIC.format({
				"c_val" : choose(value, c_green, c_red),
				"val" : str('[font size={font_size} otv="wght={b_weight}"]', str(value).to_upper(), "[/font]")
			})

		TYPE_VECTOR2:
			str = T_VEC2.format({
				"x_val" : "%.2f" % value.x,
				"y_val" : "%.2f" % value.y
			})

		TYPE_VECTOR2I:
			str = T_VEC2.format({
				"x_val" : "%02d" % value.x,
				"y_val" : "%02d" % value.y
			})

		TYPE_VECTOR3:
			str = T_VEC3.format({
				"x_val" : "%.2f" % value.x,
				"y_val" : "%.2f" % value.y,
				"z_val" : "%.2f" % value.z
			})

		TYPE_VECTOR3I:
			str = T_VEC3.format({
				"x_val" : "%02d" % value.x,
				"y_val" : "%02d" % value.y,
				"z_val" : "%02d" % value.z
			})

		_:
			str = T_BASIC.format({
				"c_val" : Color.WHITE.to_html(),
				"val" : str(value),
			})


	# Do all generic formatting before we return
	var wrap_str = str.format({
		"c_dim" : c_dim_text,
		"c_x" : c_red,
		"c_y" : c_green,
		"c_z" : c_blue,
		"c_red" : c_red,
		"c_green" : c_green,
		"c_blue" : c_blue,
		"val_type" : type_string(type),

	})

	return wrap_str


static func build_log_entry(entry : Dictionary) -> String:
	var ts := Time.get_time_string_from_unix_time(entry.get("timestamp", 0))
	var cmd = entry.get("cmd", "")
	var result = entry.get("result", "")
	var log := T_LOG.format({
		# Must format the smart string before anything else so defaults can apply to inline styles (see the bool value)
		"entry" : get_smart_type_string(result),
		"ts_val" : ts,
		"key" : cmd,
		"c_dim" : c_dim_text,
		"font_size" : get_scaled_font_size(1),
		"md_size" : get_scaled_font_size(0.95),
		"val_size" : get_scaled_font_size(0.65),
		"b_weight" : b_weight,
		"line_space" : line_space,
	})
	return log




static func get_scaled_font_size(scale : float, round : bool = true) -> float:
	if round: return floori(font_size * scale * global_scale)
	return font_size * scale * global_scale


static func choose(b : bool, v1 : Variant, v2 : Variant) -> Variant:
	if b: return v1
	return v2


static func f_string(value : float) -> String:
	var template := "%.{f}f".format({"f" : f_precision})
	return template % value



