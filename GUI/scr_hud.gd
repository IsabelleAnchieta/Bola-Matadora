extends Control

@onready var pontos_label = $Pontos
@onready var multiplicador_label = $Multiplicador

func _ready():
	Run.pontos_alterados.connect(atualizar_pontos)
	Run.multiplicador_alterado.connect(atualizar_multiplicador)
	
	atualizar_pontos()
	atualizar_multiplicador()


func atualizar_pontos():
	pontos_label.text = str(Run.pontos)


func atualizar_multiplicador():
	multiplicador_label.text = "x" + str(Run.multiplicador)
