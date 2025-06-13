# SingleRobotModal.gd - Modal de escolha para 1 robô
extends Control

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Title
@onready var message_label: Label = $Panel/Message
@onready var fight_button: Button = $Panel/FightButton
@onready var forge_button: Button = $Panel/ForgeButton
@onready var cancel_button: Button = $Panel/CancelButton

var single_robot: RobotData

func _ready():
	setup_ui_style()
	connect_signals()
	load_robot_info()

func setup_ui_style():
	"""Configura estilo visual do modal"""
	
	# Título
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.ORANGE)
	
	# Mensagem
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Estilo do painel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.12, 0.1, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.8, 0.6, 0.3, 1.0)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Estilo dos botões
	setup_button_style(fight_button, Color(0.2, 0.6, 0.8, 0.9))    # Azul
	setup_button_style(forge_button, Color(0.8, 0.4, 0.2, 0.9))    # Laranja  
	setup_button_style(cancel_button, Color(0.6, 0.2, 0.2, 0.9))   # Vermelho

func setup_button_style(button: Button, color: Color):
	"""Configura estilo de um botão específico"""
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color.WHITE
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.lightened(0.2)
	hover_style.border_width_left = 3
	hover_style.border_width_right = 3
	hover_style.border_width_top = 3
	hover_style.border_width_bottom = 3
	hover_style.border_color = Color.YELLOW
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)

func connect_signals():
	"""Conecta sinais dos botões"""
	fight_button.pressed.connect(_on_fight_pressed)
	forge_button.pressed.connect(_on_forge_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func load_robot_info():
	"""Carrega informações do robô único"""
	var active_robots = GameManager.data_manager.get_active_robots()
	
	if active_robots.size() != 1:
		print("❌ ERRO: Modal chamado sem exatamente 1 robô!")
		_on_cancel_pressed()
		return
	
	single_robot = active_robots[0]
	
	# Atualizar mensagem com info do robô
	var stats = single_robot.get_final_stats()
	message_label.text = """Você possui apenas 1 robô ativo para combate:

🤖 %s
Serial: %s | Ciclos: %d/%d
ATK:%d DEF:%d HP:%d SPD:%d

Escolha uma das opções:

🤖 LUTAR: Combate 1v2 (você escolhe posição Front ou Back)
🏭 CRIAR: Ir para Fundição fabricar outro robô  
🏠 CANCELAR: Voltar para tela inicial""" % [
		single_robot.get_model_display_name(),
		single_robot.serial_number,
		single_robot.remaining_cycles,
		single_robot.max_cycles,
		stats.attack,
		stats.defense,
		stats.health,
		stats.speed
	]

func _on_fight_pressed():
	"""Jogador escolheu lutar com 1 robô"""
	print("🤖 Jogador escolheu lutar com 1 robô")
	
	# Ir para tela de seleção de posição
	get_tree().change_scene_to_file("res://scenes/SingleRobotPosition.tscn")

func _on_forge_pressed():
	"""Jogador escolheu ir para fundição"""
	print("🏭 Jogador foi para fundição")
	
	# Ir direto para fundição
	get_tree().change_scene_to_file("res://scenes/Fundicao.tscn")

func _on_cancel_pressed():
	"""Jogador cancelou ação"""
	print("🏠 Jogador cancelou combate")
	
	# Voltar para MainHub
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
