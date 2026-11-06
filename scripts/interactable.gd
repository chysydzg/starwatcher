class_name Interactable
extends Area2D
## Obiekt, z którym gracz może wejść w interakcję (klawisz E).
## action: "message" (pokaż payload), "go_area" (payload "obszar:Spawn"), "computer", "bed", "clock".

@export var prompt := "Interakcja"
@export var action := "message"
@export_multiline var payload := ""


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true


func interact(_player: Node) -> void:
	GameState.interaction.emit(action, payload, self)
