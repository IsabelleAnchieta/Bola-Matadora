extends Node2D

@onready var Camera = $Player/Camera2D
@onready var Player = $Player
@onready var Telas = $CanvasLayer/TelaMorte
@onready var Pause = $CanvasLayer/Pause

@onready var Boss = $Boss
@onready var Boss2 = $Boss2

@onready var VidaBoss = $CanvasLayer/VidaBoss
@onready var VidaBoss2 = $CanvasLayer/VidaBoss2


func _ready() -> void:
	Camera.limit_bottom = 650
	Camera.limit_left = 0
	Camera.limit_right = 1300
	Camera.limit_top = 0
	get_tree().paused = false
	
	VidaBoss.configurar_boss(Boss, 20)
	VidaBoss2.configurar_boss(Boss2, 70)
	
	Boss.vida_boss = VidaBoss
	Boss2.vida_boss = VidaBoss2	


func _process(delta: float) -> void:
	if Player.dead:
		Telas.visible = true
		get_tree().paused = true
	
	if Input.is_action_pressed("Pause"):
		Pause.visible = true
		get_tree().paused = true
