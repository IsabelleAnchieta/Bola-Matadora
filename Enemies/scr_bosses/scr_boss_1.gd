extends "res://Enemies/scr_bosses/scr_boss_base.gd"

func _ready() -> void:
	vida = 5
	velocidade = 300.0
	desaceleracao = 100.0
	
	super._ready()
