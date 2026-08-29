extends CharacterBody2D

@onready var vida_boss = get_parent().get_node("CanvasLayer/VidaBoss")
@onready var PartImpc = $ParticulasImpacto
@onready var Boom = $Timer

@export var CenaRastro: PackedScene
var rastre
var rastro
var rastro2

var pontos_rastro: Array[Vector2] = []
var posse_anterior = false
var velocidade = 500.0
var desaceleracao = 100.0
var direcao = Vector2(1, 1).normalized()
var posse = false
var dano = 1
var pode_ser = true
var help = 3

func _ready() -> void:
	rastre = CenaRastro.instantiate()
	get_parent().add_child(rastre)
	rastro = rastre.get_node("RastroBola")
	rastro2 = rastre.get_node("RastroBola2")

func _physics_process(delta):
	
	velocity = direcao * velocidade

	move_and_slide()

	atualizar_rastro()

	if get_slide_collision_count() > 0:
		var colisao = get_slide_collision(0)
		var normal = colisao.get_normal()
		
		direcao = direcao.bounce(normal)
		PartImpc.emitting = true
		Boom.start()
		
		help -= 1
		if help <= 0:
			rastre.queue_free()
			queue_free()



func rebater(nova_direcao: Vector2, nova_forca: float):
	direcao = nova_direcao.normalized()
	velocidade = nova_forca


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if velocidade <= 0:
			posse = true
		elif !posse:
			body.death()
		var direcao_nova = global_position.direction_to(body.global_position)
		direcao = direcao_nova
		velocidade = 100.0
	
	if body.is_in_group("enemies"):
		if posse:
			body.vida -= dano
		body.rebater(direcao, velocidade)
		rebater(direcao, velocidade)
		vida_boss.atualizar_vida(body.vida)
		body.cooldown.start()
		
	if body.is_in_group("bola"):
		if body.posse:
			posse = true
		if !body.posse:
			posse = false



func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		pass
		
		
func atualizar_rastro():
	pontos_rastro.push_front(global_position)

	if pontos_rastro.size() > 20:
		pontos_rastro.pop_back()

	if posse:
		rastro.points = pontos_rastro
		rastro2.clear_points()
	else:
		rastro2.points = pontos_rastro
		rastro.clear_points()

func _on_timer_timeout() -> void:
	PartImpc.emitting = false
