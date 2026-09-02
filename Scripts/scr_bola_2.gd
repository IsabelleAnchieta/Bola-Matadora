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
	if body.has_method("receber_impacto"):
		body.receber_impacto(self)


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

func receber_impacto(bola):
	rebater(bola.direcao, velocidade + 100)
	if bola.posse:
		var a = numeros_voadores.instantiate()
		get_parent().add_child(a)
		a.global_position = global_position
		a.mostrar_pontos(Run.pontuar(250))

	if bola.posse:
		posse = true
	else:
		posse = false
