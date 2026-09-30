extends CharacterBody2D

@export var numeros_voadores : PackedScene
@export var ID : String
@export var vida = 5
@export var Forca = 1000
@export var WaitForAttack = 3.0

@onready var rastro: Line2D = $RastroBoss
@onready var target = get_parent().get_node("Player")
@onready var cooldown = $Timer
@onready var PartImpc = $ParticulasImpacto
@onready var deathtime = $Timer2
@onready var invencible_time = $Timer3
@onready var AreaTelegraph = $At/ReadyForBad

var vida_boss 

var pontos_rastro: Array[Vector2] = []
var posicao_anterior: Vector2
var can_damage = true

var dead = false
var attacking = false
var direcao = Vector2(1, 1).normalized()

var velocidade = 0
var dano = 5
var desaceleracao = 100.0

var avisar
var tempo_telegraph = 1.0
var tempo_passado = 0.0
var cool = true

func _ready() -> void:
	posicao_anterior = global_position
	avisar = get_parent()
	tempo_passado = 0.0
	AreaTelegraph.scale = Vector2.ZERO
	cooldown.wait_time = WaitForAttack


func _physics_process(delta: float) -> void:
	if cool:
		atualizar_telegraph(delta)
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
			quando_bater_na_parede()

		direcao = direcao.bounce(normal)


func quando_bater_na_parede() -> void:
	attacking = false


func rebater(nova_direcao: Vector2, nova_forca: float) -> void:
	direcao = nova_direcao.normalized()
	velocidade = nova_forca


func attack() -> void:
	cool = false
	cooldown.start()
	var direction = global_position.direction_to(target.global_position)

	direcao = direction
	velocidade = Forca
	tempo_passado = 0.0
	AreaTelegraph.scale = Vector2.ZERO


func _on_timer_timeout() -> void:
	cool = true


func atualizar_rastro() -> void:
	var movimento = posicao_anterior - global_position

	for i in range(pontos_rastro.size()):
		pontos_rastro[i] += movimento

	pontos_rastro.push_front(Vector2.ZERO)

	if pontos_rastro.size() > 20:
		pontos_rastro.pop_back()

	rastro.points = pontos_rastro

	posicao_anterior = global_position


func death(bola = null) -> void:
	if dead:
		return

	dead = true
	attacking = false
	velocidade = 0
	direcao = Vector2.ZERO

	Run.derrotar_bosses(ID)

	rastro.clear_points()
	pontos_rastro.clear()

	# Câmera do jogador
	
	var camera = target.get_node("Camera2D")

	camera.finalizando_boss = true

	if camera.tween_zoom:
		camera.tween_zoom.kill()

	Engine.time_scale = 0.05

	# Zoom out
	var zoom_tween = camera.create_tween()
	zoom_tween.set_ignore_time_scale(true)
	zoom_tween.tween_property(
		camera,
		"zoom",
		Vector2(0.45, 0.45),
		0.35
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	PartImpc.emitting = true

	# Mantém a pancada em câmera lenta por um instante
	await get_tree().create_timer(
		0.4,
		true,
		false,
		true
	).timeout

	# Volta a velocidade e o zoom juntos
	var retorno = camera.create_tween()
	retorno.set_ignore_time_scale(true)

	retorno.tween_method(
		func(valor):
			Engine.time_scale = valor,
		0.05,
		1.0,
		0.8
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	retorno.parallel().tween_property(
		camera,
		"zoom",
		camera.zoom_normal,
		0.8
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	await retorno.finished

	Engine.time_scale = 1.0

	queue_free()



func _on_timer_2_timeout() -> void:
	vida_boss.queue_free()
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.parrying and attacking and pode_parry(body):
			receber_parry()
		else:
			body.death()
	if body.is_in_group("ParedeQ"):
		if attacking:
			body.receber_impacto(self)
	if body.is_in_group("bola"):
		receber_impacto(body)

func receber_impacto(bola) -> void:
	if bola.posse and (!attacking or bola.velocidade >= 1200):
		efeito_pancada(bola, bola.pontos)
	else:
		var vel
		var direcao2 = direcao
		if velocidade != 0:
			vel = velocidade
		else:
			vel = bola.velocidade
		rebater(bola.direcao, vel)
		bola.rebater(direcao2, velocidade)
		bola.posse = false
		attacking = false

func efeito_pancada(bola, pontos):
	rebater(bola.direcao, (bola.velocidade + velocidade)/2)
	bola.rebater(-direcao, (bola.velocidade + velocidade)/2)
	if can_damage:
		cool = false
		tempo_passado = 0.0
		AreaTelegraph.scale = Vector2.ZERO
		cooldown.start()
		var a = numeros_voadores.instantiate()
		get_parent().add_child(a)
		a.global_position = global_position
		a.mostrar_pontos(Run.pontuar(pontos))
		Run.multiplicar(0.1)
		vida -= bola.dano
		can_damage = false
		invencible_time.start()
		vida_boss.atualizar_vida(vida)

		if vida <= 0:
			death(bola)

func _on_timer_3_timeout() -> void:
	can_damage = true


func atualizar_telegraph(delta: float):
	tempo_passado += delta

	var progresso = tempo_passado / tempo_telegraph
	progresso = clamp(progresso, 0.0, 1.0)

	AreaTelegraph.scale = Vector2.ONE * progresso

	if progresso >= 1.0 and !attacking:
		attack()
		attacking = true

func receber_parry():
	if !attacking:
		return

	attacking = false
	velocidade = 0
	direcao = Vector2.ZERO
	
func pode_parry(player) -> bool:
	var direcao_player = player.global_position.direction_to(get_global_position())
	var direcao_olhar = player.get_global_mouse_position() - player.global_position
	
	direcao_olhar = direcao_olhar.normalized()
	direcao_player = direcao_player.normalized()
	
	return direcao_olhar.dot(direcao_player) > 0.5
