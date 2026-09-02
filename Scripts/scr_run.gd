extends Node

signal multiplicador_alterado
signal pontos_alterados

var multiplicador = 1.0
var maior_multi = 1.0
var pontos = 0
var pontos_totais = 0
var tempo_total = 0.0
var tempo = 0.0

var bosses_derrotados = []

var run_ativa = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pontos = 0
	pontos_totais = 0
	tempo_total = 0.0
	tempo = 0.0
	multiplicador = 1.0
	bosses_derrotados.clear()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if run_ativa:
		if maior_multi < multiplicador:
			maior_multi = multiplicador
		tempo += delta

func pontuar(valor):
	var ganho = valor * multiplicador
	pontos += ganho
	pontos_alterados.emit()
	return ganho
	
func multiplicar(valor):
	multiplicador += valor
	multiplicador_alterado.emit()
	
func reset_multi():
	multiplicador = 1
	multiplicador_alterado.emit()
	
func derrotar_bosses(id):
	if id not in bosses_derrotados:
		print(id)
		bosses_derrotados.append(id)

func start():
	reset_multi()
	pontos = 0
	pontuar(0)
	tempo = 0.0
	run_ativa = true

func iniciar_run():
	run_ativa = true

func finalizar_run():
	run_ativa = false

func contabilizar():
	tempo_total += tempo
	pontos_totais += pontos
