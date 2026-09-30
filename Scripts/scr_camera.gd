extends Camera2D

var zoom_normal = Vector2(0.7, 0.7)
var zoom_ataque = 0.9
var finalizando_boss = false
var tween_zoom

func efeito_ataque(X):
	if finalizando_boss:
		return

	if tween_zoom:
		tween_zoom.kill()

	tween_zoom = create_tween()
	tween_zoom.tween_property(self, "zoom", Vector2(X, X), 0.05)
	tween_zoom.tween_property(self, "zoom", zoom_normal, 1)

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
