extends Node
## Globalny stan gry (autoload "GameState"): zasoby, czas, katalog gwiazdozbiorów, sygnały dla HUD.

signal stardust_changed(value: float)
signal constellation_found(id: String)
signal message(text: String)
signal prompt_changed(text: String)
signal time_changed(minutes: float)
signal interaction(action: String, payload: String, source: Node)

## Gwiazdozbiory: pozycje gwiazd jako [rektascensja w godzinach, deklinacja w stopniach].
## Rzutowanie biegunowe wokół Gwiazdy Polarnej (patrz star_position), więc układ jest zgodny z prawdziwym niebem.
const CONSTELLATIONS := {
	"big_dipper": {
		"name": "Wielki Wóz",
		"reward": 10.0,
		"stars": [[11.062, 61.75], [11.030, 56.38], [11.897, 53.69], [12.257, 57.03], [12.900, 55.96], [13.399, 54.93], [13.792, 49.31]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 0], [3, 4], [4, 5], [5, 6]],
	},
	"little_dipper": {
		"name": "Mały Wóz",
		"reward": 15.0,
		"stars": [[2.530, 89.26], [17.537, 86.59], [16.766, 82.04], [15.734, 77.79], [16.292, 75.76], [15.345, 71.83], [14.845, 74.16]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3]],
	},
	"cassiopeia": {
		"name": "Kasjopeja",
		"reward": 12.0,
		"stars": [[0.153, 59.15], [0.675, 56.54], [0.945, 60.72], [1.430, 60.24], [1.907, 63.67]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 4]],
	},
}

const SKY_SCALE := 5.0    # pikseli nieba na stopień deklinacji
const SKY_LST := 6.0      # czas gwiazdowy (h) - decyduje o obrocie nieba wokół bieguna
const INCOME_PER_CONSTELLATION := 0.5  # pył na minutę gry za każdy skatalogowany gwiazdozbiór

var stardust := 0.0
var found: Array[String] = []
var minutes := 22.0 * 60.0   # czas gry (minuty od północy), start 22:00
var time_scale := 1.0        # minut gry na sekundę rzeczywistą
var vhs_enabled := true
var prompt := ""


func _ready() -> void:
	_setup_input()


func _process(delta: float) -> void:
	var before := int(minutes)
	minutes = fmod(minutes + delta * time_scale, 24.0 * 60.0)
	if int(minutes) != before:
		time_changed.emit(minutes)
		if found.size() > 0:
			add_stardust(INCOME_PER_CONSTELLATION * found.size())


func star_position(ra_hours: float, dec_deg: float) -> Vector2:
	var r := (90.0 - dec_deg) * SKY_SCALE
	var ang := deg_to_rad((ra_hours - SKY_LST) * 15.0)
	return Vector2(r * sin(ang), -r * cos(ang))


func add_stardust(amount: float) -> void:
	stardust += amount
	stardust_changed.emit(stardust)


func catalogue(id: String) -> bool:
	if id in found or not CONSTELLATIONS.has(id):
		return false
	found.append(id)
	add_stardust(CONSTELLATIONS[id]["reward"])
	constellation_found.emit(id)
	return true


func is_found(id: String) -> bool:
	return id in found


func time_string() -> String:
	var h := int(minutes / 60.0)
	var m := int(minutes) % 60
	return "%02d:%02d" % [h, m]


func show_message(text: String) -> void:
	message.emit(text)


func set_prompt(text: String) -> void:
	if text != prompt:
		prompt = text
		prompt_changed.emit(text)


func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("interact", [KEY_E, KEY_SPACE, KEY_ENTER])
	_add_action("toggle_vhs", [KEY_F1])


func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
