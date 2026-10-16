
extends CharacterBody2D

@onready var limites_tentaculos: Area2D = get_parent().get_node("LimitesTentaculos")
@onready var anim = $AnimatedSprite2D
@onready var material_flash: ShaderMaterial = anim.material
@onready var sombra = $Sombra

enum Estado {
	SUBMERSO,
	PREPARANDO,
	ATACANDO,
	RECUANDO,
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

# Partículas
@onready var particulas_rocha : GPUParticles2D = $ParticulasRocha
@onready var particulas_raio: GPUParticles2D = $ParticulasRaio
@onready var particulas_submerso: GPUParticles2D = $ParticulasSubmerso


# Ataques
@export var projetil_rocha: PackedScene
@export var cena_raio: PackedScene
@export var numeros_voadores: PackedScene
@export var velocidade_rotacao: float = 8.0
@export var forca_empurrao: float = 35.0


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
var posicao_barragem: Vector2
var posicao_jogador: Vector2

var marcador: Line2D
var indicador_raio: Line2D
var onda_barragem: Line2D
var jogador_atingido_barragem: bool = false

var rotacao_inicial : float
var rotacao_inicial_sprite: float
var escala_inicial_sprite: Vector2

var empurrao_ativo: bool = false

func _ready() -> void:
	alvo = get_parent().get_node("Player")
	escala_inicial_sprite = anim.scale
	rotacao_inicial = rotation
	rotacao_inicial_sprite = anim.rotation
	iniciar_ciclo()

func _process(delta: float) -> void:
	atualizar_animacao_tentaculo()
	
	if (
		estado_atual == Estado.PREPARANDO
		or estado_atual == Estado.RECUPERANDO
	):
		rotation = rotacao_inicial
		return

	if not is_instance_valid(alvo):
		return

	# Nessas animações, o tentáculo mantém a orientação atual.
	if (
		estado_atual == Estado.PREPARANDO
		or estado_atual == Estado.RECUANDO
		or estado_atual == Estado.RECUPERANDO
	):
		rotation = rotacao_inicial
		return

	var direcao_desejada: Vector2

	if estado_atual == Estado.ATACANDO:
		if tipo == TipoTentaculo.RAIO:
			direcao_desejada = global_position.direction_to(
				posicao_jogador
			)
		else:
			direcao_desejada = global_position.direction_to(
				alvo.global_position
			)

	if direcao_desejada != Vector2.ZERO:
		var angulo_desejado = direcao_desejada.angle()
		rotation = rotate_toward(
			rotation,
			angulo_desejado,
			velocidade_rotacao * delta
		)

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

		if tipo == TipoTentaculo.BARRAGEM:
			posicao_barragem = global_position

		match tipo:
			TipoTentaculo.ESMAGAMENTO:
				criar_marcador()
			TipoTentaculo.RAIO:
				criar_marcador_raio()
			TipoTentaculo.BARRAGEM:
				criar_marcador_barragem()

		var arvore := get_tree()
		if arvore == null:
			return

		await arvore.create_timer(tempo_preparacao, false).timeout

		if foi_derrotado or not is_inside_tree():
			return

		estado_atual = Estado.ATACANDO
		atualizar_colisoes(true, false)
		remover_marcador()

		match tipo:
			TipoTentaculo.ESMAGAMENTO:
				await executar_esmagamento()
			TipoTentaculo.ROCHA:
				await olhar_para_jogador()
				await executar_rocha()
				await get_tree().create_timer(0.5).timeout
			TipoTentaculo.RAIO:
				await executar_raio()

			TipoTentaculo.BARRAGEM:
				for i in range(5):
					if foi_derrotado or not is_inside_tree():
						return

					if i > 0:
						posicao_barragem = escolher_posicao_ataque()
						criar_marcador_barragem()

						await get_tree().create_timer(
							aviso_entre_jatadas, false
						).timeout

						if foi_derrotado or not is_inside_tree():
							return

						remover_marcador()

					jogador_atingido_barragem = false

					await executar_barragem()

					if foi_derrotado or not is_inside_tree():
						return

					await criar_onda_barragem()


		if foi_derrotado or not is_inside_tree():
			return

		remover_marcador()
		
		estado_atual = Estado.RECUANDO
		atualizar_animacao_tentaculo()
		atualizar_colisoes(true, false)

		await anim.animation_finished

		if foi_derrotado or not is_inside_tree():
			return

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


	if tipo == TipoTentaculo.ROCHA or tipo == TipoTentaculo.BARRAGEM:
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
		

		for i in get_slide_collision_count():
			var colisao = get_slide_collision(i)
			var corpo = colisao.get_collider()

			if corpo.is_in_group("ParedeQ"):
				corpo.queue_free()


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
	indicador_raio.z_index = -1

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
	mostrar_onomatopeia_ataque()
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
		rotation = direcao.angle()
		velocity = direcao * velocidade_ataque
		move_and_slide()
		
