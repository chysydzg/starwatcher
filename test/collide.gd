extends Node
# Podgląd kolizji (widoczne kształty): Jania dochodzi do dołu balkonu i do mebli w pokoju.
func shot(label: String) -> void:
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://debug_shots/col_%s.png" % label)

func walk(w, v: Vector2, n: int) -> void:
	for i in n:
		w.body.velocity = v
		w.body.move_and_slide()
		await get_tree().physics_frame

func _ready() -> void:
	Game.use_test_save()
	get_tree().debug_collisions_hint = true
	Game.new_game()
	await get_tree().process_frame
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	await get_tree().create_timer(0.3).timeout
	w.body.position = Vector2(330, 330)
	await walk(w, Vector2(0, 150), 60)
	print("balkon dół y=", w.body.position.y)
	await walk(w, Vector2(-150, 0), 120)
	print("balkon lewo x=", w.body.position.x)
	w.body.position = Vector2(560, 340)
	await walk(w, Vector2(0, -150), 40)
	print("pod kwiatkiem y=", w.body.position.y)
	await shot("balkon")
	w._enter("room", true)
	w.body.position = Vector2(140, 160)
	await walk(w, Vector2(-150, 0), 60)
	print("łóżko bok x=", w.body.position.x, " ", w._nearest())
	w.body.position = Vector2(60, 300)
	await walk(w, Vector2(0, -150), 60)
	print("łóżko dół y=", w.body.position.y, " ", w._nearest())
	await shot("pokoj")
	# każdy punkt interakcji osiągalny mimo kolizji: idziemy z wolnego miejsca w stronę środka strefy
	for where in ["room", "balcony"]:
		w._enter(where, true)
		var spots: Dictionary = w.BALCONY_SPOTS if where == "balcony" else w.ROOM_SPOTS
		for id in spots:
			var r: Rect2 = spots[id]
			w.body.position = Vector2(clampf(r.get_center().x, 40, 600), 236.0 if where == "room" else 352.0)
			for i in 90:
				w.body.velocity = (r.get_center() - w.body.position).normalized() * 150
				w.body.move_and_slide()
				await get_tree().physics_frame
			print("strefa ", id, " -> ", w._nearest(), " @", w.body.position.round())
	Game.quit()
