# TeamSelection.gd - Sistema de Seleção de Team 2v2
extends Control

# Referencias UI
@onready var title_label: Label = $Header/TitleLabel
@onready var back_button: Button = $Header/BackButton
@onready var robot_list_container: VBoxContainer = $RobotList/ScrollContainer/VBoxContainer
@onready var front_panel: Panel = $TeamPreview/FrontSlot/FrontPanel
@onready var front_label: Label = $TeamPreview/FrontSlot/FrontLabel
@onready var front_robot_info: Label = $TeamPreview/FrontSlot/FrontRobotInfo
@onready var back_panel: Panel = $TeamPreview/BackSlot/BackPanel
@onready var back_label: Label = $TeamPreview/BackSlot/BackLabel
@onready var back_robot_info: Label = $TeamPreview/BackSlot/BackRobotInfo
@onready var start_combat_button: Button = $StartCombatButton

# Estado da seleção
var available_robots: Array[RobotData] = []
var selected_front_robot: RobotData = null
var selected_back_robot: RobotData = null
var robot_buttons: Array[Button] = []

# Seleção atual (FRONT ou BACK)
enum SelectionMode { NONE, SELECTING_FRONT, SELECTING_BACK }
var current_selection_mode: SelectionMode = SelectionMode.NONE

func _ready():
	connect_signals()
	setup_ui_styles()
	load_available_robots()
	update_robot_list()
	update_team_preview()

func connect_signals():
	back_button.pressed.connect(_on_back_pressed)
	start_combat_button.pressed.connect(_on_start_combat_pressed)
	
	# Conectar slots para seleção
	front_panel.gui_input.connect(_on_front_slot_clicked)
	back_panel.gui_input.connect(_on_back_slot_clicked)

func setup_ui_styles():
	"""Configura estilos visuais da interface"""
	
	# Título
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	
	# Estilo dos slots de team
	setup_slot_style(front_panel, Color(0.2, 0.4, 0.6, 0.8))  # Azul para Front
	setup_slot_style(back_panel, Color(0.6, 0.3, 0.2, 0.8))   # Vermelho para Back
	
	# Botão de combate
	start_combat_button.add_theme_font_size_override("font_size", 20)

func setup_slot_style(panel: Panel, color: Color):
	"""Configura estilo visual de um slot"""
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

func load_available_robots():
	"""Carrega robôs disponíveis para seleção"""
	available_robots = GameManager.data_manager.get_active_robots()
	
	print("🤖 Robôs disponíveis para seleção: %d" % available_robots.size())
	
	# Verificar se há robôs suficientes
	if available_robots.size() < 2:
		show_insufficient_robots_error()

func show_insufficient_robots_error():
	"""Mostra erro quando não há robôs suficientes"""
	title_label.text = "❌ ROBÔS INSUFICIENTES"
	title_label.modulate = Color.RED
	
	var error_label = Label.new()
	error_label.text = """⚠️ ATENÇÃO: ROBÔS INSUFICIENTES

Você precisa de pelo menos 2 robôs ativos para combate 2v2.

Robôs disponíveis: %d
Necessários: 2

Vá à Fundição para criar mais robôs!""" % available_robots.size()
	
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 18)
	error_label.add_theme_color_override("font_color", Color.YELLOW)
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	robot_list_container.add_child(error_label)
	
	start_combat_button.text = "❌ ROBÔS INSUFICIENTES"
	start_combat_button.disabled = true

func update_robot_list():
	"""Atualiza lista de robôs disponíveis"""
	
	# Limpar botões existentes
	clear_robot_buttons()
	
	if available_robots.size() < 2:
		return  # Erro já mostrado
	
	# Adicionar instrução
	var instruction_label = Label.new()
	instruction_label.text = "📋 INSTRUÇÕES:\n1. Clique em um SLOT (Front/Back)\n2. Selecione um ROBÔ da lista\n3. Repita para o outro slot"
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color.YELLOW)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	robot_list_container.add_child(instruction_label)
	
	# Adicionar separador
	var separator = HSeparator.new()
	robot_list_container.add_child(separator)
	
	# Criar botão para cada robô
	for robot in available_robots:
		var button = create_robot_button(robot)
		robot_list_container.add_child(button)
		robot_buttons.append(button)

