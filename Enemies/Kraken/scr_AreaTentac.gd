
extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("bola"):
		return

	var tentaculo = get_parent()

	if not tentaculo.pode_receber_dano:
		return

	tentaculo.afundar()
