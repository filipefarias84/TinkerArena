# Oficina.gd - Feedback Visual Melhorado + Sistema de Raridades
extends Control

@onready var back_btn: Button = $BackButton
@onready var robot_list_label: Label = $RobotListLabels
@onready var robot_details_label: Label = $RobotDetailsLabel
@onready var robot_scroll: ScrollContainer = $RobotScrollContainer
@onready var equip_btn: Button = $EquipButton
@onready var unequip_btn: Button = $UnequipButton
@onready var piece_selection_panel: Control = $PieceSelectionPanel
@onready var piece_list: VBoxContainer = $PieceSelectionPanel/PieceList
@onready var close_panel_btn: Button = $PieceSelectionPanel/CloseButton

var piece_buttons: Array[Button] = []
var selected_piece_for_equip: PieceData
var robot_buttons: Array[Button] = []
var selected_robot: RobotData

func _ready():
	connect_signals()
	setup_robot_list()
	setup_equipment_ui()
	update_robot_list()

func connect_signals():
	back_btn.pressed.connect(_on_back_pressed)
	equip_btn.pressed.connect(_on_equip_pressed)
	unequip_btn.pressed.connect(_on_unequip_pressed)
	close_panel_btn.pressed.connect(_on_close_panel_pressed)

func setup_robot_list():
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(240, 0)
	robot_scroll.add_child(vbox)

func setup_equipment_ui():
	equip_btn.visible = false
	unequip_btn.visible = false
	piece_selection_panel.visible = false

func update_robot_list():
	clear_robot_buttons()
	
	var active_robots = GameManager.data_manager.get_active_robots()
	var vbox = robot_scroll.get_child(0) as VBoxContainer
	
	if active_robots.is_empty():
		var no_robots_label = Label.new()
		no_robots_label.text = "Nenhum robô disponível.\nVá à Fundição para criar um!"
		vbox.add_child(no_robots_label)
		robot_details_label.text = "Selecione um robô para ver detalhes"
		return
	
	for robot in active_robots:
		var button = Button.new()
		
		# 🆕 VISUAL MELHORADO COM RARIDADE E CORES
		var display_text = "%s\n%s (Ciclos: %d/%d)" % [
			robot.get_model_display_name(),
			robot.get_rarity_name(),
			robot.remaining_cycles,
			robot.max_cycles
		]
		
		button.text = display_text
		button.modulate = robot.get_rarity_color()
		button.pressed.connect(_on_robot_selected.bind(robot))
		
		vbox.add_child(button)
		robot_buttons.append(button)

func clear_robot_buttons():
	var vbox = robot_scroll.get_child(0) as VBoxContainer
	for child in vbox.get_children():
		child.queue_free()
	robot_buttons.clear()

func _on_robot_selected(robot: RobotData):
	selected_robot = robot
	update_robot_details()
	update_equipment_buttons()

func update_robot_details():
	if not selected_robot:
		return
	
	var stats = selected_robot.get_final_stats()
	var equipped_piece = get_equipped_piece_details()
	
	# 🆕 DETALHES MELHORADOS COM CORES E RARIDADE
	var details_text = """🤖 ROBÔ: %s
📋 Serial: %s
⚡ Modelo: %s
🔧 Elemento: %s
✨ Raridade: %s
🔄 Ciclos: %d/%d

=== 📊 STATS FINAIS ===
%s
%s
%s
%s
%s
%s

=== 🎒 EQUIPAMENTO ===
%s

%s""" % [
		selected_robot.get_model_display_name(),
		selected_robot.serial_number,
		selected_robot.get_model_type(),
		selected_robot.get_element_type(),
		selected_robot.get_rarity_name(),
		selected_robot.remaining_cycles,
		selected_robot.max_cycles,
		format_stat_with_color("Ataque", stats.attack),
		format_stat_with_color("Defesa", stats.defense),
		format_stat_with_color("Ataque Especial", stats.special_attack),
		format_stat_with_color("Defesa Especial", stats.special_defense),
		format_stat_with_color("Vida", stats.health),
		format_stat_with_color("Velocidade", stats.speed),
		equipped_piece,
		get_legendary_ability_text()
	]
	
	robot_details_label.text = details_text
	robot_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 🆕 APLICAR COR DA RARIDADE AO LABEL
	robot_details_label.modulate = selected_robot.get_rarity_color()

# 🆕 SISTEMA DE CORES PARA STATS
func format_stat_with_color(stat_name: String, value: int) -> String:
	var color_indicator = get_stat_color_indicator(value)
	return "%s %s: %d" % [color_indicator, stat_name, value]

func get_stat_color_indicator(value: int) -> String:
	# Sistema de cores baseado no database
	if value >= 160:
		return "🟣"  # Roxo - Excepcional (16-18 * 10)
	elif value >= 130:
		return "🔵"  # Azul - Muito Alto (13-15 * 10)
	elif value >= 100:
		return "🟢"  # Verde - Alto (10-12 * 10)
	elif value >= 70:
		return "🟡"  # Amarelo - Normal (7-9 * 10)
	elif value >= 40:
		return "🟠"  # Laranja - Baixo (4-6 * 10)
	else:
		return "🔴"  # Vermelho - Muito Baixo (1-3 * 10)

func get_legendary_ability_text() -> String:
	if selected_robot.rarity != RobotData.Rarity.LENDARIO:
		return ""
	
	var ability = selected_robot.get_legendary_ability()
	if ability.is_empty():
		return ""
	
	return """
=== 🌟 HABILIDADE LENDÁRIA ===
🏆 %s
📝 %s
🎯 Chance: %.0f%%""" % [
		ability.name,
		ability.description,
		ability.proc_chance * 100
	]

