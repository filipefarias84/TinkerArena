# Bancada.gd - Inventário de peças com raridades corrigidas
extends Control

@onready var back_btn: Button = $BackButton
@onready var piece_list_label: Label = $PieceListLabel
@onready var piece_details_label: Label = $PieceDetailsLabel
@onready var piece_scroll: ScrollContainer = $PieceScrollContainer
@onready var equip_btn: Button = $EquipButton

var piece_buttons: Array[Button] = []
var selected_piece: PieceData

func _ready():
	connect_signals()
	setup_piece_list()
	update_piece_list()

func connect_signals():
	back_btn.pressed.connect(_on_back_pressed)
	equip_btn.pressed.connect(_on_equip_pressed)

func setup_piece_list():
	# Criar VBoxContainer dentro do ScrollContainer
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 0)
	piece_scroll.add_child(vbox)

func update_piece_list():
	# Limpar botões existentes
	clear_piece_buttons()
	
	# Obter todas as peças
	var all_pieces = GameManager.data_manager.pieces
	var vbox = piece_scroll.get_child(0) as VBoxContainer
	
	if all_pieces.is_empty():
		var no_pieces_label = Label.new()
		no_pieces_label.text = "Nenhuma peça disponível.\nVá ao Arsenal para criar uma!"
		vbox.add_child(no_pieces_label)
		piece_details_label.text = "Selecione uma peça para ver detalhes"
		equip_btn.visible = false
		return
	
	# 🆕 CRIAR BOTÃO COM RARIDADE CORRETA
	for piece in all_pieces:
		var button = Button.new()
		
		# Mostrar raridade correta + cor
		var display_text = "%s (%s)\nDurabilidade: %d/%d" % [
			piece.id, 
			piece.get_rarity_name(),  # 🔧 CORREÇÃO: usar função do PieceData
			piece.current_durability, 
			piece.max_durability
		]
		
		button.text = display_text
		button.modulate = piece.get_rarity_color()  # 🔧 CORREÇÃO: aplicar cor
		button.pressed.connect(_on_piece_selected.bind(piece))
		
		vbox.add_child(button)
		piece_buttons.append(button)
	
	equip_btn.visible = false
	
func clear_piece_buttons():
	var vbox = piece_scroll.get_child(0) as VBoxContainer
	for child in vbox.get_children():
		child.queue_free()
	piece_buttons.clear()

func _on_piece_selected(piece: PieceData):
	selected_piece = piece
	update_piece_details()
	equip_btn.visible = true

func update_piece_details():
	if not selected_piece:
		return
	
	# 🔧 CORREÇÃO: Usar raridade correta + melhor formatação
	var details_text = """🦾 Peça: %s
🏷️ Tipo: Braços
✨ Raridade: %s
🔧 Durabilidade: %d/%d

=== 📊 STATS ===
⚡ Ataque Especial: +%d (primário)
%s %s: +%d
%s %s: +%d

📍 Status: %s""" % [
		selected_piece.id,
		selected_piece.get_rarity_name(),  # 🔧 CORREÇÃO: raridade correta
		selected_piece.current_durability,
		selected_piece.max_durability,
		selected_piece.primary_stat,
		get_stat_color_indicator(selected_piece.secondary_stat_1),
		selected_piece.secondary_stat_1_type.capitalize(),
		selected_piece.secondary_stat_1,
		get_stat_color_indicator(selected_piece.secondary_stat_2),
		selected_piece.secondary_stat_2_type.capitalize(),
		selected_piece.secondary_stat_2,
		get_piece_status()
	]
	
	piece_details_label.text = details_text
	piece_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 🆕 APLICAR COR DA RARIDADE
	piece_details_label.modulate = selected_piece.get_rarity_color()

# 🆕 SISTEMA DE CORES PARA STATS
func get_stat_color_indicator(value: int) -> String:
	if value >= 25:
		return "🟣"  # Roxo - Excepcional
	elif value >= 20:
		return "🔵"  # Azul - Muito Alto
	elif value >= 15:
		return "🟢"  # Verde - Alto
	elif value >= 10:
		return "🟡"  # Amarelo - Normal
	elif value >= 5:
		return "🟠"  # Laranja - Baixo
	else:
		return "🔴"  # Vermelho - Muito Baixo

func get_piece_status() -> String:
	if not selected_piece:
		return "Não equipada"
	
	# Verificar se está equipada em algum robô
	for robot in GameManager.data_manager.robots:
		if robot.equipped_arms == selected_piece.id:
			return "Equipada em: " + robot.serial_number
	
	return "Disponível para equipar"

func _on_equip_pressed():
	print("🔧 Vá à Oficina para equipar peças nos robôs")
	# 🔧 CORREÇÃO: Melhor feedback

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
