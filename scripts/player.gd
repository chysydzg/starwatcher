extends CharacterBody2D
## Królik: ruch w 4 kierunkach (WASD / strzałki), interakcje klawiszem E.

@export var speed := 70.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_area: Area2D = $InteractArea

var facing := Vector2.DOWN
var can_move := true


func _ready() -> void:
	add_to_group("player")
	_update_sprite()


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if can_move:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
	if dir != Vector2.ZERO:
		facing = dir
		_update_sprite()


func _process(_delta: float) -> void:
	if not can_move:
		return
	var target := _nearest_interactable()
	GameState.set_prompt(("[E] " + target.prompt) if target else "")
	if target and can_move and Input.is_action_just_pressed("interact"):
		target.interact(self)


func set_facing(dir: Vector2) -> void:
	facing = dir
	_update_sprite()


func _update_sprite() -> void:
	if absf(facing.x) > absf(facing.y):
		sprite.frame = 2
		sprite.flip_h = facing.x < 0.0
	elif facing.y < 0.0:
		sprite.frame = 1
		sprite.flip_h = false
	else:
		sprite.frame = 0
		sprite.flip_h = false


func _nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for a in interact_area.get_overlapping_areas():
		if a is Interactable:
			var d := global_position.distance_squared_to(a.global_position)
			if d < best_d:
				best_d = d
				best = a
	return best
