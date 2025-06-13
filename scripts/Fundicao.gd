# Fundicao.gd - UI + Sistema de Raridades (BUGS CRÍTICOS CORRIGIDOS)
extends Control

@onready var back_btn: Button = $BackButton
@onready var status_label: Label = $StatusLabel
@onready var produce_btn: Button = $ProduceButton
@onready var collect_btn: Button = $CollectButton

# UI de seleção de modelo
@onready var model_selection_panel: Control = $ModelSelectionPanel
@onready var lightning_btn: Button = $ModelSelectionPanel/ModelButtons/LightningButton
@onready var guardian_btn: Button = $ModelSelectionPanel/ModelButtons/GuardianButton
@onready var swift_btn: Button = $ModelSelectionPanel/ModelButtons/SwiftButton
@onready var element_selection: OptionButton = $ModelSelectionPanel/ElementSelection
@onready var model_preview_label: Label = $ModelSelectionPanel/PreviewLabel
@onready var confirm_btn: Button = $ModelSelectionPanel/ConfirmButton
@onready var cancel_btn: Button = $ModelSelectionPanel/CancelButton

var production_timer: Timer
var is_producing: bool = false
var production_complete: bool = false

var selected_model: String = ""
var selected_element: String = ""

const PRODUCTION_TIME: float = 10.0
const PRODUCTION_COST: int = 50

# Probabilidades de raridade por nível (conforme database)
const RARITY_CHANCES = {
	1: {"COMUM": 0.80, "INCOMUM": 0.20},
	3: {"COMUM": 0.50, "INCOMUM": 0.35, "RARO": 0.15},
	6: {"COMUM": 0.45, "INCOMUM": 0.35, "RARO": 0.15, "EPICO": 0.05},
	10: {"COMUM": 0.30, "INCOMUM": 0.30, "RARO": 0.25, "EPICO": 0.12, "LENDARIO": 0.03}
}

func _ready():
	setup_ui()
	connect_signals()
	setup_model_selection()
	update_display()

func setup_ui():
	production_timer = Timer.new()
	production_timer.wait_time = PRODUCTION_TIME
	production_timer.timeout.connect(_on_production_complete)
	add_child(production_timer)
	
	model_selection_panel.visible = false

func connect_signals():
	back_btn.pressed.connect(_on_back_pressed)
	produce_btn.pressed.connect(_on_produce_pressed)
	collect_btn.pressed.connect(_on_collect_pressed)
	
	lightning_btn.pressed.connect(_on_model_selected.bind("LIGHTNING"))
	guardian_btn.pressed.connect(_on_model_selected.bind("GUARDIAN"))
	swift_btn.pressed.connect(_on_model_selected.bind("SWIFT"))
	element_selection.item_selected.connect(_on_element_selected)
	confirm_btn.pressed.connect(_on_confirm_production)
	cancel_btn.pressed.connect(_on_cancel_selection)

func setup_model_selection():
	element_selection.clear()
	element_selection.add_item("COBRE", 0)
	element_selection.add_item("FERRO", 1) 
	element_selection.add_item("ALUMÍNIO", 2)
	element_selection.select(0)
	
	setup_model_button_styles()

func setup_model_button_styles():
	lightning_btn.text = "⚡ LIGHTNING\n(Balanced)"
	guardian_btn.text = "🛡️ GUARDIAN\n(Tank)"
	swift_btn.text = "💨 SWIFT\n(DPS)"

func update_display():
	var player = GameManager.current_player
	
	produce_btn.disabled = (player.sucata < PRODUCTION_COST) or is_producing or production_complete
	collect_btn.visible = production_complete
	
	if is_producing:
		var time_left = production_timer.time_left
		status_label.text = "Produzindo %s %s... %.1fs restantes" % [selected_element, selected_model, time_left]
	elif production_complete:
		status_label.text = "C.O.R.E. %s %s pronto para coleta!" % [selected_element, selected_model]
	else:
		var fundry_level = player.fundição_level
		var rarities = get_available_rarities(fundry_level)
		status_label.text = "Fundição Nível %d\nCusto: %d sucata\nRaridades: %s" % [fundry_level, PRODUCTION_COST, rarities]

func get_available_rarities(level: int) -> String:
	var available = []
	
	if level >= 1:
		available.append("Comum")
	if level >= 1:
		available.append("Incomum")
	if level >= 3:
		available.append("Raro")
	if level >= 6:
		available.append("Épico")
	if level >= 10:
		available.append("Lendário")
	
	return ", ".join(available)

func _on_produce_pressed():
	var player = GameManager.current_player
	if player.sucata >= PRODUCTION_COST:
		show_model_selection()
	else:
		status_label.text = "Sucata insuficiente! Necessário: %d" % PRODUCTION_COST