		for i in get_slide_collision_count():
			var colisao = get_slide_collision(i)
			var corpo = colisao.get_collider()

			if corpo.is_in_group("ParedeQ"):
				corpo.queue_free()
		
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
	efeito_impacto_shader()
	aplicar_empurrao(bola)
	bola.rebater(-bola.direcao, 1000)

	if estado_atual == Estado.ATACANDO:
		bola.posse = false

	if numeros_voadores != null and bola.posse == true:
		var efeito = numeros_voadores.instantiate()
		get_parent().add_child(efeito)
		efeito.global_position = global_position

		efeito.mostrar_pontos(Run.pontuar(bola.pontos))
		Run.multiplicar(0.1)
		

	if pode_receber_dano and bola.posse:
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

	particulas_rocha.emitting = true
	mostrar_onomatopeia_ataque()
	await get_tree().create_timer(0.3).timeout
	particulas_rocha.emitting = false



func executar_raio() -> void:
	if cena_raio == null:
		push_warning("Configure a cena do raio em cena_raio!")
		return



	for i in range(quantidade_jatadas):
		
		if foi_derrotado or not is_inside_tree():
			remover_marcador()
			return

		if i > 0:
			var direcao := global_position.direction_to(
				posicao_jogador
			)
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
		particulas_raio.emitting = true

		var raio = cena_raio.instantiate()
		get_parent().add_child(raio)
		mostrar_onomatopeia_ataque()

		var excluidos: Array[RID] = [
			alvo.get_rid(),
			get_rid()
		]

		raio.disparar(global_position, direcao, excluidos)

		var arvore := get_tree()
		if arvore == null:
			return

		await arvore.create_timer(0.3, false).timeout
		
		particulas_raio.emitting = false

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



func criar_marcador_barragem() -> void:
	remover_marcador()

	marcador = Line2D.new()
	marcador.name = "MarcadorBarragem"
	marcador.width = 3.0
	marcador.default_color = Color(0.2, 0.75, 1.0, 0.9)
	marcador.closed = true
	marcador.z_index = 10

	var raio := 70.0
	var segmentos := 48

	for i in range(segmentos):
		var angulo := TAU * float(i) / float(segmentos)
		marcador.add_point(
			Vector2(cos(angulo), sin(angulo)) * raio
		)

	get_parent().add_child(marcador)
	marcador.global_position = posicao_barragem

	var tween := marcador.create_tween()
	tween.set_loops()
	tween.tween_property(marcador, "width", 6.0, 0.25)
	tween.tween_property(marcador, "width", 2.0, 0.25)




func executar_barragem() -> void:
	var arvore := get_tree()

	if arvore == null or not is_inside_tree() or foi_derrotado:
		return

	jogador_atingido = false

	# O tentáculo fica submerso durante a viagem.
	atualizar_colisoes(false, false)

	while global_position.distance_to(posicao_barragem) > 12.0:
		if foi_derrotado or not is_inside_tree():
			return

		while arvore.paused:
			await arvore.process_frame

			if foi_derrotado or not is_inside_tree():
				return

		var direcao := global_position.direction_to(posicao_barragem)
		velocity = direcao * velocidade_ataque
		move_and_slide()

		for i in get_slide_collision_count():
			var colisao = get_slide_collision(i)
			var corpo = colisao.get_collider()

			if corpo.is_in_group("ParedeQ"):
				corpo.queue_free()

		await arvore.physics_frame

		if foi_derrotado or not is_inside_tree():
			return

	velocity = Vector2.ZERO

	# O tentáculo emerge ao chegar ao ponto de impacto.
	atualizar_colisoes(true, false)



func criar_onda_barragem() -> void:
	var arvore := get_tree()
	if arvore == null or not is_inside_tree():
		return

	onda_barragem = Line2D.new()
	onda_barragem.name = "OndaBarragem"
	onda_barragem.width = 8.0
	onda_barragem.default_color = Color(0.2, 0.75, 1.0, 0.9)
	onda_barragem.closed = true
	onda_barragem.z_index = 11

	var segmentos := 64
	for i in range(segmentos):
		var angulo := TAU * float(i) / float(segmentos)
		onda_barragem.add_point(Vector2(cos(angulo), sin(angulo)) * 5.0)

	get_parent().add_child(onda_barragem)
	mostrar_onomatopeia_ataque()
	onda_barragem.global_position = posicao_barragem

	var duracao := 0.7
	var raio_maximo := 220.0


	var tween := onda_barragem.create_tween()

	tween.tween_method(
		func(raio: float) -> void:
			if not is_instance_valid(onda_barragem):
				return

			for i in range(segmentos):
				var angulo := TAU * float(i) / float(segmentos)
				var ponto := Vector2(cos(angulo), sin(angulo)) * raio
				onda_barragem.set_point_position(i, ponto)

			verificar_impacto_onda(raio),
		5.0,
		raio_maximo,
		duracao
	)


