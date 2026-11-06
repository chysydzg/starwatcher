extends Node2D
## Balkon: nocny, niebieskawy tint na postaci i rekwizytach.

@export var night_tint := Color(0.68, 0.72, 0.95)

@onready var ysort: Node2D = $YSort


func _ready() -> void:
	ysort.modulate = night_tint
