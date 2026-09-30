extends CharacterBody2D

@onready var PartImpc = $ParticulasImpacto
@onready var Boom = $Timer

@export var numeros_voadores: PackedScene
@export var CenaRastro: PackedScene
var rastre
var rastro
var rastro2

var pontos_rastro: Array[Vector2] = []
var posse_anterior = false
var velocidade = 1000.0
var desaceleracao = 100.0
var direcao = Vector2(1, 1).normalized()
var posse = false
var dano = 1
var pode_ser = true
var help = 5

var pontos = 1000
var withplayer = true #Esse é só pra nao dar erro em colisão

var posicao_inicial
var first_punch = false

func _ready() -> void:
	rastre = CenaRastro.instantiate()
	get_parent().add_child(rastre)
	rastro = rastre.get_node("RastroBola")
	rastro2 = rastre.get_node("RastroBola2")

func _physics_process(_delta):
	if velocidade <= 0:
		dano = 0
	else:
		dano = 1
	
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
	if body.has_method("receber_impacto"):
		body.receber_impacto(self)


func atualizar_rastro():
	pontos_rastro.push_front(global_position)

	if pontos_rastro.size() > 20:
		pontos_rastro.pop_back()

	if posse:
		if !first_punch:
			set_collision_mask_value(5, true)
			$Area2D.set_collision_mask_value(5, true)
			first_punch = true
		rastro.points = pontos_rastro
		rastro2.clear_points()
	else:
		rastro2.points = pontos_rastro
		rastro.clear_points()

func _on_timer_timeout() -> void:
	PartImpc.emitting = false

func receber_impacto(bola):
	if !first_punch:
		if global_position.distance_to(posicao_inicial) > 40.0:
			set_collision_mask_value(5, true)
			$Area2D.set_collision_mask_value(5, true)
			first_punch = true
		
	if bola.posse:
		var a = numeros_voadores.instantiate()
		get_parent().add_child(a)
		a.global_position = global_position
		a.mostrar_pontos(Run.pontuar(250))

	if bola.posse:
		posse = true
	else:
		posse = false
	rebater(bola.direcao, velocidade + 100)
