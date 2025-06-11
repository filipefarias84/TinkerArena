# Arsenal.gd - Produção de peças MVP
extends Control

@onready var back_btn: Button = $BackButton
@onready var status_label: Label = $StatusLabel
@onready var produce_btn: Button = $ProduceButton
@onready var collect_btn: Button = $CollectButton

var production_timer: Timer
var is_producing: bool = false
var production_complete: bool = false

const PRODUCTION_TIME: float = 5.0   # 5 segundos para MVP
const PRODUCTION_COST: int = 20      # 20 sucata

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
		status_label.text = "Braço Comum pronto para coleta!"
	else:
		status_label.text = "Arsenal pronto. Custo: %d sucata" % PRODUCTION_COST
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
	# Criar nova peça
	var new_piece = create_piece()
	GameManager.data_manager.pieces.append(new_piece)
	
	# Reset produção
	production_complete = false
	is_producing = false
	
	# Parar timer se estiver rodando
	if production_timer.timeout.is_connected(_on_production_complete):
		production_timer.stop()
	
	update_display()
	
	# Salvar jogo
	GameManager.data_manager.save_game()
	
	print("🔧 Peça coletada: " + new_piece.id)

func create_piece() -> PieceData:
	var piece = PieceData.new()
	
	# ID simples
	var piece_count = GameManager.data_manager.pieces.size() + 1
	piece.id = "ARM-C-%06d" % piece_count
	
	piece.part_type = PieceData.PartType.BRAÇOS
	piece.rarity = PieceData.Rarity.COMUM
	
	# Stats com variação
	piece.primary_stat = 20 + randi_range(-3, 7)  # 17-27 Ataque Especial
	piece.secondary_stat_1 = randi_range(5, 15)
	piece.secondary_stat_2 = randi_range(3, 10)
	
	# Stats secundários aleatórios
	var available_stats = ["attack", "defense", "speed", "health"]
	available_stats.shuffle()
	piece.secondary_stat_1_type = available_stats[0]
	piece.secondary_stat_2_type = available_stats[1]
	
	piece.max_durability = 10
	piece.current_durability = 10
	
	return piece

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _process(_delta):
	if is_producing:
		update_display()
