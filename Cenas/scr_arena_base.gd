extends Node2D

@export var limUP : int = -750
@export var limDown : int = 1000
@export var limRight : int = 1750
@export var limLeft : int = -250

@onready var Camera = $Player/Camera2D
@onready var Player = $Player
@onready var Telas = $CanvasLayer/TelaMorte
@onready var Pause = $CanvasLayer/Pause
@onready var CameraCutscene = $CameraFake/CameraCutscene
@onready var CameraFake = $CameraFake
@onready var Anim = $AnimationPlayer
@onready var Bola = $Bola



func _ready() -> void:
	congelar_bosses()
	
	for boss in get_tree().get_nodes_in_group("boss"):
		boss.tree_exited.connect(verificar_bosses)
	
	Camera.limit_bottom = limDown
	Camera.limit_left = limLeft
	Camera.limit_right = limRight
	Camera.limit_top = limUP
	
	get_tree().paused = false
	
	Run.iniciar_run()
	
	configurar_bosses()


func _process(delta: float) -> void:
	if Player.dead:
		Run.finalizar_run()
		
		Telas.atualizar_pontus()
		Telas.atualizar_tempo()
		Telas.visible = true
		
		get_tree().paused = true
	
	if Input.is_action_pressed("Pause"):
		Run.finalizar_run()
		
		Pause.atualizar_pontus()
		Pause.atualizar_tempo()
		Pause.visible = true
		
		get_tree().paused = true


func configurar_bosses() -> void:
	var bosses = get_tree().get_nodes_in_group("boss")
	var vidas = get_tree().get_nodes_in_group("vida_boss")
	
	for i in range(bosses.size()):
		var boss = bosses[i]
		
		if i < vidas.size():
			var vida_boss = vidas[i]
			
			vida_boss.configurar_boss(boss, 50 + i * 60)
			boss.vida_boss = vida_boss

#FINALIZAR ENTRADA
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "entrada":
		Camera.enabled = true
		CameraCutscene.enabled = false
		descongelar_bosses()
		get_tree().paused = false
		
	if anim_name == "skip_entrada":
		Camera.enabled = true
		CameraCutscene.enabled = false
		descongelar_bosses()
		get_tree().paused = false

func iniciar_entrada():
	Camera.enabled = false
	CameraCutscene.enabled = true

	get_tree().paused = true
	Anim.play("entrada")
	
func congelar_bosses() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		boss.process_mode = Node.PROCESS_MODE_DISABLED

func descongelar_bosses() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		boss.process_mode = Node.PROCESS_MODE_INHERIT

func verificar_bosses() -> void:
	if !is_inside_tree():
		return
	
	if get_tree().get_nodes_in_group("boss").is_empty():
		Anim.play("saida")
		$Pass.able = true
		Bola.finished()

func _on_boss_tree_exited() -> void:
	verificar_bosses()
