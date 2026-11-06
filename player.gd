extends CharacterBody2D
## Prosta postac top-down: ruch WASD / strzalki, obrot w kierunku ruchu.

@export var speed := 300.0
@export var body_radius := 24.0
@export var body_color := Color(0.25, 0.6, 1.0)

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# WASD obok strzalek, bez potrzeby konfigurowania Input Map
	var wasd := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	if wasd != Vector2.ZERO:
		dir = wasd.normalized()

	velocity = dir * speed
	move_and_slide()

	if dir != Vector2.ZERO:
		rotation = lerp_angle(rotation, dir.angle(), 0.25)

func _draw() -> void:
	# Cialo
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 32, Color.WHITE, 2.0)
	# "Nos" pokazujacy kierunek patrzenia
	var nose := PackedVector2Array([
		Vector2(body_radius + 10.0, 0.0),
		Vector2(body_radius - 6.0, -9.0),
		Vector2(body_radius - 6.0, 9.0),
	])
	draw_colored_polygon(nose, Color.WHITE)
