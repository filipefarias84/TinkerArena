# MainHub.gd - Interface Visual Melhorada com Background (COMPLETO)
extends Control

# Referências dos botões (agora posicionados sobre os prédios)
@onready var sucata_label: Label = $Header/SucataLabel
@onready var fundicao_btn: Button = $FundicaoButton
@onready var arsenal_btn: Button = $ArsenalButton
@onready var oficina_btn: Button = $OficinaButton
@onready var bancada_btn: Button = $BancadaButton
@onready var combat_btn: Button = $CombatButton

# Background
@onready var background: TextureRect = $Background

func _ready():
	# Aguardar um frame para GameManager estar inicializado
	await get_tree().process_frame
	setup_visual_interface()
	connect_signals()
	update_ui()
	print("🏠 MainHub carregado com interface visual")

func setup_visual_interface():
	"""Configura a interface visual melhorada"""
	
	# Configurar background se a imagem existir
	if background:
		# A imagem será configurada na scene (.tscn)
		background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		background.z_index = -1  # Garantir que fica atrás de tudo
	
	# Configurar estilo dos botões para melhor visibilidade
	setup_button_styles()

func setup_button_styles():
	"""Configura estilo visual dos botões para melhor contraste"""
	
	var buttons = [fundicao_btn, arsenal_btn, oficina_btn, bancada_btn, combat_btn]
	
	for button in buttons:
		if button:
			# Criar StyleBox para botão normal
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(0.2, 0.15, 0.1, 0.85)  # Marrom escuro semi-transparente
			normal_style.border_width_left = 2
			normal_style.border_width_right = 2
			normal_style.border_width_top = 2
			normal_style.border_width_bottom = 2
			normal_style.border_color = Color(0.8, 0.6, 0.3, 1.0)  # Dourado
			normal_style.corner_radius_top_left = 8
			normal_style.corner_radius_top_right = 8
			normal_style.corner_radius_bottom_left = 8
			normal_style.corner_radius_bottom_right = 8
			
			# Criar StyleBox para botão hover
			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = Color(0.3, 0.25, 0.15, 0.9)  # Marrom mais claro
			hover_style.border_width_left = 3
			hover_style.border_width_right = 3
			hover_style.border_width_top = 3
			hover_style.border_width_bottom = 3
			hover_style.border_color = Color(1.0, 0.8, 0.4, 1.0)  # Dourado mais brilhante
			hover_style.corner_radius_top_left = 8
			hover_style.corner_radius_top_right = 8
			hover_style.corner_radius_bottom_left = 8
			hover_style.corner_radius_bottom_right = 8
			
			# Aplicar estilos
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_stylebox_override("hover", hover_style)
			button.add_theme_stylebox_override("pressed", hover_style)
			
			# Configurar fonte
			button.add_theme_font_size_override("font_size", 18)
			button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))  # Texto dourado claro
			button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8, 1.0))

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
	
	# Atualizar label de sucata com estilo visual
	var player = GameManager.current_player
	sucata_label.text = "⚙️ Sucata: %d" % player.sucata
	
	# Configurar estilo da label de sucata
	sucata_label.add_theme_font_size_override("font_size", 24)
	sucata_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4, 1.0))
	
	# Verificar se data_manager existe
	if not GameManager.data_manager:
		print("⚠️ DataManager não inicializado")
		combat_btn.disabled = true
		combat_btn.text = "CARREGANDO..."
		return
	
	# Verificar se há robôs ativos para combate
	var active_robots = GameManager.data_manager.get_active_robots()
	combat_btn.disabled = active_robots.is_empty()
	
	if combat_btn.disabled:
		combat_btn.text = "SEM ROBÔS"
	else:
		if active_robots.size() >= 2:
			combat_btn.text = "COMBATE 2v2\n(%d robôs)" % active_robots.size()
		else:
			combat_btn.text = "COMBATE 1v1\n(%d robô)" % active_robots.size()

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
	print("🛠️ Acessando Bancada")
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
	
	if active_robots.size() == 1:
		print("⚠️ Apenas 1 robô disponível - abrindo modal de escolha")
		# Ir para modal de escolha com 1 robô
		get_tree().change_scene_to_file("res://scenes/SingleRobotModal.tscn")
	else:
		print("👥 %d robôs disponíveis - indo para seleção de team" % active_robots.size())
		# Para 2+ robôs, ir para tela de seleção normal
		get_tree().change_scene_to_file("res://scenes/TeamSelection.tscn")
