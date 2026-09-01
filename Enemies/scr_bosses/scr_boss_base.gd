extends CharacterBody2D

@onready var rastro: Line2D = $RastroBoss
@onready var target = get_parent().get_node("Player")
@onready var vida_boss = get_parent().get_node("CanvasLayer/VidaBoss")
@onready var cooldown = $Timer
@onready var PartImpc = $ParticulasImpacto
@onready var deathtime = $Timer2

var pontos_rastro: Array[Vector2] = []
var posicao_anterior: Vector2

var dead = false
@export var vida = 5
var attacking = false
var direcao = Vector2(1, 1).normalized()

var velocidade = 300.0
var desaceleracao = 100.0


func _ready() -> void:
	posicao_anterior = global_position
	cooldown.start()


func _physics_process(delta: float) -> void:
	if !dead:
		processar_movimento(delta)
		processar_rastro()
		processar_colisao()
		
		if vida <= 0:
			death()


func processar_movimento(delta: float) -> void:
	velocidade = move_toward(velocidade, 0, desaceleracao * delta)

	velocity = direcao * velocidade

	move_and_slide()


func processar_rastro() -> void:
	if attacking:
		atualizar_rastro()
	else:
		rastro.clear_points()
		pontos_rastro.clear()
		posicao_anterior = global_position


func processar_colisao() -> void:
	if get_slide_collision_count() > 0:
		var colisao = get_slide_collision(0)
		var normal = colisao.get_normal()
		var objeto = colisao.get_collider()

		if objeto.is_in_group("paredes"):
			quando_bater_na_parede(objeto)

		direcao = direcao.bounce(normal)


func quando_bater_na_parede(objeto) -> void:
	attacking = false


func rebater(nova_direcao: Vector2, nova_forca: float) -> void:
	direcao = nova_direcao.normalized()
	velocidade = nova_forca


func attack() -> void:
	var direction = global_position.direction_to(target.global_position)

	direcao = direction
	velocidade = 1000.0
	cooldown.start()


func _on_timer_timeout() -> void:
	attack()
	attacking = true


func atualizar_rastro() -> void:
	var movimento = posicao_anterior - global_position

	for i in range(pontos_rastro.size()):
		pontos_rastro[i] += movimento

	pontos_rastro.push_front(Vector2.ZERO)

	if pontos_rastro.size() > 20:
		pontos_rastro.pop_back()

	rastro.points = pontos_rastro

	posicao_anterior = global_position


func death() -> void:
	deathtime.start()
	dead = true
	cooldown.stop()
	PartImpc.emitting = true
	
	rastro.clear_points()
	pontos_rastro.clear()


func _on_timer_2_timeout() -> void:
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.death()


func receber_impacto(bola) -> void:
	if !attacking and bola.posse:
		rebater(bola.direcao, bola.velocidade)

		bola.rebater(bola.direcao, bola.velocidade)

		vida -= bola.dano
		vida_boss.atualizar_vida(vida)
		cooldown.start()

	else:
		bola.rebater(bola.direcao, velocidade)
		bola.posse = false
		attacking = false
