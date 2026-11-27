extends "res://test/rec_tut.gd"
# Nagranie samouczka „Konto na minusie” (Etap 2): czerwona kwota w rogu, nieopłacony zespół z dymkiem „$?”. Na komputerze z GPU.


func _ready() -> void:
	Game.use_test_save()
	await get_tree().process_frame
	Game.new_game()
	Game.logo = "paws"
	Game.start_stage(2)
	arrow = Game.img("os/ui_cursor")
	arrow.convert(Image.FORMAT_RGBA8)
	for k in ["tut_tel", "tut_pc", "tut_shop", "tut_meteor", "tut_edycja", "tut_widmo", "tut_dlug", "stage2_intro", "arbjooze"]:
		Game.tips[k] = true
	Game.shop["st_obs"] = true
	Game.shop["st_obs2"] = true
	Game.money = 120
	var w = load("res://game/world.tscn").instantiate()
	get_tree().root.add_child(w)
	for i in 10: await get_tree().process_frame
	for c in Game.candidates.slice(0, 2):
		Game.hire(c)
	w._enter("room", true)
	w.busy = false
	await get_tree().create_timer(1.0).timeout
	var hud := Rect2i(0, 0, 320, 180)  # lewy górny róg ekranu: kwota $
	for i in 6:
		await grab(hud, 0.12)
	Game.money = -110  # pensje zjadły resztę: kwota czerwona
	Game.changed.emit()
	for i in 14:
		await grab(hud, 0.12)
	save("dlug_hud")
	for p in Game.staff:
		p.unpaid = Game.STRIKE_DAYS
	Game.changed.emit()
	await get_tree().create_timer(1.5).timeout
	var r := crop_at(Vector2(200, 210) + Game.margin)  # zespół na podłodze laboratorium
	for i in 24:
		await grab(r, 0.12)
	save("dlug_strike")
	Game.quit()
