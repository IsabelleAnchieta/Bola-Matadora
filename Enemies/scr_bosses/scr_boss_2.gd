extends "res://Enemies/scr_bosses/scr_boss_base.gd"

@onready var escudo = $escudo


func _physics_process(delta: float) -> void:
	if !dead:
		var look = global_position.direction_to(target.global_position)
		escudo.global_position = global_position + look * 40
		escudo.look_at(target.global_position)

	super._physics_process(delta)
