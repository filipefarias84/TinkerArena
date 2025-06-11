# Fundicao.gd - Produção de robôs MVP
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
		status_label.text = "Robô Cobre pronto para coleta!"
	else:
		status_label.text = "Fundição pronta. Custo: %d sucata" % PRODUCTION_COST

func _on_produce_pressed():
	var player = GameManager.current_player
	if player.sucata >= PRODUCTION_COST:
		player.sucata -= PRODUCTION_COST
		is_producing = true
		production_timer.start()
		update_display()
		
		print("🏭 Iniciando produção de robô Cobre")

func _on_production_complete():
	is_producing = false
	production_complete = true
	update_display()
	
	print("🏭 Produção completa!")

func _on_collect_pressed():
	# Criar novo robô
	var new_robot = create_robot()
	GameManager.data_manager.robots.append(new_robot)
	
	# Reset produção COMPLETO
	production_complete = false
	is_producing = false  # <- Garantir reset total
	
	# Parar timer se estiver rodando
	if production_timer.timeout.is_connected(_on_production_complete):
		production_timer.stop()
	
	update_display()
	
	# Salvar jogo
	GameManager.data_manager.save_game()
	
	print("🤖 Robô coletado: " + new_robot.serial_number)

func create_robot() -> RobotData:
	var robot = RobotData.new()
	
	# Gerar número de série simples
	var robot_count = GameManager.data_manager.robots.size() + 1
	robot.serial_number = "TKR-COP-S01-%06d" % robot_count
	
	robot.type = RobotData.Type.COBRE
	robot.rarity = RobotData.Rarity.COMUM
	
	# Stats fixos com pequena variação (+/- 5)
	robot.base_attack = 100 + randi_range(-5, 5)
	robot.base_defense = 80 + randi_range(-5, 5)
	robot.base_special_attack = 90 + randi_range(-5, 5)
	robot.base_special_defense = 75 + randi_range(-5, 5)
	robot.base_health = 150 + randi_range(-10, 10)
	robot.base_speed = 60 + randi_range(-5, 5)
	
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	return robot

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _process(_delta):
	if is_producing:
		update_display()