func show_model_selection():
	model_selection_panel.visible = true
	produce_btn.disabled = true
	
	selected_model = ""
	selected_element = "COBRE"
	update_model_preview()

func _on_model_selected(model: String):
	selected_model = model
	
	reset_model_button_styles()
	match model:
		"LIGHTNING":
			lightning_btn.modulate = Color.CYAN
		"GUARDIAN":
			guardian_btn.modulate = Color.ORANGE
		"SWIFT":
			swift_btn.modulate = Color.MAGENTA
	
	update_model_preview()

func reset_model_button_styles():
	lightning_btn.modulate = Color.WHITE
	guardian_btn.modulate = Color.WHITE
	swift_btn.modulate = Color.WHITE

func _on_element_selected(index: int):
	match index:
		0: selected_element = "COBRE"
		1: selected_element = "FERRO"
		2: selected_element = "ALUMINIO"
	
	update_model_preview()

func update_model_preview():
	if selected_model == "" or selected_element == "":
		model_preview_label.text = "Selecione modelo e elemento"
		confirm_btn.disabled = true
		return
	
	var preview_text = """=== PREVIEW ===
Modelo: %s %s

=== STATS BASE ===
%s

=== ESPECIALIZAÇÃO ===
%s

=== RARIDADE POSSÍVEL ===
%s""" % [
		selected_element,
		selected_model,
		get_model_stats_preview(selected_model),
		get_model_specialization(selected_model),
		get_rarity_preview()
	]
	
	model_preview_label.text = preview_text
	confirm_btn.disabled = false

func get_model_stats_preview(model: String) -> String:
	match model:
		"LIGHTNING":
			return "ATK: 70-100 | DEF: 70-100 | VEL: 70-100\nHP: 80-110 | Balanced em tudo"
		"GUARDIAN":
			return "ATK: 50-70 | DEF: 100-130 | VEL: 40-60\nHP: 110-140 | Foco em defesa"
		"SWIFT":
			return "ATK: 90-120 | DEF: 50-70 | VEL: 110-140\nHP: 60-90 | Foco em velocidade"
		_:
			return "Stats desconhecidos"

func get_model_specialization(model: String) -> String:
	match model:
		"LIGHTNING":
			return "True Balanced - Versátil em todas situações"
		"GUARDIAN":
			return "Tank Specialist - Resistência suprema"
		"SWIFT":
			return "DPS Specialist - Velocidade e dano"
		_:
			return "Especialização desconhecida"

func get_rarity_preview() -> String:
	var player = GameManager.current_player
	var level = player.fundição_level
	
	if RARITY_CHANCES.has(level):
		var chances = RARITY_CHANCES[level]
		var preview = []
		for rarity in chances:
			var percentage = chances[rarity] * 100
			preview.append("%s: %.0f%%" % [rarity, percentage])
		return "\n".join(preview)
	else:
		return "Comum: 100%"

func _on_confirm_production():
	var player = GameManager.current_player
	if player.sucata >= PRODUCTION_COST:
		player.sucata -= PRODUCTION_COST
		is_producing = true
		production_timer.start()
		
		model_selection_panel.visible = false
		
		update_display()
		print("🏭 Iniciando produção: %s %s" % [selected_element, selected_model])

func _on_cancel_selection():
	model_selection_panel.visible = false
	produce_btn.disabled = false
	
	selected_model = ""
	selected_element = ""
	reset_model_button_styles()

func _on_production_complete():
	is_producing = false
	production_complete = true
	update_display()
	
	print("🏭 Produção completa: %s %s!" % [selected_element, selected_model])

func _on_collect_pressed():
	var new_robot = create_robot_with_selection()
	GameManager.data_manager.robots.append(new_robot)
	
	production_complete = false
	is_producing = false
	selected_model = ""
	selected_element = ""
	
	if production_timer.timeout.is_connected(_on_production_complete):
		production_timer.stop()
	
	update_display()
	GameManager.data_manager.save_game()
	print("🤖 Robô coletado: " + new_robot.serial_number)

func create_robot_with_selection() -> RobotData:
	var robot = RobotData.new()
	
	var chosen_model = selected_model
	var chosen_element = selected_element
	
	# Gerar número de série
	var robot_count = GameManager.data_manager.robots.size() + 1
	var model_code = get_model_code(chosen_model)
	var element_code = get_element_code(chosen_element)
	robot.serial_number = "TKR-%s-%s-%06d" % [element_code, model_code, robot_count]
	
	robot.type = get_robot_type(chosen_element, chosen_model)
	robot.rarity = determine_rarity()
	
	# 🔧 CORREÇÃO CRÍTICA: Stats dirigidos corretos por modelo
	apply_model_stats_with_rarity(robot, chosen_model)
	
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	print("🏭 Robô criado: %s %s (%s)" % [chosen_element, chosen_model, robot.get_rarity_name()])
	print("📊 Stats: ATK:%d DEF:%d HP:%d SPD:%d" % [
		robot.base_attack, robot.base_defense, robot.base_health, robot.base_speed
	])
	
	return robot

