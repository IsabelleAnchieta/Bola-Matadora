extends Control

@onready var Boss = get_parent().get_parent().get_node("Boss")
@onready var Painel = $Panel
var vida_maxima = 2

var quadrados_vida = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vida_maxima = Boss.vida
	Painel.size.x = Boss.vida * 30
	Painel.position.x = get_viewport_rect().size.x / 2 - Painel.size.x / 2
	Painel.size.y = 40
	criar_vida()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func criar_vida():
	for i in vida_maxima:
		var quadrado = preload("res://GUI/GUI_quadrado_life.tscn").instantiate()
		$Panel/HBoxContainer.add_child(quadrado)
		quadrados_vida.append(quadrado)

func atualizar_vida(vida_atual):
	for i in range(vida_maxima):
		if i < vida_atual:
			quadrados_vida[i].preencher()
		else:
			quadrados_vida[i].esvaziar()
