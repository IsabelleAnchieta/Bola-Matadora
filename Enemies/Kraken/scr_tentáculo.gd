
extends CharacterBody2D

@onready var limites_tentaculos: Area2D = get_parent().get_node("LimitesTentaculos")

enum Estado {
	SUBMERSO,
	PREPARANDO,
	ATACANDO,
	RECUPERANDO,
	MERGULHANDO,
	DERROTADO
}


enum TipoTentaculo {
	ROCHA,
	ESMAGAMENTO,
	RAIO,
	BARRAGEM
}


# Ataques
@export var projetil_rocha: PackedScene
@export var cena_raio: PackedScene

# Tempos
@export var tempo_preparacao: float = 0.8
@export var tempo_recuperacao: float = 2.0
@export var tempo_submerso: float = 1.0
@export var tempo_ataque: float = 0.4

# Movimento
@export var velocidade_submerso: float = 350.0
@export var velocidade_ataque: float = 900.0
@export var distancia_previsao: float = 0.25
@export var distancia_emergencia: float = 250.0

# Indicador de esmagamento
@export var largura_marcador: float = 80.0

# Ataque de raio
@export var alcance_raio: float = 1600.0
@export var largura_indicador_raio: float = 2.0
@export var intervalo_jatadas: float = 0.35
@export var quantidade_jatadas: int = 3
@export var aviso_entre_jatadas: float = 0.65


var estado_atual: Estado = Estado.SUBMERSO
var tipo: TipoTentaculo = TipoTentaculo.ESMAGAMENTO

var alvo: CharacterBody2D

var pode_receber_dano: bool = false
var foi_derrotado: bool = false
var jogador_atingido: bool = false

var posicao_ataque: Vector2
var posicao_jogador: Vector2

var marcador: Line2D
var indicador_raio: Line2D


func _ready() -> void:
	alvo = get_parent().get_node("Player")
	iniciar_ciclo()


func iniciar_ciclo() -> void:
	ciclo_tentaculo()


func ciclo_tentaculo() -> void:
	while not foi_derrotado:
		estado_atual = Estado.SUBMERSO
		atualizar_colisoes(false, false)

		posicao_ataque = escolher_posicao_ataque()
		await mover_submerso(posicao_ataque)
		await esperar_se_despausar()

		if foi_derrotado or not is_inside_tree():
			return

		estado_atual = Estado.PREPARANDO
		atualizar_colisoes(true, false)

		posicao_jogador = (
			alvo.global_position
			+ alvo.velocity * distancia_previsao
		)

		match tipo:
			TipoTentaculo.ESMAGAMENTO:
				criar_marcador()
			TipoTentaculo.RAIO:
				criar_marcador_raio()

		var arvore := get_tree()
		if arvore == null:
			return

		await arvore.create_timer(tempo_preparacao, false).timeout

		if foi_derrotado or not is_inside_tree():
			return

		estado_atual = Estado.ATACANDO
		atualizar_colisoes(true, false)

		match tipo:
			TipoTentaculo.ESMAGAMENTO:
				await executar_esmagamento()
			TipoTentaculo.ROCHA:
				executar_rocha()
			TipoTentaculo.RAIO:
				await executar_raio()
			TipoTentaculo.BARRAGEM:
				pass

		if foi_derrotado or not is_inside_tree():
			return

		remover_marcador()

		estado_atual = Estado.RECUPERANDO
		atualizar_colisoes(true, true)

		await get_tree().create_timer(
			tempo_recuperacao, false
		).timeout

		if foi_derrotado or not is_inside_tree():
			return

		estado_atual = Estado.MERGULHANDO
		atualizar_colisoes(false, false)
		velocity = Vector2.ZERO

		await get_tree().create_timer(
			tempo_submerso, false
		).timeout


# TEMPORÁRIO: será conectado a LimitesTentaculos.

func escolher_posicao_ataque() -> Vector2:
	var limites := obter_limites_arena()
	var margem := 60.0

	var x_min := limites.position.x + margem
	var y_min := limites.position.y + margem
	var x_max := limites.end.x - margem
	var y_max := limites.end.y - margem

	if tipo == TipoTentaculo.ROCHA:
		return Vector2(
			randf_range(x_min, x_max),
			randf_range(y_min, y_max)
		)

	posicao_jogador = alvo.global_position + alvo.velocity * distancia_previsao

	var angulo := randf_range(0.0, TAU)
	var direcao := Vector2.RIGHT.rotated(angulo)
	var destino := posicao_jogador + direcao * distancia_emergencia

	destino.x = clampf(destino.x, x_min, x_max)
	destino.y = clampf(destino.y, y_min, y_max)

	return destino



