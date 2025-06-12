# TurnOrderUI.gd - Interface da barra de ordem de turnos (CORRIGIDO)
extends Control
class_name TurnOrderUI

var turn_slots_container: HBoxContainer
var background_panel: Panel

const MAX_SLOTS = 6
var turn_slots: Array[Control] = []

func _ready():
	setup_ui()
	create_turn_slots()

func setup_ui():
	# Criar background se não existe
	if not background_panel:
		background_panel = Panel.new()
		background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Criar StyleBox para o background
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.2, 0.3, 0.8)
		background_panel.add_theme_stylebox_override("panel", style_box)
		
		add_child(background_panel)
	
	# Criar container principal se não existe
	if not turn_slots_container:
		turn_slots_container = HBoxContainer.new()
		turn_slots_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		turn_slots_container.add_theme_constant_override("separation", 8)
		add_child(turn_slots_container)

func create_turn_slots():
	# Limpar slots existentes
	clear_slots()
	
	# Criar 6 slots vazios
	for i in range(MAX_SLOTS):
		var slot = create_turn_slot()
		turn_slots.append(slot)
		turn_slots_container.add_child(slot)

func create_turn_slot() -> Control:
	# Criar slot programaticamente
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(80, 60)
	
	# Background do slot
	var slot_bg = Panel.new()
	slot_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Criar StyleBox para o slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.4, 0.4, 0.5, 0.9)
	slot_bg.add_theme_stylebox_override("panel", slot_style)
	
	slot.add_child(slot_bg)
	
	# Label do nome
	var name_label = Label.new()
	name_label.text = "---"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_label.add_theme_font_size_override("font_size", 10)
	slot.add_child(name_label)
	
	# Label do número do turno
	var turn_label = Label.new()
	turn_label.text = ""
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	turn_label.position = Vector2(50, 5)
	turn_label.size = Vector2(25, 15)
	turn_label.add_theme_font_size_override("font_size", 8)
	slot.add_child(turn_label)
	
	return slot

func update_turn_order(turn_data_array: Array):
	if turn_data_array.size() > turn_slots.size():
		print("⚠️ TurnOrderUI: Mais dados (%d) que slots (%d)" % [turn_data_array.size(), turn_slots.size()])
	
	for i in range(min(turn_data_array.size(), turn_slots.size())):
		update_slot(i, turn_data_array[i])
	
	# Limpar slots não utilizados
	for i in range(turn_data_array.size(), turn_slots.size()):
		clear_slot(i)

func update_slot(slot_index: int, turn_data):
	if slot_index >= turn_slots.size():
		return
	
	var slot = turn_slots[slot_index]
	var name_label = slot.get_child(1) as Label  # Nome
	var turn_label = slot.get_child(2) as Label  # Número do turno
	var background = slot.get_child(0) as Panel  # Background
	
	if turn_data and turn_data.unit:
		# Atualizar texto
		var unit_name = get_short_name(turn_data.unit)
		name_label.text = unit_name
		turn_label.text = "T%d" % turn_data.turn_number
		
		# Cor baseada no tipo de unit
		var color = get_unit_color(turn_data.unit)
		if background:
			# Aplicar cor usando StyleBox
			var unit_style = StyleBoxFlat.new()
			unit_style.bg_color = color
			background.add_theme_stylebox_override("panel", unit_style)
		
		# Highlight para turno atual
		if turn_data.is_current_turn:
			highlight_current_slot(slot)
		else:
			remove_highlight(slot)
		
		slot.visible = true
	else:
		clear_slot(slot_index)

func get_short_name(unit: CombatUnit) -> String:
	if not unit or not unit.robot_data:
		return "???"
	
	# Determinar se é player ou enemy
	var display_name = ""
	if unit.robot_data.serial_number.begins_with("TKR-"):
		display_name = "VOCÊ"
	else:
		display_name = "IA"
	
	# Adicionar modelo
	var model = unit.get_model()
	match model:
		"LIGHTNING": display_name += "\nLGT"
		"GUARDIAN": display_name += "\nGRD"  
		"SWIFT": display_name += "\nSWT"
		_: display_name += "\n???"
	
	return display_name

func get_unit_color(unit: CombatUnit) -> Color:
	if not unit or not unit.robot_data:
		return Color.GRAY
	
	# Player = azul escuro, Enemy = vermelho escuro (melhor contraste)
	if unit.robot_data.serial_number.begins_with("TKR-"):
		return Color(0.2, 0.4, 0.8, 0.9)  # Azul escuro player
	else:
		return Color(0.8, 0.3, 0.2, 0.9)  # Vermelho escuro enemy

func highlight_current_slot(slot: Control):
	var background = slot.get_child(0) as Panel
	var name_label = slot.get_child(1) as Label
	
	if background:
		# Cor de highlight mais escura para melhor contraste
		var highlight_style = StyleBoxFlat.new()
		highlight_style.bg_color = Color(0.8, 0.6, 0.0, 1.0)  # Dourado escuro
		background.add_theme_stylebox_override("panel", highlight_style)
		
		# Texto em preto para contraste
		if name_label:
			name_label.add_theme_color_override("font_color", Color.BLACK)
		
		# Efeito de escala sutil
		var tween = create_tween()
		tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.2)

func remove_highlight(slot: Control):
	var name_label = slot.get_child(1) as Label
	
	# Resetar escala
	slot.scale = Vector2(1.0, 1.0)
	
	# Resetar cor do texto para branco
	if name_label:
		name_label.add_theme_color_override("font_color", Color.WHITE)

func clear_slot(slot_index: int):
	if slot_index >= turn_slots.size():
		return
	
	var slot = turn_slots[slot_index]
	var name_label = slot.get_child(1) as Label
	var turn_label = slot.get_child(2) as Label
	
	name_label.text = "---"
	turn_label.text = ""
	slot.visible = false

func clear_slots():
	for slot in turn_slots:
		if slot:
			slot.queue_free()
	turn_slots.clear()

func animate_turn_change():
	# Animação sutil quando turnos mudam
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