	tween.parallel().tween_property(
		onda_barragem,
		"modulate:a",
		0.0,
		duracao
	)

	await tween.finished

	if is_instance_valid(onda_barragem):
		onda_barragem.queue_free()

	onda_barragem = null



func verificar_impacto_onda(raio_atual: float) -> void:
	if jogador_atingido_barragem:
		return

	if not is_instance_valid(alvo):
		return

	var distancia := posicao_barragem.distance_to(alvo.global_position)

	if distancia <= raio_atual:
		jogador_atingido_barragem = true
		alvo.death()


func atualizar_animacao_tentaculo() -> void:
	var nome_estado: String
	var tipagem: int
	
	match tipo:
		TipoTentaculo.ROCHA:
			tipagem = 1
		TipoTentaculo.ESMAGAMENTO:
			tipagem = 2
		TipoTentaculo.RAIO:
			tipagem = 3
		TipoTentaculo.BARRAGEM:
			tipagem = 4

	match estado_atual:
		Estado.SUBMERSO:
			nome_estado = "submerge"
		Estado.PREPARANDO:
			nome_estado = "idle"
		Estado.ATACANDO:
			nome_estado = "atq"
		Estado.RECUANDO:
			nome_estado = "idle_reverse"
		Estado.RECUPERANDO:
			nome_estado = "vul"
		Estado.MERGULHANDO:
			nome_estado = "submerge"
		Estado.DERROTADO:
			nome_estado = "hurt"

	var nome_animacao = nome_estado
	
	if estado_atual == Estado.ATACANDO:
		anim.rotation = rotacao_inicial_sprite - deg_to_rad(90)
		anim.scale = Vector2(4.0, 5.0)
	else:
		anim.rotation = rotacao_inicial_sprite
		anim.scale = escala_inicial_sprite
	
	if estado_atual == Estado.RECUPERANDO or estado_atual == Estado.PREPARANDO or estado_atual == Estado.RECUANDO:
		sombra.visible = true
	else:
		sombra.visible = false
	
	atualizar_particulas()

	if nome_estado != "hurt" and nome_estado != "submerge":
		nome_animacao += "_" + str(tipagem)

	if anim.animation != nome_animacao:
		anim.play(nome_animacao)
		

func atualizar_particulas() -> void:
	particulas_rocha.emitting = (
		tipo == TipoTentaculo.ROCHA
		and estado_atual == Estado.ATACANDO
	)

	particulas_submerso.emitting = (
		estado_atual == Estado.SUBMERSO
		or estado_atual == Estado.MERGULHANDO
	)

func olhar_para_jogador() -> void:
	if not is_instance_valid(alvo):
		return

	var direcao := global_position.direction_to(
		alvo.global_position
	)
	var angulo_desejado := direcao.angle()

	while absf(angle_difference(rotation, angulo_desejado)) > 0.02:
		if not is_instance_valid(alvo):
			return

		direcao = global_position.direction_to(alvo.global_position)
		angulo_desejado = direcao.angle()

		rotation = rotate_toward(
			rotation,
			angulo_desejado,
			velocidade_rotacao * get_process_delta_time()
		)

		await get_tree().process_frame

func efeito_impacto_shader() -> void:
	var tween = create_tween()

	material_flash.set_shader_parameter("intensidade", 1.0)

	tween.tween_method(
		func(valor: float):
			material_flash.set_shader_parameter("intensidade", valor),
		1.0,
		0.0,
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func aplicar_empurrao(bola) -> void:
	var direcao_empurrao : = Vector2(
		global_position - bola.global_position
	).normalized()

	if direcao_empurrao == Vector2.ZERO:
		return

	var posicao_inicial := global_position
	var posicao_final := (
		posicao_inicial + direcao_empurrao * forca_empurrao
	)

	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		posicao_final,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)



func mostrar_onomatopeia_ataque() -> void:
	if numeros_voadores == null:
		return

	var palavras: Array[String]
	var cor: Color

	match tipo:
		TipoTentaculo.ROCHA:
			palavras = ["KRAK!", "THOOM!", "CRASH!", "BOOM!"]
			cor = Color("#FF79C6") # Rosa

		TipoTentaculo.ESMAGAMENTO:
			palavras = ["KTHOOM!", "BWAM!", "DOOM!", "THRAK!"]
			cor = Color("#FF4545") # Vermelho

		TipoTentaculo.RAIO:
			palavras = ["VZZRAK!", "KRAZZT!", "VRZZT!", "ZAP!"]
			cor = Color("dfd323ff") # Azul

		TipoTentaculo.BARRAGEM:
			palavras = ["VRASHH!", "FWOOSH!", "SHLAAAP!", "WHAM!"]
			cor = Color("#438CFF") # Azul

	var efeito = numeros_voadores.instantiate()
	get_parent().add_child(efeito)

	efeito.global_position = global_position
	efeito.mostrar_pontos(palavras.pick_random())
	efeito.add_theme_color_override("font_color", cor)
