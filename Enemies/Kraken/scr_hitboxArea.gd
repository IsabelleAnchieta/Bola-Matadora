extends Area2D

@export var numeros_voadores : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bola") and $CollisionShape2D.disabled == false and body.posse:
		get_parent().hurted(body.dano)
		efeito_pancada(body, body.pontos)
		$CollisionShape2D.disabled = true
	
func efeito_pancada(bola, pontos):
	var a = numeros_voadores.instantiate()
	get_parent().add_child(a)
	a.global_position = global_position
	a.mostrar_pontos(Run.pontuar(pontos))
	Run.multiplicar(0.1)
