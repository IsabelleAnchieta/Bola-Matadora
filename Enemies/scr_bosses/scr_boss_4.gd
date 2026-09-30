extends "res://Enemies/scr_bosses/scr_boss_base.gd"

@export var Projetil: PackedScene

var count = 3
var count2 = 0
var its_mine = true
var vida_max

func _ready():
	vida_max = vida
	super._ready()

func _physics_process(delta: float) -> void:
	if vida > vida_max:
		vida = vida_max
	super._physics_process(delta)


func attack() -> void:
	super.attack()
	count2 = count


func shooting() -> void:
	if count2 <= 0:
		attack()
		vida += 1
		vida_boss.atualizar_vida(vida)
	else:
		var projetil = Projetil.instantiate()
		get_parent().add_child(projetil)

		projetil.global_position = global_position
		projetil.posicao_inicial = global_position

		var direcao_projetil = global_position.direction_to(target.global_position)
		projetil.direcao = direcao_projetil
		
		tempo_passado = 0.0
		AreaTelegraph.scale = Vector2.ZERO

		count2 -= 1

func atualizar_telegraph(delta: float):
	tempo_passado += delta

	var progresso = tempo_passado / tempo_telegraph
	progresso = clamp(progresso, 0.0, 1.0)

	AreaTelegraph.scale = Vector2.ONE * progresso

	if progresso >= 1.0:
		shooting()