func create_robot_button(robot: RobotData) -> Button:
	"""Cria botão para um robô específico"""
	var button = Button.new()
	
	# Texto do botão com informações do robô
	var stats = robot.get_final_stats()
	button.text = """🤖 %s
Serial: %s
Ciclos: %d/%d
ATK:%d DEF:%d HP:%d SPD:%d""" % [
		robot.get_model_display_name(),
		robot.serial_number,
		robot.remaining_cycles,
		robot.max_cycles,
		stats.attack,
		stats.defense,
		stats.health,
		stats.speed
	]
	
	# Configurar botão
	button.custom_minimum_size = Vector2(0, 120)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_on_robot_selected.bind(robot))
	
	# Estilo baseado na raridade (futuro)
	setup_robot_button_style(button, robot)
	
	return button

func setup_robot_button_style(button: Button, robot: RobotData):
	"""Configura estilo visual do botão do robô"""
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.12, 0.1, 0.9)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = robot.get_rarity_color()
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.25, 0.22, 0.18, 0.9)
	hover_style.border_width_left = 3
	hover_style.border_width_right = 3
	hover_style.border_width_top = 3
	hover_style.border_width_bottom = 3
	hover_style.border_color = robot.get_rarity_color()
	hover_style.corner_radius_top_left = 5
	hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_left = 5
	hover_style.corner_radius_bottom_right = 5
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color.WHITE)

func clear_robot_buttons():
	"""Limpa todos os botões de robô"""
	for child in robot_list_container.get_children():
		child.queue_free()
	robot_buttons.clear()

func _on_front_slot_clicked(event: InputEvent):
	"""Handler para clique no slot Front"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if available_robots.size() >= 2:
			set_selection_mode(SelectionMode.SELECTING_FRONT)

func _on_back_slot_clicked(event: InputEvent):
	"""Handler para clique no slot Back"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if available_robots.size() >= 2:
			set_selection_mode(SelectionMode.SELECTING_BACK)

func set_selection_mode(mode: SelectionMode):
	"""Define modo de seleção atual"""
	current_selection_mode = mode
	
	# Atualizar visual dos slots
	match mode:
		SelectionMode.SELECTING_FRONT:
			highlight_slot(front_panel, true)
			highlight_slot(back_panel, false)
			title_label.text = "👆 SELECIONE ROBÔ PARA FRONT"
		SelectionMode.SELECTING_BACK:
			highlight_slot(front_panel, false)
			highlight_slot(back_panel, true)
			title_label.text = "👆 SELECIONE ROBÔ PARA BACK"
		SelectionMode.NONE:
			highlight_slot(front_panel, false)
			highlight_slot(back_panel, false)
			title_label.text = "⚔️ SELEÇÃO DE TEAM 2v2"
	
	# Atualizar disponibilidade dos botões de robô
	update_robot_button_availability()

func highlight_slot(panel: Panel, highlight: bool):
	"""Destaca ou remove destaque de um slot"""
	var style = panel.get_theme_stylebox("panel").duplicate()
	if highlight:
		style.border_color = Color.YELLOW
		style.border_width_left = 5
		style.border_width_right = 5
		style.border_width_top = 5
		style.border_width_bottom = 5
	else:
		style.border_color = Color(1.0, 0.8, 0.4, 1.0)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
	
	panel.add_theme_stylebox_override("panel", style)

func update_robot_button_availability():
	"""Atualiza disponibilidade dos botões baseado na seleção atual"""
	for i in range(robot_buttons.size()):
		var button = robot_buttons[i]
		var robot = available_robots[i]
		
		# Verificar se robô já foi selecionado
		var already_selected = (robot == selected_front_robot or robot == selected_back_robot)
		
		if current_selection_mode == SelectionMode.NONE:
			button.disabled = true
			button.modulate = Color.GRAY
		elif already_selected:
			button.disabled = true
			button.modulate = Color.DARK_GRAY
		else:
			button.disabled = false
			button.modulate = Color.WHITE

