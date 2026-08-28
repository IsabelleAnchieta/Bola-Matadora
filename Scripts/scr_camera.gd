extends Camera2D

var zoom_normal = Vector2(1.2, 1.2)
var zoom_ataque = Vector2(1.28, 1.28)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func efeito_ataque(X):
	var tween = create_tween()
	tween.tween_property(self, "zoom", Vector2(X, X), 0.05)
	tween.tween_property(self, "zoom", Vector2(1.2, 1.2), 1)

func shake(intensidade: float, duracao: float):
	var tempo = 0.0
	
	while tempo < duracao:
		var offset = Vector2(
			randf_range(-intensidade, intensidade),
			randf_range(-intensidade, intensidade)
		)
		
		self.offset = offset
		
		await get_tree().process_frame
		tempo += get_process_delta_time()
	
	self.offset = Vector2.ZERO
	
func impacto(forca):
	var intensidade = clamp(forca / 100.0, 2.0, 10.0)
	
	shake(intensidade, 0.1)
