extends CharacterBody2D

@onready var rastro = get_parent().get_node("RastroBoss")
@onready var target = get_parent().get_node("Player")
@onready var cooldown = $Timer
@onready var PartImpc = $ParticulasImpacto
@onready var deathtime = $Timer2

@export var Projetil : PackedScene

var pontos_rastro: Array[Vector2] = []

var count = 3
var count2 = 0

var dead = false
var vida = 5
var attacking = false
var direcao = Vector2(1, 1).normalized()

var velocidade = 300.0
var desaceleracao = 100.0

func _ready() -> void:
	cooldown.start()

func _physics_process(delta: float) -> void:
	if !dead:
		
		if vida >= 5:
			vida = 5
		
		velocidade = move_toward(velocidade, 0, desaceleracao * delta)

		velocity = direcao * velocidade
		
		move_and_slide()
		
		if get_slide_collision_count() > 0:
			var colisao = get_slide_collision(0)
			var normal = colisao.get_normal()
			var objeto = colisao.get_collider()
			
			
			direcao = direcao.bounce(normal)
		
		if vida <= 0:
			death()
		
func rebater(nova_direcao: Vector2, nova_forca: float):
	direcao = nova_direcao.normalized()
	velocidade = nova_forca

func attack():
	var direction = global_position.direction_to(target.global_position)
	direcao = direction
	velocidade = 500.0
	cooldown.start()
	count2 = count
	
func shooting():
	if count2 <= 0:
		attack()
	else:
		var projetil = Projetil.instantiate()
		get_parent().add_child(projetil)
		projetil.global_position = global_position
		var direcao = global_position.direction_to(target.global_position)
		projetil.direcao = direcao
		count2 -= 1

func _on_timer_timeout() -> void:
	shooting()

	
func atualizar_rastro():
	pontos_rastro.push_front(global_position)

	if pontos_rastro.size() > 20:
		pontos_rastro.pop_back()

	rastro.points = pontos_rastro

func death():
	deathtime.start()
	dead = true
	cooldown.stop()
	PartImpc.emitting = true
	
func _on_timer_2_timeout() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.death()
