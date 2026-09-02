extends StaticBody2D

@export var numeros_voadores : PackedScene
@onready var timer = $Timer
var vida = 10
var morri = false

func _physics_process(delta):
	if !morri:
		if vida <= 0:
			morri = true
			timer.start()


func _on_timer_timeout() -> void:
	queue_free()

func receber_impacto(bola):
	if bola.velocidade > 700:
		vida -= bola.dano * 10
		if bola.is_in_group("bola"):
			var a = numeros_voadores.instantiate()
			get_parent().add_child(a)
			a.global_position = global_position
			a.mostrar_pontos(Run.pontuar(500))
			Run.multiplicar(0.1)
	else:
		vida -= bola.dano
		if bola.is_in_group("bola"):
			var a = numeros_voadores.instantiate()
			get_parent().add_child(a)
			a.global_position = global_position
			a.mostrar_pontos(Run.pontuar(150))
			Run.multiplicar(0.1)
