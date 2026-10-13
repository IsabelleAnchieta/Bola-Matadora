extends CharacterBody2D

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

#Tudo que envolve Bater na Bola
var atacando = false
var mouse_anterior: Vector2
var velocidade_mouse: float
var recarregando = false
var mira_anterior: Vector2
var tempo_particula = 0.0
var movimento_mouse: Vector2

#Tudo que envolve dash
var Dashing = false
var RecarregarDash = false

var dead = false

#Parry
var parrying = false
var tempo_parry = 0.0
var duracao_parry = 0.15
var recuperacao_parry = 0.0
var tempo_rec_parry = 1
var pseudo_tempo = true

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

	if direcao_movimento != Vector2.ZERO:
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
		recarregando = true
		Cooldown.start()
		
#Função de recarregar:
func _on_timer_timeout() -> void:
	recarregando = false
	atacando = false

func dash():
	if !RecarregarDash:
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
		Camera.impacto(forca)
		body.rebater(attack_direction, forca)
		atacando = false
		body.posse = true
		body.Sprite.scale.x = 0.5
		#PARA CRIAR O EFEITO DE BOLA
		body.Luz = body.Light.instantiate()
		body.Luz.For = forca/100
		body.Luz.global_position = body.global_position
		body.get_parent().add_child(body.Luz)
		PartImpc.emitting = true
		
	if body.is_in_group("boss") and parrying:
		$Stop.play()
		MA.play()
		body.receber_parry()
		parrying = false


func _on_mirando_body_exited(body: Node2D) -> void:
	if body.is_in_group("bola") and PartImpc.emitting:
		PartImpc.emitting = false

func death():
	dead = true

func receber_impacto(bola):
	if bola.velocidade <= 0:
		bola.posse = true
	elif !bola.posse:
		death()

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
				bola.rebater(attack_direction, forca)
				atacando = false
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


func _on_mirando_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not parrying:
		return
	if area.has_method("receber_parry"):
		area.receber_parry()
		$Stop.play()
