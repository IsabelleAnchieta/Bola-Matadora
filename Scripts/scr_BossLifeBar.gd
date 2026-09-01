extends Control

var Boss

@onready var Painel = $Panel

var vida_maxima = 2
var quadrados_vida = []


func _ready() -> void:
	pass


func configurar_boss(boss, posicao_y):
	Boss = boss
	
	vida_maxima = Boss.vida
	
	Painel.size.x = Boss.vida * 30
	Painel.size.y = 40
	
	Painel.position.x = get_viewport_rect().size.x / 2 - Painel.size.x / 2
	Painel.position.y = posicao_y
	
	criar_vida()


func criar_vida() -> void:
	for i in vida_maxima:
		var quadrado = preload("res://GUI/GUI_quadrado_life.tscn").instantiate()
		$Panel/HBoxContainer.add_child(quadrado)
		quadrados_vida.append(quadrado)


func atualizar_vida(vida_atual) -> void:
	for i in range(vida_maxima):
		if i < vida_atual:
			quadrados_vida[i].preencher()
		else:
			quadrados_vida[i].esvaziar()
