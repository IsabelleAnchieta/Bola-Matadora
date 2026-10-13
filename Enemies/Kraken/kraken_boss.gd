extends CharacterBody2D

@export var tentaculo : PackedScene

@onready var target = get_parent().get_node("Player")


var ID = "Kraken"

var vida = 5
var vida_boss
var protected = true
var dead = false

#Para o combate do Boss
var tentaculos_protetores = 8
var tentaculos_ativos = []

func _ready() -> void:
	$Timer.start()
	protection()

func protection():
	$Area2D2/CollisionShape2D.disabled = true
	protected = true
	tentaculos_protetores = 8

	for t in tentaculos_ativos:
		if is_instance_valid(t):
			t.afundar()

	tentaculos_ativos.clear()

func enviar_tentaculo():
	var quantidade = randi() % 3 + 1
	quantidade = min(quantidade, tentaculos_protetores)

	tentaculos_protetores -= quantidade

	for i in quantidade:
		instanciar_tentaculo()

	verificar_defesa()



func instanciar_tentaculo():
	if tentaculo == null:
		push_warning("A cena do tentáculo não foi configurada no Kraken.")
		return

	var novo_tentaculo = tentaculo.instantiate()

	# Sorteia um dos três ataques implementados.
	novo_tentaculo.tipo = randi_range(0, 2)

	# Adiciona o tentáculo à cena antes de definir a posição global.
	get_parent().add_child(novo_tentaculo)

	# Nasce junto ao Kraken.
	var deslocamento := Vector2(
		randf_range(-10.0, 10.0),
		randf_range(-10.0, 10.0)
	)

	novo_tentaculo.global_position = global_position + deslocamento

	tentaculos_ativos.append(novo_tentaculo)



func _on_timer_timeout() -> void:
	if tentaculos_protetores > 0:
		enviar_tentaculo()
	
func hurted(dano):
	vida -= dano
	vida_boss.atualizar_vida(vida)
	if vida <= 0:
		death()
	else:
		protection()

func verificar_defesa():
	if tentaculos_protetores == 0:
		print(tentaculos_protetores)
		protected = false
		$Area2D2/CollisionShape2D.disabled = false

func death(bola = null) -> void:
	if dead:
		return
	else:
		dead = true

	Run.derrotar_bosses(ID)

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

func receber_impacto(bola) -> void:
	bola.rebater(-bola.direcao, 1000)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
			body.death()
