# Oficina.gd - Gerenciamento de robôs MVP com modelos dirigidos
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
		# Mostrar modelo + ciclos
		button.text = "%s (Ciclos: %d/%d)" % [robot.get_model_display_name(), robot.remaining_cycles, robot.max_cycles]
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
	
	var details_text = """Robô: %s
Serial: %s
Modelo: %s
Elemento: %s
Ciclos: %d/%d

=== STATS FINAIS ===
Ataque: %d
Defesa: %d
Ataque Especial: %d
Defesa Especial: %d
Vida: %d
Velocidade: %d

=== EQUIPAMENTO ===
%s""" % [
		selected_robot.get_model_display_name(),
		selected_robot.serial_number,
		selected_robot.get_model_type(),
		selected_robot.get_element_type(),
		selected_robot.remaining_cycles,
		selected_robot.max_cycles,
		stats.attack,
		stats.defense,
		stats.special_attack,
		stats.special_defense,
		stats.health,
		stats.speed,
		equipped_piece
	]
	
	robot_details_label.text = details_text
	robot_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func get_equipped_piece_details() -> String:
	if selected_robot.equipped_arms == "":
		return "Braço: Nenhum equipado"
	
	var piece = GameManager.data_manager.get_piece_by_id(selected_robot.equipped_arms)
	if piece:
		return "Braço: %s\n  +%d Ataque Especial\n  +%d %s\n  +%d %s\n  Durabilidade: %d/%d" % [
			piece.id,
			piece.primary_stat,
			piece.secondary_stat_1,
			piece.secondary_stat_1_type.capitalize(),
			piece.secondary_stat_2,
			piece.secondary_stat_2_type.capitalize(),
			piece.current_durability,
			piece.max_durability
		]
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
			button.text = "%s (Atq.Esp: +%d)" % [piece.id, piece.primary_stat]
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

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
