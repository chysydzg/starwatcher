extends Node
# Pominięcie intro: przytrzymana spacja 2,5 s -> pasek się zapełnia, potem wygaszenie i gra.
func _ready() -> void:
	var cut: Node = load("res://game/cutscene.tscn").instantiate()
	add_child(cut)
	await get_tree().create_timer(3.0).timeout
	Input.action_press("confirm")
	await get_tree().create_timer(1.3).timeout
	var ok: bool = cut.skip_t > 1.0 and cut.skipping < 0.0
	if DisplayServer.get_name() != "headless":  # pasek w połowie (zrzut tylko z GPU)
		get_viewport().get_texture().get_image().save_png("res://debug_shots/cut_skip.png")
	await get_tree().create_timer(1.4).timeout
	ok = ok and cut.skipping >= 0.0
	Input.action_release("confirm")
	var f := FileAccess.open("res://debug_shots/skip_result.txt", FileAccess.WRITE)
	f.store_string("SKIP OK" if ok else "SKIP FAIL")
	f.close()
	get_tree().quit()  # przed końcem wygaszenia: _end() podmieniłby bieżącą scenę (ten test)
