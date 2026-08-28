extends CharacterBody2D

@export var Shoot : PackedScene

@onready var Mira = $Taco/Mirando/Mira
@onready var Cooldown = $Timer_Load
@onready var WaitDash = $Timer_Dash
@onready var CoolDash = $Timer_Dash2
@onready var Camera = $Camera2D
@onready var PartImpc = $Taco/ParticulasImpacto

#Tudo que envolve Bater na Bola
var atacando = false
var mouse_anterior: Vector2
var velocidade_mouse: float
var recarregando = false
var attack_direction : Vector2


#Tudo que envolve dash
var Dashing = false
var RecarregarDash = false

var dead = false

var SPEED = 400.0


func _physics_process(delta: float) -> void:
	
	if Dashing:
		SPEED = 700.0
	elif recarregando:
		SPEED = 200.0
	else:
		SPEED = 400.0

	var mousepos = get_global_mouse_position()
	var look = global_position.direction_to(mousepos)
	var direction := Input.get_axis("Esquerda", "Direita")
	
	#MOVIMENTAÇÃO DO PERSONAGEM:
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	var v_direction := Input.get_axis("Cima", "Baixo")
	if v_direction:
		velocity.y = v_direction * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
#PARA O TACO
	var mouse_atual = get_global_mouse_position()
	
	velocidade_mouse = mouse_atual.distance_to(mouse_anterior) / delta
	mouse_anterior = mouse_atual


	if mousepos != null && Mira != null:
		Mira.global_position = global_position + look * 40
		Mira.look_at(mousepos)
		
	if Input.is_action_just_pressed("Atirar"):
		shooting()
	
	if Input.is_action_just_pressed("Dash"):
		dash()
	
	
	move_and_slide()


#Função para atirar
func shooting():
	if !recarregando:
		Camera.efeito_ataque(1.28)
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
		var forca = clamp(velocidade_mouse * 0.1, 300.0, 1200.0)
		var attack_direction = global_position.direction_to(get_global_mouse_position())
		Camera.impacto(forca)
		body.rebater(attack_direction, forca)
		atacando = false
		body.posse = true
		PartImpc.emitting = true
		
		

func _on_mirando_body_exited(body: Node2D) -> void:
	if body.is_in_group("bola") and PartImpc.emitting:
		PartImpc.emitting = false

func death():
	dead = true