func determine_rarity() -> RobotData.Rarity:
	var player = GameManager.current_player
	var level = player.fundição_level
	
	if not RARITY_CHANCES.has(level):
		return RobotData.Rarity.COMUM
	
	var chances = RARITY_CHANCES[level]
	var roll = randf()
	var cumulative = 0.0
	
	var rarity_order = ["LENDARIO", "EPICO", "RARO", "INCOMUM", "COMUM"]
	
	for rarity_name in rarity_order:
		if chances.has(rarity_name):
			cumulative += chances[rarity_name]
			if roll <= cumulative:
				match rarity_name:
					"LENDARIO": return RobotData.Rarity.LENDARIO
					"EPICO": return RobotData.Rarity.EPICO
					"RARO": return RobotData.Rarity.RARO
					"INCOMUM": return RobotData.Rarity.INCOMUM
					"COMUM": return RobotData.Rarity.COMUM
	
	return RobotData.Rarity.COMUM

# 🔧 FUNÇÃO CORRIGIDA: Stats dirigidos por modelo
func apply_model_stats_with_rarity(robot: RobotData, model: String):
	# Aplicar ranges base conforme database + multiplicador de raridade
	match model:
		"LIGHTNING":  # Balanced - RANGES CORRETOS
			robot.base_attack = robot.apply_rarity_multiplier(randi_range(7, 10) * 10)
			robot.base_special_attack = robot.apply_rarity_multiplier(randi_range(7, 10) * 10)
			robot.base_defense = robot.apply_rarity_multiplier(randi_range(7, 10) * 10)
			robot.base_special_defense = robot.apply_rarity_multiplier(randi_range(7, 10) * 10)
			robot.base_health = robot.apply_rarity_multiplier(randi_range(8, 11) * 10)
			robot.base_speed = robot.apply_rarity_multiplier(randi_range(7, 10) * 10)
		
		"GUARDIAN":  # Tank - RANGES CORRETOS
			robot.base_attack = robot.apply_rarity_multiplier(randi_range(5, 7) * 10)
			robot.base_special_attack = robot.apply_rarity_multiplier(randi_range(4, 6) * 10)
			robot.base_defense = robot.apply_rarity_multiplier(randi_range(10, 13) * 10)
			robot.base_special_defense = robot.apply_rarity_multiplier(randi_range(9, 12) * 10)
			robot.base_health = robot.apply_rarity_multiplier(randi_range(11, 14) * 10)
			robot.base_speed = robot.apply_rarity_multiplier(randi_range(4, 6) * 10)
		
		"SWIFT":  # DPS - RANGES CORRETOS
			robot.base_attack = robot.apply_rarity_multiplier(randi_range(9, 12) * 10)
			robot.base_special_attack = robot.apply_rarity_multiplier(randi_range(10, 13) * 10)
			robot.base_defense = robot.apply_rarity_multiplier(randi_range(5, 7) * 10)
			robot.base_special_defense = robot.apply_rarity_multiplier(randi_range(6, 8) * 10)
			robot.base_health = robot.apply_rarity_multiplier(randi_range(6, 9) * 10)
			robot.base_speed = robot.apply_rarity_multiplier(randi_range(11, 14) * 10)

func get_robot_type(element: String, model: String) -> RobotData.Type:
	match element:
		"COBRE":
			match model:
				"LIGHTNING": return RobotData.Type.COBRE_LIGHTNING
				"GUARDIAN": return RobotData.Type.COBRE_GUARDIAN
				"SWIFT": return RobotData.Type.COBRE_SWIFT
		"FERRO":
			match model:
				"LIGHTNING": return RobotData.Type.FERRO_LIGHTNING
				"GUARDIAN": return RobotData.Type.FERRO_GUARDIAN
				"SWIFT": return RobotData.Type.FERRO_SWIFT
		"ALUMINIO":
			match model:
				"LIGHTNING": return RobotData.Type.ALUMINIO_LIGHTNING
				"GUARDIAN": return RobotData.Type.ALUMINIO_GUARDIAN
				"SWIFT": return RobotData.Type.ALUMINIO_SWIFT
	
	return RobotData.Type.COBRE_LIGHTNING

func get_model_code(model: String) -> String:
	match model:
		"LIGHTNING": return "LGT"
		"GUARDIAN": return "GRD"
		"SWIFT": return "SWT"
		_: return "LGT"

func get_element_code(element: String) -> String:
	match element:
		"COBRE": return "COP"
		"FERRO": return "IRO"
		"ALUMINIO": return "ALU"
		_: return "COP"

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _process(_delta):
	if is_producing:
		update_display()
