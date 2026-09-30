extends "res://Enemies/scr_bosses/scr_boss_base.gd"

var count = 5
var imcounting = 0

func _ready() -> void:
	desaceleracao = 1000.0
	super._ready()


func _on_timer_timeout() -> void:
	imcounting = count
	super._on_timer_timeout()


func quando_bater_na_parede() -> void:
	imcounting -= 1
	
	if imcounting <= 0:
		attacking = false


func processar_movimento(delta: float) -> void:
	if imcounting <= 0:
		velocidade = move_toward(velocidade, 0, desaceleracao * delta)

	velocity = direcao * velocidade
	move_and_slide()
