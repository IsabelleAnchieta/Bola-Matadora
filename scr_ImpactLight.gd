extends Node2D

var For
var count = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if For < 1:
		For = 2
	elif For < 10:
		For = 4
	else:
		For = 6


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	get_node("Sprite2D").scale += Vector2(For, For)
	count += 1
	if count > 5:
		queue_free()
