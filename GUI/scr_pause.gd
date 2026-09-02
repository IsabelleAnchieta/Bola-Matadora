extends Control

@onready var tempo = $VBoxContainer/Centralize/Cont/Label2
@onready var pontus = $VBoxContainer/Centralize/Cont/Label3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_button_pressed() -> void:
	Run.start()
	get_tree().paused = false
	visible = false


func _on_button_2_pressed() -> void:
	Run.iniciar_run()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_button_3_pressed() -> void:
	get_tree().quit()

func atualizar_tempo():
	tempo.text = str(formatar_tempo(Run.tempo))
	
func atualizar_pontus():
	pontus.text = str(Run.pontos)

func formatar_tempo(segundos: float) -> String:
	var horas = int(segundos) / 3600
	var minutos = (int(segundos) % 3600) / 60
	var segundos_restantes = int(segundos) % 60
	
	return "%02d:%02d:%02d" % [horas, minutos, segundos_restantes]
