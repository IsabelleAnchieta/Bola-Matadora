extends "res://Enemies/scr_bosses/scr_boss_base.gd"

@export var Projetil: PackedScene

var count = 3
var count2 = 0


func _physics_process(delta: float) -> void:
	if vida >= 5:
		vida = 5

	super._physics_process(delta)


func attack() -> void:
	var direction = global_position.direction_to(target.global_position)
	direcao = direction
	velocidade = 500.0
	cooldown.start()
	count2 = count


func shooting() -> void:
	if count2 <= 0:
		attack()
	else:
		var projetil = Projetil.instantiate()
		get_parent().add_child(projetil)

		projetil.global_position = global_position

		var direcao_projetil = global_position.direction_to(target.global_position)
		projetil.direcao = direcao_projetil

		count2 -= 1


func _on_timer_timeout() -> void:
	shooting()
