# GameManager.gd - Singleton para MVP (COMPLETO com seleção de posição)
extends Node

var current_player: PlayerData
var data_manager: DataManager

# Propriedades de seleção
var selected_team: Array[RobotData] = []  # [front_robot, back_robot]
var selected_position: String = ""        # "FRONT" ou "BACK" para combate 1v2

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
	
	# Criar robô inicial gratuito com stats dirigidos
	var initial_robot = create_initial_robot()
	data_manager.robots.append(initial_robot)
	
	print("🆕 Novo jogador criado com robô inicial")
	return player

func create_initial_robot() -> RobotData:
	var robot = RobotData.new()
	robot.serial_number = "TKR-COP-LGT-000001"  # Lightning inicial
	robot.type = RobotData.Type.COBRE_LIGHTNING
	robot.rarity = RobotData.Rarity.COMUM
	
	# Stats dirigidos Lightning (balanced)
	robot.base_attack = 80
	robot.base_defense = 70
	robot.base_special_attack = 85
	robot.base_special_defense = 65
	robot.base_health = 100
	robot.base_speed = 75
	
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	print("🤖 Robô inicial criado: COBRE LIGHTNING")
	return robot

func clear_team_selection():
	"""Limpa seleção de team e posição"""
	selected_team.clear()
	selected_position = ""
	print("🧹 Seleção de team e posição limpa")
