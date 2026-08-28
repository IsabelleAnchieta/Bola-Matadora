extends Node2D

@onready var rastro = get_parent().get_node("RastroTaco")
var pontos_rastro: Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	atualizar_rastro()

func atualizar_rastro():
	if owner.atacando:
		pontos_rastro.push_front($Mirando/Mira.position)

		if pontos_rastro.size() > 15:
			pontos_rastro.pop_back()

		rastro.points = pontos_rastro
	else:
		pontos_rastro.clear()
		rastro.clear_points()
