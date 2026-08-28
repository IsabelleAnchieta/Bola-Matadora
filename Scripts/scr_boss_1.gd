extends CharacterBody2D

@onready var rastro = get_parent().get_node("RastroBoss")
@onready var target = get_parent().get_node("Player")
@onready var cooldown = $Timer
@onready var PartImpc = $ParticulasImpacto
@onready var deathtime = $Timer2

var pontos_rastro: Array[Vector2] = []

var dead = false
var vida = 10
var attacking = false
var direcao = Vector2(1, 1).normalized()

var velocidade = 300.0
var desaceleracao = 100.0

func _ready() -> void:
	cooldown.start()

func _physics_process(delta: float) -> void:
	if !dead:
		velocidade = move_toward(velocidade, 0, desaceleracao * delta)

		velocity = direcao * velocidade
		
		move_and_slide()
		
		if attacking:
			atualizar_rastro()
		else:
			rastro.clear_points()
		
		if get_slide_collision_count() > 0:
			var colisao = get_slide_collision(0)
			var normal = colisao.get_normal()
			var objeto = colisao.get_collider()

			if objeto.is_in_group("paredes"):
				attacking = false
			
			direcao = direcao.bounce(normal)
		
		if vida <= 0:
			death()
		
func rebater(nova_direcao: Vector2, nova_forca: float):
	direcao = nova_direcao.normalized()
	velocidade = nova_forca

func attack():
	var direction = global_position.direction_to(target.global_position)
	direcao = direction
	velocidade = 1000.0
	cooldown.start()

func _on_timer_timeout() -> void:
	attack()
	attacking = true
	
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
