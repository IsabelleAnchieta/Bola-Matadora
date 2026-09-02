extends Node2D

@export var lugar : String
@export var able = true
@export var id_bosses : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if id_bosses in Run.bosses_derrotados:
		able = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if able:
		if body.is_in_group("player"):
			if lugar != null:
				get_tree().change_scene_to_file(lugar)
