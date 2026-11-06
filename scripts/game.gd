extends Node2D
## Główna scena: przełącza obszary (pokój / balkon / teleskop), obsługuje HUD, przejścia i warstwę VHS.

const AREAS := {
	"room": "res://scenes/room.tscn",
	"balcony": "res://scenes/balcony.tscn",
	"sky": "res://scenes/sky_view.tscn",
}

@onready var world: Node2D = $World
@onready var fade: ColorRect = $HUD/Fade
@onready var prompt_label: Label = $HUD/Prompt
@onready var message_label: Label = $HUD/Message
@onready var stardust_label: Label = $HUD/Stardust
@onready var clock_label: Label = $HUD/Clock
@onready var vhs_rect: ColorRect = $VHS/Rect

var current_area: Node = null
var current_area_id := ""
var _changing := false
var _message_tween: Tween


func _ready() -> void:
	GameState.interaction.connect(_on_interaction)
	GameState.message.connect(show_message)
	GameState.prompt_changed.connect(func(t: String) -> void: prompt_label.text = t)
	GameState.stardust_changed.connect(_update_stardust)
	GameState.time_changed.connect(func(_m: float) -> void: clock_label.text = GameState.time_string())
	GameState.constellation_found.connect(_on_constellation_found)
	_update_stardust(GameState.stardust)
	clock_label.text = GameState.time_string()
	message_label.modulate.a = 0.0
	vhs_rect.visible = GameState.vhs_enabled
	fade.modulate.a = 1.0
	await _load_area("room", "Start")
	await _fade_to(0.0, 0.6)
	if _autoshot_enabled():
		_autoshot()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_vhs"):
		GameState.vhs_enabled = not GameState.vhs_enabled
		vhs_rect.visible = GameState.vhs_enabled
		show_message("Filtr VHS: %s" % ("włączony" if GameState.vhs_enabled else "wyłączony"))


func _on_interaction(action: String, payload: String, _source: Node) -> void:
	match action:
		"message":
			show_message(payload)
		"go_area":
			var parts := payload.split(":")
			change_area(parts[0], parts[1] if parts.size() > 1 else "")
		"computer":
			show_message(_catalogue_text())
		"bed":
			show_message("Jeszcze nie pora spać. Niebo czeka.")
		"clock":
			show_message("Jest %s. Najciemniej jest przed świtem." % GameState.time_string())
		_:
			show_message(payload)


func _on_constellation_found(id: String) -> void:
	var c: Dictionary = GameState.CONSTELLATIONS[id]
	show_message("Skatalogowano: %s   (+%d pyłu gwiezdnego)" % [c["name"], int(c["reward"])])


func change_area(area_id: String, spawn: String) -> void:
	if _changing or not AREAS.has(area_id):
		return
	_changing = true
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
	GameState.set_prompt("")
	await _fade_to(1.0, 0.25)
	await _load_area(area_id, spawn)
	GameState.set_prompt("")
	await _fade_to(0.0, 0.25)
	_changing = false


func _load_area(area_id: String, spawn: String) -> void:
	if current_area:
		current_area.queue_free()
		current_area = null
	var scene: PackedScene = load(AREAS[area_id])
	current_area = scene.instantiate()
	current_area_id = area_id
	world.add_child(current_area)
	var player := get_tree().get_first_node_in_group("player")
	if player and spawn != "":
		var marker := current_area.get_node_or_null("Spawns/" + spawn)
		if marker:
			player.global_position = marker.global_position
			if marker.has_meta("facing"):
				player.set_facing(marker.get_meta("facing"))
	await get_tree().process_frame


func _fade_to(alpha: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", alpha, duration)
	await tw.finished


func show_message(text: String) -> void:
	message_label.text = text
	if _message_tween and _message_tween.is_valid():
		_message_tween.kill()
	message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(2.6 + text.length() * 0.03)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)


func _update_stardust(value: float) -> void:
	stardust_label.text = "Pył gwiezdny: %d" % int(value)


func _catalogue_text() -> String:
	var lines: Array[String] = ["KATALOG NIEBA   (pył: %d)" % int(GameState.stardust)]
	for id in GameState.CONSTELLATIONS:
		var c: Dictionary = GameState.CONSTELLATIONS[id]
		lines.append("%s %s" % ["[x]" if GameState.is_found(id) else "[ ]", c["name"]])
	if GameState.found.size() > 0:
		lines.append("+%.1f pyłu / minutę" % (GameState.INCOME_PER_CONSTELLATION * GameState.found.size()))
	else:
		lines.append("Skataloguj coś przez teleskop na balkonie.")
	return "\n".join(lines)


## Tryb debug: jeśli plik debug_autoshot.flag zawiera "on", gra sama robi zrzuty ekranu do debug_shots/ i się zamyka.
func _autoshot_enabled() -> bool:
	if not FileAccess.file_exists("res://debug_autoshot.flag"):
		return false
	var f := FileAccess.open("res://debug_autoshot.flag", FileAccess.READ)
	return f != null and f.get_as_text().strip_edges() == "on"


func _autoshot() -> void:
	await get_tree().create_timer(1.0).timeout
	await _shot("room")
	await change_area("balcony", "FromRoom")
	await get_tree().create_timer(0.8).timeout
	await _shot("balcony")
	await change_area("sky", "")
	await get_tree().create_timer(0.8).timeout
	if current_area and current_area.has_method("focus_on"):
		current_area.focus_on("big_dipper")
	await get_tree().create_timer(0.5).timeout
	await _shot("sky")
	GameState.catalogue("big_dipper")
	await get_tree().create_timer(0.8).timeout
	await _shot("sky_found")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://debug_shots"))
	var err := img.save_png("res://debug_shots/%s.png" % shot_name)
	print("[autoshot] %s -> %s" % [shot_name, error_string(err)])
