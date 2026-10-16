extends CharacterBody2D

const CENA_DASH_GHOST: PackedScene = preload("res://Objetos/obj_dash_ghost.tscn")

@export var numeros_voadores: PackedScene
@export var intervalo_ghost: float = 0.035

@onready var Mira = $Taco/Mirando/Mira
@onready var Cooldown = $Timer_Load
@onready var WaitDash = $Timer_Dash
@onready var CoolDash = $Timer_Dash2
@onready var Camera = $Camera2D
@onready var PartImpc = $Taco/ParticulasImpacto
@onready var Taco = $Taco
@onready var SoundEffect = $MakeSomeSound
@onready var SoundBase = $BaseBoll
@onready var MA = get_parent().get_node("MA")
@onready var animation = $Forma/Sprite2D/AnimatedSprite2D
@onready var animbatuta = $Taco/Mirando/Mira/Sprite2D/AnimatedSprite2D


enum Animacao {
	IDLE,
	WALK,
	ATTACK,
	PARRY,
	DASH,
	DEATH
}

var estado_atual: Animacao = Animacao.IDLE


#Tudo que envolve Bater na Bola
var atacando = false
var mouse_anterior: Vector2
var velocidade_mouse: float
var recarregando = false
var mira_anterior: Vector2
var tempo_particula = 0.0
var movimento_mouse: Vector2

var pancada_acertou_bola: bool = false
var pancada_em_andamento: bool = false


#Tudo que envolve dash
var Dashing = false
var RecarregarDash = false
var cronometro_ghost: float = 0.0

var dead = false
var verdead = false

#Parry
var parrying = false
var tempo_parry = 0.0
var duracao_parry = 0.15
var recuperacao_parry = 0.0
var tempo_rec_parry = 1
var pseudo_tempo = true
var efeito_parry_ativo: bool = false

var SPEED = 400.0

#Para mexer na bola sem o taco
var withball = false

#Var pra som
var Ramdomizer

func _physics_process(delta: float) -> void:
	
	if tempo_particula > 0:
		tempo_particula -= delta
		if tempo_particula <= 0:
			PartImpc.emitting = false

	var mousepos = get_global_mouse_position()
	var look = global_position.direction_to(mousepos)
	var direcao_camera = global_position.direction_to(mousepos)
	Camera.position = Camera.position.lerp(direcao_camera * 150, 5.0 * delta)
	
#MOVIMENTACAO DO PERSONAGEM
	
	var direction := Input.get_axis("Esquerda", "Direita")
	var v_direction := Input.get_axis("Cima", "Baixo")

	var direcao_movimento = Vector2(direction, v_direction).normalized()

	if direcao_movimento != Vector2.ZERO and !verdead:
		velocity = direcao_movimento * SPEED
	else:
		velocity = Vector2.ZERO
	
	var direcao_input = Vector2(direction, v_direction).normalized()

#Para o Parry
	if parrying:
		pseudo_tempo = true
		tempo_parry -= delta

	if tempo_parry <= 0:
		parrying = false
		set_collision_layer_value(1, true)
		if pseudo_tempo == true:
			recuperacao_parry = tempo_rec_parry
			pseudo_tempo = false
	
	if !parrying:
		recuperacao_parry -= delta
		if recuperacao_parry <= 0:
			recuperacao_parry = 0


#PARA O TACO
	var mouse_atual = get_global_mouse_position()



	movimento_mouse = mouse_atual - mouse_anterior

	velocidade_mouse = movimento_mouse.length() / delta

	mouse_anterior = mouse_atual

	if mousepos != null && Mira != null:
		mira_anterior = Mira.global_position
		
		Mira.global_position = global_position + look * 40
		if !parrying:
			$Forma/Sprite2D.rotation = Mira.rotation
		Mira.look_at(mousepos)
		
		
	if parrying:
		Mira.global_position = global_position + look * 20
		Mira.global_rotation = Mira.global_rotation + PI / 2
		
		verificar_trajetoria_taco()
		
	if Input.is_action_just_pressed("Atirar"):
		shooting()
	
	if Input.is_action_just_pressed("Dash"):
		dash()
	
	if Input.is_action_just_pressed("Parry"):
		parry()
		set_collision_layer_value(1, false)

	atualizar_estado_animacao()

	if Dashing:
		cronometro_ghost -= delta

		if cronometro_ghost <= 0.0:
			criar_dash_ghost()
			cronometro_ghost = intervalo_ghost

	move_and_slide()
	
	if Dashing:
		SPEED = 1000.0
	elif recarregando:
		SPEED = 200.0
	else:
		SPEED = 400.0
	if withball:
		SPEED = SPEED/2
	
	empurrar_bola(direcao_input)


