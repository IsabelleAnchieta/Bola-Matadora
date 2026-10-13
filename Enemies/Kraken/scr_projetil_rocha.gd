
extends Area2D

@export var velocidade: float = 650.0

var direcao: Vector2 = Vector2.ZERO
var ativa: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func configurar(direcao_ataque: Vector2) -> void:
	direcao = direcao_ataque.normalized()
	rotation = direcao.angle()


func _physics_process(delta: float) -> void:
	if not ativa:
		return

	global_position += direcao * velocidade * delta


func _on_body_entered(body: Node2D) -> void:
	if not ativa:
		return

	# A pedra mata o jogador ao tocá-lo.
	if body.is_in_group("player"):
		ativa = false
		body.death()
		queue_free()
		return

	# A bola será tratada separadamente, usando
	# o limite de velocidade necessário para causar
	# dano ao chefe.
	if body.has_method("rebater"):
		verificar_impacto_bola(body)
		return

	# Adicione os obstáculos sólidos à categoria "paredes".
	if body.is_in_group("paredes"):
		destruir()



func verificar_impacto_bola(bola: Node2D) -> void:
	if not ativa:
		return

	# A mesma velocidade mínima que permite à bola
	# causar dano ao chefe.
	if bola.velocidade > 200:
		destruir()



func destruir() -> void:
	if not ativa:
		return

	ativa = false
	queue_free()
	

func receber_parry() -> void:
	destruir()