# TEMPORÁRIO: será conectado a LimitesTentaculos.

func mover_submerso(destino: Vector2) -> void:
	var arvore := get_tree()
	if arvore == null or not is_inside_tree():
		return

	var limites := obter_limites_arena()
	var margem := 60.0

	destino.x = clampf(destino.x, limites.position.x + margem, limites.end.x - margem)
	destino.y = clampf(destino.y, limites.position.y + margem, limites.end.y - margem)

	while global_position.distance_to(destino) > 8.0:
		if foi_derrotado or not is_inside_tree():
			return

		while arvore.paused:
			await arvore.process_frame
			if foi_derrotado or not is_inside_tree():
				return

		var direcao := global_position.direction_to(destino)
		velocity = direcao * velocidade_submerso
		move_and_slide()

		await arvore.physics_frame

		if foi_derrotado or not is_inside_tree():
			return

	if is_inside_tree():
		velocity = Vector2.ZERO



func criar_marcador() -> void:
	remover_marcador()

	marcador = Line2D.new()
	marcador.width = 3.0
	marcador.default_color = Color(1.0, 0.15, 0.15, 0.9)
	marcador.closed = true
	marcador.z_index = 10

	var distancia := global_position.distance_to(posicao_jogador)
	var comprimento := maxf(distancia, 80.0)
	var metade := comprimento / 2.0
	var meia_largura := largura_marcador / 2.0

	marcador.add_point(Vector2(-metade, -meia_largura))
	marcador.add_point(Vector2(metade, -meia_largura))
	marcador.add_point(Vector2(metade, meia_largura))
	marcador.add_point(Vector2(-metade, meia_largura))

	get_parent().add_child(marcador)

	var direcao := global_position.direction_to(posicao_jogador)

	marcador.global_position = (
		global_position + posicao_jogador
	) / 2.0
	marcador.global_rotation = direcao.angle()

	var tween := marcador.create_tween()
	tween.set_loops()
	tween.tween_property(marcador, "width", 6.0, 0.25)
	tween.tween_property(marcador, "width", 2.0, 0.25)


func criar_marcador_raio() -> void:
	remover_marcador()

	var direcao := global_position.direction_to(posicao_jogador)

	if direcao == Vector2.ZERO:
		direcao = Vector2.RIGHT

	var inicio := global_position
	var fim := inicio + direcao * alcance_raio

	var consulta := PhysicsRayQueryParameters2D.create(inicio, fim)
	consulta.collision_mask = 1
	consulta.exclude = [alvo.get_rid(), get_rid()]

	var resultado := get_world_2d().direct_space_state.intersect_ray(
		consulta
	)

	if not resultado.is_empty():
		fim = resultado["position"]

	indicador_raio = Line2D.new()
	indicador_raio.width = largura_indicador_raio
	indicador_raio.default_color = Color(1.0, 0.15, 0.15, 0.9)
	indicador_raio.z_index = 10

	get_parent().add_child(indicador_raio)

	indicador_raio.points = PackedVector2Array([
		indicador_raio.to_local(inicio),
		indicador_raio.to_local(fim)
	])

	var tween := indicador_raio.create_tween()
	tween.set_loops()
	tween.tween_property(indicador_raio, "width", 4.0, 0.25)
	tween.tween_property(indicador_raio, "width", 1.0, 0.25)


func remover_marcador() -> void:
	if is_instance_valid(marcador):
		marcador.queue_free()
	marcador = null

	if is_instance_valid(indicador_raio):
		indicador_raio.queue_free()
	indicador_raio = null