#Função para atirar
func shooting():
	if !recarregando:
		Ramdomizer = randf_range(1, 2)
		SoundEffect.pitch_scale = Ramdomizer
		SoundEffect.play()
		Camera.efeito_ataque(Camera.zoom_ataque)
		atacando = true
		
		pancada_acertou_bola = false
		pancada_em_andamento = true
		
		recarregando = true
		Cooldown.start()
		
#Função de recarregar:
func _on_timer_timeout() -> void:
	recarregando = false
	atacando = false

	if pancada_em_andamento:
		if not pancada_acertou_bola:
			mostrar_texto_pancada("???")

		pancada_em_andamento = false


func dash():
	if !RecarregarDash:
		cronometro_ghost = 0.0
		Dashing = true
		RecarregarDash = true
		WaitDash.start()
		CoolDash.start()

func _on_timer_dash_timeout() -> void:
	Dashing = false


func _on_timer_dash_2_timeout() -> void:
	RecarregarDash = false


func _on_mirando_body_entered(body: Node2D) -> void:
	if body.is_in_group("bola") and atacando:
		Ramdomizer = randf_range(1, 2)
		SoundBase.pitch_scale = Run.multiplicador
		SoundBase.play()
		var forca = clamp(velocidade_mouse * 0.1, 0.0, 2000.0)
		var attack_direction = movimento_mouse.normalized()
		Run.multiplicar(0.1)
		aplicar_hitstop(forca)
		body.iniciar_ghost_trail()

		if body.efeito_pancada != null:
			var efeito = body.efeito_pancada.instantiate()
			get_tree().current_scene.add_child(efeito)
			efeito.global_position = body.global_position
		Camera.impacto(forca)
		body.rebater(attack_direction, forca)
		body.efeito_impacto_shader()
		atacando = false
		pancada_acertou_bola = true
		mostrar_texto_pancada(avaliar_pancada(forca))
		body.posse = true
		PartImpc.emitting = true
		
	if body.has_method("receber_parry") and parrying:
		body.receber_parry()
		efeito_visual_parry()
		$Stop.play()
		
	if body.is_in_group("boss") and parrying:
		$Stop.play()
		MA.play()
		body.receber_parry()
		efeito_visual_parry()
		parrying = false


func _on_mirando_body_exited(body: Node2D) -> void:
	if body.is_in_group("bola") and PartImpc.emitting:
		PartImpc.emitting = false

func death():
	verdead = true


func verificar_trajetoria_taco() -> void:
	if !atacando:
		return

	var distancia = mira_anterior.distance_to(Mira.global_position)
	var passos = max(1, int(distancia / 5.0))

	for i in range(1, passos + 1):
		var progresso = float(i) / passos
		var posicao = mira_anterior.lerp(Mira.global_position, progresso)

		for bola in get_tree().get_nodes_in_group("bola"):
			var distancia_bola = posicao.distance_to(bola.global_position)

			if distancia_bola <= 30.0:
				var forca = clamp(velocidade_mouse * 0.1, 0.0, 2000.0)
				var attack_direction = movimento_mouse.normalized()

				Run.multiplicar(0.1)
				Camera.impacto(forca)
				aplicar_hitstop(forca)
				bola.rebater(attack_direction, forca)
				bola.iniciar_ghost_trail()

				if bola.efeito_pancada != null:
					var efeito = bola.efeito_pancada.instantiate()
					get_tree().current_scene.add_child(efeito)
					efeito.global_position = bola.global_position
				
				atacando = false
				pancada_acertou_bola = true
				mostrar_texto_pancada(avaliar_pancada(forca))
				bola.posse = true
				PartImpc.emitting = true
				tempo_particula = 0.1


func empurrar_bola(direcao_input: Vector2):
	if atacando or SPEED > 400:
		withball = false
		return

	if direcao_input == Vector2.ZERO:
		withball = false
		return

	for bola in get_tree().get_nodes_in_group("bola"):
		if !is_instance_valid(bola):
			continue

		var distancia = global_position.distance_to(bola.global_position)
		
		if distancia < 15.0 and bola.posse:
			withball = true
			bola.withplayer = true
			bola.direcao = direcao_input
			bola.velocidade = SPEED
		else:
			withball = false
			bola.withplayer = false

