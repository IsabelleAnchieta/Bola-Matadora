extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func mostrar_pontos(valor: int):
	text = "+" + str(valor)
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	queue_free()
