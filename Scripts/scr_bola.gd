extends CharacterBody2D
@export var Light : PackedScene
@export var cena_ghost: PackedScene
@export var intervalo_ghost: float = 0.035
@export var duracao_ghost: float = 0.5
@export var efeito_pancada: PackedScene

@onready var rastro = get_parent().get_node("RastroBola")
@onready var rastro2 = get_parent().get_node("RastroBola2")
@onready var PartImpc = $ParticulasImpacto
@onready var Boom = $Timer
@onready var Sprite = $CollisionShape2D/AnimatedSprite2D
@onready var material_flash: ShaderMaterial = Sprite.material


var ghost_ativo: bool = false
var tempo_ghost: float = 0.0

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
	atualizar_ghost_trail(delta)

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
		rastro.clear_points()

func _on_timer_timeout() -> void:
	PartImpc.emitting = false
	
func finished():
	rastro.queue_free()
	rastro2.queue_free()
	queue_free()

func receber_parry() -> void:
	velocidade = 0



func efeito_impacto_shader() -> void:
	var tween = create_tween()

	material_flash.set_shader_parameter("intensidade", 1.0)

	tween.tween_method(
		func(valor: float):
			material_flash.set_shader_parameter("intensidade", valor),
		1.0,
		0.0,
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func iniciar_ghost_trail() -> void:
	ghost_ativo = true
	tempo_ghost = 0.0


func parar_ghost_trail() -> void:
	ghost_ativo = false
	tempo_ghost = 0.0


func atualizar_ghost_trail(delta: float) -> void:
	if not ghost_ativo:
		return

	tempo_ghost += delta

	if tempo_ghost >= duracao_ghost:
		parar_ghost_trail()
		return

	if cena_ghost == null:
		return

	if not has_node("CollisionShape2D/AnimatedSprite2D"):
		return

	if int(tempo_ghost / intervalo_ghost) != int((tempo_ghost - delta) / intervalo_ghost):
		var ghost = cena_ghost.instantiate()
		get_parent().add_child(ghost)

		ghost.configurar(
			Sprite.sprite_frames.get_frame_texture(
				Sprite.animation,
				Sprite.frame
			),
			0,
			1,
			1,
			Sprite.global_position,
			Sprite.global_scale,
			Sprite.global_rotation,
			Sprite.flip_h,
			Sprite.flip_v
		)
