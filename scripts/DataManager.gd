# DataManager.gd - Versão Simplificada MVP
extends Node
class_name DataManager

const SAVE_FILE = "user://mvp_save.json"

var robots: Array[RobotData] = []
var pieces: Array[PieceData] = []

func save_game():
	if not GameManager.current_player:
		print("❌ Erro: Nenhum jogador para salvar")
		return
		
	var save_data = {
		"player": GameManager.current_player.to_dict(),
		"robots": serialize_robots(),
		"pieces": serialize_pieces(),
		"save_version": "1.2"  # Versionamento atualizado para modelos dirigidos
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("💾 Jogo salvo - Robôs: %d, Peças: %d" % [robots.size(), pieces.size()])
	else:
		print("❌ Erro ao salvar arquivo")

func load_player_data() -> PlayerData:
	if not FileAccess.file_exists(SAVE_FILE):
		print("📁 Arquivo de save não encontrado, criando novo jogador")
		return null
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return null
	
	var data = json.data
	var save_version = data.get("save_version", "1.0")
	print("📖 Carregando save versão: " + save_version)
	
	var player = PlayerData.new()
	player.from_dict(data.get("player", {}))
	
	# Carregar robôs e peças
	load_robots_from_data(data.get("robots", []))
	load_pieces_from_data(data.get("pieces", []))
	
	print("✅ Save carregado - Robôs: %d, Peças: %d" % [robots.size(), pieces.size()])
	
	return player

func serialize_robots() -> Array:
	var serialized = []
	for robot in robots:
		serialized.append(robot.to_dict())
	return serialized

func serialize_pieces() -> Array:
	var serialized = []
	for piece in pieces:
		serialized.append(piece.to_dict())
	return serialized

func load_robots_from_data(data: Array):
	robots.clear()
	for robot_data in data:
		var robot = RobotData.new()
		robot.serial_number = robot_data.get("serial_number", "")
		robot.type = robot_data.get("type", RobotData.Type.COBRE_LIGHTNING)  # Corrigido para novo enum
		robot.rarity = robot_data.get("rarity", RobotData.Rarity.COMUM)
		robot.base_attack = robot_data.get("base_attack", 70)    # Stats balanceados
		robot.base_defense = robot_data.get("base_defense", 60)
		robot.base_special_attack = robot_data.get("base_special_attack", 75)
		robot.base_special_defense = robot_data.get("base_special_defense", 55)
		robot.base_health = robot_data.get("base_health", 120)
		robot.base_speed = robot_data.get("base_speed", 50)
		# Equipamentos (compatibilidade com saves antigos)
		robot.equipped_arms = robot_data.get("equipped_arms", "")
		robot.equipped_core = robot_data.get("equipped_core", "")
		robot.equipped_legs = robot_data.get("equipped_legs", "")
		robot.max_cycles = robot_data.get("max_cycles", 20)
		robot.remaining_cycles = robot_data.get("remaining_cycles", 20)
		robots.append(robot)

func load_pieces_from_data(data: Array):
	pieces.clear()
	for piece_data in data:
		var piece = PieceData.new()
		piece.id = piece_data.get("id", "")
		piece.part_type = piece_data.get("part_type", PieceData.PartType.BRAÇOS)
		piece.rarity = piece_data.get("rarity", PieceData.Rarity.COMUM)
		piece.primary_stat = piece_data.get("primary_stat", 20)
		piece.secondary_stat_1 = piece_data.get("secondary_stat_1", 0)
		piece.secondary_stat_2 = piece_data.get("secondary_stat_2", 0)
		piece.secondary_stat_1_type = piece_data.get("secondary_stat_1_type", "")
		piece.secondary_stat_2_type = piece_data.get("secondary_stat_2_type", "")
		piece.max_durability = piece_data.get("max_durability", 10)
		piece.current_durability = piece_data.get("current_durability", 10)
		pieces.append(piece)

func get_piece_by_id(piece_id: String) -> PieceData:
	for piece in pieces:
		if piece.id == piece_id:
			return piece
	return null

func get_active_robots() -> Array[RobotData]:
	return robots.filter(func(r): return r.remaining_cycles > 0)

func get_robot_by_serial(serial: String) -> RobotData:
	for robot in robots:
		if robot.serial_number == serial:
			return robot
	return null

func get_unequipped_pieces(part_type: PieceData.PartType = PieceData.PartType.BRAÇOS) -> Array[PieceData]:
	var unequipped = []
	for piece in pieces:
		if piece.part_type == part_type and not is_piece_equipped(piece.id):
			unequipped.append(piece)
	return unequipped

func is_piece_equipped(piece_id: String) -> bool:
	for robot in robots:
		if robot.equipped_arms == piece_id or robot.equipped_core == piece_id or robot.equipped_legs == piece_id:
			return true
	return false