func _on_robot_selected(robot: RobotData):
	"""Handler para seleção de robô"""
	
	match current_selection_mode:
		SelectionMode.SELECTING_FRONT:
			selected_front_robot = robot
			print("🛡️ Front selecionado: %s" % robot.get_model_display_name())
		SelectionMode.SELECTING_BACK:
			selected_back_robot = robot
			print("⚔️ Back selecionado: %s" % robot.get_model_display_name())
		_:
			print("⚠️ Nenhum slot selecionado!")
			return
	
	# Voltar ao modo normal
	set_selection_mode(SelectionMode.NONE)
	
	# Atualizar preview
	update_team_preview()
	
	# Verificar se pode iniciar combate
	check_combat_ready()

func update_team_preview():
	"""Atualiza preview do team selecionado"""
	
	# Atualizar Front
	if selected_front_robot:
		var stats = selected_front_robot.get_final_stats()
		front_robot_info.text = """✅ %s
Serial: %s
Raridade: %s
Ciclos: %d/%d

📊 STATS FINAIS:
ATK: %d (+10%% pos) | DEF: %d (+10%% pos)
ATK-ESP: %d | DEF-ESP: %d (+10%% pos)
VIDA: %d (+10%% pos) | VEL: %d

🛡️ ROLE: TANQUE
Recebe +10%% em defesas""" % [
			selected_front_robot.get_model_display_name(),
			selected_front_robot.serial_number,
			selected_front_robot.get_rarity_name(),
			selected_front_robot.remaining_cycles,
			selected_front_robot.max_cycles,
			stats.attack,
			stats.defense,
			stats.special_attack,
			stats.special_defense,
			stats.health,
			stats.speed
		]
		front_robot_info.modulate = Color.WHITE
	else:
		front_robot_info.text = "👆 Clique aqui e selecione um robô para posição FRONT"
		front_robot_info.modulate = Color.YELLOW
	
	# Atualizar Back
	if selected_back_robot:
		var stats = selected_back_robot.get_final_stats()
		back_robot_info.text = """✅ %s
Serial: %s
Raridade: %s
Ciclos: %d/%d

📊 STATS FINAIS:
ATK: %d (+10%% pos) | DEF: %d
ATK-ESP: %d (+10%% pos) | DEF-ESP: %d
VIDA: %d | VEL: %d

⚔️ ROLE: DPS
Recebe +10%% em ataques""" % [
			selected_back_robot.get_model_display_name(),
			selected_back_robot.serial_number,
			selected_back_robot.get_rarity_name(),
			selected_back_robot.remaining_cycles,
			selected_back_robot.max_cycles,
			stats.attack,
			stats.defense,
			stats.special_attack,
			stats.special_defense,
			stats.health,
			stats.speed
		]
		back_robot_info.modulate = Color.WHITE
	else:
		back_robot_info.text = "👆 Clique aqui e selecione um robô para posição BACK"
		back_robot_info.modulate = Color.YELLOW

func check_combat_ready():
	"""Verifica se o combate pode ser iniciado"""
	var ready = (selected_front_robot != null and selected_back_robot != null)
	
	start_combat_button.disabled = not ready
	
	if ready:
		start_combat_button.text = "🥊 INICIAR COMBATE 2v2"
		start_combat_button.modulate = Color.WHITE
		print("✅ Team pronto para combate!")
	else:
		start_combat_button.text = "⏳ Selecione 2 robôs..."
		start_combat_button.modulate = Color.GRAY

func _on_start_combat_pressed():
	"""Inicia o combate com o team selecionado"""
	
	if not selected_front_robot or not selected_back_robot:
		print("❌ Team incompleto!")
		return
	
	# Armazenar seleção no GameManager para usar no CombatScene
	GameManager.selected_team = [selected_front_robot, selected_back_robot]
	
	print("🥊 Iniciando combate com team:")
	print("  Front: %s" % selected_front_robot.get_model_display_name())
	print("  Back: %s" % selected_back_robot.get_model_display_name())
	
	# Ir para cena de combate
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _on_back_pressed():
	"""Volta para o MainHub"""
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
