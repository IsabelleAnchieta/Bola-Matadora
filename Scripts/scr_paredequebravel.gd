extends StaticBody2D

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
	if bola.velocidade > 400:
		vida -= bola.dano * 10
	else:
		vida -= bola.dano
