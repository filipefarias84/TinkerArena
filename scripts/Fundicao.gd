# Fundicao.gd - Produção de robôs MVP com modelos dirigidos (SEM MODELFACTORY)
extends Control

@onready var back_btn: Button = $BackButton
@onready var status_label: Label = $StatusLabel
@onready var produce_btn: Button = $ProduceButton
@onready var collect_btn: Button = $CollectButton

var production_timer: Timer
var is_producing: bool = false
var production_complete: bool = false

const PRODUCTION_TIME: float = 10.0  # 10 segundos para MVP
const PRODUCTION_COST: int = 50      # 50 sucata

func _ready():
	setup_ui()
	connect_signals()
	update_display()

func setup_ui():
	production_timer = Timer.new()
	production_timer.wait_time = PRODUCTION_TIME
	production_timer.timeout.connect(_on_production_complete)
	add_child(production_timer)

func connect_signals():
	back_btn.pressed.connect(_on_back_pressed)
	produce_btn.pressed.connect(_on_produce_pressed)
	collect_btn.pressed.connect(_on_collect_pressed)

func update_display():
	var player = GameManager.current_player
	
	produce_btn.disabled = (player.sucata < PRODUCTION_COST) or is_producing or production_complete
	collect_btn.visible = production_complete
	
	if is_producing:
		var time_left = production_timer.time_left
		status_label.text = "Produzindo robô... %.1fs restantes" % time_left
	elif production_complete:
		status_label.text = "Robô C.O.R.E. pronto para coleta!"
	else:
		status_label.text = "Fundição pronta. Custo: %d sucata" % PRODUCTION_COST

func _on_produce_pressed():
	var player = GameManager.current_player
	if player.sucata >= PRODUCTION_COST:
		player.sucata -= PRODUCTION_COST
		is_producing = true
		production_timer.start()
		update_display()
		
		print("🏭 Iniciando produção de robô C.O.R.E.")

func _on_production_complete():
	is_producing = false
	production_complete = true
	update_display()
	
	print("🏭 Produção completa!")

func _on_collect_pressed():
	# Criar novo robô usando função interna (evitar duplicate ModelFactory)
	var new_robot = create_robot()
	GameManager.data_manager.robots.append(new_robot)
	
	# Reset produção COMPLETO
	production_complete = false
	is_producing = false
	
	# Parar timer se estiver rodando
	if production_timer.timeout.is_connected(_on_production_complete):
		production_timer.stop()
	
	update_display()
	
	# Salvar jogo
	GameManager.data_manager.save_game()
	
	print("🤖 Robô coletado: " + new_robot.serial_number)

func create_robot() -> RobotData:
	# Criar robô com stats dirigidos SEM usar ModelFactory
	var robot = RobotData.new()
	
	# Escolher modelo e elemento aleatório
	var models = ["LIGHTNING", "GUARDIAN", "SWIFT"]
	var elements = ["COBRE", "FERRO", "ALUMINIO"]
	
	var chosen_model = models.pick_random()
	var chosen_element = elements.pick_random()
	
	# Gerar número de série
	var robot_count = GameManager.data_manager.robots.size() + 1
	var model_code = get_model_code(chosen_model)
	var element_code = get_element_code(chosen_element)
	robot.serial_number = "TKR-%s-%s-%06d" % [element_code, model_code, robot_count]
	
	# Determinar tipo enum
	robot.type = get_robot_type(chosen_element, chosen_model)
	robot.rarity = RobotData.Rarity.COMUM
	
	# Aplicar stats dirigidos manualmente
	apply_model_stats(robot, chosen_model)
	
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	print("🏭 Robô criado: %s %s" % [chosen_element, chosen_model])
	print("📊 Stats: ATK:%d DEF:%d HP:%d SPD:%d" % [
		robot.base_attack, robot.base_defense, robot.base_health, robot.base_speed
	])
	
	return robot

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

func apply_model_stats(robot: RobotData, model: String):
	# Stats dirigidos baseados no database (multiplicador 10x)
	match model:
		"LIGHTNING":  # Balanced
			robot.base_attack = randi_range(7, 10) * 10
			robot.base_special_attack = randi_range(7, 10) * 10
			robot.base_defense = randi_range(7, 10) * 10
			robot.base_special_defense = randi_range(7, 10) * 10
			robot.base_health = randi_range(8, 11) * 10
			robot.base_speed = randi_range(7, 10) * 10
		
		"GUARDIAN":  # Tank
			robot.base_attack = randi_range(5, 7) * 10
			robot.base_special_attack = randi_range(4, 6) * 10
			robot.base_defense = randi_range(10, 13) * 10
			robot.base_special_defense = randi_range(9, 12) * 10
			robot.base_health = randi_range(11, 14) * 10
			robot.base_speed = randi_range(4, 6) * 10
		
		"SWIFT":  # DPS
			robot.base_attack = randi_range(9, 12) * 10
			robot.base_special_attack = randi_range(10, 13) * 10
			robot.base_defense = randi_range(5, 7) * 10
			robot.base_special_defense = randi_range(6, 8) * 10
			robot.base_health = randi_range(6, 9) * 10
			robot.base_speed = randi_range(11, 14) * 10

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