func parry():
	if parrying:
		return
	
	if recuperacao_parry <= 0:
		parrying = true
		tempo_parry = duracao_parry


func _on_mirando_area_shape_entered(
	area_rid: RID,
	area: Area2D,
	area_shape_index: int,
	local_shape_index: int
) -> void:
	if not parrying:
		return

	if area.has_method("receber_parry"):
		area.receber_parry()
		$Stop.play()
		efeito_visual_parry()


func mudar_estado(novo_estado: Animacao) -> void:
	if estado_atual == novo_estado:
		return

	estado_atual = novo_estado
	atualizar_sprite()


func atualizar_sprite() -> void:
	var nome_animacao: String

	match estado_atual:
		Animacao.IDLE:
			nome_animacao = "idle"

		Animacao.WALK:
			nome_animacao = "walking"

		Animacao.ATTACK:
			nome_animacao = "attack"

		Animacao.PARRY:
			nome_animacao = "parry"

		Animacao.DASH:
			nome_animacao = "dash"

		Animacao.DEATH:
			nome_animacao = "death"

	if animation.sprite_frames.has_animation(nome_animacao):
		if animation.animation != nome_animacao or not animation.is_playing():
			animation.play(nome_animacao)
			if animbatuta.sprite_frames.has_animation(nome_animacao):
				animbatuta.play(nome_animacao)
			else:
				animbatuta.play("idle")


func atualizar_estado_animacao() -> void:
	var novo_estado: Animacao

	if verdead:
		novo_estado = Animacao.DEATH
	elif parrying:
		novo_estado = Animacao.PARRY
	elif atacando:
		novo_estado = Animacao.ATTACK
	elif Dashing:
		novo_estado = Animacao.DASH
	elif velocity.length_squared() > 0.0:
		novo_estado = Animacao.WALK
	else:
		novo_estado = Animacao.IDLE

	mudar_estado(novo_estado)



func _on_animated_sprite_2d_animation_finished() -> void:
	if verdead:
		dead = true



func criar_dash_ghost() -> void:
	var personagem := $Forma/Sprite2D/AnimatedSprite2D as AnimatedSprite2D

	if personagem == null or personagem.sprite_frames == null:
		return

	var fantasma = CENA_DASH_GHOST.instantiate()
	get_tree().current_scene.add_child(fantasma)

	var textura := personagem.sprite_frames.get_frame_texture(
		personagem.animation,
		personagem.frame
	)

	fantasma.configurar(
		textura,
		0,
		1,
		1,
		personagem.global_position,
		personagem.global_scale,
		personagem.global_rotation,
		personagem.flip_h,
		personagem.flip_v
	)


func efeito_visual_parry() -> void:
	if efeito_parry_ativo:
		return

	efeito_parry_ativo = true

	var zoom_original: Vector2 = Camera.zoom
	var escala_tempo_original: float = Engine.time_scale

	# Desacelera o jogo.
	Engine.time_scale = 0.35

	# Aproxima a câmera.
	var entrada := create_tween()
	entrada.set_ignore_time_scale(true)
	entrada.tween_property(
		Camera,
		"zoom",
		zoom_original * 1.2,
		0.12
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Mantém o efeito pelo tempo desejado.
	await get_tree().create_timer(
		0.5, true, false, true
	).timeout

	# Volta ao zoom original.
	var saida := create_tween()
	saida.set_ignore_time_scale(true)
	saida.tween_property(
		Camera,
		"zoom",
		zoom_original,
		0.18
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await saida.finished

	Engine.time_scale = escala_tempo_original
	efeito_parry_ativo = false


func avaliar_pancada(forca: float) -> String:
	if forca < 500.0:
		return "Meh"
	elif forca < 1300.0:
		return "Great!"
	else:
		return "PERFECT!"


func mostrar_texto_pancada(mensagem: String) -> void:
	var texto = numeros_voadores.instantiate()
	get_tree().current_scene.add_child(texto)
	texto.global_position = global_position
	texto.mostrar_pontos(mensagem)



func aplicar_hitstop(forca: float) -> void:
	var duracao: float

	if forca < 500.0:
		duracao = 0.025 # Meh
	elif forca < 1300.0:
		duracao = 0.07 # Great!
	else:
		duracao = 0.1 # PERFECT!

	var escala_anterior := Engine.time_scale
	Engine.time_scale = 0.05

	await get_tree().create_timer(
		duracao,
		true,
		false,
		true
	).timeout

	Engine.time_scale = escala_anterior
