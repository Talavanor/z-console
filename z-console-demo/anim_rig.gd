extends AnimatedSprite2D

var player : Player

enum STATE {
	IDLE,
	MOVING,
	JUMPING
}

var anim_state := STATE.IDLE
var base_scale : float = 1


func _ready() -> void:
	base_scale = scale.x
	player = owner as Player
	assert(player)
	change_state(STATE.JUMPING)


func _physics_process(_delta: float) -> void:
	var d := player.direction
	if abs(d): scale.x = base_scale * sign(d)
	if player.is_on_floor():
		if abs(d): change_state(STATE.MOVING)
		else: change_state(STATE.IDLE)
	else:
		change_state(STATE.JUMPING)


func change_state(new_state : STATE) -> void:
	if anim_state == new_state: return
	anim_state = new_state
	match anim_state:
		STATE.IDLE: play("idle")
		STATE.MOVING: play("move")
		STATE.JUMPING: play("jump")
