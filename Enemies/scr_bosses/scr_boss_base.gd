extends CharacterBody2D

@export var numeros_voadores : PackedScene
@export var ID : String
@export var vida = 5
@export var Forca = 1000
@export var WaitForAttack = 3.0

@onready var rastro: Line2D = $RastroBoss
@onready var target = get_parent().get_node("Player")
@onready var vida_boss = get_parent().get_node("CanvasLayer/VidaBoss")
@onready var cooldown = $Timer
@onready var PartImpc = $ParticulasImpacto
@onready var deathtime = $Timer2

var pontos_rastro: Array[Vector2] = []
var posicao_anterior: Vector2

var dead = false
var attacking = false
var direcao = Vector2(1, 1).normalized()

var velocidade = 0
var dano = 5
var desaceleracao = 100.0

var avisar

func _ready() -> void:
	posicao_anterior = global_position
	avisar = get_parent()
	cooldown.start()
	cooldown.wait_time = WaitForAttack


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
	velocidade = Forca
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
	Run.derrotar_bosses(ID)
	
	deathtime.start()
	dead = true
	cooldown.stop()
	PartImpc.emitting = true
	
	rastro.clear_points()
	pontos_rastro.clear()


func _on_timer_2_timeout() -> void:
	vida_boss.queue_free()
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.death()
	if body.is_in_group("ParedeQ"):
		if attacking:
			body.receber_impacto(self)
	if body.is_in_group("bola"):
		receber_impacto(body)

func receber_impacto(bola) -> void:
	if bola.posse and !attacking:
		efeito_pancada(bola, 1000)
	elif bola.velocidade >= 1000:
		efeito_pancada(bola, 1500)
	else:
		bola.rebater(direcao, velocidade)
		rebater(-direcao, velocidade)
		bola.posse = false
		attacking = false

func efeito_pancada(bola, pontos):
	rebater(bola.direcao, bola.velocidade)

	var a = numeros_voadores.instantiate()
	get_parent().add_child(a)
	a.global_position = global_position
	a.mostrar_pontos(Run.pontuar(pontos))
	Run.multiplicar(0.1)

	bola.rebater(bola.direcao, bola.velocidade)

	vida -= bola.dano
	vida_boss.atualizar_vida(vida)
	cooldown.start()
