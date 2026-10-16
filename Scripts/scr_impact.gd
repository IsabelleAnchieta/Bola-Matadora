
extends Node2D

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	rotation = randf_range(0.0, TAU)
	z_index = 10
	animacao.play("impact")
	animacao.animation_finished.connect(queue_free)
