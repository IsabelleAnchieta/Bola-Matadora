extends CharacterBody2D


func _physics_process(delta: float) -> void:

	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.death()

func receber_impacto(bola):
	bola.posse = false
	bola.rebater(bola.direcao, bola.velocidade + 100)
