
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func configurar(
	textura: Texture2D,
	quadro: int,
	hframes: int,
	vframes: int,
	posicao: Vector2,
	escala: Vector2,
	rotacao: float,
	invertido_h: bool,
	invertido_v: bool
) -> void:
	sprite.texture = textura
	sprite.hframes = hframes
	sprite.vframes = vframes
	sprite.frame = quadro
	sprite.flip_h = invertido_h
	sprite.flip_v = invertido_v
	sprite.global_position = posicao
	sprite.global_rotation = rotacao
	sprite.global_scale = escala
	sprite.modulate = Color(0.4, 0.85, 1.0, 0.5)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
