extends Node2D

var CameraFake
var CameraReal
var cutscene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		CameraFake = get_parent().get_node("CameraFake")
		CameraReal = get_parent().get_node("Player/Camera2D")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	CameraFake.global_position = CameraReal.global_position


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Timer.start()
		get_tree().paused = true

func _on_timer_timeout() -> void:
		cutscene = get_parent()
		cutscene.iniciar_entrada()
		queue_free()
