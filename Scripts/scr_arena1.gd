extends Node2D

@onready var Camera = $Player/Camera2D
@onready var Player = $Player
@onready var Telas = $CanvasLayer/TelaMorte
@onready var Pause = $CanvasLayer/Pause

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Camera.limit_bottom = 650
	Camera.limit_left = 0
	Camera.limit_right = 1300
	Camera.limit_top = 0
	get_tree().paused = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Player.dead:
		Telas.visible = true
		get_tree().paused = true
	
	if Input.is_action_pressed("Pause"):
		Pause.visible = true
		get_tree().paused = true
		
