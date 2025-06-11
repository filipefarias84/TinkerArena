# GameManager.gd - Singleton para MVP
extends Node

var current_player: PlayerData
var data_manager: DataManager

func _ready():
	initialize_mvp_systems()
	load_or_create_player()
	print("🎮 GameManager MVP iniciado")

func initialize_mvp_systems():
	data_manager = DataManager.new()
	add_child(data_manager)

func load_or_create_player():
	current_player = data_manager.load_player_data()
	if not current_player:
		current_player = create_new_player()
	
	print("👤 Jogador carregado - Sucata: %d" % current_player.sucata)
	data_manager.save_game()

func create_new_player() -> PlayerData:
	var player = PlayerData.new()
	player.tinker_name = "Novo Tinker"
	player.level = 1
	player.sucata = 200  # Sucata inicial
	
	# Criar robô inicial gratuito
	var initial_robot = create_initial_robot()
	data_manager.robots.append(initial_robot)
	
	print("🆕 Novo jogador criado com robô inicial")
	return player

func create_initial_robot() -> RobotData:
	var robot = RobotData.new()
	robot.serial_number = "TKR-COP-S01-000001"
	robot.type = RobotData.Type.COBRE
	robot.rarity = RobotData.Rarity.COMUM
	
	# Stats fixos para MVP
	robot.base_attack = 100
	robot.base_defense = 80
	robot.base_special_attack = 90
	robot.base_special_defense = 75
	robot.base_health = 150
	robot.base_speed = 60
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	return robot