func executar_esmagamento() -> void:
	var arvore := get_tree()

	if arvore == null or not is_inside_tree():
		return

	jogador_atingido = false

	var distancia_inicial := global_position.distance_to(
		posicao_jogador
	)

	var tempo_calculado := (
		distancia_inicial / maxf(velocidade_ataque, 1.0)
	) * 1.5 + 0.2

	var tempo_limite := maxf(tempo_ataque, tempo_calculado)
	var inicio := Time.get_ticks_msec()

	while (
		global_position.distance_to(posicao_jogador) > 12.0
		and (Time.get_ticks_msec() - inicio) < tempo_limite * 1000.0
	):
		if foi_derrotado or not is_inside_tree():
			return

		var direcao := global_position.direction_to(posicao_jogador)
		velocity = direcao * velocidade_ataque
		move_and_slide()
		verificar_dano_jogador()

		await arvore.physics_frame

		if foi_derrotado or not is_inside_tree():
			return

	if is_inside_tree():
		velocity = Vector2.ZERO
		verificar_dano_jogador()


func verificar_dano_jogador() -> void:
	if estado_atual != Estado.ATACANDO or jogador_atingido:
		return

	for corpo in $Area2D.get_overlapping_bodies():
		if corpo.is_in_group("player"):
			jogador_atingido = true
			corpo.death()
			return


func afundar() -> void:
	if foi_derrotado:
		return

	foi_derrotado = true
	estado_atual = Estado.DERROTADO
	atualizar_colisoes(false, false)
	velocity = Vector2.ZERO

	remover_marcador()
	queue_free()


func receber_impacto(bola) -> void:
	bola.rebater(-bola.direcao, 1000)

	if pode_receber_dano:
		afundar()


func atualizar_colisoes(
	fisica_ativa: bool,
	vulneravel: bool
) -> void:
	$CollisionShape2D.set_deferred("disabled", not fisica_ativa)
	$Area2D/CollisionShape2D.set_deferred("disabled", not fisica_ativa)

	pode_receber_dano = vulneravel


# TEMPORÁRIO: será conectado a LimitesTentaculos.

func executar_rocha() -> void:
	if foi_derrotado:
		return

	if projetil_rocha == null:
		push_warning("O tentáculo não tem ProjetilRocha configurado.")
		return

	var origem := global_position
	var direcao := origem.direction_to(posicao_jogador)

	var pedra = projetil_rocha.instantiate()
	get_parent().add_child(pedra)

	pedra.global_position = origem
	pedra.configurar(direcao)



func executar_raio() -> void:
	if cena_raio == null:
		push_warning("Configure a cena do raio em cena_raio!")
		return

	for i in range(quantidade_jatadas):
		if foi_derrotado or not is_inside_tree():
			remover_marcador()
			return

		if i > 0:
			posicao_jogador = (
				alvo.global_position
				+ alvo.velocity * distancia_previsao
			)

			criar_marcador_raio()

			var arvore := get_tree()
			if arvore == null:
				return

			await arvore.create_timer(
				aviso_entre_jatadas, false
			).timeout

			if foi_derrotado or not is_inside_tree():
				remover_marcador()
				return

		var direcao := global_position.direction_to(
			posicao_jogador
		)

		if direcao == Vector2.ZERO:
			direcao = Vector2.RIGHT

		remover_marcador()

		var raio = cena_raio.instantiate()
		get_parent().add_child(raio)

		var excluidos: Array[RID] = [
			alvo.get_rid(),
			get_rid()
		]

		raio.disparar(global_position, direcao, excluidos)

		var arvore := get_tree()
		if arvore == null:
			return

		await arvore.create_timer(0.3, false).timeout

		if foi_derrotado or not is_inside_tree():
			remover_marcador()
			return

		if i < quantidade_jatadas - 1:
			await arvore.create_timer(
				intervalo_jatadas, false
			).timeout

	remover_marcador()


func esperar_se_despausar() -> void:
	while is_inside_tree():
		var arvore := get_tree()

		if arvore == null or not arvore.paused:
			return

		await arvore.process_frame


func obter_limites_arena() -> Rect2:
	var forma := limites_tentaculos.get_node("CollisionShape2D").shape as RectangleShape2D
	var transformacao: Transform2D = limites_tentaculos.get_node("CollisionShape2D").global_transform
	var metade := forma.size / 2.0

	var extensao := Vector2(
		abs(transformacao.x.x) * metade.x + abs(transformacao.y.x) * metade.y,
		abs(transformacao.x.y) * metade.x + abs(transformacao.y.y) * metade.y
	)

	var centro: Vector2 = limites_tentaculos.get_node("CollisionShape2D").global_position

	return Rect2(centro - extensao, extensao * 2.0)
