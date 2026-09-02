extends CharacterBody2D

@onready var rastro = get_parent().get_node("RastroBola")
@onready var rastro2 = get_parent().get_node("RastroBola2")
@onready var PartImpc = $ParticulasImpacto
@onready var Boom = $Timer

var pontos_rastro: Array[Vector2] = []

var velocidade = 0.0
var desaceleracao = 100.0
var direcao = Vector2(1, 1).normalized()
var posse = true
var dano = 1
var pode_ser = true

func _physics_process(delta):
	velocidade = move_toward(velocidade, 0, desaceleracao * delta)
	if velocidade <= 0:
		Run.reset_multi()
	
	velocity = direcao * velocidade

	move_and_slide()

	atualizar_rastro()

	if get_slide_collision_count() > 0:
		var colisao = get_slide_collision(0)
		var normal = colisao.get_normal()
		
		direcao = direcao.bounce(normal)
		PartImpc.emitting = true
		Boom.start()



func rebater(nova_direcao: Vector2, nova_forca: float):
	direcao = nova_direcao.normalized()
	velocidade = nova_forca


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("receber_impacto"):
		if velocidade > 1000:
			dano = 2
		else:
			dano = 1
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
		Run.reset_multi()
		rastro.clear_points()

func _on_timer_timeout() -> void:
	PartImpc.emitting = false
	
func finished():
	rastro.queue_free()
	rastro2.queue_free()
	queue_free()
