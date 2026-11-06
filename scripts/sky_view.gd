extends Node2D
## Widok z teleskopu: przesuwanie nieba myszką / WASD, wykrywanie i katalogowanie gwiazdozbiorów.

const PAN_SPEED := 140.0
const MOUSE_SENS := 0.6
const SKY_RADIUS := 260.0
const LENS_RADIUS := 90.0

@onready var camera: Camera2D = $Camera2D
@onready var hint: Label = $Overlay/Hint
@onready var title: Label = $Overlay/Title

var _t := 0.0
var _bg_stars: Array = []
var _positions := {}   # id -> Array[Vector2]
var _candidate := ""
var _flash := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var palette := [Color(1, 1, 1), Color(0.8, 0.85, 1.0), Color(1.0, 0.94, 0.78), Color(0.62, 0.7, 0.95)]
	for i in 900:
		var r := sqrt(rng.randf()) * (SKY_RADIUS + 160.0)
		var a := rng.randf() * TAU
		_bg_stars.append({
			"pos": Vector2(cos(a), sin(a)) * r,
			"size": 1 if rng.randf() < 0.85 else 2,
			"base": rng.randf_range(0.25, 0.9),
			"phase": rng.randf() * TAU,
			"speed": rng.randf_range(0.8, 3.0),
			"col": palette[rng.randi() % palette.size()],
		})
	for id in GameState.CONSTELLATIONS:
		var pts: Array[Vector2] = []
		for s in GameState.CONSTELLATIONS[id]["stars"]:
			pts.append(GameState.star_position(s[0], s[1]))
		_positions[id] = pts
	camera.position = Vector2(40, -30)
	_update_title()
	GameState.constellation_found.connect(_on_found)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera.position += event.relative * MOUSE_SENS
		_clamp_camera()


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	camera.position += dir * PAN_SPEED * delta
	_clamp_camera()
	_candidate = _detect()
	if _candidate != "":
		if GameState.is_found(_candidate):
			hint.text = "%s   (skatalogowano)" % GameState.CONSTELLATIONS[_candidate]["name"]
		else:
			hint.text = "Coś tu jest...   [E] skataloguj"
			if Input.is_action_just_pressed("interact"):
				GameState.catalogue(_candidate)
	else:
		hint.text = "Mysz / WASD: przesuwaj niebo      Esc: wróć"
	if Input.is_action_just_pressed("ui_cancel"):
		GameState.interaction.emit("go_area", "balcony:FromTelescope", self)
	queue_redraw()


func focus_on(id: String) -> void:
	if _positions.has(id):
		camera.position = _centroid(_positions[id])


func _on_found(_id: String) -> void:
	_flash = 1.5
	_update_title()


func _update_title() -> void:
	title.text = "TELESKOP     skatalogowano: %d / %d" % [GameState.found.size(), GameState.CONSTELLATIONS.size()]


func _centroid(pts: Array) -> Vector2:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	return c / pts.size()


func _clamp_camera() -> void:
	if camera.position.length() > SKY_RADIUS:
		camera.position = camera.position.normalized() * SKY_RADIUS


func _detect() -> String:
	for id in _positions:
		var inside := true
		for p in _positions[id]:
			if p.distance_to(camera.position) > LENS_RADIUS - 6.0:
				inside = false
				break
		if inside:
			return id
	return ""


func _draw() -> void:
	draw_circle(Vector2.ZERO, SKY_RADIUS + 220.0, Color(0.03, 0.04, 0.09))
	for s in _bg_stars:
		var a: float = s["base"] * (0.7 + 0.3 * sin(_t * s["speed"] + s["phase"]))
		var c: Color = s["col"]
		c.a = a
		draw_rect(Rect2(s["pos"].floor(), Vector2.ONE * s["size"]), c)
	for id in _positions:
		var pts: Array = _positions[id]
		var found := GameState.is_found(id)
		if found or (_flash > 0.0 and id == _candidate):
			var lc := Color(0.55, 0.7, 1.0, 0.55)
			for l in GameState.CONSTELLATIONS[id]["lines"]:
				draw_line(pts[l[0]], pts[l[1]], lc, 1.0)
		for p in pts:
			var tw := 0.8 + 0.2 * sin(_t * 2.0 + p.x * 0.1)
			draw_circle(p, 3.0, Color(0.75, 0.85, 1.0, 0.18 * tw))
			draw_rect(Rect2(p.floor() - Vector2.ONE, Vector2(3, 3)), Color(1, 1, 1, tw))
		if found:
			var c := _centroid(pts)
			var bottom := -INF
			for p in pts:
				bottom = maxf(bottom, p.y)
			draw_string(ThemeDB.fallback_font, Vector2(c.x - 40.0, bottom + 14.0), GameState.CONSTELLATIONS[id]["name"], HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color(0.8, 0.88, 1.0, 0.9))
