# Arsenal.gd - Sistema de Raridades para Peças (CORRIGIDO)
extends Control

@onready var back_btn: Button = $BackButton
@onready var status_label: Label = $StatusLabel
@onready var produce_btn: Button = $ProduceButton
@onready var collect_btn: Button = $CollectButton

var production_timer: Timer
var is_producing: bool = false
var production_complete: bool = false

const PRODUCTION_TIME: float = 5.0
const PRODUCTION_COST: int = 20

# Probabilidades de raridade por nível (conforme database)
const RARITY_CHANCES = {
	1: {"COMUM": 0.85, "INCOMUM": 0.15},
	3: {"COMUM": 0.60, "INCOMUM": 0.30, "RARO": 0.10},
	6: {"COMUM": 0.50, "INCOMUM": 0.30, "RARO": 0.15, "EPICO": 0.05},
	10: {"COMUM": 0.35, "INCOMUM": 0.25, "RARO": 0.25, "EPICO": 0.12, "LENDARIO": 0.03}
}

func _ready():
	setup_ui()
	connect_signals()
	update_display()

func setup_ui():
	production_timer = Timer.new()
	production_timer.wait_time = PRODUCTION_TIME
	production_timer.timeout.connect(_on_production_complete)
	add_child(production_timer)

func connect_signals():
	back_btn.pressed.connect(_on_back_pressed)
	produce_btn.pressed.connect(_on_produce_pressed)
	collect_btn.pressed.connect(_on_collect_pressed)

func update_display():
	var player = GameManager.current_player
	
	produce_btn.disabled = (player.sucata < PRODUCTION_COST) or is_producing or production_complete
	collect_btn.visible = production_complete
	
	if is_producing:
		var time_left = production_timer.time_left
		status_label.text = "Produzindo braço... %.1fs restantes" % time_left
	elif production_complete:
		status_label.text = "🦾 Braço pronto para coleta!"
	else:
		var arsenal_level = player.arsenal_level
		var rarities = get_available_rarities(arsenal_level)
		status_label.text = """🏭 Arsenal Nível %d
💰 Custo: %d sucata
✨ Raridades: %s""" % [arsenal_level, PRODUCTION_COST, rarities]

func get_available_rarities(level: int) -> String:
	var available = []
	
	if level >= 1:
		available.append("Comum")
	if level >= 1:
		available.append("Incomum")
	if level >= 3:
		available.append("Raro")
	if level >= 6:
		available.append("Épico")
	if level >= 10:
		available.append("Lendário")
	
	return ", ".join(available)

func _on_produce_pressed():
	var player = GameManager.current_player
	if player.sucata >= PRODUCTION_COST:
		player.sucata -= PRODUCTION_COST
		is_producing = true
		production_timer.start()
		update_display()
		
		print("⚙️ Iniciando produção de braço")

func _on_production_complete():
	is_producing = false
	production_complete = true
	update_display()
	
	print("⚙️ Produção completa!")

func _on_collect_pressed():
	var new_piece = create_piece_with_rarity()
	GameManager.data_manager.pieces.append(new_piece)
	
	production_complete = false
	is_producing = false
	
	if production_timer.timeout.is_connected(_on_production_complete):
		production_timer.stop()
	
	update_display()
	GameManager.data_manager.save_game()
	print("🔧 Peça coletada: %s (%s)" % [new_piece.id, new_piece.get_rarity_name()])

func create_piece_with_rarity() -> PieceData:
	var piece = PieceData.new()
	
	var piece_count = GameManager.data_manager.pieces.size() + 1
	piece.id = "ARM-C-%06d" % piece_count
	
	piece.part_type = PieceData.PartType.BRAÇOS
	piece.rarity = determine_piece_rarity()
	
	# Aplicar stats com raridade
	apply_rarity_stats(piece)
	
	# Durabilidade baseada na raridade
	piece.max_durability = PieceData.RARITY_CYCLES[piece.rarity]
	piece.current_durability = piece.max_durability
	
	return piece

func determine_piece_rarity() -> PieceData.Rarity:
	var player = GameManager.current_player
	var level = player.arsenal_level
	
	if not RARITY_CHANCES.has(level):
		return PieceData.Rarity.COMUM
	
	var chances = RARITY_CHANCES[level]
	var roll = randf()
	var cumulative = 0.0
	
	var rarity_order = ["LENDARIO", "EPICO", "RARO", "INCOMUM", "COMUM"]
	
	for rarity_name in rarity_order:
		if chances.has(rarity_name):
			cumulative += chances[rarity_name]
			if roll <= cumulative:
				match rarity_name:
					"LENDARIO": return PieceData.Rarity.LENDARIO
					"EPICO": return PieceData.Rarity.EPICO
					"RARO": return PieceData.Rarity.RARO
					"INCOMUM": return PieceData.Rarity.INCOMUM
					"COMUM": return PieceData.Rarity.COMUM
	
	return PieceData.Rarity.COMUM

# FUNÇÃO COMPLETA CORRIGIDA
func apply_rarity_stats(piece: PieceData):
	# Range base para braços conforme database
	var base_primary = randi_range(20, 27)      # Ataque Especial base
	var base_secondary_1 = randi_range(5, 15)   # Stat secundário 1
	var base_secondary_2 = randi_range(3, 10)   # Stat secundário 2
	
	# Aplicar multiplicadores de raridade
	piece.primary_stat = piece.apply_rarity_multiplier(base_primary)
	piece.secondary_stat_1 = piece.apply_rarity_multiplier(base_secondary_1)
	piece.secondary_stat_2 = piece.apply_rarity_multiplier(base_secondary_2)
	
	# Stats secundários aleatórios
	var available_stats = ["attack", "defense", "speed", "health"]
	available_stats.shuffle()
	piece.secondary_stat_1_type = available_stats[0]
	piece.secondary_stat_2_type = available_stats[1]
	
	print("🔧 Peça criada com stats: Pri:%d Sec1:%d(%s) Sec2:%d(%s)" % [
		piece.primary_stat,
		piece.secondary_stat_1, piece.secondary_stat_1_type,
		piece.secondary_stat_2, piece.secondary_stat_2_type
	])

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _process(_delta):
	if is_producing:
		update_display()
