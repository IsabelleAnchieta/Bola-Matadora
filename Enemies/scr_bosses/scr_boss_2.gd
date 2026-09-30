extends "res://Enemies/scr_bosses/scr_boss_base.gd"

@onready var escudo = $escudo
var angulo_escudo = 0.0
var velocidade_escudo = 2.0

func _physics_process(delta: float) -> void:
	if !dead:
		var look = global_position.direction_to(target.global_position)

		var angulo_desejado = look.angle()

		angulo_escudo = lerp_angle(
			angulo_escudo,
			angulo_desejado,
			velocidade_escudo * delta
		)

		var posicao_orbita = Vector2.RIGHT.rotated(angulo_escudo) * 40

		escudo.global_position = global_position + posicao_orbita
		escudo.global_rotation = angulo_escudo

	super._physics_process(delta)
