# SingleRobotPosition.gd - Seleção de posição para combate 1v2
extends Control

@onready var title_label: Label = $Header/TitleLabel
@onready var back_button: Button = $Header/BackButton
@onready var robot_panel: Panel = $RobotInfo/RobotPanel
@onready var robot_label: Label = $RobotInfo/RobotLabel
@onready var front_panel: Panel = $PositionChoice/FrontOption/FrontPanel
@onready var front_button: Button = $PositionChoice/FrontOption/FrontButton
@onready var back_panel: Panel = $PositionChoice/BackOption/BackPanel
@onready var back_button_pos: Button = $PositionChoice/BackOption/BackButton

var single_robot: RobotData

func _ready():
	connect_signals()
	setup_ui_styles()
	load_robot_info()

func connect_signals():
	back_button.pressed.connect(_on_back_pressed)
	front_button.pressed.connect(_on_front_selected)
	back_button_pos.pressed.connect(_on_back_selected)

func setup_ui_styles():
	"""Configura estilos visuais"""
	
	# Título
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	
	# Painel do robô
	var robot_style = StyleBoxFlat.new()
	robot_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	robot_style.border_width_left = 3
	robot_style.border_width_right = 3
	robot_style.border_width_top = 3
	robot_style.border_width_bottom = 3
	robot_style.border_color = Color(0.8, 0.6, 0.3, 1.0)
	robot_style.corner_radius_top_left = 10
	robot_style.corner_radius_top_right = 10
	robot_style.corner_radius_bottom_left = 10
	robot_style.corner_radius_bottom_right = 10
	
	robot_panel.add_theme_stylebox_override("panel", robot_style)
	
	# Painéis de posição
	setup_position_panel(front_panel, Color(0.2, 0.4, 0.6, 0.8))   # Azul para Front
	setup_position_panel(back_panel, Color(0.6, 0.3, 0.2, 0.8))    # Vermelho para Back
	
	# Botões de posição
	setup_position_button(front_button)
	setup_position_button(back_button_pos)

func setup_position_panel(panel: Panel, color: Color):
	"""Configura estilo de um painel de posição"""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.8, 0.4, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	
	panel.add_theme_stylebox_override("panel", style)

func setup_position_button(button: Button):
	"""Configura estilo de um botão de posição"""
	# Tornar fundo transparente para mostrar o painel
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1, 1, 1, 0.1)
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color.YELLOW
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	
	button.add_theme_stylebox_override("normal", transparent_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.YELLOW)

func load_robot_info():
	"""Carrega e exibe informações do robô"""
	var active_robots = GameManager.data_manager.get_active_robots()
	
	if active_robots.size() != 1:
		print("❌ ERRO: Posição chamada sem exatamente 1 robô!")
		_on_back_pressed()
		return
	
	single_robot = active_robots[0]
	
	# Mostrar informações detalhadas
	var stats = single_robot.get_final_stats()
	robot_label.text = """🤖 SEU ROBÔ PARA COMBATE 1v2

%s
Serial: %s
Raridade: %s
Ciclos: %d/%d

📊 STATS BASE:
Ataque: %d | Defesa: %d
Ataque Especial: %d | Defesa Especial: %d  
Vida: %d | Velocidade: %d

⚠️ COMBATE 1v2: Você enfrentará 2 inimigos sozinho!
Escolha sua posição estratégica wisely.

🛡️ FRONT: Melhor defesa, mas recebe ataques primeiro
⚔️ BACK: Melhor ataque, mas fica vulnerável se não houver tanque""" % [
		single_robot.get_model_display_name(),
		single_robot.serial_number,
		single_robot.get_rarity_name(),
		single_robot.remaining_cycles,
		single_robot.max_cycles,
		stats.attack,
		stats.defense,
		stats.special_attack,
		stats.special_defense,
		stats.health,
		stats.speed
	]
	
	robot_label.add_theme_font_size_override("font_size", 16)
	robot_label.add_theme_color_override("font_color", Color.WHITE)

func _on_front_selected():
	"""Jogador escolheu posição Front"""
	print("🛡️ Jogador escolheu posição FRONT")
	
	# Configurar team com robô na frente (duplicado atrás como placeholder)
	GameManager.selected_team = [single_robot, single_robot]
	GameManager.selected_position = "FRONT"  # Nova variável para indicar posição principal
	
	# Ir para combate
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _on_back_selected():
	"""Jogador escolheu posição Back"""
	print("⚔️ Jogador escolheu posição BACK")
	
	# Configurar team com robô atrás (duplicado na frente como placeholder)
	GameManager.selected_team = [single_robot, single_robot]
	GameManager.selected_position = "BACK"  # Nova variável para indicar posição principal
	
	# Ir para combate
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _on_back_pressed():
	"""Volta para o modal de escolha"""
	get_tree().change_scene_to_file("res://scenes/SingleRobotModal.tscn")
