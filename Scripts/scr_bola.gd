extends CharacterBody2D
@export var Light : PackedScene

@onready var rastro = get_parent().get_node("RastroBola")
@onready var rastro2 = get_parent().get_node("RastroBola2")
@onready var PartImpc = $ParticulasImpacto
@onready var Boom = $Timer
@onready var Sprite = $CollisionShape2D/AnimatedSprite2D


var Ramdomizer

var pontos_rastro: Array[Vector2] = []

var velocidade = 0.0
var desaceleracao = 100.0
var direcao = Vector2(1, 1).normalized()
var posse = true
var dano = 1
var pode_ser = true
var pontos = 1000

var Luz

var withplayer =  false

func _physics_process(delta):
	
	if Sprite.scale.x < 1:
		Sprite.scale.x += 0.01
		
	
	if posse:
		velocidade = move_toward(velocidade, 0, desaceleracao * delta)
	else:
		velocidade = move_toward(velocidade, 0, desaceleracao * 2 * delta)
	if velocidade <= 0:
		Sprite.play("stop")
		Run.reset_multi()
	else:
		Sprite.play("our")
	
	velocity = direcao * velocidade
	Sprite.rotation += velocidade
	
	if withplayer:
		desaceleracao = 500
	else:
		desaceleracao = 100

	move_and_slide()

	atualizar_rastro()

	if get_slide_collision_count() > 0:
		var colisao = get_slide_collision(0)
		var normal = colisao.get_normal()
		Ramdomizer = randf_range(1, 2)
		$Combo.pitch_scale = Ramdomizer
		$Combo.play()
		
		direcao = direcao.bounce(normal)
		PartImpc.emitting = true
		Boom.start()



func rebater(nova_direcao: Vector2, nova_forca: float):
	direcao = nova_direcao.normalized()
	velocidade = nova_forca


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("receber_impacto"):
		if !body.is_in_group("player"):
			if velocidade >= 1100:
				dano = 2
				pontos = 1500
				Ramdomizer = randf_range(1, 2)
				$VineBoom.pitch_scale = Ramdomizer
				$VineBoom.play()
			elif velocidade <= 200:
				Ramdomizer = randf_range(1, 2)
				$Pancadinha.pitch_scale = Ramdomizer
				$Pancadinha.play()
				dano = 0
				pontos = 0
			else:
				Ramdomizer = randf_range(1, 0.8)
				$Pancadinha.pitch_scale = Ramdomizer
				$Pancadinha.play()
				dano = 1
				pontos = 1000
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
