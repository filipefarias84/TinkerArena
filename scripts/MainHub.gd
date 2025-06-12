# MainHub.gd - Tela principal MVP (CORRIGIDO)
extends Control

# Referências dos botões
@onready var sucata_label: Label = $Header/SucataLabel
@onready var fundicao_btn: Button = $Center/FundicaoButton
@onready var arsenal_btn: Button = $Center/ArsenalButton
@onready var oficina_btn: Button = $Center/OficinaButton
@onready var bancada_btn: Button = $Center/BancadaButton
@onready var combat_btn: Button = $Center/CombatButton

func _ready():
	# Aguardar um frame para GameManager estar inicializado
	await get_tree().process_frame
	connect_signals()
	update_ui()
	print("🏠 MainHub carregado")

func connect_signals():
	fundicao_btn.pressed.connect(_on_fundicao_pressed)
	arsenal_btn.pressed.connect(_on_arsenal_pressed)
	oficina_btn.pressed.connect(_on_oficina_pressed)
	bancada_btn.pressed.connect(_on_bancada_pressed)
	combat_btn.pressed.connect(_on_combat_pressed)

func update_ui():
	# Verificar se GameManager está inicializado
	if not GameManager:
		print("⚠️ GameManager não inicializado ainda")
		return
	
	if not GameManager.current_player:
		print("⚠️ Player não carregado ainda")
		return
	
	# Atualizar label de sucata
	var player = GameManager.current_player
	sucata_label.text = "Sucata: %d" % player.sucata
	
	# Verificar se data_manager existe
	if not GameManager.data_manager:
		print("⚠️ DataManager não inicializado")
		combat_btn.disabled = true
		combat_btn.text = "COMBATE (Carregando...)"
		return
	
	# Verificar se há robôs ativos para combate
	var active_robots = GameManager.data_manager.get_active_robots()
	combat_btn.disabled = active_robots.is_empty()
	
	if combat_btn.disabled:
		combat_btn.text = "COMBATE (Sem robôs)"
	else:
		combat_btn.text = "COMBATE TESTE (%d robôs)" % active_robots.size()

# Função para atualizar UI quando voltamos de outras telas
func _on_tree_entered():
	# Aguardar um frame e atualizar UI
	await get_tree().process_frame
	update_ui()

func _on_fundicao_pressed():
	print("🏭 Acessando Fundição")
	get_tree().change_scene_to_file("res://scenes/Fundicao.tscn")

func _on_arsenal_pressed():
	print("⚙️ Acessando Arsenal")
	get_tree().change_scene_to_file("res://scenes/Arsenal.tscn")

func _on_oficina_pressed():
	print("🔧 Acessando Oficina")
	get_tree().change_scene_to_file("res://scenes/Oficina.tscn")
	
func _on_bancada_pressed():
	print("🔧 Acessando Bancada")
	get_tree().change_scene_to_file("res://scenes/Bancada.tscn")

func _on_combat_pressed():
	# Verificação extra antes de ir para combate
	if not GameManager or not GameManager.data_manager:
		print("❌ Sistemas não inicializados!")
		return
	
	var active_robots = GameManager.data_manager.get_active_robots()
	if active_robots.is_empty():
		print("❌ Nenhum robô ativo para combate!")
		return
	
	print("⚔️ Iniciando combate com %d robôs ativos!" % active_robots.size())
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