func get_equipped_piece_details() -> String:
	if selected_robot.equipped_arms == "":
		return "Braço: Nenhum equipado"
	
	var piece = GameManager.data_manager.get_piece_by_id(selected_robot.equipped_arms)
	if piece:
		# 🆕 DETALHES MELHORADOS DA PEÇA
		var piece_text = """🦾 Braço: %s (%s)
   %s +%d Ataque Especial
   %s +%d %s
   %s +%d %s
   🔧 Durabilidade: %d/%d""" % [
			piece.id,
			piece.get_rarity_name(),
			get_stat_color_indicator(piece.primary_stat),
			piece.primary_stat,
			get_stat_color_indicator(piece.secondary_stat_1),
			piece.secondary_stat_1,
			piece.secondary_stat_1_type.capitalize(),
			get_stat_color_indicator(piece.secondary_stat_2),
			piece.secondary_stat_2,
			piece.secondary_stat_2_type.capitalize(),
			piece.current_durability,
			piece.max_durability
		]
		
		# Adicionar efeito lendário se existir
		if piece.rarity == PieceData.Rarity.LENDARIO:
			var effect = piece.get_legendary_effect()
			if not effect.is_empty():
				piece_text += "\n   🌟 " + effect.description
		
		return piece_text
	else:
		return "Braço: ERRO - peça não encontrada"

func update_equipment_buttons():
	if not selected_robot:
		equip_btn.visible = false
		unequip_btn.visible = false
		return
	
	var available_pieces = get_available_pieces()
	equip_btn.visible = not available_pieces.is_empty()
	unequip_btn.visible = selected_robot.equipped_arms != ""

func get_available_pieces() -> Array:
	var available = []
	
	if not GameManager or not GameManager.data_manager:
		print("⚠️ GameManager ou DataManager não inicializados")
		return available
	
	if not GameManager.data_manager.pieces:
		print("⚠️ Lista de peças não inicializada")
		return available
	
	for piece in GameManager.data_manager.pieces:
		if piece and piece.part_type == PieceData.PartType.BRAÇOS and not is_piece_equipped(piece.id):
			available.append(piece)
	
	return available

func is_piece_equipped(piece_id: String) -> bool:
	if not GameManager or not GameManager.data_manager:
		return false
	
	if not GameManager.data_manager.robots:
		return false
	
	for robot in GameManager.data_manager.robots:
		if robot and robot.equipped_arms == piece_id:
			return true
	return false

func _on_equip_pressed():
	show_piece_selection_panel()

func _on_unequip_pressed():
	if not selected_robot or selected_robot.equipped_arms == "":
		return
	
	print("🔧 Desequipando peça: " + selected_robot.equipped_arms)
	selected_robot.equipped_arms = ""
	
	update_robot_details()
	update_equipment_buttons()
	GameManager.data_manager.save_game()
	show_equipment_feedback("Peça desequipada!")

func _on_close_panel_pressed():
	piece_selection_panel.visible = false

func _on_piece_selected_for_equip(piece: PieceData):
	selected_piece_for_equip = piece
	equip_piece_to_robot()

func show_piece_selection_panel():
	clear_piece_buttons()
	
	var available_pieces = get_available_pieces()
	
	if available_pieces.is_empty():
		var no_pieces_label = Label.new()
		no_pieces_label.text = "Nenhuma peça disponível!\nVá ao Arsenal para criar uma."
		piece_list.add_child(no_pieces_label)
	else:
		for piece in available_pieces:
			var button = Button.new()
			
			# 🆕 VISUAL MELHORADO DAS PEÇAS
			var piece_text = "%s (%s)\n%s Atq.Esp: +%d" % [
				piece.id,
				piece.get_rarity_name(),
				get_stat_color_indicator(piece.primary_stat),
				piece.primary_stat
			]
			
			button.text = piece_text
			button.modulate = piece.get_rarity_color()
			button.pressed.connect(_on_piece_selected_for_equip.bind(piece))
			
			piece_list.add_child(button)
			piece_buttons.append(button)
	
	piece_selection_panel.visible = true

func clear_piece_buttons():
	for child in piece_list.get_children():
		child.queue_free()
	piece_buttons.clear()

func equip_piece_to_robot():
	if not selected_robot or not selected_piece_for_equip:
		return
	
	if selected_robot.equipped_arms != "":
		print("🔧 Desequipando peça anterior: " + selected_robot.equipped_arms)
	
	selected_robot.equipped_arms = selected_piece_for_equip.id
	print("🔧 Peça equipada: %s em %s" % [selected_piece_for_equip.id, selected_robot.serial_number])
	
	piece_selection_panel.visible = false
	update_robot_details()
	update_equipment_buttons()
	GameManager.data_manager.save_game()
	show_equipment_feedback("Peça equipada com sucesso!")

func show_equipment_feedback(message: String):
	print("✅ " + message)
	
	# 🆕 FEEDBACK VISUAL NA TELA
	var feedback_label = Label.new()
	feedback_label.text = "✅ " + message
	feedback_label.modulate = Color.GREEN
	feedback_label.position = Vector2(500, 300)
	feedback_label.z_index = 100
	add_child(feedback_label)
	
	# Animar e remover após 2 segundos
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(feedback_label.queue_free)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
