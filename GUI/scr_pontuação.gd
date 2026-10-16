
extends Label

func mostrar_pontos(valor):
	if valor is String:
		text = valor
		definir_cor_texto(valor)
	else:
		text = "+" + str(valor)
		definir_cor_pontos(valor)

	# Pequena variação na posição inicial
	position += Vector2(
		randf_range(-12.0, 12.0),
		randf_range(-8.0, 8.0)
	)

	# Direção aleatória do salto
	var angulo = randf_range(-150.0, -30.0)
	var distancia_salto = randf_range(25.0, 45.0)

	var deslocamento = Vector2.RIGHT.rotated(deg_to_rad(angulo)) * distancia_salto

	# Começa pequeno e totalmente visível.
	scale = Vector2(0.5, 0.5)
	modulate.a = 1.0

	# Pop: cresce, passa um pouco do tamanho final e estabiliza.
	var tween = create_tween()
	tween.tween_property(
		self, "scale", Vector2(1.2, 1.2), 0.12
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self, "scale", Vector2.ONE, 0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Permanece visível por um instante e depois sobe e desaparece.
	tween.tween_interval(0.18)
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"position",
		position + deslocamento,
		0.35
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "modulate:a", 0.0, 0.35)

	await tween.finished
	queue_free()


func definir_cor_texto(mensagem: String) -> void:
	match mensagem:
		"???":
			add_theme_color_override("font_color", Color("#B0B0B0"))
		"Meh":
			add_theme_color_override("font_color", Color("#A0A0A0"))
		"Great!":
			add_theme_color_override("font_color", Color("#55DDE0"))
		"PERFECT!":
			add_theme_color_override("font_color", Color("#FFB52E"))



func definir_cor_pontos(valor: int) -> void:
	if valor < 500:
		add_theme_color_override("font_color", Color("#999999"))
	elif valor < 1000:
		add_theme_color_override("font_color", Color("#FFFFFF"))
	elif valor < 1500:
		add_theme_color_override("font_color", Color("#55D66B"))
	elif valor < 2500:
		add_theme_color_override("font_color", Color("#55DDE0"))
	elif valor < 3500:
		add_theme_color_override("font_color", Color("#FFD447"))
	elif valor < 5000:
		add_theme_color_override("font_color", Color("#FF4545"))
	else:
		add_theme_color_override("font_color", Color("#438CFF"))
