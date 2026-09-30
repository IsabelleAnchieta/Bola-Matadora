extends CharacterBody2D

@onready var Boss = get_parent()

func _physics_process(delta: float) -> void:

	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	Boss._on_area_2d_body_entered(body)

func receber_impacto(bola):
	bola.posse = false
	bola.rebater(bola.direcao, bola.velocidade + 100)
