
extends Area2D

@export var alcance_maximo: float = 1600.0
@export var largura_raio: float = 35.0
@export var duracao: float = 0.3

# Configure esta máscara para incluir somente as paredes
# que devem bloquear o raio.
@export_flags_2d_physics var mascara_paredes: int = 1

@onready var forma: CollisionShape2D = $CollisionShape2D
@onready var visual: Line2D = $Line2D

var ativo := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	forma.disabled = true
	monitoring = false
	visual.visible = false


func disparar(
	origem: Vector2,
	direcao: Vector2,
	excluidos: Array[RID] = []
) -> void:
	global_position = origem
	rotation = direcao.angle()

	# Descobre onde o raio encontra a primeira parede.
	var destino := origem + direcao.normalized() * alcance_maximo

	var consulta := PhysicsRayQueryParameters2D.create(
		origem,
		origem + direcao.normalized() * alcance_maximo,
		mascara_paredes
	)

	consulta.exclude = excluidos

	var resultado := get_world_2d().direct_space_state.intersect_ray(
		consulta
	)

	var distancia := alcance_maximo

	if not resultado.is_empty():
		distancia = origem.distance_to(resultado["position"])

	# Ajusta a colisão ao comprimento efetivo do raio.
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(distancia, largura_raio)
	forma.shape = retangulo
	forma.position = Vector2(distancia / 2.0, 0.0)

	# Desenha o jato ao longo do eixo local X.
	visual.clear_points()
	visual.add_point(Vector2.ZERO)
	visual.add_point(Vector2(distancia, 0.0))
	visual.width = largura_raio
	visual.visible = true

	ativo = true
	monitoring = true
	forma.set_deferred("disabled", false)

	await get_tree().create_timer(duracao).timeout

	if is_instance_valid(self):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not ativo:
		return

	if body.is_in_group("player"):
		print("Raio atingiu o jogador!")

		ativo = false
		set_deferred("monitoring", false)
		forma.set_deferred("disabled", true)

		body.death()
		queue_free()
