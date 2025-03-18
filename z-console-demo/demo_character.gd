class_name Player extends CharacterBody2D


const SPEED = 400.0
const ACCEL = 4.0
const JUMP_VELOCITY = 500.0

var min_jump = JUMP_VELOCITY * 0.33
var jump_pressed : bool = false
var direction : float = 0
var speed_multi : float = 1.0



func _ready() -> void:
	Console.register_cheat("player.doublespeed", double_speed, "Doubles player speed.")
	Console.register_cheat("player.speedmulti", set_speed_multi, "Set player speed multiplier to provided value.")
	Console.register_cheat("player.getposition", get_world_position, "Returns the world position of the player.")


## Input example to respect console interruption
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		jump_pressed = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W)
		if jump_pressed and is_on_floor():
			velocity.y = -JUMP_VELOCITY


		var left_pressed := Input.is_physical_key_pressed(KEY_D) as float
		var right_pressed := Input.is_physical_key_pressed(KEY_A) as float

		direction = left_pressed - right_pressed


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		var g := get_gravity()
		if velocity.y >= 0: g *= 1.5
		if not jump_pressed and velocity.y < -min_jump:
			velocity.y = -min_jump
		velocity += g * delta

	var a := ACCEL
	if not is_on_floor(): a /= 2

	if direction:
		velocity.x = lerpf(velocity.x, direction * SPEED * speed_multi, a * delta)
	else:
		velocity.x = lerpf(velocity.x, 0, a * 4 * delta)

	move_and_slide()


func double_speed() -> void:
	speed_multi *= 2


func set_speed_multi(value : float, option : bool = false) -> void:
	speed_multi = value


func get_world_position() -> Vector2:
	return global_position
