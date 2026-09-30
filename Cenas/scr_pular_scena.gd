extends Node2D

var CameraCutscene
var Camera
var Anim

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CameraCutscene = get_parent().get_node("CameraFake/CameraCutscene")
	Camera = get_parent().get_node("Player/Camera2D")
	Anim = get_parent().get_node("AnimationPlayer")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pular_cutscene()

func pular_cutscene() -> void:
	if Anim.current_animation == "entrada":
		Anim.stop()
		CameraCutscene.enabled = false
		Camera.enabled = true
		Anim.play("skip_entrada")
